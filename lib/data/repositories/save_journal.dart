import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

/// Saves several keys of one profile together: after the app is stopped at
/// any moment, the next start sees all of them saved or none.
///
/// Each single key is written whole and in order (the platform commits each
/// write on its own, one after the other), but a save of several keys could
/// stop half way: coins paid with the mission not saved as solved. So a save of several keys first
/// writes all of them into one journal key, then each key, then removes the
/// journal. An unfinished journal found at the next start is written again
/// ([recover]); writing the same values twice changes nothing.
///
/// Every write is started at once: the in-memory store has the new values
/// immediately, as before.
class SaveJournal {
  SaveJournal(this._prefs, this.profileId);

  final SharedPreferences _prefs;
  final String profileId;

  String get _key => AppConstants.journalKey(profileId);

  /// Writes [writes] (a null value removes the key) all or none.
  void commit(Map<String, String?> writes) {
    assert(!writes.containsKey(_key));
    if (writes.isEmpty) return;
    if (writes.length == 1) {
      // One key is written whole anyway.
      _apply(writes);
      return;
    }
    _prefs.setString(_key, jsonEncode({'v': 1, 'writes': writes}));
    _apply(writes);
    _prefs.remove(_key);
  }

  void _apply(Map<String, String?> writes) {
    for (final MapEntry(:key, :value) in writes.entries) {
      if (value == null) {
        _prefs.remove(key);
      } else {
        _prefs.setString(key, value);
      }
    }
  }

  /// Finishes a save the app stopped in the middle of. Returns whether there
  /// was one. A journal that cannot be read was never written whole (a key is
  /// written whole or not at all), so none of its writes had started: it is
  /// dropped.
  bool recover() {
    final raw = _prefs.get(_key);
    if (raw == null) return false;
    Map<String, String?>? writes;
    if (raw is String) {
      try {
        final json = jsonDecode(raw);
        final w = json is Map ? json['writes'] : null;
        if (w is Map) {
          writes = {
            for (final MapEntry(:key, :value) in w.entries)
              if (key is String && key.startsWith(AppConstants.profilePrefix(profileId)) && (value == null || value is String))
                key: value as String?,
          };
        }
      } on FormatException {
        writes = null;
      }
    }
    if (writes == null) {
      debugPrint('An unreadable save journal was dropped');
    } else {
      _apply(writes);
    }
    _prefs.remove(_key);
    return true;
  }
}
