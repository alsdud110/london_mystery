import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/landmark_art.dart';
import 'package:london_mystery/widgets/place_art.dart';

import 'full_playthrough_test.dart' show reveal, wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// Case 02's reasoning chain: the stopped time (Mission 01) is the source
/// clue; the detective reads Gallery 8 · Picture 17 out of it (Mission 03),
/// then works out the final time, 8:17 + one hour = 9:17. No screen before
/// the final lock shows 9:17; the clock's hour hand then turns 8 → 9.
void main() {
  final season = MockEpisodeRepository.bundled();
  Episode byId(String id) => season.firstWhere((e) => e.id == id);
  final ep02 = byId('ep02');
  final m1 = ep02.missionById('ep02_m1')!;
  final m2 = ep02.missionById('ep02_m2')!;
  final m3 = ep02.missionById('ep02_m3')!;
  final fin = ep02.finalMission;

  /// Every line a player can read in [m] (its puzzle, tips, and what it saves).
  List<String> textOf(Mission m) => [
        m.title,
        m.location,
        ...m.story,
        m.letterIntro,
        m.letter,
        m.question,
        ?m.prompt,
        for (final o in m.options) o.label,
        ...m.hints,
        if (m.clue case final c?) ...[c.title, c.value, c.note],
        if (m.evidence case final e?) ...[e.name, e.description, ?e.inscription],
        m.successMessage,
        ...m.transition,
      ];

  /// 9:17 written as a time in any form a child would read as the answer.
  final finalTime = RegExp(r'9\s*[:.·]\s*17|\b917\b|nine\s+seventeen', caseSensitive: false);

  group('data', () {
    test('Mission 01 still finds the stopped time, 8:17, and keeps it in the notebook', () {
      expect(m1.type, MissionType.numberCode);
      expect(m1.answer, '817');
      expect(m1.clue!.value, '8:17');
      expect(m1.evidence!.name, 'Broken Clock Note');
      expect(m1.evidence!.inscription, 'STOPPED AT 8:17');
    });

    test('Mission 02 stays the gear and the raven stamp (evidence, no number)', () {
      expect(m2.answer, 'c');
      expect(m2.answerLabel, 'Under the smallest bell');
      expect(m2.evidence!.name, 'Small Brass Gear');
      expect(m2.evidence!.inscription, contains('raven'));
      expect(m2.clue!.symbol, 'raven');
    });

    test('Mission 03 is the deduction: the stopped time read as Gallery 8 · Picture 17', () {
      expect(m3.type, MissionType.multipleChoice);
      // The right card is Mission 01's hour and minutes, in that order.
      final hour = m1.answer.substring(0, 1), minutes = m1.answer.substring(1);
      expect(m3.answerLabel, 'Gallery $hour · Picture $minutes');
      // The plan hides both numbers in the stopped clock and says how to read it.
      expect(m3.letter, contains('stopped clock'));
      expect(m3.letter, contains('The hour is the gallery'));
      expect(m3.letter, contains('The minutes are the picture'));
      for (final n in ['Gallery 8', 'Picture 17']) {
        expect(m3.letter, isNot(contains(n)), reason: 'the plan must not give the deduction away');
        expect(m3.story.join(' '), isNot(contains(n)));
      }
      // Each wrong card is one slip: the hour read as 9, hour and minutes
      // swapped, Mrs Bell's "three" and "two marks" taken as the numbers.
      expect(
        {for (final o in m3.options) if (o.id != m3.answer) o.label},
        {'Gallery 9 · Picture 17', 'Gallery 17 · Picture 8', 'Gallery 3 · Picture 2'},
      );
      // What it saves is the deduction.
      expect(m3.clue!.title, 'Gallery 8 · Picture 17');
      expect(m3.evidence!.inscription, contains('GALLERY 8 · PICTURE 17'));
      // The scene reacts; it no longer works the message out for the player.
      expect(m3.transition, isNot(contains('Gallery 8. Picture 17.')));
      expect(m3.transition.join(' '), isNot(contains('8... 17')));
      expect(m3.transition.first, 'The time was a message.');
    });

    test("no screen before the final lock shows the final's time (9:17)", () {
      for (final line in [...ep02.synopsis, ...ep02.intro, ...ep02.objectives]) {
        expect(finalTime.hasMatch(line), isFalse, reason: line);
      }
      for (final m in ep02.missions) {
        for (final line in textOf(m)) {
          expect(finalTime.hasMatch(line), isFalse, reason: '${m.id}: "$line"');
        }
      }
      // The final itself: the page and both tips, up to the lock.
      for (final line in [...fin.story, fin.letterIntro, fin.letter, fin.question, ...fin.hints]) {
        expect(finalTime.hasMatch(line), isFalse, reason: 'final: "$line"');
      }
    });

    test('the final asks for the stopped time plus one hour: 917, on three dials', () {
      expect(fin.type, MissionType.finalCode);
      expect(fin.codeLength, 3);
      expect(fin.answer, '917');
      expect(m3.letter, contains('One hour after the clock stops'), reason: 'the rule comes from the plan');
      expect(fin.letter, contains('notebook'), reason: 'the final points to the notebook');
      expect(fin.hints, hasLength(lessThanOrEqualTo(AppConstants.maxHints)));
      expect(fin.hints.first, isNot(contains('8:17')), reason: 'tip 1 gives a direction only');
    });

    test('the clock turns from the stopped time to the solved time: 8:17 → 9:17', () {
      final hands = ArtAssets.clockHands[Artwork.clockFace]!;
      expect((hands.before.hour, hands.before.minute), (8, 17));
      expect((hands.after.hour, hands.after.minute), (9, 17));
      // The same numbers as the puzzles: Mission 01's answer, then the final's.
      expect('${hands.before.hour}${hands.before.minute}', m1.answer);
      expect('${hands.after.hour}${hands.after.minute}', fin.answer);
      expect(hands.after.hour, hands.before.hour + 1, reason: 'one hour after');
      expect(hands.after.minute, hands.before.minute, reason: 'the minutes stay');
      expect(PlaceArt.sceneOf(m3), Artwork.clockFace, reason: 'Mission 03 shows the stopped clock');
      expect(PlaceArt.sceneOf(fin), Artwork.clockFace);
    });

    test('the season still follows on: Case 03, Case 06, Case 12', () {
      final ep03 = byId('ep03');
      expect(ep03.intro.join(' '), allOf(contains('9:18'), contains('Gallery 8'), contains('one minute too late')));
      expect(ep03.missionById('ep03_m1')!.location, 'GALLERY 8');
      expect(byId('ep06').missionById('ep06_m3')!.transition.join(' '), contains('17, like 8:17'));
      final realGear = byId('ep12').missionById('ep12_m1')!;
      expect(realGear.letter, allOf(contains('raven stamp'), contains('Case 02')));
      // Case 02's post-case still confirms the message and the raven.
      expect(fin.transition, containsAll(['It was a message.', 'The same raven was stamped on the gear.']));
    });
  });

  group('screens', () {
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

    String progress(List<String> done, {String? opened}) => jsonEncode(GameProgress(
          detectiveName: 'MINYOUNG',
          introSeen: true,
          completedMissionIds: done,
          missionStartedAt: opened == null ? const {} : {opened: DateTime(2026, 10, 6, 10)},
          startedAt: DateTime(2026, 10, 6, 10),
          playMillis: 0,
        ).toJson());

    Future<GoRouterLike> start(WidgetTester t, Size size, List<String> done, {String? opened}) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: {
          AppConstants.progressStorageKey: progress([for (final m in episode01.allMissions) m.id]),
          AppConstants.progressKeyFor('ep02'): progress(done, opened: opened),
          AppConstants.seasonStorageKey:
              jsonEncode(const SeasonProgress(activeEpisodeId: 'ep02', solvedEpisodeIds: ['ep01']).toJson()),
        }),
        child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
      ));
      await wait(t, const Duration(milliseconds: 300));
      final router = ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first).read(routerProvider);
      return router.go;
    }

    Future<void> settlePictures(WidgetTester t) async {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await t.pump();
    }

    LandmarkArt clock(WidgetTester t) =>
        t.widgetList<LandmarkArt>(find.byType(LandmarkArt)).firstWhere((a) => a.artwork == Artwork.clockFace);

    for (final size in const [Size(360, 640), Size(390, 844)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('Mission 03 $tag: the stopped clock, the plan, the notebook, four cards that fit', (t) async {
        final go = await start(t, size, ['ep02_m1', 'ep02_m2']);
        go(Routes.mission(m3.id));
        await wait(t, const Duration(milliseconds: 2400));

        // The place: the clock still stopped at 8:17 (the time can be read again here).
        expect(t.takeException(), isNull);
        expect(clock(t).solved, 0);
        await settlePictures(t);
        await capture(t, 'case02_m3_place_$tag');

        // The plan, then the puzzle.
        await reveal(t, find.text('INVESTIGATE'));
        await t.tap(find.text('INVESTIGATE'));
        await wait(t, const Duration(milliseconds: 700));
        await t.tap(find.text('TAP TO OPEN'));
        await wait(t, const Duration(milliseconds: 1800));
        expect(finalTime.hasMatch(find.byType(Text).evaluate().map((e) => (e.widget as Text).data ?? '').join(' ')), isFalse);
        await capture(t, 'case02_m3_letter_$tag');
        await reveal(t, find.text('SOLVE THE PUZZLE'));
        await t.tap(find.text('SOLVE THE PUZZLE'));
        await wait(t, const Duration(milliseconds: 900));
        expect(find.text(m3.question), findsOneWidget);
        await capture(t, 'case02_m3_puzzle_$tag');

        // Every card shows whole, on one line, inside the screen.
        for (final o in m3.options) {
          final label = find.text(o.label);
          await reveal(t, label);
          final box = t.getRect(label);
          expect(box.left, greaterThanOrEqualTo(0), reason: o.label);
          expect(box.right, lessThanOrEqualTo(size.width), reason: o.label);
          expect(box.height, lessThan(40), reason: '${o.label}: one line, not cut or wrapped');
        }
        await reveal(t, find.text('CHECK ANSWER'));
        await capture(t, 'case02_m3_cards_$tag');
        expect(t.takeException(), isNull);

        // Forgot the time? The notebook has it, first.
        await t.tap(find.byTooltip('Detective notebook'));
        await wait(t, const Duration(milliseconds: 900));
        expect(find.text('8:17'), findsOneWidget);
        expect(find.text('"8:17"'), findsOneWidget, reason: 'CLUE #01, the stopped time');
        await capture(t, 'case02_m3_notebook_$tag');
        await t.tap(find.byTooltip('Close'));
        await wait(t, const Duration(milliseconds: 900));
        expect(find.text(m3.question), findsOneWidget, reason: 'back on the puzzle');
        await wait(t, const Duration(seconds: 2));
      });

      testWidgets('final $tag: the clock at 8:17, three dials, the notebook, no 9:17 written', (t) async {
        final go = await start(t, size, [for (final m in ep02.missions) m.id]);
        go(Routes.finalMission);
        await wait(t, const Duration(milliseconds: 1200));
        expect(t.takeException(), isNull);
        expect(clock(t).solved, 0, reason: 'stopped at 8:17 until the detective sets it');
        expect(find.textContaining('9:17'), findsNothing);
        await settlePictures(t);
        await capture(t, 'case02_final_page_$tag');

        for (var i = 1; i <= 3; i++) {
          expect(find.byTooltip('Lock $i up'), findsOneWidget);
        }
        expect(find.byTooltip('Lock 4 up'), findsNothing);
        final notebook = find.text('OPEN MY NOTEBOOK');
        await reveal(t, notebook);
        await wait(t, const Duration(milliseconds: 300));
        final button = t.getRect(notebook);
        expect(button.bottom, lessThanOrEqualTo(size.height), reason: 'the notebook button is on screen');
        await capture(t, 'case02_final_dials_$tag');

        // The notebook: the stopped time and the Time Card (the plan's rule).
        await t.tap(notebook);
        await wait(t, const Duration(milliseconds: 900));
        expect(find.text('Time Card'), findsOneWidget);
        // The sheet scrolls by itself (over the page): down to CLUE #01.
        await t.scrollUntilVisible(find.text('8:17'), 200, scrollable: find.byType(Scrollable).last);
        await wait(t, const Duration(milliseconds: 300));
        expect(find.text('8:17'), findsOneWidget);
        expect(find.textContaining('9:17'), findsNothing);
        await capture(t, 'case02_final_notebook_$tag');
        expect(t.takeException(), isNull);
        await wait(t, const Duration(seconds: 2));
      });
    }
  });
}

/// The router's `go`, kept as a plain function for the tests above.
typedef GoRouterLike = void Function(String location);
