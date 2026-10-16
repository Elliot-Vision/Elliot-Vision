import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:elliott_vision/src/kraken_market_data.dart';
import 'package:elliott_vision/src/models.dart';

/// Manual, opt-in public endpoint smoke check. No credentials are used.
Future<void> main() async {
  final client = http.Client();
  try {
    final source = KrakenMarketData(client, () => DateTime.now().toUtc());
    for (final pair in ['XBTEUR', 'ETHEUR']) {
      final instrument = await source.load(pair, ChartTimeframe.oneMonth);
      stdout.writeln(jsonEncode({
        'symbol': instrument.selectedSymbol,
        'source': instrument.dataSource,
        'currency': instrument.originalCurrency,
        'price': instrument.euroPrice,
        'lastTrade': instrument.dataTimestamp.toIso8601String(),
        'candles': instrument.candlesEuro.length,
        'interval': instrument.candleInterval,
      }));
    }
  } finally {
    client.close();
  }
}
