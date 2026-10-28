import 'dart:io';

import 'json_schema_lite.dart';
import 'plan_check.dart';
import 'plan_files.dart';
import 'plan_models.dart';
import 'puzzle_selection_check.dart';

/// Checks plan files: each against its JSON Schema, read as its model, its
/// structure (`PlanCheck`), then a case plan's puzzle selection
/// (`PuzzleSelectionCheck`). A case plan is checked against the season
/// plan given with `--season`; the case plans given together, for their
/// puzzles' variety across cases.
///
///     dart run tool/season_gen/validate_plan.dart [--season season.plan.json] <plan.json>...
///
/// A file named `*season.plan.json` is a season plan; `*case.plan.json` a
/// case plan. Exit code 1 when there is an error; warnings alone pass.
void main(List<String> args) {
  final schemaDir = '${File.fromUri(Platform.script).parent.path}/schema';
  final schemas = SchemaSet.load(schemaDir);
  SeasonPlan? season;
  final files = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--season' && i + 1 < args.length) {
      final path = args[++i];
      files.add(path);
      season = _tryLoad(() => PlanFiles.loadSeasonPlan(path));
    } else {
      files.add(args[i]);
    }
  }
  if (files.isEmpty) {
    stderr.writeln('usage: dart run tool/season_gen/validate_plan.dart [--season season.plan.json] <plan.json>...');
    exit(64);
  }
  var errors = 0;
  var warnings = 0;
  final cases = <String, List<CasePlan>>{};
  for (final path in files) {
    final r = check(path, schemas, season: season);
    errors += r.errors.length;
    warnings += r.warnings.length;
    if (r.casePlan case final c?) (cases[c.seasonId] ??= []).add(c);
    stdout.writeln('${r.errors.isEmpty ? 'ok     ' : 'FAILED '} $path${r.summary == null ? '' : '  (${r.summary})'}');
    _print(r.errors, r.warnings);
  }
  for (final MapEntry(key: seasonId, value: plans) in cases.entries) {
    final found = PuzzleSelectionCheck.season(plans);
    if (found.isEmpty) continue;
    warnings += found.length;
    stdout.writeln('season  $seasonId, ${plans.length} case plans');
    _print(const [], [for (final i in found) 'puzzles $i']);
  }
  stdout.writeln('$errors ${errors == 1 ? 'error' : 'errors'}, $warnings ${warnings == 1 ? 'warning' : 'warnings'}');
  exit(errors > 0 ? 1 : 0);
}

void _print(List<String> errors, List<String> warnings) {
  for (final e in errors) {
    stdout.writeln('  error    $e');
  }
  for (final w in warnings) {
    stdout.writeln('  warning  $w');
  }
}

T? _tryLoad<T>(T Function() load) {
  try {
    return load();
  } on PlanFormatException {
    return null;
  }
}

/// What was found in one plan file.
class PlanFileResult {
  const PlanFileResult(this.errors, {this.warnings = const [], this.casePlan, this.selection});

  final List<String> errors;
  final List<String> warnings;

  /// A case plan that kept its format and structure.
  final CasePlan? casePlan;

  /// Its puzzle selection's findings and fits (a case plan whose format and
  /// structure hold; the selection is not looked at before they do).
  final SelectionReport? selection;

  /// Its puzzles by what can be made of them.
  String? get summary {
    final s = selection;
    if (s == null) return null;
    final made = s.fits.where((f) => f.generatable).toList();
    final ready = made.where((f) => f.status == PuzzleStatus.ready).length;
    final dev = s.fits.where((f) => f.status == PuzzleStatus.devRequest).length;
    final wrong = s.fits.length - made.length - dev;
    return 'puzzles: $ready ready, ${made.length - ready} awaitingAssets, $dev devRequest${wrong > 0 ? ', $wrong with errors' : ''}';
  }
}

/// What is wrong with plan file [path]: its schema's findings, then its
/// model's (format), then its structure's, then (a case plan whose
/// structure holds) its puzzle selection's.
PlanFileResult check(String path, SchemaSet schemas, {SeasonPlan? season}) {
  final isSeason = path.endsWith('season.plan.json');
  if (!isSeason && !path.endsWith('case.plan.json')) return const PlanFileResult(['not a plan file name (*season.plan.json, *case.plan.json)']);
  final Object? json;
  try {
    json = PlanFiles.readJson(path);
  } on PlanFormatException catch (e) {
    return PlanFileResult([e.message]);
  }
  final out = [for (final p in schemas.validate(json, isSeason ? 'season_plan.schema.json' : 'case_plan.schema.json')) 'schema $p'];
  try {
    if (isSeason) {
      out.addAll(PlanCheck.season(SeasonPlan.fromJson(json)).map((p) => 'structure $p'));
      return PlanFileResult(out);
    }
    final plan = CasePlan.fromJson(json);
    out.addAll(PlanCheck.casePlan(plan, season: season).map((p) => 'structure $p'));
    if (out.isNotEmpty) return PlanFileResult(out);
    final selection = PuzzleSelectionCheck.casePlan(plan);
    return PlanFileResult(
      [for (final i in selection.errors) 'puzzles $i'],
      warnings: [for (final i in selection.warnings) 'puzzles $i'],
      casePlan: plan,
      selection: selection,
    );
  } on PlanFormatException catch (e) {
    out.add('model ${e.path}: ${e.message}');
    return PlanFileResult(out);
  }
}
