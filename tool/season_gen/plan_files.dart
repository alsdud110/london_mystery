import 'dart:convert';
import 'dart:io';

import 'plan_models.dart';

/// Plans on disk: read whole, written whole in one canonical form (two-space
/// JSON, the models' own key order, optional fields left out when empty,
/// one newline at the end). The same plan always writes the same bytes.
///
/// A plan is written to a file beside its own and moved over it once
/// whole: a write that fails leaves the plan that was there.
abstract final class PlanFiles {
  static const _encoder = JsonEncoder.withIndent('  ');

  /// [json] in the canonical form.
  static String encode(Map<String, Object?> json) => '${_encoder.convert(json)}\n';

  /// The JSON of [path]: a [PlanFormatException] when it is not JSON.
  static Object? readJson(String path) {
    try {
      return jsonDecode(File(path).readAsStringSync());
    } on FormatException catch (e) {
      throw PlanFormatException(path, 'not JSON: ${e.message}');
    }
  }

  static SeasonPlan loadSeasonPlan(String path) => SeasonPlan.fromJson(readJson(path));

  static CasePlan loadCasePlan(String path) => CasePlan.fromJson(readJson(path));

  static void saveSeasonPlan(SeasonPlan plan, String path) => _write(path, encode(plan.toJson()));

  static void saveCasePlan(CasePlan plan, String path) => _write(path, encode(plan.toJson()));

  static void _write(String path, String text) {
    final part = File('$path.part');
    part.parent.createSync(recursive: true);
    part.writeAsStringSync(text, flush: true);
    part.renameSync(path);
  }
}
