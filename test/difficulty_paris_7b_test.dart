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
import 'package:london_mystery/data/mock/season2/season2_case04_scenes.dart';
import 'package:london_mystery/data/mock/season2/season2_case05_scenes.dart';
import 'package:london_mystery/data/mock/season2/season2_case06_scenes.dart';
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
import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';

/// Difficulty PART 7B: Paris Cases 04–06 written at Rookie, Junior and
/// Master. The words change with the level; the case — its answers, ids,
/// orders, hints' number and price, clues, evidence, rewards, its very easy
/// steps and what stays untold — never does
/// (docs/difficulty_reviews/PARIS_CASE_04_06.md).

final base = MockEpisodeRepository.bundled();
const cases = ['s2_ep04', 's2_ep05', 's2_ep06'];
const levels = Difficulty.values;
const written = [Difficulty.junior, Difficulty.master];

Episode baseCase(String id) => base.firstWhere((e) => e.id == id);
Episode caseAt(String id, Difficulty level) => DifficultyContent.episodeAt(baseCase(id), level);
Mission at(String missionId, Difficulty level) =>
    DifficultyContent.episodeAt(base.firstWhere((e) => e.allMissions.any((m) => m.id == missionId)), level).missionById(missionId)!;

/// Everything a case says.
String everything(Episode e) => [
      ...e.intro,
      ...e.synopsis,
      ...e.objectives,
      e.hook,
      e.caseSummary,
      for (final m in e.allMissions) missionWords(m),
    ].join('\n');

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
      m.clue?.note ?? '',
      m.evidence?.description ?? '',
      m.evidence?.inscription ?? '',
    ].join('\n');

/// What a mission's scenes say at its level (their own words).
String sceneWords(Mission m) => [
      if (SeasonCatalog.riverMarks(m) case final s?) ...[s.readTask, s.chooseTask, ...s.rightLines, s.sign, for (final k in s.marks) k.word],
      if (SeasonCatalog.keeperHut(m) case final s?) ...[s.solvedLine, s.foundLine, s.doorTask, s.ledgerTask, s.circleTask, s.findTask],
      if (SeasonCatalog.quayBoxes(m) case final s?) ...[for (final b in s.boxes) ?b.note, ...s.decoyLines, s.boxTask, s.labelTask],
      if (SeasonCatalog.clockWall(m) case final s?) ...[for (final c in s.clocks) c.backNote, s.watchTask, s.backTask, s.chooseTask],
      if (SeasonCatalog.archive(m) case final s?) ...[s.notHere, s.notLetters, s.notFit, s.sealLine, s.cabinetTask, s.drawerTask, s.layTask],
      if (SeasonCatalog.easySteps(m) case final s?) easyWords(s),
    ].join('\n');

/// The words of a mission before its answer is known.
String beforeAnswer(Mission m) => [m.letter, m.letterIntro, m.question, ...m.story, ...m.hints, for (final o in m.options) o.feedback ?? ''].join('\n');

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
        '${m.id}.clue.note': m.clue?.note,
        '${m.id}.evidence.description': m.evidence?.description,
      },
    };

/// The lines kept word for word at every level, on purpose: the papers the
/// puzzles are read from (quoted again after them), the lines the story
/// bible gives, and the questions that end Cases 05 and 06. Anything else
/// the same as another level's is a line left unwritten.
const keptAtEveryLevel = {
  // The plaque's back, and the label read back once whole.
  's2_ep04_m1.letter',
  's2_ep04_m3.transition[0]',
  's2_ep04_m3.transition[1]',
  's2_ep04_m3.transition[2]',
  // The address, and the label's back (Case 05 opens with it).
  's2_ep04_final.transition[0]',
  's2_ep04_final.transition[2]',
  's2_ep04_final.transition[3]',
  // The note on the workbench and the repair card, quoted.
  's2_ep05_m1.letter',
  's2_ep05_m1.transition[2]',
  's2_ep05_m1.transition[3]',
  's2_ep05_m2.letter',
  // The receipt.
  's2_ep05_m3.transition[2]',
  's2_ep05.hook',
  // The Letter's Trail, the porter's note, the letter; the story bible's
  // lines (v1.4) and Case 06's end question.
  's2_ep06_m1.letter',
  's2_ep06_m1.successMessage',
  's2_ep06_m1.transition[1]',
  's2_ep06_m2.letter',
  's2_ep06_final.letter',
  's2_ep06_final.successMessage',
  's2_ep06_final.transition[1]',
  's2_ep06_final.transition[2]',
  's2_ep06.hook',
};

/// Lines no level can show since these puzzles are played very easy
/// (2026-10-27): the steps never send a wrong answer, so the wrong-answer
/// lines of the old pages are never said (each step has its own, written
/// per level). Kept as the base's; reported, not written.
bool unreachable(String key) =>
    key.startsWith('s2_ep04_final.feedback[') || key.startsWith('s2_ep05_final.feedback[') || key.startsWith('s2_ep05_m3.options[');

/// Rookie's own lines (the rest of Rookie is the game's own words).
const rookieLines = {'s2_ep05_m1.story', 's2_ep05_m3.evidence.description'};

const pid = 'abcdef0123456789abcdef0123456789';
String pk(String key) => AppConstants.profileKey(pid, key);

/// A player whose London is solved and whose Paris is at [level] (the
/// profile at [profile], or the same), playing [active], Cases 01 to the one
/// before it solved; [progress]: the saves of the cases named.
Map<String, Object> parisAt(Difficulty level, {required String active, Difficulty? profile, Map<String, GameProgress> progress = const {}}) {
  String done(Episode e) => jsonEncode(GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: [for (final m in e.allMissions) m.id]).toJson());
  final london = [for (final e in base) if (e.seasonId == SeasonIds.london) e];
  final before = [for (final e in base) if (e.seasonId == SeasonIds.paris && e.number < baseCase(active).number) e];
  return {
    AppConstants.detectiveStorageKey: jsonEncode({
      'schema': 1,
      'profile': {'id': pid, 'origin': 'fresh', 'walletBackfill': 'never', 'detectiveName': 'KIM', 'avatar': 'girl', 'difficulty': (profile ?? level).storageId},
    }),
    for (final e in [...london, ...before]) pk(AppConstants.progressKeyFor(e.id)): done(e),
    for (final MapEntry(:key, :value) in progress.entries) pk(AppConstants.progressKeyFor(key)): jsonEncode(value.toJson()),
    pk(AppConstants.seasonKeyFor(SeasonIds.london)): jsonEncode(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: [for (final e in london) e.id]).toJson()),
    pk(AppConstants.seasonKeyFor(SeasonIds.paris)): jsonEncode(SeasonProgress(
      activeEpisodeId: active,
      solvedEpisodeIds: [for (final e in before) e.id],
      prologueSeen: true,
      difficulty: level,
    ).toJson()),
    pk(AppConstants.selectedSeasonKey): jsonEncode({'seasonId': SeasonIds.paris}),
  };
}

void main() {
  group('Written: nothing falls back unseen', () {
    test('Cases 01–06 are marked written at every level, and nothing of theirs falls back', () {
      expect(DifficultyContent.problems(), isEmpty);
      for (final id in cases) {
        expect(season2Content.writtenLevels[id], {...levels}, reason: id);
        for (final level in levels) {
          expect(DifficultyContent.missingAt(id, level), isEmpty, reason: '$id at ${level.name}');
        }
      }
      // Case 07 on is PART 7C's.
      expect(season2Content.writtenLevels.keys.toSet(), {'s2_ep01', 's2_ep02', 's2_ep03', ...cases});
      expect(DifficultyContent.missingAt('s2_ep07', Difficulty.junior), isNotEmpty);
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

    test('Rookie plays the game\'s own words but two plainer lines; its glossary grows', () {
      for (final id in cases) {
        final b = baseCase(id);
        final r = caseAt(id, Difficulty.rookie);
        final (fb, fr) = (fields(b), fields(r));
        for (final key in fb.keys) {
          expect(fr[key] == fb[key], !rookieLines.contains(key), reason: 'Rookie $key: ${fr[key]}');
        }
        expect(r.glossary.keys, containsAll(b.glossary.keys));
        expect(r.glossary.length, greaterThan(b.glossary.length), reason: '$id: words a child may not know, explained');
        for (final m in r.allMissions) {
          expect(SeasonCatalog.learning(m)!.expressions, season2Learning[m.id]!.expressions, reason: m.id);
          // The scenes at Rookie: the base's own.
          season2Content.missionTables.forEach((table, entries) {
            if (entries[m.id] != null) expect(season2Variants[Difficulty.rookie]?.missionTables[table]?[m.id], isNull, reason: '$table/${m.id}');
          });
        }
      }
      final m1 = at('s2_ep05_m1', Difficulty.rookie);
      expect(m1.story.first, 'Behind the workbench is an empty crate. It looks like the crate from Box 23.');
      expect(m1.story.skip(1), baseCase('s2_ep05').missions.first.story.skip(1));
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
          for (final (i, m) in e.allMissions.indexed) {
            final o = b.allMissions[i];
            expect((m.id, m.title, m.location, m.type, m.answer, m.hints.length, m.nextMissionId), (o.id, o.title, o.location, o.type, o.answer, o.hints.length, o.nextMissionId));
            expect([for (final x in m.options) '${x.id}:${x.label}'], [for (final x in o.options) '${x.id}:${x.label}'], reason: '${m.id}: options, in order');
            expect(m.feedback.keys, o.feedback.keys);
            expect((m.clue?.id, m.clue?.title, m.clue?.value), (o.clue?.id, o.clue?.title, o.clue?.value));
            expect((m.evidence?.id, m.evidence?.name, m.evidence?.inscription), (o.evidence?.id, o.evidence?.name, o.evidence?.inscription));
            expect(m.story.length, o.story.length, reason: '${m.id} story lines');
            expect(m.transition.length, o.transition.length, reason: '${m.id} transition lines');
            expect(WalletController.coinsFor(m), WalletController.coinsFor(o));
            expect(m.difficulty, level);
          }
          expect(e.intro.length, b.intro.length, reason: '$id: the plaque comes after the same line');
        }
      }
      expect(caseAt('s2_ep04', Difficulty.master).intro[2], contains('back'), reason: 'the plaque is turned over after this line');
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
          }
        }
      }
    });

    test('each scene: its level\'s words on the base\'s structure; papers and ways to play the same at every level', () {
      final tables0406 = <String>{};
      for (final level in written) {
        final v = season2Variants[level]!;
        for (final MapEntry(key: table, value: entries) in v.missionTables.entries) {
          for (final MapEntry(key: id, value: entry) in entries.entries) {
            if (table == 'learning' || !cases.any(id.startsWith)) continue;
            tables0406.add('$table/$id');
            final b = season2Content.missionTables[table]![id];
            expect(DifficultyContent.structureOf(entry), isNotNull, reason: '$table/$id');
            expect(DifficultyContent.structureOf(entry), DifficultyContent.structureOf(b), reason: '$table/$id at ${level.name}');
            final kept = season2SameAtEveryLevel.contains('$table/$id');
            expect(identical(entry, b), kept, reason: '$table/$id: ${kept ? 'kept' : 'its own words'}');
          }
        }
        // Each kind's structure is told apart: a moved answer is caught.
        final hut = SeasonCatalog.keeperHut(at('s2_ep04_m2', level))!, baseHut = season2KeeperHuts['s2_ep04_m2']!;
        expect([hut.doorTask, hut.ledgerTask, hut.circleTask, hut.checkLabel, hut.turnLabel, hut.findTask],
            [baseHut.doorTask, baseHut.ledgerTask, baseHut.circleTask, baseHut.checkLabel, baseHut.turnLabel, baseHut.findTask]);
        expect(identical(hut.pages, baseHut.pages), isTrue, reason: 'the ledger, as written');
        expect((hut.solvedLine, hut.foundLine), isNot((baseHut.solvedLine, baseHut.foundLine)));
        final wall = SeasonCatalog.riverMarks(at('s2_ep04_m1', level))!, baseWall = season2RiverMarks['s2_ep04_m1']!;
        expect([wall.readTask, wall.chooseTask, wall.chooseLabel], [baseWall.readTask, baseWall.chooseTask, baseWall.chooseLabel]);
        expect(wall.rightLines, hasLength(3));
        expect(wall.rightLines, isNot(baseWall.rightLines));
        final boxes = SeasonCatalog.quayBoxes(at('s2_ep04_m3', level))!, baseBoxes = season2QuayBoxes['s2_ep04_m3']!;
        expect([boxes.boxTask, boxes.labelTask, boxes.checkLabel], [baseBoxes.boxTask, baseBoxes.labelTask, baseBoxes.checkLabel]);
        expect(boxes.boxes.firstWhere((b) => b.id == 'box23').note, isNull, reason: 'the box that opens says nothing');
        final clocks = SeasonCatalog.clockWall(at('s2_ep05_m2', level))!, baseClocks = season2ClockWalls['s2_ep05_m2']!;
        expect([clocks.watchTask, clocks.backTask, clocks.chooseTask, clocks.later], [baseClocks.watchTask, baseClocks.backTask, baseClocks.chooseTask, baseClocks.later]);
        expect([for (final c in clocks.clocks) '${c.shows}${c.change}'], [for (final c in baseClocks.clocks) '${c.shows}${c.change}']);
        final archive = SeasonCatalog.archive(at('s2_ep06_m3', level))!, baseArchive = season2ArchiveScenes['s2_ep06_m3']!;
        expect([archive.cabinetTask, archive.drawerTask, archive.layTask, archive.layLabel],
            [baseArchive.cabinetTask, baseArchive.drawerTask, baseArchive.layTask, baseArchive.layLabel]);
        for (final d in ['l4000', 'l4200', 'p4400']) {
          expect(archive.refusalOf(d), startsWith(baseArchive.drawers.drawer(d).label), reason: 'the drawer\'s own label, said');
          expect(archive.refusalOf(d), isNot(baseArchive.refusalOf(d)));
        }
        // The wrong envelope's line is the mission's own at its level.
        expect(archive.notFit, at('s2_ep06_m3', level).options.firstWhere((o) => o.id == 'x').feedback);
      }
      expect(tables0406, {
        'riverMarks/s2_ep04_m1', 'keeperHuts/s2_ep04_m2', 'quayBoxes/s2_ep04_m3', 'streetBooks/s2_ep04_final', 'easySteps/s2_ep04_final',
        'markCompares/s2_ep05_m1', 'clockWalls/s2_ep05_m2', 'easySteps/s2_ep05_m3', 'postTrails/s2_ep05_final', 'easySteps/s2_ep05_final',
        'holdRacks/s2_ep06_m1', 'planRoutes/s2_ep06_m2', 'archives/s2_ep06_m3', 'letterMaps/s2_ep06_final',
      }, reason: 'every scene of Cases 04–06, at both levels');
      // The structures differ where the puzzles differ (the check reads
      // what matters).
      expect(DifficultyContent.structureOf(season2Case05Steps['s2_ep05_m3']), isNot(DifficultyContent.structureOf(season2Case05Steps['s2_ep05_final'])));
      expect(DifficultyContent.structureOf(season2Case04Steps['s2_ep04_final']), contains('horlogers'));
    });

    test('the very easy steps: the same steps, choices, answers and free hints; each level\'s words', () {
      for (final id in ['s2_ep04_final', 's2_ep05_m3', 's2_ep05_final']) {
        final b = season2Content.easySteps[id]!;
        final says = <String>{};
        for (final level in levels) {
          final m = at(id, level);
          final s = SeasonCatalog.easySteps(m)!;
          expect((s.title, s.answer, s.finishLabel, s.seen), (b.title, b.answer, b.finishLabel, b.seen));
          expect(s.answer, m.answer, reason: 'the steps answer the mission');
          for (final (i, step) in s.steps.indexed) {
            final o = b.steps[i];
            expect((step.id, step.does, step.answer, step.hints.length, step.button, step.doneButton), (o.id, o.does, o.answer, o.hints.length, o.button, o.doneButton));
            expect([for (final x in step.options) '${x.id}:${x.label}'], [for (final x in o.options) '${x.id}:${x.label}']);
            expect(identical(step.panels, o.panels), isTrue, reason: '$id ${step.id}: what it shows');
            expect(identical(step.after, o.after), isTrue);
            expect(step.lookHere.map((x) => x.panel), o.lookHere.map((x) => x.panel));
            // A choice's hints never say its answer; its wrong lines neither.
            if (step.does == EasyDo.choose) {
              final right = step.options.firstWhere((x) => x.id == step.answer).label!.split('\n').first;
              for (final h in step.hints.take(step.hints.length - 1)) {
                expect(h, isNot(contains(right)), reason: '$id ${level.name}: "$h"');
              }
              for (final x in step.options.where((x) => x.feedback != null)) {
                expect(x.feedback, isNot(contains(right)), reason: '$id ${level.name}');
              }
            }
          }
          // The mission's hints are the steps' first ones.
          expect(m.hints, [for (final step in s.steps) ...step.hints.take(s.steps.length == 1 ? step.hints.length : 1)], reason: '$id at ${level.name}');
          says.add(easyWords(s));
        }
        expect(says, hasLength(3), reason: '$id: each level its own words');
      }
      // Only the ways to play and the papers' words are kept.
      for (final level in written) {
        final mirror = SeasonCatalog.easySteps(at('s2_ep05_m3', level))!.steps.first;
        expect((mirror.say, mirror.done, mirror.hints.last), ('Tap the mirror.', 'THE CLOCK THAT TURNS BACK.', 'Tap the hand mirror.'));
      }
    });
  });

  group('What each case keeps untold, at every level', () {
    for (final level in levels) {
      test('Case 04 at ${level.name}', () {
        final e = caseAt('s2_ep04', level);
        final [m1, m2, m3, fin] = e.allMissions;
        final all = '${everything(e)}\n${[for (final m in e.allMissions) sceneWords(m)].join('\n')}';
        // The plaque, as scratched; the hints never name the mark.
        expect(m1.letter, 'Three waves mark the place.\nFollow the arrow towards the river.\nFind the one who watches the water.');
        for (final h in m1.hints) {
          expect(h, isNot(contains('Mark D')), reason: h);
        }
        for (final h in m2.hints) {
          expect(h, isNot(contains('Box 23')), reason: h);
        }
        // The label's last piece, and the address, only once the final is
        // answered.
        for (final m in [m1, m2, m3]) {
          expect('${missionWords(m)}\n${sceneWords(m)}'.toUpperCase(), isNot(contains('HORLOGERS')), reason: m.id);
        }
        expect(beforeAnswer(fin).toUpperCase(), isNot(contains('HORLOGERS')));
        expect(m3.transition.take(3), ['FROM: EIFFEL TOWER — SERVICE LEVEL.', 'CONTENTS: CLOCK PARTS.', 'TO: THE WATCHMAKERS. PASSAGE D…']);
        expect(m2.transition.join(' '), allOf(contains('Box 23'), contains('No. 7'), contains('two clock hands')));
        expect(fin.letter, startsWith('CLUE 1: PASSAGE\nCLUE 2: No. 7\n\n'));
        expect(fin.transition, containsAllInOrder(['PASSAGE DES HORLOGERS.', 'Do not trust the clocks.', 'Follow the hands that made them.']));
        expect(fin.transition.last, endsWith('?'), reason: 'whose hands: a question');
        // Who made the mark, and what the parts were for: untold.
        for (final absent in ['CLOCKMAKER', 'STOLE', 'STOLEN', 'VANISHED', 'REPAIR', 'EMILE', 'ÉMILE', 'VICTOR']) {
          expect(all.toUpperCase(), isNot(contains(absent)), reason: absent);
        }
        expect(RegExp(r'\bmaker\b', caseSensitive: false).hasMatch(all), isFalse, reason: 'the maker is Case 05\'s');
      });

      test('Case 05 at ${level.name}', () {
        final e = caseAt('s2_ep05', level);
        final [m1, m2, m3, fin] = e.allMissions;
        final all = '${everything(e)}\n${[for (final m in e.allMissions) sceneWords(m)].join('\n')}';
        expect(e.intro.first, 'Do not trust the clocks. Follow the hands that made them.', reason: 'Case 04\'s last words');
        expect(m1.letter, 'My mark is on everything I make.\nA copy is never the same.');
        expect(m2.letter, 'I changed one clock.\nI added one small wheel.\nNow its hands turn the wrong way.');
        expect(m1.transition, containsAllInOrder(['I changed one clock. I added one small wheel.', 'Now its hands turn the wrong way.']));
        for (final m in [m2, m3]) {
          for (final h in m.hints) {
            expect(h, isNot(contains('III')), reason: '${m.id}: $h');
          }
        }
        // The note says it was hidden there; who took it out is a question.
        expect(m3.transition.where((l) => l.contains("maker's note")), hasLength(1));
        expect(m3.transition.where((l) => l.contains('take it out?')), hasLength(1));
        expect(m3.transition, contains('16 MAY — ONE LETTER COLLECTED FROM No. 7.'));
        expect(fin.letter, startsWith('16 MAY — ONE LETTER COLLECTED FROM No. 7.\nLETTER No. 4417.\n\n'));
        expect(fin.transition.join(' '), allOf(contains('HELD at the Louvre post room'), contains('16 May')));
        expect(fin.transition.last, endsWith('?'));
        expect(e.hook, 'Who held the letter at the Louvre post room?');
        // What the letter says, who held it, why: Case 06's and later.
        for (final absent in ['CLOCKMAKER', 'STOLE', 'TOOK IT', 'TAKEN OUT', 'PRESERVATION', 'KEEP IT SAFE', 'OPERA', 'GARNIER', 'ARCHIVE', 'SHOW REMEMBERS', 'CLOCKS MAY LIE', 'EMILE', 'ÉMILE', 'VICTOR']) {
          expect(all.toUpperCase(), isNot(contains(absent)), reason: absent);
        }
      });

      test('Case 06 at ${level.name}', () {
        final e = caseAt('s2_ep06', level);
        final [m1, m2, m3, fin] = e.allMissions;
        final all = '${everything(e)}\n${[for (final m in e.allMissions) sceneWords(m)].join('\n')}';
        expect(m1.letter, 'LETTER No. 4417\n16 MAY · 4:00 PM\nHELD · LOUVRE POST ROOM');
        expect(m1.successMessage, "Wait! It wasn't stolen.", reason: 'the story bible, v1.4');
        expect(m1.transition[1], 'Someone kept it safe.');
        expect(m2.story, containsAllInOrder(['16 MAY · 4:00 PM · HELD.', '17 MAY · MORNING · MOVED.']));
        expect(m2.letter, 'Letters to keep safe go downstairs.\nGo down the stairs.\nWalk past the statue.\nTake the second door on the left.');
        expect(fin.letter, 'The clocks may lie.\nBut the show remembers.');
        expect(fin.successMessage, 'We found our next clue!');
        expect(fin.transition.sublist(1), ['On the back: OPERA ARCHIVE · FILE 3–4.', 'The mystery continues at the opera house!']);
        expect(e.hook, 'What is in File 3–4 of the opera archive?');
        expect(e.caseSummary, contains('kept safe'));
        for (final (m, answer) in [(m1, 'Tag D'), (m2, 'Door E'), (m3, 'Envelope 2')]) {
          for (final h in m.hints) {
            expect(h, isNot(contains(answer)), reason: '${m.id}: $h');
          }
        }
        // Where the letter leads: only once the drawing is placed.
        for (final m in [m1, m2, m3]) {
          for (final absent in ['OPERA', 'GARNIER']) {
            expect('${missionWords(m)}\n${sceneWords(m)}'.toUpperCase(), isNot(contains(absent)), reason: '${m.id}: $absent');
          }
        }
        expect(beforeAnswer(fin).toUpperCase(), allOf(isNot(contains('OPERA')), isNot(contains('GARNIER'))));
        // Who wrote it, who held it and why, and the later twist: untold.
        for (final absent in ['CLOCKMAKER', 'RECORD WAS REMOVED', 'REMOVED', 'EMILE', 'ÉMILE', 'VICTOR', 'THIEF']) {
          expect(all.toUpperCase(), isNot(contains(absent)), reason: absent);
        }
        expect(RegExp(r'\bmaker\b', caseSensitive: false).hasMatch(all), isFalse, reason: 'who wrote it stays untold');
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
                expect(AnswerChecker.normalize(h).contains(AnswerChecker.normalize(answer)), isFalse, reason: '${m.id} ${level.name}: "$h" gives away "$answer"');
              }
              expect(h, isNot(contains('{detectiveName}')));
            }
          }
        }
      }
    });

    test('hints opened are kept whatever the level: counted by mission, priced the same', () async {
      for (final level in levels) {
        final c = ProviderContainer(overrides: await testOverrides(prefs: parisAt(level, active: 's2_ep04', progress: {
          's2_ep04': const GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: ['s2_ep04_m1'], hintsUsed: {'s2_ep04_m2': 1}),
        })));
        addTearDown(c.dispose);
        final played = c.read(currentEpisodeProvider);
        expect(played.id, 's2_ep04');
        expect(played.allMissions.first.difficulty, level);
        expect(c.read(gameControllerProvider).hintsFor('s2_ep04_m2'), 1, reason: level.name);
        expect(c.read(gameControllerProvider).isCompleted('s2_ep04_m1'), isTrue);
        expect(played.missionById('s2_ep04_m2')!.hints.first, at('s2_ep04_m2', level).hints.first);
      }
    });
  });

  group('Discovery Moments', () {
    test('each title is the success line of the level played, never another level\'s', () {
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
          // The story bible's own line (v1.4) is every level's.
          expect(titles, hasLength(m.id == 's2_ep06_m1' ? 1 : 3), reason: m.id);
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
            expect((l.dependency, l.level, l.skill, l.recallFrom, l.objective), (b.dependency, b.level, b.skill, b.recallFrom, b.objective));
            named.add(l.expressions.join('|'));
          }
          expect(named, hasLength(3), reason: '${m.id}: the levels name different English');
        }
      }
    });

    for (final level in levels) {
      test('Paris played at ${level.name}: the report of Case 05 names ${level.name}\'s English, whatever the profile says later', () async {
        // The profile now says another level: the season keeps its own.
        final other = levels[(level.index + 1) % levels.length];
        final c = ProviderContainer(overrides: await testOverrides(prefs: parisAt(level, active: 's2_ep05', profile: other, progress: {
          's2_ep05': GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: [for (final m in baseCase('s2_ep05').allMissions) m.id]),
        })));
        addTearDown(c.dispose);
        expect(c.read(currentEpisodeProvider).id, 's2_ep05');
        final report = DetectiveReport.from(c.read(currentEpisodeProvider), c.read(gameControllerProvider));
        for (final m in baseCase('s2_ep05').allMissions) {
          final p = report.performances.firstWhere((p) => p.mission.id == m.id);
          expect(p.learning!.expressions, SeasonCatalog.learning(at(m.id, level))!.expressions, reason: '${m.id} at ${level.name}');
        }
        expect(c.read(currentEpisodeProvider).allMissions.first.story, at('s2_ep05_m1', level).story);
      });
    }

    test('an old save (no level anywhere) plays Rookie\'s words', () async {
      final c = ProviderContainer(overrides: await testOverrides(prefs: {
        AppConstants.progressKeyFor('s2_ep05'):
            jsonEncode(const GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: ['s2_ep05_m1']).toJson()),
      }));
      addTearDown(c.dispose);
      final played = c.read(playedEpisodesProvider).firstWhere((e) => e.id == 's2_ep05');
      expect(played.allMissions.first.difficulty, Difficulty.rookie);
      expect(fields(played), fields(caseAt('s2_ep05', Difficulty.rookie)));
      expect(played.glossary['workshop'], isNotNull, reason: 'Rookie\'s glossary, grown');
    });
  });

  group('On screen', () {
    /// Paris opened at [level] (London solved), Case 04's three missions
    /// answered, and its final opened.
    Future<WidgetRef> openCase04Final(WidgetTester t, Difficulty level, Size size, {double textScale = 1}) async {
      await loadGameFonts();
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      t.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      GameProgress solved(Episode e) => GameProgress(
            detectiveName: 'KIM',
            introSeen: true,
            completedMissionIds: [for (final m in e.allMissions) m.id],
            startedAt: DateTime(2026, 10, 20, 10),
            completedAt: DateTime(2026, 10, 20, 10, 30),
          );
      final london = [for (final e in base) if (e.seasonId == SeasonIds.london) e];
      final paris = [for (final id in ['s2_ep01', 's2_ep02', 's2_ep03']) baseCase(id)];
      late WidgetRef ref;
      await t.pumpWidget(ProviderScope(
        overrides: [
          ...await testOverrides(prefs: {
            AppConstants.detectiveStorageKey: jsonEncode({
              'schema': 1,
              'profile': {'id': pid, 'origin': 'fresh', 'walletBackfill': 'never', 'detectiveName': 'KIM', 'avatar': 'girl', 'difficulty': level.storageId},
            }),
            for (final e in [...london, ...paris]) pk(AppConstants.progressKeyFor(e.id)): jsonEncode(solved(e).toJson()),
            pk(AppConstants.seasonKeyFor(SeasonIds.london)):
                jsonEncode(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: [for (final e in london) e.id]).toJson()),
            pk(AppConstants.seasonKeyFor(SeasonIds.paris)): jsonEncode(SeasonProgress(
              activeEpisodeId: 's2_ep04',
              solvedEpisodeIds: [for (final e in paris) e.id],
              prologueSeen: true,
              difficulty: level,
            ).toJson()),
          }),
          seasonPreviewProvider.overrideWithValue(true),
        ],
        child: Consumer(builder: (context, r, _) {
          ref = r;
          return RepaintBoundary(key: const ValueKey('shot'), child: const LondonMysteryApp());
        }),
      ));
      await wait(t, const Duration(milliseconds: 300));
      final game = ref.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      expect(game.openEpisode('s2_ep04'), isTrue);
      game.startInvestigation();
      final played = ref.read(currentEpisodeProvider);
      expect(played.allMissions.first.difficulty, level, reason: 'Paris fixed at its level');
      for (final m in played.missions) {
        game.submitAnswer(m, m.answer);
      }
      ref.read(routerProvider).go(Routes.finalMission);
      await wait(t, const Duration(milliseconds: 1600));
      return ref;
    }

    /// The final's step in [level]'s words: its line, a free hint, a wrong
    /// answer, the right one.
    Future<void> playFinal(WidgetTester t, WidgetRef ref, Difficulty level, String tag) async {
      final play = EasyPlay(t, tag);
      final step = SeasonCatalog.easySteps(at('s2_ep04_final', level))!.steps.single;
      play.expectSay(step.say);
      for (final other in levels.where((l) => l != level)) {
        final say = SeasonCatalog.easySteps(at('s2_ep04_final', other))!.steps.single.say;
        if (say != step.say) expect(findReadable(say), findsNothing, reason: '$tag: not ${other.name}\'s');
      }
      expect(findReadable('CLUE 1: PASSAGE'), findsOneWidget);
      expect(findReadable('CLUE 2: No. 7'), findsOneWidget);
      for (final k in ['easy-option-pont', 'easy-option-horlogers']) {
        final r = t.getRect(find.byKey(ValueKey(k)));
        expect(r.width >= 44 && r.height >= 44, isTrue, reason: '$tag $k: finger-sized');
      }
      await play.shot('step');
      await play.tapKey('easy-hint');
      expect(findReadable(step.hints.first), findsOneWidget, reason: '$tag: the hint in its level\'s words');
      await play.shot('hint');
      await play.tapKey('easy-option-pont');
      expect(findReadable(step.option('pont')!.feedback!), findsOneWidget);
      expect(ref.read(gameControllerProvider).wrongCount('s2_ep04_final'), 0, reason: 'a wrong answer costs nothing');
      await play.shot('wrong');
      await play.tapKey('easy-option-horlogers');
      expect(findReadable(step.done!), findsOneWidget);
      await play.shot('done');
    }

    for (final level in levels) {
      testWidgets('Case 04 final at ${level.name} (390 × 844): the step in ${level.name}\'s words', (t) async {
        final ref = await openCase04Final(t, level, const Size(390, 844));
        await playFinal(t, ref, level, '7b_${level.name}');
        expect(t.takeException(), isNull);
        await wait(t, const Duration(seconds: 2));
      });
    }

    testWidgets('Case 04 final at Master on a small phone, its words 1.3 times larger: nothing cut off', (t) async {
      final ref = await openCase04Final(t, Difficulty.master, const Size(360, 640), textScale: 1.3);
      await playFinal(t, ref, Difficulty.master, '7b_master_small');
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 2));
    });

    testWidgets('Case 04 final at Master on a tablet', (t) async {
      final ref = await openCase04Final(t, Difficulty.master, const Size(834, 1194));
      await playFinal(t, ref, Difficulty.master, '7b_master_tablet');
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 2));
    });
  });
}
