import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/mock/season1/season1_discoveries.dart';
import 'package:london_mystery/data/models/discovery.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/models/wallet.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/mission/widgets/answer_feedback.dart';
import 'package:london_mystery/features/onboarding/detective_hold_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show tapText, wait;
import 'helpers.dart';

String save(GameProgress p) => jsonEncode(p.toJson());

/// Case 01 solved, Case 02 under way: what a detective has played.
GameProgress solved01(String name) => GameProgress(
      detectiveName: name,
      introSeen: true,
      completedMissionIds: [for (final m in episode01.allMissions) m.id],
      badgeIds: const ['firstClue', 'puzzleSolver'],
      startedAt: DateTime(2026, 9, 1),
      completedAt: DateTime(2026, 9, 2),
      playMillis: 600000,
    );

/// Saves under a profile's own namespace (as the builds with accounts left
/// them).
Map<String, Object> savesOf(String id, String name, {bool played = true}) => {
      if (played) AppConstants.profileKey(id, AppConstants.progressStorageKey): save(solved01(name)),
      if (played)
        AppConstants.profileKey(id, AppConstants.seasonStorageKey):
            jsonEncode(const SeasonProgress(activeEpisodeId: 'ep02', solvedEpisodeIds: ['ep01']).toJson()),
      AppConstants.profileKey(id, AppConstants.walletStorageKey): jsonEncode(const Wallet([
        CoinEntry(key: 'start', amount: 20, source: CoinSource.start),
      ]).toJson()),
    };

/// The list of detectives of the builds with accounts (`lm.profiles.v1`).
String oldRegistry(String active, List<Map<String, Object>> profiles) =>
    jsonEncode({'schema': 1, 'activeProfileId': active, 'profiles': profiles});

const guest = '11111111111111111111111111111111';
const account = '22222222222222222222222222222222';

Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

Map<String, Object?> snapshot(SharedPreferences p) => {for (final k in p.getKeys()) k: p.get(k)};

void main() {
  group('one detective per device', () {
    test('a new device: an empty slot; creating needs a picture and a valid name', () async {
      final c = ProviderContainer(overrides: await testOverrides());
      addTearDown(c.dispose);
      final game = c.read(gameControllerProvider.notifier);
      expect(c.read(detectiveProfileProvider).isCreated, isFalse);
      expect(c.read(gameControllerProvider).hasDetective, isFalse);

      expect(game.createDetective('Anna', null), isNotNull, reason: 'a picture first');
      expect(game.createDetective('', DetectiveAvatar.girl), 'Please type your detective name.');
      expect(game.createDetective('<b>', DetectiveAvatar.girl), isNotNull);
      expect(game.createDetective('A' * 13, DetectiveAvatar.girl), isNotNull);
      expect(c.read(gameControllerProvider).hasDetective, isFalse);

      final before = DateTime.now();
      expect(game.createDetective('  anna  ', DetectiveAvatar.girl), isNull);
      await Future<void>.delayed(Duration.zero);
      final p = ProfileStore(c.read(sharedPreferencesProvider)).profile!;
      expect(p.detectiveName, 'ANNA');
      expect(p.avatar, DetectiveAvatar.girl);
      expect(p.createdAt, isNotNull);
      expect(p.createdAt!.isBefore(before.subtract(const Duration(seconds: 1))), isFalse);
      expect(p.id, c.read(profileSessionProvider).profileId);
      expect(c.read(gameControllerProvider).detectiveName, 'ANNA');
      expect(c.read(detectiveProfileProvider).avatar, DetectiveAvatar.girl);
    });

    test('a second detective is refused: the first stays as it was', () async {
      final c = ProviderContainer(overrides: await testOverrides());
      addTearDown(c.dispose);
      final game = c.read(gameControllerProvider.notifier);
      expect(game.createDetective('Anna', DetectiveAvatar.girl), isNull);
      await Future<void>.delayed(Duration.zero);
      expect(game.createDetective('Ben', DetectiveAvatar.boy), 'You already have a detective.');
      final p = ProfileStore(c.read(sharedPreferencesProvider)).profile!;
      expect((p.detectiveName, p.avatar), ('ANNA', DetectiveAvatar.girl));
      expect(ProfileStore(c.read(sharedPreferencesProvider)).read()!.held, isEmpty);
    });

    test('a restart keeps the detective, the picture and the progress', () async {
      final c = ProviderContainer(overrides: await testOverrides());
      final prefs = c.read(sharedPreferencesProvider);
      final game = c.read(gameControllerProvider.notifier);
      game.createDetective('Anna', DetectiveAvatar.girl);
      game.startInvestigation();
      game.submitAnswer(episode01.missions.first, 'b');
      final coins = c.read(walletProvider).balance;
      final id = c.read(profileSessionProvider).profileId;
      await Future<void>.delayed(Duration.zero);
      c.dispose();

      final start = await ProfileStore(prefs).bootstrap();
      expect((start as ProfileSession).profileId, id);
      final again = ProviderContainer(overrides: [
        ...await testOverridesFor(prefs),
        profileSessionProvider.overrideWithValue(start),
      ]);
      addTearDown(again.dispose);
      expect(again.read(gameControllerProvider).detectiveName, 'ANNA');
      expect(again.read(gameControllerProvider).completedMissionIds, ['m01']);
      expect(again.read(detectiveProfileProvider).avatar, DetectiveAvatar.girl);
      expect(again.read(walletProvider).balance, coins);
    });

    test('a new name or picture keeps every case, XP, coin, badge and the season', () async {
      final c = ProviderContainer(overrides: await testOverrides(prefs: {
        AppConstants.progressStorageKey: save(solved01('KIM')),
        AppConstants.progressKeyFor('ep02'): save(const GameProgress(detectiveName: 'KIM', introSeen: true)),
        AppConstants.seasonStorageKey: jsonEncode(const SeasonProgress(activeEpisodeId: 'ep02', solvedEpisodeIds: ['ep01']).toJson()),
      }));
      addTearDown(c.dispose);
      final repo = c.read(progressRepositoryProvider);
      final xp = XpBreakdown.totalFor(episode01, repo.load('ep01'));
      final coins = c.read(walletProvider).balance;
      final badges = repo.load('ep01').badgeIds;
      expect(c.read(currentEpisodeProvider).id, 'ep02');

      expect(c.read(gameControllerProvider.notifier).renameDetective('Sherlock'), isNull);
      await c.read(detectiveProfileProvider.notifier).setAvatar(DetectiveAvatar.boy);
      await Future<void>.delayed(Duration.zero);

      expect(c.read(gameControllerProvider).detectiveName, 'SHERLOCK');
      final ep01 = repo.load('ep01');
      expect(ep01.detectiveName, 'SHERLOCK', reason: 'every case save takes the new name');
      expect(ep01.completedMissionIds, solved01('KIM').completedMissionIds);
      expect(ep01.isCaseSolved, isTrue);
      expect(XpBreakdown.totalFor(episode01, ep01), xp);
      expect(ep01.badgeIds, badges);
      expect(c.read(walletProvider).balance, coins);
      expect(c.read(seasonProvider).solvedEpisodeIds, ['ep01']);
      final p = c.read(profileStoreProvider).profile!;
      expect((p.detectiveName, p.avatar), ('SHERLOCK', DetectiveAvatar.boy));
      expect(c.read(gameControllerProvider.notifier).renameDetective('<x>'), isNotNull);
      expect(c.read(gameControllerProvider).detectiveName, 'SHERLOCK');
    });

    testWidgets('the router: CREATE YOUR DETECTIVE only while there is none; settings need one', (t) async {
      late WidgetRef ref;
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(),
        child: Consumer(builder: (context, r, _) {
          ref = r;
          return const LondonMysteryApp();
        }),
      ));
      await wait(t, const Duration(milliseconds: 300));
      String path() => ref.read(routerProvider).routerDelegate.currentConfiguration.uri.path;
      ref.read(routerProvider).go(Routes.detective);
      await wait(t, const Duration(milliseconds: 500));
      expect(path(), Routes.register);
      ref.read(gameControllerProvider.notifier).createDetective('Anna', DetectiveAvatar.girl);
      ref.read(routerProvider).go(Routes.register);
      await wait(t, const Duration(milliseconds: 500));
      expect(path(), Routes.start, reason: 'never a second detective');
    });
  });

  group('earlier saves come to the one detective', () {
    test('the builds with accounts: the guest with progress plays; the account profile is held, untouched', () async {
      final registry = oldRegistry(guest, [
        {'id': guest, 'kind': 'guest', 'detectiveName': 'KIM', 'origin': 'legacy', 'walletBackfill': 'done'},
        {'id': account, 'kind': 'account', 'ownerUid': 'uid-1', 'detectiveName': 'BEN'},
      ]);
      final prefs = await prefsWith({
        AppConstants.profilesStorageKey: registry,
        ...savesOf(guest, 'KIM'),
        ...savesOf(account, 'BEN', played: false),
      });
      final before = snapshot(prefs);
      final start = await ProfileStore(prefs).bootstrap() as ProfileSession;
      expect(start.profileId, guest);
      expect(start.profile.detectiveName, 'KIM');
      expect(start.profile.origin, ProfileOrigin.legacy);
      expect(start.profile.walletBackfill, WalletBackfill.done);
      expect(ProfileStore(prefs).read()!.held, [account]);
      for (final e in before.entries) {
        expect(prefs.get(e.key), e.value, reason: '${e.key}: nothing found is changed');
      }
      final c = ProviderContainer(overrides: [
        ...await testOverridesFor(prefs),
        profileSessionProvider.overrideWithValue(start),
      ]);
      addTearDown(c.dispose);
      expect(c.read(seasonProvider).isSolved('ep01'), isTrue);
      expect(c.read(progressRepositoryProvider).load('ep01').completedMissionIds, hasLength(episode01.allMissions.length));
    });

    test('only an account profile has progress: it becomes the detective', () async {
      final prefs = await prefsWith({
        AppConstants.profilesStorageKey: oldRegistry(guest, [
          {'id': guest, 'kind': 'guest'},
          {'id': account, 'kind': 'account', 'ownerUid': 'uid-1', 'detectiveName': 'BEN'},
        ]),
        ...savesOf(guest, '', played: false),
        ...savesOf(account, 'BEN'),
      });
      final start = await ProfileStore(prefs).bootstrap() as ProfileSession;
      expect(start.profileId, account);
      expect(start.profile.detectiveName, 'BEN');
      expect(ProfileStore(prefs).read()!.held, [guest]);
    });

    test('two detectives with progress: none is chosen, nothing is written; a grown-up chooses', () async {
      final prefs = await prefsWith({
        AppConstants.profilesStorageKey: oldRegistry(guest, [
          {'id': guest, 'kind': 'guest', 'detectiveName': 'KIM'},
          {'id': account, 'kind': 'account', 'ownerUid': 'uid-1', 'detectiveName': 'BEN'},
        ]),
        ...savesOf(guest, 'KIM'),
        ...savesOf(account, 'BEN'),
      });
      final before = snapshot(prefs);
      final start = await ProfileStore(prefs).bootstrap();
      expect(start, isA<ProfileHold>());
      final hold = start as ProfileHold;
      expect([for (final d in hold.candidates) d.name], ['KIM', 'BEN']);
      expect(hold.candidates.every((d) => d.solvedCases == 1), isTrue);
      expect(snapshot(prefs), before, reason: 'held: nothing chosen, nothing written');
      expect(() => ProfileStore(prefs).ensureActiveSync(), throwsStateError);

      final session = await ProfileStore(prefs).resolveHold(hold, account);
      expect(session.profileId, account);
      expect(session.profile.detectiveName, 'BEN');
      expect(ProfileStore(prefs).read()!.held, [guest]);
      for (final e in before.entries) {
        expect(prefs.get(e.key), e.value, reason: '${e.key}: kept');
      }
      final again = await ProfileStore(prefs).bootstrap() as ProfileSession;
      expect(again.profileId, account, reason: 'the choice holds');
    });

    testWidgets('the hold page lists the detectives for a grown-up; the game waits', (t) async {
      final prefs = await prefsWith({
        AppConstants.profilesStorageKey: oldRegistry(guest, [
          {'id': guest, 'kind': 'guest'},
          {'id': account, 'kind': 'account', 'ownerUid': 'uid-1'},
        ]),
        ...savesOf(guest, 'KIM'),
        ...savesOf(account, 'BEN'),
      });
      final store = ProfileStore(prefs);
      final start = await t.runAsync(store.bootstrap);
      await t.pumpWidget(DeviceDetectiveGate(
        start: start!,
        store: store,
        overrides: await testOverridesFor(prefs),
        child: const LondonMysteryApp(),
      ));
      await t.pump();
      expect(find.text('보호자 확인이 필요합니다'), findsOneWidget);
      expect(find.text('Detective KIM'), findsOneWidget);
      expect(find.text('Detective BEN'), findsOneWidget);
      expect(find.text('이 탐정으로 계속'), findsNWidgets(2));
      expect(find.text('START ADVENTURE'), findsNothing, reason: 'the game waits for the choice');
      expect(find.text('CONTINUE ADVENTURE'), findsNothing);
    });
  });

  group('creating the detective on screen', () {
    setUpAll(() async {
      for (final (family, files) in [
        ('Sentient', ['Sentient-Variable.ttf']),
        ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
        ('LibreBaskerville', ['LibreBaskerville.ttf', 'LibreBaskerville-Italic.ttf']),
      ]) {
        final loader = FontLoader(family);
        for (final f in files) {
          loader.addFont(rootBundle.load('assets/fonts/$f'));
        }
        await loader.load();
      }
    });

    for (final (size, scale) in const [(Size(360, 640), 1.0), (Size(390, 844), 1.0), (Size(360, 640), 1.3)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}${scale == 1 ? '' : '_text13'}';
      testWidgets('$tag: picture, name, START INVESTIGATION, then How to Play; kept after a restart', (t) async {
        t.view.physicalSize = size * 3;
        t.view.devicePixelRatio = 3;
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        late WidgetRef ref;
        await t.pumpWidget(ProviderScope(
          overrides: await testOverrides(),
          child: Consumer(builder: (context, r, _) {
            ref = r;
            return const LondonMysteryApp();
          }),
        ));
        await wait(t, const Duration(milliseconds: 1500));
        expect(find.text('Sign in'), findsNothing, reason: 'no accounts');
        expect(find.text('My account'), findsNothing);
        await tapText(t, 'START ADVENTURE');
        expect(find.text('CREATE YOUR DETECTIVE'), findsOneWidget);
        expect(find.text('BOY'), findsOneWidget);
        expect(find.text('GIRL'), findsOneWidget);
        expect(t.takeException(), isNull, reason: 'nothing overflows');

        // No picture yet: asked for one; nothing is made.
        await t.enterText(find.byType(TextField), 'anna');
        await tapText(t, 'START INVESTIGATION', after: const Duration(milliseconds: 400));
        expect(find.text('Choose your detective first.'), findsOneWidget);
        expect(ref.read(gameControllerProvider).hasDetective, isFalse);
        await wait(t, const Duration(seconds: 3)); // the note goes

        await t.tap(find.byKey(const ValueKey('avatar-girl')));
        await t.pump();
        final girl = t.getSemantics(find.byKey(const ValueKey('avatar-girl')));
        expect(girl.flagsCollection.isSelected, Tristate.isTrue);
        // An empty name is refused on the form.
        await t.enterText(find.byType(TextField), '');
        await tapText(t, 'START INVESTIGATION', after: const Duration(milliseconds: 400));
        expect(find.text('Please type your detective name.'), findsOneWidget);
        expect(ref.read(gameControllerProvider).hasDetective, isFalse);

        await t.enterText(find.byType(TextField), 'anna');
        await tapText(t, 'START INVESTIGATION', after: const Duration(milliseconds: 900));
        expect(find.text('Welcome, Detective!'), findsOneWidget, reason: 'How to Play comes first');
        final p = ref.read(profileStoreProvider).profile!;
        expect((p.detectiveName, p.avatar), ('ANNA', DetectiveAvatar.girl));
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('My detective: a new name and picture are saved; progress stays', (t) async {
      late WidgetRef ref;
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: {AppConstants.progressStorageKey: save(solved01('KIM'))}),
        child: Consumer(builder: (context, r, _) {
          ref = r;
          return const LondonMysteryApp();
        }),
      ));
      await wait(t, const Duration(milliseconds: 500));
      final coins = ref.read(walletProvider).balance;
      ref.read(routerProvider).push(Routes.detective);
      await wait(t, const Duration(milliseconds: 600));
      expect(find.text('YOUR DETECTIVE'), findsOneWidget);
      expect(find.text('KIM'), findsOneWidget, reason: 'the name as it is');
      await t.tap(find.byKey(const ValueKey('avatar-boy')));
      await t.enterText(find.byType(TextField), 'watson');
      await tapText(t, 'SAVE CHANGES', after: const Duration(milliseconds: 900));
      expect(ref.read(gameControllerProvider).detectiveName, 'WATSON');
      expect(ref.read(detectiveProfileProvider).avatar, DetectiveAvatar.boy);
      expect(ref.read(gameControllerProvider).completedMissionIds, hasLength(episode01.allMissions.length));
      expect(ref.read(walletProvider).balance, coins);
      expect(ref.read(routerProvider).routerDelegate.currentConfiguration.uri.path, Routes.start,
          reason: 'back where it was opened from');
      await wait(t, const Duration(seconds: 3)); // the note goes
    });
  });

  group('mission complete', () {
    test('every cheer keeps the timing rule: nothing seen before the puzzle is "discovered"', () {
      final season = MockEpisodeRepository.bundled();
      for (final e in season) {
        for (final m in e.missions) {
          final d = discoveryOf(m);
          expect(d.type.cheer, isNotEmpty);
          if (d.timing == DiscoveryTiming.beforePuzzle) {
            expect(d.type.cheer.toLowerCase(), isNot(contains('discover')), reason: m.id);
          }
        }
      }
    });

    test('solving again pays nothing and announces nothing new', () async {
      final c = ProviderContainer(overrides: await testOverrides());
      addTearDown(c.dispose);
      final game = c.read(gameControllerProvider.notifier);
      game.createDetective('Anna', DetectiveAvatar.girl);
      game.startInvestigation();
      final first = game.submitAnswer(episode01.missions.first, 'b');
      expect((first.firstSolve, first.coins), (true, AppConstants.missionCoins));
      final coins = c.read(walletProvider).balance;
      expect(game.submitAnswer(episode01.missions.first, 'b').coins, 0, reason: 'a second tap');
      game.playAgain();
      game.startInvestigation();
      final again = game.submitAnswer(episode01.missions.first, 'b');
      expect((again.firstSolve, again.coins), (false, 0));
      expect(c.read(walletProvider).balance, coins);
      expect(XpBreakdown.totalFor(episode01, c.read(gameControllerProvider)), AppConstants.missionXp,
          reason: 'the case XP is counted once');
      expect(WalletController.coinsFor(episode01.missions.first), AppConstants.missionCoins);
    });

    for (final firstSolve in [true, false]) {
      testWidgets('the moment: cheer, ${firstSolve ? 'the reward' : 'already counted'}, CONTINUE INVESTIGATION',
          (t) async {
        late BuildContext context;
        await t.pumpWidget(ProviderScope(
          overrides: await testOverrides(),
          child: MaterialApp(home: Builder(builder: (c) {
            context = c;
            return const Scaffold();
          })),
        ));
        final m = episode01.missions.first;
        final d = discoveryOf(m);
        final closed = showDiscoveryMoment(context,
            mission: m, discovery: d, xp: const XpBreakdown(base: 30), coins: firstSolve ? 30 : 0, firstSolve: firstSolve);
        await t.pump();
        await t.pump(const Duration(milliseconds: 2600));
        expect(find.text(d.type.cheer), findsOneWidget);
        expect(find.text('+30 XP   ·   +30 COINS'), firstSolve ? findsOneWidget : findsNothing);
        expect(find.text(alreadyRewarded), firstSolve ? findsNothing : findsOneWidget);
        await t.tap(find.text('CONTINUE INVESTIGATION'));
        await t.pumpAndSettle();
        await closed;
      });
    }
  });

  group('offline only', () {
    test('no Firebase, no network package in the app or its build', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final dep in ['firebase', 'cloud_firestore', 'http:', 'dio:', 'connectivity']) {
        expect(pubspec, isNot(contains(dep)), reason: dep);
      }
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        final src = f.readAsStringSync();
        for (final banned in ['package:firebase', 'package:cloud_firestore', 'package:http/', 'HttpClient', 'dart:io']) {
          expect(src, isNot(contains(banned)), reason: '${f.path}: $banned');
        }
      }
      expect(File('android/app/build.gradle.kts').readAsStringSync(), isNot(contains('google-services')));
      expect(File('android/settings.gradle.kts').readAsStringSync(), isNot(contains('google-services')));
      expect(File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync(), isNot(contains('GoogleService')));
      expect(File('android/app/src/main/AndroidManifest.xml').readAsStringSync(), isNot(contains('INTERNET')),
          reason: 'a release build asks for no network');
      expect(Directory('lib/features/account').existsSync(), isFalse);
      expect(Directory('lib/features/sync').existsSync(), isFalse);
      expect(Directory('lib/data/sync').existsSync(), isFalse);
      expect(Directory('lib/core/cloud').existsSync(), isFalse);
    });

    testWidgets('a whole case is played and kept with nothing but the device', (t) async {
      // The game reads and writes the device only: a case played start to
      // finish, then the app started again, finds everything.
      final c = ProviderContainer(overrides: await testOverrides());
      final prefs = c.read(sharedPreferencesProvider);
      final game = c.read(gameControllerProvider.notifier);
      game.createDetective('Anna', DetectiveAvatar.girl);
      game.startInvestigation();
      for (final m in episode01.allMissions) {
        expect(game.submitAnswer(m, m.answer).result, SubmitResult.correct, reason: m.id);
      }
      expect(c.read(gameControllerProvider).isCaseSolved, isTrue);
      final xp = XpBreakdown.totalFor(episode01, c.read(gameControllerProvider));
      final coins = c.read(walletProvider).balance;
      await t.runAsync(() => Future<void>.delayed(Duration.zero));
      c.dispose();

      final start = await t.runAsync(() => ProfileStore(prefs).bootstrap());
      final again = ProviderContainer(overrides: [
        ...await testOverridesFor(prefs),
        profileSessionProvider.overrideWithValue(start! as ProfileSession),
      ]);
      addTearDown(again.dispose);
      expect(again.read(gameControllerProvider).isCaseSolved, isTrue);
      expect(XpBreakdown.totalFor(episode01, again.read(gameControllerProvider)), xp);
      expect(again.read(walletProvider).balance, coins);
      expect(again.read(seasonProvider).isSolved('ep01'), isTrue);
      expect(again.read(gameControllerProvider.notifier).openEpisode('ep02'), isTrue, reason: 'the next case opens');
    });
  });
}
