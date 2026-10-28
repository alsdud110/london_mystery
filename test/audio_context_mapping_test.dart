import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/core/utils/audio_service.dart';
import 'package:world_mystery/data/mock/season1/season1_sounds.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/audio_scenes.dart';

/// Audio context mapping 2.0: a place sounds like what the player stands in
/// and looks at on the screen, not like the landmark nearby.
void main() {
  final season = MockEpisodeRepository.bundled();
  Episode episode(String id) => season.firstWhere((e) => e.id == id);
  SoundPlace place(String missionId) => season1Places[missionId]!;

  AudioScene sceneAt(String caseId, String path, {String? id, List<String> done = const []}) => audioSceneFor(
    path: path,
    id: id,
    episode: episode(caseId),
    progress: GameProgress(detectiveName: 'T', introSeen: true, completedMissionIds: done),
    seasonBegun: true,
  )!;

  group('the river only where its water is near', () {
    test('Case 01 M3, at the foot of Big Ben: a street at night, not the river', () {
      expect(place('m03'), (AmbienceBase.londonNight, null));
    });

    test('Case 01 M3 → its story → the map: the river never comes in', () {
      final scenes = [
        sceneAt('ep01', Routes.mission('m03'), id: 'm03', done: ['m01', 'm02']),
        sceneAt('ep01', Routes.story('m03'), id: 'm03', done: ['m01', 'm02', 'm03']),
        sceneAt('ep01', Routes.map, done: ['m01', 'm02', 'm03']),
      ];
      for (final s in scenes) {
        expect(s.ambienceBase, AmbienceBase.londonNight, reason: '$s');
      }
      final audio = MockAudioService();
      for (final s in scenes) {
        audio.setScene(s);
      }
      expect(audio.ambienceStarts, [AmbienceBase.londonNight], reason: 'one street, never restarted');
    });

    test('Case 02 opens on a quiet morning street (not recorded yet: silent), not the river', () {
      expect(introSoundPlaceOf('ep02'), (AmbienceBase.londonDay, null));
      expect(ambienceLoops[AmbienceBase.londonDay], isNull);
    });

    test('on Westminster Bridge and Tower Bridge the river stays', () {
      expect(place('ep02_m1').$1, AmbienceBase.river);
      expect(place('ep10_final').$1, AmbienceBase.river);
    });

    test('Case 10 M3, the river far below the Tower wall: the Tower, not the river', () {
      expect(place('ep10_m3'), (AmbienceBase.towerGrounds, null));
    });

    test('Case 12 opens on London at night, not the river', () {
      expect(introSoundPlaceOf('ep12'), (AmbienceBase.londonNight, null));
    });

    test('no other scene of the season is the river', () {
      final river = {
        for (final e in season.map((x) => x.id))
          if (introSoundPlaceOf(e)?.$1 == AmbienceBase.river) '$e intro',
        for (final MapEntry(:key, :value) in season1Places.entries)
          if (value.$1 == AmbienceBase.river) key,
      };
      expect(river, {'ep02_m1', 'ep10_final'});
    });
  });

  group('details only where they are in the scene', () {
    test('Case 06: inside the market hall, no fountain; at the fountain and at midnight by it, the fountain', () {
      expect(place('ep06_m1').$2, isNull);
      expect(place('ep06_m2'), (AmbienceBase.londonNight, AmbienceAccent.fountain));
      expect(place('ep06_final'), (AmbienceBase.londonNight, AmbienceAccent.fountain));
    });

    test('the fountain only in Covent Garden\'s piazza', () {
      final fountains = {
        for (final MapEntry(:key, :value) in season1Places.entries)
          if (value.$2 == AmbienceAccent.fountain) key,
      };
      expect(fountains, {'ep06_m2', 'ep06_final'});
    });
  });

  group('inside rooms', () {
    test('Case 11 opens in the theatre\'s seats (Row R, Seat 17): the great room, not the street', () {
      expect(introSoundPlaceOf('ep11'), (AmbienceBase.grandInterior, null));
      final e = episode('ep11');
      expect(e.intro.join(' '), allOf(contains('The theatre is almost empty'), contains('Row R, Seat 17')),
          reason: 'the evidence: the narration is inside');
    });

    test('small rooms are small rooms, never a great hall, a station or a park', () {
      for (final id in ['ep04_m1', 'ep08_m2', 'ep08_m3', 'ep09_m2', 'ep11_m2', 'ep06_m1']) {
        expect(place(id).$1, AmbienceBase.smallInterior, reason: id);
      }
    });

    test('the boathouse is its own inside, not a small room and not the park', () {
      expect(place('ep07_m2').$1, AmbienceBase.boathouseInterior);
      expect(season1AmbienceRequired['ep07_m2'], 'BOATHOUSE_INTERIOR_REQUIRED');
    });

    test('Case 01 M4 is still the park; its night recording is owed', () {
      expect(place('m04').$1, AmbienceBase.park);
      expect(season1AmbienceRequired['m04'], 'PARK_NIGHT_VARIANT_REQUIRED');
      expect(episode('ep01').intro.first, contains('10:42 PM'), reason: 'Case 01 is one night');
    });
  });

  group('not recorded yet: silent, never a stand-in', () {
    const unrecorded = [
      AmbienceBase.stoneRoom,
      AmbienceBase.londonDay,
      AmbienceBase.smallInterior,
      AmbienceBase.boathouseInterior,
    ];

    test('they have no loop', () {
      for (final p in unrecorded) {
        expect(ambienceLoops[p], isNull, reason: p.name);
      }
    });

    // No place has a recording now (only the typing and the casebook tap are
    // heard, audio_assets_test): every scene is still followed, so adding a
    // place's loop is all it takes to hear it again.
    test('a scene on one of them is followed but not heard; so is every place now', () {
      final audio = MockAudioService();
      for (final p in [...unrecorded, AmbienceBase.station]) {
        audio.setScene(AudioScene(ambienceBase: p));
        expect(audio.ambience, p);
        expect(loopOf(AudioLayer.ambience, audio.ambience), isNull, reason: p.name);
      }
    });

    test('London by day stays London by day (Case 03 final, Case 09 intro, M3, final)', () {
      expect(place('ep03_final').$1, AmbienceBase.londonDay);
      expect(introSoundPlaceOf('ep09')!.$1, AmbienceBase.londonDay);
      expect(place('ep09_m3'), (AmbienceBase.londonDay, AmbienceAccent.guardMarch));
      expect(place('ep09_final').$1, AmbienceBase.londonDay);
    });
  });
}
