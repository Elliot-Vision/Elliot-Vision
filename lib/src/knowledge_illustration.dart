import 'package:flutter/material.dart';
import 'app.dart';

/// Vector teaching figures stay sharp offline and scale with the device width.
class KnowledgeIllustration extends StatelessWidget {
  const KnowledgeIllustration({required this.topic, super.key});
  final String topic;
  String get caption => switch (topic) {
        'pa-ohlc' ||
        'pa-body-wicks' ||
        'pa-basics' =>
          'Grün: von O 100 bis S 103. Hoch 105, Tief 98. Rot zeigt einen Schluss unter der Eröffnung.',
        'pa-doji' =>
          'Doji: kleiner Körper. Die Dochte können trotzdem eine große Spanne abbilden.',
        'pa-wick' =>
          'Links langer unterer, rechts langer oberer Docht. Der vorherige Trend ist zusätzlich zu prüfen.',
        'pa-engulfing' =>
          'Bullisches Engulfing: Der grüne Körper umfasst den vorherigen roten Körper.',
        'pa-interval' =>
          'Mehrere Intervalle nebeneinander. Die letzte, nur umrandete Kerze ist noch nicht abgeschlossen.',
        'pa-projection' =>
          'Durchgezogen: beobachteter Verlauf. Gestrichelt: Modellprojektion mit interpoliertem Ablesepunkt.',
        'pa-structure' =>
          'HH = höheres Hoch, HT = höheres Tief. Die Folge beschreibt eine Aufwärtsstruktur.',
        'pa-breakout' =>
          'Ausbruch über eine Zone, Rücktest von oben, mögliche Fortsetzung. Ein Lehrbeispiel, keine Vorhersage.',
        'pa-context' =>
          'Einzelne Kerzen werden innerhalb der größeren Struktur und ihrer benachbarten Zonen betrachtet.',
        _ =>
          'Blau: Unterstützungsbereich. Rot: Widerstandsbereich. Zonen können durchbrochen werden.',
      };
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(
            image: true,
            label: 'Schematisches Lehrbild. $caption',
            child: ExcludeSemantics(
                child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: CustomPaint(painter: _KnowledgePainter(topic)))),
          ),
          const Text('SCHEMATISCHES LEHRBILD · KEINE MARKTDATEN',
              style: TextStyle(color: AppPalette.muted, fontSize: 10)),
          const SizedBox(height: 6),
          Text(caption, style: const TextStyle(height: 1.4)),
        ]),
      );
}

class _KnowledgePainter extends CustomPainter {
  _KnowledgePainter(this.topic);
  final String topic;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    void text(String value, double x, double y,
        [Color color = AppPalette.ink]) {
      final p = TextPainter(
          text: TextSpan(
              text: value,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600)),
          textDirection: TextDirection.ltr)
        ..layout(maxWidth: w * 0.48);
      p.paint(canvas, Offset(x.clamp(0.0, w - p.width), y));
    }

    void line(Offset a, Offset b, Color color, [double width = 2]) =>
        canvas.drawLine(
            a,
            b,
            Paint()
              ..color = color
              ..strokeWidth = width);
    void candle(
        double fraction, double open, double high, double low, double close,
        {bool hollow = false, double width = 25}) {
      final x = w * fraction;
      final color = close < open ? AppPalette.limeDark : AppPalette.red;
      line(Offset(x, high), Offset(x, low), color);
      canvas.drawRect(
          Rect.fromLTRB(x - width / 2, open < close ? open : close,
              x + width / 2, (open > close ? open : close) + 1),
          Paint()
            ..color = color
            ..style = hollow ? PaintingStyle.stroke : PaintingStyle.fill
            ..strokeWidth = 2);
    }

    canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
        Paint()..color = AppPalette.surface);
    for (final y in [45.0, 95.0, 145.0, 195.0]) {
      line(Offset(12, y), Offset(w - 12, y), AppPalette.line, 1);
    }
    if (['pa-ohlc', 'pa-body-wicks', 'pa-basics'].contains(topic)) {
      candle(0.30, 135, 35, 175, 75, width: 30);
      candle(0.78, 75, 40, 170, 125, width: 30);
      text('H 105', 5, 24);
      text('S 103', 5, 66);
      text('O 100', 5, 130);
      text('T 98', 5, 177);
      line(Offset(w * .3 - 15, 75), Offset(55, 75), AppPalette.muted, 1);
      line(Offset(w * .3 - 15, 135), Offset(55, 135), AppPalette.muted, 1);
      text('steigend', w * .13, 198, AppPalette.limeDark);
      text('fallend', w * .65, 198, AppPalette.red);
    } else if (topic == 'pa-doji') {
      candle(.25, 105, 40, 170, 103);
      candle(.70, 100, 32, 180, 106);
      text('kleiner Körper', w * .15, 192);
    } else if (topic == 'pa-wick') {
      candle(.25, 70, 40, 175, 55);
      candle(.73, 145, 30, 175, 162);
      text('Erholung vom Tief', 8, 192);
      text('Rückgang vom Hoch', w * .52, 192);
    } else if (topic == 'pa-engulfing') {
      candle(.28, 90, 70, 145, 130);
      candle(.65, 155, 35, 180, 55, width: 34);
      text('1: O 104 / S 101', 8, 192);
      text('2: O 100 / S 105', w * .51, 192);
    } else if (topic == 'pa-interval') {
      for (var i = 0; i < 4; i++) {
        candle(.18 + i * .21, 140 - i * 14.0, 55 - i * 7.0, 175 - i * 10.0,
            100 - i * 12.0,
            hollow: i == 3, width: 22);
        text(i == 3 ? 'läuft' : '${i * 5}–${(i + 1) * 5}m', w * (.10 + i * .21),
            192);
      }
    } else {
      final projection = topic == 'pa-projection';
      final structure = topic == 'pa-structure';
      final breakout = topic == 'pa-breakout';
      canvas.drawRect(Rect.fromLTWH(10, breakout ? 110 : 155, w - 20, 18),
          Paint()..color = AppPalette.blue.withAlpha(55));
      if (!projection && !structure && !breakout) {
        canvas.drawRect(Rect.fromLTWH(10, 45, w - 20, 18),
            Paint()..color = AppPalette.red.withAlpha(55));
        text('Widerstand', 12, 25);
        text('Unterstützung', 12, 175);
      }
      final ys = breakout
          ? <double>[155, 120, 145, 112, 72, 115, 55]
          : structure
              ? <double>[175, 125, 150, 85, 110, 45, 70]
              : <double>[145, 70, 150, 75, 140, 62, 100];
      for (var i = 0; i < ys.length - 1; i++) {
        final a = Offset(18 + (w - 36) * i / (ys.length - 1), ys[i]);
        final b = Offset(18 + (w - 36) * (i + 1) / (ys.length - 1), ys[i + 1]);
        if (projection && i >= 3) {
          for (var j = 0; j < 10; j += 2) {
            line(Offset.lerp(a, b, j / 10)!, Offset.lerp(a, b, (j + 1) / 10)!,
                AppPalette.blue, 3);
          }
        } else {
          line(a, b, AppPalette.limeDark, 3);
        }
      }
      if (structure) {
        text('HH', w * .16, 103);
        text('HT', w * .30, 153);
        text('HH', w * .47, 62);
        text('HT', w * .62, 113);
        text('HH', w * .76, 23);
      }
      if (breakout) {
        text('Ausbruch', w * .43, 50);
        text('Rücktest', w * .65, 133);
      }
      if (projection) {
        final x = 18 + (w - 36) * .75;
        line(Offset(x, 25), Offset(x, 185), AppPalette.muted, 1);
        canvas.drawCircle(Offset(x, (ys[4] + ys[5]) / 2), 5,
            Paint()..color = AppPalette.blue);
        text('Verlauf', 12, 195);
        text('Modellwert ≈', w * .57, 195);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KnowledgePainter old) => old.topic != topic;
}
