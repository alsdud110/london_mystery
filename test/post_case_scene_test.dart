import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/mock/season1/season1_mock.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_providers.dart' show sharedPreferencesProvider;
import 'package:london_mystery/widgets/evidence_card.dart';
import 'package:london_mystery/widgets/game_button.dart';
import 'package:london_mystery/widgets/landmark_art.dart';
import 'package:london_mystery/widgets/place_art.dart';

import 'full_playthrough_test.dart' show reveal, wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// After each final case: the post-case story scene (the story scene in its
/// after-the-case mode), the case's last evidence, then the case report.
void main() {
  final catalog = MockEpisodeRepository.bundled();
  Episode byId(String id) => catalog.firstWhere((e) => e.id == id);
  String story(String id) => byId(id).finalMission.transition.join(' ');

  group('post-case content', () {
    test('every final case has a post-case scene and an evidence to show', () {
      expect(catalog, hasLength(12));
      for (final e in catalog) {
        final f = e.finalMission;
        expect(f.transition, isNotEmpty, reason: e.id);
        expect(f.nextMissionId, isNull, reason: '${e.id}: the scene ends the case, it opens no place');
        expect(f.evidence, isNotNull, reason: e.id);
        expect(f.evidence!.inscription, isNotNull, reason: '${e.id}: the card says what is written on it');
      }
    });

    test('no scene tells what a later case asks', () {
      // Case 05: no reason invented to go to Covent Garden (Case 06's intro begins that).
      expect(story('ep05'), isNot(contains('Covent')));
      // Case 10: the Shadow is unmasked only in Case 11.
      expect(story('ep10').toLowerCase(), isNot(contains('shadow')));
      // Case 11: where the door is, is Case 12's riddle.
      expect(story('ep11').toLowerCase(), isNot(contains('under big ben')));
      expect(story('ep11').toLowerCase(), isNot(contains('door')));
    });

    test("the scenes use the cases' own words and sources", () {
      // Case 01: "SEVEN o'clock" is the note on the box at Big Ben (m03); the
      // P.S. is the letter's (Old Letter, m01).
      expect(story('ep01'), isNot(contains('His letter said')));
      expect(story('ep01'), contains("The note at Big Ben said:\n\"I left London at SEVEN o'clock.\""));
      expect(byId('ep01').missionById('m03')!.letter, contains("I left London at SEVEN o'clock."));
      expect(byId('ep01').missionById('m01')!.evidence!.inscription, contains('P.S. I love trains!'));
      expect(story('ep01'), contains('"P.S. I love trains!"'));
      // Case 02: the raven is stamped on the gear.
      expect(story('ep02'), contains('stamped on the gear'));
      expect(story('ep02'), isNot(contains('carved')));
      expect(byId('ep02').missionById('ep02_m2')!.evidence!.inscription, contains('stamped'));
      // Case 05: an iron chest.
      expect(story('ep05'), contains('The iron chest is open.'));
      expect(story('ep05'), isNot(contains('iron box')));
      // Case 06: the post-case scene tells that he is on your side; the final
      // only points to his card (the detective names him from it).
      expect(story('ep06'), contains('Inspector Grey is on your side.'));
      expect(byId('ep06').finalMission.letter, isNot(contains('on your side')));
      expect(byId('ep06').missionById('ep06_m2')!.evidence!.inscription, contains('INSPECTOR GREY'));
      // Case 12: the watch is still ticking (the hook's and the evidence's words).
      expect(story('ep12'), contains('A pocket watch is still ticking.'));
    });

    test("Case 12's scene ends on PARIS; the season's closing lines stay the outro's", () {
      final lines = byId('ep12').finalMission.transition;
      expect(lines.last, 'PARIS.', reason: 'the watch → PARIS is the last beat');
      final outro = Season.fromJson(season1InfoJson).outro;
      expect(outro, ['All the pieces have come together.', 'But this is not the end...']);
      final read = [for (final l in lines) l.replaceAll('\n', ' ')];
      for (final o in outro) {
        expect(read, isNot(contains(o)), reason: '"$o" is said once, by the season');
      }
    });

    test('the season hooks the scenes carry are the ones the cases already tell', () {
      expect(story('ep03'), contains("KING'S CROSS\nLOST PROPERTY"));
      expect(byId('ep03').finalMission.evidence!.inscription, "KING'S CROSS — LOST PROPERTY");
      expect(story('ep05'), contains('the Clockmaker will stop London.'));
      expect(byId('ep05').hook, contains('the Clockmaker will stop London.'));
      expect(story('ep08'), contains('BUCKINGHAM PALACE.'));
      expect(byId('ep08').finalMission.evidence!.inscription, contains('BUCKINGHAM PALACE'));
      expect(story('ep12'), contains('PARIS.'));
      expect(byId('ep12').finalMission.evidence!.inscription, contains('PARIS'));
    });
  });

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

  /// Case [id] solved (every mission, the final too), the cases before it too.
  Future<Map<String, Object>> solvedPrefs(String id) async {
    final e = byId(id);
    final upTo = catalog.indexOf(e);
    return {
      AppConstants.progressKeyFor(id): jsonEncode(GameProgress(
        detectiveName: 'MINYOUNG',
        introSeen: true,
        completedMissionIds: [for (final m in e.allMissions) m.id],
        startedAt: DateTime(2026, 9, 29, 10),
        completedAt: DateTime(2026, 9, 29, 10, 30),
        playMillis: 0,
      ).toJson()),
      if (id != AppConstants.currentEpisodeId)
        AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINYOUNG').toJson()),
      AppConstants.seasonStorageKey: jsonEncode(
        SeasonProgress(activeEpisodeId: id, solvedEpisodeIds: [for (final c in catalog.take(upTo + 1)) c.id]).toJson(),
      ),
    };
  }

  Future<_App> start(WidgetTester t, Size size, Map<String, Object> prefs) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(prefs: prefs),
      child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
    ));
    await wait(t, const Duration(milliseconds: 300));
    return _App(ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first));
  }

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    for (final e in catalog) {
      final tag = '${e.id}_${size.width.toInt()}x${size.height.toInt()}';
      final last = e == catalog.last;
      testWidgets('post-case $tag: CASE ${e.numberLabel} COMPLETE, its place, its evidence, SEE MY CASE REPORT', (t) async {
        final app = await start(t, size, await solvedPrefs(e.id));
        final f = e.finalMission;

        // Final, solved: CONTINUE goes to the post-case scene (not the report).
        app.go(Routes.finalMission);
        await wait(t, const Duration(milliseconds: 1200));
        expect(find.text('SEE MY CASE REPORT'), findsNothing);
        await t.scrollUntilVisible(find.text('CONTINUE'), 300, scrollable: find.byType(Scrollable).first);
        await t.tap(find.text('CONTINUE'));
        await wait(t, const Duration(milliseconds: 900));
        expect(app.path, Routes.story(f.id));
        expect(find.text('CASE ${e.numberLabel} COMPLETE'), findsOneWidget);
        expect(find.textContaining('MISSION'), findsNothing, reason: 'not a mission scene');

        // A tap shows the whole story; then the evidence and the report button.
        await t.tapAt(Offset(size.width / 2, size.height / 2));
        await wait(t, const Duration(milliseconds: 1200));
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 800))); // decode the pictures
        await wait(t, const Duration(milliseconds: 300));
        expect(t.takeException(), isNull);
        for (final line in f.transition) {
          expect(storyLine(line), findsNWidgets(f.transition.where((l) => l == line).length), reason: line);
        }
        expect(find.text('TO THE MAP'), findsNothing);
        expect(find.text('NEW PLACE UNLOCKED'), findsNothing);

        // The place the case was closed at fills the screen (Case 01: the
        // Royal Archive, not the London map).
        final scenery = PlaceArt.sceneryOf(f);
        if (e.id == 'ep01') expect(scenery, Artwork.royalArchive);
        expect(LandmarkArt.hasPicture(scenery!), isTrue, reason: '${f.id} → $scenery');
        final full = find.byWidgetPredicate((w) => w is LandmarkArt && w.artwork == scenery && !w.showName);
        expect(t.getRect(full), Offset.zero & size, reason: 'the place fills the screen');

        // The case's last evidence, on screen, with what is written on it.
        final ev = f.evidence!;
        expect(t.getRect(find.text(ev.name)).bottom, lessThan(size.height), reason: '${ev.name} on screen');
        expect(find.descendant(of: find.byType(EvidenceChip), matching: find.text(ev.inscription!)), findsOneWidget);
        final cta = find.text('SEE MY CASE REPORT');
        expect(t.getRect(cta).bottom, lessThan(size.height), reason: 'SEE MY CASE REPORT on screen');
        expect(t.widget<GameButton>(find.ancestor(of: cta, matching: find.byType(GameButton))).style, GameButtonStyle.glass);
        await capture(t, 'post_case_$tag');

        // Tap the evidence: it opens large, as in the notebook.
        await t.tap(find.text(ev.name));
        await wait(t, const Duration(milliseconds: 600));
        expect(find.text(ev.name), findsNWidgets(2), reason: 'the zoom over the scene');
        await t.binding.handlePopRoute();
        await wait(t, const Duration(milliseconds: 600));

        // SEE MY CASE REPORT → the case file → the next case (or the board).
        await t.tap(cta);
        await wait(t, const Duration(milliseconds: 1500));
        expect(app.path, Routes.solved);
        await wait(t, const Duration(milliseconds: 3200));
        expect(find.text('CASE CLOSED'), findsOneWidget);
        final next = last ? 'INVESTIGATION BOARD' : 'OPEN CASE ${catalog[catalog.indexOf(e) + 1].numberLabel}';
        await reveal(t, find.text(next));
        await t.pump();
        // The hook was the scene's to tell: the report does not repeat it
        // (nor spoil the next case: Case 10 → the Shadow, Case 11 → the door).
        if (e.hook != null) expect(find.text(e.hook!), findsNothing, reason: 'no hook on the report');
        expect(find.textContaining('Find the Shadow'), findsNothing);
        expect(find.textContaining('under Big Ben'), findsNothing);
        expect(find.text('London needs you again.'), findsOneWidget);
        await t.tap(find.text(next));
        await wait(t, const Duration(milliseconds: 1500));
        expect(app.location, last ? Routes.season : Routes.caseFile(catalog[catalog.indexOf(e) + 1].id));
        await wait(t, const Duration(seconds: 3));
      });
    }
  }

  testWidgets('Case 12 read line by line on a small phone: the newest line stays in view', (t) async {
    const size = Size(360, 640);
    final app = await start(t, size, await solvedPrefs('ep12'));
    final f = byId('ep12').finalMission;
    app.go(Routes.story(f.id));
    await wait(t, const Duration(seconds: 45)); // every line typed, no tap
    expect(t.takeException(), isNull);
    final view = t.getRect(find.byType(SingleChildScrollView));
    for (final line in ['PARIS.', 'One word is written\non the back.']) {
      final r = t.getRect(storyLine(line));
      expect(r.top, greaterThanOrEqualTo(view.top - 1), reason: '$line in view');
      expect(r.bottom, lessThanOrEqualTo(view.bottom + 1), reason: '$line in view');
    }
    expect(t.getRect(find.text("The Clockmaker's Watch")).bottom, lessThan(size.height));
    expect(t.getRect(find.text('SEE MY CASE REPORT')).bottom, lessThan(size.height));
    await capture(t, 'post_case_ep12_typed_360x640');
  });

  testWidgets('back on the post-case scene goes to the case report', (t) async {
    final app = await start(t, const Size(390, 844), await solvedPrefs('ep02'));
    app.go(Routes.story('ep02_final'));
    await wait(t, const Duration(milliseconds: 900));
    expect(find.text('CASE 02 COMPLETE'), findsOneWidget);
    await t.binding.handlePopRoute();
    await wait(t, const Duration(milliseconds: 1500));
    expect(app.path, Routes.solved);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('a mission scene is unchanged: MISSION NN COMPLETE, TO THE MAP, back to the map', (t) async {
    final e = byId('ep02');
    final app = await start(t, const Size(390, 844), await solvedPrefs('ep02'));
    app.go(Routes.story(e.missions.first.id));
    await wait(t, const Duration(milliseconds: 900));
    expect(find.text('MISSION 01 COMPLETE'), findsOneWidget);
    expect(find.textContaining('CASE'), findsNothing);
    await t.tapAt(const Offset(195, 422));
    await wait(t, const Duration(milliseconds: 1200));
    expect(find.text('NEW PLACE UNLOCKED'), findsOneWidget);
    expect(find.text('TO THE MAP'), findsOneWidget);
    expect(find.text('SEE MY CASE REPORT'), findsNothing);
    await t.binding.handlePopRoute();
    await wait(t, const Duration(milliseconds: 1500));
    expect(app.path, Routes.map);
    await wait(t, const Duration(seconds: 2));
  });

  testWidgets('the post-case scene opens only once the final case is solved', (t) async {
    final e = byId('ep02');
    final app = await start(t, const Size(390, 844), {
      AppConstants.progressKeyFor('ep02'): jsonEncode(GameProgress(
        detectiveName: 'MINYOUNG',
        introSeen: true,
        completedMissionIds: [for (final m in e.missions) m.id],
        startedAt: DateTime(2026, 9, 29, 10),
        playMillis: 0,
      ).toJson()),
      AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINYOUNG').toJson()),
      AppConstants.seasonStorageKey:
          jsonEncode(const SeasonProgress(activeEpisodeId: 'ep02', solvedEpisodeIds: ['ep01']).toJson()),
    });
    app.go(Routes.story('ep02_final'));
    await wait(t, const Duration(milliseconds: 1500));
    expect(app.path, Routes.map, reason: 'the final case is not solved yet');
    await wait(t, const Duration(seconds: 2));
  });

  testWidgets('watching the post-case scene again saves nothing and locks nothing', (t) async {
    final prefs = await solvedPrefs('ep05');
    final app = await start(t, const Size(390, 844), prefs);
    final store = app.container.read(sharedPreferencesProvider);
    final before = {for (final k in store.getKeys()) k: store.get(k)};
    for (var i = 0; i < 2; i++) {
      app.go(Routes.story('ep05_final'));
      await wait(t, const Duration(milliseconds: 900));
      await t.tapAt(const Offset(195, 422));
      await wait(t, const Duration(milliseconds: 1200));
      await t.tap(find.text('SEE MY CASE REPORT'));
      await wait(t, const Duration(milliseconds: 3500));
      expect(app.path, Routes.solved);
    }
    final after = {for (final k in store.getKeys()) k: store.get(k)};
    expect(after[AppConstants.progressKeyFor('ep05')], before[AppConstants.progressKeyFor('ep05')]);
    expect(after[AppConstants.seasonStorageKey], before[AppConstants.seasonStorageKey]);
    // Case 06 is still open to play.
    await reveal(t, find.text('OPEN CASE 06'));
    await t.pump();
    await t.tap(find.text('OPEN CASE 06'));
    await wait(t, const Duration(milliseconds: 1500));
    expect(app.location, Routes.caseFile('ep06'));
    expect(find.text('Solve Case 05 to open this file.'), findsNothing);
    await wait(t, const Duration(seconds: 2));
  });
}

/// A story line as read on screen: a glossary word's "(tap for meaning)"
/// label is for screen readers, not part of the line.
/// Only the story itself (the evidence card may say the same words).
Finder storyLine(String line) => find.descendant(
  of: find.byType(SingleChildScrollView),
  matching: find.byWidgetPredicate(
    (w) => w is Text && (w.data ?? w.textSpan?.toPlainText(includeSemanticsLabels: false)) == line,
  ),
);

/// The app's router, read where the tests need it.
class _App {
  _App(this.container);

  final ProviderContainer container;

  void go(String location) => container.read(routerProvider).go(location);

  String get path => container.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

  String get location => container.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();
}
