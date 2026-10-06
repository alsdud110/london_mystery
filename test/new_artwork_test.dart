import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/landmark_art.dart';
import 'package:london_mystery/widgets/place_art.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// The six new pictures, each only where the story matches it:
/// Gallery 8 (Case 03), the theatre auditorium (Case 11), Mrs Robin's
/// black suitcase (Case 08), and the opening's stranger and locked door.
/// The jewel case and the door stay out of the cases they would contradict.
void main() {
  final catalog = MockEpisodeRepository.bundled();
  Episode byId(String id) => catalog.firstWhere((e) => e.id == id);
  Mission mission(String id) => catalog.expand((e) => e.allMissions).firstWhere((m) => m.id == id);
  String? fileOf(String id) => ArtAssets.scene(PlaceArt.sceneOf(mission(id)));

  const gallery = 'assets/art/scenes/british_museum/british_museum_gallery.png';
  const theatre = 'assets/art/scenes/covent_garden/covent_garden_theatre.png';
  const blackSuitcase = 'assets/art/objects/suitcase_black.png';
  const brownSuitcase = 'assets/art/objects/suitcase.png';
  const jewelCase = 'assets/art/objects/jewel_case.png';
  const door = 'assets/art/objects/locked_door.png';
  const stranger = 'assets/art/characters/mysterious_stranger.png';
  const gearDoor = 'assets/art/objects/locked_door_gears.png';
  const ironDoor = 'assets/art/objects/small_iron_door.png';
  const theatreDoor = 'assets/art/scenes/covent_garden/theatre_door_dark.png';
  const emptyCase = 'assets/art/objects/empty_glass_jewel_case.png';
  const ironChest = 'assets/art/objects/iron_chest.png';
  const archive = 'assets/art/scenes/royal_archive/royal_archive.png';
  const royalBoxOpen = 'assets/art/special/royal_box_open.png';

  group('which mission shows which picture', () {
    test('Case 03: Gallery 8 has its picture; the Egypt Room and the Great Court keep theirs', () {
      expect(fileOf('ep03_m1'), gallery);
      expect(fileOf('ep03_m2'), 'assets/art/scenes/british_museum/british_museum_egypt_room.png');
      expect(fileOf('ep03_m3'), 'assets/art/scenes/british_museum/british_museum_great_court.png');
    });

    test("Case 11's theatre is the auditorium; its dressing room keeps its own picture", () {
      expect(fileOf('ep11_m1'), theatre);
      expect(fileOf('ep11_m2'), 'assets/art/scenes/covent_garden/covent_garden_dressing_room.png');
      // Case 06: THE THEATRE DOOR, in the dark — its own picture.
      expect(mission('ep06_m3').story.join(' '), contains('Only the stage light is on.'));
      expect(PlaceArt.sceneOf(mission('ep06_m3')), Artwork.theatreDoor);
      expect(fileOf('ep06_m3'), theatreDoor);
    });

    test("Case 08 is Mrs Robin's black suitcase; Case 04 stays brown; Case 11 stays drawn", () {
      expect(fileOf('ep08_m1'), blackSuitcase);
      expect(fileOf('ep08_m3'), blackSuitcase);
      for (final id in ['m01', 'ep04_m1', 'ep04_m3', 'ep04_final']) {
        expect(fileOf(id), brownSuitcase, reason: id);
      }
      expect(fileOf('ep11_final'), isNull, reason: "Case 01's suitcase on Platform 9, recalled: drawn");
    });

    test('Case 09 finds the glass case empty: its own picture, never the tiara box', () {
      expect(mission('ep09_m1').story.join(' '), contains('The velvet cushion is empty'));
      expect(fileOf('ep09_m1'), emptyCase);
      expect(ArtAssets.scenes.values, isNot(contains(jewelCase)));
    });

    test("Case 05 and 12 each show their own door; the opening's door is the opening's only", () {
      expect(mission('ep05_m2').story.join(' '), contains('Four brass gears'));
      expect(mission('ep05_final').letter, contains('how many gears are on the door?'));
      expect(mission('ep05_final').answer, '745', reason: 'the gear count (4) is unchanged');
      expect(mission('ep12_m3').transition.join(' '), contains('small iron door'));
      for (final id in ['ep05_m2', 'ep05_final', 'ep12_final']) {
        expect(mission(id).scene, Artwork.lockedDoor, reason: '$id: the data is unchanged');
      }
      expect(fileOf('ep05_m2'), gearDoor);
      // Behind the door, the final is the iron chest (its gears are counted at the door, m2).
      expect(mission('ep05_final').story.join(' '), contains('The iron chest is cold and heavy.'));
      expect(fileOf('ep05_final'), ironChest);
      expect(fileOf('ep12_final'), ironDoor);
      expect(ArtAssets.scenes.values, isNot(contains(door)));
      expect(ArtAssets.lockedDoor, door);
      expect(ArtAssets.mysteriousStranger, stranger);
    });

    test('earlier choices hold: Big Ben, the open Royal Box, the clock; no Clockmaker, map or theatre box', () {
      expect(fileOf('ep12_m1'), 'assets/art/scenes/landmarks/big_ben.png');
      expect(ArtAssets.scene(Artwork.royalBox), 'assets/art/special/royal_box_open.png');
      expect(PlaceArt.sceneOf(mission('ep02_m1')), Artwork.bigBen);
      expect(PlaceArt.sceneOf(mission('ep02_m2')), Artwork.clockMechanism);
      expect(PlaceArt.sceneOf(mission('ep02_m3')), Artwork.clockFace);
      expect(PlaceArt.sceneOf(mission('ep02_final')), Artwork.clockFace);
      final used = {...ArtAssets.scenes.values, ArtAssets.mysteriousStranger, ArtAssets.lockedDoor};
      for (final never in [
        'assets/art/characters/clockmaker_master.png',
        'assets/art/objects/map.png',
        'assets/art/special/royal_box.png',
      ]) {
        expect(used, isNot(contains(never)), reason: never);
      }
      expect(byId('ep12').finalMission.scene, Artwork.lockedDoor);
    });
  });

  testWidgets('Case 02 clock: with reduced motion the hour hand is simply at 9:17', (t) async {
    final art = ArtAssets.clockHands[Artwork.clockFace]!;
    Future<ClockHandsPainter> at(double solved, {required bool still}) async {
      await t.pumpWidget(MediaQuery(
        data: MediaQueryData(disableAnimations: still),
        child: SizedBox(width: 200, height: 200, child: ClockHands(art, solved: solved, aspect: 1)),
      ));
      return t.widget<CustomPaint>(find.byType(CustomPaint)).painter! as ClockHandsPainter;
    }

    expect((await at(0.3, still: false)).hourDegrees, inExclusiveRange(248.5, 278.5), reason: 'turning');
    expect((await at(0.3, still: true)).hourDegrees, 278.5, reason: 'no turn: already set');
    expect((await at(0, still: true)).hourDegrees, 248.5);
    expect((await at(0.3, still: true)).minuteDegrees, 102);
  });

  setUpAll(() async {
    for (final (family, files) in [
      ('Nunito', ['Nunito.ttf']),
      ('Cinzel', ['Cinzel.ttf']),
      ('LibreBaskerville', ['LibreBaskerville.ttf', 'LibreBaskerville-Italic.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await loader.load();
    }
  });

  /// A picture file on screen (decoded at its size: a ResizeImage around it).
  Finder picture(String file) => find.byWidgetPredicate((w) {
        if (w is! Image) return false;
        final image = w.image;
        final source = image is ResizeImage ? image.imageProvider : image;
        return source is AssetImage && source.assetName == file;
      });
  Finder drawn(Artwork a) => find.byWidgetPredicate((w) => w is LandmarkArt && w.artwork == a);

  /// Case [id] with [done] missions completed (all, when solved).
  Future<Map<String, Object>> prefsFor(String id, {int? done, bool solved = false}) async {
    final e = byId(id);
    final before = [for (final c in catalog.takeWhile((c) => c.id != id)) c.id];
    return {
      AppConstants.progressKeyFor(id): jsonEncode(GameProgress(
        detectiveName: 'MINYOUNG',
        introSeen: true,
        completedMissionIds: [for (final m in e.allMissions.take(done ?? e.allMissions.length)) m.id],
        startedAt: DateTime(2026, 9, 29, 10),
        completedAt: solved ? DateTime(2026, 9, 29, 10, 30) : null,
        playMillis: 0,
      ).toJson()),
      if (id != AppConstants.currentEpisodeId)
        AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINYOUNG').toJson()),
      AppConstants.seasonStorageKey:
          jsonEncode(SeasonProgress(activeEpisodeId: id, solvedEpisodeIds: [...before, if (solved) id]).toJson()),
    };
  }

  Future<GoRouter> start(WidgetTester t, Size size, Map<String, Object> prefs) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const SizedBox()); // a fresh app each time
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(prefs: prefs),
      child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
    ));
    await wait(t, const Duration(milliseconds: 300));
    return ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first).read(routerProvider);
  }

  Future<void> settle(WidgetTester t, [Duration d = const Duration(milliseconds: 1500)]) async {
    await wait(t, d);
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600))); // decode the pictures
    await wait(t, const Duration(milliseconds: 300));
    expect(t.takeException(), isNull);
  }

  /// The mission page of [id] (its earlier missions done).
  Future<void> openMission(WidgetTester t, Size size, String id) async {
    final e = catalog.firstWhere((e) => e.allMissions.any((m) => m.id == id));
    final at = e.allMissions.indexWhere((m) => m.id == id);
    final router = await start(t, size, await prefsFor(e.id, done: at));
    router.go(mission(id).isFinal ? Routes.finalMission : Routes.mission(id));
    await settle(t);
  }

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('Case 03 $tag: Gallery 8, then the Egypt Room and the Great Court', (t) async {
      await openMission(t, size, 'ep03_m1');
      expect(picture(gallery), findsOneWidget);
      expect(drawn(Artwork.gallery), findsOneWidget, reason: 'its picture, through the same LandmarkArt');
      await capture(t, 'art_case03_gallery_$tag');
      await openMission(t, size, 'ep03_m2');
      expect(picture('assets/art/scenes/british_museum/british_museum_egypt_room.png'), findsOneWidget);
      await openMission(t, size, 'ep03_m3');
      expect(picture('assets/art/scenes/british_museum/british_museum_great_court.png'), findsOneWidget);
    });

    testWidgets("Case 08 $tag: Mrs Robin's black suitcase, never the brown one", (t) async {
      for (final id in ['ep08_m1', 'ep08_m3']) {
        await openMission(t, size, id);
        expect(picture(blackSuitcase), findsOneWidget, reason: id);
        expect(picture(brownSuitcase), findsNothing, reason: id);
        await capture(t, 'art_${id}_$tag');
      }
      // Case 04 is still the brown suitcase.
      await openMission(t, size, 'ep04_m3');
      expect(picture(brownSuitcase), findsOneWidget);
      expect(picture(blackSuitcase), findsNothing);
    });

    testWidgets('Case 11 $tag: the auditorium, the dressing room, and the drawn Platform 9 suitcase', (t) async {
      await openMission(t, size, 'ep11_m1');
      expect(picture(theatre), findsOneWidget);
      await capture(t, 'art_case11_theatre_$tag');
      await openMission(t, size, 'ep11_m2');
      expect(picture('assets/art/scenes/covent_garden/covent_garden_dressing_room.png'), findsOneWidget);
      expect(picture(theatre), findsNothing);
      await openMission(t, size, 'ep11_final');
      expect(drawn(Artwork.suitcase), findsOneWidget);
      expect(picture(blackSuitcase), findsNothing);
    });

    testWidgets('Cases 05, 06, 09, 12 $tag: each scene shows its own picture, never another', (t) async {
      for (final (id, file) in const [
        ('ep05_m2', gearDoor),
        ('ep05_final', ironChest),
        ('ep06_m3', theatreDoor),
        ('ep09_m1', emptyCase),
        ('ep12_final', ironDoor),
      ]) {
        await openMission(t, size, id);
        expect(picture(file), findsOneWidget, reason: id);
        for (final other in [door, jewelCase, theatre, gearDoor, ironDoor, theatreDoor, emptyCase, ironChest]) {
          if (other != file) expect(picture(other), findsNothing, reason: '$id: $other');
        }
        // No scene left as a code drawing (Case 09's `jewelCase` shows its picture now).
        expect(
          find.byWidgetPredicate((w) => w is LandmarkArt && !LandmarkArt.hasPicture(w.artwork)),
          findsNothing,
          reason: '$id: no drawing',
        );
        await capture(t, 'art2_${id}_$tag');
      }
      // Case 12's first mission is still Big Ben.
      await openMission(t, size, 'ep12_m1');
      expect(picture('assets/art/scenes/landmarks/big_ben.png'), findsOneWidget);
    });

    testWidgets('story scenes, reports and the board $tag: the same doors and theatre door', (t) async {
      // The story scene before each door (or the theatre door) opens on it.
      for (final (solvedId, file) in const [('ep05_m1', gearDoor), ('ep05_m3', ironChest), ('ep06_m2', theatreDoor), ('ep12_m3', ironDoor)]) {
        final e = catalog.firstWhere((e) => e.allMissions.any((m) => m.id == solvedId));
        final done = e.allMissions.indexWhere((m) => m.id == solvedId) + 1;
        final router = await start(t, size, await prefsFor(e.id, done: done));
        router.go(Routes.story(solvedId));
        await settle(t, const Duration(milliseconds: 900));
        expect(picture(file), findsWidgets, reason: 'the story after $solvedId');
      }
      // The case reports.
      for (final (id, file) in const [('ep05', ironChest), ('ep12', ironDoor)]) {
        final router = await start(t, size, await prefsFor(id, solved: true));
        router.go(Routes.solved);
        await settle(t, const Duration(milliseconds: 3200));
        expect(picture(file), findsOneWidget, reason: '$id report');
        expect(drawn(Artwork.lockedDoor), findsNothing);
      }
      // The board: Case 05 and Case 12 no longer share one drawn door.
      final router = await start(t, size, await prefsFor('ep12', solved: true));
      router.go(Routes.season);
      await settle(t, const Duration(milliseconds: 2500));
      expect(picture(ironChest), findsOneWidget, reason: 'Case 05');
      expect(picture(ironDoor), findsOneWidget, reason: 'Case 12');
      expect(drawn(Artwork.lockedDoor), findsNothing);
      await capture(t, 'art2_board_$tag');
    });

    testWidgets('Case 01 $tag: the Royal Archive on the way in and after; the Royal Box stays the case photo', (t) async {
      final e = byId('ep01');
      // m05's story scene: the archive behind the words and on the unlocked card.
      var router = await start(t, size, await prefsFor('ep01', done: 5));
      router.go(Routes.story('m05'));
      await settle(t, const Duration(milliseconds: 900));
      await t.tapAt(Offset(size.width / 2, size.height / 2));
      await settle(t, const Duration(milliseconds: 1200));
      expect(find.text('THE ROYAL ARCHIVE'), findsOneWidget);
      expect(picture(archive), findsNWidgets(2), reason: 'the scenery and the unlocked card');
      expect(picture('assets/art/scenes/landmarks/buckingham_palace.png'), findsNothing);
      expect(picture('assets/images/london_mystery.png'), findsNothing, reason: 'no London map fallback');
      await capture(t, 'art3_case01_unlock_$tag');

      // The final case still opens the Royal Box.
      router = await start(t, size, await prefsFor('ep01', done: 5));
      router.go(Routes.finalMission);
      await settle(t);
      expect(picture('assets/art/special/royal_box_closed.png'), findsOneWidget);
      expect(picture(archive), findsNothing);

      // After the case: the archive; then the report keeps the open Royal Box.
      router = await start(t, size, await prefsFor('ep01', solved: true));
      router.go(Routes.story(e.finalMission.id));
      await settle(t, const Duration(milliseconds: 900));
      await t.tapAt(Offset(size.width / 2, size.height / 2));
      await settle(t, const Duration(milliseconds: 1200));
      expect(picture(archive), findsOneWidget);
      expect(picture('assets/images/london_mystery.png'), findsNothing);
      await capture(t, 'art3_case01_postcase_$tag');
      router.go(Routes.solved);
      await settle(t, const Duration(milliseconds: 3200));
      expect(picture(royalBoxOpen), findsOneWidget);
      expect(picture(archive), findsNothing);

      // The board: Case 01 is the open Royal Box.
      router = await start(t, size, await prefsFor('ep12', solved: true));
      router.go(Routes.season);
      await settle(t, const Duration(milliseconds: 2500));
      expect(picture(royalBoxOpen), findsOneWidget);
      expect(picture(archive), findsNothing);
    });

    testWidgets('picture choices $tag: landmarks are named under the picture; park maps are not', (t) async {
      Future<void> toPuzzle(String id) async {
        await openMission(t, size, id);
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 700));
        await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
        await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
        expect(t.takeException(), isNull);
      }

      await toPuzzle('m04');
      final m = mission('m04');
      for (final o in m.options) {
        await reveal(t, find.text(o.label));
        expect(find.text(o.label), findsOneWidget, reason: o.label);
        expect(t.getRect(find.text(o.label)).bottom, lessThan(size.height));
      }
      await reveal(t, find.text('Buckingham Palace'));
      await capture(t, 'choice_case01_m04_$tag');

      await toPuzzle('ep07_m1');
      for (final o in mission('ep07_m1').options) {
        expect(find.text(o.label), findsNothing, reason: '${o.label} would tell the answer');
      }
    });

    testWidgets('Case 02 $tag: Big Ben, the clock room, then 8:17, then 9:17 once the clock is set', (t) async {
      const mechanism = 'assets/art/scenes/big_ben/clock_mechanism.png';
      const face = 'assets/art/scenes/big_ben/clock_face.png';
      // The hands drawn over the face, clockwise from 12.
      Finder hands() => find.byWidgetPredicate((w) => w is CustomPaint && w.painter is ClockHandsPainter);
      ClockHandsPainter painter() => t.widget<CustomPaint>(hands()).painter! as ClockHandsPainter;
      const at817 = 248.5; // the hour hand at 8:17: past VIII, toward IX
      const at917 = 278.5; // at 9:17: past IX, toward X
      // m1: from Westminster Bridge, the tower; the stopped time is its puzzle.
      await openMission(t, size, 'ep02_m1');
      expect(picture('assets/art/scenes/landmarks/big_ben.png'), findsOneWidget);
      expect(picture(mechanism), findsNothing);
      expect(picture(face), findsNothing, reason: 'm1 must not show the answer');
      expect(hands(), findsNothing);
      await capture(t, 'clock_m1_$tag');
      // m2: the clock room, "big wheels and gears".
      await openMission(t, size, 'ep02_m2');
      expect(picture(mechanism), findsOneWidget);
      expect(picture(face), findsNothing);
      expect(hands(), findsNothing);
      await capture(t, 'clock_m2_$tag');
      // m3: 8:17 is known by now (m1's clue).
      await openMission(t, size, 'ep02_m3');
      expect(picture(face), findsOneWidget);
      expect(painter().hourDegrees, at817);
      await capture(t, 'clock_m3_$tag');
      // The final: 8:17 until the clock is set.
      await openMission(t, size, 'ep02_final');
      expect(picture(face), findsOneWidget);
      expect(painter().hourDegrees, at817, reason: 'not 9:17 before the answer');
      expect(painter().hourDegrees, closeTo(248.5, 1e-9));
      expect(painter().minuteDegrees, closeTo(102, 1e-9));
      await capture(t, 'clock_final_unsolved_$tag');
      for (final (i, digit) in [9, 1, 7].indexed) {
        final up = find.byTooltip('Lock ${i + 1} up');
        await reveal(t, up);
        for (var n = 0; n < digit; n++) {
          await t.tap(up);
          await t.pump(const Duration(milliseconds: 20));
        }
      }
      await tapText(t, 'UNLOCK', after: const Duration(milliseconds: 100));
      // The page scrolls up (~0.5 s), then the 2.4 s reveal: the hour hand turns at 15-48 % of it.
      await wait(t, const Duration(milliseconds: 1300)); // mid-turn
      expect(picture(face), findsOneWidget, reason: 'the same face, never another picture');
      expect(painter().hourDegrees, inExclusiveRange(at817, at917), reason: 'the hand is on its way');
      expect(painter().minuteDegrees, 102, reason: 'the minute hand does not move');
      expect(find.text('Big Ben rings again!'), findsNothing, reason: 'the clock turns before the banner');
      await capture(t, 'clock_final_turning_$tag');
      await wait(t, const Duration(milliseconds: 3000));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await wait(t, const Duration(milliseconds: 300));
      expect(t.takeException(), isNull);
      expect(find.text('Big Ben rings again!'), findsOneWidget);
      expect(picture(face), findsOneWidget);
      expect(painter().hourDegrees, at917);
      expect(painter().hourDegrees, closeTo(278.5, 1e-9), reason: 'past IX, not on it');
      expect(painter().minuteDegrees, closeTo(102, 1e-9));
      await Scrollable.ensureVisible(t.element(picture(face)));
      await t.pump();
      await capture(t, 'clock_final_solved_$tag');
    });

    testWidgets('Case 02 $tag: the report and the board show the face at 9:17', (t) async {
      const face = 'assets/art/scenes/big_ben/clock_face.png';
      List<double> times() => [
            for (final w in t.widgetList<CustomPaint>(
              find.byWidgetPredicate((w) => w is CustomPaint && w.painter is ClockHandsPainter),
            ))
              (w.painter! as ClockHandsPainter).hourDegrees,
          ];
      var router = await start(t, size, await prefsFor('ep02', solved: true));
      router.go(Routes.solved);
      await settle(t, const Duration(milliseconds: 3200));
      expect(picture(face), findsOneWidget);
      expect(times(), [278.5]);
      await capture(t, 'clock_report_$tag');
      router = await start(t, size, await prefsFor('ep12', solved: true));
      router.go(Routes.season);
      await settle(t, const Duration(milliseconds: 2500));
      expect(picture(face), findsOneWidget);
      expect(times(), [278.5]);
      await capture(t, 'clock_board_$tag');
    });

    testWidgets('Case 05 $tag: the gear door at m2, the iron chest at the final', (t) async {
      await openMission(t, size, 'ep05_m2');
      expect(picture(gearDoor), findsOneWidget);
      expect(picture(ironChest), findsNothing);
      await capture(t, 'art3_ep05_m2_$tag');
      await openMission(t, size, 'ep05_final');
      expect(picture(ironChest), findsOneWidget);
      expect(picture(gearDoor), findsNothing);
      await capture(t, 'art3_ep05_final_$tag');
    });

    testWidgets('opening $tag: the stranger and the locked door lie with the crown and the letter', (t) async {
      final router = await start(t, size, {
        AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINYOUNG').toJson()),
      });
      router.go(Routes.prologue);
      await wait(t, const Duration(milliseconds: 2800));
      await t.tap(find.text('NEXT ›'));
      await settle(t, const Duration(milliseconds: 2800));
      expect(find.text('And strangers are hiding secrets.'), findsOneWidget);
      for (final file in [stranger, door, 'assets/art/objects/crown.png', 'assets/art/objects/letter.png']) {
        expect(picture(file), findsOneWidget, reason: file);
      }
      expect(picture('assets/art/characters/clockmaker_master.png'), findsNothing);
      expect(drawn(Artwork.lockedDoor), findsNothing, reason: 'the drawn door is only the fallback now');
      await capture(t, 'art_opening_$tag');
    });

    testWidgets('Crown Symbol $tag: CLOSE is on screen and closes the zoom', (t) async {
      final router = await start(t, size, await prefsFor('ep01', solved: true));
      router.go(Routes.notebook);
      await settle(t, const Duration(milliseconds: 900));
      await t.tap(find.text('EVIDENCE'));
      await settle(t, const Duration(milliseconds: 600));
      await reveal(t, find.text('Crown Symbol'));
      await t.tap(find.text('Crown Symbol'));
      await settle(t, const Duration(milliseconds: 600));
      final close = find.text('CLOSE');
      final r = t.getRect(close);
      expect(r.top, greaterThanOrEqualTo(0));
      expect(r.bottom, lessThanOrEqualTo(size.height), reason: 'CLOSE on screen at $tag');
      // The whole card is still there (it scrolls on a small phone).
      expect(find.text('Four pictures for four locks.\nRead them from left to right.'), findsOneWidget);
      await capture(t, 'art_crown_zoom_$tag');
      await t.tap(close);
      await settle(t, const Duration(milliseconds: 600));
      expect(close, findsNothing, reason: 'the zoom closed');
    });
  }
}
