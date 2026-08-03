import 'package:flutter/material.dart';

class KnowledgeScreen extends StatelessWidget {
  const KnowledgeScreen({super.key});

  static const entries = [
    ('Elliott-Wellen', 'Ein Modell, das Kursbewegungen als Impulswellen 1–5 und Korrekturwellen A–B–C beschreibt.'),
    ('Fibonacci-Retracement', 'Prozentuale Rücklaufmarken wie 38,2 %, 50 % und 61,8 %, die mögliche Unterstützungen oder Widerstände markieren.'),
    ('Allzeithoch (ATH)', 'Der höchste historisch erreichte Kurs eines Wertpapiers.'),
    ('Allzeittief (ATL)', 'Der niedrigste historisch erreichte Kurs eines Wertpapiers.'),
    ('Bullisch', 'Eine Markteinschätzung, die überwiegend steigende Kurse erwartet.'),
    ('Bärisch', 'Eine Markteinschätzung, die überwiegend fallende Kurse erwartet.'),
    ('Invalidierungsmarke', 'Ein Kursniveau, bei dessen Bruch eine Wellenzählung nicht mehr gültig ist.'),
    ('Analyse-Score', 'Bewertet, wie klar und widerspruchsfrei die aktuelle Analyse ist – nicht, ob die Aktie gut oder schlecht ist.'),
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
    children: [
      Text('Wissen', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Fachbegriffe verständlich erklärt.'),
      const SizedBox(height: 20),
      ...entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(e.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
          children: [Align(alignment: Alignment.centerLeft, child: Text(e.$2))],
        ),
      )),
    ],
  );
}
