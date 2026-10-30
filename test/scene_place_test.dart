import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/content/scene_place_check.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/scene_explore.dart' show ScenePixels;
import 'package:world_mystery/data/models/scene_place.dart';
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/widgets/art_assets.dart';

import 'helpers.dart';

/// Places a season registers as data (`SeasonContent.places`) and the
/// scenes missions name (`MissionScene`): data only, no screen shows a
/// season place yet. Seasons 1 and 2 keep their [Artwork] scenes as they are.
void main() {
  /// A test season (never in the game) with [places] and one case whose
  /// missions name [scenes] (mission id → its scene fields).
  SeasonContent season(String id, {Map<String, ScenePlace> places = const {}, Map<String, Map<String, Object?>> scenes = const {}}) {
    final missions = [for (final e in scenes.entries) <String, dynamic>{'id': e.key, ...e.value}];
    return SeasonContent(
      info: {'id': id, 'number': 3},
      episodes: {
        '${id}_ep01': {
          'id': '${id}_ep01',
          'missions': missions.isEmpty ? const [] : missions.sublist(0, missions.length - 1),
          'finalMission': missions.isEmpty ? <String, dynamic>{'id': 'final', 'scene': 'bigBen'} : missions.last,
        },
      },
      places: places,
    );
  }

  const station = ScenePlace(file: ArtAssets.season2GareDuNord, pixels: ScenePixels(941, 1671));

  group('place ids', () {
    test("a season place id is its season's id, a dot and a lower-case name", () {
      expect(ScenePlaceIds.of('s3_tokyo', 'station'), 's3_tokyo.station');
      expect(ScenePlaceIds.seasonOf('s3_tokyo.station'), 's3_tokyo');
      expect(ScenePlaceIds.seasonOf('s3_tokyo.old_gate_2'), 's3_tokyo');
      expect(ScenePlaceIds.isOf('s3_tokyo.station', 's3_tokyo'), isTrue);
      expect(ScenePlaceIds.isOf('s3_tokyo.station', 's2_paris'), isFalse);
      for (final bad in ['station', '.station', 's3_tokyo.', 's3_tokyo.Station', 's3_tokyo.2nd', 's3_tokyo.a.b', 'gareDuNord']) {
        expect(ScenePlaceIds.seasonOf(bad), isNull, reason: bad);
      }
    });

    test('the game looks a place up in the season its id names; nothing for an unknown one', () {
      expect(SeasonCatalog.place('s3_tokyo.station'), isNull);
      expect(SeasonCatalog.place('s2_paris.gare'), isNull);
      expect(SeasonCatalog.place('gareDuNord'), isNull);
    });
  });

  group('a mission names one scene', () {
    test('an Artwork scene, or a season place; never both, never neither, never an unknown Artwork', () {
      expect(MissionScene.fromJson({'id': 'm', 'scene': 'bigBen'}), const ArtworkScene(Artwork.bigBen));
      expect(MissionScene.fromJson({'id': 'm', 'sceneKey': 's3_tokyo.station'}), const SeasonScene('s3_tokyo.station'));
      expect(() => MissionScene.fromJson({'id': 'm', 'scene': 'bigBen', 'sceneKey': 's3_tokyo.station'}), throwsFormatException);
      expect(() => MissionScene.fromJson({'id': 'm'}), throwsFormatException);
      expect(() => MissionScene.fromJson({'id': 'm', 'scene': 'tokyoStation'}), throwsFormatException);
      expect(() => MissionScene.fromJson({'id': 'm', 'sceneKey': 3}), throwsFormatException);
    });

    test('every mission of Seasons 1 and 2 names its Artwork as before, and round-trips unchanged', () {
      final missions = [for (final e in handMadeBundled()) ...e.allMissions];
      expect(missions, isNotEmpty);
      for (final m in missions) {
        final json = m.toJson();
        final art = m.scene;
        expect(art, isNotNull, reason: m.id);
        expect(m.place, ArtworkScene(art!), reason: m.id);
        expect(json['scene'], art.name, reason: m.id);
        expect(json.containsKey('sceneKey'), isFalse, reason: m.id);
        expect(MissionScene.fromJson(json), ArtworkScene(art), reason: m.id);
        expect(Mission.fromJson(json, finale: m.finale).scene, art, reason: m.id);
      }
      for (final s in SeasonCatalog.all.where((s) => handMadeSeason(s.id))) {
        for (final MapEntry(key: id, value: json) in ScenePlaceCheck.scenesOf(s).entries) {
          expect(MissionScene.fromJson(json), isA<ArtworkScene>(), reason: id);
        }
      }
    });

    test('a mission at a season place: parsed as one, written back with its sceneKey, never with a scene', () {
      final base = MockEpisodeRepository.bundled().first.missions.first.toJson();
      final json = {...base}..remove('scene')..['sceneKey'] = 's3_tokyo.station';
      final m = Mission.fromJson(json);
      expect(m.place, const SeasonScene('s3_tokyo.station'));
      expect(m.scene, isNull, reason: 'no Artwork: no page reads one for it');
      final back = m.toJson();
      expect(back['sceneKey'], 's3_tokyo.station');
      expect(back.containsKey('scene'), isFalse);
      expect(Mission.fromJson(back).place, m.place);
      expect(() => Mission.fromJson({...base, 'sceneKey': 's3_tokyo.station'}), throwsFormatException, reason: 'both');
      expect(() => Mission.fromJson({...base}..remove('scene')), throwsFormatException, reason: 'neither');
    });
  });

  group('the checks', () {
    test("the game's seasons: London and Paris no places of their own; Rome's its own; nothing wrong, nothing to bundle", () {
      for (final s in SeasonCatalog.all) {
        // A season made from its plans (Rome on) registers its places as data.
        expect(s.places.isEmpty, handMadeSeason(s.id), reason: s.id);
        for (final id in s.places.keys) {
          expect(ScenePlaceIds.isOf(id, s.id), isTrue, reason: id);
        }
      }
      expect(ScenePlaceCheck.problems(), isEmpty);
      expect(placeAssetProblems({for (final s in SeasonCatalog.all) ...s.places}), isEmpty);
    });

    test("a registered place of the season's own passes; an unregistered one is found", () {
      final ok = season('s3_test', places: {'s3_test.station': station}, scenes: {
        'm1': {'sceneKey': 's3_test.station'},
        'final': {'scene': 'bigBen'},
      });
      expect(ScenePlaceCheck.problems(seasons: [ok]), isEmpty);

      final missing = season('s3_test', places: {'s3_test.station': station}, scenes: {
        'm1': {'sceneKey': 's3_test.gate'},
        'final': {'sceneKey': 's3_test.station'},
      });
      expect(ScenePlaceCheck.problems(seasons: [missing]), [contains('m1: s3_test.gate is not registered')]);
    });

    test("another season's place, a malformed id, both scenes or neither are found", () {
      final s = season('s3_test', places: {'s3_test.station': station}, scenes: {
        'm1': {'sceneKey': 's2_paris.station'},
        'm2': {'sceneKey': 'station'},
        'm3': {'scene': 'bigBen', 'sceneKey': 's3_test.station'},
        'm4': <String, Object?>{},
        'final': {'scene': 'tokyoStation'},
      });
      final problems = ScenePlaceCheck.problems(seasons: [s]);
      expect(problems, hasLength(5));
      expect(problems[0], contains('m1: s2_paris.station is not a place of s3_test'));
      expect(problems[1], contains('m2: station is not a place of s3_test'));
      expect(problems[2], contains('m3: '));
      expect(problems[3], contains('m4: '));
      expect(problems[4], contains('final: '));
    });

    test("a place outside its season's namespace, or without a picture or size, is found", () {
      final s = season('s3_test', places: {
        's2_paris.station': station,
        's3_test.Gate': station,
        's3_test.folder': const ScenePlace(file: 'assets/seasons/', pixels: ScenePixels(10, 10)),
        's3_test.flat': const ScenePlace(file: ArtAssets.season2GareDuNord, pixels: ScenePixels(941, 0)),
      });
      final problems = ScenePlaceCheck.problems(seasons: [s]);
      expect(problems, [
        contains('s2_paris.station: not a place id of s3_test'),
        contains('s3_test.Gate: not a place id of s3_test'),
        contains('s3_test.folder: its picture is not an asset file'),
        contains('s3_test.flat: its pixel size is empty'),
      ]);
    });

    test('no place id is registered by two seasons', () {
      final a = season('s3_test', places: {'s3_test.station': station});
      final b = season('s4_test', places: {'s3_test.station': station});
      expect(ScenePlaceCheck.problems(seasons: [a, b]), [
        contains('s4_test place s3_test.station: not a place id of s4_test'),
        's3_test.station: registered by both s3_test and s4_test',
      ]);
    });

    test("a place's picture must be on disk and bundled", () {
      expect(placeAssetProblems({'s3_test.station': station}), isEmpty);
      expect(placeAssetProblems({'s3_test.gone': const ScenePlace(file: 'assets/seasons/none.png', pixels: ScenePixels(1, 1))}), [
        contains('is not on disk'),
      ]);
      expect(File('assets/branding/app_icon.png').existsSync(), isTrue);
      expect(placeAssetProblems({'s3_test.icon': const ScenePlace(file: 'assets/branding/app_icon.png', pixels: ScenePixels(1, 1))}), [
        contains('is not listed in pubspec.yaml'),
      ]);
    });

    test("a place's pixel size must be its picture's own", () {
      expect(pngSize(station.file), (941.0, 1671.0));
      expect(placeAssetProblems({'s3_test.wrong': const ScenePlace(file: ArtAssets.season2GareDuNord, pixels: ScenePixels(1536, 1024))}), [
        contains('is (941.0, 1671.0) pixels, not (1536.0, 1024.0)'),
      ]);
    });
  });

  test('Season ids are as before', () {
    expect([for (final s in SeasonCatalog.all) s.id], [SeasonIds.london, SeasonIds.paris, SeasonIds.rome, SeasonIds.newyork]);
  });
}
