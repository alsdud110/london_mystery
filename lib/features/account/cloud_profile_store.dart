import 'package:flutter/foundation.dart';

import '../../data/models/detective_name.dart';
import '../../data/models/profile.dart';

/// Where an account's data lives in Firestore. The same paths as
/// `firebase/firestore.rules` (checked by test/cloud_profile_store_test.dart).
///
///     users/{uid}                        the account
///     users/{uid}/profiles/{profileId}   its detective profiles
///     consents/{uid}                     its consent record (read-only here)
abstract final class CloudPaths {
  static const users = 'users';
  static const profiles = 'profiles';
  static const consents = 'consents';

  static String user(String uid) => '$users/$uid';
  static String profile(String uid, String profileId) => '$users/$uid/$profiles/$profileId';
  static String consent(String uid) => '$consents/$uid';

  /// The document schema these paths are written with.
  static const schema = 1;

  /// A profile's cloud document id is its local id, unchanged.
  static bool validProfileId(String id) => DetectiveProfile.isValidId(id);

  /// Locale and region of the users document ('ko', 'KR').
  static final locale = RegExp(r'^[a-z]{2}$');
  static final region = RegExp(r'^[A-Z]{2}$');

  /// A name as it may be stored (see [DetectiveName]).
  static bool validName(String name) => DetectiveName.isValid(name);
}

/// A detective profile as kept in the account (`users/{uid}/profiles/{id}`).
/// Holds only what the rules allow: no game data before Phase 4.
@immutable
class CloudProfile {
  const CloudProfile({required this.id, required this.detectiveName, this.createdAt});

  /// The local profile's id.
  final String id;
  final String detectiveName;

  /// Set by the server when the profile is made (null until then).
  final DateTime? createdAt;

  @override
  bool operator ==(Object other) =>
      other is CloudProfile && other.id == id && other.detectiveName == detectiveName && other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, detectiveName, createdAt);
}

/// Why a cloud write was not made.
enum CloudWriteResult {
  done,

  /// The account's consent is not confirmed: nothing goes to the cloud.
  consentRequired,

  /// The users document must exist before its profiles.
  noAccountDocument,

  /// Not a valid id, name, locale or region (nothing was sent).
  invalid,

  /// Refused (another account's data, or something the rules do not allow).
  denied,

  /// The cloud could not be reached; nothing was written.
  unavailable,
}

/// The account's documents in the cloud: its users document and its
/// detective profiles. Every write needs the account's confirmed consent
/// (checked here and, independently, by the Firestore rules); a client never
/// writes consent. Game data (cases, season, wallet) is not here yet.
///
/// [uid] must be the signed-in user's id, from the sign-in provider.
abstract interface class CloudProfileStore {
  /// Makes the users document if it is not there yet (server time).
  Future<CloudWriteResult> ensureAccount(String uid, {String locale = 'ko', String region = 'KR'});

  /// Adds a detective profile under the account (server time).
  Future<CloudWriteResult> createProfile(String uid, {required String profileId, required String detectiveName});

  /// Changes a profile's detective name (the only field that may change).
  Future<CloudWriteResult> renameProfile(String uid, {required String profileId, required String detectiveName});

  /// The account's profiles (empty when none, or unreachable).
  Future<List<CloudProfile>> profilesOf(String uid);
}
