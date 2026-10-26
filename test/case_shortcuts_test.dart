import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/season.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game_master/playtest_tools.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show tapText, wait;
import 'helpers.dart';

/// The Game Master's case shortcuts: any case of any season, opened at its
/// case file, without changing a save; gone with the session, and never in
/// a build without operator tools.
void main() {
  final detective = {
    AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINA', introSeen: true).toJson()),
  };

  Future<WidgetRef> pumpApp(WidgetTester t, List<Override> overrides, {Size size = const Size(390, 844)}) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    late WidgetRef appRef;
    await t.pumpWidget(ProviderScope(
      overrides: overrides,
      child: Consumer(builder: (context, ref, _) {
        appRef = ref;
        return const LondonMysteryApp();
      }),
    ));
    await wait(t);
    return appRef;
  }

  Future<void> openGameMaster(WidgetTester t, WidgetRef ref) async {
    ref.read(gameMasterAccessProvider.notifier).grant();
    ref.read(routerProvider).go(Routes.gameMaster);
    await wait(t);
  }

  String pathOf(WidgetRef ref) => ref.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

  Future<void> tapKey(WidgetTester t, String key) async {
    final f = find.byKey(ValueKey(key));
    await t.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
    await t.tap(f);
    await wait(t, const Duration(milliseconds: 900));
  }

  /// Every save of a season, as stored: its record and each case's save.
  Map<String, Object?> savesOf(WidgetRef ref, String seasonId) {
    final repo = ref.read(progressRepositoryProvider);
    return {
      'season': repo.loadSeason(seasonId).toJson(),
      for (final e in SeasonAvailability.casesOf(seasonId, ref.read(allEpisodesProvider))) e.id: repo.load(e.id).toJson(),
    };
  }

  testWidgets('London: every case 01-12 opens at its case file, none solved before', (t) async {
    final ref = await pumpApp(t, await testOverrides(prefs: detective));
    for (final e in SeasonAvailability.casesOf(SeasonIds.london, ref.read(allEpisodesProvider))) {
      await openGameMaster(t, ref);
      await tapKey(t, 'shortcut-season-${SeasonIds.london}');
      await tapKey(t, 'shortcut-case-${e.id}');
      expect(pathOf(ref), Routes.caseFile(e.id), reason: e.id);
      expect(ref.read(currentEpisodeProvider).id, e.id);
      expect(ref.read(seasonProvider).solvedEpisodeIds, isEmpty, reason: 'nothing is marked solved');
    }
    expect(find.text('BEGIN INVESTIGATION'), findsOneWidget);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('Paris with Season 1 unsolved: every case 01-12 opens; none is coming soon', (t) async {
    final ref = await pumpApp(t, await testOverrides(prefs: detective));
    final london = savesOf(ref, SeasonIds.london);
    expect(ref.read(seasonAvailabilityProvider(SeasonIds.paris))!.canEnter, isFalse, reason: 'locked for the player');
    final paris = SeasonAvailability.casesOf(SeasonIds.paris, ref.read(allEpisodesProvider));
    expect(paris, hasLength(12));
    for (final e in paris) {
      await openGameMaster(t, ref);
      await tapKey(t, 'shortcut-season-${SeasonIds.paris}');
      await tapKey(t, 'shortcut-case-${e.id}');
      expect(pathOf(ref), Routes.caseFile(e.id), reason: e.id);
      expect(ref.read(selectedSeasonIdProvider), SeasonIds.paris);
      expect(ref.read(seasonProvider).solvedEpisodeIds, isEmpty, reason: 'the cases before it stay unsolved');
    }
    // Case 12's file: its investigation begins at its Mission 1 story intro.
    await tapText(t, 'BEGIN INVESTIGATION', after: const Duration(milliseconds: 1200));
    expect(pathOf(ref), Routes.intro);
    expect(savesOf(ref, SeasonIds.london), london, reason: "Season 1's saves are untouched");

    await openGameMaster(t, ref);
    await tapKey(t, 'shortcut-season-${SeasonIds.paris}');
    for (final n in [11, 12]) {
      expect(find.byKey(ValueKey('shortcut-planned-${SeasonIds.paris}-$n')), findsNothing, reason: '$n is in the game');
    }
    expect(find.textContaining('Coming Soon'), findsNothing);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('a restart is back to the player\'s own unlocks; their saves are as they were', (t) async {
    final ref = await pumpApp(t, await testOverrides(prefs: detective));
    // The player's own progress: Case 01 solved, Case 02 open.
    final repo = ref.read(progressRepositoryProvider);
    final ep01 = SeasonAvailability.casesOf(SeasonIds.london, ref.read(allEpisodesProvider)).first;
    repo.save(GameProgress(detectiveName: 'MINA', introSeen: true, completedMissionIds: [for (final m in ep01.allMissions) m.id]), 'ep01');
    ref.read(seasonProvider.notifier).markSolved('ep01');
    expect(ref.read(gameControllerProvider.notifier).openEpisode('ep02'), isTrue);
    final london = savesOf(ref, SeasonIds.london);

    expect(jumpToCase(ref, SeasonIds.paris, 's2_ep07'), isNull);
    expect(ref.read(currentEpisodeProvider).id, 's2_ep07');
    expect(savesOf(ref, SeasonIds.london), london);

    // The app is opened again: both session switches are off.
    final prefs = await SharedPreferences.getInstance();
    await t.pumpWidget(const SizedBox()); // the app is closed
    final after = await pumpApp(t, await testOverridesFor(prefs));
    expect(after.read(seasonPreviewProvider), isFalse);
    expect(after.read(operatorAccessProvider), isFalse);
    expect(after.read(selectedSeasonIdProvider), SeasonIds.london, reason: 'the locked season is not resumed');
    expect(after.read(currentEpisodeProvider).id, 'ep02');
    expect(after.read(seasonAvailabilityProvider(SeasonIds.paris))!.canEnter, isFalse);
    expect(after.read(seasonProvider.notifier).isUnlocked('ep03'), isFalse, reason: 'Case 03 waits for Case 02 again');
    expect(savesOf(after, SeasonIds.london), london);
    await wait(t, const Duration(seconds: 2));
  });

  testWidgets('no detective yet: nothing opens and nothing is written', (t) async {
    final ref = await pumpApp(t, await testOverrides());
    expect(jumpToCase(ref, SeasonIds.paris, 's2_ep01'), CaseJumpRefusal.noDetective);
    expect(ref.read(selectedSeasonIdProvider), SeasonIds.london);
    expect(ref.read(seasonPreviewProvider), isFalse);
  });

  testWidgets('a build without operator tools: no shortcuts, and the jump is refused', (t) async {
    final ref = await pumpApp(t, [
      ...await testOverrides(prefs: detective),
      operatorToolsAvailableProvider.overrideWithValue(false),
    ]);
    await openGameMaster(t, ref);
    expect(find.byKey(const ValueKey('case-shortcuts')), findsNothing);
    expect(jumpToCase(ref, SeasonIds.paris, 's2_ep01'), CaseJumpRefusal.noOperatorTools);
    expect(ref.read(seasonAvailabilityProvider(SeasonIds.paris))!.canEnter, isFalse);
  });

  testWidgets('small phone: the seasons and cases fit, nothing overflows', (t) async {
    final ref = await pumpApp(t, await testOverrides(prefs: detective), size: const Size(360, 640));
    await openGameMaster(t, ref);
    await tapKey(t, 'shortcut-season-${SeasonIds.paris}');
    expect(t.takeException(), isNull);
    expect(find.text('PARIS — CASE SELECT'), findsOneWidget);
  });
}
