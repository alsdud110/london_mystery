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
import 'package:world_mystery/data/models/case_talk.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/data/models/scene_explore.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/result/case_solved_screen.dart';

import '../../tool/season_gen/content_hash.dart';
import '../../tool/season_gen/generate_case.dart';
import '../../tool/season_gen/plan_files.dart';
import '../../tool/season_gen/plan_models.dart';
import '../../tool/season_gen/play_check.dart';
import '../full_playthrough_test.dart' show tapText, wait;
import '../helpers.dart';
import '../mission_play.dart';
import 'generated/s3_rome_slice/s3_ep05.g.dart';
import 'rome_slice_season.dart';
import 'sandbox_play.dart';

/// STEP 3-15A: Rome's first playable case, from its plan to the screen.
/// Case 05 ("The Cat Who Knew") of `content_pipeline/seasons/s3_rome/`, made
/// by the generator (`--slice`) on the pictures the asset pipeline drew
/// (`cat_ruins`, `cast_workshop`, the three cats): M1 a look round of the
/// cat ruins, its places measured on the drawn picture; M2 letter tiles at
/// the same ruins; M3 a talk with Carla, then an order; the final's dials
/// and its ending. Carla's portrait is not drawn yet: her lines show no face.
void main() {
  const seasonDir = 'content_pipeline/seasons/s3_rome';
  const seasonPath = '$seasonDir/season.plan.json';
  const casePath = '$seasonDir/cases/s3_ep05/case.plan.json';
  final plan = PlanFiles.loadCasePlan(casePath);
  final case05 = Episode.fromJson(s3Ep05Json);
  MissionPlan planOf(String id) => plan.allMissions.firstWhere((m) => m.missionId == id);

  group('the generated case', () {
    test('is what the Rome plans make now (generate_case --slice --check)', () {
      final made = CaseGenerator.sandbox(seasonPath: seasonPath, casePaths: [casePath], slice: true);
      expect(made.defaultDir, 'test/sandbox/generated/s3_rome_slice');
      expect(GeneratedFiles.stale(made.defaultDir, made.files), isEmpty,
          reason: 'run: dart run tool/season_gen/generate_case.dart --season $seasonPath --target sandbox --slice $casePath');
      final manifest = jsonDecode(made.files[manifestName]!) as Map;
      expect(manifest['slice'], isTrue);
      expect(manifest['cases'], ['s3_ep05']);
      expect(romeSliceContent.places.keys, {'s3_rome.cat_ruins', 's3_rome.cast_workshop'}, reason: 'the places Case 05 uses, no other');
      // The season itself is made apart (STEP 3-15B B3, s3_rome_season_test.dart):
      // the slice never writes there, nor the season here.
      expect(made.defaultDir, isNot('test/sandbox/generated/s3_rome'));
    });

    test('M1 is a look round on the drawn cat ruins, its places measured on that very file', () {
      final m1 = planOf('s3_ep05_m1');
      final ep = m1.play!.explore!;
      final explore = s3Ep05Explores['s3_ep05_m1']!;
      final file = File(ep.picture.file);
      expect(explore.picture, 'assets/seasons/season_03_rome/locations/cat_ruins.png');
      expect(PlayCheck.pngSize(file), (1536, 1024));
      expect(ep.picture.measuredOn, ContentHash.ofBytes(file.readAsBytesSync()), reason: 'measured on the file the game shows');
      expect(m1.puzzle.notes.any((n) => n.contains('UNMEASURED')), isFalse);
      Rect px(SceneRect r) => Rect.fromLTRB(r.left / 1536, r.top / 1024, r.right / 1536, r.bottom / 1024);
      for (final (i, s) in explore.spots.indexed) {
        expect(s.areas, [for (final r in ep.spots[i].areas) px(r)], reason: s.id);
      }
      expect(explore.document!.id, 'board');
      expect([for (final c in explore.choices) c.picture], [
        'assets/seasons/season_03_rome/cases/case_05/cat_rosso.png',
        'assets/seasons/season_03_rome/cases/case_05/cat_tito.png',
        'assets/seasons/season_03_rome/cases/case_05/cat_luna.png',
      ]);
      for (final c in explore.choices) {
        expect(PlayCheck.pngSize(File(c.picture)), (1024, 1024), reason: c.picture);
      }
    });

    test('Carla\'s face, drawn in STEP 3-15B B1, is written into her talk and her ending lines, never another face', () {
      const carla = 'assets/seasons/season_03_rome/characters/carla_base.png';
      expect(File(carla).existsSync(), isTrue);
      expect(planOf('s3_ep05_m3').play!.talk!.portrait, carla);
      final talk = romeSliceContent.talkMissions['s3_ep05_m3']!;
      expect(talk.before!.speaker.portraits, {'base': carla});
      final plannedFaces = [for (final l in plan.finalMission.play!.ending) l.portrait];
      expect([for (final l in romeSliceContent.endings['s3_ep05_final']!) l.portrait], plannedFaces, reason: 'each line the face its plan names');
      expect(plannedFaces.whereType<String>(), everyElement(carla));
    });

    test('the game finds nothing wrong: its validator, engine choice and bundled pictures', () {
      // One finding, of the slice itself: a season's cases are numbered from
      // its first, and this slice holds Case 05 alone. Nothing else.
      expect([for (final i in SeasonContentValidator.validate(romeSliceContent)) (i.rule, i.caseId, i.message)], [
        ('case', 's3_ep05', 'Case 05 is case 1 of the season'),
      ]);
      final engines = {for (final s in PuzzleEngineCollisionCheck.slotsOf(romeSliceContent)) s.mission.id: s.active?.engine};
      expect(engines['s3_ep05_m1'], 'SceneExplore');
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final folders = [for (final m in RegExp(r'^\s+- (assets/\S+/)\s*$', multiLine: true).allMatches(pubspec)) m[1]!];
      final files = {
        for (final p in romeSliceContent.places.values) p.file,
        for (final s in s3Ep05Explores.values) ...[s.picture, for (final c in s.choices) c.picture],
      };
      for (final f in files) {
        expect(File(f).existsSync(), isTrue, reason: f);
        expect(folders.any((d) => f.startsWith(d) && !f.substring(d.length).contains('/')), isTrue, reason: '$f is not in a pubspec assets folder');
      }
    });
  });

  group('played in the real app', () {

    Future<(ProviderContainer, SharedPreferences, Future<ProviderContainer> Function())> open(WidgetTester t, Size size, double ratio) async {
      WidgetController.hitTestWarningShouldBeFatal = true; // every tap must land
      addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
      t.view.physicalSize = size;
      t.view.devicePixelRatio = ratio;
      addTearDown(t.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      Future<ProviderContainer> start() async {
        final c = ProviderContainer(overrides: [...await testOverridesFor(prefs), ...romeSliceOverrides()]);
        addTearDown(c.dispose);
        c.read(seasonPreviewSwitchProvider.notifier).set(true); // Rome opens without Paris solved
        // Case 05 of the season in the game opens after Case 04: operator
        // access (test builds only) opens it directly, as the slice did.
        c.read(operatorAccessSwitchProvider.notifier).set(true);
        return c;
      }

      final c = await start();
      final ctrl = c.read(gameControllerProvider.notifier);
      ctrl.createDetective('Kim', DetectiveAvatar.girl);
      expect(ctrl.openSeason(romeSliceSeasonId), isTrue);
      expect(ctrl.openEpisode(case05.id), isTrue);
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: const WorldMysteryApp()));
      await wait(t);
      return (c, prefs, start);
    }

    Future<void> throughIntro(WidgetTester t, ProviderContainer c, SandboxPlay play) async {
      c.read(routerProvider).go(Routes.intro);
      await wait(t, const Duration(milliseconds: 1500));
      await tapText(t, 'SKIP ›');
      for (final line in case05.intro) {
        expect(findReadableContaining(line), findsWidgets, reason: 'intro "$line": ${play.texts()}');
      }
      await tapText(t, "I'M READY", after: const Duration(milliseconds: 2000));
    }

    /// M1 from the map: the cats locked until the board is read, the board,
    /// a wrong cat (its own line), Tito, and the Discovery Moment.
    Future<void> lookRound(WidgetTester t, ProviderContainer c, SandboxPlay play) async {
      final m1 = case05.missions[0];
      final engine = MissionPlay();
      await play.toPlace(m1);
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      expect(find.byKey(const ValueKey('explore-picture')), findsOneWidget, reason: 'the cat ruins, looked round: ${play.texts()}');
      final picture = find.descendant(of: find.byKey(const ValueKey('explore-picture')), matching: find.byType(Image));
      expect(((t.widget<Image>(picture.first)).image as AssetImage).assetName, 'assets/seasons/season_03_rome/locations/cat_ruins.png');
      final explore = s3Ep05Explores[m1.id]!;
      await engine.tapExplore(t, explore.spots.firstWhere((s) => s.kind == ExploreKind.choice).areas.first.center);
      expect(findReadableContaining('Read something first'), findsWidgets, reason: play.texts());
      // The board, read where it hangs: the three cats it names.
      await engine.tapExplore(t, explore.document!.areas.first.center);
      if (engine.sealedLetter().evaluate().isNotEmpty) {
        await t.tap(engine.sealedLetter());
        await wait(t, const Duration(milliseconds: 1200));
      }
      expect(findReadableContaining('TITO'), findsWidgets, reason: 'the board read: ${play.texts()}');
      await engine.tapKey(t, 'explore-close', after: const Duration(milliseconds: 500));
      await engine.chooseInExplore(t, explore, 'rosso');
      expect(find.text('Not quite!'), findsOneWidget, reason: play.texts());
      expect(findReadableContaining('look at its tail'), findsWidgets, reason: play.texts());
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
      await engine.chooseInExplore(t, explore, m1.answer);
      final d = romeSliceContent.discoveries[m1.id]!;
      await wait(t, const Duration(milliseconds: 1500));
      expect(findReadableContaining(d.title), findsWidgets, reason: 'M1 discovery: ${play.texts()}');
      expect(findReadableContaining(d.detail), findsWidgets, reason: 'M1 discovery: ${play.texts()}');
      expect(c.read(gameControllerProvider).isCompleted(m1.id), isTrue);
    }

    testWidgets('Case 05 from the map on a phone: the look round, a restart, the tiles, Carla\'s talk, the order, the dials, the ending',
        (t) async {
      var (c, prefs, start) = await open(t, const Size(1170, 2532), 3);
      final play = SandboxPlay(t);
      final [m1, m2, m3] = case05.missions;
      GameProgress progress() => c.read(gameControllerProvider);
      await throughIntro(t, c, play);

      // ── M1, the look round.
      await lookRound(t, c, play);
      await play.onToMap(m1);

      // ── Saved, and taken up again after a restart: M2 is next.
      final saved = savedString(prefs, AppConstants.progressKeyFor(case05.id))!;
      expect((jsonDecode(saved) as Map)['completedMissionIds'], [m1.id]);
      expect(progress().attempts[m1.id], 2, reason: 'the wrong cat, then Tito');
      c = await start();
      expect(c.read(gameControllerProvider.notifier).openSeason(romeSliceSeasonId), isTrue);
      expect(c.read(currentEpisodeProvider).id, case05.id, reason: 'the open case is kept');
      expect(progress().completedMissionIds, [m1.id]);
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: const WorldMysteryApp()));
      await wait(t);
      c.read(routerProvider).go(Routes.map);
      await wait(t, const Duration(milliseconds: 2500));

      // ── M2, Tito's tag: letter tiles at the same ruins.
      await play.toPuzzle(m2);
      await play.answer(m2, m2.answer);
      await wait(t, const Duration(milliseconds: 1500));
      expect(findReadableContaining(romeSliceContent.discoveries[m2.id]!.title), findsWidgets, reason: play.texts());
      await play.onToMap(m2);

      // ── M3, Carla's talk (no face drawn yet), her sign, the order.
      final talk = romeSliceContent.talkMissions[m3.id]!;
      await play.toPlace(m3);
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      expect(find.byKey(const ValueKey('case-talk-goal')), findsOneWidget, reason: 'the talk comes first: ${play.texts()}');
      Future<void> hear(TalkScene scene, String finish) async {
        for (final (i, line) in scene.opening.indexed) {
          if (find.text('READ ALL').evaluate().isNotEmpty) await tapText(t, 'READ ALL', after: const Duration(milliseconds: 300));
          expect(findReadableContaining(line.text), findsWidgets, reason: '${scene.id} line $i: ${play.texts()}');
          if (i < scene.opening.length - 1) await tapText(t, 'NEXT', after: const Duration(milliseconds: 300));
        }
        await tapText(t, finish, after: const Duration(milliseconds: 1200));
      }

      await hear(talk.before!, 'READ THE SIGN');
      await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
      await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
      await play.answer(m3, m3.answer);
      if (talk.after case final after?) {
        await wait(t, const Duration(milliseconds: 600));
        await hear(after, after.finishLabel);
      }
      await wait(t, const Duration(milliseconds: 1500));
      expect(findReadableContaining(romeSliceContent.discoveries[m3.id]!.title), findsWidgets, reason: play.texts());
      await play.onToMap(m3);

      // ── The final: the dials, then the ending; the case closes once it is seen.
      final fin = case05.finalMission;
      await play.toFinal(fin);
      await play.answer(fin, fin.answer);
      await wait(t, const Duration(milliseconds: 1500));
      expect(find.byKey(const ValueKey('final-ending')), findsOneWidget, reason: play.texts());
      final ending = romeSliceContent.endings[fin.id]!;
      for (final (i, line) in ending.indexed) {
        if (find.text('READ ALL').evaluate().isNotEmpty) await tapText(t, 'READ ALL', after: const Duration(milliseconds: 300));
        expect(findReadableContaining(line.text), findsWidgets, reason: 'ending line $i: ${play.texts()}');
        if (i < ending.length - 1) await tapText(t, 'NEXT', after: const Duration(milliseconds: 600));
      }
      await tapText(t, 'CLOSE THE CASE', after: const Duration(milliseconds: 1500));
      expect(progress().isCaseSolved, isTrue);
      expect(find.text('CASE 05 COMPLETE'), findsOneWidget, reason: play.texts());
      await t.tapAt(t.getCenter(find.byType(Scaffold).last));
      await wait(t, const Duration(milliseconds: 1200));
      await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 3200));
      expect(find.byType(CaseSolvedScreen), findsOneWidget);

      // ── Saved: the case and its clues; London and Paris never written.
      expect(progress().completedMissionIds, [for (final m in case05.allMissions) m.id]);
      expect([for (final x in progress().collectedClues(case05)) x.id], [for (final m in plan.allMissions) ?m.clueOutputs.clue],
          reason: 'the plan\'s clues: M1–M3 leave one each, the final evidence only');
      expect(c.read(seasonProvider).solvedEpisodeIds, [case05.id]);
      for (final e in [for (final s in SeasonCatalog.all) ...s.episodes.keys]) {
        expect(prefs.getKeys().where((k) => k.endsWith(AppConstants.progressKeyFor(e))), isEmpty, reason: '$e (London, Paris) is never written');
      }
    });

    for (final (name, size, ratio) in [('a small phone', const Size(750, 1334), 2.0), ('a tablet', const Size(2048, 2732), 2.0)]) {
      testWidgets('M1\'s look round on $name: every place reached by a tap, solved', (t) async {
        final (c, _, _) = await open(t, size, ratio);
        final play = SandboxPlay(t);
        await throughIntro(t, c, play);
        await lookRound(t, c, play);
      });
    }
  });
}
