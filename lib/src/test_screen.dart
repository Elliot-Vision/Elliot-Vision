import 'package:flutter/material.dart';

import 'analysis_engine.dart';
import 'demo_data.dart';
import 'experimental_chart.dart';
import 'experimental_demo_series.dart';
import 'models.dart';

/// Eigene Demodaten, keine Verbindung zum produktiven AppState oder Speicher.
class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final _repository = DemoMarketDataRepository();
  late final List<Instrument> _instruments = List.of(_repository.instruments);
  late Instrument _instrument =
      experimentalDemoSeries(_instruments.first, ChartTimeframe.maximum);
  late AnalysisResult _analysis = RuleBasedAnalysisGateway().analyze(
    _instrument,
    now: DateTime.utc(2026, 8, 4),
  );
  final _visibleKinds = ScenarioKind.values.toSet();
  bool _showZones = true;

  List<AnalysisScenario> get _testScenarios {
    final ranked = List<AnalysisScenario>.of(_analysis.scenarios)
      ..sort((a, b) {
        if (a.id == b.id) return 0;
        if (a.id == _analysis.primaryScenarioId) return -1;
        if (b.id == _analysis.primaryScenarioId) return 1;
        return b.probability.compareTo(a.probability);
      });
    return ranked.take(2).toList();
  }

  void _select(String id, ChartTimeframe timeframe) {
    // Always use the complete demo series, including when returning from 1D.
    final source = _instruments.firstWhere((item) => item.id == id);
    final instrument = experimentalDemoSeries(source, timeframe);
    setState(() {
      _instrument = instrument;
      _analysis = RuleBasedAnalysisGateway()
          .analyze(instrument, now: DateTime.utc(2026, 8, 4));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        key: const ValueKey('test-content-list'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        children: [
          Text('Testbereich',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          const Text(
            'Experimenteller Chart mit synthetischen Demodaten – keine aktuellen Kurse. '
            'Depot, Favoriten und Analysehistorie werden nicht verändert.',
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            key: const ValueKey('test-instrument'),
            initialValue: _instrument.id,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Demo-Wertpapier'),
            items: _instruments
                .map((item) => DropdownMenuItem(
                      value: item.id,
                      child: Text('${item.name} (${item.ticker})'),
                    ))
                .toList(),
            onChanged: (id) {
              if (id != null) _select(id, _instrument.timeframe);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ChartTimeframe>(
            key: const ValueKey('test-timeframe'),
            initialValue: _instrument.timeframe,
            decoration: const InputDecoration(labelText: 'Zeitraum'),
            items: ChartTimeframe.values
                .map((value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.label),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) _select(_instrument.id, value);
            },
          ),
          const SizedBox(height: 12),
          ExperimentalScenarioChart(
            instrument: _instrument,
            analysis: _analysis,
            visibleScenarioIds: _testScenarios
                .where((s) => _visibleKinds.contains(s.kind))
                .map((s) => s.id)
                .toSet(),
            historyPoints: _instrument.pricePoints.length,
            showZones: _showZones,
          ),
          const SizedBox(height: 16),
          Text('Szenarien', style: Theme.of(context).textTheme.titleMedium),
          const Text('Hauptszenario und stärkste Alternative'),
          Wrap(
            spacing: 8,
            children: _testScenarios
                .map((scenario) => scenario.kind)
                .map((kind) => FilterChip(
                      key: ValueKey('test-scenario-${kind.name}'),
                      label: Text(kind.label),
                      selected: _visibleKinds.contains(kind),
                      onSelected: (selected) => setState(() {
                        selected
                            ? _visibleKinds.add(kind)
                            : _visibleKinds.remove(kind);
                      }),
                    ))
                .toList(),
          ),
          if (_visibleKinds.isEmpty)
            const Text(
                'Alle Szenarien ausgeblendet – nur der Kursverlauf ist sichtbar.'),
          SwitchListTile.adaptive(
            key: const ValueKey('test-zones'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Zonen anzeigen'),
            subtitle: const Text('Einstieg, Ausstieg und Stop-Loss'),
            value: _showZones,
            onChanged: (value) => setState(() => _showZones = value),
          ),
        ],
      ),
    );
  }
}
