import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/game_progress.dart';
import '../models/season_progress.dart';
import '../models/wallet.dart';
import 'save_journal.dart';

/// Persists one detective's runs so they survive app restarts: one
/// [GameProgress] per case, the [SeasonProgress] record and the [Wallet].
abstract interface class ProgressRepository {
  GameProgress load([String episodeId = AppConstants.currentEpisodeId]);

  Future<void> save(GameProgress progress, [String episodeId = AppConstants.currentEpisodeId]);

  /// The record of season [seasonId] (Season 1 by default), or an empty
  /// record when that season was never saved.
  SeasonProgress loadSeason([String seasonId = AppConstants.firstSeasonId]);

  Future<void> saveSeason(SeasonProgress season, [String seasonId = AppConstants.firstSeasonId]);

  /// The season the detective was playing, or null when never saved (Season 1).
  String? loadSelectedSeason();

  Future<void> saveSelectedSeason(String seasonId);

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

/// Saves of the detective, under its namespace (`lm.p.<profileId>.…`, the
/// same keys as before profiles otherwise). The saves made before profiles
/// existed are never written or removed here. A save of several keys is
/// stored all or none (see [SaveJournal]); a save that changes nothing
/// writes nothing.
class SharedPrefsProgressRepository implements ProgressRepository {
  SharedPrefsProgressRepository(this._prefs, {required this.profileId, this.legacyFallback = false})
      : _journal = SaveJournal(_prefs, profileId) {
    // A save the app stopped in the middle of is finished first.
    _journal.recover();
  }

  final SharedPreferences _prefs;
  final String profileId;
  final SaveJournal _journal;

  /// Safe mode (see `ProfileSession.legacyFallback`): a save the profile
  /// does not have yet is read from the original saves, until it starts over.
  final bool legacyFallback;

  String _key(String legacyKey) => AppConstants.profileKey(profileId, legacyKey);

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

  bool get _readsOriginals {
    if (!legacyFallback) return false;
    final key = AppConstants.legacyClearedKey(profileId);
    final tx = _tx;
    final cleared = tx != null && tx.containsKey(key) ? tx[key] : _prefs.get(key);
    return cleared != true && cleared != 'true';
  }

  /// Plain JSON only — never a polymorphic/object deserializer. Without
  /// [originals], a save made before profiles is never read (a save that
  /// only profiles have, e.g. a later season's).
  Map<String, dynamic>? _read(String legacyKey, {bool originals = true}) {
    var key = _key(legacyKey);
    var raw = _get(key);
    if (raw == null && originals && _readsOriginals) {
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

  @override
  GameProgress load([String episodeId = AppConstants.currentEpisodeId]) {
    final json = _read(AppConstants.progressKeyFor(episodeId));
    return json == null ? GameProgress.empty : GameProgress.fromJson(json);
  }

  @override
  Future<void> save(GameProgress progress, [String episodeId = AppConstants.currentEpisodeId]) {
    _write(AppConstants.progressKeyFor(episodeId), progress.toJson());
    return Future.value();
  }

  /// Writes [json] under [legacyKey]'s namespaced key, unless it is saved
  /// already exactly so.
  void _write(String legacyKey, Map<String, dynamic> json) {
    final key = _key(legacyKey);
    final encoded = jsonEncode(json);
    if (_get(key) != encoded) _put({key: encoded});
  }

  @override
  SeasonProgress loadSeason([String seasonId = AppConstants.firstSeasonId]) {
    final key = AppConstants.seasonKeyFor(seasonId);
    // Only Season 1 has saves from before profiles (safe mode reads those).
    final json = _read(key, originals: seasonId == AppConstants.firstSeasonId);
    return json == null ? SeasonProgress.empty : SeasonProgress.fromJson(json);
  }

  @override
  Future<void> saveSeason(SeasonProgress season, [String seasonId = AppConstants.firstSeasonId]) {
    _write(AppConstants.seasonKeyFor(seasonId), season.toJson());
    return Future.value();
  }

  @override
  String? loadSelectedSeason() {
    final id = _read(AppConstants.selectedSeasonKey, originals: false)?['seasonId'];
    return id is String && id.isNotEmpty ? id : null;
  }

  @override
  Future<void> saveSelectedSeason(String seasonId) {
    _write(AppConstants.selectedSeasonKey, {'seasonId': seasonId});
    return Future.value();
  }

  @override
  Wallet? loadWallet() {
    final json = _read(AppConstants.walletStorageKey);
    return json == null ? null : Wallet.fromJson(json);
  }

  @override
  Future<void> saveWallet(Wallet wallet) {
    _write(AppConstants.walletStorageKey, wallet.toJson());
    return Future.value();
  }

  /// Removes the detective's saves: the saves made before profiles stay
  /// (only the game master's reset removes those), and so do the case runs
  /// the builds with a cloud kept aside. In safe mode the originals stop
  /// being read.
  @override
  Future<void> clear() {
    final prefix = AppConstants.profilePrefix(profileId);
    final keep = {AppConstants.journalKey(profileId), AppConstants.keptRunsKey(profileId)};
    _put({
      for (final k in {..._prefs.getKeys(), ...?_tx?.keys})
        if (k.startsWith(prefix) && !keep.contains(k)) k: null,
      if (legacyFallback) AppConstants.legacyClearedKey(profileId): 'true',
    });
    return Future.value();
  }
}

/// Volatile repository for tests and previews.
class InMemoryProgressRepository implements ProgressRepository {
  InMemoryProgressRepository([GameProgress progress = GameProgress.empty])
      : _progress = {AppConstants.currentEpisodeId: progress};

  final Map<String, GameProgress> _progress;
  final Map<String, SeasonProgress> _seasons = {};
  String? _selectedSeason;
  Wallet? _wallet;

  @override
  GameProgress load([String episodeId = AppConstants.currentEpisodeId]) => _progress[episodeId] ?? GameProgress.empty;

  @override
  Future<void> save(GameProgress progress, [String episodeId = AppConstants.currentEpisodeId]) async =>
      _progress[episodeId] = progress;

  @override
  SeasonProgress loadSeason([String seasonId = AppConstants.firstSeasonId]) =>
      _seasons[seasonId] ?? SeasonProgress.empty;

  @override
  Future<void> saveSeason(SeasonProgress season, [String seasonId = AppConstants.firstSeasonId]) async =>
      _seasons[seasonId] = season;

  @override
  String? loadSelectedSeason() => _selectedSeason;

  @override
  Future<void> saveSelectedSeason(String seasonId) async => _selectedSeason = seasonId;

  @override
  Wallet? loadWallet() => _wallet;

  @override
  Future<void> saveWallet(Wallet wallet) async => _wallet = wallet;

  @override
  Future<void> clear() async {
    _progress.clear();
    _seasons.clear();
    _selectedSeason = null;
    _wallet = null;
  }

  @override
  T transaction<T>(T Function() body) => body();
}
