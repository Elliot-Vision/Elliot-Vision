import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app.dart';
import 'chart.dart';
import 'models.dart';

List<AnalysisScenario> chartScenarios(AnalysisResult analysis) {
  final ranked = [...analysis.scenarios]..sort((a, b) {
      if (a.id == b.id) return 0;
      if (a.id == analysis.primaryScenarioId) return -1;
      if (b.id == analysis.primaryScenarioId) return 1;
      return b.probability.compareTo(a.probability);
    });
  return ranked.take(2).toList();
}

/// Explains model values using the selected instrument's actual data source.
class ScenarioDetails extends StatelessWidget {
  const ScenarioDetails(
      {required this.instrument,
      required this.scenario,
      required this.zonesVisible,
      required this.onClear,
      this.isDemo = false,
      super.key});
  final Instrument instrument;
  final AnalysisScenario scenario;
  final bool zonesVisible;
  final VoidCallback onClear;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    String money(double value) =>
        '${value.toStringAsFixed(2).replaceAll('.', ',')} €';
    final recent = instrument.historyEuro
        .skip(math.max(0, instrument.historyEuro.length - 20))
        .toList();
    final color = scenarioColor(scenario.kind);
    Widget metric(
            String title, String value, String explanation, Color accent) =>
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accent, width: 4)),
            color: accent.withAlpha(18),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
            SelectableText(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text(explanation),
          ]),
        );
    return Column(
      key: const ValueKey('test-scenario-details'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text('Ausgewählt: ${scenario.kind.label}',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 18)),
        Text(scenario.title),
        Text(scenario.thesis),
        TextButton(
            onPressed: onClear, child: const Text('Hervorhebung aufheben')),
        if (!zonesVisible)
          const Text(
              'Zonen sind im Chart ausgeblendet. Die Werte bleiben hier ablesbar.'),
        metric(
            'Einstiegsbereich · blau',
            '${money(scenario.entryLowEuro)} – ${money(scenario.entryHighEuro)}',
            'Modellierter Beobachtungsbereich für dieses Szenario. Er entsteht aus aktuellem Kurs, '
                'erkannten Wendepunkten und der Swing-Spanne; bei der neutralen Variante aus der Unterstützung. '
                'Eine Berührung allein bestätigt das Szenario nicht.',
            AppPalette.blue),
        metric(
            'Ausstiegsbereich · Szenariofarbe',
            '${money(scenario.exitLowEuro)} – ${money(scenario.exitHighEuro)}',
            'Modellierter Zielbereich für den Verlauf: bei Impulsen um das berechnete Kursziel, '
                'bei der neutralen Variante am Widerstand. Beim bearischen Szenario liegt dieser Bereich '
                'typischerweise unter dem Einstieg; er beschreibt eine Abwärtsbewegung.',
            color),
        metric(
            'Kursziel',
            money(scenario.targetEuro),
            'Referenzwert der Projektion. Er ist eine Modellannahme und kein zugesicherter künftiger Preis.',
            color),
        metric(
            'Stop-Loss / Invalidierung',
            '${money(scenario.stopLossEuro)} / ${money(scenario.invalidationEuro)}',
            'Rot gestrichelt: modellierter Stop-Loss. Invalidierung: Grenze, an der die Zählung '
                'neu bewertet werden muss. Die App platziert keine Order.',
            AppPalette.red),
        const SizedBox(height: 12),
        ExpansionTile(
          key: const ValueKey('test-scenario-inputs'),
          tilePadding: EdgeInsets.zero,
          title: const Text('Verwendete Daten und Herleitung'),
          children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isDemo
                          ? 'Synthetische Demodaten – keine aktuellen Börsenkurse.'
                          : 'Datenquelle: ${instrument.dataSource} · Datenstand: ${instrument.dataTimestamp.toLocal()}'),
                      SelectableText(
                          '${instrument.name} · ${instrument.timeframe.label}\n'
                          'Referenzkurs: ${money(instrument.euroPrice)}\n'
                          'Kurswerte: ${instrument.historyEuro.length}\n'
                          'Letzte ${recent.length} Werte: Tief ${money(recent.reduce(math.min))}, '
                          'Hoch ${money(recent.reduce(math.max))}'),
                      const Text(
                          'Benötigt werden chronologische Euro-Kurse und Zeitstempel. Daraus '
                          'ermittelt das Modell Wendepunkte, Trend, Momentum und Schwankung. Die jüngste '
                          'Spanne dient als Ersatz, wenn keine vollständige Impulsstruktur erkannt wird.'),
                      Text('Zählmethode: ${scenario.countMethod}'),
                      Text(
                          'Erfüllte Regeln: ${scenario.rulesSatisfied}/${scenario.rulesTotal}'),
                      for (final check in scenario.ruleChecks) Text('• $check'),
                      const SizedBox(height: 8),
                      Text(
                          'Modellgewicht: ${scenario.probability} % – relativ zu allen drei Szenarien, '
                          'keine statistisch gemessene Eintrittswahrscheinlichkeit.'),
                      for (final factor in scenario.probabilityFactors)
                        Text('• $factor'),
                    ])),
          ],
        ),
      ],
    );
  }
}
