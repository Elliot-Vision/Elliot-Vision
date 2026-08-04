# Elliott Vision – Datenquellen und Qualität

Stand: 4. August 2026 · App-Version 0.4.1

## In der persönlichen Beta verwendete Quellen

| Zweck | Quelle / Endpunkt | Verwendung |
| --- | --- | --- |
| Suche nach Name und Ticker | Yahoo-Finance-Suche `/v1/finance/search` | Kandidaten für Aktien, ETFs und Kryptowährungen |
| Kurs, Historie und Kapitalmaßnahmen | Yahoo-Finance-Chart `/v8/finance/chart/{symbol}` | Originalkurs, Zeitstempel, angepasste Schlusskurse sowie Hochs/Tiefs, Splits und Dividendenereignisse |
| ISIN-Zuordnung | OpenFIGI `/v3/mapping` | ISIN wird auf handelbares Symbol und Börsenplatz abgebildet |
| Namens-Fallback | OpenFIGI `/v3/search` | Fallback, wenn die primäre Namenssuche keinen Treffer liefert |
| Devisenkurs | Yahoo-Finance-Chart für `{Währung}EUR=X` | Umrechnung von Originalwährung in Euro |

Die App enthält keinen API-Schlüssel. Der jeweilige Kurszeitpunkt, die Quelle,
die vom Anbieter gemeldete Verzögerung, die Originalwährung und der verwendete
Euro-Wechselkurs werden in der Expertenansicht angezeigt.

## Abdeckung

- Aktien und ETFs: Suche nach Name, Ticker und – nach Prüfzifferkontrolle exakt
  über OpenFIGI – ISIN. Ein unscharfer Yahoo-Treffer wird nicht als
  ISIN-Bestätigung verwendet.
- Kryptowährungen: Suche nach Name oder Ticker; eine ISIN existiert gewöhnlich
  nicht. Der 24/7-Handel wird sichtbar gekennzeichnet.
- Handelsplätze: Es werden nur Plätze angeboten, für die beim Abruf ein
  konkretes Kurssymbol bestätigt wurde. Beim Wechsel werden Kurs, Währung,
  Zeitreihe, Zeitstempel, ATH/ATL und Analyse neu geladen. Extremwerte
  verschiedener Handelsplätze werden nicht zusammengeführt.
- Historie: 1 Tag, 5 Tage, 1 Monat, 3 Monate, 1 Jahr, 5 Jahre und maximal
  verfügbar. Die Intervalle reichen von 5 Minuten bis 1 Monat.
- Währungen: Kurse werden mit einem separat abgerufenen Devisenkurs in Euro
  umgerechnet. Erfolgreiche FX-Kurse werden höchstens fünf Minuten verwendet;
  fehlgeschlagene Abfragen werden nicht zwischengespeichert. Eine manuelle
  Kursaktualisierung lädt den FX-Kurs sofort neu. Britische Pence werden vor
  der FX-Umrechnung skaliert.
- Kapitalmaßnahmen: Nach Möglichkeit wird `adjusted close` genutzt; der Abruf
  fordert zusätzlich Split- und Dividendenereignisse an.

## Plausibilitäts- und Referenzkontrollen

Die Beta prüft vor der Anzeige:

1. Suchtreffer besitzen ein unterstütztes Asset-Segment und ein Symbol.
2. Kursreihe und aktueller Kurs sind positiv und endlich.
3. Zeitstempel und Kurswerte werden indexgleich gekoppelt; fehlende Werte werden
   verworfen.
4. Originalkurs, Zeitreihenende und Euro-Umrechnung werden gemeinsam geladen.
5. ATH und ATL werden je Symbol und Handelsplatz aus angepassten
   Periodenhochs und -tiefs des maximal verfügbaren Verlaufs berechnet. Ein
   kurzer Chart-Zeitraum erhält dafür einen getrennten Maximalabruf.
6. Bei einem fehlgeschlagenen Einzelabruf bleibt der letzte erfolgreiche lokale
   Datenstand erhalten und wird ausdrücklich als Fallback angezeigt.

Eine unabhängige Zweitquelle ist in der persönlichen Beta nicht eingebettet.
Vor einer öffentlichen Veröffentlichung muss ein lizenzierter Anbieter mit
vertraglich geklärter Echtzeitabdeckung gewählt und gegen ein festes Golden
Dataset sowie stichprobenartig gegen die jeweilige Primärbörse geprüft werden.

## Aktualisierung

- Beim App-Start werden Favoriten und Depotpositionen automatisch aktualisiert.
- Im Depot gibt es einen Aktualisieren-Button und Pull-to-refresh.
- Favoriten, Suche und Analyseseite unterstützen ebenfalls Pull-to-refresh.
- Intraday- und Historienintervalle werden beim Wechsel des Chart-Zeitraums neu
  abgerufen.
- Der letzte erfolgreiche Kursstand wird lokal gespeichert.

## Fehler- und Fallback-Verhalten

- Fällt eine Suche aus, erscheint eine verständliche Fehlermeldung mit
  Wiederholen-Aktion.
- Fällt ein Kursabruf aus, bleiben gespeicherte Werte sichtbar; Quelle und alter
  Zeitstempel werden nicht überschrieben.
- Schlägt nur ein Depotwert fehl, werden die übrigen Positionen weiter
  aktualisiert.
- Ungültige oder leere Kursreihen werden nicht analysiert.
- HTTP 429 berücksichtigt das von OpenFIGI gemeldete `ratelimit-reset`-Fenster;
  vorübergehende Serverfehler verwenden einen begrenzten exponentiellen
  Backoff. Danach erscheint ein klarer Hinweis auf das Rate-Limit.

## Lizenzstatus

Yahoo Finance und OpenFIGI werden hier als technische Übergangslösung für die
persönliche Beta verwendet. Dieses Projekt behauptet keine Lizenz zur
öffentlichen oder kommerziellen Weiterverteilung der Daten. Vor Store-Release
oder Mehrnutzerbetrieb sind Anbieterwahl, Vertrag, Attribution,
Weiterverteilungsrechte, Echtzeitstatus, Rate Limits und Datenschutz verbindlich
zu klären. Der Produktionspfad ist in `ARCHITEKTUR.md` beschrieben.
