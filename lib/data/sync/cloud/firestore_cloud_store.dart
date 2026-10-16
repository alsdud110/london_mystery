import 'package:cloud_firestore/cloud_firestore.dart';

import 'cloud_codec.dart';
import 'cloud_store.dart';

/// [CloudStore] on the Firestore plugin. Create only once Firebase is ready
/// (`CloudBootstrap.requireReady`) — or pointed at the emulator in tests.
class FirestoreCloudStore implements CloudStore {
  FirestoreCloudStore(this._db);

  final FirebaseFirestore _db;

  @override
  Future<T> runTransaction<T>(Future<T> Function(CloudTx tx) body) =>
      _guard(() => _db.runTransaction((t) => body(_Tx(_db, t)), maxAttempts: 5));

  @override
  Future<Map<String, Object?>?> get(String path) => _guard(() async {
        final snap = await _db.doc(path).get(const GetOptions(source: Source.server));
        return snap.exists ? fromFirestore(snap.data()!) : null;
      });

  @override
  Future<Map<String, Map<String, Object?>>> list(String path) => _guard(() async {
        final snap = await _db.collection(path).get(const GetOptions(source: Source.server));
        return {for (final d in snap.docs) d.id: fromFirestore(d.data())};
      });

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FirebaseException catch (e) {
      throw CloudStoreException(failureOf(e.code), e.code);
    }
  }

  /// Firestore error codes → [CloudFailure].
  static CloudFailure failureOf(String code) => switch (code) {
        'permission-denied' || 'unauthenticated' => CloudFailure.permissionDenied,
        'aborted' || 'failed-precondition' => CloudFailure.aborted,
        'unavailable' || 'deadline-exceeded' || 'cancelled' || 'internal' || 'resource-exhausted' =>
          CloudFailure.unavailable,
        _ => CloudFailure.unknown,
      };

  /// Plugin values → plain values (Timestamp → DateTime, recursively).
  static Map<String, Object?> fromFirestore(Map<String, dynamic> data) =>
      {for (final e in data.entries) e.key: _plain(e.value)};

  static Object? _plain(Object? v) => switch (v) {
        Timestamp t => t.toDate().toUtc(),
        Map m => {for (final e in m.entries) e.key as String: _plain(e.value)},
        List l => [for (final x in l) _plain(x)],
        _ => v,
      };

  /// Plain values → plugin values (DateTime → Timestamp, the server-time
  /// placeholder → a server timestamp).
  static Map<String, Object?> toFirestore(Map<String, Object?> data) =>
      {for (final e in data.entries) e.key: _store(e.value)};

  static Object? _store(Object? v) => switch (v) {
        CloudServerTime _ => FieldValue.serverTimestamp(),
        DateTime d => Timestamp.fromDate(d),
        Map m => {for (final e in m.entries) e.key as String: _store(e.value)},
        List l => [for (final x in l) _store(x)],
        _ => v,
      };
}

class _Tx implements CloudTx {
  _Tx(this._db, this._t);

  final FirebaseFirestore _db;
  final Transaction _t;

  @override
  Future<Map<String, Object?>?> get(String path) async {
    final snap = await _t.get(_db.doc(path));
    return snap.exists ? FirestoreCloudStore.fromFirestore(snap.data()!) : null;
  }

  @override
  void set(String path, Map<String, Object?> data) => _t.set(_db.doc(path), FirestoreCloudStore.toFirestore(data));
}
