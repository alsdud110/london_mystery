import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/data/models/wallet.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/data/repositories/profile_store.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/game/scoring.dart';
import 'package:world_mystery/features/game/wallet_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';

/// Difficulty PART 3: each season's level fixed at its first intro, changed
/// freely before, only by restarting the season while it is under way (the
/// coins and tips bought kept, nothing paid twice), and READY FOR YOUR NEXT
/// MYSTERY? once London is complete (see docs/DIFFICULTY_IMPLEMENTATION.md).

const id = 'abcdef0123456789abcdef0123456789';
final catalog = MockEpisodeRepository.bundled();
List<Episode> casesOf(String seasonId) => [for (final e in catalog) if (e.seasonId == seasonId) e];
final london = casesOf(SeasonIds.london);
final paris = casesOf(SeasonIds.paris);

String pk(String legacyKey) => AppConstants.profileKey(id, legacyKey);
String caseKey(String episodeId) => pk(AppConstants.progressKeyFor(episodeId));
String seasonKey(String seasonId) => pk(AppConstants.seasonKeyFor(seasonId));
final walletKey = pk(AppConstants.walletStorageKey);
final selectedKey = pk(AppConstants.selectedSeasonKey);
final journalKey = AppConstants.journalKey(id);

String profile({Difficulty? level}) => jsonEncode({
      'schema': 1,
      'profile': {
        'id': id,
        'origin': 'fresh',
        'walletBackfill': 'never',
        'detectiveName': 'KIM',
        'avatar': 'girl',
        'createdAt': '2026-09-01T10:00:00.000',
        'difficulty': ?level?.storageId,
      },
    });

String save(GameProgress p) => jsonEncode(p.toJson());
String record(SeasonProgress s) => jsonEncode(s.toJson());

GameProgress solved(Episode e) => GameProgress(
      detectiveName: 'KIM',
      introSeen: true,
      completedMissionIds: [for (final m in e.allMissions) m.id],
      badgeIds: const ['firstClue'],
      xpRules: {for (final m in e.allMissions) m.id: XpBreakdown.currentRule},
      startedAt: DateTime(2026, 9, 2),
      completedAt: DateTime(2026, 9, 2, 1),
      playMillis: 1000,
    );

/// A wallet that paid every solved mission of [paid] and bought tip 2 of
/// [tipsOf] (20 coins).
String wallet({Iterable<Episode> paid = const [], Iterable<String> paidIds = const [], Iterable<String> tipsOf = const []}) => jsonEncode(Wallet([
      const CoinEntry(key: Wallet.startKey, amount: 20, source: CoinSource.start),
      for (final e in paid)
        for (final m in e.allMissions) CoinEntry(key: Wallet.missionKey(m.id), amount: WalletController.coinsFor(m), source: CoinSource.mission),
      for (final m in paidIds) CoinEntry(key: Wallet.missionKey(m), amount: AppConstants.missionCoins, source: CoinSource.mission),
      for (final m in tipsOf) ...[
        CoinEntry(key: Wallet.tipKey(m, 1), amount: 0, source: CoinSource.tip),
        CoinEntry(key: Wallet.tipKey(m, 2), amount: -20, source: CoinSource.tip),
      ],
    ]).toJson());

/// London under way: Cases 01–02 solved, Case 03 begun (its intro seen,
/// its M1 solved, a tip bought). Coins paid for all of it.
Map<String, Object> londonUnderWay({Difficulty? fixed, Difficulty? profileLevel}) => {
      AppConstants.detectiveStorageKey: profile(level: profileLevel),
      caseKey('ep01'): save(solved(london[0])),
      caseKey('ep02'): save(solved(london[1])),
      caseKey('ep03'): save(GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: const ['ep03_m1'], hintsUsed: const {'ep03_m1': 2})),
      seasonKey(SeasonIds.london): record(SeasonProgress(activeEpisodeId: 'ep03', solvedEpisodeIds: const ['ep01', 'ep02'], difficulty: fixed)),
      walletKey: wallet(paid: london.take(2), paidIds: const ['ep03_m1'], tipsOf: const ['ep03_m1']),
    };

/// London complete (every case solved, paid), Case 12 open.
Map<String, Object> londonComplete({Difficulty? fixed, bool asked = false}) => {
      AppConstants.detectiveStorageKey: profile(),
      for (final e in london) caseKey(e.id): save(solved(e)),
      seasonKey(SeasonIds.london): record(SeasonProgress(
        activeEpisodeId: 'ep12',
        solvedEpisodeIds: [for (final e in london) e.id],
        difficulty: fixed,
        nextLevelAsked: asked,
      )),
      walletKey: wallet(paid: london),
    };

/// London complete, Paris under way and played (Case 01 solved, Case 02
/// begun) at [parisLevel].
Map<String, Object> parisUnderWay({Difficulty parisLevel = Difficulty.junior}) => {
      ...londonComplete(fixed: Difficulty.rookie, asked: true),
      caseKey('s2_ep01'): save(solved(paris[0])),
      caseKey('s2_ep02'): save(const GameProgress(detectiveName: 'KIM', introSeen: true)),
      seasonKey(SeasonIds.paris): record(SeasonProgress(
        activeEpisodeId: 's2_ep02',
        solvedEpisodeIds: const ['s2_ep01'],
        prologueSeen: true,
        difficulty: parisLevel,
      )),
      selectedKey: jsonEncode({'seasonId': SeasonIds.paris}),
      walletKey: wallet(paid: [...london, paris[0]]),
    };

Map<String, Object?> snapshot(SharedPreferences p) => {for (final k in p.getKeys()) k: p.get(k)};

Future<ProviderContainer> containerWith(Map<String, Object> prefs, {List<Override> extra = const []}) async {
  final c = ProviderContainer(overrides: [...await testOverrides(prefs: prefs), ...extra]);
  addTearDown(c.dispose);
  return c;
}

Future<ProviderContainer> restarted(SharedPreferences prefs, {List<Override> extra = const []}) async {
  final c = ProviderContainer(overrides: [...await testOverridesFor(prefs), ...extra]);
  addTearDown(c.dispose);
  return c;
}

int seasonXp(ProviderContainer c, List<Episode> cases) {
  final repo = c.read(progressRepositoryProvider);
  var xp = 0;
  for (final e in cases) {
    final p = repo.load(e.id);
    for (final m in e.allMissions) {
      if (p.isCompleted(m.id)) xp += XpBreakdown.of(m, p).total;
    }
  }
  return xp;
}

void main() {
  setUpAll(() async {
    // The real faces: the papers and links wrap as on a phone.
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

  group('the season\'s level', () {
    for (final level in Difficulty.values) {
      test('1–3. London begun as ${level.label}: fixed at its first intro, kept', () async {
        final c = await containerWith({AppConstants.detectiveStorageKey: profile(level: level)});
        final before = c.read(seasonLevelProvider(SeasonIds.london))!;
        expect(before.status, SeasonLevelStatus.notStarted);
        expect(before.level, level);
        expect(before.fixed, isNull);
        c.read(gameControllerProvider.notifier).settleSeasonLevel(); // the intro entered
        final after = c.read(seasonLevelProvider(SeasonIds.london))!;
        expect(after.fixed, level);
        expect(after.status, SeasonLevelStatus.inProgress);
        expect(c.read(currentDifficultyProvider), level);
        final saved = SeasonProgress.fromJson(jsonDecode(c.read(sharedPreferencesProvider).getString(seasonKey(SeasonIds.london))!));
        expect(saved.difficulty, level);
        // Entering an intro again changes nothing.
        await c.read(detectiveProfileProvider.notifier).setDifficulty(Difficulty.values[(level.index + 1) % 3]);
        c.read(gameControllerProvider.notifier).settleSeasonLevel();
        expect(c.read(currentDifficultyProvider), level);
      });
    }

    test('4–5. London fixed, the detective\'s level changed: London keeps its own, Paris (not begun) takes the new one', () async {
      final c = await containerWith(londonUnderWay(fixed: Difficulty.junior));
      await c.read(detectiveProfileProvider.notifier).setDifficulty(Difficulty.master);
      expect(c.read(seasonDifficultyProvider(SeasonIds.london)), Difficulty.junior);
      expect(c.read(seasonDifficultyProvider(SeasonIds.paris)), Difficulty.master);
      expect(c.read(seasonLevelProvider(SeasonIds.paris))!.status, SeasonLevelStatus.notStarted);
    });

    test('5. London and Paris levels apart; Paris restarted, London\'s level and saves as they were', () async {
      final c = await containerWith(parisUnderWay(parisLevel: Difficulty.master));
      final prefs = c.read(sharedPreferencesProvider);
      expect(c.read(selectedSeasonIdProvider), SeasonIds.paris);
      expect(c.read(seasonDifficultyProvider(SeasonIds.london)), Difficulty.rookie);
      expect(c.read(seasonDifficultyProvider(SeasonIds.paris)), Difficulty.master);
      final londonBefore = {for (final k in [seasonKey(SeasonIds.london), for (final e in london) caseKey(e.id)]) k: prefs.getString(k)};
      c.read(gameControllerProvider.notifier).restartSeason(SeasonIds.paris, Difficulty.junior);
      expect(c.read(seasonDifficultyProvider(SeasonIds.paris)), Difficulty.junior);
      expect(c.read(seasonDifficultyProvider(SeasonIds.london)), Difficulty.rookie);
      expect({for (final k in londonBefore.keys) k: prefs.getString(k)}, londonBefore, reason: 'London untouched, byte for byte');
    });

    test('6. Only the opening seen: not begun, the level changes freely', () async {
      final c = await containerWith({
        AppConstants.detectiveStorageKey: profile(level: Difficulty.rookie),
        seasonKey(SeasonIds.london): record(const SeasonProgress(prologueSeen: true)),
      });
      expect(c.read(seasonLevelProvider(SeasonIds.london))!.status, SeasonLevelStatus.notStarted);
      await c.read(detectiveProfileProvider.notifier).setDifficulty(Difficulty.master);
      expect(c.read(currentDifficultyProvider), Difficulty.master);
      expect(c.read(seasonLevelProvider(SeasonIds.london))!.fixed, isNull, reason: 'nothing fixed by a change');
    });

    testWidgets('7. Case 01\'s intro entered: the level fixed (the profile\'s); the case files alone fix nothing', (t) async {
      late WidgetRef ref;
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: {
          AppConstants.detectiveStorageKey: profile(level: Difficulty.junior),
          caseKey('ep01'): save(const GameProgress(detectiveName: 'KIM')),
        }),
        child: Consumer(builder: (context, r, _) {
          ref = r;
          return const WorldMysteryApp();
        }),
      ));
      await wait(t, const Duration(milliseconds: 300));
      ref.read(routerProvider).go(Routes.episodes);
      await wait(t, const Duration(milliseconds: 600));
      expect(ref.read(seasonProvider).difficulty, isNull, reason: 'looking at the case files fixes nothing');
      ref.read(routerProvider).go(Routes.intro);
      await wait(t, const Duration(milliseconds: 300));
      expect(ref.read(seasonProvider).difficulty, Difficulty.junior);
      final prefs = ref.read(sharedPreferencesProvider);
      expect(SeasonProgress.fromJson(jsonDecode(prefs.getString(seasonKey(SeasonIds.london))!)).difficulty, Difficulty.junior);
      await wait(t, const Duration(seconds: 2));
    });

    test('8. A season played before levels: under way at Rookie, whatever the profile; read without a write; fixed Rookie at the next intro', () async {
      final c = await containerWith(londonUnderWay());
      final prefs = c.read(sharedPreferencesProvider);
      final before = snapshot(prefs);
      final s = c.read(seasonLevelProvider(SeasonIds.london))!;
      expect(s.status, SeasonLevelStatus.inProgress);
      expect(s.level, Difficulty.rookie);
      expect(s.fixed, isNull);
      expect(c.read(levelSeasonProvider), SeasonIds.london);
      expect(snapshot(prefs), before, reason: 'asking writes nothing');
      await c.read(detectiveProfileProvider.notifier).setDifficulty(Difficulty.master);
      expect(c.read(currentDifficultyProvider), Difficulty.rookie, reason: 'its progress stays at the level it was played at');
      c.read(gameControllerProvider.notifier).settleSeasonLevel();
      expect(c.read(seasonProvider).difficulty, Difficulty.rookie);
      expect(c.read(seasonProvider).solvedEpisodeIds, ['ep01', 'ep02'], reason: 'its progress kept');
      expect(c.read(gameControllerProvider).isCompleted('ep03_m1'), isTrue);
    });

    test('8. A complete season from before levels reads complete, at Rookie', () async {
      final c = await containerWith(londonComplete());
      final s = c.read(seasonLevelProvider(SeasonIds.london))!;
      expect(s.status, SeasonLevelStatus.completed);
      expect(s.level, Difficulty.rookie);
      expect(c.read(levelSeasonProvider), SeasonIds.paris, reason: 'a change is for the season to come');
    });
  });

  group('restarting a season', () {
    test('10–17. London under way restarted at Junior: only London starts over; profile, coins, tips bought, other seasons kept', () async {
      final c = await containerWith({
        ...londonUnderWay(fixed: Difficulty.rookie),
        // Paris's opening seen (not begun): its record stays as it is.
        seasonKey(SeasonIds.paris): record(const SeasonProgress(activeEpisodeId: 's2_ep01', prologueSeen: true)),
        // A save of another detective's namespace, untouched.
        'lm.p.1111111111111111.progress.v1.ep02': save(solved(london[1])),
      });
      final prefs = c.read(sharedPreferencesProvider);
      final coins = c.read(walletProvider).balance;
      final entries = c.read(walletProvider).entries.length;
      final parisRecord = prefs.getString(seasonKey(SeasonIds.paris));
      final other = prefs.getString('lm.p.1111111111111111.progress.v1.ep02');
      expect(seasonXp(c, london), greaterThan(0));

      c.read(gameControllerProvider.notifier).restartSeason(SeasonIds.london, Difficulty.junior);
      await pumpEventQueue();

      // London: every case save empty (the name kept), its record at Case 01, Junior.
      for (final e in london) {
        final p = GameProgress.fromJson(jsonDecode(prefs.getString(caseKey(e.id))!));
        expect(p.completedMissionIds, isEmpty, reason: e.id);
        expect(p.introSeen, isFalse);
        expect(p.badgeIds, isEmpty);
        expect(p.hintsUsed, isEmpty);
        expect(p.detectiveName, 'KIM');
      }
      final rec = SeasonProgress.fromJson(jsonDecode(prefs.getString(seasonKey(SeasonIds.london))!));
      expect(rec.solvedEpisodeIds, isEmpty);
      expect(rec.activeEpisodeId, 'ep01');
      expect(rec.difficulty, Difficulty.junior);
      expect(c.read(seasonProvider).activeEpisodeId, 'ep01');
      expect(c.read(gameControllerProvider).completedMissionIds, isEmpty);
      // XP and evidence worked out again: none for London now.
      expect(seasonXp(c, london), 0);
      expect(c.read(progressRepositoryProvider).load('ep01').collectedEvidence(london[0]), isEmpty);
      // Kept.
      expect(prefs.getString(seasonKey(SeasonIds.paris)), parisRecord);
      expect(prefs.getString('lm.p.1111111111111111.progress.v1.ep02'), other);
      final p = ProfileStore(prefs).profile!;
      expect((p.id, p.detectiveName, p.avatar, p.difficulty), (id, 'KIM', DetectiveAvatar.girl, Difficulty.junior));
      expect(c.read(walletProvider).balance, coins, reason: 'the coins kept');
      expect(c.read(walletProvider).entries.length, entries, reason: 'every pay was in the record: nothing added');
      expect(c.read(walletProvider).ownsTip('ep03_m1', 2), isTrue, reason: 'the tip bought stays');
      expect(c.read(walletProvider.notifier).unlockTip(london[2].missions.first, 2), TipUnlock.alreadyYours);
      expect(c.read(walletProvider).balance, coins, reason: 'reading the tip bought again costs nothing');
      expect(c.read(seasonLevelProvider(SeasonIds.london))!.level, Difficulty.junior);
      // An app restart reads the same.
      final again = await restarted(prefs);
      expect(again.read(seasonProvider).solvedEpisodeIds, isEmpty);
      expect(again.read(currentDifficultyProvider), Difficulty.junior);
      expect(again.read(walletProvider).balance, coins);
    });

    test('12–13. Paris under way restarted: London\'s complete record, cases, XP and evidence kept', () async {
      final c = await containerWith(parisUnderWay());
      final prefs = c.read(sharedPreferencesProvider);
      final londonXp = seasonXp(c, london);
      final londonKeys = [seasonKey(SeasonIds.london), for (final e in london) caseKey(e.id)];
      final londonBefore = {for (final k in londonKeys) k: prefs.getString(k)};
      c.read(gameControllerProvider.notifier).restartSeason(SeasonIds.paris, Difficulty.master);
      expect({for (final k in londonKeys) k: prefs.getString(k)}, londonBefore);
      expect(seasonXp(c, london), londonXp);
      expect(c.read(seasonLevelProvider(SeasonIds.london))!.status, SeasonLevelStatus.completed);
      expect(c.read(seasonAvailabilityProvider(SeasonIds.paris))!.canEnter, isTrue, reason: 'Paris still open');
      final rec = c.read(seasonProvider);
      expect(rec.solvedEpisodeIds, isEmpty);
      expect(rec.activeEpisodeId, 's2_ep01');
      expect(rec.prologueSeen, isTrue, reason: 'its opening is not shown again');
      expect(rec.difficulty, Difficulty.master);
      expect(seasonXp(c, paris), 0);
      expect(c.read(selectedSeasonIdProvider), SeasonIds.paris);
    });

    test('a season restarted while another is played: what is read of it is fresh', () async {
      // London complete and played (its board); Paris under way: a change of
      // level is about Paris.
      final c = await containerWith({...parisUnderWay(), selectedKey: jsonEncode({'seasonId': SeasonIds.london})});
      expect(c.read(selectedSeasonIdProvider), SeasonIds.london);
      expect(c.read(levelSeasonProvider), SeasonIds.paris);
      expect(c.read(seasonLevelProvider(SeasonIds.paris))!.level, Difficulty.junior);
      c.read(gameControllerProvider.notifier).restartSeason(SeasonIds.paris, Difficulty.master);
      expect(c.read(seasonLevelProvider(SeasonIds.paris))!.level, Difficulty.master);
      expect(c.read(seasonDifficultyProvider(SeasonIds.paris)), Difficulty.master);
      expect(c.read(seasonLevelProvider(SeasonIds.paris))!.fixed, Difficulty.master);
      expect(c.read(seasonProvider).solvedEpisodeIds.length, london.length, reason: 'London played on, as it was');
    });

    test('18. The app stopped half way through a restart: the next start finishes it', () async {
      final seed = londonUnderWay(fixed: Difficulty.rookie);
      // The restart as it runs, to know what it writes.
      final done = await containerWith(seed);
      final donePrefs = done.read(sharedPreferencesProvider);
      final before = {...seed};
      done.read(gameControllerProvider.notifier).restartSeason(SeasonIds.london, Difficulty.master);
      await pumpEventQueue();
      final after = snapshot(donePrefs);
      final writes = <String, String?>{
        for (final k in {...before.keys, ...after.keys})
          if (k.startsWith(AppConstants.profilePrefix(id)) && before[k] != after[k]) k: after[k] as String?,
      };
      expect(writes.keys, containsAll([seasonKey(SeasonIds.london), caseKey('ep01'), caseKey('ep03')]));
      // Stopped after the journal and the first write only.
      final first = writes.entries.first;
      final crashed = <String, Object>{
        ...seed,
        journalKey: jsonEncode({'v': 1, 'writes': writes}),
        if (first.value != null) first.key: first.value!,
      };
      final c = await containerWith(crashed);
      c.read(progressRepositoryProvider); // the next start
      final prefs = c.read(sharedPreferencesProvider);
      expect(prefs.getString(journalKey), isNull, reason: 'finished and put away');
      for (final MapEntry(:key, :value) in writes.entries) {
        expect(prefs.getString(key), value, reason: key);
      }
      expect(c.read(seasonProvider).solvedEpisodeIds, isEmpty);
      expect(c.read(seasonProvider).difficulty, Difficulty.master);
      expect(c.read(walletProvider).balance, done.read(walletProvider).balance);
    });

    test('18. Stopped before the journal was written: nothing of the restart, nothing lost', () async {
      final seed = londonUnderWay(fixed: Difficulty.rookie);
      final c = await containerWith(seed);
      expect(c.read(seasonProvider).solvedEpisodeIds, ['ep01', 'ep02']);
      expect(c.read(seasonProvider).difficulty, Difficulty.rookie);
    });

    test('19. Safe mode: the saves from before profiles never come back after a restart', () async {
      final session = ProfileSession(
        profile: DetectiveProfile(id: id, detectiveName: 'KIM', avatar: DetectiveAvatar.boy),
        legacyFallback: true,
      );
      final legacy = <String, Object>{
        AppConstants.progressStorageKey: save(solved(london[0])),
        AppConstants.progressKeyFor('ep02'): save(const GameProgress(detectiveName: 'KIM', introSeen: true)),
        AppConstants.seasonStorageKey: record(const SeasonProgress(activeEpisodeId: 'ep02', solvedEpisodeIds: ['ep01'])),
      };
      final c = await containerWith(legacy, extra: [profileSessionProvider.overrideWithValue(session)]);
      expect(c.read(seasonLevelProvider(SeasonIds.london))!.status, SeasonLevelStatus.inProgress, reason: 'read from the originals');
      c.read(gameControllerProvider.notifier).restartSeason(SeasonIds.london, Difficulty.junior);
      final prefs = c.read(sharedPreferencesProvider);
      final again = await restarted(prefs, extra: [profileSessionProvider.overrideWithValue(session)]);
      expect(again.read(progressRepositoryProvider).load('ep01').completedMissionIds, isEmpty);
      expect(again.read(progressRepositoryProvider).load('ep02').introSeen, isFalse);
      expect(again.read(seasonProvider).solvedEpisodeIds, isEmpty);
      expect(again.read(seasonProvider).difficulty, Difficulty.junior);
      // The originals themselves are left where they are.
      for (final k in legacy.keys) {
        expect(prefs.getString(k), legacy[k], reason: k);
      }
    });
  });

  group('rewards after a restart', () {
    test('20–22. Played again: no mission and no final pays twice; a mission never solved still pays', () async {
      final c = await containerWith(londonUnderWay(fixed: Difficulty.rookie));
      c.read(gameControllerProvider.notifier).restartSeason(SeasonIds.london, Difficulty.junior);
      final game = c.read(gameControllerProvider.notifier);
      final coins = c.read(walletProvider).balance;
      // Case 01 again, every mission and its final.
      c.read(gameControllerProvider.notifier).startInvestigation();
      for (final m in london[0].allMissions) {
        final out = game.submitAnswer(m, m.answer);
        expect(out.result, SubmitResult.correct, reason: m.id);
        expect(out.coins, 0, reason: '${m.id} was paid before');
      }
      expect(c.read(gameControllerProvider).isCaseSolved, isTrue);
      expect(c.read(walletProvider).balance, coins);
      // Case 03's M2 was never solved: it pays as it always would.
      expect(c.read(walletProvider.notifier).rewardMission(london[2].missions[1]), AppConstants.missionCoins);
      expect(c.read(walletProvider.notifier).rewardMission(london[2].missions[0]), 0, reason: 'M1 was paid');
    });

    test('23–24. A save whose pay is not in the record: marked paid at 0 before the restart, the balance as it was', () async {
      // Cases 01–02 solved, but the wallet only holds the start coins (a
      // wallet made after them): whether they were paid cannot be told.
      final c = await containerWith({
        ...londonUnderWay(fixed: Difficulty.rookie),
        walletKey: wallet(),
      });
      final balance = c.read(walletProvider).balance;
      c.read(gameControllerProvider.notifier).restartSeason(SeasonIds.london, Difficulty.rookie);
      final w = c.read(walletProvider);
      expect(w.balance, balance, reason: 'the balance never changes on a restart');
      for (final e in london.take(2)) {
        for (final m in e.allMissions) {
          expect(w.has(Wallet.missionKey(m.id)), isTrue, reason: m.id);
        }
      }
      expect(w.has(Wallet.missionKey('ep03_m1')), isTrue);
      expect(w.has(Wallet.missionKey('ep03_m2')), isFalse, reason: 'never solved: nothing marked');
      expect(w.balance, w.entries.fold<int>(0, (s, e) => s + e.amount), reason: 'the balance is its record');
      for (final m in london[0].allMissions) {
        expect(c.read(walletProvider.notifier).rewardMission(m), 0, reason: m.id);
      }
      // The record and the coins are saved together with the restart.
      final saved = Wallet.fromJson(jsonDecode(c.read(sharedPreferencesProvider).getString(walletKey)!));
      expect(saved.balance, balance);
      expect(saved.has(Wallet.missionKey(london[0].allMissions.last.id)), isTrue, reason: 'Case 01\'s final marked too');
    });
  });

  group('after London: READY FOR YOUR NEXT MYSTERY?', () {
    test('25. Asked once London is complete and Paris not begun; never after Paris is begun; after Paris, for Rome (Season 3)', () async {
      final c = await containerWith(londonComplete(fixed: Difficulty.junior));
      expect(c.read(nextLevelQuestionProvider)?.season.id, SeasonIds.paris);
      final begun = await containerWith(parisUnderWay());
      expect(begun.read(nextLevelQuestionProvider), isNull, reason: 'Paris played: nothing to ask');
      final parisDone = await containerWith({
        ...parisUnderWay(),
        for (final e in paris) caseKey(e.id): save(solved(e)),
        seasonKey(SeasonIds.paris): record(SeasonProgress(activeEpisodeId: 's2_ep12', solvedEpisodeIds: [for (final e in paris) e.id], difficulty: Difficulty.junior)),
      });
      expect(parisDone.read(selectedSeasonIdProvider), SeasonIds.paris);
      expect(parisDone.read(seasonLevelProvider(SeasonIds.paris))!.status, SeasonLevelStatus.completed);
      // Rome is the season after Paris since the Rome integration: asked as Paris was after London.
      expect(parisDone.read(nextLevelQuestionProvider)?.season.id, SeasonIds.rome, reason: 'Rome follows Paris');
    });

    test('26, 28–29. KEEP MY LEVEL: not asked again (after a restart too); London\'s level as it was', () async {
      final c = await containerWith(londonComplete(fixed: Difficulty.junior));
      await c.read(gameControllerProvider.notifier).answerNextLevel(null);
      expect(c.read(nextLevelQuestionProvider), isNull);
      expect(c.read(detectiveProfileProvider).difficulty, Difficulty.rookie);
      expect(c.read(seasonDifficultyProvider(SeasonIds.london)), Difficulty.junior);
      final again = await restarted(c.read(sharedPreferencesProvider));
      expect(again.read(nextLevelQuestionProvider), isNull);
      expect(again.read(seasonProvider).solvedEpisodeIds.length, london.length, reason: 'the record otherwise as it was');
    });

    test('27–28. CHANGE LEVEL to Master: Paris will start as Master; London stays Junior; nothing of Paris saved', () async {
      final c = await containerWith(londonComplete(fixed: Difficulty.junior));
      final prefs = c.read(sharedPreferencesProvider);
      await c.read(gameControllerProvider.notifier).answerNextLevel(Difficulty.master);
      expect(c.read(detectiveProfileProvider).difficulty, Difficulty.master);
      expect(c.read(seasonDifficultyProvider(SeasonIds.london)), Difficulty.junior);
      expect(c.read(seasonDifficultyProvider(SeasonIds.paris)), Difficulty.master);
      expect(prefs.getString(seasonKey(SeasonIds.paris)), isNull, reason: 'Paris not begun: nothing written for it');
      expect(c.read(nextLevelQuestionProvider), isNull);
    });

    test('a record from before the question existed reads as not asked, and keeps its shape until answered', () async {
      final c = await containerWith(londonComplete());
      final prefs = c.read(sharedPreferencesProvider);
      final before = prefs.getString(seasonKey(SeasonIds.london));
      expect(c.read(nextLevelQuestionProvider), isNotNull);
      expect(prefs.getString(seasonKey(SeasonIds.london)), before);
      await c.read(gameControllerProvider.notifier).answerNextLevel(null);
      expect(jsonDecode(prefs.getString(seasonKey(SeasonIds.london))!), {...jsonDecode(before!) as Map, 'nextLevelAsked': true});
    });
  });

  group('on screen', () {
    late WidgetRef ref;

    Future<SharedPreferences> pumpApp(WidgetTester t, Map<String, Object> prefs, {Size size = const Size(390, 844)}) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: prefs),
        child: RepaintBoundary(
          key: const ValueKey('shot'),
          child: Consumer(builder: (context, r, _) {
            ref = r;
            return const WorldMysteryApp();
          }),
        ),
      ));
      await wait(t, const Duration(milliseconds: 300));
      return SharedPreferences.getInstance();
    }

    // With `LM_SCREENSHOTS` set to a folder: the page as it is, to look at.
    Future<void> capture(WidgetTester t, String name) async {
      final shots = Platform.environment['LM_SCREENSHOTS'];
      if (shots == null) return;
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
      await t.pump();
      await t.runAsync(() async {
        final image = await t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot'))).toImage(pixelRatio: 1.5);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
      });
    }

    String path() => ref.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

    Future<void> openSettings(WidgetTester t) async {
      ref.read(routerProvider).go(Routes.detective);
      await wait(t, const Duration(milliseconds: 600));
    }

    Future<void> tapLevel(WidgetTester t, Difficulty d) async {
      final card = find.byKey(ValueKey('difficulty-${d.storageId}'));
      await reveal(t, card);
      await t.tap(card);
      await wait(t, const Duration(milliseconds: 500));
    }

    for (final size in const [Size(360, 640), Size(390, 844)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('9. $tag London under way, another level: asked; KEEP MY LEVEL changes nothing', (t) async {
        final prefs = await pumpApp(t, londonUnderWay(fixed: Difficulty.rookie), size: size);
        final before = snapshot(prefs);
        await openSettings(t);
        await tapLevel(t, Difficulty.master);
        expect(find.byKey(const ValueKey('restart-season-dialog')), findsOneWidget);
        expect(find.textContaining('Changing your level will restart your current season.'), findsOneWidget);
        expect(t.takeException(), isNull);
        await capture(t, 'restart_dialog_$tag');
        for (final label in ['KEEP MY LEVEL', 'RESTART SEASON']) {
          expect(find.text(label).hitTestable(), findsOneWidget, reason: '$label on screen');
        }
        await tapText(t, 'KEEP MY LEVEL', after: const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('restart-season-dialog')), findsNothing);
        expect(snapshot(prefs), before, reason: 'nothing written');
        final rookie = t.getSemantics(find.byKey(const ValueKey('difficulty-rookie')));
        expect(rookie.flagsCollection.isSelected.toString(), contains('isTrue'), reason: 'still Rookie');
        await wait(t, const Duration(seconds: 2));
      });
    }

    testWidgets('9. Put away without an answer (tap outside): the level kept', (t) async {
      final prefs = await pumpApp(t, londonUnderWay(fixed: Difficulty.rookie));
      final before = snapshot(prefs);
      await openSettings(t);
      await tapLevel(t, Difficulty.junior);
      await t.tapAt(const Offset(8, 8));
      await wait(t, const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('restart-season-dialog')), findsNothing);
      expect(snapshot(prefs), before);
      await wait(t, const Duration(seconds: 2));
    });

    testWidgets('10. RESTART SEASON: London from its Case 01 at the new level, on to its page', (t) async {
      final prefs = await pumpApp(t, londonUnderWay(fixed: Difficulty.rookie));
      final coins = ref.read(walletProvider).balance;
      await openSettings(t);
      await tapLevel(t, Difficulty.master);
      await tapText(t, 'RESTART SEASON', after: const Duration(milliseconds: 1200));
      expect(path(), Routes.season);
      expect(ref.read(seasonProvider).solvedEpisodeIds, isEmpty);
      expect(ref.read(seasonProvider).difficulty, Difficulty.master);
      expect(ProfileStore(prefs).profile!.difficulty, Difficulty.master);
      expect(ref.read(walletProvider).balance, coins);
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('London complete, Paris not begun: the settings change the level for Paris freely', (t) async {
      final prefs = await pumpApp(t, londonComplete(fixed: Difficulty.junior));
      await openSettings(t);
      await tapLevel(t, Difficulty.master);
      expect(find.byKey(const ValueKey('restart-season-dialog')), findsNothing);
      await tapText(t, 'SAVE CHANGES', after: const Duration(milliseconds: 900));
      expect(ProfileStore(prefs).profile!.difficulty, Difficulty.master);
      expect(ref.read(seasonDifficultyProvider(SeasonIds.london)), Difficulty.junior, reason: 'London keeps its own');
      await wait(t, const Duration(seconds: 3));
    });

    Future<void> openReport(WidgetTester t) async {
      ref.read(routerProvider).go(Routes.solved);
      await wait(t, const Duration(milliseconds: 3200));
      await reveal(t, find.byKey(const ValueKey('go-to-next-season')));
    }

    for (final size in const [Size(360, 640), Size(390, 844)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';
      testWidgets('25–27. $tag London\'s last report: READY FOR YOUR NEXT MYSTERY? → CHANGE LEVEL → Master; then GO TO PARIS', (t) async {
        final prefs = await pumpApp(t, londonComplete(fixed: Difficulty.rookie), size: size);
        await openReport(t);
        expect(t.takeException(), isNull);
        expect(find.text('READY FOR YOUR NEXT MYSTERY?'), findsOneWidget);
        expect(find.text('You can keep your level or choose a new one for Paris.'), findsOneWidget);
        expect(find.text('Your level: ROOKIE'), findsOneWidget);
        expect(find.byKey(const ValueKey('go-to-next-season')), findsOneWidget, reason: 'GO TO PARIS still there');
        await capture(t, 'next_level_question_$tag');
        await tapText(t, 'CHANGE LEVEL', after: const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('choose-level-dialog')), findsOneWidget);
        expect(t.takeException(), isNull);
        await capture(t, 'choose_level_dialog_$tag');
        await tapLevel(t, Difficulty.master);
        await tapText(t, 'CHOOSE MASTER', after: const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('choose-level-dialog')), findsNothing);
        expect(ProfileStore(prefs).profile!.difficulty, Difficulty.master);
        expect(find.text('READY FOR YOUR NEXT MYSTERY?'), findsNothing, reason: 'answered: not asked again');
        expect(ref.read(seasonDifficultyProvider(SeasonIds.london)), Difficulty.rookie, reason: 'London kept');
        await wait(t, const Duration(seconds: 2));
        await reveal(t, find.byKey(const ValueKey('go-to-next-season')));
        await t.tap(find.byKey(const ValueKey('go-to-next-season')));
        await wait(t, const Duration(milliseconds: 1600));
        expect(path(), Routes.seasonOf(SeasonIds.paris));
        expect(ref.read(seasonDifficultyProvider(SeasonIds.paris)), Difficulty.master);
        expect(ref.read(seasonProvider).difficulty, isNull, reason: 'fixed at its Case 01 intro, not before');
        await wait(t, const Duration(seconds: 3));
      });
    }

    testWidgets('26, 29, 31. KEEP MY LEVEL: the question goes; GO TO PARIS works; London\'s report again does not ask', (t) async {
      final prefs = await pumpApp(t, londonComplete(fixed: Difficulty.junior));
      await openReport(t);
      await tapText(t, 'KEEP MY LEVEL', after: const Duration(milliseconds: 600));
      expect(find.text('READY FOR YOUR NEXT MYSTERY?'), findsNothing);
      expect(ProfileStore(prefs).profile!.difficulty, Difficulty.rookie);
      expect(SeasonProgress.fromJson(jsonDecode(prefs.getString(seasonKey(SeasonIds.london))!)).nextLevelAsked, isTrue);
      ref.read(routerProvider).go(Routes.season);
      await wait(t, const Duration(milliseconds: 600));
      await openReport(t);
      expect(find.text('READY FOR YOUR NEXT MYSTERY?'), findsNothing, reason: 'not asked again');
      await t.tap(find.byKey(const ValueKey('go-to-next-season')));
      await wait(t, const Duration(milliseconds: 1600));
      expect(path(), Routes.seasonOf(SeasonIds.paris));
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('31. GO TO PARIS without answering: on to Paris, as before', (t) async {
      await pumpApp(t, londonComplete(fixed: Difficulty.junior));
      await openReport(t);
      expect(find.text('READY FOR YOUR NEXT MYSTERY?'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('go-to-next-season')));
      await wait(t, const Duration(milliseconds: 1600));
      expect(path(), Routes.seasonOf(SeasonIds.paris));
      expect(ref.read(selectedSeasonIdProvider), SeasonIds.paris);
      await wait(t, const Duration(seconds: 3));
    });
  });
}
