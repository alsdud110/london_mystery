import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/result/case_solved_screen.dart';

import '../../tool/season_gen/generate_case.dart';
import '../../tool/season_gen/plan_files.dart';
import '../../tool/season_gen/season_cases.dart';
import '../full_playthrough_test.dart' show reveal, tapText, wait;
import '../helpers.dart';
import 'generated/s9_sandbox/s9_ep02.g.dart';
import 'sandbox_play.dart';
import 'sandbox_season.dart';

/// STEP 3-9: the sandbox season's two cases, made together by
/// `tool/season_gen/generate_season.dart` from their plans. Case 02 ("The
/// Story Box Code", planned by Claude Code) is checked against its plan,
/// then both cases are played one after the other in the real app: Case 02
/// sealed, Case 01 solved, Case 02 opened by it, played to its report, and
/// each case's save, clues and evidence kept apart, through a restart and a
/// replay of Case 01.
void main() {
  const seasonDir = 'content_pipeline/seasons/s9_sandbox';
  const seasonPath = '$seasonDir/season.plan.json';
  final plan = PlanFiles.loadCasePlan('$seasonDir/cases/s9_ep02/case.plan.json');
  final case02 = Episode.fromJson(s9Ep02Json);

  group('the generated season', () {
    test('holds every case its folder has, in play order, made together (generate_season --check)', () {
      final cases = SeasonCases.of(seasonPath);
      expect(cases, ['$seasonDir/cases/s9_ep01/case.plan.json', '$seasonDir/cases/s9_ep02/case.plan.json']);
      final made = CaseGenerator.sandbox(seasonPath: seasonPath, casePaths: cases.reversed.toList());
      expect(made.files.keys, ['s9_sandbox_season.g.dart', 's9_ep01.g.dart', 's9_ep02.g.dart', 's9_sandbox_cases.g.dart', 'generated.manifest.json'],
          reason: 'in play order, whatever order they are given in');
      expect(GeneratedFiles.stale('test/sandbox/generated/s9_sandbox', made.files), isEmpty,
          reason: 'run: dart run tool/season_gen/generate_season.dart --season $seasonPath --target sandbox');
      final manifest = jsonDecode(made.files[manifestName]!) as Map;
      expect(manifest['cases'], ['s9_ep01', 's9_ep02']);
      expect((manifest['inputs'] as Map).keys, ['season.plan.json', 'cases/s9_ep01/case.plan.json', 'cases/s9_ep02/case.plan.json']);
      expect((manifest['outputs'] as Map).keys, [for (final f in made.files.keys) if (f != manifestName) f]);
      expect([for (final e in sandboxEpisodes()) e.id], ['s9_ep01', 's9_ep02'], reason: 'the game has both, from the generated list alone');
    });

    test('Case 02 is its plan: ids, order, answers, dials, clues, learning', () {
      final missions = case02.allMissions;
      expect([for (final m in missions) m.id], [for (final m in plan.allMissions) m.missionId]);
      for (final (i, p) in plan.allMissions.indexed) {
        final m = missions[i];
        final a = p.puzzle.answerSpec;
        expect(m.type.name, p.puzzle.missionType, reason: m.id);
        expect([m.answer, m.acceptedAnswers, m.codeLength, m.dialSymbols], [a.answer, a.acceptedAnswers, a.codeLength, a.dialSymbols], reason: m.id);
        expect([for (final o in m.options) (o.id, o.label, o.feedback)], [for (final o in a.options) (o.id, o.label, o.feedback)], reason: m.id);
        expect((m.clue?.id, m.evidence?.id), (p.clueOutputs.clue, p.clueOutputs.evidence), reason: m.id);
        expect(m.place, SeasonScene(p.placeId), reason: m.id);
        expect(m.hints, p.play!.hints, reason: m.id);
        expect(sandboxContent.learning[m.id]!.objective, p.learning.objective, reason: m.id);
      }
      expect(case02.number, 2);
      expect(case02.intro, plan.play!.intro);
      expect(sandboxContent.languageTopics['s9_ep02']!.title, plan.learningGoal.title);
      // Its one link across cases: the visitor book of Case 01.
      expect(sandboxContent.evidenceLinks['s9_ep02_e2']?.to, 's9_ep01_e2');
    });

    test('names no other city, case or story', () {
      final text = jsonEncode(s9Ep02Json).toLowerCase();
      for (final word in ['london', 'paris', 'crown', 'clockmaker', 'big ben', 'eiffel']) {
        expect(text, isNot(contains(word)), reason: word);
      }
      expect(case02.finalMission.dialSymbols, isNot(contains('gear')), reason: "the Clockmaker's mark");
    });
  });

  group('two cases played in the real app', () {
    setUp(registerSandboxPlaces);
    tearDown(SeasonCatalog.testPlaces.clear);

    testWidgets('Case 02 sealed → Case 01 solved → Case 02 opened and solved → saves kept apart, restart, replay', (t) async {
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
        return c;
      }

      /// The app started again on the same storage. The sandbox is an
      /// unreleased season: it opens with the season preview, which every
      /// start switches off (session only), so it is switched on again first.
      Future<ProviderContainer> restart() async {
        final c = await start();
        expect(c.read(gameControllerProvider).detectiveName, 'Kim', reason: 'the detective is kept');
        c.read(seasonPreviewSwitchProvider.notifier).set(true);
        expect(c.read(gameControllerProvider.notifier).openSeason(sandboxSeasonId), isTrue);
        return c;
      }

      final c = await start();
      final ctrl = c.read(gameControllerProvider.notifier);
      ctrl.createDetective('Kim', DetectiveAvatar.girl);
      c.read(seasonPreviewSwitchProvider.notifier).set(true); // the sandbox opens unreleased
      expect(ctrl.openSeason(sandboxSeasonId), isTrue);
      expect(c.read(operatorAccessProvider), isFalse, reason: "a player's unlocks, not the operator's");
      final [case01, _] = sandboxEpisodes();
      final play = SandboxPlay(t);

      // ── Case 02 sealed: refused by the game, sealed on the board and in the case files.
      expect(c.read(currentEpisodeProvider).id, 's9_ep01');
      expect(ctrl.openEpisode('s9_ep02'), isFalse);
      expect(c.read(currentEpisodeProvider).id, 's9_ep01');

      await t.pumpWidget(UncontrolledProviderScope(container: c, child: const WorldMysteryApp()));
      await wait(t);
      final router = c.read(routerProvider);
      String path() => router.routerDelegate.currentConfiguration.uri.path;
      // (The season's board shows once it is begun: before, its cover.)
      router.go(Routes.episodes);
      await wait(t, const Duration(milliseconds: 1500));
      expect(find.bySemanticsLabel('Case 2, The Story Box Code, sealed'), findsOneWidget, reason: play.texts());
      expect(find.text('SEALED'), findsOneWidget);

      // ── Case 01, played through (its own checks are s9_ep01_test's).
      expect(ctrl.openEpisode('s9_ep01'), isTrue);
      await playCase(t, play, router, case01, (m) => m.answer);
      expect(path(), Routes.solved, reason: play.texts());

      // ── Case 01 solved: Case 02 is open, the board shows it as the current case.
      expect(c.read(seasonProvider).solvedEpisodeIds, ['s9_ep01']);
      expect(c.read(seasonProvider.notifier).isUnlocked('s9_ep02'), isTrue);
      await reveal(t, find.text('OPEN CASE 02')); // under the report
      expect(find.text('OPEN CASE 02'), findsOneWidget, reason: play.texts());
      // A restart now: the unlock was saved.
      {
        final restarted = await restart();
        expect(restarted.read(seasonProvider).solvedEpisodeIds, ['s9_ep01']);
        expect(restarted.read(seasonProvider.notifier).isUnlocked('s9_ep02'), isTrue, reason: 'still open after a restart');
      }
      await tapText(t, 'OPEN CASE 02', after: const Duration(milliseconds: 4000));
      expect(path(), Routes.season, reason: play.texts());
      expect(find.bySemanticsLabel('Case 02, The Story Box Code, current case'), findsOneWidget, reason: play.texts());
      expect(find.bySemanticsLabel('Case 01, The Lost Library Key, solved'), findsOneWidget, reason: play.texts());
      await tapText(t, 'BEGIN INVESTIGATION', after: const Duration(milliseconds: 1500));
      expect(c.read(currentEpisodeProvider).id, 's9_ep02', reason: 'opened by its own button, as a player does');

      // ── Case 02: each puzzle with a wrong try first (its own line), then the answer.
      await playCase(t, play, router, case02, (m) => m.answer, wrongFirst: {
        's9_ep02_m1': ('lamp,book,shelf', 'Find First, Then and Last.'),
        's9_ep02_m2': ('two', 'Is 9:40 before 9:20?'),
        's9_ep02_m3': ('FUOR', 'Read them from the top line down.'),
        's9_ep02_final': ('144', 'Mr. Bell fixed one.'),
      }, fromIntro: false);
      await reveal(t, find.text('CASE 03 · COMING SOON')); // under the report
      expect(find.text('CASE 03 · COMING SOON'), findsOneWidget, reason: 'the season goes on, its next case not written yet: ${play.texts()}');

      // ── Saved: each case under its own key, its own missions, clues and evidence.
      await wait(t, const Duration(milliseconds: 500));
      Map<String, Object?> saved(String id) => jsonDecode(savedString(prefs, AppConstants.progressKeyFor(id))!) as Map<String, Object?>;
      expect(saved('s9_ep01')['completedMissionIds'], [for (final m in case01.allMissions) m.id]);
      expect(saved('s9_ep02')['completedMissionIds'], [for (final m in case02.allMissions) m.id]);
      final s02 = c.read(gameControllerProvider);
      expect([for (final x in s02.collectedClues(case02)) x.id], ['s9_ep02_c1', 's9_ep02_c2', 's9_ep02_c3'], reason: "Case 02's notebook holds its own clues only");
      expect(s02.collectedClues(case01), isEmpty, reason: "Case 01's clues are in Case 01's save, not Case 02's");
      expect(c.read(seasonProvider).solvedEpisodeIds, ['s9_ep01', 's9_ep02'], reason: 'Case 01 stays solved');
      for (final e in [for (final s in SeasonCatalog.all) ...s.episodes.keys]) {
        expect(prefs.getKeys().where((k) => k.endsWith(AppConstants.progressKeyFor(e))), isEmpty, reason: '$e (London, Paris) is never written');
      }
      final case02Save = savedString(prefs, AppConstants.progressKeyFor('s9_ep02'));

      // ── A restart: both cases solved, each save as it was.
      final again = await restart();
      expect(again.read(seasonProvider).solvedEpisodeIds, ['s9_ep01', 's9_ep02']);
      expect(again.read(currentEpisodeProvider).id, 's9_ep02', reason: 'the open case file is kept');
      expect(again.read(gameControllerProvider).isCaseSolved, isTrue);

      // ── Case 01 played again: its save starts over, Case 02's is untouched and still open.
      final ctrl2 = again.read(gameControllerProvider.notifier);
      expect(ctrl2.openEpisode('s9_ep01'), isTrue);
      ctrl2.playAgain();
      expect(again.read(gameControllerProvider).completedMissionIds, isEmpty, reason: 'Case 01 from its start');
      expect(savedString(prefs, AppConstants.progressKeyFor('s9_ep02')), case02Save, reason: "Case 02's save is as it was");
      expect(again.read(seasonProvider.notifier).isUnlocked('s9_ep02'), isTrue);
      expect(again.read(seasonProvider).solvedEpisodeIds, containsAll(['s9_ep01', 's9_ep02']));
      expect(ctrl2.openEpisode('s9_ep02'), isTrue);
      expect(again.read(gameControllerProvider).completedMissionIds, [for (final m in case02.allMissions) m.id]);
    });
  });
}

/// [episode] played in the real app from its Story Intro (or, with
/// [fromIntro] false, from the intro the case's own button opened) to its
/// Case Solved report: every mission from the map, [wrongFirst] tried first
/// where given (the wrong answer and a part of its line), then [answerOf].
Future<void> playCase(
  WidgetTester t,
  SandboxPlay play,
  GoRouter router,
  Episode episode,
  String Function(Mission mission) answerOf, {
  Map<String, (String, String)> wrongFirst = const {},
  bool fromIntro = true,
}) async {
  if (fromIntro) {
    router.go(Routes.intro);
    await wait(t, const Duration(milliseconds: 1500));
  }
  await tapText(t, 'SKIP ›');
  for (final line in episode.intro) {
    expect(findReadableContaining(line), findsWidgets, reason: '${episode.id} intro "$line": ${play.texts()}');
  }
  await tapText(t, "I'M READY", after: const Duration(milliseconds: 2000));

  for (final m in episode.missions) {
    await play.toPuzzle(m);
    if (wrongFirst[m.id] case (final answer, final line)) await play.wrong(m, answer, line: line);
    await play.answer(m, answerOf(m));
    await play.onToMap(m);
  }
  final fin = episode.finalMission;
  await play.toFinal(fin);
  expect(findReadableContaining(fin.letter.split('\n').first), findsWidgets, reason: '${fin.id} letter: ${play.texts()}');
  if (wrongFirst[fin.id] case (final answer, final line)) await play.wrong(fin, answer, line: line);
  await play.answer(fin, answerOf(fin));
  await wait(t, const Duration(milliseconds: 3500));
  expect(find.text('CASE SOLVED'), findsOneWidget, reason: '${episode.id}: ${play.texts()}');

  await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 1000));
  expect(find.text('CASE ${episode.numberLabel} COMPLETE'), findsOneWidget, reason: play.texts());
  await t.tapAt(t.getCenter(find.byType(Scaffold).last));
  await wait(t, const Duration(milliseconds: 1200));
  expect(findReadableContaining(fin.transition.last), findsWidgets, reason: play.texts());
  await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 3200));
  expect(find.byType(CaseSolvedScreen), findsOneWidget);
  expect(find.text('CASE CLOSED'), findsOneWidget, reason: play.texts());
  expect(findReadableContaining(episode.caseSummary!), findsWidgets, reason: 'its own summary: ${play.texts()}');
}
