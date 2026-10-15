import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

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

/// Horizontaler Ausschnitt des gesamten Charts (Verlauf und Projektion).
class ChartViewport {
  const ChartViewport({this.start = 0, this.end = 1});
  final double start;
  final double end;
  double get span => end - start;
  double get zoom => 1 / span;

  ChartViewport transform({
    required ChartViewport initial,
    required double scale,
    required double initialFocal,
    required double currentFocal,
    double minimumSpan = 0.05,
  }) {
    if (!scale.isFinite || scale <= 0) return initial;
    final width = (initial.span / scale).clamp(minimumSpan, 1.0).toDouble();
    final anchor = initial.start + initialFocal * initial.span;
    final left =
        (anchor - currentFocal * width).clamp(0.0, 1.0 - width).toDouble();
    return ChartViewport(start: left, end: left + width);
  }
}

class ExperimentalScenarioChart extends StatefulWidget {
  const ExperimentalScenarioChart({
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
  State<ExperimentalScenarioChart> createState() =>
      _ExperimentalScenarioChartState();
}

class _ExperimentalScenarioChartState extends State<ExperimentalScenarioChart> {
  ChartViewport _viewport = const ChartViewport();
  ChartViewport _gestureStart = const ChartViewport();
  double _focalStart = 0;
  bool _restored = false;
  int? _selectedIndex;
  bool _selectedProjection = false;

  void _inspect(Offset position, double width) {
    final fraction =
        _viewport.start + _focalFraction(position, width) * _viewport.span;
    final points = widget.instrument.pricePoints;
    final start = math.max(0, points.length - widget.historyPoints);
    setState(() {
      _selectedProjection = fraction > 0.64;
      _selectedIndex = _selectedProjection || start >= points.length
          ? null
          : start +
              (fraction / 0.64 * (points.length - start - 1))
                  .round()
                  .clamp(0, points.length - start - 1);
    });
  }

  String get _inspectionLabel {
    if (_selectedProjection) return 'Projektion – kein historischer Kurs';
    if (_selectedIndex == null) return 'Mit einem Finger einen Kurs auswählen';
    final point = widget.instrument.pricePoints[_selectedIndex!];
    final date = point.timestamp.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${point.euro.toStringAsFixed(2).replaceAll('.', ',')} € · '
        '${two(date.day)}.${two(date.month)}.${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  String get _storageId => 'chart-viewport-${widget.instrument.id}-'
      '${widget.instrument.selectedSymbol}-${widget.instrument.timeframe.name}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_restored) {
      _viewport = PageStorage.maybeOf(context)?.readState(
            context,
            identifier: _storageId,
          ) as ChartViewport? ??
          const ChartViewport();
      _restored = true;
    }
  }

  @override
  void didUpdateWidget(covariant ExperimentalScenarioChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instrument.id != widget.instrument.id ||
        oldWidget.instrument.selectedSymbol !=
            widget.instrument.selectedSymbol ||
        oldWidget.instrument.timeframe != widget.instrument.timeframe) {
      _viewport = const ChartViewport();
      _selectedIndex = null;
      _selectedProjection = false;
      PageStorage.maybeOf(context)?.writeState(
        context,
        _viewport,
        identifier: _storageId,
      );
    }
  }

  void _setViewport(ChartViewport value) {
    setState(() {
      _viewport = value;
      _selectedIndex = null;
      _selectedProjection = false;
    });
    PageStorage.maybeOf(context)?.writeState(
      context,
      value,
      identifier: _storageId,
    );
  }

  double _focalFraction(Offset focal, double width) =>
      ((focal.dx - 58) / math.max(1.0, width - 72)).clamp(0.0, 1.0).toDouble();

  @override
  Widget build(BuildContext context) {
    final visibleIds = Set<String>.unmodifiable(widget.visibleScenarioIds);
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(_inspectionLabel,
                key: const ValueKey('chart-inspection'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        Semantics(
          label: 'Kurschart für ${widget.instrument.name} im Zeitraum '
              '${widget.instrument.timeframe.label} mit '
              '${visibleIds.length} sichtbaren Szenarien. '
              'Zoom ${_viewport.zoom.toStringAsFixed(1)}-fach.',
          child: SizedBox(
            height: 350,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: () => _setViewport(const ChartViewport()),
                child: RawGestureDetector(
                  key: const ValueKey('chart-gestures'),
                  behavior: HitTestBehavior.opaque,
                  gestures: {
                    _ChartScaleGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                            _ChartScaleGestureRecognizer>(
                      () => _ChartScaleGestureRecognizer(),
                      (recognizer) {
                        recognizer
                          ..onStart = (details) {
                            _gestureStart = _viewport;
                            _focalStart = _focalFraction(
                              details.localFocalPoint,
                              constraints.maxWidth,
                            );
                            if (details.pointerCount == 1) {
                              _inspect(details.localFocalPoint,
                                  constraints.maxWidth);
                            }
                          }
                          ..onUpdate = (details) {
                            if (details.pointerCount < 2) {
                              _inspect(details.localFocalPoint,
                                  constraints.maxWidth);
                              return;
                            }
                            _setViewport(
                              _viewport.transform(
                                initial: _gestureStart,
                                scale: details.scale,
                                initialFocal: _focalStart,
                                currentFocal: _focalFraction(
                                  details.localFocalPoint,
                                  constraints.maxWidth,
                                ),
                              ),
                            );
                          };
                      },
                    ),
                  },
                  child: SizedBox.expand(
                      child: CustomPaint(
                    key: const ValueKey('scenario-chart-paint'),
                    painter: _ChartPainter(
                      instrument: widget.instrument,
                      analysis: widget.analysis,
                      visibleScenarioIds: visibleIds,
                      historyPoints: widget.historyPoints,
                      showZones: widget.showZones,
                      viewport: _viewport,
                      selectedIndex: _selectedIndex,
                    ),
                  )),
                ),
              ),
            ),
          ),
        ),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Ein Finger: Kurs · Zwei Finger: Zoom und Verschieben',
                style: TextStyle(color: AppPalette.muted, fontSize: 10),
              ),
            ),
            TextButton(
              key: const ValueKey('chart-reset-zoom'),
              onPressed: () => _setViewport(const ChartViewport()),
              child:
                  Text('Zurücksetzen (${_viewport.zoom.toStringAsFixed(1)}×)'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Ein Finger vertikal scrollt weiterhin die Analyseseite.
/// Horizontales Ablesen und Gesten mit zwei Fingern gehören dem Chart.
class _ChartScaleGestureRecognizer extends ScaleGestureRecognizer {
  final Map<int, Offset> _starts = {};
  bool _multiTouch = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _starts[event.pointer] = event.position;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerDownEvent && _starts.length >= 2) {
      _multiTouch = true;
    }
    if (event is PointerMoveEvent && !_multiTouch && _starts.length == 1) {
      final start = _starts[event.pointer];
      if (start != null) {
        final delta = event.position - start;
        if (delta.dy.abs() > kTouchSlop && delta.dy.abs() > delta.dx.abs()) {
          resolve(GestureDisposition.rejected);
          return;
        }
      }
    }
    super.handleEvent(event);
    if (event is PointerDownEvent && _multiTouch) {
      resolve(GestureDisposition.accepted);
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _starts.remove(event.pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _starts.clear();
    _multiTouch = false;
    super.didStopTrackingLastPointer(pointer);
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.instrument,
    required this.analysis,
    required this.visibleScenarioIds,
    required this.historyPoints,
    required this.showZones,
    required this.viewport,
    this.selectedIndex,
  });

  final Instrument instrument;
  final AnalysisResult analysis;
  final Set<String> visibleScenarioIds;
  final int historyPoints;
  final bool showZones;
  final ChartViewport viewport;
  final int? selectedIndex;

  double _x(double original, double left, double right) =>
      left +
      ((original - left) / (right - left) - viewport.start) /
          viewport.span *
          (right - left);

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
    final plotRight = size.width - right;
    final originalHistoryEnd = left + plotWidth * 0.64;
    double xFor(double fraction) =>
        left + (fraction - viewport.start) / viewport.span * plotWidth;
    final historyEndX = xFor(0.64);
    final projectionEndX = xFor(1);

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
        top +
        plotHeight -
        ((value - minValue) / (maxValue - minValue)) * plotHeight;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(left, top, plotWidth, plotHeight));
    if (showZones) {
      for (final scenario in visibleScenarios) {
        final primary = scenario.id == analysis.primaryScenarioId;
        final color = scenarioColor(scenario.kind);
        _drawZone(
          canvas,
          historyEndX,
          projectionEndX,
          yFor(scenario.entryLowEuro),
          yFor(scenario.entryHighEuro),
          AppPalette.blue.withAlpha(primary ? 34 : 16),
        );
        _drawZone(
          canvas,
          historyEndX,
          projectionEndX,
          yFor(scenario.exitLowEuro),
          yFor(scenario.exitHighEuro),
          color.withAlpha(primary ? 30 : 14),
        );
        _drawDashedLine(
          canvas,
          Offset(historyEndX, yFor(scenario.stopLossEuro)),
          Offset(projectionEndX, yFor(scenario.stopLossEuro)),
          Paint()
            ..color = AppPalette.red.withAlpha(primary ? 180 : 95)
            ..strokeWidth = primary ? 1.4 : 1,
        );
      }
    }

    canvas.restore();

    final gridPaint = Paint()
      ..color = AppPalette.line
      ..strokeWidth = 1;
    for (var index = 0; index <= 4; index++) {
      final y = top + (plotHeight / 4) * index;
      canvas.drawLine(
          Offset(left, y), Offset(size.width - right, y), gridPaint);
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
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(left, top, plotWidth, plotHeight));
    canvas.drawLine(
      Offset(historyEndX, top),
      Offset(historyEndX, top + plotHeight),
      Paint()
        ..color = AppPalette.line
        ..strokeWidth = 1,
    );

    canvas.restore();
    if (viewport.start < 0.64) {
      _paintText(
        canvas,
        'VERLAUF',
        const Offset(left, 12),
        color: AppPalette.muted,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      );
    }
    if (viewport.end > 0.64) {
      _paintText(
        canvas,
        'PROJEKTION',
        Offset(math.max(left, historyEndX + 9), 12),
        color: AppPalette.muted,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      );
    }
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(left, top, plotWidth, plotHeight));
    if (history.length > 1) {
      final historyPath = Path();
      for (var index = 0; index < history.length; index++) {
        final x = xFor(0.64 * index / math.max(1, history.length - 1));
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
    }

    for (var scenarioIndex = 0;
        scenarioIndex < visibleScenarios.length;
        scenarioIndex++) {
      final scenario = visibleScenarios[scenarioIndex];
      final color = scenarioColor(scenario.kind);
      final path = Path()..moveTo(historyEndX, yFor(instrument.euroPrice));
      for (var index = 0; index < scenario.projectionEuro.length; index++) {
        final x = historyEndX +
            (projectionEndX - historyEndX) *
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
        Offset(projectionEndX, yFor(scenario.targetEuro)),
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
        projectionEndX,
        yFor,
        scenarioIndex,
      );
      _drawHistoricalWaveMarkers(
        canvas,
        scenario,
        startIndex,
        history.length,
        left,
        originalHistoryEnd,
        plotRight,
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

    if (selectedIndex != null && history.length > 1) {
      final localIndex = selectedIndex! - startIndex;
      if (localIndex >= 0 && localIndex < history.length) {
        final x = xFor(0.64 * localIndex / (history.length - 1));
        final y = yFor(history[localIndex].euro);
        final markerPaint = Paint()
          ..color = AppPalette.ink
          ..strokeWidth = 1;
        canvas.drawLine(
            Offset(x, top), Offset(x, top + plotHeight), markerPaint);
        canvas.drawLine(Offset(left, y), Offset(plotRight, y), markerPaint);
        canvas.drawCircle(Offset(x, y), 5, Paint()..color = AppPalette.blue);
      }
    }
    canvas.restore();
    _drawXAxis(canvas, history, left, originalHistoryEnd, plotRight,
        top + plotHeight + 9);

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
    double plotRight,
    double y,
  ) {
    if (points.length < 2 || viewport.start >= 0.64) return;
    final first = (viewport.start / 0.64 * (points.length - 1))
        .ceil()
        .clamp(0, points.length - 1)
        .toInt();
    final last = (math.min(viewport.end, 0.64) / 0.64 * (points.length - 1))
        .floor()
        .clamp(0, points.length - 1)
        .toInt();
    if (last < first) return;
    final indexes = <int>{first, (first + last) ~/ 2, last}.toList()..sort();
    for (var position = 0; position < indexes.length; position++) {
      final index = indexes[position];
      final x = _x(
          left + (right - left) * (index / math.max(1, points.length - 1)),
          left,
          plotRight);
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
      final projectionIndex =
          ((index + 1) * scenario.projectionEuro.length / (labels.length + 1))
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
    double plotRight,
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
      final x = _x(
          fromX + (toX - fromX) * (localIndex / (visibleHistoryLength - 1)),
          fromX,
          plotRight);
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
      Rect.fromLTRB(
          left, math.min(firstY, secondY), right, math.max(firstY, secondY)),
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
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.viewport.start != viewport.start ||
        oldDelegate.viewport.end != viewport.end ||
        oldDelegate.instrument.id != instrument.id ||
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
