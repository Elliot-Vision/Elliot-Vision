/// Topic-specific explanations, numerical examples and limitations.
const knowledgeDetails = <String, (String, String, String)>{
  'pa-basics': (
    'Lies zuerst die Folge der Hochs und Tiefs, dann die Lage einzelner Kerzen innerhalb dieser Struktur. Dieselbe Kerzenform kann mitten in einer Bewegung eine andere Bedeutung haben als an einer mehrfach getesteten Grenze.',
    'Steigt ein Kurs von 100 auf 110 und korrigiert nur bis 105, bleibt zunächst ein höheres Tief bestehen.',
    'Aus der Form lässt sich weder eine sichere Richtung noch der Zeitpunkt einer Bewegung ableiten.'
  ),
  'pa-ohlc': (
    'Die vier Werte beschreiben die gemeldeten Transaktionen eines Intervalls. Aus ihnen lässt sich nicht rekonstruieren, in welcher Reihenfolge Hoch und Tief erreicht wurden. Die Kerze ist eine Zusammenfassung, kein vollständiges Handelsprotokoll.',
    'Bei O 100, H 105, T 98 und S 103 reicht der Körper von 100 bis 103; die Dochte reichen bis 98 und 105.',
    'Ein Datenloch darf nicht durch einen frei erfundenen Eröffnungs- oder Extremkurs gefüllt werden.'
  ),
  'pa-body-wicks': (
    'Die Körpergröße ist der Abstand zwischen erstem und letztem Preis; die gesamte Spanne reicht vom Tief bis zum Hoch. Ein langer Docht zeigt einen zwischenzeitlichen Ausschlag, der bis zum Intervallende teilweise zurückgenommen wurde.',
    'O 103 und S 100 ergibt eine fallende Kerze, auch wenn der Schluss des vorherigen Intervalls nur bei 99 lag.',
    'Die Kerzenfarbe sagt nichts darüber aus, ob du mit deiner persönlichen Position im Gewinn bist.'
  ),
  'pa-interval': (
    'Ein Tageschart und ein Fünf-Minuten-Chart fassen unterschiedlich viele Transaktionen zusammen. Beim Wechsel der Auflösung ändern sich deshalb Anzahl und Form der Kerzen. Handelsfreie Zeiten müssen von fehlenden Daten unterschieden werden.',
    'Zwölf Fünf-Minuten-Intervalle umfassen eine Stunde; eine Stundenkerze hat deren erste Eröffnung, höchste und niedrigste Preise sowie letzten Schluss.',
    'Eine laufende Kerze kann ihre Farbe wechseln. Erst das Intervallende legt den endgültigen Schluss fest.'
  ),
  'pa-doji': (
    'Ein kleiner Körper bedeutet geringe Nettoänderung zwischen Eröffnung und Schluss. Gleichzeitig können die Dochte eine große zwischenzeitliche Schwankung zeigen. Vergleiche die Kerze mit vorherigen Körpern und ihrer Position im Trend.',
    'O 100 und S 100,20 bei H 103 und T 97: Körper 0,20, Gesamtspanne 6; das Verhältnis beträgt etwa 3,3 Prozent.',
    'Doji-ähnlich ist hier eine geometrische Beschreibung. Sie bestätigt allein keine Trendwende.'
  ),
  'pa-wick': (
    'Beim Hammer liegt ein kleiner Körper eher am oberen Ende einer Kerze mit langem unterem Docht; beim Shooting Star ist die Anordnung umgekehrt. Die übliche Musterdeutung berücksichtigt zusätzlich die vorausgehende Bewegung.',
    'Ein Tief bei 95, O 100, S 101 und H 102 zeigt eine deutliche Erholung innerhalb des Intervalls.',
    'Ein Docht beweist keine bewusste Aktion bestimmter Marktteilnehmer. Die App kann aus OHLC keine Motive erkennen.'
  ),
  'pa-engulfing': (
    'Verglichen werden zwei aufeinanderfolgende Kerzenkörper, nicht zwingend die gesamten Hoch-Tief-Spannen. Ein größerer entgegengesetzter Körper zeigt einen stärkeren Richtungswechsel innerhalb dieser beiden Intervalle.',
    'Erste Kerze O 104, S 101; zweite Kerze O 100, S 105: Der zweite Körper umfasst den ersten.',
    'Ein Lehrbild ist keine automatische Signalerkennung. Folgekerzen und der vorherige Trend können die Interpretation verändern.'
  ),
  'pa-support-resistance': (
    'Zonen entstehen durch wiederholte Reaktionen an ähnlichen Preisen. Ihre Breite sollte zur Schwankung und Auflösung passen. Je nach Datenquelle können bereits die sichtbaren Hochs und Tiefs leicht voneinander abweichen.',
    'Mehrere Erholungen zwischen 98 und 100 ergeben eher eine Unterstützungszone als eine exakt wirksame Grenze bei 99.',
    'Auch oft getestete Bereiche können durchbrochen werden; eine Linie stellt keine Preisgarantie dar.'
  ),
  'pa-structure': (
    'Ein Trend wird anhand einer Folge von Wendepunkten beschrieben. Eine kleine Gegenbewegung beendet nicht automatisch die größere Struktur. Seitwärtsphasen zeigen wiederholte Richtungswechsel ohne eindeutige Fortsetzung.',
    'Hochs bei 100, 105 und 110 sowie Tiefs bei 95, 99 und 103 bilden eine aufwärts gerichtete Folge.',
    'Die Auswahl der Wendepunkte beeinflusst die Einordnung. Ein kurzer Ausschnitt kann einen größeren Gegentrend verbergen.'
  ),
  'pa-breakout': (
    'Beim Ausbruch verlässt der Preis eine zuvor beobachtete Grenze. Ein späterer Rücklauf kann zeigen, ob der Bereich von der anderen Seite erneut hält. Schlusskurs und Docht liefern dabei unterschiedliche Informationen.',
    'Ein Kurs verlässt eine Spanne von 95 bis 100, schließt bei 102 und kehrt später in den Bereich um 100 zurück.',
    'Ein Rücktest muss nicht stattfinden. Eine Rückkehr in die alte Spanne kann die ursprüngliche Ausbruchsannahme schwächen.'
  ),
  'pa-context': (
    'Eine Kerze liefert nur einen Ausschnitt. Berücksichtige Auflösung, Quelle, Börsenzeit und benachbarte Zonen. Handelsvolumen misst gemeldete Aktivität und ist nicht mit der Anzahl interessierter Anleger gleichzusetzen.',
    'Ein Tagesvolumen einer einzelnen Kryptobörse beschreibt diese Börse, nicht automatisch den gesamten weltweiten Kryptohandel.',
    'Die aktuelle App beschreibt Kerzen, ohne ein vollständiges Volumen- oder Nachrichtenmodell zu berechnen.'
  ),
  'pa-projection': (
    'Die Projektionslinie verbindet berechnete Stützpunkte. Die Fingerabfrage liest genau diese Linie ab. Ein Modellschritt bezeichnet die Position innerhalb der Projektion und enthält keine kalibrierte Aussage über einen künftigen Handelstag.',
    'Zwischen Modellpunkten bei 100 und 110 zeigt die Mitte einen interpolierten Wert von 105.',
    'Ein präzise angezeigter Zahlenwert erhöht nicht die Prognosesicherheit des zugrunde liegenden Szenarios.'
  ),
  'elliott-prinzip': (
    'Das Regelwerk unterscheidet gerichtete Bewegungen und Korrekturen. Eine Zählung ordnet beobachtete Wendepunkte diesen Rollen zu. Es können mehrere Interpretationen parallel bestehen, weshalb die App Alternativen und Invalidierungsgrenzen zeigt.',
    'Ein fünfteiliger Anstieg wird als mögliche Trendbewegung betrachtet; eine anschließende Gegenbewegung kann korrektiv eingeordnet werden.',
    'Gezählte Wellen sind Modellzuordnungen. Das Muster lässt sich nicht wie ein Naturgesetz auf jeden Kursverlauf anwenden.'
  ),
  'impuls': (
    'Die drei gerichteten Teilwellen werden durch zwei Korrekturen getrennt. Für einen normalen Impuls gelten zusätzlich feste Preisregeln. Die Unterwellen gehören jeweils einer kleineren Betrachtungsebene an.',
    'Aufwärts: Welle 1 steigt, Welle 2 korrigiert, Welle 3 steigt weiter, Welle 4 korrigiert und Welle 5 beendet die Folge.',
    'Fünf sichtbare Richtungswechsel reichen noch nicht als Beleg für einen regelkonformen Impuls.'
  ),
  'impuls-regeln': (
    'Die Preisgrenzen müssen am selben Wellengrad geprüft werden. Ein Verstoß macht die konkrete normale Impulszählung unzulässig, auch wenn andere Merkmale gut aussehen. Leitlinien und harte Regeln sind getrennt zu behandeln.',
    'Bei Start 100 und Ende von Welle 1 bei 110 darf Welle 2 nicht unter den Start bei 100 laufen.',
    'Eine Diagonalstruktur hat eigene Überlappungsregeln. Ausnahmen dürfen nicht nachträglich jede ungültige Zählung retten.'
  ),
  'abc-korrektur': (
    'Die Buchstaben bezeichnen die größeren Teilbewegungen einer Korrektur, nicht jede einzelne Kerze. A und C laufen häufig gegen den vorherigen Trend, B stellt eine zwischenzeitliche Erholung dar.',
    'Nach einem Anstieg folgen ein Rückgang A, eine Erholung B und ein weiterer Rückgang C.',
    'Nicht jede Korrektur endet nach drei einfachen Bewegungen; auch komplexere Kombinationen sind möglich.'
  ),
  'zigzag': (
    'Die erste und letzte Teilbewegung besitzen typischerweise eine gerichtete Fünferstruktur, die mittlere eine Dreierstruktur. Dadurch wirkt die Korrektur meist zielgerichteter als eine breite Seitwärtsphase.',
    'Nach einem Rückgang A erholt sich B teilweise; C setzt anschließend die Gegenbewegung fort.',
    'Eine starke Gegenbewegung allein belegt das Muster nicht. Die innere Unterteilung muss zur gewählten Ebene passen.'
  ),
  'flat': (
    'Bei einer flachen Korrektur kann die mittlere Erholung sehr weit an den Ausgangspunkt zurückreichen. Eine ausgeweitete Variante überschreitet ihn. Der Preisweg kann deshalb zwischenzeitlich wie eine Wiederaufnahme des alten Trends aussehen.',
    'B erreicht oder überschreitet das Ausgangsniveau von A; C läuft anschließend wieder in Richtung der Korrektur.',
    'Die Seitwärtswirkung ist eine typische Eigenschaft, kein Ersatz für die Prüfung der Teilstruktur.'
  ),
  'triangle': (
    'Die fünf Teilbewegungen werden durch zwei Begrenzungslinien eingeordnet. Bei einer kontrahierenden Form nimmt die Spanne tendenziell ab. Die Unterteilung beschreibt eine zeitbindende Korrektur innerhalb einer größeren Struktur.',
    'Aufeinanderfolgende niedrigere Hochs und höhere Tiefs können die Spanne schrittweise einengen.',
    'Eine optische Dreiecksform allein sagt weder die Ausbruchsrichtung noch den genauen Zeitpunkt voraus.'
  ),
  'kombination': (
    'W und Y stehen jeweils für vollständige Korrekturabschnitte. X verbindet diese Abschnitte. Die Buchstaben dürfen nicht mit einzelnen Kerzen oder automatisch mit einer normalen A-B-C-Folge gleichgesetzt werden.',
    'Eine erste abgeschlossene Korrektur wird durch eine Erholung verbunden, bevor eine zweite Korrektur folgt.',
    'Komplexe Bezeichnungen sollten eine nachvollziehbare Struktur beschreiben und nicht bloß nachträglich Unklarheit verdecken.'
  ),
  'leading-diagonal': (
    'Diese Sonderform wird am Beginn einer größeren gerichteten Bewegung betrachtet. Ihre Preisbereiche können sich stärker überlappen als bei einem normalen Impuls. Die Position im Gesamtmuster gehört zur Definition.',
    'Eine keilförmige erste Teilbewegung kann als Anfangsdiagonale geprüft werden, bevor eine größere Fortsetzung angenommen wird.',
    'Eine Überlappung allein bestätigt keine Diagonale. Auch Position und innere Struktur müssen passen.'
  ),
  'ending-diagonal': (
    'Die Enddiagonale wird am Abschluss einer gerichteten Bewegung eingeordnet. Überlappende Teilwellen und eine keilförmige Begrenzung können nachlassende Dynamik beschreiben. Die erwartete Gegenbewegung bleibt eine Hypothese.',
    'Eine mögliche fünfte Welle entwickelt mehrere überlappende Teilbewegungen mit abnehmender Spanne.',
    'Ein sichtbarer Keil bedeutet nicht, dass der Abschluss bereits feststeht oder die Gegenbewegung unmittelbar beginnen muss.'
  ),
  'wellengrad': (
    'Die Betrachtungsebene verbindet eine größere Welle mit ihren Unterbewegungen. Ein Tageschart kann die übergeordnete Struktur zeigen, während ein Minutenchart nur einen kleinen Teil davon auflöst.',
    'Ein größerer Anstieg kann im Wochenchart eine Teilwelle und im Tageschart mehrere Unterwellen umfassen.',
    'Wellen verschiedener Ebenen dürfen bei Regelprüfungen nicht beliebig vermischt werden.'
  ),
  'alternation': (
    'Unterscheiden sich zwei Korrekturen in Form, Zeitbedarf oder Tiefe, kann das die Einordnung einer Impulsfolge unterstützen. Die Beobachtung ist eine Leitlinie und kann trotz gültiger Zählung fehlen.',
    'Eine schnelle tiefe zweite Welle kann einer längeren seitwärts laufenden vierten Welle gegenüberstehen.',
    'Eine Verletzung dieser Tendenz ist nicht automatisch ein Verstoß gegen die harten Impulsregeln.'
  ),
  'fibonacci-retracement': (
    'Gemessen wird der Rücklauf relativ zu einer klar ausgewählten Ausgangsbewegung. Die Wahl von Start und Ende verändert sämtliche Marken. Die 50-Prozent-Marke ist ein verbreiteter Vergleichswert, aber keine eigentliche Fibonacci-Quote.',
    'Bei einer Bewegung von 100 auf 120 liegt ein Rücklauf von 50 Prozent bei 110; 61,8 Prozent entsprechen etwa 107,64.',
    'Eine rechnerische Marke belegt nicht, dass dort tatsächlich Nachfrage oder Angebot auftreten wird.'
  ),
  'fibonacci-extension': (
    'Eine vorangegangene Bewegung dient als Längenmaß und wird von einem gewählten Bezugspunkt aus fortgeschrieben. Die Berechnung ergibt mögliche Vergleichsniveaus, keine gemessenen zukünftigen Kurse.',
    'Eine Referenzstrecke von 10 ergibt bei 161,8 Prozent eine Projektionslänge von 16,18 ab dem gewählten Startpunkt.',
    'Andere Bezugspunkte ergeben andere Ziele. Die mathematische Genauigkeit darf nicht mit Vorhersagegenauigkeit verwechselt werden.'
  ),
  'overlap': (
    'Entscheidend sind die tatsächlichen Preisbereiche derselben betrachteten Ebene. Die Prüfung erfolgt auf Kurswerten, nicht auf der optischen Nähe von Beschriftungen. Zoom oder Skalierung ändern den Regelverstoß nicht.',
    'Bei einem normalen Aufwärtsimpuls wäre ein Rücklauf von Welle 4 in den Preisbereich von Welle 1 eine ungültige Überlappung.',
    'Die Sonderregeln einer Diagonale müssen ausdrücklich begründet sein und gelten nicht pauschal für jeden Impuls.'
  ),
  'truncation': (
    'Eine verkürzte letzte Bewegung kann erst sinnvoll diskutiert werden, wenn ihre Unterstruktur einen Abschluss erkennen lässt. Andernfalls könnte die Bewegung schlicht noch unvollständig sein.',
    'Welle 3 erreicht 120, eine mögliche fünfte Welle endet trotz fünfteiliger Unterstruktur nur bei 118.',
    'Das Ausbleiben eines neuen Hochs allein beweist noch keine abgeschlossene fünfte Welle.'
  ),
  'invalidation': (
    'Die Grenze gehört zu einem bestimmten Szenario. Ihre Verletzung verändert diese Zählung, nicht zwangsläufig jedes andere Szenario. Sie sollte aus einer benannten Regel und einem konkreten Bezugspunkt nachvollziehbar sein.',
    'Unterschreitet eine mögliche zweite Welle den Startpunkt der ersten, ist diese normale Impulszählung ungültig.',
    'Invalidierung ist nicht gleich Ausführungskurs einer Stop-Order; Datenlücken und Kurssprünge können dazwischenliegen.'
  ),
  'szenarien': (
    'Ein Hauptszenario fasst die aktuell am besten bewertete Interpretation zusammen. Eine Alternative zeigt einen anderen regelbezogenen Verlauf. Neue Daten können die Rangfolge ändern, ohne dass historische Kurse verändert werden.',
    'Ein noch gültiger Anstieg und eine mögliche Korrektur können gleichzeitig als unterschiedliche Zählungen diskutiert werden.',
    'Die App zeigt im Chart zwei Varianten, während ihre Modellgewichte auf allen drei bewerteten Szenarien beruhen.'
  ),
  'score': (
    'Der Score verdichtet ausgewählte Modellmerkmale. Unterschiedliche Modelle können denselben Verlauf anders gewichten. Ein hoher Wert sagt deshalb zunächst etwas über die Übereinstimmung mit den Modellkriterien aus.',
    'Ein Modell kann gute Regelkonformität stärker gewichten als kurzfristiges Momentum und dadurch eine andere Rangfolge erzeugen.',
    'Ein Score von 80 bedeutet weder 80 Prozent Rendite noch automatisch 80 Prozent Trefferwahrscheinlichkeit.'
  ),
  'pivot': (
    'Wendepunkte werden erst im Verhältnis zu benachbarten Preisen sichtbar. Eine Schwankungsschwelle unterdrückt kleine Gegenbewegungen, kann aber auch spätere Bestätigung verursachen. Die App verwendet dafür eine angepasste Erkennung.',
    'Eine Folge von 100, 105 und 102 kann im kurzen Ausschnitt ein lokales Hoch bei 105 zeigen.',
    'Ein letzter Wendepunkt kann sich mit neuen Kursen verschieben. Das darf nicht als schon vorher bekannt behandelt werden.'
  ),
  'support-resistance': (
    'Mehrfache Reaktionen in ähnlichen Bereichen können eine Zone für die Strukturprüfung liefern. Für den Vergleich müssen Währung, Handelsplatz und Kursbereinigung übereinstimmen. Der Bereich bleibt eine Beobachtung statt einer Verpflichtung des Marktes.',
    'Mehrere lokale Tiefs zwischen 49 und 50 bilden einen Bereich; ein Ausbruch darunter verändert seine bisherige Einordnung.',
    'Ein auf einer Börse sichtbares Extrem muss nicht exakt mit dem Preis eines anderen Handelsplatzes übereinstimmen.'
  ),
  'volume-divergence': (
    'Eine Divergenz vergleicht die Preisentwicklung mit einem separat definierten Maß für Aktivität oder Dynamik. Dafür müssen vergleichbare Zeiträume und verlässliche Daten vorliegen. Die App berechnet nicht automatisch sämtliche genannten Indikatoren.',
    'Ein höheres Kurshoch bei einem niedrigeren Momentum-Hoch kann eine abweichende Entwicklung zeigen.',
    'Eine Divergenz kann über längere Zeit bestehen und bestimmt allein keinen Umkehrzeitpunkt.'
  ),
  'ath-atl': (
    'Die Extremwerte beziehen sich auf den verfügbaren historischen Datenumfang und dessen Bereinigung. Ein kurzer Zeitraum reicht für ein echtes Allzeithoch nicht aus; fehlende ältere Daten begrenzen die Aussage.',
    'Das Hoch eines Jahres ist nur dann zugleich ein Allzeithoch der verfügbaren Reihe, wenn ältere Daten keinen höheren Wert enthalten.',
    'Ein Börsenplatzwechsel oder eine andere Währung kann andere Höchst- und Tiefstwerte ergeben.'
  ),
  'risk-reward': (
    'Verglichen werden Preisabstände zu einem angenommenen Ziel und einer angenommenen Verlustgrenze. Das Verhältnis enthält keine Information darüber, wie häufig das Ziel tatsächlich erreicht wird. Kosten und mögliche Ausführungslücken verändern das Ergebnis.',
    'Bei Einstieg 100, Ziel 110 und Risikogrenze 95 beträgt das rechnerische Verhältnis 10 zu 5, also 2 zu 1.',
    'Auch ein Verhältnis von 2 zu 1 kann bei vielen Fehlschlägen insgesamt zu Verlusten führen.'
  ),
  'entry-zone': (
    'Die Bandbreite berücksichtigt, dass Wendepunkte nicht auf einen einzelnen Cent vorhergesagt werden. In der App folgt der Bereich den gewählten Modellannahmen und wird blau dargestellt. Eine reale Order wird dadurch nicht ausgelöst.',
    'Ein Modellbereich von 98 bis 101 beschreibt eine Spanne, nicht einen bereits bestätigten Kauf bei 99.',
    'Bei einem Abwärtsszenario hat derselbe Begriff eine andere Richtungseinordnung als bei einem Aufwärtsszenario.'
  ),
  'exit-zone': (
    'Mehrere mögliche Zielniveaus können zu einem Bereich zusammengefasst werden. In der App gehört die farbige Zone zu genau einem Szenario. Bei einer abwärts gerichteten Projektion kann sie unter dem Referenzkurs liegen.',
    'Ein Bereich von 108 bis 112 fasst mehrere angenommene Endniveaus zusammen, ohne eine Ausführung innerhalb dieser Spanne zuzusichern.',
    'Die App platziert keine Take-Profit-Order und berücksichtigt keine persönliche Steuer- oder Gebührensituation.'
  ),
  'stop-loss': (
    'Eine Stop-Market-Order wird bei Auslösung zu einer Marktorder und kann bei schnellen Bewegungen zu einem anderen Preis ausgeführt werden. Eine Stop-Limit-Order begrenzt den Preis, kann dafür unausgeführt bleiben.',
    'Eine Grenze bei 95 bedeutet bei einem Kurssprung von 97 auf 90 nicht automatisch eine Ausführung bei 95.',
    'Eine eingezeichnete Modellgrenze ist keine tatsächlich beim Broker hinterlegte Schutzorder.'
  ),
  'position-sizing': (
    'Die einfache Rechnung teilt einen angenommenen maximalen Geldverlust durch den Preisabstand zur Verlustgrenze. Gebühren, Währungsbewegungen, Mindeststückelung und Ausführungslücken sind darin noch nicht enthalten.',
    'Bei einem hypothetischen Verlustbudget von 100 und einem Preisabstand von 5 ergibt die reine Division 20 Stück.',
    'Die Beispielrechnung legt kein angemessenes persönliches Risikobudget fest und garantiert keine Verlustobergrenze.'
  ),
  'liquidity-slippage': (
    'Der Geldkurs beschreibt ein Kaufgebot, der Briefkurs ein Verkaufsangebot. Die Differenz ist der Spread. Ein zuletzt gehandelter Kurs kann zwischen beiden liegen und muss nicht sofort handelbar sein.',
    'Bei Geld 99 und Brief 101 beträgt der Spread 2; ein Marktauftrag kann deshalb vom zuletzt angezeigten Kurs abweichen.',
    'Ein schneller Abruf beseitigt weder den Spread noch mögliche Abweichungen bei der tatsächlichen Ausführung.'
  ),
  'asset-types': (
    'Die Anlageklasse beschreibt unterschiedliche Markt- und Produktstrukturen. Ein ETF ist ein Fondsanteil und kein einzelnes Unternehmen. Ein Kryptopreis gehört zu einem bestimmten Handelspaar und Handelsplatz; es gibt keinen universellen identischen Preis.',
    'BTC/EUR und BTC/USD derselben Börse sind verschiedene Märkte, deren Verhältnis auch von Wechselkursen beeinflusst wird.',
    'Ein 24-Stunden-Markt bedeutet nicht, dass Datenquelle oder Netzwerk jederzeit ohne Unterbrechung erreichbar sind.'
  ),
  'isin-ticker-venue': (
    'Für einen sauberen Vergleich müssen Produkt und konkrete Notierung zusammenpassen. Eine ISIN kann zu mehreren Börsensymbolen führen. Die App muss deshalb den gewählten Platz und die dazugehörige Währung beibehalten.',
    'Dasselbe Wertpapier kann in den USA in Dollar und an einem deutschen Platz in Euro gehandelt werden.',
    'Eine Symbolähnlichkeit oder ein ähnlicher Name genügt nicht als Beleg für dasselbe Produkt.'
  ),
  'data-delay': (
    'Unterscheide Abrufzeit, Zeitpunkt des letzten gemeldeten Geschäfts und Auflösung einer Kerze. Ein frisch empfangener Tagesbalken kann einen älteren Handelstag beschreiben. Börsenschluss erklärt ebenfalls ältere Kurse.',
    'Ein Abruf um 12:00 mit letztem gemeldeten Preis von 11:45 enthält trotz erfolgreicher Verbindung keinen Kurs von 12:00.',
    'Eine unbekannte Verzögerung darf nicht als null oder als garantierte Echtzeit dargestellt werden.'
  ),
  'corporate-actions': (
    'Bereinigte Reihen verändern frühere Preise, um Kapitalmaßnahmen vergleichbar zu machen. Für einen Kerzenvergleich müssen Eröffnung, Hoch, Tief und Schluss mit demselben Faktor angepasst werden. Eine reine Währungsumrechnung ersetzt diese Bereinigung nicht.',
    'Bei einem Split im Verhältnis zwei zu eins halbiert sich der vergleichbare Preis je Anteil, während sich die Stückzahl verdoppelt.',
    'Eine Mischung aus bereinigten Schlusskursen und unbereinigten Hochs kann falsche Spannweiten erzeugen.'
  ),
  'timeframes': (
    'Zeitraum und Intervall beantworten verschiedene Fragen: Wie weit zurück wird geschaut und wie fein ist jede Beobachtung? Eine größere Spanne benötigt oft gröbere Daten. Der Wechsel kann lokale Wendepunkte zusammenfassen.',
    'Ein Jahresblick mit Wochenkerzen hat weniger Detail als fünf Handelstage mit halbstündlichen Kerzen.',
    'Ein kurzfristiger Gegentrend widerspricht einer langfristigen Bewegung nicht zwangsläufig.'
  ),
  'probability-method': (
    'Die App berechnet vergleichende Gewichte aus Struktur und ausgewählten Kursmerkmalen und normiert sie gemeinsam. Eine statistisch kalibrierte Wahrscheinlichkeit würde unabhängige historische Prüfungen und eine genaue Erfolgsdefinition erfordern.',
    'Rohwerte von 2, 3 und 5 ergeben nach Normierung 20, 30 und 50 Prozent; das ist zunächst nur ein relativer Vergleich.',
    'Wenn im Chart nur zwei Varianten sichtbar sind, ändern sich dadurch nicht automatisch die Gewichte der vollständigen Bewertung.'
  ),
};
