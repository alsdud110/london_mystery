import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/core/utils/answer_checker.dart';
import 'package:london_mystery/core/utils/audio_service.dart';
import 'package:london_mystery/data/mock/season1/season1_inspections.dart';
import 'package:london_mystery/data/models/scene_inspect.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/mission/widgets/lens_inspect.dart' show noteLines;
import 'package:london_mystery/widgets/ink_icon.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';
import 'mission_play.dart';
import 'title_screen_test.dart' show capture;

/// Case 01 Mission 02 played by examining Room 4's exhibits under a
/// magnifying glass: the note pinned above ticks its lines as the exhibits
/// confirm them; the big grey slab of strange writing leads to its label
/// (ROOM 4, ROSETTA and a worn-away word), where the word is written. The
/// case data, its check, feedback, hints, Discovery, Clue, Evidence and
/// rewards are unchanged, and the word is never shown before it is written.
void main() {
  final season = MockEpisodeRepository.bundled();
  final ep01 = season.firstWhere((e) => e.id == 'ep01');
  final m02 = ep01.missionById('m02')!;
  final scene = inspectionOf(m02)!;
  InspectSpot spot(String id) => scene.spot(id);

  Size pngSize(String path) {
    final b = File(path).readAsBytesSync();
    int word(int at) => (b[at] << 24) | (b[at + 1] << 16) | (b[at + 2] << 8) | b[at + 3];
    return Size(word(16).toDouble(), word(20).toDouble());
  }

  group('the picture', () {
    test('the room is in the app, at the size its exhibits are measured on', () {
      expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/seasons/season_01_london/cases/case_01/'));
      expect(scene.picture, 'assets/seasons/season_01_london/cases/case_01/british_museum_room4_night.png');
      expect(pngSize(scene.picture), Size(scene.pixels.width, scene.pixels.height));
      expect(File('assets/seasons/season_01_london/cases/case_01/poster_british_museum.png').existsSync(), isTrue, reason: 'Case 01 M1 kept');
    });

    test('every exhibit is in the picture, inside its paper edge, apart from the others', () {
      expect(scene.spots.map((s) => s.id).toSet(),
          {'mask', 'mummyCase', 'cats', 'treasures', 'king', 'queen', 'slab', 'label', 'plinth'});
      for (final s in scene.spots) {
        for (final r in s.areas) {
          expect(scene.inside.contains(r.topLeft) && scene.inside.contains(r.bottomRight - const Offset(1e-6, 1e-6)), isTrue,
              reason: s.id);
        }
      }
      final areas = [for (final s in scene.spots) for (final r in s.areas) (s.id, r)];
      for (var i = 0; i < areas.length; i++) {
        for (var j = i + 1; j < areas.length; j++) {
          if (areas[i].$1 == areas[j].$1) continue;
          expect(areas[i].$2.overlaps(areas[j].$2), isFalse, reason: '${areas[i].$1} / ${areas[j].$1}');
        }
      }
    });

    test('on the narrowest phone each exhibit is a fingertip wide (the label is reached from the slab)', () {
      // 360 wide: the room inside its edge fills the width.
      final scale = 360 / (scene.inside.width * scene.pixels.width);
      const slack = 10.0;
      for (final s in scene.spots.where((s) => s.kind != InspectKind.label)) {
        final r = s.areas.first;
        expect(r.width * scene.pixels.width * scale + 2 * slack, greaterThanOrEqualTo(44), reason: s.id);
        expect(r.height * scene.pixels.height * scale + 2 * slack, greaterThanOrEqualTo(44), reason: s.id);
      }
    });

    test('the glass lands where it is meant to', () {
      for (final s in scene.spots) {
        expect(scene.hit(s.areas.first.center), s, reason: s.id);
      }
      expect(scene.hit(scene.lensAt), isNull, reason: 'it waits over the floor');
      // The king and the slab stand side by side: each its own.
      expect(scene.hit(scene.pixels.at(800, 400)), spot('king'));
      expect(scene.hit(scene.pixels.at(820, 400)), spot('slab'));
      // The label sits in the plinth: the plinth around it, the label itself.
      expect(scene.hit(scene.pixels.at(928, 714)), spot('label'));
      expect(scene.hit(scene.pixels.at(1100, 820)), spot('plinth'));
    });
  });

  group('the case is kept', () {
    test('the mission is as it was', () {
      expect(m02.answer, 'STONE');
      expect(m02.acceptedAnswers, contains('ROSETTA STONE'));
      expect(m02.prompt, 'ROSETTA _____');
      expect(m02.feedback['ROCK'], startsWith('Very close!'));
      expect(m02.hints, hasLength(2));
      expect(m02.clue!.id, 'c02');
      expect(m02.clue!.value, '4');
      expect(m02.clue!.symbol, 'museum');
      expect(m02.evidence!.id, 'e02');
    });

    test('Room 4 is the final lock\'s museum number (7924)', () {
      final fin = ep01.finalMission;
      expect(fin.answer, '7924');
      expect(fin.answer[fin.dialSymbols.indexOf(m02.clue!.symbol!)], m02.clue!.value);
      expect(scene.labelRoom, 'ROOM ${m02.clue!.value}');
    });

    test('the written word is checked as before', () {
      expect(AnswerChecker.isCorrect(m02, 'STONE'), isTrue);
      expect(AnswerChecker.isCorrect(m02, 'stone'), isTrue);
      expect(AnswerChecker.isCorrect(m02, 'ROSETTA STONE'), isTrue);
      expect(AnswerChecker.feedbackFor(m02, 'ROCK'), startsWith('Very close!'));
    });

    test('nothing here writes the word: not the room, the exhibits, the label or the key', () {
      final said = [
        scene.task, scene.nextTask, scene.dragGuide, scene.tapGuide, scene.missLine, scene.place,
        scene.labelTitle, scene.labelRoom, scene.labelWorn, scene.matchAction, scene.labelLink,
        for (final s in scene.spots) ...[s.title, s.label, s.line, s.lockedLine],
        // And what the mission's own page says before the answer.
        ...m02.story, m02.letterIntro, m02.letter, m02.question, m02.prompt!, ...m02.hints,
      ];
      for (final line in said) {
        expect(line.toLowerCase(), isNot(contains('stone')), reason: line);
      }
    });

    test('the note is the letter: the slab confirms line 1, its label lines 2 and 3; line 4 is the word', () {
      expect(noteLines(m02), [
        'It helped people read old Egyptian writing.',
        'Its name has two words.',
        'The first word is ROSETTA.',
        'The second word means a hard piece of rock.',
      ]);
      expect(spot('slab').checks, {0});
      expect(spot('label').checks, {1, 2});
      expect(scene.taskLine, 3);
      for (final s in scene.spots.where((s) => s.kind == InspectKind.exhibit)) {
        expect(s.checks, isEmpty, reason: '${s.id} confirms nothing');
      }
    });
  });

  group('on screen', () {
    Finder room() => find.byKey(const ValueKey('inspect-room'));
    Finder card(String id) => find.byKey(ValueKey('inspect-card-$id'));
    Finder label() => find.byKey(const ValueKey('inspect-label'));
    String count(WidgetTester t) => t.widget<Text>(find.byKey(const ValueKey('inspect-note-count'))).data!;
    bool ticked(WidgetTester t, String id) => find.byKey(ValueKey('tick-$id')).evaluate().isNotEmpty;
    bool lineConfirmed(WidgetTester t, int i) => find
        .descendant(of: find.byKey(ValueKey('note-line-$i')), matching: find.byWidgetPredicate((w) => w is InkIcon && w.glyph == InkGlyph.check))
        .evaluate()
        .isNotEmpty;
    bool lineIsTask(WidgetTester t, int i) => find
        .descendant(of: find.byKey(ValueKey('note-line-$i')), matching: find.byWidgetPredicate((w) => w is InkIcon && w.glyph == InkGlyph.pen))
        .evaluate()
        .isNotEmpty;

    /// No text on screen says the word before it is written.
    void neverTheWord(WidgetTester t, String when) {
      for (final e in find.byType(Text).evaluate()) {
        final w = e.widget as Text;
        final text = (w.data ?? w.textSpan?.toPlainText(includeSemanticsLabels: false) ?? '').toLowerCase();
        expect(text, isNot(contains('stone')), reason: '$when: "$text"');
      }
      for (final e in find.byType(EditableText).evaluate()) {
        expect((e.widget as EditableText).controller.text.toLowerCase(), isNot(contains('stone')), reason: when);
      }
    }

    Future<void> back(WidgetTester t) async {
      await t.tap(find.byWidgetPredicate((w) => w is IconButton && (w.tooltip == 'Back' || w.tooltip == 'Back to map')));
      await wait(t, const Duration(milliseconds: 800));
    }

    for (final size in const [Size(360, 640), Size(430, 932), Size(768, 1024)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('$tag: the room, then the glass: no envelope step; the story and the note kept', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'm02');
        expect(room(), findsOneWidget);
        expect(find.text('CHECK ANSWER'), findsNothing, reason: 'no word to write before the label');
        expect(findReadable(scene.task), findsOneWidget);
        expect(count(t), '0 / 4');
        for (final line in noteLines(m02)) {
          await reveal(t, findReadable(line));
          expect(findReadable(line), findsOneWidget, reason: 'the note, word for word');
        }
        neverTheWord(t, 'arriving');
        await capture(t, 'case01_inspect_start_$tag');
        await back(t);
        final picture = t.widget<Image>(find.byKey(const ValueKey('story-picture')));
        expect((picture.image as AssetImage).assetName, scene.picture);
        for (final line in m02.story) {
          expect(findReadable(line), findsOneWidget, reason: 'the story is kept');
        }
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 700));
        expect(find.text('TAP TO OPEN'), findsNothing);
        expect(room(), findsOneWidget);
      });

      testWidgets('$tag: exhibits under the glass, the slab, the key, the label: ROCK, then ROSETTA STONE', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'm02');
        // Before the slab: its plinth and label say nothing yet.
        await play.tapInspect(t, spot('plinth').areas.first.center);
        expect(find.text(spot('plinth').lockedLine), findsOneWidget);
        await play.tapInspect(t, spot('label').areas.first.center);
        expect(find.text(spot('label').lockedLine), findsOneWidget);
        expect(label(), findsNothing);
        // The glass dragged onto the mask, then lifted: what it shows.
        await play.dragGlass(t, scene.lensAt, spot('mask').areas.first.center);
        expect(findReadable(spot('mask').line), findsOneWidget);
        expect(ticked(t, 'mask'), isTrue);
        // Resting on the mummy case examines it, the finger still down.
        final resting = await play.dragGlass(t, spot('mask').areas.first.center, spot('mummyCase').areas.first.center, lift: false);
        await wait(t, const Duration(milliseconds: 700));
        expect(findReadable(spot('mummyCase').line), findsOneWidget);
        expect(ticked(t, 'mummyCase'), isTrue);
        await resting.up();
        await wait(t, const Duration(milliseconds: 400));
        // The rest, tapped.
        for (final id in ['cats', 'treasures', 'king', 'queen']) {
          await play.tapInspect(t, spot(id).areas.first.center);
          expect(findReadable(spot(id).line), findsOneWidget, reason: id);
          expect(ticked(t, id), isTrue, reason: id);
        }
        expect(count(t), '0 / 4', reason: 'none of them is it');
        expect(play.ref.read(gameControllerProvider).wrongCount('m02'), 0);
        expect(play.ref.read(gameControllerProvider).attempts['m02'] ?? 0, 0);
        neverTheWord(t, 'the exhibits');
        // The slab: strange writing, big and grey — the note's first line.
        await play.tapInspect(t, spot('slab').areas.first.center);
        expect(card('slab'), findsOneWidget);
        expect(findReadable(spot('slab').line), findsOneWidget);
        neverTheWord(t, 'the slab');
        await capture(t, 'case01_inspect_slab_$tag');
        await play.tapKey(t, 'inspect-close');
        expect(count(t), '1 / 4');
        expect(lineConfirmed(t, 0), isTrue);
        expect(findReadable(scene.nextTask), findsOneWidget);
        // The plinth now: the golden key (optional).
        await play.tapInspect(t, spot('plinth').areas.first.center);
        expect(card('plinth'), findsOneWidget);
        expect(find.text(spot('plinth').title), findsOneWidget);
        expect(find.byWidgetPredicate((w) => w is InkIcon && w.glyph == InkGlyph.key), findsOneWidget);
        // ROOM 4 (the final lock's number) and the tag naming the next stop,
        // read where the key is found (2026-10-23, approved).
        expect(find.text(spot('plinth').line), findsOneWidget);
        expect(spot('plinth').line, allOf(contains('ROOM 4'), contains("My next stop is where London's biggest bell rings.")));
        expect(t.takeException(), isNull, reason: '$tag: the key card fits');
        neverTheWord(t, 'the key');
        await capture(t, 'case01_inspect_key_$tag');
        await tapText(t, 'Tap to keep looking', after: const Duration(milliseconds: 400));
        // The label, from the panel: ROOM 4, ROSETTA and the worn word.
        await tapText(t, scene.labelLink, after: const Duration(milliseconds: 500));
        expect(label(), findsOneWidget);
        expect(find.text('ROOM 4'), findsOneWidget);
        expect(find.text('ROSETTA _____'), findsOneWidget);
        expect(count(t), '3 / 4');
        expect(lineConfirmed(t, 1) && lineConfirmed(t, 2), isTrue);
        expect(lineIsTask(t, 3), isTrue, reason: 'the word still to write');
        neverTheWord(t, 'the label');
        await capture(t, 'case01_inspect_label_$tag');
        // ROCK: very close, counted once, the label still open.
        await play.writeOnLabel(t, 'ROCK');
        await wait(t, const Duration(milliseconds: 400));
        expect(find.text('Not quite!'), findsOneWidget);
        expect(findReadableContaining('Very close!'), findsOneWidget);
        expect(play.ref.read(gameControllerProvider).wrongCount('m02'), 1);
        await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
        expect(label(), findsOneWidget);
        neverTheWord(t, 'after ROCK');
        // ROSETTA STONE.
        await play.writeOnLabel(t, 'ROSETTA STONE');
        await wait(t, const Duration(milliseconds: 1200));
        final p = play.ref.read(gameControllerProvider);
        expect(p.isCompleted('m02'), isTrue);
        expect(p.wrongCount('m02'), 1);
        expect(p.attempts['m02'], 2);
        expect(p.isUnlocked(ep01, 'm03'), isTrue);
        expect(p.collectedClues(ep01).map((c) => c.id), contains('c02'));
        expect(p.collectedEvidence(ep01).map((e) => e.id), contains('e02'));
        expect(findReadable('The stone that helped people read old Egyptian writing.'), findsOneWidget, reason: 'its Discovery');
      });
    }

    testWidgets('STONE alone is the answer; a second CHECK ANSWER checks once; kept after a restart', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm02');
      await play.openInspectLabel(t, scene);
      final field = find.descendant(of: label(), matching: find.byType(TextField));
      await reveal(t, field);
      await t.enterText(field, 'stone');
      await t.pump();
      final check = find.descendant(of: label(), matching: find.text('CHECK ANSWER'));
      await reveal(t, check);
      await t.tap(check);
      await t.tap(check, warnIfMissed: false);
      await wait(t, const Duration(milliseconds: 1200));
      final p = play.ref.read(gameControllerProvider);
      expect(p.isCompleted('m02'), isTrue);
      expect(p.attempts['m02'], 1, reason: 'checked once');
      final wallet = play.ref.read(walletProvider);
      await play.restart(t);
      expect(play.ref.read(gameControllerProvider).isCompleted('m02'), isTrue);
      expect(play.ref.read(walletProvider).balance, wallet.balance, reason: 'paid once, kept');
      expect(play.ref.read(walletProvider).entries, hasLength(wallet.entries.length));
    });

    testWidgets('back closes the label, then the room; the room is as it was; a new visit starts again', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm02');
      await play.tapInspect(t, spot('mask').areas.first.center);
      await play.openInspectLabel(t, scene);
      await back(t);
      expect(label(), findsNothing, reason: 'the label closed first');
      expect(room(), findsOneWidget);
      await back(t);
      expect(find.text('INVESTIGATE'), findsOneWidget);
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 700));
      expect(ticked(t, 'mask') && ticked(t, 'slab'), isTrue, reason: 'what was examined is kept');
      expect(count(t), '3 / 4');
      // The match card closes on back too.
      await play.tapInspect(t, spot('slab').areas.first.center);
      expect(card('slab'), findsOneWidget);
      await back(t);
      expect(card('slab'), findsNothing);
      // Away to the map and back: the room again, examined afresh.
      await back(t);
      await back(t);
      expect(play.path(), Routes.map);
      play.ref.read(routerProvider).go(Routes.mission('m02'));
      await wait(t, const Duration(milliseconds: 1200));
      expect(room(), findsOneWidget);
      expect(count(t), '0 / 4');
    });

    testWidgets('both hints: from the panel, then on the label', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm02');
      await tapText(t, 'Get a Free Hint', after: const Duration(milliseconds: 600));
      await takeTipFromSheet(t);
      expect(findReadable(m02.hints[0]), findsOneWidget);
      await play.openInspectLabel(t, scene);
      await press(t, find.descendant(of: label(), matching: find.text('Get More Hints')));
      await takeTipFromSheet(t);
      await wait(t, const Duration(milliseconds: 400));
      final onLabel = find.descendant(of: label(), matching: findReadable(m02.hints[1]));
      await reveal(t, onLabel);
      expect(onLabel, findsOneWidget);
      expect(find.text('Get More Hints'), findsNothing, reason: 'at most two');
    });

    testWidgets('the label with the keyboard up: the field and CHECK ANSWER in reach', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(360, 640), 'm02');
      await play.openInspectLabel(t, scene);
      final field = find.descendant(of: label(), matching: find.byType(TextField));
      await reveal(t, field);
      await t.tap(field);
      await t.enterText(field, 'RO');
      t.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      addTearDown(t.view.resetViewInsets);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      final keyboardTop = 640.0 - 300;
      expect(t.getRect(field).bottom, lessThanOrEqualTo(keyboardTop), reason: 'the field above the keyboard');
      final check = find.descendant(of: label(), matching: find.text('CHECK ANSWER'));
      await reveal(t, check);
      expect(t.getRect(check).bottom, lessThanOrEqualTo(keyboardTop), reason: 'CHECK ANSWER in reach');
      expect(t.widget<TextField>(field).controller!.text, 'RO');
    });

    testWidgets('360x640, text ×1.3: the note, the room and the label fit; solved', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(360, 640), 'm02', textScale: 1.3);
      expect(t.getSize(room()).height, greaterThan(100), reason: 'the room keeps its share');
      await play.tapInspect(t, spot('mask').areas.first.center);
      await play.openInspectLabel(t, scene);
      // The note scrolls with large text: the line now to answer is brought
      // into view as it gets the pencil.
      await wait(t, const Duration(milliseconds: 400));
      final note = t.getRect(find.byKey(const ValueKey('inspect-note-scroll')));
      final task = t.getRect(find.byKey(const ValueKey('note-line-3')));
      expect(task.top >= note.top - 0.5 && task.bottom <= note.bottom + 0.5, isTrue, reason: 'the pencilled line in view');
      await reveal(t, find.descendant(of: label(), matching: find.text('CHECK ANSWER')));
      await capture(t, 'case01_inspect_label_text13');
      await play.writeOnLabel(t, 'STONE');
      await wait(t, const Duration(milliseconds: 1200));
      expect(play.ref.read(gameControllerProvider).isCompleted('m02'), isTrue);
    });

    testWidgets('the glass enlarges the picture around the point under the finger, and stays in the room', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm02');
      for (final id in ['mask', 'queen', 'slab']) {
        if (find.byKey(ValueKey('inspect-card-$id')).evaluate().isNotEmpty) await play.tapKey(t, 'inspect-close');
        final g = await play.dragGlass(t, scene.lensAt, spot(id).areas.first.center, lift: false);
        final magnifier = t.widget<RawMagnifier>(find.byType(RawMagnifier));
        expect(magnifier.magnificationScale, greaterThan(2));
        final lens = t.getRect(find.byType(RawMagnifier));
        final focal = play.inspectAt(t, spot(id).areas.first.center);
        expect((lens.center + magnifier.focalPointOffset - focal).distance, lessThan(1), reason: '$id: it shows the point under the finger');
        final roomRect = t.getRect(room());
        expect(lens.left >= roomRect.left - 0.5 && lens.right <= roomRect.right + 0.5, isTrue, reason: '$id: whole on screen');
        await g.up();
        await wait(t, const Duration(milliseconds: 500));
      }
    });

    testWidgets('sounds: an exhibit is a pencil note, the label a rustle; the word, the discovery cue', (t) async {
      final audio = MockAudioService();
      final play = MissionPlay(audio: audio);
      await play.openPuzzle(t, const Size(390, 844), 'm02');
      audio.played.clear();
      await play.tapInspect(t, spot('mask').areas.first.center);
      expect(audio.played, [GameSound.pencilNote]);
      await play.tapInspect(t, scene.lensAt);
      expect(audio.played, [GameSound.pencilNote], reason: 'the floor is quiet');
      await play.tapInspect(t, spot('slab').areas.first.center);
      expect(audio.played.last, GameSound.pencilNote);
      await play.tapKey(t, 'inspect-read-label', after: const Duration(milliseconds: 500));
      expect(audio.played.last, GameSound.paperRustle);
      audio.played.clear();
      await play.writeOnLabel(t, 'STONE');
      expect(audio.played, contains(GameSound.puzzleCorrect));
    });

    testWidgets('screen readers: every exhibit is a button; the slab is examined from its button', (t) async {
      final semantics = t.ensureSemantics();
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm02');
      for (final s in scene.spots) {
        expect(find.bySemanticsLabel(s.label), findsOneWidget, reason: s.id);
      }
      expect(find.bySemanticsLabel('Confirmed 0 of 4'), findsOneWidget);
      t.semantics.tap(find.semantics.byLabel(spot('slab').label));
      await wait(t, const Duration(milliseconds: 500));
      expect(card('slab'), findsOneWidget);
      await play.tapKey(t, 'inspect-close');
      expect(find.bySemanticsLabel('${spot('slab').label}, examined'), findsOneWidget);
      expect(find.bySemanticsLabel('Confirmed 1 of 4'), findsOneWidget);
      semantics.dispose();
    });
  });
}
