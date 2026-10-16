import 'dart:convert';
import 'dart:io';

import 'package:london_mystery/data/sync/cloud/cloud_codec.dart';
import 'package:london_mystery/data/sync/cloud/cloud_store.dart';

// Test stores for the sync sender (Phase 4.3A):
// - [EmulatorCloudStore]: the Firestore emulator over REST, as a signed-in
//   user (so firebase/firestore.rules apply), with optimistic transactions
//   like the mobile SDKs: reads remembered, re-checked at commit, writes
//   with preconditions; a lost race reruns the body (up to 5 times).
// - [MemoryCloudStore]: the same transaction semantics in memory (no rules),
//   for fast tests of the sender's logic.
// - [FaultyStore]: wraps either to inject failures, lost answers and races.

const emulatorProject = 'demo-london-mystery';

/// The emulator's host:port, or null when the tests run without it.
String? get emulatorHost => Platform.environment['FIRESTORE_EMULATOR_HOST'];

/// An unsigned emulator ID token for [uid] (the emulator accepts these).
String emulatorToken(String uid, {DateTime? authTime}) {
  String b64(Map<String, Object?> m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final auth = (authTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch) ~/ 1000;
  return '${b64({'alg': 'none', 'kid': 'fakekid', 'typ': 'JWT'})}.${b64({
    'iss': 'https://securetoken.google.com/$emulatorProject',
    'aud': emulatorProject,
    'iat': now,
    'exp': now + 3600,
    'auth_time': auth,
    'sub': uid,
    'user_id': uid,
    'firebase': {'sign_in_provider': 'password', 'identities': <String, Object?>{}},
  })}.';
}

class EmulatorCloudStore implements CloudStore {
  /// As user [uid]; `null` uid = the admin ("owner": rules bypassed, for
  /// seeding the trusted records only).
  EmulatorCloudStore(this.uid, {this.maxAttempts = 5});

  final String? uid;
  final int maxAttempts;
  final _http = HttpClient();

  String get _docs => 'http://$emulatorHost/v1/projects/$emulatorProject/databases/(default)/documents';

  String _name(String path) => 'projects/$emulatorProject/databases/(default)/documents/$path';

  Future<(int, Map<String, Object?>)> _call(String method, String url, [Object? body]) async {
    try {
      final req = await _http.openUrl(method, Uri.parse(url));
      req.headers.set('Authorization', 'Bearer ${uid == null ? 'owner' : emulatorToken(uid!)}');
      if (body != null) {
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode(body));
      }
      final res = await req.close();
      final text = await res.transform(utf8.decoder).join();
      return (res.statusCode, text.isEmpty ? <String, Object?>{} : jsonDecode(text) as Map<String, Object?>);
    } on IOException catch (e) {
      throw CloudStoreException(CloudFailure.unavailable, e.runtimeType.toString());
    }
  }

  static CloudStoreException _error(int status, Map<String, Object?> body) {
    final s = ((body['error'] as Map?)?['status'] as String?) ?? '$status';
    return CloudStoreException(
      switch (s) {
        'PERMISSION_DENIED' || 'UNAUTHENTICATED' => CloudFailure.permissionDenied,
        'ABORTED' || 'FAILED_PRECONDITION' => CloudFailure.aborted,
        'UNAVAILABLE' || 'DEADLINE_EXCEEDED' || 'INTERNAL' => CloudFailure.unavailable,
        _ => CloudFailure.unknown,
      },
      s,
    );
  }

  /// The document and its update time (null: none).
  Future<(Map<String, Object?>?, String?)> _read(String path) async {
    final (status, body) = await _call('GET', '$_docs/$path');
    if (status == 404) return (null, null);
    if (status != 200) throw _error(status, body);
    return (decodeFields(body['fields'] as Map<String, Object?>? ?? const {}), body['updateTime'] as String?);
  }

  @override
  Future<Map<String, Object?>?> get(String path) async => (await _read(path)).$1;

  @override
  Future<Map<String, Map<String, Object?>>> list(String path) async {
    final out = <String, Map<String, Object?>>{};
    String? page;
    do {
      final (status, body) = await _call('GET', '$_docs/$path?pageSize=300${page == null ? '' : '&pageToken=$page'}');
      if (status != 200) throw _error(status, body);
      for (final d in (body['documents'] as List? ?? const [])) {
        final doc = d as Map<String, Object?>;
        out[(doc['name']! as String).split('/').last] = decodeFields(doc['fields'] as Map<String, Object?>? ?? const {});
      }
      page = body['nextPageToken'] as String?;
    } while (page != null && page.isNotEmpty);
    return out;
  }

  @override
  Future<T> runTransaction<T>(Future<T> Function(CloudTx tx) body) async {
    for (var attempt = 1;; attempt++) {
      final tx = _RestTx(this);
      final result = await body(tx);
      try {
        await tx.commit();
        return result;
      } on CloudStoreException catch (e) {
        if (e.failure != CloudFailure.aborted || attempt >= maxAttempts) rethrow;
      }
    }
  }

  /// Writes [data] directly (admin seeding / another device's raw write).
  Future<void> put(String path, Map<String, Object?> data) async {
    final (status, body) = await _call('POST', '$_docs:commit', {
      'writes': [_write(path, data, null)],
    });
    if (status != 200) throw _error(status, body);
  }

  /// Deletes a document directly (admin).
  Future<void> delete(String path) async {
    final (status, body) = await _call('DELETE', '$_docs/$path');
    if (status != 200) throw _error(status, body);
  }

  Map<String, Object?> _write(String path, Map<String, Object?> data, Map<String, Object?>? precondition) {
    final serverTime = [for (final e in data.entries) if (e.value is CloudServerTime) e.key];
    return {
      'update': {
        'name': _name(path),
        'fields': encodeFields({for (final e in data.entries) if (e.value is! CloudServerTime) e.key: e.value}),
      },
      if (serverTime.isNotEmpty)
        'updateTransforms': [for (final f in serverTime) {'fieldPath': f, 'setToServerValue': 'REQUEST_TIME'}],
      'currentDocument': ?precondition,
    };
  }

  /// Wipes the emulator's documents (between tests).
  static Future<void> clear() async {
    final c = HttpClient();
    final req = await c.deleteUrl(Uri.parse('http://$emulatorHost/emulator/v1/projects/$emulatorProject/databases/(default)/documents'));
    await (await req.close()).drain<void>();
    c.close();
  }
}

class _RestTx implements CloudTx {
  _RestTx(this.store);

  final EmulatorCloudStore store;
  final _reads = <String, String?>{}; // path → updateTime (null: missing)
  final _writes = <String, Map<String, Object?>>{};

  @override
  Future<Map<String, Object?>?> get(String path) async {
    final (doc, time) = await store._read(path);
    _reads[path] = time;
    return doc;
  }

  @override
  void set(String path, Map<String, Object?> data) => _writes[path] = data;

  Future<void> commit() async {
    // Everything read must be as it was (like the SDKs' transactions).
    for (final MapEntry(key: path, value: time) in _reads.entries) {
      if (_writes.containsKey(path)) continue; // checked by its precondition
      if ((await store._read(path)).$2 != time) throw const CloudStoreException(CloudFailure.aborted, 'read changed');
    }
    if (_writes.isEmpty) return;
    final (status, body) = await store._call('POST', '${store._docs}:commit', {
      'writes': [
        for (final MapEntry(key: path, value: data) in _writes.entries)
          store._write(
            path,
            data,
            _reads.containsKey(path)
                ? (_reads[path] == null ? {'exists': false} : {'updateTime': _reads[path]})
                : null,
          ),
      ],
    });
    if (status != 200) throw EmulatorCloudStore._error(status, body);
  }
}

// ---- Firestore REST values ----

Map<String, Object?> encodeFields(Map<String, Object?> m) => {for (final e in m.entries) e.key: encodeValue(e.value)};

Map<String, Object?> encodeValue(Object? v) => switch (v) {
      null => {'nullValue': null},
      bool b => {'booleanValue': b},
      int i => {'integerValue': '$i'},
      double d => {'doubleValue': d},
      String s => {'stringValue': s},
      DateTime t => {'timestampValue': t.toUtc().toIso8601String()},
      List l => {'arrayValue': {'values': [for (final x in l) encodeValue(x)]}},
      Map m => {'mapValue': {'fields': encodeFields(Map<String, Object?>.from(m))}},
      _ => throw ArgumentError('cannot store ${v.runtimeType}'),
    };

Map<String, Object?> decodeFields(Map<String, Object?> f) => {for (final e in f.entries) e.key: decodeValue(e.value as Map<String, Object?>)};

Object? decodeValue(Map<String, Object?> v) {
  if (v.containsKey('nullValue')) return null;
  if (v['booleanValue'] case final bool b) return b;
  if (v['integerValue'] case final String i) return int.parse(i);
  if (v['doubleValue'] case final num d) return d.toDouble();
  if (v['stringValue'] case final String s) return s;
  if (v['timestampValue'] case final String t) return DateTime.parse(t).toUtc();
  if (v['arrayValue'] case final Map a) return [for (final x in (a['values'] as List? ?? const [])) decodeValue(x as Map<String, Object?>)];
  if (v['mapValue'] case final Map m) return decodeFields((m['fields'] as Map<String, Object?>?) ?? const {});
  throw ArgumentError('unknown value $v');
}

// ---- in memory ----

class MemoryCloudStore implements CloudStore {
  final docs = <String, Map<String, Object?>>{};
  final _versions = <String, int>{};
  DateTime Function() now = () => DateTime.utc(2026, 10, 14, 12);
  int commits = 0;

  @override
  Future<Map<String, Object?>?> get(String path) async => docs[path];

  @override
  Future<Map<String, Map<String, Object?>>> list(String path) async => {
        for (final MapEntry(:key, :value) in docs.entries)
          if (key.startsWith('$path/') && !key.substring(path.length + 1).contains('/'))
            key.substring(path.length + 1): value,
      };

  @override
  Future<T> runTransaction<T>(Future<T> Function(CloudTx tx) body) async {
    for (var attempt = 1;; attempt++) {
      final tx = _MemTx(this);
      final result = await body(tx);
      if (tx._reads.entries.every((e) => (_versions[e.key] ?? 0) == e.value)) {
        for (final MapEntry(key: path, value: data) in tx._writes.entries) {
          docs[path] = {for (final e in data.entries) e.key: e.value is CloudServerTime ? now() : e.value};
          _versions[path] = (_versions[path] ?? 0) + 1;
        }
        commits++;
        return result;
      }
      if (attempt >= 5) throw const CloudStoreException(CloudFailure.aborted, 'contention');
    }
  }

  /// Another writer (a device not under test).
  void put(String path, Map<String, Object?> data) {
    docs[path] = {for (final e in data.entries) e.key: e.value is CloudServerTime ? now() : e.value};
    _versions[path] = (_versions[path] ?? 0) + 1;
  }
}

class _MemTx implements CloudTx {
  _MemTx(this.store);

  final MemoryCloudStore store;
  final _reads = <String, int>{};
  final _writes = <String, Map<String, Object?>>{};

  @override
  Future<Map<String, Object?>?> get(String path) async {
    _reads[path] = store._versions[path] ?? 0;
    return store.docs[path];
  }

  @override
  void set(String path, Map<String, Object?> data) => _writes[path] = data;
}

/// Wraps a store to inject what the network and other devices do.
class FaultyStore implements CloudStore {
  FaultyStore(this.inner);

  final CloudStore inner;

  /// Every call fails with this (e.g. offline).
  CloudFailure? down;

  /// The next transaction commits on the server, then its answer is lost.
  bool loseNextAnswer = false;

  /// The next transaction fails with this before reaching the server.
  CloudFailure? failNext;

  /// Runs at the end of the next transaction body, before its commit (a
  /// racing device, a sign-out…). Runs once.
  Future<void> Function()? duringNext;

  /// How many times transaction bodies ran.
  int bodies = 0;

  @override
  Future<Map<String, Object?>?> get(String path) {
    if (down case final f?) throw CloudStoreException(f, 'injected');
    return inner.get(path);
  }

  /// Runs before each collection read (e.g. a sign-out mid-restore).
  Future<void> Function(String path)? beforeList;

  @override
  Future<Map<String, Map<String, Object?>>> list(String path) async {
    await beforeList?.call(path);
    if (down case final f?) throw CloudStoreException(f, 'injected');
    return inner.list(path);
  }

  @override
  Future<T> runTransaction<T>(Future<T> Function(CloudTx tx) body) async {
    if (down case final f?) throw CloudStoreException(f, 'injected');
    if (failNext case final f?) {
      failNext = null;
      throw CloudStoreException(f, 'injected');
    }
    final result = await inner.runTransaction((tx) async {
      bodies++;
      final r = await body(tx);
      // After the body's reads and writes, before the commit: a race.
      final hook = duringNext;
      if (hook != null) {
        duringNext = null;
        await hook();
      }
      return r;
    });
    if (loseNextAnswer) {
      loseNextAnswer = false;
      throw const CloudStoreException(CloudFailure.unavailable, 'answer lost after commit');
    }
    return result;
  }
}

