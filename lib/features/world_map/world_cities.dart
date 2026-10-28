import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import '../../data/models/season.dart';

/// A city on the World Map. Placed by its latitude and longitude, so a new
/// city is one more entry in [WorldCities.all]: the map artwork is never
/// redrawn for it.
@immutable
class WorldCity {
  const WorldCity({required this.id, required this.name, required this.latitude, required this.longitude, this.seasonId});

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

  /// Where the city is on the map artwork (fractions of its width / height):
  /// the artwork is equirectangular, longitude -180..180 across and latitude
  /// 90..-90 down.
  Offset get at => Offset((longitude + 180) / 360, (90 - latitude) / 180);
}

/// Every city on the World Map, in the order they are listed.
abstract final class WorldCities {
  static const london = WorldCity(
    id: 'london',
    name: 'London',
    latitude: 51.51,
    longitude: -0.13,
    seasonId: SeasonIds.london,
  );
  static const paris = WorldCity(
    id: 'paris',
    name: 'Paris',
    latitude: 48.86,
    longitude: 2.35,
    seasonId: SeasonIds.paris,
  );
  static const rome = WorldCity(id: 'rome', name: 'Rome', latitude: 41.90, longitude: 12.50);
  static const tokyo = WorldCity(id: 'tokyo', name: 'Tokyo', latitude: 35.68, longitude: 139.69);
  static const seoul = WorldCity(id: 'seoul', name: 'Seoul', latitude: 37.57, longitude: 126.98);

  static const all = [london, paris, rome, tokyo, seoul];

  /// The city of season [seasonId], or null.
  static WorldCity? ofSeason(String seasonId) {
    for (final c in all) {
      if (c.seasonId == seasonId) return c;
    }
    return null;
  }
}
