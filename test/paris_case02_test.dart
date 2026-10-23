import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/core/utils/answer_checker.dart';
import 'package:london_mystery/data/mock/season2/season2_learning.dart';
import 'package:london_mystery/data/mock/season2/season2_mock.dart';
import 'package:london_mystery/data/mock/season_catalog.dart';
import 'package:london_mystery/data/models/discovery.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/learning.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/painter_puzzles.dart';
import 'package:london_mystery/data/models/picture_spot.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/scene_explore.dart' show ScenePixels;
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/season/season_overview.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/game_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';

/// Season 2, Case 02 — The Vanishing Painter: its thirteen pictures, its
/// story and puzzles as the pictures show them, its rules (unlock, saves,
/// evidence, the board), and a child playing it through on three phones.
///
/// `LM_SHOTS=folder` saves a picture of each step of the play-through.
void main() {
  final inGame = MockEpisodeRepository.bundled();
  final s1 = season1Cases();
  final case01 = inGame.firstWhere((e) => e.id == 's2_ep01');
  final case02 = inGame.firstWhere((e) => e.id == 's2_ep02');
  final [m1, m2, m3, fin] = case02.allMissions;
  final shots = Platform.environment['LM_SHOTS'];

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
          m.clue?.note ?? '',
          m.evidence?.description ?? '',
          m.evidence?.inscription ?? '',
        ],
      ].join('\n');

  group('its pictures', () {
    const folder = 'assets/seasons/season_02_paris/cases/case_02';
    const pictures = {
      'montmartre_street_real.png': (1536, 1024),
      'montmartre_street_painted.png': (1536, 1024),
      'painters_studio.png': (1024, 1536),
      'studio_painting_p1.png': (1254, 1254),
      'studio_painting_p2.png': (1254, 1254),
      'studio_painting_p3.png': (1254, 1254),
      'hidden_layer_paint.png': (1536, 1024),
      'hidden_layer_sketch.png': (1536, 1024),
      'canvas_a.png': (1536, 1024),
      'canvas_b.png': (1536, 1024),
      'canvas_c.png': (1536, 1024),
      'canvas_d.png': (1536, 1024),
      'canvas_back.png': (1536, 1024),
    };

    /// A PNG's width, height and whether it has an alpha channel (its IHDR).
    (int, int, bool) header(Uint8List b) {
      final d = ByteData.sublistView(b);
      final colourType = b[25];
      return (d.getUint32(16), d.getUint32(20), colourType == 4 || colourType == 6);
    }

    test('all thirteen are in, listed in pubspec, opaque, at the sizes their places are measured on', () {
      expect(pubspecAssets(), contains('$folder/'), reason: 'its folder, exactly, in flutter: assets:');
      for (final MapEntry(key: name, value: (w, h)) in pictures.entries) {
        final file = File('$folder/$name');
        expect(file.existsSync(), isTrue, reason: name);
        final (pw, ph, alpha) = header(file.readAsBytesSync());
        expect((pw, ph), (w, h), reason: name);
        expect(alpha, isFalse, reason: '$name is opaque: never shown as a cut-out');
      }
      // The pixel sizes the scenes are measured on are the files' own.
      final compare = SeasonCatalog.compare(m1)!;
      final studio = SeasonCatalog.studio(m2)!;
      final layer = SeasonCatalog.layer(m3)!;
      final canvases = SeasonCatalog.canvasChoice(fin)!;
      expect((compare.pixels.width, compare.pixels.height), (1536.0, 1024.0));
      expect((studio.pixels.width, studio.pixels.height), (1024.0, 1536.0));
      for (final p in studio.paintings) {
        expect((p.pixels.width, p.pixels.height), (1254.0, 1254.0));
      }
      expect((layer.pixels.width, layer.pixels.height), (1536.0, 1024.0));
      expect((canvases.pixels.width, canvases.pixels.height), (1536.0, 1024.0));
      expect((canvases.backPixels.width, canvases.backPixels.height), (1536.0, 1024.0));
    });

    test('every one of them is played on, each where it means something', () {
      final compare = SeasonCatalog.compare(m1)!;
      final studio = SeasonCatalog.studio(m2)!;
      final layer = SeasonCatalog.layer(m3)!;
      final canvases = SeasonCatalog.canvasChoice(fin)!;
      final played = {
        compare.real: 'M1',
        compare.painted: 'M1',
        studio.picture: 'M2',
        for (final p in studio.paintings) p.file: 'M2',
        layer.paint: 'M3',
        layer.sketch: 'M3',
        for (final c in canvases.canvases) c.file: 'Final',
        canvases.back: 'Final',
      };
      expect(played.keys.toSet(), {for (final name in pictures.keys) '$folder/$name'});
      // Each mission's place page and the scene after it: its own pictures,
      // never the same one twice in a row.
      final story = [for (final m in case02.allMissions) SeasonCatalog.storyScenes(m)!];
      expect(story[0].place!.file, compare.real);
      expect(story[0].after!.file, compare.painted);
      expect(story[1].place!.file, studio.picture);
      expect(story[2].place!.file, layer.paint);
      expect(story[2].after!.file, layer.sketch);
      expect(story[3].after!.file, canvases.back);
      for (final s in story) {
        if (s.place != null && s.after != null) expect(s.place!.file, isNot(s.after!.file));
      }
      // The street and the studio are the case's places everywhere else (map, cards).
      expect(ArtAssets.scenes[Artwork.montmartreStreet], compare.real);
      expect(ArtAssets.scenes[Artwork.paintersStudio], studio.picture);
    });

    test('its answer places lie on the pictures, apart from each other', () {
      bool inside(Rect r) => r.left >= 0 && r.top >= 0 && r.right <= 1 && r.bottom <= 1 && !r.isEmpty;
      void apart(List<Rect> rs, String what) {
        for (var i = 0; i < rs.length; i++) {
          expect(inside(rs[i]), isTrue, reason: '$what $i');
          for (var j = i + 1; j < rs.length; j++) {
            expect(rs[i].overlaps(rs[j]), isFalse, reason: '$what $i and $j');
          }
        }
      }

      final compare = SeasonCatalog.compare(m1)!;
      apart([for (final c in compare.changes) c.area], 'change');
      expect({for (final c in compare.changes) c.id}, {for (final o in m1.options) o.id});
      for (final c in compare.changes) {
        expect(compare.opening.overlaps(c.area), isTrue, reason: '${c.id}: in the opening view');
      }
      final studio = SeasonCatalog.studio(m2)!;
      apart([for (final p in studio.paintings) p.area, studio.desk.areas.first], 'studio place');
      expect(studio.order.toSet(), {'p1', 'p2', 'p3'});
      final layer = SeasonCatalog.layer(m3)!;
      apart([for (final m in layer.marks) m.area], 'mark');
      expect({for (final m in layer.marks) m.id}, {for (final o in m3.options) o.id});
      for (final m in layer.marks) {
        expect(layer.canvas.contains(m.area.center), isTrue, reason: '${m.id}: on the canvas, under the paint');
      }
      expect(layer.edgeAt(0), layer.canvas.left);
      expect(layer.edgeAt(1), layer.canvas.right);
      final canvases = SeasonCatalog.canvasChoice(fin)!;
      expect({for (final c in canvases.canvases) c.id}, {for (final o in fin.options) o.id});
      expect(inside(canvases.writeOn), isTrue);
    });
  });

  group('the case', () {
    test('Case 02 is in the game, after Case 01, with its four puzzles and evidence', () {
      expect(SeasonCatalog.byId(SeasonIds.paris)!.episodes.keys, ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05', 's2_ep06', 's2_ep07']);
      expect(season2AwaitingArtJson.keys, isNot(contains('s2_ep02')));
      expect(SeasonCatalog.isAwaitingArt('s2_ep02'), isFalse);
      expect(const MockEpisodeRepository().fetchEpisode('s2_ep02'), completion(isA<Episode>()));
      expect(case02.number, 2);
      expect(case02.seasonId, SeasonIds.paris);
      expect(case02.title, 'The Vanishing Painter');
      expect(case02.place, 'MONTMARTRE · PARIS');
      // It begins on the painting found in Case 01's brass box.
      expect(case02.introScene, Artwork.montmartrePainting);
      expect([for (final m in case02.allMissions) m.id], ['s2_ep02_m1', 's2_ep02_m2', 's2_ep02_m3', 's2_ep02_final']);
      expect([for (final m in case02.allMissions) m.title],
          ['The Painted Street', "The Artist's Studio", 'The Hidden Layer', 'Behind the Canvas']);
      expect([for (final m in case02.allMissions) m.type], [
        MissionType.spotDifferences,
        MissionType.matchPairs,
        MissionType.revealLayer,
        MissionType.canvasChoice,
      ]);
      // Each played on its pictures.
      expect(SeasonCatalog.compare(m1), isNotNull);
      expect(SeasonCatalog.studio(m2), isNotNull);
      expect(SeasonCatalog.layer(m3), isNotNull);
      expect(SeasonCatalog.canvasChoice(fin), isNotNull);
      expect([for (final m in case02.allMissions) m.evidence!.name],
          ['The Painted Street', "The Artist's Notes", 'The Hidden Sketch', "The Painter's Message"]);
      expect(fin.evidence!.inscription, 'A city can lose an hour. But who can steal it?');
      expect(SeasonCatalog.canvasChoice(fin)!.message.replaceAll('\n', ' '), fin.evidence!.inscription);
      for (final m in case02.allMissions) {
        expect(m.hints, hasLength(2), reason: m.id);
      }
      // Its ids are its own: nothing shared with Case 01 or Season 1.
      final ids = {
        for (final e in inGame.where((e) => e.id != 's2_ep02')) ...[
          for (final m in e.allMissions) m.id,
          for (final m in e.allMissions) ?m.evidence?.id,
          for (final m in e.allMissions) ?m.clue?.id,
        ],
      };
      for (final m in case02.allMissions) {
        expect(ids, isNot(contains(m.id)));
        expect(ids, isNot(contains(m.evidence!.id)));
        if (m.clue != null) expect(ids, isNot(contains(m.clue!.id)));
      }
    });

    test('the story goes in order, from Case 01\'s ticket and painting to the painter\'s message', () {
      expect(case01.finalMission.evidence!.inscription, contains('FIND THE PAINTER'));
      expect(case02.intro.join(' '), contains('FIND THE PAINTER'));
      expect(case02.intro.join(' '), contains('ticket'));
      expect(case02.intro.join(' '), contains('MONTMARTRE'));
      expect([for (final m in case02.missions) m.nextMissionId], ['s2_ep02_m2', 's2_ep02_m3', 's2_ep02_final']);
      expect(m1.transition.last, contains('STUDIO'));
      expect(m2.story.first, contains('key'));
      expect(m2.transition.last, contains('thick paint'));
      expect(m3.story.join(' '), contains('thick paint'));
      expect(m3.transition.last, contains('four canvases'));
      expect(fin.story.first, contains('Four canvases'));
      // M3 answers the three questions of the hidden layer.
      for (final q in ['What changed?', 'What was hidden?', 'Why does it matter?']) {
        expect(m3.transition.where((l) => l.startsWith(q)), hasLength(1), reason: q);
      }
      // The painter left on his own: what was found says it before he does.
      final end = fin.transition;
      final message = end.indexWhere((l) => l.contains('A city can lose an hour'));
      expect(message, greaterThanOrEqualTo(0));
      expect(end.indexOf('He hid his own sketch. He left his notes for you.'), greaterThan(message));
      expect(end.indexOf('He left on his own.'), greaterThan(end.indexOf('He hid his own sketch. He left his notes for you.')));
      expect(end.last, contains('still stealing the hours'));
      // Nothing the pictures do not show: no travelling bag, no gear, no
      // painter walking in his sketch.
      final text = everything(case02);
      for (final absent in ['travel bag', 'gear', 'walks up the steps', 'His bag']) {
        expect(text, isNot(contains(absent)), reason: absent);
      }
      // The Clockmaker stays untold, and so does Case 03's place.
      expect(text, isNot(contains('Clockmaker')));
      for (final place in ['Eiffel', 'Louvre', 'Notre', 'Opéra', 'Opera', 'Seine']) {
        expect(text, isNot(contains(place)), reason: place);
      }
    });

    test('only the right answer solves each puzzle; near misses say what to read again', () {
      // M1: the three changes, in any order; never fewer, never twice.
      expect(AnswerChecker.isCorrect(m1, 'clock,window,lamp'), isTrue);
      expect(AnswerChecker.isCorrect(m1, 'lamp,clock,window'), isTrue);
      expect(AnswerChecker.isCorrect(m1, 'clock,window'), isFalse);
      expect(AnswerChecker.isCorrect(m1, 'clock,clock,window'), isFalse);
      expect(AnswerChecker.isCorrect(m1, ''), isFalse);
      // M2: every note joined to its painting.
      expect(AnswerChecker.isCorrect(m2, 'a:p2,b:p3,c:p1'), isTrue);
      expect(AnswerChecker.isCorrect(m2, 'c:p1,a:p2,b:p3'), isTrue);
      expect(AnswerChecker.isCorrect(m2, 'a:p3,b:p2,c:p1'), isFalse);
      expect(AnswerChecker.feedbackFor(m2, 'a:p3,b:p2,c:p1'), contains('dry'));
      expect(AnswerChecker.feedbackFor(m2, 'a:p2,b:p1,c:p3'), contains('wet and shiny'));
      expect(AnswerChecker.feedbackFor(m2, 'a:p2,b:p3,c:p1'), isNull);
      for (final note in ['a', 'b', 'c']) {
        for (final p in ['p1', 'p2', 'p3']) {
          final pair = '$note:$p';
          final right = Mission.sequenceIds(m2.answer).contains(pair);
          expect(m2.feedback.containsKey(pair), !right, reason: pair);
        }
      }
      // Neither the notes' order nor the page's order of the paintings
      // gives the pairs: no guessing A→1, B→2.
      final order = SeasonCatalog.studio(m2)!.order;
      for (final pair in Mission.sequenceIds(m2.answer)) {
        final [note, picture] = pair.split(':');
        expect('abc'.indexOf(note) + 1, isNot(int.parse(picture.substring(1))), reason: pair);
        expect('abc'.indexOf(note), isNot(order.indexOf(picture)), reason: '$pair on the page');
      }
      // M3: the three things of the sketch.
      expect(AnswerChecker.isCorrect(m3, 'gate,lamp,steps'), isTrue);
      expect(AnswerChecker.isCorrect(m3, 'lamp,steps'), isFalse);
      // Final: the one canvas; each wrong one says which clue to check.
      expect(AnswerChecker.isCorrect(fin, 'c'), isTrue);
      for (final wrong in ['a', 'b', 'd']) {
        expect(AnswerChecker.isCorrect(fin, wrong), isFalse);
        expect(AnswerChecker.feedbackFor(fin, wrong), startsWith('Check the'), reason: wrong);
      }
    });

    test('the paintings match their notes by what they show', () {
      // What each painting shows (looked at on its file): its sky and its stones.
      const shows = {
        'p1': (darkClouds: false, wet: false, wholeSkyGold: true),
        'p2': (darkClouds: true, wet: false, wholeSkyGold: false),
        'p3': (darkClouds: true, wet: true, wholeSkyGold: false),
      };
      final notes = <String, bool Function(({bool darkClouds, bool wet, bool wholeSkyGold}))>{
        'a': (p) => p.darkClouds && !p.wet, // BEFORE THE RAIN: dark clouds, dry stones
        'b': (p) => p.wet, // AFTER THE RAIN STOPPED: wet and shiny
        'c': (p) => p.wholeSkyGold && !p.wet, // WHEN THE SKY TURNED GOLD: whole sky gold, dry
      };
      for (final MapEntry(key: note, value: fits) in notes.entries) {
        final matching = [for (final MapEntry(key: id, value: s) in shows.entries) if (fits(s)) id];
        expect(matching, hasLength(1), reason: 'note $note fits one painting only');
        expect(Mission.sequenceIds(m2.answer), contains('$note:${matching.single}'));
      }
      expect(m2.letter, contains('Dark clouds were coming. The stones were still dry.'));
      expect(m2.letter, contains('The stones were wet and shiny.'));
      expect(m2.letter, contains('The whole sky was gold. The stones were dry.'));
    });

    test('the final needs the clues: no one finds the canvas alone, together only one', () {
      // What each canvas shows (looked at on its file).
      const shows = {
        'a': (redDoor: true, blueSky: true, stepsLampBlackGate: true), // its gate is black too
        'b': (redDoor: false, blueSky: false, stepsLampBlackGate: false), // a square at sunset
        'c': (redDoor: false, blueSky: true, stepsLampBlackGate: true),
        'd': (redDoor: false, blueSky: true, stepsLampBlackGate: false), // its gate is blue
      };
      final clues = <String, bool Function(({bool redDoor, bool blueSky, bool stepsLampBlackGate}))>{
        'M1 not the red door': (c) => !c.redDoor,
        'M2 a blue-sky day': (c) => c.blueSky,
        'M3 steps, a lamp, a black gate': (c) => c.stepsLampBlackGate,
      };
      Set<String> left(Iterable<bool Function(({bool redDoor, bool blueSky, bool stepsLampBlackGate}))> use) =>
          {for (final MapEntry(key: id, value: s) in shows.entries) if (use.every((c) => c(s))) id};
      expect(left(clues.values), {fin.answer});
      for (final MapEntry(key: name, value: clue) in clues.entries) {
        expect(left([clue]).length, greaterThan(1), reason: '$name alone does not find it');
      }
      // Without the street's clue the red door stays; without the sketch's,
      // the blue gate: both are needed.
      expect(left([clues.values.elementAt(1), clues.values.elementAt(2)]), {'a', 'c'});
      expect(left([clues.values.elementAt(0), clues.values.elementAt(1)]), {'c', 'd'});
      // The notebook's letter gives the three, as the missions found them.
      expect(fin.letter, contains('Not the street with the red door.'));
      expect(fin.letter, contains('I hid my secret on a blue-sky day.'));
      expect(fin.letter, contains('Steps, a lamp and a black gate.'));
      expect(m1.transition.join(' '), contains('far from the red door'));
      expect(m2.transition.join(' '), contains('blue-sky day'));
      expect(m3.letter, contains('the gate is black'));
      // Each wrong canvas's feedback names the clue it misses.
      expect(AnswerChecker.feedbackFor(fin, 'a'), contains('red door'));
      expect(AnswerChecker.feedbackFor(fin, 'b'), contains('blue'));
      expect(AnswerChecker.feedbackFor(fin, 'd'), contains('colour is the gate'));
      // The right canvas is not the last one, and no hint names it.
      expect(fin.options.last.id, isNot(fin.answer));
      for (final h in fin.hints) {
        expect(h, isNot(contains('canvas ${fin.answer.toUpperCase()}')));
      }
    });

    test('no hint or story before the solve gives the answer away', () {
      for (final h in m1.hints) {
        expect(h, isNot(contains('clock')), reason: h);
      }
      for (final h in m2.hints) {
        expect(h, isNot(matches(RegExp(r'p[123]'))), reason: h);
        expect(h.toUpperCase(), isNot(contains('GOLD')), reason: 'the gold sky pairs itself: $h');
      }
      for (final s in [...m1.story, m1.letter]) {
        expect(s, isNot(contains('small clock')), reason: s);
      }
      for (final s in [...fin.story, fin.letter, ...fin.hints, ...m3.transition]) {
        expect(s, isNot(contains('lose an hour')), reason: s);
      }
    });

    test('every word in its glossary is in its text', () {
      final text = everything(case02).toLowerCase();
      for (final w in case02.glossary.keys) {
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
      expect(season2Learning.keys.where((id) => id.startsWith('s2_ep02_')).toSet(), {for (final m in case02.allMissions) m.id});
      expect(season2LanguageTopics['s2_ep02'], isNotNull);
      for (final m in case02.allMissions) {
        final l = SeasonCatalog.learning(m)!;
        expect(l.isHonest, isTrue, reason: m.id);
        if (l.dependency == LanguageDependency.essential) expect(l.expressions, isNotEmpty);
        for (final e in l.expressions) {
          expect(screen(m), contains(norm(e)), reason: '${m.id}: "$e" is on its screens');
        }
      }
    });

    test('its evidence matches what Case 01 found', () {
      final case01Evidence = {for (final m in case01.allMissions) m.evidence!.id};
      for (final (from, to) in [('s2_ep02_e1', 's2_ep01_e4'), ('s2_ep02_e4', 's2_ep01_e4')]) {
        expect(SeasonCatalog.evidenceLink(from)!.to, to, reason: from);
        expect(case01Evidence, contains(to));
      }
      expect(SeasonCatalog.evidenceLink('s2_ep02_e3'), isNull, reason: 'the sketch has no gear: nothing to link it to');
      // Case 01's own links are unchanged.
      expect(SeasonCatalog.evidenceLink('s2_ep01_e4')!.to, 's2_ep01_e2');
      expect(SeasonCatalog.evidenceLink('s2_ep01_e2')!.to, 's2_ep01_e4');
    });
  });

  group('its rules', () {
    late SharedPreferences prefs;

    /// The game with Paris released (with Season 1 done).
    Future<List<Override>> released() async => [
          ...await testOverridesFor(prefs),
          seasonReleasedProvider.overrideWithValue((_) => true),
        ];

    Future<ProviderContainer> start() async {
      final c = ProviderContainer(overrides: await released());
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
      final c = ProviderContainer(overrides: await released());
      c.read(gameControllerProvider.notifier).createDetective('Kim', DetectiveAvatar.girl);
      c.read(progressRepositoryProvider).saveSeason(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: [for (final e in s1) e.id]));
      c.dispose();
    });

    test('unreleased, nobody but the preview plays it', () async {
      // Paris as it was before its release (2026-10-21).
      final c = ProviderContainer(overrides: [
        ...await testOverridesFor(prefs),
        seasonReleasedProvider.overrideWithValue((id) => id != SeasonIds.paris),
      ]);
      addTearDown(c.dispose);
      final game = c.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isFalse, reason: 'the release lock first');
      expect(game.openEpisode('s2_ep02'), isFalse);
    });

    test('it opens only once Case 01 is solved', () async {
      final c = await start();
      final game = c.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      expect(c.read(episodeCatalogProvider).map((e) => e.id), ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05', 's2_ep06', 's2_ep07']);
      expect(c.read(seasonProvider.notifier).isUnlocked('s2_ep02'), isFalse);
      expect(game.openEpisode('s2_ep02'), isFalse, reason: 'no way round Case 01');
      expect(c.read(seasonOverviewProvider).marks, [CaseMark.current, CaseMark.sealed, CaseMark.sealed, CaseMark.sealed, CaseMark.sealed, CaseMark.sealed, CaseMark.sealed]);
      solve(c, case01);
      expect(c.read(seasonProvider.notifier).isUnlocked('s2_ep02'), isTrue);
      final board = c.read(seasonOverviewProvider);
      expect(board.current, 1, reason: 'Case 02 is the case to work on now');
      expect(board.comingSoonCase, isNull);
      expect(game.openEpisode('s2_ep02'), isTrue);
      expect(c.read(currentEpisodeProvider).id, 's2_ep02');
      expect(c.read(gameControllerProvider).detectiveName, 'Kim');
    });

    test('unreleased, the preview plays it in order; full access opens it at once', () async {
      final c = ProviderContainer(overrides: [
        ...await testOverridesFor(prefs),
        seasonReleasedProvider.overrideWithValue((id) => id != SeasonIds.paris),
      ]);
      addTearDown(c.dispose);
      final game = c.read(gameControllerProvider.notifier);
      c.read(seasonPreviewSwitchProvider.notifier).set(true);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      expect(game.openEpisode('s2_ep02'), isFalse, reason: 'the preview keeps the case order');
      c.read(operatorAccessSwitchProvider.notifier).set(true);
      expect(game.openEpisode('s2_ep02'), isTrue);
      expect(c.read(seasonProvider).isSolved('s2_ep01'), isFalse, reason: 'full access marks nothing solved');
    });

    test('what is found is saved, in the notebook\'s order, and kept after a restart', () async {
      var c = await start();
      var game = c.read(gameControllerProvider.notifier);
      game.openSeason(SeasonIds.paris);
      solve(c, case01);
      game.openEpisode('s2_ep02');
      game.startInvestigation();
      expect(game.submitAnswer(m1, 'clock,window').result, SubmitResult.tryAgain);
      expect(game.submitAnswer(m2, m2.answer).result, SubmitResult.locked, reason: 'missions in order');
      expect(game.submitAnswer(m1, m1.answer).result, SubmitResult.correct);
      // Paintings found in the studio; how far the paint is slid and what
      // was found under it, apart.
      game.recordExamined(GameProgress.examinedKey(m2.id, 'p1'));
      game.recordExamined(GameProgress.examinedKey(m3.id, 'lamp'));
      game.recordReveal(m3.id, 0.4);
      var p = c.read(gameControllerProvider);
      expect([for (final e in p.collectedEvidence(case02)) e.name], ['The Painted Street']);
      expect([for (final k in p.collectedClues(case02)) k.title], ['Not This Street']);

      c.dispose();
      c = await start();
      game = c.read(gameControllerProvider.notifier);
      expect(c.read(selectedSeasonIdProvider), SeasonIds.paris);
      expect(c.read(currentEpisodeProvider).id, 's2_ep02');
      p = c.read(gameControllerProvider);
      expect(p.isCompleted(m1.id), isTrue);
      expect(p.currentMission(case02)!.id, m2.id);
      expect(p.hasExamined('${m2.id}:p1'), isTrue);
      expect(p.hasExamined('${m3.id}:lamp'), isTrue);
      expect(p.revealedOf(m3.id), 0.4);
      expect(p.revealedOf(m2.id), 0);
      expect(p.wrongCount(m1.id), 1);

      for (final m in [m2, m3, fin]) {
        expect(game.submitAnswer(m, m.answer).result, SubmitResult.correct, reason: m.id);
      }
      p = c.read(gameControllerProvider);
      expect([for (final e in p.collectedEvidence(case02)) e.name],
          ['The Painted Street', "The Artist's Notes", 'The Hidden Sketch', "The Painter's Message"]);
      expect(p.isCaseSolved, isTrue);
      // Case 01's save is its own, as it was.
      expect(c.read(progressRepositoryProvider).load('s2_ep01').isCaseSolved, isTrue);
    });

    test('solved: Paris is 2 of 12, and Case 03 (in the game since its pictures came in) opens', () async {
      final c = await start();
      final game = c.read(gameControllerProvider.notifier);
      game.openSeason(SeasonIds.paris);
      final coinsBefore = c.read(walletProvider).balance;
      solve(c, case01);
      final afterCase01 = c.read(walletProvider).balance;
      solve(c, case02);
      expect(c.read(walletProvider).balance, greaterThan(afterCase01), reason: 'its missions pay as every case does');
      expect(afterCase01, greaterThan(coinsBefore));
      final season = c.read(seasonProvider);
      expect(season.isSolved('s2_ep02'), isTrue);
      expect(c.read(recentSolveProvider), contains('s2_ep02'));
      final board = c.read(seasonOverviewProvider);
      expect(board.solvedCount, 2);
      expect(board.info.plannedCases, 12);
      expect(board.complete, isFalse);
      expect(board.comingSoonCase, isNull, reason: 'Case 03 is in the game');
      expect(board.current, 2, reason: 'Case 03 is the case to work on now');
      final paris = c.read(seasonAvailabilityProvider(SeasonIds.paris))!;
      expect((paris.solvedCount, paris.plannedCount), (2, 12));
      expect(paris.isCompleted, isFalse);
      expect(game.openEpisode('s2_ep03'), isTrue, reason: 'Case 02 solved opens Case 03');
      // Season 1 is as it was.
      expect(c.read(progressRepositoryProvider).loadSeason(SeasonIds.london).solvedEpisodeIds, hasLength(12));
    });
  });

  group('a child plays Case 02 (operator season preview)', () {
    for (final size in const [Size(360, 640), Size(390, 844), Size(430, 932)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';
      testWidgets('$tag: street → studio → hidden sketch → canvases → CASE CLOSED, 2 of 12', (t) async {
        t.view.physicalSize = size * 3;
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.reset);
        // Season 1 and Paris Case 01 finished.
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
        expect(game.openEpisode('s2_ep01'), isTrue);
        game.startInvestigation();
        for (final m in case01.allMissions) {
          game.submitAnswer(m, m.answer);
        }
        expect(game.openEpisode('s2_ep02'), isTrue);
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
            File('$shots/paris02_${tag}_${(n++).toString().padLeft(2, '0')}_$name.png').writeAsBytesSync(png!.buffer.asUint8List());
          });
        }

        /// A tap at [at] (fractions) of the picture keyed [key], which must
        /// be on screen there.
        Future<void> tapOn(String key, Offset at) async {
          final picture = t.getRect(find.byKey(ValueKey(key)));
          final point = Offset(picture.left + at.dx * picture.width, picture.top + at.dy * picture.height);
          expect(point.dx, inInclusiveRange(0, size.width), reason: '$key $at on screen');
          expect(point.dy, inInclusiveRange(0, size.height), reason: '$key $at on screen');
          await t.tapAt(point);
          await wait(t, const Duration(milliseconds: 500));
        }

        Future<void> visit(String missionId) async {
          router.go(Routes.mission(missionId));
          await wait(t, const Duration(milliseconds: 1400));
        }

        Future<void> finish(String sceneLine, String name, {bool unlocked = true}) async {
          await wait(t, const Duration(milliseconds: 2800));
          expect(find.byWidgetPredicate((w) => w is Text && DiscoveryType.values.any((d) => d.cheer == w.data)), findsOneWidget);
          await shot('${name}_solved');
          await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 900));
          expect(find.text(sceneLine), findsOneWidget, reason: 'story transition');
          await t.tapAt(Offset(size.width / 2, size.height / 2)); // skip typing
          await wait(t, const Duration(milliseconds: 900));
          expect(find.byKey(const ValueKey('scene-backdrop')), findsOneWidget, reason: '$name: its own picture');
          if (unlocked) expect(find.byKey(const ValueKey('unlocked-picture')), findsOneWidget, reason: '$name: the next place');
          await shot('${name}_scene');
          await tapText(t, 'TO THE MAP', after: const Duration(milliseconds: 1200));
          await wait(t, const Duration(milliseconds: 3200));
        }

        Future<void> openLetter() async {
          await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
          await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
          await shot('letter');
          await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
        }

        Set<String> examined() => ref.read(gameControllerProvider).examined.toSet();

        // ── M1: the street and its painting ───────────────────────────────
        final compare = SeasonCatalog.compare(m1)!;
        await visit(m1.id);
        expect(find.byKey(const ValueKey('story-picture')), findsOneWidget, reason: 'the street');
        await shot('m1_place');
        await openLetter();
        expect(find.byKey(const ValueKey('compare-picture')), findsOneWidget);
        expect(find.byKey(const ValueKey('compare-painted')), findsOneWidget, reason: 'it opens on the painting');
        expect(find.text('THE PAINTING'), findsWidgets);
        await shot('m1_painting');
        // A tap on nothing changed: never wrong, a line to read the note again.
        await tapOn('compare-picture', const Offset(0.62, 0.52));
        expect(find.text(compare.missLine), findsOneWidget);
        // The street: the same spot, the other picture.
        await t.tap(find.byKey(const ValueKey('compare-show-real')));
        await wait(t, const Duration(milliseconds: 400));
        expect(find.byKey(const ValueKey('compare-real')), findsOneWidget);
        await shot('m1_street');
        // Above the red door: the clock (found on the street's picture too).
        await tapOn('compare-picture', compare.changes[0].area.center);
        expect(find.byKey(const ValueKey('found-clock')), findsOneWidget);
        expect(find.text(compare.foundLines['clock']!), findsOneWidget);
        expect(examined(), contains('s2_ep02_m1:clock'));
        // Out and back in: it opens as it was left.
        router.go(Routes.map);
        await wait(t, const Duration(milliseconds: 1400));
        await visit(m1.id);
        expect(find.byKey(const ValueKey('compare-picture')), findsOneWidget, reason: 'back on the puzzle');
        expect(find.byKey(const ValueKey('found-clock')), findsOneWidget, reason: 'still found');
        // The whole picture again after a zoom.
        await t.tap(find.byKey(const ValueKey('picture-whole')));
        await wait(t, const Duration(milliseconds: 300));
        await tapOn('compare-picture', compare.changes[1].area.center);
        expect(find.byKey(const ValueKey('found-window')), findsOneWidget);
        await shot('m1_two_found');
        await tapOn('compare-picture', compare.changes[2].area.center);
        await finish(m1.transition.first, 'm1');
        expect(ref.read(gameControllerProvider).isCompleted(m1.id), isTrue);

        // ── M2: the studio, its paintings and notes ─────────────────────
        final studio = SeasonCatalog.studio(m2)!;
        await visit(m2.id);
        expect(find.byKey(const ValueKey('story-picture')), findsOneWidget, reason: 'the studio');
        await shot('m2_place');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.text('TAP TO OPEN'), findsNothing, reason: 'the notes are found on the desk');
        expect(find.byKey(const ValueKey('studio-picture')), findsOneWidget);
        await shot('m2_studio');
        // The desk before the paintings: what to do first.
        await tapOn('studio-picture', studio.desk.areas.first.center);
        expect(find.text(studio.deskFirstLine), findsOneWidget);
        for (final p in studio.paintings) {
          await tapOn('studio-picture', p.area.center);
          expect(find.byKey(ValueKey('studio-painting-${p.id}')), findsOneWidget, reason: p.id);
          expect(find.byKey(ValueKey('painting-${p.id}')), findsOneWidget);
          await shot('m2_found_${p.id}');
          await reveal(t, find.byKey(const ValueKey('studio-painting-close')));
          await t.tap(find.byKey(const ValueKey('studio-painting-close')));
          await wait(t, const Duration(milliseconds: 400));
        }
        expect(examined(), containsAll(['s2_ep02_m2:p1', 's2_ep02_m2:p2', 's2_ep02_m2:p3']));
        expect(find.byKey(const ValueKey('desk-guide')), findsOneWidget, reason: 'the desk calls now');
        await tapOn('studio-picture', studio.desk.areas.first.center);
        expect(find.byKey(const ValueKey('studio-notes')), findsOneWidget);
        await shot('m2_notes');
        await reveal(t, find.byKey(const ValueKey('studio-notes-close')));
        await t.tap(find.byKey(const ValueKey('studio-notes-close')));
        await wait(t, const Duration(milliseconds: 400));
        await reveal(t, find.byKey(const ValueKey('studio-match')));
        await t.tap(find.byKey(const ValueKey('studio-match')));
        await wait(t, const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('studio-match-page')), findsOneWidget);
        await shot('m2_match');
        Future<void> join(String note, String painting) async {
          await reveal(t, find.byKey(ValueKey('note-$note')));
          await t.tap(find.byKey(ValueKey('note-$note')));
          await t.pump(const Duration(milliseconds: 200));
          await reveal(t, find.byKey(ValueKey('slot-$painting')));
          await t.tap(find.byKey(ValueKey('slot-$painting')));
          await t.pump(const Duration(milliseconds: 200));
        }

        // A wrong match: why, then the pairs kept to put right.
        await join('a', 'p1');
        await join('b', 'p3');
        await join('c', 'p2');
        await shot('m2_joined');
        await tapText(t, 'CHECK', after: const Duration(milliseconds: 1500));
        expect(findReadableContaining('Where are the dark clouds?'), findsWidgets);
        await shot('m2_wrong');
        await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('studio-match-page')), findsOneWidget, reason: 'still matching');
        // Dragged onto its painting this time (the paintings stay in view
        // over the notes: the note brought into view first).
        await reveal(t, find.byKey(const ValueKey('note-a')));
        await reveal(t, find.byKey(const ValueKey('slot-p2')));
        await t.drag(find.byKey(const ValueKey('note-a')), t.getCenter(find.byKey(const ValueKey('slot-p2'))) - t.getCenter(find.byKey(const ValueKey('note-a'))));
        await t.pump(const Duration(milliseconds: 300));
        await join('c', 'p1');
        await shot('m2_rejoined');
        await tapText(t, 'CHECK', after: const Duration(milliseconds: 400));
        await finish(m2.transition.first, 'm2');

        // ── M3: the paint slid away, the sketch read ────────────────────
        final layer = SeasonCatalog.layer(m3)!;
        await visit(m3.id);
        await shot('m3_place');
        await openLetter();
        expect(find.byKey(const ValueKey('layer-picture')), findsOneWidget);
        await shot('m3_paint');
        // Under the paint, nothing can be read yet.
        await tapOn('layer-picture', layer.marks[0].area.center);
        expect(find.text(layer.paintLine), findsOneWidget);
        expect(examined(), isNot(contains('s2_ep02_m3:lamp')));
        final slider = find.byKey(const ValueKey('layer-slider'));
        await reveal(t, slider);
        await t.drag(slider, Offset(t.getSize(slider).width, 0));
        await wait(t, const Duration(milliseconds: 500));
        expect(ref.read(gameControllerProvider).revealedOf(m3.id), greaterThanOrEqualTo(LayerScene.readable));
        expect(examined().where((k) => k.startsWith('s2_ep02_m3:')), isEmpty, reason: 'sliding finds nothing');
        await shot('m3_sketch');
        await tapOn('layer-picture', layer.marks[0].area.center);
        expect(find.byKey(const ValueKey('found-lamp')), findsOneWidget);
        // Out and back in: the paint stays slid, the lamp found.
        router.go(Routes.map);
        await wait(t, const Duration(milliseconds: 1400));
        await visit(m3.id);
        expect(find.byKey(const ValueKey('found-lamp')), findsOneWidget);
        await tapOn('layer-picture', layer.marks[1].area.center);
        await tapOn('layer-picture', layer.marks[2].area.center);
        await finish(m3.transition.first, 'm3');

        // ── Final: four canvases, the right one turned round ────────────
        router.go(Routes.finalMission);
        await wait(t, const Duration(milliseconds: 1600));
        expect(find.byKey(const ValueKey('canvas-stage')), findsOneWidget);
        expect(find.byKey(const ValueKey('canvas-front-a')), findsOneWidget, reason: 'it opens on canvas A');
        await shot('final_page');
        final turn = find.byKey(const ValueKey('canvas-turn'));
        await reveal(t, turn);
        expect(t.widget<GameButton>(turn).onPressed, isNull, reason: 'every canvas looked at first');
        expect(find.byKey(const ValueKey('canvas-look-first')), findsOneWidget);
        for (final id in ['b', 'c', 'd', 'a']) {
          await reveal(t, find.byKey(ValueKey('canvas-$id')));
          await t.tap(find.byKey(ValueKey('canvas-$id')));
          await t.pump(const Duration(milliseconds: 300));
        }
        expect(examined(), containsAll(['s2_ep02_final:a', 's2_ep02_final:b', 's2_ep02_final:c', 's2_ep02_final:d']));
        await shot('final_canvases');
        // The red door: its clue says why not.
        await reveal(t, turn);
        await t.tap(turn);
        await wait(t, const Duration(milliseconds: 1500));
        expect(findReadableContaining('Is there a red door?'), findsWidgets);
        await shot('final_wrong');
        await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
        await reveal(t, find.byKey(const ValueKey('canvas-c')));
        await t.tap(find.byKey(const ValueKey('canvas-c')));
        await t.pump(const Duration(milliseconds: 300));
        await reveal(t, turn);
        await t.tap(turn);
        await wait(t, const Duration(milliseconds: 3600));
        expect(find.byKey(const ValueKey('canvas-back')), findsOneWidget, reason: 'turned round');
        expect(find.byKey(const ValueKey('canvas-message')), findsOneWidget);
        expect(ref.read(gameControllerProvider).isCaseSolved, isTrue);
        await shot('final_turned');
        await tapText(t, 'READ THE BACK', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('canvas-back-close')), findsOneWidget);
        await shot('final_back');
        await tapText(t, 'BACK TO THE STUDIO', after: const Duration(milliseconds: 700));
        expect(examined(), contains('s2_ep02_final:back'));
        await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 900));
        expect(find.text(fin.transition.first), findsOneWidget);
        await t.tapAt(Offset(size.width / 2, size.height / 2));
        await wait(t, const Duration(milliseconds: 900));
        expect(find.text('He left on his own.'), findsOneWidget);
        expect(find.byKey(const ValueKey('scene-backdrop')), findsOneWidget, reason: 'the back of the canvas');
        await shot('final_scene');

        // Paris: 2 of 12, Case 03 opens next.
        final board = ref.read(seasonOverviewProvider);
        expect(board.solvedCount, 2);
        expect(board.comingSoonCase, isNull);
        expect(board.current, 2);
        await wait(t, const Duration(seconds: 3));
      });
    }
  });

  group('its pictures\' answer places', () {
    const pixels = ScenePixels(1536, 1024);
    const door = PictureSpot('clock', Rect.fromLTRB(0.40, 0.20, 0.50, 0.30));

    test('a touch is found on the picture whatever the screen, zoom or move', () {
      const box = Size(360, 400);
      final shown = fittedPicture(box: box, pixels: pixels);
      expect(shown.width, 360);
      expect(shown.top, closeTo((400 - 240) / 2, 1e-9));
      Offset onScreen(Offset f) => Offset(shown.left + f.dx * shown.width, shown.top + f.dy * shown.height);
      final middle = door.area.center;
      expect(door.contains(pictureFraction(onScreen(middle), box: box, pixels: pixels)!, pixels: pixels), isTrue);
      expect(pictureFraction(const Offset(180, 10), box: box, pixels: pixels), isNull);
      final viewer = Matrix4.identity()
        ..translateByDouble(-200.0, -90.0, 0, 1)
        ..scaleByDouble(2.5, 2.5, 1, 1);
      final zoomed = MatrixUtils.transformPoint(viewer, onScreen(middle));
      final f = pictureFraction(zoomed, box: box, pixels: pixels, viewer: viewer)!;
      expect(f.dx, closeTo(middle.dx, 1e-9));
      expect(f.dy, closeTo(middle.dy, 1e-9));
      const tall = Size(430, 300);
      final cover = fittedPicture(box: tall, pixels: pixels, fit: BoxFit.cover);
      final at = Offset(cover.left + middle.dx * cover.width, cover.top + middle.dy * cover.height);
      expect(door.contains(pictureFraction(at, box: tall, pixels: pixels, fit: BoxFit.cover)!, pixels: pixels), isTrue);
    });

    test('a fingertip just off a place still finds it; farther off does not', () {
      final justOff = Offset(door.area.right + 0.01, door.area.center.dy);
      expect(door.contains(justOff, pixels: pixels), isFalse);
      expect(door.contains(justOff, pixels: pixels, slop: 0.02), isTrue);
      expect(door.contains(const Offset(0.9, 0.9), pixels: pixels, slop: 0.02), isFalse);
      // The scenes find their own places the same way.
      final compare = SeasonCatalog.compare(m1)!;
      for (final c in compare.changes) {
        expect(compare.changeAt(c.area.center)!.id, c.id);
      }
      expect(compare.changeAt(const Offset(0.05, 0.95)), isNull);
      final layer = SeasonCatalog.layer(m3)!;
      for (final m in layer.marks) {
        expect(layer.markAt(m.area.center)!.id, m.id);
      }
    });

    test('how far the paint is slid is saved apart from what is found under it, and old saves read as before', () {
      const p = GameProgress(revealed: {'s2_ep02_m3': 0.6}, examined: ['s2_ep02_m3:lamp']);
      final back = GameProgress.fromJson(p.toJson());
      expect(back.revealedOf('s2_ep02_m3'), 0.6);
      expect(back.hasExamined('s2_ep02_m3:lamp'), isTrue);
      expect(const GameProgress().toJson().containsKey('revealed'), isFalse, reason: 'old saves unchanged');
      expect(GameProgress.fromJson(const {}).revealed, isEmpty);
      expect(GameProgress.fromJson(const {'revealed': {'x': 3, 'y': 'no'}}).revealed, {'x': 1.0});
      expect(p.resetCase().revealed, isEmpty, reason: 'play again starts the paint over');
    });
  });
}
