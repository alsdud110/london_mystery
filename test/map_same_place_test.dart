import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/features/mission_map/widgets/london_map_painter.dart';

/// Two missions in a row at one place (one room, two puzzles: a map pin each,
/// at the same point): the way between them is empty, and the map still
/// paints (it threw `Bad state: No element` from `computeMetrics().first`).
void main() {
  void paint(LondonMapPainter p) {
    final recorder = PictureRecorder();
    p.paint(Canvas(recorder), const Size(800, 600));
    recorder.endRecording().dispose();
  }

  const room = Offset(0.3, 0.62);

  for (final shown in [0.0, 0.5, 1.0]) {
    test('the way to a place at the same point, $shown drawn: nothing to draw, no error', () {
      paint(LondonMapPainter(route: const [room, room, Offset(0.6, 0.4)], completedLegs: 1, drawMap: false, heading: AlwaysStoppedAnimation(shown)));
    });
  }

  test('a solved leg of no length, then a way on: painted', () {
    paint(LondonMapPainter(route: const [room, room, Offset(0.6, 0.4)], completedLegs: 2, drawMap: false, heading: const AlwaysStoppedAnimation(0.5)));
    paint(LondonMapPainter(route: const [room, room, room], completedLegs: 3, drawMap: true));
  });
}
