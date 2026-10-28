import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/content/season_content_validator.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/scene_explore.dart' show ScenePixels;
import 'package:world_mystery/data/models/scene_place.dart';
import 'package:world_mystery/widgets/art_assets.dart';

import 'helpers.dart';

/// The rules every season keeps (`SeasonContentValidator`): the game's
/// seasons pass them, and a test season (never in the catalog) shows each
/// kind of mistake is found, with where it is.
void main() {
  test('every season of the catalog keeps the common rules, its places bundled at their size', () {
    expect(SeasonContentValidator.validateAll(SeasonCatalog.all), isEmpty);
    expect(placeAssetProblems({for (final s in SeasonCatalog.all) ...s.places}), isEmpty);
  });

  const station = ScenePlace(file: ArtAssets.season2GareDuNord, pixels: ScenePixels(941, 1671));

  /// Mission [n] of test case [caseId] (`<caseId>_m<n>`, the last one its
  /// `final`), a choice of a, b, c at the season's station: [edit] changes
  /// its JSON.
  Map<String, dynamic> mission(String caseId, int n, {required bool last, void Function(Map<String, dynamic>)? edit}) {
    String id(int k) => k == 3 ? '${caseId}_final' : '${caseId}_m$k';
    final json = <String, dynamic>{
      'id': id(n),
      'number': n,
      'title': 'Mission $n',
      'location': 'STATION',
      'story': ['A line.'],
      'sceneKey': 's3_test.station',
      'letterIntro': '',
      'letter': '',
      'type': 'multipleChoice',
      'question': 'Which one?',
      'options': [
        for (final o in ['a', 'b', 'c']) {'id': o, 'label': 'Door ${o.toUpperCase()}'},
      ],
      'answer': 'b',
      'hints': ['Look at the sign.'],
      if (!last) 'clue': {'id': '${id(n)}_c', 'title': 'Clue', 'value': '$n', 'note': 'A note.'},
      'evidence': {'id': '${id(n)}_e', 'name': 'Ticket', 'icon': 'ticket', 'description': 'A ticket.'},
      'successMessage': 'Well done.',
      if (!last) 'transition': ['On we go.'],
      if (!last) 'nextMissionId': id(n + 1),
      'mapX': 0.5,
      'mapY': 0.5,
    };
    edit?.call(json);
    return json;
  }

  Map<String, dynamic> testCase(String id, int number, {Map<int, void Function(Map<String, dynamic>)> edits = const {}}) => {
    'id': id,
    'seasonId': 's3_test',
    'number': number,
    'title': 'Case $number',
    'synopsis': ['A case.'],
    'objectives': ['Find it.'],
    'intro': ['It begins.'],
    'missions': [for (final n in [1, 2]) mission(id, n, last: false, edit: edits[n])],
    'finalMission': mission(id, 3, last: true, edit: edits[3]),
  };

  SeasonContent season({
    Map<String, dynamic> info = const {},
    Map<String, Map<String, dynamic>>? episodes,
    Map<String, ScenePlace> places = const {'s3_test.station': station},
    Map<Difficulty, Map<String, Map<String, Object?>>> casePatches = const {},
    Map<String, Set<Difficulty>> writtenLevels = const {},
  }) => SeasonContent(
    info: {'id': 's3_test', 'number': 3, 'title': 'Test', 'tagline': 'TEST', 'cases': 2, ...info},
    episodes: episodes ?? {'s3_ep01': testCase('s3_ep01', 1), 's3_ep02': testCase('s3_ep02', 2)},
    places: places,
    casePatches: casePatches,
    writtenLevels: writtenLevels,
  );

  List<String> issues(SeasonContent s) => [for (final i in SeasonContentValidator.validateAll([...SeasonCatalog.all, s])) '$i'];

  test('a well-formed new season passes with no code of its own', () {
    expect(issues(season()), isEmpty);
    expect(placeAssetProblems(season().places), isEmpty);
  });

  test('seasons and cases: ids, numbers, order and planned cases', () {
    final found = issues(season(
      info: {'id': 's2_paris', 'number': 5, 'cases': 1, 'upcoming': {'1': 'Taken'}},
      episodes: {
        's3_ep01': testCase('s3_ep01', 1),
        's3_ep02': testCase('s3_ep03', 3),
        'ep02': testCase('ep02', 4),
      },
    ));
    for (final want in [
      '[season] s2_paris: season id registered twice',
      '[season] s2_paris: number 5, but it is season 3 in the catalog',
      '[case] s2_paris s3_ep02: registered as s3_ep02, but its id is s3_ep03',
      '[case] s2_paris s3_ep02: Case 03 is case 2 of the season',
      '[case] s2_paris ep02: case id ep02 is also used by s1_london',
      '[mission] s2_paris ep02 ep02_m1: mission id ep02_m1 is also used by s1_london',
      '[progress] s2_paris: 3 cases written for 1 planned',
      '[progress] s2_paris: upcoming title for Case 1',
      '[case] s2_paris s3_ep01: read as a case of s3_test',
    ]) {
      expect(found, anyElement(contains(want)), reason: want);
    }
  });

  test('missions: broken links, loops, answers not among the options, hints that tell', () {
    final found = issues(season(episodes: {
      's3_ep01': testCase('s3_ep01', 1, edits: {
        1: (m) => m
          ..['nextMissionId'] = 's3_ep01_m9'
          ..['hints'] = ['It is Door B.'],
        2: (m) => m['nextMissionId'] = 's3_ep01_m1',
        3: (m) => m
          ..['answer'] = 'd',
      }),
      's3_ep02': testCase('s3_ep02', 2, edits: {
        1: (m) => m
          ..['id'] = 's3_ep01_m1'
          ..['options'] = [
            {'id': 'a', 'label': 'A'},
            {'id': 'a', 'label': 'B'},
          ]
          ..['answer'] = 'a',
        2: (m) => m
          ..['type'] = 'letterLock'
          ..['answer'] = 'TIME'
          ..['options'] = [
            for (final l in 'TIMS'.split('')) {'id': l.toLowerCase(), 'label': l},
          ],
        3: (m) => m
          ..['answer'] = 'c'
          ..['feedback'] = {'c': 'Not that one.'},
      }),
    }));
    for (final want in [
      's3_ep01 s3_ep01_m1: leads to s3_ep01_m9, not a mission of the case',
      's3_ep01 s3_ep01_m2: leads back to s3_ep01_m1: a loop',
      '[answer] s3_test s3_ep01 s3_ep01_final: answer d is not an option',
      '[hint] s3_test s3_ep01 s3_ep01_m1: rookie: "It is Door B." gives away "Door B"',
      '[mission] s3_test s3_ep02 s3_ep01_m1: named as a mission of s3_ep01',
      '[mission] s3_test s3_ep02 s3_ep01_m1: mission id used twice in the season',
      's3_ep02 s3_ep01_m1: an option id used twice',
      's3_ep02 s3_ep01_m1: 1 options: a guess, not a choice',
      's3_ep02 s3_ep02_m2: its tiles (TIMS) do not spell TIME',
      's3_ep02 s3_ep02_final: a wrong-answer line for "c", which is right',
    ]) {
      expect(found, anyElement(contains(want)), reason: want);
    }
  });

  test("places: one not registered, another season's, a malformed id", () {
    final found = issues(season(episodes: {
      's3_ep01': testCase('s3_ep01', 1, edits: {
        1: (m) => m['sceneKey'] = 's3_test.gate',
        2: (m) => m['sceneKey'] = 's2_paris.station',
      }),
      's3_ep02': testCase('s3_ep02', 2),
    }, places: {'s3_test.station': station, 'S3.Bad': station}));
    for (final want in [
      '[place] s3_test: s3_test s3_ep01_m1: s3_test.gate is not registered',
      '[place] s3_test: s3_test s3_ep01_m2: s2_paris.station is not a place of s3_test',
      '[place] s3_test: s3_test place S3.Bad: not a place id of s3_test',
    ]) {
      expect(found, anyElement(contains(want)), reason: want);
    }
  });

  test('levels: a patch that would be dropped, a level marked written that falls back', () {
    final found = issues(season(
      casePatches: {
        Difficulty.junior: {
          's3_ep01': {
            'missions': {
              's3_ep01_m1': {
                'hints': ['One.', 'Two.'],
                'answer': 'c',
              },
              's3_ep01_m7': {'story': ['x']},
            },
          },
        },
      },
      writtenLevels: {'s3_ep02': {Difficulty.master}},
    ));
    for (final want in [
      '[difficulty] s3_test: s3_test junior s3_ep01/s3_ep01_m1.hints: 2 hints for the base\'s 1',
      's3_ep01/s3_ep01_m1.answer: may not change with the level',
      's3_ep01/s3_ep01_m7: no such mission',
      '[difficulty] s3_test s3_ep02: master: marked written, falls back for s3_ep02.intro',
    ]) {
      expect(found, anyElement(contains(want)), reason: want);
    }
  });

  test('a case that does not parse is reported, and the rest is still checked', () {
    final found = issues(season(episodes: {
      's3_ep01': {...testCase('s3_ep01', 1)}..remove('finalMission'),
      's3_ep02': testCase('s3_ep02', 2, edits: {1: (m) => m['answer'] = 'z'}),
    }));
    expect(found, anyElement(contains('[case] s3_test s3_ep01: does not parse')));
    expect(found, anyElement(contains('s3_ep02 s3_ep02_m1: answer z is not an option')));
    expect(found, isNot(anyElement(contains('is case 1 of the season'))), reason: 'counted as registered');
  });
}
