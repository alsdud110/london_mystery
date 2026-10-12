import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/game_progress.dart';
import '../models/season_progress.dart';
import '../models/wallet.dart';

/// Persists the player's runs so they survive app restarts: one
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

  /// Removes every case save, the season record and the wallet.
  Future<void> clear();
}

class SharedPrefsProgressRepository implements ProgressRepository {
  SharedPrefsProgressRepository(this._prefs);

  final SharedPreferences _prefs;

  /// Plain JSON only — never a polymorphic/object deserializer.
  Map<String, dynamic>? _read(String key) {
    final raw = _prefs.getString(key);
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
  Future<void> save(GameProgress progress, [String episodeId = AppConstants.currentEpisodeId]) =>
      _prefs.setString(AppConstants.progressKeyFor(episodeId), jsonEncode(progress.toJson()));

  @override
  SeasonProgress loadSeason() {
    final json = _read(AppConstants.seasonStorageKey);
    return json == null ? SeasonProgress.empty : SeasonProgress.fromJson(json);
  }

  @override
  Future<void> saveSeason(SeasonProgress season) =>
      _prefs.setString(AppConstants.seasonStorageKey, jsonEncode(season.toJson()));

  @override
  Wallet? loadWallet() {
    final json = _read(AppConstants.walletStorageKey);
    return json == null ? null : Wallet.fromJson(json);
  }

  @override
  Future<void> saveWallet(Wallet wallet) =>
      _prefs.setString(AppConstants.walletStorageKey, jsonEncode(wallet.toJson()));

  @override
  Future<void> clear() async {
    final keys = _prefs
        .getKeys()
        .where((k) => k == AppConstants.progressStorageKey || k.startsWith('${AppConstants.progressStorageKey}.'))
        .toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
    await _prefs.remove(AppConstants.seasonStorageKey);
    await _prefs.remove(AppConstants.walletStorageKey);
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
}
