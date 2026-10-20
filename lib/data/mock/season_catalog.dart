import '../models/clock_puzzle.dart';
import '../models/dialogue.dart';
import '../models/discovery.dart';
import '../models/episode.dart';
import '../models/investigation.dart';
import '../models/learning.dart';
import '../models/mission.dart';
import '../models/scene_decode.dart';
import '../models/scene_deduction.dart';
import '../models/scene_explore.dart';
import '../models/scene_inspect.dart';
import '../models/season.dart';
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
import 'season2/season2_learning.dart';
import 'season2/season2_mock.dart';

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
    this.released = true,
    this.investigations = const {},
    this.explores = const {},
    this.inspections = const {},
    this.deductions = const {},
    this.decodes = const {},
    this.dialogues = const {},
    this.clocks = const {},
    this.discoveries = const {},
    this.storyEvidence = const {},
    this.learning = const {},
    this.languageTopics = const {},
  });

  /// The season as JSON (see [Season.fromJson]).
  final Map<String, dynamic> info;

  /// The season's cases as JSON, in case order, by case id.
  final Map<String, Map<String, dynamic>> episodes;

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
  released: false,
  learning: season2Learning,
  languageTopics: season2LanguageTopics,
);

/// Whether season [seasonId] is out for players (an unknown season is not).
bool seasonReleased(String seasonId) => SeasonCatalog.byId(seasonId)?.released ?? false;

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
  static int indexOf(String seasonId) => all.indexWhere((s) => s.id == seasonId);

  /// The season whose cases include [episodeId], or null.
  static SeasonContent? ofEpisode(String episodeId) {
    for (final s in all) {
      if (s.episodes.containsKey(episodeId)) return s;
    }
    return null;
  }

  /// Mission id → its season and case, from the cases' own missions.
  static final Map<String, (SeasonContent, String)> _missionSeason = {
    for (final s in all)
      for (final MapEntry(key: caseId, value: json) in s.episodes.entries)
        for (final m in Episode.fromJson(json).allMissions) m.id: (s, caseId),
  };

  /// The season of the mission with [missionId], or null.
  static SeasonContent? ofMission(String missionId) => _missionSeason[missionId]?.$1;

  /// The case of the mission with [missionId], or null.
  static String? episodeOfMission(String missionId) => _missionSeason[missionId]?.$2;

  static InvestigationScene? investigation(Mission m) => ofMission(m.id)?.investigations[m.id];

  static ExploreScene? explore(Mission m) => ofMission(m.id)?.explores[m.id];

  static InspectScene? inspection(Mission m) => ofMission(m.id)?.inspections[m.id];

  static DeductionScene? deduction(Mission m) => ofMission(m.id)?.deductions[m.id];

  static DecodeScene? decode(Mission m) => ofMission(m.id)?.decodes[m.id];

  static DialogueScene? dialogue(Mission m) => ofMission(m.id)?.dialogues[m.id];

  static ClockPuzzle? clock(Mission m) => ofMission(m.id)?.clocks[m.id];

  /// [m]'s Discovery Moment: its own, or a solved puzzle for one without.
  static Discovery discovery(Mission m) => ofMission(m.id)?.discoveries[m.id] ?? Discovery.fallback(m);

  /// The evidence the scene after [m] hands over, if any.
  static Evidence? storyEvidence(Mission m) =>
      (ofMission(m.id)?.storyEvidence.contains(m.id) ?? false) ? m.evidence : null;

  static LearningObjective? learning(Mission m) => ofMission(m.id)?.learning[m.id];

  static CaseLanguageTopic? languageTopic(String episodeId) => ofEpisode(episodeId)?.languageTopics[episodeId];
}
