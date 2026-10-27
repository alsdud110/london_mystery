# Paris Case 07~09 — 난이도별 영어 콘텐츠 검토 보고서 (PART 7C)

> Season 2 *Paris Stands Still*. 다루는 사건: Case 07 *The Phantom Performance*, Case 08 *The Painter's Last Sketch*, Case 09 *The Clockwork Garden*.
> 작업일: 2026-10-27. 로컬 `main`에서 작업했다(시작 HEAD `19f924d`).
> 기준 문서:
> - `docs/SEASON2_PARIS_STORY_BIBLE.md` §6 (Case 07 v1.5, Case 08 v1.6, Case 09 v1.7), §7~9
> - `docs/SEASON2_CASE08_SPEC.md`, `docs/SEASON2_CASE09_SPEC.md`
> - PART 7A·7B 보고서
>
> 영어 원문 전체는 **부록 A**에 있다(실제 적용 데이터에서 자동 추출). 본문 표에는 대표 문장만 싣는다.

## 0. 결과 요약

- `s2_ep07`~`s2_ep09`를 Rookie·Junior·Master로 `season2WrittenLevels`에 등록했다.
  - 세 사건 모두 세 난이도에서 `missingAt`이 빈 목록이고, `problems()`도 빈 목록이다.
- **Rookie**: 기준본을 그대로 쓰고, 한 줄만 Rookie 패치로 바꿨다(Case 09 M3의 `mended`를 `fixed`로). glossary 단어를 추가했다.
- **Junior·Master**에서 쓴 것:
  - 사건 파일 텍스트와 미션 텍스트 전부. 여기에는 회상(recall) 제목·안내·오답 줄과 최종 보드의 오답 줄 18개가 포함된다.
  - 장면 문장 7종, EasySteps 3개, 학습 표현 12개, glossary.
- **엔진 최소 확장**: `DifficultyContent`가 회상(recall)의 오답 줄 `recall.feedback`도 증거 id 기준으로 패치할 수 있게 했다.
  - 이 줄은 Case 08 M1·M3 화면에 실제로 나온다.
  - 증거 id(키)는 바꿀 수 없다. 기준본에 없는 키를 넣으면 `problems()`가 보고한다.
- **구조 검사**: 장면 10종을 `season2StructureOf`에 추가했다. EasySteps 검사는 7B에서 만든 것을 그대로 썼다.
- **검증**:
  - 신규 `test/difficulty_paris_7c_test.dart` 30개 통과.
  - 관련 회귀 286개 통과.
  - `flutter analyze` 0 issues.
  - 전체 `flutter test` 2,476개 통과(기존 2,446 + 신규 30, 실패 0, skip 0, 5분 16초).

## A. 사건별 스토리 요약 (작성 전 전수조사)

| | Case 07 — Palais Garnier | Case 08 — Abbesses | Case 09 — Luxembourg Gardens |
|---|---|---|---|
| 이미 아는 것 | 편지 `The clocks may lie. / But the show remembers.`, 뒷면 OPERA ARCHIVE · FILE 3–4 | 수정 슬립 뒷면 ABBESSES, `P. KNEW THE BAG.`, P.의 `I saw who took the hour.` | 가방에서 떨어진 시각 변경 종이, P.의 마지막 그림(정원·작은 시계·같은 가방) |
| M1 | FILE 3(입장 3:30, 막 3:00)과 FILE 4(2시간 10분) → 쇼는 4:00 시작 | 숨긴 스케치(계단, 왼쪽 램프, 기둥 사이 검은 문)와 맞는 모퉁이 → Corner 2. 돌 뒤에 그림 묶음 | 작은 시계 셋을 지도에 놓기 → T1 개선문, T2 센강 다리, T3 Arts et Métiers |
| M2 | 사진처럼 ghost light만 켜기 → 빈 무대. 큐 카드 CUE 1 · CURTAIN UP · 4:00. 빨간 문 위 작은 시계 그림 | 아침 그림 세 장(어둠→밝음→램프 꺼짐) → 가방이 지나간 뒤 종이가 계단에 있음 = 가방에서 떨어짐 | 톱니 큰 것/작은 것 → 탑이 T1·T2·T3만 돌림, 정원 시계는 연결 안 됨. 드럼 꼬리표 KEPT AT THE STAR |
| M3 | Painted Street과 같은 배경막(빨간 문 위 작은 시계) → 주머니 속 수정 슬립 4:00→3:00 | 접힌 종이: 오페라 슬립과 같은 양식·보라 도장, FILE 번호와 시각만 찢김 | 노트의 두 표식 ↔ 옛 종이: 톱니 = CHRONOS TRIAL 문양, 두 바늘 = 수리 메모(T2 WHEEL) |
| Final | 라이트 테이블: FILE 3 덧붙인 종이 아래 4:00, 위 3:00 → 기록 변경 확인. 슬립 뒷면 ABBESSES / P. KNEW THE BAG | 찢긴 종이 = 그림 3의 종이. 보드: 출처 = 그림, 종류 = 종이 + 오페라 슬립, 결론 = 가방에서 시각 변경 종이가 떨어짐. 마지막 그림 → 지도에서 Luxembourg Gardens | 탑을 한 시간 뒤로 → 연결된 시계만 3:00, 정원 시계 4:00. 별 → T1 → Arc de Triomphe |
| 숨길 것(바이블 §8) | 수정자·지시자·이유, 이름·이니셜, P.와 배경막의 관계, 같은 손인지 | 얼굴·신원·소속, 배지 의미, 종이의 대상 기록·시각, 모형 시계의 기능 | Clockmaker 실명·동기, 두 표식이 같은 사람의 것인지, 실제 시간 소멸 여부, 가방이 정원에 온 이유 |

**스토리 바이블과 실제 구현의 차이**: 수정해야 할 충돌은 찾지 못했다.
- 바이블 v1.5~v1.7의 확정 명세와 구현 데이터는 일치한다.
- 오페라 슬립 4:00→3:00, ABBESSES, `P. KNEW THE BAG.`, 방패 배지, `A paper for changing a time fell from the bag.`, T1~T3, KEPT AT THE STAR 모두 같다.
- Case 07 M1·M2·Final은 2026-10-27에 very easy 단계 엔진으로 바뀌었다. 그래서 바이블의 옛 퍼즐 방식(슬라이드, 레버 4개, 핀 꽂기)과 화면 동작은 다르다. 사실관계는 같다.

## B. Mission별 적용 현황

| 미션 | 화면 | Rookie | Junior·Master | 장면 처리 |
|---|---|---|---|---|
| `s2_ep07_m1` | EasySteps(3:00/4:00) | 기준본 | ✓ | `easySteps` 난이도별 |
| `s2_ep07_m2` | EasySteps(레버 → 카드 → 쪽지) | 기준본 | ✓ (question은 조작 안내라 공통) | `easySteps` 난이도별(카드 힌트는 문서라 공통) |
| `s2_ep07_m3` | 배경막 밧줄 | 기준본 | ✓ | `flyRails` 공통(문서·조작·스크린리더뿐) |
| `s2_ep07_final` | EasySteps(FILE 3 → 불 → 새 시각) | 기준본 | ✓ | `easySteps` 난이도별 / `lightTables` 공통 |
| `s2_ep08_m1` | 모퉁이 고르기 + 회상 | 기준본 | ✓ (회상 제목·안내·오답 줄 포함) | `cornerChoices` 공통 |
| `s2_ep08_m2` | 그림 순서·비교 | 기준본 | ✓ | `morningSketches` 난이도별(줄 3개 + 질문) |
| `s2_ep08_m3` | 접힌 종이 + 회상 | 기준본 | ✓ (오답 줄 4개, 회상 포함) | `tornSlips` 난이도별(부분 설명 4개, 도장 오답 2개) |
| `s2_ep08_final` | 종이 맞추기 → 보드 → 마지막 그림 → 지도 | 기준본 | ✓ (보드 오답 줄 18개) | `tornHours` 난이도별(줄 13개 + 지도 오답 3개) |
| `s2_ep09_m1` | 작은 시계 → 지도 | 기준본 | ✓ | `trialMaps` 난이도별(오답 줄 4개) |
| `s2_ep09_m2` | 톱니판 | 기준본 | ✓ | `gearBoards` 난이도별(돌아갈 때 줄) |
| `s2_ep09_m3` | 표식 맞추기 | **패치 1줄** | ✓ | `makerMarks` 난이도별(오답 줄 4개) |
| `s2_ep09_final` | 탑 시험 → 별 → 지도 | 기준본 | ✓ | `towerTests` 난이도별(시각 오답 4개, 결과·이후·별 줄) |

**텍스트 분류**:
- **A. 안전하게 적용**: 사건 JSON 텍스트, 회상 제목·안내, 장면 문장, EasySteps 문장, 학습 표현.
- **B. 최소 구조 확장**:
  - 장면 10종의 구조 검사.
  - 회상 오답 줄(`recall.feedback`) 패치. 엔진 약 15줄이고, id 보호 검사를 포함한다.
- **C. 정답·진행과 결합 → 모든 난이도 동일**:
  - 퍼즐 문서: FILE 3/4, Lighting Book, 큐 카드, Painted Street 줄, 수정 슬립과 뒷면, P.의 스케치 메모·꼬리표·쪽지, 최종 보드 증거 목록, 작은 파리 옆 글, 톱니판 글, 노트의 두 표식, 시험 카드, 드럼 꼬리표.
  - 보드의 질문(선택지 라벨과 같음)과 결론 문장, 선택지 라벨, 도장 질문과 보기.
  - 그림 속 변화 이름, 장소 특징 목록, 조작 안내, 스크린리더용 그림 설명.
- **화면에 나오지 않는 문장(도달 불가)**: very easy 전환 이후 옛 화면의 오답 줄은 표시되지 않는다. `s2_ep07_m1` 선택지 오답 3개, `s2_ep07_m2` 선택지 오답 4개, `s2_ep07_final` 오답 맵 8개다. 기준본 그대로 두었고 테스트 `unreachable()`에 명시했다.

## C. 난이도별 영어 문장 비교 (대표)

| 위치 | Rookie | Junior | Master |
|---|---|---|---|
| Story — `s2_ep07` intro[2] | Tonight the opera house is dark. The archive is under the roof. | Tonight the opera house is dark. The archive is up under the roof. | Tonight the great opera house lies dark; its archive hides beneath the roof. |
| Story — `s2_ep08_m2` story[1] | The same steps, lamp and gate. But something changes. | The steps, the lamp and the gate are the same. But something changes. | Steps, lamp and gate stay the same, yet something shifts from one to the next. |
| Story — `s2_ep09` intro[5] | Look! That's the little clock from the drawing! | Look! There's the little clock from the drawing! | And there stands the little clock, exactly as he drew it! |
| Puzzle — `s2_ep07_m1` question | When did the show start? | What time did the show really start? | At what time did the show truly begin? |
| Puzzle — `s2_ep08_m3` question | What is the same as the opera slip? What is missing? | What matches the opera slip, and what is missing? | What does this paper share with the opera slip, and what has it lost? |
| Puzzle — `s2_ep09_final` question | What happened? | What happened to the clocks? | What did the test show? |
| 회상 — `s2_ep08_m1` title | These steps look familiar... | Have you seen these steps before? | These steps seem strangely familiar... |
| 보드 오답 — `s2_ep08_final` why:who | Did P. draw a face, or write a name? What do we really know? | Did P. draw a face or write a name? What do we really know? | P. drew no face and wrote no name. What do we truly know? |
| Hint 2 — `s2_ep08_m2` | When does the paper come? Look at who was on the steps just before. | Find the drawing where the paper first appears. Who was on the steps just before it? | The paper appears at one moment. What happened on the steps just before? |
| Hint 2 — `s2_ep09_m2` | The big gear goes near T1. The small gear goes near T2 and T3. | The big gear goes next to T1, and the small gear goes next to T2 and T3. | The larger space is near T1; the smaller one is near T2 and T3. |
| Step 오답 — `s2_ep07_final` 4:00 | 4:00 PM is the old time, under the patch. | 4:00 PM is the old time. It is under the patch. | 4:00 PM lies under the patch: that is the old time. |
| 장면 — `s2_ep09_final` 시험 후 | T1, T2 and T3 went with it. The garden clock still says four. | T1, T2 and T3 changed with it, but the garden clock still says four. | T1, T2 and T3 followed it. The garden clock still reads four. |
| 결말 — `s2_ep07_final` transition[3] | Is it the same hand? We don't know yet. | Did the same person do both? We don't know yet. | Was it the same hand both times? That remains unknown. |

## D. 난이도 적합성

**문체 통계**(실제 적용 데이터. 대상은 intro·synopsis·story·question·hints·success·transition):

| 범위 | 난이도 | 문장 수 | 문장당 단어 | 8글자 이상 단어 |
|---|---|---|---|---|
| Case 04~06 (7B) | Rookie / Junior / Master | 198 / 182 / 175 | 5.9 / 7.4 / 7.6 | 3.2% / 3.1% / 3.5% |
| **Case 07~09 (7C)** | Rookie / Junior / Master | 229 / 208 / 191 | 5.7 / 7.3 / 7.6 | 3.3% / 2.9% / 4.2% |

- **문체 일관성**: 7B와 같은 계단이고 폭도 거의 같다. Master의 긴 단어 비율이 조금 높다(4.2%). 섞인 어휘는 witnessed, resembles, identical, supports 정도다. 7A Master(5.2%)보다는 낮다.
- **Rookie**: Case 07~09 기준본은 이미 짧은 문장이다. 어색한 한 줄만 바꿨다: `No. 7 mended a trial wheel.` → `No. 7 fixed a trial wheel.`
- **Junior**: 접속사로 잇고 단서의 관계를 말한다. 예: "Look at FILE 3. When do the doors open?", "Find the drawing where the paper first appears."
- **Master**: 간접 표현을 쓴다. 예: "No show begins before its audience has arrived.", "Whatever was added later sits on top."
  - 조작 안내는 그대로다: Tap the brass switch, Find FILE 3, Turn on the light, Read the cue card.
- **정보량이 같은지**:
  - Master가 더한 묘사는 그림에 이미 보이는 것뿐이다: "pocket sewn behind a painted backdrop", "surrounded by tiny roofs".
  - Junior 보드 힌트 "One piece … Two others …"는 기준본 오답 줄(`needs one piece only` / `two pieces only`)에 이미 있는 정보다.

### 의도적으로 모든 난이도에서 같은 줄 (테스트 `keptAtEveryLevel`)
- **Case 07**:
  - FILE 3–4(`m1.letter`), Lighting Book(`m2.letter`), Painted Street(`m3.letter`), 슬립(`final.letter`).
  - 큐 카드 줄(`m2.transition[2]`), 슬립 줄(`m3.transition[3]`), `Under it: P. KNEW THE BAG.`(`final.transition[5]`, Case 08 intro[2]와 같은 문장).
  - `Turn on the ghost light.`(`m2.question`): 조작 안내이고 기준 학습 표현이다.
- **Case 08**: 스케치 메모·꼬리표·쪽지(`m1~m3.letter`), 증거 목록(`final.letter`), 보드 질문 `What can you say now?`(`final.question` = 선택지 라벨 = 보드 결론 질문).
- **Case 09**: 작은 파리 옆 글, 톱니판 글, 노트 표식, 시험 카드(`m1~final.letter`), 드럼 꼬리표 줄(`m2.transition[2]`), 끝 질문 `Was the hour lost — or was the clock wrong?`(hook = Case 10 synopsis·Final 질문).
- **장면 3종 전체**: `flyRails/s2_ep07_m3`, `lightTables/s2_ep07_final`, `cornerChoices/s2_ep08_m1`.
- **EasySteps의 공통 줄**: 조작 안내 say(`Find FILE 3.`, `Turn on the light.`, `Read the cue card.`, `Look at the scrap.`, `Turn on the ghost light.`), 문서 읽기(`THE CLOCK…` 류, 큐 카드 힌트), 정답 라벨.

## E. 스토리 보호 (세 난이도 모두 테스트)

| 위험 | 처리 | 테스트 |
|---|---|---|
| 수정자 이름·이니셜·이유 | Case 07에 VICTOR·É/EMILE·E.M.·V.D.·CLOCKMAKER·DELACROIX·MOREAU·`because` 없음 | 금지어 |
| 같은 손인지 단정 | `Is it the same hand?` 계열 질문 + `We don't know yet / remains unknown` | 원문 |
| P.가 배경막을 그렸는지 | 질문으로만 남긴다(`Did P. paint it?` / `Was it painted by P.?`) | `P.` + `?` 줄 존재 |
| ABBESSES·`P. KNEW THE BAG` 조기 노출 | Case 07 M1~M3 문장·장면, Final 정답 전 문장에 없음 | 검사 |
| 정답 4:00 조기 노출 | Case 07 M1 힌트(JSON·단계)에 `4:00`/`4 PM` 없음 | 검사 |
| 가방 운반자 신원·배지 의미 | Case 08에 이름·OFFICE·CHRONOS·TRIAL 없음, 얼굴 없음 줄 유지(M2·Final 각 1줄) | 금지어·줄 수 |
| 모퉁이 정답·색 노출 | Case 08 M1 힌트에 `Corner 2`·`black` 없음(색은 스케치 문장에서 읽게 함) | 검사 |
| 종이의 출처 정답 노출 | Case 08 M2 힌트에 `fell` 없음 | 검사 |
| Luxembourg 조기 노출 | Case 08 M1~M3와 Final 정답 전 문장에 없음 | 검사 |
| 두 표식 동일인 단정 | `The papers do not say / stay silent` 줄 1개 유지 | 줄 수 |
| 시간 소멸 단정 | `Was an hour (really/truly) lost?` 질문 1개 유지, hook은 기준본 그대로 | 검사 |
| Case 10·11 정보 | Case 09에 SAINT-SULPICE·PAGE 3·이름 없음, 개선문은 M1 정답 전과 M2·M3에 없음 | 금지어 |
| 보드 결론 | 결론 문장 `A paper for changing a time fell from the bag.`은 구조에 포함되어 바꿀 수 없음 | 구조 + 검사 |

## F. 구조 검사 (`season2_structures.dart`)

| 객체 | 보호하는 것 |
|---|---|
| `FlyRailScene` | 배경막 4개(문 색·문 위·탑), 정답 조건, 밧줄 좌표·판, 주머니, 수정 슬립 |
| `LightTableScene` | 바뀐 기록(file3, 4:00→3:00), 핀 자리·경로, FILE 3·프로그램·큐 카드·슬립 |
| `CornerChoiceScene` | 모퉁이 id·이름·그림·영역 |
| `MorningSketchesScene` | 그림 3장(파일·변화 영역·변화 이름·여백 스케치), 보여 주는 순서, 램프 꺼진 그림, 칸 |
| `TornSlipScene` | 접힌 종이, 양식(FILE·:00·화살표·도장 위치), 부분(id·영역·같음/빠짐·이름·설명 줄 유무), 도장 질문·보기·정답, 접힘 수, P.의 쪽지 |
| `TornHourScene` | 그림·양식·처음 회전, 보드(질문·증거·결론 id와 문장), 마지막 그림의 가방 부분·미끼 영역, 특징 목록, 지도 장소·정답, 오답 키, 줄 수 |
| `TrialMapScene` | 지도 장소, 모형(id·이름·그림·정답 장소·표식), 놓기 반경, 특수 오답 키 |
| `GearBoardScene` | 톱니 크기·자리·가지, 고정 톱니, 시계(연결·방향), 트레이 |
| `MakerMarksScene` | 노트 표식(종류·이름·출처·증거 id), 종이 표식(종류·글·좌표·각도), 오답 키 |
| `TowerTestScene` | 시계 그림·시작 4·목표 3, 시험 시계(연결 여부), 오답 시각 키, 줄 수, 별 단서(제목·꼬리표·모형·정답 t1·지도 장소) |

- 줄 단위 문장은 **개수만** 구조에 넣었다(`rightLines`처럼). 정답에 따라 말하는 줄은 **키**를 넣었다.
- 난이도별 변형은 빌더로 만든다: `_morning`·`_slip`·`_corner`·`_map`·`_gears`·`_plan`·`_tower`, 그리고 7B의 `retold`(이번에 `_steps`에서 공개 이름으로 바꿈, 동작 불변). 모두 기준 객체의 구조 필드를 복사한다.
- 결과: `problems()` 빈 목록. 2개 난이도 × 13개 표 항목의 구조 문자열이 기준과 같다.

## G. 학습 표현

부록 A의 `learning …` 행에 전체가 있다. 세 난이도의 표현 묶음이 미션마다 모두 다르다. 각 표현이 그 난이도 화면 문장에 단어 단위로 있다(LearningCheck 통과). 의존도·수준·기술·목표는 기준과 같다.

| 미션 | Junior | Master |
|---|---|---|
| 07 M1 | DOORS OPEN · 3:30 PM / What time did the show really start? | DOORS OPEN · 3:30 PM / No show begins before its audience has arrived |
| 07 Final | What is the new time on FILE 3? / switch on the light table | Which is the new time on FILE 3? / Whatever was added later sits on top |
| 08 M2 | (꼬리표 2줄) + How did the paper get onto the steps? | (꼬리표 2줄) + What brought the paper to the steps? |
| 08 Final | (보드 질문 2개) + One piece of evidence shows where the paper came from | (보드 질문 2개) + Ask what each piece of evidence proves |
| 09 M2 | Join the tower to the trial clocks. / Which gear fits it? | Join the tower to the trial clocks. / Connect the tower to the trial clocks |
| 09 Final | (카드·정답 문장) + What happened to the clocks? | (카드·정답 문장) + What did the test show? |

시즌 고정 난이도로 보고서를 만든다. 프로필 난이도를 바꿔도 Case 08 보고서는 시즌 난이도의 표현을 쓴다(세 난이도 테스트).

## H. 힌트 · Discovery

- **힌트**:
  - 개수·가격·구매 기록은 그대로다. Case 08 M2 힌트 2개를 연 기록이 세 난이도에서 유지되는지 테스트했다.
  - 미션마다 세 난이도의 힌트 묶음이 모두 다르고, 정답 라벨은 들어 있지 않다.
  - EasySteps 무료 힌트: 개수와 마지막 힌트 뒤 정답을 강조하는 구조는 그대로다. M1·M2는 미션 힌트 = 첫 단계 힌트(난이도별).
- **Discovery**: 9개 미션 모두 세 난이도 제목이 서로 다르다. 제목은 그 난이도의 successMessage다.
  - Case 08 M2와 Final의 기준본은 둘 다 `It fell from the bag!`이다. Junior·Master는 둘을 다른 문장으로 썼다(`It came from the bag!` / `The paper fell from the bag!` 등).

## I. 검증

- `test/difficulty_paris_7c_test.dart` 30개 통과:
  - 완료·누락 없음과 작성 완료 사건 전체 집합(01~09). Case 10은 아직 미작성임을 확인.
  - 고유 문장, Rookie, glossary.
  - 구조·정답·회상·코인·힌트 가격, 장면 13개 구조·조작 안내·문서, EasySteps.
  - 사건별 비밀 × 3난이도, 힌트 정답 비노출·구매 기록, Discovery, 학습 표현·보고서, 옛 저장.
  - 화면 5개: Case 07 M1을 세 난이도 390×844, Master 360×640 + 글자 1.3배, Master 834×1194로 확인했다. 확인 항목은 story, 단계 문장, 무료 힌트, 오답 줄, 정답 줄, 44pt 터치 영역, 다른 난이도 문장 미혼입, overflow·예외 없음이다.
- **기존 테스트 수정 2곳(의도적)**: `difficulty_paris_7a_test`·`7b_test`의 "작성 완료 사건 = 정확히 그때까지의 집합" 단언과 7B의 "Case 07 미작성" 단언.
  - 새 사건을 등록하면 반드시 깨지는 단언이다.
  - 그래서 각 테스트는 자기 사건이 들어 있는지만 확인하고, 전체 집합은 가장 최근 PART 테스트(7C)가 검사한다. 삭제·skip은 없다.
- 관련 회귀 286개 통과, `flutter analyze` 0, 전체 2,476개 통과.

## J. 남은 위험

- 원어민·교사 검토는 없다. 실기기 확인도 없다.
- 화면 테스트는 Case 07 M1(EasySteps)만 했다. 다음 장면의 긴 Master 문장은 화면에서 보지 않았다(문장당 +1.9단어).
  - 그림 순서, 접힌 종이, 보드, 지도, 탑 시험 장면.
- 도달 불가 옛 오답 줄 15개(§B)는 기준본 그대로다. 옛 화면이 다시 쓰이면 기준본 문체로 나온다.
- 회상 오답 줄 패치는 엔진 확장이다. London 콘텐츠는 이 키를 쓰지 않는다(영향 없음).

## K. PART 7D 인수인계

- Case 10: `drumTapes`·`cityClocks`·`shadowChecks`·`hourRecords` 구조 검사를 먼저 만든다. 정답·시각 값, 기록 목록 문장, 사진 시계 시각을 보호한다.
- Case 11·12:
  - `TalkScene`·`TalkMission` 구조 검사가 필요하다. 대사 줄 수·화자·표정·질문/제시 id·accepted·requires·finishWhen·answer를 보호한다. 대화 진행 저장값이 줄 번호이기 때문이다.
  - `List<EndingLine>` 구조 검사도 필요하다.
  - EasySteps 7개. `QuotePanel`·`MachinePanel`은 7B 검사에 이미 들어 있다.

---

## 부록 A. 전체 문장 표 (실제 적용 콘텐츠에서 자동 추출)

- 표기: `= Rookie`는 Rookie와 같은 문장, `= Junior`는 Junior와 같은 문장이다. `/`는 줄바꿈 또는 목록 구분이다.
- `scene …`/`steps …`/`learning …` 행은 각각 장면, EasySteps, 학습 표현이다.
- 모든 난이도에서 같은 장면 3종과 도달 불가 줄(§B)은 표에 싣지 않았다.

### s2_ep07 — The Phantom Performance

| 위치 | Rookie | Junior | Master |
|---|---|---|---|
| `intro` | The letter led you to the Palais Garnier. / On its back: OPERA ARCHIVE · FILE 3–4. / Tonight the opera house is dark. The archive is under the roof. / One box on the table says: FILE 3–4. | The letter has led you to the Palais Garnier. / On the back of the letter: OPERA ARCHIVE · FILE 3–4. / Tonight the opera house is dark. The archive is up under the roof. / On the table is a box marked FILE 3–4. | The letter has brought you to the Palais Garnier. / On its back, the words OPERA ARCHIVE · FILE 3–4. / Tonight the great opera house lies dark; its archive hides beneath the roof. / A single box on the table bears the label FILE 3–4. |
| `synopsis` | The letter said: the show remembers. / In the opera archive, one show has two start times. / They are one hour apart. Which one is true? | The letter said that the show remembers. / In the opera archive, one show has two different start times. / The times are one hour apart. Which one is true? | "But the show remembers," the letter said. / In the opera archive, a single show has two start times. / An hour stands between them. Which one tells the truth? |
| `objectives` | Test the show's times. / Light the stage like the old photo. / Find what was changed, and prove it. | Check the show's times. / Light the stage the way it looks in the old photo. / Find out what was changed, and show the proof. | Put the show's times to the test. / Light the stage exactly as the old photo shows it. / Uncover what was changed, and prove it. |
| `caseSummary` | The show began at 4:00. Later, someone covered FILE 3 with 3:00. | The show really began at 4:00. Later, someone covered the time on FILE 3 with 3:00. | The show truly began at 4:00; later, someone patched FILE 3 to read 3:00. |
| `hook` | What did P. see — and what was in the bag? | What did P. see? And what was inside the bag? | What did P. witness — and what did the bag carry? |
| `s2_ep07_m1.story` | FILE 3 is the office record of one show. / FILE 4 is the show's programme. | FILE 3 is the office record for one show. / FILE 4 is the programme for the same show. | FILE 3 is the office's record of a single show. / FILE 4 is that same show's programme. |
| `s2_ep07_m1.letterIntro` | Inside FILE 3–4: | Inside the box marked FILE 3–4: | Inside FILE 3–4, you find: |
| `s2_ep07_m1.letter` | FILE 3 · THE GOLDEN NIGHTINGALE · PERFORMANCE No. 34 / DOORS OPEN · 3:30 PM / CURTAIN UP · 3:00 PM / CURTAIN DOWN · 6:10 PM /  / FILE 4 · THE PROGRAMME / OVERTURE · 10 MIN / ACT ONE · 60 MIN / INTERVAL · 20 MIN / ACT TWO · 40 MIN / THE WHOLE SHOW: 2 HOURS 10 MINUTES | = Rookie | = Rookie |
| `s2_ep07_m1.question` | When did the show start? | What time did the show really start? | At what time did the show truly begin? |
| `s2_ep07_m1.hints[0]` | Read FILE 3: DOORS OPEN · 3:30 PM. | Look at FILE 3. When do the doors open? | FILE 3 tells you when the audience could come in. |
| `s2_ep07_m1.hints[1]` | The show starts after 3:30 PM. | A show cannot start before the doors open. | No show begins before its audience has arrived. |
| `s2_ep07_m1.successMessage` | It fits at 4:00! | The show fits at 4:00! | Only 4:00 fits! |
| `s2_ep07_m1.transition[0]` | The show fits only from 4:00 to 6:10. | The whole show only fits between 4:00 and 6:10. | The performance fits only between 4:00 and 6:10. |
| `s2_ep07_m1.transition[1]` | A 3:00 show would start too early and end at 5:10. | A show at 3:00 would start too early and finish at 5:10. | Starting at 3:00, it would begin too early and end at 5:10. |
| `s2_ep07_m1.transition[2]` | An old photo is clipped to FILE 3. It says: 3:00 PM · CURTAIN UP! | An old photo is clipped to FILE 3. Its caption says: 3:00 PM · CURTAIN UP! | Clipped to FILE 3 is an old photo, captioned: 3:00 PM · CURTAIN UP! |
| `s2_ep07_m1.transition[3]` | Is that true? Let's look at the stage. | Is the photo telling the truth? Let's go and look at the stage. | Can the photo be trusted? The stage may tell. |
| `s2_ep07_m1.clue.note` | FILE 3 says 3:00. But the show only fits from 4:00 to 6:10. | FILE 3 says 3:00. But the show only fits between 4:00 and 6:10. | FILE 3 claims 3:00, yet the show fits only from 4:00 to 6:10. |
| `s2_ep07_m1.evidence.description` | FILE 3 and FILE 4, from a box in the opera archive. | FILE 3 and FILE 4, found in a box in the opera archive. | FILE 3 and FILE 4, taken from a box in the opera archive. |
| `s2_ep07_m2.story` | At the back of the hall is the old lighting desk. / The ghost light has its own lever. | At the back of the hall stands the old lighting desk. / The ghost light has a lever of its own. | The old lighting desk waits at the back of the hall. / Among its levers, one belongs to the ghost light alone. |
| `s2_ep07_m2.letterIntro` | The Lighting Book says: | The Lighting Book explains: | The Lighting Book reads: |
| `s2_ep07_m2.letter` | GHOST LIGHT: one lamp on an empty stage. / We use it before the doors open, and at night. / HOUSE LIGHTS: for the audience. / FOOTLIGHTS and BIG SPOT: for the show. | = Rookie | = Rookie |
| `s2_ep07_m2.question` | Turn on the ghost light. | = Rookie | = Rookie |
| `s2_ep07_m2.hints[0]` | The ghost light has one lever. | Only one lever is for the ghost light. | The photo shows a single lamp. Which lever is its? |
| `s2_ep07_m2.hints[1]` | Tap the lever. It is lit. | Tap the ghost light lever to turn it on. | Tap that lever, and watch the stage. |
| `s2_ep07_m2.successMessage` | It matches! Only the ghost light. | It matches the photo! Only the ghost light is on. | A perfect match: the ghost light alone. |
| `s2_ep07_m2.transition[0]` | The photo shows an empty stage, not a performance. | The photo shows an empty stage, not a show. | The photo captures an empty stage, not a performance. |
| `s2_ep07_m2.transition[1]` | In the Lighting Book, a cue card for show No. 34: | Inside the Lighting Book is a cue card for show No. 34: | Inside the Lighting Book lies a cue card for show No. 34: |
| `s2_ep07_m2.transition[2]` | CUE 1 · CURTAIN UP · 4:00. | = Rookie | = Rookie |
| `s2_ep07_m2.transition[3]` | A scrap of paper is tucked in the book. | A scrap of paper is also tucked in the book. | Tucked between the pages is a scrap of paper. |
| `s2_ep07_m2.transition[4]` | On it, a tiny drawing: a small clock above a red door. | It has a tiny drawing: a small clock above a red door. | On it is a tiny drawing of a small clock above a red door. |
| `s2_ep07_m2.transition[5]` | Where have you seen that before? | Have you seen that somewhere before? | Where have you come across that before? |
| `s2_ep07_m2.clue.note` | The old photo shows only the ghost light. It was an empty stage, not a show. | The old photo shows only the ghost light, so the stage was empty. It was not a show. | Only the ghost light glows in the old photo: an empty stage, not a performance. |
| `s2_ep07_m2.evidence.description` | Kept at the lighting desk, not in the office. | It was kept at the lighting desk, not in the office. | Kept at the lighting desk, far from the office. |
| `s2_ep07_m3.story` | Beside the stage is the rope rail. / Pull a rope, and its painted backdrop comes down. | Next to the stage is the rope rail. / When you pull a rope, its painted backdrop comes down. | Beside the stage runs the rope rail. / Each rope, when pulled, lowers a painted backdrop. |
| `s2_ep07_m3.letterIntro` | The Painted Street in your notebook says: | Your notebook has the Painted Street: | From the Painted Street in your notebook: |
| `s2_ep07_m3.letter` | Above the red door: a small clock. | = Rookie | = Rookie |
| `s2_ep07_m3.question` | Which backdrop matches the Painted Street? | Which backdrop looks like the Painted Street? | Which backdrop is a match for the Painted Street? |
| `s2_ep07_m3.hints[0]` | Open your notebook: The Painted Street. Two things must match. | Check The Painted Street in your notebook. Both the door and the clock must match. | The Painted Street gives you two details. A backdrop must match both. |
| `s2_ep07_m3.hints[1]` | Lower each backdrop. Each time, look right above the door. | Bring each backdrop down and look just above its door. | As each backdrop comes down, study what sits above the door. |
| `s2_ep07_m3.successMessage` | A hidden pocket! | There is a hidden pocket! | A secret pocket behind the backdrop! |
| `s2_ep07_m3.transition[0]` | It looks like the painter's street. | It looks just like the painter's street. | It closely resembles the painter's street. |
| `s2_ep07_m3.transition[1]` | Did P. paint this? We can't be sure. | Did P. paint it? We can't be sure. | Was it painted by P.? There is no way to be sure. |
| `s2_ep07_m3.transition[2]` | In the pocket is an old slip: | Inside the pocket is an old slip: | Inside the pocket waits an old slip: |
| `s2_ep07_m3.transition[3]` | FILE 3 · PERFORMANCE No. 34 · CURTAIN UP: 4:00 to 3:00. | = Rookie | = Rookie |
| `s2_ep07_m3.transition[4]` | It says to change the record. But was FILE 3 really changed? | The slip says to change the record. But was FILE 3 really changed? | It asks for the record to be changed. But was FILE 3 ever actually changed? |
| `s2_ep07_m3.options[lampRed].feedback` | There is a red door. But what is above it? | There is a red door. But what is above the door? | The door is red, but look at what hangs above it. |
| `s2_ep07_m3.options[towerRed].feedback` | That clock is far from the door. Look right above the door. | That clock is far away from the door. Look just above the door. | That clock stands far from the door. The Painted Street has one right above it. |
| `s2_ep07_m3.options[clockBlue].feedback` | There is a small clock. But what color is the door? | There is a small clock. But what colour is the door? | The clock is right, but check the colour of the door. |
| `s2_ep07_m3.clue.note` | Behind the backdrop, in a pocket: a slip to change FILE 3. | In a pocket behind the backdrop: a slip asking to change FILE 3. | Hidden in a pocket behind the backdrop: a slip for changing FILE 3. |
| `s2_ep07_m3.evidence.description` | Found in a pocket behind a painted backdrop. | It was in a pocket behind a painted backdrop. | Discovered in a pocket sewn behind a painted backdrop. |
| `s2_ep07_final.story` | Back in the archive: two records, two start times. / One of them was changed. | You are back in the archive, with two records and two start times. / One of the records was changed. | Back in the archive lie two records with two different start times. / One of them has been altered. |
| `s2_ep07_final.letterIntro` | The Amendment Slip says: | The Amendment Slip reads: | The Amendment Slip instructs: |
| `s2_ep07_final.letter` | FILE 3 · PERFORMANCE No. 34 / CURTAIN UP: 4:00 to 3:00 | = Rookie | = Rookie |
| `s2_ep07_final.question` | What is the new time? | What is the new time on FILE 3? | Which is the new time on FILE 3? |
| `s2_ep07_final.hints[0]` | Find FILE 3. Then turn on the light. | First find FILE 3, then switch on the light table. | FILE 3 first, then the light: it shows what lies underneath. |
| `s2_ep07_final.hints[1]` | The new time is on the patch, on top. | The new time is written on the patch, on top of the old one. | Whatever was added later sits on top. |
| `s2_ep07_final.successMessage` | The record was changed! | Someone changed the record! | The record was altered! |
| `s2_ep07_final.transition[0]` | At first, FILE 3 said 4:00. Later, someone covered it with 3:00. | At first, FILE 3 said 4:00. Later, someone stuck 3:00 over it. | FILE 3 once read 4:00, until someone pasted 3:00 over it. |
| `s2_ep07_final.transition[1]` | The 3:00 show was only on paper. A phantom performance! | The 3:00 show only happened on paper. It was a phantom performance! | The 3:00 show existed only on paper: a phantom performance! |
| `s2_ep07_final.transition[2]` | 3:00 and 4:00 again, like the notices at the Eiffel Tower. | Once again it is 3:00 and 4:00, like the notices at the Eiffel Tower. | 3:00 and 4:00 once more, just like the notices at the Eiffel Tower. |
| `s2_ep07_final.transition[3]` | Is it the same hand? We don't know yet. | Did the same person do both? We don't know yet. | Was it the same hand both times? That remains unknown. |
| `s2_ep07_final.transition[4]` | On the back of the slip: a sketch of a metro sign. ABBESSES. | On the back of the slip is a sketch of a metro sign: ABBESSES. | On the back of the slip, someone sketched a metro sign: ABBESSES. |
| `s2_ep07_final.transition[5]` | Under it: P. KNEW THE BAG. | = Rookie | = Rookie |
| `s2_ep07_final.transition[6]` | The mystery continues in Montmartre! | Next, the mystery leads to Montmartre! | The trail now climbs to Montmartre! |
| `s2_ep07_final.evidence.description` | FILE 3, on the light table in the opera archive. | FILE 3, lying on the light table in the opera archive. | FILE 3, laid on the light table in the opera archive. |
| `s2_ep07_m1 steps start.say` | When did the show start? | What time did the show really start? | At what time did the show truly begin? |
| `s2_ep07_m1 steps start.hints[0]` | Read FILE 3: DOORS OPEN · 3:30 PM. | Look at FILE 3. When do the doors open? | FILE 3 tells you when the audience could come in. |
| `s2_ep07_m1 steps start.hints[1]` | The show starts after 3:30 PM. | A show cannot start before the doors open. | No show begins before its audience has arrived. |
| `s2_ep07_m1 steps start.option 3` | At 3:00 PM, the doors are not open yet. | At 3:00 PM, the doors are still closed. | At 3:00 PM, the doors had not even opened. |
| `s2_ep07_m1 steps start.tell` | The show started at 4:00 PM. | The show really started at 4:00 PM. | The show began at 4:00 PM. |
| `s2_ep07_m1 steps start.done` | Yes, 4:00 PM! THE SHOW ENDED AT 6:10 PM. | Yes, 4:00 PM! The show ended at 6:10 PM. | Yes, 4:00 PM! The curtain came down at 6:10 PM. |
| `learning s2_ep07_m1` | "DOORS OPEN · 3:30 PM", "When did the show start?" | "DOORS OPEN · 3:30 PM", "What time did the show really start?" | "DOORS OPEN · 3:30 PM", "No show begins before its audience has arrived" |
| `s2_ep07_m2 steps switch.say` | Turn on the ghost light. | = Rookie | = Rookie |
| `s2_ep07_m2 steps switch.hints[0]` | The ghost light has one lever. | Only one lever is for the ghost light. | The photo shows a single lamp. Which lever is its? |
| `s2_ep07_m2 steps switch.hints[1]` | Tap the lever. It is lit. | Tap the ghost light lever to turn it on. | Tap that lever, and watch the stage. |
| `s2_ep07_m2 steps switch.done` | Only the ghost light: an empty stage, not a show. | Only the ghost light is on: an empty stage, not a show. | The ghost light alone: an empty stage, no performance. |
| `s2_ep07_m2 steps cue.say` | Read the cue card. | = Rookie | = Rookie |
| `s2_ep07_m2 steps cue.hints[0]` | CUE 1 · CURTAIN UP · 4:00. | = Rookie | = Rookie |
| `s2_ep07_m2 steps scrap.say` | Look at the scrap. | = Rookie | = Rookie |
| `s2_ep07_m2 steps scrap.hints[0]` | It was tucked in the Lighting Book. | The scrap was tucked inside the Lighting Book. | It had been tucked between the pages of the Lighting Book. |
| `learning s2_ep07_m2` | "Turn on the ghost light." | "Turn on the ghost light.", "Only one lever is for the ghost light" | "Turn on the ghost light.", "The photo shows a single lamp" |
| `learning s2_ep07_m3` | "Above the red door: a small clock.", "look right above the door" | "Above the red door: a small clock.", "look just above its door" | "Above the red door: a small clock.", "study what sits above the door" |
| `s2_ep07_final steps file.say` | Find FILE 3. | = Rookie | = Rookie |
| `s2_ep07_final steps file.hints[0]` | Look at the top of each paper. | Look at the number at the top of each paper. | Each paper is numbered at the top. |
| `s2_ep07_final steps file.hints[1]` | FILE 3 has a big 3 in its circle. | FILE 3 has a big 3 in the circle at the top. | Look for the 3 inside its circle. |
| `s2_ep07_final steps file.option file4` | That is FILE 4, the programme. Find FILE 3. | That is FILE 4, the programme. You need FILE 3. | That is the programme, FILE 4. FILE 3 is the other one. |
| `s2_ep07_final steps file.tell` | This one is FILE 3. | This paper is FILE 3. | FILE 3 is this one. |
| `s2_ep07_final steps file.done` | FILE 3 is on the light table. | FILE 3 is now on the light table. | FILE 3 lies on the light table. |
| `s2_ep07_final steps light.say` | Turn on the light. | = Rookie | = Rookie |
| `s2_ep07_final steps light.hints[0]` | The switch is on the right of the table. | Find the switch on the right side of the table. | The light table has a switch on its right edge. |
| `s2_ep07_final steps light.hints[1]` | Tap the brass switch. | = Rookie | = Rookie |
| `s2_ep07_final steps light.done` | Look! A hidden 4:00 PM under the patch. | Look! There is a hidden 4:00 PM under the patch. | Look! Beneath the patch, a hidden 4:00 PM appears. |
| `s2_ep07_final steps time.say` | What is the new time? | What is the new time on FILE 3? | Which is the new time on FILE 3? |
| `s2_ep07_final steps time.hints[0]` | The new time is on the patch, on top. | The new time is written on the patch, on top of the old one. | Whatever was added later sits on top. |
| `s2_ep07_final steps time.hints[1]` | The old time is under the patch. | The old time is hidden under the patch. | The older time is the one underneath. |
| `s2_ep07_final steps time.option 4` | 4:00 PM is the old time, under the patch. | 4:00 PM is the old time. It is under the patch. | 4:00 PM lies under the patch: that is the old time. |
| `s2_ep07_final steps time.tell` | The new time is 3:00 PM, on the patch. | The new time is 3:00 PM. It is on the patch. | The new time, 3:00 PM, is on the patch. |
| `s2_ep07_final steps time.done` | THE TIME WAS CHANGED! | Someone changed the time! | The time was altered! |
| `learning s2_ep07_final` | "What is the new time?", "Find FILE 3." | "What is the new time on FILE 3?", "switch on the light table" | "Which is the new time on FILE 3?", "Whatever was added later sits on top" |
| `glossary (추가된 단어)` | hidden, nightingale, records, tonight | caption, explains, finish, hidden, nightingale, records, switch, tonight | altered, caption, captioned, existed, explains, finish, hidden, instructs, nightingale, pasted, records, resembles, switch, tonight, underneath |

### s2_ep08 — The Painter's Last Sketch

| 위치 | Rookie | Junior | Master |
|---|---|---|---|
| `intro` | You turn the opera slip over again. / A tiny sketch: steps, a lamp, a metro sign. ABBESSES. / Under it: P. KNEW THE BAG. / P. is the painter. He said: I saw who took the hour. / What bag? What did he see? / Abbesses is on the hill of Montmartre. Let's go. | You turn the opera slip over once more. / There is a tiny sketch: steps, a lamp and a metro sign. ABBESSES. / Under it: P. KNEW THE BAG. / P. is the painter. He once said: I saw who took the hour. / Which bag? And what did he see? / Abbesses is up on the hill of Montmartre. Let's go there. | Once again, you turn the opera slip over. / A tiny sketch of steps, a lamp and a metro sign: ABBESSES. / Under it: P. KNEW THE BAG. / P. is the painter, the one who said: I saw who took the hour. / What bag? And what did he truly see? / Abbesses sits high on the hill of Montmartre. Time to go. |
| `synopsis` | The opera slip says: P. KNEW THE BAG. / P. is the painter who went away. / He said he saw who took the hour. What did he see? | On the back of the opera slip: P. KNEW THE BAG. / P. is the painter who went away on his own. / He said he saw who took the hour. But what did he really see? | The opera slip bears four words: P. KNEW THE BAG. / P. is the painter who slipped away from Montmartre. / He claimed he saw who took the hour. What exactly did he witness? |
| `objectives` | Find where the painter sat. / Read his drawings. / Find out what P. saw. | Find the spot where the painter sat. / Look closely at his drawings. / Find out what P. really saw. | Track down where the painter sat to draw. / Study his drawings. / Work out what P. witnessed. |
| `caseSummary` | P. saw the bag. A paper for changing a time fell from it. Then he drew the bag in a garden. | P. saw the bag, and a paper for changing a time fell from it. Later, he drew the same bag in a garden. | P. watched the bag pass, and a paper for changing a time fell from it. Later he sketched that bag again, in a garden. |
| `hook` | Why did the bag go to the little clock in the garden? | Why was the bag beside the little clock in the garden? | What drew the bag to the little clock in the garden? |
| `s2_ep08_m1.story` | Abbesses. Steps, lamps and gates are everywhere. / Where did the painter sit to draw? | Abbesses. There are steps, lamps and gates everywhere. / Where did the painter sit when he drew? | Abbesses: steps, lamps and gates wherever you look. / From which corner did the painter draw? |
| `s2_ep08_m1.letterIntro` | In your notebook, you wrote: | Your notebook says: | Your notebook describes it: |
| `s2_ep08_m1.letter` | The sketch he hid in his studio: / Steps. An old lamp. A gate between two pillars. / The white church above. | = Rookie | = Rookie |
| `s2_ep08_m1.question` | Where did the painter sit to draw? | Which corner did the painter draw from? | From which corner did the painter make his sketch? |
| `s2_ep08_m1.hints[0]` | Bring the painter's hidden sketch from your notebook. Compare it with each corner. | Take the painter's hidden sketch from your notebook and compare it with each corner. | The hidden sketch in your notebook is your guide. Hold it up to each corner. |
| `s2_ep08_m1.hints[1]` | Check where the lamp stands. The sketch has no colours, so read its words. | Look at which side the lamp is on. The sketch is in pencil, so read its words for colours. | Mind the side the lamp stands on, and since the sketch has no colour, trust its words. |
| `s2_ep08_m1.successMessage` | You found the painter's corner! | This is where the painter sat! | The painter's corner, found! |
| `s2_ep08_m1.transition[0]` | The lamp on the left. A black gate. This is the painter's corner. | The lamp is on the left and the gate is black. This is the painter's corner. | Lamp on the left, gate painted black: the painter's very corner. |
| `s2_ep08_m1.transition[1]` | One stone in the left pillar is loose. | One stone in the left pillar moves. | One stone in the left pillar shifts under your hand. |
| `s2_ep08_m1.transition[2]` | Behind it: a bundle of drawings, tied with string. | Behind the stone is a bundle of drawings tied with string. | Behind it lies a bundle of drawings, bound with string. |
| `s2_ep08_m1.options[corner1].feedback` | The steps and the lamp match. Now read the sketch's words. What colour is the gate? | The steps and the lamp are right. Now read the words with the sketch. What colour should the gate be? | Steps and lamp agree, but the sketch's words name the gate's colour. Does this one match? |
| `s2_ep08_m1.options[corner3].feedback` | Look at the sketch. Is the lamp on the left of the gate, or on the right? | Check the sketch again. Should the lamp be left of the gate, or right? | Where does the sketch place the lamp: left of the gate, or right? |
| `s2_ep08_m1.recall.title` | These steps look familiar... | Have you seen these steps before? | These steps seem strangely familiar... |
| `s2_ep08_m1.recall.prompt` | Find the drawing the painter hid. | Find the drawing that the painter hid. | Find the sketch the painter hid away. |
| `s2_ep08_m1.recall.feedback[s2_ep07_e3]` | That sketch brought you here. Find the one he hid in his studio. | That sketch led you here. Find the one he hid in his studio. | That sketch only brought you here. The one you need was hidden in his studio. |
| `s2_ep08_m1.recall.feedback[s2_ep02_e1]` | That street has a red door. Look for steps and a gate. | That street has a red door. You need steps and a gate. | A red door belongs to another street. Look for steps and a gate. |
| `s2_ep08_m1.recall.feedback[s2_ep02_e4]` | That message was on the back of a canvas. Find the sketch under the paint. | That message was on the back of a canvas. Find the sketch that was under the paint. | That message came from the back of a canvas. The sketch you want lay beneath the paint. |
| `s2_ep08_m1.clue.note` | The corner in his hidden sketch. His drawings were behind a loose stone. | This is the corner from his hidden sketch. His drawings were behind a loose stone. | The corner of his hidden sketch, where his drawings lay behind a loose stone. |
| `s2_ep08_m1.evidence.description` | The corner in Abbesses where the painter sat. | The corner in Abbesses where the painter sat to draw. | The corner of Abbesses from which the painter drew. |
| `s2_ep08_m2.story` | You untie the string: three drawings of this corner. / The same steps, lamp and gate. But something changes. | You untie the string and find three drawings of this corner. / The steps, the lamp and the gate are the same. But something changes. | Untying the string, you find three drawings of this very corner. / Steps, lamp and gate stay the same, yet something shifts from one to the next. |
| `s2_ep08_m2.letterIntro` | A tag on the string says: | A tag tied to the string says: | A tag on the string reads: |
| `s2_ep08_m2.letter` | I drew this corner one morning. / First, the sky was dark. / Then it grew light. / When the sun came up, the lamps went out. / — P. | = Rookie | = Rookie |
| `s2_ep08_m2.question` | Where did the paper on the steps come from? | How did the paper get onto the steps? | What brought the paper to the steps? |
| `s2_ep08_m2.hints[0]` | Read P.'s tag. Dark sky first. When the sun comes up, the lamps go out. | Use P.'s tag to put the drawings in order: dark sky first, lamps out last. | P.'s tag gives the order: darkness, then light, then the lamps going out. |
| `s2_ep08_m2.hints[1]` | When does the paper come? Look at who was on the steps just before. | Find the drawing where the paper first appears. Who was on the steps just before it? | The paper appears at one moment. What happened on the steps just before? |
| `s2_ep08_m2.successMessage` | It fell from the bag! | It came from the bag! | The bag dropped the paper! |
| `s2_ep08_m2.transition[0]` | Drawing 2: someone with a flat bag, full of papers. | In drawing 2, someone carries a flat bag full of papers. | Drawing 2: a figure with a flat bag, stuffed with papers. |
| `s2_ep08_m2.transition[1]` | Drawing 3: the person is gone. A paper lies on the steps. | In drawing 3, the person is gone, and a paper lies on the steps. | Drawing 3: the figure has gone, and a paper lies on the steps. |
| `s2_ep08_m2.transition[2]` | The paper fell from the bag. | The paper must have fallen from the bag. | The bag must have dropped it. |
| `s2_ep08_m2.transition[3]` | P. drew the bag's badge: a small shield with leaves around it. | P. also drew the bag's badge: a small shield with leaves around it. | P. even sketched the bag's badge: a small shield ringed with leaves. |
| `s2_ep08_m2.transition[4]` | But no face. Only a hat and a back. | But he drew no face. Only a hat and a back. | Yet there is no face. Only a hat, and a back turned away. |
| `s2_ep08_m2.options[always].feedback` | Look at drawings 1 and 2. Is there a paper on the steps? | Check drawings 1 and 2. Can you see a paper on the steps? | In drawings 1 and 2, is there any paper on the steps? |
| `s2_ep08_m2.options[painter].feedback` | The painter sat across the street. The paper is on the steps. | The painter was sitting across the street, far from the steps. | The painter sat across the street, nowhere near the steps. |
| `s2_ep08_m2.options[window].feedback` | Look at drawing 2. Who was on those steps just before the paper came? | Look at drawing 2. Who was on the steps just before the paper appeared? | Drawing 2 shows who climbed those steps just before the paper appeared. |
| `s2_ep08_m2.clue.note` | The bag went up the steps. Then a paper was there. | The bag went up the steps, and then a paper was there. | First the bag went up the steps; then a paper lay there. |
| `s2_ep08_m2.evidence.description` | Three drawings of one morning, from the painter's corner. | Three drawings of one morning, drawn from the painter's corner. | Three drawings of a single morning, made from the painter's corner. |
| `s2_ep08_m3.story` | Behind the drawings is one more paper, folded small. / It is not a drawing. A note is clipped to it. | Behind the drawings, there is one more paper, folded small. / It is not a drawing. There is a note clipped to it. | Behind the drawings lies one more paper, folded tightly. / This one is no drawing. A note is clipped to it. |
| `s2_ep08_m3.letterIntro` | P.'s note says: | P.'s note reads: | In P.'s own hand: |
| `s2_ep08_m3.letter` | I found this paper on the steps. / I kept it with my drawings. / — P. | = Rookie | = Rookie |
| `s2_ep08_m3.question` | What is the same as the opera slip? What is missing? | What matches the opera slip, and what is missing? | What does this paper share with the opera slip, and what has it lost? |
| `s2_ep08_m3.hints[0]` | Bring the opera slip from your notebook. Put it beside this paper. | Take the opera slip from your notebook and put it next to this paper. | Lay the opera slip from your notebook beside this paper. |
| `s2_ep08_m3.hints[1]` | Count the seal's hands. Then compare FILE and the times on both papers. | Count the hands on the seal. Then compare FILE and the times on both papers. | Compare them part by part: the seal, the FILE band and the times. |
| `s2_ep08_m3.successMessage` | The same seal! | It has the same seal! | An identical seal! |
| `s2_ep08_m3.transition[0]` | The same form. The same purple seal. | It is the same kind of form, with the same purple seal. | The same form, and the same purple seal. |
| `s2_ep08_m3.transition[1]` | But the FILE number and the hour are torn away. | But the FILE number and the hour have been torn away. | Yet the FILE number and the hour are torn away. |
| `s2_ep08_m3.transition[2]` | Like the opera slip, it is a paper for changing a time. | Just like the opera slip, it is a paper for changing a time. | Like the opera slip, it was made for changing a time. |
| `s2_ep08_m3.transition[3]` | P. found it on the steps. Is it the paper in his drawing? | P. found it on the steps. Is it the paper from his drawing? | P. found it on the steps. Could it be the very paper in his drawing? |
| `s2_ep08_m3.feedback[need:same]` | Four things on this paper are just like the opera slip. | Four things on this paper look just like the opera slip. | Four features of this paper match the opera slip exactly. |
| `s2_ep08_m3.feedback[need:seal]` | Look closely at the seal. Count the hands. | Look carefully at the seal. How many hands does it have? | Examine the seal. How many hands does its clock have? |
| `s2_ep08_m3.feedback[need:hour]` | Read the times on the opera slip. What is in front of :00? | Read the times on the opera slip. What number comes before :00? | On the opera slip, a number stands before :00. What stands there on this paper? |
| `s2_ep08_m3.feedback[need:number]` | The opera slip says FILE 3. What does this paper say after FILE? | The opera slip says FILE 3. What comes after FILE on this paper? | The opera slip reads FILE 3. What follows FILE here? |
| `s2_ep08_m3.recall.title` | Have you seen this seal before? | Do you know this seal? | Where have you seen this seal before? |
| `s2_ep08_m3.recall.prompt` | Find the slip from the opera. | Find the slip you found at the opera. | Find the slip from the opera house. |
| `s2_ep08_m3.recall.feedback[s2_ep01_e3]` | That mark is a gear. Is this a gear? | That mark is a gear. Does this seal look like a gear? | That mark is a gear; this seal is no gear. |
| `s2_ep08_m3.recall.feedback[s2_ep05_e1]` | Count the hands. This seal has none. | That mark has two hands. This seal has none. | That mark has two hands; this seal has none at all. |
| `s2_ep08_m3.recall.feedback[s2_ep07_e4]` | That is FILE 3 itself. Find the small slip that said to change it. | That is FILE 3. Find the small slip that asked for the change. | That is FILE 3 itself. You want the small slip that ordered the change. |
| `s2_ep08_m3.recall.feedback[s2_ep06_e4]` | That is Letter 4417. Look for a purple seal. | That is Letter 4417. You need the paper with a purple seal. | That is Letter 4417. Seek the paper with a purple seal. |
| `s2_ep08_m3.clue.note` | Same form and seal as the opera slip. FILE number and hour torn away. | It has the same form and seal as the opera slip. The FILE number and the hour are torn away. | The opera slip's form and seal, but with the FILE number and the hour torn off. |
| `s2_ep08_m3.evidence.description` | A torn, folded paper, kept with P.'s drawings. | A torn, folded paper that P. kept with his drawings. | A torn, folded paper, tucked among P.'s drawings. |
| `s2_ep08_final.story` | You sit where the painter sat, with drawing 3 and the torn paper. / Is it the same paper? What does it tell us? | You sit in the painter's place with drawing 3 and the torn paper. / Is it the same paper? And what does it tell us? | From the painter's own seat, you hold drawing 3 beside the torn paper. / Are they the same paper? And if so, what does it reveal? |
| `s2_ep08_final.letterIntro` | Your evidence: | Here is your evidence: | The evidence you have gathered: |
| `s2_ep08_final.letter` | THE BAG SKETCH / A paper lies on the steps after the bag goes by. /  / THE MATCHING SEAL / A torn paper. The same form and seal as the opera slip. /  / THE AMENDMENT SLIP / FILE 3 · CURTAIN UP: 4:00 to 3:00. | = Rookie | = Rookie |
| `s2_ep08_final.question` | What can you say now? | = Rookie | = Rookie |
| `s2_ep08_final.hints[0]` | First, turn the paper until its V-shaped tear matches the drawing. | Start by turning the paper until its V-shaped tear matches the drawing. | Turn the paper until its V-shaped tear lines up with the drawing. |
| `s2_ep08_final.hints[1]` | Which evidence shows where the paper came from? Which ones show what kind of paper it is? | One piece of evidence shows where the paper came from. Two others show what kind of paper it is. | Ask what each piece of evidence proves: where the paper came from, or what it is. |
| `s2_ep08_final.successMessage` | It fell from the bag! | The paper fell from the bag! | The torn paper came from the bag! |
| `s2_ep08_final.transition[0]` | The paper fell from the bag. | The paper fell out of the bag. | The paper slipped from the bag. |
| `s2_ep08_final.transition[1]` | It is a paper for changing a time, like the opera slip. | Like the opera slip, it is a paper for changing a time. | Like the opera slip, it was meant for changing a time. |
| `s2_ep08_final.transition[2]` | But who carried it? P. never drew a face. | But who carried the bag? P. never drew a face. | Yet whose hand carried the bag? P. never drew a face. |
| `s2_ep08_final.transition[3]` | And why did the bag go to a little clock in a garden? | And why was the bag next to a little clock in a garden? | And why would the bag stand beside a little clock in a garden? |
| `s2_ep08_final.transition[4]` | The mystery continues in the Luxembourg Gardens! | Next stop: the Luxembourg Gardens! | The trail now leads to the Luxembourg Gardens! |
| `s2_ep08_final.feedback[q1:e1]` | That shows where P. sat. Which drawing shows the paper come? | That shows where P. sat. Which drawings show the paper arriving? | That only shows where P. sat. Which evidence shows the paper arriving? |
| `s2_ep08_final.feedback[q1:e1+e2]` | Question 1 needs one piece only: the drawings of that morning. | Question 1 needs just one piece: the drawings of that morning. | One piece answers Question 1: the drawings of that morning. |
| `s2_ep08_final.feedback[q1:e3]` | That is the paper itself. Which drawing shows where it came from? | That is the paper itself. Which drawings show where it came from? | That is the paper itself, not where it came from. |
| `s2_ep08_final.feedback[q1:e4]` | That slip was at the opera. Which drawing shows where this paper came from? | That slip was found at the opera. Which drawings show where this paper came from? | That slip belongs to the opera. Where did this paper come from? |
| `s2_ep08_final.feedback[q1:e2+e3]` | Question 1 needs one piece only: the drawings of that morning. | Question 1 needs just one piece: the drawings of that morning. | One piece answers Question 1: the drawings of that morning. |
| `s2_ep08_final.feedback[q1:e2+e4]` | Question 1 needs one piece only: the drawings of that morning. | Question 1 needs just one piece: the drawings of that morning. | One piece answers Question 1: the drawings of that morning. |
| `s2_ep08_final.feedback[q2:e3]` | What does a paper with this seal do? Which old clue shows it? | What is a paper with this seal for? Which older clue shows that? | The paper alone cannot say what it is for. Which older clue can? |
| `s2_ep08_final.feedback[q2:e4]` | The slip shows what the form is for. Which evidence is the paper itself? | The slip shows what this kind of form is for. Now add the paper itself. | The slip explains the form. Now add the paper itself. |
| `s2_ep08_final.feedback[q2:e1]` | That shows where P. sat. Look at the paper and the opera slip. | That shows where P. sat. Look at the paper and the opera slip instead. | That is where P. sat. The paper and the opera slip matter here. |
| `s2_ep08_final.feedback[q2:e2]` | The drawings show where it came from. What kind of paper is it? | The drawings show where the paper came from, not what kind it is. | The drawings say where it came from, not what it is. |
| `s2_ep08_final.feedback[q2:e2+e3]` | The drawings show where it came from. Which old clue shows what the form is for? | The drawings show where it came from. Which older clue shows what the form is for? | Drop the drawings. Which older clue explains the form? |
| `s2_ep08_final.feedback[q2:e1+e3]` | That shows where P. sat. Which old clue shows what the form is for? | That shows where P. sat. Which older clue shows what the form is for? | Drop the corner. Which older clue explains the form? |
| `s2_ep08_final.feedback[q2:e1+e3+e4]` | Question 2 needs two pieces only: the paper, and the opera slip. | Question 2 needs just two pieces: the paper and the opera slip. | Two pieces answer Question 2: the paper and the opera slip. |
| `s2_ep08_final.feedback[q2:e2+e3+e4]` | Question 2 needs two pieces only: the paper, and the opera slip. | Question 2 needs just two pieces: the paper and the opera slip. | Two pieces answer Question 2: the paper and the opera slip. |
| `s2_ep08_final.feedback[why:]` | Choose what the evidence shows. | Now choose what the evidence shows. | Choose the conclusion the evidence supports. |
| `s2_ep08_final.feedback[why:parts]` | What fell from the bag? A clock part, or a paper? | What fell from the bag: a clock part or a paper? | Was it a clock part that fell from the bag, or a paper? |
| `s2_ep08_final.feedback[why:painter]` | The painter was drawing. Who walked up the steps? | The painter was busy drawing. Who walked up the steps? | The painter sat drawing. Someone else climbed the steps. |
| `s2_ep08_final.feedback[why:who]` | Did P. draw a face, or write a name? What do we really know? | Did P. draw a face or write a name? What do we really know? | P. drew no face and wrote no name. What do we truly know? |
| `s2_ep08_final.evidence.description` | The torn paper, laid on P.'s drawing of the steps. | The torn paper, placed on P.'s drawing of the steps. | The torn paper, laid over P.'s drawing of the steps. |
| `learning s2_ep08_m1` | "A gate between two pillars.", "The white church above." | "A gate between two pillars.", "Which corner did the painter draw from?" | "A gate between two pillars.", "From which corner did the painter make his sketch?" |
| `s2_ep08_m2 scene sketches.lampLine` | This lamp is out. Can it come before the others? | This lamp is already out. Can this drawing come before the others? | The lamp here has gone out. Could this drawing come before the rest? |
| `s2_ep08_m2 scene sketches.skyLine` | Look at the sky. Which one is darker? | Compare the skies. Which one is darker? | Study the skies. Which is the darker one? |
| `s2_ep08_m2 scene sketches.orderedLine` | Dark, then light, then the lamp goes out. | First dark, then light, and then the lamp goes out. | Darkness, then daylight, and at last the lamp goes out. |
| `s2_ep08_m2 scene sketches.questionTask` | Where did the paper on the steps come from? | How did the paper get onto the steps? | What brought the paper to the steps? |
| `learning s2_ep08_m2` | "First, the sky was dark.", "When the sun came up, the lamps went out." | "First, the sky was dark.", "When the sun came up, the lamps went out.", "How did the paper get onto the steps?" | "First, the sky was dark.", "When the sun came up, the lamps went out.", "What brought the paper to the steps?" |
| `s2_ep08_m3 scene tornSlip.foldAcross` | Those are folds. P. folded it small. | Those are just folds. P. folded the paper small. | Only folds: P. folded the paper tightly. |
| `s2_ep08_m3 scene tornSlip.foldDown` | Those are folds. P. folded it small. | Those are just folds. P. folded the paper small. | Only folds: P. folded the paper tightly. |
| `s2_ep08_m3 scene tornSlip.tear` | The opera slip is not torn. Is this the same? | The opera slip has no tear. Is this part the same? | The opera slip is whole. Can a tear be the same? |
| `s2_ep08_m3 scene tornSlip.dust` | That is dust from the steps. | That is only dust from the steps. | Just dust, from the steps. |
| `s2_ep08_m3 scene tornSlip.seal[0].wrongLine` | Look again. Is there a hand on this clock? | Look again. Can you see any hands on this clock? | Look once more. Does this clock have a single hand? |
| `s2_ep08_m3 scene tornSlip.seal[1].wrongLine` | Look at the ring round the clock. | Look at what makes the ring around the clock. | Study the ring that circles the clock. |
| `learning s2_ep08_m3` | "What is the same as the opera slip? What is missing?", "I found this paper on the steps." | "What matches the opera slip, and what is missing?", "I found this paper on the steps." | "What does this paper share with the opera slip", "I found this paper on the steps." |
| `s2_ep08_final scene tornHour.placeHeading` | Is it the same paper? | Is this the same paper? | Could it be the same paper? |
| `s2_ep08_final scene tornHour.tearLine` | Look at the V-shaped tear. Where is it in the drawing? | Find the V-shaped tear. Where is it in the drawing? | Match the V-shaped tear. Where does the drawing show it? |
| `s2_ep08_final scene tornHour.sealLine` | Where is the round seal in the drawing? | Can you find the round seal in the drawing? | Where does the round seal sit in the drawing? |
| `s2_ep08_final scene tornHour.offLine` | P. drew the paper big in the corner. Lay it there. | P. drew the paper large in the corner. Put it there. | P. drew the paper large in the corner. Lay it over that. |
| `s2_ep08_final scene tornHour.placedLines` | The tear, the folds and the seal all match. / It is the paper from the steps. | The tear, the folds and the seal are all the same. / This is the paper from the steps. | Tear, folds and seal: every detail matches. / This is the very paper from the steps. |
| `s2_ep08_final scene lead.flat` | The same flat bag. | It is the same flat bag. | Flat, just like the bag in the sketch. |
| `s2_ep08_final scene lead.buckles` | The same two buckles. | It has the same two buckles. | Two buckles, just the same. |
| `s2_ep08_final scene lead.badge` | The same shield badge. | It has the same shield badge. | The very same shield badge. |
| `s2_ep08_final scene lead.basket` | That is a round basket. The bag in your notebook is flat. | That is only a round basket. The bag in your notebook is flat. | A round basket, not a bag. The one in your notebook is flat. |
| `s2_ep08_final scene lead.bagDone` | P. saw the bag again, in a garden. | P. saw the same bag again, in a garden. | P. saw the bag once more, this time in a garden. |
| `s2_ep08_final scene lead.feedback[louvre]` | There is a palace. But where is the glass pyramid? Is there a round pond? | There is a palace. But the drawing has no glass pyramid. Is there a round pond? | A palace, yes. But where is the glass pyramid? And the round pond? |
| `s2_ep08_final scene lead.feedback[palaisGarnier]` | That is the opera house. Is there a garden with a round pond? | That is the opera house. Does it have a garden with a round pond? | That is the opera house. Where would its garden and round pond be? |
| `s2_ep08_final scene lead.feedback[montmartre]` | That is the white church. Is there a palace? | That is the white church. Can you see a palace there? | That is the white church. No palace stands there. |
| `s2_ep08_final scene lead.otherLine` | Look for a palace, a round pond and flowerbeds. | Find a place with a palace, a round pond and flowerbeds. | Search for a palace, a round pond and flowerbeds together. |
| `s2_ep08_final scene lead.doneLines` | The Luxembourg Gardens! / In the drawing, a little clock stands on the grass. Tiny roofs are all around it. / Why did the bag go to a little clock in a garden? | The Luxembourg Gardens! / In the drawing, a little clock stands on the grass, with tiny roofs all around it. / Why was the bag next to a little clock in a garden? | The Luxembourg Gardens! / In the drawing, a little clock rises from the grass, surrounded by tiny roofs. / Why would the bag stand beside a little clock in a garden? |
| `learning s2_ep08_final` | "Where did the paper come from?", "What kind of paper is it?" | "Where did the paper come from?", "What kind of paper is it?", "One piece of evidence shows where the paper came from" | "Where did the paper come from?", "What kind of paper is it?", "Ask what each piece of evidence proves" |
| `glossary (추가된 단어)` | amendment, entrance, everywhere, familiar, matching, pyramid | amendment, arriving, carefully, entrance, everywhere, matching, pencil, placed, pyramid | amendment, arriving, bound, carefully, daylight, entrance, everywhere, familiar, figure, identical, matching, pencil, placed, pyramid, ringed, shifts, stuffed, supports, untying, witness, witnessed |

### s2_ep09 — The Clockwork Garden

| 위치 | Rookie | Junior | Master |
|---|---|---|---|
| `intro` | You look at P.'s last drawing again. / A palace. A round pond. A little clock on a stone base. / And beside it, the same flat bag. / You walk into the Luxembourg Gardens. / The palace. The pond. It's the garden from the drawing! / Look! That's the little clock from the drawing! / The same bag was here. But why? | You look at P.'s last drawing once more. / There is a palace, a round pond and a little clock on a stone base. / And next to it is the same flat bag. / You walk into the Luxembourg Gardens. / There's the palace, and there's the pond. It's the garden from the drawing! / Look! There's the little clock from the drawing! / The same bag was here once. But why? | Once more, you study P.'s last drawing. / A palace, a round pond, and a little clock on a stone base. / Beside it, that same flat bag. / You step through the gates of the Luxembourg Gardens. / The palace. The pond. This is the garden in the drawing! / And there stands the little clock, exactly as he drew it! / The bag was here too. What brought it? |
| `synopsis` | A paper for changing a time fell from a bag. / P. drew the same bag in a garden, beside a little clock. / What is that little clock? | A paper for changing a time fell out of a bag. / P. drew the same bag in a garden, next to a little clock. / And what is that little clock? | A paper for changing a time slipped from a bag. / P. drew that same bag in a garden, beside a little clock. / What could the little clock be? |
| `objectives` | Find out what the little clock is. / Make the clocks move. / Test the clocks. | Find out what the little clock really is. / Get the clocks moving. / Test what the clocks do. | Discover the secret of the little clock. / Set the clocks in motion. / Put the clocks to the test. |
| `caseSummary` | One wrong setting changed only the joined clocks. T1's star pointed to the Arc de Triomphe. | One wrong setting changed only the clocks that were joined. T1's star pointed to the Arc de Triomphe. | A single wrong setting changed only the joined clocks, and T1's star pointed the way to the Arc de Triomphe. |
| `hook` | Was the hour lost — or was the clock wrong? | = Rookie | = Rookie |
| `s2_ep09_m1.story` | The stone base has a map of Paris on it. / Three little clocks lie in a box beside it. | There is a map of Paris on the stone base. / Next to it, three little clocks lie in a box. | The stone base carries a map of Paris. / Beside it, three little clocks rest in a box. |
| `s2_ep09_m1.letterIntro` | Beside the box: | A note beside the box says: | Written beside the box: |
| `s2_ep09_m1.letter` | Put each clock back where it belongs. | = Rookie | = Rookie |
| `s2_ep09_m1.question` | Put the three little clocks back on the map. | Put each little clock back in its place on the map. | Return the three little clocks to their places on the map. |
| `s2_ep09_m1.hints[0]` | Look at each clock's shape. Find the same shape on the map. | Look at the shape of each clock, then find that shape on the map. | Each little clock copies a building. Match the shapes. |
| `s2_ep09_m1.hints[1]` | T1 is an arch. T2 is a bridge. T3 is a tall spire. | T1 looks like an arch, T2 like a bridge, and T3 has a tall spire. | An arch, a bridge, a tall spire: where does each stand in Paris? |
| `s2_ep09_m1.successMessage` | All three are back! | All three clocks are back in place! | Every clock is home again! |
| `s2_ep09_m1.transition[0]` | Only three places in Paris have trial clocks. | There are trial clocks in only three places in Paris. | Just three places in Paris hold trial clocks. |
| `s2_ep09_m1.transition[1]` | Each one has a sign: a star, three arches, a bell. | Each one has its own sign: a star, three arches or a bell. | Each bears a sign: a star, three arches, a bell. |
| `s2_ep09_m1.transition[2]` | How does one little tower reach all three? | How can one little tower reach all three? | How could one little tower reach all three? |
| `s2_ep09_m1.clue.note` | Only three places in Paris have trial clocks. | Trial clocks stand in only three places in Paris. | Just three places in Paris hold trial clocks. |
| `s2_ep09_m1.evidence.description` | The little clocks, put back on the map of Paris. | The little clocks, back in their places on the map of Paris. | The little clocks, returned to the map of Paris. |
| `s2_ep09_m2.story` | A little door opens under the model. / Gears! But two are missing. | Under the model, a little door opens. / There are gears inside! But two of them are missing. | A little door swings open beneath the model. / Gears fill the space, but two are missing. |
| `s2_ep09_m2.letterIntro` | Words on the board: | The board says: | Written on the board: |
| `s2_ep09_m2.letter` | Join the tower to the trial clocks. | = Rookie | = Rookie |
| `s2_ep09_m2.question` | Join the tower to the trial clocks. | Use the gears to join the tower and the trial clocks. | Connect the tower to the trial clocks. |
| `s2_ep09_m2.hints[0]` | Look at the dotted circles. Which gear fits each one? | Look at the size of each dotted circle. Which gear fits it? | The dotted circles differ in size. Let each one choose its gear. |
| `s2_ep09_m2.hints[1]` | The big gear goes near T1. The small gear goes near T2 and T3. | The big gear goes next to T1, and the small gear goes next to T2 and T3. | The larger space is near T1; the smaller one is near T2 and T3. |
| `s2_ep09_m2.successMessage` | They turn together! | All the joined clocks turn together! | The clocks turn as one! |
| `s2_ep09_m2.transition[0]` | The gears move the model. The real trial used wires. | Gears move the model, but the real trial used wires. | Gears drive the model, though the real trial used wires. |
| `s2_ep09_m2.transition[1]` | Under T1, a little drum writes the time. | Under T1, a little drum writes down the time. | Beneath T1, a little drum records the time. |
| `s2_ep09_m2.transition[2]` | Its tag says: TRIAL RECORDS · KEPT AT THE STAR. | = Rookie | = Rookie |
| `s2_ep09_m2.transition[3]` | A drawer opens. Who planned this machine? Who fixed it? | A drawer slides open. Who planned this machine? And who fixed it? | A drawer slides open. Who designed this machine, and who repaired it? |
| `s2_ep09_m2.clue.note` | The tower moves only the clocks joined to it. | The tower only moves the clocks that are joined to it. | The tower moves only the clocks connected to it. |
| `s2_ep09_m2.evidence.description` | The gear board under the Little Paris. | The gear board under the Little Paris model. | The gear board hidden beneath the Little Paris. |
| `s2_ep09_m3.story` | In the drawer: an old plan, CHRONOS TRIAL, with a repair note. / You know these marks! | In the drawer is an old plan called CHRONOS TRIAL, with a repair note. / You have seen these marks before! | The drawer holds an old plan marked CHRONOS TRIAL, with a repair note pinned to it. / These marks are familiar! |
| `s2_ep09_m3.letterIntro` | Your notebook says: | Your notebook has these marks: | From your notebook: |
| `s2_ep09_m3.letter` | THE CLOCKMAKER'S MARK (Gare du Nord) / A tiny carved gear. /  / THE REPAIR CARD (No. 7) / Signed with two clock hands. | = Rookie | = Rookie |
| `s2_ep09_m3.question` | Find the same marks on the old paper. | Find the same two marks on the old paper. | Find where both marks appear on the old paper. |
| `s2_ep09_m3.hints[0]` | Find the same shape on the old paper. | Look for the same shapes on the old paper. | Compare each mark with the shapes on the old paper. |
| `s2_ep09_m3.hints[1]` | The gear is on the plan. The two hands are on the repair note. | Look for the gear on the plan, and the two hands on the repair note. | One mark belongs to the plan itself; the other to the repair note. |
| `s2_ep09_m3.successMessage` | The same marks! | They are the same marks! | Both marks match! |
| `s2_ep09_m3.transition[0]` | The Clockmaker's gear is the trial's emblem. | The Clockmaker's gear is the emblem of the trial. | The Clockmaker's gear turns out to be the trial's emblem. |
| `s2_ep09_m3.transition[1]` | The two hands are on the repair note. No. 7 fixed a trial wheel. | The two hands are on the repair note. No. 7 repaired a trial wheel. | The two hands appear on the repair note: No. 7 once repaired a trial wheel. |
| `s2_ep09_m3.transition[2]` | Two marks on two different papers. Did one person make both? The papers do not say. | There are two marks on two different papers. Did one person make both? The papers do not say. | Two marks, on two separate papers. Were both made by one person? The papers stay silent. |
| `s2_ep09_m3.transition[3]` | And the paper from the bag? Is it linked to this machine? We can't tell yet. | And the paper from the bag? Is it connected to this machine? We can't tell yet. | And the paper from the bag: is it linked to this machine? Nothing tells us yet. |
| `s2_ep09_m3.clue.note` | Two marks on two papers. Who made them? The papers do not say. | Two marks on two different papers. Who made them? The papers do not say. | Two marks, two papers, and no name to say who made them. |
| `s2_ep09_m3.evidence.description` | An old trial plan with a repair note. | An old plan of the trial, with a repair note. | An old trial plan, a repair note pinned to it. |
| `s2_ep09_final.story` | You put the tower's hands back on. Every clock says four. / What if the tower is set wrong? | You put the hands back on the tower. Every clock says four o'clock. / What happens if the tower is set to the wrong time? | With the tower's hands back in place, every clock reads four. / But what if the tower were set wrong? |
| `s2_ep09_final.letterIntro` | The card says: | The card reads: | A card gives the instructions: |
| `s2_ep09_final.letter` | Set the tower one hour back. Then press TEST. | = Rookie | = Rookie |
| `s2_ep09_final.question` | What happened? | What happened to the clocks? | What did the test show? |
| `s2_ep09_final.hints[0]` | One hour back: the short hand goes from 4 to 3. | To go one hour back, move the short hand from 4 to 3. | One hour back means the short hand moves from 4 to 3. |
| `s2_ep09_final.hints[1]` | Which clocks changed? Which one stayed at four? | Check which clocks changed and which one stayed at four. | After the test, compare the clocks. Did any of them refuse to move? |
| `s2_ep09_final.successMessage` | One wrong setting! | One wrong setting did it! | A single wrong setting! |
| `s2_ep09_final.transition[0]` | One wrong setting can change several connected clocks. | One wrong setting can change many joined clocks at once. | A single wrong setting can change several connected clocks at once. |
| `s2_ep09_final.transition[1]` | And the bag? Why it came here, we still don't know. | And the bag? We still don't know why it came here. | As for the bag, why it came here remains a mystery. |
| `s2_ep09_final.transition[2]` | Was an hour really lost? The records at the star may tell. | Was an hour really lost? The records at the star may tell us. | Was an hour truly lost? The records at the star may hold the answer. |
| `s2_ep09_final.transition[3]` | The mystery continues at the Arc de Triomphe! | Next, the mystery leads to the Arc de Triomphe! | The trail now leads to the Arc de Triomphe! |
| `s2_ep09_final.options[all].feedback` | Look at the garden clock. What time does it say? | Check the garden clock. What time does it show? | Did the garden clock change too? |
| `s2_ep09_final.options[who].feedback` | The test shows HOW. Does it show WHO? | The test shows HOW it happened. Does it show WHO did it? | A test can show how. Can it show who? |
| `s2_ep09_final.evidence.description` | A test on the tower clock in the garden. | A test you did on the tower clock in the garden. | A test carried out on the garden's tower clock. |
| `s2_ep09_m1 scene trialMap.t1.wrongLine` | Look for a big arch. | Find a big arch on the map. | Seek out a great arch. |
| `s2_ep09_m1 scene trialMap.t2.wrongLine` | Look for a bridge with green bookstalls. | Find a bridge with green bookstalls. | Seek a bridge lined with green bookstalls. |
| `s2_ep09_m1 scene trialMap.t3.wrongLine` | Look for one tall spire, north of the river. | Find one tall spire, north of the river. | Seek a single tall spire, north of the river. |
| `s2_ep09_m1 scene trialMap.special[t3:notreDame]` | Notre-Dame has two towers. Find one tall spire. | Notre-Dame has two towers. You need one tall spire. | Notre-Dame has two towers, not one tall spire. |
| `learning s2_ep09_m1` | "Put each clock back where it belongs.", "Find the same shape on the map." | "Put each clock back where it belongs.", "find that shape on the map" | "Put each clock back where it belongs.", "Each little clock copies a building" |
| `s2_ep09_m2 scene gearBoard.turningLine` | T1, T2 and T3 turn. The garden clock stays still. | T1, T2 and T3 turn, but the garden clock stays still. | T1, T2 and T3 turn together; the garden clock never moves. |
| `learning s2_ep09_m2` | "Join the tower to the trial clocks." | "Join the tower to the trial clocks.", "Which gear fits it?" | "Join the tower to the trial clocks.", "Connect the tower to the trial clocks" |
| `s2_ep09_m3 scene makerMarks.lines[a:repair]` | Is that a gear? | Is that shape a gear? | Does that look like a gear? |
| `s2_ep09_m3 scene makerMarks.lines[a:key]` | Is that a gear? | Is that shape a gear? | Does that look like a gear? |
| `s2_ep09_m3 scene makerMarks.lines[b:emblem]` | Count the hands. | How many hands can you count? | Count the hands there. |
| `s2_ep09_m3 scene makerMarks.lines[b:key]` | That is a key. Look for two hands. | That is a key, not two hands. | A key, not two hands. Look again. |
| `learning s2_ep09_m3` | "Find the same marks on the old paper.", "Signed with two clock hands." | "Find the same two marks on the old paper", "Signed with two clock hands." | "Find where both marks appear on the old paper", "Signed with two clock hands." |
| `s2_ep09_final scene towerTest.hourLines[5]` | That is one hour forward. Go back. | That moves it one hour forward. Go back instead. | That is forward, not back. |
| `s2_ep09_final scene towerTest.hourLines[2]` | That is two hours back. Just one. | That is two hours back. You only need one. | Too far: that is two hours back. |
| `s2_ep09_final scene towerTest.hourLines[4]` | The tower still says four. Move it one hour back. | The tower still says four. Turn it one hour back. | The tower still reads four. One hour back, please. |
| `s2_ep09_final scene towerTest.hourLines[0]` | Just one hour back: from 4 to 3. | Only one hour back: from 4 to 3. | Only a single hour back, from 4 to 3. |
| `s2_ep09_final scene towerTest.testedLines` | The tower says three. / T1, T2 and T3 went with it. The garden clock still says four. | Now the tower says three. / T1, T2 and T3 changed with it, but the garden clock still says four. | The tower now reads three. / T1, T2 and T3 followed it. The garden clock still reads four. |
| `s2_ep09_final scene towerTest.afterLines` | The model shows what could happen. But what really happened? / The records may tell us. | The model shows what could happen, but not what really happened. / The records may be able to tell us. | A model can show what might happen. What truly happened is another matter. / Perhaps the records will tell. |
| `s2_ep09_final scene starLead.question` | Which trial clock has the star? | Which trial clock has a star on it? | Which trial clock bears the star? |
| `s2_ep09_final scene starLead.otherLine` | Look at the sign on its base. Find the star. | Look at the sign on each base. You need the star. | Check the sign on its base. Only one shows a star. |
| `s2_ep09_final scene starLead.foundLine` | The star is under T1. | The star is on the base of T1. | The star sits beneath T1. |
| `s2_ep09_final scene starLead.doneLines` | T1 stands at the Arc de Triomphe. / Twelve roads meet there, like a star. / The real records may be kept there. | On the map, T1 stands at the Arc de Triomphe. / Twelve roads meet there, like the points of a star. / Maybe the real records are kept there. | T1 belongs to the Arc de Triomphe. / Twelve roads meet there, spreading out like a star. / Perhaps the real records are kept there. |
| `learning s2_ep09_final` | "Set the tower one hour back.", "Only the joined clocks went wrong." | "Set the tower one hour back.", "Only the joined clocks went wrong.", "What happened to the clocks?" | "Set the tower one hour back.", "Only the joined clocks went wrong.", "What did the test show?" |
| `glossary (추가된 단어)` | arches, chronos, setting, twelve | arches, chronos, happens, repaired, setting, slides, twelve | arches, carried, chronos, copies, designed, happens, refuse, repaired, returned, separate, setting, slides, spreading, twelve |

## 부록 B. 재현 방법

- 원본: `lib/data/mock/season2/season2_levels_07_09.dart`. 연결: `season2_difficulty.dart`. 회상 오답 줄 패치: `difficulty_content.dart`의 `_applyMission`·`_missionProblems`.
- 확인 방법: `DifficultyContent.episodeAt(...)`, `missingAt('s2_ep08', Difficulty.master)`, `problems()`.
- 부록 A와 §D 통계는 위 API로 뽑은 것이다. 위치 체계는 테스트의 `fields()`와 같다(회상 포함).
