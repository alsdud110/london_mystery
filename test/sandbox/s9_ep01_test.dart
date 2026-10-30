import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/content/season_content_validator.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/data/models/season.dart' show SeasonIds;
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/result/case_solved_screen.dart';
import 'package:world_mystery/widgets/place_scenery.dart';
import 'package:world_mystery/widgets/scene_backdrop.dart';

import '../../tool/season_gen/generate_case.dart';
import '../../tool/season_gen/plan_files.dart';
import '../../tool/season_gen/season_cases.dart';
import '../full_playthrough_test.dart' show reveal, tapText, wait;
import '../helpers.dart';
import 'generated/s9_sandbox/s9_ep01.g.dart';
import 'sandbox_season.dart';

/// STEP 3-8: the sandbox case "The Lost Library Key", made by the Dart
/// generator from its plans (`content_pipeline/seasons/s9_sandbox/`), read
/// by the game's own models, checked by the game's own validator, and played
/// from its Story Intro to its Case Solved report in the real app (its
/// router, pages and puzzles), on in-memory storage.
void main() {
  const seasonDir = 'content_pipeline/seasons/s9_sandbox';
  const casePath = '$seasonDir/cases/s9_ep01/case.plan.json';
  final plan = PlanFiles.loadCasePlan(casePath);
  final game = Episode.fromJson(s9Ep01Json);

  group('the generated content', () {
    test('is what the plans make now, byte for byte (generate_season --check)', () {
      Generated make() => CaseGenerator.sandbox(seasonPath: '$seasonDir/season.plan.json', casePaths: SeasonCases.of('$seasonDir/season.plan.json'));
      final made = make();
      expect(made.files.keys, contains('s9_ep01.g.dart'));
      expect(GeneratedFiles.stale('test/sandbox/generated/s9_sandbox', made.files), isEmpty,
          reason: 'run: dart run tool/season_gen/generate_season.dart --season $seasonDir/season.plan.json --target sandbox');
      expect(make().files, made.files, reason: 'the same plans, the same bytes');
      final manifest = jsonDecode(made.files['generated.manifest.json']!) as Map;
      expect(manifest['approved'], isFalse, reason: 'drafts: sandbox content only');
    });

    test("is read by the game's models as it is written", () {
      expect(game.toJson(), s9Ep01Json, reason: 'nothing the generator wrote is lost or changed in reading');
      expect(sandboxContent.season.id, sandboxSeasonId);
      expect(game.seasonId, sandboxSeasonId);
    });

    test("keeps every rule of the game's own content validator", () {
      expect(SeasonContentValidator.validate(sandboxContent), isEmpty);
      expect(placeAssetProblems(sandboxContent.places), isEmpty, reason: 'every place picture is bundled, of its size');
    });

    test('is the plan: ids, order, answers, options, clues, learning', () {
      final missions = game.allMissions;
      expect([for (final m in missions) m.id], [for (final m in plan.allMissions) m.missionId]);
      for (final (i, (p, m)) in [for (var i = 0; i < missions.length; i++) (plan.allMissions[i], missions[i])].indexed) {
        final a = p.puzzle.answerSpec;
        expect(m.type.name, p.puzzle.missionType, reason: m.id);
        expect([m.answer, m.acceptedAnswers, m.codeLength], [a.answer, a.acceptedAnswers, a.codeLength], reason: m.id);
        expect([for (final o in m.options) (o.id, o.label, o.feedback)], [for (final o in a.options) (o.id, o.label, o.feedback)], reason: m.id);
        expect((m.clue?.id, m.evidence?.id), (p.clueOutputs.clue, p.clueOutputs.evidence), reason: m.id);
        expect(m.place, SeasonScene(p.placeId), reason: m.id);
        expect(m.nextMissionId, i + 1 < missions.length ? missions[i + 1].id : null, reason: m.id);
        expect(m.hints, p.play!.hints, reason: m.id);
        expect(sandboxContent.learning[m.id]!.objective, p.learning.objective, reason: m.id);
      }
      expect(game.intro, plan.play!.intro);
      expect(game.caseSummary, plan.play!.caseSummary);
      expect(sandboxContent.languageTopics['s9_ep01']!.title, plan.learningGoal.title);
    });

    test('names no other city, case or story', () {
      final text = jsonEncode(s9Ep01Json).toLowerCase();
      for (final word in ['london', 'paris', 'crown', 'clockmaker', 'big ben', 'eiffel']) {
        expect(text, isNot(contains(word)), reason: word);
      }
    });

    test('is not a season of the game: the catalog and its content are as they were', () {
      expect([for (final s in SeasonCatalog.all) s.id], [SeasonIds.london, SeasonIds.paris, SeasonIds.rome, SeasonIds.newyork], reason: 'Rome is in the game; the sandbox never');
      expect(SeasonCatalog.all.any((s) => s.episodes.containsKey('s9_ep01')), isFalse);
      expect(SeasonCatalog.testPlaces, isEmpty);
    });
  });

  group('played in the real app', () {
    setUp(registerSandboxPlaces);
    tearDown(SeasonCatalog.testPlaces.clear);

    /// Every text on screen (for a failing step's reason).
    String texts() => [
      for (final e in find.byType(Text).evaluate()) (e.widget as Text).data ?? (e.widget as Text).textSpan?.toPlainText() ?? '',
    ].where((s) => s.trim().isNotEmpty).join(' | ');

    bool sceneryOf(String file) => find
        .descendant(
          of: find.byType(PlaceScenery),
          matching: find.byWidgetPredicate((w) => w is SceneBackdrop && w.file == file, skipOffstage: false),
          skipOffstage: false,
        )
        .evaluate()
        .isNotEmpty;

    testWidgets('Story Intro → three missions → the final → Case Solved → the case report', (t) async {
      WidgetController.hitTestWarningShouldBeFatal = true; // every tap must land
      addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
      t.view.physicalSize = const Size(1170, 2532);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [...await testOverridesFor(prefs), ...sandboxOverrides()]);
      addTearDown(c.dispose);
      final ctrl = c.read(gameControllerProvider.notifier);
      ctrl.createDetective('Kim', DetectiveAvatar.girl);
      c.read(seasonPreviewSwitchProvider.notifier).set(true); // the sandbox opens unreleased
      expect(ctrl.openSeason(sandboxSeasonId), isTrue);
      expect(ctrl.openEpisode('s9_ep01'), isTrue);

      await t.pumpWidget(UncontrolledProviderScope(container: c, child: const WorldMysteryApp()));
      await wait(t);
      final router = c.read(routerProvider);
      final [m1, m2, m3, fin] = game.allMissions;
      Mission done(String id) => game.missionById(id)!;
      List<String> completed() => c.read(gameControllerProvider).completedMissionIds;
      String clueTitles() => [for (final x in c.read(gameControllerProvider).collectedClues(game)) x.id].join(',');

      // ── Story Intro: the case's own opening lines.
      router.go(Routes.intro);
      await wait(t, const Duration(milliseconds: 1500));
      await tapText(t, 'SKIP ›');
      for (final line in game.intro) {
        expect(findReadableContaining(line), findsWidgets, reason: 'the intro line "$line": ${texts()}');
      }
      await tapText(t, "I'M READY", after: const Duration(milliseconds: 2000));
      expect(router.routerDelegate.currentConfiguration.uri.path, Routes.map, reason: texts());

      /// From the map to the puzzle: GO TO the place, INVESTIGATE, the letter, SOLVE.
      Future<void> toPuzzle(Mission m) async {
        await t.tap(find.bySemanticsLabel('GO TO ${m.location}'));
        await wait(t, const Duration(milliseconds: 2800));
        expect(find.text('INVESTIGATE'), findsOneWidget, reason: '${m.id}: ${texts()}');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 700));
        await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
        expect(findReadableContaining(m.letter.split('\n').first), findsWidgets, reason: '${m.id} letter: ${texts()}');
        await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
        expect(find.text(m.question), findsOneWidget, reason: '${m.id}: ${texts()}');
      }

      /// The answer's Discovery Moment, the story after it (over the next
      /// mission's place), back to the map.
      Future<void> onToMap(Mission m) async {
        await wait(t, const Duration(milliseconds: 2800));
        await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 900));
        expect(findReadableContaining(m.transition.first), findsWidgets, reason: '${m.id} scene: ${texts()}');
        final ahead = done(m.nextMissionId!).place as SeasonScene;
        expect(sceneryOf(sandboxContent.places[ahead.id]!.file), isTrue, reason: '${m.id}: the scene lies over ${ahead.id}');
        await t.tapAt(const Offset(200, 400)); // skip typing
        await wait(t, const Duration(milliseconds: 900));
        await tapText(t, 'TO THE MAP', after: const Duration(milliseconds: 1200));
        await wait(t, const Duration(milliseconds: 3200)); // LOCKED → UNLOCKED
      }

      // ── Mission 1 (text_choice): a wrong option and its line, a hint, the answer.
      await toPuzzle(m1);
      await tapText(t, 'On the front desk', after: const Duration(milliseconds: 200));
      await tapText(t, 'CHECK ANSWER');
      expect(find.text('Not quite!'), findsOneWidget, reason: texts());
      expect(findReadableContaining('Is the desk by the window?'), findsWidgets, reason: texts());
      await tapText(t, 'GET MORE HINTS');
      await takeTipFromSheet(t);
      expect(findReadableContaining(m1.hints.first), findsWidgets, reason: 'the first hint: ${texts()}');
      await tapText(t, 'On the blue shelf by the window', after: const Duration(milliseconds: 200));
      await tapText(t, 'CHECK ANSWER', after: Duration.zero);
      await wait(t, const Duration(milliseconds: 400));
      expect(completed(), [m1.id]);
      expect(clueTitles(), 's9_ep01_c1', reason: "Ms. Rosa's note's clue in the notebook");
      await onToMap(m1);

      // ── Mission 2 (order_sequence), at the same desk and map pin as Mission 1:
      // the map paints with both pins, the solved mark stepped aside from
      // the current one (never under it).
      expect((m2.mapX, m2.mapY), (m1.mapX, m1.mapY), reason: 'one place, two missions');
      expect(t.takeException(), isNull, reason: 'the map paints');
      final solvedPin = find.byKey(ValueKey('pin-${m1.id}'));
      final currentPin = find.byKey(ValueKey('pin-${m2.id}'));
      expect(solvedPin, findsOneWidget);
      expect(currentPin, findsOneWidget);
      expect(t.getTopLeft(solvedPin), isNot(t.getTopLeft(currentPin)), reason: 'the solved mark steps aside');
      await toPuzzle(m2);
      for (final id in Mission.sequenceIds(m2.answer)) {
        final tile = find.text(m2.options.firstWhere((o) => o.id == id).label).last;
        await t.tap(tile);
        await t.pump(const Duration(milliseconds: 150));
      }
      await tapText(t, 'CHECK ANSWER', after: Duration.zero);
      await wait(t, const Duration(milliseconds: 400));
      expect(completed(), [m1.id, m2.id]);
      expect(clueTitles(), 's9_ep01_c1,s9_ep01_c2', reason: 'the ladder clue');
      await onToMap(m2);

      // ── Mission 3 (word_entry): PALM is a word of the same letters, and has its own line.
      await toPuzzle(m3);
      await t.enterText(find.byType(TextField), 'palm');
      await t.pump();
      await tapText(t, 'CHECK ANSWER');
      expect(findReadableContaining('A palm is a tree!'), findsWidgets, reason: texts());
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 500));
      await t.enterText(find.byType(TextField), 'LAMP');
      await t.pump();
      await tapText(t, 'CHECK ANSWER', after: Duration.zero);
      await wait(t, const Duration(milliseconds: 400));
      expect(completed(), [m1.id, m2.id, m3.id]);
      expect(clueTitles(), 's9_ep01_c1,s9_ep01_c2,s9_ep01_c3', reason: 'the job clue');
      await onToMap(m3);

      // ── The final (letter_tile_lock): B, E, L, L — the two L tiles each placed once.
      await tapText(t, 'OPEN THE FINAL CASE', after: Duration.zero);
      await wait(t, const Duration(milliseconds: 2800));
      expect(find.text(fin.question), findsWidgets, reason: texts());
      expect(find.text('THE LIBRARY LOCK'), findsOneWidget, reason: "the plate names the case's own lock");
      expect(find.textContaining('CLOCKMAKER'), findsNothing);
      for (final letter in fin.answer.split('')) {
        final tile = find.bySemanticsLabel('Letter $letter').first;
        await reveal(t, tile);
        await t.tap(tile);
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(find.bySemanticsLabel('Letter L'), findsNothing, reason: 'both L tiles are in the lock');
      expect(find.bySemanticsLabel(RegExp(r'^Letter lock, 4 slots: BELL')), findsOneWidget, reason: 'the lock spells BELL');
      await tapText(t, 'OPEN THE LOCK', after: const Duration(milliseconds: 3500));
      expect(find.text('CASE SOLVED'), findsOneWidget, reason: texts());
      expect(completed(), [m1.id, m2.id, m3.id, fin.id]);

      // ── After the case: its scene, then the Case Solved report.
      await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 1000));
      expect(find.text('CASE 01 COMPLETE'), findsOneWidget, reason: texts());
      await t.tapAt(t.getCenter(find.byType(Scaffold).last));
      await wait(t, const Duration(milliseconds: 1200));
      expect(findReadableContaining(fin.transition.last), findsWidgets, reason: texts());
      await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 3200));
      expect(find.byType(CaseSolvedScreen), findsOneWidget);
      expect(find.text('CASE CLOSED'), findsOneWidget, reason: texts());
      expect(findReadableContaining(game.caseSummary!), findsWidgets, reason: 'its own summary: ${texts()}');
      expect(findReadableContaining('London'), findsNothing, reason: 'no London line: ${texts()}');
      expect(findReadableContaining('crown'), findsNothing, reason: texts());

      // ── Saved: the case and the season, under the sandbox's own keys only.
      await wait(t, const Duration(milliseconds: 500));
      final progress = jsonDecode(savedString(prefs, AppConstants.progressKeyFor('s9_ep01'))!) as Map;
      expect(progress['completedMissionIds'], [for (final m in game.allMissions) m.id]);
      expect(c.read(seasonProvider).solvedEpisodeIds, ['s9_ep01']);
      for (final e in [for (final s in SeasonCatalog.all) ...s.episodes.keys]) {
        expect(prefs.getKeys().where((k) => k.endsWith(AppConstants.progressKeyFor(e))), isEmpty, reason: '$e is never written');
      }
      expect(done(fin.id).finale, isTrue);
    });
  });
}
