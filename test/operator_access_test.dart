import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/scoring.dart';

import 'full_playthrough_test.dart' show tapText, wait;
import 'helpers.dart';

/// Operator full case access (QA): every case opens in a test build, while
/// a child's game keeps its rules, and opening a case marks nothing solved.
void main() {
  final season = MockEpisodeRepository.bundled();
  final ids = [for (final e in season) e.id];

  /// A detective with Case 01 solved (so Case 02 is open, the rest sealed).
  Map<String, Object> afterCase01() => {
    AppConstants.progressStorageKey: jsonEncode(
      GameProgress(
        detectiveName: 'KIM',
        introSeen: true,
        completedMissionIds: [for (final m in season.first.allMissions) m.id],
        badgeIds: const ['firstClue'],
        startedAt: DateTime(2026, 9, 29, 10),
        completedAt: DateTime(2026, 9, 29, 11),
      ).toJson(),
    ),
    AppConstants.seasonStorageKey: jsonEncode(const SeasonProgress(activeEpisodeId: 'ep01', solvedEpisodeIds: ['ep01']).toJson()),
  };

  Future<ProviderContainer> container({bool operatorTools = true, Map<String, Object>? prefs}) async {
    final c = ProviderContainer(
      overrides: [
        ...await testOverrides(prefs: prefs ?? afterCase01()),
        operatorToolsAvailableProvider.overrideWithValue(operatorTools),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('a normal player', () {
    test('keeps the case order: Case 01 and 02 open, Case 03~12 sealed', () async {
      final c = await container();
      final unlocks = c.read(seasonProvider.notifier);
      expect(unlocks.isUnlocked('ep01'), isTrue);
      expect(unlocks.isUnlocked('ep02'), isTrue, reason: 'Case 01 is solved');
      for (final id in ids.skip(2)) {
        expect(unlocks.isUnlocked(id), isFalse, reason: id);
        expect(c.read(gameControllerProvider.notifier).openEpisode(id), isFalse, reason: '$id refused by the controller');
      }
      expect(c.read(currentEpisodeProvider).id, 'ep01');
    });

    test('a fresh device: only Case 01 is open, Case 02 and Case 12 are sealed', () async {
      final c = await container(prefs: const {});
      final unlocks = c.read(seasonProvider.notifier);
      expect(unlocks.isUnlocked('ep01'), isTrue);
      expect(unlocks.isUnlocked('ep02'), isFalse);
      expect(unlocks.isUnlocked('ep12'), isFalse);
    });
  });

  group('operator access', () {
    test('opens every case of the season, Case 01 to Case 12', () async {
      final c = await container();
      c.read(operatorAccessSwitchProvider.notifier).set(true);
      expect(c.read(operatorAccessProvider), isTrue);
      expect(ids, hasLength(12));
      for (final id in ids) {
        expect(c.read(seasonProvider.notifier).isUnlocked(id), isTrue, reason: id);
        expect(c.read(gameControllerProvider.notifier).openEpisode(id), isTrue, reason: id);
        expect(c.read(currentEpisodeProvider).id, id);
      }
    });

    test('opening Case 08 marks nothing solved and gives no XP, badges or evidence', () async {
      final c = await container();
      final repo = c.read(progressRepositoryProvider);
      final seasonBefore = jsonEncode(c.read(seasonProvider).toJson());
      final savesBefore = {for (final id in ids) id: jsonEncode(repo.load(id).toJson())};

      c.read(operatorAccessSwitchProvider.notifier).set(true);
      expect(c.read(gameControllerProvider.notifier).openEpisode('ep08'), isTrue);

      final e = c.read(currentEpisodeProvider);
      final p = c.read(gameControllerProvider);
      expect(e.id, 'ep08');
      expect(p.completedMissionIds, isEmpty, reason: 'not solved');
      expect(p.isCaseSolved, isFalse);
      expect(XpBreakdown.totalFor(e, p), 0, reason: 'no XP');
      expect(p.badgeIds, isEmpty, reason: 'no badges');
      expect(p.collectedEvidence(e), isEmpty, reason: 'no evidence');
      expect(p.collectedClues(e), isEmpty);
      // The season record: still only Case 01 solved, now with Case 08 open.
      final s = c.read(seasonProvider);
      expect(s.solvedEpisodeIds, ['ep01']);
      expect(jsonEncode(s.copyWith(activeEpisodeId: 'ep01').toJson()), seasonBefore);
      for (final id in ids.where((id) => id != 'ep08')) {
        expect(jsonEncode(repo.load(id).toJson()), savesBefore[id], reason: '$id save untouched');
      }
      // Case 01 keeps its own XP and badge.
      expect(repo.load('ep01').badgeIds, ['firstClue']);
    });

    test('inside a case the missions still unlock in order', () async {
      final c = await container();
      c.read(operatorAccessSwitchProvider.notifier).set(true);
      c.read(gameControllerProvider.notifier).openEpisode('ep12');
      final e = c.read(currentEpisodeProvider);
      final p = c.read(gameControllerProvider);
      expect(p.isUnlocked(e, e.missions.first.id), isTrue);
      expect(p.isUnlocked(e, e.missions[1].id), isFalse);
      expect(p.isUnlocked(e, e.finalMission.id), isFalse);
    });

    test('switched off, the normal rules are back', () async {
      final c = await container();
      c.read(operatorAccessSwitchProvider.notifier).set(true);
      c.read(operatorAccessSwitchProvider.notifier).set(false);
      expect(c.read(seasonProvider.notifier).isUnlocked('ep08'), isFalse);
      expect(c.read(gameControllerProvider.notifier).openEpisode('ep08'), isFalse);
    });

    test('a build without operator tools (release) can never switch it on', () async {
      final c = await container(operatorTools: false);
      c.read(operatorAccessSwitchProvider.notifier).set(true);
      expect(c.read(operatorAccessProvider), isFalse);
      for (final id in ids.skip(2)) {
        expect(c.read(seasonProvider.notifier).isUnlocked(id), isFalse, reason: id);
        expect(c.read(gameControllerProvider.notifier).openEpisode(id), isFalse, reason: id);
      }
    });

    test('the release switch is the compile-time playtest flag', () {
      // Tests run in debug mode; a release build without LM_PLAYTEST has
      // kDebugMode false, so this constant (and the provider) is false.
      expect(operatorToolsInBuild, isTrue);
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(operatorToolsAvailableProvider), operatorToolsInBuild);
    });
  });

  group('case files and links', () {
    late WidgetRef appRef;

    Future<void> openApp(WidgetTester t, {required bool operator}) async {
      t.view.physicalSize = const Size(1080, 1920);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: afterCase01()),
        child: Consumer(builder: (context, ref, _) {
          appRef = ref;
          return const LondonMysteryApp();
        }),
      ));
      await wait(t, const Duration(milliseconds: 300));
      appRef.read(operatorAccessSwitchProvider.notifier).set(operator);
    }

    for (final id in ['ep07', 'ep08', 'ep12']) {
      testWidgets('an operator opens $id from its case-file link and begins with its intro', (t) async {
        await openApp(t, operator: true);
        appRef.read(routerProvider).go(Routes.caseFile(id));
        await wait(t, const Duration(milliseconds: 800));
        expect(find.text('OPERATOR MODE'), findsOneWidget);
        await tapText(t, 'BEGIN INVESTIGATION');
        expect(appRef.read(currentEpisodeProvider).id, id);
        expect(appRef.read(routerProvider).routerDelegate.currentConfiguration.uri.path, Routes.intro);
        expect(appRef.read(seasonProvider).solvedEpisodeIds, ['ep01'], reason: 'nothing solved by opening');
        await wait(t, const Duration(seconds: 3));
      });
    }

    testWidgets('a child following the same link stays on their own case', (t) async {
      await openApp(t, operator: false);
      appRef.read(routerProvider).go(Routes.caseFile('ep08'));
      await wait(t, const Duration(milliseconds: 800));
      expect(find.text('OPERATOR MODE'), findsNothing);
      // The link does not choose a sealed case: the button reviews Case 01.
      await tapText(t, 'REVIEW THE CASE');
      expect(appRef.read(currentEpisodeProvider).id, 'ep01', reason: 'Case 08 is still sealed');
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('the switch is in the Game Master tools, behind the parent gate', (t) async {
      await openApp(t, operator: false);
      appRef.read(routerProvider).go(Routes.gameMaster);
      await wait(t);
      expect(find.text('전체 사건 열기 (OPERATOR MODE)'), findsNothing, reason: 'no gate passed: no tools');

      appRef.read(gameMasterAccessProvider.notifier).grant();
      appRef.read(routerProvider).go(Routes.gameMaster);
      await wait(t);
      final label = find.text('전체 사건 열기 (OPERATOR MODE)');
      await t.dragUntilVisible(label, find.byType(ListView).last, const Offset(0, -200));
      await t.tap(label);
      await wait(t);
      expect(appRef.read(operatorAccessProvider), isTrue);
      await tapText(t, 'CASE FILES로 이동');
      expect(find.text('OPERATOR MODE'), findsOneWidget);
      await wait(t, const Duration(seconds: 3));
    });

    // Every case's answer key opens without a layout error, long sequence
    // answers (A → B → C → D) included, at a small phone width.
    testWidgets('the answer key of every case lays out and shows every answer', (t) async {
      await openApp(t, operator: true);
      appRef.read(gameMasterAccessProvider.notifier).grant();
      for (final e in season) {
        appRef.read(gameControllerProvider.notifier).openEpisode(e.id);
        appRef.read(routerProvider).go(Routes.gameMaster);
        await wait(t);
        final key = find.text('정답표 (도우미용)');
        await t.dragUntilVisible(key, find.byType(ListView).last, const Offset(0, -200));
        await t.tap(key);
        await wait(t);
        expect(t.takeException(), isNull, reason: '${e.id} answer key');
        for (final m in e.allMissions) {
          expect(find.textContaining('정답: ${m.answerLabel}', findRichText: true), findsOneWidget, reason: '${e.id} ${m.id}');
        }
        appRef.read(routerProvider).go(Routes.episodes); // leave, so the key is folded next time
        await wait(t);
      }
      await wait(t, const Duration(seconds: 3));
    });
  });
}
