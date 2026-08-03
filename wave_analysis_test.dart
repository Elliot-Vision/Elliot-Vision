import 'package:elliott_wave_app/models/security.dart';
import 'package:elliott_wave_app/models/wave_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('analysis creates ordered scenarios', () {
    final security = Security(isin: 'TEST', name: 'Test', symbol: 'T', currency: 'EUR');
    final history = List.generate(20, (i) => PricePoint(DateTime(2026, 1, i + 1), 10 + i.toDouble()));
    final snapshot = SecuritySnapshot(
      security: security,
      currentPriceEur: 29,
      allTimeHighEur: 29,
      allTimeLowEur: 10,
      history: history,
    );
    final result = const ElliottWaveAnalyzer().analyze(snapshot);
    expect(result.bullishTargetEur, greaterThan(result.baseTargetEur));
    expect(result.baseTargetEur, greaterThan(result.bearishTargetEur));
  });
}
