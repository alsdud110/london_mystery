import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/widgets/letter_card.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// The mission's letter again, and the final case's notebook: paper sheets
/// (nearly square corners, an ink tab, no grey handle), content as before,
/// closing as before.
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

  void expectPaperShell(WidgetTester t) {
    final sheet = t.widget<BottomSheet>(find.byType(BottomSheet));
    expect((sheet.shape! as RoundedRectangleBorder).borderRadius, const BorderRadius.vertical(top: Radius.circular(4)));
    expect(sheet.showDragHandle, isFalse, reason: 'the ink tab instead of the grey handle');
  }

  Future<GoRouterLike> pumpApp(WidgetTester t, Size size, GameProgress progress) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(prefs: {AppConstants.progressStorageKey: jsonEncode(progress.toJson())}),
      child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
    ));
    await wait(t, const Duration(milliseconds: 300));
    return GoRouterLike(ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first).read(routerProvider).go);
  }

  /// The three ways a sheet closes, each after [open] brings it up again.
  Future<void> closesThreeWays(WidgetTester t, Future<void> Function() open, Finder dragFrom) async {
    for (final (name, close) in <(String, Future<void> Function())>[
      ('tap outside', () => t.tapAt(Offset(t.view.physicalSize.width / t.view.devicePixelRatio / 2, 70))),
      ('back', () => t.binding.handlePopRoute()),
      ('swipe down', () => t.drag(dragFrom, const Offset(0, 700))),
    ]) {
      await open();
      await close();
      await wait(t, const Duration(milliseconds: 700));
      expect(find.byType(BottomSheet), findsNothing, reason: name);
    }
  }

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('mission letter $tag: the paper sheet, the letter as before, a word, BACK TO THE PUZZLE', (t) async {
      final go = await pumpApp(t, size, GameProgress(
        detectiveName: 'MINYOUNG',
        introSeen: true,
        startedAt: DateTime(2026, 9, 29, 10),
        missionStartedAt: {'m01': DateTime(2026, 9, 29, 10)}, // back on the puzzle
        playMillis: 0,
      ));
      go.go(Routes.mission('m01'));
      await wait(t, const Duration(milliseconds: 1200));
      expect(find.text('Get a tip'), findsOneWidget, reason: 'on the puzzle');

      Future<void> open() async {
        await t.tap(find.text('Letter'));
        await wait(t, const Duration(milliseconds: 700));
        expect(find.byType(LetterCard), findsOneWidget);
      }

      await open();
      expect(t.takeException(), isNull);
      expectPaperShell(t);
      await capture(t, 'letter_sheet_$tag');
      // A word in the letter still opens its card, over the letter.
      await t.tapOnText(find.textRange.ofSubstring('museum').first);
      await wait(t, const Duration(milliseconds: 600));
      expect(find.text('WORD CARD'), findsOneWidget);
      await t.tap(find.text('GOT IT!'));
      await wait(t, const Duration(milliseconds: 600));
      expect(find.byType(LetterCard), findsOneWidget, reason: 'back on the letter');
      await t.tap(find.text('BACK TO THE PUZZLE'));
      await wait(t, const Duration(milliseconds: 700));
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Get a tip'), findsOneWidget, reason: 'back on the puzzle');

      await closesThreeWays(t, open, find.byType(LetterCard));
    });

    testWidgets('final letter $tag: the paper sheet, the letter as before, a word, BACK TO THE LOCKS', (t) async {
      final go = await pumpApp(t, size, GameProgress(
        detectiveName: 'MINYOUNG',
        introSeen: true,
        completedMissionIds: [for (final m in episode01.missions) m.id],
        startedAt: DateTime(2026, 9, 29, 10),
        playMillis: 0,
      ));
      go.go(Routes.finalMission);
      await wait(t, const Duration(milliseconds: 1200));

      Future<void> open() async {
        final button = find.text('Letter');
        await t.scrollUntilVisible(button, 300, scrollable: find.byType(Scrollable).first);
        await wait(t, const Duration(milliseconds: 300));
        await t.tap(button);
        await wait(t, const Duration(milliseconds: 700));
        expect(find.text('BACK TO THE LOCKS'), findsOneWidget);
      }

      await open();
      expect(t.takeException(), isNull);
      expectPaperShell(t);
      await capture(t, 'final_letter_$tag');
      // A word in the letter still opens its card, over the letter.
      final sheetLetter = find.descendant(of: find.byType(BottomSheet), matching: find.byType(LetterCard));
      await t.tapOnText(find.textRange.ofSubstring('locks').last);
      await wait(t, const Duration(milliseconds: 600));
      expect(find.text('WORD CARD'), findsOneWidget);
      await t.tap(find.text('GOT IT!'));
      await wait(t, const Duration(milliseconds: 600));
      expect(sheetLetter, findsOneWidget, reason: 'back on the letter');
      await t.tap(find.text('BACK TO THE LOCKS'));
      await wait(t, const Duration(milliseconds: 700));
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('OPEN THE BOX'), findsOneWidget, reason: 'back at the locks');

      await closesThreeWays(t, open, find.text('BACK TO THE LOCKS'));
    });

    testWidgets('final notebook $tag: the paper sheet, evidence and clues as before, scrolling, closing', (t) async {
      final go = await pumpApp(t, size, GameProgress(
        detectiveName: 'MINYOUNG',
        introSeen: true,
        completedMissionIds: [for (final m in episode01.missions) m.id],
        startedAt: DateTime(2026, 9, 29, 10),
        playMillis: 0,
      ));
      go.go(Routes.finalMission);
      await wait(t, const Duration(milliseconds: 1200));

      Future<void> open() async {
        final button = find.text('OPEN MY NOTEBOOK');
        await t.scrollUntilVisible(button, 300, scrollable: find.byType(Scrollable).first);
        await wait(t, const Duration(milliseconds: 300));
        await t.tap(button);
        await wait(t, const Duration(milliseconds: 700));
        expect(find.text('DETECTIVE NOTEBOOK'), findsOneWidget);
      }

      await open();
      expect(t.takeException(), isNull);
      expectPaperShell(t);
      expect(find.text('Evidence'), findsOneWidget);
      await capture(t, 'final_notebook_$tag');
      // The notebook scrolls to its clues, the tab stays at the top.
      final tabTop = t.getRect(find.text('DETECTIVE NOTEBOOK')).top;
      await t.scrollUntilVisible(find.text('Clues'), 300, scrollable: find.byType(Scrollable).last);
      await wait(t, const Duration(milliseconds: 300));
      expect(find.text('Clues'), findsOneWidget);
      final title = find.text('DETECTIVE NOTEBOOK');
      expect(title.evaluate().isEmpty || t.getRect(title).top < tabTop, isTrue, reason: 'the notebook scrolled');
      await capture(t, 'final_notebook_clues_$tag');
      // Scrolled, the sheet has grown to the full screen (as before): back closes it.
      await t.binding.handlePopRoute();
      await wait(t, const Duration(milliseconds: 700));

      await closesThreeWays(t, open, find.text('DETECTIVE NOTEBOOK'));
    });
  }
}

/// Just the router's `go`, for the tests above.
class GoRouterLike {
  GoRouterLike(this.go);
  final void Function(String location, {Object? extra}) go;
}
