import 'dart:io';

import 'json_schema_lite.dart';
import 'plan_check.dart';
import 'plan_files.dart';
import 'plan_models.dart';

/// Checks plan files: each against its JSON Schema, read as its model, and
/// its structure (`PlanCheck`). A case plan is checked against the season
/// plan given with `--season`.
///
///     dart run tool/season_gen/validate_plan.dart [--season season.plan.json] <plan.json>...
///
/// A file named `*season.plan.json` is a season plan; `*case.plan.json` a
/// case plan. Exit code 1 when anything is wrong.
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
  var bad = false;
  for (final path in files) {
    final problems = check(path, schemas, season: season);
    bad = bad || problems.isNotEmpty;
    stdout.writeln(problems.isEmpty ? 'ok      $path' : 'FAILED  $path');
    for (final p in problems) {
      stdout.writeln('  $p');
    }
  }
  exit(bad ? 1 : 0);
}

T? _tryLoad<T>(T Function() load) {
  try {
    return load();
  } on PlanFormatException {
    return null;
  }
}

/// What is wrong with plan file [path]: its schema's findings, then its
/// model's (format), then its structure's.
List<String> check(String path, SchemaSet schemas, {SeasonPlan? season}) {
  final isSeason = path.endsWith('season.plan.json');
  if (!isSeason && !path.endsWith('case.plan.json')) return ['not a plan file name (*season.plan.json, *case.plan.json)'];
  final Object? json;
  try {
    json = PlanFiles.readJson(path);
  } on PlanFormatException catch (e) {
    return [e.message];
  }
  final out = [for (final p in schemas.validate(json, isSeason ? 'season_plan.schema.json' : 'case_plan.schema.json')) 'schema $p'];
  try {
    if (isSeason) {
      out.addAll(PlanCheck.season(SeasonPlan.fromJson(json)).map((p) => 'structure $p'));
    } else {
      out.addAll(PlanCheck.casePlan(CasePlan.fromJson(json), season: season).map((p) => 'structure $p'));
    }
  } on PlanFormatException catch (e) {
    out.add('model ${e.path}: ${e.message}');
  }
  return out;
}
