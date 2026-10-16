# Unveröffentlicht – EV-018 / EV-019

- Wissensdatenbank als aufklappbare Überschriftenliste: alle 47 Einträge mit vertiefter Erklärung, Beispiel und Grenzen; vollständige Texte bleiben durchsuchbar.
- Zwölf offlinefähige Price-Action-Lehrbilder für Kerzen, Dochte, Muster, Struktur, Zonen und Projektion ergänzt, einschließlich beschrifteter OHLC-Werte und Bildschirmleser-Beschreibungen.
- Kostenlose öffentliche Kraken-Spotdaten für ausgewählte Krypto-Euro-Paare angebunden: direkte EUR-OHLC und tatsächlicher Zeitpunkt des letzten Trades. Intervall und begrenzte Historie sind gekennzeichnet; keine Zugangsdaten erforderlich.
- Aktien-/ETF-Quelle präziser gekennzeichnet; OpenFIGI nicht länger als Kursquelle dargestellt. Fehlende Kurszeitpunkte werden nicht durch die Abrufzeit ersetzt, ungültige Zeitwerte verworfen und doppelte Zeitpunkte bereinigt. Historische Euro-Umrechnung und unbekannte Verzögerung werden offengelegt.

- Wissensdatenbank um zwölf Price-Action-Begriffe erweitert: OHLC, Kerzenaufbau, Doji, Dochte, Engulfing, Intervalle, Struktur, Zonen, Ausbruch/Rücktest und Grenzen der Interpretation.
- Szenarioauswahl und hervorgehobene Ein-/Ausstiegszonen samt Herleitung aus dem Testbereich in reguläre und gespeicherte Analysen übernommen. Charts zeigen Hauptszenario und stärkste Alternative; alle drei Szenarien bleiben Teil der Modellbewertung.
- Einfinger-Abfrage interpolierter Projektionspreise mit Fadenkreuz, Szenarioname und Modellschritt ergänzt. Die Anzeige enthält ausdrücklich keine erfundenen zukünftigen Handelstermine. Testdaten bleiben im Testbereich.

- Depot: Eingabe-Controller und Such-Timer gehören jetzt zum Zustand des Positionsdialogs. Sie werden erst beim Entfernen des Dialogs freigegeben, damit Speichern und Schließen während der Animation keine Zugriffe auf bereits freigegebene Controller auslösen. Zwei Regressionstests reproduzieren und prüfen diese Abläufe einschließlich erneutem Öffnen.

- Testbereich: Projektion und Zonen per Antippen auswählbar; aktive Linie und Einstiegs-/Ausstiegsbereiche hervorgehoben. Zugeordnete Kurswerte, Stop-Loss, Invalidierung und verwendete Daten mit Herleitung ergänzt. Alternativauswahl über beschriftete Schalter; Zoom und reguläre Analyse bleiben verfügbar.

- Reguläre Analyse und Testbereich mit Reitern „Elliott-Wellen“ und „Price Action“; alte Informationsebenen ersetzt, Elliott-Erklärungen erhalten.
- Price Action mit OHLC-Kerzenchart, Fingerabfrage der vier Kerzenwerte, regelbasierter Beschreibung und Erklärungen zu Körpern, Dochten und Intervallen. Anbieter-OHLC werden umgerechnet und gespeichert; fehlende Kerzen bleiben sichtbar fehlend.
- Horizontale Kursabfrage gegen vertikales Zittern und Richtungswechsel abgesichert; Punkteliste zwischengespeichert und Zeichnung unsichtbarer Projektionsstriche reduziert.
- Codemagic-Workflow für fest signierte Test-APKs und steigende Buildnummer vorbereitet; Kontoeinrichtung weiterhin erforderlich.
- Unabhängigen CSV-Referenzvergleich ergänzt; Lizenz-, Referenzdaten- und Veröffentlichungsaufgaben bleiben dokumentiert offen.
- Gemeinsamer interaktiver Chart für reguläre Analyse, gespeicherte Analysen und Test-Tab; doppelte Painter-Implementierung entfernt.
- Test-Tab zeigt maximal zwei Projektionen: Hauptszenario und stärkste Alternative. Reguläre Analyse behält ihre drei Szenariofilter.
- Linke Euro-Achsenbeschriftung im Test-Chart entfernt; Kursverlauf erhält 44 Pixel mehr Breite. Preisabfrage und Zoom verwenden dieselben neuen Plot-Grenzen.
- Test-Chart frei ohne Kartenhintergrund, mit geringerem Seitenabstand.
- Eigene synthetische Demoreihen mit tatsächlicher Zeitspanne pro Auswahl; Max zeigt zehn Jahre.
- Einfinger-Ablesen zwischen Datenpunkten interpoliert, mit entsprechender Kennzeichnung.
- Test-Tab mit Demo-Wertpapierauswahl, sieben Zeiträumen, einzelnen Szenarioschaltern und Zonenschalter erweitert.
- Neue Kursabfrage-Korrektur und Price Action benötigen noch die Android-Abnahme.
- Isolierter Test-Tab mit Demodaten.
- Stufenloser Chart-Zoom, Verschieben und Reset in den gemeinsamen Charts.
- Repository-Abgleich und sechs neue Regressionstests.
- Kurs und Datum/Uhrzeit beim horizontalen Ablesen mit einem Finger, inklusive Fadenkreuz; Projektionen separat gekennzeichnet.
- Zwei Finger übernehmen Zoom und Verschieben auf der gesamten Chartfläche; fünf zusätzliche Gesten- und Ablesetests.

# Änderungsprotokoll

## 0.4.1+7 – 4. August 2026

- echte Pivot-Erkennung per volatilitätsangepasstem ZigZag ergänzt
- harte Elliott-Regeln für Welle 2, Welle 3 und Welle 4 explizit geprüft
- erkannte historische Wellenpunkte und Regelstatus im Chart sichtbar
- ISIN-Prüfziffer validiert und ISIN vor Yahoo-Treffern exakt über OpenFIGI
  zugeordnet
- OpenFIGI-Rate-Limits mit Backoff, Retry und verständlichem Fehler behandelt
- Handelsplatzwahl lädt nun das bestätigte Symbol, den Kurs, die Währung und
  die Zeitreihe des gewählten Platzes neu
- Zeitraum und Chart bleiben bei fehlgeschlagenem Abruf konsistent
- sichtbare Szenarien bleiben bei Aktualisierung, Zeitraum- und Platzwechsel
  erhalten
- Ein-/Ausstiegs- und Stop-Loss-Zonen für jedes sichtbare Szenario ergänzt
- ATH/ATL aus angepassten Tages-/Periodenhochs und -tiefs statt nur
  Schlusskursen berechnet
- Depot, Favoriten, Kurscache und Historie in atomare Datendatei mit Backup und
  Migration verschoben; Historie auf 100 Snapshots begrenzt
- Codemagic um technischen Check, einmalige Schlüsselerzeugung und fest
  signierten APK-/AAB-Releaseworkflow erweitert
- Widget-Tests für Suche, Navigation und Zeitraumwechsel vollständig
  entkoppelt; konkurrierenden Debounce-Suchlauf entfernt, asynchrone
  Zustandswechsel explizit abgewartet und lazy aufgebaute Listeninhalte vor
  der Prüfung gezielt sichtbar gescrollt
- eindeutige UI-Schlüssel für Startseitenliste, Analyseinhalt, Handelsplatz,
  Zeitraum, Kurszeitpunkt und Szenarien ergänzt
- Widget-Test für den Kurszeitpunkt von der mehrdeutigen Textsuche
  `Kursstand` auf den eindeutigen Schlüssel `quote-timestamp` umgestellt
- GitHub-Upload und Codemagic-Ersteinrichtung vollständig dokumentiert
- Szenarioauswahl auf unveränderliche Zustands- und Painter-Snapshots
  umgestellt, damit jede Änderung den Chart zuverlässig neu zeichnet
- FX-Cache auf fünf Minuten begrenzt; fehlgeschlagene Abfragen werden nicht
  gespeichert und eine manuelle Aktualisierung lädt den Wechselkurs neu
- OpenFIGI-Wiederholungen berücksichtigen nun den dokumentierten Header
  `ratelimit-reset` statt zu früh im selben Sperrfenster erneut anzufragen
- ATH und ATL werden beim Handelsplatzwechsel nicht mehr mit Werten eines
  anderen Börsenplatzes vermischt; kurze Zeiträume erhalten die Extremwerte
  aus einem separaten Maximalabruf desselben Symbols
- Codemagic auf Flutter 3.44.0 festgelegt und `pubspec.lock` mit Paketversionen
  und SHA-256-Prüfsummen eingecheckt
- Regressionstests für Chart-Neuzeichnung, FX-Ablauf und FX-Fehler,
  OpenFIGI-Reset, handelsplatzbezogene Extremwerte und Backup-Wiederherstellung
  ergänzt; insgesamt 19 Tests
- Codemagic-Widget-Test gegen durch lazy Listen entsorgte Chart-Widgets
  abgesichert; der Fehler `Bad state: No element` tritt nicht mehr auf
- Keystore-Pfade vor dem Schreiben von `key.properties` plattformübergreifend
  normalisiert und mit zwei Python-Regressionstests in beiden
  Codemagic-Workflows abgesichert

## 0.4.0+6 – 4. August 2026

- vollständige Umsetzung der zentralen App-To-do-Liste
- echte Zeitachsen und sieben Chart-Zeiträume
- mehrere Zählmethoden mit Szenario-Overlays und Wellenlabels
- Einstiegs-, Ausstiegs-, Stop- und Invalidierungszonen
- transparente Prozentfaktoren und drei Informationsebenen
- vollständige Analyse-Snapshots mit damaligem Kursstand
- Asset-Typen und Filter für Aktie, ETF und Krypto
- Depotkarten direkt analysierbar; Gewinn/Verlust in Euro und Prozent
- Pull-to-refresh für Suche, Favoriten, Depot und Analyse
- ATH-/ATL-Abstände, Datenverzögerung und erweiterte Quellenangaben
- Wissensdatenbank auf mindestens 35 Begriffe erweitert
- Datenquellen-, Qualitäts- und Lizenzdokumentation ergänzt

## 0.3.0+5 – 3. August 2026

- Kurszeitpunkt unter dem Originalkurs
- Online-Suche beim Hinzufügen einer Depotposition
- durchsuchbare Wissensdatenbank

## 0.2.0+4 – 3. August 2026

- Online-Suche nach Name, Ticker und ISIN
- Euro-Umrechnung und Depot-Aktualisierung
- durchgängiger Dark Mode
