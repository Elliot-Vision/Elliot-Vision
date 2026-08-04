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
  Zeitraum und Szenarien ergänzt
- GitHub-Upload und Codemagic-Ersteinrichtung vollständig dokumentiert

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
