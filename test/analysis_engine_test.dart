import 'package:flutter_test/flutter_test.dart';
import 'package:elliott_vision/elliott_vision.dart';

void main() {
  group('RuleBasedAnalysisGateway', () {
    final repository = DemoMarketDataRepository();
    final gateway = RuleBasedAnalysisGateway();

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
      expect(result.primaryScenario.probability, greaterThan(0));
      expect(result.methodology, contains('ZigZag'));
    });

    test('liefert für jedes Szenario Ziel, Invalidierung und Projektion', () {
      final instrument = repository.byId('aapl');
      final result = gateway.analyze(instrument);

      for (final scenario in result.scenarios) {
        expect(scenario.targetEuro, greaterThan(0));
        expect(scenario.invalidationEuro, greaterThan(0));
        expect(scenario.entryLowEuro, greaterThan(0));
        expect(scenario.entryHighEuro, greaterThan(0));
        expect(scenario.exitLowEuro, greaterThan(0));
        expect(scenario.stopLossEuro, greaterThan(0));
        expect(scenario.probabilityFactors, isNotEmpty);
        expect(scenario.countMethod, isNotEmpty);
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
      expect(result.engineVersion, 'elliott-pivot-engine-v2.0.0');
      expect(result.explanationModel, contains('kein LLM'));
      expect(result.instrumentSnapshot?.id, 'dro');
      expect(result.promptVersion, 'nicht verwendet');
    });

    test('erkennt einen regelkonformen bullischen Fuenferimpuls', () {
      final source = repository.byId('aapl');
      final history = <double>[
        100,
        115,
        130,
        110,
        150,
        190,
        150,
        185,
        220,
        185,
      ];
      final instrument = source.copyWith(
        euroPrice: history.last,
        originalPrice: history.last,
        historyEuro: history,
        timeframe: ChartTimeframe.oneMonth,
      );

      final result = gateway.analyze(instrument);
      final bullish = result.scenarios.firstWhere(
        (scenario) => scenario.kind == ScenarioKind.bullish,
      );

      expect(bullish.passesAllHardRules, isTrue);
      expect(bullish.rulesSatisfied, bullish.rulesTotal);
      expect(bullish.ruleChecks, contains(contains('Welle 2')));
      expect(bullish.ruleChecks, contains(contains('Welle 3')));
      expect(bullish.ruleChecks, contains(contains('Welle 4')));
      expect(bullish.waveMarkers.map((marker) => marker.label),
          containsAll(<String>['1', '2', '3', '4', '5']));
    });
  });
}
