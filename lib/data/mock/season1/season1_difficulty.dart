import '../../models/difficulty.dart';
import '../season_catalog.dart';
import 'difficulty/ep01_levels.dart';
import 'difficulty/ep02_levels.dart';
import 'difficulty/ep03_levels.dart';

/// Season 1's words at each level (Rookie: the game's own words, with a few
/// lines of its own where the base was harder than Rookie's English).
///
/// Written case by case (PART 6: 6A Cases 01–03, then 04–06, 07–09, 10–12),
/// one file each under `difficulty/`. Every fact stays — every answer,
/// clue, evidence, the number of hints, and the English a later case reads
/// again — see each file's notes and docs/difficulty_reviews/.
const Map<Difficulty, Map<String, Map<String, Object?>>> season1CasePatches = {
  Difficulty.rookie: {
    'ep01': ep01Rookie,
    'ep02': ep02Rookie,
    'ep03': ep03Rookie,
  },
  Difficulty.junior: {
    'ep01': ep01Junior,
    'ep02': ep02Junior,
    'ep03': ep03Junior,
  },
  Difficulty.master: {
    'ep01': ep01Master,
    'ep02': ep02Master,
    'ep03': ep03Master,
  },
};

/// Season 1's puzzle tables at Junior and Master: only the entries whose
/// words differ (their pictures, places, answers and structure never).
final Map<Difficulty, SeasonContent> season1Variants = {
  Difficulty.junior: SeasonContent(
    info: const {},
    episodes: const {},
    explores: ep01JuniorExplores,
    inspections: ep01JuniorInspections,
    deductions: ep01JuniorDeductions,
    decodes: ep01JuniorDecodes,
    investigations: ep03JuniorInvestigations,
    clocks: ep02JuniorClocks,
    discoveries: const {...ep01JuniorDiscoveries, ...ep02JuniorDiscoveries, ...ep03JuniorDiscoveries},
    learning: {...ep01JuniorLearning, ...ep02JuniorLearning, ...ep03JuniorLearning},
  ),
  Difficulty.master: SeasonContent(
    info: const {},
    episodes: const {},
    explores: ep01MasterExplores,
    inspections: ep01MasterInspections,
    deductions: ep01MasterDeductions,
    decodes: ep01MasterDecodes,
    investigations: ep03MasterInvestigations,
    clocks: ep02MasterClocks,
    discoveries: const {...ep01MasterDiscoveries, ...ep02MasterDiscoveries, ...ep03MasterDiscoveries},
    learning: {...ep01MasterLearning, ...ep02MasterLearning, ...ep03MasterLearning},
  ),
};

/// The cases whose words are written at each level (checked: nothing at a
/// written Junior or Master falls back on another level's words; Rookie
/// reviewed — the base kept wherever it already read as Rookie's).
const Map<String, Set<Difficulty>> season1WrittenLevels = {
  'ep01': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  'ep02': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  'ep03': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
};
