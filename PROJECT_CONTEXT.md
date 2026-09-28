# London Mystery — PROJECT_CONTEXT

> 이 파일은 Claude Code 세션이 바뀌어도 개발 흐름을 이어가기 위한 **영속적인 작업 기억 파일**이다.
> README.md(사용자/운영자용 안내)와 달리, 이 파일은 **다음 개발 세션이 현재 상태를 정확히 파악하기 위한 문서**다.
> 새 세션은 반드시 이 파일을 먼저 읽고, 아래 *Session Continuity Protocol*을 따른다.
>
> 최종 검증일: 2026-09-28 (실제 소스 전수 확인 + `flutter analyze` + `flutter test` 기준)
> 마지막 작업: Phase 2 안정화 — 플레이 시간 / Parent Gate lifecycle / 보호자 리포트 보호 (Change Log 참고)

---

## Project Overview

| 항목 | 내용 |
|---|---|
| 프로젝트 이름 | London Mystery (`london_mystery`, v0.1.0+1) |
| 위치 | `V:\vscode\basic\london_mystery` |
| 목적 | 8~12세 어린이용 **오프라인 탐정 미션 게임**. 실제 놀이 공간(체험관/행사장)에서 진행자가 운영할 수 있는 형태 |
| 핵심 컨셉 | 런던에서 사라진 왕관을 쫓는 탐정이 되어, 영어로 된 편지·단서를 읽고 퍼즐을 풀어 사건을 해결 |
| Target User | 8~12세 어린이 (플레이어) / 보호자 (결과 리포트) / 현장 운영자 (Game Master) |
| 현재 개발 단계 | Phase 2 — Game Experience Enhancement **구현 완료** 상태 (다음 Phase 미확정) |

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

---

## Completed Features

실제 코드에 구현되어 있고, analyze/test로 검증된 항목만 기록한다.

### 플레이 흐름 / 화면
- [x] **Start (Title)** — `features/onboarding/start_screen.dart`. 저장 데이터 있으면 "CONTINUE ADVENTURE" + "Start a new case"(확인 다이얼로그). 엠블럼 **길게 누르기** → Parent Gate → Game Master
- [x] **Player Registration (Detective ID)** — `register_screen.dart`. 이름 1~12자, 영문/숫자/한글/공백/`.`/`-`만 허용, 대문자 변환. 클라이언트 입력 필터 + `GameController.validateName` 이중 검증
- [x] **Episode Selection (Case Files)** — `episode_select_screen.dart`. EP01 케이스 파일 카드 + "EPISODE 02 Coming soon..." 잠금 카드(하드코딩)
- [x] **Story Intro** — `story_intro_screen.dart`. 타자기 효과, 탭으로 줄 넘김, SKIP, "Are you ready?" → `startInvestigation()`(사건 타이머 시작)
- [x] **Mission Map** — `features/mission_map/`. CustomPainter 런던 지도, 경로 점선/실선, 핀 3상태(completed/current/locked), 헤더(에피소드·탐정 이름·XP·경과시간·진행바), 게임 메뉴(사운드 토글/노트북/결과/타이틀)
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
- [ ] 이미지 asset 기반 일러스트 (현재 전부 CustomPainter; `Artwork` enum 키로 추후 URL 대체 가능하게 설계만 됨)
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
│   ├── mock/episode01_mock.dart       # EP01 콘텐츠 (백엔드 JSON과 같은 형태의 const Map)
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
| `/episodes` | EpisodeSelectScreen | 탐정 등록 필요 |
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

### Episode 01 — The Missing Crown (`ep01`) — **유일하게 구현된 에피소드**

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
- 정답 제출 시 조건 검사 → 신규 배지는 `badgeIds`에 획득 순서대로 추가, 성공 오버레이에 "NEW BADGE!" 표시

### Evidence
- 각 미션 데이터의 `evidence` (id, name, icon, description, inscription?, symbols[])
- 별도 저장 없이 `completedMissionIds` 순서에서 파생 (`collectedEvidence`)
- 노트북 EVIDENCE 탭 / 최종 미션 노트북 시트에서 탭 → 확대(`showEvidenceZoom`), inscription·symbols 표시

### Detective Notebook
- CLUES: 발견 순서의 단서 카드(심볼·값·장소·메모) + 미발견 슬롯
- EVIDENCE: 2열 그리드 + 잠금 슬롯
- BADGES: 6개 메달 (획득/미획득)
- 커버: 탐정 이름 + 총 XP

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

### Persistence (`lm.progress.v1`, `lm.settings.sound`)
`GameProgress` 필드: detectiveName, introSeen, completedMissionIds(해결 순서, final 포함), attempts, wrongAnswers, hintsUsed, missionStartedAt, missionStartPlayMillis, solveSeconds, badgeIds, lookedUpWords, startedAt, completedAt, playMillis
- Play again: 이름만 유지하고 사건 초기화 (`resetCase`)
- Reset all: 전부 삭제 (Start 화면 "Start a new case", Game Master 초기화)

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
| Images | **없음** | 랜드마크·지도·Royal Box·증거 아이콘 모두 CustomPainter (`widgets/landmark_art.dart`, `london_map_painter.dart`, `final_mission_screen.dart`) |
| Icons | Material Icons + 이모지 일부 | 앱 런처 아이콘은 Flutter 기본값 |
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
flutter analyze        # 2026-09-28: No issues found
flutter test           # 2026-09-28: 41 tests passed
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
- [ ] **EP02 "Coming soon" 카드 하드코딩** — 에피소드 목록이 데이터(`availableEpisodeIds`)와 연결되어 있지 않음
- [ ] (경미) `StorySceneScreen.build()` 안에서 `lines.isEmpty`일 때 `_done = true`를 대입 (build 중 상태 변경). 현재 모든 일반 미션에 transition이 있어 실제로 발생하지 않음

---

## TODO

### High Priority
- [ ] 현재 코드를 git에 커밋하여 보존 (사용자 승인 후)
- [ ] 실제 기기(Android/iOS)에서 전체 플레이 1회 수동 검증 — 특히 QR 스캔, 카메라 권한 거부 흐름, 사운드, ParentGate 닫기, **홈 버튼/앱 전환/화면 잠금 후 플레이 시간**
- [x] ~~경과 시간 계산 방식 결정~~ — 앱 활성 시간만 누적으로 결정·구현 (2026-09-28)

### Medium Priority
- [ ] 영어 난이도 처리 방향 결정 (난이도 레벨 / TTS 읽어주기 / 현 상태 유지)
- [ ] 에피소드 선택을 `EpisodeRepository.availableEpisodeIds()`와 연결 (EP02 준비 시)
- [ ] 효과음 품질 개선 (합성음 → 실제 효과음, 라이선스 확인)
- [x] ~~Parent Report 접근 정책 결정~~ — 매번 Parent Gate 요구로 결정·구현 (2026-09-28)
- [ ] Game Master 접근도 1회용 통과권으로 바꿀지 결정 (웹 배포 시 의미 있음)

### Low Priority
- [ ] 런처 아이콘·스플래시 교체
- [ ] 탐정 등급/칭호 (XP 기반) 검토
- [ ] README 플랫폼 설명 정정 (macOS)
- [ ] 웹 배포 시 호스팅 보안 헤더 설정

---

## Next Development Goal

**아직 사용자가 확정하지 않았다. 아래는 모두 `Proposed` 이며, 승인 전에는 개발하지 않는다.**

- ~~Phase 2 안정화: 경과 시간 / ParentGate / 보호자 리포트~~ — **완료** (2026-09-28)
- `Proposed` — **Phase 2 마무리**: git 보존 → 실기기 QA (lifecycle, QR, 사운드 포함)
- `Proposed` — **Phase 3 후보 A: Episode 02** — 기존 데이터 구조(`episode01_mock.dart` 형태)로 새 에피소드 추가 + 에피소드 선택 연결
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

### 2026-09-28

- Phase 1 MVP completed (이전 세션)
- Phase 2 game experience features implemented (이전 세션)
- 새 세션에서 인수인계 분석 수행: 소스 전수 확인, `flutter analyze` 0 issues, `flutter test` 28/28 통과
- PROJECT_CONTEXT.md created (코드 수정 없음)

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
