import 'package:flutter_test/flutter_test.dart';
import 'package:elliott_vision/elliott_vision.dart';

void main() {
  test('Wissensdatenbank filtert Begriffe, Texte und alternative Schreibweisen', () {
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
