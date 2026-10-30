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
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/data/models/scene_explore.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/result/case_solved_screen.dart';
import 'package:world_mystery/features/season/season_overview.dart';

import '../../tool/season_gen/content_hash.dart';
import '../../tool/season_gen/generate_case.dart';
import '../../tool/season_gen/plan_files.dart';
import '../../tool/season_gen/plan_models.dart';
import '../../tool/season_gen/play_check.dart';
import '../../tool/season_gen/season_cases.dart';
import '../full_playthrough_test.dart' show reveal, tapText, wait;
import '../helpers.dart';
import '../mission_play.dart';
import 'rome_season.dart';
import 's9_ep03_test.dart' show hearAndCompare;
import 'sandbox_play.dart';

/// STEP 3-15B B3: Rome, the whole season, from its plans to the screen, on
/// the pictures the asset pipeline drew. Made by the season's own path
/// (`plan_season.dart generate`, that is `generate_season.dart --target
/// sandbox`), no longer a slice. Played in order in the real app: each case
/// from its Story Intro, every mission from the map on its own place's
/// picture (talks, letters, the witnesses of Case 01, the four look rounds,
/// the three picture choices), a wrong answer and a hint in every case, every
/// Discovery Moment, each final and its ending, the report, the next case
/// opened by it, the save kept across restarts, the season complete after
/// Case 12 and a solved case opened again. The four measured look rounds are
/// played again on other screens.
void main() {
  const seasonDir = 'content_pipeline/seasons/s3_rome';
  const seasonPath = '$seasonDir/season.plan.json';
  const outDir = 'test/sandbox/generated/s3_rome';
  final casePaths = SeasonCases.of(seasonPath);
  final plans = [for (final p in casePaths) PlanFiles.loadCasePlan(p)];
  final episodes = romeEpisodes();
  final content = romeContent;
  MissionPlan planOf(String id) => [for (final p in plans) ...p.allMissions].firstWhere((m) => m.missionId == id);

  /// The four look rounds, each measured on the very file the game shows.
  const measured = [
    ('s3_ep01_m3', 'assets/seasons/season_03_rome/locations/map_hall.png'),
    ('s3_ep04_m1', 'assets/seasons/season_03_rome/locations/pantheon_hall.png'),
    ('s3_ep05_m1', 'assets/seasons/season_03_rome/locations/cat_ruins.png'),
    ('s3_ep10_m1', 'assets/seasons/season_03_rome/locations/civetta_square.png'),
  ];

  group('the generated season', () {
    test('is what the Rome plans make now, the whole season (generate_season --check)', () {
      final made = CaseGenerator.sandbox(seasonPath: seasonPath, casePaths: casePaths);
      expect(GeneratedFiles.stale(outDir, made.files), isEmpty,
          reason: 'run: dart run tool/season_planner/plan_season.dart generate $seasonDir');
      final manifest = jsonDecode(made.files[manifestName]!) as Map;
      expect(manifest['slice'] ?? false, isFalse, reason: 'the season, not a slice');
      expect(manifest['cases'], [for (var n = 1; n <= 12; n++) 's3_ep${n.toString().padLeft(2, '0')}']);
      expect([for (final e in episodes) e.number], [for (var n = 1; n <= 12; n++) n]);
      expect([for (final e in episodes) e.missions.length], everyElement(3));
      expect(Directory('test/sandbox/generated/s3_rome_c01_08').existsSync(), isFalse, reason: 'the slice it replaces');
    });

    test('the game finds nothing wrong: its validator, engine choice and bundled pictures', () {
      expect([for (final i in SeasonContentValidator.validate(content)) (i.rule, i.caseId, i.message)], isEmpty);
      final engines = {for (final s in PuzzleEngineCollisionCheck.slotsOf(content)) s.mission.id: s.active?.engine};
      for (final (id, _) in measured) {
        expect(engines[id], 'SceneExplore', reason: id);
      }
      expect(content.dialogues.keys, ['s3_ep01_m1', 's3_ep11_m2'], reason: 'the witnesses of Case 01 and Case 11');
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final folders = [for (final m in RegExp(r'^\s+- (assets/\S+/)\s*$', multiLine: true).allMatches(pubspec)) m[1]!];
      final files = {
        for (final p in content.places.values) p.file,
        for (final s in content.explores.values) ...[s.picture, for (final c in s.choices) c.picture],
        for (final d in content.dialogues.values) for (final s in d.speakers) s.portrait,
        for (final m in content.talkMissions.values) for (final s in [?m.before, ?m.after]) ...s.speaker.portraits.values,
        for (final e in content.endings.values) for (final l in e) ?l.portrait,
        for (final e in episodes) for (final m in e.allMissions) for (final o in m.options) ?o.picture,
      };
      for (final f in files) {
        expect(File(f).existsSync(), isTrue, reason: f);
        expect(folders.any((d) => f.startsWith(d) && !f.substring(d.length).contains('/')), isTrue, reason: '$f is not in a pubspec assets folder');
      }
      // Every place of the season has its picture now (Case 09 to 12's too).
      expect(content.places.keys, containsAll(['s3_rome.forum_view', 's3_rome.map_archive', 's3_rome.civetta_square', 's3_rome.site_office', 's3_rome.roman_library']));
    });

    for (final (id, file) in measured) {
      test('$id is a look round on the drawn picture, its places measured on that very file', () {
        final m = planOf(id);
        final ep = m.play!.explore!;
        final explore = content.explores[id]!;
        final f = File(ep.picture.file);
        expect(explore.picture, file);
        expect(PlayCheck.pngSize(f), (1536, 1024));
        expect(ep.picture.measuredOn, ContentHash.ofBytes(f.readAsBytesSync()), reason: 'measured on the file the game shows');
        expect(m.puzzle.notes.any((n) => n.contains('UNMEASURED')), isFalse);
        Rect px(SceneRect r) => Rect.fromLTRB(r.left / 1536, r.top / 1024, r.right / 1536, r.bottom / 1024);
        for (final (i, s) in explore.spots.indexed) {
          expect(s.areas, [for (final r in ep.spots[i].areas) px(r)], reason: s.id);
        }
        // No two places overlap: a tap inside one is never taken by another.
        final all = [for (final s in explore.spots) for (final r in s.areas) (s.id, r), for (final o in explore.others) for (final r in o.areas) (o.label, r)];
        for (final (i, (a, ra)) in all.indexed) {
          for (final (b, rb) in all.skip(i + 1)) {
            if (a == b) continue;
            expect(ra.intersect(rb).isEmpty || ra.intersect(rb).width <= 0 || ra.intersect(rb).height <= 0, isTrue, reason: '$id: $a and $b overlap');
          }
        }
        // The opening view holds every place to find (its middle, at least).
        for (final s in explore.spots) {
          for (final r in s.areas) {
            expect(explore.opening.contains(r.center), isTrue, reason: '$id ${s.id} outside the opening');
          }
        }
        expect(explore.document, isNotNull);
        for (final c in explore.choices) {
          expect(File(c.picture).existsSync(), isTrue, reason: c.picture);
        }
      });
    }

    test('Case 04 M1 opens the Pantheon closer, with nothing re-measured; Case 10 M1 on the measured helmets', () {
      final pantheon = content.explores['s3_ep04_m1']!;
      // x 300-1350 of 1536: the hall a phone's width, about 1.46 times larger
      // than the whole picture's width it opened on before.
      expect(pantheon.opening, Rect.fromLTRB(300 / 1536, 0, 1350 / 1536, 1020 / 1024));
      expect(1 / pantheon.opening.width, greaterThan(1.4));
      final civetta = content.explores['s3_ep10_m1']!;
      final hooks = civetta.spots.firstWhere((s) => s.id == 'hooks');
      expect(hooks.kind, ExploreKind.choice);
      expect(hooks.requires, 'notice');
      expect([for (final c in civetta.choices) c.picture.split('/').last], ['helmet_white_crane.png', 'helmet_yellow_plain.png', 'yellow_helmet.png']);
    });

    test('every face is drawn and written in: Pia and Bruno too', () {
      const pia = 'assets/seasons/season_03_rome/characters/pia_base.png';
      const bruno = 'assets/seasons/season_03_rome/characters/bruno_base.png';
      const brunoSite = 'assets/seasons/season_03_rome/characters/bruno_site.png';
      final d = content.dialogues['s3_ep01_m1']!;
      expect({for (final s in d.speakers) s.portrait}, {
        'assets/seasons/season_03_rome/characters/enzo_base.png',
        'assets/seasons/season_03_rome/characters/sofia_base.png',
        'assets/seasons/season_03_rome/characters/livia_base.png',
      });
      final talks = [for (final m in content.talkMissions.values) ?m.before, for (final m in content.talkMissions.values) ?m.after];
      for (final s in talks) {
        expect(s.speaker.portraits, isNotEmpty, reason: '${s.id}: ${s.speaker.name} has a face');
        for (final p in s.speaker.portraits.values) {
          expect(File(p).existsSync(), isTrue, reason: '${s.id}: $p');
        }
      }
      for (final MapEntry(key: id, value: lines) in content.endings.entries) {
        for (final l in lines) {
          if (l.portrait case final p?) expect(File(p).existsSync(), isTrue, reason: '$id: $p');
        }
      }
      expect(content.talkMissions['s3_ep03_m3']!.after!.speaker.portraits.values, everyElement(pia), reason: 'Pia at her stall');
      expect(content.talkMissions['s3_ep07_m3']!.before!.speaker.portraits.values, everyElement(bruno), reason: 'Bruno, the businessman');
      // Case 11 M2's witnesses: Valli at his site, Pia, Sofia.
      final witnesses = content.dialogues['s3_ep11_m2']!;
      for (final s in witnesses.speakers) {
        expect(File(s.portrait).existsSync(), isTrue, reason: '${s.name}: ${s.portrait}');
      }
      expect({for (final s in witnesses.speakers) s.portrait}, containsAll([brunoSite, pia]));
      final used = {
        for (final s in talks) ...s.speaker.portraits.values,
        for (final e in content.endings.values) for (final l in e) ?l.portrait,
        for (final d in content.dialogues.values) for (final s in d.speakers) s.portrait,
      };
      expect(used, containsAll([pia, bruno, brunoSite]));
      // The Owl, hood down on the bridge: the hooded portrait drawn in STEP 3-12B.
      expect(content.talkMissions['s3_ep08_m2']!.before!.speaker.portraits.values,
          everyElement('assets/seasons/season_03_rome/characters/livia_hood.png'));
    });

    test('a picture choice never shows its right picture as the mission\'s own place (Case 08 M1)', () {
      for (final e in episodes) {
        for (final m in e.allMissions.where((m) => m.type == MissionType.imageChoice)) {
          final right = m.options.firstWhere((o) => o.id == m.answer).picture;
          expect(content.places[m.place.key]!.file, isNot(right), reason: '${m.id}: its first page would show the answer');
        }
      }
      final m1 = episodes[7].missions.first;
      expect(m1.place.key, 's3_rome.map_hall', reason: 'where the card came; the bridge is first seen among the choices');
      expect(episodes[7].missions[1].place.key, 's3_rome.tiber_bridge', reason: 'M2 on the bridge, after the answer');
    });
  });

  group('played in the real app', () {
    setUp(registerRome);
    tearDown(unregisterRome);

    Future<(ProviderContainer, SharedPreferences, Future<ProviderContainer> Function())> open(WidgetTester t, Size size, double ratio,
        {bool operator = false}) async {
      WidgetController.hitTestWarningShouldBeFatal = true; // every tap must land
      addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
      t.view.physicalSize = size;
      t.view.devicePixelRatio = ratio;
      addTearDown(t.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      Future<ProviderContainer> start() async {
        final c = ProviderContainer(overrides: [...await testOverridesFor(prefs), ...romeOverrides()]);
        addTearDown(c.dispose);
        c.read(seasonPreviewSwitchProvider.notifier).set(true); // the cases open unreleased
        if (operator) c.read(operatorAccessSwitchProvider.notifier).set(true);
        return c;
      }

      final c = await start();
      final ctrl = c.read(gameControllerProvider.notifier);
      ctrl.createDetective('Kim', DetectiveAvatar.girl);
      expect(ctrl.openSeason(romeSeasonId), isTrue);
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: const WorldMysteryApp()));
      await wait(t);
      return (c, prefs, start);
    }

    /// The app opened again on [c], at the map.
    Future<void> reopen(WidgetTester t, ProviderContainer c) async {
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: const WorldMysteryApp()));
      await wait(t);
      c.read(routerProvider).go(Routes.map);
      await wait(t, const Duration(milliseconds: 2500));
    }

    /// An image of [file] in the tree (as it is, or decoded smaller).
    Finder shown(String file) => find.byWidgetPredicate((w) {
      if (w is! Image) return false;
      final image = switch (w.image) {
        ResizeImage(:final imageProvider) => imageProvider,
        final other => other,
      };
      return image is AssetImage && image.assetName == file;
    });

    /// The right pictures of the picture choices not played yet: none may be
    /// on screen before its own choice page.
    final unrevealed = <String>{
      for (final e in episodes)
        for (final m in e.allMissions.where((m) => m.type == MissionType.imageChoice)) m.options.firstWhere((o) => o.id == m.answer).picture!,
    };
    void nothingGivenAway(String where) {
      for (final f in unrevealed) {
        expect(shown(f), findsNothing, reason: '$where: $f shown before its choice');
      }
    }

    Future<void> throughIntro(WidgetTester t, ProviderContainer c, SandboxPlay play, Episode e) async {
      c.read(routerProvider).go(Routes.intro);
      await wait(t, const Duration(milliseconds: 1500));
      await tapText(t, 'SKIP ›');
      for (final line in e.intro) {
        expect(findReadableContaining(line), findsWidgets, reason: '${e.id} intro "$line": ${play.texts()}');
      }
      nothingGivenAway('${e.id} intro');
      await tapText(t, "I'M READY", after: const Duration(milliseconds: 2000));
    }

    /// The talk's lines, each read whole, then its finish.
    Future<void> hear(WidgetTester t, SandboxPlay play, TalkScene scene) async {
      for (final (i, line) in scene.opening.indexed) {
        if (find.text('READ ALL').evaluate().isNotEmpty) await tapText(t, 'READ ALL', after: const Duration(milliseconds: 300));
        expect(findReadableContaining(line.text), findsWidgets, reason: '${scene.id} line $i: ${play.texts()}');
        if (i < scene.opening.length - 1) await tapText(t, 'NEXT', after: const Duration(milliseconds: 300));
      }
      await tapText(t, scene.finishLabel, after: const Duration(milliseconds: 1200));
    }

    /// A choice's first wrong option the plan wrote a line for.
    ChoiceOption? wrongOf(Mission m) => m.options.where((o) => o.id != m.answer && (o.feedback ?? '').isNotEmpty).firstOrNull;

    /// Where the look round's picture is seen (its place between the panels).
    Rect view(WidgetTester t) => t.getRect(find.byType(InteractiveViewer));

    /// [point] (fractions of the picture) brought into the view first, as a
    /// child drags the picture when a hint opened makes its place shorter.
    Future<void> inView(WidgetTester t, MissionPlay engine, Offset point) async {
      final v = view(t).deflate(12);
      final at = engine.exploreAt(t, point);
      if (v.contains(at)) return;
      await t.dragFrom(v.center, v.center - at);
      await wait(t, const Duration(milliseconds: 600));
      expect(view(t).contains(engine.exploreAt(t, point)), isTrue, reason: 'dragged into view: $point');
    }

    /// The scale the look round opens at (1: the picture as wide as the screen).
    double openingScale(WidgetTester t) => t.widget<InteractiveViewer>(find.byType(InteractiveViewer)).transformationController!.value.getMaxScaleOnAxis();

    /// A look round from the map: the choice locked first, every place
    /// looked at, a miss, a hint, the document, a wrong picture, the right one.
    Future<void> lookRound(WidgetTester t, ProviderContainer c, SandboxPlay play, Mission m, {void Function(double scale, Rect view)? onOpen}) async {
      final engine = MissionPlay();
      final explore = content.explores[m.id]!;
      await play.toPlace(m);
      nothingGivenAway('${m.id} place');
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      final talk = content.talkMissions[m.id];
      if (talk?.before case final before?) {
        // Case 10 M1: Livia at the fence first, then the look round.
        expect(find.byKey(const ValueKey('case-talk-goal')), findsOneWidget, reason: '${m.id}: the talk comes first: ${play.texts()}');
        await hear(t, play, before);
      }
      expect(find.byKey(const ValueKey('explore-picture')), findsOneWidget, reason: '${m.id}: ${play.texts()}');
      final image = find.descendant(of: find.byKey(const ValueKey('explore-picture')), matching: find.byType(Image));
      expect(((t.widget<Image>(image.first)).image as AssetImage).assetName, explore.picture);
      // Every place is in the view as it opens (the picture's place on
      // screen, under no panel), before anything is moved.
      final opening = view(t);
      onOpen?.call(openingScale(t), opening);
      for (final s in explore.spots) {
        final at = engine.exploreAt(t, s.areas.first.center);
        expect(opening.contains(at), isTrue, reason: '${m.id} ${s.id} at $at, view $opening');
      }
      final choice = explore.spots.firstWhere((s) => s.kind == ExploreKind.choice);
      await inView(t, engine, choice.areas.first.center);
      await engine.tapExplore(t, choice.areas.first.center);
      expect(findReadableContaining(choice.lockedLine), findsWidgets, reason: '${m.id} locked: ${play.texts()}');
      expect(find.byKey(const ValueKey('explore-choice')), findsNothing);
      for (final s in explore.spots.where((s) => s.kind == ExploreKind.note)) {
        await inView(t, engine, s.areas.first.center);
        await engine.tapExplore(t, s.areas.first.center);
        expect(findReadableContaining(s.line), findsWidgets, reason: '${m.id} ${s.id}: ${play.texts()}');
        await engine.tapKey(t, 'explore-close', after: const Duration(milliseconds: 500)); // its card closed
      }
      for (final o in explore.others) {
        await inView(t, engine, o.areas.first.center);
        await engine.tapExplore(t, o.areas.first.center);
        expect(findReadableContaining(o.line), findsWidgets, reason: '${m.id} ${o.label}: ${play.texts()}');
      }
      await tapText(t, 'Get a Free Hint', after: const Duration(milliseconds: 800));
      expect(c.read(gameControllerProvider).hintsFor(m.id), 1);
      expect(findReadableContaining(m.hints.first), findsWidgets, reason: '${m.id} hint: ${play.texts()}');
      await inView(t, engine, explore.document!.areas.first.center);
      await engine.tapExplore(t, explore.document!.areas.first.center);
      if (engine.sealedLetter().evaluate().isNotEmpty) {
        await t.tap(engine.sealedLetter());
        await wait(t, const Duration(milliseconds: 1200));
      }
      expect(findReadableContaining(m.letter.split('\n').first), findsWidgets, reason: '${m.id} document: ${play.texts()}');
      await engine.tapKey(t, 'explore-close', after: const Duration(milliseconds: 500));
      final wrong = wrongOf(m)!;
      await inView(t, engine, choice.areas.first.center);
      await engine.chooseInExplore(t, explore, wrong.id);
      expect(find.text('Not quite!'), findsOneWidget, reason: play.texts());
      expect(findReadableContaining(wrong.feedback!), findsWidgets, reason: play.texts());
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
      if (find.byKey(const ValueKey('explore-choice')).evaluate().isEmpty) await inView(t, engine, choice.areas.first.center);
      await engine.chooseInExplore(t, explore, m.answer);
      if (talk?.after case final after?) {
        await wait(t, const Duration(milliseconds: 600));
        await hear(t, play, after);
      }
    }

    /// [m] from the map to its Discovery Moment, as its plan plays it, on
    /// its own place's picture. With [hint], the puzzle's first hint is
    /// opened before it is answered.
    Future<void> playMission(WidgetTester t, ProviderContainer c, SandboxPlay play, Mission m, {bool hint = false}) async {
      final talk = content.talkMissions[m.id];
      final place = content.places[m.place.key]!.file;
      expect(File(place).existsSync(), isTrue, reason: '${m.id}: $place');
      if (content.explores.containsKey(m.id)) {
        await lookRound(t, c, play, m);
      } else if (content.dialogues[m.id] case final witnesses?) {
        await play.toPlace(m);
        expect(shown(place), findsWidgets, reason: '${m.id}: its place\'s picture');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        await hearAndCompare(t, MissionPlay(), witnesses);
      } else {
        await play.toPlace(m);
        expect(shown(place), findsWidgets, reason: '${m.id}: its place\'s picture');
        nothingGivenAway('${m.id} place');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        if (talk?.before case final before?) {
          expect(find.byKey(const ValueKey('case-talk-goal')), findsOneWidget, reason: '${m.id}: the talk comes first: ${play.texts()}');
          nothingGivenAway('${m.id} talk');
          await hear(t, play, before);
        }
        nothingGivenAway('${m.id} letter');
        await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
        expect(findReadableContaining(m.letter.split('\n').first), findsWidgets, reason: '${m.id} letter: ${play.texts()}');
        nothingGivenAway('${m.id} letter open');
        await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
        expect(findReadable(m.question), findsOneWidget, reason: '${m.id}: ${play.texts()}');
        if (m.type == MissionType.imageChoice) {
          // The choice page: here, and only here, the right picture is first seen.
          for (final o in m.options) {
            expect(shown(o.picture!), findsOneWidget, reason: '${m.id} ${o.id}: its picture on screen');
          }
          unrevealed.remove(m.options.firstWhere((o) => o.id == m.answer).picture);
        }
        if (hint) {
          final link = find.text('Get a Free Hint');
          await reveal(t, link);
          await tapText(t, 'Get a Free Hint', after: const Duration(milliseconds: 800));
          expect(c.read(gameControllerProvider).hintsFor(m.id), 1, reason: m.id);
          expect(findReadableContaining(m.hints.first), findsWidgets, reason: '${m.id} hint: ${play.texts()}');
          if (find.text('CLOSE').evaluate().isNotEmpty) await tapText(t, 'CLOSE', after: const Duration(milliseconds: 500));
        }
        if (m.type == MissionType.multipleChoice || m.type == MissionType.imageChoice) {
          if (wrongOf(m) case final wrong?) await play.wrong(m, wrong.id, line: wrong.feedback);
        }
        await play.answer(m, m.answer);
        if (talk?.after case final after?) {
          await wait(t, const Duration(milliseconds: 600));
          await hear(t, play, after);
        }
      }
      if (content.discoveries[m.id] case final d?) {
        await wait(t, const Duration(milliseconds: 1500));
        expect(findReadableContaining(d.title), findsWidgets, reason: '${m.id} discovery: ${play.texts()}');
      }
      expect(c.read(gameControllerProvider).isCompleted(m.id), isTrue, reason: m.id);
    }

    /// The final, its ending, the case closed, its report.
    Future<void> playFinal(WidgetTester t, ProviderContainer c, SandboxPlay play, Episode e, {required bool last}) async {
      final fin = e.finalMission;
      await play.toFinal(fin);
      await play.answer(fin, fin.answer);
      await wait(t, const Duration(milliseconds: 1500));
      expect(find.byKey(const ValueKey('final-ending')), findsOneWidget, reason: '${e.id}: ${play.texts()}');
      final ending = content.endings[fin.id]!;
      for (final (i, line) in ending.indexed) {
        if (find.text('READ ALL').evaluate().isNotEmpty) await tapText(t, 'READ ALL', after: const Duration(milliseconds: 300));
        expect(findReadableContaining(line.text), findsWidgets, reason: '${e.id} ending line $i: ${play.texts()}');
        if (i < ending.length - 1) await tapText(t, 'NEXT', after: const Duration(milliseconds: 600));
      }
      await tapText(t, 'CLOSE THE CASE', after: const Duration(milliseconds: 1500));
      expect(c.read(gameControllerProvider).isCaseSolved, isTrue, reason: e.id);
      if (!last) expect(find.text('CASE ${e.numberLabel} COMPLETE'), findsOneWidget, reason: play.texts());
      await t.tapAt(t.getCenter(find.byType(Scaffold).last));
      await wait(t, const Duration(milliseconds: 1200));
      await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 3200));
      expect(find.byType(CaseSolvedScreen), findsOneWidget, reason: e.id);
      expect(find.text('CASE CLOSED'), findsOneWidget, reason: play.texts());
    }

    testWidgets('the whole season in order on a phone: Cases 01 to 12, every mission from the map, each final and ending, '
        'saves kept across restarts, the season complete, a solved case opened again', (t) async {
      var (c, prefs, start) = await open(t, const Size(1170, 2532), 3);
      final play = SandboxPlay(t);
      SeasonNotifier season() => c.read(seasonProvider.notifier);

      for (final (n, e) in episodes.indexed) {
        expect(season().isUnlocked(e.id), isTrue, reason: '${e.id} opened by the case before it');
        if (n + 1 < episodes.length) expect(season().isUnlocked(episodes[n + 1].id), isFalse, reason: '${episodes[n + 1].id} still sealed');
        expect(c.read(gameControllerProvider.notifier).openEpisode(e.id), isTrue, reason: e.id);
        await throughIntro(t, c, play, e);
        // A hint in every case: in its look round, else on its first puzzle page.
        final hintAt = e.missions.where((m) => !content.dialogues.containsKey(m.id)).first;
        for (final (i, m) in e.missions.indexed) {
          await playMission(t, c, play, m, hint: m == hintAt && !content.explores.containsKey(m.id));
          await play.onToMap(m);
          if (n == 0 && i == 0) {
            // ── A restart mid-case: Case 01 M1 is kept, M2 is next.
            final saved = savedString(prefs, AppConstants.progressKeyFor(e.id))!;
            expect((jsonDecode(saved) as Map)['completedMissionIds'], [m.id]);
            c = await start();
            expect(c.read(gameControllerProvider.notifier).openSeason(romeSeasonId), isTrue);
            expect(c.read(currentEpisodeProvider).id, e.id, reason: 'the open case is kept');
            expect(c.read(gameControllerProvider).completedMissionIds, [m.id]);
            await reopen(t, c);
          }
        }
        expect(c.read(gameControllerProvider).totalHints, greaterThanOrEqualTo(1), reason: '${e.id}: a hint taken');
        await playFinal(t, c, play, e, last: n == episodes.length - 1);
        expect(c.read(gameControllerProvider).completedMissionIds, [for (final m in e.allMissions) m.id], reason: e.id);
        expect(c.read(seasonProvider).solvedEpisodeIds, [for (final x in episodes.take(n + 1)) x.id]);
        if (n == 1 || n == 5 || n == 9) {
          // ── A restart between cases (after Case 02, 06 and 10): the
          // cases solved kept, the next one still open.
          c = await start();
          expect(c.read(gameControllerProvider.notifier).openSeason(romeSeasonId), isTrue);
          expect(c.read(seasonProvider).solvedEpisodeIds, [for (final x in episodes.take(n + 1)) x.id]);
          expect(season().isUnlocked(episodes[n + 1].id), isTrue, reason: 'still open after a restart');
          await reopen(t, c);
        }
      }

      // ── The season complete: said on the last report, with its last words.
      await reveal(t, find.byKey(const ValueKey('season-complete')));
      expect(find.text('${romeContent.season.label} COMPLETE'), findsOneWidget, reason: play.texts());
      for (final line in romeContent.season.finale) {
        expect(findReadableContaining(line), findsWidgets, reason: 'the finale: ${play.texts()}');
      }
      expect(c.read(seasonOverviewProvider).complete, isTrue);
      expect(c.read(seasonOverviewProvider).solvedCount, 12);
      expect(unrevealed, isEmpty, reason: 'every picture choice played');

      // ── Kept after a restart, and a solved case opened again: Case 03,
      // every mission still done, its report there to read.
      c = await start();
      expect(c.read(gameControllerProvider.notifier).openSeason(romeSeasonId), isTrue);
      expect(c.read(seasonProvider).solvedEpisodeIds, [for (final e in episodes) e.id]);
      expect(c.read(seasonOverviewProvider).complete, isTrue, reason: 'still complete after a restart');
      final again = episodes[2];
      expect(c.read(gameControllerProvider.notifier).openEpisode(again.id), isTrue);
      expect(c.read(currentEpisodeProvider).id, again.id);
      expect(c.read(gameControllerProvider).isCaseSolved, isTrue);
      expect(c.read(gameControllerProvider).completedMissionIds, [for (final m in again.allMissions) m.id]);
      await reopen(t, c);
      // Its map says it is solved, and its case file opens from there.
      expect(find.text('EVERY PLACE SOLVED'), findsOneWidget, reason: 'its map: ${play.texts()}');
      expect(find.text('CASE ${again.numberLabel}'), findsWidgets, reason: play.texts());
      await tapText(t, 'SEE MY CASE FILE', after: const Duration(milliseconds: 3200));
      expect(find.byType(CaseSolvedScreen), findsOneWidget, reason: '${again.id} case file: ${play.texts()}');
      expect(find.text('CASE CLOSED'), findsOneWidget, reason: play.texts());

      // ── Saved: each case its own; London and Paris never written.
      for (final e in episodes) {
        expect(savedString(prefs, AppConstants.progressKeyFor(e.id)), isNotNull, reason: e.id);
      }
      for (final e in [for (final s in SeasonCatalog.all) ...s.episodes.keys]) {
        expect(prefs.getKeys().where((k) => k.endsWith(AppConstants.progressKeyFor(e))), isEmpty, reason: '$e (London, Paris) is never written');
      }
    });

    // The four measured look rounds on other screens: the smallest phone, a
    // small phone, a tall narrow phone, a tablet. Opened by operator access
    // (test builds only); Case 01's M3 after its M1 and M2.
    final scales = <String, double>{};
    tearDownAll(() {
      for (final MapEntry(:key, :value) in scales.entries) {
        // ignore: avoid_print
        print('opening scale  $key  ${value.toStringAsFixed(2)}');
      }
    });
    for (final (name, size, ratio) in [
      ('the smallest phone (320x568)', const Size(640, 1136), 2.0),
      ('a small phone (375x667)', const Size(750, 1334), 2.0),
      ('a tall narrow phone (393x873)', const Size(1080, 2400), 2.75),
      ('a tablet (1024x1366)', const Size(2048, 2732), 2.0),
    ]) {
      testWidgets('Case 01 M3 (map hall) on $name: every place on screen and reached by a tap, solved', (t) async {
        final (c, _, _) = await open(t, size, ratio);
        final play = SandboxPlay(t);
        final e = episodes[0];
        expect(c.read(gameControllerProvider.notifier).openEpisode(e.id), isTrue);
        await throughIntro(t, c, play, e);
        for (final m in e.missions.take(2)) {
          await playMission(t, c, play, m);
          await play.onToMap(m);
        }
        await playMission(t, c, play, e.missions[2]);
      });

      for (final (caseIndex, label) in [(3, 'Case 04 M1 (Pantheon)'), (9, 'Case 10 M1 (the site fence)')]) {
        testWidgets('$label on $name: every place on screen and reached by a tap, solved', (t) async {
          final (c, _, _) = await open(t, size, ratio, operator: true);
          final play = SandboxPlay(t);
          final e = episodes[caseIndex];
          expect(c.read(gameControllerProvider.notifier).openEpisode(e.id), isTrue);
          await throughIntro(t, c, play, e);
          final m = e.missions[0];
          await lookRound(t, c, play, m, onOpen: (s, v) => scales['${m.id} $name'] = s);
          if (content.discoveries[m.id] case final d?) {
            await wait(t, const Duration(milliseconds: 1500));
            expect(findReadableContaining(d.title), findsWidgets, reason: '${m.id} discovery: ${play.texts()}');
          }
          expect(c.read(gameControllerProvider).isCompleted(m.id), isTrue, reason: m.id);
        });
      }
    }
  });
}
