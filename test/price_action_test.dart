import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elliott_vision/elliott_vision.dart';
import 'package:elliott_vision/src/experimental_demo_series.dart';
import 'package:elliott_vision/src/price_action.dart';

void main() {
  test(
      'OHLC bleibt in gespeicherten Instrumenten erhalten und migriert alte Daten',
      () {
    final source = DemoMarketDataRepository().instruments.first;
    final instrument = experimentalDemoSeries(source, ChartTimeframe.oneDay);
    final restored = Instrument.fromJson(instrument.toJson());
    expect(restored.candlesEuro.first.toJson(),
        instrument.candlesEuro.first.toJson());
    expect(restored.candlesEuro.every((c) => c.isValid), isTrue);
    final old = source.toJson()..remove('candlesEuro');
    expect(Instrument.fromJson(old).candlesEuro, isEmpty);
  });

  test('Kerzenauswertung unterscheidet Körper und Dochte', () {
    final date = DateTime.utc(2026, 8, 3);
    expect(
        candleDescription(PriceCandle(
            timestamp: date, open: 100, high: 110, low: 90, close: 100)),
        contains('Doji'));
    expect(
        candleDescription(PriceCandle(
            timestamp: date, open: 100, high: 103, low: 90, close: 102)),
        contains('unterer Docht'));
    expect(
        candleDescription(PriceCandle(
            timestamp: date, open: 100, high: 112, low: 99, close: 102)),
        contains('oberer Docht'));
  });

  testWidgets('Price Action zeigt echte OHLC-Auswahl ohne Elliott-Projektionen',
      (tester) async {
    final instrument = experimentalDemoSeries(
        DemoMarketDataRepository().instruments.first, ChartTimeframe.oneMonth);
    final analysis = RuleBasedAnalysisGateway().analyze(instrument);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: PriceActionPanel(
                    instrument: instrument, analysis: analysis)))));
    final chart =
        tester.widget<ElliottScenarioChart>(find.byType(ElliottScenarioChart));
    expect(chart.candleMode, isTrue);
    expect(chart.visibleScenarioIds, isEmpty);
    final rect = tester.getRect(find.byKey(const ValueKey('chart-gestures')));
    final finger =
        await tester.startGesture(rect.topLeft + const Offset(50, 130));
    await finger.moveTo(rect.topLeft + const Offset(150, 130));
    await tester.pump();
    final label = tester
        .widget<Text>(find.byKey(const ValueKey('chart-inspection')))
        .data!;
    expect(label, contains('O '));
    expect(label, contains('H '));
    expect(label, contains('T '));
    expect(label, contains('S '));
    await finger.up();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Fehlende OHLC werden nicht aus Schlusskursen erfunden',
      (tester) async {
    final instrument = DemoMarketDataRepository().instruments.first;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: PriceActionPanel(
                    instrument: instrument,
                    analysis:
                        RuleBasedAnalysisGateway().analyze(instrument))))));
    expect(find.textContaining('fehlen vollständige OHLC'), findsOneWidget);
    expect(find.byType(ElliottScenarioChart), findsNothing);
  });
}
