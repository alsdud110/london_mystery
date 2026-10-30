import '../../models/investigation.dart' show InvestigationSpot;
import '../../models/mission.dart';
import '../../models/scene_deduction.dart';
import '../../models/scene_explore.dart' show ScenePixels;

/// Missions played by reading their place's traces (presentation only:
/// nothing here is saved). Mission id → its [DeductionScene]. A mission not
/// listed is played as before.
///
/// The clues' lines are the mission's letter (the detective's notes), and
/// the places are its options: the place chosen is checked as its answer,
/// so the feedback for a wrong place, the hints, the solve, its Clue and
/// Evidence, XP, coins and the save are the puzzle's own. Every clue and
/// place is drawn in the picture; nothing here says where the box is.
final Map<String, DeductionScene> season1Deductions = {
  // ── Case 01 M3 — the foot of Big Ben at night (1536 × 1024) ──────────
  // Muddy footprints cross the wet paving and stop at the tower wall; the
  // street lamp's light falls on one stone low in the wall; that stone has
  // pale scratches around it. Under the bench, behind that stone, under the
  // drain cover: only the stone is where all three point.
  'm03': DeductionScene(
    picture: 'assets/seasons/season_01_london/cases/case_01/big_ben_base_night.png',
    pixels: _base,
    place: 'The foot of Big Ben, at night',
    task: 'Look for three clues the thief left.',
    chooseTask: 'Where is the box hidden? Tap the place.',
    missLine: 'Nothing here. Look for marks the thief made.',
    notPlaceLine: 'The box is not there. Tap a place where it could be hidden.',
    // The paving left of the footprints: no clue, no listed place.
    guideAt: _base.at(330, 900),
    inside: _base.rect(36, 30, 1500, 992),
    // From the lamp to the drain cover, the footprints and the wall between
    // (the bench at its edge; pinching out or dragging shows the rest).
    opening: _base.rect(190, 90, 1290, 992),
    clues: [
      DeductionClue(
        id: 'footprints',
        label: 'Muddy footprints on the wet stones',
        // The trail, from the bottom of the picture up to the wall.
        areas: [_base.rect(430, 880, 720, 992), _base.rect(570, 790, 830, 880), _base.rect(720, 715, 940, 800)],
        mark: _base.at(560, 860),
        line: 'The footprints stop at the tower wall.',
      ),
      DeductionClue(
        id: 'light',
        label: 'The street lamp, and its light on the tower wall',
        // The lamp and its post; the bright patch it throws on the wall.
        areas: [_base.rect(215, 115, 345, 600), _base.rect(840, 380, 1050, 485)],
        mark: _base.at(345, 200),
        line: 'The lamp shines on one stone in the wall.',
      ),
      DeductionClue(
        id: 'scratches',
        label: 'Scratches on a stone low in the tower wall',
        // The lit block with the pale scratches.
        areas: [_base.rect(840, 492, 1035, 605)],
        mark: _base.at(1020, 510),
        line: 'That stone has fresh scratches around it.',
      ),
    ],
    others: [
      InvestigationSpot(
        label: 'A wet bench',
        areas: [_base.rect(60, 600, 335, 820)],
        line: 'A wet bench. Nobody sat here tonight.',
      ),
      InvestigationSpot(
        label: 'A round drain cover',
        areas: [_base.rect(915, 860, 1265, 990)],
        line: 'A heavy iron drain cover. Nothing on it.',
      ),
      InvestigationSpot(
        label: 'An iron railing',
        areas: [_base.rect(1230, 300, 1500, 840)],
        line: 'An iron railing. Only wet leaves here.',
      ),
      InvestigationSpot(
        label: "Big Ben's clock",
        areas: [_base.rect(555, 30, 715, 170)],
        line: "Big Ben's clock, high above you.",
      ),
      InvestigationSpot(
        label: 'The Houses of Parliament',
        areas: [_base.rect(100, 320, 555, 590)],
        line: 'The Houses of Parliament. Their windows glow.',
      ),
      InvestigationSpot(
        label: 'The tower wall',
        areas: [_base.rect(680, 170, 1230, 720)],
        line: 'Old stones of the clock tower. Look closely at them.',
      ),
    ],
    places: [
      // The bench's right end: in the opening view on every phone.
      DeductionPlace(optionId: 'a', areas: [_base.rect(60, 600, 335, 820)], mark: _base.at(285, 700)),
      // The scratched stone, and the lamp's light just above it.
      DeductionPlace(
        optionId: 'b',
        areas: [_base.rect(840, 492, 1035, 605), _base.rect(840, 380, 1050, 492)],
        mark: _base.at(938, 548),
      ),
      DeductionPlace(optionId: 'c', areas: [_base.rect(915, 860, 1265, 990)], mark: _base.at(1090, 920)),
    ],
  ),
  // ── Case 04 M2 — the platforms (cases/case_04/kings_cross_platforms.png)
  // Four platform arches in a row, their sign boards blank: a big white
  // clock over the first, a small red clock over the second, no clock but a
  // red door beside the third, a green clock over the fourth. Each one,
  // tapped, notes the porter's line about it (word for word: Case 12 reads
  // "Platform 4 has a small red clock." again), so the numbers come from the
  // English; then the card's three words pick one platform. The red door is
  // the trap the porter's "but no clock" answers.
  'ep04_m2': DeductionScene(
    picture: 'assets/seasons/season_01_london/cases/case_04/kings_cross_platforms.png',
    pixels: _platforms,
    place: "King's Cross: four platforms, their clocks and a red door",
    task: 'Tap each platform. Listen to the porter.',
    chooseTask: 'RED · SMALL · CLOCK. Tap the platform.',
    missLine: 'Nothing here. Look up at each platform.',
    notPlaceLine: 'Tap one of the four platforms.',
    action: 'LOOK UNDER THE CLOCK',
    // The floor in the middle: no platform, no thing.
    guideAt: _platforms.at(770, 850),
    inside: _platforms.rect(44, 48, 1494, 985),
    opening: _platforms.rect(44, 48, 1494, 985),
    clues: [
      DeductionClue(
        id: 'p1',
        label: 'A big white clock over the first platform',
        areas: [_platforms.rect(165, 70, 345, 285)],
        mark: _platforms.at(335, 95),
        line: 'Platform 1 has a big white clock.',
      ),
      DeductionClue(
        id: 'p4',
        label: 'A small red clock over the second platform',
        areas: [_platforms.rect(525, 150, 655, 280)],
        mark: _platforms.at(645, 165),
        line: 'Platform 4 has a small red clock.',
      ),
      DeductionClue(
        id: 'p7',
        label: 'A red door beside the third platform, and no clock over it',
        // The door, and the empty brick above the arch where a clock is not.
        areas: [_platforms.rect(1035, 485, 1150, 740), _platforms.rect(800, 170, 1020, 300)],
        mark: _platforms.at(1145, 500),
        line: 'Platform 7 has a red door, but no clock.',
      ),
      DeductionClue(
        id: 'p9',
        label: 'A green clock over the fourth platform',
        areas: [_platforms.rect(1220, 150, 1355, 300)],
        mark: _platforms.at(1345, 170),
        line: 'Platform 9 has a green clock.',
      ),
    ],
    others: [
      InvestigationSpot(
        label: "A porter's trolley",
        areas: [_platforms.rect(75, 680, 495, 955)],
        line: "A porter's trolley. It is empty.",
      ),
      InvestigationSpot(
        label: 'A wooden bench',
        areas: [_platforms.rect(1080, 750, 1475, 970)],
        line: 'A wooden bench. Nobody is waiting here.',
      ),
    ],
    places: [
      DeductionPlace(optionId: 'a', areas: [_platforms.rect(70, 70, 405, 730)], mark: _platforms.at(240, 560)),
      DeductionPlace(optionId: 'b', areas: [_platforms.rect(425, 150, 730, 730)], mark: _platforms.at(580, 560)),
      DeductionPlace(
        optionId: 'c',
        areas: [_platforms.rect(775, 170, 1030, 730), _platforms.rect(1030, 485, 1150, 740)],
        mark: _platforms.at(900, 560),
      ),
      DeductionPlace(optionId: 'd', areas: [_platforms.rect(1155, 150, 1440, 740)], mark: _platforms.at(1280, 560)),
    ],
  ),
};

/// The traces of [m]'s place to read, or null when [m] is played as before.
DeductionScene? deductionOf(Mission m) => season1Deductions[m.id];

// The foot of Big Ben at night, in pixels.
const _base = ScenePixels(1536, 1024);

// Case 04's four platforms, in pixels.
const _platforms = ScenePixels(1536, 1024);
