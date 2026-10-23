import 'dart:convert';
import 'dart:io';
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
import 'package:london_mystery/data/models/river_puzzles.dart';
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/mission_map/map_world.dart';
import 'package:london_mystery/features/season/season_overview.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/game_button.dart';
import 'package:london_mystery/widgets/ink_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';

/// Season 2, Case 04 — The River's Secret: its eighteen pictures (the
/// marks, the label's outline measured on them), its story and puzzles as
/// the stones and papers say them, its rules (unlock, saves, Case 05 next),
/// and a child playing it through on three phones. The label's
/// last piece is never shown before the final is solved.
///
/// `LM_SHOTS=folder` saves a picture of each step of the play-through.
void main() {
  final inGame = MockEpisodeRepository.bundled();
  final s1 = season1Cases();
  final [case01, case02, case03, case04] = [for (final id in ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04']) inGame.firstWhere((e) => e.id == id)];
  final [m1, m2, m3, fin] = case04.allMissions;
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
          m.orderFeedback ?? '',
          m.clue?.note ?? '',
          m.evidence?.description ?? '',
          m.evidence?.inscription ?? '',
        ],
      ].join('\n');

  final marks = SeasonCatalog.riverMarks(m1)!;
  final hut = SeasonCatalog.keeperHut(m2)!;
  final boxes = SeasonCatalog.quayBoxes(m3)!;
  final book = SeasonCatalog.streetBook(fin)!;
  final label = boxes.label;

  group('its pictures', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const folder = 'assets/seasons/season_02_paris/cases/case_04';
    // Size, and whether it is cut out on transparency (as delivered).
    const pictures = {
      'seine_quays_dusk.png': (1536, 1024, false),
      'quay_wall_marks.png': (1536, 1024, false),
      'river_mark_a.png': (1254, 1254, false),
      'river_mark_b.png': (1254, 1254, false),
      'river_mark_c.png': (1254, 1254, false),
      'river_mark_d.png': (1254, 1254, false),
      'brass_plaque_back.png': (1536, 1024, true),
      'keeper_hut.png': (1536, 1024, false),
      'keeper_hut_interior.png': (1536, 1024, false),
      'keeper_ledger.png': (1536, 1024, true),
      'quay_boxes.png': (1536, 1024, false),
      'metal_box_open.png': (1536, 1024, false),
      'delivery_label_blank.png': (1377, 1142, true),
      'delivery_label_back.png': (1377, 1142, true),
      'decoy_label_piece.png': (1842, 854, true),
      'street_book.png': (1024, 1536, true),
      'passage_gate.png': (1024, 1536, true),
      'hands_sign.png': (1254, 1254, true),
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

    test('all eighteen are in, listed in pubspec, at their sizes, cut out where they are papers or parts', () {
      expect(pubspecAssets(), contains('$folder/'), reason: 'its folder, exactly, in flutter: assets:');
      expect(Directory(folder).listSync().whereType<File>().where((f) => f.path.endsWith('.png')).length, 18);
      for (final MapEntry(key: name, value: (w, h, cutOut)) in pictures.entries) {
        final file = File('$folder/$name');
        expect(file.existsSync(), isTrue, reason: name);
        final (pw, ph, alpha) = header(file.readAsBytesSync());
        expect((pw, ph), (w, h), reason: name);
        expect(alpha, cutOut, reason: name);
      }
    });

    test('every one of them is played on', () {
      final played = {
        marks.wall,
        for (final m in marks.marks) m.closeUp,
        marks.plaqueBack.file,
        hut.outside,
        hut.inside,
        hut.ledger,
        hut.hands,
        boxes.picture,
        boxes.open,
        boxes.decoy,
        label.file,
        label.back,
        book.book,
        book.gate,
        ArtAssets.scenes[case04.introScene]!,
      };
      expect({for (final f in played) f.split('/').last}, {...pictures.keys});
      expect(ArtAssets.scenes[Artwork.seineQuays], endsWith('case_04/seine_quays_dusk.png'));
    });

    test('the plaque\'s back has the front\'s outline; the label\'s back is a little wider round the same card', () async {
      double differ(ByteData a, ByteData b, int w, int h) {
        var n = 0, total = 0;
        for (var y = 0; y < h; y += 2) {
          for (var x = 0; x < w; x += 2) {
            final i = (y * w + x) * 4 + 3;
            if ((a.getUint8(i) > 127) != (b.getUint8(i) > 127)) n++;
            total++;
          }
        }
        return n / total;
      }

      final (front, fw, fh) = await pixels('assets/seasons/season_02_paris/cases/case_03/brass_plaque.png');
      final (back, _, _) = await pixels('$folder/brass_plaque_back.png');
      expect(differ(front, back, fw, fh), lessThan(0.01), reason: 'the same plaque turned over');
      final (blank, lw, lh) = await pixels('$folder/delivery_label_blank.png');
      final (lback, _, _) = await pixels('$folder/delivery_label_back.png');
      // Not cut on one outline (measured 3.6%): the back is drawn on its own,
      // a little wider. The last piece's back is its own outline, turned over.
      expect(differ(blank, lback, lw, lh), lessThan(0.05));
      // Paper where the tears run (measured edges), and under the last piece.
      int alpha(ByteData d, double x, double y) => d.getUint8((y.round() * lw + x.round()) * 4 + 3);
      for (final y in [label.tear1, label.tear2, label.tear3]) {
        expect(alpha(blank, label.paperLeft + 5, y), greaterThan(200), reason: 'left edge at $y');
        expect(alpha(blank, label.paperRight - 5, y), greaterThan(200), reason: 'right edge at $y');
      }
      expect(alpha(blank, 900, label.paperBottom - 5), greaterThan(200));
      expect(alpha(lback, lw - 900, label.paperBottom - 5), greaterThan(200), reason: 'the corner turned over is paper too');
    });

    test('every place tapped or written on is inside its picture', () {
      void inside(Rect r, String what) {
        expect(r.left >= 0 && r.top >= 0 && r.right <= 1 && r.bottom <= 1 && r.width > 0 && r.height > 0, isTrue, reason: what);
      }

      for (final m in marks.marks) {
        inside(m.area, m.id);
        inside(m.wordAt, '${m.id} word');
        expect(m.area.contains(m.wordAt.center), isTrue, reason: '${m.id}: its word is on it');
        inside(m.closeWordAt, '${m.id} close word');
      }
      inside(marks.signAt, 'sign');
      inside(hut.doorArea, 'door');
      inside(hut.ledgerArea, 'ledger');
      for (final p in hut.pages) {
        inside(p.crop, p.title);
        expect(p.crop.contains(p.writeOn.topLeft) && p.crop.contains(p.writeOn.bottomRight), isTrue, reason: p.title);
      }
      for (final b in boxes.boxes) {
        inside(b.area, b.id);
        expect(b.area.contains(b.plateAt.center), isTrue, reason: '${b.id}: its plate is on it');
        expect(boxes.view.contains(b.area.center), isTrue, reason: '${b.id} is in view');
      }
      for (final p in book.pages) {
        inside(p, 'book page');
      }
      inside(book.signAt, 'gate sign');
      inside(book.scrapAt, 'gate bar');
      expect(book.gateView.contains(book.signAt.center), isTrue, reason: 'the sign is on the stage');
    });
  });

  group('the case', () {
    test('Case 04 is in the game, after Case 03, on the Seine, with its four puzzles', () {
      expect(SeasonCatalog.byId(SeasonIds.paris)!.episodes.keys, ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05', 's2_ep06', 's2_ep07']);
      expect(case04.number, 4);
      expect(case04.title, "The River's Secret");
      expect(case04.place, 'SEINE QUAYS · PARIS');
      expect(case04.introScene, Artwork.seineQuays);
      expect([for (final m in case04.allMissions) m.id], ['s2_ep04_m1', 's2_ep04_m2', 's2_ep04_m3', 's2_ep04_final']);
      expect([for (final m in case04.allMissions) m.type],
          [MissionType.multipleChoice, MissionType.multipleChoice, MissionType.matchPairs, MissionType.matchPairs]);
      expect([for (final m in case04.allMissions) m.evidence!.name],
          ['The River Mark', "The Keeper's Ledger", 'The Torn Delivery Label', 'The Workshop Address']);
      expect(ParisLandmark.cases['s2_ep04'], ParisLandmark.seineQuays);
      expect(ParisLandmark.cases['s2_ep05'], ParisLandmark.notreDame, reason: 'Case 05 keeps its place');
      expect(SeasonMap.landmarkOf(m1.id), ParisLandmark.seineQuays);
      // Case 05 is in the game now (2026-10-21): no title waits for it.
      expect(SeasonCatalog.byId(SeasonIds.paris)!.season.upcomingTitles[5], isNull);
      expect(inGame.firstWhere((e) => e.id == 's2_ep05').title, 'The Silent Workshop');
    });

    test('the opening turns the plaque over, in the second person; Case 03 is as it was', () {
      expect(case04.intro, [
        'Three small waves. One word: SEINE.',
        'You hold the brass plaque up to a street lamp.',
        'On its back, someone has scratched three short lines.',
        'The river is only a short walk away.',
        'Old stone walls. Green bookstalls. Dark, quiet water.',
        'Somewhere on these quays, a mark is waiting for you.',
      ]);
      final plaque = SeasonCatalog.introPlaque('s2_ep04')!;
      expect(plaque.afterLine, 2);
      expect(plaque.plaque.lines, ['Three waves mark the place.', 'Follow the arrow towards the river.', 'Find the one who watches the water.']);
      expect(m1.letter.split('\n'), plaque.plaque.lines);
      for (final line in [...case04.intro, ...case04.synopsis, ...case04.objectives, for (final m in case04.allMissions) ...m.story]) {
        expect(RegExp(r"\bI\b|\bI'm\b|\bmy\b").hasMatch(line), isFalse, reason: 'second person: $line');
      }
      final c03 = case03.finalMission.evidence!;
      expect(c03.inscription, 'ONE HOUR IS MISSING. THE CLOCK IS STILL RUNNING. Under three small waves: SEINE.');
      expect(case03.finalMission.transition.last, 'And why does it lead to the river?');
    });

    test('M1: each wrong mark breaks one line of the plaque; only Mark D keeps all three', () {
      int broken(RiverMark m) => [m.waves != 3, !m.arrowDown, m.word != 'RIVER KEEPER'].where((b) => b).length;
      expect({for (final m in marks.marks) m.id: broken(m)}, {'a': 1, 'b': 1, 'c': 1, 'd': 0});
      expect({for (final o in m1.options) o.id}, {for (final m in marks.marks) m.id});
      expect(m1.answer, 'd');
      for (final o in m1.options) {
        expect(AnswerChecker.isCorrect(m1, o.id), o.id == 'd');
        if (o.id != 'd') expect(AnswerChecker.feedbackFor(m1, o.id), isNotNull, reason: o.id);
      }
      for (final h in m1.hints) {
        expect(h, isNot(contains('Mark D')));
        expect(h, isNot(contains(' D ')));
      }
      expect(marks.sign, 'QUAY 3');
      expect(m1.evidence!.inscription, contains("the keeper's steps go down to the water. QUAY 3."));
    });

    test('M2: of the crates from the tower, only one is on Quay 3, and it was moved; page 2 says where it went', () {
      final [page1, page2] = hut.pages;
      final fromTower = [for (final e in page1.entries) if (e.words.contains('Eiffel Tower')) e];
      expect(fromTower, hasLength(3));
      final onQuay3 = [for (final e in fromTower) if (e.words.contains('Quay 3')) e];
      expect(onQuay3.single.boxes, ['box17']);
      expect(page1.entries.last.words, 'Box 17 moved to Box 23. Quay 3.');
      expect(page1.entries.last.hands && onQuay3.single.hands, isTrue, reason: 'both signed with the clock hands');
      expect(m2.answer, 'box23');
      for (final o in m2.options) {
        expect(AnswerChecker.isCorrect(m2, o.id), o.id == 'box23');
        if (o.id != 'box23') expect(o.feedback, isNotNull, reason: o.id);
      }
      expect({for (final e in page1.entries) ...e.boxes}, {for (final o in m2.options) o.id});
      expect(page2.entries.last.words, "Box 23 — collected for No. 7. Delivery: through the keeper's steps.");
      // Before the answer, nothing on the mission's pages says page 2's line.
      final before = [...m2.story, m2.letter, m2.question, ...m2.hints, for (final o in m2.options) o.feedback ?? ''].join(' ');
      expect(before, isNot(contains('No. 7')));
      expect(before, isNot(contains('collected')));
      // Saved and read back.
      expect(HutState.decode(HutState.encode(HutStep.ledger, 'box17'), hut), (HutStep.ledger, 'box17'));
      expect(HutState.decode('at=roof;box=box99', hut), (HutStep.outside, null));
      expect(HutState.decode(null, hut), (HutStep.outside, null));
    });

    test('M3: only Box 23 opens; the label goes FROM, CONTENTS, TO; the blue-grey scrap fits nowhere', () {
      expect([for (final b in boxes.boxes) if (b.note == null) b.id], ['box23']);
      expect([for (final b in boxes.boxes) b.number], ['12', '17', '21', '23']);
      expect(AnswerChecker.isCorrect(m3, 'p1:top,p2:middle,p3:bottom'), isTrue);
      expect(AnswerChecker.isCorrect(m3, boxes.answerOf({'top': 'p1', 'middle': 'p2', 'bottom': 'p3'})), isTrue);
      const pieces = ['p1', 'p2', 'p3', 'decoy'];
      for (final p in pieces) {
        for (final s in boxes.slots) {
          final part = '$p:$s';
          if (Mission.sequenceIds(m3.answer).contains(part)) continue;
          expect(m3.feedback[part], isNotNull, reason: part);
        }
      }
      expect(AnswerChecker.feedbackFor(m3, 'decoy:top,p2:middle,p3:bottom'), contains('different paper'));
      expect([for (final l in label.lines) l.text], [
        'PARIS PARCEL SERVICE',
        'FROM: EIFFEL TOWER',
        'SERVICE LEVEL',
        'CONTENTS: CLOCK PARTS',
        'HANDLE WITH CARE',
        'TO: THE WATCHMAKERS',
      ]);
      expect((label.addressStart, label.addressRest), ('PASSAGE D', 'ES HORLOGERS'));
      expect(boxes.decoyLines, ['TO: BOOKSTALL 12', 'QUAY 1']);
      // Saved and read back; a piece set twice keeps its first slot.
      final placed = {'top': 'p1', 'bottom': 'decoy'};
      expect(LabelState.decode(LabelState.encode(placed, boxes), boxes), placed);
      expect(LabelState.decode('top=p1;middle=p1;bottom=p9', boxes), {'top': 'p1'});
    });

    test('Final: each wrong address is ruled out by its own evidence; only PASSAGE DES HORLOGERS is left', () {
      // What each piece of evidence says, as the book's lines are read.
      bool fitsLabel(StreetEntry e) => e.name.startsWith(label.addressStart);
      bool hasNo7(StreetEntry e) {
        final m = RegExp(r'Houses (\d+) to (\d+)\.').firstMatch(e.lines.join(' '))!;
        return int.parse(m.group(1)!) <= 7 && 7 <= int.parse(m.group(2)!);
      }

      bool gateOnKeepersSteps(StreetEntry e) => !e.lines.any((l) => l.contains('Its gate')) || e.lines.any((l) => l.contains("keeper's steps, Quay 3"));
      final ruledOut = {
        for (final e in book.entries)
          e.id: !fitsLabel(e)
              ? 'e3'
              : !hasNo7(e)
              ? 'e2'
              : !gateOnKeepersSteps(e)
              ? 'e1+e2'
              : null,
      };
      expect(ruledOut, {'quai': 'e3', 'pont': 'e1+e2', 'horloge': 'e2', 'horlogers': null});
      expect(fin.answer, [for (final e in ruledOut.entries) if (e.value != null) '${e.key}:${e.value}'].join(','));
      // Each needs its own: M1 (where the keeper's steps are), M2 (the
      // delivery and No. 7), M3 (PASSAGE D…).
      expect({for (final v in ruledOut.values.nonNulls) ...v.split('+')}, {'e1', 'e2', 'e3'});
      expect(fin.evidence!.inscription, contains('PASSAGE DES HORLOGERS'));
      // The book's answer, and every wrong way to cross an address out says
      // something.
      final crossed = {'quai': {'e3'}, 'pont': {'e2', 'e1'}, 'horloge': {'e2'}};
      expect(book.answerOf(crossed), fin.answer);
      expect(AnswerChecker.isCorrect(fin, book.answerOf(crossed)), isTrue);
      const subsets = ['e1', 'e2', 'e3', 'e1+e2', 'e1+e3', 'e2+e3'];
      for (final e in book.entries) {
        for (final s in subsets) {
          final part = '${e.id}:$s';
          if (Mission.sequenceIds(fin.answer).contains(part)) continue;
          expect(fin.feedback[part], isNotNull, reason: part);
          expect(AnswerChecker.isCorrect(fin, part), isFalse);
        }
      }
      expect(book.maxEvidence, 2);
      // Saved and read back; three pieces at once is more than allowed.
      expect(CrossOutState.decode(CrossOutState.encode(crossed, book), book), crossed);
      expect(CrossOutState.decode('quai=e1+e2+e3;pont=e1+e9;nowhere=e1', book), {'pont': {'e1'}});
      // The real Quai de l'Horloge is named; its houses are the keeper's
      // book's (said in the data, never as fact elsewhere).
      expect(File('lib/data/mock/season2/episode04_mock.dart').readAsStringSync(), contains("never given as fact"));
    });

    test('the last piece and its message are never told before the final is solved', () {
      final before = [
        everything([m1, m2, m3]),
        ...fin.story,
        fin.letter,
        fin.letterIntro,
        fin.question,
        ...fin.hints,
        ...fin.feedback.values,
        for (final m in case04.allMissions) m.clue?.note ?? '',
        m3.evidence!.inscription!,
        for (final e in case04.missions) SeasonCatalog.evidenceLink(e.evidence!.id)!.line,
      ].join('\n');
      for (final secret in ['ES HORLOGERS', 'Do not trust', 'hands that made', 'DES HORLOGERS']) {
        expect(before, isNot(contains(secret)), reason: secret);
      }
      expect(m3.evidence!.inscription, contains('PASSAGE D… The rest is torn off.'));
      // After: the gate, its message, the evidence.
      expect(fin.transition, containsAllInOrder(['PASSAGE DES HORLOGERS.', 'Do not trust the clocks.', 'Follow the hands that made them.']));
      expect(label.backLines.join(' '), 'Do not trust the clocks. Follow the hands that made them.');
      final all = everything(case04.allMissions, e: case04).toUpperCase();
      expect(all, isNot(contains('CLOCKMAKER')), reason: 'who he is stays untold');
      expect(all, isNot(contains('VANISHED')));
      expect(all, isNot(contains('STOLE')));
    });

    test('every word in its glossary is in its text', () {
      // Its text: the missions' words, and the papers read in its puzzles
      // (the ledger's lines, the street book's), whose words are dotted too.
      final text = [
        everything(case04.allMissions, e: case04),
        for (final p in hut.pages) for (final e in p.entries) e.words,
        for (final e in book.entries) ...e.lines,
      ].join('\n').toLowerCase();
      for (final w in case04.glossary.keys) {
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
      expect(season2Learning.keys.where((id) => id.startsWith('s2_ep04_')).toSet(), {for (final m in case04.allMissions) m.id});
      expect(season2LanguageTopics['s2_ep04'], isNotNull);
      for (final m in case04.allMissions) {
        final l = SeasonCatalog.learning(m)!;
        expect(l.isHonest, isTrue, reason: m.id);
        if (l.dependency == LanguageDependency.essential) expect(l.expressions, isNotEmpty);
        for (final e in l.expressions) {
          expect(screen(m), contains(norm(e)), reason: '${m.id}: "$e" is on its screens');
        }
      }
    });

    test('its evidence leads on from the brass plaque, one piece to the next', () {
      expect(SeasonCatalog.evidenceLink('s2_ep04_e1')!.to, 's2_ep03_e4');
      expect(SeasonCatalog.evidenceLink('s2_ep04_e2')!.to, 's2_ep04_e1');
      expect(SeasonCatalog.evidenceLink('s2_ep04_e3')!.to, 's2_ep04_e2');
      expect(SeasonCatalog.evidenceLink('s2_ep04_e4')!.to, 's2_ep04_e3');
      expect(SeasonCatalog.evidenceLink('s2_ep03_e4')!.to, 's2_ep03_e1', reason: "Case 03's links are as they were");
      for (final e in case04.allMissions) {
        expect(SeasonCatalog.evidenceArt(e.evidence!.id), isNotNull, reason: '${e.evidence!.id} is drawn with its words');
      }
      expect((SeasonCatalog.evidenceArt('s2_ep04_e3')! as LabelEvidenceArt).last, isFalse, reason: 'the label as found: no last piece');
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

    test('as shipped, it opens only once Case 03 is solved', () async {
      final c = await start();
      final game = c.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      expect(game.openEpisode('s2_ep04'), isFalse);
      solve(c, case01);
      solve(c, case02);
      expect(game.openEpisode('s2_ep04'), isFalse, reason: 'no way round Case 03');
      solve(c, case03);
      expect(c.read(seasonProvider.notifier).isUnlocked('s2_ep04'), isTrue);
      expect(game.openEpisode('s2_ep04'), isTrue);
      expect(c.read(currentEpisodeProvider).id, 's2_ep04');
    });

    test('the GM preview keeps the case order; full access opens it at once', () async {
      final c = await start(extra: [parisNotYetReleased]);
      final game = c.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isFalse);
      c.read(seasonPreviewSwitchProvider.notifier).set(true);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      expect(game.openEpisode('s2_ep04'), isFalse, reason: 'the preview keeps the case order');
      c.read(operatorAccessSwitchProvider.notifier).set(true);
      expect(game.openEpisode('s2_ep04'), isTrue);
      expect(c.read(seasonProvider).isSolved('s2_ep03'), isFalse, reason: 'full access marks nothing solved');
    });

    test('what is looked at, circled, set and crossed out is saved and comes back after a restart', () async {
      var c = await start();
      var game = c.read(gameControllerProvider.notifier);
      game.openSeason(SeasonIds.paris);
      for (final e in [case01, case02, case03]) {
        solve(c, e);
      }
      game.openEpisode('s2_ep04');
      game.startInvestigation();
      game.recordExamined(GameProgress.examinedKey(m1.id, 'a'));
      game.recordExamined(GameProgress.examinedKey(m1.id, RiverMarksScene.backId));
      expect(game.submitAnswer(m1, 'c').result, SubmitResult.tryAgain);
      expect(game.submitAnswer(m2, m2.answer).result, SubmitResult.locked, reason: 'missions in order');
      expect(game.submitAnswer(m1, m1.answer).result, SubmitResult.correct);
      game.recordPuzzleState(m2.id, HutState.encode(HutStep.ledger, 'box17'));
      game.recordExamined(GameProgress.examinedKey(m3.id, 'box12'));
      game.recordPuzzleState(m3.id, LabelState.encode({'top': 'p1', 'middle': 'decoy'}, boxes));
      game.recordPuzzleState(fin.id, CrossOutState.encode({'quai': {'e3'}}, book));

      c.dispose();
      c = await start();
      game = c.read(gameControllerProvider.notifier);
      expect(c.read(currentEpisodeProvider).id, 's2_ep04');
      var p = c.read(gameControllerProvider);
      expect(p.isCompleted(m1.id), isTrue);
      expect(p.wrongCount(m1.id), 1);
      expect(p.hasExamined('${m1.id}:a') && p.hasExamined('${m1.id}:back'), isTrue);
      expect(HutState.decode(p.puzzleStateOf(m2.id), hut), (HutStep.ledger, 'box17'));
      expect(p.hasExamined('${m3.id}:box12'), isTrue);
      expect(LabelState.decode(p.puzzleStateOf(m3.id), boxes), {'top': 'p1', 'middle': 'decoy'});
      expect(CrossOutState.decode(p.puzzleStateOf(fin.id), book), {'quai': {'e3'}});

      for (final m in [m2, m3, fin]) {
        expect(game.submitAnswer(m, m.answer).result, SubmitResult.correct, reason: m.id);
      }
      p = c.read(gameControllerProvider);
      expect([for (final e in p.collectedEvidence(case04)) e.name],
          ['The River Mark', "The Keeper's Ledger", 'The Torn Delivery Label', 'The Workshop Address']);
      expect(p.isCaseSolved, isTrue);
      expect(c.read(progressRepositoryProvider).load('s2_ep03').isCaseSolved, isTrue, reason: "Case 03's save is its own");
    });

    test('solved: Paris is 4 of 12, Case 05 opens next; London is as it was', () async {
      final c = await start();
      final game = c.read(gameControllerProvider.notifier);
      game.openSeason(SeasonIds.paris);
      for (final e in [case01, case02, case03, case04]) {
        solve(c, e);
      }
      final board = c.read(seasonOverviewProvider);
      expect(board.solvedCount, 4);
      expect(board.comingSoonCase, isNull, reason: 'Case 05 is in the game');
      final paris = c.read(seasonAvailabilityProvider(SeasonIds.paris))!;
      expect((paris.solvedCount, paris.plannedCount), (4, 12));
      expect(game.openEpisode('s2_ep05'), isTrue, reason: 'Case 05 opens once Case 04 is solved');
      expect(c.read(progressRepositoryProvider).loadSeason(SeasonIds.london).solvedEpisodeIds, hasLength(12));
    });
  });

  group('a child plays Case 04', () {
    for (final size in const [Size(360, 640), Size(390, 844), Size(430, 932)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';
      testWidgets('$tag: marks → hut and ledger → boxes and label → street book → gate, 4 of 12', (t) async {
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
        for (final e in [case01, case02, case03]) {
          expect(game.openEpisode(e.id), isTrue);
          game.startInvestigation();
          for (final m in e.allMissions) {
            game.submitAnswer(m, m.answer);
          }
        }
        expect(game.openEpisode('s2_ep04'), isTrue);

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
            File('$shots/paris04_${tag}_${(n++).toString().padLeft(2, '0')}_$name.png').writeAsBytesSync(png!.buffer.asUint8List());
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

        Future<void> back() async {
          await t.tap(find.byTooltip('Back'));
          await wait(t, const Duration(milliseconds: 500));
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
        void nothingOfTheLastPiece(String where) {
          expect(find.byKey(const ValueKey('label-piece-p5')), findsNothing, reason: where);
          expect(find.byKey(const ValueKey('label-address-rest')), findsNothing, reason: where);
          expect(find.byKey(const ValueKey('label-back-message')), findsNothing, reason: where);
          expect(find.textContaining('ES HORLOGERS', findRichText: true).evaluate().where((e) {
            final w = e.widget;
            return w is Text && (w.data ?? '').startsWith('ES HORLOGERS');
          }), isEmpty, reason: where);
          expect(find.textContaining('Do not trust'), findsNothing, reason: where);
        }

        // ── The opening: the plaque turned over ─────────────────────────
        router.go(Routes.intro);
        await wait(t, const Duration(milliseconds: 900));
        await tapText(t, 'SKIP ›', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('intro-plaque')), findsOneWidget);
        expect(find.text('Three waves mark the place.\nFollow the arrow towards the river.\nFind the one who watches the water.'), findsNWidgets(2), reason: 'on the brass, and large under it');
        await shot('opening');
        await tapText(t, "I'M READY", after: const Duration(milliseconds: 1600));

        // ── M1: the quay wall's marks ───────────────────────────────────
        await visit(m1.id);
        expect(find.byKey(const ValueKey('story-picture')), findsOneWidget, reason: 'the quay wall');
        await shot('m1_place');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.text('TAP TO OPEN'), findsNothing, reason: 'the plaque is read on the page');
        expect(find.byKey(const ValueKey('wall-sign')), findsOneWidget);
        await shot('m1_wall');
        await tapKey('mark-spot-a', after: const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('mark-close-a')), findsOneWidget);
        expect(find.byKey(const ValueKey('mark-word-a')), findsOneWidget);
        await shot('m1_mark_a');
        await tapKey('mark-close-done');
        await tapKey('marks-plaque', after: const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('plaque-back')), findsOneWidget, reason: 'it opens on the back');
        expect(t.widget<Text>(find.descendant(of: find.byKey(const ValueKey('plaque-side-words')), matching: find.byType(Text))).style!.fontSize, greaterThanOrEqualTo(20));
        await shot('m1_plaque_back');
        await tapKey('plaque-turn', after: const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('plaque-front')), findsOneWidget);
        expect(find.byKey(const ValueKey('plaque-river')), findsOneWidget);
        await tapKey('plaque-sides-done');
        expect(examined(), containsAll(['s2_ep04_m1:a', 's2_ep04_m1:back']));
        // The plaque's three lines on the page itself, whole, numbered.
        for (var i = 1; i <= 3; i++) {
          expect(find.byKey(ValueKey('marks-line-$i')), findsOneWidget);
        }
        for (final line in marks.plaqueBack.lines) {
          expect(findReadableContaining(line), findsWidgets, reason: line);
        }
        // Each mark large on its card (wider than a third of the screen),
        // its close-up a glass away; none chosen, no tick on the wall.
        for (final m in marks.marks) {
          expect(t.getSize(find.byKey(ValueKey('mark-${m.id}'))).width, greaterThan(size.width / 3), reason: m.id);
          expect(find.text('${m.name} · CHOSEN'), findsNothing);
        }
        expect(find.descendant(of: find.byKey(const ValueKey('mark-spot-a')), matching: find.byWidgetPredicate((w) => w is InkIcon && w.glyph == InkGlyph.check)), findsNothing,
            reason: 'looked at, but never ticked like an answer');
        await shot('m1_compare');
        await tapKey('mark-closer-c', after: const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('mark-close-c')), findsOneWidget);
        await shot('m1_mark_c');
        await tapKey('mark-close-done');
        // One chosen at a time: B, then D in its place.
        await tapKey('mark-b');
        expect(find.text('MARK B · CHOSEN'), findsOneWidget);
        await tapKey('marks-check');
        // The line it breaks, by its number; never the right mark.
        await wrongThenTryAgain('Look at line 3 again', 'm1');
        expect(findReadableContaining('Do booksellers watch the water?'), findsNothing, reason: 'closed');
        await tapKey('mark-c');
        await tapKey('marks-check');
        await wrongThenTryAgain('Look at line 1 again', 'm1c');
        await tapKey('mark-d');
        expect(find.text('MARK D · CHOSEN'), findsOneWidget);
        expect(find.text('MARK C · CHOSEN'), findsNothing, reason: 'only one chosen');
        await shot('m1_chosen');
        // Out and back in before checking: what was looked at is kept.
        router.go(Routes.map);
        await wait(t, const Duration(milliseconds: 1400));
        await visit(m1.id);
        if (find.text('INVESTIGATE').evaluate().isNotEmpty) await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(examined(), containsAll(['s2_ep04_m1:a', 's2_ep04_m1:b', 's2_ep04_m1:c', 's2_ep04_m1:d', 's2_ep04_m1:back']));
        await tapKey('mark-d');
        await tapKey('marks-check', after: const Duration(milliseconds: 600));
        // Right: why, line by line, before the case goes on.
        expect(find.byKey(const ValueKey('marks-why')), findsOneWidget);
        for (final (i, line) in marks.rightLines.indexed) {
          expect(find.descendant(of: find.byKey(ValueKey('marks-why-${i + 1}')), matching: find.text(line)), findsOneWidget);
        }
        expect(ref.read(gameControllerProvider).isCompleted(m1.id), isFalse, reason: 'checked once the why is read');
        await shot('m1_why');
        await tapKey('marks-why-continue');
        await finish(m1.transition.first, 'm1');
        expect(ref.read(gameControllerProvider).isCompleted(m1.id), isTrue);

        // ── M2: the hut, inside it, the ledger ──────────────────────────
        await visit(m2.id);
        await shot('m2_place');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('hut-outside')), findsOneWidget);
        expect(find.byKey(const ValueKey('hut-picture-hut-door')), findsOneWidget, reason: 'keeper_hut.png');
        await shot('m2_outside');
        // The door, where it is in the picture.
        final picture = t.getRect(find.byKey(const ValueKey('hut-picture-hut-door')));
        final door = t.getRect(find.byKey(const ValueKey('hut-door')));
        expect(door.center.dx, closeTo(picture.left + picture.width * hut.doorArea.center.dx, 1));
        await tapKey('hut-door', after: const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('hut-inside')), findsOneWidget);
        expect(find.byKey(const ValueKey('hut-picture-hut-ledger')), findsOneWidget, reason: 'keeper_hut_interior.png');
        await shot('m2_inside');
        await back();
        expect(find.byKey(const ValueKey('hut-outside')), findsOneWidget, reason: 'back: inside → outside');
        await tapKey('hut-door', after: const Duration(milliseconds: 600));
        await tapKey('hut-ledger', after: const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('ledger-page-0')), findsOneWidget, reason: 'keeper_ledger.png');
        expect(find.byKey(const ValueKey('ledger-title-1')), findsNothing, reason: 'page 2 is not open before the answer');
        expect(examined(), contains('s2_ep04_m2:ledger'));
        await shot('m2_ledger');
        await back();
        expect(find.byKey(const ValueKey('hut-inside')), findsOneWidget, reason: 'back: ledger → inside');
        await tapKey('hut-ledger', after: const Duration(milliseconds: 600));
        await tapKey('ledger-0-3-box17');
        expect(find.text('You circled: BOX 17'), findsOneWidget);
        await tapKey('ledger-check');
        await wrongThenTryAgain('Did it stay there?', 'm2');
        // Out and back in: where the detective was, the box circled.
        router.go(Routes.map);
        await wait(t, const Duration(milliseconds: 1400));
        await visit(m2.id);
        expect(find.byKey(const ValueKey('ledger-page-0')), findsOneWidget, reason: 'saved: at the ledger');
        expect(find.text('You circled: BOX 17'), findsOneWidget, reason: 'saved: the box');
        await tapKey('ledger-0-5-box23');
        await shot('m2_circled');
        await tapKey('ledger-check', after: const Duration(milliseconds: 900));
        // Right: page 2 is turned and read before the story goes on.
        expect(ref.read(gameControllerProvider).isCompleted(m2.id), isTrue);
        expect(find.text(hut.solvedLine), findsOneWidget);
        expect(find.byKey(const ValueKey('ledger-title-1')), findsNothing);
        await shot('m2_right');
        await tapKey('ledger-turn', after: const Duration(milliseconds: 700));
        expect(find.byKey(const ValueKey('ledger-title-1')), findsOneWidget);
        expect(t.widget<GameButton>(find.byKey(const ValueKey('ledger-continue'))).onPressed, isNull, reason: 'Box 23 found first');
        await tapKey('ledger-1-0-box4');
        expect(find.byKey(const ValueKey('ledger-missed')), findsOneWidget);
        await tapKey('ledger-1-2-box23');
        expect(find.text(hut.foundLine), findsOneWidget);
        await shot('m2_page2');
        await tapKey('ledger-continue', after: const Duration(milliseconds: 300));
        expect(examined(), contains('s2_ep04_m2:page2'));
        await finish(m2.transition.first, 'm2');

        // ── M3: the green boxes, the torn label ─────────────────────────
        await visit(m3.id);
        await shot('m3_place');
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        for (final b in boxes.boxes) {
          expect(find.byKey(ValueKey('box-number-${b.id}')), findsOneWidget);
        }
        await shot('m3_boxes');
        await tapKey('quay-box-box17');
        expect(find.text(boxes.box('box17').note!), findsOneWidget);
        await tapKey('quay-box-box21');
        expect(find.text(boxes.box('box21').note!), findsOneWidget);
        await tapKey('quay-box-box23', after: const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('label-step')), findsOneWidget);
        expect(examined(), containsAll(['s2_ep04_m3:box17', 's2_ep04_m3:box21', 's2_ep04_m3:box23']));
        nothingOfTheLastPiece('M3');
        await shot('m3_scraps');
        expect(t.widget<GameButton>(find.byKey(const ValueKey('label-check'))).onPressed, isNull, reason: 'every slot first');
        // By taps: the scrap at the top.
        await tapKey('tray-decoy');
        await tapKey('slot-top');
        await tapKey('tray-p2');
        await tapKey('slot-middle');
        await tapKey('tray-p3');
        await tapKey('slot-bottom');
        await shot('m3_wrong_scrap');
        await tapKey('label-check');
        await wrongThenTryAgain('different paper', 'm3');
        // Taken out, and the eyelet piece dragged in.
        await tapKey('slot-top');
        expect(find.byKey(const ValueKey('tray-decoy')), findsOneWidget);
        await reveal(t, find.byKey(const ValueKey('tray-p1')));
        final from = t.getCenter(find.byKey(const ValueKey('tray-p1')));
        await reveal(t, find.byKey(const ValueKey('slot-top')));
        final fromNow = t.getCenter(find.byKey(const ValueKey('tray-p1')));
        final to = t.getCenter(find.byKey(const ValueKey('slot-top')));
        expect(from, isNotNull);
        final drag = await t.startGesture(fromNow);
        for (var i = 1; i <= 12; i++) {
          await drag.moveTo(Offset.lerp(fromNow, to, i / 12)!);
          await t.pump(const Duration(milliseconds: 16));
        }
        await drag.up();
        await wait(t, const Duration(milliseconds: 400));
        expect(LabelState.decode(ref.read(gameControllerProvider).puzzleStateOf(m3.id), boxes), {'top': 'p1', 'middle': 'p2', 'bottom': 'p3'});
        nothingOfTheLastPiece('M3, the label whole');
        expect(find.byKey(const ValueKey('label-address-start')), findsOneWidget, reason: 'PASSAGE D…');
        await shot('m3_label');
        await tapKey('label-check');
        await finish(m3.transition.first, 'm3');

        // ── Final: the street book, then the gate ───────────────────────
        router.go(Routes.finalMission);
        await wait(t, const Duration(milliseconds: 1600));
        expect(find.byKey(const ValueKey('gate-stage')), findsOneWidget);
        expect(find.byKey(const ValueKey('stage-gate')), findsNothing, reason: 'nothing of the gate before the solve');
        expect(find.byKey(const ValueKey('gate-sign')), findsNothing);
        nothingOfTheLastPiece('the final, before the solve');
        await shot('final_page');
        // The book is read a page at a time: every address line is 14 on
        // screen (its type size times how much the page is scaled), its
        // name larger.
        double onScreen(String key) {
          final f = find.byKey(ValueKey(key));
          final size = t.widget<Text>(f).style!.fontSize!;
          return size * t.getRect(f).height / t.getSize(f).height;
        }

        for (final page in [0, 1]) {
          if (page == 1) await tapKey('book-page-1');
          for (final e in book.entries.where((e) => e.page == page)) {
            await reveal(t, find.byKey(ValueKey('book-entry-${e.id}')));
            for (var i = 0; i < e.lines.length; i++) {
              expect(onScreen('book-line-${e.id}-$i'), closeTo(14, 0.05), reason: '$tag ${e.id} line $i');
            }
            expect(onScreen('book-name-${e.id}'), greaterThan(14));
          }
          await shot('final_book_page_${page + 1}');
        }
        await tapKey('book-page-0');
        Future<void> crossOut(String address, List<String> evidence) async {
          await tapKey('book-entry-$address');
          for (final e in evidence) {
            await tapKey('book-evidence-$e', after: const Duration(milliseconds: 200));
          }
          await tapKey('book-cross', after: const Duration(milliseconds: 500));
        }

        await tapKey('book-entry-pont');
        expect(find.byKey(const ValueKey('book-panel-name')), findsOneWidget);
        await shot('final_address');
        await tapKey('book-evidence-e1', after: const Duration(milliseconds: 200));
        await tapKey('book-cross', after: const Duration(milliseconds: 500));
        await wrongThenTryAgain('how was the crate delivered?', 'final');
        // Up to two pieces: a third cannot be added.
        await tapKey('book-evidence-e2', after: const Duration(milliseconds: 200));
        await tapKey('book-evidence-e3', after: const Duration(milliseconds: 200));
        expect(find.text('Two pieces at most.'), findsOneWidget);
        await tapKey('book-cross', after: const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('book-crossed-pont')), findsOneWidget, reason: 'River Mark + Ledger');
        await crossOut('quai', ['e3']);
        await tapKey('book-page-1');
        await crossOut('horloge', ['e2']);
        expect(find.byKey(const ValueKey('book-crossed-horloge')), findsOneWidget);
        expect(find.byKey(const ValueKey('book-page-0')), findsNothing, reason: 'one address left: its page stays open');
        expect(find.text(book.addressTask), findsOneWidget);
        nothingOfTheLastPiece('the final, one address left');
        await shot('final_crossed');
        await tapKey('book-submit');
        await wait(t, const Duration(milliseconds: 3600));
        expect(ref.read(gameControllerProvider).isCaseSolved, isTrue);
        expect(find.byKey(const ValueKey('stage-gate')), findsOneWidget, reason: 'the gate of the address');
        expect(find.byKey(const ValueKey('gate-sign')), findsOneWidget);
        await shot('final_solved');
        await tapText(t, 'LOOK AT THE GATE', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('gate-scrap')), findsOneWidget, reason: 'the last piece, only now');
        expect(find.byKey(const ValueKey('label-address-rest')), findsOneWidget);
        await shot('final_gate');
        await tapKey('gate-next', after: const Duration(milliseconds: 1000));
        expect(find.byKey(const ValueKey('gate-fit')), findsOneWidget);
        expect(find.text('PASSAGE DES HORLOGERS'), findsOneWidget);
        await shot('final_fit');
        await tapKey('gate-next', after: const Duration(milliseconds: 1000));
        expect(find.byKey(const ValueKey('gate-scrap-back')), findsOneWidget);
        expect(find.byKey(const ValueKey('label-back-message')), findsOneWidget);
        expect(find.text('Do not trust the clocks.\nFollow the hands\nthat made them.'), findsNWidgets(2));
        expect(t.widget<Text>(find.byKey(const ValueKey('gate-words-2'))).style!.fontSize, greaterThanOrEqualTo(20));
        expect(examined(), contains('s2_ep04_final:gate'));
        await shot('final_back');
        await tapKey('gate-next', after: const Duration(milliseconds: 700));
        await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 900));
        expect(find.text(fin.transition.first), findsOneWidget);
        await t.tapAt(Offset(size.width / 2, size.height / 2));
        await wait(t, const Duration(milliseconds: 900));
        expect(findReadable('Follow the hands that made them.'), findsOneWidget);
        expect(find.byKey(const ValueKey('scene-backdrop')), findsOneWidget, reason: 'the gate');
        await shot('final_scene');
        await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 4000));
        // Case 05 is in the game now: on to it.
        await reveal(t, find.text('OPEN CASE 05'));
        expect(find.text('OPEN CASE 05'), findsOneWidget);
        expect(find.byKey(const ValueKey('next-case-coming-soon')), findsNothing);
        await shot('case_closed');

        final board = ref.read(seasonOverviewProvider);
        expect(board.solvedCount, 4);
        expect(board.comingSoonCase, isNull);
        expect(game.openEpisode('s2_ep05'), isTrue);
        await wait(t, const Duration(seconds: 3));
      });
    }

    testWidgets('reduce motion: the hut, the ledger and the label still go on, at once', (t) async {
      t.view.physicalSize = const Size(390, 844) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      late WidgetRef ref;
      await t.pumpWidget(ProviderScope(
        overrides: [
          ...await testOverrides(prefs: {
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
      game.createDetective('Kim', DetectiveAvatar.girl);
      game.openSeason(SeasonIds.paris);
      for (final e in [case01, case02, case03]) {
        game.openEpisode(e.id);
        game.startInvestigation();
        for (final m in e.allMissions) {
          game.submitAnswer(m, m.answer);
        }
      }
      game.openEpisode('s2_ep04');
      game.startInvestigation();
      game.submitAnswer(m1, m1.answer);
      ref.read(routerProvider).go(Routes.mission(m2.id));
      await wait(t, const Duration(milliseconds: 1400));
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 100));
      await t.tap(find.byKey(const ValueKey('hut-door')));
      await t.pump();
      await t.pump();
      expect(find.byKey(const ValueKey('hut-outside')), findsNothing, reason: 'no fade: at once');
      expect(find.byKey(const ValueKey('hut-inside')), findsOneWidget);
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 2));
    });
  });
}
