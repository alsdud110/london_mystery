# LONDON MYSTERY — Product Vision & Learning Experience Audit

> 감사일: 2026-10-12 · 대상: `main` (HEAD `52f24c0`) · 방식: **READ-ONLY** (앱 소스·콘텐츠·저장 데이터·PROJECT_CONTEXT.md 변경 없음)
> 기준선 확인: `flutter test` → **779 passed** (이번 감사에서 실행). `flutter analyze`는 실행하지 않음(PROJECT_CONTEXT 기재값 0 issues 인용).
> 실제 어린이 플레이테스트 기록: **없음** (`docs/playtest/`에는 체크리스트 양식만 있고 결과가 없음). 따라서 연령 적합성·사용자 반응에 대한 모든 판단은 **전문가 추정**이다.

### 표기 규칙
- **[기획]** 문서·주석에 적힌 의도 · **[구현]** 코드/데이터에서 확인한 사실 · **[무효]** 구현은 되었으나 사용자 경험에서 실제로 작동하지 않음 · **[추정]** 근거 기반 추론 · **[근거 없음]** 문서·코드 어디에서도 확인되지 않음
- 이 감사의 "초기 기획"은 **두 가지**다. ① 감사 요청서가 제시한 제품 정의(영어 = 목표이자 수단, TYPE B 지향) ② 저장소 문서의 기획(`PROJECT_CONTEXT.md`: "일반적인 영어 학습 앱이 아니다. 영어는 게임을 진행하는 도구다"). 둘은 같지 않으며, 그 차이 자체가 이번 감사의 핵심 발견 중 하나다.

---

## 1. Executive Summary

**한 문장 결론.** London Mystery는 지금 **"영어 독해가 관문 역할을 하는, 잘 만든 탐정 어드벤처"(TYPE C)** 이다. 추리 사슬, 사건 간 연결, 연출은 출시 수준에 가깝다. 반면 **영어 학습은 "설계된 경험"이 아니라 "노출되는 매체"**에 머물러 있다. 학습 목표는 코드 주석에만 숨어 있고, 측정되지 않으며, 부모 보고서는 측정하지 않은 능력을 측정한 것처럼 보여 준다.

핵심 질문에 대한 답:

> 현재 London Mystery는 **영어 문장이 포함된 탐정 게임**과 **게임을 진행하다 보니 영어를 사용하는 경험**의 중간에 있다. **영어를 배우기 위해 플레이하는 게임은 아니다.**

근거 요약 (모두 본문에서 상세):

| 발견 | 근거 |
|---|---|
| 50개 퍼즐 중 **영어 형태 자체가 퍼즐의 핵심인 것은 5개**(10%). 29개는 영어 독해가 필요하지만 **한국어로 번역해도 똑같이 작동**하는 논리 퍼즐, 16개는 키워드/그림/기호 매칭만으로 풀린다 | §5 퍼즐 전수표 |
| 퍼즐 약 30개(60%)가 **몇 번의 찍기로 반드시 풀린다**(선택형 25개는 최대 3번 오답). 오답은 XP에 영향이 없고 힌트는 XP를 깎는다 → **보상 구조가 "찍기"를 "힌트 읽기"보다 우대한다** | `scoring.dart` `XpBreakdown.of`, `game_controller.dart:173` |
| 오답 피드백은 50개 퍼즐 모두 **같은 문장 하나**("Not quite! Good detectives look again."). Case 02 M3처럼 오답 보기를 "아이가 할 법한 오독"으로 정교하게 설계해 놓고도, 어떤 오독을 했는지 알려 주지 않는다 | `answer_feedback.dart:312-352` |
| Case 01→12 **문장 길이 평균이 4.5~6.0 단어로 평평하다**. 언어 난이도 성장은 설계되지 않았다. 증가하는 것은 추리 의존성(사건 간 연결)뿐이다 | §6 텍스트 통계 |
| Case별 언어 테마(시간, 묘사, 방향, 소유격 whose, 문장 구성 …)가 **데이터 파일 머리 주석에만 존재**한다. 아이·부모·시스템 어디에도 노출되거나 측정되지 않는다 | `episode02~12_mock.dart` 헤더 주석, `keyWords` |
| 부모 보고서의 "English Skills" 별점은 **오답·힌트 횟수만으로 계산**되며 최저 2점이 보장된다. 50개 미션 전부에 `reading` 태그가 붙어 있다. "핵심 단어를 잘 알아보고 활용했어요" 같은 문장은 **측정 근거 없이** 출력된다 | `detective_report.dart:47-65, 142-170` |

**판정(§16 상세): 지금 그대로 출시 → `NO`.** 아이 쪽(탐정 게임의 재미)은 가능성이 높지만 검증되지 않았고, 부모 쪽(영어 교육 앱으로서의 가치)은 현재 보고서가 사실보다 크게 말하고 있어 신뢰를 잃을 위험이 있다. 다만 차이는 좁다. **P0 3건은 대부분 데이터·문구 수준의 작은 수정**이며, 이후 플레이테스트로 `CONDITIONAL YES`에 도달할 수 있다.

---

## 2. 현재 제품의 실제 정체성

### 2-1. 판정: TYPE C — Detective Adventure with English Puzzles (일부 Case는 TYPE B 수준)

| 유형 | 해당 여부 | 근거 |
|---|---|---|
| A. English Learning App with Game Elements | 아니오 | 학습 목표·진도·복습·평가 구조 없음. 학습 화면 없음 |
| **B. Educational Detective Adventure** | **부분적** (Case 02·05·07·09·10의 일부 미션) | 영어 표현의 정확한 이해가 추리 결과를 바꾸는 퍼즐이 존재 (02 "one hour after", 05 "the other way", 07 전치사, 09 "whose", 10 문장 어순) |
| **C. Detective Adventure with English Puzzles** | **가장 가까움** | 사건·추리·연출이 중심. 영어는 모든 텍스트의 매체이자 퍼즐 관문이지만, 대부분의 퍼즐은 언어와 무관한 논리를 영어로 "포장"한 것 |
| D. Story-Driven Detective Game | 아니오 | 모든 진행이 영어 텍스트 독해를 통과해야 하며, 퍼즐이 진행을 실제로 막는다 |

### 2-2. 지향 유형과의 관계
- **요청서의 초기 정의** → TYPE B 지향. 현재 구현과 **불일치**.
- **저장소 문서(PROJECT_CONTEXT)** → "영어 학습 앱이 아니다, 영어는 도구" — B와 C 사이, 실질적으로 **C에 가깝게 쓰여 있다**. 현재 구현과 **대체로 일치**.
- 즉 **구현이 기획에서 이탈한 것이 아니라, 기획 문서 자체가 어느 시점에 B에서 C 쪽으로 이동했다.** 이동 시점·결정 기록은 **[근거 없음]** (git 커밋 메시지·문서에 결정 기록이 없음).

---

## 3. 초기 기획 대비 일치도

### 3-1. 점수 기준 (0~5)
| 점수 | 의미 |
|---|---|
| 0 | 구현 없음 / 근거 없음 |
| 1 | 형식적으로만 존재 (데이터·라벨은 있으나 경험에서 작동하지 않음) |
| 2 | 부분 구현, 일관성 없음, 핵심 약점이 경험을 지배 |
| 3 | 의도대로 작동하나 뚜렷한 약점 존재 |
| 4 | 대체로 의도를 충족, 개선 여지 소폭 |
| 5 | 의도를 완전히 충족하고 **실사용 데이터로 검증됨** (→ 플레이테스트가 없으므로 이번 감사에서 5점은 없음) |

### 3-2. 비교표 (기준: 요청서의 초기 제품 정의)

| 항목 | 초기 의도 | 현재 구현 | 점수 | 근거 | 문제점 |
|---|---|---|---|---|---|
| 제품 정체성 | 탐정이 되어 영어를 도구로 사용하는 교육 게임 | 탐정 어드벤처. 영어는 매체이자 관문 | **3** | §2, PROJECT_CONTEXT "제품 철학" | 교육 정체성이 문서·화면 어디에도 정의되지 않음. 부모 보고서만 교육을 주장 |
| 영어 학습 | 영어 = 목표이자 수단, 새 표현과 사고 능력 사용 | 노출 + 독해 관문. Glossary 탭 뜻 보기 | **2** | §5, §6 | 학습 목표 비명시, 언어 형태 의존 퍼즐 10%, 학습 확인 없음 |
| 추리 경험 | 관찰·이해·추론·증거 활용 | Final 의존 사슬, 사건 간 R3 연결 3개, 정교한 오답 보기 | **4** | PROJECT_CONTEXT "핵심 Reasoning 구조", `case02/09_reasoning_test` | 기호 매칭으로 풀리는 Final 3개(01·05·12), 찍기 가능 |
| 스토리 몰입 | 사건 → 런던 탐험 → 다음 사건 | 12사건 연속 서사, Raven Society 아크, PARIS 훅, Investigation Board | **4** | `episode*_mock.dart` intro/transition, `investigation_board.dart` | 미션당 탭 ~7회·대기 ~14초(PROJECT_CONTEXT P2) |
| 난이도 성장 | Case가 진행될수록 새 영어와 사고 능력 | 추리 의존성은 증가, **언어 난이도는 평평** | **1** | §6 텍스트 통계 | 문장 길이·구문 복잡도 성장 없음, 연령 조절 없음 |
| 학습 피드백 | 왜 그 답인지 이해 | Discovery 한 줄이 일부 "왜"를 말함. 오답 피드백은 단일 문구 | **1** | `answer_feedback.dart:347-352`, `season1_discoveries.dart` | 오독 진단 없음, 해결 후 이해 확인 없음 |
| 보상 시스템 | 학습·추리 성취 보상 | XP(기본+노힌트+속도), 공통 배지 6 + 사건 배지 6 | **2** | `scoring.dart` | 찍기 > 힌트 인센티브, 언어 성취와 무관, 공통 배지 사건마다 반복(~70회) |
| 부모 관점 가치 | 아이가 무엇을 배웠는지 이해 | 사건별 보고서: 별점·정답률·힌트·찾아본 단어 수 | **1** | `detective_report.dart`, `parent_report_screen.dart` | 측정하지 않은 능력을 측정한 것처럼 표기 (§10) |
| 반복 플레이 | (암묵) 다시 해도 가치 | Play again = 같은 정답·같은 보기 순서 | **1** | `question_widgets.dart:188-221`(셔플 없음), `GameProgress.resetCase` | 정답 암기만 남음. 난이도 선택 없음 |

**평균 2.1 / 5.** 게임 축(정체성·추리·스토리) 평균 3.7, 학습 축(학습·성장·피드백·부모·반복) 평균 1.2. **두 축이 극명하게 갈린다.**

---

## 4. 현재 아키텍처 및 플레이 흐름

### 4-1. 학습 관련 데이터 구조 (실제 구현)

| 요소 | 위치 | 실제 사용처 | 판정 |
|---|---|---|---|
| `glossary` (사건당 26~44단어, 한국어 뜻) | `episode*_mock.dart` → `Episode.meaningOf` | 스토리·편지·질문 문장에 점선 밑줄 → 탭 시 뜻 카드 (`glossary_text.dart`) | **[구현] 작동.** 단, 보기(선택지) 문구·힌트 문구에는 적용 안 됨 |
| `lookedUpWords` | `GameProgress`, `game_controller.dart:165` | 부모 보고서 "찾아본 단어 N개" **개수만** 표시 | **[무효]** 어떤 단어인지 아무도 볼 수 없음 |
| `skills` (vocabulary/reading/problemSolving) | `Mission.skills`, `mission.dart:23` | 부모 보고서 별점 계산 | **[무효]** 태그 기준 없음, 50/50 미션이 `reading` (§10) |
| `keyWords` (Case 02~12, 3개씩) | `Episode.keyWords` | 부모 코멘트 한 문장에 끼워 넣기만 함 (`detective_report.dart:139,153`) | **[무효]** 게임 내 노출·측정 없음. Case 01은 하드코딩 폴백 |
| 사건별 언어 테마 | 각 `episodeNN_mock.dart` 헤더 주석 | 없음 | **[기획만 존재]** |
| `caseSummary` | `Episode.caseSummary` | Case Closed 화면 인용문 | [구현] 서사 요약. 학습 요약 아님 |
| `hook` | `Episode.hook` | **어디에도 표시 안 됨** (`case_solved_screen.dart:136` 주석) | 데드 데이터 (문제 아님, 기록용) |
| 난이도/연령 설정 | — | — | **[근거 없음]** PROJECT_CONTEXT "Proposed(미승인): TTS/난이도" |
| 듣기(TTS/음성) | — | 효과음만 (`audio_service.dart`) | **구현 안 됨** |

### 4-2. 실제 플레이 흐름과 단계별 평가

```
Title → Register → Season Cover → Opening(5장면) → Story Intro → Map
  → [미션 ×3~5] GO(줌 1.4s) → 장소(INVESTIGATE) → 봉투(TAP TO OPEN) → 편지(SOLVE THE PUZZLE) → Puzzle
       → 오답: Not quite! 시트(TRY AGAIN / GET A TIP)
       → 정답: Discovery Moment(2.2s) → CONTINUE → Story Scene(타자기) → TO THE MAP → 해금 연출
  → Final(편지·퍼즐·OPEN MY NOTEBOOK) → solve reveal(2.4s) → Post-Case → Case Closed → (Parent Gate → Parent Report)
  → Investigation Board → 다음 사건
```

| 단계 | 플레이어 행동 | 학습 발생 | 추리 발생 | 연출/대기 | 몰입 강화 | 흐름 단절 |
|---|---|---|---|---|---|---|
| Story Intro / 장소 | 읽기(탭 진행) | **노출**(glossary 가능) | — | 타자기 | 강 (장면 artwork) | — |
| 봉투 → 편지 | 탭, 읽기 | **핵심 독해 지점** | 정보 수집 | 봉투 850ms | 강 (물리적 문서) | 약 |
| Puzzle | 선택/입력 | 독해 적용 (퍼즐 유형에 따라 0~강) | **주 추리 지점** | — | 중 | — |
| 오답 시트 | TRY AGAIN | **없음** (일반 문구) | 없음 | — | 약 | 중 (모든 오답에 같은 시트) |
| Discovery | 보기 | 약 (일부 detail이 "왜"를 말함) | 결과 확인 | 2.2s | 강 | 약 |
| Story Scene | 읽기 | 노출 | 다음 단서 예고 | 타자기 ~7s | 강 | 중 (미션당 누적) |
| Map 왕복 | GO 탭 | 없음 | 없음 | 줌·이동·해금 ~4.4s | 중 | **중~강** (단일 랜드마크 사건에서 반복) |
| Final | Notebook/Archive 조회 + 입력 | 증거 글귀 재독해 | **최강** (사건 간 연결) | reveal 2.4s | 강 | — |
| Case Closed / Board | 보기 | 없음 | — | 2.8s+0.9s | 강 | 약 |

**관찰:** 학습이 일어나는 지점은 "편지 → 퍼즐" 구간 하나뿐이고, 그 앞뒤로 연출·대기 구간이 미션당 약 14초 붙는다. 연출 투자 대비 학습 피드백 투자가 0에 가깝다(§8).

---

## 5. Season 1 학습 설계 전수조사

### 5-1. 학습 목표의 존재 여부

- **명시된 학습 목표: [근거 없음].** 사건·미션 단위 학습 목표 필드, 문서화된 커리큘럼, 학습 성취 기준은 존재하지 않는다.
- **코드 주석에서 추론 가능한 언어 테마** (설계 의도의 흔적이지 설계된 목표로 간주하지 않음):

| Case | 헤더 주석의 테마 | `keyWords` | 추론한 언어 초점 **[추정]** |
|---|---|---|---|
| 01 | (없음) | (없음 → 폴백 museum, stone, palace) | 장소 어휘, 숫자 단어 |
| 02 | Theme: time | minute, before, after | 아날로그 시각 표현, "one hour after" |
| 03 | Theme: descriptions | button, cloth, footprint | 색·위치 묘사, 정도 표현 (very wet / almost dry), 비교급 |
| 04 | Theme: reading letters | platform, letter, seal | 관용 표현("never sleep"), 다중 조건 결합 |
| 05 | Theme: directions, commands | left, right, turn | 명령문, 서수(third floor), "the other way / the same way" |
| 06 | Theme: people and clothes | coat, hat, carried | carried vs wore, agree / different |
| 07 | Theme: directions and places | past, beside, behind | 전치사 (past, beside, behind, in front of, above, below) |
| 08 | Theme: questions and answers | where, alone, ticket | 의문문의 기능 선택(화용), "alone" vs "my dad and I" |
| 09 | Theme: possession, logic | whose, belongs, has | 소유격 's, **whose ≠ who had it** |
| 10 | Theme: words, order, hidden message | Monday, north, message | 요일, 합성 고유명사, **문장 어순(WHO/WILL/WHAT/WHEN)** |
| 11 | Theme: comparing descriptions | mask, cloak, backwards | 증언 비교, 역순 철자 |
| 12 | 시즌 피날레 | midnight, arrives, riddle | 수수께끼(다의어 hands/face), 시간표 읽기 |

> 이 표는 **잠재적으로 꽤 좋은 "문법·기능 in context" 커리큘럼**이다. 문제는 이것이 ① 아이에게 드러나지 않고 ② 이후 사건에서 재사용되지 않으며 ③ 난이도가 오르지 않고 ④ 측정되지 않는다는 것이다.

### 5-2. 퍼즐 50개 전수표 (일반 38 + Final 12)

**영어 의존도 등급**
- **E3** 영어 형태 자체가 퍼즐 (번역하면 퍼즐이 성립하지 않거나 성격이 바뀜)
- **E2** 영어 문장 이해가 필수 — 단, 한국어로 번역해도 동일하게 작동하는 논리 퍼즐
- **E1** 키워드·그림·이름표 매칭으로 해결 (단어 1~2개 인식으로 충분)
- **E0** 영어 불필요 (기호·물리·순수 논리)

**TEST B** 찍기 최대 오답 수(무벌점) · **TEST C** Hint 2 이후 남는 작업 · **TEST D** 영어를 잘못 읽으면 실제로 틀린 답에 도달하도록 설계됐는가 · **TEST E** 이 정보가 이후 추리에 실제 쓰이는가(PROJECT_CONTEXT R0~R3)

| ID | 형식 | 핵심 영어 | 영역 | 의존 | B 찍기 | C Hint 2 후 | D 오독→오답 | E 재사용 | 비고 |
|---|---|---|---|---|---|---|---|---|---|
| 01-M1 | MC | "a very big museum" | 어휘 | E1 | ≤3 | "museum, B로 시작" → 유일 보기 | 약 | Old Letter→11 **R3** | 보기 중 museum은 하나뿐 |
| 01-M2 | Word | "hard piece of rock" | 어휘 | E1* | 불가 | `S _ _ _ E` | 약 | R0 | **정답 노출**: 미션 제목 "The Famous Stone", 장면 "a big grey stone" (§13 P1-4) |
| 01-M3 | Code | FOUR/ONE/SEVEN 대문자 | 숫자 단어 | E3 | 불가 | 사실상 정답 | 중 | 7 → Final | 대문자 강조로 독해 불필요 |
| 01-M4 | Image | palace, soldiers, red coats | 묘사 | E1 | ≤3 | 그림 매칭 | 약 | 2 → Final | **그림 아래 이름표 "Buckingham Palace" 표시** |
| 01-M5 | QR | — | (말하기 힌트) | E0 | — | 진행자에게 영어로 묻기 | — | 기호 카드 | 시즌 유일의 **말하기** 요소 |
| 01-F | Code | — | — | **E0** | 불가 | 기호 매칭 | 없음 | R3(사건 내) | 자물쇠 기호 = Clue 카드 기호 (§5-3) |
| 02-M1 | Code | hour hand between eight and nine… two more small marks | 독해+시계 | E2 | 불가 | 8 + 15+2 계산만 | **강** | 8:17 → M3·F **R3** | 시계 읽기 능력과 영어가 섞임 |
| 02-M2 | MC | not under the biggest / under the smallest | 부정문 | E2 | ≤3 | 반의어 | 중 | 기어→12 R2 | 정답 보기가 편지 문장과 글자 그대로 일치 |
| 02-M3 | MC | the hour is the gallery, the minutes are the picture | 독해 | E2 | ≤3 | 대응만 | **강** (오답 3개가 각각 오독 유형) | → F | **오답 보기 설계 최우수 / 오답 피드백은 일반 문구** |
| 02-F | Code | one hour after the clock stops | 시간 표현 | E2 | 불가 | 9:17 계산 | **강** | — | 시즌 최고 수준 |
| 03-M1 | MC | next to the door | 위치 | E1 | ≤3 | "door가 있는 줄" | 약 | Red Button→08 **R3** | 키워드 매칭 |
| 03-M2 | MC(3) | red coat, blue scarf; button ← coat | 묘사 | E2 | ≤2 | Notebook 조회 | 중 | → 08 | 두 조건 결합 |
| 03-M3 | Seq | very wet / wet / a little wet / almost dry | 정도 표현 | E2 | 24순열 | 순서 대응 | **강** | — | 좋은 언어 퍼즐 |
| 03-F | Image | north, clock tower + "smells of trains" | 독해+증거 | E2 | ≤3 | 증거 재확인 | 강 | 사건 내 R3 | 이름표 표시. 데이터 주석·glossary의 "arches"는 편지에서 사라진 흔적 |
| 04-M1 | MC | where trains never sleep | 관용 표현 | E2 | ≤3 | "밤에도 여는 곳" | 중 | — | 비유 이해 |
| 04-M2 | MC | RED · FOUR · CLOCK · PLATFORM | 조건 결합 | E1 | ≤3 | 대응 | 중 | Platform 4→12 **R3** | |
| 04-M3 | Image | castle, four towers, black birds | 묘사 | E1 | ≤3 | "탑 개수 세기"(시각) | 약 | — | 이름표 "Tower of London" 표시 |
| 04-F | Word | named after a bird… lives at the Tower | 어휘 | E1 | 불가 | Notebook 봉인 | 약 | — | **RAVEN이 Case 02~03·시즌 보드에서 이미 반복 노출** |
| 05-M1 | MC | turn left, third floor, on the right | 명령문·서수 | E2 | ≤3 | 마지막 두 줄 | **강** | 5 → F | |
| 05-M2 | Seq(L/R) | the other way, the same way as | 지시어 | E2 | 16조합 | 거의 정답 | **강** | — | 좋은 언어 퍼즐 |
| 05-M3 | Word | six ravens… and one more | 수 | E2 | 불가 | 6+1 | 약 | 7 → F, 12 R2 | "숫자 단어로 쓰라"지만 `7`도 정답 처리 |
| 05-F | Code | 질문 3개 | — | **E0** | 불가 | 기호 매칭 | 없음 | 사건 내 | 주석은 "순서를 바꿔 읽게 함"이라 하나 기호가 같아 편지 불필요 |
| 06-M1 | MC | agree; carried vs wore | 동사 의미 | E2 | ≤3 | "두 명이 말한 것" | **강** | 작은 가방 → F | |
| 06-M2 | Word | colour of rain clouds | 어휘 | E2 | 불가 | "4글자, 흑백 사이" | 약 | → F | "grey hat"이 M1 편지·전환 장면에 이미 등장 |
| 06-M3 | Code(1자리) | tall/short, man/woman… | 비교 | E2 | **≤9** | 세기 | 중 | ticket→10·11 R1 | |
| 06-F | MC | tall man, small bag | 묘사 결합 | E1 | ≤3 | Notebook 카드 | 중 | — | 보기 중 서사적으로 두드러지는 인물이 하나 |
| 07-M1 | Image | go past, turn right, beside | 전치사·방향 | E2 | ≤3 | 갈림길 방향 | **강** | — | 지도 이름 숨김(유일) |
| 07-M2 | MC | not on the shelf; behind vs in front of | 전치사·부정 | E2 | ≤3 | 반의어 | **강** | — | |
| 07-M3 | Seq | top / bottom / above / below | 전치사 | E2 | **6순열** | 거의 정답 | 중 | Joined Map → F | |
| 07-F | Image | turn left + 지도 화살표 | 방향 | E2 | ≤3 | Notebook | **강** | 사건 내 R3 | |
| 08-M1 | MC | 어떤 질문이 도움이 되나 | **화용** | E2 | ≤3 | "도시를 확인" | 중 | — | 시즌에서 가장 "언어 사용"에 가까운 퍼즐 |
| 08-M2 | Word | alone vs "My dad and I" | 독해 추론 | E2 | 사실상 2명 | "혼자 가는 사람" | **강** | → F | |
| 08-M3 | Code | seat forty-two, the 9:30 | 숫자 단어 | E2 | 불가 | 순서 | 중 | — | |
| 08-F | MC | I was never in Gallery 8 / prove | 증거 논증 | E2 | ≤3 | Archive 4탭 경로 | 중 | Case 03 **R3** | M2 전환 장면이 "red coat and a blue scarf"를 다시 말해 줌 |
| 09-M1 | MC | the maid's / the guard's key | **소유격** | E3 | ≤3 | 대응 | 강 | → F | |
| 09-M2 | Word | letter after M | 알파벳 | E0 | 불가 | 정답 | 없음 | — | 영어 이해 불요(알파벳 순서) |
| 09-M3 | Code | every two hours, third change | 시간+산수 | E2 | 불가 | 세기 | 중 | — | |
| 09-F | Word | **whose key you used** | **문법(whose)** | E3 | 3개 물건 | 소유자 확인 | **최강** | M1 **R3** | 시즌 최고의 문법-추리 결합 |
| 10-M1 | MC | small, quiet, gold ring | 속성 결합 | E2 | ≤3 | 대응 | 중 | — | |
| 10-M2 | Seq | Monday~Thursday | 요일 어휘 | E2 | 24순열 | 순서 | 중 | → M3 | |
| 10-M3 | Image | TOWER + BRIDGE | 합성 | E1 | ≤3 | 대응 | 약 | — | **이름표 "Tower Bridge"와 단어가 글자 그대로 일치** |
| 10-F | Seq | WHO / WILL do / to WHAT / WHEN | **문장 구성** | E3 | 24순열 | 2순열 남음 | 강 | — | 시즌 유일의 구문 조립 |
| 11-M1 | MC(3) | does not agree | 비교 | E2 | ≤2 | 같은 둘 찾기 | 중 | — | |
| 11-M2 | Word | THGINDIM (역순) | 철자 해독 | E1 | 불가 | 첫 글자들 제공 | 없음 | — | MIDNIGHT는 Case 05·10에서 이미 반복 |
| 11-M3 | Image | north, big station, arches | 묘사 | E1 | ≤3 | 아치 찾기 | 약 | — | 직전 장면이 "the station that never sleeps"로 답을 말함 |
| 11-F | MC | We met at the very start… I still love trains | 독해+회상 | E2 | ≤3 | Archive 서명 | 중 | Case 01 **R3** | 소거로도 접근 가능(PROJECT_CONTEXT도 인정) |
| 12-M1 | MC | brass, eight teeth, raven stamp | 속성 소거 | E2 | ≤3 | 소거법 | 중 | 8 → F | |
| 12-M2 | Code | ARRIVALS 시간표 + "small red clock" | 실생활 텍스트 | E2 | **화면의 4개 시각 중 하나** | Archive Case 04 | 중 | Case 04 **R3** | 진짜 문서 유형(시간표) 읽기 |
| 12-M3 | Word | hands/face/ring 수수께끼 | 다의어 | E3 | 불가 | Case 02 언급 | 약 | — | **같은 사건 M1 장소명·장면이 "Big Ben"** |
| 12-F | Code | 질문 3개 | — | **E0** | 불가 | 기호 매칭 | 없음 | 사건 내 | 피날레가 "기호 맞추기" |

### 5-3. 사고 실험 결과 (TEST A~E)

**TEST A — 영어 제거(한국어 번역) 테스트**
- E3 **5개**(01-M3, 09-M1, 09-F, 10-F, 12-M3)만 번역 시 퍼즐이 깨지거나 성격이 바뀐다.
- E2 **29개**는 한국어로 바꿔도 **똑같이 작동**한다 → 이 퍼즐들의 학습 가치는 "영어로 된 지시를 읽어 낸다"는 **독해 관문**이지, 영어를 배우게 하는 구조는 아니다.
- E0/E1 **16개**는 영어 이해 없이 풀린다.
- **결론: 영어는 대부분 "포장"이다.** 이는 C 유형의 정의와 일치한다. (E2 퍼즐이 나쁘다는 뜻이 아니다. 아이가 실제로 영어 문장을 끝까지 읽고 정보를 뽑아내야 하므로 독해 연습으로는 유효하다.)

**TEST B — 무작위 정답 테스트**
- MC 18 + 그림 선택 7 = **25개는 최대 3회(보기 3개는 2회) 오답이면 반드시 풀린다.** 06-M3(최대 9회), 07-M3(6순열), 05-M2(16조합), 12-M2(화면의 시각 4개), 09-F(물건 3개)를 더하면 **약 30개(60%)가 찍기로 실질 통과 가능.**
- 오답 횟수 제한·감점·보기 섞기 없음 (`AnswerChecker.isCorrect`, `MultipleChoiceQuestion` — 보기 순서 고정, 오답 보기 표시 없음).
- **결정적 문제는 인센티브다:** `XpBreakdown.of`는 오답을 보지 않는다. 노힌트 +50, 속도 +20. → 빠르게 3번 찍기 = 최대 XP 170, Sharp Eyes 배지, Case Closed "You did it without a single hint!" / 힌트 2개 읽고 풀기 = XP 100(빠르면 120). **게임이 찍는 아이를 더 칭찬한다.**

**TEST C — 힌트 의존 테스트**
- 콘텐츠 테스트(`season_content_test.dart:95`)는 힌트에 **정답 문자열**이 없는지만 검사한다. 의미상 정답을 주는 Hint 2가 다수: 01-M1, 01-M2(`S _ _ _ E`), 01-M3, 02-M1, 05-M2, 05-M3, 06-M2, 09-M2, 09-M3, 11-M2, 10-F(2순열만 남음).
- 그 외 대부분의 Hint 2는 "어디를 보라"(Notebook·Archive·특정 줄)로, **찾아서 대응시키는 작업**만 남긴다.
- 긍정적 예외: Tip 1이 **언어 자체를 설명**하는 경우 — 06-M1 ("A hat is worn, not carried"), 07-M2 ("Behind is the opposite of in front of"), 05-M2 ("the other way means the opposite of left"), 09-M1 ("The maid's key means the key that belongs to the maid"), 03-M2. **이것이 이 게임이 가진 가장 좋은 학습 피드백이며, 체계화되어 있지 않다.**

**TEST D — 의미 이해 테스트**
- 오독이 실제로 오답으로 이어지도록 설계된 퍼즐: 02-M1, 02-M3, 02-F, 03-M3, 05-M1, 05-M2, 06-M1, 07-M1, 07-M2, 07-F, 08-M2, 09-F 등 **약 12개**. 설계 수준은 높다.
- **그러나 오답 이후 피드백이 일반 문구 하나라서, 오독 설계가 학습으로 전환되지 않는다.** 아이는 "틀렸다"만 알고 "무엇을 잘못 읽었는지"는 모른 채 다음 보기를 누른다.

**TEST E — 증거 활용 테스트**
- 사건 내 재사용(Final 의존)은 대부분 사건에서 R3 — **강점**.
- 사건 간 R3 3개(03→08, 01→11, 04→12) — **강점**.
- 그러나 재사용되는 것은 **사실(숫자·물건·이름)이지 영어 표현이 아니다.** Case 07의 전치사, Case 09의 whose, Case 05의 "the other way"는 이후 어느 사건에서도 다시 요구되지 않는다. **언어 재활용(spaced retrieval)은 설계되지 않았다.**

**기호 매칭 Final 확인 (TEST A의 특수 사례)**
Case 01·05·12 Final의 자물쇠는 기호(`dialSymbols`)와 라벨을 표시하고(`final_mission_screen.dart:324, 399-418`), Notebook의 Clue 카드도 같은 기호 배지를 표시한다(`clue_card.dart:57`). 예: Case 12 — 자물쇠 [train, gear, raven] ↔ Clue [Platform 4(train)=4, Eight Teeth(gear)=8, Seven Ravens(raven)=7] → 487. **편지를 읽지 않아도 풀린다.** Case 05 데이터 주석("the player must read it, not copy the clues")의 의도는 **[무효]**.

---

## 6. 영어 학습 영역별 평가

### 6-1. Case 01 → 12 텍스트 통계 (데이터 파일의 문장 문자열 자동 집계, glossary 제외)

| Case | 단어 수 | 고유 단어 | 이전 사건 대비 새 단어 | 평균 문장 길이 | 최대 | 13단어 이상 문장 |
|---|---|---|---|---|---|---|
| 01 | 896 | 262 | 262 | 5.3 | 13 | 2 |
| 02 | 815 | 207 | 109 | 5.7 | 15 | 4 |
| 03 | 745 | 233 | 106 | 5.6 | 15 | 3 |
| 04 | 723 | 203 | 58 | 5.2 | 17 | 3 |
| 05 | 739 | 208 | 64 | 5.6 | 15 | 2 |
| 06 | 769 | 222 | 73 | 5.1 | 14 | 2 |
| 07 | 702 | 196 | 46 | 6.0 | 14 | 3 |
| 08 | 733 | 236 | 41 | 4.5 | 16 | 1 |
| 09 | 731 | 219 | 46 | 5.7 | 15 | 4 |
| 10 | 668 | 214 | 44 | 4.9 | 13 | 2 |
| 11 | 662 | 240 | 40 | 4.9 | 13 | 1 |
| 12 | 751 | 235 | 29 | 5.3 | 16 | 2 |

(집계 스크립트는 감사 세션의 임시 폴더에서만 실행, 저장소에 추가하지 않음. 수치는 근사치.)

**해석:** 문장 길이·복잡도는 **사건 1~12 내내 평평**하다(4.5~6.0). 텍스트 양은 오히려 약간 줄어든다. 새 어휘는 자연스럽게 감소한다(앞에서 배운 단어가 반복되기 때문 — 이 자체는 긍정적). 접속사(because/so/but), 과거 시제 서술, 관계절 등 구문 성장은 **설계 흔적이 없다.** Case 09 whose, Case 10 문장 어순처럼 **개별 사건의 "주제"가 다를 뿐, 위계적으로 쌓이지 않는다.**

### 6-2. 영역별 판정

| 영역 | 판정 | 근거 |
|---|---|---|
| Vocabulary | **간접 노출** | glossary 탭(의미 확인), 단어 입력 9개(STONE·SEVEN·GREY·RAVEN·ROBIN·ANNA·HAT·MIDNIGHT·BIG BEN). 재사용·회상 없음, 단어 목록 열람 불가 |
| Reading Comprehension | **실제 학습 경험 구현(부분)** | E2 29개 + E3 5개가 독해를 요구. 단, 찍기로 우회 가능하고 이해 확인이 없음 |
| Listening Comprehension | **구현되지 않음** | 음성·TTS 없음 (`pubspec.yaml`: audioplayers는 효과음용) |
| Grammar in Context | **실제 학습 경험 구현(소수)** | 09 whose/'s, 10-F 어순, 07 전치사, 03 정도 표현, 02 before/after. 피드백·재사용 없음 |
| Sentence Construction | **형식적으로 1개** | 10-F 하나(카드 4장 순서) |
| Writing / Spelling | **형식적으로만 존재** | 단어 입력 9개, 대소문자·공백·구두점 무시(`AnswerChecker.normalize`). 05-M3는 "숫자 단어로 쓰라"면서 `7` 허용, 06-M2 GRAY 허용 |
| Speaking | **구현되지 않음** | 01-M5 Hint 2 "Ask your game guide in English" 한 줄(진행자 현장 운영 전제) |
| Logical Reasoning | **실제 경험 구현(강)** | 추리 사슬, Final 의존, 사건 간 R3 |
| Contextual Understanding | **실제 경험 구현(중)** | 04-M1 비유, 08-M1 화용, 09-F whose — 소수지만 질이 높음 |
| Retention / Recall | **사실은 구현, 언어는 미구현** | 사건 간 R3는 "물건·숫자" 회상. 영어 표현 회상 없음 |

---

## 7. 게임성과 교육성의 균형

1. **게임의 재미가 학습을 지원하는가?** — 부분적으로 그렇다. 편지·증거를 "물리적 문서"로 연출해 영어 텍스트를 읽을 동기를 만든다(강점). 그러나 학습이 일어나는 구간(편지→퍼즐)에 비해, 정답 후 연출(Discovery·Story·Map)이 3배 이상 길다.
2. **학습이 흐름에 자연스럽게 통합되어 있는가?** — 독해는 자연스럽게 통합되어 있다(별도 학습 화면 없음 — 좋은 결정). 문제는 통합의 "깊이"다. 읽고 → 고르고 → 끝.
3. **영어 퍼즐이 다음 스토리를 위한 장애물로 작동하는가?** — E0/E1 16개는 그렇다. 특히 이름표가 보이는 그림 선택(01-M4, 04-M3, 10-M3, 11-M3)과 기호 매칭 Final 3개.
4. **연출 대비 학습 피드백이 부족한가?** — 그렇다. 정답 시 Discovery(배경·카드·순차 등장·XP·배지)와 Story가 있지만, "어떤 영어가 결정적이었는지"를 말하는 장치는 Discovery detail 한 줄뿐이고 그마저 미션마다 다르다(일부는 단순 사실 반복).
5. **영어를 이해한 아이가 탐정으로서 유리해지는가?** — Final과 사건 간 연결에서는 그렇다(시간·오답 감소). 일반 미션에서는 **아니다**: 찍는 아이가 XP·배지에서 더 유리하다(§5-3 TEST B).

**강화 가능 지점 (게임성 유지):** 오답 보기에 이미 들어 있는 "오독 유형"을 피드백으로 꺼내는 것, Tip 1을 "언어 도움"으로 일관화하는 것, 찍기 인센티브를 없애는 것. 새 화면·퀴즈·단어 암기 없이 가능하다(§13).

---

## 8. Hint / Wrong Answer / Feedback 분석

| 단계 | 실제 구현 | 근거 | 평가 |
|---|---|---|---|
| 첫 번째 오답 | 흔들림 + 효과음 + 시트 "Not quite! Good detectives look again. Read the clue one more time!" + TRY AGAIN / GET A TIP | `mission_screen.dart:120-125`, `answer_feedback.dart:312-372` | 톤은 좋음(무벌점). **내용은 모든 퍼즐·모든 오답에 동일** |
| 반복 오답 | 같은 시트 반복. 횟수 제한·에스컬레이션 없음. 선택했던 오답 보기도 그대로 | 위 동일, `question_widgets.dart:188-221` | 3번째 오답 후에도 같은 문구 → 찍기 유도 |
| Hint 1 | "Detective Tip 1" 노트. 비용 = 노힌트 보너스 절반(−25 XP) | `game_controller.dart:156`, `scoring.dart` | 일부는 언어 설명(좋음), 다수는 "어디를 보라" |
| Hint 2 | Tip 2 노트. 노힌트 보너스 0 | 위 동일 | 약 11개가 사실상 정답 |
| 정답 | Discovery Moment: 라벨(DEDUCTION 등)·제목·detail 1줄·(선택)증거 카드·노트·XP·배지 | `answer_feedback.dart`, `season1_discoveries.dart` | detail이 "왜"를 말하는 경우도 있음(예: 02-M1 "hour hand between eight and nine, the minutes at seventeen"). **일관 규칙 없음** |
| 미션 성공 후 | Story Scene → Map | `story_scene_screen.dart` | 학습 확인 없음 |
| Final 성공 | solve reveal → Post-Case(사건 요약 서사) → Case Closed(XP·배지·caseSummary) | `final_mission_screen.dart`, `case_solved_screen.dart` | Post-Case가 추리 결론을 "확인"해 줌(좋음). 언어 성취 언급 없음 |

**핵심 질문 답변**
- 왜 틀렸는지 알 수 있는가? → **아니오.**
- 정답만 알려주는가, 추론을 돕는가? → 힌트는 추론을 돕는 쪽으로 설계됨(정답 문자열 금지 테스트). 단 Hint 2 다수는 사실상 정답.
- 영어 표현 이해를 돕는가? → Tip 1 일부만. glossary는 보기·힌트 문구에는 적용되지 않음(`GlossaryText` 사용처: 장면·편지·질문·스토리만).
- 힌트 후 학습 경험이 유지되는가? → 힌트 사용 후 정답 시에도 같은 Discovery. 힌트가 짚은 언어 포인트를 다시 확인하지 않음.
- 오답 반복에 불이익이 없는가? → **없음.** 아이 쪽 화면 기준으로는 오히려 보상이 유지됨.
- 성공 시 이해 확인? → **없음.**
- 성공 피드백이 XP·칭찬 중심인가? → **대체로 그렇다.** Discovery 한 줄이 유일한 "내용" 피드백.

**필요한 피드백 유형 (긴 해설 금지 원칙 준수)**
1. **오답 보기별 한 줄 피드백** (오독 진단형): 예) 02-M3 보기 A 선택 시 "The hour hand was *between* eight and nine. Which number has it passed?" — 데이터 필드 하나로 해결.
2. **결정적 표현 하이라이트** (정답 후): Discovery detail에 결정적 영어 구절을 인용하는 규칙. 예) 09-F "*whose* key = the key that belongs to Carl."
3. **Tip 1 = 언어 도움, Tip 2 = 어디를 볼지** 규칙 고정 (현재 PROJECT_CONTEXT 규칙은 Tip 1 = 무엇을 비교/생각할지).

---

## 9. Notebook / Evidence / Archive 분석

**판정: Notebook은 "추리 도구"로는 실제로 작동하고, "영어 기록물"로는 작동하지 않는다.**

| 항목 | 구현 | 평가 |
|---|---|---|
| Clue | 제목·값·한 줄 노트·기호 배지 (`clue_card.dart`) | Final의 정보원으로 실제 사용됨 (R3) |
| Evidence | 이름·설명·글귀(inscription), 확대 보기 | 글귀가 Final 정답 근거인 경우 다수(03 boot, 04 seal, 07 Joined Map, 11 Old Letter) — **영어 글귀를 다시 읽게 만드는 유일한 장치** |
| Case Archive | 해결한 사건의 전체 Clue·Evidence (`season_archive.dart`) | 사건 간 R3 3개의 경로(4탭) |
| 학습 내용 복습 | 없음 | 찾아본 단어, 결정적 표현 기록 없음 |
| 현재 퍼즐 해결 정보 | Final에서 `OPEN MY NOTEBOOK`, 미션 앱바 아이콘 | 작동 |
| 탐정 활동 기록 | 없음 (아이가 직접 메모·연결하는 기능 없음) | 추리 과정 정리 불가 |

- **Notebook은 사건 해결에 필요한가?** → Final 12개 중 약 9개에서 "기억하지 못하면 필요". 즉 **OPTIONAL BUT USEFUL** 목표(PROJECT_CONTEXT)는 달성됨.
- **영어 단서가 의미 있는 형태로 기록되는가?** → 사실(값)은 기록되지만 **그 값을 이끌어 낸 영어 문장은 기록되지 않는다.** 예) 04-M1 Clue "Day and Night / Platforms — The platforms never sleep." 는 예외적으로 표현을 남김. 대부분은 결과만.
- **기존 구조로 자연스러운 복습이 가능한가?** → 가능하다. Clue `note`와 Evidence `inscription`은 이미 "탐정의 메모" 톤이다. 이 메모에 **결정적 영어 표현을 남기는 작성 규칙**만 추가해도, 단어장 없이 "탐정 기록 = 복습물"이 된다(P1-5).

---

## 10. XP / Badge / Progress / Parent Report 분석

### 10-1. XP / Badge (`lib/features/game/scoring.dart`)

| 질문 | 답 | 근거 |
|---|---|---|
| 무엇으로 XP를 받는가 | 미션 해결 100(Final 200) + 노힌트 50(힌트 1개 25) + 속도 20 | `XpBreakdown.of` |
| 찍어도 같은 XP? | **같다. 오히려 빠르게 찍으면 속도 보너스까지** | 오답 수가 계산식에 없음 |
| 힌트 반영? | 반영(감소) | — |
| 추리·영어 이해 반영? | 반영되지 않음 | — |
| 배지 의미 | First Clue(단서 1개), Sharp Eyes(힌트 없이 1미션 — 찍기로 달성), Quick Thinker(속도), Puzzle Solver(3개), London Explorer(모든 미션), Master Detective(사건 완료) + 사건 배지 6개(사건 완료 시) | `GameBadge.isEarned` |
| 학습 목표 연결 | **없음.** "Letter Reader"(Case 04) 등 이름은 학습처럼 보이지만 조건은 "사건 완료" | — |
| XP로 열리는 것 | 없음 (PROJECT_CONTEXT 명시) | — |

### 10-2. Progress
- 진행률 = 해결한 미션/사건 수. **사건 완료와 영어 성취를 구분하지 않는다.**
- 저장되는 학습 관련 원자료: 미션별 `attempts`, `wrongAnswers`, `hintsUsed`, `solveSeconds`, 사건별 `lookedUpWords`(고유 단어 목록). → **"어떤 퍼즐에서 몇 번 틀렸는가"는 분석 가능**, "어떤 영어 표현을 이해했는가"는 퍼즐에 언어 목표가 매핑되어 있지 않아 **분석 불가**. 시즌 단위 집계 화면·로직 없음(보고서는 현재 사건 하나만: `ParentReportScreen`이 `currentEpisodeProvider` 사용).

### 10-3. Parent Report — **판정: "플레이 기록"에 학습 성취 보고서의 외형을 씌운 것**

| 표시 항목 | 실제 계산 | 문제 |
|---|---|---|
| English Skills ★ (어휘/읽기/문제 해결) | 미션 점수 = `1 − 0.2×min(오답,3) − 0.15×힌트`, 최저 0.3 → 해당 태그 미션 평균×5, 반올림, `clamp(1,5)` (`detective_report.dart:47-65`) | ① 태그 기준 없음: **50/50 미션이 reading**, vocabulary 18, problemSolving 33 ② 세 별점이 같은 원자료(오답·힌트)에서 나옴 → 거의 같은 값 ③ **최저 2★ 보장**(0.3×5=1.5→2) ④ 09-M2(알파벳 순서)도 reading 태그 |
| "특히 {keyWords} 같은 핵심 단어를 잘 알아보고 활용했어요" | 가장 높은 별점이 vocabulary면 출력. 동점이면 정렬 첫 항목 | **측정되지 않은 사실의 단정.** keyWords는 게임에서 측정되지 않음. Case 01은 하드코딩된 museum·stone·palace |
| "문장 속에서 장소와 인물의 단서를 찾아내는 읽기 능력이 돋보였어요" | reading이 최고 별점이면 출력 | 오답이 적었다는 사실을 "읽기 능력"으로 해석 — 찍기 3번 vs 1번 차이 |
| 정답률 | 해결 미션 수 / 전체 제출 수 | 의미 있음. 단 "정답률"이 영어 이해도를 뜻하지 않음 |
| 찾아본 단어 N개 | 고유 단어 수 | **어떤 단어인지 보여 주지 않음** — 부모에게 가장 유용한 정보가 저장되어 있는데 숨겨져 있음 |
| 미션별 기록 | 장소·퍼즐 유형 라벨·n번째 도전·힌트 수 | 유형 라벨 "객관식 읽기" 등은 사실과 대체로 부합 |
| 하단 문구 | "영어를 '공부'가 아닌 '모험의 도구'로 경험하는 에듀테인먼트" | 정직한 포지셔닝 — 위 별점과 상충 |

**부모가 알 수 있는 것 / 없는 것**

| 질문 | 현재 |
|---|---|
| 아이가 어떤 영어를 접했는가 | ✗ (사건 제목·장소만) |
| 어떤 영어를 이해했다고 볼 수 있는가 | ✗ (별점이 있는 것처럼 보이지만 근거 없음) |
| 어디서 어려움을 겪었는가 | △ (미션별 오답·힌트 수 — 원인은 모름) |
| 힌트를 얼마나 썼는가 | ✓ |
| 읽기/어휘/추론 중 어떤 경험을 했는가 | ✗ (별점은 경험이 아니라 오답 수) |
| 이전보다 무엇이 나아졌는가 | ✗ (사건 간 비교 없음) |

> **원칙 위반:** "실제로 측정하지 않은 능력을 측정한 것처럼 표시하지 말 것." — 현재 별점과 강점 코멘트가 정확히 여기에 해당한다. 이것이 P0-1이다.

---

## 11. 8~12세 적합성 (전체 **전문가 추정**, 플레이테스트 없음)

대상은 한국 아동으로 추정된다(glossary 한국어, 부모 보고서 한국어). 참고: 한국 초등 영어 정규 교육은 3학년(만 8~9세)부터 시작한다.

| 항목 | 8~9세 | 10~11세 | 12세 |
|---|---|---|---|
| 문장 길이 (평균 5단어) | 짧지만 한 화면 문장 수가 많음 | 적절 | 쉬움 |
| 어휘 | **부담 큼** (clockkeeper, belfry, postmark, porter, usher, inspector, timetable…). 사건당 glossary 26~44개 | 중간 — glossary로 해결 | 대부분 앎 |
| 독해 부담 (사건당 ~660~900단어) | **높음.** 혼자 진행 어려울 가능성 | 적정 상한 | 적정 |
| 추리 난이도 | 02 시계 읽기(8:17), 09 whose, 사건 간 Archive 4탭이 벽 | 적절 | 적절~약간 쉬움 |
| UI 안내 문구 | **전부 영어**(INVESTIGATE, TAP TO OPEN, CLUE CONFIRMED, STORY DISCOVERY) — 추상적 | 이해 가능 | 문제 없음 |
| 힌트 적절성 | 힌트 자체도 영어 문장(glossary 미적용) | 적절 | Hint 2 과다 직접 |
| 텍스트 밀도 | 높음 | 적정 | 적정 |
| 플레이 피로도 | 사건당 10~15분 + 대기 연출, 장문 반복 → 피로 | 적정 | 반복 패턴(Case 08~12 첫 미션이 모두 묘사 비교)에서 지루함 가능 |
| 자율 진행 | **낮음** — 보호자 동반 전제가 현실적 | 대체로 가능 | 가능 |
| 성취감 | 찍어서 통과 시 성취감이 공허할 수 있음 | 높을 것 | 추리(02·09·사건 간 연결)에서 높음, 영어에서는 낮음 |

**검증 필요 항목 (플레이테스트로만 확인 가능)**
1. 8~9세가 보호자 없이 Case 01을 완료하는가, 몇 번 찍는가
2. glossary 탭 빈도(사건당)와 피로의 관계
3. 02-M1 시계 읽기가 영어 문제인지 시계 문제인지
4. 12세가 영어를 "너무 쉽다"고 느끼는가(언어 성장 부재의 체감)
5. Discovery 라벨 영어를 이해하는가

---

## 12. 가상 플레이어 시뮬레이션 (**가설 — 실제 사용자 테스트 아님**)

### Player A — 8세, 영어 초급
| | Case 01 | Case 06 | Case 12 |
|---|---|---|---|
| 흥미 | 봉투·편지·런던 장면, QR 찾기 | 한밤 마켓 분위기 | 피날레 연출, Big Ben 종 |
| 막히는 곳 | M2 "hard piece of rock"(단, 제목에 STONE이 보여 우회), M3는 대문자로 우회 | M1 carried/wore, M3 다른 점 세기, M2 색 어휘 | M2 시간표 + Archive 4탭, M3 수수께끼 |
| 힌트 필요 | 미션당 1~2개 | 대부분 2개 | 대부분 2개 + 보호자 |
| 영어 이해 필요 순간 | 거의 없음(M2 일부) | M1, M3 | M2, M3 |
| 우회 가능? | **대부분 가능** (MC·그림 찍기, 기호 매칭 Final) | MC 2개 찍기 가능, M2·M3는 Hint 2로 | M1 찍기, Final 기호 매칭 |
| 해결 후 "배운 것" | "도둑이 박물관에 갔어", "museum" | "Grey는 좋은 탐정이야" | "Big Ben 아래 문" |
| 다음 사건 동기 | 높음(이야기) | 중 | — |

### Player B — 10세, 영어 중급
| | Case 01 | Case 06 | Case 12 |
|---|---|---|---|
| 흥미 | 모든 미션이 쉽게 풀리는 쾌감 | 증언 비교 | 사건 간 회수 (Platform 4!) |
| 막히는 곳 | 거의 없음 | M3 개수(같은 것까지 세는 실수) | M2 Archive 탐색 |
| 힌트 필요 | 0~1 | 0~1 | 1 |
| 영어 이해 필요 순간 | M1~M4 독해 | M1 carried, M3 비교 | M1 속성 소거, M2 시간표, M3 수수께끼 |
| 우회 가능? | 가능하지만 굳이 안 함 | 일부 | 일부 |
| 해결 후 "배운 것" | 영어 편지를 읽고 장소를 찾았다 | "carried는 들고 있는 거" (Tip 1을 봤다면) | 시즌을 다시 떠올림 — **영어 표현을 배웠다고 말하기는 어려움** |
| 다음 사건 동기 | 높음 | 높음 | PARIS 훅 |

### Player C — 12세, 영어 중상급
| | Case 01 | Case 06 | Case 12 |
|---|---|---|---|
| 흥미 | 연출 | 이중 인물 반전 | 시즌 회수, 수수께끼 |
| 막히는 곳 | 없음 | 없음 | 없음 |
| 힌트 필요 | 0 | 0 | 0~1 (Archive) |
| 영어 이해 필요 | 모두 쉬움 | 쉬움 | 쉬움 |
| 우회 가능? | 필요 없음 | 필요 없음 | 필요 없음 |
| 해결 후 "배운 것" | 런던 지명 | — | — |
| 다음 사건 동기 | 추리·스토리에 달림. **영어 도전감은 Case 12까지 증가하지 않음** | | |

**시뮬레이션의 결론 (가설):** A는 영어를 거의 이해하지 않고도 진행할 수 있고 보상도 받는다. C는 영어에서 얻는 것이 없다. **B만이 "탐정 활동으로서의 영어"를 의도대로 경험한다.** 실제 핵심 타깃은 **10~11세 중급**으로 좁혀져 있다.

---

## 13. 핵심 문제 P0 / P1 / P2

> 모든 개선안은 제약을 지킨다: Vintage London Detective Storybook 디자인 유지, 기존 스토리·사건 연결 보존, Case 01~12 구조 유지, 저장 데이터 호환(필드 추가만, 기존 키 변경 없음), 학습지/퀴즈 앱 전환 금지, 신규 화면 추가 금지.

### P0 — 제품 정체성에 치명적

#### P0-1. 부모 보고서가 측정하지 않은 영어 능력을 측정한 것처럼 표시한다
- **현재 문제:** "English Skills" 별점과 강점 코멘트가 오답·힌트 수에서 유도되며, 태그 기준이 없고, 최저 2★가 보장된다. keyWords를 "잘 알아보고 활용했다"고 단정한다.
- **근거:** `detective_report.dart:47-65`(별점), `:139`(Case 01 폴백), `:142-170`(코멘트), `parent_report_screen.dart:46-60`, 미션 50개 `skills` 태그 분포
- **아이에게 미치는 영향:** 직접 영향은 작음. **부모의 신뢰**에 치명적 — 아이가 찍어서 통과했는데 "읽기 능력이 돋보였다"를 본 부모는 제품 전체를 의심한다.
- **개선 방향:** 보고서를 **정직한 "탐정 활동 기록"**으로 재정의.
  1. 별점 제거 또는 "탐정 기록(Detective Record)"으로 개명하고 사실만 표기: "이번 사건에서 읽은 영어 편지 N통", "스스로 찾아본 단어: *frozen, gear, belfry…*"(이미 저장된 `lookedUpWords` 목록 표시), "힌트 없이 / 한 번에 해결한 미션".
  2. 강점 코멘트는 **관찰 사실 + 사건의 언어 초점**으로: "이번 사건은 *시간 표현(before / after / one hour after)*이 핵심이었어요. ○○는 Final(9:17)을 n번째 시도에 해결했어요."
- **수정 대상:** `lib/features/result/detective_report.dart`, `lib/features/result/parent_report_screen.dart`, (선택) `episodeNN_mock.dart`에 `languageFocus` 문자열
- **난이도:** 낮음 (데이터 이미 존재, 표시만 변경)
- **게임성 영향:** 없음 (Parent Gate 뒤 화면)
- **검증:** `detective_report_test.dart` 갱신 — "모든 미션 3회 오답 + 노힌트" 진행에서 '능력이 돋보였다'류 문장이 출력되지 않는지 단정. 보호자 3명에게 보고서를 보여 주고 "아이가 무엇을 했는지" 설명하게 하기.

#### P0-2. 보상 구조가 "찍기"를 "힌트 읽기"보다 우대한다
- **현재 문제:** 오답은 XP·배지에 무영향, 힌트는 XP 감소. 선택형 ~30개가 ≤3회 찍기로 통과. Sharp Eyes·"without a single hint!"를 찍기로 획득.
- **근거:** `scoring.dart` `XpBreakdown.of`(wrongAnswers 미사용), `GameBadge.sharpEyes`, `detective_report.dart` `caseSummary`, `question_widgets.dart:188-221`
- **아이에게 미치는 영향:** 영어를 읽지 않는 전략이 최적 전략이 된다. 8세에게 특히 강하게 작동할 것 **[추정]**.
- **개선 방향 (무벌점 철학 유지):**
  1. 보너스 조건을 "노힌트" → **"스스로 해결(첫 시도 또는 오답 ≤1, 그리고 노힌트)"**로. 감점이 아니라 *보너스 조건*만 바뀐다. 기본 100 XP는 유지.
  2. Sharp Eyes = "힌트 없이 **첫 시도에** 해결". Case Closed 문구도 같은 기준.
  3. 선택형에서 **오답 2회째부터 Tip 1을 무료로 자동 펼침**(XP 영향 없음) — 찍기 루프를 끊고 "다시 읽기"로 유도. 오답 보기 표시(X)는 하지 않는다(찍기 가속).
- **수정 대상:** `lib/features/game/scoring.dart`, `lib/features/mission/mission_screen.dart`, `lib/features/mission/final_mission_screen.dart`, `lib/features/result/detective_report.dart`
- **난이도:** 낮음~중
- **게임성 영향:** 작음. 무벌점·무제한 재시도 유지. XP 표시 숫자만 달라짐(XP는 저장하지 않고 매번 계산하므로 기존 세이브와 호환되며, 기존 진행분의 XP가 재계산될 수 있음 — 의도된 변화로 기록할 것).
- **검증:** `game_controller_test`·`discovery_moment_test`의 XP 단정 갱신. 플레이테스트에서 8~9세의 미션당 오답 수 분포 비교(전/후).

#### P0-3. 학습 목표가 정의되어 있지 않아, 어떤 개선도 측정·보고할 수 없다
- **현재 문제:** 사건별 언어 초점이 데이터 파일 주석에만 있다. 무엇을 배우게 하는지 시스템·부모·팀 누구도 공유하지 않는다.
- **근거:** `episode02~12_mock.dart` 헤더 주석, `Episode.keyWords`(3단어, 측정 없음), `Mission.skills`(기준 없음)
- **아이에게 미치는 영향:** 간접적 — 목표가 없으니 피드백·난이도·재사용이 설계될 수 없다.
- **개선 방향:** **새 시스템이 아니라 "명문화"**.
  1. Episode에 `languageFocus`(예: "Time: before / after / one hour after") 1줄, Mission에 선택적 `languagePoint`(그 퍼즐을 결정하는 구절, 예: `"whose key"`) 1줄 추가 — 데이터만, 표시는 P0-1 보고서·P1-2 Discovery에서.
  2. `skills` 태그 기준 문서화 또는 제거(P0-1과 연동).
  3. PROJECT_CONTEXT의 "제품 철학"에 *"영어 학습 목표는 사건별 languageFocus로 정의한다"* 한 줄 추가(다음 작업 세션에서).
- **수정 대상:** `lib/data/models/episode.dart`, `lib/data/models/mission.dart`(선택 필드, `fromJson` 관대 처리), `episodeNN_mock.dart`, `test/season_content_test.dart`(모든 사건에 languageFocus 존재)
- **난이도:** 낮음 (콘텐츠 작성 시간이 대부분)
- **게임성 영향:** 없음
- **검증:** 콘텐츠 테스트 + 팀 리뷰: 50개 퍼즐 각각에 "이 구절을 오독하면 틀린다"가 성립하는지 표시.

### P1 — 교육적 가치를 크게 높이는 개선

| # | 현재 문제 | 근거 | 아이 영향 | 개선 방향 | 수정 대상 | 난이도 | 게임성 영향 | 검증 |
|---|---|---|---|---|---|---|---|---|
| P1-1 | 오답 피드백이 모든 퍼즐에서 동일 | `answer_feedback.dart:347-352` | 무엇을 오독했는지 모름 | 선택형 보기에 선택적 `feedback` 한 줄(오독 진단). 시트의 고정 문구 자리에 표시. 없으면 기존 문구. 우선 TEST D "강" 퍼즐 ~12개만 | `mission.dart`(ChoiceOption 필드), `answer_feedback.dart`, 해당 `episode*_mock.dart` | 중 | 긍정 — "탐정 파트너의 지적" 톤 | 오답 후 다음 시도 정답률 비교 |
| P1-2 | 정답 후 "결정적 영어"가 드러나지 않음 | `season1_discoveries.dart` detail 규칙 없음 | 맞혀도 왜 맞았는지 모름 | Discovery detail 작성 규칙: E2/E3 퍼즐은 **결정적 구절을 인용**(예: *"one hour after"*, *"whose key"*). 긴 해설 금지, 1문장 유지 | `season1_discoveries.dart`, `discovery_moment_test.dart` | 낮음 | 없음 | 사건 후 "왜 9:17이었어?" 질문에 답하는 비율 |
| P1-3 | Final 3개가 기호 매칭으로 풀림 (01·05·12) | `final_mission_screen.dart:324,399-418`, `clue_card.dart:57` | 피날레에서 영어가 무의미 | Case 05·12 자물쇠에서 **기호를 지우고 위치(1·2·3)만** 표시 → 편지의 질문("how many ravens…?")을 읽어야 함. Case 01은 튜토리얼이므로 유지 가능 | `episode05/12_mock.dart`(`dialSymbols`), Final 위젯의 기호 없는 자물쇠 처리 | 중 | Case 12 피날레가 "기호 맞추기 → 읽고 회수"로 강화 | `wave1/season_content` 테스트에 "Final 자물쇠 기호 ≠ Clue 기호 1:1" 규칙 |
| P1-4 | 정답 사전 노출 | 01-M2 제목·장면 "Stone", 12-M3 같은 사건 M1 "Big Ben", 06-M2 M1 "grey hat", 04-F RAVEN 시즌 반복, 이름표가 보이는 그림 선택(10-M3 "Tower Bridge") | 독해 없이 통과 | 노출 문구 교체(제목·장면 1~2줄), 10-M3 등 단어 일치 그림 선택은 이름표 숨김(07 지도처럼). 누출 테스트를 **Case 01 포함·미션 제목·같은 사건 이전 장면**까지 확장 | `episode01/06/10/12_mock.dart`, `question_widgets.dart`(이름표 규칙), `season_content_test.dart:112`(`later` → 전체) | 낮음~중 | 없음(문구만) | 확장된 누출 테스트 통과 |
| P1-5 | Notebook에 결정적 영어 표현이 남지 않음 | `clue.note` 작성 관행 | 복습 기회 없음 | Clue `note` 작성 규칙: 결과 + 근거 구절(04-M1처럼). 단어장 화면 없이 **탐정 메모 = 복습물** | `episode*_mock.dart` clue note | 낮음 | 없음 | 사건 간 R3 퍼즐에서 Archive 조회 후 정답률 |
| P1-6 | 언어 표현이 사건 간 재사용되지 않음 | §5-3 TEST E | 배운 표현이 한 번 쓰이고 사라짐 | Case 12(종합)의 기존 퍼즐 문구에 앞 사건 언어 초점을 **재요구**: 예) 12-M1 편지에 Case 07 전치사, 12-F 질문에 Case 09 whose 구조. 구조·정답은 유지 | `episode12_mock.dart`(+ 필요 시 08~11) | 중 | 긍정(피날레 "모든 것을 쓴다" 강화) | 해당 구절 오독 시 오답 유도되는지 확인 |
| P1-7 | 언어 난이도 성장 없음 | §6-1 | 12세 정체, 8세 과부하 | **Case 07~12 편지 문장에 한해** 접속사(because/so/but), 과거 서술을 단계적으로 도입하는 문체 가이드. 사건 구조·정답 불변 | `episode07~12_mock.dart` letter/story | 중~높음(콘텐츠) | 작음 | 문장 길이·접속사 통계 재측정 |
| P1-8 | Glossary가 보기·힌트에 적용되지 않음 | `GlossaryText` 사용처 5곳 | 8세가 보기·힌트 단어에서 막힘 | `_ChoiceTile`, `_TipNote`에 GlossaryText 적용 | `question_widgets.dart`, `answer_feedback.dart` | 낮음 | 없음 | 위젯 테스트 |
| P1-9 | 반복 플레이 시 정답 암기만 남음 | 보기 순서 고정 | Play again 무가치 | 재플레이 시 MC 보기 순서 섞기(정답 id 기반 판정이라 로직 영향 없음). 단 오답 설계(Case 02 M3)의 의미 순서가 있는 퍼즐은 제외 플래그 | `question_widgets.dart` | 낮음 | 없음 | — |

### P2 — 출시 이후 개선 가능

| # | 내용 | 근거/메모 |
|---|---|---|
| P2-1 | 시즌 단위 부모 보고서 (사건별 languageFocus·찾아본 단어 누적·사건 간 비교) | 현재 사건 하나만 표시 |
| P2-2 | 듣기: 편지·증언을 탐정 파트너 목소리로 읽어 주기(선택, 8~9세용) | 구현 없음. PROJECT_CONTEXT Proposed(TTS) |
| P2-3 | 난이도/연령 모드 (예: Junior Detective — 편지 짧은 버전·한국어 UI 안내) | 데이터 다중 버전 필요 |
| P2-4 | 공통 배지 사건마다 반복(~70회) 완화 | PROJECT_CONTEXT P2 기존 이슈 |
| P2-5 | 미션당 대기 연출(~14s) skip/단축 | PROJECT_CONTEXT P2 기존 이슈 |
| P2-6 | 학습 통계(퍼즐별 오답 분포 → 어떤 languagePoint가 어려운지) | 원자료는 이미 저장됨 |
| P2-7 | 문서 정합성: 플레이테스트 체크리스트가 현재 데이터와 다름 — Case 02 M3를 "순서 맞추기 / first of all"로 기술(실제 MC), Case 01 Final 자물쇠 "P·M 머리글자"(현재 기호), Case 03 Final "두 개의 큰 아치"(현재 편지에 없음). PROJECT_CONTEXT "이미지 선택 퀴즈 타일은 이름표를 숨김"은 사실과 다름(랜드마크는 이름 표시, 지도만 숨김 — `question_widgets.dart` `nameOf`, `new_artwork_test` 테스트명) | 플레이테스트 진행자 혼선 방지 |
| P2-8 | 저장소 정리: `episode03_mock.dart` glossary의 `arches`(편지에 없음) 등 사용되지 않는 glossary 항목 | 경미 |

---

## 14. 현재 잘 설계된 부분 (유지해야 할 강점)

1. **추리 사슬의 질.** Case 02(8:17 → Gallery 8·Picture 17 → 9:17), Case 09(whose ≠ who had it), Case 07(두 정보 결합), Case 03(boot smells of trains). 각 Final이 앞 미션 정보에 실제로 의존한다. 회귀 테스트로 보호되고 있음(`case02/09/wave1/wave2_reasoning_test`).
2. **오답 보기 설계.** Case 02 M3 등은 "아이가 할 법한 오독"을 보기로 만들었다 — 교육 설계의 모범 사례이며, 피드백만 붙이면 바로 학습 장치가 된다.
3. **언어 도움형 Tip 1.** 06-M1, 07-M2, 05-M2, 09-M1의 Tip 1은 정답이 아니라 *영어의 의미*를 가르친다. 이것을 규칙으로 확장할 가치가 있다.
4. **번역 선노출 금지 + Glossary.** 영어를 먼저 읽게 하고 필요할 때만 뜻을 보는 구조는 언어 습득 관점에서 옳다.
5. **무벌점 오답·탐정 파트너 톤.** 아이의 정서적 안전. (보상 조건만 손보면 된다 — P0-2.)
6. **사건 간 R3 연결 3개 + Case Archive.** "이전에 읽은 것이 지금 쓸모 있다"는 경험은 학습 재활용의 뼈대로 그대로 쓸 수 있다.
7. **Evidence 글귀를 다시 읽게 하는 Final.** 영어 텍스트 재독해를 게임 행동으로 만든 유일하고 좋은 장치.
8. **"학습 화면 없음" 결정.** 퀴즈·단어장 화면을 만들지 않은 것은 정체성 측면에서 옳다. 개선도 이 원칙 안에서 해야 한다.
9. **저장 원자료.** 미션별 오답·힌트·시간·찾아본 단어가 이미 저장되어 있다 → 정직한 보고서는 데이터 추가 없이 가능하다.
10. **기술 기반.** 콘텐츠 = 데이터, 관대한 fromJson, 라우터 가드, 779개 테스트. 개선안 대부분이 데이터·문구 수준에서 가능하다.

---

## 15. 개선 우선순위 및 로드맵

| 단계 | 작업 | 산출물 | 예상 규모 | 선행 조건 |
|---|---|---|---|---|
| **1. 정직성 (출시 전 필수)** | P0-1 보고서 재정의, P0-3 languageFocus 명문화 | 보고서·데이터 필드 | 작음 (1~2일) | 없음 |
| **2. 인센티브 (출시 전 필수)** | P0-2 보너스 조건·자동 Tip | scoring·미션 화면 | 작음~중 (1~2일) | 없음 |
| **3. 플레이테스트 1차** | 8~9세 / 10~11세 / 12세 각 2~3명, Case 01·02·06·09·12 | 체크리스트 결과 | 1~2주 | 1·2단계, 체크리스트 정합(P2-7) |
| **4. 학습 피드백** | P1-1 오답 피드백(12개), P1-2 Discovery 인용, P1-5 Clue note, P1-8 Glossary 확장 | 데이터·위젯 소폭 | 중 (3~5일) | 3단계 결과로 우선순위 조정 |
| **5. 퍼즐 정합** | P1-3 기호 Final, P1-4 누출 제거, P1-9 셔플 | 데이터·테스트 | 중 (2~3일) | — |
| **6. 시즌 학습 곡선** | P1-6 언어 재사용(Case 12 중심), P1-7 문체 단계화(Case 07~12) | 콘텐츠 | 큼 (콘텐츠 작업) | 플레이테스트로 난이도 기준 확보 |
| **7. 출시 후** | P2 전체 | — | — | — |

---

## 16. 최종 제품 방향 제안

**방향: "TYPE C의 몸체를 유지하고, TYPE B의 신경계를 연결한다."**

- 현재의 탐정 게임 구조·스토리·연출은 **바꾸지 않는다.** 이것이 이 제품의 가장 큰 자산이다.
- 영어를 "더 많이" 넣지 않는다. 대신 **이미 있는 결정적 영어 구절**(퍼즐마다 하나씩 존재)을 ① 명시하고(P0-3) ② 오답·정답 피드백에서 짚고(P1-1·P1-2) ③ 탐정 메모에 남기고(P1-5) ④ 피날레에서 다시 요구하고(P1-6) ⑤ 부모에게 정직하게 보여 준다(P0-1).
- 이렇게 하면 **"영어를 정확히 읽은 탐정이 실제로 유리해지는" 구조**가 된다. 이것이 요청서의 초기 정의(영어 = 목표이자 수단)와 저장소 문서의 철학(학습 앱이 아니다)을 동시에 만족하는 유일한 지점으로 판단한다.
- 되돌려야 하는 것(초기 기획으로): **학습 목표의 존재**, **이해 확인(가벼운)**, **부모 보고의 정직성**.
- 유지해야 하는 것(현재 방향): **학습 화면 없음**, **무벌점**, **번역 선노출 금지**, **추리 중심 Final**, **스토리 우선 연출**.

---

### 최종 질문

> **지금 London Mystery를 그대로 출시한다면, 부모는 영어 교육 앱으로서 가치를 느끼고, 아이는 탐정 게임으로서 재미를 느낄 수 있는가?**

## 판정: **NO** (그대로 출시하는 경우)

**판정 근거**
1. **아이의 재미 — 가능성 높음, 미검증.** 추리 사슬·연출·시즌 서사는 강하다(§14). 그러나 실제 아이 플레이테스트가 한 번도 없다. 특히 8~9세의 자율 진행 가능성과 미션당 대기 피로는 확인되지 않았다.
2. **부모의 교육 가치 인식 — 현재 상태로는 아니오.** 부모가 볼 수 있는 유일한 교육 근거인 보고서가 측정하지 않은 능력을 별점·단정 문장으로 표시한다(P0-1). 찍어서 통과한 아이와 정확히 읽은 아이가 보고서에서 거의 구분되지 않는다(P0-2). 아이가 *어떤 영어를* 접하고 이해했는지 보고서에서 알 수 없다. 이 상태로 "영어 교육 앱"으로 판매하면 첫 사용 후 신뢰를 잃을 위험이 크다.
3. 두 조건이 모두 필요한 질문이므로 결론은 **NO**. 다만 격차는 구조가 아니라 **표시·보상 조건·데이터 명문화**에 있다.

**`CONDITIONAL YES`로 가기 위해 출시 전 반드시 충족·검증해야 할 조건**
1. **P0-1 완료:** 부모 보고서가 측정한 사실만 표시한다(별점 제거 또는 근거 있는 재정의, 찾아본 단어 목록, 사건 언어 초점). → 검증: 보호자 3명 이상이 보고서만 보고 "아이가 무엇을 했는지" 정확히 설명.
2. **P0-2 완료:** 찍기가 보상상 우월 전략이 아니다. → 검증: 테스트로 "3회 찍기 진행"의 XP·배지·문구가 "첫 시도 정답"보다 낮음을 고정.
3. **P0-3 완료:** 12사건 모두 languageFocus가 정의되어 있고 보고서에 표시된다.
4. **실제 플레이테스트 (최소 연령대별 2~3명):**
   - 10~11세가 Case 01·02·06을 보호자 도움 없이 완료하고 "또 할래" 반응이 있는가
   - 8~9세는 보호자 동반 시 완료 가능한가 — 아니라면 마케팅 연령을 **9~12세(또는 10~12세)로 조정**하거나 P2-3을 출시 범위로 당김
   - 미션당 평균 오답 수와 Hint 사용 분포가 "찍기 우세"가 아닌가
   - 사건 후 "왜 그 답이었어?" 질문에 결정적 영어 구절로 답하는 비율(P1-2 전후 비교 권장)
5. **포지셔닝 문구 정합:** 스토어·보고서 문구를 "영어 학습 앱"이 아니라 **"영어로 사건을 해결하는 탐정 게임 (영어 독해 경험 + 플레이 기록 제공)"**으로 맞춘다 — 현재 보고서 하단 문구("모험의 도구")와 일치하는 방향.

위 1~3은 기존 구조를 바꾸지 않는 작은 수정이며, 4·5가 확인되면 판정은 **CONDITIONAL YES**로 바뀐다고 판단한다.

---

#### 부록 A. 이번 감사에서 확인한 주요 파일
`PROJECT_CONTEXT.md`, `README.md`, `docs/playtest/SEASON1_PLAYTEST_CHECKLIST.md`, `lib/data/mock/season1/episode01~12_mock.dart`, `season1_discoveries.dart`, `lib/data/models/{mission,episode,game_progress}.dart`, `lib/core/utils/answer_checker.dart`, `lib/core/constants/app_constants.dart`, `lib/features/game/{game_controller,scoring}.dart`, `lib/features/mission/{mission_screen,final_mission_screen}.dart`, `lib/features/mission/widgets/{question_widgets,answer_feedback}.dart`, `lib/features/result/{detective_report,parent_report_screen,case_solved_screen}.dart`, `lib/features/notebook/notebook_screen.dart`, `lib/widgets/{glossary_text,clue_card}.dart`, `test/season_content_test.dart`

#### 부록 B. 이번 감사에서 하지 않은 것
- 앱 실행·실기기 확인, 스크린샷 검토 (화면 판단은 코드·테스트명 기반)
- 실제 어린이 테스트 (전부 추정으로 표기)
- `flutter analyze` 실행
- 코드·콘텐츠·PROJECT_CONTEXT.md 수정, 커밋
