import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../models/detective_name.dart';
import '../../models/game_progress.dart';
import '../../models/season_progress.dart';
import '../../models/wallet.dart';
import '../merge.dart';
import 'cloud_catalog.dart';

// Phase 4.2: what the device writes to and accepts from the cloud, in the
// shapes of firebase/firestore.rules (§12 of docs/PHASE4_CLOUD_SYNC_DESIGN.md).
// No Firestore here: the sender (Phase 4.3) turns these maps into document
// writes (and [CloudServerTime] into a server timestamp) and gives back what
// it read, with timestamps as DateTime.

/// Stands for "the server's time" in a document to write.
final class CloudServerTime {
  const CloudServerTime._();

  static const instance = CloudServerTime._();
}

/// Why something cannot go up (the local record stays as it is, unsent).
enum CloudSkip {
  /// Operator (playtest) data: never sent to a live cloud.
  operatorData,

  /// Not a case or mission of the shipped season.
  unknownId,

  /// Does not fit the cloud shape (e.g. a mission of another case).
  outOfShape,
}

/// A document to write, or why there is none.
@immutable
class CloudWrite {
  const CloudWrite(this.data) : skip = null;

  const CloudWrite.skipped(CloudSkip this.skip) : data = null;

  final Map<String, Object?>? data;
  final CloudSkip? skip;

  bool get ok => data != null;
}

/// What a document read from the cloud is good for.
sealed class CloudRead<T> {
  const CloudRead();
}

/// Valid, of the server's current epoch: may be merged.
final class CloudAccepted<T> extends CloudRead<T> {
  const CloudAccepted(this.value, {required this.cloudVersion});

  final T value;
  final int cloudVersion;
}

/// Valid but of an earlier epoch (written before a reset): not applied,
/// not a conflict.
final class CloudStale<T> extends CloudRead<T> {
  const CloudStale(this.epoch);

  final int epoch;
}

/// Not valid: never applied, never corrected. The sender keeps it as a
/// conflict ([conflictRecord]) and leaves the local data as it is.
final class CloudRejected<T> extends CloudRead<T> {
  const CloudRejected(this.subject, this.reasons);

  final String subject;
  final List<String> reasons;

  /// For `keepConflict`: kept once per subject and reasons.
  Map<String, dynamic> conflictRecord() => {
        'id': 'cloudInvalid:$subject:${reasons.join('|').hashCode}',
        'kind': 'cloudInvalid',
        'subject': subject,
        'reason': reasons.join('; '),
      };
}

/// The server's sync/meta: its epoch and version.
@immutable
class CloudMeta {
  const CloudMeta({required this.epoch, required this.cloudVersion});

  final int epoch;
  final int cloudVersion;
}

/// Turns local saves into cloud documents and checks what comes back.
class CloudCodec {
  CloudCodec(this.catalog);

  final CloudCatalog catalog;

  /// The fields of a case save the cloud keeps (the rules' list).
  static const progressFields = {
    'detectiveName', 'introSeen', 'completedMissionIds', 'attempts', 'wrongAnswers', 'hintsUsed',
    'missionStartedAt', 'missionStartPlayMillis', 'solveSeconds', 'badgeIds', 'lookedUpWords',
    'lookupsRecorded', 'xpRules', 'behavior', 'startedAt', 'completedAt', 'playMillis', 'runId', 'runSeq', 'rev',
  };

  static const _missionMaps = {
    'attempts', 'wrongAnswers', 'hintsUsed', 'missionStartedAt', 'missionStartPlayMillis', 'solveSeconds', 'xpRules',
  };

  static const _caseDocFields = {'epoch', 'runId', 'runSeq', 'cloudVersion', 'progress', 'updatedAt'};
  static const _seasonDocFields = {'epoch', 'cloudVersion', 'solvedEpisodeIds', 'updatedAt'};
  static const _metaDocFields = {'epoch', 'cloudVersion', 'updatedAt'};
  static const _eventFields = {'epoch', 'key', 'amount', 'source', 'at'};
  static const _summaryFields = {'epoch', 'cloudVersion', 'balance', 'lastEventId', 'updatedAt'};

  // ---- up ------------------------------------------------------------------

  CloudWrite metaToCloud({required int epoch, required int cloudVersion}) =>
      CloudWrite({'epoch': epoch, 'cloudVersion': cloudVersion, 'updatedAt': CloudServerTime.instance});

  /// Case [caseId]'s save at [epoch], as version [cloudVersion].
  CloudWrite caseToCloud({
    required String caseId,
    required GameProgress progress,
    required int epoch,
    required int cloudVersion,
  }) {
    if (progress.playtest) return const CloudWrite.skipped(CloudSkip.operatorData);
    if (!catalog.isCase(caseId)) return const CloudWrite.skipped(CloudSkip.unknownId);
    final json = progress.toJson();
    final out = <String, Object?>{
      for (final e in json.entries)
        if (progressFields.contains(e.key)) e.key: e.value,
    };
    if (json.keys.any((k) => !progressFields.contains(k) && k != 'playtest')) {
      return const CloudWrite.skipped(CloudSkip.outOfShape);
    }
    if (_progressProblems(caseId, out).isNotEmpty) return const CloudWrite.skipped(CloudSkip.outOfShape);
    return CloudWrite({
      'epoch': epoch,
      'runId': progress.runId,
      'runSeq': progress.runSeq,
      'cloudVersion': cloudVersion,
      'progress': out,
      'updatedAt': CloudServerTime.instance,
    });
  }

  /// The season record: cases solved only as operator data stay out.
  CloudWrite seasonToCloud({required SeasonProgress season, required int epoch, required int cloudVersion}) {
    final solved = [
      for (final id in season.solvedEpisodeIds)
        if (!season.playtestEpisodeIds.contains(id)) id,
    ];
    if (solved.any((id) => !catalog.isCase(id))) return const CloudWrite.skipped(CloudSkip.unknownId);
    return CloudWrite({
      'epoch': epoch,
      'cloudVersion': cloudVersion,
      'solvedEpisodeIds': solved,
      'updatedAt': CloudServerTime.instance,
    });
  }

  /// A coin event's document id: its epoch and key (`3_mission:m01`).
  static String eventId(int epoch, String key) => '${epoch}_$key';

  /// One coin entry at [epoch].
  CloudWrite eventToCloud(CoinEntry entry, {required int epoch}) {
    if (entry.playtest) return const CloudWrite.skipped(CloudSkip.operatorData);
    if (_eventProblem(entry.key, entry.amount, entry.source.name) case final _?) {
      return const CloudWrite.skipped(CloudSkip.outOfShape);
    }
    return CloudWrite({
      'epoch': epoch,
      'key': entry.key,
      'amount': entry.amount,
      'source': entry.source.name,
      'at': entry.at ?? DateTime.fromMillisecondsSinceEpoch(0),
    });
  }

  /// The wallet summary after adding [amount] (same epoch) or starting a new
  /// epoch with it; null when the balance would go below zero (R3: never).
  static Map<String, Object?>? summaryAfter({
    required Map<String, Object?>? previous,
    required int epoch,
    required String eventId,
    required int amount,
  }) {
    final prevEpoch = previous?['epoch'];
    final sameEpoch = previous != null && prevEpoch == epoch;
    final base = sameEpoch ? previous['balance'] as int : 0;
    final balance = base + amount;
    if (balance < 0) return null;
    return {
      'epoch': epoch,
      'cloudVersion': previous == null ? 1 : (previous['cloudVersion'] as int) + 1,
      'balance': balance,
      'lastEventId': eventId,
      'updatedAt': CloudServerTime.instance,
    };
  }

  // ---- down ----------------------------------------------------------------

  /// The server's sync/meta document.
  CloudRead<CloudMeta> readMeta(Map<String, Object?> doc) {
    final p = <String>[
      ..._exactFields(doc, _metaDocFields),
      if (!_count(doc['epoch'])) 'epoch',
      if (!_version(doc['cloudVersion'])) 'cloudVersion',
      if (doc['updatedAt'] is! DateTime) 'updatedAt',
    ];
    if (p.isNotEmpty) return CloudRejected('meta', p);
    final v = doc['cloudVersion'] as int;
    return CloudAccepted(CloudMeta(epoch: doc['epoch'] as int, cloudVersion: v), cloudVersion: v);
  }

  /// A case document, checked against the shipped season and [serverEpoch].
  CloudRead<CaseSnapshot> readCase(String caseId, Map<String, Object?> doc, {required int serverEpoch}) {
    final subject = 'case:$caseId';
    final p = <String>[
      if (!catalog.isCase(caseId)) 'unknown case',
      ..._exactFields(doc, _caseDocFields),
      if (!_count(doc['epoch'])) 'epoch',
      if (!_version(doc['cloudVersion'])) 'cloudVersion',
      if (!_count(doc['runSeq'])) 'runSeq',
      if (!(doc['runId'] == null || (doc['runId'] is String && (doc['runId'] as String).isNotEmpty))) 'runId',
      if (doc['updatedAt'] is! DateTime) 'updatedAt',
    ];
    final progress = doc['progress'];
    if (progress is! Map<String, Object?>) {
      p.add('progress');
    } else if (catalog.isCase(caseId)) {
      p.addAll(_progressProblems(caseId, progress));
      // The run named on the document is the run in the progress.
      if (progress['runId'] != doc['runId']) p.add('progress.runId');
      if ((progress['runSeq'] ?? 0) != doc['runSeq']) p.add('progress.runSeq');
    }
    if (p.isNotEmpty) return CloudRejected(subject, p);
    final epoch = doc['epoch'] as int;
    final stale = _epochCheck(subject, epoch, serverEpoch);
    if (stale != null) return stale is CloudStale ? CloudStale(epoch) : CloudRejected(subject, const ['epoch ahead of server']);
    return CloudAccepted(
      CaseSnapshot(epoch: epoch, progress: GameProgress.fromJson(Map<String, dynamic>.of(progress! as Map<String, Object?>))),
      cloudVersion: doc['cloudVersion'] as int,
    );
  }

  /// The season document. The active case is the device's own choice (the
  /// merge keeps the local one), so it is not in the cloud.
  CloudRead<SeasonSnapshot> readSeason(Map<String, Object?> doc, {required int serverEpoch}) {
    final solved = doc['solvedEpisodeIds'];
    final p = <String>[
      ..._exactFields(doc, _seasonDocFields),
      if (!_count(doc['epoch'])) 'epoch',
      if (!_version(doc['cloudVersion'])) 'cloudVersion',
      if (doc['updatedAt'] is! DateTime) 'updatedAt',
      if (solved is! List ||
          solved.length > catalog.caseIds.length ||
          solved.any((id) => id is! String || !catalog.isCase(id)) ||
          solved.toSet().length != solved.length)
        'solvedEpisodeIds',
    ];
    if (p.isNotEmpty) return CloudRejected('season', p);
    final epoch = doc['epoch'] as int;
    final stale = _epochCheck('season', epoch, serverEpoch);
    if (stale != null) return stale is CloudStale ? CloudStale(epoch) : const CloudRejected('season', ['epoch ahead of server']);
    return CloudAccepted(
      SeasonSnapshot(epoch: epoch, season: SeasonProgress(solvedEpisodeIds: [for (final id in solved! as List) id as String])),
      cloudVersion: doc['cloudVersion'] as int,
    );
  }

  /// The wallet: its events (by document id) and summary. Only events of
  /// [serverEpoch] are restored, and only all together: the current epoch's
  /// wallet is accepted when every one of its events is valid and a valid
  /// summary of that epoch names one of them and holds their exact sum (≥ 0).
  /// Otherwise nothing of it is applied ([accepted] false, an empty wallet)
  /// and every problem is reported. Never corrected.
  ({Wallet wallet, bool accepted, List<CloudRejected<void>> rejected, int? summaryVersion}) readWallet(
    Map<String, Map<String, Object?>> docs, {
    required int serverEpoch,
  }) {
    final rejected = <CloudRejected<void>>[];
    var wallet = Wallet.empty;
    final currentIds = <String>{};
    var currentBad = false;
    for (final MapEntry(key: id, value: doc) in docs.entries) {
      if (id == 'summary') continue;
      final subject = 'wallet:$id';
      final epoch = doc['epoch'];
      final key = doc['key'];
      final amount = doc['amount'];
      final source = doc['source'];
      final p = <String>[
        ..._exactFields(doc, _eventFields),
        if (!_count(epoch)) 'epoch',
        if (key is! String) 'key',
        if (amount is! int) 'amount',
        if (source is! String || CoinSource.byName(source) == null) 'source',
        if (doc['at'] is! DateTime) 'at',
      ];
      if (p.isEmpty) {
        if (id != eventId(epoch as int, key as String)) p.add('id');
        if (_eventProblem(key, amount as int, source as String) case final why?) p.add(why);
      }
      if (p.isNotEmpty) {
        rejected.add(CloudRejected(subject, p));
        if (epoch == serverEpoch || epoch is! int) currentBad = true;
        continue;
      }
      if (epoch != serverEpoch) {
        if ((epoch as int) > serverEpoch) {
          rejected.add(CloudRejected(subject, const ['epoch ahead of server']));
          currentBad = true;
        }
        continue; // an earlier epoch: not restored
      }
      currentIds.add(id);
      wallet = wallet.adding(CoinEntry(
        key: key as String,
        amount: amount as int,
        source: CoinSource.byName(source)!,
        at: doc['at'] as DateTime,
      ));
    }
    int? summaryVersion;
    final s = docs['summary'];
    final p = <String>[];
    if (s == null) {
      if (currentIds.isNotEmpty) p.add('events without a summary');
    } else {
      p.addAll([
        ..._exactFields(s, _summaryFields),
        if (!_count(s['epoch'])) 'epoch',
        if (!_version(s['cloudVersion'])) 'cloudVersion',
        if (!_count(s['balance'])) 'balance',
        if (s['lastEventId'] is! String) 'lastEventId',
        if (s['updatedAt'] is! DateTime) 'updatedAt',
      ]);
      if (p.isEmpty) {
        final epoch = s['epoch'] as int;
        if (epoch > serverEpoch) {
          p.add('epoch ahead of server');
        } else if (epoch == serverEpoch) {
          if (!currentIds.contains(s['lastEventId'])) p.add('lastEventId names no event of this epoch');
          if (s['balance'] != wallet.balance) p.add('balance != events');
        } else if (currentIds.isNotEmpty) {
          p.add('events of this epoch, summary of an earlier one');
        }
      }
    }
    if (p.isNotEmpty) rejected.add(CloudRejected('wallet:summary', p));
    // The current epoch's wallet, all or nothing.
    final accepted = p.isEmpty && !currentBad && wallet.balance >= 0;
    if (accepted && s != null && s['epoch'] == serverEpoch) summaryVersion = s['cloudVersion'] as int;
    return (
      wallet: accepted ? wallet : Wallet.empty,
      accepted: accepted,
      rejected: rejected,
      summaryVersion: summaryVersion,
    );
  }

  // ---- checks --------------------------------------------------------------

  /// Null when [epoch] is the server's; CloudStale for an earlier one;
  /// CloudRejected for a later one (the rules never allow it).
  static CloudRead<void>? _epochCheck(String subject, int epoch, int serverEpoch) {
    if (epoch == serverEpoch) return null;
    return epoch < serverEpoch ? CloudStale<void>(epoch) : CloudRejected<void>(subject, const ['epoch ahead of server']);
  }

  static List<String> _exactFields(Map<String, Object?> doc, Set<String> fields) => [
        for (final k in doc.keys)
          if (!fields.contains(k)) 'unknown field $k',
        for (final k in fields)
          if (!doc.containsKey(k)) 'missing $k',
      ];

  static bool _count(Object? v) => v is int && v >= 0;

  static bool _version(Object? v) => v is int && v >= 1;

  static bool _strings(Object? v, {int max = 1 << 30}) => v is List && v.length <= max && v.every((e) => e is String);

  static bool _iso(Object? v) => v is String && v.length <= 40 && DateTime.tryParse(v) != null;

  /// Everything wrong with a case's progress map (the rules' checks and the
  /// values the rules cannot see).
  List<String> _progressProblems(String caseId, Map<String, Object?> p) {
    final missions = catalog.missionsOf(caseId).toSet();
    final out = <String>[];
    for (final k in p.keys) {
      if (!progressFields.contains(k)) out.add('progress: unknown field $k');
    }
    void check(String field, bool ok) {
      if (p.containsKey(field) && !ok) out.add('progress.$field');
    }

    final name = p['detectiveName'];
    check('detectiveName', name == null || (name is String && DetectiveName.isValid(name)));
    check('introSeen', p['introSeen'] == null || p['introSeen'] is bool);
    check('lookupsRecorded', p['lookupsRecorded'] == null || p['lookupsRecorded'] is bool);
    final done = p['completedMissionIds'];
    check(
      'completedMissionIds',
      done == null || (_strings(done) && (done as List).every(missions.contains) && done.toSet().length == done.length),
    );
    for (final field in _missionMaps) {
      final m = p[field];
      if (!p.containsKey(field) || m == null) continue;
      if (m is! Map || !m.keys.every((k) => k is String && missions.contains(k))) {
        out.add('progress.$field');
        continue;
      }
      for (final MapEntry(key: mission, value: v) in m.entries) {
        final ok = switch (field) {
          'xpRules' => v is int && v >= 1 && v <= 4,
          'hintsUsed' => v is int && v >= 0 && v <= catalog.hintsOf(mission as String),
          'missionStartedAt' => _iso(v),
          _ => v is int && v >= 0,
        };
        if (!ok) out.add('progress.$field.$mission');
      }
    }
    check('badgeIds', p['badgeIds'] == null || _strings(p['badgeIds'], max: 32));
    check('lookedUpWords', p['lookedUpWords'] == null || _strings(p['lookedUpWords'], max: 300));
    final b = p['behavior'];
    check(
      'behavior',
      b == null ||
          (b is Map &&
              b.keys.every((k) => const {'rechecked', 'evidenceViewed', 'words'}.contains(k)) &&
              (b['rechecked'] == null ||
                  (_strings(b['rechecked'], max: 32) && (b['rechecked'] as List).every(missions.contains))) &&
              (b['evidenceViewed'] == null || _strings(b['evidenceViewed'], max: 64)) &&
              (b['words'] == null || _strings(b['words'], max: 300))),
    );
    check('startedAt', p['startedAt'] == null || _iso(p['startedAt']));
    check('completedAt', p['completedAt'] == null || _iso(p['completedAt']));
    check('playMillis', p['playMillis'] == null || _count(p['playMillis']));
    check('runId', p['runId'] == null || (p['runId'] is String && (p['runId'] as String).length <= 64));
    check('runSeq', p['runSeq'] == null || _count(p['runSeq']));
    check('rev', p['rev'] == null || _count(p['rev']));
    return out;
  }

  /// Why a coin event is not one the game makes (null: it is). The economy:
  /// start 20, a shipped mission its own coins, tip 1 free, tip 2 free or 20.
  String? _eventProblem(String key, int amount, String source) {
    final parts = key.split(':');
    switch (source) {
      case 'start':
        return key == Wallet.startKey && amount == AppConstants.startCoins ? null : 'start';
      case 'mission' || 'backfill':
        if (parts.length != 2 || parts[0] != 'mission') return 'key';
        return catalog.coinsOf(parts[1]) == amount ? null : 'mission coins';
      case 'tip':
        if (parts.length != 3 || parts[0] != 'tip' || !catalog.isMission(parts[1])) return 'key';
        return switch (parts[2]) {
          '1' => amount == AppConstants.tipPrices[0] ? null : 'tip 1 price',
          '2' => amount == 0 || amount == -AppConstants.tipPrices[1] ? null : 'tip 2 price',
          _ => 'key',
        };
      default:
        return 'source';
    }
  }
}
