import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/difficulty.dart';

import 'difficulty_london_levels.dart';

/// Difficulty PART 6B: London Cases 04–06 written at Rookie, Junior and
/// Master — the same case at every level, the reasoning guards of each case
/// kept at each level. Case 06 M1's witness talk keeps the base's words (the
/// engine has no level structure check for a DialogueScene).

void main() {
  checkLondonCases(
    const ['ep04', 'ep05', 'ep06'],
    same: const {
      // Puzzle data: the words the player reasons from, or how it is typed.
      'ep04_m1.letter', 'ep04_m2.letter', 'ep04_final.prompt',
      'ep05_m3.prompt', 'ep05_final.question',
      'ep06_m2.prompt', 'ep06_m3.letter',
    },
    partly: const {'ep06': ['dialogues/ep06_m1']},
    sameLearning: const {'ep04_m2'},
  );

  group('Case 04 guards, at every level', () {
    for (final level in Difficulty.values) {
      test('${level.label}: the seal, the porter\'s platforms, "where trains never sleep", RAVEN never written early', () {
        final e = caseAt('ep04', level);
        final m1 = e.missionById('ep04_m1')!, m2 = e.missionById('ep04_m2')!, m3 = e.missionById('ep04_m3')!;
        expect(m1.letter, contains('Meet me where trains never sleep.'), reason: 'Case 11 reads it again');
        expect(m2.letter, contains('Platform 4 has a small red clock.'), reason: 'Case 12');
        expect(m2.letter, contains('but no clock'));
        expect(m3.letter, contains('Black birds live there.'));
        expect(e.finalMission.answer, baseCase('ep04').finalMission.answer);
        for (final m in e.missions) {
          for (final line in [...pageOf(m), ...m.transition, SeasonCatalog.discovery(m).detail]) {
            expect(hasWord(line, 'ravens?'), isFalse, reason: '${m.id} at ${level.name}: "$line"');
          }
        }
      });
    }
  });

  group('Case 05 guards, at every level', () {
    for (final level in Difficulty.values) {
      test('${level.label}: the lid\'s order read as written, 745 kept, 547 told', () {
        final e = caseAt('ep05', level);
        final fin = e.finalMission;
        expect(fin.answer, '745');
        expect(fin.letter, allOf(
          contains('The first lock: how many ravens live at the Tower?'),
          contains('The second lock: how many gears are on the door?'),
          contains('The third lock: what time do the gates close?'),
        ));
        expect(fin.letter.indexOf('first lock'), lessThan(fin.letter.indexOf('second lock')));
        expect(fin.letter.indexOf('second lock'), lessThan(fin.letter.indexOf('third lock')));
        expect(fin.orderFeedback, isNotNull);
        for (final line in [...fin.hints, ?fin.orderFeedback]) {
          expect(RegExp(r'\d').hasMatch(line), isFalse, reason: line);
        }
        expect(fin.transition, contains("FOR THE CLOCKMAKER'S DOOR."));
      });
    }
  });

  group('Case 06 guards, at every level', () {
    for (final level in Difficulty.values) {
      test('${level.label}: the card\'s riddle, the witness\'s hat, and no grey, hat or card on the final', () {
        final e = caseAt('ep06', level);
        final m1 = e.missionById('ep06_m1')!, m2 = e.missionById('ep06_m2')!;
        final fin = e.finalMission;
        expect(m2.letter, contains('It is the colour of my hat'));
        expect(m1.letter, contains('grey hat'), reason: 'the hat M2 reads again');
        expect(m2.answer, baseCase('ep06').missionById('ep06_m2')!.answer);
        for (final line in finalScreenOf(fin)) {
          for (final w in ['grey', 'gray', 'hats?', 'cards?']) {
            expect(hasWord(line, w), isFalse, reason: '${level.name}: "$line"');
          }
        }
        expect(fin.transition.join(' '), contains('Find the other half'));
        // The witness talk is the base's at every level.
        expect(SeasonCatalog.dialogue(m1), same(season1Content.dialogues['ep06_m1']));
        expect(DifficultyContent.missingAt('ep06', Difficulty.master), ['dialogues/ep06_m1']);
      });
    }
  });
}
