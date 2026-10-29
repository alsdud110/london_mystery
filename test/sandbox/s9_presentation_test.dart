import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/content/puzzle_engine_collisions.dart';
import 'package:world_mystery/data/content/season_content_validator.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/case_talk.dart';
import 'package:world_mystery/data/models/discovery.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/result/case_solved_screen.dart';

import '../../tool/season_gen/plan_files.dart';
import '../../tool/season_gen/plan_models.dart';
import '../full_playthrough_test.dart' show reveal, tapText, wait;
import '../helpers.dart';
import 'sandbox_play.dart';
import 'sandbox_season.dart';

/// STEP 3-13B: the story around the puzzles, planned in Case 02's plan
/// (`content_pipeline/seasons/s9_sandbox/cases/s9_ep02/case.plan.json`),
/// made by the generator into the game's own tables (`talkMissions`,
/// `discoveries`, `endings`) and played in the real app: a talk before M1's
/// puzzle, a talk after M2's, each mission's own Discovery Moment (M3 with
/// no talk at all), the final's ending, then Case Solved and Case 03 open.
/// Saved as it goes: a talk or an ending left halfway is taken up again.
void main() {
  const casePath = 'content_pipeline/seasons/s9_sandbox/cases/s9_ep02/case.plan.json';
  final plan = PlanFiles.loadCasePlan(casePath);
  final [case01, case02, case03] = sandboxEpisodes();
  final [m1, m2, m3] = case02.missions;
  final fin = case02.finalMission;
  MissionPlayPlan words(String id) => plan.allMissions.firstWhere((m) => m.missionId == id).play!;

  group('the generated story tables', () {
    test('are the plan: talks, discoveries and the ending, each where it was written', () {
      final talks = sandboxContent.talkMissions;
      expect(talks.keys, [m1.id, m2.id], reason: 'M3 and the final have no talk');
      expect(talks[m1.id]!.after, isNull);
      expect(talks[m2.id]!.before, isNull);
      final before = talks[m1.id]!.before!;
      final t1 = words(m1.id).talk!;
      expect([for (final l in before.opening) (l.voice.name, l.text)], [for (final l in t1.before!.lines) (l.by.name, l.text)]);
      expect(before.speaker.name, 'MS. ROSA', reason: "the season plan's name, as the talks print it");
      expect((before.goal, before.place, before.finishLabel), (t1.goal, m1.location, 'READ THE NOTE'));
      expect(before.background, sandboxContent.places[(m1.place as SeasonScene).id]!.file, reason: "the mission's own place");
      expect(before.speaker.portraits, isEmpty, reason: 'no portrait planned: none shown, never a stand-in');
      expect(talks[m2.id]!.after!.finishLabel, 'CONTINUE', reason: "the game's own when not given");

      expect(sandboxContent.discoveries.keys, [m1.id, m2.id, m3.id]);
      for (final m in case02.missions) {
        final d = sandboxContent.discoveries[m.id]!;
        final p = words(m.id).discovery!;
        expect((d.type.name, d.timing, d.title, d.detail, d.showEvidence), (p.type, DiscoveryTiming.fromPuzzle, p.title, p.detail, false), reason: m.id);
        expect(d.title, isNot(m.successMessage), reason: '${m.id}: its own words, not the success line again');
      }

      final ending = sandboxContent.endings[fin.id]!;
      expect([for (final l in ending) (l.voice.name, l.text)], [for (final l in words(fin.id).ending) (l.by.name, l.text)]);
      expect([for (final l in ending) l.name], ['MS. ROSA', null, 'MS. ROSA', null, 'MS. ROSA']);
      expect(ending[1].evidenceId, 's9_ep02_e1', reason: "Mr. Bell's note, laid over the line that explains it");
      expect({for (final l in ending) l.background}, {sandboxContent.places[(fin.place as SeasonScene).id]!.file});
    });

    test("cases with none of it keep the tables empty: Case 01's and Case 03's missions play as before", () {
      for (final e in [case01, case03]) {
        for (final m in e.allMissions) {
          expect(sandboxContent.talkMissions.containsKey(m.id), isFalse, reason: m.id);
          expect(sandboxContent.discoveries.containsKey(m.id), isFalse, reason: m.id);
          expect(sandboxContent.endings.containsKey(m.id), isFalse, reason: m.id);
        }
      }
    });

    test("the game finds nothing wrong: its validator and its engine choice (the talks are played, never hidden)", () {
      expect(SeasonContentValidator.validate(sandboxContent), isEmpty);
      expect(PuzzleEngineCollisionCheck.problemsOf(sandboxContent), isEmpty);
      final slots = {for (final s in PuzzleEngineCollisionCheck.slotsOf(sandboxContent)) s.mission.id: s};
      expect(slots[m1.id]!.companions, ['talkMissions']);
      expect(slots[m2.id]!.companions, ['talkMissions']);
      expect(slots[fin.id]!.companions, ['endings']);
    });
  });

  group('played in the real app', () {
    tearDown(unregisterSandboxSeason);

    testWidgets('Case 02: talk → letter → puzzle → discovery; puzzle → talk → discovery; the ending → Case Solved → Case 03 open',
        (t) async {
      registerSandboxSeason();
      WidgetController.hitTestWarningShouldBeFatal = true; // every tap must land
      addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
      t.view.physicalSize = const Size(1170, 2532);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      Future<ProviderContainer> start() async {
        final c = ProviderContainer(overrides: [...await testOverridesFor(prefs), ...sandboxOverrides()]);
        addTearDown(c.dispose);
        c.read(seasonPreviewSwitchProvider.notifier).set(true); // the sandbox opens unreleased
        return c;
      }

      final c = await start();
      final ctrl = c.read(gameControllerProvider.notifier);
      ctrl.createDetective('Kim', DetectiveAvatar.girl);
      expect(ctrl.openSeason(sandboxSeasonId), isTrue);
      // Case 01 solved through the game's own answers (its play is s9_ep01_test's).
      expect(ctrl.openEpisode(case01.id), isTrue);
      ctrl.startInvestigation();
      for (final m in case01.allMissions) {
        expect(ctrl.submitAnswer(m, m.answer).result.name, 'correct', reason: m.id);
      }
      expect(ctrl.openEpisode(case02.id), isTrue);

      await t.pumpWidget(UncontrolledProviderScope(container: c, child: const WorldMysteryApp()));
      await wait(t);
      final router = c.read(routerProvider);
      final play = SandboxPlay(t);
      GameProgress progress() => c.read(gameControllerProvider);

      router.go(Routes.intro);
      await wait(t, const Duration(milliseconds: 1500));
      await tapText(t, 'SKIP ›');
      await tapText(t, "I'M READY", after: const Duration(milliseconds: 2000));

      /// The talk's lines from [from], each typed out whole and its name plate
      /// (the speaker's, YOU, none for the narrator), then [finish] when given.
      Future<void> hear(TalkScene talk, {int from = 0, int? to, String? finish}) async {
        final lines = talk.opening;
        for (var i = from; i < (to ?? lines.length); i++) {
          final line = lines[i];
          if (find.text('READ ALL').evaluate().isNotEmpty) await tapText(t, 'READ ALL', after: const Duration(milliseconds: 300));
          expect(findReadableContaining(line.text), findsWidgets, reason: '${talk.id} line $i: ${play.texts()}');
          final name = find.byKey(const ValueKey('case-talk-name'));
          switch (line.voice) {
            case TalkVoice.speaker:
              expect(t.widget<Text>(name).data, talk.speaker.name, reason: '${talk.id} line $i');
            case TalkVoice.detective:
              expect(t.widget<Text>(name).data, 'YOU', reason: '${talk.id} line $i');
            case TalkVoice.narrator:
              expect(name, findsNothing, reason: '${talk.id} line $i');
          }
          if (i < lines.length - 1) {
            expect(find.byKey(const ValueKey('case-talk-finish')), findsNothing, reason: 'the talk is still said');
            await tapText(t, 'NEXT', after: const Duration(milliseconds: 300));
          }
        }
        if (finish != null) await tapText(t, finish, after: const Duration(milliseconds: 1200));
      }

      Future<void> discovery(Mission m) async {
        final d = sandboxContent.discoveries[m.id]!;
        await wait(t, const Duration(milliseconds: 1500));
        expect(findReadableContaining(d.title), findsWidgets, reason: '${m.id} discovery: ${play.texts()}');
        expect(findReadableContaining(d.detail), findsWidgets, reason: '${m.id} discovery: ${play.texts()}');
        expect(find.text(d.type.cheer), findsWidgets, reason: '${m.id}: its kind of discovery (${d.type.label}): ${play.texts()}');
      }

      // ── M1: the talk before the puzzle, then the letter and the puzzle.
      final before = sandboxContent.talkMissions[m1.id]!.before!;
      await play.toPlace(m1);
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      expect(find.byKey(const ValueKey('case-talk-goal')), findsOneWidget, reason: 'the talk comes first: ${play.texts()}');
      expect(findReadable(before.goal), findsOneWidget);
      expect(find.text('TAP TO OPEN'), findsNothing, reason: 'the letter waits for the talk');
      // Two lines heard (NEXT tapped on the second): left on the third.
      await hear(before, to: 2);
      // Left halfway: saved as it is, and taken up there again.
      expect(TalkProgress.decode(progress().puzzleStateOf(TalkMission.beforeKey(m1.id)), before).line, 2);
      {
        final restarted = await start();
        expect(TalkProgress.decode(restarted.read(gameControllerProvider).puzzleStateOf(TalkMission.beforeKey(m1.id)), before).line, 2,
            reason: 'kept after a restart');
      }
      await t.tap(find.byTooltip('Back'));
      await wait(t, const Duration(milliseconds: 900));
      expect(find.text('INVESTIGATE'), findsOneWidget, reason: 'back from the talk is the place: ${play.texts()}');
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      expect(findReadableContaining(before.opening[0].text), findsNothing, reason: 'not from its start: ${play.texts()}');
      // From the line it was left on.
      await hear(before, from: 2, finish: 'READ THE NOTE');
      expect(progress().hasExamined(TalkMission.beforeKey(m1.id)), isTrue);
      // The letter, as without a talk: then the puzzle.
      await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
      expect(findReadableContaining(m1.letter.split('\n').first), findsWidgets, reason: 'm1 letter: ${play.texts()}');
      // Back and in again: the talk heard is never played again.
      await t.tap(find.byTooltip('Back'));
      await wait(t, const Duration(milliseconds: 900));
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      expect(find.byKey(const ValueKey('case-talk-goal')), findsNothing, reason: 'heard once: ${play.texts()}');
      // The letter read stays open, as always.
      expect(findReadableContaining(m1.letter.split('\n').first), findsWidgets, reason: 'm1 letter: ${play.texts()}');
      await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
      expect(findReadable(m1.question), findsOneWidget, reason: play.texts());
      await play.wrong(m1, 'lamp,book,shelf', line: 'Find First, Then and Last.');
      await play.answer(m1, m1.answer);
      expect(progress().isCompleted(m1.id), isTrue);
      await discovery(m1);
      await play.onToMap(m1);

      // ── M2: the puzzle, then the talk after it, then its discovery.
      final after = sandboxContent.talkMissions[m2.id]!.after!;
      await play.toPuzzle(m2);
      await play.answer(m2, m2.answer);
      expect(progress().isCompleted(m2.id), isTrue, reason: 'the answer is saved before the talk');
      await wait(t, const Duration(milliseconds: 600));
      expect(find.byKey(const ValueKey('case-talk-goal')), findsOneWidget, reason: 'Ms. Rosa reacts first: ${play.texts()}');
      expect(find.text('CONTINUE INVESTIGATION'), findsNothing, reason: 'the discovery waits for the talk');
      await hear(after, finish: 'CONTINUE');
      expect(progress().hasExamined(TalkMission.afterKey(m2.id)), isTrue);
      await discovery(m2);
      await play.onToMap(m2);

      // ── M3: no talk; its own discovery.
      await play.toPuzzle(m3);
      expect(find.byKey(const ValueKey('case-talk-goal')), findsNothing);
      await play.answer(m3, m3.answer);
      await discovery(m3);
      await play.onToMap(m3);

      // ── The final: its answer, then the ending; the case closes once it is seen.
      await play.toFinal(fin);
      await play.answer(fin, fin.answer);
      await wait(t, const Duration(milliseconds: 1500));
      expect(find.byKey(const ValueKey('final-ending')), findsOneWidget, reason: play.texts());
      expect(progress().isCompleted(fin.id), isTrue);
      expect(progress().isCaseSolved, isFalse, reason: 'not closed before the ending is seen');
      expect(c.read(seasonProvider).solvedEpisodeIds, [case01.id]);
      final ending = sandboxContent.endings[fin.id]!;
      for (final (i, line) in ending.indexed) {
        if (find.text('READ ALL').evaluate().isNotEmpty) await tapText(t, 'READ ALL', after: const Duration(milliseconds: 300));
        expect(findReadableContaining(line.text), findsWidgets, reason: 'ending line $i: ${play.texts()}');
        final plate = switch (line.voice) {
          TalkVoice.speaker => line.name,
          TalkVoice.detective => 'YOU',
          TalkVoice.narrator => null,
        };
        if (plate != null) expect(find.text(plate), findsWidgets, reason: 'ending line $i');
        if (line.evidenceId case final e?) {
          expect(find.byKey(ValueKey('ending-evidence-$e')), findsOneWidget, reason: 'the note laid over the line: ${play.texts()}');
        }
        if (i == 1) {
          // Left halfway (a restart): the ending is waiting, the case not closed.
          final restarted = await start();
          expect(restarted.read(gameControllerProvider).finalAwaitsLastStep(case02), isTrue);
        }
        if (i < ending.length - 1) await tapText(t, 'NEXT', after: const Duration(milliseconds: 600));
      }
      await tapText(t, 'CLOSE THE CASE', after: const Duration(milliseconds: 1500));
      expect(progress().isCaseSolved, isTrue);
      expect(c.read(seasonProvider).solvedEpisodeIds, [case01.id, case02.id]);

      // ── The story after the case, then the report; Case 03 is open.
      expect(find.text('CASE 02 COMPLETE'), findsOneWidget, reason: play.texts());
      await t.tapAt(t.getCenter(find.byType(Scaffold).last));
      await wait(t, const Duration(milliseconds: 1200));
      expect(findReadableContaining(fin.transition.last), findsWidgets, reason: play.texts());
      await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 3200));
      expect(find.byType(CaseSolvedScreen), findsOneWidget);
      expect(findReadableContaining(case02.caseSummary!), findsWidgets, reason: play.texts());
      await reveal(t, find.text('OPEN CASE 03'));
      expect(find.text('OPEN CASE 03'), findsOneWidget, reason: play.texts());
      expect(c.read(seasonProvider.notifier).isUnlocked(case03.id), isTrue);
      {
        final restarted = await start();
        expect(restarted.read(seasonProvider).solvedEpisodeIds, [case01.id, case02.id], reason: 'saved');
      }
    });

    testWidgets('a talk before a puzzle on pictures comes first: then the look round, or the search after its arrival', (t) async {
      // Case 03's missions as generated, with a talk before M1 (a look round)
      // and M2 (a search) for this test only: the engine's order (STEP 3-13B).
      TalkScene talk(String id) => TalkScene(
            id: id,
            speaker: const TalkSpeaker(id: 'ms_rosa', name: 'MS. ROSA'),
            goal: 'Follow the courier.',
            opening: const [TalkLine('Look round carefully.')],
            finishWhen: const {},
          );
      final [p1, p2, _, _] = case03.missions;
      final s = sandboxContent;
      registerSandboxPlaces();
      SeasonCatalog.testSeasons.add(SeasonContent(
        info: s.info,
        episodes: s.episodes,
        places: s.places,
        released: false,
        storyGreeting: s.storyGreeting,
        learning: s.learning,
        languageTopics: s.languageTopics,
        evidenceLinks: s.evidenceLinks,
        explores: s.explores,
        investigations: s.investigations,
        dialogues: s.dialogues,
        talkMissions: {
          ...s.talkMissions,
          p1.id: TalkMission(before: talk('${p1.id}:before')),
          p2.id: TalkMission(before: talk('${p2.id}:before')),
        },
        discoveries: s.discoveries,
        endings: s.endings,
      ));
      t.view.physicalSize = const Size(1170, 2532);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [...await testOverridesFor(prefs), ...sandboxOverrides()]);
      addTearDown(c.dispose);
      c.read(seasonPreviewSwitchProvider.notifier).set(true);
      final ctrl = c.read(gameControllerProvider.notifier);
      ctrl.createDetective('Kim', DetectiveAvatar.girl);
      expect(ctrl.openSeason(sandboxSeasonId), isTrue);
      for (final e in [case01, case02]) {
        expect(ctrl.openEpisode(e.id), isTrue, reason: e.id);
        ctrl.startInvestigation();
        for (final m in e.allMissions) {
          expect(ctrl.submitAnswer(m, m.answer).result.name, 'correct', reason: m.id);
        }
        if (SeasonCatalog.caseEnding(e.finalMission) != null) ctrl.closeCase(GameProgress.examinedKey(e.finalMission.id, 'ending'));
      }
      expect(ctrl.openEpisode(case03.id), isTrue);
      ctrl.startInvestigation();

      await t.pumpWidget(UncontrolledProviderScope(container: c, child: const WorldMysteryApp()));
      await wait(t);
      final router = c.read(routerProvider);
      final play = SandboxPlay(t);
      router.go(Routes.map);
      await wait(t, const Duration(milliseconds: 2500));

      // M1: the talk, then the place looked round.
      await play.toPlace(p1);
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      expect(find.byKey(const ValueKey('case-talk-goal')), findsOneWidget, reason: play.texts());
      expect(find.byKey(const ValueKey('explore-picture')), findsNothing);
      if (find.text('READ ALL').evaluate().isNotEmpty) await tapText(t, 'READ ALL', after: const Duration(milliseconds: 300));
      expect(findReadableContaining('Look round carefully.'), findsWidgets, reason: play.texts());
      await tapText(t, 'CONTINUE', after: const Duration(milliseconds: 1200));
      expect(find.byKey(const ValueKey('explore-picture')), findsOneWidget, reason: 'the look round after the talk: ${play.texts()}');

      // M2 (M1 answered by the game's own answer): the talk, the arrival, the search.
      expect(ctrl.submitAnswer(p1, p1.answer).result.name, 'correct');
      router.go(Routes.mission(p2.id)); // its page, as GO TO opens it
      await wait(t, const Duration(milliseconds: 2800));
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      expect(find.byKey(const ValueKey('case-talk-goal')), findsOneWidget, reason: play.texts());
      if (find.text('READ ALL').evaluate().isNotEmpty) await tapText(t, 'READ ALL', after: const Duration(milliseconds: 300));
      expect(findReadableContaining('Look round carefully.'), findsWidgets, reason: play.texts());
      await tapText(t, 'CONTINUE', after: const Duration(milliseconds: 3000));
      final search = s.investigations[p2.id]!;
      for (final line in search.arrival) {
        expect(findReadableContaining(line), findsWidgets, reason: 'its arrival, as without a talk: ${play.texts()}');
      }
      await tapText(t, search.startLabel, after: const Duration(milliseconds: 900));
      expect(find.byKey(const ValueKey('investigation-picture')), findsOneWidget, reason: play.texts());
    });
  });
}
