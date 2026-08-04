# GitHub- und Codemagic-Anleitung

## 1. Projekt nach GitHub laden

1. Dieses ZIP entpacken.
2. Im GitHub-Repository **Add file → Upload files** öffnen.
3. Den **Inhalt** des entpackten Ordners hochladen, nicht den Ordner selbst.
4. Vorhandene Dateien mit denselben Namen ersetzen und committen.

`pubspec.yaml`, `pubspec.lock`, `codemagic.yaml`, `lib`, `test`, `tool` und
`docs` müssen direkt im Stamm des Repositorys liegen. `pubspec.lock` darf nicht
fehlen: Codemagic verwendet exakt Flutter 3.44.0 und lehnt einen Build mit
abweichenden oder unvollständigen Abhängigkeiten ab. `.env.example` wird für den Build nicht
benötigt. Falls der Android-Dateidialog `.gitignore` nicht anzeigt, darf diese
eine Datei fehlen; der Codemagic-Build funktioniert trotzdem.

## 2. Ersten technischen Test starten

1. Das Repository in Codemagic öffnen beziehungsweise aktualisieren.
2. Workflow **1 - Code prüfen (ohne Release-Key)** starten.
3. Nur wenn Analyse, Tests und Test-APK grün sind, mit der Signierung fortfahren.

## 3. Festen Signierschlüssel einmalig erzeugen

In Codemagic eine geschützte Variablengruppe
`elliott_vision_key_generation` mit vier Variablen anlegen:

| Variable | Beispiel/Bedeutung |
| --- | --- |
| `KEYSTORE_PASSWORD` | ein langes, nur dir bekanntes Passwort |
| `KEY_PASSWORD` | ein langes, nur dir bekanntes Passwort |
| `KEY_ALIAS` | `elliottvision` |
| `KEY_DNAME` | `CN=Elliott Vision, O=Elliott Vision, C=DE` |

Danach Workflow **2 - Signierschlüssel einmalig erzeugen** starten und das
Artifact `elliott-vision-upload.jks` herunterladen. Die JKS-Datei und beide
Passwörter dauerhaft außerhalb von GitHub sichern. Ohne genau diesen Schlüssel
können spätere Versionen nicht als Update über dieselbe App installiert werden.

## 4. Schlüssel in Codemagic hinterlegen

1. **Team settings → codemagic.yaml settings → Code signing identities** öffnen.
2. Unter **Android keystores** die JKS-Datei hochladen.
3. Keystore-Passwort, Alias und Key-Passwort eintragen.
4. Als Reference name exakt `elliott_vision_keystore` verwenden.

Referenz: [Codemagic – Android code signing](https://docs.codemagic.io/yaml-code-signing/signing-android/)

## 5. Signiertes Update bauen

Workflow **3 - Signiertes Android-Release** starten. Nach erfolgreichem Build
liegen unter Artifacts:

- `app-release.apk` für die direkte Installation,
- `app-release.aab` für Google Play,
- je eine SHA-256-Prüfsummendatei.

Wichtig: Wurde eine ältere Beta mit einem anderen oder nur temporären
Debug-Schlüssel signiert, lässt Android das erste fest signierte Release nicht
darüber installieren. Dann ist einmalig eine Deinstallation der alten Beta
nötig. Ab Version `0.4.1+7` bleiben Updates möglich, solange immer derselbe
gesicherte Keystore verwendet wird.

Referenz: [Flutter – Android-App signieren und veröffentlichen](https://docs.flutter.dev/deployment/android)
