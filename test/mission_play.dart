import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/core/utils/audio_service.dart';
import 'package:world_mystery/data/mock/season1/season1_deductions.dart';
import 'package:world_mystery/data/mock/season1/season1_decodes.dart';
import 'package:world_mystery/data/models/scene_deduction.dart';
import 'package:world_mystery/data/models/scene_decode.dart';
import 'package:world_mystery/data/mock/season1/season1_clocks.dart';
import 'package:world_mystery/data/mock/season1/season1_dialogues.dart';
import 'package:world_mystery/data/mock/season1/season1_explores.dart';
import 'package:world_mystery/data/mock/season1/season1_inspections.dart';
import 'package:world_mystery/data/models/scene_explore.dart';
import 'package:world_mystery/data/models/scene_inspect.dart';
import 'package:world_mystery/data/mock/season1/season1_investigations.dart';
import 'package:world_mystery/data/mock/season1/season1_trails.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_providers.dart' show sharedPreferencesProvider;
import 'package:world_mystery/widgets/letter_card.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';

/// Presses [f] as a finger does: down, held a moment (the button draws its
/// press), then up. A page with nothing moving draws no frame between a
/// tester's instant tap down and up; a real press always draws one.
Future<void> press(WidgetTester t, Finder f, {Duration after = const Duration(milliseconds: 600)}) async {
  await reveal(t, f);
  final g = await t.startGesture(t.getCenter(f.last));
  await t.pump(const Duration(milliseconds: 80));
  await g.up();
  await wait(t, after);
}

/// Saved progress with [missionId]'s case open at that mission: the cases
/// before it solved, the missions before it in its case solved, and the
/// mission itself started ([started]: back on its puzzle) or not (at its
/// place).
Map<String, Object> prefsAt(List<Episode> season, String missionId, {bool started = true, String name = 'MINYOUNG', Difficulty? level}) {
  final e = season.firstWhere((e) => e.missions.any((m) => m.id == missionId));
  final before = e.missions.takeWhile((m) => m.id != missionId).map((m) => m.id).toList();
  final earlier = [for (final x in season) if (x.number < e.number) x];
  final start = DateTime.now().subtract(const Duration(minutes: 1));
  String progress(List<String> done, {bool solved = false, Map<String, DateTime> begun = const {}}) =>
      jsonEncode(GameProgress(
        detectiveName: name,
        introSeen: true,
        completedMissionIds: done,
        missionStartedAt: begun,
        startedAt: start,
        completedAt: solved ? start : null,
        playMillis: 0,
      ).toJson());
  return {
    for (final x in earlier)
      AppConstants.progressKeyFor(x.id): progress([for (final m in x.allMissions) m.id], solved: true),
    if (e.id != AppConstants.currentEpisodeId)
      AppConstants.progressStorageKey: jsonEncode(GameProgress(detectiveName: name).toJson()),
    AppConstants.progressKeyFor(e.id): progress(before, begun: started ? {missionId: start} : const {}),
    AppConstants.seasonStorageKey: jsonEncode(
      level == null
          ? SeasonProgress(activeEpisodeId: e.id, solvedEpisodeIds: [for (final x in earlier) x.id]).toJson()
          : SeasonProgress(activeEpisodeId: e.id, solvedEpisodeIds: [for (final x in earlier) x.id], difficulty: level).toJson(),
    ),
  };
}

/// Plays one regular mission of Season 1 in the real app: opens it at its
/// puzzle (earlier cases and missions solved) and answers it through its own
/// puzzle, as a child would.
class MissionPlay {
  MissionPlay({this.audio});

  /// The sounds the app plays (a fresh silent one when not given).
  final MockAudioService? audio;

  final season = MockEpisodeRepository.bundled();
  late WidgetRef ref;

  Episode caseOf(String missionId) => season.firstWhere((e) => e.missions.any((m) => m.id == missionId));

  String path() => ref.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

  /// [missionId] open at its puzzle: earlier cases solved, the missions
  /// before it solved.
  Future<Mission> openPuzzle(WidgetTester t, Size size, String missionId, {double textScale = 1, Difficulty? level}) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    t.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    final e = caseOf(missionId);
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(audio: audio, prefs: prefsAt(season, missionId, level: level)),
      child: RepaintBoundary(
        key: const ValueKey('shot'),
        child: Consumer(builder: (context, r, _) {
          ref = r;
          return const WorldMysteryApp();
        }),
      ),
    ));
    await wait(t, const Duration(milliseconds: 300));
    ref.read(routerProvider).go(Routes.mission(missionId));
    await wait(t, const Duration(milliseconds: 1200));
    expect(
        find.text('CHECK ANSWER').evaluate().isNotEmpty ||
            find.text('UNLOCK').evaluate().isNotEmpty ||
            find.byKey(const ValueKey('investigation-picture')).evaluate().isNotEmpty ||
            find.byKey(const ValueKey('talk-panel')).evaluate().isNotEmpty ||
            find.byKey(const ValueKey('clock-dial')).evaluate().isNotEmpty ||
            find.byKey(const ValueKey('explore-picture')).evaluate().isNotEmpty ||
            find.byKey(const ValueKey('inspect-room')).evaluate().isNotEmpty ||
            find.byKey(const ValueKey('deduction-picture')).evaluate().isNotEmpty ||
            find.byKey(const ValueKey('decode-picture')).evaluate().isNotEmpty,
        isTrue,
        reason: '$missionId: at its puzzle');
    return e.missionById(missionId)!;
  }

  /// Answers [m] through its own puzzle, as a child would; stops as the
  /// Discovery Moment opens.
  Future<void> solve(WidgetTester t, Mission m) async {
    // A talk: hear the two statements that match and what is still to be
    // found after, then choose the two (judged at once, Wave 2.5.1), and go
    // on.
    final talk = dialogueOf(m);
    if (talk != null) {
      String speakerOf(String statement) => talk.statement(statement).speakerId;
      for (final s in [...talk.deduction.pair, ...talk.deduction.then]) {
        // Arriving, the witnesses are their prints; talking, their faces.
        final lineup = find.byKey(ValueKey('lineup-${speakerOf(s)}'));
        // From a print, the portrait flies in first and the questions follow.
        final arriving = lineup.evaluate().isNotEmpty;
        await tapKey(
          t,
          arriving ? 'lineup-${speakerOf(s)}' : 'speaker-${speakerOf(s)}',
          after: Duration(milliseconds: arriving ? 900 : 400),
        );
        await tapKey(t, 'question-${talk.statement(s).about}');
      }
      await tapKey(t, 'compare-statements', after: const Duration(milliseconds: 600));
      for (final s in talk.deduction.pair) {
        await tapKey(t, 'pick-$s');
      }
      await wait(t, const Duration(milliseconds: 2800));
      // Everything found: DESCRIPTION RECORDED, then CONTINUE (Wave 2.5.2).
      await tapKey(t, 'continue-investigation', after: const Duration(milliseconds: 600));
      await wait(t, const Duration(milliseconds: 800));
      return;
    }
    // A searched place: each thing found where its report line says.
    final scene = investigationOf(m);
    if (scene != null) {
      for (final f in scene.finds) {
        await tapInPicture(t, f.areas.first.center);
        await closeFindCard(t);
      }
      await wait(t, const Duration(milliseconds: 1200));
      return;
    }
    // A look round: the letter found and opened, then the answer chosen
    // where the choice is.
    final explore = exploreOf(m);
    if (explore != null) {
      await readExploreDocument(t, explore);
      await chooseInExplore(t, explore, m.answer);
      return;
    }
    // Exhibits under the glass: the match examined, its label read, the
    // word written.
    final inspect = inspectionOf(m);
    if (inspect != null) {
      await openInspectLabel(t, inspect);
      await writeOnLabel(t, m.answer);
      return;
    }
    // A place read for its traces: each clue noted, then the answer's place
    // chosen in the picture and searched.
    final deduction = deductionOf(m);
    if (deduction != null) {
      await noteClues(t, deduction);
      await chooseAndSearch(t, deduction, m.answer);
      return;
    }
    // A thing to examine: tapped, its code examined, then taken.
    final decode = decodeOf(m);
    if (decode != null) {
      await examineAndTake(t, decode);
      return;
    }
    // A clock: its hands set to the answer, then SET THE TIME.
    final clock = clockPuzzleOf(m);
    if (clock != null) {
      final answer = m.answer;
      await setClock(t, int.parse(answer.substring(0, answer.length - 2)), int.parse(answer.substring(answer.length - 2)),
          from: (clock.start.hour % 12) * 60 + clock.start.minute);
      await tapKey(t, 'clock-submit');
      return;
    }
    // A trail: its traces tapped in the answer's order, then CHECK ANSWER.
    final trail = trailOf(m);
    if (trail != null) {
      for (final id in Mission.sequenceIds(m.answer)) {
        await tapKey(t, 'trail-$id', after: const Duration(milliseconds: 150));
      }
      await tapKey(t, 'trail-check');
      return;
    }
    switch (m.type) {
      case MissionType.multipleChoice:
        await tapText(t, m.answerLabel, after: const Duration(milliseconds: 200));
      case MissionType.imageChoice:
        final i = m.options.indexWhere((o) => o.id == m.answer);
        // Named ("Picture D, …") or, names hidden, described ("Picture D: …").
        final picture = m.hideOptionNames
            ? find.bySemanticsLabel(RegExp('^Picture ${String.fromCharCode(65 + i)}: '))
            : find.bySemanticsLabel('Picture ${String.fromCharCode(65 + i)}, ${m.answerLabel}');
        await reveal(t, picture);
        await t.tap(picture);
        await wait(t, const Duration(milliseconds: 200));
      case MissionType.wordInput:
        await reveal(t, find.byType(TextField));
        await t.enterText(find.byType(TextField), m.answer);
        await t.pump();
      case MissionType.numberCode:
        for (final d in m.answer.split('')) {
          await tapText(t, d, after: const Duration(milliseconds: 120));
        }
        await tapText(t, 'UNLOCK', after: const Duration(milliseconds: 400));
        return;
      case MissionType.sequence:
        for (final id in Mission.sequenceIds(m.answer)) {
          final tile = find.text(m.options.firstWhere((o) => o.id == id).label).last;
          await reveal(t, tile);
          await t.tap(tile);
          await t.pump(const Duration(milliseconds: 150));
        }
      case MissionType.letterLock:
        // Each letter of the word, tapped from the loose tiles into the next slot.
        for (final letter in m.answer.split('')) {
          final tile = find.bySemanticsLabel('Letter $letter');
          await reveal(t, tile);
          await t.tap(tile.first);
          await t.pump(const Duration(milliseconds: 150));
        }
        await tapText(t, 'OPEN THE LOCK', after: const Duration(milliseconds: 400));
        return;
      case MissionType.examine || MissionType.finalCode:
        fail('not used here');
      // Played on their pictures (Paris Case 02 only): played through in
      // `paris_case02_test.dart`, never by this Season 1 helper.
      case MissionType.spotDifferences ||
          MissionType.matchPairs ||
          MissionType.revealLayer ||
          MissionType.canvasChoice:
        fail('${m.type} is played on its pictures: see paris_case02_test.dart');
    }
    await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 400));
  }

  /// Sets a clock's hands to [hour]:[minute] with its HOUR and MINUTE keys,
  /// from [from] (minutes since 12:00 shown now): the hours forward, then
  /// the minutes forward (minutes stepped past the hour would move it too).
  Future<void> setClock(WidgetTester t, int hour, int minute, {int from = 0}) async {
    final hours = ((hour % 12) - from ~/ 60 + 12) % 12;
    final minutes = minute - from % 60;
    for (var i = 0; i < hours; i++) {
      await tapKey(t, 'clock-hour-plus', after: const Duration(milliseconds: 60));
    }
    for (var i = 0; i < minutes.abs(); i++) {
      await tapKey(t, minutes > 0 ? 'clock-minute-plus' : 'clock-minute-minus', after: const Duration(milliseconds: 60));
    }
  }

  /// Where [point] (fractions of a place read for its traces) is on screen,
  /// as the picture is shown now (enlarged or moved).
  Offset deductionAt(WidgetTester t, Offset point) {
    final box = t.getRect(find.byKey(const ValueKey('deduction-picture')));
    return Offset(box.left + point.dx * box.width, box.top + point.dy * box.height);
  }

  /// Taps a place read for its traces at [point] (fractions of the picture).
  Future<void> tapDeduction(WidgetTester t, Offset point, {Duration after = const Duration(milliseconds: 400)}) async {
    await t.tapAt(deductionAt(t, point));
    await wait(t, after);
  }

  /// Every clue of [scene] tapped (and so noted), in order.
  Future<void> noteClues(WidgetTester t, DeductionScene scene) async {
    for (final c in scene.clues) {
      await tapDeduction(t, c.areas.first.center);
    }
  }

  /// The place of [optionId] chosen in the picture, then searched.
  Future<void> chooseAndSearch(WidgetTester t, DeductionScene scene, String optionId) async {
    await tapDeduction(t, scene.placeOf(optionId).areas.first.center);
    await tapKey(t, 'deduction-search', after: const Duration(milliseconds: 400));
  }

  /// Where [point] (fractions of a thing's place) is on screen, as the
  /// picture is shown now (the whole place, or the thing closer).
  Offset decodeAt(WidgetTester t, Offset point) {
    final box = t.getRect(find.byKey(const ValueKey('decode-picture')));
    return Offset(box.left + point.dx * box.width, box.top + point.dy * box.height);
  }

  /// Taps a thing's place at [point] (fractions of the picture).
  Future<void> tapDecode(WidgetTester t, Offset point, {Duration after = const Duration(milliseconds: 700)}) async {
    await t.tapAt(decodeAt(t, point));
    await wait(t, after);
  }

  /// [scene]'s thing tapped (brought closer), its code examined (the scan
  /// and the message appearing waited out), then taken.
  Future<void> examineAndTake(WidgetTester t, DecodeScene scene) async {
    await tapDecode(t, scene.areas.first.center);
    await tapKey(t, 'decode-examine', after: const Duration(milliseconds: 2800));
    await tapKey(t, 'decode-take', after: const Duration(milliseconds: 400));
  }

  /// Where [point] (fractions of the examined room's picture) is on screen.
  Offset inspectAt(WidgetTester t, Offset point) {
    final box = t.getRect(find.byKey(const ValueKey('inspect-picture')));
    return Offset(box.left + point.dx * box.width, box.top + point.dy * box.height);
  }

  /// Taps the examined room at [point] (fractions): the glass is carried
  /// there and what is under it examined.
  Future<void> tapInspect(WidgetTester t, Offset point, {Duration after = const Duration(milliseconds: 500)}) async {
    await t.tapAt(inspectAt(t, point));
    await wait(t, after);
  }

  /// Drags the glass from [from] to [to] (fractions), in small steps, then
  /// lifts the finger (what is under it is examined), or keeps it down
  /// ([lift] false: the gesture is returned, to lift later).
  Future<TestGesture> dragGlass(WidgetTester t, Offset from, Offset to, {int steps = 12, bool lift = true}) async {
    final g = await t.startGesture(inspectAt(t, from));
    await t.pump();
    for (var i = 1; i <= steps; i++) {
      await g.moveTo(inspectAt(t, Offset.lerp(from, to, i / steps)!));
      await t.pump(const Duration(milliseconds: 16));
    }
    if (lift) {
      await g.up();
      await wait(t, const Duration(milliseconds: 500));
    }
    return g;
  }

  /// [scene]'s match examined (a tap), then its label opened.
  Future<void> openInspectLabel(WidgetTester t, InspectScene scene) async {
    await tapInspect(t, scene.match.areas.first.center);
    await tapKey(t, 'inspect-read-label', after: const Duration(milliseconds: 500));
  }

  /// [word] written on the open label, then CHECK ANSWER.
  Future<void> writeOnLabel(WidgetTester t, String word) async {
    final field = find.descendant(of: find.byKey(const ValueKey('inspect-label')), matching: find.byType(TextField));
    await reveal(t, field);
    await t.enterText(field, word);
    await t.pump();
    await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 400));
  }

  /// Where [point] (fractions of a looked-round picture) is on screen, as
  /// the picture is shown now (enlarged or moved).
  Offset exploreAt(WidgetTester t, Offset point) {
    final box = t.getRect(find.byKey(const ValueKey('explore-picture')));
    return Offset(box.left + point.dx * box.width, box.top + point.dy * box.height);
  }

  /// Taps a looked-round picture at [point] (fractions of the picture).
  Future<void> tapExplore(WidgetTester t, Offset point, {Duration after = const Duration(milliseconds: 500)}) async {
    await t.tapAt(exploreAt(t, point));
    await wait(t, after);
  }

  /// The letter still in its sealed envelope (open, it is a letter card).
  Finder sealedLetter() {
    final envelope = find.byType(EnvelopeReveal);
    final open = find.descendant(of: envelope, matching: find.byType(LetterCard));
    return envelope.evaluate().isNotEmpty && open.evaluate().isEmpty ? envelope : find.byKey(const ValueKey('no-sealed-letter'));
  }

  /// Opens [scene]'s document where it is (its sealed envelope opened),
  /// then goes back to looking.
  Future<void> readExploreDocument(WidgetTester t, ExploreScene scene) async {
    await tapExplore(t, scene.document!.areas.first.center);
    final sealed = sealedLetter();
    if (sealed.evaluate().isNotEmpty) {
      await reveal(t, sealed);
      await t.tap(sealed);
      await wait(t, const Duration(milliseconds: 1200));
    }
    await tapKey(t, 'explore-close', after: const Duration(milliseconds: 500));
  }

  /// Opens [scene]'s choice, picks [optionId] and checks it.
  Future<void> chooseInExplore(WidgetTester t, ExploreScene scene, String optionId) async {
    if (find.byKey(const ValueKey('explore-choice')).evaluate().isEmpty) {
      final choice = scene.spots.firstWhere((s) => s.kind == ExploreKind.choice);
      await tapExplore(t, choice.areas.first.center);
    }
    await tapKey(t, 'poster-$optionId', after: const Duration(milliseconds: 200));
    await tapKey(t, 'explore-check', after: const Duration(milliseconds: 400));
  }

  /// Where [point] (fractions of the search picture) is on screen, as the
  /// picture is shown now (enlarged or moved).
  Offset pictureAt(WidgetTester t, Offset point) {
    final picture = find.byKey(const ValueKey('investigation-picture'));
    final box = t.getRect(find.descendant(of: picture, matching: find.byType(GestureDetector)).first);
    return Offset(box.left + point.dx * box.width, box.top + point.dy * box.height);
  }

  /// Taps the widget keyed [key] (scrolled into view first).
  Future<void> tapKey(WidgetTester t, String key, {Duration after = const Duration(milliseconds: 400)}) async {
    final f = find.byKey(ValueKey(key));
    await reveal(t, f);
    await t.tap(f.last);
    await wait(t, after);
  }

  /// Taps the search picture at [point] (fractions of the picture), then
  /// waits out the double-tap window (a single tap counts after it) and
  /// what the tap shows.
  Future<void> tapInPicture(WidgetTester t, Offset point) async {
    await t.tapAt(pictureAt(t, point));
    await wait(t, const Duration(milliseconds: 700));
  }

  /// Closes the card of a thing just found (a tap once it has settled).
  Future<void> closeFindCard(WidgetTester t) async {
    await wait(t, const Duration(milliseconds: 400));
    await t.tap(find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('find-card-')));
    await wait(t, const Duration(milliseconds: 300));
  }

  /// The app closed and opened again on the same saved progress.
  Future<void> restart(WidgetTester t) async {
    final prefs = await testOverrides(prefs: {
      for (final k in (await _saved()).entries) k.key: k.value,
    });
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(ProviderScope(
      overrides: prefs,
      child: RepaintBoundary(
        key: const ValueKey('shot'),
        child: Consumer(builder: (context, r, _) {
          ref = r;
          return const WorldMysteryApp();
        }),
      ),
    ));
    await wait(t, const Duration(milliseconds: 1200));
  }

  Future<Map<String, Object>> _saved() async {
    final p = ref.read(sharedPreferencesProvider);
    return {for (final k in p.getKeys()) k: p.get(k)!};
  }
}
