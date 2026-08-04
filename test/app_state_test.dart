import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elliott_vision/elliott_vision.dart';

void main() {
  test('Favoriten, Position und Snapshot werden gespeichert', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesLocalStore();
    final state = AppState(
      marketData: DemoMarketDataRepository(),
      analysisGateway: RuleBasedAnalysisGateway(),
      store: store,
    );
    await state.initialize();

    final depotResults = await state.searchInstruments('US9168961038');
    expect(depotResults.single.ticker, 'UEC');
    expect(state.searchResults, isEmpty);

    await state.search('US9168961038');
    expect(state.searchResults.single.ticker, 'UEC');

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
    expect(await store.loadFavorites(), contains('uec'));
    expect((await store.loadHoldings()).single.quantity, 10);
    expect((await store.loadHistory()).single.instrumentId, 'uec');
  });
}
