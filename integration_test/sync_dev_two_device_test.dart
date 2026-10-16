// Phase 4.3B-2: the real app on two Android emulators syncing through the
// REAL DEV project (never PROD). Started by the host's orchestrator, which
// makes the run's test accounts and their consent, holds the barriers
// between the two devices, reads the run's own documents as the admin, and
// switches a device's network off and on:
//   cd firebase && node scripts/dev_two_device_e2e.mjs
// Built with LM_CLOUD_SYNC=dev (the DEV-only sync test option), LM_E2E_ROLE
// (A or B) and LM_E2E_HOST (the orchestrator, 10.0.2.2:8787).
//
// Same profile on both devices: the app has no screen yet to pick an
// account's cloud profile on another device (restore is Phase 4.4), so B
// registers the profile with A's id through the device's profile registry.
// The sender downloads a case only by merging when it sends that case: a
// device sees the other's change after its own next save of the case.
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
import 'package:london_mystery/core/cloud/cloud_environment.dart';
import 'package:london_mystery/core/cloud/cloud_sync_mode.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/data/repositories/progress_repository.dart';
import 'package:london_mystery/data/sync/cloud/cloud_store.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

const role = String.fromEnvironment('LM_E2E_ROLE');
const orchestrator = String.fromEnvironment('LM_E2E_HOST');

// ---- the orchestrator ----

Future<(int, Map<String, Object?>)> _http(String method, String path, {Object? body, Duration timeout = const Duration(seconds: 30)}) async {
  final c = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  try {
    final req = await c.openUrl(method, Uri.parse('http://$orchestrator$path')).timeout(timeout);
    if (body != null) {
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(body));
    }
    final res = await req.close().timeout(timeout);
    final text = await res.transform(utf8.decoder).join().timeout(timeout);
    return (res.statusCode, text.isEmpty ? <String, Object?>{} : jsonDecode(text) as Map<String, Object?>);
  } finally {
    c.close(force: true);
  }
}

Future<void> signal(String name, [Object? value]) async {
  final (s, _) = await _http('POST', '/signal?name=$name', body: value ?? true);
  expect(s, 200);
}

Future<Object?> waitFor(String name, {Duration timeout = const Duration(minutes: 15)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    final (s, b) = await _http('GET', '/wait?name=$name&timeout=110000', timeout: const Duration(seconds: 130));
    if (s == 200) return b['value'];
    if (s == 409) fail('stopped: the other device aborted (${b['abort']})');
  }
  fail('timed out waiting for $name');
}

Future<Map<String, Object?>?> serverDoc(String path) async {
  final (s, b) = await _http('GET', '/doc?path=${Uri.encodeQueryComponent(path)}');
  expect(s, 200, reason: 'admin read of $path');
  return b['doc'] as Map<String, Object?>?;
}

/// Records a scenario; a failure stops both devices at once.
Future<void> check(String scenario, bool ok, String observed) async {
  await _http('POST', '/result', body: {'device': role, 'scenario': scenario, 'ok': ok, 'observed': observed});
  if (!ok) {
    await signal('abort', '$role: $scenario: $observed');
    fail('$scenario: $observed');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final season = MockEpisodeRepository.bundled();
  final ep01 = season.first;
  Mission mission(String id) => ep01.missions.firstWhere((m) => m.id == id);

  testWidgets('two devices, one DEV account: role $role', (t) async {
    expect(role == 'A' || role == 'B', isTrue, reason: 'LM_E2E_ROLE');
    expect(appFlavor, 'dev');
    expect(CloudSyncMode.buildOption, 'dev', reason: 'built with LM_CLOUD_SYNC=dev');
    final (cs, config) = await _http('GET', '/config');
    expect(cs, 200);
    expect(config['project'], CloudEnvironment.dev.projectId);
    final accounts = {for (final a in (config['accounts']! as List).cast<Map>()) a['role'] as String: a};

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool(AppConstants.soundEnabledKey, false);
    await app.main();
    var h = app.debugApp!;

    Future<void> until(bool Function() ok, String what, {Duration timeout = const Duration(seconds: 30)}) async {
      final end = DateTime.now().add(timeout);
      while (!ok()) {
        if (DateTime.now().isAfter(end)) {
          await check('wait', false, 'timed out: $what');
        }
        await t.pump(const Duration(milliseconds: 200));
      }
    }

    ProviderContainer c() => h.host.currentState!.container;
    SharedPrefsProgressRepository repo() => c().read(progressRepositoryProvider) as SharedPrefsProgressRepository;
    DetectiveProfile profile() => h.host.currentState!.session.profile;
    GameController game() => c().read(gameControllerProvider.notifier);

    Future<void> idle({bool planned = false}) async {
      await t.pump(const Duration(milliseconds: 2500));
      await until(() => h.sync!.running == null && (planned || !h.sync!.planned), 'sync idle', timeout: const Duration(seconds: 90));
    }

    Future<void> sentAll(String what, {Duration timeout = const Duration(seconds: 60)}) async {
      await t.pump(const Duration(milliseconds: 2500));
      await until(() => repo().outbox.pending.isEmpty && h.sync!.running == null, what, timeout: timeout);
    }

    void solve(String id) {
      final m = mission(id);
      expect(game().submitAnswer(m, m.answer).result, SubmitResult.correct, reason: id);
    }

    Future<void> signIn(String r) async {
      final a = accounts[r]!;
      expect((await h.account.signIn(email: a['email']! as String, password: a['password']! as String)).ok, isTrue);
      await until(() => h.account.value.uid == a['uid'] && h.account.value.consentConfirmed, 'signed in as $r, consent read');
    }

    Future<void> signOut() async {
      await h.account.signOut();
      await until(() => h.account.value.uid == null && profile().kind == ProfileKind.guest, 'signed out');
    }

    Future<Map<String, Object?>> serverCase(String uid, String pid) async =>
        (await serverDoc(SyncPaths(uid, pid).caseDoc('ep01')))!['progress']! as Map<String, Object?>;

    Future<int> serverBalance(String uid, String pid) async =>
        (await serverDoc(SyncPaths(uid, pid).walletSummary))!['balance']! as int;

    // Setup: the DEV app, the real project, nobody signed in.
    await until(() => h.cloud.value == CloudStatus.ready, 'cloud ready');
    final options = Firebase.app().options;
    await check('setup: DEV project and app', options.projectId == CloudEnvironment.dev.projectId &&
        options.appId == CloudEnvironment.dev.androidAppId && FirebaseFirestore.instance.settings.host != 'localhost:8080' && h.sync != null,
        'project=${options.projectId}, app=${options.appId == CloudEnvironment.dev.androidAppId ? 'DEV android' : 'other'}, scheduler=${h.sync != null}');
    if (h.account.value.uid != null) await signOut();
    final uidA = accounts['a']!['uid']! as String;
    final uidB = accounts['b']!['uid']! as String;

    if (role == 'A') {
      // 1. A guest plays first: nothing leaves the device.
      expect(profile().kind, ProfileKind.guest);
      final guestId = profile().id;
      game().registerDetective('GUEST');
      game().startInvestigation();
      solve('m01');
      await idle();
      await check('guest play is not synced', h.sync!.runs == 0, 'runs=${h.sync!.runs}');
      await signal('A-ready');

      // 2. Account a, a new detective, Case 01 m01: uploaded.
      await signIn('a');
      final p = await c().read(profileStoreProvider).addProfile(kind: ProfileKind.account, ownerUid: uidA, detectiveName: 'ANNA');
      await h.host.currentState!.switchTo(p.id);
      await t.pump(const Duration(milliseconds: 300));
      game().registerDetective('ANNA');
      game().startInvestigation();
      c().read(walletProvider.notifier).unlockTip(mission('m01'), 1);
      game().useHint(mission('m01'));
      solve('m01');
      await sentAll('A uploads');
      final up = await serverCase(uidA, p.id);
      final bal = await serverBalance(uidA, p.id);
      await check('A plays and uploads', (up['completedMissionIds']! as List).contains('m01') && bal == 50,
          'server ep01 solved=${up['completedMissionIds']}, balance=$bal');
      await signal('profile', p.id);

      // 4. B continued (m02): A sees it after its own next save of the case.
      await waitFor('B-continued');
      game().lookUpWord('from-a');
      await sentAll('A merges');
      final mine = c().read(gameControllerProvider);
      await check('A reflects B\'s change', mine.isCompleted('m02') && mine.lookedUpWords.contains('from-a'),
          'A solved=${mine.completedMissionIds}, words=${mine.lookedUpWords}');

      // 5. Both change the same case at once; both solve m03 (one grant).
      await signal('A-c-ready');
      await waitFor('B-c-ready');
      game().lookUpWord('alpha');
      solve('m03');
      await sentAll('A concurrent');
      await signal('A-c-sent');
      await waitFor('B-c-sent');
      final both = await serverCase(uidA, p.id);
      final bal3 = await serverBalance(uidA, p.id);
      final m03 = await serverDoc(SyncPaths(uidA, p.id).walletEvent('0_mission:m03'));
      await check('simultaneous changes combined', (both['lookedUpWords']! as List).toSet().containsAll(['alpha', 'beta']) &&
          (both['completedMissionIds']! as List).contains('m03'), 'server words=${both['lookedUpWords']}, solved=${both['completedMissionIds']}');
      await check('coins: m03 solved on both, paid once', bal3 == 110 && m03?['amount'] == 30,
          'server balance=$bal3 (20+30+30+30 expected 110), event 0_mission:m03 amount=${m03?['amount']}');
      game().lookUpWord('after-a');
      await sentAll('A merges concurrent');
      await check('A shows both devices\' words', c().read(gameControllerProvider).lookedUpWords.toSet().containsAll(['alpha', 'beta']),
          'A words=${c().read(gameControllerProvider).lookedUpWords}');
      await signal('A-c-done');
      await waitFor('B-c-done');

      // 6. No network: kept; network back: sent.
      final (ns, _) = await _http('POST', '/net?device=A&seconds=50');
      expect(ns, 200);
      await t.pump(const Duration(seconds: 4));
      solve('m04');
      await idle(planned: true);
      final keptOffline = repo().outbox.pending.isNotEmpty;
      final what = 'hold=${h.sync!.activity.hold?.name}, stop=${h.sync!.activity.report?.stop?.name}, pending=${repo().outbox.pending.length}';
      // Back online (the orchestrator turns it on by itself).
      final end = DateTime.now().add(const Duration(seconds: 120));
      while (true) {
        try {
          final (s, _) = await _http('GET', '/ping', timeout: const Duration(seconds: 3));
          if (s == 200) break;
        } catch (_) {}
        if (DateTime.now().isAfter(end)) fail('network did not come back');
        await t.pump(const Duration(seconds: 2));
      }
      await check('offline: change kept, not lost', keptOffline, what);
      await sentAll('A back online', timeout: const Duration(seconds: 150));
      final bal4 = await serverBalance(uidA, p.id);
      await check('reconnected: sent', (await serverCase(uidA, p.id))['completedMissionIds'].toString().contains('m04') && bal4 == 140,
          'server balance=$bal4 after m04');
      await signal('A-net-done');

      // 7. Play again on A while B keeps playing the old run: the later run wins.
      await signal('A-r-ready');
      await waitFor('B-r-ready');
      game().playAgain();
      await sentAll('A play again');
      await signal('A-r-sent');
      await waitFor('B-r-done');
      final again = await serverCase(uidA, p.id);
      // m01 solved again in the new run: no coins a second time.
      final coins = game().submitAnswer(mission('m01'), mission('m01').answer).coins;
      await sentAll('A replay m01');
      final bal5 = await serverBalance(uidA, p.id);
      await check('conflict: the later run wins on the server', again['runSeq'] == 1,
          'server runSeq=${again['runSeq']}, solved=${again['completedMissionIds']}');
      await check('coins: a replayed mission pays nothing', coins == 0 && bal5 == 140, 'coins=$coins, server balance=$bal5');
      await signal('A-r-done');

      // 8. New adventure (reset) on A: epoch 1; B's old run must not come back.
      await game().resetAll();
      await t.pump(const Duration(milliseconds: 300));
      game().registerDetective('ANNA');
      game().startInvestigation();
      solve('m01');
      await sentAll('A reset');
      final meta = await serverDoc(SyncPaths(uidA, p.id).meta);
      await check('reset: the server moves to epoch 1', meta?['epoch'] == 1,
          'meta epoch=${meta?['epoch']}, wallet summary=${await serverDoc(SyncPaths(uidA, p.id).walletSummary)}');
      await signal('A-reset');
      await waitFor('B-reset-done');
      final afterReset = await serverCase(uidA, p.id);
      await check('reset: the old record does not come back', (afterReset['completedMissionIds']! as List).join(',') == 'm01' &&
          !(afterReset['lookedUpWords']! as List).any((w) => ['alpha', 'beta', 'stale', 'from-a'].contains(w)),
          'server ep01 epoch=${(await serverDoc(SyncPaths(uidA, p.id).caseDoc('ep01')))!['epoch']}, solved=${afterReset['completedMissionIds']}, words=${afterReset['lookedUpWords']}');

      // 11. The guest is still the guest's, and never uploaded.
      await waitFor('B-switch-done');
      await signOut();
      final g = c().read(gameControllerProvider);
      await check('guest data kept', profile().id == guestId && g.detectiveName == 'GUEST' && g.isCompleted('m01') &&
          await serverDoc('users/$uidA/profiles/$guestId') == null, 'guest name=${g.detectiveName}, solved=${g.completedMissionIds}');
      h.sync!.dispose();
      await signal('A-end');
    } else {
      // 3. B: same account, the same detective (A's profile id), its record.
      await signIn('a');
      final pid = await waitFor('profile') as String;
      final store = c().read(profileStoreProvider);
      await store.write(store.read()!.upsert(DetectiveProfile(id: pid, kind: ProfileKind.account, ownerUid: uidA, detectiveName: 'ANNA', createdAt: DateTime.now())));
      await h.host.currentState!.switchTo(pid);
      await t.pump(const Duration(milliseconds: 300));
      await check('same account, same detective on B', profile().id == pid && h.account.value.uid == uidA, 'B profile=${profile().id == pid}');
      game().registerDetective('ANNA'); // opens the case file: nothing played on B yet
      await sentAll('B joins');
      final got = c().read(gameControllerProvider);
      await check('B gets A\'s record', got.isCompleted('m01'), 'B solved=${got.completedMissionIds}');
      solve('m02');
      await sentAll('B continues');
      final up = await serverCase(uidA, pid);
      final bal = await serverBalance(uidA, pid);
      await check('B continues and uploads', (up['completedMissionIds']! as List).contains('m02'), 'server solved=${up['completedMissionIds']}');
      await check('coins: B\'s start coins not paid twice', bal == 80, 'server balance=$bal (20+30+30 expected 80; B also sent its own start 20)');
      await signal('B-continued');

      // 5. Same case at once.
      await signal('B-c-ready');
      await waitFor('A-c-ready');
      game().lookUpWord('beta');
      final coinsM03 = game().submitAnswer(mission('m03'), mission('m03').answer).coins;
      await sentAll('B concurrent');
      await signal('B-c-sent');
      await waitFor('A-c-sent');
      game().lookUpWord('after-b');
      await sentAll('B merges concurrent');
      await check('B shows both devices\' words', c().read(gameControllerProvider).lookedUpWords.toSet().containsAll(['alpha', 'beta']),
          'B words=${c().read(gameControllerProvider).lookedUpWords}, B local m03 coins=$coinsM03');
      await signal('B-c-done');
      await waitFor('A-c-done');

      // 7. B keeps playing the old run while A plays again.
      await waitFor('A-net-done');
      await signal('B-r-ready');
      await waitFor('A-r-ready');
      game().lookUpWord('old-run');
      await sentAll('B old run');
      await waitFor('A-r-sent');
      game().lookUpWord('old-run-2');
      await sentAll('B meets the new run');
      final s = c().read(gameControllerProvider);
      await check('conflict: B follows the later run', s.runSeq == 1 && !s.isCompleted('m02'), 'B runSeq=${s.runSeq}, solved=${s.completedMissionIds}');
      await signal('B-r-done');
      await waitFor('A-r-done');

      // 8. A reset: B (old epoch) saves; it moves to the new epoch.
      await waitFor('A-reset');
      game().lookUpWord('stale');
      await sentAll('B meets the reset', timeout: const Duration(seconds: 90));
      final b = c().read(gameControllerProvider);
      await check('reset: B moves to epoch 1, its old run kept aside', repo().epoch == 1 && !b.isCompleted('m02') && !b.lookedUpWords.contains('stale') &&
          repo().conflicts.any((x) => x['kind'] == 'epoch'), 'B epoch=${repo().epoch}, solved=${b.completedMissionIds}, words=${b.lookedUpWords}');
      game().registerDetective('ANNA'); // opens the case again: A's new adventure comes down
      await sentAll('B joins the new adventure');
      final nb = c().read(gameControllerProvider);
      await check('reset: B follows A\'s new adventure', nb.isCompleted('m01') && !nb.isCompleted('m02') && !nb.lookedUpWords.contains('alpha'),
          'B solved=${nb.completedMissionIds}, words=${nb.lookedUpWords}');
      await signal('B-reset-done');

      // 9. Restart with a change not sent yet.
      h.sync!.onLifecycle(AppLifecycleState.paused);
      game().lookUpWord('pre-restart');
      final pending = repo().outbox.pending.length;
      h.sync!.dispose();
      h.account.dispose();
      await app.main();
      h = app.debugApp!;
      await until(() => h.account.value.uid == uidA && h.account.value.consentConfirmed, 'restored after restart');
      if (profile().id != pid) await h.host.currentState!.switchTo(pid);
      await sentAll('after restart', timeout: const Duration(seconds: 90));
      final words = (await serverCase(uidA, pid))['lookedUpWords']! as List;
      await check('restart: the unsent change goes up', pending > 0 && words.contains('pre-restart'), 'pending before=$pending, server words=$words');

      // 10. Sign-out, another account: kept apart.
      await signOut();
      await signIn('b');
      Object? refused;
      try {
        await h.host.currentState!.switchTo(pid);
      } catch (e) {
        refused = e;
      }
      final ben = await c().read(profileStoreProvider).addProfile(kind: ProfileKind.account, ownerUid: uidB, detectiveName: 'BEN');
      await h.host.currentState!.switchTo(ben.id);
      await t.pump(const Duration(milliseconds: 300));
      game().registerDetective('BEN');
      game().startInvestigation();
      solve('m01');
      await sentAll('account b');
      final benCase = await serverCase(uidB, ben.id);
      await check('account switch: kept apart', refused is StateError && (benCase['completedMissionIds']! as List).contains('m01') &&
          await serverDoc('users/$uidB/profiles/$pid') == null && await serverDoc('users/$uidA/profiles/${ben.id}') == null,
          'a\'s profile refused under b: ${refused is StateError}; b\'s case only under b');
      await signOut();
      await signIn('a');
      await h.host.currentState!.switchTo(pid);
      await t.pump(const Duration(milliseconds: 300));
      await check('signed in again: a\'s detective opens', profile().id == pid && c().read(gameControllerProvider).isCompleted('m01'),
          'solved=${c().read(gameControllerProvider).completedMissionIds}');
      await signal('B-switch-done');
      await signOut();
      h.sync!.dispose();
      await waitFor('A-end');
    }
  }, timeout: const Timeout(Duration(minutes: 40)));
}
