import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/data/mock/season2/paris_case01_draft.dart';
import 'package:london_mystery/data/mock/season2/season2_mock.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/season.dart';

void main() {
  test('Paris Case 01 draft parses with unique season-scoped mission ids', () {
    final episode = Episode.fromJson(parisCase01DraftJson);
    expect(episode.id, 's2_ep01');
    expect(episode.seasonId, SeasonIds.paris);
    expect(episode.missions, hasLength(3));
    expect(episode.allMissions.map((m) => m.id).toSet().length, 4);
    expect(episode.allMissions.every((m) => m.id.startsWith('s2_ep01_')), isTrue);
    expect(episode.finalMission.answer, 'TIME');
    expect(episode.missions[2].answer, '1000');
    expect(episode.missions[0].evidence?.inscription, 'T');
    expect(episode.missions[1].evidence?.inscription, 'I');
    expect(episode.missions[2].evidence?.inscription, 'M');
  });

  test('draft case is not yet published in the playable Paris catalog', () {
    expect(season2Json, isEmpty);
    expect(season2PrologueJson['firstCase']!['id'], parisCase01DraftJson['id']);
  });
}
