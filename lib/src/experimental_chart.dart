import 'chart.dart';

export 'chart.dart' show ChartViewport;

/// Shares the regular renderer while TestScreen owns its demo data.
class ExperimentalScenarioChart extends ElliottScenarioChart {
  const ExperimentalScenarioChart({
    required super.instrument,
    required super.analysis,
    required super.visibleScenarioIds,
    required super.historyPoints,
    super.showZones,
    super.highlightedScenarioId,
    super.onScenarioSelected,
    super.key,
  });
}
