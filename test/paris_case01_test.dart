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
import 'package:london_mystery/core/utils/answer_checker.dart';
import 'package:london_mystery/data/mock/season2/season2_learning.dart';
import 'package:london_mystery/data/mock/season_catalog.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/learning.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/season/season_overview.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show finishMission, openMission, reveal, tapText, throughPostCase, wait;
import 'helpers.dart';

/// Season 2, Case 01 — The Ticking Watch: its content, the release lock that
/// keeps it from players, and a child's whole play of it (in an operator
/// build's season preview), from the archives to CASE CLOSED.
///
/// Set LM_SHOTS to a folder to save a picture of each screen of the play.
void main() {
  final all = MockEpisodeRepository.bundled();
  final s1 = season1Cases();
  final paris = all.firstWhere((e) => e.id == 's2_ep01');
  final shots = Platform.environment['LM_SHOTS'];

  setUpAll(() async {
    // Real fonts, so text sizes (and any overflow) match the device.
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

  group('the case', () {
    test('Case 01 of Paris: its id, season, place and four puzzles', () {
      expect([for (final e in all.where((e) => e.seasonId == SeasonIds.paris)) e.id], ['s2_ep01']);
      expect(paris.number, 1);
      expect(paris.title, 'The Ticking Watch');
      expect(paris.introScene, Artwork.gareDuNord);
      expect([for (final m in paris.allMissions) m.id], ['s2_ep01_m1', 's2_ep01_m2', 's2_ep01_m3', 's2_ep01_final']);
      expect([for (final m in paris.allMissions) m.type], [
        MissionType.multipleChoice,
        MissionType.sequence,
        MissionType.numberCode,
        MissionType.letterLock,
      ]);
      for (final m in paris.allMissions) {
        expect(m.scene, Artwork.gareDuNord, reason: '${m.id}: its own station, never a London picture');
        expect(m.hints, hasLength(greaterThanOrEqualTo(2)), reason: m.id);
      }
      // The three letters found, and the fourth carved on the box.
      expect([for (final m in paris.missions) m.clue!.value], ['T', 'I', 'M']);
      expect(paris.missions.last.transition.last, contains('E'));
      expect(paris.finalMission.answer, 'TIME');
      expect({for (final o in paris.finalMission.options) o.label}, {'T', 'I', 'M', 'E'});
      expect([for (final o in paris.finalMission.options) o.label].join(), isNot('TIME'), reason: 'the tiles start loose');
      // Its last evidence: the painting, and Case 02's lead on its back.
      expect(paris.finalMission.evidence!.name, 'Montmartre Painting');
      expect(paris.finalMission.evidence!.inscription, contains('FIND THE PAINTER'));
      expect(paris.finalMission.transition.last, 'FIND THE PAINTER.');
    });

    test('the words of the case are the ones written for it', () {
      String text(Mission m) => [m.letter, m.question, ...m.story].join('\n');
      expect(text(paris.missions[0]), contains('IF ONE CLOCK IS ONE HOUR BEHIND,\nREPORT IT TO THE LOST PROPERTY DESK.'));
      for (final line in [
        'FIRST, the hall clock struck ten.',
        'NEXT, a man with a pocket watch entered the waiting room.',
        'AFTER THAT, the old clock showed nine.',
      ]) {
        expect(text(paris.missions[1]), contains(line));
      }
      expect(text(paris.missions[2]), contains('THE OLD CLOCK IS ONE HOUR BEHIND.'));
      expect(text(paris.missions[2]), contains('MOVE ITS HANDS FORWARD ONE HOUR\nTO MATCH THE HALL CLOCK.'));
      expect(paris.missions[0].letter, contains('10:00'));
      expect(paris.missions[0].letter, contains('9:00'));
    });

    test('only the right answer solves each puzzle; near misses say why', () {
      final [m1, m2, m3, fin] = paris.allMissions;
      expect(AnswerChecker.isCorrect(m1, 'c'), isTrue);
      expect(AnswerChecker.isCorrect(m1, 'a'), isFalse);
      expect(AnswerChecker.feedbackFor(m1, 'a'), contains('10:00'));
      expect(AnswerChecker.isCorrect(m2, 'b,c,a'), isTrue);
      expect(AnswerChecker.isCorrect(m2, 'c,b,a'), isFalse);
      expect(AnswerChecker.feedbackFor(m2, 'c,b,a'), contains('FIRST'));
      expect(AnswerChecker.isCorrect(m3, '1000'), isTrue);
      expect(AnswerChecker.isCorrect(m3, '900'), isFalse);
      expect(AnswerChecker.feedbackFor(m3, '900'), contains('FORWARD'));
      expect(AnswerChecker.feedbackFor(m3, '800'), contains('BACK'));
      expect(AnswerChecker.isCorrect(fin, 'TIME'), isTrue);
      expect(AnswerChecker.isCorrect(fin, 'time'), isTrue, reason: 'letters, whatever their case');
      for (final word in ['ITEM', 'EMIT', 'MITE']) {
        expect(AnswerChecker.isCorrect(fin, word), isFalse, reason: word);
        expect(AnswerChecker.feedbackFor(fin, word), contains('$word is a real word'), reason: word);
      }
    });

    test('no hint, feedback or story before the solve gives the answer away', () {
      final [m1, m2, m3, fin] = paris.allMissions;
      for (final h in m1.hints) {
        expect(h.toLowerCase(), isNot(contains('old clock')), reason: h);
      }
      for (final h in m2.hints) {
        expect(h, isNot(contains('man with a pocket watch')), reason: 'the middle card is the puzzle: $h');
      }
      for (final h in m3.hints) {
        expect(h, isNot(contains('10:00')), reason: h);
      }
      for (final s in [...fin.hints, fin.letter, ...fin.story, fin.question, ...m3.transition]) {
        expect(s.toUpperCase(), isNot(contains('TIME')), reason: s);
      }
    });

    test('every word in the case\'s glossary is in its text', () {
      final text = [
        for (final m in paris.allMissions) ...[
          m.title,
          m.location,
          m.letter,
          m.question,
          ...m.story,
          ...m.transition,
          m.letterIntro,
          ...m.hints,
          for (final o in m.options) o.label,
          m.clue?.note ?? '',
          m.evidence?.description ?? '',
          m.evidence?.inscription ?? '',
        ],
        ...paris.intro,
        ...paris.synopsis,
        ...paris.objectives,
      ].join(' ').toLowerCase();
      for (final w in paris.glossary.keys) {
        expect(text, contains(w), reason: w);
      }
    });

    test('its learning design follows Season 1\'s rules', () {
      String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      String screen(Mission m) => norm([
            ...m.story,
            m.letterIntro,
            m.letter,
            m.question,
            for (final o in m.options) o.label,
            ...m.hints,
          ].join(' \n '));
      expect(season2Learning.keys.toSet(), {for (final m in paris.allMissions) m.id});
      expect(season2LanguageTopics.keys, ['s2_ep01']);
      for (final m in paris.allMissions) {
        final l = SeasonCatalog.learning(m)!;
        expect(l.isHonest, isTrue, reason: m.id);
        if (l.dependency == LanguageDependency.essential) expect(l.expressions, isNotEmpty);
        for (final e in l.expressions) {
          expect(screen(m), contains(norm(e)), reason: '${m.id}: "$e" is on its screens');
        }
      }
    });

    test('London Explorer is London\'s badge: Paris neither shows nor gives it', () {
      expect(GameBadge.forEpisode(paris), isNot(contains(GameBadge.londonExplorer)));
      expect(GameBadge.forEpisode(s1.first), contains(GameBadge.londonExplorer));
    });

    test('a season still being written is never complete; its next case is coming', () {
      final season = Season.fromJson(SeasonCatalog.byId(SeasonIds.paris)!.info);
      expect(season.city, 'Paris');
      expect(season.plannedCases, 12);
      final solved = SeasonOverview.of(
        info: season,
        catalog: [paris],
        season: const SeasonProgress(activeEpisodeId: 's2_ep01', solvedEpisodeIds: ['s2_ep01']),
        operator: false,
        progressOf: (_) => const GameProgress(),
      );
      expect(solved.complete, isFalse);
      expect(solved.comingSoonCase, 2);
      expect(solved.current, isNull);
    });
  });

  group('the release lock', () {
    late ProviderContainer c;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      c = ProviderContainer(overrides: await testOverridesFor(await SharedPreferences.getInstance()));
      c.read(gameControllerProvider.notifier).createDetective('Kim', DetectiveAvatar.boy);
      c.read(progressRepositoryProvider).saveSeason(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: [for (final e in s1) e.id]));
      c.invalidate(seasonProvider);
    });
    tearDown(() => c.dispose());

    SeasonAvailability parisNow() => c.read(seasonAvailabilityProvider(SeasonIds.paris))!;

    test('for players, Paris is coming soon even with Season 1 finished', () {
      expect(parisNow().status, SeasonStatus.comingSoon);
      expect(c.read(gameControllerProvider.notifier).openSeason(SeasonIds.paris), isFalse);
      expect(c.read(gameControllerProvider.notifier).openEpisode('s2_ep01'), isFalse);
      expect(c.read(playableSeasonCountProvider), 1);
    });

    test('a release build has no season preview to switch on', () async {
      final release = ProviderContainer(overrides: [
        ...await testOverridesFor(await SharedPreferences.getInstance()),
        operatorToolsAvailableProvider.overrideWithValue(false),
      ]);
      addTearDown(release.dispose);
      release.read(seasonPreviewSwitchProvider.notifier).set(true);
      expect(release.read(seasonPreviewProvider), isFalse);
      expect(release.read(seasonAvailabilityProvider(SeasonIds.paris))!.canEnter, isFalse);
    });

    test('the preview opens it for the operator, and only for the session', () async {
      c.read(seasonPreviewSwitchProvider.notifier).set(true);
      expect(parisNow().status, SeasonStatus.open);
      expect(c.read(gameControllerProvider.notifier).openSeason(SeasonIds.paris), isTrue);
      expect(c.read(currentEpisodeProvider).id, 's2_ep01');
      // A restart forgets the preview: Season 1 again, its saves as they were.
      final again = ProviderContainer(overrides: await testOverridesFor(await SharedPreferences.getInstance()));
      addTearDown(again.dispose);
      expect(again.read(seasonPreviewProvider), isFalse);
      expect(again.read(selectedSeasonIdProvider), SeasonIds.london);
      expect(again.read(seasonProvider).solvedEpisodeIds, hasLength(12));
    });

    testWidgets('no link opens a Paris case or screen while it is not released', (t) async {
      late WidgetRef ref;
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await t.pumpWidget(ProviderScope(
        overrides: await testOverridesFor(prefs),
        child: Consumer(builder: (context, r, _) {
          ref = r;
          return const LondonMysteryApp();
        }),
      ));
      await wait(t);
      ref.read(gameControllerProvider.notifier).createDetective('Kim', DetectiveAvatar.boy);
      ref.read(progressRepositoryProvider).saveSeason(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: [for (final e in s1) e.id]));
      ref.invalidate(seasonProvider);
      final router = ref.read(routerProvider);
      Uri at() => router.routerDelegate.currentConfiguration.uri;
      for (final link in [
        Routes.caseFile('s2_ep01'),
        Routes.mission('s2_ep01_m1'),
        Routes.story('s2_ep01_m1'),
        Routes.story('s2_ep01_final'),
      ]) {
        router.go(link);
        await wait(t, const Duration(milliseconds: 600));
        expect(at().toString(), isNot(contains('s2_')), reason: link);
      }
      expect(ref.read(selectedSeasonIdProvider), SeasonIds.london);
      expect(ref.read(currentEpisodeProvider).seasonId, SeasonIds.london);
      await wait(t, const Duration(seconds: 3));
    });
  });

  group('a child plays Case 01 (operator season preview)', () {
    for (final size in const [Size(360, 640), Size(390, 844), Size(430, 932)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';
      testWidgets('$tag: archives → prologue → case file → three puzzles → letter lock → CASE CLOSED', (t) async {
        t.view.physicalSize = size * 3;
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.reset);
        // Season 1 finished (saves from before profiles, as an updated app finds them).
        GameProgress solved(Episode e) => GameProgress(
          detectiveName: 'MINYOUNG',
          introSeen: true,
          completedMissionIds: [for (final m in e.allMissions) m.id],
          startedAt: DateTime(2026, 9, 29, 10),
          completedAt: DateTime(2026, 9, 29, 10, 30),
          playMillis: 0,
        );
        late WidgetRef ref;
        await t.pumpWidget(ProviderScope(
          overrides: [
            ...await testOverrides(prefs: {
              AppConstants.progressStorageKey: jsonEncode(solved(s1.first).toJson()),
              for (final e in s1.skip(1)) AppConstants.progressKeyFor(e.id): jsonEncode(solved(e).toJson()),
              AppConstants.seasonStorageKey: jsonEncode(
                SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: [for (final e in s1) e.id]).toJson(),
              ),
            }),
            seasonPreviewProvider.overrideWithValue(true),
          ],
          child: RepaintBoundary(
            key: const ValueKey('shot'),
            child: Consumer(builder: (context, r, _) {
              ref = r;
              return const LondonMysteryApp();
            }),
          ),
        ));
        await wait(t, const Duration(milliseconds: 300));
        final router = ref.read(routerProvider);
        String path() => router.routerDelegate.currentConfiguration.uri.toString();
        final prefs = ref.read(sharedPreferencesProvider);
        final season1Saved = prefs.getString(savedKey(prefs, AppConstants.seasonStorageKey));
        final coins = ref.read(walletProvider).balance;

        var n = 0;
        Future<void> shot(String name) async {
          expect(t.takeException(), isNull, reason: name);
          if (shots == null) return;
          await t.runAsync(() async {
            final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
            final image = await boundary.toImage(pixelRatio: 1);
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            File('$shots/paris01_${tag}_${(n++).toString().padLeft(2, '0')}_$name.png').writeAsBytesSync(png!.buffer.asUint8List());
          });
        }

        // ── The archives: Paris, unsealed and open (preview) ───────────
        router.go(Routes.seasons);
        await wait(t, const Duration(milliseconds: 1400));
        await reveal(t, find.text('BEGIN SEASON TWO'));
        await shot('archives');
        await tapText(t, 'BEGIN SEASON TWO', after: const Duration(milliseconds: 1600));
        expect(ref.read(selectedSeasonIdProvider), SeasonIds.paris);
        expect(prefs.getString(savedKey(prefs, AppConstants.seasonStorageKey)), season1Saved, reason: 'Season 1 kept');
        // The cover, then the opening: SKIP to the promise, then Case 01's file.
        await shot('cover');
        await tapText(t, 'BEGIN SEASON TWO', after: const Duration(milliseconds: 1400));
        expect(path(), Routes.parisPrologue);
        await tapText(t, 'SKIP ›', after: const Duration(milliseconds: 1400));
        await tapText(t, 'ACCEPT THE CASE', after: const Duration(milliseconds: 1600));
        await shot('prologue_file');
        await tapText(t, 'START CASE 01', after: const Duration(milliseconds: 1400));

        // ── SCREEN 06: the case file, BEGIN INVESTIGATION at the bottom ──
        expect(path(), Routes.caseFile('s2_ep01'));
        expect(find.text('THE TICKING WATCH'), findsOneWidget);
        final begin = find.text('BEGIN INVESTIGATION');
        expect(t.getRect(begin).bottom, lessThanOrEqualTo(size.height), reason: 'the primary action on screen');
        await shot('landing');
        await tapText(t, 'BEGIN INVESTIGATION', after: const Duration(milliseconds: 1200));
        expect(find.text('Paris. Gare du Nord.'), findsOneWidget, reason: 'the story intro, over its station');
        await shot('intro');
        await tapText(t, 'SKIP ›');
        await tapText(t, "I'M READY", after: const Duration(milliseconds: 1600));
        await shot('map');

        // ── M1: the three clocks ─────────────────────────────────────
        await openMission(t, 'GO TO THE STATION HALL');
        await shot('m1_puzzle');
        // A clock that agrees with another: why it is not the one.
        await tapText(t, 'The hall clock', after: const Duration(milliseconds: 200));
        await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 1500));
        await shot('m1_wrong');
        expect(findReadableContaining('The hall clock shows 10:00'), findsWidgets);
        await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
        // A free hint, written on the page.
        await tapText(t, 'Get a Free Hint', after: const Duration(milliseconds: 900));
        expect(findReadableContaining('Two of them show the same time'), findsWidgets);
        await tapText(t, 'The old clock', after: const Duration(milliseconds: 200));
        await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 400));
        await finishMission(t, sceneLine: paris.missions[0].transition.first);

        // ── M2: the clerk's notes, in order ──────────────────────────
        await openMission(t, 'GO TO LOST PROPERTY DESK');
        await shot('m2_puzzle');
        final m2 = paris.missions[1];
        Future<void> order(List<String> ids) async {
          for (final id in ids) {
            final tile = find.text(m2.options.firstWhere((o) => o.id == id).label).last;
            await reveal(t, tile);
            await t.tap(tile);
            await t.pump(const Duration(milliseconds: 150));
          }
          await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 900));
        }

        await order(['c', 'b', 'a']);
        expect(findReadableContaining('The man came NEXT, not first.'), findsWidgets);
        await shot('m2_wrong');
        await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
        // The order taken back, then put right.
        await tapText(t, 'Start again', after: const Duration(milliseconds: 300));
        await order(['b', 'c', 'a']);
        await finishMission(t, sceneLine: m2.transition.first);

        // ── M3: the old clock set forward one hour ──────────────────
        await openMission(t, 'GO TO THE OLD CLOCK');
        await shot('m3_puzzle');
        for (final d in '1000'.split('')) {
          await tapText(t, d, after: const Duration(milliseconds: 120));
        }
        await tapText(t, 'UNLOCK', after: const Duration(milliseconds: 400));
        await finishMission(t, sceneLine: paris.missions[2].transition.first);

        // ── Final: the letter lock ──────────────────────────────────
        await shot('map_final');
        await tapText(t, 'OPEN THE FINAL CASE', after: const Duration(milliseconds: 4000));
        expect(find.text('FINAL MISSION'), findsOneWidget);
        expect(find.text('UNDER THE OLD CLOCK'), findsOneWidget);
        await reveal(t, find.text('OPEN THE LOCK'));
        await shot('final_lock');
        final open = find.widgetWithText(GestureDetector, 'OPEN THE LOCK');
        // Dragged: E into the third slot; tapped: the others in turn.
        // As a finger drags: down on the tile, a few moves up to the slot, up.
        final from = t.getCenter(find.bySemanticsLabel('Letter E'));
        final to = t.getCenter(find.byKey(const ValueKey('lock-slot-2')));
        final finger = await t.startGesture(from);
        for (var i = 1; i <= 8; i++) {
          await finger.moveTo(Offset.lerp(from, to, i / 8)!);
          await t.pump(const Duration(milliseconds: 16));
        }
        await finger.up();
        await t.pump(const Duration(milliseconds: 300));
        await shot('final_dragged');
        expect(find.descendant(of: find.byKey(const ValueKey('lock-slot-2')), matching: find.text('E')), findsOneWidget, reason: 'dragged into the third slot');
        // A real word, the wrong one: ITEM.
        for (final l in ['I', 'T', 'M']) {
          await t.tap(find.bySemanticsLabel('Letter $l'));
          await t.pump(const Duration(milliseconds: 150));
        }
        expect(open, findsWidgets);
        await shot('final_item');
        await tapText(t, 'OPEN THE LOCK', after: const Duration(milliseconds: 1500));
        await shot('final_wrong');
        expect(findReadableContaining('ITEM is a real word'), findsWidgets);
        await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
        // All taken out, then put back in the right order.
        for (final slot in [0, 1, 2, 3]) {
          await t.tap(find.byKey(ValueKey('lock-slot-$slot')));
          await t.pump(const Duration(milliseconds: 150));
        }
        for (final l in ['T', 'I', 'M', 'E']) {
          await t.tap(find.bySemanticsLabel('Letter $l'));
          await t.pump(const Duration(milliseconds: 150));
        }
        await tapText(t, 'OPEN THE LOCK', after: const Duration(milliseconds: 600));
        await wait(t, const Duration(milliseconds: 3000)); // the lock gives, the box opens
        await shot('final_open');
        expect(find.text('The box clicks open!'), findsOneWidget);

        // ── The scene after the case, then CASE CLOSED ──────────────
        await throughPostCase(t, caseNumber: '01', evidence: 'Montmartre Painting');
        expect(path(), Routes.solved);
        await shot('case_closed');
        await wait(t, const Duration(milliseconds: 1500)); // the file lands, the footer comes in
        await reveal(t, find.text('Paris needs you again.'));
        await shot('case_closed_footer');
        expect(find.text('Paris needs you again.'), findsOneWidget);
        expect(find.text('London needs you again.'), findsNothing);
        expect(find.text('CASE 02 · COMING SOON'), findsOneWidget);
        expect(find.textContaining('OPEN CASE'), findsNothing, reason: 'no Case 02 to open');

        // Saved in Paris's own record; Season 1 and its saves untouched.
        expect(ref.read(seasonProvider).solvedEpisodeIds, ['s2_ep01']);
        expect(prefs.getString(savedKey(prefs, AppConstants.seasonKeyFor(SeasonIds.paris))), isNotNull);
        expect(prefs.getString(savedKey(prefs, AppConstants.seasonStorageKey)), season1Saved);
        expect(ref.read(walletProvider).balance, greaterThan(coins), reason: 'Paris pays into the same wallet');
        final progress = ref.read(gameControllerProvider);
        expect(progress.isCaseSolved, isTrue);
        expect(progress.detectiveName, 'MINYOUNG', reason: 'the same detective');
        expect(progress.badgeIds, isNot(contains(GameBadge.londonExplorer.name)));
        expect([for (final c in progress.collectedClues(paris)) c.value], ['T', 'I', 'M']);
        expect([for (final e in progress.collectedEvidence(paris)) e.name], contains('Montmartre Painting'));

        // The board: Case 02 is coming, nothing to begin.
        await tapText(t, 'INVESTIGATION BOARD', after: const Duration(milliseconds: 3000));
        expect(path(), Routes.season);
        await reveal(t, find.text('CASE 02 · COMING SOON'));
        await shot('board');
        expect(find.text('BEGIN INVESTIGATION'), findsNothing);
        expect(find.text('SEASON COMPLETE'), findsNothing);
        await wait(t, const Duration(seconds: 3));
      });
    }
  });
}
