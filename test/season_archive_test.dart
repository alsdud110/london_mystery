import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/notebook/season_archive.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';

void main() {
  late ProviderContainer container;
  GameController ctrl() => container.read(gameControllerProvider.notifier);
  GameProgress state() => container.read(gameControllerProvider);
  Episode current() => container.read(currentEpisodeProvider);
  List<ArchiveEntry> archive() => container.read(seasonArchiveProvider);
  ArchiveEntry entry(String id) => archive().firstWhere((a) => a.episode.id == id);

  setUp(() async => container = ProviderContainer(overrides: await testOverrides()));
  tearDown(() => container.dispose());

  void solveCurrentCase() {
    ctrl().startInvestigation();
    for (final m in current().allMissions) {
      expect(ctrl().submitAnswer(m, m.answer).result, SubmitResult.correct, reason: m.id);
    }
  }

  group('Season Archive data', () {
    test('a fresh season: Case 01 is this case, every other case is sealed', () {
      ctrl().registerDetective('Kim');
      final a = archive();
      expect(a, hasLength(12));
      expect(a.first.status, ArchiveStatus.current);
      expect(a.skip(1).every((e) => e.status == ArchiveStatus.sealed), isTrue);
      expect(a.skip(1).every((e) => e.evidence.isEmpty && !e.canOpen), isTrue, reason: 'sealed cases show nothing');
    });

    test('the open case shows only what has been found so far', () {
      ctrl().registerDetective('Kim');
      ctrl().startInvestigation();
      final m = current().missions.first;
      ctrl().submitAnswer(m, m.answer);
      expect(entry('ep01').evidence.map((e) => e.id), [m.evidence!.id]);
      expect(entry('ep01').clues.map((c) => c.id), [m.clue!.id]);
    });

    test('solved cases show all their evidence; the next case is open but not opened', () {
      ctrl().registerDetective('Kim');
      solveCurrentCase();
      expect(entry('ep01').status, ArchiveStatus.solved);
      expect(entry('ep01').evidence, hasLength(episode01.allEvidence.length));
      expect(entry('ep02').status, ArchiveStatus.notOpened);
      expect(entry('ep02').canOpen, isFalse);
      expect(entry('ep03').status, ArchiveStatus.sealed);
    });

    test('a started case that is not open is read from its own save', () {
      ctrl().registerDetective('Kim');
      solveCurrentCase();
      ctrl().openEpisode('ep02');
      ctrl().startInvestigation();
      final m = current().missions.first;
      ctrl().submitAnswer(m, m.answer);
      ctrl().openEpisode('ep01');
      expect(entry('ep02').status, ArchiveStatus.started);
      expect(entry('ep02').evidence.map((e) => e.id), [m.evidence!.id]);
    });

    test('in Case 12, the evidence of Cases 01-11 can all be read', () {
      ctrl().registerDetective('Kim');
      for (final e in container.read(episodeCatalogProvider)) {
        expect(ctrl().openEpisode(e.id), isTrue);
        if (e.id != 'ep12') solveCurrentCase();
      }
      expect(current().id, 'ep12');
      for (final a in archive().where((a) => a.episode.id != 'ep12')) {
        expect(a.status, ArchiveStatus.solved, reason: a.episode.id);
        expect(a.evidence, hasLength(a.episode.allEvidence.length), reason: a.episode.id);
        expect(a.clues, hasLength(a.episode.allClues.length), reason: a.episode.id);
      }
      // The clue Case 12 asks about: the small red clock on Platform 4 (Case 04).
      expect(entry('ep04').clues.map((c) => c.note).join(), contains('red clock on Platform 4'));
      expect(entry('ep12').status, ArchiveStatus.current);
    });

    test('playing a solved case again keeps its evidence in the archive', () {
      ctrl().registerDetective('Kim');
      solveCurrentCase();
      ctrl().playAgain();
      expect(state().collectedEvidence(current()), isEmpty);
      expect(entry('ep01').status, ArchiveStatus.solved);
      expect(entry('ep01').evidence, hasLength(episode01.allEvidence.length));
    });
  });

  group('Play again gives no double rewards', () {
    for (final id in ['ep01', 'ep02']) {
      test('$id: XP, evidence and badges are the same after a second solve', () {
        ctrl().registerDetective('Kim');
        if (id != 'ep01') {
          solveCurrentCase();
          ctrl().openEpisode(id);
        }
        solveCurrentCase();
        final e = current();
        final xp = XpBreakdown.totalFor(e, state());
        final evidence = state().collectedEvidence(e).length;
        final badges = state().badgeIds.toSet();

        ctrl().playAgain();
        solveCurrentCase();
        expect(XpBreakdown.totalFor(e, state()), xp);
        expect(state().collectedEvidence(e), hasLength(evidence));
        expect(state().badgeIds.toSet(), badges);
        expect(state().badgeIds, hasLength(badges.length), reason: 'no badge twice');
        expect(state().completedMissionIds.toSet(), hasLength(state().completedMissionIds.length));
        expect(container.read(seasonProvider).solvedEpisodeIds.where((s) => s == id), hasLength(1));
      });
    }
  });

  group('Case 01 save compatibility', () {
    test('an old Case 01 save keeps its XP, evidence and badges after the update', () async {
      final old = GameProgress(
        detectiveName: 'KIM',
        introSeen: true,
        completedMissionIds: const ['m01', 'm02', 'm03'],
        attempts: const {'m01': 1, 'm02': 1, 'm03': 1},
        solveSeconds: const {'m01': 5, 'm02': 6, 'm03': 5},
        badgeIds: const ['firstClue', 'sharpEyes', 'quickThinker', 'puzzleSolver'],
        startedAt: DateTime(2026, 9, 29, 4, 46),
        playMillis: 78390,
      );
      final raw = jsonEncode(old.toJson());
      final c = ProviderContainer(overrides: await testOverrides(prefs: {AppConstants.progressStorageKey: raw}));
      addTearDown(c.dispose);
      final p = c.read(gameControllerProvider);
      expect(c.read(currentEpisodeProvider).id, 'ep01');
      expect(p.toJson(), old.toJson());
      expect(XpBreakdown.totalFor(episode01, p), XpBreakdown.totalFor(episode01, old));
      expect(p.collectedEvidence(episode01), hasLength(3));
      expect(c.read(seasonArchiveProvider).first.status, ArchiveStatus.current);
      expect(c.read(sharedPreferencesProvider).getString(AppConstants.progressStorageKey), raw, reason: 'not rewritten');
    });
  });

  group('Locked cases', () {
    test('Case 12 cannot be opened before Case 11 is solved', () {
      ctrl().registerDetective('Kim');
      for (final e in container.read(episodeCatalogProvider).take(10)) {
        ctrl().openEpisode(e.id);
        solveCurrentCase();
      }
      expect(ctrl().openEpisode('ep12'), isFalse);
      expect(ctrl().openEpisode('ep11'), isTrue);
      expect(ctrl().openEpisode('ep12'), isFalse, reason: 'Case 11 is open, not solved');
    });
  });

  // ── Screens ───────────────────────────────────────────────────────────────

  Future<WidgetRef> pumpApp(WidgetTester t, Map<String, Object> prefs) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    late WidgetRef appRef;
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(prefs: prefs),
      child: Consumer(builder: (context, ref, _) {
        appRef = ref;
        return const LondonMysteryApp();
      }),
    ));
    await wait(t);
    return appRef;
  }

  /// Cases 01-11 solved; Case 12 open with [done] missions solved.
  Map<String, Object> lateSeason(List<String> done, {Map<String, int> hints = const {}}) {
    final ids = [for (var i = 1; i <= 11; i++) 'ep${i.toString().padLeft(2, '0')}'];
    return {
      AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'KIM').toJson()),
      AppConstants.progressKeyFor('ep12'): jsonEncode(GameProgress(
        detectiveName: 'KIM',
        introSeen: true,
        completedMissionIds: done,
        hintsUsed: hints,
        missionStartedAt: {'ep12_m2': DateTime(2026, 9, 29, 10)},
        startedAt: DateTime(2026, 9, 29, 10),
        playMillis: 0,
      ).toJson()),
      AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: ids).toJson()),
    };
  }

  String pathOf(WidgetRef ref) => ref.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

  testWidgets('Case 12 mission → notebook → archive → Case 04 evidence → back to the same puzzle', (t) async {
    final ref = await pumpApp(t, lateSeason(['ep12_m1'], hints: {'ep12_m2': 1}));
    ref.read(routerProvider).go(Routes.mission('ep12_m2'));
    await wait(t, const Duration(milliseconds: 1200));
    expect(find.text('DETECTIVE TIP 1'), findsOneWidget, reason: 'puzzle stage, one tip open');

    await t.tap(find.byTooltip('Detective notebook'));
    await wait(t, const Duration(milliseconds: 1000));
    expect(find.text('THIS CASE'), findsOneWidget);
    await tapText(t, 'CASE ARCHIVE', after: const Duration(milliseconds: 600));
    expect(find.text('11 of 12 cases solved'), findsOneWidget);
    await tapText(t, 'THE SECRET LETTER', after: const Duration(milliseconds: 600));
    await reveal(t, find.text('Word Card'));
    await tapText(t, 'Word Card', after: const Duration(milliseconds: 800));
    expect(find.text('RED · FOUR · CLOCK · PLATFORM'), findsWidgets, reason: 'evidence zoom');
    await tapText(t, 'CLOSE', after: const Duration(milliseconds: 600));
    await reveal(t, find.text('"Platform 4"'));
    expect(find.text('"Platform 4"'), findsOneWidget, reason: 'the clue Case 12 needs');

    await t.tap(find.byTooltip('Close'));
    await wait(t, const Duration(milliseconds: 1000));
    expect(pathOf(ref), Routes.mission('ep12_m2'));
    expect(find.text('DETECTIVE TIP 1'), findsOneWidget, reason: 'the puzzle is as it was');
    expect(ref.read(gameControllerProvider).hintsFor('ep12_m2'), 1);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('final case: OPEN MY NOTEBOOK → sheet → OPEN THE CASE ARCHIVE → back', (t) async {
    final ref = await pumpApp(t, lateSeason(['ep12_m1', 'ep12_m2', 'ep12_m3']));
    ref.read(routerProvider).go(Routes.finalMission);
    await wait(t, const Duration(milliseconds: 1200));
    await tapText(t, 'OPEN MY NOTEBOOK', after: const Duration(milliseconds: 800));
    expect(find.text('"Eight Teeth"'), findsOneWidget, reason: "this case's clues");
    await tapText(t, 'OPEN THE CASE ARCHIVE', after: const Duration(milliseconds: 1000));
    expect(find.text('11 of 12 cases solved'), findsOneWidget);
    await t.tap(find.byTooltip('Close'));
    await wait(t, const Duration(milliseconds: 1000));
    expect(pathOf(ref), Routes.finalMission);
    expect(find.text('OPEN MY NOTEBOOK'), findsOneWidget);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('Case 01 final: the notebook sheet has no archive link yet', (t) async {
    final ref = await pumpApp(t, {
      AppConstants.progressStorageKey: jsonEncode(GameProgress(
        detectiveName: 'KIM',
        introSeen: true,
        completedMissionIds: [for (final m in episode01.missions) m.id],
        startedAt: DateTime(2026, 9, 29, 10),
        playMillis: 0,
      ).toJson()),
    });
    ref.read(routerProvider).go(Routes.finalMission);
    await wait(t, const Duration(milliseconds: 1200));
    await tapText(t, 'OPEN MY NOTEBOOK', after: const Duration(milliseconds: 800));
    expect(find.text('OPEN THE CASE ARCHIVE'), findsNothing);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('Case Solved → Notebook → back; the last case leads back to the case files', (t) async {
    final ids = [for (var i = 1; i <= 12; i++) 'ep${i.toString().padLeft(2, '0')}'];
    final e12 = container.read(episodeCatalogProvider).last;
    final ref = await pumpApp(t, {
      AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'KIM').toJson()),
      AppConstants.progressKeyFor('ep12'): jsonEncode(GameProgress(
        detectiveName: 'KIM',
        introSeen: true,
        completedMissionIds: [for (final m in e12.allMissions) m.id],
        startedAt: DateTime(2026, 9, 29, 10),
        completedAt: DateTime(2026, 9, 29, 10, 40),
        playMillis: 0,
      ).toJson()),
      AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: ids).toJson()),
    });
    ref.read(routerProvider).go(Routes.solved);
    await wait(t, const Duration(milliseconds: 3200));
    await tapText(t, 'Notebook', after: const Duration(milliseconds: 1000));
    expect(find.text('DETECTIVE NOTEBOOK'), findsOneWidget);
    await t.tap(find.byTooltip('Close'));
    await wait(t, const Duration(milliseconds: 1000));
    expect(pathOf(ref), Routes.solved);
    expect(find.textContaining('OPEN CASE'), findsNothing, reason: 'there is no Case 13');
    // After the last case, the season's completed board (the case files are one tap on).
    await tapText(t, 'INVESTIGATION BOARD', after: const Duration(milliseconds: 2600));
    expect(pathOf(ref), Routes.season);
    await tapText(t, 'VIEW ALL CASE FILES', after: const Duration(milliseconds: 1000));
    expect(pathOf(ref), Routes.episodes);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('a sealed case in the case files cannot be opened', (t) async {
    final ref = await pumpApp(t, {
      AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'KIM').toJson()),
    });
    ref.read(routerProvider).go(Routes.episodes);
    await wait(t);
    await tapText(t, 'THE MIDNIGHT CASE', after: const Duration(milliseconds: 600));
    expect(find.text('Solve Case 11 to open this file.'), findsOneWidget);
    await tapText(t, 'Solve Case 11 to open this file.', after: const Duration(milliseconds: 400));
    expect(ref.read(currentEpisodeProvider).id, 'ep01', reason: 'nothing chosen, nothing opened');
    // A typed URL to a sealed case mission lands on the map of the open case.
    ref.read(routerProvider).go(Routes.mission('ep12_m1'));
    await wait(t, const Duration(milliseconds: 800));
    expect(pathOf(ref), isNot(Routes.mission('ep12_m1')));
    await wait(t, const Duration(seconds: 3));
  });
}
