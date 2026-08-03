import 'package:flutter_test/flutter_test.dart';
import 'package:elliott_vision/elliott_vision.dart';

void main() {
  group('RuleBasedDemoAnalysisGateway', () {
    final repository = DemoMarketDataRepository();
    final gateway = RuleBasedDemoAnalysisGateway();

    test('erzeugt drei Szenarien mit insgesamt 100 Prozent', () {
      final instrument = repository.byId('uec');
      final result = gateway.analyze(
        instrument,
        now: DateTime.utc(2026, 8, 3, 12),
      );

      expect(result.scenarios, hasLength(3));
      expect(
        result.scenarios.fold<int>(
          0,
          (sum, scenario) => sum + scenario.probability,
        ),
        100,
      );
      expect(result.primaryScenario.probability, greaterThanOrEqualTo(15));
    });

    test('liefert für jedes Szenario Ziel, Invalidierung und Projektion', () {
      final instrument = repository.byId('aapl');
      final result = gateway.analyze(instrument);

      for (final scenario in result.scenarios) {
        expect(scenario.targetEuro, greaterThan(0));
        expect(scenario.invalidationEuro, greaterThan(0));
        expect(scenario.projectionEuro.length, greaterThan(20));
        expect(
          scenario.projectionEuro.first,
          closeTo(instrument.euroPrice, 0.01),
        );
      }
    });

    test('erzeugt reproduzierbare Snapshot-Metadaten', () {
      final timestamp = DateTime.utc(2026, 8, 3, 12, 30);
      final result = gateway.analyze(repository.byId('dro'), now: timestamp);

      expect(result.createdAt, timestamp);
      expect(result.engineVersion, 'regelwerk-demo-v0.1');
      expect(result.explanationModel, contains('Demo-Modus'));
    });
  });
}
