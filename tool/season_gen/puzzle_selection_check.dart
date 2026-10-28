import 'palette_facts.dart';
import 'plan_models.dart';

/// How much a finding weighs: an error stops the plan, a warning does not.
enum Severity { error, warning }

/// The codes of the puzzle selection check's findings.
abstract final class SelectionCode {
  // ── Errors: the puzzle cannot be made as planned ──────────────────────
  /// A palette id the palette has not.
  static const paletteUnknown = 'palette_unknown';

  /// No palette id on a puzzle that is not a development request.
  static const paletteMissing = 'palette_missing';

  /// A page the palette puzzle is not played on.
  static const surfaceUnsupported = 'surface_unsupported';

  /// An engine table that is not one of the palette puzzle's engines there.
  static const engineTableMismatch = 'engine_table_mismatch';

  /// An engine table that is laid on the puzzle's engine, never played alone.
  static const engineTableCompanion = 'engine_table_companion';

  /// A mission type its engine does not play.
  static const missionTypeMismatch = 'mission_type_mismatch';

  /// A puzzle whose code must change first, not planned as a devRequest.
  static const notGeneratable = 'not_generatable';

  /// A status its palette puzzle's generation mode does not allow.
  static const statusModeConflict = 'status_mode_conflict';

  /// No picture asked for by a puzzle that needs pictures.
  static const assetNeedsMissing = 'asset_needs_missing';

  /// Data its engine plays with, missing from the plan.
  static const requiredDataMissing = 'required_data_missing';

  /// An answer its engine's data cannot give (not an option, not digits…).
  static const answerMismatch = 'answer_mismatch';

  /// `ready`, with engine data a plan does not hold.
  static const readyUnmodelled = 'ready_unmodelled_data';

  // ── Warnings: the content's variety, never a stop ─────────────────────
  /// A picture asked for that no engine of the puzzle shows.
  static const assetNeedsUnused = 'asset_needs_unused';

  /// The same palette puzzle twice or more in one case.
  static const repeatedInCase = 'repeated_in_case';

  /// One palette puzzle for more than half the puzzles of the cases given.
  static const seasonConcentration = 'season_concentration';

  /// An act with fewer kinds of puzzle than the act before it.
  static const lateDiversityDrop = 'late_diversity_drop';
}

/// One finding: how much it weighs, its code, where, and why.
class SelectionIssue {
  const SelectionIssue(this.severity, this.code, this.path, this.message, {this.caseId});

  final Severity severity;
  final String code;

  /// Where in its case plan (`$.missions[1].puzzle.paletteId`), or what of
  /// the season (an act, the season id) for a finding across cases.
  final String path;
  final String message;

  /// The case plan it is in, for a finding across cases.
  final String? caseId;

  bool get isError => severity == Severity.error;

  @override
  String toString() => '[$code] ${caseId == null ? '' : '$caseId '}$path: $message';
}

/// How one planned puzzle fits the palette, and what of its palette
/// puzzle's `requiredData` a plan can hold.
class PuzzleFit {
  const PuzzleFit({
    required this.path,
    required this.paletteId,
    required this.status,
    required this.generatable,
    this.planned = const [],
    this.words = const [],
    this.engineData = const [],
  });

  /// The puzzle plan's place (`$.missions[0].puzzle`).
  final String path;
  final String? paletteId;
  final PuzzleStatus status;

  /// A palette puzzle, without an error, that is not a development request:
  /// the generator may make it (an `awaitingAssets` one once its pictures
  /// are approved).
  final bool generatable;

  /// Its fields a plan holds, checked here.
  final List<String> planned;

  /// Its fields that are words of a level (letter, question, hints…),
  /// written when its Dart content is: not in a plan.
  final List<String> words;

  /// Its engine's own data (its scene model): not in a plan.
  final List<String> engineData;
}

/// The findings and the fits of one case plan.
class SelectionReport {
  const SelectionReport(this.issues, this.fits);

  final List<SelectionIssue> issues;
  final List<PuzzleFit> fits;

  List<SelectionIssue> get errors => [for (final i in issues) if (i.isError) i];
  List<SelectionIssue> get warnings => [for (final i in issues) if (!i.isError) i];
  bool get hasErrors => issues.any((i) => i.isError);
}

/// Whether the puzzles a plan chooses can be played by the game's engines
/// as the palette records them (STEP 3-3): palette id, page, engine table,
/// mission type, status against generation mode, and the answer data a plan
/// holds. Then the content's variety, as warnings.
///
/// Runs on a plan that keeps its format and structure (`PlanCheck`). The
/// palette is `PaletteFacts` (the game's `PuzzlePalette`, copied). Not
/// checked here: the engine data a plan does not hold (scene models,
/// pixels), the words of each level, whether pictures exist or are
/// approved, and engine collisions in the made content (those are
/// `PuzzleEngineCollisionCheck`'s, on a `SeasonContent`).
abstract final class PuzzleSelectionCheck {
  /// The fields of a palette puzzle's `requiredData` a plan holds: in its
  /// answer (`AnswerSpec`, `OptionPlan`), its clue inputs (`recall`) and
  /// its clue outputs (`evidence`).
  static const planFields = {
    'Mission.answer',
    'Mission.options',
    'Mission.acceptedAnswers',
    'Mission.codeLength',
    'Mission.codeFormat',
    'Mission.dialSymbols',
    'Mission.recall',
    'Mission.evidence',
    'ChoiceOption.label',
    'ChoiceOption.feedback',
    'ChoiceOption.altText',
  };

  /// The fields that are a level's words.
  static const wordFields = {
    'Mission.letter',
    'Mission.question',
    'Mission.prompt',
    'Mission.hints',
    'Mission.orderFeedback',
    'Mission.hideOptionNames',
  };

  /// Mission types whose answer is the id of the option chosen
  /// (`AnswerChecker.isCorrect`).
  static const _choiceTypes = {'multipleChoice', 'imageChoice', 'canvasChoice'};

  /// The findings and fits of [plan]'s puzzles, its missions then its final.
  static SelectionReport casePlan(CasePlan plan) {
    final issues = <SelectionIssue>[];
    final fits = <PuzzleFit>[];
    for (final (i, m) in plan.allMissions.indexed) {
      final at = i == plan.missions.length ? r'$.final' : '\$.missions[$i]';
      final (found, fit) = mission(m, at);
      issues.addAll(found);
      fits.add(fit);
    }

    // The same palette puzzle again in the case.
    final first = <String, String>{};
    for (final f in fits) {
      final id = f.paletteId;
      if (id == null || PaletteFacts.lookup(id) == null) continue;
      if (first[id] case final earlier?) {
        issues.add(SelectionIssue(Severity.warning, SelectionCode.repeatedInCase, '${f.path}.paletteId', '$id again (also at $earlier)'));
      } else {
        first[id] = f.path;
      }
    }
    return SelectionReport(issues, fits);
  }

  /// The findings and fit of [m]'s puzzle; [at] is [m]'s place in its case plan.
  static (List<SelectionIssue>, PuzzleFit) mission(MissionPlan m, String at) {
    final out = <SelectionIssue>[];
    final p = m.puzzle;
    final pa = '$at.puzzle';
    void error(String code, String path, String message) => out.add(SelectionIssue(Severity.error, code, path, message));

    final id = p.paletteId;
    if (id == null) {
      if (p.status != PuzzleStatus.devRequest) {
        error(SelectionCode.paletteMissing, '$pa.paletteId', 'missing: with no palette puzzle there is no engine to make it with; only a devRequest has none');
      }
      return (out, PuzzleFit(path: pa, paletteId: null, status: p.status, generatable: false));
    }
    final def = PaletteFacts.lookup(id);
    if (def == null) {
      error(SelectionCode.paletteUnknown, '$pa.paletteId', '"$id" is not a puzzle of the palette');
      return (out, PuzzleFit(path: pa, paletteId: id, status: p.status, generatable: false));
    }

    // The page, the engine on it, the type it plays.
    final engines = def.enginesFor(p.surface);
    PaletteEngine? engine;
    if (engines.isEmpty) {
      final on = [for (final s in PlanSurface.values) if (def.supports(s)) s.name];
      error(SelectionCode.surfaceUnsupported, '$pa.surface', '$id is played on ${on.join(', ')} only, not on ${p.surface.name}');
    } else {
      engine = engines.where((e) => e.table == p.engineTable).firstOrNull;
      if (engine == null) {
        final tables = engines.map((e) => e.table ?? 'none (its mission type)').join(', ');
        final t = p.engineTable;
        final owner = t == null ? null : PaletteFacts.ofTable(t);
        if (t != null && def.companionsFor(p.surface).any((e) => e.table == t)) {
          error(SelectionCode.engineTableCompanion, '$pa.engineTable', '$t is laid on $id\'s engine, never played alone; its engine table: $tables');
        } else if (t == null) {
          error(SelectionCode.engineTableMismatch, '$pa.engineTable', 'missing: $id is played on ${p.surface.name} from $tables');
        } else {
          final whose = owner == null || owner.id == id ? '' : ' ($t is ${owner.id}\'s)';
          error(SelectionCode.engineTableMismatch, '$pa.engineTable', '$t is not an engine of $id on ${p.surface.name}$whose; its engine table: $tables');
        }
      }
      final types = engine?.missionTypes ?? {for (final e in engines) ...e.missionTypes};
      if (!types.contains(p.missionType)) {
        error(SelectionCode.missionTypeMismatch, '$pa.missionType', '${p.missionType}, but ${engine?.widget ?? id} plays ${types.join(', ')}');
      }
    }

    // What its fields are: the plan's, a level's words, its engine's.
    final planned = [for (final f in def.requiredData) if (planFields.contains(f)) f];
    final words = [for (final f in def.requiredData) if (wordFields.contains(f)) f];
    final engineData = [for (final f in def.requiredData) if (!planFields.contains(f) && !wordFields.contains(f)) f];

    _status(def, p, pa, engineData, out);
    final playsType = engine != null && engine.missionTypes.contains(p.missionType);
    _data(def, m, at, engine != null && engine.table == null && playsType, out);

    final generatable = out.every((i) => !i.isError) && p.status != PuzzleStatus.devRequest;
    return (
      out,
      PuzzleFit(path: pa, paletteId: id, status: p.status, generatable: generatable, planned: planned, words: words, engineData: engineData),
    );
  }

  /// Its status against its palette puzzle's generation mode and its pictures.
  static void _status(PalettePuzzle def, PuzzlePlan p, String pa, List<String> engineData, List<SelectionIssue> out) {
    void error(String code, String path, String message) => out.add(SelectionIssue(Severity.error, code, path, message));
    final id = def.id;
    final status = p.status.name;

    if (def.mode == PaletteMode.requiresDevelopment) {
      if (p.status != PuzzleStatus.devRequest) {
        error(SelectionCode.notGeneratable, '$pa.status', '$status, but $id needs its code changed before a new season can use it (requiresDevelopment): devRequest');
      }
    } else {
      final pictures = def.mode == PaletteMode.requiresAssets || p.assetNeeds.isNotEmpty;
      if (p.status == PuzzleStatus.devRequest) {
        error(SelectionCode.statusModeConflict, '$pa.status', 'devRequest, but $id\'s engine plays it as it is (${def.mode.name}): ${pictures ? 'awaitingAssets' : 'ready'}');
      } else if (p.status == PuzzleStatus.ready && pictures) {
        final why = def.mode == PaletteMode.requiresAssets ? '$id needs pictures made and approved first (requiresAssets)' : 'its assetNeeds are pictures still to be made';
        error(SelectionCode.statusModeConflict, '$pa.status', 'ready, but $why: awaitingAssets');
      } else if (p.status == PuzzleStatus.awaitingAssets && !pictures) {
        error(SelectionCode.statusModeConflict, '$pa.status', 'awaitingAssets, but $id needs no picture (textOnly) and the plan asks for none: ready');
      }
    }

    if (def.mode == PaletteMode.requiresAssets && p.assetNeeds.isEmpty) {
      error(SelectionCode.assetNeedsMissing, '$pa.assetNeeds', 'empty, but $id needs pictures (${def.requiredAssets.join(', ')})');
    }
    if (def.mode == PaletteMode.textOnly && p.assetNeeds.isNotEmpty && (def.optionalAssets.isEmpty || def.companionsFor(p.surface).isEmpty)) {
      out.add(SelectionIssue(Severity.warning, SelectionCode.assetNeedsUnused, '$pa.assetNeeds', '$id shows no picture beyond its place\'s on ${p.surface.name}'));
    }
    if (p.status == PuzzleStatus.ready && engineData.isNotEmpty) {
      error(SelectionCode.readyUnmodelled, '$pa.status', 'ready, but $id\'s engine data is not in a plan (${engineData.join(', ')})');
    }
  }

  /// The data a plan holds, against what its engine plays with. [ownType]:
  /// played from its mission type alone (no table), so its answer data is
  /// the whole of its engine's.
  static void _data(PalettePuzzle def, MissionPlan m, String at, bool ownType, List<SelectionIssue> out) {
    void error(String code, String path, String message) => out.add(SelectionIssue(Severity.error, code, path, message));
    final p = m.puzzle;
    final a = p.answerSpec;
    final aa = '$at.puzzle.answerSpec';
    final need = def.requiredData.toSet();
    final ids = [for (final o in a.options) o.id];

    if (need.contains('Mission.options')) {
      if (a.options.isEmpty) {
        error(SelectionCode.requiredDataMissing, '$aa.options', 'missing: ${def.id} is played with options');
      } else {
        final seen = <String>{};
        for (final (i, o) in a.options.indexed) {
          if (!seen.add(o.id)) error(SelectionCode.answerMismatch, '$aa.options[$i].id', '"${o.id}" given twice');
        }
        if (_choiceTypes.contains(p.missionType)) {
          if (a.options.length < 2) error(SelectionCode.requiredDataMissing, '$aa.options', 'one option, but ${def.id} is a choice');
          if (!ids.contains(a.answer)) error(SelectionCode.answerMismatch, '$aa.answer', '"${a.answer}" is not an option id (${ids.join(', ')})');
        }
      }
    }
    if (need.contains('Mission.recall') && !m.clueInputs.any((c) => c.use == ClueUse.recall)) {
      error(SelectionCode.requiredDataMissing, '$at.clueInputs', 'missing: ${def.id} compares with an earlier evidence brought from the notebook (a clue input used as recall)');
    }
    if (!ownType) return;

    switch (p.missionType) {
      case 'wordInput':
        for (final (path, word) in [('$aa.answer', a.answer), for (final (i, w) in a.acceptedAnswers.indexed) ('$aa.acceptedAnswers[$i]', w)]) {
          if (_normalize(word).isEmpty) error(SelectionCode.answerMismatch, path, '"$word" has no letter or number to type');
        }
      case 'numberCode' || 'finalCode':
        if (!RegExp(r'^[0-9]+$').hasMatch(a.answer)) {
          error(SelectionCode.answerMismatch, '$aa.answer', '"${a.answer}" is not digits: a code is put in digit by digit');
          break;
        }
        final length = a.codeLength ?? a.answer.length;
        if (length != a.answer.length) error(SelectionCode.answerMismatch, '$aa.codeLength', '$length, but the answer "${a.answer}" has ${a.answer.length} digits');
        if (a.codeFormat == 'time' && length != 4) error(SelectionCode.answerMismatch, '$aa.codeFormat', 'time, but a code is shown as a time (H:MM) with four digits only');
        if (p.missionType == 'finalCode' && a.dialSymbols.isNotEmpty) {
          if (a.dialSymbols.length != length) error(SelectionCode.answerMismatch, '$aa.dialSymbols', '${a.dialSymbols.length} symbols for $length dials');
          for (final (i, s) in a.dialSymbols.indexed) {
            if (!PaletteFacts.dialSymbols.contains(s)) error(SelectionCode.answerMismatch, '$aa.dialSymbols[$i]', '"$s" is not a symbol a dial can show');
          }
        }
      case 'sequence':
        if (a.options.isEmpty) break;
        final steps = _ids(a.answer);
        final length = a.codeLength ?? steps.length;
        if (length != steps.length) error(SelectionCode.answerMismatch, '$aa.codeLength', '$length steps, but the answer has ${steps.length}');
        for (final s in steps.toSet()) {
          if (!ids.contains(s)) error(SelectionCode.answerMismatch, '$aa.answer', '"$s" is not an option id (${ids.join(', ')})');
        }
        // With as many options as steps, each option is used once.
        if (a.options.length >= length && steps.toSet().length != steps.length) {
          error(SelectionCode.answerMismatch, '$aa.answer', 'an option twice, but with ${a.options.length} options for $length steps each is used once');
        }
      case 'letterLock':
        if (a.options.isEmpty) break;
        final tiles = _normalize(a.options.map((o) => o.label).join());
        if (!_sameLetters(tiles, _normalize(a.answer))) {
          error(SelectionCode.answerMismatch, '$aa.answer', '"${a.answer}" is not spelled by the tiles (${a.options.map((o) => o.label).join(' ')}), each used once');
        }
    }
  }

  /// Findings across [cases] of one season: the variety of their palette
  /// puzzles. Warnings only.
  static List<SelectionIssue> season(List<CasePlan> cases) {
    final out = <SelectionIssue>[];
    if (cases.length < 2) return out;
    final seasonId = cases.first.seasonId;
    final used = <String, List<String>>{};
    var total = 0;
    for (final c in cases) {
      for (final m in c.allMissions) {
        final id = m.puzzle.paletteId;
        if (id == null || PaletteFacts.lookup(id) == null) continue;
        total++;
        (used[id] ??= []).add(m.missionId);
      }
    }
    for (final MapEntry(key: id, value: where) in used.entries) {
      if (where.length * 2 > total) {
        out.add(SelectionIssue(Severity.warning, SelectionCode.seasonConcentration, seasonId, '$id is ${where.length} of the $total palette puzzles of the ${cases.length} cases given (${where.join(', ')})'));
      }
    }

    // Acts whose cases are all given: the kinds of puzzle of each, in order.
    final kinds = <String, Set<String>>{};
    final counts = <String, int>{};
    for (final c in cases) {
      counts[c.actId] = (counts[c.actId] ?? 0) + 1;
      final k = kinds[c.actId] ??= {};
      for (final m in c.allMissions) {
        if (m.puzzle.paletteId case final id? when PaletteFacts.lookup(id) != null) k.add(id);
      }
    }
    final whole = [
      for (var n = 1; n <= actsPerSeason; n++)
        if (counts['act$n'] == casesPerAct) 'act$n',
    ];
    for (var i = 1; i < whole.length; i++) {
      final (before, now) = (kinds[whole[i - 1]]!.length, kinds[whole[i]]!.length);
      if (now < before) {
        out.add(SelectionIssue(Severity.warning, SelectionCode.lateDiversityDrop, whole[i], '$now kinds of palette puzzle, fewer than ${whole[i - 1]}\'s $before'));
      }
    }
    return out;
  }

  /// As `AnswerChecker.normalize`: upper case, letters and digits only.
  static String _normalize(String s) => s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  /// As `Mission.sequenceIds`.
  static List<String> _ids(String answer) => answer.isEmpty ? const [] : answer.split(',').map((s) => s.trim()).toList();

  static bool _sameLetters(String a, String b) => a.length == b.length && (a.split('')..sort()).join() == (b.split('')..sort()).join();
}
