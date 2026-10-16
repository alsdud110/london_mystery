import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/profile.dart';
import '../../data/repositories/profile_store.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/sync/cloud/cloud_codec.dart';
import '../../data/sync/cloud/cloud_store.dart';
import '../../data/sync/cloud/sync_restorer.dart';
import '../account/cloud_profile_store.dart';
import 'sync_scheduler.dart';

/// Why the account's detectives could not be listed or one restored.
enum RestoreProblem {
  /// Not signed in, or the account's consent is not confirmed (on the
  /// device or on the server): nothing is read.
  notAllowed,

  /// The account's deletion has started.
  deletionInProgress,

  /// No connection (or the records changed while they were read): nothing
  /// changed on the device; try again.
  unreachable,

  /// A record of the profile on the server is not valid: nothing changed.
  invalidData,

  /// Signed out, or another account, while restoring: nothing changed.
  accountChanged,

  /// A profile with this id is on the device and is not the account's.
  notYours,
}

/// One of the account's detectives as the server keeps it.
@immutable
class AccountDetective {
  const AccountDetective({required this.id, required this.detectiveName, this.createdAt, required this.onThisDevice});

  final String id;
  final String detectiveName;
  final DateTime? createdAt;

  /// Already on this device (it is chosen like any other, not restored).
  final bool onThisDevice;
}

/// Restores the signed-in account's detectives from the cloud on this device
/// (Phase 4.4): lists them, and brings one down with all its records (its
/// cases, season and coins), checked first, then saved at once, under the
/// same profile id as in the cloud.
///
/// - Only for a signed-in account whose consent is confirmed (on the device
///   and, read first, on the server), never while its deletion runs.
/// - Never during a sync run ([SyncScheduler.exclusive]).
/// - Nothing changes on the device unless every record was read and is
///   valid, and the same account is still signed in when it is saved. The
///   profile appears on the device only after its records are saved.
/// - The guest and the device's other detectives are never touched; a guest's
///   play is never moved to the account (that is a later step, with its own
///   confirmation).
class ProfileRestore {
  ProfileRestore({required this.sync, required this.profiles, required this.repoFor, required this.codec, required this.episodeIds});

  final SyncScheduler sync;
  final ProfileStore profiles;

  /// The saves of a profile on this device (a new one is empty).
  final SharedPrefsProgressRepository Function(String profileId) repoFor;
  final CloudCodec codec;
  final List<String> episodeIds;

  String? _allowedUid() {
    final a = sync.account.value;
    return a.cloudFeaturesAllowed ? a.uid : null;
  }

  /// Reads the account's records first; null when it may go on.
  Future<RestoreProblem?> _check(String uid) async {
    final records = await SyncScheduler.readAccountRecords(sync.store, uid);
    await sync.noteAccountRecords(uid, records);
    return switch (records) {
      AccountRecords.clear => null,
      AccountRecords.deleting => RestoreProblem.deletionInProgress,
      AccountRecords.consentNotConfirmed => RestoreProblem.notAllowed,
    };
  }

  static RestoreProblem _failure(CloudStoreException e) =>
      e.failure == CloudFailure.permissionDenied ? RestoreProblem.notAllowed : RestoreProblem.unreachable;

  /// The signed-in account's detectives on the server, by name. A profile
  /// document that is not valid is left out.
  Future<({List<AccountDetective> detectives, RestoreProblem? problem})> accountDetectives() async {
    final uid = _allowedUid();
    if (uid == null) return (detectives: const <AccountDetective>[], problem: RestoreProblem.notAllowed);
    return sync.exclusive(() async {
      try {
        if (await _check(uid) case final p?) return (detectives: const <AccountDetective>[], problem: p);
        final docs = await sync.store.list(SyncPaths(uid, '').profiles);
        if (sync.account.value.uid != uid) {
          return (detectives: const <AccountDetective>[], problem: RestoreProblem.accountChanged);
        }
        final out = <AccountDetective>[
          for (final MapEntry(key: id, value: doc) in docs.entries)
            if (doc['detectiveName'] case final String name when CloudPaths.validProfileId(id) && CloudPaths.validName(name))
              AccountDetective(
                id: id,
                detectiveName: name,
                createdAt: doc['createdAt'] is DateTime ? doc['createdAt'] as DateTime : null,
                onThisDevice: profiles.profile(id) != null,
              ),
        ]..sort((a, b) => a.detectiveName.compareTo(b.detectiveName));
        return (detectives: out, problem: null);
      } on CloudStoreException catch (e) {
        debugPrint('Restore: detectives not listed (${e.failure.name})');
        return (detectives: const <AccountDetective>[], problem: _failure(e));
      }
    });
  }

  /// Brings [detective] down to this device. Null when it is on the device
  /// now (restored, or found there already as the account's own).
  Future<RestoreProblem?> restore(AccountDetective detective) async {
    final uid = _allowedUid();
    if (uid == null) return RestoreProblem.notAllowed;
    final id = detective.id;
    if (!CloudPaths.validProfileId(id) || !CloudPaths.validName(detective.detectiveName)) return RestoreProblem.invalidData;
    RestoreProblem? onDevice() {
      final here = profiles.profile(id);
      if (here == null) return null;
      return here.kind == ProfileKind.account && here.ownerUid == uid ? null : RestoreProblem.notYours;
    }

    if (profiles.profile(id) != null) return onDevice();
    bool sameAccount() => sync.account.value.uid == uid && sync.account.value.cloudFeaturesAllowed;
    return sync.exclusive(() async {
      final CloudDownload down;
      try {
        if (await _check(uid) case final p?) return p;
        down = await SyncRestorer.download(sync.store, SyncPaths(uid, id), codec);
      } on CloudStoreException catch (e) {
        debugPrint('Restore: records not read (${e.failure.name})');
        return _failure(e);
      }
      if (!sameAccount()) return RestoreProblem.accountChanged;
      switch (down) {
        case DownloadInvalid(:final rejected):
          debugPrint('Restore: ${rejected.length} record(s) not valid; nothing restored');
          return RestoreProblem.invalidData;
        case DownloadChanged():
          return RestoreProblem.unreachable;
        case DownloadOk(:final state):
          // Found on the device meanwhile (another screen): it stays as it is.
          if (profiles.profile(id) != null) return onDevice();
          // Saves first (one save), then the profile: a stop in between
          // leaves saves no profile names, merged again by the next restore.
          SyncRestorer.apply(repoFor(id), state, episodeIds: episodeIds, isStillValid: sameAccount);
          if (!sameAccount()) return RestoreProblem.accountChanged;
          await profiles.addRestored(
            id: id,
            ownerUid: uid,
            detectiveName: detective.detectiveName,
            createdAt: detective.createdAt,
          );
          return null;
      }
    });
  }
}

/// The restore of this build (null: this build does not sync, see
/// `CloudSyncMode`).
final profileRestoreProvider = Provider<ProfileRestore?>((ref) => null);
