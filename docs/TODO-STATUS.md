# Elliott Vision – Umsetzungsstatus der zentralen To-do-Liste

Stand: Entwicklungsbranch vom 16. Oktober 2026 (Basis 0.4.1+7)

## Umgesetzt: Analyse-Reiter für Elliott-Wellen und Price Action

In regulärer Analyse und Testbereich umgesetzt; Geräteabnahme steht aus.

- „Kompakt“, „Standard“ und „Experte“ in der regulären Analyse ersetzt.
- Beide Bereiche zeigen einen eigenen Inhalt: Elliott-Szenarien oder OHLC-Kerzen.
- Kerzen aus vollständigen Anbieterwerten, einschließlich Euro-Umrechnung und
  Anpassung an bereinigte Schlusskurse; alte Snapshots bleiben lesbar.
- Synthetische Kerzen ausschließlich für die gekennzeichneten Testdaten.
- Price Action beschreibt die letzte Kerze (Körper, Doji-ähnlich, langer Docht),
  die Spanne und Schlusskursänderung der letzten bis zu 20 Kerzen.
- Erklärungen zu OHLC, Körper, Dochten, Intervallen und laufenden Kerzen.
- Vorhandene Elliott-Erklärungen und Regelprüfungen bleiben zugänglich.
- Keine erfundenen Kerzen bei fehlenden OHLC-Daten; Neuladen wird angeboten.

## Entwicklungsbranch EV-018 / EV-019

- Separater Test-Tab mit eigenen, sichtbar gekennzeichneten Demodaten.
- Demo-Wertpapierauswahl, sieben Zeiträume, Szenarien einzeln schaltbar und Zonen ein-/ausblendbar.
- Stufenloser horizontaler Zoom im gemeinsamen Chart.
- Zoom und Scrollen auf dem zurückgenommenen Stand auf Android bestätigt; Verschieben und Reset zuvor ebenfalls bestätigt.
- Nutzer bestätigt fünf Demo-Aktien, Einfinger-Kursabfrage und funktionierenden Zoom.
- Zeitraum-Demoreihen und kontinuierlich interpoliertes Ablesen nachgebessert; neue Geräteprüfung ausstehend.
- Horizontale Ablesegesten bleiben nach Beginn auch bei vertikalem Zittern
  aktiv; Punkteliste wird zwischengespeichert und unsichtbare Projektionsstriche
  werden beim Zeichnen übersprungen. Regressionstest für Richtungswechsel ergänzt.
- Rahmenlose Darstellung ohne Kartenhintergrund im Test-Tab ergänzt.
- Gemeinsamer Chart in regulärer Analyse und Historie übernommen: Zoom, Verschieben, interpolierte Kursabfrage, freie Darstellung ohne linke Euro-Achse.
- Testbereich auf Hauptszenario und stärkste Alternative begrenzt; reguläre Analyse behält alle drei Szenarien.
- Datenabruf und gespeicherte Snapshots bleiben an ihre bisherigen Quellen angebunden; Demoreihen bleiben im Testbereich.
- Vollständiger Abgleich: [Repository-Prüfung](REPOSITORY-ABGLEICH-EV018-EV019.md).

## In der App umgesetzt

- Bullische, neutrale und bärische Szenarien einzeln ein-/ausblendbar
- Szenariofilter lösen nachweislich eine Neuzeichnung der Chart-Overlays aus
- Haupt- und Alternativszenarien mit normalisierten Prozentwerten
- sichtbare Erklärung der Bewertungsfaktoren und Methodik
- adaptive Wendepunkterkennung, drei Zählmethoden und überlagerbare
  Wellenlabels
- sichtbare Prüfung der harten Regeln zu Welle 2, Welle 3 und Welle 4
- Einstiegs-, Ausstiegs-, Ziel-, Stop- und Invalidierungszonen
- Analysehistorie mit vollständigem Instrument- und Kurs-Snapshot
- Regelwerk-, Erklärungsmodell- und Promptversions-Nachweis
- Zeitachse und Euro-Kursabfrage mit dem Finger; keine linke Preisachse
- 1 Tag, 5 Tage, 1 Monat, 3 Monate, 1 Jahr, 5 Jahre und Max
- automatisch passende 5-Minuten-, 30-Minuten-, Tages-, Wochen- und Monatsdaten
- aktueller Kurs, Kurszeitpunkt, ATH, ATL und aktuelle Abstände
- erwartete Kursverläufe im Dark-Mode-Chart
- durchsuchbares Depot und Hinzufügen mit Kaufdatum, Kaufpreis und Stückzahl
- Depotpositionen anklickbar und direkt analysierbar
- Positionswert sowie Gewinn/Verlust in Euro und Prozent
- automatische Aktualisierung, Aktualisieren-Button und Pull-to-refresh
- atomare lokale Speicherung mit Backup, Altdatenmigration und maximal 100
  Historieneinträgen
- sichtbare Unterscheidung von Aktie, ETF und Kryptowährung
- 24/7-Kennzeichnung für Krypto und Börsenzeiten-Hinweis für Wertpapiere
- Asset-Filter in der Suche
- Suche nach Name, Ticker und prüfziffervalidierter ISIN
- Handelsplatzwechsel mit tatsächlichem Neuladen von Symbol, Kurs, Währung und
  Zeitreihe
- Originalkurs, Euro-Kurs, FX-Rate, Kurszeitpunkt und Datenverzögerung
- fünfminütiger FX-Cache ohne Fehler-Caching und mit erzwungenem Neuladen bei
  manueller Aktualisierung
- handelsplatzbezogene ATH/ATL ohne Vermischung mit vorherigen Börsenplätzen
- reproduzierbarer Build mit Flutter 3.44.0 und `pubspec.lock`
- Favoriten direkt analysierbar
- dokumentierte Quellen, Endpunkte, Intervalle, FX-, Split- und Fallback-Logik
- durchsuchbare Wissensdatenbank mit mindestens 35 Begriffen
- durchgängiger Dark Mode, minimalistisches Finanz-App-Design und Farbscore
- getrennte Analyseansichten für Elliott-Wellen und Price Action

## Technisch vorbereitet; Einrichtung / Abnahme noch offen

- Workflow `android-test-signed` für Test-APKs mit fester Signatur und steigender
  Buildnummer. Der passende Keystore muss in Codemagic hinterlegt werden.
- CSV-Vergleichswerkzeug für unabhängige Referenzdaten, einschließlich Tests.
  Ein tatsächlich unabhängiger Datensatz muss noch bereitgestellt werden.
- Anleitung und konkrete Freigabeschritte: [Test-Signierung und Freigabe](TEST-SIGNIERUNG-UND-FREIGABE.md).
- Android-Prüfung: längeres Ablesen mit Richtungswechsel, Zoom/Pan/Scrollen,
  Zeitraum- und Reiterwechsel, OHLC-Anzeige und Installation eines Folgeupdates.

## Extern vor einer öffentlichen Produktionsversion erforderlich

- Vertrag und Lizenz für einen kommerziell nutzbaren Marktdatenanbieter
- unabhängige Referenzquelle und Golden Dataset für automatisierte Datenchecks
- dauerhaft gesicherter Android-Release-Keystore in Codemagic
- Datenschutz-, Impressums-, Risiko- und Store-Prüfung

Diese Punkte benötigen Anbieter-, Rechts- oder Kontoinhaberentscheidungen und
können nicht allein durch App-Code abgeschlossen werden.
