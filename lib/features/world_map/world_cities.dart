import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import '../../data/generated/generated_season_art.g.dart';
import '../../data/models/season.dart';
import '../../widgets/art_assets.dart';

/// A city on the World Map. Its pin stands by its landmark on the artwork
/// ([mapAt]), or else by its latitude and longitude, so a new city is one
/// more entry in [WorldCities.all]: the map artwork is never redrawn for it.
@immutable
class WorldCity {
  const WorldCity({required this.id, required this.name, required this.latitude, required this.longitude, this.seasonId, this.mapAt});

  final String id;

  /// "London", as the map and the card name it.
  final String name;

  /// Degrees, north positive.
  final double latitude;

  /// Degrees, east positive.
  final double longitude;

  /// The season played in this city ([SeasonIds]), or null: a city whose
  /// season is not made yet (always COMING SOON, whatever is solved).
  final String? seasonId;

  /// Where the tip of the city's pin goes on the artwork, by its landmark
  /// (fractions of its width / height), or null when the artwork has no
  /// landmark for it. The artwork is an illustration, not a true
  /// projection, so this wins over [latitude] and [longitude].
  final Offset? mapAt;

  /// Where the city is on the map artwork (fractions of its width / height):
  /// its pin's place ([mapAt]), else its latitude and longitude, the
  /// artwork read as equirectangular, its edges at the longitudes and
  /// latitudes in [ArtAssets] (`worldMapWest` .. `worldMapSouth`).
  Offset get at => mapAt ?? Offset(
    (longitude - ArtAssets.worldMapWest) / (ArtAssets.worldMapEast - ArtAssets.worldMapWest),
    (ArtAssets.worldMapNorth - latitude) / (ArtAssets.worldMapNorth - ArtAssets.worldMapSouth),
  );
}

/// Every city on the World Map, in the order they are listed.
abstract final class WorldCities {
  static const london = WorldCity(
    id: 'london',
    name: 'London',
    latitude: 51.51,
    longitude: -0.13,
    seasonId: SeasonIds.london,
    mapAt: Offset(897.5 / 1983, 209.5 / 793),
  );
  static const paris = WorldCity(
    id: 'paris',
    name: 'Paris',
    latitude: 48.86,
    longitude: 2.35,
    seasonId: SeasonIds.paris,
    mapAt: Offset(965.5 / 1983, 279.5 / 793),
  );
  static const rome = WorldCity(
    id: 'rome',
    name: 'Rome',
    latitude: 41.90,
    longitude: 12.50,
    mapAt: Offset(1038.5 / 1983, 330 / 793),
  );
  static const tokyo = WorldCity(
    id: 'tokyo',
    name: 'Tokyo',
    latitude: 35.68,
    longitude: 139.69,
    mapAt: Offset(1734 / 1983, 350.5 / 793),
  );
  static const seoul = WorldCity(
    id: 'seoul',
    name: 'Seoul',
    latitude: 37.57,
    longitude: 126.98,
    mapAt: Offset(1633 / 1983, 325 / 793),
  );

  /// The cities drawn on the map, a season's or coming soon.
  static const _drawn = [london, paris, rome, tokyo, seoul];

  /// Every city: one whose season is made from its plans (Rome on,
  /// [generatedWorldCities]) takes its season in its own place in the
  /// list; a new city goes after the ones drawn.
  static final all = [
    for (final c in _drawn) generatedWorldCities.where((g) => g.id == c.id).firstOrNull ?? c,
    for (final g in generatedWorldCities) if (!_drawn.any((c) => c.id == g.id)) g,
  ];

  /// The city of season [seasonId], or null.
  static WorldCity? ofSeason(String seasonId) {
    for (final c in all) {
      if (c.seasonId == seasonId) return c;
    }
    return null;
  }
}
