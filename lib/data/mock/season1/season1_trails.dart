import '../../models/mission.dart';
import '../../models/scene_explore.dart' show ScenePixels;
import '../../models/scene_trail.dart';

/// Sequence puzzles played on their place (presentation only: nothing here
/// is saved). Mission id → its [TrailScene]. A mission not listed is played
/// through its buttons as before.
///
/// The case data is left as it is: the order tapped is the buttons' answer
/// (option ids joined by commas), so the check, the feedback for a known
/// wrong order, the solve, its Clue and Evidence, XP, coins and the save are
/// the ones the puzzle always gave.
final Map<String, TrailScene> season1Trails = {
  // ── Case 03 M3 — the Great Court (cases/case_03/great_court_footprints.png)
  // Four footprints, one by each place the cleaner names: the shop (back
  // left), the stairs (front left), the café (front right) and the north
  // door (back, in the middle). All four are drawn alike — the same boot,
  // the same damp grey — and the places are not in the order walked (front
  // to back, or left to right, is wrong), so only her words "very wet",
  // "wet", "a little wet" and "almost dry" give the order.
  'ep03_m3': TrailScene(
    picture: 'assets/seasons/season_01_london/cases/case_03/great_court_footprints.png',
    pixels: _court,
    place: 'The Great Court: a shop, the stairs, a café and the north door, a footprint by each',
    lead: 'Four footprints cross the floor. Tap them in the order she walked.',
    guide: 'Tap a footprint to number it. Tap it again to take it back.',
    inside: _court.rect(42, 40, 1494, 985),
    stops: [
      // The shop counter at the back on the left, its footprint in front.
      TrailStop(optionId: 'shop', areas: [_court.rect(40, 170, 410, 520)], mark: _court.at(328, 500)),
      // The bottom of the curved stairs, front left.
      TrailStop(optionId: 'stairs', areas: [_court.rect(40, 520, 340, 905)], mark: _court.at(288, 856)),
      // The café's round tables, front right.
      TrailStop(optionId: 'cafe', areas: [_court.rect(1110, 480, 1460, 930)], mark: _court.at(1152, 885)),
      // The open north doors at the back, in the middle.
      TrailStop(optionId: 'door', areas: [_court.rect(730, 180, 910, 440)], mark: _court.at(822, 412)),
    ],
  ),
};

/// [m]'s trail, or null when [m] is played through its buttons.
TrailScene? trailOf(Mission m) => season1Trails[m.id];

// The Great Court with its four footprints, in pixels.
const _court = ScenePixels(1536, 1024);
