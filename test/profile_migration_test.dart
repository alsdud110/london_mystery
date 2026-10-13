import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/wallet.dart';
import 'package:london_mystery/data/repositories/legacy_migrator.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

String save(GameProgress p) => jsonEncode(p.toJson());

/// Saves of a detective from before profiles: Case 01 solved under XP rule
/// 3 (100 / 200), a tip bought, Case 02 under way, the season and a wallet.
final legacySaves = <String, Object>{
  AppConstants.progressStorageKey: save(GameProgress(
    detectiveName: 'KIM',
    introSeen: true,
    completedMissionIds: [for (final m in episode01.allMissions) m.id],
    hintsUsed: const {'m01': 2},
    xpRules: {for (final m in episode01.allMissions) m.id: 3},
    startedAt: DateTime(2026, 9, 1),
    completedAt: DateTime(2026, 9, 2),
    playMillis: 600000,
  )),
  AppConstants.progressKeyFor('ep02'): save(const GameProgress(detectiveName: 'KIM', introSeen: true)),
  AppConstants.seasonStorageKey: jsonEncode({'activeEpisodeId': 'ep02', 'solvedEpisodeIds': ['ep01']}),
  AppConstants.walletStorageKey: jsonEncode(const Wallet([
    CoinEntry(key: 'start', amount: 20, source: CoinSource.start),
    CoinEntry(key: 'mission:m01', amount: 30, source: CoinSource.backfill),
    CoinEntry(key: 'tip:m01:2', amount: -20, source: CoinSource.tip),
  ]).toJson()),
};

Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

Map<String, Object?> snapshot(SharedPreferences p) => {for (final k in p.getKeys()) k: p.get(k)};

Map<String, dynamic> marker(SharedPreferences p) =>
    jsonDecode(p.getString(AppConstants.legacyMigrationKey)!) as Map<String, dynamic>;

void main() {
  tearDown(() => LegacyMigrator.simulateVerifyFailure = false);

  group('first start', () {
    test('an empty device gets one fresh guest that starts with the start coins only', () async {
      final prefs = await prefsWith({});
      final session = await ProfileStore(prefs).bootstrap();
      expect(session.legacyFallback, isFalse);
      expect(session.profile.kind, ProfileKind.guest);
      expect(session.profile.origin, ProfileOrigin.fresh);
      expect(session.profile.walletBackfill, WalletBackfill.never);
      expect(ProfileStore(prefs).read()!.profiles, hasLength(1));
      expect(prefs.getString(AppConstants.legacyMigrationKey), isNull, reason: 'nothing to copy');
    });

    test('saves from before profiles are copied byte for byte; the originals stay as they were', () async {
      final prefs = await prefsWith(legacySaves);
      final session = await ProfileStore(prefs).bootstrap();
      final pid = session.profileId;
      expect(session.legacyFallback, isFalse);
      for (final e in legacySaves.entries) {
        expect(prefs.getString(e.key), e.value, reason: '${e.key}: the original is untouched');
        expect(prefs.getString(AppConstants.profileKey(pid, e.key)), e.value, reason: '${e.key}: copied exactly');
      }
      expect(marker(prefs)['state'], 'done');
      expect(marker(prefs)['profileId'], pid);
      final p = ProfileStore(prefs).read()!.active;
      expect(p.id, pid);
      expect(p.origin, ProfileOrigin.legacy);
      expect(p.detectiveName, 'KIM', reason: 'from the open case');
      expect(p.walletBackfill, WalletBackfill.done, reason: 'the wallet was copied');
    });

    test('the copied game plays as before: XP of rule 3, coins, tips owned, the season', () async {
      final c = ProviderContainer(overrides: await testOverrides(prefs: legacySaves));
      addTearDown(c.dispose);
      expect(c.read(seasonProvider).isSolved('ep01'), isTrue);
      expect(c.read(seasonProvider).activeEpisodeId, 'ep02');
      expect(c.read(gameControllerProvider).detectiveName, 'KIM');
      final ep01 = c.read(progressRepositoryProvider).load('ep01');
      expect(XpBreakdown.totalFor(episode01, ep01), 5 * 100 + 200, reason: 'rule 3 XP is kept');
      expect(c.read(walletProvider).balance, 30);
      expect(c.read(walletProvider).ownsTip('m01', 2), isTrue, reason: 'bought before, still free to read again');
      expect(c.read(walletProvider).entries.map((e) => e.key), ['start', 'mission:m01', 'tip:m01:2']);
    });
  });

  group('running again', () {
    test('a second start changes nothing', () async {
      final prefs = await prefsWith(legacySaves);
      final first = await ProfileStore(prefs).bootstrap();
      final before = snapshot(prefs);
      final again = await ProfileStore(prefs).bootstrap();
      expect(again.profileId, first.profileId);
      expect(snapshot(prefs), before);
    });

    test('a copy cut short continues with the same profile and keeps what was copied', () async {
      // Stopped after the record and the first key: no registry yet.
      const pid = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      final prefs = await prefsWith({
        ...legacySaves,
        AppConstants.legacyMigrationKey: jsonEncode({'state': 'copying', 'profileId': pid}),
        AppConstants.profileKey(pid, AppConstants.progressStorageKey): legacySaves[AppConstants.progressStorageKey]!,
      });
      final session = await ProfileStore(prefs).bootstrap();
      expect(session.profileId, pid);
      expect(session.legacyFallback, isFalse);
      for (final e in legacySaves.entries) {
        expect(prefs.getString(AppConstants.profileKey(pid, e.key)), e.value);
        expect(prefs.getString(e.key), e.value);
      }
      expect(marker(prefs)['state'], 'done');
      expect(ProfileStore(prefs).read()!.profiles.map((p) => p.id), [pid], reason: 'one guest, not two');
    });

    test('cut short between the registry and the done mark: marked done on the next start', () async {
      final prefs = await prefsWith(legacySaves);
      final session = await ProfileStore(prefs).bootstrap();
      await prefs.setString(
        AppConstants.legacyMigrationKey,
        jsonEncode({'state': 'copying', 'profileId': session.profileId}),
      );
      expect((await ProfileStore(prefs).bootstrap()).profileId, session.profileId);
      expect(marker(prefs)['state'], 'done');
    });

    test('an unreadable registry is rebuilt for the same profile, its saves kept', () async {
      final prefs = await prefsWith(legacySaves);
      final session = await ProfileStore(prefs).bootstrap();
      final pid = session.profileId;
      final newer = save(const GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: ['x']));
      await prefs.setString(AppConstants.profileKey(pid, AppConstants.progressKeyFor('ep02')), newer);
      await prefs.setString(AppConstants.profilesStorageKey, '{not json');
      final again = await ProfileStore(prefs).bootstrap();
      expect(again.profileId, pid);
      expect(prefs.getString(AppConstants.profileKey(pid, AppConstants.progressKeyFor('ep02'))), newer,
          reason: 'newer progress is never replaced by the old copy');
    });
  });

  group('newer progress and damaged records are never overwritten or lost', () {
    const pid = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    final case01 = AppConstants.progressStorageKey;
    final newer = save(GameProgress(
      detectiveName: 'KIM',
      introSeen: true,
      completedMissionIds: [for (final m in episode01.allMissions) m.id],
      xpRules: {for (final m in episode01.allMissions) m.id: 3},
      lookedUpWords: const ['crown', 'shadow'],
      startedAt: DateTime(2026, 9, 1),
      completedAt: DateTime(2026, 9, 2),
      playMillis: 900000,
    ));

    test('a copy cut short, then new progress in the profile: the retry keeps it', () async {
      final prefs = await prefsWith({
        ...legacySaves,
        AppConstants.legacyMigrationKey: jsonEncode({'state': 'copying', 'profileId': pid}),
        AppConstants.profileKey(pid, case01): newer,
      });
      final session = await ProfileStore(prefs).bootstrap();
      expect(session.profileId, pid);
      expect(prefs.getString(AppConstants.profileKey(pid, case01)), newer, reason: 'not replaced by the older original');
      expect(prefs.getString(AppConstants.profileKey(pid, AppConstants.seasonStorageKey)),
          legacySaves[AppConstants.seasonStorageKey],
          reason: 'what was missing is copied');
      for (final e in legacySaves.entries) {
        expect(prefs.getString(e.key), e.value);
      }
    });

    test('after the copy, the profile moves on; restarts never copy the originals again', () async {
      final c = ProviderContainer(overrides: await testOverrides(prefs: legacySaves));
      final prefs = c.read(sharedPreferencesProvider);
      c.read(gameControllerProvider.notifier).lookUpWord('platform');
      final played = savedString(prefs, AppConstants.progressKeyFor('ep02'));
      final coins = c.read(walletProvider).balance;
      c.dispose();
      for (var i = 0; i < 3; i++) {
        await ProfileStore(prefs).bootstrap();
      }
      final again = ProviderContainer(overrides: await testOverridesFor(prefs));
      addTearDown(again.dispose);
      expect(savedString(prefs, AppConstants.progressKeyFor('ep02')), played);
      expect(again.read(gameControllerProvider).lookedUpWords, contains('platform'));
      expect(again.read(walletProvider).balance, coins);
      for (final e in legacySaves.entries) {
        expect(prefs.getString(e.key), e.value);
      }
    });

    test('an unreadable copy record with the registry intact changes nothing', () async {
      final prefs = await prefsWith(legacySaves);
      final session = await ProfileStore(prefs).bootstrap();
      await prefs.setString(AppConstants.profileKey(session.profileId, case01), newer);
      await prefs.setString(AppConstants.legacyMigrationKey, '{broken');
      final before = snapshot(prefs);
      final again = await ProfileStore(prefs).bootstrap();
      expect(again.profileId, session.profileId);
      expect(snapshot(prefs), before);
    });

    test('an unreadable copy record mid-copy: the same profile continues, its progress kept', () async {
      final prefs = await prefsWith({
        ...legacySaves,
        AppConstants.legacyMigrationKey: '{broken',
        AppConstants.profileKey(pid, case01): newer,
      });
      final session = await ProfileStore(prefs).bootstrap();
      expect(session.profileId, pid, reason: 'found by its own saves, not a new profile');
      expect(prefs.getString(AppConstants.profileKey(pid, case01)), newer);
      expect(ProfileStore(prefs).read()!.profiles.map((p) => p.id), [pid]);
    });

    test('registry and record both unreadable on a device that never had old saves: the profile is found', () async {
      final c = ProviderContainer(overrides: await testOverrides());
      final prefs = c.read(sharedPreferencesProvider);
      final id = c.read(profileSessionProvider).profileId;
      c.read(gameControllerProvider.notifier).registerDetective('ANNA');
      expect(c.read(walletProvider).balance, 20);
      c.dispose();
      await prefs.setString(AppConstants.profilesStorageKey, 'garbage');

      final session = await ProfileStore(prefs).bootstrap();
      expect(session.profileId, id);
      expect(session.profile.origin, ProfileOrigin.fresh);
      expect(session.profile.detectiveName, 'ANNA');
      expect(session.profile.walletBackfill, WalletBackfill.done);
      expect(prefs.getString(AppConstants.legacyMigrationKey), isNull, reason: 'nothing was copied');
    });

    test('registry unreadable and the wallet lost after a finished copy: no second pay-back', () async {
      final beforeCoins = {
        AppConstants.progressStorageKey: save(const GameProgress(
          detectiveName: 'LEE',
          introSeen: true,
          completedMissionIds: ['m01', 'm02'],
        )),
      };
      final c = ProviderContainer(overrides: await testOverrides(prefs: beforeCoins));
      final prefs = c.read(sharedPreferencesProvider);
      final id = c.read(profileSessionProvider).profileId;
      expect(c.read(walletProvider).balance, 80, reason: 'paid back once: 20 + 30 + 30');
      c.dispose();
      await prefs.setString(AppConstants.profilesStorageKey, 'garbage');
      await prefs.remove(AppConstants.profileKey(id, AppConstants.walletStorageKey));

      final session = await ProfileStore(prefs).bootstrap();
      expect(session.profileId, id);
      expect(session.profile.walletBackfill, WalletBackfill.never);
      final again = ProviderContainer(overrides: await testOverridesFor(prefs));
      addTearDown(again.dispose);
      expect(again.read(walletProvider).balance, 20);
    });
  });

  group('safe mode (the copy could not be verified)', () {
    test('plays from the original saves, saves nothing over them, and tries again next start', () async {
      final prefs = await prefsWith(legacySaves);
      LegacyMigrator.simulateVerifyFailure = true;
      final session = await ProfileStore(prefs).bootstrap();
      expect(session.legacyFallback, isTrue);
      expect(ProfileStore(prefs).read(), isNull, reason: 'not marked done');
      expect(marker(prefs)['state'], 'copying');

      // The game in safe mode: the original saves are read …
      final c = ProviderContainer(overrides: [
        ...await testOverridesFor(prefs),
        profileSessionProvider.overrideWithValue(session),
      ]);
      expect(c.read(gameControllerProvider).detectiveName, 'KIM');
      expect(c.read(walletProvider).balance, 30);
      // … and new progress goes to the profile's own keys, never the originals.
      c.read(gameControllerProvider.notifier).lookUpWord('clock');
      c.dispose();
      for (final e in legacySaves.entries) {
        expect(prefs.getString(e.key), e.value, reason: '${e.key}: original untouched');
      }

      // Next start: the copy works; the newer progress made in safe mode is kept.
      LegacyMigrator.simulateVerifyFailure = false;
      final next = await ProfileStore(prefs).bootstrap();
      expect(next.legacyFallback, isFalse);
      expect(next.profileId, session.profileId);
      final ep02 = prefs.getString(AppConstants.profileKey(next.profileId, AppConstants.progressKeyFor('ep02')))!;
      expect(ep02, contains('clock'));
      expect(marker(prefs)['state'], 'done');
    });

    test('starting over in safe mode hides the originals without removing them', () async {
      final prefs = await prefsWith(legacySaves);
      LegacyMigrator.simulateVerifyFailure = true;
      final session = await ProfileStore(prefs).bootstrap();
      final c = ProviderContainer(overrides: [
        ...await testOverridesFor(prefs),
        profileSessionProvider.overrideWithValue(session),
      ]);
      await c.read(gameControllerProvider.notifier).resetAll();
      expect(c.read(progressRepositoryProvider).load('ep01').hasDetective, isFalse);
      expect(c.read(seasonProvider).solvedEpisodeIds, isEmpty);
      c.dispose();
      for (final e in legacySaves.entries) {
        expect(prefs.getString(e.key), e.value);
      }
      LegacyMigrator.simulateVerifyFailure = false;
      final next = await ProfileStore(prefs).bootstrap();
      final repoKeys = prefs.getKeys().where((k) => k.startsWith(AppConstants.profilePrefix(next.profileId)));
      expect(repoKeys.any((k) => k.endsWith('progress.v1')), isFalse, reason: 'the originals are not copied back');
    });
  });

  group('wallet pay-back for saves from before coins', () {
    final beforeCoins = <String, Object>{
      AppConstants.progressStorageKey: save(GameProgress(
        detectiveName: 'LEE',
        introSeen: true,
        completedMissionIds: const ['m01', 'm02'],
        hintsUsed: const {'m01': 1},
        startedAt: DateTime(2026, 8, 1),
      )),
    };

    test('runs once: the wallet is made with the pay-back, and never made with it again', () async {
      final c = ProviderContainer(overrides: await testOverrides(prefs: beforeCoins));
      final prefs = c.read(sharedPreferencesProvider);
      final pid = c.read(profileSessionProvider).profileId;
      expect(ProfileStore(prefs).profile(pid)!.walletBackfill, WalletBackfill.pending);
      expect(c.read(walletProvider).balance, 20 + 30 + 30);
      expect(c.read(walletProvider).ownsTip('m01', 1), isTrue);
      expect(ProfileStore(prefs).profile(pid)!.walletBackfill, WalletBackfill.done);
      c.dispose();

      // The wallet record is lost: a new wallet has the start coins only.
      await prefs.remove(AppConstants.profileKey(pid, AppConstants.walletStorageKey));
      final again = ProviderContainer(overrides: await testOverridesFor(prefs));
      addTearDown(again.dispose);
      expect(again.read(walletProvider).balance, 20);
      expect(again.read(walletProvider).entries.where((e) => e.source == CoinSource.backfill), isEmpty);
    });

    test('a fresh profile is never paid back for case saves it finds', () async {
      final prefs = await prefsWith({});
      final session = await ProfileStore(prefs).bootstrap();
      await prefs.setString(
        AppConstants.profileKey(session.profileId, AppConstants.progressStorageKey),
        beforeCoins[AppConstants.progressStorageKey]! as String,
      );
      final c = ProviderContainer(overrides: await testOverridesFor(prefs));
      addTearDown(c.dispose);
      expect(c.read(walletProvider).balance, WalletController.priceOf(2), reason: 'start coins only (20)');
    });
  });
}
