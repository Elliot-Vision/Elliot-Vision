import 'dart:async';

import 'package:flutter/foundation.dart';

import 'analysis_engine.dart';
import 'demo_data.dart';
import 'local_store.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.marketData,
    required this.analysisGateway,
    required this.store,
  });

  final MarketDataRepository marketData;
  final AnalysisGateway analysisGateway;
  final LocalStore store;

  Set<String> _favoriteIds = {};
  List<Holding> _holdings = [];
  List<AnalysisResult> _history = [];
  List<Instrument> _searchResults = [];
  bool _initialized = false;
  bool _isSearching = false;
  bool _isRefreshingPortfolio = false;
  String? _searchError;
  String? _portfolioError;
  int _searchRequest = 0;

  bool get initialized => _initialized;
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  List<Holding> get holdings => List.unmodifiable(_holdings);
  List<AnalysisResult> get history => List.unmodifiable(_history);
  List<Instrument> get searchResults => List.unmodifiable(_searchResults);
  bool get isSearching => _isSearching;
  bool get isRefreshingPortfolio => _isRefreshingPortfolio;
  String? get searchError => _searchError;
  String? get portfolioError => _portfolioError;

  List<Instrument> get favoriteInstruments => _favoriteIds
      .map(marketData.findById)
      .whereType<Instrument>()
      .toList();

  Future<void> initialize() async {
    marketData.restore(await store.loadInstruments());
    _favoriteIds = await store.loadFavorites();
    _holdings = await store.loadHoldings();
    _history = await store.loadHistory();
    _history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _initialized = true;
    notifyListeners();
    if (_holdings.isNotEmpty || _favoriteIds.isNotEmpty) {
      unawaited(refreshPortfolio());
    }
  }

  Instrument? instrumentById(String id) => marketData.findById(id);

  Future<void> search(String query) async {
    final normalized = query.trim();
    final request = ++_searchRequest;
    if (normalized.isEmpty) {
      clearSearch();
      return;
    }

    _isSearching = true;
    _searchError = null;
    notifyListeners();
    try {
      final results = await marketData.search(normalized);
      if (request != _searchRequest) {
        return;
      }
      _searchResults = results;
      await store.saveInstruments(marketData.instruments);
    } on Object {
      if (request != _searchRequest) {
        return;
      }
      _searchResults = [];
      _searchError =
          'Die Online-Suche ist gerade nicht erreichbar. Prüfe die Internetverbindung und versuche es erneut.';
    } finally {
      if (request == _searchRequest) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  void clearSearch() {
    _searchRequest++;
    _searchResults = [];
    _searchError = null;
    _isSearching = false;
    notifyListeners();
  }

  bool isFavorite(String instrumentId) => _favoriteIds.contains(instrumentId);

  AnalysisResult analyze(Instrument instrument, {DateTime? now}) =>
      analysisGateway.analyze(instrument, now: now);

  Future<void> toggleFavorite(String instrumentId) async {
    if (!_favoriteIds.add(instrumentId)) {
      _favoriteIds.remove(instrumentId);
    }
    notifyListeners();
    await store.saveFavorites(_favoriteIds);
    await store.saveInstruments(marketData.instruments);
  }

  Future<void> addHolding(Holding holding) async {
    _holdings = [holding, ..._holdings];
    notifyListeners();
    await store.saveHoldings(_holdings);
    await store.saveInstruments(marketData.instruments);
    unawaited(refreshPortfolio());
  }

  Future<void> removeHolding(String holdingId) async {
    _holdings = _holdings.where((holding) => holding.id != holdingId).toList();
    notifyListeners();
    await store.saveHoldings(_holdings);
  }

  Future<void> saveAnalysis(AnalysisResult result) async {
    _history = [result, ..._history.where((item) => item.id != result.id)];
    notifyListeners();
    await store.saveHistory(_history);
    await store.saveInstruments(marketData.instruments);
  }

  Future<void> refreshPortfolio() async {
    if (_isRefreshingPortfolio ||
        (_holdings.isEmpty && _favoriteIds.isEmpty)) {
      return;
    }
    _isRefreshingPortfolio = true;
    _portfolioError = null;
    notifyListeners();

    try {
      var refreshed = 0;
      final ids = <String>{
        ..._holdings.map((holding) => holding.instrumentId),
        ..._favoriteIds,
      };
      for (final id in ids) {
        final instrument = marketData.findById(id);
        if (instrument == null) {
          continue;
        }
        try {
          await marketData.refresh(instrument);
          refreshed++;
        } on Object {
          // Der zuletzt gespeicherte Kurs bleibt sichtbar, wenn ein einzelner
          // Handelsplatz voruebergehend nicht erreichbar ist.
        }
      }

      if (refreshed == 0) {
        _portfolioError =
            'Die Kurse konnten nicht aktualisiert werden. Angezeigt wird der zuletzt gespeicherte Datenstand.';
      } else {
        await store.saveInstruments(marketData.instruments);
      }
    } on Object {
      _portfolioError =
          'Der neue Kursstand konnte nicht gespeichert werden. Die bisherigen Werte bleiben erhalten.';
    } finally {
      _isRefreshingPortfolio = false;
      notifyListeners();
    }
  }
}
