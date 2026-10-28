import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/mission/widgets/question_widgets.dart';

import 'full_playthrough_test.dart' show reveal, wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// Case 12, Mission 2 (The Last Train In): the time is typed as four digits
/// and read as HH:MM — the colon printed between the hours and the minutes,
/// always there and never typed. Other number codes keep their plain wheels.
void main() {
  final catalog = MockEpisodeRepository.bundled();
  final missions = [for (final e in catalog) ...e.allMissions];
  Mission mission(String id) => missions.firstWhere((m) => m.id == id);

  setUpAll(() async {
    for (final (family, files) in [
      ('Sentient', ['Sentient-Variable.ttf']),
      ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
      ('LibreBaskerville', ['LibreBaskerville.ttf', 'LibreBaskerville-Italic.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await loader.load();
    }
  });

  group('content', () {
    test('only Case 12\'s train time is read as a time, and it is a real HH:MM', () {
      final times = [for (final m in missions) if (m.isTimeCode) m.id];
      expect(times, ['ep12_m2']);
      final m = mission('ep12_m2');
      expect(m.type, MissionType.numberCode);
      expect(m.answer, '1140', reason: 'the answer stays the digits: no colon to type');
      for (final code in [m.answer, ...m.feedback.keys]) {
        expect(code, matches(RegExp(r'^\d{4}$')), reason: '$code: four digits');
        expect(int.parse(code.substring(0, 2)), lessThan(24), reason: '$code: the hours');
        expect(int.parse(code.substring(2)), lessThan(60), reason: '$code: the minutes');
      }
    });

    test('the format is kept through the mission\'s JSON', () {
      final m = mission('ep12_m2');
      expect(Mission.fromJson(m.toJson()).isTimeCode, isTrue);
      expect(Mission.fromJson(mission('ep08_m3').toJson()).isTimeCode, isFalse);
    });
  });

  group('other number codes: their wheels as before, no colon', () {
    // 06-M3 is a choice now (2026-10-23): no wheels.
    for (final (id, length) in const [('ep08_m3', 3), ('ep09_m3', 2)]) {
      testWidgets(id, (t) async {
        final m = mission(id);
        expect(m.type, MissionType.numberCode);
        expect(m.codeLength, length);
        await t.pumpWidget(ProviderScope(
          overrides: await testOverrides(),
          child: MaterialApp(
            home: Scaffold(body: Center(child: NumberCodeQuestion(mission: m, onSubmit: (_) {}))),
          ),
        ));
        expect(find.byKey(const ValueKey('code-time-colon')), findsNothing);
        for (var i = 0; i < length; i++) {
          expect(find.byKey(ValueKey('code-wheel-$i')), findsOneWidget);
        }
        expect(find.text(':'), findsNothing);
      });
    }
  });

  group('Case 12 Mission 2 on the phone', () {
    late WidgetRef appRef;

    Future<void> pumpMission(WidgetTester t, Size size) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final ids = [for (var i = 1; i <= 11; i++) 'ep${i.toString().padLeft(2, '0')}'];
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: {
          AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'KIM').toJson()),
          AppConstants.progressKeyFor('ep12'): jsonEncode(GameProgress(
            detectiveName: 'KIM',
            introSeen: true,
            completedMissionIds: const ['ep12_m1'],
            missionStartedAt: {'ep12_m2': DateTime(2026, 9, 29, 10)},
            startedAt: DateTime(2026, 9, 29, 10),
            playMillis: 0,
          ).toJson()),
          AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: ids).toJson()),
        }),
        child: RepaintBoundary(
          key: const ValueKey('shot'),
          child: Consumer(builder: (context, ref, _) {
            appRef = ref;
            return const WorldMysteryApp();
          }),
        ),
      ));
      await wait(t, const Duration(milliseconds: 300));
      appRef.read(routerProvider).go(Routes.mission('ep12_m2'));
      await wait(t, const Duration(milliseconds: 1200));
      await reveal(t, find.byKey(const ValueKey('code-wheel-3')));
    }

    Future<void> press(WidgetTester t, String digit) async {
      await t.tap(find.widgetWithText(PuzzleKey, digit));
      await t.pump(const Duration(milliseconds: 200));
    }

    String wheel(WidgetTester t, int i) =>
        t.widget<Text>(find.descendant(of: find.byKey(ValueKey('code-wheel-$i')), matching: find.byType(Text))).data!;

    for (final size in const [Size(360, 640), Size(390, 844)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('$tag: HH:MM, the colon fixed between hours and minutes, all on screen', (t) async {
        await pumpMission(t, size);
        expect(t.takeException(), isNull);
        final colon = find.byKey(const ValueKey('code-time-colon'));
        expect(colon, findsOneWidget);
        final wheels = [for (var i = 0; i < 4; i++) t.getRect(find.byKey(ValueKey('code-wheel-$i')))];
        final c = t.getRect(colon);
        // Order: H H : M M, the colon in the gap between the two pairs.
        expect(wheels[0].right, lessThanOrEqualTo(wheels[1].left));
        expect(c.left, greaterThanOrEqualTo(wheels[1].right));
        expect(c.right, lessThanOrEqualTo(wheels[2].left));
        expect(wheels[2].right, lessThanOrEqualTo(wheels[3].left));
        // In line with the wheels and centred between the pairs.
        expect((c.center.dy - wheels[1].center.dy).abs(), lessThan(8));
        expect(((c.center.dx - wheels[1].right) - (wheels[2].left - c.center.dx)).abs(), lessThan(2));
        // The pairs are the same size; nothing off the phone.
        for (final w in wheels) {
          expect(w.size, wheels[0].size);
          expect(w.left, greaterThanOrEqualTo(0));
          expect(w.right, lessThanOrEqualTo(size.width));
        }
        await capture(t, 'time_code_$tag');
        await wait(t, const Duration(seconds: 3));
      });
    }

    testWidgets('typed as digits only: 1·1·4·0 reads 11:40, a fifth digit is not taken, UNLOCK solves it', (t) async {
      await pumpMission(t, const Size(390, 844));
      for (final d in ['1', '1', '4']) {
        await press(t, d);
      }
      expect([for (var i = 0; i < 4; i++) wheel(t, i)], ['1', '1', '4', '']);
      await press(t, '0');
      await press(t, '5'); // the wheels are full
      expect([for (var i = 0; i < 4; i++) wheel(t, i)], ['1', '1', '4', '0']);
      expect(find.byKey(const ValueKey('code-time-colon')), findsOneWidget, reason: 'still there, never a wheel');

      // Delete takes back the last digit, never the colon.
      await t.tap(find.bySemanticsLabel('Delete'));
      await t.pump(const Duration(milliseconds: 200));
      expect([for (var i = 0; i < 4; i++) wheel(t, i)], ['1', '1', '4', '']);
      await press(t, '0');

      await t.tap(find.text('UNLOCK'));
      await wait(t, const Duration(milliseconds: 1500));
      expect(appRef.read(gameControllerProvider).isCompleted('ep12_m2'), isTrue, reason: 'checked as 1140');
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('a wrong time on the board still gets its own feedback', (t) async {
      await pumpMission(t, const Size(390, 844));
      for (final d in ['1', '1', '0', '4']) {
        await press(t, d);
      }
      await t.tap(find.text('UNLOCK'));
      await wait(t, const Duration(milliseconds: 1200));
      expect(appRef.read(gameControllerProvider).isCompleted('ep12_m2'), isFalse);
      expect(find.textContaining('That is the Edinburgh train itself'), findsOneWidget);
      await wait(t, const Duration(seconds: 3));
    });
  });
}
