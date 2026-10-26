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
import 'package:london_mystery/data/mock/season2/season2_case09_scenes.dart';
import 'package:london_mystery/data/mock/season2/season2_discoveries.dart';
import 'package:london_mystery/data/mock/season2/season2_learning.dart';
import 'package:london_mystery/data/mock/season2/season2_mock.dart';
import 'package:london_mystery/data/mock/season_catalog.dart';
import 'package:london_mystery/data/models/abbesses_puzzles.dart' show TornHourScene;
import 'package:london_mystery/data/models/discovery.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/garden_puzzles.dart';
import 'package:london_mystery/data/models/learning.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/river_puzzles.dart';
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/mission/widgets/clockwork_garden.dart';
import 'package:london_mystery/features/mission_map/map_world.dart';
import 'package:london_mystery/features/season/season_overview.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';

/// Season 2, Case 09 — The Clockwork Garden: its eight pictures (as
/// delivered), its story and puzzles as the spec says them, its rules
/// (unlock after Case 08, saves, Case 10 next), and a child playing it
/// through on three phones. Nothing is told before its time: who made the
/// marks, who carried the bag and why, what happened in Paris long ago, and
/// any name, never.
///
/// `LM_SHOTS=folder` saves a picture of each step of the play-through.
void main() {
  final inGame = MockEpisodeRepository.bundled();
  final s1 = season1Cases();
  final paris = [for (final id in ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05', 's2_ep06', 's2_ep07', 's2_ep08']) inGame.firstWhere((e) => e.id == id)];
  final case08 = paris.last;
  final case09 = inGame.firstWhere((e) => e.id == 's2_ep09');
  final [m1, m2, m3, fin] = case09.allMissions;
  final shots = Platform.environment['LM_SHOTS'];

  final trial = SeasonCatalog.trialMap(m1)!;
  final gears = SeasonCatalog.gearBoard(m2)!;
  final marks = SeasonCatalog.makerMarks(m3)!;
  final tower = SeasonCatalog.towerTest(fin)!;

  /// Kept once Case 08's last drawing is done (its case closed with it).
  final case08Lead = GameProgress.examinedKey(case08.finalMission.id, TornHourScene.leadId);

  /// Kept once the star is followed (and the case closed with it).
  final starKey = GameProgress.examinedKey(fin.id, TowerTestScene.leadId);
  final testedKey = GameProgress.examinedKey(fin.id, TowerTestScene.testedId);

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
        ...tower.afterLines,
        ...tower.testedLines,
        ...tower.lead.doneLines,
        tower.lead.tag,
        ...marks.lines.values,
      ].join('\n');

  group('its pictures', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const folder = 'assets/seasons/season_02_paris/cases/case_09';
    // Size, and whether it has an alpha channel (as delivered, never
    // changed).
    const pictures = {
      'garden_model_view.png': (1536, 1024, false),
      'clock_model_t1.png': (1254, 1254, true),
      'clock_model_t2.png': (1254, 1254, true),
      'clock_model_t3.png': (1254, 1254, true),
      'gear_board.png': (1536, 1024, false),
      'gear_brass.png': (1254, 1254, true),
      'clock_dial.png': (1254, 1254, true),
      'chronos_plan.png': (1536, 1024, true),
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

    test('all eight are in, listed in pubspec, at their sizes', () {
      expect(pubspecAssets(), contains('$folder/'), reason: 'its folder, exactly, in flutter: assets:');
      expect(Directory(folder).listSync().whereType<File>().where((f) => f.path.endsWith('.png')).length, 8);
      for (final MapEntry(key: name, value: (w, h, alpha)) in pictures.entries) {
        final file = File('$folder/$name');
        expect(file.existsSync(), isTrue, reason: name);
        final (pw, ph, a) = header(file.readAsBytesSync());
        expect((pw, ph), (w, h), reason: name);
        expect(a, alpha, reason: name);
      }
    });

    test("every one of them is played on; Case 09's places have their pictures", () {
      final scenes = [File('lib/data/mock/season2/season2_case09_scenes.dart').readAsStringSync(), File('lib/widgets/art_assets.dart').readAsStringSync()].join();
      for (final name in pictures.keys) {
        expect(scenes, contains(name), reason: name);
      }
      expect(ArtAssets.parisScenes[case09.introScene], '$folder/garden_model_view.png');
      for (final m in case09.allMissions) {
        expect(ArtAssets.parisScenes[m.scene], isNotNull, reason: m.id);
      }
      expect(missingAssets([
        trial.mapFile,
        for (final m in trial.models) m.file,
        gears.file,
        gears.gearFile,
        gears.dialFile,
        marks.file,
        marks.handsFile,
        tower.garden,
        tower.dialFile,
        season2IntroPictures['s2_ep09']!.from,
      ]), isEmpty);
    });

    test('the cut-outs are truly clear round them; the gear and the dial turn about their centres', () async {
      for (final name in pictures.entries.where((e) => e.value.$3).map((e) => e.key)) {
        final (d, w, h) = await pixels('$folder/$name');
        int alphaAt(int x, int y) => d.getUint8((y * w + x) * 4 + 3);
        expect(alphaAt(2, 2), 0, reason: '$name: a clear corner');
        expect(alphaAt(w - 3, h - 3), 0, reason: name);
      }
      // The gear: opaque straight through its middle ring, left and right
      // alike (so it never wobbles as it turns), its hole in the middle.
      final (g, gw, _) = await pixels('$folder/gear_brass.png');
      int ga(int x, int y) => g.getUint8((y * gw + x) * 4 + 3);
      expect(ga(627, 627), lessThan(40), reason: 'the axle hole');
      expect(ga(627 - 300, 627) > 200, ga(627 + 300, 627) > 200);
      // The dial: its pivot (the brass dot) where the scene says.
      final (dd, dw, _) = await pixels('$folder/clock_dial.png');
      int red(int x, int y) => dd.getUint8((y * dw + x) * 4);
      int blue(int x, int y) => dd.getUint8((y * dw + x) * 4 + 2);
      final (px, py) = (gears.dialPivot.dx.toInt(), gears.dialPivot.dy.toInt());
      expect(red(px, py) - blue(px, py), greaterThan(40), reason: 'the brass dot under the hands');
      expect(red(px, py - 250), greaterThan(200), reason: 'the white face above it');
    });

    test("the garden clock's face is where it is covered; the story's garden leaves it out", () async {
      final (d, w, _) = await pixels('$folder/garden_model_view.png');
      double light(Rect r) {
        var sum = 0.0;
        var n = 0;
        for (var y = r.top.toInt(); y < r.bottom; y += 2) {
          for (var x = r.left.toInt(); x < r.right; x += 2) {
            final i = (y * w + x) * 4;
            sum += (d.getUint8(i) + d.getUint8(i + 1) + d.getUint8(i + 2)) / 3;
            n++;
          }
        }
        return sum / n;
      }

      final face = tower.gardenClock.face;
      expect(light(face.deflate(face.width * 0.3)), greaterThan(170), reason: 'the white face, under its cover');
      expect(light(Rect.fromCenter(center: face.center + Offset(0, face.height * 0.95), width: 10, height: 30)), lessThan(140), reason: 'its dark post below it');
      final story = SeasonCatalog.storyScenes(m1)!.place!;
      expect(story.crop.right * 1536, lessThan(face.left), reason: "the story's picture stops before the garden clock");
    });
  });

  group('in the game', () {
    test('Case 09 is in the game, after Case 08, in the Luxembourg Gardens, with its four puzzles', () {
      expect(SeasonCatalog.byId(SeasonIds.paris)!.episodes.keys, ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05', 's2_ep06', 's2_ep07', 's2_ep08', 's2_ep09', 's2_ep10', 's2_ep11', 's2_ep12']);
      expect(season2AwaitingArtJson, isEmpty);
      expect(const MockEpisodeRepository().fetchEpisode('s2_ep09'), completes);
      expect(case09.number, 9);
      expect(case09.seasonId, SeasonIds.paris);
      expect(case09.title, 'The Clockwork Garden');
      expect(case09.place, 'LUXEMBOURG GARDENS');
      expect([for (final m in case09.allMissions) m.id], ['s2_ep09_m1', 's2_ep09_m2', 's2_ep09_m3', 's2_ep09_final']);
      expect([for (final m in case09.allMissions) m.title], ['The Little Paris', 'The Gear Path', "The Maker's Marks", 'The Wrong Hour']);
      expect([for (final m in case09.allMissions) m.evidence!.name], ['Trial Map', 'Synchronisation Diagram', 'Marks Key', 'The Wrong Hour Test']);
      expect([for (final m in case09.missions) m.clue!.title], ['Three Trial Clocks', 'The Tower Wheel', 'Two Marks']);
      expect(ParisLandmark.cases['s2_ep09'], ParisLandmark.luxembourgGardens);
      expect(case09.introScene, Artwork.luxembourgGarden);
      expect([for (final m in case09.allMissions) m.scene], [Artwork.luxembourgGarden, Artwork.gearBoard, Artwork.gearBoard, Artwork.luxembourgGarden]);
      expect(SeasonCatalog.evidenceArt('s2_ep09_e1'), isA<DrawnEvidenceArt>());
      expect((SeasonCatalog.evidenceArt('s2_ep09_e1')! as DrawnEvidenceArt).drawn, isA<TrialMapPaper>());
      expect((SeasonCatalog.evidenceArt('s2_ep09_e2')! as DrawnEvidenceArt).drawn, isA<GearDiagram>());
      expect((SeasonCatalog.evidenceArt('s2_ep09_e3')! as DrawnEvidenceArt).drawn, isA<MarksPaper>());
      expect((SeasonCatalog.evidenceArt('s2_ep09_e4')! as DrawnEvidenceArt).drawn, isA<TestCard>());
      for (final m in case09.allMissions) {
        expect(SeasonCatalog.storyScenes(m)?.after, isNotNull, reason: m.id);
      }
      expect(SeasonCatalog.closesAfterLastStep(fin), isTrue, reason: 'the star closes the case');
    });

    test('its Discovery Moments name what each mission found', () {
      expect(season2DiscoveryTypes['s2_ep09_m1'], DiscoveryType.deduction);
      expect(season2DiscoveryTypes['s2_ep09_m2'], DiscoveryType.deduction);
      expect(season2DiscoveryTypes['s2_ep09_m3'], DiscoveryType.evidenceFound);
      for (final m in case09.missions) {
        expect(SeasonCatalog.discovery(m).title, m.successMessage, reason: m.id);
      }
    });

    test("Case 09 leads on to Case 10 (the bible's title), now in the game, and its question; Case 08 is as it was", () {
      final season = SeasonCatalog.byId(SeasonIds.paris)!.season;
      expect(season.upcomingTitles.containsKey(10), isFalse, reason: 'Case 10 is no longer to come: it is in the game');
      expect(inGame.firstWhere((e) => e.id == 's2_ep10').title, 'The Hour of Shadows');
      final bible = File('docs/SEASON2_PARIS_STORY_BIBLE.md').readAsStringSync();
      expect(bible, contains('| 10 | **The Hour of Shadows** | Arc de Triomphe |'));
      expect(case09.hook, 'Was the hour lost — or was the clock wrong?');
      expect(bible, contains("**Opening question:** `Was the hour lost — or was the clock wrong?`"));
      expect(case08.hook, 'Why did the bag go to the little clock in the garden?', reason: 'Case 08 is as it was');
    });
  });

  group('its story and puzzles', () {
    test("it opens on P.'s last drawing, turning into the garden; the bag is remembered, never explained", () {
      final picture = SeasonCatalog.introPicture('s2_ep09')!;
      expect(picture.from, 'assets/seasons/season_02_paris/cases/case_08/last_sketch_garden.png', reason: "Case 08's own drawing");
      expect(picture.afterLine, 0, reason: 'shown from the first line');
      expect(case09.intro[picture.afterLine], "You look at P.'s last drawing again.");
      expect(case09.intro[picture.turnAtLine], 'You walk into the Luxembourg Gardens.');
      expect(case09.intro, containsAll(["The palace. The pond. It's the garden from the drawing!", "Look! That's the little clock from the drawing!", 'The same bag was here. But why?']));
      expect(case09.objectives.join(' '), isNot(matches(RegExp(r'three|joined', caseSensitive: false))));
      expect(fin.transition, contains("And the bag? Why it came here, we still don't know."));
    });

    test('M1: each little clock has one place; a wrong place sends it back; nothing else is saved', () {
      expect(AnswerChecker.isCorrect(m1, trial.answerOf({for (final m in trial.models) m.id: m.spot})), isTrue);
      expect([for (final m in trial.models) m.spot], ['arcDeTriomphe', 'seineQuays', 'artsEtMetiers']);
      // Let go on a place's centre: that place, and no other.
      for (final s in trial.spots) {
        expect(trial.spotNear(Offset(s.at.dx * 1536, s.at.dy * 1024))?.id, s.id, reason: s.id);
      }
      expect(trial.spotNear(const Offset(1500, 1000)), isNull, reason: 'far from every place');
      // No two places close enough to share a drop.
      for (final a in trial.spots) {
        for (final b in trial.spots) {
          if (a != b) expect((Offset(a.at.dx * 1536, a.at.dy * 1024) - Offset(b.at.dx * 1536, b.at.dy * 1024)).distance, greaterThan(trial.dropRadius * 1.6), reason: '${a.id} ${b.id}');
        }
      }
      expect(trial.lineFor('t1', 'palaisGarnier'), 'Look for a big arch.');
      expect(trial.lineFor('t3', 'notreDame'), 'Notre-Dame has two towers. Find one tall spire.');
      expect(TrialMapState.decode('t1=arcDeTriomphe;t2=louvre;x=y;t3', trial), {'t1': 'arcDeTriomphe'});
      expect(TrialMapState.decode(TrialMapState.encode({'t2': 'seineQuays'}), trial), {'t2': 'seineQuays'});
    });

    test('M2: each gear fits one place; joined, the tower turns T1–T3 and never the garden clock', () {
      expect(AnswerChecker.isCorrect(m2, gears.answerOf({'slot1': GearSize.big, 'slot2': GearSize.small})), isTrue);
      expect(AnswerChecker.isCorrect(m2, gears.answerOf({'slot1': GearSize.small, 'slot2': GearSize.big})), isFalse);
      for (final s in gears.slots) {
        expect(gears.slotNear(s.at)?.id, s.id);
      }
      expect(GearBoardState.decode('slot1=small;slot2=small', gears), {'slot2': GearSize.small}, reason: 'only a gear in its own size is kept');
      const none = <String, GearSize>{};
      expect(gears.joined('top', none), isFalse);
      expect(gears.joined('top', {'slot1': GearSize.big}), isTrue);
      expect(gears.joined('low', {'slot1': GearSize.big}), isFalse, reason: 'one gear turns its own branch only');
      final garden = gears.clocks.singleWhere((c) => !c.joined);
      expect(garden.name, 'GARDEN');
      expect([for (final c in gears.clocks.where((c) => c.joined)) c.name], ['T1', 'T2', 'T3']);
      // Gears that turn each other touch; nothing touches the garden clock.
      double gap(Offset a, double ra, Offset b, double rb) => (a - b).distance - (ra + rb) * 0.88;
      final tower = gears.fixed.firstWhere((f) => f.branch == null);
      final slot1 = gears.slots.firstWhere((s) => s.id == 'slot1');
      expect(gap(tower.at, tower.radius, slot1.at, gears.radii[GearSize.big]!).abs(), lessThan(4));
      for (final c in gears.clocks.where((c) => c.joined)) {
        expect(c.clockwise == (c.id != 't2'), isTrue, reason: '${c.id}: gears that touch turn opposite ways');
      }
      for (final f in [...gears.fixed.map((f) => (f.at, f.radius)), ...gears.slots.map((s) => (s.at, gears.radii[s.size]!)), ...gears.clocks.where((c) => c.joined).map((c) => (c.at, c.radius))]) {
        expect(gap(f.$1, f.$2, garden.at, garden.radius), greaterThan(40), reason: 'the garden clock is joined to nothing');
      }
      expect(m2.transition, contains('The gears move the model. The real trial used wires.'));
      expect(m2.evidence!.inscription, contains('The real trial used wires.'));
    });

    test("M3: Case 01's gear and the two clock hands, each to its own paper; the key is never theirs", () {
      expect(AnswerChecker.isCorrect(m3, marks.answerOf({'a': 'emblem', 'b': 'repair'})), isTrue);
      expect(marks.same('a', 'emblem'), isTrue);
      expect(marks.same('b', 'repair'), isTrue);
      for (final m in marks.marks) {
        expect(marks.same(m.id, 'key'), isFalse, reason: '${m.id}: the key is a decoy');
      }
      expect(marks.lines['b:key'], 'That is a key. Look for two hands.');
      expect(marks.lines['a:repair'], 'Is that a gear?');
      expect(marks.lines['b:emblem'], 'Count the hands.');
      // The notebook evidence they come from, as it is.
      final all = {for (final e in inGame) for (final ev in e.allEvidence) ev.id: ev};
      expect(all['s2_ep01_e3']!.inscription, 'A tiny carved gear, and the letter M.');
      expect(all['s2_ep05_e1']!.inscription, contains('Signed with two clock hands.'));
      expect(marks.handsFile, endsWith('case_04/hands_sign.png'), reason: 'the very picture of the two hands');
      expect(MakerMarksState.decode('a=key;b=repair', marks), {'b': 'repair'});
      expect(m3.transition, contains('Two marks on two different papers. Did one person make both? The papers do not say.'));
      expect(m3.transition.join(' '), contains('Is it linked to this machine? We can\'t tell yet.'));
    });

    test('the final: 4:00 → 3:00 tested first; only the joined clocks change; the answer says no more', () {
      expect((tower.startHour, tower.targetHour), (4, 3));
      for (final c in tower.clocks) {
        expect(tower.hourOf(c, tested: false), 4, reason: c.id);
        expect(tower.hourOf(c, tested: true), c.joined ? 3 : 4, reason: c.id);
      }
      expect(tower.lineFor(5), 'That is one hour forward. Go back.');
      expect(tower.lineFor(2), 'That is two hours back. Just one.');
      expect(tower.lineFor(9), isNotEmpty);
      expect(fin.answer, 'connected');
      expect(AnswerChecker.feedbackFor(fin, 'all'), contains('garden clock'));
      expect(AnswerChecker.feedbackFor(fin, 'who'), 'The test shows HOW. Does it show WHO?');
      expect(tower.afterLines.first, 'The model shows what could happen. But what really happened?');
      expect(tower.lead.tag, 'TRIAL RECORDS · KEPT AT THE STAR');
      expect(tower.lead.answer, 't1');
      expect(tower.lead.spot.id, 'arcDeTriomphe');
      expect(trial.model('t1').sign, 'a star');
    });

    test('nothing is told before its time: no name, no culprit, no answer for Case 10', () {
      final all = everything(case09.allMissions, e: case09);
      for (final banned in ['Émile', 'Emile', 'Moreau', 'Victor', 'Delacroix', 'RECORD WAS REMOVED', 'the same person', 'stole', 'deleted', 'erased', 'Saint-Sulpice']) {
        expect(all.toLowerCase(), isNot(contains(banned.toLowerCase())), reason: banned);
      }
      // The hour is never said to be lost, or not lost: that is Case 10's.
      expect(all, isNot(contains('time did not')));
      expect(all, isNot(contains('hour was not lost')));
      expect(all, isNot(contains('letter M')), reason: "Case 01's M is never read here");
    });

    test('its learning design: every expression is on its screens', () {
      expect(season2LanguageTopics['s2_ep09'], isNotNull);
      String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      String screen(Mission m) => norm([...m.story, m.letterIntro, m.letter, m.question, for (final o in m.options) o.label, ...m.hints].join(' \n '));
      for (final m in case09.allMissions) {
        final l = season2Learning[m.id]!;
        expect(l.dependency, LanguageDependency.essential, reason: m.id);
        for (final e in l.expressions) {
          expect(screen(m), contains(norm(e)), reason: '${m.id}: "$e" is on its screens');
        }
      }
    });

    test('its evidence leads on from Case 01, one piece to the next', () {
      expect(SeasonCatalog.evidenceLink('s2_ep09_e2')!.to, 's2_ep09_e1');
      expect(SeasonCatalog.evidenceLink('s2_ep09_e3')!.to, 's2_ep01_e3');
      expect(SeasonCatalog.evidenceLink('s2_ep09_e4')!.to, 's2_ep09_e2');
      expect(SeasonCatalog.evidenceLink('s2_ep08_e4')!.to, 's2_ep08_e2', reason: "Case 08's links are as they were");
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
      if (e == case08) expect(game.closeCase(case08Lead), isTrue);
      if (e == case09) {
        game.recordExamined(testedKey);
        expect(game.closeCase(starKey), isTrue);
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

    test('it opens only once Case 08 is closed', () async {
      final c = await start();
      final game = c.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      for (final e in paris.take(7)) {
        solve(c, e);
      }
      expect(game.openEpisode('s2_ep09'), isFalse, reason: 'no way round Case 08');
      // Case 08 answered but its last drawing not done: still closed.
      expect(game.openEpisode('s2_ep08'), isTrue);
      game.startInvestigation();
      for (final m in case08.allMissions) {
        game.submitAnswer(m, m.answer);
      }
      expect(game.openEpisode('s2_ep09'), isFalse, reason: "Case 08's last drawing first");
      expect(game.closeCase(case08Lead), isTrue);
      expect(c.read(seasonProvider.notifier).isUnlocked('s2_ep09'), isTrue);
      expect(game.openEpisode('s2_ep09'), isTrue);
      expect(c.read(currentEpisodeProvider).id, 's2_ep09');
    });

    test('the clocks, gears, marks, hour and test are saved and come back after a restart; evidence is never twice', () async {
      var c = await start();
      var game = c.read(gameControllerProvider.notifier);
      game.openSeason(SeasonIds.paris);
      for (final e in paris) {
        solve(c, e);
      }
      game.openEpisode('s2_ep09');
      game.startInvestigation();
      game.recordPuzzleState(m1.id, TrialMapState.encode({'t1': 'arcDeTriomphe', 't3': 'artsEtMetiers'}));
      expect(game.submitAnswer(m2, m2.answer).result, SubmitResult.locked, reason: 'missions in order');

      c.dispose();
      c = await start();
      game = c.read(gameControllerProvider.notifier);
      expect(c.read(currentEpisodeProvider).id, 's2_ep09');
      var p = c.read(gameControllerProvider);
      expect(TrialMapState.decode(p.puzzleStateOf(m1.id), trial), {'t1': 'arcDeTriomphe', 't3': 'artsEtMetiers'});
      expect(p.wrongCount(m1.id), 0, reason: 'a clock sent back is never a wrong answer');
      expect(game.submitAnswer(m1, m1.answer).result, SubmitResult.correct);
      game.recordPuzzleState(m2.id, GearBoardState.encode({'slot1': GearSize.big}));
      expect(game.submitAnswer(m2, m2.answer).result, SubmitResult.correct);
      game.recordPuzzleState(m3.id, MakerMarksState.encode({'a': 'emblem'}));
      expect(game.submitAnswer(m3, m3.answer).result, SubmitResult.correct);
      game.recordPuzzleState(fin.id, 'hour=3');
      game.recordExamined(testedKey);

      c.dispose();
      c = await start();
      game = c.read(gameControllerProvider.notifier);
      p = c.read(gameControllerProvider);
      expect(GearBoardState.decode(p.puzzleStateOf(m2.id), gears), {'slot1': GearSize.big});
      expect(MakerMarksState.decode(p.puzzleStateOf(m3.id), marks), {'a': 'emblem'});
      expect(p.puzzleStateOf(fin.id), 'hour=3');
      expect(p.hasExamined(testedKey), isTrue);
      expect(game.submitAnswer(fin, 'all').result, SubmitResult.tryAgain);
      expect(game.submitAnswer(fin, fin.answer).result, SubmitResult.correct);
      // Answered again: nothing new, no evidence twice.
      game.submitAnswer(m1, m1.answer);
      p = c.read(gameControllerProvider);
      expect([for (final e in p.collectedEvidence(case09)) e.name], ['Trial Map', 'Synchronisation Diagram', 'Marks Key', 'The Wrong Hour Test']);
      // Answered, not closed: the star waits.
      expect(p.isCompleted(fin.id), isTrue);
      expect(p.isCaseSolved, isFalse);
      expect(p.finalAwaitsLastStep(case09), isTrue);

      c.dispose();
      c = await start();
      game = c.read(gameControllerProvider.notifier);
      p = c.read(gameControllerProvider);
      expect((p.isCompleted(fin.id), p.isCaseSolved), (true, false), reason: 'after a restart: answered, still open');
      expect(game.closeCase(starKey), isTrue);
      expect(c.read(gameControllerProvider).isCaseSolved, isTrue);
      expect(game.closeCase(starKey), isFalse, reason: 'closed once');
      expect(c.read(progressRepositoryProvider).load('s2_ep08').isCaseSolved, isTrue, reason: "Case 08's save is its own");
      expect(c.read(progressRepositoryProvider).load('s2_ep08').examined.any((k) => k.startsWith('s2_ep09')), isFalse);
    });

    test('solved: Paris is 9 of 12, Case 10 opens next; London is as it was', () async {
      final c = await start();
      final game = c.read(gameControllerProvider.notifier);
      game.openSeason(SeasonIds.paris);
      for (final e in [...paris, case09]) {
        solve(c, e);
      }
      final board = c.read(seasonOverviewProvider);
      expect(board.solvedCount, 9);
      expect(board.comingSoonCase, isNull, reason: 'Case 10 is in the game: nothing is only coming');
      final available = c.read(seasonAvailabilityProvider(SeasonIds.paris))!;
      expect((available.solvedCount, available.plannedCount), (9, 12));
      expect(game.openEpisode('s2_ep10'), isTrue, reason: 'Case 10 opens after Case 09');
      expect(c.read(progressRepositoryProvider).loadSeason(SeasonIds.london).solvedEpisodeIds, hasLength(12));
    });
  });

  group('a child plays Case 09', () {
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
        if (e == case08) game.closeCase(case08Lead);
      }
      return ref;
    }

    for (final size in const [Size(360, 640), Size(390, 844), Size(430, 932)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';
      testWidgets('$tag: Case 08 closed → the garden → clocks on the map → gears → marks → the wrong hour → the star, 9 of 12', (t) async {
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
            File('$shots/paris09_${tag}_${(n++).toString().padLeft(2, '0')}_$name.png').writeAsBytesSync(png!.buffer.asUint8List());
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

        /// A point of a picture shown in the widget with [key] ([pixels]
        /// big), on the screen.
        Offset onPicture(String key, Offset px, Size pixels) {
          final r = t.getRect(find.byKey(ValueKey(key)));
          return Offset(r.left + px.dx / pixels.width * r.width, r.top + px.dy / pixels.height * r.height);
        }

        /// [thing] dragged by a finger to [to] (with the picture in view).
        Future<void> drag(String thing, Offset Function() to) async {
          await reveal(t, find.byKey(ValueKey(thing)));
          final g = await t.startGesture(t.getCenter(find.byKey(ValueKey(thing))));
          await t.pump(const Duration(milliseconds: 50));
          await g.moveBy(const Offset(0, -24));
          await t.pump(const Duration(milliseconds: 50));
          await g.moveTo(to());
          await t.pump(const Duration(milliseconds: 50));
          await g.up();
          await wait(t, const Duration(milliseconds: 500));
        }

        /// Tapped, then its place tapped (the way that needs no reach).
        Future<void> tapThen(String thing, String picture, Offset px, Size pixels) async {
          await tapKey(thing, after: const Duration(milliseconds: 250));
          await reveal(t, find.byKey(ValueKey(picture)));
          await t.tapAt(onPicture(picture, px, pixels));
          await wait(t, const Duration(milliseconds: 500));
        }

        /// Whether both are on the screen at once (a drag can reach).
        bool bothInView(String a, String b) {
          final screen = Offset.zero & size;
          return [a, b].every((k) {
            final r = t.getRect(find.byKey(ValueKey(k)));
            return screen.contains(r.center) && r.top >= 0 && r.bottom <= size.height;
          });
        }

        Future<void> finish(String sceneLine, String name, {Duration settle = const Duration(milliseconds: 2800)}) async {
          await wait(t, settle);
          expect(find.byWidgetPredicate((w) => w is Text && DiscoveryType.values.any((d) => d.cheer == w.data)), findsOneWidget, reason: '$name: its Discovery Moment');
          await shot('${name}_solved');
          await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 900));
          expect(find.text(sceneLine), findsOneWidget, reason: 'story transition');
          await t.tapAt(Offset(size.width / 2, size.height / 2)); // skip typing
          await wait(t, const Duration(milliseconds: 900));
          expect(find.byKey(const ValueKey('scene-backdrop')), findsOneWidget, reason: '$name: its own picture');
          await shot('${name}_scene');
          await tapText(t, 'TO THE MAP', after: const Duration(milliseconds: 1200));
          await wait(t, const Duration(milliseconds: 3200));
        }

        Set<String> examined() => ref.read(gameControllerProvider).examined.toSet();
        void finger(String key) {
          final r = t.getRect(find.byKey(ValueKey(key)));
          expect(r.width >= 44 && r.height >= 44, isTrue, reason: '$tag $key: finger-sized ($r)');
        }

        // ── Case 08's Case Closed: on to Case 09 ────────────────────────
        router.go(Routes.solvedSettled);
        await wait(t, const Duration(milliseconds: 3000));
        await reveal(t, find.text('OPEN CASE 09'));
        expect(find.text('OPEN CASE 09'), findsOneWidget, reason: 'Case 09 is in the game now');
        expect(game.openEpisode('s2_ep09'), isTrue);

        // ── The opening: P.'s drawing becomes the garden ────────────────
        router.go(Routes.intro);
        await wait(t, const Duration(milliseconds: 1600));
        await tapText(t, 'SKIP ›', after: const Duration(milliseconds: 2200));
        await reveal(t, find.byKey(const ValueKey('intro-picture')));
        expect(find.byKey(const ValueKey('intro-picture')), findsOneWidget);
        expect(find.byKey(const ValueKey('intro-picture-garden')), findsOneWidget, reason: 'walked in: the garden');
        expect(find.byKey(const ValueKey('garden-clock-cover')), findsWidgets, reason: 'the garden clock at four');
        expect(find.text('The same bag was here. But why?'), findsOneWidget);
        await shot('opening');
        await tapText(t, "I'M READY", after: const Duration(milliseconds: 1600));

        // ── M1: the little clocks back on the map ───────────────────────
        await visit(m1.id);
        expect(find.byKey(const ValueKey('story-picture')), findsOneWidget, reason: 'the garden');
        await shot('m1_place');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('trial-map')), findsOneWidget);
        for (final m in trial.models) {
          finger('trial-model-${m.id}');
        }
        await shot('m1_map');
        Offset spot(String id) {
          final s = trial.spots.firstWhere((s) => s.id == id);
          return Offset(s.at.dx * 1536, s.at.dy * 1024);
        }

        Future<void> lay(String model, String place) async {
          final key = 'trial-model-$model';
          await reveal(t, find.byKey(ValueKey(key)));
          if (bothInView(key, 'trial-map')) {
            // The clock is held above the finger: its base where it lands.
            await drag(key, () => onPicture('trial-map', spot(place), const Size(1536, 1024)) + const Offset(0, 10));
          } else {
            await tapThen(key, 'trial-map', spot(place), const Size(1536, 1024));
          }
        }

        // T1 laid on the opera first: it goes back, with its line.
        await lay('t1', 'palaisGarnier');
        expect(find.text('Look for a big arch.'), findsOneWidget);
        expect(find.byKey(const ValueKey('trial-model-t1')), findsOneWidget, reason: 'back in the box');
        await lay('t3', 'notreDame');
        expect(find.text('Notre-Dame has two towers. Find one tall spire.'), findsOneWidget);
        expect(ref.read(gameControllerProvider).wrongCount(m1.id), 0, reason: 'a clock sent back costs nothing');
        await shot('m1_wrong');
        await lay('t1', 'arcDeTriomphe');
        expect(find.byKey(const ValueKey('trial-model-t1')), findsNothing, reason: 'in its place');
        expect(TrialMapState.decode(ref.read(gameControllerProvider).puzzleStateOf(m1.id), trial), {'t1': 'arcDeTriomphe'}, reason: 'saved as it is laid');
        await lay('t2', 'seineQuays');
        await shot('m1_two');
        await lay('t3', 'artsEtMetiers');
        await finish(m1.transition.first, 'm1');
        expect(ref.read(gameControllerProvider).isCompleted(m1.id), isTrue);

        // ── M2: two gears on the board ──────────────────────────────────
        await visit(m2.id);
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('gear-board')), findsOneWidget);
        expect(find.byKey(const ValueKey('gear-slot-slot1')), findsOneWidget);
        await shot('m2_board');
        Future<void> fit(GearSize g, String slot) async {
          final key = 'gear-tray-${g.name}';
          final at = gears.slots.firstWhere((s) => s.id == slot).at;
          await reveal(t, find.byKey(const ValueKey('gear-board')));
          // The board shows its plate only; the gear is held above the
          // finger.
          final r = t.getRect(find.byKey(const ValueKey('gear-board')));
          final s = r.width / gears.view.width;
          await drag(key, () => r.topLeft + (at - gears.view.topLeft) * s + Offset(0, gears.radii[g]! * s + 14));
        }

        // The small gear in the big place: too small, back to the tray.
        await fit(GearSize.small, 'slot1');
        expect(find.text('Too small!'), findsOneWidget);
        expect(find.byKey(const ValueKey('gear-tray-small')), findsOneWidget);
        await fit(GearSize.big, 'slot1');
        expect(find.byKey(const ValueKey('gear-in-slot1')), findsOneWidget);
        expect(find.text('One more gear!'), findsOneWidget);
        expect(ref.read(gameControllerProvider).wrongCount(m2.id), 0);
        await shot('m2_one');
        await fit(GearSize.small, 'slot2');
        expect(find.text(gears.turningLine), findsOneWidget);
        await shot('m2_turning');
        await finish(m2.transition.first, 'm2', settle: const Duration(milliseconds: 5800));
        expect(ref.read(gameControllerProvider).isCompleted(m2.id), isTrue);

        // ── M3: the maker's marks ───────────────────────────────────────
        await visit(m3.id);
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('marks-plan')), findsOneWidget);
        for (final id in ['a', 'b']) {
          finger('marks-card-$id');
        }
        for (final p in marks.paper) {
          finger('marks-paper-${p.id}');
        }
        await shot('m3_marks');
        // The paper tapped first: pick a notebook mark first.
        await tapKey('marks-paper-emblem');
        expect(find.text(marks.pickFirst), findsOneWidget);
        // The two hands to the key: said why, nothing joined.
        await tapKey('marks-card-b');
        await tapKey('marks-paper-key');
        expect(find.text('That is a key. Look for two hands.'), findsOneWidget);
        expect(ref.read(gameControllerProvider).wrongCount(m3.id), 0);
        await tapKey('marks-paper-repair');
        await tapKey('marks-card-a');
        await tapKey('marks-paper-emblem');
        await shot('m3_joined');
        await finish(m3.transition.first, 'm3');
        expect(ref.read(gameControllerProvider).isCompleted(m3.id), isTrue);

        // ── Final: the wrong hour ───────────────────────────────────────
        router.go(Routes.finalMission);
        await wait(t, const Duration(milliseconds: 2600));
        expect(find.byKey(const ValueKey('tower-stage')), findsOneWidget);
        expect(find.byKey(const ValueKey('garden-clock-cover')), findsOneWidget, reason: 'the garden clock at four on the stage');
        await reveal(t, find.byKey(const ValueKey('tower-test')));
        finger('tower-back');
        finger('tower-forward');
        finger('tower-test');
        expect(find.text('4:00'), findsWidgets);
        await shot('fin_tower');
        // One hour forward, tested: said why, never a wrong answer.
        await tapKey('tower-forward');
        expect(find.text('5:00'), findsOneWidget);
        await tapKey('tower-test');
        expect(find.text('That is one hour forward. Go back.'), findsOneWidget);
        expect(ref.read(gameControllerProvider).wrongCount(fin.id), 0);
        await tapKey('tower-back');
        await tapKey('tower-back');
        expect(ref.read(gameControllerProvider).puzzleStateOf(fin.id), 'hour=3');
        await tapKey('tower-test', after: const Duration(milliseconds: 1600));
        expect(examined(), contains(testedKey));
        expect(find.byKey(const ValueKey('test-clock-time-t1')), findsOneWidget);
        expect((t.widget<Text>(find.byKey(const ValueKey('test-clock-time-t1'))).data, t.widget<Text>(find.byKey(const ValueKey('test-clock-time-garden'))).data), ('3:00', '4:00'), reason: 'only the joined clocks went with it');
        await reveal(t, find.byKey(const ValueKey('tower-question-sheet')));
        await shot('fin_tested');
        await tapText(t, 'Every clock in Paris went wrong.', after: const Duration(milliseconds: 300));
        await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 1500));
        expect(findReadableContaining('Look at the garden clock.'), findsWidgets);
        await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
        await tapText(t, 'Only the joined clocks went wrong.', after: const Duration(milliseconds: 300));
        await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 300));
        await wait(t, const Duration(milliseconds: 3600));
        // Answered, the case not closed: only the star to follow.
        expect(ref.read(gameControllerProvider).isCompleted(fin.id), isTrue);
        expect(ref.read(gameControllerProvider).isCaseSolved, isFalse, reason: 'the star closes the case');
        expect(find.text('CASE SOLVED'), findsNothing);
        await reveal(t, find.byKey(const ValueKey('final-follow-star')));
        expect(find.text(tower.afterLines.first), findsOneWidget, reason: 'a model shows what could happen');
        expect(find.textContaining('Arc de Triomphe'), findsNothing, reason: 'no place named before the star is followed');
        await shot('fin_solved');

        // ── The star: the drum's tag, T1, the Arc de Triomphe ───────────
        await tapKey('final-follow-star', after: const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('star-tag')), findsOneWidget);
        expect(find.text('TRIAL RECORDS · KEPT AT THE STAR'), findsOneWidget);
        await tapKey('star-model-t2');
        expect(find.text(tower.lead.otherLine), findsOneWidget);
        expect(examined(), isNot(contains(starKey)));
        await tapKey('star-model-t1', after: const Duration(milliseconds: 1000));
        expect(find.byKey(const ValueKey('star-map-ring')), findsOneWidget);
        expect(find.text('T1 stands at the Arc de Triomphe.'), findsOneWidget);
        await shot('star_map');
        await tapKey('star-done', after: const Duration(milliseconds: 600));
        expect(examined(), contains(starKey));
        expect(ref.read(gameControllerProvider).isCaseSolved, isTrue, reason: 'closed with the star');
        expect(find.text('CASE SOLVED'), findsOneWidget);
        await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 900));
        expect(find.text(fin.transition.first), findsOneWidget);
        await t.tapAt(Offset(size.width / 2, size.height / 2));
        await wait(t, const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('scene-backdrop')), findsOneWidget);
        expect(findReadable('The mystery continues at the Arc de Triomphe!'), findsOneWidget);
        await shot('final_scene');
        await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 4000));
        // Case 10 is in the game: its case file opens next.
        await reveal(t, find.text('OPEN CASE 10'));
        expect(find.text('OPEN CASE 10'), findsOneWidget);
        expect(find.text('COMING SOON'), findsNothing);
        await shot('case_closed');

        final board = ref.read(seasonOverviewProvider);
        expect(board.solvedCount, 9);
        expect(board.comingSoonCase, isNull);
        expect(game.openEpisode('s2_ep10'), isTrue);
        expect(ref.read(walletProvider).balance, greaterThan(coinsAtStart), reason: 'the case paid its coins');
        await wait(t, const Duration(seconds: 3));
      });
    }

    testWidgets("the opening's picture holds its place from the first line; only Case 09 has one", (t) async {
      final ref = await open(t, const Size(360, 640));
      expect(ref.read(gameControllerProvider.notifier).openEpisode('s2_ep09'), isTrue);
      ref.read(routerProvider).go(Routes.intro);
      await wait(t, const Duration(milliseconds: 500));
      final picture = find.byKey(const ValueKey('intro-picture'));
      expect(picture, findsOneWidget, reason: 'its place is there from the start');
      final first = t.getRect(picture);
      expect(first.height, greaterThan(100));
      // The pictures decoded (or a moment passed): the first line, under the
      // picture, which has not moved.
      await wait(t, const Duration(milliseconds: 2500));
      expect(find.byKey(const ValueKey('intro-0')), findsOneWidget);
      expect(t.getRect(picture), first, reason: 'the picture never resizes the page');
      final line0 = t.getRect(find.byKey(const ValueKey('intro-0')));
      expect(line0.top, greaterThanOrEqualTo(first.bottom));
      // Lines go on; the picture stays put (the garden by line 4).
      await wait(t, const Duration(seconds: 14));
      expect(t.getRect(picture), first);
      expect(find.byKey(const ValueKey('intro-picture-garden')), findsOneWidget);
      // No case before it has such a picture: their openings are as they
      // were (Cases 10–12, after it, have their own).
      for (final e in inGame.where((e) => e.id != 's2_ep09' && e.id != 's2_ep10' && e.id != 's2_ep11' && e.id != 's2_ep12')) {
        expect(SeasonCatalog.introPicture(e.id), isNull, reason: e.id);
      }
      expect(t.takeException(), isNull);
    });

    testWidgets("the final's card says what to do, once: no heading repeats it", (t) async {
      final ref = await open(t, const Size(390, 844));
      final game = ref.read(gameControllerProvider.notifier);
      expect(game.openEpisode('s2_ep09'), isTrue);
      game.startInvestigation();
      for (final m in case09.missions) {
        game.submitAnswer(m, m.answer);
      }
      ref.read(routerProvider).go(Routes.finalMission);
      await wait(t, const Duration(milliseconds: 2600));
      expect(findReadable(fin.letter), findsOneWidget, reason: "the spec's card");
      expect(findReadableContaining('one hour back'), findsOneWidget, reason: 'said once only');
      expect(find.text(fin.question), findsNothing, reason: 'not asked before the test');
      expect(t.takeException(), isNull);
    });

    testWidgets('back again after a restart: the clocks, the gear, the joined mark and the hour are as left', (t) async {
      final ref = await open(t, const Size(390, 844));
      final game = ref.read(gameControllerProvider.notifier);
      expect(game.openEpisode('s2_ep09'), isTrue);
      game.startInvestigation();
      game.recordPuzzleState(m1.id, TrialMapState.encode({'t2': 'seineQuays'}));
      final router = ref.read(routerProvider);
      router.go(Routes.mission(m1.id));
      await wait(t, const Duration(milliseconds: 1400));
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      expect(find.byKey(const ValueKey('trial-model-t2')), findsNothing, reason: 'T2 still in its place');
      expect(find.byKey(const ValueKey('trial-model-t1')), findsOneWidget);
      game.submitAnswer(m1, m1.answer);
      game.recordPuzzleState(m2.id, GearBoardState.encode({'slot2': GearSize.small}));
      router.go(Routes.map);
      await wait(t, const Duration(milliseconds: 1400));
      router.go(Routes.mission(m2.id));
      await wait(t, const Duration(milliseconds: 1400));
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      expect(find.byKey(const ValueKey('gear-in-slot2')), findsOneWidget, reason: 'the small gear as left');
      expect(find.byKey(const ValueKey('gear-tray-small')), findsNothing);
      game.submitAnswer(m2, m2.answer);
      game.submitAnswer(m3, m3.answer);
      game.recordPuzzleState(fin.id, 'hour=5');
      router.go(Routes.finalMission);
      await wait(t, const Duration(milliseconds: 2600));
      await reveal(t, find.byKey(const ValueKey('tower-time')));
      expect(t.widget<Text>(find.byKey(const ValueKey('tower-time'))).data, '5:00', reason: 'the hour as left');
      expect(find.byKey(const ValueKey('tower-question-sheet')), findsNothing, reason: 'not tested yet');
      expect(t.takeException(), isNull);
    });
  });

  group('small screens (found in the device QA)', () {
    testWidgets("M2's two-line feedback grows its row on a 360-wide phone, never clipped", (t) async {
      t.view.physicalSize = const Size(360, 640) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GearBoardPuzzle(
              scene: gears,
              placed: {for (final s in gears.slots) s.id: s.size},
              onPlaced: (_) {},
              onSubmit: (_) async {},
            ),
          ),
        ),
      ));
      await t.pump(const Duration(milliseconds: 400));
      final line = find.text(gears.turningLine);
      expect(line, findsOneWidget);
      expect(t.getSize(line).height, greaterThan(30), reason: 'two lines at this width');
      // Its row holds it whole: the tray row starts below its last line.
      final tray = find.descendant(of: find.byType(GearBoardPuzzle), matching: find.byType(Row)).last;
      expect(t.getRect(line).bottom, lessThanOrEqualTo(t.getRect(tray).top + 0.5));
      await t.pumpWidget(const SizedBox());
      expect(t.takeException(), isNull);
    });
  });

  group('the drawn evidence', () {
    testWidgets('the four pieces draw on a phone without overflow', (t) async {
      t.view.physicalSize = const Size(360, 640) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const TrialMapPaperView(paper: TrialMapPaper(season2TrialMap)),
                const GearDiagramView(diagram: GearDiagram(season2GearBoard)),
                const MarksPaperView(paper: MarksPaper(season2MakerMarks)),
                const TestCardView(card: TestCard(season2TowerTest)),
              ],
            ),
          ),
        ),
      ));
      await t.pump(const Duration(milliseconds: 500));
      expect(t.takeException(), isNull);
      expect(find.byType(DialFace), findsWidgets);
    });
  });
}
