import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/core/utils/answer_checker.dart';
import 'package:london_mystery/data/content/difficulty_content.dart';
import 'package:london_mystery/data/content/learning_check.dart';
import 'package:london_mystery/data/mock/season2/season2_case03_scenes.dart';
import 'package:london_mystery/data/mock/season2/season2_difficulty.dart';
import 'package:london_mystery/data/mock/season2/season2_discoveries.dart';
import 'package:london_mystery/data/mock/season2/season2_learning.dart';
import 'package:london_mystery/data/mock/season2/season2_scenes.dart';
import 'package:london_mystery/data/mock/season_catalog.dart';
import 'package:london_mystery/data/models/difficulty.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/result/detective_report.dart';

import 'full_playthrough_test.dart' show tapText, wait;
import 'helpers.dart';

/// Difficulty PART 7A: Paris Cases 01–03 written at Rookie, Junior and
/// Master. The words change with the level; the case — its times, answers,
/// ids, orders, hints' number and price, clues, evidence, rewards and what
/// stays untold — never does (docs/difficulty_reviews/PARIS_CASE_01_03.md).

final base = MockEpisodeRepository.bundled();
const cases = ['s2_ep01', 's2_ep02', 's2_ep03'];
const levels = Difficulty.values;
const written = [Difficulty.junior, Difficulty.master];

Episode baseCase(String id) => base.firstWhere((e) => e.id == id);
Episode caseAt(String id, Difficulty level) => DifficultyContent.episodeAt(baseCase(id), level);
Mission at(String missionId, Difficulty level) =>
    DifficultyContent.episodeAt(base.firstWhere((e) => e.allMissions.any((m) => m.id == missionId)), level).missionById(missionId)!;

/// Everything a case says (as the cases' own tests read it).
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
        m.successMessage,
        for (final o in m.options) o.label,
        for (final o in m.options) o.feedback ?? '',
        ...m.feedback.values,
        m.orderFeedback ?? '',
        m.clue?.note ?? '',
        m.evidence?.description ?? '',
        m.evidence?.inscription ?? '',
      ],
    ].join('\n');

/// What a case's scenes say at [level] (their own words).
String sceneWords(Episode e) => [
      for (final m in e.allMissions) ...[
        if (SeasonCatalog.stationClocks(m) case final s?) ...[s.missLine, s.boardFirstLine, s.clocksFirstLine, for (final o in s.others) o.line],
        if (SeasonCatalog.exhibit(m) case final x?) ...[x.description, x.caption],
        if (SeasonCatalog.clock(m) case final c?) ...[c.question, c.lead, c.guide],
        if (SeasonCatalog.compare(m) case final c?) ...[c.missLine, ...c.foundLines.values, ...c.checklist.values],
        if (SeasonCatalog.studio(m) case final s?) ...[s.missLine, s.deskFirstLine, s.desk.line, for (final p in s.paintings) p.line, for (final o in s.others) o.line],
        if (SeasonCatalog.layer(m) case final l?) ...[l.missLine, l.paintLine, ...l.foundLines.values],
      ],
    ].join('\n');

/// Every written text of a case, by where it is (`m.field[i]`).
Map<String, String?> fields(Episode e) => {
      'intro': e.intro.join('\n'),
      'synopsis': e.synopsis.join('\n'),
      'objectives': e.objectives.join('\n'),
      'caseSummary': e.caseSummary,
      'hook': e.hook,
      for (final m in e.allMissions) ...{
        '${m.id}.story': m.story.join('\n'),
        '${m.id}.letterIntro': m.letterIntro,
        '${m.id}.letter': m.letter,
        '${m.id}.question': m.question,
        for (final (i, h) in m.hints.indexed) '${m.id}.hints[$i]': h,
        '${m.id}.successMessage': m.successMessage,
        for (final (i, l) in m.transition.indexed) '${m.id}.transition[$i]': l,
        '${m.id}.orderFeedback': m.orderFeedback,
        for (final k in m.feedback.keys) '${m.id}.feedback[$k]': m.feedback[k],
        for (final o in m.options) '${m.id}.options[${o.id}].feedback': o.feedback,
        '${m.id}.clue.note': m.clue?.note,
        '${m.id}.evidence.description': m.evidence?.description,
      },
    };

/// The lines kept word for word at every level, on purpose: what a paper,
/// a note or the painter says (quoted again after the puzzle), the riddle
/// of the plaque, the inspection note, and the lines of the case's end the
/// next case begins from. Anything else the same as another level's is a
/// line left unwritten.
const keptAtEveryLevel = {
  // The clerk's three order lines, read back in order.
  's2_ep01_m2.transition[0]',
  's2_ep01_m2.transition[1]',
  's2_ep01_m2.transition[2]',
  // The painting's church is the ticket's (its evidence link says so too);
  // the three words on its back.
  's2_ep01_final.transition[2]',
  's2_ep01_final.transition[4]',
  // The painter's own lines, quoted.
  's2_ep02_m1.transition[1]',
  's2_ep02_m2.transition[1]',
  // The back of the canvas: his studio, TOUJOURS PLUS HAUT (Case 03
  // begins from it), his message, his own words, and the case's last line.
  's2_ep02_final.transition[0]',
  's2_ep02_final.transition[1]',
  's2_ep02_final.transition[3]',
  's2_ep02_final.transition[4]',
  's2_ep02_final.transition[8]',
  // The inspection note: its three order lines are the puzzle.
  's2_ep03_m3.letter',
  // The plaque's riddle, SEINE, the tag and the questions it leaves.
  's2_ep03_final.transition[0]',
  's2_ep03_final.transition[1]',
  's2_ep03_final.transition[3]',
  's2_ep03_final.transition[6]',
  's2_ep03_final.transition[7]',
  's2_ep03_final.transition[8]',
  // The room alone answers nothing; and nothing proves the hour vanished.
  's2_ep03_final.feedback[q3:e3]',
  's2_ep03_final.feedback[why:vanished]',
};

/// Kept at Junior as the game's own (everyday English already), Master's
/// own: what the evidence says of the painter.
const keptAtJunior = {'s2_ep02_final.transition[5]', 's2_ep02_final.transition[7]'};

void main() {
  group('Written: nothing falls back unseen', () {
    test('Cases 01–03 are marked written at every level, and nothing of theirs falls back', () {
      expect(DifficultyContent.problems(), isEmpty);
      for (final id in cases) {
        expect(season2Content.writtenLevels[id], {...levels}, reason: id);
        for (final level in levels) {
          expect(DifficultyContent.missingAt(id, level), isEmpty, reason: '$id at ${level.name}');
        }
      }
      // Cases 04–06 are PART 7B's (difficulty_paris_7b_test.dart holds the
      // whole set written so far); Case 07 on is still to come.
      expect(season2Content.writtenLevels.keys.toSet(), {...cases, 's2_ep04', 's2_ep05', 's2_ep06'});
    });

    test('Junior and Master each have their own line everywhere but the lines kept on purpose', () {
      for (final id in cases) {
        final b = fields(baseCase(id));
        final j = fields(caseAt(id, Difficulty.junior));
        final m = fields(caseAt(id, Difficulty.master));
        for (final key in b.keys) {
          if (b[key] == null) continue;
          final kept = keptAtEveryLevel.contains(key);
          expect(j[key] == b[key], kept || keptAtJunior.contains(key), reason: 'Junior $key: ${j[key]}');
          expect(m[key] == b[key], kept, reason: 'Master $key: ${m[key]}');
          expect(m[key] == j[key], kept, reason: 'Master = Junior $key: ${m[key]}');
        }
      }
    });

    test('Rookie plays the game\'s own words; only its glossary grows', () {
      for (final id in cases) {
        final b = baseCase(id);
        final r = caseAt(id, Difficulty.rookie);
        expect(fields(r), fields(b), reason: id);
        expect(r.glossary.keys, containsAll(b.glossary.keys));
        expect(r.glossary.length, greaterThan(b.glossary.length), reason: '$id: words a child may not know, explained');
        for (final m in r.allMissions) {
          expect(SeasonCatalog.learning(m)!.expressions, season2Learning[m.id]!.expressions, reason: m.id);
        }
      }
    });

    test('Every glossary word of a level is on its pages; keys are lower-case single words', () {
      for (final id in cases) {
        for (final level in levels) {
          final e = caseAt(id, level);
          final text = ' ${LearningCheck.words('${everything(e)}\n${sceneWords(e)}')} ';
          // The words this level's own patch explains.
          final own = (season2CasePatches[level]![id]!['glossary'] as Map?) ?? const {};
          for (final k in own.keys.cast<String>()) {
            expect(k, k.toLowerCase());
            expect(k.contains(' '), isFalse, reason: k);
            expect(text, contains(' ${LearningCheck.words(k)} '), reason: '$id at ${level.name}: "$k"');
          }
        }
      }
    });
  });

  group('The case never changes with the level', () {
    test('ids, answers, orders, hints\' number, clues, evidence, coins: the same at every level', () {
      for (final id in cases) {
        final b = baseCase(id);
        for (final level in levels) {
          final e = caseAt(id, level);
          expect(DifficultyContent.structureOfEpisode(e), DifficultyContent.structureOfEpisode(b), reason: '$id ${level.name}');
          expect((e.title, e.place), (b.title, b.place));
          expect(e.keyWords, b.keyWords);
          for (final (i, m) in e.allMissions.indexed) {
            final o = b.allMissions[i];
            expect((m.id, m.title, m.location, m.answer, m.codeLength, m.hints.length), (o.id, o.title, o.location, o.answer, o.codeLength, o.hints.length));
            expect([for (final x in m.options) '${x.id}:${x.label}'], [for (final x in o.options) '${x.id}:${x.label}'], reason: '${m.id}: options, in order');
            expect((m.clue?.title, m.clue?.value, m.evidence?.name, m.evidence?.inscription), (o.clue?.title, o.clue?.value, o.evidence?.name, o.evidence?.inscription));
            expect(WalletController.coinsFor(m), WalletController.coinsFor(o));
            expect(m.difficulty, level);
          }
        }
      }
      expect([WalletController.priceOf(1), WalletController.priceOf(2)], AppConstants.tipPrices);
    });

    test('the right answer is right at every level; every known wrong one is wrong, and says its level\'s line', () {
      for (final id in cases) {
        for (final level in levels) {
          for (final m in caseAt(id, level).allMissions) {
            expect(AnswerChecker.isCorrect(m, m.answer), isTrue, reason: '${m.id} ${level.name}');
            for (final wrong in m.feedback.keys) {
              expect(AnswerChecker.isCorrect(m, wrong), isFalse, reason: '${m.id} "$wrong"');
              expect(AnswerChecker.feedbackFor(m, wrong), m.feedback[wrong], reason: '${m.id} "$wrong" at ${level.name}');
            }
            for (final o in m.options.where((o) => o.feedback != null)) {
              expect(AnswerChecker.feedbackFor(m, o.id), o.feedback, reason: '${m.id} ${o.id}');
            }
          }
        }
      }
    });

    test('each scene: its level\'s words on the base\'s structure; ways to play the same at every level', () {
      for (final level in written) {
        final v = season2Variants[level]!;
        for (final MapEntry(key: table, value: entries) in v.missionTables.entries) {
          for (final MapEntry(key: id, value: entry) in entries.entries) {
            final b = season2Content.missionTables[table]![id];
            expect(DifficultyContent.structureOf(entry), isNotNull, reason: '$table/$id');
            expect(DifficultyContent.structureOf(entry), DifficultyContent.structureOf(b), reason: '$table/$id at ${level.name}');
            if (season2SameAtEveryLevel.contains('$table/$id')) expect(identical(entry, b), isTrue, reason: '$table/$id kept');
          }
        }
        final m1 = at('s2_ep01_m1', level), m3 = at('s2_ep01_m3', level);
        final hall = SeasonCatalog.stationClocks(m1)!, baseHall = season2StationClocks['s2_ep01_m1']!;
        expect([hall.task, hall.boardTask, hall.reportTask, hall.reportHow, hall.tapGuide, hall.zoomGuide],
            [baseHall.task, baseHall.boardTask, baseHall.reportTask, baseHall.reportHow, baseHall.tapGuide, baseHall.zoomGuide]);
        expect(hall.notice, baseHall.notice, reason: 'the station\'s own sign');
        expect(hall.missLine, isNot(baseHall.missLine));
        expect(SeasonCatalog.clock(m3)!.guide, season2Clocks['s2_ep01_m3']!.guide, reason: 'how to drag the hands');
        expect(SeasonCatalog.clock(m3)!.question, isNot(season2Clocks['s2_ep01_m3']!.question));
        expect(SeasonCatalog.exhibit(at('s2_ep01_m2', level))!.description, contains('MONTMARTRE, PARIS, number 72831'));
        final studio = SeasonCatalog.studio(at('s2_ep02_m2', level))!, baseStudio = season2Studios['s2_ep02_m2']!;
        expect([studio.task, studio.deskTask, studio.matchTask, studio.matchHow, studio.matchPainting, studio.matchDone, studio.matchDrag],
            [baseStudio.task, baseStudio.deskTask, baseStudio.matchTask, baseStudio.matchHow, baseStudio.matchPainting, baseStudio.matchDone, baseStudio.matchDrag]);
        final layer = SeasonCatalog.layer(at('s2_ep02_m3', level))!;
        expect((layer.slideTask, layer.findTask), (season2Layers['s2_ep02_m3']!.slideTask, season2Layers['s2_ep02_m3']!.findTask));
        // The street's checklist is the note's own lines, at its level.
        final street = at('s2_ep02_m1', level);
        for (final line in SeasonCatalog.compare(street)!.checklist.values) {
          expect(street.letter, contains(line), reason: line);
        }
        // The evidence board's questions are the mission's options.
        final fin = at('s2_ep03_final', level);
        expect([for (final q in SeasonCatalog.evidenceBoard(fin)!.questions) q.text], [for (final o in fin.options.take(3)) o.label]);
      }
      expect(season2EvidenceBoards['s2_ep03_final']!.conclusions.map((c) => c.text), contains('An hour really vanished from Paris.'));
    });
  });

  group('What each case keeps untold, at every level', () {
    for (final level in levels) {
      test('Case 01 at ${level.name}', () {
        final e = caseAt('s2_ep01', level);
        final [m1, m2, m3, fin] = e.allMissions;
        expect(m1.letter, contains('If one clock is ONE HOUR BEHIND,\nreport it to the LOST PROPERTY DESK.'));
        expect(m1.letter, allOf(contains('10:00'), contains('9:00')));
        for (final h in m1.hints) {
          expect(h.toLowerCase(), isNot(contains('old clock')), reason: h);
        }
        for (final line in ['AFTER THAT, the old clock showed nine.', 'FIRST, the hall clock struck ten.', 'NEXT, a man with a pocket watch came in.']) {
          expect(m2.letter, contains(line));
        }
        for (final h in m2.hints) {
          expect(h, isNot(contains('man with a pocket watch')), reason: h);
        }
        // The ticket's words say nothing of where it leads.
        for (final s in [...m2.story, m2.letterIntro, m2.letter, m2.question, ...m2.hints, ...m2.transition, m2.clue!.note, m2.successMessage]) {
          expect(s.toLowerCase(), isNot(contains('montmartre')), reason: s);
          expect(s.toLowerCase(), isNot(contains('painter')), reason: s);
        }
        // Whether the man changed the clock is a question, never a finding.
        expect(m2.transition.where((l) => l.contains('Did the man')), hasLength(1));
        expect(m3.letter, contains('FORWARD'));
        for (final h in m3.hints) {
          expect(h, isNot(contains('10:00')), reason: h);
        }
        for (final s in [...fin.hints, fin.letter, ...fin.story, fin.question, ...m3.transition]) {
          expect(s.toUpperCase(), isNot(contains('TIME')), reason: s);
        }
        expect(fin.hints.first, startsWith('The Clockmaker steals an hour.'), reason: 'the story bible: kept as it is');
        expect(fin.letter, contains('The Clockmaker loves one thing most.\nHe steals it. He hides it.'));
        expect(fin.transition, contains('The same white church is on the lost ticket.'));
        expect(fin.transition.last, 'FIND THE PAINTER.');
        for (final word in ['ITEM', 'EMIT', 'MITE']) {
          expect(AnswerChecker.feedbackFor(fin, word), contains('$word is a real word'), reason: word);
        }
      });

      test('Case 02 at ${level.name}', () {
        final e = caseAt('s2_ep02', level);
        final [m1, m2, m3, fin] = e.allMissions;
        final intro = e.intro.join(' ');
        expect(intro, allOf(contains('FIND THE PAINTER'), contains('ticket'), contains('MONTMARTRE')));
        expect(m1.transition.join(' '), contains('far from the red door'));
        expect(m1.transition.last, contains('STUDIO'));
        expect(m2.story.first, contains('key'));
        for (final heading in ['BEFORE THE RAIN', 'AFTER THE RAIN STOPPED', 'WHEN THE SKY TURNED GOLD']) {
          expect(m2.letter, contains(heading));
        }
        expect(m2.letter, allOf(contains('still dry'), contains('wet and shiny')));
        expect(m2.letter.toLowerCase(), anyOf(contains('no dark clouds'), contains('single dark cloud')));
        expect(m2.transition.join(' '), contains('blue-sky day'));
        expect(m2.transition.last, contains('thick paint'));
        expect(m3.story.join(' ').toLowerCase(), contains('thick paint'));
        expect(m3.letter, contains('the gate is black'));
        for (final q in ['What changed?', 'What was hidden?', 'Why does it matter?']) {
          expect(m3.transition.where((l) => l.startsWith(q)), hasLength(1), reason: q);
        }
        expect(m3.transition.last, contains('four canvases'));
        expect(fin.story.first, contains('Four canvases'));
        expect(fin.letter, allOf(contains('Not the street with the red door.'), contains('I hid my secret on a blue-sky day.'), contains('Steps, a lamp and a black gate.')));
        // The painter left on his own: what was found says it before he does.
        final end = fin.transition;
        final message = end.indexWhere((l) => l.contains('A city can lose an hour'));
        expect(message, greaterThanOrEqualTo(0));
        expect(end, contains('"I saw who took the hour. I went away to keep the secret safe. — P."'));
        final hid = end.indexWhere((l) => l.startsWith('He hid his own sketch'));
        expect(hid, greaterThan(message));
        expect(end.indexWhere((l) => l.contains('He left on his own.')), greaterThan(hid));
        expect(end[1], 'And three French words: TOUJOURS PLUS HAUT. Always higher.', reason: 'Case 03 begins from it');
        expect(end.last, 'But someone is still stealing the hours of Paris.');
        expect(AnswerChecker.feedbackFor(fin, 'a'), contains('red door'));
        expect(AnswerChecker.feedbackFor(fin, 'b'), contains('blue'));
        expect(AnswerChecker.feedbackFor(fin, 'd'), contains('colour'));
        // Nothing the pictures do not show; the Clockmaker and Case 03's
        // place untold.
        final text = '${everything(e)}\n${sceneWords(e)}';
        for (final absent in ['travel bag', 'gear', 'walks up the steps', 'His bag', 'Clockmaker', 'Eiffel', 'Louvre', 'Notre', 'Opéra', 'Opera', 'Seine']) {
          expect(text, isNot(contains(absent)), reason: absent);
        }
      });

      test('Case 03 at ${level.name}', () {
        final e = caseAt('s2_ep03', level);
        final [m1, m2, m3, fin] = e.allMissions;
        // The opening: second person, and no time given away.
        for (final line in [...e.intro, ...e.synopsis, ...e.objectives, ...m1.story, m1.letter, m1.letterIntro, m1.question]) {
          for (final giveaway in ['3:00', '4:00', 'three', 'four', 'one hour']) {
            expect(line.toLowerCase(), isNot(contains(giveaway)), reason: line);
          }
          expect(RegExp(r"\bI\b|\bI'm\b|\bmy\b").hasMatch(line), isFalse, reason: 'second person: $line');
        }
        expect(e.intro.first, contains('Always higher'));
        expect(e.intro[1], contains('You turn the canvas over'));
        expect(e.intro.join(' ').toLowerCase(), contains('the eiffel tower'));
        expect(m3.letter, allOf(contains('First, check the clock.'), contains('Next, stop the lift.'), contains('Finally, turn the key.')));
        expect(m2.hints.join(' '), contains('S = SERVICE RUN'));
        // The plaque is a riddle, never proof.
        final all = '${everything(e)}\n${sceneWords(e)}'.toUpperCase();
        expect(all, isNot(contains('THREE MORE')));
        expect(all, isNot(contains('CLOCKMAKER')), reason: 'who he is stays untold');
        for (final claim in ['VANISHED FROM PARIS', 'HOUR WAS STOLEN', 'STOLE THE HOUR', 'HOUR REALLY']) {
          expect(all, isNot(contains(claim)), reason: claim);
        }
        expect(fin.transition, containsAllInOrder(['One hour is missing.', 'The clock is still running.', 'SEINE.', 'And why does it lead to the river?']));
        for (final s in [...fin.story, fin.letter, ...fin.hints, ...m3.transition]) {
          expect(s.toUpperCase(), isNot(contains('SEINE')), reason: s);
          expect(s.toUpperCase(), isNot(contains('STILL RUNNING')), reason: s);
        }
        expect(fin.feedback['why:vanished'], 'We have no proof of that yet.');
        expect(fin.feedback['q3:e3'], contains('what shows that someone went up there'));
      });
    }
  });

  group('Hints', () {
    test('as many at every level, never the answer; three different sets', () {
      for (final id in cases) {
        for (final m in baseCase(id).allMissions) {
          final sets = {for (final level in levels) at(m.id, level).hints.join('|')};
          expect(sets, hasLength(3), reason: '${m.id}: Rookie, Junior and Master each their own');
          for (final level in levels) {
            final hints = at(m.id, level).hints;
            expect(hints, hasLength(m.hints.length));
            // As the season's own rule: a choice's answer is its label; an
            // order is never in one hint.
            final answer = switch (m.type) {
              MissionType.multipleChoice || MissionType.imageChoice || MissionType.canvasChoice => m.answerLabel,
              MissionType.sequence => null,
              _ => m.answer,
            };
            for (final h in hints) {
              if (answer != null) {
                expect(AnswerChecker.normalize(h).contains(AnswerChecker.normalize(answer)), isFalse, reason: '${m.id} ${level.name}: "$h" gives away "$answer"');
              }
              expect(h, isNot(contains('{detectiveName}')));
            }
          }
        }
      }
    });
  });

  group('Discovery Moments', () {
    test('each title is the success line of the level played, never the base\'s', () {
      for (final id in cases) {
        for (final m in baseCase(id).missions) {
          expect(season2DiscoveryTypes[m.id], isNotNull, reason: m.id);
          final titles = <String>{};
          for (final level in levels) {
            final played = at(m.id, level);
            final d = SeasonCatalog.discovery(played);
            expect(d.title, played.successMessage, reason: '${m.id} at ${level.name}');
            expect(d.type, season2DiscoveryTypes[m.id]);
            if (level != Difficulty.rookie) expect(d.title, isNot(m.successMessage), reason: '${m.id}: no base title left behind');
            titles.add(d.title);
          }
          expect(titles, hasLength(3), reason: m.id);
        }
      }
    });
  });

  group('The parent report', () {
    test('each level names its own English, really on its pages', () {
      for (final id in cases) {
        for (final m in baseCase(id).allMissions) {
          final named = <String>{};
          for (final level in levels) {
            final played = at(m.id, level);
            final l = SeasonCatalog.learning(played)!;
            expect(l.isHonest, isTrue);
            expect(l.expressions, isNotEmpty);
            expect(LearningCheck.unmatched(l, played), isEmpty, reason: '${m.id} at ${level.name}');
            final b = season2Learning[m.id]!;
            expect((l.dependency, l.level, l.skill, l.recallFrom), (b.dependency, b.level, b.skill, b.recallFrom));
            named.add(l.expressions.join('|'));
          }
          expect(named.length, greaterThanOrEqualTo(2), reason: '${m.id}: the levels name different English');
        }
      }
    });

    for (final level in levels) {
      test('Paris played at ${level.name}: the report of Case 02 names ${level.name}\'s English', () async {
        String done(Episode e) => jsonEncode(GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: [for (final m in e.allMissions) m.id]).toJson());
        const pid = 'abcdef0123456789abcdef0123456789';
        String pk(String key) => AppConstants.profileKey(pid, key);
        final london = [for (final e in base) if (e.seasonId == SeasonIds.london) e];
        final c = ProviderContainer(overrides: await testOverrides(prefs: {
          AppConstants.detectiveStorageKey: jsonEncode({
            'schema': 1,
            'profile': {'id': pid, 'origin': 'fresh', 'walletBackfill': 'never', 'detectiveName': 'KIM', 'avatar': 'girl', 'difficulty': level.storageId},
          }),
          for (final e in london) pk(AppConstants.progressKeyFor(e.id)): done(e),
          pk(AppConstants.seasonKeyFor(SeasonIds.london)):
              jsonEncode(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: [for (final e in london) e.id]).toJson()),
          pk(AppConstants.seasonKeyFor(SeasonIds.paris)): jsonEncode(SeasonProgress(
            activeEpisodeId: 's2_ep02',
            solvedEpisodeIds: const ['s2_ep01'],
            prologueSeen: true,
            difficulty: level,
          ).toJson()),
          pk(AppConstants.progressKeyFor('s2_ep01')): done(baseCase('s2_ep01')),
          pk(AppConstants.progressKeyFor('s2_ep02')): done(baseCase('s2_ep02')),
          pk(AppConstants.selectedSeasonKey): jsonEncode({'seasonId': SeasonIds.paris}),
        }));
        addTearDown(c.dispose);
        expect(c.read(currentEpisodeProvider).id, 's2_ep02');
        final report = DetectiveReport.from(c.read(currentEpisodeProvider), c.read(gameControllerProvider));
        for (final m in baseCase('s2_ep02').allMissions) {
          final p = report.performances.firstWhere((p) => p.mission.id == m.id);
          expect(p.learning!.expressions, SeasonCatalog.learning(at(m.id, level))!.expressions, reason: '${m.id} at ${level.name}');
        }
        expect(c.read(currentEpisodeProvider).allMissions.first.story, at('s2_ep02_m1', level).story);
      });
    }

    test('an old save (no level anywhere) plays the game\'s own words', () async {
      final c = ProviderContainer(overrides: await testOverrides(prefs: {
        AppConstants.progressKeyFor('s2_ep01'):
            jsonEncode(const GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: ['s2_ep01_m1']).toJson()),
      }));
      addTearDown(c.dispose);
      final played = c.read(playedEpisodesProvider).firstWhere((e) => e.id == 's2_ep01');
      expect(played.allMissions.first.difficulty, Difficulty.rookie);
      expect(fields(played), fields(baseCase('s2_ep01')));
      expect(played.glossary['pocket'], isNotNull, reason: 'Rookie\'s glossary, grown');
    });
  });

  group('On screen', () {
    for (final level in levels) {
      testWidgets('Case 01 M3 at ${level.name}: the old clock in ${level.name}\'s words', (t) async {
        t.view.physicalSize = const Size(390, 844) * 3;
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.reset);
        GameProgress solved(Episode e) => GameProgress(
              detectiveName: 'KIM',
              introSeen: true,
              completedMissionIds: [for (final m in e.allMissions) m.id],
              startedAt: DateTime(2026, 10, 20, 10),
              completedAt: DateTime(2026, 10, 20, 10, 30),
            );
        const pid = 'abcdef0123456789abcdef0123456789';
        String pk(String key) => AppConstants.profileKey(pid, key);
        final london = [for (final e in base) if (e.seasonId == SeasonIds.london) e];
        late WidgetRef ref;
        await t.pumpWidget(ProviderScope(
          overrides: [
            ...await testOverrides(prefs: {
              AppConstants.detectiveStorageKey: jsonEncode({
                'schema': 1,
                'profile': {'id': pid, 'origin': 'fresh', 'walletBackfill': 'never', 'detectiveName': 'KIM', 'avatar': 'girl', 'difficulty': level.storageId},
              }),
              for (final e in london) pk(AppConstants.progressKeyFor(e.id)): jsonEncode(solved(e).toJson()),
              pk(AppConstants.seasonKeyFor(SeasonIds.london)):
                  jsonEncode(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: [for (final e in london) e.id]).toJson()),
            }),
            seasonPreviewProvider.overrideWithValue(true),
          ],
          child: Consumer(builder: (context, r, _) {
            ref = r;
            return const LondonMysteryApp();
          }),
        ));
        await wait(t, const Duration(milliseconds: 300));
        final game = ref.read(gameControllerProvider.notifier);
        expect(game.openSeason(SeasonIds.paris), isTrue);
        expect(game.openEpisode('s2_ep01'), isTrue);
        game.startInvestigation();
        final played = ref.read(currentEpisodeProvider);
        expect(played.allMissions.first.difficulty, level, reason: 'Paris fixed at the profile\'s level');
        for (final m in played.allMissions.take(2)) {
          game.submitAnswer(m, m.answer);
        }
        ref.read(routerProvider).go(Routes.mission('s2_ep01_m3'));
        await wait(t, const Duration(milliseconds: 1400));
        // Its story first, in the level's words; then the clock.
        expect(findReadable(at('s2_ep01_m3', level).story.first), findsOneWidget, reason: level.name);
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
        // The carving, in the level's words.
        expect(findReadable(at('s2_ep01_m3', level).letterIntro), findsOneWidget);
        await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
        expect(findReadableContaining(at('s2_ep01_m3', level).letter.split('\n').first), findsWidgets);
        await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 1400));
        final clock = SeasonCatalog.clock(at('s2_ep01_m3', level))!;
        expect(findReadable(clock.question), findsOneWidget, reason: level.name);
        expect(findReadable(clock.lead), findsOneWidget);
        expect(findReadable(clock.guide), findsOneWidget, reason: 'how to drag the hands, the same at every level');
        for (final other in levels.where((l) => l != level)) {
          expect(findReadable(SeasonCatalog.clock(at('s2_ep01_m3', other))!.question), findsNothing);
        }
        expect(t.takeException(), isNull);
        await wait(t, const Duration(seconds: 2));
      });
    }
  });
}
