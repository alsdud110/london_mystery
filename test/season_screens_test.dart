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
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';

/// Opens every screen of every case at a small phone size and fails on any
/// layout error (overflow, clipping exceptions). Set LM_SCREENSHOTS to a
/// folder to also save a picture of each screen for visual review.
void main() {
  final season = MockEpisodeRepository.bundled();
  final shots = Platform.environment['LM_SCREENSHOTS'];

  setUpAll(() async {
    // Real fonts, so text sizes (and any overflow) match the device.
    for (final (family, files) in [
      ('Nunito', ['Nunito.ttf']),
      ('Cinzel', ['Cinzel.ttf']),
      ('LibreBaskerville', ['LibreBaskerville.ttf', 'LibreBaskerville-Italic.ttf']),
      ('Fredoka', ['Fredoka.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await loader.load();
    }
  });

  /// Everything before [e] solved; in [e], the missions before [upTo] solved.
  Map<String, Object> saves(Episode e, int upTo, {required bool puzzle}) {
    final done = [for (final m in e.allMissions.take(upTo)) m.id];
    final current = upTo < e.allMissions.length ? e.allMissions[upTo] : null;
    final progress = GameProgress(
      detectiveName: 'MINYOUNG',
      introSeen: true,
      completedMissionIds: done,
      missionStartedAt: {if (puzzle && current != null) current.id: DateTime(2026, 9, 29, 10)},
      startedAt: DateTime(2026, 9, 29, 10),
      playMillis: 0,
    );
    final solved = [for (final s in season.takeWhile((s) => s.id != e.id)) s.id];
    return {
      AppConstants.progressKeyFor(e.id): jsonEncode(progress.toJson()),
      if (e.id != AppConstants.currentEpisodeId)
        AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINYOUNG').toJson()),
      AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: e.id, solvedEpisodeIds: solved).toJson()),
    };
  }

  Future<void> capture(WidgetTester t, String name) async {
    if (shots == null) return;
    await t.runAsync(() async {
      final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
      final image = await boundary.toImage(pixelRatio: 1.5);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<void> openScreen(WidgetTester t, Map<String, Object> prefs, String path) async {
    t.view.physicalSize = const Size(1080, 1920); // 360 × 640: a small phone
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    late WidgetRef appRef;
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(prefs: prefs),
      child: RepaintBoundary(
        key: const ValueKey('shot'),
        child: Consumer(builder: (context, ref, _) {
          appRef = ref;
          return const LondonMysteryApp();
        }),
      ),
    ));
    await wait(t, const Duration(milliseconds: 300));
    appRef.read(routerProvider).go(path);
    await wait(t, const Duration(milliseconds: 1200));
    expect(appRef.read(routerProvider).routerDelegate.currentConfiguration.uri.path, path, reason: 'not redirected');
  }

  for (final e in season) {
    // The notebook of a solved case: every evidence tile, at a small size.
    testWidgets('${e.id} notebook evidence page lays out without errors', (t) async {
      await openScreen(t, saves(e, e.allMissions.length, puzzle: false), Routes.notebook);
      await t.tap(find.text('EVIDENCE'));
      await wait(t, const Duration(milliseconds: 800));
      await capture(t, '${e.id}_notebook_evidence');
      await t.drag(find.byType(Scrollable).last, const Offset(0, -2000));
      await wait(t, const Duration(milliseconds: 400));
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 3));
    });
  }

  testWidgets('the case archive with every case file opened lays out without errors', (t) async {
    final last = season.last;
    await openScreen(t, saves(last, 0, puzzle: false), Routes.notebook);
    await t.tap(find.text('CASE ARCHIVE'));
    await wait(t, const Duration(milliseconds: 600));
    for (final e in season.take(season.length - 1)) {
      final folder = find.text(e.title.toUpperCase());
      await t.drag(find.byType(ListView).last, const Offset(0, 20000)); // back to the top
      await t.pump();
      await t.scrollUntilVisible(folder, 200, scrollable: find.descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable)).first);
      await t.tap(folder);
      await wait(t, const Duration(milliseconds: 500));
      await capture(t, 'archive_${e.id}');
      await t.drag(find.byType(ListView).last, const Offset(0, -900));
      await wait(t, const Duration(milliseconds: 300));
      expect(t.takeException(), isNull, reason: e.id);
    }
    await wait(t, const Duration(seconds: 3));
  });

  for (final e in season) {
    for (final (i, m) in e.allMissions.indexed) {
      final path = m.isFinal ? Routes.finalMission : Routes.mission(m.id);
      for (final puzzle in m.isFinal ? const [true] : const [false, true]) {
        final stage = m.isFinal ? 'final' : (puzzle ? 'puzzle' : 'story');
        testWidgets('${e.id} ${m.id} $stage screen lays out without errors', (t) async {
          await openScreen(t, saves(e, i, puzzle: puzzle), path);
          await capture(t, '${m.id}_$stage');
          // Scroll to the end so everything below the fold is laid out too.
          final list = find.byType(Scrollable);
          if (list.evaluate().isNotEmpty) {
            await t.drag(list.first, const Offset(0, -3000));
            await wait(t, const Duration(milliseconds: 600));
            await capture(t, '${m.id}_${stage}_end');
          }
          expect(t.takeException(), isNull);
          await wait(t, const Duration(seconds: 3)); // let timers finish
        });
      }
    }
  }
}
