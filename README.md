# Elliott Vision – Android MVP

Elliott Vision ist eine Flutter-App zum transparenten Vergleichen mehrerer
Elliott-Wellen-Szenarien. Dieser Stand ist ein lauffähiger MVP mit lokal
gespeicherten Favoriten, Depotpositionen und Analyse-Snapshots.

## Was im MVP funktioniert

- Suche nach ISIN, Wertpapiername oder Ticker
- Auswahl des Handelsplatzes und des Chart-Zeitraums
- Darstellung von Originalkurs, Euro-Kurs und verwendetem Wechselkurs
- Chart mit historischem Verlauf und gleichzeitig einblendbaren bullischen,
  neutralen und bärischen Szenarien
- Wahrscheinlichkeit, Score, Kursziel und Invalidierungsmarke je Szenario
- Kennzeichnung eines Hauptszenarios
- Favoritenliste
- persönliches Depot mit Kaufdatum, Kaufpreis und Stückzahl
- Analysehistorie als datierter Snapshot
- Speicherung von Datenstand, Analyseversion, Modell- und Promptinformation
- Lernbereich und Risikohinweis
- minimalistisches Finanz-App-Design

## Wichtige MVP-Grenze

Alle Kurse, Wechselkurse und Analysen sind deutlich als **Demo-Daten**
gekennzeichnet. Der MVP beweist Bedienung, Speicherung, Chart-Overlays und
Architektur. Er behauptet keine aktuellen Marktwerte und gibt keine
Anlageberatung.

Der nächste technische Schritt ist die Anbindung eines lizenzierten
Marktdatenanbieters und eines eigenen Backends. Ein OpenAI-API-Schlüssel darf
niemals in die Flutter-App, die APK oder das Git-Repository gelangen. Das
vorgesehene Produktionsdesign steht in [docs/ARCHITEKTUR.md](docs/ARCHITEKTUR.md).

## Projektstruktur

```text
lib/
  main.dart                 App-Start
  src/
    app.dart                Theme und App-Scope
    app_state.dart          Favoriten, Depot und Historie
    models.dart             Domänenmodelle und Snapshots
    demo_data.dart          klar gekennzeichnete Beispieldaten
    analysis_engine.dart    regelbasierter Demo-Analysator
    local_store.dart        lokale Speicherung
    chart.dart              eigener Szenario-Chart
    screens.dart            vollständige MVP-Oberfläche
test/                       Kern- und Widgettests
codemagic.yaml              Cloud-Build der Android-APK
```

## Android-APK mit Codemagic bauen

Das Repository enthält bewusst keine generierten Android-Plattformdateien.
Codemagic erzeugt sie reproduzierbar vor jedem Build.

1. Den Inhalt dieses Projekts in das GitHub-Repository hochladen.
2. Das Repository in Codemagic als Flutter-Projekt auswählen.
3. Codemagic erkennt `codemagic.yaml`.
4. Workflow **Elliott Vision Android MVP** starten.
5. Nach erfolgreichem Build unter **Artifacts**
   `app-release.apk` herunterladen.
6. Die APK auf dem Android-Gerät öffnen und die Installation aus dieser Quelle
   einmalig erlauben.

Der Workflow führt automatisch aus:

```text
flutter create --platforms=android ...
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Zusätzlich wird eine SHA-256-Prüfsumme für die APK erzeugt.

## Lokal starten (optional)

Voraussetzung: aktuelles Flutter-SDK.

```text
flutter create --platforms=android --org de.elliottvision \
  --project-name elliott_vision .
flutter pub get
flutter test
flutter run
```

## Sicherheit

- `.env`, `.env.local`, Keystores und `key.properties` sind ignoriert.
- `.env.example` enthält nur leere Platzhalter.
- Der Flutter-Code liest und enthält keinen OpenAI-API-Schlüssel.
- Spätere OpenAI-Aufrufe laufen ausschließlich über ein eigenes Backend.
- Das Backend validiert strukturierte Analyseantworten gegen ein festes Schema.

## Status

Version: `0.1.2+3`  
Stand: 3. August 2026  
Modus: Android-MVP mit Demo-Daten
