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
import 'package:london_mystery/data/mock/season2/season2_case05_scenes.dart';
import 'package:london_mystery/data/mock/season2/season2_case06_scenes.dart';
import 'package:london_mystery/data/mock/season2/season2_discoveries.dart';
import 'package:london_mystery/data/mock/season2/season2_learning.dart';
import 'package:london_mystery/data/mock/season2/season2_mock.dart';
import 'package:london_mystery/data/mock/season_catalog.dart';
import 'package:london_mystery/data/models/discovery.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/learning.dart';
import 'package:london_mystery/data/models/letter_puzzles.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/river_puzzles.dart';
import 'package:london_mystery/data/models/scene_explore.dart' show ScenePixels;
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/mission/widgets/letter_map.dart' show LetterMapPuzzle;
import 'package:london_mystery/features/mission_map/map_world.dart';
import 'package:london_mystery/features/season/season_overview.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/game_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';

/// Season 2, Case 06 — The Letter That Never Arrived: its fifteen pictures
/// (as delivered, measured), its story and puzzles as the tags, the plan,
/// the drawers and the map say them, its rules (unlock after Case 05,
/// saves, Case 07 still to come), and a child playing it through on three
/// phones. Nothing is told before its time; who wrote the letter, who held
/// it and why, and that a record was removed, never.
///
/// `LM_SHOTS=folder` saves a picture of each step of the play-through.
void main() {
  final inGame = MockEpisodeRepository.bundled();
  final s1 = season1Cases();
  final paris = [for (final id in ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05']) inGame.firstWhere((e) => e.id == id)];
  final case05 = paris.last;
  final case06 = inGame.firstWhere((e) => e.id == 's2_ep06');
  final [m1, m2, m3, fin] = case06.allMissions;
  final shots = Platform.environment['LM_SHOTS'];

  final rack = season2HoldRacks[m1.id]!;
  final plan = season2PlanRoutes[m2.id]!;
  final archive = season2ArchiveDrawers[m3.id]!;
  final letter = season2LetterMaps[fin.id]!;

  final rackScene = SeasonCatalog.holdRack(m1)!;
  final planScene = SeasonCatalog.planRoute(m2)!;
  final archiveScene = SeasonCatalog.archive(m3)!;
  final mapScene = SeasonCatalog.letterMap(fin)!;

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
      [...m.story, m.letterIntro, m.letter, m.question, ...m.hints, for (final o in m.options) o.feedback ?? ''].join('\n');

  group('its pictures', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const folder = 'assets/seasons/season_02_paris/cases/case_06';
    // Size, and whether it has an alpha channel (as delivered, never
    // changed): the torn pieces share one canvas.
    const pictures = {
      'louvre_post_room_exterior.png': (1536, 1024, false),
      'post_room_hold_rack.png': (1536, 1024, false),
      'hold_tag_blank.png': (1254, 1254, true),
      'ink_blot.png': (1254, 1254, true),
      'archive_floor_plan.png': (1024, 1536, false),
      'archive_room.png': (1536, 1024, false),
      'archive_cabinet.png': (1254, 1254, false),
      'archive_drawer_open.png': (1536, 1024, false),
      'torn_corner_4417.png': (1474, 1067, true),
      'torn_envelope_match.png': (1474, 1067, true),
      'torn_envelope_decoy_a.png': (1474, 1067, true),
      'torn_envelope_decoy_b.png': (1474, 1067, true),
      'opera_seal.png': (1254, 1254, true),
      'opera_sketch.png': (1448, 1086, true),
      'letter_paper_open.png': (1086, 1448, true),
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

    int alphaAt(ByteData d, int w, int x, int y) => d.getUint8((y * w + x) * 4 + 3);

    test('all fifteen are in, listed in pubspec, at their sizes', () {
      expect(File('pubspec.yaml').readAsStringSync(), contains('    - $folder/\n'));
      expect(Directory(folder).listSync().whereType<File>().where((f) => f.path.endsWith('.png')).length, 15);
      for (final MapEntry(key: name, value: (w, h, alpha)) in pictures.entries) {
        final file = File('$folder/$name');
        expect(file.existsSync(), isTrue, reason: name);
        final (pw, ph, a) = header(file.readAsBytesSync());
        expect((pw, ph), (w, h), reason: name);
        expect(a, alpha, reason: name);
      }
    });

    test('every one of them is played on; Case 06\'s places have their pictures', () {
      // The scenes' tables, and the case's opening picture (a place picture).
      final scenes = [File('lib/data/mock/season2/season2_case06_scenes.dart').readAsStringSync(), File('lib/widgets/art_assets.dart').readAsStringSync()].join();
      for (final name in pictures.keys) {
        expect(scenes, contains(name), reason: name);
      }
      expect(ArtAssets.parisScenes[case06.introScene], '$folder/louvre_post_room_exterior.png');
      for (final m in case06.allMissions) {
        expect(ArtAssets.parisScenes[m.scene], isNotNull, reason: m.id);
      }
      expect(mapScene.mapFile, ArtAssets.parisMap, reason: 'the map of Paris, as on the map page');
    });

    test('the cut-outs are clear round their object', () async {
      for (final name in pictures.entries.where((e) => e.value.$3).map((e) => e.key)) {
        final (d, w, h) = await pixels('$folder/$name');
        expect(alphaAt(d, w, 2, 2), 0, reason: '$name: a clear corner');
        expect(alphaAt(d, w, w - 2, h - 2), 0, reason: name);
      }
    });

    test('the corner fits the right envelope only, as drawn: no gap, no overlap; the wrong ones clearly not', () async {
      Future<List<bool>> mask(String name) async {
        final (d, w, h) = await pixels('$folder/$name');
        return [for (var i = 0; i < w * h; i++) d.getUint8(i * 4 + 3) > 128];
      }

      const w = 1474;
      final corner = await mask('torn_corner_4417.png');
      final cornerArea = corner.where((a) => a).length;
      // Inside the whole envelope, a little in from its edges.
      const inner = Rect.fromLTRB(126, 115, 1362, 950);
      bool inside(int i) => inner.contains(Offset((i % w).toDouble(), (i ~/ w).toDouble()));
      for (final (name, fits) in [('torn_envelope_match.png', true), ('torn_envelope_decoy_a.png', false), ('torn_envelope_decoy_b.png', false)]) {
        final e = await mask(name);
        var overlap = 0, gap = 0, area = 0;
        for (var i = 0; i < e.length; i++) {
          if (corner[i] && e[i]) overlap++;
          if (inside(i)) {
            area++;
            if (!corner[i] && !e[i]) gap++;
          }
        }
        // The number tag lies on paper on every envelope, the same place on each.
        for (final dx in [-80, 0, 80]) {
          final at = archiveScene.numberTag.center + Offset(dx.toDouble(), 0);
          expect(e[at.dy.round() * w + at.dx.round()], isTrue, reason: '$name: the tag is on its paper');
        }
        if (fits) {
          expect(overlap / cornerArea, lessThan(0.02), reason: '$name: the torn edges meet');
          expect(gap / area, lessThan(0.003), reason: '$name: a hairline seam at most');
        } else {
          expect(overlap / cornerArea, greaterThan(0.05), reason: '$name: the corner lies over its paper');
        }
      }
      // The right envelope is the one the rules fit, and its seal spot is
      // where the seal is pressed.
      expect(archiveScene.envelope(archive.fitting.single.id).file, '$folder/torn_envelope_match.png');
      final (m, mw, _) = await pixels('$folder/torn_envelope_match.png');
      final c = archiveScene.sealAt.center;
      expect(alphaAt(m, mw, c.dx.round(), c.dy.round()), greaterThan(240), reason: 'the seal is on the paper');
      expect(corner[archiveScene.cornerTagAt.center.dy.round() * w + archiveScene.cornerTagAt.center.dx.round()], isTrue, reason: 'the number is on the sticker');
    });

    test('every place tapped or written on is inside its picture, and no two taps meet', () {
      Rect px(ScenePixels p) => Offset.zero & Size(p.width, p.height);
      bool within(Rect outer, Rect r) => outer.contains(r.topLeft) && outer.contains(r.bottomRight.translate(-0.01, -0.01));
      void apart(List<Rect> rs, String what) {
        for (var i = 0; i < rs.length; i++) {
          for (var j = i + 1; j < rs.length; j++) {
            expect(rs[i].overlaps(rs[j]), isFalse, reason: '$what $i and $j');
          }
        }
      }

      // M1: each tag's tap is round its paper, inside the part shown.
      expect(within(px(rackScene.pixels), rackScene.view), isTrue);
      for (final t in rackScene.tags) {
        expect(within(rackScene.view, t.spot), isTrue, reason: t.id);
        expect(within(t.spot, t.paper), isTrue, reason: t.id);
      }
      expect({for (final t in rackScene.tags) t.id}, {for (final t in rack.tags) t.id});
      apart([for (final t in rackScene.tags) t.spot], 'tag');
      expect(within(px(rackScene.tagPixels), rackScene.writeOn), isTrue);
      // M2: the stairs, the statue and the six doors.
      expect(within(px(planScene.pixels), planScene.view), isTrue);
      final taps = [for (final s in planScene.steps.values) s.area, for (final d in planScene.doors) d.area];
      for (final r in taps) {
        expect(within(planScene.view, r), isTrue, reason: '$r');
      }
      apart(taps, 'plan tap');
      expect({for (final d in planScene.doors) d.id}, {for (final d in plan.doors) d.id});
      // Each door's spot is on its own side of the corridor, in the order
      // the plan reads (up the page: the letter's left is the plan's left).
      for (final d in plan.doors) {
        final spot = planScene.doorSpot(d.id);
        expect(spot.area.center.dx < 512, d.side == Side.left, reason: d.id);
        expect(spot.at.dy < planScene.steps[PlanStep.statue]!.area.top, d.pastStatue, reason: '${d.id}: past the statue or not');
      }
      expect(planScene.doorSpot('e').at.dy, lessThan(planScene.doorSpot('c').at.dy), reason: 'E is the second on the left');
      expect(planScene.start.dy, greaterThan(planScene.steps[PlanStep.stairs]!.area.bottom), reason: 'it starts in the post room');
      // M3: the drawers and their labels, the envelopes in the drawer.
      for (final d in archiveScene.cabinetDrawers) {
        expect(within(archiveScene.cabinetView, d.area) && within(d.area, d.label), isTrue, reason: d.id);
      }
      apart([for (final d in archiveScene.cabinetDrawers) d.area], 'drawer');
      expect({for (final d in archiveScene.cabinetDrawers) d.id}, {for (final d in archive.drawers) d.id});
      for (final e in archiveScene.envelopes) {
        expect(within(archiveScene.drawerView, e.inDrawer), isTrue, reason: e.id);
        expect(e.inDrawer.width / e.inDrawer.height, closeTo(archiveScene.envelopePixels.aspect, 0.01), reason: '${e.id}: never stretched');
      }
      expect(within(px(archiveScene.envelopePixels), archiveScene.cornerPiece), isTrue);
      // The number tag covers the seal spot whole, and keeps clear of the torn corner.
      expect(within(px(archiveScene.envelopePixels), archiveScene.numberTag), isTrue);
      expect(within(archiveScene.numberTag.deflate(10), archiveScene.sealAt.deflate(10)), isTrue, reason: 'no edge of the spot peeps out');
      expect(archiveScene.numberTag.overlaps(archiveScene.cornerPiece), isFalse);
      expect(within(archiveScene.cornerPiece, archiveScene.cornerTagAt), isTrue);
      // Final: the letter's lines and drawing, the map's buildings.
      final paper = mapScene.letter;
      expect(within(px(paper.pixels), paper.writeOn) && within(px(paper.pixels), paper.sketchAt) && within(px(paper.pixels), paper.backOn), isTrue);
      expect(paper.writeOn.overlaps(paper.sketchAt), isFalse);
      expect(paper.sketchAt.width / paper.sketchAt.height, closeTo(mapScene.sketchPixels.aspect, 0.02), reason: 'the drawing is never stretched');
      final landmarks = {for (final l in ParisLandmark.values) l.name: l.at};
      for (final s in mapScene.spots) {
        expect(landmarks[s.name], s.at, reason: '${s.id}: the map\'s own landmark');
        final c = mapScene.closerOf(s);
        expect(c.left >= 0 && c.top >= 0 && c.right <= 1.0001 && c.bottom <= 1.0001, isTrue, reason: s.id);
      }
      expect({for (final s in mapScene.spots) s.id}, {for (final o in fin.options) o.id});
      // The map's round taps never meet.
      for (final a in mapScene.spots) {
        for (final b in mapScene.spots.where((b) => b != a)) {
          final d = Offset((a.at.dx - b.at.dx) * mapScene.mapPixels.width, (a.at.dy - b.at.dy) * mapScene.mapPixels.height).distance;
          expect(d, greaterThan(LetterMapPuzzle.tap), reason: '${a.id} and ${b.id}');
        }
      }
    });
  });

  group('in the game', () {
    test('Case 06 is in the game, after Case 05, at the Louvre, with its four puzzles', () {
      expect(SeasonCatalog.byId(SeasonIds.paris)!.episodes.keys, ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05', 's2_ep06']);
      expect(season2AwaitingArtJson, isEmpty);
      expect(SeasonCatalog.isAwaitingArt('s2_ep06'), isFalse);
      expect(const MockEpisodeRepository().fetchEpisode('s2_ep06'), completes);
      expect(case06.number, 6);
      expect(case06.seasonId, SeasonIds.paris);
      expect(case06.title, 'The Letter That Never Arrived');
      expect(case06.place, 'LOUVRE POST ROOM');
      expect([for (final m in case06.allMissions) m.id], ['s2_ep06_m1', 's2_ep06_m2', 's2_ep06_m3', 's2_ep06_final']);
      expect([for (final m in case06.allMissions) m.evidence!.name], ['The Hold Tag', "The Porter's Note", 'The Torn Envelope', 'The Letter']);
      expect(ParisLandmark.cases['s2_ep06'], ParisLandmark.louvre);
      expect(case06.introScene, Artwork.louvrePostRoom);
      expect([for (final m in case06.allMissions) m.scene], [Artwork.holdRack, Artwork.archiveFloorPlan, Artwork.archiveRoom, Artwork.archiveRoom]);
      // Each puzzle on its own pictures.
      expect(SeasonCatalog.holdRack(m1)?.rack, same(rack));
      expect(SeasonCatalog.planRoute(m2)?.route, same(plan));
      expect(SeasonCatalog.archive(m3)?.drawers, same(archive));
      expect(SeasonCatalog.letterMap(fin)?.map, same(letter));
      for (final m in case06.allMissions) {
        expect(SeasonCatalog.storyScenes(m)?.after, isNotNull, reason: m.id);
        expect(SeasonCatalog.evidenceArt(m.evidence!.id), isA<DrawnEvidenceArt>(), reason: m.id);
      }
    });

    test('its Discovery Moments name what each mission found', () {
      expect(season2DiscoveryTypes['s2_ep06_m1'], DiscoveryType.evidenceFound);
      expect(season2DiscoveryTypes['s2_ep06_m2'], DiscoveryType.newLead);
      expect(season2DiscoveryTypes['s2_ep06_m3'], DiscoveryType.evidenceFound);
      for (final m in case06.missions) {
        expect(SeasonCatalog.discovery(m).title, m.successMessage, reason: m.id);
      }
    });

    test("Case 06's Case Closed tells Case 07's title (the bible's), and nothing else of it", () {
      final season = SeasonCatalog.byId(SeasonIds.paris)!.season;
      expect(season.upcomingTitles, {7: 'The Phantom Performance'});
      expect(File('docs/SEASON2_PARIS_STORY_BIBLE.md').readAsStringSync(), contains('| 07 | **The Phantom Performance** | Palais Garnier |'));
      expect(case06.hook, 'What is in File 3–4 of the opera archive?');
      expect(case05.hook, 'Who held the letter at the Louvre post room?', reason: 'Case 05 is as it was');
    });
  });

  group('its story and puzzles', () {
    test("it opens on Case 05's last question; M1's clue is Case 05's slip, word for word", () {
      expect(case06.intro.first, contains('4417'));
      expect(case06.intro.first, contains('Louvre post room'));
      expect(case06.intro.last, 'Letter 4417 should be here.');
      final held = season2PostTrails['s2_ep05_final']!.slipOf('s3');
      expect(m1.letter, 'LETTER No. ${held.letter}\n${held.date} · ${held.time}\n${held.record} · ${held.where}');
      expect(rack.clue.number, held.letter);
      expect(rack.clue.date, held.date);
      expect(rack.clue.time, held.time);
      expect(rackScene.trail.lines, held.lines, reason: 'the slip itself is shown with it');
      expect(m1.letterIntro, contains("Letter's Trail"), reason: 'read in the notebook: Case 05\'s evidence');
      expect(SeasonCatalog.evidenceLink('s2_ep06_e1')!.to, 's2_ep05_e4');
    });

    test('M1: A and B are ruled out by their fronts; C and D only by their backs; only D is letter 4417', () {
      expect({for (final t in rack.tags) t.id}, {for (final o in m1.options) o.id});
      expect([for (final t in rack.fitting) t.id], [m1.answer]);
      expect(m1.answer, 'd');
      final [a, b, c, d] = rack.tags;
      expect(a.kind, PostKind.parcel);
      expect(a.frontFits(rack.clue), isFalse, reason: 'a parcel');
      expect(b.frontFits(rack.clue), isFalse, reason: '4471');
      expect(b.inked, isFalse);
      // Ink hides one digit on each of C and D: their fronts both could be.
      expect(c.inked && d.inked, isTrue);
      expect(c.frontFits(rack.clue) && d.frontFits(rack.clue), isTrue);
      expect(c.backFits(rack.clue), isFalse, reason: 'held on 15 May');
      expect(d.back, ['16 MAY · 4:00 PM', 'HELD', 'PRESERVATION ORDER', 'Keep it safe.', 'Do not send it.', 'Do not throw it away.']);
      expect(d.front, ['LETTER No. 4?17']);
      for (final o in m1.options.where((o) => o.id != m1.answer)) {
        expect(o.feedback, isNotNull, reason: o.id);
      }
      expect(m1.successMessage, "Wait! It wasn't stolen.");
      expect(m1.transition, contains('Someone kept it safe.'));
      expect(HoldRack.turnedKey('d'), 'turned-d');
      // Tag D is not where the eye goes first: it hangs low, alone.
      expect(rackScene.spotOf('d').spot.top, greaterThan(rackScene.spotOf('a').spot.bottom));
    });

    test('M2: held, then moved the next morning; the note leads past the statue to the second door on the left', () {
      expect(m2.story, containsAll(['16 MAY · 4:00 PM · HELD.', '17 MAY · MORNING · MOVED.']));
      expect(m2.letter, contains('Walk past the statue.'));
      expect(m2.letter, contains('Take the second door on the left.'));
      expect({for (final d in plan.doors) d.id}, {for (final o in m2.options) o.id});
      expect([for (final d in plan.followed) d.id], [m2.answer]);
      expect(plan.archive, m2.answer);
      expect(m2.answer, 'e');
      expect({for (final d in plan.doors) (d.side, d.pastStatue, d.nth)}, hasLength(plan.doors.length));
      expect(PlanRoute.canReach(PlanStep.stairs, {}), isTrue);
      expect(PlanRoute.canReach(PlanStep.statue, {}), isFalse);
      expect(PlanRoute.canReach(PlanStep.statue, {PlanStep.stairs}), isTrue);
      expect(PlanRoute.canOpen(plan.door('a'), {}), isFalse, reason: 'down the stairs first');
      expect(PlanRoute.canOpen(plan.door('a'), {PlanStep.stairs}), isTrue);
      expect(PlanRoute.canOpen(plan.door('e'), {PlanStep.stairs}), isFalse, reason: 'past the statue first');
      expect(PlanRoute.canOpen(plan.door('e'), {PlanStep.stairs, PlanStep.statue}), isTrue);
      for (final d in plan.doors.where((d) => d.id != m2.answer)) {
        final feedback = m2.options.firstWhere((o) => o.id == d.id).feedback!;
        if (!d.pastStatue) {
          expect(feedback, contains('statue'), reason: d.id);
        } else if (d.side == Side.right) {
          expect(feedback, contains('right'), reason: d.id);
        } else {
          expect(feedback, contains('first door'), reason: d.id);
        }
      }
      expect(m2.successMessage, 'The letter went to the archive!');
      expect(PlanRoute.reachedKey(PlanStep.statue), 'reached-statue');
    });

    test('M3: only one drawer keeps letter 4417; the corner from Clock III fits only one envelope', () {
      expect([for (final d in archive.keeping) d.id], ['l4400']);
      final parcels = archive.drawer('p4400');
      expect((parcels.from, parcels.to), (archive.drawer('l4400').from, archive.drawer('l4400').to));
      expect(parcels.keeps(PostKind.letter, 4417), isFalse);
      expect(archive.drawer('l4400').label, 'LETTERS · 4400–4599');
      expect(archiveScene.refusalOf('p4400'), contains('parcels'));
      expect(archiveScene.refusalOf('l4000'), contains('Is 4417 between'));
      expect({for (final e in archive.envelopes) e.id}, {for (final o in m3.options) o.id});
      expect([for (final e in archive.fitting) e.id], [m3.answer]);
      expect(m3.answer, 'y');
      // Envelope 2 of the three, as its option says.
      expect(archiveScene.envelopes.indexWhere((e) => e.id == m3.answer) + 1, 2);
      expect(m3.options.firstWhere((o) => o.id == m3.answer).label, 'Envelope 2');
      expect(season2Blotters['s2_ep05_m3']!.hideaway.tag, archive.cornerLabel);
      expect(m3.letter, startsWith(archive.cornerLabel));
      expect(SeasonCatalog.evidenceLink('s2_ep06_e3')!.to, 's2_ep05_e3');
      expect(m3.successMessage, 'There it is! Letter 4417!');
      expect(m3.transition, contains("But what's this little picture on the seal?"));
    });

    test('Final: only the Palais Garnier has the drawing and plays shows; its back leads to Case 07', () {
      expect(fin.letter, 'The clocks may lie.\nBut the show remembers.');
      expect(mapScene.letter.lines, fin.letter.split('\n'));
      expect({for (final b in letter.buildings) b.id}, {for (final o in fin.options) o.id});
      for (final o in fin.options) {
        expect(ParisLandmark.values.byName(o.id).name, o.label);
      }
      expect([for (final b in letter.matching) b.id], [fin.answer]);
      expect(fin.answer, 'palaisGarnier');
      expect(letter.building('montmartre').features.containsAll(letter.drawing), isFalse);
      expect(ParisLandmark.cases['s2_ep07'], ParisLandmark.values.byName(fin.answer));
      expect(letter.back, ['OPERA ARCHIVE', 'FILE 3–4']);
      expect(mapScene.letter.back, letter.back);
      expect(fin.transition, contains('On the back: OPERA ARCHIVE · FILE 3–4.'));
      expect(fin.transition.last, 'The mystery continues at the opera house!');
      expect(fin.successMessage, 'We found our next clue!');
      for (final o in fin.options.where((o) => o.id != fin.answer)) {
        expect(o.feedback, isNotNull, reason: o.id);
      }
    });

    test('nothing is told before its time; the letter\'s writer, the order\'s giver and the removed record, never', () {
      final beforeM2 = [everything([m1]), beforeSolved(m2)].join('\n');
      expect(beforeM2.toLowerCase(), isNot(contains('archive')));
      final beforeFinal = [
        everything([m1, m2, m3]),
        ...case06.intro,
        ...case06.synopsis,
        ...case06.objectives,
        beforeSolved(fin),
        // What the puzzles' pages say.
        rackScene.lookTask, planScene.task, archiveScene.cabinetTask, archiveScene.drawerTask, archiveScene.sealLine, archiveScene.sealLabel,
        mapScene.mapTask, mapScene.drawingLabel,
      ].join('\n');
      for (final secret in ['opera', 'garnier', 'file 3']) {
        expect(beforeFinal.toLowerCase(), isNot(contains(secret)), reason: secret);
      }
      final all = [everything(case06.allMissions, e: case06), File('lib/data/mock/season2/season2_case06_scenes.dart').readAsStringSync()].join('\n').toUpperCase();
      for (final banned in ['RECORD WAS REMOVED', 'CLOCKMAKER', 'VICTOR', 'ÉMILE', 'EMILE', 'THIEF']) {
        expect(all, isNot(contains(banned)), reason: banned);
      }
    });

    test('its English is short: one idea a sentence', () {
      for (final m in case06.allMissions) {
        for (final line in [...m.story, ...m.transition, ...m.hints, ...m.letter.split('\n')]) {
          for (final sentence in line.split(RegExp(r'(?<=[.!?])\s+'))) {
            expect(sentence.split(' ').length, lessThanOrEqualTo(12), reason: '${m.id}: $sentence');
          }
        }
      }
    });

    test('every word in its glossary is in its text', () {
      final text = [
        everything(case06.allMissions, e: case06),
        for (final t in rack.tags) ...[...t.front, ...t.back],
        for (final d in archive.drawers) d.label,
      ].join('\n').toLowerCase();
      for (final w in case06.glossary.keys) {
        expect(text, contains(w), reason: w);
      }
    });

    test('its learning design follows Season 1\'s rules', () {
      String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      String screen(Mission m) => norm([...m.story, m.letterIntro, m.letter, m.question, for (final o in m.options) o.label, ...m.hints].join(' \n '));
      expect(season2Learning.keys.where((id) => id.startsWith('s2_ep06_')).toSet(), {for (final m in case06.allMissions) m.id});
      expect(season2LanguageTopics['s2_ep06'], isNotNull);
      for (final m in case06.allMissions) {
        final l = SeasonCatalog.learning(m)!;
        expect(l.isHonest, isTrue, reason: m.id);
        if (l.dependency == LanguageDependency.essential) expect(l.expressions, isNotEmpty);
        for (final e in l.expressions) {
          expect(screen(m), contains(norm(e)), reason: '${m.id}: "$e" is on its screens');
        }
      }
    });

    test('its evidence leads on from Case 05, one piece to the next', () {
      expect(SeasonCatalog.evidenceLink('s2_ep06_e2')!.to, 's2_ep06_e1');
      expect(SeasonCatalog.evidenceLink('s2_ep06_e4')!.to, 's2_ep06_e3');
      expect(SeasonCatalog.evidenceLink('s2_ep05_e4')!.to, 's2_ep05_e3', reason: "Case 05's links are as they were");
    });
  });

  group('its rules', () {
    late SharedPreferences prefs;

    Future<ProviderContainer> start() async {
      final c = ProviderContainer(overrides: await testOverridesFor(prefs));
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

    test('it opens only once Case 05 is solved', () async {
      final c = await start();
      final game = c.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      for (final e in paris.take(4)) {
        solve(c, e);
      }
      expect(game.openEpisode('s2_ep06'), isFalse, reason: 'no way round Case 05');
      expect(c.read(seasonProvider.notifier).isUnlocked('s2_ep06'), isFalse);
      solve(c, case05);
      expect(c.read(seasonProvider.notifier).isUnlocked('s2_ep06'), isTrue);
      expect(c.read(seasonOverviewProvider).comingSoonCase, isNot(6), reason: 'Case 06 is open now');
      expect(game.openEpisode('s2_ep06'), isTrue);
      expect(c.read(currentEpisodeProvider).id, 's2_ep06');
    });

    test('what is turned over, walked, opened and looked at is saved and comes back after a restart', () async {
      var c = await start();
      var game = c.read(gameControllerProvider.notifier);
      game.openSeason(SeasonIds.paris);
      for (final e in paris) {
        solve(c, e);
      }
      game.openEpisode('s2_ep06');
      game.startInvestigation();
      game.recordExamined(GameProgress.examinedKey(m1.id, HoldRack.turnedKey('c')));
      game.recordExamined(GameProgress.examinedKey(m1.id, HoldRack.turnedKey('d')));
      expect(game.submitAnswer(m1, 'c').result, SubmitResult.tryAgain);
      expect(game.submitAnswer(m2, m2.answer).result, SubmitResult.locked, reason: 'missions in order');
      expect(game.submitAnswer(m1, m1.answer).result, SubmitResult.correct);
      game.recordExamined(GameProgress.examinedKey(m2.id, PlanRoute.reachedKey(PlanStep.stairs)));
      game.recordExamined(GameProgress.examinedKey(m2.id, PlanRoute.reachedKey(PlanStep.statue)));
      expect(game.submitAnswer(m2, 'c').result, SubmitResult.tryAgain);
      expect(game.submitAnswer(m2, m2.answer).result, SubmitResult.correct);
      game.recordExamined(GameProgress.examinedKey(m3.id, ArchiveDrawers.openedKey('l4400')));

      c.dispose();
      c = await start();
      game = c.read(gameControllerProvider.notifier);
      expect(c.read(currentEpisodeProvider).id, 's2_ep06');
      var p = c.read(gameControllerProvider);
      expect(p.isCompleted(m1.id) && p.isCompleted(m2.id), isTrue);
      expect(p.isCompleted(m3.id), isFalse);
      expect((p.wrongCount(m1.id), p.wrongCount(m2.id)), (1, 1));
      expect(p.hasExamined('${m1.id}:turned-c') && p.hasExamined('${m1.id}:turned-d'), isTrue);
      expect(p.hasExamined('${m1.id}:turned-a'), isFalse);
      expect(p.hasExamined('${m2.id}:reached-stairs') && p.hasExamined('${m2.id}:reached-statue'), isTrue);
      expect(p.hasExamined('${m3.id}:drawer-l4400'), isTrue);

      expect(game.submitAnswer(m3, 'x').result, SubmitResult.tryAgain);
      expect(game.submitAnswer(m3, m3.answer).result, SubmitResult.correct);
      game.recordExamined(GameProgress.examinedKey(m3.id, ArchiveDrawers.sealId));
      game.recordExamined(GameProgress.examinedKey(fin.id, LetterMap.lookedKey('montmartre')));

      c.dispose();
      c = await start();
      game = c.read(gameControllerProvider.notifier);
      p = c.read(gameControllerProvider);
      expect(p.hasExamined('${m3.id}:seal') && p.hasExamined('${fin.id}:looked-montmartre'), isTrue);
      expect(game.submitAnswer(fin, 'montmartre').result, SubmitResult.tryAgain);
      expect(game.submitAnswer(fin, fin.answer).result, SubmitResult.correct);
      p = c.read(gameControllerProvider);
      expect([for (final e in p.collectedEvidence(case06)) e.name], ['The Hold Tag', "The Porter's Note", 'The Torn Envelope', 'The Letter']);
      expect(p.isCaseSolved, isTrue);
      expect(c.read(progressRepositoryProvider).load('s2_ep05').isCaseSolved, isTrue, reason: "Case 05's save is its own");
      expect(c.read(progressRepositoryProvider).load('s2_ep05').examined.any((k) => k.startsWith('s2_ep06')), isFalse);
    });

    test('solved: Paris is 6 of 12, Case 07 is coming soon, nothing opens it; London is as it was', () async {
      final c = await start();
      final game = c.read(gameControllerProvider.notifier);
      game.openSeason(SeasonIds.paris);
      for (final e in [...paris, case06]) {
        solve(c, e);
      }
      final board = c.read(seasonOverviewProvider);
      expect(board.solvedCount, 6);
      expect(board.comingSoonCase, 7);
      final available = c.read(seasonAvailabilityProvider(SeasonIds.paris))!;
      expect((available.solvedCount, available.plannedCount), (6, 12));
      expect(game.openEpisode('s2_ep07'), isFalse, reason: 'no Case 07 to open');
      expect(c.read(progressRepositoryProvider).loadSeason(SeasonIds.london).solvedEpisodeIds, hasLength(12));
    });
  });

  group('a child plays Case 06', () {
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
      testWidgets('$tag: Case 05 closed → hold rack → plan → archive and seal → letter and map, 6 of 12', (t) async {
        final ref = await open(t, size);
        final router = ref.read(routerProvider);
        final game = ref.read(gameControllerProvider.notifier);

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
            File('$shots/paris06_${tag}_${(n++).toString().padLeft(2, '0')}_$name.png').writeAsBytesSync(png!.buffer.asUint8List());
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
        void nothingOfTheOpera(String where) {
          expect(find.textContaining('OPERA', findRichText: true), findsNothing, reason: where);
          expect(find.textContaining('Garnier', findRichText: true), findsNothing, reason: where);
        }

        // ── Case 05's Case Closed: on to Case 06 ────────────────────────
        router.go(Routes.solvedSettled);
        await wait(t, const Duration(milliseconds: 3000));
        await reveal(t, find.text('OPEN CASE 06'));
        expect(find.text('OPEN CASE 06'), findsOneWidget, reason: 'Case 06 is in the game now');
        await shot('case05_closed');
        expect(game.openEpisode('s2_ep06'), isTrue);

        // ── The opening ─────────────────────────────────────────────────
        router.go(Routes.intro);
        await wait(t, const Duration(milliseconds: 900));
        await tapText(t, 'SKIP ›', after: const Duration(milliseconds: 900));
        await shot('opening');
        await tapText(t, "I'M READY", after: const Duration(milliseconds: 1600));

        // ── M1: the hold rack ───────────────────────────────────────────
        await visit(m1.id);
        expect(find.byKey(const ValueKey('story-picture')), findsOneWidget, reason: 'the rack');
        await shot('m1_place');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('rack-clue')), findsOneWidget, reason: "the Letter's Trail beside the rack");
        for (final id in ['a', 'b', 'c', 'd']) {
          expect(find.byKey(ValueKey('rack-tag-$id')), findsOneWidget);
        }
        nothingOfTheOpera('M1');
        await shot('m1_rack');
        // The tag's tap is where its paper is drawn.
        final rackBox = t.getRect(find.byKey(const ValueKey('rack')));
        final k = rackBox.width / rackScene.view.width;
        final dSpot = t.getRect(find.byKey(const ValueKey('rack-tag-d')));
        final dPaper = rackScene.spotOf('d').paper;
        expect(dSpot.contains(rackBox.topLeft + (dPaper.center - rackScene.view.topLeft) * k), isTrue, reason: 'tap on the drawn tag');
        expect(dSpot.width, greaterThanOrEqualTo(44), reason: '$tag: a finger-sized tap');
        await tapKey('rack-tag-c', after: const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('tag-front-view')), findsOneWidget);
        expect(find.byKey(const ValueKey('tag-ink-c')), findsOneWidget, reason: 'ink hides a digit');
        expect(find.text('LETTER'), findsOneWidget);
        await shot('m1_tag_c_front');
        await tapKey('tag-turn', after: const Duration(milliseconds: 700));
        expect(find.byKey(const ValueKey('tag-back-view')), findsOneWidget);
        expect(find.text('15 MAY\n11:00 AM'), findsOneWidget);
        expect(examined(), contains('s2_ep06_m1:turned-c'));
        await shot('m1_tag_c_back');
        await tapKey('tag-choose', after: const Duration(milliseconds: 400));
        await wrongThenTryAgain('Check the day and the time', 'm1');
        await tapKey('rack-tag-d', after: const Duration(milliseconds: 600));
        await tapKey('tag-turn', after: const Duration(milliseconds: 700));
        expect(find.text('PRESERVATION ORDER'), findsOneWidget);
        expect(find.text('Keep it safe.'), findsOneWidget);
        await shot('m1_tag_d_back');
        await tapKey('tag-choose');
        await finish(m1.transition.first, 'm1');
        expect(ref.read(gameControllerProvider).isCompleted(m1.id), isTrue);

        // ── M2: the plan ────────────────────────────────────────────────
        await visit(m2.id);
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('porter-note')), findsOneWidget);
        expect(find.byKey(const ValueKey('plan-next-stairs')), findsOneWidget, reason: 'the stairs first');
        expect(t.widget<GameButton>(find.byKey(const ValueKey('plan-go'))).onPressed, isNull, reason: 'at no door yet');
        await shot('m2_plan');
        final doorE = t.getRect(find.byKey(const ValueKey('plan-door-e')));
        expect(doorE.width >= 44 && doorE.height >= 40, isTrue, reason: '$tag: a finger-sized door ($doorE)');
        await tapKey('plan-door-e');
        expect(find.text(planScene.stairsFirst), findsOneWidget);
        await tapKey('plan-stairs', after: const Duration(milliseconds: 700));
        expect(examined(), contains('s2_ep06_m2:reached-stairs'));
        await tapKey('plan-door-e');
        expect(find.text(planScene.statueFirst), findsOneWidget);
        await tapKey('plan-statue', after: const Duration(milliseconds: 700));
        expect(examined(), contains('s2_ep06_m2:reached-statue'));
        await tapKey('plan-door-c', after: const Duration(milliseconds: 700));
        expect(find.text('GO THROUGH DOOR C'), findsOneWidget);
        await shot('m2_at_c');
        await tapKey('plan-go');
        await wrongThenTryAgain('Count one more', 'm2');
        // Out and back: the letter is still past the statue.
        router.go(Routes.map);
        await wait(t, const Duration(milliseconds: 1400));
        await visit(m2.id);
        expect(find.byKey(const ValueKey('plan-next-stairs')), findsNothing, reason: 'saved: down the stairs');
        expect(find.byKey(const ValueKey('plan-next-statue')), findsNothing, reason: 'saved: past the statue');
        await tapKey('plan-door-e', after: const Duration(milliseconds: 700));
        await shot('m2_at_e');
        await tapKey('plan-go');
        await finish(m2.transition.first, 'm2');

        // ── M3: the archive ─────────────────────────────────────────────
        await visit(m3.id);
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('cabinet')), findsOneWidget);
        expect(find.text('LETTERS\n4400–4599'), findsOneWidget);
        expect(find.text('PARCELS\n4400–4599'), findsOneWidget);
        nothingOfTheOpera('M3');
        await shot('m3_cabinet');
        await tapKey('drawer-p4400');
        expect(findReadableContaining('This drawer is for parcels.'), findsOneWidget);
        expect(find.byKey(const ValueKey('open-drawer')), findsNothing);
        await shot('m3_parcels');
        await tapKey('drawer-l4400', after: const Duration(milliseconds: 700));
        expect(find.byKey(const ValueKey('open-drawer')), findsOneWidget);
        expect(examined(), containsAll(['s2_ep06_m3:drawer-p4400', 's2_ep06_m3:drawer-l4400']));
        // Every envelope has the same number tag at the same place: nothing
        // but the torn edge tells them apart.
        final tags = [for (final e in archiveScene.envelopes) t.getRect(find.byKey(ValueKey('envelope-tag-${e.id}')))];
        for (final r in tags.skip(1)) {
          expect(r.width, closeTo(tags.first.width, 0.01));
          expect(r.top, closeTo(tags.first.top, 40));
        }
        await shot('m3_drawer');
        await tapKey('envelope-x', after: const Duration(milliseconds: 600));
        expect(find.text('ENVELOPE 1'), findsOneWidget);
        await shot('m3_envelope_1');
        await tapKey('corner-lay', after: const Duration(milliseconds: 300));
        await wait(t, const Duration(milliseconds: 500));
        expect(find.text(archiveScene.notFit), findsOneWidget, reason: 'it does not fit');
        await shot('m3_envelope_1_laid');
        await wait(t, const Duration(milliseconds: 600));
        await wrongThenTryAgain('The torn edges do not match.', 'm3');
        expect(ref.read(gameControllerProvider).isCompleted(m3.id), isFalse);
        // Envelope 2: the corner dragged onto it settles where it was torn from.
        await tapKey('envelope-y', after: const Duration(milliseconds: 600));
        double tagShown(String id) => t
            .widget<AnimatedOpacity>(find.ancestor(of: find.byKey(ValueKey('envelope-tag-$id')).last, matching: find.byType(AnimatedOpacity)).first)
            .opacity;
        expect(tagShown('y'), 1, reason: 'the seal spot is covered until the corner fits');
        final canvas = t.getRect(find.byKey(const ValueKey('envelope-close-y')));
        final kc = canvas.width / archiveScene.envelopePixels.width;
        final from = t.getCenter(find.byKey(const ValueKey('corner-drag')));
        final home = canvas.topLeft + archiveScene.cornerPiece.center * kc;
        final g = await t.startGesture(from);
        for (var i = 1; i <= 12; i++) {
          await g.moveTo(Offset.lerp(from, home + const Offset(10, 12), i / 12)!);
          await t.pump(const Duration(milliseconds: 16));
        }
        await g.up();
        await wait(t, const Duration(milliseconds: 500));
        expect(find.text('It fits!'), findsOneWidget);
        expect(tagShown('y'), 0, reason: 'fitted: the tag comes off, the seal spot shows');
        await wait(t, const Duration(milliseconds: 600));
        expect(t.getCenter(find.byKey(const ValueKey('corner-drag'))), within(distance: 1.5, from: home), reason: 'it snaps where it was torn from');
        await shot('m3_fits');
        await wait(t, const Duration(milliseconds: 1200));
        expect(ref.read(gameControllerProvider).isCompleted(m3.id), isTrue);
        expect(find.byKey(const ValueKey('envelope-found')), findsOneWidget, reason: 'the envelope found first');
        expect(find.byKey(const ValueKey('envelope-seal')), findsOneWidget);
        await shot('m3_found');
        await tapKey('envelope-seal-look', after: const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('seal-close')), findsOneWidget);
        expect(findReadable(archiveScene.sealLine), findsOneWidget);
        await shot('m3_seal');
        await tapKey('seal-close-done', after: const Duration(milliseconds: 300));
        expect(examined(), contains('s2_ep06_m3:seal'));
        await finish(m3.transition.first, 'm3');

        // ── Final: the letter and the map ───────────────────────────────
        router.go(Routes.finalMission);
        await wait(t, const Duration(milliseconds: 1600));
        expect(find.byKey(const ValueKey('letter-stage')), findsOneWidget);
        expect(find.byKey(const ValueKey('letter-face-front')), findsOneWidget);
        expect(find.byKey(const ValueKey('letter-back')), findsNothing, reason: 'its back is read with the solve');
        nothingOfTheOpera('the final, before');
        await shot('final_page');
        await tapKey('look-at-drawing', after: const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('drawing-close')), findsOneWidget);
        await shot('final_drawing');
        await tapKey('drawing-done', after: const Duration(milliseconds: 400));
        await reveal(t, find.byKey(const ValueKey('letter-map')));
        await shot('final_map');
        for (final s in mapScene.spots) {
          final r = t.getRect(find.byKey(ValueKey('map-spot-${s.id}')));
          expect(r.width, greaterThanOrEqualTo(44), reason: '$tag: ${s.id} is finger-sized ($r)');
        }
        // A tap on the drawn building opens it; one between two buildings opens neither.
        final map = t.getRect(find.byKey(const ValueKey('letter-map')));
        final km = map.width / 1200;
        Offset onMap(Offset f) => map.topLeft + (Offset(f.dx * 1536, f.dy * 1024) - const Offset(90, 30)) * km;
        final between = Offset.lerp(mapScene.spot('palaisGarnier').at, mapScene.spot('louvre').at, 0.5)!;
        await t.tapAt(onMap(between));
        await wait(t, const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('building-name')), findsNothing, reason: 'between the two round taps');
        await tapKey('map-spot-montmartre', after: const Duration(milliseconds: 600));
        expect(find.text('MONTMARTRE'), findsOneWidget);
        await shot('final_montmartre');
        await tapKey('building-choose');
        await wrongThenTryAgain('no statues on the roof', 'final');
        expect(examined(), contains('s2_ep06_final:looked-montmartre'));
        await tapKey('map-spot-palaisGarnier', after: const Duration(milliseconds: 600));
        expect(find.text('PALAIS GARNIER'), findsOneWidget);
        await shot('final_garnier');
        await tapKey('building-choose');
        await wait(t, const Duration(milliseconds: 3600));
        expect(ref.read(gameControllerProvider).isCaseSolved, isTrue);
        expect(find.byKey(const ValueKey('letter-face-back')), findsOneWidget, reason: 'turned over');
        expect(find.byKey(const ValueKey('letter-back')), findsOneWidget);
        expect(find.text('OPERA ARCHIVE'), findsOneWidget);
        expect(find.text('FILE 3–4'), findsOneWidget);
        expect(findReadableContaining('We found our next clue!'), findsWidgets);
        await shot('final_solved');
        await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 900));
        expect(find.text(fin.transition.first), findsOneWidget);
        await t.tapAt(Offset(size.width / 2, size.height / 2));
        await wait(t, const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('scene-backdrop')), findsOneWidget, reason: 'the drawing');
        expect(findReadable('The mystery continues at the opera house!'), findsOneWidget);
        await shot('final_scene');
        await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 4000));
        await reveal(t, find.byKey(const ValueKey('next-case-coming-soon')));
        expect(find.text('CASE 07 · THE PHANTOM PERFORMANCE'), findsOneWidget);
        expect(find.text('COMING SOON'), findsOneWidget);
        await shot('case_closed');

        final board = ref.read(seasonOverviewProvider);
        expect(board.solvedCount, 6);
        expect(board.comingSoonCase, 7);
        expect(game.openEpisode('s2_ep07'), isFalse);
        await wait(t, const Duration(seconds: 3));
      });
    }

    testWidgets('back again after a restart: the tags turned, the steps walked, the drawer opened are as left', (t) async {
      final ref = await open(t, const Size(390, 844));
      final game = ref.read(gameControllerProvider.notifier);
      expect(game.openEpisode('s2_ep06'), isTrue);
      game.startInvestigation();
      game.recordExamined(GameProgress.examinedKey(m1.id, HoldRack.turnedKey('b')));
      final router = ref.read(routerProvider);
      router.go(Routes.mission(m1.id));
      await wait(t, const Duration(milliseconds: 1400));
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      expect(find.descendant(of: find.byKey(const ValueKey('rack-tag-b')), matching: find.byType(CircleAvatar)), findsOneWidget, reason: 'B turned before');
      expect(find.descendant(of: find.byKey(const ValueKey('rack-tag-a')), matching: find.byType(CircleAvatar)), findsNothing);
      game.submitAnswer(m1, m1.answer);
      game.markMissionStarted(m2.id);
      game.recordExamined(GameProgress.examinedKey(m2.id, PlanRoute.reachedKey(PlanStep.stairs)));
      // As a child goes: back by the map.
      router.go(Routes.map);
      await wait(t, const Duration(milliseconds: 1400));
      router.go(Routes.mission(m2.id));
      await wait(t, const Duration(milliseconds: 1400));
      // Started before: straight to the plan, the letter at the stairs.
      expect(find.byKey(const ValueKey('plan')), findsOneWidget);
      expect(find.byKey(const ValueKey('plan-next-stairs')), findsNothing);
      expect(find.byKey(const ValueKey('plan-next-statue')), findsOneWidget, reason: 'the statue next');
      final plan = t.getRect(find.byKey(const ValueKey('plan')));
      final letterAt = t.getCenter(find.byKey(const ValueKey('plan-letter')));
      final kp = plan.width / planScene.view.width;
      expect(letterAt, within(distance: 2, from: plan.topLeft + (planScene.steps[PlanStep.stairs]!.at - planScene.view.topLeft) * kp));
      game.submitAnswer(m2, m2.answer);
      game.recordExamined(GameProgress.examinedKey(m3.id, ArchiveDrawers.openedKey('l4400')));
      router.go(Routes.map);
      await wait(t, const Duration(milliseconds: 1400));
      router.go(Routes.mission(m3.id));
      await wait(t, const Duration(milliseconds: 1400));
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      expect(find.byKey(const ValueKey('open-drawer')), findsOneWidget, reason: 'the drawer stays open');
      // Solved but the seal not looked at (a restart): the envelope found, its seal next.
      game.submitAnswer(m3, m3.answer);
      router.go(Routes.map);
      await wait(t, const Duration(milliseconds: 1400));
      router.go(Routes.mission(m3.id));
      await wait(t, const Duration(milliseconds: 1400));
      expect(find.byKey(const ValueKey('envelope-seal-look')), findsOneWidget);
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 3));
    });
  });
}
