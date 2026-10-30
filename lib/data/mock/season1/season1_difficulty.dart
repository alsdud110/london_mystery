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

/// Season 1's words at each level (Rookie: the game's own words, with a few
/// lines of its own where the base was harder than Rookie's English).
///
/// Written case by case (PART 6: 6A Cases 01–03, 6B 04–06, 6C 07–09, 6D
/// 10–12), one file each under `difficulty/`. Every fact stays — every
/// answer, clue, evidence, the number of hints, and the English a later case
/// reads again — see each file's notes and docs/difficulty_reviews/.
const Map<Difficulty, Map<String, Map<String, Object?>>> season1CasePatches = {
  Difficulty.rookie: {
    'ep01': ep01Rookie,
    'ep02': ep02Rookie,
    'ep03': ep03Rookie,
    'ep04': ep04Rookie,
    'ep05': ep05Rookie,
    'ep06': ep06Rookie,
    'ep07': ep07Rookie,
    'ep08': ep08Rookie,
    'ep09': ep09Rookie,
    'ep10': ep10Rookie,
    'ep11': ep11Rookie,
    'ep12': ep12Rookie,
  },
  Difficulty.junior: {
    'ep01': ep01Junior,
    'ep02': ep02Junior,
    'ep03': ep03Junior,
    'ep04': ep04Junior,
    'ep05': ep05Junior,
    'ep06': ep06Junior,
    'ep07': ep07Junior,
    'ep08': ep08Junior,
    'ep09': ep09Junior,
    'ep10': ep10Junior,
    'ep11': ep11Junior,
    'ep12': ep12Junior,
  },
  Difficulty.master: {
    'ep01': ep01Master,
    'ep02': ep02Master,
    'ep03': ep03Master,
    'ep04': ep04Master,
    'ep05': ep05Master,
    'ep06': ep06Master,
    'ep07': ep07Master,
    'ep08': ep08Master,
    'ep09': ep09Master,
    'ep10': ep10Master,
    'ep11': ep11Master,
    'ep12': ep12Master,
  },
};

/// Season 1's puzzle tables at Junior and Master: only the entries whose
/// words differ (their pictures, places, answers and structure never).
/// Case 06 M1's witness talk (`dialogues`) is written at Junior and Master
/// since 2026-10-30, once `DifficultyContent.structureOf` checked a talk's
/// structure (it was kept in the base's words until then).
final Map<Difficulty, SeasonContent> season1Variants = {
  Difficulty.junior: SeasonContent(
    info: const {},
    episodes: const {},
    explores: ep01JuniorExplores,
    inspections: ep01JuniorInspections,
    deductions: {...ep01JuniorDeductions, ...ep04JuniorDeductions},
    decodes: ep01JuniorDecodes,
    dialogues: ep06JuniorDialogues,
    investigations: {...ep02JuniorInvestigations, ...ep03JuniorInvestigations, ...ep07JuniorInvestigations},
    clocks: ep02JuniorClocks,
    trails: ep03JuniorTrails,
    finalClocks: ep02JuniorFinalClocks,
    discoveries: const {...ep01JuniorDiscoveries, ...ep02JuniorDiscoveries, ...ep03JuniorDiscoveries, ...ep04JuniorDiscoveries, ...ep05JuniorDiscoveries, ...ep06JuniorDiscoveries, ...ep07JuniorDiscoveries, ...ep08JuniorDiscoveries, ...ep09JuniorDiscoveries, ...ep10JuniorDiscoveries, ...ep11JuniorDiscoveries, ...ep12JuniorDiscoveries},
    learning: {...ep01JuniorLearning, ...ep02JuniorLearning, ...ep03JuniorLearning, ...ep04JuniorLearning, ...ep05JuniorLearning, ...ep06JuniorLearning, ...ep07JuniorLearning, ...ep08JuniorLearning, ...ep09JuniorLearning, ...ep10JuniorLearning, ...ep11JuniorLearning, ...ep12JuniorLearning},
  ),
  Difficulty.master: SeasonContent(
    info: const {},
    episodes: const {},
    explores: ep01MasterExplores,
    inspections: ep01MasterInspections,
    deductions: {...ep01MasterDeductions, ...ep04MasterDeductions},
    decodes: ep01MasterDecodes,
    dialogues: ep06MasterDialogues,
    investigations: {...ep02MasterInvestigations, ...ep03MasterInvestigations, ...ep07MasterInvestigations},
    clocks: ep02MasterClocks,
    trails: ep03MasterTrails,
    finalClocks: ep02MasterFinalClocks,
    discoveries: const {...ep01MasterDiscoveries, ...ep02MasterDiscoveries, ...ep03MasterDiscoveries, ...ep04MasterDiscoveries, ...ep05MasterDiscoveries, ...ep06MasterDiscoveries, ...ep07MasterDiscoveries, ...ep08MasterDiscoveries, ...ep09MasterDiscoveries, ...ep10MasterDiscoveries, ...ep11MasterDiscoveries, ...ep12MasterDiscoveries},
    learning: {...ep01MasterLearning, ...ep02MasterLearning, ...ep03MasterLearning, ...ep04MasterLearning, ...ep05MasterLearning, ...ep06MasterLearning, ...ep07MasterLearning, ...ep08MasterLearning, ...ep09MasterLearning, ...ep10MasterLearning, ...ep11MasterLearning, ...ep12MasterLearning},
  ),
};

/// The cases whose words are written at each level (checked: nothing at a
/// written Junior or Master falls back on another level's words; Rookie
/// reviewed — the base kept wherever it already read as Rookie's). Case 06:
/// every level since 2026-10-30, its M1 talk written too (it was Rookie
/// only while the engine could not check a talk at a level).
const Map<String, Set<Difficulty>> season1WrittenLevels = {
  'ep01': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  'ep02': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  'ep03': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  'ep04': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  'ep05': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  'ep06': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  'ep07': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  'ep08': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  'ep09': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  'ep10': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  'ep11': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  'ep12': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
};
