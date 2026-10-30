import 'dart:convert';
import 'dart:io';

import 'json_schema_lite.dart' show SchemaSet;
import 'plan_files.dart';
import 'plan_models.dart';
import 'play_check.dart';
import 'season_cases.dart';
import 'validate_plan.dart' show checkJson;

/// A case's words at each level (Rookie, Junior, Master): its
/// `cases/<caseId>/levels.json`, beside its plan.
///
/// The plan is the game, and its words are Rookie's. A level is the same
/// game read in other English: every line the player reads (story, talk,
/// question, choice, hint, clue and scene line) given again, and nothing
/// else — never an id, an answer, an order, a choice more or less, a
/// picture, a place on one or a step of a puzzle. So a level is only a
/// list of lines: each of the plan's Rookie lines, and what Junior and
/// Master say instead.
///
///     {
///       "schemaVersion": 1,
///       "caseId": "s3_ep01",
///       "lines": [
///         {"rookie": "Who took it?", "junior": "…", "master": "…"}
///       ],
///       "glossary": {"junior": {"word": "뜻"}, "master": {"word": "뜻"}}
///     }
///
/// The same Rookie line is the same line at a level wherever it is, so a
/// line the plan repeats (a question asked of each witness, an expression
/// that must be in the mission's English) stays repeated. A level plan is
/// the plan with its lines given again ([apply]); it is checked as the
/// plan is (`validate_plan`, `PlayCheck`) and must be the same game beyond
/// its words ([problems]), then made by the same generator
/// (`generate_case.dart`, `<caseId>_levels.g.dart`).
///
///     dart run tool/season_gen/case_levels.dart skeleton (<case.plan.json> | <season.plan.json>)...
///     dart run tool/season_gen/case_levels.dart check --season <season.plan.json> [<case.plan.json>...]
///     dart run tool/season_gen/case_levels.dart review (<case.plan.json> | <season.plan.json>)...
///
/// No case given to `check`, or a season plan given to `review`: every
/// case of the season ([SeasonCases.of]), found by the tool itself, so no
/// shell has to spread a `cases/*/` pattern (PowerShell does not).
///
/// The season's own lines (its outro and finale): `season.levels.json`
/// beside its plan ([SeasonLevels]), checked with every `check`.
///
/// `skeleton`: writes `levels.json` with a line for every Rookie line the
/// plan has (the lines already written kept; lines the plan no longer has
/// dropped), Junior's and Master's empty where not written yet.
/// `check`: every finding, a line each; exit 1 when there is one. Besides
/// what the generator holds a level to ([checkCase]), a level that gives
/// most of its sentences back as Rookie's is copied, not written
/// ([copied]).
/// `review`: each mission's lines a player reads to solve it (question,
/// choices with the answer marked, hints, clue, evidence, a line holding a
/// typed answer) at Rookie, Junior and Master, one under another, for a
/// person (or Claude) to read: the checks hold the answers' words, not
/// their meaning.
void main(List<String> args) {
  if (args.isEmpty) return _usage();
  switch (args.first) {
    case 'skeleton':
      for (final path in args.skip(1)) {
        final season = path.endsWith('season.plan.json');
        final n = season ? SeasonLevels.writeSkeleton(path) : CaseLevels.writeSkeleton(path);
        stdout.writeln('levels   ${season ? SeasonLevels.pathFor(path) : CaseLevels.pathFor(path)}: ${n.$1} lines, ${n.$2} still to write');
      }
    case 'check':
      final i = args.indexOf('--season');
      if (i < 0 || i + 1 >= args.length) return _usage();
      final season = PlanFiles.loadSeasonPlan(args[i + 1]);
      final schemas = SchemaSet.load('${File.fromUri(Platform.script).parent.path}/schema');
      final own = SeasonLevels.checkWritten(args[i + 1]);
      var failed = own.isNotEmpty;
      stdout.writeln(own.isEmpty ? 'ok       ${args[i + 1]}: the season\'s own lines at every level' : 'FAILED  ${args[i + 1]}');
      for (final f in own) {
        stdout.writeln('  error    $f');
      }
      final given = [for (final (j, a) in args.indexed) if (j > 0 && j != i && j != i + 1) a];
      for (final path in given.isEmpty ? SeasonCases.of(args[i + 1]) : given) {
        final found = CaseLevels.checkWritten(path, season, schemas);
        failed |= found.isNotEmpty;
        stdout.writeln(found.isEmpty ? 'ok       $path: every level written, the same game' : 'FAILED  $path');
        for (final f in found) {
          stdout.writeln('  error    $f');
        }
      }
      if (failed) exitCode = 1;
    case 'review':
      for (final path in [for (final a in args.skip(1)) ...a.endsWith('season.plan.json') ? SeasonCases.of(a) : [a]]) {
        final levels = CaseLevels.load(path);
        stdout.writeln('review   $path');
        for (final (at, rookie) in CaseLevels.keyLines(PlanFiles.readJson(path))) {
          stdout
            ..writeln('  $at')
            ..writeln('    R  $rookie')
            ..writeln('    J  ${levels?.lines[rookie]?[PlanLevel.junior] ?? ''}')
            ..writeln('    M  ${levels?.lines[rookie]?[PlanLevel.master] ?? ''}');
        }
      }
    default:
      _usage();
  }
}

void _usage() {
  stderr.writeln('usage: dart run tool/season_gen/case_levels.dart (skeleton <case.plan.json>... | '
      'check --season <season.plan.json> [<case.plan.json>...] | review (<case.plan.json> | <season.plan.json>)...)');
  exitCode = 64;
}

/// The levels written beside the plan: Junior and Master (Rookie's words
/// are the plan's own).
enum PlanLevel { junior, master }

/// A season's own words at each level: `season.levels.json` beside its
/// plan, as a case's (`lines`: each Rookie line, Junior's and Master's),
/// for the lines the season shows itself — its [textKeys] (the words when
/// its last case is solved and on its completed board). Nothing else of
/// the season changes with the level.
class SeasonLevels {
  SeasonLevels({required this.seasonId, required this.lines});

  final String seasonId;
  final Map<String, Map<PlanLevel, String>> lines;

  static const fileName = 'season.levels.json';

  /// The season plan's lines shown to the player, by their `Season` key.
  static const textKeys = ['outro', 'finale'];

  static String pathFor(String seasonPlanPath) => '${File(seasonPlanPath).parent.path.replaceAll(r'\', '/')}/$fileName';

  /// Every Rookie line of season plan [json], each once.
  static List<String> rookieLines(Object? json) => {
    if (json is Map)
      for (final k in textKeys)
        for (final s in json[k] as List? ?? const []) '$s',
  }.toList();

  static SeasonLevels? load(String seasonPlanPath) {
    final path = pathFor(seasonPlanPath);
    if (!File(path).existsSync()) return null;
    final json = PlanFiles.readJson(path);
    if (json is! Map || json['schemaVersion'] != CaseLevels.schemaVersion || json['seasonId'] is! String) {
      throw PlanFormatException(path, '{"schemaVersion": ${CaseLevels.schemaVersion}, "seasonId", "lines"} expected');
    }
    final lines = CaseLevels.fromJson({...json, 'caseId': json['seasonId']}, path).lines;
    return SeasonLevels(seasonId: json['seasonId'] as String, lines: lines);
  }

  /// [level]'s lines of each of the season's [textKeys] it has (as many
  /// lines as the plan's, in their order).
  Map<String, List<String>> textAt(Object? seasonJson, PlanLevel level) => {
    if (seasonJson is Map)
      for (final k in textKeys)
        if ((seasonJson[k] as List? ?? const []).isNotEmpty) k: [for (final s in seasonJson[k] as List) lines['$s']?[level] ?? '$s'],
  };

  /// A line of the season not written at a level, or one written for no line.
  List<String> problems(Object? seasonJson) {
    final rookie = rookieLines(seasonJson);
    return [
      if (seasonJson is Map && seasonJson['seasonId'] != seasonId) '[levels_season] seasonId $seasonId: the plan is ${seasonJson['seasonId']}',
      for (final s in rookie)
        for (final level in PlanLevel.values)
          if ((lines[s]?[level] ?? '').trim().isEmpty) '[level_missing] ${level.name}: "${CaseLevels._short(s)}" is not written',
      for (final s in lines.keys)
        if (!rookie.contains(s)) '[level_stale] "${CaseLevels._short(s)}": no line of the season plan (run case_levels.dart skeleton)',
    ];
  }

  /// Every finding of the season's levels at [seasonPlanPath] (none when the
  /// season shows no line of its own).
  static List<String> check(String seasonPlanPath) {
    final json = PlanFiles.readJson(seasonPlanPath);
    final SeasonLevels? levels;
    try {
      levels = load(seasonPlanPath);
    } on PlanFormatException catch (e) {
      return ['[levels_format] ${e.path}: ${e.message}'];
    }
    if (levels == null) {
      return rookieLines(json).isEmpty ? const [] : ['[levels_missing] ${pathFor(seasonPlanPath)}: not written (run case_levels.dart skeleton)'];
    }
    return levels.problems(json);
  }

  /// [check]'s findings and, the lines all there, those a level copied
  /// from Rookie ([CaseLevels.copied]): what a season's own lines must pass
  /// to count as written (the factory's levels step, `case_levels.dart check`).
  static List<String> checkWritten(String seasonPlanPath) {
    final found = check(seasonPlanPath);
    if (found.isNotEmpty) return found;
    final levels = load(seasonPlanPath);
    return levels == null ? const [] : CaseLevels.copied(levels.lines, rookieLines(PlanFiles.readJson(seasonPlanPath)));
  }

  /// Writes the season's levels file: its lines written kept, the others empty.
  static (int, int) writeSkeleton(String seasonPlanPath) {
    final json = PlanFiles.readJson(seasonPlanPath) as Map;
    final had = load(seasonPlanPath);
    final rookie = rookieLines(json);
    final out = <String, Object?>{
      'schemaVersion': CaseLevels.schemaVersion,
      'seasonId': json['seasonId'],
      'lines': [
        for (final s in rookie) {'rookie': s, for (final l in PlanLevel.values) l.name: had?.lines[s]?[l] ?? ''},
      ],
    };
    File('${pathFor(seasonPlanPath)}.part')
      ..writeAsStringSync(PlanFiles.encode(out), flush: true)
      ..renameSync(pathFor(seasonPlanPath));
    final todo = rookie.where((s) => PlanLevel.values.any((l) => (had?.lines[s]?[l] ?? '').trim().isEmpty)).length;
    return (rookie.length, todo);
  }
}

/// A case's `levels.json`, read.
class CaseLevels {
  CaseLevels({required this.caseId, required this.lines, this.glossary = const {}});

  final String caseId;

  /// Rookie line → its words at each level.
  final Map<String, Map<PlanLevel, String>> lines;

  /// Words a level adds to the case's glossary (lower case → meaning).
  final Map<PlanLevel, Map<String, String>> glossary;

  static const fileName = 'levels.json';
  static const schemaVersion = 1;

  /// `cases/<caseId>/case.plan.json` → `cases/<caseId>/levels.json`.
  static String pathFor(String casePlanPath) => '${File(casePlanPath).parent.path.replaceAll(r'\', '/')}/$fileName';

  /// The levels beside [casePlanPath], or null when none are written.
  /// A [PlanFormatException] when the file is not a levels file.
  static CaseLevels? load(String casePlanPath) {
    final path = pathFor(casePlanPath);
    if (!File(path).existsSync()) return null;
    return fromJson(PlanFiles.readJson(path), path);
  }

  static CaseLevels fromJson(Object? json, String path) {
    PlanFormatException bad(String why) => PlanFormatException(path, why);
    if (json is! Map) throw bad('not an object');
    if (json['schemaVersion'] != schemaVersion) throw bad('schemaVersion: $schemaVersion expected');
    final caseId = json['caseId'];
    if (caseId is! String) throw bad('caseId: missing');
    final lines = <String, Map<PlanLevel, String>>{};
    for (final (i, l) in (json['lines'] as List? ?? const []).indexed) {
      if (l is! Map || l['rookie'] is! String) throw bad('lines[$i]: {"rookie", "junior", "master"} expected');
      final rookie = l['rookie'] as String;
      if (lines.containsKey(rookie)) throw bad('lines[$i]: "$rookie" given twice');
      lines[rookie] = {
        for (final level in PlanLevel.values)
          if (l[level.name] case final String s) level: s,
      };
    }
    final g = json['glossary'] is Map ? json['glossary'] as Map : const {};
    return CaseLevels(
      caseId: caseId,
      lines: lines,
      glossary: {
        for (final level in PlanLevel.values)
          if (g[level.name] is Map) level: {for (final e in (g[level.name] as Map).entries) '${e.key}'.toLowerCase(): '${e.value}'},
      },
    );
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'caseId': caseId,
    'lines': [
      for (final MapEntry(key: rookie, value: at) in lines.entries)
        {'rookie': rookie, for (final level in PlanLevel.values) level.name: at[level] ?? ''},
    ],
    'glossary': {for (final level in PlanLevel.values) level.name: glossary[level] ?? const <String, String>{}},
  };

  // ── Which of a plan's strings are its words ─────────────────────────────

  /// A case's own words (top level, and its `play`).
  static const _caseText = {'title', 'synopsis', 'hook'};
  static const _casePlayText = {'objectives', 'intro', 'caseSummary', 'place'};

  /// In a mission's `play`, every string is its words but these: ids,
  /// pictures, who says a line, what a puzzle is made of, and what other
  /// tables or matches read (a witness statement's `thing` is what two
  /// statements match by; an evidence's inscription and a clue's value are
  /// what puzzles read; the evidence link's line is read by its own table).
  static const _playNotText = {
    'id', 'by', 'speaker', 'portrait', 'picture', 'background', 'file', 'measuredOn', 'kind', 'requires', //
    'timing', 'type', 'optionId', 'topic', 'pair', 'then', 'evidence', 'thing', 'evidenceLinkLine',
    'inscription', 'value', 'symbol', 'icon', 'symbols',
  };

  /// A choice's words (`answerSpec.options[]`).
  static const _optionText = {'label', 'feedback', 'altText'};

  /// Every Rookie line of [plan] (its JSON), in order, each once.
  static List<String> rookieLines(Object? plan) {
    final out = <String>{};
    _visit(plan, (s) {
      out.add(s);
      return s;
    });
    return out.toList();
  }

  /// [plan] (its JSON) with each line [words] gives at a level; the others
  /// as they are. [plan] itself is never changed.
  static Object? applyWords(Object? plan, String? Function(String rookie) words) =>
      _visit(_copy(plan), (s) => words(s) ?? s);

  /// [plan] read at [level].
  Object? apply(Object? plan, PlanLevel level) => applyWords(plan, (s) {
    final w = lines[s]?[level];
    return w == null || w.trim().isEmpty ? null : w;
  });

  static Object? _copy(Object? v) => switch (v) {
    final Map<dynamic, dynamic> m => <String, Object?>{for (final e in m.entries) '${e.key}': _copy(e.value)},
    final List<dynamic> l => [for (final x in l) _copy(x)],
    _ => v,
  };

  /// Calls [f] on each of the words of a case plan's JSON, in order, and
  /// puts what it gives in their place (in [plan] itself).
  static Object? _visit(Object? plan, String Function(String) f) {
    if (plan is! Map) return plan;
    String text(Object? v) => f(v as String);
    void strings(Map<dynamic, dynamic> m, String key) {
      final v = m[key];
      if (v is String) m[key] = text(v);
      if (v is List) {
        for (var i = 0; i < v.length; i++) {
          if (v[i] is String) v[i] = text(v[i]);
        }
      }
    }

    for (final k in _caseText) {
      strings(plan, k);
    }
    if (plan['play'] is Map) {
      for (final k in _casePlayText) {
        strings(plan['play'] as Map, k);
      }
    }
    for (final m in [...plan['missions'] as List? ?? const [], plan['final']]) {
      if (m is! Map) continue;
      final options = ((m['puzzle'] as Map?)?['answerSpec'] as Map?)?['options'];
      for (final o in options is List ? options : const []) {
        if (o is Map) {
          for (final k in _optionText) {
            strings(o, k);
          }
        }
      }
      if (m['learning'] is Map) strings(m['learning'] as Map, 'expressions');
      if (m['play'] is Map) _play(m['play'] as Map, text);
    }
    return plan;
  }

  /// Every string of a mission's `play` but [_playNotText]'s; a `feedback`
  /// map's lines (its keys are answers, or evidence ids: never words).
  static void _play(Map<dynamic, dynamic> node, String Function(Object?) text) {
    for (final key in node.keys.toList()) {
      final v = node[key];
      if (v is String) {
        if (!_playNotText.contains(key)) node[key] = text(v);
      } else if (v is List) {
        if (_playNotText.contains(key)) continue;
        for (var i = 0; i < v.length; i++) {
          if (v[i] is String) {
            v[i] = text(v[i]);
          } else if (v[i] is Map) {
            _play(v[i] as Map, text);
          }
        }
      } else if (v is Map) {
        if (key == 'feedback') {
          for (final k in v.keys.toList()) {
            if (v[k] is String) v[k] = text(v[k]);
          }
        } else if (key == 'answers') {
          // A witness's answers, by question id: each {line, thing}.
          for (final a in v.values) {
            if (a is Map) _play(a, text);
          }
        } else if (!_playNotText.contains(key)) {
          _play(v, text);
        }
      }
    }
  }

  // ── Checks ───────────────────────────────────────────────────────────

  /// What is wrong with these levels of [plan] (its JSON): a Rookie line
  /// not written at a level, a line written for no line of the plan, an
  /// answer the line holds that its level's words leave out, a glossary
  /// word not lower case.
  List<String> problems(Object? plan) {
    final out = <String>[];
    final rookie = rookieLines(plan);
    final known = rookie.toSet();
    for (final s in rookie) {
      for (final level in PlanLevel.values) {
        if ((lines[s]?[level] ?? '').trim().isEmpty) out.add('[level_missing] ${level.name}: "${_short(s)}" is not written');
      }
    }
    for (final s in lines.keys) {
      if (!known.contains(s)) out.add('[level_stale] "${_short(s)}": no line of the plan (run case_levels.dart skeleton)');
    }
    // An answer a line holds is in its words at every level.
    for (final (s, answers) in _answerLines(plan)) {
      for (final level in PlanLevel.values) {
        final w = lines[s]?[level];
        if (w == null || w.trim().isEmpty) continue;
        for (final a in answers) {
          if (!_holds(w, a)) out.add('[level_answer_lost] ${level.name}: "${_short(w)}" leaves out "$a", which its Rookie line holds');
        }
      }
    }
    return out;
  }

  /// Each Rookie line of a mission that holds one of its typed answers
  /// (not a choice's id), with the answers it holds.
  static List<(String, Set<String>)> _answerLines(Object? plan) {
    final out = <(String, Set<String>)>[];
    if (plan is! Map) return out;
    for (final m in [...plan['missions'] as List? ?? const [], plan['final']]) {
      if (m is! Map) continue;
      final spec = (m['puzzle'] as Map?)?['answerSpec'] as Map? ?? const {};
      final optionIds = {for (final o in spec['options'] as List? ?? const []) (o as Map)['id']};
      final answers = {
        if (spec['answer'] is String && !optionIds.contains(spec['answer'])) spec['answer'] as String,
        for (final a in spec['acceptedAnswers'] as List? ?? const []) '$a',
      }.where((a) => a.trim().length > 1 && !a.contains(',') && !a.contains(':')).toSet();
      if (answers.isEmpty) continue;
      final lines = rookieLines({'missions': [m], 'final': null});
      for (final s in lines) {
        final held = {for (final a in answers) if (_holds(s, a)) a};
        if (held.isNotEmpty) out.add((s, held));
      }
    }
    return out;
  }

  /// [line] holds [answer] as words of its own (any case).
  static bool _holds(String line, String answer) =>
      RegExp('(^|[^A-Za-z0-9])${RegExp.escape(answer)}(\$|[^A-Za-z0-9])', caseSensitive: false).hasMatch(line);

  static String _short(String s) => s.length > 60 ? '${s.substring(0, 57)}…' : s;

  /// A sentence: a line of [_sentenceWords] words or more. Names, titles,
  /// labels, choices and the in-world writing a puzzle reads are shorter,
  /// and rightly the same at every level; a sentence is written again.
  static const _sentenceWords = 6;

  /// A level that gives more than half its sentences back word for word as
  /// Rookie's was copied, not written (Rome, written by hand, gives back at
  /// most about a third at Junior and a fifth at Master). [lines]: each
  /// Rookie line's words at each level; [rookie]: the plan's lines.
  static List<String> copied(Map<String, Map<PlanLevel, String>> lines, Iterable<String> rookie) {
    final sentences = [for (final s in rookie) if (s.trim().split(RegExp(r'\s+')).length >= _sentenceWords) s];
    return [
      for (final level in PlanLevel.values)
        if (sentences.where((s) => lines[s]?[level] == s).length case final n when n * 2 > sentences.length)
          '[level_copied] ${level.name}: $n of ${sentences.length} sentences are Rookie\'s own words: '
              'write them again at ${level.name} (the same meaning), never copy them',
    ];
  }

  /// [checkCase]'s findings and, the case otherwise right, those a level
  /// copied from Rookie ([copied]): what a case's levels must pass to count
  /// as written (the factory's levels step, `case_levels.dart check`). The
  /// generator holds a level only to [checkCase].
  static List<String> checkWritten(String path, SeasonPlan season, SchemaSet schemas, {String root = '.'}) {
    final found = checkCase(path, season, schemas, root: root);
    if (found.isNotEmpty) return found;
    return copied(load(path)!.lines, rookieLines(PlanFiles.readJson(path)));
  }

  /// Each mission's lines a player reads to solve it, in order, with where
  /// each is (`<missionId> <what>`): the question, every choice (the
  /// answer marked), the hints, the clue and evidence it gives, and any
  /// other line holding a typed answer. What `review` shows at each level.
  static List<(String, String)> keyLines(Object? plan) {
    final out = <(String, String)>[];
    if (plan is! Map) return out;
    final answerLines = {for (final (s, _) in _answerLines(plan)) s};
    for (final m in [...plan['missions'] as List? ?? const [], plan['final']]) {
      if (m is! Map) continue;
      final id = m['missionId'];
      final shown = <String>{};
      void add(String what, Object? v) {
        if (v is String && v.trim().isNotEmpty && shown.add(v)) out.add(('$id $what', v));
      }

      final play = m['play'] is Map ? m['play'] as Map : const {};
      add('question', play['question']);
      final spec = (m['puzzle'] as Map?)?['answerSpec'] as Map? ?? const {};
      for (final o in spec['options'] as List? ?? const []) {
        if (o is! Map) continue;
        final right = o['id'] == spec['answer'] || (spec['answers'] is List && (spec['answers'] as List).contains(o['id']));
        add(right ? 'choice ✓' : 'choice', o['label']);
        add('choice feedback', o['feedback']);
      }
      for (final h in play['hints'] as List? ?? const []) {
        add('hint', h);
      }
      for (final key in ['clue', 'evidence']) {
        final c = play[key];
        if (c is Map) {
          for (final e in c.entries) {
            if (!_playNotText.contains(e.key)) add('$key ${e.key}', e.value);
          }
        }
      }
      for (final s in rookieLines({'missions': [m], 'final': null})) {
        if (answerLines.contains(s)) add('holds the answer', s);
      }
    }
    return out;
  }

  /// Every finding of the levels of the case plan at [path]: the levels
  /// file itself ([problems]), then each level's plan checked as the plan
  /// is (`validate_plan`'s checks, `PlayCheck`'s blocking ones) and the
  /// same game as the plan beyond its words ([sameGame]).
  static List<String> checkCase(String path, SeasonPlan season, SchemaSet schemas, {String root = '.'}) {
    final CaseLevels? levels;
    try {
      levels = load(path);
    } on PlanFormatException catch (e) {
      return ['[levels_format] ${e.path}: ${e.message}'];
    }
    if (levels == null) return ['[levels_missing] ${pathFor(path)}: not written (run case_levels.dart skeleton, then write each line)'];
    final json = PlanFiles.readJson(path);
    final out = [...levels.problems(json)];
    if ((json as Map)['caseId'] != levels.caseId) out.add('[levels_case] caseId ${levels.caseId}: the plan is ${json['caseId']}');
    if (out.isNotEmpty) return out;
    final base = CasePlan.fromJson(json);
    for (final level in PlanLevel.values) {
      final levelJson = levels.apply(json, level);
      final r = checkJson(levelJson, schemas, season: season);
      out.addAll([for (final e in r.errors) '${level.name}: $e']);
      final plan = r.casePlan;
      if (plan == null) continue;
      out.addAll([for (final i in PlayCheck.casePlan(plan, season, root: root)) if (i.blocking) '${level.name}: play $i']);
      out.addAll([for (final d in sameGame(base, plan)) '[level_not_same_game] ${level.name}: $d']);
      final kept = _expressionsHeld(json);
      _expressionsHeld(levelJson).forEach((at, held) {
        if (!held && kept[at] == true) out.add('[level_expression_lost] ${level.name}: $at is not in its mission\'s words');
      });
    }
    return out;
  }

  /// Each mission's expression (`<missionId>: "<expression>"`) → whether
  /// the mission's words (or those of the mission it recalls) hold it: the
  /// English it is designed to teach is read in it at every level.
  static Map<String, bool> _expressionsHeld(Object? plan) {
    if (plan is! Map) return const {};
    final missions = [for (final m in [...plan['missions'] as List? ?? const [], plan['final']]) if (m is Map) m];
    String wordsOf(Map<dynamic, dynamic> m) {
      final copy = _copy(m) as Map;
      (copy['learning'] as Map?)?.remove('expressions');
      return ' ${_words(rookieLines({'missions': [copy]}).join(' '))} ';
    }

    final words = {for (final m in missions) m['missionId']: wordsOf(m)};
    return {
      for (final m in missions)
        for (final e in ((m['learning'] as Map?)?['expressions'] as List? ?? const []))
          '${m['missionId']}: "$e"': words[m['missionId']]!.contains(' ${_words('$e')} ') ||
              (words[(m['learning'] as Map)['recallFrom']]?.contains(' ${_words('$e')} ') ?? false),
    };
  }

  /// [text] as the game's learning check reads it (`LearningCheck.words`):
  /// lower case, its words only, one space between them.
  static String _words(String text) => text
      .toLowerCase()
      .replaceAll(RegExp('[‘’]'), "'")
      .replaceAll(RegExp(r"[^a-z0-9']+"), ' ')
      .replaceAll(RegExp(r"(?<![a-z0-9])'|'(?![a-z0-9])"), ' ')
      .replaceAll(RegExp(' +'), ' ')
      .trim();

  /// Where [level] is another game than [base] beyond its words: the plans
  /// with every word taken out must be the very same.
  static List<String> sameGame(CasePlan base, CasePlan level) {
    final a = applyWords(base.toJson(), (_) => '');
    final b = applyWords(level.toJson(), (_) => '');
    final out = <String>[];
    void diff(Object? x, Object? y, String at) {
      if (x is Map && y is Map) {
        for (final k in {...x.keys, ...y.keys}) {
          diff(x[k], y[k], '$at.$k');
        }
      } else if (x is List && y is List && x.length == y.length) {
        for (var i = 0; i < x.length; i++) {
          diff(x[i], y[i], '$at[$i]');
        }
      } else if (jsonEncode(x) != jsonEncode(y)) {
        out.add('$at differs');
      }
    }

    diff(a, b, r'$');
    return out;
  }

  // ── Skeleton ─────────────────────────────────────────────────────────

  /// Writes the levels file of the case plan at [path] with every Rookie
  /// line of the plan: the lines written kept, the others empty. Its lines
  /// and how many are still to write.
  static (int, int) writeSkeleton(String path) {
    final json = PlanFiles.readJson(path);
    final had = load(path);
    final rookie = rookieLines(json);
    final next = CaseLevels(
      caseId: (json as Map)['caseId'] as String,
      lines: {for (final s in rookie) s: had?.lines[s] ?? const {}},
      glossary: had?.glossary ?? const {},
    );
    final out = File('${pathFor(path)}.part')..writeAsStringSync(PlanFiles.encode(next.toJson()), flush: true);
    out.renameSync(pathFor(path));
    final todo = rookie.where((s) => PlanLevel.values.any((l) => (next.lines[s]?[l] ?? '').trim().isEmpty)).length;
    return (rookie.length, todo);
  }
}
