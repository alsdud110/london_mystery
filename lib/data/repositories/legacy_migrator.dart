import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/profile.dart';
import 'profile_store.dart';

/// Finds the device's one detective at start, and brings earlier saves to it.
/// Nothing found is ever changed or removed here: only copied.
///
/// - The record (`lm.detective.v1`) is saved: that is the detective.
/// - The profiles of the builds with accounts (`lm.profiles.v1`) are on the
///   device: the one with saved progress becomes the detective (no progress
///   anywhere: the device's guest); the others are kept, held, untouched.
/// - The saves made before profiles (`lm.progress.v1…`, `lm.season.v1`,
///   `lm.wallet.v1`) are copied into the detective's namespace: copy → read
///   back → verify → mark done. Safe to stop at any point and to run again:
///   - a record (`lm.migration.legacy.v1`, state `copying`) names the profile
///     first, so a run cut short continues with the same profile;
///   - a key already in the namespace is kept (it is a copy, or newer
///     progress made in safe mode); only missing or unreadable ones are
///     copied;
///   - the detective record is written only after the copy is verified, then
///     the copy record is marked `done`. Until then the session runs in safe
///     mode ([ProfileSession.legacyFallback]) and the next start tries again.
/// - Two or more profiles with saved progress and nothing that says which is
///   this device's: none is chosen ([ProfileHold]); a grown-up picks one.
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

  Future<DeviceStart> run() async {
    final plan = _start();
    if (!await _flush()) debugPrint('Profile records could not be fully saved');
    if (plan.start != null) return plan.start!;
    _copy(plan);
    final written = await _flush();
    await _prefs.reload(); // verify what storage really holds
    final session = _finish(plan, verified: written && _verify(plan));
    if (!await _flush()) debugPrint('Profile records could not be fully saved');
    return session;
  }

  DeviceStart runSync() {
    final plan = _start();
    if (plan.start != null) return plan.start!;
    _copy(plan);
    return _finish(plan, verified: _verify(plan));
  }

  /// A grown-up chose [id] from [hold] (see [ProfileStore.resolveHold]).
  Future<ProfileSession> resolve(ProfileHold hold, String id) async {
    final ids = [for (final c in hold.candidates) c.id];
    if (!ids.contains(id)) throw ArgumentError.value(id, 'id', 'not one of the detectives found');
    final profile = DetectiveProfile(
      id: id,
      walletBackfill: _has(id, AppConstants.walletStorageKey) ? WalletBackfill.done : WalletBackfill.never,
      detectiveName: _nameFrom((k) => _own(id, k)),
      createdAt: DateTime.now(),
    );
    _writes.add(_store.write(DetectiveRecord(profile: profile, held: [...ids.where((i) => i != id), ...hold.others])));
    if (!await _flush()) debugPrint('Profile records could not be fully saved');
    return ProfileSession(profile: profile);
  }

  _Plan _start() {
    final record = _store.read();
    final marker = _readMarker();
    if (record != null) {
      // Cut short between writing the record and marking the copy done.
      if (marker != null && marker.state == 'copying' && marker.profileId == record.profile.id) {
        _writeMarker(marker.profileId, 'done', marker.keys, startedAt: marker.startedAt);
      }
      return _Plan.ready(ProfileSession(profile: record.profile));
    }
    final registry = _OldRegistry.read(_prefs);
    if (registry != null) return _Plan.ready(_fromRegistry(registry, marker));

    final legacy = ProfileStore.legacyKeys(_prefs).where((k) => _prefs.get(k) is String).toList();
    // No record: saves already under a profile's own keys belong to that
    // profile — never start a new one beside them, never drop one.
    final candidates = _savedProfileIds();
    if (legacy.isEmpty && marker == null && candidates.isEmpty) {
      final fresh = DetectiveProfile(id: _store.newId(), createdAt: DateTime.now());
      _writes.add(_store.write(DetectiveRecord(profile: fresh)));
      return _Plan.ready(ProfileSession(profile: fresh));
    }
    // Which one plays: the one the copy record names; else the only one with
    // progress (or, with none, the first); several with progress and nothing
    // saying which: none — a grown-up chooses.
    String? pid = marker?.profileId;
    if (pid == null) {
      final played = candidates.where(_hasProgress).toList();
      if (played.length > 1) {
        debugPrint('${played.length} detectives with progress found; waiting for a grown-up to choose');
        return _Plan.ready(_hold(played, candidates));
      }
      pid = played.isNotEmpty ? played.single : (candidates.isEmpty ? _store.newId() : candidates.first);
    }
    if (marker == null && legacy.isNotEmpty) _writeMarker(pid, 'copying', legacy, startedAt: DateTime.now());
    return _Plan(
      pid,
      legacy,
      fromLegacy: marker != null || legacy.isNotEmpty,
      // The pay-back is decided while copying; a copy already done (or a
      // profile found without one) is never paid back again.
      mayPayBack: legacy.isNotEmpty && candidates.isEmpty && (marker == null || marker.state == 'copying'),
      others: [for (final id in candidates) if (id != pid) id],
    );
  }

  /// The profiles of the builds with accounts: the device keeps one.
  DeviceStart _fromRegistry(_OldRegistry registry, _Marker? marker) {
    final ids = {...registry.ids, ..._savedProfileIds()}.toList();
    final played = ids.where(_hasProgress).toList()..sort();
    if (played.length > 1) {
      debugPrint('${played.length} detectives with progress found; waiting for a grown-up to choose');
      return _hold(played, ids);
    }
    final pid = played.isNotEmpty ? played.single : registry.guestId ?? registry.activeId;
    final old = registry.entry(pid);
    final profile = DetectiveProfile(
      id: pid,
      origin: ProfileOrigin.byName(old?['origin']),
      walletBackfill: WalletBackfill.byName(old?['walletBackfill']) ?? WalletBackfill.never,
      detectiveName: switch (old?['detectiveName']) {
        final String n when n.isNotEmpty => n,
        _ => _nameFrom((k) => _own(pid, k)),
      },
      createdAt: switch (old?['createdAt']) {
        final String t => DateTime.tryParse(t),
        _ => null,
      },
    );
    _writes.add(_store.write(DetectiveRecord(profile: profile, held: [for (final id in ids) if (id != pid) id])));
    if (marker != null && marker.state == 'copying' && marker.profileId == pid) {
      _writeMarker(pid, 'done', marker.keys, startedAt: marker.startedAt);
    }
    return ProfileSession(profile: profile);
  }

  ProfileHold _hold(List<String> played, List<String> all) => ProfileHold(
        candidates: [
          for (final id in played)
            HeldDetective(
              id: id,
              name: _nameFrom((k) => _own(id, k)),
              solvedCases: _solvedCases(id),
              lastPlayed: _lastPlayed(id),
            ),
        ],
        others: [for (final id in all) if (!played.contains(id)) id],
      );

  static final _profileKey = RegExp(r'^lm\.p\.([0-9a-f]{8,64})\.');

  /// Profiles with saves of their own on the device, in id order.
  List<String> _savedProfileIds() => {
        for (final k in _prefs.getKeys()) ?_profileKey.firstMatch(k)?.group(1),
      }.toList()
        ..sort();

  String? _own(String id, String legacyKey) => switch (_prefs.get(AppConstants.profileKey(id, legacyKey))) {
        final String s => s,
        _ => null,
      };

  bool _has(String id, String legacyKey) => _own(id, legacyKey) != null;

  /// Whether [id] has played anything: a detective named, a case begun or a
  /// mission solved, or a case solved. Coins alone (every new wallet has the
  /// start coins) are not progress.
  bool _hasProgress(String id) {
    if (_solvedCases(id) > 0) return true;
    final prefix = '${AppConstants.profilePrefix(id)}progress.v1';
    for (final k in _prefs.getKeys()) {
      if (!k.startsWith(prefix)) continue;
      final json = _decode(_prefs.get(k) is String ? _prefs.get(k) as String : null);
      if (json == null) continue;
      final name = json['detectiveName'];
      final done = json['completedMissionIds'];
      if ((name is String && name.isNotEmpty) || json['introSeen'] == true || (done is List && done.isNotEmpty)) {
        return true;
      }
    }
    return false;
  }

  int _solvedCases(String id) => switch (_decode(_own(id, AppConstants.seasonStorageKey))?['solvedEpisodeIds']) {
        final List l => l.length,
        _ => 0,
      };

  /// The latest time in [id]'s saves (a coin entry, a case started or
  /// solved, a mission opened), or null when none has one.
  DateTime? _lastPlayed(String id) {
    DateTime? last;
    void see(Object? v) {
      final t = v is String ? DateTime.tryParse(v) : null;
      if (t != null && (last == null || t.isAfter(last!))) last = t;
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
      final own = _own(pid, legacyKey);
      if (own != null) return own;
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
    );
    if (!verified) {
      debugPrint('Copying the saved game could not be verified; playing from the original saves this time');
      return ProfileSession(profile: profile, legacyFallback: true);
    }
    // The other profiles found are kept whole, held.
    _writes.add(_store.write(DetectiveRecord(profile: profile, held: plan.others)));
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

/// The list of detectives the builds with accounts kept (`lm.profiles.v1`),
/// read as plain JSON. Never written.
class _OldRegistry {
  _OldRegistry(this.entries, this.activeId);

  final List<Map<dynamic, dynamic>> entries;
  final String activeId;

  List<String> get ids => [for (final e in entries) e['id'] as String];

  Map<dynamic, dynamic>? entry(String id) {
    for (final e in entries) {
      if (e['id'] == id) return e;
    }
    return null;
  }

  /// The device's guest: the profile that played without an account.
  String? get guestId {
    for (final e in entries) {
      if ((e['kind'] ?? 'guest') == 'guest' && e['ownerUid'] == null) return e['id'] as String;
    }
    return null;
  }

  static _OldRegistry? read(SharedPreferences prefs) {
    final raw = prefs.get(AppConstants.profilesStorageKey);
    if (raw is! String) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map || json['profiles'] is! List) return null;
      final entries = <Map<dynamic, dynamic>>[];
      for (final e in json['profiles'] as List) {
        if (e is Map && DetectiveProfile.isValidId(e['id']) && !entries.any((q) => q['id'] == e['id'])) entries.add(e);
      }
      if (entries.isEmpty) return null;
      final active = json['activeProfileId'];
      return _OldRegistry(entries, entries.any((e) => e['id'] == active) ? active as String : entries.first['id'] as String);
    } on FormatException {
      return null;
    }
  }
}

class _Plan {
  _Plan(this.profileId, this.legacy, {required this.fromLegacy, required this.mayPayBack, this.others = const []})
      : start = null;

  _Plan.ready(DeviceStart this.start)
      : profileId = '',
        legacy = const [],
        fromLegacy = false,
        mayPayBack = false,
        others = const [];

  final DeviceStart? start;
  final String profileId;
  final List<String> legacy;

  /// The profile holds (or is getting) the saves from before profiles.
  final bool fromLegacy;

  /// A save from before coins may still be paid back once.
  final bool mayPayBack;

  /// The other profiles found (kept, held).
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
