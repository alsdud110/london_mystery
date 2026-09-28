import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/game_progress.dart';

/// Persists the player's run so it survives app restarts.
abstract interface class ProgressRepository {
  GameProgress load();

  Future<void> save(GameProgress progress);

  Future<void> clear();
}

class SharedPrefsProgressRepository implements ProgressRepository {
  SharedPrefsProgressRepository(this._prefs);

  final SharedPreferences _prefs;

  @override
  GameProgress load() {
    final raw = _prefs.getString(AppConstants.progressStorageKey);
    if (raw == null) return GameProgress.empty;
    try {
      // Plain JSON only — never a polymorphic/object deserializer.
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return GameProgress.fromJson(decoded);
    } on FormatException catch (e) {
      debugPrint('Saved progress was unreadable, starting fresh (${e.message})');
    }
    return GameProgress.empty;
  }

  @override
  Future<void> save(GameProgress progress) =>
      _prefs.setString(AppConstants.progressStorageKey, jsonEncode(progress.toJson()));

  @override
  Future<void> clear() => _prefs.remove(AppConstants.progressStorageKey);
}

/// Volatile repository for tests and previews.
class InMemoryProgressRepository implements ProgressRepository {
  InMemoryProgressRepository([this._progress = GameProgress.empty]);

  GameProgress _progress;

  @override
  GameProgress load() => _progress;

  @override
  Future<void> save(GameProgress progress) async => _progress = progress;

  @override
  Future<void> clear() async => _progress = GameProgress.empty;
}
