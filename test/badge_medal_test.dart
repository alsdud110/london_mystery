import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/core/theme/app_theme.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/badge_medal.dart';
import 'package:london_mystery/widgets/ink_icon.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';

/// The badge medal pictures (2026-10-19): one finished medal per badge,
/// shown as it is when earned; the empty rosette, greyed, with a lock, for
/// every badge still to win. Only the pictures changed: badge ids, awards,
/// XP and saves are those of `game_controller_test` and `type_b_rewards_test`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A picture file on screen (decoded at its size: a ResizeImage around it).
  Finder picture(String file) => find.byWidgetPredicate((w) {
        if (w is! Image) return false;
        final image = w.image;
        final source = image is ResizeImage ? image.imageProvider : image;
        return source is AssetImage && source.assetName == file;
      });

  group('mapping', () {
    test('badge ids are the saved ones, unchanged', () {
      expect([for (final b in GameBadge.values) b.name], [
        'firstClue', 'sharpEyes', 'quickThinker', 'puzzleSolver', 'londonExplorer', 'masterDetective', //
        'clockWatcher', 'evidenceHunter', 'letterReader', 'codeBreaker', 'mapMaster', 'londonLegend', //
        'secondLook', 'notebookExplorer', 'wordCollector',
      ]);
      expect([for (final b in GameBadge.values) if (b.retired) b], [GameBadge.sharpEyes, GameBadge.quickThinker]);
    });

    test('every badge has its own picture, named after it', () {
      String snake(String id) => id.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');
      expect(ArtAssets.badges.keys.toSet(), GameBadge.values.toSet());
      expect(ArtAssets.badges.values.toSet(), hasLength(GameBadge.values.length), reason: 'no shared picture');
      for (final b in GameBadge.values) {
        expect(ArtAssets.badges[b], 'assets/images/badges/badge_${snake(b.name)}.png', reason: b.name);
      }
      expect(ArtAssets.badgeFrame, 'assets/images/badges/badge_frame.png');
      expect(ArtAssets.badges.values, isNot(contains(ArtAssets.badgeFrame)));
    });

    test("every badge has a short line for the notebook's grid; its description stays whole", () {
      expect({for (final b in GameBadge.values) b: b.shortDescription}, {
        GameBadge.firstClue: '첫 단서 발견',
        GameBadge.puzzleSolver: '퍼즐 3개 해결',
        GameBadge.londonExplorer: '모든 장소 방문',
        GameBadge.masterDetective: '사건 해결 완료',
        GameBadge.secondLook: '단서 다시 확인',
        GameBadge.notebookExplorer: '수첩 증거 확인',
        GameBadge.wordCollector: '단어 3개 확인',
        GameBadge.clockWatcher: '시계 비밀 해결',
        GameBadge.evidenceHunter: '숨은 단서 추적',
        GameBadge.letterReader: '비밀 편지 해결',
        GameBadge.codeBreaker: '암호 해독 성공',
        GameBadge.mapMaster: '지도 완성',
        GameBadge.londonLegend: '시즌 1 완료',
        GameBadge.sharpEyes: '이전 버전 배지',
        GameBadge.quickThinker: '이전 버전 배지',
      });
      // The descriptions the details show are those of the game, unchanged.
      expect(GameBadge.masterDetective.description, '에피소드 완료');
      expect(GameBadge.secondLook.description, '막혔을 때 편지나 증거를 다시 확인하고 해결');
      expect(GameBadge.sharpEyes.description, '이전 버전에서 미션을 해결하며 받은 배지');
    });

    test('the badges folder is bundled', () {
      expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/images/badges/'));
    });
  });

  group('the files', () {
    /// The picture decoded small, as RGBA bytes.
    Future<(ui.Image, ByteData)> decode(String path) async {
      final bytes = File(path).readAsBytesSync();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 128, targetHeight: 128);
      final image = (await codec.getNextFrame()).image;
      return (image, (await image.toByteData())!);
    }

    int alpha(ByteData px, int x, int y) => px.getUint8((y * 128 + x) * 4 + 3);

    for (final path in [...ArtAssets.badges.values, ArtAssets.badgeFrame]) {
      test('$path: a square PNG with a transparent background', () async {
        final file = File(path);
        expect(file.existsSync(), isTrue);
        final bytes = file.readAsBytesSync();
        expect(bytes.sublist(1, 4), ascii.encode('PNG'));
        // The IHDR header: its size, and colour type 6 (RGBA).
        final header = ByteData.sublistView(bytes, 16, 26);
        expect(Size(header.getUint32(0).toDouble(), header.getUint32(4).toDouble()), ArtAssets.badgePixels);
        expect(header.getUint8(9), 6, reason: 'RGBA: an alpha channel');

        final (image, px) = await decode(path);
        addTearDown(image.dispose);
        // Outside the round medal: transparent, so it sits on any page.
        for (final (x, y) in [(0, 0), (127, 0), (0, 127), (127, 127), (6, 6), (121, 121)]) {
          expect(alpha(px, x, y), lessThan(16), reason: 'corner ($x, $y)');
        }
        // The rosette's edge (left and right of the centre): solid.
        expect(alpha(px, 64, 8), greaterThan(200), reason: 'top of the rosette');
        expect(alpha(px, 64, 120), greaterThan(200), reason: 'bottom of the rosette');
        // The face: an emblem on every badge; open on the empty frame.
        if (path == ArtAssets.badgeFrame) {
          expect(alpha(px, 64, 52), lessThan(16), reason: 'the frame has an empty face');
        } else {
          expect(alpha(px, 64, 64), greaterThan(200), reason: 'the face is painted');
        }
      });
    }
  });

  group('BadgeMedal', () {
    Future<void> pump(WidgetTester t, Widget child) async {
      await t.pumpWidget(MaterialApp(theme: AppTheme.light(), home: Scaffold(body: Center(child: child))));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300))); // decode
      await t.pump();
    }

    testWidgets('earned: its own picture in full colour, nothing drawn over it', (t) async {
      await pump(t, const BadgeMedal(badge: GameBadge.firstClue, size: 72));
      expect(picture(ArtAssets.badges[GameBadge.firstClue]!), findsOneWidget);
      final image = t.widget<Image>(picture(ArtAssets.badges[GameBadge.firstClue]!));
      expect(image.color, isNull, reason: 'never tinted');
      expect(image.fit, BoxFit.contain);
      expect(find.byType(ColorFiltered), findsNothing);
      expect(find.byType(InkIcon), findsNothing, reason: 'no glyph or lock over the picture');
      expect(picture(ArtAssets.badgeFrame), findsNothing, reason: 'the medal has its own rosette');
      expect(t.getSize(find.byType(Image)), const Size(72, 72));
      expect(t.takeException(), isNull);
    });

    testWidgets('locked: the empty rosette, greyed, with a lock; its emblem stays hidden', (t) async {
      await pump(t, const BadgeMedal(badge: GameBadge.puzzleSolver, earned: false, size: 72));
      expect(picture(ArtAssets.badgeFrame), findsOneWidget);
      expect(picture(ArtAssets.badges[GameBadge.puzzleSolver]!), findsNothing, reason: 'not given away');
      expect(find.byType(ColorFiltered), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is InkIcon && w.glyph == InkGlyph.lock), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is InkIcon && w.glyph == GameBadge.puzzleSolver.glyph), findsNothing);
      // Its name and description still say what is to discover.
      expect(find.text('Puzzle Solver'), findsOneWidget);
      expect(find.text(GameBadge.puzzleSolver.description), findsOneWidget);
    });

    testWidgets('a screen reader hears the name and the state, once', (t) async {
      final semantics = t.ensureSemantics();
      await pump(
        t,
        const Wrap(children: [
          BadgeMedal(badge: GameBadge.firstClue),
          BadgeMedal(badge: GameBadge.puzzleSolver, earned: false),
          BadgeMedal(badge: GameBadge.sharpEyes),
        ]),
      );
      expect(find.bySemanticsLabel('First Clue, earned'), findsOneWidget);
      expect(find.bySemanticsLabel('Puzzle Solver, locked'), findsOneWidget);
      expect(find.bySemanticsLabel('Sharp Eyes, retired, earned'), findsOneWidget);
      // The picture and the label text are not read a second time.
      expect(find.bySemanticsLabel(RegExp('^First Clue\$')), findsNothing);
      expect(find.bySemanticsLabel(GameBadge.firstClue.description), findsNothing);
      semantics.dispose();
    });

    testWidgets('earned and locked medals take the same space', (t) async {
      await pump(
        t,
        const Row(mainAxisSize: MainAxisSize.min, children: [
          BadgeMedal(badge: GameBadge.londonLegend, size: 72),
          BadgeMedal(badge: GameBadge.londonLegend, earned: false, size: 72),
        ]),
      );
      final sizes = {for (final e in find.byType(BadgeMedal).evaluate()) t.getSize(find.byWidget(e.widget))};
      expect(sizes, hasLength(1));
    });
  });

  group('the notebook BADGES page', () {
    final ep02 = MockEpisodeRepository.bundled().firstWhere((e) => e.id == 'ep02');

    /// Case 02 open: First Clue and Puzzle Solver earned, Sharp Eyes from an
    /// old version, the rest still to win.
    Map<String, Object> prefs() => {
          AppConstants.progressKeyFor('ep02'): jsonEncode(GameProgress(
            detectiveName: 'MINYOUNG',
            introSeen: true,
            completedMissionIds: [for (final m in ep02.missions.take(3)) m.id],
            badgeIds: const ['firstClue', 'puzzleSolver', 'sharpEyes'],
            startedAt: DateTime(2026, 9, 29, 10),
            playMillis: 0,
          ).toJson()),
          AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINYOUNG').toJson()),
          AppConstants.seasonStorageKey: jsonEncode(
            const SeasonProgress(activeEpisodeId: 'ep02', solvedEpisodeIds: ['ep01']).toJson(),
          ),
        };

    /// The notebook open on BADGES, on a [width] × [height] phone.
    Future<void> openBadges(WidgetTester t, double width, double scale, {double height = 800}) async {
      t.view.physicalSize = Size(width, height) * 3;
      t.view.devicePixelRatio = 3;
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pumpWidget(ProviderScope(overrides: await testOverrides(prefs: prefs()), child: const LondonMysteryApp()));
      await wait(t, const Duration(milliseconds: 300));
      ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first).read(routerProvider).go(Routes.notebook);
      await wait(t, const Duration(milliseconds: 900));
      await t.tap(find.text('BADGES'));
      await wait(t, const Duration(milliseconds: 900));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400))); // decode
      await wait(t, const Duration(milliseconds: 200));
      expect(t.takeException(), isNull, reason: 'no overflow');
    }

    /// The grid page's scroll view.
    Finder badgePage() => find.ancestor(of: find.byType(BadgeMedal).first, matching: find.byType(Scrollable)).first;

    /// Opens [b]'s details from the grid.
    Future<void> openDetails(WidgetTester t, GameBadge b) async {
      final cell = find.ancestor(of: find.byWidgetPredicate((w) => w is BadgeMedal && w.badge == b), matching: find.byType(GestureDetector)).first;
      await t.ensureVisible(cell);
      await wait(t, const Duration(milliseconds: 200));
      await t.tap(cell);
      await wait(t, const Duration(milliseconds: 600));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300))); // decode
      await wait(t, const Duration(milliseconds: 200));
      expect(t.takeException(), isNull, reason: 'the sheet fits');
    }

    /// The details sheet's medal.
    Finder sheetMedal() => find.byWidgetPredicate((w) => w is BadgeMedal && w.size == 132);

    /// [text] on the details sheet.
    Finder onSheet(String text) => find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

    for (final width in const [360.0, 430.0, 768.0]) {
      for (final scale in const [1.0, 1.3]) {
        testWidgets('${width.toInt()}dp, text ×$scale: three a row, every medal whole, names and descriptions in line', (t) async {
          await openBadges(t, width, scale);

          // The shared badges, Case 02's own, and the retired one it holds.
          final shown = GameBadge.shownFor(ep02, const ['firstClue', 'puzzleSolver', 'sharpEyes']);
          expect(shown.first, GameBadge.sharpEyes);
          expect(shown, contains(GameBadge.clockWatcher));
          expect(shown, isNot(contains(GameBadge.quickThinker)), reason: 'retired, never earned: not shown');
          final medals = find.byType(BadgeMedal);
          expect(medals, findsNWidgets(shown.length));

          for (final b in [GameBadge.firstClue, GameBadge.puzzleSolver, GameBadge.sharpEyes]) {
            expect(picture(ArtAssets.badges[b]!), findsOneWidget, reason: '${b.name} earned');
          }
          expect(picture(ArtAssets.badges[GameBadge.clockWatcher]!), findsNothing, reason: 'locked');
          expect(picture(ArtAssets.badgeFrame), findsNWidgets(shown.length - 3));

          final screen = Offset.zero & t.view.physicalSize / 3;
          final pictures = find.descendant(of: medals, matching: find.byType(Image));
          final sizes = <Size>{};
          for (final e in pictures.evaluate()) {
            final rect = t.getRect(find.byWidget(e.widget));
            sizes.add(Size((rect.width * 100).round() / 100, (rect.height * 100).round() / 100));
            expect(rect.left >= screen.left && rect.right <= screen.right, isTrue, reason: 'within the page: $rect');
          }
          expect(sizes, {const Size(84, 84)}, reason: 'larger, square, undistorted, all alike');

          // Three columns, rows in line.
          final rects = [for (final b in shown) t.getRect(find.descendant(of: find.byWidgetPredicate((w) => w is BadgeMedal && w.badge == b), matching: find.byType(Image)))];
          expect({for (final r in rects) r.left.round()}, hasLength(3), reason: 'three columns');
          for (var row = 0; row < shown.length; row += 3) {
            final tops = {for (final r in rects.skip(row).take(3)) r.top.round()};
            expect(tops, hasLength(1), reason: 'row ${row ~/ 3}: medals in line');
            // One-line and two-line names alike: every name starts the same
            // distance under its medal, every description at the same height.
            final cells = shown.skip(row).take(3).toList();
            final nameTops = {for (final b in cells) t.getTopLeft(find.text(b.title)).dy.round()};
            final textTops = {for (final b in cells) t.getTopLeft(find.text(b.shortDescription)).dy.round()};
            expect(nameTops, hasLength(1), reason: 'row ${row ~/ 3}: names in line');
            expect(textTops, hasLength(1), reason: 'row ${row ~/ 3}: descriptions in line');
          }
          final gaps = {
            for (final (i, b) in shown.indexed) (t.getTopLeft(find.text(b.title)).dy - rects[i].bottom).round(),
          };
          expect(gaps, hasLength(1), reason: 'the same space under every medal');
          // Each cell: one tap target, at least 48 dp.
          for (final b in shown) {
            final cell = find.ancestor(of: find.byWidgetPredicate((w) => w is BadgeMedal && w.badge == b), matching: find.byType(GestureDetector)).first;
            final size = t.getSize(cell);
            expect(size.width >= 48 && size.height >= 48, isTrue, reason: '${b.name}: $size');
          }

          // The collection page: a slot for every badge, all one size, the
          // same space across and down, the slot itself the tap target.
          Finder slotOf(GameBadge b) =>
              find.ancestor(of: find.byWidgetPredicate((w) => w is BadgeMedal && w.badge == b), matching: find.byType(AnimatedContainer)).first;
          final slots = [for (final b in shown) t.getRect(slotOf(b))];
          String r1(double v) => v.toStringAsFixed(1);
          expect({for (final s in slots) '${r1(s.width)}×${r1(s.height)}'}, hasLength(1), reason: 'one slot size: $slots');
          expect(slots.first.width, lessThanOrEqualTo(136), reason: 'a slot does not stretch on a tablet');
          final across = {
            for (var i = 0; i < slots.length; i++)
              if (i % 3 != 0) r1(slots[i].left - slots[i - 1].right),
          };
          final down = {for (var i = 3; i < slots.length; i++) r1(slots[i].top - slots[i - 3].bottom)};
          expect(across, {'8.0'}, reason: 'across');
          expect(down, {'8.0'}, reason: 'down');
          for (final (i, b) in shown.indexed) {
            final cell = find.ancestor(of: find.byWidgetPredicate((w) => w is BadgeMedal && w.badge == b), matching: find.byType(GestureDetector)).first;
            expect(t.getRect(cell), slots[i], reason: '${b.name}: the whole slot is the tap target');
            // Inside its slot, whole.
            expect(slots[i].contains(rects[i].topLeft) && slots[i].contains(rects[i].bottomRight - const Offset(0.01, 0.01)), isTrue);
          }
          // Each slot's slot: no fill, line or shadow beyond the fine ink pocket.
          final earnedBox = t.widget<AnimatedContainer>(slotOf(GameBadge.firstClue)).decoration! as BoxDecoration;
          final lockedBox = t.widget<AnimatedContainer>(slotOf(GameBadge.clockWatcher)).decoration! as BoxDecoration;
          expect(earnedBox.boxShadow, isNull);
          expect(earnedBox.border!.top.width, 0.8);
          expect(lockedBox.border!.top.color.a, lessThan(earnedBox.border!.top.color.a), reason: 'a locked pocket is fainter');
          expect(lockedBox.color!.a, lessThan(earnedBox.color!.a));
          // The short descriptions: never cut off, one or two lines alike in
          // every slot.
          final captionLines = {
            for (final b in shown) (t.renderObject(find.text(b.shortDescription)) as RenderParagraph).maxLines,
          };
          expect(captionLines, hasLength(1));
          for (final b in shown) {
            expect((t.renderObject(find.text(b.shortDescription)) as RenderParagraph).didExceedMaxLines, isFalse, reason: b.name);
            // (Some are one and the same: First Clue, Puzzle Solver.)
            if (b.description != b.shortDescription) {
              expect(find.text(b.description), findsNothing, reason: 'the whole description is on the details');
            }
          }

          // The count, under the medals (the page scrolls on a short phone).
          await t.scrollUntilVisible(find.text('3 / ${shown.length} badges'), 200, scrollable: badgePage());
          expect(find.text('3 / ${shown.length} badges'), findsOneWidget);
          expect(t.takeException(), isNull);
        });
      }
    }

    for (final (width, height, scale) in const [(360.0, 640.0, 1.0), (360.0, 640.0, 1.3), (768.0, 1024.0, 1.3)]) {
      testWidgets('${width.toInt()}×${height.toInt()}, text ×$scale: a tap opens the details; each state as it is', (t) async {
        await openBadges(t, width, scale, height: height);

        // Earned: the colour medal, the whole description, EARNED.
        await openDetails(t, GameBadge.firstClue);
        expect(sheetMedal(), findsOneWidget);
        expect(find.descendant(of: sheetMedal(), matching: picture(ArtAssets.badges[GameBadge.firstClue]!)), findsOneWidget);
        expect(find.text('EARNED'), findsOneWidget);
        expect(onSheet(GameBadge.firstClue.description), findsOneWidget, reason: 'the whole description, on the sheet');
        expect(t.getSize(find.descendant(of: sheetMedal(), matching: find.byType(Image))), const Size(132, 132));
        await t.tap(find.text('CLOSE'));
        await wait(t, const Duration(milliseconds: 600));
        expect(sheetMedal(), findsNothing);

        // Locked: the grey rosette and its lock, never the colour medal.
        await openDetails(t, GameBadge.clockWatcher);
        expect(find.descendant(of: sheetMedal(), matching: picture(ArtAssets.badgeFrame)), findsOneWidget);
        expect(picture(ArtAssets.badges[GameBadge.clockWatcher]!), findsNothing, reason: 'not on the sheet, not on the page');
        expect(find.descendant(of: sheetMedal(), matching: find.byWidgetPredicate((w) => w is InkIcon && w.glyph == InkGlyph.lock)), findsOneWidget);
        expect(find.text('LOCKED'), findsOneWidget);
        expect(onSheet(GameBadge.clockWatcher.description), findsOneWidget);
        expect(find.text(GameBadge.clockWatcher.description), findsOneWidget, reason: 'the page shows the short one');
        // Back closes it.
        await t.binding.handlePopRoute();
        await wait(t, const Duration(milliseconds: 600));
        expect(sheetMedal(), findsNothing);
        expect(find.text('BADGES'), findsOneWidget, reason: 'still on the notebook');

        // Retired, held from an old version: its colour medal, RETIRED · EARNED.
        await openDetails(t, GameBadge.sharpEyes);
        expect(find.descendant(of: sheetMedal(), matching: picture(ArtAssets.badges[GameBadge.sharpEyes]!)), findsOneWidget);
        expect(find.text('RETIRED · EARNED'), findsOneWidget);
        expect(onSheet(GameBadge.sharpEyes.description), findsOneWidget);
        // A tap outside closes it.
        await t.tapAt(const Offset(10, 10));
        await wait(t, const Duration(milliseconds: 600));
        expect(sheetMedal(), findsNothing);
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('the page keeps its place when the details close', (t) async {
      await openBadges(t, 360, 1.3, height: 640);
      final shown = GameBadge.shownFor(ep02, const ['firstClue', 'puzzleSolver', 'sharpEyes']);
      await openDetails(t, shown.last); // scrolls down to it
      final at = t.state<ScrollableState>(badgePage()).position.pixels;
      expect(at, greaterThan(0), reason: 'the last row is below the fold');
      await t.tap(find.text('CLOSE'));
      await wait(t, const Duration(milliseconds: 600));
      expect(t.state<ScrollableState>(badgePage()).position.pixels, at);
    });

    testWidgets('a screen reader hears one button per badge, and the whole description on its details', (t) async {
      final semantics = t.ensureSemantics();
      await openBadges(t, 360, 1.0);
      expect(
        t.getSemantics(find.bySemanticsLabel('First Clue, earned')),
        isSemantics(label: 'First Clue, earned', isButton: true, hasTapAction: true, onTapHint: 'show badge details'),
      );
      expect(
        t.getSemantics(find.bySemanticsLabel('Clock Watcher, locked')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      expect(find.bySemanticsLabel('Sharp Eyes, retired, earned'), findsOneWidget);
      // The grid's texts are inside the button's label, not read again.
      expect(find.bySemanticsLabel(GameBadge.firstClue.description), findsNothing);

      await openDetails(t, GameBadge.firstClue);
      expect(find.bySemanticsLabel(GameBadge.firstClue.description), findsOneWidget, reason: 'read on the details');
      expect(find.bySemanticsLabel('earned'), findsOneWidget, reason: 'its state');
      expect(find.bySemanticsLabel('First Clue, earned'), findsOneWidget, reason: 'the sheet medal is not read twice');
      semantics.dispose();
    });
  });

  group('other screens keep their medal sizes', () {
    test('a medal with no label width is laid out as before', () {
      // How to Play (56) and Case Closed (70 and 30) pass no label width or
      // gap: the label is the medal plus 36, right under it.
      const medal = BadgeMedal(badge: GameBadge.firstClue, size: 56);
      expect(medal.labelWidth, isNull);
      expect(medal.labelGap, 0);
    });

    testWidgets('a medal of 56 is 92 wide, as before', (t) async {
      await t.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: Center(child: BadgeMedal(badge: GameBadge.firstClue, size: 56))),
      ));
      expect(t.getSize(find.byType(BadgeMedal)).width, 92);
    });

    testWidgets('Case Closed: the headline medal 70, the others 30', (t) async {
      final ep01 = MockEpisodeRepository.bundled().firstWhere((e) => e.id == 'ep01');
      t.view.physicalSize = const Size(360, 640) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: {
          AppConstants.progressKeyFor('ep01'): jsonEncode(GameProgress(
            detectiveName: 'MINYOUNG',
            introSeen: true,
            completedMissionIds: [for (final m in ep01.allMissions) m.id],
            badgeIds: [for (final b in GameBadge.forEpisode(ep01)) b.name],
            startedAt: DateTime(2026, 9, 29, 10),
            completedAt: DateTime(2026, 9, 29, 10, 30),
            playMillis: 0,
          ).toJson()),
          AppConstants.seasonStorageKey: jsonEncode(const SeasonProgress(activeEpisodeId: 'ep01', solvedEpisodeIds: ['ep01']).toJson()),
        }),
        child: const LondonMysteryApp(),
      ));
      await wait(t, const Duration(milliseconds: 300));
      ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first).read(routerProvider).go(Routes.solved);
      await wait(t, const Duration(milliseconds: 3200));
      final sizes = [for (final e in find.byType(BadgeMedal).evaluate()) (e.widget as BadgeMedal).size];
      expect(sizes.toSet(), {70, 30});
      expect(sizes.where((s) => s == 70), hasLength(1));
      for (final e in find.byType(BadgeMedal).evaluate()) {
        expect((e.widget as BadgeMedal).labelWidth, isNull);
      }
    });
  });
}
