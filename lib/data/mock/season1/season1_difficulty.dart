import '../../models/clock_puzzle.dart';
import '../../models/difficulty.dart';
import '../../models/learning.dart';
import '../../models/mission.dart';
import '../season_catalog.dart';

/// Season 1's words at Junior and Master (Rookie: the game's own words).
///
/// PART 5 sample only — Case 02 M1 (Westminster Bridge): its case JSON's
/// text, its clock puzzle's lines and its learning design, at each level.
/// The facts stay (the hour hand between eight and nine, the minute hand on
/// the three and two more small marks: 8:17), and so does every answer,
/// clue, evidence and the number of hints. The other cases are written in
/// PART 6 (see docs/DIFFICULTY_IMPLEMENTATION.md, section H).
const Map<Difficulty, Map<String, Map<String, Object?>>> season1CasePatches = {
  Difficulty.junior: {
    'ep02': {
      'missions': {
        'ep02_m1': {
          'story': [
            'From Westminster Bridge, you look up at Big Ben.',
            'The great clock has gone silent. Its hands are not moving at all.',
          ],
          'letter': 'Detective {detectiveName},\n\n'
              'I was watching the clock when it stopped.\n'
              'The short hour hand had passed eight, but it had not reached nine.\n'
              'The long minute hand pointed at the three...\n'
              'then it crept forward two more small marks.\n\n'
              '— Mrs Bell, Clockkeeper',
          'question': 'At what time did Big Ben stop? Type the hour, then the minutes.',
          'hints': [
            "Go through Mrs Bell's note one line at a time. Find the hour hand first, then the minute hand.",
            'Between eight and nine, the hour is still eight. On a clock, the three means fifteen minutes. Now add the small marks.',
          ],
          'feedback': {
            '815': 'Read the last line again: the minute hand crept forward two more small marks.',
            '832': 'On a clock, the three means fifteen minutes, not three minutes.',
            '917': 'The hour hand had not reached nine yet, so the hour is still eight.',
          },
          'successMessage': 'Big Ben stopped at 8:17 exactly.',
          // Master keeps these (it has none of its own): Junior's, then the base.
          'transition': [
            'Mrs Bell unlocks a small door at the foot of the tower.',
            'Three hundred steps climb up into the dark.',
            'The answer is waiting inside the clock.',
          ],
        },
      },
    },
  },
  Difficulty.master: {
    'ep02': {
      'missions': {
        'ep02_m1': {
          'story': [
            'From the middle of Westminster Bridge, you gaze up at Big Ben.',
            'The great clock stands silent, its hands frozen in place.',
          ],
          'letter': 'Detective {detectiveName},\n\n'
              'I happened to glance up at the very moment the clock fell silent.\n'
              'The hour hand rested somewhere past eight, still short of nine.\n'
              'The minute hand lay upon the three...\n'
              'yet before it froze, it shuffled on by two more of the small marks.\n\n'
              '— Mrs Bell, Clockkeeper',
          'question': 'When exactly did Big Ben stop? Type the hour, then the minutes.',
          'hints': [
            'Mrs Bell describes each hand on its own line. Which line gives you the hour, and which the minutes?',
            'An hour hand still short of nine belongs to the eight o\'clock hour. Work out what the three means for the minute hand, then count on.',
          ],
          'feedback': {
            '815': 'The note does not end at the three. What happened just before the clock froze?',
            '832': 'The numbers on a clock face are not minutes. What does the three stand for?',
            '917': 'Was the hour hand past nine, or still short of it?',
          },
          'successMessage': 'Big Ben fell silent at precisely 8:17.',
        },
      },
    },
  },
};

/// Season 1's puzzle tables at Junior and Master: only the entries whose
/// words differ (the clock face, the hands' start and the answer never).
const Map<Difficulty, SeasonContent> season1Variants = {
  Difficulty.junior: SeasonContent(
    info: {},
    episodes: {},
    clocks: {
      'ep02_m1': ClockPuzzle(
        face: Artwork.clockFace,
        question: 'At what time did Big Ben stop? Set the hands.',
        lead: 'Mrs Bell passes you her clock face. Move the hands to where she saw them stop.',
        guide: 'Drag the short hand for the hour and the long hand for the minutes.',
        dialLabel: "Mrs Bell's clock face",
      ),
    },
    learning: {
      'ep02_m1': LearningObjective(
        dependency: LanguageDependency.essential,
        level: LearningLevel.comprehension,
        skill: LanguageSkill.sentenceMeaning,
        objective: '시계 바늘을 설명한 영어 문장을 읽고 멈춘 시각(8:17)을 알아낸다.',
        expressions: ['had passed eight, but it had not reached nine', 'crept forward two more small marks'],
      ),
    },
  ),
  Difficulty.master: SeasonContent(
    info: {},
    episodes: {},
    clocks: {
      'ep02_m1': ClockPuzzle(
        face: Artwork.clockFace,
        question: 'When exactly did Big Ben stop? Set the hands to show it.',
        lead: 'Mrs Bell entrusts you with her clock face. Place the hands just as she remembers them.',
        guide: 'Drag the short hand for the hour and the long hand for the minutes.',
        dialLabel: "Mrs Bell's clock face",
      ),
    },
    learning: {
      'ep02_m1': LearningObjective(
        dependency: LanguageDependency.essential,
        level: LearningLevel.comprehension,
        skill: LanguageSkill.sentenceMeaning,
        objective: '시계 바늘을 설명한 영어 문장을 읽고 멈춘 시각(8:17)을 알아낸다.',
        expressions: ['somewhere past eight, still short of nine', 'two more of the small marks'],
      ),
    },
  ),
};
