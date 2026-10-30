import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/mission_map/map_world.dart';
import 'package:world_mystery/features/season/world_archive_screen.dart';
import 'package:world_mystery/features/world_map/world_cities.dart';
import 'package:world_mystery/features/world_map/world_map_state.dart';
import 'package:world_mystery/widgets/art_assets.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';

/// The Rome integration: Season 3, made from its plans
/// (`lib/data/generated/s3_rome/`), is in the game as London and Paris are:
/// in the catalog, with its own map, cover, World Map city and evidence
/// pictures; unlocked by Paris's Case 12; its saves its own, London's and
/// Paris's left exactly as they were. Its twelve cases are played in
/// `test/sandbox/s3_rome_season_test.dart`.
void main() {
  late ProviderContainer container;
  late SharedPreferences prefs;
  GameController ctrl() => container.read(gameControllerProvider.notifier);
  SeasonAvailability of(String id) => container.read(seasonAvailabilityProvider(id))!;

  final londonIds = [for (var i = 1; i <= 12; i++) 'ep${i.toString().padLeft(2, '0')}'];
  final parisIds = [for (var i = 1; i <= 12; i++) 's2_ep${i.toString().padLeft(2, '0')}'];
  final romeIds = [for (var i = 1; i <= 12; i++) 's3_ep${i.toString().padLeft(2, '0')}'];

  Future<ProviderContainer> open() async => ProviderContainer(overrides: await testOverridesFor(prefs));

  void save(String key, SeasonProgress record) => prefs.setString(savedKey(prefs, key), jsonEncode(record.toJson()));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    container = await open();
  });
  tearDown(() => container.dispose());

  group('in the game', () {
    test('Rome is Season 3 of the catalog: 12 cases, released, after London and Paris', () {
      expect([for (final s in container.read(seasonsProvider)) s.id], [SeasonIds.london, SeasonIds.paris, SeasonIds.rome, SeasonIds.newyork]);
      final rome = SeasonCatalog.byId(SeasonIds.rome)!;
      expect(rome.released, isTrue);
      expect(rome.season.number, 3);
      expect(rome.season.title, 'The Broken Map of Rome');
      expect(rome.season.city, 'Rome');
      expect(rome.season.label, 'SEASON THREE');
      expect(rome.episodes.keys, romeIds);
      final cases = SeasonAvailability.casesOf(SeasonIds.rome, MockEpisodeRepository.bundled());
      expect([for (final e in cases) e.id], romeIds);
      expect([for (final e in cases) e.allMissions.length], everyElement(4), reason: '3 missions and a final each');
      // Its content lives in lib/, never read from the test sandbox.
      expect(Directory('test/sandbox/generated/s3_rome').existsSync(), isFalse);
    });

    test('Rome has its own map: its eleven landmarks, every mission at one, never Paris\'s', () {
      final map = SeasonMap.forSeason(SeasonIds.rome)!;
      expect(map, isNot(same(SeasonMap.paris)));
      expect(map.artwork, 'assets/seasons/season_03_rome/locations/map/rome_map.png');
      expect(File(map.artwork).existsSync(), isTrue);
      expect(map.aspect, 1.5);
      expect(map.landmarks, hasLength(11));
      final names = {for (final l in map.landmarks) l.name};
      expect(names, containsAll(['The Pantheon', 'Trevi Fountain', 'Tiber Island', 'The Roman Forum', 'Piazza della Civetta']));
      for (final l in map.landmarks) {
        expect(l.at.dx, inInclusiveRange(0.0, 1.0), reason: l.name);
        expect(l.at.dy, inInclusiveRange(0.0, 1.0), reason: l.name);
      }
      final rome = MockEpisodeRepository.bundled().where((e) => e.seasonId == SeasonIds.rome);
      for (final e in rome) {
        final places = MapWorld.places(e, map: map);
        for (final m in e.allMissions) {
          expect(map.landmarkFor(m.id, e.id), isNotNull, reason: m.id);
          final at = places[m.id]!;
          expect(at.dy, greaterThanOrEqualTo(MapWorld.topMargin - 1e-9), reason: '${m.id} under the top margin');
        }
      }
      // Case 08: the card read in the museum, the Owl met on the island.
      expect((SeasonMap.landmarkOf('s3_ep08_m1') as SeasonLandmark).id, 'capitoline_museums');
      expect((SeasonMap.landmarkOf('s3_ep08_m2') as SeasonLandmark).id, 'tiber_island');
    });

    test('its cover, its city on the World Map and its evidence pictures are registered, each on disk and bundled', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final folders = [for (final m in RegExp(r'^\s+- (assets/\S+/)\s*$', multiLine: true).allMatches(pubspec)) m[1]!];
      bool bundled(String f) => File(f).existsSync() && folders.any((d) => f.startsWith(d) && !f.substring(d.length).contains('/'));

      final cover = ArtAssets.seasonCovers[SeasonIds.rome]!;
      expect(cover.file, 'assets/seasons/season_03_rome/cover/season3_cover_rome.png');
      expect(bundled(cover.file), isTrue);
      expect(cover.pixels, const Size(1024, 1536));
      expect(ArtAssets.seasonCovers[SeasonIds.paris]!.file, contains('season_02_paris'), reason: 'Paris keeps its own');

      final city = WorldCities.ofSeason(SeasonIds.rome)!;
      expect(city.id, 'rome');
      expect(city.mapAt, const Offset(1038.5 / 1983, 330 / 793), reason: 'where the coming-soon pin always stood');
      expect([for (final c in WorldCities.all) c.name], ['London', 'Paris', 'Rome', 'Tokyo', 'Seoul', 'New York']);
      expect(WorldCities.all.where((c) => c.id == 'rome'), hasLength(1));

      final evidence = {for (final e in MockEpisodeRepository.bundled().where((e) => e.seasonId == SeasonIds.rome)) for (final v in e.allEvidence) v.id};
      final pictures = {for (final MapEntry(:key, :value) in ArtAssets.evidencePictures.entries) if (key.startsWith('s3_')) key: value};
      expect(pictures.keys.toSet(), hasLength(14), reason: '11 drawn for the notebook, 3 the puzzles\' (the real piece, the card, the helmet)');
      for (final MapEntry(:key, :value) in pictures.entries) {
        expect(evidence, contains(key), reason: '$key is evidence of a Rome case');
        expect(bundled(value), isTrue, reason: value);
      }
      expect(pictures['s3_ep11_e1'], 'assets/seasons/season_03_rome/objects/real_map_piece.png');
      expect(ArtAssets.evidencePictures['e01'], 'assets/shared/objects/letter.png', reason: 'London\'s unchanged');
    });
  });

  group('unlocked by Paris', () {
    test('locked while Paris\'s Case 12 is open; open the moment it is solved; entered; its saves its own', () async {
      ctrl().createDetective('Kim', DetectiveAvatar.girl);
      save(AppConstants.seasonStorageKey, SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: londonIds));
      save(AppConstants.seasonKeyFor(SeasonIds.paris), SeasonProgress(activeEpisodeId: 's2_ep12', solvedEpisodeIds: parisIds.take(11).toList()));
      container.dispose();
      container = await open();
      expect(of(SeasonIds.paris).status, SeasonStatus.open);
      expect(of(SeasonIds.rome).status, SeasonStatus.locked);
      expect(ctrl().openSeason(SeasonIds.rome), isFalse);

      // Paris's Case 12 solved: Rome opens at once, with its map.
      expect(ctrl().openSeason(SeasonIds.paris), isTrue);
      expect(ctrl().openEpisode('s2_ep12'), isTrue);
      final londonRecord = prefs.getString(savedKey(prefs, AppConstants.seasonStorageKey));
      final e = container.read(currentEpisodeProvider);
      ctrl().startInvestigation();
      for (final m in e.allMissions) {
        ctrl().markMissionStarted(m.id);
        expect(ctrl().submitAnswer(m, m.answer).result, SubmitResult.correct, reason: m.id);
      }
      // Paris's Case 12 closes with its ending, as its page closes it.
      expect(of(SeasonIds.rome).status, SeasonStatus.locked, reason: 'the ending not seen yet');
      expect(ctrl().closeCase(GameProgress.examinedKey(e.finalMission.id, 'ending')), isTrue);
      expect(of(SeasonIds.paris).isCompleted, isTrue);
      final rome = of(SeasonIds.rome);
      expect(rome.status, SeasonStatus.open);
      expect(rome.hasMap, isTrue);
      expect(rome.caseCount, 12);
      final parisRecord = prefs.getString(savedKey(prefs, AppConstants.seasonKeyFor(SeasonIds.paris)));

      expect(ctrl().openSeason(SeasonIds.rome), isTrue);
      expect(container.read(currentEpisodeProvider).id, 's3_ep01', reason: 'Rome starts at its own Case 01');
      expect(container.read(gameControllerProvider).detectiveName, 'Kim');
      expect(ctrl().openEpisode('s3_ep02'), isFalse, reason: 'Case 02 waits for Case 01');
      ctrl().startInvestigation();
      final romeKey = savedKey(prefs, AppConstants.seasonKeyFor(SeasonIds.rome));
      expect(romeKey, endsWith('.season.v1.s3_rome'), reason: 'its own key, as Paris has');
      // London's and Paris's records are as they were.
      expect(prefs.getString(savedKey(prefs, AppConstants.seasonStorageKey)), londonRecord);
      expect(prefs.getString(savedKey(prefs, AppConstants.seasonKeyFor(SeasonIds.paris))), parisRecord);

      // A restart reopens in Rome; the other seasons are where they were.
      container.dispose();
      container = await open();
      expect(container.read(selectedSeasonIdProvider), SeasonIds.rome);
      expect(container.read(currentEpisodeProvider).id, 's3_ep01');
      expect(ctrl().openSeason(SeasonIds.paris), isTrue);
      expect(container.read(seasonProvider).solvedEpisodeIds, parisIds);
      expect(ctrl().openSeason(SeasonIds.london), isTrue);
      expect(container.read(seasonProvider).solvedEpisodeIds, londonIds);
    });

    test('a save made before Rome was in the game loads as it was: no key changed, nothing reset', () async {
      final london = SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: londonIds);
      final paris = SeasonProgress(activeEpisodeId: 's2_ep05', solvedEpisodeIds: parisIds.take(4).toList());
      final progress = GameProgress(detectiveName: 'MIN', introSeen: true);
      SharedPreferences.setMockInitialValues({
        AppConstants.seasonStorageKey: jsonEncode(london.toJson()),
        AppConstants.progressStorageKey: jsonEncode(progress.toJson()),
      });
      prefs = await SharedPreferences.getInstance();
      container.dispose();
      container = await open();
      // The detective (name, avatar, wallet, badges) is in the keys written
      // here, by the game as it was: every one of them is compared below.
      ctrl().createDetective('MIN', DetectiveAvatar.girl);
      save(AppConstants.seasonKeyFor(SeasonIds.paris), paris);
      prefs.setString(savedKey(prefs, AppConstants.selectedSeasonKey), jsonEncode({'seasonId': SeasonIds.paris}));
      final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      container.dispose();
      container = await open();

      expect(container.read(selectedSeasonIdProvider), SeasonIds.paris, reason: 'the season being played is kept');
      expect(container.read(currentEpisodeProvider).id, 's2_ep05');
      expect(container.read(seasonProvider).solvedEpisodeIds, parisIds.take(4));
      expect(of(SeasonIds.rome).status, SeasonStatus.locked, reason: 'Paris is not finished');
      expect(of(SeasonIds.rome).solvedCount, 0);
      expect(ctrl().openSeason(SeasonIds.london), isTrue);
      expect(container.read(seasonProvider).solvedEpisodeIds, londonIds);
      // Nothing was written over, and no Rome save was made by reading it.
      for (final MapEntry(:key, :value) in before.entries) {
        if (key.endsWith('.selectedSeason.v1')) continue; // the season switched to London just now
        expect(prefs.get(key), value, reason: key);
      }
      expect(prefs.getKeys().where((k) => k.endsWith('.s3_rome')), isEmpty);
    });
  });

  testWidgets('Rome begins at its own Case 01 from its board: never London\'s opening page', (t) async {
    ctrl().createDetective('Kim', DetectiveAvatar.boy);
    save(AppConstants.seasonStorageKey, SeasonProgress(activeEpisodeId: 'ep01', solvedEpisodeIds: londonIds));
    save(AppConstants.seasonKeyFor(SeasonIds.paris), SeasonProgress(activeEpisodeId: 's2_ep12', solvedEpisodeIds: parisIds));
    container.dispose();
    container = await open();
    expect(ctrl().openSeason(SeasonIds.rome), isTrue);
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(UncontrolledProviderScope(container: container, child: const WorldMysteryApp()));
    await wait(t);
    final router = container.read(routerProvider);
    // A link to the opening page in Rome goes back to Rome's board.
    router.go(Routes.prologue);
    await wait(t, const Duration(milliseconds: 1500));
    expect(router.routerDelegate.currentConfiguration.uri.path, Routes.season);
    expect(find.text('THE BROKEN MAP OF ROME'), findsOneWidget, reason: "Rome's own board");
    expect(find.text('SEASON THREE'), findsOneWidget);
    await t.tap(find.text('BEGIN INVESTIGATION'));
    await wait(t, const Duration(milliseconds: 3000));
    expect(router.routerDelegate.currentConfiguration.uri.path, Routes.intro, reason: 'Case 01\'s story intro');
    expect(container.read(currentEpisodeProvider).id, 's3_ep01');
    expect(container.read(seasonProvider).prologueSeen, isTrue, reason: 'the board says it has begun');
  });

  group('the archive and the World Map', () {
    Future<void> show(WidgetTester t, String route) async {
      t.view.physicalSize = const Size(1179, 2556);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(UncontrolledProviderScope(container: container, child: const WorldMysteryApp()));
      await wait(t);
      container.read(routerProvider).go(route);
      await wait(t, const Duration(milliseconds: 2500));
    }

    testWidgets('sealed while Paris is under way; open after it; complete once its twelve cases are solved', (t) async {
      ctrl().createDetective('Kim', DetectiveAvatar.boy);
      SeasonFile file() => container.read(seasonFilesProvider).firstWhere((f) => f.season.id == SeasonIds.rome);
      WorldCityState city() => container.read(worldCityStatesProvider).firstWhere((c) => c.city.id == 'rome');
      expect(file().state, SeasonFileState.sealed);
      expect(city().status, WorldCityStatus.locked);

      // London's open case stays Case 01, where the detective was made.
      save(AppConstants.seasonStorageKey, SeasonProgress(activeEpisodeId: 'ep01', solvedEpisodeIds: londonIds));
      save(AppConstants.seasonKeyFor(SeasonIds.paris), SeasonProgress(activeEpisodeId: 's2_ep12', solvedEpisodeIds: parisIds));
      container.dispose();
      container = await open();
      expect(file().state, SeasonFileState.notStarted);
      expect(city().status, WorldCityStatus.playable);
      expect(city().canEnter, isTrue);
      await show(t, Routes.seasons);
      await t.scrollUntilVisible(find.text('THE BROKEN MAP OF ROME'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('THE BROKEN MAP OF ROME'), findsWidgets, reason: 'Rome\'s file in the archives');
      String? asset(ImageProvider p) => switch (p) {
        AssetImage(:final assetName) => assetName,
        ResizeImage(:final imageProvider) => asset(imageProvider),
        _ => null,
      };
      expect(find.byWidgetPredicate((w) => w is Image && asset(w.image) == ArtAssets.seasonCovers[SeasonIds.rome]!.file), findsWidgets,
          reason: 'its cover on its file');

      save(AppConstants.seasonKeyFor(SeasonIds.rome), SeasonProgress(activeEpisodeId: 's3_ep12', solvedEpisodeIds: romeIds));
      container.dispose();
      container = await open();
      expect(file().state, SeasonFileState.completed);
      expect(city().status, WorldCityStatus.completed);
      expect(of(SeasonIds.rome).isCompleted, isTrue);
      await t.pumpWidget(const SizedBox());
      await show(t, Routes.seasons);
      await t.scrollUntilVisible(find.text('THE BROKEN MAP OF ROME'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('REVIEW THE FILE'), findsWidgets, reason: 'a completed season is reviewed');
      expect(find.textContaining('SEASON FOUR'), findsNothing, reason: 'no season after Rome is offered');
    });
  });
}
