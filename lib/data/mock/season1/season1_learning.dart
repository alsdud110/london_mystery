import '../../models/learning.dart';
import '../../models/mission.dart';

/// What [m] is designed to do with English, or null when it has no entry.
LearningObjective? learningOf(Mission m) => season1Learning[m.id];

/// The language topic of a case, or null when it has none.
CaseLanguageTopic? languageTopicOf(String episodeId) => season1LanguageTopics[episodeId];

/// The language topic of each case of Season 1 (see
/// LONDON_MYSTERY_TYPE_B_DESIGN.md §3).
const Map<String, CaseLanguageTopic> season1LanguageTopics = {
  'ep01': CaseLanguageTopic(title: 'Places, objects and number words', titleKo: '런던의 장소·사물 이름과 숫자 단어'),
  'ep02': CaseLanguageTopic(title: 'Telling the time: "one hour after"', titleKo: '시각 표현과 "~한 시간 뒤"'),
  'ep03': CaseLanguageTopic(title: 'Describing things: colours and how wet', titleKo: '색깔·상태 묘사와 정도 표현'),
  'ep04': CaseLanguageTopic(title: 'Reading letters: phrases and word clues', titleKo: '편지 읽기: 비유 표현과 단어 조합'),
  'ep05': CaseLanguageTopic(title: 'Directions and instructions', titleKo: '방향과 순서 지시문'),
  'ep06': CaseLanguageTopic(title: 'Describing people, comparing witnesses', titleKo: '인물 묘사와 증언 비교'),
  'ep07': CaseLanguageTopic(title: 'Where things are: prepositions of place', titleKo: '위치 전치사와 공간 관계'),
  'ep08': CaseLanguageTopic(title: 'Questions, answers and statements', titleKo: '질문·대답과 진술 확인'),
  'ep09': CaseLanguageTopic(title: "Whose is it? 's and whose", titleKo: "소유 표현('s, whose)"),
  'ep10': CaseLanguageTopic(title: 'Days, order and building a sentence', titleKo: '요일·순서와 문장 구성'),
  'ep11': CaseLanguageTopic(title: 'Comparing stories, reading old clues again', titleKo: '증언 비교와 이전 단서 다시 읽기'),
  'ep12': CaseLanguageTopic(title: "Using the season's English together", titleKo: '시즌에서 만난 영어 함께 쓰기'),
};

/// The learning design of every mission of Season 1, by mission id.
///
/// Rules (tested in `learning_objectives_test.dart`):
/// - every expression is on the mission's screens word for word (or, with
///   [LearningObjective.recallFrom], in that earlier mission's text, clue or
///   evidence): nothing the child never sees is listed;
/// - only [LanguageDependency.essential] missions are given more than
///   [LearningLevel.exposure]: a picture, a symbol or an answer the case
///   already showed is not recorded as understanding English.
const Map<String, LearningObjective> season1Learning = {
  // ── Case 01 — The Missing Crown ─────────────────────────────────────
  'm01': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '편지의 "old mummies from Egypt and a famous stone"을 이해하고, 공룡·기차·로켓이 아닌 박물관을 고른다. 보기에는 편지와 같은 단어가 없다.',
    expressions: ['old mummies from Egypt', 'a famous stone'],
  ),
  'm02': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '뜻풀이(a hard piece of rock)나 첫 편지의 "a famous stone"으로 단어를 떠올려 쓴다.',
    expressions: ['a hard piece of rock', 'a famous stone'],
    recallFrom: 'm01',
  ),
  // The scene's three clues are drawn as well as written, so the notes help
  // but the picture alone can decide it: helpful, exposure.
  'm03': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.vocabulary,
    objective: '현장에서 찾은 단서 메모(footprints, lamp, scratches)를 읽고 세 단서가 가리키는 숨긴 장소를 고른다.',
    expressions: ['The footprints stop at the tower wall', 'The lamp shines on one stone', 'fresh scratches'],
  ),
  'm04': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '그림에 이름이 없다. 편지의 묘사(a big palace, a red flag, a fountain)를 읽고 그림을 고른다.',
    expressions: ['a big palace', 'There is a fountain in front'],
  ),
  'm05': LearningObjective(
    dependency: LanguageDependency.low,
    level: LearningLevel.exposure,
    objective: '현장의 QR 카드를 찾는 미션. 영어 이해와는 거의 관계가 없다.',
  ),
  'final': LearningObjective(
    dependency: LanguageDependency.low,
    level: LearningLevel.exposure,
    objective: '자물쇠 그림과 수첩 단서의 그림을 맞추는 미션. 편지를 읽지 않아도 풀린다.',
  ),

  // ── Case 02 — The Silent Clock ──────────────────────────────────────
  'ep02_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '시계 바늘을 설명한 영어 문장을 읽고 멈춘 시각(8:17)을 알아낸다.',
    expressions: ['The hour hand was between eight and nine', 'two more small marks'],
  ),
  'ep02_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.grammarInContext,
    objective: '부정문(not)과 긍정문을 구분해 톱니바퀴가 있는 곳을 찾는다.',
    expressions: ['It is not under the biggest bell', 'It is under the smallest bell'],
  ),
  'ep02_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"시는 전시실, 분은 그림"이라는 규칙을 앞에서 찾은 시각에 적용한다.',
    expressions: ['The hour is the gallery. The minutes are the picture.'],
    recallFrom: 'ep02_m1',
  ),
  'ep02_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.grammarInContext,
    objective: '앞 미션 계획서의 "one hour after"를 다시 읽고 시각을 계산한다(8:17 → 9:17).',
    expressions: ['One hour after the clock stops'],
    recallFrom: 'ep02_m3',
  ),

  // ── Case 03 — The Vanishing Painting ────────────────────────────────
  // Played as a search of Gallery 8 (`season1_investigations.dart`): each
  // place word is acted on in the picture (under ≠ on the bench).
  'ep03_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.grammarInContext,
    objective: '보고서의 위치 표현(under / on / next to)을 읽고, 그 자리를 갤러리에서 직접 조사해 세 물건을 찾는다.',
    expressions: ['It is under the bench', 'It is on the frame', 'It is next to the door'],
  ),
  'ep03_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '옷차림 묘사(색깔 + 옷)를 두 조건으로 비교해 범인을 찾는다.',
    expressions: ['Miss Rose wore a red coat and a blue scarf'],
    recallFrom: 'ep03_m1',
  ),
  'ep03_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.grammarInContext,
    objective: '정도 표현(very wet → almost dry)으로 발자국의 순서를 정한다.',
    expressions: ['very wet', 'a little wet', 'almost dry', 'Wet shoes get drier with every step'],
  ),
  'ep03_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.sentenceMeaning,
    objective: '택시 기사의 말과 앞에서 찾은 증거 글귀(기차 냄새)를 함께 읽어 장소를 정한다.',
    expressions: ['Take me north', 'a tall clock tower', 'The boot smells of trains and smoke'],
    recallFrom: 'ep03_m3',
  ),

  // ── Case 04 — The Secret Letter ─────────────────────────────────────
  'ep04_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '비유 표현 "never sleep"을 "밤낮으로 열려 있다"로 이해한다.',
    expressions: ['Meet me where trains never sleep', 'open day and night'],
  ),
  'ep04_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '보기는 승강장 번호뿐이다. 짐꾼의 네 문장을 끝까지 읽고 RED·FOUR·CLOCK을 모두 맞는 곳을 찾는다("a red door, but no clock"은 시계가 아니다).',
    expressions: ['Platform 4 has a small red clock', 'Platform 7 has a red door, but no clock'],
  ),
  'ep04_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '그림에 이름이 없다. 편지의 묘사(an old castle by the river, four towers, black birds)를 읽고 그림을 고른다.',
    expressions: ['an old castle by the river', 'It has four towers and thick stone walls', 'Black birds live there'],
  ),
  'ep04_final': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.vocabulary,
    objective: '봉인 글귀를 다시 읽고 모임의 이름을 쓴다. 정답 단어가 앞 사건들에서 여러 번 나온다.',
    expressions: ['We are named after a bird', 'It is pressed into every seal we send'],
    recallFrom: 'ep04_m1',
  ),

  // ── Case 05 — The Locked Room ───────────────────────────────────────
  'ep05_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '길 안내 지시문(왼쪽·층·오른쪽)을 읽고 방의 위치를 고른다.',
    expressions: ['Turn left at the old cannon', 'Go up the stairs to the third floor', 'The door is on the right'],
  ),
  'ep05_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.grammarInContext,
    objective: '"the other way", "the same way as"를 이해하고 다이얼을 실제로 돌린다.',
    expressions: ['Next, turn it the other way', 'the same way as the first time'],
  ),
  'ep05_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"six ravens … and one more"를 읽고 까마귀 수를 알아낸다.',
    expressions: ['there are always six ravens here', 'and one more, just in case'],
  ),
  'ep05_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.sentenceMeaning,
    objective: '자물쇠에 그림이 없다. 뚜껑의 질문 세 개를 읽고, 수첩의 단서(찾은 순서와 다름)를 질문 순서대로 맞춘다.',
    expressions: ['The first lock: how many ravens live at the Tower?', 'what time do the gates close?'],
    recallFrom: 'ep05_m1',
  ),

  // ── Case 06 — The Midnight Detective ────────────────────────────────
  'ep06_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '"carried"(들고 있던 것)와 입은 것을 구분하고, 두 증언이 일치하는 것을 찾는다.',
    expressions: ['He carried a small bag', 'Two witnesses agree'],
  ),
  'ep06_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.sentenceMeaning,
    objective: '카드 뒷면의 "the colour of my hat"을 이해하고, 카드를 떨어뜨린 사람의 모자 색을 앞 증언에서 다시 찾는다(수수께끼 "rain clouds"가 두 번째 길).',
    expressions: ['It is the colour of my hat', 'rain clouds and old stones', 'He had a grey hat'],
    recallFrom: 'ep06_m1',
  ),
  'ep06_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '두 날의 인물 묘사(tall/short, man/woman …)를 비교해 다른 점을 센다.',
    expressions: ['A tall man', 'A short woman', 'How many are different?'],
  ),
  'ep06_final': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.sentenceMeaning,
    objective: '인물 묘사를 앞의 기록과 맞춘다. 보기 중 이야기상 두드러지는 인물이 하나라 묘사 없이도 고를 수 있다.',
    expressions: ['A tall man', 'He carries a small bag'],
    recallFrom: 'ep06_m3',
  ),

  // ── Case 07 — The Lost Map ──────────────────────────────────────────
  'ep07_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.grammarInContext,
    objective: '길 안내(past, turn right, beside)를 따라 지도에서 위치를 찾는다.',
    expressions: ['Go past the tree', 'Turn right at the bridge', 'Look beside the bench'],
  ),
  'ep07_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.grammarInContext,
    objective: '부정문(not on)과 위치 전치사(under, behind)를 함께 읽고 상자의 위치를 고른다.',
    expressions: ['The box is not on the shelf', 'It is under the table', 'behind the green watering can'],
  ),
  'ep07_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.grammarInContext,
    objective: 'top / bottom / above / below를 이해하고 지도 조각을 실제로 배열한다.',
    expressions: [
      'The station piece goes at the top',
      'The river piece goes at the bottom',
      'above the river',
      'below the station',
    ],
  ),
  'ep07_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.sentenceMeaning,
    objective: '새 길 안내와 앞에서 맞춘 지도의 화살표 글귀를 함께 읽어 멈출 곳을 정한다.',
    expressions: ['Cross the bridge and turn left', 'An arrow goes north'],
    recallFrom: 'ep07_m3',
  ),

  // ── Case 08 — The Mystery on Platform 9 ─────────────────────────────
  'ep08_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '이름표에 남은 정보를 확인할 수 있는 질문을 고른다(질문의 쓰임 이해).',
    expressions: ['Where are you going?', 'TO: Edinburgh'],
  ),
  'ep08_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"travelling alone"과 "My dad and I"를 구분해 혼자 가는 승객을 찾는다.',
    expressions: ['I am travelling alone', 'My dad and I are going to Edinburgh'],
    recallFrom: 'ep08_m1',
  ),
  'ep08_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '숫자 단어(forty-two)와 "the hour of my train"을 읽고 번호를 만든다.',
    expressions: ['Seat: forty-two', 'then the hour of my train'],
  ),
  'ep08_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.sentenceMeaning,
    objective: '용의자의 부정 진술을 읽고, Case 03 증거 글귀("From a coat")를 다시 찾아 반박한다.',
    expressions: ['I was never in Gallery 8', 'You cannot prove it', 'From a coat'],
    recallFrom: 'ep03_m1',
  ),

  // ── Case 09 — The Missing Jewel ─────────────────────────────────────
  'ep09_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.grammarInContext,
    objective: "소유 표현('s)을 이해하고 열쇠의 주인을 찾는다.",
    expressions: ["The guard's key is big and gold", 'The jewel case opens only with a big gold key'],
  ),
  'ep09_m2': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.vocabulary,
    objective: '이름의 글자 설명을 읽고 이름을 쓴다. 알파벳 순서 퍼즐에 가깝다.',
    expressions: ['It starts with A, and it ends with A', 'the letter after M'],
  ),
  'ep09_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"every two hours", "the third change"를 읽고 시각을 계산한다.',
    expressions: ['The guards change every two hours', 'Anna was seen at the third change'],
  ),
  'ep09_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.grammarInContext,
    objective: '"whose key"(누구의 열쇠인가)와 "누가 썼는가"를 구분하고, 앞 미션의 열쇠 주인을 다시 확인한다.',
    expressions: ['the one whose key you used'],
    recallFrom: 'ep09_m1',
  ),

  // ── Case 10 — The London Raven ──────────────────────────────────────
  'ep10_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '까마귀 묘사(smallest, quiet, gold ring)를 세 조건으로 맞춘다.',
    expressions: ['Poppy is the smallest', 'Your raven is small, quiet and has a gold ring'],
  ),
  'ep10_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.vocabulary,
    objective: '요일 단어를 이해하고 쪽지를 월요일부터 순서대로 놓는다.',
    expressions: ['On Monday, the word was NORTH', 'On Tuesday: TOWER'],
  ),
  'ep10_m3': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.vocabulary,
    objective: '두 단어를 합쳐 장소 이름을 만든다(그림 이름이 퍼즐 자체). TOWER 하나만 맞는 이름이 함정이라 두 단어를 모두 확인해야 하지만, 단어 맞춰 보기 수준이다.',
    expressions: ['Two of them, put together, are the name of a place in London'],
    recallFrom: 'ep10_m2',
  ),
  'ep10_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.grammarInContext,
    objective: '누가(WHO) → 무엇을 할지(WILL) → 무엇에(WHAT) → 언제(WHEN) 순서로 영어 문장을 조립한다.',
    expressions: ['First: WHO?', 'what WILL they do?', 'Then: to WHAT?', 'Last: WHEN?'],
  ),

  // ── Case 11 — The Masked Stranger ───────────────────────────────────
  'ep11_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '세 증언을 비교해 다른 하나("does not agree")를 찾는다.',
    expressions: ['One witness does not agree with the other two', 'The mask was gold'],
  ),
  'ep11_m2': LearningObjective(
    dependency: LanguageDependency.low,
    level: LearningLevel.exposure,
    objective: '거꾸로 쓴 글자를 바로 읽는 철자 해독. 영어 의미 이해와는 거의 관계가 없다.',
    expressions: ['Read me from right to left'],
  ),
  'ep11_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.vocabulary,
    objective: '그림에 이름이 없다. 경비원의 "the station that never sleeps"를 Case 04의 "where trains never sleep"과 연결하고, 택시 기사의 묘사(two big arches, a clock tower)로 고른다. 시계탑만 있는 그림이 함정이다.',
    expressions: ['the station that never sleeps', 'two big arches and a clock tower', 'Meet me where trains never sleep'],
    recallFrom: 'ep04_m1',
  ),
  'ep11_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"the very start"가 첫 사건임을 이해하고, Case 01 편지의 서명을 다시 찾아 읽는다.',
    expressions: ['We met at the very start', 'I left you a letter in a suitcase', 'Signed: The Shadow'],
    recallFrom: 'm01',
  ),

  // ── Case 12 — The Midnight Case ─────────────────────────────────────
  'ep12_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: '세 가지 조건(금속·톱니 수·도장)을 읽고 맞지 않는 보기를 지워 진짜를 찾는다.',
    expressions: ['The real gear is brass', 'It has eight teeth'],
    recallFrom: 'ep02_m2',
  ),
  'ep12_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.sentenceMeaning,
    objective: '도착 시간표를 읽고, Case 04의 "small red clock"으로 승강장을, Case 02에서 쓴 "after"로 그 승강장의 두 열차 중 하나를 정한다.',
    expressions: [
      'always arrives on the platform with the small red clock',
      'after the train from Edinburgh',
      'Platform 4 has a small red clock',
    ],
    recallFrom: 'ep04_m2',
  ),
  'ep12_m3': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.vocabulary,
    objective: '시계를 사람처럼 묘사한 수수께끼(hands, face)를 푼다. 정답 장소가 같은 사건 앞에서 이미 나온다.',
    expressions: ['I have hands, but I cannot clap', 'I have a face, but I cannot smile'],
  ),
  'ep12_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.grammarInContext,
    objective: '자물쇠에 그림이 없다. 문에 새겨진 질문 세 개를 순서대로 읽고 오늘 밤의 단서를 맞춘다. 첫 질문은 Case 09의 whose 구조("the platform whose clock is small and red")로 읽는다.',
    expressions: [
      'the platform whose clock is small and red',
      'how many teeth on the real gear?',
      'how many ravens guard the Tower?',
    ],
    recallFrom: 'ep12_m2',
  ),
};
