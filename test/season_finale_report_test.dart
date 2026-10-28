import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/widgets/game_button.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';
import 'multi_season_test.dart' show asReleased, withParis, withParisMap;

/// Season 1's last report, once the season is complete: on to Paris (GO TO
/// PARIS, the one strong action) while Season 2 can be played, Paris
/// COMING SOON on the ticket while it cannot; and coming back to it, the
/// report as it was left, nothing played again.
void main() {
  final catalog = MockEpisodeRepository.bundled();
  // Season 1's cases only (the bundled catalog has Paris's too).
  final ids = [for (final e in catalog) if (e.seasonId == SeasonIds.london) e.id];

  /// Every case of Season 1 solved, Case 12 the open case file.
  Map<String, Object> season1Complete() {
    GameProgress solvedCase(String id) => GameProgress(
      detectiveName: 'MINYOUNG',
      introSeen: true,
      completedMissionIds: [for (final m in catalog.firstWhere((e) => e.id == id).allMissions) m.id],
      startedAt: DateTime(2026, 9, 29, 10),
      completedAt: DateTime(2026, 9, 29, 10, 30),
      playMillis: 0,
    );
    return {
      AppConstants.progressStorageKey: jsonEncode(solvedCase('ep01').toJson()),
      for (final id in ids.skip(1)) AppConstants.progressKeyFor(id): jsonEncode(solvedCase(id).toJson()),
      AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: ids).toJson()),
    };
  }

  late WidgetRef appRef;
  String path() => appRef.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

  Future<void> pumpApp(WidgetTester t, {Size size = const Size(360, 640), List<Override> extra = const []}) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: [...await testOverrides(prefs: season1Complete()), ...extra],
      child: Consumer(builder: (context, ref, _) {
        appRef = ref;
        return const WorldMysteryApp();
      }),
    ));
    await wait(t, const Duration(milliseconds: 300));
  }

  Future<void> openReport(WidgetTester t) async {
    appRef.read(routerProvider).go(Routes.solved);
    await wait(t, const Duration(milliseconds: 3200)); // the file, stamp, XP and footer all in
    await reveal(t, find.byKey(const ValueKey('finale-ticket')));
  }

  GameButton buttonOf(WidgetTester t, Finder label) =>
      t.widget<GameButton>(find.ancestor(of: label, matching: find.byType(GameButton)));

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('$tag release build, Paris not yet released: the ticket says COMING SOON, the board leads', (t) async {
      await pumpApp(t, size: size, extra: [parisNotYetReleased]);
      await openReport(t);
      expect(t.takeException(), isNull);
      expect(find.text('CASE CLOSED'), findsOneWidget, reason: 'the case file, as before');
      expect(find.text('London is safe.'), findsOneWidget);
      expect(find.text('But the watch says PARIS.'), findsOneWidget);
      expect(find.text('London needs you again.'), findsNothing);
      expect(find.text('COMING SOON'), findsOneWidget, reason: 'stamped on the ticket');
      expect(find.text('SEASON TWO · PARIS STANDS STILL'), findsOneWidget);
      expect(find.byKey(const ValueKey('go-to-next-season')), findsNothing, reason: 'nothing to press for Paris');
      expect(find.textContaining('GO TO'), findsNothing);
      expect(buttonOf(t, find.text('INVESTIGATION BOARD')).style, GameButtonStyle.glass, reason: 'the board leads');
      expect(find.byType(GameButton), findsOneWidget);
      expect(find.text('View my detective report'), findsOneWidget);
      expect(find.text('Notebook'), findsOneWidget);
      expect(find.text('Play again'), findsOneWidget);
      // Not entered from here, however asked.
      expect(appRef.read(gameControllerProvider.notifier).openSeason(SeasonIds.paris), isFalse);
      expect(appRef.read(selectedSeasonIdProvider), SeasonIds.london);

      await tapText(t, 'INVESTIGATION BOARD', after: const Duration(milliseconds: 2400));
      expect(path(), Routes.season);
      expect(find.text('SEASON TWO · COMING SOON'), findsOneWidget, reason: 'the board says the same');
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('$tag operator season preview: GO TO PARIS, the one strong action → cover → opening', (t) async {
      await pumpApp(t, size: size, extra: [seasonPreviewProvider.overrideWithValue(true)]);
      final prefs = appRef.read(sharedPreferencesProvider);
      final season1 = prefs.getString(savedKey(prefs, AppConstants.seasonStorageKey));
      await openReport(t);
      expect(t.takeException(), isNull);
      expect(find.text('But the watch says PARIS.'), findsOneWidget);
      expect(find.text('COMING SOON'), findsNothing, reason: 'the journey can be made');
      final go = find.byKey(const ValueKey('go-to-next-season'));
      await reveal(t, go);
      expect(find.text('GO TO PARIS'), findsOneWidget);
      expect(t.widget<GameButton>(go).style, GameButtonStyle.glass);
      expect(buttonOf(t, find.text('INVESTIGATION BOARD')).style, GameButtonStyle.outline);
      expect(find.byType(GameButton), findsNWidgets(2), reason: 'two boxes: Paris, then the board');
      expect(t.getRect(go).top, lessThan(t.getRect(find.text('INVESTIGATION BOARD')).top), reason: 'Paris first');
      expect(find.text('View my detective report'), findsOneWidget, reason: 'quieter, a text button');

      await t.tap(go);
      await t.pump();
      // While the report fades out, it never shows Paris's case in London's file.
      expect(find.text('Paris needs you again.'), findsNothing);
      expect(find.text('CASE CLOSED'), findsNothing);
      await wait(t, const Duration(milliseconds: 1600));
      expect(appRef.read(selectedSeasonIdProvider), SeasonIds.paris);
      expect(path(), Routes.seasonOf(SeasonIds.paris));
      expect(prefs.getString(savedKey(prefs, AppConstants.seasonStorageKey)), season1, reason: 'Season 1 kept');
      // Paris's cover: begun once already, so its investigation.
      expect(find.text('BEGIN SEASON TWO'), findsNothing);
      await wait(t, const Duration(milliseconds: 1400)); // the cover comes in
      await t.tap(find.text('BEGIN INVESTIGATION'));
      await wait(t, const Duration(milliseconds: 1400));
      expect(path(), Routes.parisPrologue);
      expect(find.text('THE LAST CLUE'), findsOneWidget);
      await wait(t, const Duration(seconds: 3));
    });
  }

  for (final size in const [Size(360, 640), Size(390, 844), Size(430, 932)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('$tag as shipped (Paris released, a release build): report → GO TO PARIS → cover → opening → Case 01', (t) async {
      await pumpApp(t, size: size, extra: [operatorToolsAvailableProvider.overrideWithValue(false)]);
      expect(appRef.read(seasonPreviewProvider), isFalse, reason: 'no preview: the release itself');
      final prefs = appRef.read(sharedPreferencesProvider);
      final season1 = prefs.getString(savedKey(prefs, AppConstants.seasonStorageKey));
      await openReport(t);
      expect(t.takeException(), isNull);
      // The completion report as before: the case file, stamped, its
      // badge and XP.
      expect(find.text('CASE CLOSED'), findsOneWidget);
      expect(find.text('London is safe.'), findsOneWidget);
      expect(find.text('But the watch says PARIS.'), findsOneWidget);
      expect(find.text('COMING SOON'), findsNothing);
      final go = find.byKey(const ValueKey('go-to-next-season'));
      await reveal(t, go);
      expect(find.text('GO TO PARIS'), findsOneWidget);
      expect(t.widget<GameButton>(go).style, GameButtonStyle.glass, reason: 'the one strong action');
      expect(buttonOf(t, find.text('INVESTIGATION BOARD')).style, GameButtonStyle.outline);
      expect(find.text('View my detective report'), findsOneWidget);

      await t.tap(go);
      await wait(t, const Duration(milliseconds: 1600));
      expect(appRef.read(selectedSeasonIdProvider), SeasonIds.paris);
      expect(path(), Routes.seasonOf(SeasonIds.paris), reason: "Paris's cover");
      expect(prefs.getString(savedKey(prefs, AppConstants.seasonStorageKey)), season1, reason: 'Season 1 kept');
      await wait(t, const Duration(milliseconds: 1400)); // the cover comes in
      expect(t.takeException(), isNull);
      final begin = find.text('BEGIN SEASON TWO').evaluate().isNotEmpty ? 'BEGIN SEASON TWO' : 'BEGIN INVESTIGATION';
      await tapText(t, begin, after: const Duration(milliseconds: 1400));
      expect(path(), Routes.parisPrologue, reason: "Paris's opening");
      expect(find.text('THE LAST CLUE'), findsOneWidget);
      await t.tap(find.text('SKIP ›'));
      await wait(t, const Duration(milliseconds: 1600));
      await t.tap(find.text('ACCEPT THE CASE'));
      await wait(t, const Duration(milliseconds: 2000));
      expect(find.text('ASSIGNED'), findsOneWidget, reason: 'Case 01 can be played');
      expect(find.text('COMING SOON'), findsNothing);
      await tapText(t, 'START CASE 01', after: const Duration(milliseconds: 1600));
      expect(path(), Routes.caseFile('s2_ep01'));
      expect(appRef.read(currentEpisodeProvider).id, 's2_ep01');
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 3));
    });
  }

  testWidgets('Season 2 as released: GO TO PARIS too', (t) async {
    await pumpApp(t, extra: [allEpisodesProvider.overrideWithValue(withParis), seasonMapsProvider.overrideWithValue(withParisMap), asReleased]);
    await openReport(t);
    expect(find.byKey(const ValueKey('go-to-next-season')), findsOneWidget);
    expect(find.text('COMING SOON'), findsNothing);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('the parent gate still guards the report from the text button', (t) async {
    await pumpApp(t);
    await openReport(t);
    await tapText(t, 'View my detective report', after: const Duration(milliseconds: 600));
    expect(find.byType(TextField), findsOneWidget, reason: 'the gate asks first');
    expect(path(), Routes.solved);
    await tapText(t, 'Cancel', after: const Duration(milliseconds: 800));
    expect(appRef.read(parentReportAccessProvider), isFalse);
    await wait(t, const Duration(seconds: 3));
  });

  group('coming back to the app', () {
    /// The report's footer (the ticket and the way on), scrolled to at once.
    Future<Opacity> footerOf(WidgetTester t) async {
      await t.drag(find.byType(Scrollable).first, const Offset(0, -2000));
      await t.pump();
      final ticket = find.byKey(const ValueKey('finale-ticket'), skipOffstage: false);
      return t.widget<Opacity>(find.ancestor(of: ticket, matching: find.byType(Opacity, skipOffstage: false)).first);
    }

    testWidgets('the report as it was left: stamped, nothing comes down or counts up again', (t) async {
      await pumpApp(t, extra: [seasonPreviewProvider.overrideWithValue(true)]);
      await tapText(t, 'CONTINUE ADVENTURE', after: const Duration(milliseconds: 100));
      expect(path(), Routes.solvedSettled);
      await t.pump(const Duration(milliseconds: 400)); // the page's fade only
      expect(find.text('CASE CLOSED'), findsOneWidget);
      expect((await footerOf(t)).opacity, 1, reason: 'already in: no entrance played again');
      expect(find.byKey(const ValueKey('go-to-next-season'), skipOffstage: false), findsOneWidget, reason: 'on to Paris, as left');
      expect(appRef.read(selectedSeasonIdProvider), SeasonIds.london, reason: 'not moved anywhere by itself');
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('just solved (the case\'s own flow): the file still comes in', (t) async {
      await pumpApp(t);
      appRef.read(routerProvider).go(Routes.solved);
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect((await footerOf(t)).opacity, lessThan(1));
      await wait(t, const Duration(seconds: 3));
    });
  });
}
