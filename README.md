# Elliott Vision – Android Beta 0.4.1

Elliott Vision ist eine Flutter-App zum transparenten Vergleichen mehrerer
Elliott-Wellen-Szenarien. Version 0.4.1 korrigiert die technische Abnahme von
0.4.0+6 und ist für den Upload nach GitHub sowie den Build mit Codemagic
vorbereitet.

## Funktionen

- Online-Suche nach Name, Ticker und ISIN sowie Filter für Aktie, ETF und Krypto
- Originalkurs, Euro-Umrechnung, Kurszeitpunkt, Verzögerung und Handelsplatz
- sieben Chart-Zeiträume mit neu geladenen 5-Minuten- bis Monatsdaten
- beschriftete X-/Y-Achsen, ATH/ATL-Abstände und aktueller Kurs
- adaptive ZigZag-Wendepunkterkennung und explizite Elliott-Regelprüfung
- historische Wellenmarker sowie überlagerbare bullische, neutrale und
  bärische Zählungen
- Haupt- und Alternativszenarien mit Prozentwert, Score und Faktoren
- Einstieg, Ausstieg, Ziel, Stop-Loss, Invalidierung und Chance/Risiko
- drei Informationsebenen: Kompakt, Standard und Experte
- Favoriten und Depot mit eigener Suche, Kaufdatum, Kaufpreis und Stückzahl
- aktueller Depotwert sowie Gewinn/Verlust in Euro und Prozent
- Depotwerte und Favoriten direkt analysierbar
- automatische Aktualisierung beim Start, Aktualisieren-Button und Pull-to-refresh
- vollständige Analyse-Snapshots mit damaligem Instrument- und Kursstand
- durchsuchbare Wissensdatenbank mit mindestens 35 Begriffen
- durchgängiger Dark Mode im minimalistischen Finanz-App-Design
- atomare lokale Datendatei mit Sicherung und Migration der bisherigen Daten
- feste, außerhalb von GitHub verwaltete Android-Release-Signierung
- reproduzierbarer Codemagic-Build mit Flutter 3.44.0 und eingecheckter
  Abhängigkeits-Lockdatei

## Transparenz und Grenzen

Die Prozentwerte sind normalisierte Plausibilitäts-Scores eines lokalen,
deterministischen Regelwerks. Sie sind keine garantierten statistischen
Wahrscheinlichkeiten und keine Anlageberatung. Die App nutzt kein LLM und
enthält keinen API-Schlüssel.

Die persönliche Beta nutzt öffentlich erreichbare Datenendpunkte. Quelle,
Zeitstempel und Verzögerung bleiben sichtbar; bei Ausfällen greift die App auf
den letzten gespeicherten Stand zurück. Details stehen in
[`docs/DATENQUELLEN.md`](docs/DATENQUELLEN.md). Für einen öffentlichen Release
ist ein lizenzierter Marktdatenanbieter erforderlich.

## Projektstruktur

```text
lib/
  main.dart
  src/
    analysis_engine.dart    Pivot-Erkennung, Elliott-Regeln und Szenarien
    app.dart                Dark-Mode-Theme und App-Scope
    app_state.dart          Suche, Depot, Favoriten und Historie
    chart.dart              Zeit-/Kursachsen und Szenario-Overlays
    demo_data.dart          Repository-Vertrag und Offline-Testdaten
    knowledge_data.dart     durchsuchbare Wissensdatenbank
    live_market_data.dart   Suche, ISIN, Kurse, Zeitreihen und FX
    local_store.dart        atomare Persistenz, Sicherung und Migration
    models.dart             Asset-, Kurs-, Szenario- und Snapshotmodelle
    screens.dart            vollständige Oberfläche
test/                       automatisierte Kern- und Widgettests
docs/                       Architektur, Datenquellen und Umsetzungsstatus
tool/                       reproduzierbare Android-/Signierkonfiguration
codemagic.yaml              Test-, Schlüssel- und Release-Workflows
pubspec.lock                festgeschriebene Paketversionen und Prüfsummen
```

## Android-APK mit Codemagic bauen

Die vollständige Schritt-für-Schritt-Anleitung steht in
[`GITHUB-CODEMAGIC-ANLEITUNG.md`](GITHUB-CODEMAGIC-ANLEITUNG.md). Zuerst läuft
der Workflow **1 - Code prüfen**, danach wird einmalig ein fester privater
Signierschlüssel eingerichtet und künftig **3 - Signiertes Android-Release**
verwendet.

## Sicherheit und Updates

- Die App benötigt keine `.env`-Datei und keine eingebetteten API-Schlüssel.
- Niemals einen API-Schlüssel in Flutter-Code, APK oder GitHub speichern.
- Der private Android-Keystore wird nur in Codemagic hinterlegt und zusätzlich
  offline gesichert; er gehört niemals in das Repository.

Version: `0.4.1+7`  
Stand: 4. August 2026  
Modus: persönliche Android-Beta
