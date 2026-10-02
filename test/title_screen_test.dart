import 'dart:math' as math;
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
import 'package:london_mystery/core/theme/app_tokens.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/ink_icon.dart';

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

  for (final (size, scale) in const [(Size(360, 640), 1.0), (Size(390, 844), 1.0), (Size(360, 640), 1.3)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}${scale == 1 ? '' : '_text13'}';

    testWidgets('new player at $tag: title → registration form on the office desk → the casebook', (t) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(),
        child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
      ));
      await wait(t, const Duration(milliseconds: 300));
      await t.tap(find.text('START ADVENTURE'));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600))); // decode the office
      await wait(t);
      expect(t.takeException(), isNull, reason: 'no overflow');
      for (final s in ['LONDON DETECTIVE AGENCY', 'DETECTIVE REGISTRATION', 'What should we call you,\nDetective?', 'Detective Name']) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
      // The office is behind the form, not a plain page.
      expect(
        find.byWidgetPredicate((w) =>
            w is Image &&
            w.image is ResizeImage &&
            ((w.image as ResizeImage).imageProvider as AssetImage).assetName == ArtAssets.titleDetectiveOffice),
        findsOneWidget,
      );
      final paper = t.getRect(find.ancestor(of: find.text('DETECTIVE REGISTRATION'), matching: find.byType(Container)).last);
      expect(paper.left, greaterThan(20), reason: 'the office shows around the form');
      final cta = t.getRect(find.text('OPEN THE CASEBOOK'));
      expect(cta.bottom, lessThan(size.height), reason: 'the button is on screen');
      await capture(t, 'register_$tag');

      // Keyboard up: the name line and the button stay above the keys.
      // The keyboard opens when the name line is tapped (no autofocus).
      await t.tap(find.byType(TextField));
      await t.pump();
      t.view.viewInsets = FakeViewPadding(bottom: size.height * 3 * 0.45);
      addTearDown(t.view.resetViewInsets);
      await wait(t, const Duration(milliseconds: 600));
      expect(t.takeException(), isNull, reason: 'no overflow with the keyboard');
      for (final f in [find.byType(TextField), find.text('OPEN THE CASEBOOK')]) {
        expect(t.getRect(f).bottom, lessThanOrEqualTo(size.height * 0.55 + 1), reason: '$f above the keys');
      }
      await capture(t, 'register_${tag}_keyboard');

      await t.enterText(find.byType(TextField), 'kim');
      await t.tap(find.text('OPEN THE CASEBOOK'));
      t.view.resetViewInsets(); // the keyboard goes with the name field
      await wait(t, const Duration(milliseconds: 1500));
      expect(find.text('BEGIN SEASON ONE'), findsOneWidget, reason: 'on to the season, as before');
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('returning player at $tag: NEW ADVENTURE asks on a paper laid over the office', (t) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: saved),
        child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
      ));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await wait(t, const Duration(milliseconds: 1200));

      await t.tap(find.text('NEW ADVENTURE'));
      await wait(t, const Duration(milliseconds: 500));
      expect(t.takeException(), isNull);
      expect(find.text('Start a New Adventure?'), findsOneWidget);
      expect(find.text('START NEW ADVENTURE'), findsOneWidget);
      expect(find.text('Keep playing'), findsOneWidget);
      // One word for it: an adventure, never "a new case".
      expect(find.textContaining(RegExp('new case', caseSensitive: false)), findsNothing);
      // The office is still there under a translucent shade.
      final barrier = t.widgetList<ModalBarrier>(find.byType(ModalBarrier)).last;
      expect(barrier.color!.a, inInclusiveRange(0.3, 0.7), reason: 'the scene stays in view');
      await capture(t, 'new_adventure_$tag');

      await t.tap(find.text('Keep playing'));
      await wait(t, const Duration(milliseconds: 500));
      expect(find.text('Start a New Adventure?'), findsNothing);
      expect(find.text('Welcome back, Detective MINYOUNG!'), findsOneWidget, reason: 'nothing cleared');

      await t.tap(find.text('NEW ADVENTURE'));
      await wait(t, const Duration(milliseconds: 500));
      await t.tap(find.text('START NEW ADVENTURE'));
      await wait(t, const Duration(milliseconds: 1500));
      expect(find.text('What should we call you,\nDetective?'), findsOneWidget, reason: 'the reset leads to registration, as before');
      await wait(t, const Duration(seconds: 3));
    });
  }

  for (final (size, scale) in const [(Size(360, 640), 1.0), (Size(390, 844), 1.0), (Size(360, 640), 1.3), (Size(390, 844), 1.3)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}${scale == 1 ? '' : '_text13'}';
    testWidgets('registration at $tag: no focus on arrival, the name centred under its label, tap away to close', (t) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(),
        child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
      ));
      await wait(t, const Duration(milliseconds: 300));
      await t.tap(find.text('START ADVENTURE'));
      await wait(t);

      final field = find.byType(EditableText);
      bool focused() => t.widget<EditableText>(field).focusNode.hasFocus;
      // 1. Arrival: no focus, no keyboard.
      expect(focused(), isFalse, reason: 'no autofocus');
      expect(t.testTextInput.isVisible, isFalse, reason: 'no keyboard on arrival');

      // The writing space is centred under the label, the hint and a real name alike.
      // Where the letters themselves are (a text's box can be wider than its
      // letters, and the floating label is drawn through a transform).
      double inkX(RenderParagraph p) {
        final text = p.text.toPlainText();
        final boxes = p.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: text.length));
        final left = boxes.map((b) => b.left).reduce(math.min), right = boxes.map((b) => b.right).reduce(math.max);
        final y = boxes.first.toRect().center.dy;
        return (p.localToGlobal(Offset(left, y)).dx + p.localToGlobal(Offset(right, y)).dx) / 2;
      }

      final labelX = inkX(t.renderObject<RenderParagraph>(find.text('Detective Name')));
      final paper = t.getRect(find.ancestor(of: find.text('DETECTIVE REGISTRATION'), matching: find.byType(Container)).last);
      expect(labelX, closeTo(paper.center.dx, 1.5), reason: 'the label is in the middle of the form');
      expect(inkX(t.renderObject<RenderParagraph>(find.text('SHERLOCK'))), closeTo(labelX, 1.5), reason: 'the hint under the label');
      expect(t.renderObject<RenderParagraph>(find.text('SHERLOCK')).didExceedMaxLines, isFalse, reason: 'the hint is whole');
      double typedX() {
        final editable = t.state<EditableTextState>(field).renderEditable;
        final text = editable.text!.toPlainText();
        final boxes = editable.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: text.length));
        final left = boxes.map((b) => b.left).reduce(math.min), right = boxes.map((b) => b.right).reduce(math.max);
        return editable.localToGlobal(Offset((left + right) / 2, 0)).dx;
      }

      // 2–3. Tap the line: focus, keyboard; a short name, then the longest, both centred.
      await t.tap(find.text('SHERLOCK'));
      await t.pump();
      expect(focused(), isTrue);
      expect(t.testTextInput.isVisible, isTrue, reason: 'the keyboard comes when asked');
      for (final name in ['OO', 'ABCDEFGHIJKL']) {
        await t.enterText(field, name);
        await t.pump();
        expect(typedX(), closeTo(labelX, 1.5), reason: '"$name" centred under the label');
      }
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600))); // decode the office
      await t.pump();
      await capture(t, 'register_typing_$tag');

      // 4. A blank part of the form: pen down, name kept.
      final blank = t.getRect(find.text('DETECTIVE REGISTRATION'));
      await t.tapAt(Offset(paper.left + 12, blank.center.dy));
      await t.pump();
      expect(focused(), isFalse, reason: 'tap on the form closes the keyboard');
      expect(t.widget<EditableText>(field).controller.text, 'ABCDEFGHIJKL', reason: 'the name stays');

      // 5. The office around the form (after focusing again).
      await t.tap(field);
      await t.pump();
      expect(focused(), isTrue, reason: '6. back to the line, name kept');
      expect(t.widget<EditableText>(field).controller.text, 'ABCDEFGHIJKL');
      await t.tapAt(Offset(paper.left / 2, paper.center.dy));
      await t.pump();
      expect(focused(), isFalse, reason: 'tap on the office closes the keyboard');

      // 7. The pen opens the line too.
      await t.tap(find.byWidgetPredicate((w) => w is InkIcon && w.glyph == InkGlyph.pen));
      await t.pump();
      expect(focused(), isTrue, reason: 'the pen is part of the line');

      // 8. The button still works while the keyboard is up: validation as before.
      await t.enterText(field, '');
      await t.tap(find.text('OPEN THE CASEBOOK'));
      await wait(t, const Duration(milliseconds: 600));
      expect(find.text('Please type your detective name.'), findsOneWidget, reason: 'validation, as before');
      // Under the line on the left, as before — not centred like the name.
      expect(t.getRect(find.text('Please type your detective name.')).left, lessThan(paper.left + AppSpace.xxl),
          reason: 'the message starts at the left of the line');
      expect(find.text('0/12'), findsOneWidget, reason: 'the counter, as before');
      expect(t.takeException(), isNull);
      await capture(t, 'register_validation_$tag');

      // 9. Back to the title, as before.
      await t.tap(find.byTooltip('Back'));
      await wait(t, const Duration(milliseconds: 800));
      expect(find.text('START ADVENTURE'), findsOneWidget);
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
