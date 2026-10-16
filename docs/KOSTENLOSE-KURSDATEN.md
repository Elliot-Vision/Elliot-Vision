# Kostenlose Kursdaten: Umfang und Genauigkeit

Nutzerentscheidung vom 16. Oktober 2026: Aktien, ETFs und Kryptowährungen sind
gleich wichtig; zunächst ausschließlich kostenlose Quellen. Verzögerungen sollen
sichtbar sein. Keine Abos, Schlüssel oder kostenpflichtigen Rechte wurden eingerichtet.

## Neu: direkte Krypto-Euro-Kurse

Die Suche nach BTC/Bitcoin, ETH/Ethereum, SOL/Solana, XRP, ADA/Cardano,
LTC/Litecoin, DOGE/Dogecoin oder DOT/Polkadot versucht zuerst das jeweilige
Kraken-Euro-Paar. Auch explizite Schreibweisen wie BTC/EUR werden unterstützt.
API-Fehler führen bei der Suche zur bisherigen, sichtbar benannten Yahoo-Quelle.
Eine bereits gespeicherte Kraken-Position wechselt bei einem Abruffehler nicht
heimlich zu einer anderen Börse; der bisherige Datenstand bleibt erhalten.

- Öffentliche, ausschließlich lesende REST-Endpunkte OHLC und Trades.
- Preis und Zeitstempel stammen aus dem letzten gemeldeten Trade.
- Direkte Euro-Kerzen; keine USD/EUR-Näherung für diese Paare.
- Kurze Zeiträume: 5m, 30m oder 1d; lange Zeiträume: 1wk, auch bei 5 Jahren/Max.
- Kraken liefert höchstens 720 OHLC-Einträge. Max und Extremwerte beziehen sich
  deshalb ausdrücklich auf die verfügbare Wochenhistorie, nicht auf eine
  nachgewiesen vollständige weltweite Handelshistorie.
- Die letzte Kerze ist noch offen. Ein REST-Abruf ist kein Streaming-Abonnement.
- Fehler, unvollständige Daten und ungültige Kerzen werden abgelehnt.

Implementierung: lib/src/kraken_market_data.dart. Manueller, optionaler Abruf:
`dart run tool/check_public_market_data.dart`. Mit BTC/EUR und ETH/EUR am
16. Oktober 2026 erfolgreich gegen die echten öffentlichen Endpunkte geprüft.

Primärquellen:
- [Kraken OHLC](https://docs.kraken.com/api-reference/market-data/get-ohlc-data)
- [Kraken Recent Trades](https://docs.kraken.com/api-reference/market-data/get-recent-trades)

## Aktien und ETFs

Yahoo bleibt die bisherige kostenlose Betatest-Quelle. Es wurde keine bessere,
vollständige kostenlose weltweite Echtzeitversorgung verifiziert. OpenFIGI ordnet
Kennungen zu und wird nicht als Lieferant von Preisen bezeichnet. Die App zeigt
nun Quelle, Börsenplatz, Symbol und Kurszeitpunkt eindeutiger an. Fehlende Zeiten
werden aus datierten Chartwerten abgeleitet, nicht aus dem aktuellen Abrufzeitpunkt.
Ohne datierte Reihe wird ein Abruf verworfen. Unbekannte Verzögerungen bleiben
unbekannt; eine undokumentierte Rohzahl wird nicht in Minuten umgedeutet.

Ausländische historische Kurse werden weiterhin mit einem aktuellen FX-Kurs in
Euro angenähert, nicht mit individuellen historischen Tageswechselkursen. Dieser
Punkt steht nun auch in der Datenansicht. Die zusätzliche Quelle macht Aktien-
und ETF-Kurse somit nicht pauschal genauer oder zu garantierten Echtzeitkursen.

## Geprüfte Alternativen

- [Deutsche Börse: verzögerte Daten](https://www.mds.deutsche-boerse.com/mds-en/real-time-data/Delayed-data):
  öffentliche Daten mit 15 Minuten Verzögerung und begrenztem Bereitstellungsfenster;
  kein einfacher Ersatz für eine globale mehrjährige OHLC-Schnittstelle.
- [Twelve Data: Tarife](https://twelvedata.com/pricing) und
  [EU-Datenherkunft](https://support.twelvedata.com/en/articles/12656239-european-equities-market-data):
  Zugang und Marktumfang sind tarifabhängig; EU-Kurse aus Cboe sind nicht automatisch
  identisch mit einer konkreten Xetra-, Tradegate- oder LS-Notierung.

Diese kosten- oder kontogebundenen Alternativen wurden nicht aktiviert. Für eine
öffentliche kommerzielle App müssen Datenrechte weiterhin gesondert geklärt werden.
