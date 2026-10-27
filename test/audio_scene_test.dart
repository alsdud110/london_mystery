import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/core/utils/audio_service.dart';
import 'package:london_mystery/data/mock/season1/season1_sounds.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/features/game/audio_scenes.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';

/// The lasting layers (music, place, detail): scenes compared layer by
/// layer, the loop players' lifecycle, Season 1's places and the flow of
/// the music through a case.
void main() {
  final season = season1Cases();
  Episode episode(String id) => season.firstWhere((e) => e.id == id);

  group('scene diff, layer by layer', () {
    const office = AudioScene(music: MusicTheme.casebook, ambienceBase: AmbienceBase.officeRain);

    test('A. the same scene twice: nothing restarts', () {
      final audio = MockAudioService()..setScene(office);
      final changes = audio.changes.length;
      audio.setScene(office);
      expect(audio.changes, hasLength(changes));
      expect(audio.levels, isEmpty);
      expect(audio.changesOf(AudioLayer.music), [MusicTheme.casebook]);
      expect(audio.changesOf(AudioLayer.ambience), [AmbienceBase.officeRain]);
      expect(audio.changesOf(AudioLayer.accent), isEmpty);
    });

    test('A. the same scene with an accent twice: the accent does not restart either', () {
      const tower = AudioScene(
        music: MusicTheme.investigation,
        ambienceBase: AmbienceBase.towerInterior,
        ambienceAccent: AmbienceAccent.clockMechanism,
      );
      final audio = MockAudioService()
        ..setScene(tower)
        ..setScene(tower);
      for (final layer in AudioLayer.values) {
        expect(audio.changesOf(layer), hasLength(1), reason: layer.name);
      }
    });

    test('B. same music, another place: only the place crosses over', () {
      final audio = MockAudioService()
        ..setScene(office)
        ..setScene(const AudioScene(music: MusicTheme.casebook, ambienceBase: AmbienceBase.londonNight));
      expect(audio.changesOf(AudioLayer.music), [MusicTheme.casebook]);
      expect(audio.changesOf(AudioLayer.ambience), [AmbienceBase.officeRain, AmbienceBase.londonNight]);
    });

    test('C. another music, same place: only the music crosses over', () {
      final audio = MockAudioService()
        ..setScene(office)
        ..setScene(const AudioScene(music: MusicTheme.resolution, ambienceBase: AmbienceBase.officeRain));
      expect(audio.changesOf(AudioLayer.music), [MusicTheme.casebook, MusicTheme.resolution]);
      expect(audio.changesOf(AudioLayer.ambience), [AmbienceBase.officeRain]);
    });

    test('D. same theme, another music level: the level moves, the track is not restarted', () {
      final audio = MockAudioService()
        ..setScene(const AudioScene(music: MusicTheme.investigation, musicLevel: -6))
        ..setScene(const AudioScene(music: MusicTheme.investigation, musicLevel: -4));
      expect(audio.changesOf(AudioLayer.music), hasLength(1));
      expect(audio.levels.single.layer, AudioLayer.music);
      expect(audio.levels.single.volume, closeTo(_volume(AudioLayer.music, MusicTheme.investigation, -4), 1e-9));
    });

    test('E. same place, another place level: the level moves, the place is not restarted', () {
      final audio = MockAudioService()
        ..setScene(const AudioScene(ambienceBase: AmbienceBase.londonNight))
        ..setScene(const AudioScene(ambienceBase: AmbienceBase.londonNight, ambienceLevel: -6));
      expect(audio.ambienceStarts, hasLength(1));
      expect(audio.levels.single.layer, AudioLayer.ambience);
      expect(audio.levels.single.volume, closeTo(_volume(AudioLayer.ambience, AmbienceBase.londonNight, -6), 1e-9));
    });

    test('F. same place, another detail: the bed stays, only the detail changes', () {
      final audio = MockAudioService()
        ..setScene(const AudioScene(ambienceBase: AmbienceBase.towerInterior))
        ..setScene(
          const AudioScene(ambienceBase: AmbienceBase.towerInterior, ambienceAccent: AmbienceAccent.clockMechanism),
        )
        ..setScene(const AudioScene(ambienceBase: AmbienceBase.towerInterior));
      expect(audio.ambienceStarts, [AmbienceBase.towerInterior]);
      expect(audio.changesOf(AudioLayer.accent), [AmbienceAccent.clockMechanism, null]);
      expect(audio.changesOf(AudioLayer.music), isEmpty);
    });

    test('G/H. sound off: the layers fade out, the scene wanted is kept; on again: it comes back', () {
      var on = true;
      final audio = MockAudioService(isEnabled: () => on)..setScene(office);
      audio.changes.clear();

      on = false;
      audio.refresh();
      expect(audio.active, AudioScene.silence);
      expect(audio.target, office, reason: 'what the page wants is kept');
      expect(audio.changes.map((c) => c.to), everyElement(isNull));
      expect(audio.changes.map((c) => c.fade), everyElement(GatedAudioService.silence));

      // Pages change while the sound is off: followed, not heard.
      const night = AudioScene(music: MusicTheme.casebook, ambienceBase: AmbienceBase.londonNight);
      audio.setScene(night);
      expect(audio.active, AudioScene.silence);
      expect(audio.target, night);

      audio.changes.clear();
      on = true;
      audio.refresh();
      expect(audio.active, night);
      expect(audio.changesOf(AudioLayer.music), [MusicTheme.casebook]);
      expect(audio.changesOf(AudioLayer.ambience), [AmbienceBase.londonNight]);
      expect(audio.changes.map((c) => c.fade), everyElement(GatedAudioService.restore));
    });

    test('I/J. the background stops the layers at once; coming back restores the scene', () {
      final audio = MockAudioService()..setScene(office);
      audio.changes.clear();

      audio.setForeground(false);
      expect(audio.stopsNow, 1, reason: 'at once: timers may not run in the background');
      expect(audio.changes, isEmpty, reason: 'no fades');
      expect(audio.active, AudioScene.silence);
      expect(audio.target, office);

      audio.setForeground(false); // hidden then paused: still one stop
      expect(audio.stopsNow, 1);

      audio.setForeground(true);
      expect(audio.active, office);
      expect(audio.changesOf(AudioLayer.music), [MusicTheme.casebook]);
      expect(audio.changesOf(AudioLayer.ambience), [AmbienceBase.officeRain]);
    });

    test('K. themes, places and details without a file yet: no crash, the scene is followed', () {
      final audio = _ChannelAudio();
      for (final music in MusicTheme.values) {
        for (final place in AmbienceBase.values) {
          for (final accent in [null, ...AmbienceAccent.values]) {
            final scene = AudioScene(music: music, ambienceBase: place, ambienceAccent: accent);
            audio.setScene(scene);
            expect(audio.target, scene);
            expect(audio.active, scene);
          }
        }
      }
      // A layer without a file is silent: no player is made for it.
      for (final made in audio.players.made) {
        expect(made.loop, isNotNull);
      }
      final unheard = [
        ...MusicTheme.values.where((m) => musicLoops[m] == null),
        ...AmbienceBase.values.where((p) => ambienceLoops[p] == null),
        ...AmbienceAccent.values.where((a) => accentLoops[a] == null),
      ];
      expect(unheard, isNotEmpty, reason: 'Season 1 still has places to record');
      audio.dispose();
    });

    testWidgets('L. a duck lowers the music only, and lets it back', (t) async {
      final audio = MockAudioService()
        ..setScene(
          const AudioScene(
            music: MusicTheme.finalMission,
            ambienceBase: AmbienceBase.stoneRoom,
            ambienceAccent: AmbienceAccent.ravenCalls,
          ),
        );
      final changes = audio.changes.length;
      audio.duckMusic(-8, hold: const Duration(seconds: 2));
      expect(audio.levels.single.layer, AudioLayer.music);
      expect(audio.levels.single.volume, closeTo(_volume(AudioLayer.music, MusicTheme.finalMission, -8), 1e-9));
      expect(audio.levels.single.fade, GatedAudioService.duckIn);

      await t.pump(const Duration(seconds: 2));
      expect(audio.levels, hasLength(2));
      expect(audio.levels.last.layer, AudioLayer.music);
      expect(audio.levels.last.volume, closeTo(_volume(AudioLayer.music, MusicTheme.finalMission, 0), 1e-9));
      expect(audio.levels.last.fade, GatedAudioService.duckOut);
      expect(audio.changes, hasLength(changes), reason: 'nothing restarted');
      expect(audio.levels.where((l) => l.layer != AudioLayer.music), isEmpty, reason: 'the places are untouched');
    });

    testWidgets('L. a newer duck holds the music: the first one cannot release it', (t) async {
      final audio = MockAudioService()..setScene(const AudioScene(music: MusicTheme.finalMission));
      audio.duckMusic(-8, hold: const Duration(seconds: 1));
      await t.pump(const Duration(milliseconds: 500));
      audio.duckMusic(-8, hold: const Duration(seconds: 2));
      await t.pump(const Duration(milliseconds: 700)); // the first duck's hold is over
      expect(audio.levels, hasLength(2), reason: 'still ducked');
      await t.pump(const Duration(seconds: 2));
      expect(audio.levels, hasLength(3));
    });

    test('M. rapid A → B → C: C is what plays; B never comes back', () {
      const a = AudioScene(music: MusicTheme.casebook, ambienceBase: AmbienceBase.officeRain);
      const b = AudioScene(music: MusicTheme.investigation, ambienceBase: AmbienceBase.londonNight);
      const c = AudioScene(music: MusicTheme.finalMission, ambienceBase: AmbienceBase.stoneRoom);
      final audio = MockAudioService()
        ..setScene(a)
        ..setScene(b)
        ..setScene(c);
      expect(audio.active, c);
      expect(audio.changesOf(AudioLayer.music).last, MusicTheme.finalMission);
      expect(audio.changesOf(AudioLayer.ambience).last, AmbienceBase.stoneRoom);
      audio.refresh();
      expect(audio.active, c);
    });
  });

  group('a loop channel and its players', () {
    const a = SoundFile('a.wav');
    const b = SoundFile('b.wav');
    const c = SoundFile('c.wav');
    const fade = Duration(seconds: 1);

    testWidgets('a crossover: the old loop fades out and is retired, the new one fades in', (t) async {
      final players = _Players();
      final channel = LoopChannel(players.create)..switchTo(a, 0.8, fade);
      await t.pump(const Duration(milliseconds: 1100));
      final pa = players.made.single;
      expect(pa.volume, closeTo(0.8, 1e-9));

      channel.switchTo(b, 0.6, fade);
      await t.pump(const Duration(milliseconds: 1100));
      final pb = players.made.last;
      expect(pa.disposed, isTrue);
      expect(pb.volume, closeTo(0.6, 1e-9));
      expect(channel.players, 1);
      expect(channel.loop, b);
      channel.dispose();
      await t.pump();
      expect(players.made.every((p) => p.disposed), isTrue);
    });

    testWidgets('the same loop again only moves its volume', (t) async {
      final players = _Players();
      final channel = LoopChannel(players.create)..switchTo(a, 0.8, fade);
      await t.pump(const Duration(milliseconds: 1100));
      channel.switchTo(a, 0.4, fade);
      await t.pump(const Duration(milliseconds: 1100));
      expect(players.made, hasLength(1));
      expect(players.made.single.volume, closeTo(0.4, 1e-9));
      channel.dispose();
      await t.pump();
    });

    testWidgets('no file (a layer not recorded yet): the old loop fades out, nothing new starts', (t) async {
      final players = _Players();
      final channel = LoopChannel(players.create)..switchTo(a, 0.8, fade);
      await t.pump(const Duration(milliseconds: 1100));
      channel.switchTo(null, 0.8, fade);
      await t.pump(const Duration(milliseconds: 1100));
      expect(players.made, hasLength(1));
      expect(players.made.single.disposed, isTrue);
      expect(channel.players, 0);
      expect(channel.loop, isNull);
    });

    testWidgets('a loop still loading when a newer one is asked for is retired unheard', (t) async {
      final players = _Players()..hold = true;
      final channel = LoopChannel(players.create)..switchTo(a, 0.8, fade);
      players.hold = false;
      channel.switchTo(b, 0.8, fade);
      await t.pump(const Duration(milliseconds: 1100));
      final (pa, pb) = (players.made[0], players.made[1]);
      expect(pb.volume, closeTo(0.8, 1e-9));

      pa.gate!.complete(); // a finishes loading, late
      await t.pump(const Duration(milliseconds: 1100));
      expect(pa.disposed, isTrue);
      expect(pa.volumes.every((v) => v == 0), isTrue, reason: 'never heard');
      expect(channel.loop, b);
      expect(channel.players, 1);
      channel.dispose();
      await t.pump();
    });

    testWidgets('another switch mid-crossover: the stale loop cannot become current again', (t) async {
      final players = _Players();
      final channel = LoopChannel(players.create)..switchTo(a, 0.8, fade);
      await t.pump(const Duration(milliseconds: 1100));
      channel.switchTo(b, 0.8, fade);
      await t.pump(const Duration(milliseconds: 500)); // a and b both sounding
      channel.switchTo(c, 0.8, fade);
      await t.pump(const Duration(milliseconds: 1100));
      final [pa, pb, pc] = players.made;
      expect(pa.disposed && pb.disposed, isTrue);
      expect(pb.volume, 0);
      expect(pc.volume, closeTo(0.8, 1e-9));
      expect(channel.players, 1, reason: 'no orphan player');

      channel.setVolume(0.3, fade);
      await t.pump(const Duration(milliseconds: 1100));
      expect(pc.volume, closeTo(0.3, 1e-9));
      expect(pb.volume, 0, reason: 'only the current loop moves');
      expect(players.made.any((p) => p.touchedAfterDispose), isFalse);
      channel.dispose();
      await t.pump();
    });

    testWidgets('stopNow mid-crossover: every player stops at once, no fade goes on', (t) async {
      final players = _Players();
      final channel = LoopChannel(players.create)..switchTo(a, 0.8, fade);
      await t.pump(const Duration(milliseconds: 1100));
      channel.switchTo(b, 0.8, fade);
      await t.pump(const Duration(milliseconds: 300));
      channel.stopNow();
      await t.pump();
      expect(channel.players, 0);
      expect(channel.loop, isNull);
      expect(players.made.every((p) => p.stopped && p.disposed), isTrue);
      await t.pump(const Duration(seconds: 2));
      expect(players.made.any((p) => p.touchedAfterDispose), isFalse);

      channel.switchTo(a, 0.8, fade); // back again: a fresh player
      await t.pump(const Duration(milliseconds: 1100));
      expect(players.made, hasLength(3));
      expect(players.made.last.volume, closeTo(0.8, 1e-9));
      channel.dispose();
      await t.pump();
    });

    testWidgets('disposed mid-fade, with a loop still loading: everything retired, nothing heard after', (t) async {
      final players = _Players();
      final channel = LoopChannel(players.create)..switchTo(a, 0.8, fade);
      await t.pump(const Duration(milliseconds: 400));
      players.hold = true;
      channel.switchTo(b, 0.8, fade);
      channel.dispose();
      await t.pump();
      players.made.last.gate!.complete();
      await t.pump(const Duration(seconds: 2));
      expect(channel.players, 0);
      expect(players.made.every((p) => p.disposed), isTrue);
      expect(players.made.last.volumes, isEmpty, reason: 'loaded after dispose: never faded in');
      expect(players.made.any((p) => p.touchedAfterDispose), isFalse);
    });

    testWidgets('a loop that cannot play is retired, and the channel carries on', (t) async {
      final players = _Players()..fail = true;
      final channel = LoopChannel(players.create)..switchTo(a, 0.8, fade);
      await t.pump();
      expect(players.made.single.disposed, isTrue);
      expect(channel.players, 0);
      players.fail = false;
      channel.switchTo(b, 0.8, fade);
      await t.pump(const Duration(milliseconds: 1100));
      expect(players.made.last.volume, closeTo(0.8, 1e-9));
      channel.dispose();
      await t.pump();
    });

    testWidgets('the service over real channels: rapid scenes leave one player per layer heard', (t) async {
      final audio = _ChannelAudio();
      const places = AmbienceBase.values;
      for (var i = 0; i < 6; i++) {
        audio.setScene(AudioScene(ambienceBase: places[i % places.length], ambienceLevel: i.isEven ? 0 : -6));
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(seconds: 3));
      expect(audio.channels[AudioLayer.ambience]!.players, ambienceLoops[audio.ambience] == null ? 0 : 1);
      audio.setForeground(false);
      await t.pump();
      for (final ch in audio.channels.values) {
        expect(ch.players, 0);
      }
      expect(audio.players.made.every((p) => p.disposed), isTrue);
      audio.dispose();
    });
  });

  group('Season 1 places', () {
    test('every case has 12 episodes worth of places: intro, every mission, every final', () {
      expect(season, hasLength(12));
      final missing = <String>[
        for (final e in season) ...[
          if (introSoundPlaceOf(e.id) == null) '${e.id} intro',
          for (final m in e.allMissions)
            if (soundPlaceOf(m) == null) m.id,
        ],
      ];
      expect(missing, isEmpty);
    });

    test('the place tables name only real cases and missions', () {
      final ids = {for (final e in season) ...e.allMissions.map((m) => m.id)};
      expect(season1IntroPlaces.keys.toSet(), {for (final e in season) e.id});
      expect(season1Places.keys.toSet(), ids);
      for (final id in season1SolvedAccents.keys) {
        expect(ids, contains(id));
      }
    });
  });

  group('continuity of a place through a case', () {
    /// Scenes in play order: the intro, then for each mission the map, the
    /// mission and its story, then the map, the final and the scene after it.
    List<(String, AudioScene)> walk(Episode e) {
      final done = <String>[];
      final out = <(String, AudioScene)>[];
      void at(String label, String path, {String? id, bool solved = false}) {
        final scene = audioSceneFor(
          path: path,
          id: id,
          episode: e,
          progress: GameProgress(
            detectiveName: 'T',
            introSeen: true,
            completedMissionIds: [...done],
            completedAt: solved ? DateTime(2026) : null,
          ),
          seasonBegun: true,
        );
        out.add((label, scene!));
      }

      at('intro', Routes.intro);
      for (final m in e.missions) {
        at('map', Routes.map);
        at(m.id, Routes.mission(m.id), id: m.id);
        done.add(m.id);
        at('story ${m.id}', Routes.story(m.id), id: m.id);
      }
      at('map', Routes.map);
      at('final', Routes.finalMission);
      done.add(e.finalMission.id);
      at('after', Routes.story(e.finalMission.id), id: e.finalMission.id, solved: true);
      return out;
    }

    void expectHeldThrough(String caseId, AmbienceBase place, {required String from, required String to}) {
      final scenes = walk(episode(caseId));
      final start = scenes.indexWhere((s) => s.$1 == from);
      final end = scenes.lastIndexWhere((s) => s.$1 == to);
      expect(start, isNonNegative);
      expect(end, greaterThan(start));
      final span = scenes.sublist(start, end + 1);
      for (final (label, scene) in span) {
        expect(scene.ambienceBase, place, reason: '$caseId $label');
      }
      final audio = MockAudioService();
      for (final (_, scene) in span) {
        audio.setScene(scene);
      }
      expect(audio.ambienceStarts, [place], reason: '$caseId: the place never restarts');
    }

    test('Case 03: the museum holds from M1 to M3', () {
      expectHeldThrough('ep03', AmbienceBase.grandInterior, from: 'ep03_m1', to: 'story ep03_m3');
    });

    // M1 is the Lost Property office, a small room of its own (mapping 2.0).
    test('Case 04: the station holds from M2 to M3', () {
      expectHeldThrough('ep04', AmbienceBase.station, from: 'ep04_m2', to: 'story ep04_m3');
    });

    // Inside the boathouse (M2) is not the park (mapping 2.0).
    test('Case 07: the park holds from the intro to M1, and from M3 to the final and after', () {
      expectHeldThrough('ep07', AmbienceBase.park, from: 'intro', to: 'story ep07_m1');
      expectHeldThrough('ep07', AmbienceBase.park, from: 'ep07_m3', to: 'after');
    });

    // The waiting room and the station office are small rooms (mapping 2.0).
    test('Case 08: the station holds from the intro to M1, and from the final to after', () {
      expectHeldThrough('ep08', AmbienceBase.station, from: 'intro', to: 'story ep08_m1');
      expectHeldThrough('ep08', AmbienceBase.station, from: 'final', to: 'after');
    });
  });

  group('the music through a case', () {
    final e = episode('ep01');

    AudioScene sceneAt(String path, {String? id, List<String> done = const [], bool solved = false}) => audioSceneFor(
      path: path,
      id: id,
      episode: e,
      progress: GameProgress(
        detectiveName: 'T',
        introSeen: true,
        completedMissionIds: done,
        completedAt: solved ? DateTime(2026) : null,
      ),
      seasonBegun: true,
    )!;

    final all = [for (final m in e.allMissions) m.id];
    final regular = [for (final m in e.missions) m.id];
    final flow = <(String, AudioScene, MusicTheme, double)>[
      ('title', sceneAt(Routes.start), MusicTheme.casebook, MusicLevels.casebook),
      ('registration', sceneAt(Routes.register), MusicTheme.casebook, MusicLevels.casebook),
      ('board', sceneAt(Routes.season), MusicTheme.casebook, MusicLevels.casebook),
      ('case files', sceneAt(Routes.episodes), MusicTheme.casebook, MusicLevels.casebook),
      ('story intro', sceneAt(Routes.intro), MusicTheme.investigation, MusicLevels.story),
      ('map', sceneAt(Routes.map), MusicTheme.investigation, MusicLevels.map),
      ('mission', sceneAt(Routes.mission('m01'), id: 'm01'), MusicTheme.investigation, MusicLevels.mission),
      ('story', sceneAt(Routes.story('m01'), id: 'm01', done: ['m01']), MusicTheme.investigation, MusicLevels.story),
      ('map again', sceneAt(Routes.map, done: ['m01']), MusicTheme.investigation, MusicLevels.map),
      ('final', sceneAt(Routes.finalMission, done: regular), MusicTheme.finalMission, MusicLevels.finalMission),
      (
        'after the final',
        sceneAt(Routes.story('final'), id: 'final', done: all, solved: true),
        MusicTheme.resolution,
        MusicLevels.afterCase,
      ),
      ('case closed', sceneAt(Routes.solved, done: all, solved: true), MusicTheme.resolution, MusicLevels.caseClosed),
      ('back to the board', sceneAt(Routes.season, done: all, solved: true), MusicTheme.casebook, MusicLevels.casebook),
    ];

    test('each page has its theme and level', () {
      for (final (label, scene, theme, level) in flow) {
        expect(scene.music, theme, reason: label);
        expect(scene.musicLevel, level, reason: label);
      }
      expect([MusicLevels.story, MusicLevels.map, MusicLevels.mission], [-6, -4, -6]);
    });

    test('the theme changes only between parts of the game; within one only its level moves', () {
      final audio = MockAudioService();
      for (final (_, scene, _, _) in flow) {
        audio.setScene(scene);
      }
      expect(audio.changesOf(AudioLayer.music), [
        MusicTheme.casebook,
        MusicTheme.investigation,
        MusicTheme.finalMission,
        MusicTheme.resolution,
        MusicTheme.casebook,
      ]);
    });

    test('story → map → mission: no restart, the music level goes -6, -4, -6', () {
      final audio = MockAudioService()..setScene(flow[4].$2); // story intro
      audio.levels.clear();
      audio.setScene(flow[5].$2); // map
      audio.setScene(flow[6].$2); // mission
      expect(audio.changesOf(AudioLayer.music), [MusicTheme.investigation]);
      final music = [
        for (final l in audio.levels)
          if (l.layer == AudioLayer.music) l.volume,
      ];
      expect(music, [
        closeTo(_volume(AudioLayer.music, MusicTheme.investigation, -4), 1e-9),
        closeTo(_volume(AudioLayer.music, MusicTheme.investigation, -6), 1e-9),
      ]);
    });

    test('the final and the case closed never borrow another theme', () {
      for (final (label, scene, _, _) in flow.where(
        (f) => f.$1 == 'final' || f.$1.contains('after') || f.$1 == 'case closed',
      )) {
        expect(scene.music, isNot(anyOf(MusicTheme.casebook, MusicTheme.investigation)), reason: label);
      }
    });
  });

  group('pages over the scene', () {
    // (The QR scanner, once also over the scene, is gone since 2026-10-19.)
    test('the notebook keeps the scene below', () {
      for (final path in [Routes.notebook]) {
        expect(
          audioSceneFor(
            path: path,
            episode: episode('ep01'),
            progress: const GameProgress(detectiveName: 'T'),
            seasonBegun: true,
          ),
          isNull,
          reason: path,
        );
      }
    });

    testWidgets('opening and closing the notebook over a mission restarts nothing', (t) async {
      final audio = MockAudioService();
      t.view.physicalSize = const Size(390, 844) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      late WidgetRef ref;
      await t.pumpWidget(
        ProviderScope(
          overrides: await testOverrides(
            audio: audio,
            prefs: {
              AppConstants.progressStorageKey: jsonEncode(
                GameProgress(detectiveName: 'T', introSeen: true, startedAt: DateTime(2026)).toJson(),
              ),
              AppConstants.seasonStorageKey: jsonEncode(const SeasonProgress(activeEpisodeId: 'ep01').toJson()),
            },
          ),
          child: Consumer(
            builder: (context, r, _) {
              ref = r;
              return const LondonMysteryApp();
            },
          ),
        ),
      );
      await wait(t, const Duration(milliseconds: 600));
      final router = ref.read(routerProvider);
      router.go(Routes.mission('m01'));
      await wait(t, const Duration(milliseconds: 1200));
      final under = audio.active;
      expect(under.ambienceBase, AmbienceBase.station);
      final (changes, levels) = (audio.changes.length, audio.levels.length);

      router.push(Routes.notebook);
      await wait(t, const Duration(milliseconds: 800));
      expect(audio.active, under);
      expect(audio.changes, hasLength(changes), reason: 'notebook open: nothing restarted');
      expect(audio.levels, hasLength(levels));

      router.pop();
      await wait(t, const Duration(milliseconds: 800));
      expect(audio.active, under);
      expect(audio.changes, hasLength(changes), reason: 'notebook closed: nothing restarted');
      expect(audio.levels, hasLength(levels));
    });
  });

  group('the confirmed sounds are unchanged', () {
    List<(String, double)> takes(GameSound s) => [for (final t in s.takes) (t.file, t.volume)];

    test('files and levels', () {
      expect(takes(GameSound.typewriterKey), [
        ('processed/typewriter_key_v4_01.wav', 0.21),
        ('processed/typewriter_key_v4_02.wav', 0.29),
        ('processed/typewriter_key_v4_03.wav', 0.23),
        ('processed/typewriter_key_v4_04.wav', 0.24),
      ]);
    });
  });
}

/// The playing volume the service gives [state] of [layer] at [db].
double _volume(AudioLayer layer, Enum state, double db) {
  final own = loopOf(layer, state)?.volume ?? 1;
  return (own * _gain(db)).clamp(0.0, 1.0);
}

double _gain(double db) => math.pow(10, db / 20).toDouble();

/// A stand-in loop player that remembers what was done to it.
class _FakePlayer implements LoopPlayer {
  _FakePlayer({this.gate, this.fail = false});

  /// While not complete, the loop is still loading.
  final Completer<void>? gate;
  final bool fail;
  SoundFile? loop;
  final List<double> volumes = [];
  bool stopped = false;
  bool disposed = false;
  bool touchedAfterDispose = false;

  @override
  double volume = 0;

  @override
  Future<void> start(SoundFile loop) {
    this.loop = loop;
    if (fail) return Future.error(StateError('no such file'));
    return gate?.future ?? Future.value();
  }

  @override
  Future<void> setVolume(double v) async {
    if (disposed) touchedAfterDispose = true;
    volume = v;
    volumes.add(v);
  }

  @override
  Future<void> stop() async => stopped = true;

  @override
  void dispose() => disposed = true;
}

class _Players {
  final List<_FakePlayer> made = [];
  bool hold = false;
  bool fail = false;

  LoopPlayer create() {
    final p = _FakePlayer(gate: hold ? Completer<void>() : null, fail: fail);
    made.add(p);
    return p;
  }
}

/// The service's rules over real [LoopChannel]s with stand-in players.
class _ChannelAudio extends GatedAudioService {
  final players = _Players();
  late final Map<AudioLayer, LoopChannel> channels = {
    for (final l in AudioLayer.values) l: LoopChannel(players.create),
  };

  @override
  Future<void> playFile(GameSound sound, SoundFile take, double volume) async {}

  @override
  void stop(GameSound sound) {}

  @override
  void applyLayer(AudioLayer layer, Enum? state, SoundFile? loop, double volume, Duration fade) =>
      channels[layer]!.switchTo(loop, volume, fade);

  @override
  void applyLevel(AudioLayer layer, double volume, Duration fade) => channels[layer]!.setVolume(volume, fade);

  @override
  void stopLayersNow() {
    for (final c in channels.values) {
      c.stopNow();
    }
  }

  @override
  void dispose() {
    super.dispose();
    for (final c in channels.values) {
      c.dispose();
    }
  }
}
