import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/mission_map/map_camera.dart';
import 'package:london_mystery/features/mission_map/map_world.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/game_button.dart';

import 'full_playthrough_test.dart' show goToTime, wait;
import 'helpers.dart';

/// GO TO a place: the camera moves in on it, then its mission page fades in
/// straight away — once.
void main() {
  final season = MockEpisodeRepository.bundled();
  late WidgetRef appRef;

  /// The map of [episodeId] with its first [solved] places solved.
  Future<void> openMap(WidgetTester t, String episodeId, int solved, {Size size = const Size(360, 640)}) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final e = season.firstWhere((e) => e.id == episodeId);
    final progress = GameProgress(
      detectiveName: 'KIM',
      introSeen: true,
      completedMissionIds: [for (final m in e.allMissions.take(solved)) m.id],
      startedAt: DateTime(2026, 10, 1, 10),
      playMillis: 0,
    );
    final before = [for (final s in season.takeWhile((s) => s.id != episodeId)) s.id];
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(prefs: {
        AppConstants.progressKeyFor(episodeId): jsonEncode(progress.toJson()),
        if (episodeId != AppConstants.currentEpisodeId)
          AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'KIM').toJson()),
        AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: episodeId, solvedEpisodeIds: before).toJson()),
      }),
      child: Consumer(builder: (context, ref, _) {
        appRef = ref;
        return const LondonMysteryApp();
      }),
    ));
    await wait(t, const Duration(milliseconds: 300));
    appRef.read(routerProvider).go(Routes.map);
    await wait(t, const Duration(milliseconds: 1200));
  }

  /// The page on top (a pushed page included).
  String path() => appRef.read(routerProvider).routerDelegate.currentConfiguration.last.matchedLocation;
  int depth() => appRef.read(routerProvider).routerDelegate.currentConfiguration.matches.length;
  final goTo = find.ancestor(of: find.text('GO'), matching: find.byType(GameButton));
  Rect world(WidgetTester t) => t.getRect(find.byKey(const ValueKey('map-world')));
  Rect inner(WidgetTester t) => t.getRect(find.byKey(const ValueKey('map-viewport'))).deflate(5);

  String? assetOf(Image image) {
    var provider = image.image;
    if (provider is ResizeImage) provider = provider.imageProvider;
    return provider is AssetImage ? provider.assetName : null;
  }

  /// The picture files on stage (the map is off stage under a mission page).
  List<String?> pictures(WidgetTester t) => [for (final i in t.widgetList<Image>(find.byType(Image))) assetOf(i)];

  double mapOpacity(WidgetTester t) => t.widget<FadeTransition>(find.byKey(const ValueKey('map-page'))).opacity.value;

  testWidgets('GO TO THE GREAT COURT: zoom right in on the pin, the map fades out, the mission page fades in', (t) async {
    await openMap(t, 'ep03', 2);
    final e = season.firstWhere((e) => e.id == 'ep03');
    expect(find.bySemanticsLabel('GO TO THE GREAT COURT'), findsOneWidget);
    final before = world(t);

    // Frame by frame (20 ms): how far in the camera is, how faded the map,
    // and whether the mission page has opened — so the order is checked
    // whatever the exact timings are tuned to.
    await t.tap(goTo);
    await t.pump();
    final place = MapWorld.places(e)['ep03_m3']!;
    final frames = <({double zoom, double opacity, String path, Rect world})>[];
    for (var i = 0; i < 125 && path() == Routes.map; i++) {
      await t.pump(const Duration(milliseconds: 20));
      if (path() != Routes.map) break;
      frames.add((zoom: world(t).width / before.width, opacity: mapOpacity(t), path: path(), world: world(t)));
    }
    expect(path(), Routes.mission('ep03_m3'), reason: 'the trip ends in the mission');

    // The camera moves in first, gradually, with the map fully there.
    expect(frames.where((f) => f.opacity == 1 && f.zoom > 1.2 && f.zoom < 2.5), isNotEmpty, reason: 'zooming before fading');
    // The fade-out starts before the zoom is over: the two overlap.
    final fadeStart = frames.firstWhere((f) => f.opacity < 1);
    expect(fadeStart.zoom, lessThan(2.95), reason: 'fading out while still zooming');
    // Heading in on the pin's tip. If the zoom is over before the map has
    // gone: 3×, the tip exactly at the centre; if the map is gone first (the
    // fade may start early), the tip is still closing in on the centre.
    double tipToCentre(({double zoom, double opacity, String path, Rect world}) f) =>
        (f.world.topLeft + Offset(place.dx * f.world.width, place.dy * f.world.height) - inner(t).center).distance;
    final zoomedIn = frames.where((f) => f.zoom > 2.995).firstOrNull;
    if (zoomedIn != null) {
      final camera = MapCamera.cover(inner(t).size, aspect: 3 / 2).zoomed(3);
      expect(zoomedIn.world.topLeft - inner(t).topLeft, offsetMoreOrLessEquals(camera.offsetFor(place), epsilon: 1.5));
      expect(tipToCentre(zoomedIn), lessThan(1.5), reason: 'the pin tip at the centre');
    } else {
      expect(frames.last.zoom, greaterThan(2.5), reason: 'well in by the time the map is gone');
      expect(tipToCentre(frames.last), lessThan(tipToCentre(frames.first) / 2), reason: 'closing in on the pin tip');
    }
    for (final f in frames) {
      expect(f.world.left <= inner(t).left + 0.5 && f.world.right >= inner(t).right - 0.5, isTrue, reason: 'no empty edge');
      expect(f.world.top <= inner(t).top + 0.5 && f.world.bottom >= inner(t).bottom - 0.5, isTrue, reason: 'no empty edge');
    }
    // The mission page opens only once the map has gone.
    expect(frames.last.opacity, 0, reason: 'the map is gone before the mission page comes');
    // ...and the mission page fades in.
    await t.pump(const Duration(milliseconds: 100));
    final fadeIn = t.widgetList<FadeTransition>(find.byType(FadeTransition)).map((f) => f.opacity.value).where((v) => v > 0 && v < 1);
    expect(fadeIn, isNotEmpty, reason: 'fading in');
    await wait(t);
    expect(pictures(t), contains(ArtAssets.scenes[Artwork.greatCourt]), reason: 'the mission page shows the Great Court');
    expect(appRef.read(gameControllerProvider).completedMissionIds, hasLength(2), reason: 'nothing solved by going');
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('tapping GO TO again while travelling opens the mission once', (t) async {
    await openMap(t, 'ep03', 2);
    await t.tap(goTo);
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(goTo, warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(goTo, warnIfMissed: false);
    await wait(t, goToTime);
    expect(path(), Routes.mission('ep03_m3'));
    expect(depth(), 2, reason: 'map + one mission page');

    // Back to the map: as it was, ready to go again.
    appRef.read(routerProvider).pop();
    await wait(t, const Duration(seconds: 1));
    expect(path(), Routes.map);
    expect(world(t).width, closeTo(inner(t).height * 1.2 * 1.5, 1), reason: 'zoom back to normal');
    expect(mapOpacity(t), 1, reason: 'the map is back');
    expect(t.widget<GameButton>(goTo).onPressed, isNotNull);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('back while travelling does not leave half-way', (t) async {
    await openMap(t, 'ep03', 2);
    await t.tap(goTo);
    await t.pump(const Duration(milliseconds: 400));
    expect(t.widget<GameButton>(goTo).onPressed, isNull, reason: 'GO TO is off while travelling');
    await t.binding.handlePopRoute();
    await t.pump(const Duration(milliseconds: 100));
    expect(path(), Routes.map);
    await wait(t, goToTime);
    expect(path(), Routes.mission('ep03_m3'), reason: 'the trip ends in the mission');
    await wait(t, const Duration(seconds: 3));
  });

  // The same trip everywhere: landmarks, rooms inside them, the final case.
  // Each mission page shows its place (a puzzle scene such as the suitcase,
  // the Raven or the Clock Room stays drawn).
  for (final (episode, solved, label, route, picture) in [
    ('ep01', 0, "GO TO KING'S CROSS", Routes.mission('m01'), null),
    ('ep03', 1, 'GO TO THE EGYPT ROOM', Routes.mission('ep03_m2'), Artwork.egyptRoom),
    ('ep07', 1, 'GO TO THE BOATHOUSE', Routes.mission('ep07_m2'), Artwork.boathouse),
    ('ep08', 1, 'GO TO THE WAITING ROOM', Routes.mission('ep08_m2'), Artwork.waitingRoom),
    ('ep09', 2, 'GO TO THE COURTYARD', Routes.mission('ep09_m3'), Artwork.courtyard),
    ('ep11', 1, 'GO TO BEHIND THE STAGE', Routes.mission('ep11_m2'), Artwork.dressingRoom),
    ('ep10', 3, 'OPEN THE FINAL CASE', Routes.finalMission, null),
  ]) {
    testWidgets('$label: the camera moves in, then $route', (t) async {
      await openMap(t, episode, solved);
      expect(find.bySemanticsLabel(label), findsOneWidget);
      await t.tap(find.bySemanticsLabel(label));
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      expect(path(), Routes.map, reason: 'moving in first');
      await wait(t, goToTime);
      expect(path(), route);
      if (picture != null) expect(pictures(t), contains(ArtAssets.scenes[picture]));
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 3));
    });
  }

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    testWidgets('the trip works on a ${size.width.toInt()}×${size.height.toInt()} screen', (t) async {
      await openMap(t, 'ep03', 2, size: size);
      await t.tap(goTo);
      await t.pump();
      await t.pump(const Duration(milliseconds: 1199));
      final zoomed = world(t);
      expect(zoomed.left <= inner(t).left + 0.5 && zoomed.right >= inner(t).right - 0.5, isTrue, reason: 'no empty edge');
      expect(zoomed.top <= inner(t).top + 0.5 && zoomed.bottom >= inner(t).bottom - 0.5, isTrue, reason: 'no empty edge');
      await wait(t, goToTime);
      expect(path(), Routes.mission('ep03_m3'));
      final picture = t.getRect(find.byType(Image).first);
      expect(picture.left >= 0 && picture.right <= size.width, isTrue, reason: 'the mission picture fits');
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 3));
    });
  }
}
