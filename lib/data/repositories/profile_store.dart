import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/profile.dart';
import 'legacy_migrator.dart';

/// How the game can start on this device: with its detective
/// ([ProfileSession]), or held until a grown-up says which of several
/// detectives found on the device is this device's ([ProfileHold]).
sealed class DeviceStart {
  const DeviceStart();
}

/// The detective playing now, as the game session was started with it.
@immutable
class ProfileSession extends DeviceStart {
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

/// More than one detective with saved progress was found on the device and
/// nothing says which one is this device's: none is chosen and nothing is
/// removed until a grown-up picks one ([ProfileStore.resolveHold]).
@immutable
class ProfileHold extends DeviceStart {
  const ProfileHold({required this.candidates, required this.others});

  /// The detectives with saved progress, in id order.
  final List<HeldDetective> candidates;

  /// Every other profile found (no progress): kept, never opened.
  final List<String> others;
}

/// A detective found with saved progress (for the grown-up's choice).
@immutable
class HeldDetective {
  const HeldDetective({required this.id, this.name, this.solvedCases = 0, this.lastPlayed});

  final String id;
  final String? name;
  final int solvedCases;
  final DateTime? lastPlayed;
}

/// The device's one detective (`lm.detective.v1`).
class ProfileStore {
  ProfileStore(this._prefs, {Random? random}) : _random = random ?? Random.secure();

  final SharedPreferences _prefs;
  final Random _random;

  /// A new random id: 32 hex digits.
  String newId() => [for (var i = 0; i < 16; i++) _random.nextInt(256).toRadixString(16).padLeft(2, '0')].join();

  /// Null when no record is saved or it cannot be read.
  DetectiveRecord? read() {
    final raw = _prefs.get(AppConstants.detectiveStorageKey);
    if (raw is! String) return null;
    try {
      return DetectiveRecord.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  /// The device's detective as saved (null before the first start, and in
  /// safe mode).
  DetectiveProfile? get profile => read()?.profile;

  Future<bool> write(DetectiveRecord record) =>
      _prefs.setString(AppConstants.detectiveStorageKey, jsonEncode(record.toJson()));

  /// Changes the saved detective. Does nothing while none is saved (the
  /// safe-mode session's profile).
  Future<void> update(DetectiveProfile Function(DetectiveProfile p) change) async {
    final record = read();
    if (record == null) return;
    await write(record.withProfile(change(record.profile)));
  }

  /// How the game starts: the saves made before profiles and the profiles
  /// of the builds with accounts are first brought to the one detective
  /// (read back and verified, see [LegacyMigrator]). Run before the app
  /// starts.
  Future<DeviceStart> bootstrap() => LegacyMigrator(_prefs, this).run();

  /// [bootstrap] without awaiting storage: copies are checked against the
  /// in-memory store only. Only for a session started without [bootstrap]
  /// (tests); after [bootstrap] it just reads the record. A device on hold
  /// has no session yet (StateError).
  ProfileSession ensureActiveSync() => switch (LegacyMigrator(_prefs, this).runSync()) {
        final ProfileSession s => s,
        ProfileHold() => throw StateError('the device detective is on hold'),
      };

  /// A grown-up chose [id] from [hold]: it becomes the device's detective;
  /// every other profile is kept, held, untouched.
  Future<ProfileSession> resolveHold(ProfileHold hold, String id) =>
      LegacyMigrator(_prefs, this).resolve(hold, id);

  /// Removes the saves made before profiles and the record of copying them.
  /// Only for the game master's "next player" reset. Every key is tried even
  /// if one fails; returns false if anything is left, so the caller can say
  /// so and offer to try again (it is safe to repeat). The migration record
  /// stays while no detective record is saved, so a safe-mode session's own
  /// saves are still picked up on the next start.
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
