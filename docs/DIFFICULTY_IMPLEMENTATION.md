# Difficulty System — 구현 인수인계 문서

> 난이도 시스템(Rookie / Junior / Master)을 여러 세션·여러 Claude Code 계정에 걸쳐 개발하기 위한 **단일 인수인계 문서**다.
> 새 세션은 이전 대화를 모른다고 가정한다. 이 문서와 `PROJECT_CONTEXT.md`, `CLAUDE.md`만 읽고 다음 PART를 시작할 수 있어야 한다.
> 코드와 이 문서가 다르면 **코드가 source of truth**다. 다르다는 사실을 발견하면 이 문서를 고치고 그 사실을 작업 이력에 남긴다.
>
> 표기: **[확인]** = 코드에서 직접 확인한 사실(경로:줄) / **[추정]** = 코드에서 추론한 내용(구현 전 재확인 필요) / **[제안]** = 이 문서가 제안하는 설계 / **[미결정]** = 사용자 결정 필요.
> 줄 번호는 2026-10-27, HEAD `0cdbe8a` 기준이다. 코드가 바뀌면 어긋날 수 있으므로 심볼 이름으로 다시 찾는다.

---

## A. 프로젝트 및 작업 개요

### 목적
같은 미스터리를 플레이어의 영어 수준에 맞춰 세 가지 영어로 경험하게 한다. **영어의 난이도만 바뀌고 사건·퍼즐·정답·보상은 모두 같다.** 어려운 영어를 주는 것과 불친절한 UI를 만드는 것은 다르다 — Master에서도 조작 안내는 명확해야 한다.

### 난이도 3단계 (확정)
| 난이도 | 화면 설명(영어, 프로필 생성 카드) | 의미 |
|---|---|---|
| **Rookie** (기본값) | Short English sentences. Easy words. Clear clues and simple explanations. | 짧은 문장, 쉬운 단어, 명확한 단서 |
| **Junior** | Everyday English. More detailed sentences. Connect clues to understand the mystery. | 일상 영어, 더 자세한 문장, 단서 연결 |
| **Master** | Advanced English. Richer vocabulary. More indirect clues and challenging reading. | 고급 영어, 풍부한 어휘, 간접적인 단서 |

### 난이도별로 바뀌는 것
스토리 문장 · 대사 · 편지 · 단서 설명 · 퍼즐에 표시되는 문장 · 선택지의 영어 표현 · 힌트 문구 · 힌트 제공 방식 · 사건 관련 안내 문구 · 영어 어휘 수준

### 난이도와 관계없이 같은 것 (불변 조건)
스토리의 사실관계 · 사건의 결말 · 퍼즐 구조 · 퍼즐 단계 수 · 선택지 수와 순서 · 정답 · 증거 ID · 보상(XP·코인·배지) · 시즌 진행 순서

### 프로필 정책 (확정)
프로필 생성 시 ① 아바타 BOY/GIRL ② 탐정 이름 ③ 난이도 Rookie/Junior/Master. 기본값 Rookie. 난이도 선택은 **별도 BottomSheet가 아니라 기존 CREATE YOUR DETECTIVE 화면에 통합된 심플한 카드형 UI**, 각 카드에 위 영어 설명.

### 시즌 난이도 변경 정책 (확정)
- **시즌 시작 전**: 자유롭게 변경.
- **시즌 진행 중**: 변경하려면 현재 진행 중인 시즌 초기화가 필요. 확인 화면을 띄우고 동의할 때만 초기화. 취소하면 진행 기록·난이도 모두 그대로. 완료된 다른 시즌 기록은 보존.
- **시즌 완료 후**: 다음 시즌의 난이도를 바꿀지 묻는다. 완료 시즌은 초기화하지 않는다. 새 난이도는 다음 시즌부터. 이 안내는 반복 표시하지 않는다.

### 개발자 모드 정책 (확정)
- 일반 사용자 진행 데이터와 분리.
- 진입 시 Detective Name `TESTER`, Avatar `BOY`, Difficulty는 개발자 모드 안에서 자유 선택. 일반 사용자 프로필은 변경하지 않음.
- **개발자 모드에 새로 진입할 때마다 테스트 진행 상태 초기화**. 같은 개발자 모드 세션 안에서는 진행 상태 유지.
  - 예: 진입 → Paris Case 03 → Mission 2까지 → 종료 → 재진입 → Paris Case 03 → Mission 1부터.
- 테스트용 XP·증거·힌트·퍼즐 상태가 일반 사용자 데이터에 영향을 주면 안 됨.
- 프로필 초기화 기능(Game Master의 다음 플레이어용 초기화)은 변경·삭제하지 않음.

---

## B. 현재 프로젝트 구조 (2026-10-27 조사)

### B-0. 저장소 상태
- [확인] 브랜치 `main`, HEAD `0cdbe8afb4fab91601dae67a0e65c573d441d409` ("시즌2 미션 6개 초간단 버전…").
- [확인] 미커밋 변경: `.claude/settings.json`(untracked) 하나뿐. 난이도 작업과 무관 — 커밋에 포함하지 않는다.
- [확인] 코드에 난이도 개념이 전혀 없다. `lib/`에서 difficulty/rookie/junior 검색 결과 0건("Master"는 Game Master·Master Detective 배지·스토리 문장뿐).
- [확인] `rig`(OpenRig CLI)는 이 PC에 설치되어 있지 않다 — 작업 기록은 이 문서와 git 커밋으로 남긴다.
- 개발 지침: `CLAUDE.md`(디자인·테스트·Season 2 bible 규칙), `PROJECT_CONTEXT.md`(작업 기억), Season 2는 `docs/SEASON2_PARIS_STORY_BIBLE.md` 먼저 읽기.

### B-1. 시즌·사건·미션 ID
- [확인] 시즌 ID: `SeasonIds.london = 's1_london'`, `SeasonIds.paris = 's2_paris'` — `lib/data/models/season.dart:87-93`, `lib/core/constants/app_constants.dart:18`.
- [확인] 사건 ID: London `ep01`~`ep12`, Paris `s2_ep01`~`s2_ep12`.
- [확인] 미션 ID: London Case 01 = `m01`~`m05`, `final`(단서 `c01…`, 증거 `e01…`) / London Case 02~12 = `epNN_m1`~`m3`, `epNN_final`, 증거 `epNN_e4` 등 / Paris = `s2_epNN_m1`~`m3`, `s2_epNN_final`.
- [확인] 카탈로그: `SeasonCatalog.all = [season1Content, season2Content]` — `lib/data/mock/season_catalog.dart:436`. Paris는 `released: true`(`:324`). 주석(`:317-318`, `season2_mock.dart:42-44`)의 "unreleased"는 오래된 설명.

### B-2. 탐정 프로필 (아바타·이름)
- [확인] 모델 `DetectiveProfile` — `lib/data/models/profile.dart:67-147`: `id`(16진 무작위, `^[0-9a-f]{8,64}$`), `origin`, `walletBackfill`, `detectiveName?`, `avatar?`(`DetectiveAvatar.boy/girl`), `createdAt?`. `isCreated` = 이름이 있음(`:93`).
- [확인] JSON(`:121-128`): enum은 `.name`. `fromJson`(`:132-146`)은 관대함 — 모르는 enum 값은 기본값, 추가 키는 무시.
- [확인] 래퍼 `DetectiveRecord` `{schema: 1, profile, held?}`(`:154-184`). `schema`는 쓰기만 하고 읽지 않음.
- [확인] `copyWith`(`:101-115`)는 `??` 방식 — 필드를 null로 되돌릴 수 없음.
- [확인] 저장 키 `lm.detective.v1`(`app_constants.dart:46`), `ProfileStore` — `lib/data/repositories/profile_store.dart:71-94`. 시작 시 `bootstrap()` → `LegacyMigrator.run()`(`main.dart:27`).
- [확인] Provider — `lib/features/game/game_providers.dart`: `profileStoreProvider`(:30), `profileSessionProvider`(:34), `detectiveProfileProvider`(:44-64, 변경은 `change()`만, :50-57).
- [확인] 생성: `lib/features/onboarding/register_screen.dart`(CREATE YOUR DETECTIVE + `DetectiveDesk` :84) → `GameController.createDetective`(`game_controller.dart:144-155`, 이미 있으면 거부). 폼 위젯: `detective_form.dart`의 `AvatarChoice`(:42), `DetectiveNameLine`(:147, 최대 12자).
- [확인] 변경: `/detective` = `detective_settings_screen.dart:36-53`(이름·아바타). `renameDetective`(`game_controller.dart:160-177`)는 모든 시즌의 모든 사건 저장의 이름까지 고침 — **이름이 프로필과 각 `GameProgress.detectiveName`에 이중 저장**.
- [확인] 보류 화면 `detective_hold_screen.dart`(여러 탐정 → 보호자 선택), `ProfileStore.resolveHold` → `LegacyMigrator.resolve`(`legacy_migrator.dart:67-79`, 아바타 없는 새 프로필).

### B-3. 진행 데이터 저장 구조
- [확인] 프로필 네임스페이스: `lm.p.<id>.` + 예전 키에서 `lm.` 제거(`app_constants.dart:56-63`).

| 데이터 | 키 | 근거 |
|---|---|---|
| London ep01 사건 저장 | `lm.p.<id>.progress.v1` (접미사 없음) | `app_constants.dart:11, 34-35` |
| 그 밖의 사건 | `lm.p.<id>.progress.v1.<episodeId>` (예: `.ep02`, `.s2_ep03`) | 같음 |
| London 시즌 기록 | `lm.p.<id>.season.v1` | `:15, 23-24` |
| Paris 시즌 기록 | `lm.p.<id>.season.v1.s2_paris` | 같음 |
| 선택한 시즌 | `lm.p.<id>.selectedSeason.v1` (`{seasonId}`) | `:27`, `progress_repository.dart:165-171` |
| 지갑(시즌 공용) | `lm.p.<id>.wallet.v1` | `:30` |
| 저장 저널 | `lm.p.<id>.journal.v1` | `:71`, `save_journal.dart` |
| 네임스페이스 밖 | `lm.onboarding.v1.<id>`, `lm.settings.sound`, `lm.migration.legacy.v1`, `lm.profiles.v1`, 예전 `lm.progress.v1*`/`lm.season.v1`/`lm.wallet.v1` | `:39-83` |

- [확인] 사건별 `GameProgress`(`lib/data/models/game_progress.dart:302-324`): 이름, introSeen, completedMissionIds, attempts, wrongAnswers, hintsUsed, 시간, **badgeIds**, lookedUpWords, xpRules, behavior, examined, revealed, **puzzleStates**, 시작/완료 시각, playMillis. **XP 총합은 저장하지 않고 계산**, **증거·단서는 `completedMissionIds`에서 파생**(`:163-165`).
- [확인] 시즌별 `SeasonProgress`(`lib/data/models/season_progress.dart:11-58`): `activeEpisodeId`, `solvedEpisodeIds`, `prologueSeen`. `fromJson` 관대.
- [확인] 지갑 `Wallet`(`lib/data/models/wallet.dart`): 항목 원장(`mission:<missionId>`, `tip:<missionId>:<n>`, `start`, `rewarded-ad:<id>`), 잔액 = 항목 합(`:87`). 미션 보상은 평생 1회(`wallet_controller.dart:90-98`).
- [확인] 여러 키 저장은 `SaveJournal` + `repo.transaction`(`progress_repository.dart:88-98`)으로 원자적.
- [확인] 저장소 Provider는 하나: `progressRepositoryProvider`(`game_providers.dart:67-74`) → `SharedPrefsProgressRepository(prefs, profileId, legacyFallback)`. `SeasonNotifier`·`SelectedSeasonNotifier`·`WalletController`·Archive가 모두 이것을 통한다. 메모리 구현 `InMemoryProgressRepository`(`progress_repository.dart:205`) 존재.

### B-4. 초기화 동작 (현재)
- [확인] **Play again**(`game_controller.dart:395-398`): 열린 사건 키만 `resetCase()`.
- [확인] **NEW ADVENTURE**(`_wipe`, `game_controller.dart:423-437`): `repo.clear()`(`progress_repository.dart:192-201`)가 `lm.p.<id>.*` 중 journal·conflicts 외 전부 삭제 → 새 지갑(시작 코인) → ep01에 이름 → 선택 시즌 London. 프로필 id·이름·아바타 유지.
- [확인] **Game Master 다음 플레이어 초기화**(`playtest_tools.dart:110-115`): `resetAll` + 프로필 `startedOver()` + How to Play 기록 삭제 + `wipeLegacy`. **이 기능은 난이도 작업에서 바꾸지 않는다.**
- [확인] **한 시즌만 초기화하는 기능은 없다.**

### B-5. 시즌 완료·다음 시즌 해금
- [확인] 사건 해결 → `GameController._markCaseSolved` → `SeasonNotifier.markSolved`(`game_controller.dart:335,350,364-392`, `game_providers.dart:350-353`).
- [확인] 시즌 완료는 저장하지 않고 매번 계산: `SeasonAvailability.isCompleted`(`game_providers.dart:174`), `SeasonOverview.complete`(`lib/features/season/season_overview.dart:92`) — 모든 사건 해결 + `plannedCases` 이상 존재.
- [확인] 해금: `SeasonAvailability.of`(`game_providers.dart:191-227`) — 첫 시즌 항상 열림, 다음 시즌은 이전 시즌의 계획 사건이 모두 있고 **마지막 사건이 해결**되면 열림. 상태 `locked/comingSoon/open`.
- [확인] 완료 표시: Season Board `_Completed`(`lib/features/season/season_screen.dart:741-764`, `overview.complete`일 때 :536-537) + GO TO PARIS / COMING SOON(:539-560). 마지막 사건 Case Closed의 `_SeasonFinale` + GO TO PARIS(`lib/features/result/case_solved_screen.dart:145-148,190-196`). World Archive(`world_archive_screen.dart:80`).
- [확인] 활성 시즌: `SelectedSeasonNotifier`(`game_providers.dart:287-310`) — 저장된 시즌이 `canEnter`일 때만 재개, 아니면 London. 전환은 `GameController.openSeason`(`game_controller.dart:110-128`) ← `SeasonActions.goToSeason`(`season_actions.dart:38-44`), World Archive(`:135-140`).
- [확인] Paris 프롤로그: `ParisPrologueScreen`(`lib/features/season/paris_prologue.dart`, `season_prologue_screen.dart`의 part). Season Cover BEGIN → `Routes.parisPrologue`(`season_screen.dart:157-161`). `prologueSeen`은 마지막 장면 + Paris 선택 상태에서만 저장(`paris_prologue.dart:74,87`). 텍스트 `season2PrologueJson`(`lib/data/mock/season2/season2_mock.dart:74-110`). London 프롤로그 텍스트 `season1InfoJson['prologue']`(`season1_mock.dart`) → `SeasonPrologue.fromJson`(`season.dart:67-82`).

### B-6. 개발자(운영자) 모드
- [확인] 빌드 게이트: `operatorToolsInBuild = kDebugMode || bool.fromEnvironment('LM_PLAYTEST')`(`game_providers.dart:448`), `playtestToolsEnabled`(`lib/features/game_master/playtest_tools.dart:11`).
- [확인] 진입: Start 화면 `_openGameMaster` → `ParentGate.show`(곱셈) → `gameMasterAccessProvider.grant()` → `/game-master`(`start_screen.dart:148-156`, 가드 `app_router.dart:121-123`). UI 이름은 "GAME MASTER", "플레이 테스트 도구", "OPERATOR MODE", "SEASON PREVIEW", "사건 바로가기". 코드에 "developer"라는 말은 없음.
- [확인] **명시적 종료가 없다.** 스위치는 모두 저장 안 되는 메모리 `Notifier`(`game_providers.dart:436-478`) — 앱 재시작 시 꺼짐.
- [확인] `startPlaytestAt`("CASE NN부터", `playtest_tools.dart:24-61`): **London 전용**, `newAdventure()`로 **실제 프로필 저장을 지우고**, 이전 사건들을 해결 상태로 실제 저장에 기록. `playtestDetectiveName = 'TESTER'`(`:14`)는 탐정이 없을 때 쓰는 이름.
- [확인] `jumpToCase`("사건 바로가기", `:86-98`): **Paris 지원**, 저장을 지우지 않지만 SEASON PREVIEW·OPERATOR MODE를 켜고 **실제 `selectedSeason.v1`과 시즌 `activeEpisodeId`를 저장**. 이후 미션 해결은 실제 저장(XP·코인·배지)에 기록.
- [확인] OPERATOR MODE(`operatorAccessProvider`): 선택 시즌의 모든 사건 열림(`game_providers.dart:367-377`), 해결은 일반 플레이처럼 저장.
- [확인] **현재 개발/테스트 상태는 일반 사용자 데이터와 전혀 격리되어 있지 않다.**
- [확인] 기존 override 지점: `main.dart:40-44`(`sharedPreferencesProvider`·`episodeRepositoryProvider`·`allEpisodesProvider`), `DeviceDetectiveGate`/`detective_hold_screen.dart:50-51`(`profileSessionProvider.overrideWithValue`), 중첩 `ProviderScope` 선례 `how_to_play_screen.dart:101-104`.

### B-7. 콘텐츠 데이터 모델
- [확인] **두 가지 형태가 섞여 있다.**
  1. 사건·미션 = `const Map<String, dynamic>` JSON(`lib/data/mock/season1/episodeNN_mock.dart`, `lib/data/mock/season2/episodeNN_mock.dart`) → `Episode.fromJson`(`lib/data/models/episode.dart:89`), `Mission.fromJson`(`lib/data/models/mission.dart:511`).
  2. 약 60개 부가 테이블 = 타입이 있는 `const` Dart 객체(fromJson 없음). `SeasonContent`(`season_catalog.dart:60-298`)에 미션/사건/증거 ID → 객체 맵으로 등록, 정적 조회 `SeasonCatalog.xxx(Mission m) => ofMission(m.id)?.table[m.id]`(`:490-665`). `lib/features`에서 약 112곳이 호출.
- [확인] JSON 쪽 영어 텍스트 필드:
  - `Episode`(`episode.dart:31-64`): title, synopsis, objectives, intro, glossary, caseSummary, keyWords, hook, place.
  - `Mission`(`mission.dart:414-476`): title, location, story, letterIntro, letter, question, prompt, options, **hints**(:446), successMessage, transition, **feedback**(키 = 오답 문자열), orderFeedback.
  - `ChoiceOption`(`:220-234`): label, feedback, altText. `Clue`(`:255-263`): title, note(**value는 정답 조각**). `Evidence`(`:288-309`): name, description, inscription(**일부는 퍼즐 데이터**). `EvidenceRecall`(`:335-357`).
- [확인] 타입 객체 쪽 텍스트: `dialogue.dart`, `case_talk.dart`(TalkLine·TalkSpeaker·TalkQuestion·TalkPresent·EndingLine), `easy_steps.dart`(EasyStep say/button/question/hints/wrong/tell/done, `defaultWrong` :385), `discovery.dart`, 각종 `*_puzzles.dart`·`scene_*.dart`(title/label/line/question/wrongLine/missLine/feedback).
- [확인] 구조(정답) 필드: `answer`, `acceptedAnswers`, `codeLength`, `dialSymbols`, `nextMissionId`, 옵션 id·순서, `Clue.value`, 증거 id, 각 퍼즐 모델의 정답 필드.
- [확인] **텍스트이면서 정답처럼 동작하는 것**: `Mission.feedback`의 키(오답 문자열), `Mission.answerLabel`(`:498`, 옵션 label로 GM 정답표 생성), Season 2 Discovery 제목이 `successMessage`에서 만들어짐(`season2_discoveries.dart:68-74`), 일부 `Evidence.inscription`(예: 'BUCKINGHAM PALACE' 테스트 고정).
- [확인] 로딩: `MockEpisodeRepository`(`lib/data/repositories/episode_repository.dart:11-56`) → `main.dart:31-34`에서 전부 미리 로드 → `allEpisodesProvider` override → `episodeCatalogProvider`(선택 시즌 필터, `game_providers.dart:91-94`) → `currentEpisodeProvider`(:383).
- [확인] 위젯에 하드코딩된 영어: `lib/features/mission/` 아래 여러 단어 영어 리터럴 약 360개(대부분 버튼·접근성 라벨, 일부 퍼즐 내용 설명 — 예: `clockwork_garden.dart:1194`, `star_records.dart:1050`, `final_mission_screen.dart:1152-1548`). [추정] 대부분은 난이도와 무관한 조작 안내로 유지 가능.

### B-8. 힌트
- [확인] `Mission.hints: List<String>`(최대 2, 약 → 직접), `AppConstants.maxHints = 2`(`app_constants.dart:90`), `season_content_test.dart:42`가 미션당 1~2개 강제.
- [확인] 가격 `tipPrices = [0, 20]`(`:126`) — Tip 1 무료, Tip 2 20코인, 코인 부족하면 무료 "help"(`answer_feedback.dart:486-488`). 본 힌트 수는 `GameProgress.hintsUsed`에 미션별 저장(`game_controller.dart:233-239`).
- [확인] 표시: `TipsPanel`(`answer_feedback.dart:490-520`), `DetectiveTipNotes`(`lib/widgets/detective_tips.dart:21-56`), `tip_shop.dart`.
- [확인] EasySteps 힌트(`EasyStep.hints`)는 별개 — 무료·무제한, 다 보면 정답 위치가 빛남(`easy_steps.dart:411`, `widgets/easy_steps.dart:140-167`).
- [참고] `PROJECT_CONTEXT.md` 일부(XP 규칙 3, "힌트 무료")는 현재 코드(XP 규칙 4 = 30/60, Tip 2 유료)와 다르다. 코드가 기준.

### B-9. 단어 뜻(글로서리)
- [확인] 사건별 `glossary` 맵(영어 소문자 → 한국어), `Episode.meaningOf`(`episode.dart:75-78`, 구두점 제거·`'s` 처리). 키 규칙 테스트 `season_content_test.dart:82-87`.
- [확인] **롱프레스만**(탭은 조회 아님) — `lib/widgets/glossary_text.dart:16-21`, 단어별 `LongPressGestureRecognizer`(:209-210), 단어 카드 `showWordMeaning`(:253-294), 사용 glossary = `widget.episode ?? currentEpisodeProvider`(:148).
- [확인] 기록: `lookUpAndShowWord`(:240) → `GameController.lookUpWord`(`game_controller.dart:242-251`) → `GameProgress.lookedUpWords` → 부모 보고서.
- [추정] 텍스트와 glossary의 일치를 검사하는 테스트는 없다.

### B-10. 표시 시점 치환 (선례)
- [확인] `DetectiveName.placeholder = '{detectiveName}'`(`lib/data/models/detective_name.dart:34`), 표시 시점에만 치환(`glossary_text.dart:174-194`, `story_scene_screen.dart:209`, `mission_screen.dart:2172`). 저장 데이터는 템플릿 유지 — **런타임 텍스트 선택의 유일한 기존 선례**.

### B-11. 콘텐츠를 고정하는 테스트
- [확인] `test/final_small_pass_test.dart:233-246`: London 사건(ep06·ep08 제외) `toJson()`의 FNV-1a 해시 고정, `:215-230` 정확한 문자열 단언.
- [확인] `test/personalized_lines.dart`: 이름 개인화 줄 목록 + `withoutNames`.
- [확인] `test/season_content_test.dart`: 힌트가 정답 미포함(96-111), 인트로·스토리에 정답 미포함(113-130), JSON 왕복 무손실(89-91), 옵션 3개 이상.
- [확인] `test/learning_objectives_test.dart:51-58`: `expressions`가 미션 영어의 부분 문자열이어야 함.
- 관련 테스트(프로필·시즌·도구): `test/profile_migration_test.dart`, `profile_reset_test.dart`, `single_detective_test.dart`, `season_flow_test.dart`, `playtest_tools_test.dart`, `detective_address_test.dart`, `detective_report_test.dart`.

### B-12. 마이그레이션 구조
- [확인] `LegacyMigrator`(`lib/data/repositories/legacy_migrator.dart:10-29`): 기록 있음 → 사용 / 계정 빌드 목록 → 변환 / 레거시 키 → 복사·검증·실패 시 safe mode(`legacyFallback`) / 여러 탐정 → 보류.
- [확인] 버전은 키 이름(`.v1`)뿐. 필드 단위 마이그레이션은 `fromJson`의 관대한 기본값(`GameProgress.fromJson` :248-279 등).
- [확인] safe mode에서 London 키가 없으면 예전 원본 키를 읽는다(`progress_repository.dart:114,153`).
- [추정] 새 선택 필드는 옛 저장에서 기본값으로 읽힌다. 단, **이전 빌드가 다시 저장하면 새 필드는 사라진다**(모든 `toJson`이 고정된 키 목록만 씀).

---

## C. 확정된 설계 (정책 → 동작)

### C-1. 난이도 정책
- 3단계, 기본 Rookie(섹션 A). 불변 조건(섹션 A)은 테스트로 강제한다(D-4).
- 난이도는 **시즌 단위로 고정**된다. 한 시즌을 플레이하는 동안 그 시즌의 텍스트 난이도는 바뀌지 않는다(바꾸려면 C-2의 초기화).

### C-2. 시즌 난이도 변경 정책 — 상태 정의 (PART 3에서 **APPROVED** 정책으로 확정·구현 — 아래 표는 PART 0 초안이고, 실제 규칙은 I의 Q7·Q9와 F의 PART 3 항목이 기준)
| 시즌 상태 | 판정 [제안] | 난이도 변경 시 동작 |
|---|---|---|
| 시작 전 | 시즌 기록 없음 또는 (`prologueSeen == false` && `solvedEpisodeIds` 비어 있음 && 그 시즌 어떤 사건 저장에도 `introSeen`/`completedMissionIds` 없음) | 프로필 난이도만 바꿈. 확인 없음 |
| 진행 중 | 시작됨 && 완료 아님 | 확인 화면 → 동의 시 **그 시즌만 초기화**하고 새 난이도로 고정. 취소 시 아무것도 바꾸지 않음 |
| 완료 | `SeasonAvailability.isCompleted` | 그 시즌은 바꾸지 않음. 다음 시즌 난이도로만 적용 |

- **시즌 완료 후 안내**: 마지막 사건을 닫은 뒤(다음 시즌이 존재할 때만) "Next season: keep Rookie / change" 를 한 번 묻는다. 물었다는 사실을 **완료된 시즌의 `SeasonProgress`에 저장**해 다시 묻지 않는다.

### C-3. 시즌 초기화 영향 범위 [제안 — 확인된 키 기준]
초기화 대상(그 시즌의 사건 목록에서 키를 만든다. **접두사 매칭 금지** — `progress.v1.`은 두 시즌을 모두 덮고, `season.v1`은 Paris 키의 접두사다):
- London: `lm.p.<id>.progress.v1`(ep01), `…progress.v1.ep02`~`.ep12`, `…season.v1`.
- Paris: `…progress.v1.s2_ep01`~`.s2_ep12`, `…season.v1.s2_paris`.

함께 사라지는 것: 그 시즌의 완료 미션·증거·단서(파생), 배지(`badgeIds`는 사건별), 찾아본 단어, 힌트 사용 기록, 퍼즐 상태, 플레이 시간, 프롤로그 시청 여부.
유지하는 것: 프로필(id·이름·아바타), 다른 시즌의 모든 기록, How to Play 시청 기록, 소리 설정, 레거시 원본 키.

주의 사항 [확인 → 대응 제안]:
1. **safe mode 레거시 되살아남**: London 키를 *삭제*하면 safe mode에서 예전 원본을 다시 읽는다(`progress_repository.dart:114,153`). → 삭제 대신 **빈 저장으로 덮어쓰기**(`GameProgress(detectiveName: name)`, 빈 `SeasonProgress`).
2. **ep01 자동 해결 표시**: `SeasonNotifier._fromSaves`가 ep01 사건 저장이 해결이면 시즌 기록에 해결로 다시 표시(`game_providers.dart:330-334`). → 사건 저장과 시즌 기록을 **한 트랜잭션**으로 함께 초기화.
3. **지갑은 시즌 공용**: 미션 코인은 평생 1회, 산 Tip은 "yours"로 남는다. → [미결정 Q3] 기본 제안은 지갑을 건드리지 않음(코인 착취 방지, 단순). 다시 푼 미션은 코인 0 — 기존 Play again과 같은 규칙.
4. **Paris 재잠금**: London 초기화는 Paris 해금(London ep12 해결)을 없앤다. 단 London이 "진행 중"이면 아직 미완료이므로 Paris는 원래 잠겨 있다 → 실제 영향 없음. Paris 초기화는 London에 영향 없음.
5. 이름은 유지(`_wipe(keepName:)`와 동일).
6. 모든 쓰기는 `repo.transaction` 안에서(원자성).

### C-4. 개발자 모드 정책 → 동작 [제안]
- 개발자 모드 = **별도의 메모리 전용 세션**. 일반 사용자의 `ProviderContainer`와 SharedPreferences 키를 쓰지 않는다.
- 진입할 때마다 새 세션(새 메모리 저장소) → 자동 초기화. 세션 안에서는 메모리에 유지. 종료하면 세션을 버리고 일반 화면으로 돌아감(일반 상태는 진입 전 그대로).
- TESTER / BOY / 난이도 자유 선택(개발자 세션 화면 안에서 언제든 바꿈, 확인·초기화 없음 [미결정 Q5]).
- 기존 Game Master 다음 플레이어 초기화(`resetForNextPlayer`)는 그대로 둔다.

---

## D. 기술 설계

### D-1. Difficulty enum — **PART 1 구현 완료**
실제 코드: `lib/data/models/difficulty.dart`
```dart
enum Difficulty {
  rookie('rookie', 'ROOKIE'),
  junior('junior', 'JUNIOR'),
  master('master', 'MASTER');

  final String storageId; // 저장 식별자 — 배포 후 절대 변경 금지
  final String label;     // 화면 표시 이름 — 바꿔도 저장에 영향 없음

  static const standard = Difficulty.rookie;
  static Difficulty? tryParse(Object? id); // 모르는 값·null·형식 오류 → null ("고정 안 됨" 표현용)
  static Difficulty parse(Object? id);     // 모르는 값·null·형식 오류 → rookie
}
```
- 저장은 enum `.name`이 아니라 **`storageId`**(PART 0 초안의 `.name` 저장에서 변경 — 화면 이름·enum 이름과 저장 식별자를 분리하라는 PART 1 요구). 대소문자 구분(`'Rookie'`은 모르는 값 → rookie).
- **PART 2에서 추가**: `final String blurb` — 프로필 생성 카드의 영어 설명(Rookie "Short English sentences. Easy words and simple clues." / Junior "Everyday English. Read clues and connect the dots." / Master "Advanced English. Read carefully and think deeply."). 화면 문구라 저장과 무관.
- `fallbackChain`은 **PART 5**에서 필요할 때 추가한다.

### D-2. 프로필 저장 구조 — **PART 1 구현 완료**
- `DetectiveProfile.difficulty`(`lib/data/models/profile.dart`, 기본 `Difficulty.standard` = rookie) — **"다음에 시작하는 시즌에 쓸 난이도"(기본값)**.
- 저장 키는 그대로 `lm.detective.v1`, 레코드 `schema`도 1 그대로. 프로필 JSON 예:
  `{"id":"…","origin":"legacy","walletBackfill":"done","detectiveName":"KIM","avatar":"girl","createdAt":"…","difficulty":"junior"}`
- `toJson`: **항상** `'difficulty': storageId` 기록(rookie도 기록 — 없음/rookie를 구분할 필요가 생겨도 안전). `fromJson`: `Difficulty.parse(json['difficulty'])`(없음·null·모르는 값 → rookie, 프로필 자체는 계속 읽힘).
- `copyWith(difficulty:)` 추가. `startedOver()`(Game Master 다음 플레이어 초기화)는 id만 남김 → rookie(코드 변경 없이 기본값).
- NEW ADVENTURE(`newAdventure`)는 `copyWith`로 프로필을 고치므로 **난이도 유지**(Q4 제안 기본값과 일치, 테스트로 고정). 단 NEW ADVENTURE는 시즌 기록을 모두 지우므로 시즌 고정값은 사라지고 프로필 난이도를 따른다.
- `LegacyMigrator`가 만드는 프로필(레거시 복사·계정 빌드 변환·보류 해결)은 난이도 인자가 없어 rookie.
- API: `DetectiveProfileNotifier.setDifficulty(Difficulty)`(`game_providers.dart`) — 다른 필드·`held` 목록 보존. `GameController.createDetective(name, avatar, {Difficulty difficulty = Difficulty.standard})` — **현재 UI는 인자를 넘기지 않음(PART 2에서 연결)**.

### D-3. 시즌별 난이도 적용 구조 — **저장·조회·고정 API는 PART 1 구현 완료, 고정 시점은 PART 3**
- 구현: `SeasonProgress.difficulty`(`Difficulty?`, `lib/data/models/season_progress.dart`) — 그 시즌에 **고정된** 난이도, null = 아직 고정 안 됨. `fromJson`은 `Difficulty.tryParse`(없음·모르는 값 → null), `toJson`은 **값이 있을 때만** `'difficulty'` 기록 → 고정 전 기록은 예전 JSON 모양 그대로. `difficultyOr(profileLevel)`, `copyWith(difficulty:)`.
- 키는 그대로: London `lm.p.<id>.season.v1`, Paris `lm.p.<id>.season.v1.s2_paris` → **두 시즌 독립**.
- API(`lib/features/game/game_providers.dart`):
  - `SeasonNotifier.fixDifficulty(Difficulty)` — **선택된 시즌**의 기록에 고정값 저장(같은 값이면 아무것도 쓰지 않음). 진행·해결·해금 불변. **아직 아무 화면도 호출하지 않는다.** 선택되지 않은 시즌을 고정해야 하면 PART 3에서 `repo.saveSeason(repo.loadSeason(id).copyWith(difficulty: d), id)` 또는 API 추가.
  - `seasonDifficultyProvider(seasonId)` — 고정값 ?? 프로필 난이도. 선택 시즌은 `seasonProvider`를 watch(즉시 반영), 다른 시즌은 저장소에서 읽기(그 시즌 기록이 바뀌어도 자동 갱신되지 않음 — 현재 다른 시즌 기록을 바꾸는 경로가 없어 문제없음, PART 3에서 다른 시즌을 고치면 `ref.invalidate` 필요).
  - `currentDifficultyProvider` — 선택 시즌의 실효 난이도. **콘텐츠 선택(PART 5)은 이것을 쓴다.**
  - 조회는 아무것도 저장하지 않는다(테스트로 고정: 조회 전후 SharedPreferences 스냅샷 동일, 조회만 한 시즌의 기록 키가 생기지 않음).
- `nextDifficultyAsked`(완료 후 안내 1회)는 PART 0 초안과 달리 **PART 1에서 추가하지 않았다** — 안내 기능(PART 3)과 함께 추가한다(지금 넣으면 쓰는 곳 없는 필드).
- **시즌의 실효 난이도**(PART 1) = `seasonProgress.difficulty ?? profile.difficulty`.
- **PART 3에서 변경(승인 정책 4)**: 실효 난이도 = 고정값 ?? (시즌 시작 전이면 프로필 난이도, 진행 기록이 있는 옛 시즌·완료 시즌이면 Rookie). 판정은 `SeasonLevel.of`/`seasonLevelProvider` — F의 PART 3 항목 참고. 고정 시점은 Story Intro 진입(`settleSeasonLevel`), `nextDifficultyAsked`는 `nextLevelAsked`라는 이름으로 PART 3에서 추가.
  - 시즌이 "시작"되는 순간(그 시즌의 첫 사건 인트로 진입 또는 프롤로그 완료 — PART 3에서 한 곳으로 정함) `seasonProgress.difficulty`가 비어 있으면 그때의 `profile.difficulty`로 고정.
  - 시작 전 시즌은 고정값이 없으므로 프로필 변경이 바로 반영된다(= "시즌 시작 전 자유 변경").
- Provider: `seasonDifficultyProvider(seasonId)` / `currentDifficultyProvider`(선택 시즌) — `seasonProvider`와 `detectiveProfileProvider`를 watch.
- **옛 저장**: 진행 중인 시즌에 `difficulty`가 없으면 → 프로필 난이도(없으면 rookie). 기존 사용자는 모두 rookie가 되며 D-5의 base = Rookie 제안과 합쳐 **기존 사용자의 화면은 바뀌지 않는다**.

### D-4. 난이도별 콘텐츠 ID 관리 [제안]
기존 ID 체계를 그대로 키로 쓴다. 새 ID 체계를 만들지 않는다.

| 콘텐츠 | 변형 키 | 변형 단위 |
|---|---|---|
| 사건 JSON(Episode 필드) | `caseId` | 필드 단위 패치 |
| 미션 JSON | `caseId` → `missions[]`/`finalMission`의 `id` | 필드 단위 패치(목록 원소는 `id`로 매칭: options·clue·evidence) |
| 부가 테이블(타입 객체) | 기존 테이블 키(미션 id / 사건 id / 증거 id) | **객체 통째로 교체** |
| 시즌 정보(프롤로그·outro·finale) | `seasonId` | 필드 단위 패치 |

- 위치: `lib/data/mock/season1/difficulty/` · `lib/data/mock/season2/difficulty/` 아래 사건별 파일(`ep03_junior.dart` 등) — 사건 단위로 PART 6·7을 나눠 커밋할 수 있게.
- JSON 패치는 **텍스트 키 화이트리스트**만 허용(title, story, letterIntro, letter, question, prompt, hints, successMessage, transition, feedback 값, orderFeedback, options[].label/feedback/altText, clue title/note, evidence name/description, intro, synopsis, caseSummary, hook, glossary 추가). 정답·구조 키(answer, acceptedAnswers, codeLength, dialSymbols, nextMissionId, id, value, type, 옵션 수·순서)는 패치에서 **금지 → 테스트 실패**.
- `Mission.feedback`의 **키는 오답 문자열**이라 바꾸지 않는다(값만 바꿈). `Clue.value`, 퍼즐 데이터를 담은 `inscription`은 정답 취급(변형 금지 목록을 PART 5에서 확정).
- 불변 조건 테스트(PART 5): 모든 난이도에서 `answer`·`acceptedAnswers`·옵션 수/순서·증거 ID·단서 value·`nextMissionId`·`codeLength`·미션 수·힌트 **개수**가 base와 같음. 타입 객체 교체는 모델별 `structureOf(x)`(정답·단계 수·선택지 수만 뽑는 함수) 비교로 검사.

### D-5. 영어 문장 선택 및 fallback 정책 [제안]
- **base 텍스트 = 현재 저장소의 텍스트 = Rookie** [미결정 Q1, 강력 추천].
  - 이유: ① 기존 사용자(난이도 없음 → rookie)의 화면이 전혀 바뀌지 않음, ② 기존 해시·추리 보호·학습 표현 테스트가 base에 대해 그대로 유효, ③ Paris는 최근 "VERY EASY"로 단순화되어 Rookie 성격과 맞음. PART 6 감사에서 London 일부가 Rookie보다 어렵다고 판단되면 그 부분만 Rookie 패치를 두는 것도 가능(base ≠ 실제 표시가 되므로 가급적 피하고, 대신 base 자체를 쉽게 고치는 것은 별도 승인 필요).
- 선택 위치: **콘텐츠를 만드는 시점**에 난이도를 반영한다(위젯은 난이도를 모른다 — "위젯에 미션별 분기 금지" 규칙 유지).
  - JSON: `MockEpisodeRepository.bundled(difficultyOf: (seasonId) → Difficulty)`가 base JSON에 패치를 깊은 병합한 뒤 `Episode.fromJson`. `allEpisodesProvider`가 시즌별 실효 난이도를 watch해 다시 만든다(`main.dart`의 선로딩 override를 "base 카탈로그 + 패치 함수"로 바꿈).
  - 타입 테이블: `Mission`·`Episode`에 직렬화하지 않는 `difficulty` 필드를 둔다(`toJson`에 넣지 않음 → 해시 불변). `SeasonCatalog.xxx(Mission m)`가 `ofMission(m.id)?.tableFor(m.difficulty)[m.id] ?? base` 로 찾는다 → **112개 호출부 수정 불필요**. 사건 ID로 찾는 테이블은 `Episode.difficulty`를 받는 오버로드.
- **fallback**: 필드(JSON) / 객체(타입 테이블) 단위로 `Master → Junior → base`, `Junior → base`. 변형이 없으면 조용히 아래 단계를 쓴다(게임은 항상 진행 가능). 디버그 빌드에서만 누락을 집계(PART 5의 커버리지 테스트가 표 H를 검증).
- 탐정 이름 플레이스홀더(`{detectiveName}`)는 모든 난이도에서 같은 규칙. 개인화 줄 목록(`test/personalized_lines.dart`)은 base 기준.
- Glossary: 난이도 패치는 base glossary에 **단어를 추가**(덮어쓰기 가능, 삭제 없음). Master에서 새로 쓴 어려운 단어는 반드시 glossary에 추가 → PART 5에서 "변형 텍스트의 지정 어휘가 glossary에 있다" 검사 도입 검토.
- 위젯 하드코딩 UI 문구(버튼·조작 안내·접근성 라벨)는 **난이도와 무관하게 동일** — "Master에서도 조작 안내는 명확" 원칙. 퍼즐 내용을 설명하는 하드코딩 문구만 PART 5에서 목록화해 데이터로 옮길지 결정.
- 파생 텍스트: Season 2 Discovery(`season2DiscoveriesOf`가 `successMessage`로 제목 생성)는 **난이도 적용된 미션으로 다시 만들어야** 한다. `answerLabel`은 GM 정답표용이라 base 사용 가능.

### D-6. 힌트 제공 정책 [제안]
- **불변**: 미션당 힌트 개수, 가격(`tipPrices`), XP·코인 규칙, `hintsUsed` 의미. → 난이도에 따라 보상·경제가 달라지지 않음(불변 조건 "보상").
- **변하는 것**: 문구와 직접성.
  - Rookie: Tip 1 = 볼 곳 + 핵심 단어를 쉬운 말로, Tip 2 = 정답 바로 앞까지(정답 문자열 금지는 모든 난이도 공통).
  - Junior: 현재 TYPE B 규칙(Tip 1 = 무엇을 비교할지, Tip 2 = 어디를 볼지/Notebook Case 번호).
  - Master: Tip 1 = 간접적 질문, Tip 2 = 위치 지시(조작 방법은 명확하게).
- **제공 방식**(UI) [미결정 Q2]: Rookie에서 오답 시트의 기본 강조를 GET A TIP으로, Junior·Master는 TRY AGAIN — 개수·가격은 같음. 원치 않으면 문구만 다르게.
- EasySteps 힌트(무료·무제한, 마지막에 정답 위치 강조)는 구조이므로 모든 난이도 동일, 문구만 변형.

### D-7. 개발자 테스트 세션 격리 [제안]
구현 방식: **개발자 세션 전용 중첩 `ProviderScope`**(`DevSessionScope`).
- 진입: Game Master → "DEVELOPER MODE" 시작 → 새 `ProviderScope(key: ValueKey(sessionNo), overrides: [...])`로 앱(라우터 포함)을 감싼다. `sessionNo`가 바뀌면 컨테이너가 새로 만들어져 **진입마다 초기화**.
- override:
  - `progressRepositoryProvider` → 새 `InMemoryProgressRepository()`(사건·시즌·선택 시즌·지갑 모두 메모리). SharedPreferences에 쓰지 않음.
  - `profileSessionProvider` / `detectiveProfileProvider` → 메모리 전용 TESTER 프로필(`avatar: boy`, 난이도 선택값, 고정 dev id). `ProfileStore`에 쓰지 않도록 `change()`가 메모리만 갱신하는 dev 구현.
  - How to Play 시청 여부(`lm.onboarding.v1.<id>`를 prefs로 직접 씀) → dev에서는 "본 것"으로 override.
  - 운영 스위치(OPERATOR MODE·SEASON PREVIEW)는 dev 세션 안에서 켜 둔다.
- 종료: "EXIT DEVELOPER MODE" → dev 스코프 제거 → 일반 컨테이너(진입 전 상태 그대로)로 복귀, 라우터는 `/`.
- 주의 [추정, PART 4에서 확인]: `routerProvider`는 자기 `ref`로 provider를 읽으므로 **라우터도 dev 스코프 안에서 다시 만들어야** 한다. `SoundEnabledNotifier`는 prefs 직접 사용(기기 설정이라 공유 허용). `ProfileStore.wipeLegacy`·`resetForNextPlayer`는 dev 세션에서 노출하지 않음. `startPlaytestAt`·`jumpToCase`는 dev 세션 안에서 실행되면 메모리 저장소에만 쓴다 → 일반 데이터 보호.
- 앱 재시작 시 dev 세션은 사라진다(메모리) — "재진입 시 초기화" 정책과 일치.
- 대안(비추천): 고정 dev 프로필 id 네임스페이스 `lm.p.<devId>.*`에 저장하고 진입 시 삭제 — 디스크에 테스트 흔적이 남고 키 정리 누락 위험.

### D-8. 기존 데이터 마이그레이션 [제안]
- 키 버전 올리지 않음(`lm.detective.v1`, `season.v1` 유지). 새 필드는 **선택 필드 + 관대한 기본값**.
  - 프로필 `difficulty` 없음 → `rookie`.
  - `SeasonProgress.difficulty` 없음 → 실효 난이도 = 프로필 난이도(=rookie). 진행 중 시즌의 사용자는 base(Rookie) 텍스트를 계속 봄 → **화면·진행 불변**.
  - `nextDifficultyAsked` 없음 → false. **이미 완료된 시즌**(예: London 완료 후 Paris 진행 중)에 안내가 갑자기 뜨지 않도록, 마이그레이션 규칙: 다음 시즌이 이미 시작된 완료 시즌은 "이미 물은 것"으로 간주(저장하지 않고 계산) [제안].
- `DetectiveRecord.schema`는 1 유지(읽지 않으므로 올려도 효과 없음).
- 다운그레이드(이전 빌드가 다시 저장)하면 새 필드가 사라진다 — 앱스토어 배포에서는 드묾. 사라져도 기본값 rookie로 안전하게 읽힘 → 허용.
- **PART 1 결과**: 위 규칙대로 구현. 키·스키마 변경 없음, 마이그레이션 코드 없음(읽을 때 기본값). 옛 프로필은 다음 저장 때 `"difficulty":"rookie"`가 붙고 다른 필드는 그대로, 옛 시즌 기록은 고정될 때까지 JSON이 바이트 단위로 같다. 테스트는 새 파일 `test/difficulty_persistence_test.dart`에 모았다(기존 `profile_migration_test`/`single_detective_test`는 수정 불필요 — 전체 회귀 통과).

---

## E. PART별 진행 현황

| PART | 내용 | 상태 |
|---|---|---|
| PART 0 | 조사 및 설계 문서 | **COMPLETED** (2026-10-27) |
| PART 1 | 난이도 모델 및 저장 구조 | **COMPLETED** (2026-10-27) |
| PART 2 | 프로필 생성 난이도 UI | **COMPLETED** (2026-10-27) |
| PART 3 | 시즌 난이도 변경 및 초기화 정책 | **COMPLETED** (2026-10-27) |
| PART 4 | 개발자 모드 개선 | **COMPLETED** (2026-10-27) |
| PART 5 | 난이도별 영어 콘텐츠 시스템 | NOT STARTED |
| PART 6 | London Season 1 콘텐츠 적용 (Case 단위 세분 가능) | NOT STARTED |
| PART 7 | Paris Season 2 콘텐츠 적용 및 최종 검증 (Case 단위 세분 가능) | NOT STARTED |

상태 값: NOT STARTED / IN PROGRESS / COMPLETED / BLOCKED. 테스트 실패나 미해결 문제가 있으면 COMPLETED로 바꾸지 않는다.

### 각 PART 범위 요약
- **PART 1**: `Difficulty` enum, `DetectiveProfile.difficulty`, `SeasonProgress.difficulty`/`nextDifficultyAsked`, 실효 난이도 provider, 마이그레이션 테스트. **UI·콘텐츠 변경 없음.**
- **PART 2**: CREATE YOUR DETECTIVE 화면에 난이도 카드 3개(기본 Rookie, 영어 설명), `createDetective`에 난이도 전달. 360×640·390×844·글자 1.3배 확인. 디자인 규칙은 `CLAUDE.md` 2~19절.
- **PART 3**: 시즌 상태 판정(시작 전/진행 중/완료), `/detective` 설정에서 난이도 변경 + 진행 중 확인 화면 + 단일 시즌 초기화(C-3), 시즌 완료 후 1회 안내(Case Closed 피날레 또는 Season Completed 보드), 시즌 시작 시 난이도 고정.
- **PART 4**: 개발자 세션 격리(D-7), TESTER/BOY, 난이도 자유 선택, 진입마다 초기화, 종료 동작. 기존 다음 플레이어 초기화 유지.
- **PART 5**: 패치/변형 로더(D-4·D-5), `Mission/Episode.difficulty`, `SeasonCatalog` 조회 확장, Season 2 Discovery 재생성, 불변 조건·anti-giveaway·커버리지 테스트, 하드코딩 문구 목록화, 힌트 제공 방식(D-6). 콘텐츠는 샘플 1개 미션만(파이프라인 검증용).
- **PART 6**: London Case 01~12(+ 시즌 프롤로그) Junior·Master 텍스트 작성. 추리 보호 규칙(PROJECT_CONTEXT *핵심 Reasoning 구조*, *Continuity Guardrails*)을 모든 난이도에서 지킨다.
- **PART 7**: Paris Case 01~12(+ Paris 프롤로그) Junior·Master. `docs/SEASON2_PARIS_STORY_BIBLE.md` 우선 확인. 최종 전체 회귀.

---

## F. 작업 이력

### PART 0 — 조사 및 설계 문서
- **작업 날짜**: 2026-10-27
- **구현 내용**: 코드 수정 없음. 프로필·저장·마이그레이션·시즌 해금·개발자 도구·콘텐츠·힌트·글로서리 구조 조사(섹션 B), 설계(섹션 C·D), PART 계획(E), 인수인계(G), 콘텐츠 진행표(H) 작성. `PROJECT_CONTEXT.md`에 난이도 시스템 섹션 추가.
- **변경 파일**: `docs/DIFFICULTY_IMPLEMENTATION.md`(신규), `PROJECT_CONTEXT.md`(섹션 추가·Next Goal 한 줄·Change Log 한 줄)
- **테스트 결과**: 실행하지 않음(문서만 변경, Dart 소스·테스트 무변경). `flutter analyze`도 실행하지 않음.
- **커밋 해시**: `042afac9e5142bd0bc9c4c880012255cafcf851b` ("난이도 시스템 PART 0: 조사 및 설계 인수인계 문서") — PART 1 커밋에서 기록.
- **남은 위험**: 섹션 I(미결정 사항)와 D의 [추정] 항목. 특히 base = Rookie 결정(Q1)이 PART 5 이전에 필요.

### PART 1 — 난이도 모델 및 저장 구조
- **작업 날짜**: 2026-10-27
- **시작 상태**: 브랜치 `main`, HEAD `042afac`(PART 0), 미커밋 `.claude/settings.json`만(커밋하지 않음). 문서 B의 경로·줄 번호와 코드가 일치함을 확인(차이 없음).
- **구현 내용**:
  - `Difficulty` enum(D-1): 저장 식별자(`storageId`)와 표시 이름(`label`) 분리, `parse`(→ rookie)/`tryParse`(→ null).
  - 프로필 기본 난이도(D-2): `DetectiveProfile.difficulty`, JSON `difficulty`, `copyWith`, `setDifficulty`, `createDetective`의 선택 인자(UI 미연결).
  - 시즌 고정 난이도(D-3): `SeasonProgress.difficulty`(고정 시에만 기록), `difficultyOr`, `SeasonNotifier.fixDifficulty`(호출하는 화면 없음), `seasonDifficultyProvider(seasonId)`, `currentDifficultyProvider`.
  - PART 0 설계와 다른 점: 저장을 `.name` 대신 `storageId`로, `nextDifficultyAsked`·`blurb`·`fallbackChain`은 쓰는 PART(3·2·5)로 미룸.
- **변경 파일**:
  - 신규 `lib/data/models/difficulty.dart`, `test/difficulty_persistence_test.dart`
  - 수정 `lib/data/models/profile.dart`, `lib/data/models/season_progress.dart`, `lib/features/game/game_providers.dart`, `lib/features/game/game_controller.dart`(createDetective 인자만)
  - 문서 `docs/DIFFICULTY_IMPLEMENTATION.md`, `PROJECT_CONTEXT.md`
- **테스트 결과**(실제 실행):
  - `flutter test test/difficulty_persistence_test.dart` → **21 passed**. 검증: enum 직렬화·모르는 값, 난이도 없는 옛 프로필 → rookie·다른 필드 불변, rookie/junior/master 프로필, 모르는 문자열, 옛 시즌 기록(고정 전 JSON 모양 유지), 시즌 난이도 없음 → 프로필 따름, London junior/Paris master 독립, 프로필 변경 후 시즌 고정값 유지, 저장·복원 5회 반복 동일, 앱 재시작 후 동일, 고정해도 진행·해결·해금 불변, 조회는 저장하지 않음, 같은 값 고정은 쓰기 없음, NEW ADVENTURE 난이도 유지, createDetective 기본 rookie/지정값.
  - `flutter analyze` → **No issues found**.
  - 전체 `flutter test` → **2277 passed, 0 failed, 0 skipped**(약 4분 6초). 기존 테스트 수정·삭제·skip 없음.
- **커밋 해시**: `8c9b4c84cb5191178c3dc8aef6b7c152627daea2` (`feat: add difficulty model and persistence`) — PART 2 커밋에서 기록.
- **남은 위험**:
  - 다른(선택되지 않은) 시즌의 `seasonDifficultyProvider`는 저장소 값을 읽어 자동 갱신되지 않음(D-3) — PART 3에서 다른 시즌 기록을 바꾸면 invalidate 필요.
  - 이전 빌드로 다운그레이드 후 프로필을 다시 저장하면 `difficulty`가 사라짐 → rookie로 읽힘(허용, D-8).
  - 아직 아무 화면도 난이도를 쓰지 않음 — 사용자 화면 변화 없음(의도).

### PART 2 — 프로필 생성 난이도 선택 UI
- **작업 날짜**: 2026-10-27
- **시작 상태**: `main`, HEAD `8c9b4c8`(PART 1), 미커밋 `.claude/settings.json`만(커밋하지 않음).
- **구현 내용**:
  - CREATE YOUR DETECTIVE(`/register`) 폼 안, 이름 줄 아래에 **CHOOSE YOUR LEVEL** + 세로 카드 3개(ROOKIE / JUNIOR / MASTER, 각 카드에 `Difficulty.blurb`). 별도 BottomSheet·새 화면·이미지·사운드 없음(선택 시 기존 UI 탭 소리 `TapRole.select`만 — 아바타 카드와 동일).
  - 위젯 `DifficultyChoice` / `_DifficultyCard`(`lib/features/onboarding/detective_form.dart`, `AvatarChoice` 옆): 카드 전체가 탭 대상(`HitTestBehavior.opaque`, 최소 높이 `kMinInteractiveDimension` 48). 선택 = antique gold(`AppColors.gold`) 2px 테두리 + 밝은 종이 + 금색 원 안의 체크(`InkGlyph.check`, `goldDeep`), 비선택 = 옅은 테두리 + 빈 원 → **색만으로 구분하지 않음**. 글자: 이름 `AppText.mark`, 설명 `AppText.caption`(토큰만 사용).
  - 접근성: 카드마다 `Semantics(button, selected, inMutuallyExclusiveGroup, label "rookie level. <설명>", onTap)`. (`excludeSemantics`만 쓰면 탭 동작이 화면 읽기에서 빠지므로 `onTap`을 명시 — 참고: 기존 아바타 카드 `_AvatarCard`는 같은 이유로 화면 읽기 탭 동작이 없다. 범위 밖이라 그대로 둠.)
  - 기본 선택 Rookie(`_RegisterScreenState._difficulty = Difficulty.standard`). 키보드가 올라오면(이름 입력 중) 난이도 영역은 엠블럼처럼 접히고 선택은 유지.
  - **레이아웃 변경(`DetectiveDesk`)**: 폼이 화면보다 길면 **폼만 스크롤되고 START INVESTIGATION은 그 아래 화면에 고정**(`Column(center)[Flexible(Center(heightFactor:1, SingleChildScrollView(PaperSheet))), 버튼]`). 폼이 화면에 다 들어가면(태블릿 등) 예전처럼 종이와 버튼이 함께 가운데. 이유: 카드 3개(약 310dp)를 넣으면 360×640·390×844에서 버튼이 첫 화면 밖으로 밀려, 기존 테스트가 지키는 "도착 시 버튼이 화면에 있음"(`title_screen_test`)과 생성 흐름 약 14개 테스트가 깨졌다(버튼까지 스크롤하면 포커스된 이름 칸이 캐럿을 보이려 되돌아 스크롤하며 탭이 무시됨). 버튼 고정으로 기존 테스트 수정 없이 모두 통과. `DetectiveDesk`는 `/detective` 설정 화면도 쓰므로 그 화면도 같은 규칙(폼이 넘칠 때만 버튼 고정)을 따른다 — 설정 화면에 난이도 UI는 없음.
  - 저장 연결: START INVESTIGATION → `createDetective(name, avatar, difficulty: _difficulty)` → 기존 `lm.detective.v1` 프로필의 `difficulty`. 새 저장 키 없음.
- **변경 파일**:
  - `lib/data/models/difficulty.dart`(`blurb`), `lib/features/onboarding/detective_form.dart`(`DifficultyChoice`), `lib/features/onboarding/register_screen.dart`(`_difficulty` 상태·`createDetective` 인자, `DetectiveDesk`의 선택적 `difficulty`/`onDifficulty`와 레이아웃)
  - 신규 테스트 `test/difficulty_selection_test.dart`
  - 문서 `docs/DIFFICULTY_IMPLEMENTATION.md`, `PROJECT_CONTEXT.md`
- **화면 크기별 검증**(실제 폰트 로드, `difficulty_selection_test`): 360×640(1.0·1.3배), 390×844(1.0·1.3배), 430×932, 800×1280(태블릿) — overflow 없음, 카드 설명 잘림 없음(`didExceedMaxLines == false`, 카드 폭 안), 카드 높이 ≥ 44, 아바타 두 장 온전, 버튼 탭 가능, Master 선택 후 생성. 키보드(360×640, 약 300dp): 이름 줄·버튼이 키보드 위, 난이도 영역 접힘, 키보드 내린 뒤 선택 유지. 스크린샷(`LM_SCREENSHOTS`)으로 360×640·390×844·1.3배·태블릿 육안 확인.
- **테스트 결과**(실제 실행):
  - `flutter test test/difficulty_selection_test.dart` → **15 passed**(표시·Rookie 기본·Junior/Master 선택·선택 해제·카드 모서리 탭·세 난이도 각각 생성·저장·재시작 복원·이름/아바타 저장·`/detective`에 난이도 UI 없음·6개 크기·키보드·난이도 없는 기존 프로필 호환(읽기만으로 레코드 재작성 없음))
  - `flutter analyze` → **No issues found**
  - 전체 `flutter test` → **2292 passed, 0 failed, 0 skipped**(약 4분). 기존 테스트 수정·삭제·skip 없음.
- **커밋 해시**: `0da1dac7375008f83039713f21e892e2fee47f40` (`feat: add difficulty selection to detective profile`) — PART 3 커밋에서 기록.
- **PART 3에서 바뀐 점(참고)**: 이 PART의 "`/detective`에 난이도 UI 없음" 테스트는 PART 3 요구(설정 화면에서 난이도 변경)에 맞춰 "시즌 시작 전 자유 변경" 테스트로 갱신됨.
- **남은 위험·미해결**:
  - 360×640 같은 작은 화면에서는 Junior·Master 카드가 첫 화면 아래에 있어 스크롤해야 보인다(Rookie 카드 일부와 고정 버튼은 보임). 아이가 다른 난이도를 못 보고 Rookie로 시작할 수 있음 — 기본값이 Rookie라 진행에는 문제없고, PART 3에서 `/detective`로 바꿀 수 있게 된다. 실제 플레이테스트에서 관찰 필요.
  - 폼이 넘치는 화면에서는 종이 아래쪽이 스크롤 영역 경계에서 잘려 보인다(스크롤 단서 역할). 페이드 등 장식은 넣지 않음.
  - 실기기(iOS/Android) 확인은 하지 않음 — 위젯 테스트·스크린샷만.

### PART 3 — 시즌 난이도 변경 및 초기화 정책
- **작업 날짜**: 2026-10-27
- **시작 상태**: `main`, HEAD `0da1dac`(PART 2), 미커밋 `.claude/settings.json`만(커밋하지 않음).
- **승인 정책**(사용자 최종 승인, I의 Q3·Q6·Q7·Q9): 코인·구매 힌트 유지 + 중복 지급 금지 / Paris 완료 후 안내 생략 / Case 01 인트로 최초 진입 시 고정 / 기존 진행 데이터까지 고려한 진행 중 판정.
- **구현 내용**:
  - **시즌 상태·난이도 판정** `SeasonLevel.of`(`game_providers.dart`): 완료 = 시즌 마지막 사건 해결 + 계획 사건 수 충족(다음 시즌 해금과 같은 규칙) / 진행 중 = 기록에 난이도 고정됨 **또는**(기존 사용자) 해결 사건·인트로 본 사건·해결 미션이 하나라도 있음 / 그 외 시작 전(프롤로그만 본 상태 포함). 난이도 = 고정값 ?? (시작 전이면 프로필 난이도, 아니면 **Rookie** — 기존 진행분은 유일한 영어였던 base로 플레이된 것). `seasonLevelProvider(seasonId)`(읽기 전용, 저장 없음), `seasonDifficultyProvider`는 이것을 사용(PART 1의 "고정값 ?? 프로필"에서 변경), `levelSeasonProvider`(난이도 변경이 적용될 시즌 = 플레이 중 시즌, 완료됐으면 다음 시즌, 마지막 시즌 완료면 null), `nextLevelQuestionProvider`(완료 안내 조건), `seasonSavesRevisionProvider`(다른 시즌 저장을 바꾼 뒤 다시 읽게 하는 카운터).
  - **고정 시점**: Story Intro 화면(`story_intro_screen.dart`) `initState` 다음 프레임에 `GameController.settleSeasonLevel()` — 고정값이 없을 때만 `fixDifficulty`(시작 전 → 프로필 난이도, 기존 진행 시즌 → Rookie). 일반 플레이에서 시즌의 첫 인트로는 Case 01. 사건 파일·시즌 화면·조회는 고정하지 않음(테스트). 기존 사용자의 진행 중 시즌은 읽을 때 Rookie로 계산되고, 다음 인트로 진입 때 Rookie로 저장된다(읽기 경로는 쓰지 않음).
  - **`/detective`**(`detective_settings_screen.dart`): PART 2의 카드(`DetectiveDesk` `difficulty`/`onDifficulty`) 재사용, 생성 화면 동작 불변. 대상 시즌이 시작 전/없음 → 자유 변경, SAVE CHANGES 때 프로필 저장. 진행 중 → 다른 카드를 누르면 `RestartSeasonDialog`("Restart your season?" + 승인 문구, **KEEP MY LEVEL = 굵은 안전 버튼**, RESTART SEASON = 다시 해 보기 잉크색 링크, 바깥 탭으로 닫으면 유지). RESTART → `restartSeason` → 토스트 → `/season`(시즌 화면, Case 01부터). 진행 중 시즌의 카드에는 그 시즌의 난이도가 표시됨.
  - **시즌 초기화** `GameController.restartSeason(seasonId, level)`: 아래 키만, **한 트랜잭션**(SaveJournal)으로 — ① 그 시즌 해결 미션 중 지갑 기록에 보상 항목이 없는 것을 0코인 항목으로 기록(`WalletController.settleSolved`), ② 그 시즌 모든 사건 저장을 `GameProgress(detectiveName: 이름)`으로 **덮어쓰기**(삭제 아님), ③ 시즌 기록을 `SeasonProgress(activeEpisodeId: Case 01, prologueSeen: 기존값 유지, difficulty: 새 난이도)`로 덮어쓰기(새 난이도로 즉시 고정 — 사용자가 이 시즌을 위해 고른 값). 트랜잭션 뒤 메모리 상태 정리(열린 사건·시즌 기록 다시 읽기, 최근 해금/해결 연출 초기화, revision 증가) → 마지막으로 프로필 난이도 저장.
  - **완료 후 안내** `NextLevelQuestion`(`lib/features/season/next_level_question.dart`): London 마지막 사건 Case Closed의 `_SeasonFinale`에서 GO TO PARIS 바로 위에 READY FOR YOUR NEXT MYSTERY? + 설명 + "Your level: …" + 잉크 링크 KEEP MY LEVEL / CHANGE LEVEL(굵은 버튼은 GO TO PARIS와 INVESTIGATION BOARD 두 개 그대로 — 기존 테스트 조건). CHANGE LEVEL → `ChooseLevelDialog`(같은 카드 3개 + CHOOSE <LEVEL> + Not now). 답하면 `answerNextLevel`(바꾸면 프로필 저장 → 완료 시즌 기록에 `nextLevelAsked: true`). GO TO PARIS는 가로막지 않음(답하지 않고 가도 Paris로 이동, 그때 Paris는 Case 01 인트로에서 프로필 난이도로 고정). Paris가 시작되면·답했으면·다음 시즌이 없으면 표시 안 함. Season Completed 보드에는 넣지 않음(보드 버튼 화면 배치 테스트 보호, Case Closed가 항상 먼저 나옴).
- **시즌 초기화 대상 키**(`<id>` = 프로필 id, 키는 `AppConstants.progressKeyFor`/`seasonKeyFor`로 생성):
  - London: `lm.p.<id>.progress.v1`(ep01), `lm.p.<id>.progress.v1.ep02` ~ `.ep12`, `lm.p.<id>.season.v1`
  - Paris: `lm.p.<id>.progress.v1.s2_ep01` ~ `.s2_ep12`, `lm.p.<id>.season.v1.s2_paris`
  - 함께 바뀌는 키: `lm.p.<id>.wallet.v1`(항목 **추가만** — 0코인 정산 항목, 잔액 불변), 트랜잭션 중에만 `lm.p.<id>.journal.v1`, 트랜잭션 뒤 `lm.detective.v1`(프로필 `difficulty`만)
- **보존 대상**: `lm.detective.v1`의 id·이름·아바타·기타 필드(난이도만 갱신), 다른 시즌의 사건·시즌 키(바이트 동일, 테스트), 지갑의 기존 항목 전부(잔액·구매 힌트 `tip:<missionId>:<n>`·보상 `mission:<missionId>`·광고 보상), `lm.p.<id>.selectedSeason.v1`, `lm.onboarding.v1.<id>`(How to Play), `lm.settings.sound`, 레거시 원본(`lm.progress.v1*`, `lm.season.v1`, `lm.wallet.v1`), 다른 프로필 네임스페이스, 시즌의 `prologueSeen`.
- **코인 중복 지급 방지**: 기존 지갑이 이미 영구 지급 기록(원장)이다 — 보상 키 `mission:<missionId>`(일반 미션 5코인·Final=사건 보상 10코인, 미션 id는 시즌 간 고유 → 시즌·사건·미션을 모두 식별), 같은 키는 한 번만 기록, 잔액 = 항목 합. 지갑을 초기화하지 않으므로 재플레이 시 `rewardMission`이 0을 돌려줌. 시즌 완료 보상은 별도로 없음(확인). 지급 기록이 없는 해결 미션(지급 여부 확인 불가)은 초기화 전에 0코인 `backfill` 항목으로 "지급됨" 처리 → 이후에도 지급 안 함, 잔액 불변. 기록과 초기화가 같은 트랜잭션이라 불일치 없음. 구매한 힌트는 지갑의 `tip:` 항목으로 남아 다시 열면 무료(`alreadyYours`). NEW ADVENTURE·Game Master 초기화는 기존대로 새 지갑(변경 없음).
- **저장 중단 복구**: 기존 `SaveJournal` 사용 — 트랜잭션의 모든 쓰기를 저널 키 하나에 먼저 기록한 뒤 각 키를 쓰고 저널을 지움. 중간 종료 시 다음 시작에 저장소가 만들어질 때 `recover()`가 저널을 끝까지 다시 쓴다(같은 값 재기록은 무해). 저널이 깨져 있으면(통째로 쓰이지 않음) 어떤 쓰기도 시작되지 않은 것이므로 버림 → 초기화 전 상태 그대로. 프로필(`lm.detective.v1`)은 저널 범위(프로필 네임스페이스) 밖이라 트랜잭션 **뒤에** 따로 저장 — 그 사이 종료되면 시즌은 이미 새 난이도로 고정·초기화된 상태이고 프로필 기본값만 이전 값(다음 시즌 기본값에만 영향, 일관성 유지). 테스트: 실제 초기화가 쓰는 키 집합으로 "저널 + 첫 쓰기만 적용" 상태를 만들어 재시작 → 전부 적용됨 확인.
- **변경 파일**:
  - `lib/data/models/season_progress.dart`(`nextLevelAsked`, 참일 때만 JSON 기록), `lib/data/models/wallet.dart`(문서 주석)
  - `lib/features/game/game_providers.dart`(`SeasonLevelStatus`/`SeasonLevel`, `seasonLevelProvider`, `seasonDifficultyProvider` 변경, `levelSeasonProvider`, `nextLevelQuestionProvider`, `seasonSavesRevisionProvider`, `SeasonNotifier.markNextLevelAsked`/`reload`)
  - `lib/features/game/game_controller.dart`(`settleSeasonLevel`, `restartSeason`, `answerNextLevel`), `lib/features/game/wallet_controller.dart`(`settleSolved`)
  - `lib/features/onboarding/story_intro_screen.dart`(진입 시 고정), `lib/features/onboarding/detective_settings_screen.dart`(난이도 변경 + `RestartSeasonDialog`), 신규 `lib/features/season/next_level_question.dart`(`NextLevelQuestion`, `ChooseLevelDialog`), `lib/features/result/case_solved_screen.dart`(안내 배치)
  - 테스트: 신규 `test/difficulty_season_policy_test.dart`(30), 갱신 `test/difficulty_persistence_test.dart`(정책 4에 맞춰 1개 — 진행 기록 있는 옛 시즌은 프로필이 아니라 Rookie), `test/difficulty_selection_test.dart`(PART 2의 "설정 화면에 난이도 없음" → PART 3 동작)
  - 문서 `docs/DIFFICULTY_IMPLEMENTATION.md`, `PROJECT_CONTEXT.md`
- **테스트 결과**(실제 실행):
  - `test/difficulty_season_policy_test.dart` **30 passed** — 요청 시나리오 1~31 대응: Rookie/Junior/Master로 London 시작·고정, 고정 후 프로필 변경, London/Paris 독립(한쪽 초기화 시 다른 쪽 바이트 동일), 프롤로그만 → 자유 변경, Case 01 인트로 진입 시 고정(사건 파일만으로는 고정 안 됨, 위젯), 기존 진행 사용자(진행 중·Rookie·읽기 무쓰기·다음 인트로에 Rookie 고정, 완료 시즌 인식), 변경 취소(KEEP MY LEVEL·바깥 탭 → 저장 스냅샷 동일, 360×640·390×844), 승인(RESTART SEASON → Case 01·새 난이도·잔액 유지·`/season`), London만·Paris만 초기화, 다른 시즌 완료 기록·XP·해금 보존, 프로필 보존, 코인 잔액·구매 힌트 보존(다시 열기 무료), XP·증거 재계산(초기화 시즌 0, 다른 시즌 불변), 중간 종료 후 복구, safe mode 레거시 부활 방지(원본 키는 그대로), 재플레이 시 미션·Final 보상 0·미해결 미션은 정상 지급, 지급 기록 없는 기존 저장 → 0코인 정산·잔액 불변·잔액 = 항목 합, London 완료 안내(조건·KEEP·CHANGE→Master·London 난이도 유지·재시작 후 재표시 없음·Paris 시작 후/Paris 완료 후 미표시·GO TO PARIS 정상, 답 없이 GO TO PARIS도 정상), 안내 필드 없는 기존 기록 호환, 다른 시즌 초기화 후 조회 최신화.
  - `flutter analyze` → **No issues found**
  - 전체 `flutter test` → **2322 passed, 0 failed, 0 skipped**(약 4분 43초). 기존 테스트 삭제·skip 없음(갱신 2개는 위에 기록).
  - 스크린샷(`LM_SCREENSHOTS`, 실제 폰트) 360×640·390×844: 재시작 확인창, 완료 안내, 난이도 선택 대화상자 — 잘림·가림 없음 육안 확인.
- **커밋 해시**: `19c18015c46a2dc05e926bd62ead1b86c27446f7` (`feat: enforce season difficulty change policy`) — PART 4 커밋에서 기록.
- **PART 4에서 해결**: "운영자 도구로 인트로에 들어가면 실제 사용자 시즌 난이도가 고정됨" 위험 → 테스트 도구가 개발자 테스트 세션에서만 동작하도록 격리(PART 4 항목).
- **남은 위험**:
  - 운영자 도구(사건 바로가기·CASE NN부터)로 인트로에 들어가면 **실제 사용자 시즌 난이도가 고정**된다(현재 개발 상태가 일반 데이터와 분리되어 있지 않음) — PART 4에서 격리로 해결 대상.
  - `seasonLevelProvider`는 사건 저장을 저장소에서 읽는다(현재 사건 진행을 감시하지 않음). 새 흐름에서는 인트로 고정이 진행보다 먼저라 문제없으나, 고정 없이 진행이 생기는 새 경로를 만들면 갱신 경로(`seasonSavesRevisionProvider.bump` 또는 감시)를 추가해야 한다.
  - 완료 안내는 Case Closed에만 있다. 사용자가 그것을 지나쳐 보드에서 GO TO PARIS를 눌러도 Paris Case 01 인트로 전까지는 `/detective`에서 자유 변경 가능.
  - 프로필 난이도 저장은 트랜잭션 밖(위 복구 항목) — 극히 짧은 구간의 종료 시 "다음 시즌 기본값"만 이전 값.
  - 이전 빌드로 다운그레이드 시 `nextLevelAsked`·`difficulty` 필드 유실 가능(기본값으로 안전하게 읽힘).
  - 실기기 확인은 하지 않음.

### PART 4 — 개발자 모드 개선 (테스트 세션 격리)
- **작업 날짜**: 2026-10-27
- **시작 상태**: `main`, HEAD `19c1801`(PART 3), 미커밋 `.claude/settings.json`만(커밋하지 않음). G의 조사 내용을 코드로 재확인: `SharedPreferences.getInstance()`는 `main.dart` 한 곳뿐이고 모든 저장(진행·시즌·지갑·프로필 `ProfileStore`·How to Play·소리)은 `sharedPreferencesProvider`를 거친다. 라우터는 컨테이너의 `routerProvider`가 만든다.
- **개발자 세션 생성 방식** — `DevSessionHost`(`lib/features/game_master/dev_session.dart`), `DeviceDetectiveGate`가 기존 `ProviderScope` 대신 사용:
  - **플레이어 컨테이너**: 호스트가 한 번 만들어 앱 실행 내내 유지(`UncontrolledProviderScope`). 개발자 모드 동안 화면에서만 빠지고 폐기되지 않음 → 나오면 같은 컨테이너·같은 라우터(떠난 Game Master 페이지)·같은 상태로 복귀. 재구성·재초기화 없음.
  - **테스트 컨테이너**: 진입할 때마다 **부모 없는 새 `ProviderContainer`** — 플레이어 Provider로 되돌아갈 경로가 구조적으로 없음(일부 override 방식의 위험 제거). 저장소는 `MemoryPreferences`(신규, `lib/data/repositories/memory_preferences.dart`, `SharedPreferences` 인터페이스의 메모리 구현)로 override → 진행·시즌·시즌 난이도·완료 안내·지갑·보상 기록·구매 힌트·퍼즐 상태·프로필·How to Play·저널까지 **모두 메모리**. 플레이어 쪽에서 읽어 복사하는 것은 콘텐츠·지도·출시 여부·빌드 플래그(`allEpisodesProvider`, `episodeRepositoryProvider`, `seasonMapsProvider`, `seasonReleasedProvider`, `operatorToolsAvailableProvider`)와 기기 소리 설정 값뿐(쓰기 없음). 오디오는 기기에 하나(플레이어의 `audioServiceProvider` 인스턴스 공유 — 화면에 있는 쪽이 장면을 정함).
  - 종료: 테스트 컨테이너를 화면에서 빼고 다음 프레임에 `dispose`(Provider·라우터·메모리 저장소 폐기). 재진입은 세션 번호를 올려 새 컨테이너·새 위젯 키(이전 세션 재사용 불가). 앱 재시작 시 테스트 세션은 존재하지 않음(메모리).
  - 플레이어 사건 시계: 진입 시 `GameController.holdPlayClock()`(신규 — 흐른 시간을 메모리에만 보관하고 **아무것도 쓰지 않음**, 다음 저장 때 함께 기록), 종료 시 `resumePlayClock()`.
- **TESTER 프로필**: `devDetective()` — id `7e57de7e7e57de7e7e57de7e7e57de7e`(테스트 네임스페이스, 메모리), 이름 `TESTER`(`playtestDetectiveName`), BOY, Rookie. 메모리 저장소에 `lm.detective.v1` 레코드 + Case 01 저장(이름) + How to Play 본 것으로 시드 → 생성 화면·How to Play를 거치지 않고 Game Master로 시작. 이름 개인화·탐정 파일·아바타는 모두 TESTER/BOY(테스트로 확인). **실제 `lm.detective.v1`에는 쓰지 않음**(바이트 동일 검증).
- **라우터·Provider 격리**: 테스트 컨테이너가 자기 `routerProvider`로 새 `GoRouter`를 만든다(초기 `gameMasterAccessProvider.grant()` + `/game-master`). `LondonMysteryApp`은 활성 컨테이너의 라우터를 읽는다. 같은 세션 안에서 페이지 이동·rebuild는 같은 컨테이너 유지(테스트로 `identical` 확인). 시각 표시: 테스트 세션의 모든 화면 우측 상단에 `TESTER` 리본(`Banner`, 입력 차단 없음).
- **진입·종료 흐름**: 플레이어 Game Master(Start → 보호자 확인 → `/game-master`, 테스트 빌드) → **START DEVELOPER MODE** → 테스트 세션의 Game Master(상단 DEVELOPER MODE · TESTER · BOY, 설명, **EXIT DEVELOPER MODE**, TEST LEVEL 카드, 기존 도구 전부). 종료: EXIT 버튼, 또는 **테스트 세션 첫 페이지에서 시스템 Back**(라우터가 더 pop할 수 없을 때 앱 종료 대신 개발자 모드 종료 — `WidgetsBindingObserver.didPopRoute`). 탐정이 아직 없는 기기에서도 진입 가능(TESTER), 나와도 기기는 탐정 없음 그대로.
- **기존 도구**(`playtest_tools.dart`): CASE NN부터·사건 바로가기·지금 사건 처음부터·OPERATOR MODE·SEASON PREVIEW·Paris 프롤로그 미리보기는 **테스트 세션의 Game Master에만** 표시. 함수에도 보호 추가: 개발자 모드가 있는 게임(호스트 존재)의 **플레이어 세션**에서는 `startPlaytestAt` → `StateError`, `jumpToCase` → `CaseJumpRefusal.playerSaves`(신규), `restartCurrentCase`·`changeTestLevel` → 아무것도 안 함(`onPlayerSaves`). 호스트가 없는 게임(도구 자체를 검사하는 기존 테스트)에서는 예전처럼 그 자리에서 동작 → 기존 테스트 무수정. "다음 플레이어를 위해 기기 초기화"와 일반 NEW ADVENTURE는 **변경 없음**(플레이어 Game Master에만, 테스트 세션에는 숨김).
- **난이도 변경**(`changeTestLevel`, Q5 승인): TEST LEVEL 카드 선택 → TESTER 난이도 변경, 시즌 난이도가 고정돼 있으면 같은 값으로 재고정, 현재 Case가 시작됐으면(인트로 봄 또는 해결 미션 있음) `playAgain`으로 그 Case만 Mission 1부터(시즌 해결 기록은 유지), 시작 전이면 난이도만. 확인창 없음, 토스트 "CASE NN restarts as MASTER." 테스트 세션 밖에서는 거부.
- **실제 사용자 데이터 보호 검증**: 진입 전 `SharedPreferences` 스냅샷 → 테스트 세션에서 London·Paris 진행, 미션·Final 해결, 증거, 코인 획득, 힌트 구매, CASE 12부터로 London 완료(테스트 안에서만 완료·다음 시즌 안내 조건 성립), 난이도 변경, 인트로 고정, How to Play 기록 지우고 다시 쓰기, OPERATOR MODE·바로가기 → 종료 → **스냅샷 바이트 단위 동일**(How to Play·소리·프로필·지갑 포함). 재시작(위젯 트리 교체) 후에도 동일.
- **변경 파일**:
  - 신규 `lib/data/repositories/memory_preferences.dart`, `lib/features/game_master/dev_session.dart`
  - 수정 `lib/features/onboarding/detective_hold_screen.dart`(`DeviceDetectiveGate` → `DevSessionHost`), `lib/features/game_master/game_master_screen.dart`(플레이어/테스트 세션별 구성, 개발자 모드 헤더·EXIT·TEST LEVEL), `lib/features/game_master/playtest_tools.dart`(`onPlayerSaves`, `changeTestLevel`, 도구 보호, `CaseJumpRefusal.playerSaves`), `lib/features/game/game_controller.dart`(`holdPlayClock`)
  - 신규 테스트 `test/developer_session_test.dart`(9)
  - 문서 `docs/DIFFICULTY_IMPLEMENTATION.md`, `PROJECT_CONTEXT.md`
- **테스트 결과**(실제 실행):
  - `test/developer_session_test.dart` **9 passed** — 요청 1~37 대응: 프로필 격리(TESTER/BOY/Rookie, 종료 후 KIM/GIRL/Junior·이름 표시 복원), 진행 격리(London·Paris Case, 미션·Final, 증거, 코인, 힌트 구매, 시즌 완료, 실제 데이터 불변), 재진입 초기화(첫 상태·진행 후 종료·재진입 시 Mission 1부터·같은 세션 페이지 이동/rebuild 유지·앱 재시작 시 세션 없음), 난이도(Rookie 기본·Junior·Master, 진행 중 Case 재시작·Mission 1부터, 확인창 없음, 실제 난이도 유지), 스냅샷 바이트 동일(How to Play 포함), 기존 도구(CASE NN부터·바로가기·처음부터·OPERATOR MODE를 테스트 세션에서), 플레이어 Game Master에는 도구 없음·함수 호출 거부, NEW ADVENTURE·다음 플레이어 초기화 동작 유지, 시스템 Back으로 종료, 탐정 없는 기기에서 진입.
  - `flutter analyze` → **No issues found**
  - 전체 `flutter test` → **2331 passed, 0 failed, 0 skipped**(약 4분 8초). **기존 테스트 수정·삭제·skip 없음.**
- **커밋 해시**: PART 4 커밋(메시지 `feat: isolate and reset developer test sessions`) — **PART 5 작업자가 `git log --oneline --grep "developer test sessions"`로 확인해 이 칸을 채운다.**
- **남은 위험·미해결**:
  - 기존 도구 UI 테스트(`playtest_tools_test`, `case_shortcuts_test`, `operator_access_test` 등)는 호스트 없이 실행되어 **예전처럼 그 컨테이너의 저장소에 쓰는 동작**을 검사한다(앱에는 항상 호스트가 있어 플레이어 세션에서는 도구가 보이지도 동작하지도 않음). 호스트가 있는 실제 구성은 `developer_session_test`가 검사.
  - 테스트 세션의 소리 켜기/끄기는 메모리 설정만 바뀌고, 공유 오디오는 플레이어의 소리 설정을 따른다(기기 설정 공유 — 의도).
  - 실기기(Android Back·iOS)에서 확인하지 않음. 앱이 백그라운드로 가면 테스트 세션의 시계만 멈춤(플레이어 시계는 이미 보류 상태).
  - PART 5에서 난이도별 콘텐츠를 만들 때 `allEpisodesProvider`를 **각 컨테이너 안에서** 난이도로 파생해야 한다 — 지금 테스트 세션은 플레이어 컨테이너의 `allEpisodesProvider` 값을 복사해 쓴다(G 참고).

<!-- PART 5 이후 작업자는 아래에 같은 형식으로 추가한다 -->

---

## G. 다음 세션 인수인계

### 현재 완료된 PART
**PART 0**(`042afac`), **PART 1**(`8c9b4c8`), **PART 2**(`0da1dac`), **PART 3**(`19c1801`), **PART 4**(개발자 테스트 세션 격리, 커밋 `feat: isolate and reset developer test sessions` — 해시는 `git log --oneline --grep "developer test sessions"`).
지금 상태: 난이도는 프로필·시즌별로 저장·고정·변경되고(PART 1~3), 개발자 모드는 TESTER 메모리 세션에서 난이도를 바꿔 볼 수 있다(PART 4). **하지만 게임의 영어 문장은 아직 모든 난이도에서 같다.** "지금 적용할 난이도"는 `currentDifficultyProvider`(선택 시즌의 실효 난이도, `game_providers.dart`)가 이미 알려 준다.

### 다음 PART
**PART 5 — 난이도별 영어 콘텐츠 시스템** (구조만. London·Paris 전체 문장 작성은 PART 6·7)

### ⚠ PART 5 시작 전 사용자 확인 (섹션 I)
- **Q1**: 현재 저장소의 영어 = Rookie(base)로 볼지 — 설계 전체의 전제(제안: 예 → 기존 사용자 화면·해시 테스트 불변). **구현 전에 확정 필요.**
- **Q2**: "힌트 제공 방식" 차이를 UI로도 둘지(제안: 개수·가격 동일, Rookie는 오답 시트에서 GET A TIP 강조 정도) 또는 문구만.
- **Q8**: 부모 보고서 학습 설계(`learning` expressions)를 난이도별로 둘지(제안: PART 5는 base만).
- 미확정 정책은 임의로 확정하지 말고 답을 I에 기록한 뒤 구현.

### PART 5 작업 범위 (D-4·D-5 설계를 코드로)
1. **텍스트 선택 구조**: base(=현재 콘텐츠) + 난이도별 변형(Junior·Master, Q1 답에 따라 Rookie 패치 가능). 변형이 없으면 `Master → Junior → base` 순으로 대체(`Difficulty.fallbackChain` 추가).
2. **JSON 콘텐츠(사건·미션·단서·증거)**: 사건 ID → 패치 맵을 base JSON에 깊은 병합(목록 원소는 `id`로 매칭) 후 `Episode.fromJson`. **텍스트 키 화이트리스트만 허용**, 정답·구조 키(`answer`, `acceptedAnswers`, `codeLength`, `dialSymbols`, `nextMissionId`, `id`, `value`, 옵션 수·순서, 증거 id)는 패치 금지(테스트로 강제). `Mission.feedback`은 **키 = 오답 문자열**이라 값만 변경.
3. **타입 객체(약 60개 부가 테이블: 대화·EasySteps·퍼즐 장면)**: `SeasonContent`에 난이도별 대체 테이블(객체 통째 교체). `Mission`·`Episode`에 직렬화하지 않는 `difficulty` 필드를 두고(`toJson`에 넣지 않음 → `final_small_pass_test` FNV 해시 불변) `SeasonCatalog.xxx(Mission m)`가 `m.difficulty`로 고르게 → **약 112개 호출부 무수정**. 사건 ID로 찾는 테이블은 `Episode.difficulty` 사용.
4. **난이도 반영 위치**: `allEpisodesProvider`(현재 `main.dart`에서 미리 만든 카탈로그로 override)를 "base 카탈로그 + 시즌별 실효 난이도(`seasonDifficultyProvider`)로 파생"으로 바꾼다. **PART 4 주의**: `DevSessionHost`는 테스트 세션에 플레이어 컨테이너의 `allEpisodesProvider` **값**을 복사해 넣는다(`dev_session.dart` `_newTestSession`). 난이도 파생을 `allEpisodesProvider` 자체에 넣으면 테스트 세션이 플레이어의 난이도로 고정된 카탈로그를 받게 되므로, **base 카탈로그용 Provider를 따로 두고(그것을 복사) 난이도 파생 Provider는 각 컨테이너 안에서 계산**되게 할 것. 개발자 모드 TEST LEVEL로 문장이 바뀌는지 테스트.
5. **파생 텍스트**: Season 2 Discovery 제목은 `season2DiscoveriesOf(season2Json)`(`season_catalog.dart`)가 **base `successMessage`로 정적 생성** → 난이도 적용 미션으로 다시 만들어야 한다. `Mission.answerLabel`(GM 정답표)은 base 유지 가능.
6. **단어 뜻(롱프레스) 호환**: 난이도 패치는 사건 `glossary`에 단어를 **추가**(삭제 없음). `GlossaryText`는 `widget.episode ?? currentEpisodeProvider`의 glossary를 쓰므로 난이도 적용 `Episode`가 흘러가면 자동. Master의 어려운 단어가 glossary에 있는지 검사하는 테스트 도입 검토.
7. **힌트 구조**: 미션당 힌트 **개수·가격(`tipPrices`)·XP·코인 불변**, 문구만 난이도별(Q2 답에 따라 UI 강조 차이). 모든 난이도에서 "힌트·스토리가 정답을 말하지 않음"(`season_content_test` 규칙) 검사 확장.
8. **불변 조건 테스트**: 모든 난이도에서 정답·선택지 수/순서·증거 ID·단서 value·미션 수·힌트 개수가 base와 같음. 타입 객체는 모델별 구조 추출 비교. 커버리지 테스트로 섹션 H 표와 실제 변형 존재를 맞춤.
9. **샘플**: 미션 1~2개에만 Junior·Master 변형을 넣어 파이프라인 검증(전체 작성은 PART 6·7). 위젯 하드코딩 영어(약 360개, 대부분 조작 안내)는 목록화만 — 조작 안내는 난이도와 무관하게 동일 유지가 원칙.

### PART 5 주의 사항
- 위젯에 미션별/난이도별 분기 금지(콘텐츠는 데이터). 탐정 이름 치환(`{detectiveName}`, `DetectiveName`)은 모든 난이도 동일 규칙.
- 기존 콘텐츠 고정 테스트: `test/final_small_pass_test.dart`(FNV 해시 — base `toJson` 불변이면 유지), `test/personalized_lines.dart`, `test/season_content_test.dart`, `test/learning_objectives_test.dart`(expressions가 미션 영어의 부분 문자열 — base 기준).
- 추리 보호 규칙(PROJECT_CONTEXT *핵심 Reasoning 구조*·*Continuity Guardrails*: Case 06 grey/hat/card, 07 old gate, 08 button/coat/red 등 금지어, 02 after·09 whose·04 never sleep 표현 연결)은 변형 텍스트에도 적용 — PART 5에서 검사 틀을 만들어 PART 6·7이 쓰게.
- Season 2 콘텐츠를 만질 때는 `docs/SEASON2_PARIS_STORY_BIBLE.md` 먼저(CLAUDE.md 22절).
- 개발자 테스트 세션(PART 4)과 플레이어 세션은 컨테이너가 다르다 — 정적 전역 상태(예: `SeasonCatalog`의 static 캐시)에 "현재 난이도"를 두지 말 것(두 세션이 섞인다). 난이도는 `Mission/Episode` 객체에 실어 보낸다.
- 기존 미커밋 파일(`.claude/settings.json`)은 커밋하지 않는다. 원격 푸시 금지. F의 PART 4 커밋 해시 칸을 채운다.

### PART 5 수정 예상 파일
- `lib/data/models/difficulty.dart`(`fallbackChain`), `lib/data/models/mission.dart`·`episode.dart`(비직렬화 `difficulty`), `lib/data/repositories/episode_repository.dart`(패치 병합), `lib/data/mock/season_catalog.dart`(난이도별 테이블·조회, Season 2 Discovery 재생성), `lib/features/game/game_providers.dart`(base 카탈로그 / 난이도 파생 카탈로그), `lib/main.dart`, `lib/features/game_master/dev_session.dart`(base 카탈로그 복사), 신규 `lib/data/mock/season1/difficulty/…`·`season2/difficulty/…`(샘플)
- 테스트: 신규 콘텐츠 시스템 테스트 + 영향: `season_content_test`, `final_small_pass_test`, `learning_objectives_test`, `developer_session_test`

### PART 5 검증 방법
- 샘플 미션이 Rookie/Junior/Master에서 다른 문장, 정답·구조 동일, 변형 없는 필드는 대체 규칙대로, 기존 사용자(Rookie/base) 화면 불변(해시 테스트 유지), 개발자 TEST LEVEL 변경 시 문장 변화, 플레이어 세션 문장은 플레이어 시즌 난이도.
- `flutter analyze` 0, 관련 + 전체 `flutter test`.

### PART 5 완료 조건
- 위 구조 구현(콘텐츠 전체 적용은 제외), Q1·Q2·Q8 답 기록
- analyze 0 issues, 관련 + 전체 회귀 통과(실제 결과 기록)
- 이 문서 E(PART 5)·F(이력, PART 4 해시)·G(PART 6 인수인계)·H 갱신, `PROJECT_CONTEXT.md` 갱신
- PART 5 변경 파일만 커밋(푸시 없음)

### 모든 PART 공통 작업 규칙 (PART 1~7)
1. 시작 시 `PROJECT_CONTEXT.md`와 이 문서를 읽는다.
2. Git 브랜치, HEAD, 작업 트리 상태를 확인한다.
3. 이미 완료된 PART를 중복 구현하지 않는다.
4. 해당 PART 범위만 수정한다.
5. 관련 테스트와 전체 회귀 테스트를 실행한다(CLAUDE.md 21절: 출력은 로그 파일로, 결과는 통과/실패 수·시간만 보고).
6. 실제 결과만 이 문서에 기록한다.
7. `PROJECT_CONTEXT.md`의 진행 상태를 업데이트한다.
8. 변경 사항을 검토한다.
9. 해당 PART의 변경 파일만 커밋한다(원격 푸시 금지).
10. 다음 PART의 시작 지점을 G에 명확히 기록한다.
- 테스트가 실패하거나 미해결 문제가 있으면 완료 처리하지 않는다.
- 커밋 해시는 커밋 후 확인한 실제 값. 자기 커밋의 해시를 같은 커밋에 넣으려 하지 않는다 — 다음 PART 커밋(또는 별도 문서 커밋)에서 채우고 그 관계를 이력에 적는다.

---

## H. 콘텐츠 적용 진행표

상태 표기: `—` 미착수 / `WIP` 작성 중 / `✓` 적용·테스트 통과 / `base` 현재 텍스트를 그대로 사용(D-5 제안대로라면 Rookie = base).
Rookie 열은 base를 그대로 쓰면 `base`, 별도 Rookie 패치를 두면 `✓`.

### London — Season 1 (`s1_london`)
| 범위 | ID | Rookie | Junior | Master | 커밋 | 비고 |
|---|---|---|---|---|---|---|
| 시즌 프롤로그·outro·finale | `s1_london` | base | — | — | | `season1InfoJson` |
| Case 01 | `ep01` | base | — | — | | 미션 5 + Final, 개인화 줄 있음 |
| Case 02 | `ep02` | base | — | — | | 8:17 → 9:17 보호 |
| Case 03 | `ep03` | base | — | — | | trains and smoke / Red Button(→08) |
| Case 04 | `ep04` | base | — | — | | Platform 4(→12), RAVEN |
| Case 05 | `ep05` | base | — | — | | 745 순서 질문 |
| Case 06 | `ep06` | base | — | — | | grey/hat/card 금지어 |
| Case 07 | `ep07` | base | — | — | | "old gate" 노출 금지 |
| Case 08 | `ep08` | base | — | — | | button/coat/red 금지어 |
| Case 09 | `ep09` | base | — | — | | whose 구문이 퍼즐 |
| Case 10 | `ep10` | base | — | — | | TOWER + BRIDGE |
| Case 11 | `ep11` | base | — | — | | never sleeps(→04) |
| Case 12 | `ep12` | base | — | — | | after/whose 재사용, PARIS. |

### Paris — Season 2 (`s2_paris`)
| 범위 | ID | Rookie | Junior | Master | 커밋 | 비고 |
|---|---|---|---|---|---|---|
| Paris 프롤로그·시즌 문구 | `s2_paris` | base | — | — | | `season2PrologueJson`, 버튼 문구는 위젯 하드코딩 |
| Case 01 | `s2_ep01` | base | — | — | | |
| Case 02 | `s2_ep02` | base | — | — | | |
| Case 03 | `s2_ep03` | base | — | — | | |
| Case 04 | `s2_ep04` | base | — | — | | Final EasySteps |
| Case 05 | `s2_ep05` | base | — | — | | M3·Final EasySteps |
| Case 06 | `s2_ep06` | base | — | — | | |
| Case 07 | `s2_ep07` | base | — | — | | M1·M2·Final EasySteps |
| Case 08 | `s2_ep08` | base | — | — | | |
| Case 09 | `s2_ep09` | base | — | — | | |
| Case 10 | `s2_ep10` | base | — | — | | |
| Case 11 | `s2_ep11` | base | — | — | | Talk + EasySteps |
| Case 12 | `s2_ep12` | base | — | — | | Talk + EasySteps + Ending |

각 Case 적용 시 확인: JSON(사건·미션·단서·증거) + 그 사건의 부가 테이블(대화·EasySteps·퍼즐 장면) + Discovery + glossary + 힌트. 불변 조건 테스트와 추리 보호 규칙이 그 난이도에서 통과해야 `✓`.

---

## I. 확인된 위험과 미결정 사항

### 미결정 (사용자 결정 필요)
| # | 질문 | 제안 기본값 | 필요한 시점 |
|---|---|---|---|
| Q1 | 현재 텍스트를 Rookie(base)로 볼 것인가? | **예** — 기존 사용자 화면·테스트 불변 | PART 5 전 |
| Q2 | "힌트 제공 방식"을 UI로도 다르게(Rookie는 GET A TIP 강조) 할 것인가, 문구만 다르게 할 것인가? | 개수·가격 동일, UI 강조만 차이 | PART 5 |
| Q3 | 시즌 초기화 시 지갑(코인·산 Tip)을 어떻게? | **APPROVED (2026-10-27)**: 코인 잔액·구매한 힌트·다른 시즌 보상 유지, 재플레이 보상 중복 지급 금지(지급 여부를 확인할 수 없으면 지급하지 않음), 기존 잔액 임의 변경 금지 — PART 3 구현 | PART 3 |
| Q4 | NEW ADVENTURE 후 프로필 난이도 유지? | 유지(이름·아바타처럼) — **PART 1 현재 동작이 이것(테스트로 고정)**. 바꾸려면 사용자 결정 필요 | PART 1~3 |
| Q5 | 개발자 모드에서 난이도 변경 시 dev 진행 초기화? | **APPROVED (2026-10-27, PART 4 요청서)**: 현재 Case를 Mission 1부터 재시작(확인창 없음), Case를 고르기 전이면 난이도만 변경 — PART 4 구현 | PART 4 |
| Q6 | 마지막 시즌(Paris) 완료 후 "다음 시즌 난이도" 안내? | **APPROVED (2026-10-27)**: London 완료 후 Paris 진입 전에 변경 기회, Paris 완료 후 생략, 시즌 3 추가 시 확장 가능(다음 시즌이 있으면 묻는 일반 규칙) — PART 3 구현 | PART 3 |
| Q7 | 시즌 "시작" 시점(난이도 고정 시점) | **APPROVED (2026-10-27)**: 그 시즌 Case 01 인트로 최초 진입 시 고정. 프롤로그만 본 상태는 변경 가능. 진행 중에는 초기화 없이 변경 불가 — PART 3 구현 | PART 3 |
| Q9 | "진행 중 시즌" 판정 | **APPROVED (2026-10-27)**: Case 01 인트로 진입으로 난이도가 고정됨 + 마지막 Case 미완료. 기존 사용자: 고정값이 없어도 실제 진행 기록이 있으면 진행 중, 진행 기록 삭제·강제 재시작 없음, 최초 확인 시 Rookie로 고정, 읽기 경로는 저장하지 않음 — PART 3 구현 | PART 3 |
| Q8 | 부모 보고서의 학습 설계(`learning` expressions)를 난이도별로 둘 것인가? | 우선 base만, Junior·Master 표현은 PART 6~7에서 검토 | PART 5 |

### 확인된 위험
1. **콘텐츠 양**: 시즌당 50개 안팎 미션 × 텍스트 필드 + 약 60개 타입 테이블. Junior·Master 2벌이면 현재 영어 분량의 약 2배를 새로 써야 한다 → PART 6·7은 Case 단위로 나눈다.
2. **추리 보호 규칙**: 금지어(06 grey/hat/card, 07 old gate, 08 button/coat/red, 11 under Big Ben/door 등)와 cross-case 표현(02 after, 09 whose, 04 never sleep)은 **표현 자체가 퍼즐**이다. Master의 "더 간접적인 단서"가 이 연결을 깨거나, Rookie가 정답을 말해 버릴 위험 → 기존 보호 테스트를 모든 난이도로 확장해야 한다.
3. **텍스트이면서 정답인 데이터**: `Mission.feedback` 키, `Clue.value`, 일부 `inscription`, 문장 순서 퍼즐(10 Final)의 문장, 철자·단어 조합 퍼즐(10-M3 이름)은 난이도별로 바꾸면 정답이 바뀐다 → 변형 금지 목록 필요(PART 5).
4. **해시·문자열 고정 테스트**: base를 그대로 두면 유지. base를 바꾸는 순간 `final_small_pass_test` 해시 갱신 필요.
5. **정적 조회 112곳**: 난이도를 `Mission.difficulty`로 운반하지 않으면 호출부를 모두 고쳐야 한다(D-5 제안이 이를 피함). Mission을 id로 다시 찾는 경로(`ofMission(m.id)` 외에 id만 들고 다니는 곳)가 base 미션을 쓰지 않는지 PART 5에서 확인.
6. **개발자 세션 스코프**: 라우터·`DeviceDetectiveGate`와 provider 스코프가 얽혀 있다(D-7 주의). prefs를 직접 쓰는 provider(How to Play 시청, 소리)가 누수 경로.
7. **시즌 초기화와 safe mode/ep01 자동 해결/트랜잭션**(C-3 1~2).
8. **문서 불일치**: `PROJECT_CONTEXT.md`의 XP 규칙·Tip 가격 서술이 현재 코드(규칙 4, Tip 2 = 20코인)와 다르다. Paris "unreleased" 주석도 오래됨. 난이도 작업 범위 밖이라 PART 0에서는 고치지 않음.
9. **다운그레이드 시 필드 유실**(D-8) — 허용.
