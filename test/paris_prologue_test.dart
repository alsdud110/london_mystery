import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/mock/season2/season2_mock.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/widgets/art_assets.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'multi_season_test.dart' show assetOf;

void main() {
  final ids = [for (final e in MockEpisodeRepository.bundled()) e.id];

  /// A detective with Season 1 [solved] cases solved (12: finished).
  Map<String, Object> saves({int solved = 0}) => {
    AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINYOUNG', introSeen: true).toJson()),
    AppConstants.seasonStorageKey: jsonEncode(
      SeasonProgress(activeEpisodeId: 'ep01', solvedEpisodeIds: ids.take(solved).toList()).toJson(),
    ),
  };

  late WidgetRef appRef;
  String path() => appRef.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

  Future<void> pumpApp(WidgetTester t, {Size size = const Size(360, 640), int solved = 0, List<Override> extra = const []}) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: [...await testOverrides(prefs: saves(solved: solved)), ...extra],
      child: Consumer(builder: (context, ref, _) {
        appRef = ref;
        return const LondonMysteryApp();
      }),
    ));
    await wait(t, const Duration(milliseconds: 300));
  }

  Future<void> openPrologue(WidgetTester t) async {
    appRef.read(routerProvider).go(Routes.parisPrologue);
    await wait(t, const Duration(milliseconds: 2000)); // the first scene comes in
  }

  Map<String, Object?> stored() {
    final prefs = appRef.read(sharedPreferencesProvider);
    return {for (final k in prefs.getKeys()) k: prefs.get(k)};
  }

  /// Every text on screen, lower case.
  String screenText(WidgetTester t) => [
    for (final w in t.widgetList<Text>(find.byType(Text))) (w.data ?? w.textSpan?.toPlainText() ?? '').toLowerCase(),
  ].join(' | ');

  bool showsAsset(WidgetTester t, String asset) =>
      find.byWidgetPredicate((w) => w is Image && assetOf(w.image) == asset).evaluate().isNotEmpty;

  Future<void> next(WidgetTester t) async {
    await t.tap(find.text('NEXT ›'));
    await wait(t, const Duration(milliseconds: 2400));
  }

  group('the scenes', () {
    testWidgets('one to six, in order, with Season 2\'s own words', (t) async {
      await pumpApp(t);
      await openPrologue(t);
      expect(path(), Routes.parisPrologue);
      // 1 — the last clue: the watch from London, PARIS on its back.
      expect(find.text('THE LAST CLUE'), findsOneWidget);
      expect(find.text('PARIS'), findsOneWidget);
      expect(find.text('The Clockmaker is gone.'), findsOneWidget);
      expect(find.text('But his watch is still ticking.'), findsOneWidget);
      expect(showsAsset(t, ArtAssets.objects['pocketWatch']!), isTrue);
      await next(t);
      // 2 — the journey: his train to London, the detective's ticket back.
      expect(find.text('THE JOURNEY'), findsOneWidget);
      expect(find.text('He came to London\non the 11:40 from Paris.'), findsOneWidget);
      expect(find.text('Now you follow him back.'), findsOneWidget);
      expect(find.text('DETECTIVE MINYOUNG'), findsOneWidget, reason: 'the ticket is in the detective\'s name');
      await next(t);
      // 3 — Gare du Nord: its hall, full screen.
      expect(find.text('GARE DU NORD'), findsOneWidget);
      expect(find.text('Look up at the station clocks...'), findsOneWidget);
      expect(showsAsset(t, ArtAssets.season2GareDuNord), isTrue);
      expect(showsAsset(t, ArtAssets.parisMap), isFalse, reason: 'the station, not the map');
      await next(t);
      // 4 — the missing hour.
      expect(find.text('THE MISSING HOUR'), findsOneWidget);
      expect(find.text('10:00'), findsNWidgets(2));
      expect(find.text('9:00'), findsOneWidget);
      // The case and its mystery: an hour gone, and who took it.
      expect(find.text('One hour is missing in Paris.'), findsOneWidget);
      expect(find.text('Who took it? And why?'), findsOneWidget);
      await next(t);
      // 5 — the promise: the detective's goal for the season.
      expect(find.text('Follow the clues. Find out who took the hour.'), findsOneWidget);
      expect(find.text('SEASON TWO'), findsOneWidget);
      expect(find.text('PARIS STANDS STILL'), findsOneWidget);
      expect(find.text('12 CASES'), findsOneWidget);
      expect(find.text('ONE STOLEN HOUR'), findsOneWidget);
      expect(find.text('NEXT ›'), findsNothing);
      await t.tap(find.text('ACCEPT THE CASE'));
      await wait(t, const Duration(milliseconds: 2000));
      // 6 — Case 01's file.
      expect(find.text('CASE 01'), findsOneWidget);
      expect(find.text('THE TICKING WATCH'), findsOneWidget);
      expect(find.text('GARE DU NORD'), findsOneWidget);
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('Gare du Nord\'s picture is decoded once while the camera moves in', (t) async {
      await pumpApp(t);
      await openPrologue(t);
      await next(t); // the journey
      await t.tap(find.text('NEXT ›')); // into the station: its scene starts
      final sizes = <int?>{};
      for (var i = 0; i < 12; i++) {
        await t.pump(const Duration(milliseconds: 120));
        for (final w in t.widgetList<Image>(find.byType(Image))) {
          if (assetOf(w.image) == ArtAssets.season2GareDuNord) {
            sizes.add(w.image is ResizeImage ? (w.image as ResizeImage).width : null);
          }
        }
      }
      expect(sizes, hasLength(1), reason: 'one decode size through the push: $sizes');
      expect(sizes.single, isNotNull);
      expect(sizes.single!, lessThanOrEqualTo(ArtAssets.season2GareDuNordPixels.width));
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('a tap finishes a scene first; BACK goes a scene back; SKIP goes to the promise', (t) async {
      await pumpApp(t);
      appRef.read(routerProvider).go(Routes.parisPrologue);
      await wait(t, const Duration(milliseconds: 500)); // the route has faded in
      await t.tap(find.text('NEXT ›')); // the watch's scene is still coming in
      await t.pump(const Duration(milliseconds: 50));
      expect(find.text('THE LAST CLUE'), findsOneWidget, reason: 'the first tap only finishes the scene');
      await t.tap(find.text('NEXT ›'));
      await wait(t, const Duration(milliseconds: 2000));
      expect(find.text('THE JOURNEY'), findsOneWidget);
      await t.tap(find.byTooltip('Back'));
      await wait(t);
      expect(find.text('THE LAST CLUE'), findsOneWidget);
      await t.binding.handlePopRoute(); // Android back, from the first scene: out
      await wait(t);
      expect(path(), Routes.seasons, reason: 'not played yet: back to the archives');
      await openPrologue(t);
      await t.tap(find.text('SKIP ›'));
      await wait(t, const Duration(milliseconds: 1600));
      expect(find.text('ACCEPT THE CASE'), findsOneWidget);
      expect(find.text('SKIP ›'), findsNothing);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('nothing of London\'s opening: its pictures and words stay in Season 1', (t) async {
      await pumpApp(t);
      await openPrologue(t);
      for (var scene = 1; scene <= 6; scene++) {
        final text = screenText(t);
        for (final london in ['something strange', 'one mystery', 'shadows over london', 'your first investigation', 'big ben']) {
          expect(text, isNot(contains(london)), reason: 'scene $scene');
        }
        for (final picture in [ArtAssets.londonMap, ArtAssets.season1LondonNight, ArtAssets.season1CoverLondonPanorama]) {
          expect(showsAsset(t, picture), isFalse, reason: 'scene $scene');
        }
        if (scene < 5) {
          await next(t);
        } else if (scene == 5) {
          await t.tap(find.text('ACCEPT THE CASE'));
          await wait(t, const Duration(milliseconds: 2000));
        }
      }
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('Season 1\'s opening is as it was', (t) async {
      await pumpApp(t);
      appRef.read(routerProvider).go(Routes.prologue);
      await wait(t, const Duration(milliseconds: 2000));
      expect(find.text('LONDON'), findsOneWidget);
      expect(find.text('Something strange is happening\nacross the city.'), findsOneWidget);
      expect(find.text('THE LAST CLUE'), findsNothing);
      await wait(t, const Duration(seconds: 3));
    });
  });

  group('Case 01 not in the game yet', () {
    testWidgets('no way into it: COMING SOON, back to the archives; nothing saved, Season 2 still coming soon', (t) async {
      // Paris not yet released: the opening shown in an operator build only.
      await pumpApp(t, solved: 12, extra: [parisNotYetReleased]);
      final before = stored();
      await openPrologue(t);
      await t.tap(find.text('SKIP ›'));
      await wait(t, const Duration(milliseconds: 1600));
      await t.tap(find.text('ACCEPT THE CASE'));
      await wait(t, const Duration(milliseconds: 2000));
      expect(find.text('COMING SOON'), findsOneWidget);
      expect(find.text('ASSIGNED'), findsNothing);
      expect(find.textContaining('START CASE'), findsNothing, reason: 'no button into a case that is not there');
      await t.tap(find.text('BACK TO THE ARCHIVE'));
      await wait(t, const Duration(milliseconds: 1400));
      expect(path(), Routes.seasons);
      expect(appRef.read(selectedSeasonIdProvider), SeasonIds.london);
      expect(appRef.read(currentEpisodeProvider).seasonId, SeasonIds.london);
      final paris = appRef.read(seasonAvailabilityProvider(SeasonIds.paris))!;
      expect(paris.status, SeasonStatus.comingSoon);
      expect(paris.canEnter, isFalse);
      expect(stored(), before, reason: 'the opening saves nothing');
      await wait(t, const Duration(seconds: 3));
    });

    test('its words name the case the opening hands over', () {
      final first = season2PrologueJson['firstCase'] as Map<String, dynamic>;
      expect(first['id'], 's2_ep01');
      expect(first['title'], 'The Ticking Watch');
      expect(first['place'], 'GARE DU NORD');
      expect(ArtAssets.objects[first['picture']], isNotNull, reason: 'a picture the game has');
    });
  });

  group('who may see it', () {
    testWidgets('a build without operator tools (release) never opens it: Season 2 stays shut', (t) async {
      await pumpApp(t, solved: 12, extra: [operatorToolsAvailableProvider.overrideWithValue(false)]);
      appRef.read(routerProvider).go(Routes.parisPrologue);
      await wait(t, const Duration(milliseconds: 1400));
      expect(path(), Routes.seasons);
      expect(find.text('THE LAST CLUE'), findsNothing);
      await wait(t, const Duration(seconds: 3));
    });
  });

  group('small and large phones', () {
    for (final size in const [Size(360, 640), Size(390, 844), Size(430, 932)]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}: every scene fits, its way on on screen', (t) async {
        await pumpApp(t, size: size);
        await openPrologue(t);
        for (var scene = 1; scene <= 6; scene++) {
          expect(t.takeException(), isNull, reason: 'scene $scene');
          final way = find.text(scene < 5 ? 'NEXT ›' : scene == 5 ? 'ACCEPT THE CASE' : 'BACK TO THE ARCHIVE');
          final r = t.getRect(way);
          expect(r.bottom, lessThanOrEqualTo(size.height), reason: 'scene $scene');
          expect(r.right, lessThanOrEqualTo(size.width), reason: 'scene $scene');
          if (scene < 5) {
            await next(t);
          } else if (scene == 5) {
            await t.tap(find.text('ACCEPT THE CASE'));
            await wait(t, const Duration(milliseconds: 2000));
          }
        }
        await wait(t, const Duration(seconds: 3));
      });
    }
  });
}
