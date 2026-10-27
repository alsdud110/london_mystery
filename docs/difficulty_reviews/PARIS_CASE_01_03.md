# Paris Case 01–03 — 난이도별 영어 콘텐츠 검토 보고서 (Difficulty PART 7A)

- 작성: 2026-10-27 · 브랜치 `feat/difficulty-paris-01-03` · 기반 커밋 `b6fb71e`(PART 5)
- 범위: Season 2 *Paris Stands Still*의 Case 01 *The Ticking Watch*, Case 02 *The Vanishing Painter*, Case 03 *The Tower's Secret* — Rookie 검토 + Junior·Master 전체 작성
- 콘텐츠 원본: `lib/data/mock/season2/difficulty/ep01_levels.dart`~`ep03_levels.dart` (Case별 Rookie 패치·Junior·Master 사건 JSON 패치·장면 문장·학습 표현; 학습 헬퍼 `levelObjectiveWith`는 `difficulty/level_words.dart`). 등록: `lib/data/mock/season2/season2_difficulty.dart` (`season2CasePatches`, `season2Variants`, 완료 표시 `season2WrittenLevels`). PART 7A 당시에는 모두 `season2_difficulty.dart` 한 파일에 있었고, 2026-10-27 Case별로 분리(`77e65d2`, 내용 불변).
- 검증: `test/difficulty_paris_7a_test.dart`(26), 기존 전체 회귀 포함 2,386 통과
- 이 문서 끝의 **부록 A**는 실제 적용된 콘텐츠에서 자동 추출한 *모든* Rookie/Junior/Master 문장 표다(재현 방법은 부록 B).

---

## 1. 결과 요약

| Case | Rookie | Junior | Master | 비고 |
|---|---|---|---|---|
| 01 `s2_ep01` | 기준본 유지 + glossary 5어 | ✓ 전 문장 | ✓ 전 문장 | PART 5 샘플(M1 story·question·hints·success·학습 표현) 유지 |
| 02 `s2_ep02` | 기준본 유지 + glossary 9어 | ✓ 전 문장 | ✓ 전 문장 | 화가의 인용·캔버스 메시지 원문 유지 |
| 03 `s2_ep03` | 기준본 유지 + glossary 11어 | ✓ 전 문장 | ✓ 전 문장 | "시간이 실제로 사라졌다" 단정 금지 유지 |

- 세 Case 모두 `writtenLevels`에 Rookie·Junior·Master로 등록 → `DifficultyContent.missingAt` 빈 목록을 테스트가 강제(대체 문장으로 가려진 미작성 문장 없음).
- `DifficultyContent.problems()` 빈 목록(구조·정답·ID·순서·힌트 개수 위반 없음).
- 난이도별로 같은 것: 사건 제목·장소, 미션 제목·위치, 정답, 선택지 ID·순서·라벨, 힌트 개수·가격, 단서 제목·값, 증거 이름·글귀(inscription), 코인·XP, Discovery 종류, 학습 설계의 의존도·수준·기능.

## 2. 작성한 필드와 적용 방식

**사건 JSON(필드 단위 패치)**: `intro`, `synopsis`, `objectives`, `caseSummary`, `hook`, `glossary`(추가) / 미션 `story`, `letterIntro`, `letter`, `question`, `hints`(개수 동일), `successMessage`(= Discovery 제목), `transition`, `orderFeedback`, 오답 줄 `feedback` 값(키 = 오답 그대로), 선택지 `feedback`, `clue.note`, `evidence.description`.

**바꾸지 않은 JSON 텍스트**: 사건·미션 `title`/`location`/`place`, 선택지 `label`(판정·부모 보고서 정답표·장면 이름과 연결), 단서 `title`, 증거 `name`(Case 08·09·12가 이 이름과 ID로 회수), `inscription`(퍼즐 자료).

**장면 객체(난이도별 객체 전체 교체)** — 구조 필드는 기준 객체에서 그대로 복사하는 빌더(`_hall`, `_ticket`, `_oldClock`, `_street`, `_studio`, `_easel`)로 만들고, 바뀌는 것은 설명·발견·실패 줄뿐:

| 표/미션 | 난이도별로 쓴 것 | 모든 난이도 동일(의도) |
|---|---|---|
| `stationClocks/s2_ep01_m1` | missLine, boardFirstLine, clocksFirstLine, 주변 5곳 줄 | task·boardTask·reportTask·reportHow·tap/zoom 안내, 시계·출발 안내판·안내문(notice)·창구 |
| `exhibits/s2_ep01_m2` | 표 설명·캡션 | 표에 인쇄된 글자 `MONTMARTRE, PARIS, number 72831` |
| `clocks/s2_ep01_m3` | question, lead | guide("Drag the short hand…"), 시작 9:00, 시계판 |
| `compares/s2_ep02_m1` | 발견 줄 3, missLine, (Master) 체크리스트 = Master 메모 문장 | 변경 위치·ID, task |
| `studios/s2_ep02_m2` | 그림 3점 발견 줄, 책상·주변 5곳 줄, missLine, deskFirstLine | 매칭 조작 안내 4줄(`{note}` 포함), 그림 배치 순서 |
| `layers/s2_ep02_m3` | 발견 줄 3, missLine, paintLine | slideTask, findTask, 표식 위치 |
| `canvases/s2_ep02_final` | — | **전체 동일**: 조작 안내 + 캔버스 뒷면 메시지(증거 글귀) |
| `records/s2_ep03_m1` | — | **전체 동일**: 두 기록 문서 자체(퍼즐 자료) + 조작 안내 |
| `lifts/s2_ep03_m2` | — | **전체 동일**: 노선판·운행 기록(퍼즐 자료) + 조작 안내 |
| `dialLocks/s2_ep03_m3` | — | **전체 동일**: 조작 안내·버튼 |
| `evidenceBoards/s2_ep03_final` | — | **전체 동일**: 질문 3개(= 미션 선택지 라벨), 결론 3개(정답 선택지), 명판 |

"전체 동일" 5종은 `season2SameAtEveryLevel`로 명시하고 각 난이도 표에 **기준 객체 그 자체**를 등록했다(테스트가 `identical`을 확인) — 검토 후 의도적으로 유지한 것과 미작성으로 대체된 것을 구분하기 위함.

**구조 검사 추가**: PART 5에는 `ClockPuzzle`·`Discovery`·`LearningObjective`만 있었다. 이번에 쓴 장면 10종(`StationClocksScene`, `Exhibit`, `CompareScene`, `StudioScene`, `LayerScene`, `CanvasScene`, `RecordsScene`, `LiftScene`, `DialLockScene`, `EvidenceBoardScene`)의 구조 추출을 `lib/data/mock/season2/season2_structures.dart`에 두고, 공통 엔진에는 **한 줄**(`structureOf`가 먼저 `season2StructureOf`를 봄)만 추가했다. 추출 대상: 그림 파일·크기, 모든 영역·좌표(`Rect`/`Offset`의 `toString`은 소수 1자리로 반올림하므로 **전체 정밀도로 직접 기록**), ID와 순서, 시계 시각, 출발 시각표, 안내문과 강조 키, 기록 문서의 줄(DATE/JOB/TIME 값), 노선·정차 구역·운행표, 다이얼 기호·각도·시작 위치, 증거판 질문·증거·결론·명판 문구.

## 3. Case별 스토리 정리 (작성 전 확인)

### Case 01 — The Ticking Watch (Gare du Nord)
1. **시작**: 프롤로그(LONDON → PARIS, Gare du Nord, 10:00·10:00·9:00) 직후, 탐정이 역에 도착.
2. **인물**: 분실물 창구 직원(clerk), 회중시계를 든 남자(정체 미상), Clockmaker(표식만).
3. **알아야 할 것**: 옛 시계 하나가 한 시간 늦다 / 직원 메모의 순서 / 조각 글귀대로 시계를 앞으로 한 시간.
4. **숨길 것**: 남자가 시계를 바꿨는지(질문으로만), 표가 어디로 이끄는지(M2에서 Montmartre·painter 언급 금지), Clockmaker의 정체·방법.
5. **단서**: T(유리) · I(표 뒷면) · M(작은 문) · E(상자).
6. **퍼즐**: 시계 고르기 → 순서 배열(FIRST/NEXT/AFTER THAT) → 시계 바늘 10:00 → 글자 자물쇠 TIME.
7. **해결**: 상자 속 Montmartre 그림, 뒷면 FIND THE PAINTER, 같은 흰 성당이 표에도 있음.
8. **연결**: 그림·표 → Case 02 Montmartre.

### Case 02 — The Vanishing Painter (Montmartre)
1. **시작**: 그림 뒷면 FIND THE PAINTER와 표의 MONTMARTRE.
2. **인물**: 화가 P.(부재, 메모로만).
3. **알아야 할 것**: 메모의 ABOVE/MISSING/BESIDE, BEFORE/AFTER/WHEN, UNDERNEATH, "the gate is black".
4. **숨길 것**: Clockmaker, Case 03 장소(Eiffel 등 금지), 화가가 본 사람의 정체.
5. **단서**: 이 거리 아님(빨간 문) · 파란 하늘 · 계단·가로등·검은 문.
6. **퍼즐**: 틀린 그림 찾기 → 메모·그림 짝짓기 → 덧칠 밀어내기 → 세 단서로 캔버스 고르기.
7. **해결**: "I saw who took the hour. I went away to keep the secret safe." — 화가는 스스로 떠났다.
8. **연결**: TOUJOURS PLUS HAUT(Always higher) + 탑 스케치 → Case 03.

### Case 03 — The Tower's Secret (Eiffel Tower)
1. **시작**: 캔버스 뒷면의 탑 그림.
2. **인물**: 없음(기록·물건만).
3. **알아야 할 것**: 두 기록의 시각 차이(4:00/3:00), S = SERVICE RUN, 점검 순서 First/Next/Finally, 증거로 증명 가능한 결론만.
4. **숨길 것**: 시간이 실제로 사라졌다는 단정, Clockmaker, 명판을 둔 사람, 도입부에서 시각·"one hour".
5. **단서**: CHECK THE LIFT LOG · SERVICE ACCESS ONLY · 숨은 방(상자 자국).
6. **퍼즐**: 두 기록 비교 → 노선판으로 S 해석 → 다이얼 순서 → 증거판 연결·결론.
7. **해결**: ONE HOUR IS MISSING. THE CLOCK IS STILL RUNNING. / SEINE.
8. **연결**: FROM: SERVICE LEVEL. TO: THE RIVER. → Case 04.

## 4. Mission별 적용 현황

모든 미션: story · letterIntro · letter · question · hints(2) · successMessage · transition · 오답/선택지 줄 · clue note · evidence description · 장면 객체 · 학습 표현 — **Junior·Master 모두 작성**(아래 "의도적으로 같은 줄" 제외). Rookie = 기준본.

| 미션 | 유형 | 장면 | Junior | Master |
|---|---|---|---|---|
| s2_ep01_m1 The Three Clocks | multipleChoice | stationClocks | ✓(샘플 유지 + 나머지) | ✓(샘플 유지 + 나머지) |
| s2_ep01_m2 The Lost Ticket | sequence | exhibits | ✓ | ✓ |
| s2_ep01_m3 The Clockmaker's Mark | numberCode(시계) | clocks | ✓ | ✓ |
| s2_ep01_final The Hidden Compartment | letterLock | (lockBoxes: 그림 전용) | ✓ | ✓ |
| s2_ep02_m1 The Painted Street | spotDifferences | compares | ✓ | ✓ |
| s2_ep02_m2 The Artist's Studio | matchPairs | studios | ✓ | ✓ |
| s2_ep02_m3 The Hidden Layer | revealLayer | layers | ✓ | ✓ |
| s2_ep02_final Behind the Canvas | canvasChoice | canvases(동일) | ✓ | ✓ |
| s2_ep03_m1 The Two Notices | matchPairs | records(동일) | ✓ | ✓ |
| s2_ep03_m2 The Lift That Stopped | multipleChoice | lifts(동일) | ✓ | ✓ |
| s2_ep03_m3 Behind the Iron Door | sequence(다이얼) | dialLocks(동일) | ✓ | ✓ |
| s2_ep03_final The Missing Hour | matchPairs(증거판) | evidenceBoards(동일) | ✓ | ✓ |

## 5. 주요 문장 비교 (질문 · 성공 줄 = Discovery 제목)

| 미션 | Rookie | Junior | Master |
|---|---|---|---|
| 01 M1 Q | Which clock is one hour behind? | Which clock is running one hour behind? | Which clock has fallen one hour behind the others? |
| 01 M1 ✓ | The old clock is one hour behind! | The old clock is running one hour behind! | The old clock has fallen one hour behind! |
| 01 M2 Q | Put what happened in order. | In what order did these things happen? | Arrange the events in the order they happened. |
| 01 M2 ✓ | You put the events in order! | You put the events in the right order! | The events fall into place! |
| 01 M3 Q | Set the old clock to the right time. | What should the old clock show? Set its hands. | Set the old clock to the time the carving asks for. |
| 01 M3 ✓ | The old clock shows ten again! | The old clock shows ten o'clock again! | The old clock is back at ten! |
| 01 F Q | Make the word that opens the box. | Which word opens the box? Put the four letters in order. | Arrange the four letters into the word that opens the box. |
| 02 M1 Q | Find the three changes. | Find the three things he changed. | Spot the three changes the painter made. |
| 02 M1 ✓ | You found all three! | You found all three changes! | All three changes uncovered! |
| 02 M2 Q | Match each note to its painting. | Which painting goes with each note? Match them. | Pair each note with the painting it describes. |
| 02 M3 Q | Find the lamp, the steps and the gate. | Find the lamp, the steps and the gate in the sketch. | Uncover the sketch, then find its lamp, its steps and its gate. |
| 02 F Q | Which canvas hides the message? | Which canvas has the message on its back? | Which canvas is hiding the message? |
| 03 M1 Q | Which lines do not match? | Which two lines do not match? | Where do the two records disagree? |
| 03 M1 ✓ | The times do not match! | The times on the two records do not match! | The two records disagree on the time! |
| 03 M2 Q | Where did the lift go at 3:20? | At 3:20, where did the lift go? | Where was the lift heading at 3:20? |
| 03 M2 ✓ | You found the missing stop! | You found the stop that was missing from the log! | The unwritten stop is found! |
| 03 M3 ✓ | The lock is open! | The padlock is open! | The padlock gives way! |
| 03 F Q | Link the evidence to each question. | Link each question to the evidence that answers it. | Connect each question to the evidence that answers it. |

**도입부(intro) 예 — Case 01**
- Rookie: "The Clockmaker's watch is still ticking in your pocket. / Above the platforms, three clocks are ticking too."
- Junior: "You step off the train with the Clockmaker's watch in your pocket. / High above the platforms, three clocks are ticking."
- Master: "The Clockmaker's watch rests in your pocket as you step onto the platform. / … Yet no two of them seem to share the same time."

**편지(조각 글귀) 예 — Case 01 M3**
- Rookie: "The old clock is one hour behind. / Move its hands FORWARD one hour / to match the hall clock."
- Junior: "This clock is one hour behind. / Move its hands FORWARD one hour / so it matches the hall clock."
- Master: "This clock has fallen one hour behind. / Turn its hands FORWARD by one hour / until it agrees with the hall clock."

**메모 예 — Case 02 M2** (머리글 BEFORE THE RAIN / AFTER THE RAIN STOPPED / WHEN THE SKY TURNED GOLD는 모든 난이도 동일)
- Rookie: "Dark clouds were coming. The stones were still dry."
- Junior: "Dark clouds were coming, but the stones were still dry."
- Master: "Dark clouds were gathering, yet the stones were still dry."

## 6. Rookie 검토 결과

**결론: Rookie 문장은 바꾸지 않았다(기준본 유지).** Paris 기준본은 2026-10-26 "VERY EASY" 단순화를 거쳐 이미 짧은 문장·쉬운 단어·명확한 다음 행동 안내를 갖추고 있다. 문장을 바꾸면 기존 사용자 화면이 바뀌고(Q1), 다른 Case와의 연결 표현이 어긋날 위험이 있다. 대표 검토 사례:

- Case 02 Final "Below, in the same hand as FIND THE PAINTER:" — *in the same hand*(같은 필체)는 어린이에게 어려운 관용 표현이지만, 같은 표현이 Case 07("Is it the same hand?")과 위젯 고정 문구("Written in the same hand as FIND THE PAINTER.")에도 쓰인다. Rookie에서 Case 02만 바꾸면 시즌 내 표현이 어긋나므로 **문장은 유지하고 glossary에 `hand` = "손; (in the same hand) 같은 사람의 글씨로"를 추가**했다. Junior·Master는 "in the same handwriting"으로 썼다.
- Case 03 intro "two records describe the same inspection" — `describe`, `apart`, `agree` 등 glossary에 없던 단어를 추가.
- Case 03 Final 결론 "Someone went into the service area in the hour the records do not agree on." — Rookie에게 긴 문장이지만 정답 선택지이자 기존 테스트가 고정한 문장이고 증거판 객체 안에 있어 유지(남은 문제 §12-3).

**Rookie 개선 = 길게 누르면 뜻이 나오는 단어 추가(문장 불변)**:
- Case 01: events, order, pocket, hands(시계 바늘), heavy
- Case 02: alike, pinned, tucked, narrow, square(광장), uncovered, atelier, toujours, hand
- Case 03: describe, apart, agree, holder, staff, plaque, recording, piece, pieces, wheels, locked

## 7. Junior / Master 작성 원칙과 기준본 대비 개선 이유

- **Junior**: 기준본의 끊어진 명사구("Sunlight. The smell of paint.")를 자연스러운 문장으로 잇고, 접속어(but, so, and)와 이유·관계 표현을 더했다. 예: "Dark clouds were coming, **but** the stones were still dry." / 직원 메모에 "I wrote them down as I remembered them."를 붙여 *메모가 순서대로가 아님*을 스스로 알아차리게 했다. 질문은 의문문으로("In what order did these things happen?").
- **Master**: 어휘(gathering, lingered, smothered, deserted, concealed, scrawled), 분사·도치 구문("Beside the departure board hangs a printed notice."), 간접적인 단서 표현("Two of the clocks tell the same story.")을 쓰되 문장 하나가 두 줄을 넘지 않게 했다. 8–12세가 읽을 수 있도록 은유는 한 번에 하나, 추상어는 피했다.
- **조작 안내는 모든 난이도 동일**(Tap…, Drag…, Slide…, SOLVE THE CASE 등) — "Master라도 조작 방법은 명확하게".
- **사실관계 동일**: 시각(9:00/10:00, 3:00/4:00, 3:20, 4:25, 12 MAY), 숫자(72831), 색(검은 문), 위치(above/beside/underneath), 순서어(FIRST/NEXT/AFTER THAT/Finally)는 모든 난이도에서 같은 의미로 등장.

## 8. 힌트 난이도 비교 (개수 2·가격 Tip 1 무료/Tip 2 20코인·구매 기록 모두 불변)

| 미션 | Rookie (직접·구체) | Junior (단계적 연결) | Master (간접·관계 암시, 조작은 명확) |
|---|---|---|---|
| 01 M1 Tip 1 | Look at all three clocks. Two of them show the same time. | Compare the three clocks. Two of them agree with each other. | Two of the clocks tell the same story. Which one disagrees? |
| 01 M1 Tip 2 | Behind means one hour less. Which clock shows 9:00? | One hour behind means one hour less than the others. Which clock shows 9:00? | A clock one hour behind shows an hour less. Your notes hold the odd time out. |
| 01 M2 Tip 2 | FIRST is the hall clock. AFTER THAT is the old clock. What is in the middle? | Start with FIRST and finish with AFTER THAT. The NEXT line goes in between. | One line begins the story and one ends it. The remaining card fills the gap. |
| 01 F Tip 1 | The Clockmaker steals an hour. What word means hours and minutes? | The Clockmaker steals an hour. Which word means hours and minutes? | The Clockmaker steals an hour. What do hours and minutes add up to? |
| 02 M2 Tip 1 | Each note says WHEN he painted it. Check the clouds and the stones. | Each note says WHEN he painted it. Look at the clouds and the stones in each painting. | The sky alone can fool you. Each note gives two signs: the clouds and the stones. |
| 02 F Tip 2 | No red door. A blue sky. A black gate beside the steps. | You need: no red door, a blue sky, and a black gate beside the steps. | One canvas fails the street clue, one fails the sky and one fails the gate. Which one survives? |
| 03 M2 Tip 1 | Find the S in the lift log. Then find what S means on the route plate. | Find the S in the lift log. Then look for S on the route plate. | The log keeps a secret in a single letter. The route plate can explain it. |
| 03 F Tip 2 | Question 3 needs two pieces: where the lift went, and what was behind the door. | Question 3 needs two pieces: one shows where the lift went, one shows what was behind the door. | One question cannot be answered by a single piece. Pair the journey with its destination. |

- 모든 난이도·모든 힌트가 정답(선택형은 정답 라벨)을 포함하지 않음 — 프로젝트 기존 규칙과 같은 방식으로 테스트.
- Case 01 Final Tip 1의 "The Clockmaker steals an hour."는 **스토리 바이블 §1이 유지를 요구**하는 문장이라 세 난이도 모두 첫머리에 그대로 둠.
- Master의 Tip 2도 "어디를 볼지"는 분명히 말한다(예: 03 M2 "Once you know that S = SERVICE RUN, ask which stop only a service run can reach.").

## 9. 부모 보고서 학습 표현

| 미션 | Rookie | Junior | Master |
|---|---|---|---|
| 01 M1 | one hour behind · report it to the LOST PROPERTY DESK | running one hour behind · report it to the LOST PROPERTY DESK | fallen one hour behind the others · report it to the LOST PROPERTY DESK |
| 01 M2 | FIRST · NEXT · AFTER THAT | + In what order did these things happen? | + Arrange the events in the order they happened |
| 01 M3 | Move its hands FORWARD one hour · to match the hall clock | Move its hands FORWARD one hour · so it matches the hall clock | Turn its hands FORWARD by one hour · until it agrees with the hall clock |
| 01 F | LETTERS FOUND · hours and minutes | + Put the four letters in order | + Every clock measures it |
| 02 M1 | Look above the red door · Find the window that is missing · Check the lamp beside the steps | (같음) | Look above the red door · the window that has gone missing · Check the lamp beside the steps |
| 02 M2 | BEFORE THE RAIN · AFTER THE RAIN STOPPED · WHEN THE SKY TURNED GOLD | + Which painting goes with each note? | + Pair each note with the painting it describes |
| 02 M3 | Slide the paint away · look UNDERNEATH · the gate is black | Slide the paint away · look UNDERNEATH · remember this: the gate is black | Slide the paint away · look UNDERNEATH · Whatever he hid lies beneath the paint |
| 02 F | Not the street with the red door · One canvas matches all three | Not the street… · Only one canvas matches all three clues | Not the street… · Only one canvas fits every clue |
| 03 M1 | The same day. The same job. · Find the two lines that do not match | + Compare them line by line | The same day. The same job. · Somewhere, they disagree · Where do the two records disagree? |
| 03 M2 | One stop is not written · S = SERVICE RUN | (같음) | One stop has been left unwritten · S = SERVICE RUN |
| 03 M3 | First, check the clock. · Next, stop the lift. · Finally, turn the key. | (같음) | + the order the note demands |
| 03 F | What was wrong with the inspection records? · What can we conclude? | + the evidence that answers it | + what it proves, and what it does not |

- 모든 표현이 그 난이도의 실제 미션 화면 문장(스토리·편지 앞말·편지·질문·선택지·힌트)에 **단어 단위로** 있다(`LearningCheck`, 테스트 36 + 7A 테스트).
- "(같음)" 3곳은 퍼즐 자료 문장 자체가 학습 대상이라 같은 표현이 맞다(02 M1 Junior: 화가 메모의 지시문, 03 M2 Junior: 운행 기록 지시문, 03 M3 Junior: 점검 메모). 그래도 각 미션은 최소 두 난이도에서 서로 다른 표현을 갖는다(테스트).
- 학습 설계의 의존도(essential)·수준·기능·recallFrom은 기준과 동일. 목표(한국어) 문장은 인용 영어가 바뀐 01 M3(J·M), 02 M1(M)만 그 난이도 문장으로 바꿨다.
- 보고서는 그 시즌의 고정 난이도로 만들어진다(테스트: Paris를 각 난이도로 고정 → Case 02 보고서 = 그 난이도의 표현).

## 10. 의도적으로 같은 줄 (fallback이 아니라 검토 후 유지)

테스트 `keptAtEveryLevel`이 이 목록을 고정한다 — 이 밖에 Junior/Master가 기준본(또는 서로)과 같은 줄이 생기면 실패한다.

| 위치 | 문장 | 이유 |
|---|---|---|
| 01 M2 transition 1–3 | FIRST, the hall clock struck ten. / NEXT, a man with a pocket watch came in. / AFTER THAT, the old clock showed nine. | 직원 메모를 순서대로 다시 읽는 장면(퍼즐 자료 인용) |
| 01 F transition 3, 5 | The same white church is on the lost ticket. / FIND THE PAINTER. | 증거 연결 문구와 같은 사실, 그림 뒷면 글자 |
| 02 M1 transition 2 | "My secret is not on this street. Look far from the red door." | 화가의 글 인용 |
| 02 M2 transition 2 | "My secret is not in a gold sky. I hid it on a blue-sky day." | 화가의 글 인용 |
| 02 F transition 1, 2, 4, 5, 9 | ATELIER MONTMARTRE… / TOUJOURS PLUS HAUT. Always higher. / A city can lose an hour. But who can steal it? / "I saw who took the hour…" / But someone is still stealing the hours of Paris. | 캔버스 뒷면 글자·화가 인용·Case 03 시작점·사건 마지막 줄 |
| 02 F transition 6, 8 (Junior만) | He hid his own sketch. He left his notes for you. / He left on his own. | Junior는 기준본 문장이 이미 자연스러운 일상 영어 — Master는 자체 문장 |
| 03 M3 letter | INSPECTION STEPS / Finally, turn the key. / First, check the clock. / Next, stop the lift. | 점검 메모 자체가 퍼즐(순서어) |
| 03 F transition 1, 2, 4, 7–9 | One hour is missing. / The clock is still running. / SEINE. / FROM: SERVICE LEVEL. TO: THE RIVER. / Who left this message? / And why does it lead to the river? | 명판 글자·꼬리표 글자·Case 04로 넘기는 질문 |
| 03 F 오답 `q3:e3`, `why:vanished` | You found the room. But what shows that someone went up there? / We have no proof of that yet. | 증거로 증명되는 것만 말한다는 사건의 핵심 줄 |

이 밖에 모든 난이도에서 같은 퍼즐 자료: 역 안내문(STATION NOTICE), 직원 메모 3줄, 화가 메모 머리글, 덧칠 메모 지시문(Slide the paint away and look UNDERNEATH), Notebook의 YOUR CLUES 3줄, 시간 카드(OFFICIAL TIME — 4:00 / RECORDED TIME — 3:00), Case 01 Final 편지의 "The Clockmaker loves one thing most. He steals it. He hides it."(바이블 §1).

## 11. 프롤로그 연결 검토 (프롤로그는 이번에 수정하지 않음)

프롤로그(`season2PrologueJson`, 난이도 비대상 = 모든 난이도에서 기준본): THE LAST CLUE("The Clockmaker is gone. But his watch is still ticking.") → THE JOURNEY(LONDON → PARIS, 11:40) → GARE DU NORD("Look up at the station clocks...") → THE MISSING HOUR(10:00·10:00·9:00, "One hour is missing in Paris. Who took it? And why?") → PROMISE → Case 01 파일.

- **불필요한 반복**: Rookie Case 01 intro의 "The Clockmaker's watch is still ticking in your pocket."는 프롤로그 첫 장면과 거의 같은 문장이다. 시즌 연결을 다시 짚는 역할이라 Rookie에서는 유지했고, Junior("You step off the train with the Clockmaker's watch in your pocket.")·Master("…rests in your pocket as you step onto the platform.")는 반복 대신 *도착 동작*으로 이었다.
- **Case 01 시작의 자연스러움**: 프롤로그가 "Look up at the station clocks..."로 끝나고 Case 01 intro가 세 시계로 시작해 자연스럽다. 프롤로그가 이미 10/10/9를 보여 주지만 Case 01 M1은 *어느 시계가* 늦은지와 *안내문이 무엇을 하라는지*를 읽는 퍼즐이라 긴장감이 유지된다.
- **현재 상황 이해**: synopsis 마지막 줄 "This is where the missing hour begins."(R·J) / "Here, the mystery of the missing hour begins."(M)가 프롤로그의 THE MISSING HOUR와 이어진다.
- **수정 제안(미적용, 프롤로그 PART에서 결정)**:
  1. 프롤로그는 난이도 비대상이라 Master 플레이어도 Rookie 문장을 본다 — 프롤로그 PART에서 같은 엔진 확장(시즌 ID 패치)이 필요.
  2. 프롤로그 "One hour is missing in Paris."는 단정형이다. 바이블 §2.3·§8은 Case 03까지 "실제 시간 소멸" 단정을 피하므로, 프롤로그 Master 문장을 쓸 때 "One hour seems to be missing in Paris." 같은 완화형을 검토할 만하다(기준본 변경은 사용자 승인 필요).

## 12. 후반 사건 정보 노출 위험

세 난이도 모두 테스트로 확인:
- **Clockmaker 정체**: Case 02·03 전체 텍스트(장면 포함)에 "Clockmaker" 없음. Case 01은 "Clockmaker's mark/box/watch"만(별명, 시즌 1부터 공개).
- **회중시계 남자**: "Did the man change the old clock?"는 질문으로만(J: "You cannot be sure yet.", M: "Nothing proves it yet.") — 남자가 바꿨다고 단정하지 않음.
- **M2 표의 행선지**: Case 01 M2의 스토리·편지·질문·힌트·전환·단서·성공 줄에 montmartre/painter 없음.
- **Case 03 장소**: Case 02 전체에 Eiffel/Louvre/Notre/Opera/Seine 없음, 'gear'·'travel bag' 등 그림에 없는 것 없음.
- **시간 소멸 단정**: Case 03 전체에 "VANISHED FROM PARIS"(오답 결론 선택지 제외 — 장면 객체), "HOUR WAS STOLEN", "STOLE THE HOUR", "HOUR REALLY" 없음. `why:vanished` = "We have no proof of that yet." 유지. 바이블 §1 "실제 시간 소멸은 입증되지 않았다" 준수.
- **명판 선노출**: Case 03 Final 스토리·편지·힌트와 M3 전환에 SEINE·STILL RUNNING 없음.
- **TIME 선노출**: Case 01 Final 힌트·편지·스토리·질문·M3 전환에 TIME(대소문자 무시, "sometimes" 등 포함) 없음.
- **Case 03 도입부**: intro·synopsis·objectives·M1 스토리·편지·질문에 3:00/4:00/three/four/one hour 없음, 2인칭(I/my 없음).
- **Master의 간접 표현 점검**: "Who turned it back, and why?"(01 synopsis M)는 *누군가* 돌렸다는 기준본("Who changed it?")과 같은 수준의 가정이며 남자를 지목하지 않는다. "Why would a painter bury his own work?"(02 M3 M)는 같은 미션 메모("I painted over my sketch")가 곧 밝히는 사실.

## 13. Discovery 제목

- Paris Discovery 제목은 플레이 중 미션의 `successMessage`(PART 5). 세 Case 9개 일반 미션 × 3 난이도 모두 제목 = 그 난이도의 success 줄, Junior·Master 제목은 기준본과 다르고 세 난이도 제목이 서로 다름(기준본 누출 없음), Discovery 종류(deduction/clueFound/evidenceFound/newLead)는 동일 — 테스트.
- 제목이 결과를 미리 말하지 않는지 확인: 예) 03 M3(newLead) "The padlock is open!"/"The padlock gives way!" — 방 안의 내용은 다음 장면이 말함.

## 14. 검증

| 검증 | 결과 |
|---|---|
| `DifficultyContent.problems()` | 빈 목록 |
| `missingAt(s2_ep01~03, rookie/junior/master)` | 모두 빈 목록 |
| 구조 불변(`structureOfEpisode`), 정답·오답 판정(`AnswerChecker`), 옵션 ID·순서·라벨, 힌트 개수·가격, 코인 | 3 Case × 3 난이도 동일 |
| 장면 10종 구조 검사 + 조작 안내 동일 + 유지 객체 `identical` | 통과 |
| 추리 보호(위 §12) | 3 Case × 3 난이도 통과 |
| 학습 표현 일치 + 보고서(시즌 고정 난이도) | 통과 |
| Discovery 제목 | 통과 |
| glossary(각 난이도 패치의 단어가 그 난이도 본문에 있음) | 통과 — 이 검사가 Master Case 02의 잘못된 `alike` 항목을 잡아 수정함 |
| 저장 호환(난이도 없는 옛 저장 → Rookie = 기준본 문장, glossary만 증가) | 통과 |
| 화면(390×844): Case 01 M3를 각 난이도로 — 스토리·조각 글귀 앞말·편지·시계 질문/안내가 그 난이도 문장, 다른 난이도 문장은 없음, 조작 안내 동일 | 통과 |
| TESTER 난이도 전환 | 기존 `difficulty_content_test` D(19–24): 개발자 세션 Master에서 `s2_ep01_m1` 질문이 Master 문장, 플레이어 세션은 그대로 — 통과 |
| `flutter analyze` | No issues |
| 전체 `flutter test` | 2,386 통과 (기존 2,360 + 신규 26), 실패·skip 0 |

## 15. 남은 문제

1. **실기기·시각 확인 없음**: 화면 테스트는 390×844 Case 01 M3 한 곳. 긴 Master 문장(예: 02 F 선택지 d 오답 줄 "Remember the hidden sketch. His pencil had no colours, but his note told you the colour of the gate.")의 360×640·글자 1.3배 줄바꿈은 확인하지 않았다(기존 화면은 스크롤·줄바꿈 구조).
2. **프롤로그 난이도 미적용**(§11) — 별도 PART.
3. **장면 객체 안의 Rookie 문장**: Case 03 증거판 결론("…in the hour the records do not agree on.")·기록 문서 등 5종은 모든 난이도 동일. 결론 문장을 난이도별로 바꾸려면 증거판 결론 텍스트와 기존 고정 테스트(`paris_case03_test`)를 함께 다뤄야 한다.
4. **선택지 라벨 고정**: 선택지 라벨은 부모 보고서 정답표·장면 이름(THE HALL CLOCK 등)·증거판 질문과 연결되어 모든 난이도 동일. Master에서 질문문(evidence board questions)을 더 풍부하게 하려면 장면 객체와 선택지 라벨을 함께 바꾸는 별도 검토 필요.
5. **병합 주의**: 공통 엔진 변경은 `difficulty_content.dart` 한 줄(+import 한 줄)과 `season_catalog.dart`의 `writtenLevels: season2WrittenLevels` 한 줄. London 세션이 `structureOf` 시그니처 줄이나 `season2Content` 끝부분을 고치면 사소한 충돌 가능.
6. **문서 표 E(PART 상태)·G(다음 인수인계)는 London 세션과의 충돌을 피하려고 수정하지 않았다** — 7A 결과는 F의 PART 7A 절과 H의 Paris 행에만 기록. 병합 후 E의 PART 7 행을 "IN PROGRESS (7A 완료)"로 갱신 필요.

## 16. PART 7B 인수인계 (Case 04~06)

- 같은 파일 `season2_difficulty.dart`에 `_junior04…` 형식으로 추가하고 `season2WrittenLevels`에 등록. (실제로는 7B~7D가 묶음 파일로 만들었고, 지금은 Case별 `difficulty/epNN_levels.dart`에 두고 `season2_difficulty.dart`에서 등록한다.) 장면 객체는 이 PART의 빌더 패턴(기준 객체에서 구조 필드 복사)을 따른다.
- 새로 쓰는 장면 종류(Case 04 `riverMarks`·`keeperHuts`·`quayBoxes`, Case 05 `streetBooks`·`markCompares`·`clockWalls`, Case 06 `postTrails`·`holdRacks`·`planRoutes`·`archives`·`letterMaps`…, EasySteps `Case 04 Final`, `Case 05 M3·Final`)마다 **먼저 `season2StructureOf`에 구조 추출을 추가**해야 `problems()`가 통과한다. EasySteps는 무료·무제한 힌트와 정답 위치 강조가 구조.
- Case 03 → 04 연결(SEINE, FROM: SERVICE LEVEL. TO: THE RIVER., 사라진 상자)과 Case 05 우편 기록(16 MAY 9:00/11:00/4:00 HELD)은 바이블 §1 고정 사실.
- 7A 테스트의 `keptAtEveryLevel` 방식(의도적으로 같은 줄을 명시하고 나머지는 모두 달라야 함)을 Case 04~06에도 적용 권장.

---

## 부록 A. 전체 문장 표 (실제 적용 콘텐츠에서 자동 추출)

- 표기: `= Rookie` = Rookie(기준본)와 같은 문장, `= Junior` = Junior와 같은 문장. `/` = 줄바꿈 또는 목록 구분.
- `scene …` 행 = 장면 객체의 문장, `learning …` 행 = 부모 보고서 학습 표현.
- "전체 동일" 장면 5종(§2)의 문장은 표에 싣지 않았다(모든 난이도에서 기준본 그대로).

### s2_ep01 — The Ticking Watch

| 위치 | Rookie (기준본) | Junior | Master |
|---|---|---|---|
| `intro` | Paris. Gare du Nord. / The Clockmaker's watch is still ticking in your pocket. / Above the platforms, three clocks are ticking too. / But they do not show the same time. | Paris. Gare du Nord. / You step off the train with the Clockmaker's watch in your pocket. / High above the platforms, three clocks are ticking. / But they do not show the same time. | Paris. Gare du Nord. / The Clockmaker's watch rests in your pocket as you step onto the platform. / High above the trains, three clocks are ticking. / Yet no two of them seem to share the same time. |
| `synopsis` | The clocks at Gare du Nord show different times. / One clock is an hour behind. Who changed it? / This is where the missing hour begins. | The clocks at Gare du Nord do not agree. / One of them is running an hour behind. Who changed it, and why? / This is where the missing hour begins. | The clocks of Gare du Nord refuse to agree. / One has slipped an hour behind the rest. Who turned it back, and why? / Here, the mystery of the missing hour begins. |
| `objectives` | Find the clock that is wrong. / Find out who changed it. / Open what the old clock is hiding. | Find the clock that is running behind. / Work out what happened, and in what order. / Open what the old clock is hiding. | Find the clock that has fallen behind. / Piece together what happened, and when. / Discover what the old clock is hiding. |
| `caseSummary` | You found the wrong clock, put the events in order and opened the Clockmaker's box. | You found the clock that was running behind, put the events in order and opened the Clockmaker's box. | You exposed the clock that had fallen behind, pieced the events together and opened the Clockmaker's box. |
| `hook` | Inside the box is a painting of Montmartre. On the back: FIND THE PAINTER. | Inside the box is a painting of Montmartre. On the back, three words: FIND THE PAINTER. | Inside the box lies a painting of Montmartre. On its back, a command: FIND THE PAINTER. |
| `s2_ep01_m1.story` | The station hall is busy. / Under the glass roof, three clocks are ticking. | The station hall is full of busy travellers. / High under the glass roof, three clocks keep ticking. | The station hall hums with hurrying travellers. / High beneath the glass roof, three clocks tick away. But do they all agree? |
| `s2_ep01_m1.letterIntro` | A notice hangs beside the departure board. | A notice hangs next to the departure board. | Beside the departure board hangs a printed notice. |
| `s2_ep01_m1.letter` | STATION NOTICE /  / All our clocks show Paris time. / If one clock is ONE HOUR BEHIND, / report it to the LOST PROPERTY DESK. /  / YOUR NOTES / The hall clock shows 10:00. / The platform clock shows 10:00. / The old clock shows 9:00. | STATION NOTICE /  / All our clocks show Paris time. / If one clock is ONE HOUR BEHIND, / report it to the LOST PROPERTY DESK. /  / YOUR NOTES / The hall clock says 10:00. / The platform clock says 10:00. / The old clock says 9:00. | STATION NOTICE /  / All our clocks show Paris time. / If one clock is ONE HOUR BEHIND, / report it to the LOST PROPERTY DESK. /  / YOUR NOTES / The great hall clock reads 10:00. / The platform clock reads 10:00. / The old brass clock reads 9:00. |
| `s2_ep01_m1.question` | Which clock is one hour behind? | Which clock is running one hour behind? | Which clock has fallen one hour behind the others? |
| `s2_ep01_m1.hints[1]` | Look at all three clocks. Two of them show the same time. | Compare the three clocks. Two of them agree with each other. | Two of the clocks tell the same story. Which one disagrees? |
| `s2_ep01_m1.hints[2]` | Behind means one hour less. Which clock shows 9:00? | One hour behind means one hour less than the others. Which clock shows 9:00? | A clock one hour behind shows an hour less. Your notes hold the odd time out. |
| `s2_ep01_m1.successMessage` | The old clock is one hour behind! | The old clock is running one hour behind! | The old clock has fallen one hour behind! |
| `s2_ep01_m1.transition[1]` | The old clock shows nine. The others show ten. | The old clock says nine. The other two say ten. | The old clock reads nine, while the others read ten. |
| `s2_ep01_m1.transition[2]` | A letter is scratched on its glass: T. | Someone has scratched a letter on its glass: T. | Someone has scratched a single letter into its glass: T. |
| `s2_ep01_m1.transition[3]` | Now go to the Lost Property desk. | Next stop: the Lost Property desk. | The notice is clear. The Lost Property desk is next. |
| `s2_ep01_m1.option a feedback` | The hall clock shows 10:00, like the platform clock. Which one is different? | The hall clock shows 10:00, the same as the platform clock. Look for the one that disagrees. | The hall clock reads 10:00, exactly like the platform clock. The odd one out must be elsewhere. |
| `s2_ep01_m1.option b feedback` | The platform clock shows 10:00, like the hall clock. Which one is different? | The platform clock shows 10:00, the same as the hall clock. Look for the one that disagrees. | The platform clock reads 10:00, exactly like the hall clock. The odd one out must be elsewhere. |
| `s2_ep01_m1.clue.note` | The old clock is one hour behind. On its glass: T. | The old clock is running one hour behind. Scratched on its glass: T. | The old clock has fallen one hour behind. Scratched into its glass: T. |
| `s2_ep01_m1.evidence.description` | It hangs beside the departure board. | It hangs next to the departure board in the station hall. | A printed notice beside the departure board, easy to walk past. |
| `s2_ep01_m1 scene stationClocks.missLine` | Nothing here. Look at the clocks and the departure board. | There is nothing here. Look at the clocks and the departure board. | Nothing of interest here. The clocks and the departure board matter more. |
| `s2_ep01_m1 scene stationClocks.boardFirstLine` | What should you report? Read the departure board first. | = Rookie | What is there to report? The departure board will tell you. Read it first. |
| `s2_ep01_m1 scene stationClocks.clocksFirstLine` | Look at all three clocks first. Which one is different? | = Rookie | Study all three clocks first. Which one is out of step? |
| `s2_ep01_m1 scene stationClocks.others[1] (Wooden benches)` | Wooden benches. People wait here for their trains. | Wooden benches. People sit here and wait for their trains. | Wooden benches, worn smooth by travellers waiting for their trains. |
| `s2_ep01_m1 scene stationClocks.others[2] (A train at the platform)` | A train is waiting at the platform. | = Rookie | A train stands ready at the platform. |
| `s2_ep01_m1 scene stationClocks.others[3] (A luggage trolley)` | Suitcases on a trolley. They are all locked. | Suitcases on a trolley. Every one of them is locked. | Suitcases piled on a trolley, every one of them locked tight. |
| `s2_ep01_m1 scene stationClocks.others[4] (Stone statues)` | Stone statues. They are not telling you anything. | Stone statues. They cannot tell you anything. | Stone statues gaze down at the hall. They keep their secrets. |
| `s2_ep01_m1 scene stationClocks.others[5] (The glass roof)` | The glass roof. The morning light comes in. | The glass roof. Morning light shines in. | The glass roof. Morning light pours in from above. |
| `learning s2_ep01_m1` | "one hour behind", "report it to the LOST PROPERTY DESK" | "running one hour behind", "report it to the LOST PROPERTY DESK" | "fallen one hour behind the others", "report it to the LOST PROPERTY DESK" |
| `s2_ep01_m2.story` | The clerk shows you a train ticket. / Someone dropped it under the old clock this morning. | The clerk at the desk holds up a train ticket. / Someone dropped it under the old clock this morning. | Behind the Lost Property desk, the clerk holds up a crumpled train ticket. / It was found under the old clock early this morning. |
| `s2_ep01_m2.letterIntro` | The clerk gives you the ticket and her notes. | She hands you the ticket and her notes. | She passes you the ticket, along with her hurried notes. |
| `s2_ep01_m2.letter` | CLERK'S NOTES /  / AFTER THAT, the old clock showed nine. / FIRST, the hall clock struck ten. / NEXT, a man with a pocket watch came in. /  / — Lost Property, Gare du Nord | CLERK'S NOTES /  / AFTER THAT, the old clock showed nine. / FIRST, the hall clock struck ten. / NEXT, a man with a pocket watch came in. /  / I wrote them down as I remembered them. / — Lost Property, Gare du Nord | CLERK'S NOTES /  / AFTER THAT, the old clock showed nine. / FIRST, the hall clock struck ten. / NEXT, a man with a pocket watch came in. /  / (Written in a hurry, not in order.) / — Lost Property, Gare du Nord |
| `s2_ep01_m2.question` | Put what happened in order. | In what order did these things happen? | Arrange the events in the order they happened. |
| `s2_ep01_m2.hints[1]` | Find the order words: FIRST, NEXT and AFTER THAT. | Look for the order words: FIRST, NEXT and AFTER THAT. Each one starts a line. | The clerk wrote in a hurry. Her order words matter more than the order of her lines. |
| `s2_ep01_m2.hints[2]` | FIRST is the hall clock. AFTER THAT is the old clock. What is in the middle? | Start with FIRST and finish with AFTER THAT. The NEXT line goes in between. | One line begins the story and one ends it. The remaining card fills the gap. |
| `s2_ep01_m2.successMessage` | You put the events in order! | You put the events in the right order! | The events fall into place! |
| `s2_ep01_m2.transition[1]` | FIRST, the hall clock struck ten. | = Rookie | = Rookie |
| `s2_ep01_m2.transition[2]` | NEXT, a man with a pocket watch came in. | = Rookie | = Rookie |
| `s2_ep01_m2.transition[3]` | AFTER THAT, the old clock showed nine. | = Rookie | = Rookie |
| `s2_ep01_m2.transition[4]` | Did the man change the old clock? | Did the man change the old clock? You cannot be sure yet. | Did the man turn the old clock back? Nothing proves it yet. |
| `s2_ep01_m2.transition[5]` | On the back of the ticket is a letter: I. | On the back of the ticket, there is a small letter: I. | On the back of the ticket, a small letter is written: I. |
| `s2_ep01_m2.orderFeedback` | Read the notes again. What happened FIRST? NEXT? AFTER THAT? | Look at the notes again. Which came FIRST, which came NEXT, and which came AFTER THAT? | The cards are right, but the order is not. Let FIRST, NEXT and AFTER THAT guide you. |
| `s2_ep01_m2.feedback["c,b,a"]` | The man came NEXT. What happened FIRST? | The man came in NEXT, not first. What happened FIRST? | The man arrived NEXT. Something else came FIRST. |
| `s2_ep01_m2.feedback["b,a,c"]` | The old clock changed AFTER THAT, at the end. What came NEXT? | The old clock changed AFTER THAT, at the very end. So what came NEXT? | The old clock changed AFTER THAT, at the very end. What happened in between? |
| `s2_ep01_m2.clue.note` | The man came in before the old clock went back. On the ticket: I. | The man came in before the old clock went back an hour. On the back of the ticket: I. | The man arrived before the old clock went back an hour. On the back of the ticket: I. |
| `s2_ep01_m2.evidence.description` | Dropped under the old clock this morning. | Someone dropped it under the old clock this morning. | Found under the old clock early this morning. |
| `s2_ep01_m2 scene exhibit.description` | An old train ticket. PARIS on the red stub. A white church in the middle. On the right: MONTMARTRE, PARIS, number 72831. | An old train ticket. On the red stub: PARIS. In the middle: a white church. On the right: MONTMARTRE, PARIS, number 72831. | A worn train ticket: PARIS on its red stub, a white church printed in the middle, and on the right MONTMARTRE, PARIS, number 72831. |
| `s2_ep01_m2 scene exhibit.caption` | Someone dropped it under the old clock this morning. | = Rookie | Found under the old clock early this morning. |
| `learning s2_ep01_m2` | "FIRST", "NEXT", "AFTER THAT" | "FIRST", "NEXT", "AFTER THAT", "In what order did these things happen?" | "FIRST", "NEXT", "AFTER THAT", "Arrange the events in the order they happened" |
| `s2_ep01_m3.story` | You climb the iron steps to the old clock. / A message is carved into its brass frame. | You climb the iron steps up to the old clock. / Someone has carved a message into its brass frame. | You climb the narrow iron steps up to the old clock. / Carved into its brass frame, a message is waiting. |
| `s2_ep01_m3.letterIntro` | The carving says: | The carving reads: | The carved words read: |
| `s2_ep01_m3.letter` | The old clock is one hour behind. / Move its hands FORWARD one hour / to match the hall clock. /  / Under the words: a tiny gear. | This clock is one hour behind. / Move its hands FORWARD one hour / so it matches the hall clock. /  / Below the words: a tiny carved gear. | This clock has fallen one hour behind. / Turn its hands FORWARD by one hour / until it agrees with the hall clock. /  / Beneath the words: a tiny carved gear. |
| `s2_ep01_m3.question` | Set the old clock to the right time. | What should the old clock show? Set its hands. | Set the old clock to the time the carving asks for. |
| `s2_ep01_m3.hints[1]` | The old clock shows 9:00. FORWARD means later. | The old clock shows 9:00 now. FORWARD one hour means one hour later. | Where does the old clock stand now? FORWARD always means later. |
| `s2_ep01_m3.hints[2]` | The short hand moves to the next number. The long hand stays on 12. | Move the short hand to the next number. Leave the long hand on 12. | Only the short hand needs to travel, one number on. The long hand stays at the top. |
| `s2_ep01_m3.successMessage` | The old clock shows ten again! | The old clock shows ten o'clock again! | The old clock is back at ten! |
| `s2_ep01_m3.transition[1]` | The old clock chimes ten. | Ding, ding! The old clock chimes ten. | The old clock chimes ten, loud and clear. |
| `s2_ep01_m3.transition[2]` | A small brass box slides out. | Click! A small brass box slides out from under it. | With a soft click, a small brass box slides out from beneath it. |
| `s2_ep01_m3.transition[3]` | Its lock has four letter slots. One letter is carved on it: E. | Its lock has four slots for letters. One letter is carved on the box: E. | Its lock has four letter slots. A single letter is carved into the lid: E. |
| `s2_ep01_m3.feedback["900"]` | That is the time now. Move the hands FORWARD. | That is the time it shows now. Move the hands FORWARD. | The clock already shows that. The carving says FORWARD. |
| `s2_ep01_m3.feedback["800"]` | That is one hour BACK. FORWARD means later. | That moves it one hour BACK. FORWARD means later. | That turns it BACK an hour. FORWARD means later, not earlier. |
| `s2_ep01_m3.feedback["1100"]` | That is two hours. The carving says ONE hour. | That is two hours forward. The carving says ONE hour. | Two hours is too far. The carving asks for just ONE. |
| `s2_ep01_m3.clue.note` | The old clock shows ten again. A little door opened: M. | The old clock shows ten again. Behind a little door: M. | Put right, the old clock opened a little door. Inside: M. |
| `s2_ep01_m3.evidence.description` | Carved into the old clock. | Carved into the frame of the old clock. | Carved into the brass frame of the old clock. |
| `s2_ep01_m3 scene clock.question` | Move the old clock's hands forward one hour. | Move the old clock's hands one hour forward. | Turn the old clock's hands one hour forward. |
| `s2_ep01_m3 scene clock.lead` | The carving says how to put the old clock right. | The carving tells you how to fix the old clock. | The carving explains how to put the old clock right. |
| `learning s2_ep01_m3` | "Move its hands FORWARD one hour", "to match the hall clock" | "Move its hands FORWARD one hour", "so it matches the hall clock" | "Turn its hands FORWARD by one hour", "until it agrees with the hall clock" |
| `s2_ep01_final.story` | The brass box is small and heavy. / Inside, something is ticking. | The brass box is small but heavy. / Something inside it is ticking. | The brass box is small, but surprisingly heavy. / From somewhere inside, something is ticking. |
| `s2_ep01_final.letterIntro` | Your notebook says: | You open your notebook: | Your notebook reads: |
| `s2_ep01_final.letter` | LETTERS FOUND /  / T — scratched on the old clock / I — on the lost ticket / M — behind the Clockmaker's mark / E — carved on the box /  / The Clockmaker loves one thing most. / He steals it. He hides it. | LETTERS FOUND /  / T — scratched on the old clock / I — on the back of the lost ticket / M — behind the Clockmaker's mark / E — carved on the box /  / The Clockmaker loves one thing most. / He steals it. He hides it. | LETTERS FOUND /  / T — scratched into the old clock's glass / I — on the back of the lost ticket / M — behind the Clockmaker's mark / E — carved into the box /  / The Clockmaker loves one thing most. / He steals it. He hides it. |
| `s2_ep01_final.question` | Make the word that opens the box. | Which word opens the box? Put the four letters in order. | Arrange the four letters into the word that opens the box. |
| `s2_ep01_final.hints[1]` | The Clockmaker steals an hour. What word means hours and minutes? | The Clockmaker steals an hour. Which word means hours and minutes? | The Clockmaker steals an hour. What do hours and minutes add up to? |
| `s2_ep01_final.hints[2]` | Clocks show the T _ _ E. | Clocks show the T _ _ E. Fill in the two letters in the middle. | Every clock measures it. It begins with T and ends with E. |
| `s2_ep01_final.successMessage` | The box clicks open! | Click! The box opens! | With a click, the lid springs open! |
| `s2_ep01_final.transition[1]` | The lid lifts. Inside is a small painting. | The lid opens. Inside is a small painting. | The lid lifts. On red velvet lies a small painting. |
| `s2_ep01_final.transition[2]` | Montmartre: a white church on a hill, / above the roofs of Paris. | It shows Montmartre: a white church on a hill, / above the roofs of Paris. | Montmartre: a white church on a hill, / high above the roofs of Paris. |
| `s2_ep01_final.transition[3]` | The same white church is on the lost ticket. | = Rookie | = Rookie |
| `s2_ep01_final.transition[4]` | On the back, three words: | On the back, someone has written three words: | Turned over, it carries three words: |
| `s2_ep01_final.transition[5]` | FIND THE PAINTER. | = Rookie | = Rookie |
| `s2_ep01_final.orderFeedback` | Right letters. Try another order. What does a clock show? | The letters are right, but the order is not. What does every clock show? | The right letters in the wrong order. What does every clock measure? |
| `s2_ep01_final.feedback["ITEM"]` | ITEM is a real word, but not this one. What does a clock show? | ITEM is a real word, but it is not the one. What does a clock show? | ITEM is a real word, but not the right one. Think of what a clock measures. |
| `s2_ep01_final.feedback["EMIT"]` | EMIT is a real word, but not this one. What does a clock show? | EMIT is a real word, but it is not the one. What does a clock show? | EMIT is a real word, but not the right one. Think of what a clock measures. |
| `s2_ep01_final.feedback["MITE"]` | MITE is a real word, but not this one. What does a clock show? | MITE is a real word, but it is not the one. What does a clock show? | MITE is a real word, but not the right one. Think of what a clock measures. |
| `s2_ep01_final.evidence.description` | Found in the hidden box. | Found inside the hidden box. | Found on red velvet inside the hidden box. |
| `learning s2_ep01_final` | "LETTERS FOUND", "hours and minutes" | "LETTERS FOUND", "hours and minutes", "Put the four letters in order" | "LETTERS FOUND", "hours and minutes", "Every clock measures it" |

### s2_ep02 — The Vanishing Painter

| 위치 | Rookie (기준본) | Junior | Master |
|---|---|---|---|
| `intro` | Montmartre, a hill high above Paris. / The lost ticket said MONTMARTRE. The painting shows this hill. / On its back: FIND THE PAINTER. / Who is he? And why was his painting under an old clock? | Montmartre, a hill high above Paris. / The lost ticket said MONTMARTRE, and the painting shows this hill. / On its back: FIND THE PAINTER. / Who is he? And why was his painting hidden under an old clock? | Montmartre: a hill of narrow streets, high above Paris. / The lost ticket read MONTMARTRE, and the painting shows this very hill. / On its back: FIND THE PAINTER. / But who is he? And why was his painting waiting beneath an old clock? |
| `synopsis` | The painting from the brass box shows Montmartre. / On its back: FIND THE PAINTER. / But the painter has vanished. Does he know who took the hour? | The painting from the brass box shows Montmartre. / On the back, someone wrote: FIND THE PAINTER. / But the painter has disappeared. Does he know who took the hour? | The painting from the brass box shows Montmartre. / On its back, a command: FIND THE PAINTER. / Yet the painter has vanished. Could he know who took the hour? |
| `objectives` | Find the street in the painting. / Search the painter's studio. / Find the message he left behind. | Find the street from the painting. / Search the painter's studio for clues. / Find the message he left behind. | Track down the street in the painting. / Search the painter's deserted studio. / Uncover the message he left behind. |
| `caseSummary` | Three of the painter's clues led you to his hidden message. | You followed three of the painter's clues to his hidden message. | Three of the painter's clues, read together, led you to his hidden message. |
| `hook` | Nobody took the painter. He left to keep a secret. But who took the hour? | Nobody took the painter. He went away to keep a secret. But who took the hour? | Nobody took the painter. He slipped away to keep a secret safe. But who took the hour? |
| `s2_ep02_m1.story` | Near the white church: a quiet street. A red door. Stone steps. An old lamp. / On the corner, an easel holds a painting of this street. Nobody is painting. | Near the white church is a quiet street with a red door, stone steps and an old lamp. / On the corner stands an easel with a painting of this street. But nobody is painting. | Close to the white church lies a quiet street: a red door, worn stone steps, an old lamp. / At the corner, an easel holds a painting of this very street. The painter is nowhere to be seen. |
| `s2_ep02_m1.letterIntro` | A note is pinned to the painting: | Someone has pinned a note to the painting: | A note is pinned to the corner of the painting: |
| `s2_ep02_m1.letter` | I did not paint this street as it is. / I changed three things. /  / Look above the red door. / Find the window that is missing. / Check the lamp beside the steps. /  / — P. | I did not paint this street exactly as it is. / I changed three things. /  / Look above the red door. / Find the window that is missing. / Check the lamp beside the steps. /  / — P. | I did not paint this street as it truly is. / Three things are different. /  / Look above the red door. / Seek out the window that has gone missing. / Check the lamp beside the steps. /  / — P. |
| `s2_ep02_m1.question` | Find the three changes. | Find the three things he changed. | Spot the three changes the painter made. |
| `s2_ep02_m1.hints[1]` | Each line of the note tells you where to look. | Each line of the note tells you where to look. Read them one by one. | The note is a map: each line points to one place. Compare that place on the street and in the painting. |
| `s2_ep02_m1.hints[2]` | ABOVE means higher than. MISSING means it is not there. BESIDE means next to. | ABOVE means higher up. MISSING means it is not there. BESIDE means right next to. | What sits ABOVE the door? What has gone MISSING? What looks different BESIDE the steps? |
| `s2_ep02_m1.successMessage` | You found all three! | You found all three changes! | All three changes uncovered! |
| `s2_ep02_m1.transition[1]` | You turn his note over. One more line: | You turn his note over. There is one more line: | You turn his note over. One more line is written on the back: |
| `s2_ep02_m1.transition[2]` | "My secret is not on this street. Look far from the red door." | = Rookie | = Rookie |
| `s2_ep02_m1.transition[3]` | Under the easel, you find a key. Its tag says: STUDIO, TOP FLOOR. | You find a key under the easel. Its tag says: STUDIO, TOP FLOOR. | Beneath the easel lies a key. Its tag reads: STUDIO, TOP FLOOR. |
| `s2_ep02_m1.clue.note` | On the back: "My secret is not on this street. Look far from the red door." | On the back of his note: "My secret is not on this street. Look far from the red door." | Written on the back of his note: "My secret is not on this street. Look far from the red door." |
| `s2_ep02_m1.evidence.description` | Left on the easel, on the corner of the street. | Left on the easel at the corner of the street. | Left behind on the easel at the corner of the street. |
| `s2_ep02_m1 scene compare.missLine` | The same on both. Read the note again. | This looks the same in both. Read the note again. | No difference here. Let the note guide you. |
| `s2_ep02_m1 scene compare.found[clock]` | Above the red door: a small clock. The street has none. | Above the red door, the painting has a small clock. The real street has none. | A small clock hangs above the red door, but only in the painting. |
| `s2_ep02_m1 scene compare.found[window]` | The street has a window here. In the painting, it is missing. | = Rookie | The real street has a window here. The painter left it out. |
| `s2_ep02_m1 scene compare.found[lamp]` | The lamp beside the steps is bright in the painting. On the street, it is not. | In the painting, the lamp beside the steps is bright. On the street, it is not. | In the painting, the lamp beside the steps glows brightly. On the street, its flame is small. |
| `s2_ep02_m1 scene compare.checklist[clock]` | Look above the red door. | = Rookie | = Rookie |
| `s2_ep02_m1 scene compare.checklist[window]` | Find the window that is missing. | = Rookie | Seek out the window that has gone missing. |
| `s2_ep02_m1 scene compare.checklist[lamp]` | Check the lamp beside the steps. | = Rookie | = Rookie |
| `learning s2_ep02_m1` | "Look above the red door", "Find the window that is missing", "Check the lamp beside the steps" | = Rookie | "Look above the red door", "the window that has gone missing", "Check the lamp beside the steps" |
| `s2_ep02_m2.story` | The key opens a door at the top of narrow stairs. / Sunlight. The smell of paint. Nobody is here. | The key opens a door at the top of some narrow stairs. / Sunlight. The smell of paint. But the studio is empty. | The key turns in a door at the top of a narrow, creaking staircase. / Sunlight pours in. The air smells of paint. The studio is deserted. |
| `s2_ep02_m2.letterIntro` | Three notes lie on his desk: | There are three notes on his desk: | Three notes lie side by side on his desk: |
| `s2_ep02_m2.letter` | A — I painted this BEFORE THE RAIN. / Dark clouds were coming. The stones were still dry. /  / B — I painted this AFTER THE RAIN STOPPED. / The stones were wet and shiny. Some dark clouds were still there. /  / C — I painted this WHEN THE SKY TURNED GOLD. / The whole sky was gold. No dark clouds. The stones were dry. | A — I painted this BEFORE THE RAIN. / Dark clouds were coming, but the stones were still dry. /  / B — I painted this AFTER THE RAIN STOPPED. / The stones were wet and shiny. A few dark clouds were still in the sky. /  / C — I painted this WHEN THE SKY TURNED GOLD. / The whole sky was gold, with no dark clouds. The stones were dry. | A — I painted this BEFORE THE RAIN. / Dark clouds were gathering, yet the stones were still dry. /  / B — I painted this AFTER THE RAIN STOPPED. / The stones gleamed, wet and shiny, and a few dark clouds still lingered. /  / C — I painted this WHEN THE SKY TURNED GOLD. / The whole sky glowed gold, without a single dark cloud. The stones were dry. |
| `s2_ep02_m2.question` | Match each note to its painting. | Which painting goes with each note? Match them. | Pair each note with the painting it describes. |
| `s2_ep02_m2.hints[1]` | Each note says WHEN he painted it. Check the clouds and the stones. | Each note says WHEN he painted it. Look at the clouds and the stones in each painting. | The sky alone can fool you. Each note gives two signs: the clouds and the stones. |
| `s2_ep02_m2.hints[2]` | BEFORE THE RAIN, the stones are dry. AFTER THE RAIN, they are wet and shiny. | BEFORE THE RAIN: dry stones. AFTER THE RAIN: wet, shiny stones. Which one has a gold sky and no clouds? | Wet, shiny stones can only come AFTER the rain. Which painting has dark clouds over dry stones? |
| `s2_ep02_m2.successMessage` | Every note has its painting! | Each note has its painting! | Every note is matched to its painting! |
| `s2_ep02_m2.transition[1]` | Under note C, one more line in pencil: | Under note C, there is one more line in pencil: | Beneath note C, a final line in pencil: |
| `s2_ep02_m2.transition[2]` | "My secret is not in a gold sky. I hid it on a blue-sky day." | = Rookie | = Rookie |
| `s2_ep02_m2.transition[3]` | By the window, a big easel holds a canvas of thick paint. | By the window, a big easel holds a canvas covered in thick paint. | By the window, a big easel holds a canvas smothered in thick paint. |
| `s2_ep02_m2.feedback["a:p1"]` | Read note A again. Where are the dark clouds? | Look at note A again. Can you see the dark clouds in this painting? | Note A mentions dark clouds. Do you see any here? |
| `s2_ep02_m2.feedback["a:p3"]` | Read note A again. BEFORE THE RAIN, the stones were still dry. | Look at note A again. BEFORE THE RAIN, the stones were still dry. | Note A was painted BEFORE THE RAIN. The stones should still be dry. |
| `s2_ep02_m2.feedback["b:p1"]` | Read note B again. AFTER THE RAIN, the stones are wet and shiny. | Look at note B again. AFTER THE RAIN, the stones are wet and shiny. | Note B comes AFTER THE RAIN. Look for stones that are wet and shiny. |
| `s2_ep02_m2.feedback["b:p2"]` | Read note B again. AFTER THE RAIN, the stones are wet and shiny. | Look at note B again. AFTER THE RAIN, the stones are wet and shiny. | Note B comes AFTER THE RAIN. Look for stones that are wet and shiny. |
| `s2_ep02_m2.feedback["c:p2"]` | Read note C again. Is the whole sky gold? | Look at note C again. Is the whole sky gold here? | Note C describes a whole sky of gold. Is that what you see? |
| `s2_ep02_m2.feedback["c:p3"]` | Read note C again. No dark clouds, and dry stones. | Look at note C again. There are no dark clouds, and the stones are dry. | Note C has no dark clouds and dry stones. Look again. |
| `s2_ep02_m2.clue.note` | Under note C: "My secret is not in a gold sky. I hid it on a blue-sky day." | Written under note C: "My secret is not in a gold sky. I hid it on a blue-sky day." | Pencilled under note C: "My secret is not in a gold sky. I hid it on a blue-sky day." |
| `s2_ep02_m2.evidence.description` | On his desk, beside his paintings of one square. | Found on his desk, next to his paintings of one square. | Lying on his desk, beside his paintings of one square. |
| `s2_ep02_m2 scene studio.missLine` | Nothing here. Where would he put things away? | Nothing here. Where would a painter put things away? | Nothing of interest. Where might a painter tuck things away? |
| `s2_ep02_m2 scene studio.deskFirstLine` | Three notes. Find the paintings first. Where did he put them away? | Three notes. But first, find the paintings. Where did he put them away? | Three notes, but they need their paintings. Where did he put them away? |
| `s2_ep02_m2 scene studio.desk` | Three notes, A, B and C. | Three notes, marked A, B and C. | Three notes, labelled A, B and C. |
| `s2_ep02_m2 scene studio.painting[p1]` | In the old trunk: a painting of a square. | You open the old trunk. Inside is a painting of a square. | The old trunk creaks open. Inside lies a painting of a square. |
| `s2_ep02_m2 scene studio.painting[p2]` | In the desk drawer: a painting of a square. | You open the desk drawer. Inside is a painting of a square. | Tucked away in the desk drawer: a painting of a square. |
| `s2_ep02_m2 scene studio.painting[p3]` | In the crate under the desk: a painting of a square. | You look in the crate under the desk. There is a painting of a square. | Hidden in the crate beneath the desk: a painting of a square. |
| `s2_ep02_m2 scene studio.others[1] (A canvas on the small easel)` | Some paint on a canvas, but no picture yet. | A canvas with some paint on it, but no picture yet. | A canvas with a few strokes of paint, but no picture yet. |
| `s2_ep02_m2 scene studio.others[2] (A straw hat and a painting smock on a hook)` | His straw hat and his painting smock, on a hook. | His straw hat and his painting smock hang on a hook. | His straw hat and paint-spattered smock, hanging on a hook. |
| `s2_ep02_m2 scene studio.others[3] (The big window)` | The white church on the hill. You can see it from here. | You can see the white church on the hill from here. | The white church on its hill fills the window. |
| `s2_ep02_m2 scene studio.others[4] (Brushes and a palette on a table)` | Brushes and a palette. The paint on it is dry. | Brushes and a palette. The paint on the palette is dry. | Brushes and a palette. The paint on it has dried hard. |
| `s2_ep02_m2 scene studio.others[5] (Paintings of Paris on the wall)` | Paintings of Paris on the wall. The white church, again and again. | Paintings of Paris on the wall. The white church appears again and again. | Paintings of Paris cover the wall. The white church, over and over again. |
| `learning s2_ep02_m2` | "BEFORE THE RAIN", "AFTER THE RAIN STOPPED", "WHEN THE SKY TURNED GOLD" | "BEFORE THE RAIN", "AFTER THE RAIN STOPPED", "WHEN THE SKY TURNED GOLD", "Which painting goes with each note?" | "BEFORE THE RAIN", "AFTER THE RAIN STOPPED", "WHEN THE SKY TURNED GOLD", "Pair each note with the painting it describes" |
| `s2_ep02_m3.story` | The canvas is covered in thick paint. Blue, red, yellow. No picture at all. / Why would a painter do that? | The canvas is covered in thick paint: blue, red and yellow. There is no picture at all. / Why would a painter do that? | Thick paint smothers the canvas: blue, red, yellow, and no picture at all. / Why would a painter bury his own work? |
| `s2_ep02_m3.letterIntro` | A note is tucked into the frame: | Someone has tucked a note into the frame: | A note is tucked into the edge of the frame: |
| `s2_ep02_m3.letter` | I painted over my sketch. / Slide the paint away / and look UNDERNEATH. /  / My pencil has no colours. / So remember: the gate is black. /  / — P. | I painted over my sketch. / Slide the paint away / and look UNDERNEATH. /  / My pencil has no colours, / so remember this: the gate is black. /  / — P. | I painted over my sketch. / Slide the paint away / and look UNDERNEATH. /  / My pencil knows no colours, / so remember: the gate is black. /  / — P. |
| `s2_ep02_m3.question` | Find the lamp, the steps and the gate. | Find the lamp, the steps and the gate in the sketch. | Uncover the sketch, then find its lamp, its steps and its gate. |
| `s2_ep02_m3.hints[1]` | Slide the paint away first. The sketch is underneath. | First, slide the paint away. The sketch is hidden underneath. | Whatever he hid lies beneath the paint. Clear it away first. |
| `s2_ep02_m3.hints[2]` | The lamp is tall. The steps are at the bottom. The gate is between two pillars. | The lamp is tall and thin. The steps are at the bottom. The gate stands between two pillars. | Search high for something tall, low for something you climb, and between two pillars for the last. |
| `s2_ep02_m3.successMessage` | The sketch is uncovered! | You uncovered the sketch! | The hidden sketch is revealed! |
| `s2_ep02_m3.transition[1]` | What changed? The painter covered his own sketch. | What changed? The painter covered his own sketch with paint. | What changed? The painter buried his own sketch under paint. |
| `s2_ep02_m3.transition[2]` | What was hidden? A place: stone steps, an old lamp, a black gate. | What was hidden? A place with stone steps, an old lamp and a black gate. | What was hidden? A place of stone steps, an old lamp and a black gate. |
| `s2_ep02_m3.transition[3]` | Why does it matter? He hid it himself, on purpose. | Why does it matter? The painter hid it himself, on purpose. | Why does it matter? He hid it himself, deliberately. |
| `s2_ep02_m3.transition[4]` | Against the wall, four canvases are waiting. | Against the wall, four canvases are standing in a row. | Against the wall, four canvases stand waiting. |
| `s2_ep02_m3.clue.note` | Under the paint: stone steps, an old lamp and an iron gate. The gate is black. | Under the paint: stone steps, an old lamp and an iron gate. The note says the gate is black. | Beneath the paint: stone steps, an old lamp and an iron gate. His note insists the gate is black. |
| `s2_ep02_m3.evidence.description` | Found underneath the thick paint on his big easel. | Found under the thick paint on his big easel. | Uncovered beneath the thick paint on his big easel. |
| `s2_ep02_m3 scene layer.missLine` | Look again. A lamp, steps, a gate. | Look again. Find a lamp, some steps and a gate. | Nothing there. A lamp, some steps, a gate: keep looking. |
| `s2_ep02_m3 scene layer.paintLine` | Thick paint. Slide it away first. | This is thick paint. Slide it away first. | Only thick paint. Slide it aside first. |
| `s2_ep02_m3 scene layer.found[lamp]` | An old lamp, tall and thin. | = Rookie | A tall, thin lamp, old and elegant. |
| `s2_ep02_m3 scene layer.found[steps]` | Stone steps, going up. | = Rookie | Worn stone steps, climbing upward. |
| `s2_ep02_m3 scene layer.found[gate]` | An iron gate between two stone pillars. The gate is black. | An iron gate between two stone pillars. The note says it is black. | An iron gate between two stone pillars. Black, the note insists. |
| `learning s2_ep02_m3` | "Slide the paint away", "look UNDERNEATH", "the gate is black" | "Slide the paint away", "look UNDERNEATH", "remember this: the gate is black" | "Slide the paint away", "look UNDERNEATH", "Whatever he hid lies beneath the paint" |
| `s2_ep02_final.story` | Four canvases lean against the wall. They look alike. / Only one has a message on its back. | Four canvases lean against the wall. They look very alike. / Only one of them has a message on the back. | Four canvases lean against the wall, almost identical at first glance. / Only one carries a message on its back. |
| `s2_ep02_final.letterIntro` | Your notebook says: | You check your notebook: | Your notebook reads: |
| `s2_ep02_final.letter` | YOUR CLUES /  / THE PAINTED STREET / Not the street with the red door. /  / THE ARTIST'S NOTES / I hid my secret on a blue-sky day. /  / THE HIDDEN SKETCH / Steps, a lamp and a black gate. /  / One canvas matches all three. | YOUR CLUES /  / THE PAINTED STREET / Not the street with the red door. /  / THE ARTIST'S NOTES / I hid my secret on a blue-sky day. /  / THE HIDDEN SKETCH / Steps, a lamp and a black gate. /  / Only one canvas matches all three clues. | YOUR CLUES /  / THE PAINTED STREET / Not the street with the red door. /  / THE ARTIST'S NOTES / I hid my secret on a blue-sky day. /  / THE HIDDEN SKETCH / Steps, a lamp and a black gate. /  / Only one canvas fits every clue. |
| `s2_ep02_final.question` | Which canvas hides the message? | Which canvas has the message on its back? | Which canvas is hiding the message? |
| `s2_ep02_final.hints[1]` | Check each canvas against all three clues. | Check each canvas against all three clues, one by one. | No single clue is enough. Test every canvas against all three. |
| `s2_ep02_final.hints[2]` | No red door. A blue sky. A black gate beside the steps. | You need: no red door, a blue sky, and a black gate beside the steps. | One canvas fails the street clue, one fails the sky and one fails the gate. Which one survives? |
| `s2_ep02_final.successMessage` | You found the right canvas! | That is the right canvas! | The right canvas at last! |
| `s2_ep02_final.transition[1]` | On the back: ATELIER MONTMARTRE, his studio. | = Rookie | = Rookie |
| `s2_ep02_final.transition[2]` | And three French words: TOUJOURS PLUS HAUT. Always higher. | = Rookie | = Rookie |
| `s2_ep02_final.transition[3]` | Below, in the same hand as FIND THE PAINTER: | Below, in the same handwriting as FIND THE PAINTER: | Below it, in the same handwriting as FIND THE PAINTER: |
| `s2_ep02_final.transition[4]` | A city can lose an hour. / But who can steal it? | = Rookie | = Rookie |
| `s2_ep02_final.transition[5]` | "I saw who took the hour. I went away to keep the secret safe. — P." | = Rookie | = Rookie |
| `s2_ep02_final.transition[6]` | He hid his own sketch. He left his notes for you. | = Rookie | He hid his own sketch, and left his notes for you to find. |
| `s2_ep02_final.transition[7]` | Did he leave his painting in the brass box for you, too? | Did he also leave his painting in the brass box for you? | Was it he who left his painting in the brass box for you, too? |
| `s2_ep02_final.transition[8]` | He left on his own. | = Rookie | Nobody took him. He left on his own. |
| `s2_ep02_final.transition[9]` | But someone is still stealing the hours of Paris. | = Rookie | = Rookie |
| `s2_ep02_final.option a feedback` | Check the painted street clue. Is there a red door? | Check the clue from the painted street. Does this canvas have a red door? | Remember the painted street. A red door rules this one out. |
| `s2_ep02_final.option b feedback` | Check the artist's notes. Is the sky blue? | Check the artist's notes. Is this sky blue? | Remember the artist's notes. Is this the sky of a blue-sky day? |
| `s2_ep02_final.option d feedback` | Check the hidden sketch. What colour is the gate? | Check the hidden sketch. What colour should the gate be? | Remember the hidden sketch. His pencil had no colours, but his note told you the colour of the gate. |
| `s2_ep02_final.evidence.description` | On the back of his canvas. His note says: "I saw who took the hour." | Written on the back of his canvas. His note says: "I saw who took the hour." | Written on the back of his canvas, beside his note: "I saw who took the hour." |
| `learning s2_ep02_final` | "Not the street with the red door", "One canvas matches all three" | "Not the street with the red door", "Only one canvas matches all three clues" | "Not the street with the red door", "Only one canvas fits every clue" |

### s2_ep03 — The Tower's Secret

| 위치 | Rookie (기준본) | Junior | Master |
|---|---|---|---|
| `intro` | The painter left one last message: Always higher. / You turn the canvas over again. Beside the words is a small drawing. / A tall iron tower. The Eiffel Tower. / At its entrance, two records describe the same inspection. They do not match. | The painter left one last message: Always higher. / You turn the canvas over again. Next to the words is a small drawing. / It shows a tall iron tower: the Eiffel Tower. / At its entrance, two records tell you about the same inspection. But they do not match. | The painter left one last message: Always higher. / You turn the canvas over again. Beside the words, a small drawing catches your eye. / A tall iron tower. The Eiffel Tower. / At its entrance, two records describe the very same inspection, yet they disagree. |
| `synopsis` | The painter's last message said: ALWAYS HIGHER. / Beside it, a small drawing of a tall iron tower. / At the Eiffel Tower, two records do not agree. | The painter's last message said: ALWAYS HIGHER. / Next to it, he drew a small picture of a tall iron tower. / At the Eiffel Tower, two records do not agree. | The painter's final message read: ALWAYS HIGHER. / Beside it, he had sketched a tall iron tower. / At the Eiffel Tower, two official records refuse to agree. |
| `objectives` | Compare the two records. / Find where the lift went. / Open the iron door. | Compare the two records line by line. / Find out where the lift went. / Open the locked iron door. | Compare the two records closely. / Trace the lift's secret journey. / Get past the locked iron door. |
| `caseSummary` | Two records, one hour apart. In that hour, someone went up to the Service Level. | Two records were one hour apart. In that hour, someone went up to the Service Level. | Two records, one hour apart. In that hour, someone slipped up to the Service Level. |
| `hook` | Who left the plaque about the missing hour? And why does it lead to the river? | Who left the plaque about the missing hour? And why does it point to the river? | Who left the plaque about the missing hour, and why does it lead to the river? |
| `s2_ep03_m1.story` | At the foot of the tower, the lamps are coming on. / By the gate: a notice for visitors. In the ticket booth: the maintenance log. | At the foot of the tower, the lamps are coming on. / By the gate is a notice for visitors. In the ticket booth is the maintenance log. | At the foot of the tower, the evening lamps flicker on. / By the gate hangs a notice for visitors. Inside the ticket booth lies the maintenance log. |
| `s2_ep03_m1.letterIntro` | Your notebook says: | You write in your notebook: | Your notebook reminds you: |
| `s2_ep03_m1.letter` | Two records. / The same day. The same job. /  / Find the two lines that do not match. | Two records. / The same day. The same job. /  / Compare them line by line. / Find the two lines that do not match. | Two records. / The same day. The same job. /  / Somewhere, they disagree. / Find the two lines that do not match. |
| `s2_ep03_m1.question` | Which lines do not match? | Which two lines do not match? | Where do the two records disagree? |
| `s2_ep03_m1.hints[1]` | Read each record line by line: the date, the job, the time. | Read each record one line at a time: the date, the job, the time. | A careful detective reads every line on both records. |
| `s2_ep03_m1.hints[2]` | The date and the job are the same on both. What about the time? | The date is the same on both. So is the job. Now look at the time. | Two of the three lines agree perfectly. The last one tells a different story. |
| `s2_ep03_m1.successMessage` | The times do not match! | The times on the two records do not match! | The two records disagree on the time! |
| `s2_ep03_m1.transition[1]` | The visitor notice says 4:00. The maintenance log says 3:00. | The visitor notice says 4:00, but the maintenance log says 3:00. | The visitor notice claims 4:00. The maintenance log insists on 3:00. |
| `s2_ep03_m1.transition[2]` | The same day. The same job. One hour apart. | Same day. Same job. But one hour apart. | Same day, same job, yet one hour apart. |
| `s2_ep03_m1.transition[3]` | At the bottom of the log, a pencil line: CHECK THE LIFT LOG. | At the bottom of the log, someone has written in pencil: CHECK THE LIFT LOG. | Scrawled in pencil at the bottom of the log: CHECK THE LIFT LOG. |
| `s2_ep03_m1.feedback["date:date"]` | Both records say 12 MAY. The dates match. | Both records say 12 MAY. The dates are the same. | Both records give 12 MAY. No difference there. |
| `s2_ep03_m1.feedback["job:job"]` | Both records say LIFT INSPECTION. The jobs match. | Both records say LIFT INSPECTION. The jobs are the same. | Both records name LIFT INSPECTION. No difference there. |
| `s2_ep03_m1.feedback["date:job"]` | Compare the same line on both: date with date, time with time. | Compare the same line on both records: date with date, time with time. | Compare like with like: date with date, time with time. |
| `s2_ep03_m1.feedback["date:time"]` | Compare the same line on both: date with date, time with time. | Compare the same line on both records: date with date, time with time. | Compare like with like: date with date, time with time. |
| `s2_ep03_m1.feedback["job:date"]` | Compare the same line on both: date with date, time with time. | Compare the same line on both records: date with date, time with time. | Compare like with like: date with date, time with time. |
| `s2_ep03_m1.feedback["job:time"]` | Compare the same line on both: date with date, time with time. | Compare the same line on both records: date with date, time with time. | Compare like with like: date with date, time with time. |
| `s2_ep03_m1.feedback["time:date"]` | Compare the same line on both: date with date, time with time. | Compare the same line on both records: date with date, time with time. | Compare like with like: date with date, time with time. |
| `s2_ep03_m1.feedback["time:job"]` | Compare the same line on both: date with date, time with time. | Compare the same line on both records: date with date, time with time. | Compare like with like: date with date, time with time. |
| `s2_ep03_m1.clue.note` | At the bottom of the maintenance log, a pencil line: CHECK THE LIFT LOG. | At the bottom of the maintenance log, a pencil note: CHECK THE LIFT LOG. | Scrawled in pencil at the bottom of the maintenance log: CHECK THE LIFT LOG. |
| `s2_ep03_m1.evidence.description` | Found at the entrance of the Eiffel Tower. | Two records found at the entrance of the Eiffel Tower. | Two records from the entrance of the Eiffel Tower. |
| `learning s2_ep03_m1` | "The same day. The same job.", "Find the two lines that do not match" | "The same day. The same job.", "Compare them line by line", "Find the two lines that do not match" | "The same day. The same job.", "Somewhere, they disagree", "Where do the two records disagree?" |
| `s2_ep03_m2.story` | On one wall of the old lift: a brass route plate. On the other: the lift log. / Where did the lift go after three o'clock? | On one wall of the old lift is a brass route plate. On the other is the lift log. / Where did the lift go after three o'clock? | On one wall of the old lift gleams a brass route plate. On the other hangs the lift log. / After three o'clock, where did the lift really go? |
| `s2_ep03_m2.letterIntro` | Your notebook says: | You check your notebook: | Your notebook reads: |
| `s2_ep03_m2.letter` | CHECK THE LIFT LOG. /  / Read every trip. / One stop is not written. / The route plate shows every stop. | CHECK THE LIFT LOG. /  / Read every trip in the log. / One stop is not written. / The route plate shows every stop. | CHECK THE LIFT LOG. /  / Study every trip. / One stop has been left unwritten. / The route plate knows every stop. |
| `s2_ep03_m2.question` | Where did the lift go at 3:20? | At 3:20, where did the lift go? | Where was the lift heading at 3:20? |
| `s2_ep03_m2.hints[1]` | Find the S in the lift log. Then find what S means on the route plate. | Find the S in the lift log. Then look for S on the route plate. | The log keeps a secret in a single letter. The route plate can explain it. |
| `s2_ep03_m2.hints[2]` | S = SERVICE RUN. Which stop is only on the service route? | On the plate, S = SERVICE RUN. Which stop is only on the service route? | Once you know that S = SERVICE RUN, ask which stop only a service run can reach. |
| `s2_ep03_m2.successMessage` | You found the missing stop! | You found the stop that was missing from the log! | The unwritten stop is found! |
| `s2_ep03_m2.transition[1]` | At 3:20, the lift went up to the Service Level. It came back down at 4:25. | At 3:20, the lift went up to the Service Level. It did not come back down until 4:25. | At 3:20, the lift climbed to the Service Level. It did not return to Ground until 4:25. |
| `s2_ep03_m2.transition[2]` | You ride up. The gates open onto a dark iron platform. | You ride the lift up. The gates open onto a dark iron platform. | You ride up. The brass gates slide open onto a dark iron platform. |
| `s2_ep03_m2.transition[3]` | On an iron door, a sign: SERVICE ACCESS ONLY. | On an iron door, there is a sign: SERVICE ACCESS ONLY. | An iron door bears a sign: SERVICE ACCESS ONLY. |
| `s2_ep03_m2.option ground feedback` | The lift came back down to Ground at 4:25. Where was it before that? | At 4:25, the lift came back down to Ground. Where was it before that? | The lift returned to Ground at 4:25. But where had it been until then? |
| `s2_ep03_m2.option first feedback` | First is a passenger stop. The 3:20 trip has an S. What does S mean? | First is a stop for passengers. The 3:20 trip has an S next to it. What does S mean? | First is a passenger stop. Yet the 3:20 trip carries an S. What could that mean? |
| `s2_ep03_m2.option top feedback` | Top is a passenger stop. The 3:20 trip has an S. What does S mean? | Top is a stop for passengers. The 3:20 trip has an S next to it. What does S mean? | Top is a passenger stop. Yet the 3:20 trip carries an S. What could that mean? |
| `s2_ep03_m2.clue.note` | At the Service Level, a sign on an iron door: SERVICE ACCESS ONLY. | At the Service Level, there is a sign on an iron door: SERVICE ACCESS ONLY. | At the Service Level, an iron door bears a sign: SERVICE ACCESS ONLY. |
| `s2_ep03_m2.evidence.description` | Kept in a holder on the wall of the lift. | It hangs in a holder on the wall of the lift. | Kept in a brass holder on the wall of the lift. |
| `learning s2_ep03_m2` | "One stop is not written", "S = SERVICE RUN" | = Rookie | "One stop has been left unwritten", "S = SERVICE RUN" |
| `s2_ep03_m3.story` | The Service Level is dark and quiet. Visitors never come here. / A heavy padlock with three dials locks the iron door. | The Service Level is dark and quiet. Visitors never come up here. / A heavy padlock with three dials keeps the iron door shut. | The Service Level is dark and silent. No visitor ever comes this far. / A heavy padlock with three dials guards the iron door. |
| `s2_ep03_m3.letterIntro` | Beside the door, a note is pinned: | Next to the door, someone has pinned a note: | Pinned beside the door is a note: |
| `s2_ep03_m3.letter` | INSPECTION STEPS /  / Finally, turn the key. / First, check the clock. / Next, stop the lift. | = Rookie | = Rookie |
| `s2_ep03_m3.question` | Set the three dials. Then open the lock. | Set the three dials in the right order. Then open the lock. | Set the dials in the order the note demands, then open the lock. |
| `s2_ep03_m3.hints[1]` | Read the note again. FIRST, NEXT and FINALLY tell you the order. | Read the note again. The words FIRST, NEXT and FINALLY tell you the order. | The note is jumbled on purpose. Its order words matter more than the order of its lines. |
| `s2_ep03_m3.hints[2]` | Dial 1 is what you do FIRST. Dial 2 is NEXT. Dial 3 is FINALLY. | Dial 1 is the step you do FIRST. Dial 2 is NEXT. Dial 3 is FINALLY. | Each dial is one step. Let the first dial hold the step that comes FIRST. |
| `s2_ep03_m3.successMessage` | The lock is open! | The padlock is open! | The padlock gives way! |
| `s2_ep03_m3.transition[1]` | Click. Behind the iron door is a small hidden room. | Click! Behind the iron door is a small hidden room. | Click. The iron door swings open onto a small hidden room. |
| `s2_ep03_m3.transition[2]` | Wheels, cables and gears. At the back, an old machine with a clock. | There are wheels, cables and gears. At the back stands an old machine with a clock. | Wheels, cables and gears fill the space. At the back crouches an old machine with a clock. |
| `s2_ep03_m3.transition[3]` | On the floor, a square mark in the dust. A heavy crate stood here. Now it is gone. | On the floor is a square mark in the dust. A heavy crate stood here. Now it is gone. | On the floor, a square mark in the dust. A heavy crate once stood here. Now it is gone. |
| `s2_ep03_m3.orderFeedback` | Right pictures, wrong order. Read the note: FIRST, NEXT, FINALLY. | The pictures are right, but the order is wrong. Read the note: FIRST, NEXT, FINALLY. | The right pictures, but in the wrong order. The note's FIRST, NEXT and FINALLY decide it. |
| `s2_ep03_m3.clue.note` | Behind the iron door: a small machine room. Only the service staff can come in. | Behind the iron door is a small machine room. Only the service staff can go in. | Behind the iron door: a small machine room, meant only for the service staff. |
| `s2_ep03_m3.evidence.description` | Behind the locked iron door at the Service Level. | Found behind the locked iron door at the Service Level. | Hidden behind the locked iron door at the Service Level. |
| `learning s2_ep03_m3` | "First, check the clock.", "Next, stop the lift.", "Finally, turn the key." | = Rookie | "First, check the clock.", "Next, stop the lift.", "Finally, turn the key.", "the order the note demands" |
| `s2_ep03_final.story` | The old machine has a slot for time cards. Two cards are inside. / What really happened at the tower? | The old machine has a slot for time cards. There are two cards inside. / What really happened at the tower? | The old machine has a slot for time cards. Two cards are still inside. / So what truly happened at the tower? |
| `s2_ep03_final.letterIntro` | The two time cards say: | You read the two time cards: | The two time cards read: |
| `s2_ep03_final.letter` | OFFICIAL TIME — 4:00 / RECORDED TIME — 3:00 /  / One hour apart, like the two records / at the entrance. | OFFICIAL TIME — 4:00 / RECORDED TIME — 3:00 /  / One hour apart, just like the two records / at the entrance. | OFFICIAL TIME — 4:00 / RECORDED TIME — 3:00 /  / One hour apart, exactly like the two records / at the entrance. |
| `s2_ep03_final.question` | Link the evidence to each question. | Link each question to the evidence that answers it. | Connect each question to the evidence that answers it. |
| `s2_ep03_final.hints[1]` | Open each piece of evidence. What does each one show? | Open each piece of evidence and ask: what does this one show? | Examine each piece of evidence. Ask what it proves, and what it does not. |
| `s2_ep03_final.hints[2]` | Question 3 needs two pieces: where the lift went, and what was behind the door. | Question 3 needs two pieces: one shows where the lift went, one shows what was behind the door. | One question cannot be answered by a single piece. Pair the journey with its destination. |
| `s2_ep03_final.successMessage` | The evidence fits together! | All the evidence fits together! | Every piece of evidence falls into place! |
| `s2_ep03_final.transition[1]` | One hour is missing. | = Rookie | = Rookie |
| `s2_ep03_final.transition[2]` | The clock is still running. | = Rookie | = Rookie |
| `s2_ep03_final.transition[3]` | Under the words: three small waves, and one word. | Under the words are three small waves and one word. | Beneath the words: three small waves, and a single word. |
| `s2_ep03_final.transition[4]` | SEINE. | = Rookie | = Rookie |
| `s2_ep03_final.transition[5]` | The river that runs through Paris. | It is the river that runs through Paris. | The river that winds through Paris. |
| `s2_ep03_final.transition[6]` | By the square mark in the dust lies a torn shipping tag: | Next to the square mark in the dust is a torn shipping tag: | Beside the square mark in the dust lies a torn shipping tag: |
| `s2_ep03_final.transition[7]` | FROM: SERVICE LEVEL. TO: THE RIVER. | = Rookie | = Rookie |
| `s2_ep03_final.transition[8]` | Who left this message? | = Rookie | = Rookie |
| `s2_ep03_final.transition[9]` | And why does it lead to the river? | = Rookie | = Rookie |
| `s2_ep03_final.feedback["q1:"]` | Question 1 is about the inspection records. Which evidence shows them? | Question 1 is about the inspection records. Which evidence shows those records? | Question 1 concerns the inspection records. Which evidence holds them? |
| `s2_ep03_final.feedback["q1:e2"]` | Question 1 is about the inspection records. Which evidence shows them? | Question 1 is about the inspection records. Which evidence shows those records? | Question 1 concerns the inspection records. Which evidence holds them? |
| `s2_ep03_final.feedback["q1:e3"]` | Question 1 is about the inspection records. Which evidence shows them? | Question 1 is about the inspection records. Which evidence shows those records? | Question 1 concerns the inspection records. Which evidence holds them? |
| `s2_ep03_final.feedback["q1:e2+e3"]` | Question 1 is about the inspection records. Which evidence shows them? | Question 1 is about the inspection records. Which evidence shows those records? | Question 1 concerns the inspection records. Which evidence holds them? |
| `s2_ep03_final.feedback["q1:e1+e2"]` | Question 1 needs only one piece: the two records. | Question 1 needs just one piece: the two records. | For question 1, the two records alone are enough. |
| `s2_ep03_final.feedback["q1:e1+e3"]` | Question 1 needs only one piece: the two records. | Question 1 needs just one piece: the two records. | For question 1, the two records alone are enough. |
| `s2_ep03_final.feedback["q1:e1+e2+e3"]` | Question 1 needs only one piece: the two records. | Question 1 needs just one piece: the two records. | For question 1, the two records alone are enough. |
| `s2_ep03_final.feedback["q2:"]` | Which evidence shows the lift's trips? | Which evidence shows where the lift went? | Which evidence traces the lift's trips? |
| `s2_ep03_final.feedback["q2:e1"]` | Which evidence shows the lift's trips? | Which evidence shows where the lift went? | Which evidence traces the lift's trips? |
| `s2_ep03_final.feedback["q2:e3"]` | Which evidence shows the lift's trips? | Which evidence shows where the lift went? | Which evidence traces the lift's trips? |
| `s2_ep03_final.feedback["q2:e1+e3"]` | Which evidence shows the lift's trips? | Which evidence shows where the lift went? | Which evidence traces the lift's trips? |
| `s2_ep03_final.feedback["q2:e1+e2"]` | Question 2 needs only one piece: where the lift went. | Question 2 needs just one piece: the one that shows where the lift went. | Question 2 needs only one piece: the record of where the lift went. |
| `s2_ep03_final.feedback["q2:e2+e3"]` | Question 2 needs only one piece: where the lift went. | Question 2 needs just one piece: the one that shows where the lift went. | Question 2 needs only one piece: the record of where the lift went. |
| `s2_ep03_final.feedback["q2:e1+e2+e3"]` | Question 2 needs only one piece: where the lift went. | Question 2 needs just one piece: the one that shows where the lift went. | Question 2 needs only one piece: the record of where the lift went. |
| `s2_ep03_final.feedback["q3:"]` | Question 3 needs two pieces. Where did the lift go? What was there? | Question 3 needs two pieces. Where did the lift go? And what was up there? | Question 3 needs two pieces. Where did the lift go, and what waited there? |
| `s2_ep03_final.feedback["q3:e1"]` | The notices were at the entrance. Question 3 is about the service area. | The notices were down at the entrance. Question 3 is about the service area. | The notices stayed down at the entrance. Question 3 concerns the service area. |
| `s2_ep03_final.feedback["q3:e1+e2"]` | The notices were at the entrance. Question 3 is about the service area. | The notices were down at the entrance. Question 3 is about the service area. | The notices stayed down at the entrance. Question 3 concerns the service area. |
| `s2_ep03_final.feedback["q3:e1+e3"]` | The notices were at the entrance. Question 3 is about the service area. | The notices were down at the entrance. Question 3 is about the service area. | The notices stayed down at the entrance. Question 3 concerns the service area. |
| `s2_ep03_final.feedback["q3:e1+e2+e3"]` | The notices were at the entrance. Question 3 is about the service area. | The notices were down at the entrance. Question 3 is about the service area. | The notices stayed down at the entrance. Question 3 concerns the service area. |
| `s2_ep03_final.feedback["q3:e2"]` | The lift log shows where the lift went. What did you find behind the door? | The lift log shows where the lift went. What did you find behind the iron door? | The lift log proves where the lift went. But what was behind the door? |
| `s2_ep03_final.feedback["q3:e3"]` | You found the room. But what shows that someone went up there? | = Rookie | = Rookie |
| `s2_ep03_final.feedback["why:"]` | Choose what the evidence shows. | Choose what the evidence really shows. | Choose only what the evidence can prove. |
| `s2_ep03_final.feedback["why:vanished"]` | We have no proof of that yet. | = Rookie | = Rookie |
| `s2_ep03_final.feedback["why:still"]` | Read the lift log again. The lift went up at 3:20. | Look at the lift log again. The lift went up at 3:20. | Check the lift log again. The lift went up at 3:20. |
| `s2_ep03_final.evidence.description` | Hidden inside the time-recording machine. | It was hidden inside the time-recording machine. | Concealed inside the time-recording machine. |
| `learning s2_ep03_final` | "What was wrong with the inspection records?", "What can we conclude?" | "What was wrong with the inspection records?", "What can we conclude?", "the evidence that answers it" | "What was wrong with the inspection records?", "What can we conclude?", "what it proves, and what it does not" |

## 부록 B. 재현 방법

- 원본: `lib/data/mock/season2/difficulty/ep01_levels.dart`~`ep03_levels.dart` — Rookie 패치(`rookie01`~`rookie03`), Junior·Master의 모든 사건 JSON 문장(`junior01`~`master03`), 장면 문장(`juniorScenes01`·`masterScenes01` 등), 학습 표현(`juniorLearning01` 등), glossary. 등록은 `season2_difficulty.dart`(`season2CasePatches`·`season2Variants`).
- 난이도 적용 결과 보기: `DifficultyContent.episodeAt(<기준 사건>, Difficulty.junior|master)` → `Episode`(장면은 그 미션으로 `SeasonCatalog.stationClocks(m)` 등).
- 미작성 확인: `DifficultyContent.missingAt('s2_ep02', Difficulty.master)`(빈 목록이어야 함), 구조 위반: `DifficultyContent.problems()`.
- 부록 A는 위 API로 세 Case의 Rookie·Junior·Master 문장을 같은 위치끼리 나란히 뽑은 것이다(테스트 `test/difficulty_paris_7a_test.dart`의 `fields()`와 같은 위치 체계).
- 개발자 모드: Game Master → START DEVELOPER MODE → TEST LEVEL에서 난이도 선택 후 Paris Case 01~03.
