import 'package:elliott_vision/src/analysis_engine.dart';
import 'package:elliott_vision/src/app.dart';
import 'package:elliott_vision/src/app_state.dart';
import 'package:elliott_vision/src/chart.dart';
import 'package:elliott_vision/src/demo_data.dart';
import 'package:elliott_vision/src/local_store.dart';
import 'package:elliott_vision/src/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Startseite und Analyse sind erreichbar', (tester) async {
    final state = AppState(
      marketData: DemoMarketDataRepository(),
      analysisGateway: RuleBasedDemoAnalysisGateway(),
      store: _EmptyStore(),
    );
    await state.initialize();

    await tester.pumpWidget(ElliottVisionApp(state: state));
    expect(find.text('Elliott Vision'), findsOneWidget);
    expect(find.text('Szenarien statt\nScheinsicherheit.'), findsOneWidget);

    await tester.tap(find.text('Apple Inc.'));
    await tester.pumpAndSettle();

    expect(find.text('Apple Inc.'), findsOneWidget);
    expect(find.text('Handelsplatz'), findsOneWidget);
    expect(find.byType(ElliottScenarioChart), findsOneWidget);
  });
}

class _EmptyStore implements LocalStore {
  @override
  Future<Set<String>> loadFavorites() async => {};

  @override
  Future<List<Holding>> loadHoldings() async => [];

  @override
  Future<List<AnalysisResult>> loadHistory() async => [];

  @override
  Future<void> saveFavorites(Set<String> ids) async {}

  @override
  Future<void> saveHoldings(List<Holding> holdings) async {}

  @override
  Future<void> saveHistory(List<AnalysisResult> history) async {}
}
