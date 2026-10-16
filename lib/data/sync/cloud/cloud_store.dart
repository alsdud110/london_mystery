import 'package:flutter/foundation.dart';

// Phase 4.3A: the sender's view of the cloud. Documents are plain maps:
// timestamps as DateTime, and `CloudServerTime.instance` in a write for "the
// server's time". Implementations: `FirestoreCloudStore` (the app, plugin)
// and the emulator store of the tests (REST, same rules).

/// Why a cloud call failed. The sender decides from this alone.
enum CloudFailure {
  /// The rules refused (consent, deletion, a check). Nothing was written.
  permissionDenied,

  /// The transaction lost a race and could not be retried in time.
  aborted,

  /// No connection, a timeout, or a server error: the outcome of a write
  /// may be unknown (it may have committed). Retry with the same ids.
  unavailable,

  /// Anything else.
  unknown,
}

class CloudStoreException implements Exception {
  const CloudStoreException(this.failure, [this.detail = '']);

  final CloudFailure failure;

  /// A short code for logs (never data).
  final String detail;

  @override
  String toString() => 'CloudStoreException(${failure.name}${detail.isEmpty ? '' : ', $detail'})';
}

/// One transaction's reads and writes. Reads come first; writes are applied
/// only if the whole transaction commits.
abstract interface class CloudTx {
  /// The document at [path], or null when there is none.
  Future<Map<String, Object?>?> get(String path);

  /// Writes the whole document at [path] (create or replace).
  void set(String path, Map<String, Object?> data);
}

abstract interface class CloudStore {
  /// Runs [body] in a transaction; the store may run it more than once
  /// (contention). [body] must not change anything outside the transaction:
  /// it only reads, decides and writes through [CloudTx], and returns what
  /// the caller applies after the commit.
  Future<T> runTransaction<T>(Future<T> Function(CloudTx tx) body);

  /// The document at [path] outside a transaction (null: none).
  Future<Map<String, Object?>?> get(String path);

  /// The documents directly in the collection at [path], by document id
  /// (empty: none), read from the server (never a cache).
  Future<Map<String, Map<String, Object?>>> list(String path);
}

/// Firestore paths of one profile's sync documents
/// (`users/{uid}/profiles/{pid}/…`, see firebase/firestore.rules).
@immutable
class SyncPaths {
  const SyncPaths(this.uid, this.profileId);

  final String uid;
  final String profileId;

  String get user => 'users/$uid';

  /// The account's detective profiles (a collection).
  String get profiles => 'users/$uid/profiles';
  String get profile => _base;
  String get _base => 'users/$uid/profiles/$profileId';
  String get meta => '$_base/sync/meta';
  String caseDoc(String caseId) => '$_base/cases/$caseId';

  /// The profile's case documents (a collection).
  String get cases => '$_base/cases';
  String get season => '$_base/season/state';
  String walletEvent(String eventId) => '$_base/wallet/$eventId';
  String get walletSummary => '$_base/wallet/summary';

  /// The coin events and the summary (a collection).
  String get wallet => '$_base/wallet';
  String get consent => 'consents/$uid';
  String get deletion => 'deletions/$uid';
}
