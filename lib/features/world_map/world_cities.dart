import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import '../../data/models/season.dart';
import '../../widgets/art_assets.dart';

/// A city on the World Map. Placed where the artwork paints its marker
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

  /// The centre of the round marker the artwork paints for this city
  /// (fractions of its width / height), or null when it paints none. The
  /// artwork is an illustration, not a true projection, so a painted marker
  /// wins over [latitude] and [longitude].
  final Offset? mapAt;

  /// Where the city is on the map artwork (fractions of its width / height):
  /// its painted marker ([mapAt]), else its latitude and longitude, the
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
    mapAt: Offset(898 / 1983, 182 / 793),
  );
  static const paris = WorldCity(
    id: 'paris',
    name: 'Paris',
    latitude: 48.86,
    longitude: 2.35,
    seasonId: SeasonIds.paris,
    mapAt: Offset(964 / 1983, 250 / 793),
  );
  static const rome = WorldCity(
    id: 'rome',
    name: 'Rome',
    latitude: 41.90,
    longitude: 12.50,
    mapAt: Offset(1042 / 1983, 302 / 793),
  );
  static const tokyo = WorldCity(
    id: 'tokyo',
    name: 'Tokyo',
    latitude: 35.68,
    longitude: 139.69,
    mapAt: Offset(1735 / 1983, 322 / 793),
  );
  // The upper of the two markers by Korea.
  static const seoul = WorldCity(
    id: 'seoul',
    name: 'Seoul',
    latitude: 37.57,
    longitude: 126.98,
    mapAt: Offset(1632 / 1983, 297 / 793),
  );

  static const all = [london, paris, rome, tokyo, seoul];

  /// The city of season [seasonId], or null.
  static WorldCity? ofSeason(String seasonId) {
    for (final c in all) {
      if (c.seasonId == seasonId) return c;
    }
    return null;
  }
}
