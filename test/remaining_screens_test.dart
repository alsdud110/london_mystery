import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/core/theme/app_colors.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/widgets/game_button.dart';
import 'package:world_mystery/widgets/ink_icon.dart';
import 'package:world_mystery/widgets/paper_background.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'parent_gate_test.dart' show gateAnswer;
import 'title_screen_test.dart' show capture;

/// The last screens of the UI audit in the game's language: the evidence
/// close-up, the absent scanner page, the parent gate, the parent report and the
/// game master tools — their functions as before.
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
          return const WorldMysteryApp();
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

    // The QR scanner page is gone (2026-10-19): Case 01 M5's crown card is
    // examined in its own scene, on this device alone, with no camera.
    testWidgets('no scanner page $tag: the app has no camera route, the map opens as before', (t) async {
      final ref = await pumpApp(t, size, GameProgress(detectiveName: 'KIM', introSeen: true, startedAt: DateTime(2026, 9, 29)));
      ref.read(routerProvider).go(Routes.map);
      await wait(t, const Duration(milliseconds: 1000));
      expect(t.takeException(), isNull);
      expect(pathOf(ref), Routes.map);
      final paths = <String>[];
      void collect(List<RouteBase> routes) {
        for (final r in routes) {
          if (r is GoRoute) paths.add(r.path);
          collect(r.routes);
        }
      }
      collect(ref.read(routerProvider).configuration.routes);
      expect(paths, isNot(contains('/scan')));
      expect(find.text('No camera here'), findsNothing);
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
      // Each figure on one line in its column (TYPE B: a play record, no
      // accuracy or skill scores). This case was solved without a play
      // record, so its figures say so instead of showing zeros.
      await t.scrollUntilVisible(find.text('Play Time'), 300, scrollable: find.byType(Scrollable).last);
      for (final s in ['Missions', 'Hints Opened', 'First Try', 'Play Time']) {
        expect(find.text(s), findsOneWidget);
      }
      expect(find.text('Accuracy'), findsNothing);
      expect(find.text('기록 없음'), findsWidgets);
      expect(t.takeException(), isNull);
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
      // No QR card to print or place on site any more (Case 01 M5 is played
      // on the device), and the page says so.
      expect(find.text('LM-EP01-PALACE'), findsNothing);
      expect(find.textContaining('현장에 따로 준비할 카드는 없습니다'), findsOneWidget);
      await capture(t, 'game_master_$tag');
      await t.tap(find.byTooltip('Back'));
      await wait(t, const Duration(milliseconds: 800));
      expect(find.text('GAME MASTER'), findsNothing);
      expect(pathOf(ref), Routes.start);
    });
  }
}
