import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/content/puzzle_engine_collisions.dart';
import 'package:world_mystery/data/content/puzzle_palette.dart';
import 'package:world_mystery/data/content/season_content_validator.dart';
import 'package:world_mystery/data/mock/season2/season2_case04_scenes.dart';
import 'package:world_mystery/data/mock/season2/season2_case09_scenes.dart';
import 'package:world_mystery/data/mock/season2/season2_case11_scenes.dart';
import 'package:world_mystery/data/mock/season2/season2_scenes.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/scene_explore.dart' show ScenePixels;
import 'package:world_mystery/data/models/scene_place.dart';
import 'package:world_mystery/widgets/art_assets.dart';

/// The puzzle engines registered for each mission and final
/// (`PuzzleEngineCollisionCheck`): the pages' order of choice held against
/// their code, London and Paris as they are, and test seasons (never in the
/// catalog) with each kind of mistake.
void main() {
  group('the pages, as their code chooses', () {
    final missionPage = File('lib/features/mission/mission_screen.dart')
        .readAsStringSync();
    final finalPage = File('lib/features/mission/final_mission_screen.dart')
        .readAsStringSync();
    final accessors = _accessorTables();

    test("the mission page's steps are its switch's, in its order", () {
      final vars = {
        for (final m in RegExp(
          r'final (\w+) = SeasonCatalog\.(\w+)\(m\);',
        ).allMatches(missionPage))
          m[1]!: accessors[m[2]!]!,
        'caseTalk': 'talks', // caseTalkOfProvider: SeasonCatalog.caseTalk
      };
      final order = [
        for (final m in RegExp(
          r'MissionStage\.puzzle when (\w+)',
        ).allMatches(missionPage))
          m[1] == 'talkBefore' ? '<talkBefore>' : vars[m[1]!]!,
      ];
      expect(
        missionPage,
        contains(
          'child: clock == null ? _questionFor(m) : _clockFor(m, clock)',
        ),
      );
      expect(vars['clock'], 'clocks');
      expect(
        [
          for (final s in PuzzleEngineDispatch.mission)
            s.kind == EngineStepKind.talkBefore ? '<talkBefore>' : s.table,
        ],
        [...order, 'clocks'],
      );
    });

    test('the story goes straight to the puzzle for the same tables', () {
      final start = missionPage.indexOf('onInvestigate: () => _goTo(');
      final listed = missionPage.substring(
        start,
        missionPage.indexOf('? MissionStage.puzzle', start),
      );
      final vars = {
        for (final m in RegExp(
          r'final (\w+) = SeasonCatalog\.(\w+)\(m\);',
        ).allMatches(missionPage))
          m[1]!: accessors[m[2]!]!,
      };
      final tables = {
        for (final m in RegExp(r'(\w+) != null').allMatches(listed))
          m[1] == 'caseTalk' ? 'talks' : vars[m[1]!]!,
      };
      expect(listed, contains('talkBefore'));
      expect(tables, PuzzleEngineDispatch.skipsLetter);
    });

    test("the final page's steps are its own, in its order", () {
      final getters = {
        for (final m in RegExp(
          r'get _(\w+) => SeasonCatalog\.(\w+)\(_mission\);',
        ).allMatches(finalPage))
          m[1]!: accessors[m[2]!]!,
      };
      final page = [
        for (final m in RegExp(
          r'if \(!solved && (\w+) != null\) return',
        ).allMatches(finalPage))
          m[1],
      ];
      expect(page, ['talkFinal', 'easy']);
      expect(finalPage, contains('final easy = SeasonCatalog.easySteps(m);'));
      expect(
        finalPage,
        contains('final talkFinal = ref.watch(caseTalkOfProvider)(m);'),
      );
      final start = finalPage.indexOf('List<Widget> _puzzle(');
      final body = finalPage.substring(
        start,
        finalPage.indexOf('Widget _solvedActions()', start),
      );
      final puzzle = [
        for (final m in RegExp(
          r'(?:if|else if) \((?:m\.type == MissionType\.(\w+)\)|_(\w+) case final|_box != null && m\.type == MissionType\.letterLock\))',
        ).allMatches(body))
          m[1] != null
              ? '<type:${m[1]}>'
              : m[2] != null
              ? getters[m[2]!]!
              : '<lockBox>',
      ];
      expect(puzzle.last, '<lockBox>');
      expect(
        [
          for (final s in PuzzleEngineDispatch.finalMission)
            s.kind == EngineStepKind.type ? '<type:${s.type!.name}>' : s.table,
        ],
        ['talks', 'easySteps', ...puzzle.take(puzzle.length - 1)],
      );
      expect(getters['box'], 'lockBoxes');
      expect(
        finalPage,
        contains('final ending = SeasonCatalog.caseEnding(m);'),
      );
    });

    test('every table a page reads is one it is said to read, and every table is placed', () {
      final missionReads = {
        for (final m in RegExp(
          r'final \w+ = SeasonCatalog\.(\w+)\(m\);',
        ).allMatches(missionPage))
          accessors[m[1]!]!,
        'talks',
        'talkMissions',
      };
      expect(missionReads, PuzzleEngineDispatch.readOn(PuzzleSurface.mission));
      final finalReads = {
        for (final m in RegExp(
          r'get _\w+ => SeasonCatalog\.(\w+)\(_mission\);',
        ).allMatches(finalPage))
          accessors[m[1]!]!,
        'talks',
        'easySteps',
        'endings',
      };
      expect(
        finalReads,
        PuzzleEngineDispatch.readOn(PuzzleSurface.finalMission),
      );
      final placed = {
        ...PuzzleEngineDispatch.readOn(PuzzleSurface.mission),
        ...PuzzleEngineDispatch.readOn(PuzzleSurface.finalMission),
        ...PuzzleEngineDispatch.notEngines,
      };
      expect(season1Content.missionTables.keys.toSet(), placed);
    });

    test('every engine is a widget of the game', () {
      final code = [
        for (final f in Directory(
          'lib/features/mission',
        ).listSync(recursive: true).whereType<File>())
          if (f.path.endsWith('.dart')) f.readAsStringSync(),
      ].join('\n');
      for (final s in [
        ...PuzzleEngineDispatch.mission,
        ...PuzzleEngineDispatch.finalMission,
      ]) {
        if (s.kind == EngineStepKind.talkBefore) continue;
        expect(
          code,
          matches(
            RegExp('^class ${RegExp.escape(s.engine)} ', multiLine: true),
          ),
          reason: s.engine,
        );
      }
    });

    test("the palette's engines are where the pages play them", () {
      for (final p in PuzzlePalette.all) {
        for (final e in p.engines) {
          final table = e.table;
          if (table == null) continue;
          for (final s in PuzzleSurface.values) {
            final reason = '${p.id} $table $s';
            if (e.role == PuzzleBindingRole.optional) {
              expect(
                PuzzleEngineDispatch.companionsOn(s).contains(table),
                e.surfaces.contains(s),
                reason: reason,
              );
            } else {
              expect(
                PuzzleEngineDispatch.enginesOn(s).contains(table),
                e.surfaces.contains(s),
                reason: reason,
              );
            }
          }
        }
      }
    });
  });

  group('London and Paris', () {
    final london = PuzzleEngineCollisionCheck.slotsOf(season1Content);
    final paris = PuzzleEngineCollisionCheck.slotsOf(season2Content);
    final all = [...london, ...paris];

    test('98 slots, each played on one engine', () {
      expect(london, hasLength(50));
      expect(paris, hasLength(48));
      expect(all.where((s) => s.active == null), isEmpty);
      expect(
        all.where((s) => s.unread.isNotEmpty || s.hiddenCompanions.isNotEmpty),
        isEmpty,
      );
      expect(all.where((s) => s.shadowed.isEmpty), hasLength(95));
    });

    test('London: nothing to report', () {
      expect(PuzzleEngineCollisionCheck.findingsOf(season1Content), isEmpty);
    });

    test(
      "Paris: three finals' first engines kept under their steps, retired",
      () {
        final found = PuzzleEngineCollisionCheck.findingsOf(season2Content);
        expect(
          [for (final f in found) '$f'],
          [
            '[primary_collision, accepted] s2_paris s2_ep04 s2_ep04_final: EasyStepsPuzzle (easySteps) is played; StreetBookPuzzle (streetBooks) never (easySteps is looked at first); retired by the season',
            '[primary_collision, accepted] s2_paris s2_ep05 s2_ep05_final: EasyStepsPuzzle (easySteps) is played; PostTrailPuzzle (postTrails) never (easySteps is looked at first); retired by the season',
            '[primary_collision, accepted] s2_paris s2_ep07 s2_ep07_final: EasyStepsPuzzle (easySteps) is played; ChangedRecordPuzzle (lightTables) never (easySteps is looked at first); retired by the season',
          ],
        );
        expect(PuzzleEngineCollisionCheck.problemsOf(season2Content), isEmpty);
      },
    );

    test('companions: talks around steps, an exhibit with its letter, a box on its lock, an ending', () {
      String companions(String id) =>
          all.firstWhere((s) => s.mission.id == id).companions.join(',');
      for (final id in [
        's2_ep11_m1',
        's2_ep11_m2',
        's2_ep12_m1',
        's2_ep12_m2',
        's2_ep12_m3',
      ]) {
        expect(companions(id), 'talkMissions', reason: id);
      }
      expect(companions('s2_ep01_m2'), 'exhibits');
      expect(companions('s2_ep01_final'), 'lockBoxes');
      expect(companions('s2_ep12_final'), 'endings');
      expect(all.where((s) => s.companions.isNotEmpty), hasLength(8));
    });

    test('engines outside the palette: the custom ones, played; the retired ones, under the steps', () {
      final outside = {
        for (final s in all)
          if (s.paletteId == null) s.active!.engine,
      };
      expect(outside, {
        'LiftRoute',
        'KeeperHut',
        'LabelAssembly',
        'ClockWall',
        'PlanRoutePuzzle',
        'ArchivePuzzle',
        'FlyRailPuzzle',
        'MorningSketchesPuzzle',
        'TornSlipPuzzle',
        'PaperOnDrawing',
        'GearBoardPuzzle',
        'TowerTestPuzzle',
        'DrumTapePuzzle',
        'CityClocksPuzzle',
        'ShadowCheckPuzzle',
        'HourRecordPuzzle',
      });
      final hidden = {for (final s in all) ...s.shadowed.map((u) => u.table)};
      expect(hidden, {'streetBooks', 'postTrails', 'lightTables'});
      for (final t in ['blotters', 'showStrips', 'lightBoards']) {
        expect(
          season2Content.missionTables[t],
          isEmpty,
          reason: '$t: not registered (its scenes are kept in code only)',
        );
      }
    });
  });

  group('new content', () {
    test('one engine, a talk around steps, a box on its letter lock, an exhibit with its letter, a type alone: nothing to report', () {
      final s = _season(
        cases: {
          's3_ep01': _case(
            's3_ep01',
            1,
            types: {1: 'spotDifferences', 2: 'examine', 3: 'letterLock'},
          ),
          's3_ep02': _case(
            's3_ep02',
            2,
            types: {1: 'sequence', 2: 'wordInput', 3: 'finalCode'},
          ),
        },
        compares: {'s3_ep01_m1': _compare},
        easySteps: {'s3_ep01_m2': _steps},
        talkMissions: {'s3_ep01_m2': _talk},
        lockBoxes: {'s3_ep01_final': _box},
        exhibits: {'s3_ep02_m1': _exhibit},
      );
      expect(PuzzleEngineCollisionCheck.findingsOf(s), isEmpty);
      final slots = {
        for (final x in PuzzleEngineCollisionCheck.slotsOf(s)) x.mission.id: x,
      };
      expect('${slots['s3_ep01_m1']!.active}', 'SpotDifferences (compares)');
      expect(slots['s3_ep01_m1']!.paletteId, 'spot_difference');
      expect(slots['s3_ep01_m2']!.companions, ['talkMissions']);
      expect(slots['s3_ep01_final']!.companions, ['lockBoxes']);
      expect(slots['s3_ep01_final']!.paletteId, 'letter_tile_lock');
      expect(slots['s3_ep02_m1']!.companions, ['exhibits']);
      expect('${slots['s3_ep02_final']!.active}', '_Dial');
      expect(slots['s3_ep02_final']!.paletteId, 'combo_dial_lock');
      expect(_validate(s), isEmpty);
    });

    test(
      'two engines for one mission: the first played, the other reported',
      () {
        final s = _season(
          compares: {'s3_ep01_m1': _compare},
          studios: {'s3_ep01_m1': _studio},
        );
        expect(_found(s), [
          '[primary_collision] s3_test s3_ep01 s3_ep01_m1: SpotDifferences (compares) is played; StudioMatch (studios) never (compares is looked at first)',
        ]);
        final f = PuzzleEngineCollisionCheck.findingsOf(s).single;
        expect((f.slot, '${f.active}'), ('M1', 'SpotDifferences (compares)'));
        expect([for (final u in f.shadowed) u.engine], ['StudioMatch']);
        expect(f.tables, ['compares', 'studios']);
      },
    );

    test('an engine under the steps: a problem, unless the season retires its table', () {
      final hidden = _season(
        easySteps: {'s3_ep01_final': _steps},
        streetBooks: {'s3_ep01_final': _book},
      );
      expect(_found(hidden), [
        '[primary_collision] s3_test s3_ep01 s3_ep01_final: EasyStepsPuzzle (easySteps) is played; StreetBookPuzzle (streetBooks) never (easySteps is looked at first)',
      ]);
      expect(_validate(hidden), [
        '[engine] s3_test s3_ep01 s3_ep01_final: primary_collision: EasyStepsPuzzle (easySteps) is played; StreetBookPuzzle (streetBooks) never (easySteps is looked at first)',
      ]);
      final retired = _season(
        easySteps: {'s3_ep01_final': _steps},
        streetBooks: {'s3_ep01_final': _book},
        retired: {'streetBooks'},
      );
      expect(
        PuzzleEngineCollisionCheck.findingsOf(retired).single.accepted,
        isTrue,
      );
      expect(_validate(retired), isEmpty);
      // Retired, yet played; and a retired name that is no engine.
      final played = _season(
        streetBooks: {'s3_ep01_final': _book},
        retired: {'streetBooks', 'storyScenes'},
      );
      expect(_found(played), [
        '[retired_engine_unknown] s3_test: retired table storyScenes is no engine table',
        '[retired_engine_played] s3_test s3_ep01 s3_ep01_final: streetBooks is retired by the season, yet StreetBookPuzzle (streetBooks) is played',
      ]);
    });

    test("a table on the other page's slot is never read", () {
      final s = _season(
        canvases: {'s3_ep01_m1': _canvas},
        talkMissions: {'s3_ep01_final': _talk},
      );
      expect(_found(s), [
        '[wrong_surface] s3_test s3_ep01 s3_ep01_m1: canvases is never read on a mission page (read on the final page only)',
        '[wrong_surface] s3_test s3_ep01 s3_ep01_final: talkMissions is never read on a final page (read on the mission page only)',
      ]);
    });

    test('an engine outside the palette collides like any other', () {
      final s = _season(
        compares: {'s3_ep01_m1': _compare},
        gearBoards: {'s3_ep01_m1': _gears, 's3_ep01_m2': _gears},
      );
      expect(_found(s), [
        '[primary_collision] s3_test s3_ep01 s3_ep01_m1: SpotDifferences (compares) is played; GearBoardPuzzle (gearBoards) never (compares is looked at first)',
      ]);
      final alone = PuzzleEngineCollisionCheck.slotsOf(s)
          .firstWhere((x) => x.mission.id == 's3_ep01_m2');
      expect(
        ('${alone.active}', alone.paletteId),
        ('GearBoardPuzzle (gearBoards)', null),
      );
    });

    test('registered, never played: a talk before, an exhibit, a box, a type looked at first', () {
      final s = _season(
        cases: {
          's3_ep01': _case(
            's3_ep01',
            1,
            types: {1: 'spotDifferences', 2: 'matchPairs', 3: 'finalCode'},
          ),
        },
        compares: {'s3_ep01_m1': _compare},
        talkMissions: {'s3_ep01_m1': _talk},
        studios: {'s3_ep01_m2': _studio},
        exhibits: {'s3_ep01_m2': _exhibit},
        canvases: {'s3_ep01_final': _canvas},
        lockBoxes: {'s3_ep01_final': _box},
      );
      expect(_found(s), [
        '[companion_hidden] s3_test s3_ep01 s3_ep01_m1: talkMissions never shown: its talk before comes after SpotDifferences (compares)',
        '[companion_hidden] s3_test s3_ep01 s3_ep01_m2: exhibits never shown: the mission goes from its story straight to its puzzle: its letter page is never shown',
        '[type_override] s3_test s3_ep01 s3_ep01_final: CanvasPicker (canvases) never played: a finalCode is played on _Dial, looked at first',
        '[companion_hidden] s3_test s3_ep01 s3_ep01_final: lockBoxes never shown: a finalCode has no letter lock',
      ]);
    });

    test("a scene registered under another case's mission: a collision there, nothing to play here", () {
      final s = _season(
        cases: {
          's3_ep01': _case('s3_ep01', 1, types: {1: 'spotDifferences'}),
          's3_ep02': _case('s3_ep02', 2, types: {1: 'matchPairs'}),
        },
        // The studio meant for Case 02's M1, written under Case 01's; and one
        // under another season's mission.
        compares: {'s3_ep01_m1': _compare, 's2_ep02_m1': _compare},
        studios: {'s3_ep01_m1': _studio},
      );
      expect(_found(s), [
        '[primary_collision] s3_test s3_ep01 s3_ep01_m1: SpotDifferences (compares) is played; StudioMatch (studios) never (compares is looked at first)',
        '[unplayable_type] s3_test s3_ep02 s3_ep02_m1: a matchPairs with no engine for its pictures on the mission page: nothing is shown',
      ]);
      // The entry under another season's mission is the validator's to
      // report, once.
      expect(_validate(s).where((i) => i.contains('s2_ep02_m1')), [
        '[reference] s3_test: compares/s2_ep02_m1: not a mission of the season',
      ]);
    });

    test(
      'every finding is collected, and the policy chooses what is a problem',
      () {
        final s = _season(
          cases: {
            's3_ep01': _case(
              's3_ep01',
              1,
              types: {1: 'spotDifferences', 2: 'revealLayer', 3: 'finalCode'},
            ),
            's3_ep02': _case('s3_ep02', 2),
          },
          compares: {'s3_ep01_m1': _compare, 's3_ep02_final': _compare},
          studios: {'s3_ep01_m1': _studio},
          gearBoards: {'s3_ep01_m1': _gears},
          canvases: {'s3_ep01_final': _canvas, 's3_ep02_m1': _canvas},
          easySteps: {'s3_ep02_final': _steps},
          streetBooks: {'s3_ep02_final': _book},
          exhibits: {'s3_ep02_final': _exhibit},
        );
        final kinds = [
          for (final f in PuzzleEngineCollisionCheck.findingsOf(s)) f.kind,
        ];
        expect(kinds.toSet(), {
          EngineIssueKind.primaryCollision,
          EngineIssueKind.wrongSurface,
          EngineIssueKind.unplayable,
          EngineIssueKind.typeOverride,
        });
        expect(kinds, hasLength(7));
        expect(
          _validate(s).where((i) => i.startsWith('[engine]')),
          hasLength(7),
        );
        expect(
          SeasonContentValidator.validate(
            s,
            engines: EngineCheckPolicy.diagnose,
          ).where((i) => i.rule == 'engine'),
          isEmpty,
        );
        expect(
          PuzzleEngineCollisionCheck.problemsOf(
            s,
            policy: EngineCheckPolicy.diagnose,
          ),
          isEmpty,
        );
      },
    );
  });
}

// ── Test seasons ─────────────────────────────────────────────────────────

const _station = ScenePlace(
  file: ArtAssets.season2GareDuNord,
  pixels: ScenePixels(941, 1671),
);

final _compare = season2Compares['s2_ep02_m1']!;
final _studio = season2Studios['s2_ep02_m2']!;
final _canvas = season2Canvases['s2_ep02_final']!;
final _box = season2LockBoxes['s2_ep01_final']!;
final _exhibit = season2Exhibits['s2_ep01_m2']!;
final _book = season2StreetBooks['s2_ep04_final']!;
final _steps = season2Case04Steps['s2_ep04_final']!;
final _talk = season2Case11TalkMissions['s2_ep11_m1']!;
final _gears = season2GearBoards['s2_ep09_m2']!;

/// Mission [n] of test case [caseId] (the third its final), of [type].
Map<String, dynamic> _mission(String caseId, int n, String type) {
  String id(int k) => k == 3 ? '${caseId}_final' : '${caseId}_m$k';
  final last = n == 3;
  final (options, answer) = switch (type) {
    'letterLock' => (
      [
        for (final l in ['T', 'I', 'M', 'E'])
          {'id': l.toLowerCase(), 'label': l},
      ],
      'TIME',
    ),
    'wordInput' => (const <Map<String, String>>[], 'DOOR'),
    'finalCode' => (const <Map<String, String>>[], '123'),
    'examine' => (const <Map<String, String>>[], 'thing'),
    'sequence' => (
      [
        for (final o in ['a', 'b', 'c']) {'id': o, 'label': 'Step $o'},
      ],
      'a,b,c',
    ),
    'spotDifferences' || 'revealLayer' => (
      [
        for (final o in ['x', 'y']) {'id': o, 'label': 'Mark $o'},
      ],
      'x,y',
    ),
    'matchPairs' => (
      [
        for (final o in ['a', 'b']) {'id': o, 'label': 'Note $o'},
      ],
      'a:p,b:q',
    ),
    _ => (
      [
        for (final o in ['a', 'b', 'c'])
          {'id': o, 'label': 'Door ${o.toUpperCase()}'},
      ],
      'b',
    ),
  };
  return {
    'id': id(n),
    'number': n,
    'title': 'Mission $n',
    'location': 'STATION',
    'story': ['A line.'],
    'sceneKey': 's3_test.station',
    'letterIntro': '',
    'letter': '',
    'type': type,
    'question': 'Which one?',
    'options': options,
    'answer': answer,
    if (type == 'finalCode') 'codeLength': 3,
    'hints': ['Look at the sign.'],
    if (!last)
      'clue': {
        'id': '${id(n)}_c',
        'title': 'Clue',
        'value': '$n',
        'note': 'A note.',
      },
    'evidence': {
      'id': '${id(n)}_e',
      'name': 'Ticket',
      'icon': 'ticket',
      'description': 'A ticket.',
    },
    'successMessage': 'Well done.',
    if (!last) 'transition': ['On we go.'],
    if (!last) 'nextMissionId': id(n + 1),
    'mapX': 0.5,
    'mapY': 0.5,
  };
}

Map<String, dynamic> _case(
  String id,
  int number, {
  Map<int, String> types = const {},
}) => {
  'id': id,
  'seasonId': 's3_test',
  'number': number,
  'title': 'Case $number',
  'synopsis': ['A case.'],
  'objectives': ['Find it.'],
  'intro': ['It begins.'],
  'missions': [
    for (final n in [1, 2]) _mission(id, n, types[n] ?? 'multipleChoice'),
  ],
  'finalMission': _mission(id, 3, types[3] ?? 'multipleChoice'),
};

SeasonContent _season({
  Map<String, Map<String, dynamic>>? cases,
  Map<String, Object> compares = const {},
  Map<String, Object> studios = const {},
  Map<String, Object> canvases = const {},
  Map<String, Object> easySteps = const {},
  Map<String, Object> streetBooks = const {},
  Map<String, Object> talkMissions = const {},
  Map<String, Object> lockBoxes = const {},
  Map<String, Object> exhibits = const {},
  Map<String, Object> gearBoards = const {},
  Set<String> retired = const {},
}) => SeasonContent(
  info: {
    'id': 's3_test',
    'number': 3,
    'title': 'Test',
    'tagline': 'TEST',
    'cases': 2,
  },
  episodes:
      cases ?? {'s3_ep01': _case('s3_ep01', 1), 's3_ep02': _case('s3_ep02', 2)},
  places: const {'s3_test.station': _station},
  compares: compares.cast(),
  studios: studios.cast(),
  canvases: canvases.cast(),
  easySteps: easySteps.cast(),
  streetBooks: streetBooks.cast(),
  talkMissions: talkMissions.cast(),
  lockBoxes: lockBoxes.cast(),
  exhibits: exhibits.cast(),
  gearBoards: gearBoards.cast(),
  retiredEngines: retired,
);

List<String> _found(SeasonContent s) => [
  for (final f in PuzzleEngineCollisionCheck.findingsOf(s)) '$f',
];

List<String> _validate(SeasonContent s) => [
  for (final i in SeasonContentValidator.validateAll([...SeasonCatalog.all, s]))
    if (i.seasonId == 's3_test') '$i',
];

/// Season accessor → the table it reads (`SeasonCatalog`'s own code).
Map<String, String> _accessorTables() {
  final code = File('lib/data/mock/season_catalog.dart').readAsStringSync();
  return {
    for (final m in RegExp(
      r'static [\w<>?]+ (\w+)\(Mission m\)\s*=>\s*_pick\(m, \(s\) => s\.(\w+)\)',
    ).allMatches(code))
      m[1]!: m[2]!,
  };
}
