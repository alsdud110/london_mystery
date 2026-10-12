import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/core/utils/audio_service.dart';
import 'package:london_mystery/data/mock/season1/season1_sounds.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/widgets/typewriter_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';
import 'mission_play.dart';

/// The sound prototype: which sound plays at which moment of play, its
/// takes, and the office ambience.
void main() {
  final season = MockEpisodeRepository.bundled();
  Mission mission(String id) => [for (final e in season) ...e.allMissions].firstWhere((m) => m.id == id);

  int count(MockAudioService a, GameSound s) => a.played.where((p) => p == s).length;

  group('the sound service', () {
    test('a sound with several takes never plays the same take twice in a row, and uses them all', () {
      final audio = MockAudioService(random: math.Random(7));
      for (final sound in GameSound.values.where((s) => s.takes.length > 1)) {
        audio.takes.clear();
        for (var i = 0; i < 300; i++) {
          audio.play(sound);
        }
        final files = [for (final (take, _) in audio.takes) take.file];
        for (var i = 1; i < files.length; i++) {
          expect(files[i], isNot(files[i - 1]), reason: '${sound.name} repeated a take');
        }
        expect(files.toSet(), {for (final t in sound.takes) t.file}, reason: '${sound.name}: every take is heard');
      }
    });

    test('a take plays at its own level, times the volume asked for', () {
      final audio = MockAudioService();
      audio.play(GameSound.puzzleWrong, volume: 0.5);
      final (take, volume) = audio.takes.single;
      expect(volume, closeTo(take.volume * 0.5, 1e-9));
    });

    test('every take and loop is a bundled file', () {
      final files = [
        for (final s in GameSound.values) ...s.takes,
        for (final loops in [musicLoops, ambienceLoops, accentLoops]) ...loops.values,
      ];
      for (final f in files) {
        expect(File('assets/${f.assetPath}').existsSync(), isTrue, reason: f.file);
        expect(f.volume, inInclusiveRange(0, 1), reason: f.file);
      }
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final f in files) {
        expect(pubspec, contains('- assets/${f.assetPath}\n'), reason: '${f.file}: listed for the app');
      }
    });

    test('sound off: no sound and no ambience; on again: the ambience starts', () {
      var on = false;
      final audio = MockAudioService(isEnabled: () => on);
      for (final s in GameSound.values) {
        audio.play(s);
      }
      audio.setScene(const AudioScene(ambienceBase: AmbienceBase.officeRain));
      expect(audio.played, isEmpty);
      expect(audio.ambience, isNull);
      expect(audio.ambienceStarts, isEmpty);

      on = true;
      audio.refresh();
      expect(audio.ambience, AmbienceBase.officeRain);
      audio.play(GameSound.paperPlace);
      expect(audio.played, [GameSound.paperPlace]);
    });

    test('the same ambience keeps running; the background stops it, coming back starts it again', () {
      final audio = MockAudioService();
      audio.setScene(const AudioScene(ambienceBase: AmbienceBase.officeRain));
      audio.setScene(const AudioScene(ambienceBase: AmbienceBase.officeRain));
      expect(audio.ambienceStarts, hasLength(1));

      audio.setForeground(false);
      expect(audio.ambience, isNull);
      audio.setForeground(true);
      expect(audio.ambience, AmbienceBase.officeRain);
      expect(audio.ambienceStarts, hasLength(2));

      audio.setScene(AudioScene.silence);
      expect(audio.ambience, isNull);
    });
  });

  group('the takes after listening', () {
    List<String> files(GameSound s) => [for (final t in s.takes) t.file];

    test('the envelope and the discovery cue are the second recordings', () {
      expect(files(GameSound.envelopeOpen), everyElement(contains('envelope_open_v2_')));
      expect(files(GameSound.envelopeOpen), hasLength(3));
      expect(files(GameSound.puzzleCorrect), everyElement(contains('puzzle_correct_v2_')));
      expect(files(GameSound.puzzleCorrect), hasLength(3));
    });

    test('paper: only take 02 for now; the other takes are kept on disk', () {
      expect(files(GameSound.paperPlace), ['generated/paper_place_02.wav']);
      final audio = MockAudioService();
      for (var i = 0; i < 5; i++) {
        audio.play(GameSound.paperPlace);
      }
      expect({for (final (take, _) in audio.takes) take.file}, {'generated/paper_place_02.wav'});
      for (final n in ['01', '03']) {
        expect(File('assets/sounds/generated/paper_place_$n.wav').existsSync(), isTrue);
      }
    });

    test('the dial clicks are trimmed copies: short, valid, four takes', () {
      expect(files(GameSound.lockDialClick), hasLength(4));
      for (final f in files(GameSound.lockDialClick)) {
        expect(f, startsWith('processed/'));
        final wav = _Wav(File('assets/sounds/$f'));
        expect(wav.seconds, inInclusiveRange(0.08, 0.2), reason: f);
        expect(wav.peak, greaterThan(0.3), reason: '$f: the click itself is kept');
        expect(File('assets/sounds/${f.replaceFirst('processed/', 'generated/')}').existsSync(), isTrue,
            reason: 'the original is kept');
      }
    });

    test('processed copies never clip; the rain is heard; typing keys are short', () {
      for (final f in Directory('assets/sounds/processed').listSync().whereType<File>()) {
        expect(_Wav(f).peak, lessThan(0.99), reason: f.path);
      }
      final rain = _Wav(File('assets/sounds/${ambienceLoops[AmbienceBase.officeRain]!.file}'));
      expect(rain.seconds, closeTo(30, 0.01), reason: 'the loop keeps its length');
      expect(rain.peak, greaterThan(0.25), reason: 'raised from -26 dBFS');
      for (final t in GameSound.typewriterKey.takes) {
        // One whole keystroke (mechanism, strike, body, decay): never a
        // second keystroke.
        expect(_Wav(File('assets/sounds/${t.file}')).seconds, inInclusiveRange(0.08, 0.201), reason: t.file);
      }
    });

    test('the heavier typewriter keys and the sparse rain are the ones played', () {
      expect([for (final t in GameSound.typewriterKey.takes) t.file], everyElement(contains('typewriter_key_v4_')));
      expect(GameSound.typewriterKey.takes, hasLength(4));
      expect(ambienceLoops[AmbienceBase.officeRain]!.file, 'processed/office_night_rain_v2_01.wav');
      for (final kept in [
        'processed/office_night_rain_v2_02.wav',
        'processed/office_night_rain.wav',
        for (var i = 1; i <= 4; i++) 'processed/typewriter_key_0$i.wav',
        for (var i = 1; i <= 4; i++) 'processed/typewriter_key_v2_0$i.wav',
        for (var i = 1; i <= 4; i++) 'processed/typewriter_key_v3_0$i.wav',
      ]) {
        expect(File('assets/sounds/$kept').existsSync(), isTrue, reason: kept);
      }
    });

    test('the typewriter sits under the puzzle sounds', () {
      for (final t in GameSound.typewriterKey.takes) {
        expect(t.volume, lessThan(0.5), reason: t.file);
      }
    });
  });

  group('the typewriter', () {
    Future<MockAudioService> type(WidgetTester t, String text, {bool Function()? isEnabled, bool skip = false}) async {
      final audio = MockAudioService(isEnabled: isEnabled);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(audio: audio),
        child: MaterialApp(
          home: Scaffold(body: _Line(text: text, skip: skip)),
        ),
      ));
      return audio;
    }

    int keys(MockAudioService a) => a.played.where((s) => s == GameSound.typewriterKey).length;

    testWidgets('keys sound while a line types, about every second letter, never two in a row', (t) async {
      const text = 'The Crown is missing tonight';
      final audio = await type(t, text);
      final perTick = <int>[];
      for (var i = 0; i < text.length + 4; i++) {
        final before = keys(audio);
        await t.pump(const Duration(milliseconds: 45));
        perTick.add(keys(audio) - before);
      }
      expect(keys(audio), greaterThan(3));
      // At most one key per 70 ms: one per two characters typed (45 ms each).
      expect(keys(audio), lessThanOrEqualTo((text.length / 2).ceil()), reason: 'throttled');
      for (var i = 1; i < perTick.length; i++) {
        expect(perTick[i] > 0 && perTick[i - 1] > 0, isFalse, reason: 'no keys 45 ms apart');
      }
      expect(audio.stopped, contains(GameSound.typewriterKey), reason: 'cut off when the line is whole');
    });

    testWidgets('spaces only: silent', (t) async {
      final audio = await type(t, '          ');
      await t.pump(const Duration(seconds: 1));
      expect(audio.played, isEmpty);
    });

    testWidgets('punctuation is a small rest: no key on a mark', (t) async {
      final audio = await type(t, '... , ! ? ... ; : ...');
      await t.pump(const Duration(seconds: 2));
      expect(audio.played, isEmpty);
    });

    testWidgets('once the line is whole: no more keys', (t) async {
      final audio = await type(t, 'Big Ben has stopped');
      await t.pump(const Duration(seconds: 2));
      final after = keys(audio);
      await t.pump(const Duration(seconds: 2));
      expect(keys(audio), after);
    });

    testWidgets('tapped to finish (skip): silent from then on, and cut off', (t) async {
      const text = 'Something strange happened at the Royal Archive';
      final audio = MockAudioService();
      final overrides = await testOverrides(audio: audio);
      Widget line(bool skip) => ProviderScope(
            overrides: overrides,
            child: MaterialApp(home: Scaffold(body: _Line(text: text, skip: skip))),
          );
      await t.pumpWidget(line(false));
      for (var i = 0; i < 8; i++) {
        await t.pump(const Duration(milliseconds: 45));
      }
      expect(keys(audio), greaterThan(0));
      await t.pumpWidget(line(true));
      await t.pump();
      final atSkip = keys(audio);
      expect(audio.stopped, contains(GameSound.typewriterKey));
      await t.pump(const Duration(seconds: 3));
      expect(keys(audio), atSkip);
      expect(find.text(text, findRichText: true), findsOneWidget);
    });

    testWidgets('skipped from the start (a line read again): silent', (t) async {
      final audio = await type(t, 'The thief left a trail of clues', skip: true);
      await t.pump(const Duration(seconds: 2));
      expect(audio.played, isEmpty);
    });

    testWidgets('sound off: silent', (t) async {
      final audio = await type(t, 'You have been chosen as a detective', isEnabled: () => false);
      await t.pump(const Duration(seconds: 3));
      expect(audio.played, isEmpty);
    });

    testWidgets('in the background: silent, and what was sounding is cut off', (t) async {
      final audio = await type(t, 'London, early in the morning, is too quiet');
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 45));
      }
      expect(keys(audio), greaterThan(0));
      audio.setForeground(false);
      final at = keys(audio);
      expect(audio.stopped, contains(GameSound.typewriterKey));
      await t.pump(const Duration(seconds: 3));
      expect(keys(audio), at);
    });

    testWidgets('a dialog over the story: the typing is not heard', (t) async {
      final audio = await type(t, 'Inside, there is a letter with a black wax seal');
      showDialog<void>(context: t.element(find.byType(_Line)), builder: (_) => const Text('a dialog'));
      await t.pump();
      final at = keys(audio);
      await t.pump(const Duration(seconds: 3));
      expect(keys(audio), at);
    });

    testWidgets('the story intro types with keys; a tap finishes the line and the keys stop', (t) async {
      final audio = MockAudioService();
      await _pumpApp(t, audio, {
        AppConstants.progressStorageKey: _progress(),
        AppConstants.seasonStorageKey: jsonEncode(const SeasonProgress(activeEpisodeId: 'ep01').toJson()),
      });
      _router(t).go(Routes.intro);
      await wait(t, const Duration(milliseconds: 900));
      expect(keys(audio), greaterThan(0), reason: 'London, 10:42 PM... is typing');
      await t.tapAt(const Offset(200, 400));
      await t.pump();
      final at = keys(audio);
      await t.pump(const Duration(milliseconds: 400)); // the pause before the next line
      expect(keys(audio), at, reason: 'the line is whole');
    });
  });

  group('Season 1 sound data', () {
    test('only real locks open with the padlock', () {
      expect(season1LockMissions, {'m03', 'ep05_m3', 'ep08_m3'});
      for (final id in season1LockMissions) {
        expect(mission(id).isFinal, isFalse, reason: id);
      }
    });

    test('order puzzles: paper laid down, the dial turned, or quiet steps', () {
      expect(sequenceTouchOf(mission('ep07_m3')), SequenceTouch.paper);
      expect(sequenceTouchOf(mission('ep10_m2')), SequenceTouch.paper);
      expect(sequenceTouchOf(mission('ep10_final')), SequenceTouch.paper);
      expect(sequenceTouchOf(mission('ep05_m2')), SequenceTouch.dial);
      expect(sequenceTouchOf(mission('ep03_m3')), SequenceTouch.none);
      for (final id in [...season1PaperSequences, ...season1DialSequences]) {
        expect(mission(id).type, MissionType.sequence, reason: id);
      }
    });
  });

  group('sounds in play', () {
    const phone = Size(390, 844);

    testWidgets('the envelope sounds the moment it is tapped, with the seal cracking', (t) async {
      final audio = MockAudioService();
      await _pumpApp(t, audio, {
        AppConstants.progressStorageKey: _progress(introSeen: true),
        AppConstants.seasonStorageKey: jsonEncode(const SeasonProgress(activeEpisodeId: 'ep01').toJson()),
      });
      _router(t).go(Routes.mission('m01'));
      await wait(t, const Duration(milliseconds: 1200));
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 600));
      expect(audio.played, [GameSound.uiTap], reason: 'INVESTIGATE taps the casebook, nothing more');
      audio.played.clear();

      await reveal(t, find.text('TAP TO OPEN'));
      await t.tap(find.text('TAP TO OPEN'));
      await t.pump(const Duration(milliseconds: 16));
      expect(audio.played, [GameSound.envelopeOpen], reason: 'with the tap, not after the letter is open');
      expect(find.text('TAP TO OPEN'), findsOneWidget, reason: 'the envelope is still opening');

      await wait(t, const Duration(milliseconds: 1200));
      expect(audio.played, [GameSound.envelopeOpen], reason: 'once');
    });

    testWidgets('a wrong answer: not quite, with the shake', (t) async {
      final audio = MockAudioService();
      final play = MissionPlay(audio: audio);
      await play.openPuzzle(t, phone, 'm01');
      audio.played.clear();
      await tapText(t, 'The Natural History Museum (dinosaur bones)', after: const Duration(milliseconds: 200));
      expect(audio.played, isEmpty, reason: 'choosing a card is quiet');
      await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 100));
      expect(audio.played, [GameSound.puzzleWrong]);
      expect(find.text('Not quite!'), findsOneWidget);
    });

    testWidgets('a regular puzzle solved: the discovery cue, no lock', (t) async {
      final audio = MockAudioService();
      final play = MissionPlay(audio: audio);
      final m = await play.openPuzzle(t, phone, 'm01');
      audio.played.clear();
      await play.solve(t, m);
      expect(count(audio, GameSound.puzzleCorrect), 1);
      expect(audio.played, isNot(contains(GameSound.padlockOpen)));
    });

    for (final id in season1LockMissions) {
      testWidgets('$id: the real lock opens instead of the discovery cue', (t) async {
        final audio = MockAudioService();
        final play = MissionPlay(audio: audio);
        final m = await play.openPuzzle(t, phone, id);
        audio.played.clear();
        await play.solve(t, m);
        expect(count(audio, GameSound.padlockOpen), 1);
        expect(audio.played, isNot(contains(GameSound.puzzleCorrect)));
        if (m.type == MissionType.numberCode) {
          expect(count(audio, GameSound.lockDialClick), m.answer.length, reason: 'one click a digit');
        }
      });
    }

    testWidgets('the evidence card on the Discovery Moment is laid down with a sound', (t) async {
      final audio = MockAudioService();
      final play = MissionPlay(audio: audio);
      final m = await play.openPuzzle(t, phone, 'm03'); // Pocket Watch is shown
      audio.played.clear();
      await play.solve(t, m);
      expect(audio.played, isNot(contains(GameSound.paperPlace)), reason: 'not before the card is down');
      await wait(t, const Duration(milliseconds: 1200));
      expect(count(audio, GameSound.paperPlace), 1);
      await wait(t, const Duration(milliseconds: 1500));
      expect(count(audio, GameSound.paperPlace), 1, reason: 'once');
    });

    testWidgets('a Discovery Moment without a card is quiet after the cue', (t) async {
      final audio = MockAudioService();
      final play = MissionPlay(audio: audio);
      final m = await play.openPuzzle(t, phone, 'm01');
      audio.played.clear();
      await play.solve(t, m);
      await wait(t, const Duration(milliseconds: 2500));
      expect(audio.played, [GameSound.puzzleCorrect]);
    });

    testWidgets('the evidence handed over in a story is laid down with a sound', (t) async {
      final audio = MockAudioService();
      final play = MissionPlay(audio: audio);
      final m = await play.openPuzzle(t, phone, 'ep06_m3'); // the Theatre Ticket
      await play.solve(t, m);
      await wait(t, const Duration(milliseconds: 2500));
      audio.played.clear();
      await tapText(t, 'CONTINUE', after: const Duration(milliseconds: 900));
      List<GameSound> notTyping() => audio.played.where((s) => s != GameSound.typewriterKey).toList();
      expect(notTyping(), [GameSound.uiTap], reason: 'CONTINUE taps the casebook; the story itself is quiet');
      await t.tapAt(const Offset(200, 400)); // all of the story at once
      await wait(t, const Duration(milliseconds: 900));
      expect(notTyping(), [GameSound.uiTap, GameSound.paperPlace], reason: 'the story tap adds no casebook tap');
    });

    testWidgets('paper order puzzle: each piece laid down; the dial door: each turn clicks', (t) async {
      final audio = MockAudioService();
      final play = MissionPlay(audio: audio);
      final pieces = await play.openPuzzle(t, phone, 'ep07_m3');
      audio.played.clear();
      await play.solve(t, pieces);
      expect(count(audio, GameSound.paperPlace), 3);
    });

    testWidgets('the dial door: four turns click, and the heavy door lock opens (Wave 2)', (t) async {
      final audio = MockAudioService();
      final play = MissionPlay(audio: audio);
      final door = await play.openPuzzle(t, phone, 'ep05_m2');
      audio.played.clear();
      await play.solve(t, door);
      expect(count(audio, GameSound.lockDialClick), 4);
      expect(count(audio, GameSound.lockOpenHeavy), 1);
      expect(audio.played, isNot(contains(GameSound.puzzleCorrect)));
      expect(audio.played, isNot(contains(GameSound.padlockOpen)));
    });

    testWidgets('footsteps order puzzle: the steps are quiet', (t) async {
      final audio = MockAudioService();
      final play = MissionPlay(audio: audio);
      final m = await play.openPuzzle(t, phone, 'ep03_m3');
      audio.played.clear();
      await play.solve(t, m);
      expect(audio.played, [GameSound.puzzleCorrect]);
    });

    testWidgets('the final locks: every turn of a dial clicks', (t) async {
      final audio = MockAudioService();
      await _pumpApp(t, audio, {
        AppConstants.progressStorageKey: _progress(introSeen: true, done: [for (final m in season.first.missions) m.id]),
        AppConstants.seasonStorageKey: jsonEncode(const SeasonProgress(activeEpisodeId: 'ep01').toJson()),
      });
      _router(t).go(Routes.finalMission);
      await wait(t, const Duration(milliseconds: 1200));
      audio.played.clear();
      final up = find.byTooltip('Lock 1 up');
      await reveal(t, up);
      await t.tap(up);
      await t.pump();
      await t.tap(find.byTooltip('Lock 2 down'));
      await t.pump();
      expect(audio.played, [GameSound.lockDialClick, GameSound.lockDialClick]);
    });

    testWidgets('CASE CLOSED: the stamp sounds as it meets the paper (1.26 s), once', (t) async {
      final audio = MockAudioService();
      await _pumpApp(t, audio, {
        AppConstants.progressStorageKey:
            _progress(introSeen: true, done: [for (final m in season.first.allMissions) m.id], solved: true),
        AppConstants.seasonStorageKey:
            jsonEncode(const SeasonProgress(activeEpisodeId: 'ep01', solvedEpisodeIds: ['ep01']).toJson()),
      });
      _router(t).go(Routes.solved);
      await wait(t, const Duration(milliseconds: 1150)); // lands at 0.45 × 2.8 s = 1260 ms
      expect(audio.played, isNot(contains(GameSound.caseStamp)), reason: 'still coming down');
      await wait(t, const Duration(milliseconds: 250));
      expect(count(audio, GameSound.caseStamp), 1);
      await wait(t, const Duration(milliseconds: 2000));
      expect(count(audio, GameSound.caseStamp), 1);
      expect(audio.played, isNot(contains(GameSound.puzzleCorrect)), reason: 'no success music');
    });

    testWidgets('the opening: ASSIGNED is stamped on the first case file', (t) async {
      final audio = MockAudioService();
      await _pumpApp(t, audio, {AppConstants.progressStorageKey: _progress()});
      _router(t).go(Routes.prologue);
      await wait(t, const Duration(milliseconds: 600));
      await tapText(t, 'SKIP ›', after: const Duration(milliseconds: 1500));
      audio.played.clear();
      await tapText(t, 'ACCEPT THE CASE', after: Duration.zero);
      await wait(t, const Duration(milliseconds: 750)); // lands at 0.8 × 1.1 s = 880 ms
      expect(audio.played, isEmpty);
      await wait(t, const Duration(milliseconds: 250));
      expect(audio.played, [GameSound.caseStamp]);
    });
  });

  group('the office ambience', () {
    testWidgets('runs through the office pages without starting again, and not elsewhere', (t) async {
      final audio = MockAudioService();
      await _pumpApp(t, audio, {
        AppConstants.progressStorageKey: _progress(introSeen: true),
        AppConstants.seasonStorageKey: jsonEncode(const SeasonProgress(activeEpisodeId: 'ep01').toJson()),
      });
      expect(audio.ambience, AmbienceBase.officeRain, reason: 'the title');
      for (final page in [Routes.register, Routes.season, Routes.episodes, Routes.start]) {
        _router(t).go(page);
        await wait(t, const Duration(milliseconds: 500));
        expect(audio.ambience, AmbienceBase.officeRain, reason: page);
      }
      expect(audio.ambienceStarts, hasLength(1), reason: 'never restarted between office pages');

      _router(t).go(Routes.map);
      await wait(t, const Duration(milliseconds: 500));
      expect(audio.ambience, AmbienceBase.londonNight, reason: 'the map is out in London (the case opened at night)');
      _router(t).go(Routes.episodes);
      await wait(t, const Duration(milliseconds: 500));
      expect(audio.ambience, AmbienceBase.officeRain);
      expect(audio.ambienceStarts.where((a) => a == AmbienceBase.officeRain), hasLength(2));
    });

    testWidgets('the season cover (before the season begins) is not the office', (t) async {
      final audio = MockAudioService();
      await _pumpApp(t, audio, {AppConstants.progressStorageKey: _progress()});
      expect(audio.ambience, AmbienceBase.officeRain);
      _router(t).go(Routes.season);
      await wait(t, const Duration(milliseconds: 500));
      expect(audio.ambience, AmbienceBase.londonNight, reason: 'its cover: London at night (no file yet)');
    });

    testWidgets('stops in the background and starts again on coming back', (t) async {
      final audio = MockAudioService();
      await _pumpApp(t, audio, {});
      expect(audio.ambience, AmbienceBase.officeRain);
      for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
        t.binding.handleAppLifecycleStateChanged(s);
      }
      await t.pump();
      expect(audio.ambience, isNull);
      for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
        t.binding.handleAppLifecycleStateChanged(s);
      }
      await t.pump();
      expect(audio.ambience, AmbienceBase.officeRain);
      expect(audio.ambienceStarts, hasLength(2));
    });
  });

  group('sound off', () {
    testWidgets('no sound and no ambience; switched on in the game, the ambience starts', (t) async {
      late MockAudioService audio;
      _phoneView(t);
      SharedPreferences.setMockInitialValues({
        AppConstants.soundEnabledKey: false,
        AppConstants.progressStorageKey: _progress(introSeen: true),
        AppConstants.seasonStorageKey: jsonEncode(const SeasonProgress(activeEpisodeId: 'ep01').toJson()),
      });
      final prefs = await SharedPreferences.getInstance();
      late WidgetRef ref;
      await t.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // The real wiring: the service asks the saved setting.
          audioServiceProvider.overrideWith((r) => audio = MockAudioService(isEnabled: () => r.read(soundEnabledProvider))),
        ],
        child: Consumer(builder: (context, r, _) {
          ref = r;
          return const LondonMysteryApp();
        }),
      ));
      await wait(t, const Duration(milliseconds: 600));
      expect(audio.ambience, isNull, reason: 'the title, sound off');

      ref.read(routerProvider).go(Routes.mission('m01'));
      await wait(t, const Duration(milliseconds: 1200));
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 600));
      await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1200));
      await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 600));
      await tapText(t, 'The Natural History Museum (dinosaur bones)', after: const Duration(milliseconds: 200));
      await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 600));
      expect(find.text('Not quite!'), findsOneWidget);
      expect(audio.played, isEmpty);
      expect(audio.ambienceStarts, isEmpty);

      ref.read(routerProvider).go(Routes.start);
      await wait(t, const Duration(milliseconds: 500));
      ref.read(soundEnabledProvider.notifier).toggle();
      await t.pump();
      expect(audio.ambience, AmbienceBase.officeRain);
    });
  });
}

/// A line typing out, as on the story pages.
class _Line extends StatelessWidget {
  const _Line({required this.text, required this.skip});

  final String text;
  final bool skip;

  @override
  Widget build(BuildContext context) =>
      Center(child: TypewriterText(text, skip: skip, style: const TextStyle(fontSize: 20)));
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
      final v = (bytes[i] | bytes[i + 1] << 8).toSigned(16).abs();
      if (v > max) max = v;
    }
    return max / 32768;
  }
}

/// A 390×844 phone.
void _phoneView(WidgetTester t) {
  t.view.physicalSize = const Size(390, 844) * 3;
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

String _progress({bool introSeen = false, List<String> done = const [], bool solved = false}) {
  final start = DateTime.now().subtract(const Duration(minutes: 5));
  return jsonEncode(GameProgress(
    detectiveName: 'MINYOUNG',
    introSeen: introSeen,
    completedMissionIds: done,
    startedAt: start,
    completedAt: solved ? start : null,
    playMillis: 0,
  ).toJson());
}

late WidgetRef _ref;

/// The app's router (of the app pumped by [_pumpApp]).
GoRouter _router(WidgetTester t) => _ref.read(routerProvider);

Future<void> _pumpApp(WidgetTester t, MockAudioService audio, Map<String, Object> prefs) async {
  _phoneView(t);
  await t.pumpWidget(ProviderScope(
    overrides: await testOverrides(prefs: prefs, audio: audio),
    child: Consumer(builder: (context, r, _) {
      _ref = r;
      return const LondonMysteryApp();
    }),
  ));
  await wait(t, const Duration(milliseconds: 600));
}
