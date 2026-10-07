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
import 'package:london_mystery/widgets/place_art.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// The story scene after each mission shows the place it unlocks: its own
/// picture, or the London map for a place pinned at another landmark.
void main() {
  test('every story scene has the picture of the place it unlocks', () {
    var scenes = 0;
    for (final e in MockEpisodeRepository.bundled()) {
      for (final m in e.missions) {
        final next = m.nextMissionId == null ? null : e.missionById(m.nextMissionId!);
        if (next == null) continue;
        scenes++;
        final scenery = PlaceArt.sceneryOf(next);
        if (next.id == 'final') {
          expect(scenery, Artwork.royalArchive, reason: 'the Royal Archive, not the palace it is pinned at');
        }
        expect(scenery, PlaceArt.placeOf(next), reason: '${m.id}: the same place as its unlocked card');
        expect(LandmarkArt.hasPicture(scenery!), isTrue, reason: '${m.id} → ${next.location} has a picture');
        // Never the season's own pictures (the cover and the opening keep them).
        expect(ArtAssets.scene(scenery), isNot(anyOf(ArtAssets.season1LondonNight, ArtAssets.season1CoverLondonPanorama)));
      }
    }
    expect(scenes, 38, reason: 'Case 01: 5, Cases 02-12: 3 each');
    // Case 01's first scene opens on the British Museum.
    final e1 = MockEpisodeRepository.bundled().first;
    expect(PlaceArt.sceneryOf(e1.missionById('m02')!), Artwork.britishMuseum);
  });

  setUpAll(() async {
    for (final (family, files) in [
      ('Sentient', ['Sentient-Variable.ttf']),
      ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
      ('LibreBaskerville', ['LibreBaskerville.ttf', 'LibreBaskerville-Italic.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await loader.load();
    }
  });

  // On screen: the scene's place behind the words, the unlocked card, TO THE MAP.
  final catalog = MockEpisodeRepository.bundled();
  for (final size in const [Size(360, 640), Size(390, 844)]) {
    for (final (episodeId, missionId) in const [('ep01', 'm01'), ('ep01', 'm02'), ('ep01', 'm05'), ('ep03', 'ep03_m1'), ('ep07', 'ep07_m2')]) {
      final tag = '${missionId}_${size.width.toInt()}x${size.height.toInt()}';
      testWidgets('story scene $tag: its place fills the screen, the card and TO THE MAP', (t) async {
        t.view.physicalSize = size * 3;
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.reset);
        final e = catalog.firstWhere((c) => c.id == episodeId);
        final upTo = e.missions.indexWhere((m) => m.id == missionId) + 1;
        final solved = [for (final c in catalog.takeWhile((c) => c.id != episodeId)) c.id];
        await t.pumpWidget(ProviderScope(
          overrides: await testOverrides(prefs: {
            AppConstants.progressKeyFor(episodeId): jsonEncode(GameProgress(
              detectiveName: 'MINYOUNG',
              introSeen: true,
              completedMissionIds: [for (final m in e.missions.take(upTo)) m.id],
              startedAt: DateTime(2026, 9, 29, 10),
              playMillis: 0,
            ).toJson()),
            if (episodeId != AppConstants.currentEpisodeId)
              AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINYOUNG').toJson()),
            AppConstants.seasonStorageKey:
                jsonEncode(SeasonProgress(activeEpisodeId: episodeId, solvedEpisodeIds: solved).toJson()),
          }),
          child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
        ));
        await wait(t, const Duration(milliseconds: 300));
        ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first).read(routerProvider).go(Routes.story(missionId));
        await wait(t, const Duration(milliseconds: 600));
        await t.tapAt(Offset(size.width / 2, size.height / 2)); // the whole story at once
        await wait(t, const Duration(milliseconds: 900));
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 800))); // decode the pictures
        await wait(t, const Duration(milliseconds: 300));
        expect(t.takeException(), isNull);
        final next = e.missionById(e.missions[upTo - 1].nextMissionId!)!;
        final scenery = PlaceArt.sceneryOf(next);
        if (scenery != null) {
          // Full screen: the scenery, and the small one on the card.
          final full = find.byWidgetPredicate((w) => w is LandmarkArt && w.artwork == scenery && !w.showName);
          expect(full, findsOneWidget);
          expect(t.getRect(full), Offset.zero & size, reason: 'the place fills the screen');
        }
        expect(find.text(next.location), findsOneWidget, reason: 'the unlocked card');
        final cta = t.getRect(find.text('TO THE MAP'));
        expect(cta.bottom, lessThan(size.height), reason: 'TO THE MAP on screen');
        await capture(t, 'story_scene_$tag');
        await t.tap(find.text('TO THE MAP'));
        await wait(t, const Duration(milliseconds: 1500));
        expect(
          ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first)
              .read(routerProvider)
              .routerDelegate
              .currentConfiguration
              .uri
              .path,
          Routes.map,
        );
        await wait(t, const Duration(seconds: 3));
      });
    }
  }
}
