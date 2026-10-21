import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/mock/season1/episode02_mock.dart';
import 'package:london_mystery/data/mock/season1/season1_explores.dart';
import 'package:london_mystery/data/mock/season1/season1_learning.dart';
import 'package:london_mystery/data/mock/season2/season2_learning.dart';
import 'package:london_mystery/data/mock/season_catalog.dart';
import 'package:london_mystery/data/models/discovery.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/models/wallet.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/mission_map/map_world.dart';
import 'package:london_mystery/features/mission_map/mission_map_screen.dart';
import 'package:london_mystery/widgets/place_scenery.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/place_art.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';

/// A stand-in Paris case for these tests only (Season 2 has only its Case 01
/// in the game): Case 02's content under Season 2's ids. Never Case 01, the
/// real one.
Episode parisCase(int n) {
  assert(n > 1, 'Paris Case 01 is in the game');
  final id = 's2_ep${n.toString().padLeft(2, '0')}';
  final text = jsonEncode(episode02Json).replaceAll('"ep02_', '"${id}_').replaceAll('"ep02"', '"$id"');
  return Episode.fromJson({...jsonDecode(text) as Map<String, dynamic>, 'number': n, 'seasonId': SeasonIds.paris});
}

/// The game as bundled: Season 1, and Paris's Case 01 with its Case 02
/// after it (in the game since its pictures came in; before, a stand-in
/// Case 02 stood here).
final withParis = MockEpisodeRepository.bundled();

/// Every season played as if released. Season 2 is not released yet (only an
/// operator build's season preview plays it: see `paris_case01_test.dart`);
/// these tests check the rules a released season follows.
final asReleased = seasonReleasedProvider.overrideWithValue((_) => true);


/// The game's maps, Paris's included (a season is entered only with its map).
const withParisMap = SeasonMap.bySeason;

/// The maps as if Paris's were missing: a season with cases but no map.
const londonOnlyMaps = {SeasonIds.london: SeasonMap.london};

final season1Ids = [for (var i = 1; i <= 12; i++) 'ep${i.toString().padLeft(2, '0')}'];

/// Season 1's record with Case 12 solved (Season 2 unlocks).
final season1Finished = SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: season1Ids);

/// The asset an image shows (through a decode-size wrapper too), or null.
String? assetOf(ImageProvider image) => switch (image) {
  AssetImage(:final assetName) => assetName,
  ResizeImage(:final imageProvider) => assetOf(imageProvider),
  _ => null,
};

/// Whether the London map artwork is on screen.
bool showsLondon() =>
    find.byWidgetPredicate((w) => w is Image && assetOf(w.image) == ArtAssets.londonMap).evaluate().isNotEmpty;

void main() {
  late ProviderContainer container;
  late SharedPreferences prefs;
  GameController ctrl() => container.read(gameControllerProvider.notifier);
  GameProgress state() => container.read(gameControllerProvider);
  Episode current() => container.read(currentEpisodeProvider);
  SeasonAvailability paris() => container.read(seasonAvailabilityProvider(SeasonIds.paris))!;

  /// A container on [prefs] (a restart when it is the same storage). With
  /// [episodes] (a stand-in Paris case), Paris is played as released and has
  /// its map unless [maps] says otherwise. Without, the game as it ships:
  /// Paris not released.
  Future<ProviderContainer> open({List<Episode>? episodes, Map<String, SeasonMap>? maps, bool parisUnreleased = false}) async => ProviderContainer(
    overrides: [
      ...await testOverridesFor(prefs),
      if (parisUnreleased) parisNotYetReleased,
      if (episodes != null) ...[allEpisodesProvider.overrideWithValue(episodes), asReleased],
      if (maps != null || episodes != null) seasonMapsProvider.overrideWithValue(maps ?? withParisMap),
    ],
  );

  /// Writes [record] as Season 1's saved record (the detective's own key).
  void saveSeason1(SeasonProgress record) =>
      prefs.setString(savedKey(prefs, AppConstants.seasonStorageKey), jsonEncode(record.toJson()));

  void solveCurrentCase() {
    final e = current();
    ctrl().startInvestigation();
    for (final m in e.allMissions) {
      ctrl().markMissionStarted(m.id);
      expect(ctrl().submitAnswer(m, m.answer).result, SubmitResult.correct, reason: m.id);
    }
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    container = await open();
  });
  tearDown(() => container.dispose());

  group('season ids and content', () {
    test('Season 1 keeps its cases, ids and content; Season 2 has its Cases 01 to 03, released', () {
      final seasons = container.read(seasonsProvider);
      expect([for (final s in seasons) s.id], [SeasonIds.london, SeasonIds.paris]);
      expect(seasons.first.title, 'Shadows over London');
      expect(seasons.first.label, 'SEASON ONE');
      expect(seasons.last.title, 'Paris Stands Still');
      expect(seasons.last.tagline, 'ONE STOLEN HOUR');
      expect(seasons.last.label, 'SEASON TWO');

      // Season 1 is what is played; its catalog is the twelve cases as before.
      expect(container.read(selectedSeasonIdProvider), SeasonIds.london);
      expect(container.read(seasonInfoProvider).id, SeasonIds.london);
      expect([for (final e in container.read(episodeCatalogProvider)) e.id], season1Ids);
      expect(container.read(episodeCatalogProvider).every((e) => e.seasonId == SeasonIds.london), isTrue);
      expect(SeasonCatalog.byId(SeasonIds.paris)!.episodes.keys, ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04']);
      // Paris is out for players (2026-10-21): it opens by the season rule.
      expect(SeasonCatalog.byId(SeasonIds.paris)!.released, isTrue);
      expect(SeasonCatalog.byId(SeasonIds.london)!.released, isTrue);
    });

    test('a case says its season; Season 1 content without one is Season 1', () {
      final ep01 = MockEpisodeRepository.bundled().first;
      expect(ep01.seasonId, SeasonIds.london);
      expect(ep01.toJson().containsKey('seasonId'), isFalse, reason: 'Season 1 content is unchanged');
      final p = parisCase(3);
      expect(p.seasonId, SeasonIds.paris);
      expect(Episode.fromJson(p.toJson()).seasonId, SeasonIds.paris);
      expect(Season.fromJson(const {'number': 1, 'title': 'x', 'tagline': 'y'}).id, SeasonIds.london);
    });

    test('every season orders its own cases from 01, season by season', () {
      final ordered = MockEpisodeRepository.inPlayOrder([parisCase(5), ...MockEpisodeRepository.bundled()]);
      expect([for (final e in ordered) e.id], [...season1Ids, 's2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05']);
    });

    test('mission ids are never shared between seasons, so no reward is paid twice', () {
      final ids = [for (final e in withParis) for (final m in e.allMissions) m.id];
      expect(ids.toSet(), hasLength(ids.length), reason: 'a coin key is mission:<id>');
      final paris = [for (final e in withParis.where((e) => e.seasonId == SeasonIds.paris)) ...e.allMissions];
      final pattern = RegExp(r'^s2_ep\d{2}_(m\d|final)$');
      for (final m in paris) {
        expect(pattern.hasMatch(m.id), isTrue, reason: m.id);
      }
      expect(paris.first.id, 's2_ep01_m1');
      expect(paris.firstWhere((m) => m.isFinal).id, 's2_ep01_final');
      // The bundled seasons never share a case or a mission id.
      final bundledCases = [for (final s in SeasonCatalog.all) ...s.episodes.keys];
      expect(bundledCases.toSet(), hasLength(bundledCases.length));
      final bundledMissions = [for (final e in MockEpisodeRepository.bundled()) for (final m in e.allMissions) m.id];
      expect(bundledMissions.toSet(), hasLength(bundledMissions.length));
      // Every bundled season's own cases say their season and follow its ids.
      for (final season in SeasonCatalog.all) {
        for (final json in season.episodes.values) {
          final e = Episode.fromJson(json);
          expect(e.seasonId, season.id, reason: e.id);
          if (season.id == SeasonIds.paris) expect(RegExp(r'^s2_ep\d{2}$').hasMatch(e.id), isTrue, reason: e.id);
        }
      }
    });

    test('a mission\'s content is found in its own season only', () {
      final ep01 = MockEpisodeRepository.bundled().first;
      final m01 = ep01.missionById('m01')!;
      expect(SeasonCatalog.ofMission('m01')!.id, SeasonIds.london);
      expect(SeasonCatalog.explore(m01), same(season1Explores['m01']));
      expect(SeasonCatalog.languageTopic('ep01'), same(season1LanguageTopics['ep01']));
      for (final e in season1Cases()) {
        for (final m in e.allMissions) {
          expect(SeasonCatalog.learning(m), same(season1Learning[m.id]), reason: m.id);
        }
      }
      // Paris's Case 01: its own season's notes.
      final s2m1 = MockEpisodeRepository.bundled().firstWhere((e) => e.id == 's2_ep01').missions.first;
      expect(SeasonCatalog.ofMission(s2m1.id)!.id, SeasonIds.paris);
      expect(SeasonCatalog.learning(s2m1), same(season2Learning[s2m1.id]));
      expect(SeasonCatalog.languageTopic('s2_ep01'), same(season2LanguageTopics['s2_ep01']));
      // Paris's Case 02: its own season's notes.
      expect(SeasonCatalog.ofMission('s2_ep02_m1')!.id, SeasonIds.paris);
      expect(SeasonCatalog.languageTopic('s2_ep02'), same(season2LanguageTopics['s2_ep02']));
      // A mission no season has (a stand-in Paris mission, of a case not
      // written yet): no scene, the plain Discovery Moment, no learning note.
      final paris = parisCase(12).missions.first;
      expect(SeasonCatalog.ofMission(paris.id), isNull);
      expect(SeasonCatalog.explore(paris), isNull);
      expect(SeasonCatalog.dialogue(paris), isNull);
      expect(SeasonCatalog.learning(paris), isNull);
      expect(SeasonCatalog.discovery(paris).type, Discovery.fallback(paris).type);
      expect(SeasonCatalog.byId('s9_nowhere'), isNull);
      expect(SeasonCatalog.languageTopic('s2_ep12'), isNull);
    });
  });

  group('season saves', () {
    test('a Season 1 save keeps its keys; Season 2 has its own, written only when played', () async {
      ctrl().createDetective('Kim', DetectiveAvatar.girl);
      solveCurrentCase();
      final s1Key = savedKey(prefs, AppConstants.seasonStorageKey);
      expect(s1Key, endsWith('.season.v1'), reason: 'Season 1 keeps the key it always had');
      final s1Saved = prefs.getString(s1Key);
      expect(s1Saved, isNotNull);

      // Reading Season 2 makes no save of it: its record starts empty.
      expect(paris().solvedCount, 0);
      final s2Key = savedKey(prefs, AppConstants.seasonKeyFor(SeasonIds.paris));
      expect(s2Key, endsWith('.season.v1.s2_paris'));
      expect(prefs.getString(s2Key), isNull);
      expect(prefs.getString(savedKey(prefs, AppConstants.selectedSeasonKey)), isNull);
      expect(prefs.getString(s1Key), s1Saved);
    });

    test('a save from before seasons had ids (keys before profiles) loads as Season 1', () async {
      final record = SeasonProgress(activeEpisodeId: 'ep03', solvedEpisodeIds: const ['ep01', 'ep02']);
      SharedPreferences.setMockInitialValues({
        AppConstants.seasonStorageKey: jsonEncode(record.toJson()),
        AppConstants.progressStorageKey: jsonEncode(GameProgress(detectiveName: 'MIN', introSeen: true).toJson()),
      });
      prefs = await SharedPreferences.getInstance();
      container.dispose();
      container = await open();
      expect(container.read(selectedSeasonIdProvider), SeasonIds.london);
      expect(container.read(seasonProvider).activeEpisodeId, 'ep03');
      expect(container.read(seasonProvider).solvedEpisodeIds, ['ep01', 'ep02']);
      expect(current().id, 'ep03');
      expect(paris().status, SeasonStatus.locked);
      // The originals are never changed.
      expect(prefs.getString(AppConstants.seasonStorageKey), jsonEncode(record.toJson()));
    });

    test('Season 1 and Season 2 keep separate progress; coins, badges and profile are shared', () async {
      container.dispose();
      container = await open(episodes: withParis);
      ctrl().createDetective('Kim', DetectiveAvatar.boy);
      solveCurrentCase(); // Season 1, Case 01
      saveSeason1(season1Finished.copyWith(activeEpisodeId: 'ep01'));
      container.dispose();
      container = await open(episodes: withParis);

      final s1Key = savedKey(prefs, AppConstants.seasonStorageKey);
      final s1Record = prefs.getString(s1Key);
      final ep01Save = prefs.getString(savedKey(prefs, AppConstants.progressStorageKey));
      final coins = container.read(walletProvider).balance;
      final ep01Badges = [...state().badgeIds];
      expect(ep01Badges, isNotEmpty);

      expect(paris().status, SeasonStatus.open);
      expect(ctrl().openSeason(SeasonIds.paris), isTrue);
      expect(container.read(selectedSeasonIdProvider), SeasonIds.paris);
      expect(current().id, 's2_ep01', reason: 'Season 2 starts at its own Case 01');
      expect(state().completedMissionIds, isEmpty);
      expect(state().detectiveName, 'Kim', reason: 'the detective is the same');
      expect([for (final e in container.read(episodeCatalogProvider)) e.id], ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04']);
      expect(ctrl().openEpisode('s2_ep02'), isFalse, reason: 'Case 02 of Paris waits for its Case 01');
      expect(ctrl().openEpisode('ep05'), isFalse, reason: 'a case of another season never opens here');

      solveCurrentCase(); // Paris, Case 01
      expect(container.read(seasonProvider).solvedEpisodeIds, ['s2_ep01']);
      expect(container.read(walletProvider).balance, greaterThan(coins), reason: 'one wallet, new missions pay');
      final afterParis = container.read(walletProvider).balance;
      for (final m in current().allMissions) {
        expect(container.read(walletProvider).has(Wallet.missionKey(m.id)), isTrue);
      }

      // Season 1 is untouched by Season 2.
      expect(prefs.getString(s1Key), s1Record);
      expect(prefs.getString(savedKey(prefs, AppConstants.progressStorageKey)), ep01Save);
      expect(prefs.getString(savedKey(prefs, AppConstants.seasonKeyFor(SeasonIds.paris))), isNotNull);

      // Back to Season 1: its own record and case, as they were.
      expect(ctrl().openSeason(SeasonIds.london), isTrue);
      expect(container.read(seasonProvider).solvedEpisodeIds, season1Ids);
      expect(current().id, 'ep01');
      expect(state().badgeIds, ep01Badges);
      expect(container.read(walletProvider).balance, afterParis, reason: 'coins are the detective\'s, not a season\'s');
      expect(container.read(seasonAvailabilityProvider(SeasonIds.paris))!.solvedCount, 1);
    });

    test('the app reopens on the season being played; a season left keeps its case', () async {
      container.dispose();
      container = await open(episodes: withParis);
      ctrl().createDetective('Kim', DetectiveAvatar.boy);
      saveSeason1(season1Finished.copyWith(activeEpisodeId: 'ep04'));
      container.dispose();
      container = await open(episodes: withParis);
      expect(ctrl().openSeason(SeasonIds.paris), isTrue);
      ctrl().startInvestigation();

      container.dispose(); // the app closes in Paris
      container = await open(episodes: withParis);
      expect(container.read(selectedSeasonIdProvider), SeasonIds.paris);
      expect(current().id, 's2_ep01');
      expect(state().introSeen, isTrue);

      expect(ctrl().openSeason(SeasonIds.london), isTrue);
      container.dispose();
      container = await open(episodes: withParis);
      expect(container.read(selectedSeasonIdProvider), SeasonIds.london);
      expect(current().id, 'ep04', reason: 'Season 1 reopens on its own open case');
    });

    test('a saved season that cannot be entered (gone, locked, not released) reopens on Season 1', () async {
      ctrl().createDetective('Kim', DetectiveAvatar.boy);
      for (final saved in ['s9_nowhere', SeasonIds.paris]) {
        prefs.setString(savedKey(prefs, AppConstants.selectedSeasonKey), jsonEncode({'seasonId': saved}));
        container.dispose();
        container = await open(); // the game as it ships: Paris not released
        expect(container.read(selectedSeasonIdProvider), SeasonIds.london, reason: saved);
        expect(current().seasonId, SeasonIds.london);
      }
      // Locked (Season 1 not finished), even with its cases.
      container.dispose();
      container = await open(episodes: withParis);
      expect(paris().status, SeasonStatus.locked);
      expect(container.read(selectedSeasonIdProvider), SeasonIds.london);
    });

    test('NEW ADVENTURE starts over in Season 1, every season forgotten', () async {
      container.dispose();
      container = await open(episodes: withParis);
      ctrl().createDetective('Kim', DetectiveAvatar.boy);
      saveSeason1(season1Finished);
      container.dispose();
      container = await open(episodes: withParis);
      expect(ctrl().openSeason(SeasonIds.paris), isTrue);
      solveCurrentCase();

      await ctrl().newAdventure();
      expect(container.read(selectedSeasonIdProvider), SeasonIds.london);
      expect(current().id, 'ep01');
      expect(container.read(seasonProvider).solvedEpisodeIds, isEmpty);
      expect(paris().status, SeasonStatus.locked);
      expect(paris().solvedCount, 0);
      expect(prefs.getString(savedKey(prefs, AppConstants.seasonKeyFor(SeasonIds.paris))), isNull);
    });

    test('renaming the detective renames the saves of every season', () async {
      container.dispose();
      container = await open(episodes: withParis);
      ctrl().createDetective('Kim', DetectiveAvatar.boy);
      saveSeason1(season1Finished);
      container.dispose();
      container = await open(episodes: withParis);
      expect(ctrl().openSeason(SeasonIds.paris), isTrue);
      ctrl().startInvestigation();
      expect(ctrl().openSeason(SeasonIds.london), isTrue);
      expect(ctrl().renameDetective('Lee'), isNull);
      final repo = container.read(progressRepositoryProvider);
      expect(repo.load('s2_ep01').detectiveName, 'Lee');
    });
  });

  group('season unlocking', () {
    test('Season 2 stays locked until Season 1\'s Case 12 is solved', () async {
      container.dispose();
      container = await open(episodes: withParis);
      ctrl().createDetective('Kim', DetectiveAvatar.boy);
      expect(paris().status, SeasonStatus.locked);
      expect(paris().isUnlocked, isFalse);
      expect(ctrl().openSeason(SeasonIds.paris), isFalse);
      expect(container.read(selectedSeasonIdProvider.notifier).select(SeasonIds.paris), isFalse);
      expect(container.read(selectedSeasonIdProvider), SeasonIds.london);
      expect(ctrl().openEpisode('s2_ep01'), isFalse, reason: 'a locked season\'s case never opens');
      expect(current().id, 'ep01');

      // Eleven cases solved: still locked.
      saveSeason1(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: season1Ids.take(11).toList()));
      container.dispose();
      container = await open(episodes: withParis);
      expect(paris().status, SeasonStatus.locked);

      // Operator access opens the cases of the season played, not a season.
      container.read(operatorAccessSwitchProvider.notifier).set(true);
      expect(container.read(operatorAccessProvider), isTrue);
      expect(ctrl().openSeason(SeasonIds.paris), isFalse);
    });

    test('solving Season 1\'s Case 12 unlocks Season 2 at once', () async {
      container.dispose();
      container = await open(episodes: withParis);
      ctrl().createDetective('Kim', DetectiveAvatar.boy);
      saveSeason1(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: season1Ids.take(11).toList()));
      container.dispose();
      container = await open(episodes: withParis);
      expect(current().id, 'ep12');
      expect(paris().status, SeasonStatus.locked);
      expect(container.read(seasonAvailabilityProvider(SeasonIds.london))!.isCompleted, isFalse);

      solveCurrentCase();
      expect(paris().status, SeasonStatus.open);
      expect(container.read(seasonAvailabilityProvider(SeasonIds.london))!.isCompleted, isTrue);
      expect(ctrl().openSeason(SeasonIds.paris), isTrue);
    });

    test('unlocked but not released, Season 2 is coming soon and is never entered, its Case 01 in the game or not', () async {
      ctrl().createDetective('Kim', DetectiveAvatar.boy);
      saveSeason1(season1Finished);
      container.dispose();
      container = await open(parisUnreleased: true); // Paris's cases and map in, not released yet
      expect(paris().hasCases, isTrue);
      expect(paris().hasMap, isTrue);
      expect(paris().released, isFalse);
      expect(paris().status, SeasonStatus.comingSoon);
      expect(paris().isUnlocked, isTrue);
      expect(paris().canEnter, isFalse);
      expect(container.read(selectedSeasonIdProvider.notifier).select(SeasonIds.paris), isFalse);
      expect(ctrl().openSeason(SeasonIds.paris), isFalse);
      expect(container.read(selectedSeasonIdProvider), SeasonIds.london);
      expect(current().seasonId, SeasonIds.london);
      expect(container.read(episodeCatalogProvider), hasLength(12));
      expect(prefs.getString(savedKey(prefs, AppConstants.selectedSeasonKey)), isNull);
    });

    test('with its cases but no map, Season 2 is not ready: never entered, never on London\'s map', () async {
      ctrl().createDetective('Kim', DetectiveAvatar.boy);
      saveSeason1(season1Finished);
      container.dispose();
      container = await open(episodes: withParis, maps: londonOnlyMaps); // no Paris map
      expect(paris().hasCases, isTrue);
      expect(paris().hasMap, isFalse);
      expect(paris().status, SeasonStatus.comingSoon);
      expect(ctrl().openSeason(SeasonIds.paris), isFalse);
      expect(container.read(selectedSeasonIdProvider), SeasonIds.london);
      // A saved choice of it is not resumed either.
      prefs.setString(savedKey(prefs, AppConstants.selectedSeasonKey), jsonEncode({'seasonId': SeasonIds.paris}));
      container.dispose();
      container = await open(episodes: withParis, maps: londonOnlyMaps);
      expect(container.read(selectedSeasonIdProvider), SeasonIds.london);
      // With its map, it opens.
      container.dispose();
      container = await open(episodes: withParis);
      expect(paris().hasMap, isTrue);
      expect(paris().status, SeasonStatus.open);
    });

    test('a season the game does not have is neither available nor entered', () {
      expect(container.read(seasonAvailabilityProvider('s9_nowhere')), isNull);
      expect(ctrl().openSeason('s9_nowhere'), isFalse);
      expect(container.read(selectedSeasonIdProvider), SeasonIds.london);
    });
  });

  group('the map', () {
    test('Season 1 keeps its London map, landmarks and places', () {
      expect(SeasonMap.forSeason(SeasonIds.london), same(SeasonMap.london));
      expect(SeasonMap.forSeason(SeasonIds.paris), same(SeasonMap.paris), reason: 'Paris has its own map, not London\'s');
      // London's map is the artwork, size, ratio and places it always had.
      expect(SeasonMap.london.artwork, ArtAssets.londonMap);
      expect(SeasonMap.london.pixels, ArtAssets.londonMapPixels);
      expect(SeasonMap.london.aspect, ArtAssets.londonMapAspect);
      expect(SeasonMap.london.landmarks, Landmark.values);
      expect(SeasonMap.london.missionLandmarks, same(MapWorld.missionLandmarks));
      expect(File(SeasonMap.london.artwork).existsSync(), isTrue, reason: SeasonMap.london.artwork);
      // Case 01's first place, as placed before seasons: King's Cross, its group of one.
      final ep01 = MockEpisodeRepository.bundled().first;
      expect(MapWorld.places(ep01)['m01'], Landmark.kingsCross.at + Offset(0, math.max(0, MapWorld.topMargin - Landmark.kingsCross.at.dy)));
      for (final e in season1Cases()) {
        for (final m in e.allMissions) {
          expect(SeasonMap.landmarkOf(m.id), MapWorld.missionLandmarks[m.id], reason: m.id);
        }
      }
      // A mission of no map stands at its own layout place (a stand-in case
      // no season has written).
      final paris = parisCase(12);
      final places = MapWorld.places(paris);
      for (final m in paris.allMissions) {
        expect(SeasonMap.landmarkOf(m.id), isNull);
        expect(places[m.id]!.dx, m.mapX);
      }
      expect(PlaceArt.placeOf(paris.missions.first), paris.missions.first.scene);
    });

    testWidgets('a season played without its map shows the map is not ready, never London', (t) async {
      // Paris opened with its map, then the map gone from the game: the page
      // must neither show London nor fail.
      var maps = withParisMap;
      final c = ProviderContainer(
        overrides: [
          ...await testOverridesFor(prefs),
          allEpisodesProvider.overrideWithValue(withParis),
          seasonMapsProvider.overrideWith((ref) => maps),
          asReleased,
        ],
      );
      addTearDown(c.dispose);
      c.read(gameControllerProvider.notifier).createDetective('Kim', DetectiveAvatar.boy);
      c.read(progressRepositoryProvider).saveSeason(season1Finished);
      c.invalidate(seasonProvider); // read the season record again
      expect(c.read(gameControllerProvider.notifier).openSeason(SeasonIds.paris), isTrue);
      c.read(gameControllerProvider.notifier).startInvestigation();
      maps = londonOnlyMaps;
      c.invalidate(seasonMapsProvider);

      await t.pumpWidget(UncontrolledProviderScope(container: c, child: const MaterialApp(home: MissionMapScreen())));
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('THE MAP IS NOT READY'), findsOneWidget);
      expect(find.text('BACK TO CASE FILES'), findsOneWidget);
      expect(showsLondon(), isFalse);
      expect(t.takeException(), isNull);
    });

    testWidgets('a place with no picture shows its season\'s map; with no map, only the night', (t) async {
      await t.pumpWidget(const MaterialApp(home: PlaceScenery(null)));
      expect(showsLondon(), isTrue, reason: 'Season 1 as before: the London map');
      await t.pumpWidget(const MaterialApp(home: PlaceScenery(null, map: null)));
      expect(showsLondon(), isFalse);
      expect(t.takeException(), isNull);
      // A mission's own season map: London for Season 1's; a season missing
      // from the maps has none.
      final m01 = MockEpisodeRepository.bundled().first.missionById('m01')!;
      expect(SeasonMap.ofMission(m01.id), same(SeasonMap.london));
      expect(londonOnlyMaps[SeasonIds.paris], isNull);
    });
  });

  group('links', () {
    Future<WidgetRef> pumpApp(WidgetTester t) async {
      t.view.physicalSize = const Size(1170, 2532);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final overrides = await testOverrides(prefs: {
        AppConstants.progressStorageKey: jsonEncode(GameProgress(detectiveName: 'MIN', introSeen: true).toJson()),
      });
      late WidgetRef appRef;
      await t.pumpWidget(ProviderScope(
        overrides: [...overrides, allEpisodesProvider.overrideWithValue(withParis)],
        child: Consumer(builder: (context, ref, _) {
          appRef = ref;
          return const LondonMysteryApp();
        }),
      ));
      await wait(t);
      return appRef;
    }

    testWidgets('a link to a case of a locked season, or one not played, opens no case file', (t) async {
      final ref = await pumpApp(t);
      final router = ref.read(routerProvider);
      Uri at() => router.routerDelegate.currentConfiguration.uri;

      for (final link in [Routes.caseFile('s2_ep01'), Routes.caseFile('s2_ep02'), '/mission/s2_ep01_m1', '/story/s2_ep01_m1']) {
        router.go(link);
        await wait(t, const Duration(milliseconds: 600));
        expect(at().queryParameters['case'], isNull, reason: link);
        expect(at().path, isNot(startsWith('/mission/s2_')), reason: link);
        expect(at().path, isNot(startsWith('/story/s2_')), reason: link);
      }
      expect(ref.read(currentEpisodeProvider).id, 'ep01');

      // Season 1's own links work as before.
      router.go(Routes.caseFile('ep01'));
      await wait(t, const Duration(milliseconds: 600));
      expect(at().path, Routes.episodes);
      expect(at().queryParameters['case'], 'ep01');
      await wait(t, const Duration(seconds: 3));
    });
  });
}
