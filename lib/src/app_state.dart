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
  bool _initialized = false;

  bool get initialized => _initialized;
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  List<Holding> get holdings => List.unmodifiable(_holdings);
  List<AnalysisResult> get history => List.unmodifiable(_history);

  List<Instrument> get favoriteInstruments => marketData.instruments
      .where((instrument) => _favoriteIds.contains(instrument.id))
      .toList();

  Future<void> initialize() async {
    _favoriteIds = await store.loadFavorites();
    _holdings = await store.loadHoldings();
    _history = await store.loadHistory();
    _history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _initialized = true;
    notifyListeners();
  }

  List<Instrument> search(String query) => marketData.search(query);

  bool isFavorite(String instrumentId) => _favoriteIds.contains(instrumentId);

  AnalysisResult analyze(Instrument instrument, {DateTime? now}) =>
      analysisGateway.analyze(instrument, now: now);

  Future<void> toggleFavorite(String instrumentId) async {
    if (!_favoriteIds.add(instrumentId)) {
      _favoriteIds.remove(instrumentId);
    }
    notifyListeners();
    await store.saveFavorites(_favoriteIds);
  }

  Future<void> addHolding(Holding holding) async {
    _holdings = [holding, ..._holdings];
    notifyListeners();
    await store.saveHoldings(_holdings);
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
  }
}
