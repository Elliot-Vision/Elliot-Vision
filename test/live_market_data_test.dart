import 'dart:convert';

import 'package:elliott_vision/elliott_vision.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('Fehlender Kurszeitpunkt verwendet datierten Chartwert statt Abrufzeit',
      () async {
    final source = DemoMarketDataRepository().byId('aapl');
    final payload = _chartResponse(
        currency: 'EUR',
        venue: 'Nasdaq',
        marketPrice: 999,
        closes: [80, 90, 100],
        highs: [85, 95, 110],
        lows: [70, 75, 90]);
    final result = ((payload['chart'] as Map)['result'] as List).first as Map;
    (result['meta'] as Map).remove('regularMarketTime');
    final repository = LiveMarketDataRepository(
        client:
            MockClient((_) async => http.Response(jsonEncode(payload), 200)),
        now: () => DateTime.utc(2040));
    final loaded = await repository.loadSeries(source, ChartTimeframe.maximum);
    expect(loaded.euroPrice, 100);
    expect(loaded.dataTimestamp,
        DateTime.fromMillisecondsSinceEpoch(1785756000 * 1000, isUtc: true));
    expect(loaded.dataDelay, contains('Kurszeitpunkt fehlt'));
    expect(loaded.dataSource, contains('Yahoo Finance'));
    expect(loaded.dataSource, isNot(contains('OpenFIGI')));
  });

  test(
      'ISIN wird exakt gemappt, in Euro umgerechnet und nach Hoch/Tief bewertet',
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
    expect(frankfurt.athEuro, closeTo(97, 0.001));
    expect(frankfurt.atlEuro, closeTo(82, 0.001));
  });

  test('ISIN-Pruefziffer wird validiert', () {
    expect(LiveMarketDataRepository.isValidIsin('US0378331005'), isTrue);
    expect(LiveMarketDataRepository.isValidIsin('US0378331004'), isFalse);
    expect(LiveMarketDataRepository.isValidIsin('kein-isin'), isFalse);
  });

  test('OpenFIGI 429 respektiert das dokumentierte Reset-Fenster', () async {
    var attempts = 0;
    final delays = <Duration>[];
    final repository = LiveMarketDataRepository(
      client: MockClient((request) async {
        attempts++;
        return http.Response(
          'rate limited',
          429,
          headers: const <String, String>{'ratelimit-reset': '13'},
        );
      }),
      delay: (duration) async => delays.add(duration),
    );

    await expectLater(
      repository.search('US0378331005'),
      throwsA(isA<MarketDataException>()),
    );
    expect(attempts, 3);
    expect(delays, <Duration>[
      const Duration(seconds: 13),
      const Duration(seconds: 13),
    ]);
  });

  test('fehlgeschlagene FX-Abfrage wird nicht zwischengespeichert', () async {
    var fxAttempts = 0;
    final repository = LiveMarketDataRepository(
      client: MockClient((request) async {
        if (request.url.path == '/v3/mapping') {
          return http.Response(jsonEncode(_mappingResponse()), 200);
        }
        if (request.url.path.endsWith('/AAPL')) {
          return http.Response(jsonEncode(_appleChartResponse()), 200);
        }
        if (request.url.path.endsWith('/USDEUR=X')) {
          fxAttempts++;
          if (fxAttempts == 1) {
            return http.Response('temporarily unavailable', 503);
          }
          return http.Response(jsonEncode(_fxResponse(0.91)), 200);
        }
        return http.Response('Not found', 404);
      }),
    );

    expect(await repository.search('US0378331005'), isEmpty);
    final recovered = await repository.search('US0378331005');

    expect(recovered, hasLength(1));
    expect(recovered.single.fxRate, closeTo(0.91, 0.001));
    expect(fxAttempts, 2);
  });

  test('FX-Cache laeuft ab und manuelles Aktualisieren laedt neu', () async {
    var now = DateTime.utc(2026, 8, 4, 12);
    var fxAttempts = 0;
    const rates = <double>[0.90, 0.80, 0.70];
    final repository = LiveMarketDataRepository(
      client: MockClient((request) async {
        if (request.url.path == '/v3/mapping') {
          return http.Response(jsonEncode(_mappingResponse()), 200);
        }
        if (request.url.path.endsWith('/AAPL')) {
          return http.Response(jsonEncode(_appleChartResponse()), 200);
        }
        if (request.url.path.endsWith('/USDEUR=X')) {
          final index = fxAttempts.clamp(0, rates.length - 1).toInt();
          final rate = rates[index];
          fxAttempts++;
          return http.Response(jsonEncode(_fxResponse(rate)), 200);
        }
        return http.Response('Not found', 404);
      }),
      now: () => now,
      fxCacheTtl: const Duration(minutes: 5),
    );

    final initial = (await repository.search('US0378331005')).single;
    final cached = await repository.loadSeries(
      initial,
      ChartTimeframe.oneMonth,
    );
    expect(initial.fxRate, closeTo(0.90, 0.001));
    expect(initial.candlesEuro, hasLength(3));
    expect(initial.candlesEuro.first.open, closeTo(72, 0.001));
    expect(initial.candlesEuro.first.high, closeTo(76.5, 0.001));
    expect(initial.candlesEuro.first.low, closeTo(63, 0.001));
    expect(initial.candlesEuro.first.close, closeTo(72, 0.001));
    expect(cached.fxRate, closeTo(0.90, 0.001));
    expect(fxAttempts, 1);

    now = now.add(const Duration(minutes: 6));
    final expired = await repository.loadSeries(
      cached,
      ChartTimeframe.oneMonth,
    );
    expect(expired.fxRate, closeTo(0.80, 0.001));
    expect(fxAttempts, 2);

    final refreshed = await repository.refresh(expired);
    expect(refreshed.fxRate, closeTo(0.70, 0.001));
    expect(fxAttempts, 3);
  });

  test('Chart-Zeitraeume besitzen passende Minuten- bis Monatsintervalle', () {
    expect(ChartTimeframe.oneDay.interval, '5m');
    expect(ChartTimeframe.fiveDays.interval, '30m');
    expect(ChartTimeframe.oneYear.interval, '1wk');
    expect(ChartTimeframe.maximum.interval, '1mo');
  });
}

List<Object?> _mappingResponse() => <Object?>[
      <String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'ticker': 'AAPL',
            'name': 'Apple Inc.',
            'exchCode': 'US',
            'marketSector': 'Equity',
          },
        ],
      },
    ];

Map<String, Object?> _appleChartResponse() => _chartResponse(
      currency: 'USD',
      venue: 'Nasdaq',
      marketPrice: 100,
      closes: const <double>[80, 90, 100],
      highs: const <double>[85, 95, 110],
      lows: const <double>[70, 75, 90],
    );

Map<String, Object?> _fxResponse(double rate) => <String, Object?>{
      'chart': <String, Object?>{
        'result': <Object?>[
          <String, Object?>{
            'meta': <String, Object?>{'regularMarketPrice': rate},
            'indicators': <String, Object?>{},
          },
        ],
        'error': null,
      },
    };

Map<String, Object?> _chartResponse({
  required String currency,
  required String venue,
  required double marketPrice,
  required List<double> closes,
  required List<double> highs,
  required List<double> lows,
}) =>
    <String, Object?>{
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
                  'open': closes,
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
