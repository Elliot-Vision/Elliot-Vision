import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'models.dart';

/// Public, read-only EUR spot data. No account, key or trading endpoint is used.
class KrakenMarketData {
  KrakenMarketData(this.client, this.now);
  final http.Client client;
  final DateTime Function() now;
  static const coins = <String, (String, String)>{
    'BTC': ('XBT', 'Bitcoin'),
    'ETH': ('ETH', 'Ethereum'),
    'SOL': ('SOL', 'Solana'),
    'XRP': ('XRP', 'XRP'),
    'ADA': ('ADA', 'Cardano'),
    'LTC': ('LTC', 'Litecoin'),
    'DOGE': ('XDG', 'Dogecoin'),
    'DOT': ('DOT', 'Polkadot'),
  };

  static String? pairForQuery(String query) {
    final value = query.trim().toUpperCase().replaceAll(' ', '');
    for (final coin in coins.entries) {
      if ([
        coin.key,
        coin.value.$2.toUpperCase(),
        '${coin.key}-EUR',
        '${coin.key}/EUR',
        '${coin.key}EUR'
      ].contains(value)) {
        return '${coin.value.$1}EUR';
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> _get(
      String path, Map<String, String> query) async {
    final response = await client
        .get(Uri.https('api.kraken.com', '/0/public/$path', query))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw StateError('Kraken nicht erreichbar');
    final root = jsonDecode(response.body) as Map<String, dynamic>;
    if (root['error'] is! List ||
        (root['error'] as List).isNotEmpty ||
        root['result'] is! Map) {
      throw StateError('Kraken liefert keine gültigen Marktdaten');
    }
    return Map<String, dynamic>.from(root['result'] as Map);
  }

  Future<List<PriceCandle>> _candles(String pair, int interval) async {
    final result = await _get('OHLC', {'pair': pair, 'interval': '$interval'});
    final arrays = result.entries
        .where((entry) => entry.key != 'last' && entry.value is List);
    if (arrays.length != 1) throw StateError('Kraken-Kerzen fehlen');
    final values = <DateTime, PriceCandle>{};
    for (final raw in arrays.single.value as List) {
      if (raw is! List || raw.length < 5) continue;
      final time = double.tryParse('${raw[0]}');
      final prices =
          raw.skip(1).take(4).map((v) => double.tryParse('$v')).toList();
      if (time == null ||
          !time.isFinite ||
          time <= 0 ||
          time > 8640000000000 ||
          prices.any((v) => v == null || !v.isFinite || v <= 0)) {
        continue;
      }
      final candle = PriceCandle(
          timestamp: DateTime.fromMillisecondsSinceEpoch((time * 1000).round(),
              isUtc: true),
          open: prices[0]!,
          high: prices[1]!,
          low: prices[2]!,
          close: prices[3]!);
      if (candle.isValid &&
          !candle.timestamp.isAfter(now().add(const Duration(minutes: 1)))) {
        values[candle.timestamp] = candle;
      }
    }
    final candles = values.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (candles.length < 3) throw StateError('Zu wenige gültige Kraken-Kerzen');
    return candles;
  }

  Future<Instrument> load(String pair, ChartTimeframe timeframe,
      {String? id}) async {
    final coin =
        coins.entries.where((c) => '${c.value.$1}EUR' == pair).firstOrNull;
    if (coin == null) throw StateError('Nicht unterstütztes Kraken-Euro-Paar');
    final interval = switch (timeframe) {
      ChartTimeframe.oneDay => 5,
      ChartTimeframe.fiveDays => 30,
      ChartTimeframe.oneMonth || ChartTimeframe.threeMonths => 1440,
      _ => 10080,
    };
    final candles = await _candles(pair, interval);
    final allAvailable =
        interval == 10080 ? candles : await _candles(pair, 10080);
    final trades = await _get('Trades', {'pair': pair, 'count': '1'});
    final rows =
        trades.entries.where((e) => e.key != 'last' && e.value is List);
    if (rows.length != 1 || (rows.single.value as List).isEmpty) {
      throw StateError('Letzter Trade fehlt');
    }
    final trade = (rows.single.value as List).last;
    if (trade is! List || trade.length < 3) {
      throw StateError('Ungültiger Trade');
    }
    final price = double.tryParse('${trade[0]}');
    final time = double.tryParse('${trade[2]}');
    if (price == null ||
        !price.isFinite ||
        price <= 0 ||
        time == null ||
        !time.isFinite ||
        time <= 0 ||
        time > 8640000000000) {
      throw StateError('Ungültiger letzter Trade');
    }
    final stamp =
        DateTime.fromMillisecondsSinceEpoch((time * 1000).round(), isUtc: true);
    if (stamp.isAfter(now().add(const Duration(minutes: 1))) ||
        stamp.isBefore(candles.last.timestamp)) {
      throw StateError('Inkonsistenter Kurszeitpunkt');
    }
    final days = switch (timeframe) {
      ChartTimeframe.oneDay => 1,
      ChartTimeframe.fiveDays => 5,
      ChartTimeframe.oneMonth => 30,
      ChartTimeframe.threeMonths => 90,
      ChartTimeframe.oneYear => 365,
      ChartTimeframe.fiveYears => 1825,
      ChartTimeframe.maximum => null,
    };
    final chosen = candles
        .where((c) =>
            days == null ||
            !c.timestamp.isBefore(now().subtract(Duration(days: days))))
        .toList();
    if (chosen.length < 3) throw StateError('Gewählter Zeitraum unvollständig');
    final history = chosen.map((c) => c.close).toList();
    final timestamps = chosen.map((c) => c.timestamp).toList();
    if (stamp.isAfter(timestamps.last)) {
      history.add(price);
      timestamps.add(stamp);
    }
    final symbol = 'KRAKEN:$pair';
    return Instrument(
        id: id ?? '${coin.key.toLowerCase()}-eur-kraken',
        name: coin.value.$2,
        ticker: '${coin.key}/EUR',
        isin: 'Nicht verfügbar',
        defaultVenue: 'Kraken',
        venues: const ['Kraken'],
        venueSymbols: {'Kraken': symbol},
        originalCurrency: 'EUR',
        originalPrice: price,
        euroPrice: price,
        fxRate: 1,
        athEuro:
            math.max(price, allAvailable.map((c) => c.high).reduce(math.max)),
        atlEuro:
            math.min(price, allAvailable.map((c) => c.low).reduce(math.min)),
        dataTimestamp: stamp,
        historyEuro: history,
        historyTimestamps: timestamps,
        candlesEuro: chosen,
        assetType: AssetType.crypto,
        timeframe: timeframe,
        dataInterval: interval == 10080 ? '1wk' : timeframe.interval,
        dataSource: 'Kraken Spot · ${coin.key}/EUR · öffentliche Börsendaten',
        dataDelay:
            'REST-Abruf; Zeitpunkt des letzten gemeldeten Trades. Letzte Kerze läuft. '
            'Extremwerte: verfügbare Wochenhistorie, maximal 720 Kerzen.',
        isLive: true);
  }
}
