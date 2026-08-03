import 'dart:math' as math;

import 'models.dart';

abstract class AnalysisGateway {
  AnalysisResult analyze(Instrument instrument, {DateTime? now});
}

class RuleBasedDemoAnalysisGateway implements AnalysisGateway {
  @override
  AnalysisResult analyze(Instrument instrument, {DateTime? now}) {
    final history = instrument.historyEuro;
    final longTrend = (history.last / history.first) - 1;
    final momentumBase = history[math.max(0, history.length - 8)];
    final momentum = (history.last / momentumBase) - 1;
    final volatility = _volatility(history);

    var bullishProbability =
        (42 + longTrend * 12 + momentum * 95 - volatility * 25)
            .round()
            .clamp(25, 65)
            .toInt();
    var bearishProbability =
        (28 - longTrend * 7 - momentum * 70 + volatility * 18)
            .round()
            .clamp(15, 48)
            .toInt();
    var neutralProbability = 100 - bullishProbability - bearishProbability;

    if (neutralProbability < 15) {
      final correction = 15 - neutralProbability;
      if (bullishProbability >= bearishProbability) {
        bullishProbability -= correction;
      } else {
        bearishProbability -= correction;
      }
      neutralProbability = 15;
    }

    final bullishScore = (58 + longTrend * 10 + momentum * 95 - volatility * 12)
        .round()
        .clamp(45, 88)
        .toInt();
    final neutralScore = (55 - momentum.abs() * 45 - volatility * 8)
        .round()
        .clamp(38, 72)
        .toInt();
    final bearishScore = (45 - momentum * 80 + volatility * 18)
        .round()
        .clamp(30, 76)
        .toInt();

    final scenarios = [
      AnalysisScenario(
        id: 'bullish',
        title: 'Impuls setzt sich fort',
        kind: ScenarioKind.bullish,
        probability: bullishProbability,
        score: bullishScore,
        targetEuro: instrument.euroPrice * 1.34,
        invalidationEuro: instrument.euroPrice * 0.82,
        projectionEuro: _projection(instrument.euroPrice, const [
          1,
          1.06,
          1.02,
          1.17,
          1.11,
          1.28,
          1.22,
          1.34,
        ]),
        thesis:
            'Die jüngste Struktur bleibt oberhalb der Invalidierung intakt. '
            'Ein neuer fünfteiliger Impuls wäre das Hauptszenario.',
      ),
      AnalysisScenario(
        id: 'neutral',
        title: 'Seitwärtskorrektur',
        kind: ScenarioKind.neutral,
        probability: neutralProbability,
        score: neutralScore,
        targetEuro: instrument.euroPrice * 1.10,
        invalidationEuro: instrument.euroPrice * 0.75,
        projectionEuro: _projection(instrument.euroPrice, const [
          1,
          1.03,
          0.96,
          1.07,
          0.99,
          1.10,
          1.03,
          1.08,
        ]),
        thesis:
            'Die Wellen überlappen stärker. Das spricht für eine komplexe '
            'ABC-Korrektur, bevor sich ein neuer Trend etabliert.',
      ),
      AnalysisScenario(
        id: 'bearish',
        title: 'Größere Korrektur',
        kind: ScenarioKind.bearish,
        probability: bearishProbability,
        score: bearishScore,
        targetEuro: instrument.euroPrice * 0.69,
        invalidationEuro: instrument.euroPrice * 1.14,
        projectionEuro: _projection(instrument.euroPrice, const [
          1,
          0.94,
          0.97,
          0.86,
          0.90,
          0.76,
          0.81,
          0.69,
        ]),
        thesis:
            'Ein Bruch der zentralen Unterstützung würde die laufende '
            'Aufwärtszählung verwerfen und eine größere ABC-Korrektur öffnen.',
      ),
    ];

    final primary = scenarios.reduce(
      (best, scenario) =>
          scenario.probability > best.probability ? scenario : best,
    );
    final timestamp = now ?? DateTime.now();
    return AnalysisResult(
      id: '${instrument.id}-${timestamp.microsecondsSinceEpoch}',
      instrumentId: instrument.id,
      createdAt: timestamp,
      dataTimestamp: instrument.dataTimestamp,
      overallScore: primary.score,
      primaryScenarioId: primary.id,
      scenarios: scenarios,
      engineVersion: 'regelwerk-demo-v0.1',
      explanationModel: 'Kein LLM – Demo-Modus',
      promptVersion: 'mvp-v1',
    );
  }

  double _volatility(List<double> values) {
    if (values.length < 3) {
      return 0;
    }
    final returns = <double>[];
    for (var index = 1; index < values.length; index++) {
      returns.add((values[index] / values[index - 1]) - 1);
    }
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance =
        returns
            .map((value) => math.pow(value - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        returns.length;
    return math.sqrt(variance);
  }

  List<double> _projection(double start, List<double> anchors) {
    const stepsPerSegment = 4;
    final result = <double>[];
    for (var segment = 0; segment < anchors.length - 1; segment++) {
      final from = anchors[segment];
      final to = anchors[segment + 1];
      for (var step = 0; step < stepsPerSegment; step++) {
        final progress = step / stepsPerSegment;
        result.add(start * (from + (to - from) * progress));
      }
    }
    result.add(start * anchors.last);
    return result;
  }
}
