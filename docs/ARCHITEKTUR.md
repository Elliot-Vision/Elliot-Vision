# Elliott Vision – Zielarchitektur

## Grundsatz

Die mobile App visualisiert Daten und verwaltet den lokalen Nutzerzustand. Sie
berechnet keine vermeintlich aktuellen Kurse aus freien Texten und enthält keine
geheimen Zugangsdaten.

## Persönliche Beta 0.2

Bis das vorgesehene Backend bereitgestellt ist, verwendet die persönliche Beta
öffentlich erreichbare Marktdaten-Endpunkte ohne eingebettete Zugangsdaten.
OpenFIGI dient als Fallback zur ISIN-Zuordnung. Kurse, Zeitreihen und
Devisenkurse werden online geladen, in Euro umgerechnet und zusammen mit dem
Datenzeitpunkt lokal zwischengespeichert. Bei einem Ausfall zeigt die App den
letzten gespeicherten Stand ausdrücklich als solchen an.

Diese Übergangslösung ersetzt nicht die unten beschriebene Produktionsarchitektur
mit lizenziertem Datenanbieter, Authentifizierung und serverseitigen Rate Limits.

```text
Flutter-App
    |
    | HTTPS + App-Authentifizierung
    v
Elliott-Vision-Backend
    |-- Marktdatenanbieter und Devisenkurse
    |-- Pivot-Erkennung und Elliott-Regelwerk
    |-- statistischer Szenario-Score
    |-- OpenAI Responses API für strukturierte Erklärung
    `-- Snapshot-Datenbank
```

## Verantwortlichkeiten

### Flutter-App

- ISIN-, Namens- und Tickersuche
- Auswahl von Handelsplatz und Zeitraum
- Chart-Rendering und ein-/ausblendbare Szenarien
- Favoriten und Depot
- Historienansicht
- keine API-Schlüssel

### Marktdaten-Schicht

- eindeutige Zuordnung von ISIN, Ticker und Handelsplatz
- Originalkurs und vollständige Zeitreihe
- Devisenkurs für die Euro-Umrechnung
- Datenquelle, Datenstand und Lizenzinformation
- ATH/ATL nur bei ausreichend vollständiger Historie

### Regelbasierte Analyse

- Glättung und Pivot-Erkennung
- Erzeugung regelkonformer Impuls- und Korrekturvarianten
- Fibonacci-Verhältnisse
- Kursziele und eindeutige Invalidierung je Variante
- nachvollziehbarer Score aus dokumentierten Faktoren

### LLM-Erklärung

Das LLM erhält ausschließlich geprüfte Marktdaten und vorvalidierte Szenarien.
Es erzeugt keine Kurse und keine eigenständige freie Chart-Zählung. Die Antwort
wird mit Structured Outputs gegen ein JSON-Schema validiert.

Das Backend speichert je Snapshot:

- Instrument, ISIN und Handelsplatz
- Datenquelle und Datenzeitpunkt
- Originalwährung, Euro-Kurs und Wechselkurs
- alle Szenarien mit Wahrscheinlichkeit, Ziel und Invalidierung
- Regelwerk- und Score-Version
- LLM-Anbieter, Modellversion und Prompt-Version

OpenAI empfiehlt, API-Schlüssel niemals in Browsern oder mobilen Apps
auszuliefern, sondern Anfragen über ein eigenes Backend zu führen:
[Best Practices for API Key Safety](https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety).
Für die maschinenlesbare Erklärung soll das Backend Structured Outputs statt
freiem JSON verwenden:
[Structured model outputs](https://developers.openai.com/api/docs/guides/structured-outputs).

## Vorgesehener API-Vertrag

```json
{
  "instrument": {
    "isin": "US9168961038",
    "ticker": "UEC",
    "venue": "NYSE American",
    "currency": "USD"
  },
  "data": {
    "timestamp": "2026-08-03T10:00:00Z",
    "originalPrice": 9.96,
    "euroPrice": 9.14,
    "fxRate": 0.9177,
    "source": "provider-id"
  },
  "analysis": {
    "primaryScenarioId": "bullish",
    "overallScore": 72,
    "scenarios": [
      {
        "id": "bullish",
        "kind": "bullish",
        "probability": 48,
        "targetEuro": 12.25,
        "invalidationEuro": 7.49,
        "explanation": "..."
      }
    ],
    "engineVersion": "rules-v1",
    "model": "configured-server-side",
    "promptVersion": "explain-v1"
  }
}
```

## Produktionsschritte nach dem MVP

1. Marktdatenanbieter auswählen und Lizenzbedingungen prüfen.
2. Backend mit Authentifizierung, Rate Limits und Budgetgrenzen bereitstellen.
3. Regelwerk mit historischen Testfällen und Golden Datasets evaluieren.
4. OpenAI-Erklärungen als strikt strukturierte Ausgabe anbinden.
5. Snapshot-Speicherung und Nutzer-Synchronisierung ergänzen.
6. Datenschutz, Impressum, Risikohinweise und Store-Anforderungen prüfen.
7. Geschlossenen Beta-Test durchführen, bevor Live-Daten öffentlich werden.
