import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';

import 'helpers.dart';

void main() {
  group('run fields in the case save', () {
    test('a save from before runs reads as run 0 and keeps its shape', () {
      final old = {'detectiveName': 'KIM', 'introSeen': true, 'completedMissionIds': ['m01']};
      final p = GameProgress.fromJson(old);
      expect(p.runId, isNull);
      expect(p.runSeq, 0);
      expect(p.rev, 0);
      final json = p.toJson();
      expect(json.containsKey('runId'), isFalse);
      expect(json.containsKey('runSeq'), isFalse);
      expect(json.containsKey('rev'), isFalse);
    });

    test('round trip; unreadable values fall back to 0 / none', () {
      const p = GameProgress(detectiveName: 'KIM', runId: 'abc123', runSeq: 2, rev: 7);
      final back = GameProgress.fromJson(jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>);
      expect((back.runId, back.runSeq, back.rev), ('abc123', 2, 7));
      final bad = GameProgress.fromJson({'runId': '', 'runSeq': -3, 'rev': 'x'});
      expect((bad.runId, bad.runSeq, bad.rev), (null, 0, 0));
    });
  });

  group('the controller records the run', () {
    late DateTime clock;
    setUp(() {
      clock = DateTime(2026, 10, 13, 9);
      GameController.now = () => clock;
    });
    tearDown(() => GameController.now = DateTime.now);

    test('the first save gets a run; only real changes count a revision', () async {
      final c = ProviderContainer(overrides: await testOverrides());
      addTearDown(c.dispose);
      final game = c.read(gameControllerProvider.notifier);
      game.registerDetective('ANNA');
      final run = c.read(gameControllerProvider).runId;
      expect(run, isNotNull);
      expect(c.read(gameControllerProvider).rev, 0);

      game.startInvestigation();
      expect(c.read(gameControllerProvider).rev, 1);

      // Nothing changed (no time passed): saving again counts nothing.
      game.pausePlayClock();
      game.resumePlayClock();
      game.lookUpWord('clock');
      game.lookUpWord('clock');
      expect(c.read(gameControllerProvider).rev, 2, reason: 'one word looked up, once');

      // Play time passing is a real change.
      clock = clock.add(const Duration(seconds: 5));
      game.pausePlayClock();
      expect(c.read(gameControllerProvider).rev, 3);
      expect(c.read(gameControllerProvider).runId, run, reason: 'the same run all along');

      final saved = jsonDecode(savedString(c.read(sharedPreferencesProvider), AppConstants.progressStorageKey)!);
      expect(saved['runId'], run);
      expect(saved['rev'], 3);
    });
  });
}
