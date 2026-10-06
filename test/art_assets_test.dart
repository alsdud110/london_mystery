import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/mission_map/map_world.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/evidence_card.dart';
import 'package:london_mystery/widgets/ink_icon.dart';
import 'package:london_mystery/widgets/landmark_art.dart';
import 'package:london_mystery/widgets/place_art.dart';
import 'package:london_mystery/widgets/symbol_icon.dart';

/// The artwork replacement points: until a file is added, every picture
/// looks exactly as it did; a file that is listed must exist; a missing
/// file never leaves an empty frame.
void main() {
  Future<List<int>> draw(WidgetTester t, Artwork a, {bool drawingOnly = false}) async {
    await t.pumpWidget(RepaintBoundary(
      key: const ValueKey('art'),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 160, height: 120, child: drawingOnly ? LandmarkArt.drawing(a) : LandmarkArt(a)),
      ),
    ));
    // Let a scene picture decode, so both sides of a comparison are drawn.
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await t.pump();
    return (await t.runAsync(() async {
      final image = await t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('art'))).toImage();
      return (await image.toByteData())!.buffer.asUint8List().toList();
    }))!;
  }

  // A place inside a landmark has a picture of its own; without it (a file
  // missing) it is drawn as its landmark — never shown as the landmark's
  // picture (the Boathouse is not Hyde Park).
  testWidgets('a place inside a landmark is drawn like its landmark when its picture is missing', (t) async {
    // Gallery 8 keeps its own drawing (the empty frame) as its fallback.
    expect(LandmarkArt.standIns.keys.toSet(), {...PlaceArt.inside.difference({Artwork.gallery}), Artwork.oldSuitcase, Artwork.blackSuitcase});
    for (final MapEntry(key: place, value: standIn) in LandmarkArt.standIns.entries) {
      expect(await draw(t, place, drawingOnly: true), await draw(t, standIn, drawingOnly: true), reason: '$place');
      expect(ArtAssets.scene(place), isNot(ArtAssets.scene(standIn)), reason: '$place does not borrow the $standIn picture');
      expect(LandmarkArt.standIns.containsKey(standIn), isFalse, reason: 'a stand-in is a real drawing');
    }
  });

  test('the nine landmarks and the places inside them each have their own picture', () {
    const landmarks = {
      Artwork.kingsCross: 'assets/art/scenes/landmarks/kings_cross.png',
      Artwork.britishMuseum: 'assets/art/scenes/landmarks/british_museum.png',
      Artwork.coventGarden: 'assets/art/scenes/landmarks/covent_garden.png',
      Artwork.bigBen: 'assets/art/scenes/landmarks/big_ben.png',
      Artwork.hydePark: 'assets/art/scenes/landmarks/hyde_park.png',
      Artwork.buckinghamPalace: 'assets/art/scenes/landmarks/buckingham_palace.png',
      Artwork.towerBridge: 'assets/art/scenes/landmarks/tower_bridge.png',
      Artwork.towerOfLondon: 'assets/art/scenes/landmarks/tower_of_london.png',
      Artwork.londonEye: 'assets/art/scenes/landmarks/london_eye.png',
    };
    const inside = {
      Artwork.greatCourt: 'assets/art/scenes/british_museum/british_museum_great_court.png',
      Artwork.egyptRoom: 'assets/art/scenes/british_museum/british_museum_egypt_room.png',
      Artwork.boathouse: 'assets/art/scenes/hyde_park/hyde_park_boathouse.png',
      Artwork.roseGarden: 'assets/art/scenes/hyde_park/hyde_park_rose_garden.png',
      Artwork.staffRoom: 'assets/art/scenes/buckingham_palace/buckingham_palace_palace_staff_room.png',
      Artwork.courtyard: 'assets/art/scenes/buckingham_palace/buckingham_palace_palace_courtyard.png',
      Artwork.dressingRoom: 'assets/art/scenes/covent_garden/covent_garden_dressing_room.png',
      Artwork.waitingRoom: 'assets/art/scenes/kings_cross/kings_cross_waiting_hall.png',
      Artwork.gallery: 'assets/art/scenes/british_museum/british_museum_gallery.png',
      Artwork.auditorium: 'assets/art/scenes/covent_garden/covent_garden_theatre.png',
      Artwork.theatreDoor: 'assets/art/scenes/covent_garden/theatre_door_dark.png',
      Artwork.royalArchive: 'assets/art/scenes/royal_archive/royal_archive.png',
    };
    expect(ArtAssets.landmarkScenes, landmarks);
    expect(ArtAssets.insideScenes, inside);
    const objectScenes = {
      Artwork.raven: 'assets/art/characters/raven_master.png',
      Artwork.oldSuitcase: 'assets/art/objects/suitcase.png',
      // The Royal Box once found (case photo): open, never the theatre box.
      Artwork.royalBox: 'assets/art/special/royal_box_open.png',
      // Case 08's black suitcase.
      Artwork.blackSuitcase: 'assets/art/objects/suitcase_black.png',
      // Case 09's empty glass case; Case 05's and Case 12's own doors.
      Artwork.jewelCase: 'assets/art/objects/empty_glass_jewel_case.png',
      Artwork.gearDoor: 'assets/art/objects/locked_door_gears.png',
      Artwork.ironDoor: 'assets/art/objects/small_iron_door.png',
      Artwork.ironChest: 'assets/art/objects/iron_chest.png',
    };
    expect(ArtAssets.objectScenes, objectScenes);
    expect(ArtAssets.scenes, {...landmarks, ...inside, ...objectScenes});
    for (final a in Artwork.values) {
      expect(LandmarkArt.hasPicture(a), landmarks.containsKey(a) || inside.containsKey(a) || objectScenes.containsKey(a), reason: '$a');
    }
    // Each inside place's picture is in its landmark's folder.
    final landmarkFolders = {for (final p in landmarks.values) p.split('/').last.replaceAll('.png', '')};
    for (final MapEntry(key: place, value: path) in inside.entries) {
      final [_, _, _, folder, file] = path.split('/');
      // The Royal Archive is no map landmark: its own folder.
      if (place != Artwork.royalArchive) expect(landmarkFolders, contains(folder), reason: '$place is grouped under a landmark');
      // The theatre door keeps the name it was delivered with.
      if (place != Artwork.theatreDoor && place != Artwork.royalArchive) {
        expect(file, startsWith('${folder}_'), reason: '$place');
      }
    }
    // The map's landmarks are the same nine places, each with its picture.
    expect({for (final l in Landmark.values) l.artwork}, landmarks.keys.toSet());
  });

  testWidgets('every scene picture is in the app bundle', (t) async {
    expect(ArtAssets.scenes, hasLength(29));
    final all = {
      ...ArtAssets.scenes.values,
      ...ArtAssets.characters.values,
      ...ArtAssets.objects.values,
      ArtAssets.ravenMark,
      ArtAssets.mysteriousStranger,
      ArtAssets.lockedDoor,
      ...ArtAssets.special.values,
      ...ArtAssets.evidencePictures.values,
    };
    for (final path in all) {
      final data = await t.runAsync(() => rootBundle.load(path));
      expect(data!.lengthInBytes, greaterThan(1000), reason: path);
    }
  });

  testWidgets('a scene picture shows whole (contain, never stretched); other scenes stay drawn', (t) async {
    Future<void> show(Widget art) => t.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: SizedBox(width: 200, height: 128, child: art)),
        ));
    for (final (place, aspect) in [(Artwork.bigBen, 400 / 256), (Artwork.boathouse, 1288 / 816)]) {
      await show(LandmarkArt(place));
      expect(t.widget<Image>(find.byType(Image)).fit, BoxFit.contain, reason: '$place');
      expect(LandmarkArt.aspectOf(place), closeTo(aspect, 1e-9), reason: 'frames take the picture ratio');
    }
    for (final (scene, aspect) in [(Artwork.raven, 1.0), (Artwork.oldSuitcase, 1.0), (Artwork.royalBox, 885 / 868), (Artwork.greatCourt, 1264 / 848)]) {
      await show(LandmarkArt(scene));
      expect(t.widget<Image>(find.byType(Image)).fit, BoxFit.contain, reason: '$scene');
      expect(LandmarkArt.aspectOf(scene), closeTo(aspect, 1e-9), reason: '$scene frame takes its own ratio');
    }
    // Case 08's black suitcase and the puzzle scenes stay drawn.
    for (final scene in [Artwork.clockFace, Artwork.suitcase, Artwork.theatre]) {
      await show(LandmarkArt(scene));
      expect(find.byType(Image), findsNothing, reason: '$scene keeps its drawing');
      expect(LandmarkArt.aspectOf(scene), 4 / 3, reason: '$scene frame unchanged');
    }
  });

  test('each mission shows its own place: a room inside a landmark, else the landmark', () {
    final m = {for (final e in MockEpisodeRepository.bundled()) for (final m in e.allMissions) m.id: m};
    expect(PlaceArt.placeOf(m['ep03_m3']!), Artwork.greatCourt);
    expect(PlaceArt.placeOf(m['ep03_m2']!), Artwork.egyptRoom);
    expect(PlaceArt.sceneOf(m['ep03_m3']!), Artwork.greatCourt, reason: 'the mission page too');
    expect(PlaceArt.placeOf(m['ep07_m2']!), Artwork.boathouse);
    expect(PlaceArt.placeOf(m['ep07_m3']!), Artwork.roseGarden);
    expect(PlaceArt.placeOf(m['ep09_m2']!), Artwork.staffRoom);
    expect(PlaceArt.placeOf(m['ep09_m3']!), Artwork.courtyard);
    expect(PlaceArt.placeOf(m['ep11_m2']!), Artwork.dressingRoom);
    expect(PlaceArt.placeOf(m['ep08_m2']!), Artwork.waitingRoom);
    // A landmark visit shows the landmark, not the puzzle scene found there.
    expect(m['m01']!.scene, Artwork.suitcase);
    expect(PlaceArt.placeOf(m['m01']!), Artwork.kingsCross);
    expect(PlaceArt.sceneOf(m['m01']!), Artwork.oldSuitcase, reason: 'the mission page shows the suitcase picture');
    expect(PlaceArt.sceneOf(m['ep04_m1']!), Artwork.oldSuitcase, reason: 'an old brown suitcase');
    expect(PlaceArt.sceneOf(m['ep08_m1']!), Artwork.blackSuitcase, reason: "Case 08's suitcase is black");
    for (final id in ['ep05_m3', 'ep10_m1', 'ep10_m2', 'ep10_final', 'ep12_m3']) {
      expect(LandmarkArt.hasPicture(PlaceArt.sceneOf(m[id]!)), isTrue, reason: '$id shows the Tower raven');
    }
    expect(PlaceArt.placeOf(m['ep10_final']!), Artwork.towerBridge);
    // Every mission arrives at a place with a picture.
    for (final mission in m.values) {
      expect(LandmarkArt.hasPicture(PlaceArt.placeOf(mission)), isTrue, reason: mission.id);
    }
  });

  testWidgets('every scene draws without errors', (t) async {
    for (final a in Artwork.values) {
      await draw(t, a);
      expect(t.takeException(), isNull, reason: '$a');
    }
  });

  test('the six places are used by their missions', () {
    final scenes = {for (final e in MockEpisodeRepository.bundled()) for (final m in e.allMissions) m.id: m.scene};
    expect(scenes['ep07_m2'], Artwork.boathouse);
    expect(scenes['ep07_m3'], Artwork.roseGarden);
    expect(scenes['ep08_m2'], Artwork.waitingRoom);
    expect(scenes['ep09_m2'], Artwork.staffRoom);
    expect(scenes['ep09_m3'], Artwork.courtyard);
    expect(scenes['ep11_m2'], Artwork.dressingRoom);
  });

  test('a scene picture (whose name plate shows) never names its own image-choice answer', () {
    for (final e in MockEpisodeRepository.bundled()) {
      for (final m in e.allMissions.where((m) => m.type == MissionType.imageChoice)) {
        final answer = m.options.firstWhere((o) => o.id == m.answer).artwork;
        final scene = LandmarkArt.standIns[m.scene] ?? m.scene;
        expect(scene, isNot(answer), reason: m.id);
      }
    }
  });

  test('every listed file exists and its folder is bundled in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final files = [
      ...ArtAssets.scenes.values,
      ...ArtAssets.solvedScenes.values,
      ...ArtAssets.symbols.values,
      ...ArtAssets.badges.values,
    ];
    for (final path in files) {
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(pubspec, contains('- ${path.substring(0, path.lastIndexOf('/') + 1)}'), reason: path);
      expect(path, matches(RegExp(r'\.(png|webp|jpe?g)$')), reason: 'no SVG: it needs a new package');
    }
    // Keys are real: symbols the game uses, badges that exist.
    for (final key in ArtAssets.symbols.keys) {
      expect(GameSymbol.of(key).label, isNot('Mystery'), reason: key);
    }
    expect(GameBadge.values, containsAll(ArtAssets.badges.keys));
  });

  test('a place without a picture keeps its drawing (or monogram)', () {
    for (final a in Artwork.values) {
      expect(ArtAssets.scene(a), ArtAssets.scenes[a]);
    }
    expect(GameSymbol.of('park').asset, ArtAssets.symbols['park']);
    // The solved clock keeps its drawn change unless a solved picture exists.
    expect(ArtAssets.scene(Artwork.clockFace, solved: 1), ArtAssets.solvedScenes[Artwork.clockFace]);
  });

  testWidgets('a listed file that is missing falls back to the drawing', (t) async {
    await t.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: InkMark(glyph: InkGlyph.raven, monogram: 'R', size: 40, asset: 'assets/art/symbols/missing.png'),
      ),
    ));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await t.pump();
    expect(find.byType(InkIcon), findsOneWidget, reason: 'the raven glyph, not an empty box');

    await t.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: InkMark(glyph: null, monogram: 'P', size: 40, asset: 'assets/art/symbols/missing.png')),
    ));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await t.pump();
    expect(find.text('P'), findsOneWidget, reason: 'the monogram');
  });

  test('characters, objects, the Raven mark and special pictures are listed by name', () {
    expect(ArtAssets.characters, {
      'raven': 'assets/art/characters/raven_master.png',
      'clockmaker': 'assets/art/characters/clockmaker_master.png',
    });
    expect(ArtAssets.objects, {
      'crown': 'assets/art/objects/crown.png',
      'key': 'assets/art/objects/key.png',
      'letter': 'assets/art/objects/letter.png',
      'map': 'assets/art/objects/map.png',
      'pocketWatch': 'assets/art/objects/pocket_watch.png',
      'suitcase': 'assets/art/objects/suitcase.png',
    });
    expect(ArtAssets.ravenMark, 'assets/art/symbols/raven_mark.png');
    expect(ArtAssets.special, {'theatreRoyalBox': 'assets/art/special/royal_box.png'});
    // Full-colour pictures never go in the tinted one-colour symbol slot.
    expect(ArtAssets.symbols.values, isNot(contains(ArtAssets.ravenMark)));
  });

  test('evidence shows its real picture only where the picture agrees with it', () {
    expect(ArtAssets.evidencePictures, {
      'e01': ArtAssets.objects['letter'],
      'e02': ArtAssets.objects['key'],
      'e06': ArtAssets.objects['crown'],
      'ep04_e1': ArtAssets.ravenMark,
      'ep05_e3': ArtAssets.objects['key'],
      'ep10_e3': ArtAssets.objects['letter'],
      'ep12_e4': ArtAssets.objects['pocketWatch'],
    });
    final evidence = {for (final e in MockEpisodeRepository.bundled()) for (final x in e.allEvidence) x.id: x};
    expect(evidence.keys, containsAll(ArtAssets.evidencePictures.keys), reason: 'real evidence ids');
    // Case 01's watch (7 o'clock) and map (two swans) give numbers for the
    // Royal Box; their pictures would show other ones, so they stay drawn.
    expect(evidence['e03']!.inscription, contains('7'));
    expect(evidence['e04']!.inscription, contains('Two swans'));
    expect(ArtAssets.evidencePictures.keys, isNot(contains('e03')));
    expect(ArtAssets.evidencePictures.keys, isNot(contains('e04')));
  });

  testWidgets('an evidence tile shows its picture where it has one, else its symbol', (t) async {
    final evidence = {for (final e in MockEpisodeRepository.bundled()) for (final x in e.allEvidence) x.id: x};
    Future<void> tile(Evidence e) async {
      await t.pumpWidget(MaterialApp(home: Center(child: SizedBox(width: 160, height: 190, child: EvidenceTile(evidence: e)))));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await t.pump();
    }

    await tile(evidence['e02']!);
    final image = t.widget<Image>(find.byType(Image));
    expect((image.image as ResizeImage).imageProvider, isA<AssetImage>().having((a) => a.assetName, 'asset', ArtAssets.objects['key']));
    expect(find.byType(InkIcon).evaluate().where((e) => (e.widget as InkIcon).glyph == InkGlyph.key), isEmpty, reason: 'the picture, not the glyph');

    await tile(evidence['e03']!);
    expect(find.byType(Image), findsNothing, reason: 'the watch keeps its symbol');

    await t.pumpWidget(const MaterialApp(home: Center(child: SizedBox(width: 160, height: 120, child: LandmarkArt(Artwork.raven)))));
    expect(find.byType(Image), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
