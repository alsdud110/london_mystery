import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/scoring.dart';

import 'helpers.dart';

void main() {
  late ProviderContainer container;
  GameController ctrl() => container.read(gameControllerProvider.notifier);
  GameProgress state() => container.read(gameControllerProvider);
  Episode current() => container.read(currentEpisodeProvider);
  List<Episode> catalog() => container.read(episodeCatalogProvider);

  setUp(() async {
    container = ProviderContainer(overrides: await testOverrides());
  });
  tearDown(() => container.dispose());

  /// Plays the open case from the intro to the final case, with no mistakes.
  void solveCurrentCase() {
    final e = current();
    ctrl().startInvestigation();
    for (final m in e.allMissions) {
      ctrl().markMissionStarted(m.id);
      expect(ctrl().submitAnswer(m, m.answer).result, SubmitResult.correct, reason: m.id);
    }
    expect(state().isCaseSolved, isTrue, reason: e.id);
  }

  test('Case 01 is open; every later case is sealed until the one before is solved', () {
    ctrl().registerDetective('Kim');
    final ids = [for (final e in catalog()) e.id];
    expect(ids.first, 'ep01');
    for (final id in ids.skip(1)) {
      expect(ctrl().openEpisode(id), isFalse, reason: '$id is sealed');
    }
    expect(current().id, 'ep01', reason: 'a refused case does not open');

    for (var i = 0; i < ids.length; i++) {
      expect(ctrl().openEpisode(ids[i]), isTrue, reason: ids[i]);
      expect(current().id, ids[i]);
      expect(state().detectiveName, 'KIM', reason: 'the detective keeps their name');
      if (i + 1 < ids.length) expect(ctrl().openEpisode(ids[i + 1]), isFalse, reason: 'not yet');
      solveCurrentCase();
    }
    expect(container.read(seasonProvider).solvedEpisodeIds, ids);
  });

  test('each case keeps its own clues, evidence, XP and badges — no double awards', () {
    ctrl().registerDetective('Kim');
    solveCurrentCase();
    final ep01Save = container.read(sharedPreferencesProvider).getString(AppConstants.progressStorageKey);
    final ep01Xp = XpBreakdown.totalFor(current(), state());

    expect(ctrl().openEpisode('ep02'), isTrue);
    expect(state().completedMissionIds, isEmpty, reason: 'Case 02 starts fresh');
    solveCurrentCase();
    final e = current();
    final xp = XpBreakdown.totalFor(e, state());
    final badges = [...state().badgeIds];
    expect(badges, contains(GameBadge.clockWatcher.name));
    expect(badges.toSet(), hasLength(badges.length));
    expect(state().collectedEvidence(e), hasLength(e.allEvidence.length));

    // Answering a solved mission again changes nothing.
    for (final m in e.allMissions) {
      expect(ctrl().submitAnswer(m, m.answer).result, SubmitResult.correct);
    }
    expect(XpBreakdown.totalFor(e, state()), xp);
    expect(state().badgeIds, badges);
    expect(state().completedMissionIds, hasLength(e.allMissions.length));
    expect(state().collectedEvidence(e), hasLength(e.allEvidence.length));

    // Case 01 was not touched by playing Case 02.
    expect(container.read(sharedPreferencesProvider).getString(AppConstants.progressStorageKey), ep01Save);
    expect(ctrl().openEpisode('ep01'), isTrue);
    expect(XpBreakdown.totalFor(current(), state()), ep01Xp);
    expect(state().badgeIds, isNot(contains(GameBadge.clockWatcher.name)));
  });

  test('hints are counted per case', () {
    ctrl().registerDetective('Kim');
    solveCurrentCase();
    ctrl().openEpisode('ep02');
    ctrl().startInvestigation();
    final m = current().missions.first;
    expect(ctrl().useHint(m), 1);
    expect(ctrl().useHint(m), 2);
    expect(ctrl().useHint(m), 2, reason: 'at most two tips');
    expect(state().totalHints, 2);
    ctrl().openEpisode('ep01');
    expect(state().totalHints, 0);
  });

  test('restarting the app restores the open case and the solved cases', () async {
    ctrl().registerDetective('Kim');
    solveCurrentCase();
    ctrl().openEpisode('ep02');
    ctrl().startInvestigation();
    final first = current().missions.first;
    ctrl().submitAnswer(first, first.answer);

    final prefs = container.read(sharedPreferencesProvider);
    final restarted = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(restarted.dispose);
    expect(restarted.read(currentEpisodeProvider).id, 'ep02');
    final p = restarted.read(gameControllerProvider);
    expect(p.detectiveName, 'KIM');
    expect(p.completedMissionIds, [first.id]);
    expect(restarted.read(seasonProvider).isSolved('ep01'), isTrue);
  });

  test('a save from before the season still opens Case 02', () async {
    final solved = GameProgress(
      detectiveName: 'KIM',
      introSeen: true,
      completedMissionIds: [for (final m in episode01.allMissions) m.id],
      startedAt: DateTime(2026, 9, 1, 10),
      completedAt: DateTime(2026, 9, 1, 10, 30),
    );
    final c = ProviderContainer(
      overrides: await testOverrides(prefs: {AppConstants.progressStorageKey: jsonEncode(solved.toJson())}),
    );
    addTearDown(c.dispose);
    expect(c.read(gameControllerProvider).isCaseSolved, isTrue);
    expect(c.read(gameControllerProvider.notifier).openEpisode('ep02'), isTrue);
    expect(c.read(gameControllerProvider).detectiveName, 'KIM');
  });

  test('playing a case again keeps the next case open; reset seals everything', () async {
    ctrl().registerDetective('Kim');
    solveCurrentCase();
    ctrl().playAgain();
    expect(state().isCaseSolved, isFalse);
    expect(ctrl().openEpisode('ep02'), isTrue, reason: 'solved once is enough');

    await ctrl().resetAll();
    expect(current().id, 'ep01');
    expect(state().hasDetective, isFalse);
    ctrl().registerDetective('Lee');
    expect(ctrl().openEpisode('ep02'), isFalse);
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getKeys().where((k) => k.startsWith(AppConstants.progressStorageKey)), [AppConstants.progressStorageKey]);
  });
}
