import 'dart:ui' show Offset, Rect;

import '../../models/investigation.dart';
import '../../models/mission.dart';

/// Missions played by searching their place (presentation only: nothing
/// here is saved). Mission id → its [InvestigationScene]. A mission not
/// listed is played through its puzzle as before.
///
/// The case data is left as it is: the search ends with the puzzle's own
/// answer, so the solve, its Clue and Evidence, XP, coins and the save are
/// the ones the puzzle always gave.
final Map<String, InvestigationScene> season1Investigations = {
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

// Gallery 8's picture, in pixels.
const double _w = 1536;
const double _h = 1024;

Rect _px(double left, double top, double right, double bottom) =>
    Rect.fromLTRB(left / _w, top / _h, right / _w, bottom / _h);

Offset _at(double x, double y) => Offset(x / _w, y / _h);
