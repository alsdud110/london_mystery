import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/theme/app_theme.dart';
import 'package:world_mystery/data/mock/season1/season1_deductions.dart';
import 'package:world_mystery/data/mock/season1/season1_explores.dart';
import 'package:world_mystery/data/mock/season1/season1_investigations.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/mission/widgets/search_stage.dart';
import 'package:world_mystery/widgets/place_scenery.dart';

import 'full_playthrough_test.dart' show tapText, wait;
import 'mission_play.dart';
import 'title_screen_test.dart' show capture;

/// The searched places' page (Case 01's station and Big Ben, Case 03's
/// gallery): the room covers its whole place on screen, at the opening and
/// however it is pinched, dragged or double tapped, with no second, dimmed
/// copy of it behind; every thing to find is in sight at the opening; the
/// words sit on the page's paper under it; and a tap still lands where it
/// is meant to.
void main() {
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

  group('SearchFrame', () {
    const inside = Rect.fromLTRB(0.03, 0.04, 0.97, 0.95);
    const focus = Rect.fromLTRB(0.15, 0.10, 0.85, 0.90);
    const frame = SearchFrame(width: 390, aspect: 1.5, inside: inside, focus: focus, maxScale: 4);

    bool coversViewport(Matrix4 m, Size viewport) {
      final s = m.getMaxScaleOnAxis();
      final t = m.getTranslation();
      final content = Rect.fromLTWH(t.x, t.y, frame.content.width * s, frame.content.height * s);
      return content.inflate(1e-6).contains(Offset.zero) &&
          content.inflate(1e-6).contains(Offset(viewport.width, viewport.height));
    }

    Rect onScreen(Matrix4 m, Rect r) => MatrixUtils.transformRect(m, r);

    test('the inside part runs the full width; the paper edge lies outside it', () {
      expect(frame.content.width, 390);
      expect(frame.picture.width * inside.width, closeTo(390, 1e-9));
      expect(frame.origin.dx, closeTo(-inside.left * frame.picture.width, 1e-9));
      expect(frame.origin.dy, closeTo(-inside.top * frame.picture.height, 1e-9));
    });

    test('at its ideal height the opening shows the focus whole and covers its place', () {
      final viewport = Size(390, frame.idealHeight);
      final home = frame.home(viewport);
      expect(coversViewport(home, viewport), isTrue);
      final f = onScreen(home, frame.focusRect);
      expect(f.left, greaterThanOrEqualTo(-1e-6));
      expect(f.right, lessThanOrEqualTo(390 + 1e-6));
      expect(f.top, greaterThanOrEqualTo(-1e-6));
      expect(f.bottom, lessThanOrEqualTo(viewport.height + 1e-6));
      expect(home.getMaxScaleOnAxis(), closeTo(frame.minScale(viewport), 1e-9), reason: 'no farther out to go');
    });

    test('a shorter place: the opening starts closer, still covering it', () {
      for (final h in [120.0, 200.0, frame.idealHeight - 1]) {
        final viewport = Size(390, h);
        expect(coversViewport(frame.home(viewport), viewport), isTrue, reason: 'h $h');
        expect(frame.minScale(viewport), greaterThanOrEqualTo(1));
      }
    });

    test('any view is kept inside the picture; a changed place keeps the spot in the middle', () {
      const viewport = Size(390, 300);
      // Asked for a spot past the edge: held at the edge.
      final edge = frame.view(2, const Offset(5, 5), Offset.zero, viewport);
      expect(coversViewport(edge, viewport), isTrue);
      final far = frame.view(2, Offset(frame.content.width, frame.content.height), const Offset(390, 300), viewport);
      expect(coversViewport(far, viewport), isTrue);

      // Closer around a spot, then the place gets shorter (a hint opened)
      // and taller again: it still covers, the spot still in the middle.
      final spot = frame.focusRect.center;
      final close = frame.view(2.5, spot, viewport.center(Offset.zero), viewport);
      const shorter = Size(390, 220);
      final kept = frame.keep(close, shorter);
      expect(coversViewport(kept, shorter), isTrue);
      expect(kept.getMaxScaleOnAxis(), closeTo(2.5, 1e-9));
      expect(MatrixUtils.transformPoint(kept, spot).dx, closeTo(195, 1));
      // Out as far as it went, then taller: brought in just enough.
      final out = frame.home(shorter);
      final taller = Size(390, frame.idealHeight * 1.2);
      expect(coversViewport(frame.keep(out, taller), taller), isTrue);
    });
  });

  final season = MockEpisodeRepository.bundled();
  final ep01 = season.firstWhere((e) => e.id == 'ep01');
  final ep03 = season.firstWhere((e) => e.id == 'ep03');
  final station = exploreOf(ep01.missionById('m01')!)!;
  final bigBen = deductionOf(ep01.missionById('m03')!)!;
  final gallery = investigationOf(ep03.missionById('ep03_m1')!)!;

  /// The three searched places: the mission, the picture's key, the
  /// picture inside its paper edge, the things that must be in sight at
  /// the opening, a spot that holds nothing and what a tap there says, and
  /// whether its bar is navy.
  final places = [
    (
      'm01',
      'explore-picture',
      station.inside,
      [for (final s in station.spots) s.areas.first],
      station.pixels.at(760, 940),
      station.missLine,
      false,
    ),
    (
      'm03',
      'deduction-picture',
      bigBen.inside,
      [for (final c in bigBen.clues) c.areas.first],
      bigBen.guideAt,
      bigBen.missLine,
      false,
    ),
    (
      'ep03_m1',
      'investigation-picture',
      gallery.inside,
      [for (final f in gallery.finds) f.areas.first],
      gallery.guideAt,
      gallery.missLine,
      true,
    ),
  ];

  // An older iPhone and a small Android, today's iPhone and Android sizes,
  // and a large iPhone.
  const sizes = [Size(360, 640), Size(390, 844), Size(412, 915), Size(430, 932)];

  /// Screenshots only: the pictures on screen decoded before the shot (a
  /// test's clock does not wait for image decoding).
  Future<void> settlePictures(WidgetTester t) async {
    if (Platform.environment['LM_SCREENSHOTS'] == null) return;
    final context = t.element(find.byType(Scaffold).first);
    await t.runAsync(() async {
      for (final i in t.widgetList<Image>(find.byType(Image))) {
        await precacheImage(i.image, context);
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await t.pump(const Duration(milliseconds: 100));
  }

  for (final (id, key, inside, targets, empty, miss, navy) in places) {
    Rect pictureRect(WidgetTester t) =>
        t.getRect(find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(GestureDetector)).first);
    Offset at(WidgetTester t, Offset point) {
      final p = pictureRect(t);
      return Offset(p.left + point.dx * p.width, p.top + point.dy * p.height);
    }

    Rect room(WidgetTester t) {
      final p = pictureRect(t);
      return Rect.fromLTRB(
        p.left + inside.left * p.width,
        p.top + inside.top * p.height,
        p.left + inside.right * p.width,
        p.top + inside.bottom * p.height,
      );
    }

    void expectCovered(WidgetTester t, String when) {
      final viewer = t.getRect(find.byType(InteractiveViewer));
      final r = room(t).inflate(0.5);
      expect(r.contains(viewer.topLeft) && r.contains(viewer.bottomRight - const Offset(0.01, 0.01)), isTrue,
          reason: '$id: the room covers its place $when (viewer $viewer, room ${room(t)})');
    }

    for (final size in sizes) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('$id at $tag: one picture, covering its place, everything in sight; the words on paper under it', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, id);
        expect(t.takeException(), isNull, reason: 'no overflow');
        await settlePictures(t);
        await capture(t, 'stage_${id}_${tag}_start');

        // No second, dimmed copy of the room behind it.
        expect(find.byType(PlaceScenery), findsNothing);
        expect(find.byType(ImageFiltered), findsNothing);

        final viewer = t.getRect(find.byType(InteractiveViewer));
        expect(viewer.width, size.width, reason: 'the room runs the screen\'s full width');
        expectCovered(t, 'at the opening');
        for (final r in targets) {
          for (final corner in [r.topLeft, r.bottomRight]) {
            expect(viewer.inflate(0.5).contains(at(t, corner)), isTrue, reason: '$id: $r in sight at the opening');
          }
        }

        // The bar's status icons: dark on paper, light on navy.
        final bar = t.widget<AppBar>(find.byType(AppBar));
        expect(bar.systemOverlayStyle, navy ? AppTheme.statusOnNight : AppTheme.statusOnPaper);

        // The page under the room is paper to the bottom edge; the words
        // start right under the picture and stay on screen.
        final paper = t.getRect(find.byType(SearchStage));
        expect(paper.bottom, size.height);
        final words = find.descendant(of: find.byType(SearchStage), matching: find.byType(RichText));
        for (final e in words.evaluate()) {
          final r = t.getRect(find.byElementPredicate((x) => identical(x, e)));
          if (r.height == 0) continue;
          expect(r.top, greaterThanOrEqualTo(viewer.bottom - 0.5), reason: 'no words over the room');
          expect(r.bottom, lessThanOrEqualTo(size.height + 0.5), reason: 'the words are on screen');
        }
      });

      testWidgets('$id at $tag: a slip where it reads; pinched and dragged: still covering; a tap still lands', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, id);
        final viewer = t.getRect(find.byType(InteractiveViewer));
        final centre = viewer.center;

        // A tap on an empty spot: a pencilled slip, on the page under the
        // words when there is room, over the top of the room when not;
        // never past the screen.
        final emptyAt = at(t, empty);
        expect(viewer.contains(emptyAt), isTrue);
        await t.tapAt(emptyAt);
        await wait(t, const Duration(milliseconds: 700));
        expect(find.text(miss), findsOneWidget);
        final slip = t.getRect(find.text(miss));
        expect(slip.bottom, lessThanOrEqualTo(size.height), reason: 'the slip is on screen');
        expect(slip.top >= viewer.bottom || slip.bottom <= viewer.top + viewer.height * 0.5, isTrue,
            reason: 'under the words, or over the top of the room');
        await settlePictures(t);
        await capture(t, 'stage_${id}_${tag}_slip');

        // Fingers together, as far as they go.
        final p = await t.startGesture(centre - const Offset(120, 0), pointer: 1);
        final q = await t.startGesture(centre + const Offset(120, 0), pointer: 2);
        for (var i = 0; i < 10; i++) {
          await p.moveBy(const Offset(11, 0));
          await q.moveBy(const Offset(-11, 0));
          await t.pump(const Duration(milliseconds: 16));
        }
        await p.up();
        await q.up();
        await wait(t, const Duration(milliseconds: 500));
        expectCovered(t, 'pinched out');

        // Apart: closer; then dragged to a corner and past it.
        final a = await t.startGesture(centre - const Offset(20, 0), pointer: 3);
        final b = await t.startGesture(centre + const Offset(20, 0), pointer: 4);
        for (var i = 0; i < 8; i++) {
          await a.moveBy(const Offset(-12, 0));
          await b.moveBy(const Offset(12, 0));
          await t.pump(const Duration(milliseconds: 16));
        }
        await a.up();
        await b.up();
        await wait(t, const Duration(milliseconds: 500));
        await t.dragFrom(centre, const Offset(400, 400));
        await wait(t, const Duration(milliseconds: 600));
        expectCovered(t, 'dragged past the corner');

        // Enlarged and moved: a thing to find, dragged to the middle and
        // tapped where it now lies, is found (never the miss line).
        final target = targets.first.center;
        final by = centre - at(t, target);
        final finger = await t.startGesture(centre, pointer: 5);
        for (var i = 0; i < 12; i++) {
          await finger.moveBy(by / 12);
          await t.pump(const Duration(milliseconds: 16));
        }
        await t.pump(const Duration(milliseconds: 300)); // held still: no fling
        await finger.up();
        await wait(t, const Duration(milliseconds: 600));
        expectCovered(t, 'dragged back');
        expect(viewer.contains(at(t, target)), isTrue, reason: 'the thing is in sight');
        await t.tapAt(at(t, target));
        await wait(t, const Duration(milliseconds: 800));
        expect(find.text(miss), findsNothing);
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('$id: a hint opened makes the room\'s place shorter; it still covers it, and a tap still lands', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(360, 640), id);
      final before = t.getRect(find.byType(InteractiveViewer));
      await tapText(t, 'Get a Free Hint', after: const Duration(milliseconds: 900));
      expect(t.takeException(), isNull, reason: 'no overflow');
      final after = t.getRect(find.byType(InteractiveViewer));
      expect(after.height, lessThanOrEqualTo(before.height));
      expect(after.height, greaterThan(640 * 0.25), reason: 'the room keeps its share');
      expectCovered(t, 'with the hint open');
      await settlePictures(t);
      await capture(t, 'stage_${id}_360x640_hint');
      // The first thing to find, tapped where it now lies: it answers (its
      // card, its note, or its page opens: something other than a miss).
      final target = targets.first.center;
      expect(after.contains(at(t, target)), isTrue);
      await t.tapAt(at(t, target));
      await wait(t, const Duration(milliseconds: 800));
      expect(find.text(miss), findsNothing);
      expect(t.takeException(), isNull);
    });
  }

  // A place looked round (King's Cross) keeps its picture when a hint opens
  // (`SearchStage.pictureFirst`): the hint scrolls in its own box. The other
  // searched places are as before (above).
  for (final size in const [Size(320, 568), Size(360, 640)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('m01 at $tag: a hint and the letter read: the station keeps its height (its share on the shortest), all in sight', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, size, 'm01');
      Rect picture() => t.getRect(find.byKey(const ValueKey('explore-picture')));
      final before = t.getRect(find.byType(InteractiveViewer));
      await tapText(t, 'Get a Free Hint', after: const Duration(milliseconds: 900));
      expect(t.takeException(), isNull, reason: '$size: no overflow');
      final suitcase = station.spot('suitcase').areas.first.center;
      await t.tapAt(Offset(picture().left + suitcase.dx * picture().width, picture().top + suitcase.dy * picture().height));
      await wait(t, const Duration(milliseconds: 600));
      await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1600));
      await tapText(t, 'BACK TO INVESTIGATION', after: const Duration(milliseconds: 600));
      expect(t.takeException(), isNull, reason: '$size: no overflow');
      final after = t.getRect(find.byType(InteractiveViewer));
      // The picture keeps its height, or gives up only what the actions
      // need to keep their least share of the page (no more).
      final panel = t.getRect(find.byKey(const ValueKey('explore-panel')));
      expect(
        (after.height - before.height).abs() < 0.5 || panel.height <= size.height * SearchStage.actionsShare + 0.5,
        isTrue,
        reason: '$size: picture ${before.height} → ${after.height}, actions ${panel.height}',
      );
      final hints = t.getRect(find.byKey(const ValueKey('explore-hints')));
      expect(hints.height, greaterThan(40), reason: '$size: the hint\'s first lines are read');
      expect(hints.bottom, lessThanOrEqualTo(size.height), reason: '$size: on screen');
      for (final s in station.spots) {
        final c = s.areas.first.center;
        final at = Offset(picture().left + c.dx * picture().width, picture().top + c.dy * picture().height);
        expect(after.contains(at), isTrue, reason: '$size: ${s.id} in sight');
      }
    });
  }

  testWidgets('the letter\'s way back, BACK TO INVESTIGATION: sealed, after the envelope; open, under the letter on screen (320x568, text ×1.3)', (t) async {
    final play = MissionPlay();
    await play.openPuzzle(t, const Size(320, 568), 'm01');
    t.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await t.pump();
    final p = t.getRect(find.byKey(const ValueKey('explore-picture')));
    final suitcase = station.spot('suitcase').areas.first.center;
    await t.tapAt(Offset(p.left + suitcase.dx * p.width, p.top + suitcase.dy * p.height));
    await wait(t, const Duration(milliseconds: 600));
    final back = find.byKey(const ValueKey('explore-close'));
    expect(find.descendant(of: back, matching: find.text('BACK TO INVESTIGATION')), findsOneWidget);
    expect(find.text('BACK TO THE STATION'), findsNothing);
    // Sealed: the envelope comes first, the way back under it.
    expect(t.getRect(back).top, greaterThan(t.getRect(find.text('TAP TO OPEN')).bottom));
    await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1600));
    // Open: the way back is on screen with no scroll, under the letter.
    final r = t.getRect(back);
    expect(r.top, greaterThanOrEqualTo(0));
    expect(r.bottom, lessThanOrEqualTo(568), reason: 'no scroll to reach it');
    expect(t.takeException(), isNull, reason: 'no overflow');
    await t.tap(find.byKey(const ValueKey('explore-close')));
    await wait(t, const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('explore-close')), findsNothing, reason: 'back at the station');
  });
}
