import '../../models/learning.dart';

/// The language topic of each case of Season 2.
const Map<String, CaseLanguageTopic> season2LanguageTopics = {
  's2_ep01': CaseLanguageTopic(title: 'Time words: behind, forward, first and next', titleKo: '시간 표현: behind, forward와 순서어 first, next'),
  's2_ep02': CaseLanguageTopic(
    title: 'Where and when: above, beside, missing, before and after',
    titleKo: '위치와 때: above, beside, missing, before, after',
  ),
  's2_ep03': CaseLanguageTopic(
    title: 'Reading records: times, routes and first, next, finally',
    titleKo: '기록 읽기: 시각, 노선, 순서어 first, next, finally',
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

  // ── Case 03 — The Tower's Secret ───────────────────────────────────────
  // The records are read line by line: only their words say which line is
  // which, and that the date and the job agree.
  's2_ep03_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '두 기록(VISITOR NOTICE, MAINTENANCE LOG)의 DATE, JOB, TIME을 한 줄씩 비교해 서로 다른 시각(4:00 PM, 3:00 PM)을 찾는다.',
    expressions: ['The same day. The same job.', 'Find the two lines that do not match'],
  ),
  // The log alone has no answer: S is read on the route plate (SERVICE
  // RUN), and only the service route has the stop.
  's2_ep03_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: '운행 기록의 S 표시를 노선판의 "S = SERVICE RUN"과 연결하고, 일반 노선(passenger route)에 없는 정차 구역 SERVICE LEVEL을 찾는다.',
    expressions: ['One stop is not written', 'S = SERVICE RUN'],
  ),
  // The order words alone set the dials.
  's2_ep03_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.grammarInContext,
    objective: '점검 메모의 순서어 First, Next, Finally를 읽고 세 다이얼을 CLOCK, LIFT, KEY 순서로 맞춘다.',
    expressions: ['First, check the clock.', 'Next, stop the lift.', 'Finally, turn the key.'],
  ),
  // Each question is read for what it asks, and only what the evidence
  // shows is concluded.
  's2_ep03_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: '세 질문(무엇이 잘못됐나, 승강기는 어디로 갔나, 누가 들어갔다는 근거는)을 읽고 증거를 연결한 뒤, 증거로 증명할 수 있는 결론만 고른다.',
    expressions: ['What was wrong with the inspection records?', 'What can we conclude?'],
  ),
};
