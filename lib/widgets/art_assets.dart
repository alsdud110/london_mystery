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
  /// Scene pictures (mission, final, image choices, Case Solved photo).
  /// Full colour, 4:3, e.g. `Artwork.boathouse: 'assets/art/scenes/boathouse.png'`.
  static const Map<Artwork, String> scenes = {};

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
