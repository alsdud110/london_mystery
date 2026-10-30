import 'dart:ui' show Offset, Rect;

import '../../models/investigation.dart';
import '../../models/mission.dart';
import '../../models/scene_explore.dart' show ScenePixels;

/// Missions played by searching their place (presentation only: nothing
/// here is saved). Mission id → its [InvestigationScene]. A mission not
/// listed is played through its puzzle as before.
///
/// The case data is left as it is: the search ends with the puzzle's own
/// answer, so the solve, its Clue and Evidence, XP, coins and the save are
/// the ones the puzzle always gave.
final Map<String, InvestigationScene> season1Investigations = {
  // ── Case 02 M2 — the belfry (cases/case_02/big_ben_belfry.png, 1536 × 1024)
  // Five bells, each its own size; the back of a clock face on the left
  // wall, the stairs coming up on the right. R.'s note says where the gear
  // is NOT (the biggest bell) and where it IS (its opposite): the detective
  // reads it, picks out the smallest bell by eye and looks under it. Nothing
  // in the picture shows the gear before it is found. The find answers the
  // puzzle's question (under the smallest bell, `c`), as a solve always did.
  'ep02_m2': InvestigationScene(
    picture: _belfryFile,
    pixels: _belfry,
    // As short as Gallery 8's: the panel keeps its room at 1.3× text with
    // both tips open.
    task: 'Read the note. Find the gear.',
    documentTitle: "R.'S NOTE",
    answer: 'c',
    missLine: 'Nothing here. The note says the gear is under a bell.',
    doneLine: 'You found the missing gear!',
    startLabel: 'SEARCH THE BELFRY',
    documentLabel: 'Note',
    arrival: [
      'A ladder goes up from the clock room to the belfry. Five bells hang there.',
      'R. pinned a note to the empty place where the gear should be.',
    ],
    // The bare floor at the front, lit by the clock face: no bell, no place.
    guideAt: _belfry.at(330, 860),
    // Every bell, the clock face and the stairs; the room inside its paper edge.
    opening: _belfry.rect(60, 180, 1480, 975),
    inside: _belfry.rect(48, 45, 1490, 978),
    finds: [
      InvestigationFind(
        id: 'gear',
        name: 'The brass gear',
        title: 'SMALL BRASS GEAR',
        reportLine: 'It is under the bell that is the opposite of the biggest.',
        spot: 'Under a bell',
        // The smallest bell and the floor just under its rim.
        areas: [_belfry.rect(1278, 425, 1400, 700)],
        foundLine: 'Under the smallest bell: the brass gear!',
        picture: 'assets/seasons/season_01_london/objects/brass_gear.png',
        at: _belfry.at(1338, 668),
        width: 70 / 1536,
        squash: 0.7,
      ),
    ],
    spots: [
      InvestigationSpot(
        label: 'The biggest bell',
        areas: [_belfry.rect(605, 230, 1008, 668), _belfry.rect(620, 668, 1000, 745)],
        line: 'The biggest bell. The note says the gear is NOT under this one.',
      ),
      InvestigationSpot(
        label: 'A bell',
        areas: [
          _belfry.rect(278, 345, 502, 645),
          _belfry.rect(500, 425, 652, 610),
          _belfry.rect(995, 278, 1266, 662),
        ],
        line: 'Nothing under this bell. Which bell is the opposite of the biggest?',
      ),
      InvestigationSpot(
        label: 'The back of the clock face',
        areas: [_belfry.rect(75, 235, 315, 660)],
        line: 'The back of the clock face. The note says the gear is under a bell.',
      ),
      InvestigationSpot(
        label: 'The stairs',
        areas: [_belfry.rect(1015, 700, 1490, 975)],
        line: 'The stairs go down. The note does not talk about the stairs.',
      ),
      InvestigationSpot(
        label: 'An old rope',
        areas: [_belfry.rect(1060, 80, 1225, 215)],
        line: 'An old rope on a beam. Nothing here.',
      ),
    ],
  ),
  // ── Case 07 M2 — the boathouse (cases/case_07/boathouse_inside.png) ──
  // A shelf of four little boxes (the boxes the note rules out), a table
  // with a coil of rope on it, and under the table a green watering can that
  // hides the floor behind it. The note's place words decide: NOT on the
  // shelf, UNDER the table, BEHIND (not in front of) the can. The box is
  // never drawn: it is laid behind the can once found (`c`).
  'ep07_m2': InvestigationScene(
    picture: _boathouseFile,
    pixels: _boathouse,
    task: 'Read the note. Find the box.',
    documentTitle: 'THE NOTE ON THE DOOR',
    answer: 'c',
    missLine: 'Nothing here. What do the place words say?',
    doneLine: 'You found the map piece!',
    startLabel: 'SEARCH THE BOATHOUSE',
    documentLabel: 'Note',
    arrival: [
      'The boathouse is dark and quiet. Someone was here last night.',
      'A message is scratched on the inside of the door.',
    ],
    // The bare floor on the left: no thing, no listed place.
    guideAt: _boathouse.at(250, 880),
    // The shelf, the table and the can under it: what the note talks about
    // is in the opening view even when the tips leave the picture short.
    opening: _boathouse.rect(44, 330, 1250, 940),
    inside: _boathouse.rect(44, 40, 1494, 985),
    finds: [
      InvestigationFind(
        id: 'box',
        name: 'The box',
        title: 'THE BOX',
        reportLine: 'behind the green watering can.',
        spot: 'Behind the watering can',
        // The can itself: a tap on it looks behind it.
        areas: [_boathouse.rect(545, 612, 780, 835)],
        foundLine: 'Behind the green watering can, under the table: a box!',
        picture: 'assets/seasons/season_01_london/objects/small_wooden_box.png',
        at: _boathouse.at(800, 770),
        width: 120 / 1536,
        squash: 0.85,
      ),
    ],
    spots: [
      InvestigationSpot(
        label: 'The shelf with four boxes',
        areas: [_boathouse.rect(45, 335, 528, 560)],
        line: 'Empty boxes on the shelf. The note says the box is NOT on the shelf.',
      ),
      InvestigationSpot(
        label: 'The table, with a rope on it',
        areas: [_boathouse.rect(425, 495, 945, 605)],
        line: 'Only a rope on the table. The note says UNDER the table.',
      ),
      InvestigationSpot(
        label: 'The floor in front of the watering can',
        areas: [_boathouse.rect(500, 836, 830, 935)],
        line: 'In front of the can there is nothing. The note says BEHIND it.',
      ),
      InvestigationSpot(
        label: 'Under the table',
        areas: [_boathouse.rect(445, 605, 545, 845), _boathouse.rect(780, 605, 920, 845)],
        line: 'Under the table, yes. Now read the last line of the note.',
      ),
      InvestigationSpot(
        label: 'A stack of old crates',
        areas: [_boathouse.rect(850, 298, 1032, 650)],
        line: 'Big old crates. The note says the box is under the table.',
      ),
      InvestigationSpot(
        label: 'Two oars and a rowing boat',
        areas: [_boathouse.rect(1240, 175, 1465, 910), _boathouse.rect(1125, 515, 1290, 770)],
        line: 'Oars and a little boat. Nothing is hidden here.',
      ),
    ],
  ),
  // ── Case 03 M1 — Gallery 8 (british_museum_gallery_8.png, 1536 × 1024) ──
  // The guard's report says where each thing is ("under the bench", "on the
  // frame", "next to the door"): the detective finds all three where the
  // report says. The last answers the puzzle's question (which one is next
  // to the door: the wet footprint, `c`), as a solve always did.
  'ep03_m1': InvestigationScene(
    artwork: Artwork.gallery,
    task: 'Find the three things in the report.',
    documentTitle: 'GUARD REPORT',
    answer: 'c',
    missLine: 'Nothing here. Read the report: where is each thing?',
    doneLine: 'All three things are found!',
    startLabel: 'SEARCH GALLERY 8',
    // Why the report is read: the room as it was left, then the guard (he
    // is there in the scenes after: he hands it over, he does not leave it).
    // The empty frame itself was the place page's line, so not said again.
    arrival: [
      'Gallery 8 is strangely quiet. Nothing has been moved since the theft.',
      'The museum guard hands you his report about three unusual things.',
    ],
    // The empty floor in the middle of the room: no thing, no listed place.
    guideAt: _at(960, 822),
    // The door (left), the bench and the empty frame (right), with a little
    // room around them; and the room without the print's worn paper edge.
    opening: _px(110, 150, 1426, 990),
    inside: _px(46, 37, 1490, 975),
    finds: [
      InvestigationFind(
        id: 'button',
        name: 'The red button',
        title: 'RED BUTTON',
        reportLine: 'The button is red. It is under the bench.',
        spot: 'Under the bench',
        // Between the bench legs, down to the floor just below them.
        areas: [_px(395, 805, 795, 965)],
        foundLine: 'You found a red button under the bench!',
        picture: 'assets/seasons/season_01_london/objects/red_button.png',
        at: _at(560, 885),
        width: 72 / _w,
      ),
      InvestigationFind(
        id: 'cloth',
        name: 'The blue cloth',
        title: 'BLUE CLOTH',
        reportLine: 'The cloth is blue. It is on the frame.',
        spot: 'On the empty frame',
        // The empty gold frame on the right wall, its gilt edge included.
        areas: [_px(1218, 190, 1392, 550)],
        foundLine: 'A piece of blue cloth was caught on the frame.',
        picture: 'assets/seasons/season_01_london/objects/blue_cloth.png',
        at: _at(1262, 592),
        width: 150 / _w,
      ),
      InvestigationFind(
        id: 'footprint',
        name: 'The wet footprint',
        title: 'WET FOOTPRINT',
        reportLine: 'The footprint is wet. It is next to the door.',
        spot: 'Next to the door',
        // The floor in front of the door, and the wall just beside it (the
        // bust on its left and the bench on its right are their own places).
        areas: [_px(165, 752, 385, 872), _px(306, 300, 362, 752)],
        foundLine: 'A wet footprint was found next to the door.',
        picture: 'assets/seasons/season_01_london/objects/wet_footprint.png',
        at: _at(276, 812),
        width: 96 / _w,
        pictureAspect: 1024 / 1536,
        squash: 0.55,
        turn: -0.3,
      ),
    ],
    spots: [
      InvestigationSpot(
        label: 'On the bench',
        areas: [_px(388, 722, 798, 805)],
        line: 'Nothing on the bench. The report says UNDER it.',
      ),
      InvestigationSpot(
        label: 'The door',
        areas: [_px(176, 212, 306, 752)],
        line: 'The door is shut. The report says NEXT TO the door.',
      ),
      InvestigationSpot(
        label: 'A painting',
        areas: [
          _px(48, 188, 138, 488),
          _px(398, 345, 530, 568),
          _px(1076, 360, 1160, 552),
          _px(1392, 136, 1490, 502),
          _px(1240, 552, 1380, 702),
          _px(572, 432, 628, 558),
          _px(712, 528, 770, 618),
          _px(846, 532, 934, 618),
          _px(988, 528, 1046, 618),
        ],
        line: 'This frame still has its painting.',
      ),
      InvestigationSpot(
        label: 'A marble statue',
        areas: [_px(630, 450, 716, 728)],
        line: 'A marble statue. Nothing is hidden here.',
      ),
      InvestigationSpot(
        label: 'A glass case',
        areas: [_px(1096, 552, 1232, 794), _px(1042, 566, 1106, 730)],
        line: 'The glass case is locked. The vase is safe.',
      ),
      InvestigationSpot(
        label: 'A marble head',
        areas: [_px(52, 500, 162, 816), _px(362, 535, 442, 742), _px(1380, 556, 1488, 906)],
        line: 'A marble head. Nothing here.',
      ),
      InvestigationSpot(
        label: 'Another bench',
        areas: [_px(764, 670, 862, 728), _px(830, 652, 882, 684)],
        line: 'Not this bench. The report means the bench near you.',
      ),
      InvestigationSpot(
        label: 'The glass roof',
        areas: [_px(640, 40, 1070, 250)],
        line: 'Only the glass roof and the sky.',
      ),
    ],
  ),
};

/// The search of [m], or null when [m] is played through its puzzle.
InvestigationScene? investigationOf(Mission m) => season1Investigations[m.id];

// Case 02's belfry, in pixels.
const _belfryFile = 'assets/seasons/season_01_london/cases/case_02/big_ben_belfry.png';
const _belfry = ScenePixels(1536, 1024);

// Case 07's boathouse, inside, in pixels.
const _boathouseFile = 'assets/seasons/season_01_london/cases/case_07/boathouse_inside.png';
const _boathouse = ScenePixels(1536, 1024);

// Gallery 8's picture, in pixels.
const double _w = 1536;
const double _h = 1024;

Rect _px(double left, double top, double right, double bottom) =>
    Rect.fromLTRB(left / _w, top / _h, right / _w, bottom / _h);

Offset _at(double x, double y) => Offset(x / _w, y / _h);
