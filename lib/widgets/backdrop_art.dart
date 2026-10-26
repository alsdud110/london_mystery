import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';

import '../data/models/backdrop.dart';
import '../data/models/scene_explore.dart' show ScenePixels;
import '../data/models/story_picture.dart';
import 'art_assets.dart';

/// A picture that can be laid as a full-screen backdrop: its size in pixels
/// (as the file is) and how it is laid ([look]).
@immutable
class BackdropPicture {
  const BackdropPicture(this.pixels, [this.look = const BackdropLook()]);

  final ScenePixels pixels;
  final BackdropLook look;
}

/// How each picture is laid when it fills the screen behind the story (the
/// case's opening, the Discovery Moment, the scene after a mission): which
/// part must be seen ([BackdropLook.focus]), which part may never be
/// ([BackdropLook.bounds]), and how ([BackdropFit]). Presentation only:
/// the same picture is laid the same way on every one of those screens, so
/// one place never jumps in size from one screen to the next.
abstract final class BackdropArt {
  /// The London landmark prints (about 400 × 256, a thin paper frame and the
  /// place's name plate along the bottom): only the scene above the plate,
  /// inside the frame ([ArtAssets.scenePrint]).
  static const printScene = Rect.fromLTRB(0.045, 0.045, 0.955, 0.68);

  /// The most a print is enlarged (screen points per print pixel): a phone
  /// shows it across its width; a tablet, no larger than this.
  static const printMaxScale = 1.5;

  /// The most a photo-sized picture is enlarged on the largest screens.
  static const photoMaxScale = 1.6;

  static const _london = 'assets/seasons/season_01_london/locations';
  static const _objects = 'assets/seasons/season_01_london/objects';
  static const _paris = 'assets/seasons/season_02_paris/cases';

  static const _wide = ScenePixels(1536, 1024);
  static const _tall = ScenePixels(1024, 1536);

  /// A landmark print: never enlarged past the screen's width, the room
  /// above and below it filled.
  static BackdropPicture _print(double w, double h, [Rect focus = printScene]) =>
      BackdropPicture(ScenePixels(w, h), BackdropLook(bounds: printScene, focus: focus, maxScale: printMaxScale));

  /// A part of a [w] × [h] picture, in its pixels, as fractions.
  static Rect _px(double w, double h, double l, double t, double r, double b) => Rect.fromLTRB(l / w, t / h, r / w, b / h);

  /// A part of a 1536 × 1024 picture, in its pixels.
  static Rect _wpx(double l, double t, double r, double b) => _px(1536, 1024, l, t, r, b);

  /// The scene inside a print's worn paper edge (Season 1's places inside
  /// a landmark, its doors and its chest, its market hall).
  static const paperEdge = Rect.fromLTRB(0.045, 0.045, 0.955, 0.955);

  /// A Season 1 print on paper: inside its edge, its subject (in its
  /// pixels) whole.
  static BackdropPicture _inPaper(double w, double h, double l, double t, double r, double b) =>
      BackdropPicture(ScenePixels(w, h), BackdropLook(bounds: paperEdge, focus: _px(w, h, l, t, r, b)));

  /// A 1536 × 1024 picture, its subject (in its pixels) whole.
  static BackdropPicture _focus(double l, double t, double r, double b) =>
      BackdropPicture(_wide, BackdropLook(focus: _wpx(l, t, r, b)));

  static final Map<String, BackdropPicture> pictures = {
    // ── Season 1: the nine landmark prints ──
    '$_london/landmarks/kings_cross.png': _print(404, 264),
    '$_london/landmarks/british_museum.png': _print(401, 259),
    '$_london/landmarks/covent_garden.png': _print(400, 253),
    // The palace and the clock tower whole: the clock face is Case 02's.
    '$_london/landmarks/big_ben.png': _print(395, 258, Rect.fromLTRB(0.22, 0.045, 0.72, 0.68)),
    '$_london/landmarks/hyde_park.png': _print(401, 254),
    '$_london/landmarks/buckingham_palace.png': _print(401, 254),
    '$_london/landmarks/tower_bridge.png': _print(397, 258),
    '$_london/landmarks/tower_of_london.png': _print(397, 260),
    '$_london/landmarks/london_eye.png': _print(400, 256),
    // ── Season 1: places inside a landmark, the doors and the chest ──
    // Printed like the landmarks, on paper with a worn edge: only the scene
    // inside it ([paperEdge]), its subject whole.
    '$_london/british_museum/british_museum_great_court.png': _inPaper(1264, 848, 340, 280, 930, 700), // the reading room
    '$_london/british_museum/british_museum_egypt_room.png': _inPaper(1264, 848, 370, 100, 1000, 700), // the pharaohs
    '$_london/british_museum/british_museum_gallery_8.png': _inPaper(1536, 1024, 600, 330, 1400, 900), // the empty frame
    '$_london/hyde_park/hyde_park_boathouse.png': _inPaper(1288, 816, 470, 140, 1010, 640),
    '$_london/hyde_park/hyde_park_rose_garden.png': _inPaper(1288, 816, 330, 250, 960, 700), // the fountain
    '$_london/buckingham_palace/buckingham_palace_palace_staff_room.png': _inPaper(1288, 816, 320, 150, 970, 700),
    '$_london/buckingham_palace/buckingham_palace_palace_courtyard.png': _inPaper(1288, 816, 320, 150, 970, 700),
    '$_london/covent_garden/covent_garden_dressing_room.png': _inPaper(1290, 816, 320, 150, 970, 700),
    '$_london/covent_garden/covent_garden_theatre.png': _inPaper(1536, 1024, 380, 150, 1160, 820), // the stage
    '$_london/covent_garden/theatre_door_dark.png': _inPaper(1536, 1024, 500, 60, 1150, 880), // the open doors
    '$_london/kings_cross/kings_cross_waiting_hall.png': _inPaper(1273, 832, 420, 190, 880, 600), // the clock
    '$_london/royal_archive/royal_archive.png': _inPaper(1536, 1024, 150, 40, 1100, 800), // banner, the open book
    '$_objects/locked_door_gears.png': _inPaper(1536, 1024, 430, 40, 1140, 970), // the dial and its gears
    '$_objects/small_iron_door.png': _inPaper(1536, 1024, 520, 170, 1050, 880),
    '$_objects/iron_chest.png': _inPaper(1536, 1024, 380, 290, 1290, 900),
    // Case 06's market hall, a portrait picture: it covers the screen,
    // inside its paper edge.
    ArtAssets.marketHall: const BackdropPicture(_tall, BackdropLook(fit: BackdropFit.cover, bounds: paperEdge)),
    // ── Season 2 ──
    ArtAssets.season2GareDuNord: const BackdropPicture(ScenePixels(941, 1671)),
    // The painting from the brass box (Case 02 opens on it): its canvas only,
    // never the gilt frame or the night around it; the white church and its
    // domes whole.
    '$_paris/case_01/montmartre_painting.png': BackdropPicture(
      const ScenePixels(1774, 887),
      BackdropLook(
        bounds: _px(1774, 887, 230, 205, 1550, 695),
        focus: _px(1774, 887, 880, 205, 1250, 695),
        maxScale: photoMaxScale,
      ),
    ),
    '$_paris/case_01/station_hall_clocks.png': const BackdropPicture(_wide),
    // Case 02: the street with the white church above it, the red door.
    '$_paris/case_02/montmartre_street_real.png': _focus(560, 60, 1400, 880),
    '$_paris/case_02/montmartre_street_painted.png': const BackdropPicture(_wide),
    // The studio (portrait): the easel and the window on the church.
    '$_paris/case_02/painters_studio.png': BackdropPicture(_tall, BackdropLook(focus: _px(1024, 1536, 160, 150, 880, 1000))),
    // The canvas's back (Case 03 opens on it): "Paris — Toujours plus haut"
    // and the little tower drawn beside it, the clue, whole.
    '$_paris/case_02/canvas_back.png': _focus(350, 180, 870, 500),
    '$_paris/case_02/hidden_layer_sketch.png': const BackdropPicture(_wide),
    '$_paris/case_02/studio_painting_p1.png': const BackdropPicture(ScenePixels(1254, 1254)),
    '$_paris/case_03/eiffel_tower_exterior.png': const BackdropPicture(_tall),
    // The tower's entrance: the great arch of the tower whole above the gate.
    '$_paris/case_03/tower_notice_board.png': _focus(760, 0, 1400, 700),
    '$_paris/case_03/tower_lift.png': _focus(380, 100, 1150, 950),
    '$_paris/case_03/service_door.png': _focus(480, 60, 1100, 960),
    '$_paris/case_03/service_room.png': _focus(300, 100, 1240, 900),
    '$_paris/case_03/time_recording_machine_open.png': const BackdropPicture(_wide),
    // Case 04: the quays at dusk, the river and its bridge.
    '$_paris/case_04/seine_quays_dusk.png': _focus(450, 150, 1300, 800),
    '$_paris/case_04/quay_wall_marks.png': _focus(700, 150, 1500, 760), // the carved marks
    '$_paris/case_04/keeper_hut.png': _focus(400, 100, 1150, 950),
    '$_paris/case_04/keeper_hut_interior.png': const BackdropPicture(_wide),
    '$_paris/case_04/quay_boxes.png': _focus(300, 250, 1250, 900),
    '$_paris/case_04/metal_box_open.png': _focus(350, 150, 1200, 950),
    // The passage's iron gate (portrait), whole.
    '$_paris/case_04/passage_gate.png': BackdropPicture(_tall, BackdropLook(focus: _px(1024, 1536, 150, 100, 880, 1150))),
    // Case 05: the bench's marks, the four clocks, the desk, the room.
    '$_paris/case_05/workbench_marks.png': _focus(700, 250, 1536, 780),
    '$_paris/case_05/wall_of_clocks.png': _focus(190, 90, 1380, 670),
    '$_paris/case_05/writing_desk_blotter.png': BackdropPicture(
      const ScenePixels(1264, 848),
      BackdropLook(focus: _px(1264, 848, 250, 150, 1050, 750)),
    ),
    '$_paris/case_05/workshop_interior.png': _focus(640, 30, 1500, 880), // the desk and the door
    '$_paris/case_05/clock_back_extra_wheel.png': BackdropPicture(
      const ScenePixels(1024, 1024),
      BackdropLook(focus: _px(1024, 1024, 170, 40, 850, 1000)),
    ),
    // The post room's door at the Louvre: the palace and the glass pyramid
    // beyond it whole, the lamp-lit door beside them.
    '$_paris/case_06/louvre_post_room_exterior.png': _focus(700, 150, 1470, 640),
    '$_paris/case_06/post_room_hold_rack.png': _focus(230, 70, 1360, 900), // the rack, its tags
    '$_paris/case_06/archive_floor_plan.png': BackdropPicture(_tall, BackdropLook(focus: _px(1024, 1536, 180, 150, 840, 1490))),
    '$_paris/case_06/archive_room.png': _focus(200, 200, 1300, 950),
    // Case 07: the opera house at night, its archive, stage and fly rail.
    '$_paris/case_07/palais_garnier_night.png': _focus(250, 80, 1290, 780),
    '$_paris/case_07/opera_archive_room.png': _focus(300, 300, 1300, 950), // the green box
    '$_paris/case_07/stage_base.png': _focus(330, 90, 1210, 760), // the stage in its arch
    '$_paris/case_07/stage_ghost.png': _focus(330, 90, 1210, 760),
    '$_paris/case_07/fly_rail.png': _focus(240, 310, 1350, 700), // the four rope locks
    '$_paris/case_07/backdrop_back_pocket.png': _focus(500, 350, 1050, 880), // the pocket
    // Place des Abbesses: the white church on the hill and the metro
    // entrance, as the scene names them.
    '$_paris/case_08/abbesses_square.png': _focus(880, 0, 1510, 980),
    '$_paris/case_08/drawing_bundle.png': _focus(380, 250, 1200, 900), // the bundle in the wall
    // Case 09's garden: its post clock (right edge) shows ten past ten, and
    // the story has every clock of the garden at four. It is never shown.
    '$_paris/case_09/garden_model_view.png': const BackdropPicture(_wide, BackdropLook(bounds: gardenNoClock)),
    '$_paris/case_09/gear_board.png': const BackdropPicture(_wide),
    // Case 10: the arch and the roads running out from it.
    '$_paris/case_10/arc_star_view.png': _focus(380, 180, 1120, 720),
    '$_paris/case_10/star_room.png': _focus(130, 80, 1480, 900),
    '$_paris/case_10/roof_photo.png': const BackdropPicture(_wide),
    // Case 11: the street and its little door; the reading room (its
    // middle kept calm for the people talked to).
    '$_paris/case_11/annex_street.png': _focus(300, 120, 1250, 900),
    '$_paris/case_11/annex_reading_room.png': _focus(250, 150, 1300, 900),
    // Case 12: the museum hall, the room of old machines (its plinth in
    // the middle), and the morning the case ends on (the glass case).
    '$_paris/case_12/arts_metiers_hall.png': _focus(250, 100, 1300, 900),
    '$_paris/case_12/old_machine_room.png': _focus(150, 150, 1300, 850),
    '$_paris/case_12/finale_morning.png': _focus(300, 200, 1250, 950),
  };

  /// The part of Case 09's garden left of its post clock (fractions): the
  /// clock's face spans (1412, 325)–(1506, 420) of 1536 × 1024, its post
  /// further down. Nothing right of it is ever on screen.
  static const gardenNoClock = Rect.fromLTRB(0, 0, 1380 / 1536, 1);

  /// How [file] is laid as a backdrop (null: it is no backdrop picture).
  static BackdropPicture? of(String file) => pictures[file];

  /// How a story picture (Paris: the scene after a mission) is laid: a part
  /// picked out of its file ([StoryPicture.crop]) is its focus, kept whole
  /// with the scene around it; a whole file is laid as the file is. Its
  /// file's bounds hold either way.
  static BackdropLook storyLook(StoryPicture p) {
    final base = of(p.file)?.look ?? const BackdropLook();
    if (p.crop == BackdropLook.whole) return base;
    return BackdropLook(focus: p.crop, bounds: base.bounds, anchor: base.anchor);
  }
}
