import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/mock/season2/season2_case11_scenes.dart';
import 'package:london_mystery/data/mock/season2/season2_discoveries.dart';
import 'package:london_mystery/data/mock/season2/season2_learning.dart';
import 'package:london_mystery/data/mock/season_catalog.dart';
import 'package:london_mystery/data/models/abbesses_puzzles.dart' show TornHourScene;
import 'package:london_mystery/data/models/case_talk.dart';
import 'package:london_mystery/data/models/discovery.dart';
import 'package:london_mystery/data/models/easy_steps.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/garden_puzzles.dart' show TowerTestScene;
import 'package:london_mystery/data/models/learning.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/river_puzzles.dart' show DrawnEvidenceArt;
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/models/star_puzzles.dart' show HourRecordScene;
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/mission_map/map_world.dart';
import 'package:london_mystery/features/season/season_overview.dart';

import 'easy_play.dart';
import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';

/// Season 2, Case 11 — The Unwritten Hour, played very easy (the user's
/// rules of 2026-10-27): its pictures, its steps and talks (two answers,
/// one right; the clue on screen; free hints; a wrong answer never
/// counted, never a restart), its saves, and a child playing it through
/// from Case 10's report to Case 12's file on phones of three sizes.
///
/// `LM_SHOTS=folder` saves a picture of each moment.
void main() {
  final inGame = MockEpisodeRepository.bundled();
  final s1 = season1Cases();
  final paris = [for (final e in inGame) if (e.seasonId == SeasonIds.paris) e];
  final case11 = paris.firstWhere((e) => e.id == 's2_ep11');
  final [m1, m2, m3, fin] = case11.allMissions;

  setUpAll(loadGameFonts);

  /// PNG width and height, from its header.
  (int, int) pixelsOf(String file) {
    final b = File(file).readAsBytesSync();
    int at(int i) => (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];
    return (at(16), at(20));
  }

  /// Every picture a panel shows (its file and size), and the files laid on it.
  Iterable<(String, (double, double)?)> filesOf(EasyPanel p) sync* {
    switch (p) {
      case PicturePanel(:final picture, :final layers):
        yield (picture.file, (picture.pixels.width, picture.pixels.height));
        for (final l in layers) {
          yield (l.file, null);
        }
      case RubPanel(:final book, :final signature):
        yield (book.file, (book.pixels.width, book.pixels.height));
        if (signature != null) yield (signature.file, null);
      case PaperPanel(:final foot):
        if (foot != null) yield (foot, null);
      case QuotePanel(:final portrait):
        if (portrait != null) yield (portrait, null);
      case MachinePanel(:final scene):
        yield (scene.machine.file, (scene.machine.pixels.width, scene.machine.pixels.height));
        yield (scene.wheel, (scene.wheelPixels.width, scene.wheelPixels.height));
        yield (scene.lever, (scene.leverPixels.width, scene.leverPixels.height));
        yield (scene.pin, (scene.pinPixels.width, scene.pinPixels.height));
        yield (scene.wallDial, (scene.wallDialPixels.width, scene.wallDialPixels.height));
      case EvidencePanel() || GearMarkPanel():
        break;
    }
  }

  group('in the game', () {
    test('Case 11 follows Case 10 at Saint-Sulpice, with its four puzzles; Case 12 after it', () {
      expect([for (final e in paris) e.id].indexOf('s2_ep11'), 10);
      expect(case11.number, 11);
      expect(case11.title, 'The Unwritten Hour');
      expect(case11.place, 'SAINT-SULPICE');
      expect([for (final m in case11.allMissions) m.id], ['s2_ep11_m1', 's2_ep11_m2', 's2_ep11_m3', 's2_ep11_final']);
      expect([for (final m in case11.allMissions) m.evidence!.name], ['Page 3', "Victor's Paper", "Victor's Name", "Victor's Truth"]);
      expect(ParisLandmark.cases['s2_ep11'], ParisLandmark.luxembourgGardens);
      expect(case11.introScene, Artwork.annexStreet);
      expect(SeasonCatalog.byId(SeasonIds.paris)!.season.upcomingTitles, isEmpty);
      for (final m in case11.missions) {
        expect(SeasonCatalog.easySteps(m), isNotNull, reason: m.id);
        expect(SeasonCatalog.discovery(m).title, m.successMessage, reason: m.id);
        expect(SeasonCatalog.storyScenes(m)?.after, isNotNull, reason: m.id);
      }
      expect(SeasonCatalog.caseTalk(fin), isNotNull, reason: 'the final is a talk with Victor');
      expect(SeasonCatalog.closesAfterLastStep(fin), isFalse, reason: 'its answer closes it');
      expect(season2DiscoveryTypes['s2_ep11_m1'], DiscoveryType.evidenceFound);
    });

    test('its pictures are in the game at the sizes they are measured on', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final folder in ['cases/case_11/', 'cases/case_12/', 'characters/']) {
        expect(pubspec, contains('    - assets/seasons/season_02_paris/$folder'));
      }
      final panels = [
        for (final m in case11.missions)
          for (final step in SeasonCatalog.easySteps(m)!.steps) ...[
            ...step.panels,
            ...?step.after,
            for (final o in step.options) ?o.panel,
          ],
      ];
      final files = {for (final p in panels) ...filesOf(p)};
      for (final (file, size) in files) {
        expect(File(file).existsSync(), isTrue, reason: file);
        if (size != null) expect(pixelsOf(file), (size.$1.toInt(), size.$2.toInt()), reason: file);
      }
      for (final face in season2Victor.portraits.values) {
        expect(pixelsOf(face), (1122, 1402), reason: face);
      }
      for (final talk in [
        for (final m in case11.missions) ...[?SeasonCatalog.talkMission(m)?.before, ?SeasonCatalog.talkMission(m)?.after],
        SeasonCatalog.caseTalk(fin)!,
      ]) {
        expect(File(talk.background!).existsSync(), isTrue, reason: talk.id);
      }
    });
  });

  group('very easy', () {
    final scenes = [for (final m in case11.missions) SeasonCatalog.easySteps(m)!];

    test('every choice has two answers (Box 9: three boxes), exactly one right, each a few words', () {
      for (final scene in scenes) {
        for (final step in scene.steps) {
          expect(step.hints, isNotEmpty, reason: step.id);
          expect(step.say.split(' ').length, lessThanOrEqualTo(12), reason: '${step.id}: "${step.say}"');
          if (step.does != EasyDo.choose) continue;
          final max = step.id == 'box' ? 3 : 2;
          expect(step.options.length, inInclusiveRange(2, max), reason: step.id);
          expect([for (final o in step.options) if (o.id == step.answer) o], hasLength(1), reason: '${step.id}: one right answer');
          for (final o in step.options) {
            expect((o.label ?? '').split(' ').length, lessThanOrEqualTo(4), reason: '${step.id}: "${o.label}"');
          }
          expect(step.tell, isNotNull, reason: '${step.id}: the second wrong answer says it plainly');
        }
      }
    });

    test('nothing to remember: what a choice needs is on its screen', () {
      final box = scenes[0].steps.firstWhere((s) => s.id == 'box');
      expect((box.panels.single as PicturePanel).writing.map((w) => w.text), containsAll(['3', '9', '12']));
      final clocks = scenes[1].steps.firstWhere((s) => s.id == 'clocks');
      expect({for (final p in clocks.panels) p.id}, {'victor', 'page3'}, reason: "Victor's paper beside page 3");
      final stamps = scenes[1].steps.firstWhere((s) => s.id == 'stamps');
      expect({for (final p in stamps.panels) p.id}, {'slipStamp', 'victorStamp'}, reason: 'the two stamps side by side');
      final match = scenes[2].steps.firstWhere((s) => s.id == 'match');
      expect(match.panels.single.id, 'rubbing', reason: 'the name from the big book over the two to choose');
    });

    test("Victor's final: three clues, each shown from two cards, one right", () {
      final talk = SeasonCatalog.caseTalk(fin)!;
      expect(talk.presents, hasLength(3));
      for (final p in talk.presents) {
        expect(p.choices, hasLength(2), reason: p.id);
        expect(p.choices.where(p.accepted.contains), hasLength(1), reason: p.id);
        expect(p.tell, isNotNull, reason: p.id);
        for (final id in p.choices) {
          expect(case11.allEvidence.map((e) => e.id), contains(id), reason: '${p.id}: a clue of this case, on its card');
        }
      }
      // Never more than two questions to ask at once.
      var progress = TalkProgress.start.next(talk);
      for (final id in ['s2_ep11_e1', 's2_ep11_e2', 's2_ep11_e3']) {
        progress = progress.show(talk, id).$1.skip(talk);
        expect(progress.questions(talk).length, lessThanOrEqualTo(2));
      }
      expect(progress.questions(talk).map((q) => q.id), ['bag', 'clues']);
      progress = progress.ask(talk, 'clues').skip(talk);
      expect(progress.finished(talk), isTrue, reason: 'the bag is told only if asked');
      expect(progress.questions(talk).map((q) => q.id), ['bag'], reason: 'a question asked goes');
    });

    test('a talk only listened to finishes once its opening is heard', () {
      final before = SeasonCatalog.talkMission(m1)!.before!;
      var p = TalkProgress.start;
      expect(p.finished(before), isFalse);
      for (var i = 0; i < before.opening.length; i++) {
        p = p.next(before);
      }
      expect(p.finished(before), isTrue);
      expect(TalkProgress.decode(p.encode(), before).finished(before), isTrue, reason: 'saved, it is still heard');
    });

    test('the steps reached are saved, and a save that cannot be read starts at the first', () {
      final scene = scenes.first;
      expect(EasyStepsState.decode(EasyStepsState.encode(3), scene), 3);
      expect(EasyStepsState.decode('step=99', scene), scene.steps.length);
      expect(EasyStepsState.decode('nonsense', scene), 0);
      expect(EasyStepsState.decode(null, scene), 0);
    });
  });

  group('its story', () {
    test('Victor hid the truth; E.M. stays only E.M.; nothing of Case 12 told', () {
      final words = [
        ...case11.intro,
        for (final m in case11.allMissions) ...[...m.story, ...m.transition, m.letter, m.question, ...m.hints, m.evidence?.inscription ?? ''],
        for (final scene in [for (final m in case11.missions) SeasonCatalog.easySteps(m)!])
          for (final s in scene.steps) ...[s.say, ?s.question, ?s.done, ?s.tell, ...s.hints],
        for (final m in case11.missions)
          for (final talk in [?SeasonCatalog.talkMission(m)?.before, ?SeasonCatalog.talkMission(m)?.after])
            for (final l in talk.opening) l.text,
        for (final p in SeasonCatalog.caseTalk(fin)!.presents)
          for (final l in p.beat) l.text,
      ].join(' ');
      expect(words, contains('Yes. I hid the page.'));
      expect(words, contains('I was afraid.'));
      for (final never in ['Émile', 'Emile', 'Moreau', 'Clockmaker', 'London', 'Big Ben']) {
        expect(words.contains(never), isFalse, reason: '"$never" waits for Case 12');
      }
      expect(case11.hook, 'Who left the clues for me?');
    });

    test('its learning design follows the season\'s rules; every expression is on its screens', () {
      String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      String screen(Mission m) => norm([...m.story, m.letterIntro, m.letter, m.question, for (final o in m.options) o.label, ...m.hints].join(' \n '));
      expect(season2LanguageTopics['s2_ep11'], isNotNull);
      for (final m in case11.allMissions) {
        final l = SeasonCatalog.learning(m)!;
        expect(l.isHonest, isTrue, reason: m.id);
        if (l.dependency == LanguageDependency.essential) expect(l.expressions, isNotEmpty);
        for (final e in l.expressions) {
          expect(screen(m), contains(norm(e)), reason: '${m.id}: "$e"');
        }
      }
    });

    test('its evidence is drawn, and matched to what it answers', () {
      for (final e in case11.allEvidence) {
        expect(SeasonCatalog.evidenceArt(e.id), isA<DrawnEvidenceArt>(), reason: e.id);
        final link = SeasonCatalog.evidenceLink(e.id)!;
        expect(inGame.any((c) => c.allEvidence.any((v) => v.id == link.to)), isTrue, reason: '${e.id} → ${link.to}');
      }
      expect(SeasonCatalog.evidenceLink('s2_ep11_e2')!.to, 's2_ep07_e3', reason: "the opera slip's stamp");
    });
  });

  group('a child plays Case 11', () {
    final case08 = paris[7];
    final case09 = paris[8];
    final case10 = paris[9];
    final closing = {
      case08.id: GameProgress.examinedKey(case08.finalMission.id, TornHourScene.leadId),
      case09.id: GameProgress.examinedKey(case09.finalMission.id, TowerTestScene.leadId),
      case10.id: GameProgress.examinedKey(case10.finalMission.id, HourRecordScene.leadId),
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
            return const LondonMysteryApp();
          }),
        ),
      ));
      await wait(t, const Duration(milliseconds: 300));
      final game = ref.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      for (final e in paris.take(10)) {
        expect(game.openEpisode(e.id), isTrue);
        game.startInvestigation();
        for (final m in e.allMissions) {
          game.submitAnswer(m, m.answer);
        }
        if (closing[e.id] case final key?) game.closeCase(key);
      }
      return ref;
    }

    for (final size in const [Size(360, 640), Size(393, 783), Size(430, 908)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';
      testWidgets('$tag: Case 10 closed → the annex → page 3 → two papers → the name → Victor\'s truth → Case 12', (t) async {
        final ref = await open(t, size);
        final play = EasyPlay(t, 'c11_$tag');
        final router = ref.read(routerProvider);
        final game = ref.read(gameControllerProvider.notifier);
        int wrongs() => [for (final m in case11.allMissions) ref.read(gameControllerProvider).wrongCount(m.id)].fold<int>(0, (a, b) => a + b);
        String? saved(String id) => ref.read(gameControllerProvider).puzzleStateOf(id);

        Future<void> visit(Mission m) async {
          router.go(Routes.mission(m.id));
          await wait(t, const Duration(milliseconds: 1400));
          await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        }

        Future<void> finish(Mission m, String name) async {
          await wait(t, const Duration(milliseconds: 2800));
          expect(find.byWidgetPredicate((w) => w is Text && DiscoveryType.values.any((d) => d.cheer == w.data)), findsOneWidget, reason: '$name: its Discovery Moment');
          await play.shot('${name}_solved');
          await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 900));
          expect(find.text(m.transition.first), findsOneWidget, reason: '$name: its story');
          await t.tapAt(Offset(size.width / 2, size.height / 2));
          await wait(t, const Duration(milliseconds: 900));
          await play.shot('${name}_scene');
          await tapText(t, 'TO THE MAP', after: const Duration(milliseconds: 1200));
          await wait(t, const Duration(milliseconds: 3200));
        }

        // ── Case 10's report: on to Case 11 ─────────────────────────────
        router.go(Routes.solvedSettled);
        await wait(t, const Duration(milliseconds: 3000));
        await reveal(t, find.text('OPEN CASE 11'));
        expect(game.openEpisode('s2_ep11'), isTrue);
        router.go(Routes.intro);
        await wait(t, const Duration(milliseconds: 2200));
        expect(find.byKey(const ValueKey('intro-picture')), findsOneWidget);
        await play.shot('opening');
        await tapText(t, 'SKIP ›', after: const Duration(milliseconds: 2200));
        await tapText(t, "I'M READY", after: const Duration(milliseconds: 1600));

        // ── M1: Victor; the big book; Box 9; page 3 ──────────────────────
        final steps1 = SeasonCatalog.easySteps(m1)!;
        await visit(m1);
        expect(find.byKey(const ValueKey('case-talk-portrait')), findsOneWidget, reason: "Victor's face");
        await play.shot('m1_victor');
        await play.talk();
        play.expectSay('Tap the big book.');
        await play.shot('m1_book');
        // A free hint, as often as wanted: its last level lights the book.
        for (var i = 0; i < 3; i++) {
          await play.tapKey('easy-hint', after: const Duration(milliseconds: 300));
        }
        expect(findReadable(steps1.steps.first.hints.last), findsOneWidget);
        expect(ref.read(gameControllerProvider).hintsFor(m1.id), 0, reason: 'hints are free: nothing is counted');
        await play.tapOn('book', (steps1.steps.first.panels.first as PicturePanel).picture, null);
        play.expectSay('A page is torn out! Rub the next page.');
        await play.shot('m1_rub');
        // A finger dragged over the page (or tapped twice) brings it out.
        final rub = t.getRect(find.byKey(const ValueKey('easy-rub')));
        await t.dragFrom(rub.centerLeft + const Offset(10, 0), Offset(rub.width - 20, 0));
        await wait(t, const Duration(milliseconds: 300));
        await t.dragFrom(rub.topLeft + Offset(10, rub.height * 0.3), Offset(rub.width - 20, 0));
        await wait(t, const Duration(milliseconds: 300));
        if (find.byKey(const ValueKey('easy-rub')).evaluate().isNotEmpty) {
          await t.tapAt(rub.center - Offset(rub.width / 4, 0));
          await t.tapAt(rub.center + Offset(rub.width / 4, 0));
          await wait(t, const Duration(milliseconds: 400));
        }
        expect(findReadable('Page 3 is in Box 9! And a name.'), findsOneWidget);
        expect(EasyStepsState.decode(saved(m1.id), steps1), 2, reason: 'saved as done');
        await play.shot('m1_rubbed');
        await play.next();
        play.expectSay('Find Box 9.');
        final shelves = (steps1.steps[2].panels.first as PicturePanel).picture;
        final box9 = steps1.steps[2].option('9')!.area!;
        final boxSize = play.sizeOn('shelves', shelves, box9);
        expect(boxSize.width >= 48 && boxSize.height >= 48, isTrue, reason: '$tag: Box 9 is finger-sized ($boxSize)');
        await play.shot('m1_shelves');
        // Wrong once: said why, where to look lit. Wrong twice: said plainly.
        await play.tapOn('shelves', shelves, steps1.steps[2].option('3')!.area);
        expect(findReadable('That is Box 3. Find 9.'), findsOneWidget);
        await play.tapOn('shelves', shelves, steps1.steps[2].option('12')!.area);
        expect(findReadable('Box 9 is on the right. Tap it.'), findsOneWidget);
        expect(wrongs(), 0, reason: 'a wrong box is never a wrong answer');
        await play.shot('m1_told');
        await play.tapOn('shelves', shelves, box9);
        play.expectSay('Box 9 is open. Tap the folder.');
        await play.shot('m1_box');
        await play.tapOn('box', (steps1.steps[3].panels.first as PicturePanel).picture, steps1.steps[3].target!.area);
        play.expectSay('You found page 3! Read it.');
        expect(find.text('3:00  The clocks are wrong!'), findsOneWidget);
        await play.shot('m1_page3');
        await play.tapKey('easy-button-page', after: const Duration(milliseconds: 1200));
        // Victor shown page 3.
        expect(find.byKey(const ValueKey('case-talk-line')), findsOneWidget);
        await play.talk();
        await finish(m1, 'm1');
        expect(ref.read(gameControllerProvider).isCompleted(m1.id), isTrue);

        // ── M2: two papers; the two stamps ──────────────────────────────
        await visit(m2);
        await play.talk();
        play.expectSay('Look at the two papers.');
        expect(findReadable('Were the clocks right?'), findsOneWidget);
        expect(find.text('All the clocks were fine.'), findsOneWidget);
        expect(find.text('The clocks are wrong!'), findsOneWidget);
        await play.shot('m2_papers');
        await play.tapKey('easy-option-yes');
        expect(findReadable('Read page 3 again.'), findsOneWidget);
        await play.tapKey('easy-option-no');
        expect(findReadable("Victor's paper is not true!"), findsOneWidget);
        await play.next();
        expect(findReadable('Are they the same?'), findsOneWidget);
        await play.shot('m2_stamps');
        await play.tapKey('easy-option-yes', after: const Duration(milliseconds: 600));
        expect(findReadable('The same stamp! His office changed the opera paper.'), findsOneWidget);
        await play.shot('m2_same');
        await play.next(after: const Duration(milliseconds: 1200));
        await play.talk();
        await finish(m2, 'm2');

        // ── M3: the visitor book; the same name ─────────────────────────
        await visit(m3);
        play.expectSay('Look at the names in the visitor book.');
        await play.shot('m3_book');
        await play.tapKey('easy-button-names');
        play.expectSay('Which name is the same?');
        final card = t.getRect(find.byKey(const ValueKey('easy-option-victor')));
        expect(card.width >= 120 && card.height >= 60, isTrue, reason: '$tag: a name card is large ($card)');
        await play.shot('m3_names');
        await play.tapKey('easy-option-old');
        expect(findReadable('Look: no long line, no dot.'), findsOneWidget);
        await play.tapKey('easy-option-victor');
        expect(findReadable("It's Victor's name! Victor signed it."), findsOneWidget);
        await play.next(after: const Duration(milliseconds: 600));
        await finish(m3, 'm3');
        expect(wrongs(), 0);

        // ── The final: Victor's truth ───────────────────────────────────
        router.go(Routes.finalMission);
        await wait(t, const Duration(milliseconds: 1400));
        expect(find.byKey(const ValueKey('final-talk')), findsOneWidget);
        await play.shot('final_victor');
        // A wrong card first: Victor says it does not fit; nothing is counted.
        for (var i = 0; i < 20 && find.byKey(const ValueKey('case-talk-choice-s2_ep11_e3')).evaluate().isEmpty; i++) {
          await play.tapKey('case-talk-next', after: const Duration(milliseconds: 250));
        }
        await play.shot('final_cards');
        await play.tapKey('case-talk-choice-s2_ep11_e3');
        expect(find.textContaining("That doesn't show the clocks."), findsOneWidget);
        await play.talk(show: ['s2_ep11_e1', 's2_ep11_e2', 's2_ep11_e3'], ask: ['bag', 'clues']);
        await wait(t, const Duration(milliseconds: 3000));
        expect(ref.read(gameControllerProvider).isCaseSolved, isTrue);
        expect(wrongs(), 0, reason: 'never a wrong answer in the whole case');
        await play.shot('final_solved');
        await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 900));
        await t.tapAt(Offset(size.width / 2, size.height / 2));
        await wait(t, const Duration(milliseconds: 900));
        expect(findReadable("Let's find E.M. at Arts et Métiers!"), findsOneWidget);
        await play.shot('final_scene');
        await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 4000));
        await reveal(t, find.text('OPEN CASE 12'));
        await play.shot('case_closed');
        expect(ref.read(seasonOverviewProvider).solvedCount, 11);
        expect(game.openEpisode('s2_ep12'), isTrue, reason: 'Case 12 opens');
        await wait(t, const Duration(seconds: 2));
      });
    }

    testWidgets('left halfway (in a talk, in the steps): back where it was', (t) async {
      final ref = await open(t, const Size(393, 783));
      final router = ref.read(routerProvider);
      final game = ref.read(gameControllerProvider.notifier);
      final play = EasyPlay(t, 'c11_resume');
      expect(game.openEpisode('s2_ep11'), isTrue);
      game.startInvestigation();
      router.go(Routes.mission(m1.id));
      await wait(t, const Duration(milliseconds: 1400));
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      // Two lines into Victor's talk, then away.
      await play.tapKey('case-talk-next', after: const Duration(milliseconds: 300));
      await play.tapKey('case-talk-next', after: const Duration(milliseconds: 300));
      final talkKey = TalkMission.beforeKey(m1.id);
      final savedTalk = ref.read(gameControllerProvider).puzzleStateOf(talkKey);
      expect(savedTalk, isNotNull, reason: 'the talk is saved as it goes');
      router.go(Routes.map);
      await wait(t, const Duration(milliseconds: 1500));
      // Back again: straight to where it was (no place page first).
      router.go(Routes.mission(m1.id));
      await wait(t, const Duration(milliseconds: 1400));
      expect(find.text('INVESTIGATE'), findsNothing);
      expect(TalkProgress.decode(ref.read(gameControllerProvider).puzzleStateOf(talkKey), SeasonCatalog.talkMission(m1)!.before!).line, greaterThan(0),
          reason: 'back on the line it was left at');
      await play.talk();
      // One step done, then away and back: the next step.
      await play.tapOn('book', (SeasonCatalog.easySteps(m1)!.steps.first.panels.first as PicturePanel).picture, null);
      router.go(Routes.map);
      await wait(t, const Duration(milliseconds: 1500));
      router.go(Routes.mission(m1.id));
      await wait(t, const Duration(milliseconds: 1400));
      play.expectSay('A page is torn out! Rub the next page.');
      expect(t.takeException(), isNull);
    });
  });
}
