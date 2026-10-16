// Phase 4.3B-1: the app's cloud sync, end to end, in the real app on a
// device, against the LOCAL emulators only (Auth + Firestore):
//   cd firebase && DEVICE=<id> EMULATOR_HOST=<host> npm run test:sync-app
// (<host>: localhost on the iOS simulator, 10.0.2.2 on an Android emulator.)
// The app is built with LM_CLOUD_EMULATOR, so Auth and Firestore are pointed
// at the emulators before anything uses them; nothing reaches the DEV or
// PROD project. Consent records are written by the emulator's admin only
// (as a trusted backend would), never by the app.
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:london_mystery/core/cloud/cloud_bootstrap.dart';
import 'package:london_mystery/core/cloud/cloud_emulator.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/data/repositories/progress_repository.dart';
import 'package:london_mystery/data/sync/cloud/cloud_catalog.dart';
import 'package:london_mystery/data/sync/cloud/cloud_codec.dart';
import 'package:london_mystery/data/sync/cloud/cloud_store.dart';
import 'package:london_mystery/features/account/account_controller.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/sync/sync_gate.dart';
import 'package:london_mystery/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

import '../test/support/cloud_stores.dart' show decodeFields, encodeFields;

const host = CloudEmulator.buildHost;
const password = 'detective42';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String projectId;
  final season = MockEpisodeRepository.bundled();
  final codec = CloudCodec(CloudCatalog.of(season));
  final m01 = season.first.missions.first;

  // ---- the emulators' admin (rules bypassed, like a trusted backend) ----

  Future<(int, Map<String, Object?>)> rest(String method, String url, [Object? body]) async {
    final c = HttpClient();
    try {
      final req = await c.openUrl(method, Uri.parse(url));
      req.headers.set('Authorization', 'Bearer owner');
      if (body != null) {
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode(body));
      }
      final res = await req.close();
      final text = await res.transform(utf8.decoder).join();
      return (res.statusCode, text.isEmpty ? <String, Object?>{} : jsonDecode(text) as Map<String, Object?>);
    } finally {
      c.close();
    }
  }

  String docs() => 'http://$host:8080/v1/projects/$projectId/databases/(default)/documents';

  Future<Map<String, Object?>?> server(String path) async {
    final (status, body) = await rest('GET', '${docs()}/$path');
    if (status == 404) return null;
    expect(status, 200, reason: 'admin read of $path');
    return decodeFields(body['fields'] as Map<String, Object?>? ?? const {});
  }

  Future<List<String>> listIds(String collection) async {
    final (status, body) = await rest('GET', '${docs()}/$collection');
    expect(status, 200);
    return [for (final d in (body['documents'] as List? ?? const [])) ((d as Map)['name'] as String).split('/').last];
  }

  Future<void> adminPut(String path, Map<String, Object?> data) async {
    final (status, _) = await rest('POST', '${docs()}:commit', {
      'writes': [
        {
          'update': {'name': 'projects/$projectId/databases/(default)/documents/$path', 'fields': encodeFields(data)},
        },
      ],
    });
    expect(status, 200, reason: 'admin write of $path');
  }

  Future<void> adminDelete(String path) async {
    final (status, _) = await rest('DELETE', '${docs()}/$path');
    expect(status, 200);
  }

  Future<void> clearEmulators() async {
    await rest('DELETE', 'http://$host:8080/emulator/v1/projects/$projectId/databases/(default)/documents');
    await rest('DELETE', 'http://$host:9099/emulator/v1/projects/$projectId/accounts');
  }

  testWidgets('the app syncs through the emulators: accounts, consent, profiles, offline, restart, merge', (t) async {
    expect(appFlavor, 'dev', reason: 'dev flavor only');
    expect(host, isNotEmpty, reason: 'built with LM_CLOUD_EMULATOR');
    projectId = (await Firebase.initializeApp()).options.projectId;
    await clearEmulators();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool(AppConstants.soundEnabledKey, false); // no music in the test run

    await app.main();
    var h = app.debugApp!;

    Future<void> until(bool Function() ok, String what, {Duration timeout = const Duration(seconds: 20)}) async {
      final end = DateTime.now().add(timeout);
      while (!ok()) {
        if (DateTime.now().isAfter(end)) fail('timed out: $what');
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    ProviderContainer c() => h.host.currentState!.container;
    SharedPrefsProgressRepository repo() => c().read(progressRepositoryProvider) as SharedPrefsProgressRepository;
    DetectiveProfile profile() => h.host.currentState!.session.profile;

    /// Settled: nothing running or planned (a back-off may stay with [planned]).
    Future<void> idle({bool planned = false}) async {
      await t.pump(const Duration(milliseconds: 2500)); // past the save delay
      await until(() => h.sync!.running == null && (planned || !h.sync!.planned), 'sync idle', timeout: const Duration(seconds: 60));
    }

    Future<void> sentAll(String what, {Duration timeout = const Duration(seconds: 20)}) async {
      await until(() => repo().outbox.pending.isEmpty && h.sync!.running == null, what, timeout: timeout);
    }

    void play(String name) {
      final game = c().read(gameControllerProvider.notifier);
      expect(game.registerDetective(name), isNull);
      game.startInvestigation();
      c().read(walletProvider.notifier).unlockTip(m01, 1);
      game.useHint(m01);
      expect(game.submitAnswer(m01, 'b').result, SubmitResult.correct);
    }

    void save(String word) => c().read(gameControllerProvider.notifier).lookUpWord(word);

    Future<String> signUp(String email) async {
      expect((await h.account.signUp(email: email, password: password)).ok, isTrue);
      await until(() => h.account.value.uid != null, 'signed up');
      await t.pump(const Duration(milliseconds: 500)); // the consent read
      return h.account.value.uid!;
    }

    Future<void> signIn(String email) async {
      expect((await h.account.signIn(email: email, password: password)).ok, isTrue);
      await until(() => h.account.value.uid != null, 'signed in');
      await t.pump(const Duration(milliseconds: 500));
    }

    Future<void> signOut() async {
      await h.account.signOut();
      await until(() => h.account.value.uid == null && profile().kind == ProfileKind.guest, 'signed out, the guest plays');
    }

    Future<DetectiveProfile> choose(String uid, String name) async {
      final p = await c().read(profileStoreProvider).addProfile(kind: ProfileKind.account, ownerUid: uid, detectiveName: name);
      await h.host.currentState!.switchTo(p.id);
      await t.pump(const Duration(milliseconds: 300));
      expect(profile().id, p.id);
      return p;
    }

    Future<void> resume() async {
      h.sync!.onLifecycle(AppLifecycleState.resumed);
      await t.pump(const Duration(milliseconds: 300));
    }

    Future<void> confirm(String uid, [String status = 'confirmed']) => adminPut('consents/$uid', {'status': status, 'schema': 1});

    void onEmulatorOnly() =>
        expect(FirebaseFirestore.instance.settings.host, startsWith(host), reason: 'Firestore on the emulator, never a project');

    await until(() => h.cloud.value == CloudStatus.ready, 'cloud ready');
    onEmulatorOnly();
    expect(h.sync, isNotNull, reason: 'the scheduler exists in this build');
    if (h.account.value.uid != null) await signOut(); // a session left from an earlier run

    // 1. The guest plays: nothing syncs.
    await until(() => h.account.value.status == AccountStatus.signedOut, 'signed out');
    expect(profile().kind, ProfileKind.guest);
    play('GUEST');
    await idle();
    expect(h.sync!.runs, 0);
    expect(await listIds('users'), isEmpty);

    // 2. Anna signs up; her consent is not confirmed: still nothing.
    final anna = await signUp('anna@example.com');
    expect(h.account.value.consentConfirmed, isFalse);
    final annaProfile = await choose(anna, 'ANNA'); // the detective chosen
    play('ANNA');
    await idle();
    expect(h.sync!.activity.block, SyncBlock.consentNotConfirmed);
    expect(h.sync!.runs, 0);
    expect(await server('users/$anna'), isNull);
    expect(repo().outbox.pending, isNotEmpty);

    // 3. Her consent is confirmed (by the trusted backend); the app comes back.
    await confirm(anna);
    await resume();
    await sentAll('first sync');
    final annaPaths = SyncPaths(anna, annaProfile.id);
    expect((await server(annaPaths.profile))?['detectiveName'], 'ANNA');
    expect((await server(annaPaths.caseDoc('ep01')))?['cloudVersion'], greaterThanOrEqualTo(1));
    expect((await server(annaPaths.walletSummary))?['balance'], 50);
    expect(await server('consents/$anna'), {'status': 'confirmed', 'schema': 1}, reason: 'as the backend wrote it');

    // 4. A burst of saves and resumes: few runs, never two at once.
    final runsBefore = h.sync!.runs;
    for (var i = 0; i < 10; i++) {
      save('burst$i');
      if (i.isEven) h.sync!.onLifecycle(AppLifecycleState.resumed);
      await t.pump(const Duration(milliseconds: 30));
    }
    await idle();
    expect(repo().outbox.pending, isEmpty);
    expect(h.sync!.runs - runsBefore, inInclusiveRange(1, 3));
    expect(((await server(annaPaths.caseDoc('ep01')))!['progress'] as Map)['lookedUpWords'], hasLength(10));

    // 5. Another device of Anna's profile added a word: merged, on screen.
    final cloudCase = (await server(annaPaths.caseDoc('ep01')))!;
    final mine = repo().load('ep01');
    final theirs = mine.copyWith(lookedUpWords: [...mine.lookedUpWords, 'lantern'], rev: mine.rev + 1);
    final w = codec.caseToCloud(caseId: 'ep01', progress: theirs, epoch: 0, cloudVersion: (cloudCase['cloudVersion']! as int) + 1);
    await adminPut(annaPaths.caseDoc('ep01'), {...w.data!, 'updatedAt': DateTime.now().toUtc()});
    save('fog');
    await sentAll('merge');
    expect(c().read(gameControllerProvider).lookedUpWords, containsAll(['fog', 'lantern']), reason: 'the game shows the merge');
    expect(((await server(annaPaths.caseDoc('ep01')))!['progress'] as Map)['lookedUpWords'], containsAll(['fog', 'lantern']));

    // 6. Another profile of Anna's: its own documents; Anna's untouched.
    final annaVersion = (await server(annaPaths.caseDoc('ep01')))!['cloudVersion'];
    final ben = await choose(anna, 'BEN');
    play('BEN');
    await sentAll('second profile');
    expect((await server(SyncPaths(anna, ben.id).walletSummary))?['balance'], 50);
    expect((await server(annaPaths.caseDoc('ep01')))!['cloudVersion'], annaVersion);
    await h.host.currentState!.switchTo(annaProfile.id);
    await t.pump(const Duration(milliseconds: 300));
    expect(c().read(gameControllerProvider).lookedUpWords, contains('lantern'), reason: 'her own case again');

    // 7. Sign-out: the guest plays on, nothing syncs.
    await signOut();
    final runsOut = h.sync!.runs;
    save('guest-word');
    await idle();
    expect(h.sync!.runs, runsOut);

    // 8. Another account (Carl): no consent, blocked; Anna's profile stays shut.
    final carl = await signUp('carl@example.com');
    await expectLater(h.host.currentState!.switchTo(annaProfile.id), throwsStateError);
    await confirm(carl);
    await resume();
    final carlProfile = await choose(carl, 'CARL');
    play('CARL');
    await sentAll('Carl');
    expect(await listIds('users/$carl/profiles'), [carlProfile.id], reason: 'only his own profile');
    expect(await server('users/$carl/profiles/${annaProfile.id}'), isNull);

    // 9. Anna again (sign-out, sign-in): her profile opens with her play.
    await signOut();
    await signIn('anna@example.com');
    expect(h.account.value.consentConfirmed, isTrue);
    await h.host.currentState!.switchTo(annaProfile.id);
    await t.pump(const Duration(milliseconds: 300));
    expect(c().read(gameControllerProvider).isCompleted('m01'), isTrue);
    save('again');
    await sentAll('Anna again');

    // 10. Consent withdrawn: blocked, kept; confirmed again: sent.
    await confirm(anna, 'revoked');
    save('withdrawn');
    await idle();
    expect(h.sync!.activity.block, SyncBlock.consentNotConfirmed);
    expect(h.account.value.consentConfirmed, isFalse);
    expect(repo().outbox.pending, isNotEmpty);
    await confirm(anna);
    await resume();
    await sentAll('consent back');

    // 11. A deletion in progress: blocked, kept; gone: sent.
    await adminPut('deletions/$anna', {'startedAt': DateTime.now().toUtc()});
    save('deleting');
    await idle();
    expect(h.sync!.activity.block, SyncBlock.deletionInProgress);
    expect(repo().outbox.pending, isNotEmpty);
    await adminDelete('deletions/$anna');
    await resume();
    await sentAll('deletion gone');

    // 12. Offline: kept and backed off; online again: sent after the back-off.
    // (Firestore's disableNetwork() stops reads but not transactions, so the
    // connection is cut in front of the app's store: every call fails as
    // with no network.)
    final line = _Line();
    h.sync!.debugWrapStore((real) => line..inner = real);
    line.down = true;
    save('offline');
    await idle(planned: true);
    expect(repo().outbox.pending, isNotEmpty);
    expect(h.sync!.planned, isTrue, reason: 'the next try planned from the back-off');
    line.down = false;
    await sentAll('back online', timeout: const Duration(seconds: 90));
    expect(((await server(annaPaths.caseDoc('ep01')))!['progress'] as Map)['lookedUpWords'], contains('offline'));

    // 13. A restart with a change not sent: the app again sends it.
    line.down = true;
    save('before-restart');
    await idle(planned: true);
    expect(repo().outbox.pending, isNotEmpty);
    h.sync!.dispose();
    h.account.dispose();
    await app.main(); // a new start: its own store, connected
    h = app.debugApp!;
    await until(() => h.account.value.uid == anna && h.account.value.consentConfirmed, 'Anna restored after restart');
    if (profile().id != annaProfile.id) await h.host.currentState!.switchTo(annaProfile.id);
    await sentAll('after restart', timeout: const Duration(seconds: 90));
    expect(((await server(annaPaths.caseDoc('ep01')))!['progress'] as Map)['lookedUpWords'], contains('before-restart'));

    onEmulatorOnly();
    await h.account.signOut();
    await clearEmulators();
    debugPrint('E2E: every step passed');
  });
}

/// The connection in front of the app's store: [down] fails every call as
/// a device without network would.
class _Line implements CloudStore {
  late CloudStore inner;
  bool down = false;

  void _check() {
    if (down) throw const CloudStoreException(CloudFailure.unavailable, 'no network (test)');
  }

  @override
  Future<Map<String, Object?>?> get(String path) async {
    _check();
    return inner.get(path);
  }

  @override
  Future<Map<String, Map<String, Object?>>> list(String path) async {
    _check();
    return inner.list(path);
  }

  @override
  Future<T> runTransaction<T>(Future<T> Function(CloudTx tx) body) async {
    _check();
    return inner.runTransaction(body);
  }
}
