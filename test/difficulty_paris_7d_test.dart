import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/content/learning_check.dart';
import 'package:world_mystery/data/mock/season2/season2_case12_scenes.dart';
import 'package:world_mystery/data/mock/season2/season2_difficulty.dart';
import 'package:world_mystery/data/mock/season2/season2_discoveries.dart';
import 'package:world_mystery/data/mock/season2/season2_learning.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/case_talk.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/easy_steps.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/game/wallet_controller.dart';
import 'package:world_mystery/features/result/detective_report.dart';

import 'easy_play.dart';
import 'full_playthrough_test.dart' show tapText, wait;
import 'helpers.dart';

/// Difficulty PART 7D: Paris Cases 10–12 written at Rookie, Junior and
/// Master, and the whole season checked at every level. The words change
/// with the level; the case — its answers, ids, orders, hints, the talks'
/// steps and lines, the ending, and when each truth is told — never does
/// (docs/difficulty_reviews/PARIS_CASE_10_12.md).

final base = MockEpisodeRepository.bundled();
const cases = ['s2_ep10', 's2_ep11', 's2_ep12'];
final season = [for (var n = 1; n <= 12; n++) 's2_ep${n.toString().padLeft(2, '0')}'];
const levels = Difficulty.values;
const written = [Difficulty.junior, Difficulty.master];

Episode baseCase(String id) => base.firstWhere((e) => e.id == id);
Episode caseAt(String id, Difficulty level) => DifficultyContent.episodeAt(baseCase(id), level);
Mission at(String missionId, Difficulty level) =>
    DifficultyContent.episodeAt(base.firstWhere((e) => e.allMissions.any((m) => m.id == missionId)), level).missionById(missionId)!;

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

String everything(Episode e) => [...e.intro, ...e.synopsis, ...e.objectives, e.hook, e.caseSummary, for (final m in e.allMissions) missionWords(m)].join('\n');

/// Every word a talk says.
String talkWords(TalkScene t) => [
  t.goal,
  for (final l in t.opening) l.text,
  for (final q in t.questions) ...[q.text, for (final l in q.beat) l.text],
  for (final p in t.presents) ...[p.prompt, ?p.tell, for (final l in p.beat) l.text, p.miss.text, for (final l in p.misses.values) l.text],
].join('\n');

/// What a mission's scenes, talks and ending say at its level.
String sceneWords(Mission m) => [
  if (SeasonCatalog.drumTape(m) case final s?) ...[s.startLine, s.oneMore, s.found, s.task, s.header],
  if (SeasonCatalog.cityClocks(m) case final s?) ...[
    for (final c in s.photo.clocks) c.wrongLine,
    s.moreLine,
    s.foundLine,
    ...s.sortedLines,
    s.task,
    s.sortTask,
  ],
  if (SeasonCatalog.shadowCheck(m) case final s?) ...[s.longer, s.shorter, s.matchLine, s.task, s.dragLine, s.plateWords],
  if (SeasonCatalog.hourRecord(m) case final s?) ...[
    s.firstTwoThirty,
    s.notTwoThirty,
    ...s.foundLines,
    s.pageTask,
    s.pageInBook,
    s.pageFoundLine,
    ...s.afterLines,
    s.lead.question,
    s.lead.otherLine,
    ...s.lead.doneLines,
    for (final l in s.lead.lines) l.text,
    s.tapeTask,
  ],
  if (SeasonCatalog.talkMission(m) case final t?) ...[if (t.before case final b?) talkWords(b), if (t.after case final a?) talkWords(a)],
  if (SeasonCatalog.caseTalk(m) case final t?) talkWords(t),
  if (SeasonCatalog.caseEnding(m) case final e?) ...[for (final l in e) l.text],
  if (SeasonCatalog.easySteps(m) case final s?) easyWords(s),
].join('\n');

String beforeAnswer(Mission m) => [
  m.letter,
  m.letterIntro,
  m.question,
  ...m.story,
  ...m.hints,
  for (final o in m.options) o.feedback ?? '',
  if (SeasonCatalog.talkMission(m)?.before case final b?) talkWords(b),
  if (SeasonCatalog.easySteps(m) case final s?)
    for (final st in s.steps) ...[st.say, ?st.question, ...st.hints, for (final o in st.options) ?o.feedback],
].join('\n');

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

/// The lines kept word for word at every level, on purpose: the papers
/// the puzzles are read from, the questions the case board and earlier
/// cases ask, the lines earlier cases are quoted by, and the season's last
/// words.
const keptAtEveryLevel = {
  // T1's tape, the photo's back, the sundial, the photos; "The Clockmaker
  // steals an hour.", "The clocks may lie.", the Eiffel Tower's plaque; the
  // question Case 09 ends on; the way to play the sundial.
  's2_ep10_m1.letter',
  's2_ep10_m1.transition[2]',
  's2_ep10_m2.letter',
  's2_ep10_m3.letter',
  's2_ep10_m3.question',
  's2_ep10_m3.transition[3]',
  's2_ep10_final.letter',
  's2_ep10_final.question',
  's2_ep10_final.transition[2]',
  // The rubbing, page 3's two voices, Victor's paper, the clue names.
  's2_ep11_m1.letter',
  's2_ep11_m1.transition[2]',
  's2_ep11_m1.transition[3]',
  's2_ep11_m2.letter',
  's2_ep11_final.letter',
  // The name tag, PARIS, the machine's card, the case board.
  's2_ep12_m1.letter',
  's2_ep12_m1.transition[0]',
  's2_ep12_m2.letter',
  's2_ep12_m3.letter',
  's2_ep12_m3.hints[1]',
  's2_ep12_final.letter',
  's2_ep12_final.question',
  's2_ep12_final.transition[0]',
  's2_ep12.hook',
};

const pid = 'abcdef0123456789abcdef0123456789';
String pk(String key) => AppConstants.profileKey(pid, key);

Map<String, Object> parisAt(
  Difficulty level, {
  required String active,
  Difficulty? profile,
  Map<String, GameProgress> progress = const {},
  bool selected = true,
}) {
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
    if (selected) pk(AppConstants.selectedSeasonKey): jsonEncode({'seasonId': SeasonIds.paris}),
  };
}

final _clockmakerNamed = RegExp(r"(Émile|He|he) (is|was) the Clockmaker|Clockmaker is Émile|one and the same|I am the Clockmaker");

void main() {
  group('Written: the whole season, nothing falls back unseen', () {
    test('Cases 01–12 are marked written at every level, and nothing of theirs falls back', () {
      expect(DifficultyContent.problems(), isEmpty);
      expect(season2Content.writtenLevels.keys.toSet(), {...season}, reason: 'the whole season');
      for (final id in season) {
        expect(season2Content.writtenLevels[id], {...levels}, reason: id);
        for (final level in levels) {
          expect(DifficultyContent.missingAt(id, level), isEmpty, reason: '$id at ${level.name}');
        }
      }
    });

    test('Junior and Master each have their own line everywhere but the lines kept on purpose', () {
      for (final id in cases) {
        final b = fields(baseCase(id));
        final j = fields(caseAt(id, Difficulty.junior));
        final m = fields(caseAt(id, Difficulty.master));
        for (final key in b.keys) {
          if (b[key] == null) continue;
          final kept = keptAtEveryLevel.contains(key);
          expect(j[key] == b[key], kept, reason: 'Junior $key: ${j[key]}');
          expect(m[key] == b[key], kept, reason: 'Master $key: ${m[key]}');
          expect(m[key] == j[key], kept, reason: 'Master = Junior $key: ${m[key]}');
        }
      }
    });

    test('Rookie plays the game\'s own words; its glossary grows', () {
      for (final id in cases) {
        final b = baseCase(id);
        final r = caseAt(id, Difficulty.rookie);
        expect(fields(r), fields(b), reason: id);
        expect(r.glossary.length, greaterThan(b.glossary.length), reason: id);
        for (final m in r.allMissions) {
          expect(SeasonCatalog.learning(m)!.expressions, season2Learning[m.id]!.expressions, reason: m.id);
          expect(sceneWords(m), sceneWords(baseCase(id).missionById(m.id)!), reason: '${m.id}: its scenes, talks and ending as written');
        }
      }
    });

    test('Every glossary word of a level is on its pages; keys are lower-case single words', () {
      for (final id in cases) {
        for (final level in levels) {
          final e = caseAt(id, level);
          final text = ' ${LearningCheck.words('${everything(e)}\n${[for (final m in e.allMissions) sceneWords(m)].join('\n')}')} ';
          final own = (season2CasePatches[level]![id]!['glossary'] as Map?) ?? const {};
          expect(own, isNotEmpty, reason: '$id at ${level.name}');
          for (final k in own.keys.cast<String>()) {
            expect((k, k.contains(' ')), (k.toLowerCase(), false));
            expect(text, contains(' ${LearningCheck.words(k)} '), reason: '$id at ${level.name}: "$k"');
          }
        }
      }
    });
  });

  group('The case never changes with the level', () {
    test('ids, answers, orders, hints\' number, clues, evidence, coins: the same at every level, the whole season', () {
      for (final id in season) {
        final b = baseCase(id);
        for (final level in levels) {
          final e = caseAt(id, level);
          expect(DifficultyContent.structureOfEpisode(e), DifficultyContent.structureOfEpisode(b), reason: '$id ${level.name}');
          expect((e.title, e.place), (b.title, b.place));
          expect(e.keyWords, b.keyWords);
          expect(e.intro.length, b.intro.length, reason: '$id: its pictures come after the same lines');
          for (final (i, m) in e.allMissions.indexed) {
            final o = b.allMissions[i];
            expect((m.id, m.type, m.answer, m.hints.length, m.nextMissionId), (o.id, o.type, o.answer, o.hints.length, o.nextMissionId));
            expect([for (final x in m.options) '${x.id}:${x.label}'], [for (final x in o.options) '${x.id}:${x.label}'], reason: m.id);
            expect(
              (m.clue?.id, m.clue?.value, m.evidence?.id, m.evidence?.name, m.evidence?.inscription),
              (o.clue?.id, o.clue?.value, o.evidence?.id, o.evidence?.name, o.evidence?.inscription),
            );
            expect((m.story.length, m.transition.length), (o.story.length, o.transition.length), reason: m.id);
            expect(WalletController.coinsFor(m), WalletController.coinsFor(o));
            expect(AnswerChecker.isCorrect(m, m.answer), isTrue, reason: '${m.id} ${level.name}');
            for (final wrong in m.feedback.keys) {
              expect(AnswerChecker.feedbackFor(m, wrong), m.feedback[wrong]);
            }
          }
        }
      }
      expect([WalletController.priceOf(1), WalletController.priceOf(2)], AppConstants.tipPrices);
    });

    test('every scene of the season: its level\'s words on the base\'s structure', () {
      final tables = <String>{};
      for (final level in written) {
        final v = season2Variants[level]!;
        for (final MapEntry(key: table, value: entries) in v.missionTables.entries) {
          for (final MapEntry(key: id, value: entry) in entries.entries) {
            if (table == 'learning') continue;
            final b = season2Content.missionTables[table]![id];
            expect(DifficultyContent.structureOf(entry), isNotNull, reason: '$table/$id');
            expect(DifficultyContent.structureOf(entry), DifficultyContent.structureOf(b), reason: '$table/$id at ${level.name}');
            expect(identical(entry, b), season2SameAtEveryLevel.contains('$table/$id'), reason: '$table/$id');
            if (cases.any(id.startsWith)) tables.add('$table/$id');
          }
        }
        // Every table entry the season has (pictures aside) is given at both levels.
        season2Content.missionTables.forEach((table, entries) {
          if (DifficultyContent.pictureTables.contains(table)) return;
          for (final id in entries.keys) {
            expect(v.missionTables[table]?.containsKey(id), isTrue, reason: '$table/$id at ${level.name}');
          }
        });
      }
      expect(tables, {
        'drumTapes/s2_ep10_m1',
        'cityClocks/s2_ep10_m2',
        'shadowChecks/s2_ep10_m3',
        'hourRecords/s2_ep10_final',
        'talkMissions/s2_ep11_m1',
        'talkMissions/s2_ep11_m2',
        'talks/s2_ep11_final',
        'easySteps/s2_ep11_m1',
        'easySteps/s2_ep11_m2',
        'easySteps/s2_ep11_m3',
        'talkMissions/s2_ep12_m1',
        'talkMissions/s2_ep12_m2',
        'talkMissions/s2_ep12_m3',
        'easySteps/s2_ep12_m1',
        'easySteps/s2_ep12_m2',
        'easySteps/s2_ep12_m3',
        'easySteps/s2_ep12_final',
        'endings/s2_ep12_final',
      });
    });

    test('the talks: the same steps, needs, answers and lines (voices, moods, how many); each level\'s words', () {
      List<TalkScene> talksOf(Mission m) => [
        if (SeasonCatalog.talkMission(m) case final t?) ...[?t.before, ?t.after],
        ?SeasonCatalog.caseTalk(m),
      ];
      String shape(List<TalkLine> l) => l.map((x) => '${x.voice.name}/${x.mood}').join(';');
      for (final id in ['s2_ep11_m1', 's2_ep11_m2', 's2_ep11_final', 's2_ep12_m1', 's2_ep12_m2', 's2_ep12_m3']) {
        final b = talksOf(at(id, Difficulty.rookie));
        expect(b, isNotEmpty, reason: id);
        final words = <String>{};
        for (final level in levels) {
          final t = talksOf(at(id, level));
          expect(t, hasLength(b.length));
          for (final (i, s) in t.indexed) {
            final o = b[i];
            expect(
              (s.id, s.speaker.id, s.speaker.name, s.finishLabel, s.answer, s.place),
              (o.id, o.speaker.id, o.speaker.name, o.finishLabel, o.answer, o.place),
            );
            expect(s.finishWhen, o.finishWhen);
            expect(shape(s.opening), shape(o.opening), reason: '$id ${level.name} opening');
            expect(
              [for (final q in s.questions) '${q.id}${q.requires}${q.repeatable}${shape(q.beat)}'],
              [for (final q in o.questions) '${q.id}${q.requires}${q.repeatable}${shape(q.beat)}'],
            );
            expect(
              [for (final p in s.presents) '${p.id}${p.accepted}${p.choices}${p.requires}${shape(p.beat)}${p.miss.voice}${p.miss.mood}'],
              [for (final p in o.presents) '${p.id}${p.accepted}${p.choices}${p.requires}${shape(p.beat)}${p.miss.voice}${p.miss.mood}'],
            );
            words.add(talkWords(s));
          }
        }
        expect(words.length, 3 * b.length, reason: '$id: each level its own words');
      }
    });

    test('the very easy steps: the same steps, choices, answers and free hints; each level\'s words', () {
      for (final id in ['s2_ep11_m1', 's2_ep11_m2', 's2_ep11_m3', 's2_ep12_m1', 's2_ep12_m2', 's2_ep12_m3', 's2_ep12_final']) {
        final b = season2Content.easySteps[id]!;
        final says = <String>{};
        for (final level in levels) {
          final m = at(id, level);
          final s = SeasonCatalog.easySteps(m)!;
          expect((s.title, s.answer, s.finishLabel), (b.title, b.answer, b.finishLabel));
          expect(s.answer, m.answer);
          for (final (i, step) in s.steps.indexed) {
            final o = b.steps[i];
            expect(
              (step.id, step.does, step.answer, step.hints.length, step.button, step.doneButton, step.question),
              (o.id, o.does, o.answer, o.hints.length, o.button, o.doneButton, o.question),
            );
            expect([for (final x in step.options) '${x.id}:${x.label}'], [for (final x in o.options) '${x.id}:${x.label}']);
            expect(identical(step.panels, o.panels), isTrue);
            if (step.does == EasyDo.choose && step.options.length == 2) {
              final right = step.options.firstWhere((x) => x.id == step.answer).label!;
              if (right.length > 3) {
                expect(step.hints.first, isNot(contains(right)), reason: '$id ${level.name} ${step.id}');
              }
            }
          }
          says.add(easyWords(s));
        }
        expect(says, hasLength(3), reason: id);
      }
    });

    test('the ending: the same lines (who, where, what evidence); Victor\'s record and the case file as they are', () {
      final b = season2Case12Ending;
      final texts = <String>{};
      for (final level in levels) {
        final e = SeasonCatalog.caseEnding(at('s2_ep12_final', level))!;
        expect(
          [for (final l in e) '${l.voice}${l.name}${l.portrait}${l.background}${l.evidenceId}'],
          [for (final l in b) '${l.voice}${l.name}${l.portrait}${l.background}${l.evidenceId}'],
        );
        expect(e[1].text, 'Yes. I hid the page.', reason: "Victor's record");
        expect(
          [for (final l in e.sublist(5, 8)) l.text],
          ['The clocks were wrong.', 'Victor hid the truth.', 'Émile left the clues.'],
          reason: 'the case file',
        );
        expect(e[9].text, contains('glass case'));
        expect(e.last.text.toLowerCase(), contains('hide it again'));
        texts.add(e.map((l) => l.text).join('|'));
      }
      expect(texts, hasLength(3));
    });
  });

  group('What each case keeps untold, and when the truth is told, at every level', () {
    for (final level in levels) {
      test('Case 10 at ${level.name}', () {
        final e = caseAt('s2_ep10', level);
        final [m1, m2, m3, fin] = e.allMissions;
        final all = '${everything(e)}\n${[for (final m in e.allMissions) sceneWords(m)].join('\n')}';
        for (final absent in ['VICTOR', 'ÉMILE', 'EMILE', 'MOREAU', 'E.M.', 'V.D.', 'DELACROIX', 'BIG BEN']) {
          expect(all.toUpperCase(), isNot(contains(absent)), reason: absent);
        }
        expect(m1.transition, contains('At Gare du Nord we read: The Clockmaker steals an hour.'));
        // That the hour was not lost: only once the final is answered.
        for (final m in [m1, m2, m3]) {
          for (final claim in ['never lost', 'not lost', 'did not lose', 'lost no hour', 'never lose']) {
            expect('${missionWords(m)}\n${sceneWords(m)}'.toLowerCase(), isNot(contains(claim)), reason: '${m.id}: $claim');
          }
        }
        expect(beforeAnswer(fin).toLowerCase(), isNot(contains('not lost')));
        for (final m in [m1, m2, m3]) {
          expect('${missionWords(m)}\n${sceneWords(m)}', isNot(contains('Saint-Sulpice')), reason: m.id);
        }
        expect(beforeAnswer(fin), isNot(contains('Saint-Sulpice')));
        expect(fin.transition.last, contains('Saint-Sulpice'));
        expect(SeasonCatalog.hourRecord(fin)!.lead.lines.map((l) => l.text), contains('p.3 · SENT TO: SAINT-SULPICE · ARCHIVE ANNEX'));
        expect(SeasonCatalog.hourRecord(fin)!.lead.doneLines.last, contains('?'), reason: 'who sent it, and why: a question');
        for (final h in m2.hints) {
          expect(h, isNot(contains('café')), reason: h);
        }
      });

      test('Case 11 at ${level.name}', () {
        final e = caseAt('s2_ep11', level);
        final [m1, m2, m3, fin] = e.allMissions;
        final all = '${everything(e)}\n${[for (final m in e.allMissions) sceneWords(m)].join('\n')}';
        for (final absent in ['CLOCKMAKER', 'ÉMILE', 'EMILE', 'MOREAU', 'LONDON', 'BIG BEN']) {
          expect(all.toUpperCase(), isNot(contains(absent)), reason: 'E.M. stays E.M.: $absent');
        }
        expect(m1.letter, 'Page 3 is in Box 9.\nLock it. No one may read it.');
        expect(m1.transition, containsAll(['E.M. said, "Stop!"', 'Victor said, "Keep going."']));
        // Victor owns up only in the final.
        for (final m in [m1, m2, m3]) {
          expect('${missionWords(m)}\n${sceneWords(m)}', isNot(contains('I hid the page')), reason: m.id);
        }
        final talk = SeasonCatalog.caseTalk(fin)!;
        final name = talk.present('name')!;
        expect([for (final l in name.beat) l.text], containsAll(['Yes. I hid the page.', 'I was afraid.', "I didn't want people to know."]));
        expect(talk.question('clues')!.beat.last.text, 'His old machine is at Arts et Métiers.');
        expect(talk.question('bag')!.beat.map((l) => l.text).join(' ').toLowerCase(), isNot(contains('i carried')), reason: 'who carried the bag: untold');
        // V.D. is Victor: said after the box is opened, never before.
        expect(beforeAnswer(m1), isNot(contains('That is me')));
        expect(talkWords(SeasonCatalog.talkMission(m1)!.after!), contains('V.D.'));
      });

      test('Case 12 at ${level.name}', () {
        final e = caseAt('s2_ep12', level);
        final [m1, m2, m3, fin] = e.allMissions;
        // His name: on the tag in M1. That he is the Clockmaker: only once
        // M2 is answered.
        expect(m1.letter, 'Made by Émile Moreau');
        for (final text in ['${missionWords(m1)}\n${sceneWords(m1)}', beforeAnswer(m2)]) {
          expect(_clockmakerNamed.hasMatch(text), isFalse, reason: text);
        }
        expect(m2.successMessage.contains('Clockmaker') && m2.successMessage.contains('Émile'), isTrue);
        final after = SeasonCatalog.talkMission(m2)!.after!;
        expect([
          for (final l in after.question('bigBen')!.beat) l.text,
        ], containsAllInOrder(['A secret box is under it.', 'Inside is a list of hidden papers.', 'It opens only if Big Ben stops.']));
        expect(after.question('why')!.beat.last.text, contains('I was wrong'));
        expect(after.question('clues')!.beat.last.text, contains('wrong'), reason: 'what he did wrong, said');
        expect(SeasonCatalog.talkMission(m2)!.before!.opening.last.text, contains('Trust'), reason: '"trust clues, not my words"');
        expect(m3.letter, 'HOW TO FIX THE MACHINE\n1. Stop. 2. Turn. 3. Fix. 4. Start.');
        expect(SeasonCatalog.talkMission(m3)!.before!.opening.last.text, endsWith('Stop, turn, fix, start.'));
        // The board: the same six questions, answers; the wrong choice of the
        // last one says a good reason does not make it right.
        final board = SeasonCatalog.easySteps(fin)!;
        expect(
          [for (final s in board.steps) '${s.question}=${s.answer}'],
          [
            'Did Paris lose an hour?=no',
            'Were the clocks wrong?=yes',
            'Who hid page 3?=victor',
            'Who is the Clockmaker?=emile',
            'Why did Émile leave clues?=show',
            'Was Émile right to scare people?=no',
          ],
        );
        expect(board.steps.last.option('yes')!.feedback!.toLowerCase(), allOf(contains('reason'), anyOf(contains('ok'), contains('right'))));
        expect(fin.transition.first, 'The hour was never gone.');
        expect(e.hook, 'The hour was never gone.');
        for (final absent in ['RECORD WAS REMOVED', 'HERO']) {
          expect('${everything(e)}\n${[for (final m in e.allMissions) sceneWords(m)].join('\n')}'.toUpperCase(), isNot(contains(absent)), reason: absent);
        }
      });
    }

    test('the whole season at every level: names and truths told in their case, never before', () {
      for (final level in levels) {
        for (final id in season) {
          final e = caseAt(id, level);
          final n = e.number;
          final words = '${everything(e)}\n${[for (final m in e.allMissions) sceneWords(m)].join('\n')}'.toUpperCase();
          if (n < 11) {
            expect(words, allOf(isNot(contains('VICTOR')), isNot(contains('DELACROIX'))), reason: '$id at ${level.name}');
          }
          if (n < 12) {
            expect(words, allOf(isNot(contains('ÉMILE')), isNot(contains('MOREAU'))), reason: '$id at ${level.name}');
          }
          expect(words, isNot(contains('THE RECORD WAS REMOVED')), reason: id);
        }
      }
    });
  });

  group('Hints', () {
    test('as many at every level, never the answer; three different sets', () {
      for (final id in cases) {
        for (final m in baseCase(id).allMissions) {
          final sets = {for (final level in levels) at(m.id, level).hints.join('|')};
          expect(sets, hasLength(3), reason: m.id);
          for (final level in levels) {
            final hints = at(m.id, level).hints;
            expect(hints, hasLength(m.hints.length));
            if (m.type == MissionType.multipleChoice) {
              for (final h in hints) {
                expect(AnswerChecker.normalize(h).contains(AnswerChecker.normalize(m.answerLabel)), isFalse, reason: '${m.id} ${level.name}: "$h"');
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
              active: 's2_ep10',
              progress: {
                's2_ep10': const GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: ['s2_ep10_m1'], hintsUsed: {'s2_ep10_m2': 1}),
              },
            ),
          ),
        );
        addTearDown(c.dispose);
        final played = c.read(currentEpisodeProvider);
        expect((played.id, played.allMissions.first.difficulty), ('s2_ep10', level));
        expect(c.read(gameControllerProvider).hintsFor('s2_ep10_m2'), 1, reason: level.name);
        expect(played.missionById('s2_ep10_m2')!.hints, at('s2_ep10_m2', level).hints);
      }
    });
  });

  group('Discovery Moments and the parent report, the whole season', () {
    test('each title is the success line of the level played', () {
      for (final id in season) {
        for (final m in baseCase(id).missions) {
          for (final level in levels) {
            final played = at(m.id, level);
            final d = SeasonCatalog.discovery(played);
            expect((d.title, d.type), (played.successMessage, season2DiscoveryTypes[m.id]), reason: '${m.id} at ${level.name}');
          }
          if (cases.contains(id)) {
            expect({for (final level in levels) SeasonCatalog.discovery(at(m.id, level)).title}, hasLength(3), reason: m.id);
          }
        }
      }
    });

    test('each level names its own English, really on its pages, the whole season', () {
      for (final id in season) {
        for (final m in baseCase(id).allMissions) {
          final named = <String>{};
          for (final level in levels) {
            final played = at(m.id, level);
            final l = SeasonCatalog.learning(played)!;
            expect(LearningCheck.unmatched(l, played), isEmpty, reason: '${m.id} at ${level.name}');
            final b = season2Learning[m.id]!;
            // The design's own honesty is the base's.
            expect((l.dependency, l.level, l.skill, l.recallFrom, l.isHonest), (b.dependency, b.level, b.skill, b.recallFrom, b.isHonest));
            named.add(l.expressions.join('|'));
          }
          if (cases.contains(id)) expect(named, hasLength(3), reason: m.id);
        }
      }
    });

    for (final level in levels) {
      test('Paris played at ${level.name}: the report of Case 12 names ${level.name}\'s English, whatever the profile says later', () async {
        final other = levels[(level.index + 1) % levels.length];
        final c = ProviderContainer(
          overrides: await testOverrides(
            prefs: parisAt(
              level,
              active: 's2_ep12',
              profile: other,
              progress: {
                's2_ep12': GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: [for (final m in baseCase('s2_ep12').allMissions) m.id]),
              },
            ),
          ),
        );
        addTearDown(c.dispose);
        final report = DetectiveReport.from(c.read(currentEpisodeProvider), c.read(gameControllerProvider));
        for (final m in baseCase('s2_ep12').allMissions) {
          final p = report.performances.firstWhere((p) => p.mission.id == m.id);
          expect(p.learning!.expressions, SeasonCatalog.learning(at(m.id, level))!.expressions, reason: '${m.id} at ${level.name}');
        }
      });
    }

    test('an old save (no level anywhere) plays Rookie\'s words', () async {
      final c = ProviderContainer(
        overrides: await testOverrides(
          prefs: {
            AppConstants.progressKeyFor('s2_ep11'): jsonEncode(
              const GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: ['s2_ep11_m1']).toJson(),
            ),
          },
        ),
      );
      addTearDown(c.dispose);
      final played = c.read(playedEpisodesProvider).firstWhere((e) => e.id == 's2_ep11');
      expect(played.allMissions.first.difficulty, Difficulty.rookie);
      expect(fields(played), fields(baseCase('s2_ep11')));
    });
  });

  group('On screen', () {
    Future<WidgetRef> openParis(WidgetTester t, Difficulty level, String active, Size size, {double textScale = 1}) async {
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
            ...await testOverrides(prefs: parisAt(level, active: active, selected: false)),
            seasonPreviewProvider.overrideWithValue(true),
          ],
          child: Consumer(
            builder: (context, r, _) {
              ref = r;
              return RepaintBoundary(key: const ValueKey('shot'), child: const WorldMysteryApp());
            },
          ),
        ),
      );
      await wait(t, const Duration(milliseconds: 300));
      final game = ref.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      expect(game.openEpisode(active), isTrue);
      game.startInvestigation();
      expect(ref.read(currentEpisodeProvider).allMissions.first.difficulty, level);
      return ref;
    }

    /// Case 11 M1: its story, then Victor's first lines, in the level's words.
    Future<void> talkOpens(WidgetTester t, WidgetRef ref, Difficulty level, String tag) async {
      ref.read(routerProvider).go(Routes.mission('s2_ep11_m1'));
      await wait(t, const Duration(milliseconds: 1400));
      final m = at('s2_ep11_m1', level);
      final play = EasyPlay(t, tag);
      expect(findReadable(m.story.first), findsOneWidget, reason: '$tag: the story');
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 2500));
      final talk = SeasonCatalog.talkMission(m)!.before!;
      expect(findReadableContaining(talk.opening.first.text), findsWidgets, reason: "$tag: Victor's first line");
      for (final other in levels.where((l) => l != level)) {
        final line = SeasonCatalog.talkMission(at('s2_ep11_m1', other))!.before!.opening.first.text;
        if (!talk.opening.first.text.contains(line)) expect(findReadableContaining(line), findsNothing, reason: '$tag: not ${other.name}\'s');
      }
      await play.shot('talk');
    }

    /// Case 12's final: its board's first question (a free hint, a wrong
    /// answer), then every question answered, and the ending's first line.
    Future<void> boardAndEnding(WidgetTester t, WidgetRef ref, Difficulty level, String tag) async {
      final game = ref.read(gameControllerProvider.notifier);
      for (final m in ref.read(currentEpisodeProvider).missions) {
        game.submitAnswer(m, m.answer);
      }
      ref.read(routerProvider).go(Routes.finalMission);
      await wait(t, const Duration(milliseconds: 1600));
      final play = EasyPlay(t, tag);
      final board = SeasonCatalog.easySteps(at('s2_ep12_final', level))!;
      final q1 = board.steps.first;
      play.expectSay(q1.say);
      await play.tapKey('easy-hint');
      expect(findReadable(q1.hints.first), findsOneWidget, reason: '$tag: its level\'s hint');
      await play.tapKey('easy-option-yes');
      expect(findReadable(q1.option('yes')!.feedback!), findsOneWidget);
      await play.shot('board');
      for (final step in board.steps) {
        await play.tapKey('easy-option-${step.answer}');
        expect(findReadable(step.done!), findsOneWidget, reason: '$tag ${step.id}');
        await play.next(after: const Duration(milliseconds: 1600));
      }
      final ending = SeasonCatalog.caseEnding(at('s2_ep12_final', level))!;
      await wait(t, const Duration(seconds: 3));
      expect(findReadableContaining(ending.first.text), findsWidgets, reason: '$tag: the ending, in its level\'s words');
      await play.shot('ending');
    }

    for (final level in levels) {
      testWidgets('Case 11 M1 at ${level.name} (390 × 844): the talk', (t) async {
        final ref = await openParis(t, level, 's2_ep11', const Size(390, 844));
        await talkOpens(t, ref, level, '7d_talk_${level.name}');
        expect(t.takeException(), isNull);
        await wait(t, const Duration(seconds: 3));
      });

      testWidgets('Case 12 final at ${level.name} (390 × 844): the board and the ending', (t) async {
        final ref = await openParis(t, level, 's2_ep12', const Size(390, 844));
        await boardAndEnding(t, ref, level, '7d_board_${level.name}');
        expect(t.takeException(), isNull);
        await wait(t, const Duration(seconds: 3));
      });
    }

    testWidgets('Master on a small phone, its words 1.3 times larger: the talk, the board and the ending', (t) async {
      final ref = await openParis(t, Difficulty.master, 's2_ep11', const Size(360, 640), textScale: 1.3);
      await talkOpens(t, ref, Difficulty.master, '7d_talk_small');
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('Master on a small phone, its words 1.3 times larger: the board and the ending', (t) async {
      final ref = await openParis(t, Difficulty.master, 's2_ep12', const Size(360, 640), textScale: 1.3);
      await boardAndEnding(t, ref, Difficulty.master, '7d_board_small');
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('Master on a tablet: the board and the ending', (t) async {
      final ref = await openParis(t, Difficulty.master, 's2_ep12', const Size(834, 1194));
      await boardAndEnding(t, ref, Difficulty.master, '7d_board_tablet');
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 3));
    });
  });
}
