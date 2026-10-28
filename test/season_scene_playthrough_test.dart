import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/data/models/scene_explore.dart' show ScenePixels;
import 'package:world_mystery/data/models/scene_place.dart';
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/mission_map/map_world.dart';
import 'package:world_mystery/features/result/case_solved_screen.dart';
import 'package:world_mystery/features/season/widgets/investigation_board.dart';
import 'package:world_mystery/features/season/widgets/season_props.dart';
import 'package:world_mystery/widgets/place_scenery.dart';
import 'package:world_mystery/widgets/scene_backdrop.dart';

import 'full_playthrough_test.dart' show tapText, wait;
import 'helpers.dart';
import 'multi_season_test.dart' show assetOf;

/// A case of a test season (never in the game: its season, case and places
/// are given to the app by provider overrides and `SeasonCatalog.testPlaces`)
/// whose missions name season places (`sceneKey`), played through the real
/// app and router: map → mission → answer → story scene → final → Case
/// Solved → board. Each place's registered picture shows on every page.
void main() {
  const seasonId = 's9_test';
  const station = 's9_test.station';
  const office = 's9_test.office';
  const stationPlace = ScenePlace(file: 'assets/seasons/season_02_paris/cover/season2_gare_du_nord.png', pixels: ScenePixels(941, 1671));
  const officePlace = ScenePlace(file: 'assets/seasons/season_02_paris/cases/case_04/keeper_hut.png', pixels: ScenePixels(1536, 1024));

  const season = {
    'id': seasonId,
    'number': 3,
    'title': 'Test City Nights',
    'tagline': 'ONE TEST',
    'city': 'Test City',
    'cases': 1,
    'outro': ['The test is over.'],
    'figures': <Object>[],
  };

  const caseJson = <String, dynamic>{
    'id': 's9_test_ep01',
    'seasonId': seasonId,
    'number': 1,
    'title': 'The Test Station',
    'place': 'TEST CITY',
    'synopsis': ['A clock stopped at the test station.'],
    'objectives': ['Find the right platform.'],
    'intro': ['The station is quiet.'],
    'caseSummary': 'A platform and a code closed the case.',
    'missions': [
      {
        'id': 's9_test_ep01_m1',
        'number': 1,
        'title': 'The Platform',
        'location': 'THE TEST STATION',
        'sceneKey': station,
        'story': ['A board lists three platforms.'],
        'letterIntro': 'Your notebook says:',
        'letter': 'The night train leaves from Platform 2.',
        'type': 'multipleChoice',
        'question': 'Which platform?',
        'options': [
          {'id': 'a', 'label': 'Platform 1'},
          {'id': 'b', 'label': 'Platform 2'},
          {'id': 'c', 'label': 'Platform 3'},
        ],
        'answer': 'b',
        'hints': ['Read the letter again.'],
        'clue': {'id': 's9_test_ep01_c1', 'title': 'The Platform', 'value': 'PLATFORM 2', 'note': 'The night train left from Platform 2.'},
        'evidence': {'id': 's9_test_ep01_e1', 'name': 'The Board', 'icon': 'map', 'description': 'The board at the test station.'},
        'successMessage': 'You found the platform!',
        'transition': ['A small office stands at the end of Platform 2.'],
        'nextMissionId': 's9_test_ep01_final',
        'skills': ['reading'],
        'mapX': 0.4,
        'mapY': 0.4,
      },
    ],
    'finalMission': {
      'id': 's9_test_ep01_final',
      'number': 2,
      'title': 'The Office',
      'location': 'THE STATION OFFICE',
      'sceneKey': office,
      'story': ['The office door has a lock with two numbers.'],
      'letterIntro': 'Your clue says:',
      'letter': 'PLATFORM 2. Then 2 again.',
      'type': 'finalCode',
      'question': 'What is the code?',
      'answer': '22',
      'codeLength': 2,
      'hints': ['Your clue has the number.'],
      'evidence': {'id': 's9_test_ep01_e2', 'name': 'The Office Key', 'icon': 'key', 'description': 'It opens the test office.'},
      'successMessage': 'The office is open!',
      'transition': ['The test case is closed.'],
      'skills': ['problemSolving'],
      'mapX': 0.6,
      'mapY': 0.6,
    },
  };

  final testCase = Episode.fromJson(caseJson);

  setUp(() => SeasonCatalog.testPlaces.addAll({station: stationPlace, office: officePlace}));
  tearDown(SeasonCatalog.testPlaces.clear);

  bool showsFile(String file) =>
      find.byWidgetPredicate((w) => w is Image && assetOf(w.image) == file, skipOffstage: false).evaluate().isNotEmpty;
  /// Whether [file] fills the screen behind the page, as [PlaceScenery] lays it.
  bool sceneryOf(String file) => find
      .descendant(
        of: find.byType(PlaceScenery),
        matching: find.byWidgetPredicate((w) => w is SceneBackdrop && w.file == file, skipOffstage: false),
        skipOffstage: false,
      )
      .evaluate()
      .isNotEmpty;

  /// Whether [file] shows inside a widget of [type].
  bool inside(Type type, String file) => find
      .descendant(
        of: find.byType(type),
        matching: find.byWidgetPredicate((w) => w is Image && assetOf(w.image) == file, skipOffstage: false),
        skipOffstage: false,
      )
      .evaluate()
      .isNotEmpty;

  /// Every text on screen (for a failing step's reason).
  String texts() => [
    for (final e in find.byType(Text).evaluate()) (e.widget as Text).data ?? (e.widget as Text).textSpan?.toPlainText() ?? '',
  ].where((s) => s.trim().isNotEmpty).join(' | ');

  testWidgets('a season place case, played through the real app: every page shows its places', (t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer(
      overrides: [
        ...await testOverridesFor(await SharedPreferences.getInstance()),
        seasonsProvider.overrideWithValue([for (final s in SeasonCatalog.all) s.season, Season.fromJson(season)]),
        allEpisodesProvider.overrideWithValue([...MockEpisodeRepository.bundled(), testCase]),
        seasonMapsProvider.overrideWithValue({...SeasonMap.bySeason, seasonId: SeasonMap.paris}),
        seasonReleasedProvider.overrideWithValue((_) => true),
        operatorToolsAvailableProvider.overrideWithValue(true),
      ],
    );
    addTearDown(c.dispose);
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.createDetective('Kim', DetectiveAvatar.boy);
    c.read(seasonPreviewSwitchProvider.notifier).set(true); // the test season opens, unsealed
    expect(ctrl.openSeason(seasonId), isTrue);
    expect(ctrl.openEpisode('s9_test_ep01'), isTrue);
    ctrl.startInvestigation();

    await t.pumpWidget(UncontrolledProviderScope(container: c, child: const WorldMysteryApp()));
    await wait(t);
    c.read(routerProvider).go(Routes.map);
    await wait(t, const Duration(milliseconds: 2000));
    expect(find.text('The Test Station'), findsWidgets, reason: 'the map shows the test case');

    // ── Mission 1, at the station: GO TO → the place → the letter → the puzzle.
    await t.tap(find.bySemanticsLabel('GO TO THE TEST STATION'));
    await wait(t, const Duration(milliseconds: 2800));
    expect(find.text('INVESTIGATE'), findsOneWidget, reason: texts());
    expect(showsFile(stationPlace.file), isTrue, reason: 'the mission page shows the station');
    await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 700));
    await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
    await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
    expect(find.text('Which platform?'), findsOneWidget, reason: texts());
    await tapText(t, 'Platform 2', after: const Duration(milliseconds: 400));
    await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 1200));
    expect(find.text('You Made It!'), findsOneWidget, reason: texts());
    expect(sceneryOf(stationPlace.file), isTrue, reason: 'the answer feedback lies over the station');

    // ── The story scene after it: the office ahead, behind the story and on the unlocked card.
    await wait(t, const Duration(milliseconds: 2800));
    await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 900));
    expect(find.text('MISSION 01 COMPLETE'), findsOneWidget, reason: texts());
    expect(sceneryOf(officePlace.file), isTrue, reason: 'the story scene lies over the office ahead');
    expect(sceneryOf(stationPlace.file), isFalse);
    await t.tapAt(const Offset(200, 400)); // skip typing
    await wait(t, const Duration(milliseconds: 900));
    expect(find.text('FINAL CASE UNLOCKED'), findsOneWidget, reason: texts());
    expect(showsFile(officePlace.file), isTrue, reason: 'the unlocked card shows the office');

    // ── The final, at the office.
    await tapText(t, 'TO THE MAP', after: const Duration(milliseconds: 1200));
    await wait(t, const Duration(milliseconds: 3200)); // LOCKED → UNLOCKED ceremony
    expect(find.text('NEXT LEAD · FINAL CASE'), findsOneWidget, reason: texts());
    await tapText(t, 'OPEN THE FINAL CASE', after: Duration.zero);
    await wait(t, const Duration(milliseconds: 2800));
    expect(find.text('What is the code?'), findsOneWidget, reason: texts());
    expect(showsFile(officePlace.file), isTrue, reason: 'the final page shows the office');
    expect(find.text('OPEN THE BOX'), findsNothing, reason: "never the Royal Box's lock");
    for (final (i, digit) in [2, 2].indexed) {
      final up = find.byTooltip('Lock ${i + 1} up');
      for (var n = 0; n < digit; n++) {
        await t.tap(up);
        await t.pump(const Duration(milliseconds: 20));
      }
    }
    await wait(t, const Duration(milliseconds: 300));
    await tapText(t, 'UNLOCK', after: const Duration(milliseconds: 3500));
    expect(find.text('CASE SOLVED'), findsOneWidget, reason: texts());
    expect(showsFile(officePlace.file), isTrue, reason: 'the solved final still shows the office');

    // ── The post-case scene, then the Case Solved report: its photo is the office.
    await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 1000));
    expect(find.text('CASE 01 COMPLETE'), findsOneWidget, reason: texts());
    expect(sceneryOf(officePlace.file), isTrue, reason: 'the post-case scene lies over the office');
    await t.tapAt(t.getCenter(find.byType(Scaffold).last));
    await wait(t, const Duration(milliseconds: 1200));
    await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 3200));
    expect(find.byType(CaseSolvedScreen), findsOneWidget);
    expect(find.text('CASE CLOSED'), findsOneWidget, reason: texts());
    expect(inside(CaseSolvedScreen, officePlace.file), isTrue, reason: "the report's case photo is the office");

    // ── On to the investigation board: the solved case's print is the office.
    await tapText(t, 'INVESTIGATION BOARD', after: const Duration(milliseconds: 1500));
    expect(find.byType(InvestigationBoard), findsOneWidget, reason: texts());
    expect(find.text('1 / 1'), findsOneWidget, reason: 'the case is solved');
    expect(inside(InvestigationBoard, officePlace.file), isTrue, reason: "the board's print of the solved case is the office");
    final prints = t.widgetList<PhotoPrint>(find.descendant(of: find.byType(InvestigationBoard), matching: find.byType(PhotoPrint)));
    expect([for (final p in prints) p.scene], [const SeasonScene(office)], reason: "the solved case's print names its own place");
  });
}
