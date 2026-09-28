import '../mock/episode01_mock.dart';
import '../models/episode.dart';

/// Source of episode content. Swap [MockEpisodeRepository] for a remote
/// implementation (e.g. Firebase) without changing any UI code.
abstract interface class EpisodeRepository {
  Future<List<String>> availableEpisodeIds();

  Future<Episode> fetchEpisode(String id);
}

class MockEpisodeRepository implements EpisodeRepository {
  const MockEpisodeRepository();

  static const Map<String, Map<String, dynamic>> _episodes = {'ep01': episode01Json};

  @override
  Future<List<String>> availableEpisodeIds() async => _episodes.keys.toList();

  @override
  Future<Episode> fetchEpisode(String id) async {
    final json = _episodes[id];
    if (json == null) throw ArgumentError.value(id, 'id', 'Unknown episode');
    return Episode.fromJson(json);
  }
}
