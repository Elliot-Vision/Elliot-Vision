import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elliott_vision/elliott_vision.dart';

void main() {
  final instrument = DemoMarketDataRepository().byId('aapl');
  final analysis = RuleBasedAnalysisGateway().analyze(instrument);

  test('Projektionsabfrage folgt Startpunkt, Segmenten und letztem Modellwert',
      () {
    final s = analysis.scenarios.first;
    expect(projectionPrice(s, instrument.euroPrice, 0), instrument.euroPrice);
    expect(projectionPrice(s, instrument.euroPrice, 1), s.projectionEuro.last);
    expect(
        projectionPrice(s, instrument.euroPrice, 0.5 / s.projectionEuro.length),
        closeTo((instrument.euroPrice + s.projectionEuro.first) / 2, 0.000001));
    final empty =
        AnalysisScenario.fromJson(s.toJson()..['projectionEuro'] = <double>[]);
    expect(projectionPrice(empty, instrument.euroPrice, 0.5),
        instrument.euroPrice);
  });

  testWidgets(
      'Projektion liest ausgewähltes Szenario nach Zoom und entfernt ausgeblendete Werte',
      (tester) async {
    final selected = analysis.scenarios.last;
    Widget chart(Set<String> ids) => MaterialApp(
        home: Scaffold(
            body: ElliottScenarioChart(
                instrument: instrument,
                analysis: analysis,
                visibleScenarioIds: ids,
                highlightedScenarioId: selected.id,
                historyPoints: instrument.historyEuro.length)));
    await tester.pumpWidget(chart({selected.id}));
    final rect = tester.getRect(find.byKey(const ValueKey('chart-gestures')));
    final center = rect.topLeft + Offset(rect.width * 0.85, 150);
    final a =
        await tester.startGesture(center - const Offset(25, 0), pointer: 1);
    final b =
        await tester.startGesture(center + const Offset(25, 0), pointer: 2);
    await a.moveTo(center - const Offset(50, 0));
    await b.moveTo(center + const Offset(50, 0));
    await tester.pump();
    await a.up();
    await b.up();
    await tester.pump(const Duration(milliseconds: 400));
    final finger =
        await tester.startGesture(rect.topLeft + Offset(rect.width * 0.7, 150));
    final x = 14 + (rect.width - 28) * 0.9;
    await finger.moveTo(rect.topLeft + Offset(x, 150));
    await tester.pump();
    final dynamic painter = tester
        .widget<CustomPaint>(find.byKey(const ValueKey('scenario-chart-paint')))
        .painter;
    final ChartViewport viewport = painter.viewport;
    final fraction =
        ((viewport.start + 0.9 * viewport.span - 0.64) / 0.36).clamp(0.0, 1.0);
    final price = projectionPrice(selected, instrument.euroPrice, fraction);
    expect(painter.projectionValue, closeTo(price, 0.000001));
    expect(
        find.textContaining(
            '${price.toStringAsFixed(2).replaceAll('.', ',')} €'),
        findsOneWidget);
    expect(find.textContaining('Projektion · ${selected.kind.label}'),
        findsOneWidget);
    expect(find.textContaining('Modellschritt'), findsOneWidget);
    await finger.up();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpWidget(chart({}));
    await tester.pump();
    expect(find.textContaining('Projektion ·'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ohne sichtbares Szenario wird kein Projektionspreis erfunden',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ElliottScenarioChart(
                instrument: instrument,
                analysis: analysis,
                visibleScenarioIds: const {},
                historyPoints: instrument.historyEuro.length))));
    final rect = tester.getRect(find.byKey(const ValueKey('chart-gestures')));
    final finger =
        await tester.startGesture(rect.topLeft + Offset(rect.width * 0.7, 150));
    await finger.moveTo(rect.topLeft + Offset(rect.width * 0.9, 150));
    await tester.pump();
    expect(find.text('Keine sichtbare Projektion ausgewählt'), findsOneWidget);
    await finger.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
