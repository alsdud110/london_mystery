import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/utils/answer_checker.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/widgets/symbol_icon.dart';

/// Checks every case of the season with the same rules, so a new case is
/// validated as soon as it is added to the catalog.
void main() {
  final season = MockEpisodeRepository.bundled();
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
            expect(m.options.every((o) => o.artwork != null), isTrue, reason: m.id);
            final right = m.options.firstWhere((o) => o.id == m.answer).artwork;
            expect(m.scene, isNot(right), reason: '${m.id}: the scene picture must not show the answer');
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
          final blanks = RegExp('_+').allMatches(m.prompt!).toList();
          expect(blanks, hasLength(1), reason: '${m.id}: one blank run (it is replaced by the typed word)');
          expect(blanks.single.group(0)!.length, AnswerChecker.normalize(m.answer).length, reason: m.id);
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

    test('no QR missions: they need physical cards on site', () {
      for (final e in later) {
        expect(e.allMissions.where((m) => m.type == MissionType.qrScan), isEmpty, reason: e.id);
      }
    });

    test('a case mixes puzzle types instead of repeating one', () {
      for (final e in later) {
        final types = e.allMissions.map((m) => m.type).toSet();
        expect(types.length, greaterThanOrEqualTo(3), reason: e.id);
      }
    });
  });
}
