import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/data/models/difficulty.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/data/repositories/progress_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Difficulty PART 1: the level's model, the detective's level and each
/// season's fixed level — saved, read back, and read from saves made before
/// difficulty existed (see docs/DIFFICULTY_IMPLEMENTATION.md).

const id = 'abcdef0123456789abcdef0123456789';

/// A detective record as the builds before difficulty saved it.
Map<String, Object?> oldProfileJson({Object? difficulty = _absent}) => {
      'id': id,
      'origin': 'legacy',
      'walletBackfill': 'done',
      'detectiveName': 'KIM',
      'avatar': 'girl',
      'createdAt': '2026-09-01T10:00:00.000',
      if (!identical(difficulty, _absent)) 'difficulty': difficulty,
    };

const _absent = Object();

String recordJson(Map<String, Object?> profile, {List<String> held = const []}) =>
    jsonEncode({'schema': 1, 'profile': profile, if (held.isNotEmpty) 'held': held});

String key(String legacyKey) => AppConstants.profileKey(id, legacyKey);

final londonKey = key(AppConstants.seasonKeyFor(SeasonIds.london));
final parisKey = key(AppConstants.seasonKeyFor(SeasonIds.paris));

/// Season 1's record as the builds before difficulty saved it.
const oldLondon = {
  'activeEpisodeId': 'ep03',
  'solvedEpisodeIds': ['ep01', 'ep02'],
  'prologueSeen': true,
};

Map<String, Object?> snapshot(SharedPreferences p) => {for (final k in p.getKeys()) k: p.get(k)};

Future<ProviderContainer> containerWith(Map<String, Object> prefs) async {
  final c = ProviderContainer(overrides: await testOverrides(prefs: prefs));
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('Difficulty', () {
    test('three levels, rookie the standard; saved ids stable and apart from the words on screen', () {
      expect(Difficulty.values, [Difficulty.rookie, Difficulty.junior, Difficulty.master]);
      expect(Difficulty.standard, Difficulty.rookie);
      expect([for (final d in Difficulty.values) d.storageId], ['rookie', 'junior', 'master']);
      expect([for (final d in Difficulty.values) d.label], ['ROOKIE', 'JUNIOR', 'MASTER']);
    });

    test('every level reads back from its id', () {
      for (final d in Difficulty.values) {
        expect(Difficulty.parse(d.storageId), d);
        expect(Difficulty.tryParse(d.storageId), d);
      }
    });

    test('missing, null, unknown or malformed ids: rookie (tryParse: none)', () {
      for (final bad in <Object?>[null, '', 'expert', 'Rookie', 'MASTER', 'ROOKIE', 2, true, const ['junior'], const {'d': 'master'}]) {
        expect(Difficulty.parse(bad), Difficulty.rookie, reason: '$bad');
        expect(Difficulty.tryParse(bad), isNull, reason: '$bad');
      }
    });
  });

  group('the detective\'s level (lm.detective.v1)', () {
    test('a profile saved before difficulty reads as rookie; nothing else changes', () {
      final p = DetectiveProfile.fromJson(oldProfileJson())!;
      expect(p.difficulty, Difficulty.rookie);
      expect(p.id, id);
      expect(p.detectiveName, 'KIM');
      expect(p.avatar, DetectiveAvatar.girl);
      expect(p.origin, ProfileOrigin.legacy);
      expect(p.walletBackfill, WalletBackfill.done);
      expect(p.createdAt, DateTime(2026, 9, 1, 10));
    });

    test('rookie, junior and master read back as saved', () {
      for (final d in Difficulty.values) {
        expect(DetectiveProfile.fromJson(oldProfileJson(difficulty: d.storageId))!.difficulty, d);
      }
    });

    test('an unknown level reads as rookie; the profile still reads', () {
      for (final bad in <Object?>['expert', null, 3]) {
        final p = DetectiveProfile.fromJson(oldProfileJson(difficulty: bad));
        expect(p, isNotNull);
        expect(p!.difficulty, Difficulty.rookie);
        expect(p.detectiveName, 'KIM');
      }
    });

    test('saved again: every earlier field kept, the level written by its id', () {
      final again = DetectiveProfile.fromJson(oldProfileJson())!.toJson();
      expect(again, {...oldProfileJson(), 'difficulty': 'rookie'});
      final master = DetectiveProfile.fromJson(oldProfileJson(difficulty: 'master'))!.toJson();
      expect(master['difficulty'], 'master');
    });

    test('saved and read back many times: the same record', () {
      final first = DetectiveRecord.fromJson(jsonDecode(recordJson(oldProfileJson(difficulty: 'junior'), held: ['1234567890abcdef'])))!;
      var json = jsonEncode(first.toJson());
      for (var i = 0; i < 5; i++) {
        json = jsonEncode(DetectiveRecord.fromJson(jsonDecode(json))!.toJson());
      }
      expect(json, jsonEncode(first.toJson()));
      final back = DetectiveRecord.fromJson(jsonDecode(json))!;
      expect(back.profile.difficulty, Difficulty.junior);
      expect(back.held, ['1234567890abcdef']);
    });

    test('copyWith changes the level only; a reset slot is back to rookie', () {
      final p = DetectiveProfile.fromJson(oldProfileJson())!;
      final m = p.copyWith(difficulty: Difficulty.master);
      expect(m.difficulty, Difficulty.master);
      expect(m.toJson()..remove('difficulty'), p.toJson()..remove('difficulty'));
      expect(m.copyWith(detectiveName: 'LEE').difficulty, Difficulty.master, reason: 'other changes keep the level');
      expect(m.startedOver().difficulty, Difficulty.rookie);
    });

    test('setDifficulty saves the level; id, name, picture and the rest stay', () async {
      final c = await containerWith({AppConstants.detectiveStorageKey: recordJson(oldProfileJson(), held: ['1234567890abcdef'])});
      final prefs = c.read(sharedPreferencesProvider);
      expect(c.read(detectiveProfileProvider).difficulty, Difficulty.rookie);

      await c.read(detectiveProfileProvider.notifier).setDifficulty(Difficulty.junior);

      expect(c.read(detectiveProfileProvider).difficulty, Difficulty.junior);
      final saved = ProfileStore(prefs).read()!;
      expect(saved.profile.difficulty, Difficulty.junior);
      expect(saved.profile.toJson()..remove('difficulty'), DetectiveProfile.fromJson(oldProfileJson())!.toJson()..remove('difficulty'));
      expect(saved.held, ['1234567890abcdef']);

      // An app restart reads it back.
      final again = ProviderContainer(overrides: await testOverridesFor(prefs));
      addTearDown(again.dispose);
      expect(again.read(detectiveProfileProvider).difficulty, Difficulty.junior);
      expect(again.read(detectiveProfileProvider).detectiveName, 'KIM');
    });

    test('a new detective is rookie unless created with a level', () async {
      final c = await containerWith({});
      expect(c.read(gameControllerProvider.notifier).createDetective('Anna', DetectiveAvatar.girl), isNull);
      expect(c.read(detectiveProfileProvider).difficulty, Difficulty.rookie);
      expect(ProfileStore(c.read(sharedPreferencesProvider)).profile!.difficulty, Difficulty.rookie);

      final m = await containerWith({});
      expect(m.read(gameControllerProvider.notifier).createDetective('Ben', DetectiveAvatar.boy, difficulty: Difficulty.master), isNull);
      await pumpEventQueue();
      final saved = ProfileStore(m.read(sharedPreferencesProvider)).profile!;
      expect(saved.difficulty, Difficulty.master);
      expect(saved.detectiveName, 'Ben');
      expect(saved.avatar, DetectiveAvatar.boy);
    });

    test('NEW ADVENTURE keeps the detective\'s level (as its name and picture)', () async {
      final c = await containerWith({AppConstants.detectiveStorageKey: recordJson(oldProfileJson(difficulty: 'master'))});
      await c.read(gameControllerProvider.notifier).newAdventure();
      expect(c.read(detectiveProfileProvider).difficulty, Difficulty.master);
      expect(ProfileStore(c.read(sharedPreferencesProvider)).profile!.difficulty, Difficulty.master);
    });
  });

  group('each season\'s fixed level (season.v1[.<seasonId>])', () {
    test('a record saved before difficulty: not fixed, and saved again in its old shape', () {
      final s = SeasonProgress.fromJson(Map<String, dynamic>.from(oldLondon));
      expect(s.difficulty, isNull);
      expect(s.activeEpisodeId, 'ep03');
      expect(s.solvedEpisodeIds, ['ep01', 'ep02']);
      expect(s.prologueSeen, isTrue);
      expect(s.toJson(), oldLondon, reason: 'no difficulty key until one is fixed');
    });

    test('fixed levels read back; unknown ones read as not fixed', () {
      for (final d in Difficulty.values) {
        final s = SeasonProgress.fromJson({...oldLondon, 'difficulty': d.storageId});
        expect(s.difficulty, d);
        expect(s.toJson(), {...oldLondon, 'difficulty': d.storageId});
      }
      expect(SeasonProgress.fromJson({...oldLondon, 'difficulty': 'expert'}).difficulty, isNull);
      expect(SeasonProgress.fromJson({...oldLondon, 'difficulty': null}).difficulty, isNull);
    });

    test('the season\'s level: its own when fixed, else the detective\'s', () {
      const open = SeasonProgress();
      expect(open.difficultyOr(Difficulty.junior), Difficulty.junior);
      final fixed = open.copyWith(difficulty: Difficulty.master);
      expect(fixed.difficultyOr(Difficulty.rookie), Difficulty.master);
      expect(fixed.copyWith(activeEpisodeId: 'ep02').difficulty, Difficulty.master, reason: 'other changes keep it');
      expect(fixed.markSolved('ep01').difficulty, Difficulty.master);
    });

    test('saved and loaded many times through the repository: the same record', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = SharedPrefsProgressRepository(await SharedPreferences.getInstance(), profileId: id);
      final record = SeasonProgress.fromJson({...oldLondon, 'difficulty': 'junior'});
      await repo.saveSeason(record, SeasonIds.london);
      for (var i = 0; i < 5; i++) {
        await repo.saveSeason(repo.loadSeason(SeasonIds.london), SeasonIds.london);
      }
      expect(repo.loadSeason(SeasonIds.london).toJson(), record.toJson());
    });

    test('London and Paris keep their own levels', () async {
      final c = await containerWith({
        AppConstants.detectiveStorageKey: recordJson(oldProfileJson(difficulty: 'rookie')),
        londonKey: jsonEncode({...oldLondon, 'difficulty': 'junior'}),
        parisKey: jsonEncode({'activeEpisodeId': 's2_ep02', 'solvedEpisodeIds': ['s2_ep01'], 'difficulty': 'master'}),
      });
      expect(c.read(seasonDifficultyProvider(SeasonIds.london)), Difficulty.junior);
      expect(c.read(seasonDifficultyProvider(SeasonIds.paris)), Difficulty.master);
      expect(c.read(selectedSeasonIdProvider), SeasonIds.london);
      expect(c.read(currentDifficultyProvider), Difficulty.junior);

      // Fixing London again leaves Paris's record as it is.
      final parisBefore = c.read(sharedPreferencesProvider).getString(parisKey);
      c.read(seasonProvider.notifier).fixDifficulty(Difficulty.rookie);
      expect(c.read(seasonDifficultyProvider(SeasonIds.london)), Difficulty.rookie);
      expect(c.read(seasonDifficultyProvider(SeasonIds.paris)), Difficulty.master);
      expect(c.read(sharedPreferencesProvider).getString(parisKey), parisBefore);
    });

    // PART 3 (approved policy 4): a season played before levels existed is
    // under way at the standard level, whatever the detective's level is; a
    // season not begun follows the detective's; a fixed one keeps its own.
    test('a season not begun follows the detective\'s; one played before levels is Rookie; a fixed one keeps its own', () async {
      final c = await containerWith({
        AppConstants.detectiveStorageKey: recordJson(oldProfileJson()),
        londonKey: jsonEncode(oldLondon),
      });
      expect(c.read(currentDifficultyProvider), Difficulty.rookie, reason: 'old saves: rookie');
      expect(c.read(seasonDifficultyProvider(SeasonIds.paris)), Difficulty.rookie);

      await c.read(detectiveProfileProvider.notifier).setDifficulty(Difficulty.junior);
      expect(c.read(currentDifficultyProvider), Difficulty.rookie, reason: 'London was played (cases solved): Rookie');
      expect(c.read(seasonDifficultyProvider(SeasonIds.paris)), Difficulty.junior, reason: 'Paris not begun: the detective\'s');

      c.read(seasonProvider.notifier).fixDifficulty(Difficulty.junior);
      await c.read(detectiveProfileProvider.notifier).setDifficulty(Difficulty.master);
      expect(c.read(currentDifficultyProvider), Difficulty.junior, reason: 'fixed: the profile changing leaves it');
      expect(c.read(seasonDifficultyProvider(SeasonIds.paris)), Difficulty.master, reason: 'Paris not fixed');

      // An app restart reads the same.
      final again = ProviderContainer(overrides: await testOverridesFor(c.read(sharedPreferencesProvider)));
      addTearDown(again.dispose);
      expect(again.read(currentDifficultyProvider), Difficulty.junior);
      expect(again.read(detectiveProfileProvider).difficulty, Difficulty.master);
      expect(again.read(seasonProvider).toJson(), {...oldLondon, 'difficulty': 'junior'});
    });

    test('fixing a level keeps the season\'s progress, solved cases and unlocks', () async {
      final c = await containerWith({
        AppConstants.detectiveStorageKey: recordJson(oldProfileJson()),
        londonKey: jsonEncode(oldLondon),
      });
      final season = c.read(seasonProvider.notifier);
      final unlockedBefore = [for (final e in c.read(episodeCatalogProvider)) season.isUnlocked(e.id)];
      season.fixDifficulty(Difficulty.master);
      final s = c.read(seasonProvider);
      expect(s.activeEpisodeId, 'ep03');
      expect(s.solvedEpisodeIds, ['ep01', 'ep02']);
      expect(s.prologueSeen, isTrue);
      expect([for (final e in c.read(episodeCatalogProvider)) season.isUnlocked(e.id)], unlockedBefore);
      expect(jsonDecode(c.read(sharedPreferencesProvider).getString(londonKey)!), {...oldLondon, 'difficulty': 'master'});
    });

    test('asking for a level never saves anything', () async {
      final c = await containerWith({
        AppConstants.detectiveStorageKey: recordJson(oldProfileJson()),
        londonKey: jsonEncode(oldLondon),
        key(AppConstants.progressKeyFor('ep03')): jsonEncode(const GameProgress(detectiveName: 'KIM', introSeen: true).toJson()),
      });
      final prefs = c.read(sharedPreferencesProvider);
      final before = snapshot(prefs);
      for (var i = 0; i < 3; i++) {
        c.read(currentDifficultyProvider);
        c.read(seasonDifficultyProvider(SeasonIds.london));
        c.read(seasonDifficultyProvider(SeasonIds.paris));
        c.read(seasonProvider).difficultyOr(c.read(detectiveProfileProvider).difficulty);
      }
      expect(snapshot(prefs), before);
      expect(prefs.getString(parisKey), isNull, reason: 'no record made for a season only asked about');
    });

    test('fixing the level it already has writes nothing', () async {
      final c = await containerWith({
        AppConstants.detectiveStorageKey: recordJson(oldProfileJson()),
        londonKey: jsonEncode({...oldLondon, 'difficulty': 'junior'}),
      });
      final prefs = c.read(sharedPreferencesProvider);
      final before = snapshot(prefs);
      c.read(seasonProvider.notifier).fixDifficulty(Difficulty.junior);
      expect(snapshot(prefs), before);
    });
  });
}
