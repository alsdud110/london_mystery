import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_providers.dart' show sharedPreferencesProvider;

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';

/// Plays one regular mission of Season 1 in the real app: opens it at its
/// puzzle (earlier cases and missions solved) and answers it through its own
/// puzzle, as a child would.
class MissionPlay {
  final season = MockEpisodeRepository.bundled();
  late WidgetRef ref;

  Episode caseOf(String missionId) => season.firstWhere((e) => e.missions.any((m) => m.id == missionId));

  String path() => ref.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

  /// [missionId] open at its puzzle: earlier cases solved, the missions
  /// before it solved.
  Future<Mission> openPuzzle(WidgetTester t, Size size, String missionId, {double textScale = 1}) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    t.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    final e = caseOf(missionId);
    final before = e.missions.takeWhile((m) => m.id != missionId).map((m) => m.id).toList();
    final earlier = [for (final x in season) if (x.number < e.number) x];
    final start = DateTime.now().subtract(const Duration(minutes: 1));
    String progress(List<String> done, {bool solved = false, Map<String, DateTime> started = const {}}) =>
        jsonEncode(GameProgress(
          detectiveName: 'MINYOUNG',
          introSeen: true,
          completedMissionIds: done,
          missionStartedAt: started,
          startedAt: start,
          completedAt: solved ? start : null,
          playMillis: 0,
        ).toJson());
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(prefs: {
        for (final x in earlier)
          AppConstants.progressKeyFor(x.id): progress([for (final m in x.allMissions) m.id], solved: true),
        if (e.id != AppConstants.currentEpisodeId)
          AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINYOUNG').toJson()),
        AppConstants.progressKeyFor(e.id): progress(before, started: {missionId: start}),
        AppConstants.seasonStorageKey: jsonEncode(
          SeasonProgress(activeEpisodeId: e.id, solvedEpisodeIds: [for (final x in earlier) x.id]).toJson(),
        ),
      }),
      child: RepaintBoundary(
        key: const ValueKey('shot'),
        child: Consumer(builder: (context, r, _) {
          ref = r;
          return const LondonMysteryApp();
        }),
      ),
    ));
    await wait(t, const Duration(milliseconds: 300));
    ref.read(routerProvider).go(Routes.mission(missionId));
    await wait(t, const Duration(milliseconds: 1200));
    expect(find.text('CHECK ANSWER').evaluate().isNotEmpty || find.text('UNLOCK').evaluate().isNotEmpty, isTrue,
        reason: '$missionId: at its puzzle');
    return e.missionById(missionId)!;
  }

  /// Answers [m] through its own puzzle, as a child would; stops as the
  /// Discovery Moment opens.
  Future<void> solve(WidgetTester t, Mission m) async {
    switch (m.type) {
      case MissionType.multipleChoice:
        await tapText(t, m.answerLabel, after: const Duration(milliseconds: 200));
      case MissionType.imageChoice:
        final i = m.options.indexWhere((o) => o.id == m.answer);
        final picture = find.bySemanticsLabel('Picture ${String.fromCharCode(65 + i)}, ${m.answerLabel}');
        await reveal(t, picture);
        await t.tap(picture);
        await wait(t, const Duration(milliseconds: 200));
      case MissionType.wordInput:
        await reveal(t, find.byType(TextField));
        await t.enterText(find.byType(TextField), m.answer);
        await t.pump();
      case MissionType.numberCode:
        for (final d in m.answer.split('')) {
          await tapText(t, d, after: const Duration(milliseconds: 120));
        }
        await tapText(t, 'UNLOCK', after: const Duration(milliseconds: 400));
        return;
      case MissionType.sequence:
        for (final id in Mission.sequenceIds(m.answer)) {
          final tile = find.text(m.options.firstWhere((o) => o.id == id).label).last;
          await reveal(t, tile);
          await t.tap(tile);
          await t.pump(const Duration(milliseconds: 150));
        }
      case MissionType.qrScan || MissionType.finalCode:
        fail('not used here');
    }
    await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 400));
  }

  /// The app closed and opened again on the same saved progress.
  Future<void> restart(WidgetTester t) async {
    final prefs = await testOverrides(prefs: {
      for (final k in (await _saved()).entries) k.key: k.value,
    });
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(ProviderScope(
      overrides: prefs,
      child: RepaintBoundary(
        key: const ValueKey('shot'),
        child: Consumer(builder: (context, r, _) {
          ref = r;
          return const LondonMysteryApp();
        }),
      ),
    ));
    await wait(t, const Duration(milliseconds: 1200));
  }

  Future<Map<String, Object>> _saved() async {
    final p = ref.read(sharedPreferencesProvider);
    return {for (final k in p.getKeys()) k: p.get(k)!};
  }
}
