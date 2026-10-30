import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/widgets/art_assets.dart';
import 'package:world_mystery/widgets/clue_card.dart';
import 'package:world_mystery/widgets/evidence_card.dart';
import 'package:world_mystery/widgets/royal_box_picture.dart';
import 'package:world_mystery/widgets/symbol_icon.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// Case 01's Royal Box lock pictures (2026-10-19): four full-colour drawings
/// delivered by the user — a pocket watch, a steam train, a swan, the Rosetta
/// Stone — cut out of the checkered backdrop painted into them, and shown,
/// with the names CLOCK, TRAIN, SWAN, STONE, wherever the lock order is read:
/// the crown card's hidden message (Mission 05, see case01_decode_test), the
/// Crown Symbol evidence, and the locks of the final. One mapping
/// ([RoyalBoxPicture]) feeds all three. The locks' symbol ids, the clues'
/// numbers and the final's answer (7924) stay as they were.
void main() {
  final season = handMadeBundled(); // London and Paris: a season made from its plans has its own (generated_seasons_test.dart)
  final ep01 = season.firstWhere((e) => e.id == 'ep01');
  const order = ['clock', 'train', 'park', 'museum'];
  const names = {'clock': 'CLOCK', 'train': 'TRAIN', 'park': 'SWAN', 'museum': 'STONE'};
  const files = {
    'clock': 'symbol_pocket_watch',
    'train': 'symbol_steam_train',
    'park': 'symbol_swan',
    'museum': 'symbol_rosetta_stone',
  };

  Future<({int width, int height, Uint8List rgba})> decode(String path) async {
    final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
    final image = (await codec.getNextFrame()).image;
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!;
    return (width: image.width, height: image.height, rgba: data.buffer.asUint8List());
  }

  group('the pictures', () {
    test('the four files are in the app, mapped to the locks in order', () {
      expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/images/case01/symbols/'));
      expect(ArtAssets.royalBoxLocks.keys, order);
      for (final s in order) {
        final p = RoyalBoxPicture.of(s)!;
        expect(p.file, 'assets/images/case01/symbols/${files[s]}.png', reason: s);
        expect(File(p.file).existsSync(), isTrue, reason: s);
        expect(p.name.toUpperCase(), names[s]);
      }
    });

    test('the delivered files are kept as delivered, out of the app', () {
      const delivered = {
        'symbol_pocket_watch': 2452366,
        'symbol_steam_train': 2396942,
        'symbol_swan': 2479574,
        'symbol_rosetta_stone': 3029202,
      };
      for (final MapEntry(key: name, value: bytes) in delivered.entries) {
        final f = File('assets/images/case01/symbols/original/$name.png');
        expect(f.existsSync(), isTrue, reason: name);
        expect(f.lengthSync(), bytes, reason: '$name unchanged');
      }
      // Only the folder's own files are bundled, not original/ (no asset
      // line names it; a folder entry does not take its subfolders).
      final assetLines = File('pubspec.yaml').readAsLinesSync().where((l) => l.trim().startsWith('- assets/'));
      expect(assetLines.where((l) => l.contains('original')), isEmpty);
    });

    test('each is cut out: transparent around the drawing, square, the same margin', () async {
      for (final s in order) {
        final img = await decode(RoyalBoxPicture.of(s)!.file);
        expect((img.width, img.height), (512, 512), reason: s);
        int alpha(int x, int y) => img.rgba[(y * img.width + x) * 4 + 3];
        // The corners and edges: the old checker is gone.
        for (final (x, y) in [(0, 0), (511, 0), (0, 511), (511, 511), (256, 2), (2, 256)]) {
          expect(alpha(x, y), 0, reason: '$s at ($x, $y)');
        }
        // Some of it transparent, much of it solid: a cut-out, not a blank.
        var clear = 0, solid = 0;
        for (var i = 3; i < img.rgba.length; i += 4 * 7) {
          if (img.rgba[i] == 0) clear++;
          if (img.rgba[i] == 255) solid++;
        }
        final n = img.rgba.length ~/ (4 * 7);
        expect(clear / n, inInclusiveRange(0.2, 0.75), reason: '$s transparent share');
        expect(solid / n, greaterThan(0.2), reason: '$s solid share');
        // Trimmed and centred: the drawing reaches the 20 px margin on its
        // longer side, on every picture alike.
        var left = 512, right = -1, top = 512, bottom = -1;
        for (var y = 0; y < 512; y++) {
          for (var x = 0; x < 512; x++) {
            if (alpha(x, y) > 8) {
              if (x < left) left = x;
              if (x > right) right = x;
              if (y < top) top = y;
              if (y > bottom) bottom = y;
            }
          }
        }
        final span = (right - left) > (bottom - top) ? right - left : bottom - top;
        expect(span, inInclusiveRange(466, 474), reason: '$s fills the square alike');
      }
    });

    test('no grey left from the checker along the edges', () async {
      for (final s in order) {
        final img = await decode(RoyalBoxPicture.of(s)!.file);
        var fringe = 0, edge = 0;
        for (var y = 1; y < 511; y++) {
          for (var x = 1; x < 511; x++) {
            final i = (y * 512 + x) * 4;
            if (img.rgba[i + 3] == 0) continue;
            // An edge pixel: next to transparency.
            final nearClear = img.rgba[i - 4 + 3] == 0 || img.rgba[i + 4 + 3] == 0 ||
                img.rgba[i - 512 * 4 + 3] == 0 || img.rgba[i + 512 * 4 + 3] == 0;
            if (!nearClear) continue;
            edge++;
            final r = img.rgba[i], g = img.rgba[i + 1], b = img.rgba[i + 2];
            final hi = [r, g, b].reduce((a, c) => a > c ? a : c), lo = [r, g, b].reduce((a, c) => a < c ? a : c);
            if (hi - lo <= 10 && lo >= 215 && img.rgba[i + 3] > 200) fringe++;
          }
        }
        expect(fringe / edge, lessThan(0.03), reason: '$s: light grey checker fringe');
      }
    });
  });

  group('the case is kept', () {
    test('the locks keep their ids and numbers: clock 7, train 9, park (swan) 2, museum (stone) 4 → 7924', () {
      final fin = ep01.finalMission;
      expect(fin.dialSymbols, order);
      expect(ep01.missions.firstWhere((m) => m.id == 'm05').evidence!.symbols, order);
      final numberBySymbol = {for (final c in ep01.allClues) c.symbol: c.value};
      expect([for (final s in order) numberBySymbol[s]], ['7', '9', '2', '4']);
      expect(fin.answer, '7924');
      expect(AnswerChecker.isCorrect(fin, '7924'), isTrue);
    });

    test('only Case 01 has picture locks; other cases keep their glyphs', () {
      for (final e in season.where((e) => e.id != 'ep01')) {
        expect(e.finalMission.dialSymbols, isEmpty, reason: e.id);
        for (final ev in e.allEvidence) {
          expect(ev.symbols, isEmpty, reason: '${e.id} ${ev.id}');
        }
      }
      // The clue stamps of every case are as before.
      expect(GameSymbol.of('park').label, 'Park');
      expect(GameSymbol.of('museum').label, 'Museum');
      expect(GameSymbol.of('park').asset, isNull);
    });
  });

  group('on screen', () {
    // The Crown Symbol's order: the same pictures and names, arrows between,
    // no numbers.
    testWidgets('the Crown Symbol evidence shows the four pictures in order, named, without numbers', (t) async {
      await t.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child: SymbolSequence(symbols: order)))));
      await t.pump();
      final xs = [for (final s in order) t.getCenter(find.byKey(ValueKey('sequence-$s'))).dx];
      expect(xs, orderedEquals([...xs]..sort()));
      for (final s in order) {
        final image = t.widget<Image>(find.descendant(of: find.byKey(ValueKey('sequence-$s')), matching: find.byType(Image)));
        expect((image.image as AssetImage).assetName, RoyalBoxPicture.of(s)!.file);
        expect(find.text(names[s]!), findsOneWidget);
      }
      expect(find.textContaining(RegExp(r'\d')), findsNothing, reason: 'no numbers by the pictures');
      final semantics = t.ensureSemantics();
      expect(find.bySemanticsLabel('In order: Clock, then Train, then Swan, then Stone.'), findsOneWidget);
      semantics.dispose();
    });

    Future<WidgetRef> openFinal(WidgetTester t, Size size, {double textScale = 1, String route = Routes.finalMission}) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      t.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final start = DateTime.now().subtract(const Duration(minutes: 5));
      late WidgetRef ref;
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: {
          AppConstants.progressKeyFor(ep01.id): jsonEncode(GameProgress(
            detectiveName: 'MINYOUNG',
            introSeen: true,
            completedMissionIds: [for (final m in ep01.missions) m.id],
            missionStartedAt: {ep01.finalMission.id: start},
            startedAt: start,
            playMillis: 0,
          ).toJson()),
          AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: ep01.id).toJson()),
        }),
        child: RepaintBoundary(
          key: const ValueKey('shot'),
          child: Consumer(builder: (context, r, _) {
            ref = r;
            return const WorldMysteryApp();
          }),
        ),
      ));
      await wait(t, const Duration(milliseconds: 300));
      ref.read(routerProvider).go(route);
      await wait(t, const Duration(milliseconds: 1500));
      return ref;
    }

    // The notebook's EVIDENCE (2026-10-19): the Pocket Watch's tile and its
    // close-up show the same watch as the CLOCK lock; screen readers hear
    // its name once (the picture is not read).
    for (final (size, scale) in const [(Size(360, 640), 1.0), (Size(360, 640), 1.3), (Size(430, 932), 1.0), (Size(768, 1024), 1.0)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}@$scale';
      testWidgets('the notebook $tag: the Pocket Watch tile and its close-up show the CLOCK picture', (t) async {
        final semantics = t.ensureSemantics();
        final ref = await openFinal(t, size, textScale: scale, route: Routes.notebook);
        await t.tap(find.text('EVIDENCE'));
        await wait(t, const Duration(milliseconds: 800));
        final tile = find.ancestor(of: find.text('Pocket Watch'), matching: find.byType(EvidenceTile));
        await Scrollable.ensureVisible(t.element(tile), alignment: 0.5);
        await wait(t, const Duration(milliseconds: 400));
        expect(t.takeException(), isNull, reason: 'no overflow');
        String asset(Finder image) => ((t.widget<Image>(image).image as ResizeImage).imageProvider as AssetImage).assetName;
        final tileImage = find.descendant(of: tile, matching: find.byType(Image));
        expect(asset(tileImage), RoyalBoxPicture.of('clock')!.file);
        // The picture inside the tile, not cut by its edges.
        final tileRect = t.getRect(tile);
        final pictureRect = t.getRect(tileImage);
        expect(tileRect.contains(pictureRect.topLeft) && tileRect.contains(pictureRect.bottomRight - const Offset(1, 1)), isTrue);
        expect(find.bySemanticsLabel('Pocket Watch. Tap to look closer.'), findsOneWidget, reason: 'read once, the picture silent');
        // The other evidence as before: letter and key pictures, the map drawn.
        for (final (name, file) in [('Old Letter', ArtAssets.objects['letter']), ('Golden Key', ArtAssets.objects['key'])]) {
          final other = find.descendant(of: find.ancestor(of: find.text(name), matching: find.byType(EvidenceTile)), matching: find.byType(Image));
          expect(asset(other), file, reason: name);
        }
        expect(find.descendant(of: find.ancestor(of: find.text('London Map'), matching: find.byType(EvidenceTile)), matching: find.byType(Image)),
            findsNothing);
        // Decoded for real, so the shot shows the picture, not its fallback mark.
        await t.runAsync(() => precacheImage(AssetImage(RoyalBoxPicture.of('clock')!.file), t.element(tile)));
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
        await t.pump();
        await capture(t, 'case01_notebook_watch_$tag');

        await t.tap(tile);
        await wait(t, const Duration(milliseconds: 800));
        expect(t.takeException(), isNull, reason: 'no overflow in the close-up');
        final zoomImages = find.byType(Image).evaluate().where((e) => e.widget is Image && ((e.widget as Image).image is ResizeImage)).toList();
        expect(zoomImages.map((e) => (((e.widget as Image).image as ResizeImage).imageProvider as AssetImage).assetName),
            contains(RoyalBoxPicture.of('clock')!.file));
        expect(find.text('Pocket Watch'), findsWidgets);
        expect(ref.read(gameControllerProvider).collectedEvidence(ep01).map((e) => e.id), contains('e03'));
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
        await t.pump();
        await capture(t, 'case01_notebook_watch_zoom_$tag');
        semantics.dispose();
      });
    }

    for (final (size, scale) in const [(Size(360, 640), 1.0), (Size(360, 640), 1.3), (Size(430, 932), 1.0), (Size(768, 1024), 1.0)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}@$scale';
      testWidgets('the final $tag: each lock shows its picture and name over its wheel; 7924 typed opens the box', (t) async {
        final ref = await openFinal(t, size, textScale: scale);
        await Scrollable.ensureVisible(t.element(find.byKey(const ValueKey('lock-picture-clock'))), alignment: 0.3);
        await wait(t, const Duration(milliseconds: 400));
        expect(t.takeException(), isNull, reason: 'no overflow');
        final rects = [for (final s in order) t.getRect(find.byKey(ValueKey('lock-picture-$s')))];
        for (var i = 1; i < 4; i++) {
          expect(rects[i].left, greaterThan(rects[i - 1].right - 1), reason: 'left to right, in order');
        }
        for (final (i, s) in order.indexed) {
          final lock = find.byKey(ValueKey('lock-picture-$s'));
          // The same file as on the crown card.
          final image = t.widget<Image>(find.descendant(of: lock, matching: find.byType(Image)));
          expect((image.image as AssetImage).assetName, RoyalBoxPicture.of(s)!.file, reason: s);
          expect(image.fit, BoxFit.contain);
          expect(image.color, isNull, reason: 'never tinted');
          expect(t.getRect(find.descendant(of: lock, matching: find.byType(Image))).width, greaterThanOrEqualTo(48));
          final name = find.descendant(of: lock, matching: find.text(names[s]!));
          expect(name, findsOneWidget, reason: names[s]);
          expect(t.renderObject<RenderParagraph>(name).didExceedMaxLines, isFalse);
          // The picture above its wheel.
          expect(rects[i].bottom, lessThan(t.getRect(find.byTooltip('Lock ${i + 1} up')).top + 1));
        }
        // The wheels as before (and the shut box's drums, written to match).
        for (var i = 0; i < 4; i++) {
          expect(
            find.byWidgetPredicate((w) => w is Text && w.data == '0' && (w.semanticsLabel ?? '').startsWith('Lock ${i + 1}, ')),
            findsOneWidget,
            reason: 'wheel ${i + 1}',
          );
          expect(find.byKey(ValueKey('royal-box-dial-$i')), findsOneWidget, reason: 'drum ${i + 1}');
        }
        await capture(t, 'case01_final_locks_$tag');

        // The detective types the number: 7 9 2 4.
        for (final (i, digit) in '7924'.split('').map(int.parse).indexed) {
          final up = find.byTooltip('Lock ${i + 1} up');
          await Scrollable.ensureVisible(t.element(up), alignment: 0.5);
          for (var n = 0; n < digit; n++) {
            await t.tap(up);
            await t.pump(const Duration(milliseconds: 20));
          }
        }
        await wait(t, const Duration(milliseconds: 300));
        final open = find.text('OPEN THE BOX');
        await Scrollable.ensureVisible(t.element(open), alignment: 0.5);
        await t.tap(open);
        await wait(t, const Duration(milliseconds: 3000));
        expect(ref.read(gameControllerProvider).isCompleted(ep01.finalMission.id), isTrue);
      });
    }

    // The notebook: Case 01's clue cards show their lock's picture (by each
    // clue's own symbol, as the data has it), so a clue and its lock look
    // alike; the Royal Box clue and other cases' clues keep their stamps.
    testWidgets('the notebook: Case 01 clues show the lock pictures by their own symbol; others keep their stamps', (t) async {
      final ep02 = season.firstWhere((e) => e.id == 'ep02');
      final other = ep02.allClues.firstWhere((c) => c.id == 'ep02_c1');
      expect(order, contains(other.symbol), reason: 'a clue of another case with a lock symbol');
      const expected = {'c01': 'train', 'c02': 'museum', 'c03': 'clock', 'c04': 'park'};
      // What the data says each clue is (never guessed from its order).
      for (final MapEntry(key: id, value: s) in expected.entries) {
        expect(ep01.allClues.firstWhere((c) => c.id == id).symbol, s, reason: id);
      }
      t.view.physicalSize = const Size(360, 1400) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(),
        child: MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                for (final (i, c) in [...ep01.allClues, other].indexed)
                  Padding(padding: const EdgeInsets.all(8), child: ClueCard(clue: c, index: i)),
              ],
            ),
          ),
        ),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(t.takeException(), isNull, reason: 'no overflow at 360');
      for (final MapEntry(key: id, value: s) in expected.entries) {
        final box = find.byKey(ValueKey('clue-picture-$id'));
        expect(box, findsOneWidget, reason: id);
        final image = t.widget<Image>(find.descendant(of: box, matching: find.byType(Image)));
        expect((image.image as AssetImage).assetName, RoyalBoxPicture.of(s)!.file, reason: id);
        expect(t.getRect(box).width, greaterThanOrEqualTo(44));
      }
      // The Royal Box (c05: the crown) and another case's clue: their stamps.
      expect(find.byKey(const ValueKey('clue-picture-c05')), findsNothing);
      expect(find.byKey(ValueKey('clue-picture-${other.id}')), findsNothing);
      expect(find.byType(SymbolBadge), findsNWidgets(2));
      // Titles, notes and numbers as they are.
      for (final c in ep01.allClues) {
        expect(find.text('"${c.title}"'), findsOneWidget, reason: c.id);
        expect(find.text(c.value), findsWidgets, reason: c.id);
      }
      await capture(t, 'case01_clue_cards');
    });

    testWidgets('the final, nothing gives the code away: hints, letter and screen-reader labels', (t) async {
      final fin = ep01.finalMission;
      for (final line in [...fin.hints, fin.letter, fin.question, ...fin.story]) {
        expect(line, isNot(contains('7924')), reason: line);
        expect(RegExp(r'\d').hasMatch(line), isFalse, reason: line);
      }
      final semantics = t.ensureSemantics();
      await openFinal(t, const Size(390, 844));
      // Only the wheels' own (untouched) numbers are read: all 0.
      expect(find.bySemanticsLabel(RegExp('7924')), findsNothing);
      for (final (i, name) in const ['Clock', 'Train', 'Swan', 'Stone'].indexed) {
        expect(find.bySemanticsLabel('Lock ${i + 1}, $name: 0'), findsOneWidget);
      }
      semantics.dispose();
    });

    // The Discovery Moment's evidence card (2026-10-19): the Crown Symbol
    // (e05) is shown by the crown picture, closer in its round frame. The
    // Pocket Watch (e03) is shown by the Royal Box's own watch picture, the
    // CLOCK of the locks (requested: one watch everywhere), a little farther
    // so its bow and lid stay whole. The letter, key and map are not the
    // lock pictures' objects (e01, e02 keep their own pictures).
    testWidgets('the Discovery evidence card: the Crown Symbol by the crown picture, closer; the watch by the CLOCK', (t) async {
      final evidence = {for (final e in season) for (final x in e.allEvidence) x.id: x};
      expect([for (final id in ['e01', 'e02', 'e03', 'e04', 'e05']) evidence[id]!.name],
          ['Old Letter', 'Golden Key', 'Pocket Watch', 'London Map', 'Crown Symbol']);
      expect(ArtAssets.evidencePictures['e05'], ArtAssets.objects['crown']);
      expect(ArtAssets.evidencePictures['e03'], RoyalBoxPicture.of('clock')!.file, reason: 'the same watch as the lock');
      expect(ArtAssets.evidencePictureZoom, {'e05': 1.5, 'e03': 0.95}, reason: 'no other evidence shown closer or farther');
      t.view.physicalSize = const Size(360, 800) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(),
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                for (final id in ['e05', 'e03', 'ep12_e4'])
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: EvidenceChip(key: ValueKey('chip-$id'), evidence: evidence[id]!, note: evidence[id]!.inscription),
                  ),
              ],
            ),
          ),
        ),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(t.takeException(), isNull);
      Finder inChip(String id, Finder f) => find.descendant(of: find.byKey(ValueKey('chip-$id')), matching: f);
      // e05: the crown picture, whole (the parchment margin trimmed), 1.5×.
      final crown = t.widget<Image>(inChip('e05', find.byType(Image)));
      // (Sized for the screen: the asset inside a ResizeImage.)
      expect(((crown.image as ResizeImage).imageProvider as AssetImage).assetName, ArtAssets.objects['crown']);
      expect(crown.color, isNull, reason: 'its own colours');
      final zoom = t.widget<Transform>(find.ancestor(of: inChip('e05', find.byType(Image)), matching: find.byType(Transform)).first);
      expect(zoom.transform.getMaxScaleOnAxis(), closeTo(1.5, 1e-9));
      // Its name and words as before, for every reader.
      expect(inChip('e05', find.text('Crown Symbol')), findsOneWidget);
      expect(inChip('e05', find.textContaining('Four pictures for four locks.')), findsOneWidget);
      // e03: the Royal Box's watch, whole, in its own colours; its words as before.
      final watch = t.widget<Image>(inChip('e03', find.byType(Image)));
      expect(((watch.image as ResizeImage).imageProvider as AssetImage).assetName, RoyalBoxPicture.of('clock')!.file);
      expect(watch.color, isNull, reason: 'its own colours');
      final farther = find.ancestor(of: inChip('e03', find.byType(Image)), matching: find.byType(Transform)).first;
      expect(t.widget<Transform>(farther).transform.entry(0, 0), closeTo(0.95, 1e-9), reason: "x scale (z stays 1)");
      expect(inChip('e03', find.text('Pocket Watch')), findsOneWidget);
      expect(inChip('e03', find.text("It stopped at 7 o'clock.")), findsOneWidget);
      // Another case's pictured evidence: its picture as before, not closer.
      final other = find.ancestor(of: inChip('ep12_e4', find.byType(Image)), matching: find.byType(Transform)).first;
      expect(t.widget<Transform>(other).transform.getMaxScaleOnAxis(), closeTo(1, 1e-9));
      await capture(t, 'case01_evidence_chips');
    });

    testWidgets('the final, screen readers: each wheel names its picture', (t) async {
      final semantics = t.ensureSemantics();
      await openFinal(t, const Size(390, 844));
      for (final (i, name) in const ['Clock', 'Train', 'Swan', 'Stone'].indexed) {
        expect(find.bySemanticsLabel('Lock ${i + 1}, $name: 0'), findsOneWidget, reason: name);
      }
      semantics.dispose();
    });
  });
}
