import 'dart:convert';
import 'dart:io';

import '../season_gen/generate_case.dart';
import '../season_gen/generate_season.dart' show generateSeason;
import '../season_gen/plan_files.dart';
import '../season_gen/plan_models.dart';
import 'asset_manifest.dart';
import 'finding.dart';
import 'season_quality.dart';

/// The season planner's command line (STEP 3-11). Claude Code plans the
/// season (`tool/season_planner/PLAYBOOK.md`); this keeps the plans in their
/// folder and checks them. It never writes a story, calls an API or makes a
/// picture.
///
///     dart run tool/season_planner/plan_season.dart init --season 3 --city Rome [--cases 12] [--acts 3] [--root content_pipeline/seasons]
///     dart run tool/season_planner/plan_season.dart check <seasonDir> [--no-report] [--all]
///     dart run tool/season_planner/plan_season.dart assets <seasonDir>
///     dart run tool/season_planner/plan_season.dart format <seasonDir>
///     dart run tool/season_planner/plan_season.dart generate <seasonDir> [--target sandbox|game] [--check] [--force] [--out <dir>]
///
/// * `init`: the season's folder and its brief (`planning/brief.json`), nothing
///   else; refused when the folder or the season's number is taken.
/// * `check`: every check (`SeasonQuality`), printed, and written to
///   `planning/quality_report.json`. Exit 1 with an ERROR.
/// * `assets`: the pictures planned, by kind, and their estimated cost.
/// * `format`: the season and case plans rewritten in `PlanFiles`' one
///   canonical form; nothing written unless every plan reads.
/// * `generate`: the sandbox content (`generate_season.dart --target sandbox`),
///   only once `check` finds no ERROR and every picture is on disk. With
///   `--target game`: the season in the app (`lib/data/generated/`, its
///   content, art and the game's lists of generated seasons).
///
/// Exit codes: 0 done; 1 an ERROR (nothing generated); 2 waiting for
/// pictures (nothing generated); 64 usage.
void main(List<String> args) {
  if (args.isEmpty) _usage();
  exit(switch (args.first) {
    'init' => _init(args.skip(1).toList()),
    'check' => _check(args.skip(1).toList()),
    'assets' => _assets(args.skip(1).toList()),
    'format' => formatCommand(args.skip(1).toList()),
    'generate' => generateCommand(args.skip(1).toList()),
    _ => _usage(),
  });
}

Never _usage() {
  stderr.writeln('usage: dart run tool/season_planner/plan_season.dart\n'
      '  init --season <n> --city <City> [--cases 12] [--acts 3] [--root content_pipeline/seasons]\n'
      '  check <seasonDir> [--no-report] [--all]\n'
      '  assets <seasonDir>\n'
      '  format <seasonDir>\n'
      '  generate <seasonDir> [--target sandbox|game] [--check] [--force] [--out <dir>]');
  exit(64);
}

/// What `init` makes of its arguments: the season's id and folder, or why not.
class SeasonBrief {
  const SeasonBrief(this.number, this.city, this.seasonId, this.dir);

  final int number;
  final String city;
  final String seasonId;
  final String dir;

  /// `s3_rome` for season 3 in Rome: the city's letters, lower case.
  static String idFor(int number, String city) => 's${number}_${city.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';

  /// The brief of [args], or a [FormatException] saying what is wrong.
  /// Nothing is written: a season is twelve cases in three acts (the plans'
  /// schema), its number and its folder its own.
  static SeasonBrief parse(List<String> args, {String root = 'content_pipeline/seasons'}) {
    int? number, cases = 12, acts = 3;
    String? city;
    var dir = root;
    for (var i = 0; i < args.length; i++) {
      String next() => i + 1 < args.length ? args[++i] : throw FormatException('${args[i]} needs a value');
      switch (args[i]) {
        case '--season':
          number = int.tryParse(next());
        case '--city':
          city = next().trim();
        case '--cases':
          cases = int.tryParse(next());
        case '--acts':
          acts = int.tryParse(next());
        case '--root':
          dir = next();
        default:
          throw FormatException('unknown argument: ${args[i]}');
      }
    }
    if (number == null || number < 1) throw const FormatException('--season: a season number (1 or more)');
    if (city == null || city.isEmpty) throw const FormatException('--city: the city');
    if (cases != 12 || acts != 3) {
      throw FormatException('--cases $cases --acts $acts: a season is 12 cases in 3 acts of 4 (season_plan.schema.json, PlanCheck)');
    }
    final id = idFor(number, city);
    if (!RegExp(r'^s[1-9][0-9]*_[a-z][a-z0-9]*$').hasMatch(id)) throw FormatException('--city $city: no season id can be made of it ($id)');
    final folder = '$dir/$id';
    if (Directory(folder).existsSync()) throw FormatException('$folder is there already: never written over');
    if (Directory(dir).existsSync()) {
      for (final d in Directory(dir).listSync().whereType<Directory>()) {
        final name = d.uri.pathSegments.where((s) => s.isNotEmpty).last;
        if (name.startsWith('s${number}_')) throw FormatException('season $number is planned already ($dir/$name)');
      }
    }
    return SeasonBrief(number, city, id, folder);
  }

  /// The folder with its brief, written whole or not at all.
  void write() {
    final brief = {
      'schemaVersion': 1,
      'seasonId': seasonId,
      'number': number,
      'city': city,
      'cases': 12,
      'acts': 3,
      'assetRoot': AssetManifest.rootFor(number, seasonId),
      'playbook': 'tool/season_planner/PLAYBOOK.md',
    };
    final tmp = Directory('$dir.part');
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    try {
      Directory('${tmp.path}/planning').createSync(recursive: true);
      Directory('${tmp.path}/cases').createSync();
      File('${tmp.path}/planning/brief.json').writeAsStringSync(PlanFiles.encode(brief), flush: true);
      tmp.renameSync(dir);
    } on FileSystemException {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
      rethrow;
    }
  }
}

int _init(List<String> args) {
  final SeasonBrief brief;
  try {
    brief = SeasonBrief.parse(args);
  } on FormatException catch (e) {
    stderr.writeln('init: ${e.message}\nnothing written');
    return 64;
  }
  brief.write();
  stdout.writeln('made     ${brief.dir}/ (planning/brief.json, cases/)');
  stdout.writeln('season   ${brief.seasonId}: Season ${brief.number}, ${brief.city}, 12 cases in 3 acts');
  stdout.writeln('next     plan it as tool/season_planner/PLAYBOOK.md says, then:');
  stdout.writeln('         dart run tool/season_planner/plan_season.dart check ${brief.dir}');
  return 0;
}

String _dir(List<String> args) {
  final dirs = [for (final (i, a) in args.indexed) if (!a.startsWith('--') && (i == 0 || !const {'--out', '--target'}.contains(args[i - 1]))) a];
  if (dirs.length != 1) _usage();
  return dirs.single.replaceAll(r'\', '/').replaceAll(RegExp(r'/$'), '');
}

int _check(List<String> args) {
  final dir = _dir(args);
  final report = SeasonQuality.run(dir);
  _print(report, all: args.contains('--all'));
  if (!args.contains('--no-report') && report.seasonId != '?') {
    stdout.writeln('report   ${SeasonQuality.write(dir, report)}');
  }
  return report.hasErrors ? 1 : 0;
}

void _print(QualityReport r, {bool all = false}) {
  final s = r.summary;
  for (final f in r.findings) {
    if (all || f.level != Level.info || f.code.startsWith('generator')) stdout.writeln(f);
  }
  if (!all) {
    final infos = <String, int>{};
    for (final f in r.findings.where((f) => f.level == Level.info && !f.code.startsWith('generator'))) {
      infos[f.code] = (infos[f.code] ?? 0) + 1;
    }
    for (final MapEntry(:key, :value) in infos.entries) {
      stdout.writeln('INFO    [$key] x$value (--all to list)');
    }
  }
  stdout.writeln('season   ${r.seasonId}: ${s['cases']} cases, ${s['missions']} missions + ${s['finals']} finals, '
      '${s['crossCaseClueInputs']} clue inputs from other cases');
  stdout.writeln('puzzles  ${jsonEncode(s['puzzlesByKind'])}');
  if (s['assets'] case final Map a) {
    stdout.writeln('assets   ${a['total']} planned (${a['backgrounds']} backgrounds, ${a['characters']} characters, ${a['objects']} objects), '
        '${a['reusedAcrossCases']} in more than one case, est. \$${a['estimatedUsd']} (${a['model']}, ${a['quality']}); API calls: 0');
  }
  stdout.writeln('${r.count(Level.error)} ERROR, ${r.count(Level.warning)} WARNING, ${r.count(Level.info)} INFO');
}

int _assets(List<String> args) {
  final dir = _dir(args);
  final file = File('$dir/${AssetManifest.fileName}');
  if (!file.existsSync()) {
    stderr.writeln('no ${AssetManifest.fileName} in $dir');
    return 1;
  }
  final json = jsonDecode(file.readAsStringSync()) as Map;
  final byType = <String, List<Map>>{};
  for (final a in (json['assets'] as List).cast<Map>()) {
    (byType[a['type'] as String] ??= []).add(a);
  }
  for (final MapEntry(key: type, value: list) in byType.entries) {
    stdout.writeln('$type (${list.length})');
    for (final a in list) {
      stdout.writeln('  ${a['status'].toString().padRight(9)} ${a['width']}x${a['height']} ${a['stylePreset'].toString().padRight(12)} ${a['outputPath']}');
    }
  }
  final report = SeasonQuality.run(dir);
  if (report.summary['assets'] case final Map a) {
    stdout.writeln('total ${a['total']}, est. \$${a['estimatedUsd']} at ${a['model']} ${a['quality']} (an estimate; nothing sent)');
  }
  for (final f in report.findings.where((f) => f.source == Source.assets && f.level != Level.info)) {
    stdout.writeln(f);
  }
  return report.findings.any((f) => f.source == Source.assets && f.isError) ? 1 : 0;
}

/// `format`: every plan of the season's folder read, then (only if all read)
/// each written again in `PlanFiles`' canonical form. Its exit code.
int formatCommand(List<String> args) {
  final dir = _dir(args);
  final plans = <String, Object>{};
  final failed = <String>[];
  void read(String path, Object Function() load) {
    try {
      plans[path] = load();
    } on PlanFormatException catch (e) {
      failed.add('$path ${e.path}: ${e.message}');
    } on FileSystemException catch (e) {
      failed.add('$path: ${e.message}');
    }
  }

  read('$dir/season.plan.json', () => PlanFiles.loadSeasonPlan('$dir/season.plan.json'));
  final cases = Directory('$dir/cases').existsSync() ? Directory('$dir/cases').listSync().whereType<Directory>().toList() : <Directory>[];
  for (final d in cases) {
    final path = '${d.path.replaceAll(r'\', '/')}/case.plan.json';
    if (File(path).existsSync()) read(path, () => PlanFiles.loadCasePlan(path));
  }
  if (failed.isNotEmpty) {
    for (final f in failed) {
      stdout.writeln('error    $f');
    }
    stdout.writeln('nothing written');
    return 1;
  }
  for (final MapEntry(key: path, value: plan) in plans.entries) {
    switch (plan) {
      case SeasonPlan p:
        PlanFiles.saveSeasonPlan(p, path);
      case CasePlan p:
        PlanFiles.saveCasePlan(p, path);
    }
  }
  stdout.writeln('format   ${plans.length} plans in canonical form');
  return 0;
}

/// `generate`: the season's sandbox content, made only from plans with no
/// ERROR and every place's picture on disk. Its exit code (0, 1, 2).
int generateCommand(List<String> args) {
  final dir = _dir(args);
  String? out;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--out' && i + 1 < args.length) out = args[i + 1];
  }
  final report = SeasonQuality.run(dir);
  if (report.hasErrors) {
    for (final f in report.findings.where((f) => f.isError)) {
      stdout.writeln(f);
    }
    stdout.writeln('${report.count(Level.error)} ERROR: nothing generated');
    return 1;
  }
  if (report.picturesPending > 0) {
    stdout.writeln('waiting  ${report.picturesPending} place pictures are not made yet (assets.manifest.json): nothing generated');
    return 2;
  }
  final seasonPath = '$dir/season.plan.json';
  final i = args.indexOf('--target');
  final target = i >= 0 && i + 1 < args.length ? args[i + 1] : 'sandbox';
  if (target != 'sandbox' && target != 'game') {
    stdout.writeln('--target $target: sandbox or game');
    return 64;
  }
  if (target == 'game' && out != null) {
    stdout.writeln('--out: a season of the game is written where the game reads it (${GameRegistry.dir}/<seasonId>)');
    return 64;
  }
  return generateSeason(seasonPath, target: target, checkOnly: args.contains('--check'), force: args.contains('--force'), out: out);
}
