// The Firestore plugin adapter (FirestoreCloudStore) with the sync sender,
// against the LOCAL emulators only (Firestore + Auth), on a simulator:
//   cd firebase && DEVICE=<simulator id> npm run test:sync-device
// Both emulators are set before any Firebase call, so nothing reaches the
// DEV or PROD project. It checks what the in-VM tests cannot: Timestamp and
// server-time conversion, the plugin's error codes, the real Auth token in
// the rules.
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/wallet.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/data/repositories/progress_repository.dart';
import 'package:london_mystery/data/sync/cloud/cloud_catalog.dart';
import 'package:london_mystery/data/sync/cloud/cloud_codec.dart';
import 'package:london_mystery/data/sync/cloud/cloud_store.dart';
import 'package:london_mystery/data/sync/cloud/firestore_cloud_store.dart';
import 'package:london_mystery/data/sync/cloud/sync_sender.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _host = 'localhost';

/// Seeds a trusted record as the emulator's admin ("owner": rules bypassed).
Future<void> _adminPut(String projectId, String path, Map<String, Object?> fields) async {
  final c = HttpClient();
  final req = await c.postUrl(Uri.parse('http://$_host:8080/v1/projects/$projectId/databases/(default)/documents:commit'));
  req.headers.set('Authorization', 'Bearer owner');
  req.headers.contentType = ContentType.json;
  Map<String, Object?> v(Object? x) => switch (x) {
        String s => {'stringValue': s},
        int i => {'integerValue': '$i'},
        DateTime t => {'timestampValue': t.toUtc().toIso8601String()},
        _ => {'nullValue': null},
      };
  req.write(jsonEncode({
    'writes': [
      {
        'update': {
          'name': 'projects/$projectId/databases/(default)/documents/$path',
          'fields': {for (final e in fields.entries) e.key: v(e.value)},
        },
      },
    ],
  }));
  final res = await req.close();
  await res.drain<void>();
  c.close();
  if (res.statusCode != 200) throw StateError('seed failed: ${res.statusCode}');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FirestoreCloudStore + SyncSender on the emulators: sent, timestamps, refusal', (t) async {
    expect(appFlavor, 'dev', reason: 'dev flavor only');
    final app = await Firebase.initializeApp();
    // The emulators first: nothing may reach a real project.
    final db = FirebaseFirestore.instance;
    db.useFirestoreEmulator(_host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(_host, 9099);
    expect(db.settings.host, startsWith(_host), reason: 'the Firestore emulator, never a real project');
    final projectId = app.options.projectId;

    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: 'sync-${DateTime.now().millisecondsSinceEpoch}@example.com',
      password: 'Emulator123',
    );
    final uid = cred.user!.uid;
    const pid = 'abcdefabcdefabcdefabcdefabcdef34';
    final now = DateTime.now().toUtc();
    await _adminPut(projectId, 'consents/$uid', {'status': 'confirmed', 'schema': 1});
    await _adminPut(projectId, 'users/$uid', {'schema': 1, 'locale': 'ko', 'region': 'KR', 'createdAt': now});
    await _adminPut(projectId, 'users/$uid/profiles/$pid', {'schema': 1, 'detectiveName': 'ANNA', 'createdAt': now});

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = SharedPrefsProgressRepository(prefs, profileId: '5555555555555555555555555555eeee');
    await repo.save(GameProgress(detectiveName: 'ANNA', introSeen: true, completedMissionIds: const ['m01'], startedAt: now, runId: 'r1', runSeq: 1, rev: 1), 'ep01');
    await repo.saveWallet(Wallet.empty
        .adding(CoinEntry(key: 'start', amount: 20, source: CoinSource.start, at: now))
        .adding(CoinEntry(key: 'mission:m01', amount: 30, source: CoinSource.mission, at: now)));

    final season = MockEpisodeRepository.bundled();
    final store = FirestoreCloudStore(db);
    SyncSender sender() => SyncSender(
          store: store,
          repo: repo,
          codec: CloudCodec(CloudCatalog.of(season)),
          paths: SyncPaths(uid, pid),
          episodeIds: [for (final e in season) e.id],
          isStillValid: () => true,
        );

    final r = await sender().run();
    expect(r.stop, isNull);
    expect(r.sent, containsAll(['case:ep01', 'wallet:start', 'wallet:mission:m01']));
    final caseDoc = (await store.get('users/$uid/profiles/$pid/cases/ep01'))!;
    expect(caseDoc['cloudVersion'], 1);
    expect(caseDoc['updatedAt'], isA<DateTime>(), reason: 'a server timestamp, read back as DateTime');
    expect((await store.get('users/$uid/profiles/$pid/wallet/summary'))!['balance'], 50);
    expect(repo.outbox.events, isEmpty);

    // The rules refuse once consent is withdrawn: the plugin's error maps to a stop.
    await _adminPut(projectId, 'consents/$uid', {'status': 'unconfirmed', 'schema': 1});
    await repo.save(GameProgress(detectiveName: 'ANNA', introSeen: true, completedMissionIds: const ['m01', 'm02'], startedAt: now, runId: 'r1', runSeq: 1, rev: 2), 'ep01');
    final refused = await sender().run();
    expect(refused.stop, SyncStop.consentNotConfirmed);
    expect(repo.outbox.pending, isNotEmpty, reason: 'kept');
    expect(FirestoreCloudStore.failureOf('permission-denied'), CloudFailure.permissionDenied);

    await FirebaseAuth.instance.currentUser?.delete();
    await FirebaseAuth.instance.signOut();
  });
}
