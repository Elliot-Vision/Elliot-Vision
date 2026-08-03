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
    super.key,
  });

  final Instrument instrument;
  final AnalysisResult analysis;
  final Set<String> visibleScenarioIds;
  final int historyPoints;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Kurschart für ${instrument.name} mit ${visibleScenarioIds.length} sichtbaren Szenarien',
      child: SizedBox(
        height: 310,
        width: double.infinity,
        child: CustomPaint(
          painter: _ChartPainter(
            instrument: instrument,
            analysis: analysis,
            visibleScenarioIds: visibleScenarioIds,
            historyPoints: historyPoints,
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
  });

  final Instrument instrument;
  final AnalysisResult analysis;
  final Set<String> visibleScenarioIds;
  final int historyPoints;

  @override
  void paint(Canvas canvas, Size size) {
    final background = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(20),
    );
    canvas.drawRRect(background, Paint()..color = AppPalette.surface);

    const left = 18.0;
    const right = 12.0;
    const top = 34.0;
    const bottom = 30.0;
    final width = size.width - left - right;
    final height = size.height - top - bottom;
    final historyEndX = left + width * 0.62;

    final fullHistory = instrument.historyEuro;
    final startIndex = math.max(0, fullHistory.length - historyPoints);
    final history = fullHistory.sublist(startIndex);
    final visibleScenarios = analysis.scenarios
        .where((scenario) => visibleScenarioIds.contains(scenario.id))
        .toList();

    final values = <double>[...history];
    for (final scenario in visibleScenarios) {
      values.addAll(scenario.projectionEuro);
      values.add(scenario.targetEuro);
      values.add(scenario.invalidationEuro);
    }
    final rawMin = values.reduce(math.min);
    final rawMax = values.reduce(math.max);
    final padding = math.max((rawMax - rawMin) * 0.12, rawMax * 0.03);
    final minValue = rawMin - padding;
    final maxValue = rawMax + padding;

    double yFor(double value) =>
        top + height - ((value - minValue) / (maxValue - minValue)) * height;

    final gridPaint = Paint()
      ..color = AppPalette.line
      ..strokeWidth = 1;
    for (var index = 0; index <= 4; index++) {
      final y = top + (height / 4) * index;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }
    canvas.drawLine(
      Offset(historyEndX, top),
      Offset(historyEndX, top + height),
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
      fontWeight: FontWeight.w700,
    );
    _paintText(
      canvas,
      'PROJEKTION',
      Offset(historyEndX + 10, 12),
      color: AppPalette.muted,
      fontSize: 10,
      fontWeight: FontWeight.w700,
    );

    if (history.length > 1) {
      final historyPath = Path();
      for (var index = 0; index < history.length; index++) {
        final x =
            left +
            (historyEndX - left) * (index / math.max(1, history.length - 1));
        final point = Offset(x, yFor(history[index]));
        if (index == 0) {
          historyPath.moveTo(point.dx, point.dy);
        } else {
          historyPath.lineTo(point.dx, point.dy);
        }
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
    }

    for (final scenario in visibleScenarios) {
      final color = scenarioColor(scenario.kind);
      final path = Path()..moveTo(historyEndX, yFor(instrument.euroPrice));
      for (var index = 0; index < scenario.projectionEuro.length; index++) {
        final x =
            historyEndX +
            (size.width - right - historyEndX) *
                ((index + 1) / scenario.projectionEuro.length);
        path.lineTo(x, yFor(scenario.projectionEuro[index]));
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = scenario.id == analysis.primaryScenarioId ? 3 : 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );

      final targetY = yFor(scenario.targetEuro);
      _drawDashedLine(
        canvas,
        Offset(historyEndX + 8, targetY),
        Offset(size.width - right, targetY),
        Paint()
          ..color = color.withAlpha(115)
          ..strokeWidth = 1,
      );
    }

    final currentPoint = Offset(historyEndX, yFor(instrument.euroPrice));
    canvas.drawCircle(currentPoint, 5, Paint()..color = AppPalette.ink);
    canvas.drawCircle(
      currentPoint,
      8,
      Paint()
        ..color = AppPalette.ink.withAlpha(35)
        ..style = PaintingStyle.fill,
    );

    final primaryVisible = visibleScenarios
        .where((scenario) => scenario.id == analysis.primaryScenarioId)
        .toList();
    if (primaryVisible.isNotEmpty) {
      final projection = primaryVisible.first.projectionEuro;
      const waveIndexes = [3, 7, 11, 15, 19, 23, 27];
      const labels = ['1', '2', '3', '4', '5', 'A', 'C'];
      for (var index = 0; index < waveIndexes.length; index++) {
        final projectionIndex = math.min(
          waveIndexes[index],
          projection.length - 1,
        );
        final x =
            historyEndX +
            (size.width - right - historyEndX) *
                ((projectionIndex + 1) / projection.length);
        _paintText(
          canvas,
          labels[index],
          Offset(x - 3, yFor(projection[projectionIndex]) - 17),
          color: scenarioColor(primaryVisible.first.kind),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        );
      }
    }

    _paintText(
      canvas,
      'ATL ${_compactEuro(instrument.atlEuro)}',
      Offset(left, size.height - 21),
      color: AppPalette.muted,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );
    final athText = 'ATH ${_compactEuro(instrument.athEuro)}';
    final painter = _textPainter(
      athText,
      color: AppPalette.muted,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );
    painter.paint(
      canvas,
      Offset(size.width - right - painter.width, size.height - 21),
    );
  }

  String _compactEuro(double value) =>
      '${value.toStringAsFixed(value < 10 ? 2 : 0).replaceAll('.', ',')} €';

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
        oldDelegate.analysis.id != analysis.id ||
        oldDelegate.historyPoints != historyPoints ||
        !_sameIds(oldDelegate.visibleScenarioIds, visibleScenarioIds);
  }

  bool _sameIds(Set<String> first, Set<String> second) =>
      first.length == second.length && first.containsAll(second);
}
