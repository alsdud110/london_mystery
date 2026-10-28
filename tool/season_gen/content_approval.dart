import 'dart:convert';
import 'dart:io';

import 'content_hash.dart';
import 'plan_ids.dart';
import 'plan_models.dart';

/// What can be approved: a season plan, a case plan, a picture.
enum ApprovalKind { seasonPlan, casePlan, asset }

/// Where a target stands, judged from its file now against its last
/// approval. Never written down: an approval holds a hash, and the status is
/// what that hash says of the file as it is.
enum ApprovalStatus {
  /// Never approved.
  draft,

  /// Approved, and the file is as it was approved.
  approved,

  /// Approved, but the file has changed since (or is not JSON any more).
  stale,

  /// No file: nothing can be approved, and an approval of it holds no more.
  missing,
}

/// An approval file that cannot be read: where, and why.
class ApprovalFormatException implements Exception {
  const ApprovalFormatException(this.path, this.message);

  final String path;
  final String message;

  @override
  String toString() => '$path: $message';
}

/// What cannot be approved, and why.
class ApprovalException implements Exception {
  const ApprovalException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// One approval: a person's word that a target, with this hash, was
/// reviewed. Approvals are only added, never changed or removed: the last of
/// a target is the one that counts, the earlier ones its history.
class ApprovalRecord {
  const ApprovalRecord({
    required this.kind,
    required this.id,
    required this.hash,
    required this.approvedAt,
    required this.approvedBy,
    this.path,
    this.note,
  });

  final ApprovalKind kind;

  /// The season id, the case id, or the asset id (`s3_tokyo.asset.hall`).
  final String id;

  /// The content's [ContentHash] when it was approved.
  final String hash;

  /// In UTC.
  final DateTime approvedAt;

  /// Who approved it (`name <email>`).
  final String approvedBy;

  /// An asset's file, from the repository's root (`assets/seasons/…/hall.png`).
  /// A plan's file is its id's own (`season.plan.json`, `cases/<id>/case.plan.json`).
  final String? path;
  final String? note;

  static const _keys = {'kind', 'id', 'hash', 'approvedAt', 'approvedBy', 'path', 'note'};

  factory ApprovalRecord.fromJson(Object? json, String at, String seasonId) {
    ApprovalFormatException bad(String key, String why) => ApprovalFormatException('$at.$key', why);
    if (json is! Map<String, Object?>) throw ApprovalFormatException(at, 'not an object');
    for (final k in json.keys) {
      if (!_keys.contains(k)) throw bad(k, 'unknown field');
    }
    String str(String key, {bool optional = false}) {
      final v = json[key];
      if (v == null && optional) return '';
      if (v is! String || v.trim().isEmpty) throw bad(key, 'not a non-empty string');
      return v;
    }

    final kind = ApprovalKind.values.where((k) => k.name == json['kind']).firstOrNull ?? (throw bad('kind', 'one of ${ApprovalKind.values.map((k) => k.name).join(', ')}'));
    final id = str('id');
    final problem = SeasonApprovals.idProblem(kind, id, seasonId);
    if (problem != null) throw bad('id', problem);
    final hash = str('hash');
    if (!ContentHash.pattern.hasMatch(hash)) throw bad('hash', 'not sha256:<64 hex digits>');
    final when = DateTime.tryParse(str('approvedAt'));
    if (when == null || !when.isUtc) throw bad('approvedAt', 'not an ISO 8601 time in UTC');
    final by = str('approvedBy');
    final path = str('path', optional: true);
    if (kind == ApprovalKind.asset) {
      final p = SeasonApprovals.pathProblem(path);
      if (p != null) throw bad('path', p);
    } else if (path.isNotEmpty) {
      throw bad('path', "a plan's file is its id's own");
    }
    final note = str('note', optional: true);
    return ApprovalRecord(kind: kind, id: id, hash: hash, approvedAt: when, approvedBy: by, path: path.isEmpty ? null : path, note: note.isEmpty ? null : note);
  }

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'id': id,
    'hash': hash,
    'approvedAt': approvedAt.toIso8601String(),
    'approvedBy': approvedBy,
    if (path != null) 'path': path,
    if (note != null) 'note': note,
  };
}

/// One target's standing: its status, its file, its hash now, its approvals.
class ApprovalState {
  const ApprovalState(this.kind, this.id, this.status, {this.file, this.currentHash, this.history = const [], this.problem});

  final ApprovalKind kind;
  final String id;
  final ApprovalStatus status;

  /// Its file (absolute); null for an asset never approved (its file is not known).
  final String? file;

  /// Its content's hash now; null when there is no file, or it is not JSON.
  final String? currentHash;

  /// Its approvals, oldest first.
  final List<ApprovalRecord> history;

  /// Why its content has no hash (not JSON).
  final String? problem;

  /// Its last approval.
  ApprovalRecord? get record => history.lastOrNull;

  bool get isApproved => status == ApprovalStatus.approved;

  String get label => '${kind.name} $id';

  @override
  String toString() {
    final r = record;
    final last = r == null ? '' : ' (approved ${r.approvedAt.toIso8601String()} by ${r.approvedBy})';
    return '${status.name.padRight(8)} $label$last${problem == null ? '' : ': $problem'}';
  }
}

/// What a case still lacks to be made into the game's content (STEP 3-6):
/// its season plan, its own plan, and every picture its puzzles ask for,
/// each approved as it is now.
class CaseReadiness {
  const CaseReadiness(this.caseId, this.states, this.blockers);

  final String caseId;

  /// The season plan's, the case plan's, then its assets', in that order.
  final List<ApprovalState> states;

  /// Why it cannot be made yet: nothing when it can.
  final List<String> blockers;

  bool get ready => blockers.isEmpty;
}

/// The approvals of one season in the making (STEP 3-5), kept beside its
/// plans and tracked by Git:
///
///     content_pipeline/seasons/<seasonId>/
///       approvals.json          every approval, oldest first, never removed
///       approved/<hex>.json     each plan as it was approved, by its hash
///
/// A status is never read from the file: it is the hash of the content now
/// against the last approval's ([state]). Nothing here approves on its own:
/// [approve] is called only for a person who asked for it (the command line,
/// `approve.dart`, asks them at a terminal); checking and saving plans never
/// touch approvals.
class SeasonApprovals {
  /// [seasonDir] is `<root>/content_pipeline/seasons/<seasonId>`: the
  /// repository's root, an asset's path is read from, is three folders up.
  SeasonApprovals(String seasonDir) : dir = Directory(seasonDir.replaceFirst(RegExp(r'/+$'), '')).absolute;

  final Directory dir;

  static const fileName = 'approvals.json';
  static const snapshotDir = 'approved';
  static const schemaVersion = 1;

  String get seasonId => dir.uri.pathSegments.where((s) => s.isNotEmpty).last;

  /// The repository's root.
  Directory get root => dir.parent.parent.parent;

  String get logPath => '${dir.path}/$fileName';

  /// What is wrong with [id] as a [kind] of season [seasonId], or null.
  static String? idProblem(ApprovalKind kind, String id, String seasonId) => switch (kind) {
    ApprovalKind.seasonPlan => id == seasonId ? null : 'the season plan of $seasonId is $seasonId',
    ApprovalKind.casePlan =>
      PlanIds.caseNumbers(id)?.$1 == PlanIds.seasonNumber(seasonId) && PlanIds.seasonNumber(seasonId) != null ? null : 'not a case id of $seasonId',
    ApprovalKind.asset => PlanIds.asset.hasMatch(id) && PlanIds.seasonOfScoped(id) == seasonId ? null : 'not an asset id of $seasonId ($seasonId.asset.<name>)',
  };

  /// What is wrong with an asset's [path] (from the root), or null.
  static String? pathProblem(String path) {
    if (path.isEmpty) return 'missing: an asset is approved with its file';
    if (path.startsWith('/') || path.contains(r'\') || path.split('/').any((s) => s.isEmpty || s == '.' || s == '..')) {
      return 'not a path inside the repository (a/b/c.png, from its root)';
    }
    return null;
  }

  /// The file of a plan: `season.plan.json`, `cases/<caseId>/case.plan.json`.
  String planFile(ApprovalKind kind, String id) => switch (kind) {
    ApprovalKind.seasonPlan => '${dir.path}/season.plan.json',
    ApprovalKind.casePlan => '${dir.path}/cases/$id/case.plan.json',
    ApprovalKind.asset => throw ArgumentError.value(kind, 'kind', 'an asset has no plan file'),
  };

  /// Every approval, oldest first: none when there is no approval file.
  List<ApprovalRecord> records() {
    final file = File(logPath);
    if (!file.existsSync()) return const [];
    final Object? json;
    try {
      json = jsonDecode(file.readAsStringSync());
    } on FormatException catch (e) {
      throw ApprovalFormatException(logPath, 'not JSON: ${e.message}');
    }
    if (json is! Map<String, Object?>) throw ApprovalFormatException(logPath, 'not an object');
    for (final k in json.keys) {
      if (!const {'schemaVersion', 'seasonId', 'approvals'}.contains(k)) throw ApprovalFormatException('\$.$k', 'unknown field');
    }
    if (json['schemaVersion'] != schemaVersion) throw ApprovalFormatException(r'$.schemaVersion', 'must be $schemaVersion');
    if (json['seasonId'] != seasonId) throw ApprovalFormatException(r'$.seasonId', 'must be $seasonId, the folder it is in');
    final list = json['approvals'];
    if (list is! List) throw const ApprovalFormatException(r'$.approvals', 'not an array');
    return [for (final (i, r) in list.indexed) ApprovalRecord.fromJson(r, '\$.approvals[$i]', seasonId)];
  }

  ApprovalState seasonPlan() => state(ApprovalKind.seasonPlan, seasonId);

  ApprovalState casePlan(String caseId) => state(ApprovalKind.casePlan, caseId);

  ApprovalState asset(String assetId) => state(ApprovalKind.asset, assetId);

  /// The standing of [kind] [id] now. [records] when they are read already.
  ApprovalState state(ApprovalKind kind, String id, {List<ApprovalRecord>? records}) {
    final problem = idProblem(kind, id, seasonId);
    if (problem != null) throw ArgumentError.value(id, 'id', problem);
    final history = [for (final r in records ?? this.records()) if (r.kind == kind && r.id == id) r];
    final String? path;
    if (kind == ApprovalKind.asset) {
      final p = history.lastOrNull?.path;
      path = p == null ? null : '${root.path}/$p';
    } else {
      path = planFile(kind, id);
    }
    if (path == null) return ApprovalState(kind, id, ApprovalStatus.draft, history: history);
    final file = File(path);
    if (!file.existsSync()) return ApprovalState(kind, id, ApprovalStatus.missing, file: path, history: history);
    final (hash, why) = _hashOf(kind, file);
    final ApprovalStatus status;
    if (history.isEmpty) {
      status = ApprovalStatus.draft;
    } else {
      status = hash == history.last.hash ? ApprovalStatus.approved : ApprovalStatus.stale;
    }
    return ApprovalState(kind, id, status, file: path, currentHash: hash, history: history, problem: why);
  }

  (String?, String?) _hashOf(ApprovalKind kind, File file) {
    if (kind == ApprovalKind.asset) return (ContentHash.ofBytes(file.readAsBytesSync()), null);
    try {
      return (ContentHash.ofJson(jsonDecode(file.readAsStringSync())), null);
    } on FormatException catch (e) {
      return (null, 'not JSON: ${e.message}');
    }
  }

  /// Records a person's approval of [kind] [id] as its file is now, and
  /// returns it (a plan's content is kept under `approved/`, for
  /// `ChangeImpact` to compare with later). An asset is approved with its
  /// file, [assetPath] from the root (its last approval's when not given).
  /// Already approved as it is: nothing is added, and its approval is returned.
  ///
  /// Only for a person's explicit request: this is the one place an
  /// approval is written.
  ({ApprovalRecord record, bool added}) approve(
    ApprovalKind kind,
    String id, {
    required String approvedBy,
    String? note,
    String? assetPath,
    DateTime? now,
  }) {
    if (approvedBy.trim().isEmpty || approvedBy.contains('\n')) throw const ApprovalException('who approves is to be named (one line)');
    final all = records();
    var path = assetPath;
    if (kind == ApprovalKind.asset) {
      path ??= all.where((r) => r.kind == kind && r.id == id).lastOrNull?.path;
      final p = SeasonApprovals.pathProblem(path ?? '');
      if (p != null) throw ApprovalException('$id: $p');
    } else if (assetPath != null) {
      throw ApprovalException("$id: a plan's file is its id's own");
    }
    final current = state(kind, id, records: all);
    final file = kind == ApprovalKind.asset ? File('${root.path}/$path') : File(current.file!);
    if (!file.existsSync()) throw ApprovalException('${current.label}: no file at ${file.path}');
    final (hash, why) = _hashOf(kind, file);
    if (hash == null) throw ApprovalException('${current.label}: $why');
    final last = current.record;
    if (last != null && last.hash == hash && last.path == path) return (record: last, added: false);

    final record = ApprovalRecord(
      kind: kind,
      id: id,
      hash: hash,
      approvedAt: (now ?? DateTime.now()).toUtc(),
      approvedBy: approvedBy.trim(),
      path: kind == ApprovalKind.asset ? path : null,
      note: note == null || note.trim().isEmpty ? null : note.trim(),
    );
    if (kind != ApprovalKind.asset) {
      final json = jsonDecode(file.readAsStringSync());
      _write('${dir.path}/$snapshotDir/${ContentHash.hexOf(hash)}.json', '${const JsonEncoder.withIndent('  ').convert(json)}\n');
    }
    _write(
      logPath,
      '${const JsonEncoder.withIndent('  ').convert({
        'schemaVersion': schemaVersion,
        'seasonId': seasonId,
        'approvals': [for (final r in [...all, record]) r.toJson()],
      })}\n',
    );
    return (record: record, added: true);
  }

  /// The content of [record]'s plan as it was approved, or null when it is
  /// not kept (or kept with another hash: a changed copy is not trusted).
  Object? approvedJson(ApprovalRecord record) {
    if (record.kind == ApprovalKind.asset) return null;
    final file = File('${dir.path}/$snapshotDir/${ContentHash.hexOf(record.hash)}.json');
    if (!file.existsSync()) return null;
    try {
      final json = jsonDecode(file.readAsStringSync());
      return ContentHash.ofJson(json) == record.hash ? json : null;
    } on FormatException {
      return null;
    }
  }

  /// The case ids of the season: its season plan's (when it reads), those
  /// with a plan folder, those approved.
  List<String> caseIds({List<ApprovalRecord>? records}) {
    final ids = <String>{...?_plan(planFile(ApprovalKind.seasonPlan, seasonId), SeasonPlan.fromJson)?.caseIds};
    final cases = Directory('${dir.path}/cases');
    if (cases.existsSync()) {
      for (final d in cases.listSync().whereType<Directory>()) {
        final id = d.uri.pathSegments.where((s) => s.isNotEmpty).last;
        if (idProblem(ApprovalKind.casePlan, id, seasonId) == null && File('${d.path}/case.plan.json').existsSync()) ids.add(id);
      }
    }
    for (final r in records ?? this.records()) {
      if (r.kind == ApprovalKind.casePlan) ids.add(r.id);
    }
    return ids.toList()..sort();
  }

  /// The case plans of the season that read as plans, by case id.
  Map<String, CasePlan> casePlans() => {
    for (final id in caseIds()) id: ?_plan(planFile(ApprovalKind.casePlan, id), CasePlan.fromJson),
  };

  /// Every target of the season: the season plan, each case plan, each
  /// asset approved or asked for by a case plan.
  List<ApprovalState> report() {
    final all = records();
    final assets = <String>{
      for (final r in all) if (r.kind == ApprovalKind.asset) r.id,
      for (final p in casePlans().values)
        for (final m in p.allMissions)
          for (final a in m.puzzle.assetNeeds) if (idProblem(ApprovalKind.asset, a, seasonId) == null) a,
    };
    return [
      state(ApprovalKind.seasonPlan, seasonId, records: all),
      for (final id in caseIds(records: all)) state(ApprovalKind.casePlan, id, records: all),
      for (final id in assets.toList()..sort()) state(ApprovalKind.asset, id, records: all),
    ];
  }

  /// Whether [caseId] can be made into the game's content: its season plan
  /// and its plan approved as they are, and every asset its puzzles ask for.
  CaseReadiness readiness(String caseId) {
    final all = records();
    final season = state(ApprovalKind.seasonPlan, seasonId, records: all);
    final plan = state(ApprovalKind.casePlan, caseId, records: all);
    final states = [season, plan];
    final blockers = [
      for (final s in states)
        if (!s.isApproved) '${s.label} is ${s.status.name}',
    ];
    if (plan.isApproved) {
      final p = _plan(plan.file!, CasePlan.fromJson);
      if (p == null) {
        blockers.add('${plan.label} does not read as a case plan');
      } else {
        final needs = <String>{for (final m in p.allMissions) ...m.puzzle.assetNeeds};
        for (final id in needs) {
          if (idProblem(ApprovalKind.asset, id, seasonId) != null) {
            blockers.add('asset $id is not an asset of $seasonId');
            continue;
          }
          final a = state(ApprovalKind.asset, id, records: all);
          states.add(a);
          if (!a.isApproved) blockers.add('${a.label} is ${a.status.name}');
        }
      }
    }
    return CaseReadiness(caseId, states, blockers);
  }

  static T? _plan<T>(String path, T Function(Object? json) read) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      return read(jsonDecode(file.readAsStringSync()));
    } on FormatException {
      return null;
    } on PlanFormatException {
      return null;
    }
  }

  static void _write(String path, String text) {
    final part = File('$path.part');
    part.parent.createSync(recursive: true);
    part.writeAsStringSync(text, flush: true);
    part.renameSync(path);
  }
}
