import 'dart:convert';

import 'package:elliott_vision/elliott_vision.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('ISIN wird exakt gemappt, in Euro umgerechnet und nach Hoch/Tief bewertet',
      () async {
    final client = MockClient((request) async {
      if (request.url.path == '/v3/mapping') {
        return http.Response(
          jsonEncode(<Object?>[
            <String, Object?>{
              'data': <Object?>[
                <String, Object?>{
                  'ticker': 'AAPL',
                  'name': 'Apple Inc.',
                  'exchCode': 'US',
                  'marketSector': 'Equity',
                },
                <String, Object?>{
                  'ticker': 'APC',
                  'name': 'Apple Inc.',
                  'exchCode': 'GF',
                  'marketSector': 'Equity',
                },
              ],
            },
          ]),
          200,
        );
      }
      if (request.url.path.endsWith('/AAPL')) {
        return http.Response(
          jsonEncode(_chartResponse(
            currency: 'USD',
            venue: 'Nasdaq',
            marketPrice: 100,
            closes: <double>[80, 90, 100],
            highs: <double>[85, 95, 110],
            lows: <double>[70, 75, 90],
          )),
          200,
        );
      }
      if (request.url.path.endsWith('/APC.F')) {
        return http.Response(
          jsonEncode(_chartResponse(
            currency: 'EUR',
            venue: 'Frankfurt',
            marketPrice: 95,
            closes: <double>[85, 90, 95],
            highs: <double>[87, 94, 97],
            lows: <double>[82, 88, 92],
          )),
          200,
        );
      }
      if (request.url.path.endsWith('/USDEUR=X')) {
        return http.Response(
          jsonEncode(<String, Object?>{
            'chart': <String, Object?>{
              'result': <Object?>[
                <String, Object?>{
                  'meta': <String, Object?>{'regularMarketPrice': 0.9},
                  'indicators': <String, Object?>{},
                },
              ],
              'error': null,
            },
          }),
          200,
        );
      }
      return http.Response('Not found', 404);
    });
    final repository = LiveMarketDataRepository(client: client);

    final results = await repository.search('US0378331005');

    expect(results, hasLength(1));
    expect(results.single.name, 'Apple Inc.');
    expect(results.single.isin, 'US0378331005');
    expect(results.single.euroPrice, closeTo(90, 0.001));
    expect(results.single.fxRate, closeTo(0.9, 0.001));
    expect(results.single.athEuro, closeTo(99, 0.001));
    expect(results.single.atlEuro, closeTo(63, 0.001));
    expect(results.single.venueSymbols['Nasdaq'], 'AAPL');
    expect(results.single.venueSymbols['Frankfurt'], 'APC.F');

    final frankfurt = await repository.loadVenue(results.single, 'Frankfurt');
    expect(frankfurt.defaultVenue, 'Frankfurt');
    expect(frankfurt.ticker, 'APC.F');
    expect(frankfurt.originalCurrency, 'EUR');
    expect(frankfurt.euroPrice, closeTo(95, 0.001));
  });

  test('ISIN-Pruefziffer wird validiert', () {
    expect(LiveMarketDataRepository.isValidIsin('US0378331005'), isTrue);
    expect(LiveMarketDataRepository.isValidIsin('US0378331004'), isFalse);
    expect(LiveMarketDataRepository.isValidIsin('kein-isin'), isFalse);
  });

  test('OpenFIGI 429 wird begrenzt erneut versucht', () async {
    var attempts = 0;
    final delays = <Duration>[];
    final repository = LiveMarketDataRepository(
      client: MockClient((request) async {
        attempts++;
        return http.Response('rate limited', 429);
      }),
      delay: (duration) async => delays.add(duration),
    );

    await expectLater(
      repository.search('US0378331005'),
      throwsA(isA<MarketDataException>()),
    );
    expect(attempts, 3);
    expect(delays, hasLength(2));
  });

  test('Chart-Zeitraeume besitzen passende Minuten- bis Monatsintervalle', () {
    expect(ChartTimeframe.oneDay.interval, '5m');
    expect(ChartTimeframe.fiveDays.interval, '30m');
    expect(ChartTimeframe.oneYear.interval, '1wk');
    expect(ChartTimeframe.maximum.interval, '1mo');
  });
}

Map<String, Object?> _chartResponse({
  required String currency,
  required String venue,
  required double marketPrice,
  required List<double> closes,
  required List<double> highs,
  required List<double> lows,
}) => <String, Object?>{
  'chart': <String, Object?>{
    'result': <Object?>[
      <String, Object?>{
        'meta': <String, Object?>{
          'currency': currency,
          'regularMarketPrice': marketPrice,
          'regularMarketTime': 1785756000,
          'fullExchangeName': venue,
          'longName': 'Apple Inc.',
          'exchangeDataDelayedBy': 900,
        },
        'timestamp': <int>[1783164000, 1785752400, 1785756000],
        'indicators': <String, Object?>{
          'adjclose': <Object?>[
            <String, Object?>{'adjclose': closes},
          ],
          'quote': <Object?>[
            <String, Object?>{
              'close': closes,
              'high': highs,
              'low': lows,
            },
          ],
        },
      },
    ],
    'error': null,
  },
};
