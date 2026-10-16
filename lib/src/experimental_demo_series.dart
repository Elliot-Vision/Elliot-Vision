import 'dart:math' as math;

import 'models.dart';

/// Synthetic, deterministic chart fixtures. Never used by live market data.
Instrument experimentalDemoSeries(Instrument source, ChartTimeframe timeframe) {
  final (days, intervals) = switch (timeframe) {
    ChartTimeframe.oneDay => (1, 288),
    ChartTimeframe.fiveDays => (5, 240),
    ChartTimeframe.oneMonth => (30, 30),
    ChartTimeframe.threeMonths => (90, 90),
    ChartTimeframe.oneYear => (365, 52),
    ChartTimeframe.fiveYears => (1825, 60),
    ChartTimeframe.maximum => (3650, 120),
  };
  final end = source.dataTimestamp;
  final span = Duration(days: days).inMicroseconds;
  final timestamps = List.generate(
      intervals + 1,
      (index) => end.subtract(
          Duration(microseconds: (span * (1 - index / intervals)).round())));
  // A shared ten-year baseline plus short and medium synthetic oscillations
  // makes each window distinct without presenting it as real exchange data.
  double oscillation(double day) =>
      math.sin(day * 2 * math.pi / 0.7) * 0.004 +
      math.sin(day * 2 * math.pi / 23) * 0.025;
  final values = timestamps.map((time) {
    final day =
        time.difference(end).inMicroseconds / Duration.microsecondsPerDay;
    final position = ((day + 3650) / 3650 * (source.historyEuro.length - 1))
        .clamp(0.0, (source.historyEuro.length - 1).toDouble());
    final low = position.floor();
    final high = math.min(low + 1, source.historyEuro.length - 1);
    final baseline = source.historyEuro[low] +
        (source.historyEuro[high] - source.historyEuro[low]) * (position - low);
    return math.max(0.01, baseline + source.euroPrice * oscillation(day));
  }).toList();
  values[values.length - 1] = source.euroPrice;
  return source.copyWith(
      timeframe: timeframe,
      historyEuro: values,
      historyTimestamps: timestamps,
      dataSource: 'Synthetische Demodaten',
      isLive: false);
}
