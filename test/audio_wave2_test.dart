import 'dart:convert';
import 'dart:io';

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
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/audio_scenes.dart';
import 'package:london_mystery/features/game/game_controller.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';

/// Audio Wave 2 (provisional, listening pending): the places of Season 1,
/// their details, and the signature sounds of the world.
void main() {
  final season = MockEpisodeRepository.bundled();
  Episode episode(String id) => season.firstWhere((e) => e.id == id);

  group('the files', () {
    const wave2Places = {
      AmbienceBase.station: 'processed/amb_station_02.wav',
      AmbienceBase.grandInterior: 'processed/amb_grand_interior_01.wav',
      AmbienceBase.river: 'processed/amb_river_01.wav',
      AmbienceBase.park: 'processed/amb_park_01.wav',
      AmbienceBase.towerGrounds: 'processed/amb_tower_grounds_01.wav',
      AmbienceBase.towerInterior: 'processed/amb_tower_interior_01.wav',
      AmbienceBase.trainCarriage: 'processed/amb_train_carriage_02.wav',
    };
    const wave2Accents = {
      AmbienceAccent.clockMechanism: 'processed/acc_clock_mechanism_01.wav',
      AmbienceAccent.fountain: 'processed/acc_fountain_01.wav',
      AmbienceAccent.ravenCalls: 'processed/acc_raven_calls_01.wav',
      AmbienceAccent.guardMarch: 'processed/acc_guard_march_02.wav',
    };

    test('every new place and detail: a 30 s loop that never clips, its original kept', () {
      for (final (loop, file) in [
        for (final e in wave2Places.entries) (ambienceLoops[e.key], e.value),
        for (final e in wave2Accents.entries) (accentLoops[e.key], e.value),
      ]) {
        expect(loop?.file, file);
        final wav = _Wav(File('assets/sounds/$file'));
        expect(wav.channels, 2, reason: file);
        expect(wav.seconds, closeTo(30, 0.01), reason: '$file keeps its loop length');
        expect(wav.peak, inExclusiveRange(0.005, 0.99), reason: file);
        expect(File('assets/sounds/${file.replaceFirst('processed/', 'generated/')}').existsSync(), isTrue,
            reason: '$file: the original is kept');
      }
    });

    test('the stone room is silent until it is made again (no stand-in)', () {
      expect(ambienceLoops[AmbienceBase.stoneRoom], isNull);
      final audio = MockAudioService()..setScene(const AudioScene(ambienceBase: AmbienceBase.stoneRoom));
      expect(audio.ambience, AmbienceBase.stoneRoom, reason: 'followed as a place, simply not heard yet');
    });

    // London by day, small rooms and the boathouse are not recorded yet: silent until they are.
    test('every place and detail the season names has a loop, except those not recorded yet', () {
      final named = {
        for (final p in [...season1Places.values, ...season1IntroPlaces.values]) p.$1,
      };
      for (final place in named) {
        final notYet = {
          AmbienceBase.stoneRoom,
          AmbienceBase.londonDay,
          AmbienceBase.smallInterior,
          AmbienceBase.boathouseInterior,
        }.contains(place);
        expect(ambienceLoops[place] != null, !notYet, reason: place.name);
      }
      for (final accent in AmbienceAccent.values) {
        expect(accentLoops[accent], isNotNull, reason: accent.name);
      }
    });

    test('still no music: the Music API was not used', () {
      expect(musicLoops, isEmpty);
    });

    test('the signature sounds: their takes exist, trimmed, never clipping', () {
      const sounds = {
        GameSound.royalBoxOpen: 'processed/royal_box_open_02.wav',
        GameSound.clockRestart: 'processed/clock_restart_02.wav',
        GameSound.bigBenBell: 'processed/big_ben_bell_01.wav',
        GameSound.lockOpenHeavy: 'processed/lock_open_heavy_02.wav',
        GameSound.notebookOpen: 'processed/notebook_open_01.wav',
        GameSound.pencilNote: 'processed/pencil_note_01.wav',
        GameSound.paperRustle: 'processed/paper_rustle_01.wav',
        GameSound.pinPush: 'processed/pin_push_02.wav',
      };
      for (final MapEntry(key: sound, value: file) in sounds.entries) {
        expect([for (final t in sound.takes) t.file], [file], reason: sound.name);
        final wav = _Wav(File('assets/sounds/$file'));
        expect(wav.peak, inExclusiveRange(0.3, 0.99), reason: file);
        expect(wav.seconds, lessThanOrEqualTo(sound == GameSound.bigBenBell ? 8.0 : 3.0), reason: file);
        expect(sound.takes.single.volume, inInclusiveRange(0.1, 1), reason: file);
      }
      // Small Foley sits under the signatures.
      for (final small in [GameSound.pencilNote, GameSound.paperRustle, GameSound.pinPush]) {
        expect(small.takes.single.volume, lessThan(GameSound.royalBoxOpen.takes.single.volume), reason: small.name);
      }
    });
  });

  group('accents, layer by layer', () {
    test('same place, same detail: nothing restarts', () {
      const s = AudioScene(ambienceBase: AmbienceBase.londonNight, ambienceAccent: AmbienceAccent.fountain);
      final audio = MockAudioService()
        ..setScene(s)
        ..setScene(s);
      expect(audio.changesOf(AudioLayer.ambience), [AmbienceBase.londonNight]);
      expect(audio.changesOf(AudioLayer.accent), [AmbienceAccent.fountain]);
    });

    test('same place, another detail: the bed carries on', () {
      final audio = MockAudioService()
        ..setScene(const AudioScene(ambienceBase: AmbienceBase.towerInterior))
        ..setScene(const AudioScene(
          ambienceBase: AmbienceBase.towerInterior,
          ambienceAccent: AmbienceAccent.clockMechanism,
        ));
      expect(audio.changesOf(AudioLayer.ambience), [AmbienceBase.towerInterior]);
      expect(audio.changesOf(AudioLayer.accent), [AmbienceAccent.clockMechanism]);
    });

    test('another place, the same detail: the detail carries on', () {
      final audio = MockAudioService()
        ..setScene(const AudioScene(ambienceBase: AmbienceBase.towerGrounds, ambienceAccent: AmbienceAccent.ravenCalls))
        ..setScene(const AudioScene(ambienceBase: AmbienceBase.stoneRoom, ambienceAccent: AmbienceAccent.ravenCalls));
      expect(audio.changesOf(AudioLayer.ambience), [AmbienceBase.towerGrounds, AmbienceBase.stoneRoom]);
      expect(audio.changesOf(AudioLayer.accent), [AmbienceAccent.ravenCalls]);
    });
  });

  group('Season 1, case by case', () {
    GameProgress progress(List<String> done, {bool solved = false}) => GameProgress(
      detectiveName: 'T',
      introSeen: true,
      completedMissionIds: done,
      completedAt: solved ? DateTime(2026) : null,
    );

    /// The pages of a case in order (intro, map, each mission and its
    /// story, the final and the scene after it), as the audio service hears them.
    MockAudioService playCase(String id, {bool throughFinal = true}) {
      final e = episode(id);
      final audio = MockAudioService();
      void go(String path, {String? mission, List<String> done = const [], bool solved = false}) => audio.setScene(
        audioSceneFor(path: path, id: mission, episode: e, progress: progress(done, solved: solved), seasonBegun: true)!,
      );
      go(Routes.intro);
      final done = <String>[];
      for (final m in e.missions) {
        go(Routes.map, done: [...done]);
        go(Routes.mission(m.id), mission: m.id, done: [...done]);
        done.add(m.id);
        go(Routes.story(m.id), mission: m.id, done: [...done]);
      }
      if (throughFinal) {
        go(Routes.map, done: [...done]);
        go(Routes.finalMission, done: [...done]);
        final all = [...done, e.finalMission.id];
        go(Routes.finalMission, done: all, solved: true);
        go(Routes.story(e.finalMission.id), mission: e.finalMission.id, done: all, solved: true);
      }
      return audio;
    }

    test('Case 01: night, station, museum, night at Big Ben, park, night, the archive', () {
      expect(playCase('ep01').ambienceStarts, [
        AmbienceBase.londonNight,
        AmbienceBase.station,
        AmbienceBase.grandInterior,
        AmbienceBase.londonNight,
        AmbienceBase.park,
        AmbienceBase.londonNight,
        AmbienceBase.stoneRoom,
      ]);
    });

    test('Case 02: no clockwork until the clock runs again, then it carries on into the scene after', () {
      final audio = playCase('ep02');
      expect(audio.changesOf(AudioLayer.accent), [AmbienceAccent.clockMechanism], reason: 'once, after the solve');
      final e = episode('ep02');
      final before = audioSceneFor(
        path: Routes.finalMission,
        episode: e,
        progress: progress([for (final m in e.missions) m.id]),
        seasonBegun: true,
      )!;
      expect(before.ambienceBase, AmbienceBase.towerInterior);
      expect(before.ambienceAccent, isNull, reason: 'the clock is stopped');
      for (final m in e.missions) {
        final s = audioSceneFor(path: Routes.mission(m.id), id: m.id, episode: e, progress: progress([]), seasonBegun: true)!;
        expect(s.ambienceAccent, isNull, reason: '${m.id}: the clock is stopped');
      }
      final after = audioSceneFor(
        path: Routes.finalMission,
        episode: e,
        progress: progress([for (final m in e.allMissions) m.id], solved: true),
        seasonBegun: true,
      )!;
      expect(after.ambienceAccent, AmbienceAccent.clockMechanism);
      expect(after.ambienceBase, AmbienceBase.towerInterior);
    });

    test('Case 03: the museum holds from M1 to M3, the street at the end', () {
      expect(playCase('ep03').ambienceStarts, [AmbienceBase.grandInterior, AmbienceBase.londonDay]);
    });

    test('Case 04: the station, its Lost Property office, the platforms, the last train', () {
      expect(playCase('ep04').ambienceStarts, [
        AmbienceBase.station,
        AmbienceBase.smallInterior,
        AmbienceBase.station,
        AmbienceBase.trainCarriage,
      ]);
    });

    test('Case 05: the green and its ravens, then the stone rooms (a raven at the window)', () {
      final audio = playCase('ep05');
      expect(audio.ambienceStarts.first, AmbienceBase.towerGrounds);
      expect(audio.ambienceStarts, contains(AmbienceBase.stoneRoom));
      final e = episode('ep05');
      AudioScene at(String id) =>
          audioSceneFor(path: Routes.mission(id), id: id, episode: e, progress: progress([]), seasonBegun: true)!;
      expect(at('ep05_m1').ambienceAccent, AmbienceAccent.ravenCalls);
      expect(at('ep05_m2').ambienceAccent, isNull);
      expect(at('ep05_m3').ambienceAccent, AmbienceAccent.ravenCalls);
    });

    test('Case 06: the piazza and its fountain, inside the market hall, the fountain, the theatre', () {
      final audio = playCase('ep06');
      expect(audio.ambienceStarts, [
        AmbienceBase.londonNight,
        AmbienceBase.smallInterior,
        AmbienceBase.londonNight,
        AmbienceBase.grandInterior,
        AmbienceBase.londonNight,
      ]);
      expect(audio.changesOf(AudioLayer.accent).first, AmbienceAccent.fountain);
    });

    test('Case 07: the park, inside the boathouse, the park again; no detail', () {
      final audio = playCase('ep07');
      expect(audio.ambienceStarts, [AmbienceBase.park, AmbienceBase.boathouseInterior, AmbienceBase.park]);
      expect(audio.changesOf(AudioLayer.accent), isEmpty);
    });

    test('Case 08: the station, its waiting room and office, the train', () {
      expect(playCase('ep08').ambienceStarts, [AmbienceBase.station, AmbienceBase.smallInterior, AmbienceBase.station]);
    });

    test('Case 09: the palace rooms, then the courtyard with the guard, then the gate', () {
      final audio = playCase('ep09');
      expect(audio.ambienceStarts, [
        AmbienceBase.londonDay,
        AmbienceBase.grandInterior,
        AmbienceBase.smallInterior,
        AmbienceBase.londonDay,
      ]);
      expect(audio.changesOf(AudioLayer.accent), contains(AmbienceAccent.guardMarch));
    });

    test('Case 10: the Tower and its ravens, the river seen from the wall, then the bridge', () {
      final audio = playCase('ep10');
      expect(audio.ambienceStarts, [AmbienceBase.towerGrounds, AmbienceBase.river]);
      expect(audio.changesOf(AudioLayer.accent).first, AmbienceAccent.ravenCalls);
    });

    test('Case 11: the theatre, backstage, the stage door at night, the station', () {
      expect(playCase('ep11').ambienceStarts, [
        AmbienceBase.grandInterior,
        AmbienceBase.smallInterior,
        AmbienceBase.londonNight,
        AmbienceBase.station,
      ]);
    });

    test('Case 12: the clockwork only inside Big Ben', () {
      final audio = playCase('ep12');
      expect(audio.ambienceStarts, [
        AmbienceBase.londonNight,
        AmbienceBase.towerInterior,
        AmbienceBase.station,
        AmbienceBase.towerGrounds,
        AmbienceBase.stoneRoom,
      ]);
      final e = episode('ep12');
      for (final m in e.allMissions) {
        final place = soundPlaceOf(m)!;
        expect(place.$2 == AmbienceAccent.clockMechanism, m.id == 'ep12_m1', reason: m.id);
      }
    });
  });

  group('what solving sounds like', () {
    test('one physical identity per solve', () {
      for (final e in season) {
        for (final m in e.allMissions) {
          final expected = switch (m.id) {
            'ep05_m2' || 'ep05_final' || 'ep12_final' => GameSound.lockOpenHeavy,
            'm03' || 'ep05_m3' || 'ep08_m3' => GameSound.padlockOpen,
            'final' => GameSound.royalBoxOpen,
            'ep02_final' => GameSound.clockRestart,
            _ => m.isFinal ? GameSound.finale : GameSound.puzzleCorrect,
          };
          expect(solveSoundOf(m), expected, reason: m.id);
          expect(ringsBellOnSolve(m), m.id == 'ep02_final', reason: m.id);
        }
      }
    });

    test('heavy locks and padlocks never overlap', () {
      expect(season1HeavyLocks.intersection(season1LockMissions), isEmpty);
    });
  });

  group('signatures in play', () {
    int count(MockAudioService a, GameSound s) => a.played.where((p) => p == s).length;

    testWidgets('Case 01: OPEN THE BOX is the Royal Box, alone', (t) async {
      final audio = MockAudioService();
      final ref = await _openFinal(t, audio, season, 'ep01');
      await _dialIn(t, episode('ep01').finalMission.answer);
      audio.played.clear();
      await tapText(t, 'OPEN THE BOX', after: const Duration(milliseconds: 3500));
      expect(audio.played, [GameSound.royalBoxOpen], reason: 'no tap, no padlock, no final cue with it');
      expect(ref.read(gameControllerProvider).isCaseSolved, isTrue);
    });

    testWidgets('Case 02: the clock catches, its clockwork runs on, then Big Ben rings once', (t) async {
      final audio = MockAudioService();
      await _openFinal(t, audio, season, 'ep02');
      expect(audio.target.ambienceBase, AmbienceBase.towerInterior);
      expect(audio.target.ambienceAccent, isNull, reason: 'stopped before the solve');
      await _dialIn(t, episode('ep02').finalMission.answer);
      audio.played.clear();
      // The clock is brought into view (up to 0.5 s), then it catches.
      await tapText(t, 'UNLOCK', after: const Duration(milliseconds: 900));
      expect(audio.played, [GameSound.clockRestart], reason: 'the clock first, no bell yet');
      expect(audio.target.ambienceAccent, AmbienceAccent.clockMechanism, reason: 'the clockwork is now the place');
      expect(audio.changesOf(AudioLayer.ambience).where((p) => p == AmbienceBase.towerInterior), hasLength(1),
          reason: 'the tower does not start again');
      await wait(t, const Duration(milliseconds: 3000));
      expect(audio.played, [GameSound.clockRestart, GameSound.bigBenBell]);
      expect(count(audio, GameSound.finale), 0);
      expect(count(audio, GameSound.uiTap), 0);
    });

    testWidgets('Case 05: the iron chest opens heavily, not with a padlock', (t) async {
      final audio = MockAudioService();
      await _openFinal(t, audio, season, 'ep05');
      await _dialIn(t, episode('ep05').finalMission.answer);
      audio.played.clear();
      await tapText(t, 'UNLOCK', after: const Duration(milliseconds: 3000));
      expect(audio.played, [GameSound.lockOpenHeavy]);
    });

    testWidgets('a revisit of a solved final is quiet: no box, no bell', (t) async {
      final audio = MockAudioService();
      await _openFinal(t, audio, season, 'ep02', solved: true);
      await wait(t, const Duration(milliseconds: 3000));
      expect(audio.played, isEmpty);
      expect(audio.target.ambienceAccent, AmbienceAccent.clockMechanism);
    });

    testWidgets('the notebook opens once; its tabs inside are quiet; no tap with it', (t) async {
      final audio = MockAudioService();
      final ref = await _openFinal(t, audio, season, 'ep01');
      ref.read(routerProvider).go(Routes.map);
      await wait(t, const Duration(milliseconds: 1500));
      audio.played.clear();
      ref.read(routerProvider).push(Routes.notebook);
      await wait(t, const Duration(milliseconds: 900));
      expect(audio.played, [GameSound.notebookOpen]);
      final tabs = find.byType(Tab);
      if (tabs.evaluate().length > 1) {
        await t.tap(tabs.last);
        await wait(t, const Duration(milliseconds: 600));
      }
      expect(audio.played, [GameSound.notebookOpen], reason: 'turning inside the notebook is quiet');
    });

    testWidgets('OPEN MY NOTEBOOK on the final: the notebook, and no casebook tap', (t) async {
      final audio = MockAudioService();
      await _openFinal(t, audio, season, 'ep01');
      audio.played.clear();
      await tapText(t, 'OPEN MY NOTEBOOK', after: const Duration(milliseconds: 600));
      expect(audio.played, [GameSound.notebookOpen]);
    });

    testWidgets('a tip asked for is written with the pencil; none left, nothing', (t) async {
      final audio = MockAudioService();
      final ref = await _openFinal(t, audio, season, 'ep01');
      final m = episode('ep01').finalMission;
      audio.played.clear();
      for (var i = 0; i < m.hints.length; i++) {
        await tapText(t, 'GET A TIP', after: const Duration(milliseconds: 400));
      }
      expect(audio.played, List.filled(m.hints.length, GameSound.pencilNote));
      expect(ref.read(gameControllerProvider).hintsFor(m.id), m.hints.length);
      expect(find.text('GET A TIP'), findsNothing, reason: 'no tips left to ask for');
    });

    testWidgets('the letter read again: the paper, never the envelope', (t) async {
      final audio = MockAudioService();
      await _openFinal(t, audio, season, 'ep01');
      audio.played.clear();
      await tapText(t, 'Letter', after: const Duration(milliseconds: 600));
      expect(audio.played, [GameSound.paperRustle]);
      expect(audio.played, isNot(contains(GameSound.envelopeOpen)));
    });

    testWidgets('a case just solved is pinned to the board, once; the board alone is quiet', (t) async {
      final audio = MockAudioService();
      final ref = await _openFinal(t, audio, season, 'ep04');
      final e4 = episode('ep04');
      expect(ref.read(gameControllerProvider.notifier).submitAnswer(e4.finalMission, e4.finalMission.answer).result,
          SubmitResult.correct);
      audio.played.clear();
      ref.read(routerProvider).go(Routes.season);
      await wait(t, const Duration(milliseconds: 600));
      expect(audio.played, isEmpty, reason: 'the pin is not down yet');
      await wait(t, const Duration(milliseconds: 1800));
      expect(audio.played, [GameSound.pinPush]);
      ref.read(routerProvider).go(Routes.episodes);
      await wait(t, const Duration(milliseconds: 800));
      ref.read(routerProvider).go(Routes.season);
      await wait(t, const Duration(milliseconds: 2500));
      expect(count(audio, GameSound.pinPush), 1, reason: 'the board seen again: nothing pinned');
    });

    testWidgets('sound off: no signature is heard', (t) async {
      final audio = MockAudioService(isEnabled: () => false);
      await _openFinal(t, audio, season, 'ep02');
      await _dialIn(t, episode('ep02').finalMission.answer);
      await tapText(t, 'UNLOCK', after: const Duration(milliseconds: 3000));
      expect(audio.played, isEmpty);
      expect(audio.active, AudioScene.silence);
    });

    testWidgets('in the background: no signature, no layers', (t) async {
      final audio = MockAudioService();
      await _openFinal(t, audio, season, 'ep01');
      audio.setForeground(false);
      await _dialIn(t, episode('ep01').finalMission.answer);
      audio.played.clear();
      await tapText(t, 'OPEN THE BOX', after: const Duration(milliseconds: 3000));
      expect(audio.played, isEmpty);
      expect(audio.active, AudioScene.silence);
      audio.setForeground(true);
    });
  });

  group('protected sounds', () {
    test('the approved takes are where they were', () {
      expect(ambienceLoops[AmbienceBase.officeRain]!.file, 'processed/office_night_rain_v2_01.wav');
      expect(ambienceLoops[AmbienceBase.londonNight]!.file, 'processed/amb_london_night_01.wav');
      expect([for (final t in GameSound.uiTap.takes) (t.file, t.volume)], [
        ('processed/ui_tap_01.wav', 0.25),
        ('processed/ui_tap_02.wav', 0.38),
        ('processed/ui_tap_03.wav', 0.4),
      ]);
      expect(GameSound.finale.takes.single.file, 'final.wav');
    });
  });
}

/// The app on the final of [caseId]: earlier cases solved, its missions
/// done ([solved]: the final too).
Future<WidgetRef> _openFinal(
  WidgetTester t,
  MockAudioService audio,
  List<Episode> season,
  String caseId, {
  bool solved = false,
}) async {
  t.view.physicalSize = const Size(390, 844) * 3;
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final e = season.firstWhere((x) => x.id == caseId);
  final earlier = [for (final x in season) if (x.number < e.number) x];
  final start = DateTime.now().subtract(const Duration(minutes: 5));
  String progress(List<String> done, {bool solved = false}) => jsonEncode(GameProgress(
    detectiveName: 'MINYOUNG',
    introSeen: true,
    completedMissionIds: done,
    missionStartedAt: {e.finalMission.id: start},
    startedAt: start,
    completedAt: solved ? start : null,
    playMillis: 0,
  ).toJson());
  late WidgetRef ref;
  await t.pumpWidget(ProviderScope(
    overrides: await testOverrides(audio: audio, prefs: {
      for (final x in earlier)
        AppConstants.progressKeyFor(x.id): progress([for (final m in x.allMissions) m.id], solved: true),
      if (e.id != AppConstants.currentEpisodeId)
        AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINYOUNG').toJson()),
      AppConstants.progressKeyFor(e.id): progress(
        [for (final m in solved ? e.allMissions : e.missions) m.id],
        solved: solved,
      ),
      AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(
        activeEpisodeId: e.id,
        solvedEpisodeIds: [for (final x in earlier) x.id, if (solved) e.id],
      ).toJson()),
    }),
    child: Consumer(builder: (context, r, _) {
      ref = r;
      return const LondonMysteryApp();
    }),
  ));
  await wait(t, const Duration(milliseconds: 300));
  ref.read(routerProvider).go(Routes.finalMission);
  await wait(t, const Duration(milliseconds: 1500));
  return ref;
}

/// Turns the final's dials to [answer].
Future<void> _dialIn(WidgetTester t, String answer) async {
  for (final (i, digit) in answer.split('').map(int.parse).indexed) {
    final up = find.byTooltip('Lock ${i + 1} up');
    await reveal(t, up);
    for (var n = 0; n < digit; n++) {
      await t.tap(up);
      await t.pump(const Duration(milliseconds: 20));
    }
  }
  await wait(t, const Duration(milliseconds: 300));
}

/// A 16-bit PCM WAV: channels, length and loudest sample (0..1).
class _Wav {
  _Wav(File file) : bytes = file.readAsBytesSync();

  final List<int> bytes;

  int _u32(int at) => bytes[at] | bytes[at + 1] << 8 | bytes[at + 2] << 16 | bytes[at + 3] << 24;
  int get channels => bytes[22] | bytes[23] << 8;
  int get _rate => _u32(24);
  int get _dataSize => _u32(40);

  double get seconds => _dataSize / (_rate * channels * 2);

  double get peak {
    var max = 0;
    for (var i = 44; i + 1 < 44 + _dataSize; i += 2) {
      var v = bytes[i] | bytes[i + 1] << 8;
      if (v >= 0x8000) v -= 0x10000;
      if (v.abs() > max) max = v.abs();
    }
    return max / 32768;
  }
}
