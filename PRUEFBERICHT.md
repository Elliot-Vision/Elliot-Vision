# Prüfbericht Elliott Vision 0.4.1+7

Stand: 4. August 2026

## Korrigierte Abnahmepunkte

1. Pivot-basierte Elliott-Analyse statt fest vorgegebener Zählungen
2. Tatsächliches Neuladen beim Handelsplatzwechsel
3. ISIN-Prüfziffer und exakte OpenFIGI-Zuordnung vor Kursabruf
4. Konsistenter Zeitraum bei fehlgeschlagenem Abruf
5. Erhalt der ein-/ausgeblendeten Szenarien bei Ansichtswechseln
6. Ein-, Ausstiegs- und Stop-Loss-Zonen für alle sichtbaren Szenarien
7. ATH/ATL aus Periodenhochs und -tiefs statt nur Schlusskursen
8. Atomare Datendatei mit Backup, Migration und Historienlimit
9. Begrenzter Retry/Backoff für OpenFIGI-Rate-Limits
10. Fester Codemagic-Keystore-Verweis für updatefähige Releases

## Vor dem ZIP geprüfte Punkte

- Codemagic-Testfehler vom 4. August 2026 analysiert: Die drei betroffenen
  Widget-Tests warteten die 450-ms-Suchentprellung nicht zuverlässig ab und
  berücksichtigten die begrenzte Testfensterhöhe nicht.
- Gemeinsamer Navigationshelfer wartet nun explizit auf die Suche, scrollt die
  Apple-Ergebniskarte sichtbar und prüft den erfolgreichen Seitenwechsel.
- Eindeutige ValueKeys für Entdecken-Suche und Instrumentkarten ergänzt.
- 20 Dart-Dateien mit aktueller Dart-Tree-sitter-Grammatik ohne Syntaxfehler
- `pubspec.yaml`, `analysis_options.yaml` und `codemagic.yaml` erfolgreich
  geparst
- 17 automatisierte Unit- und Widgettests vorhanden
- Android-Konfigurationsskript syntaktisch geprüft und zweimal nacheinander
  erfolgreich auf eine Flutter-Kotlin-Teststruktur angewandt
- Repository-Vollständigkeit und Ausschluss eingebetteter Schlüssel geprüft

`flutter analyze`, `flutter test` und der echte Android-Build benötigen das
Flutter-/Android-SDK. Sie sind deshalb als zwingende, abbrechende Schritte im
Codemagic-Workflow **1 - Code prüfen** und im signierten Releaseworkflow
eingebaut. Ein Artifact wird nur erzeugt, wenn diese Prüfungen erfolgreich sind.
