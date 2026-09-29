import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game_master/playtest_tools.dart';
import 'package:london_mystery/features/notebook/season_archive.dart';

import 'full_playthrough_test.dart' show tapText, wait;
import 'helpers.dart';

/// The Game Master playtest tools: start any case from its beginning, or
/// restart the open case, without changing how the game is played.
void main() {
  Future<WidgetRef> openGameMaster(WidgetTester t, Map<String, Object> prefs) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    late WidgetRef appRef;
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(prefs: prefs),
      child: Consumer(builder: (context, ref, _) {
        appRef = ref;
        return const LondonMysteryApp();
      }),
    ));
    await wait(t);
    appRef.read(gameMasterAccessProvider.notifier).grant();
    appRef.read(routerProvider).go(Routes.gameMaster);
    await wait(t);
    return appRef;
  }

  String pathOf(WidgetRef ref) => ref.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

  test('the tools are on in debug builds (tests), off in a plain release build', () {
    expect(playtestToolsEnabled, isTrue);
  });

  testWidgets('CASE 07부터: Cases 01-06 count as solved, Case 07 is new and chosen', (t) async {
    final ref = await openGameMaster(t, {
      AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINA', introSeen: true).toJson()),
    });
    await tapText(t, 'CASE 07부터', after: const Duration(milliseconds: 600));
    await tapText(t, '시작', after: const Duration(milliseconds: 1200));

    expect(pathOf(ref), Routes.caseFile('ep07'));
    expect(find.text('BEGIN INVESTIGATION'), findsOneWidget);
    final season = ref.read(seasonProvider);
    expect(season.activeEpisodeId, 'ep07');
    expect(season.solvedEpisodeIds, ['ep01', 'ep02', 'ep03', 'ep04', 'ep05', 'ep06']);
    final p = ref.read(gameControllerProvider);
    expect(p.detectiveName, 'MINA', reason: 'the name is kept');
    expect(p.introSeen, isFalse, reason: 'Case 07 starts from its story intro');
    expect(p.completedMissionIds, isEmpty);

    final archive = ref.read(seasonArchiveProvider);
    final ep03 = archive.firstWhere((a) => a.episode.id == 'ep03');
    expect(ep03.status, ArchiveStatus.solved);
    expect(ep03.evidence, hasLength(ep03.episode.allEvidence.length), reason: 'hints can point to the archive');
    expect(archive.firstWhere((a) => a.episode.id == 'ep08').status, ArchiveStatus.sealed);

    // Nothing a real play would earn: no badges, no hints.
    final repo = ref.read(progressRepositoryProvider);
    for (final id in season.solvedEpisodeIds) {
      expect(repo.load(id).badgeIds, isEmpty, reason: id);
      expect(repo.load(id).hintsUsed, isEmpty, reason: id);
    }
    await tapText(t, 'BEGIN INVESTIGATION', after: const Duration(milliseconds: 1200));
    expect(pathOf(ref), Routes.intro);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('restart this case: only the open case is cleared', (t) async {
    final ref = await openGameMaster(t, {
      AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINA').toJson()),
    });
    await tapText(t, 'CASE 03부터', after: const Duration(milliseconds: 600));
    await tapText(t, '시작', after: const Duration(milliseconds: 1200));
    final ctrl = ref.read(gameControllerProvider.notifier);
    ctrl.startInvestigation();
    final m = ref.read(currentEpisodeProvider).missions.first;
    expect(ctrl.submitAnswer(m, m.answer).result, SubmitResult.correct);
    final ep02Before = ref.read(sharedPreferencesProvider).getString(AppConstants.progressKeyFor('ep02'));

    ref.read(gameMasterAccessProvider.notifier).grant();
    ref.read(routerProvider).go(Routes.gameMaster);
    await wait(t);
    await tapText(t, '지금 사건(CASE 03) 처음부터', after: const Duration(milliseconds: 600));
    await tapText(t, '다시 시작', after: const Duration(milliseconds: 1200));

    final p = ref.read(gameControllerProvider);
    expect(ref.read(currentEpisodeProvider).id, 'ep03');
    expect(p.completedMissionIds, isEmpty);
    expect(p.detectiveName, 'MINA');
    expect(ref.read(seasonProvider).isSolved('ep02'), isTrue);
    expect(ref.read(sharedPreferencesProvider).getString(AppConstants.progressKeyFor('ep02')), ep02Before);
    expect(pathOf(ref), Routes.caseFile('ep03'));
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('a device with no detective yet gets the tester name', (t) async {
    final ref = await openGameMaster(t, {});
    await tapText(t, 'CASE 12부터', after: const Duration(milliseconds: 600));
    await tapText(t, '시작', after: const Duration(milliseconds: 1200));
    expect(ref.read(gameControllerProvider).detectiveName, playtestDetectiveName);
    expect(ref.read(seasonProvider.notifier).isUnlocked('ep12'), isTrue);
    expect(pathOf(ref), Routes.caseFile('ep12'));
    await wait(t, const Duration(seconds: 3));
  });
}
