import '../../models/investigation.dart' show InvestigationSpot;
import '../../models/mission.dart';
import '../../models/scene_explore.dart';

/// Missions played by looking round their place (presentation only: nothing
/// here is saved). Mission id → its [ExploreScene]. A mission not listed is
/// played as before.
///
/// The case data is left as it is: the letter read in the scene is the
/// mission's letter, the pictures to choose from are its options (their
/// labels), and the choice is checked as its answer, so the feedback for a
/// wrong one, the hints, the solve, its Clue and Evidence, XP, coins and
/// the save are the ones the puzzle always gave.
final Map<String, ExploreScene> season1Explores = {
  // ── Case 01 M1 — King's Cross at night (1536 × 1024) ─────────────────
  // The detective finds the old suitcase on the bench and the thief's
  // letter in it ("old mummies from Egypt and a famous stone"), then picks
  // the museum on the station's poster board. Platform 9's sign is there
  // to look at (the case's clue for the final lock, saved with the solve
  // as always): never needed to go on.
  'm01': ExploreScene(
    picture: 'assets/images/case01/kings_cross_platform_night.png',
    pixels: _platform,
    place: "King's Cross station at night",
    task: 'Look around the station. Your first clue is waiting!',
    nextTask: 'Where is the thief going? Check the museum posters.',
    missLine: 'Nothing here. Look for something the thief left behind.',
    // The suitcase first: the first thing a new detective looks at.
    guideAt: _platform.at(402, 752),
    // The picture inside its printed paper edge; the page opens on the
    // suitcase, the sign and the board.
    inside: _platform.rect(40, 32, 1496, 988),
    opening: _platform.rect(240, 80, 1330, 900),
    spots: [
      ExploreSpot(
        id: 'suitcase',
        kind: ExploreKind.document,
        title: 'THE OLD SUITCASE',
        label: 'An old suitcase on the bench',
        // The case and its handle and label, on the bench.
        areas: [_platform.rect(282, 660, 522, 848)],
        mark: _platform.at(512, 668),
      ),
      ExploreSpot(
        id: 'platform',
        kind: ExploreKind.note,
        title: 'PLATFORM 9',
        label: 'The Platform 9 sign',
        // The hanging sign, from its bracket down.
        areas: [_platform.rect(648, 104, 830, 286)],
        mark: _platform.at(840, 298),
        // The case's own clue note (Case 01 M1's Clue).
        line: 'The suitcase was next to Platform 9.',
      ),
      ExploreSpot(
        id: 'posters',
        kind: ExploreKind.choice,
        title: 'NEXT DESTINATION',
        label: 'A board of museum posters',
        // The board, from its top to its feet (the clock above is its own).
        areas: [_platform.rect(836, 300, 1292, 876)],
        mark: _platform.at(1250, 330),
        requires: 'suitcase',
        lockedLine: 'Museum posters! But where is the thief going? Find a clue first.',
        unreadLine: 'Read the letter in the suitcase first.',
      ),
    ],
    others: [
      InvestigationSpot(
        label: "The King's Cross sign",
        areas: [_platform.rect(72, 70, 402, 345)],
        line: "King's Cross. You are at the right station.",
      ),
      InvestigationSpot(
        label: 'A railway map',
        areas: [_platform.rect(122, 262, 406, 625)],
        line: 'A map of the railway. No message here.',
      ),
      InvestigationSpot(
        label: 'The station clock',
        areas: [_platform.rect(868, 146, 1030, 297)],
        line: 'The station clock. It is very late.',
      ),
      InvestigationSpot(
        label: 'A luggage trolley',
        areas: [_platform.rect(676, 545, 812, 722)],
        line: 'Bags on a trolley. They are all locked.',
      ),
      InvestigationSpot(
        label: 'A train',
        areas: [_platform.rect(1294, 250, 1494, 840)],
        line: 'A train is waiting. Nothing to find here.',
      ),
      InvestigationSpot(
        label: 'The bench',
        areas: [_platform.rect(150, 618, 642, 965)],
        line: 'A wooden bench. Look at what is on it!',
      ),
      InvestigationSpot(
        label: 'A post box',
        areas: [_platform.rect(50, 615, 150, 940)],
        line: 'A post box. Nothing for you inside.',
      ),
    ],
    choiceTitle: 'NEXT DESTINATION',
    choiceHow: 'Which museum has the things in the letter? Tap one poster.',
    pictureAspect: 1086 / 1448,
    choices: [
      ExplorePicture(
        optionId: 'a',
        picture: 'assets/images/case01/poster_natural_history.png',
        description: 'a dinosaur skeleton in a great hall',
      ),
      ExplorePicture(
        optionId: 'b',
        picture: 'assets/images/case01/poster_british_museum.png',
        description: 'a golden pharaoh, a mummy case and a big stone covered in writing',
      ),
      ExplorePicture(
        optionId: 'c',
        picture: 'assets/images/case01/poster_transport.png',
        description: 'a steam train, a red double-decker bus and an old car',
      ),
      ExplorePicture(
        optionId: 'd',
        picture: 'assets/images/case01/poster_science.png',
        description: 'a rocket, a telescope and planets',
      ),
    ],
  ),
};

/// The look round [m]'s place, or null when [m] is played as before.
ExploreScene? exploreOf(Mission m) => season1Explores[m.id];

// King's Cross at night, in pixels.
const _platform = ScenePixels(1536, 1024);
