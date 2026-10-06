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
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/ink_icon.dart';
import 'package:london_mystery/widgets/landmark_art.dart';
import 'package:london_mystery/widgets/place_art.dart';
import 'package:london_mystery/widgets/symbol_icon.dart';

import 'full_playthrough_test.dart' show reveal, wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// The pre-release visual fixes: no lettered stand-ins where a picture is
/// meant (Case 01's place symbols, four badges), and the right picture for
/// Case 04's suitcase, Case 01's Royal Box photo and Case 12's Big Ben.
void main() {
  final catalog = MockEpisodeRepository.bundled();
  Episode byId(String id) => catalog.firstWhere((e) => e.id == id);
  Mission mission(String id) => catalog.expand((e) => e.allMissions).firstWhere((m) => m.id == id);

  /// A lettered stand-in (an [InkMark] with no glyph) anywhere on screen.
  final monogram = find.byWidgetPredicate((w) => w is InkMark && w.glyph == null);

  /// A picture file on screen (decoded at its size: a ResizeImage around it).
  Finder picture(String file) => find.byWidgetPredicate((w) {
        if (w is! Image) return false;
        final image = w.image;
        final source = image is ResizeImage ? image.imageProvider : image;
        return source is AssetImage && source.assetName == file;
      });

  group('mapping', () {
    test('museum, park and crown are drawn glyphs, not letters', () {
      expect(GameSymbol.of('museum').glyph, InkGlyph.museum);
      expect(GameSymbol.of('park').glyph, InkGlyph.park);
      expect(GameSymbol.of('crown').glyph, InkGlyph.crown);
    });

    test('every symbol and icon the episodes use has a glyph', () {
      final keys = <String>{
        for (final e in catalog)
          for (final m in e.allMissions) ...[
            ?m.clue?.symbol,
            ?m.evidence?.icon,
            ...?m.evidence?.symbols,
            ...m.dialSymbols,
          ],
      };
      for (final k in keys) {
        expect(GameSymbol.of(k).glyph, isNotNull, reason: '"$k" would show a letter');
      }
    });

    test('every badge has a glyph (no lettered medal)', () {
      expect(GameBadge.sharpEyes.glyph, InkGlyph.eye);
      expect(GameBadge.quickThinker.glyph, InkGlyph.stopwatch);
      expect(GameBadge.puzzleSolver.glyph, InkGlyph.puzzle);
      expect(GameBadge.masterDetective.glyph, InkGlyph.deerstalker);
      for (final b in GameBadge.values) {
        expect(b.glyph, isNotNull, reason: b.name);
      }
    });

    test("Case 04's suitcase is the old brown one; Case 08's black; Case 11's stays drawn", () {
      expect(PlaceArt.sceneOf(mission('ep04_m3')), Artwork.oldSuitcase);
      expect(PlaceArt.sceneOf(mission('ep04_final')), Artwork.oldSuitcase);
      for (final id in ['ep08_m1', 'ep08_m3']) {
        expect(PlaceArt.sceneOf(mission(id)), Artwork.blackSuitcase, reason: id);
      }
      // Case 11 recalls Case 01's suitcase on Platform 9, not Mrs Robin's.
      expect(PlaceArt.sceneOf(mission('ep11_final')), Artwork.suitcase);
      expect(ArtAssets.scene(Artwork.oldSuitcase), 'assets/art/objects/suitcase.png');
      expect(LandmarkArt.hasPicture(Artwork.suitcase), isFalse);
    });

    test("the Royal Box photo is the open box, never the theatre's royal box", () {
      expect(ArtAssets.scene(Artwork.royalBox), 'assets/art/special/royal_box_open.png');
      expect(ArtAssets.scene(Artwork.royalBox, solved: 1), 'assets/art/special/royal_box_open.png');
      expect(ArtAssets.scenes.values, isNot(contains('assets/art/special/royal_box.png')));
      // The final case still animates its own two pictures.
      expect(ArtAssets.royalBox.closed, 'assets/art/special/royal_box_closed.png');
      expect(ArtAssets.royalBox.open, 'assets/art/special/royal_box_open.png');
      expect(mission('final').scene, Artwork.royalBox);
    });

    test("Case 12's first mission is Big Ben; Case 02's clock is unchanged", () {
      expect(PlaceArt.sceneOf(mission('ep12_m1')), Artwork.bigBen);
      for (final id in ['ep02_m1', 'ep02_m3', 'ep02_final']) {
        expect(PlaceArt.sceneOf(mission(id)), Artwork.clockFace, reason: id);
      }
      expect(ArtAssets.changesWhenSolved, {Artwork.clockFace});
      expect(LandmarkArt.hasPicture(Artwork.clockFace), isFalse, reason: 'the 8:17 → 9:17 clock stays drawn');
    });
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

  /// Case [id] with [done] missions completed (all: solved), the cases
  /// before it solved, and every badge it can give.
  Future<Map<String, Object>> prefsFor(String id, {int? done, bool solved = false, Set<String> solvedCases = const {}}) async {
    final e = byId(id);
    final missions = e.allMissions.take(done ?? e.allMissions.length);
    final before = [for (final c in catalog.takeWhile((c) => c.id != id)) c.id];
    return {
      AppConstants.progressKeyFor(id): jsonEncode(GameProgress(
        detectiveName: 'MINYOUNG',
        introSeen: true,
        completedMissionIds: [for (final m in missions) m.id],
        badgeIds: solved ? [for (final b in GameBadge.forEpisode(e)) b.name] : const [],
        startedAt: DateTime(2026, 9, 29, 10),
        completedAt: solved ? DateTime(2026, 9, 29, 10, 30) : null,
        playMillis: 0,
      ).toJson()),
      if (id != AppConstants.currentEpisodeId)
        AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINYOUNG').toJson()),
      AppConstants.seasonStorageKey: jsonEncode(
        SeasonProgress(activeEpisodeId: id, solvedEpisodeIds: {...before, if (solved) id, ...solvedCases}.toList()).toJson(),
      ),
    };
  }

  Future<GoRouter> start(WidgetTester t, Size size, Map<String, Object> prefs) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    // A fresh app (a second start in one test must not reuse the old scope).
    await t.pumpWidget(const SizedBox());
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

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('Case 01 $tag: the Royal Box locks show a museum, a park, a clock and a train', (t) async {
      final router = await start(t, size, await prefsFor('ep01', done: 5));
      router.go(Routes.finalMission);
      await settle(t);
      await reveal(t, find.text('OPEN THE BOX'));
      expect(monogram, findsNothing, reason: 'no M / P on the locks');
      for (final g in [InkGlyph.clock, InkGlyph.train, InkGlyph.park, InkGlyph.museum]) {
        expect(find.byWidgetPredicate((w) => w is InkIcon && w.glyph == g), findsWidgets, reason: '$g');
      }
      await capture(t, 'fix_case01_locks_$tag');
    });

    testWidgets('Case 01 $tag: notebook clues, evidence, Crown Symbol and badges have no letters', (t) async {
      final router = await start(t, size, await prefsFor('ep01', solved: true));
      router.go(Routes.notebook);
      await settle(t, const Duration(milliseconds: 900));
      expect(monogram, findsNothing, reason: 'clues');
      await capture(t, 'fix_case01_clues_$tag');

      await t.tap(find.text('EVIDENCE'));
      await settle(t, const Duration(milliseconds: 600));
      expect(monogram, findsNothing, reason: 'evidence');
      await reveal(t, find.text('Crown Symbol'));
      await t.tap(find.text('Crown Symbol'));
      await settle(t, const Duration(milliseconds: 600));
      expect(monogram, findsNothing, reason: 'the Crown Symbol, close up');
      expect(find.byWidgetPredicate((w) => w is InkIcon && w.glyph == InkGlyph.crown), findsOneWidget);
      await capture(t, 'fix_case01_crown_zoom_$tag');
      await t.binding.handlePopRoute(); // close the zoom
      await settle(t, const Duration(milliseconds: 600));

      await t.tap(find.text('BADGES'));
      await settle(t, const Duration(milliseconds: 600));
      for (final b in [GameBadge.sharpEyes, GameBadge.quickThinker, GameBadge.puzzleSolver, GameBadge.masterDetective]) {
        await reveal(t, find.text(b.title));
        expect(find.byWidgetPredicate((w) => w is InkIcon && w.glyph == b.glyph), findsOneWidget, reason: b.name);
        expect(monogram, findsNothing, reason: 'badges');
      }
      await capture(t, 'fix_badges_notebook_$tag');
    });

    testWidgets('Case 01 $tag: the report headlines a deerstalker and shows the open Royal Box', (t) async {
      final router = await start(t, size, await prefsFor('ep01', solved: true));
      router.go(Routes.solved);
      await settle(t, const Duration(milliseconds: 3200));
      expect(picture('assets/art/special/royal_box_open.png'), findsOneWidget);
      expect(picture('assets/art/special/royal_box.png'), findsNothing);
      await reveal(t, find.text('MASTER DETECTIVE'));
      expect(monogram, findsNothing, reason: 'headline medal and the badge row');
      expect(find.byWidgetPredicate((w) => w is InkIcon && w.glyph == InkGlyph.deerstalker), findsOneWidget);
      await capture(t, 'fix_case01_report_$tag');
    });

    testWidgets("Case 04 $tag: Platform 4 and the last train show the brown suitcase", (t) async {
      const suitcase = 'assets/art/objects/suitcase.png';
      Finder drawnSuitcase() => find.byWidgetPredicate((w) => w is LandmarkArt && w.artwork == Artwork.suitcase);
      final router = await start(t, size, await prefsFor('ep04', done: 2));
      router.go(Routes.mission('ep04_m3'));
      await settle(t);
      expect(picture(suitcase), findsOneWidget, reason: 'm3');
      expect(drawnSuitcase(), findsNothing);
      await capture(t, 'fix_case04_m3_$tag');

      final r2 = await start(t, size, await prefsFor('ep04', done: 3));
      r2.go(Routes.finalMission);
      await settle(t);
      expect(picture(suitcase), findsOneWidget, reason: 'final');
      expect(drawnSuitcase(), findsNothing);
      await capture(t, 'fix_case04_final_$tag');

      final r3 = await start(t, size, await prefsFor('ep04', solved: true));
      r3.go(Routes.solved);
      await settle(t, const Duration(milliseconds: 3200));
      expect(picture(suitcase), findsOneWidget, reason: 'report');
      expect(drawnSuitcase(), findsNothing);
      await capture(t, 'fix_case04_report_$tag');
    });

    testWidgets('board $tag: Case 01 is the open Royal Box, Case 04 the brown suitcase', (t) async {
      final router = await start(t, size, await prefsFor('ep12', solved: true));
      router.go(Routes.season);
      await settle(t, const Duration(milliseconds: 2500));
      expect(picture('assets/art/special/royal_box_open.png'), findsOneWidget, reason: 'Case 01');
      expect(picture('assets/art/objects/suitcase.png'), findsOneWidget, reason: 'Case 04');
      // Case 11's black suitcase (Platform 9) stays drawn.
      expect(find.byWidgetPredicate((w) => w is LandmarkArt && w.artwork == Artwork.suitcase), findsOneWidget);
      await capture(t, 'fix_board_$tag');
    });

    testWidgets("Case 12 $tag: the first mission shows Big Ben; Case 02's clock is still drawn", (t) async {
      final router = await start(t, size, await prefsFor('ep12', done: 0));
      router.go(Routes.mission('ep12_m1'));
      await settle(t);
      expect(picture('assets/art/scenes/landmarks/big_ben.png'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is LandmarkArt && w.artwork == Artwork.clockFace), findsNothing);
      await capture(t, 'fix_case12_m1_$tag');

      final r2 = await start(t, size, await prefsFor('ep02', done: 0));
      r2.go(Routes.mission('ep02_m1'));
      await settle(t);
      expect(find.byWidgetPredicate((w) => w is LandmarkArt && w.artwork == Artwork.clockFace), findsOneWidget);
    });
  }
}
