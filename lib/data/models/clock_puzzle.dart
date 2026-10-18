import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'mission.dart';

/// The two hands of a clock.
enum ClockHand { hour, minute }

/// A time on a twelve-hour clock face: minutes since 12:00 (0..719).
///
/// The hands move together, as on a real clock: the hour hand creeps on
/// with the minutes (half a degree a minute), and the minute hand passing
/// 12 carries the hour forward (or back).
@immutable
class ClockTime {
  const ClockTime(int minutes) : minutes = ((minutes % _day) + _day) % _day;

  factory ClockTime.at(int hour, int minute) => ClockTime((hour % 12) * 60 + minute);

  static const _day = 720;

  final int minutes;

  /// 1..12 (12, not 0, at the top).
  int get hour => minutes ~/ 60 == 0 ? 12 : minutes ~/ 60;
  int get minute => minutes % 60;

  /// Clockwise from 12, as `ClockHands` draws them.
  double get hourDegrees => minutes * 0.5;
  double get minuteDegrees => minute * 6.0;

  double degreesOf(ClockHand hand) => hand == ClockHand.hour ? hourDegrees : minuteDegrees;

  /// "8:17".
  String get label => '$hour:${minute.toString().padLeft(2, '0')}';

  /// The time as a puzzle answer is typed: hour then two-digit minutes
  /// ("817", "1205"), so a clock answers like the keypad it replaces.
  String get answer => '$hour${minute.toString().padLeft(2, '0')}';

  ClockTime plusMinutes(int delta) => ClockTime(minutes + delta);

  /// The minute hand moved to [degrees] (clockwise from 12): the nearest
  /// minute mark. Swept there ([carry]), it goes the short way round, so
  /// dragging it past 12 moves the hour on (forward) or back. Put there at
  /// once (a finger landing on the face), the hour stays.
  ClockTime withMinuteHandAt(double degrees, {bool carry = true}) {
    final target = (normalize(degrees) / 6).round() % 60;
    if (!carry) return ClockTime(minutes - minute + target);
    final delta = ((target - minute + 90) % 60) - 30; // -30..29
    return plusMinutes(delta);
  }

  /// The hour hand moved to [degrees]: the nearest hour whose hand, at the
  /// current minutes, stands there. The minutes stay as they are.
  ClockTime withHourHandAt(double degrees) {
    final h = ((normalize(degrees) - minute * 0.5) / 30).round() % 12;
    return ClockTime(h * 60 + minute);
  }

  ClockTime withHandAt(ClockHand hand, double degrees, {bool carry = true}) =>
      hand == ClockHand.hour ? withHourHandAt(degrees) : withMinuteHandAt(degrees, carry: carry);

  /// 0..360.
  static double normalize(double degrees) => ((degrees % 360) + 360) % 360;

  /// Clockwise from 12, of a point [dx], [dy] from the pivot (screen axes:
  /// y down).
  static double angleOf(double dx, double dy) => normalize(math.atan2(dx, -dy) * 180 / math.pi);

  @override
  bool operator ==(Object other) => other is ClockTime && other.minutes == minutes;

  @override
  int get hashCode => minutes.hashCode;

  @override
  String toString() => 'ClockTime($label)';
}

/// A mission played by setting the hands of a clock face (the presentation
/// of the mission's puzzle, never saved): the time set is submitted as the
/// mission's answer ([ClockTime.answer]), through the same check, feedback,
/// save and rewards as the keypad it replaces.
@immutable
class ClockPuzzle {
  const ClockPuzzle({
    required this.face,
    required this.question,
    required this.lead,
    required this.guide,
    required this.dialLabel,
    this.start = const (hour: 12, minute: 0),
    this.submitLabel = 'SET THE TIME',
  });

  /// The face picture (its file: `ArtAssets.scenes`; its pivot and hand
  /// lengths: `ArtAssets.clockHands`). The hands are the player's, never
  /// the time the scene shows.
  final Artwork face;

  /// The puzzle's heading in place of the mission's question (which says
  /// how to answer on a keypad).
  final String question;

  /// Who gives the clock and why, one line above it.
  final String lead;

  /// How to move the hands, one quiet line under the time.
  final String guide;

  /// The face, for screen readers.
  final String dialLabel;

  /// Where the hands start: never the answer.
  final ({int hour, int minute}) start;

  final String submitLabel;
}
