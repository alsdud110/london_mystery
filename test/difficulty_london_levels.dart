import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/utils/answer_checker.dart';
import 'package:london_mystery/data/content/difficulty_content.dart';
import 'package:london_mystery/data/content/learning_check.dart';
import 'package:london_mystery/data/mock/season1/season1_difficulty.dart';
import 'package:london_mystery/data/mock/season_catalog.dart';
import 'package:london_mystery/data/models/difficulty.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';

/// The checks every London PART 6 batch (6B–6D) runs on its cases, as
/// PART 6A's test runs them on Cases 01–03: the same case at every level,
/// each level its own words, Rookie the base, nothing left to fall back,
/// and the parent report's English on each level's pages.

final base = MockEpisodeRepository.bundled();
Episode baseCase(String id) => base.firstWhere((e) => e.id == id);
Episode caseAt(String id, Difficulty level) => DifficultyContent.episodeAt(baseCase(id), level);
Mission at(String missionId, Difficulty level) =>
    caseAt(base.firstWhere((e) => e.allMissions.any((m) => m.id == missionId)).id, level).missionById(missionId)!;

/// What the player reads of [m] before answering it.
List<String> pageOf(Mission m) => [
      m.title,
      m.location,
      ...m.story,
      m.letterIntro,
      m.letter,
      m.question,
      ?m.prompt,
      for (final o in m.options)
        if (!m.hideOptionNames) o.label,
      ...m.hints,
    ];

/// Everything the final's screen shows before it is answered (its page,
/// tips and every wrong-answer line).
List<String> finalScreenOf(Mission m) => [
      ...m.story,
      m.letterIntro,
      m.letter,
      m.question,
      ?m.prompt,
      ...m.hints,
      ...m.feedback.values,
      ?m.orderFeedback,
      for (final o in m.options) ?o.feedback,
    ];

bool hasWord(String text, String w) => RegExp('\\b$w\\b', caseSensitive: false).hasMatch(text);

/// [cases] checked at every level. [same]: `missionId.field` kept the same
/// at every level on purpose (puzzle data, a quote a later case reads, how
/// to play). [partly]: cases whose Junior and Master still lack what the
/// engine cannot take at a level (each with exactly what it lacks).
void checkLondonCases(
  List<String> cases, {
  Set<String> same = const {},
  Map<String, List<String>> partly = const {},
  Set<String> sameLearning = const {},
}) {
  group('the same case at every level', () {
    for (final id in cases) {
      test('$id: structure, answers, options, hints and rewards as the base', () {
        final b = baseCase(id);
        for (final level in Difficulty.values) {
          final e = caseAt(id, level);
          expect(DifficultyContent.structureOfEpisode(e), DifficultyContent.structureOfEpisode(b), reason: level.name);
          for (final m in e.allMissions) {
            final bm = b.missionById(m.id)!;
            expect(m.answer, bm.answer);
            expect(m.acceptedAnswers, bm.acceptedAnswers);
            expect([for (final o in m.options) o.id], [for (final o in bm.options) o.id], reason: '${m.id} options in order');
            expect([for (final o in m.options) o.label], [for (final o in bm.options) o.label],
                reason: '${m.id}: the choices are named as before');
            expect(m.hints, hasLength(bm.hints.length), reason: m.id);
            expect(m.feedback.keys, bm.feedback.keys, reason: m.id);
            expect(m.clue?.value, bm.clue?.value);
            expect(m.clue?.title, bm.clue?.title);
            expect(m.evidence?.id, bm.evidence?.id);
            expect(m.evidence?.name, bm.evidence?.name);
            expect(m.evidence?.inscription, bm.evidence?.inscription, reason: '${m.id}: evidence words are puzzle data');
            expect(WalletController.coinsFor(m), WalletController.coinsFor(bm));
            expect(AnswerChecker.isCorrect(m, bm.answer), isTrue, reason: '${m.id} at ${level.name}');
            for (final wrong in bm.feedback.keys) {
              expect(AnswerChecker.isCorrect(m, wrong), isFalse);
              expect(AnswerChecker.feedbackFor(m, wrong), m.feedback[wrong]);
            }
            // The detective's name stays where the base says it.
            for (final (field, mine, theirs) in [
              ('story', m.story.join('\n'), bm.story.join('\n')),
              ('letter', m.letter, bm.letter),
              ('letterIntro', m.letterIntro, bm.letterIntro),
              ('transition', m.transition.join('\n'), bm.transition.join('\n')),
              ('successMessage', m.successMessage, bm.successMessage),
            ]) {
              expect(mine.contains('{detectiveName}'), theirs.contains('{detectiveName}'), reason: '${m.id}.$field at ${level.name}');
            }
          }
        }
        expect(DifficultyContent.problemsOf(season1Content), isEmpty);
      });
    }

    test('no tip, at any level, gives its answer', () {
      for (final id in cases) {
        for (final level in Difficulty.values) {
          for (final m in caseAt(id, level).allMissions) {
            final answer = switch (m.type) {
              MissionType.multipleChoice || MissionType.imageChoice => m.answerLabel,
              MissionType.sequence || MissionType.examine => null,
              _ => m.answer,
            };
            if (answer == null) continue;
            for (final h in m.hints) {
              expect(AnswerChecker.normalize(h).contains(AnswerChecker.normalize(answer)), isFalse,
                  reason: '${m.id} at ${level.name}: "$h"');
              expect(h, isNot(contains('{detectiveName}')));
            }
          }
        }
      }
    });
  });

  group('each level its own words', () {
    test('Junior and Master write every page; neither is the base nor the other', () {
      for (final id in cases) {
        final b = baseCase(id);
        final j = caseAt(id, Difficulty.junior), m = caseAt(id, Difficulty.master);
        expect({jsonEncode(b.intro), jsonEncode(j.intro), jsonEncode(m.intro)}, hasLength(3), reason: '$id.intro');
        expect({jsonEncode(b.synopsis), jsonEncode(j.synopsis), jsonEncode(m.synopsis)}, hasLength(3), reason: '$id.synopsis');
        expect(j.intro, hasLength(b.intro.length));
        expect(m.intro, hasLength(b.intro.length));
        for (final bm in b.allMissions) {
          final (jm, mm) = (j.missionById(bm.id)!, m.missionById(bm.id)!);
          final fields = <String, List<Object?>>{
            'story': [bm.story, jm.story, mm.story],
            'letterIntro': [bm.letterIntro, jm.letterIntro, mm.letterIntro],
            'letter': [bm.letter, jm.letter, mm.letter],
            'question': [bm.question, jm.question, mm.question],
            if (bm.prompt != null) 'prompt': [bm.prompt, jm.prompt, mm.prompt],
            'hints': [bm.hints, jm.hints, mm.hints],
            'successMessage': [bm.successMessage, jm.successMessage, mm.successMessage],
            'transition': [bm.transition, jm.transition, mm.transition],
          };
          fields.forEach((field, v) {
            final key = '${bm.id}.$field';
            if (v.first is String && (v.first as String).trim().isEmpty) return;
            if (v.first is List && (v.first as List).isEmpty) return;
            if (same.contains(key)) {
              expect(v.map(jsonEncode).toSet(), hasLength(1), reason: '$key is the same at every level, on purpose');
            } else {
              expect(v.map(jsonEncode).toSet(), hasLength(3), reason: '$key: base, Junior and Master all differ');
            }
          });
          expect(jm.story, hasLength(bm.story.length), reason: bm.id);
          expect(mm.story, hasLength(bm.story.length), reason: bm.id);
          expect(jm.transition, hasLength(bm.transition.length), reason: bm.id);
          expect(mm.transition, hasLength(bm.transition.length), reason: bm.id);
        }
      }
    });

    test('Rookie: the base, but for the lines Rookie writes', () {
      for (final id in cases) {
        final r = caseAt(id, Difficulty.rookie).toJson();
        final b = baseCase(id).toJson();
        final patch = season1CasePatches[Difficulty.rookie]?[id] ?? const <String, Object?>{};
        for (final key in b.keys) {
          if (key == 'missions' || key == 'finalMission' || patch.containsKey(key)) continue;
          expect(r[key], b[key], reason: '$id.$key');
        }
        final missions = patch['missions'] as Map? ?? const {};
        for (final bm in baseCase(id).allMissions) {
          final rm = caseAt(id, Difficulty.rookie).missionById(bm.id)!.toJson();
          final own = missions[bm.id] as Map? ?? const {};
          for (final key in bm.toJson().keys) {
            if (own.containsKey(key)) {
              expect(rm[key], isNot(bm.toJson()[key]), reason: '${bm.id}.$key: Rookie\'s own');
            } else {
              expect(rm[key], bm.toJson()[key], reason: '${bm.id}.$key: the base');
            }
          }
        }
      }
    });

    test('nothing at Junior or Master falls back unseen; the written levels marked', () {
      for (final id in cases) {
        final lacks = partly[id];
        for (final level in [Difficulty.junior, Difficulty.master]) {
          expect(DifficultyContent.missingAt(id, level), lacks ?? isEmpty, reason: '$id at ${level.name}');
        }
        expect(season1Content.writtenLevels[id], lacks == null ? Difficulty.values.toSet() : {Difficulty.rookie}, reason: id);
      }
    });

    test('Discovery Moments: the base\'s kind, timing and title; each level its own words', () {
      for (final id in cases) {
        for (final bm in baseCase(id).missions) {
          final d = {for (final level in Difficulty.values) level: SeasonCatalog.discovery(at(bm.id, level))};
          final b = SeasonCatalog.discovery(bm);
          for (final level in Difficulty.values) {
            expect(DifficultyContent.structureOf(d[level]), DifficultyContent.structureOf(b), reason: '${bm.id} ${level.name}');
            expect(d[level]!.title, b.title, reason: '${bm.id} ${level.name}');
          }
          expect({b.detail, d[Difficulty.junior]!.detail, d[Difficulty.master]!.detail}, hasLength(3), reason: bm.id);
        }
      }
    });

    test('a puzzle table entry at Junior and Master: the base\'s kind and structure', () {
      for (final level in [Difficulty.junior, Difficulty.master]) {
        final variant = season1Content.variants[level]!;
        for (final MapEntry(key: table, value: entries) in variant.missionTables.entries) {
          for (final MapEntry(key: id, value: entry) in entries.entries) {
            final b = season1Content.missionTables[table]![id];
            expect(entry.runtimeType, b.runtimeType);
            expect(DifficultyContent.structureOf(entry), isNotNull, reason: '$table/$id');
            expect(DifficultyContent.structureOf(entry), DifficultyContent.structureOf(b), reason: '$table/$id at ${level.name}');
          }
        }
      }
    });
  });

  group("the parent report's English", () {
    test('every expression is on its own level\'s pages', () {
      for (final level in Difficulty.values) {
        final missions = {
          for (final e in base)
            if (e.seasonId == baseCase(cases.first).seasonId)
              for (final m in caseAt(e.id, level).allMissions) m.id: m,
        };
        for (final id in cases) {
          for (final m in caseAt(id, level).allMissions) {
            final l = SeasonCatalog.learning(m);
            if (l == null) continue;
            final recalled = l.recallFrom == null ? null : missions[l.recallFrom];
            expect(LearningCheck.unmatched(l, m, recalled: recalled), isEmpty, reason: '${m.id} at ${level.name}');
            final b = SeasonCatalog.learning(baseCase(id).missionById(m.id)!)!;
            expect(DifficultyContent.structureOf(l), DifficultyContent.structureOf(b));
          }
        }
      }
    });

    test('Junior and Master name their own English where their words differ', () {
      for (final id in cases) {
        for (final bm in baseCase(id).allMissions) {
          final names = {
            for (final level in Difficulty.values) SeasonCatalog.learning(at(bm.id, level))?.expressions.join('|'),
          };
          if (names.every((n) => n == null || n.isEmpty)) continue;
          if (sameLearning.contains(bm.id)) {
            expect(names, hasLength(1), reason: bm.id);
          } else {
            expect(names.length, greaterThan(1), reason: bm.id);
          }
        }
      }
    });
  });
}
