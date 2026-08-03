# Elliott Vision Flutter App – MVP

Dieses Paket enthält den Flutter-Quellcode für eine Android-App mit:

- Suche nach ISIN, Name und Kürzel
- Favoritenliste
- Depotpositionen mit Kaufdatum, Kaufpreis und Stückzahl
- Euro-Anzeige
- Chart mit Allzeithoch, Allzeittief und drei Prognoseszenarien
- vereinfachter Elliott-Wellen-Heuristik
- lokaler Speicherung auf dem Gerät

## Wichtig

Die enthaltenen Kurse sind reproduzierbare Demo-Daten. Für echte Börsendaten muss `DemoMarketDataService` später durch einen lizenzierten Datenanbieter ersetzt werden. Die Analyse ist keine Anlageberatung.

## Projekt erzeugen und starten

1. Flutter SDK und Android Studio installieren.
2. Einen neuen Ordner öffnen und in diesem Ordner ausführen:

```bash
flutter create --platforms=android .
```

3. Danach die Dateien aus diesem Paket in das Projekt kopieren beziehungsweise vorhandene Dateien überschreiben.
4. Abhängigkeiten laden:

```bash
flutter pub get
```

5. App prüfen:

```bash
flutter analyze
flutter test
```

6. Samsung per USB verbinden, USB-Debugging aktivieren und starten:

```bash
flutter run
```

## APK bauen

```bash
flutter build apk --release
```

Die APK befindet sich anschließend hier:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Diese Datei auf das Samsung-Gerät übertragen und öffnen. Android fragt gegebenenfalls nach der Erlaubnis, Apps aus dieser Quelle zu installieren.

## Nächster technischer Schritt

Für eine reale Version werden benötigt:

- Wertpapier-Stammdaten-Service für ISIN → Symbol/Handelsplatz
- Kursdaten-API mit historischen Tageskursen
- Devisenkurse zur Umrechnung in EUR
- robustere Pivot-/ZigZag-Erkennung und Elliott-Regelprüfung
- verschlüsselte Speicherung sensibler Depotdaten
- Signierung und optional Veröffentlichung im Google Play Store


## Version 0.2 UI Prototype
- minimalistisches helles Finanz-App-Design
- bullisch/neutral/bärisch mit Analyse-Score
- mehrere ein-/ausblendbare Wellenzählungen
- Fibonacci-Ebene
- Analysehistorie
- Wissensbereich/FAQ
