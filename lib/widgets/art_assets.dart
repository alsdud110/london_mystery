import 'dart:ui' show Size;

import '../data/models/mission.dart';
import '../features/game/scoring.dart';

/// The one place where finished artwork files are plugged in.
///
/// Every picture in the game is drawn in code today: scenes by `LandmarkArt`,
/// symbols and badges by the Ink Icon System (or a monogram while a drawing
/// is still a Custom Asset Required). When an illustrator delivers a file,
/// add it under `assets/art/`, list the folder in pubspec.yaml, and add one
/// line here. No screen changes. A missing or broken file falls back to the
/// drawing, so the game never shows an empty frame.
///
/// Files are PNG (or WebP/JPEG) loaded with `Image.asset`, with no extra
/// packages. SVG would need a new dependency and is not used.
abstract final class ArtAssets {
  /// The Mission Map artwork: a 3:2 landscape London map ([londonMapAspect]).
  /// Streets, river and landmarks only; pins and place names are drawn by
  /// the app (landmark positions: `Landmark` in `map_world.dart`). A missing
  /// or broken file falls back to the map drawn in code (`LondonMapPainter`).
  static const londonMap = 'assets/images/london_mystery.png';

  /// Width / height of [londonMap]: the map world keeps this ratio (never
  /// stretched); the map camera shows one part of it at a time.
  static const londonMapAspect = 3 / 2;

  /// Pixel size of [londonMap]: it is never decoded larger than this.
  static const londonMapPixels = Size(1536, 1024);

  /// The title screen: the detective's office at night — lamp, desk with a
  /// map, magnifying glass and sealed letter, and London (Big Ben, the moon)
  /// through the window (portrait, no text). The title screen only.
  static const titleDetectiveOffice = 'assets/images/title/title_detective_office.png';

  /// Pixel size of [titleDetectiveOffice] (never decoded larger).
  static const titleDetectiveOfficePixels = Size(941, 1672);

  /// The Season 1 cover: London from above at night — the whole city, the
  /// Thames, Big Ben, and a young detective looking out over it from a
  /// balcony (portrait, no text). The cover only: the opening's first scene
  /// has its own picture ([season1LondonNight]), closer in.
  static const season1CoverLondonPanorama = 'assets/images/season1/season1_cover_london_panorama.png';

  /// Pixel size of [season1CoverLondonPanorama] (never decoded larger).
  static const season1CoverLondonPanoramaPixels = Size(941, 1672);

  /// The first scene of the Season 1 opening: London at night — Big Ben,
  /// Westminster, the Thames, a gas lamp (portrait, no text). Shown full
  /// screen once, as that scene's hero picture; used nowhere else, so the
  /// opening keeps its moment. Missing → the London drawn in code.
  static const season1LondonNight = 'assets/images/season1/season1_london_night.png';

  /// Pixel size of [season1LondonNight] (never decoded larger).
  static const season1LondonNightPixels = Size(941, 1672);

  /// Scene pictures (mission, final, image choices, the arrival at a place,
  /// Case Solved photo), full colour: the nine London landmarks in
  /// `scenes/landmarks/`, and the places inside a landmark in a folder named
  /// after it. A place inside a landmark (the Boathouse in Hyde Park) never
  /// borrows its landmark's picture: without its own it is drawn in code.
  static const Map<Artwork, String> scenes = {
    ...landmarkScenes,
    ...insideScenes,
    ...objectScenes,
  };

  /// Scenes shown by a character or object picture: the Tower raven (Poppy)
  /// for the raven scenes, the old brown suitcase where the story finds one.
  static const objectScenes = <Artwork, String>{
    Artwork.raven: '${_art}characters/raven_master.png',
    Artwork.oldSuitcase: '${_art}objects/suitcase.png',
  };

  /// Width / height of each scene picture that is not printed like the
  /// landmark set ([scenePrint]): frames take the picture's own ratio.
  static const sceneAspects = <Artwork, double>{
    Artwork.raven: 1,
    Artwork.oldSuitcase: 1,
    Artwork.greatCourt: 1264 / 848,
    Artwork.egyptRoom: 1264 / 848,
    Artwork.boathouse: 1288 / 816,
    Artwork.roseGarden: 1288 / 816,
    Artwork.staffRoom: 1288 / 816,
    Artwork.courtyard: 1288 / 816,
    Artwork.dressingRoom: 1290 / 816,
    Artwork.waitingRoom: 1273 / 832,
  };

  /// Width / height of the picture of [a] ([scenePrint] unless listed).
  static double sceneAspect(Artwork a) => sceneAspects[a] ?? scenePrint.size.aspectRatio;

  /// Recurring characters (full colour, on parchment, square).
  static const characters = <String, String>{
    'raven': '${_art}characters/raven_master.png',
    'clockmaker': '${_art}characters/clockmaker_master.png',
  };

  /// Story objects (full colour, on parchment, square except the map).
  static const objects = <String, String>{
    'crown': '${_art}objects/crown.png',
    'key': '${_art}objects/key.png',
    'letter': '${_art}objects/letter.png',
    'map': '${_art}objects/map.png',
    'pocketWatch': '${_art}objects/pocket_watch.png',
    'suitcase': '${_art}objects/suitcase.png',
  };

  /// The Raven Society mark (full colour, not a tinted [symbols] glyph).
  static const ravenMark = '${_art}symbols/raven_mark.png';

  /// Special pictures. The theatre royal box: listed, not shown yet — the
  /// game's Royal Box (Case 01) is a golden box with the Crown inside.
  static const special = <String, String>{
    'theatreRoyalBox': '${_art}special/royal_box.png',
  };

  /// Evidence shown by its real picture (notebook, zoom, celebrations),
  /// by evidence id. Only where the picture agrees with what the evidence
  /// says: Case 01's watch (stopped at 7) and map (two swans), whose numbers
  /// open the Royal Box, keep their drawn marks, as do the maps whose drawn
  /// ravens the pictures lack.
  static const evidencePictures = <String, String>{
    'e01': '${_art}objects/letter.png', // Old Letter
    'e02': '${_art}objects/key.png', // Golden Key
    'e06': '${_art}objects/crown.png', // The Missing Crown
    'ep04_e1': ravenMark, // Black Wax Seal: a raven pressed into the wax
    'ep05_e3': '${_art}objects/key.png', // Brass Key
    'ep10_e3': '${_art}objects/letter.png', // Ravenmaster's Letter
    'ep12_e4': '${_art}objects/pocket_watch.png', // The Clockmaker's Watch
  };

  static const _art = 'assets/art/';

  /// The nine London landmarks.
  static const landmarkScenes = <Artwork, String>{
    Artwork.kingsCross: '$_scenes/landmarks/kings_cross.png',
    Artwork.britishMuseum: '$_scenes/landmarks/british_museum.png',
    Artwork.coventGarden: '$_scenes/landmarks/covent_garden.png',
    Artwork.bigBen: '$_scenes/landmarks/big_ben.png',
    Artwork.hydePark: '$_scenes/landmarks/hyde_park.png',
    Artwork.buckinghamPalace: '$_scenes/landmarks/buckingham_palace.png',
    Artwork.towerBridge: '$_scenes/landmarks/tower_bridge.png',
    Artwork.towerOfLondon: '$_scenes/landmarks/tower_of_london.png',
    Artwork.londonEye: '$_scenes/landmarks/london_eye.png',
  };

  /// Places inside a landmark, each in its landmark's folder.
  static const insideScenes = <Artwork, String>{
    Artwork.greatCourt: '$_scenes/british_museum/british_museum_great_court.png',
    Artwork.egyptRoom: '$_scenes/british_museum/british_museum_egypt_room.png',
    Artwork.boathouse: '$_scenes/hyde_park/hyde_park_boathouse.png',
    Artwork.roseGarden: '$_scenes/hyde_park/hyde_park_rose_garden.png',
    Artwork.staffRoom: '$_scenes/buckingham_palace/buckingham_palace_palace_staff_room.png',
    Artwork.courtyard: '$_scenes/buckingham_palace/buckingham_palace_palace_courtyard.png',
    Artwork.dressingRoom: '$_scenes/covent_garden/covent_garden_dressing_room.png',
    Artwork.waitingRoom: '$_scenes/kings_cross/kings_cross_waiting_hall.png',
  };

  static const _scenes = 'assets/art/scenes';

  /// How the scene pictures are printed (about 400×256, a thin paper frame;
  /// the landmark set also has the place's name plate along the bottom).
  /// They show whole, in frames of this ratio. Only where a name must not
  /// show (an image-choice answer, always a landmark) is the part above
  /// [nameTop] shown, inside the [frame].
  /// Fractions of the picture's width / height.
  static const scenePrint = (size: Size(400, 256), frame: 0.045, nameTop: 0.68);

  /// A scene after its case is solved (only scenes that change, e.g. the
  /// Case 02 clock at 9:17). Without one, the solved scene stays drawn in
  /// code so its change still shows.
  static const Map<Artwork, String> solvedScenes = {};

  /// Symbol pictures (clue stamps, evidence, lock dials), keyed like
  /// `GameSymbol`, e.g. `'park': 'assets/art/symbols/park.png'`.
  /// One-colour artwork on transparency: the game tints it with the symbol's
  /// colour, as it does the ink glyphs.
  static const Map<String, String> symbols = {};

  /// Badge medal pictures, e.g. `GameBadge.sharpEyes: 'assets/art/badges/sharp_eyes.png'`.
  /// One-colour on transparency, tinted like the glyph it replaces.
  static const Map<GameBadge, String> badges = {};

  /// The file for [artwork], or null to keep the drawing. While a scene that
  /// changes when solved is being solved (or after), only its solved picture
  /// is used; without one, the drawing shows the change.
  static String? scene(Artwork artwork, {double solved = 0}) =>
      solved > 0 && changesWhenSolved.contains(artwork) ? solvedScenes[artwork] : scenes[artwork];

  /// Scenes that are drawn differently once their case is solved.
  static const changesWhenSolved = {Artwork.clockFace};
}
