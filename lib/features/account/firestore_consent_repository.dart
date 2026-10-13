import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'cloud_profile_store.dart';
import 'consent.dart';

/// Reads an account's consent from its trusted record, `consents/{uid}`.
///
/// The record is written only by a trusted backend; the app reads it and
/// never writes it (the Firestore rules refuse any client write). Anything
/// but a record saying exactly `status: 'confirmed'` — no record, another
/// value, a read refused or failed, offline — is [ConsentStatus.unconfirmed]:
/// it fails closed. Create only after Firebase is ready.
class FirestoreConsentRepository implements ConsentRepository {
  FirestoreConsentRepository(FirebaseFirestore db)
      : _read = ((uid) async => (await db.doc(CloudPaths.consent(uid)).get()).data());

  /// [read] returns the record's fields (null: no record); for tests.
  @visibleForTesting
  FirestoreConsentRepository.withReader(Future<Map<String, Object?>?> Function(String uid) read) : _read = read;

  final Future<Map<String, Object?>?> Function(String uid) _read;

  /// The status a record says (null: no record).
  static ConsentStatus statusFrom(Map<String, Object?>? record) =>
      record?['status'] == 'confirmed' ? ConsentStatus.confirmed : ConsentStatus.unconfirmed;

  @override
  Future<ConsentStatus> statusOf(String uid) async {
    if (uid.isEmpty) return ConsentStatus.unconfirmed;
    try {
      return statusFrom(await _read(uid));
    } catch (e) {
      // Refused, offline, or not reachable: not confirmed. The code only.
      debugPrint('Consent: read failed (${e is FirebaseException ? e.code : e.runtimeType})');
      return ConsentStatus.unconfirmed;
    }
  }
}
