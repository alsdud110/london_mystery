import 'dart:io';

import 'generate_case.dart';
import 'season_cases.dart';

/// Makes the game's Dart content of a whole season (STEP 3-9): every case
/// plan its folder holds (`cases/<caseId>/case.plan.json`, see [SeasonCases]),
/// in its play order, as `generate_case.dart` makes them, together.
///
///     dart run tool/season_gen/generate_season.dart --season <season.plan.json>
///         --target sandbox|game [--out <dir>] [--check] [--force]
///
/// All or nothing: one case plan that fails its checks (`validate_plan`,
/// `PlayCheck`), a case missing before a written one, or a folder that is no
/// case of the season, and no file is written, the other cases' neither.
/// The output: `test/sandbox/generated/<seasonId>/` — the season's file,
/// one file a case, `<seasonId>_cases.g.dart` (every case, for
/// `SeasonContent`) and the manifest of their inputs' and outputs' hashes.
///
/// `--target game` (the Rome integration): the season as the app plays it,
/// in `lib/data/generated/<seasonId>/`, with its `SeasonContent` and art,
/// and the game's two lists of generated seasons made again
/// (`GameRegistry`): the season is in `SeasonCatalog.all`, its map, cover,
/// World Map city and evidence pictures registered, no line written by
/// hand. `--out` is refused there (the game reads that one folder).
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
    stderr.writeln('usage: dart run tool/season_gen/generate_season.dart --season <season.plan.json> --target sandbox|game '
        '[--out <dir>] [--check] [--force]');
    exit(64);
  }
  if (target != 'sandbox' && target != 'game') {
    stderr.writeln('--target $target: sandbox or game');
    exit(64);
  }
  if (target == 'game' && out != null) {
    stderr.writeln('--out: a season of the game is written where the game reads it (${GameRegistry.dir}/<seasonId>)');
    exit(64);
  }
  final schemaDir = '${File.fromUri(Platform.script).parent.path}/schema';
  exit(generateSeason(seasonPath, target: target, checkOnly: checkOnly, force: force, out: out, schemaDir: schemaDir));
}

/// The season at [seasonPath] made for [target] and written (or with
/// [checkOnly], compared); for the game, the registry after it. Its exit code.
int generateSeason(String seasonPath,
    {String target = 'sandbox', bool checkOnly = false, bool force = false, String? out, String schemaDir = 'tool/season_gen/schema'}) {
  Generated? made;
  final code = makeAndWrite(
    () {
      final cases = SeasonCases.of(seasonPath);
      stdout.writeln('season   $seasonPath: ${cases.length} case plans');
      return made = CaseGenerator.sandbox(seasonPath: seasonPath, casePaths: cases, schemaDir: schemaDir, target: target);
    },
    out: out,
    checkOnly: checkOnly,
    force: force,
  );
  if (code != 0 || target != 'game') return code;
  stdout.writeln('registry ${GameRegistry.dir}: the seasons of the game made from plans');
  return makeAndWrite(
    () => Generated('registry', GameRegistry.files(GameRegistry.seasons(adding: made)), const [], target: 'registry'),
    out: GameRegistry.dir,
    checkOnly: checkOnly,
    force: force,
  );
}
