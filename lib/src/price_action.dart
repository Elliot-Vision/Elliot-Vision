import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'chart.dart';
import 'models.dart';

String candleDescription(PriceCandle candle) {
  final range = candle.high - candle.low;
  if (range <= 0) return 'Keine Preisspanne';
  final body = (candle.close - candle.open).abs();
  if (body / range <= 0.1) {
    return 'Doji-ähnlich: kleiner Körper im Verhältnis zur Spanne';
  }
  final upper = candle.high - math.max(candle.open, candle.close);
  final lower = math.min(candle.open, candle.close) - candle.low;
  if (lower > body * 2 && lower > upper * 2) {
    return 'Langer unterer Docht: Preis erholte sich vom Tief';
  }
  if (upper > body * 2 && upper > lower * 2) {
    return 'Langer oberer Docht: Preis fiel vom Hoch zurück';
  }
  return candle.close >= candle.open
      ? 'Steigende Kerze: Schluss über Eröffnung'
      : 'Fallende Kerze: Schluss unter Eröffnung';
}

class PriceActionPanel extends StatelessWidget {
  const PriceActionPanel(
      {required this.instrument, required this.analysis, super.key});
  final Instrument instrument;
  final AnalysisResult analysis;
  @override
  Widget build(BuildContext context) {
    final candles = instrument.candlesEuro;
    final recent = candles.skip(math.max(0, candles.length - 20)).toList();
    String money(double v) => '${v.toStringAsFixed(2).replaceAll('.', ',')} €';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Price Action', style: Theme.of(context).textTheme.titleLarge),
      Text(
          'Kerzenintervall: ${instrument.timeframe.interval} · ${instrument.isLive ? instrument.dataSource : 'Demodaten / gespeicherter Datenstand'}'),
      const SizedBox(height: 12),
      if (candles.isEmpty)
        const Text('Für diesen Datenstand fehlen vollständige OHLC-Kerzen. '
            'Bitte den Zeitraum neu laden. Aus reinen Schlusskursen werden keine Kerzen erfunden.'),
      if (candles.isNotEmpty) ...[
        ElliottScenarioChart(
            instrument: instrument,
            analysis: analysis,
            visibleScenarioIds: const {},
            historyPoints: candles.length,
            candleMode: true),
        const SizedBox(height: 12),
        Text('Letzte Kerze: ${candleDescription(candles.last)}'),
        Text('Spanne der letzten ${recent.length} Kerzen: '
            '${money(recent.map((c) => c.low).reduce(math.min))} bis '
            '${money(recent.map((c) => c.high).reduce(math.max))}'),
        Text('Schlusskursänderung in diesem Ausschnitt: '
            '${((recent.last.close / recent.first.close - 1) * 100).toStringAsFixed(2)} %'),
        const Text(
            'Beschreibt den beobachteten Kursverlauf. Ein Kerzenmuster allein ist keine verlässliche Prognose.'),
      ],
      const SizedBox(height: 16),
      const ExpansionTile(
          title: Text('Wie entsteht eine Kerze?'),
          childrenPadding: EdgeInsets.all(12),
          children: [
            Text(
                'Jede Kerze fasst die gemeldeten Kurse eines Zeitintervalls zusammen. '
                'Eröffnung (O) ist der erste, Schluss (S) der letzte Kurs. Hoch (H) und Tief (T) '
                'sind die Extremwerte innerhalb dieses Intervalls. Der Körper reicht von Eröffnung bis Schluss, '
                'die Dochte bis zum Hoch und Tief. Grün bedeutet Schluss ≥ Eröffnung, Rot Schluss < Eröffnung. '
                'Wische über die Kerzen, um ihre vier Werte zu sehen.'),
          ]),
      const ExpansionTile(
          title: Text('Zeitraum, Intervalle und laufende Kerzen'),
          childrenPadding: EdgeInsets.all(12),
          children: [
            Text(
                'Der Zeitraum bestimmt den gesamten Ausschnitt, das Intervall die Dauer einer Kerze. '
                '5m steht für fünf Minuten, 30m für dreißig Minuten, 1d für einen Tag, 1wk für eine Woche und 1mo für einen Monat. '
                'Solange das Intervall noch läuft, kann sich die letzte Kerze verändern: Der Schluss ist dann nur der zuletzt gemeldete Preis. '
                'Handelszeiten, Datenverzögerung und der gespeicherte Datenstand sind zu beachten. '
                'Fehlende Intervalle werden nicht durch erfundene Kurse aufgefüllt.'),
          ]),
      const ExpansionTile(
          title: Text('Körper, Dochte und Price Action lesen'),
          childrenPadding: EdgeInsets.all(12),
          children: [
            Text(
                'Ein großer Körper zeigt eine größere Änderung zwischen Eröffnung und Schluss. '
                'Ein kleiner Körper relativ zur gesamten Spanne wird hier als Doji-ähnlich beschrieben. '
                'Ein langer oberer Docht zeigt einen Rückgang vom Intervallhoch; ein langer unterer Docht eine Erholung vom Tief. '
                'Die Auswertung ist eine transparente, regelbasierte Beschreibung; Trend, Marktumfeld und Folgekerzen bleiben wichtig.'),
          ]),
      if (!instrument.isLive)
        const Text(
            'Test- und Demokerzen sind synthetisch bzw. gespeicherte Daten, keine aktuellen Börsenkurse.'),
    ]);
  }
}
