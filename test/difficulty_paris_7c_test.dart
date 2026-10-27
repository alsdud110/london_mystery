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
import 'package:london_mystery/data/mock/season2/season2_case08_scenes.dart';
import 'package:london_mystery/data/mock/season2/season2_case09_scenes.dart';
import 'package:london_mystery/data/mock/season2/season2_difficulty.dart';
import 'package:london_mystery/data/mock/season2/season2_discoveries.dart';
import 'package:london_mystery/data/mock/season2/season2_learning.dart';
import 'package:london_mystery/data/mock/season_catalog.dart';
import 'package:london_mystery/data/models/difficulty.dart';
import 'package:london_mystery/data/models/easy_steps.dart';
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

import 'easy_play.dart';
import 'full_playthrough_test.dart' show tapText, wait;
import 'helpers.dart';

/// Difficulty PART 7C: Paris Cases 07–09 written at Rookie, Junior and
/// Master. The words change with the level; the case — its answers, ids,
/// orders, hints' number and price, clues, evidence, rewards, its scenes'
/// papers and what stays untold — never does
/// (docs/difficulty_reviews/PARIS_CASE_07_09.md).

final base = MockEpisodeRepository.bundled();
const cases = ['s2_ep07', 's2_ep08', 's2_ep09'];
const levels = Difficulty.values;
const written = [Difficulty.junior, Difficulty.master];

Episode baseCase(String id) => base.firstWhere((e) => e.id == id);
Episode caseAt(String id, Difficulty level) => DifficultyContent.episodeAt(baseCase(id), level);
Mission at(String missionId, Difficulty level) =>
    DifficultyContent.episodeAt(base.firstWhere((e) => e.allMissions.any((m) => m.id == missionId)), level).missionById(missionId)!;

/// Everything a mission says, before and after its puzzle.
String missionWords(Mission m) => [
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
  m.recall?.title ?? '',
  m.recall?.prompt ?? '',
  ...?m.recall?.feedback.values,
  m.clue?.note ?? '',
  m.evidence?.description ?? '',
  m.evidence?.inscription ?? '',
].join('\n');

/// Everything a case says.
String everything(Episode e) => [...e.intro, ...e.synopsis, ...e.objectives, e.hook, e.caseSummary, for (final m in e.allMissions) missionWords(m)].join('\n');

/// What a mission's scenes say at its level.
String sceneWords(Mission m) => [
  if (SeasonCatalog.flyRail(m) case final s?) ...[s.clueLine, s.task, s.pocketTask],
  if (SeasonCatalog.lightTable(m) case final s?) ...[s.chooseTask, s.placeTask, s.lightTask, s.pinTask],
  if (SeasonCatalog.cornerChoice(m) case final s?) ...[s.task, s.squareLabel],
  if (SeasonCatalog.morningSketches(m) case final s?) ...[s.lampLine, s.skyLine, s.orderedLine, s.questionTask, s.orderTask, s.compareTask],
  if (SeasonCatalog.tornSlip(m) case final s?) ...[for (final p in s.parts) ?p.line, for (final c in s.sealChecks) c.wrongLine, ...s.noteLines],
  if (SeasonCatalog.tornHour(m) case final s?) ...[
    s.placeHeading,
    s.tearLine,
    s.sealLine,
    s.offLine,
    ...s.placedLines,
    for (final p in [...s.lead.bagParts, s.lead.decoy]) p.line,
    ...s.lead.bagDone,
    ...s.lead.feedback.values,
    s.lead.otherLine,
    ...s.lead.doneLines,
  ],
  if (SeasonCatalog.trialMap(m) case final s?) ...[for (final x in s.models) x.wrongLine, ...s.specialLines.values, s.placedLine],
  if (SeasonCatalog.gearBoard(m) case final s?) ...[s.turningLine, s.tooBig, s.tooSmall, s.oneMore],
  if (SeasonCatalog.makerMarks(m) case final s?) ...[...s.lines.values, s.pickFirst],
  if (SeasonCatalog.towerTest(m) case final s?) ...[
    ...s.hourLines.values,
    ...s.testedLines,
    ...s.afterLines,
    s.lead.question,
    s.lead.otherLine,
    s.lead.foundLine,
    ...s.lead.doneLines,
  ],
  if (SeasonCatalog.easySteps(m) case final s?) easyWords(s),
].join('\n');

/// The words of a mission before its answer is known.
String beforeAnswer(Mission m) => [
  m.letter,
  m.letterIntro,
  m.question,
  ...m.story,
  ...m.hints,
  for (final o in m.options) o.feedback ?? '',
  ...m.feedback.values,
  if (SeasonCatalog.easySteps(m) case final s?)
    for (final st in s.steps) ...[st.say, ...st.hints, for (final o in st.options) ?o.feedback],
].join('\n');

/// Every written text of a case, by where it is (`case.field` / `m.field[i]`).
Map<String, String?> fields(Episode e) => {
  '${e.id}.intro': e.intro.join('\n'),
  '${e.id}.synopsis': e.synopsis.join('\n'),
  '${e.id}.objectives': e.objectives.join('\n'),
  '${e.id}.caseSummary': e.caseSummary,
  '${e.id}.hook': e.hook,
  for (final m in e.allMissions) ...{
    '${m.id}.story': m.story.join('\n'),
    '${m.id}.letterIntro': m.letterIntro,
    '${m.id}.letter': m.letter,
    '${m.id}.question': m.question,
    for (final (i, h) in m.hints.indexed) '${m.id}.hints[$i]': h,
    '${m.id}.successMessage': m.successMessage,
    for (final (i, l) in m.transition.indexed) '${m.id}.transition[$i]': l,
    for (final k in m.feedback.keys) '${m.id}.feedback[$k]': m.feedback[k],
    for (final o in m.options) '${m.id}.options[${o.id}].feedback': o.feedback,
    if (m.recall case final r?) ...{
      '${m.id}.recall.title': r.title,
      '${m.id}.recall.prompt': r.prompt,
      for (final k in r.feedback.keys) '${m.id}.recall.feedback[$k]': r.feedback[k],
    },
    '${m.id}.clue.note': m.clue?.note,
    '${m.id}.evidence.description': m.evidence?.description,
  },
};

/// The lines kept word for word at every level, on purpose: the papers the
/// puzzles are read from (and quoted after them), the question that is
/// also the board's, the way to play that is the mission's question, and
/// the question Case 10 begins from.
const keptAtEveryLevel = {
  // FILE 3–4, the Lighting Book, the Painted Street, the slip.
  's2_ep07_m1.letter',
  's2_ep07_m2.letter',
  's2_ep07_m2.question',
  's2_ep07_m2.transition[2]',
  's2_ep07_m3.letter',
  's2_ep07_m3.transition[3]',
  's2_ep07_final.letter',
  's2_ep07_final.transition[5]',
  // His sketch notes, tag and note; the evidence on the board; the board's
  // own question.
  's2_ep08_m1.letter',
  's2_ep08_m2.letter',
  's2_ep08_m3.letter',
  's2_ep08_final.letter',
  's2_ep08_final.question',
  // The words beside the Little Paris and on its board, the notebook's
  // marks, the test card, the drum's tag; Case 10's first question.
  's2_ep09_m1.letter',
  's2_ep09_m2.letter',
  's2_ep09_m2.transition[2]',
  's2_ep09_m3.letter',
  's2_ep09_final.letter',
  's2_ep09.hook',
};

/// Lines no level can show since these puzzles are played very easy
/// (2026-10-27): their steps never send a wrong answer. Kept as the base's.
bool unreachable(String key) => key.startsWith('s2_ep07_m1.options[') || key.startsWith('s2_ep07_m2.options[') || key.startsWith('s2_ep07_final.feedback[');

/// Rookie's own lines (the rest of Rookie is the game's own words).
const rookieLines = {'s2_ep09_m3.transition[1]'};

const pid = 'abcdef0123456789abcdef0123456789';
String pk(String key) => AppConstants.profileKey(pid, key);

/// A player whose London is solved and whose Paris is at [level] (the
/// profile at [profile], or the same), playing [active], the cases before
/// it solved; [progress]: the saves of the cases named.
Map<String, Object> parisAt(Difficulty level, {required String active, Difficulty? profile, Map<String, GameProgress> progress = const {}}) {
  String done(Episode e) =>
      jsonEncode(GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: [for (final m in e.allMissions) m.id]).toJson());
  final london = [
    for (final e in base)
      if (e.seasonId == SeasonIds.london) e,
  ];
  final before = [
    for (final e in base)
      if (e.seasonId == SeasonIds.paris && e.number < baseCase(active).number) e,
  ];
  return {
    AppConstants.detectiveStorageKey: jsonEncode({
      'schema': 1,
      'profile': {
        'id': pid,
        'origin': 'fresh',
        'walletBackfill': 'never',
        'detectiveName': 'KIM',
        'avatar': 'girl',
        'difficulty': (profile ?? level).storageId,
      },
    }),
    for (final e in [...london, ...before]) pk(AppConstants.progressKeyFor(e.id)): done(e),
    for (final MapEntry(:key, :value) in progress.entries) pk(AppConstants.progressKeyFor(key)): jsonEncode(value.toJson()),
    pk(AppConstants.seasonKeyFor(SeasonIds.london)): jsonEncode(
      SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: [for (final e in london) e.id]).toJson(),
    ),
    pk(AppConstants.seasonKeyFor(SeasonIds.paris)): jsonEncode(
      SeasonProgress(activeEpisodeId: active, solvedEpisodeIds: [for (final e in before) e.id], prologueSeen: true, difficulty: level).toJson(),
    ),
    pk(AppConstants.selectedSeasonKey): jsonEncode({'seasonId': SeasonIds.paris}),
  };
}

void main() {
  group('Written: nothing falls back unseen', () {
    test('Cases 07–09 are marked written at every level, and nothing of theirs falls back', () {
      expect(DifficultyContent.problems(), isEmpty);
      for (final id in cases) {
        expect(season2Content.writtenLevels[id], {...levels}, reason: id);
        for (final level in levels) {
          expect(DifficultyContent.missingAt(id, level), isEmpty, reason: '$id at ${level.name}');
        }
      }
      // Later cases are later PARTs'; the newest PART's test holds the
      // whole set (difficulty_paris_7d_test.dart: the whole season).
      expect(season2Content.writtenLevels.keys, containsAll(cases));
    });

    test('Junior and Master each have their own line everywhere but the lines kept on purpose', () {
      for (final id in cases) {
        final b = fields(baseCase(id));
        final j = fields(caseAt(id, Difficulty.junior));
        final m = fields(caseAt(id, Difficulty.master));
        for (final key in b.keys) {
          if (b[key] == null) continue;
          if (unreachable(key)) {
            expect((j[key], m[key]), (b[key], b[key]), reason: key);
            continue;
          }
          final kept = keptAtEveryLevel.contains(key);
          expect(j[key] == b[key], kept, reason: 'Junior $key: ${j[key]}');
          expect(m[key] == b[key], kept, reason: 'Master $key: ${m[key]}');
          expect(m[key] == j[key], kept, reason: 'Master = Junior $key: ${m[key]}');
        }
      }
    });

    test('Rookie plays the game\'s own words but one plainer line; its glossary grows', () {
      for (final id in cases) {
        final b = baseCase(id);
        final r = caseAt(id, Difficulty.rookie);
        final (fb, fr) = (fields(b), fields(r));
        for (final key in fb.keys) {
          expect(fr[key] == fb[key], !rookieLines.contains(key), reason: 'Rookie $key: ${fr[key]}');
        }
        expect(r.glossary.keys, containsAll(b.glossary.keys));
        expect(r.glossary.length, greaterThan(b.glossary.length), reason: id);
        for (final m in r.allMissions) {
          expect(SeasonCatalog.learning(m)!.expressions, season2Learning[m.id]!.expressions, reason: m.id);
          season2Content.missionTables.forEach((table, entries) {
            if (entries[m.id] != null) expect(season2Variants[Difficulty.rookie]?.missionTables[table]?[m.id], isNull, reason: '$table/${m.id}');
          });
        }
      }
      expect(at('s2_ep09_m3', Difficulty.rookie).transition[1], 'The two hands are on the repair note. No. 7 fixed a trial wheel.');
    });

    test('Every glossary word of a level is on its pages; keys are lower-case single words', () {
      for (final id in cases) {
        for (final level in levels) {
          final e = caseAt(id, level);
          final text = ' ${LearningCheck.words('${everything(e)}\n${[for (final m in e.allMissions) sceneWords(m)].join('\n')}')} ';
          final own = (season2CasePatches[level]![id]!['glossary'] as Map?) ?? const {};
          expect(own, isNotEmpty, reason: '$id at ${level.name}');
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
          expect(e.intro.length, b.intro.length, reason: '$id: its pictures come after the same lines');
          for (final (i, m) in e.allMissions.indexed) {
            final o = b.allMissions[i];
            expect(
              (m.id, m.title, m.location, m.type, m.answer, m.hints.length, m.nextMissionId, m.hideOptionNames),
              (o.id, o.title, o.location, o.type, o.answer, o.hints.length, o.nextMissionId, o.hideOptionNames),
            );
            expect([for (final x in m.options) '${x.id}:${x.label}'], [for (final x in o.options) '${x.id}:${x.label}'], reason: '${m.id}: options, in order');
            expect(m.feedback.keys, o.feedback.keys);
            expect(m.recall?.evidenceId, o.recall?.evidenceId);
            expect(m.recall?.feedback.keys, o.recall?.feedback.keys);
            expect((m.clue?.id, m.clue?.title, m.clue?.value), (o.clue?.id, o.clue?.title, o.clue?.value));
            expect((m.evidence?.id, m.evidence?.name, m.evidence?.inscription), (o.evidence?.id, o.evidence?.name, o.evidence?.inscription));
            expect((m.story.length, m.transition.length), (o.story.length, o.transition.length), reason: m.id);
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
              expect(AnswerChecker.isCorrect(m, o.id), isFalse);
              expect(AnswerChecker.feedbackFor(m, o.id), o.feedback, reason: '${m.id} ${o.id}');
            }
            if (m.recall case final r?) {
              for (final ev in r.feedback.keys) {
                expect(r.missFor(ev), r.feedback[ev], reason: '${m.id} recall $ev at ${level.name}');
              }
            }
          }
        }
      }
      // A recall's line is its level's own.
      expect(at('s2_ep08_m3', Difficulty.master).recall!.missFor('s2_ep05_e1'), isNot(at('s2_ep08_m3', Difficulty.rookie).recall!.missFor('s2_ep05_e1')));
    });

    test('each scene: its level\'s words on the base\'s structure; papers and ways to play the same at every level', () {
      final tables = <String>{};
      for (final level in written) {
        final v = season2Variants[level]!;
        for (final MapEntry(key: table, value: entries) in v.missionTables.entries) {
          for (final MapEntry(key: id, value: entry) in entries.entries) {
            if (table == 'learning' || !cases.any(id.startsWith)) continue;
            tables.add('$table/$id');
            final b = season2Content.missionTables[table]![id];
            expect(DifficultyContent.structureOf(entry), isNotNull, reason: '$table/$id');
            expect(DifficultyContent.structureOf(entry), DifficultyContent.structureOf(b), reason: '$table/$id at ${level.name}');
            final kept = season2SameAtEveryLevel.contains('$table/$id');
            expect(identical(entry, b), kept, reason: '$table/$id: ${kept ? 'kept' : 'its own words'}');
          }
        }
        final sketches = SeasonCatalog.morningSketches(at('s2_ep08_m2', level))!, baseSketches = season2MorningSketches['s2_ep08_m2']!;
        expect(
          (sketches.orderTask, sketches.compareTask, sketches.checkOrderLabel),
          (baseSketches.orderTask, baseSketches.compareTask, baseSketches.checkOrderLabel),
        );
        expect(sketches.questionTask, at('s2_ep08_m2', level).question, reason: 'the question after the drawings is the mission\'s own');
        final slip = SeasonCatalog.tornSlip(at('s2_ep08_m3', level))!, baseSlip = season2TornSlips['s2_ep08_m3']!;
        expect(slip.noteLines, baseSlip.noteLines);
        expect(at('s2_ep08_m3', level).letter, slip.noteLines.join('\n'), reason: 'his note, as on the page');
        expect(
          [for (final c in slip.sealChecks) '${c.question}${c.choices}${c.answer}'],
          [for (final c in baseSlip.sealChecks) '${c.question}${c.choices}${c.answer}'],
        );
        final hour = SeasonCatalog.tornHour(at('s2_ep08_final', level))!, baseHour = season2TornHours['s2_ep08_final']!;
        expect(identical(hour.board, baseHour.board), isTrue, reason: 'the board\'s questions and conclusions');
        expect([for (final q in hour.board.questions) q.text], [for (final o in at('s2_ep08_final', level).options.take(2)) o.label]);
        expect(
          (hour.placeTask, hour.turnLabel, hour.layLabel, hour.lead.bagTask, hour.lead.mapTask),
          (baseHour.placeTask, baseHour.turnLabel, baseHour.layLabel, baseHour.lead.bagTask, baseHour.lead.mapTask),
        );
        expect(hour.lead.doneLines.first, 'The Luxembourg Gardens!');
        final map = SeasonCatalog.trialMap(at('s2_ep09_m1', level))!;
        expect((map.task, map.placedLine), (season2TrialMap.task, season2TrialMap.placedLine));
        final gears = SeasonCatalog.gearBoard(at('s2_ep09_m2', level))!;
        expect(
          (gears.task, gears.tooBig, gears.tooSmall, gears.oneMore),
          (season2GearBoard.task, season2GearBoard.tooBig, season2GearBoard.tooSmall, season2GearBoard.oneMore),
        );
        final tower = SeasonCatalog.towerTest(at('s2_ep09_final', level))!;
        expect(
          (tower.handsLine, tower.testLabel, tower.leadLabel, tower.lead.tag),
          (season2TowerTest.handsLine, season2TowerTest.testLabel, season2TowerTest.leadLabel, season2TowerTest.lead.tag),
        );
        expect(tower.lead.tag, 'TRIAL RECORDS · KEPT AT THE STAR');
      }
      expect(tables, {
        'flyRails/s2_ep07_m3',
        'lightTables/s2_ep07_final',
        'easySteps/s2_ep07_m1',
        'easySteps/s2_ep07_m2',
        'easySteps/s2_ep07_final',
        'cornerChoices/s2_ep08_m1',
        'morningSketches/s2_ep08_m2',
        'tornSlips/s2_ep08_m3',
        'tornHours/s2_ep08_final',
        'trialMaps/s2_ep09_m1',
        'gearBoards/s2_ep09_m2',
        'makerMarks/s2_ep09_m3',
        'towerTests/s2_ep09_final',
      }, reason: 'every scene of Cases 07–09, at both levels');
      // Each kind's check reads what matters: two scenes of a kind differ.
      expect(DifficultyContent.structureOf(season2TornSlips['s2_ep08_m3']), contains('None,One,Two'));
      expect(DifficultyContent.structureOf(season2TowerTests['s2_ep09_final']), contains('t1:T1:true'));
    });

    test('the very easy steps: the same steps, choices, answers and free hints; each level\'s words', () {
      for (final id in ['s2_ep07_m1', 's2_ep07_m2', 's2_ep07_final']) {
        final b = season2Content.easySteps[id]!;
        final says = <String>{};
        for (final level in levels) {
          final m = at(id, level);
          final s = SeasonCatalog.easySteps(m)!;
          expect((s.title, s.answer, s.finishLabel, s.seen), (b.title, b.answer, b.finishLabel, b.seen));
          expect(s.answer, m.answer);
          for (final (i, step) in s.steps.indexed) {
            final o = b.steps[i];
            expect(
              (step.id, step.does, step.answer, step.hints.length, step.button, step.doneButton),
              (o.id, o.does, o.answer, o.hints.length, o.button, o.doneButton),
            );
            expect([for (final x in step.options) '${x.id}:${x.label}'], [for (final x in o.options) '${x.id}:${x.label}']);
            expect(identical(step.panels, o.panels), isTrue);
            expect(identical(step.after, o.after), isTrue);
            if (step.does == EasyDo.choose) {
              final right = step.options.firstWhere((x) => x.id == step.answer).label!;
              for (final h in step.hints.take(step.hints.length - 1)) {
                expect(h, isNot(contains(right)), reason: '$id ${level.name}: "$h"');
              }
            }
          }
          says.add(easyWords(s));
        }
        expect(says, hasLength(3), reason: '$id: each level its own words');
      }
      // The mission's hints are its step's (M1, M2), at every level.
      for (final level in levels) {
        for (final id in ['s2_ep07_m1', 's2_ep07_m2']) {
          expect(at(id, level).hints, SeasonCatalog.easySteps(at(id, level))!.steps.first.hints, reason: '$id ${level.name}');
        }
        final cue = SeasonCatalog.easySteps(at('s2_ep07_m2', level))!.steps[1];
        expect(cue.say, 'Read the cue card.');
        expect(cue.hints, ['CUE 1 · CURTAIN UP · 4:00.'], reason: 'the card, read out');
        final fin = SeasonCatalog.easySteps(at('s2_ep07_final', level))!;
        expect([for (final s in fin.steps.take(2)) s.say], ['Find FILE 3.', 'Turn on the light.'], reason: 'ways to play');
      }
    });
  });

  group('What each case keeps untold, at every level', () {
    for (final level in levels) {
      test('Case 07 at ${level.name}', () {
        final e = caseAt('s2_ep07', level);
        final [m1, m2, m3, fin] = e.allMissions;
        final all = '${everything(e)}\n${[for (final m in e.allMissions) sceneWords(m)].join('\n')}';
        expect(m1.letter, allOf(contains('DOORS OPEN · 3:30 PM'), contains('CURTAIN UP · 3:00 PM'), contains('2 HOURS 10 MINUTES')));
        for (final h in [...m1.hints, ...SeasonCatalog.easySteps(m1)!.steps.single.hints]) {
          expect(h, allOf(isNot(contains('4:00')), isNot(contains('4 PM'))), reason: h);
        }
        expect(m1.transition.join(' '), contains('3:00 PM · CURTAIN UP!'));
        expect(m2.transition, contains('CUE 1 · CURTAIN UP · 4:00.'));
        expect(m3.transition, contains('FILE 3 · PERFORMANCE No. 34 · CURTAIN UP: 4:00 to 3:00.'));
        expect(m3.transition.where((l) => l.contains('P.') && l.contains('?')), isNotEmpty, reason: 'whether P. painted it: a question');
        expect(fin.transition, containsAllInOrder([contains('ABBESSES'), 'Under it: P. KNEW THE BAG.']));
        expect(fin.transition.any((l) => l.contains('Eiffel Tower')), isTrue);
        // Who changed it and why: untold. No name, no initials.
        for (final absent in ['VICTOR', 'EMILE', 'ÉMILE', 'E.M.', 'V.D.', 'CLOCKMAKER', 'DELACROIX', 'MOREAU', 'BECAUSE']) {
          expect(all.toUpperCase(), isNot(contains(absent)), reason: absent);
        }
        expect(beforeAnswer(fin).toUpperCase(), isNot(contains('ABBESSES')));
        for (final m in [m1, m2, m3]) {
          expect('${missionWords(m)}\n${sceneWords(m)}'.toUpperCase(), allOf(isNot(contains('ABBESSES')), isNot(contains('KNEW THE BAG'))), reason: m.id);
        }
      });

      test('Case 08 at ${level.name}', () {
        final e = caseAt('s2_ep08', level);
        final [m1, m2, m3, fin] = e.allMissions;
        final all = '${everything(e)}\n${[for (final m in e.allMissions) sceneWords(m)].join('\n')}';
        expect(e.intro[2], 'Under it: P. KNEW THE BAG.', reason: 'the slip is shown after this line');
        expect(m2.letter, contains('When the sun came up, the lamps went out.'));
        expect(m3.letter, 'I found this paper on the steps.\nI kept it with my drawings.\n— P.');
        for (final h in m1.hints) {
          expect(h, isNot(contains('Corner 2')), reason: h);
          expect(h.toLowerCase(), isNot(contains('black')), reason: 'the colour is read from the sketch: $h');
        }
        for (final h in m2.hints) {
          expect(h.toLowerCase(), isNot(contains('fell')), reason: h);
        }
        // No face, no name, no meaning for the badge; the paper's record and
        // hour unknown; the little clock's purpose untold.
        for (final absent in ['VICTOR', 'EMILE', 'ÉMILE', 'E.M.', 'V.D.', 'CLOCKMAKER', 'OFFICE', 'CHRONOS', 'TRIAL', 'FILE 3 ·  ']) {
          expect(all.toUpperCase(), isNot(contains(absent)), reason: absent);
        }
        expect(m2.transition.where((l) => l.contains('face')), hasLength(1));
        expect(fin.transition.where((l) => l.contains('face')), hasLength(1));
        expect(fin.transition.last, contains('Luxembourg Gardens'));
        for (final m in [m1, m2, m3]) {
          expect('${missionWords(m)}\n${sceneWords(m)}', isNot(contains('Luxembourg')), reason: m.id);
        }
        expect(beforeAnswer(fin), isNot(contains('Luxembourg')));
        // The board's conclusion the evidence supports, as worded.
        expect(SeasonCatalog.tornHour(fin)!.board.conclusions.map((c) => c.text), contains('A paper for changing a time fell from the bag.'));
        expect(fin.feedback['why:who'], anyOf(contains('really'), contains('truly')));
      });

      test('Case 09 at ${level.name}', () {
        final e = caseAt('s2_ep09', level);
        final [m1, m2, m3, fin] = e.allMissions;
        final all = '${everything(e)}\n${[for (final m in e.allMissions) sceneWords(m)].join('\n')}';
        expect(m3.letter, contains('Signed with two clock hands.'));
        expect(m2.transition, contains('Its tag says: TRIAL RECORDS · KEPT AT THE STAR.'));
        // Whether one person made both marks: a question the papers leave.
        expect(m3.transition.where((l) => l.contains('papers') && (l.contains('do not say') || l.contains('silent'))), hasLength(1));
        expect(e.hook, 'Was the hour lost — or was the clock wrong?', reason: 'Case 10 begins from it');
        for (final h in m1.hints) {
          for (final place in ['Arc de Triomphe', 'Seine', 'Arts et Métiers']) {
            expect(h, isNot(contains(place)), reason: h);
          }
        }
        for (final h in fin.hints) {
          expect(h, isNot(contains('joined clocks went wrong')), reason: h);
        }
        expect(fin.transition.where((l) => l.contains('lost?')), hasLength(1), reason: 'whether an hour was lost: a question');
        for (final absent in ['VICTOR', 'EMILE', 'ÉMILE', 'E.M.', 'V.D.', 'MOREAU', 'DELACROIX', 'SAINT-SULPICE', 'PAGE 3']) {
          expect(all.toUpperCase(), isNot(contains(absent)), reason: absent);
        }
        // The star's place: only once the drawer's tag and the test lead there.
        expect(beforeAnswer(m1), isNot(contains('Arc de Triomphe')));
        for (final m in [m2, m3]) {
          expect('${missionWords(m)}\n${sceneWords(m)}', isNot(contains('Arc de Triomphe')), reason: m.id);
        }
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
            final answer = switch (m.type) {
              MissionType.multipleChoice || MissionType.imageChoice => m.answerLabel,
              _ => null,
            };
            for (final h in hints) {
              if (answer != null) {
                expect(AnswerChecker.normalize(h).contains(AnswerChecker.normalize(answer)), isFalse, reason: '${m.id} ${level.name}: "$h"');
              }
            }
          }
        }
      }
    });

    test('hints opened are kept whatever the level', () async {
      for (final level in levels) {
        final c = ProviderContainer(
          overrides: await testOverrides(
            prefs: parisAt(
              level,
              active: 's2_ep08',
              progress: {
                's2_ep08': const GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: ['s2_ep08_m1'], hintsUsed: {'s2_ep08_m2': 2}),
              },
            ),
          ),
        );
        addTearDown(c.dispose);
        final played = c.read(currentEpisodeProvider);
        expect((played.id, played.allMissions.first.difficulty), ('s2_ep08', level));
        expect(c.read(gameControllerProvider).hintsFor('s2_ep08_m2'), 2, reason: level.name);
        expect(played.missionById('s2_ep08_m2')!.hints, at('s2_ep08_m2', level).hints);
      }
    });
  });

  group('Discovery Moments', () {
    test('each title is the success line of the level played', () {
      for (final id in cases) {
        for (final m in baseCase(id).missions) {
          expect(season2DiscoveryTypes[m.id], isNotNull, reason: m.id);
          final titles = <String>{};
          for (final level in levels) {
            final played = at(m.id, level);
            final d = SeasonCatalog.discovery(played);
            expect(d.title, played.successMessage, reason: '${m.id} at ${level.name}');
            expect(d.type, season2DiscoveryTypes[m.id]);
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
            expect(LearningCheck.unmatched(l, played), isEmpty, reason: '${m.id} at ${level.name}');
            final b = season2Learning[m.id]!;
            expect((l.dependency, l.level, l.skill, l.recallFrom, l.objective), (b.dependency, b.level, b.skill, b.recallFrom, b.objective));
            named.add(l.expressions.join('|'));
          }
          expect(named, hasLength(3), reason: m.id);
        }
      }
    });

    for (final level in levels) {
      test('Paris played at ${level.name}: the report of Case 08 names ${level.name}\'s English, whatever the profile says later', () async {
        final other = levels[(level.index + 1) % levels.length];
        final c = ProviderContainer(
          overrides: await testOverrides(
            prefs: parisAt(
              level,
              active: 's2_ep08',
              profile: other,
              progress: {
                's2_ep08': GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: [for (final m in baseCase('s2_ep08').allMissions) m.id]),
              },
            ),
          ),
        );
        addTearDown(c.dispose);
        final report = DetectiveReport.from(c.read(currentEpisodeProvider), c.read(gameControllerProvider));
        for (final m in baseCase('s2_ep08').allMissions) {
          final p = report.performances.firstWhere((p) => p.mission.id == m.id);
          expect(p.learning!.expressions, SeasonCatalog.learning(at(m.id, level))!.expressions, reason: '${m.id} at ${level.name}');
        }
      });
    }

    test('an old save (no level anywhere) plays Rookie\'s words', () async {
      final c = ProviderContainer(
        overrides: await testOverrides(
          prefs: {
            AppConstants.progressKeyFor('s2_ep09'): jsonEncode(
              const GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: ['s2_ep09_m1']).toJson(),
            ),
          },
        ),
      );
      addTearDown(c.dispose);
      final played = c.read(playedEpisodesProvider).firstWhere((e) => e.id == 's2_ep09');
      expect(played.allMissions.first.difficulty, Difficulty.rookie);
      expect(fields(played), fields(caseAt('s2_ep09', Difficulty.rookie)));
    });
  });

  group('On screen', () {
    /// Paris at [level], Case 07 open, its first mission's page.
    Future<WidgetRef> openCase07(WidgetTester t, Difficulty level, Size size, {double textScale = 1}) async {
      await loadGameFonts();
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      t.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      late WidgetRef ref;
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            ...await testOverrides(prefs: {...parisAt(level, active: 's2_ep07')}..remove(pk(AppConstants.selectedSeasonKey))),
            seasonPreviewProvider.overrideWithValue(true),
          ],
          child: Consumer(
            builder: (context, r, _) {
              ref = r;
              return RepaintBoundary(key: const ValueKey('shot'), child: const LondonMysteryApp());
            },
          ),
        ),
      );
      await wait(t, const Duration(milliseconds: 300));
      final game = ref.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      expect(game.openEpisode('s2_ep07'), isTrue);
      game.startInvestigation();
      expect(ref.read(currentEpisodeProvider).allMissions.first.difficulty, level);
      ref.read(routerProvider).go(Routes.mission('s2_ep07_m1'));
      await wait(t, const Duration(milliseconds: 1400));
      return ref;
    }

    /// Its story, then its step: line, free hint, a wrong answer, the right.
    Future<void> playM1(WidgetTester t, Difficulty level, String tag) async {
      final m = at('s2_ep07_m1', level);
      final play = EasyPlay(t, tag);
      expect(findReadable(m.story.first), findsOneWidget, reason: '$tag: the story in its level\'s words');
      await play.shot('story');
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 1200));
      final step = SeasonCatalog.easySteps(m)!.steps.single;
      play.expectSay(step.say);
      for (final other in levels.where((l) => l != level)) {
        expect(findReadable(SeasonCatalog.easySteps(at('s2_ep07_m1', other))!.steps.single.say), findsNothing, reason: '$tag: not ${other.name}\'s');
      }
      for (final k in ['easy-option-3', 'easy-option-4']) {
        final r = t.getRect(find.byKey(ValueKey(k)));
        expect(r.width >= 44 && r.height >= 44, isTrue, reason: '$tag $k');
      }
      await play.shot('step');
      await play.tapKey('easy-hint');
      expect(findReadable(step.hints.first), findsOneWidget, reason: '$tag: its level\'s hint');
      await play.tapKey('easy-option-3');
      expect(findReadable(step.option('3')!.feedback!), findsOneWidget);
      await play.shot('wrong');
      await play.tapKey('easy-option-4');
      expect(findReadable(step.done!), findsOneWidget);
      await play.shot('done');
    }

    for (final level in levels) {
      testWidgets('Case 07 M1 at ${level.name} (390 × 844)', (t) async {
        await openCase07(t, level, const Size(390, 844));
        await playM1(t, level, '7c_${level.name}');
        expect(t.takeException(), isNull);
        await wait(t, const Duration(seconds: 2));
      });
    }

    testWidgets('Case 07 M1 at Master on a small phone, its words 1.3 times larger', (t) async {
      await openCase07(t, Difficulty.master, const Size(360, 640), textScale: 1.3);
      await playM1(t, Difficulty.master, '7c_master_small');
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 2));
    });

    testWidgets('Case 07 M1 at Master on a tablet', (t) async {
      await openCase07(t, Difficulty.master, const Size(834, 1194));
      await playM1(t, Difficulty.master, '7c_master_tablet');
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 2));
    });
  });
}
