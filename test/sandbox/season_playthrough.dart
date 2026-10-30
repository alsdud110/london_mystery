import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/case_talk.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/data/models/scene_explore.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/result/case_solved_screen.dart';
import 'package:world_mystery/features/season/season_overview.dart';

import '../full_playthrough_test.dart' show reveal, tapText, wait;
import '../helpers.dart';
import '../mission_play.dart';
import 's9_ep03_test.dart' show hearAndCompare;
import 'sandbox_play.dart';

/// The screens every look round is played on again.
const screens = [
  ('the smallest phone (320x568)', Size(640, 1136), 2.0),
  ('a small phone (375x667)', Size(750, 1334), 2.0),
  ('a tall narrow phone (393x873)', Size(1080, 2400), 2.75),
  ('a tablet (1024x1366)', Size(2048, 2732), 2.0),
];

/// A season made from its plans (the Rome integration: Rome on), played in
/// the real app as the game has it, whatever its city: every case in order
/// from its Story Intro, every mission from the map on its own place's
/// picture (talks, letters, witnesses, look rounds, picture choices), a
/// wrong answer and a hint in every case, no picture choice's right picture
/// shown before its choice page, every Discovery Moment, each final and its
/// ending, the report, the next case opened by it, the save kept across
/// restarts, the season complete after its last case and a solved case
/// opened again; then every look round on four screens. A new season gets
/// these tests by being generated (`generated_seasons_test.dart`).
///
/// At [level] (PART 3: Rookie, Junior, Master): the detective is made at
/// it, as registration makes one, and the game picks the level's words by
/// itself (`playedEpisodesProvider`, `SeasonCatalog`'s tables at the
/// mission's level). Every line expected is the level's; the same lines of
/// the other levels, where theirs differ, are never on screen.
void seasonPlaythroughTests(String seasonId, {Difficulty level = Difficulty.standard}) {
  final content = SeasonCatalog.byId(seasonId)!;
  final base = [for (final json in content.episodes.values) Episode.fromJson({...json, 'seasonId': seasonId})];
  Mission? at(List<Episode> cases, String missionId) => [for (final e in cases) ...e.allMissions].where((m) => m.id == missionId).firstOrNull;

  /// The cases as the game plays them at [level]: its words, the base's game.
  final episodes = [for (final e in base) DifficultyContent.episodeAt(e, level)];
  final finale = DifficultyContent.seasonAt(content, level);

  /// The cases at the other levels, for the lines that may not be shown.
  final others = {
    for (final l in Difficulty.values)
      if (l != level) l: [for (final e in base) DifficultyContent.episodeAt(e, l)],
  };

  /// None of [theirs]' lines at any other level on screen, but where
  /// [mine] (the level's own lines here) says the same.
  void onlyMine(String where, Iterable<String> mine, Iterable<String> Function(List<Episode> cases, Difficulty l) theirs) {
    for (final MapEntry(key: l, value: cases) in others.entries) {
      for (final line in theirs(cases, l)) {
        if (line.trim().isEmpty || mine.any((m) => m.contains(line))) continue;
        expect(findReadableContaining(line), findsNothing, reason: '$where at ${level.label}: ${l.label}\'s "$line" on screen');
      }
    }
  }

  group('$seasonId played in the real app at ${level.label}', () {

    /// [c] plays the season at [level], in the very words of [episodes].
    void playsAt(ProviderContainer c) {
      expect(c.read(currentDifficultyProvider), level);
      final played = c.read(episodeCatalogProvider);
      expect([for (final e in played) e.id], [for (final e in episodes) e.id]);
      for (final (i, e) in played.indexed) {
        expect(jsonEncode(e.toJson()), jsonEncode(episodes[i].toJson()), reason: '${e.id}: the level\'s words');
        expect([for (final m in e.allMissions) m.difficulty], everyElement(level), reason: '${e.id}: its tables read at the level');
      }
    }

    Future<(ProviderContainer, SharedPreferences, Future<ProviderContainer> Function())> open(WidgetTester t, Size size, double ratio,
        {bool operator = false}) async {
      WidgetController.hitTestWarningShouldBeFatal = true; // every tap must land
      addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
      t.view.physicalSize = size;
      t.view.devicePixelRatio = ratio;
      addTearDown(t.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      Future<ProviderContainer> start() async {
        final c = ProviderContainer(overrides: [...await testOverridesFor(prefs), operatorToolsAvailableProvider.overrideWithValue(true)]);
        addTearDown(c.dispose);
        c.read(seasonPreviewSwitchProvider.notifier).set(true); // opened without the season before it solved
        if (operator) c.read(operatorAccessSwitchProvider.notifier).set(true);
        return c;
      }

      final c = await start();
      final ctrl = c.read(gameControllerProvider.notifier);
      ctrl.createDetective('Kim', DetectiveAvatar.girl, difficulty: level);
      expect(ctrl.openSeason(seasonId), isTrue);
      playsAt(c);
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: const WorldMysteryApp()));
      await wait(t);
      return (c, prefs, start);
    }

    /// The app opened again on [c], at the map.
    Future<void> reopen(WidgetTester t, ProviderContainer c) async {
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: const WorldMysteryApp()));
      await wait(t);
      c.read(routerProvider).go(Routes.map);
      await wait(t, const Duration(milliseconds: 2500));
    }

    /// An image of [file] in the tree (as it is, or decoded smaller).
    Finder shown(String file) => find.byWidgetPredicate((w) {
      if (w is! Image) return false;
      final image = switch (w.image) {
        ResizeImage(:final imageProvider) => imageProvider,
        final other => other,
      };
      return image is AssetImage && image.assetName == file;
    });

    /// The right pictures of the picture choices not played yet: none may be
    /// on screen before its own choice page.
    final unrevealed = <String>{
      for (final e in episodes)
        for (final m in e.allMissions.where((m) => m.type == MissionType.imageChoice)) m.options.firstWhere((o) => o.id == m.answer).picture!,
    };
    void nothingGivenAway(String where) {
      for (final f in unrevealed) {
        expect(shown(f), findsNothing, reason: '$where: $f shown before its choice');
      }
    }

    Future<void> throughIntro(WidgetTester t, ProviderContainer c, SandboxPlay play, Episode e) async {
      c.read(routerProvider).go(Routes.intro);
      await wait(t, const Duration(milliseconds: 1500));
      await tapText(t, 'SKIP ›');
      for (final line in e.intro) {
        expect(findReadableContaining(line), findsWidgets, reason: '${e.id} intro "$line": ${play.texts()}');
      }
      onlyMine('${e.id} intro', e.intro, (cases, _) => cases.firstWhere((x) => x.id == e.id).intro);
      nothingGivenAway('${e.id} intro');
      await tapText(t, "I'M READY", after: const Duration(milliseconds: 2000));
    }

    /// The talk's lines, each read whole, then its finish.
    Future<void> hear(WidgetTester t, SandboxPlay play, TalkScene scene) async {
      for (final (i, line) in scene.opening.indexed) {
        if (find.text('READ ALL').evaluate().isNotEmpty) await tapText(t, 'READ ALL', after: const Duration(milliseconds: 300));
        expect(findReadableContaining(line.text), findsWidgets, reason: '${scene.id} line $i: ${play.texts()}');
        if (i < scene.opening.length - 1) await tapText(t, 'NEXT', after: const Duration(milliseconds: 300));
      }
      await tapText(t, scene.finishLabel, after: const Duration(milliseconds: 1200));
    }

    /// A choice's first wrong option the plan wrote a line for.
    ChoiceOption? wrongOf(Mission m) => m.options.where((o) => o.id != m.answer && (o.feedback ?? '').isNotEmpty).firstOrNull;

    /// Where the look round's picture is seen (its place between the panels).
    Rect view(WidgetTester t) => t.getRect(find.byType(InteractiveViewer));

    /// [point] (fractions of the picture) brought into the view first, as a
    /// child drags the picture when a hint opened makes its place shorter.
    Future<void> inView(WidgetTester t, MissionPlay engine, Offset point) async {
      final v = view(t).deflate(12);
      final at = engine.exploreAt(t, point);
      if (v.contains(at)) return;
      await t.dragFrom(v.center, v.center - at);
      await wait(t, const Duration(milliseconds: 600));
      expect(view(t).contains(engine.exploreAt(t, point)), isTrue, reason: 'dragged into view: $point');
    }

    /// The scale the look round opens at (1: the picture as wide as the screen).
    double openingScale(WidgetTester t) => t.widget<InteractiveViewer>(find.byType(InteractiveViewer)).transformationController!.value.getMaxScaleOnAxis();

    /// A look round from the map: the choice locked first, every place
    /// looked at, a miss, a hint, the document, a wrong picture, the right one.
    Future<void> lookRound(WidgetTester t, ProviderContainer c, SandboxPlay play, Mission m, {void Function(double scale, Rect view)? onOpen}) async {
      final engine = MissionPlay();
      final explore = SeasonCatalog.explore(m)!;
      await play.toPlace(m);
      nothingGivenAway('${m.id} place');
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      final talk = SeasonCatalog.talkMission(m);
      if (talk?.before case final before?) {
        // Case 10 M1: Livia at the fence first, then the look round.
        expect(find.byKey(const ValueKey('case-talk-goal')), findsOneWidget, reason: '${m.id}: the talk comes first: ${play.texts()}');
        await hear(t, play, before);
      }
      expect(find.byKey(const ValueKey('explore-picture')), findsOneWidget, reason: '${m.id}: ${play.texts()}');
      final image = find.descendant(of: find.byKey(const ValueKey('explore-picture')), matching: find.byType(Image));
      expect(((t.widget<Image>(image.first)).image as AssetImage).assetName, explore.picture);
      // Every place is in the view as it opens (the picture's place on
      // screen, under no panel), before anything is moved.
      final opening = view(t);
      onOpen?.call(openingScale(t), opening);
      for (final s in explore.spots) {
        final at = engine.exploreAt(t, s.areas.first.center);
        expect(opening.contains(at), isTrue, reason: '${m.id} ${s.id} at $at, view $opening');
      }
      final choice = explore.spots.firstWhere((s) => s.kind == ExploreKind.choice);
      await inView(t, engine, choice.areas.first.center);
      await engine.tapExplore(t, choice.areas.first.center);
      expect(findReadableContaining(choice.lockedLine), findsWidgets, reason: '${m.id} locked: ${play.texts()}');
      expect(find.byKey(const ValueKey('explore-choice')), findsNothing);
      for (final s in explore.spots.where((s) => s.kind == ExploreKind.note)) {
        await inView(t, engine, s.areas.first.center);
        await engine.tapExplore(t, s.areas.first.center);
        expect(findReadableContaining(s.line), findsWidgets, reason: '${m.id} ${s.id}: ${play.texts()}');
        await engine.tapKey(t, 'explore-close', after: const Duration(milliseconds: 500)); // its card closed
      }
      for (final o in explore.others) {
        await inView(t, engine, o.areas.first.center);
        await engine.tapExplore(t, o.areas.first.center);
        expect(findReadableContaining(o.line), findsWidgets, reason: '${m.id} ${o.label}: ${play.texts()}');
      }
      await tapText(t, 'Get a Free Hint', after: const Duration(milliseconds: 800));
      expect(c.read(gameControllerProvider).hintsFor(m.id), 1);
      expect(findReadableContaining(m.hints.first), findsWidgets, reason: '${m.id} hint: ${play.texts()}');
      onlyMine('${m.id} hint', [m.hints.first], (cases, _) => [at(cases, m.id)!.hints.first]);
      await inView(t, engine, explore.document!.areas.first.center);
      await engine.tapExplore(t, explore.document!.areas.first.center);
      if (engine.sealedLetter().evaluate().isNotEmpty) {
        await t.tap(engine.sealedLetter());
        await wait(t, const Duration(milliseconds: 1200));
      }
      expect(findReadableContaining(m.letter.split('\n').first), findsWidgets, reason: '${m.id} document: ${play.texts()}');
      onlyMine('${m.id} document', m.letter.split('\n'), (cases, _) => at(cases, m.id)!.letter.split('\n'));
      await engine.tapKey(t, 'explore-close', after: const Duration(milliseconds: 500));
      final wrong = wrongOf(m)!;
      await inView(t, engine, choice.areas.first.center);
      await engine.chooseInExplore(t, explore, wrong.id);
      expect(find.text('Not quite!'), findsOneWidget, reason: play.texts());
      expect(findReadableContaining(wrong.feedback!), findsWidgets, reason: play.texts());
      onlyMine('${m.id} wrong', [wrong.feedback!], (cases, _) => [at(cases, m.id)!.options.firstWhere((o) => o.id == wrong.id).feedback ?? '']);
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
      if (find.byKey(const ValueKey('explore-choice')).evaluate().isEmpty) await inView(t, engine, choice.areas.first.center);
      await engine.chooseInExplore(t, explore, m.answer);
      if (talk?.after case final after?) {
        await wait(t, const Duration(milliseconds: 600));
        await hear(t, play, after);
      }
    }

    /// [m] from the map to its Discovery Moment, as its plan plays it, on
    /// its own place's picture. With [hint], the puzzle's first hint is
    /// opened before it is answered.
    Future<void> playMission(WidgetTester t, ProviderContainer c, SandboxPlay play, Mission m, {bool hint = false}) async {
      final talk = SeasonCatalog.talkMission(m);
      final place = content.places[m.place.key]!.file;
      expect(File(place).existsSync(), isTrue, reason: '${m.id}: $place');
      if (content.explores.containsKey(m.id)) {
        await lookRound(t, c, play, m);
      } else if (content.dialogues.containsKey(m.id)) {
        final witnesses = SeasonCatalog.dialogue(m)!;
        await play.toPlace(m);
        expect(shown(place), findsWidgets, reason: '${m.id}: its place\'s picture');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        // Each statement heard in the level's words.
        await hearAndCompare(t, MissionPlay(), witnesses, onHeard: (s) {
          expect(findReadableContaining(s.text), findsWidgets, reason: '${m.id} ${s.id}: ${play.texts()}');
          onlyMine('${m.id} ${s.id}', [s.text], (cases, _) => [SeasonCatalog.dialogue(at(cases, m.id)!)!.statement(s.id).text]);
        });
      } else {
        await play.toPlace(m);
        expect(shown(place), findsWidgets, reason: '${m.id}: its place\'s picture');
        nothingGivenAway('${m.id} place');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        if (talk?.before case final before?) {
          expect(find.byKey(const ValueKey('case-talk-goal')), findsOneWidget, reason: '${m.id}: the talk comes first: ${play.texts()}');
          nothingGivenAway('${m.id} talk');
          await hear(t, play, before);
        }
        nothingGivenAway('${m.id} letter');
        await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
        expect(findReadableContaining(m.letter.split('\n').first), findsWidgets, reason: '${m.id} letter: ${play.texts()}');
        onlyMine('${m.id} letter', m.letter.split('\n'), (cases, _) => at(cases, m.id)!.letter.split('\n'));
        nothingGivenAway('${m.id} letter open');
        await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
        expect(findReadable(m.question), findsOneWidget, reason: '${m.id}: ${play.texts()}');
        onlyMine('${m.id} question', [m.question], (cases, _) => [at(cases, m.id)!.question]);
        if (m.type == MissionType.imageChoice) {
          // The choice page: here, and only here, the right picture is first seen.
          for (final o in m.options) {
            expect(shown(o.picture!), findsOneWidget, reason: '${m.id} ${o.id}: its picture on screen');
          }
          unrevealed.remove(m.options.firstWhere((o) => o.id == m.answer).picture);
        }
        if (hint) {
          final link = find.text('Get a Free Hint');
          await reveal(t, link);
          await tapText(t, 'Get a Free Hint', after: const Duration(milliseconds: 800));
          expect(c.read(gameControllerProvider).hintsFor(m.id), 1, reason: m.id);
          expect(findReadableContaining(m.hints.first), findsWidgets, reason: '${m.id} hint: ${play.texts()}');
          onlyMine('${m.id} hint', [m.hints.first], (cases, _) => [at(cases, m.id)!.hints.first]);
          if (find.text('CLOSE').evaluate().isNotEmpty) await tapText(t, 'CLOSE', after: const Duration(milliseconds: 500));
        }
        if (m.type == MissionType.multipleChoice || m.type == MissionType.imageChoice) {
          if (wrongOf(m) case final wrong?) await play.wrong(m, wrong.id, line: wrong.feedback);
        }
        await play.answer(m, m.answer);
        if (talk?.after case final after?) {
          await wait(t, const Duration(milliseconds: 600));
          await hear(t, play, after);
        }
      }
      if (content.discoveries.containsKey(m.id)) {
        final d = SeasonCatalog.discovery(m);
        await wait(t, const Duration(milliseconds: 1500));
        expect(findReadableContaining(d.title), findsWidgets, reason: '${m.id} discovery: ${play.texts()}');
        onlyMine('${m.id} discovery', [d.title], (cases, _) => [SeasonCatalog.discovery(at(cases, m.id)!).title]);
      }
      expect(c.read(gameControllerProvider).isCompleted(m.id), isTrue, reason: m.id);
    }

    /// The final, its ending, the case closed, its report.
    Future<void> playFinal(WidgetTester t, ProviderContainer c, SandboxPlay play, Episode e, {required bool last}) async {
      final fin = e.finalMission;
      await play.toFinal(fin);
      await play.answer(fin, fin.answer);
      await wait(t, const Duration(milliseconds: 1500));
      expect(find.byKey(const ValueKey('final-ending')), findsOneWidget, reason: '${e.id}: ${play.texts()}');
      final ending = SeasonCatalog.caseEnding(fin)!;
      for (final (i, line) in ending.indexed) {
        if (find.text('READ ALL').evaluate().isNotEmpty) await tapText(t, 'READ ALL', after: const Duration(milliseconds: 300));
        expect(findReadableContaining(line.text), findsWidgets, reason: '${e.id} ending line $i: ${play.texts()}');
        onlyMine('${e.id} ending line $i', [for (final l in ending) l.text], (cases, _) => [SeasonCatalog.caseEnding(at(cases, fin.id)!)![i].text]);
        if (i < ending.length - 1) await tapText(t, 'NEXT', after: const Duration(milliseconds: 600));
      }
      await tapText(t, 'CLOSE THE CASE', after: const Duration(milliseconds: 1500));
      expect(c.read(gameControllerProvider).isCaseSolved, isTrue, reason: e.id);
      if (!last) expect(find.text('CASE ${e.numberLabel} COMPLETE'), findsOneWidget, reason: play.texts());
      await t.tapAt(t.getCenter(find.byType(Scaffold).last));
      await wait(t, const Duration(milliseconds: 1200));
      await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 3200));
      expect(find.byType(CaseSolvedScreen), findsOneWidget, reason: e.id);
      expect(find.text('CASE CLOSED'), findsOneWidget, reason: play.texts());
    }

    testWidgets('the whole season in order on a phone: Cases 01 to 12, every mission from the map, each final and ending, '
        'saves kept across restarts, the season complete, a solved case opened again', (t) async {
      var (c, prefs, start) = await open(t, const Size(1170, 2532), 3);
      final play = SandboxPlay(t);
      SeasonNotifier season() => c.read(seasonProvider.notifier);
      // A case written at the level plays its own words, never the base's;
      // its game (answers, options, hints, order) is the base's at every level.
      for (final (i, e) in episodes.indexed) {
        expect(DifficultyContent.structureOfEpisode(e), DifficultyContent.structureOfEpisode(base[i]), reason: '${e.id}: the same game');
        if (level == Difficulty.rookie || !(content.writtenLevels[e.id]?.contains(level) ?? false)) continue;
        expect(jsonEncode(e.toJson()), isNot(jsonEncode(base[i].toJson())), reason: '${e.id}: written at ${level.label}');
      }

      for (final (n, e) in episodes.indexed) {
        expect(season().isUnlocked(e.id), isTrue, reason: '${e.id} opened by the case before it');
        if (n + 1 < episodes.length) expect(season().isUnlocked(episodes[n + 1].id), isFalse, reason: '${episodes[n + 1].id} still sealed');
        expect(c.read(gameControllerProvider.notifier).openEpisode(e.id), isTrue, reason: e.id);
        await throughIntro(t, c, play, e);
        // A hint in every case: in its look round, else on its first puzzle page.
        final hintAt = e.missions.where((m) => !content.dialogues.containsKey(m.id)).first;
        for (final (i, m) in e.missions.indexed) {
          await playMission(t, c, play, m, hint: m == hintAt && !content.explores.containsKey(m.id));
          await play.onToMap(m);
          if (n == 0 && i == 0) {
            // ── A restart mid-case: Case 01 M1 is kept, M2 is next.
            final saved = savedString(prefs, AppConstants.progressKeyFor(e.id))!;
            expect((jsonDecode(saved) as Map)['completedMissionIds'], [m.id]);
            c = await start();
            expect(c.read(gameControllerProvider.notifier).openSeason(seasonId), isTrue);
            playsAt(c);
            expect(c.read(currentEpisodeProvider).id, e.id, reason: 'the open case is kept');
            expect(c.read(gameControllerProvider).completedMissionIds, [m.id]);
            await reopen(t, c);
          }
        }
        expect(c.read(gameControllerProvider).totalHints, greaterThanOrEqualTo(1), reason: '${e.id}: a hint taken');
        await playFinal(t, c, play, e, last: n == episodes.length - 1);
        expect(c.read(gameControllerProvider).completedMissionIds, [for (final m in e.allMissions) m.id], reason: e.id);
        expect(c.read(seasonProvider).solvedEpisodeIds, [for (final x in episodes.take(n + 1)) x.id]);
        if (n == 1 || n == episodes.length ~/ 2 - 1 || n == episodes.length - 3) {
          // ── A restart between cases (after Case 02, mid-season and three
          // before the end): the cases solved kept, the next one still open.
          c = await start();
          expect(c.read(gameControllerProvider.notifier).openSeason(seasonId), isTrue);
          playsAt(c);
          expect(c.read(seasonProvider).solvedEpisodeIds, [for (final x in episodes.take(n + 1)) x.id]);
          expect(season().isUnlocked(episodes[n + 1].id), isTrue, reason: 'still open after a restart');
          await reopen(t, c);
        }
      }

      // ── The season complete: said on the last report, with its last words.
      await reveal(t, find.byKey(const ValueKey('season-complete')));
      expect(find.text('${content.season.label} COMPLETE'), findsOneWidget, reason: play.texts());
      final lastWords = finale.finale.isEmpty ? finale.outro : finale.finale;
      for (final line in lastWords) {
        expect(findReadableContaining(line), findsWidgets, reason: 'the finale: ${play.texts()}');
      }
      onlyMine('the finale', lastWords, (_, l) {
        final s = DifficultyContent.seasonAt(content, l);
        return s.finale.isEmpty ? s.outro : s.finale;
      });
      expect(c.read(seasonOverviewProvider).complete, isTrue);
      expect(c.read(seasonOverviewProvider).solvedCount, episodes.length);
      expect(unrevealed, isEmpty, reason: 'every picture choice played');

      // ── Kept after a restart, and a solved case opened again: Case 03,
      // every mission still done, its report there to read.
      c = await start();
      expect(c.read(gameControllerProvider.notifier).openSeason(seasonId), isTrue);
      playsAt(c);
      expect(c.read(seasonProvider).solvedEpisodeIds, [for (final e in episodes) e.id]);
      expect(c.read(seasonOverviewProvider).complete, isTrue, reason: 'still complete after a restart');
      final again = episodes[2];
      expect(c.read(gameControllerProvider.notifier).openEpisode(again.id), isTrue);
      expect(c.read(currentEpisodeProvider).id, again.id);
      expect(c.read(gameControllerProvider).isCaseSolved, isTrue);
      expect(c.read(gameControllerProvider).completedMissionIds, [for (final m in again.allMissions) m.id]);
      await reopen(t, c);
      // Its map says it is solved, and its case file opens from there.
      expect(find.text('EVERY PLACE SOLVED'), findsOneWidget, reason: 'its map: ${play.texts()}');
      expect(find.text('CASE ${again.numberLabel}'), findsWidgets, reason: play.texts());
      await tapText(t, 'SEE MY CASE FILE', after: const Duration(milliseconds: 3200));
      expect(find.byType(CaseSolvedScreen), findsOneWidget, reason: '${again.id} case file: ${play.texts()}');
      expect(find.text('CASE CLOSED'), findsOneWidget, reason: play.texts());

      // ── Saved: each case its own; the other seasons' cases never written.
      for (final e in episodes) {
        expect(savedString(prefs, AppConstants.progressKeyFor(e.id)), isNotNull, reason: e.id);
      }
      for (final e in [for (final s in SeasonCatalog.all) if (s.id != seasonId) ...s.episodes.keys]) {
        expect(prefs.getKeys().where((k) => k.endsWith(AppConstants.progressKeyFor(e))), isEmpty, reason: '$e (another season) is never written');
      }
    });

    // Every look round on other screens: the smallest phone, a small phone,
    // a tall narrow phone, a tablet. Opened by operator access (test builds
    // only); the missions of its case before it played first.
    final scales = <String, double>{};
    tearDownAll(() {
      for (final MapEntry(:key, :value) in scales.entries) {
        // ignore: avoid_print
        print('opening scale  $key  ${value.toStringAsFixed(2)}');
      }
    });
    for (final (name, size, ratio) in screens) {
      for (final e in episodes) {
        for (final (i, m) in e.missions.indexed.where((x) => content.explores.containsKey(x.$2.id))) {
          testWidgets('${m.id} (a look round) on $name: every place on screen and reached by a tap, solved', (t) async {
            final (c, _, _) = await open(t, size, ratio, operator: true);
            final play = SandboxPlay(t);
            expect(c.read(gameControllerProvider.notifier).openEpisode(e.id), isTrue);
            await throughIntro(t, c, play, e);
            for (final before in e.missions.take(i)) {
              await playMission(t, c, play, before);
              await play.onToMap(before);
            }
            await lookRound(t, c, play, m, onOpen: (s, v) => scales['${m.id} $name'] = s);
            if (content.discoveries.containsKey(m.id)) {
              final d = SeasonCatalog.discovery(m);
              await wait(t, const Duration(milliseconds: 1500));
              expect(findReadableContaining(d.title), findsWidgets, reason: '${m.id} discovery: ${play.texts()}');
            }
            expect(c.read(gameControllerProvider).isCompleted(m.id), isTrue, reason: m.id);
          });
        }
      }
    }
  });
}
