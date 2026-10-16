# Repository-Abgleich und EV-018 / EV-019

Stand: 14. Oktober 2026. Geprüfte Basis: main, Commit
9fa34e3db73529c4c8a91dc96d714ed105f417c4 (Version 0.4.1+7).

Verglichen wurden die zentrale To-do-Liste vom 6. August 2026 aus dem
Projektmaterial, docs/TODO-STATUS.md, PRUEFBERICHT.md und der aktuelle Code.
Die ältere Liste enthält bereits einen Code-Audit: Ihre ursprünglichen
19 offenen Aufgaben sind deshalb kein zutreffender Implementierungsstatus.

## Abgleich

| ID | Befund auf main | Code / Nachweis |
| --- | --- | --- |
| EV-001 | Vorhanden | screens.dart: Depot-Suche, holding-instrument-search; Widgettest |
| EV-002 | Vorhanden | screens.dart: quote-timestamp; Widgettest |
| EV-003 | Vorhanden | knowledge_data.dart; knowledge_data_test.dart prüft Umfang |
| EV-004 | Vorhanden | LearnScreen und knowledge-search-field; Widgettest |
| EV-005 | Teilweise gemäß Plan | Szenariofilter in AnalysisScreen vorhanden, bereits regulär sichtbar |
| EV-006 | Vorhanden | chart.dart: Euro- und zeitabhängige Datumsachsen |
| EV-007 | Vorhanden | analysis_engine.dart: Entry/Exit/Stop; Chart-Zonen und Szenariokarten |
| EV-008 | Vorhanden | Drei Szenarien, Hauptszenario und normalisierte Plausibilitätswerte; Engine-Tests |
| EV-009 | Vorhanden | ChartTimeframe, loadSeries und Intervalltest |
| EV-010 | Vorhanden | AssetType und Live-Marktdaten-Zuordnung |
| EV-011 | Vorhanden | Depotkarte öffnet AnalysisScreen per onTap |
| EV-012 | Vorhanden | AppState.initialize startet refreshPortfolio für gespeicherte Positionen/Favoriten |
| EV-013 | Vorhanden | RefreshIndicator in regulären Ansichten |
| EV-014 | Vorhanden | Sichtbare Szenario-IDs und Auswahl-Erhalt beim Zeitraumwechsel; Widgettests |
| EV-015 | Teilweise gemäß Plan | Szenarioüberlagerung schon in regulärer Analyse, keine reine Testfunktion |
| EV-016 | Vorhanden | AppState.saveAnalysis, LocalStore, HistoryScreen; Persistenztests |
| EV-017 | Teilweise | Quellen und technische Plausibilitätsprüfungen dokumentiert; unabhängige Referenzquelle/Golden Dataset fehlen |
| EV-018 | Fehlte; in diesem PR umgesetzt | Sechstes Navigationsziel Test und isolierte TestScreen |
| EV-019 | Fehlte; in diesem PR umgesetzt | ExperimentalScenarioChart mit kontinuierlichem horizontalem Zoom |

Vor diesem PR: 14 Funktionen vorhanden, 3 teilweise gemäß Plan, 2 offen.
Vorhanden bedeutet Implementierung und passende Codebelege, keine unabhängige
fachliche Validierung von Finanzdaten oder Prognosewahrscheinlichkeiten.
Die bereits regulären EV-005/EV-015 werden nicht verschoben, um vorhandene
Bedienabläufe zu erhalten. Diese Abweichung vom älteren Plan bleibt sichtbar.

## Implementierung und Isolation

- TestScreen besitzt einen eigenen DemoMarketDataRepository und eine lokale
  Regelanalyse. Sie greift nicht auf AppScope, Live-Daten oder LocalStore zu.
- Der Demo-Hinweis ist sichtbar; es gibt keine Speicher- oder Depotaktionen.
- Pinch-Zoom ist kontinuierlich zwischen 1x und 20x; horizontaler Drag
  verschiebt den Ausschnitt innerhalb der Datenränder. Reset und Doppeltippen
  stellen die Übersicht wieder her. Ein Finger vertikal scrollt die Seite.
  Zwei Finger übernehmen Zoom und Verschieben. Der Nutzer bestätigt inzwischen
  die Einfinger-Kursabfrage, bemängelt jedoch die Abstufungen. Die Anzeige
  interpoliert deshalb nun entlang der Linie und kennzeichnet die Zwischenwerte.
- Der Test-Tab bietet Demo-Wertpapierauswahl, alle sieben Zeiträume,
  einzelne Schalter für bullische/neutrale/bärische Szenarien und einen
  Zonenschalter. Filter bleiben beim Wechsel erhalten. Ein eigener synthetischer
  Datengenerator bildet die tatsächliche Zeitspanne ab (24 Stunden bis zehn
  Jahre), mit expliziten Zeitstempeln und gemeinsamem Endkurs. Keine echten
  historischen Börsenkurse. Der Test-Chart hat keinen Kartenhintergrund mehr.
- Verlauf, Projektionen, Zonen und Wellenmarkierungen werden gemeinsam
  horizontal transformiert und am Plot begrenzt. Die Euro-Achse bleibt stabil,
  die Zeitbeschriftungen folgen dem sichtbaren historischen Ausschnitt.
- Der produktive chart.dart bleibt unverändert. Der experimentelle Painter
  ist bewusst separat: spätere produktive Übernahme erfordert eine gemeinsame
  Bereinigung, damit die beiden Varianten nicht dauerhaft auseinanderlaufen.
- Grundlage des experimentellen Charts ist der vorhandene lokale Zoom-Entwurf;
  dessen Änderungen an Datenabruf und Wiederherstellung wurden nicht übernommen.
- Änderungen an der bisherigen Navigation beschränken sich auf den Import,
  das zusätzliche Ziel und die zusätzliche Seite. Keine neuen Abhängigkeiten.

## Prüfung

Flutter 3.44.0 / Dart 3.12.0, festgeschriebene pubspec.lock:

- flutter pub get --enforce-lockfile: erfolgreich.
- flutter analyze --no-pub: ohne Befund.
- flutter test --no-pub: 34 Tests erfolgreich (19 bestehende, 15 neue).
- Neue Tests: Fokusverankerung, Zoomgrenzen, Pan-Grenzen, echte Pinch-Geste,
  Neuzeichnung und Filtererhalt, Reset, Zeitraumwechsel, vertikales Scrollen,
  Navigation bei 390 Pixel Breite und unveränderte gespeicherte App-Daten.

Keine Prüfung realer Börsendaten und kein neuer signierter Android-Build.
Vor Übernahme sollte der Testbereich auf einem Android-Gerät mit Zwei-Finger-
Gesten und auf schmalen Geräten manuell geprüft werden. Ein erfolgreicher
Widgettest ersetzt die Geräteabnahme nicht.

## Bestehende Risiken außerhalb dieses PR

EV-017 bleibt teilweise: die vorhandenen Mock-Tests bestätigen technische
Verarbeitung, nicht die tatsächliche Markt-Abdeckung, Lizenz oder Datenqualität.
Die Szenarioprozentwerte sind relative regelbasierte Plausibilitäten, keine
kalibrierten Eintrittswahrscheinlichkeiten. Anbieter-, Referenzdaten- und
Release-Freigaben bleiben gemäß docs/TODO-STATUS.md erforderlich.
