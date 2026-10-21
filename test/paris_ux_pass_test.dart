import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/data/mock/season1/season1_discoveries.dart';
import 'package:london_mystery/data/mock/season2/season2_discoveries.dart';
import 'package:london_mystery/data/mock/season_catalog.dart';
import 'package:london_mystery/data/models/discovery.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/mission_map/map_world.dart';
import 'package:london_mystery/features/mission_map/mission_map_screen.dart';
import 'package:london_mystery/features/mission_map/widgets/map_pin.dart';

/// Paris Cases 01–05, the second UI pass: each Discovery Moment names its
/// kind (never the plain PUZZLE COMPLETE next to MISSION COMPLETE), the
/// landmark names keep clear of the current pin, and Case 05's M3 tells
/// only what its evidence shows.
void main() {
  final inGame = MockEpisodeRepository.bundled();
  final paris = [for (final e in inGame) if (e.id.startsWith('s2_')) e];

  group('Discovery Moments', () {
    test('every Paris mission names its kind, in its own success line; no reward or evidence card changes', () {
      expect(paris.map((e) => e.id), ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05']);
      for (final e in paris) {
        for (final m in e.missions) {
          final d = SeasonCatalog.discovery(m);
          expect(d.type, isNot(DiscoveryType.puzzleComplete), reason: m.id);
          expect(d.type, season2DiscoveryTypes[m.id], reason: m.id);
          expect(d.title, m.successMessage, reason: '${m.id}: no new words');
          expect(d.detail, isEmpty);
          expect(d.showEvidence, isFalse, reason: '${m.id}: as before, no card laid');
          expect(d.timing, DiscoveryTiming.fromPuzzle);
        }
        // The final has its own solve, never a Discovery Moment.
        expect(season2DiscoveryTypes.containsKey(e.finalMission.id), isFalse);
      }
      expect(season2DiscoveryTypes, hasLength(15));
    });

    test('Season 1 keeps its own Discovery Moments', () {
      for (final e in inGame.where((e) => !e.id.startsWith('s2_'))) {
        for (final m in e.missions) {
          final d = SeasonCatalog.discovery(m);
          final own = discoveryOf(m);
          expect((d.type, d.title, d.detail, d.showEvidence), (own.type, own.title, own.detail, own.showEvidence), reason: m.id);
        }
      }
    });
  });

  group('landmark names and the current pin', () {
    const world = Size(400, 600);
    const name = Size(90, 16);
    final l = ParisLandmark.artsEtMetiers;
    final point = Offset(l.at.dx * world.width, l.at.dy * world.height);
    final below = Offset(point.dx - landmarkNameWidth / 2, point.dy + landmarkNameDrop);

    test('only Paris keeps its names clear; London as it always was', () {
      expect(SeasonMap.paris.namesClearOfCurrent, isTrue);
      expect(SeasonMap.london.namesClearOfCurrent, isFalse);
      // Without the rule, the name stays below, whatever is there.
      expect(landmarkNameAt(l, world, name, current: point + const Offset(0, 40)), below);
    });

    test('below its landmark when clear; above when the current pin is there; left out when hemmed in', () {
      expect(landmarkNameAt(l, world, name, clearOfCurrent: true), below, reason: 'no current place');
      expect(landmarkNameAt(l, world, name, current: const Offset(20, 20), clearOfCurrent: true), below, reason: 'far away');
      // The current pin's YOU'RE HERE note just under the landmark point.
      final note = MapPin.currentMarks.first;
      final pinBelow = Offset(point.dx, point.dy + landmarkNameDrop - note.top);
      final above = landmarkNameAt(l, world, name, current: pinBelow, clearOfCurrent: true)!;
      expect(above.dy + name.height, lessThanOrEqualTo(point.dy), reason: 'lettered above its landmark');
      final aboveRect = Rect.fromLTWH(above.dx + (landmarkNameWidth - name.width) / 2, above.dy, name.width, name.height);
      for (final k in MapPin.currentMarks) {
        expect(k.shift(pinBelow).overlaps(aboveRect), isFalse);
      }
      // A current pin right on the landmark: its note covers above, its
      // name below. The landmark's name waits.
      expect(landmarkNameAt(l, world, name, current: point + const Offset(0, 40), clearOfCurrent: true), isNull);
    });

    test("a solved place's mark over the name moves it above, the same way", () {
      final mark = below + Offset(landmarkNameWidth / 2, name.height / 2);
      final at = landmarkNameAt(l, world, name, solved: [mark], clearOfCurrent: true)!;
      expect(at.dy + name.height, lessThanOrEqualTo(point.dy));
      expect(landmarkNameAt(l, world, name, solved: [mark]), below, reason: 'London: as it always was');
    });
  });

  test("Case 05 M3: the note's fact, then a question; nothing told that no evidence shows", () {
    final m3 = paris.last.missions[2];
    final all = m3.transition.join(' ');
    expect(all, isNot(contains('was taken out')));
    expect(all, isNot(contains('left in its place')));
    expect(all, isNot(contains('has gone into the post')));
    expect(m3.transition, containsAllInOrder(["The maker's note said the letter was hidden here.", 'Now it is gone. Did someone take it out?']));
    expect(m3.transition.first, 'Inside Clock III, there is no letter.');
    expect(m3.transition.last, 'Under the door, post slips have piled up.');
  });
}
