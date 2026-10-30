import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'helpers.dart';
import 'package:world_mystery/widgets/symbol_icon.dart';

/// Checks every case of the season with the same rules, so a new case is
/// validated as soon as it is added to the catalog.
void main() {
  final season = season1Cases();
  final later = season.where((e) => e.id != 'ep01').toList();

  test('cases are numbered 1..n in order, with unique ids', () {
    expect([for (final e in season) e.number], [for (var i = 1; i <= season.length; i++) i]);
    final missionIds = [for (final e in season) ...e.allMissions.map((m) => m.id)];
    final clueIds = [for (final e in season) ...e.allClues.map((c) => c.id)];
    final evidenceIds = [for (final e in season) ...e.allEvidence.map((v) => v.id)];
    for (final ids in [missionIds, clueIds, evidenceIds]) {
      expect(ids.toSet(), hasLength(ids.length));
    }
  });

  for (final e in season) {
    group('Case ${e.numberLabel} — ${e.title}', () {
      test('play order: nextMissionId chains every mission into the final case', () {
        expect(e.missions, isNotEmpty);
        for (var i = 0; i < e.missions.length; i++) {
          final next = i + 1 < e.missions.length ? e.missions[i + 1].id : e.finalMission.id;
          expect(e.missions[i].nextMissionId, next, reason: e.missions[i].id);
          expect(e.missions[i].isFinal, isFalse, reason: e.missions[i].id);
        }
        expect(e.finalMission.isFinal, isTrue);
      });

      test('every mission is solvable and complete', () {
        for (final m in e.allMissions) {
          expect(AnswerChecker.isCorrect(m, m.answer), isTrue, reason: m.id);
          expect(AnswerChecker.isCorrect(m, ''), isFalse, reason: m.id);
          expect(m.hints.length, inInclusiveRange(1, AppConstants.maxHints), reason: m.id);
          expect(m.evidence, isNotNull, reason: m.id);
          if (!m.isFinal) {
            expect(m.clue, isNotNull, reason: m.id);
            expect(m.transition, isNotEmpty, reason: m.id);
          }
          if (m.type == MissionType.multipleChoice || m.type == MissionType.imageChoice) {
            expect(m.options.map((o) => o.id), contains(m.answer), reason: m.id);
            expect(m.options.length, greaterThanOrEqualTo(3), reason: '${m.id}: no 50/50 guessing');
          }
          if (m.type == MissionType.imageChoice) {
            // A landmark, or a picture file of its own (London Cases 03 and
            // 12 since 2026-10-30: the sketches, the gears).
            expect(m.options.every((o) => o.artwork != null || o.picture != null), isTrue, reason: m.id);
            final right = m.options.firstWhere((o) => o.id == m.answer).artwork;
            if (right != null) expect(m.scene, isNot(right), reason: '${m.id}: the scene picture must not show the answer');
            for (final o in m.options.where((o) => o.picture != null)) {
              expect(File(o.picture!).existsSync(), isTrue, reason: '${m.id}: ${o.picture}');
            }
          }
          if (m.type == MissionType.sequence) {
            final ids = Mission.sequenceIds(m.answer);
            expect(ids, hasLength(m.codeLength), reason: m.id);
            expect(m.options.map((o) => o.id).toSet(), containsAll(ids.toSet()), reason: m.id);
            // A shuffled order must not also be right.
            expect(AnswerChecker.isCorrect(m, ids.reversed.join(',')), ids.reversed.join() == ids.join(), reason: m.id);
          } else if (m.codeLength != null) {
            expect(m.answer.length, m.codeLength, reason: m.id);
          }
          expect(m.mapX, inInclusiveRange(0, 1), reason: m.id);
          expect(m.mapY, inInclusiveRange(0, 1), reason: m.id);
        }
      });

      test('pictures exist for every clue, evidence and lock', () {
        final keys = [
          for (final c in e.allClues) ?c.symbol,
          for (final v in e.allEvidence) v.icon,
          ...e.finalMission.dialSymbols,
        ];
        for (final k in keys) {
          expect(GameSymbol.of(k).label, isNot('Mystery'), reason: '${e.id}: unknown symbol "$k"');
        }
      });

      test('glossary keys are lower-case single words', () {
        for (final k in e.glossary.keys) {
          expect(k, k.toLowerCase());
          expect(k.contains(' '), isFalse, reason: k);
        }
      });

      test('JSON round-trip is lossless', () {
        expect(Episode.fromJson(e.toJson()).toJson(), e.toJson());
      });
    });
  }

  group('new cases', () {
    test('tips help without giving the answer away', () {
      for (final e in later) {
        for (final m in e.allMissions) {
          final answer = switch (m.type) {
            MissionType.multipleChoice || MissionType.imageChoice => m.answerLabel,
            MissionType.sequence => null,
            _ => m.answer,
          };
          if (answer == null) continue;
          for (final h in m.hints) {
            expect(AnswerChecker.normalize(h).contains(AnswerChecker.normalize(answer)), isFalse,
                reason: '${m.id}: "$h" gives away "$answer"');
          }
        }
      }
    });

    test('typed answers are not written in the intro or the scene before the puzzle', () {
      // Whole words only ("HAT" must not match inside "that").
      String words(Iterable<String> lines) =>
          ' ${lines.join(' ').toUpperCase().replaceAll(RegExp('[^A-Z0-9]+'), ' ').trim()} ';
      for (final e in later) {
        final intro = words([...e.intro, ...e.synopsis]);
        for (final m in e.allMissions) {
          if (m.type != MissionType.wordInput && m.type != MissionType.numberCode && m.type != MissionType.finalCode) {
            continue;
          }
          final answer = words([m.answer]);
          if (answer.trim().length < 3) continue;
          final scene = words([...m.story, m.letterIntro]);
          expect(intro.contains(answer), isFalse, reason: '${m.id}: the intro gives away "${m.answer}"');
          expect(scene.contains(answer), isFalse, reason: '${m.id}: the scene gives away "${m.answer}"');
        }
      }
    });

    test('word prompts show one blank per letter of the answer', () {
      for (final e in later) {
        for (final m in e.allMissions.where((m) => m.prompt != null)) {
          // One blank per word, side by side ("UNDER ___ ___"): one group.
          final blanks = RegExp(r'_+(?: +_+)*').allMatches(m.prompt!).toList();
          expect(blanks, hasLength(1), reason: '${m.id}: one blank group (it is replaced by the typed word)');
          final runs = [for (final r in RegExp('_+').allMatches(m.prompt!)) r.group(0)!.length];
          expect(runs.fold(0, (a, b) => a + b), AnswerChecker.normalize(m.answer).length, reason: m.id);
          if (runs.length > 1) {
            expect(runs, [for (final w in m.answer.trim().split(RegExp(r'\s+'))) AnswerChecker.normalize(w).length],
                reason: '${m.id}: one blank per word of the answer');
          }
        }
      }
    });

    test('each case tells its own story: summary, hook and intro', () {
      for (final e in later) {
        expect(e.caseSummary, isNotNull, reason: e.id);
        expect(e.hook, isNotNull, reason: e.id);
        expect(e.intro, isNotEmpty, reason: e.id);
        expect(e.keyWords, isNotEmpty, reason: e.id);
        expect(e.allEvidence.length, inInclusiveRange(2, 4), reason: e.id);
      }
    });

    // No mission needs physical cards on site, a camera or anyone's help:
    // the one thing examined (Case 01's crown card) is examined in its own
    // scene. (Since 2026-10-19 there is no QR mission type at all.)
    test('no mission needs a card on site: only Case 01 M5 is examined, in its scene', () {
      for (final e in later) {
        expect(e.allMissions.where((m) => m.type == MissionType.examine), isEmpty, reason: e.id);
      }
      expect(MissionType.values.map((t) => t.name), isNot(contains('qrScan')));
    });

    // A puzzle's kind as the child plays it: a mission played in its own
    // scene (a talk, a search, a lens, traces, a code, a clock) is that
    // scene, whatever its data type; any other is its type (2026-10-23,
    // approved: Case 06 M1 is a talk with the witnesses, not a choice).
    String kindOf(Mission m) => switch (m) {
          _ when SeasonCatalog.dialogue(m) != null => 'talk',
          _ when SeasonCatalog.investigation(m) != null => 'search',
          _ when SeasonCatalog.explore(m) != null => 'explore',
          _ when SeasonCatalog.inspection(m) != null => 'lens',
          _ when SeasonCatalog.deduction(m) != null => 'traces',
          _ when SeasonCatalog.decode(m) != null => 'decode',
          _ when SeasonCatalog.clock(m) != null => 'clock',
          _ => m.type.name,
        };

    test('a case mixes puzzle types instead of repeating one', () {
      for (final e in later) {
        final kinds = e.allMissions.map(kindOf).toSet();
        expect(kinds.length, greaterThanOrEqualTo(3), reason: '${e.id}: $kinds');
      }
      // Case 06: the talk, the card's word, then two choices.
      expect(season.firstWhere((e) => e.id == 'ep06').allMissions.map(kindOf).toSet(), {'talk', 'wordInput', 'multipleChoice'});
    });
  });
}
