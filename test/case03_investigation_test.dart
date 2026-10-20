import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/mock/season1/season1_discoveries.dart';
import 'package:london_mystery/data/mock/season1/season1_investigations.dart';
import 'package:london_mystery/data/mock/season1/season1_learning.dart';
import 'package:london_mystery/data/models/discovery.dart';
import 'package:london_mystery/data/models/investigation.dart';
import 'package:london_mystery/data/models/learning.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/widgets/art_assets.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart' show findReadable, findReadableContaining, tipSheetButton;
import 'mission_play.dart';
import 'title_screen_test.dart' show capture;

/// Wave 1 / 1.1 — Case 03 M1 (Gallery 8) is played as a search: the guard's report
/// says where each thing is; the detective finds the red button under the
/// bench, the blue cloth on the frame and the wet footprint next to the
/// door. The last find answers the mission's puzzle (`c`), so its Clue,
/// Evidence, XP, coins and save are the ones it always gave.
void main() {
  final season = MockEpisodeRepository.bundled();
  final c03 = season.firstWhere((e) => e.id == 'ep03');
  final c08 = season.firstWhere((e) => e.id == 'ep08');
  final m1 = c03.missionById('ep03_m1')!;
  final scene = investigationOf(m1)!;
  InvestigationFind thing(String id) => scene.finds.firstWhere((f) => f.id == id);

  group('the search data', () {
    test('only Case 03 M1 is searched; the search ends with its own answer', () {
      expect(season1Investigations.keys, ['ep03_m1']);
      expect(scene.answer, m1.answer);
      expect(m1.answer, 'c');
      expect(m1.answerLabel, 'The wet footprint', reason: 'the thing next to the door, as the puzzle asked');
    });

    test('three things, each where a line of the report says, word for word', () {
      expect(scene.finds.map((f) => f.id), ['button', 'cloth', 'footprint']);
      for (final f in scene.finds) {
        expect(m1.letter, contains(f.reportLine), reason: f.id);
      }
      expect(thing('button').reportLine, contains('under the bench'));
      expect(thing('cloth').reportLine, contains('on the frame'));
      expect(thing('footprint').reportLine, contains('next to the door'));
    });

    test('every area is inside the picture; a thing never shares a spot with a place or another thing', () {
      final all = [for (final f in scene.finds) ...f.areas, for (final s in scene.spots) ...s.areas];
      for (final r in all) {
        expect(r.left >= 0 && r.top >= 0 && r.right <= 1 && r.bottom <= 1, isTrue, reason: '$r');
        expect(r.width > 0 && r.height > 0, isTrue, reason: '$r');
      }
      for (final f in scene.finds) {
        for (final a in f.areas) {
          for (final s in scene.spots) {
            for (final b in s.areas) {
              expect(a.intersect(b).isEmpty || a.intersect(b).width <= 0 || a.intersect(b).height <= 0, isTrue,
                  reason: '${f.id} overlaps ${s.label}');
            }
          }
          for (final g in scene.finds.where((g) => g != f)) {
            for (final b in g.areas) {
              final i = a.intersect(b);
              expect(i.width <= 0 || i.height <= 0, isTrue, reason: '${f.id} overlaps ${g.id}');
            }
          }
          // Each thing is laid inside the area that finds it.
        }
        expect(f.areas.any((r) => r.inflate(0.06).contains(f.at)), isTrue, reason: '${f.id} is laid where it is found');
      }
    });

    test('the place words decide: on the bench and the door itself are not where the things are', () {
      final under = thing('button').areas.first;
      expect(scene.hit(under.center), thing('button'));
      final seat = scene.spots.firstWhere((s) => s.label == 'On the bench');
      expect(scene.hit(seat.areas.first.center), seat);
      expect(seat.line, contains('UNDER'));
      final door = scene.spots.firstWhere((s) => s.label == 'The door');
      expect(scene.hit(door.areas.first.center), door);
      expect(door.line, contains('NEXT TO'));
      expect(scene.hit(thing('footprint').areas.first.center), thing('footprint'));
      expect(scene.hit(thing('cloth').areas.first.center), thing('cloth'));
      // Nothing at all: the empty floor in the middle of the room.
      expect(scene.hit(const Offset(0.62, 0.86)), isNull);
    });

    test('a tap just outside a small place still counts for it; inside always wins', () {
      final under = thing('button').areas.first;
      final below = Offset(under.center.dx, under.bottom + 0.01);
      expect(scene.hit(below), isNull);
      expect(scene.hit(below, slack: const Size(0.03, 0.03)), thing('button'));
      expect(scene.hit(Offset(under.center.dx, under.bottom + 0.1), slack: const Size(0.03, 0.03)), isNull);
    });

    test('its pictures: Gallery 8 as the theft left it, and the three things on transparency', () {
      expect(ArtAssets.scenes[scene.artwork], 'assets/art/scenes/british_museum/british_museum_gallery_8.png');
      expect(ArtAssets.sceneAspect(scene.artwork), 1536 / 1024);
      for (final f in scene.finds) {
        expect(File(f.picture).existsSync(), isTrue, reason: f.picture);
      }
      expect(File('assets/art/scenes/british_museum/british_museum_gallery_8.png').existsSync(), isTrue);
    });
  });

  group('what the search keeps of the case', () {
    test('the mission, its Clue and its Evidence are as they were', () {
      expect(m1.id, 'ep03_m1');
      expect(m1.location, 'GALLERY 8');
      expect(m1.clue!.id, 'ep03_c1');
      expect(m1.clue!.title, 'Wet Footprint');
      expect(m1.clue!.value, 'Door');
      final button = m1.evidence!;
      expect(button.id, 'ep03_e1');
      expect(button.name, 'Red Button');
      expect(button.description, 'From a coat. It was under the bench.');
      expect(button.inscription, 'A shiny red coat button.');
      expect(m1.options.map((o) => o.id), ['a', 'b', 'c', 'd']);
    });

    test('Case 08 still proves her lie with that same Red Button', () {
      final f8 = c08.finalMission;
      expect(f8.answer, 'c');
      expect(f8.options.firstWhere((o) => o.id == 'c').label, m1.evidence!.name);
      expect(c03.missionById('ep03_m2')!.hints.first, contains('button'));
    });

    test('the Discovery: the button was found by the detective, so it is laid on screen', () {
      final d = discoveryOf(m1);
      expect(d.type, DiscoveryType.evidenceFound);
      expect(d.timing, DiscoveryTiming.fromPuzzle);
      expect(d.showEvidence, isTrue);
      expect(d.title, 'A RED BUTTON');
      expect(d.detail, contains('door'));
    });

    test('the learning design: the place words are acted on', () {
      final l = learningOf(m1)!;
      expect(l.dependency, LanguageDependency.essential);
      expect(l.level, LearningLevel.application);
      expect(l.isHonest, isTrue);
      for (final e in l.expressions) {
        expect(m1.letter, contains(e));
      }
    });

    test('its tips read the place words and never name the answer', () {
      expect(m1.hints, hasLength(2), reason: 'two tips: the cloud catalog and coins count them');
      expect(m1.hints.last, allOf(contains('Under the bench'), contains('On the frame'), contains('Next to the door')));
      for (final h in m1.hints) {
        expect(h.toLowerCase(), isNot(contains('wet footprint')));
      }
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

  Finder line(String text) => findReadableContaining(text);
  Finder counter(int n) => find.descendant(of: find.byKey(const ValueKey('found-count')), matching: find.text('FOUND $n / 3'), matchRoot: true);
  final card = find.byWidgetPredicate(
    (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('find-card-'),
    description: 'a find card',
  );
  final guide = find.byKey(const ValueKey('tap-guide'));
  final tapLine = find.byKey(const ValueKey('tap-guide-line'));
  bool titleCut(WidgetTester t) => t.renderObject<RenderParagraph>(find.text('GALLERY 8')).didExceedMaxLines;
  double zoomOf(WidgetTester t) => t.widget<InteractiveViewer>(find.byType(InteractiveViewer)).transformationController!.value.getMaxScaleOnAxis();

  /// Whether the room inside its paper edge covers the whole viewer: no
  /// band of anything else above, below or beside it.
  bool covers(WidgetTester t) {
    final viewer = t.getRect(find.byType(InteractiveViewer));
    final p = t.getRect(find.byKey(const ValueKey('investigation-picture')));
    final i = scene.inside;
    final room = Rect.fromLTRB(
      p.left + i.left * p.width,
      p.top + i.top * p.height,
      p.left + i.right * p.width,
      p.top + i.bottom * p.height,
    );
    return room.inflate(0.5).contains(viewer.topLeft) && room.inflate(0.5).contains(viewer.bottomRight - const Offset(0.01, 0.01));
  }

  /// Screenshots only: the pictures decoded before the shot (a test's
  /// clock does not wait for image decoding).
  Future<void> shot(WidgetTester t, String name) async {
    if (Platform.environment['LM_SCREENSHOTS'] == null) return;
    final context = t.element(find.byType(Scaffold).first);
    await t.runAsync(() async {
      for (final f in [ArtAssets.scenes[scene.artwork]!, for (final x in scene.finds) x.picture]) {
        await precacheImage(AssetImage(f), context);
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await t.pump(const Duration(milliseconds: 100));
    await capture(t, name);
  }

  group('Wave 1.1 data', () {
    test('the report no longer says all three were on the floor; its place lines are the same', () {
      expect(m1.letter, startsWith('GUARD REPORT — GALLERY 8\n\nI noticed three things in the gallery.\n'));
      expect(m1.letter, isNot(contains('on the floor')));
      for (final f in scene.finds) {
        expect(m1.letter, contains(f.reportLine));
      }
    });

    test('the arrival says why the report is read, without saying again what the place page said', () {
      expect(scene.arrival, hasLength(2));
      expect(scene.arrival.last, contains('report'));
      expect(scene.arrival.join(' '), isNot(contains('empty golden frame')), reason: "the place page's own line");
    });

    test('each find card names its thing and how it was found; the guide points at nothing', () {
      expect({for (final f in scene.finds) f.title: f.foundLine}, {
        'RED BUTTON': 'You found a red button under the bench!',
        'BLUE CLOTH': 'A piece of blue cloth was caught on the frame.',
        'WET FOOTPRINT': 'A wet footprint was found next to the door.',
      });
      expect(scene.hit(scene.guideAt), isNull);
      expect(scene.hit(scene.guideAt, slack: const Size(0.03, 0.03)), isNull);
      expect(scene.tapGuide, 'Tap the picture to investigate!');
      expect(scene.zoomGuide, 'Pinch to zoom in for a closer look.');
    });
  });

  for (final size in const [Size(360, 640), Size(390, 844), Size(412, 915)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    group('playing it at $tag', () {
      testWidgets('arriving: the room, why the report, then the report comes up; no envelope', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep03_m1');
        // Back from the search: the arrival plays (not seen yet on this page).
        await t.tap(find.byTooltip('Back'));
        await wait(t, const Duration(milliseconds: 350));

        // The arrival, under way: the first line is coming, the report not yet.
        expect(findReadable(scene.arrival.first), findsOneWidget);
        expect(find.text('TAP TO OPEN'), findsNothing);
        final start = find.byKey(const ValueKey('arrival-start'));
        expect(t.widget<IgnorePointer>(start).ignoring, isTrue,
            reason: 'the search cannot start before the report is there');
        await shot(t, 'case03_m1_arrival_${tag}_coming');

        // Quick taps show it all at once; the search then starts once.
        for (var i = 0; i < 3; i++) {
          await t.tapAt(const Offset(20, 300));
          await t.pump(const Duration(milliseconds: 40));
        }
        await t.pump(const Duration(milliseconds: 100));
        expect(t.widget<IgnorePointer>(start).ignoring, isFalse);
        expect(findReadable(scene.arrival.last), findsOneWidget);
        expect(line('I noticed three things in the gallery.'), findsOneWidget);
        expect((Offset.zero & size).contains(t.getRect(start).bottomCenter - const Offset(0, 1)), isTrue,
            reason: 'the start button stays in sight under the report');
        // The whole report, its three place lines included, reads on one
        // screen: nothing of it is under the button.
        expect(t.getRect(find.byKey(const ValueKey('arrival-report'))).bottom, lessThanOrEqualTo(t.getRect(start).top),
            reason: 'the report is read without scrolling');
        await shot(t, 'case03_m1_arrival_${tag}_report');
        await tapText(t, scene.startLabel, after: const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('investigation-picture')), findsOneWidget);

        // Back to the report: it is there at once, not played again; and from
        // the place page, INVESTIGATE brings the same arrival.
        await t.tap(find.byTooltip('Back'));
        await wait(t, const Duration(milliseconds: 400));
        expect(t.widget<IgnorePointer>(start).ignoring, isFalse);
        await t.tap(find.byTooltip('Back'));
        await wait(t, const Duration(milliseconds: 500));
        expect(find.text('INVESTIGATE'), findsOneWidget);
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 400));
        expect(findReadable(scene.arrival.last), findsOneWidget);
        expect(t.widget<IgnorePointer>(start).ignoring, isFalse);
      });

      testWidgets('searching: how to search is on screen; the first guide shows once and goes at a touch', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep03_m1');
        expect(findReadableContaining(scene.tapGuide), findsOneWidget);
        expect(find.text(scene.zoomGuide), findsOneWidget);
        expect(findReadable(scene.task), findsOneWidget);
        expect(find.text('GALLERY 8'), findsOneWidget);
        expect(titleCut(t), isFalse);
        expect(counter(0), findsOneWidget);
        expect(guide, findsOneWidget, reason: 'the "tap here" guide plays as the search opens');
        expect(scene.hit(scene.guideAt), isNull, reason: 'never over a thing');
        // The main line and the picture are on screen together, no scrolling.
        final screen = Offset.zero & size;
        expect(screen.contains(t.getRect(tapLine).bottomCenter), isTrue);
        expect(t.getRect(find.byKey(const ValueKey('search-panel'))).width, size.width, reason: 'the panel spans the screen');
        expect(screen.overlaps(t.getRect(find.byKey(const ValueKey('investigation-picture')))), isTrue);
        await shot(t, 'case03_m1_search_${tag}_start');

        // A first touch: the guide goes.
        await play.tapInPicture(t, const Offset(0.62, 0.86));
        expect(guide, findsNothing);
        // The report opened and closed, back to the report page and in again:
        // the guide does not come back.
        await tapText(t, scene.documentLabel, after: const Duration(milliseconds: 500));
        await tapText(t, 'BACK TO THE SEARCH', after: const Duration(milliseconds: 500));
        expect(guide, findsNothing);
        await t.tap(find.byTooltip('Back'));
        await wait(t, const Duration(milliseconds: 1700));
        await tapText(t, scene.startLabel, after: const Duration(milliseconds: 500));
        expect(guide, findsNothing);
      });

      testWidgets('three things in any order, each on its card, each once; the last answers the puzzle once', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep03_m1');
        expect(find.text('CHECK ANSWER'), findsNothing, reason: 'no multiple choice any more');

        // The bench's seat: the report says UNDER it. Nothing is recorded.
        await play.tapInPicture(t, scene.spots.firstWhere((s) => s.label == 'On the bench').areas.first.center);
        expect(line('UNDER'), findsOneWidget);
        expect(card, findsNothing);
        expect(counter(0), findsOneWidget);

        // Footprint, cloth, then button: not the report's order. The card
        // opens once the double-tap window has passed; a tap on it right
        // then does not close it unseen.
        await t.tapAt(play.pictureAt(t, thing('footprint').areas.first.center));
        await t.pump(const Duration(milliseconds: 320));
        expect(card, findsOneWidget);
        await t.tap(card);
        await t.pump(const Duration(milliseconds: 30));
        expect(card, findsOneWidget);
        await wait(t, const Duration(milliseconds: 400));
        expect(find.text('WET FOOTPRINT'), findsOneWidget);
        expect(find.text(thing('footprint').foundLine), findsOneWidget);
        expect(find.textContaining('XP'), findsNothing, reason: 'the card is the find, not the reward');
        expect(find.textContaining('coin', findRichText: true), findsNothing);
        expect(counter(1), findsOneWidget);
        await shot(t, 'case03_m1_search_${tag}_card');
        await play.closeFindCard(t);
        expect(card, findsNothing);

        // The same place again: no second find.
        await play.tapInPicture(t, thing('footprint').areas.first.center);
        expect(line('already'), findsOneWidget);
        expect(card, findsNothing);
        expect(counter(1), findsOneWidget);

        await play.tapInPicture(t, thing('cloth').areas.first.center);
        await play.closeFindCard(t);
        expect(counter(2), findsOneWidget);
        await shot(t, 'case03_m1_search_${tag}_two');

        var progress = play.ref.read(gameControllerProvider);
        expect(progress.isCompleted('ep03_m1'), isFalse);
        expect(progress.attempts['ep03_m1'] ?? 0, 0, reason: 'looking around is not answering');
        expect(progress.wrongCount('ep03_m1'), 0);

        // The last: its card first, then the answer, once, however many taps.
        await play.tapInPicture(t, thing('button').areas.first.center);
        expect(find.text('RED BUTTON'), findsOneWidget);
        expect(find.text('Tap to continue'), findsOneWidget);
        expect(counter(3), findsOneWidget);
        expect(play.ref.read(gameControllerProvider).isCompleted('ep03_m1'), isFalse, reason: 'not before its card is seen');
        await wait(t, const Duration(milliseconds: 400));
        for (var i = 0; i < 4; i++) {
          if (card.evaluate().isNotEmpty) await t.tap(card, warnIfMissed: false);
          await t.pump(const Duration(milliseconds: 30));
        }
        await wait(t, const Duration(milliseconds: 1400));
        expect(find.byKey(const ValueKey('discovery-moment')), findsOneWidget);
        await shot(t, 'case03_m1_search_${tag}_discovery');

        progress = play.ref.read(gameControllerProvider);
        expect(progress.isCompleted('ep03_m1'), isTrue);
        expect(progress.attempts['ep03_m1'], 1, reason: 'answered once');
        expect(progress.wrongCount('ep03_m1'), 0);
        expect(progress.collectedEvidence(c03).map((e) => e.id), contains('ep03_e1'));
        expect(progress.collectedClues(c03).map((c) => c.id), contains('ep03_c1'));
        expect(XpBreakdown.of(m1, progress).total, 30);
        expect(progress.isUnlocked(c03, 'ep03_m2'), isTrue, reason: 'Case 03 M2 is next');
        expect(play.ref.read(walletProvider).entries.where((e) => e.key == 'mission:ep03_m1'), hasLength(1));
      });

      testWidgets('looking closer: double tap, drag and pinch move the picture, never find; a tap still lands true', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep03_m1');
        // The opening view: the room covers its whole place, no band.
        final home = zoomOf(t);
        expect(covers(t), isTrue, reason: 'the room fills its place at the opening');

        // Double tap on the cloth: closer around it; nothing found by it.
        final at = play.pictureAt(t, thing('cloth').areas.first.center);
        await t.tapAt(at);
        await t.pump(const Duration(milliseconds: 60));
        await t.tapAt(at);
        await wait(t, const Duration(milliseconds: 600));
        expect(zoomOf(t), closeTo(2.5, 0.01));
        expect(card, findsNothing);
        expect(counter(0), findsOneWidget);

        // A drag over the button's spot only moves the picture.
        await t.dragFrom(play.pictureAt(t, const Offset(0.7, 0.5)), const Offset(-60, -40));
        await wait(t, const Duration(milliseconds: 500));
        expect(card, findsNothing);
        expect(counter(0), findsOneWidget);

        // Enlarged and moved, a tap on the cloth still finds the cloth.
        final cloth = play.pictureAt(t, thing('cloth').areas.first.center);
        if ((Offset.zero & size).contains(cloth)) {
          await play.tapInPicture(t, thing('cloth').areas.first.center);
          expect(find.text('BLUE CLOTH'), findsOneWidget);
          await play.closeFindCard(t);
          await shot(t, 'case03_m1_search_${tag}_zoomed');
        }

        // Double tap again (on screen, the viewer's middle): the opening view.
        final mid = t.getRect(find.byType(InteractiveViewer)).center;
        await t.tapAt(mid);
        await t.pump(const Duration(milliseconds: 60));
        await t.tapAt(mid);
        await wait(t, const Duration(milliseconds: 600));
        expect(zoomOf(t), closeTo(home, 0.01));

        // A pinch: two fingers apart, enlarged, nothing found.
        final centre = play.pictureAt(t, const Offset(0.62, 0.86));
        final a = await t.startGesture(centre - const Offset(20, 0), pointer: 7);
        final b = await t.startGesture(centre + const Offset(20, 0), pointer: 8);
        for (var i = 0; i < 6; i++) {
          await a.moveBy(const Offset(-12, 0));
          await b.moveBy(const Offset(12, 0));
          await t.pump(const Duration(milliseconds: 16));
        }
        await a.up();
        await b.up();
        await wait(t, const Duration(milliseconds: 500));
        expect(zoomOf(t), greaterThan(home + 0.2));
        expect(find.text('BLUE CLOTH'), findsNothing);

        // Fingers together: out as far as the room still fills its place
        // (the opening view here), never a band around it.
        final c2 = t.getRect(find.byType(InteractiveViewer)).center;
        final p = await t.startGesture(c2 - const Offset(120, 0), pointer: 9);
        final q = await t.startGesture(c2 + const Offset(120, 0), pointer: 10);
        for (var i = 0; i < 10; i++) {
          await p.moveBy(const Offset(11, 0));
          await q.moveBy(const Offset(-11, 0));
          await t.pump(const Duration(milliseconds: 16));
        }
        await p.up();
        await q.up();
        await wait(t, const Duration(milliseconds: 500));
        expect(zoomOf(t), closeTo(home, 0.01));
        expect(covers(t), isTrue, reason: 'pinched out, the room still fills its place');
        expect(play.ref.read(gameControllerProvider).attempts['ep03_m1'] ?? 0, 0);
      });

      testWidgets('layout: the room opens large with all three places in sight; the card keeps its edges', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep03_m1');
        final viewer = t.getRect(find.byType(InteractiveViewer));
        // The picture is shown wider than the screen, and taller than the
        // whole print would be: the room leads, not the navy around it.
        final picture = t.getRect(find.byKey(const ValueKey('investigation-picture')));
        expect(picture.width, greaterThan(viewer.width * 1.1));
        expect(picture.height, greaterThan(viewer.width / 1.5 * 1.1));
        // Every place to search is on screen at the opening, with its ring
        // room: the door's side, the bench and the empty frame.
        for (final f in scene.finds) {
          final r = f.areas.first;
          for (final corner in [r.topLeft, r.bottomRight, r.center]) {
            expect(viewer.contains(play.pictureAt(t, corner)), isTrue, reason: '${f.id} ${f.spot} at the opening');
          }
        }
        await shot(t, 'case03_m1_layout_${tag}_opening');

        // A find card: square in the middle, its whole edge on screen with
        // at least 20 dp either side, at most 320 dp wide.
        await play.tapInPicture(t, thing('cloth').areas.first.center);
        final sheet = t.getRect(find.byKey(const ValueKey('find-sheet')));
        expect(sheet.left, greaterThanOrEqualTo(20));
        expect(size.width - sheet.right, greaterThanOrEqualTo(20));
        expect(sheet.width, lessThanOrEqualTo(320));
        expect((sheet.center.dx - size.width / 2).abs(), lessThan(1));
        expect(sheet.top, greaterThanOrEqualTo(0));
        expect(sheet.bottom, lessThanOrEqualTo(size.height));
        await shot(t, 'case03_m1_layout_${tag}_card');
      });

      testWidgets('the report sheet: the three lines ticked as found, the tips; closing it keeps the search', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep03_m1');
        await play.tapInPicture(t, thing('cloth').areas.first.center);
        await play.closeFindCard(t);

        await tapText(t, scene.documentLabel, after: const Duration(milliseconds: 500));
        final sheet = find.byKey(const ValueKey('investigation-report'));
        expect(sheet, findsOneWidget);
        for (final f in scene.finds) {
          expect(find.descendant(of: sheet, matching: findReadable(f.reportLine)), findsOneWidget);
        }
        expect(find.descendant(of: sheet, matching: find.bySemanticsLabel('Found')), findsOneWidget);
        expect(find.descendant(of: sheet, matching: find.bySemanticsLabel('Not found yet')), findsNWidgets(2));
        await shot(t, 'case03_m1_report_$tag');
        await tapText(t, 'BACK TO THE SEARCH', after: const Duration(milliseconds: 500));
        expect(sheet, findsNothing);
        expect(counter(1), findsOneWidget, reason: 'the cloth is still found');

        // A hint: the free one opens at once (no dialog, no sheet), written in
        // the panel under the picture; the report lists it too.
        await tapText(t, 'Get a Free Hint', after: const Duration(milliseconds: 500));
        expect(tipSheetButton, findsNothing, reason: 'no dialog for the free hint');
        await wait(t, const Duration(milliseconds: 800));
        expect(sheet, findsNothing, reason: 'the report stays closed');
        expect(
          find.descendant(of: find.byKey(const ValueKey('search-panel')), matching: find.text('DETECTIVE HINT 1')),
          findsOneWidget,
        );
        expect(play.ref.read(gameControllerProvider).hintsFor('ep03_m1'), 1);
        await tapText(t, scene.documentLabel, after: const Duration(milliseconds: 500));
        expect(find.descendant(of: sheet, matching: find.text('DETECTIVE HINT 1')), findsOneWidget);
      });

      testWidgets('back to the report keeps what was found; a restart starts the search again', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep03_m1');
        await play.tapInPicture(t, thing('cloth').areas.first.center);
        await play.closeFindCard(t);
        expect(counter(1), findsOneWidget);

        await t.tap(find.byTooltip('Back'));
        await wait(t, const Duration(milliseconds: 1700));
        expect(find.text('TAP TO OPEN'), findsNothing);
        await tapText(t, scene.startLabel, after: const Duration(milliseconds: 600));
        expect(counter(1), findsOneWidget, reason: 'the cloth is still found');

        // The app closed mid-search: nothing of the search was saved, the
        // mission is not solved, and it opens on the search again.
        await play.restart(t);
        play.ref.read(routerProvider).go(Routes.mission('ep03_m1'));
        await wait(t, const Duration(milliseconds: 1200));
        expect(find.byKey(const ValueKey('investigation-picture')), findsOneWidget);
        expect(counter(0), findsOneWidget);
        expect(play.ref.read(gameControllerProvider).isCompleted('ep03_m1'), isFalse);
      });

      testWidgets('solved and opened again: the solved page, no second solve', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep03_m1');
        await play.solve(t, m1);
        await play.restart(t);
        play.ref.read(routerProvider).go(Routes.mission('ep03_m1'));
        await wait(t, const Duration(milliseconds: 1200));
        expect(find.byKey(const ValueKey('investigation-picture')), findsNothing);
        expect(find.text('SOLVED'), findsOneWidget);
        final progress = play.ref.read(gameControllerProvider);
        expect(progress.completedMissionIds.where((id) => id == 'ep03_m1'), hasLength(1));
      });

      testWidgets('back while the last card is open: on return the search finishes, once', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep03_m1');
        for (final id in ['button', 'cloth']) {
          await play.tapInPicture(t, thing(id).areas.first.center);
          await play.closeFindCard(t);
        }
        await play.tapInPicture(t, thing('footprint').areas.first.center);
        expect(card, findsOneWidget);
        await t.tap(find.byTooltip('Back'));
        await wait(t, const Duration(milliseconds: 1700));
        expect(play.ref.read(gameControllerProvider).isCompleted('ep03_m1'), isFalse);
        await tapText(t, scene.startLabel, after: const Duration(milliseconds: 1400));
        expect(find.byKey(const ValueKey('discovery-moment')), findsOneWidget);
        final progress = play.ref.read(gameControllerProvider);
        expect(progress.isCompleted('ep03_m1'), isTrue);
        expect(progress.attempts['ep03_m1'], 1);
      });

      testWidgets('stuck: after a few empty looks, a nudge to the report and the tips', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep03_m1');
        for (var i = 0; i < 3; i++) {
          await play.tapInPicture(t, const Offset(0.62, 0.86));
        }
        expect(line(scene.missLine), findsOneWidget);
        expect(line('get a hint'), findsOneWidget);
        expect(find.text('Get a Free Hint'), findsOneWidget, reason: 'the hints are there as on every puzzle');
      });
    });
  }

  group('larger text and still motion', () {
    testWidgets('text 1.3× at 360×640: arrival, search, card and report fit', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(360, 640), 'ep03_m1', textScale: 1.3);
      final screen = Offset.zero & const Size(360, 640);
      expect(screen.contains(t.getRect(tapLine).bottomCenter), isTrue, reason: 'tap the picture');
      expect(screen.contains(t.getRect(find.text(scene.zoomGuide)).bottomCenter), isTrue, reason: 'pinch');
      expect(titleCut(t), isFalse, reason: 'GALLERY 8 is never cut');
      expect(t.getRect(find.byKey(const ValueKey('investigation-picture'))).height, greaterThan(150));
      await shot(t, 'case03_m1_search_360x640_text13');
      await play.tapInPicture(t, thing('button').areas.first.center);
      expect(find.text('RED BUTTON'), findsOneWidget);
      final sheet = t.getRect(find.byKey(const ValueKey('find-sheet')));
      expect(sheet.left, greaterThanOrEqualTo(20));
      expect(360 - sheet.right, greaterThanOrEqualTo(20));
      expect(sheet.top, greaterThanOrEqualTo(0));
      expect(sheet.bottom, lessThanOrEqualTo(640));
      expect(find.text('Tap to keep searching'), findsOneWidget);
      await shot(t, 'case03_m1_card_360x640_text13');
      await play.closeFindCard(t);
      await tapText(t, scene.documentLabel, after: const Duration(milliseconds: 500));
      await tapText(t, 'BACK TO THE SEARCH', after: const Duration(milliseconds: 500));
      await t.tap(find.byTooltip('Back'));
      await wait(t, const Duration(milliseconds: 1700));
      await reveal(t, find.text(scene.startLabel));
      await shot(t, 'case03_m1_arrival_360x640_text13');
      expect(t.takeException(), isNull);
    });

    testWidgets('reduced motion: no guide animation, the words say how to search', (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'ep03_m1');
      expect(guide, findsNothing);
      expect(tapLine, findsOneWidget);
      await play.tapInPicture(t, thing('cloth').areas.first.center);
      expect(find.text('BLUE CLOTH'), findsOneWidget);
    });
  });

  // LM_SCREENSHOTS=<folder>: the areas over Gallery 8 (things in green,
  // places in red) and the three things laid where they are found.
  testWidgets('the areas on the picture (for checking by eye)', (t) async {
    if (Platform.environment['LM_SCREENSHOTS'] == null) return;
    t.view.physicalSize = const Size(1536, 1024);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      home: RepaintBoundary(
        key: const ValueKey('shot'),
        child: Stack(children: [
          Positioned.fill(child: Image.asset(ArtAssets.scenes[scene.artwork]!, fit: BoxFit.fill)),
          for (final f in scene.finds)
            Positioned(
              left: f.at.dx * 1536 - f.width * 1536 / 2,
              top: f.at.dy * 1024 - f.width * 1536 / f.pictureAspect / 2,
              width: f.width * 1536,
              height: f.width * 1536 / f.pictureAspect,
              child: Transform.rotate(
                angle: f.turn,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(1, f.squash, 1),
                  child: Image.asset(f.picture, fit: BoxFit.contain),
                ),
              ),
            ),
          Positioned.fill(child: CustomPaint(painter: _Areas(scene))),
        ]),
      ),
    ));
    await t.runAsync(() async {
      for (final f in [ArtAssets.scenes[scene.artwork]!, for (final x in scene.finds) x.picture]) {
        await precacheImage(AssetImage(f), t.element(find.byType(Stack).first));
      }
    });
    await t.pump();
    await t.runAsync(() async {
      final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
      final image = await boundary.toImage();
      final png = await image.toByteData(format: ImageByteFormat.png);
      File('${Platform.environment['LM_SCREENSHOTS']}/case03_m1_areas.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  });
}

class _Areas extends CustomPainter {
  _Areas(this.scene);

  final InvestigationScene scene;

  @override
  void paint(Canvas canvas, Size size) {
    Rect at(Rect r) => Rect.fromLTRB(r.left * size.width, r.top * size.height, r.right * size.width, r.bottom * size.height);
    final thing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0xFF00C853);
    final place = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFFF1744);
    for (final s in scene.spots) {
      for (final r in s.areas) {
        canvas.drawRect(at(r), place);
      }
    }
    for (final f in scene.finds) {
      for (final r in f.areas) {
        canvas.drawRect(at(r), thing);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
