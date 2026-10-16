import 'package:flutter/material.dart';
import 'chart.dart';
import 'models.dart';
import 'scenario_details.dart';

/// Selection lives alongside the chart and never changes saved analyses.
class ScenarioFocusChart extends StatefulWidget {
  const ScenarioFocusChart(
      {required this.instrument,
      required this.analysis,
      required this.visibleScenarioIds,
      required this.historyPoints,
      this.showZones = true,
      super.key});
  final Instrument instrument;
  final AnalysisResult analysis;
  final Set<String> visibleScenarioIds;
  final int historyPoints;
  final bool showZones;
  @override
  State<ScenarioFocusChart> createState() => _ScenarioFocusChartState();
}

class _ScenarioFocusChartState extends State<ScenarioFocusChart> {
  String? _selected;
  @override
  void didUpdateWidget(covariant ScenarioFocusChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.instrument, widget.instrument) ||
        oldWidget.analysis.id != widget.analysis.id ||
        !widget.visibleScenarioIds.contains(_selected)) {
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scenarios = widget.analysis.scenarios
        .where((s) => widget.visibleScenarioIds.contains(s.id))
        .toList();
    final selected = scenarios.where((s) => s.id == _selected).firstOrNull;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ElliottScenarioChart(
        instrument: widget.instrument,
        analysis: widget.analysis,
        visibleScenarioIds: widget.visibleScenarioIds,
        historyPoints: widget.historyPoints,
        showZones: widget.showZones,
        highlightedScenarioId: _selected,
        onScenarioSelected: (id) => setState(() => _selected = id),
      ),
      const Text(
          'Projektion oder farbigen Bereich antippen, um das Szenario hervorzuheben. '
          'Mit einem Finger über die Projektion fahren, um Modellpreise abzulesen.'),
      Wrap(spacing: 8, children: [
        for (final s in scenarios)
          ChoiceChip(
            key: ValueKey('analysis-highlight-${s.kind.name}'),
            label: Text('${s.kind.label} hervorheben'),
            selected: s.id == _selected,
            onSelected: (value) =>
                setState(() => _selected = value ? s.id : null),
          ),
      ]),
      if (selected != null)
        ScenarioDetails(
            instrument: widget.instrument,
            scenario: selected,
            zonesVisible: widget.showZones,
            onClear: () => setState(() => _selected = null)),
    ]);
  }
}
