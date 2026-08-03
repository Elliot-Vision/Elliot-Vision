import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elliott_vision/elliott_vision.dart';

void main() {
  testWidgets('Startseite und Analyse sind erreichbar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState(
      marketData: DemoMarketDataRepository(),
      analysisGateway: RuleBasedDemoAnalysisGateway(),
      store: SharedPreferencesLocalStore(),
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
