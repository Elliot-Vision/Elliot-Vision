import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:elliott_vision/elliott_vision.dart';

void main() {
  test('Online-Suche liefert ISIN-Treffer und rechnet den Kurs in Euro um', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/v1/finance/search') {
        return http.Response(
          jsonEncode({
            'quotes': [
              {
                'symbol': 'AAPL',
                'longname': 'Apple Inc.',
                'exchDisp': 'Nasdaq',
                'quoteType': 'EQUITY',
              },
            ],
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/AAPL')) {
        return http.Response(
          jsonEncode({
            'chart': {
              'result': [
                {
                  'meta': {
                    'currency': 'USD',
                    'regularMarketPrice': 100,
                    'regularMarketTime': 1785756000,
                    'fullExchangeName': 'Nasdaq',
                    'longName': 'Apple Inc.',
                  },
                  'indicators': {
                    'adjclose': [
                      {
                        'adjclose': [80, 90, 100],
                      },
                    ],
                  },
                },
              ],
              'error': null,
            },
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/USDEUR=X')) {
        return http.Response(
          jsonEncode({
            'chart': {
              'result': [
                {
                  'meta': {'regularMarketPrice': 0.9},
                  'indicators': const <String, Object?>{},
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
    expect(results.single.isLive, isTrue);
  });
}
