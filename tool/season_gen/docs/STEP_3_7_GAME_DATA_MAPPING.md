# STEP 3-7 — 게임 데이터 구조 분석과 Plan 스키마 확장 설계

**작성:** 2026-10-29 · **상태:** 조사·설계 (코드 변경 없음)
**목표:** Studio(`tool/season_gen/`)로 만든 Case를 실제 게임에서 플레이한다. 이를 위한 최소 구조와 작업 범위를 확정한다.
**대상:** London Season 1 12개 Case, Paris Season 2 12개 Case, STEP 3-6 시범 Case `s9_sandbox / s9_ep01` "The Lost Library Key"
**근거:** 실제 Dart 모델과 사용처. 24개 Case의 미션 유형과 테이블 사용은 `SeasonCatalog.all`을 읽어 집계했다(§1.9).

---

## 0. 결론 요약

| 질문 | 답 |
|---|---|
| 실제 게임과 Plan의 핵심 차이 | Plan은 **구조**(id, 순서, 정답, 단서 연결, 학습 목표)만 담는다. 게임이 화면에 쓰는 **플레이 텍스트**(intro, story, letter, question, hints, successMessage, transition, clue와 evidence의 글)와 **장소 그림 등록**(`ScenePlace`)은 Plan에 칸이 없다. |
| 추가할 필드 | 새 객체 3개(`CasePlan.play`, `MissionPlan.play`, `SeasonPlan.places`)와 시즌 필드 1개(`storyGreeting`). 최상위 26개, 하위 객체 필드를 합쳐 39개. 모두 선택 필드라 `schemaVersion` 1을 유지한다. |
| 퍼즐 호환성 | STEP 3-6의 네 퍼즐(`text_choice`, `order_sequence`, `word_entry`, `letter_tile_lock`)은 테이블 없이 `questionFor`로 바로 플레이된다. London 출시 콘텐츠가 이미 같은 경로를 쓴다. 텍스트 전용 6종은 Dart로 생성할 수 있다. 그림이 필요한 13종은 Plan에 픽셀·영역 데이터가 없어 지금은 생성할 수 없다. 개발이 필요한 9종은 생성 대상이 아니다. |
| Sandbox 연결 | **가능하며 `lib/` 변경이 0줄이다.** `test/season_scene_playthrough_test.dart`가 이미 `SeasonCatalog.all`에 없는 시즌을 provider override와 `SeasonCatalog.testPlaces`로 실제 앱에서 끝까지 플레이한다. |
| `released: false` | **격리되지 않는다.** 출시 빌드에서도 World Archive에 시즌 제목이 COMING SOON으로 노출되고, Paris 마지막 Case 리포트의 다음 시즌 표시가 바뀐다(§6.2). |
| 기존 코드 변경 범위 | STEP 3-8 기준으로 `lib/`는 0, London·Paris 콘텐츠도 0. `tool/season_gen/`(모델, 스키마, 검사, 생성기)과 `test/`, `integration_test/`만 바뀐다. |
| 객관식 보기 개수 | Plan은 2개 이상(`puzzle_selection_check.dart:311`), 게임은 3개 이상(`season_content_validator.dart:294`). 기존 검사는 그대로 두고, 생성 직전 `PlayCheck`가 3개 미만을 오류로 막는다(§5.5). |
| 다른 도시 문구 노출 | `caseSummary`가 없으면 London 문구가 나온다 → `play.caseSummary` 필수로 해결. **데이터로 덮을 수 없는 문구 2곳**이 더 있다: 문자 잠금판 "THE CLOCKMAKER'S LOCK", 일반 프롤로그의 "LONDON"(§1.13). Sandbox에서는 알려진 문제로 기록하고, 실제 새 시즌 전에 `lib/` 수정이 필요하다. |

---

## 1. 기존 게임 데이터 구조

표기:
- **필수:** fromJson이 값을 요구한다(없으면 예외).
- **선택:** 없어도 동작한다(기본값).
- **런타임:** 실행 중 계산된다. 콘텐츠에 쓰지 않는다.
- **파생:** 다른 데이터에서 정해진다. 생성기가 계산할 수 있다.
- **검증 필수:** fromJson은 받지만 `SeasonContentValidator`가 거부한다.

### 1.1 SeasonCatalog와 SeasonContent

- `lib/data/mock/season_catalog.dart:66` `SeasonContent`: 시즌 하나의 묶음.
  - `info`: Season JSON.
  - `episodes`: Case JSON, 순서대로, Case id로.
  - `awaitingArt`, `places`, `released`, `storyGreeting`.
  - 미션 id로 찾는 테이블 53개(`missionTables`, 같은 파일 :348).
  - `languageTopics`, `casePatches`, `variants`, `writtenLevels`, `evidenceLinks`, `introPictures`/`introPlaques`/`introPapers`, `evidenceArt`, `retiredEngines`.
- `:556` `SeasonCatalog.all = [season1Content, season2Content]`: **고정 목록.** 시즌 콘텐츠를 찾는 곳은 모두 이 목록만 본다.
  - `ofMission`·`ofEpisode`는 `_missionSeason`(:604)을 쓴다. 이 맵은 처음 접근할 때 한 번 만들어진다.
  - 테이블 조회는 모두 `_pick`(난이도 fallback 포함)을 거친다.
- `:600` `SeasonCatalog.testPlaces` (`@visibleForTesting`): 카탈로그 밖 시즌의 장소를 테스트가 등록하는 맵. `place()`가 시즌 장소 다음으로 이 맵을 본다(:590).
- `:549` `seasonReleased(seasonId)`: 카탈로그에 없는 시즌은 false.

| 데이터 | 구분 | 비고 |
|---|---|---|
| `info`, `episodes` | 필수 | |
| `places` | 선택. 단, 미션이 `sceneKey`를 쓰면 필수 | `ScenePlaceCheck`가 검사(`lib/data/content/scene_place_check.dart`) |
| `released` | 선택(true) | §6.2 |
| `storyGreeting` | 선택(true) | Season 2는 false |
| 퍼즐 테이블 49개 | 선택. 텍스트 퍼즐은 쓰지 않음 | 엔진 선택 순서: `PuzzleEngineDispatch`(`lib/data/content/puzzle_engine_collisions.dart:52`) |
| `learning`, `languageTopics` | 선택 | 부모 리포트(`lib/features/result/detective_report.dart:67,126`) |
| `discoveries` / `discoveryOf` | 선택 | 없으면 `Discovery.fallback(m)`: 제목은 `successMessage`(`lib/data/models/discovery.dart:84`) |
| `casePatches`, `variants`, `writtenLevels` | 선택 | 없으면 모든 난이도가 기본 글(Rookie)을 씀(`difficulty_content.dart:90`) |
| `evidenceLinks` | 선택 | `EvidenceLink{to, line}`(`lib/data/models/scene_exhibit.dart:43`) |
| `storyScenes`, `intro*`, `evidenceArt`, `exhibits`, `lockBoxes`, `endings` | 선택, 그림 필요 | Paris 전용 연출 |

### 1.2 Season (시즌 info JSON)

`lib/data/models/season.dart`. `Season.fromJson`은 너그럽게 읽는다(잘못된 줄은 건너뜀).

| 키 | 필드 | 구분 |
|---|---|---|
| `id` | `id` | 필수(없으면 London) |
| `number` | `number` | 필수(없으면 1) |
| `title`, `tagline` | | 필수(없으면 '') |
| `city` | | 선택('London') |
| `cases` | `plannedCases` | 선택 |
| `upcoming` | `upcomingTitles` | 선택 |
| `outro`, `finale` | | 선택 |
| `figures` | `SeasonFigure{after, figure, label}` | 선택 |
| `prologue` | `SeasonPrologue` | 선택. Paris는 별도 화면(`season_screen.dart:160`, `Routes.parisPrologue`) |
| — | `label` ("SEASON ONE") | 파생. 숫자를 단어로 바꾸는 표는 FOUR까지 |

### 1.3 Episode (Case)

`lib/data/models/episode.dart:97` `Episode.fromJson`

| 키 | 구분 | 사용처 |
|---|---|---|
| `id`, `number`, `title` | 필수 | Case 파일, 맵, 리포트, 저장 키 |
| `synopsis` (List) | 필수 | Case 파일 |
| `objectives` (List) | 필수 | Case 파일 브리핑 |
| `intro` (List) | 필수 | Story Intro 타자기(`lib/features/onboarding/story_intro_screen.dart`) |
| `missions` (List), `finalMission` | 필수 | `finalMission`에는 `finale: true`가 붙는다 |
| `seasonId` | 선택(London) | 새 시즌은 반드시 써야 한다 |
| `place` | 선택 | Case 파일 상단("GARE DU NORD · PARIS") |
| `introScene` | 선택. **`Artwork` 이름만** 가능 | 시즌 장소(`sceneKey`)를 지정할 수 없다. 없으면 시즌 맵, 맵도 없으면 어두운 배경(`story_intro_screen.dart:166`) |
| `caseSummary` | 선택이지만 **새 시즌은 사실상 필수** | 없으면 London 문구가 나온다: "You followed the clues across London and found the missing crown."(`detective_report.dart:151`) |
| `keyWords`, `hook`, `glossary` | 선택 | 부모 리포트, 사건 후 장면, 단어 탭 뜻풀이 |
| `difficulty`, `allClues`, `allEvidence` | 런타임/파생 | |

### 1.4 Mission

`lib/data/models/mission.dart:606` `Mission.fromJson`

| 키 | 구분 | 비고 |
|---|---|---|
| `id`, `number`, `title`, `location` | 필수 | `number`는 Case 안 순서(검증: `season_content_validator.dart:254`) |
| `scene` 또는 `sceneKey` | 필수(둘 중 정확히 하나) | 새 시즌은 `sceneKey`(시즌 장소 id) |
| `story` (List) | 필수 | 장소 도착 장면 |
| `letterIntro`, `letter` | 필수 | 그림 엔진 중에는 편지를 건너뛰는 것도 있지만(`skipsLetter`) 키는 필수 |
| `type` | 필수 | `MissionType` 12종 |
| `question` | 필수 | |
| `answer` | 필수 | |
| `hints` (List) | 필수. **검증 필수 1~2개** | `AppConstants.maxHints = 2`. 24개 Case의 98개 미션이 모두 2개 |
| `successMessage` | 필수 | 정답 화면, Discovery fallback 제목 |
| `mapX`, `mapY` (0..1) | 필수. 검증 필수 범위 | Case 랜드마크가 없는 맵에서 핀 위치 |
| `prompt` | 선택 | "ROSETTA _____" 같은 빈칸 |
| `options` | 선택. 유형에 따라 필수 | 객관식은 **검증 필수 3개 이상**(`season_content_validator.dart:294`) |
| `acceptedAnswers`, `codeLength`, `codeFormat`, `dialSymbols` | 선택 | |
| `clue` | 선택. 최종 미션 전에는 검증 필수 | `Clue{id, title, value, note, symbol?}` |
| `evidence` | 선택. 검증 필수(모든 미션) | `Evidence{id, name, icon, description, inscription?, symbols?}` |
| `transition` (List) | 선택 | 정답 후 장면. 최종 미션에서는 사건 후 장면 |
| `nextMissionId` | 파생. 검증 필수 | 다음 미션 id. 최종 미션은 없음 |
| `feedback` (Map), `orderFeedback` | 선택 | 오답 한 줄. 정답 키는 검증에서 거부 |
| `recall` | 선택 | `EvidenceRecall{evidence, title?, prompt?, feedback?, miss?}` |
| `skills` | 선택(레거시) | 화면에 쓰이지 않음 |
| `hideOptionNames` | 선택 | `imageChoice` 전용 |
| `finale`, `difficulty`, `isFinal`, `answerLabel`, `scene` | 런타임/파생 | |

`ChoiceOption{id, label, artwork?, feedback?, altText?}`: `artwork`는 `imageChoice` 전용.
`Evidence.icon`, `Clue.symbol`은 `GameSymbol` 키다(`lib/widgets/symbol_icon.dart:62`). 모르는 키는 "?"로 그려지고 예외는 나지 않는다. 키 목록은 Studio 쪽 `PaletteFacts.dialSymbols`에 복사돼 있다.

### 1.5 퍼즐 유형별 데이터: 엔진 선택

- 미션 화면은 `PuzzleEngineDispatch.mission`(`puzzle_engine_collisions.dart:52`) 순서대로 **처음 걸리는 테이블**의 엔진을 쓴다. 걸리는 테이블이 없으면 `questionFor`(`lib/features/mission/widgets/question_widgets.dart:927`)가 유형별 기본 위젯을 띄운다.
  - `multipleChoice`, `wordInput`, `numberCode`/`finalCode`(키패드), `sequence`, `letterLock`
- 최종 화면: `talks` → `easySteps` → `finalCode`(`_Dial`) → `canvases` → … → `postTrails`. 모두 해당하지 않으면 `questionFor`로 간다. `letterLock`은 `lockBoxes` 항목이 있을 때만 상자 연출이 붙는다(`final_mission_screen.dart:1554`). 없으면 일반 `LetterLockQuestion`이다(:1569).
- 정답 판정: `AnswerChecker`(`lib/core/utils/answer_checker.dart`). 입력형은 대문자로 바꾸고 영문자·숫자만 남겨 `answer`·`acceptedAnswers`와 비교한다.

### 1.6 단서 획득과 연결

- 미션을 풀면 `clue`와 `evidence`가 수첩에 들어간다. 무엇을 모았는지는 `GameProgress.completedMissionIds`에서 파생된다(`lib/data/models/game_progress.dart:159-164`). 단서 내용 자체는 저장되지 않는다.
- 이전 증거를 꺼내 보는 기능: `Mission.recall`. 증거끼리 짝짓기: `SeasonContent.evidenceLinks`. 둘 다 "앞에서 찾은 것"인지 검증된다(`season_content_validator.dart:386-400`).
- Plan의 `clueInputs` 중 게임 데이터가 있는 것은 `recall`과 `evidenceLink`뿐이다. `answerDerivation`, `textMention`, `talkPresent`, `learningRecall`은 Plan에서 설계 의도를 기록하는 용도다.

### 1.7 Final, Solved, Case Report

- 최종 미션: `Episode.finalMission`. 최종 화면은 `FinalMissionScreen`(`lib/features/mission/final_mission_screen.dart`).
- 정답 → `transition`(사건 후 장면) → Case Solved(`lib/features/result/case_solved_screen.dart`) → 조사 보드.
  - Case Solved는 `caseSummary`, `keyWords`, 다음 Case 또는 다음 시즌(`nextSeasonProvider`, :146)을 표시한다.
- 답한 뒤에도 Case가 바로 닫히지 않는 경우(`closesAfterLastStep`, `season_catalog.dart`)는 Paris 전용 테이블일 때만이다.

### 1.8 장소와 이미지 참조

- Season 1·2 미션은 `scene: Artwork`(enum, `mission.dart` `Artwork`)를 쓴다. 새 시즌은 `sceneKey: "<seasonId>.<name>"`과 `SeasonContent.places[id] = ScenePlace(file, pixels)`를 쓴다(`lib/data/models/scene_place.dart`).
- **등록되지 않은 시즌 장소는 `StateError`다**(`SeasonCatalog.placeFor`, `season_catalog.dart:594`). 다른 그림이나 빈 화면으로 대신하지 않는다(`lib/widgets/landmark_art.dart:110-155`). 따라서 미션의 장소마다 실제 번들 에셋 파일이 반드시 있어야 한다.
- 미션 맵: `SeasonMap`(`lib/features/mission_map/map_world.dart:25`)은 지도 그림과 `MapLandmark` enum으로 된 **Dart 코드**다. `seasonMapsProvider`에 맵이 없는 시즌은 COMING SOON이 되어 들어갈 수 없다.
- 세계지도: `WorldCities.all`(`lib/features/world_map/world_cities.dart:86`)에 `seasonId`가 있는 도시만 표시된다.

### 1.9 난이도별 문구

- 기본 글이 Rookie다. Junior·Master는 `casePatches`(Case JSON의 텍스트 필드만)와 `variants`(테이블)로 덮어쓴다. 바꿀 수 있는 키는 `DifficultyContent.caseText`/`missionText`/`missionParts`(`difficulty_content.dart:36-63`)에 정해져 있다.
- 패치가 없으면 모든 난이도에서 기본 글을 쓴다. `writtenLevels`에 표시한 난이도만 빠진 글을 검사한다.
- 새 Case가 처음 플레이되는 데 **필수가 아니다.**

### 1.10 진행 상태 저장

`lib/data/repositories/progress_repository.dart`, `lib/core/constants/app_constants.dart`

| 저장 | 키 | 내용 |
|---|---|---|
| Case 진행 | `lm.progress.v1.<episodeId>` (프로필 네임스페이스, :34) | `GameProgress`: 완료 미션, 시도/오답/힌트, 시간, `puzzleStates`… |
| 시즌 기록 | `lm.season.v1.<seasonId>` (:23) | `SeasonProgress`: 진행 중 Case, 해결한 Case, 프롤로그 봤는지, 난이도 |
| 선택 시즌 | `lm.selectedSeason.v1` | 들어갈 수 없는 시즌이면 London으로 되돌아감(`game_providers.dart:316`) |
| 지갑 | `lm.wallet.v1` | XP·코인. **모든 시즌이 공유** |

Case id와 시즌 id가 키에 들어가므로 `s9_*` 키는 London(`ep01`…)·Paris(`s2_*`)와 충돌하지 않는다. 단, 같은 기기의 실제 프로필로 플레이하면 지갑과 선택 시즌이 바뀐다. 그래서 Sandbox는 메모리 저장소만 쓴다(§6).

### 1.11 라우팅과 화면 연결

`lib/core/router/app_router.dart`: `/world-map` → `/season` → (`/season/prologue` | `/season/paris-prologue`) → `/episodes` → `/intro` → `/map` → 미션 화면 → 장면 → `/final` → `/solved` → `/report`.

Case를 열고 시작하는 상태 전환은 `GameController.openSeason / openEpisode / startInvestigation`이다. 정답 제출은 `submitAnswer`(`lib/features/game/game_controller.dart:319`)다.

### 1.12 24개 Case 집계 (실측)

- **London 12:** 미션 52개. 퍼즐 테이블을 쓰는 미션은 ep01의 4개, ep02 M1(clocks), ep03 M1(investigations), ep06 M1(dialogues)뿐이다. **나머지 45개는 테이블 없이 `questionFor`로 플레이된다.**
  - 유형: `multipleChoice`, `wordInput`, `numberCode`, `sequence`, `imageChoice`, `finalCode`.
  - 모든 미션에 `discoveries`와 `learning`(3개 난이도)이 있다.
- **Paris 12:** 미션 48개. 모두 장면 테이블 또는 Paris 전용 엔진을 쓰고, `storyScenes`와 `learning`이 있다. 시즌 장소(`sceneKey`)는 0개로, 모두 `Artwork`다. `evidenceLinks`는 Case 02부터 쓰인다.
- 모든 미션: 힌트 2개, `evidence` 있음. 최종 전 미션은 모두 `clue`가 있다. 객관식 보기는 3개 이상이다.

### 1.13 콘텐츠와 상관없이 화면에 고정된 도시 문구

새 시즌에서 다른 도시·이야기의 문구가 나올 수 있는 곳을 `lib/features/`에서 찾았다(문자열 리터럴 검색).

| 위치 | 문구 | 새 시즌에서 | 데이터로 해결 |
|---|---|---|---|
| `detective_report.dart:151` | "You followed the clues across London and found the missing crown." | `caseSummary`가 없을 때 Case Solved에 나온다 | **가능**: `play.caseSummary` 필수 + `PlayCheck` |
| `letter_lock.dart:111` | "THE CLOCKMAKER'S LOCK" (잠금판 제목) | `letterLock` 미션이면 **항상** 나온다. Paris의 시계공 이야기다 | **불가**: 위젯에 고정 |
| `letter_lock.dart:312` | "The Clockmaker's lock" (최종 화면 `LetterLockReveal`의 Semantics) | 최종 미션이 `letterLock`이면 나온다(`final_mission_screen.dart:1095-1101`) | **불가** |
| `season_prologue_screen.dart:219` | "LONDON" | Paris가 아닌 시즌은 모두 이 화면으로 간다(`season_screen.dart:160`) | **불가** |

그 밖의 London 문구(`register_screen.dart:175` 앱 이름 "LONDON DETECTIVE AGENCY", `scoring.dart:98,108` Season 1 배지, `map_world.dart` London 랜드마크)는 시즌 콘텐츠가 아니라 앱·Season 1 고유 요소라 이번 범위가 아니다.

판단:
- Sandbox(s9)는 플레이 검증이 목적이라 `lib/` 0을 유지하고, 잠금판 문구는 QA 기록에 "알려진 문제"로 남긴다. Sandbox 플레이는 Case를 직접 열어서(`openEpisode`) 프롤로그를 거치지 않는다.
- 실제 새 시즌 전에는 `lib/` 수정이 필요하다(§9.2-6). 예: 잠금판 제목을 미션 데이터(`prompt` 등)나 시즌 값에서 받고, 없으면 중립 문구("THE LOCK")를 쓴다. 게임 코드 변경이므로 사용자 승인 후 진행한다.

---

## 2. Studio Plan 현황

| 구성 | 파일 | 내용 |
|---|---|---|
| Season Plan | `tool/season_gen/plan_models.dart:456` | id·번호·도시·제목·tagline·plannedCases(12)·mainMystery·characters·locations(landmarkKey)·acts(3×4)·prologue·outro·finale·figures·languageArc·notes |
| Case Plan | `:569` | caseId·seasonId·number·actId·title·synopsis·goal·characters·locations·missions(1–5)·final·hook·learningGoal·notes |
| Mission Plan | `:767` | missionId·slot·placeId·puzzle·clueInputs·clueOutputs{clue?, evidence, facts}·learning·notes |
| Puzzle Plan | `:907` | paletteId·surface·engineTable·missionType·answerSpec{answer, acceptedAnswers, options{id,label,feedback?,altText?}, codeLength, codeFormat, dialSymbols}·assetNeeds·status·devNote·notes |
| 검증 | `validate_plan.dart` | 스키마 → 모델 → `PlanCheck`(구조) → `PuzzleSelectionCheck`(팔레트·정답) → `ClueGraphCheck`(단서 순서) |
| 승인 | `content_approval.dart` | `SeasonApprovals.readiness(caseId)`: 시즌 플랜·Case 플랜·필요 에셋이 모두 approved인지 |
| 저장 | `plan_files.dart` | 정해진 한 가지 형식(2칸 들여쓰기, 모델 키 순서), 임시 파일에 쓴 뒤 교체 |

STEP 3-6 `content_pipeline/seasons/s9_sandbox/`(미추적): 검증 0 errors / 0 warnings, 승인 상태 `draft`. letter와 question은 **`notes`에 자유 텍스트로만** 들어 있다. intro, hints, successMessage, transition, clue·evidence의 글, 장소 그림은 없다.

---

## 3. Plan ↔ 게임 데이터 매핑표

상태: **지원**(1:1 대응) · **부족**(일부만 있음, 형식이 다름) · **없음**
조치: **유지** · **확장**(§5의 새 필드) · **파생**(생성기가 계산) · **불필요**(게임에 없음, Plan 전용)

### 3.1 시즌

| 게임 데이터 | 현재 Plan 필드 | 상태 | 조치 |
|---|---|---|---|
| `info.id` / `number` / `title` / `tagline` / `city` | `seasonId` / `number` / `title` / `tagline` / `city` | 지원 | 유지 |
| `info.cases` | `plannedCases` | 지원 | 유지 |
| `info.outro` / `finale` | `outro` / `finale` | 지원 | 유지 |
| `info.figures` | `figures{after, figure, label}` | 지원 | 유지 |
| `info.prologue` | `prologue` | 지원(키 동일) | 유지 |
| `info.upcoming` | — | 없음 | 생성 안 함(빈 값). 아직 들어오지 않은 Case 제목은 시즌 운영 판단 |
| `SeasonContent.places` (`ScenePlace{file, pixels}`) | 미션 `placeId`만 있음 | **없음** | **확장: `SeasonPlan.places`** |
| `SeasonContent.storyGreeting` | — | 없음 | 확장: `storyGreeting`(선택, 기본 true) |
| `SeasonContent.released` | — | 없음 | Plan에 넣지 않음. 출시 결정은 사람이 Dart 등록 단계에서 한다 |
| `SeasonMap` (지도·랜드마크) | `locations[].landmarkKey` | 부족(키만 있음) | Dart 코드라 생성 불가. Sandbox는 기존 맵을 재사용(§6). 실제 시즌은 별도 작업 |
| `WorldCities` 항목 | `city` | 부족 | 코드. 실제 시즌 출시 때 작업 |
| `mainMystery`, `characters`, `acts.theme`, `languageArc`, `notes` | 있음 | — | 불필요(설계용) |

### 3.2 Case

| 게임 데이터 | 현재 Plan 필드 | 상태 | 조치 |
|---|---|---|---|
| `id` / `number` / `seasonId` | `caseId` / `number` / `seasonId` | 지원 | 유지 |
| `title` / `synopsis` / `hook` | 같은 이름 | 지원 | 유지 |
| `objectives` | `goal`(문자열 1개) | 부족 | 확장: `play.objectives`(없으면 `[goal]`로 파생) |
| `intro` (Story Intro) | — | **없음** | **확장: `play.intro`** |
| `caseSummary` (Case Report) | — | **없음** | **확장: `play.caseSummary`(필수)** |
| `place` | — | 없음 | 확장: `play.place` |
| `keyWords` / `glossary` | — | 없음 | 확장: `play.keyWords` / `play.glossary` |
| `introScene` | — | 없음 | 추가 안 함: 게임이 `Artwork`만 받는다(§8.4) |
| `missions` 순서 / `finalMission` | `missions[]` / `final` | 지원 | 유지 |
| `languageTopics[caseId]` | `learningGoal{title, titleKo}` | 지원 | 유지 |
| `casePatches` / `writtenLevels` (난이도) | — | 없음 | 이번 범위 아님. 기본 글(Rookie)만 생성 |

### 3.3 Mission

| 게임 데이터 | 현재 Plan 필드 | 상태 | 조치 |
|---|---|---|---|
| `id` | `missionId` | 지원 | 유지 |
| `number` | (`slot` / 순서) | 지원 | 파생: 순서 + 1 |
| `nextMissionId` | (순서) | 지원 | 파생: 다음 미션, 최종 미션은 없음 |
| `sceneKey` | `placeId` | 지원 | 유지(+ `places` 등록 필수) |
| `type` | `puzzle.missionType` | 지원 | 유지 |
| `options` / `answer` / `acceptedAnswers` / `codeLength` / `codeFormat` / `dialSymbols` (Puzzle Answer) | `puzzle.answerSpec.*` | 지원 | 유지 |
| `ChoiceOption.feedback` (오답 피드백, 객관식) | `answerSpec.options[].feedback` | 지원 | 유지 |
| `feedback` (입력·순서형 오답) | — | 없음 | 확장: `play.feedback` |
| `orderFeedback` | — | 없음 | 확장: `play.orderFeedback` |
| `title` / `location` | — | 없음 | 확장 |
| `story` | — | 없음 | 확장 |
| `letterIntro` / `letter` (Letter) | `notes`(자유 텍스트) | 없음 | 확장 |
| `question` (Mission Question) | `notes`(자유 텍스트) | 없음 | 확장 |
| `prompt` | — | 없음 | 확장(선택) |
| `hints` (Hint) | — | **없음** | **확장(필수 1~2)** |
| `successMessage` | — | 없음 | 확장(필수) |
| `transition` (장면, 최종 미션은 사건 후 장면) | — | 없음 | 확장 |
| `mapX` / `mapY` | — | 없음 | 확장(필수 0..1) |
| `clue.id` | `clueOutputs.clue` | 지원 | 유지 |
| `clue.title/value/note/symbol` | — | 없음 | 확장: `play.clue` |
| `evidence.id` | `clueOutputs.evidence` | 지원 | 유지 |
| `evidence.name/icon/description/inscription/symbols` | — | 없음 | 확장: `play.evidence` |
| `recall.evidence` | `clueInputs[use=recall].ref` | 지원 | 파생 |
| `recall.title/prompt/feedback/miss` | — | 없음 | 확장: `play.recall`(선택) |
| `evidenceLinks[evidence] = {to, line}` | `clueInputs[use=evidenceLink].ref` | 부족(`line` 없음) | 확장: `play.evidenceLinkLine` |
| `learning[missionId]` (`LearningObjective`) | `learning{dependency, level, objective, skill?, expressions, recallFrom?}` | 지원(1:1) | 유지 |
| `skills` | — | 레거시 | 파생: 빈 목록 |
| `discoveries` | — | 없음 | 생성 안 함(`Discovery.fallback`) |
| 퍼즐 테이블(scene, pixels, hot spot) | `engineTable`, `assetNeeds` | 부족 | 그림 퍼즐 생성은 이번 범위 아님(§4) |
| `facts`, `answerDerivation`·`textMention` 입력, `status`, `paletteId`, `devNote`, `notes` | 있음 | — | 불필요(설계·검증용) |

### 3.4 런타임에서 계산되어 생성할 필요가 없는 것

`difficulty`, `finale`/`isFinal`, `answerLabel`, 수집한 단서·증거(완료 미션에서 파생), 시도·힌트·시간(`GameProgress`), XP·코인(`scoring.dart`, 지갑), Discovery fallback, 시즌 잠금·열림(`SeasonAvailability.of`, `game_providers.dart:216`), 해결 여부, Case 리포트의 수치.

---

## 4. 퍼즐 유형 호환성

`PuzzlePalette` 28종(`lib/data/content/puzzle_palette.dart`, Studio 쪽 복사본 `tool/season_gen/palette_facts.dart`) 기준이다.

| 묶음 | 퍼즐 | 게임 엔진 | Plan 지원 | 필요한 데이터 | Dart 생성 | 이미지 | 엔진 개발 |
|---|---|---|---|---|---|---|---|
| A. 텍스트 전용(ready·textOnly) | `text_choice`, `word_entry`, `number_entry`, `order_sequence`, `letter_tile_lock`, `combo_dial_lock` | `questionFor`의 기본 위젯 / 최종 `_Dial` | 정답 데이터 전부(`PuzzleSelectionCheck`가 정답까지 검사) | §5의 Mission `play` | **가능** (STEP 3-8) | 퍼즐에는 없음(장소 그림만) | 없음 |
| A'. 선택 연출 | `letter_tile_lock` + `lockBoxes` | `LockBoxStage` | 선택 엔진으로 인식 | `LockBoxArt`(그림·슬롯 픽셀) | 이번엔 안 함(상자 없이 생성) | 필요 | 없음 |
| B. 그림 필요(ready·requiresAssets) | `scene_explore_choose`, `lens_inspect_word`, `trace_deduction`, `object_decode`, `spot_difference`, `room_find_match`, `layer_reveal`, `clue_filter_choice`, `record_mismatch`, `symbol_dial_lock`, `viewpoint_match`, `guided_steps`, `evidence_talk` | 각자의 테이블 엔진 | 팔레트·정답·`assetNeeds`까지 | 테이블 모델 전체(그림 경로, 픽셀, 영역, 대사…) | **불가**: Plan에 테이블 데이터가 없다. 승인된 그림의 영역 측정이 먼저 필요 | 필요 | 없음 |
| B'. 조건부 그림(conditional·requiresAssets) | `scene_compare_report` | `StationClocks` | 위와 같음 | 위와 같음 | 불가 | 필요 | 없음 |
| C. 개발 필요(requiresDevelopment) | `picture_choice`, `clock_set`, `dark_room_search`, `witness_compare`, `evidence_board`, `closeup_compare_choose`, `token_place_map`, 그 밖의 개발 필요 퍼즐 | `Artwork` 고정 등 시즌에 묶여 있음 | `devRequest`로만 계획 | — | 생성 대상 아님 | 필요 | 필요 |
| D. 팔레트 밖 Paris 전용 | `lifts`, `keeperHuts`, `quayBoxes`, `clockWalls`, `blotters`, `planRoutes`, `archives`, `showStrips`, `lightBoards`, `flyRails`, `morningSketches`, `tornSlips`, `tornHours`, `gearBoards`, `makerMarks`, `towerTests`, `drumTapes`, `cityClocks`, `shadowChecks`, `hourRecords`, `streetBooks`, `postTrails`, `lightTables` | Case 전용 위젯 | `devRequest`, paletteId null(Case 10 fixture) | — | 대상 아님 | — | — |

기존 유형을 단순화하거나 통합하지 않았다. B와 C는 표에 적은 이유 때문에 생성 대상이 아니다.

### 4.1 STEP 3-6 퍼즐 네 개

| 미션 | 팔레트 | MissionType | 게임 경로 | 게임 검증 규칙 | 판정 |
|---|---|---|---|---|---|
| M1 | `text_choice` | `multipleChoice` | `questionFor` → `MultipleChoiceQuestion`(question_widgets.dart:929) | 보기 3개(3개 이상 규칙 충족), 정답 `shelf`가 보기 id | **호환** |
| M2 | `order_sequence` | `sequence` | `SequenceQuestion`(:951) | 3단계 = `codeLength` 3, id 모두 보기 | **호환** |
| M3 | `word_entry` | `wordInput` | `WordInputQuestion`(:933) | `LAMP` / `the lamp`는 정규화하면 `THELAMP`. `AnswerChecker`(:76-83)로 판정 가능 | **호환** |
| Final | `letter_tile_lock` | `letterLock` | `lockBoxes`가 없으므로 `questionFor` → `LetterLockQuestion`(final_mission_screen.dart:1569) | 타일 L·E·L·B가 BELL을 정확히 만듦(:322-326 규칙) | **호환** |

확인한 점:
1. **중복 `L` 타일(BELL = `l1`·`e`·`l2`·`b`)은 게임과 테스트 헬퍼 모두에서 정상이다(코드 확인, 실행 확인은 STEP 3-8).**
   - 게임 로직: `LetterLockQuestion`은 슬롯에 **타일 id**를 넣는다(`letter_lock.dart:38`). 놓인 타일 판정(`_placed`, :47), 빼기(`_tapLoose`, :68), 자리 바꾸기(`_place`, :55)도 모두 id 기준이다. 글자는 제출할 때만 이어 붙인다(:85, :175). 같은 글자 두 개가 섞이지 않는다.
   - 테스트 헬퍼: `test/mission_play.dart:233-240`은 정답 글자마다 `find.bySemanticsLabel('Letter $letter')`의 `.first`를 누른다. 문자열 인자는 **정확히 같은 라벨**만 찾는다. 놓인 타일의 라벨은 `'Letter L, in the lock. Tap to take it out.'`으로 바뀌고(:264), 슬롯 안의 타일은 `excludeSemantics: true`로 가려진다(:210). 그래서 두 번째 `L`은 남은 `l2`를 집는다. 이미 놓인 타일을 다시 눌러 빼는 일은 없다.
   - 정답 판정: `PuzzleSelectionCheck._sameLetters`(:355)는 글자 수까지 비교하므로 L 두 개가 필요하다는 것도 Plan 단계에서 검사된다.
2. 힌트에 정답 표기가 그대로 들어가면 게임 검증기가 막는다(`season_content_validator.dart:399-411`, 정규화 후 부분 문자열 비교, 3글자 미만 제외). M1은 "On the blue shelf by the window", M3은 LAMP, Final은 BELL을 힌트에 쓰면 안 된다. **"Mr. Bell"도 BELL을 포함하므로 Final 힌트에 이름을 쓸 수 없다.** 검사 대상은 힌트뿐이며 letter·question·story에는 이름을 써도 된다.
3. Final 화면의 잠금판에는 "THE CLOCKMAKER'S LOCK"이 나온다(§1.13). 플레이에는 영향이 없다.

---

## 5. Plan 스키마 확장 설계

### 5.1 원칙

- **필드 이름은 게임 JSON 키와 똑같이 쓴다.** 생성기는 이름을 바꾸지 않고 복사한다.
- **새 블록은 모두 선택이다.** 기존 Plan, Paris fixture, s9 draft가 그대로 통과한다.
- `schemaVersion`은 **1을 유지한다.** 필드를 추가만 하므로 깨지는 변경이 아니고, 이 스키마를 읽는 도구가 리포지토리 밖에 없다. 스키마(`additionalProperties: false`)와 모델(`_Reader`가 모르는 키를 거부)을 함께 고치고, `season_gen_schema_test`가 둘이 같은지 계속 지킨다.
- **게임 콘텐츠 규칙을 Plan 쪽에 다시 구현하지 않는다.** 힌트에 정답 노출, 객관식 보기 3개 이상, `nextMissionId`, 핀 범위, 정답 판정, 장소 등록은 생성 결과를 `SeasonContentValidator.validate(season)`(`season_content_validator.dart:55`)에 넣어 검사한다. 이 함수는 카탈로그 밖 시즌도 받는다. Plan 쪽 새 검사(`PlayCheck`)는 **생성기가 변환하는 데 필요한 것**만 본다.

### 5.2 `CasePlan.play` (선택 객체 → `Episode`)

| # | 필드 | 타입 | 필수 | 기본값 | 검증 | 게임 매핑 |
|---|---|---|---|---|---|---|
| 1 | `objectives` | string[] | 아니오 | `[goal]` | 각 항목 비지 않음 | `Episode.objectives` |
| 2 | `intro` | string[] | **예** | — | 1개 이상 | `Episode.intro` |
| 3 | `caseSummary` | string | **예** | — | 비지 않음 | `Episode.caseSummary` |
| 4 | `place` | string | 아니오 | 없음 | 비지 않음 | `Episode.place` |
| 5 | `keyWords` | string[] | 아니오 | `[]` | | `Episode.keyWords` |
| 6 | `glossary` | {string: string} | 아니오 | `{}` | 키는 소문자 한 단어 | `Episode.glossary` |

### 5.3 `MissionPlan.play` (선택 객체 → `Mission`)

| # | 필드 | 타입 | 필수 | 기본값 | 검증 | 게임 매핑 |
|---|---|---|---|---|---|---|
| 7 | `title` | string | 예 | — | 비지 않음 | `title` |
| 8 | `location` | string | 예 | — | 비지 않음 | `location` |
| 9 | `story` | string[] | 예 | — | 1개 이상 | `story` |
| 10 | `letterIntro` | string | 예 | — | | `letterIntro` |
| 11 | `letter` | string | 예 | — | `{detectiveName}` 사용 가능 | `letter` |
| 12 | `question` | string | 예 | — | | `question` |
| 13 | `prompt` | string | 아니오 | 없음 | | `prompt` |
| 14 | `hints` | string[] | 예 | — | 1~2개(`AppConstants.maxHints`) | `hints` |
| 15 | `successMessage` | string | 예 | — | | `successMessage` |
| 16 | `transition` | string[] | 아니오 | `[]` | 최종 미션은 1개 이상(사건 후 장면) | `transition` |
| 17 | `feedback` | {string: string} | 아니오 | `{}` | 입력·순서형 전용. 객관식은 `options[].feedback` 사용 | `feedback` |
| 18 | `orderFeedback` | string | 아니오 | 없음 | `sequence`·`letterLock`·`wordInput`·`numberCode` 전용 | `orderFeedback` |
| 19 | `mapX` | number | 예 | — | 0..1 | `mapX` |
| 20 | `mapY` | number | 예 | — | 0..1 | `mapY` |
| 21 | `clue` | `{title, value, note, symbol?}` | `clueOutputs.clue`가 있으면 예, 없으면 금지 | — | `symbol`은 `PaletteFacts.dialSymbols`의 키 | `clue` (+ `id` ← `clueOutputs.clue`) |
| 22 | `evidence` | `{name, icon, description, inscription?, symbols?}` | 예 | — | `icon`·`symbols[]`는 `GameSymbol` 키 | `evidence` (+ `id` ← `clueOutputs.evidence`) |
| 23 | `recall` | `{title?, prompt?, feedback?, miss?}` | 아니오 | 없음 | `use: recall` 입력이 정확히 1개 있고 그 ref가 evidence id(`_e`)일 때만 | `recall` (+ `evidence` ← 그 ref) |
| 24 | `evidenceLinkLine` | string | `use: evidenceLink` 입력이 있으면 예 | — | 미션당 evidenceLink 입력 최대 1개 | `SeasonContent.evidenceLinks[evidence.id] = EvidenceLink(to: ref, line)` |

생성기가 파생하는 것: `id`, `number`, `nextMissionId`, `sceneKey`, `type`, `options`/`answer`/`acceptedAnswers`/`codeLength`/`codeFormat`/`dialSymbols`(`answerSpec`), `skills: []`.

### 5.4 `SeasonPlan` 추가

| # | 필드 | 타입 | 필수 | 기본값 | 검증 | 게임 매핑 |
|---|---|---|---|---|---|---|
| 25 | `places` | `[{placeId, file, pixels: {width, height}}]` | 아니오. 단, 생성 시 미션이 쓰는 모든 `placeId`에 필요 | `[]` | `placeId`는 `PlanIds.place` 형식이고 이 시즌 소속. `file`은 `assets/`로 시작하고 디스크에 있음. `pixels`는 양수. 중복 금지 | `SeasonContent.places[placeId] = ScenePlace(file, ScenePixels(w, h))` |
| 26 | `storyGreeting` | bool | 아니오 | `true` | | `SeasonContent.storyGreeting` |

하위 객체 필드: `clue` 4, `evidence` 5, `recall` 4, `places` 항목 3(`pixels` 하나로 계산). 최상위 26개와 합치면 **39개**다.

`places[].file`이 **새 그림**이면 해당 에셋이 STEP 3-5의 approved 상태여야 한다(`readiness`). 기존 번들 에셋을 재사용하는 것은 Sandbox에서만 허용한다(§6).

### 5.5 새 검사 `PlayCheck` (생성기 앞 단계)

`tool/season_gen/play_check.dart`

- `play`가 빠짐 → `play_missing`
- 필수 필드 빠짐 → `play_field_missing` (경로 예: `$.missions[1].play.hints`)
- 범위·개수 → `play_range`
- `clue`가 `clueOutputs`와 맞지 않음 → `play_clue_mismatch`
- `GameSymbol` 키가 아님 → `play_symbol_unknown`
- `recall`·`evidenceLink` 규칙 위반 → `play_recall`, `play_link`
- 장소 미등록 또는 파일 없음 → `place_unregistered`, `place_file_missing`
- 생성기가 아직 만들 수 없는 퍼즐(§4 A 외) → `generate_unsupported`
- 객관식(`multipleChoice`·`imageChoice`·`canvasChoice`) 보기가 3개 미만 → `play_choice_few`

**객관식 보기 개수 차이의 해결:**
- 현재: `PuzzleSelectionCheck`는 2개 미만만 막는다(`puzzle_selection_check.dart:310-311`, `_choiceTypes` :168). 게임 검증기는 3개 미만을 막는다(`season_content_validator.dart:292-294`, "a guess, not a choice").
- `PuzzleSelectionCheck`는 **바꾸지 않는다.** 설계 단계의 Plan(보기를 아직 다 정하지 않은 것)이 지금처럼 통과해야 하고, 기존 테스트 결과도 바뀌지 않아야 한다.
- 대신 생성 직전 `PlayCheck`가 게임과 같은 기준(3개)으로 막는다. 작성자는 생성 전에 JSON 경로(`$.missions[0].puzzle.answerSpec.options`)가 붙은 오류를 본다. 생성 후 `SeasonContentValidator`도 한 번 더 검사한다.
- 기준 숫자 3은 게임 코드에서 가져올 수 없으므로(`tool/`은 Flutter를 import하지 않음) `PaletteFacts`에 상수로 두고, 게임 검증기와 값이 같은지 확인하는 테스트를 `palette_facts_test.dart` 방식(게임 소스 텍스트 대조)으로 추가한다.
- s9 M1은 보기가 3개라 이미 통과한다.

`validate_plan.dart`는 기본 동작을 바꾸지 않는다. 요약에 "playable: yes / no(n개 누락)"만 덧붙인다. `--playable`을 주거나 생성기가 실행할 때만 오류로 처리한다. 그래서 기존 테스트 211개의 결과는 바뀌지 않는다.

### 5.6 마이그레이션

1. 기존 Plan은 수정할 필요가 없다. 새 블록이 없어도 형식·구조·선택·단서 검사를 모두 통과한다.
2. Paris fixture `test/fixtures/season_gen/s2_paris/`는 그대로 둔다. 원하면 `play`를 채운 fixture를 하나 추가해, 게임 Case(`season2Episode10Json`)와 생성 결과가 같은지 비교하는 테스트로 쓸 수 있다(선택).
3. `play`를 추가하면 Plan 해시가 바뀐다. 따라서 이미 승인된 Plan은 `stale`이 된다. 플레이 텍스트도 사람이 검토해야 하는 내용이므로 의도한 동작이다. 지금 승인 기록은 없다.
4. `PlanFiles`는 모델의 `toJson` 순서대로 저장하므로, 새 블록의 키 순서만 모델에 정의하면 된다.

---

## 6. Sandbox 시즌 연결 설계

### 6.1 이미 있는 경로: 게임 코드 변경 없음

`test/season_scene_playthrough_test.dart:150-160`이 `SeasonCatalog.all`에 없는 시즌 `s9_test`를 **실제 앱과 라우터로** 맵 → 미션 → 정답 → 장면 → 최종 → Case Solved → 조사 보드까지 플레이한다. 사용하는 것:

```dart
seasonsProvider.overrideWithValue([...SeasonCatalog.all.map((s) => s.season), Season.fromJson(sandboxInfo)]),
allEpisodesProvider.overrideWithValue([...MockEpisodeRepository.bundled(), ...sandboxEpisodes]),
seasonMapsProvider.overrideWithValue({...SeasonMap.bySeason, sandboxId: SeasonMap.paris}),
seasonReleasedProvider.overrideWithValue((id) => id == sandboxId || seasonReleased(id)), // 기존 테스트는 (_) => true. Sandbox는 이 좁은 형태를 제안
operatorToolsAvailableProvider.overrideWithValue(true),   // + seasonPreviewSwitchProvider.set(true)
SeasonCatalog.testPlaces.addAll(sandboxPlaces);           // tearDown에서 clear
// 저장소: testOverrides(prefs: {...}) — 메모리 SharedPreferences
```

**제안:** 이 방식을 그대로 Sandbox 연결로 쓴다. `lib/`은 바꾸지 않는다.

| 조건 | 충족 근거 |
|---|---|
| London·Paris 영향 없음 | `SeasonCatalog.all`, `season_catalog.dart`, 콘텐츠 파일을 건드리지 않는다. 기존 테스트의 시즌 목록도 그대로다. |
| 출시 빌드에 노출 안 됨 | 생성 결과와 하네스가 `test/`·`integration_test/`에만 있다. `flutter build`는 `lib/main.dart`에서 닿는 코드만 컴파일하므로 들어갈 수 없다. |
| 세계지도·Archive 영향 최소 | 실제 앱: 영향 0. 테스트 안: 세계지도는 `WorldCities`에 도시가 없어 표시하지 않고, Archive에는 override된 시즌 목록에서만 보인다. |
| 저장 데이터 충돌 방지 | 메모리 저장소(`test/helpers.dart` `testOverrides`)를 쓴다. 기기 저장소를 읽지도 쓰지도 않는다(`integration_test/case10_visual_qa_test.dart`와 같은 방식). 키도 `s9_*`라 겹치지 않는다. |
| 개발 환경에서만 실행 | `flutter test`(위젯 테스트)와 `flutter drive`(시뮬레이터 캡처)로만 실행한다. |
| 쉽게 제거 | `test/sandbox/`, `integration_test/sandbox_case_qa_test.dart`, `test_driver/sandbox_qa_driver.dart`, `content_pipeline/seasons/s9_sandbox/`를 삭제하면 끝이다. 다른 파일과 연결된 곳이 없다. |

이 방식의 한계(카탈로그 밖 시즌이라 생기는 것):
- `SeasonCatalog`가 찾아 주는 표(`learning`, `languageTopics`, `discoveries`, `storyScenes`, `evidenceLinks`, `casePatches`)는 화면에 반영되지 않는다.
  - Discovery는 `successMessage`로 대신 표시된다(`season_catalog.dart:805`).
  - 부모 리포트의 학습 항목은 비어 있다.
  - 텍스트 퍼즐 네 개의 플레이에는 영향이 없다.
- 위 표는 테스트에서 `SeasonContent(info, episodes, places, learning, languageTopics, evidenceLinks, released: false)`로 묶어 `SeasonContentValidator.validate`로 **검증만** 한다.
- 인트로 배경은 `introScene`이 없고 `SeasonMap.forSeason`(정적 맵)에도 없어서 어두운 배경이다(`story_intro_screen.dart:166`). 정상 동작이다.
- 미션 맵은 Paris 지도 그림을 빌려 쓰고, 핀은 `mapX`/`mapY` 위치에 놓인다(Case 랜드마크가 없으므로).
- `SeasonCatalog.all.add`처럼 런타임에 목록을 바꾸는 방식은 쓰지 않는다. `_missionSeason`이 처음 접근할 때 한 번 만들어지므로 나중에 추가한 시즌은 반영되지 않는다(:604).

### 6.2 `released: false`만으로는 격리되지 않는다 (검증 결과)

Sandbox를 `SeasonCatalog.all`에 `released: false`로 넣었다고 가정하고 출시 빌드(`operatorToolsInBuild == false`, `game_providers.dart:636`)를 따라가 보면 다음과 같다.

1. **바이너리에 포함된다.** `season_catalog.dart`가 import하므로 콘텐츠 문자열이 앱에 들어간다.
2. **World Archive에 노출된다.** `seasonFilesProvider`(`world_archive_screen.dart:63`)가 `seasonsProvider`의 모든 시즌에 파일을 만든다. 공개되지 않은 시즌은 `comingSoon`이 되어 **시즌 제목과 tagline**("STUDIO TRIAL / ONE TRIAL CASE")을 COMING SOON 도장과 함께 보여 준다(:479-486).
3. **Paris 엔딩이 바뀐다.** `nextSeasonProvider`(`game_providers.dart:294`)가 Paris 다음 시즌으로 Sandbox를 돌려준다. Paris Case 12 리포트가 "시즌 완료, 다음 없음"(`seasonDone`) 대신 "다음 시즌 COMING SOON"(`finale`)으로 나온다(`case_solved_screen.dart:146-152`). 출시 콘텐츠의 동작이 바뀌는 것이다.
4. **`LM_PLAYTEST` 빌드에서 열린다.** `--dart-define=LM_PLAYTEST=true`로 만든 테스터 배포 빌드는 operator 빌드라서 시즌 미리보기로 열 수 있다.
5. **검증과 테스트에 섞인다.** `SeasonContentValidator.validateAll`과 `SeasonCatalog.all`을 순회하는 테스트 파일 10개에 Sandbox가 들어간다.
6. 반대로, 세계지도는 `WorldCities`에 도시가 없어 영향이 없다. 잠금 규칙상 Paris를 다 풀기 전에는 열리지도 않는다. 하지만 1~5번이 이미 격리 조건을 깨뜨린다.

→ **`released: false`는 "플레이할 수 없게" 막는 플래그이지 "보이지 않게" 하는 플래그가 아니다.** Sandbox 용도로 쓰지 않는다.

### 6.3 기기에서 직접 손으로 플레이하는 경로 (선택, STEP 3-8 범위 밖)

시뮬레이터에서 사람이 직접 만져 보고 싶다면 `lib/main_sandbox.dart` 같은 별도 진입점(`flutter run -t`)이 필요하다. `lib/main.dart`에서 닿지 않으면 출시 빌드에는 들어가지 않는다. 다만 `lib/`에 Sandbox 데이터를 import해야 하고(`test/` 파일은 `lib/`에서 import할 수 없음), 기기 저장소 대신 메모리 저장소를 쓰도록 설정해야 한다. 자동 검증과 화면 캡처는 §6.1의 `integration_test`로 충분하므로 지금은 추가하지 않는다.

---

## 7. Dart 생성기 입력·출력 계약

### 7.1 명령

```sh
dart run tool/season_gen/generate_case.dart \
  --season content_pipeline/seasons/s9_sandbox/season.plan.json \
  --target sandbox \
  content_pipeline/seasons/s9_sandbox/cases/s9_ep01/case.plan.json
# --check : 쓰지 않고 다시 생성해 디스크와 비교 (다르면 exit 1)
```

Flutter를 import하지 않는다. `tool/season_gen/` 규칙대로 `dart run`으로 실행되며, **Dart 소스 텍스트만 만든다.** 생성 결과가 게임 모델과 맞는지는 `flutter test`(§7.6)에서 확인한다.

### 7.2 입력

| 입력 | 출처 |
|---|---|
| Season Plan | `PlanFiles.loadSeasonPlan` |
| Case Plan(1개 이상) | `PlanFiles.loadCasePlan` |
| 장소 에셋 | `SeasonPlan.places[].file`(디스크에 있는지 확인) |
| 승인 | `SeasonApprovals(seasonDir).readiness(caseId)` (`--target season`일 때만 필수) |
| 기호 키 | `PaletteFacts.dialSymbols`(`GameSymbol` 키 복사본) |

### 7.3 생성 순서 (하나라도 실패하면 아무것도 쓰지 않음)

1. `validate_plan`과 같은 파이프라인: 스키마 → 모델 → `PlanCheck` → `PuzzleSelectionCheck` → `ClueGraphCheck`(`--season`으로 시즌과 함께). 오류가 있으면 중단한다.
2. 승인:
   - `--target season`은 `readiness.ready`가 아니면 중단(`not_ready`, blockers 출력).
   - `--target sandbox`는 상태만 출력하고 manifest에 `"approved": false`로 남긴다.
3. `PlayCheck`(§5.5): 빠진 필드는 JSON 경로와 함께 **모두** 나열한 뒤 중단한다.
4. 변환: Case JSON(§3의 매핑, 키 순서는 `Episode.toJson`/`Mission.toJson`과 같게), 시즌 info JSON, `places`, `learning`, `languageTopics`, `evidenceLinks`.
5. 덮어쓰기 검사(§7.5).
6. 파일 쓰기: 생성 디렉터리 전체를 임시 디렉터리에 만든 뒤 이름을 바꿔 한 번에 교체한다(`PlanFiles._write`와 같은 방식).
7. manifest 쓰기.

오류 출력 형식은 `validate_plan`과 같다:
`error    play [play_field_missing] $.missions[1].play.hints: missing`. 종료 코드 1.

### 7.4 출력

`--target sandbox`(STEP 3-8에서 구현):

```
test/sandbox/generated/s9_sandbox/
  s9_sandbox_season.g.dart   const s9SandboxInfoJson (Map), s9SandboxPlaces (Map<String, ScenePlace>),
                             s9SandboxStoryGreeting (bool)
  s9_ep01.g.dart             const s9Ep01Json (Map, Episode JSON),
                             s9Ep01Learning (Map<String, LearningObjective>),
                             s9Ep01LanguageTopic (CaseLanguageTopic),
                             s9Ep01EvidenceLinks (Map<String, EvidenceLink>)
  generated.manifest.json
```

`--target season`(설계만, 실제 Season 3을 등록할 때 사용):
`lib/data/mock/season<N>/generated/`에 같은 형식으로 만든다. `season<N>Content`(SeasonContent 조립)와 `SeasonCatalog.all` 등록, `SeasonMap`, `WorldCities`는 **사람이 손으로 작성하는 코드**로 두고 생성기는 건드리지 않는다.

연결 방식:
- 생성 파일은 상수만 내보낸다.
- Sandbox는 손으로 한 번 작성하는 `test/sandbox/sandbox_season.dart`가 상수를 import해 두 가지를 만든다.
  - `SeasonContent`: 검증용
  - provider override 목록과 `testPlaces` 등록: 플레이용
- Case가 늘어나면 하네스의 import 목록 한 줄만 추가한다.

manifest:

```json
{
  "generator": "generate_case.dart",
  "generatorVersion": 1,
  "target": "sandbox",
  "seasonId": "s9_sandbox",
  "approved": false,
  "inputs": {
    "season.plan.json": "sha256:…",
    "cases/s9_ep01/case.plan.json": "sha256:…"
  },
  "outputs": {
    "s9_sandbox_season.g.dart": "sha256:…",
    "s9_ep01.g.dart": "sha256:…"
  }
}
```

입력 해시는 `ContentHash`(STEP 3-5의 정규화 해시), 출력 해시는 파일 바이트의 SHA-256이다. **시간 값은 넣지 않는다.**

### 7.5 결정성과 덮어쓰기 방지

- **결정성:**
  - 맵은 Plan 순서와 타입별 고정 키 순서를 따른다.
  - 문자열은 작은따옴표 Dart 리터럴로 쓰고 `\\`, `\'`, `$`, 줄바꿈을 이스케이프한다.
  - 숫자는 `ContentHash`의 정규화 규칙을 따른다.
  - 파일 끝 줄바꿈은 1개이고 시간 값은 없다.
  - 같은 입력이면 항상 같은 바이트가 나온다. `--check`와 테스트로 확인한다.
  - **줄바꿈은 항상 LF로 쓴다.** Windows 체크아웃(`core.autocrlf=true`)에서는 작업 트리 파일이 CRLF가 되어 바이트 비교가 깨진다. 실제로 이 환경에서 기존 테스트 2개가 같은 이유로 실패한다(§10). 그래서:
    - `--check`와 `hand_edited` 판정은 디스크 파일을 읽을 때 CRLF를 LF로 바꾼 뒤 비교한다.
    - STEP 3-8에서 `.gitattributes`에 `*.g.dart`, `generated.manifest.json`, `content_pipeline/**/*.json`, `test/fixtures/season_gen/**`를 `eol=lf`로 지정하는 것을 제안한다(저장소 설정 변경이므로 사용자 확인 후).
- **덮어쓰기 방지:**
  - 생성기는 자기 `generated/` 디렉터리 밖에는 쓰지 않는다. `season_catalog.dart` 같은 손으로 쓴 파일은 절대 수정하지 않는다.
  - 모든 생성 파일의 첫 두 줄은 다음과 같다.
    `// GENERATED by tool/season_gen/generate_case.dart — DO NOT EDIT.`
    `// source: cases/s9_ep01/case.plan.json sha256:…`
  - 대상 파일이 이미 있는데 이 머리말이 없거나, 바이트 해시가 manifest에 기록된 출력 해시와 다르면(누군가 손으로 고침) `hand_edited` 오류로 중단한다. 덮어쓰려면 `--force`가 필요하다.
  - manifest에 없는 파일이 `generated/`에 있으면 경고만 하고 지우지 않는다.

### 7.6 생성 후 검증 (STEP 3-8 테스트)

1. **파싱:** `Episode.fromJson(s9Ep01Json)`, `Season.fromJson(info)`. 생성기와 게임 모델이 맞는지 확인한다.
2. **게임 검증기:** 하네스의 `SeasonContent`로 `SeasonContentValidator.validate`를 돌려 문제 0개를 확인한다. 보기 3개 이상, 힌트 노출, 정답 판정, `nextMissionId`, 핀, 장소 등록, 참조, 난이도 규칙이 모두 기존 코드로 검사된다.
3. **Plan과 일치:** id, 정답, 보기, 단서·증거 id, 학습 항목이 Plan과 같은지.
4. **결정성:** 생성기를 두 번 실행해 같은 바이트인지, `--check`가 exit 0인지.
5. **플레이:** 위젯 테스트로 실제 앱을 따라간다. Story Intro → 맵 → M1~M3 → 최종 → CASE SOLVED → 리포트 → 조사 보드. `GameProgress.completedMissionIds`와 `SeasonProgress.solvedEpisodeIds`, 수첩의 단서·증거를 확인한다.
6. **기존 콘텐츠 영향 없음:** `test/season_gen/`, `test/season_content_validator_test.dart`, `test/season_scene_playthrough_test.dart`가 그대로 통과하는지.

---

## 8. The Lost Library Key 적용 가능성

### 8.1 현재 Plan에서 부족한 필드

- **Case:** `play.intro`, `play.caseSummary`. 권장: `play.place`, `play.keyWords`, `play.glossary`. `objectives`는 `goal`로 파생할 수 있다.
- **미션 4개 각각:** `title`, `location`, `story`, `letterIntro`, `letter`, `question`, `hints`(2개), `successMessage`, `transition`, `mapX`, `mapY`, `evidence{name, icon, description, inscription?}`.
  - M1~M3은 `clue{title, value, note}`도 필요하다.
  - M2·Final은 `orderFeedback`과 `feedback`이 권장이다.
  - Final의 `transition`은 사건 후 장면이므로 필수다.
  - 지금 `notes`에 적어 둔 letter와 question 문장은 `play.letter`, `play.question`으로 옮긴다.
- **시즌:** `places`에 3개(`s9_sandbox.front_desk`, `s9_sandbox.window_shelf`, `s9_sandbox.reading_room`).
- `recall`, `evidenceLinkLine`은 필요 없다. 이 Case에는 `use: recall`·`evidenceLink` 입력이 없다.

### 8.2 기존 퍼즐 엔진으로 구현할 수 있는가

**예.** §4.1 표대로 네 개 모두 테이블 없이 `questionFor` 경로로 플레이된다. London Case 02~12의 미션 45개가 같은 경로로 출시되어 있다(§1.12). 새 엔진도, 새 위젯 분기도 필요 없다.

최종 정답 BELL의 중복 `L`: 게임 로직(타일 id 기준)과 테스트 헬퍼(정확한 Semantics 라벨, 놓인 타일은 라벨이 바뀜) 모두 정상 처리된다(§4.1-1). STEP 3-8 플레이 테스트에서 `LetterLockQuestion`에 `l1`·`l2`가 모두 슬롯에 들어간 상태로 제출되는지 확인한다.

### 8.3 생성해야 하는 게임 데이터

- `s9Ep01Json`: Episode 1개(미션 3개 + 최종 미션)
- `s9SandboxInfoJson`
- `s9SandboxPlaces`(장소 3개)
- `s9Ep01Learning`(4개)
- `s9Ep01LanguageTopic`(1개)
- `s9Ep01EvidenceLinks`(0개)
- manifest

### 8.4 새 이미지 없이 플레이할 수 있는가

**퍼즐은 그림이 필요 없다. 장소에는 그림이 반드시 있어야 한다.** 시즌 장소는 등록된 파일이 없으면 `StateError`이고(`season_catalog.dart:594`), 다른 그림으로 대신 그리지 않는다(`landmark_art.dart:110-155`).

해결: 이미 번들에 있는 그림을 **Sandbox에서만** 장소로 등록한다. 장면 성격이 비슷한 후보(pubspec에 등록됨, 크기는 실측):

| 장소 | 후보 파일 | 크기 |
|---|---|---|
| `front_desk` | `assets/seasons/season_02_paris/cases/case_11/annex_reading_room.png` | 1536×1024 |
| `window_shelf` | `assets/seasons/season_02_paris/cases/case_11/annex_shelves.png` | 1536×1024 |
| `reading_room` | `annex_reading_room.png` 재사용, 또는 `visitor_book_open.png` | 1536×1024 |

그림이 실제로 어울리는지는 사람이 눈으로 확인해야 한다. 이 파일들은 Paris Case 11의 그림이므로 실제 시즌 콘텐츠로는 쓰지 않는다.

- 미션 맵: `SeasonMap.paris` 재사용
- 인트로: 어두운 배경(§6.1)
- 사운드: 기존 공통 효과음

### 8.5 Sandbox에서 실행하려면 최소 무엇이 필요한가

§6.1의 provider override 5개, 미리보기 스위치, `SeasonCatalog.testPlaces` 등록, 메모리 저장소. 모두 테스트 코드에서 설정하며 `lib/` 변경은 0이다. 같은 구성으로 이미 통과하는 테스트가 있다(`test/season_scene_playthrough_test.dart`).

### 8.6 다음 단계에서 자동 생성과 플레이 검증까지 가능한가

**예. 조건이 두 가지 있다.**
1. §8.1의 플레이 텍스트를 사람이 작성하거나 승인해야 한다. 생성기는 글을 지어내지 않는다.
2. 화면 캡처는 시뮬레이터나 기기에서 `flutter drive`로 실행해야 한다. Case 09·10의 시각 QA와 같은 방식이다(`integration_test/case10_visual_qa_test.dart`, `test_driver/case10_qa_driver.dart`).

답을 입력하는 UI 조작은 기존 헬퍼(`test/mission_play.dart:207-245`)에 네 유형이 모두 있다.

---

## 9. 다음 구현 단계

### 9.1 STEP 3-8: 생성기와 Sandbox 플레이 (정확한 작업)

| # | 작업 | 파일 | 비고 |
|---|---|---|---|
| 1 | Plan 모델 확장: `CasePlayPlan`, `MissionPlayPlan`, `ClueText`, `EvidenceText`, `RecallText`, `PlacePlan`, `SeasonPlan.storyGreeting` | `tool/season_gen/plan_models.dart` | 선택 필드, 키 순서 고정 |
| 2 | 스키마 확장(같은 규칙) | `tool/season_gen/schema/{common,season_plan,case_plan,mission_plan}.schema.json` | `schemaVersion` 1 유지 |
| 3 | 스키마-모델 일치 테스트와 샘플 갱신 | `test/season_gen/season_gen_schema_test.dart`, `plan_samples.dart` | 기존 211개 유지 |
| 4 | `PlayCheck` + `validate_plan` 요약에 playable 표시와 `--playable` 옵션 | `tool/season_gen/play_check.dart`, `validate_plan.dart` | §5.5. 보기 3개 기준 포함 |
| 5 | 생성기: 변환, Dart 리터럴 작성기, manifest, `--check`, 덮어쓰기 방지 | `tool/season_gen/generate_case.dart`, `dart_literal.dart` | `--target sandbox`만 구현 |
| 6 | 생성기 단위 테스트(결정성, 누락 오류, 손으로 고친 파일 거부) | `test/season_gen/generate_case_test.dart` | |
| 7 | s9 draft에 `play`와 `places` 작성(콘텐츠) | `content_pipeline/seasons/s9_sandbox/…` | 사람 검토 필요 |
| 8 | 생성 실행 → `test/sandbox/generated/s9_sandbox/` | (생성물) | |
| 9 | Sandbox 하네스(SeasonContent 조립, override, `testPlaces`) | `test/sandbox/sandbox_season.dart` | 손으로 한 번 작성 |
| 10 | 생성 결과 검증 + 실제 앱 플레이 위젯 테스트 | `test/sandbox/s9_ep01_test.dart` | §7.6의 1~5 |
| 11 | 시뮬레이터 화면 캡처 | `integration_test/sandbox_case_qa_test.dart`, `test_driver/sandbox_qa_driver.dart` → `qa/screenshots/sandbox/` | |
| 12 | 관련 테스트와 `flutter analyze` | | 전체 테스트 실행 불필요 |
| 13 | (확인 후) LF 고정 | `.gitattributes` | §7.5. Windows에서 `--check`와 기존 테스트 2개가 CRLF 때문에 실패하는 문제 |

변경 범위: `tool/season_gen/` 수정 5개와 추가 3개, `test/` 추가·수정 약 6개, `integration_test/`·`test_driver/` 추가 2개. **`lib/` 0, London·Paris 콘텐츠 0.**

### 9.2 STEP 3-8 이후, 실제 시즌에서 Case를 플레이하기까지 남은 작업

1. **실제 Season 3 Plan 작성과 사람 승인**(`approve.dart`). 생성기 `--target season`은 readiness를 요구한다.
2. **`--target season` 활성화:** `lib/data/mock/season3/generated/`. 손으로 작성할 것: `season3Content`, `SeasonCatalog.all` 등록, `released` 결정.
3. **시즌 맵:** `SeasonMap`(지도 그림 + `MapLandmark` enum + `caseLandmarks`). Dart 코드와 새 그림이 필요하고 생성 대상이 아니다. 세계지도 `WorldCities`의 해당 도시에 `seasonId`를 연결한다.
4. **장소 그림:** 새 그림 제작·승인 → `SeasonPlan.places`. 에셋 크기·투명도 검사는 README에 있던 원래 "STEP 3-8 에셋 검사" 항목이고, 이제 뒤 단계로 밀린다.
5. **그림 퍼즐(§4 B) 생성:** Plan에 테이블 데이터(픽셀·영역·대사)를 담는 칸을 추가하거나, 승인된 그림을 측정하는 단계가 필요하다. 퍼즐마다 별도 설계가 필요하다.
6. **게임 쪽 작은 공백(필요할 때만):**
   - `Episode.introScene`은 `Artwork`만 받는다. 새 시즌의 인트로 배경을 시즌 장소로 쓰려면 코드 변경이 필요하다.
   - Paris가 아닌 시즌은 일반 `SeasonPrologueScreen`으로 가는데(`season_screen.dart:160`), 이 화면에 "LONDON"이 고정되어 있다(`season_prologue_screen.dart:219`, §1.13).
   - 문자 잠금판 제목 "THE CLOCKMAKER'S LOCK"과 최종 화면 Semantics가 고정되어 있다(`letter_lock.dart:111,312`, §1.13).
   - `Season.label`의 숫자 표는 FOUR까지다. 그 뒤는 숫자로 나온다("SEASON 9", `season.dart:152-154`). 오류는 아니다.
7. **난이도:** Junior·Master 문구(`casePatches`, `variants`, `writtenLevels`). 없어도 플레이할 수 있다.

---

## 10. 코드 대조 검증 기록 (2026-10-29, 2차)

1차 작성 결과를 실제 코드와 다시 대조했다. 문서의 결론(새 객체 3개 + 시즌 필드 1개, `schemaVersion` 1 유지, `lib/` 0, Sandbox 연결 방식, 텍스트 퍼즐 6종 생성 가능)은 **바뀌지 않는다.**

| 확인 항목 | 근거 | 결과 |
|---|---|---|
| `caseSummary` 기본값이 London 문구 | `detective_report.dart:149-151` | 일치 |
| `SeasonCatalog.all` 고정, `testPlaces`, 미등록 장소 `StateError` | `season_catalog.dart:556, 590, 595, 600, 604` | 일치 |
| 객관식 보기 Plan 2 / 게임 3 | `puzzle_selection_check.dart:311`, `season_content_validator.dart:294` | 일치. 해결 방향 추가(§5.5) |
| Plan 모델 위치 | `plan_models.dart:456, 569, 767, 907` | 일치 |
| Sandbox override 구성 | `season_scene_playthrough_test.dart:114-115, 150-163` | 일치. `seasonReleasedProvider`만 기존 테스트가 더 넓음(§6.1 주석) |
| 중복 L 타일 | `letter_lock.dart:38-85, 210, 264`, `test/mission_play.dart:233-240` | 미확인 → **정상으로 확정**(§4.1-1) |
| 힌트 정답 노출 검사 범위 | `season_content_validator.dart:399-411` | 힌트만 검사. "Mr. Bell"도 막힘(§4.1-2) |
| 고정된 도시 문구 | `letter_lock.dart:111, 312`, `season_prologue_screen.dart:219` | **새로 발견**(§1.13) |
| 기존 season_gen 테스트 | `flutter test test/season_gen` (이 Windows 작업 트리) | **209 통과 / 2 실패**. 두 실패(`palette_facts_test.dart:66`, `paris_case10_plan_test.dart:31`) 모두 CRLF 차이. 저장소에는 LF로 들어 있고(`git ls-files --eol`: `i/lf w/crlf`) `core.autocrlf=true`가 원인이다. 코드 회귀가 아니다. LF 작업 트리에서는 211개 통과(STEP 3-6 보고). §7.5 대책 추가 |
