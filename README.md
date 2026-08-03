# Elliott Vision – Android Beta

Elliott Vision ist eine Flutter-App zum transparenten Vergleichen mehrerer
Elliott-Wellen-Szenarien. Dieser Stand ist eine lauffähige Android-Beta mit
Online-Wertpapiersuche, aktualisierbaren Depotkursen sowie lokal gespeicherten
Favoriten, Depotpositionen und Analyse-Snapshots.

## Was in der Beta funktioniert

- Suche nach ISIN, Wertpapiername oder Ticker
- Online-Auflösung von ISINs und Abruf aktueller beziehungsweise verzögerter
  Börsenkurse
- Auswahl des Handelsplatzes und des Chart-Zeitraums
- Darstellung von Originalkurs, Euro-Kurs und verwendetem Wechselkurs
- Kurszeitpunkt direkt unter dem Originalkurs
- Chart mit historischem Verlauf und gleichzeitig einblendbaren bullischen,
  neutralen und bärischen Szenarien
- Wahrscheinlichkeit, Score, Kursziel und Invalidierungsmarke je Szenario
- Kennzeichnung eines Hauptszenarios
- Favoritenliste
- persönliches Depot mit Kaufdatum, Kaufpreis und Stückzahl
- eigene Online-Suche nach Name, Ticker oder ISIN beim Hinzufügen einer Position
- automatische Depot-Aktualisierung beim Start sowie manuelle Aktualisierung
- lokaler Kurscache mit sichtbarem Datenzeitpunkt bei Netzwerkproblemen
- Analysehistorie als datierter Snapshot
- Speicherung von Datenstand, Analyseversion, Modell- und Promptinformation
- durchsuchbare Wissensdatenbank mit mehr als 20 Elliott-Wellen-, Marktstruktur-
  und Risikobegriffen sowie Risikohinweis
- minimalistisches Finanz-App-Design im durchgängigen Dark Mode

## Wichtige Beta-Grenze

Die persönliche Beta ruft Wertpapierzuordnungen und aktuelle beziehungsweise
je nach Handelsplatz verzögerte Kurse über öffentlich erreichbare Endpunkte ab.
Der Datenstand wird in der App angezeigt und der letzte erfolgreiche Abruf
lokal gespeichert. Die Elliott-Szenarien stammen weiterhin aus dem lokalen
regelbasierten Beta-Analysator und sind keine Anlageberatung.

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
    demo_data.dart          Migration/Fallback für bestehende Testpositionen
    live_market_data.dart   Online-Suche, ISIN-Zuordnung, Kurse und FX
    knowledge_data.dart     durchsuchbare Elliott-Wellen-Wissensdatenbank
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

### Bestehende Test-App aktualisieren

Die neue APK zuerst direkt über die installierte Test-App installieren. Falls
Android wegen einer abweichenden Signatur nicht aktualisiert, die bisherigen
Depotpositionen vorher notieren, die alte Test-App einmalig deinstallieren und
anschließend Version 0.2 installieren. Beim Deinstallieren werden die bislang
lokal gespeicherten Testdaten gelöscht.

Für alle späteren Updates muss in Codemagic ein dauerhaft gesicherter Android-
Keystore hinterlegt werden. Dieser private Schlüssel gehört niemals in Git oder
in das Projekt-ZIP.

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

Version: `0.3.0+5`  
Stand: 3. August 2026  
Modus: persönliche Android-Beta mit Online-Marktdaten, Depotsuche,
Wissensdatenbank und Dark Mode
