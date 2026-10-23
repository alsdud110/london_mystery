import '../../models/mission.dart';
import '../../models/scene_explore.dart' show ScenePixels;
import '../../models/scene_inspect.dart';

/// Missions played by examining their exhibits under a magnifying glass
/// (presentation only: nothing here is saved). Mission id → its
/// [InspectScene]. A mission not listed is played as before.
///
/// The case data is left as it is: the note is the mission's letter, its
/// lines ticked as the exhibits confirm them; the label is the mission's
/// prompt; the word written there is checked as its answer, so the
/// feedback for a known wrong word, the hints, the solve, its Clue and
/// Evidence, XP, coins and the save are the ones the puzzle always gave.
///
/// The answer is never written here: no line says the word the label is
/// missing (the note's meaning and the first letter's "a famous …" give
/// it), and the hidden key's card does not say what it was under.
final Map<String, InspectScene> season1Inspections = {
  // ── Case 01 M2 — Room 4 of the British Museum, at night (1536 × 1024) ─
  // The note: 0 "It helped people read old Egyptian writing.", 1 "Its name
  // has two words.", 2 "The first word is ROSETTA.", 3 "The second word
  // means a hard piece of rock." The writing on the big grey slab confirms
  // 0; its label (ROSETTA, a word worn away) confirms 1 and 2; 3 is the
  // word to write. Every exhibit here is in the picture.
  'm02': InspectScene(
    picture: 'assets/seasons/season_01_london/cases/case_01/british_museum_room4_night.png',
    pixels: _room4,
    place: 'Room 4 of the British Museum, at night',
    task: 'Look closely at the exhibits. Which one matches the note?',
    nextTask: 'Read its label. One word is missing.',
    dragGuide: 'Drag the glass over the exhibits.',
    tapGuide: 'Or tap an exhibit to look at it.',
    missLine: 'Nothing here. Look at the exhibits.',
    inside: _room4.rect(40, 34, 1496, 990),
    // The floor in front of the rail: no exhibit under the glass.
    lensAt: _room4.at(640, 930),
    labelTitle: 'THE LABEL',
    labelRoom: 'ROOM 4',
    labelWorn: 'The second word is worn away.',
    taskLine: 3,
    spots: [
      InspectSpot(
        id: 'mask',
        kind: InspectKind.exhibit,
        title: 'GOLDEN MASK',
        label: 'The golden mask of a king, in a glass case',
        areas: [_room4.rect(58, 272, 282, 575)],
        line: "A king's face. Made of gold.",
      ),
      InspectSpot(
        id: 'mummyCase',
        kind: InspectKind.exhibit,
        title: 'MUMMY CASE',
        label: 'A painted mummy case, standing up',
        areas: [_room4.rect(430, 196, 572, 458)], // above the cats' case
        line: 'A mummy case. Made of wood.',
      ),
      InspectSpot(
        id: 'cats',
        kind: InspectKind.exhibit,
        title: 'CAT STATUES',
        label: 'A glass case with a jar and two cat statues',
        areas: [_room4.rect(412, 462, 628, 660)],
        line: 'Two black cats and a little jar. No writing on them.',
      ),
      InspectSpot(
        id: 'treasures',
        kind: InspectKind.exhibit,
        title: 'SMALL TREASURES',
        label: 'A low glass case with a beetle, a little gold man and a bowl',
        areas: [_room4.rect(52, 688, 522, 900)],
        line: 'A blue beetle, a little gold man and a bowl. All very small.',
      ),
      InspectSpot(
        id: 'king',
        kind: InspectKind.exhibit,
        title: 'SITTING KING',
        label: 'A statue of a king sitting on his throne',
        areas: [_room4.rect(695, 250, 808, 515)],
        line: 'A king sitting on his throne. No writing on him.',
      ),
      InspectSpot(
        id: 'queen',
        kind: InspectKind.exhibit,
        title: "QUEEN'S HEAD",
        label: "The painted head of a queen, in a glass case",
        areas: [_room4.rect(1346, 310, 1491, 605)],
        line: "A queen's head, painted blue and gold.",
      ),
      InspectSpot(
        id: 'slab',
        kind: InspectKind.match,
        title: 'STRANGE WRITING',
        label: 'A big grey slab covered in writing',
        // The slab, from its broken top to the plinth.
        areas: [_room4.rect(810, 195, 1218, 664)],
        line: 'Strange writing… big and grey.',
        checks: {0},
      ),
      InspectSpot(
        id: 'label',
        kind: InspectKind.label,
        title: 'THE LABEL',
        label: 'The small label in front of the slab',
        areas: [_room4.rect(864, 672, 992, 756)],
        line: 'A label. One word is missing.',
        checks: {1, 2},
        requires: 'slab',
        lockedLine: 'A small label. Which exhibit is it for?',
      ),
      InspectSpot(
        id: 'plinth',
        kind: InspectKind.hidden,
        title: 'A SMALL GOLDEN KEY',
        label: 'The plinth under the slab',
        // Around the label: its left, its right, and the step below it.
        areas: [
          _room4.rect(740, 666, 862, 900),
          _room4.rect(994, 666, 1300, 758),
          _room4.rect(862, 758, 1300, 900),
        ],
        // Its tag says where the thief goes next: the bell after the case
        // (2026-10-23, approved).
        line: "Something glints in the shadow. A small golden key! ROOM 4 is cut into it. A tag on the key says: 'My next stop is where London's biggest bell rings.'",
        requires: 'slab',
        lockedLine: 'A plinth with a rail around it. What stands on it?',
      ),
    ],
  ),
};

/// The exhibits of [m] to examine, or null when [m] is played as before.
InspectScene? inspectionOf(Mission m) => season1Inspections[m.id];

// Room 4 at night, in pixels.
const _room4 = ScenePixels(1536, 1024);
