import 'package:flutter_test/flutter_test.dart';
import 'package:elliott_vision/elliott_vision.dart';

void main() {
  test('Alle Wissenseinträge enthalten Erklärung, Beispiel und Grenzen', () {
    for (final entry in knowledgeEntries) {
      expect(entry.explanation.length, greaterThan(100), reason: entry.id);
      expect(entry.example.length, greaterThan(60), reason: entry.id);
      expect(entry.limitation.length, greaterThan(60), reason: entry.id);
    }
    expect(filterKnowledgeEntries('Verlustbudget').map((e) => e.id),
        contains('position-sizing'));
  });

  test('Price Action ist vollständig suchbar und besitzt eindeutige Einträge',
      () {
    final entries = filterKnowledgeEntries('Price Action');
    expect(entries.length, greaterThanOrEqualTo(12));
    expect(knowledgeEntries.map((e) => e.id).toSet().length,
        knowledgeEntries.length);
    for (final query in [
      'OHLC',
      'Doji',
      'Pin Bar',
      'Engulfing',
      'Retest',
      'Modellpreis'
    ]) {
      expect(filterKnowledgeEntries(query), isNotEmpty, reason: query);
    }
  });

  test('Wissensdatenbank filtert Begriffe, Texte und alternative Schreibweisen',
      () {
    expect(knowledgeEntries.length, greaterThanOrEqualTo(35));

    final zigzag = filterKnowledgeEntries('Zigzag');
    expect(zigzag, hasLength(1));
    expect(zigzag.single.id, 'zigzag');

    final baerisch = filterKnowledgeEntries('Uberlappung');
    expect(baerisch.map((entry) => entry.id), contains('overlap'));

    final fibonacci = filterKnowledgeEntries('61,8');
    expect(fibonacci, isNotEmpty);

    expect(
      filterKnowledgeEntries('Aktiensplit').map((entry) => entry.id),
      contains('corporate-actions'),
    );
  });
}
