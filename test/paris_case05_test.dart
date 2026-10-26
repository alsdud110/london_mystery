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
import 'package:london_mystery/data/mock/season2/season2_case05_scenes.dart' show season2Blotters;
import 'package:london_mystery/data/mock/season2/season2_learning.dart';
import 'package:london_mystery/data/mock/season_catalog.dart';
import 'package:london_mystery/data/models/discovery.dart';
import 'package:london_mystery/data/models/easy_steps.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/learning.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/river_puzzles.dart';
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/models/workshop_puzzles.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/mission_map/map_world.dart';
import 'package:london_mystery/features/season/season_overview.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/game_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'easy_play.dart';
import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';

/// Season 2, Case 05 — The Silent Workshop: its fourteen pictures (as
/// delivered, measured), its story and puzzles as the papers and clocks say
/// them, its rules (unlock after Case 04, saves, Case 06 opening next), and
/// a child playing it through on three phones. What the letter's receipt
/// and slips say is never shown before its mission; who the maker is, who
/// the letter was for and what it says are never told.
///
/// `LM_SHOTS=folder` saves a picture of each step of the play-through.
void main() {
  final inGame = MockEpisodeRepository.bundled();
  final s1 = season1Cases();
  final [case01, case02, case03, case04, case05] = [
    for (final id in ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05']) inGame.firstWhere((e) => e.id == id),
  ];
  final [m1, m2, m3, fin] = case05.allMissions;
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
          m.clue?.note ?? '',
          m.evidence?.description ?? '',
          m.evidence?.inscription ?? '',
        ],
      ].join('\n');

  final bench = SeasonCatalog.markCompare(m1)!;
  final wall = SeasonCatalog.clockWall(m2)!;
  // M3's old blotter: no longer played (very easy since 2026-10-27), its
  // measured pictures and papers still drawn on.
  final blotter = season2Blotters[m3.id]!;
  final trail = SeasonCatalog.postTrail(fin)!;
  // M3 and the final, played very easy (the user's rules of 2026-10-27).
  final steps3 = SeasonCatalog.easySteps(m3)!;
  final stepsF = SeasonCatalog.easySteps(fin)!;

  group('its pictures', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const folder = 'assets/seasons/season_02_paris/cases/case_05';
    // Size, and whether it has an alpha channel (as delivered). Clock I's
    // back is larger than the other three and has none: the same picture.
    // Clock IV's back has none either since its watermark was taken off
    // (b64ed09): the backs are shown whole, opaque.
    const pictures = {
      'workshop_interior.png': (1536, 1024, false),
      'wall_of_clocks.png': (1536, 1024, false),
      'clock_back_normal.png': (1254, 1254, false),
      'clock_back_spring.png': (1024, 1024, true),
      'clock_back_extra_wheel.png': (1024, 1024, true),
      'clock_back_broken.png': (1024, 1024, false),
      'workbench_marks.png': (1536, 1024, false),
      'maker_mark_a.png': (1254, 1254, true),
      'writing_desk_blotter.png': (1264, 848, true),
      'hand_mirror.png': (896, 1200, true),
      'envelope_corner.png': (1216, 880, true),
      'post_slip_blank.png': (1376, 768, true),
      'repair_card_blank.png': (1480, 1062, true),
      'tracing_sheet.png': (1254, 1254, true),
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

    test('all fourteen are in, listed in pubspec, at their sizes', () {
      expect(pubspecAssets(), contains('$folder/'), reason: 'its folder, exactly, in flutter: assets:');
      expect(Directory(folder).listSync().whereType<File>().where((f) => f.path.endsWith('.png')).length, 14);
      for (final MapEntry(key: name, value: (w, h, alpha)) in pictures.entries) {
        final file = File('$folder/$name');
        expect(file.existsSync(), isTrue, reason: name);
        final (pw, ph, a) = header(file.readAsBytesSync());
        expect((pw, ph), (w, h), reason: name);
        expect(a, alpha, reason: name);
      }
    });

    test('every one of them is played on, with the two clock hands and the gate of Case 04', () {
      final scenes = File('lib/data/mock/season2/season2_case05_scenes.dart').readAsStringSync();
      for (final name in pictures.keys) {
        expect(scenes, contains(name), reason: name);
      }
      expect(scenes, contains(r"'$_case04/hands_sign.png'"));
      expect(case05.introScene, Artwork.passageGate);
      expect(ArtAssets.parisScenes[Artwork.wallOfClocks], '$folder/wall_of_clocks.png');
    });

    test('the cut-outs are clear round their object; the mirror\'s glass is clear', () async {
      for (final name in ['envelope_corner.png', 'post_slip_blank.png', 'repair_card_blank.png', 'hand_mirror.png', 'maker_mark_a.png']) {
        final (d, w, h) = await pixels('$folder/$name');
        expect(alphaAt(d, w, w - 2, h - 2), 0, reason: '$name: a clear corner');
      }
      final (m, mw, _) = await pixels('$folder/hand_mirror.png');
      final c = blotter.glassCentre;
      expect(alphaAt(m, mw, c.dx.round(), c.dy.round()), 0, reason: 'the glass is clear');
      expect(alphaAt(m, mw, (c.dx + blotter.glassRadius * 0.8).round(), c.dy.round()), 0);
    });

    test('every place tapped or written on is inside its picture', () {
      bool inside(Rect r) => r.left >= 0 && r.top >= 0 && r.right <= 1 && r.bottom <= 1 && !r.isEmpty;
      for (final s in bench.seals) {
        expect(inside(s.area) && inside(s.seal), isTrue, reason: s.id);
        expect(s.area.contains(s.seal.center), isTrue, reason: '${s.id}: the stamp is on its thing');
      }
      for (final c in wall.clocks) {
        expect(inside(c.area) && inside(c.plateAt), isTrue, reason: c.id);
        final dial = Rect.fromCircle(center: c.centre, radius: c.radius);
        final view = Rect.fromLTRB(wall.view.left * 1536, wall.view.top * 1024, wall.view.right * 1536, wall.view.bottom * 1024);
        expect(view.contains(dial.topLeft) && view.contains(dial.bottomRight), isTrue, reason: '${c.id}: its dial is shown');
        expect(c.area.contains(Offset(c.centre.dx / 1536, c.centre.dy / 1024)), isTrue);
      }
      for (final n in blotter.notes) {
        expect(blotter.blotter.contains(n.at.topLeft) && blotter.blotter.contains(n.at.bottomRight), isTrue, reason: n.id);
      }
      for (final p in [bench.card, blotter.hideaway, trail.paperOf(trail.slips.first)]) {
        expect(Offset.zero & Size(p.pixels.width, p.pixels.height), isA<Rect>().having((r) => r.contains(p.writeOn.bottomRight), 'writes inside', isTrue));
      }
      expect(inside(trail.stageView), isTrue);
    });
  });

  group('its story and puzzles', () {
    test('Case 05 is in the game, after Case 04, at Notre-Dame, with its four puzzles', () {
      expect(SeasonCatalog.byId(SeasonIds.paris)!.episodes.keys, ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05', 's2_ep06', 's2_ep07', 's2_ep08', 's2_ep09', 's2_ep10', 's2_ep11', 's2_ep12']);
      expect(case05.number, 5);
      expect(case05.title, 'The Silent Workshop');
      expect(case05.place, 'PASSAGE DES HORLOGERS · No. 7');
      expect([for (final m in case05.allMissions) m.id], ['s2_ep05_m1', 's2_ep05_m2', 's2_ep05_m3', 's2_ep05_final']);
      expect([for (final m in case05.allMissions) m.type],
          [MissionType.multipleChoice, MissionType.multipleChoice, MissionType.multipleChoice, MissionType.matchPairs]);
      expect([for (final m in case05.allMissions) m.evidence!.name],
          ['The Repair Card', 'The Backward Clock', 'The Blotted Note', "The Letter's Trail"]);
      expect(ParisLandmark.cases['s2_ep05'], ParisLandmark.notreDame);
      expect(ParisLandmark.notreDame.at, const Offset(0.732, 0.566));
      expect(SeasonMap.landmarkOf(m1.id), ParisLandmark.notreDame);
      expect(SeasonCatalog.byId(SeasonIds.paris)!.season.upcomingTitles, isEmpty, reason: 'Cases 06 to 12 are in the game; no title is left to tell');
      // M3 and the final are played very easy (2026-10-27); M1 and M2 as
      // they were. The final's trail stays for the page after its answer.
      expect(SeasonCatalog.blotter(m3), isNull);
      for (final m in [m3, fin]) {
        expect(SeasonCatalog.easySteps(m)?.answer, m.answer, reason: '${m.id}: its own answer, so saves are as before');
      }
      for (final m in [m1, m2]) {
        expect(SeasonCatalog.easySteps(m), isNull, reason: m.id);
      }
    });

    test('the opening picks up the label\'s last words, in the second person; Case 04 is as it was', () {
      expect(case05.intro, [
        'Do not trust the clocks. Follow the hands that made them.',
        'The gate is not locked. Behind it, a door says No. 7.',
        'Inside, clocks cover the walls.',
        'Their hands move, but the room is silent.',
        'Someone worked here. Not long ago.',
      ]);
      for (final line in [...case05.intro, ...case05.synopsis, ...case05.objectives, for (final m in case05.allMissions) ...m.story]) {
        expect(RegExp(r"\bI\b|\bI'm\b|\bmy\b").hasMatch(line), isFalse, reason: 'second person: $line');
      }
      expect(case04.finalMission.evidence!.inscription, contains('Do not trust the clocks. Follow the hands that made them.'));
      expect(case04.finalMission.transition.last, 'But whose hands are they?');
      expect(case04.missions[1].evidence!.inscription, contains('15 MAY: Box 23 collected for No. 7.'));
    });

    test('M1: each copy differs from the maker\'s mark in one way; only the small drawer\'s is the maker\'s', () {
      expect({for (final s in bench.seals) s.id: s.copy}, {'a': MarkCopy.tip, 'b': MarkCopy.shifted, 'c': MarkCopy.oneHand, 'd': MarkCopy.exact});
      expect({for (final o in m1.options) o.id}, {for (final s in bench.seals) s.id});
      expect(m1.answer, 'd');
      for (final o in m1.options) {
        expect(AnswerChecker.isCorrect(m1, o.id), o.id == 'd');
        if (o.id != 'd') expect(AnswerChecker.feedbackFor(m1, o.id), isNotNull, reason: o.id);
      }
      expect(AnswerChecker.feedbackFor(m1, 'a'), contains('tip'));
      expect(AnswerChecker.feedbackFor(m1, 'b'), contains('short hand'));
      expect(AnswerChecker.feedbackFor(m1, 'c'), contains('Count the hands'));
      for (final h in m1.hints) {
        expect(h, isNot(contains('drawer')));
        expect(h, isNot(contains(' D ')));
      }
      expect(m1.letter, 'My mark is on everything I make.\nA copy is never the same.');
      expect(bench.note, m1.letter);
      expect(m1.evidence!.inscription, startsWith('I changed one clock. I added one small wheel. Now its hands turn the wrong way.'));
      // The split runs between the hands, left to right.
      final xs = [for (final p in bench.mark.split) p.dx];
      expect(xs, orderedEquals([...xs]..sort()));
      expect((xs.first, xs.last), (0, 1254));
    });

    test('M2: in one minute, only Clock III turns back, and only its back has a wheel added', () {
      expect({for (final c in wall.clocks) c.id: c.change}, {'i': 1, 'ii': 5, 'iii': -1, 'iv': 0});
      expect({for (final c in wall.clocks) c.id: (clockTime(c.shows), clockTime(c.after))},
          {'i': ('3:10', '3:11'), 'ii': ('7:25', '7:30'), 'iii': ('10:40', '10:39'), 'iv': ('1:55', '1:55')});
      final backwards = [for (final c in wall.clocks) if (c.change < 0) c.id];
      final wheel = [for (final c in wall.clocks) if (c.back.endsWith('clock_back_extra_wheel.png')) c.id];
      expect(backwards, ['iii']);
      expect(wheel, ['iii']);
      expect({for (final c in wall.clocks) c.id: c.back.split('/').last},
          {'i': 'clock_back_normal.png', 'ii': 'clock_back_spring.png', 'iii': 'clock_back_extra_wheel.png', 'iv': 'clock_back_broken.png'});
      expect(m2.answer, 'iii');
      for (final o in m2.options) {
        expect(AnswerChecker.isCorrect(m2, o.id), o.id == 'iii');
        if (o.id != 'iii') expect(o.feedback, isNotNull, reason: o.id);
      }
      expect(m2.letter, 'I changed one clock.\nI added one small wheel.\nNow its hands turn the wrong way.');
      expect(wall.watch.inSeconds, inInclusiveRange(5, 8));
      expect(wall.later, 'ONE MINUTE LATER…');
      expect(wall.watchLabel, 'WATCH THE CLOCKS');
    });

    test('M3, very easy: one blotted note, read with a tap on the mirror; then Clock II or Clock III; Clock III opened', () {
      expect([for (final s in steps3.steps) s.id], ['mirror', 'clock']);
      final [mirror, clock] = steps3.steps;
      // One note, backwards on the blotter: the maker's own words.
      expect(mirror.say, 'Tap the mirror.');
      expect(mirror.does, EasyDo.tap);
      expect(mirror.target!.panel, 'mirror');
      final blotted = mirror.panels.first as PicturePanel;
      expect(blotted.picture.file, blotter.desk);
      expect(blotted.picture.view, blotter.blotter, reason: 'the blotting paper, whole');
      expect([for (final w in blotted.writing) w.text].join(' '), 'THE CLOCK THAT TURNS BACK.');
      expect(blotted.writing.every((w) => w.mirrored), isTrue, reason: 'backwards, as blotted');
      for (final w in blotted.writing) {
        expect(blotter.blotter.contains(w.at.topLeft) && blotter.blotter.contains(w.at.bottomRight), isTrue, reason: w.text);
      }
      final brown = blotter.notes.singleWhere((n) => n.mark == MarkCopy.exact);
      expect(brown.lines.join(' ').toUpperCase(), contains('THE CLOCK THAT TURNS BACK'), reason: "the maker's own note");
      // Tapped: the words in the mirror's glass, the right way round.
      expect(mirror.done, 'THE CLOCK THAT TURNS BACK.');
      final read = mirror.after!.last as PicturePanel;
      expect(read.picture.file, blotter.mirror);
      expect(read.writing.any((w) => w.mirrored), isFalse);
      expect([for (final w in read.writing) w.text].join(' '), 'THE CLOCK THAT TURNS BACK.');
      final glass = Rect.fromCircle(center: blotter.glassCentre, radius: blotter.glassRadius);
      for (final w in read.writing) {
        for (final corner in [w.at.topLeft, w.at.topRight, w.at.bottomLeft, w.at.bottomRight]) {
          expect((corner - blotter.glassCentre).distance, lessThanOrEqualTo(blotter.glassRadius), reason: '${w.text}: in the glass');
        }
        expect(glass.contains(w.at.center), isTrue);
      }
      // Which clock: Clock II and Clock III as they hang on the wall, each
      // with what M2 found, under the mirror's words.
      expect(clock.say, 'Which clock?');
      expect([for (final o in clock.options) o.label], ['CLOCK II\nruns fast', 'CLOCK III\nturns back']);
      expect(clock.answer, 'iii');
      final words = clock.panels.single as PaperPanel;
      expect([for (final l in words.lines) l.text], ['THE CLOCK THAT TURNS BACK.']);
      for (final o in clock.options) {
        final card = o.panel! as PicturePanel;
        final c = wall.clocks.firstWhere((c) => c.id == o.id);
        expect(card.picture.file, wall.wall);
        final dial = Rect.fromCircle(center: c.centre, radius: c.radius);
        expect(card.picture.view.contains(dial.topLeft) && card.picture.view.contains(dial.bottomRight), isTrue, reason: '${o.id}: its dial');
        final plate = Rect.fromLTRB(c.plateAt.left * 1536, c.plateAt.top * 1024, c.plateAt.right * 1536, c.plateAt.bottom * 1024);
        expect(card.picture.view.contains(plate.topLeft) && card.picture.view.contains(plate.bottomRight), isTrue, reason: '${o.id}: its plate');
        expect(card.writing.single.text, c.numeral);
        expect(plate.contains(card.writing.single.at.topLeft) && plate.contains(card.writing.single.at.bottomRight), isTrue, reason: '${o.id}: its numeral on its plate');
        for (final other in wall.clocks.where((x) => x.id != o.id)) {
          expect(card.picture.view.contains(other.centre), isFalse, reason: '${o.id}: ${other.id} not on its card');
        }
      }
      expect(m2.options.firstWhere((o) => o.id == 'ii').feedback, startsWith('Clock II runs fast'), reason: 'as M2 found it');
      expect(m2.answer, 'iii', reason: 'Clock III turns back, as M2 found');
      // Clock III opened: the receipt, LETTER No. 4417.
      expect(clock.done, 'Clock III! No letter inside. Only a receipt.');
      final receipt = clock.after!.last as DrawnPanel;
      expect(receipt.drawn, same(blotter.hideaway));
      expect(blotter.hideaway.lines, ['16 MAY', 'ONE LETTER COLLECTED', 'FROM No. 7', 'LETTER No. 4417']);
      expect(blotter.hideaway.tag, 'No. 4417');
      expect((clock.after!.first as PicturePanel).picture.file, blotter.hideawayBack);
      // Nothing of the receipt before Clock III is chosen.
      expect([mirror.say, ...mirror.hints, ?mirror.done, clock.say, ...clock.hints, for (final p in clock.panels) ?p.caption].join(' '), isNot(contains('4417')));
      expect(steps3.answer, m3.answer);
      expect(AnswerChecker.isCorrect(m3, steps3.answer), isTrue);
      expect(m3.question, 'Which clock?');
    });

    test('Final, very easy: letter 4417 found beside 4471; then its trail, to the Louvre post room', () {
      final step = stepsF.steps.single;
      expect(step.say, 'Find letter 4417.');
      expect([for (final o in step.options) o.label], ['LETTER 4471', 'LETTER 4417']);
      expect([for (final o in step.options) (o.panel! as DrawnPanel).drawn], [isA<WrittenPaper>(), isA<WrittenPaper>()]);
      expect((step.option('4471')!.panel! as DrawnPanel).drawn, isA<WrittenPaper>().having((p) => p.lines.join(' '), 'lines', contains('4471')));
      expect((step.option('4417')!.panel! as DrawnPanel).drawn, isA<WrittenPaper>().having((p) => p.lines.join(' '), 'lines', contains('4417')));
      expect(step.answer, '4417');
      expect(step.option('4471')!.feedback, 'This is 4471. Read the numbers again: 4417.');
      final route = step.after!.single as PaperPanel;
      expect(route.title, 'LETTER No. 4417 · 16 MAY');
      expect([for (final l in route.lines) l.text], ['9:00 AM — COLLECTED', '11:00 AM — SORTED', '4:00 PM — HELD', 'LOUVRE POST ROOM']);
      // The trail shown is the slips' own.
      final ours = [for (final id in ['s1', 's2', 's3']) trail.slipOf(id)];
      expect([for (final s in ours) '${s.time} — ${s.record}'], [for (final l in route.lines.take(3)) l.text]);
      expect(ours.last.where, 'LOUVRE POST ROOM');
      expect(stepsF.answer, fin.answer);
      expect(stepsF.finishLabel, 'FOLLOW THE LETTER');
    });

    test('Final: only letter 4417\'s three slips, in time order, make the trail; it stops at the Louvre post room', () {
      final ours = [for (final s in trail.slips) if (s.letter == '4417' && s.date == '16 MAY') s];
      int minutes(String t) {
        final [h, m] = t.replaceAll(RegExp(r' [AP]M$'), '').split(':').map(int.parse).toList();
        return (t.endsWith('PM') && h != 12 ? h + 12 : h) * 60 + m;
      }

      ours.sort((a, b) => minutes(a.time!).compareTo(minutes(b.time!)));
      expect([for (final s in ours) s.id], ['s1', 's2', 's3']);
      expect([for (final s in ours) '${s.record} · ${s.where}'], ['COLLECTED · PASSAGE BOX', 'SORTED · CENTRAL OFFICE', 'HELD · LOUVRE POST ROOM']);
      expect(fin.answer, trail.answerOf({for (final (i, s) in ours.indexed) trail.slots[i]: s.id}));
      expect(AnswerChecker.isCorrect(fin, 'first:s1,second:s2,third:s3'), isTrue);
      expect(AnswerChecker.isCorrect(fin, 'first:s2,second:s1,third:s3'), isFalse);
      // The other two: another letter of another day, and a near number.
      expect({for (final s in trail.slips) if (!ours.contains(s)) s.id: (s.letter, s.date)}, {'s4': ('2903', '3 MAY'), 's5': ('4471', '16 MAY')});
      for (final s in trail.slips) {
        for (final slot in trail.slots) {
          final part = '$slot:${s.id}';
          if (Mission.sequenceIds(fin.answer).contains(part)) continue;
          expect(fin.feedback[part], isNotNull, reason: part);
        }
      }
      expect(AnswerChecker.feedbackFor(fin, 'first:s1,second:s5,third:s3'), contains('4417'));
      expect(AnswerChecker.feedbackFor(fin, 'first:s4,second:s2,third:s3'), contains('3 May'));
      expect(
        fin.evidence!.inscription,
        'Letter No. 4417, 16 May: collected at 9:00 AM, sorted at 11:00 AM, then HELD at the Louvre post room at 4:00 PM. Never delivered.',
      );
      // Its times are the slips' own (Case 06 M1 needs the last).
      for (final s in ours) {
        expect(fin.evidence!.inscription, contains(s.time!), reason: s.id);
      }
      // Saved and read back; unknown slots, slips and doubles are left out.
      final placed = {'first': 's1', 'third': 's5'};
      expect(TrailState.decode(TrailState.encode(placed, trail), trail), placed);
      expect(TrailState.decode('first=s1;second=s1;third=s9;fourth=s2', trail), {'first': 's1'});
      expect(TrailState.decode(null, trail), isEmpty);
    });

    test('nothing is told before its time; who the maker is, and the letter\'s reader and words, never', () {
      // Before M3 is solved: no receipt, no letter number, no post.
      final beforeM3 = [everything([m1, m2]), ...m3.story, m3.letter, m3.question, ...m3.hints, for (final o in m3.options) o.feedback ?? ''].join('\n');
      for (final secret in ['4417', 'receipt', 'LOUVRE', 'Louvre', 'HELD', 'slips']) {
        expect(beforeM3, isNot(contains(secret)), reason: secret);
      }
      // Before the final is solved: where the letter stopped is on its slip
      // only (the data to solve it), never in a story line, clue or hint.
      final beforeFinal = [everything([m1, m2, m3]), ...fin.story, fin.letter, fin.question, ...fin.hints, ...fin.feedback.values].join('\n');
      for (final secret in ['Never delivered', 'never delivered', 'LOUVRE', 'Louvre']) {
        expect(beforeFinal, isNot(contains(secret)), reason: secret);
      }
      final all = everything(case05.allMissions, e: case05);
      for (final banned in ['CLOCKMAKER', 'VANISHED', 'STOLE', 'DEAR ', 'TO: ']) {
        expect(all.toUpperCase(), isNot(contains(banned)), reason: banned);
      }
      // Case 01's gear mark is never set beside the hands.
      expect(all, isNot(contains('gear mark')));
      expect(RegExp(r'(?<![A-Z])M\.').hasMatch(all), isFalse, reason: "the gear mark's M.");
      // Case 02's sketch stays for later: no white church, no Montmartre.
      expect(all.toLowerCase(), isNot(contains('white church')));
      expect(all, isNot(contains('Montmartre')));
      expect(fin.transition.last, 'Who stopped it? And why?');
    });

    test('every word in its glossary is in its text', () {
      // Its text: the missions' words, the clocks' backs read in M2, and
      // what the very-easy steps say and show, dotted too.
      final text = [
        everything(case05.allMissions, e: case05),
        for (final c in wall.clocks) c.backNote,
        easyWords(steps3),
        easyWords(stepsF),
      ].join('\n').toLowerCase();
      for (final w in case05.glossary.keys) {
        expect(text, contains(w), reason: w);
      }
    });

    test('its learning design follows Season 1\'s rules', () {
      String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      String screen(Mission m) => norm([...m.story, m.letterIntro, m.letter, m.question, for (final o in m.options) o.label, ...m.hints].join(' \n '));
      expect(season2Learning.keys.where((id) => id.startsWith('s2_ep05_')).toSet(), {for (final m in case05.allMissions) m.id});
      expect(season2LanguageTopics['s2_ep05'], isNotNull);
      for (final m in case05.allMissions) {
        final l = SeasonCatalog.learning(m)!;
        expect(l.isHonest, isTrue, reason: m.id);
        if (l.dependency == LanguageDependency.essential) expect(l.expressions, isNotEmpty);
        for (final e in l.expressions) {
          expect(screen(m), contains(norm(e)), reason: '${m.id}: "$e" is on its screens');
        }
      }
    });

    test('its evidence leads on from the ledger\'s signature, one piece to the next', () {
      expect(SeasonCatalog.evidenceLink('s2_ep05_e1')!.to, 's2_ep04_e2');
      expect(SeasonCatalog.evidenceLink('s2_ep05_e2')!.to, 's2_ep05_e1');
      expect(SeasonCatalog.evidenceLink('s2_ep05_e3')!.to, 's2_ep05_e2');
      expect(SeasonCatalog.evidenceLink('s2_ep05_e4')!.to, 's2_ep05_e3');
      expect(SeasonCatalog.evidenceLink('s2_ep04_e4')!.to, 's2_ep04_e3', reason: "Case 04's links are as they were");
      for (final m in case05.allMissions) {
        expect(SeasonCatalog.evidenceArt(m.evidence!.id), isA<DrawnEvidenceArt>(), reason: '${m.evidence!.id} is drawn');
      }
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

    test('it opens only once Case 04 is solved', () async {
      final c = await start();
      final game = c.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      for (final e in [case01, case02, case03]) {
        solve(c, e);
      }
      expect(game.openEpisode('s2_ep05'), isFalse, reason: 'no way round Case 04');
      solve(c, case04);
      expect(c.read(seasonProvider.notifier).isUnlocked('s2_ep05'), isTrue);
      expect(game.openEpisode('s2_ep05'), isTrue);
      expect(c.read(currentEpisodeProvider).id, 's2_ep05');
    });

    test('what is compared, watched and the step reached is saved and comes back after a restart', () async {
      var c = await start();
      var game = c.read(gameControllerProvider.notifier);
      game.openSeason(SeasonIds.paris);
      for (final e in [case01, case02, case03, case04]) {
        solve(c, e);
      }
      game.openEpisode('s2_ep05');
      game.startInvestigation();
      game.recordExamined(GameProgress.examinedKey(m1.id, MarkCompareScene.sheetKey('a')));
      expect(game.submitAnswer(m1, 'c').result, SubmitResult.tryAgain);
      expect(game.submitAnswer(m2, m2.answer).result, SubmitResult.locked, reason: 'missions in order');
      expect(game.submitAnswer(m1, m1.answer).result, SubmitResult.correct);
      game.recordExamined(GameProgress.examinedKey(m2.id, ClockWallScene.watchedId));
      game.recordExamined(GameProgress.examinedKey(m2.id, ClockWallScene.backKey('iii')));
      expect(game.submitAnswer(m2, m2.answer).result, SubmitResult.correct);
      // M3 left with the mirror read (one step done).
      game.recordPuzzleState(m3.id, EasyStepsState.encode(1));
      // An old save of the final: two slips set on the trail.
      game.recordPuzzleState(fin.id, TrailState.encode({'first': 's1', 'second': 's5'}, trail));

      c.dispose();
      c = await start();
      game = c.read(gameControllerProvider.notifier);
      expect(c.read(currentEpisodeProvider).id, 's2_ep05');
      var p = c.read(gameControllerProvider);
      expect(p.isCompleted(m1.id) && p.isCompleted(m2.id), isTrue);
      expect(p.wrongCount(m1.id), 1);
      expect(p.hasExamined('${m1.id}:sheet-a'), isTrue);
      expect(p.hasExamined('${m2.id}:watched') && p.hasExamined('${m2.id}:back-iii'), isTrue);
      expect(EasyStepsState.decode(p.puzzleStateOf(m3.id), steps3), 1, reason: 'back on which clock');
      expect(EasyStepsState.decode(p.puzzleStateOf(fin.id), stepsF), 0, reason: 'an old save starts the steps at the first');

      for (final m in [m3, fin]) {
        expect(game.submitAnswer(m, m.answer).result, SubmitResult.correct, reason: m.id);
      }
      p = c.read(gameControllerProvider);
      expect([for (final e in p.collectedEvidence(case05)) e.name], ['The Repair Card', 'The Backward Clock', 'The Blotted Note', "The Letter's Trail"]);
      expect(p.isCaseSolved, isTrue);
      expect(c.read(progressRepositoryProvider).load('s2_ep04').isCaseSolved, isTrue, reason: "Case 04's save is its own");
    });

    test('solved: Paris is 5 of 12, Case 06 opens next; London is as it was', () async {
      final c = await start();
      final game = c.read(gameControllerProvider.notifier);
      game.openSeason(SeasonIds.paris);
      for (final e in [case01, case02, case03, case04, case05]) {
        solve(c, e);
      }
      final board = c.read(seasonOverviewProvider);
      expect(board.solvedCount, 5);
      expect(board.comingSoonCase, isNot(6), reason: 'Case 06 is in the game (2026-10-22)');
      final paris = c.read(seasonAvailabilityProvider(SeasonIds.paris))!;
      expect((paris.solvedCount, paris.plannedCount), (5, 12));
      expect(game.openEpisode('s2_ep06'), isTrue, reason: 'Case 06 opens after Case 05');
      expect(c.read(progressRepositoryProvider).loadSeason(SeasonIds.london).solvedEpisodeIds, hasLength(12));
    });
  });

  group('a child plays Case 05', () {
    Future<WidgetRef> open(WidgetTester t, Size size, {bool still = false}) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      if (still) {
        t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      }
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
      for (final e in [case01, case02, case03, case04]) {
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
      testWidgets('$tag: Case 04 closed → workbench → clocks → blotter and Clock III → slips, 5 of 12', (t) async {
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
            File('$shots/paris05_${tag}_${(n++).toString().padLeft(2, '0')}_$name.png').writeAsBytesSync(png!.buffer.asUint8List());
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

        void nothingOfTheLetter(String where) {
          expect(find.textContaining('4417', findRichText: true), findsNothing, reason: where);
          expect(find.textContaining('LOUVRE', findRichText: true), findsNothing, reason: where);
        }

        // ── Case 04's Case Closed: on to Case 05 ────────────────────────
        router.go(Routes.solvedSettled);
        await wait(t, const Duration(milliseconds: 3000));
        await reveal(t, find.text('OPEN CASE 05'));
        expect(find.text('OPEN CASE 05'), findsOneWidget, reason: 'Case 05 is in the game now');
        await shot('case04_closed');
        expect(game.openEpisode('s2_ep05'), isTrue);

        // ── The opening ─────────────────────────────────────────────────
        router.go(Routes.intro);
        await wait(t, const Duration(milliseconds: 900));
        await tapText(t, 'SKIP ›', after: const Duration(milliseconds: 900));
        expect(find.text('Do not trust the clocks. Follow the hands that made them.'), findsOneWidget);
        await shot('opening');
        await tapText(t, "I'M READY", after: const Duration(milliseconds: 1600));

        // ── M1: the workbench ───────────────────────────────────────────
        await visit(m1.id);
        expect(find.byKey(const ValueKey('story-picture')), findsOneWidget, reason: 'the workshop');
        await shot('m1_place');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('maker-note')), findsOneWidget);
        nothingOfTheLetter('M1');
        await shot('m1_bench');
        // Nothing is chosen before the sheet is laid on every stamp.
        expect(find.byKey(const ValueKey('choices-locked')), findsOneWidget);
        await tapKey('bench-d');
        expect(t.widget<GameButton>(find.byKey(const ValueKey('bench-check'))).onPressed, isNull, reason: 'not compared yet');
        await tapKey('seal-spot-b', after: const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('seal-close-b')), findsOneWidget);
        await shot('m1_stamp_b');
        // The sheet dragged over the stamp settles on it.
        final sheet = t.getCenter(find.byKey(const ValueKey('tracing-sheet')));
        final stamp = t.getCenter(find.byKey(const ValueKey('seal-close-b')));
        final drag = await t.startGesture(sheet);
        for (var i = 1; i <= 10; i++) {
          await drag.moveTo(Offset.lerp(sheet, sheet + (stamp - sheet) * 0.75, i / 10)!);
          await t.pump(const Duration(milliseconds: 16));
        }
        await drag.up();
        await wait(t, const Duration(milliseconds: 500));
        expect(examined(), contains('s2_ep05_m1:sheet-b'));
        expect(find.text('LIFT THE SHEET'), findsOneWidget);
        await shot('m1_sheet_on_b');
        await tapKey('seal-close-done');
        for (final id in ['a', 'c', 'd']) {
          await tapKey('seal-spot-$id', after: const Duration(milliseconds: 600));
          await tapKey('seal-close-lay', after: const Duration(milliseconds: 500));
          if (id == 'd') await shot('m1_sheet_on_d');
          await tapKey('seal-close-done');
        }
        expect(examined(), containsAll(['s2_ep05_m1:sheet-a', 's2_ep05_m1:sheet-c', 's2_ep05_m1:sheet-d']));
        expect(find.byKey(const ValueKey('choices-locked')), findsNothing, reason: 'all four compared');
        await tapKey('bench-c');
        await tapKey('bench-check');
        await wrongThenTryAgain('Count the hands', 'm1');
        await tapKey('bench-d');
        await tapKey('bench-check');
        await finish(m1.transition.first, 'm1');
        expect(ref.read(gameControllerProvider).isCompleted(m1.id), isTrue);

        // ── M2: the wall of clocks ──────────────────────────────────────
        await visit(m2.id);
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('repair-card-note')), findsOneWidget);
        expect(find.byKey(const ValueKey('clocks-later')), findsNothing);
        expect(t.widget<GameButton>(find.byKey(const ValueKey('clocks-check'))).onPressed, isNull, reason: 'a clock chosen first');
        // Nothing is chosen before the minute is watched.
        expect(find.byKey(const ValueKey('choices-locked')), findsOneWidget);
        await tapKey('clock-iii');
        expect(t.widget<GameButton>(find.byKey(const ValueKey('clocks-check'))).onPressed, isNull, reason: 'not watched yet');
        await shot('m2_wall');
        await tapKey('clocks-watch', after: const Duration(milliseconds: 1500));
        expect(find.byKey(const ValueKey('clocks-watching')), findsOneWidget, reason: 'the minute plays');
        await shot('m2_watching');
        await wait(t, const Duration(seconds: 5));
        expect(find.text('ONE MINUTE LATER…'), findsOneWidget);
        expect(examined(), contains('s2_ep05_m2:watched'));
        expect(find.byKey(const ValueKey('choices-locked')), findsNothing, reason: 'watched');
        for (final c in wall.clocks) {
          expect(find.byKey(ValueKey('clock-time-${c.id}')), findsOneWidget);
        }
        expect(find.text('now 10:39'), findsOneWidget);
        await shot('m2_later');
        await tapKey('clock-spot-ii', after: const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('clock-back-ii')), findsOneWidget);
        expect(findReadable('A big, shiny spring.'), findsOneWidget);
        await tapKey('clock-back-done');
        await tapKey('clock-spot-iii', after: const Duration(milliseconds: 600));
        expect(findReadable('A small brass wheel at the side of the gears.'), findsOneWidget);
        await shot('m2_back_iii');
        await tapKey('clock-back-done');
        expect(examined(), containsAll(['s2_ep05_m2:back-ii', 's2_ep05_m2:back-iii']));
        await tapKey('clock-ii');
        await tapKey('clocks-check');
        await wrongThenTryAgain('runs fast', 'm2');
        // Out and back: the minute stays watched.
        router.go(Routes.map);
        await wait(t, const Duration(milliseconds: 1400));
        await visit(m2.id);
        expect(find.text('ONE MINUTE LATER…'), findsOneWidget, reason: 'saved: watched');
        expect(find.text(wall.againLabel), findsOneWidget);
        await tapKey('clock-iii');
        await tapKey('clocks-check');
        await finish(m2.transition.first, 'm2');

        // ── M3: the mirror, then which clock (very easy) ────────────────
        final play = EasyPlay(t, 'c05_$tag');
        await visit(m3.id);
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        play.expectSay('Tap the mirror.');
        expect(find.byKey(const ValueKey('easy-panel-blotter')), findsOneWidget);
        expect(find.byKey(const ValueKey('easy-panel-mirror')), findsOneWidget);
        nothingOfTheLetter('M3');
        final mirrorPicture = (steps3.steps.first.panels.last as PicturePanel).picture;
        final reach = play.sizeOn('mirror', mirrorPicture, mirrorPicture.view);
        expect(reach.width >= 44 && reach.height >= 44, isTrue, reason: '$tag: the mirror is finger-sized ($reach)');
        await shot('m3_blotter');
        await play.tapOn('mirror', mirrorPicture, null);
        expect(findReadable('THE CLOCK THAT TURNS BACK.'), findsOneWidget, reason: 'read in the mirror');
        nothingOfTheLetter('M3, the mirror read');
        await shot('m3_mirror_read');
        await play.next();
        play.expectSay('Which clock?');
        expect(findReadable('THE CLOCK THAT TURNS BACK.'), findsOneWidget, reason: "the mirror's words over the clocks");
        expect(find.text('CLOCK III\nturns back'), findsOneWidget);
        finger('easy-option-ii');
        finger('easy-option-iii');
        await play.tapKey('easy-option-ii');
        expect(findReadable('Clock II runs fast. Which clock turns back?'), findsOneWidget);
        expect(ref.read(gameControllerProvider).wrongCount(m3.id), 0, reason: 'a wrong answer costs nothing');
        await shot('m3_wrong');
        await play.tapKey('easy-option-iii');
        expect(findReadable('Clock III! No letter inside. Only a receipt.'), findsOneWidget);
        expect(find.textContaining('4417', findRichText: true), findsWidgets, reason: 'the receipt: LETTER No. 4417');
        expect(find.textContaining('LOUVRE'), findsNothing);
        await shot('m3_clock3');
        await play.next();
        await finish(m3.transition.first, 'm3');
        expect(ref.read(gameControllerProvider).isCompleted(m3.id), isTrue);

        // ── Final: letter 4417, then its trail (very easy) ──────────────
        router.go(Routes.finalMission);
        await wait(t, const Duration(milliseconds: 1600));
        play.expectSay('Find letter 4417.');
        expect(find.textContaining('LOUVRE'), findsNothing, reason: 'where it stopped, only once it is found');
        await shot('final_find');
        await play.tapKey('easy-option-4471');
        expect(findReadable('This is 4471. Read the numbers again: 4417.'), findsOneWidget);
        expect(ref.read(gameControllerProvider).wrongCount(fin.id), 0);
        await play.tapKey('easy-option-4417');
        expect(findReadable('Letter 4417! Here is where it went.'), findsOneWidget);
        for (final line in ['9:00 AM — COLLECTED', '11:00 AM — SORTED', '4:00 PM — HELD', 'LOUVRE POST ROOM']) {
          expect(find.text(line), findsOneWidget, reason: 'the trail, at once: $line');
        }
        await shot('final_trail');
        expect(find.text('FOLLOW THE LETTER'), findsOneWidget);
        await play.next(after: const Duration(milliseconds: 3600));
        expect(ref.read(gameControllerProvider).isCaseSolved, isTrue);
        expect(find.byKey(const ValueKey('trail-held')), findsOneWidget, reason: 'the slip that says where it stopped');
        await shot('final_solved');
        await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 900));
        expect(find.text(fin.transition.first), findsOneWidget);
        await t.tapAt(Offset(size.width / 2, size.height / 2));
        await wait(t, const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('scene-backdrop')), findsOneWidget, reason: 'the workshop');
        await shot('final_scene');
        await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 4000));
        // Case 06 is in the game (2026-10-22): its case opens from here.
        await reveal(t, find.text('OPEN CASE 06'));
        expect(find.text('OPEN CASE 06'), findsOneWidget);
        await shot('case_closed');

        final board = ref.read(seasonOverviewProvider);
        expect(board.solvedCount, 5);
        expect(game.openEpisode('s2_ep06'), isTrue);
        await wait(t, const Duration(seconds: 3));
      });
    }

    testWidgets('reduce motion: one minute of the clocks is over at once, its times said', (t) async {
      final ref = await open(t, const Size(390, 844), still: true);
      final game = ref.read(gameControllerProvider.notifier);
      expect(game.openEpisode('s2_ep05'), isTrue);
      game.startInvestigation();
      game.submitAnswer(m1, m1.answer);
      ref.read(routerProvider).go(Routes.mission(m2.id));
      await wait(t, const Duration(milliseconds: 1400));
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 300));
      await reveal(t, find.byKey(const ValueKey('clocks-watch')));
      await t.tap(find.byKey(const ValueKey('clocks-watch')));
      await t.pump();
      await t.pump();
      expect(find.byKey(const ValueKey('clocks-watching')), findsNothing, reason: 'no motion: at once');
      expect(find.text('ONE MINUTE LATER…'), findsOneWidget);
      expect(find.text('was 10:40'), findsOneWidget);
      expect(find.text('now 10:39'), findsOneWidget);
      expect(ref.read(gameControllerProvider).hasExamined('${m2.id}:watched'), isTrue);
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 2));
    });
  });
}
