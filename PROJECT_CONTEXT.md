# London Mystery — PROJECT_CONTEXT

> 이 파일은 Claude Code 세션이 바뀌어도 개발 흐름을 이어가기 위한 **영속적인 작업 기억 파일**이다.
> README.md(사용자/운영자용 안내)와 달리, 이 파일은 **다음 개발 세션이 현재 상태를 정확히 파악하기 위한 문서**다.
> 새 세션은 반드시 이 파일을 먼저 읽고, 아래 *Session Continuity Protocol*을 따른다.
> 코드와 이 문서가 다르면 **코드가 source of truth**다.
>
> 최종 검증일: 2026-10-07 — `flutter analyze` 0 issues, `flutter test` **779개** 통과.
> 마지막 작업: **Investigation Board Flow Fix**(Audit의 유일한 P1 해결 — Case Closed → Board). 그 전: Final Player Experience Audit(판정 B) → Post-Discovery Small Pass → Discovery Moment → Final Small Pass(Case 06·08) → Detective Reasoning Pass(Wave 1~3).

---

## Project Overview

| 항목 | 내용 |
|---|---|
| 프로젝트 | London Mystery (`london_mystery`, v0.1.0+1) |
| 위치 | `/Users/myhwang/flutter-workspace/london_mystery` (git 저장소, 브랜치 `main`) |
| 목적 | 8~12세 어린이용 **오프라인 탐정 미스터리 게임**. 체험관/행사장에서 진행자가 운영할 수 있는 형태(Game Master 도구 포함) |
| 핵심 컨셉 | 런던 곳곳에서 영어로 된 편지·증거를 읽고, 조사한 정보를 연결해 사건을 해결한다 |
| 사용자 | 8~12세 어린이(플레이어) / 보호자(결과 리포트, Parent Gate 뒤) / 현장 운영자(Game Master) |
| 현재 단계 | **Season 1(Case 01~12) 구현·추리 구조·Discovery 완료 → 실제 아이 플레이테스트 + 출시 polish 단계** |

### 제품 철학
- **일반적인 영어 학습 앱이 아니다.** 어린이용 미스터리 어드벤처 게임이다. 영어는 게임을 진행하는 도구다.
- 번역을 먼저 보여주지 않는다. 어려운 단어만 점선 밑줄 → 탭하면 한국어 뜻 카드(glossary).
- 오답 무벌점("Not quite! Good detectives look again."). 힌트는 "Detective Tip" — 실패가 아니라 파트너의 도움.
- 결과 화면은 성적표가 아니라 **사건 파일(Case Closed)**. 보호자 리포트도 게임 리포트 톤.
- 완전 오프라인: 백엔드·계정 없음(명시 요청 전 도입 금지).
- **London Mystery는 "Story 사이에 Puzzle을 푸는 게임"이 아니라 "조사한 정보를 연결해 사건을 해결하는 게임"을 목표로 한다** (*Detective Reasoning Rules* 참고).

---

## Current Project State (2026-10-07)

- Season 1: Case 01~12 전부 구현 (Case 01 = 일반 미션 5 + Final, Case 02~12 = 3 + Final → 일반 미션 38개 + Final 12개)
- **Detective Reasoning Pass COMPLETE** (Case 02 pilot, Wave 1: 01·04·06·08·11, Wave 2: 03·07·10, Wave 3: 09)
- **Final Small Pass COMPLETE** (Case 06·08 Final의 정답 노출 제거, Case 08 동일인 판정을 플레이어가 하게 함)
- **Discovery Moment COMPLETE** (WELL DONE 화면을 대체)
- **Post-Discovery Small Pass COMPLETE** (Case 07 M3 카드 숨김, Story Evidence Card 2곳, 중복 transition 2줄)
- **Final Player Experience Audit (2026-10-07): 판정 B — SMALL EXPERIENCE PASS.** 구조 변경 불필요 (*Final UX Audit Result* 참고)
- **Investigation Board Flow Fix COMPLETE** (Audit P1): Case 01~11 Case Closed → Investigation Board → BEGIN INVESTIGATION. **PLAYTEST READY** — 다음은 실제 아이 플레이테스트 + 출시 polish

### Current Quality Baseline
- `flutter analyze` → **0 issues**
- `flutter test` → **779 passed**
- 화면 검증 기준: 360×640, 390×844 (+ 글자 크기 1.3배) — *Testing* 참고

---

## Play Flow (현재)

### 시즌 진입
Title(`/`) → Registration(`/register`) → Season Cover(`/season`, 시즌 시작 전) → Opening 5장면 + Case 01 파일(`/season/prologue`) → Story Intro(`/intro`) → Map(`/map`)

### 일반 Mission (38개)
```
Map → GO(카메라 줌 ~1.4s) → Mission: 장소(INVESTIGATE) → 봉투(TAP TO OPEN, 850ms) → 편지(SOLVE THE PUZZLE) → Puzzle
  → 정답 → DISCOVERY MOMENT → CONTINUE(사용자만) → Story Scene(transition, 타자기) → TO THE MAP → Map(새 장소로 카메라 이동 + 해금 연출)
```
- **정답 순간에 저장 완료**(완료·Clue·Evidence·배지). Discovery·Story는 보여주기만 한다.
- 오답 → "Not quite!" 시트(TRY AGAIN / GET A TIP). 횟수 제한·감점 없음.

### Final Mission (12개, Discovery 없음)
```
Map(OPEN THE FINAL CASE) → Final(/final: 장면·이야기·편지·퍼즐, OPEN MY NOTEBOOK 시트, Tips)
  → 정답 → solve reveal(2.4s, Case 02는 시계 8:17→9:17) → CONTINUE → Post-Case(Story Scene 사건 종료 모드 + 마지막 Evidence 카드)
  → SEE MY CASE REPORT → Case Closed(/solved)
  → Case 01~11: OPEN CASE NN → Investigation Board(/season, 해결 연출 1회) → BEGIN INVESTIGATION → 다음 사건 Story Intro → Map
  → Case 12: INVESTIGATION BOARD → Season Completed 보드(12/12, CLOSED)
```
- Investigation Board(`/season`, 시즌 시작 후): 해결 사건 사진·붉은 실·figure(WHO ARE THE RAVENS? → THE RAVEN SOCIETY → THE CLOCKMAKER) + 현재 사건 + BEGIN/CONTINUE INVESTIGATION(`SeasonActions.investigate` → `openEpisode` → 인트로/지도)
- `OPEN CASE NN`(`case_solved_screen.dart`): `context.go(Routes.season)` — **보드의 현재 사건이 NN일 때만**(처음 해결한 순서대로 진행 = 일반 플레이). 이미 해결한 사건을 다시 플레이해서 보드의 현재 사건이 다른 경우에는 기존처럼 `Routes.caseFile(NN)`(문구 "OPEN CASE NN"과 실제 목적지가 맞도록). 탭 수는 이전(Case Files → BEGIN)과 같음
- `go`로 이동하므로 보드에서 Back = Title(이전 보드 동작), Case Closed와 그 연출로 돌아가지 않음
- 그 밖의 보드 진입: 지도 메뉴 Season board, Title CONTINUE ADVENTURE(진행 중 사건 없음), Case Files Back. 사건 시작은 Case Files에서도 가능(BEGIN INVESTIGATION)

---

## Discovery Moment (일반 Mission 38개)

- 구현: `showDiscoveryMoment()` in `lib/features/mission/widgets/answer_feedback.dart` (기존 WELL DONE 오버레이 대체. `showGeneralDialog` 오버레이, 새 route 없음). 호출: `mission_screen.dart` `_submit` 한 곳. **Final에는 없음**
- Presentation 모델: `lib/data/models/discovery.dart` — `DiscoveryType`, `DiscoveryTiming`, `Discovery{type, timing, title, detail, showEvidence, seasonClue, note}`, `Discovery.fallback(m)`(매핑 없는 미션 = PUZZLE COMPLETE + successMessage)
- 매핑: `lib/data/mock/season1/season1_discoveries.dart` — `season1Discoveries`(미션 id → Discovery, 38개 전부 명시), `discoveryOf(m)`. **위젯에 미션별 분기 없음**(범용 렌더러)
- 화면 순서: ① 종류 라벨(글자로: DEDUCTION / NEW LEAD / EVIDENCE FOUND / CLUE CONFIRMED / CLUE FOUND / STORY DISCOVERY, + `ALSO A SEASON CLUE`) ② 큰 제목 ③ (선택) Evidence 카드(사건 종료 카드와 같은 `EvidenceChip` 종이 카드, 탭 → 확대) ④ 한 문장 detail ⑤ (선택) `NOTED IN YOUR NOTEBOOK` + Puzzle 전에 본 사실 ⑥ 작은 `+XP` ⑦ 새 배지 한 줄 ⑧ CONTINUE(glass)
- 배경: 현재 미션 장소의 장면(`PlaceScenery(PlaceArt.sceneryOf(m))`, Story Scene과 같은 공용 위젯 `lib/widgets/place_scenery.dart`) — "현장에서 발견"
- 동작: 2.2s 순차 등장(튀는 효과·컨페티 없음), **탭 = 즉시 완성**, 모션 줄이기 = 즉시 완성, CONTINUE는 한 번만, **자동 이동 없음**. Android Back = 오버레이 닫힘 → Story(이전 WELL DONE과 동일, 정답은 이미 저장)
- 테스트용 key: `ValueKey('discovery-moment')`(아래 페이지는 해결 상태로 다시 그려져 있으므로 finder는 이 안으로 한정)
- 분포: DEDUCTION 12 · NEW LEAD 9 · EVIDENCE FOUND 8 · CLUE CONFIRMED 4 · CLUE FOUND 3 · STORY DISCOVERY 2. Evidence 카드 표시 10곳(Case 07 M3 제외 후), notebook note 7곳, season clue 2곳(02-M2 기어, 05-M3 Brass Key)

### Discovery Timing 원칙 (중요)
- **Evidence가 있다고 EVIDENCE FOUND가 아니다.** 정보를 처음 가진 시점을 구분한다:
  - `beforePuzzle`(장소·편지에서 이미 봄) → **FOUND 금지**. CLUE CONFIRMED / DEDUCTION / note로 표현, 카드 표시 금지 (예: 04-M1 Black Wax Seal, 08-M1 Name Tag, 10-M2 단어 4개)
  - `fromPuzzle` → FOUND / DEDUCTION 가능
  - `afterPuzzle`(다음 Story에서 받음) → Discovery에서 미리 보여주지 않음. 필요하면 Story Evidence Card로
- 대표 예외: **Case 06 M3 Theatre Ticket**, **Case 10 M3 Ravenmaster's Letter** → Discovery에 없음, Story에서 카드
- **Case 07 M3 Joined Map: Discovery에서 카드 숨김**(카드 글귀 "…to the old gate of the park."가 Final 답). Discovery는 "north, to the top of the park"까지만. "old gate"는 Notebook Evidence에서만
- **Case 12 M3**: 저장되는 Clue "Seven Ravens"는 이 미션에서 발견한 것이 아니므로 표시하지 않음
- 같은 정보를 successMessage + clue 제목처럼 두 번 말하지 않는다(하나의 payoff)

## Story Evidence Presentation
- 설정: `season1StoryEvidence = {'ep06_m3', 'ep10_m3'}` + `storyEvidenceOf(m)` in `season1_discoveries.dart` (presentation only, 저장/progress 모델 아님)
- 표시: `story_scene_screen.dart`가 Story 줄을 다 읽은 뒤 스크롤 안에 기존 `_EvidenceCard`(사건 종료 카드와 동일, 탭 → 확대)를 한 번 놓고 자동 스크롤. 설정이 없으면 기존 Story 그대로. Final의 Post-Case 카드는 별개(기존)
- Case 06 M3: 경비원이 티켓을 건네는 줄 → 줄을 다 읽은 뒤 Theatre Ticket 카드(`ROW R · SEAT 17`). Case 10 M3: Ravenmaster 장면 → Ravenmaster's Letter 카드

## Save / Re-entry 원칙 (중요 — 바꾸지 말 것)
- 정답 → `GameController.submitAnswer` → `completedMissionIds`에 추가 → **Clue/Evidence는 저장하지 않고 `completedMissionIds`에서 계산**(`collectedClues`, `collectedEvidence`)
- Story Scene은 **한 번만** 재생된다(앱을 끄면 다시 나오지 않음, 재진입 시 지도로)
- 따라서 **Evidence 저장을 Story/Discovery 표시에 의존시키지 않는다.** Story Evidence Card는 획득 경험을 보여주는 UI일 뿐. Discovery·Story 도중 앱을 종료해도 Evidence는 유지된다(테스트로 고정: `post_discovery_pass_test` re-entry)
- 저장 시점을 Story 뒤로 옮기면 Evidence 유실 + 모델 변경이 필요하다 → 금지

---

## Detective Reasoning Rules (새 Case/Puzzle 작성 시)

- 각 Mission에서 구분: **Puzzle Answer / Observation / Evidence / Deduction / Lead / Season Evidence** — 전부 "단서"로 뭉뚱그리지 않는다
- **Story가 플레이어 대신 deduction하지 않는다** ("So it must be X!" 금지). 결론은 플레이어가 Puzzle/Final에서 내리고, Post-Case는 확인만
- Final은 가능하면 앞 Mission의 실제 정보에 의존(Final 화면만 보고 풀리면 안 됨). 정답 명칭을 편지·질문·힌트가 그대로 말하지 않는다
- Notebook/Evidence는 reasoning material — 기억하면 바로, 잊으면 Notebook/Archive에서 확인 가능하게(목표: OPTIONAL BUT USEFUL)
- 힌트: Tip 1 = 무엇을 비교/생각할지, Tip 2 = 어디를 보면 되는지(Notebook/Archive의 Case 번호까지). 정답 문자열 금지(테스트로 강제)

### Reuse Level
- **R0**: 다시 사용 안 됨 / **R1**: Story·thematic callback / **R2**: 다시 나오지만 답이 다시 제공되거나 필수 아님 / **R3**: 플레이어가 기억하거나 Notebook에서 확인해 **실제 reasoning에 사용**
- 모든 Puzzle answer를 R3로 만들 필요는 없지만, Mission 전체가 단순 Puzzle Gate가 되지 않게 한다. "Story가 다시 말해준 정보"는 R3가 아니다

### Discovery / Story 역할 분리
- Discovery = **WHAT DID I JUST LEARN / FIND?** / Story = **WHAT HAPPENS BECAUSE OF IT?**
- Story는 Discovery 문장을 그대로 다시 읽지 않는다(짧은 반응·행동으로 이어감). 새 맥락이 있는 약한 반복은 허용

### 핵심 Reasoning 구조 (깨뜨리지 말 것)
| Case | 구조 |
|---|---|
| 01 | 자물쇠 그림(clock·train·park·museum) → 장소 → 장소의 숫자(7·9·2·4) → **7924** |
| 02 | M1 **8:17** → M3 Gallery 8 · Picture 17 → plan "one hour after the clock stops" → Final **9:17** (9:17은 Final 전 어디에도 없음) |
| 03 | M3 Wet Footprint "The boot smells of **trains and smoke**" + 택시 "north, clock tower" → 시계탑 2개 중 **King's Cross** |
| 04 | M1 Black Wax Seal(까마귀) + M3 "Black birds live there(Tower)" → **RAVEN** Society |
| 05 | M1 5시 · M2 기어 4개 · M3 까마귀 7 → 순서를 바꾼 질문 → **745** |
| 06 | Final 관찰(tall man, small bag, 물가에서 잃어버린 것) + M1 작은 가방·카드를 떨어뜨림 + M3 키 큰 남자 vs 키 작은 여자(Raven Society) + M2 Detective Card → **Inspector Grey** (Final 화면에 grey/hat/card 없음) |
| 07 | Grey 경로(다리 건너 **왼쪽**) + M3 Joined Map 화살표 **north** → old gate 지도(B). Final 보기는 A~D 글자만. **Discovery에서 "old gate" 노출 금지** |
| 08 | Mrs Robin "Gallery 8에 간 적 없다" + M2 긴 빨간 코트(Clue note에도) + **Case 03 Red Button**(From a coat, GALLERY 8) → Red Button → Post-Case가 Miss Rose = Mrs Robin 확인. Final 화면에 button/coat/red 없음 |
| 09 | M1 **guard's** key → 쪽지 "the one **whose** key you used"(쓴 사람 Anna가 아님) → Carl → 소거(Ben = 가방, Anna ≠ 검정) → **HAT** |
| 10 | M2 NORTH · TOWER · BRIDGE · THREE → M3 TOWER + BRIDGE = **Tower Bridge**(Story에 Tower Bridge·north tower·3시 미리 쓰지 않음). Final은 문장 순서(독립 ORDER 퍼즐 — 다양성 예외로 유지) |
| 11 | Case 01 Old Letter "Signed: The Shadow / P.S. I love trains!" → **The Shadow** |
| 12 | M2 Case 04 Platform 4(작은 빨간 시계) → 11:40, M1 톱니 8, (Case 05) 까마귀 7 → **487** |

### Cross-case callbacks
| From → To | 내용 | 등급 |
|---|---|---|
| 04 → 12 | Platform 4 = small red clock → 12-M2 도착 시각, Final 기차 자물쇠 | **R3** (Archive 3탭) |
| 03 → 08 | Red Button(코트 단추, GALLERY 8) → 08 Final | **R3** (Archive 4탭) |
| 01 → 11 | Old Letter(The Shadow, P.S. I love trains!) → 11 Final | **R3**(약: 소거로도 근접) (Archive 4탭) |
| 05 → 12 | Seven Ravens → 12 Final 까마귀 자물쇠 | R2 (12-M3 Clue가 값을 줌) |
| 02 → 12 | 까마귀 도장 기어 → 12-M1 | R2 (편지가 속성을 다시 말함) |
| 05 → 07 | Old Map Fragment → Case 07 park piece | R1 |
| 05 → 12 | Brass Key "FOR THE CLOCKMAKER'S DOOR" → 12-M3·Final Story | R1 |
| 06 → 10·11 | ROW R · SEAT 17 → 10 Post-Case, 11 synopsis/intro | R1 |

### Continuity Guardrails
- Case 01: 까마귀 표식을 넣지 않는다(테스트로 고정). Pocket Watch("stopped at 7 o'clock")를 Case 12 Clockmaker's Watch와 같은 물건으로 만들지 않는다(그림도 다름: Case 01은 기호, Case 12는 `pocket_watch.png`). "P.S. I love trains!" 유지
- Case 03: Miss Rose = red coat + blue scarf, Red Button은 Gallery 8 벤치 아래 — Case 08이 의존
- Case 06: Inspector Grey는 아군. Silver Whistle(현재 미사용), "Find the other half in Hyde Park" → Case 07
- Case 10: 경고문 THE CLOCKMAKER WILL STOP BIG BEN AT MIDNIGHT, Clockmaker가 Ravenmaster를 감시, Post-Case의 ROW R / SEAT 17 → Case 11. Shadow 이름은 Case 11 전까지 말하지 않음
- Case 11: Shadow 정체 공개 + 조력자. Post-Case에 "under Big Ben" / "door" 금지(Case 12 M3 수수께끼의 답)
- Case 12: midnight, Big Ben, Clockmaker는 사라짐(직접 등장 없음), 마지막 줄 **PARIS.**(Season 2 hook). Season Completed 화면은 PARIS를 반복하지 않음
- Season 화면 스포일러 규칙: figure는 해당 사건 해결 후에만(Grey·Rose·Robin·Shadow·PARIS는 시즌 화면에 없음)

---

## Visual System

- **Cinematic World**: full-screen 빅토리아 런던/장소 artwork, dark navy·near-black, 따뜻한 amber 빛, antique gold, 약한 vignette (Title, Season Cover/Opening, Story Intro, Discovery, Story Scene, Final, Post-Case)
- **Physical Casebook / Documents**: warm ivory 종이 — 폼·편지·퍼즐·미션·노트북·사건 파일
- **Detective Desk**: dark walnut(`DeskBackground`) — Final, Case Closed, Season Board 등 물건/결과 순간
- 주 행동: 어두운 화면 위 = `GameButtonStyle.glass` / 종이 위 = navy 버튼(유효). legacy 스타일(밝은 gold 대형 버튼, 흰 카드, 컨페티, WELL DONE 도장)로 되돌리지 않는다
- 밝기 리듬(일반 미션): Map(종이) → Mission·편지·Puzzle(종이) → Discovery(어두운 현장) → Story(어두운 현장) → Map(종이)

### Typography (`lib/core/theme/app_text.dart`, `pubspec.yaml`)
- **IM Fell English SC** (`AppText.display`): 빅토리아풍 display / 장소·사건·문서 이름 / editorial accent
- **Sentient** (`AppText.body`, variable 200~700): 주 UI·본문·버튼·라벨·퍼즐
- **Libre Baskerville Italic** (`AppText.italic`): aside/부제 이탤릭 전용
- 한글 fallback: 시스템 폰트. 앱 전체 글자 크기 최대 1.3배 clamp
- (Cinzel·Nunito·Fredoka는 더 이상 쓰지 않는다)

### Artwork
- 스타일: Victorian storybook, engraved pen-and-ink + muted watercolor, aged parchment, warm tan·antique gold·burgundy·muted navy/green. 금지: photorealistic, glossy 3D, flat generic vector
- 새 artwork는 Story의 물건/장소가 정말 필요할 때만. 등록·대체는 `lib/widgets/art_assets.dart`(`ArtAssets`) + `place_art.dart`(`PlaceArt.sceneOf / placeOf / sceneryOf`) 한 곳. 파일이 없으면 `LandmarkArt` 코드 그림으로 폴백
- 특수 규칙:
  - Case 02 시계: `big_ben/clock_face.png` + **코드로 그린 바늘** — m3·Final 장면은 8:17, Final 해결 진행도에 맞춰 9:17(`ArtAssets.changesWhenSolved`). m1(Westminster Bridge = bigBen), m2(clockMechanism)는 시각을 보여주지 않음
  - Case 05 Final: `objects/iron_chest.png` / Case 12 Final: `objects/small_iron_door.png`
  - Case 07 지도 퍼즐: parkMapA~D(코드 그림). Final 보기 이름은 화면에 표시하지 않음(A~D)
  - Case 08: 검은 가방(blackSuitcase), Case 01·04: 갈색 가방(oldSuitcase)
  - 이미지 선택 퀴즈 타일은 이름표를 숨김(정답 노출 방지)

---

## Architecture

```text
lib/
├── main.dart, app.dart          # SharedPreferences·카탈로그 선로딩, MaterialApp.router, 글자 1.3배 clamp, lifecycle → 플레이 시계
├── core/ constants · router(app_router.dart: Routes + redirect 가드) · theme(app_colors, app_text, app_tokens, app_theme) · utils(answer_checker, audio_service, formatters)
├── data/
│   ├── models/      episode, mission(Mission/Clue/Evidence/ChoiceOption/MissionType/Artwork), game_progress, season, season_progress, discovery
│   ├── mock/season1/ episode01~12_mock.dart(백엔드 JSON과 같은 const Map), season1_mock.dart(카탈로그·시즌 정보), season1_discoveries.dart
│   └── repositories/ EpisodeRepository(+Mock), ProgressRepository(+SharedPrefs, InMemory)
├── features/
│   ├── onboarding/  start, register, episode_select(Case Files), story_intro
│   ├── season/      season_screen(Cover/Board), season_prologue_screen, season_overview, season_actions, widgets(investigation_board, prologue_art, season_props)
│   ├── mission_map/ mission_map_screen(Map Camera), map_world, widgets(london_map_painter, map_pin)
│   ├── mission/     mission_screen, story_scene_screen, final_mission_screen, qr_scanner_screen, widgets(question_widgets, qr_question, answer_feedback = Discovery Moment·Try Again·TipsPanel)
│   ├── notebook/    notebook_screen(THIS CASE / CASE ARCHIVE), season_archive
│   ├── result/      case_solved_screen, parent_report_screen, detective_report
│   ├── game/        game_controller, game_providers, scoring(XP·Badge)
│   └── game_master/ game_master_screen, parent_gate, playtest_tools
└── widgets/         art_assets, place_art, place_scenery, landmark_art, evidence_card, clue_card, letter_card, game_button, game_dialog, paper(_background), desk_background, ink_icon, glossary_text, typewriter_text, back_to, …
```

### State
- flutter_riverpod 3 (`Notifier`, 코드 생성 없음). `gameControllerProvider`(현재 사건의 `GameProgress`, 모든 변경 즉시 저장), `seasonProvider`(`SeasonProgress`), `currentEpisodeProvider`(seasonProvider.activeEpisodeId + 카탈로그), `recentUnlockProvider`/`recentSolveProvider`(연출용, 저장 안 함), `operatorAccessProvider`(운영자 모드, 세션 전용), `parentReportAccessProvider`(1회용)

### Routing (go_router 18)
| Path | 화면 | 가드 |
|---|---|---|
| `/` | Start | 항상 |
| `/register` | Registration | 항상 |
| `/season` | Cover(시즌 시작 전) / Investigation Board | 탐정 등록 |
| `/season/prologue` | Opening 5장면 + Case 01 파일 | 탐정 등록 |
| `/episodes` (`?case=epNN`) | Case Files(해당 사건 열림·선택) | 탐정 등록 |
| `/intro` | Story Intro | 탐정 등록 |
| `/map`, `/notebook`(`?view=archive`), `/scan` | 지도 / 노트북 / QR | + introSeen |
| `/mission/:id` | Mission(일반만) | 해금된 미션 |
| `/story/:id` | Story Scene(일반 = transition, Final = Post-Case) | 해당 미션 해결 후 |
| `/final` | Final | 그 사건 일반 미션 모두 해결 |
| `/solved` | Case Closed | 사건 해결 후 |
| `/report` | Parent Report | 사건 해결 + Parent Gate 통과권 |
| `/game-master` | Game Master | Parent Gate |

### Persistence
- 키: `lm.progress.v1`(Case 01, 구버전 호환) / `lm.progress.v1.epNN` / `lm.season.v1`(`activeEpisodeId`, `solvedEpisodeIds`) / `lm.settings.sound`
- `GameProgress`: detectiveName, introSeen, completedMissionIds(해결 순서), attempts, wrongAnswers, hintsUsed, missionStartedAt, missionStartPlayMillis, solveSeconds, badgeIds, lookedUpWords, startedAt, completedAt, playMillis. 관대한 fromJson, 손상 시 새 게임
- Play again = 현재 사건만 초기화(시즌 해결 기록 유지 → 다음 사건 잠기지 않음). Reset all = 전체 삭제(Start NEW ADVENTURE, Game Master)

---

## Game Systems

- **XP** (`scoring.dart`, 저장 안 함·매번 계산): 일반 +100 / Final +200, 노힌트 +50(1개 +25), 스피드(활성 시간 ≤120s, Final ≤180s) +20. 표시: Discovery(작게), 지도 메뉴, Case Closed. **XP로 열리는 것은 없음**(등급/칭호 미구현)
- **Hint**: 미션당 최대 2개(약 → 직접), 비용 = 보너스 XP만. 오답 횟수 무제한·감점 없음 → 아이 혼자 진행 가능
- **Badge**: 공통 6개(First Clue, Sharp Eyes, Quick Thinker, Puzzle Solver, London Explorer, Master Detective)가 **사건마다 다시** 수여 + Case Badge 6개(02 Clock Watcher, 03 Evidence Hunter, 04 Letter Reader, 05 Code Breaker, 07 Map Master, 12 London Legend). Discovery에 "New badge:" 한 줄
- **Evidence/Clue**: 미션 데이터, `completedMissionIds`에서 파생. 노트북 확대(`showEvidenceZoom`: 이름·장소·설명·글귀)
- **Notebook**: THIS CASE(CLUES / EVIDENCE / BADGES) + CASE ARCHIVE(12 사건 폴더, SOLVED 사건은 전체 Evidence·Clue). 경로: 미션 앱바 노트북 / Final `OPEN MY NOTEBOOK` → `OPEN THE CASE ARCHIVE`(이전 해결 사건이 있을 때). 이전 사건 Evidence 글귀까지 Final에서 4탭
- **Play Time**: foreground 활성 시간만(`playMillis`), Story Intro 종료부터 Final 해결까지
- **Parent Report**: Case Closed → Parent Gate(곱셈) → 1회용 통과권
- **Game Master / Playtest tools**(debug 또는 `--dart-define=LM_PLAYTEST=true`): CASE NN부터, 지금 사건 처음부터, OPERATOR MODE(모든 사건 열기, 해결 기록 없음). QR은 Case 01 M5뿐(`LM-EP01-PALACE`, 수동 입력 폴백 — 집에서는 운영자 카드 필요)

---

## Testing

- 실행: `flutter analyze`, `flutter test`. 스크린샷: `LM_SCREENSHOTS=<폴더> flutter test <파일>`, UI 투어: `LM_TOUR=<폴더> [LM_TOUR_SMALL=1] flutter test test/ui_tour_test.dart`
- 추리/Discovery 회귀 테스트 (문구를 바꾸면 반드시 확인):
  - `case02_reasoning_test.dart`, `wave1_reasoning_test.dart`(01·04·06·08·11), `wave2_reasoning_test.dart`(03·07·10), `case09_reasoning_test.dart`, `final_small_pass_test.dart`(06·08 + **다른 사건 JSON 해시** — 다른 사건을 일부러 바꾸면 그 해시를 갱신)
  - `discovery_moment_test.dart`(38 매핑, timing, 시점 예외, 표시·흐름·XP·배지·모션·Back, 38개 × 2 크기 렌더), `post_discovery_pass_test.dart`(Case 07 노출, 중복 줄, Story 카드·확대·재시작), `investigation_board_flow_test.dart`(Case 01~11 OPEN CASE → Board·figure·현재 사건, BEGIN, Back, 다시 플레이 예외, 재시작, Case 12 불변, 실제 Case 04 흐름)
  - 공용 헬퍼: `test/mission_play.dart`(`MissionPlay.openPuzzle / solve / restart`), `helpers.dart`(`testOverrides`), `full_playthrough_test.dart`(`reveal / tapText / wait`)
- 콘텐츠 규칙: `season_content_test.dart`(힌트·장면이 정답을 말하지 않음 등), 흐름: `season_flow_test`, `season_playthrough_test`, `post_case_scene_test`, `back_navigation_test`
- UI 변경 시 기본 확인: **360×640, 390×844**(+ 글자 1.3배) — overflow, CTA 접근, 스크롤, Evidence 확대, Back, 모션 줄이기

---

## Final UX Audit Result (2026-10-07)

**판정: B — SMALL EXPERIENCE PASS.** 핵심 경험(추리 사슬·Discovery·런던 장면·물리적 증거·Case 간 callback)은 완성 단계. 구조 변경 불필요. 실제 아이 플레이테스트 준비 완료.

### 지켜야 할 강점
Case 02·03·07·08·09·11의 추리 사슬 / Discovery Moment(현장 배경 + 실제 발견) / cross-case R3 3개(03→08, 01→11, 04→12) / Final이 Notebook·Archive를 쓰게 만드는 힌트 / 런던 장면 artwork와 Cinematic ↔ Casebook 리듬 / Investigation Board 디자인 / 무벌점 오답 + 2단계 Tip / Case 12 PARIS hook

### 남은 마찰 (P0 없음)
- ~~**P1** Case Closed가 Investigation Board를 건너뜀~~ → **해결됨**(Investigation Board Flow Fix): OPEN CASE NN → Board
- **P2** 공통 배지 6개가 사건마다 다시 수여 → "New badge: First Clue…"가 시즌 동안 약 70회 반복
- **P2** 미션당 이동 탭 약 7회(GO·INVESTIGATE·TAP TO OPEN·SOLVE THE PUZZLE·CONTINUE·(skip)·TO THE MAP) + 대기(줌 1.4s, Discovery 2.2s, 타자기 ~7s, 지도 이동+해금 ~3s; 탭 skip 없으면 미션당 약 14s). 단일 랜드마크 사건(02~11)에서 지도 왕복이 "중간 화면"처럼 느껴질 수 있음
- **P2** Case 12 Final이 Case 01·05와 같은 숫자 자물쇠 회수형 → 피날레 규모감은 Story에 의존
- **P3** MC 18/50, Case 08~12 첫 미션이 모두 "묘사 비교·선택", 사건 종료 애니메이션(Final 2.4s, Case Closed 2.8s+0.9s, 지도 해금 2s)은 탭 skip 없음, Discovery 라벨 영어(CLUE CONFIRMED·STORY DISCOVERY)가 8세 ESL에게 추상적, 1회성 이름 부담(Case 08~10), Mr Grey(Case 03)와 Inspector Grey 이름 겹침, Case 12 Case Closed에도 "London needs you again."

### Known Low-Priority Polish (P3 — 실제 UX 문제가 확인될 때만 다시 검토. "반드시 고칠 것" 목록 아님)
- Story 반복: 02-M3 "The time was a message", 07-M1 조각 발견 줄, 01-M4 "last stop", 08-M1, 12-M1 detail ≈ 카드 글귀
- Discovery 제목 ↔ Evidence 카드 이름 반복(BRASS KEY / Brass Key 등)
- 애매한 Discovery type: 01-M2, 05-M2, 06-M3, 09-M3
- 보여주지 않는 Evidence: Golden Key, London Map, Velvet Card, Toy Train Whistle (획득 장면이 없고 이후 추리에 안 쓰임 → 현재 의도적으로 숨김). Silver Whistle 미사용
- Case 06 "R for Raven. 17, like 8:17." Story 해석(MINOR), Case 10 M1 "R.M. … Raven Master?"(MINOR)
- Case 01 Old Letter의 "P.S. I love trains!"는 편지 본문에 없고 Evidence 글귀·Post-Case에만 있음

---

## Known Issues (기능/환경)
- [ ] 실기기 확인 필요: lifecycle(홈·앱 전환·잠금 시 플레이 시간), QR·카메라 권한, 사운드, Title ambient(Impeller blend 수정 후)
- [ ] foreground 강제 종료 시 마지막 행동 이후 플레이 시간 손실(의도된 트레이드오프)
- [ ] 정답이 앱 번들에 포함(오프라인 게임이라 허용, 백엔드 도입 시 서버 검증 필요)
- [ ] 웹 배포 시 보안 헤더는 호스팅에서 설정 / README의 macOS QR 설명과 실제 플랫폼 불일치(macos 폴더 없음)
- [ ] 런처 아이콘·스플래시 기본값, 효과음은 합성 placeholder(`tool/gen_sounds.js`), BGM·TTS 없음
- [ ] Game Master 접근 권한이 세션 동안 유지(웹에서 URL 재진입 가능)
- [ ] (경미) CONTINUE ADVENTURE로 Case Files에 들어오면 인트로를 안 본 사건은 선택되지 않음
- [ ] (경미) Final 첫 진입 시 360×640 첫 화면에 자물쇠가 보이지 않음(재진입 시 자물쇠로 스크롤)
- [ ] (경미) `StorySceneScreen.build()`에서 `lines.isEmpty`면 `_done = true` 대입(실제 발생 없음)
- [ ] Custom Asset Required: `docs/art/VISUAL_ASSET_INVENTORY.md`

---

## Next Development Goal
1. **실제 아이 플레이테스트** (`docs/playtest/SEASON1_PLAYTEST_CHECKLIST.md`) — 관찰: Case 02 시계 읽기, Case 09 whose/who, Case 08/11 Archive 4탭, Discovery 라벨 이해, 미션당 탭/대기 피로, 사건당 플레이 시간(예상 Case 01 20~25분, 다른 사건 10~15분, 시즌 약 3시간)
2. (선택) 공통 배지 알림 반복 완화(P2) — 플레이테스트 결과를 보고 결정. (Audit MINIMAL NEXT PASS의 ① Board 경유는 완료)
3. 출시 polish: 아이콘·스플래시, 효과음, 실기기 QA
- `Proposed`(미승인): Season 2(Paris), 탐정 등급/칭호, TTS/난이도

---

## Development Rules
1. Never rebuild the project from scratch. 2. Never delete existing functionality without explicit approval. 3. Always inspect existing code before modifying a feature. 4. Reuse the existing architecture. 5. No unnecessary dependencies. 6. No backend unless explicitly requested. 7. Keep the game playable from start to finish. 8. Preserve the mystery/adventure identity. 9. Not a generic English learning app. 10. Prefer simple, maintainable solutions. 11. Never mark a feature COMPLETE unless implemented and verified. 12~14. Update PROJECT_CONTEXT.md when features, architecture decisions or issues change. 15~17. Read this file first each session, compare with code; **code is the final source of truth**. 18. Preserve existing working functionality.

### Project conventions
- 콘텐츠는 데이터: 새 사건/미션은 `data/mock/` JSON 형태(위젯 코드 없음). Discovery·Story Evidence는 `season1_discoveries.dart` 매핑(위젯 분기 금지)
- 상태 변경은 `GameController`로만, 즉시 저장. 저장 역직렬화는 `jsonDecode` + 수동 파싱
- 새 화면 = `Routes` + redirect 가드(URL로 건너뛰기 불가)
- 색·간격·글자는 토큰(`AppColors`, `AppSpace`, `AppText`) 사용, 위젯에 임의 색 금지
- 변경 후 `flutter analyze` + `flutter test` 통과, UI는 360×640·390×844 확인
- commit/push는 사용자 요청 시에만

## Session Continuity Protocol
시작: 이 파일 읽기 → 구조·git status 확인 → 문서와 코드 비교 → 현재 단계·미완료·Known Issues 확인 → 작업 시작.
큰 작업 후: 이 파일 갱신(완료 기능, 미완료, 새 이슈, Next Goal, Change Log 한 줄).

---

## Change Log (요약 — 상세는 git 기록)
- 2026-10-07 — **Investigation Board Flow Fix**(Audit P1): Case Closed OPEN CASE NN → Board(보드의 현재 사건이 NN일 때). 기존 테스트 4개 파일의 목적지 단언 갱신. Tests 757 → 779
- 2026-10-07 — **Final Player Experience Audit**(판정 B, 코드 변경 없음), PROJECT_CONTEXT 전면 정리
- 2026-10-07 — **Post-Discovery Small Pass**: Case 07 M3 Discovery 카드 숨김, Story Evidence Card(06-M3 티켓, 10-M3 편지), 07-M3·10-M2 transition 중복 1줄씩. Tests 732 → 757
- 2026-10-07 — **Discovery Moment**: WELL DONE → Discovery(38 매핑, 현장 배경, timing 규칙), `PlaceScenery` 공용화. Tests 693 → 732
- 2026-10-07 — **Final Small Pass**: Case 06(관찰 + 카드 연결), Case 08(거짓말 + Case 03 Red Button, Post-Case 확인형). Tests → 693
- 2026-10-06~07 — **Detective Reasoning Pass** (Case 02 pilot, Wave 1~3): Final dependency 평균 1.58 → 2.33(+Small Pass 후 Case 06·08 3), 정답 노출·Story 대리 추리 제거
- 2026-10-02 — Season One Experience(Cover·Opening·Board), Title·Registration artwork, Story Intro 장면 배경, UI 감사(legacy 화면 정리, glass CTA), Android Back 수정, Victorian Casebook 리디자인
- 2026-10-01 — Landmark·내부 장소·캐릭터·오브젝트 artwork, Map Camera, GO TO 줌 전환, Operator Mode
- 2026-09-29 — Season 1 Case 02~12, Season QA, Case Archive, Phase 4 플레이테스트 준비
- 2026-09-28 — Phase 1 MVP, Phase 2 게임성, 플레이 시간·Parent Gate·리포트 접근 안정화
