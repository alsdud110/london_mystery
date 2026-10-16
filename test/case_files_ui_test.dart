import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/cloud/cloud_bootstrap.dart';
import 'package:london_mystery/core/cloud/cloud_environment.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/models/wallet.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/data/repositories/progress_repository.dart';
import 'package:london_mystery/data/sync/case_conflicts.dart';
import 'package:london_mystery/data/sync/merge.dart';
import 'package:london_mystery/data/sync/sync_applier.dart';
import 'package:london_mystery/features/account/account_controller.dart';
import 'package:london_mystery/features/account/auth_service.dart';
import 'package:london_mystery/features/account/fake_auth_service.dart';
import 'package:london_mystery/features/account/firestore_consent_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/profile/profile_session.dart';
import 'package:london_mystery/widgets/game_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

const _uid = 'anna-uid';
const _pid = 'abcdef0123456789abcdef0123456789';

/// Phase 4.5: the two case files of a case on screen — where the detective
/// learns of them, the comparison, the choice and DECIDE LATER — on a small
/// and a common phone.
void main() {
  final season = MockEpisodeRepository.bundled();
  final ep01 = season.first;
  final m01 = ep01.missions[0];
  final m02 = ep01.missions[1];
  final episodeIds = [for (final e in season) e.id];

  GameProgress run(String id, List<Mission> solved) => GameProgress(
        detectiveName: 'ANNA',
        introSeen: true,
        completedMissionIds: [for (final m in solved) m.id],
        attempts: {for (final m in solved) m.id: 1},
        xpRules: {for (final m in solved) m.id: 4},
        startedAt: DateTime.now().subtract(const Duration(days: 1)),
        missionStartedAt: {for (final m in solved) m.id: DateTime.now()},
        runId: id,
        rev: 1,
      );

  /// Anna's detective on this device, signed in, with Case 01 played here
  /// (m01, m02) and on another device (m01) under the same run number.
  Future<({GlobalKey<ProfileSessionHostState> host, SharedPreferences prefs})> open(
    WidgetTester t, {
    Size size = const Size(390, 844),
  }) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final overrides = await testOverrides();
    final prefs = await SharedPreferences.getInstance();
    ProfileStore(prefs).ensureActiveSync();
    await ProfileStore(prefs).addRestored(id: _pid, ownerUid: _uid, detectiveName: 'ANNA', createdAt: DateTime.utc(2026, 10, 1));
    final repo = SharedPrefsProgressRepository(prefs, profileId: _pid);
    repo.saveSeason(const SeasonProgress(activeEpisodeId: 'ep01'));
    repo.save(run('dev-run', [m01, m02]), 'ep01');
    SyncApplier(repo, episodeIds: episodeIds).applyCase('ep01', CaseSnapshot(epoch: 0, progress: run('acc-run', [m01])));
    expect(CaseConflicts.choiceFor(repo, 'ep01'), isNotNull);

    final cloud = CloudBootstrap(
      decision: const CloudDecision.start(CloudEnvironment.dev),
      initialize: () async => (projectId: CloudEnvironment.dev.projectId, appId: CloudEnvironment.dev.androidAppId),
    );
    final account = AccountController(
      cloud: cloud,
      createAuth: () => FakeAuthService(restored: const UserSession(uid: _uid, emailVerified: true)),
      consents: FirestoreConsentRepository.withReader((uid) async => {'status': 'confirmed', 'schema': 1}),
    );
    addTearDown(account.dispose);
    cloud.start();
    await t.pump();
    await t.pump();
    final host = GlobalKey<ProfileSessionHostState>();
    await t.pumpWidget(ProfileSessionHost(
      key: host,
      session: ProfileStore(prefs).ensureActiveSync(),
      signedInUid: () => account.value.uid,
      overrides: [
        ...overrides,
        cloudBootstrapProvider.overrideWithValue(cloud),
        accountControllerProvider.overrideWithValue(account),
      ],
      child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
    ));
    await wait(t, const Duration(milliseconds: 400));
    await host.currentState!.switchTo(_pid);
    await wait(t, const Duration(milliseconds: 600));
    expect(host.currentState!.session.profileId, _pid);
    return (host: host, prefs: prefs);
  }

  ProviderContainer c(GlobalKey<ProfileSessionHostState> host) => host.currentState!.container;

  Future<void> go(WidgetTester t, GlobalKey<ProfileSessionHostState> host, String location) async {
    c(host).read(routerProvider).go(location);
    await wait(t, const Duration(milliseconds: 700));
  }

  Map<String, Object?> saves(SharedPreferences prefs) => {for (final k in prefs.getKeys()) k: prefs.get(k)};

  void noTechnicalWords() {
    for (final word in ['conflict', 'error', 'delete', 'overwrite', 'sync']) {
      expect(
        find.byWidgetPredicate((w) => w is Text && (w.data ?? w.textSpan?.toPlainText() ?? '').toLowerCase().contains(word)),
        findsNothing,
        reason: 'no "$word" for the detective',
      );
    }
  }

  for (final size in const [Size(320, 568), Size(390, 844)]) {
    final name = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('$name: the two files side by side; the account\'s chosen after the promise; it plays on', (t) async {
      final app = await open(t, size: size);
      await go(t, app.host, Routes.caseFiles('ep01'));
      expect(find.text('Two Case Files'), findsOneWidget);
      expect(find.text('ON THIS DEVICE'), findsOneWidget);
      expect(find.text('IN YOUR ACCOUNT'), findsOneWidget);
      expect(find.text('PLAYING NOW'), findsOneWidget);
      expect(find.text('FURTHER ALONG'), findsOneWidget);
      expect(find.text('2 of ${ep01.allMissions.length} missions'), findsOneWidget);
      expect(find.text('1 of ${ep01.allMissions.length} missions'), findsOneWidget);
      expect(find.textContaining('60 XP'), findsOneWidget);
      expect(find.textContaining('30 XP'), findsOneWidget);
      expect(find.textContaining('Last played today'), findsNWidgets(2));
      expect(find.text('Your coins stay the same.'), findsOneWidget);
      noTechnicalWords();
      // Every button can be reached and is not cut off.
      for (final b in [
        find.byKey(const ValueKey('file-playing')),
        find.byKey(const ValueKey('file-other')),
        find.widgetWithText(GameButton, 'DECIDE LATER'),
      ]) {
        await t.ensureVisible(b);
        await t.pump();
        expect(t.getRect(b).right, lessThanOrEqualTo(size.width));
      }
      await t.ensureVisible(find.byKey(const ValueKey('file-playing')));
      await t.pump();
      await capture(t, 'case_files_$name');

      final other = find.descendant(of: find.byKey(const ValueKey('file-other')), matching: find.widgetWithText(GameButton, 'KEEP PLAYING THIS ONE'));
      await t.ensureVisible(other);
      await t.pump();
      await t.tap(other);
      await wait(t, const Duration(milliseconds: 500));
      expect(find.text("We'll keep the other file safe."), findsOneWidget);
      await capture(t, 'case_files_confirm_$name');
      await t.tap(find.text('YES, KEEP PLAYING'));
      await wait(t, const Duration(milliseconds: 900));
      final now = c(app.host).read(gameControllerProvider);
      expect(now.completedMissionIds, [m01.id], reason: 'the chosen file plays on');
      expect(now.runSeq, 1);
      expect(find.text('CASE FILES'), findsOneWidget, reason: 'back on the case files');
      final repo = SharedPrefsProgressRepository(app.prefs, profileId: _pid);
      expect(CaseConflicts.choiceFor(repo, 'ep01'), isNull);
      expect(repo.conflicts.any((r) => CaseConflicts.runOf(r)?.runId == 'dev-run'), isTrue, reason: 'the other file kept');
      await wait(t, const Duration(seconds: 4)); // the note fades
    });
  }

  testWidgets('a coin counted differently elsewhere: said on the detective, the balance unchanged', (t) async {
    final app = await open(t);
    final repo = SharedPrefsProgressRepository(app.prefs, profileId: _pid);
    final at = DateTime.utc(2026, 10, 14);
    repo.saveWallet(Wallet.empty.adding(CoinEntry(key: Wallet.tipKey(m01.id, 2), amount: -20, source: CoinSource.tip, at: at)));
    SyncApplier(repo, episodeIds: episodeIds)
        .applyWallet(0, Wallet.empty.adding(CoinEntry(key: Wallet.tipKey(m01.id, 2), amount: 0, source: CoinSource.tip, at: at)));
    final balance = repo.loadWallet()!.balance;
    await go(t, app.host, Routes.profiles);
    expect(find.text('COINS CHECKED · NOTHING LOST'), findsOneWidget);
    noTechnicalWords();
    expect(SharedPrefsProgressRepository(app.prefs, profileId: _pid).loadWallet()!.balance, balance);
  });

  testWidgets('DECIDE LATER and "Not yet": nothing changes', (t) async {
    final app = await open(t, size: const Size(320, 568));
    await go(t, app.host, Routes.caseFiles('ep01'));
    final before = saves(app.prefs);
    final keep = find.descendant(of: find.byKey(const ValueKey('file-other')), matching: find.widgetWithText(GameButton, 'KEEP PLAYING THIS ONE'));
    await t.ensureVisible(keep);
    await t.pump();
    await t.tap(keep);
    await wait(t, const Duration(milliseconds: 500));
    await t.tap(find.text('Not yet'));
    await wait(t, const Duration(milliseconds: 500));
    expect(find.text('Two Case Files'), findsOneWidget);
    final later = find.widgetWithText(GameButton, 'DECIDE LATER');
    await t.ensureVisible(later);
    await t.pump();
    await t.tap(later);
    await wait(t, const Duration(milliseconds: 700));
    expect(find.text('CASE FILES'), findsOneWidget);
    expect(saves(app.prefs), before);
  });

  testWidgets('where the detective learns of it: the detectives list, the board, and once on opening the case', (t) async {
    final app = await open(t);
    await go(t, app.host, Routes.profiles);
    expect(find.text('A CASE HAS TWO FILES'), findsOneWidget, reason: 'on Anna only, never on the guest');
    await capture(t, 'case_files_detectives');

    await go(t, app.host, Routes.season);
    await wait(t, const Duration(milliseconds: 1600));
    expect(find.text('2 FILES'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Case 01, .*two case files')), findsOneWidget);
    await capture(t, 'case_files_board');

    await go(t, app.host, Routes.caseFile('ep01'));
    expect(find.byKey(const ValueKey('two-files-ep01')), findsOneWidget);
    final begin = find.widgetWithText(GameButton, 'CONTINUE INVESTIGATION');
    await t.tap(begin);
    await wait(t, const Duration(milliseconds: 500));
    expect(find.text('This case was played on two devices. You can choose the file to keep playing.'), findsOneWidget);
    await capture(t, 'case_files_notice');
    await t.tap(find.text('Play on for now'));
    await wait(t, const Duration(milliseconds: 900));
    expect(find.text('This case was played on two devices. You can choose the file to keep playing.'), findsNothing);

    // Once only: the case opens straight away the next time.
    await go(t, app.host, Routes.caseFile('ep01'));
    await t.tap(find.widgetWithText(GameButton, 'CONTINUE INVESTIGATION'));
    await wait(t, const Duration(milliseconds: 900));
    expect(find.text('Two Case Files'), findsNothing);
    // The way to the files stays on the case's folder.
    await go(t, app.host, Routes.caseFile('ep01'));
    await t.tap(find.byKey(const ValueKey('two-files-ep01')));
    await wait(t, const Duration(milliseconds: 700));
    expect(find.text('Two Case Files'), findsOneWidget);
  });
}
