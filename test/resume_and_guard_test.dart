import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart' show parentReportAccessProvider;

import 'full_playthrough_test.dart' show tapText, wait;
import 'helpers.dart';
import 'parent_gate_test.dart' show gateAnswer;

Future<WidgetRef> pumpApp(WidgetTester t, GameProgress saved) async {
  t.view.physicalSize = const Size(1170, 2532);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final overrides = await testOverrides(prefs: {
    AppConstants.progressStorageKey: jsonEncode(saved.toJson()),
  });
  late WidgetRef appRef;
  await t.pumpWidget(ProviderScope(
    overrides: overrides,
    child: Consumer(builder: (context, ref, _) {
      appRef = ref;
      return const LondonMysteryApp();
    }),
  ));
  await wait(t);
  return appRef;
}

void main() {
  final midGame = GameProgress(
    detectiveName: 'MINYOUNG',
    introSeen: true,
    completedMissionIds: const ['m01', 'm02'],
    attempts: const {'m01': 1, 'm02': 1},
    startedAt: DateTime.now().subtract(const Duration(minutes: 12)),
  );

  testWidgets('reopening the app continues the saved case', (t) async {
    await pumpApp(t, midGame);
    expect(find.text('Welcome back, Detective MINYOUNG!'), findsOneWidget);
    await tapText(t, 'CONTINUE ADVENTURE', after: const Duration(milliseconds: 1200));
    expect(find.bySemanticsLabel('GO TO BIG BEN'), findsOneWidget, reason: 'two places solved, Big Ben is next');
    await t.tap(find.byTooltip('Detective notebook'));
    await wait(t, const Duration(milliseconds: 1200));
    expect(find.text('"Platform 9"'), findsOneWidget);
    expect(find.text('"Room 4"'), findsOneWidget);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('locked missions and results cannot be opened by URL', (t) async {
    final ref = await pumpApp(t, midGame);
    final router = ref.read(routerProvider);

    for (final path in ['/mission/m04', '/mission/final', '/story/m03', '/story/nope', '/final', '/solved', '/report', '/game-master']) {
      router.go(path);
      await wait(t, const Duration(milliseconds: 600));
      final expected = path == '/game-master' ? Routes.start : Routes.map;
      expect(router.routerDelegate.currentConfiguration.uri.path, expected, reason: path);
    }

    router.go('/story/m01'); // story scenes of solved missions are allowed
    await wait(t, const Duration(milliseconds: 600));
    expect(router.routerDelegate.currentConfiguration.uri.path, '/story/m01');

    router.go('/mission/m03'); // the current mission is allowed
    await wait(t, const Duration(milliseconds: 600));
    expect(router.routerDelegate.currentConfiguration.uri.path, '/mission/m03');
    await wait(t, const Duration(seconds: 3));
  });

  final solvedCase = GameProgress(
    detectiveName: 'MINYOUNG',
    introSeen: true,
    completedMissionIds: [for (final m in episode01.allMissions) m.id],
    attempts: {for (final m in episode01.allMissions) m.id: 1},
    startedAt: DateTime(2026, 9, 28, 10),
    completedAt: DateTime(2026, 9, 28, 10, 30),
    playMillis: const Duration(minutes: 25).inMilliseconds,
  );

  String pathOf(WidgetRef ref) => ref.read(routerProvider).routerDelegate.currentConfiguration.uri.path;
  // The report is pushed on top of /solved, so check what is on screen.
  final report = find.text('Episode 01 Result');

  testWidgets('the parent report needs the parent gate every time', (t) async {
    final ref = await pumpApp(t, solvedCase);
    final router = ref.read(routerProvider);

    // A typed URL or deep link cannot open it.
    router.go(Routes.report);
    await wait(t, const Duration(milliseconds: 600));
    expect(pathOf(ref), Routes.solved);
    await wait(t, const Duration(seconds: 3));

    // Wrong answer or cancel: no report.
    await tapText(t, 'VIEW MY DETECTIVE REPORT', after: const Duration(milliseconds: 600));
    await t.enterText(find.byType(TextField), '1');
    await tapText(t, 'OK', after: const Duration(milliseconds: 800));
    expect(report, findsNothing);
    expect(ref.read(parentReportAccessProvider), isFalse);
    await tapText(t, 'VIEW MY DETECTIVE REPORT', after: const Duration(milliseconds: 600));
    await tapText(t, 'Cancel', after: const Duration(milliseconds: 800));
    expect(report, findsNothing);
    expect(ref.read(parentReportAccessProvider), isFalse);

    // Right answer: the report opens.
    await tapText(t, 'VIEW MY DETECTIVE REPORT', after: const Duration(milliseconds: 600));
    await t.enterText(find.byType(TextField), gateAnswer(t));
    await tapText(t, 'OK', after: const Duration(milliseconds: 1200));
    expect(report, findsOneWidget);

    // Back to the case file: the pass is gone, so the URL is blocked again.
    await t.tap(find.byTooltip('Back'));
    await wait(t, const Duration(milliseconds: 800));
    expect(report, findsNothing);
    expect(find.text('CASE CLOSED'), findsOneWidget);
    expect(ref.read(parentReportAccessProvider), isFalse);
    router.go(Routes.report);
    await wait(t, const Duration(milliseconds: 600));
    expect(pathOf(ref), Routes.solved);
    expect(report, findsNothing);
    await wait(t, const Duration(seconds: 3));

    // Leaving the report any other way (e.g. browser navigation) also ends it.
    await tapText(t, 'VIEW MY DETECTIVE REPORT', after: const Duration(milliseconds: 600));
    await t.enterText(find.byType(TextField), gateAnswer(t));
    await tapText(t, 'OK', after: const Duration(milliseconds: 1200));
    expect(report, findsOneWidget);
    router.go(Routes.map);
    await wait(t, const Duration(milliseconds: 800));
    expect(ref.read(parentReportAccessProvider), isFalse);
    router.go(Routes.report);
    await wait(t, const Duration(milliseconds: 600));
    expect(pathOf(ref), Routes.solved);
    expect(report, findsNothing);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('the play clock stops while the app is in the background', (t) async {
    var clock = DateTime(2026, 9, 28, 14);
    GameController.now = () => clock;
    addTearDown(() => GameController.now = DateTime.now);
    final ref = await pumpApp(t, midGame.copyWith(playMillis: const Duration(minutes: 10).inMilliseconds));
    final game = ref.read(gameControllerProvider.notifier);
    expect(game.playTime, const Duration(minutes: 10));

    // The platform reports each step: resumed → inactive → hidden → paused.
    void go(List<AppLifecycleState> states) {
      for (final s in states) {
        t.binding.handleAppLifecycleStateChanged(s);
      }
    }

    go(const [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]);
    clock = clock.add(const Duration(hours: 1));
    go(const [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]);
    expect(game.playTime, const Duration(minutes: 10), reason: 'the hour in the background is not counted');
    expect(ref.read(gameControllerProvider).playMillis, const Duration(minutes: 10).inMilliseconds,
        reason: 'saved when the app went to the background');

    clock = clock.add(const Duration(minutes: 1));
    expect(game.playTime, const Duration(minutes: 11));
  });

  testWidgets('a new player without a name is sent to registration', (t) async {
    final ref = await pumpApp(t, GameProgress.empty);
    ref.read(routerProvider).go(Routes.map);
    await wait(t);
    expect(find.text('What should we\ncall you, Detective?'), findsOneWidget);
  });
}
