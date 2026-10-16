# Price Action: Wissensumfang und Quellen

Die Kategorie „Price Action“ ergänzt zwölf eigenständig formulierte Einträge in
der Wissenssuche. Musterbeschreibungen erklären die Darstellung; Begriffe wie
Engulfing, Rücktest und Volumen sind Bildungsinhalte und keine Behauptung, die App
würde diese bereits automatisch erkennen oder daraus Orders erzeugen.

Fachliche Referenzen, geprüft am 16. Oktober 2026:

- [StockCharts: Introduction to Candlesticks](https://chartschool.stockcharts.com/table-of-contents/chart-analysis/candlestick-charts/introduction-to-candlesticks)
  — OHLC, Körper, Dochte, kleine Körper und Doji.
- [StockCharts: Candlestick Bullish Reversal Patterns](https://chartschool.stockcharts.com/table-of-contents/chart-analysis/candlestick-charts/candlestick-bullish-reversal-patterns)
  — Engulfing und Bedeutung des vorherigen Trends sowie Bestätigung.
- [Charles Schwab: Support and Resistance](https://www.schwab.com/learn/story/use-support-and-resistance-to-read-stock-charts)
  — Kurszonen, Durchbrüche und möglicher Rollentausch.
- [Charles Schwab: Stock Charts and Trading Patterns](https://www.schwab.com/learn/story/how-to-read-stock-charts-and-trading-patterns)
  — Trend, Struktur und Kontext von Mustern.

Die 10-Prozent-Schwelle für Doji-ähnliche Körper stammt aus der bestehenden
vereinfachten App-Auswertung, nicht aus einer universellen Definition.

Projektionsabfragen verwenden exakt die gezeichneten Szenariostützpunkte,
einschließlich des aktuellen Referenzkurses als Start. Zwischen Punkten wird linear
interpoliert. Die horizontale Position wird als Modellschritt bezeichnet, weil
die Szenarien keine kalibrierten Zukunftszeitstempel enthalten. Historische Werte,
Anbieter-OHLC und synthetische Testreihen bleiben entsprechend getrennt.
