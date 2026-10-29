import 'dart:io';

import 'generate_case.dart';
import 'season_cases.dart';

/// Makes the game's Dart content of a whole season (STEP 3-9): every case
/// plan its folder holds (`cases/<caseId>/case.plan.json`, see [SeasonCases]),
/// in its play order, as `generate_case.dart` makes them, together.
///
///     dart run tool/season_gen/generate_season.dart --season <season.plan.json>
///         --target sandbox [--out <dir>] [--check] [--force]
///
/// All or nothing: one case plan that fails its checks (`validate_plan`,
/// `PlayCheck`), a case missing before a written one, or a folder that is no
/// case of the season, and no file is written, the other cases' neither.
/// The output: `test/sandbox/generated/<seasonId>/` — the season's file,
/// one file a case, `<seasonId>_cases.g.dart` (every case, for
/// `SeasonContent`) and the manifest of their inputs' and outputs' hashes.
void main(List<String> args) {
  String? seasonPath, out;
  var target = 'sandbox';
  var checkOnly = false, force = false;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--season' when i + 1 < args.length:
        seasonPath = args[++i];
      case '--target' when i + 1 < args.length:
        target = args[++i];
      case '--out' when i + 1 < args.length:
        out = args[++i];
      case '--check':
        checkOnly = true;
      case '--force':
        force = true;
      default:
        stderr.writeln('unknown argument: ${args[i]}');
        exit(64);
    }
  }
  if (seasonPath == null) {
    stderr.writeln('usage: dart run tool/season_gen/generate_season.dart --season <season.plan.json> --target sandbox '
        '[--out <dir>] [--check] [--force]');
    exit(64);
  }
  if (target != 'sandbox') {
    stderr.writeln('--target $target: only --target sandbox is made (a season of the game is registered by hand)');
    exit(64);
  }
  final schemaDir = '${File.fromUri(Platform.script).parent.path}/schema';
  final season = seasonPath;
  exit(makeAndWrite(
    () {
      final cases = SeasonCases.of(season);
      stdout.writeln('season   $season: ${cases.length} case plans');
      return CaseGenerator.sandbox(seasonPath: season, casePaths: cases, schemaDir: schemaDir);
    },
    out: out,
    checkOnly: checkOnly,
    force: force,
  ));
}
