import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elliott_vision/elliott_vision.dart';
import 'package:elliott_vision/src/experimental_chart.dart';

void main() {
  test('kontinuierlicher Zoom bleibt am Fokus verankert und begrenzt', () {
    const full = ChartViewport();
    final zoomed = full.transform(
        initial: full, scale: 2.5, initialFocal: 0.4, currentFocal: 0.4);
    expect(zoomed.span, closeTo(0.4, 0.000001));
    expect(zoomed.start + 0.4 * zoomed.span, closeTo(0.4, 0.000001));
    final maximum = zoomed.transform(
        initial: zoomed, scale: 1000, initialFocal: 0.5, currentFocal: 0.5);
    expect(maximum.span, closeTo(0.05, 0.000001));
    final restored = zoomed.transform(
        initial: zoomed, scale: 0.001, initialFocal: 0.5, currentFocal: 0.5);
    expect(restored.start, 0);
    expect(restored.end, 1);
  });

  test('Verschieben stoppt an beiden Datenrändern', () {
    const viewport = ChartViewport(start: 0.2, end: 0.6);
    final left = viewport.transform(
        initial: viewport, scale: 1, initialFocal: 0.5, currentFocal: 4);
    final right = viewport.transform(
        initial: viewport, scale: 1, initialFocal: 0.5, currentFocal: -4);
    expect(left.start, 0);
    expect(right.end, 1);
    expect(left.span, closeTo(viewport.span, 0.000001));
    expect(right.span, closeTo(viewport.span, 0.000001));
  });

  testWidgets(
      'Pinch zeichnet neu; Filter erhält Zoom; Reset stellt Übersicht her',
      (tester) async {
    final instrument = DemoMarketDataRepository().byId('aapl');
    final analysis = RuleBasedAnalysisGateway().analyze(instrument);
    Future<void> show(Set<String> ids) => tester.pumpWidget(
          MaterialApp(
              home: Scaffold(
                  body: ExperimentalScenarioChart(
            instrument: instrument,
            analysis: analysis,
            visibleScenarioIds: ids,
            historyPoints: instrument.historyEuro.length,
          ))),
        );
    final ids = analysis.scenarios.map((value) => value.id).toSet();
    await show(ids);
    final paint = find.byKey(const ValueKey('scenario-chart-paint'));
    final before = tester.widget<CustomPaint>(paint).painter!;
    final center =
        tester.getCenter(find.byKey(const ValueKey('chart-gestures')));
    final first =
        await tester.startGesture(center - const Offset(30, 0), pointer: 1);
    final second =
        await tester.startGesture(center + const Offset(30, 0), pointer: 2);
    await tester.pump();
    await first.moveTo(center - const Offset(90, 0));
    await second.moveTo(center + const Offset(90, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pump();
    expect(tester.widget<CustomPaint>(paint).painter!.shouldRepaint(before),
        isTrue);
    final reset = find.byKey(const ValueKey('chart-reset-zoom'));
    String label() => tester
        .widget<Text>(find.descendant(
          of: reset,
          matching: find.byType(Text),
        ))
        .data!;
    final zoomLabel = label();
    expect(zoomLabel, isNot('Zurücksetzen (1.0×)'));
    await show(ids.where((value) => value != 'pivot-impulse-bullish').toSet());
    await tester.pump();
    expect(label(), zoomLabel);
    await tester.tap(reset);
    await tester.pump();
    expect(label(), 'Zurücksetzen (1.0×)');
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Zeitraumwechsel setzt den Ausschnitt zurück', (tester) async {
    var instrument = DemoMarketDataRepository().byId('aapl');
    Future<void> show() async {
      final analysis = RuleBasedAnalysisGateway().analyze(instrument);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: ExperimentalScenarioChart(
        instrument: instrument,
        analysis: analysis,
        visibleScenarioIds: analysis.scenarios.map((value) => value.id).toSet(),
        historyPoints: instrument.historyEuro.length,
      ))));
    }

    await show();
    final center =
        tester.getCenter(find.byKey(const ValueKey('chart-gestures')));
    final first =
        await tester.startGesture(center - const Offset(30, 0), pointer: 1);
    final second =
        await tester.startGesture(center + const Offset(30, 0), pointer: 2);
    await tester.pump();
    await first.moveTo(center - const Offset(90, 0));
    await second.moveTo(center + const Offset(90, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Zurücksetzen (3.0×)'), findsOneWidget);
    instrument = instrument.copyWith(timeframe: ChartTimeframe.oneMonth);
    await show();
    await tester.pump();
    expect(find.text('Zurücksetzen (1.0×)'), findsOneWidget);
  });
  testWidgets('Vertikaler Einfinger-Drag über Chart scrollt die Seite',
      (tester) async {
    final instrument = DemoMarketDataRepository().byId('aapl');
    final analysis = RuleBasedAnalysisGateway().analyze(instrument);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ListView(
      controller: controller,
      children: [
        ExperimentalScenarioChart(
          instrument: instrument,
          analysis: analysis,
          visibleScenarioIds:
              analysis.scenarios.map((value) => value.id).toSet(),
          historyPoints: instrument.historyEuro.length,
        ),
        const SizedBox(height: 1000),
      ],
    ))));
    await tester.drag(
        find.byKey(const ValueKey('chart-gestures')), const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(50));
    expect(find.text('Zurücksetzen (1.0×)'), findsOneWidget);
  });
}
