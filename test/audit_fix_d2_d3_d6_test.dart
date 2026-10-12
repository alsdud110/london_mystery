import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/utils/answer_checker.dart';
import 'package:london_mystery/data/mock/season1/season1_discoveries.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';

/// Season 1 audit fixes D2, D3, D6: what a scene says it remembers, reads or
/// times is what the detective really saw before.
void main() {
  final catalog = MockEpisodeRepository.bundled();
  Episode byId(String id) => catalog.firstWhere((e) => e.id == id);

  group('D2 — Case 05: the warning on the wall is seen before it is remembered', () {
    final e = byId('ep05');
    final after = e.finalMission.transition;

    test('the post-case scene remembers the words on the wall', () {
      final i = after.indexWhere((l) => l.contains('remember the words') && l.contains('on the wall'));
      expect(i, isNot(-1));
      expect(after[i + 1], '"At midnight,\nthe Clockmaker will stop London."');
    });

    test('Mission 03 shows those words, on the wall, before the final', () {
      final m3 = e.missionById('ep05_m3')!;
      expect(e.missions, contains(m3), reason: 'a regular mission, played before the final');
      final scene = m3.transition;
      final wall = scene.indexWhere((l) => l.contains('On the wall'));
      expect(wall, isNot(-1));
      expect(scene[wall + 1], '"At midnight, the Clockmaker will stop London."');
      // The same words as remembered (the line break is only layout).
      final remembered = after[after.indexWhere((l) => l.contains('remember the words')) + 1].replaceAll('\n', ' ');
      expect(scene[wall + 1], remembered);
      // Still the scene's question after it, and the chest before it.
      expect(scene.first, 'Behind the food box, there is an iron chest.');
      expect(scene.last, 'The Clockmaker... who is that?');
    });

    test('no earlier wall line was the warning (the raven sign is another wall)', () {
      final m3 = e.missionById('ep05_m3')!;
      expect(m3.letterIntro, contains('the old sign on the wall'));
      expect(m3.letter, isNot(contains('Clockmaker')));
    });

    test('the puzzles of Case 05 are unchanged', () {
      expect(e.missionById('ep05_m3')!.answer, 'SEVEN');
      expect(e.finalMission.answer, '745');
    });
  });

  group('D3 — Case 04: the postmark keeps only its picture', () {
    final e = byId('ep04');
    final m2 = e.missionById('ep04_m2')!;
    final m3 = e.missionById('ep04_m3')!;

    test('the rain washed its words away', () {
      expect(m2.transition.join(' '), contains('the rain washed the words away'));
      expect(m2.transition.join(' '), contains('Only a small picture is left.'));
    });

    test('nothing after reads the postmark as words', () {
      final later = [
        m3.evidence!.inscription!,
        m3.clue!.note,
        ...m3.transition,
        ...e.finalMission.transition,
        e.hook!,
      ];
      for (final line in later) {
        expect(line, isNot(contains('TOWER OF LONDON')), reason: '"$line": words in capitals read as printed');
        expect(line.toLowerCase(), isNot(contains('postmark says')), reason: line);
      }
      expect(m3.evidence!.inscription, contains('picture of the Tower of London'));
      expect(e.finalMission.transition.join(' '), contains('The little picture on the postmark is the Tower of London.'));
    });

    test('the picture puzzle is unchanged', () {
      expect(m3.question, 'Which picture is on the postmark?');
      expect(m3.answerLabel, 'Tower of London');
      expect(e.finalMission.answer, 'RAVEN');
    });
  });

  group('D6 — Case 08: the train is the 9:30', () {
    final m3 = byId('ep08').missionById('ep08_m3')!;

    test('the Discovery Moment names the train as the ticket does', () {
      expect(m3.letter, contains('Train: the 9:30 to Edinburgh'));
      final detail = discoveryOf(m3).detail;
      expect(detail, contains('9:30'));
      expect(detail.toLowerCase(), isNot(contains("nine o'clock")));
    });

    test('the code still takes the hour only: 429', () {
      expect(m3.answer, '429');
      expect(AnswerChecker.isCorrect(m3, '429'), isTrue);
      expect(AnswerChecker.isCorrect(m3, '4230'), isFalse);
    });
  });
}
