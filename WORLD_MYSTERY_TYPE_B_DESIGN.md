# World Mystery — TYPE B Design

> 상태: **설계 확정(Phase 1)**. 이 문서의 내용 중 무엇이 실제로 구현되었는지는 `WORLD_MYSTERY_TYPE_B_IMPLEMENTATION.md`가 기준이다.
> 근거 자료: 제품 감사(2026-10-12, 문서는 2026-10-28 정리 시 삭제 — git 이력 참조), `PROJECT_CONTEXT.md`, Case 01~12 데이터(`lib/data/mock/season1/`), HEAD `52f24c0` (감사 이후 소스 변경 없음 확인).

---

## 1. 제품 정의

**World Mystery는 TYPE B — Educational Detective Adventure다.**
아이는 런던의 탐정이 되어 사건을 해결하고, 그 과정에서 영어를 *읽고 → 증거로 삼고 → 추리하고 → 행동한다.*

> **English → Evidence → Deduction → Action**

| 지키는 것 (탐정 게임) | 더하는 것 (학습 설계) | 하지 않는 것 |
|---|---|---|
| 사건·스토리·연출·지도·아트 | 퍼즐마다 "결정적 영어"를 명시 | 퀴즈·단어장·학습 화면 추가 |
| 무벌점 오답, 무제한 재시도 | 오답 이유에 맞는 짧은 피드백 (대표 Case부터) | 감점·진행 차단 |
| 번역 선노출 금지 + Glossary | 힌트 = 영어 이해를 돕는 파트너 | 힌트 사용을 실패로 취급 |
| 추리 중심 Final, 사건 간 연결 | 이전 사건의 영어 표현 재사용 | 모든 퍼즐의 문법 문제화 |
| 부모 보고서 (게임 리포트 톤) | 측정된 사실만, 학습 목표와 성취 구분 | 측정하지 않은 능력 표시 |

### 1-1. 감사 기준선 재확인 (코드 대조)
- 퍼즐 50개(일반 38 + Final 12) — `episode01~12_mock.dart`에서 재확인.
- 감사의 E3/E2/E1·E0 = 5 / 29 / 16 분류는 "번역 시 퍼즐이 성립하는가" 축이다. 이 설계는 **"이 게임에서 영어 이해 없이 정답에 도달할 수 있는가"** 축(§2-2)으로 다시 분류한다. 두 축은 다르므로 수치도 다르다(§3 끝의 대조 참고).
- 기존 테스트 779개 통과 (감사 시 실행).

---

## 2. 학습 경험 모델

### 2-1. 설계 수준 (`LearningLevel`)
**이것은 미션이 *제공하도록 설계된* 경험의 수준이지, 아이의 영어 능력을 측정한 결과가 아니다.**

| 수준 | 정의 | 판정 기준 |
|---|---|---|
| **Exposure** | 영어를 접한다 | 영어가 화면에 있지만, 키워드·그림·기호·기억만으로도 정답에 도달 가능 |
| **Comprehension** | 영어 의미를 이해한다 | 문장의 의미를 이해해야 정답을 고를 수 있고, 오독하면 오답으로 이어진다 |
| **Application** | 이해한 영어를 활용한다 | 이해한 표현으로 무언가를 *한다*: 시각 계산, 방향 이동, 순서 배열, 문장 조립 |
| **Recall** | 이전에 접한 표현을 다시 사용한다 | 앞 미션·앞 사건의 영어 문장(편지·증거 글귀)을 다시 읽어야 정답에 도달 |

### 2-2. 영어 의존도 (`LanguageDependency`, Phase 3 분류와 동일)
| 등급 | 정의 |
|---|---|
| **essential** (영어 이해 필수) | 결정적 영어 구절을 이해하지 못하면 (찍기 외에는) 정답에 도달할 수 없다 |
| **helpful** (영어 이해가 추리에 유리) | 이해하면 빠르지만 키워드 일치, 그림 이름표, 이미 노출된 정답, 소거법으로도 도달 가능 |
| **exposure** (영어 노출 중심) | 영어는 맥락·분위기, 퍼즐은 다른 능력으로 해결 |
| **low** (언어 의존성 낮음) | 기호·QR·철자 해독 등 영어 이해와 거의 무관 |

**정직성 규칙 (테스트로 강제):** Comprehension / Application / Recall 수준은 **essential 미션에만** 기록할 수 있다. 그림 매칭·기호 매칭·노출된 정답은 Exposure로만 기록한다.

### 2-3. 미션 데이터 필드 — 필요한 것만

요청된 9개 후보 필드 중 **실제로 쓰이는 6개만** 구현한다.

| 후보 필드 | 결정 | 구현 이름 | 쓰이는 곳 |
|---|---|---|---|
| learningObjective | 구현 | `objective` (한국어 한 문장) | 부모 보고서 |
| languageSkill | 구현 | `skill` (vocabulary / sentence meaning / grammar in context, low는 없음) | 부모 보고서 |
| targetExpression + targetVocabulary | **통합** 구현 | `expressions` (화면에 실제로 있는 영어 원문) | 부모 보고서, 콘텐츠 테스트 |
| requiredComprehension | 구현 | `dependency` (§2-2) | 정직성 규칙, 부모 보고서 |
| (설계 수준) | 구현 | `level` (§2-1) | 부모 보고서 |
| priorLearningReference | 구현 | `recallFrom` (앞 미션 id) | 콘텐츠 테스트(원문 존재 확인), 부모 보고서 |
| reasoningSkill | **보류** | — | 추리 구조는 PROJECT_CONTEXT "핵심 Reasoning 구조"에 이미 문서화. 화면 사용처 없음 |
| evidenceUsage | **보류** | — | 같은 이유 (R0~R3 표) |
| feedbackStrategy | **Phase 3에서 결정** | (오답 보기별 `feedback`) | 대표 Case 승인 후 |

- 저장 위치: `lib/data/mock/season1/season1_learning.dart` (미션 id → 학습 목표, 사건 id → 언어 주제). `season1_discoveries.dart`와 같은 방식: **Case 콘텐츠 JSON은 건드리지 않는다**(사용자 승인 전 콘텐츠 수정 금지, 기존 콘텐츠 해시 테스트 보존).
- 모델: `lib/data/models/learning.dart`.
- **학습 목표 ≠ 성취.** 이 데이터는 저장 진행 데이터(`GameProgress`)에 들어가지 않는다. 부모 보고서는 "이 사건이 다룬 영어(설계)"와 "아이의 플레이 기록(측정)"을 분리해 보여 준다.

---

## 3. Season 1 학습 진행표

> "처음 접함 / 퍼즐에서 활용 / 이후 다시 등장"은 **콘텐츠에 실제로 있는 문장**만 적었다. "다시 등장"은 노출 사실이며 **학습 성취 확인이 아니다.**

| Case | 언어 주제 (확정) | 처음 접하는 표현 (예) | 퍼즐에서 활용 | 이후 다시 등장 | 영어 ↔ 추리 연결 | Final이 쓰는 요소 |
|---|---|---|---|---|---|---|
| 01 The Missing Crown | 런던 장소·사물 이름, 숫자 단어 | museum, mummies, palace, soldiers, FOUR / ONE / SEVEN | M1 박물관 내용 이해(개선 후), M2 뜻풀이, M3 숫자 단어 → 417, M4 묘사로 그림 선택(이름 없음) | "Signed: The Shadow / P.S. I love trains!"(Old Letter) → **11 Final** | 중간 (개선 후) | 기호 매칭 — 튜토리얼로 유지 |
| 02 The Silent Clock | 시각 표현, one hour after | hour hand, between eight and nine, not / smallest | M1 시각 읽기, M2 부정문, M3 "The hour is the gallery" | raven stamp → 12-M1, 시간 계산 → 09-M3, 12-M2 | **강함** | "One hour after the clock stops"(M3) **Recall** → 9:17 |
| 03 The Vanishing Painting | 색·상태 묘사, 정도 표현 | red coat, blue scarf, very wet / a little wet / almost dry | M2 두 조건 결합, M3 정도 순서 | "From a coat"(Red Button) → **08 Final**, north → 07·10·11 | 강함 | "Take me north" + "smells of trains"(M3 증거) **Recall** |
| 04 The Secret Letter | 편지 읽기: 비유 표현, 단어 조합 | where trains never sleep, open day and night, a small red clock | M1 비유 이해 | "a small red clock" → **12-M2**, "never sleeps" → 11-M2 장면 | 중간 | seal 글귀 (정답이 시즌 내내 노출 → Exposure) |
| 05 The Locked Room | 방향·순서 지시문 | turn left, the third floor, on the right, the other way, the same way | M1 위치, M2 L/R 순서, M3 "six… and one more" | left/right/turn → 07, 서수 → 09-M3 | **강함** | 뚜껑 질문 순서로 단서 맞추기 **Recall** (개선 후, 그림 없음) |
| 06 The Midnight Detective | 인물 묘사, 증언 비교 | carried, agree, tall / short, different | M1 carried vs wore, M3 차이 세기 | agree → 11-M1 | 강함 | 묘사 매칭 (서사적으로 정답 두드러짐 → Exposure) |
| 07 The Lost Map | 위치 전치사 | past, beside, behind, not on, above, below, at the top | 4개 미션 전부 | (재사용 없음 — **공백**) | **강함** | "turn left" + Joined Map "An arrow goes north" **Recall** |
| 08 Platform 9 | 질문·대답, 진술 확인 | Where are you going?, travelling alone, forty-two, never | M1 질문 선택(화용), M2 alone vs "My dad and I" | — | 강함 | Mrs Robin의 진술 + Case 03 "From a coat" **Recall** |
| 09 The Missing Jewel | 소유 표현 's, whose | the guard's key, whose, every two hours, third change | M1 's, M3 시간 계산 | (재사용 없음 — **공백**) | **강함** | "the one whose key you used" **Recall** (M1) |
| 10 The London Raven | 요일, 순서, 문장 구성 | smallest, gold ring, Monday~Thursday, WHO / WILL / WHAT / WHEN | M2 요일 순서 | north (03·07) | 강함 | 문장 조립 **Application** |
| 11 The Masked Stranger | 증언 비교, 과거 단서 다시 읽기 | does not agree, backwards, two big arches | M1 비교 | — | 중간 | Case 01 Old Letter 서명 **Recall** |
| 12 The Midnight Case | 시즌 표현 통합 | real / fake, eight teeth, ARRIVALS, arrives, riddle | M1 속성 소거, M2 시간표 + Case 04 **Recall** | (PARIS — Season 2) | 중간 | 문에 새긴 질문 순서로 단서 맞추기 **Recall** (개선 후, 그림 없음) |

### 3-1. 학습 난이도 ≠ 추리 난이도
| 축 | 현재 | 설계 원칙 |
|---|---|---|
| 추리 난이도 | 사건이 진행될수록 증가 (사건 간 Recall, Archive 활용) | 유지 |
| 언어 난이도 | Case 01~12 평균 문장 길이 4.5~6.0 단어로 평평 (감사 §6) | **"긴 문장"이 아니라 "의미 단위"로 성장**: 단어 → 한 문장의 의미 → 두 문장 결합(부정·비교) → 이전 표현 재사용 → 문장 구성. 문장 길이를 인위적으로 늘리지 않는다 |
| 연령 조절 | 없음 | 출시 후(P2) — 플레이테스트 근거가 생기면 결정 |

### 3-2. 의존도 분포 (이 설계 축 기준, `season1_learning.dart` 실제 값)
| 의존도 | P0 시점 (콘텐츠 변경 전) | 대표 Case 개선 후 (현재) | 수준 분포 |
|---|---|---|---|
| essential | 32 | **37** (+01-M1·M2·M4, 05-F, 12-F) | Comprehension / Application / Recall |
| helpful | 13 | **10** | Exposure |
| low | 5 | **3** (01-M5 QR, 01-F 기호 — 튜토리얼로 유지, 11-M2 역순 철자) | Exposure |
| exposure | 0 | 0 | (현재 Season 1에는 이 유형으로 분류할 퍼즐 없음) |

> 현재 값(Season 1 전체 개선 + Wave 1 03-M1 탐색 후): essential **42** / helpful **5** / low **3** (`learning_objectives_test`).

> 감사 축(번역 시 성립 여부)으로는 E3 5 / E2 29 / E0·E1 16이었다. 감사의 E2 대부분(오독 시 오답)이 여기서는 essential이고, 감사의 E1 다수가 helpful이다. 01-M3(대문자 숫자 단어)는 감사 E3 → 여기 essential, 09-M2(알파벳)는 감사 E0 → 여기 helpful(지시문 이해 필요)로, 두 축의 판단이 다르다.

---

## 4. 퍼즐 설계 원칙 (새 퍼즐·개정 시)

1. **결정적 구절 하나.** 모든 essential 퍼즐은 "이 구절을 오독하면 틀린다"가 성립하는 영어 구절을 하나 이상 가진다(`expressions`).
2. **포장 금지.** 영어 없이 풀리는 퍼즐을 긴 영어 문장으로 감싸 essential로 만들지 않는다. low/helpful 퍼즐도 분위기·관찰·보상에 필요하면 유지한다.
3. **정답 노출 금지 범위 확장.** 미션 제목, 같은 사건의 이전 장면, 그림 이름표도 정답을 말하지 않는다(감사 P1-4 — 콘텐츠 변경이므로 승인 후).
4. **오답 보기 = 오독 유형.** 선택지 오답은 아이가 할 법한 오독을 하나씩 대표한다(Case 02 M3 모델).
5. **Final은 앞의 영어를 다시 읽게 한다.** 기호 매칭 Final(01·05·12)은 Case 01(튜토리얼)을 제외하고 개선 후보.
6. **언어 재사용은 퍼즐에서.** 같은 단어가 장면에 다시 나오는 것은 재사용이 아니다. 앞의 표현을 *다시 해석해야* 풀리는 경우만 Recall로 기록한다.

---

## 5. 보상 / 피드백 원칙

### 5-1. XP

> **대체됨 (2026-10-12, XP 규칙 3):** 아래 규칙 2 표는 당시 설계 기록이다. 후속 감사에서 "첫 시도 보너스"가 운 좋은 찍기와 이해를 구분하지 못하고, 한 번 오독했다가 정정한 아이(125)를 운 좋게 찍은 아이(150)보다 덜 보상한다는 것이 확인되었다. 현재 원칙: **정답에 도달하면 누구나 같은 XP**(일반 100 / Final 200), 오답·힌트·시간 무관. 추가 보상은 XP가 아닌 **탐정 행동 배지**(§5-2-1)로만, 기록된 UI 이벤트에만 준다.

| 원칙 | 규칙 (XP 규칙 v2) |
|---|---|
| 정답에 도달한 모든 아이에게 같은 기본 XP | 일반 100 / Final 200 — 힌트·오답·시간 무관 |
| 힌트는 실패가 아니다 | **힌트는 XP를 깎지 않는다** |
| 찍기가 이득이 되지 않는다 | **Careful Answer 보너스**: 첫 시도 정답 +50, 두 번째 시도 +25, 그 이후 0. 힌트를 다 보고 첫 시도에 맞혀도 +50 → "모르면 찍지 말고 다시 읽고 팁을 보라"가 최적 전략 |
| 서두름을 보상하지 않는다 | 속도 보너스 폐지 (읽는 시간을 처벌하지 않음) |
| 오답 없음 ≠ 영어 실력 | Careful Answer는 *신중하게 답한 탐정 행동*에 대한 게임 보상이며, 부모 보고서에서 영어 능력으로 표시하지 않는다 |
| 소급 변경 금지 | XP는 저장값이 아니라 매번 계산된다. 따라서 **미션마다 어떤 규칙으로 풀었는지(`xpRules`)를 정답 순간 기록**하고, 기록이 없는 미션(기존 세이브)은 기존 규칙 v1으로 계산한다 → 기존 진행분의 XP는 바뀌지 않는다 |
| 재플레이 중복 방지 | 사건 XP·배지는 사건별 저장 하나에만 존재(시즌 누적 XP 없음). Play again은 그 사건 기록을 대체하므로 누적되지 않는다 — 테스트로 고정 |

### 5-2. 배지 의미 점검

> **갱신 (XP 규칙 3):** Sharp Eyes·Quick Thinker는 **신규 지급 중단(retired)**. 이미 받은 세이브에서만 보이고, 설명은 과거 두 조건 모두에 맞게 "이전 버전에서 …받은 배지"로 바꿨다. 아래 표는 규칙 2 당시 기록이다.

| 배지 | 기존 조건 | 문제 | v2 조건 / 설명 |
|---|---|---|---|
| First Clue | 단서 1개 | 없음 | 유지 |
| Sharp Eyes | 힌트 없이 미션 해결 | 찍어도 획득, 힌트를 실패로 취급 | **첫 시도에 해결**(힌트 사용 무관). "단서를 꼼꼼히 보고 첫 시도에 해결" |
| Quick Thinker | 2분 내 해결 | 빠른 찍기 보상 | **첫 시도에, 빠르게**. "빠르고 정확하게 해결" |
| Puzzle Solver / London Explorer / Master Detective | 진행 | 없음 | 유지 |
| Letter Reader (Case 04) | 사건 완료 | 이름·설명("비밀 편지 해독")이 읽기 능력을 암시 | 조건 유지(사건 완료), 설명을 **"비밀 편지 사건 해결"**로 — 능력이 아니라 사건 |
| 그 외 사건 배지 | 사건 완료 | 설명이 사건을 가리킴 | 유지 |

이미 획득해 저장된 배지(`badgeIds`)는 그대로 둔다(새 조건은 앞으로의 획득에만 적용).

#### 5-2-1. 탐정 행동 배지 (XP 규칙 3과 함께 도입)
| 배지 | 조건 (실제 UI 이벤트) | 하지 않는 것 |
|---|---|---|
| Second Look | 미션에서 오답 → 해결 전에 편지 다시 읽기(Letter) 또는 수첩·Case Archive·Final 수첩에서 증거 열기 → 같은 미션 정답 | 오답만으로, 오답 시트를 닫은 것만으로, 오답 전·해결 후의 확인으로는 지급 안 함 |
| Notebook Explorer | 사건 해결 중에 수첩·Case Archive·Final 수첩에서 증거 하나를 자세히 열어 봄 | 수첩에 들어가기만 한 것, 사건 해결 후의 열람 |
| Word Collector | 이번 실행에서 서로 다른 단어 3개의 뜻을 봄 | 같은 단어 반복, 기록 이전 세이브의 단어 |

- 모두 **XP 없음, 사건당 1회, 사건 진행 조건 아님.** 영어 능력이 아니라 탐정 행동을 표현한다.
- 기록이 없는 옛 세이브(`behavior` 키 없음)는 그 실행에서 행동 배지를 받지 않는다(추정 소급 금지). Play again부터 기록.
- 남은 위험: Second Look은 조건에 "오답"이 들어가므로 일부러 틀리는 행동을 유도할 수 있다. 완화: 설명에 "틀리면"을 쓰지 않고("막혔을 때"), XP가 없고, 사건당 1회. 플레이테스트로 확인한다.

### 5-3. 피드백 (Phase 3 — 승인 후)
- 오답 피드백: 핵심 퍼즐의 오답 보기에 **한 줄** 진단(정답 비공개, 다시 생각할 지점). 없으면 기존 "Not quite!" fallback.
- Hint 1 = 무엇을 살펴볼지, Hint 2 = 결정적 영어 표현의 의미 또는 추론 관계. 이해하기 어렵게 만들지 않는다.
- 힌트 안내 문구에서 "보너스 XP 소모" 표현을 제거한다(P0에서 처리 — 규칙이 바뀌므로).

---

## 6. Parent Report 원칙

| 표시해도 되는 것 (측정됨) | 표시하지 않는 것 |
|---|---|
| 해결한 미션·사건, 플레이 시간 | 영어 능력 별점 (오답·힌트에서 유도한 것 포함) |
| 사용한 힌트 수, 첫 시도에 해결한 미션 수 (플레이 기록으로 명시) | "읽기 능력이 돋보였다", "핵심 단어를 잘 활용했다" 류 단정 |
| **실제로 찾아본 단어 목록** (`lookedUpWords`) | 모든 미션을 Reading으로 일괄 평가 |
| 이 사건의 언어 주제·다룬 영어 표현 (**학습 목표로 표기**) | 학습 목표를 성취처럼 표기 |
| 퍼즐 유형, 미션별 "영어가 한 역할"(의존도) | |

**기록 없음 처리:** 저장에 근거가 없는 항목은 0이나 "한 번에 해결"로 표시하지 않는다.
- 단어 찾기 기록이 없던 세이브 → "기록 없음"
- 시도 기록(`attempts`)이 없는 해결 미션(예: 플레이테스트 도구로 "해결" 처리된 사건, v1 세이브) → 그 미션은 "기록 없음", 첫 시도 수에서 제외
- 플레이 시간을 알 수 없는 세이브 → "기록 없음"

**톤:** 게임 리포트 톤 유지. 칭찬은 *관찰된 행동*에만 ("힌트를 활용해 끝까지 해결했어요" ○ / "어휘력이 뛰어나요" ✗).

---

## 7. 학습 연속성 설계 (Phase 4 — 설계만, 구현은 승인 후 결정)

### Notebook
- 정체성: 탐정의 기록물. 단어장 탭을 만들지 않는다.
- 후보 (새 화면 없이): Clue `note`에 결정적 영어 구절을 남기는 작성 규칙(04-M1 "The platforms never sleep"이 모델). Evidence 글귀는 이미 원문 단서.
- "찾아본 단어"는 부모 보고서에 먼저 표시(P0). 아이 Notebook 노출은 플레이테스트 후 결정.

### Cross-Case Learning (후보, 모두 콘텐츠 변경 → 승인 필요)
| From → To | 언어 요소 | 현재 | 제안 |
|---|---|---|---|
| 02 → 12 | 시각·"one hour after" | 12-M2는 시간표 읽기만 | 12-M2/Final에서 "before midnight / … minutes after" 해석 요구 |
| 07 → 12 | 위치 전치사 | 재사용 없음 | 12-F 자물쇠 질문 또는 12-M3 장소를 전치사로 지시 |
| 09 → 12 | whose | 재사용 없음 | 12 Final 질문 한 개를 whose 구조로 |
| 04 → 12 | "a small red clock" | **이미 R3** | 유지 |
| 03 → 08, 01 → 11 | 증거 글귀 | **이미 R3** | 유지 |

같은 단어의 재등장만으로 성취를 기록하지 않는다.
