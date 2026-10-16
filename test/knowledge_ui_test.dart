import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:elliott_vision/src/app.dart' show AppPalette;
import 'package:flutter_test/flutter_test.dart';
import 'package:elliott_vision/src/knowledge_card.dart';
import 'package:elliott_vision/src/knowledge_data.dart';
import 'package:elliott_vision/src/knowledge_illustration.dart';

void main() {
  testWidgets(
      'Wissen zeigt nur Überschrift und öffnet Text und Bild per Berührung',
      (tester) async {
    final entry = knowledgeEntries.firstWhere((e) => e.id == 'pa-ohlc');
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(child: KnowledgeCard(entry: entry)))));
    expect(find.text(entry.title), findsOneWidget);
    expect(find.text(entry.text), findsNothing);
    expect(find.byType(KnowledgeIllustration), findsNothing);
    await tester.tap(find.text(entry.title));
    await tester.pumpAndSettle();
    expect(find.text(entry.text), findsOneWidget);
    expect(find.text(entry.explanation), findsOneWidget);
    expect(find.byType(KnowledgeIllustration), findsOneWidget);
    await tester.ensureVisible(find.text(entry.title));
    await tester.tap(find.text(entry.title));
    await tester.pumpAndSettle();
    expect(find.text(entry.text), findsNothing);
  });

  testWidgets('Alle Price-Action-Lehrbilder passen auf ein schmales Display',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fontPath = Platform.environment['KNOWLEDGE_FONT_PATH'];
    if (fontPath != null) {
      await tester.runAsync(() async {
        final loader = FontLoader('Roboto')
          ..addFont(File(fontPath)
              .readAsBytes()
              .then((bytes) => ByteData.sublistView(bytes)));
        await loader.load();
      });
    }
    for (final entry
        in knowledgeEntries.where((e) => e.category == 'Price Action')) {
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark()
              .copyWith(scaffoldBackgroundColor: AppPalette.background),
          home: Scaffold(
              body: RepaintBoundary(
            key: boundaryKey,
            child: ColoredBox(
                color: AppPalette.background,
                child: DefaultTextStyle(
                    style: const TextStyle(
                        color: AppPalette.ink,
                        fontFamily: 'Roboto',
                        fontSize: 14),
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.title),
                              KnowledgeIllustration(topic: entry.id),
                            ])))),
          ))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: entry.id);
      if (Platform.environment['WRITE_KNOWLEDGE_PREVIEW'] == '1') {
        await tester.runAsync(() async {
          final boundary = boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('../knowledge-previews/${entry.id}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(png!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
  });
}
