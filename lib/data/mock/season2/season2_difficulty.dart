import '../../models/difficulty.dart';
import '../season_catalog.dart';
import 'difficulty/ep01_levels.dart';
import 'difficulty/ep02_levels.dart';
import 'difficulty/ep03_levels.dart';
import 'difficulty/ep04_levels.dart';
import 'difficulty/ep05_levels.dart';
import 'difficulty/ep06_levels.dart';
import 'difficulty/ep07_levels.dart';
import 'difficulty/ep08_levels.dart';
import 'difficulty/ep09_levels.dart';
import 'difficulty/ep10_levels.dart';
import 'difficulty/ep11_levels.dart';
import 'difficulty/ep12_levels.dart';
import 'season2_case03_scenes.dart';
import 'season2_case04_scenes.dart';
import 'season2_case05_scenes.dart';
import 'season2_case06_scenes.dart';
import 'season2_case07_scenes.dart';
import 'season2_case08_scenes.dart';
import 'season2_scenes.dart';

/// Season 2's words at each level (the game's own words are Rookie's).
///
/// Written case by case, one file each under `difficulty/` (shared builders
/// in `difficulty/level_words.dart`).
///
/// Written (PART 7A): Cases 01–03, every page, at Junior and Master — the
/// case file, each mission's story, papers, question, hints, wrong-answer
/// lines, success line (also its Discovery Moment's title), the scene after
/// it, its clue and evidence notes, its scene's own words and its learning
/// design. Rookie: the game's own words, reviewed, with the words a child
/// may not know added to the glossary (`docs/difficulty_reviews/
/// PARIS_CASE_01_03.md`).
///
/// Written (PART 7B): Cases 04–06, the same way
/// (`docs/difficulty_reviews/PARIS_CASE_04_06.md`).
/// Written (PART 7C): Cases 07–09
/// (`docs/difficulty_reviews/PARIS_CASE_07_09.md`).
/// Written (PART 7D): Cases 10–12
/// (`docs/difficulty_reviews/PARIS_CASE_10_12.md`): the whole season.
///
/// At every level the same: the times, the answers, every id and order, the
/// papers the puzzles are read from (the station notice, the clerk's three
/// order lines, the painter's three note headings and the instructions of
/// his notes, the inspection steps, the time cards), the painter's own
/// words ("I saw who took the hour.", "A city can lose an hour. But who can
/// steal it?"), the plaque, the names of the evidence (other cases name
/// them), and every way to play (Tap…, Drag…, Slide…).
///
/// Kept untold at every level: who the Clockmaker is; that the man with the
/// pocket watch changed the clock; where Case 03 is before Case 02 ends;
/// that an hour really vanished.
final Map<Difficulty, Map<String, Map<String, Object?>>> season2CasePatches = {
  // ── Rookie: the game's own words; only the glossary grows ──────────────
  // (two lines of Case 05 and one of Case 09 made plainer).
  Difficulty.rookie: {
    's2_ep01': rookie01,
    's2_ep02': rookie02,
    's2_ep03': rookie03,
    's2_ep04': rookie04,
    's2_ep05': rookie05,
    's2_ep06': rookie06,
    's2_ep07': rookie07,
    's2_ep08': rookie08,
    's2_ep09': rookie09,
    's2_ep10': rookie10,
    's2_ep11': rookie11,
    's2_ep12': rookie12,
  },
  Difficulty.junior: {
    's2_ep01': junior01,
    's2_ep02': junior02,
    's2_ep03': junior03,
    's2_ep04': junior04,
    's2_ep05': junior05,
    's2_ep06': junior06,
    's2_ep07': junior07,
    's2_ep08': junior08,
    's2_ep09': junior09,
    's2_ep10': junior10,
    's2_ep11': junior11,
    's2_ep12': junior12,
  },
  Difficulty.master: {
    's2_ep01': master01,
    's2_ep02': master02,
    's2_ep03': master03,
    's2_ep04': master04,
    's2_ep05': master05,
    's2_ep06': master06,
    's2_ep07': master07,
    's2_ep08': master08,
    's2_ep09': master09,
    's2_ep10': master10,
    's2_ep11': master11,
    's2_ep12': master12,
  },
};

/// The cases whose words are written at a level: nothing of theirs falls
/// back on another level's (`DifficultyContent.missingAt`, enforced by the
/// tests). Rookie: reviewed (the game's own words are Rookie's).
const Map<String, Set<Difficulty>> season2WrittenLevels = {
  's2_ep01': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  's2_ep02': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  's2_ep03': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  // PART 7B.
  's2_ep04': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  's2_ep05': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  's2_ep06': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  // PART 7C.
  's2_ep07': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  's2_ep08': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  's2_ep09': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  // PART 7D.
  's2_ep10': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  's2_ep11': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  's2_ep12': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
};

/// The scenes whose words are the same at every level, by `table/mission`:
/// they hold only ways to play (Tap…, Turn…), the documents their puzzles
/// are read from (the two records, the lift log and its plate, the evidence
/// board's questions and conclusions) and what screen readers say of the
/// pictures. Reviewed and kept on purpose: each level's table names them,
/// so nothing falls back unseen.
const Set<String> season2SameAtEveryLevel = {
  'canvases/s2_ep02_final',
  'records/s2_ep03_m1',
  'lifts/s2_ep03_m2',
  'dialLocks/s2_ep03_m3',
  'evidenceBoards/s2_ep03_final',
  // PART 7B: Cases 04–06.
  ...sameAtEveryLevel04,
  ...sameAtEveryLevel05,
  ...sameAtEveryLevel06,
  // PART 7C: Cases 07–09.
  ...sameAtEveryLevel07,
  ...sameAtEveryLevel08,
  // PART 7D: Cases 10–12 have none.
};

/// Season 2's puzzle tables at Junior and Master: only what differs (and
/// the scenes kept the same on purpose, [season2SameAtEveryLevel]).
final Map<Difficulty, SeasonContent> season2Variants = {
  Difficulty.junior: SeasonContent(
    info: const {},
    episodes: const {},
    stationClocks: juniorScenes01.stationClocks,
    exhibits: juniorScenes01.exhibits,
    clocks: juniorScenes01.clocks,
    compares: juniorScenes02.compares,
    studios: juniorScenes02.studios,
    layers: juniorScenes02.layers,
    canvases: {'s2_ep02_final': season2Canvases['s2_ep02_final']!},
    records: {'s2_ep03_m1': season2Records['s2_ep03_m1']!},
    lifts: {'s2_ep03_m2': season2Lifts['s2_ep03_m2']!},
    dialLocks: {'s2_ep03_m3': season2DialLocks['s2_ep03_m3']!},
    evidenceBoards: {'s2_ep03_final': season2EvidenceBoards['s2_ep03_final']!},
    // PART 7B: Cases 04–06.
    riverMarks: juniorScenes04.riverMarks,
    keeperHuts: juniorScenes04.keeperHuts,
    quayBoxes: juniorScenes04.quayBoxes,
    streetBooks: {'s2_ep04_final': season2StreetBooks['s2_ep04_final']!},
    markCompares: {'s2_ep05_m1': season2MarkCompares['s2_ep05_m1']!},
    clockWalls: juniorScenes05.clockWalls,
    postTrails: {'s2_ep05_final': season2PostTrails['s2_ep05_final']!},
    holdRacks: {'s2_ep06_m1': season2HoldRackScenes['s2_ep06_m1']!},
    planRoutes: {'s2_ep06_m2': season2PlanScenes['s2_ep06_m2']!},
    archives: juniorScenes06.archives,
    letterMaps: {'s2_ep06_final': season2LetterMapScenes['s2_ep06_final']!},
    easySteps: {
      ...juniorScenes04.easySteps,
      ...juniorScenes05.easySteps,
      ...juniorScenes07.easySteps,
      ...juniorScenes11.easySteps,
      ...juniorScenes12.easySteps,
    },
    // PART 7D: Cases 10–12.
    drumTapes: juniorScenes10.drumTapes,
    cityClocks: juniorScenes10.cityClocks,
    shadowChecks: juniorScenes10.shadowChecks,
    hourRecords: juniorScenes10.hourRecords,
    talks: juniorScenes11.talks,
    talkMissions: {...juniorScenes11.talkMissions, ...juniorScenes12.talkMissions},
    endings: juniorScenes12.endings,
    // PART 7C: Cases 07–09.
    flyRails: {'s2_ep07_m3': season2FlyRailScenes['s2_ep07_m3']!},
    lightTables: {'s2_ep07_final': season2LightTableScenes['s2_ep07_final']!},
    cornerChoices: {'s2_ep08_m1': season2CornerChoices['s2_ep08_m1']!},
    morningSketches: juniorScenes08.morningSketches,
    tornSlips: juniorScenes08.tornSlips,
    tornHours: juniorScenes08.tornHours,
    trialMaps: juniorScenes09.trialMaps,
    gearBoards: juniorScenes09.gearBoards,
    makerMarks: juniorScenes09.makerMarks,
    towerTests: juniorScenes09.towerTests,
    learning: {
      ...juniorLearning01,
      ...juniorLearning02,
      ...juniorLearning03,
      ...juniorLearning04,
      ...juniorLearning05,
      ...juniorLearning06,
      ...juniorLearning07,
      ...juniorLearning08,
      ...juniorLearning09,
      ...juniorLearning10,
      ...juniorLearning11,
      ...juniorLearning12,
    },
  ),
  Difficulty.master: SeasonContent(
    info: const {},
    episodes: const {},
    stationClocks: masterScenes01.stationClocks,
    exhibits: masterScenes01.exhibits,
    clocks: masterScenes01.clocks,
    compares: masterScenes02.compares,
    studios: masterScenes02.studios,
    layers: masterScenes02.layers,
    canvases: {'s2_ep02_final': season2Canvases['s2_ep02_final']!},
    records: {'s2_ep03_m1': season2Records['s2_ep03_m1']!},
    lifts: {'s2_ep03_m2': season2Lifts['s2_ep03_m2']!},
    dialLocks: {'s2_ep03_m3': season2DialLocks['s2_ep03_m3']!},
    evidenceBoards: {'s2_ep03_final': season2EvidenceBoards['s2_ep03_final']!},
    // PART 7B: Cases 04–06.
    riverMarks: masterScenes04.riverMarks,
    keeperHuts: masterScenes04.keeperHuts,
    quayBoxes: masterScenes04.quayBoxes,
    streetBooks: {'s2_ep04_final': season2StreetBooks['s2_ep04_final']!},
    markCompares: {'s2_ep05_m1': season2MarkCompares['s2_ep05_m1']!},
    clockWalls: masterScenes05.clockWalls,
    postTrails: {'s2_ep05_final': season2PostTrails['s2_ep05_final']!},
    holdRacks: {'s2_ep06_m1': season2HoldRackScenes['s2_ep06_m1']!},
    planRoutes: {'s2_ep06_m2': season2PlanScenes['s2_ep06_m2']!},
    archives: masterScenes06.archives,
    letterMaps: {'s2_ep06_final': season2LetterMapScenes['s2_ep06_final']!},
    easySteps: {
      ...masterScenes04.easySteps,
      ...masterScenes05.easySteps,
      ...masterScenes07.easySteps,
      ...masterScenes11.easySteps,
      ...masterScenes12.easySteps,
    },
    // PART 7D: Cases 10–12.
    drumTapes: masterScenes10.drumTapes,
    cityClocks: masterScenes10.cityClocks,
    shadowChecks: masterScenes10.shadowChecks,
    hourRecords: masterScenes10.hourRecords,
    talks: masterScenes11.talks,
    talkMissions: {...masterScenes11.talkMissions, ...masterScenes12.talkMissions},
    endings: masterScenes12.endings,
    // PART 7C: Cases 07–09.
    flyRails: {'s2_ep07_m3': season2FlyRailScenes['s2_ep07_m3']!},
    lightTables: {'s2_ep07_final': season2LightTableScenes['s2_ep07_final']!},
    cornerChoices: {'s2_ep08_m1': season2CornerChoices['s2_ep08_m1']!},
    morningSketches: masterScenes08.morningSketches,
    tornSlips: masterScenes08.tornSlips,
    tornHours: masterScenes08.tornHours,
    trialMaps: masterScenes09.trialMaps,
    gearBoards: masterScenes09.gearBoards,
    makerMarks: masterScenes09.makerMarks,
    towerTests: masterScenes09.towerTests,
    learning: {
      ...masterLearning01,
      ...masterLearning02,
      ...masterLearning03,
      ...masterLearning04,
      ...masterLearning05,
      ...masterLearning06,
      ...masterLearning07,
      ...masterLearning08,
      ...masterLearning09,
      ...masterLearning10,
      ...masterLearning11,
      ...masterLearning12,
    },
  ),
};
