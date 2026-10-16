// Phase 4.4: restoring an account's detective, end to end, in the real app on
// a device, against the LOCAL emulators only (Auth + Firestore):
//   cd firebase && DEVICE=<id> EMULATOR_HOST=<host> npm run test:restore-app
// (<host>: localhost on the iOS simulator, 10.0.2.2 on an Android emulator.)
// Built with LM_CLOUD_EMULATOR: nothing reaches the DEV or PROD project.
// Consent records are written by the emulator's admin only, never the app.
//
// The "old device" plays and sends; then this device forgets that detective
// (its entry and saves removed, the guest kept) and the app starts again as
// a new device would: sign in, the detectives screen, restore.
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
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/data/repositories/progress_repository.dart';
import 'package:london_mystery/data/sync/cloud/cloud_store.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

import '../test/support/cloud_stores.dart' show decodeFields, encodeFields;

const host = CloudEmulator.buildHost;
const password = 'detective42';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String projectId;
  final season = MockEpisodeRepository.bundled();
  final ep01 = season.first;
  final m01 = ep01.missions.first;
  final m02 = ep01.missions[1];

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

  Future<void> clearEmulators() async {
    await rest('DELETE', 'http://$host:8080/emulator/v1/projects/$projectId/databases/(default)/documents');
    await rest('DELETE', 'http://$host:9099/emulator/v1/projects/$projectId/accounts');
  }

  testWidgets('a detective restored on a new device: listed, restored, played on, kept after a restart', (t) async {
    expect(appFlavor, 'dev', reason: 'dev flavor only');
    expect(host, isNotEmpty, reason: 'built with LM_CLOUD_EMULATOR');
    projectId = (await Firebase.initializeApp()).options.projectId;
    await clearEmulators();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool(AppConstants.soundEnabledKey, false);

    await app.main();
    var h = app.debugApp!;

    Future<void> until(bool Function() ok, String what, {Duration timeout = const Duration(seconds: 30)}) async {
      final end = DateTime.now().add(timeout);
      while (!ok()) {
        if (DateTime.now().isAfter(end)) fail('timed out: $what');
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    ProviderContainer c() => h.host.currentState!.container;
    SharedPrefsProgressRepository repo() => c().read(progressRepositoryProvider) as SharedPrefsProgressRepository;
    DetectiveProfile profile() => h.host.currentState!.session.profile;
    void onEmulatorOnly() =>
        expect(FirebaseFirestore.instance.settings.host, startsWith(host), reason: 'Firestore on the emulator, never a project');

    Future<void> sentAll(String what) async {
      await t.pump(const Duration(milliseconds: 2500));
      await until(() => repo().outbox.pending.isEmpty && h.sync!.running == null, what, timeout: const Duration(seconds: 60));
    }

    Future<void> signIn(String email, {bool create = false}) async {
      final r = create
          ? await h.account.signUp(email: email, password: password)
          : await h.account.signIn(email: email, password: password);
      expect(r.ok, isTrue);
      await until(() => h.account.value.uid != null, 'signed in');
      await t.pump(const Duration(milliseconds: 500));
    }

    Future<void> confirm(String uid) => adminPut('consents/$uid', {'status': 'confirmed', 'schema': 1});

    Future<void> go(String location) async {
      c().read(routerProvider).go(location);
      await t.pump(const Duration(milliseconds: 800));
    }

    Future<void> restartApp() async {
      h.sync!.dispose();
      h.account.dispose();
      await app.main();
      h = app.debugApp!;
      await until(() => h.cloud.value == CloudStatus.ready, 'cloud ready again');
    }

    Map<String, Object?> guestSaves() {
      final prefix = AppConstants.profilePrefix(ProfileStore(prefs).guest!.id);
      return {for (final k in prefs.getKeys()) if (k.startsWith(prefix)) k: prefs.get(k)};
    }

    await until(() => h.cloud.value == CloudStatus.ready, 'cloud ready');
    onEmulatorOnly();
    expect(h.restore, isNotNull, reason: 'restore exists in a build that syncs');
    if (h.account.value.uid != null) await h.account.signOut();

    // 1. The old device: the guest plays; Anna (consent confirmed) plays as
    //    ANNA (Case 01, mission 1) and as BEN; everything is sent.
    // (Its case not started: no play clock is banked when it is left.)
    c().read(gameControllerProvider.notifier).registerDetective('GUEST');
    await signIn('anna@example.com', create: true);
    final anna = h.account.value.uid!;
    await confirm(anna);
    await h.account.refreshConsent();
    Future<DetectiveProfile> newDetective(String name) async {
      final p = await c().read(profileStoreProvider).addProfile(kind: ProfileKind.account, ownerUid: anna, detectiveName: name);
      await h.host.currentState!.switchTo(p.id);
      await t.pump(const Duration(milliseconds: 300));
      final game = c().read(gameControllerProvider.notifier);
      expect(game.registerDetective(name), isNull);
      game.startInvestigation();
      expect(game.submitAnswer(m01, m01.answer).result, SubmitResult.correct);
      return p;
    }

    final annaProfile = await newDetective('ANNA');
    await sentAll('ANNA sent');
    final xpOld = XpBreakdown.totalFor(ep01, c().read(gameControllerProvider));
    final caseOld = jsonEncode(repo().load('ep01').toJson());
    final benProfile = await newDetective('BEN');
    await sentAll('BEN sent');
    expect((await server(SyncPaths(anna, annaProfile.id).walletSummary))?['balance'], 50);

    // 2. This device forgets both (as a new device has neither); the guest stays.
    await h.account.signOut();
    await until(() => profile().kind == ProfileKind.guest, 'the guest plays');
    final store = ProfileStore(prefs);
    final registry = store.read()!;
    await store.write(ProfileRegistry(
      activeProfileId: registry.activeProfileId,
      profiles: [for (final p in registry.profiles) if (p.id != annaProfile.id && p.id != benProfile.id) p],
    ));
    for (final id in [annaProfile.id, benProfile.id]) {
      for (final k in prefs.getKeys().where((k) => k.startsWith(AppConstants.profilePrefix(id))).toList()) {
        await prefs.remove(k);
      }
    }
    await restartApp();
    final guestBefore = guestSaves();
    expect(guestBefore, isNotEmpty);

    // 3. Sign in on the "new device"; offline first: said, nothing changes.
    await signIn('anna@example.com');
    await until(() => h.account.value.consentConfirmed, 'consent read');
    final line = _Line();
    h.sync!.debugWrapStore((real) => line..inner = real);
    line.down = true;
    await go(Routes.profiles);
    await until(() => find.text("Couldn't reach your account's case files. Nothing on this device changed.").evaluate().isNotEmpty,
        'offline said');
    expect(store.profile(annaProfile.id), isNull);
    line.down = false;
    await t.tap(find.text('TRY AGAIN'));
    await until(() => find.byKey(ValueKey('cloud-profile-${annaProfile.id}')).evaluate().isNotEmpty, 'ANNA listed');
    expect(find.byKey(ValueKey('cloud-profile-${benProfile.id}')), findsOneWidget);

    // 4. BEN's case on the server is not valid: nothing of BEN restored.
    final benCase = SyncPaths(anna, benProfile.id).caseDoc('ep01');
    final benDoc = (await server(benCase))!;
    await adminPut(benCase, {
      ...benDoc,
      'progress': {...(benDoc['progress']! as Map<String, Object?>), 'xpRules': {m01.id: 99}},
    });
    await t.tap(find.byKey(ValueKey('cloud-profile-${benProfile.id}')));
    await until(() => find.textContaining('could not be checked').evaluate().isNotEmpty, 'BEN refused');
    expect(store.profile(benProfile.id), isNull);
    expect(profile().kind, ProfileKind.guest);

    // 5. ANNA restored: she plays with her case, coins and XP.
    await t.tap(find.byKey(ValueKey('cloud-profile-${annaProfile.id}')));
    await until(() => profile().id == annaProfile.id, 'ANNA restored and playing');
    expect(jsonEncode(repo().load('ep01').toJson()), caseOld, reason: 'the case as the old device sent it');
    expect(c().read(gameControllerProvider).isCompleted(m01.id), isTrue);
    expect(XpBreakdown.totalFor(ep01, c().read(gameControllerProvider)), xpOld);
    expect(c().read(walletProvider).balance, 50);
    expect(guestSaves(), guestBefore, reason: 'the guest untouched');
    expect(await server('users/$anna/profiles/${ProfileStore(prefs).guest!.id}'), isNull, reason: 'the guest never uploaded');

    // 6. Play on: the next mission, sent on top of the restored state.
    expect(c().read(gameControllerProvider.notifier).submitAnswer(m02, m02.answer).result, SubmitResult.correct);
    await sentAll('played on');
    final up = (await server(SyncPaths(anna, annaProfile.id).caseDoc('ep01')))!['progress'] as Map;
    expect(up['completedMissionIds'], containsAll([m01.id, m02.id]));
    expect((await server(SyncPaths(anna, annaProfile.id).walletSummary))?['balance'], 80);
    expect(c().read(walletProvider).balance, 80);
    expect(repo().conflicts, isEmpty);

    // 7. A restart: the session comes back; ANNA opens from this device.
    final caseNow = jsonEncode(repo().load('ep01').toJson());
    final version = (await server(SyncPaths(anna, annaProfile.id).caseDoc('ep01')))!['cloudVersion'];
    await restartApp();
    await until(() => h.account.value.uid == anna && h.account.value.consentConfirmed, 'Anna back after restart');
    await go(Routes.profiles);
    await until(() => find.byKey(ValueKey('profile-${annaProfile.id}')).evaluate().isNotEmpty, 'ANNA on this device');
    expect(find.byKey(ValueKey('cloud-profile-${annaProfile.id}')), findsNothing, reason: 'not offered again');
    await t.tap(find.byKey(ValueKey('profile-${annaProfile.id}')));
    await until(() => profile().id == annaProfile.id, 'ANNA chosen');
    await sentAll('after restart');
    expect(jsonEncode(repo().load('ep01').toJson()), caseNow);
    expect((await server(SyncPaths(anna, annaProfile.id).caseDoc('ep01')))!['cloudVersion'], version,
        reason: 'nothing written again');
    expect(c().read(walletProvider).balance, 80);

    onEmulatorOnly();
    await h.account.signOut();
    await clearEmulators();
    debugPrint('E2E restore: every step passed');
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
