import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/difficulty.dart';

import 'difficulty_london_levels.dart';

/// Difficulty PART 6D: London Cases 10–12 written at Rookie, Junior and
/// Master — the same case at every level, the reasoning guards of each case
/// kept at each level, and Season 1 as a whole (every case but Case 06 M1's
/// witness talk written at every level).

void main() {
  checkLondonCases(
    const ['ep10', 'ep11', 'ep12'],
    same: const {
      // How to play, and puzzle data: the reversed word, the driver's words,
      // the arrivals board, the blanks.
      'ep10_final.question',
      'ep11_m2.letter', 'ep11_m2.prompt', 'ep11_m3.letter',
      'ep12_m2.letter', 'ep12_m3.prompt',
    },
    // Read word for word at every level: Case 01's letter ("Signed: The
    // Shadow"), the door's three locks.
    sameLearning: const {'ep11_final', 'ep12_final'},
  );

  group('Case 10 guards, at every level', () {
    for (final level in Difficulty.values) {
      test('${level.label}: the choices and the order puzzle as the base, nothing named before M3, no Shadow', () {
        final b = baseCase('ep10'), e = caseAt('ep10', level);
        final m3 = e.missionById('ep10_m3')!, fin = e.finalMission;
        expect([for (final o in fin.options) o.label], [for (final o in b.finalMission.options) o.label]);
        expect(fin.answer, b.finalMission.answer);
        expect([for (final o in m3.options) o.label], [for (final o in b.missionById('ep10_m3')!.options) o.label]);
        final early = [
          ...e.intro, ...e.synopsis,
          // (M3's choices are named on purpose: the names are its puzzle.)
          for (final m in e.missions.take(3)) ...[...m.story, m.letterIntro, m.letter, m.question, ...m.hints],
          for (final m in e.missions.take(2)) ...[...m.transition, m.successMessage, SeasonCatalog.discovery(m).detail],
        ].join('\n').toLowerCase();
        expect(early, isNot(contains('tower bridge')));
        expect(early, isNot(contains('north tower')));
        expect(fin.transition.join('\n'), allOf(contains('THE CLOCKMAKER WILL STOP\nBIG BEN AT MIDNIGHT.'), contains('ROW R\nSEAT 17.')));
        for (final m in e.allMissions) {
          for (final line in [...pageOf(m), ...m.transition, m.successMessage]) {
            expect(hasWord(line, 'shadow'), isFalse, reason: '${m.id} at ${level.name}');
          }
        }
      });
    }
  });

  group('Case 11 guards, at every level', () {
    for (final level in Difficulty.values) {
      test('${level.label}: never sleeps, the driver\'s words, and nothing under Big Ben after', () {
        final e = caseAt('ep11', level);
        final m2 = e.missionById('ep11_m2')!, m3 = e.missionById('ep11_m3')!, fin = e.finalMission;
        expect(m2.transition.join(' '), contains('the station that never sleeps'), reason: "Case 04's phrase, read again");
        expect(m3.hints.first, contains('never sleep'));
        expect(m3.letter, contains('I love trains'));
        expect(fin.letter, contains('We met at the very start.'));
        expect(fin.hints.last, contains('Case 01'));
        final after = [...fin.transition, ?e.caseSummary].join(' ').toLowerCase();
        expect(after, isNot(contains('under big ben')));
        expect(hasWord([...fin.story, fin.letterIntro, fin.letter, ...fin.hints, ...fin.transition].join(' '), 'door'), isFalse);
      });
    }
  });

  group('Case 12 guards, at every level', () {
    for (final level in Difficulty.values) {
      test('${level.label}: after the train from Edinburgh, whose clock is small and red, 487, PARIS.', () {
        final e = caseAt('ep12', level);
        final m2 = e.missionById('ep12_m2')!, fin = e.finalMission;
        expect(m2.letter, contains('after the train from Edinburgh'));
        expect(m2.answer, '1140');
        expect(fin.letter, contains('the platform whose clock is small and red'));
        expect(fin.answer, '487');
        expect(fin.orderFeedback, isNotNull);
        expect(fin.transition.last, 'PARIS.');
      });
    }
  });

  // Case 06 M1's witness talk too, since 2026-10-30 (the last text that was
  // the base's at Junior and Master).
  test('Season 1: every case written at every level', () {
    for (final e in base.where((e) => e.seasonId == baseCase('ep01').seasonId)) {
      for (final level in [Difficulty.junior, Difficulty.master]) {
        expect(DifficultyContent.missingAt(e.id, level), isEmpty, reason: '${e.id} ${level.name}');
        expect(season1Content.writtenLevels[e.id], contains(level), reason: '${e.id} ${level.name}');
      }
    }
    expect(season1Content.writtenLevels.keys, hasLength(12));
    expect(DifficultyContent.problems(), isEmpty);
  });
}
