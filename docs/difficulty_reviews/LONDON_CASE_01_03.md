# London Case 01~03 — 난이도별 영어 콘텐츠 검토 보고서 (PART 6A)

> 작성 2026-10-27 · 브랜치 `feat/difficulty-london-01-03` · 기준 커밋 PART 5 `b6fb71e`
> 대상: London Season 1 Case 01(The Missing Crown) · Case 02(The Silent Clock) · Case 03(The Vanishing Painting)
> 원칙: **영어 난이도만 바뀌고 사건·정답·순서·단서·증거·보상은 모두 같다.** Master는 영어가 어려운 것이지 퍼즐이 어려운 것이 아니다.

## 0. 전체 목록(재현 가능한 참조)

이 보고서는 대표 문장과 검토 근거를 담는다. **바뀐 문장 전체**는 아래 세 파일에 미션·필드 순서대로 모두 들어 있다(파일 자체가 전체 목록이다).

| 파일 | 내용 |
|---|---|
| `lib/data/mock/season1/difficulty/ep01_levels.dart` | Case 01 Rookie 패치, Junior·Master 사건 JSON 패치, 장면 객체(탐색 m01·돋보기 m02·추리 m03·해독 m05), Discovery, 학습 설계 |
| `lib/data/mock/season1/difficulty/ep02_levels.dart` | Case 02 Rookie 패치, Junior·Master 패치(PART 5 샘플 `ep02_m1` 포함), 시계 퍼즐, Discovery, 학습 설계 |
| `lib/data/mock/season1/difficulty/ep03_levels.dart` | Case 03 Rookie 패치, Junior·Master 패치, 갤러리 수색 장면(ep03_m1), Discovery, 학습 설계 |

화면에 실제로 나오는 최종 문장(기준본 + 패치)은 `DifficultyContent.episodeAt(<기준 사건>, Difficulty.<level>)`로 재현된다. 퍼즐 객체는 `SeasonCatalog.<표>(<그 난이도의 미션>)`(예: `SeasonCatalog.explore(m)`)로 읽는다. 기준본(Rookie)은 `lib/data/mock/season1/episode0N_mock.dart`와 각 `season1_*.dart` 표다.

## 1. 적용 범위

### 1.1 난이도별로 작성한 것
- **사건**: `synopsis`, `intro`(줄 수 동일), Case 02·03은 `caseSummary`·`hook`(사건 결과 화면), `glossary`(Junior·Master에서 새로 쓴 어려운 단어를 추가 — 길게 눌러 뜻 보기)
- **미션(모든 미션 + Final)**: `story`·`transition`(줄 수 동일), `letterIntro`, `letter`, `question`, `prompt`, `hints`(개수 동일), `successMessage`, 오답 줄(`feedback` 값 — 키는 오답 문자열이라 불변), 선택지 오답 피드백(`options[].feedback`), Notebook 문장(`clue.note`), 증거 설명(`evidence.description`), Case 03 M3 `orderFeedback`
- **퍼즐 객체**: Case 01 M1 탐색(`ExploreScene`), M2 돋보기(`InspectScene`), M3 추리(`DeductionScene`), M5 해독(`DecodeScene`), Case 02 M1 시계(`ClockPuzzle`), Case 03 M1 수색(`InvestigationScene`)의 안내·발견 문장, 모든 일반 미션의 Discovery Moment(`detail`·`note`), 학습 설계(부모 보고서 학습 표현)

### 1.2 일부러 세 난이도에서 같게 둔 것 (fallback이 아니라 **명시적으로 같은 값**을 적음)
| 위치 | 이유 |
|---|---|
| `m02.prompt` `ROSETTA _____` | 퍼즐 입력 칸 표시(글자 수 = 정답 길이) |
| `m05.letter` "Four pictures. Four locks. / Remember the order." | 해독된 카드 **그림 위에 직접 그려지는 문장**(영역·기울기 고정) |
| `m05.question`, `final.question`, `ep02_final.question` | 조작 안내("Examine the card…", "Open the four locks.", "Set the time…") |
| 선택지 **이름**(`options[].label`) | 정답표·그림·추리(예: Case 02 M3 "Gallery 9 · Picture 17"이 실수 유형 그 자체)와 묶여 있음 |
| 증거 **이름·글귀**(`evidence.name`·`inscription`), 단서 **제목·값** | 퍼즐 데이터(7924, "P.S. I love trains!", "The boot smells of trains and smoke.", "KING'S CROSS — LOST PROPERTY" 등) — 엔진이 변경을 막는다 |
| 장면의 조작 안내·버튼(“Drag the glass…”, “Tap…”, SEARCH HERE, EXAMINE THE CODE, 그림 설명 접근성 라벨) | "Master에서도 조작 안내는 명확" 원칙 |
| Case 01 M5·Final 학습 설계 | 영어 의존도 낮음(표현 없음) — 기준본 객체 그대로 |
| Case 02 Final 학습 표현 "One hour after the clock stops" | 계획서의 규칙 문장 자체(Case 12가 "after"를 다시 읽음) — 모든 난이도에서 같은 문장 |

### 1.3 Rookie
기준본은 이미 짧은 문장·쉬운 단어가 대부분이라 **기준본 유지**를 원칙으로 하고, 기준본이 Rookie보다 어렵거나 길었던 4곳만 Rookie 패치로 고쳤다(기준 JSON 불변 → 기존 FNV 해시·문자열 고정 테스트 영향 없음).

| 위치 | 기준본 | Rookie | 이유 |
|---|---|---|---|
| ep01 intro 5행 | You have been chosen as a detective. | Now you are the detective. Find the Crown! | 수동태 현재완료 → 능동 + 목표 명확(첫 사건: "무엇을 해야 하는가") |
| ep01 final story 1행 | Deep inside the Royal Archive, behind the secret door, you find a heavy golden box. | Behind the secret door, you find a heavy golden box. | 한 문장에 장소 두 개 → 하나 |
| ep01 final story 2행 | The Crown is inside. | The Crown is inside it. | 지시 대상 명확 |
| ep02 final letter 끝 2행 | Your notebook knows when the clock stopped, / and the Time Card has the thief's plan. | Your notebook tells you when the clock stopped. / The Time Card has the thief's plan. | 의인화("knows") 제거, 한 문장 한 정보 |
| ep03 M3 Tip 2 | Wet shoes get drier with every step: her first print is the wettest, her last is the driest. Put the other two between them. | Wet shoes get drier with every step. Her first footprint is the wettest. Her last one is the driest. Put the other two in between. | 콜론·쉼표 연결 문장을 짧은 4문장으로(각 9단어 이하 — 테스트) |

PART 5 테스트(TESTER 세션 Rookie = 기준본, `ep02_m1` Rookie 학습 표현 = 기준본)를 지키기 위해 `ep02_m1`은 Rookie 패치를 두지 않았다. 장면 객체도 Rookie 변형 없음(기존 위젯 테스트가 기준본 장면 문장으로 화면을 확인함 — 위 기준본 문장들은 Rookie 수준으로 판단).

## 2. Case별 스토리 요약과 추리 흐름 (세 난이도 공통)

### Case 01 — The Missing Crown (밤 10:42, 런던 곳곳)
King's Cross 9번 승강장 옆 가방 → 편지 "old mummies from Egypt and a famous stone" → **British Museum**(포스터 보드에서 선택) → Room 4 돋보기, 메모 "a hard piece of rock"(+ 첫 편지의 "a famous stone") → **STONE** → 열쇠 꼬리표 "London's biggest bell" → Big Ben 발치, 발자국·가로등 빛·긁힌 자국이 가리키는 **돌 뒤** → 회중시계 7시 → Hyde Park(백조 2) → 빨간 깃발·분수·왕이 사는 **Buckingham Palace** → 왕관 카드 해독(그림 순서) → Royal Box **7924**. 사건 후 "P.S. I love trains!"(→ Case 11).
첫 사건 이해 점검(프롬프트 5장): ① 어디 — 각 미션 `location`·story 첫 줄이 장소를 말함 ② 무엇을 조사 — M1 탐색 `task`("Look around the station…"/"Search the quiet station…"), `nextTask`가 다음 행동 ③ 왜 중요 — 편지·메모가 다음 장소를 가리킴, Discovery `detail`이 의미를 한 줄로 ④ 다음 — `transition` 마지막 줄이 다음 장소("It must be Hyde Park. Let's go!").

### Case 02 — The Silent Clock (다음 날 아침, Big Ben)
Mrs Bell의 메모(시침 8과 9 사이, 분침 3에서 눈금 두 칸 더) → **8:17**(입력 817) → 톱니 "not under the biggest bell / the opposite of the biggest" → **가장 작은 종 아래** → 계획서 "The hour is the gallery. The minutes are the picture." → **Gallery 8 · Picture 17** → "One hour after the clock stops" → Final **9:17**(입력 917). **9:17은 Final 자물쇠 전 어떤 화면에도 없음**(세 난이도 테스트).

### Case 03 — The Vanishing Painting (9:18 AM, British Museum)
경비 보고서 위치 표현 under / on / next to → 갤러리 수색으로 빨간 단추(벤치 아래)·파란 천(액자)·젖은 발자국(문 옆) → 방문객 옷차림 비교: 빨간 **코트**(단추) + 파란 **스카프**(천) = **Miss Rose**(Mr Grey의 빨강은 스카프) → 젖은 정도 very wet → wet → a little wet → almost dry = **shop, stairs, café, north door** → 택시 기사 "Take me north", "a tall clock tower"(Big Ben과 King's Cross 둘 다 해당) → 장화 "smells of trains and smoke"(증거 글귀, 불변)로 **King's Cross**. Final 전 어디에도 station/train/King's Cross 없음(세 난이도 테스트).

## 3. 미션별 적용 현황

모든 미션에서 Junior·Master의 story·letterIntro·letter·question·hints·successMessage·transition이 **기준본과도, 서로와도 다르다**(1.2의 의도적 동일 5곳 제외 — 테스트가 강제). `DifficultyContent.missingAt(ep01|ep02|ep03, junior|master)` = 빈 목록, `writtenLevels` = {rookie, junior, master}.

| Case | 미션 | 사건 JSON | 퍼즐 객체 | Discovery | 학습 표현 |
|---|---|---|---|---|---|
| 01 | m01 King's Cross | ✓ (옵션 a·c·d 피드백, clue note, evidence desc) | 탐색 ✓ (task·nextTask·missLine·choiceHow·승강장 카드 = clue note·포스터 잠김 줄·빈 장소 7줄) | ✓ | ✓ |
| 01 | m02 British Museum | ✓ (prompt 동일, ROCK 오답 줄) | 돋보기 ✓ (전시물 9개 줄·잠김 줄·labelWorn) | ✓ | ✓ (recall m01) |
| 01 | m03 Big Ben | ✓ (옵션 a·c 피드백) | 추리 ✓ (단서 3줄 = 편지 3줄, 빈 장소 6줄) | ✓ | ✓ |
| 01 | m04 Hyde Park | ✓ (옵션 a·b·d 피드백) | — (객체 없음) | ✓ | ✓ |
| 01 | m05 Palace | ✓ (letter·question 동일) | 해독 ✓ (found·closerTask·missLine) | ✓ | 기준본(표현 없음) |
| 01 | final Royal Box | ✓ (question 동일) | — | (Final은 Discovery 없음) | 기준본(표현 없음) |
| 02 | ep02_m1 Westminster | ✓ (PART 5 샘플 유지 + letterIntro·clue·evidence, Master transition 신규, Master 편지 1행 개선) | 시계 ✓ (PART 5) | ✓ | ✓ |
| 02 | ep02_m2 Clock Room | ✓ | — | ✓ | ✓ |
| 02 | ep02_m3 Belfry | ✓ | — | ✓ | ✓ (recall m1) |
| 02 | ep02_final | ✓ (question 동일, 오답 817·717·818) | — | — | ✓ (recall m3, 문장 동일) |
| 03 | ep03_m1 Gallery 8 | ✓ | 수색 ✓ (보고서 3줄·발견 카드 3줄·도착 2줄·빈 장소 8줄) | ✓ | ✓ |
| 03 | ep03_m2 Egypt Room | ✓ | — | ✓ | ✓ (recall m1) |
| 03 | ep03_m3 Great Court | ✓ (오답 2개·orderFeedback) | — | ✓ | ✓ |
| 03 | ep03_final | ✓ | — | — | ✓ (recall m3) |

PART 5 샘플 `ep02_m1` 처리: Junior는 그대로 유지(자연스럽고 수준 적절). Master 편지 4행 "yet before it froze, it **shuffled on by** two more of the small marks"는 어색한 표현이라 "it **ticked on by** two more of the small marks"로 고침(학습 표현 'two more of the small marks' 유지). Master `transition`이 없어 Junior로 대체되던 것을 Master 문장으로 채움.

## 4. 난이도별 주요 문장 비교 (실제 원문)

### Case 01

**intro (5행 중 2~5행)**
- R: Something strange happened at the Royal Archive. / The Crown is missing. / The thief left a trail of clues all over London. / Now you are the detective. Find the Crown!
- J: Something strange has happened at the Royal Archive. / The Crown of London has disappeared! / The thief left a trail of clues across the city. / You have been chosen to follow it, Detective.
- M: Behind the locked doors of the Royal Archive, something is terribly wrong. / The Crown of London has vanished without a sound. / Yet the thief has left a trail of clues, scattered across the city. / Tonight, you have been chosen to follow it.

**m01 편지**
- R: I took the Crown! Ha ha! / My next stop is a very big museum. / It has old mummies from Egypt and a famous stone.
- J: Yes, I took the Crown! Ha ha! / Can you catch me? My next stop is a very big museum. / Inside, there are old mummies from Egypt and a famous stone.
- M: The Crown is mine! Ha ha! / If you wish to catch me, follow me to a grand museum. / There, mummies from ancient Egypt rest beside a famous stone.
- 질문 R "Where is the thief going next?" / J "Which museum is the thief going to next?" / M "Where is the Shadow heading next?"
- 탐색 task R "Look around the station. Your first clue is waiting!" / J "Look around the station. The thief left something here for you." / M "Search the quiet station. Somewhere here, the thief has left something behind."

**m02 메모 (4행 — 돋보기 장면이 줄 번호로 확인, 마지막 줄이 답할 줄)**
- R: It helped people read old Egyptian writing. / Its name has two words. / The first word is ROSETTA. / The second word means a hard piece of rock.
- J: Long ago, it helped people read old Egyptian writing. / Its name has two words. / The first word is ROSETTA. / The second word means a hard piece of rock.
- M: It once unlocked the secret of old Egyptian writing. / Its name is made of two words. / The first of them is ROSETTA. / The second is a word for a hard piece of rock.
- 질문 R "Complete its name." / J "Write the missing word in its name." / M "Restore the missing word of its name."

**m03 메모 (= 추리 장면 단서 카드 3장, 글자 그대로)**
- R: The footprints stop at the tower wall. / The lamp shines on one stone in the wall. / That stone has fresh scratches around it.
- J: The muddy footprints stop at the tower wall. / The lamp light falls on one stone in the wall. / That stone has fresh scratches all around it.
- M: The muddy footprints end abruptly at the tower wall. / The lamp casts its light on a single stone in that wall. / Around that stone, the scratches look fresh.

**m04 편지**
- R: My last stop is a big palace. / A red flag flies on top. / There is a fountain in front. / The King lives there!
- J: My last stop is a big palace. / A red flag is flying on top of it. / There is a fountain in front of it. / The King lives there!
- M: My final stop is a grand palace. / A red flag flies from its roof, / and a fountain stands before it. / It is the home of the King himself!

**final 뚜껑 글**
- R: Four locks keep the Crown safe. / Each lock has a picture. / Every picture is a place you visited. / Find its number in your Detective Notebook!
- J: Four locks keep the Crown safe. / There is a picture on each lock. / Each picture is a place you visited tonight. / Find the number from that place in your Detective Notebook!
- M: Four locks guard the Crown. / Each one bears a picture. / Every picture stands for a place you have visited. / Your Detective Notebook holds the number that belongs to each.

### Case 02

**ep02_m1 Mrs Bell 메모**
- R: I looked at the clock at the moment it stopped. / The hour hand was between eight and nine. / The minute hand was on the three... / and then it moved two more small marks.
- J: I was watching the clock when it stopped. / The short hour hand had passed eight, but it had not reached nine. / The long minute hand pointed at the three... / then it crept forward two more small marks.
- M: I happened to glance up at the very moment the clock fell silent. / The hour hand rested somewhere past eight, still short of nine. / The minute hand lay upon the three... / yet before it froze, it ticked on by two more of the small marks.

**ep02_m2 R.의 쪽지 (뒤 3행)**
- R: I did not take it far. / It is not under the biggest bell. / It is under the bell that is the opposite of the biggest.
- J: Do not worry. I did not take it far. / It is not under the biggest bell. / It is under the bell that is the opposite of the biggest.
- M: I have not carried it far. / You will not find it beneath the biggest bell. / Look instead beneath the bell that is its very opposite.

**ep02_m3 계획서** — 세 난이도 모두 "One hour after the clock stops, I take a picture." · "The hour is the gallery. The minutes are the picture."를 글자 그대로 유지(규칙 문장 = 퍼즐, Case 12 연결).
- R: Before the museum opens, I hide in a gallery. / … / Look at my stopped clock.
- J: Then, before the museum opens, I hide in one of its galleries. / … / The answer is in my stopped clock.
- M: Before the museum opens its doors, I slip into a gallery and wait. / … / My stopped clock holds both numbers.

**ep02_final Mrs Bell의 속삭임 (끝 2행)**
- R: Your notebook tells you when the clock stopped. / The Time Card has the thief's plan.
- J: Your notebook shows when the clock stopped, / and the Time Card shows the thief's plan.
- M: Your notebook remembers when the clock stopped; / the Time Card reveals the rest of the thief's plan.

### Case 03

**ep03_m1 경비 보고서 (= 수색 장면 보고서 줄, 글자 그대로)**
- R: The button is red. It is under the bench. / The cloth is blue. It is on the frame. / The footprint is wet. It is next to the door.
- J: The button is red. I saw it under the bench. / The cloth is blue. It is caught on the frame. / The footprint is wet. It is right next to the door.
- M: A red button lies under the bench. / A scrap of blue cloth hangs on the frame. / A wet footprint marks the floor next to the door.

**ep03_m2 방문객 메모**
- R: Miss Rose wore a red coat and a blue scarf.
- J: Miss Rose was wearing a red coat and a blue scarf.
- M: Miss Rose was dressed in a red coat and a blue scarf. (Mr Green arrived in… / Mr Grey came in…)

**ep03_m3 청소부 증언**
- R: The footprint by the café was a little wet. / …by the shop was very wet. / …by the north door was almost dry. / …by the stairs was wet. / Wet shoes get drier with every step!
- J: The footprint by the café was only a little wet. / (같은 구조) / Remember: wet shoes get drier with every step!
- M: By the café, the footprint was only a little wet. / By the shop, it was very wet indeed. / By the north door, it was almost dry. / By the stairs, it was simply wet. / After all, wet shoes get drier with every step.

**ep03_final 택시 기사 메모**
- R: The lady said: "Take me north!" / I stopped at a big building with a tall clock tower. / She ran inside with her parcel.
- J: The lady said: "Take me north, please!" / I stopped outside a big building with a tall clock tower. / She hurried inside with her parcel.
- M: The lady said: "Take me north, and quickly!" / I pulled up outside a large building crowned by a tall clock tower. / She rushed inside, her parcel held tight.

## 5. 기존 문장에서 개선한 이유 (요약)
- **Rookie**: 1.3 표 — 수동태·의인화·한 문장 다중 정보 제거. 나머지 기준본은 이미 Rookie 수준(평균 8~10단어, 한 문장 한 정보)이라 유지.
- **Junior**: 기준본의 단문을 기본 접속사(and, but, so, then)와 진행형·과거완료로 자연스럽게 잇고, 이유·관계를 한 단계 더 말한다("Without it, the clock cannot turn!"). 추리에 필요한 정보는 모두 남긴다.
- **Master**: 어휘(vanished, abruptly, casts, beneath, crowned by)와 분위기(hush, gleams, looms) 위주. 문장 구조는 복문 1개 수준으로 제한(성인 소설체 지양). 단서의 **사실**은 그대로, 표현만 간접적(예: "the bell that is its very opposite", "still short of nine"). 새 어휘는 사건 glossary에 한국어 뜻 추가.
- **장면 문구**: 접근성 라벨·조작 안내는 그대로, 상황 문장(task, 빈 장소 대답, 발견 카드)만 난이도별.

## 6. 힌트 난이도 비교 (개수·가격·구매 상태·코인·정답 불변 — 테스트)

| 미션 | Rookie(기준본) Tip 1 | Junior Tip 1 | Master Tip 1 |
|---|---|---|---|
| m01 | Read the letter again. What two things does the next museum have? | Find the line in the letter about the museum. It names two things inside. | The letter describes the museum by what lies inside it. Which two things does it name? |
| m03 | Where do the footprints stop? Look closely at that place. | Follow the footprints. Where do they stop? Look closely at that part of the wall. | Where the trail of footprints ends, what does the lamp light up? |
| ep02_m2 | Read the last two lines of the note again. One says "not". | Read the last two lines of the note. One of them says "not". What does the other one say? | Two lines of the note concern the bells. One tells you where the gear is not. What does the other tell you? |
| ep02_m3 | The thief hid the numbers in the stopped clock. What time did it stop? | The plan hides two numbers in the stopped clock. What time did the clock stop? | The plan never writes its numbers down. Where else have you already seen them today? |
| ep03_final | Two pictures have a clock tower. Look at the evidence you found today, too. | Two pictures have a tall clock tower. The driver's words cannot tell them apart. Look at today's evidence. | The driver's words fit more than one picture. Something you found earlier today can tell them apart. |

| 미션 | Rookie Tip 2 | Junior Tip 2 | Master Tip 2 |
|---|---|---|---|
| m02 | Rock and ____ mean almost the same. The thief's first letter said: 'a famous ____'. | Think back to the thief's first letter. The museum had 'a famous ____'. The same word fits here. | The thief's first letter has already used this word. What was famous in that museum? |
| ep02_final | The Time Card says 'one hour after'. That means the hour goes up by one. Do the minutes change too? | The plan says 'one hour after the clock stops'. Add one to the hour. What happens to the minutes? | How far does each hand travel in exactly one hour? |
| ep03_m3 | Wet shoes get drier with every step. Her first footprint is the wettest. Her last one is the driest. Put the other two in between. | Her first step was the wettest, and her last step was the driest. Now place the other two between them. | If shoes dry with every step, the wettest print came first. Order the rest by how wet they were. |

원칙: Rookie = 볼 곳·핵심 단어를 직접, Junior = 관련 단서를 가리키고 단계로, Master = 단서 사이의 관계를 묻는 질문. Case 03 Final Tip 2는 세 난이도 모두 "footprint"와 "notebook"을 말하고 train/station/King's Cross는 말하지 않는다. Case 01 Final Tip 1은 세 난이도 모두 기차 그림 = King's Cross 연결만 준다(Master는 "Where did you see trains?"로 질문형).

## 7. 학습 표현 (부모 보고서) — 모두 그 난이도의 실제 화면 문장에서 단어 단위 일치(`LearningCheck`, 테스트)

| 미션 | Rookie(기준본) | Junior | Master |
|---|---|---|---|
| m01 | old mummies from Egypt · a famous stone | old mummies from Egypt · a famous stone | mummies from ancient Egypt · a famous stone |
| m02 (recall m01) | a hard piece of rock · a famous stone | means a hard piece of rock · a famous stone | a word for a hard piece of rock · a famous stone |
| m03 | The footprints stop at the tower wall · The lamp shines on one stone · fresh scratches | footprints stop at the tower wall · The lamp light falls on one stone · fresh scratches | end abruptly at the tower wall · casts its light on a single stone · the scratches look fresh |
| m04 | a big palace · There is a fountain in front | a big palace · There is a fountain in front of it | a grand palace · a fountain stands before it |
| ep02_m1 | The hour hand was between eight and nine · two more small marks | had passed eight, but it had not reached nine · crept forward two more small marks | somewhere past eight, still short of nine · two more of the small marks |
| ep02_m2 | It is not under the biggest bell · the opposite of the biggest | (같음 — Junior 쪽지에 그대로 있음) | You will not find it beneath the biggest bell · its very opposite |
| ep02_m3 (recall m1) | The hour is the gallery. The minutes are the picture. | The answer is in my stopped clock · (규칙 문장) | My stopped clock holds both numbers · (규칙 문장) |
| ep02_final (recall m3) | One hour after the clock stops | 같음(의도) | 같음(의도) |
| ep03_m1 | It is under the bench · It is on the frame · It is next to the door | I saw it under the bench · It is caught on the frame · right next to the door | lies under the bench · hangs on the frame · marks the floor next to the door |
| ep03_m2 (recall m1) | Miss Rose wore a red coat and a blue scarf | Miss Rose was wearing a red coat and a blue scarf | Miss Rose was dressed in a red coat and a blue scarf |
| ep03_m3 | very wet · a little wet · almost dry · Wet shoes get drier with every step | very wet · only a little wet · almost dry · wet shoes get drier with every step | very wet indeed · simply wet · only a little wet · almost dry |
| ep03_final (recall m3) | Take me north · a tall clock tower · The boot smells of trains and smoke | 같음 | Take me north · crowned by a tall clock tower · The boot smells of trains and smoke |

학습 설계의 구조(의존도·수준·스킬·recallFrom)는 세 난이도 동일(테스트). 목표 설명(한국어)은 Master에서 그 난이도 표현에 맞춰 고쳤다.

## 8. 정답 노출 위험 점검 (모두 세 난이도 자동 테스트 — `test/difficulty_london_6a_test.dart`)
| 위험 | 점검 |
|---|---|
| Case 01 M1 선택지가 편지 단어 반복 | 선택지 이름 불변, mummies/egypt/stone 없음 |
| Case 01 M2 STONE 노출 | story·letterIntro·letter·question·prompt·hints + 돋보기 장면 모든 줄에 "stone" 없음 |
| Case 01 M3 위치 노출 | 선택 전 모든 문장(장면 단서·빈 장소 포함)에 "behind"·정답 이름 없음 — **작성 중 Junior 장면 task "…left behind."가 이 검사에 걸려 수정함** |
| Case 01 M3 단서 카드 ↔ 편지 | 단서 3줄 = 편지 3줄(글자 그대로) |
| Case 01 M1 승강장 카드 ↔ Notebook | 카드 문장 = 그 난이도 clue note |
| Case 02 9:17 | Final 자물쇠 전 사건·미션·오답 줄·선택지 피드백·Discovery·시계 퍼즐·Final 페이지·힌트 전부에서 9:17 / 917 / nine seventeen 없음 |
| Case 02 M1 8:17 | M1 화면(story~hints)에 8:17·817 없음 |
| Case 02 M2 정답 단어 | 쪽지에 "smallest" 없음, "not"·"opposite" 유지 |
| Case 02 M3 추리 결과 | 계획서·story·hints·transition에 Gallery 8 / Picture 17 없음 |
| Case 03 행선지 | Final 전 모든 문장(장면·Discovery 포함, 장화 글귀 제외)에 station(s)/train(s)/King's Cross 없음, Final 힌트에도 없음 |
| Case 03 Final 편지 | north·clock tower 포함(두 그림 해당), arches 없음 |
| 모든 힌트 | 정답(입력값·정답 선택지 이름) 미포함, `{detectiveName}` 미포함 |

## 9. 검증 (자동)
- `DifficultyContent.problems()` 빈 목록 — 구조 검사 5종(`ExploreScene`·`InspectScene`·`DeductionScene`·`DecodeScene`·`InvestigationScene`) 추가: 그림·좌표·spot id/종류/requires/checks·선택지 id·정답·taskLine·labelRoom.
- 세 난이도 × 세 사건: `structureOfEpisode` 동일, 정답·허용 답·옵션 id/순서/이름·힌트 개수·오답 키·단서 값·증거 id/글귀·코인 동일, `AnswerChecker` 판정 동일(오답은 그 난이도 줄).
- 힌트 가격·구매 상태(미션 id 기준) 세 난이도 공통.
- 옛 저장(난이도 없음) → Rookie 문장, 진행·단서·증거 유지 / 같은 저장을 Junior로 → 같은 진행, Junior Notebook 문장.
- TESTER 세션에서 Junior → Master → Rookie 전환 시 Case 01~03 문장과 장면 문구가 그 난이도로, 플레이어 세션 불변.
- 화면: Case 01 M1 탐색 첫 안내, Case 03 M2 질문·선택지가 각 난이도 문장으로 표시(390×844).

## 10. 아직 남은 문제
1. **실기기·사람 검토 없음** — 영어 문장은 작성자 검토와 자동 규칙만 거쳤다. 원어민/교육 담당 검토 권장(특히 Master의 어휘 밀도).
2. **화면 맞춤 미확인(작은 폰·글자 1.3배)** — Master의 긴 줄(예: Case 01 final story 1행, Case 03 M2 story 2행)은 기존 레이아웃 테스트가 기준본만 검사한다. 360×640·텍스트 1.3배 스크린샷 확인 필요.
3. **사건 간 연결 표현**: Case 04 이후는 아직 기준본이므로 Junior·Master 시즌에서 Case 04+ 문장이 Rookie 문체가 된다(문체 차이일 뿐 사실은 일치). 6B~6D에서 해소. 연결 고리(Red Button, LOST PROPERTY, P.S. I love trains!, One hour after)는 글자 그대로 유지했다.
4. **Glossary**: Junior·Master에서 추가한 어려운 단어는 사건 glossary에 넣었지만, "모든 새 단어가 glossary에 있다"는 자동 검사는 아직 없다(PART 5 제안 사항).
5. **장면의 접근성 라벨**(`label`, 그림 `description`)은 세 난이도 공통(스크린리더용 사물 이름).
6. 사건 ID 기준 표(intro 그림 등)·시즌 프롤로그는 PART 5대로 난이도 비대상.
