import 'dart:convert';
import 'dart:math' as math;
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
import 'package:london_mystery/data/mock/season2/season2_scenes.dart';
import 'package:london_mystery/data/models/clock_puzzle.dart';
import 'package:london_mystery/data/models/discovery.dart';
import 'package:london_mystery/data/models/learning.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/models/story_picture.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/mission/widgets/scene_explore.dart' show LookMark;
import 'package:london_mystery/features/mission/widgets/station_clocks.dart' show GuideOutline, GuidePulse;
import 'package:london_mystery/features/season/season_overview.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
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
      expect([for (final e in all.where((e) => e.seasonId == SeasonIds.paris)) e.id], ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05', 's2_ep06']);
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
      // Case 01's own (Case 02's are checked in paris_case02_test.dart).
      expect(season2Learning.keys.where((id) => id.startsWith('s2_ep01_')).toSet(), {for (final m in paris.allMissions) m.id});
      expect(season2LanguageTopics.keys.first, 's2_ep01');
      // Case 06's is written with it, waiting for its pictures.
      expect(season2LanguageTopics.keys.toSet(), {'s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05', 's2_ep06'});
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

  group('its pictures, in its scenes', () {
    const folder = 'assets/seasons/season_02_paris/cases/case_01';
    final [m1, m2, m3, fin] = paris.allMissions;

    /// A PNG's width and height, from its header.
    (int, int) pixelsOf(String file) {
      final b = File(file).readAsBytesSync();
      int at(int i) => (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];
      return (at(16), at(20));
    }

    test('the six pictures are in the game, at the sizes their scenes are measured on', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('    - $folder/'));
      final hall = SeasonCatalog.stationClocks(m1)!;
      final ticket = SeasonCatalog.exhibit(m2)!;
      final box = SeasonCatalog.lockBox(fin)!;
      final sizes = {
        hall.picture: hall.pixels,
        ticket.picture: ticket.pixels,
        box.closed: box.closedPixels,
        box.open: box.openPixels,
        box.found: box.foundPixels,
      };
      for (final MapEntry(key: file, value: px) in sizes.entries) {
        expect(File(file).existsSync(), isTrue, reason: file);
        expect(pixelsOf(file), (px.width.toInt(), px.height.toInt()), reason: file);
      }
      expect(pixelsOf('$folder/old_clock_face.png'), (1254, 1254));
      expect(ArtAssets.scenes[Artwork.oldClockFace], '$folder/old_clock_face.png');
      expect(ArtAssets.evidencePictures['s2_ep01_e2'], ticket.picture);
      expect(ArtAssets.evidencePictures['s2_ep01_e4'], box.found);
    });

    test('M1: three clocks, one for each answer; only the old one an hour behind', () {
      final hall = SeasonCatalog.stationClocks(m1)!;
      expect(m1.type, MissionType.multipleChoice, reason: 'checked as its choice, as before');
      expect({for (final c in hall.clocks) c.optionId}, {for (final o in m1.options) o.id});
      expect({for (final c in hall.clocks) c.optionId: c.time}, {'a': '10:00', 'b': '10:00', 'c': '9:00'});
      expect(hall.clock(m1.answer).name, 'THE OLD CLOCK');
      expect(hall.notice, contains('IF ONE CLOCK IS ONE HOUR BEHIND, REPORT IT TO THE LOST PROPERTY DESK.'));
      // Its trains leave after ten: the board never says which clock is right.
      for (final d in hall.departures) {
        expect(d.time.compareTo('10:00'), greaterThan(0), reason: d.time);
      }
      for (final c in hall.clocks) {
        // The hands on the dial: the pivot inside the clock, XII above it,
        // the hour hand at ten (or nine) o'clock, on the picture's numerals.
        expect(c.area.contains(c.centre), isTrue, reason: c.name);
        expect(c.closeUp.contains(c.centre), isTrue, reason: c.name);
        Offset px(Offset f) => Offset(f.dx * hall.pixels.width, f.dy * hall.pixels.height);
        final twelve = px(c.twelve) - px(c.centre);
        final hour = px(c.hourNumeral) - px(c.centre);
        expect(ClockTime.angleOf(twelve.dx, twelve.dy), anyOf(lessThan(5), greaterThan(355)), reason: c.name);
        final a = ClockTime.angleOf(hour.dx, hour.dy);
        final wanted = int.parse(c.time.split(':').first) * 30.0;
        expect((a - wanted).abs(), lessThan(20), reason: '${c.name}: its hour hand at ${c.time}');
        // A close look is square on screen.
        expect(c.closeUp.width * hall.pixels.width, moreOrLessEquals(c.closeUp.height * hall.pixels.height, epsilon: 1));
      }
    });

    test('M3: the old clock\'s hands start at nine and are set forward to ten', () {
      final clock = SeasonCatalog.clock(m3)!;
      expect(clock.face, Artwork.oldClockFace);
      final start = ClockTime.at(clock.start.hour, clock.start.minute);
      expect(start.label, '9:00');
      expect(AnswerChecker.isCorrect(m3, start.answer), isFalse, reason: 'never the answer at the start');
      expect(AnswerChecker.isCorrect(m3, start.plusMinutes(60).answer), isTrue);
      expect(ArtAssets.clockHands[Artwork.oldClockFace], isNotNull);
    });

    test('M2: the ticket is shown as printed, and nothing in the mission says where it leads', () {
      final ticket = SeasonCatalog.exhibit(m2)!;
      expect(ticket.description, contains('MONTMARTRE, PARIS, number 72831'));
      expect(m2.evidence!.inscription, contains('MONTMARTRE · PARIS · No. 72831'));
      expect(m2.letter, isNot(contains('LONDON')), reason: 'the printed ticket says nothing of London');
      // The ticket's words are read on it, never pointed out as the next case.
      for (final s in [...m2.story, m2.letterIntro, m2.letter, m2.question, ...m2.hints, ...m2.transition, m2.clue!.note, m2.successMessage]) {
        expect(s.toLowerCase(), isNot(contains('montmartre')), reason: s);
        expect(s.toLowerCase(), isNot(contains('painter')), reason: s);
      }
      expect(m2.answer, 'b,c,a', reason: 'its order puzzle as it was');
      expect(m2.clue!.value, 'I');
    });

    test('Final: the box\'s four slots, its painting, and the painting matched to the ticket', () {
      final box = SeasonCatalog.lockBox(fin)!;
      expect(box.closedSlots, hasLength(fin.answer.length));
      expect(box.openSlots, hasLength(fin.answer.length));
      for (final slots in [box.closedSlots, box.openSlots]) {
        for (var i = 1; i < slots.length; i++) {
          expect(slots[i].left, greaterThan(slots[i - 1].right), reason: 'left to right, apart');
        }
      }
      expect(box.back, 'FIND THE PAINTER.');
      expect(fin.evidence!.inscription, contains(box.back));
      const links = season2EvidenceLinks;
      expect(links['s2_ep01_e4']!.to, m2.evidence!.id);
      expect(links['s2_ep01_e2']!.to, fin.evidence!.id);
      expect(fin.transition, contains('The same white church is on the lost ticket.'));
      expect(fin.transition.last, 'FIND THE PAINTER.');
      expect(SeasonCatalog.evidenceLink('e01'), isNull, reason: 'Season 1 has no links');
    });

    test('the story\'s pictures: a new one at each moment, never ahead of the story', () {
      final scenes = [for (final m in paris.allMissions) SeasonCatalog.storyScenes(m)];
      expect(scenes.every((s) => s != null), isTrue);
      String id(StoryPicture p) => '${p.file}@${p.crop}';
      // Each mission's place page is its own picture.
      final places = [for (final s in scenes) ?s!.place];
      expect(places, hasLength(3), reason: 'M1-M3 have a place page; the final opens on its box');
      expect({for (final p in places) id(p)}, hasLength(3));
      // Each scene after a mission is its own picture, never the place page
      // just seen.
      final afters = [for (final s in scenes) s!.after!];
      expect({for (final p in afters) id(p)}, hasLength(4));
      for (var i = 0; i < 3; i++) {
        expect(id(afters[i]), isNot(id(places[i])), reason: '${paris.allMissions[i].id}: a new picture after it');
      }
      // Never ahead: the box open only after the case, the painting never.
      final box = SeasonCatalog.lockBox(paris.finalMission)!;
      for (final (i, s) in scenes.indexed) {
        for (final p in [?s!.place, ?s.after, ?s.next]) {
          expect(p.file, isNot(box.found), reason: 'the painting is shown by the box, at the end');
          if (i < 3) expect(p.file, isNot(box.open), reason: 'the box is shut until the final');
        }
      }
      expect(scenes.last!.after!.file, box.open);
      // The old clock is at nine wherever it is shown before it is put right.
      for (final p in [for (final s in scenes.take(3)) ...[?s!.place, ?s.next]]) {
        for (final c in p.clocks) {
          if (c.name == 'THE OLD CLOCK') expect(c.time, '9:00', reason: p.label);
        }
      }
      expect(scenes[2]!.after!.clocks.single.time, '10:00', reason: 'put right after M3');
      // Season 1 has none: its scenes as they were.
      for (final e in s1) {
        for (final m in e.allMissions) {
          expect(SeasonCatalog.storyScenes(m), isNull, reason: m.id);
        }
      }
    });

    testWidgets('the guides breathe; with reduced motion they are simply there', (t) async {
      for (final still in [false, true]) {
        await t.pumpWidget(MaterialApp(
          home: Column(children: [
            GuidePulse(still: still, child: const SizedBox.square(dimension: 30)),
            SizedBox(width: 100, height: 60, child: GuideOutline(still: still)),
          ]),
        ));
        await t.pump(const Duration(milliseconds: 100));
        expect(t.hasRunningAnimations, !still, reason: still ? 'still' : 'pulsing');
        await t.pumpWidget(const SizedBox());
        expect(t.hasRunningAnimations, isFalse, reason: 'disposed with the hall');
      }
    });

    test('the case file prints where the case happens; Season 1\'s files are as they were', () {
      expect(paris.place, 'GARE DU NORD · PARIS');
      for (final e in s1) {
        expect(e.place, isNull, reason: e.id);
      }
    });

    test('what was looked at is saved with the case, and read back', () {
      final p = GameProgress.fromJson(
        const GameProgress(examined: ['s2_ep01_m1:board', 's2_ep01_m1:c']).toJson(),
      );
      expect(p.hasExamined(GameProgress.examinedKey('s2_ep01_m1', 'board')), isTrue);
      expect(p.hasExamined('s2_ep01_m1:a'), isFalse);
      expect(const GameProgress().toJson().containsKey('examined'), isFalse, reason: 'old saves unchanged');
      expect(GameProgress.fromJson(const {}).examined, isEmpty);
    });
  });

  group('the release lock', () {
    /// Paris as it was before its release (2026-10-21): the lock is tested
    /// on it. The game ships it released.
    final notYetReleased = seasonReleasedProvider.overrideWithValue((id) => id != SeasonIds.paris);
    late ProviderContainer c;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      c = ProviderContainer(overrides: [...await testOverridesFor(await SharedPreferences.getInstance()), notYetReleased]);
      c.read(gameControllerProvider.notifier).createDetective('Kim', DetectiveAvatar.boy);
      c.read(progressRepositoryProvider).saveSeason(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: [for (final e in s1) e.id]));
      c.invalidate(seasonProvider);
    });
    tearDown(() => c.dispose());

    SeasonAvailability parisNow() => c.read(seasonAvailabilityProvider(SeasonIds.paris))!;

    test('as shipped, Paris is released: Season 1 finished opens it for players, no preview needed', () async {
      final shipped = ProviderContainer(overrides: await testOverridesFor(await SharedPreferences.getInstance()));
      addTearDown(shipped.dispose);
      expect(SeasonCatalog.byId(SeasonIds.paris)!.released, isTrue);
      expect(shipped.read(seasonPreviewProvider), isFalse);
      final paris = shipped.read(seasonAvailabilityProvider(SeasonIds.paris))!;
      expect(paris.released, isTrue);
      expect(paris.status, SeasonStatus.open);
      expect(shipped.read(gameControllerProvider.notifier).openSeason(SeasonIds.paris), isTrue);
      expect(shipped.read(currentEpisodeProvider).id, 's2_ep01');
      expect(shipped.read(gameControllerProvider.notifier).openEpisode('s2_ep02'), isFalse, reason: 'still case by case');
    });

    test('as shipped, Paris stays locked until Season 1 is finished', () async {
      SharedPreferences.setMockInitialValues({});
      final fresh = ProviderContainer(overrides: await testOverridesFor(await SharedPreferences.getInstance()));
      addTearDown(fresh.dispose);
      fresh.read(gameControllerProvider.notifier).createDetective('Lee', DetectiveAvatar.girl);
      final paris = fresh.read(seasonAvailabilityProvider(SeasonIds.paris))!;
      expect(paris.released, isTrue);
      expect(paris.isUnlocked, isFalse);
      expect(fresh.read(gameControllerProvider.notifier).openSeason(SeasonIds.paris), isFalse);
    });

    // The lock itself, on a Paris not yet out (as before its release).
    test('for players, an unreleased Paris is coming soon even with Season 1 finished', () {
      expect(parisNow().status, SeasonStatus.comingSoon);
      expect(c.read(gameControllerProvider.notifier).openSeason(SeasonIds.paris), isFalse);
      expect(c.read(gameControllerProvider.notifier).openEpisode('s2_ep01'), isFalse);
      expect(c.read(playableSeasonCountProvider), 1);
    });

    test('a release build has no season preview to switch on', () async {
      final release = ProviderContainer(overrides: [
        ...await testOverridesFor(await SharedPreferences.getInstance()),
        notYetReleased,
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
      final again = ProviderContainer(overrides: [...await testOverridesFor(await SharedPreferences.getInstance()), notYetReleased]);
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
          // Every picture on screen decoded first (a test's image cache
          // starts cold), so the picture shows what a phone shows.
          await t.runAsync(() async {
            for (final e in find.byType(Image).evaluate()) {
              await precacheImage((e.widget as Image).image, e);
            }
          });
          await t.pump();
          await t.runAsync(() async {
            final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
            final image = await boundary.toImage(pixelRatio: 1);
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            File('$shots/paris01_${tag}_${(n++).toString().padLeft(2, '0')}_$name.png').writeAsBytesSync(png!.buffer.asUint8List());
          });
        }

        // A mission solved: its Discovery Moment, then the scene after it,
        // over its own picture (never the same station each time), the
        // next place on its card, then the map.
        Future<void> finish(String sceneLine, String name) async {
          await wait(t, const Duration(milliseconds: 2800));
          expect(find.byWidgetPredicate((w) => w is Text && DiscoveryType.values.any((d) => d.cheer == w.data)), findsOneWidget);
          await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 900));
          expect(find.text(sceneLine), findsOneWidget, reason: 'story transition');
          await t.tapAt(const Offset(200, 400)); // skip typing
          await wait(t, const Duration(milliseconds: 900));
          expect(find.byKey(const ValueKey('scene-backdrop')), findsOneWidget, reason: '$name: its own picture');
          expect(find.byKey(const ValueKey('unlocked-picture')), findsOneWidget, reason: '$name: the next place');
          await shot('${name}_scene');
          await tapText(t, 'TO THE MAP', after: const Duration(milliseconds: 1200));
          await wait(t, const Duration(milliseconds: 3200)); // LOCKED → UNLOCKED ceremony
        }

        // ── Season 1 completed: GO TO PARIS, no archive between ─────────
        router.go(Routes.season);
        await wait(t, const Duration(milliseconds: 2400));
        expect(find.text('COMPLETED'), findsOneWidget);
        expect(find.text('But this is not the end...'), findsOneWidget);
        expect(find.text('OPEN THE ARCHIVE'), findsNothing);
        expect(find.text('View Case Files'), findsOneWidget);
        final next = find.byKey(const ValueKey('begin-next-season'));
        expect(t.getRect(next).bottom, lessThanOrEqualTo(size.height), reason: 'the main action on screen');
        await shot('season1_completed');
        await t.tap(next);
        await wait(t, const Duration(milliseconds: 1600));
        expect(ref.read(selectedSeasonIdProvider), SeasonIds.paris);
        expect(prefs.getString(savedKey(prefs, AppConstants.seasonStorageKey)), season1Saved, reason: 'Season 1 kept');
        // The cover, then the opening: SKIP to the promise, then Case 01's file.
        await shot('cover');
        expect(find.text('BEGIN SEASON TWO'), findsNothing, reason: 'begun once, on the board');
        await tapText(t, 'BEGIN INVESTIGATION', after: const Duration(milliseconds: 1400));
        expect(path(), Routes.parisPrologue);
        await tapText(t, 'SKIP ›', after: const Duration(milliseconds: 1400));
        // Left before the end of the opening: it is not seen yet, the cover
        // and the opening come again.
        expect(ref.read(seasonProvider).prologueSeen, isFalse);
        await tapText(t, 'ACCEPT THE CASE', after: const Duration(milliseconds: 1600));
        expect(ref.read(seasonProvider).prologueSeen, isTrue, reason: 'watched to the case file: saved');
        await shot('prologue_file');
        await tapText(t, 'START CASE 01', after: const Duration(milliseconds: 1400));
        expect(path(), Routes.caseFile('s2_ep01'));
        // Leaving the case file and coming back to Season 2: its board (Case
        // 01 to begin), never the opening again.
        router.go(Routes.season);
        await wait(t, const Duration(milliseconds: 2400));
        expect(find.text('BEGIN INVESTIGATION'), findsOneWidget, reason: 'the board, Case 01 to begin');
        expect(find.text('CASES SOLVED'), findsOneWidget, reason: 'the board, not the cover again');
        await shot('paris_board_begun');
        router.go(Routes.caseFile('s2_ep01'));
        await wait(t, const Duration(milliseconds: 1400));

        // ── SCREEN 06: the case file, BEGIN INVESTIGATION at the bottom ──
        expect(path(), Routes.caseFile('s2_ep01'));
        expect(find.text('THE TICKING WATCH'), findsOneWidget);
        expect(find.text('GARE DU NORD · PARIS'), findsOneWidget);
        expect(find.text('YOUR OBJECTIVES'), findsOneWidget);
        for (final o in paris.objectives) {
          expect(find.text(o), findsOneWidget, reason: o);
        }
        final begin = find.text('BEGIN INVESTIGATION');
        expect(t.getRect(begin).bottom, lessThanOrEqualTo(size.height), reason: 'the primary action on screen');
        await shot('landing');
        await tapText(t, 'BEGIN INVESTIGATION', after: const Duration(milliseconds: 1200));
        expect(find.text('Paris. Gare du Nord.'), findsOneWidget, reason: 'the story intro, over its station');
        await shot('intro');
        await tapText(t, 'SKIP ›');
        await tapText(t, "I'M READY", after: const Duration(milliseconds: 1600));
        await shot('map');

        // ── M1: the three clocks, looked at in the hall ─────────────────
        final hall = SeasonCatalog.stationClocks(paris.missions[0])!;
        Future<void> tapHall(Offset at) async {
          final picture = t.getRect(find.byKey(const ValueKey('station-picture')));
          await t.tapAt(Offset(picture.left + at.dx * picture.width, picture.top + at.dy * picture.height));
          await wait(t, const Duration(milliseconds: 600));
        }

        Finder task(String line) => findReadableContaining(line);
        final boardGuide = find.byKey(const ValueKey('board-guide'));
        final deskGuide = find.byKey(const ValueKey('desk-guide'));
        // Out to the map and back into the hall: it opens as it was left.
        Future<void> leaveAndComeBack() async {
          router.go(Routes.map);
          await wait(t, const Duration(milliseconds: 1400));
          router.go(Routes.mission('s2_ep01_m1'));
          await wait(t, const Duration(milliseconds: 1400));
          expect(find.byKey(const ValueKey('station-picture')), findsOneWidget, reason: 'back in the hall');
        }

        bool looked(String id) => t.widget<LookMark>(find.byKey(ValueKey('mark-$id'))).looked;

        await t.tap(find.bySemanticsLabel('GO TO THE STATION HALL'));
        await wait(t, const Duration(milliseconds: 2800));
        expect(find.byKey(const ValueKey('story-picture')), findsOneWidget, reason: 'the hall, its clocks with hands');
        await shot('m1_place');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.text('TAP TO OPEN'), findsNothing, reason: 'the notice is read in the hall itself');
        // State A: the clocks first; nothing else pointed out.
        expect(task('Tap the three clocks to investigate.'), findsWidgets);
        expect(boardGuide, findsNothing);
        expect(deskGuide, findsNothing);
        await shot('m1_hall');
        // The desk before anything is seen: what to do first.
        await tapHall(hall.desk.area.center);
        expect(find.text(hall.boardFirstLine), findsOneWidget);
        // Each clock up close: its name and its time; between them, out and
        // back in (one clock seen, then two): the hall as it was left.
        for (final (i, c) in hall.clocks.indexed) {
          await tapHall(c.centre);
          expect(find.byKey(ValueKey('station-clock-${c.optionId}')), findsOneWidget, reason: c.name);
          expect(find.text(c.name), findsOneWidget);
          expect(find.text(c.time), findsOneWidget);
          await shot('m1_clock_${c.optionId}');
          await t.tap(find.byKey(const ValueKey('station-close')));
          await wait(t, const Duration(milliseconds: 400));
          expect(find.byKey(ValueKey('station-clock-${c.optionId}')), findsNothing);
          if (i < 2) {
            await leaveAndComeBack();
            for (final seen in hall.clocks.take(i + 1)) {
              expect(looked(seen.optionId), isTrue, reason: '${seen.name} still ticked');
            }
            expect(looked(hall.clocks[i + 1].optionId), isFalse);
            expect(task('Tap the three clocks to investigate.'), findsWidgets, reason: '${i + 1} of 3: the clocks still');
            expect(boardGuide, findsNothing);
          }
        }
        // State B: every clock seen: the departure board, outlined.
        expect(task('Great! Now check the departure board.'), findsWidgets);
        expect(boardGuide, findsOneWidget);
        expect(deskGuide, findsNothing);
        await shot('m1_board_guide');
        // Restored as it was.
        await leaveAndComeBack();
        expect(task('Great! Now check the departure board.'), findsWidgets);
        expect(boardGuide, findsOneWidget);
        // Still the notice to read before the desk.
        await tapHall(hall.desk.area.center);
        expect(find.text(hall.boardFirstLine), findsOneWidget);
        // The departure board: its trains, and the notice under them.
        await tapHall(hall.board.area.center);
        expect(find.byKey(const ValueKey('departure-board')), findsOneWidget);
        expect(find.text('DEPARTURES'), findsOneWidget);
        expect(find.text('10:15'), findsOneWidget);
        for (final part in ['ONE HOUR BEHIND,', 'LOST PROPERTY DESK.']) {
          expect(findReadableContaining(part), findsWidgets, reason: part);
        }
        await shot('m1_board');
        await tapText(t, 'BACK TO THE HALL', after: const Duration(milliseconds: 500));
        // Saved: the clocks and the board stay looked at after a restart.
        expect(ref.read(gameControllerProvider).examined, containsAll(['s2_ep01_m1:a', 's2_ep01_m1:b', 's2_ep01_m1:c', 's2_ep01_m1:board']));
        // State C: the report, the desk's glass calling (where, not which).
        expect(task('One clock is one hour behind!'), findsWidgets);
        expect(task('Report it to the Lost Property Desk.'), findsWidgets);
        expect(boardGuide, findsNothing);
        expect(deskGuide, findsOneWidget);
        expect(find.byKey(const ValueKey('report-here')), findsOneWidget);
        expect(t.hasRunningAnimations, isTrue, reason: 'the glass pulses');
        await shot('m1_desk_guide');
        await leaveAndComeBack();
        expect(deskGuide, findsOneWidget, reason: 'restored: still to go to');
        // The desk: the three clocks as seen, one to report.
        await tapHall(hall.desk.area.center);
        expect(find.byKey(const ValueKey('station-desk')), findsOneWidget);
        // The three cards alike: as tall, their faces, names and times level.
        final cards = [for (final c in hall.clocks) t.getRect(find.byKey(ValueKey('report-${c.optionId}')))];
        final names = [for (final c in hall.clocks) t.getRect(find.byKey(ValueKey('report-name-${c.optionId}')))];
        final times = [for (final c in hall.clocks) t.getRect(find.byKey(ValueKey('report-time-${c.optionId}')))];
        for (var i = 1; i < 3; i++) {
          expect(cards[i].top, moreOrLessEquals(cards[0].top, epsilon: 0.5));
          expect(cards[i].bottom, moreOrLessEquals(cards[0].bottom, epsilon: 0.5), reason: 'the same height');
          expect(cards[i].width, moreOrLessEquals(cards[0].width, epsilon: 0.5));
          expect(names[i].height, moreOrLessEquals(names[0].height, epsilon: 0.5));
          expect(times[i].center.dy, moreOrLessEquals(times[0].center.dy, epsilon: 0.5), reason: 'the times on one line');
        }
        expect(cards[1].left - cards[0].right, moreOrLessEquals(cards[2].left - cards[1].right, epsilon: 0.5));
        // The platform clock's name fits its room (two lines, not cut).
        final platformName = t.widget<Text>(find.descendant(of: find.byKey(const ValueKey('report-name-b')), matching: find.byType(Text)));
        expect(platformName.style!.fontSize, greaterThanOrEqualTo(13), reason: 'never shrunk below 13');
        expect(t.takeException(), isNull, reason: 'no overflow');
        await shot('m1_desk');
        // Back to the hall: the desk was gone to, its glass quiet now.
        await t.tap(find.byKey(const ValueKey('station-desk-close')));
        await wait(t, const Duration(milliseconds: 500));
        expect(deskGuide, findsNothing, reason: 'the guide stops once the desk is tapped');
        expect(find.byKey(const ValueKey('mark-desk')), findsOneWidget, reason: 'still a way to it');
        expect(task('Report it to the Lost Property Desk.'), findsWidgets);
        await leaveAndComeBack();
        expect(deskGuide, findsNothing, reason: 'restored: gone to');
        await tapHall(hall.desk.area.center);
        // A clock that agrees with another: why it is not the one.
        await t.tap(find.byKey(const ValueKey('report-a')));
        await t.pump(const Duration(milliseconds: 200));
        await shot('m1_desk_chosen');
        await tapText(t, 'REPORT IT', after: const Duration(milliseconds: 1500));
        await shot('m1_wrong');
        expect(findReadableContaining('The hall clock shows 10:00'), findsWidgets);
        await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
        // A free hint, written on the page.
        await tapText(t, 'Get a Free Hint', after: const Duration(milliseconds: 900));
        expect(findReadableContaining('Two of them show the same time'), findsWidgets);
        await t.tap(find.byKey(const ValueKey('report-c')));
        await t.pump(const Duration(milliseconds: 200));
        await tapText(t, 'REPORT IT', after: const Duration(milliseconds: 400));
        await finish(paris.missions[0].transition.first, 'm1');
        expect(ref.read(gameControllerProvider).collectedClues(paris).map((c) => c.value), ['T']);

        // ── M2: the lost ticket, then the clerk's notes in order ───────
        final m2 = paris.missions[1];
        await t.tap(find.bySemanticsLabel('GO TO LOST PROPERTY DESK'));
        await wait(t, const Duration(milliseconds: 2800));
        // The desk, under the old clock: a print of its own.
        expect(find.byKey(const ValueKey('story-picture')), findsOneWidget);
        expect(find.byKey(const ValueKey('story-lens')), findsNothing);
        await shot('m2_place');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 700));
        final ticket = find.byKey(const ValueKey('exhibit-ticket'));
        expect(ticket, findsOneWidget, reason: 'the ticket, handed over with the notes');
        await shot('m2_notes');
        await reveal(t, ticket);
        await t.tap(ticket);
        await wait(t, const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('exhibit-zoom')), findsOneWidget);
        await shot('m2_ticket');
        await tapText(t, 'BACK TO THE NOTES', after: const Duration(milliseconds: 600));
        expect(ref.read(gameControllerProvider).hasExamined('s2_ep01_m2:ticket'), isTrue);
        await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
        await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
        await shot('m2_puzzle');
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
        await finish(m2.transition.first, 'm2');

        // ── M3: the old clock's hands, dragged forward one hour ────────
        // The old clock, up close through a lens, before its carving.
        await t.tap(find.bySemanticsLabel('GO TO THE OLD CLOCK'));
        await wait(t, const Duration(milliseconds: 2800));
        expect(find.byKey(const ValueKey('story-lens')), findsOneWidget);
        await shot('m3_place');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 700));
        await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
        await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
        await reveal(t, find.byKey(const ValueKey('clock-dial')));
        await shot('m3_puzzle');
        expect(find.byKey(const ValueKey('clock-time')), findsOneWidget);
        expect(find.text('9:00'), findsOneWidget, reason: 'the hands start where the old clock stands');
        final art = ArtAssets.clockHands[Artwork.oldClockFace]!;
        // The hour hand dragged round the face to [hour] o'clock.
        Future<void> dragHourTo(int from, int to) async {
          final dial = t.getRect(find.byKey(const ValueKey('clock-dial')));
          final pivot = dial.topLeft + Offset(art.pivot.dx * dial.width, art.pivot.dy * dial.width);
          final r = art.hourLength * dial.width * 0.7;
          Offset at(double hour) => pivot + Offset(math.sin(hour * math.pi / 6), -math.cos(hour * math.pi / 6)) * r;
          final finger = await t.startGesture(at(from.toDouble()));
          for (var i = 1; i <= 6; i++) {
            await finger.moveTo(at(from + (to - from) * i / 6));
            await t.pump(const Duration(milliseconds: 16));
          }
          await finger.up();
          await t.pump(const Duration(milliseconds: 200));
        }

        // Back an hour first: the carving says FORWARD.
        await dragHourTo(9, 8);
        expect(find.text('8:00'), findsOneWidget);
        await tapText(t, 'SET THE TIME', after: const Duration(milliseconds: 1500));
        expect(findReadableContaining('That is one hour BACK'), findsWidgets);
        await shot('m3_wrong');
        await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
        await reveal(t, find.byKey(const ValueKey('clock-dial')));
        await dragHourTo(8, 10);
        expect(find.text('10:00'), findsOneWidget);
        await shot('m3_set');
        await tapText(t, 'SET THE TIME', after: const Duration(milliseconds: 400));
        await finish(paris.missions[2].transition.first, 'm3');

        // ── Final: the brass box's letter lock ─────────────────────────
        await shot('map_final');
        await tapText(t, 'OPEN THE FINAL CASE', after: const Duration(milliseconds: 4000));
        expect(find.text('FINAL MISSION'), findsOneWidget);
        expect(find.text('UNDER THE OLD CLOCK'), findsOneWidget);
        expect(find.byKey(const ValueKey('lock-box-shut')), findsOneWidget, reason: 'the brass box, shut');
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
        expect(find.descendant(of: find.byKey(const ValueKey('lock-slot-2')), matching: find.text('E')), findsOneWidget, reason: 'dragged into the third slot');
        expect(find.text('E'), findsNWidgets(2), reason: 'the letter shows in the box\'s own slot too');
        // A real word, the wrong one: ITEM.
        for (final l in ['I', 'T', 'M']) {
          await t.tap(find.bySemanticsLabel('Letter $l'));
          await t.pump(const Duration(milliseconds: 150));
        }
        expect(open, findsWidgets);
        await Scrollable.ensureVisible(t.element(find.byKey(const ValueKey('lock-box-shut'))));
        await t.pump();
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
        await tapText(t, 'OPEN THE LOCK', after: const Duration(milliseconds: 1200));
        await shot('final_opening');
        await wait(t, const Duration(milliseconds: 2400)); // the lock gives, the box opens
        await shot('final_open');
        expect(find.text('The box clicks open!'), findsOneWidget);
        expect(find.byKey(const ValueKey('lock-box-open')), findsOneWidget);
        expect(find.byKey(const ValueKey('lock-box-shut')), findsNothing);
        // The painting first: the case goes on once its back is read.
        expect(find.text('CONTINUE INVESTIGATION'), findsNothing);
        await tapText(t, 'LOOK INSIDE THE BOX', after: const Duration(milliseconds: 700));
        expect(find.byKey(const ValueKey('found-front')), findsOneWidget);
        await shot('final_painting');
        await tapText(t, 'TURN IT OVER', after: const Duration(milliseconds: 1000));
        expect(find.text('FIND THE PAINTER.'), findsOneWidget);
        // The ticket from M2: the same church.
        expect(find.byKey(const ValueKey('evidence-link-s2_ep01_e2')), findsOneWidget);
        await shot('final_painting_back');
        await t.tap(find.byKey(const ValueKey('evidence-link-s2_ep01_e2')));
        await wait(t, const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('evidence-print-s2_ep01_e2')), findsOneWidget, reason: 'the ticket, whole');
        expect(find.byKey(const ValueKey('evidence-link-s2_ep01_e4')), findsOneWidget, reason: 'and back to the painting');
        await shot('final_ticket_again');
        await tapText(t, 'CLOSE', after: const Duration(milliseconds: 600));
        await tapText(t, 'BACK TO THE BOX', after: const Duration(milliseconds: 600));
        expect(ref.read(gameControllerProvider).hasExamined('s2_ep01_final:painting'), isTrue);

        // ── The scene after the case, then CASE CLOSED ──────────────
        // The scene after the case, over the box opened.
        await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 1000));
        expect(find.text('CASE 01 COMPLETE'), findsOneWidget);
        await t.tapAt(t.getCenter(find.byType(Scaffold).last));
        await wait(t, const Duration(milliseconds: 1200));
        expect(find.byKey(const ValueKey('scene-backdrop')), findsOneWidget, reason: 'the open box under the words');
        expect(find.text('Montmartre Painting'), findsOneWidget, reason: "the case's last evidence");
        await shot('final_scene');
        await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 3200));
        expect(path(), Routes.solved);
        await shot('case_closed');
        expect(find.text('PARIS MYSTERY · FILE 01'), findsOneWidget);
        expect(find.byKey(const ValueKey('case-closed-emblem')), findsOneWidget, reason: 'the painting on the file');
        expect(find.text('On the back: FIND THE PAINTER.'), findsOneWidget);
        await wait(t, const Duration(milliseconds: 1500)); // the file lands, the footer comes in
        await reveal(t, find.text('Paris needs you again.'));
        await shot('case_closed_footer');
        expect(find.text('Paris needs you again.'), findsOneWidget);
        expect(find.text('London needs you again.'), findsNothing);
        // Case 02 is in the game: it is next, nothing COMING SOON.
        expect(find.text('OPEN CASE 02'), findsOneWidget);
        expect(find.textContaining('COMING SOON'), findsNothing, reason: 'Case 02 is open now');

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
        expect([for (final e in progress.collectedEvidence(paris)) e.name], ['Station Notice', 'Lost Ticket', "The Clockmaker's Mark", 'Montmartre Painting']);

        // The board: Case 02 is the case to begin now (its case is the
        // board's current one, so OPEN CASE 02 goes there).
        await tapText(t, 'OPEN CASE 02', after: const Duration(milliseconds: 3000));
        expect(path(), Routes.season);
        expect(ref.read(seasonOverviewProvider).currentCase?.id, 's2_ep02');
        await reveal(t, find.text('BEGIN INVESTIGATION'));
        await shot('board');
        expect(find.text('BEGIN INVESTIGATION'), findsOneWidget);
        expect(find.textContaining('COMING SOON'), findsNothing);
        expect(find.text('SEASON COMPLETE'), findsNothing);

        // Back to Season 1 and, from its completed board, GO TO PARIS
        // again: Paris's board (Case 01 solved), not its cover or opening.
        expect(ref.read(gameControllerProvider.notifier).openSeason(SeasonIds.london), isTrue);
        router.go(Routes.seasonOf(SeasonIds.london));
        await wait(t, const Duration(milliseconds: 2400));
        await t.tap(find.byKey(const ValueKey('begin-next-season')));
        await wait(t, const Duration(milliseconds: 2400));
        expect(ref.read(selectedSeasonIdProvider), SeasonIds.paris);
        await reveal(t, find.text('BEGIN INVESTIGATION'));
        expect(find.text('BEGIN INVESTIGATION'), findsOneWidget, reason: 'its board, as left: Case 02 to begin');
        expect(find.text('CASES SOLVED'), findsOneWidget, reason: 'no cover again');
        await wait(t, const Duration(seconds: 3));
      });
    }
  });
}
