import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app.dart';
import 'models.dart';

class CandleChartPainter extends CustomPainter {
  CandleChartPainter(
      {required this.candles,
      required this.start,
      required this.end,
      required this.selected});
  final List<PriceCandle> candles;
  final double start, end;
  final double? selected;
  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;
    const inset = 14.0;
    final width = size.width - inset * 2;
    final height = size.height - 50;
    final first =
        (start * (candles.length - 1)).floor().clamp(0, candles.length - 1);
    final last =
        (end * (candles.length - 1)).ceil().clamp(first, candles.length - 1);
    final visible = candles.sublist(first, last + 1);
    final minPrice = visible.map((c) => c.low).reduce(math.min);
    final maxPrice = visible.map((c) => c.high).reduce(math.max);
    final range = math.max(maxPrice - minPrice, maxPrice.abs() * 0.001);
    double y(double price) =>
        14 + height * (1 - (price - minPrice + range * 0.05) / (range * 1.1));
    double x(int index) =>
        inset +
        ((index / math.max(1, candles.length - 1) - start) / (end - start)) *
            width;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(inset, 10, width, height + 10));
    final bodyWidth =
        (width / (math.max(1, candles.length - 1) * (end - start)) * 0.65)
            .clamp(1.0, 20.0);
    for (var i = first; i <= last; i++) {
      final c = candles[i];
      final paint = Paint()
        ..color = c.close >= c.open ? AppPalette.limeDark : AppPalette.red
        ..strokeWidth = 1.3;
      canvas.drawLine(Offset(x(i), y(c.high)), Offset(x(i), y(c.low)), paint);
      final top = math.min(y(c.open), y(c.close));
      final bottom = math.max(y(c.open), y(c.close));
      canvas.drawRect(
          Rect.fromLTWH(
              x(i) - bodyWidth / 2, top, bodyWidth, math.max(1, bottom - top)),
          paint);
    }
    if (selected != null) {
      canvas.drawLine(
          Offset(x(selected!.round()), 10),
          Offset(x(selected!.round()), height + 20),
          Paint()
            ..color = AppPalette.ink
            ..strokeWidth = 1);
    }
    canvas.restore();
    for (final index in {first, last}) {
      final date = candles[index].timestamp.toLocal();
      final text = TextPainter(
          text: TextSpan(
              text: '${date.day}.${date.month}.${date.year}',
              style: const TextStyle(color: AppPalette.muted, fontSize: 10)),
          textDirection: TextDirection.ltr)
        ..layout();
      text.paint(
          canvas,
          Offset(index == first ? inset : size.width - inset - text.width,
              size.height - 20));
    }
  }

  @override
  bool shouldRepaint(covariant CandleChartPainter old) =>
      old.candles != candles ||
      old.start != start ||
      old.end != end ||
      old.selected != selected;
}
