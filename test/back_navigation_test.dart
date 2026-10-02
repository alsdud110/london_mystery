import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/game_progress.dart';

import 'full_playthrough_test.dart' show goToTime, reveal, tapText, wait;
import 'helpers.dart';

/// How a player goes back.
enum BackVia {
  /// The system back as older Android versions deliver it (popRoute).
  systemBack,

  /// Android 16 (target SDK 36, predictive back): the back gesture channel.
  backGesture,

  /// The arrow in the app bar.
  appBar,
}

/// Android back (the system back button / gesture) never closes the app in
/// the middle of a case: it walks back a step, or asks first. It does exactly
/// what the app bar arrow does.
void main() {
  late WidgetRef appRef;
  String path() => appRef.read(routerProvider).routerDelegate.currentConfiguration.last.matchedLocation;

  /// What the framework last told Android: whether it handles back itself.
  /// False would let Android send the app away on the next back.
  late List<bool> handlesBack;

  Future<void> start(WidgetTester t, {bool introSeen = true, String at = Routes.map}) async {
    t.view.physicalSize = const Size(1080, 1920);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    handlesBack = [];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemNavigator.setFrameworkHandlesBack') handlesBack.add(call.arguments as bool);
      return null;
    });
    addTearDown(() => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final progress = GameProgress(detectiveName: 'KIM', introSeen: introSeen, startedAt: DateTime(2026, 10, 1, 10), playMillis: 0);
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(prefs: {AppConstants.progressStorageKey: jsonEncode(progress.toJson())}),
      child: Consumer(builder: (context, ref, _) {
        appRef = ref;
        return const LondonMysteryApp();
      }),
    ));
    await wait(t, const Duration(milliseconds: 300));
    appRef.read(routerProvider).go(at);
    await wait(t, const Duration(milliseconds: 1500));
  }

  Future<void> back(WidgetTester t, BackVia via) async {
    expect(handlesBack.last, isTrue, reason: 'Android must hand this back to the game');
    switch (via) {
      case BackVia.systemBack:
        await t.binding.handlePopRoute();
      case BackVia.backGesture:
        const codec = StandardMethodCodec();
        for (final call in const [
          MethodCall('startBackGesture', <String, Object?>{'touchOffset': <double>[0, 300], 'progress': 0.0, 'swipeEdge': 0}),
          MethodCall('commitBackGesture'),
        ]) {
          await t.binding.defaultBinaryMessenger.handlePlatformMessage('flutter/backgesture', codec.encodeMethodCall(call), (_) {});
          await t.pump();
        }
      case BackVia.appBar:
        await t.tap(find.byWidgetPredicate((w) => w is IconButton && (w.tooltip == 'Back' || w.tooltip == 'Back to map')));
    }
    await wait(t, const Duration(milliseconds: 800));
  }

  /// The map is on screen and ready: not faded out, GO can be tapped.
  void expectMapBack(WidgetTester t) {
    expect(path(), Routes.map);
    expect(t.widget<FadeTransition>(find.byKey(const ValueKey('map-page'))).opacity.value, 1, reason: 'the map is visible again');
    expect(find.bySemanticsLabel("GO TO KING'S CROSS"), findsOneWidget);
    expect(find.text('Leave the case?'), findsNothing);
  }

  Future<void> goToMission(WidgetTester t) async {
    await t.tap(find.bySemanticsLabel("GO TO KING'S CROSS"));
    await wait(t, goToTime);
    expect(path(), Routes.mission('m01'));
  }

  Future<void> investigate(WidgetTester t) async {
    await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 700));
    expect(find.text('TAP TO OPEN'), findsOneWidget, reason: 'the letter step');
  }

  Future<void> openLetterAndSolve(WidgetTester t) async {
    await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
    await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
    expect(find.text('CHECK ANSWER'), findsOneWidget, reason: 'the puzzle step');
  }

  for (final via in BackVia.values) {
    group(via.name, () {
      testWidgets('Map → GO → the mission → back → the map', (t) async {
        await start(t);
        await goToMission(t);
        await back(t, via);
        expectMapBack(t);
        await wait(t, const Duration(seconds: 3));
      });

      testWidgets('the letter → back → the mission (the place) → back → the map', (t) async {
        await start(t);
        await goToMission(t);
        await investigate(t);
        await back(t, via);
        expect(path(), Routes.mission('m01'));
        await reveal(t, find.text('INVESTIGATE'));
        expect(find.text('INVESTIGATE'), findsOneWidget, reason: 'letter → the place');
        await back(t, via);
        expectMapBack(t);
        await wait(t, const Duration(seconds: 3));
      });

      testWidgets('the puzzle → back → the letter, still open → the place → the map', (t) async {
        await start(t);
        await goToMission(t);
        await investigate(t);
        await openLetterAndSolve(t);
        await back(t, via);
        await reveal(t, find.text('SOLVE THE PUZZLE')); // under the letter on a small phone
        expect(find.text('SOLVE THE PUZZLE'), findsOneWidget, reason: 'puzzle → the letter, still open');
        await back(t, via);
        await reveal(t, find.text('INVESTIGATE'));
        expect(find.text('INVESTIGATE'), findsOneWidget, reason: 'letter → the place');
        await back(t, via);
        expectMapBack(t);
        await wait(t, const Duration(seconds: 3));
      });
    });
  }

  testWidgets('a returning detective (straight to the puzzle) also walks back to the map', (t) async {
    await start(t);
    await goToMission(t);
    await investigate(t);
    await openLetterAndSolve(t); // the puzzle is now started: next time it opens on the puzzle
    for (var i = 0; i < 3; i++) {
      await back(t, BackVia.backGesture);
    }
    expectMapBack(t);
    await goToMission(t);
    expect(find.text('CHECK ANSWER'), findsOneWidget, reason: 'reopens on the puzzle');
    for (var i = 0; i < 3; i++) {
      await back(t, BackVia.backGesture);
    }
    expectMapBack(t);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('a mission with nothing under it still goes back to its map', (t) async {
    await start(t, at: Routes.mission('m01'));
    expect(path(), Routes.mission('m01'));
    expect(appRef.read(routerProvider).canPop(), isFalse, reason: 'the mission is the only page');
    await back(t, BackVia.backGesture);
    expect(path(), Routes.map);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('pressing back many times never closes the app: the map asks first', (t) async {
    await start(t);
    await goToMission(t);
    await investigate(t);
    await openLetterAndSolve(t);
    for (var i = 0; i < 3; i++) {
      await back(t, BackVia.backGesture); // puzzle → letter → place → map
    }
    expectMapBack(t);
    await back(t, BackVia.backGesture);
    expect(find.text('Leave the case?'), findsOneWidget, reason: 'on the map, back asks');
    await back(t, BackVia.backGesture); // closes the question
    expect(find.text('Leave the case?'), findsNothing);
    expect(path(), Routes.map);
    expect(handlesBack.last, isTrue, reason: 'the game still owns back');
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('back on the map asks before leaving the case', (t) async {
    await start(t);
    await back(t, BackVia.systemBack);
    expect(find.text('Leave the case?'), findsOneWidget);
    await tapText(t, 'Keep investigating', after: const Duration(milliseconds: 600));
    expect(path(), Routes.map, reason: 'stay on the case');

    await back(t, BackVia.systemBack);
    await tapText(t, 'TITLE SCREEN', after: const Duration(milliseconds: 800));
    expect(path(), Routes.start);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('back on the story intro returns to the case files', (t) async {
    await start(t, introSeen: false, at: Routes.intro);
    expect(path(), Routes.intro);
    await back(t, BackVia.systemBack);
    expect(path(), Routes.episodes);
    await wait(t, const Duration(seconds: 3));
  });
}
