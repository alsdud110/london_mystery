import 'dart:ui' show Offset, Size;

import '../data/models/mission.dart';
import '../features/game/scoring.dart';

/// The two pictures of the Royal Box: shut, and open with the Crown inside.
typedef RoyalBoxArt = ({String closed, String open});

/// A clock face picture with no hands, and the hands drawn over it: where
/// its pivot is and how long its hands are (fractions of the picture's
/// width / height), and the time it shows before and after its case is
/// solved (hours, minutes).
typedef ClockHandsArt = ({
  Offset pivot,
  double hourLength,
  double minuteLength,
  ({int hour, int minute}) before,
  ({int hour, int minute}) after,
});

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
  /// for the raven scenes, the old brown suitcase where the story finds one,
  /// and the Royal Box as it is once found: open, the Crown inside (the case
  /// photo; the final case itself animates [royalBox]). Never `special/
  /// royal_box.png`: that is a theatre's royal box. Mrs Robin's black
  /// suitcase (Case 08, its name tag washed blank). Case 09's open glass
  /// case, its cushion empty and a card left on it. The two doors, each for
  /// its own case: the White Tower's, a dial and the four gears the final
  /// lock asks about (Case 05), and the small iron door under Big Ben
  /// (Case 12).
  ///
  /// Not here, on purpose: `objects/jewel_case.png` (a full red box with a
  /// tiara: Case 09's glass case is empty, the Blue Star is a blue jewel) and
  /// `objects/locked_door.png` (a plain arched wooden door, neither case's).
  /// That door is the Season opening's "doors found locked" print only.
  static const objectScenes = <Artwork, String>{
    Artwork.raven: '${_art}characters/raven_master.png',
    Artwork.oldSuitcase: '${_art}objects/suitcase.png',
    Artwork.royalBox: '${_art}special/royal_box_open.png',
    Artwork.blackSuitcase: '${_art}objects/suitcase_black.png',
    Artwork.jewelCase: '${_art}objects/empty_glass_jewel_case.png',
    Artwork.gearDoor: '${_art}objects/locked_door_gears.png',
    Artwork.ironDoor: '${_art}objects/small_iron_door.png',
    // The iron chest behind the White Tower's door (Case 05's final).
    Artwork.ironChest: '${_art}objects/iron_chest.png',
    // Big Ben's clock (Case 02): its face with no hands (the hands are drawn
    // over it: [clockHands]), and the wheels behind it, no time to read.
    Artwork.clockFace: '$_scenes/big_ben/clock_face.png',
    Artwork.clockMechanism: '$_scenes/big_ben/clock_mechanism.png',
  };

  /// Width / height of each scene picture that is not printed like the
  /// landmark set ([scenePrint]): frames take the picture's own ratio.
  static const sceneAspects = <Artwork, double>{
    Artwork.raven: 1,
    Artwork.oldSuitcase: 1,
    Artwork.royalBox: 885 / 868,
    Artwork.greatCourt: 1264 / 848,
    Artwork.egyptRoom: 1264 / 848,
    Artwork.boathouse: 1288 / 816,
    Artwork.roseGarden: 1288 / 816,
    Artwork.staffRoom: 1288 / 816,
    Artwork.courtyard: 1288 / 816,
    Artwork.dressingRoom: 1290 / 816,
    Artwork.waitingRoom: 1273 / 832,
    Artwork.gallery: 1536 / 1024,
    Artwork.auditorium: 1536 / 1024,
    Artwork.blackSuitcase: 1377 / 1142,
    Artwork.jewelCase: 1536 / 1024,
    Artwork.gearDoor: 1536 / 1024,
    Artwork.ironDoor: 1536 / 1024,
    Artwork.theatreDoor: 1536 / 1024,
    Artwork.ironChest: 1536 / 1024,
    Artwork.royalArchive: 1536 / 1024,
    Artwork.clockFace: 1,
    Artwork.clockMechanism: 1536 / 1024,
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

  /// The Season opening's prints of trouble, cut out on transparency: a
  /// stranger hiding his face (no one in particular: never the Clockmaker
  /// or the Ravenmaster) and a locked old door (mood only, no case's door).
  static const mysteriousStranger = '${_art}characters/mysterious_stranger.png';
  static const lockedDoor = '${_art}objects/locked_door.png';

  /// The Raven Society mark (full colour, not a tinted [symbols] glyph).
  static const ravenMark = '${_art}symbols/raven_mark.png';

  /// Case 01's Royal Box (the final mission's golden box with the Crown
  /// inside), as two pictures on transparency: shut, and open with the
  /// Crown in it — the same box on near-identical canvases (the same empty
  /// band under it), so fitted into the same space from the bottom they
  /// stay in register. The opening animation crossfades the two over the
  /// code-drawn light rays; a missing picture falls back to the box drawn in
  /// code (`RoyalBoxAnimation`).
  static const RoyalBoxArt royalBox = (
    closed: '${_art}special/royal_box_closed.png',
    open: '${_art}special/royal_box_open.png',
  );

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
    // Gallery 8 (Case 03) and the theatre's auditorium (Case 11).
    Artwork.gallery: '$_scenes/british_museum/british_museum_gallery.png',
    Artwork.auditorium: '$_scenes/covent_garden/covent_garden_theatre.png',
    // The theatre's door at night (Case 06; the file keeps its delivered name).
    Artwork.theatreDoor: '$_scenes/covent_garden/theatre_door_dark.png',
    // The Royal Archive, down the secret stairs of Buckingham Palace (its own
    // folder: it is no landmark of the map).
    Artwork.royalArchive: '$_scenes/royal_archive/royal_archive.png',
  };

  static const _scenes = 'assets/art/scenes';

  /// How the scene pictures are printed (about 400×256, a thin paper frame;
  /// the landmark set also has the place's name plate along the bottom).
  /// They show whole, in frames of this ratio. Only where a name must not
  /// show (an image-choice answer, always a landmark) is the part above
  /// [nameTop] shown, inside the [frame].
  /// Fractions of the picture's width / height.
  static const scenePrint = (size: Size(400, 256), frame: 0.045, nameTop: 0.68);

  /// A scene after its case is solved, when it is another picture (none
  /// today: Case 02's clock keeps its face and turns its drawn hands).
  static const Map<Artwork, String> solvedScenes = {};

  /// Clock faces whose hands are drawn over the picture. Case 02: Big Ben
  /// stopped at 8:17, set to 9:17 when the case is solved. The pivot and the
  /// hands are measured on `big_ben/clock_face.png` (1254 × 1254: the pivot
  /// at 627, 548; the numerals' ring about 337 px out).
  static const Map<Artwork, ClockHandsArt> clockHands = {
    Artwork.clockFace: (
      pivot: Offset(0.5, 0.437),
      hourLength: 0.185,
      minuteLength: 0.30,
      before: (hour: 8, minute: 17),
      after: (hour: 9, minute: 17),
    ),
  };

  /// Symbol pictures (clue stamps, evidence, lock dials), keyed like
  /// `GameSymbol`, e.g. `'park': 'assets/art/symbols/park.png'`.
  /// One-colour artwork on transparency: the game tints it with the symbol's
  /// colour, as it does the ink glyphs.
  static const Map<String, String> symbols = {};

  /// Badge medal pictures, e.g. `GameBadge.sharpEyes: 'assets/art/badges/sharp_eyes.png'`.
  /// One-colour on transparency, tinted like the glyph it replaces.
  static const Map<GameBadge, String> badges = {};

  /// The file for [artwork], or null to keep the drawing. Once a scene that
  /// changes when solved is being solved (or after), its solved picture if
  /// it has one, else its own picture (its change is drawn over it).
  static String? scene(Artwork artwork, {double solved = 0}) =>
      solved > 0 && changesWhenSolved.contains(artwork) ? solvedScenes[artwork] ?? scenes[artwork] : scenes[artwork];

  /// Scenes that show differently once their case is solved (the clock's
  /// drawn hands; drawn in code, its hands turn too).
  static const changesWhenSolved = {Artwork.clockFace};
}
