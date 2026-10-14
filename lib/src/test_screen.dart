import 'package:flutter/material.dart';

import 'analysis_engine.dart';
import 'demo_data.dart';
import 'experimental_chart.dart';
import 'models.dart';

/// Eigene Demodaten, keine Verbindung zum produktiven AppState oder Speicher.
class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  late final Instrument _instrument = DemoMarketDataRepository().byId('aapl');
  late final AnalysisResult _analysis = RuleBasedAnalysisGateway().analyze(
    _instrument,
    now: DateTime.utc(2026, 8, 4),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        key: const ValueKey('test-content-list'),
        padding: const EdgeInsets.all(20),
        children: [
          Text('Testbereich',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          const Text(
            'Experimenteller Chart mit Demodaten – keine aktuellen Kurse. '
            'Depot, Favoriten und Analysehistorie werden nicht verändert.',
          ),
          const SizedBox(height: 20),
          Text(_instrument.name),
          const SizedBox(height: 12),
          ExperimentalScenarioChart(
            instrument: _instrument,
            analysis: _analysis,
            visibleScenarioIds: _analysis.scenarios.map((s) => s.id).toSet(),
            historyPoints: _instrument.pricePoints.length,
          ),
        ],
      ),
    );
  }
}
