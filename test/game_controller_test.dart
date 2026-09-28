import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/scoring.dart';

import 'helpers.dart';

const fullRun = [('m01', 'b'), ('m02', 'stone'), ('m03', '417'), ('m04', 'c'), ('m05', 'LM-EP01-PALACE')];

void main() {
  late ProviderContainer container;
  late DateTime clock;
  GameController ctrl() => container.read(gameControllerProvider.notifier);
  GameProgress state() => container.read(gameControllerProvider);
  final m = {for (final x in episode01.allMissions) x.id: x};

  setUp(() async {
    clock = DateTime(2026, 9, 28, 10);
    GameController.now = () => clock;
    container = ProviderContainer(overrides: await testOverrides());
  });
  tearDown(() {
    container.dispose();
    GameController.now = DateTime.now;
  });

  group('detective name', () {
    test('is trimmed and upper-cased', () {
      expect(ctrl().registerDetective('  minyoung  '), isNull);
      expect(state().detectiveName, 'MINYOUNG');
    });

    test('rejects empty, too long and unsafe input', () {
      expect(GameController.validateName(''), isNotNull);
      expect(GameController.validateName('   '), isNotNull);
      expect(GameController.validateName('A' * (AppConstants.nameMaxLength + 1)), isNotNull);
      expect(GameController.validateName('<script>'), isNotNull);
      expect(GameController.validateName('민영'), isNull);
      expect(ctrl().registerDetective('<b>x</b>'), isNotNull);
      expect(state().hasDetective, isFalse);
    });
  });

  test('missions unlock strictly in order', () {
    ctrl().registerDetective('Kim');
    ctrl().startInvestigation();
    final e = episode01;
    expect(state().isUnlocked(e, 'm01'), isTrue);
    expect(state().isUnlocked(e, 'm02'), isFalse);
    expect(state().isUnlocked(e, 'final'), isFalse);

    // Skipping ahead is refused and not recorded.
    expect(ctrl().submitAnswer(m['m03']!, '417').result, SubmitResult.locked);
    expect(state().attempts, isEmpty);

    expect(ctrl().submitAnswer(m['m01']!, 'b').result, SubmitResult.correct);
    expect(state().isUnlocked(e, 'm02'), isTrue);
    expect(state().currentMission(e)!.id, 'm02');
    expect(container.read(recentUnlockProvider), 'm02');
  });

  test('hints open one at a time, at most two, and reduce the bonus', () {
    ctrl().registerDetective('Kim');
    ctrl().startInvestigation();
    expect(ctrl().useHint(m['m01']!), 1);
    expect(ctrl().useHint(m['m01']!), 2);
    expect(ctrl().useHint(m['m01']!), 2, reason: 'no third hint');
    expect(state().totalHints, 2);

    ctrl().submitAnswer(m['m01']!, 'b');
    expect(XpBreakdown.of(m['m01']!, state()).noHintBonus, 0);
    expect(ctrl().useHint(m['m01']!), 2, reason: 'no hints after solving');
  });

  test('XP: +100 base, +50 without hints, +20 when fast', () {
    ctrl().registerDetective('Kim');
    ctrl().startInvestigation();

    ctrl().markMissionStarted('m01');
    clock = clock.add(const Duration(seconds: 40));
    ctrl().submitAnswer(m['m01']!, 'b');
    final fast = XpBreakdown.of(m['m01']!, state());
    expect((fast.base, fast.noHintBonus, fast.speedBonus, fast.total), (100, 50, 20, 170));

    ctrl().markMissionStarted('m02');
    ctrl().useHint(m['m02']!);
    clock = clock.add(const Duration(minutes: 5));
    ctrl().submitAnswer(m['m02']!, 'stone');
    final slow = XpBreakdown.of(m['m02']!, state());
    expect((slow.base, slow.noHintBonus, slow.speedBonus), (100, 25, 0));
    expect(state().solveSeconds['m02'], 300);
  });

  test('records wrong answers, clues, evidence and looked-up words', () {
    ctrl().registerDetective('Kim');
    ctrl().startInvestigation();
    expect(ctrl().submitAnswer(m['m01']!, 'a').result, SubmitResult.tryAgain);
    expect(ctrl().submitAnswer(m['m01']!, 'b').result, SubmitResult.correct);
    ctrl().lookUpWord('Museum');
    ctrl().lookUpWord('museum');

    expect(state().attempts['m01'], 2);
    expect(state().wrongAnswers['m01'], 1);
    expect(state().collectedClues(episode01).single.value, '9');
    expect(state().collectedEvidence(episode01).single.name, 'Old Letter');
    expect(state().lookedUpWords, ['museum']);
  });

  test('badges are awarded once, in order, as the case progresses', () {
    ctrl().registerDetective('Kim');
    ctrl().startInvestigation();
    ctrl().markMissionStarted('m01');
    final first = ctrl().submitAnswer(m['m01']!, 'b');
    expect(first.newBadges, containsAll([GameBadge.firstClue, GameBadge.sharpEyes, GameBadge.quickThinker]));

    for (final (id, answer) in fullRun.skip(1)) {
      final out = ctrl().submitAnswer(m[id]!, answer);
      if (id == 'm03') expect(out.newBadges, [GameBadge.puzzleSolver]);
      if (id == 'm05') expect(out.newBadges, [GameBadge.londonExplorer]);
    }
    final last = ctrl().submitAnswer(m['final']!, '7924');
    expect(last.newBadges, [GameBadge.masterDetective]);
    expect(state().badgeIds.toSet(), {for (final b in GameBadge.values) b.name});
  });

  test('full run solves the case and survives an app restart', () async {
    ctrl().registerDetective('Kim');
    ctrl().startInvestigation();
    for (final (id, answer) in fullRun) {
      expect(ctrl().submitAnswer(m[id]!, answer).result, SubmitResult.correct, reason: id);
    }
    expect(state().allMissionsDone(episode01), isTrue);
    expect(ctrl().submitAnswer(m['final']!, '9472').result, SubmitResult.tryAgain,
        reason: 'clue order alone is not the code');
    expect(ctrl().submitAnswer(m['final']!, '7924').result, SubmitResult.correct);
    expect(state().isCaseSolved, isTrue);
    expect(state().currentMission(episode01), isNull);

    // "Restart the app": a new container reading the same storage.
    final prefs = container.read(sharedPreferencesProvider);
    final restarted = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      currentEpisodeProvider.overrideWithValue(episode01),
    ]);
    addTearDown(restarted.dispose);
    final restored = restarted.read(gameControllerProvider);
    expect(restored.detectiveName, 'KIM');
    expect(restored.completedMissionIds, state().completedMissionIds);
    expect(restored.badgeIds, state().badgeIds);
    expect(restored.isCaseSolved, isTrue);
    expect(restored.startedAt, state().startedAt);
  });

  test('play again keeps the name; reset clears everything', () async {
    ctrl().registerDetective('Kim');
    ctrl().startInvestigation();
    ctrl().submitAnswer(m['m01']!, 'b');
    ctrl().playAgain();
    expect(state().detectiveName, 'KIM');
    expect(state().completedMissionIds, isEmpty);
    expect(state().badgeIds, isEmpty);
    expect(state().introSeen, isFalse);

    await ctrl().resetAll();
    expect(state().hasDetective, isFalse);
    expect(container.read(sharedPreferencesProvider).getString(AppConstants.progressStorageKey), isNull);
  });

  test('corrupted storage falls back to a fresh game', () async {
    final c = ProviderContainer(
      overrides: await testOverrides(prefs: {AppConstants.progressStorageKey: '{not json'}),
    );
    addTearDown(c.dispose);
    expect(c.read(gameControllerProvider).hasDetective, isFalse);
  });

  group('play time counts only while the app is in the foreground', () {
    void advance(Duration d) => clock = clock.add(d);
    const tenMinutes = Duration(minutes: 10);

    /// "Restart the app" at the current clock: a new container, same storage.
    GameController restart() {
      final prefs = container.read(sharedPreferencesProvider);
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentEpisodeProvider.overrideWithValue(episode01),
      ]);
      addTearDown(c.dispose);
      c.read(gameControllerProvider);
      return c.read(gameControllerProvider.notifier);
    }

    setUp(() {
      ctrl().registerDetective('Kim');
      advance(const Duration(minutes: 3)); // registering is not case time
      ctrl().startInvestigation();
    });

    test('A: 10 minutes of play, then the app is closed', () {
      advance(tenMinutes);
      expect(ctrl().playTime, tenMinutes);
      ctrl().pausePlayClock();
      expect(state().playMillis, tenMinutes.inMilliseconds, reason: 'saved when the app closes');
      expect(restart().playTime, tenMinutes);
    });

    test('B: an hour in the background is not counted', () {
      advance(tenMinutes);
      ctrl().pausePlayClock();
      advance(const Duration(hours: 1));
      expect(ctrl().playTime, tenMinutes, reason: 'clock is stopped in the background');
      ctrl().resumePlayClock();
      expect(ctrl().playTime, tenMinutes);
      advance(const Duration(minutes: 2));
      expect(ctrl().playTime, const Duration(minutes: 12));
    });

    test('C: closed overnight, reopened the next day', () {
      advance(tenMinutes);
      ctrl().pausePlayClock();
      advance(const Duration(hours: 23, minutes: 50));
      final reopened = restart();
      expect(reopened.playTime, tenMinutes);
      advance(const Duration(minutes: 5));
      expect(reopened.playTime, const Duration(minutes: 15));
    });

    test('C: killed without a background event loses only the time since the last save', () {
      advance(const Duration(minutes: 8));
      ctrl().lookUpWord('crown'); // any action saves the clock
      advance(const Duration(minutes: 2));
      advance(const Duration(days: 1)); // app killed, reopened next day
      expect(restart().playTime, const Duration(minutes: 8));
    });

    test('D: many background / foreground switches add up correctly', () {
      for (var i = 0; i < 4; i++) {
        advance(const Duration(minutes: 2));
        ctrl().pausePlayClock();
        ctrl().pausePlayClock(); // repeated events are harmless
        advance(const Duration(minutes: 30));
        ctrl().resumePlayClock();
        ctrl().resumePlayClock();
      }
      advance(const Duration(minutes: 2));
      expect(ctrl().playTime, tenMinutes);
    });

    test('speed bonus ignores time spent in the background', () {
      ctrl().markMissionStarted('m01');
      advance(const Duration(minutes: 1));
      ctrl().pausePlayClock();
      advance(const Duration(hours: 2));
      ctrl().resumePlayClock();
      advance(const Duration(seconds: 30));
      ctrl().submitAnswer(m['m01']!, 'b');
      expect(state().solveSeconds['m01'], 90);
      expect(XpBreakdown.of(m['m01']!, state()).speedBonus, AppConstants.speedBonusXp);
    });

    test('the clock stops when the case is solved', () {
      for (final (id, answer) in fullRun) {
        advance(const Duration(minutes: 1));
        ctrl().submitAnswer(m[id]!, answer);
      }
      advance(const Duration(minutes: 1));
      ctrl().submitAnswer(m['final']!, '7924');
      expect(ctrl().playTime, const Duration(minutes: 6));
      advance(const Duration(hours: 1));
      expect(ctrl().playTime, const Duration(minutes: 6));
      expect(state().elapsed(), const Duration(minutes: 6), reason: 'the reports read the saved value');
      expect(restart().playTime, const Duration(minutes: 6));
    });
  });

  test('saves from before play time was tracked', () {
    final start = DateTime(2026, 9, 1, 10);
    final inProgress = GameProgress.fromJson({'detectiveName': 'KIM', 'introSeen': true, 'startedAt': start.toIso8601String()});
    expect(inProgress.playMillis, 0, reason: 'closed time was never recorded, so counting restarts');

    final solved = GameProgress.fromJson({
      'detectiveName': 'KIM',
      'startedAt': start.toIso8601String(),
      'completedAt': start.add(const Duration(minutes: 40)).toIso8601String(),
    });
    expect(solved.playMillis, isNull);
    expect(solved.elapsed(), const Duration(minutes: 40), reason: 'old results keep their time');
  });

  test('older saves (one hint per mission) are migrated', () {
    final old = GameProgress.fromJson({
      'detectiveName': 'KIM',
      'completedMissionIds': ['m01'],
      'hintMissionIds': ['m01'],
    });
    expect(old.hintsFor('m01'), 1);
    expect(old.totalHints, 1);
  });
}
