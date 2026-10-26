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
  's2_ep04': CaseLanguageTopic(
    title: 'Following written clues: towards, moved, collected, and ruling out',
    titleKo: '글로 된 단서 따라가기: towards, moved, collected와 근거로 지우기',
  ),
  's2_ep05': CaseLanguageTopic(
    title: 'Two clues at once: the wrong way, added, and collected, sorted, held',
    titleKo: '두 조건 함께 읽기: the wrong way, added와 우편 기록 collected, sorted, held',
  ),
  's2_ep06': CaseLanguageTopic(
    title: 'Following directions: past, second, left, and letter or parcel',
    titleKo: '길 안내 따라가기: past, second, left와 LETTER/PARCEL 구분',
  ),
  's2_ep07': CaseLanguageTopic(
    title: 'Reading a record: times, above and under, and what was changed',
    titleKo: '기록 읽기: 시각, above와 under, 바뀐 것 찾기',
  ),
  's2_ep08': CaseLanguageTopic(
    title: 'Where things stand and what changed: between, above, first, then, same and missing',
    titleKo: '위치와 변화 읽기: between, above, first/then, same/missing',
  ),
  's2_ep09': CaseLanguageTopic(
    title: 'Joined or not: same, big and small, one hour back',
    titleKo: '이어졌나 아닌가: same, big/small, one hour back',
  ),
  's2_ep10': CaseLanguageTopic(
    title: 'Time words: after, behind, missing',
    titleKo: '시간 표현: after, behind, missing',
  ),
  's2_ep11': CaseLanguageTopic(
    title: 'True or not true? Right, wrong and the same',
    titleKo: '사실일까, 아닐까? right, wrong, the same',
  ),
  's2_ep12': CaseLanguageTopic(
    title: 'Who and why: the same, wrong, and the truth',
    titleKo: '누가, 왜: the same, wrong, the truth',
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
    objective: '안내문의 "If one clock is ONE HOUR BEHIND"를 이해하고, 10:00인 두 시계와 비교해 한 시간 늦은 9:00 시계를 찾는다.',
    expressions: ['one hour behind', 'report it to the LOST PROPERTY DESK'],
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
    objective: '"Move its hands FORWARD one hour"를 이해하고 9:00에서 한 시간 앞으로 시계를 맞춘다(10:00).',
    expressions: ['Move its hands FORWARD one hour', 'to match the hall clock'],
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
  // ── Case 04 — The River's Secret ───────────────────────────────────────
  // The plaque's three lines are the three checks: each wrong mark breaks
  // one of them, so only reading all three finds the mark.
  's2_ep04_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '황동판 뒷면의 세 문장을 조건으로 읽고(물결 세 개, 강 쪽을 가리키는 화살표, 물을 지켜보는 사람) 네 표식과 비교해 RIVER KEEPER 표식 D를 찾는다.',
    expressions: ['Three waves mark the place.', 'Follow the arrow towards the river.', 'Find the one who watches the water.'],
  ),
  // The ledger's words decide: from the Eiffel Tower, on Quay 3, and then
  // moved to another box.
  's2_ep04_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: '장부에서 에펠탑에서 온 짐 가운데 QUAY 3에 있는 것을 찾고, "Box 17 moved to Box 23"의 moved를 이해해 짐이 지금 있는 상자(Box 23)를 고른다.',
    expressions: ['The crate from the tower went to the river.', 'Where is the crate now?'],
  ),
  // A label is read from the top: FROM, CONTENTS, TO; the scrap that says
  // something else is left out.
  's2_ep04_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: '배송표의 FROM, CONTENTS, TO 순서를 이해해 찢어진 조각을 위에서 아래로 맞추고, 내용이 다른 종이 조각(TO: BOOKSTALL 12)을 구별한다.',
    expressions: ['Put the torn label back together.', 'Read where it was sent.'],
  ),
  // Very easy since 2026-10-27: two addresses, both a PASSAGE; the house
  // number (No. 7) decides, so it is exposure.
  's2_ep04_final': LearningObjective(
    dependency: LanguageDependency.exposure,
    level: LearningLevel.exposure,
    skill: LanguageSkill.sentenceMeaning,
    objective: '라벨의 CLUE 1: PASSAGE와 장부의 CLUE 2: No. 7을 읽고, PASSAGE DU PONT — No. 3과 PASSAGE DES HORLOGERS — No. 7 중 두 단서에 모두 맞는 주소를 고른다.',
    expressions: ['Find the address.', 'CLUE 2: No. 7'],
  ),
  // ── Case 05 — The Silent Workshop ──────────────────────────────────────
  // The note says what a copy is; the stamps are compared by their lines
  // under the sheet: a matching job more than an English one.
  's2_ep05_m1': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.sentenceMeaning,
    objective: '쪽지 "A copy is never the same."를 읽고, 투명 대조지를 겹쳐 바늘 끝 모양·짧은 바늘 위치·바늘 개수가 다른 사본 셋을 가려 진짜 서명(D)을 찾는다.',
    expressions: ['My mark is on everything I make.', 'A copy is never the same.'],
  ),
  // The card's two sentences are the two checks: one small wheel added (the
  // back), and the hands turn the wrong way (the times before and after).
  's2_ep05_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: '수리 카드의 "I added one small wheel."과 "Now its hands turn the wrong way."를 두 조건으로 읽고, 1분 뒤 시각과 시계 뒷면을 비교해 둘 다 맞는 Clock III를 찾는다.',
    expressions: ['I added one small wheel.', 'Now its hands turn the wrong way.'],
  ),
  // Very easy since 2026-10-27: the mirror's words and the notebook's line
  // share "turns back", so the key words are enough.
  's2_ep05_m3': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.sentenceMeaning,
    objective: '거울로 읽은 쪽지 "THE CLOCK THAT TURNS BACK."을 노트의 CLOCK II runs fast / CLOCK III turns back과 맞춰 Clock III를 고르고, 그 안의 영수증 LETTER No. 4417을 찾는다.',
    expressions: ['the clock that turns back', 'Which clock?'],
  ),
  // Very easy since 2026-10-27: 4417 is found among two numbers; its trail
  // (COLLECTED, SORTED, HELD at the Louvre post room) is then shown.
  's2_ep05_final': LearningObjective(
    dependency: LanguageDependency.exposure,
    level: LearningLevel.exposure,
    skill: LanguageSkill.sentenceMeaning,
    objective: 'LETTER 4471과 LETTER 4417 중 영수증의 편지 번호를 찾고, 이어서 9:00 AM — COLLECTED, 11:00 AM — SORTED, 4:00 PM — HELD(LOUVRE POST ROOM) 경로를 읽는다.',
    expressions: ['Find letter 4417.'],
  ),
  // ── Case 06 — The Letter That Never Arrived ────────────────────────────
  // The tags are read against the Letter's Trail: LETTER or PARCEL, the
  // number's digits, then (where ink hides one) the day and time on the back.
  's2_ep06_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '노트의 LETTER No. 4417 · 16 MAY · 4:00 PM과 꼬리표 앞뒤를 비교해, PARCEL과 LETTER를 구분하고 잉크로 가려진 번호는 뒷면의 날짜·시각으로 가려 Tag D를 찾는다.',
    expressions: ['LETTER No. 4417', 'Which tag is for Letter 4417?'],
  ),
  // Only the note's words lead to the door: past, second, on the left.
  's2_ep06_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: '쪽지의 "Walk past the statue."와 "Take the second door on the left."를 따라 평면도에서 편지를 한 걸음씩 옮기고, 조각상을 지난 뒤 왼쪽 두 번째 문(E)을 찾는다.',
    expressions: ['Walk past the statue.', 'Take the second door on the left.'],
  ),
  // The drawer is found by its numbers; the envelope by the torn edge.
  's2_ep06_m3': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.sentenceMeaning,
    objective: '서랍 라벨의 LETTERS와 번호 범위로 4417이 든 서랍을 열고, Case 05에서 찾은 찢긴 모서리를 대어 찢긴 가장자리가 맞는 봉투를 찾는다.',
    expressions: ['Find the envelope it was torn from.'],
  ),
  // The drawing alone can find it (statues on the roof); "the show" helps
  // decide between the buildings with a dome.
  's2_ep06_final': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.sentenceMeaning,
    objective: '편지 그림의 둥근 지붕·지붕 위 조각상을 지도의 건물과 비교하고, "But the show remembers."의 show(공연)로 공연장인 Palais Garnier를 찾는다.',
    expressions: ['But the show remembers.'],
  ),
  // ── Case 07 — The Phantom Performance ──────────────────────────────────
  // Very easy since 2026-10-27: FILE 3's DOORS OPEN · 3:30 PM decides
  // between 3:00 PM and 4:00 PM (the show starts after the doors open).
  's2_ep07_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: 'FILE 3의 DOORS OPEN · 3:30 PM과 "The show starts after the doors open."을 읽고, 3:00 PM과 4:00 PM 중 문이 열린 뒤인 4:00 PM을 고른다. 이어서 THE SHOW ENDED AT 6:10 PM과 FILE 3의 3:00 PM을 함께 본다.',
    expressions: ['DOORS OPEN · 3:30 PM', 'When did the show start?'],
  ),
  // Very easy since 2026-10-27: one switch, named GHOST LIGHT.
  's2_ep07_m2': LearningObjective(
    dependency: LanguageDependency.exposure,
    level: LearningLevel.exposure,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"Turn on the ghost light."를 읽고 GHOST LIGHT 스위치를 켠 뒤, 빈 무대(Only the ghost light: an empty stage, not a show.)와 Cue Card의 CUE 1 · CURTAIN UP · 4:00, 쪽지의 작은 시계와 빨간 문을 본다.',
    expressions: ['Turn on the ghost light.'],
  ),
  // The clue's two words decide: the door's colour, and what is right
  // above it (a small clock, not a lamp, not a tower far off).
  's2_ep07_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"Above the red door: a small clock."의 red door와 above(바로 위)를 두 조건으로 읽고, 램프·먼 시계탑·파란 문 배경막과 구별해 맞는 배경막을 찾는다.',
    expressions: ['Above the red door: a small clock.', 'look right above the door'],
  ),
  // Very easy since 2026-10-27: FILE 3 lit, the new time (on the patch)
  // told from the old (under it).
  's2_ep07_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: 'FILE 3을 찾아 라이트 테이블에 올리고 불을 켠 뒤, 덧붙인 종이 위의 3:00 PM(새 시각)과 그 아래 비치는 4:00 PM(원래 시각)을 구별해 "What is the new time?"에 답한다.',
    expressions: ['What is the new time?', 'Find FILE 3.'],
  ),
  // ── Case 08 — The Painter's Last Sketch ────────────────────────────────
  // The Hidden Sketch decides two ways: its picture (where the lamp
  // stands) and its words (the gate is black). The note names the things.
  's2_ep08_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: '메모의 "A gate between two pillars.", "The white church above."로 무엇을 찾을지 알고, Notebook의 Hidden Sketch 그림(가로등이 대문 왼쪽)과 문구 "The gate is black."로 세 모퉁이 중 하나를 고른다.',
    expressions: ['A gate between two pillars.', 'The white church above.'],
  ),
  // P.'s tag gives the rule; the drawings are put in order by it, then the
  // paper's coming is read against the bag's going.
  's2_ep08_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: 'P.의 꼬리표 "First, the sky was dark.", "When the sun came up, the lamps went out."을 규칙으로 그림 3장을 시간순으로 놓고, 겹쳐 비교해 종이가 가방이 지나간 뒤 나타났음을 추론한다.',
    expressions: ['First, the sky was dark.', 'When the sun came up, the lamps went out.'],
  ),
  // The two papers are read side by side: what is the same, what is
  // missing (FILE's number, the hour).
  's2_ep08_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '"What is the same as the opera slip? What is missing?"의 same과 missing을 구별해, 찢긴 종이에서 수정 슬립과 같은 양식·도장과 찢겨 없어진 FILE 번호·시각을 표시한다.',
    expressions: ['What is the same as the opera slip? What is missing?', 'I found this paper on the steps.'],
  ),
  // Two questions answered with evidence, then what can be said: no more
  // than the evidence shows.
  's2_ep08_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"Where did the paper come from?", "What kind of paper is it?"에 맞는 증거를 고르고, 증거가 말하는 만큼만 결론(종이 한 장이 가방에서 떨어졌다)을 고른다.',
    expressions: ['Where did the paper come from?', 'What kind of paper is it?'],
  ),
  // The little clocks put back by their shapes: the note says where each
  // belongs, the hint how to find it.
  's2_ep09_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"Put each clock back where it belongs."를 읽고 시계 모형 3개를 모양으로 지도의 제자리에 놓아, 시험 시계가 파리의 세 곳에만 있음을 알아낸다.',
    expressions: ['Put each clock back where it belongs.', 'Find the same shape on the map.'],
  ),
  // The board's words say what to do: join the tower to its clocks.
  's2_ep09_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '판의 글귀 "Join the tower to the trial clocks."를 읽고 크기가 맞는 톱니를 끼워, 탑이 이어진 시계만 움직이는 것을 관찰한다.',
    expressions: ['Join the tower to the trial clocks.'],
  ),
  // Two notebook marks found again on the old paper, each by its shape.
  's2_ep09_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: 'Notebook의 "A tiny carved gear.", "Signed with two clock hands."를 읽고 설계도와 수리 메모에서 같은 표식을 찾아 잇는다.',
    expressions: ['Find the same marks on the old paper.', 'Signed with two clock hands.'],
  ),
  // One hour back, tested; then no more than the test shows.
  's2_ep09_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"Set the tower one hour back."에 따라 탑을 4시에서 3시로 옮겨 시험하고, 결과가 보여 주는 만큼만 결론("Only the joined clocks went wrong.")을 고른다.',
    expressions: ['Set the tower one hour back.', 'Only the joined clocks went wrong.'],
  ),
  // The tape's rule read, then the two marks that break it.
  's2_ep10_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"Each one should be fifteen minutes after the last."를 읽고 테이프의 시각을 하나씩 따라가, 시간이 건너뛰는 두 곳(2:45 → 2:00, 2:45 → 4:00)을 찾는다.',
    expressions: ['Each one should be fifteen minutes after the last.', 'Where does the time jump?'],
  ),
  // Sorted by where each clock comes from, not by the time it shows.
  's2_ep10_m2': LearningObjective(
    dependency: LanguageDependency.exposure,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '"Is it a trial clock?"에 답하며 사진 속 시계를 Trial Map의 표식으로 나누고, 시험 시계가 아닌 시계들이 서로 같은 시각임을 확인한다.',
    expressions: ['Is it a trial clock?', 'The other clocks are not trial clocks.'],
  ),
  // The shadow made the same as the photo's: the sun's time read.
  's2_ep10_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"Make the same shadow as in the photo."를 읽고 해를 움직여 그림자의 방향과 길이를 사진과 맞추고, 해의 시각을 읽는다.',
    expressions: ['Make the same shadow as in the photo.'],
  ),
  // The two records laid together; then no more than they show.
  's2_ep10_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: '두 사진의 시각으로 테이프에서 Photo 2의 순간을 찾고 빠진 쪽을 확인한 뒤, 기록이 보여 주는 만큼만 결론("T1 was one hour behind, and the page about it is missing.")을 고른다.',
    expressions: ['Was the hour lost — or was the clock wrong?', 'T1 was one hour behind, and the page about it is missing.'],
  ),
  // ── Case 11 — The Unwritten Hour (very easy: one step at a time) ──────
  // The rubbed line says where page 3 is; the boxes' numbers say the same.
  's2_ep11_m1': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.sentenceMeaning,
    objective: '연필로 문질러 드러난 "Page 3 is in Box 9."를 읽고 9번 상자를 찾아 3쪽을 꺼낸다.',
    expressions: ['Page 3 is in Box 9.'],
  ),
  // Page 3's line against Victor's: only reading them answers.
  's2_ep11_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '3쪽("The clocks are wrong!")과 Victor의 서류("All the clocks were fine.")를 나란히 읽고 "Were the clocks right?"에 NO로 답한다. 이어서 두 도장이 같은지 본다.',
    expressions: ['Were the clocks right?'],
  ),
  // Two names matched by their shapes.
  's2_ep11_m3': LearningObjective(
    dependency: LanguageDependency.exposure,
    level: LearningLevel.exposure,
    skill: LanguageSkill.vocabulary,
    objective: '큰 장부에 눌린 서명과 방명록의 두 서명을 비교해 같은 서명(Victor)을 고른다. 영어는 장면을 설명한다.',
    expressions: ['Match the names.'],
  ),
  // Victor's three questions, each answered with the clue that fits.
  's2_ep11_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: 'Victor의 질문("What happened at three?" 등)을 읽고 두 증거 카드 중 맞는 것을 보여 주어 "Who hid the truth?"의 답에 이른다.',
    expressions: ['Who hid the truth?'],
  ),
  // ── Case 12 — The Clockmaker's Truth (very easy) ──────────────────────
  // The same wheel, by its spokes.
  's2_ep12_m1': LearningObjective(
    dependency: LanguageDependency.exposure,
    level: LearningLevel.exposure,
    skill: LanguageSkill.vocabulary,
    objective: 'Clock III의 바퀴와 바큇살 수가 같은 바퀴를 고르고, 이름표 "Made by Émile Moreau"를 읽는다.',
    expressions: ['Find the same wheel.'],
  ),
  // Three clues read, then who they point to.
  's2_ep12_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '바퀴·회중시계·톱니 표식 세 단서의 문장을 읽고 "Who is the Clockmaker?"에 답한다.',
    expressions: ['Who is the Clockmaker?'],
  ),
  // Stop, turn, fix, start: one word for each step.
  's2_ep12_m3': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.vocabulary,
    objective: 'Stop, turn, fix, start 네 단어를 따라 기계를 멈추고, 바퀴를 돌리고, 핀을 꽂고, 다시 켠다.',
    expressions: ['Fix the old machine.'],
  ),
  // Six questions, each with its clue: the whole season in short answers.
  's2_ep12_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: '여섯 개의 질문("Did Paris lose an hour?" 등)을 증거와 함께 읽고 두 답 중 하나를 골라 시즌의 진실을 정리한다.',
    expressions: ['Did Paris lose an hour?'],
  ),
};
