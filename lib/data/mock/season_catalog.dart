import '../models/abbesses_puzzles.dart';
import '../models/clock_puzzle.dart';
import '../models/dialogue.dart';
import '../models/discovery.dart';
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
import '../models/season.dart';
import '../models/station_clocks.dart';
import '../models/story_picture.dart';
import '../models/tower_puzzles.dart';
import '../models/workshop_puzzles.dart';
import 'season1/episode01_mock.dart';
import 'season1/season1_clocks.dart';
import 'season1/season1_decodes.dart';
import 'season1/season1_deductions.dart';
import 'season1/season1_dialogues.dart';
import 'season1/season1_discoveries.dart';
import 'season1/season1_explores.dart';
import 'season1/season1_inspections.dart';
import 'season1/season1_investigations.dart';
import 'season1/season1_learning.dart';
import 'season1/season1_mock.dart';
import 'season2/season2_discoveries.dart';
import 'season2/season2_case03_scenes.dart';
import 'season2/season2_case04_scenes.dart';
import 'season2/season2_case05_scenes.dart';
import 'season2/season2_case06_scenes.dart';
import 'season2/season2_case07_scenes.dart';
import 'season2/season2_case08_scenes.dart';
import 'season2/season2_case09_scenes.dart';
import 'season2/season2_case10_scenes.dart';
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
    this.released = true,
    this.storyGreeting = true,
    this.investigations = const {},
    this.explores = const {},
    this.inspections = const {},
    this.deductions = const {},
    this.decodes = const {},
    this.dialogues = const {},
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
);

/// Season 2 — Paris Stands Still: in the making, not released (its cases
/// are played only in an operator build's season preview).
final season2Content = SeasonContent(
  info: season2InfoJson,
  episodes: season2Json,
  awaitingArt: season2AwaitingArtJson,
  discoveries: season2DiscoveriesOf(season2Json),
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
  blotters: season2Blotters,
  postTrails: season2PostTrails,
  holdRacks: season2HoldRackScenes,
  planRoutes: season2PlanScenes,
  archives: season2ArchiveScenes,
  letterMaps: season2LetterMapScenes,
  showStrips: season2ShowStripScenes,
  lightBoards: season2LightBoardScenes,
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
  introPictures: {...season2IntroPictures, ...season2Case10IntroPictures},
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
  },
  learning: season2Learning,
  languageTopics: season2LanguageTopics,
);

/// Whether season [seasonId] is out for players (an unknown season is not).
bool seasonReleased(String seasonId) =>
    SeasonCatalog.byId(seasonId)?.released ?? false;

/// Every season of the game, in play order, and the one place that finds a
/// mission's or a case's season content. A mission's content is looked up in
/// its own season only (mission ids are never shared between seasons).
abstract final class SeasonCatalog {
  static final List<SeasonContent> all = [season1Content, season2Content];

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

  /// The season of the mission with [missionId], or null.
  static SeasonContent? ofMission(String missionId) =>
      _missionSeason[missionId]?.$1;

  /// The case of the mission with [missionId], or null.
  static String? episodeOfMission(String missionId) =>
      _missionSeason[missionId]?.$2;

  static InvestigationScene? investigation(Mission m) =>
      ofMission(m.id)?.investigations[m.id];

  static ExploreScene? explore(Mission m) => ofMission(m.id)?.explores[m.id];

  static InspectScene? inspection(Mission m) =>
      ofMission(m.id)?.inspections[m.id];

  static DeductionScene? deduction(Mission m) =>
      ofMission(m.id)?.deductions[m.id];

  static DecodeScene? decode(Mission m) => ofMission(m.id)?.decodes[m.id];

  static DialogueScene? dialogue(Mission m) => ofMission(m.id)?.dialogues[m.id];

  static ClockPuzzle? clock(Mission m) => ofMission(m.id)?.clocks[m.id];

  static StationClocksScene? stationClocks(Mission m) =>
      ofMission(m.id)?.stationClocks[m.id];

  static CompareScene? compare(Mission m) => ofMission(m.id)?.compares[m.id];

  static StudioScene? studio(Mission m) => ofMission(m.id)?.studios[m.id];

  static LayerScene? layer(Mission m) => ofMission(m.id)?.layers[m.id];

  static CanvasScene? canvasChoice(Mission m) =>
      ofMission(m.id)?.canvases[m.id];

  static RecordsScene? records(Mission m) => ofMission(m.id)?.records[m.id];

  static LiftScene? lift(Mission m) => ofMission(m.id)?.lifts[m.id];

  static DialLockScene? dialLock(Mission m) => ofMission(m.id)?.dialLocks[m.id];

  static EvidenceBoardScene? evidenceBoard(Mission m) =>
      ofMission(m.id)?.evidenceBoards[m.id];

  static RiverMarksScene? riverMarks(Mission m) =>
      ofMission(m.id)?.riverMarks[m.id];

  static KeeperHutScene? keeperHut(Mission m) =>
      ofMission(m.id)?.keeperHuts[m.id];

  static BoxesScene? quayBoxes(Mission m) => ofMission(m.id)?.quayBoxes[m.id];

  static StreetBookScene? streetBook(Mission m) =>
      ofMission(m.id)?.streetBooks[m.id];

  static MarkCompareScene? markCompare(Mission m) =>
      ofMission(m.id)?.markCompares[m.id];

  static ClockWallScene? clockWall(Mission m) =>
      ofMission(m.id)?.clockWalls[m.id];

  static BlotterScene? blotter(Mission m) => ofMission(m.id)?.blotters[m.id];

  static PostTrailScene? postTrail(Mission m) =>
      ofMission(m.id)?.postTrails[m.id];

  static HoldRackScene? holdRack(Mission m) => ofMission(m.id)?.holdRacks[m.id];

  static PlanScene? planRoute(Mission m) => ofMission(m.id)?.planRoutes[m.id];

  static ArchiveScene? archive(Mission m) => ofMission(m.id)?.archives[m.id];

  static LetterMapScene? letterMap(Mission m) =>
      ofMission(m.id)?.letterMaps[m.id];

  static ShowStripScene? showStrip(Mission m) =>
      ofMission(m.id)?.showStrips[m.id];

  static LightBoardScene? lightBoard(Mission m) =>
      ofMission(m.id)?.lightBoards[m.id];

  static FlyRailScene? flyRail(Mission m) => ofMission(m.id)?.flyRails[m.id];

  static LightTableScene? lightTable(Mission m) =>
      ofMission(m.id)?.lightTables[m.id];

  static CornerChoiceScene? cornerChoice(Mission m) => ofMission(m.id)?.cornerChoices[m.id];

  static MorningSketchesScene? morningSketches(Mission m) => ofMission(m.id)?.morningSketches[m.id];

  static TornSlipScene? tornSlip(Mission m) => ofMission(m.id)?.tornSlips[m.id];

  static TornHourScene? tornHour(Mission m) => ofMission(m.id)?.tornHours[m.id];

  static TrialMapScene? trialMap(Mission m) => ofMission(m.id)?.trialMaps[m.id];

  static GearBoardScene? gearBoard(Mission m) => ofMission(m.id)?.gearBoards[m.id];

  static MakerMarksScene? makerMarks(Mission m) => ofMission(m.id)?.makerMarks[m.id];

  static TowerTestScene? towerTest(Mission m) => ofMission(m.id)?.towerTests[m.id];

  static DrumTapeScene? drumTape(Mission m) => ofMission(m.id)?.drumTapes[m.id];

  static CityClocksScene? cityClocks(Mission m) => ofMission(m.id)?.cityClocks[m.id];

  static ShadowCheckScene? shadowCheck(Mission m) => ofMission(m.id)?.shadowChecks[m.id];

  static HourRecordScene? hourRecord(Mission m) => ofMission(m.id)?.hourRecords[m.id];

  /// Whether final [m]'s case closes only after a step after its answer
  /// (Paris Case 08: P.'s last drawing, matched to the map; Case 09: the
  /// star followed to the map; Case 10: the record list read), not with
  /// the answer itself.
  static bool closesAfterLastStep(Mission m) => m.isFinal && (tornHour(m) != null || towerTest(m) != null || hourRecord(m) != null);

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

  static Exhibit? exhibit(Mission m) => ofMission(m.id)?.exhibits[m.id];

  static LockBoxArt? lockBox(Mission m) => ofMission(m.id)?.lockBoxes[m.id];

  static StoryScenes? storyScenes(Mission m) =>
      ofMission(m.id)?.storyScenes[m.id];

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
  static Discovery discovery(Mission m) =>
      ofMission(m.id)?.discoveries[m.id] ?? Discovery.fallback(m);

  /// The evidence the scene after [m] hands over, if any.
  static Evidence? storyEvidence(Mission m) =>
      (ofMission(m.id)?.storyEvidence.contains(m.id) ?? false)
      ? m.evidence
      : null;

  static LearningObjective? learning(Mission m) =>
      ofMission(m.id)?.learning[m.id];

  static CaseLanguageTopic? languageTopic(String episodeId) =>
      ofEpisode(episodeId)?.languageTopics[episodeId];
}
