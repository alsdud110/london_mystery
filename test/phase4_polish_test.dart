import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/core/theme/app_colors.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/widgets/landmark_art.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';

/// Phase 4 polish: the solved Case 02 clock, a disabled Undo that looks
/// disabled, and "OPEN CASE NN" landing on that case in the case files.
void main() {
  final season = MockEpisodeRepository.bundled();
  final ep01 = season.first;
  final ep02 = season[1];

  Future<WidgetRef> pumpApp(WidgetTester t, Map<String, Object> prefs) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    late WidgetRef appRef;
    await t.pumpWidget(
      ProviderScope(
        overrides: await testOverrides(prefs: prefs),
        child: Consumer(
          builder: (context, ref, _) {
            appRef = ref;
            return const LondonMysteryApp();
          },
        ),
      ),
    );
    await wait(t);
    return appRef;
  }

  String pathOf(WidgetRef ref) => ref.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

  String progress({List<String> done = const [], bool solved = false, String? opened}) => jsonEncode(
    GameProgress(
      detectiveName: 'KIM',
      introSeen: true,
      completedMissionIds: done,
      missionStartedAt: opened == null ? const {} : {opened: DateTime(2026, 9, 29, 10)},
      startedAt: DateTime(2026, 9, 29, 10),
      completedAt: solved ? DateTime(2026, 9, 29, 10, 40) : null,
      playMillis: 0,
    ).toJson(),
  );

  /// Case 01 solved, Case 02 active with [done] of its missions solved.
  Map<String, Object> case02(List<String> done, {bool solved = false, String? opened}) => {
    AppConstants.progressStorageKey: progress(done: [for (final m in ep01.allMissions) m.id], solved: true),
    AppConstants.progressKeyFor('ep02'): progress(done: done, solved: solved, opened: opened),
    AppConstants.seasonStorageKey: jsonEncode(
      SeasonProgress(activeEpisodeId: 'ep02', solvedEpisodeIds: ['ep01', if (solved) 'ep02']).toJson(),
    ),
  };

  LandmarkArt clockArt(WidgetTester t) =>
      t.widgetList<LandmarkArt>(find.byType(LandmarkArt)).firstWhere((a) => a.artwork == Artwork.clockFace);

  group('Case 02 clock', () {
    testWidgets('the final clock starts at 8:17 and turns to the solved time with the solve', (t) async {
      final ref = await pumpApp(t, case02([for (final m in ep02.missions) m.id]));
      ref.read(routerProvider).go(Routes.finalMission);
      await wait(t, const Duration(milliseconds: 1200));
      expect(clockArt(t).solved, 0, reason: 'still stopped before the answer');

      for (final (i, digit) in ep02.finalMission.answer.split('').map(int.parse).indexed) {
        final up = find.byTooltip('Lock ${i + 1} up');
        await reveal(t, up);
        for (var n = 0; n < digit; n++) {
          await t.tap(up);
          await t.pump(const Duration(milliseconds: 20));
        }
      }
      await wait(t, const Duration(milliseconds: 300));
      await tapText(t, 'UNLOCK', after: const Duration(milliseconds: 3500));
      expect(ref.read(gameControllerProvider).isCaseSolved, isTrue);
      expect(clockArt(t).solved, 1, reason: 'the clock shows the time the detective set');
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('the solved clock is drawn differently; other scenes ignore it', (t) async {
      Future<List<int>> draw(Artwork a, double solved) async {
        await t.pumpWidget(RepaintBoundary(
          key: const ValueKey('art'),
          child: SizedBox(width: 120, height: 90, child: LandmarkArt(a, solved: solved)),
        ));
        return (await t.runAsync(() async {
          final image = await t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('art'))).toImage();
          return (await image.toByteData())!.buffer.asUint8List().toList();
        }))!;
      }

      expect(await draw(Artwork.clockFace, 1), isNot(await draw(Artwork.clockFace, 0)));
      expect(await draw(Artwork.gallery, 1), await draw(Artwork.gallery, 0));
    });

    testWidgets('the case solved photo shows the solved clock', (t) async {
      final ref = await pumpApp(t, case02([for (final m in ep02.allMissions) m.id], solved: true));
      ref.read(routerProvider).go(Routes.solved);
      await wait(t, const Duration(milliseconds: 3200));
      expect(clockArt(t).solved, 1);
      await wait(t, const Duration(seconds: 3));
    });
  });

  testWidgets('sequence puzzle: Undo is greyed out until there is something to undo', (t) async {
    final m = ep02.missionById('ep02_m3')!;
    final ref = await pumpApp(t, case02(['ep02_m1', 'ep02_m2'], opened: m.id));
    ref.read(routerProvider).go(Routes.mission(m.id));
    await wait(t, const Duration(milliseconds: 1200));
    Color undoInk() => t.widget<Text>(find.text('Undo')).style!.color!;

    expect(undoInk(), AppColors.locked);
    expect(t.widget<Text>(find.text('Start again')).style!.color, AppColors.locked);
    await tapText(t, m.options.first.label, after: const Duration(milliseconds: 300));
    expect(undoInk(), AppColors.royalBlue, reason: 'one step to undo');
    await tapText(t, 'Undo', after: const Duration(milliseconds: 300));
    expect(undoInk(), AppColors.locked);
    await wait(t, const Duration(seconds: 3));
  });

  group('OPEN CASE NN', () {
    testWidgets('after solving Case 01, OPEN CASE 02 lands on Case 02, chosen and open', (t) async {
      final ref = await pumpApp(t, {
        AppConstants.progressStorageKey: progress(done: [for (final m in ep01.allMissions) m.id], solved: true),
        AppConstants.seasonStorageKey: jsonEncode(
          const SeasonProgress(activeEpisodeId: 'ep01', solvedEpisodeIds: ['ep01']).toJson(),
        ),
      });
      ref.read(routerProvider).go(Routes.solved);
      await wait(t, const Duration(milliseconds: 3200));
      await tapText(t, 'OPEN CASE 02', after: const Duration(milliseconds: 1200));

      expect(pathOf(ref), Routes.caseFile('ep02'));
      expect(find.text(ep02.title), findsOneWidget, reason: 'the Case 02 folder is open');
      expect(find.text(ep02.synopsis.first), findsOneWidget, reason: 'Case 02 is the chosen case');
      expect(find.text('BEGIN INVESTIGATION'), findsOneWidget);
      await tapText(t, 'BEGIN INVESTIGATION', after: const Duration(milliseconds: 1200));
      expect(ref.read(currentEpisodeProvider).id, 'ep02');
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('on a small phone, OPEN CASE 07 scrolls the Case 07 folder into view', (t) async {
      final ep06 = season[5], ep07 = season[6];
      final solved = [for (final e in season.take(6)) e.id];
      await pumpApp(t, {
        AppConstants.progressStorageKey: progress(done: [for (final m in ep01.allMissions) m.id], solved: true),
        AppConstants.progressKeyFor(ep06.id): progress(done: [for (final m in ep06.allMissions) m.id], solved: true),
        AppConstants.seasonStorageKey:
            jsonEncode(SeasonProgress(activeEpisodeId: ep06.id, solvedEpisodeIds: solved).toJson()),
      }).then((ref) async {
        t.view.physicalSize = const Size(1080, 1920); // 360 × 640
        ref.read(routerProvider).go(Routes.solved);
        await wait(t, const Duration(milliseconds: 3200));
        await tapText(t, 'OPEN CASE 07', after: const Duration(milliseconds: 1500));
        expect(pathOf(ref), Routes.caseFile(ep07.id));
        expect(find.text(ep07.title).hitTestable(), findsOneWidget, reason: 'the chosen episode is on screen');
        expect(find.text(ep07.title.toUpperCase()).hitTestable(), findsOneWidget, reason: 'its folder too');
        await tapText(t, 'BEGIN INVESTIGATION', after: const Duration(milliseconds: 1200));
        expect(ref.read(currentEpisodeProvider).id, ep07.id);
      });
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('a sealed or unknown case in the link is ignored', (t) async {
      final ref = await pumpApp(t, {AppConstants.progressStorageKey: progress()});
      for (final id in ['ep12', 'ep99']) {
        ref.read(routerProvider).go(Routes.caseFile(id));
        await wait(t, const Duration(milliseconds: 800));
        expect(find.text('Solve Case 11 to open this file.'), findsNothing, reason: '$id folder stays closed');
        expect(find.text('CONTINUE INVESTIGATION'), findsOneWidget, reason: 'Case 01 stays chosen');
      }
      expect(ref.read(currentEpisodeProvider).id, 'ep01');
      await wait(t, const Duration(seconds: 3));
    });
  });
}
