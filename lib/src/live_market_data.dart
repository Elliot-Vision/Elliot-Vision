import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'demo_data.dart';
import 'models.dart';
import 'kraken_market_data.dart';

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
  LiveMarketDataRepository({
    http.Client? client,
    Iterable<Instrument>? seed,
    Future<void> Function(Duration)? delay,
    DateTime Function()? now,
    this.fxCacheTtl = const Duration(minutes: 5),
  })  : _client = client ?? http.Client(),
        _delay = delay ?? ((duration) => Future<void>.delayed(duration)),
        _now = now ?? (() => DateTime.now().toUtc()) {
    if (seed != null) {
      restore(seed);
    }
  }

  final http.Client _client;
  final Future<void> Function(Duration) _delay;
  final DateTime Function() _now;
  final Duration fxCacheTtl;
  final Map<String, Instrument> _instruments = {};
  final Map<String, _FxRateCacheEntry> _fxRates = {};
  final Map<String, Future<double>> _fxRequests = {};

  static const _headers = <String, String>{
    'Accept': 'application/json',
    'User-Agent': 'ElliottVision/0.4.1 (Android; personal beta)',
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
      final symbols = instrument.venueSymbols.isEmpty
          ? <String, String>{
              instrument.defaultVenue: _legacySymbolForVenue(
                instrument.ticker,
                instrument.defaultVenue,
              ),
            }
          : Map<String, String>.from(instrument.venueSymbols);
      if (!symbols.containsKey(instrument.defaultVenue)) {
        symbols[instrument.defaultVenue] = instrument.ticker;
      }
      _instruments[instrument.id] = instrument.copyWith(
        venues: symbols.keys.toList(growable: false),
        venueSymbols: symbols,
      );
    }
  }

  @override
  Future<List<Instrument>> search(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return const [];
    }

    final normalizedIsin = normalized.toUpperCase();
    final hasIsinShape = _hasIsinShape(normalizedIsin);
    if (hasIsinShape && !isValidIsin(normalizedIsin)) {
      throw const MarketDataException(
        'Die ISIN ist formal ungueltig. Bitte pruefe die letzte Ziffer.',
      );
    }
    final isin = hasIsinShape ? normalizedIsin : null;
    final krakenPair = KrakenMarketData.pairForQuery(normalized);
    if (krakenPair != null) {
      try {
        final loaded = await KrakenMarketData(_client, _now)
            .load(krakenPair, ChartTimeframe.maximum);
        _instruments[loaded.id] = loaded;
        return [loaded];
      } on Object {
        // Search may still succeed through the explicitly labelled Yahoo source.
      }
    }

    if (isin != null) {
      final candidates = await _mapIsinWithOpenFigi(isin);
      final results = await _loadCandidates(candidates, isin: isin);
      for (final instrument in results) {
        _instruments[instrument.id] = instrument;
      }
      return results;
    }

    var candidates = <_QuoteCandidate>[];
    var yahooFailed = false;
    var usedOpenFigi = false;
    try {
      candidates = await _searchYahoo(normalized);
    } on Object {
      yahooFailed = true;
    }
    if (candidates.isEmpty) {
      candidates = await _searchOpenFigi(normalized);
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

    var results = await _loadCandidates(candidates);
    if (results.isEmpty && !usedOpenFigi) {
      final mapped = await _searchOpenFigi(normalized);
      results = await _loadCandidates(mapped);
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
      candidates.take(10).map((candidate) async {
        try {
          return await _loadInstrument(
            candidate.copyWith(
              isin: candidate.isin ?? isin,
              idOverride: isin?.toLowerCase(),
            ),
          );
        } on Object {
          return null;
        }
      }),
    );
    final results = loaded.whereType<Instrument>().toList();
    if (isin == null || results.isEmpty) {
      return results;
    }
    final venueSymbols = <String, String>{};
    for (final instrument in results) {
      venueSymbols.addAll(instrument.venueSymbols);
    }
    final preferred = results.first;
    return <Instrument>[
      preferred.copyWith(
        isin: isin,
        venues: venueSymbols.keys.toList(growable: false),
        venueSymbols: venueSymbols,
      ),
    ];
  }

  @override
  Future<Instrument> refresh(Instrument instrument) async {
    final candidate = _QuoteCandidate(
      symbol: instrument.selectedSymbol,
      name: instrument.name,
      venue: instrument.defaultVenue,
      assetType: instrument.assetType,
      isin: _hasIsinShape(instrument.isin) ? instrument.isin : null,
      idOverride: instrument.id,
    );
    final loaded = await _loadInstrumentWithAllTimeExtremes(
      candidate,
      timeframe: instrument.timeframe,
      refreshFx: true,
    );
    final refreshed = loaded.copyWith(
      isin: instrument.isin,
      defaultVenue: instrument.defaultVenue,
      venues: instrument.venues,
      venueSymbols: instrument.venueSymbols,
    );
    _instruments[refreshed.id] = refreshed;
    return refreshed;
  }

  @override
  Future<Instrument> loadSeries(
    Instrument instrument,
    ChartTimeframe timeframe,
  ) async {
    final candidate = _QuoteCandidate(
      symbol: instrument.selectedSymbol,
      name: instrument.name,
      venue: instrument.defaultVenue,
      assetType: instrument.assetType,
      isin: _hasIsinShape(instrument.isin) ? instrument.isin : null,
      idOverride: instrument.id,
    );
    final periodSeries = await _loadInstrumentWithAllTimeExtremes(
      candidate,
      timeframe: timeframe,
    );
    final loaded = periodSeries.copyWith(
      isin: instrument.isin,
      defaultVenue: instrument.defaultVenue,
      venues: instrument.venues,
      venueSymbols: instrument.venueSymbols,
    );
    _instruments[loaded.id] = loaded;
    return loaded;
  }

  @override
  Future<Instrument> loadVenue(Instrument instrument, String venue) async {
    final symbol = instrument.venueSymbols[venue];
    if (symbol == null || symbol.isEmpty) {
      throw const MarketDataException(
        'Fuer diesen Handelsplatz liegt kein bestaetigtes Kurssymbol vor.',
      );
    }
    if (venue == instrument.defaultVenue &&
        symbol == instrument.selectedSymbol) {
      return instrument;
    }
    final candidate = _QuoteCandidate(
      symbol: symbol,
      name: instrument.name,
      venue: venue,
      assetType: instrument.assetType,
      isin: _hasIsinShape(instrument.isin) ? instrument.isin : null,
      idOverride: instrument.id,
    );
    final loaded = await _loadInstrumentWithAllTimeExtremes(
      candidate,
      timeframe: instrument.timeframe,
    );
    final updated = loaded.copyWith(
      isin: instrument.isin,
      defaultVenue: venue,
      venues: instrument.venues,
      venueSymbols: instrument.venueSymbols,
    );
    _instruments[updated.id] = updated;
    return updated;
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
      if (type != 'EQUITY' && type != 'ETF' && type != 'CRYPTOCURRENCY') {
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
        _QuoteCandidate(
          symbol: symbol,
          name: name,
          venue: venue,
          assetType: _assetTypeForQuote(type),
        ),
      );
    }
    return _deduplicate(results);
  }

  Future<List<_QuoteCandidate>> _mapIsinWithOpenFigi(String isin) async {
    final uri = Uri.https('api.openfigi.com', '/v3/mapping');
    final response = await _postOpenFigi(
      uri,
      jsonEncode([
        <String, String>{'idType': 'ID_ISIN', 'idValue': isin},
      ]),
    );
    if (response.statusCode != 200) {
      throw MarketDataException(
        'Die ISIN-Zuordnung ist derzeit nicht erreichbar (${response.statusCode}).',
      );
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
          assetType: _assetTypeForFigi(item),
          isin: isin,
        ),
      );
    }
    return _deduplicate(results);
  }

  Future<List<_QuoteCandidate>> _searchOpenFigi(String query) async {
    final uri = Uri.https('api.openfigi.com', '/v3/search');
    final response = await _postOpenFigi(
      uri,
      jsonEncode(<String, Object?>{
        'query': query,
        'marketSecDes': 'Equity',
      }),
    );
    if (response.statusCode != 200) {
      throw MarketDataException(
        'Die Wertpapierzuordnung ist derzeit nicht erreichbar (${response.statusCode}).',
      );
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
          assetType: _assetTypeForFigi(item),
        ),
      );
    }
    return _deduplicate(results);
  }

  Future<http.Response> _postOpenFigi(Uri uri, String body) async {
    http.Response? lastResponse;
    for (var attempt = 0; attempt < 3; attempt++) {
      final response = await _client
          .post(
            uri,
            headers: <String, String>{
              ..._headers,
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 12));
      lastResponse = response;
      final retryable = response.statusCode == 429 ||
          (response.statusCode >= 500 && response.statusCode < 600);
      if (!retryable || attempt == 2) {
        if (response.statusCode == 429) {
          throw const MarketDataException(
            'Das kostenlose ISIN-Limit ist gerade erreicht. Bitte warte kurz und versuche es erneut.',
          );
        }
        return response;
      }
      final reset = double.tryParse(
        response.headers['ratelimit-reset'] ?? '',
      );
      final retryAfter = double.tryParse(
        response.headers['retry-after'] ?? '',
      );
      final requestedSeconds =
          reset?.ceil() ?? retryAfter?.ceil() ?? math.pow(2, attempt).toInt();
      final seconds = requestedSeconds.clamp(1, 60).toInt();
      await _delay(Duration(seconds: seconds));
    }
    return lastResponse!;
  }

  Future<Instrument> _loadInstrument(
    _QuoteCandidate candidate, {
    ChartTimeframe timeframe = ChartTimeframe.maximum,
    bool refreshFx = false,
  }) async {
    if (candidate.symbol.startsWith('KRAKEN:')) {
      return KrakenMarketData(_client, _now).load(
          candidate.symbol.substring('KRAKEN:'.length), timeframe,
          id: candidate.idOverride);
    }
    final uri = Uri.https(
      'query1.finance.yahoo.com',
      '/v8/finance/chart/${candidate.symbol}',
      <String, String>{
        'interval': timeframe.interval,
        'range': timeframe.range,
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
    final fxRate = await _eurRate(
      currencyInfo.currency,
      forceRefresh: refreshFx,
    );
    final conversion = currencyInfo.unitScale * fxRate;

    final indicators = _asMap(result['indicators']);
    final rawCloses = _extractCloses(indicators);
    if (rawCloses.isEmpty) {
      throw MarketDataException('Keine Kurswerte fuer ${candidate.symbol}.');
    }
    final points = _extractPricePoints(result, conversion: conversion);
    if (points.isEmpty) {
      throw MarketDataException(
          'Keine datierten Kurswerte fuer ${candidate.symbol}.');
    }
    final rawTime = meta['regularMarketTime'];
    final rawQuote = meta['regularMarketPrice'];
    final hasQuoteTime = rawTime is num &&
        rawTime.isFinite &&
        rawTime > 0 &&
        rawTime < 8640000000000 &&
        rawQuote is num &&
        rawQuote.isFinite &&
        rawQuote > 0;
    final marketPrice =
        hasQuoteTime ? rawQuote.toDouble() : points.last.euro / conversion;
    if (!marketPrice.isFinite || marketPrice <= 0) {
      throw MarketDataException('Ungültiger Kurs fuer ${candidate.symbol}.');
    }
    final timestamp = hasQuoteTime
        ? DateTime.fromMillisecondsSinceEpoch(
            rawTime.toInt() * 1000,
            isUtc: true,
          )
        : points.last.timestamp;
    final history = points.map((point) => point.euro).toList();
    final historyTimestamps = points.map((point) => point.timestamp).toList();
    final extremes = _extractExtremes(result, conversion: conversion);
    final currentEuro = marketPrice * conversion;
    if (timestamp.isAfter(historyTimestamps.last)) {
      history.add(currentEuro);
      historyTimestamps.add(timestamp);
    } else if (timestamp == historyTimestamps.last) {
      history[history.length - 1] = currentEuro;
    }
    final venue = (meta['fullExchangeName'] as String?) ??
        (meta['exchangeName'] as String?) ??
        candidate.venue;
    final name = (meta['longName'] as String?) ??
        (meta['shortName'] as String?) ??
        candidate.name;
    final venueSymbols = <String, String>{venue: candidate.symbol};
    final closeHigh = history.reduce(math.max);
    final closeLow = history.reduce(math.min);

    return Instrument(
      id: candidate.idOverride ?? candidate.symbol.toLowerCase(),
      name: name,
      ticker: candidate.symbol,
      isin: candidate.isin ?? 'Nicht verfügbar',
      defaultVenue: venue,
      venues: venueSymbols.keys.toList(growable: false),
      venueSymbols: venueSymbols,
      originalCurrency: currencyInfo.currency,
      originalPrice: marketPrice * currencyInfo.unitScale,
      euroPrice: currentEuro,
      fxRate: fxRate,
      athEuro: math.max(currentEuro, extremes.high ?? closeHigh),
      atlEuro: math.min(currentEuro, extremes.low ?? closeLow),
      dataTimestamp: timestamp,
      historyEuro: history,
      historyTimestamps: historyTimestamps,
      candlesEuro: _extractCandles(result, conversion: conversion),
      assetType: candidate.assetType,
      timeframe: timeframe,
      dataSource: 'Yahoo Finance · $venue · ${candidate.symbol}',
      dataDelay: hasQuoteTime
          ? _dataDelayText(meta, candidate.assetType)
          : 'Letzter gültiger Chartwert; aktueller Kurs oder Kurszeitpunkt fehlt beim Anbieter.',
      isLive: true,
    );
  }

  List<PriceCandle> _extractCandles(Map<String, Object?> result,
      {required double conversion}) {
    final times = result['timestamp'];
    final indicators = _asMap(result['indicators']);
    final quotes = indicators['quote'];
    if (times is! List || quotes is! List || quotes.isEmpty) return [];
    final quote = _asMap(quotes.first);
    final columns =
        ['open', 'high', 'low', 'close'].map((key) => quote[key]).toList();
    if (columns.any((column) => column is! List)) return [];
    final adjusted = indicators['adjclose'];
    final adjustedValues = adjusted is List && adjusted.isNotEmpty
        ? _asMap(adjusted.first)['adjclose']
        : null;
    final candles = <PriceCandle>[];
    for (var i = 0; i < times.length; i++) {
      if (times[i] is! num ||
          !(times[i] as num).isFinite ||
          (times[i] as num) <= 0 ||
          (times[i] as num) >= 8640000000000 ||
          columns.any(
              (column) => i >= (column as List).length || column[i] is! num)) {
        continue;
      }
      final raw = columns
          .map((column) => ((column as List)[i] as num).toDouble())
          .toList();
      var factor = conversion;
      if (adjustedValues is List &&
          i < adjustedValues.length &&
          adjustedValues[i] is num &&
          raw[3] > 0) {
        factor *= (adjustedValues[i] as num).toDouble() / raw[3];
      }
      final candle = PriceCandle(
          timestamp: DateTime.fromMillisecondsSinceEpoch(
              (times[i] as num).toInt() * 1000,
              isUtc: true),
          open: raw[0] * factor,
          high: raw[1] * factor,
          low: raw[2] * factor,
          close: raw[3] * factor);
      if (candle.isValid &&
          (candles.isEmpty ||
              candle.timestamp.isAfter(candles.last.timestamp))) {
        candles.add(candle);
      }
    }
    return candles;
  }

  Future<Instrument> _loadInstrumentWithAllTimeExtremes(
    _QuoteCandidate candidate, {
    required ChartTimeframe timeframe,
    bool refreshFx = false,
  }) async {
    final selected = await _loadInstrument(
      candidate,
      timeframe: timeframe,
      refreshFx: refreshFx,
    );
    if (timeframe == ChartTimeframe.maximum ||
        candidate.symbol.startsWith('KRAKEN:')) {
      return selected;
    }
    final allTime = await _loadInstrument(candidate);
    return selected.copyWith(
      athEuro: allTime.athEuro,
      atlEuro: allTime.atlEuro,
    );
  }

  List<PricePoint> _extractPricePoints(
    Map<String, Object?> result, {
    required double conversion,
  }) {
    final timestamps = result['timestamp'];
    if (timestamps is! List<Object?> || timestamps.isEmpty) {
      return const <PricePoint>[];
    }
    final indicators = _asMap(result['indicators']);
    List<Object?>? values;
    final adjusted = indicators['adjclose'];
    if (adjusted is List<Object?> && adjusted.isNotEmpty) {
      values = _asMap(adjusted.first)['adjclose'] as List<Object?>?;
    }
    final quotes = indicators['quote'];
    if ((values == null || values.isEmpty) &&
        quotes is List<Object?> &&
        quotes.isNotEmpty) {
      values = _asMap(quotes.first)['close'] as List<Object?>?;
    }
    if (values == null || values.isEmpty) {
      return const <PricePoint>[];
    }
    final points = <PricePoint>[];
    final length = math.min(timestamps.length, values.length);
    for (var index = 0; index < length; index++) {
      final rawTime = timestamps[index];
      final rawValue = values[index];
      if (rawTime is! num || rawValue is! num) {
        continue;
      }
      if (!rawTime.isFinite || rawTime <= 0 || rawTime >= 8640000000000) {
        continue;
      }
      final value = rawValue.toDouble();
      if (!value.isFinite || value <= 0) {
        continue;
      }
      points.add(
        PricePoint(
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            rawTime.toInt() * 1000,
            isUtc: true,
          ),
          euro: value * conversion,
        ),
      );
    }
    if (points.isEmpty) {
      return const <PricePoint>[];
    }
    final unique = {for (final point in points) point.timestamp: point};
    return unique.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  _Extremes _extractExtremes(
    Map<String, Object?> result, {
    required double conversion,
  }) {
    final indicators = _asMap(result['indicators']);
    final quotes = indicators['quote'];
    if (quotes is! List<Object?> || quotes.isEmpty) {
      return const _Extremes();
    }
    final quote = _asMap(quotes.first);
    final highs = quote['high'];
    final lows = quote['low'];
    final closes = quote['close'];
    if (highs is! List<Object?> || lows is! List<Object?>) {
      return const _Extremes();
    }
    List<Object?>? adjustedCloses;
    final adjusted = indicators['adjclose'];
    if (adjusted is List<Object?> && adjusted.isNotEmpty) {
      adjustedCloses = _asMap(adjusted.first)['adjclose'] as List<Object?>?;
    }
    double? highest;
    double? lowest;
    final length = math.min(highs.length, lows.length);
    for (var index = 0; index < length; index++) {
      final rawHigh = highs[index];
      final rawLow = lows[index];
      if (rawHigh is! num || rawLow is! num) {
        continue;
      }
      var adjustment = 1.0;
      if (closes is List<Object?> &&
          adjustedCloses is List<Object?> &&
          index < closes.length &&
          index < adjustedCloses.length &&
          closes[index] is num &&
          adjustedCloses[index] is num) {
        final close = (closes[index]! as num).toDouble();
        final adjustedClose = (adjustedCloses[index]! as num).toDouble();
        if (close > 0 && adjustedClose > 0) {
          adjustment = adjustedClose / close;
        }
      }
      final high = rawHigh.toDouble() * adjustment * conversion;
      final low = rawLow.toDouble() * adjustment * conversion;
      if (!high.isFinite || !low.isFinite || high <= 0 || low <= 0) {
        continue;
      }
      highest = highest == null ? high : math.max(highest, high);
      lowest = lowest == null ? low : math.min(lowest, low);
    }
    return _Extremes(high: highest, low: lowest);
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

  Future<double> _eurRate(
    String currency, {
    bool forceRefresh = false,
  }) async {
    if (currency == 'EUR') {
      return 1;
    }
    final cached = _fxRates[currency];
    if (!forceRefresh &&
        cached != null &&
        _now().difference(cached.loadedAt) < fxCacheTtl) {
      return cached.rate;
    }

    final pending = _fxRequests[currency];
    if (pending != null) {
      return pending;
    }

    final request = _fetchEurRate(currency);
    _fxRequests[currency] = request;
    try {
      final rate = await request;
      _fxRates[currency] = _FxRateCacheEntry(
        rate: rate,
        loadedAt: _now(),
      );
      return rate;
    } finally {
      if (identical(_fxRequests[currency], request)) {
        _fxRequests.remove(currency);
      }
    }
  }

  Future<double> _fetchEurRate(String currency) async {
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
    if (price != null && price.isFinite && price > 0) {
      return price;
    }
    final closes = _extractCloses(_asMap(result['indicators']));
    if (closes.isEmpty) {
      throw MarketDataException('EUR-Umrechnung fuer $currency fehlt.');
    }
    return closes.last;
  }

  static Map<String, Object?> _asMap(Object? value) {
    if (value is Map<Object?, Object?>) {
      return Map<String, Object?>.from(value);
    }
    return const <String, Object?>{};
  }

  static bool _hasIsinShape(String value) =>
      RegExp(r'^[A-Za-z]{2}[A-Za-z0-9]{9}[0-9]$').hasMatch(value.trim());

  static bool isValidIsin(String value) {
    final normalized = value.trim().toUpperCase();
    if (!_hasIsinShape(normalized)) {
      return false;
    }
    final digits = StringBuffer();
    for (final codeUnit in normalized.codeUnits) {
      if (codeUnit >= 48 && codeUnit <= 57) {
        digits.writeCharCode(codeUnit);
      } else if (codeUnit >= 65 && codeUnit <= 90) {
        digits.write(codeUnit - 55);
      } else {
        return false;
      }
    }
    final expanded = digits.toString();
    var sum = 0;
    var doubleDigit = false;
    for (var index = expanded.length - 1; index >= 0; index--) {
      var digit = int.parse(expanded[index]);
      if (doubleDigit) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      sum += digit;
      doubleDigit = !doubleDigit;
    }
    return sum % 10 == 0;
  }

  static AssetType _assetTypeForQuote(String quoteType) {
    switch (quoteType.toUpperCase()) {
      case 'CRYPTOCURRENCY':
        return AssetType.crypto;
      case 'ETF':
        return AssetType.etf;
      default:
        return AssetType.stock;
    }
  }

  static AssetType _assetTypeForFigi(Map<String, Object?> item) {
    final description = <String>[
      item['securityType']?.toString() ?? '',
      item['securityType2']?.toString() ?? '',
      item['securityDescription']?.toString() ?? '',
    ].join(' ').toUpperCase();
    return description.contains('ETF') || description.contains('FUND')
        ? AssetType.etf
        : AssetType.stock;
  }

  static String _dataDelayText(
    Map<String, Object?> meta,
    AssetType assetType,
  ) {
    if (assetType == AssetType.crypto) {
      return '24/7-Markt; Datenstand laut Anbieter';
    }
    final seconds = (meta['exchangeDataDelayedBy'] as num?)?.toInt() ?? 0;
    if (seconds <= 0) {
      return 'Datenstand laut Anbieter; Echtzeitstatus nicht garantiert';
    }
    return 'Verzögert laut Anbieter; genaue Verzögerung nicht bestätigt. Kurszeitpunkt beachten.';
  }

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
    if (normalized == 'GBX' || rawCurrency == 'GBp') {
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

  static String _legacySymbolForVenue(String ticker, String venueName) {
    if (ticker.contains('.') || ticker.contains('=')) {
      return ticker;
    }
    final venue = venueName.toUpperCase();
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
    required this.assetType,
    this.isin,
    this.idOverride,
  });

  final String symbol;
  final String name;
  final String venue;
  final AssetType assetType;
  final String? isin;
  final String? idOverride;

  _QuoteCandidate copyWith({String? isin, String? idOverride}) =>
      _QuoteCandidate(
        symbol: symbol,
        name: name,
        venue: venue,
        assetType: assetType,
        isin: isin ?? this.isin,
        idOverride: idOverride ?? this.idOverride,
      );
}

class _Extremes {
  const _Extremes({this.high, this.low});

  final double? high;
  final double? low;
}

class _FxRateCacheEntry {
  const _FxRateCacheEntry({
    required this.rate,
    required this.loadedAt,
  });

  final double rate;
  final DateTime loadedAt;
}

class _CurrencyInfo {
  const _CurrencyInfo(this.currency, this.unitScale);

  final String currency;
  final double unitScale;
}
