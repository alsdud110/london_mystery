import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:world_mystery/features/mission/widgets/evidence_recall.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';
import 'mission_play.dart';
import 'title_screen_test.dart' show capture;

/// London Case 02–12 gameplay upgrade (2026-10-30,
/// docs/LONDON_GAMEPLAY_UPGRADE_PROGRESS.md): each puzzle played on its new
/// engine at every level and on small and large phones, its answer, save and
/// rewards the mission's own.
void main() {
  final season = MockEpisodeRepository.bundled();
  Episode caseOf(String missionId) => season.firstWhere((e) => e.allMissions.any((m) => m.id == missionId));
  Mission at(String missionId, Difficulty level) =>
      DifficultyContent.episodeAt(caseOf(missionId), level).missionById(missionId)!;

  const sizes = [(Size(360, 640), 1.0, '360x640'), (Size(390, 844), 1.0, '390x844'), (Size(360, 640), 1.3, '360x640_x1.3')];

  /// Opens both hints on a search page (the free one, then the paid one).
  Future<void> bothHints(WidgetTester t) async {
    await tapText(t, 'Get a Free Hint', after: const Duration(milliseconds: 600));
    await tapText(t, 'Get More Hints', after: const Duration(milliseconds: 600));
    await takeTipFromSheet(t);
    await wait(t, const Duration(milliseconds: 400));
  }

  group('Case 02 — the belfry, the Time Card, the Great Clock', () {
    test('the belfry: each level reads its own letter, the find its own line', () {
      for (final level in Difficulty.values) {
        final m = at('ep02_m2', level);
        final scene = SeasonCatalog.investigation(m)!;
        expect(scene.answer, m.answer, reason: level.name);
        expect(m.letter, contains(scene.finds.single.reportLine), reason: '${level.name}: the line is the letter\'s, word for word');
        expect(m.letter.toLowerCase(), contains('not'), reason: 'the note says where the gear is not');
        for (final line in [scene.task, scene.missLine, ...scene.arrival, for (final s in scene.spots) s.line]) {
          expect(line.toLowerCase(), isNot(contains('smallest')), reason: '${level.name}: "$line" gives the bell away');
        }
      }
    });

    test('the Time Card brings the stopped time from the notebook', () {
      final m = caseOf('ep02_m3').missionById('ep02_m3')!;
      expect(m.recall!.evidenceId, 'ep02_e1');
      expect(caseOf('ep02_m1').missionById('ep02_m1')!.evidence!.id, 'ep02_e1', reason: 'found before it');
    });

    for (final (size, scale, tag) in sizes) {
      for (final level in Difficulty.values) {
        testWidgets('belfry $tag ${level.label}: both hints open, a wrong bell, then the gear', (t) async {
          final play = MissionPlay();
          final m = await play.openPuzzle(t, size, 'ep02_m2', textScale: scale, level: level);
          final scene = SeasonCatalog.investigation(at('ep02_m2', level))!;
          expect(find.byKey(const ValueKey('investigation-picture')), findsOneWidget);
          await bothHints(t);
          expect(t.takeException(), isNull, reason: 'the page fits with both hints open');
          await capture(t, 'upgrade_ep02_m2_${tag}_${level.name}');
          await play.tapInPicture(t, scene.spots.first.areas.first.center);
          expect(play.ref.read(gameControllerProvider).isCompleted(m.id), isFalse);
          await play.solve(t, m);
          expect(play.ref.read(gameControllerProvider).isCompleted(m.id), isTrue);
          expect(play.ref.read(gameControllerProvider).hintsFor(m.id), 2, reason: 'the hints bought are kept by mission id');
          expect(t.takeException(), isNull);
          await wait(t, const Duration(seconds: 2));
        });
      }
    }

    testWidgets('Gallery 8 at 360x640 x1.3: both hints open (the same search engine)', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(360, 640), 'ep03_m1', textScale: 1.3);
      await bothHints(t);
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 2));
    });

    for (final level in Difficulty.values) {
      testWidgets('Great Clock 390x844 ${level.label}: solved on its hands, the stage turning after', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, const Size(390, 844), 'ep02_m3', level: level);
        final m3 = at('ep02_m3', level);
        play.ref.read(gameControllerProvider.notifier).submitAnswer(m3, m3.answer);
        play.ref.read(routerProvider).go(Routes.finalMission);
        await wait(t, const Duration(milliseconds: 1500));
        final fin = at('ep02_final', level);
        await reveal(t, find.byKey(const ValueKey('clock-dial')));
        expect(findReadable(SeasonCatalog.finalClock(fin)!.lead), findsOneWidget, reason: level.name);
        await play.setClock(t, 9, 17, from: 8 * 60 + 17);
        await play.tapKey(t, 'clock-submit', after: const Duration(milliseconds: 3500));
        expect(play.ref.read(gameControllerProvider).isCompleted(fin.id), isTrue);
        expect(find.text('CASE SOLVED'), findsOneWidget);
        expect(t.takeException(), isNull);
        await wait(t, const Duration(seconds: 2));
      });
    }
  });

  group('Case 03 — the visitors sketched, the footprints followed', () {
    test('the sketches are pencil only: no colour to read instead of the notes', () {
      final m2 = caseOf('ep03_m2').missionById('ep03_m2')!;
      expect(m2.type, MissionType.imageChoice);
      expect(m2.answer, 'b');
      expect(m2.recall!.evidenceId, 'ep03_e1', reason: 'the Red Button, found in Mission 01');
      for (final o in m2.options) {
        final png = img.decodePng(File(o.picture!).readAsBytesSync())!;
        var most = 0;
        for (final p in png) {
          most = math.max(most, [p.r, p.g, p.b].reduce(math.max).toInt() - [p.r, p.g, p.b].reduce(math.min).toInt());
        }
        // Cream paper and graphite only (paper tint ≈ 20): never a red,
        // a blue or a green to see.
        expect(most, lessThan(40), reason: '${o.label}: a colour would tell the answer');
      }
      for (final level in Difficulty.values) {
        final m = at('ep03_m2', level);
        expect(m.letter, allOf(contains('red coat'), contains('blue scarf')), reason: '${level.name}: the colours are in the notes');
      }
    });

    test('the footprints: one stop for each place, the order the base\'s, in every level\'s words', () {
      final m3 = caseOf('ep03_m3').missionById('ep03_m3')!;
      final trail = SeasonCatalog.trail(m3)!;
      expect({for (final s in trail.stops) s.optionId}, {for (final o in m3.options) o.id});
      expect(m3.answer, 'shop,stairs,cafe,door');
      for (final s in trail.stops) {
        expect(s.areas.any((r) => r.contains(s.mark)), isTrue, reason: '${s.optionId}: its number sits on its footprint');
        for (final o in trail.stops.where((o) => o != s)) {
          for (final r in s.areas) {
            expect(o.areas.any((x) => x.overlaps(r)), isFalse, reason: '${s.optionId} and ${o.optionId} apart');
          }
        }
      }
      for (final level in Difficulty.values) {
        final at3 = SeasonCatalog.trail(at('ep03_m3', level))!;
        expect([for (final s in at3.stops) s.optionId], [for (final s in trail.stops) s.optionId]);
        expect(at3.picture, trail.picture);
      }
      // Front to back, or left to right, is not the order walked.
      final byDepth = [...trail.stops]..sort((a, b) => b.mark.dy.compareTo(a.mark.dy));
      final byLeft = [...trail.stops]..sort((a, b) => a.mark.dx.compareTo(b.mark.dx));
      for (final guess in [byDepth, byDepth.reversed, byLeft, byLeft.reversed]) {
        expect([for (final s in guess) s.optionId].join(','), isNot(m3.answer));
      }
    });

    for (final (size, scale, tag) in sizes) {
      for (final level in Difficulty.values) {
        testWidgets('visitors $tag ${level.label}: three sketches on screen, the notebook card, then Miss Rose', (t) async {
          final play = MissionPlay();
          final m = await play.openPuzzle(t, size, 'ep03_m2', textScale: scale, level: level);
          for (final o in m.options) {
            final tile = find.bySemanticsLabel(RegExp('Picture [ABC], ${o.label}'));
            await reveal(t, tile);
            final r = t.getRect(tile);
            expect(r.left, greaterThanOrEqualTo(0), reason: o.label);
            expect(r.right, lessThanOrEqualTo(size.width), reason: o.label);
          }
          expect(find.byType(EvidenceRecallDock), findsOneWidget, reason: 'the Red Button can be brought');
          await capture(t, 'upgrade_ep03_m2_${tag}_${level.name}');
          await play.solve(t, m);
          expect(play.ref.read(gameControllerProvider).isCompleted(m.id), isTrue);
          expect(t.takeException(), isNull);
          await wait(t, const Duration(seconds: 2));
        });

        testWidgets('footprints $tag ${level.label}: a wrong order answered, start again, then the right one', (t) async {
          final play = MissionPlay();
          final m = await play.openPuzzle(t, size, 'ep03_m3', textScale: scale, level: level);
          final lm = at('ep03_m3', level);
          expect(findReadable(SeasonCatalog.trail(lm)!.lead), findsOneWidget);
          final picture = t.getRect(find.byKey(const ValueKey('trail-picture')));
          expect(picture.right, lessThanOrEqualTo(size.width));
          // Driest first: the slip the base answers with its own line.
          for (final id in ['door', 'cafe', 'stairs', 'shop']) {
            await play.tapKey(t, 'trail-$id', after: const Duration(milliseconds: 150));
          }
          await capture(t, 'upgrade_ep03_m3_${tag}_${level.name}');
          await play.tapKey(t, 'trail-check', after: const Duration(milliseconds: 600));
          expect(find.text('Not quite!'), findsOneWidget);
          expect(findReadable(lm.feedback['door,cafe,stairs,shop']!), findsOneWidget, reason: '${level.name}\'s own line');
          await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 400));
          await play.tapKey(t, 'trail-clear');
          expect(play.ref.read(gameControllerProvider).isCompleted(m.id), isFalse);
          await play.solve(t, m);
          expect(play.ref.read(gameControllerProvider).isCompleted(m.id), isTrue);
          expect(t.takeException(), isNull);
          await wait(t, const Duration(seconds: 2));
        });
      }
    }
  });

  group('Case 06 — the witnesses at every level, the notes brought', () {
    test('the Witness Notes are brought where they are read again', () {
      for (final id in ['ep06_m2', 'ep06_m3']) {
        expect(caseOf(id).missionById(id)!.recall!.evidenceId, 'ep06_e1', reason: id);
      }
    });

    for (final level in [Difficulty.junior, Difficulty.master]) {
      testWidgets('market hall 360x640 ${level.label}: the talk in its own words, solved', (t) async {
        final play = MissionPlay();
        final m = await play.openPuzzle(t, const Size(360, 640), 'ep06_m1', level: level);
        final talk = SeasonCatalog.dialogue(at('ep06_m1', level))!;
        await play.solve(t, m);
        expect(play.ref.read(gameControllerProvider).isCompleted(m.id), isTrue);
        expect(talk.statement('juggler.wearing').text, isNot(SeasonCatalog.dialogue(caseOf('ep06_m1').missionById('ep06_m1')!)!.statement('juggler.wearing').text));
        expect(t.takeException(), isNull);
        await wait(t, const Duration(seconds: 2));
      });
    }
  });

  group('Case 07 — the boathouse searched with the place words', () {
    test('the find is the last line of each level\'s note; no line names the place', () {
      for (final level in Difficulty.values) {
        final m = at('ep07_m2', level);
        final scene = SeasonCatalog.investigation(m)!;
        expect(scene.answer, m.answer);
        expect(m.letter.split('\n').last, scene.finds.single.reportLine, reason: level.name);
        for (final line in [scene.task, scene.missLine, ...scene.arrival]) {
          expect(line.toLowerCase(), isNot(contains('behind')), reason: '${level.name}: "$line"');
        }
      }
    });

    for (final (size, scale, tag) in sizes) {
      for (final level in Difficulty.values) {
        testWidgets('boathouse $tag ${level.label}: both hints, the shelf, in front of the can, then behind it', (t) async {
          final play = MissionPlay();
          final m = await play.openPuzzle(t, size, 'ep07_m2', textScale: scale, level: level);
          final scene = SeasonCatalog.investigation(at('ep07_m2', level))!;
          await bothHints(t);
          expect(t.takeException(), isNull, reason: 'the page fits with both hints open');
          await capture(t, 'upgrade_ep07_m2_${tag}_${level.name}');
          for (final spot in [scene.spots[0], scene.spots[2]]) {
            await play.tapInPicture(t, spot.areas.first.center);
            expect(play.ref.read(gameControllerProvider).isCompleted(m.id), isFalse, reason: spot.label);
          }
          await play.solve(t, m);
          expect(play.ref.read(gameControllerProvider).isCompleted(m.id), isTrue);
          expect(t.takeException(), isNull);
          await wait(t, const Duration(seconds: 2));
        });
      }
    }
  });

  group('Case 12 — the four gears checked against three words', () {
    test('each wrong gear misses exactly one of the three words; no name shows', () {
      final m = caseOf('ep12_m1').missionById('ep12_m1')!;
      expect(m.type, MissionType.imageChoice);
      expect(m.hideOptionNames, isTrue);
      expect(m.answer, 'd');
      final real = m.options.firstWhere((o) => o.id == m.answer).label.split(', ');
      for (final o in m.options.where((o) => o.id != m.answer)) {
        final parts = o.label.split(', ');
        expect([for (var i = 0; i < 3; i++) if (parts[i] != real[i]) i], hasLength(1), reason: o.label);
        expect(File(o.picture!).existsSync(), isTrue, reason: o.picture);
      }
      for (final level in Difficulty.values) {
        expect(at('ep12_m1', level).letter, allOf(contains('brass'), contains('eight teeth'), contains('raven stamp')), reason: level.name);
      }
    });

    for (final (size, scale, tag) in sizes) {
      for (final level in Difficulty.values) {
        testWidgets('gears $tag ${level.label}: four unnamed gears on screen, a wrong one, then the real one', (t) async {
          final play = MissionPlay();
          final m = await play.openPuzzle(t, size, 'ep12_m1', textScale: scale, level: level);
          for (final o in m.options) {
            expect(find.text(o.label), findsNothing, reason: 'the gears are unnamed');
          }
          Future<void> pick(String letter) async {
            final tile = find.bySemanticsLabel(RegExp('^Picture $letter: '));
            await reveal(t, tile);
            final r = t.getRect(tile);
            expect(r.left, greaterThanOrEqualTo(0));
            expect(r.right, lessThanOrEqualTo(size.width));
            await t.tap(tile);
            await wait(t, const Duration(milliseconds: 200));
            await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 600));
          }

          await capture(t, 'upgrade_ep12_m1_${tag}_${level.name}');
          await pick('C');
          expect(find.text('Not quite!'), findsOneWidget);
          await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 400));
          await pick('D');
          await wait(t, const Duration(milliseconds: 1200));
          expect(play.ref.read(gameControllerProvider).isCompleted(m.id), isTrue);
          expect(t.takeException(), isNull);
          await wait(t, const Duration(seconds: 2));
        });
      }
    }
  });

  group('saves written before the upgrade', () {
    // A case's save as the app wrote it before 2026-10-30: mission ids,
    // started times, hints bought and wrong answers, nothing of the new
    // pictures (they are presentation only: never saved).
    String oldSave(List<String> done, {Map<String, int> hints = const {}, Map<String, int> wrong = const {}, String? started, bool solved = false}) =>
        jsonEncode({
          'detectiveName': 'MINYOUNG',
          'introSeen': true,
          'completedMissionIds': done,
          'hintsUsed': hints,
          'wrongAnswers': wrong,
          'missionStartedAt': started == null ? const <String, String>{} : {started: DateTime(2026, 10, 1, 10).toIso8601String()},
          'completedAt': solved ? DateTime(2026, 10, 1, 10, 40).toIso8601String() : null,
          'startedAt': DateTime(2026, 10, 1, 10).toIso8601String(),
          'playMillis': 0,
        });

    Future<WidgetRef> openWith(WidgetTester t, String caseId, String save, String route) async {
      t.view.physicalSize = const Size(390, 844) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final e = season.firstWhere((x) => x.id == caseId);
      late WidgetRef ref;
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: {
          ...prefsAt(season, e.missions.first.id),
          AppConstants.progressKeyFor(caseId): save,
        }),
        child: Consumer(builder: (context, r, _) {
          ref = r;
          return const WorldMysteryApp();
        }),
      ));
      await wait(t, const Duration(milliseconds: 300));
      ref.read(routerProvider).go(route);
      await wait(t, const Duration(milliseconds: 1500));
      return ref;
    }

    testWidgets('mid Case 02: the belfry opens as a search, the tip and the wrong answer kept', (t) async {
      final ref = await openWith(t, 'ep02', oldSave(['ep02_m1'], hints: {'ep02_m2': 1}, wrong: {'ep02_m2': 1}, started: 'ep02_m2'), Routes.mission('ep02_m2'));
      expect(find.byKey(const ValueKey('investigation-picture')), findsOneWidget, reason: 'back on its puzzle, now the search');
      expect(find.text('DETECTIVE HINT 1'), findsOneWidget, reason: 'the tip bought before');
      final progress = ref.read(gameControllerProvider);
      expect(progress.hintsFor('ep02_m2'), 1);
      expect(progress.wrongAnswers['ep02_m2'], 1);
      expect(progress.isCompleted('ep02_m1'), isTrue);
      await wait(t, const Duration(seconds: 2));
    });

    testWidgets("Case 02's final started before: the Great Clock, both tips kept", (t) async {
      final ref = await openWith(t, 'ep02', oldSave(['ep02_m1', 'ep02_m2', 'ep02_m3'], hints: {'ep02_final': 2}, started: 'ep02_final'), Routes.finalMission);
      expect(find.byKey(const ValueKey('clock-dial')), findsOneWidget);
      expect(ref.read(gameControllerProvider).hintsFor('ep02_final'), 2);
      final fin = caseOf('ep02_final').finalMission;
      expect(ref.read(gameControllerProvider.notifier).submitAnswer(fin, '917').result, SubmitResult.correct, reason: 'the lock answers as it did');
      await wait(t, const Duration(seconds: 4));
    });

    testWidgets('Case 03 solved before: its missions stay solved, nothing to play again', (t) async {
      final e = season.firstWhere((x) => x.id == 'ep03');
      final ref = await openWith(t, 'ep03', oldSave([for (final m in e.allMissions) m.id], solved: true), Routes.mission('ep03_m3'));
      expect(ref.read(gameControllerProvider).isCaseSolved, isTrue);
      expect(find.byKey(const ValueKey('trail-picture')), findsNothing, reason: 'a solved mission shows its solve, not its puzzle');
      expect(find.byKey(const ValueKey('solved')), findsOneWidget);
      await wait(t, const Duration(seconds: 2));
    });
  });

  group('Case 04 — the platforms read, then chosen', () {
    test("each platform's note is the porter's line, word for word, at every level", () {
      for (final level in Difficulty.values) {
        final m = at('ep04_m2', level);
        final scene = SeasonCatalog.deduction(m)!;
        expect([for (final c in scene.clues) c.line], m.letter.split('\n').take(4).toList(), reason: level.name);
        expect({for (final p in scene.places) p.optionId}, {for (final o in m.options) o.id});
        expect(scene.chooseTask, contains('RED · SMALL · CLOCK'), reason: "${level.name}: the card's words");
      }
      // Case 12 reads it again.
      expect(caseOf('ep12_m2').missionById('ep12_m2')!.hints.join(' '), contains('small red clock'));
    });

    for (final (size, scale, tag) in sizes) {
      for (final level in Difficulty.values) {
        testWidgets('platforms $tag ${level.label}: every note, the red door tried, then Platform 4', (t) async {
          final play = MissionPlay();
          final m = await play.openPuzzle(t, size, 'ep04_m2', textScale: scale, level: level);
          final scene = SeasonCatalog.deduction(at('ep04_m2', level))!;
          await play.noteClues(t, scene);
          expect(t.takeException(), isNull);
          await capture(t, 'upgrade_ep04_m2_${tag}_${level.name}');
          await play.chooseAndSearch(t, scene, 'c');
          await wait(t, const Duration(milliseconds: 600));
          expect(find.text('Not quite!'), findsOneWidget);
          expect(findReadable(at('ep04_m2', level).options.firstWhere((o) => o.id == 'c').feedback!), findsOneWidget);
          await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 400));
          await play.chooseAndSearch(t, scene, m.answer);
          await wait(t, const Duration(milliseconds: 1200));
          expect(play.ref.read(gameControllerProvider).isCompleted(m.id), isTrue);
          expect(t.takeException(), isNull);
          await wait(t, const Duration(seconds: 2));
        });
      }
    }
  });
}
