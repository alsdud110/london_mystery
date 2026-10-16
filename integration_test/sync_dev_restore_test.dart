// Phase 4.4 on the REAL DEV project (never PROD): restoring an account's
// detective on a second device, with the real app on two dedicated Android
// emulators (A, B) and, after them, the iOS simulator (C). Started by the
// host's orchestrator, which makes the run's test accounts and consent,
// holds the barriers, reads the run's own documents as the admin, and
// switches an Android device's network off and on:
//   cd firebase && node scripts/dev_two_device_e2e.mjs --test integration_test/sync_dev_restore_test.dart [--ios <udid>]
// Built with LM_CLOUD_SYNC=dev, LM_E2E_ROLE (A, B or C) and LM_E2E_HOST.
//
// B never has the detective on the device before: it is listed under "IN
// YOUR ACCOUNT" on the detectives screen and restored from there.
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:london_mystery/core/cloud/cloud_bootstrap.dart';
import 'package:london_mystery/core/cloud/cloud_environment.dart';
import 'package:london_mystery/core/cloud/cloud_sync_mode.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/mission.dart';
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

/// A step marker in the device's log (read by the host after a run).
void step(String what) => debugPrint('E2E $role ${DateTime.now().toIso8601String()}: $what');

/// Asks the host to turn this device's network off for [seconds] (it answers
/// first, then turns it off; an answer lost to it still means off).
Future<void> networkOff(int seconds) async {
  step('network off for ${seconds}s');
  try {
    final (s, _) = await _http('POST', '/net?device=$role&seconds=$seconds');
    expect(s, 200);
  } on IOException catch (e) {
    step('network off: the answer was lost ($e)');
  }
}

Future<void> signal(String name, [Object? value]) async {
  step('signal $name');
  final (s, _) = await _http('POST', '/signal?name=$name', body: value ?? true);
  expect(s, 200);
}

Future<Object?> waitFor(String name, {Duration timeout = const Duration(minutes: 15)}) async {
  step('wait for $name');
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    final (s, b) = await _http('GET', '/wait?name=$name&timeout=110000', timeout: const Duration(seconds: 130));
    if (s == 200) return b['value'];
    if (s == 409) fail('stopped: another device aborted (${b['abort']})');
  }
  fail('timed out waiting for $name');
}

Future<Map<String, Object?>?> serverDoc(String path) async {
  final (s, b) = await _http('GET', '/doc?path=${Uri.encodeQueryComponent(path)}');
  expect(s, 200, reason: 'admin read of $path');
  return b['doc'] as Map<String, Object?>?;
}

/// Records a scenario; a failure stops every device at once.
Future<void> check(String scenario, bool ok, String observed) async {
  step('${ok ? 'PASS' : 'FAIL'} $scenario');
  await _http('POST', '/result', body: {'device': role, 'scenario': scenario, 'ok': ok, 'observed': observed});
  if (!ok) {
    await signal('abort', '$role: $scenario: $observed');
    fail('$scenario: $observed');
  }
}

/// The app's store with a hook before each collection read (a sign-out or
/// another account in the middle of a restore).
class _Hook implements CloudStore {
  late CloudStore inner;
  Future<void> Function(String path)? beforeList;

  @override
  Future<Map<String, Object?>?> get(String path) => inner.get(path);

  @override
  Future<Map<String, Map<String, Object?>>> list(String path) async {
    final hook = beforeList;
    if (hook != null) await hook(path);
    return inner.list(path);
  }

  @override
  Future<T> runTransaction<T>(Future<T> Function(CloudTx tx) body) => inner.runTransaction(body);
}

/// [v] with every map's keys in order (Firestore keeps no order in maps).
Object? _canon(Object? v) => switch (v) {
      Map m => {for (final k in (m.keys.map((k) => '$k').toList()..sort())) k: _canon(m[k])},
      List l => [for (final x in l) _canon(x)],
      _ => v,
    };

const _offline = "Couldn't reach your account's case files. Nothing on this device changed.";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final season = MockEpisodeRepository.bundled();
  final ep01 = season.first;
  Mission mission(String id) => ep01.missions.firstWhere((m) => m.id == id);

  testWidgets('restore on the real DEV project: role $role', (t) async {
    expect(['A', 'B', 'C'].contains(role), isTrue, reason: 'LM_E2E_ROLE');
    expect(appFlavor, 'dev');
    expect(CloudSyncMode.buildOption, 'dev', reason: 'built with LM_CLOUD_SYNC=dev');
    final (cs, config) = await _http('GET', '/config');
    expect(cs, 200);
    expect(config['project'], CloudEnvironment.dev.projectId);
    final accounts = {for (final a in (config['accounts']! as List).cast<Map>()) a['role'] as String: a};
    final uidA = accounts['a']!['uid']! as String;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool(AppConstants.soundEnabledKey, false);
    await app.main();
    var h = app.debugApp!;
    final hook = _Hook();

    Future<void> until(bool Function() ok, String what, {Duration timeout = const Duration(seconds: 30)}) async {
      final end = DateTime.now().add(timeout);
      while (!ok()) {
        if (DateTime.now().isAfter(end)) await check('wait', false, 'timed out: $what');
        await t.pump(const Duration(milliseconds: 200));
      }
    }

    ProviderContainer c() => h.host.currentState!.container;
    SharedPrefsProgressRepository repo() => c().read(progressRepositoryProvider) as SharedPrefsProgressRepository;
    DetectiveProfile profile() => h.host.currentState!.session.profile;
    GameController game() => c().read(gameControllerProvider.notifier);
    GameProgress caseNow() => c().read(gameControllerProvider);
    int xp() => XpBreakdown.totalFor(ep01, caseNow());
    int balance() => c().read(walletProvider).balance;

    Future<void> idle() async {
      await t.pump(const Duration(milliseconds: 2500));
      await until(() => h.sync!.running == null && !h.sync!.planned, 'sync idle', timeout: const Duration(seconds: 120));
    }

    Future<void> sentAll(String what, {Duration timeout = const Duration(seconds: 90)}) async {
      await t.pump(const Duration(milliseconds: 2500));
      await until(() => repo().outbox.pending.isEmpty && h.sync!.running == null, what, timeout: timeout);
    }

    Future<void> resume() async {
      h.sync!.onLifecycle(AppLifecycleState.resumed);
      await t.pump(const Duration(milliseconds: 500));
      await idle();
    }

    void solve(String id) {
      final m = mission(id);
      expect(game().submitAnswer(m, m.answer).result, SubmitResult.correct, reason: id);
    }

    Future<void> signIn(String r) async {
      final a = accounts[r]!;
      step('sign in as $r');
      final res = await h.account
          .signIn(email: a['email']! as String, password: a['password']! as String)
          .timeout(const Duration(seconds: 60), onTimeout: () => fail('sign-in as $r did not answer in 60s'));
      if (!res.ok) await check('sign in as $r', false, 'failed: ${res.failure?.name}');
      await until(() => h.account.value.uid == a['uid'] && h.account.value.consentConfirmed, 'signed in as $r, consent read');
    }

    Future<void> signOut() async {
      await h.account.signOut();
      await until(() => h.account.value.uid == null && profile().kind == ProfileKind.guest, 'signed out');
    }

    Future<void> go(String location) async {
      step('go $location');
      c().read(routerProvider).go(location);
      await t.pump(const Duration(milliseconds: 800));
    }

    Future<void> tapKey(String key) async {
      final f = find.byKey(ValueKey(key));
      await t.ensureVisible(f);
      await t.pump();
      await t.tap(f);
      await t.pump(const Duration(milliseconds: 300));
    }

    Future<bool> waitNetwork() async {
      final end = DateTime.now().add(const Duration(seconds: 150));
      while (DateTime.now().isBefore(end)) {
        try {
          final (s, _) = await _http('GET', '/ping', timeout: const Duration(seconds: 3));
          if (s == 200) return true;
        } catch (_) {}
        await t.pump(const Duration(seconds: 2));
      }
      return false;
    }

    Future<Map<String, Object?>> serverCase(String pid) async =>
        (await serverDoc(SyncPaths(uidA, pid).caseDoc('ep01')))!;

    Future<Map<String, Object?>?> summary(String pid) => serverDoc(SyncPaths(uidA, pid).walletSummary);

    /// The case as the server holds it, read the way the game reads a save.
    /// Compared without key order: Firestore keeps no order in maps.
    Future<String> serverCaseJson(String pid) async => jsonEncode(_canon(
        GameProgress.fromJson(Map<String, dynamic>.of((await serverCase(pid))['progress']! as Map<String, Object?>)).toJson()));

    String localCaseJson() => jsonEncode(_canon(repo().load('ep01').toJson()));

    /// The fields where two case saves differ, the play clock left out (it
    /// banks play time on its own when a session starts or ends).
    List<String> playDiff(String a, String b) {
      final x = jsonDecode(a) as Map<String, dynamic>;
      final y = jsonDecode(b) as Map<String, dynamic>;
      return [
        for (final k in {...x.keys, ...y.keys})
          if (k != 'playMillis' && k != 'rev' && jsonEncode(x[k]) != jsonEncode(y[k])) k,
      ];
    }

    /// The fields where the device's case differs from the server's (empty: none).
    Future<List<String>> caseDiff(String pid) async {
      final mine = _canon(repo().load('ep01').toJson()) as Map<String, dynamic>;
      final theirs = jsonDecode(await serverCaseJson(pid)) as Map<String, dynamic>;
      return [for (final k in {...mine.keys, ...theirs.keys}) if (jsonEncode(mine[k]) != jsonEncode(theirs[k])) k];
    }

    Map<String, Object?> savesOf(String id) {
      final prefix = AppConstants.profilePrefix(id);
      return {for (final k in prefs.getKeys()) if (k.startsWith(prefix)) k: prefs.get(k)};
    }

    /// Every run id this device holds for Case 01: its save and the kept conflicts.
    Set<String?> runsKept() => {
          repo().load('ep01').runId,
          for (final x in repo().conflicts)
            if (x['cloud'] case final Map<String, dynamic> cloud) cloud['runId'] as String?,
          for (final x in repo().conflicts)
            if (x['kept'] case final Map<String, dynamic> kept) kept['runId'] as String?,
        };

    // Setup: the DEV app, the real project, nobody signed in.
    await until(() => h.cloud.value == CloudStatus.ready, 'cloud ready');
    h.sync!.debugWrapStore((real) => hook..inner = real); // the store exists once Firebase is ready
    final options = Firebase.app().options;
    final appId = defaultTargetPlatform == TargetPlatform.iOS ? CloudEnvironment.dev.iosAppId : CloudEnvironment.dev.androidAppId;
    await check('setup: DEV project and app', options.projectId == CloudEnvironment.dev.projectId && options.appId == appId &&
        !(FirebaseFirestore.instance.settings.host ?? '').startsWith('localhost') && h.sync != null && h.restore != null,
        'project=${options.projectId}, app=${options.appId == appId ? 'DEV ${defaultTargetPlatform.name}' : 'other'}, '
        'firestore=${FirebaseFirestore.instance.settings.host}, restore=${h.restore != null}');
    if (h.account.value.uid != null) await signOut();

    // 14 (start). The device's guest plays first (its case not started, so no
    // play clock moves when it is left): nothing of it leaves the device.
    expect(profile().kind, ProfileKind.guest);
    final guestId = profile().id;
    game().registerDetective('GUEST');
    await t.pump(const Duration(milliseconds: 300));
    final guestBefore = savesOf(guestId);

    Future<void> guestCheck(String scenario) async {
      final after = savesOf(guestId);
      final same = jsonEncode(after) == jsonEncode(guestBefore);
      final up = await serverDoc('users/$uidA/profiles/$guestId');
      await check(scenario, same && up == null && ProfileStore(prefs).guest?.id == guestId,
          'guest saves unchanged=$same (${after.length} keys), guest in the account=${up != null}');
    }

    if (role == 'A') {
      await signal('A-ready');
      // 1-3. Account a, a new detective, Case 01 m01 with a tip: XP and coins, sent.
      await signIn('a');
      final p = await c().read(profileStoreProvider).addProfile(kind: ProfileKind.account, ownerUid: uidA, detectiveName: 'ANNA');
      await h.host.currentState!.switchTo(p.id);
      await t.pump(const Duration(milliseconds: 300));
      await check('1. A signs in and makes a detective', profile().id == p.id && h.account.value.uid == uidA,
          'A playing ANNA (${p.id.substring(0, 8)}…) as account a');
      game().registerDetective('ANNA');
      game().startInvestigation();
      c().read(walletProvider.notifier).unlockTip(mission('m01'), 1);
      game().useHint(mission('m01'));
      solve('m01');
      await check('2. A plays: XP and coins', caseNow().isCompleted('m01') && xp() > 0 && balance() == 50,
          'A solved=${caseNow().completedMissionIds}, xp=${xp()}, coins=${balance()}');
      await sentAll('A uploads');
      final sum = await summary(p.id);
      final meta = await serverDoc(SyncPaths(uidA, p.id).meta);
      final same = await serverCaseJson(p.id) == localCaseJson();
      await check('3. A synced to the server', same && sum?['balance'] == 50 && meta?['epoch'] == 0,
          'server case == A=$same, balance=${sum?['balance']}, meta epoch=${meta?['epoch']} v${meta?['cloudVersion']}');
      await signal('A-synced', {'pid': p.id, 'xp': xp(), 'season': jsonEncode(repo().loadSeason().toJson())});

      // 8. B played on (m02): A, coming back to the app, shows it.
      final b = await waitFor('B-played') as Map;
      await resume();
      final shown = caseNow().isCompleted('m02') && balance() == 80 && xp() == b['xp'];
      final diffBefore = await caseDiff(p.id);
      // A's own case clock runs on A: what it banked meanwhile goes up next.
      await sentAll('A sends what it banked');
      final diffAfter = await caseDiff(p.id);
      await check('8. A shows B\'s play after coming back', shown && diffAfter.isEmpty,
          'A solved=${caseNow().completedMissionIds}, coins=${balance()}, xp=${xp()} (B ${b['xp']}), '
          'A vs server before sending: $diffBefore, after: $diffAfter');
      await signal('A-reflects');

      // 13. Both devices start Case 01 again at once (Play again): two runs
      // with the same run number. B is offline; A sends first.
      await waitFor('B-offline');
      game().playAgain();
      solve('m01'); // a replay: no coins
      game().lookUpWord('a-run');
      final runA = caseNow().runId;
      await sentAll('A new run');
      await signal('A-run-sent', runA);
      final bRun = await waitFor('B-conflict') as Map;
      await resume();
      final serverRun = (await serverCase(p.id))['runId'];
      final kept = runsKept();
      final sumNow = await summary(p.id);
      // A's run is never lost here; B's is kept on the server (B won) or on B.
      await check('13. A after the conflict: its run kept, nothing lost', kept.contains(runA) &&
          (serverRun == runA || (serverRun == bRun['runB'] && kept.contains(bRun['runB']))) && sumNow?['balance'] == 80,
          'server run=${serverRun == runA ? 'A' : serverRun == bRun['runB'] ? 'B' : serverRun}, A holds runs: '
          '${kept.map((r) => r == runA ? 'A' : r == bRun['runB'] ? 'B' : r).toList()}, balance=${sumNow?['balance']}');
      await signal('A-conflict-done');

      // 12. A New Adventure on A: epoch 1, played again from the start.
      await game().resetAll();
      await t.pump(const Duration(milliseconds: 300));
      game().registerDetective('ANNA');
      game().startInvestigation();
      solve('m01');
      game().lookUpWord('after-reset');
      await sentAll('A reset');
      final m1 = await serverDoc(SyncPaths(uidA, p.id).meta);
      final s1 = await summary(p.id);
      await check('12. New Adventure on A: the server moves to epoch 1', m1?['epoch'] == 1 && s1?['epoch'] == 1 && s1?['balance'] == 50,
          'meta epoch=${m1?['epoch']}, wallet summary epoch=${s1?['epoch']} balance=${s1?['balance']}');
      await signal('A-reset', p.id);
      await waitFor('B-reset-done');
      await resume();
      final after = await serverCase(p.id);
      final words = (after['progress']! as Map)['lookedUpWords'] as List;
      await check('12. no old record comes back (server and A)', after['epoch'] == 1 &&
          !words.any((w) => ['a-run', 'b-run'].contains(w)) && !caseNow().isCompleted('m02') && !caseNow().lookedUpWords.contains('b-run'),
          'server epoch=${after['epoch']}, words=$words, A solved=${caseNow().completedMissionIds}');

      // 14. The guest: still the device's own, never sent.
      await signOut();
      await guestCheck('14. A: the guest kept, not uploaded');
      h.sync!.dispose();
      await signal('A-end');
    } else if (role == 'B') {
      // 4. Account a on B: its detective is not on this device.
      final a = await waitFor('A-synced') as Map;
      final pid = a['pid'] as String;
      await signIn('a');
      await check('4. B signs in, no local detective', ProfileStore(prefs).profile(pid) == null && savesOf(pid).isEmpty,
          'B registry has it=${ProfileStore(prefs).profile(pid) != null}, saves=${savesOf(pid).length}');

      // 10. No network: the list cannot be read; nothing changes. Back: TRY AGAIN.
      final registry = jsonEncode(ProfileStore(prefs).read()!.toJson());
      await networkOff(45);
      await t.pump(const Duration(seconds: 4));
      await go(Routes.profiles);
      await until(() => find.text(_offline).evaluate().isNotEmpty, 'the offline message', timeout: const Duration(seconds: 60));
      final offlineSame = jsonEncode(ProfileStore(prefs).read()!.toJson()) == registry && savesOf(pid).isEmpty;
      final back = await waitNetwork();
      await t.pump(const Duration(seconds: 3));
      // Firestore takes a moment to reconnect after the network is back: as
      // a player would, TRY AGAIN is pressed again while it still says so.
      var tries = 0;
      final listed = find.byKey(ValueKey('cloud-profile-$pid'));
      final end = DateTime.now().add(const Duration(seconds: 90));
      while (listed.evaluate().isEmpty && DateTime.now().isBefore(end)) {
        final retry = find.text('TRY AGAIN');
        if (retry.evaluate().isNotEmpty) {
          tries++;
          await t.ensureVisible(retry);
          await t.tap(retry);
        }
        for (var i = 0; i < 50 && listed.evaluate().isEmpty; i++) {
          await t.pump(const Duration(milliseconds: 200));
        }
      }
      await check('10. offline: restore refused, nothing changed; retried after reconnect', offlineSame && back && listed.evaluate().isNotEmpty,
          'offline message shown, registry and saves unchanged=$offlineSame, network back=$back, '
          'listed after $tries TRY AGAIN press(es)');
      await check('5. IN YOUR ACCOUNT lists the detective', find.text('IN YOUR ACCOUNT').evaluate().isNotEmpty &&
          find.text('ANNA').evaluate().isNotEmpty, 'section shown, ANNA listed (${pid.substring(0, 8)}…)');

      // 11. Sign-out, then another account, in the middle of a restore.
      final d = (await h.restore!.accountDetectives()).detectives.singleWhere((x) => x.id == pid);
      hook.beforeList = (path) async {
        if (!path.endsWith('/cases')) return;
        hook.beforeList = null;
        await h.account.signOut();
        await t.pump(const Duration(milliseconds: 500));
      };
      final r1 = await h.restore!.restore(d);
      final out1 = ProfileStore(prefs).profile(pid) == null && savesOf(pid).isEmpty;
      await signIn('a');
      hook.beforeList = (path) async {
        if (!path.endsWith('/cases')) return;
        hook.beforeList = null;
        await h.account.signOut();
        final b = accounts['b']!;
        await h.account.signIn(email: b['email']! as String, password: b['password']! as String);
        await t.pump(const Duration(milliseconds: 500));
      };
      final r2 = await h.restore!.restore(d);
      final out2 = ProfileStore(prefs).profile(pid) == null && savesOf(pid).isEmpty;
      await until(() => h.account.value.uid == accounts['b']!['uid'] && h.account.value.consentConfirmed, 'account b');
      final bList = await h.restore!.accountDetectives();
      await check('11. sign-out / another account mid-restore: nothing saved, a\'s detective not shown to b',
          r1 != null && r2 != null && out1 && out2 && bList.problem == null && bList.detectives.isEmpty,
          'sign-out → ${r1?.name}, nothing saved=$out1; switch to b → ${r2?.name}, nothing saved=$out2; b lists ${bList.detectives.length}');
      await signOut();
      await signIn('a');

      // 6. Restore from the screen: cases, missions, XP, coins, season.
      await go(Routes.profiles);
      await until(() => find.byKey(ValueKey('cloud-profile-$pid')).evaluate().isNotEmpty, 'listed', timeout: const Duration(seconds: 60));
      await tapKey('cloud-profile-$pid');
      await until(() => profile().id == pid, 'restored and playing', timeout: const Duration(seconds: 60));
      final restored = ProfileStore(prefs).profile(pid)!;
      final caseSame = localCaseJson() == await serverCaseJson(pid);
      final seasonSame = jsonEncode(repo().loadSeason().toJson()) == a['season'];
      await check('6. restored: case, missions, XP, coins, season', caseSame && caseNow().isCompleted('m01') && xp() == a['xp'] &&
          balance() == 50 && seasonSame && restored.ownerUid == uidA && restored.kind == ProfileKind.account && repo().conflicts.isEmpty,
          'case == server=$caseSame, solved=${caseNow().completedMissionIds}, xp=${xp()} (A ${a['xp']}), coins=${balance()}, '
          'season same=$seasonSame, owner a=${restored.ownerUid == uidA}, conflicts=${repo().conflicts.length}');

      // 7. B plays on: m02, sent.
      solve('m02');
      await sentAll('B plays on');
      final up = await serverCase(pid);
      final sum = await summary(pid);
      await check('7. B plays on and syncs', ((up['progress']! as Map)['completedMissionIds'] as List).toSet().containsAll(['m01', 'm02']) &&
          sum?['balance'] == 80 && balance() == 80,
          'server solved=${(up['progress']! as Map)['completedMissionIds']}, server balance=${sum?['balance']}, B coins=${balance()}');
      await signal('B-played', {'xp': xp()});
      await waitFor('A-reflects');

      // 9. B starts again: the detective is on the device, as it was.
      final before = localCaseJson();
      final version = (await serverCase(pid))['cloudVersion'];
      h.sync!.dispose();
      h.account.dispose();
      await app.main();
      h = app.debugApp!;
      await until(() => h.cloud.value == CloudStatus.ready, 'cloud ready after restart');
      h.sync!.debugWrapStore((real) => hook..inner = real);
      await until(() => h.account.value.uid == uidA && h.account.value.consentConfirmed, 'session back after restart');
      await go(Routes.profiles);
      await until(() => find.byKey(ValueKey('profile-$pid')).evaluate().isNotEmpty, 'on this device');
      final offered = find.byKey(ValueKey('cloud-profile-$pid')).evaluate().isNotEmpty;
      await tapKey('profile-$pid');
      await until(() => profile().id == pid, 'chosen');
      await sentAll('B after restart');
      final v2 = (await serverCase(pid))['cloudVersion'];
      final changed = playDiff(before, localCaseJson());
      final vsServer = await caseDiff(pid);
      // Only the play clock may have moved (banked on leaving and opening the
      // case); it is sent like any save. Nothing played is lost or redone.
      await check('9. B restarted: the restored record stays', changed.isEmpty && vsServer.isEmpty && balance() == 80 && !offered &&
          repo().conflicts.isEmpty, 'play fields changed=$changed, B vs server=$vsServer, coins=${balance()}, offered again=$offered, '
          'server version $version → $v2 (play clock only)');

      // 13. Offline, B plays Case 01 again; A does the same and sends first.
      await signal('B-offline');
      await networkOff(40);
      await t.pump(const Duration(seconds: 4));
      // Played away from the network, then the app put aside: nothing is
      // tried until it comes back (its first run then brings A's run down).
      game().playAgain();
      solve('m01');
      game().lookUpWord('b-run');
      h.sync!.onLifecycle(AppLifecycleState.paused);
      final runB = caseNow().runId;
      final localB = localCaseJson();
      await t.pump(const Duration(seconds: 3));
      expect(await waitNetwork(), isTrue);
      final runA = await waitFor('A-run-sent');
      // Back: the pull meets A's run (same run number, another run).
      h.sync!.onLifecycle(AppLifecycleState.resumed);
      await until(() => repo().conflicts.any((x) => x['kind'] == 'restoreHeld' && x['subject'] == 'case:ep01'), 'the pull holds it',
          timeout: const Duration(seconds: 90));
      final held = repo().conflicts.firstWhere((x) => x['kind'] == 'restoreHeld');
      final heldRun = (held['cloud'] as Map)['runId'];
      await idle();
      final kept = runsKept();
      final serverRun = (await serverCase(pid))['runId'];
      final sum13 = await summary(pid);
      await check('13. conflict held by the pull: B\'s play not overwritten, A\'s run kept', heldRun == runA && kept.containsAll([runA, runB]) &&
          sum13?['balance'] == 80 && (sum13?['balance'] as int) >= 0,
          'held cloud run is A\'s=${heldRun == runA}, B local before send=${localB.length} chars, B holds runs: '
          '${kept.map((r) => r == runA ? 'A' : r == runB ? 'B' : r).toList()}, server run now=${serverRun == runA ? 'A' : serverRun == runB ? 'B' : serverRun}, '
          'balance=${sum13?['balance']} (replays paid 0)');
      await signal('B-conflict', {'runB': runB});
      await waitFor('A-conflict-done');

      // 12. A New Adventure on A: B, coming back, moves to epoch 1.
      await waitFor('A-reset');
      await resume();
      final caseB = caseNow();
      await check('12. B follows the New Adventure; the old play does not come back', repo().epoch == 1 &&
          !caseB.isCompleted('m02') && !caseB.lookedUpWords.contains('b-run') && !caseB.lookedUpWords.contains('a-run') &&
          caseB.lookedUpWords.contains('after-reset') && balance() == 50 && repo().conflicts.any((x) => x['kind'] == 'epoch'),
          'B epoch=${repo().epoch}, solved=${caseB.completedMissionIds}, words=${caseB.lookedUpWords}, coins=${balance()}, old play kept aside');
      game().lookUpWord('b-after-reset');
      await sentAll('B after reset');
      final words = ((await serverCase(pid))['progress']! as Map)['lookedUpWords'] as List;
      await check('12. B\'s next save does not bring the old epoch back', !words.contains('b-run') && words.contains('b-after-reset'),
          'server words=$words');
      await signal('B-reset-done');

      // 14. The guest.
      await signOut();
      await guestCheck('14. B: the guest kept, not uploaded');
      h.sync!.dispose();
      await waitFor('A-end');
    } else {
      // C (iOS simulator, after A and B): a third device restores the
      // detective as it is now (epoch 1).
      final pid = await waitFor('A-reset') as String;
      await signIn('a');
      await go(Routes.profiles);
      await until(() => find.byKey(ValueKey('cloud-profile-$pid')).evaluate().isNotEmpty, 'listed on iOS', timeout: const Duration(seconds: 60));
      await tapKey('cloud-profile-$pid');
      await until(() => profile().id == pid, 'restored on iOS', timeout: const Duration(seconds: 60));
      final same = playDiff(localCaseJson(), await serverCaseJson(pid)).isEmpty;
      final sum = await summary(pid);
      await check('iOS: restore on a third device (epoch 1)', same && repo().epoch == 1 && balance() == sum?['balance'] &&
          !caseNow().lookedUpWords.contains('b-run') && repo().conflicts.isEmpty,
          'case == server=$same, epoch=${repo().epoch}, coins=${balance()} (server ${sum?['balance']}), words=${caseNow().lookedUpWords}');
      await signOut();
      await guestCheck('iOS: the guest kept, not uploaded');
      h.sync!.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 40)));
}
