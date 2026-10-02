import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/core/theme/app_colors.dart';
import 'package:london_mystery/data/models/game_progress.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// The map's menu: a page of the casebook over the map — same content,
/// order and actions; closes by swipe, a tap outside or back.
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

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('map menu $tag: paper page, same items, closes three ways, items still go where they went', (t) async {
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
      final router = ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first).read(routerProvider);
      router.go(Routes.map);
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await wait(t, const Duration(milliseconds: 1200));

      Future<void> open() async {
        await t.tap(find.byTooltip('Menu'));
        await wait(t, const Duration(milliseconds: 600));
        expect(find.text('Detective MINYOUNG'), findsOneWidget);
      }

      await open();
      expect(t.takeException(), isNull);
      // The paper of the case files, nearly square corners, no grey handle.
      final sheet = t.widget<BottomSheet>(find.byType(BottomSheet));
      expect(sheet.backgroundColor, AppColors.paper);
      expect((sheet.shape! as RoundedRectangleBorder).borderRadius, const BorderRadius.vertical(top: Radius.circular(4)));
      expect(sheet.showDragHandle, isFalse);
      // Same content, same order.
      final labels = ['The Missing Crown', 'Detective MINYOUNG', 'Sound effects', 'Detective Notebook', 'Season board', 'Case files', 'Title screen'];
      final tops = [for (final l in labels) t.getRect(find.descendant(of: find.byType(BottomSheet), matching: find.text(l))).top];
      expect(tops, [...tops]..sort(), reason: 'in the same order');
      // The sound switch still switches.
      final before = t.widget<Switch>(find.byType(Switch)).value;
      await t.tap(find.text('Sound effects'));
      await wait(t, const Duration(milliseconds: 300));
      expect(t.widget<Switch>(find.byType(Switch)).value, !before);
      await capture(t, 'map_menu_$tag');

      // Closes: a tap outside, back, and a swipe down.
      await t.tapAt(const Offset(20, 20));
      await wait(t, const Duration(milliseconds: 600));
      expect(find.byType(BottomSheet), findsNothing, reason: 'tap outside');
      await open();
      await t.binding.handlePopRoute();
      await wait(t, const Duration(milliseconds: 600));
      expect(find.byType(BottomSheet), findsNothing, reason: 'back');
      await open();
      await t.drag(find.text('Detective MINYOUNG'), const Offset(0, 500));
      await wait(t, const Duration(milliseconds: 600));
      expect(find.byType(BottomSheet), findsNothing, reason: 'swipe down');

      // The notebook opens over the map (pushed, as before).
      await open();
      await t.tap(find.text('Detective Notebook'));
      await wait(t, const Duration(milliseconds: 1200));
      expect(find.text('DETECTIVE NOTEBOOK'), findsOneWidget);

      // Where each other item goes, as before.
      for (final (label, path) in const [

        ('Season board', Routes.season),
        ('Case files', Routes.episodes),
        ('Title screen', Routes.start),
      ]) {
        router.go(Routes.map);
        await wait(t, const Duration(milliseconds: 1200));
        await open();
        await t.tap(find.text(label));
        await wait(t, const Duration(milliseconds: 1200));
        expect(router.routerDelegate.currentConfiguration.uri.path, path, reason: label);
      }
      await wait(t, const Duration(seconds: 3));
    });
  }
}
