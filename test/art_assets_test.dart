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
    expect(LandmarkArt.standIns.keys.toSet(), {...PlaceArt.inside.difference({Artwork.gallery}), Artwork.oldSuitcase, Artwork.blackSuitcase, Artwork.clockMechanism});
    for (final MapEntry(key: place, value: standIn) in LandmarkArt.standIns.entries) {
      expect(await draw(t, place, drawingOnly: true), await draw(t, standIn, drawingOnly: true), reason: '$place');
      expect(ArtAssets.scene(place), isNot(ArtAssets.scene(standIn)), reason: '$place does not borrow the $standIn picture');
      expect(LandmarkArt.standIns.containsKey(standIn), isFalse, reason: 'a stand-in is a real drawing');
    }
  });

  test('the nine landmarks and the places inside them each have their own picture', () {
    const landmarks = {
      Artwork.kingsCross: 'assets/seasons/season_01_london/locations/landmarks/kings_cross.png',
      Artwork.britishMuseum: 'assets/seasons/season_01_london/locations/landmarks/british_museum.png',
      Artwork.coventGarden: 'assets/seasons/season_01_london/locations/landmarks/covent_garden.png',
      Artwork.bigBen: 'assets/seasons/season_01_london/locations/landmarks/big_ben.png',
      Artwork.hydePark: 'assets/seasons/season_01_london/locations/landmarks/hyde_park.png',
      Artwork.buckinghamPalace: 'assets/seasons/season_01_london/locations/landmarks/buckingham_palace.png',
      Artwork.towerBridge: 'assets/seasons/season_01_london/locations/landmarks/tower_bridge.png',
      Artwork.towerOfLondon: 'assets/seasons/season_01_london/locations/landmarks/tower_of_london.png',
      Artwork.londonEye: 'assets/seasons/season_01_london/locations/landmarks/london_eye.png',
    };
    const inside = {
      Artwork.greatCourt: 'assets/seasons/season_01_london/locations/british_museum/british_museum_great_court.png',
      Artwork.egyptRoom: 'assets/seasons/season_01_london/locations/british_museum/british_museum_egypt_room.png',
      Artwork.boathouse: 'assets/seasons/season_01_london/locations/hyde_park/hyde_park_boathouse.png',
      Artwork.roseGarden: 'assets/seasons/season_01_london/locations/hyde_park/hyde_park_rose_garden.png',
      Artwork.staffRoom: 'assets/seasons/season_01_london/locations/buckingham_palace/buckingham_palace_palace_staff_room.png',
      Artwork.courtyard: 'assets/seasons/season_01_london/locations/buckingham_palace/buckingham_palace_palace_courtyard.png',
      Artwork.dressingRoom: 'assets/seasons/season_01_london/locations/covent_garden/covent_garden_dressing_room.png',
      Artwork.waitingRoom: 'assets/seasons/season_01_london/locations/kings_cross/kings_cross_waiting_hall.png',
      Artwork.gallery: 'assets/seasons/season_01_london/locations/british_museum/british_museum_gallery_8.png',
      Artwork.auditorium: 'assets/seasons/season_01_london/locations/covent_garden/covent_garden_theatre.png',
      Artwork.theatreDoor: 'assets/seasons/season_01_london/locations/covent_garden/theatre_door_dark.png',
      Artwork.royalArchive: 'assets/seasons/season_01_london/locations/royal_archive/royal_archive.png',
    };
    expect(ArtAssets.landmarkScenes, landmarks);
    expect(ArtAssets.insideScenes, inside);
    const objectScenes = {
      Artwork.raven: 'assets/seasons/season_01_london/characters/raven_master.png',
      Artwork.oldSuitcase: 'assets/shared/objects/suitcase.png',
      // The Royal Box once found (case photo): open, never the theatre box.
      Artwork.royalBox: 'assets/seasons/season_01_london/special/royal_box_open.png',
      // Case 08's black suitcase.
      Artwork.blackSuitcase: 'assets/seasons/season_01_london/objects/suitcase_black.png',
      // Case 09's empty glass case; Case 05's and Case 12's own doors.
      Artwork.jewelCase: 'assets/seasons/season_01_london/objects/empty_glass_jewel_case.png',
      Artwork.gearDoor: 'assets/seasons/season_01_london/objects/locked_door_gears.png',
      Artwork.ironDoor: 'assets/seasons/season_01_london/objects/small_iron_door.png',
      Artwork.ironChest: 'assets/seasons/season_01_london/objects/iron_chest.png',
      // Case 02: Big Ben's clock stopped at 8:17, and the wheels behind it.
      Artwork.clockFace: 'assets/seasons/season_01_london/locations/big_ben/clock_face.png',
      Artwork.clockMechanism: 'assets/seasons/season_01_london/locations/big_ben/clock_mechanism.png',
    };
    expect(ArtAssets.objectScenes, objectScenes);
    // Season 2's places: Gare du Nord (Case 01), its own picture.
    const parisScenes = {
      Artwork.gareDuNord: 'assets/seasons/season_02_paris/cover/season2_gare_du_nord.png',
      // Case 01 M3: the old clock's face, its hands set by the detective.
      Artwork.oldClockFace: 'assets/seasons/season_02_paris/cases/case_01/old_clock_face.png',
      // Case 02 begins on the painting from Case 01's brass box; its street
      // (as it really is) and the painter's studio.
      Artwork.montmartrePainting: 'assets/seasons/season_02_paris/cases/case_01/montmartre_painting.png',
      Artwork.montmartreStreet: 'assets/seasons/season_02_paris/cases/case_02/montmartre_street_real.png',
      Artwork.paintersStudio: 'assets/seasons/season_02_paris/cases/case_02/painters_studio.png',
      // Case 03 begins on the back of Case 02's last canvas (its tower
      // sketch); then the tower, its entrance, lift, iron door, hidden room
      // and time-recording machine.
      Artwork.paintersMessage: 'assets/seasons/season_02_paris/cases/case_02/canvas_back.png',
      Artwork.eiffelTower: 'assets/seasons/season_02_paris/cases/case_03/eiffel_tower_exterior.png',
      Artwork.towerEntrance: 'assets/seasons/season_02_paris/cases/case_03/tower_notice_board.png',
      Artwork.towerLift: 'assets/seasons/season_02_paris/cases/case_03/tower_lift.png',
      Artwork.serviceDoor: 'assets/seasons/season_02_paris/cases/case_03/service_door.png',
      Artwork.serviceRoom: 'assets/seasons/season_02_paris/cases/case_03/service_room.png',
      Artwork.timeMachine: 'assets/seasons/season_02_paris/cases/case_03/time_recording_machine.png',
      // Case 04's places on the Seine: the quays at dusk, the quay wall, the
      // keeper's hut outside and in, the green boxes and the passage's gate.
      Artwork.seineQuays: 'assets/seasons/season_02_paris/cases/case_04/seine_quays_dusk.png',
      Artwork.quayWall: 'assets/seasons/season_02_paris/cases/case_04/quay_wall_marks.png',
      Artwork.keeperHut: 'assets/seasons/season_02_paris/cases/case_04/keeper_hut.png',
      Artwork.keeperHutInside: 'assets/seasons/season_02_paris/cases/case_04/keeper_hut_interior.png',
      Artwork.quayBoxes: 'assets/seasons/season_02_paris/cases/case_04/quay_boxes.png',
      Artwork.passageGate: 'assets/seasons/season_02_paris/cases/case_04/passage_gate.png',
      // Case 05's places in No. 7's workshop: the room, the workbench, the
      // wall of clocks and the writing desk.
      Artwork.workshopInterior: 'assets/seasons/season_02_paris/cases/case_05/workshop_interior.png',
      Artwork.workbenchMarks: 'assets/seasons/season_02_paris/cases/case_05/workbench_marks.png',
      Artwork.wallOfClocks: 'assets/seasons/season_02_paris/cases/case_05/wall_of_clocks.png',
      Artwork.writingDesk: 'assets/seasons/season_02_paris/cases/case_05/writing_desk_blotter.png',
      Artwork.louvrePostRoom: 'assets/seasons/season_02_paris/cases/case_06/louvre_post_room_exterior.png',
      Artwork.holdRack: 'assets/seasons/season_02_paris/cases/case_06/post_room_hold_rack.png',
      Artwork.archiveFloorPlan: 'assets/seasons/season_02_paris/cases/case_06/archive_floor_plan.png',
      Artwork.archiveRoom: 'assets/seasons/season_02_paris/cases/case_06/archive_room.png',
      Artwork.palaisGarnierNight: 'assets/seasons/season_02_paris/cases/case_07/palais_garnier_night.png',
      Artwork.operaArchive: 'assets/seasons/season_02_paris/cases/case_07/opera_archive_room.png',
      Artwork.operaStage: 'assets/seasons/season_02_paris/cases/case_07/stage_base.png',
      Artwork.flyRail: 'assets/seasons/season_02_paris/cases/case_07/fly_rail.png',
      Artwork.lightTable: 'assets/seasons/season_02_paris/cases/case_07/light_table_off.png',
      // Case 08's places in Abbesses: the square, the painter's corner and
      // the bundle behind the loose stone.
      Artwork.abbessesSquare: 'assets/seasons/season_02_paris/cases/case_08/abbesses_square.png',
      Artwork.paintersCorner: 'assets/seasons/season_02_paris/cases/case_08/corner_2.png',
      Artwork.drawingBundle: 'assets/seasons/season_02_paris/cases/case_08/drawing_bundle.png',
      Artwork.luxembourgGarden: 'assets/seasons/season_02_paris/cases/case_09/garden_model_view.png',
      Artwork.gearBoard: 'assets/seasons/season_02_paris/cases/case_09/gear_board.png',
    };
    expect(ArtAssets.parisScenes, parisScenes);
    expect(LandmarkArt.hasPicture(Artwork.montmartreStreet), isTrue);
    expect(LandmarkArt.hasPicture(Artwork.paintersStudio), isTrue);
    expect(ArtAssets.scenes, {...landmarks, ...inside, ...objectScenes, ...parisScenes});
    for (final a in Artwork.values) {
      expect(
        LandmarkArt.hasPicture(a),
        landmarks.containsKey(a) || inside.containsKey(a) || objectScenes.containsKey(a) || parisScenes.containsKey(a),
        reason: '$a',
      );
    }
    // Each inside place's picture is in its landmark's folder.
    final landmarkFolders = {for (final p in landmarks.values) p.split('/').last.replaceAll('.png', '')};
    for (final MapEntry(key: place, value: path) in inside.entries) {
      // The picture's own folder and name (however deep its season folder is).
      final [..., folder, file] = path.split('/');
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
    // Season 1's 31, and Season 2's Gare du Nord, old clock face, the
    // Montmartre painting (Case 02's first scene), Case 02's street and studio,
    // Case 03's seven (the canvas back and six places at the tower),
    // Case 04's six places on the Seine, and Case 05's four in the workshop;
    // Case 06's four, Case 07's five, Case 08's three in Abbesses, and
    // Case 09's two in the Luxembourg Gardens.
    expect(ArtAssets.scenes, hasLength(67));
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
    for (final (scene, aspect) in [(Artwork.raven, 1.0), (Artwork.oldSuitcase, 1.0), (Artwork.royalBox, 1659 / 948), (Artwork.clockFace, 1.0), (Artwork.greatCourt, 1264 / 848)]) {
      await show(LandmarkArt(scene));
      expect(t.widget<Image>(find.byType(Image)).fit, BoxFit.contain, reason: '$scene');
      expect(LandmarkArt.aspectOf(scene), closeTo(aspect, 1e-9), reason: '$scene frame takes its own ratio');
    }
    // Case 01's suitcase (recalled in Case 11) and the plain theatre stay drawn.
    for (final scene in [Artwork.suitcase, Artwork.theatre]) {
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
    // The solved clock: its own picture (9:17).
    expect(ArtAssets.scene(Artwork.clockFace, solved: 1), ArtAssets.scene(Artwork.clockFace),
        reason: 'the same face before and after: only its drawn hands turn');
    expect(ArtAssets.solvedScenes, isEmpty);
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
      'raven': 'assets/seasons/season_01_london/characters/raven_master.png',
      'clockmaker': 'assets/seasons/season_01_london/characters/clockmaker_master.png',
      // Wave 2: Case 06's three witnesses (see test/case06_dialogue_test.dart).
      'flowerSeller': 'assets/seasons/season_01_london/characters/flower_seller.png',
      'juggler': 'assets/seasons/season_01_london/characters/juggler.png',
      'baker': 'assets/seasons/season_01_london/characters/baker.png',
    });
    expect(ArtAssets.marketHall, 'assets/seasons/season_01_london/locations/covent_garden/covent_garden_market_hall.png');
    expect(ArtAssets.objects, {
      'crown': 'assets/seasons/season_01_london/objects/crown.png',
      'key': 'assets/shared/objects/key.png',
      'letter': 'assets/shared/objects/letter.png',
      'map': 'assets/shared/objects/map.png',
      'pocketWatch': 'assets/shared/objects/pocket_watch.png',
      'suitcase': 'assets/shared/objects/suitcase.png',
    });
    expect(ArtAssets.ravenMark, 'assets/seasons/season_01_london/symbols/raven_mark.png');
    expect(ArtAssets.special, {'theatreRoyalBox': 'assets/seasons/season_01_london/special/royal_box.png'});
    // Full-colour pictures never go in the tinted one-colour symbol slot.
    expect(ArtAssets.symbols.values, isNot(contains(ArtAssets.ravenMark)));
  });

  test('evidence shows its real picture only where the picture agrees with it', () {
    expect(ArtAssets.evidencePictures, {
      'e01': ArtAssets.objects['letter'],
      'e02': ArtAssets.objects['key'],
      // The Pocket Watch is the Royal Box's clock picture (2026-10-19, requested).
      'e03': ArtAssets.royalBoxLocks['clock'],
      // The Crown Symbol card shows a crown (2026-10-19, requested).
      'e05': ArtAssets.objects['crown'],
      'e06': ArtAssets.objects['crown'],
      'ep03_e1': 'assets/seasons/season_01_london/objects/red_button.png',
      'ep04_e1': ArtAssets.ravenMark,
      'ep05_e3': ArtAssets.objects['key'],
      'ep10_e3': ArtAssets.objects['letter'],
      'ep12_e4': ArtAssets.objects['pocketWatch'],
      // Paris Case 01: the lost ticket and the painting, their own pictures.
      's2_ep01_e2': 'assets/seasons/season_02_paris/cases/case_01/lost_ticket.png',
      's2_ep01_e4': 'assets/seasons/season_02_paris/cases/case_01/montmartre_painting.png',
      // Paris Case 02: the painted street (its clock above the door). The
      // notes, the sketch and the message keep their marks: no picture shows
      // them as the evidence says.
      's2_ep02_e1': 'assets/seasons/season_02_paris/cases/case_02/montmartre_street_painted.png',
      // Paris Case 03: the hidden room, and the plaque (blank brass: its
      // message is in its words). The records and the log keep their marks:
      // their pictures are blank paper.
      's2_ep03_e3': 'assets/seasons/season_02_paris/cases/case_03/service_room.png',
      's2_ep03_e4': 'assets/seasons/season_02_paris/cases/case_03/brass_plaque.png',
      // Paris Case 04: blank stone, ledger and label, drawn with their words
      // wherever they are shown (`season2Case04EvidenceArt`).
      's2_ep04_e1': 'assets/seasons/season_02_paris/cases/case_04/river_mark_d.png',
      's2_ep04_e2': 'assets/seasons/season_02_paris/cases/case_04/keeper_ledger.png',
      's2_ep04_e3': 'assets/seasons/season_02_paris/cases/case_04/delivery_label_blank.png',
      's2_ep04_e4': 'assets/seasons/season_02_paris/cases/case_04/delivery_label_blank.png',
    });
    final evidence = {for (final e in MockEpisodeRepository.bundled()) for (final x in e.allEvidence) x.id: x};
    expect(evidence.keys, containsAll(ArtAssets.evidencePictures.keys), reason: 'real evidence ids');
    // Case 01's map (two swans) gives a number for the Royal Box; its
    // picture would show another one, so it stays drawn.
    expect(evidence['e03']!.inscription, contains('7'));
    expect(evidence['e04']!.inscription, contains('Two swans'));
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
    final watch = t.widget<Image>(find.byType(Image));
    expect((watch.image as ResizeImage).imageProvider,
        isA<AssetImage>().having((a) => a.assetName, 'asset', 'assets/images/case01/symbols/symbol_pocket_watch.png'));

    await t.pumpWidget(const MaterialApp(home: Center(child: SizedBox(width: 160, height: 120, child: LandmarkArt(Artwork.raven)))));
    expect(find.byType(Image), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
