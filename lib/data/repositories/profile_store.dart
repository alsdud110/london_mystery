import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/profile.dart';
import 'legacy_migrator.dart';

/// The detective playing now, as the game session was started with it.
@immutable
class ProfileSession {
  const ProfileSession({required this.profile, this.legacyFallback = false});

  /// The profile at the start of the session. While [legacyFallback] is on it
  /// exists only here (nothing about it is saved yet).
  final DetectiveProfile profile;

  /// Safe mode: copying the saves made before profiles existed could not be
  /// verified, so the session reads them where they are (its own saves first)
  /// and the copy is tried again on the next start. Nothing is lost.
  final bool legacyFallback;

  String get profileId => profile.id;
}

/// The detectives of this device (`lm.profiles.v1`) and which one is playing.
class ProfileStore {
  ProfileStore(this._prefs, {Random? random}) : _random = random ?? Random.secure();

  final SharedPreferences _prefs;
  final Random _random;

  /// A new random id: 32 hex digits.
  String newId() => [for (var i = 0; i < 16; i++) _random.nextInt(256).toRadixString(16).padLeft(2, '0')].join();

  /// Null when no registry is saved or it cannot be read.
  ProfileRegistry? read() {
    final raw = _prefs.get(AppConstants.profilesStorageKey);
    if (raw is! String) return null;
    try {
      return ProfileRegistry.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  DetectiveProfile? profile(String id) => read()?.byId(id);

  Future<bool> write(ProfileRegistry registry) =>
      _prefs.setString(AppConstants.profilesStorageKey, jsonEncode(registry.toJson()));

  /// Changes a saved profile. Does nothing for a profile that is not saved
  /// (the safe-mode session's profile).
  Future<void> update(String id, DetectiveProfile Function(DetectiveProfile p) change) async {
    final registry = read();
    final p = registry?.byId(id);
    if (registry == null || p == null) return;
    await write(registry.upsert(change(p)));
  }

  Future<void> setActive(String id) async {
    final registry = read();
    if (registry == null) throw StateError('no profiles saved');
    await write(registry.withActive(id));
  }

  /// Adds a profile (not made active). One guest per device: a second guest
  /// is refused. There is no screen for this yet; account profiles come with
  /// user accounts.
  Future<DetectiveProfile> addProfile({
    ProfileKind kind = ProfileKind.account,
    String? detectiveName,
    String? ownerUid,
  }) async {
    final registry = read();
    if (registry == null) throw StateError('no profiles saved');
    if (kind == ProfileKind.guest && registry.profiles.any((p) => p.kind == ProfileKind.guest)) {
      throw StateError('this device already has a guest detective');
    }
    final p = DetectiveProfile(
      id: newId(),
      kind: kind,
      detectiveName: detectiveName,
      createdAt: DateTime.now(),
      ownerUid: ownerUid,
    );
    await write(registry.upsert(p));
    return p;
  }

  /// The profiles that may be opened with [signedInUid] signed in: the guest,
  /// and that account's own. Another account's profiles are not listed.
  List<DetectiveProfile> openableBy(String? signedInUid) =>
      [for (final p in read()?.profiles ?? const <DetectiveProfile>[]) if (p.mayOpen(signedInUid)) p];

  /// The device's guest (the profile every session can fall back to).
  DetectiveProfile? get guest {
    for (final p in read()?.profiles ?? const <DetectiveProfile>[]) {
      if (p.kind == ProfileKind.guest && p.ownerUid == null) return p;
    }
    return null;
  }

  /// The profile to play at app start, with saves from before profiles
  /// copied, read back from storage and verified first (see
  /// [LegacyMigrator]). Run before the app starts.
  Future<ProfileSession> bootstrap() async {
    final session = await LegacyMigrator(_prefs, this).run();
    final id = installId;
    if (id == null) await _prefs.setString(AppConstants.deviceStorageKey, _deviceRecord());
    return _openableAtStart(session);
  }

  /// [bootstrap] without awaiting storage: copies are checked against the
  /// in-memory store only. Only a fallback for a session started without
  /// [bootstrap] (tests); after [bootstrap] it just reads the registry.
  ProfileSession ensureActiveSync() {
    final session = LegacyMigrator(_prefs, this).runSync();
    if (installId == null) _prefs.setString(AppConstants.deviceStorageKey, _deviceRecord());
    return _openableAtStart(session);
  }

  /// At start nobody is signed in yet (the session comes back later, if at
  /// all): an account's profile left open does not open; the guest does.
  ProfileSession _openableAtStart(ProfileSession session) {
    if (session.profile.mayOpen(null)) return session;
    final g = guest;
    if (g == null) throw StateError('no guest profile to fall back to');
    final registry = read();
    if (registry != null) write(registry.withActive(g.id));
    return ProfileSession(profile: g);
  }

  /// This installation of the app: a random id made once at the first start
  /// (`lm.device.v1`), gone when the app is removed. It tells installations
  /// apart when a guest's saves are linked to a user account later.
  ///
  /// It proves nothing: never use it to sign anyone in, to grant access, or
  /// as a secret — anyone can read or copy it.
  String? get installId {
    final raw = _prefs.get(AppConstants.deviceStorageKey);
    if (raw is! String) return null;
    try {
      final id = (jsonDecode(raw) as Map)['installId'];
      return DetectiveProfile.isValidId(id) ? id as String : null;
    } catch (_) {
      return null;
    }
  }

  String _deviceRecord() =>
      jsonEncode({'schema': 1, 'installId': newId(), 'createdAt': DateTime.now().toIso8601String()});

  /// Removes the saves made before profiles existed and the record of
  /// copying them. Only for the game master's "next player" reset. Every key
  /// is tried even if one fails; returns false if anything is left, so the
  /// caller can say so and offer to try again (it is safe to repeat). The
  /// migration record stays while no registry is saved, so a safe-mode
  /// session's own saves are still picked up on the next start.
  Future<bool> wipeLegacy() async {
    var ok = true;
    Future<void> remove(String key) async {
      try {
        if (!await _prefs.remove(key)) ok = false;
      } catch (e) {
        debugPrint('Could not remove a saved record (${e.runtimeType})');
        ok = false;
      }
    }

    for (final k in legacyKeys(_prefs)) {
      await remove(k);
    }
    if (read() != null) await remove(AppConstants.legacyMigrationKey);
    return ok && legacyKeys(_prefs).isEmpty;
  }

  /// The saves made before profiles existed that are still on the device.
  static List<String> legacyKeys(SharedPreferences prefs) =>
      prefs.getKeys().where(AppConstants.isLegacySaveKey).toList()..sort();
}
