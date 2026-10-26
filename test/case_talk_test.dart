import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/data/mock/season_catalog.dart';
import 'package:london_mystery/data/models/case_talk.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/mission/widgets/case_talk.dart';
import 'package:london_mystery/features/mission/widgets/evidence_recall.dart';

import 'helpers.dart';

/// CaseTalk, the talk with one person of Season 2's Cases 11–12: questions
/// asked, evidence shown from the notebook, the person's face changing, new
/// questions opening, and the talk saved in the case save's puzzle states
/// (no key of its own). Played here on a talk made for the test only: the
/// cases' own talks are not in the game yet, and no mission of the game
/// changes.
void main() {
  // A talk for the test (not a case's): two questions, one opened by the
  // other; a piece of evidence to show; a name learnt on the way.
  final scene = TalkScene(
    id: 'test_talk',
    speaker: const TalkSpeaker(
      id: 'man',
      name: 'MR TEST',
      hiddenName: '???',
      revealedBy: 'show',
      portraits: {'base': 'missing/base.png', 'nervous': 'missing/nervous.png'},
    ),
    goal: 'Find out what he hid.',
    opening: const [
      TalkLine.narrator('A man waits by the door.'),
      TalkLine('Hello, detective.'),
    ],
    questions: const [
      TalkQuestion(
        id: 'who',
        text: 'Who are you?',
        beat: [TalkLine("Don't ask me."), TalkLine('Find out with clues.')],
      ),
      TalkQuestion(
        id: 'why',
        text: 'Why did you hide it?',
        requires: {'show'},
        beat: [TalkLine('I was afraid.', mood: 'nervous')],
      ),
    ],
    presents: const [
      TalkPresent(
        id: 'show',
        prompt: 'Show him what you found.',
        requires: {'who'},
        accepted: {'right'},
        beat: [TalkLine('That box was locked!', mood: 'nervous'), TalkLine('All right.')],
        misses: {'close': TalkLine('That is not mine.')},
      ),
    ],
    finishWhen: {'show', 'why'},
    answer: 'q:done',
  );

  group('the talk, step by step (data only)', () {
    test('the opening, line by line; the face and the name as they are now', () {
      var p = TalkProgress.start;
      expect(p.current(scene)!.voice, TalkVoice.narrator);
      expect(p.beatOver(scene), isFalse);
      expect(p.questions(scene), isNotEmpty, reason: 'listed, shown once the beat is said');
      p = p.next(scene);
      expect(p.current(scene)!.text, 'Hello, detective.');
      expect(p.beatOver(scene), isTrue);
      expect(p.openingSeen, isTrue);
      expect(p.speakerName(scene), '???');
      expect(p.mood(scene), 'base');
    });

    test('a question opens only once what it needs is done', () {
      var p = TalkProgress.start.skip(scene);
      expect(p.questions(scene).map((q) => q.id), ['who']);
      expect(p.presents(scene), isEmpty, reason: 'nothing to show before the first question');
      expect(p.ask(scene, 'why'), p, reason: 'not open yet: nothing happens');
      p = p.ask(scene, 'who');
      expect(p.beatId, 'who');
      expect(p.line, 0);
      expect(p.done, ['who']);
      expect(p.nextPresent(scene)!.id, 'show');
      // Asked again: the same answer, done once.
      p = p.skip(scene).ask(scene, 'who');
      expect(p.done, ['who']);
    });

    test('the right evidence: its reaction, the face it brings, the name learnt, a new question', () {
      var p = TalkProgress.start.skip(scene).ask(scene, 'who').skip(scene);
      final (shown, fits) = p.show(scene, 'right');
      expect(fits, isTrue);
      p = shown;
      expect(p.beatId, 'show');
      expect(p.mood(scene), 'nervous');
      expect(p.next(scene).mood(scene), 'nervous', reason: 'a line without a mood keeps the face before it');
      expect(p.speakerName(scene), 'MR TEST');
      expect(p.questions(scene).map((q) => q.id), ['who', 'why']);
      expect(p.presents(scene), isEmpty, reason: 'shown once');
      expect(p.finished(scene), isFalse);
      p = p.ask(scene, 'why');
      expect(p.finished(scene), isTrue);
    });

    test('other evidence: the line for it, or the general one; never done, never wrong', () {
      final p = TalkProgress.start.skip(scene).ask(scene, 'who').skip(scene);
      final (close, fits) = p.show(scene, 'close');
      expect(fits, isFalse);
      expect(close.beatId, TalkProgress.missId('show', 'close'));
      expect(close.current(scene)!.text, 'That is not mine.');
      expect(close.done, ['who']);
      final (other, _) = p.show(scene, 'nothing_like_it');
      expect(other.current(scene)!.text, "I don't see what that means.");
      expect(other.nextPresent(scene)!.id, 'show', reason: 'still to be shown');
      expect(other.speakerName(scene), '???');
    });

    test('saved as a short string and read back as it was; anything strange starts afresh', () {
      final p = TalkProgress.start.skip(scene).ask(scene, 'who').skip(scene).show(scene, 'right').$1.next(scene);
      final raw = p.encode();
      expect(TalkProgress.decode(raw, scene), p);
      final miss = TalkProgress.start.skip(scene).ask(scene, 'who').skip(scene).show(scene, 'close').$1;
      expect(TalkProgress.decode(miss.encode(), scene), miss, reason: 'after the person answered a piece');
      expect(TalkProgress.decode(null, scene), TalkProgress.start);
      expect(TalkProgress.decode('not json', scene), TalkProgress.start);
      expect(TalkProgress.decode('[1,2]', scene), TalkProgress.start);
      final odd = TalkProgress.decode('{"d":["who","gone","who"],"b":"gone","l":9}', scene);
      expect(odd.done, ['who'], reason: 'unknown steps dropped, none twice');
      expect(odd.beatId, TalkScene.openingId);
      expect(odd.line, 1, reason: 'within the beat');
      expect(odd.openingSeen, isTrue);
    });

    test("the talk's save is an entry of the puzzle states, kept across a restart", () {
      expect(caseTalkStateKey('s2_ep11_m1'), 's2_ep11_m1:talk');
      final p = TalkProgress.start.skip(scene).ask(scene, 'who');
      final saved = const GameProgress().copyWith(puzzleStates: {caseTalkStateKey('m'): p.encode(), 'm': 'its puzzle'});
      final again = GameProgress.fromJson(saved.toJson());
      expect(TalkProgress.decode(again.puzzleStateOf(caseTalkStateKey('m')), scene), p);
      expect(again.puzzleStateOf('m'), 'its puzzle', reason: "the mission's own puzzle is kept apart");
    });

    test('no mission of the game is played as a case talk yet; Season 1 keeps its talk', () {
      for (final e in MockEpisodeRepository.bundled()) {
        for (final m in e.allMissions) {
          expect(SeasonCatalog.caseTalk(m), isNull, reason: m.id);
        }
      }
      for (final c in SeasonCatalog.all) {
        expect(c.talks, isEmpty);
      }
      expect(season1Content.dialogues.keys, ['ep06_m1']);
    });
  });

  group("Season 1's Clockmaker's watch in Season 2 (ep12_e4)", () {
    final all = MockEpisodeRepository.bundled();

    test('evidence ids never repeat across seasons', () {
      final ids = [for (final e in all) for (final v in e.allEvidence) v.id];
      expect(ids.toSet().length, ids.length);
      expect([for (final e in all) if (e.seasonId == SeasonIds.paris) ...e.allEvidence.map((v) => v.id)].every((id) => id.startsWith('s2_')), isTrue);
    });

    List<String> held({required bool solved, bool reference = false, String? playing}) => [
      for (final h in earlierSeasonEvidence(
        ids: const ['ep12_e4'],
        allEpisodes: all,
        seasonId: playing ?? SeasonIds.paris,
        solved: (e) => solved && e.id == 'ep12',
        reference: reference,
      ))
        '${h.evidence.id}|${h.evidence.name}|${h.episode.id}|${h.location}',
    ];

    test("held when Season 1's Case 12 is solved (as every Season 2 player's is)", () {
      expect(held(solved: true), ["ep12_e4|The Clockmaker's Watch|ep12|${all.firstWhere((e) => e.id == 'ep12').finalMission.location}"]);
    });

    test('not held when it is not solved; shown for reference in operator access or the season preview', () {
      expect(held(solved: false), isEmpty);
      expect(held(solved: false, reference: true), hasLength(1));
    });

    test('never as an earlier season while Season 1 itself is played', () {
      expect(held(solved: true, playing: AppConstants.firstSeasonId), isEmpty);
    });
  });

  group('the talk on screen', () {
    Future<(List<TalkProgress>, List<String>)> pumpTalk(
      WidgetTester t, {
      TalkProgress start = TalkProgress.start,
      String? pick,
      TalkScene? talk,
    }) async {
      final saved = <TalkProgress>[];
      final finished = <String>[];
      await t.pumpWidget(
        ProviderScope(
          overrides: await testOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: CaseTalk(
                scene: talk ?? scene,
                progress: start,
                onProgress: saved.add,
                onFinish: () => finished.add('done'),
                pickEvidence: (_) async => pick,
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(seconds: 3));
      return (saved, finished);
    }

    Future<void> tapKey(WidgetTester t, String key) async {
      await t.ensureVisible(find.byKey(ValueKey(key)));
      await t.tap(find.byKey(ValueKey(key)));
      // The new line comes a frame later (showing evidence waits for the
      // notebook), then is typed out.
      await t.pump();
      await t.pump(const Duration(seconds: 3));
    }

    testWidgets('the opening, then a question, its answer, and the next one opened', (t) async {
      final (saved, _) = await pumpTalk(t);
      expect(find.text('A man waits by the door.'), findsOneWidget);
      expect(find.byKey(const ValueKey('case-talk-name')), findsNothing, reason: "the narrator's line has no name plate");
      expect(find.byKey(const ValueKey('case-talk-q-who')), findsNothing, reason: 'nothing to choose while a line is said');
      await tapKey(t, 'case-talk-next');
      expect(find.text('"Hello, detective."'), findsOneWidget);
      expect(find.text('???'), findsOneWidget, reason: 'his name is not known yet');
      expect(find.byKey(const ValueKey('case-talk-show')), findsNothing, reason: 'nothing to show before the first question');
      await tapKey(t, 'case-talk-q-who');
      expect(find.text('"Don\'t ask me."'), findsOneWidget);
      expect(saved.last.done, ['who']);
      await tapKey(t, 'case-talk-line');
      expect(find.text('"Find out with clues."'), findsOneWidget);
      expect(find.text('Show him what you found.'), findsOneWidget);
      expect(find.byKey(const ValueKey('case-talk-show')), findsOneWidget);
      expect(find.byKey(const ValueKey('case-talk-q-why')), findsNothing);
    });

    testWidgets('the right evidence: the reaction, the name, the new question; then the way on', (t) async {
      final start = TalkProgress.start.skip(scene).ask(scene, 'who').skip(scene);
      final (saved, finished) = await pumpTalk(t, start: start, pick: 'right');
      await tapKey(t, 'case-talk-show');
      expect(find.text('"That box was locked!"'), findsOneWidget);
      expect(find.text('MR TEST'), findsOneWidget, reason: 'his name, learnt from the evidence');
      expect(saved.last.done, ['who', 'show']);
      await tapKey(t, 'case-talk-next');
      await tapKey(t, 'case-talk-q-why');
      expect(find.text('"I was afraid."'), findsOneWidget);
      expect(find.byKey(const ValueKey('case-talk-finish')), findsOneWidget);
      await tapKey(t, 'case-talk-finish');
      await tapKey(t, 'case-talk-finish');
      expect(finished, ['done'], reason: 'once');
    });

    testWidgets('other evidence: what he says to it; it can be shown again', (t) async {
      final start = TalkProgress.start.skip(scene).ask(scene, 'who').skip(scene);
      final (saved, _) = await pumpTalk(t, start: start, pick: 'close');
      await tapKey(t, 'case-talk-show');
      expect(find.text('"That is not mine."'), findsOneWidget);
      expect(find.text('???'), findsOneWidget);
      expect(saved.last.done, ['who']);
      expect(find.byKey(const ValueKey('case-talk-show')), findsOneWidget, reason: 'still to be shown');
    });

    testWidgets('a talk left anywhere opens there again (a restart)', (t) async {
      final start = TalkProgress.start.skip(scene).ask(scene, 'who').skip(scene).show(scene, 'right').$1;
      final again = TalkProgress.decode(start.encode(), scene);
      await pumpTalk(t, start: again);
      expect(find.text('"That box was locked!"'), findsOneWidget);
      expect(find.text('MR TEST'), findsOneWidget);
      expect(find.byKey(const ValueKey('case-talk-skip')), findsNothing, reason: 'not heard to its end yet');
    });

    testWidgets('a beat heard before can be skipped', (t) async {
      final start = TalkProgress.start.skip(scene).ask(scene, 'who').skip(scene);
      await pumpTalk(t, start: start);
      await tapKey(t, 'case-talk-q-who');
      expect(find.byKey(const ValueKey('case-talk-skip')), findsOneWidget);
      await tapKey(t, 'case-talk-skip');
      expect(find.text('"Find out with clues."'), findsOneWidget);
    });

    testWidgets('no portrait: nothing stands in for the person, and the talk goes on', (t) async {
      final bare = TalkScene(
        id: 'bare',
        speaker: const TalkSpeaker(id: 'x', name: 'NOBODY'),
        goal: 'A goal.',
        opening: const [TalkLine('Hi.')],
        questions: const [TalkQuestion(id: 'q', text: 'Why?', beat: [TalkLine('Because.')])],
        finishWhen: const {'q'},
      );
      await pumpTalk(t, talk: bare);
      expect(find.byType(Image), findsNothing);
      expect(find.byKey(const ValueKey('case-talk-portrait')), findsNothing);
      await tapKey(t, 'case-talk-q-q');
      expect(find.text('"Because."'), findsOneWidget);
      expect(find.byKey(const ValueKey('case-talk-finish')), findsOneWidget);
    });

    testWidgets('a portrait file that is not there yet leaves the space empty', (t) async {
      await pumpTalk(t);
      expect(find.byKey(const ValueKey('case-talk-portrait')), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('the talk log reads back what was said', (t) async {
      final start = TalkProgress.start.skip(scene).ask(scene, 'who').skip(scene);
      await pumpTalk(t, start: start);
      await tapKey(t, 'case-talk-log');
      expect(find.byKey(const ValueKey('case-talk-log-sheet')), findsOneWidget);
      expect(find.text('Who are you?'), findsWidgets);
      expect(find.text('???: Find out with clues.'), findsOneWidget);
    });
  });

  testWidgets("the notebook sheet shows an earlier season's piece under its city, and gives what is taken", (t) async {
    final all = MockEpisodeRepository.bundled();
    final watch = earlierSeasonEvidence(
      ids: const ['ep12_e4'],
      allEpisodes: all,
      seasonId: SeasonIds.paris,
      solved: (_) => true,
      reference: false,
    );
    String? taken = 'none';
    await t.pumpWidget(
      ProviderScope(
        overrides: await testOverrides(),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async => taken = await showEvidencePicker(context, ask: 'Which clue will you show?', earlier: watch),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('Which clue will you show?'), findsOneWidget);
    expect(find.textContaining('LONDON · CASE 12'), findsOneWidget);
    await t.scrollUntilVisible(find.byKey(const ValueKey('recall-pick-ep12_e4')), 200, scrollable: find.byType(Scrollable).last);
    await t.tap(find.byKey(const ValueKey('recall-pick-ep12_e4')));
    await t.pumpAndSettle();
    expect(taken, 'ep12_e4');
  });
}

