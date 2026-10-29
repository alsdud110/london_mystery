import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/models/case_talk.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show tapText, wait;
import 'helpers.dart';
import 'mission_play.dart' show prefsAt;

/// A mission played with talks around its own puzzle (Season 2, Cases
/// 11–12, see `TalkMission`): talk → puzzle → talk, and a mission played as
/// a talk only, in the real app. Played on Season 1 missions given talks for
/// the test only (the cases' own talks are not in the game yet); the
/// missions' data and saves are as they always are.
void main() {
  final season = MockEpisodeRepository.bundled();
  final case04 = season.firstWhere((e) => e.id == 'ep04');
  // A plain multiple-choice puzzle (its own answer, evidence and save).
  final m2 = case04.missionById('ep04_m2')!;
  final m1 = case04.missionById('ep04_m1')!;
  final found = m2.evidence!.id;

  final before = TalkScene(
    id: 'test_before',
    speaker: const TalkSpeaker(id: 'man', name: 'MR TEST'),
    goal: 'Find out what he knows.',
    opening: const [TalkLine('Hello, detective.')],
    questions: const [
      TalkQuestion(id: 'where', text: 'Where is it?', beat: [TalkLine('Look in the big book.'), TalkLine('If you like.')]),
    ],
    finishWhen: const {'where'},
    finishLabel: 'LOOK IN THE BOOK',
  );
  final after = TalkScene(
    id: 'test_after',
    speaker: const TalkSpeaker(id: 'man', name: 'MR TEST'),
    goal: 'Show him what you found.',
    opening: const [TalkLine('You found something?')],
    presents: [
      TalkPresent(
        id: 'show',
        prompt: 'Show him the evidence.',
        accepted: {found},
        beat: const [TalkLine('That was locked!', mood: 'nervous'), TalkLine('All right.')],
      ),
    ],
    finishWhen: const {'show'},
  );

  TalkMission? aroundM2(Mission m) => m.id == m2.id ? TalkMission(before: before, after: after) : null;

  late SharedPreferences prefs;
  late WidgetRef ref;

  /// The app at [missionId] (its place, or its puzzle when [started]), with
  /// [talks] and [asTalk] as the missions' talks; [restart]: the same saves
  /// as before (the app opened again).
  Future<void> open(
    WidgetTester t,
    String missionId, {
    bool started = true,
    bool restart = false,
    TalkMission? Function(Mission m)? talks,
    TalkScene? Function(Mission m)? asTalk,
  }) async {
    t.view.physicalSize = const Size(390, 844) * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    if (!restart) {
      SharedPreferences.setMockInitialValues(prefsAt(season, missionId, started: started));
      prefs = await SharedPreferences.getInstance();
    }
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(ProviderScope(
      key: UniqueKey(),
      overrides: [
        ...await testOverridesFor(prefs),
        talkMissionOfProvider.overrideWithValue(talks ?? aroundM2),
        if (asTalk != null) caseTalkOfProvider.overrideWithValue(asTalk),
      ],
      child: Consumer(builder: (context, r, _) {
        ref = r;
        return const WorldMysteryApp();
      }),
    ));
    await wait(t, const Duration(milliseconds: 300));
    ref.read(routerProvider).go(Routes.mission(missionId));
    await wait(t, const Duration(milliseconds: 1500));
  }

  Finder key(String k) => find.byKey(ValueKey(k));

  Future<void> tapKey(WidgetTester t, String k) async {
    await t.ensureVisible(key(k));
    await t.tap(key(k));
    await t.pump();
    await wait(t, const Duration(seconds: 3));
  }

  /// The talk said to its end (each line typed out, then the next).
  Future<void> sayAll(WidgetTester t) async {
    for (var i = 0; i < 6 && key('case-talk-next').evaluate().isNotEmpty; i++) {
      await tapKey(t, 'case-talk-next');
    }
  }

  Future<void> answerPuzzle(WidgetTester t, Mission m) async {
    await tapText(t, m.answerLabel, after: const Duration(milliseconds: 200));
    await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 600));
  }

  /// The letter after the talk before: opened, read, on to the puzzle.
  Future<void> readLetter(WidgetTester t) async {
    expect(find.text('CHECK ANSWER'), findsNothing, reason: 'the letter comes first');
    await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
    expect(findReadableContaining(m2.letter.split('\n').first), findsWidgets);
    await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
  }

  bool examined(String k) => ref.read(gameControllerProvider).hasExamined(k);

  group('talk → puzzle → talk', () {
    testWidgets('from its place: the talk first, then its letter and the puzzle, then the talk after, then the moment',
        (t) async {
      await open(t, m2.id, started: false);
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 1500));
      expect(find.text('"Hello, detective."'), findsOneWidget, reason: 'the talk before, at once');
      expect(find.text('CHECK ANSWER'), findsNothing, reason: 'the puzzle waits for the talk');
      await tapKey(t, 'case-talk-q-where');
      await sayAll(t);
      expect(key('case-talk-finish'), findsOneWidget);
      expect(find.text('LOOK IN THE BOOK'), findsOneWidget);
      await tapKey(t, 'case-talk-finish');
      expect(examined(TalkMission.beforeKey(m2.id)), isTrue);
      expect(key('case-talk-line'), findsNothing);
      // STEP 3-13B: then the mission's letter, as without a talk (a plain
      // puzzle is read from it), then the puzzle.
      await readLetter(t);
      expect(find.text('CHECK ANSWER'), findsOneWidget, reason: 'the puzzle now');

      await answerPuzzle(t, m2);
      expect(ref.read(gameControllerProvider).isCompleted(m2.id), isTrue, reason: 'solved and saved as always');
      expect(key('discovery-moment'), findsNothing, reason: 'the talk after comes first');
      expect(find.text('"You found something?"'), findsOneWidget);

      // The evidence just found, shown to him: his reaction.
      expect(find.text('Show him the evidence.'), findsOneWidget);
      final talk = ref.read(gameControllerProvider).puzzleStateOf(TalkMission.afterKey(m2.id));
      final shown = TalkProgress.decode(talk, after).show(after, found).$1;
      ref.read(gameControllerProvider.notifier).recordPuzzleState(TalkMission.afterKey(m2.id), shown.encode());
      await wait(t, const Duration(seconds: 3));
      expect(find.text('"That was locked!"'), findsOneWidget);
      await sayAll(t);
      await tapKey(t, 'case-talk-finish');
      expect(examined(TalkMission.afterKey(m2.id)), isTrue);
      expect(key('discovery-moment'), findsOneWidget, reason: "then the mission's moment");
      expect(t.takeException(), isNull);
    });

    testWidgets('the evidence shown through the notebook: the right piece, his reaction', (t) async {
      await open(t, m2.id);
      // The talk before already heard; the puzzle solved: the talk after.
      final c = ref.read(gameControllerProvider.notifier);
      c.recordExamined(TalkMission.beforeKey(m2.id));
      await wait(t, const Duration(milliseconds: 600));
      await answerPuzzle(t, m2);
      await sayAll(t);
      await tapKey(t, 'case-talk-show');
      expect(find.text('Which clue will you show?'), findsOneWidget, reason: "the notebook's evidence");
      await t.scrollUntilVisible(
        key('recall-pick-$found'),
        200,
        scrollable: find.descendant(of: find.byType(DraggableScrollableSheet), matching: find.byType(Scrollable)).first,
      );
      await t.tap(key('recall-pick-$found'));
      await t.pump();
      await wait(t, const Duration(seconds: 3));
      expect(find.text('"That was locked!"'), findsOneWidget);
      expect(TalkProgress.decode(ref.read(gameControllerProvider).puzzleStateOf(TalkMission.afterKey(m2.id)), after).isDone('show'), isTrue);
    });
  });

  group('saved and opened again', () {
    testWidgets('closed during the talk before: it opens on the line it was at, never past the puzzle', (t) async {
      await open(t, m2.id);
      await tapKey(t, 'case-talk-q-where');
      expect(find.text('"Look in the big book."'), findsOneWidget);
      await open(t, m2.id, restart: true);
      expect(find.text('"Look in the big book."'), findsOneWidget);
      expect(find.text('CHECK ANSWER'), findsNothing);
    });

    testWidgets('closed after the talk, before the puzzle: the puzzle, the talk not again', (t) async {
      await open(t, m2.id);
      await tapKey(t, 'case-talk-q-where');
      await sayAll(t);
      await tapKey(t, 'case-talk-finish');
      await open(t, m2.id, restart: true);
      expect(find.text('CHECK ANSWER'), findsOneWidget);
      expect(key('case-talk-line'), findsNothing, reason: 'no talk heard twice');
    });

    testWidgets('closed during the talk after (the puzzle solved): the talk again, the puzzle not', (t) async {
      await open(t, m2.id);
      ref.read(gameControllerProvider.notifier).recordExamined(TalkMission.beforeKey(m2.id));
      await wait(t, const Duration(milliseconds: 600));
      await answerPuzzle(t, m2);
      expect(find.text('"You found something?"'), findsOneWidget);
      await open(t, m2.id, restart: true);
      expect(find.text('"You found something?"'), findsOneWidget);
      expect(find.text('CHECK ANSWER'), findsNothing, reason: 'never solved twice');
      expect(ref.read(gameControllerProvider).isCompleted(m2.id), isTrue);
    });

    testWidgets('closed after his reaction to the evidence: the reaction, as it was', (t) async {
      await open(t, m2.id);
      final c = ref.read(gameControllerProvider.notifier);
      c.recordExamined(TalkMission.beforeKey(m2.id));
      await wait(t, const Duration(milliseconds: 600));
      await answerPuzzle(t, m2);
      final shown = TalkProgress.start.skip(after).show(after, found).$1;
      c.recordPuzzleState(TalkMission.afterKey(m2.id), shown.encode());
      await open(t, m2.id, restart: true);
      expect(find.text('"That was locked!"'), findsOneWidget);
      expect(key('case-talk-show'), findsNothing, reason: 'shown once');
    });

    testWidgets('a mission done (both talks heard): solved, as any mission', (t) async {
      await open(t, m2.id);
      final c = ref.read(gameControllerProvider.notifier);
      c.recordExamined(TalkMission.beforeKey(m2.id));
      await wait(t, const Duration(milliseconds: 600));
      await answerPuzzle(t, m2);
      c.recordExamined(TalkMission.afterKey(m2.id));
      await open(t, m2.id, restart: true);
      expect(key('solved'), findsOneWidget);
      expect(key('case-talk-line'), findsNothing);
    });
  });

  testWidgets('a talk before only: after the puzzle, the moment at once (no talk after)', (t) async {
    await open(t, m2.id, talks: (m) => m.id == m2.id ? TalkMission(before: before) : null);
    await tapKey(t, 'case-talk-q-where');
    await sayAll(t);
    await tapKey(t, 'case-talk-finish');
    await readLetter(t);
    await answerPuzzle(t, m2);
    expect(key('discovery-moment'), findsOneWidget);
  });

  testWidgets('a talk after only: the puzzle first, then the talk', (t) async {
    await open(t, m2.id, talks: (m) => m.id == m2.id ? TalkMission(after: after) : null);
    expect(find.text('CHECK ANSWER'), findsOneWidget);
    await answerPuzzle(t, m2);
    expect(find.text('"You found something?"'), findsOneWidget);
  });

  testWidgets('a mission played as a talk only still answers its puzzle with the talk', (t) async {
    final asTalk = TalkScene(
      id: 'test_only',
      speaker: const TalkSpeaker(id: 'man', name: 'MR TEST'),
      goal: 'Ask him.',
      opening: const [TalkLine('Ask me.')],
      questions: const [TalkQuestion(id: 'q', text: 'What is it?', beat: [TalkLine('That is all.')])],
      finishWhen: const {'q'},
      answer: m1.answer,
    );
    await open(t, m1.id, talks: (_) => null, asTalk: (m) => m.id == m1.id ? asTalk : null);
    await tapKey(t, 'case-talk-q-q');
    await tapKey(t, 'case-talk-finish');
    expect(ref.read(gameControllerProvider).isCompleted(m1.id), isTrue);
    expect(key('discovery-moment'), findsOneWidget);
  });

  testWidgets('back from the talk before goes to the place (no letter step)', (t) async {
    await open(t, m2.id);
    expect(key('case-talk-line'), findsOneWidget);
    await t.tap(find.byTooltip('Back'));
    await wait(t, const Duration(milliseconds: 800));
    expect(find.text('INVESTIGATE'), findsOneWidget);
  });
}
