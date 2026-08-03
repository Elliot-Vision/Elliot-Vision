import 'security.dart';

enum MarketBias { bullish, neutral, bearish }

class WaveLabel {
  const WaveLabel({required this.index, required this.label});
  final int index;
  final String label;
}

class WaveCount {
  const WaveCount({
    required this.id,
    required this.name,
    required this.labels,
    required this.probability,
    required this.bias,
    required this.isPrimary,
  });

  final String id;
  final String name;
  final List<WaveLabel> labels;
  final int probability;
  final MarketBias bias;
  final bool isPrimary;
}

class WaveAnalysis {
  const WaveAnalysis({
    required this.counts,
    required this.score,
    required this.bias,
    required this.bullishTargetEur,
    required this.baseTargetEur,
    required this.bearishTargetEur,
    required this.summary,
    required this.invalidAboveEur,
    required this.invalidBelowEur,
  });

  final List<WaveCount> counts;
  final int score;
  final MarketBias bias;
  final double bullishTargetEur;
  final double baseTargetEur;
  final double bearishTargetEur;
  final double invalidAboveEur;
  final double invalidBelowEur;
  final String summary;
}

class ElliottWaveAnalyzer {
  const ElliottWaveAnalyzer();

  WaveAnalysis analyze(SecuritySnapshot snapshot) {
    final points = snapshot.history;
    final pivots = <int>[];
    for (var i = 1; i < points.length - 1; i++) {
      final a = points[i - 1].priceEur;
      final b = points[i].priceEur;
      final c = points[i + 1].priceEur;
      if ((b > a && b > c) || (b < a && b < c)) pivots.add(i);
    }

    List<WaveLabel> labelsFor(int offset, List<String> names) {
      final selected = pivots.length <= 8 ? pivots : pivots.sublist(pivots.length - 8);
      final labels = <WaveLabel>[];
      for (var i = 0; i < selected.length && i < names.length; i++) {
        final index = (selected[i] + offset).clamp(0, points.length - 1);
        labels.add(WaveLabel(index: index, label: names[i]));
      }
      return labels;
    }

    final current = snapshot.currentPriceEur;
    final range = snapshot.allTimeHighEur - snapshot.allTimeLowEur;
    final lookback = points.length > 20 ? points[points.length - 20].priceEur : points.first.priceEur;
    final momentum = current - lookback;
    final normalized = range == 0 ? 0.0 : momentum / range;
    final bias = normalized > 0.055
        ? MarketBias.bullish
        : normalized < -0.055
            ? MarketBias.bearish
            : MarketBias.neutral;
    final score = (58 + normalized.abs() * 180).round().clamp(58, 92);

    return WaveAnalysis(
      counts: [
        WaveCount(
          id: 'primary',
          name: 'Hauptzählung',
          labels: labelsFor(0, const ['1', '2', '3', '4', '5', 'A', 'B', 'C']),
          probability: bias == MarketBias.neutral ? 58 : 72,
          bias: bias,
          isPrimary: true,
        ),
        WaveCount(
          id: 'alternative_a',
          name: 'Alternative A',
          labels: labelsFor(-2, const ['(1)', '(2)', '(3)', '(4)', '(5)', 'A', 'B', 'C']),
          probability: 19,
          bias: bias == MarketBias.bearish ? MarketBias.neutral : MarketBias.bearish,
          isPrimary: false,
        ),
        WaveCount(
          id: 'alternative_b',
          name: 'Alternative B',
          labels: labelsFor(2, const ['i', 'ii', 'iii', 'iv', 'v', 'a', 'b', 'c']),
          probability: 9,
          bias: bias == MarketBias.bullish ? MarketBias.neutral : MarketBias.bullish,
          isPrimary: false,
        ),
      ],
      score: score,
      bias: bias,
      bullishTargetEur: current + range * 0.18,
      baseTargetEur: current + range * (bias == MarketBias.bearish ? -0.05 : 0.06),
      bearishTargetEur: (current - range * 0.16).clamp(0.01, double.infinity),
      invalidAboveEur: current + range * 0.11,
      invalidBelowEur: (current - range * 0.09).clamp(0.01, double.infinity),
      summary: bias == MarketBias.bullish
          ? 'Die Hauptzählung spricht für eine intakte Aufwärtsstruktur. Unterhalb der Invalidierungsmarke muss die Zählung neu bewertet werden.'
          : bias == MarketBias.bearish
              ? 'Die Hauptzählung deutet auf eine laufende Abwärts- oder Korrekturphase. Erst oberhalb der oberen Invalidierungsmarke verbessert sich das Bild.'
              : 'Die Wellenstruktur ist derzeit nicht eindeutig. Haupt- und Alternativzählungen liegen vergleichsweise nah beieinander.',
    );
  }
}
