// Phase 4.5: two case files of a case and the detective's choice, end to end,
// in the real app on a device, against the LOCAL emulators only (Auth +
// Firestore):
//   cd firebase && DEVICE=<id> EMULATOR_HOST=<host> npm run test:case-files-app
// (<host>: localhost on the iOS simulator, 10.0.2.2 on an Android emulator.)
// Built with LM_CLOUD_EMULATOR: nothing reaches the DEV or PROD project.
// "Another device" is the emulator's admin writing Anna's case on the server
// under the same run number, as a second device's send would.
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
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/data/repositories/progress_repository.dart';
import 'package:london_mystery/data/sync/case_conflicts.dart';
import 'package:london_mystery/data/sync/cloud/cloud_store.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/main.dart' as app;
import 'package:london_mystery/widgets/game_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/support/cloud_stores.dart' show decodeFields, encodeFields;

const host = CloudEmulator.buildHost;
const password = 'detective42';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String projectId;
  final season = MockEpisodeRepository.bundled();
  final ep01 = season.first;
  final m01 = ep01.missions[0];
  final m02 = ep01.missions[1];
  final m03 = ep01.missions[2];

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

  testWidgets('two case files: shown, chosen, sent; offline choice waits and goes; kept after a restart', (t) async {
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
    void onEmulatorOnly() =>
        expect(FirebaseFirestore.instance.settings.host, startsWith(host), reason: 'Firestore on the emulator, never a project');

    Future<void> sentAll(String what) async {
      await t.pump(const Duration(milliseconds: 2500));
      await until(() => repo().outbox.pending.isEmpty && h.sync!.running == null && !h.sync!.planned, what,
          timeout: const Duration(seconds: 60));
    }

    Future<void> go(String location) async {
      c().read(routerProvider).go(location);
      await t.pump(const Duration(milliseconds: 900));
    }

    Future<void> resume() async {
      h.sync!.onLifecycle(AppLifecycleState.resumed);
      await t.pump(const Duration(milliseconds: 300));
      await until(() => h.sync!.running == null && !h.sync!.planned, 'the resume run');
    }

    Map<String, Object?> guestSaves() {
      final prefix = AppConstants.profilePrefix(ProfileStore(prefs).guest!.id);
      return {for (final k in prefs.getKeys()) if (k.startsWith(prefix)) k: prefs.get(k)};
    }

    /// Another device of Anna's sends its own run of Case 01 under run
    /// number [runSeq]: [solved] missions.
    Future<void> anotherDevicePlays(String uid, String pid, {required String runId, required int runSeq, required List<Mission> solved}) async {
      final path = SyncPaths(uid, pid).caseDoc('ep01');
      final doc = (await server(path))!;
      final progress = GameProgress(
        detectiveName: 'ANNA',
        introSeen: true,
        completedMissionIds: [for (final m in solved) m.id],
        attempts: {for (final m in solved) m.id: 1},
        xpRules: {for (final m in solved) m.id: XpBreakdown.currentRule},
        startedAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        playMillis: 600000,
        runId: runId,
        runSeq: runSeq,
        rev: 7,
      );
      await adminPut(path, {
        ...doc,
        'runId': runId,
        'runSeq': runSeq,
        'cloudVersion': (doc['cloudVersion']! as int) + 1,
        'progress': progress.toJson()..removeWhere((_, v) => v == null),
      });
    }

    Future<void> keep(String card) async {
      final button = find.descendant(of: find.byKey(ValueKey(card)), matching: find.widgetWithText(GameButton, 'KEEP PLAYING THIS ONE'));
      await t.ensureVisible(button);
      await t.pump(const Duration(milliseconds: 200));
      await t.tap(button);
      await until(() => find.text("We'll keep the other file safe.").evaluate().isNotEmpty, 'the promise');
      await t.tap(find.text('YES, KEEP PLAYING'));
      await until(() => find.text('CASE FILES').evaluate().isNotEmpty, 'back on the case files', timeout: const Duration(seconds: 60));
      await t.pump(const Duration(seconds: 3)); // the note fades
    }

    await until(() => h.cloud.value == CloudStatus.ready, 'cloud ready');
    onEmulatorOnly();
    if (h.account.value.uid != null) await h.account.signOut();

    // 1. The guest plays; Anna (consent confirmed) plays Case 01's first
    //    mission as ANNA; everything is sent.
    c().read(gameControllerProvider.notifier).registerDetective('GUEST');
    expect((await h.account.signUp(email: 'anna@example.com', password: password)).ok, isTrue);
    await until(() => h.account.value.uid != null, 'signed up');
    final anna = h.account.value.uid!;
    await adminPut('consents/$anna', {'status': 'confirmed', 'schema': 1});
    await h.account.refreshConsent();
    final p = await c().read(profileStoreProvider).addProfile(kind: ProfileKind.account, ownerUid: anna, detectiveName: 'ANNA');
    await h.host.currentState!.switchTo(p.id);
    await t.pump(const Duration(milliseconds: 300));
    final game = c().read(gameControllerProvider.notifier);
    expect(game.registerDetective('ANNA'), isNull);
    game.startInvestigation();
    expect(game.submitAnswer(m01, m01.answer).result, SubmitResult.correct);
    await sentAll('ANNA sent');
    final guestBefore = guestSaves();
    final mine = repo().load('ep01');
    final summary = SyncPaths(anna, p.id).walletSummary;
    expect((await server(summary))?['balance'], 50);

    // 2. Another device sent its own run of Case 01 (m01, m02) under the same
    //    run number. Back in the app: both files on the device, the one
    //    further along playing, the device's own kept.
    await anotherDevicePlays(anna, p.id, runId: 'other-device-run', runSeq: mine.runSeq, solved: [m01, m02]);
    await resume();
    await until(() => CaseConflicts.choiceFor(repo(), 'ep01') != null, 'two case files');
    var choice = CaseConflicts.choiceFor(repo(), 'ep01')!;
    expect(choice.playing.run.runId, 'other-device-run');
    expect((choice.other.run.runId, choice.other.side), (mine.runId, FileSide.device));
    expect(c().read(gameControllerProvider).completedMissionIds, [m01.id, m02.id], reason: 'shown at once');
    expect(c().read(walletProvider).balance, 50, reason: 'coins never follow a run');

    // 3. Where Anna learns of it, then the files: she keeps her own.
    await go(Routes.profiles);
    await until(() => find.text('A CASE HAS TWO FILES').evaluate().isNotEmpty, 'the detectives list says so');
    await go(Routes.season);
    await until(() => find.text('2 FILES').evaluate().isNotEmpty, 'the board says so');
    await go(Routes.caseFiles('ep01'));
    await until(() => find.text('Two Case Files').evaluate().isNotEmpty, 'the two files');
    expect(find.text('ON THIS DEVICE'), findsOneWidget);
    expect(find.text('IN YOUR ACCOUNT'), findsOneWidget);
    await keep('file-other');
    await sentAll('the choice sent');
    var cloud = (await server(SyncPaths(anna, p.id).caseDoc('ep01')))!;
    final firstChoice = CaseConflicts.choiceRunId(mine, mine.runSeq + 1);
    expect((cloud['runSeq'], cloud['runId']), (mine.runSeq + 1, firstChoice));
    expect((cloud['progress']! as Map)['completedMissionIds'], [m01.id]);
    expect(c().read(gameControllerProvider).runId, firstChoice);
    expect(XpBreakdown.totalFor(ep01, c().read(gameControllerProvider)), 30);
    expect(repo().conflicts.where((r) => r['status'] == 'waiting'), isEmpty, reason: 'resolved once the server has it');
    expect(repo().conflicts.any((r) => CaseConflicts.runOf(r)?.runId == 'other-device-run'), isTrue, reason: 'the other file kept');
    expect((await server(summary))?['balance'], 50);
    expect(c().read(walletProvider).balance, 50);

    // 4. Again from another device, further along, under the new number;
    //    this time Anna chooses with no connection: it waits, then goes.
    await anotherDevicePlays(anna, p.id, runId: 'third-run', runSeq: mine.runSeq + 1, solved: [m01, m02, m03]);
    await resume();
    await until(() => CaseConflicts.choiceFor(repo(), 'ep01') != null, 'two case files again');
    choice = CaseConflicts.choiceFor(repo(), 'ep01')!;
    expect(choice.playing.run.runId, 'third-run');
    final line = _Line();
    h.sync!.debugWrapStore((real) => line..inner = real);
    line.down = true;
    await go(Routes.caseFiles('ep01'));
    await until(() => find.text('Two Case Files').evaluate().isNotEmpty, 'the two files again');
    await keep('file-other');
    await t.pump(const Duration(seconds: 2));
    expect(repo().conflicts.where((r) => r['status'] == 'waiting'), isNotEmpty, reason: 'waiting to be sent');
    expect((await server(SyncPaths(anna, p.id).caseDoc('ep01')))!['runId'], 'third-run', reason: 'not sent yet');
    line.down = false;
    await resume();
    await sentAll('the offline choice sent');
    cloud = (await server(SyncPaths(anna, p.id).caseDoc('ep01')))!;
    expect(cloud['runSeq'], mine.runSeq + 2);
    expect((cloud['progress']! as Map)['completedMissionIds'], [m01.id]);
    expect(repo().conflicts.where((r) => r['status'] == 'waiting'), isEmpty);
    expect(c().read(walletProvider).balance, 50);

    // 5. A restart: nothing to choose, the case as chosen, nothing written.
    final caseNow = jsonEncode(repo().load('ep01').toJson());
    final version = cloud['cloudVersion'];
    h.sync!.dispose();
    h.account.dispose();
    await app.main();
    h = app.debugApp!;
    await until(() => h.cloud.value == CloudStatus.ready && h.account.value.uid == anna && h.account.value.consentConfirmed,
        'Anna back after restart');
    // At a start the guest opens; Anna chooses her detective again.
    await h.host.currentState!.switchTo(p.id);
    await until(() => h.host.currentState!.session.profileId == p.id, 'ANNA playing');
    await sentAll('after restart');
    expect(CaseConflicts.choiceFor(repo(), 'ep01'), isNull);
    expect(jsonEncode(repo().load('ep01').toJson()), caseNow);
    expect((await server(SyncPaths(anna, p.id).caseDoc('ep01')))!['cloudVersion'], version);
    expect(guestSaves(), guestBefore, reason: 'the guest untouched');
    expect(await server('users/$anna/profiles/${ProfileStore(prefs).guest!.id}'), isNull, reason: 'the guest never uploaded');

    onEmulatorOnly();
    await h.account.signOut();
    await clearEmulators();
    debugPrint('E2E case files: every step passed');
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
