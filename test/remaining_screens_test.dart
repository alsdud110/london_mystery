import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/core/theme/app_colors.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/widgets/game_button.dart';
import 'package:london_mystery/widgets/ink_icon.dart';
import 'package:london_mystery/widgets/paper_background.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'parent_gate_test.dart' show gateAnswer;
import 'title_screen_test.dart' show capture;

/// The last screens of the UI audit in the game's language: the evidence
/// close-up, the QR scanner, the parent gate, the parent report and the
/// game master tools — their functions as before.
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

  GameProgress solved() => GameProgress(
        detectiveName: 'ALEXANDRINA',
        introSeen: true,
        completedMissionIds: [for (final m in episode01.allMissions) m.id],
        startedAt: DateTime(2026, 9, 29, 10),
        completedAt: DateTime(2026, 9, 29, 10, 30),
        playMillis: 0,
      );

  Future<WidgetRef> pumpApp(WidgetTester t, Size size, GameProgress progress) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    late WidgetRef ref;
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(prefs: {AppConstants.progressStorageKey: jsonEncode(progress.toJson())}),
      child: RepaintBoundary(
        key: const ValueKey('shot'),
        child: Consumer(builder: (context, r, _) {
          ref = r;
          return const LondonMysteryApp();
        }),
      ),
    ));
    await wait(t, const Duration(milliseconds: 300));
    return ref;
  }

  String pathOf(WidgetRef ref) => ref.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('evidence close-up $tag: CLOSE is the glass button, and closes', (t) async {
      final ref = await pumpApp(t, size, solved());
      ref.read(routerProvider).go(Routes.notebook);
      await wait(t, const Duration(milliseconds: 1200));
      await t.tap(find.text('EVIDENCE'));
      await wait(t, const Duration(milliseconds: 800));
      await t.tap(find.text('Golden Key'));
      await wait(t, const Duration(milliseconds: 800));
      final close = find.ancestor(of: find.text('CLOSE'), matching: find.byType(GameButton));
      await t.ensureVisible(close);
      await wait(t, const Duration(milliseconds: 300));
      expect(t.widget<GameButton>(close).style, GameButtonStyle.glass);
      await capture(t, 'evidence_zoom_$tag');
      await t.tap(find.text('CLOSE'));
      await wait(t, const Duration(milliseconds: 600));
      expect(find.text('CLOSE'), findsNothing);
    });

    testWidgets('qr scanner $tag (no camera): gold ink, GO BACK is the glass button, and goes back', (t) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows; // a device without a camera
      try {
        final ref = await pumpApp(t, size, GameProgress(detectiveName: 'KIM', introSeen: true, startedAt: DateTime(2026, 9, 29)));
        ref.read(routerProvider).go(Routes.map);
        await wait(t, const Duration(milliseconds: 1000));
        ref.read(routerProvider).push(Routes.qrScanner);
        await wait(t, const Duration(milliseconds: 1000));
        expect(t.takeException(), isNull);
        expect(find.text('No camera here'), findsOneWidget);
        final back = find.ancestor(of: find.text('GO BACK'), matching: find.byType(GameButton));
        expect(t.widget<GameButton>(back).style, GameButtonStyle.glass);
        final white = t.widgetList<Text>(find.byType(Text)).where((w) => w.style?.color == Colors.white);
        expect(white, isEmpty, reason: 'ink from the palette, not plain white');
        await capture(t, 'qr_no_camera_$tag');
        await t.tap(find.text('GO BACK'));
        await wait(t, const Duration(milliseconds: 800));
        expect(pathOf(ref), Routes.map);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('parent gate and report $tag: the scene under a navy shade; the report, name whole', (t) async {
      final ref = await pumpApp(t, size, solved());
      ref.read(routerProvider).go(Routes.solved);
      await wait(t, const Duration(milliseconds: 3200));
      final report = find.text('VIEW MY DETECTIVE REPORT');
      await t.scrollUntilVisible(report, 300, scrollable: find.byType(Scrollable).first);
      await wait(t, const Duration(milliseconds: 300));
      await t.tap(report);
      await wait(t, const Duration(milliseconds: 600));
      expect(find.text('For grown-ups'), findsOneWidget);
      final barrier = t.widgetList<ModalBarrier>(find.byType(ModalBarrier)).last;
      expect(barrier.color, AppColors.navyDeep.withValues(alpha: 0.55), reason: 'the scene stays in view');
      await capture(t, 'parent_gate_$tag');
      await t.enterText(find.byType(TextField), gateAnswer(t));
      await t.tap(find.text('OK'));
      await wait(t, const Duration(milliseconds: 1200));
      expect(find.text('DETECTIVE REPORT'), findsOneWidget, reason: 'the report opens (pushed over the case file)');
      expect(t.takeException(), isNull);
      // The name, whole on one line (shrunk if it must), not cut with "…".
      final name = t.renderObject<RenderParagraph>(find.text('ALEXANDRINA'));
      expect(name.didExceedMaxLines, isFalse);
      // Each figure on one line in its column.
      for (final s in ['Accuracy', 'Completion Time', 'Words Checked']) {
        expect(find.text(s), findsOneWidget);
      }
      await capture(t, 'parent_report_$tag');
    });

    testWidgets('game master $tag: the casebook paper, the ink back arrow, no Material card', (t) async {
      final ref = await pumpApp(t, size, GameProgress(detectiveName: 'KIM'));
      ref.read(gameMasterAccessProvider.notifier).grant();
      ref.read(routerProvider).push(Routes.gameMaster);
      await wait(t, const Duration(milliseconds: 1000));
      expect(t.takeException(), isNull);
      expect(find.text('GAME MASTER'), findsOneWidget);
      expect(find.byType(PaperBackground), findsWidgets);
      expect(find.byType(Card), findsNothing);
      expect(find.byType(BackButton), findsNothing);
      expect(find.byWidgetPredicate((w) => w is InkIcon && w.glyph == InkGlyph.back), findsOneWidget);
      expect(find.text('LM-EP01-PALACE'), findsOneWidget, reason: 'the QR card, as before');
      await capture(t, 'game_master_$tag');
      await t.tap(find.byTooltip('Back'));
      await wait(t, const Duration(milliseconds: 800));
      expect(find.text('GAME MASTER'), findsNothing);
      expect(pathOf(ref), Routes.start);
    });
  }
}
