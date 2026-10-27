import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/difficulty.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/widgets/ink_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';

/// Difficulty PART 2: CHOOSE YOUR LEVEL on CREATE YOUR DETECTIVE — Rookie
/// unless another card is picked, saved with the new detective; never on the
/// detective's settings (see docs/DIFFICULTY_IMPLEMENTATION.md).

Finder card(Difficulty d) => find.byKey(ValueKey('difficulty-${d.storageId}'));

late WidgetRef ref;

Future<SharedPreferences> openRegister(
  WidgetTester t, {
  Size size = const Size(390, 844),
  double scale = 1,
  Map<String, Object> prefs = const {},
}) async {
  t.view.physicalSize = size * 3;
  t.view.devicePixelRatio = 3;
  t.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(t.view.reset);
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  final overrides = await testOverrides(prefs: prefs);
  await t.pumpWidget(ProviderScope(
    overrides: overrides,
    child: RepaintBoundary(
      key: const ValueKey('shot'),
      child: Consumer(builder: (context, r, _) {
        ref = r;
        return const LondonMysteryApp();
      }),
    ),
  ));
  await wait(t, const Duration(milliseconds: 300));
  if (prefs.isEmpty) await tapText(t, 'START ADVENTURE');
  return SharedPreferences.getInstance();
}

/// Whether [d]'s card says it is the chosen one: to a screen reader, and on
/// the page by its tick (not its colour alone).
void expectChosen(WidgetTester t, Difficulty chosen) {
  for (final d in Difficulty.values) {
    final on = d == chosen;
    final node = t.getSemantics(card(d));
    expect(node, isSemantics(isButton: true, isInMutuallyExclusiveGroup: true, hasTapAction: true));
    expect(node.flagsCollection.isSelected, on ? Tristate.isTrue : Tristate.isFalse,
        reason: '${d.label} ${on ? '' : 'not '}selected');
    final tick = find.descendant(
      of: card(d),
      matching: find.byWidgetPredicate((w) => w is InkIcon && w.glyph == InkGlyph.check),
    );
    expect(tick, on ? findsOneWidget : findsNothing, reason: '${d.label} tick');
  }
}

/// With `LM_SCREENSHOTS` set to a folder: the page as it is, to look at.
Future<void> capture(WidgetTester t, String name) async {
  final shots = Platform.environment['LM_SCREENSHOTS'];
  if (shots == null) return;
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400))); // decode the office
  await t.pump();
  await t.runAsync(() async {
    final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
    final image = await boundary.toImage(pixelRatio: 1.5);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$shots/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

Future<void> pick(WidgetTester t, Difficulty d) async {
  await reveal(t, card(d));
  await t.tap(card(d));
  await wait(t, const Duration(milliseconds: 250));
}

Future<void> fillIn(WidgetTester t, {DetectiveAvatar avatar = DetectiveAvatar.girl, String name = 'Anna'}) async {
  await reveal(t, find.byKey(ValueKey('avatar-${avatar.name}')));
  await t.tap(find.byKey(ValueKey('avatar-${avatar.name}')));
  await t.pump();
  await t.enterText(find.byType(TextField), name);
  // The pen is put down (the keyboard closes), as a tap elsewhere does.
  FocusManager.instance.primaryFocus?.unfocus();
  await wait(t, const Duration(milliseconds: 300));
}

void main() {
  setUpAll(() async {
    // The real faces: the cards' lines wrap as on a phone.
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

  testWidgets('CHOOSE YOUR LEVEL: three cards with their lines, Rookie chosen on arrival', (t) async {
    final semantics = t.ensureSemantics();
    await openRegister(t);
    expect(find.text('Create Your Detective'), findsOneWidget);
    expect(find.text('Choose Your Level'), findsOneWidget);
    // Side by side on a phone this wide: each card's line in a few words
    // (the whole line is what a screen reader says, below).
    for (final (label, line) in [
      ('Rookie', 'Short, easy English.'),
      ('Junior', 'Everyday English.'),
      ('Master', 'Advanced English.'),
    ]) {
      expect(find.text(label), findsOneWidget);
      expect(find.text(line), findsOneWidget);
    }
    // Picture, then name, then level, then the button.
    double top(Finder f) => t.getRect(f).top;
    expect(top(find.byKey(const ValueKey('avatar-boy'))), lessThan(top(find.byType(TextField))));
    expect(top(find.byType(TextField)), lessThan(top(card(Difficulty.rookie))));
    // The levels in a row, Rookie first.
    expect(top(card(Difficulty.junior)), top(card(Difficulty.rookie)));
    expect(top(card(Difficulty.master)), top(card(Difficulty.rookie)));
    expect(t.getRect(card(Difficulty.rookie)).right, lessThan(t.getRect(card(Difficulty.junior)).left));
    expect(t.getRect(card(Difficulty.junior)).right, lessThan(t.getRect(card(Difficulty.master)).left));
    // The cards are on the form, which scrolls; the button is not: it stays
    // on screen, under the form.
    final form = find.byType(SingleChildScrollView).first;
    expect(find.descendant(of: form, matching: card(Difficulty.master)), findsOneWidget);
    expect(find.descendant(of: form, matching: find.text('START INVESTIGATION')), findsNothing);
    expect(t.getRect(find.text('START INVESTIGATION')).bottom, lessThan(844), reason: 'the button is on screen on arrival');
    expect(t.getRect(find.text('START INVESTIGATION')).top, greaterThan(t.getRect(form).bottom - 1));
    expectChosen(t, Difficulty.rookie);
    expect(t.getSemantics(card(Difficulty.junior)).label,
        'junior level. Everyday English. Read clues and connect the dots.');
    semantics.dispose();
  });

  testWidgets('a tap anywhere on a card chooses it; the one before is let go', (t) async {
    final semantics = t.ensureSemantics();
    await openRegister(t);
    await pick(t, Difficulty.junior);
    expectChosen(t, Difficulty.junior);
    // The card's far corner, not its word: the whole card is the target.
    await t.tapAt(t.getRect(card(Difficulty.master)).bottomRight - const Offset(4, 4));
    await wait(t, const Duration(milliseconds: 250));
    expectChosen(t, Difficulty.master);
    await pick(t, Difficulty.rookie);
    expectChosen(t, Difficulty.rookie);
    semantics.dispose();
  });

  for (final level in Difficulty.values) {
    testWidgets('created as ${level.label}: saved with the name and picture, kept after a restart', (t) async {
      final prefs = await openRegister(t);
      await fillIn(t, avatar: DetectiveAvatar.boy, name: 'Lee');
      if (level != Difficulty.rookie) await pick(t, level);
      await tapText(t, 'START INVESTIGATION', after: const Duration(milliseconds: 900));
      expect(ref.read(routerProvider).routerDelegate.currentConfiguration.uri.path, Routes.howToPlay);

      final saved = ProfileStore(prefs).profile!;
      expect(saved.difficulty, level);
      expect(saved.detectiveName, 'Lee');
      expect(saved.avatar, DetectiveAvatar.boy);
      expect(jsonDecode(prefs.getString(AppConstants.detectiveStorageKey)!)['profile']['difficulty'], level.storageId);
      expect(prefs.getKeys().where((k) => k.contains('difficulty')), isEmpty, reason: 'no key of its own');

      // The app opened again.
      final again = ProviderContainer(overrides: await testOverridesFor(prefs));
      addTearDown(again.dispose);
      expect(again.read(detectiveProfileProvider).difficulty, level);
      expect(again.read(detectiveProfileProvider).detectiveName, 'Lee');
      expect(again.read(currentDifficultyProvider), level, reason: 'no season fixed yet: the detective\'s');
      await wait(t, const Duration(seconds: 1));
    });
  }

  testWidgets('a level changed before the name is written stays chosen through the keyboard', (t) async {
    final prefs = await openRegister(t);
    await pick(t, Difficulty.junior);
    await fillIn(t);
    expectChosen(t, Difficulty.junior);
    await tapText(t, 'START INVESTIGATION', after: const Duration(milliseconds: 900));
    expect(ProfileStore(prefs).profile!.difficulty, Difficulty.junior);
    expect(ProfileStore(prefs).profile!.avatar, DetectiveAvatar.girl);
    await wait(t, const Duration(seconds: 1));
  });

  // PART 2 kept the level off the settings; PART 3 puts it there (season
  // policy). A season not begun yet: changed freely, with SAVE CHANGES.
  testWidgets('the detective\'s settings: the level chosen shows, and changes freely before the season begins', (t) async {
    final semantics = t.ensureSemantics();
    final prefs = await openRegister(t);
    await fillIn(t);
    await pick(t, Difficulty.master);
    await tapText(t, 'START INVESTIGATION', after: const Duration(milliseconds: 900));
    ref.read(routerProvider).go(Routes.detective);
    await wait(t, const Duration(milliseconds: 600));
    expect(ref.read(routerProvider).routerDelegate.currentConfiguration.uri.path, Routes.detective);
    expect(find.text('Choose Your Level'), findsOneWidget);
    expectChosen(t, Difficulty.master);
    await pick(t, Difficulty.junior);
    expect(find.byKey(const ValueKey('restart-season-dialog')), findsNothing, reason: 'nothing begun: nothing to ask');
    expectChosen(t, Difficulty.junior);
    expect(ProfileStore(prefs).profile!.difficulty, Difficulty.master, reason: 'saved with SAVE CHANGES');
    await tapText(t, 'SAVE CHANGES', after: const Duration(milliseconds: 900));
    expect(ProfileStore(prefs).profile!.difficulty, Difficulty.junior);
    semantics.dispose();
    await wait(t, const Duration(seconds: 3));
  });

  for (final (size, scale) in [
    (const Size(360, 640), 1.0),
    (const Size(360, 640), 1.3),
    (const Size(390, 844), 1.0),
    (const Size(390, 844), 1.3),
    (const Size(430, 932), 1.0),
    (const Size(800, 1280), 1.0), // a tablet
  ]) {
    testWidgets('${size.width.toInt()}×${size.height.toInt()} ×$scale: no overflow, lines whole, cards tall enough, button reachable', (t) async {
      final prefs = await openRegister(t, size: size, scale: scale);
      expect(t.takeException(), isNull);
      final shotName = 'register_${size.width.toInt()}x${size.height.toInt()}_x$scale';
      await capture(t, shotName);
      for (final d in Difficulty.values) {
        final box = t.getRect(card(d));
        expect(box.height, greaterThanOrEqualTo(44), reason: '${d.label} touch target');
        expect(box.left, greaterThanOrEqualTo(0));
        expect(box.right, lessThanOrEqualTo(size.width));
        // Side by side, the line in a few words; under one another (too
        // narrow for three), the whole line.
        final shown = find.text(d.tagline).evaluate().isNotEmpty ? d.tagline : d.blurb;
        final line = t.renderObject<RenderParagraph>(find.text(shown));
        expect(line.didExceedMaxLines, isFalse, reason: '${d.label} line not cut');
        expect(line.size.width, lessThanOrEqualTo(box.width), reason: '${d.label} line inside its card');
      }
      // Both pictures stay whole beside each other.
      final boy = t.getRect(find.byKey(const ValueKey('avatar-boy')));
      final girl = t.getRect(find.byKey(const ValueKey('avatar-girl')));
      expect(boy.right, lessThanOrEqualTo(girl.left));
      expect(boy.height, greaterThanOrEqualTo(44));

      await pick(t, Difficulty.master);
      await fillIn(t);
      await reveal(t, find.text('START INVESTIGATION'));
      await capture(t, '${shotName}_master');
      expect(find.text('START INVESTIGATION').hitTestable(), findsOneWidget, reason: 'the button can be tapped');
      await tapText(t, 'START INVESTIGATION', after: const Duration(milliseconds: 900));
      expect(t.takeException(), isNull);
      expect(ProfileStore(prefs).profile!.difficulty, Difficulty.master);
      await wait(t, const Duration(seconds: 1));
    });
  }

  testWidgets('360×640, keyboard up: the level folds away, the line and the button stay above the keys; the choice is kept', (t) async {
    final prefs = await openRegister(t, size: const Size(360, 640));
    await pick(t, Difficulty.junior);
    await reveal(t, find.byType(TextField));
    await t.tap(find.byType(TextField));
    await t.pump();
    t.view.viewInsets = const FakeViewPadding(bottom: 900); // ~300 dp of keys
    addTearDown(t.view.resetViewInsets);
    await wait(t, const Duration(milliseconds: 600));
    expect(t.takeException(), isNull, reason: 'no overflow above the keyboard');
    expect(find.text('Choose Your Level'), findsNothing);
    for (final f in [find.byType(TextField), find.text('START INVESTIGATION')]) {
      final r = t.getRect(f);
      expect(r.top, greaterThanOrEqualTo(0), reason: '$f is not pushed off the top');
      expect(r.bottom, lessThanOrEqualTo(640 - 300), reason: '$f sits above the keyboard');
    }
    await t.enterText(find.byType(TextField), 'Ben');
    await t.tap(find.byKey(const ValueKey('avatar-boy')));
    await t.pump();
    // Keyboard down: the level is back, still Junior.
    t.view.resetViewInsets();
    await wait(t, const Duration(milliseconds: 600));
    expect(find.text('Choose Your Level'), findsOneWidget);
    expectChosen(t, Difficulty.junior);
    await tapText(t, 'START INVESTIGATION', after: const Duration(milliseconds: 900));
    expect(ProfileStore(prefs).profile!.difficulty, Difficulty.junior);
    expect(ProfileStore(prefs).profile!.detectiveName, 'Ben');
    await wait(t, const Duration(seconds: 1));
  });

  testWidgets('a detective saved before difficulty: opened as before, read as Rookie, its record not rewritten', (t) async {
    const id = 'abcdef0123456789abcdef0123456789';
    final record = jsonEncode({
      'schema': 1,
      'profile': {'id': id, 'origin': 'fresh', 'walletBackfill': 'never', 'detectiveName': 'KIM', 'avatar': 'girl'},
    });
    final prefs = await openRegister(t, prefs: {
      AppConstants.detectiveStorageKey: record,
      // Its first case save, with the name in it (as every detective's).
      AppConstants.profileKey(id, AppConstants.progressStorageKey):
          jsonEncode(const GameProgress(detectiveName: 'KIM').toJson()),
    });
    expect(find.text('Choose Your Level'), findsNothing, reason: 'no new detective to create');
    expect(ref.read(detectiveProfileProvider).difficulty, Difficulty.rookie);
    expect(ref.read(detectiveProfileProvider).detectiveName, 'KIM');
    expect(prefs.getString(AppConstants.detectiveStorageKey), record);
    // The form is not offered again: /register goes back to the start.
    ref.read(routerProvider).go(Routes.register);
    await wait(t, const Duration(milliseconds: 600));
    expect(ref.read(routerProvider).routerDelegate.currentConfiguration.uri.path, Routes.start);
    await wait(t, const Duration(seconds: 1));
  });
}
