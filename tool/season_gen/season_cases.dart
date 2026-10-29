import 'dart:io';

import 'generate_case.dart' show GenerateFailure;
import 'plan_files.dart';
import 'plan_models.dart';

/// The case plans a season's folder holds (STEP 3-9): `cases/<caseId>/case.plan.json`
/// beside its `season.plan.json`, for every case of its acts written so far.
///
/// Only the folders are judged here: a folder of no case of the season, or a
/// case folder with no plan. Whether the cases written are the season's
/// first, none missing between them, is `CaseGenerator.sandbox`'s
/// (`case_missing`), as are the plans themselves.
abstract final class SeasonCases {
  /// The case plans' paths, in the season's play order. A [GenerateFailure]
  /// with every finding when the folder cannot be read as the season's.
  static List<String> of(String seasonPath) {
    final SeasonPlan season;
    try {
      season = PlanFiles.loadSeasonPlan(seasonPath);
    } on PlanFormatException catch (e) {
      throw GenerateFailure(['FAILED  $seasonPath', '  error    ${e.path}: ${e.message}']);
    } on FileSystemException catch (e) {
      throw GenerateFailure(['FAILED  $seasonPath', '  error    ${e.message}']);
    }
    final dir = '${File(seasonPath).parent.path.replaceAll(r'\', '/')}/cases';
    final errors = <String>[];
    final written = <String>{};
    final folders = Directory(dir).existsSync() ? Directory(dir).listSync().whereType<Directory>().toList() : <Directory>[];
    folders.sort((a, b) => a.path.compareTo(b.path));
    for (final f in folders) {
      final name = f.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (!season.caseIds.contains(name)) {
        errors.add('[case_not_in_season] cases/$name: not a case of ${season.seasonId} (its acts)');
      } else if (!File('${f.path}/case.plan.json').existsSync()) {
        errors.add('[case_plan_missing] cases/$name: no case.plan.json');
      } else {
        written.add(name);
      }
    }
    if (errors.isEmpty && written.isEmpty) errors.add('[no_cases] $dir: no case plan is written');
    if (errors.isNotEmpty) throw GenerateFailure(['FAILED  $seasonPath', for (final e in errors) '  error    $e']);
    return [for (final id in season.caseIds) if (written.contains(id)) '$dir/$id/case.plan.json'];
  }
}
