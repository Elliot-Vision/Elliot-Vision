import 'package:elliott_vision/elliott_vision.dart';
import 'package:elliott_vision/src/experimental_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Test-Tab isoliert Demochart und erhält reguläre Navigation',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final state = AppState(
      marketData: DemoMarketDataRepository(),
      analysisGateway: RuleBasedAnalysisGateway(),
      store: SharedPreferencesLocalStore(),
    );
    await state.initialize();
    await tester.pumpWidget(ElliottVisionApp(state: state));
    final prefs = await SharedPreferences.getInstance();
    final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
    expect(find.byType(NavigationDestination), findsNWidgets(6));
    expect(find.byType(ExperimentalScenarioChart), findsNothing);
    await tester.tap(find.byIcon(Icons.science_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Testbereich'), findsOneWidget);
    expect(find.byType(ExperimentalScenarioChart), findsOneWidget);
    expect(find.byType(ElliottScenarioChart), findsNothing);
    await tester.tap(find.byKey(const ValueKey('chart-reset-zoom')));
    await tester.pumpAndSettle();
    expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
    expect(state.holdings, isEmpty);
    expect(state.history, isEmpty);
    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Szenarien statt\nScheinsicherheit.'), findsOneWidget);
    expect(find.byType(ExperimentalScenarioChart), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
