import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elliott_vision/elliott_vision.dart';

void main() {
  testWidgets('Startseite und Analyse sind erreichbar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState(
      marketData: DemoMarketDataRepository(),
      analysisGateway: RuleBasedAnalysisGateway(),
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

    await _openAppleAnalysis(tester);

    expect(find.text('Apple Inc.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('venue-dropdown')),
      findsOneWidget,
    );
    expect(find.textContaining('Kursstand'), findsOneWidget);
    expect(find.byType(ElliottScenarioChart), findsOneWidget);
  });

  testWidgets('Depot und Wissen besitzen eigene Suchfelder', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState(
      marketData: DemoMarketDataRepository(),
      analysisGateway: RuleBasedAnalysisGateway(),
      store: SharedPreferencesLocalStore(),
    );
    await state.initialize();

    await tester.pumpWidget(ElliottVisionApp(state: state));

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
  });

  testWidgets('Szenarioauswahl bleibt beim Zeitraumwechsel erhalten',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState(
      marketData: DemoMarketDataRepository(),
      analysisGateway: RuleBasedAnalysisGateway(),
      store: SharedPreferencesLocalStore(),
    );
    await state.initialize();
    await _pumpAppleAnalysis(tester, state);

    Finder bullishChip() => find.byKey(
      const ValueKey('scenario-filter-pivot-impulse-bullish'),
    );

    await tester.ensureVisible(bullishChip());
    await tester.pumpAndSettle();
    await tester.tap(bullishChip());
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(bullishChip()).selected, isFalse);

    final timeframe = tester.widget<DropdownButton<ChartTimeframe>>(
      find.byKey(const ValueKey('timeframe-dropdown')),
    );
    timeframe.onChanged!(ChartTimeframe.oneMonth);
    await tester.pumpAndSettle();

    expect(tester.widget<FilterChip>(bullishChip()).selected, isFalse);
    expect(
      tester
          .widget<DropdownButton<ChartTimeframe>>(
            find.byKey(const ValueKey('timeframe-dropdown')),
          )
          .value,
      ChartTimeframe.oneMonth,
    );
  });

  testWidgets('fehlgeschlagener Zeitraumwechsel aendert die Auswahl nicht',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState(
      marketData: _FailingSeriesRepository(),
      analysisGateway: RuleBasedAnalysisGateway(),
      store: SharedPreferencesLocalStore(),
    );
    await state.initialize();
    await _pumpAppleAnalysis(tester, state);

    final before = tester.widget<DropdownButton<ChartTimeframe>>(
      find.byKey(const ValueKey('timeframe-dropdown')),
    );
    expect(before.value, ChartTimeframe.maximum);
    before.onChanged!(ChartTimeframe.oneDay);
    await tester.pumpAndSettle();

    final after = tester.widget<DropdownButton<ChartTimeframe>>(
      find.byKey(const ValueKey('timeframe-dropdown')),
    );
    expect(after.value, ChartTimeframe.maximum);
    expect(find.textContaining('Zeitraum konnte nicht geladen'), findsOneWidget);
  });
}

Future<void> _openAppleAnalysis(WidgetTester tester) async {
  final searchField = find.byKey(const ValueKey('discover-search-field'));
  await tester.enterText(searchField, 'Apple');
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();

  final appleCard = find.byKey(const ValueKey('instrument-card-aapl'));
  expect(appleCard, findsOneWidget);
  await tester.ensureVisible(appleCard);
  await tester.pumpAndSettle();
  await tester.tap(appleCard);
  await tester.pumpAndSettle();

  expect(
    find.byKey(const ValueKey('analysis-screen')),
    findsOneWidget,
  );
}

Future<void> _pumpAppleAnalysis(
  WidgetTester tester,
  AppState state,
) async {
  final instrument = state.instrumentById('aapl');
  expect(instrument, isNotNull);
  await tester.pumpWidget(
    AppScope(
      notifier: state,
      child: MaterialApp(
        home: AnalysisScreen(instrument: instrument!),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('analysis-screen')), findsOneWidget);
}

class _FailingSeriesRepository extends DemoMarketDataRepository {
  @override
  Future<Instrument> loadSeries(
    Instrument instrument,
    ChartTimeframe timeframe,
  ) async {
    throw const MarketDataException('Testfehler');
  }
}
