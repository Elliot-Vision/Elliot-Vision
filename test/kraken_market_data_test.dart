import 'dart:convert';
import 'package:elliott_vision/elliott_vision.dart';
import 'package:elliott_vision/src/kraken_market_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final now = DateTime.utc(2026, 10, 16, 12);
  final stamp = now.millisecondsSinceEpoch ~/ 1000;
  Map<String, Object> response(String path, {bool invalid = false}) => {
        'error': <String>[],
        'result': {
          'XXBTZEUR': path == 'Trades'
              ? [
                  ['104', '0.1', stamp, 'b', 'm', '', 1]
                ]
              : [
                  [stamp - 86400 * 3, '100', '110', '90', '101', '100', '2', 3],
                  [stamp - 86400 * 2, '101', '111', '91', '102', '100', '2', 3],
                  [stamp - 86400, '102', '112', '92', '103', '100', '2', 3],
                  [
                    stamp - 300,
                    '103',
                    invalid ? '99' : '113',
                    '93',
                    '104',
                    '100',
                    '2',
                    3
                  ],
                ],
          'last': '$stamp',
        },
      };

  test(
      'Kostenlose Kryptosuche liefert direkte Euro-Börsendaten ohne FX-Mischung',
      () async {
    final requested = <Uri>[];
    final client = MockClient((request) async {
      requested.add(request.url);
      expect(request.url.host, 'api.kraken.com');
      return http.Response(
          jsonEncode(response(request.url.path.split('/').last)), 200);
    });
    final repository = LiveMarketDataRepository(client: client, now: () => now);
    final results = await repository.search('Bitcoin');
    final instrument = results.single;
    expect(instrument.defaultVenue, 'Kraken');
    expect(instrument.originalCurrency, 'EUR');
    expect(instrument.euroPrice, 104);
    expect(instrument.fxRate, 1);
    expect(instrument.dataTimestamp, now);
    expect(instrument.candlesEuro, hasLength(4));
    expect(instrument.candleInterval, '1wk');
    expect(instrument.athEuro, 113);
    expect(instrument.atlEuro, 90);
    final loaded =
        await repository.loadSeries(instrument, ChartTimeframe.oneMonth);
    expect(loaded.id, instrument.id);
    expect(loaded.candleInterval, '1d');
    expect(loaded.historyTimestamps.last, now);
    expect(requested.any((uri) => uri.queryParameters['interval'] == '1440'),
        isTrue);
    final restored = Instrument.fromJson(instrument.toJson());
    expect(restored.dataInterval, '1wk');
    expect(restored.selectedSymbol, 'KRAKEN:XBTEUR');
  });

  test(
      'Ungültige Kerzen werden verworfen, fehlende oder fehlerhafte Daten abgelehnt',
      () async {
    final client = MockClient((request) async => http.Response(
        jsonEncode(response(request.url.path.split('/').last, invalid: true)),
        200));
    final source = KrakenMarketData(client, () => now);
    final instrument = await source.load('XBTEUR', ChartTimeframe.maximum);
    expect(instrument.candlesEuro, hasLength(3));
    expect(instrument.candlesEuro.every((c) => c.isValid), isTrue);
    final bad = KrakenMarketData(
        MockClient((_) async => http.Response(
            jsonEncode({
              'error': ['EQuery:Unknown asset pair']
            }),
            200)),
        () => now);
    await expectLater(
        bad.load('XBTEUR', ChartTimeframe.maximum), throwsStateError);
    expect(KrakenMarketData.pairForQuery('BTC/USD'), isNull);
    expect(KrakenMarketData.pairForQuery('ETH/EUR'), 'ETHEUR');
  });
}
