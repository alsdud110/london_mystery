import '../../core/constants/app_constants.dart';
import '../../core/utils/answer_checker.dart';
import '../mock/season_catalog.dart';
import '../models/difficulty.dart';
import '../models/episode.dart';
import '../models/mission.dart';
import '../models/scene_place.dart';
import 'difficulty_content.dart';
import 'puzzle_engine_collisions.dart';
import 'scene_place_check.dart';

/// One thing wrong in a season's content: where (season, case, mission),
/// which kind of rule ([rule]) and why ([message]).
class ContentIssue {
  const ContentIssue(this.seasonId, this.rule, this.message, {this.caseId, this.missionId});

  final String seasonId;
  final String? caseId;
  final String? missionId;

  /// `season`, `case`, `mission`, `answer`, `hint`, `reference`,
  /// `difficulty`, `place`, `progress` or `engine`.
  final String rule;
  final String message;

  @override
  String toString() => '[$rule] ${[seasonId, ?caseId, ?missionId].join(' ')}: $message';
}

/// The rules every season's content keeps, whatever its city: checked on
/// each season of `SeasonCatalog.all` by the tests, so a season added there
/// is checked with no code of its own. Never run by the game.
///
/// Static checks only: a season that passes is well formed (ids, order,
/// links, answers against their options, levels, places), not proven
/// solvable, well told, well pitched or well drawn — that is playtesting's.
/// Whether a place's picture is on disk, bundled and of its size is the
/// tests' (they read the files).
///
/// Reuses `DifficultyContent.problemsOf` (the levels' words) and
/// `ScenePlaceCheck.problemsOf` (places and scenes). Every issue is
/// collected: a case that does not parse is reported and the others are
/// still checked.
abstract final class SeasonContentValidator {
  /// Everything wrong in [seasons] (the game's by default), each season on
  /// its own and between them (their order, ids two seasons share).
  /// [engines]: how the puzzle engines' findings count
  /// (`PuzzleEngineCollisionCheck`; strict unless asked otherwise).
  static List<ContentIssue> validateAll([Iterable<SeasonContent>? seasons, EngineCheckPolicy engines = EngineCheckPolicy.strict]) {
    final all = (seasons ?? SeasonCatalog.all).toList();
    return [..._between(all), for (final s in all) ...validate(s, engines: engines)];
  }

  /// Everything wrong in [season] on its own.
  static List<ContentIssue> validate(SeasonContent season, {EngineCheckPolicy engines = EngineCheckPolicy.strict}) {
    final v = _SeasonCheck(season, engines)..run();
    return v.out;
  }

  // ── Between seasons ──────────────────────────────────────────────────

  static List<ContentIssue> _between(List<SeasonContent> all) {
    final out = <ContentIssue>[];
    final ids = <String>{};
    for (final (i, s) in all.indexed) {
      final info = s.season;
      if (!ids.add(s.id)) out.add(ContentIssue(s.id, 'season', 'season id registered twice'));
      if (ScenePlaceIds.seasonOf('${s.id}.place') != s.id) {
        out.add(ContentIssue(s.id, 'season', 'not a season id (no dot, nothing empty)'));
      }
      // Seasons open in catalog order (each after the one before), and are
      // labelled by number: SEASON ONE first.
      if (info.number != i + 1) {
        out.add(ContentIssue(s.id, 'season', 'number ${info.number}, but it is season ${i + 1} in the catalog'));
      }
      // A later season opens once the season before it has all its planned
      // cases and its last is solved: released after a season still short
      // of its cases, no player can ever reach it.
      if (i > 0 && s.released) {
        final before = all[i - 1];
        final planned = before.season.plannedCases ?? 0;
        if (before.episodes.isEmpty || before.episodes.length < planned) {
          out.add(ContentIssue(s.id, 'progress',
              'released, but ${before.id} has ${before.episodes.length} of its $planned cases: it can never be unlocked'));
        }
      }
    }
    // Ids the game keys saves, coins and the notebook by: one season's only.
    final owner = <String, String>{};
    void own(String kind, String id, SeasonContent s, {String? caseId}) {
      final first = owner.putIfAbsent('$kind $id', () => s.id);
      if (first != s.id) {
        out.add(ContentIssue(s.id, kind, '$kind id $id is also used by $first', caseId: caseId, missionId: kind == 'mission' ? id : null));
      }
    }

    for (final s in all) {
      for (final MapEntry(key: caseId, value: json) in _cases(s).entries) {
        own('case', caseId, s, caseId: caseId);
        final e = _parse(s, json);
        if (e == null) continue;
        for (final m in e.allMissions) {
          own('mission', m.id, s, caseId: caseId);
          if (m.clue case final c?) own('clue', c.id, s, caseId: caseId);
          if (m.evidence case final v?) own('evidence', v.id, s, caseId: caseId);
        }
      }
    }
    for (final p in ScenePlaceCheck.sharedPlaces(all)) {
      out.add(ContentIssue(p.split(' ').last, 'place', p));
    }
    return out;
  }

  /// Every case of [s]: in the game, then those awaiting their pictures.
  static Map<String, Map<String, dynamic>> _cases(SeasonContent s) => {...s.episodes, ...s.awaitingArt};

  static Episode? _parse(SeasonContent s, Map<String, dynamic> json) {
    try {
      return Episode.fromJson({...json, 'seasonId': s.id});
    } catch (_) {
      return null;
    }
  }
}

class _SeasonCheck {
  _SeasonCheck(this.s, this.engines);

  final SeasonContent s;
  final EngineCheckPolicy engines;
  final out = <ContentIssue>[];

  /// The cases that parse, by the id they are registered under, in case
  /// order (in the game, then awaiting art).
  final registered = <String, Episode>{};

  Iterable<Episode> get cases => registered.values;

  /// Every case id of the game's seasons and of this one.
  late final _caseIdsEverywhere = {
    for (final other in SeasonCatalog.all) ...SeasonContentValidator._cases(other).keys,
    ...SeasonContentValidator._cases(s).keys,
  };

  void add(String rule, String message, {String? caseId, String? missionId}) =>
      out.add(ContentIssue(s.id, rule, message, caseId: caseId, missionId: missionId));

  void run() {
    _parseCases();
    _caseOrder();
    final missionIds = <String>{};
    final evidenceIds = <String, String>{};
    final clueIds = <String>{};
    for (final e in cases) {
      _missions(e);
      for (final m in e.allMissions) {
        if (!missionIds.add(m.id)) add('mission', 'mission id used twice in the season', caseId: e.id, missionId: m.id);
        if (m.clue case final c? when !clueIds.add(c.id)) add('mission', 'clue id ${c.id} used twice', caseId: e.id, missionId: m.id);
        if (m.evidence case final v?) {
          if (evidenceIds.containsKey(v.id)) add('mission', 'evidence id ${v.id} used twice', caseId: e.id, missionId: m.id);
          evidenceIds[v.id] = e.id;
        }
      }
    }
    _references(missionIds, evidenceIds);
    _hintsAtEveryLevel();
    _levels();
    for (final p in _guard('place', () => ScenePlaceCheck.problemsOf(s))) {
      add('place', p);
    }
    // Each mission's engines, as its page chooses them.
    try {
      out.addAll(PuzzleEngineCollisionCheck.problemsOf(s, policy: engines));
    } catch (e) {
      add('engine', 'the engine check could not finish: $e');
    }
  }

  /// [check]'s problems, or the reason it could not finish.
  List<String> _guard(String what, List<String> Function() check) {
    try {
      return check();
    } catch (e) {
      return ['the $what check could not finish: $e'];
    }
  }

  // ── Cases ────────────────────────────────────────────────────────────

  void _parseCases() {
    for (final MapEntry(key: id, value: json) in SeasonContentValidator._cases(s).entries) {
      if (json['id'] != id) add('case', 'registered as $id, but its id is ${json['id']}', caseId: id);
      final Episode e;
      try {
        e = Episode.fromJson({...json, 'seasonId': s.id});
      } catch (err) {
        add('case', 'does not parse: $err', caseId: id);
        continue;
      }
      registered[id] = e;
      // The game reads a case in its season as it is written (a case that
      // names no season is the first season's).
      if (s.episodes.containsKey(id)) {
        final named = json['seasonId'] is String ? json['seasonId'] : null;
        final own = Episode.fromJson(json).seasonId;
        if (own != s.id) add('case', 'read as a case of ${named ?? '$own (it names no season)'}', caseId: id);
      }
    }
  }

  void _caseOrder() {
    final info = s.season;
    final order = s.episodes.keys.toList();
    final numbers = <int>{};
    for (final MapEntry(key: id, value: e) in registered.entries) {
      if (s.episodes.containsKey(id)) {
        // The game opens each case after the one before it and counts what
        // is still to come from how many are in: Case 01 to n, in order.
        final at = order.indexOf(id) + 1;
        if (e.number != at) add('case', 'Case ${e.numberLabel} is case $at of the season', caseId: id);
        numbers.add(e.number);
      } else {
        if (!numbers.add(e.number)) add('case', 'awaiting its pictures as Case ${e.numberLabel}, a number taken', caseId: id);
        if (e.number <= order.length) add('case', 'awaiting its pictures as Case ${e.numberLabel}, among the cases in the game', caseId: id);
      }
    }
    final planned = info.plannedCases;
    final written = SeasonContentValidator._cases(s).length;
    if (planned != null && written > planned) add('progress', '$written cases written for $planned planned');
    // Coming soon: titles of cases planned but not in the game yet.
    for (final n in info.upcomingTitles.keys) {
      if (n <= order.length || (planned != null && n > planned)) {
        add('progress', 'upcoming title for Case $n, not a case still to come (${order.length} in, ${planned ?? '?'} planned)');
      }
    }
    final ids = registered.keys.toSet();
    for (final f in info.figures) {
      if (!ids.contains(f.afterCase)) add('reference', 'a figure after ${f.afterCase}, not a case of the season');
    }
  }

  // ── Missions ─────────────────────────────────────────────────────────

  void _missions(Episode e) {
    final all = e.allMissions;
    final index = {for (final (i, m) in all.indexed) m.id: i};
    for (final (i, m) in all.indexed) {
      void bad(String rule, String message) => add(rule, message, caseId: e.id, missionId: m.id);
      if (m.id.trim().isEmpty || m.id.contains(' ')) bad('mission', 'not a mission id');
      // A mission named after another case was copied and not renamed.
      for (final c in _caseIdsEverywhere) {
        if (c != e.id && m.id.startsWith('${c}_')) bad('mission', 'named as a mission of $c');
      }
      if (m.number != i + 1) bad('mission', 'M${m.number} is mission ${i + 1} of the case');
      // The game plays a case's missions in order, the final last; the story
      // after a mission goes on to its nextMissionId: the same one.
      final next = i + 1 < all.length ? all[i + 1].id : null;
      if (m.nextMissionId != next) {
        bad('mission', switch (m.nextMissionId) {
          null => 'leads nowhere: the next mission is $next',
          final n when !index.containsKey(n) => 'leads to $n, not a mission of the case',
          final n when index[n]! <= i => 'leads back to $n: a loop',
          final n when next == null => 'the final leads on to $n',
          final n => 'leads to $n, skipping $next',
        });
      }
      if (m.isFinal != (i == all.length - 1)) {
        bad('mission', m.isFinal ? 'closes the case before its final' : 'the final does not close the case');
      }
      if (m.hints.isEmpty || m.hints.length > AppConstants.maxHints) bad('hint', '${m.hints.length} hints (1 to ${AppConstants.maxHints})');
      if (m.evidence == null) bad('mission', 'no evidence');
      if (!m.isFinal && m.clue == null) bad('mission', 'no clue for the notebook');
      if (m.mapX < 0 || m.mapX > 1 || m.mapY < 0 || m.mapY > 1) bad('mission', 'its map pin is off the map');
      for (final p in _answerProblems(m)) {
        bad('answer', p);
      }
    }
  }

  /// What is wrong with [m]'s answer for its type.
  static List<String> _answerProblems(Mission m) {
    final out = <String>[];
    final options = [for (final o in m.options) o.id];
    final ids = options.toSet();
    if (ids.length != options.length) out.add('an option id used twice');
    if (options.any((o) => o.trim().isEmpty)) out.add('an option with no id');
    if (m.answer.trim().isEmpty) return [...out, 'no answer'];
    if (!AnswerChecker.isCorrect(m, m.answer)) out.add('its own answer is not judged right');
    if (AnswerChecker.isCorrect(m, '')) out.add('nothing is judged right');
    switch (m.type) {
      case MissionType.multipleChoice || MissionType.imageChoice || MissionType.canvasChoice:
        if (!ids.contains(m.answer)) out.add('answer ${m.answer} is not an option');
        if (ids.length < 3) out.add('${ids.length} options: a guess, not a choice');
        if (m.type == MissionType.imageChoice && m.options.any((o) => o.artwork == null)) out.add('an option with no picture');
      case MissionType.sequence:
        final order = Mission.sequenceIds(m.answer);
        if (!ids.containsAll(order)) out.add('its order names ${order.toSet().difference(ids)}, not options');
        if (m.codeLength != null && order.length != m.codeLength) out.add('${order.length} steps for ${m.codeLength}');
      case MissionType.spotDifferences || MissionType.revealLayer:
        final found = Mission.sequenceIds(m.answer);
        if (!ids.containsAll(found)) out.add('it names ${found.toSet().difference(ids)}, not options');
        if (found.toSet().length != found.length) out.add('a part named twice');
      case MissionType.matchPairs:
        // Pairs of one side's option and the other's mark (`note:picture`):
        // the options are the left of every pair, or the right.
        final pairs = [for (final p in Mission.sequenceIds(m.answer)) p.split(':')];
        if (pairs.any((p) => p.length != 2 || p.any((x) => x.trim().isEmpty))) {
          out.add('not pairs (a:b, joined by commas)');
        } else if (!pairs.every((p) => ids.contains(p[0])) && !pairs.every((p) => p[1].split('+').every(ids.contains))) {
          out.add('its pairs name no option on either side');
        }
        if (pairs.map((p) => p.join(':')).toSet().length != pairs.length) out.add('a pair named twice');
      case MissionType.letterLock:
        // A slot for each tile; the tiles' letters spell the word.
        final letters = (AnswerChecker.normalize(m.answer).split('')..sort()).join();
        final tiles = ([for (final o in m.options) ...AnswerChecker.normalize(o.label).split('')]..sort()).join();
        if (letters != tiles) out.add('its tiles (${m.options.map((o) => o.label).join()}) do not spell ${m.answer}');
      case MissionType.wordInput || MissionType.numberCode || MissionType.finalCode || MissionType.examine:
        if (m.codeLength != null && m.answer.length != m.codeLength) out.add('answer ${m.answer} is not ${m.codeLength} long');
        if (m.type == MissionType.numberCode && !RegExp(r'^\d+$').hasMatch(m.answer)) out.add('a number code that is not a number');
    }
    // A line for a wrong answer is never for a right one.
    for (final wrong in m.feedback.keys) {
      if (AnswerChecker.isCorrect(m, wrong)) out.add('a wrong-answer line for "$wrong", which is right');
    }
    return out;
  }

  // ── References ───────────────────────────────────────────────────────

  void _references(Set<String> missionIds, Map<String, String> evidenceIds) {
    final caseIds = {for (final c in SeasonContentValidator._cases(s).keys) c};
    // Every table names what the season has: a missing one is never read.
    s.missionTables.forEach((table, entries) {
      for (final id in entries.keys) {
        if (!missionIds.contains(id)) add('reference', '$table/$id: not a mission of the season');
      }
    });
    for (final id in s.storyEvidence) {
      if (!missionIds.contains(id)) add('reference', 'storyEvidence/$id: not a mission of the season');
    }
    for (final (table, keys) in [
      ('introPictures', s.introPictures.keys),
      ('introPlaques', s.introPlaques.keys),
      ('introPapers', s.introPapers.keys),
      ('languageTopics', s.languageTopics.keys),
      ('writtenLevels', s.writtenLevels.keys),
    ]) {
      for (final id in keys) {
        if (!caseIds.contains(id)) add('reference', '$table/$id: not a case of the season');
      }
    }
    for (final id in s.evidenceArt.keys) {
      if (!evidenceIds.containsKey(id)) add('reference', 'evidenceArt/$id: not evidence of the season');
    }
    // A piece of evidence is matched to one of its own case or of a case
    // before it (Paris: each case's first piece to the case before).
    final caseOrder = {for (final (i, e) in cases.indexed) e.id: i};
    s.evidenceLinks.forEach((id, link) {
      final (from, to) = (caseOrder[evidenceIds[id]], caseOrder[evidenceIds[link.to]]);
      if (from == null) {
        add('reference', 'evidenceLinks/$id: not evidence of the season');
      } else if (to == null || to > from) {
        add('reference', 'evidenceLinks/$id: matched to ${link.to}, not evidence of its case or one before', caseId: evidenceIds[id]);
      }
    });
    // What a mission recalls was found before it: evidence of an earlier
    // mission (a recall), or an earlier mission's words (a learning design).
    final before = <String>{};
    final found = <String>{};
    for (final e in cases) {
      for (final m in e.allMissions) {
        if (m.recall case final r? when !found.contains(r.evidenceId)) {
          add('reference', 'recalls ${r.evidenceId}, not evidence found before it', caseId: e.id, missionId: m.id);
        }
        if (s.learning[m.id]?.recallFrom case final from? when !before.contains(from)) {
          add('reference', 'learning recalls $from, not a mission played before it', caseId: e.id, missionId: m.id);
        }
        before.add(m.id);
        if (m.evidence case final v?) found.add(v.id);
      }
    }
  }

  // ── Levels ───────────────────────────────────────────────────────────

  /// No hint gives the answer away, at any level (each has its own hints).
  void _hintsAtEveryLevel() {
    for (final e in cases) {
      for (final level in Difficulty.values) {
        final Episode played;
        try {
          played = DifficultyContent.episodeAt(e, level, patches: s.casePatches);
        } catch (err) {
          add('difficulty', '${level.storageId}: its words do not lay on: $err', caseId: e.id);
          continue;
        }
        for (final m in played.allMissions) {
          final answer = switch (m.type) {
            MissionType.multipleChoice || MissionType.imageChoice || MissionType.canvasChoice => m.answerLabel,
            MissionType.wordInput || MissionType.numberCode || MissionType.finalCode || MissionType.letterLock => m.answer,
            _ => null,
          };
          // Too short to tell (a digit, "UP"): found inside any word.
          if (answer == null || AnswerChecker.normalize(answer).length < 3) continue;
          for (final h in m.hints) {
            if (AnswerChecker.normalize(h).contains(AnswerChecker.normalize(answer))) {
              add('hint', '${level.storageId}: "$h" gives away "$answer"', caseId: e.id, missionId: m.id);
            }
          }
        }
      }
    }
  }

  /// The levels' words (what they may change, laid on unchanged in
  /// structure), and every word of a level a case is marked written at.
  void _levels() {
    for (final p in _guard('level', () => DifficultyContent.problemsOf(s))) {
      add('difficulty', p);
    }
    s.writtenLevels.forEach((caseId, levels) {
      for (final level in levels) {
        for (final p in _guard('level', () => DifficultyContent.missingAt(caseId, level, season: s))) {
          add('difficulty', '${level.storageId}: marked written, falls back for $p', caseId: caseId);
        }
      }
    });
  }
}
