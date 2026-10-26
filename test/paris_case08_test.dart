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
import 'package:london_mystery/data/mock/season2/season2_case08_scenes.dart';
import 'package:london_mystery/data/mock/season2/season2_discoveries.dart';
import 'package:london_mystery/data/mock/season2/season2_learning.dart';
import 'package:london_mystery/data/mock/season2/season2_mock.dart';
import 'package:london_mystery/data/mock/season_catalog.dart';
import 'package:london_mystery/data/models/abbesses_puzzles.dart';
import 'package:london_mystery/data/models/discovery.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/learning.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/opera_puzzles.dart' show AmendmentSlip;
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/river_puzzles.dart';
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/models/tower_puzzles.dart' show boardAnswerOf;
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/mission/widgets/abbesses_papers.dart';
import 'package:london_mystery/features/mission_map/map_world.dart';
import 'package:london_mystery/features/season/season_overview.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';

/// Season 2, Case 08 — The Painter's Last Sketch: its twelve pictures (as
/// delivered, measured), its story and puzzles as the Hidden Sketch, P.'s
/// drawings, the torn paper and the board say them, its rules (unlock after
/// Case 07, saves, Case 09 next), and a child playing it through on three
/// phones. Nothing is told before its time; who carried the bag, what its
/// badge means, whose change it was, and any name, never.
///
/// `LM_SHOTS=folder` saves a picture of each step of the play-through.
void main() {
  final inGame = MockEpisodeRepository.bundled();
  final s1 = season1Cases();
  final paris = [for (final id in ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05', 's2_ep06', 's2_ep07']) inGame.firstWhere((e) => e.id == id)];
  final case07 = paris.last;
  final case08 = inGame.firstWhere((e) => e.id == 's2_ep08');
  final [m1, m2, m3, fin] = case08.allMissions;
  final shots = Platform.environment['LM_SHOTS'];

  final corners = SeasonCatalog.cornerChoice(m1)!;
  final sketches = SeasonCatalog.morningSketches(m2)!;
  final slip = SeasonCatalog.tornSlip(m3)!;
  final hour = SeasonCatalog.tornHour(fin)!;

  /// Kept once P.'s last drawing is done (and the case closed with it).
  final leadKey = GameProgress.examinedKey(fin.id, TornHourScene.leadId);

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

  String everything(Iterable<Mission> missions, {Episode? e}) => [
        if (e != null) ...[...e.intro, ...e.synopsis, ...e.objectives, e.hook, e.caseSummary],
        for (final m in missions) ...[
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
          m.successMessage,
          m.clue?.note ?? '',
          m.evidence?.description ?? '',
          m.evidence?.inscription ?? '',
        ],
      ].join('\n');

  /// What a mission shows before it is solved.
  String beforeSolved(Mission m) =>
      [...m.story, m.letterIntro, m.letter, m.question, ...m.hints, for (final o in m.options) o.feedback ?? '', ...m.feedback.values].join('\n');

  group('its pictures', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const folder = 'assets/seasons/season_02_paris/cases/case_08';
    // Size, and whether it has an alpha channel (as delivered, never
    // changed).
    const pictures = {
      'abbesses_square.png': (1536, 1024, false),
      'corner_1.png': (1536, 1024, false),
      'corner_2.png': (1536, 1024, false),
      'corner_3.png': (1536, 1024, false),
      'drawing_bundle.png': (1536, 1024, false),
      'torn_form_blank.png': (1536, 1024, true),
      'folded_paper.png': (1254, 1254, true),
      'sketch_morning_1_dark.png': (1536, 1024, true),
      'sketch_morning_2_bag.png': (1536, 1024, true),
      'sketch_morning_3_light.png': (1536, 1024, true),
      'paper_study.png': (1254, 1254, true),
      'last_sketch_garden.png': (1536, 1024, true),
    };

    (int, int, bool) header(Uint8List b) {
      final d = ByteData.sublistView(b);
      final colourType = b[25];
      return (d.getUint32(16), d.getUint32(20), colourType == 4 || colourType == 6);
    }

    Future<(ByteData, int, int)> pixels(String path) async {
      final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
      final image = (await codec.getNextFrame()).image;
      return ((await image.toByteData(format: ui.ImageByteFormat.rawRgba))!, image.width, image.height);
    }

    double brightness(ByteData d, int w, Rect r) {
      var sum = 0.0;
      var n = 0;
      for (var y = r.top.toInt(); y < r.bottom; y += 4) {
        for (var x = r.left.toInt(); x < r.right; x += 4) {
          final i = (y * w + x) * 4;
          sum += (d.getUint8(i) + d.getUint8(i + 1) + d.getUint8(i + 2)) / 3;
          n++;
        }
      }
      return sum / n;
    }

    test('all twelve are in, listed in pubspec, at their sizes', () {
      expect(pubspecAssets(), contains('$folder/'), reason: 'its folder, exactly, in flutter: assets:');
      expect(Directory(folder).listSync().whereType<File>().where((f) => f.path.endsWith('.png')).length, 12);
      for (final MapEntry(key: name, value: (w, h, alpha)) in pictures.entries) {
        final file = File('$folder/$name');
        expect(file.existsSync(), isTrue, reason: name);
        final (pw, ph, a) = header(file.readAsBytesSync());
        expect((pw, ph), (w, h), reason: name);
        expect(a, alpha, reason: name);
      }
    });

    test("every one of them is played on; Case 08's places have their pictures", () {
      final scenes = [File('lib/data/mock/season2/season2_case08_scenes.dart').readAsStringSync(), File('lib/widgets/art_assets.dart').readAsStringSync()].join();
      for (final name in pictures.keys) {
        expect(scenes, contains(name), reason: name);
      }
      expect(ArtAssets.parisScenes[case08.introScene], '$folder/abbesses_square.png');
      for (final m in case08.allMissions) {
        expect(ArtAssets.parisScenes[m.scene], isNotNull, reason: m.id);
      }
    });

    test('the cut-outs are truly clear round their paper', () async {
      for (final name in pictures.entries.where((e) => e.value.$3).map((e) => e.key)) {
        final (d, w, h) = await pixels('$folder/$name');
        int alphaAt(int x, int y) => d.getUint8((y * w + x) * 4 + 3);
        expect(alphaAt(2, 2), 0, reason: '$name: a clear corner');
        expect(alphaAt(w - 3, h - 3), 0, reason: name);
      }
    });

    test("P.'s three drawings are one drawing in register; the sky and the lamp give their order", () async {
      final [(d1, w, _), (d2, _, _), (d3, _, _)] = [
        for (final s in sketches.sketches) await pixels(s.file),
      ];
      // The sky: dark, then grey, then white.
      const sky = Rect.fromLTRB(600, 60, 760, 200);
      final skies = [for (final d in [d1, d2, d3]) brightness(d, w, sky)];
      expect(skies[0], lessThan(skies[1]));
      expect(skies[1], lessThan(skies[2]));
      // The lamp's glass: lit, lit, out.
      const glass = Rect.fromLTRB(415, 290, 465, 340);
      final lamps = [for (final d in [d1, d2, d3]) brightness(d, w, glass)];
      expect(lamps[2], lessThan(lamps[0] - 20), reason: 'the third lamp is out');
      expect(lamps[2], lessThan(lamps[1] - 20));
      // The steps, the lamp post and the right pillar stay where they are.
      for (final part in const [Rect.fromLTRB(405, 600, 475, 840), Rect.fromLTRB(915, 520, 995, 840)]) {
        double gap(ByteData a, ByteData b) {
          var sum = 0.0;
          var n = 0;
          for (var y = part.top.toInt(); y < part.bottom; y += 3) {
            for (var x = part.left.toInt(); x < part.right; x += 3) {
              final i = (y * w + x) * 4;
              sum += ((a.getUint8(i) + a.getUint8(i + 1) + a.getUint8(i + 2)) - (b.getUint8(i) + b.getUint8(i + 1) + b.getUint8(i + 2))).abs() / 3;
              n++;
            }
          }
          return sum / n;
        }

        expect(gap(d1, d2), lessThan(40), reason: '$part: drawing 2 in register');
        expect(gap(d1, d3), lessThan(40), reason: '$part: drawing 3 in register');
      }
    });
  });

  group('in the game', () {
    test('Case 08 is in the game, after Case 07, in Abbesses, with its four puzzles', () {
      expect(SeasonCatalog.byId(SeasonIds.paris)!.episodes.keys, ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05', 's2_ep06', 's2_ep07', 's2_ep08', 's2_ep09', 's2_ep10', 's2_ep11', 's2_ep12']);
      expect(season2AwaitingArtJson, isEmpty);
      expect(const MockEpisodeRepository().fetchEpisode('s2_ep08'), completes);
      expect(case08.number, 8);
      expect(case08.seasonId, SeasonIds.paris);
      expect(case08.title, "The Painter's Last Sketch");
      expect(case08.place, 'ABBESSES · MONTMARTRE');
      expect([for (final m in case08.allMissions) m.id], ['s2_ep08_m1', 's2_ep08_m2', 's2_ep08_m3', 's2_ep08_final']);
      expect([for (final m in case08.allMissions) m.title], ['The Hidden Sketch', 'The Morning Drawing', 'The Purple Seal', 'The Torn Hour']);
      expect([for (final m in case08.allMissions) m.evidence!.name], ["The Painter's Spot", 'The Bag Sketch', 'The Matching Seal', 'The Torn Hour']);
      expect([for (final m in case08.missions) m.clue!.title], ["The Painter's Corner", 'It Fell from the Bag', 'The Same Seal']);
      expect(ParisLandmark.cases['s2_ep08'], ParisLandmark.montmartre);
      expect(case08.introScene, Artwork.abbessesSquare);
      expect([for (final m in case08.allMissions) m.scene], [Artwork.abbessesSquare, Artwork.drawingBundle, Artwork.drawingBundle, Artwork.paintersCorner]);
      for (final m in case08.allMissions) {
        expect(SeasonCatalog.storyScenes(m)?.after, isNotNull, reason: m.id);
        expect(SeasonCatalog.evidenceArt(m.evidence!.id), isA<DrawnEvidenceArt>(), reason: m.id);
      }
      expect(SeasonCatalog.introPaper('s2_ep08')?.paper, isA<AmendmentSlip>());
      expect((SeasonCatalog.introPaper('s2_ep08')!.paper as AmendmentSlip).showBack, isTrue, reason: "it opens on the slip's back");
    });

    test('its Discovery Moments name what each mission found', () {
      expect(season2DiscoveryTypes['s2_ep08_m1'], DiscoveryType.newLead);
      expect(season2DiscoveryTypes['s2_ep08_m2'], DiscoveryType.deduction);
      expect(season2DiscoveryTypes['s2_ep08_m3'], DiscoveryType.evidenceFound);
      for (final m in case08.missions) {
        expect(SeasonCatalog.discovery(m).title, m.successMessage, reason: m.id);
      }
    });

    test("Case 08 leads on to Case 09 (the bible's title), now in the game", () {
      final season = SeasonCatalog.byId(SeasonIds.paris)!.season;
      expect(season.upcomingTitles.containsKey(9), isFalse, reason: 'Case 09 is no longer to come: it is in the game');
      expect(inGame.firstWhere((e) => e.id == 's2_ep09').title, 'The Clockwork Garden');
      expect(File('docs/SEASON2_PARIS_STORY_BIBLE.md').readAsStringSync(), contains('| 09 | **The Clockwork Garden** | Luxembourg Gardens |'));
      expect(case08.hook, 'Why did the bag go to the little clock in the garden?');
      expect(case07.hook, 'What did P. see — and what was in the bag?', reason: 'Case 07 is as it was');
    });
  });

  group('its story and puzzles', () {
    test("it opens on the back of Case 07's slip: ABBESSES and P. KNEW THE BAG.", () {
      expect(case08.intro, contains('Under it: P. KNEW THE BAG.'));
      final back = (SeasonCatalog.introPaper('s2_ep08')!.paper as AmendmentSlip).back;
      expect((back.sign, back.note), ('ABBESSES', 'P. KNEW THE BAG.'));
      expect(SeasonCatalog.introPaper('s2_ep08')!.afterLine, case08.intro.indexOf('Under it: P. KNEW THE BAG.'));
      // The objectives never say what fell from the bag.
      expect(case08.objectives.join(' '), isNot(contains('fell')));
    });

    test("M1: the Hidden Sketch decides two ways — its picture and its words — and nothing else does", () {
      expect(m1.recall!.evidenceId, 's2_ep02_e3', reason: "Case 02's Hidden Sketch");
      final hidden = case02Evidence('s2_ep02_e3', inGame);
      expect(hidden.inscription, contains('The gate is black.'));
      expect(m1.letter, isNot(contains('black')), reason: "the colour is in the sketch's words, not the note");
      expect(m1.letter, isNot(contains('left')), reason: 'where the lamp stands is in its picture');
      expect([for (final c in corners.corners) c.id], [for (final o in m1.options) o.id]);
      expect(m1.answer, 'corner2');
      expect(m1.hideOptionNames, isTrue);
      // Each wrong corner fails exactly one of the two.
      expect(corners.corner('corner1').label, allOf(contains('left of a dark green'), contains('church above')));
      expect(corners.corner('corner3').label, allOf(contains('right of a black'), contains('church above')));
      expect(corners.corner('corner2').label, allOf(contains('left of a black'), contains('church above')));
      expect(AnswerChecker.feedbackFor(m1, 'corner1'), contains('What colour is the gate?'));
      expect(AnswerChecker.feedbackFor(m1, 'corner3'), contains('on the left of the gate, or on the right?'));
      // The three corners on the square do not overlap.
      for (final a in corners.corners) {
        for (final b in corners.corners) {
          if (a != b) expect(a.area.overlaps(b.area), isFalse, reason: '${a.id} ${b.id}');
        }
      }
    });

    test('M2: one order only, by the sky and the lamp; the paper comes after the bag', () {
      expect(sketches.order, ['dark', 'bag', 'light']);
      expect(sketches.shown, ['light', 'dark', 'bag'], reason: 'never shown in order');
      expect(sketches.lineFor(['dark', 'bag', 'light']), isNull);
      for (final order in [
        ['light', 'dark', 'bag'],
        ['dark', 'light', 'bag'],
        ['light', 'bag', 'dark'],
        ['bag', 'light', 'dark'],
      ]) {
        expect(sketches.lineFor(order), sketches.lampLine, reason: '$order: the lamp is out before the end');
      }
      expect(sketches.lineFor(['bag', 'dark', 'light']), sketches.skyLine);
      expect(m2.letter, allOf(contains('First, the sky was dark.'), contains('When the sun came up, the lamps went out.')));
      expect(m2.letter, isNot(contains('bag')), reason: 'the tag gives the rule, never the answer');
      // The paper is new in drawing 3 only; the bag in drawing 2 only.
      expect([for (final c in sketches.sketch('bag').changes) c.id], ['person', 'gate', 'badge']);
      expect([for (final c in sketches.sketch('light').changes) c.id], ['lamp', 'gone', 'paper', 'study']);
      expect(m2.answer, 'bag');
      expect(AnswerChecker.feedbackFor(m2, 'always'), contains('drawings 1 and 2'));
      // Saved and back.
      const s = SketchState(placed: ['dark', 'bag', 'light'], ordered: true, found: {'person', 'gate'});
      final back = SketchState.decode(s.encode(), sketches);
      expect(back.placed, ['dark', 'bag', 'light']);
      expect(back.ordered, isTrue);
      expect(back.found, {'person', 'gate'});
      expect(SketchState.decode('order=bag,dark,light;ok=1;found=nope', sketches).ordered, isFalse, reason: 'checked right only while it is');
    });

    test("M3: P.'s note says he picked it up, never where it came from; same and missing are marked", () {
      expect(m3.letter, contains('I found this paper on the steps.'));
      expect(m3.letter, isNot(contains('bag')));
      expect(m3.recall!.evidenceId, 's2_ep07_e3', reason: "Case 07's Amendment Slip");
      expect(AnswerChecker.isCorrect(m3, slip.answerOf({'border', 'band', 'arrow', 'seal'}, {'number', 'hour'})), isTrue);
      expect(AnswerChecker.feedbackFor(m3, slip.answerOf({'border', 'band'}, {})), contains('Four things'));
      expect(AnswerChecker.feedbackFor(m3, slip.answerOf({'border', 'band', 'arrow'}, {'number', 'hour'})), contains('Count the hands'));
      expect(AnswerChecker.feedbackFor(m3, slip.answerOf({'border', 'band', 'arrow', 'seal'}, {'number'})), contains('in front of :00'));
      expect(AnswerChecker.feedbackFor(m3, slip.answerOf({'border', 'band', 'arrow', 'seal'}, {'hour'})), contains('after FILE'));
      // A fold, the tear and the dust only say what they are.
      expect(slip.partAt(800, 700)?.line, contains('folds'));
      expect(slip.partAt(1400, 600)?.line, contains('not torn'));
      expect(slip.partAt(200, 800)?.line, contains('dust'));
      expect(slip.partAt(1050, 700)?.id, 'seal');
      expect(slip.partAt(780, 470)?.id, 'hour');
      // The paper's words: FILE, the minutes and an arrow; no number, no hour.
      expect((slip.form.fileWord, slip.form.minutes), ('FILE', ':00'));
      const saved = SlipState(opened: 3, same: {'seal'}, missing: {'hour'});
      final back = SlipState.decode(saved.encode(), slip);
      expect(back.opened, 3);
      expect(back.same, {'seal'});
      expect(back.missing, {'hour'});
    });

    test('the final: the paper fits its drawing one way; the board says no more than the evidence', () {
      expect(hour.startTurns, isNot(0), reason: 'it never starts the right way round');
      expect(hour.board.evidence.map((e) => e.evidenceId), ['s2_ep08_e1', 's2_ep08_e2', 's2_ep08_e3', 's2_ep07_e3']);
      expect(boardAnswerOf(hour.board, {'q1': {'e2'}, 'q2': {'e3', 'e4'}}, 'fell'), fin.answer);
      expect(AnswerChecker.isCorrect(fin, fin.answer), isTrue);
      expect(AnswerChecker.feedbackFor(fin, boardAnswerOf(hour.board, {'q1': {'e1'}, 'q2': {'e3', 'e4'}}, 'fell')), contains('where P. sat'));
      expect(AnswerChecker.feedbackFor(fin, boardAnswerOf(hour.board, {'q1': {'e2'}, 'q2': {'e3'}}, 'fell')), contains('old clue'));
      expect(AnswerChecker.feedbackFor(fin, boardAnswerOf(hour.board, {'q1': {'e2'}, 'q2': {'e3', 'e4'}}, 'who')), contains('What do we really know?'));
      expect(hour.board.conclusions.firstWhere((c) => c.id == 'fell').text, 'A paper for changing a time fell from the bag.');
      expect(fin.evidence!.inscription, contains('Who carried it, and who changed what, is not known.'));
      // The last drawing: three parts of the bag, a basket that is not it.
      final lead = hour.lead;
      expect(lead.partAt(520, 492)?.id, 'badge', reason: 'the smallest part where they meet');
      expect(lead.partAt(560, 540)?.id, 'buckles');
      expect(lead.partAt(470, 450)?.id, 'flat');
      expect(lead.partAt(1170, 770)?.id, 'basket');
      expect(lead.answer, 'luxembourgGardens');
      expect(lead.spots.map((s) => s.id), contains('louvre'));
      expect(lead.lineFor('louvre'), contains('glass pyramid'));
    });

    test('nothing is told before its time: no name, no trial, no answer early', () {
      final all = everything(case08.allMissions, e: case08);
      for (final word in ['Victor', 'Delacroix', 'Émile', 'Emile', 'Moreau', 'Chronos', 'trial', 'Trial', 'Clockmaker', 'Box 23', 'stolen hour']) {
        expect(all, isNot(contains(word)), reason: word);
      }
      expect(beforeSolved(m1), isNot(contains('black')));
      expect([...case08.intro, ...case08.objectives, beforeSolved(m1), beforeSolved(m2)].join(), isNot(contains('fell from the bag')), reason: 'found in M2, not told');
      expect(beforeSolved(m3), isNot(contains('bag')));
      expect(beforeSolved(fin), isNot(contains('A paper for changing a time fell from the bag.')));
      expect(fin.transition.join(' '), contains('Luxembourg Gardens'), reason: 'after the last drawing is matched to the map');
    });

    test('its learning design: every expression is on its screens', () {
      expect(season2LanguageTopics['s2_ep08'], isNotNull);
      String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      String screen(Mission m) => norm([...m.story, m.letterIntro, m.letter, m.question, for (final o in m.options) o.label, ...m.hints].join(' \n '));
      for (final m in case08.allMissions) {
        final l = season2Learning[m.id]!;
        expect(l.dependency, LanguageDependency.essential, reason: m.id);
        for (final e in l.expressions) {
          expect(screen(m), contains(norm(e)), reason: '${m.id}: "$e" is on its screens');
        }
      }
    });

    test('its evidence leads on from Case 02 and Case 07, one piece to the next', () {
      expect(SeasonCatalog.evidenceLink('s2_ep08_e1')!.to, 's2_ep02_e3');
      expect(SeasonCatalog.evidenceLink('s2_ep08_e3')!.to, 's2_ep07_e3');
      expect(SeasonCatalog.evidenceLink('s2_ep08_e4')!.to, 's2_ep08_e2');
      expect(SeasonCatalog.evidenceLink('s2_ep07_e3')!.to, 's2_ep02_e1', reason: "Case 07's links are as they were");
    });
  });

  group('its rules', () {
    late SharedPreferences prefs;

    Future<ProviderContainer> start() async {
      final c = ProviderContainer(overrides: await testOverridesFor(prefs));
      addTearDown(c.dispose);
      return c;
    }

    /// Every answer of [e]; Case 08 then closed with its last drawing.
    void solve(ProviderContainer c, Episode e) {
      final game = c.read(gameControllerProvider.notifier);
      expect(game.openEpisode(e.id), isTrue, reason: e.id);
      game.startInvestigation();
      for (final m in e.allMissions) {
        expect(game.submitAnswer(m, m.answer).result, SubmitResult.correct, reason: m.id);
      }
      if (e == case08) expect(game.closeCase(leadKey), isTrue);
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: await testOverridesFor(prefs));
      c.read(gameControllerProvider.notifier).createDetective('Kim', DetectiveAvatar.girl);
      c.read(progressRepositoryProvider).saveSeason(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: [for (final e in s1) e.id]));
      c.dispose();
    });

    test('it opens only once Case 07 is solved', () async {
      final c = await start();
      final game = c.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      for (final e in paris.take(6)) {
        solve(c, e);
      }
      expect(game.openEpisode('s2_ep08'), isFalse, reason: 'no way round Case 07');
      solve(c, case07);
      expect(c.read(seasonProvider.notifier).isUnlocked('s2_ep08'), isTrue);
      expect(game.openEpisode('s2_ep08'), isTrue);
      expect(c.read(currentEpisodeProvider).id, 's2_ep08');
    });

    test('what is looked at, ordered, found, marked and laid is saved and comes back after a restart', () async {
      var c = await start();
      var game = c.read(gameControllerProvider.notifier);
      game.openSeason(SeasonIds.paris);
      for (final e in paris) {
        solve(c, e);
      }
      game.openEpisode('s2_ep08');
      game.startInvestigation();
      game.recordExamined(GameProgress.examinedKey(m1.id, CornerChoiceScene.lookedKey('corner1')));
      expect(game.submitAnswer(m1, 'corner1').result, SubmitResult.tryAgain);
      expect(game.submitAnswer(m2, m2.answer).result, SubmitResult.locked, reason: 'missions in order');
      expect(game.submitAnswer(m1, m1.answer).result, SubmitResult.correct);
      game.recordPuzzleState(m2.id, const SketchState(placed: ['dark', 'bag', 'light'], ordered: true, found: {'person'}).encode());

      c.dispose();
      c = await start();
      game = c.read(gameControllerProvider.notifier);
      expect(c.read(currentEpisodeProvider).id, 's2_ep08');
      var p = c.read(gameControllerProvider);
      expect(p.isCompleted(m1.id), isTrue);
      expect(p.wrongCount(m1.id), 1);
      expect(p.hasExamined('${m1.id}:corner-corner1'), isTrue);
      final sketchState = SketchState.decode(p.puzzleStateOf(m2.id), sketches);
      expect(sketchState.ordered, isTrue);
      expect(sketchState.found, {'person'});
      expect(game.submitAnswer(m2, 'window').result, SubmitResult.tryAgain);
      expect(game.submitAnswer(m2, m2.answer).result, SubmitResult.correct);
      game.recordPuzzleState(m3.id, const SlipState(opened: 3, same: {'border'}).encode());
      expect(game.submitAnswer(m3, m3.answer).result, SubmitResult.correct);
      game.recordExamined(GameProgress.examinedKey(fin.id, TornHourScene.placedId));

      c.dispose();
      c = await start();
      game = c.read(gameControllerProvider.notifier);
      p = c.read(gameControllerProvider);
      expect(SlipState.decode(p.puzzleStateOf(m3.id), slip).same, {'border'});
      expect(p.hasExamined('${fin.id}:placed'), isTrue);
      expect(game.submitAnswer(fin, fin.answer).result, SubmitResult.correct);
      p = c.read(gameControllerProvider);
      expect([for (final e in p.collectedEvidence(case08)) e.name], ["The Painter's Spot", 'The Bag Sketch', 'The Matching Seal', 'The Torn Hour']);
      // Answered, not closed: the last drawing waits.
      expect(p.isCompleted(fin.id), isTrue);
      expect(p.isCaseSolved, isFalse);
      expect(p.finalAwaitsLastStep(case08), isTrue);

      c.dispose();
      c = await start();
      game = c.read(gameControllerProvider.notifier);
      p = c.read(gameControllerProvider);
      expect((p.isCompleted(fin.id), p.isCaseSolved), (true, false), reason: 'after a restart: answered, still open');
      expect(game.closeCase(leadKey), isTrue);
      p = c.read(gameControllerProvider);
      expect(p.isCaseSolved, isTrue);
      expect(c.read(progressRepositoryProvider).load('s2_ep07').isCaseSolved, isTrue, reason: "Case 07's save is its own");
      expect(c.read(progressRepositoryProvider).load('s2_ep07').examined.any((k) => k.startsWith('s2_ep08')), isFalse);
    });

    test('solved: Paris is 8 of 12, Case 09 opens next; London is as it was', () async {
      final c = await start();
      final game = c.read(gameControllerProvider.notifier);
      game.openSeason(SeasonIds.paris);
      for (final e in [...paris, case08]) {
        solve(c, e);
      }
      final board = c.read(seasonOverviewProvider);
      expect(board.solvedCount, 8);
      expect(board.comingSoonCase, isNull, reason: 'Case 09 is in the game: nothing is only coming');
      final available = c.read(seasonAvailabilityProvider(SeasonIds.paris))!;
      expect((available.solvedCount, available.plannedCount), (8, 12));
      expect(game.openEpisode('s2_ep09'), isTrue, reason: 'Case 09 opens after Case 08');
      expect(c.read(progressRepositoryProvider).loadSeason(SeasonIds.london).solvedEpisodeIds, hasLength(12));
    });
  });

  group('a child plays Case 08', () {
    Future<WidgetRef> open(WidgetTester t, Size size) async {
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
            AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: [for (final e in s1) e.id]).toJson()),
          }),
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
      final game = ref.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      for (final e in paris) {
        expect(game.openEpisode(e.id), isTrue);
        game.startInvestigation();
        for (final m in e.allMissions) {
          game.submitAnswer(m, m.answer);
        }
      }
      return ref;
    }

    for (final size in const [Size(360, 640), Size(390, 844), Size(430, 932)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';
      testWidgets('$tag: Case 07 closed → corners → drawings → torn paper → paper on the drawing, board and last drawing, 8 of 12', (t) async {
        final ref = await open(t, size);
        final router = ref.read(routerProvider);
        final game = ref.read(gameControllerProvider.notifier);
        final coinsAtStart = ref.read(walletProvider).balance;

        var n = 0;
        Future<void> shot(String name) async {
          expect(t.takeException(), isNull, reason: '$tag $name: no overflow, no error');
          if (shots == null) return;
          await t.runAsync(() async {
            for (final e in find.byType(Image).evaluate()) {
              await precacheImage((e.widget as Image).image, e);
            }
            await Future<void>.delayed(const Duration(milliseconds: 400));
          });
          await t.pump();
          await t.runAsync(() async {
            final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
            final image = await boundary.toImage(pixelRatio: 1);
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            File('$shots/paris08_${tag}_${(n++).toString().padLeft(2, '0')}_$name.png').writeAsBytesSync(png!.buffer.asUint8List());
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

        /// A tap on a picture at its own pixels ([pixels] big, [crop] of it
        /// shown in the widget with [key]).
        Future<void> tapPicture(String key, Offset at, {Size pixels = const Size(1536, 1024), Rect? crop, Duration after = const Duration(milliseconds: 300)}) async {
          await reveal(t, find.byKey(ValueKey(key)));
          final r = t.getRect(find.byKey(ValueKey(key)));
          final c = crop ?? Offset.zero & pixels;
          await t.tapAt(Offset(r.left + (at.dx - c.left) / c.width * r.width, r.top + (at.dy - c.top) / c.height * r.height));
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

        /// A tile of the notebook's sheet tapped, scrolled into view in the
        /// sheet's own list.
        Future<void> pickInSheet(String key, {Duration after = const Duration(milliseconds: 500)}) async {
          final f = find.byKey(ValueKey(key));
          if (f.evaluate().isEmpty) {
            final list = find.descendant(of: find.byType(DraggableScrollableSheet), matching: find.byType(Scrollable)).first;
            t.state<ScrollableState>(list).position.jumpTo(0);
            await t.pump();
            if (f.evaluate().isEmpty) await t.scrollUntilVisible(f, 200, scrollable: list);
          }
          await Scrollable.ensureVisible(t.element(f), alignment: 0.5);
          await t.pump();
          await t.tap(f);
          await wait(t, after);
        }

        Future<void> bring(String evidenceId, {List<(String, String)> wrong = const []}) async {
          await tapKey('evidence-recall-open', after: const Duration(milliseconds: 700));
          for (final (id, line) in wrong) {
            await pickInSheet('recall-pick-$id');
            expect(findReadable(line), findsOneWidget, reason: id);
          }
          await pickInSheet('recall-pick-$evidenceId', after: const Duration(milliseconds: 800));
          expect(find.byKey(const ValueKey('evidence-recall-brought')), findsOneWidget);
        }

        Set<String> examined() => ref.read(gameControllerProvider).examined.toSet();
        void finger(String key) {
          final r = t.getRect(find.byKey(ValueKey(key)));
          expect(r.width >= 44 && r.height >= 44, isTrue, reason: '$tag $key: finger-sized ($r)');
        }

        // ── Case 07's Case Closed: on to Case 08 ────────────────────────
        router.go(Routes.solvedSettled);
        await wait(t, const Duration(milliseconds: 3000));
        await reveal(t, find.text('OPEN CASE 08'));
        expect(find.text('OPEN CASE 08'), findsOneWidget, reason: 'Case 08 is in the game now');
        expect(game.openEpisode('s2_ep08'), isTrue);

        // ── The opening: the back of the slip ───────────────────────────
        router.go(Routes.intro);
        await wait(t, const Duration(milliseconds: 900));
        await tapText(t, 'SKIP ›', after: const Duration(milliseconds: 900));
        await reveal(t, find.byKey(const ValueKey('intro-paper')));
        expect(find.byKey(const ValueKey('intro-paper')), findsOneWidget);
        expect(find.byKey(const ValueKey('slip-note')), findsOneWidget, reason: 'P. KNEW THE BAG., on the slip itself');
        expect(find.byKey(const ValueKey('slip-sign')), findsOneWidget);
        await shot('opening');
        await tapText(t, "I'M READY", after: const Duration(milliseconds: 1600));

        // ── M1: the square of Abbesses ──────────────────────────────────
        await visit(m1.id);
        expect(find.byKey(const ValueKey('story-picture')), findsOneWidget, reason: 'the square');
        await shot('m1_place');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('corner-square')), findsOneWidget);
        expect(find.byKey(const ValueKey('evidence-recall')), findsOneWidget, reason: 'the Hidden Sketch card under the page');
        expect(find.text('These steps look familiar...'), findsOneWidget);
        for (final c in corners.corners) {
          finger('corner-tab-${c.id}');
        }
        await shot('m1_square');
        // Corner 1 from the bench, chosen without the sketch's words.
        await tapKey('corner-tab-corner1');
        expect(find.byKey(const ValueKey('corner-view-corner1')), findsOneWidget);
        expect(examined(), contains('s2_ep08_m1:corner-corner1'));
        await tapKey('corner-choose');
        await wrongThenTryAgain('What colour is the gate?', 'm1_corner1');
        // The Hidden Sketch brought: two wrong picks say why first.
        await bring('s2_ep02_e3', wrong: [
          ('s2_ep07_e3', 'That sketch brought you here. Find the one he hid in his studio.'),
          ('s2_ep02_e1', 'That street has a red door. Look for steps and a gate.'),
        ]);
        await shot('m1_sketch_brought');
        // On the square itself: corner 3, then the closer look.
        await tapPicture('corner-square', const Offset(1130, 480));
        expect(find.byKey(const ValueKey('corner-view-corner3')), findsOneWidget, reason: 'tapped on the square');
        await tapKey('corner-view', after: const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('corner-close-corner3')), findsOneWidget);
        await shot('m1_corner3_close');
        await tapKey('corner-close-done', after: const Duration(milliseconds: 400));
        await tapKey('corner-choose');
        await wrongThenTryAgain('on the left of the gate, or on the right?', 'm1_corner3');
        await tapKey('corner-tab-corner2');
        // The choose button is never under the recall card.
        await reveal(t, find.byKey(const ValueKey('corner-choose')));
        expect(t.getRect(find.byKey(const ValueKey('corner-choose'))).bottom, lessThanOrEqualTo(t.getRect(find.byKey(const ValueKey('evidence-recall'))).top + 0.5));
        await shot('m1_corner2');
        await tapKey('corner-choose');
        await finish(m1.transition.first, 'm1');
        expect(ref.read(gameControllerProvider).isCompleted(m1.id), isTrue);

        // ── M2: P.'s three drawings ─────────────────────────────────────
        await visit(m2.id);
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('sketch-tag')), findsOneWidget, reason: "P.'s tag beside the drawings");
        expect(findReadable(sketches.orderTask), findsOneWidget, reason: 'the heading asks for the order first');
        await shot('m2_table');
        // Drawing A (the light one) first: the lamp says no.
        await tapKey('sketch-card-light');
        await tapKey('sketch-slot-0');
        await tapKey('sketch-card-dark');
        await tapKey('sketch-slot-1');
        await tapKey('sketch-card-bag');
        await tapKey('sketch-slot-2');
        await tapKey('sketch-check-order');
        expect(find.text(sketches.lampLine), findsOneWidget);
        await shot('m2_lamp_line');
        // Every one back to the table, then the lamp last but the sky the
        // wrong way round.
        for (final i in [0, 1, 2]) {
          await tapKey('sketch-slot-$i');
        }
        for (final (i, id) in ['bag', 'dark', 'light'].indexed) {
          await tapKey('sketch-card-$id');
          await tapKey('sketch-slot-$i');
        }
        await tapKey('sketch-check-order');
        expect(find.text(sketches.skyLine), findsOneWidget);
        await tapKey('sketch-slot-0');
        await tapKey('sketch-slot-1');
        await tapKey('sketch-card-dark');
        await tapKey('sketch-slot-0');
        await tapKey('sketch-card-bag');
        await tapKey('sketch-slot-1');
        await tapKey('sketch-check-order');
        expect(find.text(sketches.orderedLine), findsOneWidget);
        expect(ref.read(gameControllerProvider).wrongCount(m2.id), 0, reason: 'putting them in order costs nothing');
        // Laid over each other: drawing 1 and 2.
        expect(find.byKey(const ValueKey('sketch-overlay')), findsOneWidget);
        await t.drag(find.byKey(const ValueKey('sketch-slider')), const Offset(-60, 0));
        await wait(t, const Duration(milliseconds: 300));
        await shot('m2_pair1');
        await tapPicture('sketch-overlay', const Offset(1000, 150)); // the sky: nothing new to find
        expect(find.text('Found 0 of 3'), findsOneWidget);
        await tapPicture('sketch-overlay', const Offset(280, 670));
        await tapPicture('sketch-overlay', const Offset(780, 680));
        await tapPicture('sketch-overlay', const Offset(1350, 585));
        expect(find.textContaining('Found 3 of 3'), findsOneWidget);
        await shot('m2_pair1_found');
        await tapKey('sketch-next-pair');
        expect(find.text('DRAWING 2  ·  DRAWING 3'), findsOneWidget);
        for (final at in const [Offset(445, 290), Offset(280, 650), Offset(325, 872), Offset(1325, 505)]) {
          await tapPicture('sketch-overlay', at);
        }
        // The question now, under the drawings in order.
        expect(findReadable(m2.question), findsWidgets);
        for (final s in sketches.sketches) {
          expect(find.byKey(ValueKey('sketch-ordered-${s.id}')), findsOneWidget);
        }
        await shot('m2_question');
        await tapText(t, 'It fell from a window.', after: const Duration(milliseconds: 300));
        await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 300));
        await wrongThenTryAgain('Who was on those steps just before the paper came?', 'm2_window');
        await tapText(t, 'It fell from the bag.', after: const Duration(milliseconds: 300));
        await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 300));
        await finish(m2.transition.first, 'm2');
        expect(ref.read(gameControllerProvider).isCompleted(m2.id), isTrue);

        // ── M3: the torn paper ──────────────────────────────────────────
        await visit(m3.id);
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('slip-note-card')), findsOneWidget);
        expect(find.byKey(const ValueKey('evidence-recall')), findsOneWidget, reason: 'the opera slip card under the page');
        await shot('m3_folded');
        for (var i = 0; i < slip.folds; i++) {
          await tapKey('slip-folded', after: const Duration(milliseconds: 350));
        }
        expect(find.byKey(const ValueKey('slip-torn')), findsOneWidget);
        expect(find.byKey(const ValueKey('torn-file')), findsOneWidget);
        expect(find.byKey(const ValueKey('torn-minutes')), findsOneWidget);
        expect(find.byKey(const ValueKey('torn-stamp')), findsOneWidget, reason: 'the very stamp of the opera slip');
        await bring('s2_ep07_e3', wrong: [('s2_ep01_e3', 'That mark is a gear. Is this a gear?')]);
        await shot('m3_slip_brought');
        const paper = Rect.fromLTRB(65, 85, 1460, 915);
        Future<void> tapPaper(Offset at) => tapPicture('slip-torn', at, crop: paper);
        await tapPaper(const Offset(1380, 600));
        expect(find.text('The opera slip is not torn. Is this the same?'), findsOneWidget);
        for (final at in const [Offset(125, 500), Offset(400, 200), Offset(1050, 470)]) {
          await tapPaper(at);
        }
        expect(find.byKey(const ValueKey('slip-marked-border')), findsOneWidget);
        await tapKey('slip-check');
        await wrongThenTryAgain('Look closely at the seal. Count the hands.', 'm3_seal');
        // The seal, closer: one wrong answer says why first.
        await tapPaper(const Offset(1065, 710));
        expect(find.byKey(const ValueKey('seal-close')), findsOneWidget);
        await tapKey('seal-0-One', after: const Duration(milliseconds: 200));
        expect(find.byKey(const ValueKey('seal-wrong-0')), findsOneWidget);
        await tapKey('seal-0-None', after: const Duration(milliseconds: 200));
        await tapKey('seal-1-Leaves', after: const Duration(milliseconds: 200));
        await shot('m3_seal_close');
        await tapKey('seal-done', after: const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('slip-marked-seal')), findsOneWidget);
        await tapKey('slip-mode-missing');
        await tapPaper(const Offset(700, 200));
        await tapKey('slip-check');
        await wrongThenTryAgain('What is in front of :00?', 'm3_hour');
        await tapPaper(const Offset(780, 470));
        expect(find.byKey(const ValueKey('slip-marked-hour')), findsOneWidget);
        await shot('m3_marked');
        await tapKey('slip-check');
        await finish(m3.transition.first, 'm3');
        expect(ref.read(gameControllerProvider).isCompleted(m3.id), isTrue);

        // ── Final: the paper on the drawing, and the board ──────────────
        router.go(Routes.finalMission);
        await wait(t, const Duration(milliseconds: 1600));
        expect(find.byKey(const ValueKey('torn-hour-stage')), findsOneWidget);
        expect(findReadable(hour.placeHeading), findsOneWidget);
        await reveal(t, find.byKey(const ValueKey('place-drawing')));
        expect(find.byKey(const ValueKey('margin-study')), findsWidgets, reason: "P.'s drawing of the paper in the margin");
        finger('place-turn');
        finger('place-lay');
        await shot('fin_place');
        await tapKey('place-lay');
        expect(find.text(hour.tearLine), findsOneWidget);
        await tapKey('place-turn');
        await tapKey('place-lay');
        expect(find.text(hour.sealLine), findsOneWidget);
        await tapKey('place-turn');
        expect(find.byKey(const ValueKey('place-paper-0')), findsOneWidget, reason: 'the right way round now');
        await tapKey('place-lay', after: const Duration(milliseconds: 800));
        expect(examined(), contains('s2_ep08_final:placed'));
        expect(ref.read(gameControllerProvider).wrongCount(fin.id), 0, reason: 'laying the paper costs nothing');
        expect(find.byKey(const ValueKey('paper-on-drawing')), findsOneWidget, reason: 'the paper lies on the drawing on the stage');
        await reveal(t, find.byKey(const ValueKey('evidence-board')));
        expect(find.byKey(const ValueKey('board-evidence-e4')), findsOneWidget, reason: "Case 07's slip given on the board");
        await shot('fin_board');
        // The Painter's Spot linked first: wrong, and said why.
        for (final (q, ids) in [('q1', ['e1']), ('q2', ['e3', 'e4'])]) {
          await tapKey('board-question-$q', after: const Duration(milliseconds: 200));
          for (final e in ids) {
            await tapKey('board-evidence-$e', after: const Duration(milliseconds: 200));
          }
        }
        await tapKey('board-conclusion-fell', after: const Duration(milliseconds: 200));
        await tapKey('board-solve');
        await wrongThenTryAgain('That shows where P. sat.', 'fin_spot');
        await tapKey('board-question-q1', after: const Duration(milliseconds: 200));
        await tapKey('board-evidence-e1', after: const Duration(milliseconds: 200));
        await tapKey('board-evidence-e2', after: const Duration(milliseconds: 200));
        await tapKey('board-conclusion-who', after: const Duration(milliseconds: 200));
        await tapKey('board-solve');
        await wrongThenTryAgain('What do we really know?', 'fin_who');
        await tapKey('board-conclusion-fell', after: const Duration(milliseconds: 200));
        await shot('fin_board_linked');
        await tapKey('board-solve');
        await wait(t, const Duration(milliseconds: 3600));
        // Answered, the case not closed: only the last drawing to look at.
        expect(ref.read(gameControllerProvider).isCompleted(fin.id), isTrue);
        expect(ref.read(gameControllerProvider).isCaseSolved, isFalse, reason: 'the last drawing closes the case');
        expect(find.text('CASE SOLVED'), findsNothing, reason: 'not stamped before the case is closed');
        final garden = find.textContaining('Luxembourg');
        expect(garden, findsNothing, reason: 'no garden named before it is found');
        expect(find.byKey(const ValueKey('final-last-drawing')), findsOneWidget);
        expect(find.text('CONTINUE INVESTIGATION'), findsNothing, reason: 'the story waits for the last drawing');
        await shot('fin_solved');

        // ── P.'s last drawing: the same bag, then its garden ────────────
        await tapKey('final-last-drawing', after: const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('lead-drawing')), findsOneWidget);
        expect(find.text('One drawing is left at the bottom of the bundle.'), findsOneWidget);
        // The final's page stays under it, out of reach, its solve line
        // never read over the drawing.
        expect(find.byKey(const ValueKey('final-last-drawing')).hitTestable(), findsNothing);
        expect(find.text(fin.transition.first), findsNothing, reason: 'the story after the case has not started');
        expect(garden, findsNothing);
        await tapPicture('lead-drawing', const Offset(1170, 770));
        expect(find.text('That is a round basket. The bag in your notebook is flat.'), findsOneWidget);
        expect(find.text('Found 0 of 3'), findsOneWidget, reason: 'the basket is not part of the bag');
        await tapPicture('lead-drawing', const Offset(523, 494));
        await tapPicture('lead-drawing', const Offset(560, 540));
        await tapPicture('lead-drawing', const Offset(470, 450));
        expect(find.text('P. saw the bag again, in a garden.'), findsOneWidget);
        expect(find.text('The same flat bag.'), findsNothing, reason: "the bag's last line gives way to the map's");
        expect(garden, findsNothing, reason: 'the map is to choose from; nothing names the garden yet');
        await shot('lead_bag');
        await tapKey('lead-spot-louvre');
        await tapKey('lead-choose');
        expect(find.textContaining('glass pyramid'), findsOneWidget);
        // A wrong place: nothing is done, the garden still unnamed.
        expect(find.byKey(const ValueKey('lead-done')), findsNothing);
        expect(find.text('The Luxembourg Gardens!'), findsNothing);
        expect(examined(), isNot(contains('s2_ep08_final:last-drawing')));
        await tapKey('lead-spot-luxembourgGardens');
        // Picked, not yet chosen: its name is on the map's choice only.
        expect(find.text('The Luxembourg Gardens!'), findsNothing);
        expect(find.byKey(const ValueKey('lead-done')), findsNothing);
        await shot('lead_map');
        await tapKey('lead-choose');
        expect(find.text('The Luxembourg Gardens!'), findsOneWidget);
        await shot('lead_done');
        await tapKey('lead-done', after: const Duration(milliseconds: 600));
        expect(examined(), contains('s2_ep08_final:last-drawing'));
        expect(ref.read(gameControllerProvider).isCaseSolved, isTrue, reason: 'closed with the last drawing');
        expect(find.text('CASE SOLVED'), findsOneWidget);
        await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 900));
        expect(find.text(fin.transition.first), findsOneWidget);
        await t.tapAt(Offset(size.width / 2, size.height / 2));
        await wait(t, const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('scene-backdrop')), findsOneWidget, reason: 'the last drawing');
        expect(findReadable('The mystery continues in the Luxembourg Gardens!'), findsOneWidget);
        await shot('final_scene');
        await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 4000));
        // Case 09 is in the game: its case file opens next.
        await reveal(t, find.text('OPEN CASE 09'));
        expect(find.text('OPEN CASE 09'), findsOneWidget);
        expect(find.text('COMING SOON'), findsNothing);
        await shot('case_closed');

        final board = ref.read(seasonOverviewProvider);
        expect(board.solvedCount, 8);
        expect(board.comingSoonCase, isNull);
        expect(game.openEpisode('s2_ep09'), isTrue);
        expect(ref.read(walletProvider).balance, greaterThan(coinsAtStart), reason: 'the case paid its coins');
        await wait(t, const Duration(seconds: 3));
      });
    }

    testWidgets('back again after a restart: the drawings in order, the marks and the laid paper are as left', (t) async {
      final ref = await open(t, const Size(390, 844));
      final game = ref.read(gameControllerProvider.notifier);
      expect(game.openEpisode('s2_ep08'), isTrue);
      game.startInvestigation();
      game.submitAnswer(m1, m1.answer);
      game.recordPuzzleState(m2.id, const SketchState(placed: ['dark', 'bag', 'light'], ordered: true, found: {'person', 'gate', 'badge'}).encode());
      final router = ref.read(routerProvider);
      router.go(Routes.mission(m2.id));
      await wait(t, const Duration(milliseconds: 1400));
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      expect(find.text('DRAWING 2  ·  DRAWING 3'), findsOneWidget, reason: 'the first pair all found: back on the next one');
      expect(find.text('Found 0 of 4'), findsOneWidget);
      expect(find.byKey(const ValueKey('sketch-next-pair')), findsNothing);
      game.submitAnswer(m2, m2.answer);
      game.recordPuzzleState(m3.id, const SlipState(opened: 3, same: {'border', 'seal'}, missing: {'hour'}).encode());
      router.go(Routes.map);
      await wait(t, const Duration(milliseconds: 1400));
      router.go(Routes.mission(m3.id));
      await wait(t, const Duration(milliseconds: 1400));
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      expect(find.byKey(const ValueKey('slip-torn')), findsOneWidget, reason: 'unfolded as left');
      for (final id in ['border', 'seal', 'hour']) {
        expect(find.byKey(ValueKey('slip-marked-$id')), findsOneWidget, reason: id);
      }
      expect(t.takeException(), isNull);
    });
  });

  group('the last drawing', () {
    Future<WidgetRef> solvedCase08(WidgetTester t) async {
      t.view.physicalSize = const Size(390, 844) * 3;
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
            AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: [for (final e in s1) e.id]).toJson()),
          }),
        ],
        child: Consumer(builder: (context, r, _) {
          ref = r;
          return const LondonMysteryApp();
        }),
      ));
      await wait(t, const Duration(milliseconds: 300));
      final game = ref.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      for (final e in [...paris, case08]) {
        expect(game.openEpisode(e.id), isTrue, reason: e.id);
        game.startInvestigation();
        if (e == case08) game.recordExamined(GameProgress.examinedKey(fin.id, TornHourScene.placedId));
        for (final m in e.allMissions) {
          expect(game.submitAnswer(m, m.answer).result, SubmitResult.correct, reason: m.id);
        }
      }
      return ref;
    }

    Future<void> openFinal(WidgetTester t, WidgetRef ref) async {
      ref.read(routerProvider).go(Routes.finalMission);
      await wait(t, const Duration(milliseconds: 1600));
    }

    testWidgets('left before the garden is found: nothing done, the place unnamed, the drawing waits again', (t) async {
      final ref = await solvedCase08(t);
      await openFinal(t, ref);
      expect(find.textContaining('Luxembourg'), findsNothing);
      await reveal(t, find.byKey(const ValueKey('final-last-drawing')));
      await t.tap(find.byKey(const ValueKey('final-last-drawing')));
      await wait(t, const Duration(milliseconds: 600));
      expect(find.byKey(const ValueKey('lead-drawing')), findsOneWidget);
      // One part of the bag found, then Android back: nothing kept.
      final r = t.getRect(find.byKey(const ValueKey('lead-drawing')));
      await t.tapAt(Offset(r.left + 523 / 1536 * r.width, r.top + 494 / 1024 * r.height));
      await wait(t, const Duration(milliseconds: 300));
      expect(find.text('Found 1 of 3'), findsOneWidget);
      await t.binding.handlePopRoute();
      await wait(t, const Duration(milliseconds: 600));
      expect(find.byKey(const ValueKey('lead-drawing')), findsNothing);
      expect(ref.read(gameControllerProvider).hasExamined(GameProgress.examinedKey(fin.id, TornHourScene.leadId)), isFalse);
      expect(ref.read(gameControllerProvider).isCaseSolved, isFalse);
      expect(find.text('CONTINUE INVESTIGATION'), findsNothing, reason: 'the story still waits');
      expect(find.textContaining('Luxembourg'), findsNothing);

      // No way round it: the case report and the story after the case are
      // not open; the map leads back to the final.
      final router = ref.read(routerProvider);
      String at() => router.routerDelegate.currentConfiguration.uri.path;
      for (final way in [Routes.solved, Routes.solvedSettled, Routes.report]) {
        router.go(way);
        await wait(t, const Duration(milliseconds: 1400));
        expect(at(), Routes.map, reason: '$way: the case is not closed');
      }
      router.go(Routes.story(fin.id));
      await wait(t, const Duration(milliseconds: 1400));
      expect(at(), Routes.finalMission, reason: 'the story after the case waits for the last drawing');
      router.go(Routes.map);
      await wait(t, const Duration(milliseconds: 1400));
      expect(find.text('OPEN THE FINAL CASE'), findsOneWidget, reason: 'the map leads back to the final');
      expect(ref.read(gameControllerProvider).currentMission(case08)?.id, fin.id);

      // The final again (as the map opens it): the last drawing is the way on.
      await openFinal(t, ref);
      await reveal(t, find.byKey(const ValueKey('final-last-drawing')));
      expect(find.byKey(const ValueKey('final-last-drawing')), findsOneWidget);
      expect(find.text('CONTINUE INVESTIGATION'), findsNothing);
      expect(find.text('CASE SOLVED'), findsNothing);
      expect(t.takeException(), isNull);
    });

    Future<(SharedPreferences, Future<ProviderContainer> Function())> freshSaves() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      Future<ProviderContainer> start() async {
        final c = ProviderContainer(overrides: await testOverridesFor(prefs));
        addTearDown(c.dispose);
        return c;
      }

      final c = await start();
      c.read(gameControllerProvider.notifier).createDetective('Kim', DetectiveAvatar.girl);
      c.read(progressRepositoryProvider).saveSeason(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: [for (final e in s1) e.id]));
      c.dispose();
      return (prefs, start);
    }

    test('the final answered is not the case closed: no report, no Case 09, until the last drawing is done — across restarts', () async {
      final (_, start) = await freshSaves();
      var c = await start();
      var game = c.read(gameControllerProvider.notifier);
      game.openSeason(SeasonIds.paris);
      for (final e in [...paris, case08]) {
        expect(game.openEpisode(e.id), isTrue);
        game.startInvestigation();
        for (final m in e.allMissions) {
          expect(game.submitAnswer(m, m.answer).result, SubmitResult.correct, reason: m.id);
        }
      }
      // Cases 01–07 closed with their finals' answers, as ever.
      for (final e in paris) {
        expect(c.read(progressRepositoryProvider).load(e.id).isCaseSolved, isTrue, reason: e.id);
      }
      void expectWaiting(String when) {
        final p = c.read(gameControllerProvider);
        expect(p.isCompleted(fin.id), isTrue, reason: '$when: the answer is kept');
        expect(p.isCaseSolved, isFalse, reason: '$when: the case is not closed');
        expect(p.hasExamined(leadKey), isFalse, reason: when);
        expect(p.currentMission(case08)?.id, fin.id, reason: '$when: the final is still the place to go');
        expect(c.read(seasonProvider).isSolved('s2_ep08'), isFalse, reason: '$when: not on the season record');
        expect(c.read(seasonOverviewProvider).solvedCount, 7, reason: when);
        expect(c.read(seasonProvider.notifier).isUnlocked('s2_ep09'), isFalse, reason: '$when: Case 09 stays locked');
      }

      expectWaiting('answered');
      c.dispose();
      c = await start();
      expect(c.read(currentEpisodeProvider).id, 's2_ep08');
      expectWaiting('after a restart');

      game = c.read(gameControllerProvider.notifier);
      expect(game.closeCase(leadKey), isTrue, reason: 'the last drawing done: the case closes now');
      expect(game.closeCase(leadKey), isFalse, reason: 'once');
      c.dispose();
      c = await start();
      final p = c.read(gameControllerProvider);
      expect(p.hasExamined(leadKey), isTrue, reason: 'done: kept');
      expect(p.isCaseSolved, isTrue);
      expect(p.currentMission(case08), isNull);
      expect(c.read(seasonProvider).isSolved('s2_ep08'), isTrue);
      expect(c.read(seasonOverviewProvider).solvedCount, 8);
      expect(c.read(seasonOverviewProvider).comingSoonCase, isNull, reason: 'Case 09 is in the game');
      expect(c.read(gameControllerProvider.notifier).openEpisode('s2_ep09'), isTrue, reason: 'closed: Case 09 opens now');
      expect(c.read(progressRepositoryProvider).loadSeason(SeasonIds.london).solvedEpisodeIds, hasLength(12), reason: 'London is as it was');
    });

    test('nothing closes a case whose final is not answered; a save closed before stays closed', () async {
      final (_, start) = await freshSaves();
      final c = await start();
      final game = c.read(gameControllerProvider.notifier);
      game.openSeason(SeasonIds.paris);
      for (final e in paris) {
        solveAll(game, e);
      }
      expect(game.openEpisode('s2_ep08'), isTrue);
      game.startInvestigation();
      for (final m in case08.missions) {
        game.submitAnswer(m, m.answer);
      }
      expect(game.closeCase(leadKey), isFalse, reason: 'the final is not answered yet');
      expect(c.read(gameControllerProvider).isCaseSolved, isFalse);
      expect(c.read(seasonProvider).isSolved('s2_ep08'), isFalse);

      // A Case 08 save closed by an earlier build (its final's answer closed
      // it; its last drawing not recorded): kept as it is, never reopened.
      final repo = c.read(progressRepositoryProvider);
      final earlier = repo.load('s2_ep08').copyWith(
        completedMissionIds: [for (final m in case08.allMissions) m.id],
        completedAt: DateTime(2026, 10, 23, 12),
      );
      c.dispose();
      final c2 = await start();
      c2.read(progressRepositoryProvider).save(earlier, 's2_ep08');
      c2.read(progressRepositoryProvider).saveSeason(c2.read(progressRepositoryProvider).loadSeason(SeasonIds.paris).markSolved('s2_ep08'), SeasonIds.paris);
      c2.dispose();
      final c3 = await start();
      final again = c3.read(gameControllerProvider.notifier);
      expect(again.openSeason(SeasonIds.paris), isTrue);
      expect(again.openEpisode('s2_ep08'), isTrue);
      final p = c3.read(gameControllerProvider);
      expect(p.isCaseSolved, isTrue, reason: 'a closed case is never reopened');
      expect(p.finalAwaitsLastStep(case08), isFalse);
      expect(p.hasExamined(leadKey), isFalse, reason: 'its last drawing is not counted as done');
      expect(c3.read(seasonProvider).isSolved('s2_ep08'), isTrue);
      // Its last drawing can still be done: kept, nothing else changes.
      expect(c3.read(gameControllerProvider.notifier).closeCase(leadKey), isFalse);
      expect(c3.read(gameControllerProvider).hasExamined(leadKey), isTrue);
      expect(c3.read(gameControllerProvider).completedAt, DateTime(2026, 10, 23, 12));
    });
  });

  group('the drawn evidence', () {
    testWidgets('the notebook shows the torn paper with its words and seal, and drawing 3 with its study', (t) async {
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(width: 360, child: TornFormView(form: slip.form)),
                SizedBox(width: 360, child: MorningSketchView(sketch: season2LightSketch)),
              ],
            ),
          ),
        ),
      ));
      await t.pump();
      expect(find.text('FILE'), findsOneWidget);
      expect(find.text(':00'), findsOneWidget);
      expect(find.byKey(const ValueKey('torn-stamp')), findsOneWidget);
      expect(find.byKey(const ValueKey('margin-study')), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });
}

/// Every answer of case [e] (its final's included).
void solveAll(GameController game, Episode e) {
  expect(game.openEpisode(e.id), isTrue, reason: e.id);
  game.startInvestigation();
  for (final m in e.allMissions) {
    expect(game.submitAnswer(m, m.answer).result, SubmitResult.correct, reason: m.id);
  }
}

/// An earlier case's evidence, by id.
Evidence case02Evidence(String id, List<Episode> game) => [for (final e in game) ...e.allEvidence].firstWhere((e) => e.id == id);
