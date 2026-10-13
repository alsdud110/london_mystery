import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/profile.dart';
import 'profile_store.dart';

/// Moves the saves made before profiles existed (`lm.progress.v1…`,
/// `lm.season.v1`, `lm.wallet.v1`) into the guest profile's namespace:
/// copy → read back → verify → mark done. The originals are never changed
/// or removed here.
///
/// Safe to stop at any point and to run again:
/// - a record (`lm.migration.legacy.v1`, state `copying`) names the profile
///   first, so a run cut short continues with the same profile;
/// - a key already in the namespace is kept (it is a copy, or newer progress
///   made in safe mode); only missing or unreadable ones are copied;
/// - the registry is written only after the copy is verified, then the
///   record is marked `done`. Until then the session runs in safe mode
///   ([ProfileSession.legacyFallback]) and the next start tries again;
/// - with the registry and the record both unreadable, the profile whose
///   own saves are on the device is continued, not replaced by a new one.
class LegacyMigrator {
  LegacyMigrator(this._prefs, this._store);

  final SharedPreferences _prefs;
  final ProfileStore _store;

  final List<Future<bool>> _writes = [];

  /// Waits for every write so far; false if any of them failed.
  Future<bool> _flush() async {
    final results = await Future.wait(_writes);
    _writes.clear();
    return results.every((ok) => ok);
  }

  void _setString(String key, String value) => _writes.add(_prefs.setString(key, value));

  Future<ProfileSession> run() async {
    final plan = _start();
    if (!await _flush()) debugPrint('Profile records could not be fully saved');
    if (plan.session != null) return plan.session!;
    _copy(plan);
    final written = await _flush();
    await _prefs.reload(); // verify what storage really holds
    final session = _finish(plan, verified: written && _verify(plan));
    if (!await _flush()) debugPrint('Profile records could not be fully saved');
    return session;
  }

  ProfileSession runSync() {
    final plan = _start();
    if (plan.session != null) return plan.session!;
    _copy(plan);
    return _finish(plan, verified: _verify(plan));
  }

  _Plan _start() {
    final registry = _store.read();
    final marker = _readMarker();
    if (registry != null) {
      // Cut short between writing the registry and marking the copy done.
      if (marker != null && marker.state == 'copying' && registry.byId(marker.profileId) != null) {
        _writeMarker(marker.profileId, 'done', marker.keys, startedAt: marker.startedAt);
      }
      return _Plan.ready(ProfileSession(profile: registry.active));
    }
    final legacy = ProfileStore.legacyKeys(_prefs).where((k) => _prefs.get(k) is String).toList();
    // No registry: saves already under a profile's own keys belong to that
    // profile — never start a new one beside them, never drop one.
    final candidates = _savedProfileIds();
    if (legacy.isEmpty && marker == null && candidates.isEmpty) {
      final guest = DetectiveProfile(id: _store.newId(), createdAt: DateTime.now());
      _writes.add(_store.write(ProfileRegistry(activeProfileId: guest.id, profiles: [guest])));
      return _Plan.ready(ProfileSession(profile: guest));
    }
    // Which one plays: the one the copy record names; else the only one;
    // else (several, nothing says which) the one played last — and then all
    // of them wait for a grown-up's review before anything is synced.
    final ambiguous = marker == null && candidates.length > 1;
    if (ambiguous) debugPrint('Profile records were unreadable; ${candidates.length} saved profiles kept for review');
    final pid = marker?.profileId ??
        (candidates.isEmpty ? _store.newId() : (ambiguous ? _playedLast(candidates) : candidates.single));
    if (marker == null && legacy.isNotEmpty) _writeMarker(pid, 'copying', legacy, startedAt: DateTime.now());
    return _Plan(
      pid,
      legacy,
      fromLegacy: marker != null || legacy.isNotEmpty,
      // The pay-back is decided while copying; a copy already done (or a
      // profile found without one) is never paid back again.
      mayPayBack: legacy.isNotEmpty && candidates.isEmpty && (marker == null || marker.state == 'copying'),
      review: ambiguous,
      others: [for (final id in candidates) if (id != pid) id],
    );
  }

  static final _profileKey = RegExp(r'^lm\.p\.([0-9a-f]{8,64})\.');

  /// Profiles with saves of their own on the device, in id order.
  List<String> _savedProfileIds() => {
        for (final k in _prefs.getKeys()) ?_profileKey.firstMatch(k)?.group(1),
      }.toList()
        ..sort();

  /// The profile whose saves carry the latest time (a coin entry, a case
  /// started or solved, a mission opened); the first id when none has one.
  String _playedLast(List<String> ids) {
    DateTime latest(String id) {
      var last = DateTime.fromMillisecondsSinceEpoch(0);
      void see(Object? v) {
        final t = v is String ? DateTime.tryParse(v) : null;
        if (t != null && t.isAfter(last)) last = t;
      }

      for (final k in _prefs.getKeys()) {
        if (!k.startsWith(AppConstants.profilePrefix(id))) continue;
        final json = _decode(_prefs.get(k) is String ? _prefs.get(k) as String : null);
        if (json == null) continue;
        see(json['startedAt']);
        see(json['completedAt']);
        if (json['missionStartedAt'] case final Map m) m.values.forEach(see);
        if (json['entries'] case final List entries) {
          for (final e in entries) {
            if (e is Map) see(e['at']);
          }
        }
      }
      return last;
    }

    var best = ids.first;
    for (final id in ids.skip(1)) {
      if (latest(id).isAfter(latest(best))) best = id;
    }
    return best;
  }

  void _copy(_Plan plan) {
    final cleared = _prefs.get(AppConstants.legacyClearedKey(plan.profileId));
    plan.cleared = cleared == true || cleared == 'true';
    if (plan.cleared) return; // the detective started over in safe mode
    for (final k in plan.legacy) {
      final existing = _prefs.get(AppConstants.profileKey(plan.profileId, k));
      if (existing is String && _readable(existing)) continue;
      _setString(AppConstants.profileKey(plan.profileId, k), _prefs.get(k) as String);
      plan.copied.add(k);
    }
  }

  /// Makes every verification fail, to test safe mode.
  @visibleForTesting
  static bool simulateVerifyFailure = false;

  bool _verify(_Plan plan) {
    if (simulateVerifyFailure) return false;
    if (plan.cleared) return true;
    for (final k in plan.legacy) {
      final copy = _prefs.get(AppConstants.profileKey(plan.profileId, k));
      if (copy is! String) return false;
      if (plan.copied.contains(k) && copy != _prefs.get(k)) return false;
    }
    return true;
  }

  ProfileSession _finish(_Plan plan, {required bool verified}) {
    final pid = plan.profileId;
    String? read(String legacyKey) {
      final own = _prefs.get(AppConstants.profileKey(pid, legacyKey));
      if (own is String) return own;
      if (verified || plan.cleared) return null;
      final original = _prefs.get(legacyKey);
      return original is String ? original : null;
    }

    final hasWallet = read(AppConstants.walletStorageKey) != null || plan.cleared;
    final profile = DetectiveProfile(
      id: pid,
      origin: plan.fromLegacy ? ProfileOrigin.legacy : ProfileOrigin.fresh,
      walletBackfill: hasWallet
          ? WalletBackfill.done
          : plan.mayPayBack
              ? WalletBackfill.pending
              : WalletBackfill.never,
      detectiveName: _nameFrom(read),
      createdAt: DateTime.now(),
      needsReview: plan.review,
    );
    if (!verified) {
      debugPrint('Copying the saved game could not be verified; playing from the original saves this time');
      return ProfileSession(profile: profile, legacyFallback: true);
    }
    // The other profiles found are kept whole, waiting for a review.
    final others = [
      for (final id in plan.others)
        DetectiveProfile(
          id: id,
          walletBackfill: _prefs.get(AppConstants.profileKey(id, AppConstants.walletStorageKey)) is String
              ? WalletBackfill.done
              : WalletBackfill.never,
          detectiveName: _nameFrom((k) => switch (_prefs.get(AppConstants.profileKey(id, k))) {
                final String s => s,
                _ => null,
              }),
          createdAt: DateTime.now(),
          needsReview: true,
        ),
    ];
    _writes.add(_store.write(ProfileRegistry(activeProfileId: pid, profiles: [profile, ...others])));
    if (plan.fromLegacy) _writeMarker(pid, 'done', plan.legacy, startedAt: _readMarker()?.startedAt);
    return ProfileSession(profile: profile);
  }

  /// The detective's name: from the open case's save, else the first case
  /// save that has one.
  static String? _nameFrom(String? Function(String legacyKey) read) {
    String? nameIn(String? raw) {
      final json = _decode(raw);
      final name = json?['detectiveName'];
      return name is String && name.isNotEmpty ? name : null;
    }

    final active = _decode(read(AppConstants.seasonStorageKey))?['activeEpisodeId'];
    if (active is String && active.isNotEmpty) {
      final name = nameIn(read(AppConstants.progressKeyFor(active)));
      if (name != null) return name;
    }
    for (var n = 1; n <= 99; n++) {
      final id = 'ep${n.toString().padLeft(2, '0')}';
      final name = nameIn(read(AppConstants.progressKeyFor(id)));
      if (name != null) return name;
    }
    return null;
  }

  static Map<String, dynamic>? _decode(String? raw) {
    if (raw == null) return null;
    try {
      final v = jsonDecode(raw);
      return v is Map<String, dynamic> ? v : null;
    } on FormatException {
      return null;
    }
  }

  static bool _readable(String raw) => _decode(raw) != null;

  _Marker? _readMarker() {
    final raw = _prefs.get(AppConstants.legacyMigrationKey);
    final json = raw is String ? _decode(raw) : null;
    if (json == null) return null;
    final pid = json['profileId'];
    if (!DetectiveProfile.isValidId(pid)) return null;
    final keys = json['keys'];
    final started = json['startedAt'];
    return _Marker(
      profileId: pid as String,
      state: json['state'] == 'done' ? 'done' : 'copying',
      keys: keys is List ? keys.whereType<String>().toList() : const [],
      startedAt: started is String ? DateTime.tryParse(started) : null,
    );
  }

  void _writeMarker(String pid, String state, List<String> keys, {DateTime? startedAt}) => _setString(
        AppConstants.legacyMigrationKey,
        jsonEncode({
          'state': state,
          'profileId': pid,
          'keys': keys,
          if (startedAt != null) 'startedAt': startedAt.toIso8601String(),
          if (state == 'done') 'doneAt': DateTime.now().toIso8601String(),
        }),
      );
}

class _Plan {
  _Plan(
    this.profileId,
    this.legacy, {
    required this.fromLegacy,
    required this.mayPayBack,
    this.review = false,
    this.others = const [],
  }) : session = null;

  _Plan.ready(this.session)
      : profileId = session!.profileId,
        legacy = const [],
        fromLegacy = false,
        mayPayBack = false,
        review = false,
        others = const [];

  final ProfileSession? session;
  final String profileId;
  final List<String> legacy;

  /// The profile holds (or is getting) the saves from before profiles.
  final bool fromLegacy;

  /// A save from before coins may still be paid back once.
  final bool mayPayBack;

  /// Several profiles were found and nothing said which plays: every one of
  /// them waits for a review before it may be synced.
  final bool review;

  /// The other profiles found (kept, waiting for a review).
  final List<String> others;
  final Set<String> copied = {};
  bool cleared = false;
}

@immutable
class _Marker {
  const _Marker({required this.profileId, required this.state, required this.keys, this.startedAt});

  final String profileId;
  final String state;
  final List<String> keys;
  final DateTime? startedAt;
}
