import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/season.dart';
import '../game/game_providers.dart';
import '../season/world_archive_screen.dart';
import 'world_cities.dart';

/// Where the detective stands with a city on the World Map.
enum WorldCityStatus {
  /// Its season can be played and has not begun.
  playable,

  /// Its season is under way.
  inProgress,

  /// Every case of its season is solved.
  completed,

  /// Its season waits on the season before it (Paris: London's last case).
  locked,

  /// Its season is not in the game: whatever is solved, it does not open.
  comingSoon,
}

/// One city on the map with its status. Worked out from the season files
/// ([seasonFilesProvider]); nothing of it is saved.
@immutable
class WorldCityState {
  const WorldCityState({required this.city, required this.status, this.file});

  /// [city] with its season's [file] (null: its season is not in the game).
  factory WorldCityState.of(WorldCity city, SeasonFile? file) => WorldCityState(
    city: city,
    file: file,
    status: switch (file?.state) {
      null || SeasonFileState.comingSoon => WorldCityStatus.comingSoon,
      SeasonFileState.sealed => WorldCityStatus.locked,
      SeasonFileState.notStarted => WorldCityStatus.playable,
      SeasonFileState.inProgress => WorldCityStatus.inProgress,
      SeasonFileState.completed => WorldCityStatus.completed,
    },
  );

  final WorldCity city;
  final WorldCityStatus status;

  /// Its season's file (null: no season in the game).
  final SeasonFile? file;

  Season? get season => file?.season;

  /// Whether its season can be played now.
  bool get canEnter => file?.canOpen ?? false;
}

/// Every city of the map with its status, in [WorldCities.all] order.
final worldCityStatesProvider = Provider<List<WorldCityState>>((ref) {
  final files = {for (final f in ref.watch(seasonFilesProvider)) f.season.id: f};
  return [
    for (final c in WorldCities.all) WorldCityState.of(c, c.seasonId == null ? null : files[c.seasonId]),
  ];
});

/// The city the map opens on (and goes back to): the city of the season
/// being played ([selectedSeasonId]) — or, once that season is complete,
/// the next season's city while it is open and not begun (London solved,
/// Paris not started: Paris). Only looked at: nothing is chosen by it.
String homeCityId({required String selectedSeasonId, required List<WorldCityState> cities}) {
  final playing = cities.where((c) => c.city.seasonId == selectedSeasonId).firstOrNull;
  if (playing == null) return (WorldCities.ofSeason(SeasonIds.london) ?? WorldCities.all.first).id;
  if (playing.status == WorldCityStatus.completed) {
    final next = cities
        .where((c) => c.file?.before?.id == selectedSeasonId && c.status == WorldCityStatus.playable)
        .firstOrNull;
    if (next != null) return next.city.id;
  }
  return playing.city.id;
}

/// [homeCityId] of the running game.
final homeCityIdProvider = Provider<String>(
  (ref) => homeCityId(
    selectedSeasonId: ref.watch(selectedSeasonIdProvider),
    cities: ref.watch(worldCityStatesProvider),
  ),
);
