# London Mystery — PROJECT_CONTEXT

> 이 파일은 Claude Code 세션이 바뀌어도 개발 흐름을 이어가기 위한 **영속적인 작업 기억 파일**이다.
> README.md(사용자/운영자용 안내)와 달리, 이 파일은 **다음 개발 세션이 현재 상태를 정확히 파악하기 위한 문서**다.
> 새 세션은 반드시 이 파일을 먼저 읽고, 아래 *Session Continuity Protocol*을 따른다.
>
> 최종 검증일: 2026-10-02 (`flutter analyze` 0 issues + `flutter test` **424개** 통과, 360×640·390×844 Season 화면 스크린샷 확인. 실기기 확인은 2026-09-29가 마지막)
> 마지막 작업: **Season Opening Sequence (Briefing → 5장면 Prologue + Case 01 파일)**, 그 전 Season One 재설계, **Season One Experience** (2026-10-02, Change Log 참고). 그 전: Mission 화면 Android Back 버그, UI/UX 감사 1차 수정, 전체 UI 리디자인 "Victorian Casebook"

---

## Project Overview

| 항목 | 내용 |
|---|---|
| 프로젝트 이름 | London Mystery (`london_mystery`, v0.1.0+1) |
| 위치 | `V:\vscode\basic\london_mystery` |
| 목적 | 8~12세 어린이용 **오프라인 탐정 미션 게임**. 실제 놀이 공간(체험관/행사장)에서 진행자가 운영할 수 있는 형태 |
| 핵심 컨셉 | 런던에서 사라진 왕관을 쫓는 탐정이 되어, 영어로 된 편지·단서를 읽고 퍼즐을 풀어 사건을 해결 |
| Target User | 8~12세 어린이 (플레이어) / 보호자 (결과 리포트) / 현장 운영자 (Game Master) |
| 현재 개발 단계 | Season 1(Case 01~12) 구현·QA 완료, **Phase 4 플레이 테스트 준비 완료** — 다음: 실제 아이 플레이 테스트 (다음 Phase 미확정) |

### 핵심 경험

```
STORY → EXPLORATION → PUZZLE → DISCOVERY → REWARD
```

### 제품 철학

- **이 앱은 일반적인 영어 학습 앱이 아니다.** 어린이용 **미스터리 어드벤처 게임**이다.
- 영어는 학습 목표 그 자체가 아니라 **게임을 진행하기 위한 핵심 도구**다 (편지를 읽어야 다음 장소를 알 수 있다).
- 번역은 먼저 보여주지 않는다. 어려운 단어만 점선 밑줄 → 탭하면 뜻 카드(한국어). 아이가 영어를 먼저 읽게 한다.
- 오답은 벌점이 없다 ("Not quite! Good detectives look again."). 힌트는 "Detective Tip"으로, 실패가 아닌 파트너의 도움으로 표현한다.
- 결과 화면은 성적표가 아닌 **탐정 사건 파일**(Case Closed) 형태. 보호자용 리포트도 "성적표가 아닌 게임 리포트" 톤.
- 완전 오프라인: 백엔드 없음, 폰트·사운드 번들, 그림은 CustomPainter로 앱 내 드로잉.

---

## Current Development Phase

**Phase 2 — Game Experience Enhancement: 구현 완료 (코드 기준 검증됨)**

- Phase 1 (Flutter MVP, 전체 플레이 흐름): 완료
- Phase 2 (게임성·UX 강화): 요청된 12개 항목 중 대부분 완료. "영어 난이도 처리"만 부분 구현 (아래 참고)
- Phase 2 안정화 (2026-09-28): 플레이 시간 계산, Parent Gate lifecycle 오류, 보호자 리포트 접근 보호 수정 완료
- 검증 결과 (2026-09-28, 안정화 작업 후):
  - `flutter analyze` → **No issues found**
  - `flutter test` → **41개 테스트 전부 통과** (타이틀 → 케이스 리포트까지 전체 플레이스루 위젯 테스트 포함)
- 다음 Phase: **미확정** (아래 *Next Development Goal* 참고)
- **2026-09-29 Season 1 콘텐츠 추가**: Case 02~12 구현, 멀티 케이스 저장/잠금 해제 구조. `flutter analyze` 0 issues, `flutter test` **116개 통과**, Android 에뮬레이터(API 34)에서 Case 01 구세이브 → Case 02 해금 → Case 02 전체 플레이 → 재시작 후 복구 → Case 03 해금 확인
- **2026-09-29 Season 1 QA**: P0 0 · P1 7 수정 · P2 9 수정, Notebook CASE ARCHIVE, OPEN MY NOTEBOOK 가독성. `flutter analyze` 0 issues, `flutter test` **236개 통과**
- **2026-09-29 Phase 4 (Playtest Preparation & Visual Polish)**: 남은 P2 3건 + 새로 찾은 P2 2건 수정, Game Master 플레이 테스트 도구, 8~12세 체크리스트, Visual Asset Inventory, 그림 교체 구조(`ArtAssets`). `flutter analyze` 0 issues, `flutter test` **253개 통과**

---

## Completed Features

실제 코드에 구현되어 있고, analyze/test로 검증된 항목만 기록한다.

### 플레이 흐름 / 화면
- [x] **Start (Title)** — `features/onboarding/start_screen.dart`. 저장 데이터 있으면 "CONTINUE ADVENTURE" + "Start a new case"(확인 다이얼로그). 엠블럼 **길게 누르기** → Parent Gate → Game Master
- [x] **Player Registration (Detective ID)** — `register_screen.dart`. 이름 1~12자, 영문/숫자/한글/공백/`.`/`-`만 허용, 대문자 변환. 클라이언트 입력 필터 + `GameController.validateName` 이중 검증
- [x] **Episode Selection (Case Files)** — `episode_select_screen.dart`. EP01 케이스 파일 카드 + "EPISODE 02 Coming soon..." 잠금 카드(하드코딩)
- [x] **Story Intro** — `story_intro_screen.dart`. 타자기 효과, 탭으로 줄 넘김, SKIP, "Are you ready?" → `startInvestigation()`(사건 타이머 시작)
- [x] **Mission Map** — `features/mission_map/`. Map Camera: 세로 뷰포트가 3:2 런던 지도 world(`ArtAssets.londonMap`, 없으면 CustomPainter 지도)의 일부를 보여주고 현재 장소로 자동 이동(`map_camera.dart`, `map_world.dart`). 수사 경로(실선/점선), 랜드마크 이름, 핀(completed/current만 표시, 잠긴 장소는 숨김), 헤더는 사건 제목 + 메뉴만. 게임 메뉴(탐정 이름·XP·플레이 시간 / 사운드 토글 / 노트북 / 결과 / 타이틀). Phase 3에서 리디자인됨
- [x] **Mission (3단계)** — `features/mission/mission_screen.dart`. story(장면+봉인 편지) → letter(편지 읽기) → puzzle. 상단 단계 점 표시, 재진입 시 퍼즐 단계로 바로 이동, 퍼즐 중 편지 다시 읽기
- [x] **Question 타입 5종 + Final** — `mission/widgets/question_widgets.dart`, `qr_question.dart`
  - Multiple Choice (m01), Word Input (m02), Number Code 키패드 (m03), Image Choice (m04, 이름 숨김), QR Scan (m05, 수동 입력 폴백)
- [x] **Answer Validation** — `core/utils/answer_checker.dart`. 선택형은 option id 일치, 텍스트형은 대소문자·공백·구두점 무시 + `acceptedAnswers`
- [x] **Success Overlay** — `answer_feedback.dart`. SUCCESS 스탬프, 컨페티, XP 내역 애니메이션, 획득 단서/증거, 신규 배지
- [x] **Try Again Sheet** — 오답 시 흔들림 + 격려 시트 + "GET A TIP" 버튼
- [x] **Story Transition** — `story_scene_screen.dart` (`/story/:id`). 미션 해결 후 짧은 타자기 장면 + "NEW PLACE UNLOCKED / FINAL CASE UNLOCKED" 카드
- [x] **Mission Unlock Animation** — `map_pin.dart`. `recentUnlockProvider`로 지정된 핀이 LOCKED → UNLOCKED 연출(스파클/글로우) + unlock 사운드
- [x] **Detective Notebook** — `features/notebook/notebook_screen.dart`. 탭 3개: CLUES / EVIDENCE(탭하면 확대) / BADGES. 미획득 슬롯은 잠금 표시
- [x] **Final Case** — `final_mission_screen.dart` (`/final`). 그림 자물쇠 4개 다이얼, 노트북 미리보기 시트, Royal Box 개봉 애니메이션(CustomPainter)
- [x] **Result (Case Closed, 아이용)** — `features/result/case_solved_screen.dart`. 탐정 사건 파일 디자인, SOLVED 도장, XP 카운트업, 대표 배지, 사건 요약 문장, Play again
- [x] **Parent Report (보호자용)** — `parent_report_screen.dart`. **Parent Gate를 통과해야만 열림** (아래 *Parent Report Access* 참고). 영어 능력 별점(Vocabulary/Reading/Problem Solving), 정답률·힌트·시간·한 번에 해결·찾아본 단어·배지, 미션별 기록, 한국어 코멘트
- [x] **Game Master (운영자)** — `features/game_master/`. Parent Gate(랜덤 곱셈 문제) 통과 시에만 접근. QR 카드 표시(`qr_flutter`), 정답표, 기기 초기화

### 게임 시스템
- [x] **Detective Identity** — 탐정 이름 등록·저장, 전 화면에서 "Detective {NAME}" 호칭 (레벨/칭호/아바타는 없음 → Not Implemented 참고)
- [x] **Detective XP** — `features/game/scoring.dart` `XpBreakdown`
- [x] **Badge System** — `GameBadge` enum 6종, 해결 시 자동 수여
- [x] **Hint System** — 미션당 최대 2단계
- [x] **Evidence Collection** — 미션마다 증거 1개, 노트북 확대 보기, Crown Symbol 증거가 최종 암호 순서를 제공
- [x] **Mission Unlock** — 순차 해금
- [x] **Local Persistence** — `shared_preferences`, 모든 변경 즉시 저장, 앱 재시작 시 이어하기
- [x] **Play Time (활성 플레이 시간)** — 앱이 foreground에 있는 동안만 카운트. 백그라운드·종료 시간 제외, 재실행 시 복구 (아래 *Play Time* 참고)
- [x] **Sound 구조** — `AudioService` 인터페이스 + `AssetAudioService`(audioplayers) + `MockAudioService`, 사운드 on/off 저장, 주요 효과음 시 햅틱
- [x] **어린이용 UX** — 큰 버튼/터치 영역(최소 48~68px), 한 화면 한 액션, 세로 고정, 텍스트 스케일 최대 1.3배 제한, Semantics 라벨, 오답 무벌점
- [x] **Routing Guard (접근 제어)** — URL/딥링크로 잠긴 미션·최종·결과·Game Master 진입 불가 (테스트로 검증)
- [x] **Glossary Word Cards** — 에피소드 glossary의 단어만 점선 밑줄, 탭 시 한국어 뜻 카드, 조회 단어 기록 → 보호자 리포트 반영

---

## Partial Features

- [~] **영어 난이도 처리** — 구현된 것: glossary 탭-투-뜻 카드, 짧고 쉬운 문장으로 작성된 콘텐츠, 관대한 정답 판정, 2단계 힌트. **없는 것**: 난이도 레벨 선택(예: Easy/Normal), 연령/레벨별 문장 분기, 음성(TTS) 읽어주기
- [~] **Sound** — 구조는 완료. 실제 음원은 `tool/gen_sounds.js`로 **합성한 단순 효과음 6개**(placeholder 수준). BGM/내레이션 없음
- [~] **Episode Selection** — 화면은 있으나 에피소드는 EP01 하나뿐. EP02 카드는 하드코딩된 "Coming soon". `MockEpisodeRepository`는 다중 에피소드 구조를 지원하지만 선택 UI는 `currentEpisodeProvider`(단일, 앱 시작 시 `AppConstants.currentEpisodeId`로 고정)에 묶여 있음
- [~] **Detective Identity** — 이름만 있음. XP 누적에 따른 탐정 등급/칭호, 아바타, 탐정 카드 없음
- [~] **릴리즈 준비** — 런처 아이콘·스플래시가 Flutter 기본값 (README "Before release"에 명시)

---

## Not Implemented

- [ ] 탐정 레벨/랭크 (XP → 등급) 시스템
- [ ] 난이도 선택 / 연령별 콘텐츠 분기
- [ ] TTS 또는 녹음된 음성 내레이션, BGM
- [ ] Episode 02 이후 콘텐츠
- [ ] 이미지 asset 기반 일러스트 — **교체 구조는 준비됨**(`ArtAssets`, 2026-09-29), 실제 그림 파일은 아직 없음 (`docs/art/VISUAL_ASSET_INVENTORY.md`)
- [ ] 백엔드 / 계정 / 클라우드 동기화 (의도적으로 없음 — 명시 요청 전에는 도입 금지)
- [ ] 다국어(l10n) 프레임워크 — UI 영어 + 보호자/운영자 문구 한국어가 코드에 직접 작성됨
- [ ] 다중 플레이어(한 기기 여러 프로필) — 기기당 한 명, Game Master에서 초기화
- [ ] macOS / Linux 플랫폼 폴더 (현재 android, ios, web, windows만 존재)

---

## Architecture

```text
lib/
├── main.dart                  # SharedPreferences·에피소드 선로딩 → ProviderScope overrides
├── app.dart                   # MaterialApp.router, 텍스트 스케일 clamp(1.3)
├── core/
│   ├── constants/app_constants.dart   # 저장 키, 이름 규칙, 힌트 수, XP 규칙
│   ├── router/app_router.dart         # go_router + redirect 가드, Routes 상수
│   ├── theme/                         # app_colors, app_text(Cinzel/Fredoka/Nunito), app_theme(M3)
│   └── utils/                         # answer_checker, formatters, audio_service
├── data/
│   ├── models/                        # episode.dart, mission.dart(Mission/Clue/Evidence/ChoiceOption/enum), game_progress.dart
│   ├── mock/season1/episode01_mock.dart # EP01 콘텐츠 (백엔드 JSON과 같은 형태의 const Map)
│   └── repositories/                  # EpisodeRepository(+Mock), ProgressRepository(+SharedPrefs, InMemory)
├── features/
│   ├── onboarding/    # start, register, episode_select, story_intro
│   ├── mission_map/   # mission_map_screen + widgets(london_map_painter, map_pin)
│   ├── mission/       # mission_screen, story_scene_screen, final_mission_screen, qr_scanner_screen
│   │   └── widgets/   # question_widgets, qr_question, answer_feedback(성공 오버레이/오답 시트/TipsPanel)
│   ├── notebook/      # notebook_screen
│   ├── result/        # case_solved_screen, parent_report_screen, detective_report(순수 계산 로직)
│   ├── game/          # game_controller(Notifier), game_providers, scoring(XP/Badge)
│   └── game_master/   # game_master_screen, parent_gate
└── widgets/           # 공용 UI: game_button, letter_card(LetterCard/EnvelopeReveal/WaxSeal), landmark_art,
                       # clue_card, evidence_card, badge_medal(+XpCounter), glossary_text, symbol_icon,
                       # typewriter_text, paper_background, game_toast
test/                  # answer_checker, detective_report, episode_content, game_controller,
                       # full_playthrough, resume_and_guard, parent_gate (+ helpers.dart)
tool/gen_sounds.js     # 효과음 WAV 생성 스크립트 (node)
```

### State Management
- **flutter_riverpod 3.x** (`Notifier` / `NotifierProvider`, 코드 생성 없음)
- `gameControllerProvider` (`GameController extends Notifier<GameProgress>`) — 플레이 상태의 단일 소유자. **모든 변경을 `_update()`로 즉시 저장**
- `currentEpisodeProvider`, `sharedPreferencesProvider` — `main()`에서 override (미override 시 throw)
- `soundEnabledProvider` (저장됨), `audioServiceProvider`
- `recentUnlockProvider` — 핀 해금 연출 대상 (일시 상태, 저장 안 함)
- `gameMasterAccessProvider` — Parent Gate 통과 여부 (세션 한정, 저장 안 함)
- `parentReportAccessProvider` — 보호자 리포트 **1회용** 통과권 (Parent Gate 통과 시 grant, 리포트를 떠나면 revoke, 저장 안 함)
- `GameController.now` — 테스트용 시계 주입 지점
- `GameController.playTime` — 실시간 플레이 시간 (저장값 + 현재 foreground 구간), `pausePlayClock()` / `resumePlayClock()`
- `LondonMysteryApp`(`app.dart`)이 `AppLifecycleListener`로 lifecycle을 받아 플레이 시계를 멈추거나 다시 움직인다

### Routing (go_router 18)
| Path | 화면 | 가드 조건 |
|---|---|---|
| `/` | StartScreen | 항상 |
| `/register` | RegisterScreen | 항상 |
| `/season` | SeasonScreen (시즌 시작 전 = Casebook, 이후 = Investigation Board. Back → `/`) | 탐정 등록 필요 |
| `/season/prologue` | SeasonPrologueScreen (Casebook → 5장면 오프닝 → Case 01 파일 → Case 01 인트로. Back = 이전 장면, 첫 장면에서 `/season`) | 탐정 등록 필요 |
| `/episodes` (`?case=epNN`) | EpisodeSelectScreen (`case`: 그 사건 폴더를 열고 선택한 채 스크롤. 봉인/모르는 id는 무시. Back → `/season`) | 탐정 등록 필요 |
| `/intro` | StoryIntroScreen | 탐정 등록 필요 |
| `/map`, `/notebook`, `/scan` | 지도 / 노트북 / QR 스캐너 | + introSeen |
| `/mission/:id` | MissionScreen | + 해금된 일반 미션만 (final 불가) |
| `/story/:id` | StorySceneScreen | 해당 미션 해결 후 |
| `/final` | FinalMissionScreen | 일반 미션 5개 모두 해결 |
| `/solved` | CaseSolvedScreen | 사건 해결 후 |
| `/report` | ParentReportScreen | 사건 해결 후 + `parentReportAccessProvider` (없으면 → `/solved`) |
| `/game-master` | GameMasterScreen | Parent Gate 통과 |

- 페이지 전환: 공통 fade + 약간의 slide (`_fade`), `errorBuilder` → StartScreen

### Repository / Persistence
- `EpisodeRepository` (interface) → `MockEpisodeRepository` (`{'ep01': episode01Json}` → `Episode.fromJson`)
- `ProgressRepository` (interface) → `SharedPrefsProgressRepository` (키 `lm.progress.v1`, 순수 `jsonDecode`만 사용 — 다형성 역직렬화 금지), `InMemoryProgressRepository` (테스트)
- `GameProgress.fromJson`은 관대한 디코딩(잘못된 필드는 기본값) + 구버전 `hintMissionIds` → `hintsUsed` 마이그레이션
- 손상된 저장 데이터 → 새 게임으로 폴백 (테스트 있음)
- 백엔드 전환 시: 두 인터페이스 구현 후 `main.dart`의 provider override만 교체

### Services
- `AudioService` (interface) → `AssetAudioService`(사운드별 AudioPlayer 1개, 예외 삼킴, success/finale/unlock 시 햅틱) / `MockAudioService`

---

## Episode

### Episode 01 — The Missing Crown (`ep01`) — Season 1의 첫 사건 (데이터·정답·로직 변경 없음)

**Story**: 런던 Royal Archive에서 왕관이 사라졌다(밤 10:42). 도둑 "The Shadow"가 도시 곳곳에 단서를 남겼고, 플레이어는 탐정으로 선택되어 단서를 추적한다.

**Mission 구성 (실제 코드 기준)** — 기획 초안과 달리 **Big Ben이 3번 미션**으로 들어가 있고, 일반 미션 5개 + Final 1개 구조다.

| # | id | Location | Title | Type | Answer | Clue (value / symbol) | Evidence |
|---|---|---|---|---|---|---|---|
| 01 | m01 | KING'S CROSS | The Mysterious Suitcase | multipleChoice | `b` (The British Museum) | Platform 9 (`9` / train) | Old Letter |
| 02 | m02 | BRITISH MUSEUM | The Famous Stone | wordInput | `STONE` (+`ROSETTA STONE`) | Room 4 (`4` / museum) | Golden Key |
| 03 | m03 | BIG BEN | The Locked Box | numberCode (3자리) | `417` | 7 o'clock (`7` / clock) | Pocket Watch |
| 04 | m04 | HYDE PARK | The Secret Drawing | imageChoice | `c` (Buckingham Palace) | 2 Swans (`2` / park) | London Map |
| 05 | m05 | BUCKINGHAM PALACE | The Royal Guard | qrScan | `LM-EP01-PALACE` | The Royal Box (`4 locks` / crown) | Crown Symbol (symbols: clock, train, park, museum) |
| Final | final | THE ROYAL ARCHIVE | The Royal Box | finalCode (4자리) | `7924` | — | The Missing Crown |

**Final Case 설계**: Royal Box의 자물쇠 4개에 그림(clock, train, park, museum)이 있다. 그림 순서는 Crown Symbol 증거에서만 확인 가능. 각 그림 = 방문 장소 = 그 장소의 숫자 단서 → clock=Big Ben 7, train=King's Cross 9, park=Hyde Park 2, museum=British Museum 4 → **7924**. 단서를 발견 순서대로 읽으면(9472) 틀리도록 설계됨 (테스트로 검증).

- Glossary: 43개 단어 (영어 소문자 → 한국어 뜻), `'s` 소유격 처리
- 미션별 skills: vocabulary / reading / problemSolving (보호자 리포트 별점 계산용)
- 지도 핀 위치: `mapX`, `mapY` (0..1 비율)

---

## Season 1 (2026-09-29 추가)

12개 사건 모두 **구현 완료** (데이터 + 전체 진행 테스트). 각 사건 = 일반 미션 3개 + Final 1개 (Opening → 장소 3곳(단서·퍼즐·증거) → Final Case → Case Solved → Season Hook). Episode 01만 5+1 구조.

### 시즌 스토리 줄기
모든 사건의 증거에 작은 까마귀 표식 → 비밀 조직 **Raven Society**(Case 04에서 이름 판명) → 명령을 내리는 **the Clockmaker**(Case 12). Case 01의 도둑 **The Shadow**는 Case 11에서 가면 쓴 인물로 재등장해 조력자가 됨. Case 06의 정체불명 인물은 적이 아니라 **Inspector Grey**(Case 03 방문객 명단에 "Mr Grey"로 복선). Case 03의 도둑 **Miss Rose** = Case 06 붉은 모자 여인 = Case 08 **Mrs Robin**(빨간 단추가 빠진 코트로 입증). 시즌 마지막: Clockmaker는 사라지고 **PARIS**가 새겨진 시계만 남음 → Season 2 훅.

### Case 목록
| # | id | 제목 | 장소 | 핵심 퍼즐 방식 | 미션 타입 (m1 / m2 / m3 / final) | Final 정답 | Case Badge |
|---|---|---|---|---|---|---|---|
| 01 | ep01 | The Missing Crown | 런던 전역 | 그림 자물쇠 | (기존 5+1) | 7924 | — |
| 02 | ep02 | The Silent Clock | Westminster / Big Ben | 시계 읽기·시간 | numberCode `817` / MC / **sequence** / finalCode `917` | 9:17 | Clock Watcher |
| 03 | ep03 | The Vanishing Painting | British Museum | 사물 묘사·색·위치 | MC / MC / sequence(젖은→마른 발자국) / imageChoice | King's Cross | Evidence Hunter |
| 04 | ep04 | The Secret Letter | King's Cross | 편지 읽기 | MC(영업시간) / MC(RED·FOUR·CLOCK·PLATFORM) / imageChoice(소인) / wordInput | RAVEN | Letter Reader |
| 05 | ep05 | The Locked Room | Tower of London | 명령문·방향 | MC / sequence(L·R·L·R) / wordInput `SEVEN` / finalCode | 745 | Code Breaker |
| 06 | ep06 | The Midnight Detective | Covent Garden | 목격자 비교 | MC / wordInput `GREY` / numberCode(차이 4개) / MC | Inspector Grey | — |
| 07 | ep07 | The Lost Map | Hyde Park | 지도·전치사 | imageChoice(공원 지도) / MC(behind) / sequence(위→아래) / imageChoice | 옛 문(old gate) 지도 | Map Master |
| 08 | ep08 | The Mystery on Platform 9 | King's Cross | 질문·대답 | MC(질문 고르기) / wordInput `ROBIN` / numberCode `429` / MC(증거로 반박) | 단추 증거 | — |
| 09 | ep09 | The Missing Jewel | Buckingham Palace | 소유·논리 | MC(누구의 열쇠) / wordInput `ANNA` / numberCode `12` / wordInput | HAT | — |
| 10 | ep10 | The London Raven | Tower of London | 단어 순서·숨은 메시지 | MC / sequence(요일) / imageChoice / sequence(문장) | THE CLOCKMAKER WILL STOP BIG BEN AT MIDNIGHT | — |
| 11 | ep11 | The Masked Stranger | Covent Garden 극장 | 묘사 비교·정체 | MC / wordInput(거꾸로 `MIDNIGHT`) / imageChoice / MC | The Shadow | — |
| 12 | ep12 | The Midnight Case | 런던 전역 | 시즌 단서 종합 | MC / numberCode `1140` / wordInput `BIG BEN` / finalCode | 487 | London Legend |

- 정답 전체는 Game Master 화면의 "정답표"(현재 열린 사건 기준)와 각 `episodeNN_mock.dart` 파일 상단 설계 주석 참고
- Case 12는 이전 사건 지식을 요구(Case 02 까마귀 톱니, Case 04 빨간 시계 = 4번 승강장, Case 05 까마귀 7마리·Brass Key, Case 10 경고문). 기억이 안 나면 힌트가 해당 Case 번호를 짚어준다
- QR 미션은 새 사건에 넣지 않음(현장 카드 준비가 필요해서) — 테스트로 강제

### 구조 (Episode 추가 방법)
1. `lib/data/mock/season1/episodeNN_mock.dart`에 Episode 01과 **같은 JSON 모양**으로 작성 (위젯 코드 없음 → JSON/원격 전환 가능)
2. `season1_mock.dart`의 `season1Json`에 등록 → `MockEpisodeRepository`가 번호순 카탈로그로 제공
3. (선택) 사건 배지: `GameBadge`에 `episodeId: 'epNN'`으로 추가
4. `test/season_content_test.dart`가 자동 검증: 순서/ID 중복, 정답 풀이 가능, 힌트 1~2개, 증거·단서·transition, MC 선택지 ≥3, imageChoice 장면 그림이 정답을 노출하지 않음, **힌트가 정답을 직접 말하지 않음**, **인트로·장면 문장이 입력 정답을 미리 말하지 않음**, 사건당 퍼즐 타입 ≥3종, 모르는 심볼 없음, JSON 왕복

### 새/변경된 모델 필드 (모두 선택값, Episode 01 JSON은 그대로)
- `Episode.caseSummary` / `keyWords` / `hook` — 리포트 문장, 보호자 코멘트 핵심 단어, Case Solved 화면 시즌 훅. 없으면 Episode 01의 기존 문구
- `MissionType.sequence` — 선택지를 순서대로 탭 (정답 = id를 `,`로 연결). 선택지 수 < `codeLength`면 재사용 가능(LEFT/RIGHT), 아니면 1회씩
- `Mission.finale` — `Episode.fromJson`이 `finalMission`에 설정. Final Case가 어떤 퍼즐 타입이든 될 수 있음 (`isFinal = finale || type == finalCode`)
- `Mission.answerLabel` — Game Master 정답표용
- 새 `Artwork`: clockFace, gallery, towerOfLondon, lockedDoor, coventGarden, theatre, raven, jewelCase, parkMapA~D (LandmarkArt 잉크 스타일로 직접 그림)
- 새 `InkGlyph`(18개): clock, gear, key, footprint, button, cloth, map, ticket, feather, mask, gem, bag, raven, umbrella, seal, frame, whistle, train

---

## Season 1 QA (2026-09-29)

**범위**: Case 01~12 전 텍스트(인트로·스토리·편지·질문·선택지·정답·힌트·증거·전환·훅) 수검 / 잠금·저장·보상 코드 경로 / 화면 전체(에뮬레이터 실기 + 360×640 자동 렌더 101화면) / 회귀 테스트.

**Case별 결과**: 12개 사건 모두 통과. Case 01은 데이터·정답·로직 변경 없음 (구버전 실세이브로 에뮬레이터에서 끝까지 플레이: XP 510→1120, 기존 배지 6개, Royal Box 엔딩 동일).

**발견·수정 (P0 0 / P1 7 / P2 9)**
| P | 위치 | 문제 | 수정 |
|---|---|---|---|
| P1 | Final 화면 (전 사건) | OPEN MY NOTEBOOK 밤 배경 대비 부족 | 공통 `GameButton.outline` 표면 인식 |
| P1 | Case 08 Final | 편지 마지막 줄이 정답 선택지를 그대로 말함 | 줄 삭제, 힌트 → Archive |
| P1 | 공통 단어 입력 | 빈칸이 데이터와 무관하게 항상 5칸 (Case 09 "four letters"인데 5칸) | 프롬프트의 빈칸 유지 (Case 01은 5칸이라 동일), Case 09·12 빈칸 수 정정, 규칙 테스트 |
| P1 | Case Solved (Case 12) | 마지막 사건 후 Case Files로 갈 길 없음 | "CASE FILES" 버튼 |
| P1 | Notebook EVIDENCE (Case 01 포함, 기존) | 360dp 폰에서 증거 타일 overflow | `EvidenceTile`이 공간 부족 시에만 그림 축소 |
| P1 | Case Archive | 증거 타일 overflow (좁은 폴더 안) | 고정 높이 그리드 |
| P1 | Case 12 | 이전 사건 증거를 볼 수 없음 | CASE ARCHIVE |
| P2 | Case 03 M2 | 파란 천 위치 모순 (액자 위 ↔ Egypt Room) | "같은 천의 다른 조각" |
| P2 | Case 07 M1 | 증거 "Park Map Piece" ↔ M3 "river piece" | "River Map Piece" |
| P2 | Case 12 M2 | 힌트 "without the dots" | "as four numbers" |
| P2 | Case Files | Play again 하면 SOLVED 도장 사라짐 | 시즌 해결 기록 기준 |
| P2 | Archive / Case Files | 긴 제목이 도장에 붙음 | 간격 |
| P2 | Case 07 지도 그림 | 그림 글자(A~D)가 옛 문 그림을 가림 | 문·길 위치 이동 |
| P2 | Final 자물쇠 | 톱니 심볼 테두리 = 황동 다이얼 색 | 잉크 갈색 |
| P2 | Case 08·11·12 | 과거 사건 기억 의존 | 힌트가 Archive의 해당 Case를 가리킴 |
| P2 | Case Solved | "OPEN CASE NN"이 임시 잉크 링크 | 공통 outline 버튼으로 통일 |

**유지 판단 (설계 의도)**: Case 11 M3가 Case 03 Final과 같은 King's Cross 그림 선택(“I love trains” 복선) / Case 12 M3 정답(Big Ben)이 맥락상 추측 가능(수수께끼 읽기가 핵심) / 일부 힌트 2단계가 꽤 직접적(8~12세 진행 보장, 정답 문자열 자체는 없음 — 테스트로 강제).

**UI — OPEN MY NOTEBOOK**: `PaperBackground(night: true)`가 `InkSurface(night)`를 내려주고 `PaperSheet`는 종이로 재설정. `GameButton.outline`만 이를 읽음: 종이 = 기존 ink / 밤 = `goldLight` 글자·아이콘 + gold 테두리 (navy 대비 4.5:1 이상 테스트). 크기·아이콘 위치·pressed/disabled 동작 불변 (테스트). Case 01~12 동일 스타일, 사건별 분기 없음. 바텀시트(별도 route)는 종이로 처리.

**Tests**: 기존 116 → **236** (+120). `season_screens_test`(12 Case × 모든 미션 story/puzzle + Final + Notebook + Archive, 360×640 실제 폰트, 레이아웃 오류 시 실패, `LM_SCREENSHOTS=폴더`로 PNG 저장), `season_archive_test`(Archive 상태·Case 12 열람·Play again 무중복·Case 01 세이브 호환·잠금·Notebook 이동/복귀·Final 시트 → Archive·Case Solved → Notebook → Back·마지막 사건 CASE FILES), `game_button_surface_test`, 프롬프트 빈칸 규칙.

**Emulator QA (API 34)**: FLOW A Case 01 구세이브 끝까지 / FLOW C Archive / FLOW D Case 12(미션 → Archive → 복귀 → 앱 재시작 복구 → Final → 시트 → Archive → 해결 → CASE FILES) / FLOW E 잠긴 사건 / Case 07 지도 퍼즐. Case 03~11은 전 화면 자동 렌더 + 일부 실기. 끝난 뒤 에뮬레이터 세이브를 원본으로 복원(바이트 동일 확인).

---

## Phase 4 — Playtest Preparation & Visual Polish (2026-09-29)

**원칙**: 게임 로직·정답·범인·결말·저장 키·Case 01 데이터 변경 없음. 새 dependency·상태 관리 없음.

**P2 수정 (Season 1 QA에서 남긴 3건)**
| 위치 | 문제 | 수정 |
|---|---|---|
| Case 02 Final | 해결 후에도 시계 8:17 | `LandmarkArt(solved: 0~1)`: 해결 애니메이션 진행도로 바늘이 9:17까지 돌아감. Case Solved 사진은 `solved: 1`. 다른 장면은 무시(픽셀 동일 테스트) |
| 시퀀스 퍼즐 | Undo/Start again 비활성 구분 없음 | 공통 `InkTextButton`: `onPressed == null`이면 글자·아이콘 `AppColors.locked` |
| Case Solved → Case Files | OPEN CASE NN 후 다음 사건 미선택 | `Routes.caseFile(id)` = `/episodes?case=id`. 폴더 열림 + 선택 + `Scrollable.ensureVisible`. 봉인·모르는 id는 무시. 마지막 사건의 CASE FILES는 기존 `/episodes` |

**작업 중 새로 찾아 수정한 P2**
- Case Files가 `ListView`(지연 생성)라 화면 밖 사건(예: Case 07)으로 스크롤되지 않음 → 에뮬레이터에서 발견. 12개 폴더를 한 번에 만드는 `SingleChildScrollView + Column`으로 변경, 360×640 테스트 추가
- 밤 배경 초승달이 인트로 `SKIP ›`(오른쪽 위 액션) 뒤에 겹쳐 읽기 어려움 → 공통 `PaperBackground`에서 달을 앱바 줄 아래(최소 130dp)로 이동. 모든 밤 화면에 같이 적용

**실제 플레이 준비 (게임 로직 변경 없음)**
- `lib/features/game_master/playtest_tools.dart`: `playtestToolsEnabled = kDebugMode || bool.fromEnvironment('LM_PLAYTEST')`. 일반 release 빌드에서는 보이지 않음
- Game Master(기존 Parent Gate 뒤) → **플레이 테스트 도구**
  - `CASE NN부터`: 확인 창 → `resetAll()` → 앞 사건을 완료 세이브 + 시즌 해결로 기록(힌트·배지 없음, Archive에 증거 표시) → 해당 사건 새 세이브(이름 유지, 없으면 `TESTER`) → `/episodes?case=` 로 이동
  - `지금 사건 처음부터`: 기존 `playAgain()`과 같음(이 사건만 초기화)
  - `전체 사건 열기 (OPERATOR MODE)` 스위치 (2026-10-01): Case 01~12를 순서와 상관없이 열 수 있음. **접근만** 허용하고 아무것도 해결로 기록하지 않음(XP·배지·증거·시즌 해결 기록 그대로) — 이전 사건을 해결로 저장하는 `CASE NN부터`와 다른 점. 세션 전용(저장 안 함, 재시작하면 꺼짐). 켜져 있으면 Case Files 상단에 작은 `OPERATOR MODE` 도장 + `CASE FILES로 이동` 버튼
- QR이 필요한 사건은 Case 01뿐. Case 02~12는 기기만으로 플레이 가능
- 체크리스트: `docs/playtest/SEASON1_PLAYTEST_CHECKLIST.md` (준비 방법, 공통 10항목, 사건별 관찰 포인트·기록표)

**Visual Asset Inventory / 교체 구조**
- 목록·사양·우선순위: `docs/art/VISUAL_ASSET_INVENTORY.md`
- `lib/widgets/art_assets.dart` `ArtAssets` (`scenes`, `solvedScenes`, `symbols`, `badges` — 현재 모두 비어 있음 = 화면 변화 없음)
- `LandmarkArt`: 파일 → 코드 그림. `InkMark`: 파일(한 색, `srcIn` 틴트) → 글리프 → 모노그램. `GameSymbol.of`, `BadgeMedal`이 `InkMark`로 전달. 파일 오류 시 `errorBuilder`로 코드 그림
- 새 `Artwork` 키 6개(`boathouse`, `roseGarden`, `waitingRoom`, `staffRoom`, `courtyard`, `dressingRoom`)를 데이터에서 사용. 그림 전에는 `LandmarkArt.standIns`의 기존 장면을 그대로 그림(픽셀 동일 테스트)
- PNG/WebP/JPEG만 (SVG는 새 dependency 필요 → 사용 안 함)

**Tests**: 236 → **253** (+17). `phase4_polish_test`(시계 solved 상태·픽셀 차이, Case Solved 사진, Undo 비활성 색, OPEN CASE 02 선택·열림·BEGIN, 360×640에서 OPEN CASE 07 스크롤, 봉인/모르는 id 무시), `playtest_tools_test`(도구 노출, CASE 07부터 → 시즌·Archive·배지/힌트 없음·인트로부터, 지금 사건 처음부터 → 다른 사건 세이브 불변, 이름 없는 기기), `art_assets_test`(stand-in 픽셀 동일, 모든 장면 렌더, 여섯 장소 키 사용, 등록 파일 존재·pubspec·확장자·키 유효, 파일 없을 때 글리프/모노그램 폴백). 기존 테스트 1곳(`season_playthrough_test`)만 새 동작에 맞춰 수정: OPEN CASE 03 뒤 폴더가 이미 열려 있으므로 폴더를 다시 탭하지 않음(검증 항목은 유지 + BEGIN INVESTIGATION 추가)

**Emulator (API 34, debug APK)**: Game Master → 플레이 테스트 도구 표시 → `CASE 07부터` → Case Files에서 Case 07 열림·선택·화면 안(수정 후) → BEGIN → 인트로(달이 SKIP과 겹치지 않음). 시작 전 세이브 백업 → 끝난 뒤 복원(바이트 동일 확인, "Welcome back, Detective KIM!")

---

## Game Systems

### XP (`scoring.dart`, 규칙은 `AppConstants`)
- XP는 **저장하지 않고** `GameProgress`에서 매번 계산 (`XpBreakdown.of`, `totalFor`)
- 미션 해결 base **+100** (Final **+200**)
- 노힌트 보너스: 힌트 0개 **+50**, 1개 **+25**, 2개 0
- 스피드 보너스: 미션 첫 오픈부터 해결까지 **활성 플레이 시간** ≤120초(Final ≤180초) **+20** (백그라운드·종료 시간 제외)
- 오답 감점 없음
- 최대: 일반 5 × 170 + Final 270 = **1,120 XP**

### Hint (Detective Tips)
- 미션당 최대 **2단계** (`AppConstants.maxHints`), 약한 힌트 → 직접적 힌트 순
- 퍼즐 화면 TipsPanel "NEED A TIP?" 또는 오답 시트 "GET A TIP"으로 공개
- 미션별 공개 개수 `hintsUsed`에 저장, 해결 후엔 증가 불가, 보호자 리포트에 표시

### Badge (`GameBadge`)
| id | Title | 조건 |
|---|---|---|
| firstClue | First Clue | 단서 1개 이상 |
| sharpEyes | Sharp Eyes | 힌트 없이 해결한 미션 1개 이상 |
| quickThinker | Quick Thinker | 스피드 보너스 받은 미션 1개 이상 |
| puzzleSolver | Puzzle Solver | 3개 이상 해결 (Final 포함 카운트) |
| londonExplorer | London Explorer | 일반 미션 5개 모두 해결 |
| masterDetective | Master Detective | 사건 해결 (Final 해결) |
| clockWatcher / evidenceHunter / letterReader / codeBreaker / mapMaster / londonLegend | (Case Badge) | 각각 Case 02 / 03 / 04 / 05 / 07 / 12 해결 |
- 정답 제출 시 조건 검사 → 신규 배지는 `badgeIds`에 획득 순서대로 추가, 성공 오버레이에 "NEW BADGE!" 표시
- 배지는 **사건별**(각 사건의 `GameProgress.badgeIds`). `GameBadge.forEpisode(e)` = 공통 6개 + 그 사건의 Case Badge. Episode 01 배지 선반은 기존 6개 그대로 (테스트로 고정)
- 리포트 대표 배지: 그 사건의 Case Badge → 없으면 Master Detective → 없으면 마지막 획득

### Evidence
- 각 미션 데이터의 `evidence` (id, name, icon, description, inscription?, symbols[])
- 별도 저장 없이 `completedMissionIds` 순서에서 파생 (`collectedEvidence`)
- 노트북 EVIDENCE 탭 / 최종 미션 노트북 시트에서 탭 → 확대(`showEvidenceZoom`), inscription·symbols 표시

### Detective Notebook (2026-09-29: 두 "쪽" 구조)
수첩 상단의 **THIS CASE / CASE ARCHIVE** (Cinzel 글자 + 잉크 밑줄, Material 탭 아님). 같은 route 안의 상태 전환이라 닫으면 진행 중 화면이 그대로 (미션 단계·열린 팁·Final 스크롤 유지 — 테스트·실기 확인).
- **THIS CASE** (기존 그대로): 커버(탐정 이름 + 현재 사건 XP) + CLUES / EVIDENCE / BADGES(공통 6개 + 그 사건 Case Badge)
- **CASE ARCHIVE** (`features/notebook/season_archive.dart`): 12개 사건을 기존 `CaseFolder`로 나열, 펼치면 EVIDENCE(기존 `EvidenceTile`, 탭 → 기존 확대 화면) + CLUES(기존 `ClueCard`)
  - 상태: `SOLVED`(시즌 해결 기록) → 그 사건의 **전체** Evidence·Clues (해결했으니 모두 찾은 것 — Play again 중에도 유지) / `THIS CASE` → 지금까지 찾은 것 / `OPEN` → 다른 진행 중 사건, 그 사건 세이브에서 읽음 / "Not opened yet." / `SEALED` → 내용 없음
  - **새 저장 키 없음**: `lm.season.v1` + `lm.progress.v1[.epNN]` + 에피소드 데이터에서 계산 (`seasonArchiveProvider`)
- 진입: 모든 화면의 Notebook → CASE ARCHIVE, 라우트 `/notebook?view=archive`(`Routes.archive`), Final 화면 "OPEN MY NOTEBOOK" 시트 하단 "OPEN THE CASE ARCHIVE"(이전에 해결한 사건이 있을 때만 → Case 01 첫 플레이 시트는 기존 그대로)
- Case 12 사용: M2 힌트 "Open Case 04 in your Case Archive…"(빨간 시계 = Platform 4), Case 08·11 Final 힌트도 Archive의 Case 03 Red Button / Case 01 Old Letter를 가리킴

### Mission Unlock
- `GameProgress.isUnlocked`: 이미 해결했거나 = `currentMission`(아직 안 푼 첫 번째 일반 미션, 모두 풀면 Final)
- 해결 시 `nextMissionId`를 `recentUnlockProvider`에 설정 → 지도 복귀 시 해당 핀 해금 연출 후 null로 초기화
- 잠긴 핀 탭 → 토스트 ("Locked! First solve MISSION 0X at ...")
- 라우터 가드가 동일 규칙을 강제

### Play Time (2026-09-28 수정)
- 사건 시계는 스토리 인트로 종료(`startInvestigation`)부터 Final 해결까지 돈다. 탐정 등록·인트로 시간은 포함하지 않는다
- `GameProgress.playMillis` = 저장된 누적 활성 플레이 시간(ms). `GameController._activeSince` = 현재 foreground 구간의 시작 시각(메모리 전용)
- `GameController._update()`가 저장할 때마다 현재 구간을 `playMillis`에 더하고 구간을 새로 시작한다. 그래서 foreground에서 강제 종료돼도 잃는 시간은 마지막 행동 이후분뿐이다
- lifecycle(`app.dart`): `hidden` / `paused` / `detached` → `pausePlayClock()`(구간 저장 후 정지), `resumed` → `resumePlayClock()`. `inactive`는 화면이 보이는 상태(시스템 다이얼로그 등)라 계속 카운트
- 앱 시작 시(`build`) foreground로 간주하고 새 구간을 시작한다. 종료 전 시간은 저장된 `playMillis`에서 복구
- 미션 스피드 판정: `missionStartPlayMillis[id]`(미션을 처음 연 시점의 플레이 시간) → 해결 시 `solveSeconds = (playTime − 시작값) / 1000`
- 표시: 지도 타이머는 `GameController.playTime`(실시간), Case Closed와 보호자 리포트는 `GameProgress.elapsed()`(해결 시점에 확정된 `playMillis`)를 쓴다
- 이전 저장 데이터 호환(`fromJson`): `playMillis`가 없으면 → 해결된 사건은 null(기존 벽시계 결과 유지), 진행 중 사건은 0부터 다시 카운트. `missionStartPlayMillis`가 없는 미션은 기존 벽시계 방식으로 fallback

### Parent Report Access (2026-09-28 추가)
- Case Closed의 "VIEW MY DETECTIVE REPORT" → `ParentGate.show` → 통과 시 `parentReportAccessProvider.grant()` → `push(/report)` → 돌아오면 `revoke()`
- 라우터 가드: `/report`는 통과권이 있을 때만 열린다. `/report`가 아닌 location으로 이동하면 redirect에서 통과권을 회수한다(웹 브라우저 이동이나 URL 입력 대비. go_router는 `go()`로 교체된 push의 Future를 완료하지 않기 때문)
- 결과적으로 매번 보호자 확인이 필요하고, URL·딥링크·재시작·뒤로가기 후 재접근으로는 우회할 수 없다 (테스트로 검증)

### Persistence (`lm.progress.v1`, `lm.progress.v1.epNN`, `lm.season.v1`, `lm.settings.sound`)
`GameProgress` 필드: detectiveName, introSeen, completedMissionIds(해결 순서, final 포함), attempts, wrongAnswers, hintsUsed, missionStartedAt, missionStartPlayMillis, solveSeconds, badgeIds, lookedUpWords, startedAt, completedAt, playMillis
- **사건별 저장**: Episode 01은 기존 키 `lm.progress.v1` 그대로(이전 세이브 호환), 나머지는 `lm.progress.v1.ep02` … (`AppConstants.progressKeyFor`)
- **시즌 기록** `lm.season.v1` = `SeasonProgress { activeEpisodeId, solvedEpisodeIds }`. 해결 기록은 사건 세이브가 아니라 여기에 남아 **다시 하기(Play again)를 해도 다음 사건이 잠기지 않음**
- 이전 버전 세이브 마이그레이션: 시즌 기록이 없고 ep01이 해결돼 있으면 ep01을 solved로 간주 (`SeasonNotifier.build`) — 에뮬레이터의 실제 구버전 세이브로 확인
- 사건 전환: `GameController.openEpisode(id)` — 잠긴 사건은 **컨트롤러에서 거부**(UI만의 검사 아님), 떠나는 사건의 플레이 시간을 먼저 저장, 탐정 이름을 대상 사건 세이브로 복사, `seasonProvider.open()` → 컨트롤러가 대상 사건 세이브로 rebuild
- `currentEpisodeProvider`는 이제 `seasonProvider.activeEpisodeId` + `episodeCatalogProvider`에서 파생 (main에서 카탈로그를 override)
- Play again: 이름만 유지하고 **현재 사건만** 초기화 (`resetCase`)
- Reset all: 모든 사건 세이브 + 시즌 기록 삭제, Case 01로 복귀 (Start 화면 "Start a new case", Game Master 초기화)

### Reports (`detective_report.dart`)
- 미션 점수 = `1.0 − 0.2×min(오답,3) − 0.15×힌트`, 0.3~1.0으로 clamp → 스킬별 평균 × 5 → 별 1~5
- 정답률 = 해결 수 / 총 제출 수, 사건 요약 문장·보호자 코멘트 자동 생성

---

## Data Models

### `Episode` (`data/models/episode.dart`)
`id`, `number`, `title`, `synopsis: List<String>`, `objectives: List<String>`, `intro: List<String>`, `missions: List<Mission>`, `finalMission: Mission`, `glossary: Map<String,String>`
- getters/methods: `allMissions`, `allClues`, `allEvidence`, `meaningOf(word)`, `missionById(id)`, `numberLabel`; `fromJson`/`toJson`

### `Mission` (`data/models/mission.dart`)
`id`, `number`, `title`, `location`, `story: List<String>`, `scene: Artwork`, `letterIntro`, `letter`, `type: MissionType`, `question`, `prompt?`, `options: List<ChoiceOption>`, `answer`, `acceptedAnswers`, `codeLength?`, `dialSymbols`, `hints: List<String>`, `clue?: Clue`, `evidence?: Evidence`, `successMessage`, `transition: List<String>`, `nextMissionId?`, `skills: List<Skill>`, `mapX`, `mapY`
- getters: `isFinal` (type == finalCode), `numberLabel`

### 같은 파일의 보조 타입
- `enum MissionType { multipleChoice, wordInput, numberCode, imageChoice, qrScan, finalCode }`
- `enum Skill { vocabulary, reading, problemSolving }`
- `enum Artwork { kingsCross, suitcase, britishMuseum, bigBen, hydePark, buckinghamPalace, towerBridge, londonEye, royalBox }`
- `ChoiceOption { id, label, artwork? }`
- `Clue { id, title, value, note, symbol? }`
- `Evidence { id, name, icon, description, inscription?, symbols: List<String> }`

### `GameProgress` (`data/models/game_progress.dart`) — Player / Progress 역할을 겸함
필드는 위 *Persistence* 참고 (`playMillis: int?`, `missionStartPlayMillis: Map<String,int>` 포함). 주요 메서드: `hasDetective`, `isCaseSolved`, `totalHints`, `hintsFor`, `usedHint`, `isCompleted`, `wrongCount`, `completedCount`, `allMissionsDone`, `currentMission`, `isUnlocked`, `collectedClues`, `collectedEvidence`, `elapsed`(저장된 플레이 시간, 이전 데이터면 벽시계), `copyWith`, `resetCase`, `fromJson`/`toJson`

### 기타
- `GameBadge` (enum, `features/game/scoring.dart`) — title, description(한국어), icon, color, `isEarned()`
- `XpBreakdown` — base, noHintBonus, speedBonus, total
- `DetectiveReport`, `MissionPerformance` (`features/result/detective_report.dart`)
- `SubmitResult { correct, tryAgain, locked }`, `SubmitOutcome` (`game_controller.dart`)
- `GameSound { tap, success, wrong, unlock, clue, finale }` (`audio_service.dart`)
- **별도의 Player / Hint / Badge 데이터 모델 클래스는 없다** (Player = GameProgress.detectiveName, Hint = Mission.hints 문자열 리스트, Badge = enum)

---

## Assets

| 종류 | 경로 | 비고 |
|---|---|---|
| Fonts | `assets/fonts/Cinzel.ttf`, `Fredoka.ttf`, `Nunito.ttf` | SIL OFL, 로컬 번들 (`AppText.display/heading/body`) |
| Audio | `assets/sounds/tap.wav`, `success.wav`, `wrong.wav`, `unlock.wav`, `clue.wav`, `final.wav` | `tool/gen_sounds.js`로 생성한 합성음 |
| Images | Mission Map 지도 1장 (`assets/images/london_mystery.png`) | 그 외 랜드마크·Royal Box·증거 아이콘 모두 CustomPainter (`widgets/landmark_art.dart`, `london_map_painter.dart`, `final_mission_screen.dart`). PNG 교체 지점: `widgets/art_assets.dart` (*Phase 4* 참고) |
| Icons | Ink Icon System (`InkGlyph`, `widgets/ink_icon.dart`). 예외: QR 스캐너 화면에 Material 아이콘 3개(손전등·카메라 없음·카메라 꺼짐)가 남아 있음. 그림이 없는 심볼·배지는 모노그램 | 앱 런처 아이콘은 별도 커밋에서 통일 |
| Animations | **asset 없음** | Flutter 내장 애니메이션(AnimationController, Tween, AnimatedSwitcher)만 사용 |

pubspec에 등록된 asset 디렉터리는 `assets/sounds/` 뿐이다 (폰트는 `fonts:` 섹션).

---

## Environment

- Flutter **3.47.2** (stable) / Dart **3.13.2** / SDK constraint `^3.13.2`
- Platforms: android, ios, web, windows (Android `CAMERA` 권한, iOS `NSCameraUsageDescription` 설정됨)
- Android package: `kr.co.jness.london_mystery`
- 방향: 세로 고정 (`main.dart`)

### Dependencies
| 패키지 | 버전 | 용도 |
|---|---|---|
| flutter_riverpod | 3.4.3 | 상태 관리 |
| go_router | 18.0.1 | 라우팅 + 가드 |
| shared_preferences | ^2.5.5 | 로컬 저장 |
| mobile_scanner | ^7.4.2 | QR 스캔 (android/ios/web/macOS) |
| qr_flutter | ^4.1.0 | Game Master QR 카드 표시 |
| audioplayers | 6.8.1 | 효과음 |
| cupertino_icons | ^1.0.8 | 기본 |
| (dev) flutter_test, flutter_lints 6.0.0 | | 테스트/린트 |

### Commands
```bash
flutter pub get
flutter run
flutter analyze        # 2026-09-29: No issues found
flutter test           # 2026-09-29: 253 tests passed
flutter build apk --dart-define=LM_PLAYTEST=true   # 플레이 테스트 도구가 보이는 빌드 (Phase 4)
node tool/gen_sounds.js  # 효과음 재생성
```

### Git
- 이 프로젝트는 **자체 git 저장소가 없다.** 상위 폴더 저장소(`D:/20210701/vscode`, 브랜치 `master`, 커밋 `449b43c Initial commit` 1개)의 **untracked(`??`) 디렉터리**로 잡혀 있다
- 즉 현재 코드는 **어떤 커밋에도 포함되어 있지 않다** (Known Issues 참고)
- 절대 임의로 reset / revert / checkout / clean 하지 않는다

---

## Known Issues

- [ ] **버전 관리 부재** — 프로젝트 전체가 git untracked 상태. 실수로 삭제/덮어쓰기 시 복구 수단이 없음. 사용자 승인 후 커밋 또는 별도 저장소 초기화 필요 (임의 실행 금지)
- [x] ~~**경과 시간이 벽시계 기준**~~ — 2026-09-28 수정. 활성 플레이 시간(`playMillis`)으로 전환해 지도 타이머, 스피드 보너스, Case Closed, 보호자 리포트 모두 백그라운드·종료 시간을 제외 (*Play Time* 참고)
- [x] ~~**ParentGate TextEditingController 조기 dispose**~~ — 2026-09-28 **실제 버그로 확인 후 수정.** 위젯 테스트에서 확인·오답·취소 세 경로 모두 `A TextEditingController was used after being disposed.` assert가 재현됨. controller를 다이얼로그 `State`가 소유하게 바꿔 route가 제거될 때 dispose (`test/parent_gate_test.dart`)
- [x] ~~**Parent Report 접근에 Parent Gate 없음**~~ — 2026-09-28 수정 (*Parent Report Access* 참고)
- [ ] **foreground 상태에서 강제 종료되면 마지막 행동 이후 시간이 빠짐** — 크래시, 디버거 종료, 일부 데스크톱(Windows) 창 닫기처럼 lifecycle 이벤트 없이 종료되는 경우. 마지막 저장 시점까지는 보존됨 (의도적 트레이드오프: 주기적 저장은 넣지 않음)
- [ ] **업데이트 이전의 진행 중 저장 데이터** — `playMillis`가 없어 플레이 시간이 0부터 다시 시작됨 (닫혀 있던 시간이 기록된 적이 없어 분리할 수 없음). 해결된 사건은 기존 벽시계 결과 유지
- [ ] **실기기 lifecycle 검증 필요** — Android/iOS에서 홈 버튼, 앱 전환, 화면 잠금 시 `hidden/paused` 전달을 실제로 확인하지 않음 (위젯 테스트에서는 시뮬레이션으로 검증됨)
- [ ] **정답이 앱 번들에 포함** — 오프라인 현장 게임에는 문제 없으나, 보상/경쟁 요소나 백엔드 도입 시 서버 측 검증 필요 (README에도 명시)
- [ ] **웹 배포 시 보안 헤더 미설정** — CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy를 호스팅 레이어에서 설정해야 함 (Flutter 코드로는 불가)
- [ ] **런처 아이콘·스플래시 기본값**
- [ ] **README와 실제 플랫폼 불일치** — README는 QR이 macOS에서 동작한다고 하지만 `macos/` 폴더가 없음
- [ ] **Game Master 접근 권한이 세션 동안 유지됨** — `gameMasterAccessProvider`는 한 번 통과하면 앱을 끌 때까지 true. 모바일에서는 UI가 매번 Parent Gate를 요구하지만, 웹에서는 통과 후 `/game-master` URL로 다시 들어갈 수 있음 (이번 범위 밖, 기존 동작)
- [x] ~~**EP02 "Coming soon" 카드 하드코딩**~~ — 2026-09-29 Case Files가 카탈로그(`episodeCatalogProvider`)와 연결됨
- [x] ~~**Final 화면 "OPEN MY NOTEBOOK" 버튼 가독성**~~ — 2026-09-29 공통 `GameButton.outline`이 밤 배경을 인식해 gold ink로 전환 (*Season 1 QA → UI* 참고)
- [x] ~~**Notebook은 사건별**~~ — 2026-09-29 CASE ARCHIVE 추가, Case 12에서 이전 사건 Evidence·Clues 열람 가능
- [x] ~~**Case Files에서 방금 해결한 사건의 다음 사건이 자동 선택되지 않음**~~ — 2026-09-29 `/episodes?case=epNN`: 폴더 열림 + 선택 + 스크롤 (*Phase 4*)
- [x] ~~(경미) Case 02 Final 해결 후에도 시계가 8:17~~ — 2026-09-29 해결 애니메이션과 함께 9:17로 돌아감 (`LandmarkArt.solved`)
- [x] ~~(경미) 시퀀스 퍼즐의 Undo/Start again 비활성 구분 없음~~ — 2026-09-29 공통 `InkTextButton`이 비활성일 때 `locked` 회색
- [ ] (경미) **CONTINUE ADVENTURE로 Case Files에 들어오면 인트로를 아직 안 본 사건은 선택되지 않음** — 기존 동작(인트로를 본 사건만 선택 유지). `OPEN CASE NN`과 플레이 테스트 도구(`CASE NN부터`)로 들어오면 선택되어 있음
- [ ] (UI 감사 후 남은 것, 2026-10-02) Game Master 화면은 아직 Material 기본 위젯(흰 Card·ExpansionTile·기본 BackButton 아이콘). 다이얼로그·OutlinedButton·초기화 버튼만 정리함
- [ ] (UI 감사 후 남은 것) ParentGate 문제(6~9 × 6~9)는 8~12세가 풀 수 있는 수준. 오답이면 안내 없이 닫힘 (테스트가 이 동작을 고정하고 있어 이번에 바꾸지 않음)
- [ ] (UI 감사 후 남은 것) 지도 메뉴 시트는 기본 ListTile/SwitchListTile, Parent Report는 영어·한국어 혼용과 3열 지표(360폭에서 좁음)
- [ ] (UI 감사 후 남은 것) Final Case는 처음 들어오면 아트→이야기→편지→자물쇠 순서로 스크롤해서 읽음(다시 들어오면 자물쇠로 바로 이동). 360×640 첫 화면에는 자물쇠가 보이지 않음
- [ ] (UI 감사 후 남은 것) 버튼 라벨 Cinzel 대문자는 그대로(영어가 외국어인 아이의 가독성은 실제 플레이 테스트로 판단 필요)
- [ ] (경미) `StorySceneScreen.build()` 안에서 `lines.isEmpty`일 때 `_done = true`를 대입 (build 중 상태 변경). 현재 모든 일반 미션에 transition이 있어 실제로 발생하지 않음

---

## TODO

### High Priority
- [ ] 현재 코드를 git에 커밋하여 보존 (사용자 승인 후)
- [ ] 실제 기기(Android/iOS)에서 전체 플레이 1회 수동 검증 — 특히 QR 스캔, 카메라 권한 거부 흐름, 사운드, ParentGate 닫기, **홈 버튼/앱 전환/화면 잠금 후 플레이 시간**
- [x] ~~경과 시간 계산 방식 결정~~ — 앱 활성 시간만 누적으로 결정·구현 (2026-09-28)

### Medium Priority
- [ ] 영어 난이도 처리 방향 결정 (난이도 레벨 / TTS 읽어주기 / 현 상태 유지)
- [x] ~~에피소드 선택을 `EpisodeRepository.availableEpisodeIds()`와 연결~~ (2026-09-29)
- [ ] Season 1 Case 03~11 **처음부터 끝까지 실기 플레이** — **준비 완료**: Game Master `CASE NN부터` / `지금 사건 처음부터` (테스트 빌드 전용). 남은 것은 실제 기기에서 플레이하는 일 (Case 07은 에뮬레이터에서 도구로 시작 확인)
- [ ] 8~12세 대상 **실제 아이 플레이 테스트**로 난이도·힌트 강도 조정 — 체크리스트 준비됨: `docs/playtest/SEASON1_PLAYTEST_CHECKLIST.md` (특히 Case 02 시계 읽기, Case 09 Final 논리 소거, 힌트 2가 답에 가까운 Case 05 M3·Case 09 M2·Case 11 M2)
- [ ] TODO: CUSTOM ASSET REQUIRED — 목록·사양·우선순위: `docs/art/VISUAL_ASSET_INVENTORY.md`. A: Case 01 심볼 crown·park·museum, 배지 masterDetective / B: 배지 3개, 장면 staffRoom·courtyard·dressingRoom·waitingRoom / C: boathouse·roseGarden, palace(미사용), 기타 UI 글리프. 파일이 오면 `ArtAssets`에 한 줄 추가
- [x] ~~Final 화면 notebook 버튼 가독성~~ (2026-09-29 공통 스타일로 수정)
- [x] ~~시즌 통합 노트북~~ (2026-09-29 CASE ARCHIVE)
- [ ] 효과음 품질 개선 (합성음 → 실제 효과음, 라이선스 확인)
- [x] ~~Parent Report 접근 정책 결정~~ — 매번 Parent Gate 요구로 결정·구현 (2026-09-28)
- [ ] Game Master 접근도 1회용 통과권으로 바꿀지 결정 (웹 배포 시 의미 있음)

### Low Priority
- [ ] 런처 아이콘·스플래시 교체
- [ ] 탐정 등급/칭호 (XP 기반) 검토
- [ ] README 플랫폼 설명 정정 (macOS)
- [ ] 웹 배포 시 호스팅 보안 헤더 설정

---

## Phase 3 — Visual & UX Redesign (진행 중 — Step 3 완료, 사용자 확인 대기)

Goal: Reduce UI density and establish a consistent London Mystery visual identity.

Visual Direction: **Vintage London Detective Storybook**

Principles:
- One Screen = One Primary Purpose
- Progressive Disclosure
- Story-first UI
- Minimal UI
- Consistent iconography
- Consistent illustration style
- Preserve existing game systems

Status:
- [x] Step 1 — 전체 UI Audit (2026-09-28)
- [x] Step 0/2 — Design System 정의 및 구현 (2026-09-28, 승인됨)
- [x] Step 3 — Start / Mission Map / Mission 리디자인 (2026-09-28)
- [x] Step 3.1 — 실기기 피드백 반영 (2026-09-28): Case Files, 지도 YOU'RE HERE, GO TO 버튼 고정 크기, 편지 UI와 오픈 애니메이션, Well Done 정리
- [x] Step 3.2 — 2차 실기기 피드백 반영 (2026-09-28): Case Files 기본 접힘, YOU'RE HERE 표시를 지도에 맞게 정리, 봉투 디자인과 오픈 애니메이션 재설계
- [ ] Step 5 — 나머지 화면 적용 (**사용자 확인 후 진행. 임의로 진행하지 말 것**): 오답 시트, Story Scene, Notebook, Evidence, Final Case, Case Solved, Register, Story Intro, 다이얼로그, Parent Report

Step 3.2 변경 (UI만. 로직·모델·라우팅·저장은 그대로. 아래 3.1의 설명 중 해당 항목을 대체):
- **Case Files**: 항상 모든 폴더가 접힌 상태로 시작(자동 펼침 없음). 이미 시작한 탐정은 에피소드가 선택된 상태로 간주해 CONTINUE가 바로 활성
- **지도 현재 위치**: 네이비 원·펜 원·테두리 이름표·종이 박스 제거. 남은 것: 작은 "YOU'RE HERE"(Cinzel 9.5) + 작은 잉크 화살표 + 잉크 위치 핀(`_InkPinPainter`, 핀 끝 = 지도상의 위치 = 점선 경로의 끝) + 지도에 직접 쓴 장소명. 글자는 얇은 종이색 외곽선(`MapLettering`, 인쇄 지도식 표기, glow 아님)으로 경로선 위에서도 읽힘. 외곽선 레이어는 semantics·text finder에서 제외
- **봉투** (`letter_card.dart`): 빅토리아풍 봉투 뒷면. 레이어별 painter로 분리(`_PocketPainter` 몸통 / `_FlapPainter` 덮개 / `_WaxBlobPainter` 봉랍) → PNG/SVG로 교체 쉬움. 살짝 불규칙한 가장자리와 모서리, -1.4° 기울기, 오래된 manila 색 + 미세한 반점 + 모서리 foxing, 약한 종이 그림자, 곡선 끝의 덮개, 불규칙한 봉랍, 흐린 손도장 우체국 소인("LONDON")
- **오픈 애니메이션** (`EnvelopeReveal`, 850ms): ① 봉랍이 가운데로 갈라져 벌어지며 사라짐 → ② 덮개가 뒤로 젖혀짐 → ③ 세 번 접힌 편지가 봉투 안에서 위로 나옴(봉투 몸통 뒤에서) → ④ 봉투가 아래로 빠지며 사라지고 편지는 중앙으로 오며 접힌 1/3에서 전체로 펼쳐짐(0.82→1 소폭 스케일, 기울기 -1.4°→-0.6°) → ⑤ 글씨가 마지막에 짧게 fade-in. 마지막 프레임과 완성된 `LetterCard`가 같은 위치라 전환이 튀지 않음. 이미 연 편지는 애니메이션 없이 바로 표시
- `LetterCard(textOpacity:)` 추가(애니메이션용)

Step 3.1 변경 (UI만. 로직·모델·라우팅·저장은 그대로):
- **Case Files** (`episode_select_screen.dart`): 사건 폴더(`CaseFolder`: 탭 + 마닐라 종이) 목록만 먼저 보이고, 폴더를 누르면 에피소드가 아래로 펼쳐지는 아코디언(한 번에 하나, 220ms). 에피소드는 한 단계 낮은 계층(들여쓰기·얇은 구분선). 선택하면 왼쪽 네이비 선 + 체크 + 시놉시스 한 줄. `BEGIN/CONTINUE INVESTIGATION`은 화면 하단 고정이고, 에피소드를 고르기 전에는 비활성. Case/Episode 목록은 화면 안의 표시용 목록(Case 01 = EP01 + 봉인된 EP02·03, Case 02 봉인)이며, 플레이 가능한 에피소드는 여전히 `currentEpisodeProvider` 하나. 이미 시작한 탐정은 폴더가 열리고 선택된 상태로 시작
- **지도**: 현재 장소 위에 "YOU'RE HERE" + 잉크 화살표(Cinzel 10, burgundy, 종이 배경이라 경로선이 뒤로 지나감, 2px 느린 이동만). 현재 마커 아이콘은 잉크 위치 핀(`InkGlyph.pin`). 핀 앵커는 `MapPin.anchorY`
- **GO TO 버튼**: `GameButton(singleLine: true)` = 높이 56 고정, 한 줄, 화살표 위치 고정, 긴 이름은 줄바꿈 대신 약간 축소(FittedBox). 가로는 하단 행의 Expanded로 고정. 360dp에서도 오버플로우 없음 확인
- **편지** (`letter_card.dart`): `LetterCard`를 CustomPaint로 다시 그림 — 살짝 불규칙한 종이 가장자리, 세 번 접힌 자국, 아주 옅은 얼룩, 부드러운 종이 그림자, 하단 모서리 밀랍 봉인. 오픈 애니메이션(`EnvelopeReveal`)은 850ms 한 흐름으로 새로 설계: 봉인이 들리고 flap이 열림 → 종이가 올라옴 → 봉투가 사라지며 편지가 위에서 아래로 펼쳐지고 자리잡음. bounce·큰 확대·회전·glow 없음. 이미 연 편지는 애니메이션 없이 바로 표시
- **Well Done** (`answer_feedback.dart`): 애니메이션 순서(도장 → 한 줄 → XP 카운트 → 배지 → 버튼)는 유지하고 요소를 줄임. 큰 "WELL DONE" 도장, 미션 결과 한 줄, `New clue: "…"` 한 줄, 작은 `+XP`, 새로 얻은 배지가 있을 때만 텍스트 한 줄, `CONTINUE →`. 제거: XP 세부 내역, "ADDED TO YOUR NOTEBOOK" 카드, 증거 카드, 중복 인사말, 다색 메달. 배경은 불투명 네이비. 컨페티는 유지하되 팔레트 색으로만. XP·배지·단서·증거 저장은 그대로

Design System (구현됨):
- 색 `lib/core/theme/app_colors.dart`: ink `#2A2622`, navy `#1E2A44`(Primary), paper `#F4ECDA`, paperLight `#FAF5EA`, muted royal blue `#3E5A8C`, antique gold `#A8844A`, burgundy `#7A2E2E`. 상태 색은 도장·작은 글씨·선·아이콘에만 사용: muted green `#5E7A55`, muted burgundy `#94453D`, muted gray `#A39C8C`. 기존 색 이름은 호환을 위해 유지하고 값만 교체
- 폰트 `app_text.dart`: Cinzel = 짧은 대문자 라벨·도장·로고만 / Libre Baskerville(`assets/fonts`, OFL) = 제목·장소명 / Nunito = 본문·버튼. Fredoka는 더 이상 사용하지 않음(pubspec 등록만 남음)
- 토큰 `app_tokens.dart`: `AppSpace`(4pt 스케일, 화면 여백 24), `AppRadius`(paper 4 / button 12 / sheet 20), `AppShadow.paperLift`(유일한 그림자), `AppLine`
- 공통 컴포넌트: `GameButton`(평평함, navy=종이 위 Primary, gold=밤 화면 Primary, outline=보조, `arrow:`로 →, 비활성은 흐린 연필 윤곽) · `InkTextButton` · `InkIcon`/`InkGlyph`(CustomPainter 잉크 선 아이콘 18종) · `PaperSheet` · `InkStamp` · `DetectiveTipNotes` · `LondonSkyline` · `PaperBackground`(단색 종이 + 섬유 결)
- 삽화 `LandmarkArt`: 하늘 gradient·구름·glow 제거 → 종이 바탕 + 잉크 선(손그림 느낌의 두 번째 선) + 제한된 워시 색. 큰 그림에서도 선이 두꺼워지지 않게 선 굵기 보정. `Artwork` 키 구조는 유지(향후 PNG/SVG로 교체 가능)

리디자인한 화면 요약:
- Start: 떠다니는 엠블럼·배지·에피소드 표기 제거 → 잉크 도장 + 로고 + 한 줄 + CTA 1개 + 잉크 스카이라인. 도장 길게 누르기 = Game Master (기존과 동일)
- Mission Map: 헤더의 에피소드 라벨·타이머·탐정 이름·XP·진행바·n/5 제거 → 사건 제목 + 메뉴만. **탐정 이름·XP·플레이 시간은 메뉴 시트로 이동.** 핀: 현재 장소만 이름표, 해결한 곳은 체크 도장, 잠긴 곳은 "?". 경로는 해결한 곳까지 실선, 현재 장소까지 점선, 그 뒤는 숨김. pulse·glow·sparkle 제거, 해금 연출은 "UNLOCKED" 도장. CTA 문구 `GO TO {장소} →`
- Mission: appbar 제목·단계 점 제거. story(장소·장면·짧은 이야기·INVESTIGATE) → letter(봉투 → 열면 SOLVE THE PUZZLE) → puzzle(질문·답·조용한 Letter / Need a tip? 링크). 팁은 종이 쪽지로 표시하고, XP 비용 문구는 제거

Phase 3 남은 이슈:
- [ ] 리디자인하지 않은 화면은 색·폰트 톤만 바뀐 상태라, 새 화면과 기존 카드 스타일이 섞여 있음 (Step 5에서 해결)
- [ ] 오답 시트에 이모지(💡) 남아 있음. 최종 미션 `TipsPanel`, `GameSymbol` 다색 아이콘, `BadgeMedal` gradient(노트북 배지 탭)도 남아 있음 (Step 5 대상)
- [ ] Case Files의 Case 02, EP02·03은 표시용 자리(봉인). 실제 에피소드를 추가할 때 `EpisodeRepository.availableEpisodeIds()`와 연결해야 함
- [ ] 지도의 실시간 타이머를 제거함. 플레이 시간은 메뉴를 열었을 때 그 시점 값으로 표시 (측정·저장 동작은 그대로)
- [ ] Fredoka 폰트 등록 정리 (전체 리디자인 완료 후)
- [ ] 실기기에서 폰트 렌더링과 작은 화면(360dp) 확인 필요

Audit 요약 (현재 UI가 "AI가 만든 교육용 앱"처럼 보이는 원인):
- 장식 과다: gradient·glow·bounce·이모지가 20개 파일에서 45곳 사용됨 (paper 배경, 편지, 밀랍 봉인, 메달, 증거 아이콘, 하늘, 지도)
- 색이 너무 많음: 심볼·배지에 보라/청록/초록/빨강이 섞여 있고, gold `#E2A93B`, royalBlue `#3257C8`의 채도가 높음
- 폰트: 둥근 Fredoka(제목·버튼)가 교육용 앱 인상을 줌
- 아이콘: Material filled rounded 아이콘, 이모지(💡🎉), 컬러 원형 배지가 섞여 있음
- 카드: 흰 배경 + 22~28px 라운드 + 그림자가 모든 화면에서 반복됨
- 정보 과다: 지도 헤더(에피소드·제목·타이머·메뉴·이름·XP·진행바·n/5), 성공 오버레이(약 12개 요소가 동시에 표시), Case Closed(약 18개 요소)

## Next Development Goal

**아직 사용자가 확정하지 않았다. 아래는 모두 `Proposed` 이며, 승인 전에는 개발하지 않는다.**

- ~~Phase 2 안정화: 경과 시간 / ParentGate / 보호자 리포트~~ — **완료** (2026-09-28)
- `Proposed` — **Phase 2 마무리**: git 보존 → 실기기 QA (lifecycle, QR, 사운드 포함)
- ~~`Proposed` — **Phase 3 후보 A: Episode 02**~~ — **완료** (2026-09-29, Season 1 Case 02~12 전체)
- ~~`Proposed` — **Season 1 QA**~~ — **완료** (2026-09-29)
- ~~**Phase 4 — Playtest Preparation & Visual Polish**~~ — **완료** (2026-09-29). 다음 단계 후보: ① 체크리스트로 실제 아이 플레이 테스트 → 결과로 문장·힌트 데이터 조정 ② A등급 그림 발주·교체 ③ 효과음
- `Proposed` — **Season 2 (Paris?)**: Case 12 훅(PARIS 시계)에서 이어짐
- `Proposed` — **Phase 3 후보 B: 탐정 성장 시스템** — XP 누적 → 탐정 등급/칭호, 탐정 ID 카드
- `Proposed` — **Phase 3 후보 C: 영어 접근성** — 문장 읽어주기(TTS/녹음), 난이도 선택

---

## Development Rules

1. Never rebuild the project from scratch.

2. Never delete existing functionality without explicit approval.

3. Always inspect existing code before modifying a feature.

4. Reuse the existing architecture whenever possible.

5. Do not add unnecessary dependencies.

6. Do not introduce backend infrastructure unless explicitly requested.

7. Keep the MVP playable from start to finish.

8. Preserve the mystery/adventure identity.

9. Do not turn the product into a generic English learning application.

10. Prefer simple and maintainable solutions over unnecessary complexity.

11. Never mark a feature as COMPLETE unless it is actually implemented and verified.

12. When a feature is added or changed, update PROJECT_CONTEXT.md.

13. When an important architecture decision is made, update PROJECT_CONTEXT.md.

14. When an issue is discovered, update PROJECT_CONTEXT.md.

15. At the beginning of every new Claude Code session, read PROJECT_CONTEXT.md first.

16. Compare PROJECT_CONTEXT.md with the actual source code before starting substantial work.

17. The source code is the final source of truth if PROJECT_CONTEXT.md and the code disagree.

18. Preserve existing working functionality while extending the project.

### Project-specific conventions (코드에서 확인된 관례)
- 콘텐츠는 데이터다: 새 미션/에피소드는 위젯이 아니라 JSON 형태 데이터(`data/mock/`)로 추가
- 상태 변경은 `GameController`를 통해서만, 변경 즉시 저장
- 새 화면은 `Routes`에 경로 추가 + `redirect` 가드 규칙 추가 (URL로 건너뛰기 불가 유지)
- 사운드 재생은 `audioServiceProvider`를 통해서만 (예외를 던지지 않음)
- 저장 데이터 역직렬화는 `jsonDecode` + 수동 필드 파싱만 (다형성 역직렬화 금지)
- 사용자 입력은 입력 필터(`FilteringTextInputFormatter`) + 로직 측 검증을 함께 적용
- 변경 후 `flutter analyze`와 `flutter test`를 통과시킬 것

---

## Session Continuity Protocol

At the beginning of every new Claude Code session:

1. Read PROJECT_CONTEXT.md.
2. Inspect the current project structure.
3. Check git status.
4. Compare the documentation with the actual code.
5. Identify the current development phase.
6. Identify completed, partial, and pending work.
7. Check known issues.
8. Only then begin the requested task.

At the end of a significant development session:

1. Update PROJECT_CONTEXT.md.
2. Record newly completed features.
3. Record partial or unfinished work.
4. Record newly discovered issues.
5. Update TODO.
6. Update the Next Development Goal.
7. Add a concise entry to the Change Log.

PROJECT_CONTEXT.md is the persistent development context for this project.

---

## Change Log

### 2026-10-02 — Title Screen: 탐정 사무실 artwork

- 파일: `assets/images/title/title_detective_office.png`(941×1672), pubspec `assets/images/title/`, `ArtAssets.titleDetectiveOffice` + `…Pixels`. 타이틀 화면 전용(Season Cover 파노라마 재사용 안 함)
- 이 화면에서 제거(공용 위젯·asset은 유지): `PaperBackground(night)`의 밤하늘·별·하단 스카이라인, 큰 `BrassEmblem` 로고(그림의 책상 위 돋보기와 중복), 밝은 gold 버튼, 스카이라인 자리 여백. 그림이 없을 때만 기존 밤 페이지로 폴백
- 구성: 그림 full-bleed(`BoxFit.cover`, 좁은 폰 `Alignment(0.55, 0)` → 창문·Big Ben 온전, 램프는 일부). 제목은 **왼쪽 위 책장/커튼의 어두운 영역**(창문의 달·Big Ben 비움): THE CASEBOOK OF / LONDON / MYSTERY / ◆ / Become a Detective.(+ 저장 있으면 Welcome back). 열 폭 ≤ 화면 68%, 제목 단어는 한 줄 고정(넘치면 축소), 글자 확대는 1.15배까지. 그늘은 제목 뒤 radial + 화면 아래 20%만(책상 소품은 그대로)
- CTA: Season Cover와 같은 `GameButtonStyle.glass`. 새 플레이어는 아래 여백 16 + 화면 높이 3.8%(20~28), 저장 있으면 그 아래 `Start a new case`
- 후속(같은 날): 부제 한 줄만 — 새 플레이어 `Become a Detective.` / 저장 있으면 `Welcome back, Detective {이름}!`(같은 aside 스타일·좌측선). 보조 버튼 `Start a new case` → **`NEW ADVENTURE`**(동작·확인 창 그대로, 확인 창 제목은 여전히 "Start a new case?"). 저장 있을 때 버튼 그룹 아래 여백 8 → 8 + 화면 높이 1.9%(10~14)
- Ambient(같은 날, 그림 레이어에만, 글자·버튼은 고정): 카메라 1.0 ↔ 1.022(14s 왕복 easeInOut, 창문 쪽 Alignment(0.6, -0.3)), 창문 유리 4칸에만 clip된 빗줄기 34개(가늘고 옅게, 9s 루프·끊김 없음, CustomPainter), 램프 주변 따뜻한 빛 0.88 ↔ 1.0(4.2s 왕복). 셋 다 **진입 2.4s 뒤** 2s fade-in으로 시작, 다이얼로그(Parent Gate·새 모험 확인) 동안 정지, 다른 페이지가 덮으면 TickerMode로 정지, 앱 백그라운드는 프레임 없음, dispose 확인. 첫 진입 시 1회만 제목→장식선→부제→버튼 0~1s fade + 6px 상승(버튼은 처음부터 눌림). 모션 줄이기 = 전부 정적
- 수정(같은 날, 실기기 보고: 진입 직후 글자·버튼이 그림 뒤로 사라짐): 위젯 트리 순서는 원래 정상(테스트 렌더러에서 재현 안 됨). 원인 추정 = 램프 빛의 `BlendMode.screen`(Impeller의 advanced blend — 배경을 다시 읽어 합성) — 이 painter가 그리기 시작하는 2.4s와 증상 시점, 그 사각형 영역과 "Welcome back"의 보이는 부분이 일치. → source-over로 변경(같은 세기). 구조도 정리: camera push는 그림에만, 비·램프 빛은 각자 같은 push를 따르는 형제 레이어 + `IgnorePointer`, 그 위 그라데이션, 맨 위 UI. 같이 찾은 버그: 등장 구간 계산으로 NEW ADVENTURE가 영원히 불투명도 0.98에서 멈춤 → 각 구간이 1에서 끝나게. 비 미세 조정: 속도 +25%(루프 9s → 7.2s), 굵기 0.8 → 0.98, 길이 약 +8%, 투명도·개수 그대로. 테스트 +2(360·390, 0.1/1.2/5/12s에 UI가 그림·비·램프보다 나중에 그려지고 불투명도 1). **실기기 재확인 필요**
- **Game Master 길게 누르기**: 로고 대신 제목 블록에(동작·Parent Gate 동일)
- 로직 변경 없음(START/CONTINUE 분기, 새 게임 확인, 라우팅). 모션 없음(그림만으로 충분)
- Tests: 424 → 430 (`title_screen_test`: 360×640·390×844·1.3배 × 새/저장 — 그림이 화면 전체, 제목이 창문 왼쪽(폭 72% 안), 제목 단어가 줄바꿈되지 않음, 버튼이 아래 끝에서 떨어지고 책상 아래쪽, Welcome back·Start a new case. `LM_SCREENSHOTS`로 PNG)

### 2026-10-02 — Season Cover: 런던 파노라마 (사건철 제거)

- 파일: `assets/images/season1/season1_cover_london_panorama.png`(941×1672, 폴더는 이미 등록됨). `ArtAssets.season1CoverLondonPanorama` + `…Pixels`. **Cover 전용** — Scene 1 그림(`season1LondonNight`)과 서로 대체·반복하지 않음
- 제거: 가죽 사건철(`season_casebook.dart` 삭제), 종이 라벨, 책상 배경·지도(Cover에서), 밝은 gold 대형 버튼, 갈색 앱바 띠
- 구성: 그림 full-bleed(`BoxFit.cover`, 좁은 폰은 `Alignment(0.55, 0)` — Big Ben 쪽으로, 탐정 아이도 화면 안). 하늘에 LONDON MYSTERY / SEASON ONE / SHADOWS·OVER LONDON(항상 두 줄, 넓은 줄은 폭에 맞춰 축소) / 장식선 / 12 CASES • ONE MYSTERY. 위·아래에만 navy 그라데이션(도시 가운데는 맑게), 글자 그림자 최소. 제목 글자 확대는 1.15배까지(1.3배 설정에서도 도시를 덮지 않게)
- CTA: 새 `GameButtonStyle.glass`(반투명 navyDeep + 얇은 gold 테두리 + gold 글자, 깊이 없음) — 지붕 위, 아이와 겹치지 않음. Back: 그림 위 반투명 원형 배경
- 애니메이션: 제목·버튼 순서대로 등장 + 1.0 → 1.025 아주 느린 push(1.5s, 탭 = 즉시). BEGIN SEASON ONE → 0.52s 동안 Westminster 쪽으로 카메라가 들어가며(+0.14) 어둠으로 → 오프닝 Scene 1(밤 런던, 더 가까이)이 어둠에서 나옴. 모션 줄이기 = 바로 이동
- 미세 조정(같은 날): 제목 크기 약 18% 축소(폭 × 0.082, 26~36), 제목 ↔ 문구 사이 `OrnamentRule` 150폭 + 간격 확대, 문구는 goldLight→paperLight 35% + 진한 그림자, 문구 최대 폭 = 화면 62%(1.3배 글자에서도 Big Ben 시계에 닿지 않음), glass 버튼 배경 0.62 → 0.48(배경은 이 값으로 확정; 이후 버튼 인지성만 보강: 글자·화살표 goldLight→paperLight 20%, 테두리 0.75 → 0.92, 안쪽 선 0.25 → 0.32, glow·그림자 없음. Cover 구성은 확정), 버튼 아래 여백 16 + 화면 높이 3.8%(20~28) → 지붕이 버튼 아래로 보임, 탐정 아이와 간격 유지
- 360×640: 그림 비율과 같아 잘림 없음. 390×844: 좌우 일부 잘림, Big Ben·아이 모두 화면 안. 1.3배 글자 OK. 테스트 424개 그대로 통과(문구 `SHADOWS\nOVER LONDON`, `12 CASES • ONE MYSTERY`, `BEGIN SEASON ONE` 유지)

### 2026-10-02 — Season Opening Scene 1: 밤 런던 hero artwork 적용

- 파일: `assets/images/season1/season1_london_night.png`(941×1672, 9:16, 텍스트 없음). pubspec에 `assets/images/season1/` 등록. `ArtAssets.season1LondonNight` + `season1LondonNightPixels`(위젯에 경로 하드코딩 없음). **오프닝 1장면 전용** — 다른 화면에는 쓰지 않음
- `LondonNightHero`(`prologue_art.dart`): full-bleed `BoxFit.cover`, `focus = Alignment(0.75, -0.2)`(폰이 그림보다 좁으면 Big Ben 쪽으로 기울여 자름), 표시 폭 기준 디코딩(원본 이하). 파일 오류 시 기존 코드 그림 `NightLondon`으로 폴백
- 구도: 위쪽 옅은 navy 그늘(Back/SKIP 대비), 아래쪽 투명 → navy 그라데이션(0.52~1, 불투명 패널 없음) 위에 LONDON(부드러운 그림자) + 문장 + NEXT. 색 필터 없음
- Camera push: 기존 그대로 1.0 → 1.04, Big Ben 쪽(Alignment(0.7, -0.25))으로, 장면 애니메이션(1.4s)에 묶여 탭하면 즉시 완료
- 전환: 장면 사이 Scaffold 배경 = `nightBottom` → 밤 런던 → 어둠 → 책상 (420ms crossfade, 기존). 장면 2~5·파일·로직 변경 없음
- 확인: 360×640 = 그림 비율과 같아 잘림 없음(Big Ben·의사당·템스·가스등 전부), 390×844 = 좌우 약 18% 잘림, Big Ben 온전 + 여백, 가스등 일부만. 1.3배 글자 overflow 없음. 테스트 424개 그대로 통과

### 2026-10-02 — Season Opening Sequence (Briefing 문서 폐기 → 5장면 Prologue + Case 01 파일)

- **진단**: Briefing은 한 장의 종이에 정보를 배치한 화면이라 worksheet/onboarding처럼 보였음(teaser가 UI 라벨, 빈 지도 사각형, 12 CASES와 CTA 충돌). Cover의 폴라로이드는 이야기 없는 장식(scrapbook)
- **흐름**: Cover `BEGIN SEASON ONE` → `/season/prologue`(`season_prologue_screen.dart`, Briefing 화면·`SeasonBriefing` 모델 삭제) → ① LONDON(밤 런던) ② 책상 위에 사건 자료 4장이 하나씩(문장도 한 줄씩) ③ 지도에 따로 꽂힌 4장 "They look like separate cases." → "But a great detective looks closer." ④ 같은 지도에 붉은 실 2가닥이 교차 "What if they're connected?" ⑤ SEASON ONE / 12 CASES ◆ ONE MYSTERY + 3줄 → `ACCEPT THE CASE` → ⑥ Case 01 사건 파일(CASE 01 탭, THE MISSING CROWN, 왕관 사진, Case 01 synopsis 첫 줄, "Your first investigation begins tonight.", ASSIGNED 도장) → `START CASE 01` → 기존 Story Intro
- **조작**: 탭 = 장면 애니메이션 즉시 완료 → 다음 탭 = 다음 장면, NEXT ›, SKIP ›(→ ⑤). ⑤·⑥은 버튼으로만. Back(앱바·시스템 동일, 장면 단위 `BackTo`) = 이전 장면(완성 상태), ①에서 Cover. 모션 줄이기 = 즉시. 장면 등장 1.1~2.6s
- **저장**: 없음. Cover가 시즌 시작 전에만 나오므로 오프닝도 그때만(새 플래그 없음). START CASE 01 전에는 아무 사건도 시작되지 않음
- **데이터**: `season1InfoJson.prologue`(장면 문구, `\n` 줄바꿈, firstCase 그림 키 `crown`) + `SeasonPrologue` 모델. Case 파일 문장은 Episode synopsis(하드코딩 없음)
- **그림**: `prologue_art.dart` — `NightLondon`(기존 `LondonSkylinePainter`를 크게 + 템스강 반사광·안개·가스등, 카메라 push), `TroublePrint`(crown.png / letter.png / 잠긴 문 코드 그림 / 안개 속 실루엣 코드 그림), `TroubleMap`(Season 보드와 같은 호두나무 액자·세피아 지도·압정·붉은 실 → 보드는 이 지도가 완성되어 가는 것). `season_props.dart`에 `PrintFrame`
- **Cover**: 폴라로이드 제거, 지도는 어둡게(책상 그림자 속), 사건철만 초점
- **Custom Asset Required**: 밤 런던 파노라마(현재 코드 실루엣이라 단순), "mysterious stranger" 사진(현재 코드 실루엣). `clockmaker_master.png`는 스포일러라 사용 안 함
- **Tests**: 422 → 424. Briefing 테스트 → 오프닝 테스트(신규 플레이 Cover → ①~⑤ 문구·화면 안·글이 버튼 위·스포일러/학습 용어 없음 → 파일 → 인트로, 360×640 / 390×844 / 1.3배 글자, 탭·SKIP, Back 장면 단위·Cover 복귀·파일→⑤)

### 2026-10-02 — Season One 재설계: Season Briefing + 책상/보드 물성 (같은 날 Season One Experience 위에)

- **흐름**: Casebook `BEGIN SEASON ONE` → **새 `/season/briefing`**(`season_briefing_screen.dart`) → `BEGIN THE INVESTIGATION`(기존 BEGIN/CONTINUE INVESTIGATION 문체) → Case 01 Story Intro(그대로). Briefing은 사건을 열거나 저장하지 않음. Casebook은 시즌 시작 전(`begun` false)에만 나오므로 Briefing도 그때만 — **새 저장 플래그 없음**. Briefing Back → Casebook. 케이스 열기는 `SeasonActions.investigate` 하나(Season·Briefing 공용, `openEpisode` + 인트로/지도)
- **데이터**: `season1InfoJson.intro` → `briefing`(opening, teasers 4개 + ink glyph 이름, turn, connected, closing). `SeasonBriefing` 모델. Teaser는 분위기만(Missing treasures / Secret letters / Locked rooms / Mysterious strangers)
- **물성**: 새 토큰 `AppColors.walnut/walnutDeep` + `widgets/desk_background.dart`(호두나무 책상 + 결 + 램프 빛, InkSurface night). Season 세 화면 모두 navy 대신 책상 위. 공용 소품 `season/widgets/season_props.dart`: `MapPrint`(기존 지도, 세피아), `PhotoPrint`(기존 장면 그림 인화), `PushPin`, `PaperTag`
- **Cover**: 책상 위 지도 한 장 + Big Ben·Tower Bridge 사진(런던만, 사건 정보 없음) 위에 사건철. 사건철 = 가죽 결, 페이지 단면, 황동 모서리, 가죽 끈 + 황동 징, 약간 기울임. 문장 3줄 제거(Briefing으로), 책 ↔ CTA 간격 축소
- **Briefing**: CONFIDENTIAL 도장의 종이 dossier. 지도 위에 teaser 쪽지 4개(핀), 12 CASES / ONE MYSTERY, EVERY CLUE MAY BE CONNECTED. 순서대로 1.5s 등장(터치 = 즉시), 하단 고정 CTA, 문서 끝은 CTA 위로 페이드(이어짐 표시)
- **Board**: 호두나무 액자, 진한 세피아 지도 + 가장자리 그림자, 큰 사진(겹침 허용)·빨간 압정·번호 PaperTag, 봉인 사건 = 봉랍 봉투(작고 흐리게), 현재 = 빨간 핀 `?` 쪽지, 빈 메모 2장·LONDON 소인(정보 없음), 실에 그림자. 해결 연출 1.4s: 사진 → 핀 → 실 → 번호 태그 → 다음 사건 → figure, 터치 = 즉시
- **Main 하단**: 진행·현재 사건·CTA(navy, 종이 위 Primary)·View all case files를 종이 dossier 하나로 → 보드가 화면 대부분(360×640에서 약 330dp)
- **유지**: 스포일러 규칙(이전 항목 그대로), 저장·라우팅·Case Files·Notebook·Archive·Operator Mode
- **Tests**: 419 → 422 (+Briefing 390×844·1.3배 글자·Back, Cover 390×844, 시작된 시즌은 Briefing/Cover 없음 + 0/12 보드). 신규 플레이 테스트는 Cover → Briefing(문구·스포일러·학습 용어 없음) → Case 01 인트로로 변경. 스크린샷 헬퍼는 큰 지도 디코딩을 기다린 뒤 촬영

### 2026-10-02 — Season One Experience (LONDON MYSTERY → SEASON ONE → CASE → MISSION)

- **선행 수정**: `test/helpers.dart`·`lib/data/repositories/episode_repository.dart`의 import 줄이 깨져 있었음(`episode01_mock.dart'void ck.dart'…`, 파일을 `season1/`로 옮기며 생긴 편집 사고) → `season1/episode01_mock.dart`로 복구. 이 상태에서는 analyze 45 issues·테스트 컴파일 불가였고, 복구 후 기준선 392개 통과
- **데이터**: `data/models/season.dart`(`Season`, `SeasonFigure`, 관대한 fromJson) + `season1_mock.dart`의 `season1InfoJson`(제목 Shadows over London, tagline, intro/outro 문장, figures). **새 저장 키 없음**
- **상태 계산**: `features/season/season_overview.dart` `SeasonOverview.of` — 시즌 기록 + 사건 세이브 + 카탈로그에서 계산. 사건 표시(solved/current/open/sealed), 현재 사건(진행 중인 열린 사건 → 아니면 한 번도 해결 안 한 첫 해금 사건), `begun`(해결 기록 또는 인트로를 본 사건이 있음 = 첫 진입 판별, 플래그 없음), figure, 실(chain/lead/spoke). 잠금 규칙은 `SeasonNotifier.unlockRule`(기존 `isUnlocked`가 이를 호출 — 규칙 한 곳)
- **스포일러 규칙**(figure는 해당 사건 *해결 후*에만): 0~1 해결 `?`/ONE MYSTERY → Case 02 `WHO ARE THE RAVENS?`(Case 02 hook) → Case 04 `THE RAVEN SOCIETY`(Final 정답 RAVEN) → Case 05 `THE CLOCKMAKER` + `?`(Case 05 hook) → Case 12 Clockmaker의 회중시계(`pocket_watch.png`) + CLOSED. Grey·Rose·Robin·Shadow·PARIS는 시즌 화면에 전혀 없음. 봉인 사건은 번호만(스크린리더도 제목 없음). Operator Mode는 열기만 하고 공개하지 않음
- **화면** `features/season/season_screen.dart` (`/season`):
  - 시즌 시작 전: 가죽 Casebook(`widgets/season_casebook.dart`, 기존 leather/RuledFrame/BrassEmblem/PaperSheet/WaxSeal) → 문장 3줄 → `BEGIN SEASON ONE` → `openEpisode` → Case 01 Story Intro. 1.6s 등장(책 fade/scale → 라벨 → 봉랍), 탭하면 즉시 완료, 모션 줄이기 = 즉시
  - 이후: Investigation Board(`widgets/investigation_board.dart`) + CASES SOLVED n/12 + 사건별 점 + CURRENT CASE(번호 태그·제목, 탭 → 그 사건 Case File) + `CONTINUE/BEGIN INVESTIGATION`(Case Files와 같은 규칙·`openEpisode` 재사용: 인트로 / 지도) + `View all case files`. 완료: SEASON ONE COMPLETED + outro + `VIEW ALL CASE FILES`
  - Board: 흐린 세피아 런던 지도(`ArtAssets.londonMap`, BlendMode.color + 투명도) 위에 12개 사건을 위에서 시계 방향 링(superellipse, 길이 기준 등간격 → 어떤 비율에도 균등)으로 배치, Case 12가 맨 위에서 링을 닫음. 해결 = 그 사건 Final 장면 사진(Case Closed 사진과 같은 그림) + 황동 핀, 현재 = 빨간 핀 `?` 메모 + 점선 lead, 봉인 = 작고 흐린 자물쇠 메모. 붉은 실은 CustomPainter(처짐 곡선). 사건 탭 → `/episodes?case=`(봉인은 "Solve Case NN to open this file.")
  - 새로 해결한 사건 연출: `recentSolveProvider`(세션 전용, `recentUnlockProvider`와 같은 패턴, 처음 해결할 때만 컨트롤러가 추가) → 다음 Season 진입 시 1.8s: 사진 fade/settle → 실 그리기 → 다음 사건 열림 → figure 교체 → (완료 시) CLOSED 도장. 한 번만 재생, 모션 줄이기 = 즉시
  - 작은 화면: Board가 남는 공간을 쓰고 최소 220dp, 부족하면 페이지 스크롤(`_MinHeight` + IntrinsicHeight). 360×640·1.3배 글자에서도 스크롤 없이 CTA 보임(스크린샷 확인)
- **진입/라우팅**: Register `TO THE CASE FILES` → **`OPEN THE CASEBOOK`** → `/season`. Start `CONTINUE ADVENTURE`: 진행 중 사건 → 지도, 해결된 사건 → Case Closed(**기존 그대로**), 진행 중 사건 없음 → `/season`(이전 `/episodes`). Case Files Back(앱바·시스템) → `/season`(이전 `/register`). 지도 메뉴 `Season board`. 마지막 사건 Case Closed의 주 버튼 `CASE FILES` → **`INVESTIGATION BOARD`**(→ 완성된 보드, 거기서 VIEW ALL CASE FILES). Case 12 엔딩·PARIS 훅은 Case Closed에 그대로. Story Intro Back → Case Files(그대로)
- **유지**: 게임 로직·정답·저장 키·잠금 규칙·Case Files/Notebook/Archive·라우터 가드(`/season`은 탐정 등록 필요)·Operator Mode·Play again(시즌 해결 기록 유지)
- **Tests**: 392 → 419 (`season_screen_test` 27: overview 단위 9(0/12, 시작 판별, 중간, 12/12, 스포일러 표, 다시하기, Operator, 직전 상태) + 화면 18(신규 플레이 → Casebook → BEGIN → Case 01 인트로, 탭 스킵·Back, 기존 세이브 resume → 지도, 진행 없음 → 보드, 360×640·390×844 중간/완료 레이아웃·CTA 화면 안, 1.3배 글자, CONTINUE → 지도, Case Files ↔ Season(앱바·시스템 Back), 사건 탭·봉인 토스트·봉인 시맨틱, 화면 스포일러 단계, 해결 직후 reveal 1회, Case 12 → INVESTIGATION BOARD, 지도 메뉴, resetAll, Operator, URL 가드). `LM_SCREENSHOTS=폴더`로 PNG). 기존 테스트 수정: Register 버튼 라벨(`full_playthrough`·`ui_tour`·`small_screen` — Case Files 검사 항목은 라우터로 이동해 그대로 유지), 마지막 사건 버튼(`season_archive`: INVESTIGATION BOARD → VIEW ALL CASE FILES → `/episodes`)
- **Asset**: 사용 = `london_mystery.png`(흐린 지도), `raven_mark.png`(Raven Society·봉랍), `pocket_watch.png`(완료 figure = Case 12 증거 The Clockmaker's Watch), 기존 장면 그림/코드 그림(사건 사진). 새 파일 없음. 사용 안 함 = `clockmaker_master.png`(Clockmaker는 시즌 내내 직접 나오지 않음), 참고 이미지의 까마귀 문장 표지(첫 화면에서 까마귀 노출 = 스포일러 → 황동 돋보기 엠블럼), 핀·실·쪽지 PNG(코드로 충분)
- **남은 것**: 실기기 확인 안 함. 8~12세가 보드의 사진(작은 크기)을 사건으로 알아보는지, `BEGIN`/`CONTINUE` 구분을 이해하는지 플레이 테스트 필요

### 2026-10-02 — Mission 화면 Android Back 버그 (실기기 보고)

- **증상**: 장소(INVESTIGATE) 단계에서 Android 시스템 Back을 눌러도 Mission Map으로 돌아가지 않음 (실기기)
- **원인**: Mission의 `BackTo`(PopScope)가 장소 단계에서만 `canPop: true`라 시스템 Back을 라우트 스택과 플랫폼에 맡김 (AppBar 화살표는 `_back()`으로 다른 경로). Mission 아래에 지도가 없으면 Flutter가 Android에 `setFrameworkHandlesBack(false)`를 보내고, target SDK 36 + Android 16(predictive back)은 Back을 앱에 주지 않고 앱을 백그라운드로 보냄. 위젯 테스트로 확인(아래 테스트가 이전 코드에서 실패). 지도 위에 push된 일반 경로는 테스트 환경에서 정상이었으므로 실기기에서 어떤 경로로 스택이 비었는지는 확인하지 못함
- **수정** (`mission_screen.dart` 한 줄): `BackTo`를 모든 단계에서 켬 → 시스템 Back = AppBar Back = `_back()` (퍼즐→편지→장소→`pop`, 아래에 아무것도 없으면 `go(map)`). 라우팅 구조·UI 변경 없음
- **Tests**: 381 → 392. `back_navigation_test`를 다시 씀: 시스템 Back(popRoute) / Android 16 back gesture 채널 / AppBar 세 경로 × (지도←장소, 장소←편지, 편지←퍼즐), 다시 들어온 미션(퍼즐부터), 아래에 페이지가 없는 미션, 여러 번 Back(지도에서는 질문, 앱 종료 없음, `setFrameworkHandlesBack` 항상 true)

### 2026-10-02 — UI/UX 감사 1차 수정 (디자인 방향 유지, 접근성·조작·일관성)

- **대비**: `muted` #7C7466→#6A6254(종이 5.1:1), `goldDeep` #8A6A35→#7E5F2C(5.0:1), `locked` #A39C8C→#857D6D(큰 글씨·아이콘용 3:1+). 작은 잠금 글씨(Case Files·Notebook·Archive)는 `muted`로. 밤 화면의 `gold` 제목은 `goldLight`
- **GameDialog** (`widgets/game_dialog.dart`): 종이 문서 다이얼로그. `confirm`(아이용: 주 버튼 + 잉크 링크) / `confirmPlain`(보호자·운영자용: 장식 없음, Material 테마 버튼, `destructive`). Start·Case Closed·ParentGate·Game Master의 AlertDialog 대체. 버튼 라벨은 그대로
- **퍼즐 선택 상태** (`question_widgets.dart`): `AnswerState`(idle/selected/correct/wrong/disabled) + `_answerPaper` 하나로 통일. 선택 = navy 채움 + 금색 표시(객관식·그림 선택 동일). 시퀀스의 "다음 칸"은 금색 테두리(선택과 구분). 눌림 = `_Pressable`(0.97 축소 + 살짝 흐림, 90ms, 키패드 포함, Material ripple 제거). 키패드 지우기 키에 Delete/Clear 글자
- **정답 오버레이**: 화면을 탭하면 연출 즉시 완료, CONTINUE는 한 번만 동작, 모션 줄이기 설정이면 바로 완성 상태. 컨페티 제거(램프 빛·도장 유지). 팁 문구 통일: 링크 "Get a tip", 버튼 "GET A TIP"(`tipButtonLabel`). Final의 TipsPanel도 GameButton outline
- **뒤로가기**: `widgets/back_to.dart`(PopScope 래퍼). 지도 = "Leave the case?" 확인 후 타이틀(이동 중에는 무시). 미션 = 퍼즐→편지(열린 채)→장소→지도(앱바 화살표도 같음). Register→Start, Case Files→Register(앱바와 같음), Story Intro→Case Files, Story Scene·Case Closed→지도 (라우터의 pageBuilder에서 감쌈, 경로 구조는 그대로)
- **Mission Map**: 장소 이름을 NEXT LEAD 줄로 옮김(제목 20pt, 전체 폭), CTA는 "GO →"(스크린리더 라벨 `GO TO {장소}` = `GameButton.semanticLabel`). `_LeadNote` 고정 높이 52 제거(지도는 Flexible). 지도 글자 소폭 확대: YOU'RE HERE 9.5→11, 핀 이름 12.5→13.5, 랜드마크 11.5→12.5. YOU'RE HERE 화살표는 모션 줄이기면 멈춤
- **Register**: 키보드가 올라오면 기관명·엠블럼을 접고 제목 축소 → 입력줄·버튼이 키보드 위에 보임. 버튼 "START MISSION"→"TO THE CASE FILES"(실제 동작). 힌트 'MINYOUNG'→'SHERLOCK'. 오류는 GameToast. `AppText.style`에 한글 시스템 폰트 fallback
- **작은 화면**: Story Intro 새 줄 자동 스크롤 / Final 아트 높이 = 화면 30%(160~250), 중복 eyebrow 제거, 다시 들어오면 자물쇠로 스크롤, 자물쇠 아래 "Letter" 다시 보기 시트, 해결 배너 전환 AnimatedSize / Notebook 탭 라벨 잘림("EVIDENC") 수정, 표지 이름 축소 표시, 증거 그리드 = `evidenceGridDelegate`(고정 높이, Notebook·Archive·Final 공용), 순차 등장 최대 670ms / 미션 해결 화면 증거 타일 `evidenceTileHeight` / Case Closed 도장은 사진에 고정(이름과 겹침 해결), 이름은 한 줄 축소 / CONTINUE ADVENTURE·BEGIN INVESTIGATION·리포트 버튼 한 줄 고정(`singleLine`, glyph 지원 추가) / 시퀀스 Undo·Start again은 Wrap
- **Case Closed 행동 순서**: 다음 사건(OPEN CASE NN / CASE FILES)이 금색 주 버튼, VIEW MY DETECTIVE REPORT는 자물쇠 아이콘의 outline 보조 버튼
- **Motion**: easeOutBack·elasticOut 제거(Story Scene 해금 카드, Final 배너·뚜껑, Case Closed 종이·배지) → easeOutCubic. 모션 줄이기: 타자기 줄 즉시 표시, Case Closed 즉시 완성, 해금 카드 즉시
- **Game Master**: OutlinedButton 테마(잉크), 기기 초기화 버튼은 구분선 아래 tryAgain 색
- **Tests**: 374 → 381 (+`back_navigation_test` 3, `answer_feedback_test` 3, `small_screen_test` 1). 지도 CTA 변경으로 `GO TO …` 텍스트 탐색을 `find.bySemanticsLabel`로, 팁 라벨, Register 버튼 라벨 갱신. `ui_tour_test`: `LM_TOUR_SMALL=1`이면 360×640, 나가기 다이얼로그·선택 상태·자물쇠·다시하기 다이얼로그·Archive·운영자 게이트·Game Master 스크린샷 추가
- **유지**: 색 방향·폰트·아트·사건 파일 콘셉트, 게임 로직·데이터·정답·저장·라우팅 경로

### 2026-10-02 — 전체 UI 리디자인 "Victorian Casebook" (사용자 요청: "밤티 안 나게")

- **진단**: 색·폰트 방향(종이 + 네이비 + 세리프)은 맞았지만 ① 화면이 평평한 베이지 + 빈 공간에 요소가 떠 있음 ② 버튼·선택지가 기본 폼 컨트롤 같음 ③ 노트북·리포트·Case Closed·팁이 옛 스타일(흰 카드·굵은 금테·큰 라운드·컬러 원)이라 두 가지 디자인이 섞여 있었음 ④ 밤 화면의 클립아트 달 ⑤ 실제 그림(세피아 수채화)과 UI 톤 불일치
- **공통 시스템** (게임 로직·정답·저장·라우팅·텍스트 라벨 변경 없음):
  - `PaperBackground`: 종이 = 섬유 결 + 옅은 foxing + 램프 비네트. 밤 = 하늘 그라데이션 + 달빛 haze + 별 + **런던 스카이라인 실루엣**(불 켜진 창, 강 안개). 클립아트 달 제거. `skyline:` 옵션
  - `LondonSkyline`: 선화 → 밤 실루엣(`LondonSkylinePainter`, 빅벤·국회의사당·런던아이·타워브리지·세인트폴)
  - `GameButton`: 각인된 티켓 스타일 — 안쪽 hairline 테두리, 아래 3px 두께(눌리면 내려감, 크기 불변), 라벨 Cinzel. radius 12 → 8
  - `paper.dart` 추가: `RuledFrame`(문서 이중 테두리), `PaperSheet(ruled:)`, 밤 위 종이 그림자 `AppShadow.onNight`, `OrnamentRule`(◆ 장식선), `PageHeading`(eyebrow + 제목 + 장식선 + 부제), `BrassEmblem`(황동 메달 + 돋보기, 그려서 표현)
  - `InkStar`: 글자 ★ → 그린 별(기기마다 같은 모양)
  - 테마: 다이얼로그·FilledButton·TextButton·Switch·ListTile을 게임 색으로(Material 보라 제거)
  - 새 색: `nightTop/nightBottom/nightSkyline`, `leather/leatherDeep`
- **화면**:
  - Start: 밤 런던 타이틀 페이지(황동 엠블럼, THE CASEBOOK OF, 금색 CTA). 작은 화면/큰 글씨는 스크롤. 엠블럼 길게 누르기 = Game Master 그대로
  - Register: 탐정 ID 카드(이중 테두리 종이, 서명줄 입력)
  - Map: 헤더 `CASE 01` + 제목, 지도 아래 **NEXT LEAD** 줄(미션 번호·제목 + 장소별 진행 표시)로 빈 띠 제거. 지도 액자 그림자
  - Mission: `PageHeading`(MISSION 01 / 장소 / 미션 제목), 퍼즐 상단 `MISSION 01 · THE PUZZLE`
  - 퍼즐: 선택지 = 들린 카드 + 원형 글자 표시, 선택 시 네이비로 채움 / 숫자 암호 = 네이비·금 휠 / 키패드 = 타자기 키 / 시퀀스 번호도 원형 표시
  - 성공 오버레이: 푸른 램프 빛, 단서는 종이 쪽지, XP Cinzel / 오답 시트: 분홍 원 → 잉크 링 + 장식선
  - Story Scene: 해금 카드 = 이중 테두리 종이 카드
  - Notebook: 가죽 커버(금박 테두리·황동 엠블럼), 탭 = 잉크 밑줄(버건디), 단서 = 인덱스 카드, 증거 = 증거 태그(이중 테두리), 빈 칸 = 연필 윤곽, 확대 화면 = 종이 문서 + 금색 CLOSE
  - Badge: 평평한 원 → 가리비 테두리 황동 로제트(미획득 = 연필 윤곽)
  - Final: 앱바까지 밤 배경(위쪽 종이 띠 제거), THE FINAL CASE + 장식선, 자물쇠 = 황동 판
  - Case Closed·Parent Report: 흰 카드 → 종이 문서/네이비 커버 + 이중 테두리
  - 단어 카드·토스트: 같은 버튼/테두리 언어
- **유지**: 모든 버튼·탭 라벨 텍스트, 키, 툴팁, Semantics, 지도 카메라 규칙(뷰포트 비율·핀 위치), 애니메이션 타이밍
- **Tests**: 373 → 374 (+`test/ui_tour_test.dart`: Episode 01 전체 플레이를 하며 화면마다 PNG 저장. `LM_TOUR=<폴더> flutter test test/ui_tour_test.dart`, 변수가 없으면 일반 플레이스루로만 동작). `flutter analyze` 0 issues, `flutter test` 374 통과, 360×640 전 사건 화면 렌더(`season_screens_test`) 통과
- **남은 것**: 실기기 확인 안 함(폰트 렌더·그림자 성능·스카이라인 크기), Royal Box 상자 그림은 코드 그림 그대로, QR 스캐너·Game Master 화면은 손대지 않음, Fredoka 등록 정리 미완

### 2026-10-01 — Season 1 Art Asset Integration (characters / objects / symbols / special)

- 새 에셋 10장(전부 양피지 배경의 컬러 그림, 투명 아님): `assets/art/characters/`(raven_master, clockmaker_master), `objects/`(crown, key, letter, map, pocket_watch, suitcase), `symbols/raven_mark.png`, `special/royal_box.png`. pubspec에 4개 폴더 등록
- 레지스트리(`ArtAssets`, 기존 구조 확장): `characters`, `objects`, `ravenMark`, `special`, `objectScenes`(Artwork.raven → raven_master, Artwork.oldSuitcase → suitcase), `sceneAspects`/`sceneAspect()`(그림별 실제 비율 — 내부 장소 8장도 이제 실제 비율), `evidencePictures`(증거 id → 그림). 컬러 그림은 색을 입히는 1색 `symbols` 슬롯에 넣지 않음
- 적용:
  - 까마귀 장면 5곳(Case 05 M3, Case 10 M1·M2·Final, Case 12 M3: 모두 Tower 까마귀 Poppy) → raven_master
  - 여행 가방: Case 01 M1("mysterious suitcase"), Case 04 M1("old brown suitcase") → suitcase (`PlaceArt.missionScenes` → `Artwork.oldSuitcase`, 없으면 기존 가방 코드 그림). Case 08 M1·M3은 "black suitcase"라 갈색 그림과 맞지 않아 코드 그림 유지. 다른 suitcase 장면(엽서 소인·마지막 기차·Platform 9 가면)은 가방이 주제가 아니라 유지
  - 증거(노트북 타일·확대·축하 칩, `_EvidenceArt`의 둥근 종이 틀 안 `cover` — 물건이 정사각형 가운데 있어 잘리는 건 빈 양피지뿐): e01 Old Letter·ep10_e3 Ravenmaster's Letter → letter, e02 Golden Key·ep05_e3 Brass Key → key, e06 The Missing Crown → crown, ep04_e1 Black Wax Seal("A raven is pressed into the wax") → raven_mark, ep12_e4 The Clockmaker's Watch → pocket_watch. 읽는 동안·실패 시 기존 기호
  - 미션 화면의 정사각형 그림은 최대 폭 240dp(본문이 첫 화면에 보이도록)
- **일부러 적용하지 않음(그림과 게임 내용이 어긋남)**:
  - royal_box.png = 극장 귀빈석 그림 / 게임의 Royal Box = "a heavy golden box", 왕관이 든 상자(열리는 애니메이션) → 등록만, `RoyalBoxAnimation` 유지
  - Case 01 Pocket Watch("stopped at 7 o'clock") / London Map("Two swans") — Royal Box 암호 7924의 숫자 단서인데 그림은 10시 10분·돛단배 → 기호 유지
  - Case 04 The Secret Letter(검은 봉랍) ↔ letter.png(빨간 봉랍), Case 05·07 지도 조각/Old London Map(그려진 까마귀 단서) ↔ map.png(까마귀 없음) → 기호 유지. map.png는 현재 사용처 없음
  - clockmaker_master: 시즌 내내 직접 등장하지 않음(Case 12도 "The Clockmaker is gone"), 기존 자리 표시·실루엣 없음 → 등록만
  - letter.png를 편지 읽기 종이 배경으로: 그림의 소인·봉랍 위로 본문이 겹치고 편지 길이가 제각각 → 기존 종이 유지
- 테스트 370 → 373: 캐릭터·오브젝트·마크·스페셜 경로, 증거 그림 대응표 + "7시 시계·두 마리 백조 지도는 제외" 근거 검사, 증거 타일이 그림/기호를 보여줌, 기존 매핑 테스트를 19개 장면 + 그림별 비율로 갱신, Case 08 가방·Royal Box는 코드 그림
- QA: 360×640 전 사건 화면 레이아웃 검사 + 스크린샷(King's Cross 가방, Tower Green 까마귀, Case 10 Final), 360·390 노트북 증거 그리드·확대(Case 01·04·05·10·12). 에뮬레이터 실기는 안 함

### 2026-10-01 — 카메라 이동 빨간 점선 (사용자 요청)

- 현재 장소로 가는 길(해결한 마지막 장소 → 현재 장소)을 남색 점선 → **빨간(`AppColors.burgundy`) 점선**으로. 지도 위에서도 읽히도록 얇은 종이색 외곽선 위에 그림(`LondonMapPainter._heading`). 지나온 길은 기존 남색 실선
- 카메라가 다음 장소로 이동할 때(미션을 풀고 돌아온 직후, 또는 지도가 열린 채 풀었을 때) **점선이 카메라 팬과 같은 곡선으로 점점 그려지고**, 그리는 동안 펜 끝에 작은 빨간 점. 이동이 없으면 처음부터 끝까지 그려져 있음. 구현: `LondonMapPainter.heading`(`Animation<double>`, `super(repaint:)`) ← `_MapViewport._heading` = `CurvedAnimation(_pan, panCurve)` → world builder `(size, heading)`. 경로 레이어는 자체 `RepaintBoundary`라 점선이 자랄 때 지도 그림은 다시 그리지 않음
- `map_camera_test`: 이동 중 점선 0~1 사이, 도착하면 1, 이동 없음이면 1
- 사용자가 `_MapViewport.arrivingAt`을 0.7 → **0.5**로 조정(페이드 아웃 600~1000ms, 줌은 1200ms까지 → 지도가 사라진 뒤 줌 마지막 200ms는 보이지 않고 미션이 약 1.4초에 열림). `place_arrival_test` Great Court 시나리오를 고정 타이밍 대신 20ms 프레임 기록으로 순서만 검사하도록 변경(줌 먼저 → 줌 중 페이드 시작 → 빈 가장자리 없음 → 핀 끝으로 접근(3배 도달 시 정중앙) → 지도가 사라진 뒤 미션) — 이 값을 다시 조정해도 테스트가 깨지지 않음

### 2026-10-01 — GO TO: 줌과 페이드 아웃 겹치기 (사용자 피드백: "딱딱하다")

- 줌이 끝난 뒤 페이드 아웃하던 것을 **줌 70% 지점(약 840ms)부터 페이드 아웃 시작**으로 변경: `_MapViewport.arrivingAt = 0.7`에서 `onArriving`(이전 `onZoomedIn`) 1회 호출 → 지도 페이드 아웃 400ms easeInOut(이전 300ms easeIn)이 줌 마지막 360ms와 겹침 → 페이드가 끝나면(약 1240ms) 미션 push → 380ms 페이드 인. 총 약 1.6초(이전 1.9초)
- `place_arrival_test` Great Court 시나리오: 줌 50%에는 불투명, 줌 진행 중(아직 3배 미만)에 이미 페이드 아웃 중, 줌 끝에는 절반 이상 사라짐, 완전히 사라진 뒤 미션 push

### 2026-10-01 — GO TO: 핀 끝까지 줌인 → 지도 페이드 아웃 → 미션 페이드 인 (사용자 피드백)

- 줌: 1.25배/1000ms → **3배/1200ms**, 핀 끝(장소 좌표)을 뷰포트 정중앙에(`MapCamera.zoomed`, focusDrop 0, clamp 유지). 핀·YOU'RE HERE도 world와 함께 커짐
- 줌이 끝나면 지도 화면 전체(헤더·지도·버튼)가 300ms easeIn으로 종이색(`AppColors.paper`) 배경으로 **페이드 아웃**(`_leave`, 키 `map-page`) → 그다음 미션 페이지 push(기존 380ms **페이드 인**). 총 약 1.9초. 미션에서 돌아오면 줌·불투명도 원상태
- `place_arrival_test` 갱신(테스트 수 그대로): 3배·핀 끝이 중앙에서 1px 이내·clamp, 줌 중에는 지도 불투명, 페이드 아웃 중에는 아직 지도 페이지, 완전히 사라진 뒤 미션 push → 페이드 인, 돌아오면 지도 불투명도 1

### 2026-10-01 — GO TO: 줌 후 바로 미션 페이지로 (사용자 피드백)

- 사용자 요청: "랜드마크를 한 번 보여주고 Investigate 페이지로" → **줌이 끝나면 곧바로 Investigate 페이지가 페이드 인**. 아래 항목의 `_PlaceArrival`(장소 그림 + 이름 + hold 800ms)을 제거. 흐름: GO TO → 카메라 줌 1.0→1.25(1000ms) → 미션 페이지 push(기존 `_fade` 380ms 페이드)로 확대된 지도 위에 페이드 인. 총 약 1.4초
- 이동 중 보호는 그대로: `PopScope` 뒤로가기 차단, `AbsorbPointer`로 지도 전체 탭 차단(핀·메뉴·노트북), GO TO·메뉴 비활성, push 정확히 1회, 돌아오면 줌 원상태
- 장소 PNG는 계속 쓰임: 미션 페이지 장면(`PlaceArt.sceneOf`), NEW PLACE UNLOCKED 카드(`PlaceArt.placeOf`)
- 테스트 수 그대로(370): `place_arrival_test`를 새 흐름으로 다시 씀 — 즉시 이동 안 함 → 점진 줌 → 1.25배·중앙·clamp → 줌 끝난 다음 프레임에 미션 push(중간 페이지 없음) → 페이드 중 → 미션 페이지에 장소 PNG / 연속 탭 1회 / 이동 중 뒤로가기 무시 / 7개 장소(미션 페이지 장면 확인) / 360·390 줌 중 빈 가장자리 없음
- 작업 중 실수와 복구: 도착 화면 클래스를 지우면서 뒤의 `_MapViewport`·`_MapWorldView`·`_NotebookButton`까지 지워짐 → HEAD(`548d71f`)에서 복원하고 줌 변경만 다시 적용. HEAD 대비 diff로 의도한 변경만 남았음을 확인

### 2026-10-01 — Landmark Artwork Integration + Location Transition (GO TO)

- **Asset 구조**: `assets/art/scenes/landmarks/`(9개 랜드마크) + 랜드마크별 폴더 `british_museum/`(great_court, egypt_room), `hyde_park/`(boathouse, rose_garden), `buckingham_palace/`(palace_staff_room, palace_courtyard), `covent_garden/`(dressing_room), `kings_cross/`(waiting_hall). 파일명 변경 없음. Flutter asset 폴더는 하위 폴더를 포함하지 않으므로 pubspec에 6개 폴더를 각각 등록(이전 `assets/art/scenes/` 1줄 대체)
- **중앙 매핑**: `ArtAssets.landmarkScenes`(9) + `ArtAssets.insideScenes`(8) → `ArtAssets.scenes`(17). 내부 장소 PNG는 약 1270×830이라 화면 크기로 디코딩(`cacheWidth`, 원본보다 크게는 안 함). `Artwork`에 `egyptRoom`·`greatCourt` 추가(표시용 키, 데이터 아님). 코드 그림 fallback: 내부 장소는 각 랜드마크 코드 그림(`LandmarkArt.standIns`, Dressing Room은 Theatre), 파일이 없을 때만
- **장소 선택 단일 지점**: `lib/widgets/place_art.dart` `PlaceArt` — `sceneOf(m)`: 미션 화면 장면(퍼즐 장면은 유지, Egypt Room·Great Court만 `missionScenes` 대응표로 내부 장소 — 미션 데이터의 `scene`은 그대로), `placeOf(m)`: 도착 장소(내부 장소 → 그 PNG, 아니면 `MapWorld.missionLandmarks`의 랜드마크 PNG — 예: Case 01 King's Cross는 suitcase가 아니라 kings_cross.png). `Landmark.artwork` 추가(좌표 변경 없음). NEW PLACE UNLOCKED 카드는 `placeOf(next)`
- **GO TO 전환**(`mission_map_screen.dart`): GO TO(또는 현재 핀) → `_goTo` → ① 카메라 줌 1.0→1.25, 1000ms easeInOutCubic(`_MapViewport.travelZoom/zoomDuration`): `MapCamera.zoomed(1.25)`로 장소를 정중앙(focusDrop 0) 쪽으로, 같은 clamp라 매 프레임 세계가 뷰포트를 덮음(지도 가장자리 장소 포함). 기존 950ms 팬과 독립(`Matrix4` 한 번에 합성) ② `_PlaceArrival`: 양피지 페이지 위 장소 PNG(PaperSheet, contain) + 장소 이름(이미지에 글자 추가 없음), 360ms fade + 0.96→1 settle, 440ms hold — 줌 시작 때 투명하게 미리 빌드해 PNG를 디코딩 ③ `context.push` 1회 → 기존 미션 화면(기존 380ms 페이드). 총 약 1.8초 + 페이지 전환. glow/bounce/shake 없음
- 보호: 이동 중 GO TO·메뉴 비활성, 도착 화면이 모든 탭 흡수, `PopScope`로 뒤로가기 차단, `_goTo` 중복 무시, 도착 후 push는 정확히 1회. 미션에서 뒤로 오면 지도 원상태(줌 0, 도착 화면 없음, GO TO 활성)
- 테스트 357 → 370: `place_arrival_test`(Great Court 대표 시나리오: 즉시 이동 안 함 → 점진 줌 → 1.25배·중앙·clamp → 이름과 함께 등장 → hold → 미션 1회, 해결 기록 변화 없음 / 연속 탭 → 미션 1개만 / 이동 중 뒤로가기 무시 / King's Cross·Egypt Room·Boathouse·Waiting Room·Courtyard·Dressing Room·Tower Bridge(Final) 각각 올바른 PNG / 360×640·390×844 도착 화면이 화면 안·비율 유지·이름이 그림 아래), `art_assets_test` 17개 매핑·폴더 규칙·번들 존재·장소 선택 규칙. 기존 플레이 테스트의 GO TO 대기 1500ms → `goToTime` 2800ms(검사 내용 동일)
- QA: 360×640·390×844 프레임별 스크린샷(지도 → 줌 → 겹쳐 등장 → 장소 → 미션). 발견·수정: 도착 화면이 Scaffold 밖이라 글자에 노란 밑줄(Material 없음 경고) → `Material` 배경으로 수정 + 테스트. 에뮬레이터 실기는 안 함

### 2026-10-01 — 9개 Landmark PNG artwork replacement

- 역할 분리: `assets/images/london_mystery.png` = 지도 세계(Map Camera, Flutter 핀/라벨 오버레이 — 변경 없음), `assets/art/scenes/*.png` 9장 = 미션·스토리에서 장소를 보여주는 삽화. 지도에는 장면 PNG를 넣지 않음
- 중앙 매핑: `ArtAssets.scenes`(Artwork → PNG, 9개 고정: kingsCross·britishMuseum·coventGarden·bigBen·hydePark·buckinghamPalace·towerBridge·towerOfLondon·londonEye) + `LandmarkArt`(모든 장면 표시의 단일 위젯). 화면은 `Artwork`만 넘기고 `Image.asset`을 직접 쓰지 않음. 지도의 `Landmark` 9곳과 같은 장소 집합(테스트로 확인)
- 표시: PNG를 **자르지 않고** `BoxFit.contain`으로 종이 테두리·이름표까지 전체 표시. 프레임이 PNG 비율을 따름(`LandmarkArt.aspectOf` / `hasPicture`) — 미션·Final 장면(이전 4:3 → 400:256), NEW PLACE UNLOCKED 카드(72×72 → 112×72), Case Solved 사진(96×96 → 144×96). 코드 그림인 장소는 이전 크기 그대로. 필터·그라데이션·그림자 추가 없음
- 예외 1곳: 이미지 선택 퀴즈 타일은 이름표를 계속 숨김(`showName: false`, 이름표 위쪽만 cover로 표시) — 이름표가 정답을 글자로 알려주기 때문(정답 무결성 우선)
- **세부 장소는 랜드마크 PNG를 빌리지 않음**(이전 기록의 "stand-in 장소는 stand-in의 그림 사용"을 되돌림): Boathouse·Rose Garden(Hyde Park 코드 그림), Waiting Room(King's Cross 코드 그림), Staff Room·Courtyard(Buckingham Palace 코드 그림), Dressing Room(Theatre 코드 그림). 전용 PNG를 `ArtAssets.scenes`에 추가하면 그 장소만 바뀜. 다음 단계 권장 순서: Boathouse → Rose Garden → Staff Room → Courtyard → Dressing Room → Waiting Room
- 그대로 둔 비-랜드마크 artwork: Royal Box·Clock Face·Gallery·Locked Door·Raven·Jewel Case·Suitcase·Theatre·Park Map A~D(코드 그림), 단서 도장 기호(`train`·`clock`은 잉크 glyph, `museum`·`palace`·`park`는 monogram) — 단서 기호는 Case 01 Royal Box 다이얼 퍼즐의 정답 기호와 같아야 하므로 교체하지 않음(전용 1색 기호 PNG는 `ArtAssets.symbols` 슬롯)
- fallback 유지: PNG가 없거나 깨지면 `LandmarkArt.drawing`(기존 CustomPainter). 새 named constructor `LandmarkArt.drawing`은 fallback과 테스트에 사용
- 테스트 354 → 357: 9개 매핑 경로 고정·9개만 그림 보유, 9개 PNG가 번들에 있음, PNG는 `BoxFit.contain` + PNG 비율 프레임, 세부 장소·Royal Box·Raven·Clock Face는 그림 없이 코드 그림·4:3 유지. 기존 "stand-in 장면과 똑같이 보임"은 "stand-in의 **코드 그림**과 똑같이 보임 + 랜드마크 PNG를 빌리지 않음"으로(stand-in 랜드마크가 PNG를 갖게 되어 비교 대상을 명시)
- QA: 360×640 전 사건 화면 렌더(레이아웃 검사 173개), 390×844 미션 장면·NEW PLACE UNLOCKED 카드·Case Solved(Case 01 Royal Box / Case 07 Hyde Park) 스크린샷. Map 테스트 72개 그대로 통과(지도 코드 변경 없음). 에뮬레이터 실기 확인은 안 함

### 2026-10-01 — Operator Full Case Access

- 기존 구조 재사용: Game Master(부모 게이트 + 라우터 가드 `gameMasterAccessProvider`) → 플레이 테스트 도구(`playtestToolsEnabled`)에 스위치 추가. 새 인증·환경변수·dependency·저장 형식 없음
- 정책은 한 곳: `SeasonNotifier.isUnlocked` 안에서 `operatorAccessProvider`가 켜져 있으면 모든 사건 허용. Case Files, `/episodes?case=` 직접 링크, `GameController.openEpisode`(실제 열기 가드), Case Archive(SEALED 표시)가 모두 이 함수를 씀. 사건 안의 미션 순서(`GameProgress.isUnlocked`)·라우터의 미션/결과 가드는 그대로
- 상태 분리: 접근 ≠ 해결 ≠ XP ≠ 배지 ≠ 증거. 사건을 열면 그 사건의 실제 세이브(없으면 새 세이브)를 불러올 뿐, 해결·XP·배지·증거를 저장하는 코드는 지나지 않음. Archive는 해결하지 않은 사건에 실제로 모은 증거만 표시
- Release Safety(3중): `operatorToolsInBuild = kDebugMode || bool.fromEnvironment('LM_PLAYTEST')` 컴파일 상수(`playtestToolsEnabled`도 이 값) → `operatorToolsAvailableProvider` → 스위치 `set()`이 거부 + `operatorAccessProvider`가 AND. 일반 release 빌드에서는 UI가 없고, 켜는 방법도 없고, 정책도 무시함
- 파일: `features/game/game_providers.dart`(정책·provider), `features/game_master/playtest_tools.dart`(상수 공유), `game_master_screen.dart`(스위치), `onboarding/episode_select_screen.dart`(도장·재빌드), `notebook/season_archive.dart`(재빌드)
- 테스트 339 → 352: `operator_access_test`(일반 사용자 순차 해금·컨트롤러 거부, Case 01~12 전체 접근, Case 08 열기로 해결·XP·배지·증거·다른 세이브 변화 없음, 사건 안 미션 순서 유지, 스위치 끄면 원래 규칙, 운영 도구 없는 빌드에서 켤 수 없음, Case 07/08/12 링크 → 인트로, 일반 사용자 링크는 잠긴 사건 선택 안 됨, 스위치는 부모 게이트 뒤에만)
- 실제 QA(위젯 렌더 스크린샷): 새 기기에서 Operator Mode → Case Files 12개 모두 열림 + `OPERATOR MODE` 도장, Case 01·02·07·08·12 인트로 진입. 에뮬레이터 실기는 안 함

### 2026-10-01 — Mission Map Camera

- 지도 artwork가 clean 버전으로 교체됨(인쇄된 핀·장소명·타이틀 없음, 같은 경로·1536×1024) → 장소명은 앱이 씀. 이전 기록의 "artwork 핀과 Flutter 핀 중복" 문제는 해소
- 3:2 지도판(`_MapBoard`, 전체 표시)을 **Map Camera**로 교체: 세로 뷰포트(`_MapViewport`, 높이 = min(남은 높이, 폭×1.25), 헤더와 버튼 사이 가운데) 안에 3:2 map world(뷰포트를 덮는 크기 × zoom 1.2)를 두고, world 전체(artwork·경로·랜드마크 이름·핀·YOU'RE HERE)를 `Transform.translate`로 이동. 360×640: 뷰포트 328×410, 390×844: 358×448
- `MapCamera`(`map_camera.dart`, 순수 계산): 정규화 좌표 → world px, 장소를 뷰포트 중앙(아래로 20dp, YOU'RE HERE 자리)에 두는 offset, world가 빈 공간을 드러내지 않게 clamp, world가 뷰포트보다 작은 축은 가운데 정렬
- 애니메이션: 첫 진입은 현재 장소에 바로 표시. 미션을 풀고 돌아오면(`recentUnlockProvider` = 현재 미션) 방금 푼 장소에서 시작해 950ms(앞 20% 대기 + easeInOutCubic)로 새 장소까지 이동 — 핀의 해금 도장과 타이밍이 맞음. 지도가 열린 채 현재 장소가 바뀌어도 같은 방식으로 이동, 같은 장소면 움직이지 않음. 사용자 드래그·줌 없음
- **시각 좌표와 진행 좌표 분리**(`map_world.dart`): `Landmark` 9곳(artwork 위 실제 위치) + 미션 → 랜드마크 표. 진행용 `mapX/mapY`는 그대로 두고, 같은 랜드마크를 쓰는 미션들은 랜드마크 주변 반경 0.12 무리로 배치(무리 모양 = `mapX/mapY` 배치). 위쪽 끝 무리는 모양을 유지한 채 아래로(`topMargin` 0.15). 에피소드 데이터 구조 변경 없음
- **잠긴 장소는 지도에 표시하지 않음**(사용자 결정): 핀이 실제 랜드마크에 있으면 잠긴 핀 위치가 이전 퀴즈 정답(다음 장소)을 알려주기 때문. 잠긴 미션 URL 차단은 라우터 가드 그대로. 현재 장소의 랜드마크 이름은 숨김(핀이 자기 이름을 표시), 현재 핀은 맨 위에 그림
- 성능: world는 게임 상태가 바뀔 때만 빌드(`AnimatedBuilder` child + `RepaintBoundary`), artwork는 world 폭 × dpr(최대 원본 1536px)로 한 번 디코딩, 이동 중 재디코딩 없음
- `MapLettering`(지도 글씨)을 `map_pin.dart`에서 공개해 랜드마크 이름에도 사용. `ArtAssets.londonMapPixels` 추가
- 테스트 326 → 339: `map_camera_test`(camera math 7, map world 3, 진입·복귀 이동·열린 상태 이동 3). `season_screens_test` 지도 검사 72개를 카메라 기준으로 다시 씀(뷰포트 비율·크기, world 3:2·빈 공간 없음, 카메라 = 현재 장소, 핀 = world 위치, 잠긴 핀 없음, YOU'RE HERE가 보임, 버튼이 지도 아래 고정). `full_playthrough_test`의 "잠긴 핀 탭 → Locked! 안내"는 "잠긴 핀이 지도에 없음 + 랜드마크 이름 표시"로 변경(잠긴 핀 숨김 결정에 따름)
- 남은 문제: (1) King's Cross·Tower Bridge처럼 지도 가장자리 랜드마크는 카메라가 끝에서 멈춰 정중앙에 오지 않음(빈 공간을 드러내지 않기 위한 clamp). (2) ~~Case 08 중간 등 King's Cross 무리에서 해결한 장소 표시가 현재 장소의 YOU'RE HERE 글자에 살짝 걸림~~ → 2026-10-01 수정: 현재 핀이 차지하는 영역(`MapPin.currentMarks`: 메모·핀·장소명)에 해결한 체크 표시가 겹치면, 그리기 위치만 가장 가까운 빈 자리(지도 안)로 옮김(`_MapWorldView.clearOf`). 경로선은 옮긴 표시까지 이어짐. 장소 좌표·현재 핀·카메라는 그대로. Case 08 중간은 체크가 메모 위로, Case 07 중간은 체크가 이름 옆으로 몇 dp 이동. `season_screens_test`에 렌더링 영역 기준 겹침 검사 추가(수정을 끄면 Case 08 두 크기에서 실패함을 확인). (3) world가 원본보다 커서(390폭 기준 약 2400px 필요, 원본 1536px) 약 1.5배 확대 — 약간 부드러움. 2400px 이상 원본이면 선명. (4) 에뮬레이터 실기 확인 안 함(위젯 테스트 렌더 + 스크린샷으로 확인)

### 2026-09-30 — Landmark 장면 그림 적용

- 랜드마크 9장(약 400×256, 종이 테두리 + 하단 이름표 인쇄)을 `assets/art/scenes/<key>.png`로 옮기고(원래 `assets/images/`에 공백 포함 이름) `ArtAssets.scenes`에 연결: kingsCross, britishMuseum, bigBen, hydePark, buckinghamPalace, towerBridge, londonEye, towerOfLondon, coventGarden
- `ArtAssets.scenePrint`(frame 4.5%, nameTop 68%): 앱이 이미 액자를 두므로 인쇄된 테두리를 모든 곳에서 잘라냄. `LandmarkArt(showName: false)`는 이름표도 잘라냄 → 이미지 선택 퀴즈 타일(정답 노출 방지), 스토리 72dp 썸네일, Case Solved 96dp 사진. 미션·Final 4:3 장면은 이름표 표시
- stand-in 장소(boathouse/roseGarden → Hyde Park, waitingRoom → King's Cross, staffRoom/courtyard → Buckingham Palace)는 전용 그림이 생길 때까지 stand-in의 그림을 사용. 파일이 없거나 깨지면 코드 드로잉으로 대체
- 테스트 325 → 326: 이미지 선택 미션의 장면 그림 ≠ 정답 그림(장면 이름표가 정답을 말하지 않음), 이미지 선택 타일은 항상 `showName: false`
- 남은 문제: 원본 해상도가 약 400px라 4:3 미션 장면(3x 기기 기준 약 930px)에서 2배 이상 확대돼 약간 흐림. 800px 이상 원본을 권장. 이미지 선택 타일(거의 정사각)에서는 가운데만 보여서 Tower Bridge는 탑 하나와 보행교만 보임

### 2026-09-30 — Mission Map Landscape Board

- 지도 artwork(`assets/images/london_mystery.png`, 1536×1024)를 pubspec에 등록하고 `ArtAssets.londonMap` / `londonMapAspect`(3:2)로 연결. 파일이 없거나 깨지면 `LondonMapPainter` 지도로 대체
- Mission Map의 지도 영역을 3:2 지도판(`_MapBoard`: parchment 5dp 프레임 + 옅은 잉크 테두리 + `AppShadow.paperLift`, `AspectRatio`)으로 변경. 폭 = 화면 폭 − 16×2(360 → 328×219, 390 → 358×239). `BoxFit.contain`으로 잘림 없음. 헤더 아래 배치(위 40dp는 상단 핀의 YOU'RE HERE 자리), 남는 높이는 버튼 위로
- `LondonMapPainter(drawMap: false)`: artwork 위에는 수사 경로만 그림
- 핀: 정규화 좌표(`mapX*w`, `mapY*h`)에 핀 끝을 정확히 둠. 예전의 세로 clamp(핀 박스를 지도 안에 가두면서 위치가 밀림) 제거. 가로 clamp는 화면 여백(16dp)까지만 적용
- 지도 가로 스크롤·줌·드래그 없음(원래 코드에도 없었음). 게임 로직·좌표 데이터·저장 구조 변경 없음
- 테스트 253 → 325: `season_screens_test`에 지도 검사 72개 추가(12개 사건 × 시작/중간/완료 × 360×640·390×844). 3:2 비율, artwork 크기 = 지도판 크기, 핀 끝 위치, 버튼이 지도 아래 화면 안에 있는지, overflow 없음을 확인
- **남은 문제**: artwork에 인쇄된 빨간 핀·장소 이름과 Flutter 핀이 서로 다른 위치에 함께 보임. `mapX/mapY`는 artwork 이전의 배치값이고 Ep02~12는 한 장소 안의 세부 위치(Gallery 8 등)라 artwork의 랜드마크와 대응하지 않음. 핀·라벨이 없는 clean artwork로 교체하거나 좌표를 artwork에 맞춰 다시 정해야 함

### 2026-09-29 — Phase 4: Playtest Preparation & Visual Polish

- P2: Case 02 시계가 해결과 함께 9:17로, 비활성 `InkTextButton` 회색, OPEN CASE NN → `/episodes?case=` (열림·선택·스크롤)
- 새로 찾은 P2: Case Files 지연 생성 목록이 먼 사건으로 스크롤 안 됨(에뮬레이터 발견), 밤 배경 달이 SKIP과 겹침
- Game Master 플레이 테스트 도구(`LM_PLAYTEST`/debug 전용): `CASE NN부터`, `지금 사건 처음부터`
- `docs/playtest/SEASON1_PLAYTEST_CHECKLIST.md`, `docs/art/VISUAL_ASSET_INVENTORY.md`
- `ArtAssets` 교체 구조 + `Artwork` 장소 키 6개(stand-in으로 그림 동일). 새 dependency 없음
- 테스트 236 → 253, 상세는 *Phase 4*

### 2026-09-29 — Season 1 QA + Case Archive + OPEN MY NOTEBOOK

- Notebook에 CASE ARCHIVE (새 저장 키 없음), Final 시트 → Archive 링크, `/notebook?view=archive`
- 공통 `GameButton.outline` 밤 배경 가독성 (`InkSurface`), `EvidenceTile` 소형 화면 대응, 단어 입력 빈칸 수 유지, 마지막 사건 CASE FILES 버튼, Case Files SOLVED 도장 시즌 기준
- 콘텐츠 최소 수정: Case 03 M2 story, Case 07 M1 증거 이름, Case 08 Final 편지(정답 노출 제거)·힌트, Case 09 Final·Case 12 M3 빈칸 수, Case 11·12 힌트 → Archive, Case 12 M2 힌트 표현. 정답·순서·범인·결말 변경 없음
- 테스트 116 → 236, 상세는 *Season 1 QA*

### 2026-09-29 — Season 1 (Case 02~12)

- 멀티 케이스 구조: `SeasonProgress`(`lm.season.v1`), 사건별 세이브 키, `seasonProvider`/`episodeCatalogProvider`, `GameController.openEpisode`(잠금 검사), Case Files를 카탈로그 기반 아코디언으로(SEALED/SOLVED 도장, "Solve Case NN to open this file."), 지도 메뉴에 "Case files", Case Solved에 시즌 훅 + "OPEN CASE NN"
- 콘텐츠: `lib/data/mock/season1/episode02~12_mock.dart` (사건당 3+1 미션, 증거 4개, 시즌 스토리 줄기)
- 새 퍼즐 타입 `sequence` + `SequenceQuestion` 위젯, Final Case가 모든 퍼즐 타입 지원(`Mission.finale`), 비-Royal Box 사건은 장면 그림 + 사건별 성공 문구
- 사건 배지 6개(사건별 스코프), 리포트 문구/핵심 단어/사진을 사건 데이터에서 가져옴 (Episode 01은 기존 문구 fallback)
- 새 LandmarkArt 장면 12개, 새 InkGlyph 18개 (Case 01의 clock/key/watch/map/train 심볼도 모노그램 → 잉크 그림으로 바뀜 — 시각 변경만, 데이터 동일)
- 테스트 43 → 116: `season_content_test`(전 사건 콘텐츠 규칙), `season_flow_test`(잠금 사슬·중복 지급 없음·Ep01 불변·재시작 복구·구세이브 마이그레이션·Play again/Reset), `season_playthrough_test`(Case 01 구세이브 → Case 02 UI 전체 → Case 03 해금). 기존 테스트는 "모든 배지 = Episode 01 배지" 가정 3곳만 명시적으로 수정
- 에뮬레이터 실기 확인 중 발견·수정: Case Solved의 outline 버튼이 밤 배경에서 보이지 않음 → 잉크 링크로 교체. Case 02 인트로가 Mission 1 정답(8:17)을 미리 말함 → 인트로 수정 + 재발 방지 테스트 추가. Case 03/07 Final 장면 그림이 정답 그림과 같음 → 교체 + 테스트 추가

### 2026-09-28

- Phase 1 MVP completed (이전 세션)
- Phase 2 game experience features implemented (이전 세션)
- 새 세션에서 인수인계 분석 수행: 소스 전수 확인, `flutter analyze` 0 issues, `flutter test` 28/28 통과
- PROJECT_CONTEXT.md created (코드 수정 없음)

### 2026-09-28 — Phase 3 Step 3.2 (2차 실기기 피드백)

- Case Files 기본 접힘. 지도 현재 위치 표시를 작은 잉크 요소로 정리(카드·배지 형태 제거). 봉투를 오래된 사건 편지 소품처럼 다시 그리고, 오픈 애니메이션을 봉랍 → 덮개 → 꺼내기 → 펼치기 → 글씨 순서의 물리적 동작으로 재설계
- `flutter analyze` 0 issues, 테스트 43개 통과 (테스트 수정 없음)

### 2026-09-28 — Phase 3 Step 3.1 (실기기 피드백)

- Case Files를 Case → Episode 아코디언으로 변경하고 CTA를 하단에 고정. 지도에 YOU'RE HERE 추가, GO TO 버튼 고정 크기, 편지 종이와 오픈 애니메이션 재설계, Well Done 정보량 축소
- 새 공통 요소: `CaseFolder`, `InkGlyph.pin` / `InkGlyph.down`, `GameButton.singleLine`
- 테스트 문구만 갱신 (Case Files 선택 단계, `WELL DONE`, `New clue`, `New badge:`, `YOU'RE HERE`). 게임 로직 검증은 그대로
- `flutter analyze` 0 issues, 테스트 43개 통과

### 2026-09-28 — Phase 3 Step 0 + 핵심 3개 화면

- Visual Direction "Vintage London Detective Storybook" 승인 후 구현
- Design System(색·폰트·토큰·공통 컴포넌트·AppTheme) 적용, Libre Baskerville 폰트 추가(OFL)
- Start / Mission Map / Mission(문제 5종 포함) 리디자인. 게임 로직·데이터 모델·라우팅·저장은 변경 없음
- 버튼 문구 변경에 맞춰 위젯 테스트의 문구만 수정 (`PLAY MISSION 0X` → `GO TO {장소}`, `NOTES` → notebook tooltip, 진행 표시 `n / 5` → CTA 문구, `UNLOCKED!` → `UNLOCKED`, `NEED A TIP?` → `Need a tip?`). 게임 로직 검증은 그대로 유지
- 리디자인 중 발견해 수정: "TAP TO OPEN" 라벨이 탭 영역 밖에 있던 문제, 긴 링크 문구 오버플로우
- `flutter analyze` 0 issues, 테스트 43개 통과

### 2026-09-28 — Phase 2 안정화

- **플레이 시간**: 벽시계 → 활성 플레이 시간. `GameProgress.playMillis`, `missionStartPlayMillis` 추가. `GameController`에 플레이 시계(`playTime`, `pausePlayClock`, `resumePlayClock`, 저장할 때마다 구간 누적) 추가. `app.dart`에 `AppLifecycleListener` 연결. 지도 타이머는 실시간 값 사용. 이전 저장 데이터 호환 처리
- **Parent Gate**: 다이얼로그 닫힘 애니메이션 중 disposed controller 사용 오류를 재현·수정 (controller를 `_ParentGateDialog` State가 소유). UI 변경 없음
- **보호자 리포트**: Parent Gate 통과 시에만 열리는 1회용 통과권(`parentReportAccessProvider`)과 라우터 가드 추가. 브라우저 이동으로 우회되는 경로를 발견해 redirect에서 회수하도록 함
- 테스트 28 → 41개 (플레이 시간 Case A~D·스피드 보너스·해결 후 정지·이전 데이터, lifecycle 위젯 테스트, Parent Gate 3개 경로, 보호자 리포트 우회 시나리오). `flutter analyze` 0 issues
- 이후 UI 버그 수정 (별도 커밋 `fix: unify badge size and fix try-again sheet overflow`):
  - `BadgeMedal`: 제목과 설명이 항상 2줄 높이를 차지하게 해서 모든 배지 크기를 통일
  - 오답 "Not quite!" 시트: `isScrollControlled` + 스크롤로 바꿔 작은 화면에서 생기던 25px 오버플로우 해결
  - `test/layout_test.dart` 추가 (테스트 43개)
- 변경 파일: `lib/app.dart`, `lib/core/router/app_router.dart`, `lib/data/models/game_progress.dart`, `lib/features/game/game_controller.dart`, `lib/features/game/game_providers.dart`, `lib/features/game_master/parent_gate.dart`, `lib/features/mission_map/mission_map_screen.dart`, `lib/features/result/case_solved_screen.dart`, `test/game_controller_test.dart`, `test/full_playthrough_test.dart`, `test/resume_and_guard_test.dart`, `test/parent_gate_test.dart`(신규)
