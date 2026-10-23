import 'package:flutter/rendering.dart' show SemanticsAction, SemanticsNode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/widgets/glossary_text.dart';

import 'helpers.dart';

/// Looking up a word: nothing marks the words that can be looked up; a
/// press and hold lights that word alone and opens its word card, and
/// closing the card puts it back. A tap stays the screen's own (the next
/// story line), a drag its scroll; a word not in the glossary opens nothing.
void main() {
  // Case 01's glossary: "Mysterious" and "museum" are in it, the rest not.
  const line = 'A Mysterious note came from the museum, at night.\nWho wrote it?';

  late int taps;
  late ProviderContainer container;

  Future<void> pump(WidgetTester t, {Size size = const Size(360, 640)}) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    taps = 0;
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(),
      child: MaterialApp(
        home: Scaffold(
          // As a story scene: a tap anywhere is the next line.
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 200),
                GlossaryText(line, episode: episode01, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      ),
    ));
    container = ProviderScope.containerOf(t.element(find.byType(Scaffold)));
    await t.pump();
  }

  List<TextSpan> words(WidgetTester t) {
    final spans = <TextSpan>[];
    t.widget<RichText>(find.byType(RichText).first).text.visitChildren((s) {
      if (s is TextSpan && s.text != null) spans.add(s);
      return true;
    });
    return spans;
  }

  List<String> litWords(WidgetTester t) => [
    for (final s in words(t))
      if (s.style?.backgroundColor != null) s.text!,
  ];

  Finder card() => find.text('WORD CARD');

  /// The middle of [word] in the line, on screen.
  Offset centerOf(String word) {
    final r = find.textRange.ofSubstring(word).evaluate().first;
    final box = r.renderObject
        .getBoxesForSelection(TextSelection(baseOffset: r.textRange.start, extentOffset: r.textRange.end))
        .first
        .toRect();
    return r.renderObject.localToGlobal(box.center);
  }

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('$tag: every word reads plain: no underline, no colour of its own', (t) async {
      await pump(t, size: size);
      for (final s in words(t)) {
        expect(s.style?.decoration, isNull, reason: s.text);
        expect(s.style?.color, isNull, reason: s.text);
      }
      expect(litWords(t), isEmpty);
      expect(t.takeException(), isNull);
    });

    testWidgets('$tag: a tap on a word opens nothing: it is the next line', (t) async {
      await pump(t, size: size);
      await t.tapOnText(find.textRange.ofSubstring('museum'));
      await t.pumpAndSettle();
      expect(card(), findsNothing);
      expect(taps, 1, reason: "the screen's own tap");
      expect(container.read(gameControllerProvider).lookedUpWords, isEmpty);
    });

    testWidgets('$tag: a hold opens the card, that word alone lit, back as it was once closed', (t) async {
      await pump(t, size: size);
      await t.holdOnText(find.textRange.ofSubstring('museum'));
      await t.pumpAndSettle();
      expect(card(), findsOneWidget);
      expect(find.text('= 박물관'), findsOneWidget);
      expect(litWords(t), ['museum'], reason: 'the word alone (not its comma, not the line)');
      expect(taps, 0, reason: 'a hold is not the next line');
      expect(container.read(gameControllerProvider).lookedUpWords, contains('museum'));
      await t.tap(find.text('GOT IT!'));
      await t.pumpAndSettle();
      expect(card(), findsNothing);
      expect(litWords(t), isEmpty, reason: 'restored');
      expect(taps, 0);
    });

    testWidgets('$tag: capitals and a line break: the word is still found', (t) async {
      await pump(t, size: size);
      await t.holdOnText(find.textRange.ofSubstring('Mysterious'));
      await t.pumpAndSettle();
      expect(find.text('Mysterious'), findsOneWidget, reason: 'the card, as written');
      expect(find.text('= 수상한, 이상한'), findsOneWidget);
      expect(litWords(t), ['Mysterious']);
      await t.tap(find.text('GOT IT!'));
      await t.pumpAndSettle();
      // After the line break: a plain word, held, opens nothing.
      await t.holdOnText(find.textRange.ofSubstring('wrote'));
      await t.pumpAndSettle();
      expect(card(), findsNothing, reason: 'not in the glossary: no card, no empty card');
      expect(litWords(t), isEmpty);
      expect(t.takeException(), isNull);
    });

    testWidgets('$tag: two words held at once, or one again and again: one card at a time', (t) async {
      await pump(t, size: size);
      // Two fingers, each on a word, held together.
      final a = await t.startGesture(centerOf('museum'), pointer: 1);
      final b = await t.startGesture(centerOf('Mysterious'), pointer: 2);
      await t.pump(const Duration(milliseconds: 700));
      await a.up();
      await b.up();
      await t.pumpAndSettle();
      expect(card(), findsOneWidget, reason: 'one card, never two stacked');
      expect(litWords(t).length, 1, reason: 'the one word whose card is open');
      await t.tap(find.text('GOT IT!'));
      await t.pumpAndSettle();
      expect(card(), findsNothing);
      expect(litWords(t), isEmpty);
      // The same word, quickly, three times over: a card each time, closed between.
      for (var i = 0; i < 3; i++) {
        await t.holdOnText(find.textRange.ofSubstring('museum'));
        await t.pumpAndSettle();
        expect(card(), findsOneWidget);
        await t.tap(find.text('GOT IT!'));
        await t.pumpAndSettle();
        expect(card(), findsNothing);
      }
      expect(taps, 0);
    });

    testWidgets('$tag: a drag from a word scrolls, it opens nothing', (t) async {
      await pump(t, size: size);
      final scroll = t.state<ScrollableState>(find.byType(Scrollable)).position;
      final g = await t.startGesture(centerOf('museum'));
      for (var i = 0; i < 10; i++) {
        await g.moveBy(const Offset(0, -20));
        await t.pump(const Duration(milliseconds: 80));
      }
      await g.up();
      await t.pumpAndSettle();
      expect(scroll.pixels, greaterThan(0));
      expect(card(), findsNothing);
      expect(litWords(t), isEmpty);
      expect(taps, 0);
    });
  }

  testWidgets('screen readers: a word to look up says so, and holds as an action', (t) async {
    final semantics = t.ensureSemantics();
    await pump(t);
    // The line's words, each its own node: label → whether it holds.
    final holds = <String, bool>{};
    void visit(SemanticsNode n) {
      final d = n.getSemanticsData();
      holds[d.label] = d.hasAction(SemanticsAction.longPress);
      n.visitChildren((c) {
        visit(c);
        return true;
      });
    }

    visit(t.getSemantics(find.byType(RichText).first));
    expect(holds['museum (hold for meaning)'], isTrue);
    expect(holds['Mysterious (hold for meaning)'], isTrue);
    expect(holds[' note came from the '], isFalse, reason: 'plain words: nothing to hold');
    expect(holds.keys.where((l) => l.contains('tap for meaning')), isEmpty);
    semantics.dispose();
  });
}
