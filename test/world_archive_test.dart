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
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/game/wallet_controller.dart';
import 'package:world_mystery/features/season/world_archive_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';
import 'multi_season_test.dart' show asReleased, withParis, withParisMap;

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
        return const WorldMysteryApp();
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
      // Its own file (Rome's, after it, is sealed too: by Paris).
      expect(find.descendant(of: file(SeasonIds.paris), matching: find.text('SEALED FILE')), findsOneWidget);
      expect(find.descendant(of: file(SeasonIds.paris), matching: find.text('SEALED')), findsOneWidget);
      expect(find.text('Solve Shadows over London to unseal this file.'), findsOneWidget);
      await reveal(t, file(SeasonIds.rome));
      expect(find.descendant(of: file(SeasonIds.rome), matching: find.text('Solve the season before it to unseal this file.')), findsOneWidget);
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
      expect(find.descendant(of: file(SeasonIds.paris), matching: find.text('SEALED FILE')), findsOneWidget);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('Season 1 solved, Paris not yet released: SOLVED, REVIEW THE FILE; Season 2 named and coming soon', (t) async {
      await pumpApp(t, seasonSaves(12), extra: [parisNotYetReleased]);
      await openArchive(t);
      expect(find.text('12 / 12'), findsOneWidget);
      expect(find.text('SOLVED'), findsOneWidget);
      expect(find.text('REVIEW THE FILE'), findsOneWidget);
      await reveal(t, file(SeasonIds.paris));
      expect(find.text('PARIS STANDS STILL'), findsOneWidget);
      expect(find.text('ONE STOLEN HOUR'), findsOneWidget);
      expect(find.descendant(of: file(SeasonIds.paris), matching: find.text('COMING SOON')), findsOneWidget);
      expect(find.descendant(of: file(SeasonIds.paris), matching: find.text('SEALED FILE')), findsNothing);
      expect(find.text('BEGIN SEASON TWO'), findsNothing, reason: 'not released yet');
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('three seasons or more: the archives scroll to every file', (t) async {
      // After New York (Season 4): a fifth.
      const third = Season(id: 's5_test', number: 5, title: 'A Fifth City', tagline: 'ONE MORE', prologue: SeasonPrologue(), outro: [], figures: []);
      await pumpApp(t, seasonSaves(0), extra: [
        seasonsProvider.overrideWithValue([
          for (final s in SeasonCatalog.all) s.season,
          third,
        ]),
      ]);
      await openArchive(t);
      expect(file('s5_test').hitTestable(), findsNothing, reason: 'below the fold');
      await reveal(t, file(SeasonIds.rome));
      expect(find.text('SEASON THREE'), findsOneWidget);
      await reveal(t, file(SeasonIds.newyork));
      expect(find.text('SEASON FOUR'), findsOneWidget);
      await reveal(t, file('s5_test'));
      expect(find.text(third.label), findsOneWidget);
      expect(find.text('A FIFTH CITY'), findsNothing, reason: 'sealed: its season before is not solved');
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

    testWidgets('coming soon (Paris not yet released): still being prepared, Season 1 stays the one played', (t) async {
      await pumpApp(t, seasonSaves(12), extra: [parisNotYetReleased]);
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
      // The archives go back to the World Map, both ways (and the map to
      // the title: no loop between the two).
      await t.tap(find.byTooltip('Back'));
      await wait(t);
      expect(path(), Routes.worldMap);
      await openArchive(t);
      await t.binding.handlePopRoute();
      await wait(t);
      expect(path(), Routes.worldMap);
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

    testWidgets('the board opened directly goes back to the World Map (arrow and system back)', (t) async {
      await pumpApp(t, seasonSaves(4, activeBegun: true));
      appRef.read(routerProvider).go(Routes.season);
      await wait(t, const Duration(milliseconds: 1400));
      await t.tap(find.byTooltip('Back'));
      await wait(t);
      expect(path(), Routes.worldMap);
      appRef.read(routerProvider).go(Routes.season);
      await wait(t, const Duration(milliseconds: 1400));
      await t.binding.handlePopRoute();
      await wait(t);
      expect(path(), Routes.worldMap);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('Season 2 playable (as released, a stand-in Case 02): BEGIN SEASON TWO plays it; Season 1 kept', (t) async {
      await pumpApp(t, seasonSaves(12), extra: [
        allEpisodesProvider.overrideWithValue(withParis),
        seasonMapsProvider.overrideWithValue(withParisMap),
        asReleased,
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
      testWidgets('${size.width.toInt()}x${size.height.toInt()}: the completed board, Season 2 not yet released: coming soon, nothing to begin', (t) async {
        await pumpApp(t, seasonSaves(12), size: size, extra: [parisNotYetReleased]);
        appRef.read(routerProvider).go(Routes.season);
        await wait(t, const Duration(milliseconds: 2400));
        expect(find.text('SEASON TWO · COMING SOON'), findsOneWidget);
        expect(find.text('BEGIN SEASON TWO'), findsNothing, reason: 'never a button that cannot start it');
        expect(find.text('OPEN THE ARCHIVE'), findsNothing);
        expect(t.getRect(find.text('SEASON TWO · COMING SOON')).bottom, lessThanOrEqualTo(size.height));
        // The case files: on screen on a larger phone; on the smallest the
        // board page scrolls to them (it always scrolls).
        if (size.height > 640) expect(t.getRect(find.text('View Case Files')).bottom, lessThanOrEqualTo(size.height));
        expect(t.takeException(), isNull);
        await tapText(t, 'View Case Files');
        expect(path(), Routes.episodes);
        await wait(t, const Duration(seconds: 3));
      });

      testWidgets('${size.width.toInt()}x${size.height.toInt()}: the completed board, Season 2 out: GO TO PARIS opens its cover, no archive between', (t) async {
        await pumpApp(t, seasonSaves(12), size: size, extra: [
          allEpisodesProvider.overrideWithValue(withParis),
          seasonMapsProvider.overrideWithValue(withParisMap),
          asReleased,
        ]);
        final prefs = appRef.read(sharedPreferencesProvider);
        final season1 = prefs.getString(savedKey(prefs, AppConstants.seasonStorageKey));
        appRef.read(routerProvider).go(Routes.season);
        await wait(t, const Duration(milliseconds: 2400));
        expect(find.text('OPEN THE ARCHIVE'), findsNothing);
        final begin = find.byKey(const ValueKey('begin-next-season'));
        expect(begin, findsOneWidget);
        expect(t.getRect(begin).bottom, lessThanOrEqualTo(size.height), reason: 'the main action, on screen');
        expect(find.text('GO TO PARIS'), findsOneWidget, reason: 'named by the city');
        expect(find.text('BEGIN SEASON TWO'), findsNothing);
        expect(t.getRect(find.text('View Case Files')).height, lessThan(t.getRect(begin).height), reason: 'the quiet one');
        await t.tap(begin);
        await wait(t, const Duration(milliseconds: 1600));
        expect(path(), Routes.seasonOf(SeasonIds.paris));
        expect(appRef.read(selectedSeasonIdProvider), SeasonIds.paris);
        // Paris's cover, its BEGIN INVESTIGATION leading to its opening.
        expect(find.byKey(const ValueKey('begin-next-season')), findsNothing);
        expect(find.text('BEGIN INVESTIGATION'), findsOneWidget);
        expect(find.text('BEGIN SEASON TWO'), findsNothing);
        expect(prefs.getString(savedKey(prefs, AppConstants.seasonStorageKey)), season1, reason: 'Season 1 kept');
        await wait(t, const Duration(seconds: 3));
      });
    }

    testWidgets('the completed board, in an operator build\'s season preview: GO TO PARIS', (t) async {
      await pumpApp(t, seasonSaves(12), extra: [seasonPreviewProvider.overrideWithValue(true)]);
      appRef.read(routerProvider).go(Routes.season);
      await wait(t, const Duration(milliseconds: 2400));
      expect(find.byKey(const ValueKey('begin-next-season')), findsOneWidget);
      expect(find.text('SEASON TWO · COMING SOON'), findsNothing);
      await wait(t, const Duration(seconds: 3));
    });

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

    testWidgets('CONTINUE with no case under way: the World Map (one season can be played)', (t) async {
      // Case 05 open, not begun (opening it gave its save the detective's name).
      await pumpApp(t, {
        ...seasonSaves(4),
        AppConstants.progressKeyFor('ep05'): jsonEncode(const GameProgress(detectiveName: 'MINYOUNG').toJson()),
      });
      await wait(t, const Duration(milliseconds: 1200)); // the title comes in
      await tapText(t, 'CONTINUE ADVENTURE', after: const Duration(milliseconds: 1200));
      expect(path(), Routes.worldMap, reason: 'the World Map is the hub');
      expect(find.byKey(const ValueKey('city-card-london')), findsOneWidget);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('CONTINUE with two seasons that can be played: the World Map, Paris in the middle', (t) async {
      await pumpApp(t, seasonSaves(12), extra: [
        allEpisodesProvider.overrideWithValue(withParis),
        seasonMapsProvider.overrideWithValue(withParisMap),
        asReleased,
      ]);
      // A solved case is shown again first, as always: from its last case's
      // result, Season 1 has no case under way.
      appRef.read(gameControllerProvider.notifier).playAgain();
      await wait(t, const Duration(milliseconds: 1200)); // the title comes in
      await tapText(t, 'CONTINUE ADVENTURE', after: const Duration(milliseconds: 1200));
      expect(path(), Routes.worldMap);
      expect(find.byKey(const ValueKey('city-card-paris')), findsOneWidget, reason: 'London done: Paris is next');
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
    expect([for (final f in files) f.season.id], [SeasonIds.london, SeasonIds.paris, SeasonIds.rome, SeasonIds.newyork]);
    // Rome, two files on, never names Paris while London is under way; New
    // York, three on, never names Rome.
    expect(files[2].unsealNote, 'Solve the season before it to unseal this file.');
    expect(files.last.unsealNote, 'Solve the season before it to unseal this file.');
    expect(files[1].unsealNote, 'Solve Shadows over London to unseal this file.');
    expect(files.first.state, SeasonFileState.inProgress);
    expect(files.first.availability.solvedCount, 4);
    expect(files.first.current, isTrue);
    expect(files[2].state, SeasonFileState.sealed);
    expect(files.last.state, SeasonFileState.sealed);
    expect(files[1].before!.id, SeasonIds.london);
    expect(files[2].before!.id, SeasonIds.paris);
    expect(files.last.before!.id, SeasonIds.rome);
  });
}

