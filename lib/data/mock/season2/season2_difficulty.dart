import '../../models/difficulty.dart';
import '../../models/learning.dart';
import '../season_catalog.dart';

/// Season 2's words at Junior and Master (Rookie: the game's own words).
///
/// PART 5 sample only — Case 01 M1 (The Three Clocks): its story, question,
/// hints and success line (which is also its Discovery Moment's title) and
/// its learning design, at each level. The notice, the three clocks' times,
/// the answer (the old clock), the clue (T) and the evidence stay as they
/// are. The other cases are written in PART 7.
const Map<Difficulty, Map<String, Map<String, Object?>>> season2CasePatches = {
  Difficulty.junior: {
    's2_ep01': {
      'missions': {
        's2_ep01_m1': {
          'story': [
            'The station hall is full of busy travellers.',
            'High under the glass roof, three clocks keep ticking.',
          ],
          'question': 'Which clock is running one hour behind?',
          'hints': [
            'Compare the three clocks. Two of them agree with each other.',
            'One hour behind means one hour less than the others. Which clock shows 9:00?',
          ],
          'successMessage': 'The old clock is running one hour behind!',
        },
      },
    },
  },
  Difficulty.master: {
    's2_ep01': {
      'missions': {
        's2_ep01_m1': {
          'story': [
            'The station hall hums with hurrying travellers.',
            'High beneath the glass roof, three clocks tick away. But do they all agree?',
          ],
          'question': 'Which clock has fallen one hour behind the others?',
          'hints': [
            'Two of the clocks tell the same story. Which one disagrees?',
            'A clock one hour behind shows an hour less. Your notes hold the odd time out.',
          ],
          'successMessage': 'The old clock has fallen one hour behind!',
        },
      },
    },
  },
};

/// Season 2's puzzle tables at Junior and Master: only what differs.
const Map<Difficulty, SeasonContent> season2Variants = {
  Difficulty.junior: SeasonContent(
    info: {},
    episodes: {},
    learning: {
      's2_ep01_m1': LearningObjective(
        dependency: LanguageDependency.essential,
        level: LearningLevel.comprehension,
        skill: LanguageSkill.sentenceMeaning,
        objective: '안내문의 "If one clock is ONE HOUR BEHIND"를 이해하고, 10:00인 두 시계와 비교해 한 시간 늦은 9:00 시계를 찾는다.',
        expressions: ['running one hour behind', 'report it to the LOST PROPERTY DESK'],
      ),
    },
  ),
  Difficulty.master: SeasonContent(
    info: {},
    episodes: {},
    learning: {
      's2_ep01_m1': LearningObjective(
        dependency: LanguageDependency.essential,
        level: LearningLevel.comprehension,
        skill: LanguageSkill.sentenceMeaning,
        objective: '안내문의 "If one clock is ONE HOUR BEHIND"를 이해하고, 10:00인 두 시계와 비교해 한 시간 늦은 9:00 시계를 찾는다.',
        expressions: ['fallen one hour behind the others', 'report it to the LOST PROPERTY DESK'],
      ),
    },
  ),
};
