import '../../models/learning.dart';

/// The language topic of each case of Season 2.
const Map<String, CaseLanguageTopic> season2LanguageTopics = {
  's2_ep01': CaseLanguageTopic(title: 'Time words: behind, forward, first and next', titleKo: '시간 표현: behind, forward와 순서어 first, next'),
  's2_ep02': CaseLanguageTopic(
    title: 'Where and when: above, beside, missing, before and after',
    titleKo: '위치와 때: above, beside, missing, before, after',
  ),
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

  // ── Case 02 — The Vanishing Painter ────────────────────────────────────
  // The note says where each change is: without ABOVE, MISSING and BESIDE
  // the two pictures are searched blind.
  's2_ep02_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '화가의 메모 "Look above the red door", "the window that is missing", "the lamp beside the steps"를 읽고 실제 거리와 그림의 차이 세 곳을 찾는다.',
    expressions: ['Look above the red door', 'Find the window that is missing', 'Check the lamp beside the steps'],
  ),
  // The paintings carry no word: only BEFORE, AFTER and WHEN, read against
  // their sky and stones, join each note to its painting.
  's2_ep02_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.grammarInContext,
    objective: '메모의 BEFORE THE RAIN, AFTER THE RAIN STOPPED, WHEN THE SKY TURNED GOLD를 이해하고 하늘과 돌바닥 모습으로 각 그림과 연결한다.',
    expressions: ['BEFORE THE RAIN', 'AFTER THE RAIN STOPPED', 'WHEN THE SKY TURNED GOLD'],
  ),
  // The note says what to do, and the one thing a pencil cannot show.
  's2_ep02_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"Slide the paint away and look UNDERNEATH"를 이해하고 덧칠을 밀어 밑그림의 lamp, steps, gate를 찾는다. "the gate is black"을 기억한다.',
    expressions: ['Slide the paint away', 'look UNDERNEATH', 'the gate is black'],
  ),
  // Three clues, read together: no one of them finds the canvas alone.
  's2_ep02_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: '세 단서(빨간 문이 아닌 곳, 파란 하늘, 계단 옆 검은 문)를 모두 읽고 네 캔버스 중 셋을 모두 만족하는 하나를 고른다.',
    expressions: ['Not the street with the red door', 'One canvas matches all three'],
  ),
};
