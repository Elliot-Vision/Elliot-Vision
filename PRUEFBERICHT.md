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
11. Unveränderliche Szenario-Snapshots erzwingen die Chart-Neuzeichnung
12. Begrenzter FX-Cache ohne Fehler-Caching und mit manuellem Neuladen
13. OpenFIGI-Wartezeit anhand des dokumentierten `ratelimit-reset`-Headers
14. Handelsplatzbezogene ATH/ATL aus dem Maximalverlauf desselben Symbols
15. Flutter 3.44.0 und vollständige `pubspec.lock` für reproduzierbare Builds
16. Robuster Widget-Testzugriff auf lazy aufgebaute Chart- und Filterelemente
17. Plattformunabhängiger Keystore-Pfad für lokale und Codemagic-Builds

## Vor dem ZIP geprüfte Punkte

- Codemagic-Testfehler vom 4. August 2026 korrigiert: Die Analyseansicht
  enthält sowohl `Kursstand …` als auch `Gespeicherter Kursstand`. Der Test
  adressiert den aktuellen Kurszeitpunkt nun eindeutig über
  `quote-timestamp` und prüft dessen Inhalt separat.
- Codemagic-Testfehler vom 4. August 2026 analysiert: Suchergebnisse und
  Szenariofilter liegen in lazy aufgebauten Listen. Die vorherigen Tests
  erwarteten diese Elemente bereits im Widget-Baum, bevor zu ihnen gescrollt
  wurde.
- Der Navigationstest löst die Suche genau einmal über die echte
  Such-Eingabeaktion aus, wartet den Suchzustand vollständig ab, scrollt die
  Apple-Ergebniskarte sichtbar und prüft anschließend den Seitenwechsel.
- Die beiden Zeitraumtests öffnen die Analyseansicht unabhängig von Suche und
  Navigation. Eindeutige ValueKeys adressieren die Hauptlisten, Handelsplatz,
  Zeitraum und Bullisch-Szenario. Der Test scrollt nun auch den Chart selbst
  wieder in den Widget-Baum, bevor dessen Painter gelesen wird. Damit kann ein
  von der lazy `ListView` entsorgtes Element nicht mehr über
  `tester.widget(...).single` den Fehler `Bad state: No element` auslösen.
- Windows-Keystore-Pfade werden vor dem Schreiben von `key.properties` auf
  Vorwärtsslashe normalisiert. Dadurch interpretiert Java Properties keine
  Backslash-Sequenzen mehr als Escape-Zeichen und Gradle findet den Schlüssel
  auf Windows ebenso wie auf macOS/Linux.
- 20 Dart-Dateien durch strukturelle Syntax- und Klammerprüfung validiert
- `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml` und `codemagic.yaml`
  geprüft; die Codemagic-Workflows referenzieren Flutter 3.44.0 und Java 17
- 19 automatisierte Unit- und Widgettests vorhanden; neue Regressionstests
  decken Chart-Neuzeichnung, FX-Ablauf/Fehler, OpenFIGI-Reset,
  handelsplatzbezogene Extremwerte und Backup-Wiederherstellung ab
- zwei Python-Regressionstests für vollständige Signierungsvariablen und die
  Windows-Pfadnormalisierung ergänzt und in beide Codemagic-Builds eingebunden
- alle gehosteten Lockdatei-Einträge enthalten feste Versionen und
  SHA-256-Prüfsummen; Codemagic verwendet `--enforce-lockfile`
- Android-Konfigurationsskript syntaktisch geprüft und zweimal nacheinander
  erfolgreich auf eine Flutter-Kotlin-Teststruktur angewandt
- Repository-Vollständigkeit und Ausschluss eingebetteter Schlüssel geprüft
- mit dem in Codemagic festgelegten Flutter 3.44.0 / Dart 3.12.0 ausgeführt:
  `flutter pub get --enforce-lockfile`, `flutter analyze` ohne Befund und alle
  19 Flutter-Tests erfolgreich
- Android-Debug-APK real gebaut
- Release-APK und Release-AAB mit einem nur für die lokale Prüfung erzeugten,
  temporären Testschlüssel erfolgreich gebaut; der produktive Schlüssel bleibt
  ausschließlich in Codemagic und der Offline-Sicherung
