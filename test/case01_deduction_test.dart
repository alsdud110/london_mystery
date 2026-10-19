import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/core/utils/answer_checker.dart';
import 'package:london_mystery/data/mock/season1/season1_deductions.dart';
import 'package:london_mystery/data/mock/season1/season1_discoveries.dart';
import 'package:london_mystery/data/mock/season1/season1_sounds.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/investigation.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/scene_deduction.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/mission/widgets/scene_explore.dart' show LookMark;
import 'package:london_mystery/widgets/game_button.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';
import 'mission_play.dart';
import 'title_screen_test.dart' show capture;

/// Case 01 Mission 03: the foot of Big Ben at night. Three traces are drawn
/// in the scene — muddy footprints that stop at the tower wall, the street
/// lamp's light on one stone, fresh scratches around that stone — and each,
/// tapped, is written in the detective's notes. Then the detective chooses,
/// in the picture, where the box is hidden: under the bench, behind the
/// stone, or under the drain cover. Behind the stone, the box holds the
/// Pocket Watch, stopped at 7 o'clock: the clock number of the final lock.
void main() {
  final season = MockEpisodeRepository.bundled();
  final ep01 = season.firstWhere((e) => e.id == 'ep01');
  final m03 = ep01.missionById('m03')!;
  final scene = deductionOf(m03)!;
  DeductionClue clue(String id) => scene.clue(id);

  Size pngSize(String path) {
    final b = File(path).readAsBytesSync();
    int word(int at) => (b[at] << 24) | (b[at + 1] << 16) | (b[at + 2] << 8) | b[at + 3];
    return Size(word(16).toDouble(), word(20).toDouble());
  }

  group('the scene', () {
    test('the picture is in the app, at the size its places are measured on', () {
      expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/images/case01/'));
      expect(scene.picture, 'assets/images/case01/big_ben_base_night.png');
      expect(pngSize(scene.picture), Size(scene.pixels.width, scene.pixels.height));
    });

    test('three traces and three places, every one inside the paper edge', () {
      expect(scene.clues.map((c) => c.id), ['footprints', 'light', 'scratches']);
      expect(scene.places.map((p) => p.optionId).toList(), m03.options.map((o) => o.id).toList());
      final all = [
        for (final c in scene.clues) ...c.areas,
        for (final p in scene.places) ...p.areas,
        for (final o in scene.others) ...o.areas,
      ];
      for (final r in all) {
        expect(scene.inside.contains(r.topLeft) && scene.inside.contains(r.bottomRight - const Offset(1e-6, 1e-6)), isTrue,
            reason: '$r');
      }
    });

    test('a tap lands where it is meant to: traces first, then the rest', () {
      for (final c in scene.clues) {
        for (final r in c.areas) {
          expect(scene.hitClue(r.center), c, reason: c.id);
        }
      }
      expect(scene.hitClue(scene.guideAt), isNull, reason: 'the first ripple points at no clue');
      expect(scene.hitClue(scene.places.first.areas.first.center), isA<InvestigationSpot>(), reason: 'the bench, before choosing');
      for (final p in scene.places) {
        expect(scene.hitPlace(p.areas.first.center), p, reason: p.optionId);
      }
      expect(scene.hitPlace(clue('light').areas.first.center), isNull, reason: 'the lamp is no hiding place');
    });

    test('on the narrowest phone each trace and place is a fingertip wide', () {
      final scale = 360 / (scene.inside.width * scene.pixels.width);
      const slack = 14.0;
      for (final r in [for (final c in scene.clues) c.areas.first, for (final p in scene.places) p.areas.first]) {
        expect(r.width * scene.pixels.width * scale + 2 * slack, greaterThanOrEqualTo(44), reason: '$r');
        expect(r.height * scene.pixels.height * scale + 2 * slack, greaterThanOrEqualTo(44), reason: '$r');
      }
    });
  });

  group('the puzzle', () {
    test('a place chosen: behind the stone; the notes are the letter, line for line', () {
      expect(m03.type, MissionType.multipleChoice);
      expect(m03.answer, 'b');
      expect(m03.answerLabel, 'Behind the stone in the tower wall');
      expect(scene.clues.map((c) => c.line).toList(), m03.letter.split('\n'));
    });

    test('nothing said before the choice says where the box is', () {
      final said = [
        ...m03.story, m03.question, m03.letterIntro, m03.letter, ...m03.hints,
        scene.task, scene.chooseTask, scene.missLine, scene.notPlaceLine, scene.place,
        for (final c in scene.clues) ...[c.label, c.line],
        for (final o in scene.others) ...[o.label, o.line],
      ];
      for (final line in said) {
        expect(line.toLowerCase(), isNot(contains('behind')), reason: line);
        expect(line.toLowerCase(), isNot(contains(m03.answerLabel.toLowerCase())), reason: line);
      }
    });

    test('the wrong places are told why, never the answer; two hints', () {
      for (final wrong in ['a', 'c']) {
        expect(AnswerChecker.isCorrect(m03, wrong), isFalse);
        expect(AnswerChecker.feedbackFor(m03, wrong), contains('footprints'), reason: wrong);
      }
      expect(AnswerChecker.isCorrect(m03, 'b'), isTrue);
      expect(m03.hints, hasLength(2));
    });

    test('no old puzzle is left in Case 01: no code words, 417, or pictures in order', () {
      final all = jsonEncode(ep01.toJson());
      for (final old in ['417', 'FOUR clock', 'ONE time', 'SEVEN', '3-number', 'bell,clock,train', 'First, hear']) {
        expect(all, isNot(contains(old)), reason: old);
      }
    });
  });

  group('the case is kept', () {
    test("the box holds the Pocket Watch, stopped at 7 o'clock; the clue is 7", () {
      expect(m03.evidence!.id, 'e03');
      expect(m03.evidence!.name, 'Pocket Watch');
      expect(m03.evidence!.inscription, "It stopped at 7 o'clock.");
      expect(m03.clue!.id, 'c03');
      expect(m03.clue!.title, "7 o'clock");
      expect(m03.clue!.value, '7');
      final d = discoveryOf(m03);
      expect(d.title, 'POCKET WATCH');
      expect(d.showEvidence, isTrue);
      expect(d.detail, contains("7 o'clock"), reason: 'the 7 is found as the box opens');
      expect(m03.nextMissionId, 'm04');
    });

    test("Big Ben's 7 is still the final lock's clock number (7924)", () {
      final fin = ep01.finalMission;
      expect(fin.answer, '7924');
      expect(fin.answer[fin.dialSymbols.indexOf(m03.clue!.symbol!)], m03.clue!.value);
    });

    test('its lock opens as before; no new sound', () {
      expect(opensLock(m03), isTrue);
      expect(sequenceTouchOf(m03), SequenceTouch.none);
    });

    test('an older save that solved the box still loads, solved, with its clue and watch', () {
      final p = GameProgress.fromJson(
        jsonDecode(
              jsonEncode(
                const GameProgress(
                  detectiveName: 'MINYOUNG',
                  completedMissionIds: ['m01', 'm02', 'm03'],
                  attempts: {'m01': 1, 'm02': 1, 'm03': 2},
                  wrongAnswers: {'m03': 1},
                ).toJson(),
              ),
            )
            as Map<String, dynamic>,
      );
      expect(p.isCompleted('m03'), isTrue);
      expect(p.isUnlocked(ep01, 'm04'), isTrue);
      expect(p.collectedClues(ep01).map((c) => c.id), contains('c03'));
      expect(p.collectedEvidence(ep01).map((e) => e.id), contains('e03'));
      expect(XpBreakdown.of(m03, p).total, greaterThan(0));
    });
  });

  group('on screen', () {
    String count(WidgetTester t) => t.widget<Text>(find.byKey(const ValueKey('deduction-count'))).data!;
    bool ticked(WidgetTester t, String id) => t.widget<LookMark>(find.byKey(ValueKey('mark-$id'))).looked;
    Finder search() => find.ancestor(of: find.text('SEARCH HERE'), matching: find.byType(GameButton));
    Finder slip(String line) => find.text(line);

    Future<void> back(WidgetTester t) async {
      await t.tap(find.byWidgetPredicate((w) => w is IconButton && (w.tooltip == 'Back' || w.tooltip == 'Back to map')));
      await wait(t, const Duration(milliseconds: 800));
    }

    for (final size in const [Size(360, 640), Size(430, 932), Size(768, 1024)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('$tag: the traces noted, a wrong place, then behind the stone: the Pocket Watch', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'm03');
        expect(find.text('TAP TO OPEN'), findsNothing, reason: 'no envelope');
        expect(find.text('UNLOCK'), findsNothing);
        expect(count(t), 'CLUES 0 / 3');
        expect(findReadable(scene.task), findsOneWidget);
        expect(search(), findsNothing, reason: 'nothing to search before the traces');
        expect(find.byKey(const ValueKey('place-b')), findsNothing);
        await capture(t, 'case01_deduction_start_$tag');

        // Places holding nothing, and nothing at all: a line, never a wrong answer.
        await play.tapDeduction(t, scene.places.first.areas.first.center);
        expect(slip(scene.others.first.line), findsOneWidget);
        await play.tapDeduction(t, scene.guideAt);
        expect(slip(scene.missLine), findsOneWidget);
        expect(play.ref.read(gameControllerProvider).wrongCount('m03'), 0);

        // The three traces, one at a time; a trace tapped again is noted once.
        for (final (i, c) in scene.clues.indexed) {
          expect(ticked(t, c.id), isFalse);
          await play.tapDeduction(t, c.areas.last.center);
          expect(ticked(t, c.id), isTrue, reason: c.id);
          expect(find.byKey(ValueKey('note-${c.id}')), findsOneWidget, reason: c.id);
          if (i < 2) expect(count(t), 'CLUES ${i + 1} / 3');
        }
        await play.tapDeduction(t, clue('footprints').areas.first.center);
        expect(find.byKey(const ValueKey('note-footprints')), findsOneWidget, reason: 'noted once');

        // Choosing: the places are marked, nothing chosen yet.
        expect(count(t), 'YOUR NOTES');
        expect(findReadable(scene.chooseTask), findsOneWidget);
        for (final p in scene.places) {
          expect(find.byKey(ValueKey('place-${p.optionId}')), findsOneWidget);
        }
        expect(t.widget<GameButton>(search()).onPressed, isNull);
        await play.tapDeduction(t, clue('light').areas.first.center);
        expect(slip(scene.notPlaceLine), findsOneWidget, reason: 'the lamp is no hiding place');
        await capture(t, 'case01_deduction_choose_$tag');

        // Under the bench: not quite, counted once.
        await play.chooseAndSearch(t, scene, 'a');
        await wait(t, const Duration(milliseconds: 500));
        expect(find.text('Not quite!'), findsOneWidget);
        expect(findReadableContaining('the footprints do not go there'), findsOneWidget);
        var p = play.ref.read(gameControllerProvider);
        expect(p.wrongCount('m03'), 1);
        expect(p.isCompleted('m03'), isFalse);
        await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));

        // Behind the stone.
        await play.tapDeduction(t, scene.placeOf('b').areas.first.center);
        expect(find.text('Your choice: ${m03.answerLabel}'), findsOneWidget);
        await capture(t, 'case01_deduction_chosen_$tag');
        await play.tapKey(t, 'deduction-search', after: const Duration(milliseconds: 1500));
        p = play.ref.read(gameControllerProvider);
        expect(p.isCompleted('m03'), isTrue);
        expect(p.attempts['m03'], 2);
        expect(p.isUnlocked(ep01, 'm04'), isTrue);
        expect(p.collectedClues(ep01).map((c) => c.id), contains('c03'));
        expect(p.collectedEvidence(ep01).map((e) => e.id), contains('e03'));
        final moment = find.byKey(const ValueKey('discovery-moment'));
        expect(moment, findsOneWidget);
        expect(find.descendant(of: moment, matching: find.text('POCKET WATCH')), findsOneWidget);
        expect(find.descendant(of: moment, matching: findReadableContaining("7 o'clock")), findsWidgets);
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('360x640, text ×1.3: the notes and SEARCH HERE fit under the picture; solved', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(360, 640), 'm03', textScale: 1.3);
      final picture = t.getRect(find.byKey(const ValueKey('deduction-picture')));
      await play.noteClues(t, scene);
      await play.tapDeduction(t, scene.placeOf('b').areas.first.center);
      expect(t.takeException(), isNull);
      expect(picture.height, greaterThan(150), reason: 'the picture keeps its share');
      final button = t.getRect(find.text('SEARCH HERE'));
      expect(button.bottom, lessThanOrEqualTo(640), reason: 'SEARCH HERE in sight');
      await capture(t, 'case01_deduction_text13');
      await play.tapKey(t, 'deduction-search', after: const Duration(milliseconds: 1500));
      expect(play.ref.read(gameControllerProvider).isCompleted('m03'), isTrue);
    });

    testWidgets('both hints, then no more', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm03');
      await tapText(t, 'Get a Free Hint', after: const Duration(milliseconds: 600));
      await takeTipFromSheet(t);
      await reveal(t, findReadable(m03.hints[0]));
      expect(findReadable(m03.hints[0]), findsOneWidget);
      await tapText(t, 'Get More Hints', after: const Duration(milliseconds: 600));
      await takeTipFromSheet(t);
      await reveal(t, findReadable(m03.hints[1]));
      expect(findReadable(m03.hints[1]), findsOneWidget);
      expect(hintAction(), findsNothing, reason: 'at most two');
      expect(play.ref.read(gameControllerProvider).hintsFor('m03'), 2);
    });

    testWidgets('back is the place; the notes are kept on the page; a new visit or a restart starts again', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm03');
      await play.tapDeduction(t, clue('footprints').areas.first.center);
      await back(t);
      expect(find.text('INVESTIGATE'), findsOneWidget, reason: 'no letter step');
      final picture = t.widget<Image>(find.byKey(const ValueKey('story-picture')));
      expect((picture.image as AssetImage).assetName, scene.picture, reason: 'the place is its own scene');
      for (final line in m03.story) {
        expect(findReadable(line), findsOneWidget, reason: line);
      }
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 700));
      expect(count(t), 'CLUES 1 / 3', reason: 'kept while the page is open');
      await back(t);
      await back(t);
      expect(play.path(), Routes.map);
      play.ref.read(routerProvider).go(Routes.mission('m03'));
      await wait(t, const Duration(milliseconds: 1200));
      expect(count(t), 'CLUES 0 / 3', reason: 'a new visit');
      await play.restart(t);
      play.ref.read(routerProvider).go(Routes.mission('m03'));
      await wait(t, const Duration(milliseconds: 1200));
      expect(count(t), 'CLUES 0 / 3', reason: 'never saved');
    });

    testWidgets('SEARCH HERE tapped twice checks once; rewards paid once and kept after a restart', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm03');
      await play.noteClues(t, scene);
      await play.tapDeduction(t, scene.placeOf('b').areas.first.center);
      final button = find.byKey(const ValueKey('deduction-search'));
      await t.tap(button);
      await t.tap(button, warnIfMissed: false);
      await wait(t, const Duration(milliseconds: 1500));
      final p = play.ref.read(gameControllerProvider);
      expect(p.isCompleted('m03'), isTrue);
      expect(p.attempts['m03'], 1, reason: 'checked once');
      final wallet = play.ref.read(walletProvider);
      final xp = XpBreakdown.totalFor(ep01, p);
      await play.restart(t);
      final again = play.ref.read(gameControllerProvider);
      expect(again.isCompleted('m03'), isTrue);
      expect(XpBreakdown.totalFor(ep01, again), xp);
      expect(play.ref.read(walletProvider).balance, wallet.balance, reason: 'paid once, kept');
      expect(play.ref.read(walletProvider).entries, hasLength(wallet.entries.length));
      play.ref.read(routerProvider).go(Routes.mission('m03'));
      await wait(t, const Duration(milliseconds: 1200));
      expect(find.text('SOLVED'), findsOneWidget);
      expect(find.byKey(const ValueKey('deduction-picture')), findsNothing);
    });

    testWidgets('screen readers: the traces, then the places, are buttons that work', (t) async {
      final semantics = t.ensureSemantics();
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm03');
      for (final c in scene.clues) {
        expect(find.bySemanticsLabel(c.label), findsOneWidget, reason: c.id);
      }
      for (final c in scene.clues) {
        t.semantics.tap(find.semantics.byLabel(c.label));
        await wait(t, const Duration(milliseconds: 300));
      }
      expect(count(t), 'YOUR NOTES');
      for (final o in m03.options) {
        expect(find.bySemanticsLabel(o.label), findsOneWidget, reason: o.id);
      }
      t.semantics.tap(find.semantics.byLabel(m03.answerLabel));
      await wait(t, const Duration(milliseconds: 300));
      expect(find.text('Your choice: ${m03.answerLabel}'), findsOneWidget);
      semantics.dispose();
    });
  });
}
