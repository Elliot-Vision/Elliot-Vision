import 'package:flutter/material.dart';
import 'app.dart';
import 'knowledge_data.dart';
import 'knowledge_illustration.dart';

class KnowledgeCard extends StatelessWidget {
  const KnowledgeCard({required this.entry, super.key});
  final KnowledgeEntry entry;

  @override
  Widget build(BuildContext context) => ExpansionTile(
        key: PageStorageKey('knowledge-${entry.id}'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
        title: Text(entry.title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        children: [
          Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.category.toUpperCase(),
                      style: const TextStyle(color: AppPalette.lime)),
                  const SizedBox(height: 10),
                  Text(entry.text, style: const TextStyle(height: 1.5)),
                  const SizedBox(height: 12),
                  Text(entry.explanation, style: const TextStyle(height: 1.5)),
                  if (entry.category == 'Price Action')
                    KnowledgeIllustration(topic: entry.id),
                  const SizedBox(height: 14),
                  const Text('Beispiel',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  Text(entry.example, style: const TextStyle(height: 1.5)),
                  const SizedBox(height: 14),
                  const Text('Einordnung und Grenzen',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  Text(entry.limitation,
                      style: const TextStyle(
                          height: 1.5, color: AppPalette.muted)),
                ],
              )),
        ],
      );
}
