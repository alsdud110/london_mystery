import 'dart:ui' show Offset, Rect;

import '../../models/garden_puzzles.dart' show IntroInset, IntroMark, IntroPicture;
import '../../models/letter_puzzles.dart' show MapSpot;
import '../../models/river_puzzles.dart' show DrawnEvidenceArt, RiverEvidenceArt;
import '../../models/scene_exhibit.dart' show EvidenceLink;
import '../../models/scene_explore.dart' show ScenePixels;
import '../../models/star_puzzles.dart';
import '../../models/story_picture.dart';

/// Season 2, Case 10's missions, keyed by mission id, as they are played on
/// the case's pictures (every place measured on the delivered pictures, in
/// their pixels). The answers, the hints, the solves, their Clue and
/// Evidence, XP, coins and the save are the case's own
/// (`episode10_mock.dart`). The design: `docs/SEASON2_CASE10_SPEC.md`.

const _case09 = 'assets/seasons/season_02_paris/cases/case_09';
const _case10 = 'assets/seasons/season_02_paris/cases/case_10';
const _map = 'assets/seasons/season_02_paris/locations/map/paris_mystery.png';

const _wide = ScenePixels(1536, 1024);
const _square = ScenePixels(1254, 1254);

// ── The Star Room ───────────────────────────────────────────────────────
// The room (1536 × 1024): on the wall, a blank brass plate leaning up to the
// right, its inner panel (652, 235)–(868, 210) along the top and
// (652, 318)–(868, 312) along the bottom; on the door, a twelve-point star
// round a ring, centred (1292, 191), its points 100 out. On the table: the
// brass drum (130, 430)–(690, 790), the box of photos (630, 415)–(1085, 700)
// and the green book (735, 630)–(1375, 900).
const season2StarRoom = StarRoom(
  file: '$_case10/star_room.png',
  pixels: _wide,
  label: 'A little stone room under the roof: a brass drum with a paper tape, a box of old photos and a thick green book on a table; a brass plate on the wall; a star on the door',
  plateCentre: Offset(760, 268),
  plateSize: (196, 74),
  plateAngle: -4,
  plateLines: ['TRIAL RECORDS', 'KEPT AT THE STAR'],
  doorStar: Rect.fromLTRB(1188, 87, 1396, 295),
  things: [
    Rect.fromLTRB(130, 430, 690, 790),
    Rect.fromLTRB(630, 415, 1085, 700),
    Rect.fromLTRB(735, 630, 1375, 900),
  ],
);

/// The case opens at the Arc de Triomphe, T1's little arch and its star
/// laid over it (lines 2–3), then the room under the roof (line 4 on): the
/// door's star ringed (line 4), the three things (line 5), the plate
/// (line 6).
final Map<String, IntroPicture> season2Case10IntroPictures = {
  's2_ep10': const IntroPicture(
    afterLine: 0,
    turnAtLine: 3,
    from: '$_case10/arc_star_view.png',
    to: '$_case10/star_room.png',
    pixels: _wide,
    fromLabel: 'The Arc de Triomphe at the end of the afternoon, wide roads running out from it like the points of a star',
    toLabel: 'The little room under the roof: a brass drum, a box of photos, a thick book; a brass plate on the wall; a star on the door',
    room: season2StarRoom,
    inset: IntroInset(
      file: '$_case09/clock_model_t1.png',
      pixels: _square,
      label: 'T1: a little arch with a clock on top, a star carved on its base',
      fromLine: 1,
      toLine: 3,
    ),
    marks: [
      IntroMark(line: 3, area: Rect.fromLTRB(1188, 87, 1396, 295)),
      IntroMark(line: 4, area: Rect.fromLTRB(130, 415, 1375, 900)),
      IntroMark(line: 5, area: Rect.fromLTRB(630, 190, 890, 345)),
    ],
  ),
};

// ── M1 — T1's drum tape ─────────────────────────────────────────────────
// The drum (1254 × 1254, cut out): a brass cylinder on a wooden base; the
// tape's slot on its right end, round (1043, 490); a blank oval plate on the
// base, (640, 890)–(812, 1003).
// The tape (the story bible's v1.9 table): T1 printed its own time every
// fifteen minutes. At 3:00 its hour hand went one hour back (it printed
// 2:00); at 4:00 it was right again. Real times are never printed.
const season2DrumTape = DrumTapeScene(
  drumFile: '$_case10/record_drum.png',
  drumPixels: _square,
  slot: Offset(1043, 490),
  plate: Rect.fromLTRB(640, 890, 812, 1003),
  header: 'T1 · DRUM TAPE · TRIAL DAY',
  marks: [
    TapeMark(id: 't1', printed: 120, real: 120),
    TapeMark(id: 't2', printed: 135, real: 135),
    TapeMark(id: 't3', printed: 150, real: 150),
    TapeMark(id: 't4', printed: 165, real: 165),
    TapeMark(id: 't5', printed: 120, real: 180),
    TapeMark(id: 't6', printed: 135, real: 195),
    TapeMark(id: 't7', printed: 150, real: 210),
    TapeMark(id: 't8', printed: 165, real: 225),
    TapeMark(id: 't9', printed: 240, real: 240),
    TapeMark(id: 't10', printed: 255, real: 255),
  ],
  task: 'Pull the tape. Then tap the two places where the time jumps.',
  pullLabel: 'PULL THE TAPE',
  startLine: "That's where the tape starts.",
  oneMore: 'One jump! Find one more.',
  found: 'Two jumps!',
);

final Map<String, DrumTapeScene> season2DrumTapes = {'s2_ep10_m1': season2DrumTape};

// ── The roof photos ─────────────────────────────────────────────────────
// The photo (1536 × 1024, its own worn paper edge): T1 on its iron post at
// the front left, the star on the post; the sundial at the front right;
// behind, the city. The four faces, plain white, seen a little from the
// side (centre and half-axes, measured on the delivered picture):
//   T1 (354, 399), 100 × 116; the café's bracket clock (636, 542), 20 × 24.5;
//   the church tower (1036, 213), 14.6 × 15; the post office door (1352, 498),
//   28.5 × 35.
// The sundial: its lines meet at (1009, 755); its plate 228 × 77 on the
// picture; its gnomon points 40° round from straight away from the camera.
const _photo = RoofPhoto(
  file: '$_case10/roof_photo.png',
  pixels: _wide,
  label: 'An old photo from the roof: T1 on its post with a star, a sundial, and the city behind with a café clock, a church clock and a clock over a post office door',
  clocks: [
    PhotoClock(
      id: 't1',
      name: 'T1',
      label: 'T1, the trial clock on the roof, a star on its post',
      centre: Offset(354, 399),
      rx: 100,
      ry: 116,
      trial: true,
      photo1: 120,
      photo2: 150,
      wrongLine: 'Look at the post under T1. What sign is there?',
      card: Rect.fromLTRB(165, 255, 545, 762),
    ),
    PhotoClock(
      id: 'cafe',
      name: 'Café',
      label: 'The clock on the corner café',
      centre: Offset(636, 542),
      rx: 20,
      ry: 24.5,
      trial: false,
      photo1: 120,
      photo2: 210,
      wrongLine: 'Is there a star, three arches or a bell on it? Check your Trial Map.',
      card: Rect.fromLTRB(566, 470, 706, 657),
    ),
    PhotoClock(
      id: 'church',
      name: 'Church',
      label: 'The clock on the church tower',
      centre: Offset(1036, 213),
      rx: 14.6,
      ry: 15,
      trial: false,
      photo1: 120,
      photo2: 210,
      wrongLine: 'Is there a star, three arches or a bell on it? Check your Trial Map.',
      card: Rect.fromLTRB(986, 150, 1086, 283),
    ),
    PhotoClock(
      id: 'post',
      name: 'Post office',
      label: 'The clock over the post office door',
      centre: Offset(1352, 498),
      rx: 28.5,
      ry: 35,
      trial: false,
      photo1: 120,
      photo2: 210,
      wrongLine: 'Is there a star, three arches or a bell on it? Check your Trial Map.',
      card: Rect.fromLTRB(1282, 430, 1422, 617),
    ),
  ],
  dial: PhotoDial(hub: Offset(1009, 755), rx: 228, ry: 77, gnomonTurn: 40.2),
  t1Crop: Rect.fromLTRB(234, 270, 474, 528),
  dialCrop: Rect.fromLTRB(770, 610, 1290, 870),
);

// ── M2 — a city of clocks ───────────────────────────────────────────────
// In the glass, one photo pixel is 1.5 points: the church's face, 29 pixels
// across, is 44 points wide there.
const season2CityClocks = CityClocksScene(
  photo: _photo,
  task: 'Move the glass over the photo. Find four clocks.',
  sortTask: 'Is it a trial clock? Put each clock in its tray.',
  trialTray: 'TRIAL CLOCK',
  otherTray: 'NOT A TRIAL CLOCK',
  lensScale: 1.5,
  lensSize: 132,
  moreLine: 'There are more clocks in the photo.',
  foundLine: 'A clock!',
  sortedLines: ['T1 says 2:30.', 'The café, the church and the post office say 3:30.'],
  trialMapId: 's2_ep09_e1',
);

final Map<String, CityClocksScene> season2CityClocksScenes = {'s2_ep10_m2': season2CityClocks};

// ── M3 — the hour of shadows ────────────────────────────────────────────
// The sundial from above (1254 × 1254, cut out): its gnomon from the hub
// (627, 627) up to the top; seven hour lines on its right half, measured on
// the delivered picture (the darkest line through r 200–450 from the hub):
// 23.4°, 45.9°, 65.1°, 82.9°, 102.5°, 121.9°, 143.3° clockwise from the
// gnomon. They are not evenly apart. The straight line down (180°) is the
// gnomon's own line: no hour. The lines end 470 from the hub; the plate's
// edge is 578 out.
const season2Sundial = Sundial(
  file: '$_case10/sundial_top.png',
  pixels: _square,
  hub: Offset(627, 627),
  radius: 470,
  plate: 578,
  lines: [
    SundialLine(60, 23.4),
    SundialLine(90, 45.9),
    SundialLine(120, 65.1),
    SundialLine(150, 82.9),
    SundialLine(180, 102.5),
    SundialLine(210, 121.9),
    SundialLine(240, 143.3),
  ],
  shortest: 0.45,
  longest: 0.90,
);

const season2ShadowCheck = ShadowCheckScene(
  sundial: season2Sundial,
  photo: _photo,
  photos: [
    ShadowPhoto(id: 'photo1', number: 1, t1: 120, sun: 120),
    ShadowPhoto(id: 'photo2', number: 2, t1: 150, sun: 210),
  ],
  task: 'Move the sun. Make the same shadow as in the photo.',
  dragLine: 'Drag the sun round the dial.',
  longer: 'Not yet. The shadow in the photo is longer.',
  shorter: 'Not yet. The shadow in the photo is shorter.',
  matchLine: 'The same shadow!',
  nextLabel: 'NEXT PHOTO',
  plateWords: 'I COUNT ONLY THE SUNNY HOURS',
);

final Map<String, ShadowCheckScene> season2ShadowChecks = {'s2_ep10_m3': season2ShadowCheck};

// ── Final — the hour was recorded ───────────────────────────────────────
// The Trial Log, open (1536 × 1024, cut out): the left page's ruled panel
// (185, 148)–(742, 848), an empty circle at its top left (225, 185); the
// right page's (808, 150)–(1365, 846).
const season2HourRecord = HourRecordScene(
  room: season2StarRoom,
  tape: season2DrumTape,
  photo1Mark: 't1',
  photo2Mark: 't7',
  photos: [
    ShadowPhoto(id: 'photo1', number: 1, t1: 120, sun: 120),
    ShadowPhoto(id: 'photo2', number: 2, t1: 150, sun: 210),
  ],
  tapeTask: 'When was Photo 2 taken? Tap that 2:30 on the tape.',
  firstTwoThirty: "This 2:30 is only half an hour after Photo 1. Photo 2's sun said 3:30, much later.",
  notTwoThirty: 'T1 said 2:30 in Photo 2. Find a 2:30.',
  foundLines: [
    'Six marks from Photo 1 to Photo 2: one and a half hours. Fifteen minutes for each mark.',
    'There it is: the hour from three to four! It was on the tape all along.',
    'At three, T1 went one hour back. At four, it was right again.',
  ],
  backLabel: 'one hour back',
  rightLabel: 'right again',
  logFile: '$_case10/trial_log_open.png',
  logPixels: _wide,
  leftPage: Rect.fromLTRB(185, 148, 742, 848),
  rightPage: Rect.fromLTRB(808, 150, 1365, 846),
  emblem: Rect.fromLTRB(206, 166, 244, 204),
  logTitle: 'TRIAL LOG · TRIAL DAY',
  pages: [
    LogPage(id: 'p1', number: 1, from: 60, to: 120, inBook: true),
    LogPage(id: 'p2', number: 2, from: 120, to: 180, inBook: true),
    LogPage(id: 'p3', number: 3, from: 180, to: 240, inBook: false),
    LogPage(id: 'p4', number: 4, from: 240, to: 300, inBook: true),
  ],
  pageTask: 'Which page tells about three to four? Is it in the book?',
  pageInBook: 'That page is in the book. Turn the pages again.',
  pageFoundLine: 'Page 3 should tell about three to four. It is not in the book.',
  afterLines: [
    'In the garden, a model showed what could happen. This tape shows what happened to T1.',
    'Time did not stop. T1 showed the wrong time, and a page went missing.',
    'And page 3 is not in the book.',
  ],
  lead: RecordListLead(
    title: 'THE BACK OF THE BOOK',
    heading: 'RECORD LIST · TRIAL LOG',
    lines: [
      RecordLine(id: 'p1', text: 'p.1 · KEPT AT THE STAR'),
      RecordLine(id: 'p2', text: 'p.2 · KEPT AT THE STAR'),
      RecordLine(id: 'p3', text: 'p.3 · SENT TO: SAINT-SULPICE · ARCHIVE ANNEX'),
      RecordLine(id: 'p4', text: 'p.4 · KEPT AT THE STAR'),
    ],
    question: 'Where was page 3 sent?',
    answer: 'p3',
    otherLine: 'That page is here, in the book. Find page 3.',
    mapFile: _map,
    mapPixels: _wide,
    // Just north of the Luxembourg Gardens' palace on the map.
    spot: MapSpot(id: 'saintSulpice', name: 'Saint-Sulpice', at: Offset(0.462, 0.684)),
    doneLines: [
      'The list says page 3 was sent to an archive near Saint-Sulpice.',
      "It's just north of the Luxembourg Gardens.",
      'Is page 3 really there? Who sent it, and why? The list doesn\'t say.',
    ],
  ),
  leadLabel: 'READ THE RECORD LIST',
);

final Map<String, HourRecordScene> season2HourRecords = {'s2_ep10_final': season2HourRecord};

/// Case 10's evidence, one piece to the next: the tape from the drum the
/// garden's tag told of; the clocks in the photo, T1 the trial clock with
/// the star; the sun in the same photo; the tape beside the sun's time, a
/// real record, not the garden's model.
const season2Case10EvidenceLinks = <String, EvidenceLink>{
  's2_ep10_e1': EvidenceLink(to: 's2_ep09_e2', line: 'The drum under T1, from the tag in the garden.'),
  's2_ep10_e2': EvidenceLink(to: 's2_ep09_e1', line: 'T1 is the trial clock with the star.'),
  's2_ep10_e3': EvidenceLink(to: 's2_ep10_e2', line: 'The same photo, the same moment.'),
  's2_ep10_e4': EvidenceLink(to: 's2_ep09_e4', line: 'The garden test was a model. This tape is a real record.'),
};

/// Case 10's evidence drawn: the tape and its jumps, Photo 2's clocks, the
/// two shadows, and the tape with the sun's times under it.
final Map<String, RiverEvidenceArt> season2Case10EvidenceArt = {
  's2_ep10_e1': const DrawnEvidenceArt(TapeCard(season2DrumTape), whole: true),
  's2_ep10_e2': const DrawnEvidenceArt(PhotoLog(_photo), whole: true),
  's2_ep10_e3': const DrawnEvidenceArt(ShadowCard(season2ShadowCheck), whole: true),
  's2_ep10_e4': const DrawnEvidenceArt(TapeCard(season2DrumTape, record: season2HourRecord), whole: true),
};

// ── The story's pictures, mission by mission ────────────────────────────
// Each moment shows what the detective has just reached, never more: the
// room, the drum, the photo, the sundial, the book, the arch.
const _room = StoryPicture(
  file: '$_case10/star_room.png',
  pixels: _wide,
  label: 'A little stone room under the roof: a brass drum, a box of old photos and a thick book on a table, a star on the door',
);

const _drum = StoryPicture(
  file: '$_case10/record_drum.png',
  pixels: _square,
  label: 'A brass drum that prints the time on a paper tape',
  cutOut: true,
);

const _roofPhoto = StoryPicture(
  file: '$_case10/roof_photo.png',
  pixels: _wide,
  label: 'An old photo from the roof: T1 on its post, a sundial, and the city behind',
);

const _photoDial = StoryPicture(
  file: '$_case10/roof_photo.png',
  pixels: _wide,
  crop: Rect.fromLTRB(700 / 1536, 560 / 1024, 1340 / 1536, 960 / 1024),
  label: 'The sundial on the roof, in the old photo',
);

const _sundial = StoryPicture(
  file: '$_case10/sundial_top.png',
  pixels: _square,
  label: 'An old bronze sundial, seen from above',
  cutOut: true,
);

const _book = StoryPicture(
  file: '$_case10/trial_log_open.png',
  pixels: _wide,
  label: 'A thick old book, open: the Trial Log',
  cutOut: true,
);

const _arch = StoryPicture(
  file: '$_case10/arc_star_view.png',
  pixels: _wide,
  label: 'The Arc de Triomphe, roads running out from it like a star',
);

final Map<String, StoryScenes> season2Case10StoryScenes = {
  // The room; after it, the drum; then the photos.
  's2_ep10_m1': const StoryScenes(place: _room, after: _drum, next: _roofPhoto),
  // The photo; after it, its sundial; then the sundial on the roof.
  's2_ep10_m2': const StoryScenes(place: _roofPhoto, after: _photoDial, next: _sundial),
  // The sundial in the photo; after it, the sundial itself; then the book.
  's2_ep10_m3': const StoryScenes(place: _photoDial, after: _sundial, next: _book),
  // After the case: the arch, the roads running out from it.
  's2_ep10_final': const StoryScenes(after: _arch),
};
