import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/game_progress.dart';
import '../models/season_progress.dart';
import '../models/wallet.dart';
import '../sync/cloud/cloud_sync_meta.dart';
import '../sync/outbox.dart';
import '../sync/save_journal.dart';

/// Persists one detective's runs so they survive app restarts: one
/// [GameProgress] per case, the [SeasonProgress] record and the [Wallet].
abstract interface class ProgressRepository {
  GameProgress load([String episodeId = AppConstants.currentEpisodeId]);

  Future<void> save(GameProgress progress, [String episodeId = AppConstants.currentEpisodeId]);

  SeasonProgress loadSeason();

  Future<void> saveSeason(SeasonProgress season);

  /// The coins, or null when no wallet was ever saved (a new player, or a
  /// save from before coins existed).
  Wallet? loadWallet();

  Future<void> saveWallet(Wallet wallet);

  /// Removes every case save, the season record and the wallet (of this
  /// detective only).
  Future<void> clear();

  /// Runs [body] (which must not wait for anything) so that every save it
  /// makes is stored together: after the app stops at any moment, all of
  /// them or none (e.g. a mission's coins and the mission solved).
  T transaction<T>(T Function() body);
}

/// Saves of one profile, under its namespace (`lm.p.<profileId>.…`, the
/// same keys as before profiles otherwise). The saves made before profiles
/// existed are never written or removed here.
///
/// Every change is also queued in the profile's [outbox] for a later sync,
/// in the same all-or-nothing save as the change itself (see
/// [SaveJournal]); a save that changes nothing writes nothing.
class SharedPrefsProgressRepository implements ProgressRepository {
  SharedPrefsProgressRepository(this._prefs, {required this.profileId, this.legacyFallback = false})
      : _journal = SaveJournal(_prefs, profileId) {
    // A save the app stopped in the middle of is finished first; changes
    // handed to a sender before the app stopped wait to be sent again.
    _journal.recover();
    final waiting = outbox;
    final recovered = waiting.recovered();
    if (!identical(recovered, waiting)) _put({_outboxKey: recovered.encode()});
  }

  final SharedPreferences _prefs;
  final String profileId;
  final SaveJournal _journal;

  /// Safe mode (see `ProfileSession.legacyFallback`): a save the profile
  /// does not have yet is read from the original saves, until it starts over.
  final bool legacyFallback;

  static final _random = Random.secure();

  String _key(String legacyKey) => AppConstants.profileKey(profileId, legacyKey);
  String get _outboxKey => AppConstants.outboxKey(profileId);

  /// Writes of the transaction under way (null: none).
  Map<String, String?>? _tx;

  String? _get(String key) {
    final tx = _tx;
    if (tx != null && tx.containsKey(key)) return tx[key];
    final v = _prefs.get(key);
    return v is String ? v : null;
  }

  void _put(Map<String, String?> writes) {
    final tx = _tx;
    if (tx != null) {
      tx.addAll(writes);
    } else {
      _journal.commit(writes);
    }
  }

  @override
  T transaction<T>(T Function() body) {
    if (_tx != null) return body(); // already in one
    _tx = {};
    try {
      return body();
    } finally {
      final writes = _tx!;
      _tx = null;
      _journal.commit(writes);
    }
  }

  /// How many times everything of this profile was wiped. Every save and
  /// queued change belongs to it; a merge prefers a later epoch, so a reset
  /// is never undone by data from before it. Kept in the namespace, so a
  /// reset and its new epoch are saved together.
  int get epoch {
    final raw = _get(AppConstants.metaKey(profileId));
    if (raw == null) return 0;
    try {
      final e = (jsonDecode(raw) as Map)['epoch'];
      return e is int && e > 0 ? e : 0;
    } catch (_) {
      return 0;
    }
  }

  bool get _readsOriginals {
    if (!legacyFallback) return false;
    final key = AppConstants.legacyClearedKey(profileId);
    final tx = _tx;
    final cleared = tx != null && tx.containsKey(key) ? tx[key] : _prefs.get(key);
    return cleared != true && cleared != 'true';
  }

  /// Plain JSON only — never a polymorphic/object deserializer.
  Map<String, dynamic>? _read(String legacyKey) {
    var key = _key(legacyKey);
    var raw = _get(key);
    if (raw == null && _readsOriginals) {
      key = legacyKey;
      final original = _prefs.get(key);
      raw = original is String ? original : null;
    }
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException catch (e) {
      debugPrint('Saved data "$key" was unreadable, starting fresh (${e.message})');
    }
    return null;
  }

  OutboxEvent _event(
    OutboxKind kind,
    String subject, {
    String? runId,
    int runSeq = 0,
    int rev = 0,
    Map<String, dynamic>? payload,
    bool playtest = false,
  }) =>
      OutboxEvent(
        id: [for (var i = 0; i < 8; i++) _random.nextInt(256).toRadixString(16).padLeft(2, '0')].join(),
        profileId: profileId,
        kind: kind,
        subject: subject,
        epoch: epoch,
        runId: runId,
        runSeq: runSeq,
        rev: rev,
        payload: payload,
        playtest: playtest,
        createdAt: DateTime.now(),
      );

  @override
  GameProgress load([String episodeId = AppConstants.currentEpisodeId]) {
    final json = _read(AppConstants.progressKeyFor(episodeId));
    return json == null ? GameProgress.empty : GameProgress.fromJson(json);
  }

  @override
  Future<void> save(GameProgress progress, [String episodeId = AppConstants.currentEpisodeId]) {
    _saveCase(progress, episodeId, queue: true);
    return Future.value();
  }

  void _saveCase(GameProgress progress, String episodeId, {required bool queue}) {
    final key = _key(AppConstants.progressKeyFor(episodeId));
    final json = jsonEncode(progress.toJson());
    if (_get(key) == json) return;
    _put({
      key: json,
      if (queue)
        _outboxKey: outbox
            .enqueue(_event(
              OutboxKind.caseRun,
              episodeId,
              runId: progress.runId,
              runSeq: progress.runSeq,
              rev: progress.rev,
              playtest: progress.playtest,
            ))
            .encode(),
    });
  }

  @override
  SeasonProgress loadSeason() {
    final json = _read(AppConstants.seasonStorageKey);
    return json == null ? SeasonProgress.empty : SeasonProgress.fromJson(json);
  }

  @override
  Future<void> saveSeason(SeasonProgress season) {
    _saveSeason(season, queue: true);
    return Future.value();
  }

  void _saveSeason(SeasonProgress season, {required bool queue}) {
    final key = _key(AppConstants.seasonStorageKey);
    final json = jsonEncode(season.toJson());
    if (_get(key) == json) return;
    _put({key: json, if (queue) _outboxKey: outbox.enqueue(_event(OutboxKind.season, 'season')).encode()});
  }

  @override
  Wallet? loadWallet() {
    final json = _read(AppConstants.walletStorageKey);
    return json == null ? null : Wallet.fromJson(json);
  }

  @override
  Future<void> saveWallet(Wallet wallet) {
    _saveWallet(wallet, queue: true);
    return Future.value();
  }

  /// Queues every entry not saved before (entries never change: each is
  /// sent once, by its key).
  void _saveWallet(Wallet wallet, {required bool queue}) {
    final key = _key(AppConstants.walletStorageKey);
    final json = jsonEncode(wallet.toJson());
    if (_get(key) == json) return;
    var box = outbox;
    if (queue) {
      final before = loadWallet() ?? Wallet.empty;
      for (final e in wallet.entries) {
        if (!before.has(e.key)) {
          box = box.enqueue(_event(OutboxKind.walletEntry, e.key, payload: e.toJson(), playtest: e.playtest));
        }
      }
    }
    _put({key: json, if (queue) _outboxKey: box.encode()});
  }

  /// Removes this profile's saves only, together with its queued changes:
  /// other profiles and the saves made before profiles stay. The profile
  /// moves to the next epoch. In safe mode the originals stop being read.
  @override
  Future<void> clear() {
    final next = epoch + 1;
    final prefix = AppConstants.profilePrefix(profileId);
    final journal = AppConstants.journalKey(profileId);
    _put({
      for (final k in {..._prefs.getKeys(), ...?_tx?.keys})
        if (k.startsWith(prefix) && k != journal) k: null,
      AppConstants.metaKey(profileId): jsonEncode({'epoch': next}),
      if (legacyFallback) AppConstants.legacyClearedKey(profileId): 'true',
    });
    return Future.value();
  }

  // --- For syncing (no sender yet) ---------------------------------------

  /// The profile's changes waiting to be synced.
  Outbox get outbox => Outbox.decode(_get(_outboxKey));

  /// Changes the outbox (a sender claims, acknowledges or releases events).
  void updateOutbox(Outbox Function(Outbox outbox) change) => _put({_outboxKey: change(outbox).encode()});

  /// The cloud sync bookkeeping (confirmed cloudVersions, back-off), under
  /// its own key: no game save changes for it. A full wipe ([clear]) drops
  /// it with the rest (the next sync then merges with the cloud first).
  CloudSyncMeta get cloudSync => CloudSyncMeta.decode(_get(AppConstants.cloudSyncKey(profileId)));

  /// Changes the bookkeeping; inside [transaction] it commits with the rest
  /// (e.g. a confirmation together with the events it acknowledges).
  void updateCloudSync(CloudSyncMeta Function(CloudSyncMeta meta) change) =>
      _put({AppConstants.cloudSyncKey(profileId): change(cloudSync).encode()});

  /// Saves merged with the other side: stored like any save, and queued
  /// only when [queue] (the other side does not have it yet).
  void saveMerged({String? episodeId, GameProgress? progress, SeasonProgress? season, Wallet? wallet, required bool queue}) =>
      transaction(() {
        if (progress != null) _saveCase(progress, episodeId ?? AppConstants.currentEpisodeId, queue: queue);
        if (season != null) _saveSeason(season, queue: queue);
        if (wallet != null) _saveWallet(wallet, queue: queue);
      });

  /// Sync conflicts kept for a later decision, oldest first.
  List<Map<String, dynamic>> get conflicts {
    final raw = _get(AppConstants.conflictsKey(profileId));
    if (raw == null) return const [];
    try {
      final list = (jsonDecode(raw) as Map)['items'];
      return list is List ? list.whereType<Map<String, dynamic>>().toList() : const [];
    } catch (_) {
      return const [];
    }
  }

  /// Keeps [conflict] (with an `id`); one with the same id is kept once.
  void keepConflict(Map<String, dynamic> conflict) {
    final items = conflicts;
    if (items.any((c) => c['id'] == conflict['id'])) return;
    _put({AppConstants.conflictsKey(profileId): jsonEncode({'items': [...items, conflict]})});
  }

  /// Moves to [newEpoch] (a reset made on another copy of the profile):
  /// every save of the current epoch is first kept as a conflict, then the
  /// saves and queued changes of the old epoch are emptied.
  void adoptEpoch(int newEpoch, {required Iterable<String> episodeIds}) {
    final old = epoch;
    if (newEpoch <= old) return;
    transaction(() {
      final kept = <String, dynamic>{
        for (final id in episodeIds)
          if (_get(_key(AppConstants.progressKeyFor(id))) case final raw?) id: jsonDecode(raw),
        if (_get(_key(AppConstants.seasonStorageKey)) case final raw?) 'season': jsonDecode(raw),
        if (_get(_key(AppConstants.walletStorageKey)) case final raw?) 'wallet': jsonDecode(raw),
      };
      if (kept.isNotEmpty) {
        keepConflict({'id': 'epoch:$old>$newEpoch', 'kind': 'epoch', 'subject': 'profile', 'reason': 'reset elsewhere', 'local': kept});
      }
      _put({
        for (final k in {..._prefs.getKeys(), ...?_tx?.keys})
          if (k.startsWith(AppConstants.profilePrefix(profileId)) &&
              (k.contains('.progress.v1') || k.endsWith('.season.v1') || k.endsWith('.wallet.v1')))
            k: null,
        _outboxKey: null,
        AppConstants.metaKey(profileId): jsonEncode({'epoch': newEpoch}),
      });
    });
  }
}

/// Volatile repository for tests and previews.
class InMemoryProgressRepository implements ProgressRepository {
  InMemoryProgressRepository([GameProgress progress = GameProgress.empty])
      : _progress = {AppConstants.currentEpisodeId: progress};

  final Map<String, GameProgress> _progress;
  SeasonProgress _season = SeasonProgress.empty;
  Wallet? _wallet;

  @override
  GameProgress load([String episodeId = AppConstants.currentEpisodeId]) => _progress[episodeId] ?? GameProgress.empty;

  @override
  Future<void> save(GameProgress progress, [String episodeId = AppConstants.currentEpisodeId]) async =>
      _progress[episodeId] = progress;

  @override
  SeasonProgress loadSeason() => _season;

  @override
  Future<void> saveSeason(SeasonProgress season) async => _season = season;

  @override
  Wallet? loadWallet() => _wallet;

  @override
  Future<void> saveWallet(Wallet wallet) async => _wallet = wallet;

  @override
  Future<void> clear() async {
    _progress.clear();
    _season = SeasonProgress.empty;
    _wallet = null;
  }

  @override
  T transaction<T>(T Function() body) => body();
}
