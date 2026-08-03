import 'dart:math';
import 'package:flutter/material.dart';
import '../models/security.dart';
import '../models/wave_analysis.dart';

class PriceChart extends StatelessWidget {
  const PriceChart({super.key, required this.snapshot, required this.analysis, required this.visibleCountIds, this.showFibonacci = true});
  final SecuritySnapshot snapshot;
  final WaveAnalysis analysis;
  final Set<String> visibleCountIds;
  final bool showFibonacci;
  @override Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.35,
    child: CustomPaint(painter: _ChartPainter(snapshot, analysis, visibleCountIds, showFibonacci), child: const SizedBox.expand()),
  );
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.snapshot, this.analysis, this.visibleCountIds, this.showFibonacci);
  final SecuritySnapshot snapshot;
  final WaveAnalysis analysis;
  final Set<String> visibleCountIds;
  final bool showFibonacci;

  @override void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTWH(10, 12, size.width - 20, size.height - 36);
    final prices = snapshot.history.map((e) => e.priceEur).toList();
    final minP = min(prices.reduce(min), analysis.bearishTargetEur) * .96;
    final maxP = max(prices.reduce(max), analysis.bullishTargetEur) * 1.04;
    Offset map(int i, double v) => Offset(chart.left + chart.width * i / (prices.length - 1), chart.bottom - chart.height * (v - minP) / (maxP - minP));

    final grid = Paint()..color = const Color(0xFFE9E9E5)..strokeWidth = 1;
    for (var i=0;i<5;i++) { final y=chart.top+chart.height*i/4; canvas.drawLine(Offset(chart.left,y),Offset(chart.right,y),grid); }
    if (showFibonacci) {
      for (final f in const [0.382,0.5,0.618]) {
        final value = snapshot.allTimeLowEur + (snapshot.allTimeHighEur-snapshot.allTimeLowEur)*f;
        final y = map(0,value).dy;
        canvas.drawLine(Offset(chart.left,y),Offset(chart.right,y),Paint()..color=const Color(0xFFB9B9B3)..strokeWidth=1);
      }
    }
    final path=Path()..moveTo(map(0,prices.first).dx,map(0,prices.first).dy);
    for(var i=1;i<prices.length;i++){final p=map(i,prices[i]);path.lineTo(p.dx,p.dy);} 
    canvas.drawPath(path,Paint()..color=const Color(0xFF111111)..strokeWidth=2.4..style=PaintingStyle.stroke);

    final palettes=[const Color(0xFF111111),const Color(0xFF76766F),const Color(0xFFA5A59E)];
    for(var c=0;c<analysis.counts.length;c++){
      final count=analysis.counts[c]; if(!visibleCountIds.contains(count.id)) continue;
      for(final label in count.labels){ if(label.index>=prices.length) continue; final p=map(label.index,prices[label.index]);
        canvas.drawCircle(p, count.isPrimary?4:3, Paint()..color=palettes[c]);
        final tp=TextPainter(text:TextSpan(text:label.label,style:TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:palettes[c])),textDirection:TextDirection.ltr)..layout();
        tp.paint(canvas,p.translate(-tp.width/2,-20-(c*10)));
      }
    }
    final current=map(prices.length-1,prices.last); canvas.drawCircle(current,5,Paint()..color=const Color(0xFF111111));
  }
  @override bool shouldRepaint(covariant _ChartPainter old) => true;
}
