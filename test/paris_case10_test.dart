import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
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
import 'package:london_mystery/data/mock/season2/season2_case10_scenes.dart';
import 'package:london_mystery/data/mock/season2/season2_discoveries.dart';
import 'package:london_mystery/data/mock/season2/season2_learning.dart';
import 'package:london_mystery/data/mock/season2/season2_mock.dart';
import 'package:london_mystery/data/mock/season_catalog.dart';
import 'package:london_mystery/data/models/abbesses_puzzles.dart' show TornHourScene;
import 'package:london_mystery/data/models/discovery.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/garden_puzzles.dart' show TowerTestScene;
import 'package:london_mystery/data/models/learning.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/river_puzzles.dart';
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/models/star_puzzles.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/mission/widgets/star_records.dart';
import 'package:london_mystery/features/mission_map/map_world.dart';
import 'package:london_mystery/features/season/season_overview.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/ink_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';

/// Season 2, Case 10 — The Hour of Shadows: its six pictures (as delivered,
/// the sundial's hour lines and the photo's clock faces where the scenes
/// say), its story and puzzles as the spec says them, its rules (unlock
/// after Case 09, saves, Case 11 coming soon), and a child playing it
/// through on three phones. Nothing is told before its time: what page 3
/// says, who sent it and why, why T1 went wrong, T2 and T3, and any name.
///
/// `LM_SHOTS=folder` saves a picture of each step of the play-through.
void main() {
  final inGame = MockEpisodeRepository.bundled();
  final s1 = season1Cases();
  final paris = [for (final id in ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05', 's2_ep06', 's2_ep07', 's2_ep08', 's2_ep09']) inGame.firstWhere((e) => e.id == id)];
  final case08 = paris[7];
  final case09 = paris.last;
  final case10 = inGame.firstWhere((e) => e.id == 's2_ep10');
  final [m1, m2, m3, fin] = case10.allMissions;
  final shots = Platform.environment['LM_SHOTS'];

  final tape = SeasonCatalog.drumTape(m1)!;
  final city = SeasonCatalog.cityClocks(m2)!;
  final shadow = SeasonCatalog.shadowCheck(m3)!;
  final record = SeasonCatalog.hourRecord(fin)!;
  final dial = shadow.sundial;

  final case08Lead = GameProgress.examinedKey(case08.finalMission.id, TornHourScene.leadId);
  final case09Star = GameProgress.examinedKey(case09.finalMission.id, TowerTestScene.leadId);
  final listKey = GameProgress.examinedKey(fin.id, HourRecordScene.leadId);
  final photoKey = GameProgress.examinedKey(fin.id, HourRecordScene.photoId);
  final pageKey = GameProgress.examinedKey(fin.id, HourRecordScene.pageId);

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

  String everything() => [
        ...case10.intro,
        ...case10.synopsis,
        ...case10.objectives,
        case10.hook,
        case10.caseSummary,
        for (final m in case10.allMissions) ...[
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
          m.successMessage,
          m.clue?.note ?? '',
          m.evidence?.description ?? '',
          m.evidence?.inscription ?? '',
        ],
        ...record.afterLines,
        ...record.foundLines,
        ...record.lead.doneLines,
        for (final l in record.lead.lines) l.text,
        ...city.sortedLines,
        for (final c in city.photo.clocks) c.wrongLine,
      ].join('\n');

  group('its pictures', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const folder = 'assets/seasons/season_02_paris/cases/case_10';
    // Size, and whether it has an alpha channel (as delivered, never
    // changed).
    const pictures = {
      'arc_star_view.png': (1536, 1024, false),
      'star_room.png': (1536, 1024, false),
      'record_drum.png': (1254, 1254, true),
      'roof_photo.png': (1536, 1024, false),
      'sundial_top.png': (1254, 1254, true),
      'trial_log_open.png': (1536, 1024, true),
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

    test('all six are in, listed in pubspec, at their sizes; no frame is borrowed', () {
      expect(pubspecAssets(), contains('$folder/'));
      expect(Directory(folder).listSync().whereType<File>().where((f) => f.path.endsWith('.png')).length, 6);
      for (final MapEntry(key: name, value: (w, h, alpha)) in pictures.entries) {
        final (pw, ph, a) = header(File('$folder/$name').readAsBytesSync());
        expect((pw, ph), (w, h), reason: name);
        expect(a, alpha, reason: name);
      }
      final code = [
        File('lib/data/mock/season2/season2_case10_scenes.dart').readAsStringSync(),
        File('lib/features/mission/widgets/star_records.dart').readAsStringSync(),
      ].join();
      expect(code, isNot(contains('photo_frame')), reason: 'the photo has its own worn edge: no second frame');
    });

    test("every one of them is played on; Case 10's places have their pictures", () {
      final scenes = [File('lib/data/mock/season2/season2_case10_scenes.dart').readAsStringSync(), File('lib/widgets/art_assets.dart').readAsStringSync()].join();
      for (final name in pictures.keys) {
        expect(scenes, contains(name), reason: name);
      }
      expect(ArtAssets.parisScenes[case10.introScene], '$folder/arc_star_view.png');
      for (final m in case10.allMissions) {
        expect(ArtAssets.parisScenes[m.scene], isNotNull, reason: m.id);
      }
      expect(missingAssets([tape.drumFile, city.photo.file, dial.file, record.logFile, record.room.file, record.lead.mapFile, SeasonCatalog.introPicture('s2_ep10')!.inset!.file]), isEmpty);
    });

    test('the cut-outs are clear round them', () async {
      for (final name in pictures.entries.where((e) => e.value.$3).map((e) => e.key)) {
        final (d, w, h) = await pixels('$folder/$name');
        int alphaAt(int x, int y) => d.getUint8((y * w + x) * 4 + 3);
        expect(alphaAt(2, 2), lessThan(4), reason: '$name: a clear corner');
        expect(alphaAt(w - 3, h - 3), lessThan(4), reason: name);
      }
    });

    test("the sundial's seven hour lines are where the data says, each darker than the plate beside it; the line down is no hour", () async {
      final (d, w, _) = await pixels('$folder/sundial_top.png');
      double light(double degrees) {
        final a = degrees * math.pi / 180;
        var sum = 0.0;
        var n = 0;
        for (var r = 200.0; r <= 450; r += 5) {
          final x = (dial.hub.dx + math.sin(a) * r).round(), y = (dial.hub.dy - math.cos(a) * r).round();
          final i = (y * w + x) * 4;
          sum += (d.getUint8(i) + d.getUint8(i + 1) + d.getUint8(i + 2)) / 3;
          n++;
        }
        return sum / n;
      }

      for (final l in dial.lines) {
        final line = light(l.angle);
        expect(line, lessThan(light(l.angle - 4) - 6), reason: '${clockText(l.time)} (${l.angle}°): darker than the plate before it');
        expect(line, lessThan(light(l.angle + 4) - 6), reason: '${clockText(l.time)}: darker than the plate after it');
      }
      // Seven lines, 1:00 to 4:00 every half hour, never spread evenly.
      expect([for (final l in dial.lines) l.time], [60, 90, 120, 150, 180, 210, 240]);
      final gaps = [for (var i = 1; i < dial.lines.length; i++) dial.lines[i].angle - dial.lines[i - 1].angle];
      expect(gaps.reduce(math.max) - gaps.reduce(math.min), greaterThan(2), reason: 'measured, not an even spread');
      expect(dial.lines.any((l) => (l.angle - 180).abs() < 20), isFalse, reason: 'the straight line down is the gnomon’s, no hour');
      expect(light(180), lessThan(light(176) - 6), reason: 'that line is there, and is not one of the hours');
    });

    test("the photo's four clock faces are white where the scenes say; the church's is small", () async {
      final (d, w, _) = await pixels('$folder/roof_photo.png');
      double light(Offset c, double r) {
        var sum = 0.0;
        var n = 0;
        for (var y = c.dy - r; y <= c.dy + r; y += 1) {
          for (var x = c.dx - r; x <= c.dx + r; x += 1) {
            final i = (y.round() * w + x.round()) * 4;
            sum += (d.getUint8(i) + d.getUint8(i + 1) + d.getUint8(i + 2)) / 3;
            n++;
          }
        }
        return sum / n;
      }

      for (final c in city.photo.clocks) {
        // Between the pivot and the rim: the pale face.
        expect(light(c.centre + Offset(c.rx * 0.5, 0), c.rx * 0.15), greaterThan(170), reason: '${c.id}: its white face');
      }
      final church = city.photo.clock('church');
      expect(church.rx * 2 / 1536, lessThan(0.03), reason: 'small in the photo: the glass is needed');
    });
  });

  group('in the game', () {
    test('Case 10 is in the game, after Case 09, at the Arc de Triomphe, with its four puzzles', () {
      expect(SeasonCatalog.byId(SeasonIds.paris)!.episodes.keys, ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05', 's2_ep06', 's2_ep07', 's2_ep08', 's2_ep09', 's2_ep10']);
      expect(season2AwaitingArtJson, isEmpty);
      expect(case10.number, 10);
      expect(case10.title, 'The Hour of Shadows');
      expect(case10.place, 'ARC DE TRIOMPHE');
      expect([for (final m in case10.allMissions) m.id], ['s2_ep10_m1', 's2_ep10_m2', 's2_ep10_m3', 's2_ep10_final']);
      expect([for (final m in case10.allMissions) m.title], ['The Drum Tape', 'A City of Clocks', 'The Hour of Shadows', 'The Hour Was Recorded']);
      expect([for (final m in case10.allMissions) m.evidence!.name], ['T1 Drum Tape', 'Independent Time Log', 'The Shadow Check', 'The Hour Was Recorded']);
      expect(ParisLandmark.cases['s2_ep10'], ParisLandmark.arcDeTriomphe);
      expect(case10.introScene, Artwork.arcStarView);
      expect((SeasonCatalog.evidenceArt('s2_ep10_e1')! as DrawnEvidenceArt).drawn, isA<TapeCard>());
      expect((SeasonCatalog.evidenceArt('s2_ep10_e2')! as DrawnEvidenceArt).drawn, isA<PhotoLog>());
      expect((SeasonCatalog.evidenceArt('s2_ep10_e3')! as DrawnEvidenceArt).drawn, isA<ShadowCard>());
      expect((SeasonCatalog.evidenceArt('s2_ep10_e4')! as DrawnEvidenceArt).drawn, isA<TapeCard>());
      for (final m in case10.allMissions) {
        expect(SeasonCatalog.storyScenes(m)?.after, isNotNull, reason: m.id);
      }
      expect(SeasonCatalog.closesAfterLastStep(fin), isTrue, reason: 'the record list closes the case');
      for (final m in case10.missions) {
        expect(SeasonCatalog.discovery(m).title, m.successMessage, reason: m.id);
      }
      expect(season2DiscoveryTypes['s2_ep10_m1'], DiscoveryType.evidenceFound);
    });

    test("Case 11 is told next by its title only; the bible's Case 10 is the one played", () {
      expect(SeasonCatalog.byId(SeasonIds.paris)!.season.upcomingTitles, {11: 'The Unwritten Hour'});
      final bible = File('docs/SEASON2_PARIS_STORY_BIBLE.md').readAsStringSync();
      // v2.0 (2026-10-26) added Cases 11–12; Case 10's section is as v1.9 wrote it.
      expect(bible, contains('**Version:** 2.0'));
      expect(bible, contains('- **v1.9 (2026-10-24):**'));
      expect(bible, contains('| 11 | **The Unwritten Hour** |'));
      for (final m in case10.allMissions) {
        expect(bible, contains(m.evidence!.name), reason: m.evidence!.name);
      }
      expect(case10.hook, 'Who sent page 3 away — and why?');
      expect(case09.hook, 'Was the hour lost — or was the clock wrong?', reason: 'Case 09 is as it was');
    });
  });

  group('its story and puzzles', () {
    test('it opens at the arch, T1’s star over it, then the room: door, things, plate', () {
      final picture = SeasonCatalog.introPicture('s2_ep10')!;
      expect(case10.intro, [
        'The Arc de Triomphe. Twelve roads meet around it, like a star.',
        "T1's little clock stood on top of an arch, with a star under it.",
        'You climb the stairs to the top.',
        'Under the roof, a small door has a star on it.',
        'Inside: a brass drum, a box of photos, and a thick book.',
        'A brass plate on the wall: TRIAL RECORDS · KEPT AT THE STAR.',
        'In the garden, we tested a model. These records are from the real trial.',
        "Let's read what T1 wrote.",
      ]);
      expect(case10.intro[picture.turnAtLine], 'Under the roof, a small door has a star on it.');
      expect(picture.inset!.file, endsWith('case_09/clock_model_t1.png'), reason: "T1's own star");
      expect([picture.inset!.fromLine, picture.inset!.toLine], [1, 3]);
      expect(picture.room!.plateLines, ['TRIAL RECORDS', 'KEPT AT THE STAR']);
      final plateMark = picture.marks.firstWhere((m) => m.area.contains(picture.room!.plateCentre));
      expect(case10.intro[plateMark.line], startsWith('A brass plate on the wall'));
      expect(picture.marks.firstWhere((m) => m.line == picture.turnAtLine).area, picture.room!.doorStar);
    });

    test("M1: T1 printed its own time every fifteen real minutes; it jumps at 3:00 and at 4:00; no three o'clock", () {
      expect([for (final m in tape.marks) m.printedText], ['2:00', '2:15', '2:30', '2:45', '2:00', '2:15', '2:30', '2:45', '4:00', '4:15']);
      expect([for (final m in tape.marks) m.realText], ['2:00', '2:15', '2:30', '2:45', '3:00', '3:15', '3:30', '3:45', '4:00', '4:15']);
      for (var i = 1; i < tape.marks.length; i++) {
        expect(tape.marks[i].real - tape.marks[i - 1].real, 15, reason: 'marks fifteen real minutes apart');
      }
      for (final m in tape.marks) {
        final behind = m.real - m.printed;
        expect(behind, m.real >= 180 && m.real < 240 ? 60 : 0, reason: '${m.id}: one hour behind from 3:00 to 4:00 only');
      }
      expect(tape.marks.any((m) => m.printed >= 180 && m.printed < 240), isFalse, reason: "no three o'clock printed");
      expect(tape.jumps, {'t5', 't9'});
      expect(AnswerChecker.isCorrect(m1, tape.answerOf({'t9', 't5'})), isTrue);
      expect(AnswerChecker.isCorrect(m1, tape.answerOf({'t5'})), isFalse);
      expect(tape.lineFor('t2'), "2:15 comes fifteen minutes after 2:00. That's fine.");
      expect(tape.lineFor('t1'), "That's where the tape starts.");
      expect(DrumTapeState.decode('t5;t3;x;t9', tape), {'t5', 't9'}, reason: 'only jumps are kept');
      expect(m1.transition.take(2), [
        'After 2:45, the tape goes back to 2:00. Then it jumps to 4:00.',
        "There is no three o'clock on the tape.",
      ]);
    });

    test('M2: the clocks are sorted by their signs; only T1 is a trial clock; the other three agree, T1 one hour behind', () {
      final photo = city.photo;
      expect(AnswerChecker.isCorrect(m2, city.answerOf({for (final c in photo.clocks) c.id: city.trayOf(c)})), isTrue);
      expect([for (final c in photo.clocks) if (c.trial) c.id], ['t1']);
      final others = photo.clocks.where((c) => !c.trial);
      expect({for (final c in others) c.photo2}, {210}, reason: 'the clocks that are not trial clocks agree');
      expect(photo.clock('t1').photo2, 150, reason: 'T1 one hour behind them');
      expect({for (final c in photo.clocks) c.photo1}, {120}, reason: 'in Photo 1 every clock agrees');
      // A finger's width (48 points) round each face on a 360-wide phone,
      // and no two reaches overlap.
      const shown = 328.0;
      final reach = 24 / (shown / 1536);
      for (final c in photo.clocks) {
        expect(city.clockAt(c.centre, reach)?.id, c.id, reason: c.id);
        expect(city.clockAt(c.centre + Offset(reach * 0.9, 0), reach)?.id, c.id, reason: '${c.id}: anywhere in a finger round it');
        for (final o in photo.clocks.where((o) => o != c)) {
          final rc = math.max(math.max(c.rx, c.ry) * 1.25, reach), ro = math.max(math.max(o.rx, o.ry) * 1.25, reach);
          expect((c.centre - o.centre).distance, greaterThan(rc + ro), reason: '${c.id} and ${o.id} never share a tap');
        }
      }
      expect(city.clockAt(const Offset(1009, 755), reach), isNull, reason: 'the sundial is no clock');
      // In the glass the church's face is at least 40 points wide.
      final church = photo.clock('church');
      expect(church.rx * 2 * city.lensScale, greaterThanOrEqualTo(40));
      final (found, sorted) = CityClocksState.decode('found=t1,church,x;sorted=church:trial,cafe:not', city);
      expect(sorted, {'cafe': 'not'}, reason: 'only a clock in its own tray is kept');
      expect(found, {'t1', 'church', 'cafe'});
      expect(m2.transition, contains('T1 is one hour behind them.'));
      expect(m2.transition.join(' '), isNot(contains('T2')), reason: 'nothing said of T2 and T3');
    });

    test("M3: one set of hour lines moves the sun, turns and stretches the shadow, and judges; any line settles", () {
      for (final l in dial.lines) {
        expect(dial.angleAt(l.time.toDouble()), closeTo(l.angle, 1e-9));
        expect(dial.timeAt(l.angle), closeTo(l.time, 1e-9));
        expect(dial.sunAngleAt(l.time.toDouble()), closeTo(l.angle + 180, 1e-9), reason: 'the sun opposite its shadow');
      }
      // Between lines: in between, both ways.
      expect(dial.timeAt(dial.angleAt(135)), closeTo(135, 1e-9));
      expect(dial.angleAt(135), closeTo((dial.lines[2].angle + dial.lines[3].angle) / 2, 1e-9));
      // Longer later.
      expect(dial.lengthAt(60), 0.45);
      expect(dial.lengthAt(240), 0.90);
      expect(dial.lengthAt(210), greaterThan(dial.lengthAt(120)));
      // Every line settles when near it; between two, none.
      for (final l in dial.lines) {
        expect(dial.settleAt(dial.timeAt(l.angle + 2))?.time, l.time);
      }
      expect(dial.settleAt(135), isNull);
      expect(dial.nearest(200).time, 210);
      expect([for (final p in shadow.photos) (p.t1, p.sun)], [(120, 120), (150, 210)]);
      expect(AnswerChecker.isCorrect(m3, shadow.answerOf({'photo1', 'photo2'})), isTrue);
      expect(m3.answer, 'photo1:t200,photo2:t330');
      expect(ShadowCheckState.decode('photo2;x', shadow), {'photo2'});
      // The photo's shadow is drawn through the photo's own sundial.
      final tip = shadow.photo.dial.along(dial.angleAt(210), dial.lengthAt(210));
      expect(shadow.photo.dialCrop.contains(tip), isTrue, reason: "Photo 2's shadow lies on the photo's sundial");
    });

    test('the final: Photo 2 is the second 2:30, at 3:30 by the sun; page 3 (3:00–4:00) is not in the book; the list names a place, no more', () {
      expect(record.tape.mark(record.photo2Mark).printedText, '2:30');
      expect(record.realAt(record.photo2Mark), 210);
      expect(record.realAt('t3'), 150, reason: 'the first 2:30 is only half an hour after Photo 1');
      expect(record.realAt('t5'), 180);
      expect(record.realAt('t9'), 240);
      expect(record.missing.id, 'p3');
      expect((record.missing.from, record.missing.to), (180, 240));
      expect([for (final p in record.inBook) p.number], [1, 2, 4]);
      expect(fin.answer, 'wrong');
      expect(AnswerChecker.feedbackFor(fin, 'lost'), "Look at the sun's line. Did the sun jump?");
      expect(AnswerChecker.feedbackFor(fin, 'all'), 'What did the café and church clocks say?');
      expect(record.lead.lines.firstWhere((l) => l.id == record.lead.answer).text, 'p.3 · SENT TO: SAINT-SULPICE · ARCHIVE ANNEX');
      expect(record.lead.doneLines.last, 'Is page 3 really there? Who sent it, and why? The list doesn\'t say.');
      // Just north of the Luxembourg Gardens on the map.
      final lux = ParisLandmark.luxembourgGardens.at;
      expect(record.lead.spot.at.dy, lessThan(lux.dy));
      expect((record.lead.spot.at - lux).distance, lessThan(0.1));
      expect(fin.transition.last, 'The mystery continues at Saint-Sulpice!');
    });

    test('Case 03 is remembered once, in its own words', () {
      final case03 = inGame.firstWhere((e) => e.id == 's2_ep03');
      expect(case03.finalMission.evidence!.inscription, startsWith('ONE HOUR IS MISSING. THE CLOCK IS STILL RUNNING.'));
      expect(case03.allMissions.any((m) => m.evidence?.inscription?.contains('time-recording machine') ?? false), isTrue);
      final all = everything();
      expect('time-recording machine'.allMatches(all).length, 1, reason: 'one recall only');
      expect(all, contains('ONE HOUR IS MISSING. THE CLOCK IS STILL RUNNING.'));
    });

    test('nothing is told before its time: no name, no culprit, no page 3, no T2 or T3 result', () {
      final all = everything().toLowerCase();
      for (final banned in ['émile', 'emile', 'moreau', 'victor', 'delacroix', 'removed', 'record was removed', 'deleted', 'erased', 'ordered', 'warning', 'stop the trial', 'binding', 'torn page', 'the same person']) {
        expect(all, isNot(contains(banned)), reason: banned);
      }
      // T2 and T3 named only to say they are not known.
      for (final line in everything().split('\n').where((l) => l.contains('T2') || l.contains('T3'))) {
        expect(line, anyOf(contains("We can't tell"), contains('Were T2 and T3 wrong too')), reason: line);
      }
      // Sent, never arrived.
      expect(all, isNot(contains('page 3 is at')));
      expect(all, isNot(contains('arrived')));
    });

    test('its learning design: every expression is on its screens', () {
      expect(season2LanguageTopics['s2_ep10'], isNotNull);
      String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      String screen(Mission m) => norm([...m.story, m.letterIntro, m.letter, m.question, for (final o in m.options) o.label, ...m.hints].join(' \n '));
      for (final m in case10.allMissions) {
        final l = season2Learning[m.id]!;
        for (final e in l.expressions) {
          expect(screen(m), contains(norm(e)), reason: '${m.id}: "$e" is on its screens');
        }
      }
      expect(season2Learning['s2_ep10_m2']!.dependency, LanguageDependency.exposure);
    });

    test('its evidence leads on from Case 09, one piece to the next', () {
      expect(SeasonCatalog.evidenceLink('s2_ep10_e1')!.to, 's2_ep09_e2');
      expect(SeasonCatalog.evidenceLink('s2_ep10_e2')!.to, 's2_ep09_e1');
      expect(SeasonCatalog.evidenceLink('s2_ep10_e3')!.to, 's2_ep10_e2');
      expect(SeasonCatalog.evidenceLink('s2_ep10_e4')!.to, 's2_ep09_e4');
      expect(SeasonCatalog.evidenceLink('s2_ep09_e4')!.to, 's2_ep09_e2', reason: "Case 09's links are as they were");
    });

    test('the sun is an ink glyph of its own, not a star', () {
      expect(InkGlyph.values, contains(InkGlyph.sun));
      expect(File('lib/features/mission/widgets/star_records.dart').readAsStringSync(), isNot(contains('Icons.')), reason: 'no Material icons');
    });
  });

  group('its rules', () {
    late SharedPreferences prefs;

    Future<ProviderContainer> start() async {
      final c = ProviderContainer(overrides: await testOverridesFor(prefs));
      addTearDown(c.dispose);
      return c;
    }

    /// Every answer of [e]; Cases 08 and 09 then closed with their last steps.
    void solve(ProviderContainer c, Episode e) {
      final game = c.read(gameControllerProvider.notifier);
      expect(game.openEpisode(e.id), isTrue, reason: e.id);
      game.startInvestigation();
      for (final m in e.allMissions) {
        expect(game.submitAnswer(m, m.answer).result, SubmitResult.correct, reason: m.id);
      }
      if (e == case08) expect(game.closeCase(case08Lead), isTrue);
      if (e == case09) expect(game.closeCase(case09Star), isTrue);
      if (e == case10) {
        game.recordExamined(photoKey);
        game.recordExamined(pageKey);
        expect(game.closeCase(listKey), isTrue);
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

    test('it opens only once Case 09 is closed with its star', () async {
      final c = await start();
      final game = c.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      for (final e in paris.take(8)) {
        solve(c, e);
      }
      expect(game.openEpisode('s2_ep10'), isFalse, reason: 'no way round Case 09');
      expect(game.openEpisode('s2_ep09'), isTrue);
      game.startInvestigation();
      for (final m in case09.allMissions) {
        game.submitAnswer(m, m.answer);
      }
      expect(game.openEpisode('s2_ep10'), isFalse, reason: "Case 09's star first");
      expect(game.closeCase(case09Star), isTrue);
      expect(game.openEpisode('s2_ep10'), isTrue);
      expect(c.read(currentEpisodeProvider).id, 's2_ep10');
    });

    test('the tape, the clocks, the shadows and both final steps are saved and come back; evidence and XP never twice', () async {
      var c = await start();
      var game = c.read(gameControllerProvider.notifier);
      game.openSeason(SeasonIds.paris);
      for (final e in paris) {
        solve(c, e);
      }
      game.openEpisode('s2_ep10');
      game.startInvestigation();
      game.recordExamined(GameProgress.examinedKey(m1.id, DrumTapeScene.pulledId));
      game.recordPuzzleState(m1.id, DrumTapeState.encode({'t5'}));

      c.dispose();
      c = await start();
      game = c.read(gameControllerProvider.notifier);
      var p = c.read(gameControllerProvider);
      expect(c.read(currentEpisodeProvider).id, 's2_ep10');
      expect(DrumTapeState.decode(p.puzzleStateOf(m1.id), tape), {'t5'});
      expect(p.hasExamined(GameProgress.examinedKey(m1.id, DrumTapeScene.pulledId)), isTrue);
      expect(p.wrongCount(m1.id), 0);
      expect(game.submitAnswer(m1, m1.answer).result, SubmitResult.correct);
      final xpAfterM1 = c.read(gameControllerProvider).completedMissionIds.length;
      game.recordPuzzleState(m2.id, CityClocksState.encode({'t1', 'church'}, {'t1': 'trial'}));
      expect(game.submitAnswer(m2, m2.answer).result, SubmitResult.correct);
      game.recordPuzzleState(m3.id, ShadowCheckState.encode({'photo1'}));
      expect(game.submitAnswer(m3, m3.answer).result, SubmitResult.correct);
      game.recordExamined(photoKey);

      c.dispose();
      c = await start();
      game = c.read(gameControllerProvider.notifier);
      p = c.read(gameControllerProvider);
      final (found, sorted) = CityClocksState.decode(p.puzzleStateOf(m2.id), city);
      expect(found, {'t1', 'church'});
      expect(sorted, {'t1': 'trial'});
      expect(ShadowCheckState.decode(p.puzzleStateOf(m3.id), shadow), {'photo1'});
      expect((p.hasExamined(photoKey), p.hasExamined(pageKey)), (true, false));
      game.recordExamined(pageKey);
      expect(game.submitAnswer(fin, 'lost').result, SubmitResult.tryAgain);
      expect(game.submitAnswer(fin, fin.answer).result, SubmitResult.correct);
      // Answered again: nothing new, no evidence twice.
      final coins = c.read(walletProvider).balance;
      game.submitAnswer(m1, m1.answer);
      expect(c.read(walletProvider).balance, coins, reason: 'no coins twice');
      p = c.read(gameControllerProvider);
      expect(p.completedMissionIds.where((id) => id == m1.id).length, 1);
      expect(xpAfterM1, greaterThan(0));
      expect([for (final e in p.collectedEvidence(case10)) e.name], ['T1 Drum Tape', 'Independent Time Log', 'The Shadow Check', 'The Hour Was Recorded']);
      // Answered, not closed: the record list waits.
      expect((p.isCompleted(fin.id), p.isCaseSolved, p.finalAwaitsLastStep(case10)), (true, false, true));

      c.dispose();
      c = await start();
      game = c.read(gameControllerProvider.notifier);
      expect(c.read(gameControllerProvider).isCaseSolved, isFalse, reason: 'after a restart: answered, still open');
      expect(game.closeCase(listKey), isTrue);
      expect(c.read(gameControllerProvider).isCaseSolved, isTrue);
      expect(game.closeCase(listKey), isFalse, reason: 'closed once');
      expect(c.read(progressRepositoryProvider).load('s2_ep09').isCaseSolved, isTrue, reason: "Case 09's save is its own");
      expect(c.read(progressRepositoryProvider).load('s2_ep09').examined.any((k) => k.startsWith('s2_ep10')), isFalse);
    });

    test('solved: Paris is 10 of 12, Case 11 is coming soon, nothing opens it; London is as it was', () async {
      final c = await start();
      final game = c.read(gameControllerProvider.notifier);
      game.openSeason(SeasonIds.paris);
      for (final e in [...paris, case10]) {
        solve(c, e);
      }
      final board = c.read(seasonOverviewProvider);
      expect(board.solvedCount, 10);
      expect(board.comingSoonCase, 11);
      final available = c.read(seasonAvailabilityProvider(SeasonIds.paris))!;
      expect((available.solvedCount, available.plannedCount), (10, 12));
      expect(game.openEpisode('s2_ep11'), isFalse, reason: 'no Case 11 to open');
      expect(c.read(progressRepositoryProvider).loadSeason(SeasonIds.london).solvedEpisodeIds, hasLength(12));
    });
  });

  group('a child plays Case 10', () {
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
        if (e == case09) game.closeCase(case09Star);
      }
      return ref;
    }

    for (final size in const [Size(360, 640), Size(393, 783), Size(430, 908), Size(800, 1280)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';
      testWidgets('$tag: Case 09 closed → the arch → the tape → the photo → the shadows → the record → the list, 10 of 12', (t) async {
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
            File('$shots/paris10_${tag}_${(n++).toString().padLeft(2, '0')}_$name.png').writeAsBytesSync(png!.buffer.asUint8List());
          });
        }

        Future<void> visit(String missionId) async {
          router.go(Routes.mission(missionId));
          await wait(t, const Duration(milliseconds: 1400));
        }

        Future<void> tapKey(String key, {Duration after = const Duration(milliseconds: 400)}) async {
          final f = find.byKey(ValueKey(key));
          await reveal(t, f);
          await t.ensureVisible(f);
          await t.pump(const Duration(milliseconds: 100));
          await t.tap(f);
          await wait(t, after);
        }

        Offset onPhoto(Offset px) {
          final r = t.getRect(find.byKey(const ValueKey('city-photo')));
          return Offset(r.left + px.dx / 1536 * r.width, r.top + px.dy / 1024 * r.height);
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

        // ── Case 09's Case Closed: on to Case 10 ────────────────────────
        router.go(Routes.solvedSettled);
        await wait(t, const Duration(milliseconds: 3000));
        await reveal(t, find.text('OPEN CASE 10'));
        expect(find.text('OPEN CASE 10'), findsOneWidget, reason: 'Case 10 is in the game now');
        expect(game.openEpisode('s2_ep10'), isTrue);

        // ── The opening: the arch, then the room under the roof ─────────
        router.go(Routes.intro);
        await wait(t, const Duration(milliseconds: 2200));
        expect(find.byKey(const ValueKey('intro-picture')), findsOneWidget);
        await shot('opening_arch');
        await tapText(t, 'SKIP ›', after: const Duration(milliseconds: 2200));
        expect(find.byKey(const ValueKey('intro-picture-garden')), findsOneWidget, reason: 'walked in: the room');
        expect(find.byKey(const ValueKey('star-room-plate')), findsWidgets, reason: "the plate's words, engraved");
        expect(find.text('TRIAL RECORDS'), findsWidgets);
        expect(find.text('A brass plate on the wall: TRIAL RECORDS · KEPT AT THE STAR.'), findsOneWidget);
        await shot('opening_room');
        await tapText(t, "I'M READY", after: const Duration(milliseconds: 1600));

        // ── M1: the drum tape ───────────────────────────────────────────
        await visit(m1.id);
        expect(find.byKey(const ValueKey('story-picture')), findsOneWidget, reason: 'the room');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('tape-pull')), findsOneWidget);
        finger('tape-pull');
        await shot('m1_drum');
        // Pulled out with a finger to the right.
        await reveal(t, find.byKey(const ValueKey('tape-pull')));
        await t.drag(find.byKey(const ValueKey('tape-pull')), const Offset(90, 0));
        await wait(t, const Duration(milliseconds: 700));
        expect(find.byKey(const ValueKey('tape-scroll')), findsOneWidget, reason: 'the tape out');
        expect(examined(), contains(GameProgress.examinedKey(m1.id, DrumTapeScene.pulledId)));
        for (final id in ['t1', 't2']) {
          finger('tape-mark-$id');
        }
        await shot('m1_tape');
        await tapKey('tape-mark-t2');
        expect(find.text("2:15 comes fifteen minutes after 2:00. That's fine."), findsOneWidget);
        expect(ref.read(gameControllerProvider).wrongCount(m1.id), 0, reason: 'never a wrong answer');
        await tapKey('tape-mark-t5');
        expect(find.text(tape.oneMore), findsOneWidget);
        expect(DrumTapeState.decode(ref.read(gameControllerProvider).puzzleStateOf(m1.id), tape), {'t5'}, reason: 'saved as found');
        await tapKey('tape-mark-t5');
        expect(DrumTapeState.decode(ref.read(gameControllerProvider).puzzleStateOf(m1.id), tape), {'t5'}, reason: 'found once');
        await shot('m1_one');
        await tapKey('tape-mark-t9');
        expect(find.text(tape.found), findsOneWidget);
        expect(find.text('2:45 → 4:00'), findsOneWidget, reason: 'the jump named on the tape');
        await shot('m1_two');
        await finish(m1.transition.first, 'm1');
        expect(ref.read(gameControllerProvider).isCompleted(m1.id), isTrue);

        // ── M2: a city of clocks ────────────────────────────────────────
        await visit(m2.id);
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('city-photo')), findsOneWidget);
        expect(find.byKey(const ValueKey('city-lens')), findsOneWidget);
        await shot('m2_photo');
        // The glass dragged over the church: its small face, large in the glass.
        await reveal(t, find.byKey(const ValueKey('city-photo')));
        final church = city.photo.clock('church');
        final g = await t.startGesture(onPhoto(const Offset(700, 300)));
        await t.pump(const Duration(milliseconds: 50));
        await g.moveTo(onPhoto(church.centre + const Offset(30, 10)));
        await t.pump(const Duration(milliseconds: 50));
        await g.moveTo(onPhoto(church.centre));
        await wait(t, const Duration(milliseconds: 500));
        expect(t.getSize(find.byKey(const ValueKey('city-lens'))).width, city.lensSize);
        await shot('m2_glass_church');
        await g.up();
        await wait(t, const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('city-card-church')), findsOneWidget, reason: 'the church clock found under the glass');
        // A tap a finger's width off a face still finds it.
        final photoRect = t.getRect(find.byKey(const ValueKey('city-photo')));
        await t.tapAt(onPhoto(city.photo.clock('cafe').centre) + const Offset(16, 0));
        await wait(t, const Duration(milliseconds: 400));
        expect(find.byKey(const ValueKey('city-card-cafe')), findsOneWidget);
        expect(photoRect.width, greaterThan(300));
        // The sundial is no clock.
        await t.tapAt(onPhoto(const Offset(1009, 755)));
        await wait(t, const Duration(milliseconds: 400));
        expect(find.text('FOUND 2 / 4'), findsOneWidget);
        for (final id in ['t1', 'post']) {
          await reveal(t, find.byKey(const ValueKey('city-photo')));
          await t.tapAt(onPhoto(city.photo.clock(id).centre));
          await wait(t, const Duration(milliseconds: 400));
        }
        expect(find.text('FOUND 4 / 4'), findsOneWidget);
        expect(find.text(city.sortTask), findsWidgets);
        for (final id in ['t1', 'cafe', 'church', 'post']) {
          finger('city-card-$id');
        }
        finger('city-tray-trial');
        finger('city-tray-not');
        await shot('m2_found');
        // The café to the trial tray: back, with its line.
        await tapKey('city-card-cafe');
        await tapKey('city-tray-trial');
        expect(find.text(city.photo.clock('cafe').wrongLine), findsOneWidget);
        expect(ref.read(gameControllerProvider).wrongCount(m2.id), 0);
        await shot('m2_wrong');
        await tapKey('city-card-cafe');
        await tapKey('city-tray-not');
        await tapKey('city-card-t1');
        await tapKey('city-tray-trial');
        await tapKey('city-card-church');
        await tapKey('city-tray-not');
        await tapKey('city-card-post');
        await tapKey('city-tray-not', after: const Duration(milliseconds: 300));
        expect(find.text('T1 · 2:30'), findsOneWidget, reason: 'the times shown once all are sorted');
        expect(find.text('Church · 3:30'), findsOneWidget);
        await shot('m2_sorted');
        await finish(m2.transition.first, 'm2');
        expect(ref.read(gameControllerProvider).isCompleted(m2.id), isTrue);

        // ── M3: the hour of shadows ─────────────────────────────────────
        await visit(m3.id);
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('sundial')), findsOneWidget);
        expect(find.byKey(const ValueKey('shadow-photo-photo1')), findsOneWidget);
        for (final l in dial.lines) {
          finger('sun-point-${l.time}');
        }
        await shot('m3_photo1');
        // 1:30: the photo's shadow is longer.
        await tapKey('sun-point-90');
        expect(find.text(shadow.longer), findsOneWidget);
        expect(t.widget<Text>(find.byKey(const ValueKey('shadow-reading'))).data, 'SUN: 1:30', reason: 'settled on a line that is not the answer');
        await tapKey('sun-point-120');
        expect(find.text(shadow.matchLine), findsOneWidget);
        expect(find.text('PHOTO 1: T1 2:00 · SUN 2:00 · same'), findsOneWidget);
        await shot('m3_photo1_matched');
        await tapKey('shadow-next', after: const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('shadow-photo-photo2')), findsOneWidget);
        // 3:00: shorter than the photo's.
        await tapKey('sun-point-180');
        expect(find.text(shadow.longer), findsOneWidget);
        // Dragged: the finger on the dial (never on the sun), round to 3:30.
        await reveal(t, find.byKey(const ValueKey('sundial')));
        await t.ensureVisible(find.byKey(const ValueKey('sundial')));
        await t.pump(const Duration(milliseconds: 300));
        final r = t.getRect(find.byKey(const ValueKey('sundial')));
        Offset towards(double degrees, double reach) {
          final a = degrees * math.pi / 180;
          return r.center + Offset(math.sin(a), -math.cos(a)) * reach;
        }

        final d = await t.startGesture(towards(dial.sunAngleAt(180), r.width * 0.3));
        await t.pump(const Duration(milliseconds: 50));
        for (final time in [190.0, 200.0, 208.0]) {
          await d.moveTo(towards(dial.sunAngleAt(time), r.width * 0.3));
          await t.pump(const Duration(milliseconds: 60));
        }
        await shot('m3_dragging');
        await d.up();
        await wait(t, const Duration(milliseconds: 500));
        expect(t.widget<Text>(find.byKey(const ValueKey('shadow-reading'))).data, 'SUN: 3:30');
        expect(find.text('PHOTO 2: T1 2:30 · SUN 3:30 · one hour apart'), findsOneWidget);
        await shot('m3_photo2_matched');
        await finish(m3.transition.first, 'm3');
        expect(ref.read(gameControllerProvider).isCompleted(m3.id), isTrue);

        // ── Final: the hour was recorded ────────────────────────────────
        router.go(Routes.finalMission);
        await wait(t, const Duration(milliseconds: 2600));
        expect(find.byKey(const ValueKey('record-stage')), findsOneWidget);
        expect(find.text(fin.question), findsNothing, reason: 'not asked before the tape and the book');
        await reveal(t, find.byKey(const ValueKey('record-tape')));
        await shot('fin_tape');
        await tapKey('tape-mark-t3');
        expect(find.text(record.firstTwoThirty), findsOneWidget);
        await tapKey('tape-mark-t2');
        expect(find.text(record.notTwoThirty), findsOneWidget);
        expect(ref.read(gameControllerProvider).wrongCount(fin.id), 0);
        await tapKey('tape-mark-t7', after: const Duration(milliseconds: 2400));
        expect(examined(), contains(photoKey));
        expect(t.widget<Text>(find.descendant(of: find.byKey(const ValueKey('record-sun-t5')), matching: find.byType(Text))).data, '3:00');
        expect(find.byKey(const ValueKey('record-jump-t5')), findsOneWidget);
        await shot('fin_sun_laid');
        // The book: page 2 is in it; page 3 is not.
        await tapKey('trial-log-line-p2');
        expect(find.text(record.pageInBook), findsOneWidget);
        await tapKey('trial-log-next');
        await tapKey('trial-log-next');
        await shot('fin_book');
        await tapKey('trial-log-line-p3', after: const Duration(milliseconds: 800));
        expect(examined(), contains(pageKey));
        await reveal(t, find.byKey(const ValueKey('record-question-sheet')));
        await shot('fin_question');
        await tapText(t, 'The hour was lost. Time jumped from 2:45 to 4:00.', after: const Duration(milliseconds: 300));
        await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 1500));
        expect(findReadableContaining("Did the sun jump?"), findsWidgets);
        await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
        await tapText(t, 'The hour was there. T1 was one hour behind, and the page about it is missing.', after: const Duration(milliseconds: 300));
        await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 300));
        await wait(t, const Duration(milliseconds: 3600));
        expect(ref.read(gameControllerProvider).isCompleted(fin.id), isTrue);
        expect(ref.read(gameControllerProvider).isCaseSolved, isFalse, reason: 'the record list closes the case');
        await reveal(t, find.byKey(const ValueKey('final-read-list')));
        expect(find.text(record.afterLines.first), findsOneWidget);
        expect(find.textContaining('Saint-Sulpice'), findsNothing, reason: 'no place named before the list is read');
        await shot('fin_solved');

        // ── The record list: page 3's line, Saint-Sulpice ───────────────
        await tapKey('final-read-list', after: const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('record-list')), findsOneWidget);
        await tapKey('record-line-p1');
        expect(find.text(record.lead.otherLine), findsOneWidget);
        expect(examined(), isNot(contains(listKey)));
        await tapKey('record-line-p3', after: const Duration(milliseconds: 1000));
        expect(find.byKey(const ValueKey('record-map-ring')), findsOneWidget);
        expect(find.text(record.lead.doneLines.first), findsOneWidget);
        await shot('list_map');
        await tapKey('record-done', after: const Duration(milliseconds: 600));
        expect(examined(), contains(listKey));
        expect(ref.read(gameControllerProvider).isCaseSolved, isTrue, reason: 'closed with the list');
        expect(find.text('CASE SOLVED'), findsOneWidget);
        await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 900));
        expect(find.text(fin.transition.first), findsOneWidget);
        await t.tapAt(Offset(size.width / 2, size.height / 2));
        await wait(t, const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('scene-backdrop')), findsOneWidget);
        expect(findReadable('The mystery continues at Saint-Sulpice!'), findsOneWidget);
        await shot('final_scene');
        await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 4000));
        await reveal(t, find.byKey(const ValueKey('next-case-coming-soon')));
        expect(find.text('CASE 11 · THE UNWRITTEN HOUR'), findsOneWidget);
        expect(find.text('COMING SOON'), findsOneWidget);
        await shot('case_closed');

        final board = ref.read(seasonOverviewProvider);
        expect(board.solvedCount, 10);
        expect(board.comingSoonCase, 11);
        expect(game.openEpisode('s2_ep11'), isFalse);
        expect(ref.read(walletProvider).balance, greaterThan(coinsAtStart), reason: 'the case paid its coins');
        await wait(t, const Duration(seconds: 3));
      });
    }

    testWidgets("the opening's picture holds its place; the plate up close on its line", (t) async {
      final ref = await open(t, const Size(360, 640));
      expect(ref.read(gameControllerProvider.notifier).openEpisode('s2_ep10'), isTrue);
      ref.read(routerProvider).go(Routes.intro);
      await wait(t, const Duration(milliseconds: 500));
      final picture = find.byKey(const ValueKey('intro-picture'));
      final first = t.getRect(picture);
      expect(first.height, greaterThan(100));
      await wait(t, const Duration(milliseconds: 2500));
      expect(find.byKey(const ValueKey('intro-0')), findsOneWidget);
      expect(t.getRect(picture), first, reason: 'the picture never resizes the page');
      // On through the lines to the plate's: the picture stays put.
      for (var i = 0; i < 40 && find.byKey(const ValueKey('intro-5')).evaluate().isEmpty; i++) {
        await wait(t, const Duration(milliseconds: 600));
      }
      expect(find.byKey(const ValueKey('intro-5')), findsOneWidget);
      expect(t.getRect(picture), first);
      expect(find.byKey(const ValueKey('star-room-plate-closer')), findsOneWidget, reason: 'the plate up close on its line');
      expect(t.takeException(), isNull);
    });

    testWidgets('back again after a restart: the tape, the clocks, the shadows and the final steps are as left', (t) async {
      final ref = await open(t, const Size(393, 783));
      final game = ref.read(gameControllerProvider.notifier);
      expect(game.openEpisode('s2_ep10'), isTrue);
      game.startInvestigation();
      game.recordExamined(GameProgress.examinedKey(m1.id, DrumTapeScene.pulledId));
      game.recordPuzzleState(m1.id, DrumTapeState.encode({'t9'}));
      final router = ref.read(routerProvider);
      router.go(Routes.mission(m1.id));
      await wait(t, const Duration(milliseconds: 1400));
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      expect(find.byKey(const ValueKey('tape-scroll')), findsOneWidget, reason: 'pulled already');
      expect(find.text('2:45 → 4:00'), findsOneWidget, reason: 'the jump found before');
      game.submitAnswer(m1, m1.answer);
      game.recordPuzzleState(m2.id, CityClocksState.encode({'church', 't1'}, {'church': 'not'}));
      router.go(Routes.map);
      await wait(t, const Duration(milliseconds: 1400));
      router.go(Routes.mission(m2.id));
      await wait(t, const Duration(milliseconds: 1400));
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      expect(find.text('FOUND 2 / 4'), findsOneWidget);
      expect(find.byKey(const ValueKey('city-card-t1')), findsOneWidget);
      game.submitAnswer(m2, m2.answer);
      game.recordPuzzleState(m3.id, ShadowCheckState.encode({'photo1'}));
      router.go(Routes.map);
      await wait(t, const Duration(milliseconds: 1400));
      router.go(Routes.mission(m3.id));
      await wait(t, const Duration(milliseconds: 1400));
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      expect(find.byKey(const ValueKey('shadow-photo-photo2')), findsOneWidget, reason: 'Photo 1 matched before: Photo 2 now');
      game.submitAnswer(m3, m3.answer);
      game.recordExamined(photoKey);
      router.go(Routes.finalMission);
      await wait(t, const Duration(milliseconds: 2600));
      await reveal(t, find.byKey(const ValueKey('trial-log')));
      expect(find.byKey(const ValueKey('record-pin-photo2')), findsOneWidget, reason: 'Photo 2 on the tape as left');
      expect(find.byKey(const ValueKey('record-question-sheet')), findsNothing, reason: 'the book still to check');
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
                const TapeCardView(card: TapeCard(season2DrumTape)),
                PhotoLogView(log: PhotoLog(season2CityClocks.photo)),
                const ShadowCardView(card: ShadowCard(season2ShadowCheck)),
                const TapeCardView(card: TapeCard(season2DrumTape, record: season2HourRecord)),
              ],
            ),
          ),
        ),
      ));
      await t.pump(const Duration(milliseconds: 800));
      expect(t.takeException(), isNull);
      expect(find.byType(TapeStrip), findsNWidgets(2));
    });
  });
}
