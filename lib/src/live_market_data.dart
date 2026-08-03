import 'dart:convert';

import 'package:http/http.dart' as http;

import 'demo_data.dart';
import 'models.dart';

class MarketDataException implements Exception {
  const MarketDataException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Online-Marktdaten fuer die persoenliche Beta.
///
/// Die App nutzt oeffentlich erreichbare Endpunkte ohne eingebetteten
/// API-Schluessel. ISINs werden bei Bedarf ueber OpenFIGI einem handelbaren
/// Symbol zugeordnet. Fuer eine spaetere Store-/Produktionsversion bleibt ein
/// lizenzierter Anbieter hinter dem in der Architektur vorgesehenen Backend
/// erforderlich.
class LiveMarketDataRepository implements MarketDataRepository {
  LiveMarketDataRepository({http.Client? client, Iterable<Instrument>? seed})
    : _client = client ?? http.Client() {
    if (seed != null) {
      restore(seed);
    }
  }

  final http.Client _client;
  final Map<String, Instrument> _instruments = {};
  final Map<String, Future<double>> _fxRequests = {};

  static const _headers = <String, String>{
    'Accept': 'application/json',
    'User-Agent': 'ElliottVision/0.2 (Android; personal beta)',
  };

  @override
  List<Instrument> get instruments {
    final values = _instruments.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return List.unmodifiable(values);
  }

  @override
  Instrument byId(String id) {
    final instrument = findById(id);
    if (instrument == null) {
      throw StateError('Unbekanntes Wertpapier: $id');
    }
    return instrument;
  }

  @override
  Instrument? findById(String id) => _instruments[id];

  @override
  void restore(Iterable<Instrument> instruments) {
    for (final instrument in instruments) {
      _instruments[instrument.id] = instrument;
    }
  }

  @override
  Future<List<Instrument>> search(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return const [];
    }

    final isin = _looksLikeIsin(normalized) ? normalized.toUpperCase() : null;
    var candidates = <_QuoteCandidate>[];
    var yahooFailed = false;
    try {
      candidates = await _searchYahoo(normalized);
    } on Object {
      yahooFailed = true;
    }
    var usedOpenFigi = false;
    if (candidates.isEmpty) {
      candidates = isin == null
          ? await _searchOpenFigi(normalized)
          : await _mapIsinWithOpenFigi(isin);
      usedOpenFigi = true;
    }
    if (candidates.isEmpty) {
      if (yahooFailed) {
        throw const MarketDataException(
          'Die Wertpapiersuche ist vorübergehend nicht erreichbar.',
        );
      }
      return const [];
    }

    var results = await _loadCandidates(candidates, isin: isin);
    if (results.isEmpty && isin != null && !usedOpenFigi) {
      candidates = await _mapIsinWithOpenFigi(isin);
      results = await _loadCandidates(candidates, isin: isin);
    }
    for (final instrument in results) {
      _instruments[instrument.id] = instrument;
    }
    return results;
  }

  Future<List<Instrument>> _loadCandidates(
    Iterable<_QuoteCandidate> candidates, {
    String? isin,
  }) async {
    final loaded = await Future.wait(
      candidates.take(6).map((candidate) async {
        try {
          return await _loadInstrument(
            candidate.copyWith(isin: candidate.isin ?? isin),
          );
        } on Object {
          return null;
        }
      }),
    );
    return loaded.whereType<Instrument>().toList();
  }

  @override
  Future<Instrument> refresh(Instrument instrument) async {
    final refreshed = await _loadInstrument(
      _QuoteCandidate(
        symbol: _symbolForInstrument(instrument),
        name: instrument.name,
        venue: instrument.defaultVenue,
        isin: _looksLikeIsin(instrument.isin) ? instrument.isin : null,
        idOverride: instrument.id,
      ),
    );
    _instruments[refreshed.id] = refreshed;
    return refreshed;
  }

  Future<List<_QuoteCandidate>> _searchYahoo(String query) async {
    final uri = Uri.https(
      'query1.finance.yahoo.com',
      '/v1/finance/search',
      <String, String>{
        'q': query,
        'quotesCount': '10',
        'newsCount': '0',
        'enableFuzzyQuery': 'true',
        'quotesQueryId': 'tss_match_phrase_query',
      },
    );
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw MarketDataException(
        'Wertpapiersuche derzeit nicht erreichbar (${response.statusCode}).',
      );
    }

    final root = _asMap(jsonDecode(response.body));
    final rawQuotes = root['quotes'];
    if (rawQuotes is! List<Object?>) {
      return const [];
    }
    final results = <_QuoteCandidate>[];
    for (final raw in rawQuotes) {
      if (raw is! Map<Object?, Object?>) {
        continue;
      }
      final quote = Map<String, Object?>.from(raw);
      final type = (quote['quoteType'] as String? ?? '').toUpperCase();
      if (type != 'EQUITY' && type != 'ETF') {
        continue;
      }
      final symbol = quote['symbol'] as String?;
      if (symbol == null || symbol.isEmpty) {
        continue;
      }
      final name = (quote['longname'] as String?) ??
          (quote['shortname'] as String?) ??
          symbol;
      final venue = (quote['exchDisp'] as String?) ??
          (quote['exchange'] as String?) ??
          'Boerse';
      results.add(
        _QuoteCandidate(symbol: symbol, name: name, venue: venue),
      );
    }
    return _deduplicate(results);
  }

  Future<List<_QuoteCandidate>> _mapIsinWithOpenFigi(String isin) async {
    final uri = Uri.https('api.openfigi.com', '/v3/mapping');
    final response = await _client
        .post(
          uri,
          headers: <String, String>{
            ..._headers,
            'Content-Type': 'application/json',
          },
          body: jsonEncode([
            <String, String>{'idType': 'ID_ISIN', 'idValue': isin},
          ]),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      return const [];
    }
    final jobs = jsonDecode(response.body);
    if (jobs is! List<Object?> || jobs.isEmpty) {
      return const [];
    }
    final job = jobs.first;
    if (job is! Map<Object?, Object?>) {
      return const [];
    }
    final data = job['data'];
    if (data is! List<Object?>) {
      return const [];
    }

    final results = <_QuoteCandidate>[];
    for (final raw in data) {
      if (raw is! Map<Object?, Object?>) {
        continue;
      }
      final item = Map<String, Object?>.from(raw);
      if ((item['marketSector'] as String?) != 'Equity') {
        continue;
      }
      final ticker = item['ticker'] as String?;
      if (ticker == null || ticker.isEmpty) {
        continue;
      }
      final exchange = (item['exchCode'] as String?) ?? '';
      results.add(
        _QuoteCandidate(
          symbol: _toYahooSymbol(ticker, exchange),
          name: (item['name'] as String?) ?? ticker,
          venue: exchange.isEmpty ? 'Boerse' : exchange,
          isin: isin,
        ),
      );
    }
    return _deduplicate(results);
  }

  Future<List<_QuoteCandidate>> _searchOpenFigi(String query) async {
    final uri = Uri.https('api.openfigi.com', '/v3/search');
    final response = await _client
        .post(
          uri,
          headers: <String, String>{
            ..._headers,
            'Content-Type': 'application/json',
          },
          body: jsonEncode(<String, Object?>{
            'query': query,
            'marketSecDes': 'Equity',
          }),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      return const [];
    }
    final root = _asMap(jsonDecode(response.body));
    final data = root['data'];
    if (data is! List<Object?>) {
      return const [];
    }

    final results = <_QuoteCandidate>[];
    for (final raw in data) {
      if (raw is! Map<Object?, Object?>) {
        continue;
      }
      final item = Map<String, Object?>.from(raw);
      final ticker = item['ticker'] as String?;
      if (ticker == null || ticker.isEmpty) {
        continue;
      }
      final exchange = (item['exchCode'] as String?) ?? '';
      results.add(
        _QuoteCandidate(
          symbol: _toYahooSymbol(ticker, exchange),
          name: (item['name'] as String?) ?? ticker,
          venue: exchange.isEmpty ? 'Börse' : exchange,
        ),
      );
    }
    return _deduplicate(results);
  }

  Future<Instrument> _loadInstrument(_QuoteCandidate candidate) async {
    final uri = Uri.https(
      'query1.finance.yahoo.com',
      '/v8/finance/chart/${candidate.symbol}',
      const <String, String>{
        'interval': '1mo',
        'range': 'max',
        'events': 'div,splits',
      },
    );
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw MarketDataException('Kein Kurs fuer ${candidate.symbol}.');
    }

    final root = _asMap(jsonDecode(response.body));
    final chart = _asMap(root['chart']);
    final rawResults = chart['result'];
    if (rawResults is! List<Object?> || rawResults.isEmpty) {
      throw MarketDataException('Keine Kursreihe fuer ${candidate.symbol}.');
    }
    final result = _asMap(rawResults.first);
    final meta = _asMap(result['meta']);
    final rawCurrency = (meta['currency'] as String?) ?? 'EUR';
    final currencyInfo = _currencyInfo(rawCurrency);
    final fxRate = await _eurRate(currencyInfo.currency);
    final conversion = currencyInfo.unitScale * fxRate;

    final indicators = _asMap(result['indicators']);
    final closes = _extractCloses(indicators);
    if (closes.isEmpty) {
      throw MarketDataException('Keine Kurswerte fuer ${candidate.symbol}.');
    }
    final marketPrice = (meta['regularMarketPrice'] as num?)?.toDouble() ??
        closes.last;
    final history = closes.map((value) => value * conversion).toList();
    final currentEuro = marketPrice * conversion;
    if ((history.last - currentEuro).abs() > 0.000001) {
      history.add(currentEuro);
    } else {
      history[history.length - 1] = currentEuro;
    }

    final timestampSeconds = (meta['regularMarketTime'] as num?)?.toInt();
    final timestamp = timestampSeconds == null
        ? DateTime.now().toUtc()
        : DateTime.fromMillisecondsSinceEpoch(
            timestampSeconds * 1000,
            isUtc: true,
          );
    final venue = (meta['fullExchangeName'] as String?) ??
        (meta['exchangeName'] as String?) ??
        candidate.venue;
    final name = (meta['longName'] as String?) ??
        (meta['shortName'] as String?) ??
        candidate.name;

    return Instrument(
      id: candidate.idOverride ?? candidate.symbol.toLowerCase(),
      name: name,
      ticker: candidate.symbol,
      isin: candidate.isin ?? 'Nicht verfügbar',
      defaultVenue: venue,
      venues: <String>{venue, candidate.venue}.where((item) => item.isNotEmpty).toList(),
      originalCurrency: currencyInfo.currency,
      originalPrice: marketPrice * currencyInfo.unitScale,
      euroPrice: currentEuro,
      fxRate: fxRate,
      athEuro: history.reduce((a, b) => a > b ? a : b),
      atlEuro: history.reduce((a, b) => a < b ? a : b),
      dataTimestamp: timestamp,
      historyEuro: history,
      dataSource: 'Yahoo Finance / OpenFIGI',
      isLive: true,
    );
  }

  List<double> _extractCloses(Map<String, Object?> indicators) {
    List<Object?>? values;
    final adjusted = indicators['adjclose'];
    if (adjusted is List<Object?> && adjusted.isNotEmpty) {
      final series = _asMap(adjusted.first);
      values = series['adjclose'] as List<Object?>?;
    }
    final quotes = indicators['quote'];
    if ((values == null || values.isEmpty) &&
        quotes is List<Object?> &&
        quotes.isNotEmpty) {
      final series = _asMap(quotes.first);
      values = series['close'] as List<Object?>?;
    }
    return (values ?? const <Object?>[])
        .whereType<num>()
        .map((value) => value.toDouble())
        .where((value) => value.isFinite && value > 0)
        .toList();
  }

  Future<double> _eurRate(String currency) {
    if (currency == 'EUR') {
      return Future.value(1);
    }
    return _fxRequests.putIfAbsent(currency, () async {
      final symbol = '${currency}EUR=X';
      final uri = Uri.https(
        'query1.finance.yahoo.com',
        '/v8/finance/chart/$symbol',
        const <String, String>{'interval': '1d', 'range': '5d'},
      );
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw MarketDataException('EUR-Umrechnung fuer $currency fehlt.');
      }
      final root = _asMap(jsonDecode(response.body));
      final chart = _asMap(root['chart']);
      final results = chart['result'];
      if (results is! List<Object?> || results.isEmpty) {
        throw MarketDataException('EUR-Umrechnung fuer $currency fehlt.');
      }
      final result = _asMap(results.first);
      final meta = _asMap(result['meta']);
      final price = (meta['regularMarketPrice'] as num?)?.toDouble();
      if (price != null && price > 0) {
        return price;
      }
      final closes = _extractCloses(_asMap(result['indicators']));
      if (closes.isEmpty) {
        throw MarketDataException('EUR-Umrechnung fuer $currency fehlt.');
      }
      return closes.last;
    });
  }

  static Map<String, Object?> _asMap(Object? value) {
    if (value is Map<Object?, Object?>) {
      return Map<String, Object?>.from(value);
    }
    return const <String, Object?>{};
  }

  static bool _looksLikeIsin(String value) =>
      RegExp(r'^[A-Za-z]{2}[A-Za-z0-9]{9}[0-9]$').hasMatch(value.trim());

  static List<_QuoteCandidate> _deduplicate(
    Iterable<_QuoteCandidate> candidates,
  ) {
    final seen = <String>{};
    return candidates
        .where((candidate) => seen.add(candidate.symbol.toUpperCase()))
        .toList();
  }

  static _CurrencyInfo _currencyInfo(String rawCurrency) {
    final normalized = rawCurrency.toUpperCase();
    if (normalized == 'GBX' ||
        (normalized == 'GBP' && rawCurrency != 'GBP')) {
      return const _CurrencyInfo('GBP', 0.01);
    }
    return _CurrencyInfo(normalized, 1);
  }

  static String _toYahooSymbol(String ticker, String exchange) {
    if (ticker.contains('.')) {
      return ticker;
    }
    const suffixes = <String, String>{
      'GR': '.DE',
      'GY': '.DE',
      'GF': '.F',
      'AU': '.AX',
      'AT': '.AX',
      'CN': '.TO',
      'CT': '.TO',
      'CV': '.V',
      'LN': '.L',
      'FP': '.PA',
      'IM': '.MI',
      'NA': '.AS',
      'BB': '.BR',
      'SM': '.MC',
      'SW': '.SW',
      'SS': '.ST',
      'NO': '.OL',
      'DC': '.CO',
      'FH': '.HE',
    };
    return '$ticker${suffixes[exchange.toUpperCase()] ?? ''}';
  }

  static String _symbolForInstrument(Instrument instrument) {
    final ticker = instrument.ticker;
    if (ticker.contains('.') || ticker.contains('=')) {
      return ticker;
    }
    final venue = instrument.defaultVenue.toUpperCase();
    if (venue.contains('ASX')) {
      return '$ticker.AX';
    }
    if (venue.contains('XETRA')) {
      return '$ticker.DE';
    }
    if (venue.contains('FRANKFURT')) {
      return '$ticker.F';
    }
    if (venue.contains('TSX VENTURE')) {
      return '$ticker.V';
    }
    if (venue.contains('TSX')) {
      return '$ticker.TO';
    }
    if (venue.contains('LONDON') || venue.contains('LSE')) {
      return '$ticker.L';
    }
    return ticker;
  }
}

class _QuoteCandidate {
  const _QuoteCandidate({
    required this.symbol,
    required this.name,
    required this.venue,
    this.isin,
    this.idOverride,
  });

  final String symbol;
  final String name;
  final String venue;
  final String? isin;
  final String? idOverride;

  _QuoteCandidate copyWith({String? isin}) => _QuoteCandidate(
    symbol: symbol,
    name: name,
    venue: venue,
    isin: isin ?? this.isin,
    idOverride: idOverride,
  );
}

class _CurrencyInfo {
  const _CurrencyInfo(this.currency, this.unitScale);

  final String currency;
  final double unitScale;
}
