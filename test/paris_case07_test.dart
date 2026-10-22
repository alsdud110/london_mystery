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
import 'package:london_mystery/data/mock/season2/season2_case07_scenes.dart';
import 'package:london_mystery/data/mock/season2/season2_discoveries.dart';
import 'package:london_mystery/data/mock/season2/season2_learning.dart';
import 'package:london_mystery/data/mock/season2/season2_mock.dart';
import 'package:london_mystery/data/mock/season_catalog.dart';
import 'package:london_mystery/data/models/discovery.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/learning.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/opera_puzzles.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/river_puzzles.dart';
import 'package:london_mystery/data/models/scene_explore.dart' show ScenePixels;
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/mission/widgets/light_board.dart' show LitStage;
import 'package:london_mystery/features/mission_map/map_world.dart';
import 'package:london_mystery/features/season/season_overview.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/game_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';

/// Season 2, Case 07 — The Phantom Performance: its twenty-nine pictures
/// (as delivered, measured), its story and puzzles as the strip, the
/// lights, the backdrops and the light table say them, its rules (unlock
/// after Case 06, saves, Case 08 still to come), and a child playing it
/// through on three phones. Nothing is told before its time; who changed
/// the record and why, and any name behind it, never.
///
/// `LM_SHOTS=folder` saves a picture of each step of the play-through.
void main() {
  final inGame = MockEpisodeRepository.bundled();
  final s1 = season1Cases();
  final paris = [for (final id in ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05', 's2_ep06']) inGame.firstWhere((e) => e.id == id)];
  final case06 = paris.last;
  final case07 = inGame.firstWhere((e) => e.id == 's2_ep07');
  final [m1, m2, m3, fin] = case07.allMissions;
  final shots = Platform.environment['LM_SHOTS'];

  final strip = season2ShowStrips[m1.id]!;
  final board = season2LightBoards[m2.id]!;
  final rail = season2FlyRails[m3.id]!;
  final record = season2ChangedRecords[fin.id]!;

  final stripScene = SeasonCatalog.showStrip(m1)!;
  final lightScene = SeasonCatalog.lightBoard(m2)!;
  final railScene = SeasonCatalog.flyRail(m3)!;
  final tableScene = SeasonCatalog.lightTable(fin)!;

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
    const folder = 'assets/seasons/season_02_paris/cases/case_07';
    // Size, and whether it has an alpha channel (as delivered, never
    // changed).
    const pictures = {
      'palais_garnier_night.png': (1536, 1024, false),
      'opera_archive_room.png': (1536, 1024, false),
      'office_record_blank.png': (1055, 1491, true),
      'record_patch.png': (1983, 793, true),
      'programme_page_blank.png': (1024, 1536, true),
      'show_strip_blank.png': (2172, 724, true),
      'photo_frame.png': (1536, 1024, true),
      'stage_base.png': (1536, 1024, false),
      'stage_ghost.png': (1536, 1024, false),
      'stage_house.png': (1536, 1024, false),
      'stage_foot.png': (1536, 1024, false),
      'stage_spot.png': (1536, 1024, false),
      'lighting_desk.png': (1536, 1024, true),
      'lighting_lever.png': (1024, 1536, true),
      'lighting_book_open.png': (1536, 1024, true),
      'cue_card_blank.png': (1536, 1024, true),
      'scrap_clock_door.png': (1254, 1254, true),
      'fly_rail.png': (1536, 1024, false),
      'rope_line.png': (1024, 1536, true),
      'backdrop_clock_red.png': (1536, 1024, true),
      'backdrop_lamp_red.png': (1536, 1024, true),
      'backdrop_clock_blue.png': (1536, 1024, true),
      'backdrop_tower_red.png': (1536, 1024, true),
      'backdrop_back_pocket.png': (1536, 1024, false),
      'amendment_slip_blank.png': (1536, 1024, true),
      'office_stamp.png': (1254, 1254, true),
      'abbesses_sketch.png': (1536, 1024, true),
      'light_table_off.png': (1536, 1024, false),
      'light_table_on.png': (1536, 1024, false),
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

    test('all twenty-nine are in, listed in pubspec, at their sizes', () {
      expect(File('pubspec.yaml').readAsStringSync(), contains('    - $folder/\n'));
      expect(Directory(folder).listSync().whereType<File>().where((f) => f.path.endsWith('.png')).length, 29);
      for (final MapEntry(key: name, value: (w, h, alpha)) in pictures.entries) {
        final file = File('$folder/$name');
        expect(file.existsSync(), isTrue, reason: name);
        final (pw, ph, a) = header(file.readAsBytesSync());
        expect((pw, ph), (w, h), reason: name);
        expect(a, alpha, reason: name);
      }
    });

    test("every one of them is played on; Case 07's places have their pictures", () {
      final scenes = [File('lib/data/mock/season2/season2_case07_scenes.dart').readAsStringSync(), File('lib/widgets/art_assets.dart').readAsStringSync()].join();
      for (final name in pictures.keys) {
        expect(scenes, contains(name), reason: name);
      }
      expect(ArtAssets.parisScenes[case07.introScene], '$folder/palais_garnier_night.png');
      for (final m in case07.allMissions) {
        expect(ArtAssets.parisScenes[m.scene], isNotNull, reason: m.id);
      }
    });

    test('the cut-outs are truly clear round their object (no checkerboard painted in)', () async {
      for (final name in pictures.entries.where((e) => e.value.$3).map((e) => e.key)) {
        final (d, w, h) = await pixels('$folder/$name');
        var clear = 0;
        for (var i = 0; i < w * h; i += 7) {
          if (d.getUint8(i * 4 + 3) < 10) clear++;
        }
        expect(clear / (w * h / 7), greaterThan(0.05), reason: '$name: clear round its object');
        // A corner of a cut-out paper or object is clear (the backdrops'
        // batten reaches the top edge: their bottom corners are clear).
        expect(alphaAt(d, w, 2, h - 3), 0, reason: '$name: a clear corner');
        expect(alphaAt(d, w, w - 3, h - 3), 0, reason: name);
      }
    });

    test('each lit stage is the dark stage with one light on; the four backdrops are one painting', () async {
      Future<double> difference(String a, String b) async {
        final (da, w, h) = await pixels('$folder/$a');
        final (db, _, _) = await pixels('$folder/$b');
        var sum = 0;
        var n = 0;
        for (var i = 0; i < w * h; i += 13) {
          for (var c = 0; c < 3; c++) {
            sum += (da.getUint8(i * 4 + c) - db.getUint8(i * 4 + c)).abs();
          }
          n += 3;
        }
        return sum / n;
      }

      for (final lit in lightScene.lit.values) {
        expect(await difference('stage_base.png', lit.split('/').last), lessThan(25), reason: '$lit: the same stage');
      }
      for (final b in railScene.backdrops.where((b) => b.id != 'clockRed')) {
        expect(await difference('backdrop_clock_red.png', b.file.split('/').last), lessThan(20), reason: '${b.id}: the same painting');
      }
      expect(await difference('light_table_off.png', 'light_table_on.png'), lessThan(60), reason: 'the same table');
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

      // FILE 3: its words on its paper; the patch over CURTAIN UP's time;
      // the old time under it, the new one on it.
      final r = tableScene.file3;
      for (final row in r.rows) {
        expect(within(px(r.pixels), row.labelAt) && within(px(r.pixels), row.timeAt), isTrue, reason: row.id.name);
        expect(row.labelAt.overlaps(row.timeAt), isFalse, reason: row.id.name);
      }
      apart([for (final row in r.rows) row.labelAt], 'line');
      expect(within(r.patch.at, r.patch.newAt) && within(r.patch.at, r.patch.oldAt), isTrue);
      expect(r.patch.oldAt.bottom, lessThanOrEqualTo(r.patch.newAt.top + 0.01), reason: 'the old time shows through above the new one');
      expect(r.patch.newAt, r.row(RecordSpot.patch).timeAt, reason: 'the new time on its line, beside CURTAIN UP');
      expect((r.patch.newAt.top, r.patch.newAt.bottom), (r.row(RecordSpot.patch).labelAt.top, r.row(RecordSpot.patch).labelAt.bottom), reason: 'one baseline with its words');
      expect(within(px(r.patch.pixels), r.patch.paper), isTrue);
      expect(r.photoAt.overlaps(r.row(RecordSpot.down).labelAt), isFalse);
      // The pins' places on the close-up, finger-sized on a 360 phone.
      for (final p in tableScene.pins) {
        expect(within(tableScene.closeUp, p.area), isTrue, reason: p.spot.name);
        expect(p.area.contains(p.at), isTrue, reason: p.spot.name);
        // The final's page, its sheet and the glass round FILE 3.
        expect(p.area.height * (360 - 2 * 24 - 2 * (8 + 1) - 2 * 6) / tableScene.closeUp.width, greaterThanOrEqualTo(44), reason: '${p.spot.name}: finger-sized');
      }
      apart([for (final p in tableScene.pins) p.area], 'pin spot');
      expect(tableScene.pin(RecordSpot.patch).area.contains(r.patch.newAt.center), isTrue);
      expect(tableScene.pin(RecordSpot.under).area.contains(r.patch.oldAt.center), isTrue);
      expect(tableScene.pin(RecordSpot.doors).area.contains(r.row(RecordSpot.doors).timeAt.center), isTrue);
      expect(tableScene.pin(RecordSpot.down).area.contains(r.row(RecordSpot.down).timeAt.center), isTrue);
      // The slip: its times where its pins stand.
      final slip = tableScene.slip;
      for (final at in [slip.headerAt, slip.linesAt, slip.changeAt, slip.oldAt, slip.newAt, slip.stampAt, slip.back.sketchAt, slip.back.noteAt]) {
        expect(within(slip.paper, at), isTrue, reason: '$at');
      }
      apart([slip.changeAt, slip.oldAt, slip.newAt, slip.stampAt], 'slip');
      expect(within(px(slip.back.sketchPixels), slip.back.signAt), isTrue);
      // M2: the desk's slots and plates; the cue card and the scrap in the book.
      for (final s in lightScene.slots) {
        expect(within(lightScene.deskPaper, s.slot) && within(lightScene.deskPaper, s.plate), isTrue, reason: s.light.name);
      }
      expect([for (final s in lightScene.slots) s.light], StageLight.values);
      expect(within(px(lightScene.book.pixels), lightScene.cueOnPage), isTrue);
      expect(within(px(lightScene.book.pixels), lightScene.scrapAt), isTrue);
      expect(lightScene.cueOnPage.width / lightScene.cueOnPage.height, closeTo(lightScene.cue.pixels.aspect, 0.02), reason: 'the card never stretched');
      // M3: the stage's opening, the rail's four ropes, the pocket.
      expect(within(railScene.stageView, railScene.opening), isTrue);
      expect(railScene.ropeX, hasLength(rail.ropes.length));
      for (final (i, x) in railScene.ropeX.indexed) {
        expect(railScene.plates[i].left < x && x < railScene.plates[i].right, isTrue, reason: 'rope ${i + 1} under its card');
        expect(railScene.railView.left < x - 100 && x + 100 < railScene.railView.right, isTrue);
      }
      expect(within(px(railScene.backPixels), railScene.pocket), isTrue);
      expect(within(railScene.canvas, railScene.closer), isTrue);
      // Final: the label on the box, the glass and the switch.
      expect(within(tableScene.archiveView, tableScene.labelAt), isTrue);
      expect(within(px(tableScene.tablePixels), tableScene.glass) && within(px(tableScene.tablePixels), tableScene.switchAt), isTrue);
      expect(tableScene.glass.overlaps(tableScene.switchAt), isFalse);
    });

    test("a red thread comes to each pin through blank paper, never over FILE 3's words", () {
      final r = tableScene.file3;
      final words = [
        r.titleAt,
        for (final row in r.rows) ...[row.labelAt, if (row.id != RecordSpot.patch) row.timeAt],
        r.patch.newAt,
        r.patch.oldAt,
      ];
      bool crosses(Offset a, Offset b, Rect box) {
        for (var i = 0; i <= 40; i++) {
          if (box.contains(Offset.lerp(a, b, i / 40)!)) return true;
        }
        return false;
      }

      for (final MapEntry(key: pin, value: spot) in ChangedRecord.homes.entries) {
        final p = tableScene.pin(spot);
        final way = p.threadOn(tableScene.closeUp.left);
        expect(way.first.dx, tableScene.closeUp.left, reason: '$pin: in from the edge of the paper');
        expect(way.last, p.at, reason: '$pin: it ends on its pin');
        expect(p.area.contains(p.at), isTrue, reason: '$pin: the pin where it is tapped');
        for (var i = 0; i < way.length - 1; i++) {
          // The last few pixels reach the pin at the edge of its time.
          final b = i == way.length - 2 ? Offset.lerp(way[i], way[i + 1], 0.9)! : way[i + 1];
          for (final box in words) {
            expect(crosses(way[i], b, box.deflate(2)), isFalse, reason: '$pin: run $i crosses $box');
          }
        }
      }
    });

    test('the photo is the stage with the ghost light alone, as the rules say', () {
      expect(lightScene.photo.stage, lightScene.lit[StageLight.ghost]);
      expect(board.photo, {StageLight.ghost});
    });
  });

  group('in the game', () {
    test('Case 07 is in the game, after Case 06, at the Palais Garnier, with its four puzzles', () {
      expect(SeasonCatalog.byId(SeasonIds.paris)!.episodes.keys, ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05', 's2_ep06', 's2_ep07']);
      expect(season2AwaitingArtJson, isEmpty);
      expect(SeasonCatalog.isAwaitingArt('s2_ep07'), isFalse);
      expect(const MockEpisodeRepository().fetchEpisode('s2_ep07'), completes);
      expect(case07.number, 7);
      expect(case07.seasonId, SeasonIds.paris);
      expect(case07.title, 'The Phantom Performance');
      expect(case07.place, 'PALAIS GARNIER');
      expect([for (final m in case07.allMissions) m.id], ['s2_ep07_m1', 's2_ep07_m2', 's2_ep07_m3', 's2_ep07_final']);
      expect([for (final m in case07.allMissions) m.location], ['THE ARCHIVE TABLE', 'THE LIGHTING DESK', 'THE ROPE RAIL', 'THE ARCHIVE LIGHT TABLE']);
      expect([for (final m in case07.allMissions) m.evidence!.name], ['The Office Record', 'The Stage Cue Card', 'The Amendment Slip', 'The Changed Record']);
      expect([for (final m in case07.missions) m.clue!.title], ['Two Start Times', 'An Empty Stage', 'A Hidden Pocket']);
      expect(ParisLandmark.cases['s2_ep07'], ParisLandmark.palaisGarnier);
      expect(case07.introScene, Artwork.palaisGarnierNight);
      expect([for (final m in case07.allMissions) m.scene], [Artwork.operaArchive, Artwork.operaStage, Artwork.flyRail, Artwork.lightTable]);
      expect(SeasonCatalog.showStrip(m1)?.strip, same(strip));
      expect(SeasonCatalog.lightBoard(m2)?.board, same(board));
      expect(SeasonCatalog.flyRail(m3)?.rail, same(rail));
      expect(SeasonCatalog.lightTable(fin)?.record, same(record));
      for (final m in case07.allMissions) {
        expect(SeasonCatalog.storyScenes(m)?.after, isNotNull, reason: m.id);
        expect(SeasonCatalog.evidenceArt(m.evidence!.id), isA<DrawnEvidenceArt>(), reason: m.id);
      }
    });

    test('its Discovery Moments name what each mission found', () {
      expect(season2DiscoveryTypes['s2_ep07_m1'], DiscoveryType.deduction);
      expect(season2DiscoveryTypes['s2_ep07_m2'], DiscoveryType.evidenceFound);
      expect(season2DiscoveryTypes['s2_ep07_m3'], DiscoveryType.evidenceFound);
      for (final m in case07.missions) {
        expect(SeasonCatalog.discovery(m).title, m.successMessage, reason: m.id);
      }
    });

    test("Case 07's Case Closed tells Case 08's title, and nothing else of it", () {
      final season = SeasonCatalog.byId(SeasonIds.paris)!.season;
      expect(season.upcomingTitles, {8: "The Painter's Last Sketch"});
      expect(File('docs/SEASON2_PARIS_STORY_BIBLE.md').readAsStringSync(), contains("| 08 | **The Painter's Last Sketch** | Montmartre / Abbesses |"));
      expect(case07.hook, 'What did P. see — and what was in the bag?');
      expect(case06.hook, 'What is in File 3–4 of the opera archive?', reason: 'Case 06 is as it was');
    });
  });

  group('its story and puzzles', () {
    test("it opens on Case 06's letter: OPERA ARCHIVE · FILE 3–4", () {
      expect(case07.intro, contains('On its back: OPERA ARCHIVE · FILE 3–4.'));
      expect(case07.intro.last, 'One box on the table says: FILE 3–4.');
      expect(season2LetterMapsBack(), ['OPERA ARCHIVE', 'FILE 3–4']);
      expect(tableScene.label, 'FILE 3–4');
      expect(SeasonCatalog.evidenceLink('s2_ep07_e1')!.to, 's2_ep06_e4');
    });

    test('M1: the show is 2 hours 10 minutes; in after 3:30 and down at 6:10, it starts only at 4:00', () {
      expect(strip.length, 130);
      expect([for (final p in strip.parts) (p.name, p.minutes)], [('OVERTURE', 10), ('ACT ONE', 60), ('INTERVAL', 20), ('ACT TWO', 40)]);
      expect((strip.doorsOpen, strip.officeStart, strip.curtainDown), (pm(3, 30), pm(3), pm(6, 10)));
      expect((strip.from, strip.to, strip.earliest, strip.latest, strip.step, strip.initial), (pm(2, 30), pm(6, 30), pm(2, 30), pm(4, 20), 10, pm(3)));
      expect(strip.endOf(strip.latest), strip.to, reason: 'the strip never leaves the clock');
      expect(strip.starts, hasLength(12));
      expect(strip.fitting, [pm(4)]);
      expect(strip.endOf(pm(3)), pm(5, 10), reason: '"it would end at 5:10, not 6:10"');
      for (final s in strip.starts) {
        final v = strip.verdict(s);
        if (s == pm(3)) {
          expect(v, StripVerdict.office);
        } else if (s <= pm(3, 30)) {
          expect(v, StripVerdict.early, reason: clockOf(s));
        } else if (s != pm(4)) {
          expect(v, StripVerdict.end, reason: clockOf(s));
        } else {
          expect(v, StripVerdict.fit);
        }
      }
      // The edges: the doors' own time is still too early; ten minutes
      // after it the audience is in.
      expect(strip.verdict(pm(3, 30)), StripVerdict.early);
      expect(strip.verdict(pm(3, 40)), StripVerdict.end);
      expect(strip.verdict(pm(2, 30)), StripVerdict.early);
      expect(strip.verdict(pm(4, 20)), StripVerdict.end);
      expect(strip.snap(pm(4) + 4), pm(4));
      expect(strip.snap(pm(4) + 6), pm(4, 10));
      expect(strip.snap(pm(1)), strip.earliest);
      expect(strip.snap(pm(9)), strip.latest);
      expect({for (final o in m1.options) o.id}, {for (final v in StripVerdict.values) v.name});
      expect(m1.answer, StripVerdict.fit.name);
      String feedback(StripVerdict v) => AnswerChecker.feedbackFor(m1, v.name)!;
      expect(feedback(StripVerdict.office), "That's the office's 3:00. The doors open at 3:30. Nobody is in the seats yet!");
      expect(feedback(StripVerdict.early), 'The doors are not open yet. Who is watching the show?');
      expect(feedback(StripVerdict.end), 'The audience is in. Now look at the END flag. Is it at CURTAIN DOWN?');
      expect(AnswerChecker.isCorrect(m1, 'fit'), isTrue);
      expect(m1.hints, ["The show strip can't get shorter or longer.", 'Put the END flag on the CURTAIN DOWN pin.']);
      expect(stripScene.task, 'Slide the show. The audience must be in first. The show must end at CURTAIN DOWN.');
      // FILE 4 says no start time.
      expect([...stripScene.programme.title, stripScene.programme.whole].join(' '), isNot(matches(RegExp(r'\d:\d\d'))));
      expect(m1.successMessage, 'It fits at 4:00!');
      expect(m1.transition.last, "Is that true? Let's look at the stage.");
    });

    test('M2: of the sixteen settings of the levers, only the ghost light alone matches the photo', () {
      final settings = LightBoard.settings;
      expect(settings, hasLength(16));
      expect([for (final s in settings) if (board.verdict(s) == LightBoard.matchId) s], [
        {StageLight.ghost},
      ]);
      // The first light that differs, in the desk's order.
      expect(board.verdict({}), 'ghostOff');
      expect(board.verdict({StageLight.house, StageLight.foot}), 'ghostOff');
      expect(board.verdict({StageLight.ghost, StageLight.house, StageLight.spot}), 'house');
      expect(board.verdict({StageLight.ghost, StageLight.foot, StageLight.spot}), 'foot');
      expect(board.verdict({StageLight.ghost, StageLight.spot}), 'spot');
      for (final s in settings) {
        expect({for (final o in m2.options) o.id}, contains(board.verdict(s)));
      }
      expect(m2.answer, LightBoard.matchId);
      expect(AnswerChecker.feedbackFor(m2, 'ghostOff'), 'Look at the middle of the photo. One small lamp is glowing.');
      expect(AnswerChecker.feedbackFor(m2, 'house'), 'In the photo, the seats are dark.');
      expect(AnswerChecker.feedbackFor(m2, 'foot'), 'In the photo, the front of the stage is dark.');
      expect(AnswerChecker.feedbackFor(m2, 'spot'), 'Do you see a big circle of light in the photo?');
      expect(m2.question, 'Light the stage like the old photo.');
      expect(lightScene.photo.caption, '3:00 PM · CURTAIN UP!');
      expect(m2.letter, contains('GHOST LIGHT: one lamp on an empty stage.'));
      expect(lightScene.cue.heading, 'SHOW No. 34');
      expect(lightScene.cue.lines, ['CUE 1 · CURTAIN UP', '4:00']);
      // The photo proves an empty stage, not when it was taken.
      expect(m2.clue!.note, isNot(contains('4:00')));
      expect(m2.transition, containsAll(['The photo shows an empty stage, not a performance.', 'CUE 1 · CURTAIN UP · 4:00.']));
      expect(m2.transition.last, 'Where have you seen that before?');
      expect(m2.successMessage, 'It matches! Only the ghost light.');
    });

    test("M3: of four backdrops, only one has the Painted Street's small clock right above a red door; each other misses one thing", () {
      expect(rail.door, DoorColour.red);
      expect(rail.above, AboveDoor.smallClock);
      expect(m3.letter, 'Above the red door: a small clock.');
      expect(railScene.clueLine, m3.letter);
      expect(case06Inscription(), contains('Above the red door: a small clock.'));
      expect([for (final b in rail.ropes) b.id], ['lampRed', 'towerRed', 'clockRed', 'clockBlue']);
      expect([for (final b in rail.matching) b.id], [m3.answer]);
      expect(rail.ropes.indexWhere((b) => b.id == m3.answer), 2, reason: 'on rope 3');
      for (final b in rail.ropes.where((b) => b.id != m3.answer)) {
        expect(rail.misses(b), 1, reason: b.id);
      }
      expect(rail.backdrop('towerRed').tower, isTrue);
      expect(rail.backdrop('towerRed').above, AboveDoor.nothing);
      expect({for (final b in rail.ropes) b.id}, {for (final o in m3.options) o.id});
      expect({for (final b in railScene.backdrops) b.id}, {for (final b in rail.ropes) b.id});
      expect(AnswerChecker.feedbackFor(m3, 'lampRed'), 'There is a red door. But what is above it? Look closer.');
      expect(AnswerChecker.feedbackFor(m3, 'clockBlue'), 'There is a small clock. But what color is the door?');
      expect(AnswerChecker.feedbackFor(m3, 'towerRed'), 'That clock is big, and far from the door. Look right above the door.');
      // The option names never give the answer away: the ropes' numbers only.
      expect([for (final o in m3.options) o.label], ['Backdrop 1', 'Backdrop 2', 'Backdrop 3', 'Backdrop 4']);
      expect(railScene.slip.words, ['FILE 3', 'PERFORMANCE No. 34', 'CURTAIN UP: 4:00 to 3:00']);
      expect(m3.evidence!.inscription, endsWith('No name.'));
      expect(m3.transition, contains("Did P. paint this? We can't be sure."));
      expect(m3.transition.last, 'It says to change the record. But was FILE 3 really changed?');
      expect(SeasonCatalog.evidenceLink('s2_ep07_e3')!.to, 's2_ep02_e1');
    });

    test('Final: FILE 3 was changed; the slip pinned old time to under the patch, new time to the patch', () {
      expect(record.files, ['file3', 'file4']);
      expect(record.changed, 'file3');
      expect((record.oldTime, record.newTime), (pm(4), pm(3)));
      expect(ChangedRecord.answer, fin.answer);
      expect(fin.answer, 'old:under,new:patch');
      expect(fin.type, MissionType.matchPairs);
      expect(AnswerChecker.isCorrect(fin, fin.answer), isTrue);
      expect(AnswerChecker.isCorrect(fin, 'new:patch,old:under'), isTrue, reason: 'in any order');
      expect(AnswerChecker.isCorrect(fin, 'old:under'), isFalse, reason: 'both pins');
      expect(AnswerChecker.feedbackFor(fin, ChangedRecord.pickPart('file4')), 'The programme and the stage cue card agree on 4:00. Look at the other one.');
      // The old time under the patch is seen only with the light on.
      expect(ChangedRecord.spots(lit: false), isNot(contains(RecordSpot.under)));
      expect(ChangedRecord.spots(lit: true), RecordSpot.values);
      for (final pin in ChangedRecord.homes.keys) {
        for (final lit in [false, true]) {
          for (final spot in ChangedRecord.spots(lit: lit)) {
            final part = ChangedRecord.partOf(pin, spot, lit: lit);
            if (ChangedRecord.fits(pin, spot)) {
              expect(Mission.sequenceIds(fin.answer), contains(part));
            } else {
              expect(AnswerChecker.feedbackFor(fin, part), isNotNull, reason: part);
            }
          }
        }
      }
      expect(ChangedRecord.partOf('old', RecordSpot.patch, lit: false), 'old:unlit');
      expect(AnswerChecker.feedbackFor(fin, 'old:unlit'), 'Turn on the light first. What is under the patch?');
      expect(AnswerChecker.feedbackFor(fin, 'old:patch'), "That's the new time on top. Where is the old one?");
      expect(AnswerChecker.feedbackFor(fin, 'old:doors'), 'No extra paper on this line. Look for the patch.');
      expect(AnswerChecker.feedbackFor(fin, 'new:down'), 'No extra paper on this line. Look for the patch.');
      // FILE 3 on the light table: 3:00 on the patch, 4:00 under it; the
      // doors and the curtain down as they were.
      final r = tableScene.file3;
      expect((r.patch.newTime, r.patch.oldTime), ('3:00 PM', '4:00 PM'));
      expect([for (final row in r.rows) '${row.label} ${row.time}'], ['DOORS OPEN · 3:30 PM', 'CURTAIN UP · 3:00 PM', 'CURTAIN DOWN · 6:10 PM']);
      expect(fin.question, 'Which record was changed?');
      expect([tableScene.lightTask, tableScene.pinTask], ['Turn on the light. Look at each line.', 'Pin the slip to the change.']);
      expect(fin.successMessage, 'The record was changed!');
      // After the case: the slip's back leads to Case 08.
      expect(tableScene.slip.back.sign, 'ABBESSES');
      expect(tableScene.slip.back.note, 'P. KNEW THE BAG.');
      expect(fin.transition, containsAll(['Under it: P. KNEW THE BAG.', '3:00 and 4:00 again, like the notices at the Eiffel Tower.', "Is it the same hand? We don't know yet."]));
      expect(fin.transition.last, 'The mystery continues in Montmartre!');
      expect(fin.evidence!.inscription, endsWith('Who changed it, and why, is not known.'));
      expect(SeasonCatalog.evidenceLink('s2_ep07_e4')!.to, 's2_ep07_e3');
    });

    test('nothing is told before its time; who changed the record, any name behind it, and time itself vanishing, never', () {
      // Before M2 is solved: no ghost light's verdict, no cue card's 4:00.
      expect(beforeSolved(m2).toLowerCase(), isNot(contains('cue card')));
      // Before M3 is solved: no slip, no pocket.
      final beforeM3 = [everything([m1, m2]), beforeSolved(m3)].join('\n').toLowerCase();
      for (final secret in ['pocket', 'slip', '4:00 to 3:00']) {
        expect(beforeM3, isNot(contains(secret)), reason: secret);
      }
      // Before the case is closed: nothing of Abbesses or the bag.
      final beforeEnd = [everything([m1, m2, m3]), ...case07.intro, ...case07.synopsis, ...case07.objectives, beforeSolved(fin)].join('\n').toUpperCase();
      for (final secret in ['ABBESSES', 'BAG', 'PHANTOM']) {
        expect(beforeEnd, isNot(contains(secret)), reason: secret);
      }
      // M1 never says the record was changed.
      expect(everything([m1]).toLowerCase(), isNot(contains('changed')));
      final all = [everything(case07.allMissions, e: case07), File('lib/data/mock/season2/season2_case07_scenes.dart').readAsStringSync()].join('\n').toUpperCase();
      for (final banned in ['VICTOR', 'DELACROIX', 'ÉMILE', 'EMILE', 'CLOCKMAKER', 'THIEF', 'V.D.', 'RECORD WAS REMOVED', 'TIME VANISHED', 'HOUR VANISHED', 'P. PAINTED', 'P. HID']) {
        expect(all, isNot(contains(banned)), reason: banned);
      }
    });

    test('its English is short: one idea a sentence', () {
      for (final m in case07.allMissions) {
        for (final line in [...m.story, ...m.transition, ...m.hints, ...m.letter.split('\n')]) {
          for (final sentence in line.split(RegExp(r'(?<=[.!?])\s+'))) {
            expect(sentence.split(' ').length, lessThanOrEqualTo(12), reason: '${m.id}: $sentence');
          }
        }
      }
    });

    test('every word in its glossary is in its text', () {
      final text = [
        everything(case07.allMissions, e: case07),
        stripScene.task,
        lightScene.task,
        railScene.task,
        tableScene.lightTask,
        tableScene.pinTask,
      ].join('\n').toLowerCase();
      for (final w in case07.glossary.keys) {
        expect(text, contains(w), reason: w);
      }
    });

    test("its learning design follows Season 1's rules", () {
      String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      String screen(Mission m) => norm([...m.story, m.letterIntro, m.letter, m.question, for (final o in m.options) o.label, ...m.hints].join(' \n '));
      expect(season2Learning.keys.where((id) => id.startsWith('s2_ep07_')).toSet(), {for (final m in case07.allMissions) m.id});
      expect(season2LanguageTopics['s2_ep07'], isNotNull);
      for (final m in case07.allMissions) {
        final l = SeasonCatalog.learning(m)!;
        expect(l.isHonest, isTrue, reason: m.id);
        if (l.dependency == LanguageDependency.essential) expect(l.expressions, isNotEmpty);
        for (final e in l.expressions) {
          expect(screen(m), contains(norm(e)), reason: '${m.id}: "$e" is on its screens');
        }
      }
    });

    test('its evidence leads on from Case 06 and Case 02, one piece to the next', () {
      expect(SeasonCatalog.evidenceLink('s2_ep07_e2')!.to, 's2_ep07_e1');
      expect(SeasonCatalog.evidenceLink('s2_ep06_e4')!.to, 's2_ep06_e3', reason: "Case 06's links are as they were");
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

    test('it opens only once Case 06 is solved', () async {
      final c = await start();
      final game = c.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      for (final e in paris.take(5)) {
        solve(c, e);
      }
      expect(game.openEpisode('s2_ep07'), isFalse, reason: 'no way round Case 06');
      expect(c.read(seasonProvider.notifier).isUnlocked('s2_ep07'), isFalse);
      solve(c, case06);
      expect(c.read(seasonProvider.notifier).isUnlocked('s2_ep07'), isTrue);
      expect(c.read(seasonOverviewProvider).comingSoonCase, isNot(7), reason: 'Case 07 is open now');
      expect(game.openEpisode('s2_ep07'), isTrue);
      expect(c.read(currentEpisodeProvider).id, 's2_ep07');
    });

    test('what is looked at, lowered, chosen, lit and pinned is saved and comes back after a restart', () async {
      var c = await start();
      var game = c.read(gameControllerProvider.notifier);
      game.openSeason(SeasonIds.paris);
      for (final e in paris) {
        solve(c, e);
      }
      game.openEpisode('s2_ep07');
      game.startInvestigation();
      expect(game.submitAnswer(m1, 'office').result, SubmitResult.tryAgain);
      expect(game.submitAnswer(m2, m2.answer).result, SubmitResult.locked, reason: 'missions in order');
      expect(game.submitAnswer(m1, m1.answer).result, SubmitResult.correct);
      game.recordExamined(GameProgress.examinedKey(m2.id, LightBoard.photoId));
      expect(game.submitAnswer(m2, 'house').result, SubmitResult.tryAgain);
      expect(game.submitAnswer(m2, m2.answer).result, SubmitResult.correct);
      game.recordExamined(GameProgress.examinedKey(m2.id, LightBoard.cueId));
      game.recordExamined(GameProgress.examinedKey(m3.id, FlyRail.loweredKey('lampRed')));

      c.dispose();
      c = await start();
      game = c.read(gameControllerProvider.notifier);
      expect(c.read(currentEpisodeProvider).id, 's2_ep07');
      var p = c.read(gameControllerProvider);
      expect(p.isCompleted(m1.id) && p.isCompleted(m2.id), isTrue);
      expect((p.wrongCount(m1.id), p.wrongCount(m2.id)), (1, 1));
      expect(p.hasExamined('${m2.id}:photo') && p.hasExamined('${m2.id}:cue'), isTrue);
      expect(p.hasExamined('${m2.id}:scrap'), isFalse, reason: 'the scrap is found again');
      expect(p.hasExamined('${m3.id}:backdrop-lampRed'), isTrue);
      expect(game.submitAnswer(m3, 'lampRed').result, SubmitResult.tryAgain);
      expect(game.submitAnswer(m3, m3.answer).result, SubmitResult.correct);
      game.recordExamined(GameProgress.examinedKey(m3.id, FlyRail.pocketId));
      expect(game.submitAnswer(fin, ChangedRecord.pickPart('file4')).result, SubmitResult.tryAgain);
      for (final k in [ChangedRecord.chosenId, ChangedRecord.placedId, ChangedRecord.litId, ChangedRecord.pinnedKey('old')]) {
        game.recordExamined(GameProgress.examinedKey(fin.id, k));
      }

      c.dispose();
      c = await start();
      game = c.read(gameControllerProvider.notifier);
      p = c.read(gameControllerProvider);
      for (final k in ['file3', 'placed', 'lit', 'pin-old']) {
        expect(p.hasExamined('${fin.id}:$k'), isTrue, reason: k);
      }
      expect(p.hasExamined('${fin.id}:pin-new'), isFalse);
      expect(game.submitAnswer(fin, 'new:under').result, SubmitResult.tryAgain);
      expect(game.submitAnswer(fin, fin.answer).result, SubmitResult.correct);
      p = c.read(gameControllerProvider);
      expect([for (final e in p.collectedEvidence(case07)) e.name], ['The Office Record', 'The Stage Cue Card', 'The Amendment Slip', 'The Changed Record']);
      expect(p.isCaseSolved, isTrue);
      expect(c.read(progressRepositoryProvider).load('s2_ep06').isCaseSolved, isTrue, reason: "Case 06's save is its own");
      expect(c.read(progressRepositoryProvider).load('s2_ep06').examined.any((k) => k.startsWith('s2_ep07')), isFalse);
    });

    test('solved: Paris is 7 of 12, Case 08 is coming soon, nothing opens it; London is as it was', () async {
      final c = await start();
      final game = c.read(gameControllerProvider.notifier);
      game.openSeason(SeasonIds.paris);
      for (final e in [...paris, case07]) {
        solve(c, e);
      }
      final board = c.read(seasonOverviewProvider);
      expect(board.solvedCount, 7);
      expect(board.comingSoonCase, 8);
      final available = c.read(seasonAvailabilityProvider(SeasonIds.paris))!;
      expect((available.solvedCount, available.plannedCount), (7, 12));
      expect(game.openEpisode('s2_ep08'), isFalse, reason: 'no Case 08 to open');
      expect(c.read(progressRepositoryProvider).loadSeason(SeasonIds.london).solvedEpisodeIds, hasLength(12));
    });
  });

  group('a child plays Case 07', () {
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
      testWidgets('$tag: Case 06 closed → strip → lights, cue and scrap → ropes and pocket → light table and pins, 7 of 12', (t) async {
        final ref = await open(t, size);
        final router = ref.read(routerProvider);
        final game = ref.read(gameControllerProvider.notifier);

        var n = 0;
        Future<void> shot(String name) async {
          expect(t.takeException(), isNull, reason: '$tag $name: no overflow, no error');
          if (shots == null) return;
          // Every picture decoded (the stage's lights are decoded by the
          // stage itself), then drawn.
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
            File('$shots/paris07_${tag}_${(n++).toString().padLeft(2, '0')}_$name.png').writeAsBytesSync(png!.buffer.asUint8List());
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
        void finger(String key) {
          final r = t.getRect(find.byKey(ValueKey(key)));
          expect(r.width >= 44 && r.height >= 44, isTrue, reason: '$tag $key: finger-sized ($r)');
        }

        // ── Case 06's Case Closed: on to Case 07 ────────────────────────
        router.go(Routes.solvedSettled);
        await wait(t, const Duration(milliseconds: 3000));
        await reveal(t, find.text('OPEN CASE 07'));
        expect(find.text('OPEN CASE 07'), findsOneWidget, reason: 'Case 07 is in the game now');
        await shot('case06_closed');
        expect(game.openEpisode('s2_ep07'), isTrue);

        // ── The opening ─────────────────────────────────────────────────
        router.go(Routes.intro);
        await wait(t, const Duration(milliseconds: 900));
        await tapText(t, 'SKIP ›', after: const Duration(milliseconds: 900));
        await shot('opening');
        await tapText(t, "I'M READY", after: const Duration(milliseconds: 1600));

        // ── M1: the show strip ──────────────────────────────────────────
        await visit(m1.id);
        expect(find.byKey(const ValueKey('story-picture')), findsOneWidget, reason: 'the archive');
        await shot('m1_place');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('strip-task')), findsOneWidget);
        expect(find.byKey(const ValueKey('pin-doors')), findsOneWidget);
        expect(find.byKey(const ValueKey('pin-down')), findsOneWidget);
        expect(find.byKey(const ValueKey('pin-office')), findsOneWidget);
        String readout() => t.widget<Text>(find.byKey(const ValueKey('strip-readout'))).textSpan!.toPlainText();
        expect(readout(), contains('START 3:00 PM'));
        expect(readout(), contains('END 5:10 PM'));
        await reveal(t, find.byKey(const ValueKey('strip-check')));
        await shot('m1_strip');
        // The strip, its flags and the clock's pins: all on screen.
        final timeline = t.getRect(find.byKey(const ValueKey('strip-timeline')));
        for (final k in ['flag-start', 'flag-end', 'pin-doors', 'pin-down', 'pin-office']) {
          final r = t.getRect(find.byKey(ValueKey(k)));
          expect(r.left >= timeline.left - 0.5 && r.right <= timeline.right + 0.5, isTrue, reason: '$tag $k inside ($r)');
          expect(r.left >= 0 && r.right <= size.width, isTrue, reason: '$tag $k on screen');
        }
        finger('strip-earlier');
        finger('strip-later');
        // FILE 3 read closer.
        await tapKey('paper-file3', after: const Duration(milliseconds: 500));
        expect(find.text('CURTAIN DOWN ·'), findsWidgets);
        await shot('m1_file3');
        await tapKey('paper-done', after: const Duration(milliseconds: 400));
        await tapKey('strip-check');
        await wrongThenTryAgain("That's the office's 3:00.", 'm1_office');
        // Dragged right six steps: 4:00 (the pins of the clock in reach).
        final k = (timeline.width - 28) / (strip.to - strip.from);
        await reveal(t, find.byKey(const ValueKey('show-strip')));
        final from = t.getCenter(find.byKey(const ValueKey('show-strip')));
        final g = await t.startGesture(from);
        for (var i = 1; i <= 10; i++) {
          await g.moveTo(from + Offset(50 * k * i / 10, 0));
          await t.pump(const Duration(milliseconds: 16));
        }
        await g.up();
        await wait(t, const Duration(milliseconds: 300));
        expect(readout(), contains('START 3:50 PM'), reason: 'dragged five steps');
        await tapKey('strip-check');
        await wrongThenTryAgain('Now look at the END flag.', 'm1_end');
        await tapKey('strip-later', after: const Duration(milliseconds: 300));
        expect(readout(), contains('START 4:00 PM'));
        expect(readout(), contains('END 6:10 PM'));
        await shot('m1_fit');
        await tapKey('strip-check');
        await finish(m1.transition.first, 'm1');
        expect(ref.read(gameControllerProvider).isCompleted(m1.id), isTrue);

        // ── M2: the lighting desk ───────────────────────────────────────
        await visit(m2.id);
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.byType(LitStage), findsOneWidget);
        expect(find.byKey(const ValueKey('photo-caption')), findsOneWidget);
        for (final l in StageLight.values) {
          expect(t.widget<Text>(find.byKey(ValueKey('lever-state-${l.name}'))).data, 'OFF', reason: '${l.name}: off at first');
          finger('lever-tap-${l.name}');
        }
        await shot('m2_desk');
        await tapKey('old-photo', after: const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('photo-close')), findsOneWidget);
        expect(find.byKey(const ValueKey('photo-compare-stage')), findsOneWidget, reason: 'the photo beside the stage');
        expect(examined(), contains('s2_ep07_m2:photo'));
        await shot('m2_photo');
        await tapKey('photo-done', after: const Duration(milliseconds: 400));
        await tapKey('lighting-book', after: const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('book-close')), findsOneWidget);
        await shot('m2_book');
        await tapKey('book-done', after: const Duration(milliseconds: 400));
        await tapKey('lever-tap-house', after: const Duration(milliseconds: 400));
        await tapKey('lever-tap-ghost', after: const Duration(milliseconds: 400));
        expect(t.widget<LitStage>(find.byType(LitStage)).on, {StageLight.house, StageLight.ghost}, reason: 'two lights on together');
        await shot('m2_two_lights');
        await tapKey('lights-check');
        await wrongThenTryAgain('In the photo, the seats are dark.', 'm2_house');
        // A slide down turns the house lights off.
        await reveal(t, find.byKey(const ValueKey('lever-tap-house')));
        await t.drag(find.byKey(const ValueKey('lever-tap-house')), const Offset(0, 60));
        await wait(t, const Duration(milliseconds: 400));
        expect(t.widget<LitStage>(find.byType(LitStage)).on, {StageLight.ghost});
        await tapKey('lights-check');
        await wait(t, const Duration(milliseconds: 900));
        expect(ref.read(gameControllerProvider).isCompleted(m2.id), isTrue);
        // The cue card first, then the scrap; then on.
        expect(find.byKey(const ValueKey('book-page-34')), findsOneWidget);
        expect(find.byKey(const ValueKey('scrap')), findsNothing, reason: 'the cue card first');
        expect(t.widget<GameButton>(find.byKey(const ValueKey('cue-continue'))).onPressed, isNull);
        await shot('m2_page_34');
        await tapKey('cue-card', after: const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('cue-close')), findsOneWidget);
        expect(find.text('4:00'), findsWidgets);
        expect(examined(), contains('s2_ep07_m2:cue'));
        await shot('m2_cue_card');
        await tapKey('cue-done', after: const Duration(milliseconds: 700));
        await tapKey('scrap', after: const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('scrap-close')), findsOneWidget);
        expect(findReadable(lightScene.scrapLine), findsOneWidget);
        await shot('m2_scrap');
        await tapKey('scrap-done', after: const Duration(milliseconds: 400));
        await tapKey('cue-continue');
        expect(examined(), contains('s2_ep07_m2:scrap'));
        await finish(m2.transition.first, 'm2');

        // ── M3: the rope rail ───────────────────────────────────────────
        await visit(m3.id);
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('painted-street-clue')), findsOneWidget);
        expect(findReadable('Above the red door: a small clock.'), findsWidgets);
        expect(t.widget<GameButton>(find.byKey(const ValueKey('backdrop-choose'))).onPressed, isNull, reason: 'no backdrop down yet');
        for (var i = 1; i <= 4; i++) {
          finger('rope-$i');
        }
        await shot('m3_rail');
        await tapKey('rope-1', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('backdrop-lampRed')), findsOneWidget);
        expect(examined(), contains('s2_ep07_m3:backdrop-lampRed'));
        await shot('m3_backdrop_1');
        await tapKey('backdrop-down', after: const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('backdrop-close-lampRed')), findsOneWidget);
        expect(find.byKey(const ValueKey('backdrop-door')), findsOneWidget);
        await shot('m3_backdrop_1_closer');
        await tapKey('backdrop-choose-close', after: const Duration(milliseconds: 400));
        await wrongThenTryAgain('But what is above it?', 'm3_lamp');
        // A pull down on rope 2: the first goes up, the second comes down.
        await reveal(t, find.byKey(const ValueKey('rope-2')));
        await t.drag(find.byKey(const ValueKey('rope-2')), const Offset(0, 80));
        await wait(t, const Duration(milliseconds: 1300));
        expect(find.byKey(const ValueKey('backdrop-towerRed')), findsOneWidget);
        expect(find.byKey(const ValueKey('backdrop-lampRed')), findsNothing);
        await shot('m3_backdrop_2');
        await tapKey('rope-3', after: const Duration(milliseconds: 1300));
        expect(find.byKey(const ValueKey('backdrop-clockRed')), findsOneWidget);
        await shot('m3_backdrop_3');
        await tapKey('backdrop-choose', after: const Duration(milliseconds: 900));
        expect(ref.read(gameControllerProvider).isCompleted(m3.id), isTrue);
        expect(find.byKey(const ValueKey('backdrop-back')), findsOneWidget, reason: 'its back first');
        await shot('m3_back');
        await tapKey('pocket', after: const Duration(milliseconds: 800));
        expect(find.byKey(const ValueKey('pocket-slip')), findsOneWidget);
        expect(find.byKey(const ValueKey('slip-stamp')), findsOneWidget);
        expect(find.text('FILE 3'), findsWidgets);
        await shot('m3_slip');
        await tapKey('pocket-continue');
        expect(examined(), contains('s2_ep07_m3:pocket'));
        await finish(m3.transition.first, 'm3');

        // ── Final: the light table ──────────────────────────────────────
        router.go(Routes.finalMission);
        await wait(t, const Duration(milliseconds: 1600));
        expect(find.byKey(const ValueKey('record-stage')), findsOneWidget);
        expect(find.byKey(const ValueKey('box-label')), findsOneWidget);
        await shot('final_page');
        await tapKey('record-file4', after: const Duration(milliseconds: 300));
        await wrongThenTryAgain('agree on 4:00', 'final_file4');
        await tapKey('record-file3', after: const Duration(milliseconds: 600));
        expect(examined(), contains('s2_ep07_final:file3'));
        await reveal(t, find.byKey(const ValueKey('light-table')));
        await shot('final_table');
        // FILE 3 dragged onto the glass.
        final file3At = t.getCenter(find.byKey(const ValueKey('drag-file3')));
        final tableAt = t.getCenter(find.byKey(const ValueKey('light-table')));
        final d = await t.startGesture(file3At);
        for (var i = 1; i <= 12; i++) {
          await d.moveTo(Offset.lerp(file3At, tableAt, i / 12)!);
          await t.pump(const Duration(milliseconds: 16));
        }
        await d.up();
        await wait(t, const Duration(milliseconds: 600));
        expect(examined(), contains('s2_ep07_final:placed'));
        expect(find.byKey(const ValueKey('record-close-up')), findsOneWidget);
        expect(find.descendant(of: find.byKey(const ValueKey('record-close-up')), matching: find.byKey(const ValueKey('record-old-time'))), findsNothing, reason: 'the old time is not seen before the light');
        expect(find.byKey(const ValueKey('board-slip')), findsNothing, reason: 'the light first');
        await reveal(t, find.byKey(const ValueKey('light-switch')));
        await shot('final_unlit');
        await tapKey('light-switch', after: const Duration(milliseconds: 800));
        expect(examined(), contains('s2_ep07_final:lit'));
        expect(find.descendant(of: find.byKey(const ValueKey('record-close-up')), matching: find.byKey(const ValueKey('record-old-time'))), findsOneWidget, reason: 'the old time shows through');
        expect(find.descendant(of: find.byKey(const ValueKey('record-close-up')), matching: find.byKey(const ValueKey('patch-edge'))), findsOneWidget);
        expect(find.byKey(const ValueKey('board-slip')), findsOneWidget);
        finger('pin-old');
        finger('pin-new');
        await reveal(t, find.byKey(const ValueKey('record-close-up')));
        await shot('final_lit');
        // Where a place on FILE 3 is on screen now.
        Offset onRecord(RecordSpot s) {
          final at = t.getRect(find.byKey(const ValueKey('record-close-up')));
          return at.topLeft + (tableScene.pin(s).at - tableScene.closeUp.topLeft) * (at.width / tableScene.closeUp.width);
        }

        // The old time tapped onto the patch: that is the new time.
        await tapKey('pin-old', after: const Duration(milliseconds: 300));
        expect(findReadable('Now tap the line on FILE 3.'), findsOneWidget);
        await t.tapAt(onRecord(RecordSpot.patch));
        await wrongThenTryAgain("That's the new time on top.", 'final_old_on_patch');
        // The light off, the old time dropped on the patch: the light first.
        await tapKey('light-switch', after: const Duration(milliseconds: 700));
        await reveal(t, find.byKey(const ValueKey('pin-old')));
        Future<void> dragPin(String pin, RecordSpot to) async {
          final from = t.getCenter(find.byKey(ValueKey('pin-$pin')));
          final target = onRecord(to);
          final g = await t.startGesture(from);
          for (var i = 1; i <= 14; i++) {
            await g.moveTo(Offset.lerp(from, target, i / 14)!);
            await t.pump(const Duration(milliseconds: 16));
          }
          await g.up();
          await wait(t, const Duration(milliseconds: 400));
        }

        await dragPin('old', RecordSpot.patch);
        await wrongThenTryAgain('Turn on the light first.', 'final_unlit_pin');
        await tapKey('light-switch', after: const Duration(milliseconds: 700));
        await reveal(t, find.byKey(const ValueKey('pin-old')));
        await dragPin('old', RecordSpot.under);
        expect(examined(), contains('s2_ep07_final:pin-old'));
        await shot('final_old_pinned');
        await tapKey('pin-new', after: const Duration(milliseconds: 300));
        await t.tapAt(onRecord(RecordSpot.patch));
        await wait(t, const Duration(milliseconds: 3600));
        expect(ref.read(gameControllerProvider).isCaseSolved, isTrue);
        expect(findReadableContaining('The record was changed!'), findsWidgets);
        await shot('final_solved');
        // The slip turned over: Abbesses, and P. KNEW THE BAG.
        await tapKey('final-turn-slip', after: const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('slip-back')), findsOneWidget);
        expect(find.byKey(const ValueKey('slip-sign')), findsOneWidget);
        expect(find.byKey(const ValueKey('slip-sign-close')), findsOneWidget, reason: 'the metro sign up close, readable');
        expect(find.text('ABBESSES'), findsNWidgets(2));
        expect(find.text('P. KNEW THE BAG.'), findsOneWidget);
        await shot('final_slip_back');
        await tapKey('slip-back-done', after: const Duration(milliseconds: 500));
        expect(examined(), contains('s2_ep07_final:slip-back'));
        await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 900));
        expect(find.text(fin.transition.first), findsOneWidget);
        await t.tapAt(Offset(size.width / 2, size.height / 2));
        await wait(t, const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('scene-backdrop')), findsOneWidget, reason: 'the sketch');
        expect(findReadable('The mystery continues in Montmartre!'), findsOneWidget);
        await shot('final_scene');
        await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 4000));
        await reveal(t, find.byKey(const ValueKey('next-case-coming-soon')));
        expect(find.text("CASE 08 · THE PAINTER'S LAST SKETCH"), findsOneWidget);
        expect(find.text('COMING SOON'), findsOneWidget);
        await shot('case_closed');

        final board = ref.read(seasonOverviewProvider);
        expect(board.solvedCount, 7);
        expect(board.comingSoonCase, 8);
        expect(game.openEpisode('s2_ep08'), isFalse);
        await wait(t, const Duration(seconds: 3));
      });
    }

    testWidgets('back again after a restart: the cue card read, the backdrops lowered, the pins pressed in are as left', (t) async {
      final ref = await open(t, const Size(390, 844));
      final game = ref.read(gameControllerProvider.notifier);
      expect(game.openEpisode('s2_ep07'), isTrue);
      game.startInvestigation();
      game.submitAnswer(m1, m1.answer);
      // Solved, the cue card read, the scrap not yet found (a restart).
      game.markMissionStarted(m2.id);
      game.submitAnswer(m2, m2.answer);
      game.recordExamined(GameProgress.examinedKey(m2.id, LightBoard.cueId));
      final router = ref.read(routerProvider);
      router.go(Routes.mission(m2.id));
      await wait(t, const Duration(milliseconds: 1400));
      expect(find.byKey(const ValueKey('book-page-34')), findsOneWidget, reason: 'the page, not the solved file');
      expect(find.byKey(const ValueKey('scrap')), findsOneWidget, reason: 'the cue card was read: the scrap is there');
      expect(t.widget<GameButton>(find.byKey(const ValueKey('cue-continue'))).onPressed, isNull, reason: 'the scrap is found first');
      // M3: the backdrops lowered before have their tick.
      game.recordExamined(GameProgress.examinedKey(m2.id, LightBoard.scrapId));
      game.markMissionStarted(m3.id);
      game.recordExamined(GameProgress.examinedKey(m3.id, FlyRail.loweredKey('clockBlue')));
      router.go(Routes.map);
      await wait(t, const Duration(milliseconds: 1400));
      router.go(Routes.mission(m3.id));
      await wait(t, const Duration(milliseconds: 1400));
      expect(find.byKey(const ValueKey('rope-rail')), findsOneWidget, reason: 'started before: straight to the rail');
      expect(find.descendant(of: find.byKey(const ValueKey('rope-rail')), matching: find.byType(Row)), findsNWidgets(4));
      // The final: chosen, placed, lit and the old pin pressed in.
      game.submitAnswer(m3, m3.answer);
      game.recordExamined(GameProgress.examinedKey(m3.id, FlyRail.pocketId));
      for (final k in [ChangedRecord.chosenId, ChangedRecord.placedId, ChangedRecord.litId, ChangedRecord.pinnedKey('old')]) {
        game.recordExamined(GameProgress.examinedKey(fin.id, k));
      }
      router.go(Routes.finalMission);
      await wait(t, const Duration(milliseconds: 1600));
      expect(find.byKey(const ValueKey('record-close-up')), findsOneWidget, reason: 'FILE 3 on the glass');
      expect(find.descendant(of: find.byKey(const ValueKey('record-close-up')), matching: find.byKey(const ValueKey('record-old-time'))), findsOneWidget, reason: 'the light on again');
      expect(find.byKey(const ValueKey('board-slip')), findsOneWidget);
      expect(t.widget<Semantics>(find.descendant(of: find.byKey(const ValueKey('pin-old')), matching: find.byType(Semantics)).first).properties.label, contains('pinned'));
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 3));
    });
  });
}

/// The back of Case 06's letter, as its final shows it.
List<String> season2LetterMapsBack() => SeasonCatalog.letterMap(MockEpisodeRepository.bundled().firstWhere((e) => e.id == 's2_ep06').finalMission)!.letter.back;

/// What Case 02's Painted Street says.
String case06Inscription() => MockEpisodeRepository.bundled().firstWhere((e) => e.id == 's2_ep02').missions.first.evidence!.inscription!;
