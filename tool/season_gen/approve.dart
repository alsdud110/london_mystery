import 'dart:io';

import 'change_impact.dart';
import 'content_approval.dart';
import 'json_schema_lite.dart';
import 'plan_files.dart';
import 'plan_models.dart';
import 'validate_plan.dart' as plans;

/// The approvals of a season in the making (STEP 3-5): their status, a
/// person's approval, what a change since touches.
///
///     dart run tool/season_gen/approve.dart status  <seasonDir> [season | case <caseId> | asset <assetId>]
///     dart run tool/season_gen/approve.dart approve <seasonDir> (season | case <caseId> | asset <assetId> [--path <file>]) [--by <name>] [--note <text>]
///     dart run tool/season_gen/approve.dart impact  <seasonDir> [season | case <caseId> | asset <assetId>]
///
/// `<seasonDir>` is `content_pipeline/seasons/<seasonId>`; an asset's
/// `--path` is from the repository's root. `approve` checks a plan as
/// `validate_plan.dart` does and refuses one with errors; then asks, at a
/// terminal only, for the target's id to be typed. Who approves is `--by`,
/// or Git's `user.name <user.email>`.
///
/// Exit codes: `status` 0 when every target shown is approved, else 1;
/// `approve` 0 when approved, 1 when refused; `impact` 0; 2 an approval file
/// that cannot be read; 64 a wrong command line.
void main(List<String> args) {
  final schemaDir = '${File.fromUri(Platform.script).parent.path}/schema';
  exit(run(args, out: stdout, schemaDir: schemaDir, confirm: _askAtTerminal));
}

const _usage = '''usage: dart run tool/season_gen/approve.dart status  <seasonDir> [season | case <caseId> | asset <assetId>]
       dart run tool/season_gen/approve.dart approve <seasonDir> (season | case <caseId> | asset <assetId> [--path <file>]) [--by <name>] [--note <text>]
       dart run tool/season_gen/approve.dart impact  <seasonDir> [season | case <caseId> | asset <assetId>]''';

/// The command line on [args], writing to [out]. [confirm] is asked, for a
/// target's label and id, whether a person approves it; [approver] names
/// who approves when `--by` is not given.
int run(
  List<String> args, {
  required StringSink out,
  required String schemaDir,
  required bool Function(String label, String id) confirm,
  String? Function() approver = _gitUser,
  DateTime Function()? clock,
}) {
  final positional = <String>[];
  final options = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a.startsWith('--')) {
      if (!const {'--path', '--by', '--note'}.contains(a) || i + 1 >= args.length) return _misuse(out, 'unknown or empty option $a');
      options[a.substring(2)] = args[++i];
    } else {
      positional.add(a);
    }
  }
  if (positional.length < 2) return _misuse(out, null);
  final [command, seasonDir, ...rest] = positional;
  if (!Directory(seasonDir).existsSync()) return _misuse(out, 'no folder $seasonDir');
  final approvals = SeasonApprovals(seasonDir);
  final (ApprovalKind, String)? target;
  switch (rest) {
    case []:
      target = null;
    case ['season']:
      target = (ApprovalKind.seasonPlan, approvals.seasonId);
    case ['case', final id]:
      target = (ApprovalKind.casePlan, id);
    case ['asset', final id]:
      target = (ApprovalKind.asset, id);
    default:
      return _misuse(out, 'a target is season, case <caseId> or asset <assetId>');
  }
  if (target case (final kind, final id)) {
    final problem = SeasonApprovals.idProblem(kind, id, approvals.seasonId);
    if (problem != null) return _misuse(out, '$id: $problem');
  }
  if (options.containsKey('path') && (command != 'approve' || target?.$1 != ApprovalKind.asset)) return _misuse(out, '--path is for approving an asset');

  try {
    return switch (command) {
      'status' => _status(approvals, target, out),
      'approve' when target != null => _approve(approvals, target, options, out, schemaDir, confirm, approver, clock),
      'impact' => _impact(approvals, target, out),
      _ => _misuse(out, null),
    };
  } on ApprovalFormatException catch (e) {
    out.writeln('the approvals cannot be read: $e');
    return 2;
  }
}

int _misuse(StringSink out, String? why) {
  if (why != null) out.writeln(why);
  out.writeln(_usage);
  return 64;
}

int _status(SeasonApprovals approvals, (ApprovalKind, String)? target, StringSink out) {
  if (target case (final kind, final id)) {
    final s = approvals.state(kind, id);
    out.writeln(s);
    return s.isApproved ? 0 : 1;
  }
  final states = approvals.report();
  for (final s in states) {
    out.writeln(s);
  }
  for (final s in states) {
    if (s.kind != ApprovalKind.casePlan) continue;
    final r = approvals.readiness(s.id);
    out.writeln(r.ready ? 'ready    ${r.caseId}' : 'blocked  ${r.caseId}: ${r.blockers.join('; ')}');
  }
  final counts = {for (final v in ApprovalStatus.values) v: states.where((s) => s.status == v).length};
  out.writeln([for (final MapEntry(:key, :value) in counts.entries) '$value ${key.name}'].join(', '));
  return states.every((s) => s.isApproved) ? 0 : 1;
}

int _approve(
  SeasonApprovals approvals,
  (ApprovalKind, String) target,
  Map<String, String> options,
  StringSink out,
  String schemaDir,
  bool Function(String label, String id) confirm,
  String? Function() approver,
  DateTime Function()? clock,
) {
  final (kind, id) = target;
  final current = approvals.state(kind, id);
  if (kind != ApprovalKind.asset) {
    final path = current.file!;
    if (!File(path).existsSync()) {
      out.writeln('not approved: ${current.label} has no file at $path');
      return 1;
    }
    // A plan with errors is not approved: its checks run as validate_plan's.
    SeasonPlan? season;
    if (kind == ApprovalKind.casePlan) {
      try {
        season = PlanFiles.loadSeasonPlan(approvals.planFile(ApprovalKind.seasonPlan, approvals.seasonId));
      } on PlanFormatException {
        season = null;
      } on FileSystemException {
        season = null;
      }
    }
    final r = plans.check(path, SchemaSet.load(schemaDir), season: season);
    if (r.errors.isNotEmpty) {
      out.writeln('not approved: ${current.label} has errors (validate_plan.dart)');
      for (final e in r.errors) {
        out.writeln('  error    $e');
      }
      return 1;
    }
    for (final w in r.warnings) {
      out.writeln('  warning  $w');
    }
  }
  final by = options['by'] ?? approver();
  if (by == null || by.trim().isEmpty) {
    out.writeln('not approved: who approves is not known (--by, or Git user.name)');
    return 1;
  }
  out.writeln('$current');
  if (!confirm(current.label, id)) {
    out.writeln('not approved: ${current.label}');
    return 1;
  }
  try {
    final (:record, :added) = approvals.approve(kind, id, approvedBy: by, note: options['note'], assetPath: options['path'], now: clock?.call());
    out.writeln(added ? 'approved ${current.label} ${record.hash} by ${record.approvedBy}' : 'already approved as it is: ${current.label} ${record.hash}');
    return 0;
  } on ApprovalException catch (e) {
    out.writeln('not approved: $e');
    return 1;
  }
}

int _impact(SeasonApprovals approvals, (ApprovalKind, String)? target, StringSink out) {
  final states = target == null
      ? [for (final s in approvals.report()) if (s.status == ApprovalStatus.stale || (s.status == ApprovalStatus.missing && s.record != null)) s]
      : [approvals.state(target.$1, target.$2)];
  if (states.isEmpty) out.writeln('nothing approved has changed');
  final cases = approvals.casePlans();
  final assets = {for (final s in approvals.report()) if (s.kind == ApprovalKind.asset) s.id: s.status};
  for (final s in states) {
    out.writeln(s);
    final items = _impactOf(approvals, s, cases, assets, out);
    if (items == null) continue;
    if (items.isEmpty) out.writeln('  nothing else is touched');
    for (final i in items) {
      out.writeln('  $i');
    }
  }
  return 0;
}

/// What [s]'s change touches, or null (said why on [out]).
List<ImpactItem>? _impactOf(SeasonApprovals approvals, ApprovalState s, Map<String, CasePlan> cases, Map<String, ApprovalStatus> assets, StringSink out) {
  final r = s.record;
  if (r == null) {
    out.writeln('  never approved: nothing to compare');
    return null;
  }
  if (s.status == ApprovalStatus.approved) return const [];
  if (s.kind == ApprovalKind.asset) return ChangeImpact.asset(s.id, cases.values);
  if (s.status == ApprovalStatus.missing) {
    out.writeln('  its file is gone');
    return null;
  }
  final was = approvals.approvedJson(r);
  if (was == null) {
    out.writeln('  its approved content is not kept (approved/${r.hash.substring(7)}.json): nothing to compare');
    return null;
  }
  try {
    if (s.kind == ApprovalKind.seasonPlan) {
      return ChangeImpact.season(SeasonPlan.fromJson(was), PlanFiles.loadSeasonPlan(s.file!), cases: cases.values);
    }
    return ChangeImpact.casePlan(CasePlan.fromJson(was), PlanFiles.loadCasePlan(s.file!), others: cases.values, assets: assets);
  } on PlanFormatException catch (e) {
    out.writeln('  cannot be compared: ${e.path}: ${e.message}');
    return null;
  }
}

/// A person's word, typed at a terminal: input piped in, or output not on a
/// screen, is no one's.
bool _askAtTerminal(String label, String id) {
  if (!stdin.hasTerminal || !stdout.hasTerminal) {
    stdout.writeln('an approval is asked of a person at a terminal, and there is none');
    return false;
  }
  stdout.write('Approve $label as it is now? Type "$id" to approve: ');
  return stdin.readLineSync()?.trim() == id;
}

String? _gitUser() {
  String? config(String key) {
    try {
      final r = Process.runSync('git', ['config', key]);
      final v = (r.stdout as String).trim();
      return r.exitCode == 0 && v.isNotEmpty ? v : null;
    } on ProcessException {
      return null;
    }
  }

  final name = config('user.name');
  if (name == null) return null;
  final email = config('user.email');
  return email == null ? name : '$name <$email>';
}
