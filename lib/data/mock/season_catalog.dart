import 'package:flutter/foundation.dart' show visibleForTesting;

import '../models/abbesses_puzzles.dart';
import '../models/case_talk.dart';
import '../models/clock_puzzle.dart';
import '../models/dialogue.dart';
import '../models/difficulty.dart';
import '../models/discovery.dart';
import '../models/easy_steps.dart';
import '../models/episode.dart';
import '../models/garden_puzzles.dart';
import '../models/star_puzzles.dart';
import '../models/investigation.dart';
import '../models/learning.dart';
import '../models/letter_puzzles.dart';
import '../models/mission.dart';
import '../models/opera_puzzles.dart';
import '../models/painter_puzzles.dart';
import '../models/river_puzzles.dart';
import '../models/scene_decode.dart';
import '../models/scene_deduction.dart';
import '../models/scene_exhibit.dart';
import '../models/scene_explore.dart';
import '../models/scene_inspect.dart';
import '../models/scene_place.dart';
import '../models/season.dart';
import '../models/station_clocks.dart';
import '../models/story_picture.dart';
import '../models/tower_puzzles.dart';
import '../models/workshop_puzzles.dart';
import '../generated/generated_seasons.g.dart';
import 'season1/episode01_mock.dart';
import 'season1/season1_clocks.dart';
import 'season1/season1_decodes.dart';
import 'season1/season1_deductions.dart';
import 'season1/season1_difficulty.dart';
import 'season1/season1_dialogues.dart';
import 'season1/season1_discoveries.dart';
import 'season1/season1_explores.dart';
import 'season1/season1_inspections.dart';
import 'season1/season1_investigations.dart';
import 'season1/season1_learning.dart';
import 'season1/season1_mock.dart';
import 'season2/season2_difficulty.dart';
import 'season2/season2_discoveries.dart';
import 'season2/season2_case03_scenes.dart';
import 'season2/season2_case04_scenes.dart';
import 'season2/season2_case05_scenes.dart';
import 'season2/season2_case06_scenes.dart';
import 'season2/season2_case07_scenes.dart';
import 'season2/season2_case08_scenes.dart';
import 'season2/season2_case09_scenes.dart';
import 'season2/season2_case10_scenes.dart';
import 'season2/season2_case11_scenes.dart';
import 'season2/season2_case12_scenes.dart';
import 'season2/season2_learning.dart';
import 'season2/season2_mock.dart';
import 'season2/season2_scenes.dart';

/// One season's bundled content: who the season is, its cases, and the
/// tables that give some of its missions more than their question (a scene
/// to search, a lens, a talk…), its Discovery Moments and its learning
/// notes. Every table is keyed by mission (or case) id.
///
/// A new puzzle kind joins as one more table here (and its widget in the
/// mission page), so no page reads a season's files directly.
class SeasonContent {
  const SeasonContent({
    required this.info,
    required this.episodes,
    this.awaitingArt = const {},
    this.places = const {},
    this.released = true,
    this.storyGreeting = true,
    this.investigations = const {},
    this.explores = const {},
    this.inspections = const {},
    this.deductions = const {},
    this.decodes = const {},
    this.dialogues = const {},
    this.talks = const {},
    this.talkMissions = const {},
    this.easySteps = const {},
    this.endings = const {},
    this.clocks = const {},
    this.stationClocks = const {},
    this.compares = const {},
    this.studios = const {},
    this.layers = const {},
    this.canvases = const {},
    this.records = const {},
    this.lifts = const {},
    this.dialLocks = const {},
    this.evidenceBoards = const {},
    this.riverMarks = const {},
    this.keeperHuts = const {},
    this.quayBoxes = const {},
    this.streetBooks = const {},
    this.markCompares = const {},
    this.clockWalls = const {},
    this.blotters = const {},
    this.postTrails = const {},
    this.holdRacks = const {},
    this.planRoutes = const {},
    this.archives = const {},
    this.letterMaps = const {},
    this.showStrips = const {},
    this.lightBoards = const {},
    this.flyRails = const {},
    this.lightTables = const {},
    this.cornerChoices = const {},
    this.morningSketches = const {},
    this.tornSlips = const {},
    this.tornHours = const {},
    this.trialMaps = const {},
    this.gearBoards = const {},
    this.makerMarks = const {},
    this.towerTests = const {},
    this.drumTapes = const {},
    this.cityClocks = const {},
    this.shadowChecks = const {},
    this.hourRecords = const {},
    this.introPictures = const {},
    this.introPlaques = const {},
    this.introPapers = const {},
    this.evidenceArt = const {},
    this.exhibits = const {},
    this.lockBoxes = const {},
    this.evidenceLinks = const {},
    this.storyScenes = const {},
    this.discoveries = const {},
    this.storyEvidence = const {},
    this.learning = const {},
    this.languageTopics = const {},
    this.casePatches = const {},
    this.variants = const {},
    this.discoveryOf,
    this.writtenLevels = const {},
    this.infoLevels = const {},
    this.retiredEngines = const {},
  });

  /// The season as JSON (see [Season.fromJson]).
  final Map<String, dynamic> info;

  /// The season's cases as JSON, in case order, by case id.
  final Map<String, Map<String, dynamic>> episodes;

  /// Cases written but waiting for their pictures (as JSON, in case order,
  /// by case id): never in the game — no case file, board, map or save
  /// shows them, whatever is solved and whoever plays (operator access and
  /// season preview included). A case is never played without the
  /// pictures its puzzles are played on. Their missions' content (learning,
  /// links) is still found by mission id, so it can be checked.
  final Map<String, Map<String, dynamic>> awaitingArt;

  /// The places the season registers as data, by season place id
  /// (`s3_tokyo.station`, see [ScenePlaceIds]): a new season's places, with
  /// no [Artwork] value. Seasons 1 and 2 have none (their places are
  /// [Artwork] scenes). A mission names one by `sceneKey`; the pages show
  /// its picture ([placeFor]). Checked by `ScenePlaceCheck`.
  final Map<String, ScenePlace> places;

  /// Whether the season is out for players. An unreleased season stays
  /// COMING SOON for everyone, whatever is solved and whatever is in the
  /// game; only an operator build's season preview plays it (see
  /// `SeasonAvailability`).
  final bool released;

  /// The story after a solve greets the detective ("Great work, Detective
  /// …") under MISSION / CASE COMPLETE. Season 2 leaves it out: its
  /// Discovery Moment has just cheered the solve, and the story goes
  /// straight on.
  final bool storyGreeting;

  final Map<String, InvestigationScene> investigations;
  final Map<String, ExploreScene> explores;
  final Map<String, InspectScene> inspections;
  final Map<String, DeductionScene> deductions;
  final Map<String, DecodeScene> decodes;
  final Map<String, DialogueScene> dialogues;

  /// Missions played by talking with one person (Season 2, Cases 11–12):
  /// questions asked, evidence shown, the talk's answer the mission's (see
  /// [TalkScene], the `CaseTalk` page).
  final Map<String, TalkScene> talks;

  /// Missions played with their own puzzle and a talk before and/or after
  /// it (see [TalkMission]).
  final Map<String, TalkMission> talkMissions;

  /// Missions (and finals) played one small step at a time (Season 2,
  /// Cases 11–12, and the very-easy missions of Cases 04, 05 and 07: see
  /// [EasyStepsScene]).
  final Map<String, EasyStepsScene> easySteps;

  /// Finals with an ending played after their answer, one line at a time
  /// (Case 12): the case closes once it is seen.
  final Map<String, List<EndingLine>> endings;
  final Map<String, ClockPuzzle> clocks;

  /// Missions played by comparing a place's clocks (Season 2, Case 01 M1).
  final Map<String, StationClocksScene> stationClocks;

  /// Missions played on Case 02's pictures (Season 2): a place compared with
  /// its painting, a studio looked round and its notes joined to its
  /// paintings, a sketch uncovered under paint, the canvases of the final.
  final Map<String, CompareScene> compares;
  final Map<String, StudioScene> studios;
  final Map<String, LayerScene> layers;
  final Map<String, CanvasScene> canvases;

  /// Missions played on Case 03's pictures (Season 2): two records compared
  /// line by line, a lift log read against its route plate, a padlock's
  /// three dials, and the final's evidence linked to its questions.
  final Map<String, RecordsScene> records;
  final Map<String, LiftScene> lifts;
  final Map<String, DialLockScene> dialLocks;
  final Map<String, EvidenceBoardScene> evidenceBoards;

  /// Missions played on Case 04's pictures (Season 2): the quay wall's
  /// marks, the keeper's hut and ledger, the green boxes and the torn
  /// label, and the final's street book and gate.
  final Map<String, RiverMarksScene> riverMarks;
  final Map<String, KeeperHutScene> keeperHuts;
  final Map<String, BoxesScene> quayBoxes;
  final Map<String, StreetBookScene> streetBooks;

  /// Missions played on Case 05's pictures (Season 2): the workbench's
  /// stamps under the tracing sheet, the wall of clocks watched for a
  /// minute, the blotter read in a hand mirror, and the final's post slips.
  final Map<String, MarkCompareScene> markCompares;
  final Map<String, ClockWallScene> clockWalls;
  final Map<String, BlotterScene> blotters;
  final Map<String, PostTrailScene> postTrails;

  /// Missions played on Case 06's pictures (Season 2): the hold rack's tags
  /// turned over, the letter moved along the plan of the building, the
  /// archive's drawers and the torn corner fitted to its envelope, and the
  /// final's letter matched to the map of Paris.
  final Map<String, HoldRackScene> holdRacks;
  final Map<String, PlanScene> planRoutes;
  final Map<String, ArchiveScene> archives;
  final Map<String, LetterMapScene> letterMaps;

  /// Missions played on Case 07's pictures (Season 2): the show's strip slid
  /// along the clock, the stage lit like the old photo from the lighting
  /// desk, the backdrops lowered from the rope rail, and the final's light
  /// table and the Amendment Slip pinned to FILE 3.
  final Map<String, ShowStripScene> showStrips;
  final Map<String, LightBoardScene> lightBoards;
  final Map<String, FlyRailScene> flyRails;
  final Map<String, LightTableScene> lightTables;

  /// Missions played on Case 08's pictures (Season 2): the square's corners
  /// beside the Hidden Sketch, P.'s three drawings put in order and laid
  /// over each other, the torn paper unfolded beside the Amendment Slip,
  /// and the final's paper laid on P.'s drawing and its board.
  final Map<String, CornerChoiceScene> cornerChoices;
  final Map<String, MorningSketchesScene> morningSketches;
  final Map<String, TornSlipScene> tornSlips;
  final Map<String, TornHourScene> tornHours;

  /// Missions played on Case 09's pictures (Season 2): the little clocks put
  /// back on the map, the gears fitted on the board, the notebook's marks
  /// joined on the old plan, and the final's tower set one hour back.
  final Map<String, TrialMapScene> trialMaps;
  final Map<String, GearBoardScene> gearBoards;
  final Map<String, MakerMarksScene> makerMarks;
  final Map<String, TowerTestScene> towerTests;

  /// Missions played on Case 10's pictures (Season 2): T1's tape and its
  /// jumps, the roof photo's clocks sorted, the sundial's shadow made, and
  /// the final's tape laid beside the sun's time.
  final Map<String, DrumTapeScene> drumTapes;
  final Map<String, CityClocksScene> cityClocks;
  final Map<String, ShadowCheckScene> shadowChecks;
  final Map<String, HourRecordScene> hourRecords;

  /// By case id: a picture under the case's opening lines that turns into
  /// another (Case 09: P.'s drawing into the garden).
  final Map<String, IntroPicture> introPictures;

  /// By case id: a picture shown under the case's opening lines.
  final Map<String, IntroPlaque> introPlaques;

  /// By case id: a paper shown under one of the case's opening lines.
  final Map<String, IntroPaper> introPapers;

  /// By evidence id: evidence drawn with its words (its picture is blank).
  final Map<String, RiverEvidenceArt> evidenceArt;

  /// Things handed over with a mission's document, to look at closer.
  final Map<String, Exhibit> exhibits;

  /// Final cases opened on a letter-lock box in two pictures.
  final Map<String, LockBoxArt> lockBoxes;

  /// By evidence id: the evidence of the same case it matches.
  final Map<String, EvidenceLink> evidenceLinks;

  /// A mission's pictures as the story goes through it (its place page, the
  /// scene after it): Season 2's own, never the same station each time.
  final Map<String, StoryScenes> storyScenes;

  final Map<String, Discovery> discoveries;

  /// Missions whose evidence the scene after the puzzle hands over.
  final Set<String> storyEvidence;

  final Map<String, LearningObjective> learning;

  /// By case id.
  final Map<String, CaseLanguageTopic> languageTopics;

  /// The words of the cases at each level (see `DifficultyContent`): by
  /// level, case id → a patch of the case's JSON (its text fields only; its
  /// ids, answers and order never). A case with no patch at a level reads
  /// the base (the game's own words, Rookie's).
  final Map<Difficulty, Map<String, Map<String, Object?>>> casePatches;

  /// The puzzles' own tables at each level (talks, scenes, clocks,
  /// Discovery Moments, learning…): by level, a season content holding only
  /// the entries that differ at that level (its info and cases empty). A
  /// mission finds its entry at its level first (see [SeasonCatalog]).
  final Map<Difficulty, SeasonContent> variants;

  /// A mission's Discovery Moment made from the mission itself, at its
  /// level (Season 2: its own success line), when [discoveries] has none.
  final Discovery? Function(Mission m)? discoveryOf;

  /// By case id: the levels whose words are written for the whole case
  /// (marked as each case is done, PART 6–7). At a written Junior or Master
  /// level every text of the case has its own words at that very level —
  /// checked (`DifficultyContent.missingAt`), never left to fall back on
  /// another level's. Rookie written: its words were reviewed (the base
  /// stays wherever they were kept).
  final Map<String, Set<Difficulty>> writtenLevels;

  /// The season's own lines at each level (the generated seasons): by
  /// level, `outro` / `finale` → its lines, as many as [info]'s own (see
  /// `DifficultyContent.seasonAt`). A level without them reads [info]'s.
  final Map<Difficulty, Map<String, List<String>>> infoLevels;

  /// Puzzle tables (by their name in [missionTables]) kept but never
  /// played: each of their entries is under an engine the page plays before
  /// it, on purpose. Their entries stay (their words are checked at every
  /// level); `PuzzleEngineCollisionCheck` accepts them under another engine
  /// and reports one that is played. Read by checks only, never the game.
  final Set<String> retiredEngines;

  /// Every table looked up by mission id (the ones [SeasonCatalog] reads at
  /// a mission's level), by name: what a level's [variants] may hold, and
  /// what `DifficultyContent` checks.
  Map<String, Map<String, Object?>> get missionTables => {
    'investigations': investigations,
    'explores': explores,
    'inspections': inspections,
    'deductions': deductions,
    'decodes': decodes,
    'dialogues': dialogues,
    'talks': talks,
    'talkMissions': talkMissions,
    'easySteps': easySteps,
    'endings': endings,
    'clocks': clocks,
    'stationClocks': stationClocks,
    'compares': compares,
    'studios': studios,
    'layers': layers,
    'canvases': canvases,
    'records': records,
    'lifts': lifts,
    'dialLocks': dialLocks,
    'evidenceBoards': evidenceBoards,
    'riverMarks': riverMarks,
    'keeperHuts': keeperHuts,
    'quayBoxes': quayBoxes,
    'streetBooks': streetBooks,
    'markCompares': markCompares,
    'clockWalls': clockWalls,
    'blotters': blotters,
    'postTrails': postTrails,
    'holdRacks': holdRacks,
    'planRoutes': planRoutes,
    'archives': archives,
    'letterMaps': letterMaps,
    'showStrips': showStrips,
    'lightBoards': lightBoards,
    'flyRails': flyRails,
    'lightTables': lightTables,
    'cornerChoices': cornerChoices,
    'morningSketches': morningSketches,
    'tornSlips': tornSlips,
    'tornHours': tornHours,
    'trialMaps': trialMaps,
    'gearBoards': gearBoards,
    'makerMarks': makerMarks,
    'towerTests': towerTests,
    'drumTapes': drumTapes,
    'cityClocks': cityClocks,
    'shadowChecks': shadowChecks,
    'hourRecords': hourRecords,
    'exhibits': exhibits,
    'lockBoxes': lockBoxes,
    'storyScenes': storyScenes,
    'discoveries': discoveries,
    'learning': learning,
  };

  Season get season => Season.fromJson(info);

  String get id => season.id;
}

/// Season 1 — Shadows over London: its content as it always was.
final season1Content = SeasonContent(
  info: season1InfoJson,
  episodes: const {'ep01': episode01Json, ...season1Json},
  investigations: season1Investigations,
  explores: season1Explores,
  inspections: season1Inspections,
  deductions: season1Deductions,
  decodes: season1Decodes,
  dialogues: season1Dialogues,
  clocks: season1Clocks,
  discoveries: season1Discoveries,
  storyEvidence: season1StoryEvidence,
  learning: season1Learning,
  languageTopics: season1LanguageTopics,
  casePatches: season1CasePatches,
  variants: season1Variants,
  writtenLevels: season1WrittenLevels,
);

/// Season 2 — Paris Stands Still: in the making, not released (its cases
/// are played only in an operator build's season preview).
final season2Content = SeasonContent(
  info: season2InfoJson,
  episodes: season2Json,
  awaitingArt: season2AwaitingArtJson,
  // Made from each mission as it is played (its success line at its level).
  discoveryOf: season2DiscoveryOf,
  released: true,
  storyGreeting: false,
  clocks: season2Clocks,
  stationClocks: season2StationClocks,
  compares: season2Compares,
  studios: season2Studios,
  layers: season2Layers,
  canvases: season2Canvases,
  records: season2Records,
  lifts: season2Lifts,
  dialLocks: season2DialLocks,
  evidenceBoards: season2EvidenceBoards,
  riverMarks: season2RiverMarks,
  keeperHuts: season2KeeperHuts,
  quayBoxes: season2QuayBoxes,
  streetBooks: season2StreetBooks,
  markCompares: season2MarkCompares,
  clockWalls: season2ClockWalls,
  // Case 05's M3 (the blotter), Case 07's M1 (the show strip) and M2 (the
  // lighting desk) are played very easy since 2026-10-27 (`easySteps`).
  postTrails: season2PostTrails,
  holdRacks: season2HoldRackScenes,
  planRoutes: season2PlanScenes,
  archives: season2ArchiveScenes,
  letterMaps: season2LetterMapScenes,
  flyRails: season2FlyRailScenes,
  lightTables: season2LightTableScenes,
  cornerChoices: season2CornerChoices,
  morningSketches: season2MorningSketches,
  tornSlips: season2TornSlips,
  tornHours: season2TornHours,
  trialMaps: season2TrialMaps,
  gearBoards: season2GearBoards,
  makerMarks: season2MakerMarksScenes,
  towerTests: season2TowerTests,
  drumTapes: season2DrumTapes,
  cityClocks: season2CityClocksScenes,
  shadowChecks: season2ShadowChecks,
  hourRecords: season2HourRecords,
  talks: season2Case11Talks,
  talkMissions: {...season2Case11TalkMissions, ...season2Case12TalkMissions},
  // Case 04's final, Case 05's M3 and final, Case 07's M1, M2 and final:
  // very easy since 2026-10-27, like Cases 11–12.
  easySteps: {
    ...season2Case04Steps,
    ...season2Case05Steps,
    ...season2Case07Steps,
    ...season2Case11Steps,
    ...season2Case12Steps,
  },
  endings: season2Case12Endings,
  introPictures: {
    ...season2IntroPictures,
    ...season2Case10IntroPictures,
    ...season2Case11IntroPictures,
    ...season2Case12IntroPictures,
  },
  introPlaques: season2IntroPlaques,
  introPapers: season2IntroPapers,
  evidenceArt: {
    ...season2Case02EvidenceArt,
    ...season2Case04EvidenceArt,
    ...season2Case05EvidenceArt,
    ...season2Case06EvidenceArt,
    ...season2Case07EvidenceArt,
    ...season2Case08EvidenceArt,
    ...season2Case09EvidenceArt,
    ...season2Case10EvidenceArt,
    ...season2Case11EvidenceArt,
    ...season2Case12EvidenceArt,
  },
  exhibits: season2Exhibits,
  lockBoxes: season2LockBoxes,
  evidenceLinks: {
    ...season2EvidenceLinks,
    ...season2Case03EvidenceLinks,
    ...season2Case04EvidenceLinks,
    ...season2Case05EvidenceLinks,
    ...season2Case06EvidenceLinks,
    ...season2Case07EvidenceLinks,
    ...season2Case08EvidenceLinks,
    ...season2Case09EvidenceLinks,
    ...season2Case10EvidenceLinks,
    ...season2Case11EvidenceLinks,
    ...season2Case12EvidenceLinks,
  },
  storyScenes: {
    ...season2StoryScenes,
    ...season2Case02StoryScenes,
    ...season2Case03StoryScenes,
    ...season2Case04StoryScenes,
    ...season2Case05StoryScenes,
    ...season2Case06StoryScenes,
    ...season2Case07StoryScenes,
    ...season2Case08StoryScenes,
    ...season2Case09StoryScenes,
    ...season2Case10StoryScenes,
    ...season2Case11StoryScenes,
    ...season2Case12StoryScenes,
  },
  learning: season2Learning,
  languageTopics: season2LanguageTopics,
  casePatches: season2CasePatches,
  variants: season2Variants,
  writtenLevels: season2WrittenLevels,
  // The finals of Cases 04, 05 and 07 are played very easy since 2026-10-27
  // (`easySteps`, played first on a final page): their first engines stay
  // registered at every level, never played.
  retiredEngines: const {'streetBooks', 'postTrails', 'lightTables'},
);

/// Whether season [seasonId] is out for players (an unknown season is not).
bool seasonReleased(String seasonId) =>
    SeasonCatalog.byId(seasonId)?.released ?? false;

/// Every season of the game, in play order, and the one place that finds a
/// mission's or a case's season content. A mission's content is looked up in
/// its own season only (mission ids are never shared between seasons).
abstract final class SeasonCatalog {
  /// London, Paris, then the seasons made from their plans (Rome on:
  /// `generate_season.dart --target game`, listed by [generatedSeasons]).
  static final List<SeasonContent> all = [season1Content, season2Content, ...generatedSeasons];

  /// The season with [seasonId], or null when there is none.
  static SeasonContent? byId(String seasonId) {
    for (final s in all) {
      if (s.id == seasonId) return s;
    }
    return null;
  }

  /// Where [seasonId] is in play order (-1: no such season).
  static int indexOf(String seasonId) =>
      all.indexWhere((s) => s.id == seasonId);

  /// The season whose cases include [episodeId] (in the game or awaiting
  /// their pictures), or null.
  static SeasonContent? ofEpisode(String episodeId) {
    for (final s in all) {
      if (s.episodes.containsKey(episodeId) ||
          s.awaitingArt.containsKey(episodeId)) {
        return s;
      }
    }
    return null;
  }

  /// Whether case [episodeId] is written but waiting for its pictures (see
  /// [SeasonContent.awaitingArt]): never in the game until they are.
  static bool isAwaitingArt(String episodeId) =>
      all.any((s) => s.awaitingArt.containsKey(episodeId));

  /// The place season place id [id] names, registered by the season the id
  /// names (see [SeasonContent.places]), or null.
  static ScenePlace? place(String id) =>
      byId(ScenePlaceIds.seasonOf(id) ?? '')?.places[id] ?? testPlaces[id];

  /// The place [id] names, for a page to show: a [StateError] when no season
  /// registers it (never another place's picture in its stead).
  static ScenePlace placeFor(String id) =>
      place(id) ?? (throw StateError('Season place $id is not registered (SeasonContent.places)'));

  /// Places of a season that is not in the game, registered by a test only
  /// (cleared by it): the game's own are its seasons'.
  @visibleForTesting
  static final Map<String, ScenePlace> testPlaces = {};

  /// Mission id → its season and case, from the cases' own missions (the
  /// cases awaiting their pictures too: their content is checked by id).
  static final Map<String, (SeasonContent, String)> _missionSeason = {
    for (final s in all)
      for (final MapEntry(key: caseId, value: json) in {
        ...s.episodes,
        ...s.awaitingArt,
      }.entries)
        for (final m in Episode.fromJson({
          ...json,
          'seasonId': s.id,
        }).allMissions)
          m.id: (s, caseId),
  };

  /// Seasons that are not in the game, registered by a test only (cleared
  /// by it), so their missions find their puzzle tables as the game's do:
  /// a generated sandbox season's scenes and talks (STEP 3-13). Looked at
  /// only for a mission no season of the game has.
  @visibleForTesting
  static final List<SeasonContent> testSeasons = [];

  static (SeasonContent, String)? _testMission(String missionId) {
    for (final s in testSeasons) {
      for (final MapEntry(key: caseId, value: json) in s.episodes.entries) {
        final e = Episode.fromJson({...json, 'seasonId': s.id});
        if (e.allMissions.any((m) => m.id == missionId)) return (s, caseId);
      }
    }
    return null;
  }

  /// The season of the mission with [missionId], or null.
  static SeasonContent? ofMission(String missionId) =>
      _missionSeason[missionId]?.$1 ?? _testMission(missionId)?.$1;

  /// [m]'s entry in one of its season's tables (by mission id), at [m]'s
  /// level: the level's own entry ([SeasonContent.variants], looked for as
  /// [Difficulty.fallbackChain] says), else the season's base entry. The one
  /// place every puzzle table is read at a level: the pages ask for [m]'s
  /// talk, scene or clock as always, and the mission brings its level.
  static T? _pick<T>(Mission m, Map<String, T> Function(SeasonContent s) table) {
    final season = ofMission(m.id);
    if (season == null) return null;
    for (final level in m.difficulty.fallbackChain) {
      final variant = season.variants[level];
      if (variant == null) continue;
      if (table(variant)[m.id] case final found?) return found;
    }
    return table(season)[m.id];
  }

  /// The case of the mission with [missionId], or null.
  static String? episodeOfMission(String missionId) =>
      _missionSeason[missionId]?.$2 ?? _testMission(missionId)?.$2;

  static InvestigationScene? investigation(Mission m) =>
      _pick(m, (s) => s.investigations);

  static ExploreScene? explore(Mission m) => _pick(m, (s) => s.explores);

  static InspectScene? inspection(Mission m) =>
      _pick(m, (s) => s.inspections);

  static DeductionScene? deduction(Mission m) =>
      _pick(m, (s) => s.deductions);

  static DecodeScene? decode(Mission m) => _pick(m, (s) => s.decodes);

  static DialogueScene? dialogue(Mission m) => _pick(m, (s) => s.dialogues);

  static TalkScene? caseTalk(Mission m) => _pick(m, (s) => s.talks);

  static TalkMission? talkMission(Mission m) => _pick(m, (s) => s.talkMissions);

  static EasyStepsScene? easySteps(Mission m) => _pick(m, (s) => s.easySteps);

  /// The ending played after final [m]'s answer, if it has one.
  static List<EndingLine>? caseEnding(Mission m) => m.isFinal ? _pick(m, (s) => s.endings) : null;

  static ClockPuzzle? clock(Mission m) => _pick(m, (s) => s.clocks);

  static StationClocksScene? stationClocks(Mission m) =>
      _pick(m, (s) => s.stationClocks);

  static CompareScene? compare(Mission m) => _pick(m, (s) => s.compares);

  static StudioScene? studio(Mission m) => _pick(m, (s) => s.studios);

  static LayerScene? layer(Mission m) => _pick(m, (s) => s.layers);

  static CanvasScene? canvasChoice(Mission m) =>
      _pick(m, (s) => s.canvases);

  static RecordsScene? records(Mission m) => _pick(m, (s) => s.records);

  static LiftScene? lift(Mission m) => _pick(m, (s) => s.lifts);

  static DialLockScene? dialLock(Mission m) => _pick(m, (s) => s.dialLocks);

  static EvidenceBoardScene? evidenceBoard(Mission m) =>
      _pick(m, (s) => s.evidenceBoards);

  static RiverMarksScene? riverMarks(Mission m) =>
      _pick(m, (s) => s.riverMarks);

  static KeeperHutScene? keeperHut(Mission m) =>
      _pick(m, (s) => s.keeperHuts);

  static BoxesScene? quayBoxes(Mission m) => _pick(m, (s) => s.quayBoxes);

  static StreetBookScene? streetBook(Mission m) =>
      _pick(m, (s) => s.streetBooks);

  static MarkCompareScene? markCompare(Mission m) =>
      _pick(m, (s) => s.markCompares);

  static ClockWallScene? clockWall(Mission m) =>
      _pick(m, (s) => s.clockWalls);

  static BlotterScene? blotter(Mission m) => _pick(m, (s) => s.blotters);

  static PostTrailScene? postTrail(Mission m) =>
      _pick(m, (s) => s.postTrails);

  static HoldRackScene? holdRack(Mission m) => _pick(m, (s) => s.holdRacks);

  static PlanScene? planRoute(Mission m) => _pick(m, (s) => s.planRoutes);

  static ArchiveScene? archive(Mission m) => _pick(m, (s) => s.archives);

  static LetterMapScene? letterMap(Mission m) =>
      _pick(m, (s) => s.letterMaps);

  static ShowStripScene? showStrip(Mission m) =>
      _pick(m, (s) => s.showStrips);

  static LightBoardScene? lightBoard(Mission m) =>
      _pick(m, (s) => s.lightBoards);

  static FlyRailScene? flyRail(Mission m) => _pick(m, (s) => s.flyRails);

  static LightTableScene? lightTable(Mission m) =>
      _pick(m, (s) => s.lightTables);

  static CornerChoiceScene? cornerChoice(Mission m) => _pick(m, (s) => s.cornerChoices);

  static MorningSketchesScene? morningSketches(Mission m) => _pick(m, (s) => s.morningSketches);

  static TornSlipScene? tornSlip(Mission m) => _pick(m, (s) => s.tornSlips);

  static TornHourScene? tornHour(Mission m) => _pick(m, (s) => s.tornHours);

  static TrialMapScene? trialMap(Mission m) => _pick(m, (s) => s.trialMaps);

  static GearBoardScene? gearBoard(Mission m) => _pick(m, (s) => s.gearBoards);

  static MakerMarksScene? makerMarks(Mission m) => _pick(m, (s) => s.makerMarks);

  static TowerTestScene? towerTest(Mission m) => _pick(m, (s) => s.towerTests);

  static DrumTapeScene? drumTape(Mission m) => _pick(m, (s) => s.drumTapes);

  static CityClocksScene? cityClocks(Mission m) => _pick(m, (s) => s.cityClocks);

  static ShadowCheckScene? shadowCheck(Mission m) => _pick(m, (s) => s.shadowChecks);

  static HourRecordScene? hourRecord(Mission m) => _pick(m, (s) => s.hourRecords);

  /// Whether final [m]'s case closes only after a step after its answer
  /// (Paris Case 08: P.'s last drawing, matched to the map; Case 09: the
  /// star followed to the map; Case 10: the record list read; Case 12:
  /// its ending seen), not with the answer itself.
  static bool closesAfterLastStep(Mission m) =>
      m.isFinal && (tornHour(m) != null || towerTest(m) != null || hourRecord(m) != null || caseEnding(m) != null);

  /// The picture under case [episodeId]'s opening lines that turns into
  /// another, if any.
  static IntroPicture? introPicture(String episodeId) => ofEpisode(episodeId)?.introPictures[episodeId];

  /// The paper under one of case [episodeId]'s opening lines, if any.
  static IntroPaper? introPaper(String episodeId) => ofEpisode(episodeId)?.introPapers[episodeId];

  /// The picture under case [episodeId]'s opening lines, if any.
  static IntroPlaque? introPlaque(String episodeId) =>
      ofEpisode(episodeId)?.introPlaques[episodeId];

  /// Evidence [evidenceId] drawn with its words, if it is drawn so.
  static RiverEvidenceArt? evidenceArt(String evidenceId) {
    for (final s in all) {
      if (s.evidenceArt[evidenceId] case final art?) return art;
    }
    return null;
  }

  static Exhibit? exhibit(Mission m) => _pick(m, (s) => s.exhibits);

  static LockBoxArt? lockBox(Mission m) => _pick(m, (s) => s.lockBoxes);

  static StoryScenes? storyScenes(Mission m) =>
      _pick(m, (s) => s.storyScenes);

  /// The evidence [evidenceId] matches, from its season's content (evidence
  /// ids are never shared between seasons), or null.
  /// Whether the story after [m] greets the detective (a mission no
  /// season has: as Season 1 does).
  static bool storyGreeting(Mission m) =>
      ofMission(m.id)?.storyGreeting ?? true;

  static EvidenceLink? evidenceLink(String evidenceId) {
    for (final s in all) {
      final link = s.evidenceLinks[evidenceId];
      if (link != null) return link;
    }
    return null;
  }

  /// [m]'s Discovery Moment: its own, or a solved puzzle for one without.
  /// Made from [m] itself when its season builds it so (Season 2: its own
  /// success line, at its level — never a line kept from another level).
  static Discovery discovery(Mission m) =>
      _pick(m, (s) => s.discoveries) ?? ofMission(m.id)?.discoveryOf?.call(m) ?? Discovery.fallback(m);

  /// The evidence the scene after [m] hands over, if any.
  static Evidence? storyEvidence(Mission m) =>
      (ofMission(m.id)?.storyEvidence.contains(m.id) ?? false)
      ? m.evidence
      : null;

  static LearningObjective? learning(Mission m) =>
      _pick(m, (s) => s.learning);

  static CaseLanguageTopic? languageTopic(String episodeId) =>
      ofEpisode(episodeId)?.languageTopics[episodeId];
}
