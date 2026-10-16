import 'package:elliott_vision/elliott_vision.dart';
import 'package:elliott_vision/src/experimental_chart.dart';
import 'package:elliott_vision/src/test_screen.dart';
import 'package:elliott_vision/src/price_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Test-Reiter wechseln und erhalten Demo-Auswahl und Filter',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: TestScreen())));
    final zones = find.byKey(const ValueKey('test-zones'));
    await tester.scrollUntilVisible(zones, 150);
    await tester.pumpAndSettle();
    await tester.tap(zones);
    await tester.pumpAndSettle();
    final tabs = find.byKey(const ValueKey('test-analysis-tabs'));
    await tester.scrollUntilVisible(tabs, -150);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Price Action'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('test-price-action-preview')),
        findsOneWidget);
    expect(find.byType(ExperimentalScenarioChart), findsNothing);
    await tester.tap(find.byKey(const ValueKey('test-timeframe')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 Tag').last);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<PriceActionPanel>(find.byType(PriceActionPanel))
            .instrument
            .timeframe,
        ChartTimeframe.oneDay);
    await tester.tap(find.text('Elliott-Wellen'));
    await tester.pumpAndSettle();
    final chart = tester.widget<ExperimentalScenarioChart>(
        find.byType(ExperimentalScenarioChart));
    expect(chart.instrument.timeframe, ChartTimeframe.oneDay);
    expect(chart.showZones, isFalse);
    expect(chart.visibleScenarioIds.length, 2);
    expect(tester.takeException(), isNull);
  });

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
    await tester.ensureVisible(find.byKey(const ValueKey('chart-reset-zoom')));
    await tester.pumpAndSettle();
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

  testWidgets(
      'Demo-Auswahl wechselt Instrument und stellt vollständigen Zeitraum wieder her',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: TestScreen())));
    ExperimentalScenarioChart chart() =>
        tester.widget(find.byType(ExperimentalScenarioChart));
    final originalCount = chart().instrument.pricePoints.length;
    await tester.tap(find.byKey(const ValueKey('test-timeframe')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 Tag').last);
    await tester.pumpAndSettle();
    expect(chart().instrument.timeframe, ChartTimeframe.oneDay);
    expect(chart().instrument.pricePoints.length, 289);
    expect(
        chart()
            .instrument
            .pricePoints
            .last
            .timestamp
            .difference(chart().instrument.pricePoints.first.timestamp),
        const Duration(days: 1));
    await tester.tap(find.byKey(const ValueKey('test-timeframe')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Max').last);
    await tester.pumpAndSettle();
    expect(chart().instrument.pricePoints.length, originalCount);
    expect(
        chart()
            .instrument
            .pricePoints
            .last
            .timestamp
            .difference(chart().instrument.pricePoints.first.timestamp),
        const Duration(days: 3650));
    await tester.tap(find.byKey(const ValueKey('test-instrument')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Microsoft Corp. (MSFT)').last);
    await tester.pumpAndSettle();
    expect(chart().instrument.id, 'msft');
    expect(chart().instrument.timeframe, ChartTimeframe.maximum);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Szenarien und Zonen bleiben beim Instrumentwechsel ausgewählt',
      (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: TestScreen())));
    ExperimentalScenarioChart chart() =>
        tester.widget(find.byType(ExperimentalScenarioChart));
    expect(chart().visibleScenarioIds.length, 2);
    expect(chart().visibleScenarioIds,
        contains(chart().analysis.primaryScenarioId));
    final offeredKinds = chart()
        .analysis
        .scenarios
        .where((s) => chart().visibleScenarioIds.contains(s.id))
        .map((s) => s.kind)
        .toList();
    for (final kind in offeredKinds) {
      final chip = find.byKey(ValueKey('test-scenario-${kind.name}'));
      await tester.scrollUntilVisible(chip, 150);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }
    expect(chart().visibleScenarioIds, isEmpty);
    final zones = find.byKey(const ValueKey('test-zones'));
    await tester.scrollUntilVisible(zones, 150);
    await tester.pumpAndSettle();
    await tester.tap(zones);
    await tester.pumpAndSettle();
    expect(chart().showZones, isFalse);
    final instrument = find.byKey(const ValueKey('test-instrument'));
    await tester.scrollUntilVisible(instrument, -150);
    await tester.pumpAndSettle();
    await tester.tap(instrument);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Microsoft Corp. (MSFT)').last);
    await tester.pumpAndSettle();
    expect(chart().visibleScenarioIds, isEmpty);
    expect(chart().showZones, isFalse);
    final bullish = find.byKey(const ValueKey('test-scenario-bullish'));
    await tester.scrollUntilVisible(bullish, 150);
    await tester.pumpAndSettle();
    await tester.tap(bullish);
    await tester.pumpAndSettle();
    expect(chart().visibleScenarioIds.length, 1);
    expect(
        chart()
            .analysis
            .scenarios
            .singleWhere((s) => chart().visibleScenarioIds.contains(s.id))
            .kind,
        ScenarioKind.bullish);
    expect(tester.takeException(), isNull);
  });
}
