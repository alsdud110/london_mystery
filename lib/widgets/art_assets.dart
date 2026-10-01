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

  /// Scene pictures (mission, final, image choices, Case Solved photo).
  /// Full colour, e.g. `Artwork.boathouse: 'assets/art/scenes/boathouse.png'`.
  /// A place drawn through a stand-in (`LandmarkArt.standIns`) uses its
  /// stand-in's picture until it has one of its own.
  static const Map<Artwork, String> scenes = {
    Artwork.kingsCross: 'assets/art/scenes/kings_cross.png',
    Artwork.britishMuseum: 'assets/art/scenes/british_museum.png',
    Artwork.bigBen: 'assets/art/scenes/big_ben.png',
    Artwork.hydePark: 'assets/art/scenes/hyde_park.png',
    Artwork.buckinghamPalace: 'assets/art/scenes/buckingham_palace.png',
    Artwork.towerBridge: 'assets/art/scenes/tower_bridge.png',
    Artwork.londonEye: 'assets/art/scenes/london_eye.png',
    Artwork.towerOfLondon: 'assets/art/scenes/tower_of_london.png',
    Artwork.coventGarden: 'assets/art/scenes/covent_garden.png',
  };

  /// How the scene pictures are printed (the landmark set: about 400×256,
  /// a thin paper frame, the place's name plate along the bottom).
  /// [frame] is trimmed on every side, because the game already frames each
  /// picture; below [nameTop] is the name plate, cut off wherever the name
  /// must not show (an image-choice answer) or would be too small to read.
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
