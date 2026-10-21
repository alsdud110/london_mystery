import '../models/clock_puzzle.dart';
import '../models/dialogue.dart';
import '../models/discovery.dart';
import '../models/episode.dart';
import '../models/investigation.dart';
import '../models/learning.dart';
import '../models/mission.dart';
import '../models/painter_puzzles.dart';
import '../models/scene_decode.dart';
import '../models/scene_deduction.dart';
import '../models/scene_exhibit.dart';
import '../models/scene_explore.dart';
import '../models/scene_inspect.dart';
import '../models/season.dart';
import '../models/station_clocks.dart';
import '../models/story_picture.dart';
import '../models/tower_puzzles.dart';
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
import 'season2/season2_case03_scenes.dart';
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
  released: true,
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
  exhibits: season2Exhibits,
  lockBoxes: season2LockBoxes,
  evidenceLinks: {...season2EvidenceLinks, ...season2Case03EvidenceLinks},
  storyScenes: {...season2StoryScenes, ...season2Case02StoryScenes, ...season2Case03StoryScenes},
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
          s.awaitingArt.containsKey(episodeId))
        return s;
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

  static EvidenceBoardScene? evidenceBoard(Mission m) => ofMission(m.id)?.evidenceBoards[m.id];

  static Exhibit? exhibit(Mission m) => ofMission(m.id)?.exhibits[m.id];

  static LockBoxArt? lockBox(Mission m) => ofMission(m.id)?.lockBoxes[m.id];

  static StoryScenes? storyScenes(Mission m) =>
      ofMission(m.id)?.storyScenes[m.id];

  /// The evidence [evidenceId] matches, from its season's content (evidence
  /// ids are never shared between seasons), or null.
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
