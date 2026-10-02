import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/widgets/art_assets.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';

/// The title screen: the detective's office, the title in the dark of the
/// bookshelves (clear of the window), the button raised off the bottom edge.
/// Set LM_SCREENSHOTS to a folder to save a picture of each state.
void main() {
  setUpAll(() async {
    for (final (family, files) in [
      ('Nunito', ['Nunito.ttf']),
      ('Cinzel', ['Cinzel.ttf']),
      ('LibreBaskerville', ['LibreBaskerville.ttf', 'LibreBaskerville-Italic.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await loader.load();
    }
  });

  final saved = {AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINYOUNG').toJson())};

  for (final (size, scale, save) in const [
    (Size(360, 640), 1.0, false),
    (Size(360, 640), 1.0, true),
    (Size(390, 844), 1.0, false),
    (Size(390, 844), 1.0, true),
    (Size(360, 640), 1.3, false),
    (Size(360, 640), 1.3, true),
  ]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}${scale == 1 ? '' : '_text13'}${save ? '_save' : ''}';
    testWidgets('title screen at $tag: the office, the title clear of the window, the button off the edge', (t) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: save ? saved : const {}),
        child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
      ));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600))); // decode the painting
      await wait(t);
      expect(t.takeException(), isNull, reason: 'no overflow');

      // The painting is the page.
      final office = find.byWidgetPredicate((w) => w is Image && w.image is ResizeImage
          ? ((w.image as ResizeImage).imageProvider as AssetImage).assetName == ArtAssets.titleDetectiveOffice
          : w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == ArtAssets.titleDetectiveOffice);
      expect(office, findsOneWidget);
      expect(t.getRect(office), Offset.zero & size, reason: 'full screen, not in a frame');

      // One subtitle: the invitation for a new player, the greeting for one coming back.
      final subtitle = save ? 'Welcome back, Detective MINYOUNG!' : 'Become a Detective.';
      expect(find.text(save ? 'Become a Detective.' : 'Welcome back, Detective MINYOUNG!'), findsNothing);
      // Same left edge as the title above it.
      expect(t.getRect(find.text(subtitle)).left, closeTo(t.getRect(find.text('THE CASEBOOK OF')).left, 1));
      for (final s in ['THE CASEBOOK OF', 'LONDON', 'MYSTERY', subtitle]) {
        expect(find.text(s), findsOneWidget);
        // The window (moon, Big Ben) is the right part of the painting.
        expect(t.getRect(find.text(s)).right, lessThan(size.width * 0.72), reason: '$s stays clear of the window');
      }
      // The two title words never break mid-word, whatever the text size.
      for (final word in ['LONDON', 'MYSTERY']) {
        final para = t.renderObject<RenderParagraph>(find.text(word));
        expect(para.didExceedMaxLines, isFalse, reason: word);
        expect(para.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: word.length)).map((b) => b.top).toSet().length, 1,
            reason: '$word on one line');
      }
      final cta = find.text(save ? 'CONTINUE ADVENTURE' : 'START ADVENTURE');
      expect(cta, findsOneWidget);
      final button = t.getRect(find.ancestor(of: cta, matching: find.byType(GestureDetector)).first);
      expect(button.bottom, lessThan(size.height - (save ? 48 : 36)), reason: 'raised off the bottom edge');
      expect(button.top, greaterThan(size.height * 0.7), reason: 'below the desk things, not over the window');
      if (save) {
        // Starts the whole adventure over (behind its question), not a case.
        expect(find.text('NEW ADVENTURE'), findsOneWidget);
        expect(find.text('Start a new case'), findsNothing);
        expect(t.getRect(find.text('NEW ADVENTURE')).bottom, lessThan(size.height - 16), reason: 'the group is off the edge');
      }

      await capture(t, 'title_$tag');
      if (scale == 1) {
        // The office a while later: the camera at its deepest, rain on the glass.
        await wait(t, const Duration(seconds: 16));
        expect(t.takeException(), isNull);
        await capture(t, 'title_${tag}_ambient');
      }
    });
  }

  Future<void> pumpTitle(WidgetTester t, {bool still = false}) async {
    t.view.physicalSize = const Size(1080, 1920);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(),
      child: MediaQuery(
        data: MediaQueryData.fromView(t.view).copyWith(disableAnimations: still),
        child: const LondonMysteryApp(),
      ),
    ));
  }

  testWidgets('the button answers at once, while the title is still coming in', (t) async {
    await pumpTitle(t);
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.text('START ADVENTURE'), warnIfMissed: false);
    await wait(t);
    expect(find.text('OPEN THE CASEBOOK'), findsOneWidget, reason: 'registration opened right away');
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('the room comes alive a beat after the title, rests under a dialog, and stops when left', (t) async {
    await pumpTitle(t);
    await wait(t, const Duration(milliseconds: 1500)); // the title is in (about 1 s)
    await t.pump(const Duration(milliseconds: 300));
    expect(t.binding.hasScheduledFrame, isFalse, reason: 'nothing moves yet: the title is simply there');
    await t.pump(const Duration(seconds: 1)); // the ambience starts 2.4 s in
    await t.pump(const Duration(milliseconds: 16));
    expect(t.binding.hasScheduledFrame, isTrue, reason: 'rain, light and camera are running');

    // A grown-up question over the title: the room rests behind it.
    await t.longPress(find.byWidgetPredicate((w) => w is GestureDetector && w.onLongPress != null));
    await t.pumpAndSettle();
    expect(find.textContaining('What is'), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await t.pump(const Duration(milliseconds: 600));
    await t.pump(const Duration(milliseconds: 16));
    expect(t.binding.hasScheduledFrame, isTrue, reason: 'and comes back after it');

    // Leaving the title disposes everything (no ticker left running).
    await t.tap(find.text('START ADVENTURE'));
    await wait(t, const Duration(milliseconds: 800));
    expect(find.text('OPEN THE CASEBOOK'), findsOneWidget);
    await wait(t, const Duration(seconds: 3));
  });

  // Regression: the words and buttons stay above the painting and its rain
  // and lamp light at every moment — entering, after the entrance, with the
  // ambience running, and late in the camera push.
  for (final size in const [Size(360, 640), Size(390, 844)]) {
    testWidgets('the title and buttons stay on top all the way through (${size.width.toInt()}×${size.height.toInt()})', (t) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: saved),
        child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
      ));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));

      final ui = ['THE CASEBOOK OF', 'LONDON', 'MYSTERY', 'Welcome back, Detective MINYOUNG!', 'CONTINUE ADVENTURE', 'NEW ADVENTURE'];
      final painting = find.byWidgetPredicate((w) => w is Image);
      var elapsed = Duration.zero;
      for (final (at, name) in const [
        (Duration(milliseconds: 100), 'enter'),
        (Duration(milliseconds: 1200), 'entered'),
        (Duration(seconds: 5), 'ambient'),
        (Duration(seconds: 12), 'push_late'),
      ]) {
        await wait(t, at - elapsed);
        elapsed = at;
        for (final s in ui) {
          final f = find.text(s);
          expect(f, findsOneWidget, reason: '$s at $name');
          // Painted after (above) the painting and everything that moves with it.
          final text = t.renderObject(f);
          expect(_paintsAfter(text, t.renderObject(painting.first)), isTrue, reason: '$s above the painting at $name');
          for (final p in t.widgetList<CustomPaint>(find.byWidgetPredicate((w) => w is CustomPaint && w.painter != null &&
              (w.painter.runtimeType.toString() == '_RainPainter' || w.painter.runtimeType.toString() == '_LampLightPainter')))) {
            expect(_paintsAfter(text, t.firstRenderObject(find.byWidget(p))), isTrue, reason: '$s above the rain and lamp at $name');
          }
          if (name != 'enter') {
            final opacity = t.widgetList<Opacity>(find.ancestor(of: f, matching: find.byType(Opacity))).fold(1.0, (a, o) => a * o.opacity);
            expect(opacity, 1, reason: '$s fully shown at $name');
          }
        }
        await capture(t, 'title_layers_${name}_${size.width.toInt()}x${size.height.toInt()}');
      }
      await t.tap(find.text('CONTINUE ADVENTURE'));
      await wait(t, const Duration(seconds: 3));
    });
  }

  testWidgets('reduced motion: the title page is complete and still', (t) async {
    await pumpTitle(t, still: true);
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(seconds: 5));
    expect(t.binding.hasScheduledFrame, isFalse, reason: 'no camera, rain or light movement');
    final opacity = t.widgetList<Opacity>(find.ancestor(of: find.text('START ADVENTURE'), matching: find.byType(Opacity)));
    expect(opacity.every((o) => o.opacity == 1), isTrue, reason: 'everything in place, no entrance');
  });
}

Future<void> capture(WidgetTester t, String name) async {
  final shots = Platform.environment['LM_SCREENSHOTS'];
  if (shots == null) return;
  await t.runAsync(() async {
    final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
    final image = await boundary.toImage(pixelRatio: 1.5);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$shots/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

/// Whether [a] is painted after (on top of) [b]: below their nearest common
/// ancestor, the branch holding [a] comes later in paint order.
bool _paintsAfter(RenderObject a, RenderObject b) {
  List<RenderObject> chain(RenderObject r) => [for (RenderObject? x = r; x != null; x = x.parent) x];
  final ca = chain(a), cb = chain(b);
  final common = ca.firstWhere(cb.contains);
  final branchA = ca[ca.indexOf(common) - 1];
  final branchB = cb[cb.indexOf(common) - 1];
  final order = <RenderObject>[];
  common.visitChildren(order.add);
  return order.indexOf(branchA) > order.indexOf(branchB);
}
