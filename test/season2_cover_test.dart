import 'dart:convert';
import 'dart:io';

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
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/widgets/art_assets.dart';

import 'full_playthrough_test.dart' show reveal, wait;
import 'helpers.dart';
import 'multi_season_test.dart' show asReleased, assetOf, withParis, withParisMap;

void main() {
  final ids = [for (final e in MockEpisodeRepository.bundled()) e.id];
  const paris = ArtAssets.season2CoverParisPanorama;
  const london = ArtAssets.season1CoverLondonPanorama;

  /// [begun]: Case 01's story read (the season page is its board, not its cover).
  Map<String, Object> saves({int solved = 0, bool begun = true}) => {
    AppConstants.progressStorageKey: jsonEncode(GameProgress(detectiveName: 'MINYOUNG', introSeen: begun).toJson()),
    AppConstants.seasonStorageKey: jsonEncode(
      SeasonProgress(activeEpisodeId: 'ep01', solvedEpisodeIds: ids.take(solved).toList()).toJson(),
    ),
  };

  late WidgetRef appRef;
  String path() => appRef.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

  Future<void> pumpApp(
    WidgetTester t, {
    Size size = const Size(360, 640),
    int solved = 0,
    bool begun = true,
    List<Override> extra = const [],
  }) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: [...await testOverrides(prefs: saves(solved: solved, begun: begun)), ...extra],
      child: Consumer(builder: (context, ref, _) {
        appRef = ref;
        return const LondonMysteryApp();
      }),
    ));
    await wait(t, const Duration(milliseconds: 300));
  }

  /// The pictures built now, on screen or scrolled to.
  bool shows(WidgetTester t, String asset) => find
      .byWidgetPredicate((w) => w is Image && assetOf(w.image) == asset, skipOffstage: false)
      .evaluate()
      .isNotEmpty;

  Finder parisFile() => find.byKey(const ValueKey('season-file-s2_paris'));

  test('the Season 2 cover is in the game, at its size, its folder bundled', () {
    final file = File(paris);
    expect(file.existsSync(), isTrue);
    final png = file.readAsBytesSync();
    int u32(int at) => (png[at] << 24) | (png[at + 1] << 16) | (png[at + 2] << 8) | png[at + 3];
    expect(png.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    expect((u32(16), u32(20)), (941, 1671));
    expect(ArtAssets.season2CoverParisPanoramaPixels.width, 941);
    expect(ArtAssets.season2CoverParisPanoramaPixels.height, 1671);
    expect(ArtAssets.seasonCovers[SeasonIds.paris]!.$1, paris);
    expect(ArtAssets.seasonCovers[SeasonIds.london]!.$1, london, reason: 'London\'s cover unchanged');
    expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/seasons/season_02_paris/cover/'));
  });

  group('the archives', () {
    testWidgets('sealed: the Paris cover never shows (it names the city)', (t) async {
      await pumpApp(t);
      appRef.read(routerProvider).go(Routes.seasons);
      await wait(t, const Duration(milliseconds: 1400));
      await reveal(t, parisFile());
      expect(find.text('SEALED FILE'), findsOneWidget);
      expect(shows(t, paris), isFalse);
      expect(shows(t, london), isTrue, reason: 'Season 1\'s file keeps its cover');
      await wait(t, const Duration(seconds: 3));
    });

    for (final size in const [Size(360, 640), Size(390, 844), Size(430, 932)]) {
      testWidgets('${size.width.toInt()}: unsealed, coming soon: the Paris cover on its file, still shut', (t) async {
        await pumpApp(t, size: size, solved: 12);
        appRef.read(routerProvider).go(Routes.seasons);
        await wait(t, const Duration(milliseconds: 1400));
        await reveal(t, parisFile());
        expect(find.text('COMING SOON'), findsOneWidget);
        expect(shows(t, paris), isTrue);
        expect(t.takeException(), isNull);
        final r = t.getRect(parisFile());
        expect(r.right, lessThanOrEqualTo(size.width));
        await t.tap(parisFile());
        await wait(t, const Duration(milliseconds: 400));
        expect(path(), Routes.seasons);
        expect(appRef.read(selectedSeasonIdProvider), SeasonIds.london);
        await wait(t, const Duration(seconds: 3));
      });
    }
  });

  group('the Season 2 cover page (played as released, its map, a stand-in Case 02: tests only)', () {
    for (final size in const [Size(360, 640), Size(390, 844), Size(430, 932)]) {
      testWidgets('${size.width.toInt()}: Paris\'s cover, its title, BEGIN into its own opening', (t) async {
        await pumpApp(t, size: size, solved: 12, extra: [
          allEpisodesProvider.overrideWithValue(withParis),
          seasonMapsProvider.overrideWithValue(withParisMap),
          asReleased,
        ]);
        expect(appRef.read(gameControllerProvider.notifier).openSeason(SeasonIds.paris), isTrue);
        appRef.read(routerProvider).go(Routes.season);
        await wait(t, const Duration(milliseconds: 2000));
        expect(shows(t, paris), isTrue);
        expect(shows(t, london), isFalse);
        expect(find.text('PARIS STANDS STILL'), findsOneWidget);
        expect(find.text('SEASON TWO'), findsOneWidget);
        final begin = find.text('BEGIN SEASON TWO');
        expect(begin, findsOneWidget);
        expect(t.getRect(begin).bottom, lessThanOrEqualTo(size.height));
        expect(t.takeException(), isNull);
        await t.tap(begin);
        await wait(t, const Duration(milliseconds: 1400));
        expect(path(), Routes.parisPrologue);
        expect(find.text('THE LAST CLUE'), findsOneWidget);
        await wait(t, const Duration(seconds: 3));
      });
    }

    testWidgets('Season 1\'s cover page is as it was: London, BEGIN into its own opening', (t) async {
      await pumpApp(t, begun: false);
      appRef.read(routerProvider).go(Routes.season);
      await wait(t, const Duration(milliseconds: 2000));
      expect(shows(t, london), isTrue);
      expect(shows(t, paris), isFalse);
      await t.tap(find.text('BEGIN SEASON ONE'));
      await wait(t, const Duration(milliseconds: 1400));
      expect(path(), Routes.prologue);
      await wait(t, const Duration(seconds: 3));
    });
  });
}
