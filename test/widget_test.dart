import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elliott_vision/elliott_vision.dart';

void main() {
  testWidgets('Analyse wechselt zwischen Elliott-Wellen und Price Action',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState(
        marketData: DemoMarketDataRepository(),
        analysisGateway: RuleBasedAnalysisGateway(),
        store: SharedPreferencesLocalStore());
    await state.initialize();
    await _pumpAppleAnalysis(tester, state);
    await _revealLazyListChild(tester,
        target: find.byKey(const ValueKey('analysis-mode-tabs')),
        scrollable: _scrollableInside('analysis-content-list'),
        dragOffset: const Offset(0, -200));
    await tester.tap(find.text('Price Action'));
    await tester.pumpAndSettle();
    expect(find.textContaining('fehlen vollständige OHLC'), findsOneWidget);
    expect(find.byType(ElliottScenarioChart), findsNothing);
    await tester.tap(find.text('Elliott-Wellen'));
    await tester.pumpAndSettle();
    await _revealLazyListChild(tester,
        target: find.byType(ElliottScenarioChart),
        scrollable: _scrollableInside('analysis-content-list'),
        dragOffset: const Offset(0, -200));
    expect(
        tester
            .widget<ElliottScenarioChart>(find.byType(ElliottScenarioChart))
            .visibleScenarioIds
            .length,
        3);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Reguläre Analyse verwendet interaktiven Chart mit eigenen Kursdaten',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState(
        marketData: DemoMarketDataRepository(),
        analysisGateway: RuleBasedAnalysisGateway(),
        store: SharedPreferencesLocalStore());
    await state.initialize();
    await _pumpAppleAnalysis(tester, state);
    await _revealLazyListChild(tester,
        target: find.byKey(const ValueKey('chart-gestures')),
        scrollable: _scrollableInside('analysis-content-list'),
        dragOffset: const Offset(0, -250));
    final chart =
        tester.widget<ElliottScenarioChart>(find.byType(ElliottScenarioChart));
    expect(chart.instrument.historyEuro,
        state.instrumentById('aapl')!.historyEuro);
    expect(chart.visibleScenarioIds.length, 3);
    expect(find.text('Kompakt'), findsNothing);
    expect(find.text('Standard'), findsNothing);
    expect(find.text('Experte'), findsNothing);
    final rect = tester.getRect(find.byKey(const ValueKey('chart-gestures')));
    final center = rect.topLeft + Offset(rect.width * 0.32, 150);
    final first =
        await tester.startGesture(center - const Offset(25, 0), pointer: 1);
    final second =
        await tester.startGesture(center + const Offset(25, 0), pointer: 2);
    await first.moveTo(center - const Offset(75, 0));
    await second.moveTo(center + const Offset(75, 0));
    await tester.pump();
    expect(find.text('Zurücksetzen (3.0×)'), findsOneWidget);
    await first.up();
    await second.up();
    await tester.pump(const Duration(milliseconds: 400));
    final finger = await tester.startGesture(center - const Offset(30, 0));
    await finger.moveTo(center + const Offset(30, 0));
    await tester.pump();
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('chart-inspection')))
            .data,
        contains('€ ·'));
    await finger.up();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });

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

    await _openAppleAnalysis(tester, state);

    expect(find.text('Apple Inc.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('venue-dropdown')),
      findsOneWidget,
    );
    final quoteTimestamp = find.byKey(const ValueKey('quote-timestamp'));
    expect(quoteTimestamp, findsOneWidget);
    expect(
      tester.widget<Text>(quoteTimestamp).data,
      startsWith('Kursstand '),
    );
    final chart = find.byType(ElliottScenarioChart);
    await tester.scrollUntilVisible(
      chart,
      250,
      scrollable: _scrollableInside('analysis-content-list'),
    );
    expect(chart, findsOneWidget);
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
    final analysisScroll = _scrollableInside('analysis-content-list');
    final chartPaint = find.byKey(const ValueKey('scenario-chart-paint'));
    final oldPainter = tester.widget<CustomPaint>(chartPaint).painter!;

    await _revealLazyListChild(
      tester,
      target: bullishChip(),
      scrollable: analysisScroll,
      dragOffset: const Offset(0, -300),
    );
    await tester.tap(bullishChip());
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(bullishChip()).selected, isFalse);

    // Der Chart liegt oberhalb der Filterchips und kann von der lazy
    // aufgebauten ListView nach dem Pumpen bereits entsorgt worden sein.
    // Vor dem Zugriff muss er deshalb wieder in den Widget-Baum gescrollt
    // werden. Ein direkter tester.widget-Aufruf auf einen leeren Finder war
    // die Ursache des Codemagic-Fehlers "Bad state: No element".
    await _revealLazyListChild(
      tester,
      target: chartPaint,
      scrollable: analysisScroll,
      dragOffset: const Offset(0, 300),
    );
    final newPainter = tester.widget<CustomPaint>(chartPaint).painter!;
    expect(
      newPainter.shouldRepaint(oldPainter),
      isTrue,
      reason: 'Das Ausblenden muss den Chart tatsaechlich neu zeichnen.',
    );

    final timeframeFinder = find.byKey(const ValueKey('timeframe-dropdown'));
    await _revealLazyListChild(
      tester,
      target: timeframeFinder,
      scrollable: analysisScroll,
      dragOffset: const Offset(0, 300),
    );
    final timeframe =
        tester.widget<DropdownButton<ChartTimeframe>>(timeframeFinder);
    timeframe.onChanged!(ChartTimeframe.oneMonth);
    await _pumpUntil(
      tester,
      () =>
          timeframeFinder.evaluate().isNotEmpty &&
          tester
                  .widget<DropdownButton<ChartTimeframe>>(timeframeFinder)
                  .value ==
              ChartTimeframe.oneMonth,
      reason: 'Der Zeitraumwechsel auf 1 Monat wurde nicht abgeschlossen.',
    );

    await _revealLazyListChild(
      tester,
      target: bullishChip(),
      scrollable: analysisScroll,
      dragOffset: const Offset(0, -300),
    );

    expect(tester.widget<FilterChip>(bullishChip()).selected, isFalse);
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
    await _pumpUntil(
      tester,
      () => find
          .textContaining('Zeitraum konnte nicht geladen')
          .evaluate()
          .isNotEmpty,
      reason: 'Der fehlgeschlagene Zeitraumwechsel wurde nicht angezeigt.',
    );

    final after = tester.widget<DropdownButton<ChartTimeframe>>(
      find.byKey(const ValueKey('timeframe-dropdown')),
    );
    expect(after.value, ChartTimeframe.maximum);
    expect(
        find.textContaining('Zeitraum konnte nicht geladen'), findsOneWidget);
  });
}

Future<void> _openAppleAnalysis(
  WidgetTester tester,
  AppState state,
) async {
  final searchField = find.byKey(const ValueKey('discover-search-field'));
  await tester.enterText(searchField, 'Apple');
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await _pumpUntil(
    tester,
    () =>
        !state.isSearching &&
        state.searchResults.any((instrument) => instrument.id == 'aapl'),
    reason: 'Die Apple-Suche wurde nicht vollständig abgeschlossen.',
  );

  final appleCard = find.byKey(const ValueKey('instrument-card-aapl'));
  await tester.scrollUntilVisible(
    appleCard,
    250,
    scrollable: _scrollableInside('discover-content-list'),
  );
  expect(appleCard, findsOneWidget);
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

Finder _scrollableInside(String listKey) => find
    .descendant(
      of: find.byKey(ValueKey<String>(listKey)),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _revealLazyListChild(
  WidgetTester tester, {
  required Finder target,
  required Finder scrollable,
  required Offset dragOffset,
}) async {
  for (var attempt = 0; attempt < 12; attempt++) {
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      expect(target, findsOneWidget);
      return;
    }
    await tester.drag(scrollable, dragOffset);
    await tester.pumpAndSettle();
  }
  expect(
    target,
    findsOneWidget,
    reason: 'Das erwartete Listenelement wurde nicht aufgebaut.',
  );
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String reason,
}) async {
  for (var attempt = 0; attempt < 30 && !condition(); attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(condition(), isTrue, reason: reason);
  await tester.pump();
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
