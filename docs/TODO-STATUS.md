# Elliott Vision – Umsetzungsstatus der zentralen To-do-Liste

Stand: Version 0.4.1+7

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
- X-Achse mit Datum/Uhrzeit und Y-Achse mit Euro-Kurs
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
- drei Informationsebenen: Kompakt, Standard und Experte

## Extern vor einer öffentlichen Produktionsversion erforderlich

- Vertrag und Lizenz für einen kommerziell nutzbaren Marktdatenanbieter
- unabhängige Referenzquelle und Golden Dataset für automatisierte Datenchecks
- dauerhaft gesicherter Android-Release-Keystore in Codemagic
- Datenschutz-, Impressums-, Risiko- und Store-Prüfung

Diese Punkte benötigen Anbieter-, Rechts- oder Kontoinhaberentscheidungen und
können nicht allein durch App-Code abgeschlossen werden.
