import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app.dart';
import 'models.dart';

Color scenarioColor(ScenarioKind kind) {
  switch (kind) {
    case ScenarioKind.bullish:
      return AppPalette.limeDark;
    case ScenarioKind.neutral:
      return AppPalette.blue;
    case ScenarioKind.bearish:
      return AppPalette.red;
  }
}

class ElliottScenarioChart extends StatelessWidget {
  const ElliottScenarioChart({
    required this.instrument,
    required this.analysis,
    required this.visibleScenarioIds,
    required this.historyPoints,
    this.showZones = true,
    super.key,
  });

  final Instrument instrument;
  final AnalysisResult analysis;
  final Set<String> visibleScenarioIds;
  final int historyPoints;
  final bool showZones;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Kurschart für ${instrument.name} im Zeitraum ${instrument.timeframe.label} '
          'mit ${visibleScenarioIds.length} sichtbaren Szenarien',
      child: SizedBox(
        height: 350,
        width: double.infinity,
        child: CustomPaint(
          painter: _ChartPainter(
            instrument: instrument,
            analysis: analysis,
            visibleScenarioIds: visibleScenarioIds,
            historyPoints: historyPoints,
            showZones: showZones,
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.instrument,
    required this.analysis,
    required this.visibleScenarioIds,
    required this.historyPoints,
    required this.showZones,
  });

  final Instrument instrument;
  final AnalysisResult analysis;
  final Set<String> visibleScenarioIds;
  final int historyPoints;
  final bool showZones;

  @override
  void paint(Canvas canvas, Size size) {
    final background = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(20),
    );
    canvas.drawRRect(background, Paint()..color = AppPalette.surface);

    const left = 58.0;
    const right = 14.0;
    const top = 34.0;
    const bottom = 52.0;
    final plotWidth = size.width - left - right;
    final plotHeight = size.height - top - bottom;
    final historyEndX = left + plotWidth * 0.64;

    final fullPoints = instrument.pricePoints;
    final startIndex = math.max(0, fullPoints.length - historyPoints);
    final history = fullPoints.sublist(startIndex);
    final visibleScenarios = analysis.scenarios
        .where((scenario) => visibleScenarioIds.contains(scenario.id))
        .toList();

    final values = <double>[
      ...history.map((point) => point.euro),
      instrument.euroPrice,
    ];
    for (final scenario in visibleScenarios) {
      values
        ..addAll(scenario.projectionEuro)
        ..addAll([
          scenario.targetEuro,
          scenario.invalidationEuro,
          scenario.entryLowEuro,
          scenario.entryHighEuro,
          scenario.exitLowEuro,
          scenario.exitHighEuro,
          scenario.stopLossEuro,
        ]);
    }
    final rawMin = values.reduce(math.min);
    final rawMax = values.reduce(math.max);
    final rawRange = math
        .max(rawMax - rawMin, math.max(rawMax.abs() * 0.04, 0.01))
        .toDouble();
    final minValue = rawMin - rawRange * 0.10;
    final maxValue = rawMax + rawRange * 0.10;

    double yFor(double value) =>
        top + plotHeight - ((value - minValue) / (maxValue - minValue)) * plotHeight;

    if (showZones) {
      for (final scenario in visibleScenarios) {
        final primary = scenario.id == analysis.primaryScenarioId;
        final color = scenarioColor(scenario.kind);
        _drawZone(
          canvas,
          historyEndX,
          size.width - right,
          yFor(scenario.entryLowEuro),
          yFor(scenario.entryHighEuro),
          AppPalette.blue.withAlpha(primary ? 34 : 16),
        );
        _drawZone(
          canvas,
          historyEndX,
          size.width - right,
          yFor(scenario.exitLowEuro),
          yFor(scenario.exitHighEuro),
          color.withAlpha(primary ? 30 : 14),
        );
        _drawDashedLine(
          canvas,
          Offset(historyEndX, yFor(scenario.stopLossEuro)),
          Offset(size.width - right, yFor(scenario.stopLossEuro)),
          Paint()
            ..color = AppPalette.red.withAlpha(primary ? 180 : 95)
            ..strokeWidth = primary ? 1.4 : 1,
        );
      }
    }

    final gridPaint = Paint()
      ..color = AppPalette.line
      ..strokeWidth = 1;
    for (var index = 0; index <= 4; index++) {
      final y = top + (plotHeight / 4) * index;
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), gridPaint);
      final value = maxValue - (maxValue - minValue) * index / 4;
      _paintTextRight(
        canvas,
        _axisEuro(value),
        Offset(left - 7, y - 6),
        color: AppPalette.muted,
        fontSize: 9,
        fontWeight: FontWeight.w600,
      );
    }
    canvas.drawLine(
      Offset(historyEndX, top),
      Offset(historyEndX, top + plotHeight),
      Paint()
        ..color = AppPalette.line
        ..strokeWidth = 1,
    );

    _paintText(
      canvas,
      'VERLAUF',
      const Offset(left, 12),
      color: AppPalette.muted,
      fontSize: 10,
      fontWeight: FontWeight.w800,
    );
    _paintText(
      canvas,
      'PROJEKTION',
      Offset(historyEndX + 9, 12),
      color: AppPalette.muted,
      fontSize: 10,
      fontWeight: FontWeight.w800,
    );

    if (history.length > 1) {
      final historyPath = Path();
      for (var index = 0; index < history.length; index++) {
        final x = left +
            (historyEndX - left) * (index / math.max(1, history.length - 1));
        final point = Offset(x, yFor(history[index].euro));
        index == 0
            ? historyPath.moveTo(point.dx, point.dy)
            : historyPath.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        historyPath,
        Paint()
          ..color = AppPalette.ink
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
      _drawXAxis(canvas, history, left, historyEndX, top + plotHeight + 9);
    }

    for (var scenarioIndex = 0;
        scenarioIndex < visibleScenarios.length;
        scenarioIndex++) {
      final scenario = visibleScenarios[scenarioIndex];
      final color = scenarioColor(scenario.kind);
      final path = Path()..moveTo(historyEndX, yFor(instrument.euroPrice));
      for (var index = 0; index < scenario.projectionEuro.length; index++) {
        final x = historyEndX +
            (size.width - right - historyEndX) *
                ((index + 1) / scenario.projectionEuro.length);
        path.lineTo(x, yFor(scenario.projectionEuro[index]));
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = scenario.id == analysis.primaryScenarioId ? 3 : 1.8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
      _drawDashedLine(
        canvas,
        Offset(historyEndX + 5, yFor(scenario.targetEuro)),
        Offset(size.width - right, yFor(scenario.targetEuro)),
        Paint()
          ..color = color.withAlpha(115)
          ..strokeWidth = 1,
      );
      _drawDashedLine(
        canvas,
        Offset(left, yFor(scenario.invalidationEuro)),
        Offset(size.width - right, yFor(scenario.invalidationEuro)),
        Paint()
          ..color = color.withAlpha(70)
          ..strokeWidth = 1,
      );
      _drawWaveLabels(
        canvas,
        scenario,
        historyEndX,
        size.width - right,
        yFor,
        scenarioIndex,
      );
      _drawHistoricalWaveMarkers(
        canvas,
        scenario,
        startIndex,
        history.length,
        left,
        historyEndX,
        yFor,
        scenarioIndex,
      );
    }

    final currentPoint = Offset(historyEndX, yFor(instrument.euroPrice));
    canvas.drawCircle(currentPoint, 5, Paint()..color = AppPalette.ink);
    canvas.drawCircle(
      currentPoint,
      8,
      Paint()..color = AppPalette.ink.withAlpha(35),
    );
    _paintTextRight(
      canvas,
      _axisEuro(instrument.euroPrice),
      Offset(historyEndX - 8, currentPoint.dy - 18),
      color: AppPalette.ink,
      fontSize: 10,
      fontWeight: FontWeight.w800,
    );

    _paintText(
      canvas,
      'ATH ${_compactEuro(instrument.athEuro)} '
          '(${instrument.distanceToAthPercent.toStringAsFixed(1).replaceAll('.', ',')} %)',
      Offset(left, size.height - 16),
      color: AppPalette.muted,
      fontSize: 9,
      fontWeight: FontWeight.w600,
    );
    final atlText = 'ATL ${_compactEuro(instrument.atlEuro)}';
    final atlPainter = _textPainter(
      atlText,
      color: AppPalette.muted,
      fontSize: 9,
      fontWeight: FontWeight.w600,
    );
    atlPainter.paint(
      canvas,
      Offset(size.width - right - atlPainter.width, size.height - 16),
    );
  }

  void _drawXAxis(
    Canvas canvas,
    List<PricePoint> points,
    double left,
    double right,
    double y,
  ) {
    final indexes = <int>{0, points.length ~/ 2, points.length - 1}.toList()
      ..sort();
    for (var position = 0; position < indexes.length; position++) {
      final index = indexes[position];
      final x = left + (right - left) * (index / math.max(1, points.length - 1));
      final label = _axisDate(points[index].timestamp);
      if (position == 0) {
        _paintText(
          canvas,
          label,
          Offset(x, y),
          color: AppPalette.muted,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        );
      } else {
        _paintTextRight(
          canvas,
          label,
          Offset(x, y),
          color: AppPalette.muted,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        );
      }
    }
  }

  void _drawWaveLabels(
    Canvas canvas,
    AnalysisScenario scenario,
    double fromX,
    double toX,
    double Function(double) yFor,
    int scenarioIndex,
  ) {
    if (scenario.projectionEuro.isEmpty || scenario.waveLabels.isEmpty) {
      return;
    }
    final labels = scenario.waveLabels;
    for (var index = 0; index < labels.length; index++) {
      final projectionIndex = ((index + 1) * scenario.projectionEuro.length /
              (labels.length + 1))
          .round()
          .clamp(0, scenario.projectionEuro.length - 1)
          .toInt();
      final x = fromX +
          (toX - fromX) *
              ((projectionIndex + 1) / scenario.projectionEuro.length);
      final y = yFor(scenario.projectionEuro[projectionIndex]);
      _paintText(
        canvas,
        labels[index],
        Offset(x - 3, y - 15 - scenarioIndex * 8),
        color: scenarioColor(scenario.kind),
        fontSize: 8,
        fontWeight: FontWeight.w900,
      );
    }
  }

  void _drawHistoricalWaveMarkers(
    Canvas canvas,
    AnalysisScenario scenario,
    int historyStartIndex,
    int visibleHistoryLength,
    double fromX,
    double toX,
    double Function(double) yFor,
    int scenarioIndex,
  ) {
    if (visibleHistoryLength < 2 || scenario.waveMarkers.isEmpty) {
      return;
    }
    final color = scenarioColor(scenario.kind);
    for (final marker in scenario.waveMarkers) {
      final localIndex = marker.historyIndex - historyStartIndex;
      if (localIndex < 0 || localIndex >= visibleHistoryLength) {
        continue;
      }
      final x = fromX +
          (toX - fromX) * (localIndex / (visibleHistoryLength - 1));
      final y = yFor(marker.priceEuro);
      canvas.drawCircle(
        Offset(x, y),
        3.2,
        Paint()
          ..color = AppPalette.surface
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(x, y),
        3.2,
        Paint()
          ..color = color
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke,
      );
      _paintText(
        canvas,
        marker.label,
        Offset(x - 3, y - 14 - scenarioIndex * 7),
        color: color,
        fontSize: 8,
        fontWeight: FontWeight.w900,
      );
    }
  }

  String _axisDate(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    if (instrument.timeframe == ChartTimeframe.oneDay ||
        instrument.timeframe == ChartTimeframe.fiveDays) {
      return '${two(local.hour)}:${two(local.minute)}';
    }
    if (instrument.timeframe == ChartTimeframe.oneMonth ||
        instrument.timeframe == ChartTimeframe.threeMonths) {
      return '${two(local.day)}.${two(local.month)}.';
    }
    return '${two(local.month)}.${local.year.toString().substring(2)}';
  }

  String _axisEuro(double value) {
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1).replaceAll('.', ',')}k €';
    }
    return '${value.toStringAsFixed(value.abs() < 10 ? 2 : 0).replaceAll('.', ',')} €';
  }

  String _compactEuro(double value) =>
      '${value.toStringAsFixed(value < 10 ? 2 : 0).replaceAll('.', ',')} €';

  void _drawZone(
    Canvas canvas,
    double left,
    double right,
    double firstY,
    double secondY,
    Color color,
  ) {
    canvas.drawRect(
      Rect.fromLTRB(left, math.min(firstY, secondY), right, math.max(firstY, secondY)),
      Paint()..color = color,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dash = 5.0;
    const gap = 4.0;
    var x = start.dx;
    while (x < end.dx) {
      canvas.drawLine(
        Offset(x, start.dy),
        Offset(math.min(x + dash, end.dx), end.dy),
        paint,
      );
      x += dash + gap;
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset, {
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
  }) {
    _textPainter(
      text,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    ).paint(canvas, offset);
  }

  void _paintTextRight(
    Canvas canvas,
    String text,
    Offset anchor, {
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
  }) {
    final painter = _textPainter(
      text,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
    painter.paint(canvas, Offset(anchor.dx - painter.width, anchor.dy));
  }

  TextPainter _textPainter(
    String text, {
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.instrument.id != instrument.id ||
        oldDelegate.instrument.dataTimestamp != instrument.dataTimestamp ||
        oldDelegate.instrument.timeframe != instrument.timeframe ||
        oldDelegate.analysis.id != analysis.id ||
        oldDelegate.historyPoints != historyPoints ||
        oldDelegate.showZones != showZones ||
        !_sameIds(oldDelegate.visibleScenarioIds, visibleScenarioIds);
  }

  bool _sameIds(Set<String> first, Set<String> second) =>
      first.length == second.length && first.containsAll(second);
}
