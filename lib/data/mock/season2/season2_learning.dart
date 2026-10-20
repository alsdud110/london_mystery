import '../../models/learning.dart';

/// The language topic of each case of Season 2.
const Map<String, CaseLanguageTopic> season2LanguageTopics = {
  's2_ep01': CaseLanguageTopic(title: 'Time words: behind, forward, first and next', titleKo: '시간 표현: behind, forward와 순서어 first, next'),
};

/// The learning design of every mission of Season 2, by mission id (the
/// same rules as Season 1's, tested in `paris_case01_test.dart`): every
/// expression is on the mission's screens word for word, and only essential
/// missions claim more than exposure.
const Map<String, LearningObjective> season2Learning = {
  // ── Case 01 — The Ticking Watch ────────────────────────────────────────
  // The three clocks agree on nothing but the notice's rule: the times are
  // written, and "one hour behind" decides which one is wrong.
  's2_ep01_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '안내문의 "IF ONE CLOCK IS ONE HOUR BEHIND"를 이해하고, 10:00인 두 시계와 비교해 한 시간 늦은 9:00 시계를 찾는다.',
    expressions: ['one hour behind', 'REPORT IT TO THE LOST PROPERTY DESK'],
  ),
  // Only the order words put the shuffled cards in order.
  's2_ep01_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.grammarInContext,
    objective: '직원 기록의 순서어 FIRST, NEXT, AFTER THAT을 읽고 일어난 일을 순서대로 배열한다.',
    expressions: ['FIRST', 'NEXT', 'AFTER THAT'],
  ),
  // The carving says which way and how far: the hands are set from it.
  's2_ep01_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"MOVE ITS HANDS FORWARD ONE HOUR"를 이해하고 9:00에서 한 시간 앞으로 시계를 맞춘다(10:00).',
    expressions: ['MOVE ITS HANDS FORWARD ONE HOUR', 'TO MATCH THE HALL CLOCK'],
  ),
  // No picture on the lock: the four letters make a word only by knowing it.
  's2_ep01_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.vocabulary,
    objective: '모은 글자 T, I, M, E로 시계와 시계공을 잇는 단어 TIME을 만든다(ITEM 등 다른 단어와 구별).',
    expressions: ['LETTERS FOUND', 'hours and minutes'],
  ),
};
