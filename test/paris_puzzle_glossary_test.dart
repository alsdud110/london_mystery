import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/data/mock/season_catalog.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/mission/widgets/post_trail.dart';
import 'package:london_mystery/features/mission/widgets/river_papers.dart';

import 'helpers.dart';

/// Paris Cases 03–05: the papers read inside the puzzles (the ledger, the
/// slips) have their harder words to look up, and holding a word opens its
/// word card without doing the puzzle's own tap (circling a box, picking a
/// slip).
void main() {
  final inGame = MockEpisodeRepository.bundled();
  final case04 = inGame.firstWhere((e) => e.id == 's2_ep04');
  final case05 = inGame.firstWhere((e) => e.id == 's2_ep05');

  Future<void> pump(WidgetTester t, Widget child, {required String caseId}) async {
    t.view.physicalSize = const Size(390, 844) * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final episode = caseId == case04.id ? case04 : case05;
    await t.pumpWidget(ProviderScope(
      overrides: [...await testOverrides(), currentEpisodeProvider.overrideWithValue(episode)],
      child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
    ));
    await t.pumpAndSettle();
  }

  testWidgets('the ledger: a word opens its meaning; a box number still circles the box', (t) async {
    final hut = SeasonCatalog.keeperHut(case04.missions[1])!;
    final circled = <String>[];
    await pump(t, LedgerPageView(scene: hut, page: 0, onBox: circled.add, words: true), caseId: case04.id);

    // A word of the ledger, dotted: its card opens, no box is circled.
    final crate = findReadableContaining('A heavy crate');
    expect(crate, findsOneWidget);
    await t.tap(find.byKey(const ValueKey('ledger-0-3-box17')));
    await t.pumpAndSettle();
    expect(circled, ['box17'], reason: 'the box number keeps its own tap');

    expect(holdOnWord(t, crate, 'crate'), isTrue);
    await t.pumpAndSettle();
    expect(find.text('WORD CARD'), findsOneWidget);
    expect(find.text('= ${case04.meaningOf('crate')}'), findsOneWidget);
    expect(circled, ['box17'], reason: 'a word is not a box');
  });

  testWidgets('the ledger as a small picture (evidence): no dotted words', (t) async {
    final hut = SeasonCatalog.keeperHut(case04.missions[1])!;
    await pump(t, LedgerPageView(scene: hut, page: 0), caseId: case04.id);
    final rich = findReadableContaining('A heavy crate');
    expect(rich, findsOneWidget);
    expect(holdOnWord(t, rich, 'crate'), isFalse);
  });

  testWidgets('the slips: the slip picked is read with its words; on the trail, its letter number', (t) async {
    final trail = SeasonCatalog.postTrail(case05.finalMission)!;
    final picks = <String>[];
    await pump(
      t,
      PostTrailPuzzle(
        scene: trail,
        mission: case05.finalMission,
        placed: const {'second': 's5'},
        picked: 's3',
        checking: false,
        onPick: picks.add,
        onSlot: (_) {},
        onSubmit: () {},
      ),
      caseId: case05.id,
    );
    // On the trail: the letter's number, so 4471 is told from 4417 there.
    expect(findReadableContaining('No. 4471 · 16 MAY'), findsOneWidget);
    // The slip picked, its words written out and dotted.
    final words = find.byKey(const ValueKey('slip-detail-words'));
    expect(words, findsOneWidget);
    final detail = find.descendant(of: words, matching: find.byType(Text));
    expect(holdOnWord(t, detail, 'HELD'), isTrue);
    await t.pumpAndSettle();
    expect(find.text('WORD CARD'), findsOneWidget);
    expect(picks, isEmpty, reason: 'a word is not a slip');
  });
}

/// Holds [word] inside the rich text [finder] if it is a word to look up (has a
/// press and hold of its own); false when it is plain.
bool holdOnWord(WidgetTester t, Finder finder, String word) {
  final text = t.widget<Text>(finder);
  var found = false;
  text.textSpan!.visitChildren((span) {
    if (span is TextSpan && span.text == word && span.recognizer != null) {
      (span.recognizer! as LongPressGestureRecognizer).onLongPress!();
      found = true;
      return false;
    }
    return true;
  });
  return found;
}
