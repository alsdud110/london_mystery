import 'dart:convert';
import 'dart:io';

import '../ai_agents/png_check.dart';
import '../season_gen/sha256.dart';

/// Where one asset of a season's manifest stands in the pipeline.
///
/// * `planned`: nothing made (the manifest's own status).
/// * `generating`: a call was sent and no answer recorded. Read back, it is
///   `failed`: the call may have been billed, its picture is not trusted.
/// * `generated`: the API's picture is on disk (`raw`), checked whole.
/// * `validated`: the picture at the game's size (`game`) is on disk,
///   checked whole: what a later step copies to the manifest's `outputPath`.
/// * `failed`: the last call or check failed (`error`); a later run tries again.
/// * `blocked`: a file is there that the pipeline did not write as recorded
///   (changed, damaged, or someone else's): never used, never written over,
///   until a person moves it away.
///
/// `assets.manifest.json` keeps its own two statuses: `planned`, and
/// `generated` once the picture is in `assets/` (a later step's copy).
enum AssetStatus { planned, generating, generated, validated, failed, blocked }

/// A file the pipeline wrote, as it wrote it.
class FileRecord {
  const FileRecord({required this.path, required this.sha256, required this.width, required this.height, required this.hasAlpha});

  /// From the repository's root.
  final String path;
  final String sha256;
  final int width;
  final int height;
  final bool hasAlpha;

  static FileRecord of(String root, String path) {
    final bytes = File('$root/$path').readAsBytesSync();
    final info = PngCheck.bytes(bytes);
    return FileRecord(path: path, sha256: 'sha256:${Sha256.hex(bytes)}', width: info.width, height: info.height, hasAlpha: info.hasAlpha);
  }

  /// Why the file at [path] is not this one any more, or null when it is.
  String? problem(String root) {
    final f = File('$root/$path');
    if (!f.existsSync()) return 'missing';
    final bytes = f.readAsBytesSync();
    if ('sha256:${Sha256.hex(bytes)}' != sha256) return 'changed since it was written';
    try {
      PngCheck.bytes(bytes);
    } on PngProblem catch (e) {
      return '$e';
    }
    return null;
  }

  Map<String, Object?> toJson() => {'path': path, 'sha256': sha256, 'width': width, 'height': height, 'hasAlpha': hasAlpha};

  static FileRecord? fromJson(Object? j) => j is Map
      ? FileRecord(
          path: j['path'] as String,
          sha256: j['sha256'] as String,
          width: j['width'] as int,
          height: j['height'] as int,
          hasAlpha: j['hasAlpha'] as bool,
        )
      : null;
}

/// One asset's record.
class AssetRecord {
  AssetRecord(this.assetId);

  final String assetId;
  AssetStatus status = AssetStatus.planned;
  int attempts = 0;
  String? requestKey;
  FileRecord? raw;
  FileRecord? game;
  bool transformed = false;
  String? error;
  double? estimatedUsd;
  double? conservativeUsd;
  double? fromUsageUsd;
  String? updatedAt;

  Map<String, Object?> toJson() => {
    'status': status.name,
    'attempts': attempts,
    'requestKey': ?requestKey,
    'raw': ?raw?.toJson(),
    'game': ?game?.toJson(),
    if (game != null) 'transformed': transformed,
    'error': ?error,
    'cost': {'estimatedUsd': estimatedUsd, 'conservativeUsd': conservativeUsd, 'fromUsageUsd': fromUsageUsd},
    'updatedAt': ?updatedAt,
  };

  static AssetRecord fromJson(String id, Map j) {
    final cost = j['cost'] is Map ? j['cost'] as Map : const {};
    return AssetRecord(id)
      ..status = AssetStatus.values.byName(j['status'] as String)
      ..attempts = j['attempts'] as int? ?? 0
      ..requestKey = j['requestKey'] as String?
      ..raw = FileRecord.fromJson(j['raw'])
      ..game = FileRecord.fromJson(j['game'])
      ..transformed = j['transformed'] as bool? ?? false
      ..error = j['error'] as String?
      ..estimatedUsd = (cost['estimatedUsd'] as num?)?.toDouble()
      ..conservativeUsd = (cost['conservativeUsd'] as num?)?.toDouble()
      ..fromUsageUsd = (cost['fromUsageUsd'] as num?)?.toDouble()
      ..updatedAt = j['updatedAt'] as String?;
  }
}

/// A season's pipeline state: `<work>/pipeline_state.json`, every asset's
/// record and every generating run. Holds no key and no prompt (the call
/// ledger, `image_manifest.json` beside it, has the requests).
class PipelineState {
  PipelineState._(this.path, this.seasonId, this.records, this.runs);

  static const schemaVersion = 1;
  static const fileName = 'pipeline_state.json';

  /// The file, as a path the process opens.
  final String path;
  final String seasonId;
  final Map<String, AssetRecord> records;
  final List<Map<String, Object?>> runs;

  /// The state at [path] (a new one when there is none).
  static PipelineState load(String path, String seasonId) {
    final f = File(path);
    if (!f.existsSync()) return PipelineState._(path, seasonId, {}, []);
    final json = jsonDecode(f.readAsStringSync());
    if (json is! Map || json['schemaVersion'] != schemaVersion || json['assets'] is! Map) {
      throw FormatException('$path: not a pipeline state (schemaVersion $schemaVersion)');
    }
    if (json['seasonId'] != seasonId) throw FormatException('$path: the state of ${json['seasonId']}, not $seasonId');
    return PipelineState._(
      path,
      seasonId,
      {for (final MapEntry(:key, :value) in (json['assets'] as Map).entries) key as String: AssetRecord.fromJson(key, value as Map)},
      [for (final r in json['runs'] as List? ?? const []) (r as Map).cast<String, Object?>()],
    );
  }

  AssetRecord of(String assetId) => records[assetId] ??= AssetRecord(assetId);

  AssetStatus statusOf(String assetId) => records[assetId]?.status ?? AssetStatus.planned;

  /// Every recorded file checked against the disk under [root], each
  /// record set to what can still be trusted. The changes, as lines.
  ///
  /// A call left `generating` is `failed`. A missing picture is made again
  /// (`failed`, or `generated` when only the game copy is missing). A file
  /// that is there but not as written is `blocked`: never reused.
  List<String> verify(String root) {
    final out = <String>[];
    for (final r in records.values) {
      if (r.status == AssetStatus.generating) {
        r.status = AssetStatus.failed;
        r.error = 'interrupted during a call (it may have been billed; its picture is not trusted)';
        out.add('${r.assetId}: ${r.error}');
        continue;
      }
      if (r.status != AssetStatus.generated && r.status != AssetStatus.validated) continue;
      final String? rawProblem = r.raw == null ? 'no record of its file' : r.raw!.problem(root);
      if (rawProblem == 'missing' || rawProblem == 'no record of its file') {
        r.status = AssetStatus.failed;
        r.error = 'its picture ${r.raw?.path ?? ''} is $rawProblem: made again';
        r.game = null;
        out.add('${r.assetId}: ${r.error}');
        continue;
      }
      if (rawProblem != null) {
        r.status = AssetStatus.blocked;
        r.error = '${r.raw!.path}: $rawProblem; never reused or written over (move it away to make it again)';
        out.add('${r.assetId}: ${r.error}');
        continue;
      }
      if (r.status == AssetStatus.validated && r.game != null && r.game!.path != r.raw!.path) {
        final gameProblem = r.game!.problem(root);
        if (gameProblem == 'missing') {
          r.status = AssetStatus.generated;
          r.game = null;
          out.add('${r.assetId}: its game copy is missing: made again from its picture');
        } else if (gameProblem != null) {
          r.status = AssetStatus.blocked;
          r.error = '${r.game!.path}: $gameProblem; never reused or written over';
          out.add('${r.assetId}: ${r.error}');
        }
      }
    }
    return out;
  }

  Map<String, int> get counts {
    final out = <String, int>{};
    for (final r in records.values) {
      out[r.status.name] = (out[r.status.name] ?? 0) + 1;
    }
    return out;
  }

  /// Written whole beside itself, then moved over the old one.
  void save() {
    final f = File(path)..parent.createSync(recursive: true);
    final part = File('$path.part');
    final ids = records.keys.toList()..sort();
    part.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert({
        'schemaVersion': schemaVersion,
        'seasonId': seasonId,
        'counts': counts,
        'assets': {for (final id in ids) id: records[id]!.toJson()},
        'runs': runs,
      })}\n',
      flush: true,
    );
    part.renameSync(f.path);
  }
}
