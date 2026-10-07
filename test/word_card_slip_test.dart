import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/game_progress.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// The word card as a small reference card: nearly square corners, an ink
/// tab instead of the grey handle; its content and GOT IT! as before.
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
    testWidgets('word card $tag: tap a word on the mission page, the card, GOT IT!, and closing', (t) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: {
          AppConstants.progressStorageKey: jsonEncode(GameProgress(
            detectiveName: 'MINYOUNG',
            introSeen: true,
            startedAt: DateTime(2026, 9, 29, 10),
            playMillis: 0,
          ).toJson()),
        }),
        child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
      ));
      await wait(t, const Duration(milliseconds: 300));
      ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first).read(routerProvider).go(Routes.mission('m01'));
      await wait(t, const Duration(milliseconds: 1200));

      Future<void> tapWord(String word) async {
        await t.tapOnText(find.textRange.ofSubstring(word).first);
        await wait(t, const Duration(milliseconds: 600));
        expect(find.text('WORD CARD'), findsOneWidget, reason: word);
      }

      // Two different words, each its own card.
      for (final word in ['Platform', 'suitcase']) {
        await tapWord(word);
        expect(t.takeException(), isNull);
        final sheet = t.widget<BottomSheet>(find.byType(BottomSheet));
        expect((sheet.shape! as RoundedRectangleBorder).borderRadius, const BorderRadius.vertical(top: Radius.circular(4)));
        expect(sheet.showDragHandle, isFalse, reason: 'the ink tab instead of the grey handle');
        expect(find.textContaining('= '), findsOneWidget, reason: 'its meaning');
        expect(t.getRect(find.text('GOT IT!')).bottom, lessThan(size.height));
        await capture(t, 'word_card_${word.toLowerCase()}_$tag');
        await t.tap(find.text('GOT IT!'));
        await wait(t, const Duration(milliseconds: 600));
        expect(find.text('WORD CARD'), findsNothing, reason: 'GOT IT! closes it');
      }

      // Closes as before: a tap outside, back, a swipe down.
      for (final (name, close) in <(String, Future<void> Function())>[
        ('tap outside', () => t.tapAt(const Offset(20, 20))),
        ('back', () => t.binding.handlePopRoute()),
        ('swipe down', () => t.drag(find.text('WORD CARD'), const Offset(0, 500))),
      ]) {
        await tapWord('Platform');
        await close();
        await wait(t, const Duration(milliseconds: 600));
        expect(find.text('WORD CARD'), findsNothing, reason: name);
      }
      expect(find.text('INVESTIGATE'), findsOneWidget, reason: 'still on the mission page');
    });
  }
}
