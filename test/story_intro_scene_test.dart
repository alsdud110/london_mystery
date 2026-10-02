import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/landmark_art.dart';

import 'full_playthrough_test.dart' show tapText, wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// The story intro of every case: its narration over the place it opens on
/// (or the London map), the I'M READY button in the game's cinematic style.
/// Set LM_SCREENSHOTS to a folder to save pictures.
void main() {
  final catalog = MockEpisodeRepository.bundled();

  setUpAll(() async {
    for (final (family, files) in [
      ('Nunito', ['Nunito.ttf']),
      ('Cinzel', ['Cinzel.ttf']),
      ('LibreBaskerville', ['LibreBaskerville.ttf', 'LibreBaskerville-Italic.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await loader.load();
    }
  });

  test('every case opens on a picture of the place its intro names, or the London map', () {
    final expected = <String, Artwork?>{
      'ep01': null, // the Royal Archive has no picture yet: the London map
      'ep02': Artwork.bigBen,
      'ep03': Artwork.britishMuseum,
      'ep04': Artwork.kingsCross,
      'ep05': Artwork.towerOfLondon,
      'ep06': Artwork.coventGarden,
      'ep07': Artwork.hydePark,
      'ep08': Artwork.kingsCross,
      'ep09': Artwork.buckinghamPalace,
      'ep10': Artwork.towerOfLondon,
      'ep11': Artwork.coventGarden,
      'ep12': Artwork.bigBen,
    };
    for (final e in catalog) {
      expect(e.introScene, expected[e.id], reason: e.id);
      if (e.introScene != null) expect(LandmarkArt.hasPicture(e.introScene!), isTrue, reason: '${e.id} has its picture');
    }
    // Never the season's own pictures (kept for the cover and the opening).
    for (final e in catalog) {
      final file = e.introScene == null ? null : ArtAssets.scene(e.introScene!);
      expect(file, isNot(anyOf(ArtAssets.season1LondonNight, ArtAssets.season1CoverLondonPanorama)));
    }
  });

  testWidgets('Case 01: the file → START CASE 01 → the story over London → I\'M READY → the map', (t) async {
    t.view.physicalSize = const Size(360, 640) * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(prefs: {
        AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'KIM').toJson()),
      }),
      child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
    ));
    await wait(t, const Duration(milliseconds: 300));
    final router = find.byType(LondonMysteryApp).evaluate().first;
    ProviderScope.containerOf(router).read(routerProvider).go(Routes.prologue);
    await wait(t, const Duration(milliseconds: 600));
    await tapText(t, 'SKIP ›', after: const Duration(milliseconds: 1600));
    await tapText(t, 'ACCEPT THE CASE', after: const Duration(milliseconds: 1600));
    await tapText(t, 'START CASE 01', after: const Duration(milliseconds: 600));
    expect(find.text('London, 10:42 PM...'), findsOneWidget, reason: "Case 01's own story, unchanged");
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
    await wait(t, const Duration(milliseconds: 1400));
    await capture(t, 'intro_ep01_reading_360x640');
    await tapText(t, 'SKIP ›', after: const Duration(milliseconds: 900));
    expect(find.text('Are you ready?'), findsOneWidget);
    await capture(t, 'intro_ep01_ready_360x640');
    await tapText(t, "I'M READY", after: const Duration(milliseconds: 1500));
    expect(ProviderScope.containerOf(router).read(routerProvider).routerDelegate.currentConfiguration.uri.path, Routes.map);
    await wait(t, const Duration(seconds: 3));
  });

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    for (final e in catalog) {
      final tag = '${e.id}_${size.width.toInt()}x${size.height.toInt()}';
      testWidgets('story intro $tag: narration over its place, I\'M READY on screen', (t) async {
        t.view.physicalSize = size * 3;
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.reset);
        final solved = [for (final c in catalog.takeWhile((c) => c.id != e.id)) c.id];
        await t.pumpWidget(ProviderScope(
          overrides: await testOverrides(prefs: {
            AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'KIM').toJson()),
            if (e.id != AppConstants.currentEpisodeId)
              AppConstants.progressKeyFor(e.id): jsonEncode(const GameProgress(detectiveName: 'KIM').toJson()),
            AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: e.id, solvedEpisodeIds: solved).toJson()),
          }),
          child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
        ));
        await wait(t, const Duration(milliseconds: 300));
        final app = find.byType(LondonMysteryApp).evaluate().first;
        ProviderScope.containerOf(app).read(routerProvider).go(Routes.intro);
        await wait(t, const Duration(milliseconds: 600)); // the intro is built: its picture is asked for
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600))); // and decoded
        await wait(t, const Duration(milliseconds: 1000));
        expect(t.takeException(), isNull);
        expect(find.text(e.intro.first), findsOneWidget, reason: 'its own first line');
        // The place behind the words: its picture, or the London map.
        if (e.introScene != null) {
          expect(find.byWidgetPredicate((w) => w is LandmarkArt && w.artwork == e.introScene), findsOneWidget);
        } else {
          expect(
            find.byWidgetPredicate((w) =>
                w is Image &&
                w.image is ResizeImage &&
                ((w.image as ResizeImage).imageProvider as AssetImage).assetName == ArtAssets.londonMap),
            findsOneWidget,
          );
        }
        if (size.width == 360 || e.id == 'ep01') await capture(t, 'intro_${tag}_reading');
        await tapText(t, 'SKIP ›', after: const Duration(milliseconds: 900));
        expect(find.text('Are you ready?'), findsOneWidget);
        final ready = t.getRect(find.text("I'M READY"));
        expect(ready.bottom, lessThan(size.height - 20), reason: 'off the bottom edge');
        if (size.width == 360 || e.id == 'ep01') await capture(t, 'intro_${tag}_ready');
        await wait(t, const Duration(seconds: 1));
      });
    }
  }
}
