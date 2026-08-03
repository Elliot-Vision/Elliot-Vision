import 'package:elliott_vision/src/analysis_engine.dart';
import 'package:elliott_vision/src/app_state.dart';
import 'package:elliott_vision/src/demo_data.dart';
import 'package:elliott_vision/src/local_store.dart';
import 'package:elliott_vision/src/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Favoriten, Position und Snapshot werden gespeichert', () async {
    final store = _MemoryStore();
    final state = AppState(
      marketData: DemoMarketDataRepository(),
      analysisGateway: RuleBasedDemoAnalysisGateway(),
      store: store,
    );
    await state.initialize();

    await state.toggleFavorite('uec');
    await state.addHolding(
      Holding(
        id: 'holding-1',
        instrumentId: 'uec',
        purchaseDate: DateTime.utc(2026, 7, 1),
        purchasePriceEuro: 8.20,
        quantity: 10,
      ),
    );
    await state.saveAnalysis(
      state.analyze(
        state.marketData.byId('uec'),
        now: DateTime.utc(2026, 8, 3),
      ),
    );

    expect(state.isFavorite('uec'), isTrue);
    expect(state.holdings, hasLength(1));
    expect(state.history, hasLength(1));
    expect(store.favoriteIds, contains('uec'));
    expect(store.holdings.single.quantity, 10);
    expect(store.history.single.instrumentId, 'uec');
  });
}

class _MemoryStore implements LocalStore {
  Set<String> favoriteIds = {};
  List<Holding> holdings = [];
  List<AnalysisResult> history = [];

  @override
  Future<Set<String>> loadFavorites() async => Set.of(favoriteIds);

  @override
  Future<List<Holding>> loadHoldings() async => List.of(holdings);

  @override
  Future<List<AnalysisResult>> loadHistory() async => List.of(history);

  @override
  Future<void> saveFavorites(Set<String> ids) async {
    favoriteIds = Set.of(ids);
  }

  @override
  Future<void> saveHoldings(List<Holding> value) async {
    holdings = List.of(value);
  }

  @override
  Future<void> saveHistory(List<AnalysisResult> value) async {
    history = List.of(value);
  }
}
