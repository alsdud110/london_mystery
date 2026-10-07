import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/mock/season1/season1_discoveries.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/widgets/evidence_card.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'mission_play.dart';
import 'title_screen_test.dart' show capture;

/// Post-discovery small pass: the joined map's card no longer names the
/// final's spot (Case 07); the scene after a puzzle does not read the
/// discovery again (Cases 07, 10); and evidence handed over in a scene
/// (Case 06's theatre ticket, Case 10's letter) is laid down there as a card.
/// The answers save everything, as before.
void main() {
  final season = MockEpisodeRepository.bundled();
  Episode byId(String id) => season.firstWhere((e) => e.id == id);

  group('content', () {
    final c07 = byId('ep07'), c10 = byId('ep10'), c06 = byId('ep06');
    final m07 = c07.missionById('ep07_m3')!, m102 = c10.missionById('ep10_m2')!, m103 = c10.missionById('ep10_m3')!;
    final m063 = c06.missionById('ep06_m3')!;

    test('1–2. Case 07 M3: no card, and no "old gate" in its discovery', () {
      final d = discoveryOf(m07);
      expect(d.title, 'THE JOINED MAP');
      expect(d.showEvidence, isFalse);
      expect(d.detail, contains('north'));
      expect([d.title, d.detail, ?d.note].join(' ').toLowerCase(), isNot(contains('gate')));
    });

    test('3. the Joined Map itself still names the spot (the notebook keeps it)', () {
      expect(m07.evidence!.name, 'Joined Map');
      expect(m07.evidence!.inscription, 'An arrow goes north, to the old gate of the park.');
    });

    test('5. its scene goes on from the discovery, and never names the spot', () {
      final scene = m07.transition.join(' ');
      expect(scene, isNot(contains(discoveryOf(m07).detail)));
      expect(scene.toLowerCase(), isNot(contains('to the top of the park')), reason: 'the discovery said it');
      expect(scene.toLowerCase(), isNot(contains('gate')));
      expect(m07.transition, contains('"The last piece waits where my arrow points."'));
    });

    test('6. the Case 07 final is unchanged: Grey turns left; the map gives the end', () {
      final fin = c07.finalMission;
      expect(fin.answerLabel, 'At the old gate');
      expect(fin.letter, allOf(contains('turn left'), contains('joined map')));
      expect(fin.letter.toLowerCase(), isNot(contains('gate')));
    });

    test('7. Case 10 M2: the scene does not read the four words again', () {
      for (final w in ['north', 'tower', 'bridge', 'three']) {
        expect(RegExp('\\b$w\\b', caseSensitive: false).hasMatch(m102.transition.join(' ')), isFalse, reason: w);
      }
      expect(m102.transition, contains('The words must point to a place.'));
    });

    test('8. Case 10 M3 is still Tower Bridge', () {
      expect(m103.answerLabel, 'Tower Bridge');
    });

    test('9–10, 13–14. the evidence the scenes hand over, as it was', () {
      expect(season1StoryEvidence, {'ep06_m3', 'ep10_m3'});
      expect(storyEvidenceOf(m103)!.name, "Ravenmaster's Letter");
      expect(storyEvidenceOf(m103)!.description, 'Given to you at the north tower.');
      expect(storyEvidenceOf(m103)!.inscription, '"The Clockmaker watches me. So Poppy speaks for me."');
      expect(storyEvidenceOf(m063)!.name, 'Theatre Ticket');
      expect(storyEvidenceOf(m063)!.inscription, 'ROW R · SEAT 17');
      expect(m063.transition.first, contains('gives you a theatre ticket'));
      // Neither is laid out by the Discovery Moment too.
      expect(discoveryOf(m103).showEvidence, isFalse);
      expect(discoveryOf(m063).showEvidence, isFalse);
    });

    test('16. Case 06: the final and the ticket line are unchanged', () {
      expect(c06.finalMission.answerLabel, 'Inspector Grey');
      expect(m063.transition, contains('Row R, seat 17. R for Raven. 17, like 8:17.'));
    });

    test('17–19. no other mission hands over evidence in its scene; 38 discoveries; no final', () {
      for (final e in season) {
        expect(storyEvidenceOf(e.finalMission), isNull);
        for (final m in e.missions) {
          if (!season1StoryEvidence.contains(m.id)) expect(storyEvidenceOf(m), isNull, reason: m.id);
          expect(season1Discoveries, contains(m.id));
        }
      }
      expect(season1Discoveries, hasLength(38));
    });
  });

  setUpAll(() async {
    for (final (family, files) in [
      ('Sentient', ['Sentient-Variable.ttf']),
      ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
      ('LibreBaskerville', ['LibreBaskerville.ttf', 'LibreBaskerville-Italic.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await loader.load();
    }
  });

  group('play', () {
    final play = MissionPlay();

    /// Solve [id] → its Discovery Moment → CONTINUE → its scene, read to the end.
    Future<Mission> toScene(WidgetTester t, Size size, String id, {double textScale = 1, String? shot}) async {
      final m = await play.openPuzzle(t, size, id, textScale: textScale);
      await play.solve(t, m);
      await wait(t, const Duration(milliseconds: 2600));
      if (shot != null) await capture(t, '${shot}_discovery');
      await tapText(t, 'CONTINUE', after: const Duration(milliseconds: 900));
      expect(play.path(), Routes.story(id));
      await t.tapAt(Offset(size.width / 2, size.height / 2)); // the whole scene at once
      await wait(t, const Duration(milliseconds: 1200));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500))); // decode the pictures
      await t.pump();
      expect(t.takeException(), isNull);
      return m;
    }

    for (final size in const [Size(360, 640), Size(390, 844)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('Case 07 $tag: M3 → discovery (north only) → scene → final by Grey + the map', (t) async {
        final m = await play.openPuzzle(t, size, 'ep07_m3');
        await play.solve(t, m);
        await wait(t, const Duration(milliseconds: 2600));
        expect(find.text('THE JOINED MAP'), findsOneWidget);
        expect(find.textContaining('top of the park'), findsOneWidget);
        expect(find.descendant(of: find.byKey(const ValueKey('discovery-moment')), matching: find.byType(EvidenceChip)),
            findsNothing, reason: 'no card');
        expect(find.textContaining('old gate'), findsNothing);
        await capture(t, 'pass_ep07_m3_discovery_$tag');
        await tapText(t, 'CONTINUE', after: const Duration(milliseconds: 900));
        await t.tapAt(Offset(size.width / 2, size.height / 2));
        await wait(t, const Duration(milliseconds: 1200));
        expect(find.text(m.transition.first), findsOneWidget);
        expect(find.textContaining('old gate'), findsNothing);
        await capture(t, 'pass_ep07_m3_scene_$tag');
        await tapText(t, 'TO THE MAP', after: const Duration(milliseconds: 1400));

        // The final: its maps are lettered, not named; nothing on its page names the spot.
        play.ref.read(routerProvider).go(Routes.finalMission);
        await wait(t, const Duration(milliseconds: 1500));
        await capture(t, 'pass_ep07_final_$tag');
        expect(find.textContaining('old gate'), findsNothing);
        expect(find.textContaining('gate'), findsNothing);
        // 4. The notebook still has the whole map.
        await tapText(t, 'OPEN MY NOTEBOOK', after: const Duration(milliseconds: 900));
        final tile = find.text('Joined Map');
        await t.scrollUntilVisible(tile, 200,
            scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.physics is! NeverScrollableScrollPhysics).last);
        await t.tap(tile);
        await wait(t, const Duration(milliseconds: 700));
        expect(find.text('An arrow goes north, to the old gate of the park.'), findsOneWidget);
        await tapText(t, 'CLOSE', after: const Duration(milliseconds: 600));
        await t.binding.handlePopRoute(); // the notebook sheet
        await wait(t, const Duration(milliseconds: 700));
        // Grey turns left after the bridge; the arrow ends north: the old gate.
        final fin = play.caseOf('ep07_m1').finalMission;
        expect(fin.options[1].label, 'At the old gate');
        final gate = find.bySemanticsLabel('Picture B');
        await reveal(t, gate);
        await t.tap(gate);
        await wait(t, const Duration(milliseconds: 300));
        await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 2600));
        expect(play.ref.read(gameControllerProvider).isCaseSolved, isTrue);
        await wait(t, const Duration(seconds: 3));
      });

      testWidgets('Case 10 M2 $tag: the scene reacts, it does not read the words again', (t) async {
        final m = await toScene(t, size, 'ep10_m2');
        expect(find.text('You read the four papers once more, slowly.'), findsOneWidget);
        expect(find.textContaining('North...'), findsNothing);
        expect(find.byType(EvidenceChip), findsNothing, reason: 'no card: nothing is handed over');
        expect(m.transition, isNot(contains('North... tower... bridge... three...')));
        await capture(t, 'pass_ep10_m2_scene_$tag');
        await wait(t, const Duration(seconds: 3));
      });

      for (final (id, name, writing, description) in const [
        ('ep10_m3', "Ravenmaster's Letter", '"The Clockmaker watches me. So Poppy speaks for me."', 'Given to you at the north tower.'),
        ('ep06_m3', 'Theatre Ticket', 'ROW R · SEAT 17', 'Dropped by the woman in the red hat.'),
      ]) {
        for (final scale in const [1.0, 1.3]) {
          testWidgets('$id $tag text ${scale}x: the scene hands over $name as a card', (t) async {
            final shot = 'pass_${id}_${tag}_text${(scale * 100).round()}';
            await toScene(t, size, id, textScale: scale, shot: scale == 1 ? shot : null);
            // 12. Saved with the answer, as before (not by the scene).
            final state = play.ref.read(gameControllerProvider);
            expect(state.isCompleted(id), isTrue);
            expect(state.collectedEvidence(play.caseOf(id)).map((e) => e.name), contains(name));
            // 9 / 13. Laid down once, after the lines, whole on screen.
            final card = find.byType(EvidenceChip);
            expect(card, findsOneWidget);
            expect(find.text(name), findsOneWidget);
            expect(find.text(writing), findsOneWidget);
            await wait(t, const Duration(milliseconds: 800)); // still one after more frames
            expect(card, findsOneWidget);
            final r = t.getRect(card);
            expect(r.top, greaterThanOrEqualTo(0));
            expect(r.bottom, lessThanOrEqualTo(size.height), reason: 'the card is scrolled into view');
            final cta = find.text('TO THE MAP');
            expect(t.getRect(cta).bottom, lessThanOrEqualTo(size.height), reason: 'the way on stays reachable');
            expect(t.getRect(cta).top, greaterThanOrEqualTo(r.bottom - 1), reason: 'card and button do not overlap');
            await capture(t, shot);
            // 11 / 15. Tap: it opens large, as in the notebook.
            await t.tap(find.text(name));
            await wait(t, const Duration(milliseconds: 700));
            expect(find.text(description), findsOneWidget);
            expect(find.text(name), findsNWidgets(2), reason: 'the zoom over the scene');
            await capture(t, '${shot}_zoom');
            await tapText(t, 'CLOSE', after: const Duration(milliseconds: 600));
            expect(find.text(description), findsNothing);
            await tapText(t, 'TO THE MAP', after: const Duration(milliseconds: 1400));
            expect(play.path(), Routes.map);
            await wait(t, const Duration(seconds: 3));
          });
        }
      }
    }

    testWidgets('17. a scene that hands over nothing is as before (Case 06 M2: the card came in Mission 01)', (t) async {
      await toScene(t, const Size(390, 844), 'ep06_m2');
      expect(find.byType(EvidenceChip), findsNothing);
      expect(find.text('NEW PLACE UNLOCKED'), findsOneWidget);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('20. XP and the saved answer are untouched (Case 10 M3)', (t) async {
      final m = await play.openPuzzle(t, const Size(390, 844), 'ep10_m3');
      await play.solve(t, m);
      await wait(t, const Duration(milliseconds: 2600));
      final state = play.ref.read(gameControllerProvider);
      expect(find.text('+${XpBreakdown.of(m, state).total} XP'), findsOneWidget);
      expect(state.isCompleted('ep10_m3'), isTrue, reason: 'saved before the moment');
      await tapText(t, 'CONTINUE', after: const Duration(milliseconds: 900));
      await wait(t, const Duration(seconds: 3));
    });

    // 25. Closed and opened again: the evidence is kept, scene or no scene.
    for (final (id, name, moment) in const [
      ('ep06_m3', 'Theatre Ticket', 'during the Discovery Moment'),
      ('ep10_m3', "Ravenmaster's Letter", 'in the middle of the scene'),
    ]) {
      testWidgets('re-entry: $id closed $moment → $name is still in the notebook', (t) async {
        final m = await play.openPuzzle(t, const Size(390, 844), id);
        await play.solve(t, m);
        await wait(t, const Duration(milliseconds: 1200));
        if (moment != 'during the Discovery Moment') {
          await wait(t, const Duration(milliseconds: 1400));
          await tapText(t, 'CONTINUE', after: const Duration(milliseconds: 300));
        }
        await play.restart(t);
        final state = play.ref.read(gameControllerProvider);
        expect(state.isCompleted(id), isTrue);
        expect(state.collectedEvidence(play.caseOf(id)).map((e) => e.name), contains(name));
        expect(play.ref.read(sharedPreferencesProvider).getKeys(), isNotEmpty);
        await wait(t, const Duration(seconds: 3));
      });
    }
  });
}
