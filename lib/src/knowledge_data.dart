class KnowledgeEntry {
  const KnowledgeEntry({
    required this.id,
    required this.category,
    required this.title,
    required this.text,
    this.keywords = const <String>[],
  });

  final String id;
  final String category;
  final String title;
  final String text;
  final List<String> keywords;

  bool matches(String query) {
    final needle = _normalizeKnowledgeText(query);
    if (needle.isEmpty) {
      return true;
    }
    final haystack = _normalizeKnowledgeText(
      '$category $title $text ${keywords.join(' ')}',
    );
    return haystack.contains(needle);
  }
}

List<KnowledgeEntry> filterKnowledgeEntries(String query) {
  return knowledgeEntries.where((entry) => entry.matches(query)).toList();
}

String _normalizeKnowledgeText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('ä', 'a')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ß', 'ss');
}

const knowledgeEntries = <KnowledgeEntry>[
  KnowledgeEntry(
    id: 'elliott-prinzip',
    category: 'Grundlagen',
    title: 'Elliott-Wellen-Prinzip',
    text:
        'Das Modell beschreibt wiederkehrende Marktstrukturen aus Trend- und Korrekturbewegungen. Eine Zählung ist eine regelgebundene Interpretation des Kursverlaufs, keine sichere Vorhersage.',
    keywords: ['Ralph Nelson Elliott', 'Marktzyklus', 'Zählung'],
  ),
  KnowledgeEntry(
    id: 'impuls',
    category: 'Grundlagen',
    title: 'Impulswellen 1–5',
    text:
        'Ein Trendimpuls besteht typischerweise aus fünf Wellen. Die Wellen 1, 3 und 5 laufen mit dem Trend; die Wellen 2 und 4 korrigieren ihn.',
    keywords: ['Motive Wave', 'Trendwelle', 'fünf Wellen'],
  ),
  KnowledgeEntry(
    id: 'impuls-regeln',
    category: 'Regeln',
    title: 'Drei Impulsregeln',
    text:
        'Welle 2 darf den Beginn von Welle 1 nicht überschreiten. Welle 3 darf nie die kürzeste der Wellen 1, 3 und 5 sein. Welle 4 überlappt bei einem normalen Impuls den Preisbereich von Welle 1 nicht.',
    keywords: ['Welle 2', 'Welle 3', 'Welle 4', 'Überlappung'],
  ),
  KnowledgeEntry(
    id: 'abc-korrektur',
    category: 'Korrekturen',
    title: 'Korrektur A–B–C',
    text:
        'Nach einem Impuls folgt häufig eine dreiteilige Gegenbewegung. Die Buchstaben A, B und C bezeichnen deren Teilwellen; die genaue innere Struktur hängt vom Korrekturmuster ab.',
    keywords: ['ABC', 'Gegenbewegung', 'Corrective Wave'],
  ),
  KnowledgeEntry(
    id: 'zigzag',
    category: 'Korrekturen',
    title: 'Zigzag',
    text:
        'Ein Zigzag ist meist eine scharfe Korrektur mit der Unterteilung 5–3–5. Welle B korrigiert Welle A häufig nur teilweise, bevor Welle C die Bewegung fortsetzt.',
    keywords: ['5-3-5', 'Zickzack', 'scharfe Korrektur'],
  ),
  KnowledgeEntry(
    id: 'flat',
    category: 'Korrekturen',
    title: 'Flat und Expanded Flat',
    text:
        'Ein Flat verläuft eher seitwärts und unterteilt sich typischerweise 3–3–5. Beim Expanded Flat überschreitet Welle B den Start von A; Welle C endet häufig über das Ende von A hinaus.',
    keywords: ['3-3-5', 'Running Flat', 'Seitwärtskorrektur'],
  ),
  KnowledgeEntry(
    id: 'triangle',
    category: 'Korrekturen',
    title: 'Triangle',
    text:
        'Ein Triangle besteht aus fünf überlappenden Teilwellen A–B–C–D–E. Es tritt häufig vor der letzten Bewegung einer größeren Formation auf und bindet Zeit statt starkem Preisweg.',
    keywords: ['Dreieck', 'A-B-C-D-E', 'Contracting', 'Expanding'],
  ),
  KnowledgeEntry(
    id: 'kombination',
    category: 'Korrekturen',
    title: 'Kombination W–X–Y',
    text:
        'Komplexe Korrekturen verbinden zwei Korrekturmuster durch eine Zwischenwelle X. Die Bezeichnungen W und Y stehen für die verbundenen Muster.',
    keywords: ['Double Three', 'WXY', 'komplexe Korrektur'],
  ),
  KnowledgeEntry(
    id: 'leading-diagonal',
    category: 'Sonderformen',
    title: 'Leading Diagonal',
    text:
        'Eine Leading Diagonal kann am Beginn einer Welle 1 oder A auftreten. Die Trendlinien laufen oft keilförmig; eine Überlappung von Welle 1 und 4 ist hier im Gegensatz zum normalen Impuls zulässig.',
    keywords: ['Anfangsdiagonale', 'Keil', 'Welle 1', 'Welle A'],
  ),
  KnowledgeEntry(
    id: 'ending-diagonal',
    category: 'Sonderformen',
    title: 'Ending Diagonal',
    text:
        'Eine Ending Diagonal erscheint häufig in Welle 5 oder C und kann auf nachlassende Trendkraft hindeuten. Nach ihrem Abschluss folgt oft eine deutliche Gegenbewegung.',
    keywords: ['Enddiagonale', 'Keil', 'Welle 5', 'Welle C'],
  ),
  KnowledgeEntry(
    id: 'wellengrad',
    category: 'Struktur',
    title: 'Wellengrad und Unterwellen',
    text:
        'Elliott-Strukturen sind fraktal: Eine Welle eines großen Zeitrahmens besteht selbst aus kleineren Wellen. Der Wellengrad bezeichnet die betrachtete Größen- beziehungsweise Zeitebene.',
    keywords: ['Degree', 'Subwaves', 'fraktal', 'Zeitebene'],
  ),
  KnowledgeEntry(
    id: 'alternation',
    category: 'Leitlinien',
    title: 'Alternation',
    text:
        'Die Leitlinie der Alternation besagt: Ist Welle 2 scharf und kurz, verläuft Welle 4 häufig eher seitwärts und komplex – oder umgekehrt. Es handelt sich um eine Tendenz, nicht um eine harte Regel.',
    keywords: ['Abwechslung', 'Welle 2', 'Welle 4'],
  ),
  KnowledgeEntry(
    id: 'fibonacci-retracement',
    category: 'Fibonacci',
    title: 'Fibonacci-Retracement',
    text:
        'Retracements messen, wie weit eine vorherige Bewegung korrigiert wurde. Häufig beobachtete Bereiche sind 38,2 %, 50 % und 61,8 %; sie sind Zonen und keine garantierten Wendepunkte.',
    keywords: ['38,2', '50', '61,8', 'Rücklauf'],
  ),
  KnowledgeEntry(
    id: 'fibonacci-extension',
    category: 'Fibonacci',
    title: 'Fibonacci-Extension',
    text:
        'Extensions projizieren mögliche Ziele einer laufenden Welle. Häufig verwendet werden 100 %, 161,8 % und 261,8 %, etwa zur Einordnung von Welle 3 oder C.',
    keywords: ['100', '161,8', '261,8', 'Kursziel', 'Projektion'],
  ),
  KnowledgeEntry(
    id: 'overlap',
    category: 'Regeln',
    title: 'Überlappung',
    text:
        'Überlappung bedeutet, dass sich Preisbereiche zweier Wellen schneiden. Bei einem normalen Impuls darf Welle 4 nicht in den Preisbereich von Welle 1 laufen; bei Diagonalen gilt diese Ausnahme nicht.',
    keywords: ['Overlap', 'Welle 1', 'Welle 4'],
  ),
  KnowledgeEntry(
    id: 'truncation',
    category: 'Sonderformen',
    title: 'Versagen / Truncation',
    text:
        'Bei einer Truncation erreicht Welle 5 nicht das Ende von Welle 3. Das kann auf starke Gegenkräfte hindeuten, sollte aber erst nach klar erkennbarer fünfteiliger Unterstruktur angenommen werden.',
    keywords: ['Failure', 'verkürzte fünfte Welle', 'Welle 5'],
  ),
  KnowledgeEntry(
    id: 'invalidation',
    category: 'Analyse',
    title: 'Invalidierung',
    text:
        'Die Invalidierungsmarke zeigt, ab welchem Kurs eine Zählung gegen eine Elliott-Regel verstößt. Wird sie erreicht, muss dieses Szenario verworfen oder neu gezählt werden.',
    keywords: ['ungültig', 'Marke', 'Szenario verwerfen'],
  ),
  KnowledgeEntry(
    id: 'szenarien',
    category: 'Analyse',
    title: 'Haupt- und Alternativszenario',
    text:
        'Mehrere Zählungen können gleichzeitig regelkonform sein. Das Hauptszenario ist die aktuell bevorzugte Variante; Alternativen zeigen, wie sich die Bewertung bei anderen Wendepunkten verändert.',
    keywords: ['Primary Count', 'Alternate Count', 'Zählmethoden'],
  ),
  KnowledgeEntry(
    id: 'score',
    category: 'Analyse',
    title: 'Score und Wahrscheinlichkeit',
    text:
        'Scores vergleichen die Regelkonformität und Plausibilität von Szenarien. Sie sind modellabhängige Orientierungshilfen und keine objektive Eintrittswahrscheinlichkeit oder Anlageempfehlung.',
    keywords: ['Bewertung', 'Plausibilität', 'Prozent'],
  ),
  KnowledgeEntry(
    id: 'pivot',
    category: 'Marktstruktur',
    title: 'Pivot, Swing High und Swing Low',
    text:
        'Pivots sind markante lokale Hoch- und Tiefpunkte. Sie helfen, mögliche Wellenenden zu bestimmen; zu empfindliche Einstellungen erzeugen zu viele, zu grobe Einstellungen zu wenige Wendepunkte.',
    keywords: ['Wendepunkt', 'Hoch', 'Tief', 'Pivot-Erkennung'],
  ),
  KnowledgeEntry(
    id: 'support-resistance',
    category: 'Marktstruktur',
    title: 'Unterstützung und Widerstand',
    text:
        'Unterstützungen und Widerstände sind Kurszonen, an denen Angebot oder Nachfrage wiederholt reagieren. Zusammen mit Wellenstruktur und Fibonacci können sie Ziel- oder Invalidierungszonen bestätigen.',
    keywords: ['Support', 'Resistance', 'Kurszone'],
  ),
  KnowledgeEntry(
    id: 'volume-divergence',
    category: 'Bestätigung',
    title: 'Volumen und Divergenz',
    text:
        'Volumen und Momentum können eine Zählung stützen. Ein neues Kurshoch bei schwächerem Momentum ist eine Divergenz und kann auf nachlassende Trendkraft hindeuten, bestätigt allein aber keine Wende.',
    keywords: ['Momentum', 'RSI', 'MACD', 'Trendkraft'],
  ),
  KnowledgeEntry(
    id: 'ath-atl',
    category: 'Kursdaten',
    title: 'Allzeithoch und Allzeittief',
    text:
        'ATH und ATL bezeichnen den höchsten beziehungsweise niedrigsten verfügbaren Kurs einer Datenreihe. Ihr Wert hängt von Datenquelle, Börsenplatz, Währung und berücksichtigtem Zeitraum ab.',
    keywords: ['ATH', 'ATL', 'All Time High', 'All Time Low'],
  ),
  KnowledgeEntry(
    id: 'risk-reward',
    category: 'Risiko',
    title: 'Chance-Risiko-Verhältnis',
    text:
        'Das Verhältnis vergleicht den möglichen Gewinn bis zum Ziel mit dem möglichen Verlust bis zur Risikogrenze. Auch ein gutes Verhältnis ersetzt keine Positionsgrößen- und Verlustbegrenzung.',
    keywords: ['CRV', 'Risk Reward', 'Stop-Loss', 'Positionsgröße'],
  ),
  KnowledgeEntry(
    id: 'entry-zone',
    category: 'Trading-Plan',
    title: 'Einstiegszone',
    text:
        'Eine Einstiegszone ist ein Kursbereich statt eines einzelnen Preises. Sie wird aus Struktur, Rückläufen und Invalidierung abgeleitet und ersetzt keine eigene Order- oder Risikoprüfung.',
    keywords: ['Entry', 'Kaufbereich', 'Limit'],
  ),
  KnowledgeEntry(
    id: 'exit-zone',
    category: 'Trading-Plan',
    title: 'Ausstiegs- und Zielzone',
    text:
        'Eine Zielzone bündelt mögliche Wellenenden und Fibonacci-Projektionen. Teilverkäufe können das Risiko reduzieren; das Erreichen der Zone ist nicht garantiert.',
    keywords: ['Exit', 'Take Profit', 'Kursziel', 'Teilverkäufe'],
  ),
  KnowledgeEntry(
    id: 'stop-loss',
    category: 'Risiko',
    title: 'Stop-Loss und Risikogrenze',
    text:
        'Ein Stop-Loss begrenzt den geplanten Verlust. Die technische Invalidierung kann als Orientierung dienen, muss aber um Volatilität, Positionsgröße, Gaps und persönliche Risikotoleranz ergänzt werden.',
    keywords: ['Stop', 'Verlustbegrenzung', 'Gap', 'Risikogrenze'],
  ),
  KnowledgeEntry(
    id: 'position-sizing',
    category: 'Risiko',
    title: 'Positionsgröße',
    text:
        'Die Positionsgröße bestimmt, wie stark ein Stop-Loss das Gesamtkapital belastet. Sie sollte aus maximal akzeptiertem Verlust und Abstand zur Risikogrenze berechnet werden.',
    keywords: ['Kapital', 'Risiko pro Trade', 'Stückzahl'],
  ),
  KnowledgeEntry(
    id: 'liquidity-slippage',
    category: 'Handel',
    title: 'Liquidität, Spread und Slippage',
    text:
        'Geringe Liquidität kann zu großen Spreads und Ausführungen außerhalb des erwarteten Kurses führen. Das ist besonders bei kleinen Aktien und in volatilen Kryptomärkten relevant.',
    keywords: ['Bid Ask', 'Spread', 'Slippage', 'Liquidität'],
  ),
  KnowledgeEntry(
    id: 'asset-types',
    category: 'Kursdaten',
    title: 'Aktie, ETF und Kryptowährung',
    text:
        'Aktien und ETFs handeln zu Börsenzeiten und können Kapitalmaßnahmen haben. Kryptowährungen handeln rund um die Uhr und zeigen oft höhere Volatilität; deshalb bewertet die App den Asset-Typ sichtbar.',
    keywords: ['Krypto', 'ETF', 'Aktie', '24/7', 'Handelszeiten'],
  ),
  KnowledgeEntry(
    id: 'isin-ticker-venue',
    category: 'Kursdaten',
    title: 'ISIN, Ticker und Handelsplatz',
    text:
        'Die ISIN identifiziert ein Wertpapier, während Ticker je Handelsplatz variieren können. Kurs, Währung, Handelszeit und Datenqualität hängen deshalb auch vom gewählten Börsenplatz ab.',
    keywords: ['Symbol', 'Börse', 'Venue', 'WKN'],
  ),
  KnowledgeEntry(
    id: 'data-delay',
    category: 'Kursdaten',
    title: 'Echtzeit, verzögert und Kurszeitpunkt',
    text:
        'Ein aktueller Abruf ist nicht automatisch ein Echtzeitkurs. Entscheidend ist der angezeigte Kurszeitpunkt; je Anbieter und Börse können Daten mehrere Minuten verzögert sein.',
    keywords: ['Realtime', 'Live', 'Delay', 'Zeitstempel'],
  ),
  KnowledgeEntry(
    id: 'corporate-actions',
    category: 'Kursdaten',
    title: 'Aktiensplit, Dividende und Kapitalmaßnahme',
    text:
        'Splits und Dividenden können historische Kursreihen verzerren. Für Vergleiche verwendet die App nach Möglichkeit angepasste Schlusskurse; Quelle und Zeitraum bleiben trotzdem entscheidend.',
    keywords: ['Adjusted Close', 'Split', 'Dividende', 'Kapitalmaßnahme'],
  ),
  KnowledgeEntry(
    id: 'timeframes',
    category: 'Analyse',
    title: 'Zeitrahmen und Mehrfachanalyse',
    text:
        'Eine Zählung kann im Minutenchart bullisch und im Wochenchart korrektiv wirken. Mehrere Zeitrahmen sollten gemeinsam geprüft werden; der gewählte Zeitraum wird in jedem Snapshot gespeichert.',
    keywords: ['Minute', 'Stunde', 'Tag', 'Woche', 'Monat', 'Multi Timeframe'],
  ),
  KnowledgeEntry(
    id: 'probability-method',
    category: 'Analyse',
    title: 'Plausibilitätswert statt Gewissheit',
    text:
        'Die Szenario-Prozente werden auf 100 normiert und vergleichen Trend, Momentum, Volatilität, Drawdown und Struktur. Sie sind keine aus tausenden identischen Fällen gemessene Häufigkeit.',
    keywords: ['Wahrscheinlichkeit', 'Score', 'Normalisierung', 'Faktoren'],
  ),
];
