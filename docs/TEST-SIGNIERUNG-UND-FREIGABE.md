# Test-Signierung und noch benötigte externe Schritte

## Updatefähige Test-APKs

Der neue Codemagic-Workflow `android-test-signed` verwendet ausschließlich die
Code-Signing-Identität `elliott_vision_test_keystore`. Diese muss einmalig unter
Team settings → Code signing identities → Android keystores hochgeladen werden.
Keystore und Passwörter nicht ins Repository oder in den Chat schreiben.

Nach Einrichtung immer diesen Workflow und denselben Keystore verwenden.
Debug-APKs werden damit ebenfalls fest signiert; Versionscodes steigen mit der
Codemagic-Buildnummer (1000 + BUILD_NUMBER). Die bisherige `android-check`-APK
bleibt ein Build ohne feste Update-Identität und ist kein Ersatz dafür.

Der erste Wechsel von den bisherigen zufälligen Debug-Schlüsseln auf die feste
Test-Identität erfordert eine einmalige Neuinstallation mit entsprechendem
Datenverlust oder eine zuvor geklärte Datensicherung. Künftige Updates benötigen
bei gleichem Paket, gleichem Schlüssel und passendem Versionscode keine erneute
Deinstallation. Die Hinterlegung und ein tatsächlicher signierter Build sind
noch nicht bestätigt.

Quelle: https://docs.codemagic.io/yaml-code-signing/signing-android/

## Unabhängige Datenprüfung (EV-017)

`python tool/validate_reference_data.py export.csv referenz.csv --tolerance 0.01`
vergleicht Zeitpunkte und Währungen, Schlusskurse und optional OHLC-Werte.
CSV-Spalten: `symbol,timestamp,currency,close`, optional `open,high,low`.
Zeitstempel müssen eine Zeitzone enthalten. Quelle, Handelsplatz, Intervall,
FX-Bezug und Split-/Dividendenbereinigung müssen vor einem Vergleich passen.

Ein unabhängiger, rechtmäßig nutzbarer Referenzdatensatz ist weiterhin nötig.
Die automatisierten Tests des Vergleichswerkzeugs ersetzen diese Daten nicht.

## Entscheidungen vor öffentlicher Veröffentlichung

- Marktdatenanbieter mit kommerziellen Nutzungsrechten auswählen und Vertrag klären.
- Referenzquelle und Golden Dataset bereitstellen und den Datenvergleich durchführen.
- Release-Keystore dauerhaft sichern und einen signierten Release-Build prüfen.
- Betreiberangaben für Impressum, Datenschutz und Store-Einreichung bereitstellen;
  tatsächliche Datenflüsse und Risikohinweise prüfen und freigeben.
- Aktuelle App auf Android abnehmen; danach PR-Review und ausdrückliche Merge-Freigabe.

Diese Entscheidungen, Verträge, Zugangsdaten und Geräteprüfungen sind nicht durch
Code allein erledigt und bleiben ausdrücklich offen.
