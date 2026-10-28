import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/difficulty.dart';

import 'difficulty_london_levels.dart';

/// Difficulty PART 6C: London Cases 07–09 written at Rookie, Junior and
/// Master — the same case at every level, the reasoning guards of each case
/// kept at each level.

void main() {
  checkLondonCases(
    const ['ep07', 'ep08', 'ep09'],
    same: const {
      // Puzzle data: the directions, the instructions, the tag, the ticket,
      // the notes — or how it is typed.
      'ep07_m1.letter', 'ep07_m3.letter', 'ep07_final.letter',
      'ep08_m1.letter', 'ep08_m2.prompt', 'ep08_m3.letter',
      'ep09_m2.prompt', 'ep09_final.prompt', 'ep09_final.letter',
    },
    // The notes' "whose" lines, word for word at every level (Case 12).
    sameLearning: const {'ep09_final'},
  );

  group('Case 07 guards, at every level', () {
    for (final level in Difficulty.values) {
      test('${level.label}: left over the bridge, the arrow, and no old gate named early', () {
        final e = caseAt('ep07', level);
        final fin = e.finalMission;
        expect(fin.letter, contains('Cross the bridge and turn left!'));
        expect(fin.answer, baseCase('ep07').finalMission.answer);
        for (final m in e.missions) {
          final d = SeasonCatalog.discovery(m);
          for (final line in [d.title, d.detail, ?d.note]) {
            expect(line.toLowerCase(), isNot(contains('old gate')), reason: '${m.id} at ${level.name}');
          }
        }
        expect(e.missionById('ep07_m3')!.transition.join(' '), contains('where my arrow points'));
      });
    }
  });

  group('Case 08 guards, at every level', () {
    for (final level in Difficulty.values) {
      test('${level.label}: never in Gallery 8, the long red coat, and no button, coat or red on the final', () {
        final e = caseAt('ep08', level);
        final m2 = e.missionById('ep08_m2')!;
        final fin = e.finalMission;
        expect(m2.letter, contains('in a long red coat'));
        expect(m2.clue!.note, contains('long red coat'));
        expect(fin.letter, contains('I was never in Gallery 8.'));
        for (final line in finalScreenOf(fin)) {
          for (final w in ['buttons?', 'coats?', 'red']) {
            expect(hasWord(line, w), isFalse, reason: '${level.name}: "$line"');
          }
        }
        expect(fin.hints.last, contains('Case 03'));
      });
    }
  });

  group('Case 09 guards, at every level', () {
    for (final level in Difficulty.values) {
      test('${level.label}: "whose key you used" word for word, HAT never in a tip', () {
        final e = caseAt('ep09', level);
        final fin = e.finalMission;
        expect(fin.letter, contains('Hide it in the thing of the one whose key you used.'));
        expect(e.missionById('ep09_m1')!.letter, contains("The guard's key is big and gold."));
        expect(fin.answer, baseCase('ep09').finalMission.answer);
      });
    }
  });
}
