import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/core/utils/audio_service.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/audio_scenes.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/widgets/game_button.dart';

import 'full_playthrough_test.dart' show tapText, wait;
import 'helpers.dart';
import 'mission_play.dart';

/// Audio Wave 1B (provisional, listening pending): London at night, the
/// casebook tap on the buttons that move the investigation on, and no
/// music yet (the Music API was not available: every theme stays silent).
void main() {
  final season = MockEpisodeRepository.bundled();
  Episode episode(String id) => season.firstWhere((e) => e.id == id);

  group('the files', () {
    test('London at night: a 30 s loop, its other candidate and both originals kept', () {
      final night = ambienceLoops[AmbienceBase.londonNight]!;
      expect(night.file, 'processed/amb_london_night_01.wav');
      final wav = _Wav(File('assets/sounds/${night.file}'));
      expect(wav.seconds, closeTo(30, 0.01), reason: 'the loop keeps its length');
      expect(wav.peak, inExclusiveRange(0.02, 0.99));
      for (final kept in [
        'processed/amb_london_night_02.wav',
        'generated/amb_london_night_01.wav',
        'generated/amb_london_night_02.wav',
      ]) {
        expect(File('assets/sounds/$kept').existsSync(), isTrue, reason: kept);
      }
    });

    test('the office keeps its rain; the street is another file', () {
      expect(ambienceLoops[AmbienceBase.officeRain]!.file, 'processed/office_night_rain_v2_01.wav');
      expect(ambienceLoops[AmbienceBase.londonNight]!.file, isNot(ambienceLoops[AmbienceBase.officeRain]!.file));
    });

    test('no music yet, and never a placeholder in the final or the closed case', () {
      expect(musicLoops, isEmpty, reason: 'MUSIC GENERATION BLOCKED: silence, not sound effects as music');
      expect(musicLoops[MusicTheme.finalMission], isNull);
      expect(musicLoops[MusicTheme.resolution], isNull);
    });

    test('the casebook tap: three takes of one tap, short, under the puzzle sounds', () {
      expect([for (final t in GameSound.uiTap.takes) t.file], [
        'processed/ui_tap_01.wav',
        'processed/ui_tap_02.wav',
        'processed/ui_tap_03.wav',
      ]);
      for (final t in GameSound.uiTap.takes) {
        final wav = _Wav(File('assets/sounds/${t.file}'));
        expect(wav.seconds, inInclusiveRange(0.06, 0.161), reason: '${t.file}: the tap and its body');
        expect(wav.peak, inExclusiveRange(0.3, 0.99), reason: t.file);
        expect(t.volume, lessThan(0.5), reason: '${t.file}: quieter than a puzzle sound');
        expect(File('assets/sounds/${t.file.replaceFirst('processed/', 'generated/')}').existsSync(), isTrue,
            reason: 'the original is kept');
      }
    });

    test('one tap, three firmnesses: primary over secondary over select', () {
      expect(TapRole.primary.volume, 1);
      expect(TapRole.secondary.volume, lessThan(TapRole.primary.volume));
      expect(TapRole.select.volume, lessThan(TapRole.secondary.volume));
    });
  });

  group('London at night in the scenes', () {
    AudioScene sceneAt(String path, {required Episode e, String? id, bool begun = true}) => audioSceneFor(
      path: path,
      id: id,
      episode: e,
      progress: const GameProgress(detectiveName: 'T', introSeen: true),
      seasonBegun: begun,
    )!;

    test('the season cover and the opening are heard as London at night, one bed throughout', () {
      final e = episode('ep01');
      final audio = MockAudioService()
        ..setScene(sceneAt(Routes.season, e: e, begun: false))
        ..setScene(sceneAt(Routes.prologue, e: e));
      expect(audio.ambienceStarts, [AmbienceBase.londonNight]);
      expect(loopOf(AudioLayer.ambience, audio.ambience), isNotNull, reason: 'now heard');
    });

    // The market hall (M1) is inside since mapping 2.0: the street carries
    // on from the fountain (M2) through its story.
    test('Case 06 at night: at the fountain and through its story, the street does not start again', () {
      final e = episode('ep06');
      final audio = MockAudioService()
        ..setScene(sceneAt(Routes.mission('ep06_m2'), e: e, id: 'ep06_m2'))
        ..setScene(sceneAt(Routes.story('ep06_m2'), e: e, id: 'ep06_m2'));
      expect(audio.ambienceStarts, [AmbienceBase.londonNight]);
    });
  });

  group('GameButton and its tap', () {
    Future<MockAudioService> pump(WidgetTester t, Widget button, {bool on = true}) async {
      final audio = MockAudioService(isEnabled: () => on);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(audio: audio),
        child: MaterialApp(home: Scaffold(body: Center(child: button))),
      ));
      return audio;
    }

    for (final role in TapRole.values) {
      testWidgets('${role.name}: the casebook tap at its level, then the action', (t) async {
        var pressed = 0;
        final audio = await pump(t, GameButton(label: 'GO', tap: role, onPressed: () => pressed++));
        await t.tap(find.text('GO'));
        expect(audio.played, [GameSound.uiTap]);
        final (take, volume) = audio.takes.single;
        expect(volume, closeTo(take.volume * role.volume, 1e-9));
        expect(pressed, 1);
      });
    }

    testWidgets('no tap given: silent', (t) async {
      var pressed = 0;
      final audio = await pump(t, GameButton(label: 'BACK', onPressed: () => pressed++));
      await t.tap(find.text('BACK'));
      expect(audio.played, isEmpty);
      expect(pressed, 1);
    });

    testWidgets('disabled: no tap', (t) async {
      final audio = await pump(t, const GameButton(label: 'GO', tap: TapRole.primary, onPressed: null));
      await t.tap(find.text('GO'));
      expect(audio.played, isEmpty);
    });

    testWidgets('sound off: the action, no tap', (t) async {
      var pressed = 0;
      final audio = await pump(t, GameButton(label: 'GO', tap: TapRole.primary, onPressed: () => pressed++), on: false);
      await t.tap(find.text('GO'));
      expect(audio.played, isEmpty);
      expect(pressed, 1);
    });
  });

  group('the tap in play', () {
    const phone = Size(390, 844);
    int count(MockAudioService a, GameSound s) => a.played.where((p) => p == s).length;

    testWidgets('a mission: INVESTIGATE and SOLVE THE PUZZLE tap; the envelope and CHECK ANSWER are their own sound',
        (t) async {
      final audio = MockAudioService();
      t.view.physicalSize = phone * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      late WidgetRef ref;
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(audio: audio, prefs: {
          AppConstants.progressStorageKey:
              jsonEncode(GameProgress(detectiveName: 'T', introSeen: true, startedAt: DateTime.now()).toJson()),
          AppConstants.seasonStorageKey: jsonEncode(const SeasonProgress(activeEpisodeId: 'ep01').toJson()),
        }),
        child: Consumer(builder: (context, r, _) {
          ref = r;
          return const LondonMysteryApp();
        }),
      ));
      await wait(t, const Duration(milliseconds: 600));
      ref.read(routerProvider).go(Routes.mission('m01'));
      await wait(t, const Duration(milliseconds: 1200));
      audio.played.clear();
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 600));
      expect(audio.played, [GameSound.uiTap]);
      await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1200));
      expect(audio.played, [GameSound.uiTap, GameSound.envelopeOpen], reason: 'the envelope: no tap with it');
      await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 600));
      expect(audio.played, [GameSound.uiTap, GameSound.envelopeOpen, GameSound.uiTap]);
      audio.played.clear();
      await tapText(t, 'The Natural History Museum (dinosaur bones)', after: const Duration(milliseconds: 200));
      await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 600));
      expect(audio.played, [GameSound.puzzleWrong], reason: 'CHECK ANSWER: its result alone');
      expect(count(audio, GameSound.uiTap), 0);
    });

    testWidgets('TO THE MAP taps; the story before it stays quiet', (t) async {
      final audio = MockAudioService();
      final play = MissionPlay(audio: audio);
      final m = await play.openPuzzle(t, phone, 'm01');
      await play.solve(t, m);
      await wait(t, const Duration(milliseconds: 2500));
      await tapText(t, 'CONTINUE', after: const Duration(milliseconds: 900));
      audio.played.clear();
      await t.tapAt(const Offset(200, 400)); // all of the story at once
      await wait(t, const Duration(milliseconds: 900));
      expect(audio.played.where((s) => s != GameSound.typewriterKey), isEmpty, reason: 'story taps are quiet');
      await tapText(t, 'TO THE MAP', after: const Duration(milliseconds: 600));
      expect(count(audio, GameSound.uiTap), 1);
      expect(play.path(), Routes.map);
      expect(play.ref.read(audioServiceProvider), same(audio));
    });
  });
}

/// A 16-bit PCM WAV: its length and loudest sample (0..1).
class _Wav {
  _Wav(File file) : bytes = file.readAsBytesSync();

  final List<int> bytes;

  int _u32(int at) => bytes[at] | bytes[at + 1] << 8 | bytes[at + 2] << 16 | bytes[at + 3] << 24;
  int get _channels => bytes[22] | bytes[23] << 8;
  int get _rate => _u32(24);
  int get _dataSize => _u32(40);

  double get seconds => _dataSize / (_rate * _channels * 2);

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
