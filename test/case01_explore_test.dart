import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/utils/audio_service.dart';
import 'package:world_mystery/data/mock/season1/season1_explores.dart';
import 'package:world_mystery/data/models/investigation.dart';
import 'package:world_mystery/data/models/scene_explore.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/wallet_controller.dart';
import 'package:world_mystery/widgets/game_button.dart';
import 'package:world_mystery/widgets/ink_icon.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';
import 'mission_play.dart';
import 'title_screen_test.dart' show capture;

/// Case 01 Mission 01 played by looking round King's Cross at night: the
/// old suitcase on the bench holds the thief's letter, Platform 9's sign
/// is there to note, and the station's poster board is where the museum is
/// chosen. The choice is the puzzle's answer: the case data, its feedback,
/// hints, Discovery, evidence and rewards are unchanged.
void main() {
  final season = MockEpisodeRepository.bundled();
  final ep01 = season.firstWhere((e) => e.id == 'ep01');
  final m01 = ep01.missionById('m01')!;
  final scene = exploreOf(m01)!;
  ExploreSpot spot(String id) => scene.spot(id);

  /// A PNG's width and height, read from its header.
  Size pngSize(String path) {
    final b = File(path).readAsBytesSync();
    int word(int at) => (b[at] << 24) | (b[at + 1] << 16) | (b[at + 2] << 8) | b[at + 3];
    return Size(word(16).toDouble(), word(20).toDouble());
  }

  group('the pictures', () {
    test('the five pictures are in the app, at the sizes the scene is measured on', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('- assets/seasons/season_01_london/cases/case_01/'));
      expect(pngSize(scene.picture), Size(scene.pixels.width, scene.pixels.height));
      expect(scene.choices, hasLength(4));
      for (final c in scene.choices) {
        final s = pngSize(c.picture);
        expect(s.width / s.height, closeTo(scene.pictureAspect, 0.001), reason: c.picture);
      }
      expect(File('assets/seasons/season_01_london/locations/kings_cross/kings_cross_waiting_hall.png').existsSync(), isTrue, reason: 'kept');
    });

    test('the suitcase, the sign and the board: inside the picture, apart, a fingertip wide', () {
      final main = [spot('suitcase'), spot('platform'), spot('posters')];
      for (final s in main) {
        for (final r in s.areas) {
          expect(scene.inside.contains(r.topLeft) && scene.inside.contains(r.bottomRight - const Offset(1e-6, 1e-6)), isTrue,
              reason: s.id);
          expect(scene.opening.overlaps(r), isTrue, reason: '${s.id} is in the opening view');
          // On the narrowest phone, the whole picture 360 wide.
          expect(r.width * 360 >= 40 && r.height * 240 >= 40, isTrue, reason: '${s.id} is a fingertip wide');
        }
      }
      for (var i = 0; i < main.length; i++) {
        for (var j = i + 1; j < main.length; j++) {
          expect(main[i].areas.first.overlaps(main[j].areas.first), isFalse, reason: '${main[i].id} / ${main[j].id}');
        }
      }
      for (final o in scene.others) {
        if (o.label == 'The bench') continue; // the suitcase lies on it, and is found first
        for (final s in main) {
          expect(o.areas.first.overlaps(s.areas.first), isFalse, reason: '${o.label} / ${s.id}');
        }
      }
    });

    test('a tap lands where it is meant to', () {
      expect(scene.hit(spot('suitcase').areas.first.center), spot('suitcase'));
      expect(scene.hit(spot('platform').areas.first.center), spot('platform'));
      expect(scene.hit(spot('posters').areas.first.center), spot('posters'));
      expect((scene.hit(scene.pixels.at(950, 220))! as InvestigationSpot).label, 'The station clock');
      // The empty floor in front of the board: nothing, never an error.
      expect(scene.hit(scene.pixels.at(760, 940)), isNull);
      // Just off the sign's edge, within a fingertip: still the sign.
      final edge = spot('platform').areas.first;
      expect(scene.hit(Offset(edge.right + 0.004, edge.center.dy), slack: const Size(0.01, 0.01)), spot('platform'));
    });
  });

  group('the case is kept', () {
    test('the mission is as it was: the letter, the four museums, B', () {
      expect(m01.answer, 'b');
      expect(m01.letter, contains('old mummies from Egypt and a famous stone'));
      expect(m01.options.map((o) => o.id), ['a', 'b', 'c', 'd']);
      expect(m01.clue!.value, '9');
      expect(m01.evidence!.id, 'e01');
      expect(m01.hints, hasLength(2));
    });

    test('each poster is one of its options; the British Museum is the answer', () {
      expect(scene.choices.map((c) => c.optionId), ['a', 'b', 'c', 'd']);
      final right = scene.choices.firstWhere((c) => c.optionId == m01.answer);
      expect(right.picture, endsWith('poster_british_museum.png'));
      expect(m01.options.firstWhere((o) => o.id == m01.answer).label, startsWith('The British Museum'));
    });

    test('Platform 9 says the case\'s own clue, and nothing needs it', () {
      expect(spot('platform').kind, ExploreKind.note);
      expect(spot('platform').line, m01.clue!.note);
      expect(spot('posters').requires, 'suitcase', reason: 'the letter, not the sign, opens the choice');
    });
  });

  group('on screen', () {
    Finder card(String id) => find.byKey(ValueKey('explore-card-$id'));
    Finder choice() => find.byKey(const ValueKey('explore-choice'));
    /// Whether [id]'s glass has turned to a tick (looked at).
    bool ticked(WidgetTester t, String id) => find
        .descendant(of: find.byKey(ValueKey('mark-$id')), matching: find.byWidgetPredicate((w) => w is InkIcon && w.glyph == InkGlyph.check))
        .evaluate()
        .isNotEmpty;

    Future<void> back(WidgetTester t) async {
      await t.tap(find.byWidgetPredicate((w) => w is IconButton && (w.tooltip == 'Back' || w.tooltip == 'Back to map')));
      await wait(t, const Duration(milliseconds: 800));
    }

    for (final size in const [Size(360, 640), Size(430, 932), Size(768, 1024)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('$tag: the station at night, then a look round: no envelope step', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'm01');
        expect(find.byKey(const ValueKey('explore-picture')), findsOneWidget);
        expect(find.text('CHECK ANSWER'), findsNothing);
        expect(findReadable(scene.task), findsOneWidget);
        for (final s in scene.spots) {
          expect(find.byKey(ValueKey('mark-${s.id}')), findsOneWidget, reason: s.id);
        }
        await capture(t, 'case01_explore_start_$tag');
        // Back: the place, with the station's own picture; INVESTIGATE goes
        // straight back to the look round (no letter step).
        await back(t);
        final picture = t.widget<Image>(find.byKey(const ValueKey('story-picture')));
        expect((picture.image as AssetImage).assetName, scene.picture);
        for (final line in m01.story) {
          expect(findReadable(line), findsOneWidget, reason: 'the story is kept');
        }
        await capture(t, 'case01_story_$tag');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 700));
        expect(find.text('TAP TO OPEN'), findsNothing);
        expect(find.byKey(const ValueKey('explore-picture')), findsOneWidget);
      });

      testWidgets('$tag: suitcase → letter; the sign noted; the board; a wrong museum, then the British Museum', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'm01');
        // The board first: the letter has not been found.
        await play.tapExplore(t, spot('posters').areas.first.center);
        expect(choice(), findsNothing);
        expect(find.text(spot('posters').lockedLine), findsOneWidget);
        // The suitcase: its letter, sealed.
        await play.tapExplore(t, spot('suitcase').areas.first.center);
        expect(card('suitcase'), findsOneWidget);
        expect(findReadable(m01.letterIntro), findsOneWidget);
        expect(play.sealedLetter(), findsOneWidget);
        await capture(t, 'case01_suitcase_sealed_$tag');
        // Closed unread: the board asks for the letter.
        await play.tapKey(t, 'explore-close');
        await play.tapExplore(t, spot('posters').areas.first.center);
        expect(choice(), findsNothing);
        expect(find.text(spot('posters').unreadLine), findsOneWidget);
        // Read it.
        await play.readExploreDocument(t, scene);
        expect(findReadable(scene.nextTask), findsOneWidget, reason: 'what to do now');
        expect(ticked(t, 'suitcase'), isTrue);
        expect(ticked(t, 'platform'), isFalse);
        // Opened again from the panel: open at once.
        await tapText(t, scene.documentLabel, after: const Duration(milliseconds: 500));
        expect(play.sealedLetter(), findsNothing);
        expect(findReadableContaining('old mummies from Egypt and a famous stone'), findsOneWidget);
        await capture(t, 'case01_letter_$tag');
        await play.tapKey(t, 'explore-close');
        // Platform 9: a note, a tap closes it.
        await play.tapExplore(t, spot('platform').areas.first.center);
        expect(card('platform'), findsOneWidget);
        expect(findReadable(spot('platform').line), findsOneWidget);
        await capture(t, 'case01_platform_$tag');
        // Its dotted words open their meaning; anywhere else closes it.
        await tapText(t, 'Tap to keep looking', after: const Duration(milliseconds: 400));
        expect(card('platform'), findsNothing);
        // Looking was never a wrong answer.
        expect(play.ref.read(gameControllerProvider).wrongCount('m01'), 0);
        expect(play.ref.read(gameControllerProvider).attempts['m01'] ?? 0, 0);
        // The board: four posters, named; CHECK ANSWER waits for one.
        await play.tapExplore(t, spot('posters').areas.first.center);
        expect(choice(), findsOneWidget);
        for (final o in m01.options) {
          expect(find.byKey(ValueKey('poster-${o.id}')), findsOneWidget);
        }
        expect(findReadable('The British Museum'), findsOneWidget);
        expect(findReadable('treasures from long ago'), findsOneWidget);
        expect(t.widget<GameButton>(find.byKey(const ValueKey('explore-check'))).onPressed, isNull);
        await capture(t, 'case01_posters_$tag');
        // A wrong museum: its own line, counted once, and another try.
        await play.chooseInExplore(t, scene, 'a');
        await wait(t, const Duration(milliseconds: 400));
        expect(find.text('Not quite!'), findsOneWidget);
        expect(findReadableContaining('Dinosaur bones are very old, too.'), findsOneWidget);
        expect(play.ref.read(gameControllerProvider).wrongCount('m01'), 1);
        await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
        expect(choice(), findsOneWidget, reason: 'back on the posters');
        // The British Museum.
        await play.chooseInExplore(t, scene, 'b');
        await wait(t, const Duration(milliseconds: 1200));
        final p = play.ref.read(gameControllerProvider);
        expect(p.isCompleted('m01'), isTrue);
        expect(p.wrongCount('m01'), 1);
        expect(p.attempts['m01'], 2);
        expect(p.isUnlocked(ep01, 'm02'), isTrue);
        expect(p.collectedEvidence(ep01).map((e) => e.id), contains('e01'));
        expect(p.collectedClues(ep01).map((c) => c.id), contains('c01'));
        expect(
          findReadable('Old mummies and a famous stone: the thief is going to the big museum.'),
          findsOneWidget,
          reason: 'its Discovery Moment',
        );
      });
    }

    testWidgets('back closes the posters first, then goes to the place; what was looked at is kept', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm01');
      await play.readExploreDocument(t, scene);
      await play.tapExplore(t, spot('posters').areas.first.center);
      expect(choice(), findsOneWidget);
      await back(t);
      expect(choice(), findsNothing);
      expect(find.byKey(const ValueKey('explore-picture')), findsOneWidget);
      await back(t);
      expect(find.text('INVESTIGATE'), findsOneWidget);
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 700));
      expect(ticked(t, 'suitcase'), isTrue);
      expect(findReadable(scene.nextTask), findsOneWidget, reason: 'the letter is still read');
      await play.tapExplore(t, spot('posters').areas.first.center);
      expect(choice(), findsOneWidget, reason: 'no need to find the letter again');
      // The posters' own close.
      await play.tapKey(t, 'explore-choice-close');
      expect(choice(), findsNothing);
    });

    testWidgets('both hints: from the panel, then from the posters', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm01');
      await tapText(t, 'Get a Free Hint', after: const Duration(milliseconds: 600));
      await takeTipFromSheet(t);
      await wait(t, const Duration(milliseconds: 400));
      await reveal(t, findReadable(m01.hints[0]));
      expect(findReadable(m01.hints[0]), findsOneWidget);
      await play.readExploreDocument(t, scene);
      await play.tapExplore(t, spot('posters').areas.first.center);
      await tapText(t, 'Get More Hints', after: const Duration(milliseconds: 600));
      await takeTipFromSheet(t);
      await wait(t, const Duration(milliseconds: 400));
      final onPosters = find.descendant(of: choice(), matching: findReadable(m01.hints[1]));
      await reveal(t, onPosters);
      expect(onPosters, findsOneWidget);
      expect(find.text('Get More Hints'), findsNothing, reason: 'at most two');
    });

    testWidgets('a second tap on CHECK ANSWER checks once; the solve is kept after a restart', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm01');
      await play.readExploreDocument(t, scene);
      await play.tapExplore(t, spot('posters').areas.first.center);
      await play.tapKey(t, 'poster-b', after: const Duration(milliseconds: 200));
      final check = find.byKey(const ValueKey('explore-check'));
      await reveal(t, check);
      await t.tap(check);
      await t.tap(check, warnIfMissed: false);
      await wait(t, const Duration(milliseconds: 1200));
      final p = play.ref.read(gameControllerProvider);
      expect(p.isCompleted('m01'), isTrue);
      expect(p.attempts['m01'], 1, reason: 'checked once');
      final wallet = play.ref.read(walletProvider);
      await play.restart(t);
      expect(play.ref.read(gameControllerProvider).isCompleted('m01'), isTrue);
      expect(play.ref.read(walletProvider).balance, wallet.balance, reason: 'paid once, kept');
      expect(play.ref.read(walletProvider).entries, hasLength(wallet.entries.length));
    });

    testWidgets('360x640, text ×1.3: the letter card and the posters fit and scroll', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(360, 640), 'm01', textScale: 1.3);
      await play.tapExplore(t, spot('suitcase').areas.first.center);
      await reveal(t, find.byKey(const ValueKey('explore-close')));
      await play.readExploreDocument(t, scene);
      await play.tapExplore(t, spot('posters').areas.first.center);
      for (final o in m01.options) {
        await reveal(t, find.byKey(ValueKey('poster-${o.id}')));
      }
      await reveal(t, find.byKey(const ValueKey('explore-check')));
      await capture(t, 'case01_posters_text13');
      await play.chooseInExplore(t, scene, 'b');
      await wait(t, const Duration(milliseconds: 1200));
      expect(play.ref.read(gameControllerProvider).isCompleted('m01'), isTrue);
    });

    testWidgets('sounds: a look is a pencil note, the envelope its own, the posters a rustle; then the answer', (t) async {
      final audio = MockAudioService();
      final play = MissionPlay(audio: audio);
      await play.openPuzzle(t, const Size(390, 844), 'm01');
      audio.played.clear();
      await play.tapExplore(t, spot('suitcase').areas.first.center);
      expect(audio.played, [GameSound.pencilNote]);
      await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1600));
      expect(audio.played, [GameSound.pencilNote, GameSound.envelopeOpen]);
      await play.tapKey(t, 'explore-close');
      // A place holding nothing is quiet.
      await play.tapExplore(t, scene.pixels.at(950, 220));
      expect(audio.played, [GameSound.pencilNote, GameSound.envelopeOpen]);
      await play.tapExplore(t, spot('posters').areas.first.center);
      expect(audio.played.last, GameSound.paperRustle);
      audio.played.clear();
      await play.tapKey(t, 'poster-a', after: const Duration(milliseconds: 200));
      expect(audio.played, isEmpty, reason: 'choosing a poster is quiet');
      await play.tapKey(t, 'explore-check', after: const Duration(milliseconds: 400));
      expect(audio.played, [GameSound.puzzleWrong]);
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
      audio.played.clear();
      await play.chooseInExplore(t, scene, 'b');
      expect(audio.played, contains(GameSound.puzzleCorrect));
      expect(audio.played, isNot(contains(GameSound.padlockOpen)), reason: 'no lock here');
    });

    testWidgets('a wrong museum, then the letter opened again from the station: a second look', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm01');
      await play.readExploreDocument(t, scene);
      await play.chooseInExplore(t, scene, 'c');
      await wait(t, const Duration(milliseconds: 400));
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
      expect(play.ref.read(gameControllerProvider).behavior!.rechecked, isEmpty);
      await play.tapKey(t, 'explore-choice-close');
      await tapText(t, scene.documentLabel, after: const Duration(milliseconds: 500));
      expect(play.ref.read(gameControllerProvider).behavior!.rechecked, ['m01']);
    });

    testWidgets('screen readers: the things to look at and the posters are named', (t) async {
      final semantics = t.ensureSemantics();
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm01');
      for (final s in scene.spots) {
        expect(find.bySemanticsLabel(s.label), findsOneWidget, reason: s.id);
      }
      expect(find.bySemanticsLabel(scene.place), findsOneWidget);
      await play.readExploreDocument(t, scene);
      expect(find.bySemanticsLabel('${spot('suitcase').label}, looked at'), findsOneWidget);
      await play.tapExplore(t, spot('posters').areas.first.center);
      expect(find.bySemanticsLabel(RegExp(r'^The British Museum, treasures from long ago\. Poster: .*mummy')), findsOneWidget);
      semantics.dispose();
    });
  });
}
