import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/core/utils/answer_checker.dart';
import 'package:london_mystery/data/mock/season2/season2_learning.dart';
import 'package:london_mystery/data/mock/season_catalog.dart';
import 'package:london_mystery/data/models/discovery.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/learning.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/models/tower_puzzles.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/mission_map/map_world.dart';
import 'package:london_mystery/features/season/season_overview.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/game_button.dart';
import 'package:london_mystery/widgets/letter_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';

/// Season 2, Case 03 — The Tower's Secret: its thirteen pictures (the
/// padlock's windows and dial measured on them), its story and puzzles as
/// the papers say them, its rules (unlock, saves, the board), and a child
/// playing it through on three phones.
///
/// `LM_SHOTS=folder` saves a picture of each step of the play-through.
void main() {
  final inGame = MockEpisodeRepository.bundled();
  final s1 = season1Cases();
  final case01 = inGame.firstWhere((e) => e.id == 's2_ep01');
  final case02 = inGame.firstWhere((e) => e.id == 's2_ep02');
  final case03 = inGame.firstWhere((e) => e.id == 's2_ep03');
  final [m1, m2, m3, fin] = case03.allMissions;
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

  String everything(Episode e) => [
        ...e.intro,
        ...e.synopsis,
        ...e.objectives,
        e.hook,
        e.caseSummary,
        for (final m in e.allMissions) ...[
          m.title,
          m.location,
          m.letter,
          m.letterIntro,
          m.question,
          ...m.story,
          ...m.transition,
          ...m.hints,
          for (final o in m.options) o.label,
          for (final o in m.options) o.feedback ?? '',
          ...m.feedback.values,
          m.orderFeedback ?? '',
          m.clue?.note ?? '',
          m.evidence?.description ?? '',
          m.evidence?.inscription ?? '',
        ],
      ].join('\n');

  group('its pictures', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const folder = 'assets/seasons/season_02_paris/cases/case_03';
    // Size, and whether it is cut out on transparency.
    const pictures = {
      'eiffel_tower_exterior.png': (1024, 1536, false),
      'tower_notice_board.png': (1536, 1024, false),
      'inspection_log.png': (1254, 1254, true),
      'tower_lift.png': (1536, 1024, false),
      'lift_route_diagram.png': (1024, 1536, true),
      'lift_log.png': (1254, 1254, true),
      'service_door.png': (1536, 1024, false),
      'mechanical_lock.png': (1536, 1024, true),
      'lock_dial.png': (1254, 1254, true),
      'service_room.png': (1536, 1024, false),
      'time_recording_machine.png': (1536, 1024, false),
      'time_recording_machine_open.png': (1536, 1024, false),
      'brass_plaque.png': (1536, 1024, true),
    };

    (int, int, bool) header(Uint8List b) {
      final d = ByteData.sublistView(b);
      final colourType = b[25];
      return (d.getUint32(16), d.getUint32(20), colourType == 4 || colourType == 6);
    }

    Future<(ByteData, int)> pixels(String name) async {
      final codec = await ui.instantiateImageCodec(File('$folder/$name').readAsBytesSync());
      final image = (await codec.getNextFrame()).image;
      return ((await image.toByteData(format: ui.ImageByteFormat.rawRgba))!, image.width);
    }

    test('all thirteen are in, listed in pubspec, at their sizes, cut out where they are papers or parts', () {
      expect(pubspecAssets(), contains('$folder/'), reason: 'its folder, exactly, in flutter: assets:');
      for (final MapEntry(key: name, value: (w, h, cutOut)) in pictures.entries) {
        final file = File('$folder/$name');
        expect(file.existsSync(), isTrue, reason: name);
        final (pw, ph, alpha) = header(file.readAsBytesSync());
        expect((pw, ph), (w, h), reason: name);
        expect(alpha, cutOut, reason: name);
      }
      expect(File('$folder/pection_log.png').existsSync(), isFalse, reason: 'renamed to inspection_log.png');
    });

    test('every one of them is played on', () {
      final records = SeasonCatalog.records(m1)!;
      final lift = SeasonCatalog.lift(m2)!;
      final lock = SeasonCatalog.dialLock(m3)!;
      final board = SeasonCatalog.evidenceBoard(fin)!;
      final played = {
        for (final d in records.docs) d.file,
        lift.picture,
        lift.plate,
        lift.log,
        lock.lock,
        lock.dial,
        board.shut,
        board.open,
        board.plaque,
        for (final a in [Artwork.eiffelTower, Artwork.serviceDoor, Artwork.serviceRoom]) ArtAssets.scenes[a]!,
      };
      expect({for (final f in played) f.split('/').last}, {...pictures.keys});
      // The story's pictures name only the case's own (and Case 02's canvas back).
      expect(ArtAssets.scenes[Artwork.paintersMessage], endsWith('case_02/canvas_back.png'));
    });

    test('the padlock\'s windows are cut clean at their measured centres; the dial turns about its hole', () async {
      final scene = SeasonCatalog.dialLock(m3)!;
      final (lock, lockW) = await pixels('mechanical_lock.png');
      int alpha(ByteData b, int w, double x, double y) => b.getUint8((y.round() * w + x.round()) * 4 + 3);
      for (final c in scene.windows) {
        for (var a = 0.0; a < 2 * math.pi; a += math.pi / 8) {
          final inside = c + Offset(math.cos(a), math.sin(a)) * scene.windowRadius * 0.9;
          final outside = c + Offset(math.cos(a), math.sin(a)) * scene.windowRadius * 1.15;
          expect(alpha(lock, lockW, inside.dx, inside.dy), lessThan(10), reason: 'window $c open at $a');
          expect(alpha(lock, lockW, outside.dx, outside.dy), greaterThan(240), reason: 'bezel round $c at $a');
        }
      }
      // The dial's centre hole is round its pivot; shown 405 px round it,
      // it is all dial (no transparent rim shows in a window).
      final (dial, dialW) = await pixels('lock_dial.png');
      final p = scene.pivot;
      expect(alpha(dial, dialW, p.dx, p.dy), lessThan(10));
      for (var a = 0.0; a < 2 * math.pi; a += math.pi / 12) {
        final at = p + Offset(math.cos(a), math.sin(a)) * scene.showRadius;
        expect(alpha(dial, dialW, at.dx, at.dy), greaterThan(240), reason: 'dial under the window at $a');
      }
    });

    test('the machine, shut and open, is one picture but for its hatch', () async {
      final (shut, w) = await pixels('time_recording_machine.png');
      final (open, _) = await pixels('time_recording_machine_open.png');
      // Mean difference outside the hatch (x 640–1150, y 540–960) stays
      // small: no shift of the machine, only the hatch changes.
      double meanDiff(bool hatch) {
        var sum = 0.0, n = 0;
        for (var y = 0; y < 1024; y += 4) {
          for (var x = 0; x < 1536; x += 4) {
            final inHatch = x >= 640 && x < 1150 && y >= 540 && y < 960;
            if (inHatch != hatch) continue;
            final i = (y * w + x) * 4;
            for (var c = 0; c < 3; c++) {
              sum += (shut.getUint8(i + c) - open.getUint8(i + c)).abs();
            }
            n++;
          }
        }
        return sum / n;
      }

      final outside = meanDiff(false);
      final hatch = meanDiff(true);
      expect(outside, lessThan(30), reason: 'the machine stands still');
      expect(hatch, greaterThan(outside * 2), reason: 'the hatch is what changes');
    });
  });

  group('the case', () {
    test('Case 03 is in the game, after Case 02, at the Eiffel Tower, with its four puzzles', () {
      expect(SeasonCatalog.byId(SeasonIds.paris)!.episodes.keys.take(3), ['s2_ep01', 's2_ep02', 's2_ep03']);
      expect(case03.number, 3);
      expect(case03.title, "The Tower's Secret");
      expect(case03.place, 'EIFFEL TOWER · PARIS');
      expect(case03.introScene, Artwork.paintersMessage);
      expect([for (final m in case03.allMissions) m.id], ['s2_ep03_m1', 's2_ep03_m2', 's2_ep03_m3', 's2_ep03_final']);
      expect([for (final m in case03.allMissions) m.type],
          [MissionType.matchPairs, MissionType.multipleChoice, MissionType.sequence, MissionType.matchPairs]);
      expect(SeasonCatalog.records(m1), isNotNull);
      expect(SeasonCatalog.lift(m2), isNotNull);
      expect(SeasonCatalog.dialLock(m3), isNotNull);
      expect(SeasonCatalog.evidenceBoard(fin), isNotNull);
      expect([for (final m in case03.allMissions) m.evidence!.name],
          ['The Conflicting Notices', 'The Lift Log', 'The Service Room', 'The Brass Plaque']);
      // On the map: Case 03 at the Eiffel Tower, Case 04 on the Seine, Case 06 at the Louvre.
      expect(ParisLandmark.cases['s2_ep03'], ParisLandmark.eiffelTower);
      expect(ParisLandmark.cases['s2_ep04'], ParisLandmark.seineQuays);
      expect(ParisLandmark.cases['s2_ep06'], ParisLandmark.louvre);
      expect(SeasonMap.landmarkOf(m1.id), ParisLandmark.eiffelTower);
    });

    test('the opening follows the canvas\'s tower drawing, in the second person, and gives no time away', () {
      final opening = [...case03.intro, ...case03.synopsis, ...case03.objectives, ...m1.story, m1.letter, m1.letterIntro, m1.question];
      for (final line in opening) {
        for (final giveaway in ['3:00', '4:00', 'three', 'four', 'one hour']) {
          expect(line.toLowerCase(), isNot(contains(giveaway)), reason: line);
        }
        expect(RegExp(r"\bI\b|\bI'm\b|\bmy\b").hasMatch(line), isFalse, reason: 'second person: $line');
      }
      expect(case03.intro.first, contains('Always higher'));
      expect(case03.intro[1], contains('You turn the canvas over'));
      expect(case03.intro.join(' '), contains('The Eiffel Tower'));
      // Case 02's ending is as it was.
      expect(case02.finalMission.transition.last, 'But someone is still stealing the hours of Paris.');
      expect(case02.finalMission.transition[1], contains('TOUJOURS PLUS HAUT. Always higher.'));
    });

    test('M1: only the two times disagree; nothing but the times answers', () {
      final scene = SeasonCatalog.records(m1)!;
      final [notice, log] = scene.docs;
      for (final line in notice.lines) {
        final other = log.lines.firstWhere((l) => l.id == line.id);
        expect(other.value == line.value, line.id != 'time', reason: line.id);
      }
      expect(notice.lines.firstWhere((l) => l.id == 'time').value, '4:00 PM');
      expect(log.lines.firstWhere((l) => l.id == 'time').value, '3:00 PM');
      final ids = [for (final l in notice.lines) l.id];
      for (final a in ids) {
        for (final b in ids) {
          final pair = '$a:$b';
          expect(AnswerChecker.isCorrect(m1, pair), pair == 'time:time', reason: pair);
          if (pair != 'time:time') expect(AnswerChecker.feedbackFor(m1, pair), isNotNull, reason: pair);
        }
      }
      expect(m1.clue!.value, 'CHECK THE LIFT LOG.');
      expect(log.note, 'CHECK THE LIFT LOG.');
    });

    test('M2: the log alone cannot tell; with the plate only the Service Level fits', () {
      final scene = SeasonCatalog.lift(m2)!;
      final trip = scene.trips.firstWhere((t) => t.service);
      expect((trip.time, trip.from, trip.to), ('3:20', 'Second', '?'));
      expect(scene.trips.last.from, '?', reason: 'the return trip hides the same stop');
      // The log never says what S is, nor names the stop.
      final logWords = [scene.logTitle, for (final t in scene.trips) '${t.time} ${t.from} ${t.to}'].join(' ').toUpperCase();
      expect(logWords, isNot(contains('SERVICE')));
      expect(scene.legend, 'S = SERVICE RUN');
      // The stops a service run from Second can reach, by the plate.
      final from = scene.stops.firstWhere((s) => s.name.toLowerCase() == trip.from.toLowerCase());
      final reachable = [
        for (final s in scene.stops)
          if (s.service && scene.serviceRoute.contains(from.id) && scene.serviceRoute.contains(s.id)) s.id,
      ];
      expect(reachable, ['service']);
      // Every other option is a passenger stop.
      for (final o in m2.options) {
        final stop = scene.stops.firstWhere((s) => s.name.toLowerCase() == o.label.toLowerCase());
        expect(stop.service, o.id == m2.answer, reason: o.id);
        expect(scene.passengerRoute.contains(stop.id), o.id != m2.answer, reason: o.id);
        expect(AnswerChecker.isCorrect(m2, o.id), o.id == 'service');
        if (o.id != 'service') expect(o.feedback, isNotNull);
      }
    });

    test('M3: the note sets the order; no dial starts on its answer; the dials settle on their symbols', () {
      final scene = SeasonCatalog.dialLock(m3)!;
      expect(m3.letter, allOf(contains('First, check the clock.'), contains('Next, stop the lift.'), contains('Finally, turn the key.')));
      expect({for (final s in scene.symbols) s.id}, {for (final o in m3.options) o.id});
      final answer = Mission.sequenceIds(m3.answer);
      expect(answer, ['clock', 'lift', 'key']);
      for (var i = 0; i < scene.windows.length; i++) {
        expect(scene.symbols[scene.start[i]].id, isNot(answer[i]), reason: 'dial ${i + 1} starts off its answer');
      }
      expect(AnswerChecker.isCorrect(m3, 'clock,lift,key'), isTrue);
      expect(AnswerChecker.feedbackFor(m3, 'key,lift,clock'), m3.orderFeedback);
      expect(AnswerChecker.isCorrect(m3, [for (final i in scene.start) scene.symbols[i].id].join(',')), isFalse);
      // Each symbol settles under the pointer, from any whole turn.
      for (var i = 0; i < scene.symbols.length; i++) {
        for (final extra in [-2, -1, 0, 1]) {
          expect(scene.symbolAt(scene.turnFor(i) + extra * 2 * math.pi), i);
          // A little off still settles on it.
          expect(scene.symbolAt(scene.turnFor(i) + 0.3), i);
          expect(scene.symbolAt(scene.turnFor(i) - 0.3), i);
        }
      }
      // Each close-up is cut round its own symbol: its middle lies where
      // the symbol's angle says, on the dial's face.
      for (final s in scene.symbols) {
        final c = s.closeUp.center - scene.pivot;
        final angle = (math.atan2(c.dx, -c.dy) * 180 / math.pi) % 360;
        final gap = (angle - s.angle).abs() % 360;
        expect(math.min(gap, 360 - gap), lessThan(12), reason: s.id);
        expect(c.distance, lessThan(scene.showRadius), reason: '${s.id} is inside what a window shows');
      }
      // Saved and read back; anything unknown is the lock's start.
      expect(DialState.decode(DialState.encode([0, 2, 1]), scene), [0, 2, 1]);
      expect(DialState.decode('9,0,0', scene), scene.start);
      expect(DialState.decode(null, scene), scene.start);
    });

    test('Final: each question needs its own evidence; the discovery order and "an hour vanished" are wrong', () {
      final scene = SeasonCatalog.evidenceBoard(fin)!;
      Map<String, Set<String>> links(Map<String, List<String>> l) => {for (final e in l.entries) e.key: e.value.toSet()};
      final right = links({'q1': ['e1'], 'q2': ['e2'], 'q3': ['e3', 'e2']});
      expect(scene.answerOf(right, 'entered'), fin.answer);
      expect(AnswerChecker.isCorrect(fin, scene.answerOf(right, 'entered')), isTrue);
      // Linked in the order the evidence was found: question 3 is short of one.
      final inOrder = scene.answerOf(links({'q1': ['e1'], 'q2': ['e2'], 'q3': ['e3']}), 'entered');
      expect(AnswerChecker.isCorrect(fin, inOrder), isFalse);
      expect(AnswerChecker.feedbackFor(fin, inOrder), contains('what shows that someone went up there'));
      expect(AnswerChecker.feedbackFor(fin, scene.answerOf(right, 'vanished')), 'We have no proof of that yet.');
      expect(AnswerChecker.feedbackFor(fin, scene.answerOf(right, 'still')), isNotNull);
      // Every wrong way to link a question says something.
      final subsets = ['', 'e1', 'e2', 'e3', 'e1+e2', 'e1+e3', 'e2+e3', 'e1+e2+e3'];
      for (final q in ['q1', 'q2', 'q3']) {
        for (final s in subsets) {
          final part = '$q:$s';
          if (Mission.sequenceIds(fin.answer).contains(part)) continue;
          expect(fin.feedback[part], isNotNull, reason: part);
        }
      }
      expect([for (final c in scene.conclusions) c.text], [
        'Someone went into the service area in the hour the records do not agree on.',
        'An hour really vanished from Paris.',
        'The lift never moved.',
      ]);
      // The board's evidence is the case's own.
      final ids = {for (final m in case03.missions) m.evidence!.id};
      expect({for (final e in scene.evidence) e.evidenceId}, ids);
      // Saved and read back.
      final (l, c) = BoardState.decode(BoardState.encode(right, 'entered', scene), scene);
      expect(l, right);
      expect(c, 'entered');
      final (junk, none) = BoardState.decode('q9=e1;why=nope', scene);
      expect(junk, isEmpty);
      expect(none, isNull);
    });

    test('the plaque is a riddle, never proof; it points to the Seine', () {
      final scene = SeasonCatalog.evidenceBoard(fin)!;
      expect(scene.plaqueMessage, 'ONE HOUR IS MISSING.\nTHE CLOCK IS STILL RUNNING.');
      expect(scene.riverWord, 'SEINE');
      final all = everything(case03).toUpperCase();
      expect(all, isNot(contains('THREE MORE')));
      expect(all, isNot(contains('CLOCKMAKER')), reason: 'who he is stays untold');
      expect(fin.transition, containsAllInOrder(['One hour is missing.', 'The clock is still running.', 'SEINE.', 'And why does it lead to the river?']));
      // Before the solve, nothing says the message.
      for (final s in [...fin.story, fin.letter, ...fin.hints, ...m3.transition]) {
        expect(s.toUpperCase(), isNot(contains('SEINE')), reason: s);
        expect(s.toUpperCase(), isNot(contains('STILL RUNNING')), reason: s);
      }
    });

    test('every word in its glossary is in its text', () {
      final text = everything(case03).toLowerCase();
      for (final w in case03.glossary.keys) {
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
      expect(season2Learning.keys.where((id) => id.startsWith('s2_ep03_')).toSet(), {for (final m in case03.allMissions) m.id});
      expect(season2LanguageTopics['s2_ep03'], isNotNull);
      for (final m in case03.allMissions) {
        final l = SeasonCatalog.learning(m)!;
        expect(l.isHonest, isTrue, reason: m.id);
        if (l.dependency == LanguageDependency.essential) expect(l.expressions, isNotEmpty);
        for (final e in l.expressions) {
          expect(screen(m), contains(norm(e)), reason: '${m.id}: "$e" is on its screens');
        }
      }
    });

    test('its evidence leads on from the painter\'s message', () {
      expect(SeasonCatalog.evidenceLink('s2_ep03_e1')!.to, 's2_ep02_e4');
      expect(SeasonCatalog.evidenceLink('s2_ep03_e4')!.to, 's2_ep03_e1');
      expect(case02.finalMission.evidence!.id, 's2_ep02_e4');
      expect(case02.finalMission.evidence!.name, "The Painter's Message");
    });
  });

  group('its rules', () {
    late SharedPreferences prefs;

    Future<ProviderContainer> start({List<Override> extra = const []}) async {
      final c = ProviderContainer(overrides: [...await testOverridesFor(prefs), ...extra]);
      addTearDown(c.dispose);
      return c;
    }

    void solve(ProviderContainer c, Episode e) {
      final game = c.read(gameControllerProvider.notifier);
      expect(game.openEpisode(e.id), isTrue, reason: e.id);
      game.startInvestigation();
      for (final m in e.allMissions) {
        expect(game.submitAnswer(m, m.answer).result, SubmitResult.correct, reason: m.id);
      }
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: await testOverridesFor(prefs));
      c.read(gameControllerProvider.notifier).createDetective('Kim', DetectiveAvatar.girl);
      c.read(progressRepositoryProvider).saveSeason(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: [for (final e in s1) e.id]));
      c.dispose();
    });

    test('as shipped, it opens only once Case 02 is solved', () async {
      final c = await start();
      final game = c.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isTrue, reason: 'Paris is released');
      expect(game.openEpisode('s2_ep03'), isFalse);
      solve(c, case01);
      expect(game.openEpisode('s2_ep03'), isFalse, reason: 'no way round Case 02');
      expect(c.read(seasonProvider.notifier).isUnlocked('s2_ep03'), isFalse);
      solve(c, case02);
      expect(c.read(seasonProvider.notifier).isUnlocked('s2_ep03'), isTrue);
      expect(game.openEpisode('s2_ep03'), isTrue);
      expect(c.read(currentEpisodeProvider).id, 's2_ep03');
    });

    test('the GM preview keeps the case order; full access opens it at once', () async {
      final c = await start(extra: [seasonReleasedProvider.overrideWithValue((id) => id != SeasonIds.paris)]);
      final game = c.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isFalse, reason: 'not released: nobody but the preview');
      c.read(seasonPreviewSwitchProvider.notifier).set(true);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      expect(game.openEpisode('s2_ep03'), isFalse, reason: 'the preview keeps the case order');
      c.read(operatorAccessSwitchProvider.notifier).set(true);
      expect(game.openEpisode('s2_ep03'), isTrue);
      expect(c.read(seasonProvider).isSolved('s2_ep02'), isFalse, reason: 'full access marks nothing solved');
    });

    test('what is read, set and linked is saved and comes back after a restart', () async {
      var c = await start();
      var game = c.read(gameControllerProvider.notifier);
      game.openSeason(SeasonIds.paris);
      solve(c, case01);
      solve(c, case02);
      game.openEpisode('s2_ep03');
      game.startInvestigation();
      game.recordExamined(GameProgress.examinedKey(m1.id, 'notice'));
      expect(game.submitAnswer(m1, 'date:date').result, SubmitResult.tryAgain);
      expect(game.submitAnswer(m2, m2.answer).result, SubmitResult.locked, reason: 'missions in order');
      expect(game.submitAnswer(m1, m1.answer).result, SubmitResult.correct);
      game.recordExamined(GameProgress.examinedKey(m2.id, LiftScene.plateId));
      game.recordExamined(GameProgress.examinedKey(m3.id, noteId));
      game.recordPuzzleState(m3.id, DialState.encode([2, 0, 0]));
      final board = SeasonCatalog.evidenceBoard(fin)!;
      game.recordPuzzleState(fin.id, BoardState.encode({'q1': {'e1'}, 'q3': {'e2', 'e3'}}, null, board));

      c.dispose();
      c = await start();
      game = c.read(gameControllerProvider.notifier);
      expect(c.read(currentEpisodeProvider).id, 's2_ep03');
      var p = c.read(gameControllerProvider);
      expect(p.isCompleted(m1.id), isTrue);
      expect(p.wrongCount(m1.id), 1);
      expect(p.hasExamined('${m1.id}:notice'), isTrue);
      expect(p.hasExamined('${m2.id}:plate'), isTrue);
      expect(p.hasExamined('${m3.id}:note'), isTrue);
      expect(DialState.decode(p.puzzleStateOf(m3.id), SeasonCatalog.dialLock(m3)!), [2, 0, 0]);
      final (links, conclusion) = BoardState.decode(p.puzzleStateOf(fin.id), board);
      expect(links, {'q1': {'e1'}, 'q2': <String>{}, 'q3': {'e2', 'e3'}});
      expect(conclusion, isNull);

      for (final m in [m2, m3, fin]) {
        expect(game.submitAnswer(m, m.answer).result, SubmitResult.correct, reason: m.id);
      }
      p = c.read(gameControllerProvider);
      expect([for (final e in p.collectedEvidence(case03)) e.name],
          ['The Conflicting Notices', 'The Lift Log', 'The Service Room', 'The Brass Plaque']);
      expect(p.isCaseSolved, isTrue);
      expect(c.read(progressRepositoryProvider).load('s2_ep02').isCaseSolved, isTrue, reason: "Case 02's save is its own");
    });

    test('a save from before puzzle states reads as before, and writes none until one is set', () {
      final old = GameProgress.fromJson(const {
        'detectiveName': 'Kim',
        'completedMissionIds': ['s2_ep03_m1'],
        'examined': ['s2_ep03_m1:notice'],
        'revealed': {'s2_ep02_m3': 0.5},
      });
      expect(old.puzzleStates, isEmpty);
      expect(old.puzzleStateOf('s2_ep03_m3'), isNull);
      expect(old.revealedOf('s2_ep02_m3'), 0.5);
      expect(old.toJson().containsKey('puzzleStates'), isFalse);
      final set = old.copyWith(puzzleStates: {'s2_ep03_m3': '0,2,1'});
      final again = GameProgress.fromJson(jsonDecode(jsonEncode(set.toJson())) as Map<String, dynamic>);
      expect(again.puzzleStateOf('s2_ep03_m3'), '0,2,1');
      expect(GameProgress.fromJson(const {'puzzleStates': {'a': 3, 'b': 'x'}}).puzzleStates, {'b': 'x'});
      expect(set.resetCase().puzzleStates, isEmpty, reason: 'play again starts the puzzles afresh');
    });

    test('solved: Paris is 3 of 12, and Case 04 opens next', () async {
      final c = await start();
      final game = c.read(gameControllerProvider.notifier);
      game.openSeason(SeasonIds.paris);
      solve(c, case01);
      solve(c, case02);
      solve(c, case03);
      expect(c.read(seasonProvider).isSolved('s2_ep03'), isTrue);
      final board = c.read(seasonOverviewProvider);
      expect(board.solvedCount, 3);
      expect(board.info.plannedCases, 12);
      expect(board.comingSoonCase, isNull, reason: 'Case 04 is in the game (2026-10-21)');
      expect(board.current, 3, reason: 'Case 04 is the case to work on now');
      final paris = c.read(seasonAvailabilityProvider(SeasonIds.paris))!;
      expect((paris.solvedCount, paris.plannedCount), (3, 12));
      expect(game.openEpisode('s2_ep04'), isTrue, reason: 'Case 04 follows');
      expect(c.read(progressRepositoryProvider).loadSeason(SeasonIds.london).solvedEpisodeIds, hasLength(12));
    });
  });

  group('a child plays Case 03 (operator season preview)', () {
    for (final size in const [Size(360, 640), Size(390, 844), Size(430, 932)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';
      testWidgets('$tag: notices → lift → iron door → evidence board → plaque, 3 of 12', (t) async {
        t.view.physicalSize = size * 3;
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.reset);
        GameProgress solved(Episode e) => GameProgress(
              detectiveName: 'MINYOUNG',
              introSeen: true,
              completedMissionIds: [for (final m in e.allMissions) m.id],
              startedAt: DateTime(2026, 10, 20, 10),
              completedAt: DateTime(2026, 10, 20, 10, 30),
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
        final game = ref.read(gameControllerProvider.notifier);
        expect(game.openSeason(SeasonIds.paris), isTrue);
        for (final e in [case01, case02]) {
          expect(game.openEpisode(e.id), isTrue);
          game.startInvestigation();
          for (final m in e.allMissions) {
            game.submitAnswer(m, m.answer);
          }
        }
        expect(game.openEpisode('s2_ep03'), isTrue);
        game.startInvestigation();

        var n = 0;
        Future<void> shot(String name) async {
          expect(t.takeException(), isNull, reason: '$tag $name: no overflow, no error');
          if (shots == null) return;
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
            File('$shots/paris03_${tag}_${(n++).toString().padLeft(2, '0')}_$name.png').writeAsBytesSync(png!.buffer.asUint8List());
          });
        }

        Future<void> visit(String missionId) async {
          router.go(Routes.mission(missionId));
          await wait(t, const Duration(milliseconds: 1400));
        }

        Future<void> tapKey(String key, {Duration after = const Duration(milliseconds: 400)}) async {
          await reveal(t, find.byKey(ValueKey(key)));
          await t.tap(find.byKey(ValueKey(key)));
          await wait(t, after);
        }

        Future<void> finish(String sceneLine, String name) async {
          await wait(t, const Duration(milliseconds: 2800));
          expect(find.byWidgetPredicate((w) => w is Text && DiscoveryType.values.any((d) => d.cheer == w.data)), findsOneWidget);
          await shot('${name}_solved');
          await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 900));
          expect(find.text(sceneLine), findsOneWidget, reason: 'story transition');
          await t.tapAt(Offset(size.width / 2, size.height / 2)); // skip typing
          await wait(t, const Duration(milliseconds: 900));
          expect(find.byKey(const ValueKey('scene-backdrop')), findsOneWidget, reason: '$name: its own picture');
          expect(find.byKey(const ValueKey('unlocked-picture')), findsOneWidget, reason: '$name: the next place');
          await shot('${name}_scene');
          await tapText(t, 'TO THE MAP', after: const Duration(milliseconds: 1200));
          await wait(t, const Duration(milliseconds: 3200));
        }

        Future<void> wrongThenTryAgain(String feedback, String name) async {
          await wait(t, const Duration(milliseconds: 1500));
          expect(findReadableContaining(feedback), findsWidgets, reason: name);
          await shot('${name}_wrong');
          await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
        }

        Set<String> examined() => ref.read(gameControllerProvider).examined.toSet();

        // ── M1: the two notices ──────────────────────────────────────────
        await visit(m1.id);
        expect(find.byKey(const ValueKey('story-picture')), findsOneWidget, reason: 'the entrance');
        await shot('m1_place');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.text('TAP TO OPEN'), findsNothing, reason: 'the records are read on the page');
        expect(find.byKey(const ValueKey('record-notice')), findsOneWidget);
        expect(examined(), contains('s2_ep03_m1:notice'));
        expect(find.byKey(const ValueKey('records-check')), findsNothing, reason: 'both records read first');
        await shot('m1_notice');
        await tapKey('record-tab-log');
        expect(find.byKey(const ValueKey('record-log')), findsOneWidget);
        expect(examined(), contains('s2_ep03_m1:log'));
        await shot('m1_log');
        // Same lines on both: a near miss says why.
        await tapKey('line-log-date');
        await tapKey('record-tab-notice');
        await tapKey('line-notice-date');
        await tapKey('records-check');
        await wrongThenTryAgain('The dates match', 'm1');
        await tapKey('line-notice-time');
        await tapKey('record-tab-log');
        await tapKey('line-log-time');
        expect(find.text('TIME 3:00 PM'), findsOneWidget);
        expect(find.text('TIME 4:00 PM'), findsOneWidget);
        await shot('m1_picked');
        await tapKey('records-check');
        await finish(m1.transition.first, 'm1');
        expect(ref.read(gameControllerProvider).isCompleted(m1.id), isTrue);

        // ── M2: the lift, its plate and its log ───────────────────────────
        await visit(m2.id);
        await shot('m2_place');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('lift-check')), findsNothing, reason: 'the plate and the log first');
        await shot('m2_lift');
        await tapKey('lift-spot-log', after: const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('log-service-mark')), findsOneWidget);
        await shot('m2_log');
        await tapKey('document-close');
        await tapKey('lift-spot-plate', after: const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('stop-name-service')), findsOneWidget);
        expect(find.byKey(const ValueKey('plate-legend')), findsOneWidget);
        await shot('m2_plate');
        await tapKey('document-close');
        expect(examined(), containsAll(['s2_ep03_m2:plate', 's2_ep03_m2:log']));
        await tapKey('stop-first');
        await tapKey('lift-check');
        await wrongThenTryAgain('What does S mean?', 'm2');
        await tapKey('stop-service');
        await shot('m2_chosen');
        await tapKey('lift-check');
        await finish(m2.transition.first, 'm2');

        // ── M3: the note, then the padlock's dials ───────────────────────
        final lock = SeasonCatalog.dialLock(m3)!;
        await visit(m3.id);
        await shot('m3_place');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
        expect(find.byType(LetterCard), findsOneWidget, reason: 'the pinned note');
        await shot('m3_note');
        await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
        expect(examined(), contains('s2_ep03_m3:note'));
        String setOn(int i) => t.widget<Text>(find.byKey(ValueKey('dial-set-$i'))).data!;
        expect([setOn(0), setOn(1), setOn(2)], [for (final i in lock.start) lock.symbols[i].name]);
        await shot('m3_lock');
        // As it starts: wrong, and nothing given away.
        await tapKey('dial-open');
        await wait(t, const Duration(milliseconds: 1500));
        expect(find.text('TRY AGAIN'), findsWidgets);
        await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
        // One turn, then out and back in: the dial is where it was left.
        await tapKey('dial-0');
        expect(setOn(0), 'LIFT');
        router.go(Routes.map);
        await wait(t, const Duration(milliseconds: 1400));
        await visit(m3.id);
        expect(setOn(0), 'LIFT', reason: 'saved');
        // The middle dial dragged round, clockwise a third of the way and
        // more: it follows the finger and settles on the LIFT.
        await reveal(t, find.byKey(const ValueKey('dial-1')));
        final middle = t.getCenter(find.byKey(const ValueKey('dial-1')));
        Offset round(double degrees) => middle + Offset(math.cos(degrees * math.pi / 180), math.sin(degrees * math.pi / 180)) * 34;
        final gesture = await t.startGesture(round(-90));
        for (final a in const <double>[-75, -60, -40, -20, 0, 20]) {
          await gesture.moveTo(round(a));
          await t.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await wait(t, const Duration(milliseconds: 400));
        expect(setOn(1), 'LIFT');
        expect(DialState.decode(ref.read(gameControllerProvider).puzzleStateOf(m3.id), lock)[1], 2, reason: 'saved as it settles');
        // The others by taps (each tap turns on to the next symbol).
        await tapKey('dial-0'); // LIFT → CLOCK
        await tapKey('dial-2'); // LIFT → CLOCK
        await tapKey('dial-2'); // CLOCK → KEY
        expect([setOn(0), setOn(1), setOn(2)], ['CLOCK', 'LIFT', 'KEY']);
        // Each set symbol close and upright under its dial.
        for (final (i, id) in ['clock', 'lift', 'key'].indexed) {
          expect(find.byKey(ValueKey('dial-symbol-$i-$id')), findsOneWidget);
          expect(t.getSize(find.byKey(ValueKey('dial-symbol-$i-$id'))).width, greaterThanOrEqualTo(56));
        }
        await shot('m3_set');
        await tapKey('dial-open');
        await finish(m3.transition.first, 'm3');

        // ── Final: the evidence board, then the plaque ───────────────────
        router.go(Routes.finalMission);
        await wait(t, const Duration(milliseconds: 1600));
        expect(find.byKey(const ValueKey('machine-stage')), findsOneWidget);
        expect(find.byKey(const ValueKey('plaque-message')), findsNothing, reason: 'nothing of the plaque before the solve');
        await shot('final_page');
        final solve = find.byKey(const ValueKey('board-solve'));
        await reveal(t, solve);
        expect(t.widget<GameButton>(solve).onPressed, isNull, reason: 'every question linked first');
        Future<void> link(String q, List<String> evidence) async {
          await tapKey('board-question-$q', after: const Duration(milliseconds: 200));
          for (final e in evidence) {
            await tapKey('board-evidence-$e', after: const Duration(milliseconds: 200));
          }
        }

        await link('q1', ['e1']);
        await link('q2', ['e2']);
        await link('q3', ['e2', 'e3']);
        await shot('final_linked');
        await tapKey('board-conclusion-vanished');
        await reveal(t, solve);
        await t.tap(solve);
        await wrongThenTryAgain('We have no proof of that yet.', 'final');
        await tapKey('board-conclusion-entered');
        await reveal(t, solve);
        await t.tap(solve);
        await wait(t, const Duration(milliseconds: 3600));
        expect(ref.read(gameControllerProvider).isCaseSolved, isTrue);
        expect(find.byKey(const ValueKey('machine-open')), findsOneWidget, reason: 'the hatch opens');
        await shot('final_open');
        await tapText(t, 'LOOK INSIDE', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('plaque-message')), findsOneWidget);
        // Engraved on the brass, and again in large words under it.
        expect(find.text('ONE HOUR IS MISSING.\nTHE CLOCK IS STILL RUNNING.'), findsNWidgets(2));
        expect(t.widget<Text>(find.byKey(const ValueKey('plaque-words'))).style!.fontSize, greaterThanOrEqualTo(20));
        expect(find.byKey(const ValueKey('plaque-river')), findsOneWidget);
        await shot('final_plaque');
        await tapText(t, 'BACK TO THE ROOM', after: const Duration(milliseconds: 700));
        expect(examined(), contains('s2_ep03_final:plaque'));
        await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 900));
        expect(find.text(fin.transition.first), findsOneWidget);
        await t.tapAt(Offset(size.width / 2, size.height / 2));
        await wait(t, const Duration(milliseconds: 900));
        expect(find.text('SEINE.'), findsOneWidget);
        expect(find.byKey(const ValueKey('scene-backdrop')), findsOneWidget, reason: 'the open machine');
        await shot('final_scene');
        await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 4000));
        expect(find.byKey(const ValueKey('next-case-coming-soon')), findsNothing, reason: 'Case 04 is in the game');
        await shot('case_closed');

        // Paris: 3 of 12, Case 04 next.
        final board = ref.read(seasonOverviewProvider);
        expect(board.solvedCount, 3);
        expect(board.comingSoonCase, isNull);
        expect(game.openEpisode('s2_ep04'), isTrue);
        await wait(t, const Duration(seconds: 3));
      });
    }
  });
}
