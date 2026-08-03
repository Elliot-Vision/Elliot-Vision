import 'package:flutter/material.dart';
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
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).theme?.brightness,
      Brightness.dark,
    );
    expect(find.text('Elliott Vision'), findsOneWidget);
    expect(find.text('Szenarien statt\nScheinsicherheit.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Apple');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apple Inc.'));
    await tester.pumpAndSettle();

    expect(find.text('Apple Inc.'), findsOneWidget);
    expect(find.text('HANDELSPLATZ'), findsOneWidget);
    expect(find.textContaining('Kursstand'), findsOneWidget);
    expect(find.byType(ElliottScenarioChart), findsOneWidget);
  });

  testWidgets('Depot und Wissen besitzen eigene Suchfelder', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState(
      marketData: DemoMarketDataRepository(),
      analysisGateway: RuleBasedDemoAnalysisGateway(),
      store: SharedPreferencesLocalStore(),
    );
    await state.initialize();

    await tester.pumpWidget(ElliottVisionApp(state: state));

    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Position hinzufügen'));
    await tester.pumpAndSettle();

    final depotSearch = find.byKey(
      const ValueKey('holding-instrument-search'),
    );
    expect(depotSearch, findsOneWidget);
    await tester.enterText(depotSearch, 'US9168961038');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Uranium Energy Corp.'), findsOneWidget);
    expect(find.text('Apple Inc.'), findsNothing);

    Navigator.of(tester.element(depotSearch)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.school_outlined));
    await tester.pumpAndSettle();

    final knowledgeSearch = find.byKey(
      const ValueKey('knowledge-search-field'),
    );
    expect(knowledgeSearch, findsOneWidget);
    await tester.enterText(knowledgeSearch, 'Zigzag');
    await tester.pumpAndSettle();
    expect(find.text('KORREKTUREN'), findsOneWidget);
    expect(find.text('Flat und Expanded Flat'), findsNothing);
  });
}
