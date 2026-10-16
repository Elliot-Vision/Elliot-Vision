import 'package:flutter_test/flutter_test.dart';
import 'package:elliott_vision/src/demo_data.dart';
import 'package:elliott_vision/src/models.dart';
import 'package:elliott_vision/src/experimental_demo_series.dart';

void main() {
  test(
      'Demo-Zeiträume decken ihre tatsächliche Dauer ab und enden am selben Kurs',
      () {
    final source = DemoMarketDataRepository().instruments.first;
    final days = [1, 5, 30, 90, 365, 1825, 3650];
    for (var i = 0; i < ChartTimeframe.values.length; i++) {
      final series = experimentalDemoSeries(source, ChartTimeframe.values[i]);
      final points = series.pricePoints;
      expect(points.last.timestamp, source.dataTimestamp);
      expect(points.last.timestamp.difference(points.first.timestamp),
          Duration(days: days[i]));
      expect(points.last.euro, source.euroPrice);
      expect(points.every((p) => p.euro.isFinite && p.euro > 0), isTrue);
      for (var n = 1; n < points.length; n++) {
        expect(points[n].timestamp.isAfter(points[n - 1].timestamp), isTrue);
      }
      expect(series.isLive, isFalse);
    }
  });

  test('Ein und drei Monate besitzen unterschiedliche Demo-Verläufe', () {
    final source = DemoMarketDataRepository().instruments.first;
    final month = experimentalDemoSeries(source, ChartTimeframe.oneMonth);
    final quarter = experimentalDemoSeries(source, ChartTimeframe.threeMonths);
    expect(month.historyEuro.first, isNot(quarter.historyEuro.first));
    expect(experimentalDemoSeries(source, ChartTimeframe.oneMonth).historyEuro,
        month.historyEuro);
    expect(source.historyEuro.length, 36);
  });
}
