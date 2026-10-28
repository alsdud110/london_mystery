import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/mock/season2/season2_case12_scenes.dart';
import 'package:world_mystery/data/mock/season2/season2_learning.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/abbesses_puzzles.dart' show TornHourScene;
import 'package:world_mystery/data/models/case_talk.dart';
import 'package:world_mystery/data/models/discovery.dart';
import 'package:world_mystery/data/models/easy_steps.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/garden_puzzles.dart' show TowerTestScene;
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/river_puzzles.dart' show DrawnEvidenceArt;
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/data/models/star_puzzles.dart' show HourRecordScene;
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/mission_map/map_world.dart';
import 'package:world_mystery/features/season/season_overview.dart';

import 'easy_play.dart';
import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';

/// Season 2, Case 12 — The Clockmaker's Truth, the season's last case,
/// played very easy (2026-10-27): its pictures, steps and talks, the
/// Clockmaker proved by three clues before he says it, the machine fixed by
/// four taps, the final case board (six questions, two answers each, the
/// clue on screen), the ending line by line, and the season complete on to
/// the Detective Archives.
///
/// `LM_SHOTS=folder` saves a picture of each moment.
void main() {
  final inGame = MockEpisodeRepository.bundled();
  final s1 = season1Cases();
  final paris = [for (final e in inGame) if (e.seasonId == SeasonIds.paris) e];
  final case12 = paris.firstWhere((e) => e.id == 's2_ep12');
  final [m1, m2, m3, fin] = case12.allMissions;

  setUpAll(loadGameFonts);

  (int, int) pixelsOf(String file) {
    final b = File(file).readAsBytesSync();
    int at(int i) => (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];
    return (at(16), at(20));
  }

  group('in the game', () {
    test("Case 12 is the season's last, at Arts et Métiers, with its four puzzles and an ending", () {
      expect(paris.last.id, 's2_ep12');
      expect(paris, hasLength(12));
      expect(case12.title, "The Clockmaker's Truth");
      expect(case12.place, 'ARTS ET MÉTIERS');
      expect([for (final m in case12.allMissions) m.id], ['s2_ep12_m1', 's2_ep12_m2', 's2_ep12_m3', 's2_ep12_final']);
      expect([for (final m in case12.allMissions) m.evidence!.name], ['The Name Tag', "The Clockmaker's Mark Tool", 'The Fixed Machine', 'The Case File']);
      expect(ParisLandmark.cases['s2_ep12'], ParisLandmark.artsEtMetiers);
      expect(case12.introScene, Artwork.artsMetiersHall);
      for (final m in case12.allMissions) {
        expect(SeasonCatalog.easySteps(m), isNotNull, reason: m.id);
        expect(SeasonCatalog.storyScenes(m)?.after, isNotNull, reason: m.id);
      }
      expect(SeasonCatalog.caseEnding(fin), season2Case12Ending);
      expect(SeasonCatalog.closesAfterLastStep(fin), isTrue, reason: 'the ending closes the case');
      final season = SeasonCatalog.byId(SeasonIds.paris)!.season;
      expect(season.plannedCases, 12);
      expect(season.upcomingTitles, isEmpty);
      expect(season.outro, isNotEmpty);
      expect(season.finale, isNotEmpty);
    });

    test('its pictures are measured as delivered; the machine\'s parts sit on it', () {
      final m = season2Machine;
      for (final (file, px) in [
        (m.machine.file, m.machine.pixels),
        (m.wheel, m.wheelPixels),
        (m.lever, m.leverPixels),
        (m.pin, m.pinPixels),
        (m.wallDial, m.wallDialPixels),
      ]) {
        expect(pixelsOf(file), (px.width.toInt(), px.height.toInt()), reason: file);
      }
      final machine = Rect.fromLTWH(0, 0, m.machine.pixels.width, m.machine.pixels.height);
      for (final part in [m.wheelAt, m.window, m.leverAt, m.pinOut, m.pinIn, for (final d in m.dials) Rect.fromCircle(center: d, radius: m.dialRadius)]) {
        expect(machine.contains(part.topLeft) && machine.contains(part.bottomRight), isTrue, reason: '$part on the machine');
      }
      expect(MachineScene.timeOf(m.wrong), '10:20');
      expect(MachineScene.timeOf(m.right), '11:20');
      expect(m.right - m.wrong, 60, reason: 'one hour behind, as the story says');
      for (final face in ['emile_base', 'emile_sad', 'emile_back']) {
        expect(pixelsOf('assets/seasons/season_02_paris/characters/$face.png'), (1122, 1402));
      }
      for (final l in season2Case12Ending) {
        expect(File(l.background).existsSync(), isTrue);
        if (l.portrait != null) expect(File(l.portrait!).existsSync(), isTrue);
      }
    });
  });

  group('very easy', () {
    test('every choice has two answers, exactly one right, and its clue on screen', () {
      for (final m in case12.allMissions) {
        for (final step in SeasonCatalog.easySteps(m)!.steps) {
          expect(step.hints, isNotEmpty, reason: step.id);
          if (step.does != EasyDo.choose) continue;
          expect(step.options, hasLength(2), reason: '${m.id} ${step.id}');
          expect([for (final o in step.options) if (o.id == step.answer) o], hasLength(1), reason: step.id);
          expect(step.panels, isNotEmpty, reason: '${step.id}: what it needs is shown with it');
          expect(step.tell, isNotNull, reason: step.id);
          for (final o in step.options) {
            expect((o.label ?? '').split(' ').length, lessThanOrEqualTo(4), reason: '${step.id}: "${o.label}"');
          }
        }
      }
    });

    test('the case board: six questions, one at a time, as the user set them', () {
      final board = SeasonCatalog.easySteps(fin)!;
      expect([for (final s in board.steps) s.question], [
        'Did Paris lose an hour?',
        'Were the clocks wrong?',
        'Who hid page 3?',
        'Who is the Clockmaker?',
        'Why did Émile leave clues?',
        'Was Émile right to scare people?',
      ]);
      expect([for (final s in board.steps) s.option(s.answer!)!.label], ['NO', 'YES', 'Victor', 'Émile', 'To show the truth', 'NO']);
      for (final s in board.steps) {
        final shown = s.panels.single;
        if (shown is EvidencePanel) {
          expect(inGame.any((e) => e.allEvidence.any((v) => v.id == shown.evidenceId)), isTrue, reason: s.id);
        }
      }
    });

    test('the machine: four taps, no turning by hand, no pin to drag', () {
      final steps = SeasonCatalog.easySteps(m3)!.steps;
      expect([for (final s in steps) s.does], [EasyDo.next, EasyDo.tap, EasyDo.tap, EasyDo.next]);
      expect([for (final s in steps) s.button].first, 'STOP');
      expect(steps.last.button, 'START');
      expect([for (final s in steps) (s.panels.single as MachinePanel).state], [MachineState.running, MachineState.stopped, MachineState.turned, MachineState.pinned]);
      expect((steps.last.after!.single as MachinePanel).state, MachineState.fixed);
    });

    test('the Clockmaker is proved by three clues before he says it; his name only then', () {
      final m2Steps = SeasonCatalog.easySteps(m2)!.steps.map((s) => s.id);
      expect(m2Steps, ['open', 'wheel', 'stamp', 'marks', 'who']);
      final after = SeasonCatalog.talkMission(m2)!.after!;
      var p = TalkProgress.start;
      for (var i = 0; i < after.opening.length; i++) {
        p = p.next(after);
      }
      expect(p.speakerName(after), '???', reason: 'not named before he says so');
      expect(p.questions(after).map((q) => q.id), ['clockmaker'], reason: 'one question at a time');
      p = p.ask(after, 'clockmaker');
      expect(p.speakerName(after), 'ÉMILE MOREAU');
      for (final q in ['why', 'bigBen', 'clues']) {
        p = p.skip(after);
        expect(p.questions(after).map((x) => x.id), [q]);
        p = p.ask(after, q);
      }
      expect(p.skip(after).finished(after), isTrue);
      final said = [for (final q in after.questions) for (final l in q.beat) l.text].join(' ');
      expect(said, contains('I tried to stop Big Ben.'));
      expect(said, contains('I know. I was wrong.'));
      expect(SeasonCatalog.talkMission(m1)!.before!.speaker.portrait('back'), contains('emile_back'));
    });
  });

  group('its story', () {
    test('the season ends as the bible has it, and the ending as the user wrote it', () {
      final lines = [for (final l in season2Case12Ending) l.text];
      expect(lines, [
        "Victor's words are in the case file.",
        'Yes. I hid the page.',
        'And I made bad choices.',
        "I scared people. I'm sorry.",
        'I will tell everyone what I did.',
        'The clocks were wrong.',
        'Victor hid the truth.',
        'Émile left the clues.',
        'But now everyone can know.',
        'Page 3 goes into a glass case.',
        'No one can hide it again.',
      ]);
      expect(fin.transition, ['The hour was never gone.', 'The truth was waiting to be found.']);
      expect(season2Case12Ending[1].evidenceId, 's2_ep11_e4', reason: "Victor's record, from Case 11");
      final told = [
        ...case12.intro,
        for (final m in case12.allMissions) ...[...m.story, ...m.transition],
        for (final m in case12.missions)
          for (final talk in [?SeasonCatalog.talkMission(m)?.before, ?SeasonCatalog.talkMission(m)?.after]) ...[
            for (final l in talk.opening) l.text,
            for (final q in talk.questions)
              for (final l in q.beat) l.text,
          ],
      ].join(' ');
      for (final never in ['arrest', 'police', 'prison', 'punish', '8:17', '4417']) {
        expect(told.toLowerCase().contains(never), isFalse, reason: '"$never" stays untold');
      }
    });

    test('its learning design follows the season\'s rules', () {
      String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      String screen(Mission m) => norm([...m.story, m.letterIntro, m.letter, m.question, ...m.hints].join(' \n '));
      expect(season2LanguageTopics['s2_ep12'], isNotNull);
      for (final m in case12.allMissions) {
        final l = SeasonCatalog.learning(m)!;
        expect(l.isHonest, isTrue, reason: m.id);
        for (final e in l.expressions) {
          expect(screen(m), contains(norm(e)), reason: '${m.id}: "$e"');
        }
      }
    });

    test('its evidence is drawn and matched; Season 1\'s watch and Case 01\'s mark are the proof', () {
      for (final e in case12.allEvidence) {
        expect(SeasonCatalog.evidenceArt(e.id), isA<DrawnEvidenceArt>(), reason: e.id);
        final link = SeasonCatalog.evidenceLink(e.id)!;
        expect(inGame.any((c) => c.allEvidence.any((v) => v.id == link.to)), isTrue, reason: '${e.id} → ${link.to}');
      }
      expect(SeasonCatalog.evidenceLink('s2_ep12_e2')!.to, 's2_ep01_e3');
      expect(SeasonCatalog.evidenceLink('s2_ep12_e1')!.to, 's2_ep05_e2');
      expect(inGame.firstWhere((e) => e.id == 'ep12').allEvidence.map((v) => v.id), contains('ep12_e4'), reason: "Season 1's watch is the one opened");
    });
  });

  group('a child plays Case 12', () {
    final closing = {
      for (final (i, step) in [(7, TornHourScene.leadId), (8, TowerTestScene.leadId), (9, HourRecordScene.leadId)])
        paris[i].id: GameProgress.examinedKey(paris[i].finalMission.id, step),
    };

    Future<WidgetRef> open(WidgetTester t, Size size) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      GameProgress solved(e) => GameProgress(
            detectiveName: 'MINYOUNG',
            introSeen: true,
            completedMissionIds: [for (final m in e.allMissions) m.id],
            startedAt: DateTime(2026, 10, 20, 10),
            completedAt: DateTime(2026, 10, 20, 10, 30),
            playMillis: 0,
          );
      late WidgetRef ref;
      await t.pumpWidget(ProviderScope(
        overrides: [
          ...await testOverrides(prefs: {
            AppConstants.progressStorageKey: jsonEncode(solved(s1.first).toJson()),
            for (final e in s1.skip(1)) AppConstants.progressKeyFor(e.id): jsonEncode(solved(e).toJson()),
            AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: [for (final e in s1) e.id]).toJson()),
          }),
        ],
        child: RepaintBoundary(
          key: const ValueKey('shot'),
          child: Consumer(builder: (context, r, _) {
            ref = r;
            return const WorldMysteryApp();
          }),
        ),
      ));
      await wait(t, const Duration(milliseconds: 300));
      final game = ref.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      for (final e in paris.take(11)) {
        expect(game.openEpisode(e.id), isTrue);
        game.startInvestigation();
        for (final m in e.allMissions) {
          game.submitAnswer(m, m.answer);
        }
        if (closing[e.id] case final key?) game.closeCase(key);
      }
      return ref;
    }

    for (final size in const [Size(360, 640), Size(393, 783), Size(430, 908), Size(800, 1280)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';
      testWidgets('$tag: the wheel → the watch and the mark → the machine → the board → the ending → Season Complete → the Archives', (t) async {
        final ref = await open(t, size);
        final play = EasyPlay(t, 'c12_$tag');
        final router = ref.read(routerProvider);
        final game = ref.read(gameControllerProvider.notifier);
        int wrongs() => [for (final m in case12.allMissions) ref.read(gameControllerProvider).wrongCount(m.id)].fold<int>(0, (a, b) => a + b);

        Future<void> visit(Mission m) async {
          router.go(Routes.mission(m.id));
          await wait(t, const Duration(milliseconds: 1400));
          await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        }

        Future<void> finish(Mission m, String name) async {
          await wait(t, const Duration(milliseconds: 2800));
          expect(find.byWidgetPredicate((w) => w is Text && DiscoveryType.values.any((d) => d.cheer == w.data)), findsOneWidget, reason: '$name: its Discovery Moment');
          await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 900));
          expect(find.text(m.transition.first), findsOneWidget, reason: '$name: its story');
          await t.tapAt(Offset(size.width / 2, size.height / 2));
          await wait(t, const Duration(milliseconds: 900));
          await play.shot('${name}_scene');
          await tapText(t, 'TO THE MAP', after: const Duration(milliseconds: 1200));
          await wait(t, const Duration(milliseconds: 3200));
        }

        // ── Case 11's report: on to Case 12 ─────────────────────────────
        router.go(Routes.solvedSettled);
        await wait(t, const Duration(milliseconds: 3000));
        await reveal(t, find.text('OPEN CASE 12'));
        expect(game.openEpisode('s2_ep12'), isTrue);
        router.go(Routes.intro);
        await wait(t, const Duration(milliseconds: 2200));
        await play.shot('opening');
        await tapText(t, 'SKIP ›', after: const Duration(milliseconds: 2200));
        await tapText(t, "I'M READY", after: const Duration(milliseconds: 1600));

        // ── M1: the man by the machine; the same wheel; the tag ─────────
        await visit(m1);
        // On to his first line: his back turned, his name not known.
        for (var i = 0; i < 6 && find.text('???').evaluate().isEmpty; i++) {
          await play.tapKey('case-talk-next', after: const Duration(milliseconds: 400));
        }
        expect(find.text('???'), findsOneWidget, reason: 'his name not known');
        await play.shot('m1_back');
        await play.talk();
        play.expectSay('Look at this wheel. Find the same one.');
        await play.shot('m1_wheels');
        await play.tapKey('easy-option-six');
        expect(findReadable('Count the spokes. Wheel A has 6.'), findsOneWidget);
        await play.tapKey('easy-option-four');
        expect(findReadable('The same wheel! A tag is on it.'), findsOneWidget);
        await play.shot('m1_tag');
        await play.next();
        play.expectSay('Émile Moreau made this wheel!');
        await play.tapKey('easy-button-tag', after: const Duration(milliseconds: 1200));
        await play.talk();
        await finish(m1, 'm1');

        // ── M2: the watch, the stamp, the marks; who he is, and why ─────
        await visit(m2);
        await play.talk();
        play.expectSay('Tap to open the watch.');
        expect(find.text('PARIS'), findsOneWidget, reason: "Season 1's watch: PARIS on its back");
        await play.shot('m2_watch');
        final steps2 = SeasonCatalog.easySteps(m2)!.steps;
        expect(find.text("The Clockmaker's Watch"), findsOneWidget, reason: "Season 1's evidence, on the same screen");
        await play.tapOn('watch', (steps2[0].panels.last as PicturePanel).picture, null);
        play.expectSay('Tap the wheel in the watch.');
        await play.shot('m2_open');
        await play.tapOn('watch', (steps2[1].panels.first as PicturePanel).picture, steps2[1].target!.area);
        expect(findReadable('Look! The same wheel! But anyone can use a wheel.'), findsOneWidget);
        await play.next();
        play.expectSay('Tap the stamp.');
        await play.shot('m2_stamp');
        await play.tapOn('tool', (steps2[2].panels.first as PicturePanel).picture, null);
        expect(find.byKey(const ValueKey('gear-mark')), findsOneWidget, reason: 'the mark pressed');
        await play.next();
        expect(findReadable('Are the marks the same?'), findsOneWidget);
        await play.shot('m2_marks');
        await play.tapKey('easy-option-yes');
        await play.next();
        expect(findReadable('Who is the Clockmaker?'), findsOneWidget);
        await play.shot('m2_who');
        await play.tapKey('easy-option-victor');
        expect(findReadable('Whose stamp made the mark?'), findsOneWidget);
        await play.tapKey('easy-option-emile');
        await play.tapKey('easy-next', after: const Duration(milliseconds: 1200));
        await play.talk(ask: ['clockmaker', 'why', 'bigBen', 'clues'], shotAt: null);
        await finish(m2, 'm2');

        // ── M3: stop, turn, fix, start ──────────────────────────────────
        await visit(m3);
        await play.talk();
        play.expectSay('Press STOP.');
        await play.shot('m3_running');
        final machine = season2Machine.machine;
        await play.tapKey('easy-button-stop', after: const Duration(milliseconds: 1200));
        play.expectSay('Tap the big wheel.');
        final wheel = play.sizeOn('machine', machine, season2Machine.wheelTarget);
        expect(wheel.width >= 48, isTrue, reason: '$tag: the wheel is finger-sized ($wheel)');
        await play.tapOn('machine', machine, season2Machine.wheelTarget, after: const Duration(milliseconds: 1400));
        play.expectSay('The clocks say 11:20! Tap the pin.');
        expect(find.text('11:20'), findsOneWidget, reason: "the window's time");
        await play.shot('m3_turned');
        await play.tapOn('machine', machine, season2Machine.pinTarget, after: const Duration(milliseconds: 1400));
        play.expectSay('Press START.');
        await play.tapKey('easy-button-start', after: const Duration(milliseconds: 1400));
        expect(findReadable('All the clocks agree! You fixed the machine!'), findsOneWidget);
        await play.shot('m3_fixed');
        await play.tapKey('easy-next', after: const Duration(milliseconds: 1200));
        await play.talk();
        await finish(m3, 'm3');

        // ── The final case board ────────────────────────────────────────
        router.go(Routes.finalMission);
        await wait(t, const Duration(milliseconds: 1400));
        expect(find.byKey(const ValueKey('final-steps')), findsOneWidget);
        final board = SeasonCatalog.easySteps(fin)!;
        for (final (i, step) in board.steps.indexed) {
          expect(findReadable(step.question!), findsOneWidget, reason: 'question ${i + 1}');
          await play.shot('board_q${i + 1}');
          if (i == 0) {
            // Wrong twice: the help, then the answer said and lit.
            await play.tapKey('easy-option-yes');
            expect(findReadable('Did the sun lose an hour?'), findsOneWidget);
            await play.tapKey('easy-option-yes');
            expect(findReadable(step.tell!), findsOneWidget);
          }
          await play.tapKey('easy-option-${step.answer}');
          expect(findReadable(step.done!), findsOneWidget);
          await play.tapKey('easy-next', after: Duration(milliseconds: i == 5 ? 1800 : 700));
        }
        expect(wrongs(), 0, reason: 'never a wrong answer in the whole case');
        expect(ref.read(gameControllerProvider).isCaseSolved, isFalse, reason: 'the ending closes it');

        // ── The ending, line by line ────────────────────────────────────
        expect(find.byKey(const ValueKey('final-ending')), findsOneWidget);
        for (var i = 0; i < season2Case12Ending.length; i++) {
          await wait(t, const Duration(milliseconds: 1500));
          if (i == 1 || i == 3 || i == 9) await play.shot('ending_$i');
          await play.tapKey('ending-next', after: const Duration(milliseconds: 300));
          if (i < season2Case12Ending.length - 1 && find.text('READ ALL').evaluate().isNotEmpty) {
            await play.tapKey('ending-next', after: const Duration(milliseconds: 300));
          }
        }
        // The last line's CLOSE THE CASE.
        await wait(t, const Duration(milliseconds: 1500));
        if (find.text('CLOSE THE CASE').evaluate().isNotEmpty) await play.tapKey('ending-next', after: const Duration(milliseconds: 1500));
        expect(ref.read(gameControllerProvider).isCaseSolved, isTrue, reason: 'closed with the ending');
        await t.tapAt(Offset(size.width / 2, size.height / 2));
        await wait(t, const Duration(milliseconds: 900));
        expect(findReadable('The truth was waiting to be found.'), findsOneWidget);
        await play.shot('last_lines');
        await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 4000));

        // ── Case Closed: the season complete; on to the Archives ────────
        await reveal(t, find.byKey(const ValueKey('season-complete')));
        expect(find.text('SEASON TWO COMPLETE'), findsOneWidget);
        await play.shot('season_complete');
        expect(ref.read(seasonOverviewProvider).complete, isTrue);
        expect(ref.read(seasonOverviewProvider).solvedCount, 12);
        await tapText(t, 'INVESTIGATION BOARD', after: const Duration(milliseconds: 3500));
        await reveal(t, find.byKey(const ValueKey('complete-to-archives')));
        expect(find.text('COMPLETED'), findsOneWidget);
        await play.shot('board_complete');
        await play.tapKey('complete-to-archives', after: const Duration(milliseconds: 2500));
        expect(router.routerDelegate.currentConfiguration.uri.path, Routes.seasons);
        await play.shot('archives');
        await wait(t, const Duration(seconds: 2));
      });
    }

    testWidgets('left halfway through the machine, or before the ending: back where it was', (t) async {
      final ref = await open(t, const Size(393, 783));
      final router = ref.read(routerProvider);
      final game = ref.read(gameControllerProvider.notifier);
      final play = EasyPlay(t, 'c12_resume');
      expect(game.openEpisode('s2_ep12'), isTrue);
      game.startInvestigation();
      for (final m in [m1, m2]) {
        game.submitAnswer(m, m.answer);
        game.recordExamined(TalkMission.afterKey(m.id));
      }
      // Two steps of the machine done (saved), then the page left.
      game.recordExamined(TalkMission.beforeKey(m3.id));
      game.recordPuzzleState(m3.id, EasyStepsState.encode(2));
      router.go(Routes.mission(m3.id));
      await wait(t, const Duration(milliseconds: 1400));
      if (find.text('INVESTIGATE').evaluate().isNotEmpty) await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      play.expectSay('The clocks say 11:20! Tap the pin.');
      expect(find.text('11:20'), findsOneWidget, reason: 'the wheel stays turned');
      await play.shot('machine_resumed');
      // The board answered, the app closed before the ending: the ending.
      game.submitAnswer(m3, m3.answer);
      game.recordExamined(TalkMission.afterKey(m3.id));
      game.submitAnswer(fin, fin.answer);
      expect(ref.read(gameControllerProvider).isCaseSolved, isFalse);
      router.go(Routes.map);
      await wait(t, const Duration(milliseconds: 1500));
      router.go(Routes.finalMission);
      await wait(t, const Duration(milliseconds: 1500));
      expect(find.byKey(const ValueKey('final-ending')), findsOneWidget, reason: 'the ending waits to be seen');
      expect(t.takeException(), isNull);
    });
  });
}
