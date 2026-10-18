import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/core/utils/answer_checker.dart';
import 'package:london_mystery/data/mock/season1/season1_clocks.dart';
import 'package:london_mystery/data/models/clock_puzzle.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/game_button.dart';
import 'package:london_mystery/widgets/landmark_art.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';
import 'mission_play.dart';
import 'title_screen_test.dart' show capture;

/// Case 02 Mission 01 played on Mrs Bell's clock face: the detective sets
/// the hands where her note says she saw them (8:17), by dragging them or
/// with the HOUR and MINUTE keys. The time set is the keypad's answer, so
/// the case data, its check, feedback, hints and rewards are unchanged.
void main() {
  final season = MockEpisodeRepository.bundled();
  final ep02 = season.firstWhere((e) => e.id == 'ep02');
  final m1 = ep02.missionById('ep02_m1')!;

  group('the clock', () {
    test('12:00 is 12, not 0; the answer reads like the keypad', () {
      const noon = ClockTime(0);
      expect(noon.hour, 12);
      expect(noon.label, '12:00');
      expect(noon.answer, '1200');
      expect(ClockTime.at(8, 17).answer, '817');
      expect(ClockTime.at(8, 17).label, '8:17');
      expect(ClockTime.at(12, 5).answer, '1205');
    });

    test('the hands move together, as ClockHands draws them', () {
      for (var t = 0; t < 720; t += 7) {
        final c = ClockTime(t);
        expect(c.hourDegrees, ClockHands.hourDegreesAt(c.hour, c.minute), reason: c.label);
        expect(c.minuteDegrees, ClockHands.minuteDegreesAt(c.minute), reason: c.label);
      }
      expect(ClockTime.at(8, 17).hourDegrees, 248.5, reason: 'past VIII, toward IX');
    });

    test('the minute hand goes one minute mark at a time', () {
      const noon = ClockTime(0);
      expect(noon.withMinuteHandAt(102).label, '12:17');
      expect(noon.withMinuteHandAt(104.9).label, '12:17', reason: 'the nearest mark');
      expect(noon.withMinuteHandAt(90).label, '12:15');
      expect(noon.withMinuteHandAt(192).label, '11:32', reason: 'swept the short way, back past 12');
      expect(noon.withMinuteHandAt(192, carry: false).label, '12:32', reason: 'put there at once: the hour stays');
      for (var m = 0; m < 60; m++) {
        expect(ClockTime.at(3, 0).withMinuteHandAt(m * 6.0).minute, m);
      }
    });

    test('past 12 the minute hand carries the hour, both ways', () {
      expect(ClockTime.at(8, 58).withMinuteHandAt(6).label, '9:01');
      expect(ClockTime.at(9, 2).withMinuteHandAt(348).label, '8:58');
      expect(ClockTime.at(11, 59).withMinuteHandAt(0).label, '12:00');
      expect(ClockTime.at(12, 0).withMinuteHandAt(354).label, '11:59');
    });

    test('the hour hand keeps the minutes and stops on an hour', () {
      expect(ClockTime.at(12, 17).withHourHandAt(248.5).label, '8:17');
      expect(ClockTime.at(12, 17).withHourHandAt(245).label, '8:17', reason: 'the nearest hour');
      expect(ClockTime.at(12, 17).withHourHandAt(270).label, '9:17');
      expect(ClockTime.at(1, 30).withHourHandAt(10).label, '12:30');
    });

    test('the keys step past 12 both ways', () {
      expect(const ClockTime(0).plusMinutes(-1).label, '11:59');
      expect(ClockTime.at(11, 59).plusMinutes(1).label, '12:00');
      expect(ClockTime.at(12, 30).plusMinutes(-60).label, '11:30');
      expect(ClockTime.at(11, 30).plusMinutes(60).label, '12:30');
    });
  });

  group('the case is kept', () {
    test('only Case 02 Mission 01 is played on a clock', () {
      expect(season1Clocks.keys, ['ep02_m1']);
      for (final e in season) {
        for (final m in e.allMissions) {
          expect(clockPuzzleOf(m) != null, m.id == 'ep02_m1', reason: m.id);
        }
      }
    });

    test('the mission data is as it was: a keypad answer, 817', () {
      expect(m1.type, MissionType.numberCode);
      expect(m1.answer, '817');
      expect(m1.hints, hasLength(2));
      expect(m1.clue!.value, '8:17');
      expect(m1.evidence!.id, 'ep02_e1');
    });

    test('the time set is checked as the keypad answer was, with its feedback', () {
      String? said(int h, int m) => AnswerChecker.feedbackFor(m1, ClockTime.at(h, m).answer);
      expect(AnswerChecker.isCorrect(m1, ClockTime.at(8, 17).answer), isTrue);
      expect(said(8, 15), contains('two more small marks'));
      expect(said(8, 32), contains('fifteen minutes'));
      expect(said(9, 17), contains('not reached nine'));
      expect(AnswerChecker.isCorrect(m1, const ClockTime(0).answer), isFalse);
    });

    test('the clock never starts at the answer and writes no time', () {
      final clock = clockPuzzleOf(m1)!;
      expect(ClockTime.at(clock.start.hour, clock.start.minute).answer, isNot(m1.answer));
      final time = RegExp(r'\d{1,2}\s*[:.]\s*\d{2}|\b\d{3,4}\b');
      for (final line in [clock.question, clock.lead, clock.guide, clock.dialLabel, clock.submitLabel]) {
        expect(time.hasMatch(line), isFalse, reason: line);
      }
      expect(ArtAssets.clockHands[clock.face], isNotNull, reason: 'its pivot and hands are measured');
    });
  });

  group('on screen', () {
    Finder dialBox() => find.descendant(of: find.byKey(const ValueKey('clock-dial')), matching: find.byType(Listener)).first;
    String shown(WidgetTester t) => t.widget<Text>(find.byKey(const ValueKey('clock-time'))).data!;

    /// A point on the face: [degrees] clockwise from 12, [radius] a
    /// fraction of the face's width from its pivot.
    Offset onFace(WidgetTester t, double degrees, double radius) {
      final box = t.getRect(dialBox());
      final art = ArtAssets.clockHands[clockPuzzleOf(m1)!.face]!;
      final pivot = box.topLeft + Offset(art.pivot.dx * box.width, art.pivot.dy * box.width);
      final a = degrees * math.pi / 180;
      return pivot + Offset(math.sin(a), -math.cos(a)) * (radius * box.width);
    }

    /// Drags on the face from [from] to [to] degrees at [radius], in small
    /// steps, as a finger sweeps round.
    Future<void> sweep(WidgetTester t, double from, double to, double radius) async {
      final g = await t.startGesture(onFace(t, from, radius));
      await t.pump();
      final steps = ((to - from).abs() / 6).ceil();
      for (var i = 1; i <= steps; i++) {
        await g.moveTo(onFace(t, from + (to - from) * i / steps, radius));
        await t.pump();
      }
      await g.up();
      await t.pump(const Duration(milliseconds: 100));
    }

    for (final size in const [Size(360, 640), Size(430, 932)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('$tag: the clock face at 12:00, no keypad, SET THE TIME waits', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep02_m1');
        final clock = clockPuzzleOf(m1)!;
        expect(find.byKey(const ValueKey('clock-dial')), findsOneWidget);
        expect(find.text('UNLOCK'), findsNothing, reason: 'the keypad is gone');
        expect(findReadable(clock.question), findsOneWidget);
        expect(findReadable(m1.question), findsNothing, reason: 'no "type" heading over a clock');
        expect(find.text(clock.lead), findsOneWidget);
        expect(shown(t), '12:00');
        final hands = t.widget<CustomPaint>(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is ClockHandsPainter));
        expect((hands.painter! as ClockHandsPainter).hourDegrees, 0, reason: 'not the stopped time');
        expect(t.widget<GameButton>(find.byKey(const ValueKey('clock-submit'))).onPressed, isNull);
        await reveal(t, find.byKey(const ValueKey('clock-submit')));
        await reveal(t, find.byKey(const ValueKey('clock-dial')));
        await capture(t, 'case02_clock_start_$tag');
        await reveal(t, find.text('Reread Letter'));
      });

      testWidgets('$tag: drag the minute hand, then the hour hand, to 8:17', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep02_m1');
        await reveal(t, find.byKey(const ValueKey('clock-dial')));
        // Both hands up at 12: beyond the short hand's tip is the long one.
        await sweep(t, 0, 90, 0.27);
        expect(shown(t), '12:15');
        await sweep(t, 90, 102, 0.27);
        expect(shown(t), '12:17', reason: 'one minute mark at a time');
        // The short hand (just past 12 at 12:17), turned back to past VIII.
        await sweep(t, 8.5, -111.5, 0.10);
        expect(shown(t), '8:17');
        expect(t.widget<GameButton>(find.byKey(const ValueKey('clock-submit'))).onPressed, isNotNull);
        final hands = t.widget<CustomPaint>(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is ClockHandsPainter));
        expect((hands.painter! as ClockHandsPainter).hourDegrees, 248.5);
        expect((hands.painter! as ClockHandsPainter).minuteDegrees, 102);
        await capture(t, 'case02_clock_817_$tag');
      });

      testWidgets('$tag: the minute hand dragged past 12 moves the hour on and back', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep02_m1');
        await play.setClock(t, 8, 50);
        await reveal(t, find.byKey(const ValueKey('clock-dial')));
        await sweep(t, 300, 366, 0.27);
        expect(shown(t), '9:01');
        await sweep(t, 6, -12, 0.27);
        expect(shown(t), '8:58');
        // The keys too.
        await play.setClock(t, 12, 0, from: 8 * 60 + 58);
        expect(shown(t), '12:00');
        await play.tapKey(t, 'clock-minute-minus', after: const Duration(milliseconds: 60));
        expect(shown(t), '11:59');
        await play.tapKey(t, 'clock-minute-plus', after: const Duration(milliseconds: 60));
        expect(shown(t), '12:00');
        await play.tapKey(t, 'clock-hour-minus', after: const Duration(milliseconds: 60));
        expect(shown(t), '11:00');
      });

      testWidgets('$tag: a drag on the face turns a hand, never scrolls the page', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep02_m1');
        await reveal(t, find.byKey(const ValueKey('clock-dial')));
        final top = t.getRect(dialBox()).top;
        final g = await t.startGesture(onFace(t, 180, 0.27));
        for (var i = 1; i <= 4; i++) {
          await g.moveBy(const Offset(0, -10));
          await t.pump();
        }
        await g.up();
        await t.pumpAndSettle();
        expect(t.getRect(dialBox()).top, top, reason: 'the page stayed put');
        expect(shown(t), isNot('12:00'), reason: 'a hand moved');
      });

      testWidgets('$tag: 8:15, 8:32, 9:17 are wrong with their own lines; 8:17 solves', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep02_m1');
        var at = 0;
        for (final (h, m, line) in const [
          (8, 15, 'two more small marks'),
          (8, 32, 'fifteen minutes'),
          (9, 17, 'not reached nine'),
        ]) {
          await play.setClock(t, h, m, from: at);
          at = (h % 12) * 60 + m;
          await play.tapKey(t, 'clock-submit', after: const Duration(milliseconds: 600));
          expect(find.text('Not quite!'), findsOneWidget, reason: '$h:$m');
          expect(find.textContaining(line), findsOneWidget, reason: '$h:$m');
          await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
          expect(shown(t), ClockTime.at(h, m).label, reason: 'the hands stay where they were set');
        }
        await play.setClock(t, 8, 17, from: at);
        await play.tapKey(t, 'clock-submit', after: const Duration(milliseconds: 1200));
        final progress = play.ref.read(gameControllerProvider);
        expect(progress.isCompleted('ep02_m1'), isTrue);
        expect(progress.wrongCount('ep02_m1'), 3);
        expect(progress.isUnlocked(ep02, 'ep02_m2'), isTrue);
        expect(
          findReadable('The hour hand between eight and nine, the minutes at seventeen: the moment Big Ben stopped.'),
          findsOneWidget,
          reason: 'its Discovery Moment',
        );
      });

      testWidgets('$tag: both hints open on the clock page', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep02_m1');
        await tapText(t, 'Get a Free Hint', after: const Duration(milliseconds: 600));
        await takeTipFromSheet(t);
        await wait(t, const Duration(milliseconds: 400));
        await reveal(t, findReadable(m1.hints[0]));
        expect(findReadable(m1.hints[0]), findsOneWidget);
        await tapText(t, 'Get More Hints', after: const Duration(milliseconds: 600));
        await takeTipFromSheet(t);
        await wait(t, const Duration(milliseconds: 400));
        await reveal(t, findReadable(m1.hints[1]));
        expect(findReadable(m1.hints[1]), findsOneWidget);
        expect(find.text('Get More Hints'), findsNothing, reason: 'at most two');
        expect(find.byKey(const ValueKey('clock-dial')), findsOneWidget, reason: 'the clock stays');
      });

      testWidgets('$tag: back to the letter keeps the hands; a new visit starts at 12:00', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep02_m1');
        await play.setClock(t, 8, 15);
        Future<void> back() async {
          await t.tap(find.byWidgetPredicate((w) => w is IconButton && (w.tooltip == 'Back' || w.tooltip == 'Back to map')));
          await wait(t, const Duration(milliseconds: 800));
        }

        await back();
        expect(find.byKey(const ValueKey('clock-dial')), findsNothing, reason: 'the letter step');
        await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
        expect(shown(t), '8:15', reason: 'where they were set');
        // Away to the map and back: the puzzle again, the hands at the start.
        await back();
        await back();
        await back();
        expect(play.path(), Routes.map);
        play.ref.read(routerProvider).go(Routes.mission('ep02_m1'));
        await wait(t, const Duration(milliseconds: 1200));
        expect(shown(t), '12:00');
        expect(t.widget<GameButton>(find.byKey(const ValueKey('clock-submit'))).onPressed, isNull);
      });
    }

    testWidgets('360x640, text ×1.3: everything reachable, solved with the keys', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(360, 640), 'ep02_m1', textScale: 1.3);
      for (final key in ['clock-dial', 'clock-hour-minus', 'clock-minute-plus', 'clock-submit']) {
        await reveal(t, find.byKey(ValueKey(key)));
        expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
      }
      await reveal(t, find.byKey(const ValueKey('clock-dial')));
      await capture(t, 'case02_clock_text13');
      await play.solve(t, m1);
      await wait(t, const Duration(milliseconds: 1200));
      expect(play.ref.read(gameControllerProvider).isCompleted('ep02_m1'), isTrue);
    });

    testWidgets('screen readers: the face says its time; the keys say what they do', (t) async {
      final semantics = t.ensureSemantics();
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'ep02_m1');
      final face = clockPuzzleOf(m1)!.dialLabel;
      expect(t.getSemantics(find.bySemanticsLabel(face)).value, '12:00');
      for (final label in ['HOUR forward', 'HOUR back', 'MINUTE forward', 'MINUTE back', 'HOUR hand', 'MINUTE hand']) {
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      }
      await play.tapKey(t, 'clock-hour-plus', after: const Duration(milliseconds: 60));
      expect(t.getSemantics(find.bySemanticsLabel(face)).value, '1:00');
      expect(find.bySemanticsLabel('Time on the clock: 1:00'), findsOneWidget);
      semantics.dispose();
    });
  });
}
