import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/data/mock/season_catalog.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/season/world_archive_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';
import 'multi_season_test.dart' show withParis, withParisMap;

void main() {
  final catalog = MockEpisodeRepository.bundled();
  final ids = [for (final e in catalog) e.id];

  /// Season 1 with its first [solved] cases solved (saves from before
  /// profiles, as an updated app finds them); [activeBegun]: the case after
  /// them has begun.
  Map<String, Object> seasonSaves(int solved, {bool activeBegun = false}) {
    final act = ids[solved == 0 ? 0 : (solved < 12 ? solved : 11)];
    GameProgress solvedCase(String id) => GameProgress(
      detectiveName: 'MINYOUNG',
      introSeen: true,
      completedMissionIds: [for (final m in catalog.firstWhere((e) => e.id == id).allMissions) m.id],
      startedAt: DateTime(2026, 9, 29, 10),
      completedAt: DateTime(2026, 9, 29, 10, 30),
      playMillis: 0,
    );
    return {
      AppConstants.progressStorageKey: jsonEncode(
        (solved > 0 ? solvedCase('ep01') : GameProgress(detectiveName: 'MINYOUNG', introSeen: activeBegun)).toJson(),
      ),
      for (final id in ids.skip(1).take(solved > 0 ? solved - 1 : 0))
        AppConstants.progressKeyFor(id): jsonEncode(solvedCase(id).toJson()),
      if (activeBegun && solved > 0 && solved < 12)
        AppConstants.progressKeyFor(act): jsonEncode(
          GameProgress(detectiveName: 'MINYOUNG', introSeen: true, startedAt: DateTime(2026, 9, 29, 11), playMillis: 0).toJson(),
        ),
      AppConstants.seasonStorageKey: jsonEncode(
        SeasonProgress(activeEpisodeId: act, solvedEpisodeIds: ids.take(solved).toList()).toJson(),
      ),
    };
  }

  late WidgetRef appRef;
  String path() => appRef.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

  Future<void> pumpApp(
    WidgetTester t,
    Map<String, Object> prefs, {
    Size size = const Size(360, 640),
    List<Override> extra = const [],
  }) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: [...await testOverrides(prefs: prefs), ...extra],
      child: Consumer(builder: (context, ref, _) {
        appRef = ref;
        return const LondonMysteryApp();
      }),
    ));
    await wait(t, const Duration(milliseconds: 300));
  }

  Future<void> openArchive(WidgetTester t) async {
    appRef.read(routerProvider).go(Routes.seasons);
    await wait(t, const Duration(milliseconds: 1400)); // the files are laid down
    expect(path(), Routes.seasons);
  }

  /// Every text on screen (built, scrolled to or not), lower case.
  String screenText(WidgetTester t) => [
    for (final w in t.widgetList<Text>(find.byType(Text, skipOffstage: false)))
      (w.data ?? w.textSpan?.toPlainText() ?? '').toLowerCase(),
  ].join(' | ');

  /// Every save on the device, as stored.
  Map<String, Object?> saves() {
    final prefs = appRef.read(sharedPreferencesProvider);
    return {for (final k in prefs.getKeys()) k: prefs.get(k)};
  }

  Finder file(String seasonId) => find.byKey(ValueKey('season-file-$seasonId'));

  Future<void> tapFile(WidgetTester t, String seasonId) async {
    await reveal(t, file(seasonId));
    await t.tap(file(seasonId));
    await wait(t, const Duration(milliseconds: 400));
  }

  group('the files', () {
    testWidgets('before Season 1 is finished, Season 2 is a sealed file that names nothing', (t) async {
      await pumpApp(t, seasonSaves(0));
      await openArchive(t);
      expect(find.text('WORLD MYSTERY'), findsOneWidget);
      expect(find.text('Choose your next adventure'), findsOneWidget);
      expect(find.text('SEASON ONE'), findsOneWidget);
      expect(find.text('SHADOWS OVER LONDON'), findsOneWidget);
      expect(find.text('12 CASES • ONE MYSTERY'), findsOneWidget);
      expect(find.text('0 / 12'), findsOneWidget);
      expect(find.text('BEGIN SEASON ONE'), findsOneWidget);

      await reveal(t, file(SeasonIds.paris));
      expect(find.text('SEASON TWO'), findsOneWidget);
      expect(find.text('SEALED FILE'), findsOneWidget);
      expect(find.text('SEALED'), findsOneWidget);
      expect(find.text('Solve Shadows over London to unseal this file.'), findsOneWidget);
      final text = screenText(t);
      for (final spoiler in ['paris', 'stands still', 'stolen hour', 'eiffel']) {
        expect(text, isNot(contains(spoiler)), reason: 'Season 1 ends on PARIS: nothing tells it first');
      }
      expect(find.text('COMING SOON'), findsNothing);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('Season 1 under way: its real count, CONTINUE THE FILE, the current file', (t) async {
      await pumpApp(t, seasonSaves(4, activeBegun: true));
      await openArchive(t);
      expect(find.text('4 / 12'), findsOneWidget);
      expect(find.text('CONTINUE THE FILE'), findsOneWidget);
      expect(find.text('CURRENT FILE'), findsOneWidget);
      expect(find.text('SOLVED'), findsNothing);
      await reveal(t, file(SeasonIds.paris));
      expect(find.text('SEALED FILE'), findsOneWidget);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('Season 1 solved: SOLVED, REVIEW THE FILE; Season 2 named and coming soon', (t) async {
      await pumpApp(t, seasonSaves(12));
      await openArchive(t);
      expect(find.text('12 / 12'), findsOneWidget);
      expect(find.text('SOLVED'), findsOneWidget);
      expect(find.text('REVIEW THE FILE'), findsOneWidget);
      await reveal(t, file(SeasonIds.paris));
      expect(find.text('PARIS STANDS STILL'), findsOneWidget);
      expect(find.text('ONE STOLEN HOUR'), findsOneWidget);
      expect(find.text('COMING SOON'), findsOneWidget);
      expect(find.text('SEALED FILE'), findsNothing);
      expect(find.text('BEGIN SEASON TWO'), findsNothing, reason: 'no cases and no map yet');
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('three seasons or more: the archives scroll to every file', (t) async {
      const third = Season(id: 's3_test', number: 3, title: 'A Third City', tagline: 'ONE MORE', prologue: SeasonPrologue(), outro: [], figures: []);
      await pumpApp(t, seasonSaves(0), extra: [
        seasonsProvider.overrideWithValue([
          for (final s in SeasonCatalog.all) s.season,
          third,
        ]),
      ]);
      await openArchive(t);
      expect(file('s3_test').hitTestable(), findsNothing, reason: 'below the fold');
      await reveal(t, file('s3_test'));
      expect(find.text('SEASON THREE'), findsOneWidget);
      expect(find.text('A THIRD CITY'), findsNothing, reason: 'sealed: its season before is not solved');
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 3));
    });
  });

  group('choosing a file', () {
    testWidgets('a sealed or coming-soon file only says why: nothing saved, the season kept', (t) async {
      await pumpApp(t, seasonSaves(4, activeBegun: true));
      final before = saves();
      await openArchive(t);
      await tapFile(t, SeasonIds.paris);
      expect(find.text('Solve Shadows over London to unseal this file.'), findsNWidgets(2), reason: 'the note and the toast');
      expect(path(), Routes.seasons);
      expect(appRef.read(selectedSeasonIdProvider), SeasonIds.london);
      expect(saves(), before, reason: 'visiting and tapping saves nothing');
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('coming soon: still being prepared, Season 1 stays the one played', (t) async {
      await pumpApp(t, seasonSaves(12));
      // Read before the snapshot: the first read of the wallet makes it (a
      // save from before coins), which is not the archives' doing.
      final coins = appRef.read(walletProvider).balance;
      final before = saves();
      await openArchive(t);
      await tapFile(t, SeasonIds.paris);
      expect(find.text('This file is still being prepared.'), findsNWidgets(2), reason: 'the note and the toast');
      expect(path(), Routes.seasons);
      expect(appRef.read(selectedSeasonIdProvider), SeasonIds.london);
      expect(appRef.read(currentEpisodeProvider).seasonId, SeasonIds.london);
      expect(appRef.read(walletProvider).balance, coins);
      expect(appRef.read(detectiveProfileProvider).detectiveName, 'MINYOUNG');
      expect(saves(), before);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('London: its board, and back to the archives (arrow and system back)', (t) async {
      await pumpApp(t, seasonSaves(4, activeBegun: true));
      final before = saves();
      await openArchive(t);
      await tapText(t, 'CONTINUE THE FILE', after: const Duration(milliseconds: 1500));
      expect(path(), Routes.seasonFromArchive);
      expect(find.text('CASES SOLVED'), findsOneWidget, reason: 'the Season 1 board, as always');
      expect(saves(), before, reason: 'Season 1 was being played: choosing it changes nothing');
      await t.tap(find.byTooltip('Back'));
      await wait(t, const Duration(milliseconds: 1400));
      expect(path(), Routes.seasons);
      await tapText(t, 'CONTINUE THE FILE', after: const Duration(milliseconds: 1500));
      await t.binding.handlePopRoute(); // Android back
      await wait(t, const Duration(milliseconds: 1400));
      expect(path(), Routes.seasons);
      // The archives go back to the title, both ways.
      await t.tap(find.byTooltip('Back'));
      await wait(t);
      expect(path(), Routes.start);
      await openArchive(t);
      await t.binding.handlePopRoute();
      await wait(t);
      expect(path(), Routes.start);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('London not begun: BEGIN SEASON ONE opens its cover, as always', (t) async {
      await pumpApp(t, seasonSaves(0));
      await openArchive(t);
      await tapText(t, 'BEGIN SEASON ONE', after: const Duration(milliseconds: 1500));
      expect(path(), Routes.seasonFromArchive);
      expect(find.text('SHADOWS\nOVER LONDON'), findsOneWidget, reason: 'the Season 1 cover');
      expect(find.text('BEGIN SEASON ONE'), findsOneWidget);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('the board opened directly still goes back to the title (arrow and system back)', (t) async {
      await pumpApp(t, seasonSaves(4));
      appRef.read(routerProvider).go(Routes.season);
      await wait(t, const Duration(milliseconds: 1400));
      await t.tap(find.byTooltip('Back'));
      await wait(t);
      expect(path(), Routes.start);
      appRef.read(routerProvider).go(Routes.season);
      await wait(t, const Duration(milliseconds: 1400));
      await t.binding.handlePopRoute();
      await wait(t);
      expect(path(), Routes.start);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('Season 2 playable (stand-in cases and map): BEGIN SEASON TWO plays it; Season 1 kept', (t) async {
      await pumpApp(t, seasonSaves(12), extra: [
        allEpisodesProvider.overrideWithValue(withParis),
        seasonMapsProvider.overrideWithValue(withParisMap),
      ]);
      final prefs = appRef.read(sharedPreferencesProvider);
      final season1 = prefs.getString(savedKey(prefs, AppConstants.seasonStorageKey));
      await openArchive(t);
      await reveal(t, find.text('BEGIN SEASON TWO'));
      await tapText(t, 'BEGIN SEASON TWO', after: const Duration(milliseconds: 1500));
      expect(path(), Routes.seasonFromArchive);
      expect(appRef.read(selectedSeasonIdProvider), SeasonIds.paris);
      expect(appRef.read(currentEpisodeProvider).id, 's2_ep01');
      expect(prefs.getString(savedKey(prefs, AppConstants.seasonStorageKey)), season1);
      await wait(t, const Duration(seconds: 3));
    });
  });

  group('the ways in', () {
    for (final size in const [Size(360, 640), Size(390, 844)]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}: the completed board opens the archives', (t) async {
        await pumpApp(t, seasonSaves(12), size: size);
        appRef.read(routerProvider).go(Routes.season);
        await wait(t, const Duration(milliseconds: 2400));
        // The case files stay on screen; on a larger phone the archives too.
        // On the smallest the board page scrolls to them (it always scrolls).
        expect(t.getRect(find.text('VIEW ALL CASE FILES')).bottom, lessThanOrEqualTo(size.height));
        if (size.height > 640) expect(t.getRect(find.text('OPEN THE ARCHIVE')).bottom, lessThanOrEqualTo(size.height));
        expect(t.takeException(), isNull);
        await tapText(t, 'OPEN THE ARCHIVE');
        expect(path(), Routes.seasons);
        await wait(t, const Duration(seconds: 3));
      });
    }

    testWidgets('the map menu opens the archives', (t) async {
      await pumpApp(t, seasonSaves(0, activeBegun: true));
      appRef.read(routerProvider).go(Routes.map);
      await wait(t, const Duration(milliseconds: 1400));
      await t.tap(find.byTooltip('Menu'));
      await wait(t);
      await tapText(t, 'World Archive');
      expect(path(), Routes.seasons);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('CONTINUE with no case under way: the board while one season can be played', (t) async {
      // Case 05 open, not begun (opening it gave its save the detective's name).
      await pumpApp(t, {
        ...seasonSaves(4),
        AppConstants.progressKeyFor('ep05'): jsonEncode(const GameProgress(detectiveName: 'MINYOUNG').toJson()),
      });
      await wait(t, const Duration(milliseconds: 1200)); // the title comes in
      await tapText(t, 'CONTINUE ADVENTURE', after: const Duration(milliseconds: 1200));
      expect(path(), Routes.season, reason: 'no archives in between with one season');
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('CONTINUE with two seasons that can be played: the archives, to choose', (t) async {
      await pumpApp(t, seasonSaves(12), extra: [
        allEpisodesProvider.overrideWithValue(withParis),
        seasonMapsProvider.overrideWithValue(withParisMap),
      ]);
      // A solved case is shown again first, as always: from its last case's
      // result, Season 1 has no case under way.
      appRef.read(gameControllerProvider.notifier).playAgain();
      await wait(t, const Duration(milliseconds: 1200)); // the title comes in
      await tapText(t, 'CONTINUE ADVENTURE', after: const Duration(milliseconds: 1200));
      expect(path(), Routes.seasons);
      await wait(t, const Duration(seconds: 3));
    });
  });

  group('small and large phones', () {
    for (final size in const [Size(360, 640), Size(390, 844), Size(430, 932)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';
      for (final solved in [0, 4, 12]) {
        testWidgets('$tag, $solved solved: no overflow, every file reachable', (t) async {
          await pumpApp(t, seasonSaves(solved, activeBegun: solved == 4), size: size);
          await openArchive(t);
          expect(t.takeException(), isNull);
          // The title and Season 1's way in are on screen without scrolling.
          final title = t.getRect(find.text('WORLD MYSTERY'));
          expect(title.top, greaterThanOrEqualTo(0));
          final button = find.text(switch (solved) {
            0 => 'BEGIN SEASON ONE',
            12 => 'REVIEW THE FILE',
            _ => 'CONTINUE THE FILE',
          });
          await reveal(t, button);
          final r = t.getRect(button);
          expect(r.bottom, lessThanOrEqualTo(size.height));
          expect(r.right, lessThanOrEqualTo(size.width));
          await reveal(t, file(SeasonIds.paris));
          expect(t.getRect(file(SeasonIds.paris)).right, lessThanOrEqualTo(size.width));
          expect(t.takeException(), isNull);
          await wait(t, const Duration(seconds: 3));
        });
      }
    }
  });

  test('the files are worked out from the saves, not written in the page', () async {
    SharedPreferences.setMockInitialValues(seasonSaves(4, activeBegun: true));
    final c = ProviderContainer(overrides: await testOverridesFor(await SharedPreferences.getInstance()));
    addTearDown(c.dispose);
    final files = c.read(seasonFilesProvider);
    expect([for (final f in files) f.season.id], [SeasonIds.london, SeasonIds.paris]);
    expect(files.first.state, SeasonFileState.inProgress);
    expect(files.first.availability.solvedCount, 4);
    expect(files.first.current, isTrue);
    expect(files.last.state, SeasonFileState.sealed);
    expect(files.last.before!.id, SeasonIds.london);
  });
}

