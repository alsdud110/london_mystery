import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mission_play.dart';
import 'title_screen_test.dart' show capture;

/// Before/after sample shots of the three searched places (temporary).
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

  for (final id in ['m01', 'm03', 'ep03_m1']) {
    for (final size in const [Size(390, 844), Size(430, 932), Size(360, 640), Size(412, 915)]) {
      testWidgets('$id ${size.width.toInt()}x${size.height.toInt()}', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, id);
        final context = t.element(find.byType(Scaffold).first);
        await t.runAsync(() async {
          for (final i in t.widgetList<Image>(find.byType(Image))) {
            await precacheImage(i.image, context);
          }
          await Future<void>.delayed(const Duration(milliseconds: 400));
        });
        await t.pump(const Duration(milliseconds: 100));
        await capture(t, '${id}_${size.width.toInt()}x${size.height.toInt()}');
        expect(Platform.environment['LM_SCREENSHOTS'], isNotNull);
      });
    }
  }
}
