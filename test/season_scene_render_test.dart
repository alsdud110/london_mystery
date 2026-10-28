import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/scene_explore.dart' show ScenePixels;
import 'package:world_mystery/data/models/scene_place.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/season/widgets/season_props.dart';
import 'package:world_mystery/widgets/art_assets.dart';
import 'package:world_mystery/widgets/landmark_art.dart';
import 'package:world_mystery/widgets/place_art.dart';
import 'package:world_mystery/widgets/place_scenery.dart';
import 'package:world_mystery/widgets/scene_backdrop.dart';

import 'multi_season_test.dart' show assetOf;

/// A mission at a season place (`sceneKey`) shows that place's registered
/// picture wherever the game shows a mission's place, with no [Artwork] value;
/// every mission of Seasons 1 and 2 shows its scene as before.
///
/// The place belongs to a test season that is not in the game
/// (`SeasonCatalog.testPlaces`); its picture is a bundled file.
void main() {
  const id = 's9_test.station';
  const place = ScenePlace(file: ArtAssets.season2GareDuNord, pixels: ScenePixels(941, 1671));
  const scene = SeasonScene(id);

  setUp(() => SeasonCatalog.testPlaces[id] = place);
  tearDown(SeasonCatalog.testPlaces.clear);

  final bundled = [for (final e in MockEpisodeRepository.bundled()) ...e.allMissions];

  /// A mission of the test season, at the place [key]: a London mission's
  /// content, its scene swapped for the place.
  Mission seasonMission({String key = id, bool finale = false}) {
    final json = bundled.first.toJson()
      ..remove('scene')
      ..['id'] = 's9_test_ep01_m1'
      ..['sceneKey'] = key;
    return Mission.fromJson(json, finale: finale);
  }

  bool showsFile(String file) =>
      find.byWidgetPredicate((w) => w is Image && assetOf(w.image) == file, skipOffstage: false).evaluate().isNotEmpty;

  Future<void> pumpIn(WidgetTester t, Widget child) =>
      t.pumpWidget(MaterialApp(home: Center(child: SizedBox(width: 300, height: 400, child: child))));

  group('Seasons 1 and 2: every mission as before', () {
    test('its picture, arrival and scenery are its Artwork, as the old answers', () {
      for (final m in bundled) {
        expect(PlaceArt.pictureOf(m), ArtworkScene(PlaceArt.sceneOf(m)!), reason: m.id);
        expect(PlaceArt.arrivalOf(m), ArtworkScene(PlaceArt.placeOf(m)!), reason: m.id);
        expect(PlaceArt.sceneryPlaceOf(m), ArtworkScene(PlaceArt.sceneryOf(m)!), reason: m.id);
      }
    });

    test('an Artwork scene is sized and shown by its Artwork, unchanged', () {
      for (final art in Artwork.values) {
        const solved = [0.0, 1.0];
        for (final s in solved) {
          expect(LandmarkArt.hasPictureOf(ArtworkScene(art), solved: s), LandmarkArt.hasPicture(art, solved: s), reason: art.name);
          expect(LandmarkArt.aspectOfScene(ArtworkScene(art), solved: s), LandmarkArt.aspectOf(art, solved: s), reason: art.name);
        }
        final w = LandmarkArt.ofScene(ArtworkScene(art), borderRadius: 2, solved: 1, showName: false);
        expect(w, isA<LandmarkArt>());
        w as LandmarkArt;
        expect((w.artwork, w.borderRadius, w.solved, w.showName, w.showSky), (art, 2.0, 1.0, false, true));
      }
    });

    testWidgets('a London scene and a Paris scene show their own pictures', (t) async {
      await pumpIn(t, LandmarkArt.ofScene(const ArtworkScene(Artwork.bigBen)));
      expect(showsFile(ArtAssets.scene(Artwork.bigBen)!), isTrue);
      await pumpIn(t, PlaceScenery.scene(const ArtworkScene(Artwork.gareDuNord)));
      expect(find.byWidgetPredicate((w) => w is SceneBackdrop && w.file == ArtAssets.scene(Artwork.gareDuNord)), findsOneWidget);
      await pumpIn(t, const PhotoPrint(ArtworkScene(Artwork.bigBen)));
      expect(showsFile(ArtAssets.scene(Artwork.bigBen)!), isTrue);
    });

    test("the Royal Box stays Case 01's final's own scene; a season place never is it", () {
      final box = bundled.firstWhere((m) => m.scene == Artwork.royalBox);
      expect(box.isFinal, isTrue);
      expect(PlaceArt.pictureOf(box), const ArtworkScene(Artwork.royalBox));
      final m = seasonMission(finale: true);
      expect(m.scene, isNull);
      expect(m.scene == Artwork.royalBox, isFalse, reason: "the final page's Royal Box branch reads the mission's Artwork");
    });
  });

  group('a mission at a season place', () {
    test('every page names the same place for it: the mission, its final, the photo, the board, the story', () {
      final m = seasonMission();
      expect(m.place, scene);
      expect(PlaceArt.pictureOf(m), scene, reason: 'mission page, final page, Case Solved photo, board print');
      expect(PlaceArt.sceneryPlaceOf(m), scene, reason: 'story scene and answer feedback backdrop');
      expect(PlaceArt.arrivalOf(m), scene, reason: 'the unlocked card');
      expect((PlaceArt.sceneOf(m), PlaceArt.placeOf(m), PlaceArt.sceneryOf(m)), (null, null, null), reason: 'no Artwork');
    });

    test('its frame is its picture\'s own ratio', () {
      expect(LandmarkArt.hasPictureOf(scene), isTrue);
      expect(LandmarkArt.aspectOfScene(scene), 941 / 1671);
      expect(LandmarkArt.aspectOfScene(scene, solved: 1), 941 / 1671);
    });

    testWidgets('its picture shows: as a scene, as the scenery behind the story, as a board print', (t) async {
      await pumpIn(t, LandmarkArt.ofScene(PlaceArt.pictureOf(seasonMission()), borderRadius: 2));
      expect(showsFile(place.file), isTrue);
      expect(find.byType(CustomPaint).evaluate().where((e) => (e.widget as CustomPaint).painter != null), isEmpty, reason: 'never drawn');

      await pumpIn(t, PlaceScenery.scene(PlaceArt.sceneryPlaceOf(seasonMission())));
      final backdrop = t.widget<SceneBackdrop>(find.byType(SceneBackdrop));
      expect((backdrop.file, backdrop.pixels.width, backdrop.pixels.height), (place.file, 941.0, 1671.0));
      expect(showsFile(ArtAssets.londonMap), isFalse, reason: "never London's map in its stead");

      await pumpIn(t, PhotoPrint(PlaceArt.pictureOf(seasonMission())));
      expect(showsFile(place.file), isTrue);
    });

    test('an unregistered place is an error, never another picture', () {
      const gone = SeasonScene('s9_test.gone');
      expect(() => SeasonCatalog.placeFor(gone.id), throwsStateError);
      expect(() => LandmarkArt.aspectOfScene(gone), throwsStateError);
      expect(() => LandmarkArt.ofScene(gone), throwsStateError);
      expect(() => LandmarkArt.backdropOf(gone), throwsStateError);
    });

    testWidgets('an unregistered place on a page is an error', (t) async {
      await pumpIn(t, const PlaceScenery.scene(SeasonScene('s9_test.gone')));
      expect(t.takeException(), isStateError);
    });

    testWidgets('a picture that does not load is said as an error, not covered', (t) async {
      SeasonCatalog.testPlaces['s9_test.missing'] = const ScenePlace(file: 'assets/seasons/none.png', pixels: ScenePixels(10, 10));
      await pumpIn(t, LandmarkArt.ofScene(const SeasonScene('s9_test.missing')));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pump();
      expect(find.byType(ErrorWidget), findsOneWidget);
      expect(t.takeException(), isA<FlutterError>());
    });
  });
}
