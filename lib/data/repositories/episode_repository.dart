import '../mock/season_catalog.dart';
import '../models/episode.dart';

/// Source of episode content (bundled with the app: the game is offline).
abstract interface class EpisodeRepository {
  Future<List<String>> availableEpisodeIds();

  Future<Episode> fetchEpisode(String id);
}

class MockEpisodeRepository implements EpisodeRepository {
  const MockEpisodeRepository();

  /// Every season's cases, season by season in case order. Every entry is
  /// plain JSON (no widgets), so the same content can later come from a file
  /// or a server.
  /// Each case is told its season here, from the season it is bundled in.
  static final Map<String, Map<String, dynamic>> _episodes = {
    for (final season in SeasonCatalog.all)
      for (final e in season.episodes.entries) e.key: {...e.value, 'seasonId': season.id},
  };

  /// Every bundled episode, parsed synchronously (the content ships with the
  /// app). Used as the default catalog, e.g. in tests.
  static List<Episode> bundled() => inPlayOrder([for (final json in _episodes.values) Episode.fromJson(json)]);

  static List<Episode> sortedByNumber(List<Episode> episodes) =>
      [...episodes]..sort((a, b) => a.number.compareTo(b.number));

  /// [episodes] season by season (in play order), each season's in case
  /// order: every season numbers its cases from 01.
  static List<Episode> inPlayOrder(List<Episode> episodes) => [...episodes]
    ..sort((a, b) {
      final bySeason = SeasonCatalog.indexOf(a.seasonId).compareTo(SeasonCatalog.indexOf(b.seasonId));
      return bySeason != 0 ? bySeason : a.number.compareTo(b.number);
    });

  @override
  Future<List<String>> availableEpisodeIds() async => _episodes.keys.toList();

  @override
  Future<Episode> fetchEpisode(String id) async {
    final json = _episodes[id];
    if (json == null) throw ArgumentError.value(id, 'id', 'Unknown episode');
    return Episode.fromJson(json);
  }
}
