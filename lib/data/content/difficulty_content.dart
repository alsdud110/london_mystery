import '../mock/season2/season2_structures.dart';
import '../mock/season_catalog.dart';
import '../models/clock_puzzle.dart';
import '../models/difficulty.dart';
import '../models/discovery.dart';
import '../models/episode.dart';
import '../models/investigation.dart';
import '../models/learning.dart';
import '../models/mission.dart';
import '../models/scene_decode.dart';
import '../models/scene_deduction.dart';
import '../models/scene_explore.dart';
import '../models/scene_inspect.dart';

/// The words of the game at each level (Rookie, Junior, Master).
///
/// The game's own words — the cases as written — are the base, and the base
/// is Rookie's. A level gives its own words through its season's content:
///
/// * a case's JSON, field by field ([SeasonContent.casePatches]): only its
///   text — never an id, an answer, an order or a picture ([caseText],
///   [missionText]);
/// * the puzzles' own tables, object by object ([SeasonContent.variants]),
///   read through `SeasonCatalog` at the mission's level.
///
/// A level without its own words for something falls back
/// ([Difficulty.fallbackChain]): Master on Junior's, then the base; Junior
/// and Rookie on the base. Nothing is ever missing for the player — and
/// nothing hides either: [problems] finds what may not change, [missingAt]
/// what a level marked written has left to the fallback.
///
/// Pure functions of the content: no level is held here. Each game session
/// builds its own cases at its own seasons' levels (`playedEpisodesProvider`).
abstract final class DifficultyContent {
  /// A case's own text, as a level may give it: whole values.
  static const caseText = {'title', 'synopsis', 'objectives', 'intro', 'caseSummary', 'keyWords', 'hook', 'place'};

  /// A case's glossary: words a level adds (or explains its own way).
  static const caseGlossary = 'glossary';

  /// A mission's own text, as a level may give it: whole values, a list
  /// (story, hints, transition) as a whole. Hints keep their number.
  static const missionText = {
    'title',
    'location',
    'story',
    'letterIntro',
    'letter',
    'question',
    'prompt',
    'hints',
    'successMessage',
    'transition',
    'orderFeedback',
  };

  /// Parts of a mission given by key, each with its text fields: options by
  /// option id; the wrong-answer lines by the wrong answer they are for (the
  /// keys are answers and never change); the clue, evidence and recall's
  /// words (their ids, values, inscriptions and pictures never); a recall's
  /// lines for wrong evidence by evidence id (`recall.feedback`, PART 7C).
  static const missionParts = {
    'options': {'label', 'feedback', 'altText'},
    'feedback': <String>{},
    'clue': {'title', 'note'},
    'evidence': {'name', 'description'},
    'recall': {'title', 'prompt', 'miss'},
  };

  /// [base] (a case's JSON) with [level]'s words: the patches of
  /// [level]'s fallback chain laid over it, the nearest last, field by
  /// field. Anything a patch may not change is left as it is (and reported
  /// by [problems]). [base] itself is never changed.
  static Map<String, dynamic> apply(
    Map<String, dynamic> base,
    Difficulty level,
    Map<Difficulty, Map<String, Map<String, Object?>>> patches,
  ) {
    var json = _copy(base) as Map<String, dynamic>;
    for (final l in level.fallbackChain.reversed) {
      final patch = patches[l]?[base['id']];
      if (patch != null) json = _applyCase(json, patch);
    }
    return json;
  }

  /// Case [base] as played at [level] (its season's patches unless
  /// [patches] are given): a case whose missions carry [level], so their
  /// puzzle tables are read at it too.
  static Episode episodeAt(
    Episode base,
    Difficulty level, {
    Map<Difficulty, Map<String, Map<String, Object?>>>? patches,
  }) {
    final own = patches ?? SeasonCatalog.byId(base.seasonId)?.casePatches ?? const {};
    return Episode.fromJson(apply(base.toJson(), level, own), difficulty: level);
  }

  static Object? _copy(Object? v) => switch (v) {
        final Map<dynamic, dynamic> m => <String, dynamic>{for (final e in m.entries) '${e.key}': _copy(e.value)},
        final List<dynamic> l => [for (final x in l) _copy(x)],
        _ => v,
      };

  static Map<String, dynamic> _applyCase(Map<String, dynamic> json, Map<String, Object?> patch) {
    for (final MapEntry(:key, :value) in patch.entries) {
      if (caseText.contains(key) && _sameShape(json[key], value, optional: true)) {
        json[key] = _copy(value);
      } else if (key == caseGlossary && value is Map) {
        json[key] = {...(json[key] as Map? ?? const {}), for (final e in value.entries) '${e.key}'.toLowerCase(): '${e.value}'};
      } else if (key == 'missions' && value is Map) {
        for (final MapEntry(key: id, value: m) in value.entries) {
          final mission = _missionJson(json, '$id');
          if (mission != null && m is Map) _applyMission(mission, m);
        }
      }
    }
    return json;
  }

  static Map<String, dynamic>? _missionJson(Map<String, dynamic> episode, String id) {
    for (final m in [...episode['missions'] as List, episode['finalMission']]) {
      if (m is Map<String, dynamic> && m['id'] == id) return m;
    }
    return null;
  }

  static void _applyMission(Map<String, dynamic> mission, Map<dynamic, dynamic> patch) {
    for (final MapEntry(key: k, :value) in patch.entries) {
      final key = '$k';
      if (missionText.contains(key)) {
        if (!_sameShape(mission[key], value, optional: key == 'prompt' || key == 'orderFeedback')) continue;
        // Hints keep their number (and their prices, and what was opened).
        if (key == 'hints' && (value as List).length != (mission[key] as List).length) continue;
        mission[key] = _copy(value);
      } else if (key == 'options' && value is Map) {
        for (final o in mission['options'] as List? ?? const []) {
          final words = value[(o as Map)['id']];
          if (words is Map) _applyFields(o as Map<String, dynamic>, words, missionParts['options']!);
        }
      } else if (key == 'feedback' && value is Map && mission['feedback'] is Map) {
        final lines = mission['feedback'] as Map<String, dynamic>;
        for (final e in value.entries) {
          if (lines.containsKey('${e.key}') && e.value is String) lines['${e.key}'] = e.value;
        }
      } else if (missionParts.containsKey(key) && value is Map && mission[key] is Map) {
        _applyFields(mission[key] as Map<String, dynamic>, value, missionParts[key]!);
        // A recall's lines for the wrong pieces of evidence, by evidence id
        // (the ids are the base's and never change).
        if (key == 'recall' && value['feedback'] is Map && mission[key]['feedback'] is Map) {
          final lines = mission[key]['feedback'] as Map<String, dynamic>;
          for (final e in (value['feedback'] as Map).entries) {
            if (lines.containsKey('${e.key}') && e.value is String) lines['${e.key}'] = e.value;
          }
        }
      }
    }
  }

  static void _applyFields(Map<String, dynamic> part, Map<dynamic, dynamic> words, Set<String> allowed) {
    for (final e in words.entries) {
      if (allowed.contains('${e.key}') && e.value is String) part['${e.key}'] = e.value;
    }
  }

  /// A level's value may replace the base's only as the same kind of value
  /// (a line for a line, lines for lines).
  static bool _sameShape(Object? base, Object? value, {bool optional = false}) => switch (value) {
        final String _ => base is String || (optional && base == null),
        final List<dynamic> l => base is List && l.every((x) => x is String),
        _ => false,
      };

  // ── Checks ───────────────────────────────────────────────────────────

  /// Everything wrong with the levels' words of every season (empty: all
  /// good): a patch reaching what may not change (an id, an answer, an
  /// order, a structure field), a case or mission that does not exist, hints
  /// not as many as the base's, a puzzle table entry of another kind than
  /// the base's or with another structure, and — after the words are laid —
  /// any case whose structure differs from the base's at any level.
  static List<String> problems({Iterable<SeasonContent>? seasons}) => [
        for (final s in seasons ?? SeasonCatalog.all) ...problemsOf(s),
      ];

  static List<String> problemsOf(SeasonContent season) {
    final out = <String>[];
    final cases = {...season.episodes, ...season.awaitingArt};
    season.casePatches.forEach((level, byCase) {
      byCase.forEach((caseId, patch) {
        final at = '${season.id} ${level.storageId} $caseId';
        final base = cases[caseId];
        if (base == null) {
          out.add('$at: no such case');
          return;
        }
        for (final MapEntry(:key, :value) in patch.entries) {
          if (caseText.contains(key)) {
            if (!_sameShape(base[key], value, optional: true)) out.add('$at.$key: not text of the same kind as the base');
          } else if (key == caseGlossary) {
            if (value is! Map) out.add('$at.glossary: not a word list');
          } else if (key == 'missions' && value is Map) {
            value.forEach((id, m) => out.addAll(_missionProblems('$at/$id', _missionJson(base, '$id'), m)));
          } else {
            out.add('$at.$key: may not change with the level');
          }
        }
      });
    });
    // Puzzle tables: an entry only where the base has one, of its kind and
    // structure.
    season.variants.forEach((level, variant) {
      final bases = season.missionTables;
      variant.missionTables.forEach((table, entries) {
        entries.forEach((id, entry) {
          final at = '${season.id} ${level.storageId} $table/$id';
          final base = bases[table]?[id];
          if (base == null) {
            out.add('$at: the base has no such entry');
          } else if (entry.runtimeType != base.runtimeType) {
            out.add('$at: a ${entry.runtimeType} for a ${base.runtimeType}');
          } else {
            final (shape, baseShape) = (structureOf(entry), structureOf(base));
            if (shape == null) {
              out.add('$at: no structure check for ${entry.runtimeType} (add one to DifficultyContent.structureOf)');
            } else if (shape != baseShape) {
              out.add('$at: its structure differs from the base ($shape ≠ $baseShape)');
            }
          }
        });
      });
    });
    // Laid on: the same structure at every level.
    for (final json in season.episodes.values) {
      final base = Episode.fromJson({...json, 'seasonId': season.id});
      final want = structureOfEpisode(base);
      for (final level in Difficulty.values) {
        final got = structureOfEpisode(episodeAt(base, level, patches: season.casePatches));
        if (got != want) out.add('${season.id} ${level.storageId} ${base.id}: the case changed beyond its words');
      }
    }
    return out;
  }

  static List<String> _missionProblems(String at, Map<String, dynamic>? base, Object? patch) {
    if (base == null) return ['$at: no such mission'];
    if (patch is! Map) return ['$at: not a mission patch'];
    final out = <String>[];
    patch.forEach((k, value) {
      final key = '$k';
      if (missionText.contains(key)) {
        if (!_sameShape(base[key], value, optional: key == 'prompt' || key == 'orderFeedback')) {
          out.add('$at.$key: not text of the same kind as the base');
        } else if (key == 'hints' && (value as List).length != (base[key] as List).length) {
          out.add('$at.hints: ${value.length} hints for the base\'s ${(base[key] as List).length}');
        }
      } else if (key == 'options' && value is Map) {
        final ids = {for (final o in base['options'] as List? ?? const []) (o as Map)['id']};
        value.forEach((id, words) {
          if (!ids.contains(id)) out.add('$at.options.$id: no such option');
          out.addAll(_fieldProblems('$at.options.$id', words, missionParts['options']!));
        });
      } else if (key == 'feedback' && value is Map) {
        final keys = (base['feedback'] as Map? ?? const {}).keys.toSet();
        for (final answer in value.keys) {
          if (!keys.contains(answer)) out.add('$at.feedback: "$answer" is not a wrong answer the base has a line for');
        }
      } else if (key == 'recall' && value is Map && value['feedback'] is Map) {
        // Its wrong-evidence lines: only for the evidence the base has a line for.
        final keys = ((base[key] as Map?)?['feedback'] as Map? ?? const {}).keys.toSet();
        for (final id in (value['feedback'] as Map).keys) {
          if (!keys.contains(id)) out.add('$at.recall.feedback: "$id" is not evidence the base has a line for');
        }
        out.addAll(_fieldProblems('$at.$key', {...value}..remove('feedback'), missionParts[key]!));
      } else if (missionParts.containsKey(key) && value is Map) {
        if (base[key] is! Map) out.add('$at.$key: the base has none');
        out.addAll(_fieldProblems('$at.$key', value, missionParts[key]!));
      } else {
        out.add('$at.$key: may not change with the level');
      }
    });
    return out;
  }

  static List<String> _fieldProblems(String at, Object? words, Set<String> allowed) => [
        if (words is! Map) '$at: not a set of words'
        else
          for (final e in words.entries)
            if (!allowed.contains('${e.key}'))
              '$at.${e.key}: may not change with the level'
            else if (e.value is! String)
              '$at.${e.key}: not a line',
      ];

  /// What a case is beyond its words: what no level may change.
  static String structureOfEpisode(Episode e) => [
        e.id,
        e.seasonId,
        e.number,
        e.introScene?.name,
        for (final m in e.allMissions) structureOfMission(m),
      ].join('|');

  static String structureOfMission(Mission m) => [
        m.id,
        m.number,
        m.type.name,
        m.place.key,
        m.answer,
        m.acceptedAnswers.join(','),
        m.codeLength,
        m.codeFormat,
        m.dialSymbols.join(','),
        m.options.map((o) => '${o.id}:${o.artwork?.name}').join(','),
        m.hints.length,
        m.clue == null ? null : '${m.clue!.id}:${m.clue!.value}:${m.clue!.symbol}',
        m.evidence == null
            ? null
            : '${m.evidence!.id}:${m.evidence!.icon}:${m.evidence!.inscription}:${m.evidence!.symbols.join(',')}',
        m.nextMissionId,
        m.skills.map((s) => s.name).join(','),
        m.mapX,
        m.mapY,
        m.feedback.keys.join(','),
        m.hideOptionNames,
        m.recall?.evidenceId,
        m.recall?.feedback.keys.join(','),
        m.finale,
      ].join('~');

  /// What a puzzle table's entry is beyond its words (its pictures, its
  /// answer, its steps and choices in order), for the kinds whose levels
  /// have words written; null for a kind not known here yet — a level's
  /// entry of that kind is then reported, never trusted (PART 6–7 add each
  /// kind they write words for). Season 2's scenes: [season2StructureOf].
  static String? structureOf(Object? entry) => season2StructureOf(entry) ?? switch (entry) {
        final ClockPuzzle c => '${c.face.name}:${c.start.hour}:${c.start.minute}',
        final Discovery d => '${d.type.name}:${d.timing.name}:${d.showEvidence}:${d.seasonClue}',
        final LearningObjective l => '${l.dependency.name}:${l.level.name}:${l.skill?.name}:${l.recallFrom}',
        // London Case 01 and 03's scenes (PART 6A): pictures, places, ids
        // and what each needs or confirms — every word may differ.
        final ExploreScene s => [
            s.picture, s.pixels.width, s.pixels.height, s.guideAt, s.inside, s.opening, s.pictureAspect,
            for (final p in s.spots) '${p.id}:${p.kind.name}:${p.areas}:${p.mark}:${p.requires}',
            for (final o in s.others) '${o.areas}',
            for (final c in s.choices) '${c.optionId}:${c.picture}',
          ].join('|'),
        final InspectScene s => [
            s.picture, s.pixels.width, s.pixels.height, s.inside, s.lensAt, s.labelRoom, s.taskLine,
            for (final p in s.spots) '${p.id}:${p.kind.name}:${p.areas}:${p.checks.toList()..sort()}:${p.requires}',
          ].join('|'),
        final DeductionScene s => [
            s.picture, s.pixels.width, s.pixels.height, s.guideAt, s.inside, s.opening,
            for (final c in s.clues) '${c.id}:${c.areas}:${c.mark}',
            for (final o in s.others) '${o.areas}',
            for (final p in s.places) '${p.optionId}:${p.areas}:${p.mark}',
          ].join('|'),
        final DecodeScene s => [
            s.picture, s.pixels.width, s.pixels.height, s.areas, s.mark, s.closer, s.code, s.cleared,
            s.clearedArea, s.revealed, s.ink, s.messageTilt, s.inside,
          ].join('|'),
        final InvestigationScene s => [
            s.artwork.name, s.answer, s.guideAt, s.opening, s.inside,
            for (final f in s.finds)
              '${f.id}:${f.areas}:${f.picture}:${f.at}:${f.width}:${f.pictureAspect}:${f.squash}:${f.turn}',
            for (final o in s.spots) '${o.areas}',
          ].join('|'),
        _ => null,
      };

  // ── Coverage ─────────────────────────────────────────────────────────

  /// Puzzle tables that hold pictures only (nothing to write at a level).
  static const pictureTables = {'storyScenes', 'lockBoxes'};

  /// What case [caseId] still lacks at [level] to count as written there:
  /// every text of the case with no words of [level]'s own (falling back to
  /// another level's or the base's does not count), each as `mission.field`
  /// or `table/mission`. Rookie: nothing (the base is Rookie's words).
  /// [season]: the case's own (found in `SeasonCatalog` when not given).
  static List<String> missingAt(String caseId, Difficulty level, {SeasonContent? season}) {
    if (level == Difficulty.rookie) return const [];
    season ??= SeasonCatalog.ofEpisode(caseId);
    final json = season?.episodes[caseId];
    if (season == null || json == null) return ['$caseId: no such case'];
    final patch = season.casePatches[level]?[caseId] ?? const {};
    final missions = patch['missions'] is Map ? patch['missions'] as Map : const {};
    final variant = season.variants[level];
    final out = <String>[
      for (final key in const ['intro', 'synopsis'])
        if (_hasText(json[key]) && !patch.containsKey(key)) '$caseId.$key',
    ];
    final base = Episode.fromJson({...json, 'seasonId': season.id});
    for (final m in base.allMissions) {
      final own = missions[m.id] is Map ? missions[m.id] as Map : const {};
      final mj = m.toJson();
      for (final key in const ['story', 'letterIntro', 'letter', 'question', 'prompt', 'hints', 'successMessage', 'transition']) {
        if (_hasText(mj[key]) && !own.containsKey(key)) out.add('${m.id}.$key');
      }
      season.missionTables.forEach((table, entries) {
        if (pictureTables.contains(table) || !entries.containsKey(m.id)) return;
        if (variant?.missionTables[table]?.containsKey(m.id) != true) out.add('$table/${m.id}');
      });
    }
    return out;
  }

  static bool _hasText(Object? v) => switch (v) {
        final String s => s.trim().isNotEmpty,
        final List<dynamic> l => l.isNotEmpty,
        _ => false,
      };
}
