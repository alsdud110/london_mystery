import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/mock/season1/season1_mock.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/season/season_overview.dart';

import 'full_playthrough_test.dart' show tapText, wait;
import 'helpers.dart';

/// The season above its cases: the casebook, the investigation board, how
/// it is reached and left, and that it never tells more than the story.
/// Set LM_SCREENSHOTS to a folder to save a picture of each state.
void main() {
  final catalog = MockEpisodeRepository.bundled();
  final info = Season.fromJson(season1InfoJson);
  final ids = [for (final e in catalog) e.id];
  final shots = Platform.environment['LM_SCREENSHOTS'];

  setUpAll(() async {
    // Real fonts, so text sizes (and any overflow) match the device.
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

  // ── The season as numbers (no widgets) ─────────────────────────────────

  GameProgress solvedSave(String id) => GameProgress(
        detectiveName: 'KIM',
        introSeen: true,
        completedMissionIds: [for (final m in catalog.firstWhere((e) => e.id == id).allMissions) m.id],
        completedAt: DateTime(2026, 9, 29, 10, 30),
      );

  SeasonOverview overview(List<String> solved, {String? active, Map<String, GameProgress> saves = const {}, bool operator = false}) =>
      SeasonOverview.of(
        info: info,
        catalog: catalog,
        season: SeasonProgress(activeEpisodeId: active ?? 'ep01', solvedEpisodeIds: solved),
        operator: operator,
        progressOf: (id) => saves[id] ?? (solved.contains(id) ? solvedSave(id) : const GameProgress(detectiveName: 'KIM')),
      );

  group('season overview', () {
    test('a new season: 0 of 12, Case 01 to begin, nothing known yet', () {
      final o = overview(const []);
      expect(o.total, 12);
      expect(o.solvedCount, 0);
      expect(o.currentCase!.id, 'ep01');
      expect(o.currentStarted, isFalse);
      expect(o.begun, isFalse);
      expect(o.figure, isNull);
      expect(o.marks.first, CaseMark.current);
      expect(o.marks.skip(1), everyElement(CaseMark.sealed));
      expect(o.threads, isEmpty);
      expect(o.complete, isFalse);
    });

    test('Case 01 begun: the season has begun', () {
      final o = overview(const [], saves: {'ep01': const GameProgress(detectiveName: 'KIM', introSeen: true)});
      expect(o.begun, isTrue);
      expect(o.currentStarted, isTrue);
    });

    test('midway: 4 of 12, Case 05 next, the trail and its lead', () {
      final o = overview(ids.take(4).toList(), active: 'ep04');
      expect(o.solvedCount, 4);
      expect(o.currentCase!.id, 'ep05');
      expect(o.currentCase!.title, 'The Locked Room', reason: 'titles come from the catalog');
      expect(o.marks.take(4), everyElement(CaseMark.solved));
      expect(o.marks[4], CaseMark.current);
      expect(o.marks.skip(5), everyElement(CaseMark.sealed));
      expect(
        {for (final th in o.threads) th.id},
        {'chain:0-1', 'chain:1-2', 'chain:2-3', 'lead:3-4', 'spoke:0-x', 'spoke:1-x', 'spoke:2-x', 'spoke:3-x'},
      );
    });

    test('every case solved: 12 of 12, no current case, the ring is closed', () {
      final o = overview(ids, active: 'ep12');
      expect(o.complete, isTrue);
      expect(o.solvedCount, 12);
      expect(o.current, isNull);
      expect(o.threads.map((th) => th.id), contains('chain:11-0'));
    });

    test('spoilers: who is behind it is named only after the case that names it', () {
      final expected = <int, String?>{
        0: null, 1: null, // Case 01: the Shadow's crown, no ravens yet
        2: 'ravens', 3: 'ravens', // Case 02 hook: "Who are the ravens?"
        4: 'ravenSociety', // Case 04 final: RAVEN
        for (var k = 5; k < 12; k++) k: 'clockmaker', // Case 05 hook names him
        12: 'clockmakerWatch', // Case 12: he is gone, his watch is left
      };
      for (final MapEntry(key: k, value: figure) in expected.entries) {
        final o = overview(ids.take(k).toList());
        expect(o.figure?.figure, figure, reason: '$k cases solved');
      }
      // Never on the board at all, at any point.
      final p = info.prologue;
      final said = [
        info.title, info.tagline, p.city, ...p.cases, ...p.separate, p.question, p.bigger, ...p.promise, p.firstCaseLine,
        ...info.outro, for (final f in info.figures) f.label,
      ].join(' ').toLowerCase();
      for (final secret in ['paris', 'grey', 'rose', 'robin', 'the shadow', 'inspector']) {
        expect(said, isNot(contains(secret)), reason: '"$secret" belongs to the cases, not the season board');
      }
    });

    test('replaying a solved case keeps the season; the case under way is the current one', () {
      // Case 03 played again (Play again), its intro seen again, not solved yet.
      final o = overview(ids.take(4).toList(), active: 'ep03', saves: {
        'ep03': const GameProgress(detectiveName: 'KIM', introSeen: true),
      });
      expect(o.solvedCount, 4, reason: 'solved stays solved');
      expect(o.currentCase!.id, 'ep03');
      // Play again just pressed (intro not seen yet): the season goes on with Case 05.
      final o2 = overview(ids.take(4).toList(), active: 'ep03', saves: {'ep03': const GameProgress(detectiveName: 'KIM')});
      expect(o2.currentCase!.id, 'ep05');
    });

    test('operator access opens every file but solves nothing and reveals nothing', () {
      final o = overview(const [], operator: true);
      expect(o.solvedCount, 0);
      expect(o.figure, isNull);
      expect(o.currentCase!.id, 'ep01');
      expect(o.marks.skip(1), everyElement(CaseMark.open));
    });

    test('a moment before a case was solved: what the board plays as new', () {
      final now = overview(ids.take(5).toList(), active: 'ep05');
      final before = SeasonOverview.before(
        now,
        SeasonProgress(activeEpisodeId: 'ep05', solvedEpisodeIds: ids.take(5).toList()),
        const ['ep05'],
        operator: false,
        progressOf: solvedSave,
      );
      expect(before.solvedCount, 4);
      expect(before.marks[4], CaseMark.current);
      expect(before.marks[5], CaseMark.sealed);
      expect(before.figure!.figure, 'ravenSociety');
      expect(now.figure!.figure, 'clockmaker');
      final added = {for (final th in now.threads) th.id}.difference({for (final th in before.threads) th.id});
      expect(added, {'chain:3-4', 'lead:4-5', 'spoke:4-x'});
    });
  });

  // ── On screen ──────────────────────────────────────────────────────────

  /// First [solved] cases solved; the case after them (if any) not begun.
  Map<String, Object> seasonSaves(int solved, {String? active, bool activeBegun = false}) {
    final act = active ?? ids[(solved == 0 ? 0 : solved - 1)];
    return {
      AppConstants.progressStorageKey: jsonEncode(GameProgress(
        detectiveName: 'MINYOUNG',
        introSeen: solved > 0 || (act == 'ep01' && activeBegun),
        completedMissionIds: solved > 0 ? [for (final m in catalog.first.allMissions) m.id] : const [],
        startedAt: solved > 0 ? DateTime(2026, 9, 29, 10) : null,
        completedAt: solved > 0 ? DateTime(2026, 9, 29, 10, 30) : null,
        playMillis: solved > 0 ? 0 : null,
      ).toJson()),
      for (final id in ids.skip(1).take(solved > 0 ? solved - 1 : 0))
        AppConstants.progressKeyFor(id): jsonEncode(GameProgress(
          detectiveName: 'MINYOUNG',
          introSeen: true,
          completedMissionIds: [for (final m in catalog.firstWhere((e) => e.id == id).allMissions) m.id],
          startedAt: DateTime(2026, 9, 29, 10),
          completedAt: DateTime(2026, 9, 29, 10, 30),
          playMillis: 0,
        ).toJson()),
      if (activeBegun && act != 'ep01')
        AppConstants.progressKeyFor(act): jsonEncode(GameProgress(
          detectiveName: 'MINYOUNG',
          introSeen: true,
          startedAt: DateTime(2026, 9, 29, 11),
          playMillis: 0,
        ).toJson()),
      AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: act, solvedEpisodeIds: ids.take(solved).toList()).toJson()),
    };
  }

  late WidgetRef appRef;
  String path() => appRef.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

  Future<void> pumpApp(WidgetTester t, Map<String, Object> prefs, {Size size = const Size(360, 640), double textScale = 1}) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    t.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(prefs: prefs),
      child: RepaintBoundary(
        key: const ValueKey('shot'),
        child: Consumer(builder: (context, ref, _) {
          appRef = ref;
          return const LondonMysteryApp();
        }),
      ),
    ));
    await wait(t, const Duration(milliseconds: 300));
  }

  Future<void> capture(WidgetTester t, String name) async {
    if (shots == null) return;
    // Let the pictures (the large map) finish decoding before the picture is taken.
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
    await t.pump();
    await t.runAsync(() async {
      final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
      final image = await boundary.toImage(pixelRatio: 1.5);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<void> openSeason(WidgetTester t, {Size size = const Size(360, 640)}) async {
    appRef.read(routerProvider).go(Routes.season);
    await wait(t, const Duration(milliseconds: 600));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300))); // decode the pictures
    await wait(t, const Duration(milliseconds: 2400));
    expect(path(), Routes.season);
  }

  /// Every text on screen, lower case.
  String screenText(WidgetTester t) => [
        for (final w in t.widgetList<Text>(find.byType(Text))) (w.data ?? w.textSpan?.toPlainText() ?? '').toLowerCase(),
      ].join(' | ');

  /// The CTA (and everything else that matters) is on screen, not pushed off it.
  void expectOnScreen(WidgetTester t, Finder f, Size size) {
    final r = t.getRect(f);
    expect(r.top, greaterThanOrEqualTo(0), reason: '$f');
    expect(r.bottom, lessThanOrEqualTo(size.height), reason: '$f is on screen');
    expect(r.left, greaterThanOrEqualTo(0));
    expect(r.right, lessThanOrEqualTo(size.width));
  }

  /// The opening sequence, scene by scene, from the casebook to Case 01's
  /// story: what each scene says, that it fits the screen, and no spoilers.
  Future<void> playOpening(WidgetTester t, Size size, String tag, {bool fromRegister = false}) async {
    if (fromRegister) {
      await tapText(t, 'START ADVENTURE');
      await t.enterText(find.byType(TextField), 'minyoung');
      await tapText(t, 'OPEN THE CASEBOOK', after: const Duration(milliseconds: 600));
    } else {
      appRef.read(routerProvider).go(Routes.season);
    }
    await wait(t, const Duration(milliseconds: 1800));
    expect(path(), Routes.season);
    expect(find.text('SHADOWS\nOVER LONDON'), findsOneWidget);
    expect(find.text('12 CASES • ONE MYSTERY'), findsOneWidget);
    expect(find.text('CASE FILES'), findsNothing, reason: 'not straight to the case files');
    expect(t.takeException(), isNull);
    expectOnScreen(t, find.text('BEGIN SEASON ONE'), size);
    await capture(t, 'cover_$tag');

    await tapText(t, 'BEGIN SEASON ONE', after: const Duration(milliseconds: 600));
    expect(path(), Routes.prologue);
    expect(appRef.read(gameControllerProvider).introSeen, isFalse, reason: 'the opening starts no case');

    final scenes = <List<String>>[
      ['LONDON', 'Something strange is happening\nacross the city.'],
      ['Treasures have vanished.', 'Secret letters have appeared.', 'Doors have been found locked.', 'And strangers are hiding secrets.'],
      ['They look like separate cases.', 'But a great detective\nlooks closer.'],
      ["What if they're connected?", 'Every clue could be part\nof something bigger.'],
      ['SEASON ONE', 'SHADOWS OVER LONDON', '12 CASES', 'ONE MYSTERY', 'Follow the clues.', 'Find the connection.', 'Discover the truth.'],
    ];
    for (final (i, words) in scenes.indexed) {
      await wait(t, const Duration(milliseconds: 2800));
      expect(t.takeException(), isNull, reason: 'scene ${i + 1} at $tag');
      for (final s in words) {
        expect(find.text(s), findsOneWidget, reason: 'scene ${i + 1}: $s');
        expectOnScreen(t, find.text(s), size); // never cut off
      }
      final text = screenText(t);
      for (final secret in ['raven', 'clockmaker', 'paris', 'grey', 'robin', 'rose', 'the shadow', 'vocabulary', 'reading']) {
        expect(text, isNot(contains(secret)), reason: 'scene ${i + 1} tells the mood, not "$secret"');
      }
      await capture(t, 'opening_${i + 1}_$tag');
      if (i < 4) {
        expectOnScreen(t, find.text('NEXT ›'), size);
        expect(t.getRect(find.text(words.last)).bottom, lessThanOrEqualTo(t.getRect(find.text('NEXT ›')).top + 4),
            reason: 'the words sit above the way on');
        await t.tap(find.text('NEXT ›'));
      }
    }
    expectOnScreen(t, find.text('ACCEPT THE CASE'), size);
    expect(t.getRect(find.text('Discover the truth.')).bottom, lessThanOrEqualTo(t.getRect(find.text('ACCEPT THE CASE')).top),
        reason: 'the button never covers the words');

    // The first case's file: Season → Case.
    await tapText(t, 'ACCEPT THE CASE', after: const Duration(milliseconds: 1800));
    expect(path(), Routes.prologue);
    expect(t.takeException(), isNull);
    for (final s in [
      'CASE 01',
      'THE MISSING CROWN',
      'The Crown has disappeared from the Royal Archive in London!',
      'Your first investigation\nbegins tonight.',
      'ASSIGNED',
    ]) {
      expect(find.text(s), findsOneWidget, reason: s);
      expectOnScreen(t, find.text(s), size);
    }
    expectOnScreen(t, find.text('START CASE 01'), size);
    await capture(t, 'case01_file_$tag');

    await tapText(t, 'START CASE 01', after: const Duration(milliseconds: 800));
    expect(path(), Routes.intro, reason: "Case 01's own story begins, as from the case files");
    expect(appRef.read(currentEpisodeProvider).id, 'ep01');
  }

  testWidgets('a new player: register → cover → the opening (5 scenes) → Case 01 file → Case 01 story, at 360×640', (t) async {
    await pumpApp(t, const {});
    await playOpening(t, const Size(360, 640), '360x640', fromRegister: true);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('the opening at 390×844 and at 360×640 with large text (1.3×)', (t) async {
    for (final (size, scale) in const [(Size(390, 844), 1.0), (Size(360, 640), 1.3)]) {
      await pumpApp(t, {AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'KIM').toJson())},
          size: size, textScale: scale);
      await playOpening(t, size, '${size.width.toInt()}x${size.height.toInt()}${scale == 1 ? '' : '_text13'}');
      await t.pumpWidget(const SizedBox());
      await wait(t, const Duration(seconds: 2));
    }
  });

  testWidgets('the opening: a tap finishes a scene, the next tap moves on; SKIP goes to the promise', (t) async {
    await pumpApp(t, {AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'KIM').toJson())});
    appRef.read(routerProvider).go(Routes.prologue);
    await wait(t, const Duration(milliseconds: 500));
    await t.tapAt(const Offset(180, 300)); // finish scene 1
    await wait(t, const Duration(milliseconds: 100));
    expect(find.text('LONDON'), findsOneWidget, reason: 'still scene 1, now complete');
    await t.tapAt(const Offset(180, 300)); // on
    await wait(t, const Duration(milliseconds: 600));
    expect(find.text('Treasures have vanished.'), findsOneWidget);
    await t.tap(find.text('SKIP ›'));
    await wait(t, const Duration(milliseconds: 1600));
    expect(find.text('ACCEPT THE CASE'), findsOneWidget);
    await t.tapAt(const Offset(180, 300)); // the promise waits for its button
    await wait(t, const Duration(milliseconds: 600));
    expect(find.text('ACCEPT THE CASE'), findsOneWidget);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('the opening: back (app bar or system) goes to the scene before, then to the casebook', (t) async {
    await pumpApp(t, {AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'KIM').toJson())});
    appRef.read(routerProvider).go(Routes.prologue);
    await wait(t, const Duration(milliseconds: 1800));
    for (var i = 0; i < 2; i++) {
      await t.tap(find.text('NEXT ›'));
      await wait(t, const Duration(milliseconds: 3000));
    }
    expect(find.text('They look like separate cases.'), findsOneWidget);
    await t.binding.handlePopRoute(); // Android back
    await wait(t, const Duration(milliseconds: 600));
    expect(path(), Routes.prologue);
    expect(find.text('Treasures have vanished.'), findsOneWidget, reason: 'one scene back, shown complete');
    await t.tap(find.byTooltip('Back'));
    await wait(t, const Duration(milliseconds: 600));
    expect(find.text('LONDON'), findsOneWidget);
    await t.binding.handlePopRoute();
    await wait(t, const Duration(milliseconds: 900));
    expect(path(), Routes.season, reason: 'from the first scene, back to the casebook');
    expect(find.text('BEGIN SEASON ONE'), findsOneWidget);

    // From the case file, back is the promise.
    appRef.read(routerProvider).go(Routes.prologue);
    await wait(t, const Duration(milliseconds: 600));
    await t.tap(find.text('SKIP ›'));
    await wait(t, const Duration(milliseconds: 1600));
    await tapText(t, 'ACCEPT THE CASE', after: const Duration(milliseconds: 1600));
    expect(find.text('START CASE 01'), findsOneWidget);
    await t.binding.handlePopRoute();
    await wait(t, const Duration(milliseconds: 600));
    expect(find.text('ACCEPT THE CASE'), findsOneWidget);
    expect(appRef.read(gameControllerProvider).introSeen, isFalse);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('the cover at 390×844', (t) async {
    await pumpApp(t, {AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'KIM').toJson())},
        size: const Size(390, 844));
    appRef.read(routerProvider).go(Routes.season);
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await wait(t, const Duration(milliseconds: 1800));
    expect(t.takeException(), isNull);
    expectOnScreen(t, find.text('BEGIN SEASON ONE'), const Size(390, 844));
    await capture(t, 'cover_390x844');
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('the casebook and opening are not shown again once the season has begun', (t) async {
    await pumpApp(t, seasonSaves(0, activeBegun: true));
    await tapText(t, 'CONTINUE ADVENTURE', after: const Duration(milliseconds: 1500));
    expect(path(), Routes.map, reason: 'Case 01 under way: straight back to it');
    appRef.read(routerProvider).go(Routes.season);
    await wait(t, const Duration(milliseconds: 2000));
    expect(find.text('BEGIN SEASON ONE'), findsNothing, reason: 'the board, not the casebook');
    expect(find.text('0 / 12'), findsOneWidget);
    expect(find.text('CONTINUE INVESTIGATION'), findsOneWidget);
    await capture(t, 'board_0_360x640');
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('the casebook: a tap brings it in at once; back goes to the title', (t) async {
    await pumpApp(t, {AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'KIM').toJson())});
    appRef.read(routerProvider).go(Routes.season);
    await wait(t, const Duration(milliseconds: 450));
    await t.tapAt(const Offset(180, 200));
    await wait(t, const Duration(milliseconds: 100));
    expect(find.text('BEGIN SEASON ONE').hitTestable(), findsOneWidget);
    await t.tap(find.byTooltip('Back'));
    await wait(t);
    expect(path(), Routes.start);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('an existing save resumes as before: CONTINUE ADVENTURE → the map of the case under way', (t) async {
    await pumpApp(t, seasonSaves(4, active: 'ep05', activeBegun: true));
    await tapText(t, 'CONTINUE ADVENTURE', after: const Duration(milliseconds: 1500));
    expect(path(), Routes.map, reason: 'no season page in between');
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('CONTINUE ADVENTURE with no case under way opens the season board', (t) async {
    await pumpApp(t, {
      ...seasonSaves(4),
      // Case 04 played again from the start (Play again): nothing under way.
      AppConstants.progressKeyFor('ep04'): jsonEncode(const GameProgress(detectiveName: 'MINYOUNG').toJson()),
    });
    await tapText(t, 'CONTINUE ADVENTURE', after: const Duration(milliseconds: 2400));
    expect(path(), Routes.season);
    expect(find.text('4 / 12'), findsOneWidget, reason: 'Play again keeps the season record');
    expect(find.text('The Locked Room'), findsOneWidget, reason: 'the season goes on with Case 05');
    await wait(t, const Duration(seconds: 3));
  });

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('board midway at $tag: progress, current case, actions on screen', (t) async {
      await pumpApp(t, seasonSaves(4), size: size);
      await openSeason(t, size: size);
      expect(t.takeException(), isNull, reason: 'no overflow');
      expect(find.text('CASES SOLVED'), findsOneWidget);
      expect(find.text('4 / 12'), findsOneWidget);
      expect(find.text('CURRENT CASE'), findsOneWidget);
      expect(find.text('The Locked Room'), findsOneWidget);
      expect(find.text('05'), findsWidgets);
      for (final f in [find.text('BEGIN INVESTIGATION'), find.text('View all case files'), find.text('The Locked Room')]) {
        expectOnScreen(t, f, size);
      }
      // Every case on the board, inside it.
      final board = t.getRect(find.byKey(const ValueKey('board-figure'))).inflate(size.width);
      for (final id in ids) {
        final r = t.getRect(find.byKey(ValueKey('board-$id')));
        expect(r.left, greaterThanOrEqualTo(0), reason: id);
        expect(r.right, lessThanOrEqualTo(size.width), reason: id);
        expect(board.overlaps(r), isTrue);
        expect(r.height, greaterThanOrEqualTo(36), reason: 'a case is big enough to tap');
      }
      expect(find.text('THE RAVEN SOCIETY'), findsOneWidget, reason: 'named in Case 04');
      await capture(t, 'board_4_$tag');

      await tapText(t, 'BEGIN INVESTIGATION', after: const Duration(milliseconds: 800));
      expect(path(), Routes.intro, reason: 'Case 05 has not begun: its story first');
      expect(appRef.read(currentEpisodeProvider).id, 'ep05');
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('season complete at $tag: 12 / 12, COMPLETED, the closed board', (t) async {
      await pumpApp(t, seasonSaves(12), size: size);
      await openSeason(t, size: size);
      expect(t.takeException(), isNull);
      expect(find.text('12 / 12'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('All the pieces have come together.'), findsOneWidget);
      expect(find.text('But this is not the end...'), findsOneWidget);
      expect(find.text('THE CLOCKMAKER'), findsOneWidget);
      expect(find.text('CLOSED'), findsOneWidget);
      expect(find.text('CONTINUE INVESTIGATION'), findsNothing);
      expect(find.text('BEGIN INVESTIGATION'), findsNothing);
      expect(screenText(t), isNot(contains('paris')), reason: 'the Season 2 hook stays in Case 12');
      expectOnScreen(t, find.text('VIEW ALL CASE FILES'), size);
      await capture(t, 'board_12_$tag');
      await tapText(t, 'VIEW ALL CASE FILES');
      expect(path(), Routes.episodes);
      await wait(t, const Duration(seconds: 3));
    });
  }

  testWidgets('board at 360×640 with large text (1.3×) stays usable', (t) async {
    await pumpApp(t, seasonSaves(8), textScale: 1.3);
    await openSeason(t);
    expect(t.takeException(), isNull, reason: 'no overflow with large text');
    final board = t.getRect(find.byKey(const ValueKey('board-figure')));
    expect(board.height, greaterThan(60));
    await capture(t, 'board_8_360_text13');
    // The page scrolls if it must: the action is still there to reach.
    await tapText(t, 'BEGIN INVESTIGATION', after: const Duration(milliseconds: 800));
    expect(path(), Routes.intro);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('CONTINUE INVESTIGATION resumes the case under way on its map', (t) async {
    await pumpApp(t, seasonSaves(4, active: 'ep05', activeBegun: true));
    await openSeason(t);
    await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 1200));
    expect(path(), Routes.map);
    expect(appRef.read(currentEpisodeProvider).id, 'ep05');
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('case files ↔ season: VIEW ALL CASE FILES, then back (arrow and system back)', (t) async {
    await pumpApp(t, seasonSaves(2));
    await openSeason(t);
    await tapText(t, 'View all case files');
    expect(path(), Routes.episodes);
    await t.tap(find.byTooltip('Back'));
    await wait(t);
    expect(path(), Routes.season);
    await tapText(t, 'View all case files');
    await t.binding.handlePopRoute(); // Android back
    await wait(t);
    expect(path(), Routes.season);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('board cases: a solved one opens its case file; a sealed one stays shut', (t) async {
    await pumpApp(t, seasonSaves(3));
    await openSeason(t);
    expect(find.bySemanticsLabel('Case 07, sealed'), findsOneWidget, reason: 'a sealed case does not say its title');
    await t.tap(find.byKey(const ValueKey('board-ep07')));
    await wait(t, const Duration(milliseconds: 300));
    expect(find.text('Solve Case 06 to open this file.'), findsOneWidget);
    expect(path(), Routes.season);
    await wait(t, const Duration(seconds: 3));

    await t.tap(find.byKey(const ValueKey('board-ep02')));
    await wait(t, const Duration(milliseconds: 900));
    expect(path(), Routes.caseFile('ep02'));
    expect(find.text('The Silent Clock'), findsOneWidget, reason: 'its folder is open');
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('spoilers on screen: names appear only after the case that tells them', (t) async {
    final checks = <int, (List<String>, List<String>)>{
      1: ([], ['raven', 'clockmaker']),
      3: (['who are the ravens?'], ['raven society', 'clockmaker']),
      4: (['the raven society'], ['clockmaker']),
      9: (['the clockmaker'], ['completed']),
      11: (['the clockmaker'], ['completed']),
    };
    for (final MapEntry(key: solved, value: (shown, hidden)) in checks.entries) {
      await pumpApp(t, seasonSaves(solved));
      await openSeason(t);
      final text = screenText(t);
      for (final s in shown) {
        expect(text, contains(s), reason: '$solved solved: "$s" is known');
      }
      for (final s in [...hidden, 'paris', 'grey', 'robin', 'miss rose', 'the shadow', 'inspector']) {
        expect(text, isNot(contains(s)), reason: '$solved solved: "$s" is not known yet');
      }
      await capture(t, 'board_$solved');
      await t.pumpWidget(const SizedBox());
      await wait(t, const Duration(seconds: 1));
    }
  });

  testWidgets('a case just solved is revealed on the board, once', (t) async {
    // Case 04 down to its final; solving it names the Raven Society.
    final e4 = catalog.firstWhere((e) => e.id == 'ep04');
    await pumpApp(t, {
      ...seasonSaves(3),
      AppConstants.progressKeyFor('ep04'): jsonEncode(GameProgress(
        detectiveName: 'MINYOUNG',
        introSeen: true,
        completedMissionIds: [for (final m in e4.missions) m.id],
        startedAt: DateTime(2026, 9, 29, 11),
        playMillis: 0,
      ).toJson()),
      AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: 'ep04', solvedEpisodeIds: ids.take(3).toList()).toJson()),
    });
    final outcome = appRef.read(gameControllerProvider.notifier).submitAnswer(e4.finalMission, e4.finalMission.answer);
    expect(outcome.result, SubmitResult.correct);
    expect(appRef.read(recentSolveProvider), ['ep04']);

    appRef.read(routerProvider).go(Routes.season);
    await wait(t, const Duration(milliseconds: 500));
    double opacityOf(String text) => t
        .widgetList<Opacity>(find.ancestor(of: find.text(text), matching: find.byType(Opacity)))
        .fold(1.0, (a, o) => a * o.opacity);
    expect(find.text('THE RAVEN SOCIETY'), findsNothing, reason: 'not yet: the photo and thread come first');
    expect(find.text('WHO ARE THE RAVENS?'), findsOneWidget);
    expect(opacityOf('WHO ARE THE RAVENS?'), greaterThan(0.8));
    await wait(t, const Duration(milliseconds: 1000));
    expect(opacityOf('THE RAVEN SOCIETY'), inExclusiveRange(0.0, 1.0), reason: 'the name comes in');
    await capture(t, 'reveal_start');
    await wait(t, const Duration(milliseconds: 2400));
    expect(opacityOf('THE RAVEN SOCIETY'), 1);
    expect(find.text('WHO ARE THE RAVENS?'), findsNothing);
    expect(appRef.read(recentSolveProvider), isEmpty, reason: 'shown once');

    // Next visit: the board as it is, no replay.
    appRef.read(routerProvider).go(Routes.episodes);
    await wait(t);
    appRef.read(routerProvider).go(Routes.season);
    await wait(t, const Duration(milliseconds: 500));
    expect(opacityOf('THE RAVEN SOCIETY'), 1);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('Case 12 closed → INVESTIGATION BOARD → the completed season', (t) async {
    await pumpApp(t, seasonSaves(12));
    appRef.read(recentSolveProvider.notifier).add('ep12');
    appRef.read(routerProvider).go(Routes.solved);
    await wait(t, const Duration(milliseconds: 3200));
    await t.scrollUntilVisible(find.textContaining('PARIS'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('PARIS'), findsOneWidget, reason: "Case 12's own ending and Season 2 hook stay");
    await tapText(t, 'INVESTIGATION BOARD', after: const Duration(milliseconds: 3000));
    expect(path(), Routes.season);
    expect(find.text('COMPLETED'), findsOneWidget);
    expect(find.text('CLOSED'), findsOneWidget);
    await capture(t, 'board_12_revealed');
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('the map menu opens the season board', (t) async {
    await pumpApp(t, seasonSaves(4, active: 'ep05', activeBegun: true));
    appRef.read(routerProvider).go(Routes.map);
    await wait(t, const Duration(milliseconds: 1500));
    await t.tap(find.byTooltip('Menu'));
    await wait(t);
    await tapText(t, 'Season board', after: const Duration(milliseconds: 2400));
    expect(path(), Routes.season);
    expect(find.text('CONTINUE INVESTIGATION'), findsOneWidget);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('reset all: the season starts again with its casebook', (t) async {
    await pumpApp(t, seasonSaves(6));
    await tapText(t, 'NEW ADVENTURE');
    await tapText(t, 'START NEW ADVENTURE', after: const Duration(milliseconds: 1000));
    expect(path(), Routes.register);
    await t.enterText(find.byType(TextField), 'kim');
    await tapText(t, 'OPEN THE CASEBOOK', after: const Duration(milliseconds: 2200));
    expect(path(), Routes.season);
    expect(find.text('BEGIN SEASON ONE'), findsOneWidget);
    final o = appRef.read(seasonOverviewProvider);
    expect(o.solvedCount, 0);
    expect(o.begun, isFalse);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('operator mode: every case opens from the board, nothing is solved or revealed', (t) async {
    await pumpApp(t, {AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'KIM', introSeen: true).toJson())});
    appRef.read(operatorAccessSwitchProvider.notifier).set(true);
    await openSeason(t);
    expect(find.text('0 / 12'), findsOneWidget);
    expect(find.text('ONE MYSTERY'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('board-ep08')));
    await wait(t, const Duration(milliseconds: 900));
    expect(path(), Routes.caseFile('ep08'));
    expect(appRef.read(seasonProvider).solvedEpisodeIds, isEmpty);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('the season needs a detective: a typed URL goes to registration', (t) async {
    await pumpApp(t, const {});
    appRef.read(routerProvider).go(Routes.season);
    await wait(t);
    expect(path(), Routes.register);
    await wait(t, const Duration(seconds: 3));
  });
}
