import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import '../../data/mock/season_catalog.dart';
import '../../data/models/episode.dart';
import '../../data/models/mission.dart';
import '../../data/models/season.dart';
import '../../widgets/art_assets.dart';

/// A landmark drawn on a season's map artwork, lettered by the app.
abstract interface class MapLandmark {
  String get name;

  /// Where it stands on the artwork (fractions of its width / height).
  Offset get at;

  /// Its scene picture key (see `ArtAssets.scenes`), or null while the
  /// landmark has no scene picture (the place's own scene is shown then).
  Artwork? get artwork;
}

/// A season's map: its artwork, the landmarks lettered on it, and the
/// landmark each of its missions happens at. Each season has its own; a
/// season without one has no map yet (see [forSeason]).
class SeasonMap {
  const SeasonMap({
    required this.artwork,
    required this.pixels,
    required this.aspect,
    required this.landmarks,
    this.missionLandmarks = const {},
    this.caseLandmarks = const {},
    this.groupHeights = const {},
  });

  /// The map artwork asset.
  final String artwork;

  /// Its pixel size: it is never decoded larger than this.
  final Size pixels;

  /// Width / height of the artwork: the map world keeps this ratio.
  final double aspect;

  final List<MapLandmark> landmarks;

  /// The landmark of a mission, by mission id: every mission of Season 1;
  /// in a season mapped by case, only a mission away from its case's place.
  final Map<String, MapLandmark> missionLandmarks;

  /// The landmark every mission of a case happens at, by case id (a mission
  /// in [missionLandmarks] is placed there instead). Several cases may share
  /// a landmark: the map shows the missions of the case being played only.
  final Map<String, MapLandmark> caseLandmarks;

  /// How tall the group of places around a landmark is, as a share of
  /// [MapWorld.groupRadius] (its width stays the same). Only for a landmark
  /// drawn at the very top of the artwork: its group must stay below the
  /// top margin, and a full-height group would be pushed far below the
  /// landmark. None on London's map.
  final Map<MapLandmark, double> groupHeights;

  /// Where mission [missionId] of case [episodeId] happens on this map: its
  /// own landmark, else its case's, else none.
  MapLandmark? landmarkFor(String missionId, String episodeId) =>
      missionLandmarks[missionId] ?? caseLandmarks[episodeId];

  /// Season 1's London map, as it always was.
  static const london = SeasonMap(
    artwork: ArtAssets.londonMap,
    pixels: ArtAssets.londonMapPixels,
    aspect: ArtAssets.londonMapAspect,
    landmarks: Landmark.values,
    missionLandmarks: MapWorld.missionLandmarks,
  );

  /// Season 2's Paris map: its twelve cases at ten landmarks, by case.
  static const paris = SeasonMap(
    artwork: ArtAssets.parisMap,
    pixels: ArtAssets.parisMapPixels,
    aspect: ArtAssets.parisMapAspect,
    landmarks: ParisLandmark.values,
    caseLandmarks: ParisLandmark.cases,
    // Sacré-Cœur stands above the top margin: a full-height group there was
    // pushed 0.17 down, off the hill. At 0.6 of the height its places stay
    // between the basilica's steps and the foot of the hill, still apart.
    groupHeights: {ParisLandmark.montmartre: 0.6},
  );

  /// Every season's map by season id. A season without one is not ready:
  /// it cannot be entered (see `SeasonAvailability`), and no other season's
  /// map ever stands in for it. A map alone opens no season: it needs its
  /// cases too.
  static const bySeason = {SeasonIds.london: london, SeasonIds.paris: paris};

  /// The map of season [seasonId], or null while it has none.
  static SeasonMap? forSeason(String seasonId) => bySeason[seasonId];

  /// The map of the season mission [missionId] belongs to (Season 1 for a
  /// mission no season has), or null while that season has none.
  static SeasonMap? ofMission(String missionId) =>
      forSeason(SeasonCatalog.ofMission(missionId)?.id ?? SeasonIds.london);

  /// The landmark mission [missionId] happens at, on its season's map (mission
  /// ids are never shared between seasons), or null.
  static MapLandmark? landmarkOf(String missionId) {
    final episodeId = SeasonCatalog.episodeOfMission(missionId);
    for (final map in bySeason.values) {
      final l = episodeId == null ? map.missionLandmarks[missionId] : map.landmarkFor(missionId, episodeId);
      if (l != null) return l;
    }
    return null;
  }
}

/// The landmarks drawn on the Paris map artwork (`ArtAssets.parisMap`), at
/// the centre of each one's drawing, measured on the artwork (fractions of
/// its width / height). The names are lettered by the app. No scene
/// pictures yet: each place shows its own scene.
enum ParisLandmark implements MapLandmark {
  gareDuNord('Gare du Nord', Offset(0.768, 0.200)),
  // Sacré-Cœur, above the top margin: its places sit just below it, on the hill.
  montmartre('Montmartre', Offset(0.555, 0.098)),
  // The west end of the green bookstalls, clear of Notre-Dame's name.
  seineQuays('Seine Quays', Offset(0.602, 0.596)),
  louvre('Louvre', Offset(0.501, 0.441)),
  notreDame('Notre-Dame', Offset(0.732, 0.566)),
  eiffelTower('Eiffel Tower', Offset(0.120, 0.562)),
  palaisGarnier('Palais Garnier', Offset(0.391, 0.273)),
  luxembourgGardens('Luxembourg Gardens', Offset(0.475, 0.771)),
  arcDeTriomphe('Arc de Triomphe', Offset(0.128, 0.246)),
  artsEtMetiers('Arts et Métiers', Offset(0.684, 0.381));

  const ParisLandmark(this.name, this.at);

  @override
  final String name;
  @override
  final Offset at;

  @override
  Artwork? get artwork => null;

  /// Season 2's cases at their landmarks. Montmartre has Case 02 and Case 08
  /// (Abbesses is on its hill); the Luxembourg Gardens Case 09 and Case 11
  /// (Saint-Sulpice is at their north edge). Case 03 climbs the Eiffel
  /// Tower, the tower drawn on the painter's canvas; its brass plaque
  /// points Case 04 to the Seine; Case 06 (place only, 2026-10-21) is at
  /// the Louvre.
  static const cases = <String, MapLandmark>{
    's2_ep01': gareDuNord,
    's2_ep02': montmartre,
    's2_ep03': eiffelTower,
    's2_ep04': seineQuays,
    's2_ep05': notreDame,
    's2_ep06': louvre,
    's2_ep07': palaisGarnier,
    's2_ep08': montmartre,
    's2_ep09': luxembourgGardens,
    's2_ep10': arcDeTriomphe,
    's2_ep11': luxembourgGardens,
    's2_ep12': artsEtMetiers,
  };
}

/// The landmarks drawn on the London map artwork (`ArtAssets.londonMap`),
/// with where each one stands on it (fractions of the artwork's width /
/// height). The names are lettered by the app, not printed on the artwork.
///
/// These are *visual* positions only. A mission's `mapX` / `mapY` is its
/// place in the case's own layout and is left as it is; [MapWorld] puts the
/// mission on the landmark it happens at.
enum Landmark implements MapLandmark {
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

  @override
  final String name;
  @override
  final Offset at;

  /// The landmark's scene picture key (its picture: `ArtAssets.scenes`).
  @override
  Artwork get artwork => switch (this) {
    kingsCross => Artwork.kingsCross,
    britishMuseum => Artwork.britishMuseum,
    coventGarden => Artwork.coventGarden,
    hydePark => Artwork.hydePark,
    towerOfLondon => Artwork.towerOfLondon,
    bigBen => Artwork.bigBen,
    buckinghamPalace => Artwork.buckinghamPalace,
    londonEye => Artwork.londonEye,
    towerBridge => Artwork.towerBridge,
  };
}

/// Where every mission of a case is on its season's map (London by default).
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

  /// The landmark each mission of Season 1 happens at (see [SeasonMap.london]).
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

  /// Each mission of [episode] (by id) at its place on [map].
  static Map<String, Offset> places(Episode episode, {SeasonMap map = SeasonMap.london}) {
    MapLandmark? landmarkOf(Mission m) => map.landmarkFor(m.id, episode.id);
    final missions = episode.allMissions;
    final groups = <MapLandmark, List<Mission>>{};
    for (final m in missions) {
      final l = landmarkOf(m);
      if (l != null) (groups[l] ??= []).add(m);
    }
    final raw = {
      for (final m in missions)
        m.id: switch (landmarkOf(m)) {
          null => Offset(m.mapX, m.mapY),
          final l => l.at + _inGroup(m, groups[l]!, map.aspect, height: map.groupHeights[l] ?? 1),
        },
    };
    // Move a group (or a lone place) down from the top edge, all together.
    final drop = <String, double>{};
    for (final group in [...groups.values, for (final m in missions) if (landmarkOf(m) == null) [m]]) {
      final top = group.map((m) => raw[m.id]!.dy).reduce(math.min);
      for (final m in group) {
        drop[m.id] = math.max(0, topMargin - top);
      }
    }
    return {for (final m in missions) m.id: raw[m.id]! + Offset(0, drop[m.id]!)};
  }

  /// [m]'s offset from its landmark: the group's `mapX` / `mapY` layout,
  /// centred on the landmark and scaled to [groupRadius] ([height] of it
  /// up and down: see [SeasonMap.groupHeights]).
  static Offset _inGroup(Mission m, List<Mission> group, double aspect, {double height = 1}) {
    if (group.length < 2) return Offset.zero;
    final centre = group.fold(Offset.zero, (s, g) => s + Offset(g.mapX, g.mapY)) / group.length.toDouble();
    final reach = group.map((g) => (Offset(g.mapX, g.mapY) - centre).distance).reduce(math.max);
    if (reach == 0) return Offset.zero;
    final d = (Offset(m.mapX, m.mapY) - centre) / reach;
    return Offset(d.dx * groupRadius / aspect, height == 1 ? d.dy * groupRadius : d.dy * groupRadius * height);
  }
}
