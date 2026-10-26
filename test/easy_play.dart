import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/data/models/easy_steps.dart';

import 'full_playthrough_test.dart' show reveal, wait;
import 'helpers.dart' show findReadable;

/// The game's own fonts, so text sizes (and any overflow) match a device.
Future<void> loadGameFonts() async {
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
}

/// Every word a very-easy puzzle says or shows: its title, each step's
/// words, hints, answers and help, and what its panels have written on them.
String easyWords(EasyStepsScene scene) => [
      scene.title,
      for (final s in scene.steps) ...[
        s.say,
        ?s.question,
        ?s.done,
        ?s.tell,
        s.wrong,
        ...s.hints,
        for (final o in s.options) ...[?o.label, ?o.feedback],
        for (final p in [...s.panels, ...?s.after, for (final o in s.options) ?o.panel]) ...[
          ?p.caption,
          if (p is PaperPanel) ...[p.title, for (final l in p.lines) l.text],
          if (p is PicturePanel) for (final w in p.writing) w.text,
        ],
      ],
    ].join('\n');

/// Playing Cases 11–12 as a child does, in widget tests: the talks line by
/// line, the steps tapped where they are lit. `LM_SHOTS=folder` saves a
/// picture of each moment.
class EasyPlay {
  EasyPlay(this.t, this.tag);

  final WidgetTester t;
  final String tag;
  int _n = 0;

  static final shots = Platform.environment['LM_SHOTS'];

  /// No overflow, no error; a picture saved when asked for.
  Future<void> shot(String name) async {
    expect(t.takeException(), isNull, reason: '$tag $name: no overflow, no error');
    if (shots == null) return;
    await t.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await t.pump();
    await t.runAsync(() async {
      final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
      final image = await boundary.toImage(pixelRatio: 1);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/easy_${tag}_${(_n++).toString().padLeft(2, '0')}_$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<void> tapKey(String key, {Duration after = const Duration(milliseconds: 500)}) async {
    final f = find.byKey(ValueKey(key));
    expect(f, findsOneWidget, reason: '$tag: $key');
    await reveal(t, f);
    await t.tap(f, warnIfMissed: false);
    await wait(t, after);
  }

  /// Through a talk to its end: every line (NEXT), the questions in [ask]
  /// (in order, as they come), the cards in [show]; then its way on.
  Future<void> talk({List<String> ask = const [], List<String> show = const [], String? shotAt}) async {
    final asks = [...ask];
    final shows = [...show];
    for (var i = 0; i < 200; i++) {
      if (find.byKey(const ValueKey('case-talk-next')).evaluate().isNotEmpty) {
        await t.tap(find.byKey(const ValueKey('case-talk-next')));
        await wait(t, const Duration(milliseconds: 250));
        continue;
      }
      if (shows.isNotEmpty && find.byKey(ValueKey('case-talk-choice-${shows.first}')).evaluate().isNotEmpty) {
        if (shotAt != null && shows.length == show.length) await shot(shotAt);
        await t.tap(find.byKey(ValueKey('case-talk-choice-${shows.removeAt(0)}')));
        await wait(t, const Duration(milliseconds: 400));
        continue;
      }
      if (asks.isNotEmpty && find.byKey(ValueKey('case-talk-q-${asks.first}')).evaluate().isNotEmpty) {
        await t.tap(find.byKey(ValueKey('case-talk-q-${asks.removeAt(0)}')));
        await wait(t, const Duration(milliseconds: 400));
        continue;
      }
      if (asks.isEmpty && shows.isEmpty && find.byKey(const ValueKey('case-talk-finish')).evaluate().isNotEmpty) {
        await reveal(t, find.byKey(const ValueKey('case-talk-finish')));
        await t.tap(find.byKey(const ValueKey('case-talk-finish')));
        await wait(t, const Duration(milliseconds: 900));
        return;
      }
      await wait(t, const Duration(milliseconds: 200));
    }
    fail('$tag: the talk did not end (left to ask $asks, to show $shows)');
  }

  /// The place [area] (pixels of [picture]) on panel [panel], tapped.
  Future<void> tapOn(String panel, EasyPicture picture, Rect? area, {Duration after = const Duration(milliseconds: 600)}) async {
    final r = t.getRect(find.byKey(ValueKey('easy-panel-$panel')));
    final view = picture.view;
    final at = area?.center ?? view.center;
    final s = r.width / view.width;
    await t.tapAt(r.topLeft + (at - view.topLeft) * s);
    await wait(t, after);
  }

  /// The size on screen of [area] (pixels of [picture]) on panel [panel].
  Size sizeOn(String panel, EasyPicture picture, Rect area) {
    final r = t.getRect(find.byKey(ValueKey('easy-panel-$panel')));
    final s = r.width / picture.view.width;
    return area.size * s;
  }

  /// The step on screen says [say].
  void expectSay(String say) => expect(findReadable(say), findsWidgets, reason: '$tag: "$say"');

  /// The way on from a done step, or a step's own button.
  Future<void> next({Duration after = const Duration(milliseconds: 700)}) async {
    await tapKey('easy-next', after: after);
  }
}
