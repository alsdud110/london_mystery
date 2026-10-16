// Phase 4.5-5 on the REAL DEV project (never PROD): two case files of one
// case and the detective's choice, with the real app on two dedicated
// Android emulators (A, B) and, after them, the dedicated iOS simulator (C).
// Started by the host's orchestrator, which makes the run's test accounts and
// consent, holds the barriers, reads the run's own documents as the admin,
// and switches an Android device's network off and on:
//   cd firebase && node scripts/dev_two_device_e2e.mjs --test integration_test/sync_dev_conflict_test.dart --ios <udid>
// Built with LM_CLOUD_SYNC=dev, LM_E2E_ROLE (A, B or C) and LM_E2E_HOST.
//
// A conflict ("round"): both devices play Case 01 again (Play again) under
// the same run number, B away from the network. A sends first; B, back,
// holds A's run (its own play unsent), then sends its run (further along)
// and keeps A's; A, back, takes B's run and keeps its own. Both then show
// two case files.
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
import 'package:london_mystery/data/sync/case_conflicts.dart';
import 'package:london_mystery/data/sync/cloud/cloud_catalog.dart';
import 'package:london_mystery/data/sync/cloud/cloud_codec.dart';
import 'package:london_mystery/data/sync/cloud/cloud_store.dart';
import 'package:london_mystery/data/sync/cloud/sync_sender.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/sync/case_file_choice.dart';
import 'package:london_mystery/features/sync/sync_session.dart';
import 'package:london_mystery/main.dart' as app;
import 'package:london_mystery/widgets/game_button.dart';
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

void step(String what) => debugPrint('E2E $role ${DateTime.now().toIso8601String()}: $what');

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

/// Records a scenario; a failure stops every device at once (data loss or
/// accounts mixed: nothing goes on).
Future<void> check(String scenario, bool ok, String observed) async {
  step('${ok ? 'PASS' : 'FAIL'} $scenario');
  await _http('POST', '/result', body: {'device': role, 'scenario': scenario, 'ok': ok, 'observed': observed});
  if (!ok) {
    await signal('abort', '$role: $scenario: $observed');
    fail('$scenario: $observed');
  }
}

/// The app's store with a hook before each collection read (a sign-out or
/// another account in the middle of a choice).
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

Object? _canon(Object? v) => switch (v) {
      Map m => {for (final k in (m.keys.map((k) => '$k').toList()..sort())) k: _canon(m[k])},
      List l => [for (final x in l) _canon(x)],
      _ => v,
    };

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final season = MockEpisodeRepository.bundled();
  final ep01 = season.first;
  final codec = CloudCodec(CloudCatalog.of(season));
  final episodeIds = [for (final e in season) e.id];
  Mission mission(String id) => ep01.missions.firstWhere((m) => m.id == id);

  testWidgets('case files on the real DEV project: role $role', (t) async {
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
    CaseChoice? choice() => CaseConflicts.choiceFor(repo(), 'ep01');
    List<String> statuses() => [for (final r in repo().conflicts) if (r['kind'] == 'case' || r['kind'] == 'restoreHeld') '${r['status'] ?? 'legacy'}'];

    Future<void> idle() async {
      await t.pump(const Duration(milliseconds: 2500));
      await until(() => h.sync!.running == null && !h.sync!.planned, 'sync idle', timeout: const Duration(seconds: 120));
    }

    Future<void> sentAll(String what, {Duration timeout = const Duration(seconds: 120)}) async {
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

    Future<void> playAs(String pid) async {
      if (profile().id == pid) return;
      await h.host.currentState!.switchTo(pid);
      await until(() => profile().id == pid, 'playing $pid');
      await t.pump(const Duration(milliseconds: 300));
    }

    Future<void> go(String location) async {
      step('go $location');
      c().read(routerProvider).go(location);
      await t.pump(const Duration(milliseconds: 800));
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

    Future<Map<String, Object?>> serverCase(String pid) async => (await serverDoc(SyncPaths(uidA, pid).caseDoc('ep01')))!;
    Future<Map<String, Object?>?> meta(String pid) => serverDoc(SyncPaths(uidA, pid).meta);
    Future<Map<String, Object?>?> summary(String pid) => serverDoc(SyncPaths(uidA, pid).walletSummary);

    Future<GameProgress> serverRun(String pid) async =>
        GameProgress.fromJson(Map<String, dynamic>.of((await serverCase(pid))['progress']! as Map<String, Object?>));

    /// Fields where this device's case differs from the server's, the play
    /// clock and revision count left out (they move on their own).
    Future<List<String>> caseDiff(String pid) async {
      final mine = _canon(repo().load('ep01').toJson()) as Map<String, dynamic>;
      final theirs = _canon((await serverRun(pid)).toJson()) as Map<String, dynamic>;
      return [
        for (final k in {...mine.keys, ...theirs.keys})
          if (k != 'playMillis' && k != 'rev' && jsonEncode(mine[k]) != jsonEncode(theirs[k])) k,
      ];
    }

    /// A case save without its play clock and revision count.
    String playOf(GameProgress p) {
      final m = _canon(p.toJson())! as Map<String, dynamic>
        ..remove('playMillis')
        ..remove('rev');
      return jsonEncode(m);
    }

    /// What a choice may change on this device for [pid]: its case (the
    /// clock aside), its kept files, its coins. Read from the saves, whoever
    /// plays now.
    String choiceState(String pid) {
      final r = SharedPrefsProgressRepository.peek(prefs, profileId: pid);
      return jsonEncode([playOf(r.load('ep01')), r.conflicts, r.loadWallet()?.toJson()]);
    }

    /// The server's case of [pid]: its run, number, epoch and play (the clock aside).
    Future<String> serverState(String pid) async {
      final d = await serverCase(pid);
      return jsonEncode([d['runId'], d['runSeq'], d['epoch'], playOf(await serverRun(pid))]);
    }

    Map<String, Object?> savesOf(String id) {
      final prefix = AppConstants.profilePrefix(id);
      return {for (final k in prefs.getKeys()) if (k.startsWith(prefix)) k: prefs.get(k)};
    }

    /// Every run this device keeps for Case 01 (its save and every record).
    Set<String?> runsKept() => {
          repo().load('ep01').runId,
          for (final r in repo().conflicts) CaseConflicts.runOf(r)?.runId,
        };

    /// Records kept for Case 01 at the current epoch (the per-case limit
    /// counts these).
    /// Case 01's kept records, briefly (status, reason, run number, run,
    /// missions, side), and the run playing: evidence in a check's message.
    String caseRecordsNow() {
      final cur = repo().load('ep01');
      return 'playing ${cur.runId?.substring(0, 6)}/${cur.runSeq}/${cur.completedMissionIds.length}; '
          '${[for (final r in repo().conflicts) if (CaseConflicts.caseOf(r) == 'ep01') '${r['status']}|${r['reason']}|${r['runSeq']}|${(r['runId'] as String?)?.substring(0, 6)}|${CaseConflicts.runOf(r)?.completedMissionIds.length}|${r['side']}'].join(', ')}';
    }

    int keptCount() => repo().conflicts.where((r) => CaseConflicts.caseOf(r) == 'ep01' && (r['epoch'] == null || r['epoch'] == repo().epoch)).length;

    Future<ChoiceResult> chooseNow(CaseChoice ch, {required bool keepPlaying, required String pid}) =>
        c().read(caseFileChooserProvider).choose(
              repo: repo(),
              choice: ch,
              keepPlaying: keepPlaying,
              isStillValid: () => profile().id == pid && h.account.value.uid == uidA,
              applied: (id) => refreshFromSaves(c(), 'case:$id'),
            );

    /// The choice through the screen: the card's KEEP PLAYING THIS ONE, then
    /// the promise.
    Future<void> chooseOnScreen(String card) async {
      await go(Routes.caseFiles('ep01'));
      await until(() => find.text('Two Case Files').evaluate().isNotEmpty, 'the two files on screen');
      final button = find.descendant(of: find.byKey(ValueKey(card)), matching: find.widgetWithText(GameButton, 'KEEP PLAYING THIS ONE'));
      await t.ensureVisible(button);
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(button);
      await until(() => find.text("We'll keep the other file safe.").evaluate().isNotEmpty, 'the promise');
      await t.tap(find.text('YES, KEEP PLAYING'));
      step('YES tapped');
      final end = DateTime.now().add(const Duration(seconds: 90));
      while (find.text('CASE FILES').evaluate().isEmpty && DateTime.now().isBefore(end)) {
        await t.pump(const Duration(milliseconds: 200));
      }
      if (find.text('CASE FILES').evaluate().isEmpty) {
        step('on screen: ${[for (final e in find.byType(Text).evaluate()) (e.widget as Text).data].whereType<String>().join(' | ')}');
        await check('wait', false, 'timed out: back on the case files');
      }
      await t.pump(const Duration(seconds: 3));
    }

    // Setup: the DEV app, the real project, nobody signed in.
    await until(() => h.cloud.value == CloudStatus.ready, 'cloud ready');
    h.sync!.debugWrapStore((real) => hook..inner = real);
    final options = Firebase.app().options;
    final appId = defaultTargetPlatform == TargetPlatform.iOS ? CloudEnvironment.dev.iosAppId : CloudEnvironment.dev.androidAppId;
    await check('setup: DEV project and app', options.projectId == CloudEnvironment.dev.projectId && options.appId == appId &&
        !(FirebaseFirestore.instance.settings.host ?? '').startsWith('localhost') && h.sync != null,
        'project=${options.projectId}, app=${options.appId == appId ? 'DEV ${defaultTargetPlatform.name}' : 'other'}, '
        'firestore=${FirebaseFirestore.instance.settings.host}');
    if (h.account.value.uid != null) await signOut();

    // 17 (start). The device's guest plays first: never sent.
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

    // ---- a round: the same run number played differently on A and B ----

    /// A's side of a round: plays m01 in a new run while B is offline, sends,
    /// then takes B's run when it comes back. Returns A's run id.
    Future<String> roundA(int n, String pid) async {
      await waitFor('R$n-B-offline');
      game().playAgain();
      game().startInvestigation();
      solve('m01');
      final runA = caseNow().runId!;
      await sentAll('R$n: A sends its run');
      await signal('R$n-A-sent', runA);
      await waitFor('R$n-B-sent');
      await resume();
      await until(() => choice() != null, 'R$n: two files on A', timeout: const Duration(seconds: 90));
      return runA;
    }

    /// B's side: offline, plays m01 and m02 in a new run (the app put aside),
    /// back: holds A's run, sends its own. Returns B's run id.
    Future<String> roundB(int n, String pid) async {
      await signal('R$n-B-offline');
      await networkOff(45);
      await t.pump(const Duration(seconds: 4));
      h.sync!.onLifecycle(AppLifecycleState.paused);
      game().playAgain();
      game().startInvestigation();
      solve('m01');
      solve('m02');
      final runB = caseNow().runId!;
      expect(await waitNetwork(), isTrue, reason: 'network back');
      await waitFor('R$n-A-sent');
      h.sync!.onLifecycle(AppLifecycleState.resumed);
      await t.pump(const Duration(milliseconds: 500));
      await idle();
      await sentAll('R$n: B sends its run');
      await until(() => choice() != null, 'R$n: two files on B', timeout: const Duration(seconds: 90));
      await signal('R$n-B-sent', runB);
      return runB;
    }

    if (role == 'A') {
      await signal('A-ready');
      // 1. Account a, the detective ANNA, Case 01 m01; sent.
      await signIn('a');
      final p = await c().read(profileStoreProvider).addProfile(kind: ProfileKind.account, ownerUid: uidA, detectiveName: 'ANNA');
      await playAs(p.id);
      game().registerDetective('ANNA');
      game().startInvestigation();
      solve('m01');
      await sentAll('A uploads');
      await signal('A-synced', p.id);
      await waitFor('B-restored');
      await check('1. A and B sign in as the same detective', profile().id == p.id && h.account.value.uid == uidA,
          'A playing ANNA (${p.id.substring(0, 8)}…), B restored it');

      // ---- Round 1: A keeps ON THIS DEVICE (its own run), on screen ----
      final runA1 = await roundA(1, p.id);
      final runB1 = (await waitFor('R1-B-sent'))! as String;
      final c1 = choice()!;
      final m0 = await meta(p.id);
      final before1 = await serverCase(p.id);
      await check('2. a conflict: the further-along run plays everywhere, A keeps its own as a second file',
          c1.playing.run.runId == runB1 && c1.other.run.runId == runA1 && c1.other.side == FileSide.device &&
              before1['runId'] == runB1 && statuses().contains('open'),
          'A plays ${c1.playing.run.runId == runB1 ? 'B' : '?'}\'s run (${c1.playing.run.completedMissionIds}), other file = A\'s '
          '(${c1.other.side.name}), server run=B, statuses=${statuses()}');
      final coins1 = balance();
      final sum1 = (await summary(p.id))?['balance'];
      await chooseOnScreen('file-other');
      final waiting1 = statuses().contains('waiting') || statuses().contains('resolved');
      await sentAll('R1: A\'s choice sent');
      final after1 = await serverCase(p.id);
      final m1 = await meta(p.id);
      final chosenId1 = CaseConflicts.choiceRunId(c1.other.run, c1.other.run.runSeq + 1);
      await check('3. A chooses ON THIS DEVICE: the next run number, the same epoch, sent and resolved',
          after1['runId'] == chosenId1 && after1['runSeq'] == (before1['runSeq']! as int) + 1 && after1['epoch'] == before1['epoch'] &&
              m1?['epoch'] == m0?['epoch'] && (after1['cloudVersion']! as int) > (before1['cloudVersion']! as int) &&
              waiting1 && !statuses().contains('waiting') && statuses().contains('resolved') && choice() == null,
          'server runSeq ${before1['runSeq']}→${after1['runSeq']}, epoch ${before1['epoch']}→${after1['epoch']} (meta ${m0?['epoch']}→${m1?['epoch']}), '
          'cloudVersion ${before1['cloudVersion']}→${after1['cloudVersion']}, statuses=${statuses()}');
      await check('15. R1: coins unchanged, XP of the chosen file',
          balance() == coins1 && (await summary(p.id))?['balance'] == sum1 && xp() == XpBreakdown.totalFor(ep01, c1.other.run),
          'A coins $coins1→${balance()}, server $sum1→${(await summary(p.id))?['balance']}, XP ${xp()}');
      // 8. The same choice again: done once.
      final again = await chooseNow(c1, keepPlaying: false, pid: p.id);
      await idle();
      final after1b = await serverCase(p.id);
      await check('8. the same choice twice: no second run number', again == ChoiceResult.alreadyDone &&
          after1b['runSeq'] == after1['runSeq'] && after1b['runId'] == after1['runId'],
          'second choice → ${again.name}, server runSeq ${after1['runSeq']}→${after1b['runSeq']}, same run=${after1b['runId'] == after1['runId']}');
      await signal('R1-chosen', {'runSeq': after1['runSeq'], 'runId': after1['runId']});
      await waitFor('R1-B-checked');
      await check('6. R1: the file not chosen is kept on A', runsKept().containsAll([runA1, runB1]) &&
          repo().conflicts.any((r) => CaseConflicts.runOf(r)?.runId == runB1 && r['status'] == 'archived'),
          'A keeps runs: A=${runsKept().contains(runA1)}, B=${runsKept().contains(runB1)} (archived)');

      // ---- Round 2: B keeps IN YOUR ACCOUNT (A's run), after DECIDE LATER ----
      final runA2 = await roundA(2, p.id);
      await waitFor('R2-B-chosen');
      await resume();
      await sentAll('A after R2');
      await check('5. R2: B chose IN YOUR ACCOUNT (A\'s run): A plays it, matches the server', choice() == null &&
          caseNow().completedMissionIds.length == 1 && (await caseDiff(p.id)).isEmpty && runsKept().contains(runA2),
          'A solved=${caseNow().completedMissionIds}, A vs server=${await caseDiff(p.id)}');
      await signal('R2-A-checked');

      // ---- Round 3: B chooses offline ----
      await roundA(3, p.id);
      await waitFor('R3-B-chosen');
      await resume();
      await check('12. R3: B\'s offline choice reached A after it reconnected', choice() == null && (await caseDiff(p.id)).isEmpty,
          'A vs server=${await caseDiff(p.id)}');
      await signal('R3-A-checked');

      // ---- Round 4: A chooses first; B's older view must not be applied ----
      await roundA(4, p.id);
      await waitFor('R4-B-has-view');
      final s4 = await serverCase(p.id);
      expect(await chooseNow(choice()!, keepPlaying: true, pid: p.id), ChoiceResult.applied);
      await sentAll('R4: A chooses first');
      final a4 = await serverCase(p.id);
      await signal('R4-A-chosen', {'runId': a4['runId'], 'runSeq': a4['runSeq'], 'before': s4['runSeq']});
      await waitFor('R4-B-checked');

      // ---- Round 5: the same file chosen on both, both offline ----
      // The file playing on both (B's run): choosing it keeps nothing new, so
      // B — which has kept a file in every round so far — stays under the
      // per-case limit (§19.8; the limit itself is test 18).
      await roundA(5, p.id);
      await waitFor('R5-ready');
      final c5 = choice()!;
      final kept5 = keptCount();
      await signal('R5-A-offline');
      await networkOff(45);
      await t.pump(const Duration(seconds: 4));
      final r5 = await chooseNow(c5, keepPlaying: true, pid: p.id); // B's run, playing here
      expect(await waitNetwork(), isTrue);
      await waitFor('R5-B-back');
      await resume();
      await sentAll('R5: A sends');
      await signal('R5-A-sent');
      await waitFor('R5-B-sent');
      await resume();
      final s5 = await serverCase(p.id);
      await check('9. R5: both chose the same file at once: one run, one new number, nothing asked again',
          r5 == ChoiceResult.applied && s5['runId'] == CaseConflicts.choiceRunId(c5.playing.run, c5.other.run.runSeq + 1) &&
              s5['runSeq'] == c5.other.run.runSeq + 1 && choice() == null && (await caseDiff(p.id)).isEmpty,
          'A → ${r5.name}, server runSeq=${s5['runSeq']} (from ${c5.other.run.runSeq}), run = the shared choice id: '
          '${s5['runId'] == CaseConflicts.choiceRunId(c5.playing.run, c5.other.run.runSeq + 1)}, A vs server=${await caseDiff(p.id)}, kept $kept5→${keptCount()}');
      await signal('R5-A-checked', s5['runId']);

      // ---- Round 6: different files chosen at once, both offline ----
      await roundA(6, p.id);
      await waitFor('R6-ready');
      final c6 = choice()!;
      await signal('R6-A-offline');
      await networkOff(45);
      await t.pump(const Duration(seconds: 4));
      final kept6 = keptCount();
      final r6 = await chooseNow(c6, keepPlaying: false, pid: p.id); // A's run (1 mission)
      expect(await waitNetwork(), isTrue);
      // A's choice reaches the server before B is back (B is offline longer):
      // a retry B makes on its own once back cannot overtake it.
      await resume();
      await sentAll('R6: A sends');
      await signal('R6-A-sent');
      await waitFor('R6-B-back');
      await waitFor('R6-B-sent');
      await resume();
      await sentAll('R6: A settles');
      final s6 = await serverCase(p.id);
      // No endless conflict: two more rounds of syncing change nothing.
      await resume();
      await waitFor('R6-B-resumed');
      await resume();
      final s6b = await serverCase(p.id);
      final again6 = choice();
      await check('10. R6: different files chosen at once: the same run on both, the other offered again, no endless loop',
          r6 == ChoiceResult.applied && (await caseDiff(p.id)).isEmpty && s6b['runSeq'] == s6['runSeq'] &&
              s6b['runId'] == s6['runId'] && caseNow().completedMissionIds.length == 2 && again6 != null &&
              again6.other.run.completedMissionIds.length == 1,
          'A → ${r6.name}, server runSeq ${s6['runSeq']}→${s6b['runSeq']}, same run=${s6b['runId'] == s6['runId']} after two more syncs, '
          'A plays ${caseNow().completedMissionIds} (further along), asked again: ${again6 != null}, kept before choosing $kept6');
      await signal('R6-A-checked', {'runSeq': s6b['runSeq'], 'runId': s6b['runId']});
      await waitFor('R6-B-checked');

      // ---- 18. Ten kept files for the case: the choice is refused, play goes on ----
      final c18 = choice()!;
      final epoch = repo().epoch;
      var kept = repo().conflicts.where((r) => CaseConflicts.caseOf(r) == 'ep01' && (r['epoch'] == null || r['epoch'] == epoch)).length;
      for (var i = 0; kept < CaseConflicts.perCaseLimit; i++, kept++) {
        repo().keepConflict(CaseConflicts.caseRecord(
          caseId: 'ep01',
          run: c18.other.run.copyWith(runId: 'fill-$i'),
          side: FileSide.device,
          epoch: epoch,
          reason: 'later run',
          at: DateTime.now(),
        ));
      }
      final ids18 = {for (final r in repo().conflicts) r['id']};
      final save18 = playOf(repo().load('ep01'));
      final s18 = await serverState(p.id);
      final r18 = await chooseNow(c18, keepPlaying: false, pid: p.id);
      await idle();
      final s18b = await serverState(p.id);
      final idsAfter = {for (final r in repo().conflicts) r['id']};
      final refusedSafely = r18 == ChoiceResult.cannotKeep && idsAfter.containsAll(ids18) &&
          playOf(repo().load('ep01')) == save18 && s18b == s18;
      // Play goes on, and syncs.
      solve('m03');
      await sentAll('A plays on after the refusal');
      final up18 = await serverRun(p.id);
      await check('18. ten kept files: the choice that must keep one more is refused, nothing removed; play still syncs',
          refusedSafely && up18.isCompleted('m03'),
          'choice → ${r18.name}, records kept ${ids18.length}→${idsAfter.length} (none removed), save unchanged, '
          'server unchanged by it; then m03 solved and sent=${up18.isCompleted('m03')}');

      // ---- 11. A tie (same progress, revision, play time) in both send orders ----
      Future<String> tieProfile(String name) async {
        final q = await c().read(profileStoreProvider).addProfile(kind: ProfileKind.account, ownerUid: uidA, detectiveName: name);
        await playAs(q.id);
        game().registerDetective(name);
        await sentAll('$name made');
        return q.id;
      }

      final t1 = await tieProfile('TESS');
      final t2 = await tieProfile('TOBY');
      await signal('TIE-made', {'t1': t1, 't2': t2});
      GameProgress tieRun(String name, String id) => GameProgress(
            detectiveName: name,
            introSeen: true,
            completedMissionIds: const ['m01'],
            attempts: const {'m01': 1},
            xpRules: const {'m01': XpBreakdown.currentRule},
            playMillis: 90000,
            runId: id,
            runSeq: 1,
            rev: 3,
          );
      Future<void> sendRun(String pid, GameProgress run) async {
        await playAs(pid);
        repo().save(run, 'ep01');
        refreshFromSaves(c(), 'case:ep01');
        await sentAll('a tie run sent');
      }

      // TESS: A sends first, then B. TOBY: B first, then A.
      await sendRun(t1, tieRun('TESS', 'tie-from-a'));
      await signal('TIE1-A-sent');
      await waitFor('TIE2-B-sent');
      await sendRun(t2, tieRun('TOBY', 'tie-from-a'));
      await signal('TIE2-A-sent');
      await waitFor('TIE-B-done');
      final w1 = (await serverCase(t1))['runId'];
      final w2 = (await serverCase(t2))['runId'];
      await playAs(t1);
      await resume();
      final local1 = repo().load('ep01').runId;
      await playAs(t2);
      await resume();
      final local2 = repo().load('ep01').runId;
      await check('11. a tie: the same winner whichever device sent last, on the server and A', w1 == 'tie-from-b' &&
          w2 == 'tie-from-b' && local1 == w1 && local2 == w2,
          'TESS (A then B) server=$w1, TOBY (B then A) server=$w2, A plays TESS=$local1 TOBY=$local2');

      // 18 (size). Kept data over 512 KB: the choice that must keep more is refused.
      // The tie left nothing to choose (the same play): a second file with
      // other play is kept for TESS first, so there is a choice to refuse.
      await playAs(t1);
      repo().keepConflict(CaseConflicts.caseRecord(
        caseId: 'ep01',
        run: tieRun('TESS', 'size-other').copyWith(attempts: const {'m01': 2}),
        side: FileSide.account,
        epoch: repo().epoch,
        reason: CaseConflicts.reasonSameNumber,
        at: DateTime.now(),
      ));
      final ct = choice();
      final keptT = keptCount();
      repo().keepConflict({
        ...CaseConflicts.caseRecord(caseId: 'ep02', run: GameProgress.empty, side: FileSide.device, epoch: repo().epoch, reason: 'later run', at: DateTime.now()),
        'id': 'size-filler',
        'filler': 'x' * (CaseConflicts.maxBytes + 1024),
      });
      final rt = ct == null ? null : await chooseNow(ct, keepPlaying: false, pid: t1);
      await check('18. kept data over 512 KB: refused, nothing removed', rt == ChoiceResult.cannotKeep && keptT < CaseConflicts.perCaseLimit &&
          repo().conflicts.any((r) => r['id'] == 'size-filler'), 'TESS choice → ${rt?.name} (a choice was offered: ${ct != null}, kept for the case: $keptT, under the count limit: ${keptT < CaseConflicts.perCaseLimit})');
      await signal('TIE-A-checked');

      // ---- 14. A New Adventure on A: the kept files stay (archived) ----
      await playAs(p.id);
      final recordsBefore = {for (final r in repo().conflicts) r['id']};
      await game().resetAll();
      await t.pump(const Duration(milliseconds: 300));
      game().registerDetective('ANNA');
      game().startInvestigation();
      solve('m01');
      await sentAll('A after the New Adventure');
      final m14 = await meta(p.id);
      final recordsAfter = repo().conflicts;
      await check('14. New Adventure on A: epoch 1, every kept file still there (archived), nothing offered',
          m14?['epoch'] == 1 && {for (final r in recordsAfter) r['id']}.containsAll(recordsBefore) &&
              recordsAfter.where((r) => r['kind'] == 'case' || r['kind'] == 'restoreHeld').every((r) => r['status'] == 'archived' || r['status'] == 'resolved') &&
              choice() == null,
          'meta epoch=${m14?['epoch']}, records ${recordsBefore.length}→${recordsAfter.length}, statuses=${statuses().toSet()}');
      await signal('A-reset', p.id);
      await waitFor('B-reset-checked');

      // 17. The guest.
      await signOut();
      await guestCheck('17. A: the guest kept, not uploaded');
      h.sync!.dispose();
      await signal('A-end');
    } else if (role == 'B') {
      // 1. B: the same account and detective (restored from the account).
      final pid = (await waitFor('A-synced'))! as String;
      await signIn('a');
      final d = (await h.restore!.accountDetectives()).detectives.singleWhere((x) => x.id == pid);
      expect(await h.restore!.restore(d), isNull);
      await playAs(pid);
      await sentAll('B restored');
      await signal('B-restored');

      // Round 1 (A chooses).
      await roundB(1, pid);
      final c1 = choice()!;
      await check('2. B: the same two files (B\'s plays, A\'s from the account)', c1.other.side == FileSide.account &&
          c1.playing.run.completedMissionIds.length == 2 && c1.other.run.completedMissionIds.length == 1,
          'B plays ${c1.playing.run.completedMissionIds}, other = ${c1.other.run.completedMissionIds} (${c1.other.side.name})');
      final coins1 = balance();
      final chosen1 = (await waitFor('R1-chosen'))! as Map;
      await resume();
      await sentAll('B after R1');
      await check('4. R1: A\'s choice is on B and matches the server', caseNow().runId == chosen1['runId'] && choice() == null &&
          (await caseDiff(pid)).isEmpty && balance() == coins1 && xp() == XpBreakdown.totalFor(ep01, c1.other.run),
          'B run = chosen=${caseNow().runId == chosen1['runId']}, B vs server=${await caseDiff(pid)}, coins $coins1→${balance()}, XP ${xp()}');
      await check('6. R1: B keeps its own run (not chosen) as a kept file',
          repo().conflicts.any((r) => CaseConflicts.runOf(r)?.runId == c1.playing.run.runId),
          'B keeps runs: ${runsKept().length}');
      await signal('R1-B-checked');

      // Round 2: DECIDE LATER, then IN YOUR ACCOUNT on screen.
      await roundB(2, pid);
      final c2 = choice()!;
      final saves2 = choiceState(pid);
      final v2 = await serverState(pid);
      await go(Routes.caseFiles('ep01'));
      await until(() => find.text('Two Case Files').evaluate().isNotEmpty, 'the two files on B');
      final later = find.widgetWithText(GameButton, 'DECIDE LATER');
      await t.ensureVisible(later);
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(later);
      await until(() => find.text('CASE FILES').evaluate().isNotEmpty, 'back from DECIDE LATER');
      await idle();
      final same2 = choiceState(pid) == saves2;
      final server2 = await serverState(pid) == v2;
      await check('7. DECIDE LATER: nothing changes on B or the server', same2 && server2 && choice() != null,
          'B case/files/coins unchanged=$same2, server case unchanged=$server2, still offered=${choice() != null}');
      final coins2 = balance();
      await chooseOnScreen('file-other'); // IN YOUR ACCOUNT: A's run
      await sentAll('R2: B\'s choice sent');
      final s2 = await serverCase(pid);
      await check('5. R2: B chooses IN YOUR ACCOUNT: A\'s run plays on the server and B; B\'s run kept', choice() == null &&
          s2['runId'] == CaseConflicts.choiceRunId(c2.other.run, c2.other.run.runSeq + 1) &&
          caseNow().completedMissionIds.length == 1 && balance() == coins2 &&
          repo().conflicts.any((r) => CaseConflicts.runOf(r)?.runId == c2.playing.run.runId && r['status'] == 'archived') &&
          !statuses().contains('waiting'),
          'server run = the choice id, B solved=${caseNow().completedMissionIds}, coins $coins2→${balance()}, statuses=${statuses().toSet()}');
      await signal('R2-B-chosen');
      await waitFor('R2-A-checked');

      // Round 3: B chooses with no network.
      await roundB(3, pid);
      final c3 = choice()!;
      final s3 = await serverCase(pid);
      final s3state = await serverState(pid);
      await networkOff(45);
      await t.pump(const Duration(seconds: 4));
      final r3 = await chooseNow(c3, keepPlaying: true, pid: pid);
      await t.pump(const Duration(seconds: 2));
      final waiting = statuses().contains('waiting');
      final pending = repo().outbox.events.isNotEmpty;
      expect(await waitNetwork(), isTrue);
      final s3off = await serverState(pid);
      await resume();
      await sentAll('R3: B\'s offline choice sent');
      final s3b = await serverCase(pid);
      await check('12. R3: chosen offline: waiting (not resolved) until sent; sent on reconnect, then resolved',
          r3 == ChoiceResult.applied && waiting && pending && s3off == s3state &&
              s3b['runSeq'] == c3.playing.run.runSeq + 1 && !statuses().contains('waiting') && (await caseDiff(pid)).isEmpty,
          'B → ${r3.name}, waiting=$waiting, queued=$pending, server untouched while offline=${s3off == s3state}, '
          'then runSeq ${s3['runSeq']}→${s3b['runSeq']}, statuses=${statuses().toSet()}');
      await signal('R3-B-chosen');
      await waitFor('R3-A-checked');

      // Round 4: A chooses first; B chooses from its older view.
      await roundB(4, pid);
      final stale = choice()!;
      await signal('R4-B-has-view');
      final a4 = (await waitFor('R4-A-chosen'))! as Map;
      final r4 = await chooseNow(stale, keepPlaying: false, pid: pid);
      await sentAll('R4: B after its stale choice');
      final s4 = await serverCase(pid);
      await check('13. R4: the server changed just before B\'s choice: nothing applied, B follows A\'s choice',
          r4 == ChoiceResult.changed && s4['runId'] == a4['runId'] && s4['runSeq'] == a4['runSeq'] && caseNow().runId == a4['runId'],
          'B → ${r4.name}, server run = A\'s choice=${s4['runId'] == a4['runId']}, runSeq ${a4['before']}→${s4['runSeq']}');
      await signal('R4-B-checked');

      // Round 5: the same file (B's run, playing on both) chosen on both, offline.
      await roundB(5, pid);
      final c5 = choice()!;
      final kept5 = keptCount();
      await signal('R5-ready');
      await waitFor('R5-A-offline');
      await networkOff(45);
      await t.pump(const Duration(seconds: 4));
      final r5 = await chooseNow(c5, keepPlaying: true, pid: pid); // B's own run
      final own5 = (caseNow().runId, caseNow().runSeq);
      final expected5 = (CaseConflicts.choiceRunId(c5.playing.run, c5.other.run.runSeq + 1), c5.other.run.runSeq + 1);
      expect(await waitNetwork(), isTrue);
      await signal('R5-B-back');
      await waitFor('R5-A-sent');
      await resume();
      await sentAll('R5: B sends');
      await signal('R5-B-sent');
      final shared = await waitFor('R5-A-checked');
      await resume();
      await check('9. R5: B made the same choice: the same run as A, nothing asked again', r5 == ChoiceResult.applied &&
          own5 == expected5 && own5.$1 == shared && caseNow().runId == shared && choice() == null && (await caseDiff(pid)).isEmpty,
          'B → ${r5.name}, B\'s own choice = the expected id=${own5 == expected5}, = A\'s=${own5.$1 == shared}, B run = A\'s=${caseNow().runId == shared}, '
          'B vs server=${await caseDiff(pid)}, kept $kept5→${keptCount()}');

      // Round 6: different files, both offline.
      await roundB(6, pid);
      final c6 = choice()!;
      await signal('R6-ready');
      await waitFor('R6-A-offline');
      await networkOff(90); // back after A has sent its choice
      await t.pump(const Duration(seconds: 4));
      final r6 = await chooseNow(c6, keepPlaying: true, pid: pid); // B's run (2 missions)
      expect(await waitNetwork(), isTrue);
      await signal('R6-B-back');
      await waitFor('R6-A-sent');
      await resume();
      await sentAll('R6: B sends');
      await signal('R6-B-sent');
      await resume();
      await signal('R6-B-resumed');
      final a6 = (await waitFor('R6-A-checked'))! as Map;
      await resume();
      final s6 = await serverCase(pid);
      final again6 = choice();
      await check('10. R6: B ends on the same run as A; the other file offered again; the server settled',
          r6 == ChoiceResult.applied && (await caseDiff(pid)).isEmpty && s6['runSeq'] == a6['runSeq'] &&
              s6['runId'] == a6['runId'] && again6 != null,
          'B → ${r6.name}, B vs server=${await caseDiff(pid)}, server runSeq=${s6['runSeq']} (A saw ${a6['runSeq']}), same run as A saw=${s6['runId'] == a6['runId']}, '
          'offered again=${again6 != null}; c6 other ${c6.other.run.runId?.substring(0, 6)}/${c6.other.run.runSeq}; ${caseRecordsNow()}');

      // 16. Signed out, then another account, while choosing: stopped.
      final save16 = choiceState(pid);
      hook.beforeList = (path) async {
        if (!path.endsWith('/cases')) return;
        hook.beforeList = null;
        await h.account.signOut();
        await t.pump(const Duration(milliseconds: 500));
      };
      final r16a = await chooseNow(again6!, keepPlaying: false, pid: pid);
      final same16a = choiceState(pid) == save16;
      await until(() => profile().kind == ProfileKind.guest, 'the guest after sign-out');
      await signIn('a');
      await playAs(pid);
      await idle();
      final c16 = choice()!;
      final save16b = choiceState(pid);
      hook.beforeList = (path) async {
        if (!path.endsWith('/cases')) return;
        hook.beforeList = null;
        await h.account.signOut();
        final b = accounts['b']!;
        await h.account.signIn(email: b['email']! as String, password: b['password']! as String);
        await t.pump(const Duration(milliseconds: 500));
      };
      final r16b = await chooseNow(c16, keepPlaying: false, pid: pid);
      final same16b = choiceState(pid) == save16b;
      await until(() => h.account.value.uid == accounts['b']!['uid'], 'account b');
      final bSees = await serverDoc('users/${accounts['b']!['uid']}/profiles/$pid');
      await check('16. sign-out / another account while choosing: stopped, nothing changed, nothing of a under b',
          r16a == ChoiceResult.stopped && same16a && r16b == ChoiceResult.stopped && same16b && bSees == null,
          'sign-out → ${r16a.name} (unchanged=$same16a), switch to b → ${r16b.name} (unchanged=$same16b), a\'s detective under b=${bSees != null}');
      await signOut();
      await signIn('a');
      await playAs(pid);
      await idle();
      await signal('R6-B-checked');

      // 11. The tie: B sends TESS second and TOBY first.
      final ties = (await waitFor('TIE-made'))! as Map;
      for (final id in [ties['t1'] as String, ties['t2'] as String]) {
        final dd = (await h.restore!.accountDetectives()).detectives.singleWhere((x) => x.id == id);
        expect(await h.restore!.restore(dd), isNull);
      }
      GameProgress tieRun(String name) => GameProgress(
            detectiveName: name,
            introSeen: true,
            completedMissionIds: const ['m01'],
            attempts: const {'m01': 1},
            xpRules: const {'m01': XpBreakdown.currentRule},
            playMillis: 90000,
            runId: 'tie-from-b',
            runSeq: 1,
            rev: 3,
          );
      Future<void> sendRun(String id, GameProgress run) async {
        await playAs(id);
        repo().save(run, 'ep01');
        refreshFromSaves(c(), 'case:ep01');
        await sentAll('B tie run sent');
      }

      await playAs(ties['t2'] as String);
      await sendRun(ties['t2'] as String, tieRun('TOBY'));
      await signal('TIE2-B-sent');
      await waitFor('TIE1-A-sent');
      await sendRun(ties['t1'] as String, tieRun('TESS'));
      await waitFor('TIE2-A-sent');
      await playAs(ties['t2'] as String);
      await resume();
      final b2 = repo().load('ep01').runId;
      await playAs(ties['t1'] as String);
      await resume();
      final b1 = repo().load('ep01').runId;
      await check('11. the tie on B: the same winner as on the server', b1 == 'tie-from-b' && b2 == 'tie-from-b',
          'B plays TESS=$b1, TOBY=$b2');
      await signal('TIE-B-done');
      await waitFor('TIE-A-checked');

      // 14. A's New Adventure reaches B: B's kept files stay, archived.
      await playAs(pid);
      final records = {for (final r in repo().conflicts) r['id']};
      await waitFor('A-reset');
      await resume();
      await check('14. B follows the New Adventure: epoch 1, its kept files still there, nothing offered',
          repo().epoch == 1 && {for (final r in repo().conflicts) r['id']}.containsAll(records) && choice() == null,
          'B epoch=${repo().epoch}, records ${records.length}→${repo().conflicts.length}, statuses=${statuses().toSet()}');

      // 19. B restarts: the same as the server, nothing offered.
      final recordsNow = repo().conflicts.length;
      h.sync!.dispose();
      h.account.dispose();
      await app.main();
      h = app.debugApp!;
      await until(() => h.cloud.value == CloudStatus.ready, 'cloud ready after restart');
      h.sync!.debugWrapStore((real) => hook..inner = real);
      await until(() => h.account.value.uid == uidA && h.account.value.consentConfirmed, 'session back after restart');
      await playAs(pid);
      await sentAll('B after restart');
      await check('19. B restarted: matches the server, kept files there, nothing offered', (await caseDiff(pid)).isEmpty &&
          repo().conflicts.length == recordsNow && choice() == null && repo().epoch == 1,
          'B vs server=${await caseDiff(pid)}, records=${repo().conflicts.length}, epoch=${repo().epoch}');
      await signal('B-reset-checked');

      // 17. The guest.
      await signOut();
      await guestCheck('17. B: the guest kept, not uploaded');
      h.sync!.dispose();
      await waitFor('A-end');
    } else {
      // C (iOS, after A and B): restores ANNA (epoch 1), then meets a case
      // file of "another device" (this device's own sender on a scratch copy
      // of the profile) and keeps its own on screen.
      final pid = (await waitFor('A-reset'))! as String;
      await signIn('a');
      await go(Routes.profiles);
      await until(() => find.byKey(ValueKey('cloud-profile-$pid')).evaluate().isNotEmpty, 'listed on iOS', timeout: const Duration(seconds: 60));
      final f = find.byKey(ValueKey('cloud-profile-$pid'));
      await t.ensureVisible(f);
      await t.pump();
      await t.tap(f);
      await until(() => profile().id == pid, 'restored on iOS', timeout: const Duration(seconds: 60));
      await sentAll('C restored');
      await check('20. iOS: restored (epoch 1), the same as the server', repo().epoch == 1 && (await caseDiff(pid)).isEmpty &&
          balance() == (await summary(pid))?['balance'], 'epoch=${repo().epoch}, C vs server=${await caseDiff(pid)}, coins=${balance()}');

      h.sync!.onLifecycle(AppLifecycleState.paused);
      game().playAgain();
      game().startInvestigation();
      solve('m01');
      final runC = caseNow().runId;
      final seq = caseNow().runSeq;
      // "Another device": a scratch copy of the profile on this device, at
      // the same epoch, sends its own run under the same run number.
      final other = SharedPrefsProgressRepository(prefs, profileId: 'f' * 32);
      await other.clear(); // epoch 1, like the server
      other.save(GameProgress(
        detectiveName: 'ANNA',
        introSeen: true,
        completedMissionIds: const ['m01', 'm02'],
        attempts: const {'m01': 1, 'm02': 1},
        xpRules: const {'m01': XpBreakdown.currentRule, 'm02': XpBreakdown.currentRule},
        playMillis: 120000,
        runId: 'ios-other-device',
        runSeq: seq,
        rev: 4,
      ), 'ep01');
      await SyncSender(
        store: h.sync!.store,
        repo: other,
        codec: codec,
        paths: SyncPaths(uidA, pid),
        episodeIds: episodeIds,
        isStillValid: () => h.account.value.uid == uidA,
      ).run();
      h.sync!.onLifecycle(AppLifecycleState.resumed);
      await t.pump(const Duration(milliseconds: 500));
      await idle();
      await sentAll('C back');
      await until(() => choice() != null, 'two files on iOS', timeout: const Duration(seconds: 90));
      await go(Routes.caseFiles('ep01'));
      await until(() => find.text('Two Case Files').evaluate().isNotEmpty, 'the two files on iOS');
      final shown = find.text('ON THIS DEVICE').evaluate().isNotEmpty && find.text('IN YOUR ACCOUNT').evaluate().isNotEmpty &&
          find.text('FURTHER ALONG').evaluate().isNotEmpty;
      final cC = choice()!;
      await chooseOnScreen('file-other'); // ON THIS DEVICE: C's own run
      await sentAll('C\'s choice sent');
      final sC = await serverCase(pid);
      await check('20. iOS: the case files screen; ON THIS DEVICE chosen and sent', shown && cC.other.run.runId == runC &&
          sC['runId'] == CaseConflicts.choiceRunId(cC.other.run, seq + 1) && sC['epoch'] == 1 && (await caseDiff(pid)).isEmpty &&
          repo().conflicts.any((r) => CaseConflicts.runOf(r)?.runId == 'ios-other-device'),
          'labels shown=$shown, server run = C\'s choice, runSeq=${sC['runSeq']}, epoch=${sC['epoch']}, the other file kept');
      await signOut();
      await guestCheck('17. iOS: the guest kept, not uploaded');
      h.sync!.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 60)));
}
