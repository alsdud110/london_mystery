import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/models/detective_name.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/data/repositories/profile_store.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/game/scoring.dart';
import 'package:world_mystery/features/game/wallet_controller.dart';
import 'package:world_mystery/features/game_master/playtest_tools.dart';
import 'package:world_mystery/features/onboarding/how_to_play_state.dart';
import 'package:world_mystery/widgets/art_assets.dart';

import 'full_playthrough_test.dart' show tapText, wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// The detective's name kept exactly as typed, the guide's pictures of the
/// chosen detective (boy or girl), and the guide speaking to the detective
/// by name.
void main() {
  group('the name, as typed', () {
    for (final name in ['Lee', 'MIN', 'alex', 'McDonald', 'SeoYoung', 'Mary-Jo', '민영']) {
      test('$name is saved and shown as $name, also after a restart', () async {
        final c = ProviderContainer(overrides: await testOverrides());
        final prefs = c.read(sharedPreferencesProvider);
        expect(c.read(gameControllerProvider.notifier).createDetective('  $name ', DetectiveAvatar.boy), isNull);
        await Future<void>.delayed(Duration.zero);
        expect(c.read(gameControllerProvider).detectiveName, name);
        expect(ProfileStore(prefs).profile!.detectiveName, name);
        expect(jsonDecode(savedString(prefs, AppConstants.progressStorageKey)!)['detectiveName'], name);
        c.dispose();

        final again = ProviderContainer(overrides: await testOverridesFor(prefs));
        addTearDown(again.dispose);
        expect(again.read(gameControllerProvider).detectiveName, name);
        expect(again.read(detectiveProfileProvider).detectiveName, name);
      });
    }

    test('a name saved in capitals before is kept; changed to Lee it is Lee everywhere, progress kept', () async {
      final c = ProviderContainer(overrides: await testOverrides(prefs: {
        AppConstants.progressStorageKey: jsonEncode(GameProgress(
          detectiveName: 'LEE',
          introSeen: true,
          completedMissionIds: [for (final m in episode01.allMissions) m.id],
          badgeIds: const ['firstClue'],
          completedAt: DateTime(2026, 9, 2),
        ).toJson()),
        AppConstants.progressKeyFor('ep02'): jsonEncode(const GameProgress(detectiveName: 'LEE', introSeen: true).toJson()),
        AppConstants.seasonStorageKey: jsonEncode({'activeEpisodeId': 'ep02', 'solvedEpisodeIds': ['ep01']}),
      }));
      addTearDown(c.dispose);
      expect(c.read(gameControllerProvider).detectiveName, 'LEE', reason: 'never changed by itself');
      expect(c.read(profileStoreProvider).profile!.detectiveName, 'LEE');
      final repo = c.read(progressRepositoryProvider);
      final xp = XpBreakdown.totalFor(episode01, repo.load('ep01'));
      final coins = c.read(walletProvider).balance;

      expect(GameController.validateName('Lee'), isNull);
      expect(c.read(gameControllerProvider.notifier).renameDetective('Lee'), isNull, reason: 'LEE → Lee is a change');
      await Future<void>.delayed(Duration.zero);
      expect(c.read(gameControllerProvider).detectiveName, 'Lee');
      expect(repo.load('ep01').detectiveName, 'Lee');
      expect(c.read(profileStoreProvider).profile!.detectiveName, 'Lee');
      expect(XpBreakdown.totalFor(episode01, repo.load('ep01')), xp);
      expect(repo.load('ep01').badgeIds, ['firstClue']);
      expect(c.read(walletProvider).balance, coins);
      expect(c.read(seasonProvider).solvedEpisodeIds, ['ep01']);
    });

    test('the name field types as written: no capitals forced', () {
      final source = File('lib/features/onboarding/detective_form.dart').readAsStringSync();
      expect(source, isNot(contains('TextCapitalization.characters')));
      final controller = File('lib/features/game/game_controller.dart').readAsStringSync();
      expect(RegExp(r'cleanName\(String raw\) => [^;]*toUpperCase').hasMatch(controller), isFalse);
    });
  });

  test('no partner anywhere the player reads: the detective is the player', () {
    // String literals only (comments and code names are not on screen).
    final literal = RegExp(r"'(?:[^'\\\n]|\\.)*'|\x22(?:[^\x22\\\n]|\\.)*\x22");
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      for (final m in literal.allMatches(f.readAsStringSync())) {
        expect(m.group(0)!.toLowerCase(), isNot(contains('partner')), reason: '${f.path}: ${m.group(0)}');
      }
    }
  });

  group('the name in a line', () {
    test('filled in as saved; without a name the line still reads well', () {
      const line = 'Hello, Detective ${DetectiveName.placeholder}!';
      expect(DetectiveName.address(line, 'Lee'), 'Hello, Detective Lee!');
      expect(DetectiveName.address(line, 'alex'), 'Hello, Detective alex!');
      expect(DetectiveName.address(line, 'Mary-Jo'), r'Hello, Detective Mary-Jo!');
      expect(DetectiveName.address(line, null), 'Hello, Detective!');
      expect(DetectiveName.address(line, '  '), 'Hello, Detective!');
      for (final n in [null, '', 'Lee']) {
        final out = DetectiveName.address(line, n);
        expect(out, isNot(contains('{')), reason: '$n');
        expect(out, isNot(contains('null')), reason: '$n');
      }
    });
  });

  group('the guide\'s pictures', () {
    test('boy and girl, welcome and ready (a detective made before avatars: the boy)', () {
      expect(ArtAssets.onboardingWelcome(DetectiveAvatar.boy), 'assets/shared/onboarding/detective_welcome_boy.png');
      expect(ArtAssets.onboardingWelcome(DetectiveAvatar.girl), 'assets/shared/onboarding/detective_welcome_girl.png');
      expect(ArtAssets.onboardingReady(DetectiveAvatar.boy), 'assets/shared/onboarding/detective_ready_boy.png');
      expect(ArtAssets.onboardingReady(DetectiveAvatar.girl), 'assets/shared/onboarding/detective_ready_girl.png');
      expect(ArtAssets.onboardingWelcome(null), ArtAssets.onboardingWelcome(DetectiveAvatar.boy));
      expect(ArtAssets.onboardingReady(null), ArtAssets.onboardingReady(DetectiveAvatar.boy));
    });

    test('all four are in the app, decode, 2:3 at the same size, with a transparent background', () async {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('- assets/shared/onboarding/'));
      for (final a in DetectiveAvatar.values) {
        for (final path in [ArtAssets.onboardingWelcome(a), ArtAssets.onboardingReady(a)]) {
          final bytes = File(path).readAsBytesSync();
          final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
          final image = (await codec.getNextFrame()).image;
          expect(Size(image.width.toDouble(), image.height.toDouble()), ArtAssets.onboardingDetectivePixels, reason: path);
          final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
          int alphaAt(int x, int y) => rgba.getUint8((y * image.width + x) * 4 + 3);
          final w = image.width - 1, h = image.height - 1;
          for (final (x, y) in [(0, 0), (w, 0), (0, h), (w, h)]) {
            expect(alphaAt(x, y), lessThan(255), reason: '$path: a transparent corner ($x, $y)');
          }
          image.dispose();
        }
      }
    });
  });

  group('the guide speaks to the detective', () {
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

    late WidgetRef ref;

    Future<void> openGuide(WidgetTester t, {Size size = const Size(390, 844), double scale = 1}) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(),
        child: RepaintBoundary(
          key: const ValueKey('shot'),
          child: Consumer(builder: (context, r, _) {
            ref = r;
            return const WorldMysteryApp();
          }),
        ),
      ));
      await wait(t, const Duration(milliseconds: 300));
    }

    Future<void> create(WidgetTester t, String name, DetectiveAvatar avatar) async {
      await tapText(t, 'START ADVENTURE');
      await t.tap(find.byKey(ValueKey('avatar-${avatar.name}')));
      await t.pump();
      await t.enterText(find.byType(TextField), name);
      await tapText(t, 'START INVESTIGATION', after: const Duration(milliseconds: 900));
    }

    Future<void> next(WidgetTester t) async {
      await t.tap(find.text('NEXT').hitTestable());
      await wait(t, const Duration(milliseconds: 450));
    }

    String? assetOf(Image i) => switch (i.image) {
          final AssetImage a => a.assetName,
          final ResizeImage r when r.imageProvider is AssetImage => (r.imageProvider as AssetImage).assetName,
          _ => null,
        };

    Finder pictureOf(String asset) => find.byWidgetPredicate((w) => w is Image && assetOf(w) == asset);

    for (final (name, avatar) in [('Lee', DetectiveAvatar.boy), ('Anna', DetectiveAvatar.girl), ('McDonald', DetectiveAvatar.boy)]) {
      testWidgets('${avatar.label} / $name: their picture, their name, from welcome to ready', (t) async {
        final semantics = t.ensureSemantics();
        await openGuide(t);
        await create(t, name, avatar);
        expect(ref.read(routerProvider).routerDelegate.currentConfiguration.uri.path, Routes.howToPlay);

        // 1. Welcome: the greeting by name, the chosen detective.
        expect(find.text('Hello, Detective $name!'), findsOneWidget);
        expect(pictureOf(ArtAssets.onboardingWelcome(avatar)), findsOneWidget);
        final other = avatar == DetectiveAvatar.boy ? DetectiveAvatar.girl : DetectiveAvatar.boy;
        expect(pictureOf(ArtAssets.onboardingWelcome(other)), findsNothing);
        // The detective in the picture is the player, not a partner.
        expect(find.text("Your first mystery awaits. Let's find clues and solve mysteries in London!"), findsOneWidget);
        expect(find.textContaining('partner'), findsNothing);
        expect(find.bySemanticsLabel('Detective $name'), findsOneWidget);

        // 2. The letter is written to them.
        await next(t);
        await t.tap(find.text('TAP TO OPEN'));
        await wait(t, const Duration(milliseconds: 1400));
        expect(findReadableContaining('Dear Detective $name,'), findsOneWidget);
        expect(findReadableContaining('My little cat, Pip, is lost!'), findsOneWidget, reason: 'the story is the same');

        // 3. Mrs Moss greets them by name; her answers are as before.
        await next(t);
        expect(find.text('"Hello, Detective $name! I sell tea here every day. Ask me anything!"'), findsOneWidget);
        await t.tap(find.text('Did you see a cat?'));
        await wait(t, const Duration(milliseconds: 400));
        expect(find.text('"Yes! A little cat with a red collar ran past my stall."'), findsOneWidget);

        // Through the practice pages to the last one: the same detective, setting off.
        for (var i = 0; i < 5; i++) {
          await next(t);
        }
        expect(find.text('Your First Case Awaits!'), findsOneWidget);
        expect(pictureOf(ArtAssets.onboardingReady(avatar)), findsOneWidget);
        expect(pictureOf(ArtAssets.onboardingReady(other)), findsNothing);
        expect(find.bySemanticsLabel('Detective $name'), findsOneWidget, reason: 'the same detective, setting off');
        expect(find.text('Hints are here whenever you need them.'), findsOneWidget);
        expect(find.textContaining("I'll be right here"), findsNothing);
        expect(find.textContaining('{detectiveName}'), findsNothing);
        expect(t.takeException(), isNull);
        semantics.dispose();
      });
    }

    testWidgets('the practice hints: no partner, the free hint said plainly', (t) async {
      await openGuide(t);
      await create(t, 'Lee', DetectiveAvatar.boy);
      await next(t);
      await t.tap(find.text('TAP TO OPEN'));
      await wait(t, const Duration(milliseconds: 1400));
      for (var i = 0; i < 4; i++) {
        await next(t);
      }
      expect(find.text('Hints When You Need Them'), findsOneWidget);
      expect(find.text('Not enough coins? You can still get a free hint!'), findsOneWidget);
      expect(find.textContaining('partner'), findsNothing);
    });

    testWidgets('a new picture in My detective: the guide shows it the next time', (t) async {
      await openGuide(t);
      await create(t, 'Lee', DetectiveAvatar.boy);
      expect(pictureOf(ArtAssets.onboardingWelcome(DetectiveAvatar.boy)), findsOneWidget);
      await ref.read(detectiveProfileProvider.notifier).setAvatar(DetectiveAvatar.girl);
      ref.read(routerProvider).go(Routes.howToPlayAgain);
      await wait(t, const Duration(milliseconds: 600));
      expect(pictureOf(ArtAssets.onboardingWelcome(DetectiveAvatar.girl)), findsOneWidget);
      expect(find.text('Hello, Detective Lee!'), findsOneWidget);
    });

    testWidgets('NEW ADVENTURE: the guide still knows the detective', (t) async {
      await openGuide(t);
      await create(t, 'Anna', DetectiveAvatar.girl);
      await ref.read(gameControllerProvider.notifier).newAdventure();
      ref.read(routerProvider).go(Routes.howToPlayAgain);
      await wait(t, const Duration(milliseconds: 600));
      expect(find.text('Hello, Detective Anna!'), findsOneWidget);
      expect(pictureOf(ArtAssets.onboardingWelcome(DetectiveAvatar.girl)), findsOneWidget);
    });

    testWidgets('the game master\'s next player: the new detective\'s name and picture', (t) async {
      await openGuide(t);
      await create(t, 'Anna', DetectiveAvatar.girl);
      await ref.read(gameControllerProvider.notifier).resetAll();
      expect(ref.read(gameControllerProvider).hasDetective, isFalse);
      ref.read(routerProvider).go(Routes.start);
      await wait(t, const Duration(milliseconds: 1200));
      await create(t, 'Leo', DetectiveAvatar.boy);
      expect(find.text('Hello, Detective Leo!'), findsOneWidget, reason: 'How to Play again (already seen: this opens it)');
    }, skip: false);

    testWidgets('the next player (game master reset): a new detective sees How to Play from page one', (t) async {
      await openGuide(t);
      await create(t, 'Anna', DetectiveAvatar.girl);
      await tapText(t, 'SKIP', after: const Duration(milliseconds: 1500));
      expect(ref.read(howToPlaySeenProvider), isTrue);

      // NEW ADVENTURE keeps the detective, who has learnt how to play.
      ref.read(routerProvider).go(Routes.start);
      await wait(t, const Duration(milliseconds: 1200));
      await tapText(t, 'NEW ADVENTURE');
      await tapText(t, 'START NEW ADVENTURE', after: const Duration(milliseconds: 1500));
      expect(ref.read(routerProvider).routerDelegate.currentConfiguration.uri.path, Routes.season);

      // The game master's reset: the next child starts at the very beginning.
      final complete = await t.runAsync(() => resetForNextPlayer(ref));
      expect(complete, isTrue);
      expect(ref.read(gameControllerProvider).hasDetective, isFalse);
      expect(ref.read(howToPlaySeenProvider), isFalse);
      final prefs = ref.read(sharedPreferencesProvider);
      expect(prefs.getKeys().where((k) => k.startsWith('lm.onboarding.v1.')), isEmpty);
      ref.read(routerProvider).go(Routes.start);
      await wait(t, const Duration(milliseconds: 1200));
      await create(t, 'Leo', DetectiveAvatar.boy);
      expect(ref.read(routerProvider).routerDelegate.currentConfiguration.uri.path, Routes.howToPlay);
      expect(find.text('Hello, Detective Leo!'), findsOneWidget);
      expect(find.bySemanticsLabel('Page 1 of 8'), findsWidgets);
      await wait(t, const Duration(seconds: 3));
    });

    for (final (size, scale) in const [(Size(320, 568), 1.0), (Size(360, 640), 1.0), (Size(360, 640), 1.3), (Size(320, 568), 1.3)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}${scale == 1 ? '' : '_text13'}';
      testWidgets('$tag: a long name — greeting, detective and NEXT all whole on screen', (t) async {
        await openGuide(t, size: size, scale: scale);
        await create(t, 'Alexandra-Jo', DetectiveAvatar.girl);
        final greeting = find.text('Hello, Detective Alexandra-Jo!');
        expect(greeting, findsOneWidget);
        expect(t.takeException(), isNull, reason: 'nothing overflows');
        final g = t.getRect(greeting);
        expect(g.left >= 0 && g.right <= size.width && g.top >= 0 && g.bottom <= size.height, isTrue, reason: '$g');
        final picture = t.getRect(pictureOf(ArtAssets.onboardingWelcome(DetectiveAvatar.girl)));
        expect(picture.height, greaterThan(40), reason: 'the detective stays in the picture');
        // The card is laid a little in front of the detective (by design);
        // most of the detective shows above it, never hidden by the words.
        expect(g.top - picture.top, greaterThan(picture.height * 0.6), reason: 'the detective shows above the card');
        expect(picture.top, greaterThanOrEqualTo(0));
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400))); // decode the picture
        await t.pump();
        await capture(t, 'onboarding_welcome_long_name_$tag');
        final nextButton = t.getRect(find.text('NEXT'));
        expect(nextButton.bottom, lessThanOrEqualTo(size.height), reason: 'the way on');
        await next(t);
        await t.tap(find.text('TAP TO OPEN'));
        await wait(t, const Duration(milliseconds: 1400));
        await next(t);
        expect(find.text('"Hello, Detective Alexandra-Jo! I sell tea here every day. Ask me anything!"'), findsOneWidget);
        await capture(t, 'onboarding_witness_long_name_$tag');
        // Her questions are reachable (the page scrolls on the smallest
        // phones with large text) and answer as before.
        await tapText(t, 'Where did she go?', after: const Duration(milliseconds: 400));
        expect(find.text('"She jumped up to the roof, next to the warm chimney."'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  });
}
