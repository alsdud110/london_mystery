import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/content/puzzle_engine_collisions.dart';
import 'package:world_mystery/data/content/season_content_validator.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/dialogue.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/data/models/scene_explore.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/result/case_solved_screen.dart';

import '../../tool/season_gen/generate_case.dart';
import '../../tool/season_gen/plan_files.dart';
import '../../tool/season_gen/plan_models.dart';
import '../../tool/season_gen/season_cases.dart';
import '../full_playthrough_test.dart' show reveal, tapText, wait;
import '../helpers.dart';
import '../mission_play.dart';
import 'generated/s9_sandbox/s9_ep03.g.dart';
import 'sandbox_play.dart';
import 'sandbox_season.dart';

/// STEP 3-13: the puzzles played on pictures, made by the generator from a
/// plan and played in the real app. Case 03 of the sandbox ("The Travelling
/// Book") is a look round (M1, `explores`), a search (M2, `investigations`,
/// its room a picture file), a talk with witnesses (M3, `dialogues`), a
/// picture choice with hidden names (M4, `imageChoice` with picture files)
/// and a text final whose answer is a statement heard in M3. Its scenes are
/// checked against the plan (places as the pictures' pixels), by the game's
/// own validator and engine choice, then played from the map with each
/// engine's own controls: hints, a wrong answer, back, a restart mid-case,
/// the case solved and its report.
void main() {
  const seasonDir = 'content_pipeline/seasons/s9_sandbox';
  const seasonPath = '$seasonDir/season.plan.json';
  final plan = PlanFiles.loadCasePlan('$seasonDir/cases/s9_ep03/case.plan.json');
  final case03 = Episode.fromJson(s9Ep03Json);
  MissionPlan planOf(String id) => plan.allMissions.firstWhere((m) => m.missionId == id);

  group('the generated case', () {
    test('is what the plans make now (generate_season --check), with its scene tables', () {
      final made = CaseGenerator.sandbox(seasonPath: seasonPath, casePaths: SeasonCases.of(seasonPath));
      expect(GeneratedFiles.stale('test/sandbox/generated/s9_sandbox', made.files), isEmpty,
          reason: 'run: dart run tool/season_gen/generate_season.dart --season $seasonPath --target sandbox');
      expect((jsonDecode(made.files[manifestName]!) as Map)['generatorVersion'], generatorVersion);
      expect(s9Ep03Explores.keys, ['s9_ep03_m1']);
      expect(s9Ep03Investigations.keys, ['s9_ep03_m2']);
      expect(s9Ep03Dialogues.keys, ['s9_ep03_m3']);
      expect(sandboxContent.explores.keys, ['s9_ep03_m1'], reason: 'the season takes every case\'s tables');
    });

    test('the game finds nothing wrong: its validator, engine choice and places', () {
      expect(SeasonContentValidator.validate(sandboxContent), isEmpty);
      final engines = {for (final s in PuzzleEngineCollisionCheck.slotsOf(sandboxContent)) if (s.caseId == 's9_ep03') s.mission.id: s.active?.engine};
      expect(engines, {
        's9_ep03_m1': 'SceneExplore',
        's9_ep03_m2': 'InvestigationSearch',
        's9_ep03_m3': 'DialogueInvestigation',
        's9_ep03_m4': 'ImageChoiceQuestion',
        's9_ep03_final': 'MultipleChoiceQuestion',
      });
      final slots = PuzzleEngineCollisionCheck.slotsOf(sandboxContent).where((s) => s.caseId == 's9_ep03');
      for (final s in slots) {
        expect(s.paletteId, planOf(s.mission.id).puzzle.paletteId, reason: s.mission.id);
      }
    });

    test('places on the pictures are the plan\'s pixels, as fractions of the same picture', () {
      Rect px(SceneRect r, int w, int h) => Rect.fromLTRB(r.left / w, r.top / h, r.right / w, r.bottom / h);
      final explore = s9Ep03Explores['s9_ep03_m1']!;
      final ep = planOf('s9_ep03_m1').play!.explore!;
      expect(explore.picture, ep.picture.file);
      expect((explore.pixels.width, explore.pixels.height), (1536.0, 1024.0));
      for (final (i, s) in explore.spots.indexed) {
        expect(s.areas, [for (final r in ep.spots[i].areas) px(r, 1536, 1024)], reason: s.id);
      }
      expect(explore.document!.id, 'suitcase');
      expect({for (final c in explore.choices) c.optionId}, {for (final o in case03.missions[0].options) o.id});
      expect(explore.pictureAspect, 1086 / 1448);

      final search = s9Ep03Investigations['s9_ep03_m2']!;
      expect(search.artwork, isNull, reason: 'a season\'s own room: its file, no Artwork');
      expect(search.picture, planOf('s9_ep03_m2').play!.search!.picture.file);
      expect(search.answer, case03.missions[1].answer, reason: 'the search ends with the puzzle\'s own answer');
      for (final f in search.finds) {
        expect(case03.missions[1].letter, contains(f.reportLine), reason: 'read in the letter, word for word: ${f.id}');
      }
      expect(search.finds.last.pictureAspect, 1024 / 1536);

      final talk = s9Ep03Dialogues['s9_ep03_m3']!;
      expect(talk.deduction.answer, case03.missions[2].answer);
      expect(talk.deduction.solves('flower_seller.carry', 'juggler.carry'), isTrue);
      expect(talk.matches('flower_seller.carry', 'juggler.carry'), isTrue);
      expect(talk.matches('baker.carry', 'juggler.carry'), isFalse);
      expect(talk.statements, hasLength(6), reason: '"when" tells the night, not a statement');
      expect(talk.deduction.then, {'juggler.wearing'});
    });

    test('a picture choice: its options are picture files, named for screen readers, shown unnamed', () {
      final m4 = case03.missions[3];
      expect(m4.type, MissionType.imageChoice);
      expect(m4.hideOptionNames, isTrue);
      for (final o in m4.options) {
        expect(o.artwork, isNull, reason: o.id);
        expect(o.picture, startsWith('assets/'), reason: o.id);
        expect(o.altText, isNotEmpty, reason: o.id);
        expect(File(o.picture!).existsSync(), isTrue, reason: o.picture);
      }
    });

    test('every picture it shows is bundled (pubspec folders)', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final folders = [for (final m in RegExp(r'^\s+- (assets/\S+/)\s*$', multiLine: true).allMatches(pubspec)) m[1]!];
      final files = <String>{
        for (final s in s9Ep03Explores.values) ...[s.picture, for (final c in s.choices) c.picture],
        for (final s in s9Ep03Investigations.values) ...[s.picture!, for (final f in s.finds) f.picture],
        for (final s in s9Ep03Dialogues.values) ...[s.background, for (final p in s.speakers) p.portrait],
        for (final o in case03.missions[3].options) o.picture!,
      };
      for (final f in files) {
        expect(folders.any((d) => f.startsWith(d) && !f.substring(d.length).contains('/')), isTrue, reason: '$f is not in a pubspec assets folder');
      }
    });
  });

  group('played in the real app', () {
    setUp(registerSandboxSeason);
    tearDown(unregisterSandboxSeason);

    testWidgets('Case 03 from the map: a look round, a search, a talk, a picture choice, the final, its report', (t) async {
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

      var c = await start();
      var ctrl = c.read(gameControllerProvider.notifier);
      ctrl.createDetective('Kim', DetectiveAvatar.girl);
      expect(ctrl.openSeason(sandboxSeasonId), isTrue);
      // Cases 01 and 02 solved through the game's own answers (their play is
      // s9_multi_case_test's): Case 03 is opened by them.
      final [case01, case02, _] = sandboxEpisodes();
      for (final e in [case01, case02]) {
        expect(ctrl.openEpisode(e.id), isTrue, reason: e.id);
        ctrl.startInvestigation();
        for (final m in e.allMissions) {
          expect(ctrl.submitAnswer(m, m.answer).result.name, 'correct', reason: m.id);
        }
        // A final with an ending (Case 02, STEP 3-13B) closes its case once
        // the ending is seen, as its page does (s9_presentation_test plays it).
        if (SeasonCatalog.caseEnding(e.finalMission) != null) {
          expect(ctrl.closeCase(GameProgress.examinedKey(e.finalMission.id, 'ending')), isTrue, reason: e.id);
        }
      }
      expect(c.read(seasonProvider).solvedEpisodeIds, ['s9_ep01', 's9_ep02']);
      expect(ctrl.openEpisode('s9_ep03'), isTrue);

      await t.pumpWidget(UncontrolledProviderScope(container: c, child: const WorldMysteryApp()));
      await wait(t);
      var router = c.read(routerProvider);
      String path() => router.routerDelegate.currentConfiguration.uri.path;
      final play = SandboxPlay(t);
      final engine = MissionPlay();
      final [m1, m2, m3, m4] = case03.missions;

      router.go(Routes.intro);
      await wait(t, const Duration(milliseconds: 1500));
      await tapText(t, 'SKIP ›');
      for (final line in case03.intro) {
        expect(findReadableContaining(line), findsWidgets, reason: 'intro "$line": ${play.texts()}');
      }
      await tapText(t, "I'M READY", after: const Duration(milliseconds: 2000));

      // ── M1, a look round: the letter is in the suitcase; the posters open once it is read.
      await play.toPlace(m1);
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      expect(find.byKey(const ValueKey('explore-picture')), findsOneWidget, reason: 'the station, looked round: ${play.texts()}');
      expect(find.text('TAP TO OPEN'), findsNothing, reason: 'no envelope: the letter is in the suitcase');
      final explore = s9Ep03Explores[m1.id]!;
      // The posters before the letter: the scene's own locked line.
      await engine.tapExplore(t, explore.spots.firstWhere((s) => s.kind == ExploreKind.choice).areas.first.center);
      expect(findReadableContaining('Find a clue first'), findsWidgets, reason: play.texts());
      await engine.readExploreDocument(t, explore);
      // A wrong poster first: its own line, and the scene stays open.
      await engine.chooseInExplore(t, explore, 'wheels');
      expect(find.text('Not quite!'), findsOneWidget, reason: play.texts());
      expect(findReadableContaining('trains or buses'), findsWidgets, reason: play.texts());
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
      await engine.chooseInExplore(t, explore, m1.answer);
      await play.onToMap(m1);
      expect(c.read(gameControllerProvider).isCompleted(m1.id), isTrue);

      // ── M2, a search of the gallery (a picture file, no Artwork): each thing where its line says.
      await play.toPlace(m2);
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 3000));
      final search = s9Ep03Investigations[m2.id]!;
      // Arriving: why the report is read, then the report itself.
      for (final line in search.arrival) {
        expect(findReadableContaining(line), findsWidgets, reason: play.texts());
      }
      await tapText(t, search.startLabel, after: const Duration(milliseconds: 900));
      expect(find.byKey(const ValueKey('investigation-picture')), findsOneWidget, reason: play.texts());
      await engine.tapInPicture(t, search.finds.first.areas.first.center);
      await engine.closeFindCard(t);
      // Back to the report: what was found stays found.
      await t.tap(find.byTooltip('Back'));
      await wait(t, const Duration(milliseconds: 1700));
      await tapText(t, search.startLabel, after: const Duration(milliseconds: 900));
      for (final f in search.finds.skip(1)) {
        await engine.tapInPicture(t, f.areas.first.center);
        await engine.closeFindCard(t);
      }
      await wait(t, const Duration(milliseconds: 1200));
      await play.onToMap(m2);
      expect(c.read(gameControllerProvider).isCompleted(m2.id), isTrue);
      expect(c.read(gameControllerProvider).attempts[m2.id], 1, reason: 'a search is never a wrong answer');

      // ── A restart mid-case: the two solves are kept; M3 is next.
      final saved = savedString(prefs, AppConstants.progressKeyFor('s9_ep03'))!;
      expect((jsonDecode(saved) as Map)['completedMissionIds'], [m1.id, m2.id]);
      c = await start();
      ctrl = c.read(gameControllerProvider.notifier);
      expect(ctrl.openSeason(sandboxSeasonId), isTrue);
      expect(c.read(currentEpisodeProvider).id, 's9_ep03', reason: 'the open case is kept');
      expect(c.read(gameControllerProvider).completedMissionIds, [m1.id, m2.id]);
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: const WorldMysteryApp()));
      await wait(t);
      router = c.read(routerProvider);
      router.go(Routes.map);
      await wait(t, const Duration(milliseconds: 2500));

      // ── M3, a talk: the two who saw the same thing carried, then the grey hat still to hear.
      await play.toPlace(m3);
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      final talk = s9Ep03Dialogues[m3.id]!;
      await hearAndCompare(t, engine, talk);
      await play.onToMap(m3);
      expect(c.read(gameControllerProvider).isCompleted(m3.id), isTrue);

      // ── M4, a picture choice: the note read, a hint, a wrong picture, then the right one.
      await play.toPuzzle(m4);
      await tapText(t, 'Get a Free Hint', after: const Duration(milliseconds: 800));
      expect(c.read(gameControllerProvider).hintsFor(m4.id), 1);
      expect(findReadableContaining(m4.hints.first), findsWidgets, reason: play.texts());
      await pickPicture(t, m4, 'box');
      await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 400));
      expect(find.text('Not quite!'), findsOneWidget, reason: play.texts());
      expect(findReadableContaining('This box is red'), findsWidgets, reason: play.texts());
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
      await pickPicture(t, m4, m4.answer);
      await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 400));
      await play.onToMap(m4);

      // ── The final: the label's grey hat, answered from M3's notes.
      final fin = case03.finalMission;
      await play.toFinal(fin);
      await play.answer(fin, fin.answer);
      await wait(t, const Duration(milliseconds: 3500));
      expect(find.text('CASE SOLVED'), findsOneWidget, reason: play.texts());
      await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 1000));
      await t.tapAt(t.getCenter(find.byType(Scaffold).last));
      await wait(t, const Duration(milliseconds: 1200));
      expect(findReadableContaining(fin.transition.last), findsWidgets, reason: play.texts());
      await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 3200));
      expect(find.byType(CaseSolvedScreen), findsOneWidget);
      expect(findReadableContaining(case03.caseSummary!), findsWidgets, reason: play.texts());
      expect(path(), Routes.solved);

      // ── Saved: the case, its clues and evidence, the season.
      final s = c.read(gameControllerProvider);
      expect(s.completedMissionIds, [for (final m in case03.allMissions) m.id]);
      expect([for (final x in s.collectedClues(case03)) x.id], ['s9_ep03_c1', 's9_ep03_c2', 's9_ep03_c3', 's9_ep03_c4']);
      expect(c.read(seasonProvider).solvedEpisodeIds, ['s9_ep01', 's9_ep02', 's9_ep03']);
      for (final e in [for (final s in SeasonCatalog.all) ...s.episodes.keys]) {
        expect(prefs.getKeys().where((k) => k.endsWith(AppConstants.progressKeyFor(e))), isEmpty, reason: '$e (London, Paris) is never written');
      }
    });
  });
}

/// [talk] played as a child plays it: each statement of its answer and the
/// ones still to find after it heard (a witness chosen, then the question),
/// the two that answer it compared, and on.
Future<void> hearAndCompare(WidgetTester t, MissionPlay engine, DialogueScene talk) async {
  String speakerOf(String statement) => talk.statement(statement).speakerId;
  for (final s in [...talk.deduction.pair, ...talk.deduction.then]) {
    final lineup = find.byKey(ValueKey('lineup-${speakerOf(s)}'));
    final arriving = lineup.evaluate().isNotEmpty;
    await engine.tapKey(t, arriving ? 'lineup-${speakerOf(s)}' : 'speaker-${speakerOf(s)}', after: Duration(milliseconds: arriving ? 900 : 400));
    await engine.tapKey(t, 'question-${talk.statement(s).about}');
  }
  await engine.tapKey(t, 'compare-statements', after: const Duration(milliseconds: 600));
  for (final s in talk.deduction.pair) {
    await engine.tapKey(t, 'pick-$s');
  }
  await wait(t, const Duration(milliseconds: 2800));
  await engine.tapKey(t, 'continue-investigation', after: const Duration(milliseconds: 600));
  await wait(t, const Duration(milliseconds: 800));
}

/// [m]'s picture [optionId] tapped, found by what it shows (its names hidden).
Future<void> pickPicture(WidgetTester t, Mission m, String optionId) async {
  final i = m.options.indexWhere((o) => o.id == optionId);
  final picture = find.bySemanticsLabel('Picture ${String.fromCharCode(65 + i)}: ${m.options[i].altText}');
  await reveal(t, picture);
  await t.tap(picture);
  await wait(t, const Duration(milliseconds: 200));
}
