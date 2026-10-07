import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/theme/app_theme.dart';
import 'package:london_mystery/features/mission/widgets/answer_feedback.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// "Not quite!" as a paper slip: nearly square corners, an ink tab instead
/// of the grey handle, its content and buttons as before; closes as before.
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

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('not quite slip $tag: the shell, the content, TRY AGAIN, GET A TIP, and closing', (t) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      late BuildContext context;
      await t.pumpWidget(
        ProviderScope(
          // The buttons play their tap sound through the app's providers.
          overrides: await testOverrides(),
          child: RepaintBoundary(
            key: const ValueKey('shot'),
            child: MaterialApp(
              theme: AppTheme.light(),
              home: Builder(
                builder: (c) {
                  context = c;
                  return const Scaffold(body: Center(child: Text('The puzzle')));
                },
              ),
            ),
          ),
        ),
      );

      // Shows the slip and lets it slide up. The choice is recorded when the
      // slip closes (never awaited: a slip left open fails, it does not hang).
      final results = <TryAgainChoice>[];
      Future<void> open() async {
        showTryAgainSheet(context, hintAvailable: true).then(results.add);
        await wait(t, const Duration(milliseconds: 600));
      }

      await open();
      expect(t.takeException(), isNull, reason: 'no overflow');
      final sheet = t.widget<BottomSheet>(find.byType(BottomSheet));
      expect(
        (sheet.shape! as RoundedRectangleBorder).borderRadius,
        const BorderRadius.vertical(top: Radius.circular(4)),
      );
      expect(sheet.showDragHandle, isFalse, reason: 'the ink tab instead of the grey handle');
      for (final s in ['Not quite!', 'TRY AGAIN', 'GET A TIP']) {
        expect(find.text(s), findsOneWidget);
        expect(t.getRect(find.text(s)).bottom, lessThan(size.height), reason: '$s on screen');
      }
      await capture(t, 'not_quite_$tag');

      await t.tap(find.text('TRY AGAIN'));
      await wait(t, const Duration(milliseconds: 600));
      expect(results, [TryAgainChoice.retry]);

      await open();
      await t.tap(find.text('GET A TIP'));
      await wait(t, const Duration(milliseconds: 600));
      expect(results.last, TryAgainChoice.hint);

      // Closes as before: a tap outside, back, a swipe down (no choice: try again).
      for (final (name, close) in <(String, Future<void> Function())>[
        ('tap outside', () => t.tapAt(const Offset(20, 20))),
        ('back', () => t.binding.handlePopRoute()),
        ('swipe down', () => t.drag(find.text('Not quite!'), const Offset(0, 600))),
      ]) {
        final before = results.length;
        await open();
        await close();
        await wait(t, const Duration(milliseconds: 600));
        expect(find.byType(BottomSheet), findsNothing, reason: name);
        expect(results.length, before + 1, reason: '$name closes it');
        expect(results.last, TryAgainChoice.retry, reason: name);
      }
    });
  }
}
