import 'dart:math' as math;

import 'models.dart';

abstract class AnalysisGateway {
  AnalysisResult analyze(Instrument instrument, {DateTime? now});
}

/// Deterministische Elliott-Wellen-Analyse auf Basis erkannter Wendepunkte.
///
/// Die Engine verwendet einen volatilitaetsangepassten ZigZag, bewertet
/// moegliche Impuls- und Korrekturzaehlungen und prueft die harten
/// Elliott-Regeln. Die ausgegebenen Prozentwerte sind relative
/// Plausibilitaetswerte der gleichzeitig berechneten Szenarien. Sie sind keine
/// statistisch kalibrierten Eintrittswahrscheinlichkeiten.
class RuleBasedAnalysisGateway implements AnalysisGateway {
  @override
  AnalysisResult analyze(Instrument instrument, {DateTime? now}) {
    final history = instrument.historyEuro;
    if (history.length < 2 ||
        history.any((value) => !value.isFinite || value <= 0)) {
      throw ArgumentError.value(
        history,
        'instrument.historyEuro',
        'Fuer eine Wellenanalyse werden mindestens zwei positive Kurswerte benoetigt.',
      );
    }

    final pivots = _detectPivots(history, instrument.timeframe);
    final bullishImpulse = _bestImpulse(pivots, bullish: true);
    final bearishImpulse = _bestImpulse(pivots, bullish: false);
    final correction = _bestCorrection(pivots);
    final current = instrument.euroPrice;
    final volatility = _volatility(history);
    final longTrend = _return(history, 0, history.length - 1);
    final momentum = _return(
      history,
      math.max(0, history.length - math.max(6, history.length ~/ 5)),
      history.length - 1,
    );
    final recent = history.skip(math.max(0, history.length - 20)).toList();
    final recentHigh = recent.reduce(math.max);
    final recentLow = recent.reduce(math.min);
    final swing = math.max(recentHigh - recentLow, current * 0.035);

    final bullRatio = bullishImpulse.ratio;
    final bearRatio = bearishImpulse.ratio;
    final correctionRatio = correction.ratio;
    final assetVolatility = volatility *
        (instrument.assetType == AssetType.crypto ? 0.70 : 1.0);
    final rawPlausibility = <double>[
      18 +
          bullRatio * 52 +
          longTrend.clamp(-0.5, 0.5) * 28 +
          momentum.clamp(-0.25, 0.25) * 55 -
          assetVolatility * 35,
      20 +
          correctionRatio * 48 +
          (1 - (momentum.abs() * 8).clamp(0.0, 1.0)) * 16 +
          assetVolatility * 18,
      18 +
          bearRatio * 52 -
          longTrend.clamp(-0.5, 0.5) * 24 -
          momentum.clamp(-0.25, 0.25) * 55 +
          assetVolatility * 35,
    ];
    final plausibility = _normalizePlausibility(rawPlausibility);

    final bullBase = _impulseBase(bullishImpulse, swing);
    final bullInvalidation = _positive(
      bullishImpulse.invalidation ?? recentLow,
      current * 0.75,
    );
    final bullTarget = math.max(
      current + bullBase * 0.618,
      _fibonacciTarget(bullishImpulse, current, bullish: true),
    );
    final bullEntryLow = math.max(
      bullInvalidation * 1.01,
      current - bullBase * 0.382,
    );
    final bullEntryHigh = math.max(bullEntryLow, current + bullBase * 0.05);

    final bearBase = _impulseBase(bearishImpulse, swing);
    final bearInvalidation = math.max(
      bearishImpulse.invalidation ?? recentHigh,
      current + bearBase * 0.15,
    );
    final bearTarget = math.max(
      current * 0.08,
      math.min(
        current - bearBase * 0.618,
        _fibonacciTarget(bearishImpulse, current, bullish: false),
      ),
    );
    final bearEntryLow = math.max(current * 0.05, current - bearBase * 0.05);
    final bearEntryHigh = math.max(bearEntryLow, current + bearBase * 0.382);

    final neutralSupport = math.max(
      current * 0.08,
      correction.support ?? recentLow,
    );
    final neutralResistance = math.max(
      neutralSupport,
      correction.resistance ?? recentHigh,
    );
    final neutralTarget = (neutralSupport + neutralResistance) / 2;
    final neutralEntryLow = neutralSupport +
        (neutralResistance - neutralSupport) * 0.08;
    final neutralEntryHigh = neutralSupport +
        (neutralResistance - neutralSupport) * 0.35;

    final scenarios = <AnalysisScenario>[
      AnalysisScenario(
        id: 'pivot-impulse-bullish',
        title: bullishImpulse.passesAll
            ? 'Regelkonformer bullischer Impuls'
            : 'Bullische Impuls-Alternative',
        kind: ScenarioKind.bullish,
        probability: plausibility[0],
        score: _score(plausibility[0], bullRatio),
        targetEuro: bullTarget,
        invalidationEuro: bullInvalidation,
        entryLowEuro: bullEntryLow,
        entryHighEuro: bullEntryHigh,
        exitLowEuro: bullTarget * 0.96,
        exitHighEuro: bullTarget * 1.04,
        stopLossEuro: bullInvalidation * 0.995,
        projectionEuro: _projection(<double>[
          current,
          bullEntryLow,
          current + bullBase * 0.382,
          current + bullBase * 0.236,
          bullTarget,
          bullTarget - bullBase * 0.236,
        ]),
        countMethod: 'Adaptiver ZigZag · Impuls 1–2–3–4–5',
        waveLabels: const <String>['1', '2', '3', '4', '5'],
        waveMarkers: bullishImpulse.markers,
        ruleChecks: bullishImpulse.checkTexts,
        rulesSatisfied: bullishImpulse.passed,
        rulesTotal: bullishImpulse.total,
        probabilityFactors: <String>[
          'Erkannte Wendepunkte: ${pivots.length}',
          'Harte Impulsregeln: ${bullishImpulse.passed}/${bullishImpulse.total}',
          _factor('Trend', longTrend),
          _factor('Momentum', momentum),
          'Ziel aus tatsaechlicher Swing-Laenge und Fibonacci 0,618/1,618',
        ],
        thesis: bullishImpulse.passesAll
            ? 'Die erkannte Fuenferstruktur erfuellt die harten Impulsregeln. '
                'Oberhalb der Invalidierung bleibt eine Fortsetzung oder '
                'Extension technisch moeglich.'
            : 'Die bullische Zaehlung ist eine Alternative: Mindestens eine '
                'harte Impulsregel ist in den erkannten Wendepunkten noch '
                'nicht bestaetigt.',
      ),
      AnalysisScenario(
        id: 'pivot-correction-neutral',
        title: correction.passesAll
            ? 'Regelkonforme A–B–C-Korrektur'
            : 'Seitwaerts-/Korrektur-Alternative',
        kind: ScenarioKind.neutral,
        probability: plausibility[1],
        score: _score(plausibility[1], correctionRatio),
        targetEuro: neutralTarget,
        invalidationEuro: neutralSupport * 0.985,
        entryLowEuro: neutralEntryLow,
        entryHighEuro: math.max(neutralEntryLow, neutralEntryHigh),
        exitLowEuro: neutralResistance * 0.94,
        exitHighEuro: neutralResistance * 1.01,
        stopLossEuro: neutralSupport * 0.985,
        projectionEuro: _projection(<double>[
          current,
          neutralSupport + (neutralResistance - neutralSupport) * 0.25,
          neutralResistance * 0.985,
          neutralTarget,
          neutralSupport * 1.02,
          neutralTarget,
        ]),
        countMethod: 'Adaptiver ZigZag · A–B–C / komplexe Korrektur',
        waveLabels: const <String>['A', 'B', 'C'],
        waveMarkers: correction.markers,
        ruleChecks: correction.checkTexts,
        rulesSatisfied: correction.passed,
        rulesTotal: correction.total,
        probabilityFactors: <String>[
          'Erkannte Wendepunkte: ${pivots.length}',
          'Korrekturregeln: ${correction.passed}/${correction.total}',
          _factor('Momentum nahe neutral', -momentum.abs()),
          _factor('Volatilitaet/Seitwaertsrisiko', assetVolatility),
        ],
        thesis: correction.passesAll
            ? 'Die juengste A–B–C-Struktur erfuellt die geprueften '
                'Korrekturregeln. Die markierte Spanne bleibt bis zu einem '
                'bestaetigten Ausbruch das neutrale Referenzszenario.'
            : 'Die Wendepunkte lassen eine komplexe oder noch unvollstaendige '
                'Korrektur zu. Ein Ausbruch aus der markierten Spanne ist zur '
                'Bestaetigung erforderlich.',
      ),
      AnalysisScenario(
        id: 'pivot-impulse-bearish',
        title: bearishImpulse.passesAll
            ? 'Regelkonformer bearischer Impuls'
            : 'Bearische Impuls-Alternative',
        kind: ScenarioKind.bearish,
        probability: plausibility[2],
        score: _score(plausibility[2], bearRatio),
        targetEuro: bearTarget,
        invalidationEuro: bearInvalidation,
        entryLowEuro: bearEntryLow,
        entryHighEuro: bearEntryHigh,
        exitLowEuro: math.max(current * 0.05, bearTarget * 0.94),
        exitHighEuro: bearTarget * 1.04,
        stopLossEuro: bearInvalidation * 1.005,
        projectionEuro: _projection(<double>[
          current,
          bearEntryHigh,
          current - bearBase * 0.382,
          current - bearBase * 0.236,
          bearTarget,
          bearTarget + bearBase * 0.236,
        ].map((value) => math.max(value, current * 0.05)).toList()),
        countMethod: 'Adaptiver ZigZag · Abwaertsimpuls 1–2–3–4–5',
        waveLabels: const <String>['1', '2', '3', '4', '5'],
        waveMarkers: bearishImpulse.markers,
        ruleChecks: bearishImpulse.checkTexts,
        rulesSatisfied: bearishImpulse.passed,
        rulesTotal: bearishImpulse.total,
        probabilityFactors: <String>[
          'Erkannte Wendepunkte: ${pivots.length}',
          'Harte Impulsregeln: ${bearishImpulse.passed}/${bearishImpulse.total}',
          _factor('Trendgegenwind', -longTrend),
          _factor('Negatives Momentum', -momentum),
          'Invalidierung oberhalb des erkannten Swing-Hochs',
        ],
        thesis: bearishImpulse.passesAll
            ? 'Die erkannte Abwaertsstruktur erfuellt die harten '
                'Impulsregeln. Erst ein Anstieg ueber die Invalidierung '
                'verwirft diese Zaehlung.'
            : 'Die bearische Zaehlung ist eine Alternative: Mindestens eine '
                'harte Impulsregel ist in den erkannten Wendepunkten noch '
                'nicht bestaetigt.',
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
      engineVersion: 'elliott-pivot-engine-v2.0.0',
      explanationModel: 'Deterministisches Regelwerk – kein LLM',
      promptVersion: 'nicht verwendet',
      timeframe: instrument.timeframe,
      instrumentSnapshot: instrument,
      methodology:
          'Volatilitaetsangepasster ZigZag zur Wendepunkterkennung; '
          'explizite Pruefung von Welle-2-Retracement, Welle-3-Laenge, '
          'Welle-4-Ueberlappung und neuen Extremen; Fibonacci-Ziele aus den '
          'erkannten Swing-Laengen. Prozentwerte sind relative '
          'Plausibilitaeten, keine Prognosegarantie.',
    );
  }

  List<_Pivot> _detectPivots(
    List<double> values,
    ChartTimeframe timeframe,
  ) {
    final volatility = _volatility(values);
    final floor = switch (timeframe) {
      ChartTimeframe.oneDay => 0.004,
      ChartTimeframe.fiveDays => 0.006,
      ChartTimeframe.oneMonth => 0.010,
      ChartTimeframe.threeMonths => 0.012,
      ChartTimeframe.oneYear => 0.015,
      ChartTimeframe.fiveYears => 0.020,
      ChartTimeframe.maximum => 0.020,
    };
    final reversal = math.max(floor, volatility * 1.05).clamp(0.004, 0.12);
    final pivots = <_Pivot>[];
    var direction = 0;
    var extremeIndex = 0;
    var extremePrice = values.first;

    for (var index = 1; index < values.length; index++) {
      final price = values[index];
      if (direction == 0) {
        final change = price / values.first - 1;
        if (change.abs() >= reversal) {
          direction = change > 0 ? 1 : -1;
          pivots.add(
            _Pivot(
              index: 0,
              price: values.first,
              isHigh: direction < 0,
            ),
          );
          extremeIndex = index;
          extremePrice = price;
        }
        continue;
      }
      if (direction > 0) {
        if (price >= extremePrice) {
          extremeIndex = index;
          extremePrice = price;
        } else if ((extremePrice - price) / extremePrice >= reversal) {
          pivots.add(
            _Pivot(index: extremeIndex, price: extremePrice, isHigh: true),
          );
          direction = -1;
          extremeIndex = index;
          extremePrice = price;
        }
      } else {
        if (price <= extremePrice) {
          extremeIndex = index;
          extremePrice = price;
        } else if ((price - extremePrice) / extremePrice >= reversal) {
          pivots.add(
            _Pivot(index: extremeIndex, price: extremePrice, isHigh: false),
          );
          direction = 1;
          extremeIndex = index;
          extremePrice = price;
        }
      }
    }
    if (direction != 0 &&
        (pivots.isEmpty || pivots.last.index != extremeIndex)) {
      pivots.add(
        _Pivot(
          index: extremeIndex,
          price: extremePrice,
          isHigh: direction > 0,
        ),
      );
    }
    if (pivots.length >= 4) {
      return pivots;
    }
    return _localExtrema(values);
  }

  List<_Pivot> _localExtrema(List<double> values) {
    final raw = <_Pivot>[
      _Pivot(
        index: 0,
        price: values.first,
        isHigh: values.first > values[1],
      ),
    ];
    final radius = math.max(1, math.min(3, values.length ~/ 20));
    for (var index = radius; index < values.length - radius; index++) {
      final from = math.max(0, index - radius);
      final to = math.min(values.length, index + radius + 1);
      final window = values.sublist(from, to);
      if (values[index] == window.reduce(math.max)) {
        raw.add(_Pivot(index: index, price: values[index], isHigh: true));
      } else if (values[index] == window.reduce(math.min)) {
        raw.add(_Pivot(index: index, price: values[index], isHigh: false));
      }
    }
    raw.add(
      _Pivot(
        index: values.length - 1,
        price: values.last,
        isHigh: values.last > values[values.length - 2],
      ),
    );
    final compressed = <_Pivot>[];
    for (final pivot in raw) {
      if (compressed.isEmpty || compressed.last.isHigh != pivot.isHigh) {
        compressed.add(pivot);
        continue;
      }
      final previous = compressed.last;
      final replace = pivot.isHigh
          ? pivot.price >= previous.price
          : pivot.price <= previous.price;
      if (replace) {
        compressed[compressed.length - 1] = pivot;
      }
    }
    return compressed;
  }

  _StructureMatch _bestImpulse(
    List<_Pivot> pivots, {
    required bool bullish,
  }) {
    _StructureMatch? best;
    final firstCandidate = math.max(0, pivots.length - 12);
    for (var start = firstCandidate; start + 5 < pivots.length; start++) {
      final points = pivots.sublist(start, start + 6);
      final beginsCorrectly = bullish ? !points.first.isHigh : points.first.isHigh;
      final wave1 = (points[1].price - points[0].price).abs();
      final wave3 = (points[3].price - points[2].price).abs();
      final wave5 = (points[5].price - points[4].price).abs();
      final checks = bullish
          ? <_RuleCheck>[
              _RuleCheck('Wechselnde Hoch-/Tiefpunkte', beginsCorrectly),
              _RuleCheck(
                'Welle 2 unterschreitet den Start von Welle 1 nicht',
                points[2].price > points[0].price,
              ),
              _RuleCheck(
                'Welle 3 uebersteigt das Ende von Welle 1',
                points[3].price > points[1].price,
              ),
              _RuleCheck(
                'Welle 3 ist nicht die kuerzeste Antriebswelle',
                wave3 >= math.min(wave1, wave5),
              ),
              _RuleCheck(
                'Welle 4 ueberlappt den Preisbereich von Welle 1 nicht',
                points[4].price > points[1].price,
              ),
              _RuleCheck(
                'Welle 5 markiert ein neues Hoch',
                points[5].price > points[3].price,
              ),
            ]
          : <_RuleCheck>[
              _RuleCheck('Wechselnde Hoch-/Tiefpunkte', beginsCorrectly),
              _RuleCheck(
                'Welle 2 uebersteigt den Start von Welle 1 nicht',
                points[2].price < points[0].price,
              ),
              _RuleCheck(
                'Welle 3 unterschreitet das Ende von Welle 1',
                points[3].price < points[1].price,
              ),
              _RuleCheck(
                'Welle 3 ist nicht die kuerzeste Antriebswelle',
                wave3 >= math.min(wave1, wave5),
              ),
              _RuleCheck(
                'Welle 4 ueberlappt den Preisbereich von Welle 1 nicht',
                points[4].price < points[1].price,
              ),
              _RuleCheck(
                'Welle 5 markiert ein neues Tief',
                points[5].price < points[3].price,
              ),
            ];
      final candidate = _StructureMatch(
        points: points,
        labels: const <String>['0', '1', '2', '3', '4', '5'],
        checks: checks,
        recency: points.last.index,
        invalidation: points[4].price,
      );
      if (best == null || candidate.rank > best.rank) {
        best = candidate;
      }
    }
    return best ?? _StructureMatch.empty();
  }

  _StructureMatch _bestCorrection(List<_Pivot> pivots) {
    _StructureMatch? best;
    final firstCandidate = math.max(0, pivots.length - 12);
    for (var start = firstCandidate; start + 3 < pivots.length; start++) {
      final points = pivots.sublist(start, start + 4);
      final down = points.first.isHigh;
      final alternating = points[0].isHigh != points[1].isHigh &&
          points[1].isHigh != points[2].isHigh &&
          points[2].isHigh != points[3].isHigh;
      final bWithinOrigin = down
          ? points[2].price < points[0].price
          : points[2].price > points[0].price;
      final cExtendsA = down
          ? points[3].price < points[1].price
          : points[3].price > points[1].price;
      final aLength = (points[1].price - points[0].price).abs();
      final cLength = (points[3].price - points[2].price).abs();
      final proportional = aLength > 0 &&
          (cLength / aLength).clamp(0.0, 4.0) >= 0.382;
      final candidate = _StructureMatch(
        points: points,
        labels: const <String>['0', 'A', 'B', 'C'],
        checks: <_RuleCheck>[
          _RuleCheck('A–B–C besitzt wechselnde Wendepunkte', alternating),
          _RuleCheck('Welle B bleibt innerhalb des Korrekturursprungs', bWithinOrigin),
          _RuleCheck('Welle C uebertrifft das Ende von Welle A', cExtendsA),
          _RuleCheck('Welle C erreicht mindestens 38,2 % von Welle A', proportional),
        ],
        recency: points.last.index,
        support: points.map((point) => point.price).reduce(math.min),
        resistance: points.map((point) => point.price).reduce(math.max),
      );
      if (best == null || candidate.rank > best.rank) {
        best = candidate;
      }
    }
    return best ?? _StructureMatch.empty();
  }

  double _impulseBase(_StructureMatch match, double fallback) {
    if (match.points.length < 4) {
      return fallback;
    }
    final wave1 = (match.points[1].price - match.points[0].price).abs();
    final wave3 = (match.points[3].price - match.points[2].price).abs();
    return math.max((wave1 + wave3) / 2, fallback * 0.35);
  }

  double _fibonacciTarget(
    _StructureMatch match,
    double current, {
    required bool bullish,
  }) {
    if (match.points.length < 4) {
      return current;
    }
    final wave1 = (match.points[1].price - match.points[0].price).abs();
    final anchor = match.points.length > 4 ? match.points[4].price : current;
    return bullish ? anchor + wave1 * 1.618 : anchor - wave1 * 1.618;
  }

  List<int> _normalizePlausibility(List<double> raw) {
    final safe = raw.map((value) => value.clamp(5.0, 90.0)).toList();
    final sum = safe.reduce((a, b) => a + b);
    final first = (safe[0] / sum * 100).round();
    final second = (safe[1] / sum * 100).round();
    return <int>[first, second, 100 - first - second];
  }

  int _score(int plausibility, double ruleRatio) =>
      (35 + plausibility * 0.35 + ruleRatio * 30)
          .round()
          .clamp(35, 92)
          .toInt();

  double _return(List<double> values, int from, int to) {
    if (values.length < 2 || values[from] == 0) {
      return 0;
    }
    return values[to] / values[from] - 1;
  }

  String _factor(String label, double value) {
    final direction = value > 0.01
        ? 'stuetzt'
        : value < -0.01
        ? 'belastet'
        : 'neutral';
    return '$label: $direction';
  }

  double _volatility(List<double> values) {
    if (values.length < 3) {
      return 0;
    }
    final returns = <double>[];
    for (var index = 1; index < values.length; index++) {
      returns.add(values[index] / values[index - 1] - 1);
    }
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns
            .map((value) => math.pow(value - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        returns.length;
    return math.sqrt(variance);
  }

  List<double> _projection(List<double> anchors) {
    const stepsPerSegment = 4;
    final result = <double>[];
    for (var segment = 0; segment < anchors.length - 1; segment++) {
      final from = anchors[segment];
      final to = anchors[segment + 1];
      for (var step = 0; step < stepsPerSegment; step++) {
        final progress = step / stepsPerSegment;
        result.add(from + (to - from) * progress);
      }
    }
    result.add(anchors.last);
    return result;
  }

  double _positive(double value, double fallback) =>
      value.isFinite && value > 0 ? value : fallback;
}

class _Pivot {
  const _Pivot({
    required this.index,
    required this.price,
    required this.isHigh,
  });

  final int index;
  final double price;
  final bool isHigh;
}

class _RuleCheck {
  const _RuleCheck(this.text, this.passed);

  final String text;
  final bool passed;
}

class _StructureMatch {
  const _StructureMatch({
    required this.points,
    required this.labels,
    required this.checks,
    required this.recency,
    this.invalidation,
    this.support,
    this.resistance,
  });

  factory _StructureMatch.empty() => const _StructureMatch(
    points: <_Pivot>[],
    labels: <String>[],
    checks: <_RuleCheck>[],
    recency: 0,
  );

  final List<_Pivot> points;
  final List<String> labels;
  final List<_RuleCheck> checks;
  final int recency;
  final double? invalidation;
  final double? support;
  final double? resistance;

  int get passed => checks.where((check) => check.passed).length;
  int get total => checks.length;
  double get ratio => total == 0 ? 0 : passed / total;
  bool get passesAll => total > 0 && passed == total;
  double get rank => passed * 1000000 + ratio * 1000 + recency;

  List<WaveMarker> get markers => List<WaveMarker>.generate(
    math.min(points.length, labels.length),
    (index) => WaveMarker(
      historyIndex: points[index].index,
      priceEuro: points[index].price,
      label: labels[index],
    ),
    growable: false,
  );

  List<String> get checkTexts => checks
      .map((check) => '${check.passed ? '✓' : '✗'} ${check.text}')
      .toList(growable: false);
}

@Deprecated('Seit 0.4 RuleBasedAnalysisGateway verwenden.')
class RuleBasedDemoAnalysisGateway extends RuleBasedAnalysisGateway {}
