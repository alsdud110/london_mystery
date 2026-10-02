import '../mock/season1/episode01_mock.dart';
import '../mock/season1/season1_mock.dart';
import '../models/episode.dart';

/// Source of episode content. Swap [MockEpisodeRepository] for a remote
/// implementation (e.g. Firebase) without changing any UI code.
abstract interface class EpisodeRepository {
  Future<List<String>> availableEpisodeIds();

  Future<Episode> fetchEpisode(String id);
}

class MockEpisodeRepository implements EpisodeRepository {
  const MockEpisodeRepository();

  /// Season 1 in case order. Every entry is plain JSON (no widgets), so the
  /// same content can later come from a file or a server.
  static const Map<String, Map<String, dynamic>> _episodes = {'ep01': episode01Json, ...season1Json};

  /// Every bundled episode, parsed synchronously (the content ships with the
  /// app). Used as the default catalog, e.g. in tests.
  static List<Episode> bundled() => sortedByNumber([for (final json in _episodes.values) Episode.fromJson(json)]);

  static List<Episode> sortedByNumber(List<Episode> episodes) =>
      [...episodes]..sort((a, b) => a.number.compareTo(b.number));

  @override
  Future<List<String>> availableEpisodeIds() async => _episodes.keys.toList();

  @override
  Future<Episode> fetchEpisode(String id) async {
    final json = _episodes[id];
    if (json == null) throw ArgumentError.value(id, 'id', 'Unknown episode');
    return Episode.fromJson(json);
  }
}
