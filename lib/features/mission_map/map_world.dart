import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../../data/models/episode.dart';
import '../../data/models/mission.dart';
import '../../widgets/art_assets.dart';

/// The landmarks drawn on the London map artwork (`ArtAssets.londonMap`),
/// with where each one stands on it (fractions of the artwork's width /
/// height). The names are lettered by the app, not printed on the artwork.
///
/// These are *visual* positions only. A mission's `mapX` / `mapY` is its
/// place in the case's own layout and is left as it is; [MapWorld] puts the
/// mission on the landmark it happens at.
enum Landmark {
  kingsCross("King's Cross", Offset(0.53, 0.17)),
  britishMuseum('British Museum', Offset(0.385, 0.30)),
  coventGarden('Covent Garden', Offset(0.645, 0.34)),
  hydePark('Hyde Park', Offset(0.21, 0.44)),
  towerOfLondon('Tower of London', Offset(0.85, 0.45)),
  bigBen('Big Ben', Offset(0.53, 0.58)),
  buckinghamPalace('Buckingham Palace', Offset(0.245, 0.64)),
  londonEye('London Eye', Offset(0.69, 0.72)),
  towerBridge('Tower Bridge', Offset(0.915, 0.69));

  const Landmark(this.name, this.at);

  final String name;
  final Offset at;
}

/// Where every mission of a case is on the London map.
///
/// Most cases happen inside one landmark (the rooms of Big Ben, the galleries
/// of the British Museum), so a mission is placed on its [Landmark]; missions
/// that share a landmark are spread in a small group around it, keeping the
/// shape of their `mapX` / `mapY` layout. A mission with no landmark here is
/// placed at its `mapX` / `mapY`.
abstract final class MapWorld {
  /// Radius of a group of places around their landmark, as a fraction of
  /// the map height (horizontal offsets are scaled by the map aspect so the group
  /// is round on the map).
  static const groupRadius = 0.12;

  /// No place is higher on the map than this (fraction of the map height):
  /// the "YOU'RE HERE" note above a pin must fit inside the map, even with
  /// the camera stopped at the top edge. A group near the top is moved down
  /// as a whole, keeping its shape.
  static const topMargin = 0.15;

  /// The landmark each mission happens at.
  static const missionLandmarks = <String, Landmark>{
    // Case 01 — a tour of London.
    'm01': Landmark.kingsCross,
    'm02': Landmark.britishMuseum,
    'm03': Landmark.bigBen,
    'm04': Landmark.hydePark,
    'm05': Landmark.buckinghamPalace,
    'final': Landmark.buckinghamPalace, // the Royal Archive
    // Case 02 — Westminster Bridge and inside Big Ben.
    'ep02_m1': Landmark.bigBen,
    'ep02_m2': Landmark.bigBen,
    'ep02_m3': Landmark.bigBen,
    'ep02_final': Landmark.bigBen,
    // Case 03 — the British Museum.
    'ep03_m1': Landmark.britishMuseum,
    'ep03_m2': Landmark.britishMuseum,
    'ep03_m3': Landmark.britishMuseum,
    'ep03_final': Landmark.britishMuseum,
    // Case 04 — King's Cross station.
    'ep04_m1': Landmark.kingsCross,
    'ep04_m2': Landmark.kingsCross,
    'ep04_m3': Landmark.kingsCross,
    'ep04_final': Landmark.kingsCross,
    // Case 05 — the Tower of London.
    'ep05_m1': Landmark.towerOfLondon,
    'ep05_m2': Landmark.towerOfLondon,
    'ep05_m3': Landmark.towerOfLondon,
    'ep05_final': Landmark.towerOfLondon,
    // Case 06 — Covent Garden market and theatre.
    'ep06_m1': Landmark.coventGarden,
    'ep06_m2': Landmark.coventGarden,
    'ep06_m3': Landmark.coventGarden,
    'ep06_final': Landmark.coventGarden,
    // Case 07 — Hyde Park.
    'ep07_m1': Landmark.hydePark,
    'ep07_m2': Landmark.hydePark,
    'ep07_m3': Landmark.hydePark,
    'ep07_final': Landmark.hydePark,
    // Case 08 — King's Cross station.
    'ep08_m1': Landmark.kingsCross,
    'ep08_m2': Landmark.kingsCross,
    'ep08_m3': Landmark.kingsCross,
    'ep08_final': Landmark.kingsCross,
    // Case 09 — Buckingham Palace.
    'ep09_m1': Landmark.buckinghamPalace,
    'ep09_m2': Landmark.buckinghamPalace,
    'ep09_m3': Landmark.buckinghamPalace,
    'ep09_final': Landmark.buckinghamPalace,
    // Case 10 — the Tower, then Tower Bridge.
    'ep10_m1': Landmark.towerOfLondon,
    'ep10_m2': Landmark.towerOfLondon,
    'ep10_m3': Landmark.towerOfLondon,
    'ep10_final': Landmark.towerBridge,
    // Case 11 — the Covent Garden theatre, then Platform 9.
    'ep11_m1': Landmark.coventGarden,
    'ep11_m2': Landmark.coventGarden,
    'ep11_m3': Landmark.coventGarden,
    'ep11_final': Landmark.kingsCross,
    // Case 12 — back to the places of the season.
    'ep12_m1': Landmark.bigBen,
    'ep12_m2': Landmark.kingsCross,
    'ep12_m3': Landmark.towerOfLondon,
    'ep12_final': Landmark.bigBen, // under Big Ben
  };

  /// Each mission of [episode] (by id) at its place on the map.
  static Map<String, Offset> places(Episode episode) {
    final missions = episode.allMissions;
    final groups = <Landmark, List<Mission>>{};
    for (final m in missions) {
      final l = missionLandmarks[m.id];
      if (l != null) (groups[l] ??= []).add(m);
    }
    final raw = {
      for (final m in missions)
        m.id: switch (missionLandmarks[m.id]) {
          null => Offset(m.mapX, m.mapY),
          final l => l.at + _inGroup(m, groups[l]!),
        },
    };
    // Move a group (or a lone place) down from the top edge, all together.
    final drop = <String, double>{};
    for (final group in [...groups.values, for (final m in missions) if (missionLandmarks[m.id] == null) [m]]) {
      final top = group.map((m) => raw[m.id]!.dy).reduce(math.min);
      for (final m in group) {
        drop[m.id] = math.max(0, topMargin - top);
      }
    }
    return {for (final m in missions) m.id: raw[m.id]! + Offset(0, drop[m.id]!)};
  }

  /// [m]'s offset from its landmark: the group's `mapX` / `mapY` layout,
  /// centred on the landmark and scaled to [groupRadius].
  static Offset _inGroup(Mission m, List<Mission> group) {
    if (group.length < 2) return Offset.zero;
    final centre = group.fold(Offset.zero, (s, g) => s + Offset(g.mapX, g.mapY)) / group.length.toDouble();
    final reach = group.map((g) => (Offset(g.mapX, g.mapY) - centre).distance).reduce(math.max);
    if (reach == 0) return Offset.zero;
    final d = (Offset(m.mapX, m.mapY) - centre) / reach;
    return Offset(d.dx * groupRadius / ArtAssets.londonMapAspect, d.dy * groupRadius);
  }
}
