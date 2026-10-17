import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/mock/season1/season1_discoveries.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/mission/widgets/answer_feedback.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/detective_character.dart';
import 'package:london_mystery/widgets/ink_icon.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// The player's detective (the boy or the girl chosen at CREATE YOUR
/// DETECTIVE) through the game, one expression per moment: investigating
/// by the way into a place, thinking when looking again, surprised by a new
/// find, happy at a mission solved, confident on Case Closed. Shown from the
/// saved profile (a change shows at once, a restart keeps it); a detective
/// from before avatars is the boy; nothing it shows covers the play.
void main() {
  final catalog = MockEpisodeRepository.bundled();
  final ep01 = catalog.first;

  setUpAll(() async {
    for (final (family, files) in [
      ('Sentient', ['Sentient-Variable.ttf']),
      ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
      ('LibreBaskerville', ['LibreBaskerville.ttf', 'LibreBaskerville-Italic.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await loader.load();
    }
  });

  Finder medallion(DetectiveAvatar a, DetectiveExpression e) => find.byKey(ValueKey('detective-${a.name}-${e.name}'));
  DetectiveStyle styleOf(WidgetTester t, Finder f) =>
      t.widget<DetectiveCharacter>(find.ancestor(of: f, matching: find.byType(DetectiveCharacter))).style;
  Finder anyMedallion() => find.byWidgetPredicate(
        (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('detective-'),
      );

  group('the pictures', () {
    test('each avatar has its five expressions, in one folder each, listed for the app', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final a in DetectiveAvatar.values) {
        expect(pubspec, contains('- assets/art/detectives/${a.name}/'));
        for (final e in DetectiveExpression.values) {
          final path = ArtAssets.detective(a, e);
          expect(path, 'assets/art/detectives/${a.name}/${e.name}.png');
          expect(File(path).existsSync(), isTrue, reason: '$path is in the project');
        }
      }
    });

    test('every picture is a real cut-out: RGBA, the backdrop transparent, no checker fringe', () async {
      for (final a in DetectiveAvatar.values) {
        for (final e in DetectiveExpression.values) {
          final name = '${a.name}/${e.name}';
          final bytes = File(ArtAssets.detective(a, e)).readAsBytesSync();
          expect(bytes[25], 6, reason: '$name: PNG colour type 6 (RGBA)');
          final codec = await ui.instantiateImageCodec(bytes);
          final image = (await codec.getNextFrame()).image;
          final px = (await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!.buffer.asUint8List();
          final w = image.width, h = image.height, n = w * h;
          int alpha(int x, int y) => px[(y * w + x) * 4 + 3];
          var clear = 0, solid = 0, edge = 0, greyEdge = 0;
          for (var y = 0; y < h; y++) {
            for (var x = 0; x < w; x++) {
              final al = alpha(x, y);
              if (al == 0) clear++;
              if (al == 255) solid++;
              if (al < 128 || x == 0 || y == 0 || x == w - 1 || y == h - 1) continue;
              if (alpha(x - 1, y) == 0 || alpha(x + 1, y) == 0 || alpha(x, y - 1) == 0 || alpha(x, y + 1) == 0) {
                edge++;
                final i = (y * w + x) * 4;
                final hi = math.max(px[i], math.max(px[i + 1], px[i + 2]));
                final lo = math.min(px[i], math.min(px[i + 1], px[i + 2]));
                if (hi - lo <= 14 && lo >= 185) greyEdge++;
              }
            }
          }
          expect(clear / n, greaterThan(0.12), reason: '$name: the backdrop is transparent');
          expect(solid / n, greaterThan(0.4), reason: '$name: the detective is whole');
          for (final (x, y) in [(0, 0), (w - 1, 0), (0, h ~/ 2), (w - 1, h ~/ 3)]) {
            expect(alpha(x, y), 0, reason: '$name: the backdrop at ($x, $y) is gone');
          }
          expect(greyEdge / edge, lessThan(0.03), reason: '$name: no white or grey checker fringe round the figure');
        }
      }
    });

    test('the delivered files are kept as they came, out of the app', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, isNot(contains('assets/art/detectives/original')));
      for (final a in DetectiveAvatar.values) {
        for (final e in DetectiveExpression.values) {
          final original = File('assets/art/detectives/original/${a.name}/${e.name}.png');
          expect(original.existsSync(), isTrue, reason: original.path);
          expect(original.readAsBytesSync()[25], 2, reason: '${original.path}: the RGB file as delivered');
        }
      }
    });

    test('a detective made before avatars existed is the boy (as in How to Play)', () {
      for (final e in DetectiveExpression.values) {
        expect(ArtAssets.detective(null, e), ArtAssets.detective(DetectiveAvatar.boy, e));
        expect(ArtAssets.detectiveCrop(null, e), ArtAssets.detectiveCrop(DetectiveAvatar.boy, e));
      }
    });

    test('every medallion is measured on its own file and lies inside the picture', () {
      for (final a in DetectiveAvatar.values) {
        for (final e in DetectiveExpression.values) {
          final bytes = File(ArtAssets.detective(a, e)).readAsBytesSync();
          final header = ByteData.sublistView(bytes, 16, 24);
          final pixels = Size(header.getUint32(0).toDouble(), header.getUint32(4).toDouble());
          final crop = ArtAssets.detectiveCrop(a, e);
          expect(crop.pixels, pixels, reason: '${a.name}/${e.name}: the size it was measured at');
          final circle = Rect.fromCircle(center: crop.centre, radius: crop.radius);
          expect((Offset.zero & pixels).intersect(circle), circle, reason: '${a.name}/${e.name}: inside the picture');
        }
      }
    });

    test('each moment of play has its own expression', () {
      expect({for (final m in DetectiveMoment.values) m.expression}, DetectiveExpression.values.toSet());
      expect(DetectiveMoment.investigate.expression, DetectiveExpression.investigating);
      expect(DetectiveMoment.lookAgain.expression, DetectiveExpression.thinking);
      expect(DetectiveMoment.newFind.expression, DetectiveExpression.surprised);
      expect(DetectiveMoment.missionSolved.expression, DetectiveExpression.happy);
      expect(DetectiveMoment.caseSolved.expression, DetectiveExpression.confident);
    });
  });

  group('the profile', () {
    test('a saved detective without an avatar reads as it was: nothing added, nothing lost', () {
      final old = {'id': 'a1b2c3d4e5f60718', 'origin': 'legacy', 'walletBackfill': 'done', 'detectiveName': 'MinYoung'};
      final p = DetectiveProfile.fromJson(old)!;
      expect(p.avatar, isNull);
      expect(p.detectiveName, 'MinYoung');
      expect(p.toJson(), old, reason: 'written back unchanged: no avatar invented');
    });

    testWidgets('the chosen avatar is saved, shows at once, and is still there after a restart', (t) async {
      await _open(t, const Size(390, 844), done: const []);
      final container = ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first);
      // Older detective (no avatar yet): the boy.
      expect(container.read(detectiveProfileProvider).avatar, isNull);
      expect(medallion(DetectiveAvatar.boy, DetectiveExpression.investigating), findsOneWidget);

      // Chosen in the detective's settings: shown at once, saved.
      await container.read(detectiveProfileProvider.notifier).setAvatar(DetectiveAvatar.girl);
      await wait(t, const Duration(milliseconds: 100));
      expect(medallion(DetectiveAvatar.girl, DetectiveExpression.investigating), findsOneWidget);
      expect(medallion(DetectiveAvatar.boy, DetectiveExpression.investigating), findsNothing);
      final prefs = container.read(sharedPreferencesProvider);
      expect(ProfileStore(prefs).read()!.profile.avatar, DetectiveAvatar.girl);
      final name = ProfileStore(prefs).read()!.profile.detectiveName;

      // The app closed and opened again on the same device.
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(ProviderScope(
        overrides: await testOverridesFor(prefs),
        child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
      ));
      await wait(t, const Duration(milliseconds: 300));
      final again = ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first);
      expect(again.read(detectiveProfileProvider).avatar, DetectiveAvatar.girl);
      expect(again.read(detectiveProfileProvider).detectiveName, name, reason: 'the name is untouched');
      again.read(routerProvider).go(Routes.mission(ep01.missions.first.id));
      await wait(t, const Duration(milliseconds: 1200));
      expect(medallion(DetectiveAvatar.girl, DetectiveExpression.investigating), findsOneWidget);
    });
  });

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    group('in play $tag', () {
      testWidgets('the place: investigating, beside INVESTIGATE, never over it', (t) async {
        await _open(t, size, done: const [], avatar: DetectiveAvatar.girl);
        final detective = medallion(DetectiveAvatar.girl, DetectiveExpression.investigating);
        await reveal(t, find.text('INVESTIGATE'));
        expect(detective, findsOneWidget);
        expect(styleOf(t, detective), DetectiveStyle.portrait, reason: 'by a button: the medallion');
        final button = t.getRect(find.text('INVESTIGATE'));
        final face = t.getRect(detective);
        expect(face.overlaps(button), isFalse);
        expect(face.right, lessThan(button.left));
        expect(face.top >= 0 && face.bottom <= size.height, isTrue, reason: 'whole on screen');
        await _settleArt(t);
        await capture(t, 'detective_investigate_$tag');
        // Still the way in.
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 600));
        expect(find.text('TAP TO OPEN').evaluate().isNotEmpty || find.text('SOLVE THE PUZZLE').evaluate().isNotEmpty, isTrue);
        expect(t.takeException(), isNull);
      });

      testWidgets('the puzzle itself shows no detective; a wrong answer: thinking, the buttons clear', (t) async {
        final m = ep01.missions.first;
        await _open(t, size, done: const [], started: m.id, avatar: DetectiveAvatar.girl);
        expect(find.text('CHECK ANSWER'), findsOneWidget);
        expect(anyMedallion(), findsNothing, reason: 'the puzzle and its answers stay clear');
        final wrong = m.options.firstWhere((o) => o.id != m.answer);
        await tapText(t, wrong.label, after: const Duration(milliseconds: 200));
        await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 900));
        expect(find.text('Not quite!'), findsOneWidget);
        final detective = medallion(DetectiveAvatar.girl, DetectiveExpression.thinking);
        expect(detective, findsOneWidget);
        expect(styleOf(t, detective), DetectiveStyle.portrait);
        final face = t.getRect(detective);
        for (final label in ['Not quite!', 'TRY AGAIN']) {
          expect(face.overlaps(t.getRect(find.text(label))), isFalse, reason: label);
        }
        await _settleArt(t);
        await capture(t, 'detective_look_again_$tag');
        await t.tap(find.text('TRY AGAIN'));
        await wait(t, const Duration(milliseconds: 600));
        expect(find.text('CHECK ANSWER'), findsOneWidget, reason: 'back to the puzzle, as before');
        expect(t.takeException(), isNull);
      });

      testWidgets('Case Closed: confident, pinned to the file, the name and buttons as before', (t) async {
        await _open(t, size, done: [for (final m in ep01.allMissions) m.id], solved: true, avatar: DetectiveAvatar.girl);
        final container = ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first);
        container.read(routerProvider).go(Routes.solved);
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
        await wait(t, const Duration(milliseconds: 3200));
        final detective = medallion(DetectiveAvatar.girl, DetectiveExpression.confident);
        expect(detective, findsOneWidget);
        expect(styleOf(t, detective), DetectiveStyle.illustration, reason: 'the whole picture, hands and glass');
        final face = t.getRect(detective);
        final pixels = ArtAssets.detectiveCrop(DetectiveAvatar.girl, DetectiveExpression.confident).pixels;
        expect(face.width / face.height, closeTo(pixels.aspectRatio, 0.01), reason: 'its own ratio');
        expect(face.left >= 0 && face.right <= size.width, isTrue, reason: 'never cut at the sides');
        for (final label in ['CASE CLOSED', 'MINYOUNG']) {
          expect(face.overlaps(t.getRect(find.text(label))), isFalse, reason: label);
        }
        expect(face.top, greaterThanOrEqualTo(0), reason: 'never cut at the top');
        expect(
          find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Detective MINYOUNG, case solved'),
          findsOneWidget,
          reason: 'read out as the detective who solved it',
        );
        await _settleArt(t);
        await capture(t, 'detective_case_closed_$tag');
        // A new picture chosen: shown at once here too.
        await container.read(detectiveProfileProvider.notifier).setAvatar(DetectiveAvatar.boy);
        await wait(t, const Duration(milliseconds: 100));
        expect(medallion(DetectiveAvatar.boy, DetectiveExpression.confident), findsOneWidget);
        // The way on is unchanged.
        await t.scrollUntilVisible(find.text('OPEN CASE 02'), 300, scrollable: find.byType(Scrollable).first);
        expect(find.text('OPEN CASE 02'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    });

    group('Discovery Moment $tag', () {
      for (final (id, expression) in const [('m03', DetectiveExpression.surprised), ('m02', DetectiveExpression.happy)]) {
        testWidgets('$id (${discoveryOf(ep01.missionById(id)!).type.label}): ${expression.name}, smaller than what was found', (t) async {
          final m = ep01.missionById(id)!;
          await _open(t, size, done: const [], avatar: DetectiveAvatar.girl);
          final context = t.element(find.byType(Scaffold).first);
          final closed = showDiscoveryMoment(
            context,
            mission: m,
            discovery: discoveryOf(m),
            xp: XpBreakdown.of(m, const GameProgress()),
            coins: 10,
            showDetective: true,
          );
          await wait(t, const Duration(milliseconds: 2600));
          final detective = medallion(DetectiveAvatar.girl, expression);
          expect(detective, findsOneWidget);
          expect(styleOf(t, detective), DetectiveStyle.illustration);
          final face = t.getRect(detective);
          final pixels = ArtAssets.detectiveCrop(DetectiveAvatar.girl, expression).pixels;
          expect(face.width / face.height, closeTo(pixels.aspectRatio, 0.01), reason: 'its own ratio');
          expect(face.top >= 0 && face.left >= 0 && face.right <= size.width, isTrue, reason: 'whole on screen');
          final evidence = find.text('Pocket Watch');
          if (evidence.evaluate().isNotEmpty) {
            expect(face.overlaps(t.getRect(evidence)), isFalse, reason: 'the evidence card is clear');
          }
          final title = t.getRect(find.text(discoveryOf(m).title));
          final cheer = t.getRect(find.text(discoveryOf(m).type.cheer));
          expect(face.bottom, lessThanOrEqualTo(cheer.top), reason: 'it greets first, above the cheer');
          expect(face.width, lessThan(title.width), reason: 'what was found leads');
          expect(find.textContaining('+'), findsWidgets, reason: 'the reward, as before');
          await _settleArt(t);
          await capture(t, 'detective_discovery_${id}_$tag');
          await tapText(t, continueInvestigation, after: const Duration(milliseconds: 500));
          await closed;
          expect(t.takeException(), isNull);
        });
      }
    });
  }

  group('large text (1.3×) on 360x640', () {
    testWidgets('a new find: the detective, the find and the button all clear of each other', (t) async {
      final m = ep01.missionById('m03')!;
      await _open(t, const Size(360, 640), done: const [], avatar: DetectiveAvatar.boy, textScale: 1.3);
      final closed = showDiscoveryMoment(
        t.element(find.byType(Scaffold).first),
        mission: m,
        discovery: discoveryOf(m),
        xp: XpBreakdown.of(m, const GameProgress()),
        coins: 10,
        showDetective: true,
      );
      await wait(t, const Duration(milliseconds: 2600));
      final face = t.getRect(medallion(DetectiveAvatar.boy, DetectiveExpression.surprised));
      for (final f in [find.text(discoveryOf(m).type.cheer), find.text('Pocket Watch')]) {
        expect(face.overlaps(t.getRect(f)), isFalse);
      }
      await _settleArt(t);
      await capture(t, 'detective_discovery_m03_360x640_text13');
      await tapText(t, continueInvestigation, after: const Duration(milliseconds: 500));
      await closed;
      expect(t.takeException(), isNull);
    });

    testWidgets('Case Closed: the detective, the title and the name clear, the way on reachable', (t) async {
      await _open(t, const Size(360, 640),
          done: [for (final m in ep01.allMissions) m.id], solved: true, avatar: DetectiveAvatar.boy, textScale: 1.3);
      ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first).read(routerProvider).go(Routes.solved);
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await wait(t, const Duration(milliseconds: 3200));
      final face = t.getRect(medallion(DetectiveAvatar.boy, DetectiveExpression.confident));
      for (final label in ['CASE CLOSED', 'MINYOUNG']) {
        expect(face.overlaps(t.getRect(find.text(label))), isFalse, reason: label);
      }
      await _settleArt(t);
      await capture(t, 'detective_case_closed_360x640_text13');
      await t.scrollUntilVisible(find.text('OPEN CASE 02'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('OPEN CASE 02'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  testWidgets('a picture that cannot be loaded leaves the detective\'s cap, never a broken frame', (t) async {
    for (final style in DetectiveStyle.values) {
      await t.pumpWidget(DefaultAssetBundle(
        bundle: _NoPictures(),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: SizedBox()),
        ),
      ));
      await t.pumpWidget(DefaultAssetBundle(
        bundle: _NoPictures(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: DetectiveCharacter(
              avatar: DetectiveAvatar.girl,
              expression: DetectiveExpression.happy,
              style: style,
              size: 120,
              entrance: false,
            ),
          ),
        ),
      ));
      for (var i = 0; i < 5; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await t.pump();
      }
      expect(t.takeException(), isNull, reason: style.name);
      expect(find.byWidgetPredicate((w) => w is InkIcon && w.glyph == InkGlyph.deerstalker), findsOneWidget, reason: style.name);
    }
  });

  testWidgets('not asked for (showDetective off), the sheet keeps its magnifier', (t) async {
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(),
      child: MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showTryAgainSheet(context, hintAvailable: true),
            child: const Text('go'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('go'));
    await wait(t, const Duration(milliseconds: 600));
    expect(find.text('Not quite!'), findsOneWidget);
    expect(anyMedallion(), findsNothing);
  });

  testWidgets('reduced motion: the detective is simply there, at once', (t) async {
    await t.pumpWidget(const MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: DetectiveCharacter(avatar: DetectiveAvatar.girl, expression: DetectiveExpression.happy),
        ),
      ),
    ));
    final opacity = t.widget<Opacity>(find.ancestor(of: medallion(DetectiveAvatar.girl, DetectiveExpression.happy), matching: find.byType(Opacity)).first);
    expect(opacity.opacity, 1, reason: 'no fade on the first frame');
    expect(t.binding.hasScheduledFrame, isFalse, reason: 'nothing left to animate');
  });

  testWidgets('How to Play: the detective chosen at registration, in the guide and its practice puzzle', (t) async {
    t.view.physicalSize = const Size(390, 844) * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(),
      child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
    ));
    await wait(t, const Duration(milliseconds: 300));
    await tapText(t, 'START ADVENTURE');
    expect(find.text('CHOOSE YOUR DETECTIVE'), findsOneWidget, reason: 'the picture is the detective\'s look');
    await _settleArt(t);
    await capture(t, 'detective_register_390x844');
    await t.tap(find.byKey(const ValueKey('avatar-girl')));
    await t.enterText(find.byType(TextFormField), 'Ada');
    await t.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(t, const Duration(milliseconds: 300));
    await tapText(t, 'START INVESTIGATION', after: const Duration(milliseconds: 900));
    final container = ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first);
    expect(container.read(detectiveProfileProvider).avatar, DetectiveAvatar.girl);
    // The guide's cover: the girl.
    String? assetOf(ImageProvider p) => switch (p) {
          AssetImage(:final assetName) => assetName,
          ResizeImage(:final imageProvider) => assetOf(imageProvider),
          _ => null,
        };
    expect(
      find.byWidgetPredicate((w) => w is Image && assetOf(w.image) == ArtAssets.onboardingWelcome(DetectiveAvatar.girl)),
      findsOneWidget,
    );
    // The practice puzzle (page 4): the same reactions as in the cases.
    for (var i = 0; i < 3; i++) {
      await tapText(t, 'NEXT', after: const Duration(milliseconds: 500));
    }
    expect(find.text('Solve the Mystery'), findsOneWidget);
    await tapText(t, 'In the cold river', after: const Duration(milliseconds: 200));
    await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 500));
    expect(medallion(DetectiveAvatar.girl, DetectiveExpression.thinking), findsOneWidget);
    await tapText(t, 'On the warm roof', after: const Duration(milliseconds: 200));
    await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 500));
    expect(medallion(DetectiveAvatar.girl, DetectiveExpression.happy), findsOneWidget);
    await reveal(t, find.text('Well done!'));
    await _settleArt(t);
    await capture(t, 'detective_practice_390x844');
    expect(t.takeException(), isNull);
  });
}

/// The app at Case 01 (cases before it solved), mission [done] solved and,
/// when [started], that mission open at its puzzle; otherwise the first
/// mission not done, at its place. [avatar]: chosen for the detective.
Future<void> _open(
  WidgetTester t,
  Size size, {
  required List<String> done,
  String? started,
  bool solved = false,
  DetectiveAvatar? avatar,
  double textScale = 1,
}) async {
  t.view.physicalSize = size * 3;
  t.view.devicePixelRatio = 3;
  t.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(t.view.reset);
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  final ep01 = MockEpisodeRepository.bundled().first;
  final start = DateTime(2026, 9, 29, 10);
  await t.pumpWidget(ProviderScope(
    overrides: await testOverrides(prefs: {
      AppConstants.progressKeyFor(ep01.id): jsonEncode(GameProgress(
        detectiveName: 'MINYOUNG',
        introSeen: true,
        completedMissionIds: done,
        missionStartedAt: {?started: start},
        startedAt: start,
        completedAt: solved ? start.add(const Duration(minutes: 30)) : null,
        playMillis: 0,
      ).toJson()),
      AppConstants.seasonStorageKey: jsonEncode(
        SeasonProgress(activeEpisodeId: ep01.id, solvedEpisodeIds: [if (solved) ep01.id]).toJson(),
      ),
    }),
    child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
  ));
  await wait(t, const Duration(milliseconds: 300));
  final container = ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first);
  if (avatar != null) await container.read(detectiveProfileProvider.notifier).setAvatar(avatar);
  if (!solved) {
    final next = started ?? ep01.missions.firstWhere((m) => !done.contains(m.id)).id;
    container.read(routerProvider).go(Routes.mission(next));
    await wait(t, const Duration(milliseconds: 1200));
  }
  // Keep the controller referenced so a test can reach the session's game.
  container.read(gameControllerProvider);
}

/// Lets the pictures on screen load (real image decoding), for screenshots.
Future<void> _settleArt(WidgetTester t) async {
  if (Platform.environment['LM_SCREENSHOTS'] == null) return;
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 800)));
  await wait(t, const Duration(milliseconds: 100));
}

/// The app's assets without the detective pictures (a file missing or
/// broken in a build).
class _NoPictures extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      key.contains('detectives/') ? throw FlutterError('no picture: $key') : rootBundle.load(key);
}
