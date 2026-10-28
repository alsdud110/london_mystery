# London Mystery — PROJECT_CONTEXT

> 이 파일은 Claude Code 세션이 바뀌어도 개발 흐름을 이어가기 위한 **영속적인 작업 기억 파일**이다.
> README.md(사용자/운영자용 안내)와 달리, 이 파일은 **다음 개발 세션이 현재 상태를 정확히 파악하기 위한 문서**다.
> 새 세션은 반드시 이 파일을 먼저 읽고, 아래 *Session Continuity Protocol*을 따른다.
> 코드와 이 문서가 다르면 **코드가 source of truth**다.
>
> 최종 검증일: 2026-10-18 — `flutter analyze` 0 issues, `flutter test` **1548개 전부 통과**, Android debug APK·iOS(`--no-codesign`) 빌드 성공, iPhone 시뮬레이터 실행. 단일 앱 `com.londonmystery.app` "London Mystery"(flavor 없음).
> 마지막 작업: **Wave 2.5.2 — Case 06-M1 추리 피드백 다듬기**(GOOD MATCH / 다름 구분, 판정을 카드 바로 아래로, 착지 후 말풍선, DESCRIPTION RECORDED + CONTINUE). 그 전: **Wave 2.5.1 — Case 06-M1 상호작용 다듬기**(TALK 은은한 빛, 초상화 비행 전환, 두 진술 선택 즉시 판정). 그 전: **Wave 2.5 — Case 06-M1 직관적 수사·진짜 추리**(화살표 제거, 진술 2개 선택 비교, 옷차림 확인 단계, Notebook 진술 기록, WORDS). 그 전: **Wave 2.4.1 — Case 06-M1 미조사 증인 안내 보정**(남은 증인마다 같은 작은 정적 화살표). 그 전: **Wave 2.4 — Case 06-M1 다음 행동 화살표**(GuidedActionIndicator·ASK ANOTHER WITNESS·CHOOSE ANOTHER PAIR). 그 전: Wave 2.3 — Case 06-M1 단계별 수사(한 번에 다음 행동 하나·YES/NO 비교). 그 전: Wave 2.2 — Case 06-M1 목표 중심 수사(YOUR MISSION·carry 진술 2명 조건·BACK TO WITNESSES). 그 전: Wave 2.1 — Case 06-M1 대화 화면 다듬기. 그 전: Wave 2 — Case 06-M1 증인 대화 수사. 그 전: Wave 1.2 — Case 03-M1 화면 마감. 그 전: Wave 1.1 — Case 03-M1 탐색 UX. 그 전: Wave 1 — Case 03-M1 현장 탐색. 그 전: **Phase 4 P1-3·P1-4 — 사건 간 영어 재사용**(12-M2 after, 12-F whose, 11-M3 never sleeps). 그 전: Phase 4 P1-1·P1-2(Notebook 단어 뜻, Operator Archive 참고 공개), TYPE B Phase 3B — Season 1 전 사건 TYPE B 적용.

---

## Project Overview

| 항목 | 내용 |
|---|---|
| 프로젝트 | World Mystery (`world_mystery`, v0.1.0+1) — 2026-10-28 London Mystery에서 리브랜딩. 단일 앱 `com.worldmystery.app` "World Mystery" |
| 위치 | `/Users/myhwang/flutter-workspace/world_mystery` (git 저장소 `alsdud110/world_mystery`, 브랜치 `main`) |
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

- **탐정 이름 개인화 (2026-10-17)**: 플레이어에게 직접 말하는 10줄만 `Detective {detectiveName}`(`DetectiveName.placeholder`)로 표시 — 편지 6(01-M1·01-M5·02-M1·02-M2·04-M3·04-F), 인물 대사 4(06-F Grey 호루라기, 08-M1 successMessage, 08-F Mrs Robin, 11-F Shadow). 치환은 **표시 시점에만**(`GlossaryText`가 이름을 일반 텍스트로 넣음 — 점선 단어가 되지 않음, 이름 변경 즉시 반영; 타자기·완료 문구는 `DetectiveName.address/title`). 이름 없음 → `Dear Detective,`, 이름이 `Detective …`로 시작하면 호칭 중복 없음. 저장·정답·단서·증거·힌트에는 플레이스홀더 금지(`detective_address_test`). 목록과 원문: `test/personalized_lines.dart` — 내용 고정(FNV) 테스트는 `withoutNames`로 원문을 복원해 **기존 해시 그대로** 비교. 새 줄을 개인화하면 이 목록에 추가
- **제품 방향 최종 결정 (2026-10-16): 계정·Firebase·클라우드 완전 제거 → 100% 오프라인, 기기당 탐정 1명(Boy/Girl 아바타 + 이름).** 회원가입·로그인·동기화·충돌 해결·여러 탐정 선택 UI와 코드·의존성·테스트·Firebase 설정 삭제. 미션 완료 연출에 축하 문구 + CONTINUE INVESTIGATION. 아바타 그림 2장은 Custom Asset Required(`assets/art/avatars/` 등록 완료 — 파일만 넣으면 됨, 없으면 잉크 모자 아이콘 + 글자). Tip 코인 대화상자 버튼 = GET MORE HINTS
- Season 1: Case 01~12 전부 구현 (Case 01 = 일반 미션 5 + Final, Case 02~12 = 3 + Final → 일반 미션 38개 + Final 12개)
- **Detective Reasoning Pass COMPLETE** (Case 02 pilot, Wave 1: 01·04·06·08·11, Wave 2: 03·07·10, Wave 3: 09)
- **Final Small Pass COMPLETE** (Case 06·08 Final의 정답 노출 제거, Case 08 동일인 판정을 플레이어가 하게 함)
- **Discovery Moment COMPLETE** (WELL DONE 화면을 대체)
- **Post-Discovery Small Pass COMPLETE** (Case 07 M3 카드 숨김, Story Evidence Card 2곳, 중복 transition 2줄)
- **Final Player Experience Audit (2026-10-07): 판정 B — SMALL EXPERIENCE PASS.** 구조 변경 불필요 (*Final UX Audit Result* 참고)
- **Investigation Board Flow Fix COMPLETE** (Audit P1): Case 01~11 Case Closed → Investigation Board → BEGIN INVESTIGATION. **PLAYTEST READY** — 다음은 실제 아이 플레이테스트 + 출시 polish
- **제품 방향 결정 (2026-10-12): TYPE B — Educational Detective Adventure** (English → Evidence → Deduction → Action). 설계: `LONDON_MYSTERY_TYPE_B_DESIGN.md`, 근거: `LONDON_MYSTERY_PRODUCT_AUDIT.md`, 구현 기록: `LONDON_MYSTERY_TYPE_B_IMPLEMENTATION.md`
- **TYPE B P0 COMPLETE** (2026-10-12): 부모 보고서 정직화, XP 규칙 2(힌트 무료·찍기 불리·소급 불변), 50개 미션 학습 설계 데이터. 정답 변경 없음.
- **Phase 4 Notebook & Cross-Case — P1-1·P1-2 COMPLETE** (2026-10-12, 사용자 승인): 증거 상세·단서 카드의 영어에 단어 뜻 보기(그 증거·단서가 발견된 **원래 사건의 glossary**, 미션과 같은 WORD CARD, `lookedUpWords`·Word Collector 연동), Operator Mode에서 열려 있는 사건 외 모든 사건 파일을 `REFERENCE`로 전체 열람(해결·XP·Evidence·Badge·행동 기록 없음, 일반 플레이 잠금 불변). P1-3·P1-4도 **구현 완료**(아래). P2 보류
- **Phase 4 P1-3·P1-4 COMPLETE** (2026-10-12, 사용자 승인): 12-M2 도착판 York 열차를 Platform 4로 + Grey "…small red clock, after the train from Edinburgh"(Case 04 승강장 + Case 02 after가 함께 필요), 12-F 첫 자물쇠 "the number of the platform whose clock is small and red"(Case 09 whose), 11-M3 Tip 1이 경비원의 "the station that never sleeps"를 Case 04 "where trains never sleep"과 연결. **정답(1140·487·King's Cross)·Evidence·결말 불변.** Archive 없이도 Tip으로 진행 가능
- **TYPE B Phase 3B (Case 09~11) COMPLETE** (2026-10-12, 사용자 승인): 12개 미션 오답 피드백 + Hint, 09-F 우산 함정에 whose 피드백, 10-M3 보기 Big Ben → Tower of London(단어 하나만 맞는 함정, **이름 표시는 유지 — 두 단어로 이름을 만드는 것이 퍼즐**), 11-M3 그림 이름 숨김, `ChoiceOption.altText`로 이름 없는 그림을 화면 읽기에 묘사(01-M4·04-M3 소급). **정답·결말·사건 간 연결 불변.** Essential 40 → 41. **Season 1 전체 적용 완료**
- **TYPE B Phase 3A (Case 06~08) COMPLETE** (2026-10-12, 사용자 승인): 12개 미션 오답 피드백 + Hint 정리(06-F·07-F·08-F의 보호 Hint는 그대로), 06-M2 카드 뒷면 "It is the colour of my hat"(앞 증언의 grey hat을 다시 읽어야 함). **정답·결말·Case 03 → 08 연결 불변.** 보호 규칙(Case 06 grey/hat/card, 07 gate, 08 button/coat/red/miss rose)을 오답 피드백에도 적용하는 테스트 추가. Essential 39 → 40. Case 09~11 미적용
- **TYPE B Phase 2 (Case 02~04) COMPLETE** (2026-10-12, 사용자 승인): 12개 미션 오답 피드백 + Hint 1 = 볼 곳 / Hint 2 = 핵심 영어 의미, 04-M2 보기 "Platform 1/4/7/9"(짐꾼 문장·"but no clock"을 읽어야 함), 04-M3 그림 이름 숨김. **정답 불변.** Essential 시즌 37 → 39. 03-F Hint는 Case 03 보호 규칙(Tip에 train/station 금지, 마지막 Tip = Notebook footprint)에 맞춤. 남은 사건(06~11)은 미적용
- **XP 규칙 3 + 탐정 행동 배지 COMPLETE** (2026-10-12, 사용자 승인): 규칙 2의 첫 시도 보너스가 운 좋은 찍기와 이해를 구분하지 못하고 오독 후 정정을 덜 보상하던 문제를 감사로 확인 → 모든 해결 동일 XP. 행동 배지는 UI 이벤트로만 기록, XP 없음
- **TYPE B 대표 Case COMPLETE** (2026-10-12, 사용자 승인): Case 01·05·12 — 보기별/입력별/순서 오답 피드백, 01-M1 박물관 보기·01-M2 STONE 노출 제거·01-M4 그림 이름 숨김, 05·12 Final 자물쇠 그림 제거(질문을 읽어야 함). **50개 정답 전부 불변.** 나머지 9개 사건은 미적용. 플레이테스트 미실시(계획: `LONDON_MYSTERY_LEARNING_PLAYTEST.md`)

### Current Quality Baseline
- `flutter analyze` → **0 issues**
- `flutter test` → **779 passed**
- 화면 검증 기준: 360×640, 390×844 (+ 글자 크기 1.3배) — *Testing* 참고

---

## Difficulty System (난이도 시스템, 2026-10-27 도입 결정)

- **인수인계 문서: `docs/DIFFICULTY_IMPLEMENTATION.md`** — 조사 결과(실제 파일 경로), 확정 정책, 기술 설계, PART별 상태·작업 이력, 다음 세션 인수인계, Case별 콘텐츠 적용 진행표. 난이도 관련 세부 사항은 그 문서가 기준이다(이 섹션은 요약).
- **현재 진행 PART: PART 0~5 COMPLETED(PART 5 `b6fb71e`) · PART 6A COMPLETE(London Case 01~03, `7bfa4a7`) · PART 7A COMPLETE(Paris Case 01~03, `f048688`) — 둘 다 main 통합(`6fd8dbb`, 전체 2416 통과). PART 7B·7C·7D COMPLETE(Paris Case 04~12, `19f924d`·`98bae78`·`85d0461`) → **Paris Season 2 Case 01~12 난이도 콘텐츠 완료**. PART 6B·6C·6D COMPLETE(London Case 04~12, `7038d4b`·`e89a342`·6D) → **London Season 1 Case 01~12 난이도 콘텐츠 완료**(미지원: Case 06 M1 증인 대화 `DialogueScene` — 기준본 대사).** 확정 정책(2026-10-27): Q1 기존 영어 = Rookie 기준본(PART 6~7에서 Rookie 문장도 검토), Q2 힌트는 개수·가격·정답 유지하고 문구의 직접성만 난이도별(기존 UI 범위 안 강조), Q8 부모 보고서 학습 표현은 실제 플레이 난이도에 맞춤. 인수인계·콘텐츠 형식·추리 결합 위험 표: `docs/DIFFICULTY_IMPLEMENTATION.md` G.
- PART 5로 생긴 것(난이도별 콘텐츠 엔진): `DifficultyContent`(`lib/data/content/difficulty_content.dart`) — 사건 JSON은 **텍스트 필드만** 난이도별 패치(`SeasonContent.casePatches`, 정답·ID·순서·힌트 개수 보호 → 위반은 `problems()`가 보고), 퍼즐·대화 등 Dart 객체는 난이도별 표(`SeasonContent.variants`)를 `SeasonCatalog`의 공통 `_pick`이 미션의 난이도로 고른다(53개 조회, 호출부 무수정). 대체 순서 Rookie→기준 / Junior→기준 / Master→Junior→기준, 완료 검사 `missingAt` + `writtenLevels`. 각 세션은 `playedEpisodesProvider`(기준 목록 × 시즌 유효 난이도)로 문장을 고르고, `Mission/Episode.difficulty`(저장 안 함)가 난이도를 실어 나른다 — 개발자 테스트 세션은 자기 난이도로 따로 계산. Paris Discovery 제목은 플레이 중 미션의 success 줄로 즉석 생성. 학습 표현은 난이도별 표 + `LearningCheck`(단어 단위 일치, 두 시즌 × 세 난이도 테스트). 샘플: London `ep02_m1`, Paris `s2_ep01_m1`(Junior·Master 일부)
- PART 4로 생긴 것(개발자 모드): `DevSessionHost`(`lib/features/game_master/dev_session.dart`, `DeviceDetectiveGate`가 사용) — 플레이어 컨테이너는 실행 내내 유지, **START DEVELOPER MODE**(테스트 빌드의 Game Master)마다 부모 없는 새 테스트 컨테이너 + `MemoryPreferences`(메모리 저장소) + TESTER/BOY/Rookie. 테스트 도구(CASE NN부터·사건 바로가기·처음부터·OPERATOR MODE·SEASON PREVIEW)는 테스트 세션의 Game Master에만, TEST LEVEL 카드(바꾸면 진행 중 Case만 Mission 1부터), EXIT DEVELOPER MODE·첫 페이지 시스템 Back으로 종료, 화면 우측 상단 `TESTER` 리본. 종료하면 플레이어 게임이 그대로(기기 저장 바이트 동일 — 테스트로 검증). 다음 플레이어 초기화·NEW ADVENTURE는 플레이어 쪽에서 기존 그대로
- **확정(APPROVED, 2026-10-27) 시즌 정책**: ① 시즌 초기화 시 코인 잔액·구매 힌트·다른 시즌 보상 유지, 재플레이 보상 중복 지급 금지 ② London 완료 후 Paris 진입 전에 난이도 변경 기회, Paris 완료 후 생략 ③ 시즌 난이도는 그 시즌 Case 01 인트로 최초 진입 시 고정(프롤로그만 본 상태는 변경 가능) ④ 진행 중 = 고정됨(또는 기존 사용자의 실제 진행 기록 있음) + 마지막 사건 미완료, 기존 진행 시즌은 Rookie
- PART 3으로 생긴 것: `SeasonLevel`/`seasonLevelProvider`(시즌 상태·난이도 판정, 읽기 전용), Story Intro 진입 시 `settleSeasonLevel`, `/detective`에서 난이도 변경(진행 중이면 "Restart your season?" — KEEP MY LEVEL / RESTART SEASON), `GameController.restartSeason`(그 시즌 사건·시즌 키만 빈 저장으로 덮어쓰기 + 지급 기록 없는 해결 미션 0코인 정산, 한 트랜잭션), London 마지막 Case Closed의 READY FOR YOUR NEXT MYSTERY?(KEEP MY LEVEL / CHANGE LEVEL 잉크 링크, GO TO PARIS 그대로), 시즌 기록 `nextLevelAsked`. 지갑은 원래 영구 지급 원장(`mission:<missionId>` 평생 1회)이라 시즌 초기화에서 지우지 않는다
- PART 2로 생긴 것: CREATE YOUR DETECTIVE(`/register`)의 이름 줄 아래 **CHOOSE YOUR LEVEL** — ROOKIE/JUNIOR/MASTER 세로 카드(각 카드 영어 설명 `Difficulty.blurb`, 선택 = antique gold 테두리 + 체크 원, 비선택 = 빈 원, 카드 전체 탭, 화면 읽기 selected/탭), 기본 Rookie, START INVESTIGATION 시 `createDetective(difficulty:)`로 프로필에 저장. 위젯 `DifficultyChoice`(`detective_form.dart`). `/detective` 설정 화면에는 없음. **`DetectiveDesk` 레이아웃: 폼이 화면보다 길면 폼만 스크롤되고 버튼은 아래에 고정**(다 들어가면 예전처럼 종이와 버튼이 함께 가운데) — 생성·설정 화면 공통. 키보드가 올라오면 난이도 영역은 접힘(선택 유지)
- PART 1로 생긴 것(화면 변화 없음): `lib/data/models/difficulty.dart`(`Difficulty` rookie/junior/master — 저장 식별자 `storageId`와 표시 이름 `label` 분리, 모르는 값 → rookie), 프로필 기본 난이도 `DetectiveProfile.difficulty`(`lm.detective.v1`에 `"difficulty"`, 없으면 rookie, `setDifficulty`), 시즌 고정 난이도 `SeasonProgress.difficulty`(London·Paris 각자 기록, 고정될 때만 JSON에 기록, `SeasonNotifier.fixDifficulty` — 호출하는 화면은 아직 없음), 실효 난이도 `seasonDifficultyProvider(seasonId)`·`currentDifficultyProvider` = 시즌 고정값 ?? 프로필 난이도(조회는 저장하지 않음). 키·스키마 변경 없음. 테스트 `test/difficulty_persistence_test.dart`. 2026-10-27 전체 `flutter test` 2277 통과, analyze 0 issues
- **London PART 6A (2026-10-27, `7bfa4a7`)**: London Case 01~03 Rookie(기준본 + 패치 4곳)·Junior·Master 완료(`lib/data/mock/season1/difficulty/ep0N_levels.dart`, `season1WrittenLevels`), 장면 5종 구조 검사(`DifficultyContent.structureOf`)·텍스트 전용 `copyWith`, 테스트 `test/difficulty_london_6a_test.dart`. 상세·영어 원문: `docs/difficulty_reviews/LONDON_CASE_01_03.md`. 다음: PART 6B(Case 04~06)
- **Paris PART 7A (2026-10-27, 브랜치 `feat/difficulty-paris-01-03`)**: Paris Case 01~03 Rookie(기준본 + glossary)·Junior·Master 완료(당시 `season2_difficulty.dart`, 지금은 `season2/difficulty/ep01~03_levels.dart`, `writtenLevels`), 장면 구조 검사 `season2_structures.dart`, 테스트 `test/difficulty_paris_7a_test.dart`. 상세·영어 원문: `docs/difficulty_reviews/PARIS_CASE_01_03.md`. 다음: PART 7B(Case 04~06)
- **Paris PART 7B (2026-10-27, main)**: Paris Case 04~06 Rookie(기준본 + glossary + 패치 2줄)·Junior·Master 완료(당시 `season2_levels_04_06.dart`, 지금은 `season2/difficulty/ep04~06_levels.dart`, `writtenLevels`), 구조 검사 `season2_structures.dart`에 장면 11종 + EasySteps 추가, 테스트 `test/difficulty_paris_7b_test.dart`. 상세·영어 원문: `docs/difficulty_reviews/PARIS_CASE_04_06.md`. 다음: PART 7C(Case 07~09). London PART 6B는 시작 전
- **Paris PART 7C·7D (2026-10-27, main)**: Paris Case 07~12 Rookie(기준본 + glossary, Case 09 패치 1줄)·Junior·Master 완료(당시 `season2_levels_07_09.dart`·`season2_levels_10_12.dart`, 지금은 `season2/difficulty/ep07~12_levels.dart`), 구조 검사 17종 추가(장면 14종 + `TalkScene`·`TalkMission`·`List<EndingLine>`), 엔진은 회상 오답 줄(`recall.feedback`) 패치만 추가. 테스트 `test/difficulty_paris_7c_test.dart`(30)·`7d_test.dart`(36, 시즌 전체 검증). 상세·영어 원문: `docs/difficulty_reviews/PARIS_CASE_07_09.md`·`PARIS_CASE_10_12.md`. 다음: London PART 6B
- 계획: PART 0 조사·설계 / 1 모델·저장 / 2 프로필 생성 UI / 3 시즌 난이도 변경·초기화 / 4 개발자 모드 개선 / 5 난이도별 영어 콘텐츠 시스템 / 6 London 콘텐츠 / 7 Paris 콘텐츠·최종 검증(6·7은 Case 단위로 세분 가능, 세부 작업마다 테스트·문서·커밋)
- 확정 정책 요약:
  - 난이도 **Rookie(기본) / Junior / Master** — 바뀌는 것은 영어(스토리·대사·편지·단서 설명·퍼즐 문장·선택지 표현·힌트 문구와 제공 방식·안내 문구·어휘)뿐. **사실관계·결말·퍼즐 구조·단계 수·선택지 수와 순서·정답·증거 ID·보상·시즌 순서는 모든 난이도에서 동일.** Master도 조작 안내는 명확하게
  - 프로필 생성(CREATE YOUR DETECTIVE)에서 아바타·이름과 함께 난이도 선택 — 같은 화면의 심플한 카드형 UI(별도 BottomSheet 아님), 각 카드에 짧은 영어 설명
  - 난이도는 시즌 단위로 고정: 시즌 시작 전 자유 변경 / 진행 중 변경 = 확인 후 **그 시즌만 초기화**(취소 시 그대로, 다른 완료 시즌 보존) / 완료 후 다음 시즌 난이도를 한 번만 물음(완료 시즌은 초기화하지 않음)
  - 개발자 모드는 일반 데이터와 분리: TESTER·BOY·난이도 자유 선택, **진입할 때마다 테스트 진행 초기화**, 같은 세션 안에서는 유지, 일반 프로필·XP·증거·힌트·퍼즐 상태에 영향 없음. Game Master의 다음 플레이어 초기화는 변경하지 않음
- 다음 세션 시작 방법: 이 파일 → `docs/DIFFICULTY_IMPLEMENTATION.md`(특히 *G. 다음 세션 인수인계*, *I. 미결정 사항*) → `git status`·`git log -3` 확인 → 해당 PART 범위만 작업 → 관련 테스트 + 전체 회귀 → 두 문서 갱신 → 그 PART 파일만 커밋(푸시 없음)

---

## Play Flow (현재)

### 시즌 진입
Title(`/`) → **CREATE YOUR DETECTIVE**(`/register`: BOY/GIRL + 이름 + 난이도(ROOKIE 기본/JUNIOR/MASTER) → START INVESTIGATION, 기기당 1명) → How to Play(처음 1회) → Season Cover(`/season`, 시즌 시작 전) → Opening 5장면 + Case 01 파일(`/season/prologue`) → Story Intro(`/intro`) → Map(`/map`)

### 일반 Mission (38개)
```
Map → GO(카메라 줌 ~1.4s) → Mission: 장소(INVESTIGATE) → 봉투(TAP TO OPEN, 850ms) → 편지(SOLVE THE PUZZLE) → Puzzle
  → 정답 → DISCOVERY MOMENT → CONTINUE(사용자만) → Story Scene(transition, 타자기) → TO THE MAP → Map(새 장소로 카메라 이동 + 해금 연출)
```
- **정답 순간에 저장 완료**(완료·Clue·Evidence·배지). Discovery·Story는 보여주기만 한다.
- 오답 → "Not quite!" 시트(TRY AGAIN / GET A TIP). 횟수 제한·감점 없음. 미션 데이터에 그 오답의 한 줄(`ChoiceOption.feedback` / `Mission.feedback` / `Mission.orderFeedback`, `AnswerChecker.feedbackFor`)이 있으면 일반 문구 대신 표시(무엇을 잘못 읽었는지, 정답은 말하지 않음 — `type_b_cases_test`가 강제). 현재 **Season 1 전 사건(01~12)**. **오답 피드백도 사건의 추리 보호 규칙(금지어)을 지킨다** — `type_b_phase3a_test`

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
- 화면 순서: ① 축하 문구(`DiscoveryType.cheer`: DEDUCTION → Brilliant Deduction! / EVIDENCE·CLUE FOUND → Clue Discovered! / CLUE CONFIRMED·STORY DISCOVERY → Excellent Detective Work! / NEW LEAD·PUZZLE COMPLETE → You Made It! — 퍼즐 전 정보에 Discovered 금지, 종류 라벨은 화면 읽기에만, + `ALSO A SEASON CLUE`) ② 큰 제목 ③ (선택) Evidence 카드(사건 종료 카드와 같은 `EvidenceChip` 종이 카드, 탭 → 확대) ④ 한 문장 detail ⑤ (선택) `NOTED IN YOUR NOTEBOOK` + Puzzle 전에 본 사실 ⑥ 작은 `+XP · +COINS`(다시 푼 미션은 *Already in your case file*) ⑦ 새 배지 한 줄 ⑧ CONTINUE INVESTIGATION(glass)
- 배경: 현재 미션 장소의 장면(`PlaceScenery(PlaceArt.sceneryOf(m))`, Story Scene과 같은 공용 위젯 `lib/widgets/place_scenery.dart`) — "현장에서 발견"
- 동작: 2.2s 순차 등장(튀는 효과·컨페티 없음), **탭 = 즉시 완성**, 모션 줄이기 = 즉시 완성, CONTINUE는 한 번만, **자동 이동 없음**. Android Back = 오버레이 닫힘 → Story(이전 WELL DONE과 동일, 정답은 이미 저장)
- 테스트용 key: `ValueKey('discovery-moment')`(아래 페이지는 해결 상태로 다시 그려져 있으므로 finder는 이 안으로 한정)
- 분포: DEDUCTION 12 · NEW LEAD 9 · EVIDENCE FOUND 9 · CLUE CONFIRMED 3 · CLUE FOUND 3 · STORY DISCOVERY 2. Evidence 카드 표시 11곳(Case 07 M3 제외 후, Wave 1에서 03-M1 추가), notebook note 6곳, season clue 2곳(02-M2 기어, 05-M3 Brass Key)

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
| 05 | M1 5시 · M2 기어 4개 · M3 까마귀 7 → 순서를 바꾼 질문 → **745**. 자물쇠에 그림 없음(TYPE B): 뚜껑 질문을 읽어야 순서를 앎. 찾은 순서 547 → 순서 피드백 |
| 06 | Final 관찰(tall man, small bag, 물가에서 잃어버린 것) + M1 작은 가방·카드를 떨어뜨림 + M3 키 큰 남자 vs 키 작은 여자(Raven Society) + M2 Detective Card → **Inspector Grey** (Final 화면에 grey/hat/card 없음). M2(TYPE B): 카드 뒷면 "the colour of my hat" → M1 증언의 grey hat을 다시 읽어 GREY |
| 07 | Grey 경로(다리 건너 **왼쪽**) + M3 Joined Map 화살표 **north** → old gate 지도(B). Final 보기는 A~D 글자만. **Discovery에서 "old gate" 노출 금지** |
| 08 | Mrs Robin "Gallery 8에 간 적 없다" + M2 긴 빨간 코트(Clue note에도) + **Case 03 Red Button**(From a coat, GALLERY 8) → Red Button → Post-Case가 Miss Rose = Mrs Robin 확인. Final 화면에 button/coat/red 없음 |
| 09 | M1 **guard's** key → 쪽지 "the one **whose** key you used"(쓴 사람 Anna가 아님) → Carl → 소거(Ben = 가방, Anna ≠ 검정) → **HAT** |
| 10 | M2 NORTH · TOWER · BRIDGE · THREE → M3 TOWER + BRIDGE = **Tower Bridge**(Story에 Tower Bridge·north tower·3시 미리 쓰지 않음). Final은 문장 순서(독립 ORDER 퍼즐 — 다양성 예외로 유지). M3(TYPE B): 보기에 Tower of London(TOWER 하나만 맞는 함정), 이름 표시 유지 |
| 11 | Case 01 Old Letter "Signed: The Shadow / P.S. I love trains!" → **The Shadow**. M3(TYPE B): 그림 이름 숨김 — 택시 기사의 묘사(two big arches, clock tower)로 선택. M3 Tip 1: "never sleeps" → Case 04 |
| 12 | M2 Case 04 Platform 4(작은 빨간 시계) → 11:40, M1 톱니 8, (Case 05) 까마귀 7 → **487**. 자물쇠에 그림 없음(TYPE B): 문에 새긴 질문 순서. 찾은 순서 847 → 순서 피드백. M2(Phase 4): 4번 승강장 열차가 둘(10:15·11:40) — "after the train from Edinburgh"가 11:40을 고름. Final 첫 줄: "the platform whose clock is small and red" |

### Cross-case callbacks
| From → To | 내용 | 등급 |
|---|---|---|
| 04 → 12 | Platform 4 = small red clock → 12-M2 도착 시각, Final 기차 자물쇠 | **R3** (Archive 3탭) |
| 02 → 12 | before/after → 12-M2 "after the train from Edinburgh"(4번 승강장 두 열차 중 하나) | **R3**(표현) |
| 09 → 12 | whose → 12-F "the platform whose clock is small and red" | **R3**(표현, 답은 이번 사건 단서로도 확인) |
| 04 → 11 | "where trains never sleep" → 11-M2 "the station that never sleeps" → 11-M3 Tip 1 | **R2~R3**(표현, Tip이 연결) |
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
  - **플레이어 탐정 표정(2026-10-17)**: `assets/art/detectives/<boy|girl>/<thinking|surprised|investigating|happy|confident>.png`. 경로·크롭은 `ArtAssets.detective / detectiveCrop`(avatar null = boy), 표시는 `lib/widgets/detective_character.dart`(`DetectiveCharacter` — `DetectiveStyle.portrait` 금색 메달리온 / `.illustration` 원본 비율 상반신·아래 22% 페이드·선택적 램프빛, `PlayerDetective` = 저장된 프로필 구독, `DetectiveMoment` = 장면별 표정+기본 스타일, `DetectiveCast.shown` = 표시 스위치). **파일은 RGBA 컷아웃**(배달본은 체커보드가 구워진 RGB → 한 번 배경 제거 후 원본 RGB 폴더와 재생성 도구는 삭제(2026-10-17, 의도적). 남은 도구는 검수 시트 `tool/detective_cutout/review_sheet_test.dart`). 배치: 장소 INVESTIGATE·수색 시작 버튼 옆(investigating, portrait 42), "Not quite!" 시트(thinking, portrait, 돋보기 자리), Discovery 축하 문구 위(EVIDENCE/CLUE FOUND = surprised, 그 외 happy, illustration 120/160), Case Closed 파일 뒤에서 상반신(confident, illustration 150/190, 파일이 허리를 덮음), How to Play 연습 퍼즐 결과(happy/thinking, portrait). 퍼즐 화면 자체·선택지·Final 퍼즐 화면에는 없음. 테스트 `player_detective_test`
  - Case 05 Final: `objects/iron_chest.png` / Case 12 Final: `objects/small_iron_door.png`
  - Case 07 지도 퍼즐: parkMapA~D(코드 그림). Final 보기 이름은 화면에 표시하지 않음(A~D)
  - Case 08: 검은 가방(blackSuitcase), Case 01·04: 갈색 가방(oldSuitcase)
  - 이미지 선택 퀴즈 타일: 랜드마크는 그림 아래 이름 표시, **공원 지도(Case 07)와 `hideOptionNames` 미션(01-M4, 04-M3, 11-M3)은 이름 숨김** — 이 셋은 화면 읽기가 이름 대신 그림 묘사(`ChoiceOption.altText`, "Picture C: …")를 읽음. 랜드마크 PNG 속 이름 두루마리는 타일에서 잘림(스크린샷 확인). 10-M3는 이름이 퍼즐이라 표시(화면 읽기 라벨도 `Picture C`). (이전 문서의 "이름표를 숨김"은 사실과 달랐음 — 2026-10-12 감사에서 확인)

---

## Architecture

```text
lib/
├── main.dart, app.dart          # SharedPreferences·카탈로그 선로딩, MaterialApp.router, 글자 1.3배 clamp, lifecycle → 플레이 시계
├── core/ constants · router(app_router.dart: Routes + redirect 가드) · theme(app_colors, app_text, app_tokens, app_theme) · utils(answer_checker, audio_service, formatters)
├── data/
│   ├── models/      episode, mission(Mission/Clue/Evidence/ChoiceOption/MissionType/Artwork), game_progress, season, season_progress, discovery
│   ├── mock/season1/ episode01~12_mock.dart(백엔드 JSON과 같은 const Map), season1_mock.dart(카탈로그·시즌 정보), season1_discoveries.dart
│   └── repositories/ EpisodeRepository(+Mock), ProgressRepository(+SharedPrefs, InMemory), SaveJournal(원자적 저장), ProfileStore(단일 탐정 `lm.detective.v1`), LegacyMigrator(이전 저장 → 탐정)
├── features/
│   ├── onboarding/  start, register(CREATE YOUR DETECTIVE + DetectiveDesk), detective_form(아바타·이름 줄), detective_settings(/detective), detective_hold(보류 화면 + DeviceDetectiveGate), how_to_play, episode_select(Case Files), story_intro
│   ├── season/      season_screen(Cover/Board), season_prologue_screen, season_overview, season_actions, widgets(investigation_board, prologue_art, season_props)
│   ├── mission_map/ mission_map_screen(Map Camera), map_world, widgets(london_map_painter, map_pin)
│   ├── mission/     mission_screen, story_scene_screen, final_mission_screen, widgets(question_widgets, scene_deduction, scene_decode, answer_feedback = Discovery Moment·Try Again·TipsPanel, …)
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
| `/register` | CREATE YOUR DETECTIVE | 탐정이 **없을 때만** (있으면 `/`) |
| `/detective` | My detective(이름·아바타 변경, 진행 유지) | 탐정 등록 |
| `/season` | Cover(시즌 시작 전) / Investigation Board | 탐정 등록 |
| `/season/prologue` | Opening 5장면 + Case 01 파일 | 탐정 등록 |
| `/episodes` (`?case=epNN`) | Case Files(해당 사건 열림·선택) | 탐정 등록 |
| `/intro` | Story Intro | 탐정 등록 |
| `/map`, `/notebook`(`?view=archive`) | 지도 / 노트북 | + introSeen |
| `/mission/:id` | Mission(일반만) | 해금된 미션 |
| `/story/:id` | Story Scene(일반 = transition, Final = Post-Case) | 해당 미션 해결 후 |
| `/final` | Final | 그 사건 일반 미션 모두 해결 |
| `/solved` | Case Closed | 사건 해결 후 |
| `/report` | Parent Report | 사건 해결 + Parent Gate 통과권 |
| `/game-master` | Game Master | Parent Gate |

### Persistence
- **100% 오프라인, 기기당 탐정 1명** (`docs/OFFLINE_SINGLE_DETECTIVE.md`). 탐정 기록 `lm.detective.v1` = `{profile: {id, detectiveName, avatar, createdAt, origin, walletBackfill}, held: [보류된 이전 프로필 id]}`
- 진행 키(탐정 네임스페이스): `lm.p.<id>.progress.v1`(Case 01) / `…progress.v1.epNN` / `…season.v1` / `…wallet.v1` / `…journal.v1`(여러 키 저장 중에만). 프로필 이전 원본 `lm.progress.v1…`·`lm.season.v1`·`lm.wallet.v1`은 보존(GM 초기화만 삭제). 계정 빌드의 `lm.profiles.v1`, `…conflicts.v1`, `…outbox.v1`, `…cloud.v1`, `…meta.v1`, `lm.device.v1`은 읽기만/무시하고 지우지 않음. 기기 설정 `lm.settings.sound`
- 시작 시 `LegacyMigrator`: 기록 있음 → 그대로 / 계정 빌드 목록만 있음 → 진행 기록 있는 프로필 1개를 탐정으로(0개면 게스트), **2개 이상이면 보류 화면(보호자 선택, 아무것도 쓰지 않음)** / 그 외 레거시 복사·검증·안전 모드(기존 규칙)
- `GameProgress`: detectiveName, introSeen, completedMissionIds(해결 순서), attempts, wrongAnswers, hintsUsed, missionStartedAt, missionStartPlayMillis, solveSeconds, badgeIds, lookedUpWords, **lookupsRecorded**(단어 목록이 없던 세이브 = false, 저장 후에도 유지), **xpRules**(미션 → XP 규칙 번호 1·2·3, 비어 있으면 JSON에 안 씀), **behavior**(`BehaviorLog`: rechecked·evidenceViewed·words, 키가 없으면 "기록 없음" — 새 실행은 항상 기록), startedAt, completedAt, playMillis. 관대한 fromJson, 손상 시 새 게임
- Play again = 현재 사건만 초기화(시즌 해결 기록 유지 → 다음 사건 잠기지 않음, 다시 푼 미션은 코인 0·"Already in your case file"). NEW ADVENTURE(확인 대화상자) = **같은 탐정(ID·이름·아바타 유지)**, 사건·시즌·XP·배지 초기화, 새 지갑(시작 코인) → How to Play(미시청 시) → 시즌 케이스북. Game Master 초기화 = 진행 + 탐정(이름·아바타) 삭제 + 레거시 원본 삭제 → CREATE YOUR DETECTIVE

---

## Game Systems

- **XP** (`scoring.dart`, 저장 안 함·매번 계산 — 단 미션별 **규칙 번호**는 정답 순간 `GameProgress.xpRules`에 기록): **규칙 3**(현재) = 정답에 도달하면 일반 100 / Final 200, 오답·힌트·시간 무관(보너스 없음). **규칙 2**(기록된 미션만) = 기본 + 첫 시도 +50 / 두 번째 +25. **규칙 1**(기록 없는 미션 = TYPE B 이전 세이브) = 기본 + 노힌트 +50(1개 +25) + 스피드 +20. 기존 XP 소급 변경 금지. 표시: Discovery(작게), 지도 메뉴, Case Closed. **XP로 열리는 것은 없음**. 사건별 저장 하나뿐이라 재플레이는 누적되지 않음
- **Hint**: 미션당 최대 2개(약 → 직접), **무료**("Tips are free. Good detectives use them."). 오답 횟수 무제한·감점 없음 → 아이 혼자 진행 가능
- **Badge** (`GameBadge`, 저장은 이름 문자열 — id 변경·삭제 금지): 진행 배지 4개(First Clue, Puzzle Solver, London Explorer, Master Detective) + **탐정 행동 배지 3개**(아래) + Case Badge 6개(02 Clock Watcher, 03 Evidence Hunter, 04 Letter Reader, 05 Code Breaker, 07 Map Master, 12 London Legend), 사건마다 수여. **Sharp Eyes·Quick Thinker는 retired**: 신규 지급 없음, 이미 받은 세이브에서만 표시(`GameBadge.shownFor`), 설명은 "이전 버전에서 …받은 배지". 행동 배지(XP 없음, 사건당 1회): **Second Look** = 오답 후 · 해결 전에 편지 다시 읽기(Letter) 또는 수첩/Archive/Final 수첩의 증거 열기 → 같은 미션 정답 / **Notebook Explorer** = 사건 해결 중 수첩·Case Archive·Final 수첩에서 증거 1개 이상 자세히 보기(진입만으로는 아님) / **Word Collector** = 이번 실행에서 서로 다른 단어 3개 뜻 보기. 기록은 `GameProgress.behavior`(`BehaviorLog`); 키가 없는 옛 세이브는 기록 없음 → 그 실행에서는 행동 배지 없음(추정 소급 금지), Play again부터 기록. Discovery에 "New badge:" 한 줄
- **Learning design** (`season1_learning.dart` + `models/learning.dart`): 50개 미션 전부 학습 설계(dependency essential 42 / helpful 5 / low 3 (Season 1 전체 개선 + Wave 1 03-M1 탐색 후), level, objective, expressions, recallFrom) + 사건별 언어 주제. **콘텐츠이며 저장되지 않고 성취가 아님**. Case JSON은 건드리지 않는 별도 매핑. 규칙은 `learning_objectives_test`가 강제(표현이 실제 콘텐츠에 있음, essential만 exposure 초과 수준)
- **Evidence/Clue**: 미션 데이터, `completedMissionIds`에서 파생. 노트북 확대(`showEvidenceZoom`: 이름·장소·설명·글귀)
- **Notebook**: THIS CASE(CLUES / EVIDENCE / BADGES) + CASE ARCHIVE(12 사건 폴더, SOLVED 사건은 전체 Evidence·Clue; **Operator Mode면 열린 사건 외 전부 `REFERENCE`로 전체 공개 — 기록 없음**). 증거 상세·단서 메모의 영어는 **원래 사건 glossary**로 단어 뜻 보기(`GlossaryText(episode:)`, `caseOfEvidence`/`caseOfClue`). 경로: 미션 앱바 노트북 / Final `OPEN MY NOTEBOOK` → `OPEN THE CASE ARCHIVE`(이전 해결 사건이 있을 때). 이전 사건 Evidence 글귀까지 Final에서 4탭
- **Play Time**: foreground 활성 시간만(`playMillis`), Story Intro 종료부터 Final 해결까지
- **Parent Report**: Case Closed → Parent Gate(곱셈) → 1회용 통과권. **측정된 사실만**(TYPE B P0): English in This Case(사건 언어 주제 + 미션별 학습 설계, "측정 결과 아님" 명시) → Words Checked(실제 찾아본 단어 + 뜻) → **Detective Actions**(새 기록: 막혔을 때 다시 확인한 미션 수, 수첩에서 살펴본 증거 수 — 옛 세이브는 "기록 없음") → Play Record(해결 미션, 열어 본 힌트, 첫 시도 n/기록 m, 플레이 시간) → Game Master's Note(관찰 사실). 영어 별점·정답률·능력 단정 문구 없음. 시도 기록 없는 미션/사건(플레이테스트 도구 seed, 옛 세이브)·단어 기록 없는 세이브 → "기록 없음"
- **Game Master / Playtest tools**(debug 또는 `--dart-define=LM_PLAYTEST=true`): CASE NN부터, 지금 사건 처음부터, OPERATOR MODE(모든 사건 열기, 해결 기록 없음). **2026-10-27(난이도 PART 4)부터 이 도구들은 개발자 모드(TESTER 메모리 테스트 세션) 안에서만** 보이고 동작한다 — 플레이어의 저장에는 쓰지 않음(*Difficulty System* 참고). 현장 비치용 QR 카드·카메라 없음(2026-10-19 Case 01 M5가 화면 안 카드 조사로 바뀌며 제거)

---

## Testing

- 실행: `flutter analyze`, `flutter test`. 스크린샷: `LM_SCREENSHOTS=<폴더> flutter test <파일>`, UI 투어: `LM_TOUR=<폴더> [LM_TOUR_SMALL=1] flutter test test/ui_tour_test.dart`
- 추리/Discovery 회귀 테스트 (문구를 바꾸면 반드시 확인):
  - `case02_reasoning_test.dart`, `wave1_reasoning_test.dart`(01·04·06·08·11), `wave2_reasoning_test.dart`(03·07·10), `case09_reasoning_test.dart`, `final_small_pass_test.dart`(06·08 + **다른 사건 JSON 해시** — 다른 사건을 일부러 바꾸면 그 해시를 갱신)
  - `discovery_moment_test.dart`(38 매핑, timing, 시점 예외, 표시·흐름·XP·배지·모션·Back, 38개 × 2 크기 렌더), `post_discovery_pass_test.dart`(Case 07 노출, 중복 줄, Story 카드·확대·재시작), `investigation_board_flow_test.dart`(Case 01~11 OPEN CASE → Board·figure·현재 사건, BEGIN, Back, 다시 플레이 예외, 재시작, Case 12 불변, 실제 Case 04 흐름)
  - Phase 4: `cross_case_language_test.dart`(12-M2 도착판 논리·after, 12-F whose·숫자 미노출, 11-M3 never sleeps ↔ Case 04, Archive 없는 경로, 2 크기), `notebook_cross_case_test.dart`(증거·단서 → 사건 매핑, Archive에서 원래 사건 glossary, Word Collector 연동, Operator 참고 공개·기록 없음·잠금 유지, 2 크기). Notebook/증거 글자는 rich text라 테스트는 `findReadable`(`helpers.dart`)로 찾는다(`find.text`는 "(tap for meaning)" 라벨까지 읽음)
  - TYPE B: `learning_objectives_test.dart`(50 매핑·표현 실재·정직성·분포), `type_b_p0_test.dart`(옛 세이브 XP 불변, 기록 없음, 힌트 무료, 읽기 > 찍기, 재플레이 비누적, 보고서 단정 문구 없음, 2 크기 렌더), `type_b_phase3b_test.dart`(Case 09~11 정답 불변·피드백·보호 규칙 피드백 확장·사건 간 연결·이름 없는 그림의 대체 텍스트·11-M3 화면 2 크기·XP), `type_b_phase3a_test.dart`(Case 06~08 정답 불변·피드백·보호 규칙의 피드백 확장·Case 03 → 08·06-M2 카드 경로·XP·화면 2 크기), `type_b_phase2_test.dart`(Case 02~04 정답 불변·오답 보기 피드백·미션별 오독·학습 설계·XP 규칙 3·화면 2 크기), `type_b_rewards_test.dart`(XP 규칙 3 시나리오 1~7, 규칙 1·2 보존, 옛 세이브 로드, retired 배지, Second Look·Notebook Explorer·Word Collector 조건과 실제 UI 이벤트, 재플레이, 사건 문구, 부모 보고서), `type_b_cases_test.dart`(피드백이 정답에 붙지 않음·정답을 말하지 않음, Case 01·05·12 동작, 오답 시트 2 크기). 콘텐츠를 바꾸면 `final_small_pass_test`의 사건 해시도 갱신(이번에 ep01·05·12)
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
- [ ] 실기기 확인 필요: lifecycle(홈·앱 전환·잠금 시 플레이 시간), 사운드, Title ambient(Impeller blend 수정 후), Case 01 M5 카드 터치 영역·스캔 연출
- [ ] foreground 강제 종료 시 마지막 행동 이후 플레이 시간 손실(의도된 트레이드오프)
- [ ] 정답이 앱 번들에 포함(오프라인 게임이라 허용, 백엔드 도입 시 서버 검증 필요)
- [ ] 웹 배포 시 보안 헤더는 호스팅에서 설정
- [ ] 런처 아이콘·스플래시 기본값, 효과음은 타자 소리·버튼 탭만 남김(나머지 효과음·환경음 없음), BGM·TTS 없음
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
- `Proposed`(미승인): 탐정 등급/칭호, TTS. (Season 2(Paris)는 구현됨. **난이도는 2026-10-27 승인 — *Difficulty System* 섹션, `docs/DIFFICULTY_IMPLEMENTATION.md`**)

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
난이도 시스템 작업(PART 1~7)은 추가로 `docs/DIFFICULTY_IMPLEMENTATION.md`를 읽고, 끝나면 그 문서의 E(상태)·F(이력)·G(인수인계)·H(진행표)를 갱신한다.

---

## Change Log (요약 — 상세는 git 기록)
- 2026-10-28 — **World Mystery 리브랜딩**: 패키지 `world_mystery`, 앱 ID `com.worldmystery.app`(Android applicationId·namespace, iOS Bundle ID), 표시 이름·타이틀 로고 `WORLD / MYSTERY`·브랜드 문구 변경, `LondonMysteryApp` → `WorldMysteryApp`. 저장 키(`lm.*`)·시즌/Case ID·스토리·에셋 불변. 앱 ID가 바뀌어 기존 `com.londonmystery.app` 설치본과는 별도 앱(진행 기록 이전 없음)
- 2026-10-27 — **Paris 난이도 파일 Case별 분리(main, `77e65d2`)**: London과 같은 `lib/data/mock/season2/difficulty/ep01~12_levels.dart` + 공통 빌더 `difficulty/level_words.dart`, `season2_difficulty.dart`는 등록만, 묶음 파일 3개 삭제. 영어 문장·데이터 불변(변경 전후 덤프·문자열 리터럴 비교 동일). analyze 0, 전체 2581 통과
- 2026-10-27 — **난이도 시스템 PART 6B·6C·6D(London Cases 04~12 영어 콘텐츠, main)**: 6B `7038d4b`·6C `e89a342`·6D. `difficulty/ep04~12_levels.dart`, Rookie = 기준본, Junior·Master 전 문장 + Discovery·학습 표현. 엔진·UI 무수정, Case 06 M1 대화 미지원(ep06 writtenLevels = rookie). 테스트 6b/6c/6d, 전체 2573 통과, analyze 0
- 2026-10-27 — **난이도 시스템 PART 7C·7D(Paris Cases 07~12 영어 콘텐츠 + 시즌 전체 검증, main)**: 7C `98bae78`(Case 07~09, 회상 오답 줄 패치, 장면 구조 검사 10종, 전체 2476 통과), 7D `85d0461`(Case 10~12, 대화·결말 구조 검사, 시즌 12 Case × 3난이도 누락·구조·Discovery·학습 표현·공개 시점 검증, 전체 2512 통과). analyze 0. 검토 보고서 `PARIS_CASE_07_09.md`·`PARIS_CASE_10_12.md`. 다음: London PART 6B
- 2026-10-27 — **난이도 시스템 PART 7B(Paris Cases 04~06 영어 콘텐츠, main)**: Case 04~06 Junior·Master 전 문장(사건·미션·오답·단서/증거 설명·장면 5종·EasySteps 3개·Discovery·학습 표현) + Rookie 패치 2줄·glossary, 구조 검사 장면 11종 + EasySteps. 신규 테스트 30개, analyze 0, 전체 2446 통과. 검토 보고서 `docs/difficulty_reviews/PARIS_CASE_04_06.md`. 다음: PART 7C
- 2026-10-27 — **난이도 PART 6A / 7A main 통합**: London `7bfa4a7`(merge `908c7eb`) → Paris `f048688`(merge `6fd8dbb`), 통합 전 main `b6fb71e`는 `backup/main-before-6a-7a`. 충돌은 `docs/DIFFICULTY_IMPLEMENTATION.md` F 한 곳(두 항목 모두 유지), 코드는 자동 병합(두 시즌 구조 검사·`writtenLevels` 모두 유지). analyze 0, 전체 2416 통과. 다음: PART 6B / 7B
- 2026-10-27 — **난이도 시스템 PART 6A(London Cases 01~03 영어 콘텐츠, 브랜치 `feat/difficulty-london-01-03`)**: Case 01~03 Junior·Master 전 문장(사건·미션·오답·Notebook·증거 설명·장면 5종·Discovery·학습 표현) + Rookie 패치 4곳, 장면 구조 검사 5종·텍스트 전용 `copyWith`. 세 난이도 추리 보호 테스트 30개, 전체 2390 통과, analyze 0. 검토 보고서 `docs/difficulty_reviews/LONDON_CASE_01_03.md`. 다음(London): PART 6B
- 2026-10-27 — **난이도 시스템 PART 5(난이도별 영어 콘텐츠 엔진)**: 사건 JSON 텍스트 필드 패치 + 퍼즐 객체 난이도별 표(공통 `_pick`), 대체 규칙·완료 검사·구조 불변 검증, 세션별 `playedEpisodesProvider`, Paris Discovery 즉석 생성, 학습 표현 난이도별 + 일치성 검사. 샘플 ep02_m1·s2_ep01_m1. 새 테스트 29개, 기존 테스트 무수정, 전체 2360 통과, analyze 0. 다음: PART 6A
- 2026-10-27 — **난이도 시스템 PART 4(개발자 테스트 세션 격리)**: 개발자 모드 = 진입마다 새 독립 컨테이너(부모 없음) + 메모리 저장소 + TESTER/BOY/Rookie, 테스트 도구는 그 안에서만, TEST LEVEL 변경 시 현재 Case Mission 1부터, EXIT·시스템 Back으로 종료, 플레이어 게임은 같은 컨테이너로 복귀(기기 저장 바이트 동일). 새 테스트 9개, 기존 테스트 무수정, 전체 2331 통과, analyze 0. 다음: PART 5
- 2026-10-27 — **난이도 시스템 PART 3(시즌 난이도 정책, 사용자 승인 정책 4개)**: Case 01 인트로 진입 시 시즌 난이도 고정, `/detective` 난이도 변경(진행 중이면 확인 후 그 시즌만 재시작 — 코인·구매 힌트·다른 시즌 보존, 재플레이 중복 지급 없음, 저널로 중간 종료 복구, safe mode 레거시 부활 방지), London 완료 후 Paris 난이도 1회 안내(Paris 완료 후 없음), 기존 진행 시즌은 Rookie·진행 보존. 새 테스트 30개, 전체 2322 통과, analyze 0. 다음: PART 4
- 2026-10-27 — **난이도 시스템 PART 2(프로필 생성 난이도 선택 UI)**: CREATE YOUR DETECTIVE에 CHOOSE YOUR LEVEL 카드 3개(기본 Rookie) → 프로필 `difficulty` 저장. `DetectiveDesk`는 폼이 넘칠 때 버튼을 화면 아래에 고정(기존 "도착 시 버튼이 화면에" 보장 유지). 게임 문장 변화 없음. 새 테스트 15개, 전체 2292 통과, analyze 0. 다음: PART 3
- 2026-10-27 — **난이도 시스템 PART 1(모델·저장 구조)**: `Difficulty` enum, 프로필 기본 난이도(`lm.detective.v1`의 `difficulty`, 없으면 rookie), 시즌별 고정 난이도(`SeasonProgress.difficulty`, 고정 시에만 기록), 실효 난이도 provider, `createDetective`의 선택 인자(UI 미연결). 화면·콘텐츠 변화 없음. 새 테스트 21개, 전체 2277 통과, analyze 0. 다음: PART 2
- 2026-10-27 — **난이도 시스템 PART 0(조사·설계 문서)**: 코드 변경 없음. `docs/DIFFICULTY_IMPLEMENTATION.md` 신규(프로필·저장·마이그레이션·시즌 해금·개발자 도구·콘텐츠·힌트·글로서리 구조 조사, Difficulty enum·프로필/시즌별 저장·콘텐츠 패치와 fallback·힌트 정책·개발자 세션 격리·마이그레이션 설계, PART 계획, Case별 진행표). 이 파일에 *Difficulty System* 섹션 추가. 다음: PART 1
- 2026-10-19 — **Case 01 Case Closed 파일: 기울어진 사건 사진 → 왕관 하나**(사용자 요청). 탐정 이름 옆 작은 열린 상자 사진(흰 폴라로이드·회전·그림자, 그 위로 SOLVED 도장이 찍혀 갈색 선처럼 보임)을 Case 01에서만 빼고, 사건 제목 아래 가운데에 `assets/art/objects/crown_cutout.png`(원본 `crown.png`는 불투명 양피지 바탕이라 보존, `tool/crown_cutout/cutout_test.dart`로 오려냄: 밝고 노란기 적은 양피지를 테두리에서·아치 사이 큰 구멍(2500px+)까지 제거, 띠의 하이라이트 유지, 모서리 반짝이 표식 제거, 512² 정사각) 프레임·그림자 없이 카드 폭 42%(96–150dp). SOLVED 도장은 사진 자리(빈 칸)에 그대로 찍힘, 이름 칸 침범 없음. `ArtAssets.caseClosedEmblems`(ep01만), 다른 사건은 기존 사진. 테스트 `case01_case_closed_test`
- 2026-10-19 — **Case 01 Final Royal Box 새 그림**(사용자 제공 `royal_box_closed.png`·`royal_box_open.png`, 1659×948 RGBA 투명 배경, 같은 캔버스·같은 위치). 닫힌 그림에 그려진 다이얼 0000은 실제 휠과 맞지 않으므로(사용자 결정) `tool/royal_box_blank/blank_test.dart`로 원본은 보존하고 드럼 4개의 숫자 영역(521–552·709–740·909–940·1104–1135 × 644–688)만 같은 줄의 드럼 색으로 보간해 지운 `royal_box_closed_blank.png`를 사용. 상자 드럼 창에 아래 휠의 현재 값을 그 자리에 굴러 들어오게 표시(`_DrumDigit`, 스크린리더 제외 — 휠이 읽힘), 조작은 기존 휠 그대로. `RoyalBoxArt`에 `dials/shut/opened` 추가, 열릴 때 보는 영역이 상자 전체 → 뚜껑부터 받침까지로 약간 다가가 왕관이 크게(360dp에서 무대 폭 가득). 열린 그림(7924)은 OPEN THE BOX 정답 판정 후에만, 닫힌 그림이 먼저 빠지는 크로스페이드. 사진 모드의 코드 빛줄기 제거(과한 효과), 그림 없을 때만 코드로 그린 상자. 무대 높이는 그림 비율 기준(150–320). 두 그림 미리 캐시. `sceneAspects[royalBox]` 885/868 → 1659/948(사건 사진도 새 열린 그림). 기존 `royal_box.png`(극장)는 미사용 그대로
- 2026-10-19 — **Case 01 Discovery 증거 카드 그림**(사용자 요청·결정): 실제 증거 e01 Old Letter(편지)·e02 Golden Key(열쇠)·e03 Pocket Watch·e04 London Map(지도)·e05 Crown Symbol 중 Discovery에 증거 카드가 나오는 것은 M3(e03)·M5(e05)뿐. e05만 `assets/art/objects/crown.png`로(`ArtAssets.evidencePictures` — Discovery·노트북 타일·확대 공통), 원 안에서 1.5배(`evidencePictureZoom`, 양피지 여백만 잘림, 왕관 전체 보임). e03은 Royal Box 회중시계 삽화가 10:10이라 "7시" 증거와 맞지 않아 기존 잉크 표시 유지(사용자 결정). e01·e02는 기존 실물 그림, e04는 지도라 그대로. 해독 장면에서 증거 그림 미리 캐시. 다른 사건·`GameSymbol` 불변
- 2026-10-19 — **01-M5 해독: 양피지 패치 폐기 → QR이 카드에서 사라지고 삽화가 그 자리에** + **Case 01 노트북 단서 카드 삽화**(사용자 요청). `tool/card_code_clear/clear_test.dart`: 카드 원본은 그대로 두고, QR 영역(648,414)–(980,714)만 잘라 잉크(주변 종이 밝기 80백분위보다 확실히 어두운 픽셀, 측정한 QR 범위 안만, +3px)를 지우고 종이 복원 = 가우시안 가중 평균 색(잉크 제외, 얼룩 포함) + 근처 깨끗한 종이의 결(6×6 블록 단위 오프셋, 영역 안·선/얼룩 없는 곳만, 실패 시 픽셀 단위). 아래 왼쪽 백합 장식과 오른쪽 위 얼룩은 보존 → `buckingham_palace_crown_card_code_clear.png`(332×300). 해독 시 이 조각이 원본 위에 그대로 겹쳐지며 페이드(QR이 종이 속으로 사라짐), 그 자리에 삽화 4개(그림자·테두리·패널 없음)와 이름, 연필 곡선 점선(`_PencilTrail`: 3차 베지어 위를 약간 흔들리는 크기 고르지 않은 점, 열린 화살촉, 해당 그림 등장 전에 선이 그려짐 — 첫 줄은 위로 휘는 호, TRAIN→SWAN은 가운데로 휘어 내려가는 곡선, 둘째 줄은 아래로 처지는 호). 복원 조각·삽화 미리 캐시. `DecodeScene.patch/patchTilt` → `cleared/clearedArea/messageTilt`. 노트북: `RoyalBoxPicture.forClue` — 단서의 상징이 **그 사건 Final의 자물쇠 그림**일 때만(데이터 기준, Case 01뿐) 삽화(c01 train→TRAIN, c02 museum→STONE, c03 clock→CLOCK, c04 park→SWAN; c05 crown·다른 사건은 기존 도장), 48dp 창으로 카드 왼쪽 칸 소폭 확대. 테스트: 복원 조각 픽셀 검사(QR 잉크 0.2% 미만, 잉크 외 원본 동일, 백합·얼룩 불변), 해독 전 QR 존재·후 복원 조각 불투명·패널 없음, 단서 매핑, Final 힌트·편지·스크린리더에 정답 숫자 없음
- 2026-10-19 — **Case 01 Royal Box 자물쇠 삽화 교체 + 01-M5 해독 화면 재작업**(사용자 요청): 사용자 제공 컬러 삽화 4장(회중시계·증기기관차·백조·로제타 스톤, 1254² RGB, 체크무늬가 픽셀로 포함)을 `assets/images/case01/symbols/original/`에 원본 그대로 보존(번들 제외)하고, `tool/symbol_cutout/cutout_test.dart`(탐정 투명화 알고리즘 재사용: 테두리에서 닿는 무채색 체크 + 체크 무늬 갇힌 구멍 제거, 가장자리 매팅) → 여백 정리·동일 여백 512² RGBA로 `symbols/symbol_*.png`. 공용 매핑 `RoyalBoxPicture`(`widgets/royal_box_picture.dart`, 파일은 `ArtAssets.royalBoxLocks`): clock→CLOCK, train→TRAIN, park→**SWAN**, museum→**STONE** (내부 id·단서 숫자 7·9·2·4·정답 7924 불변). 적용: ① 01-M5 해독 — 흰 패널·잉크 아이콘 폐기, 스캔 뒤 QR 위로 낡은 양피지 패치(테마 parchment/parchmentDark, 불규칙 가장자리·어두운 테두리·은은한 그림자·결)가 내려와 QR을 완전히 가리고, 화면이 카드 오른쪽으로 한 번 더 다가감(`revealed`), 삽화 4개가 순서대로 번지듯 등장 + 이름 + 점선 화살표(2×2, 읽는 순서 Z), 공개가 끝나야 TAKE THE CARD 활성(1.4s, 모션 줄이기 = 즉시), 삽화 미리 캐시. 360dp에서 삽화 약 65dp. ② Final 자물쇠 — 기존 놋쇠 판에 양피지 창(58dp) 속 삽화 + 이름, 숫자 휠 그대로, 스크린리더 "Lock 3, Swan: n". ③ e05 Crown Symbol 확대의 순서 표시(`SymbolSequence`, e05만 사용) — 같은 삽화·이름·화살표, 번호 없음. 다른 사건의 상징 글리프(`GameSymbol`) 불변. 새 테스트 `case01_lock_pictures_test`(투명·여백·잔여 체크·매핑·원본 보존·Final 4크기·7924 입력·스크린리더), `case01_decode_test` 갱신, `visual_placeholders_test` 자물쇠 검사를 삽화 기준으로
- 2026-10-19 — **Case 01-M5 해독 결과 표현 개선**(사용자 요청): 카드 위 흰 패널 제거 → 스캔 뒤 QR 문양 자리에만 카드 자체의 종이색을 lighten 블렌드·흐린 가장자리로 칠해 잉크가 종이결 속으로 사라지고(1.0s 중 앞 30%), 같은 자리에 카드의 갈색 잉크로 네 그림을 2×2(읽는 순서: 위 왼→오, 아래 왼→오)로 번지듯 새김(투명도 + 흐림 2.5→0, 크기·회전 변화 없음) + 그림 사이 점선 화살표. 숫자·테두리·패널 없음, 왕관·카드 테두리 미가림(테스트), 문양 기울기 2°. 종이·잉크 색은 그림에서 잰 값으로 `season1_decodes`에 둠(`DecodeScene.paper/ink/codeTilt`, `face/faceTilt` 삭제). 편지 "Four pictures. Four locks. / Remember the order."(이름 없음 → `personalized_lines`에서 m05 제외), 패널 문구 전환은 겹치지 않게 순차 페이드. ep01 해시 3곳 갱신
- 2026-10-19 — **Case 01-M5 재설계: QR 스캔 → 화면 안 왕관 카드 조사**(사용자 요청: 폰 한 대로 아이 혼자 진행). 새 그림 `assets/images/case01/buckingham_palace_crown_card.png`(1536×1024, 사용자 제공: 정문 돌기둥에 기댄 카드, 왼쪽 왕관, 오른쪽 QR 모양 문양 — 장식일 뿐 인식하지 않음). 장소 화면은 기존 그대로(궁전 장면) → INVESTIGATE → 봉투 없이 바로 그림(`SceneDecode`): "You found a mysterious card near the palace gate." + 문양에 돋보기 표시 → 카드 탭(카드 전체 영역, 좌표는 그림 위에 겹쳐 그려 확인) → 카드 확대(0.45s)·문양 금색 테두리 → EXAMINE THE CODE → 문양 위 금색 스캔 줄 1회(1.0s, 모션 줄이기 = 즉시) → 카드 면(2° 기울임)에 양피지 막이 비치며 네 그림이 왼→오 순서로 나타남(CLOCK → TRAIN → PARK → MUSEUM, **숫자 없음**, 순서는 e05 `symbols`에서 읽음) + 패널에 숨은 메시지(편지) → TAKE THE CARD = 정답 제출 1회 → 기존 Discovery(CROWN SYMBOL). **데이터 변경(요청)**: `MissionType.qrScan` 삭제 → `examine`(입력·선택 없음, 오답 없음), m05 type·letterIntro·letter(숨은 메시지 "Detective {detectiveName}, four pictures. Four locks. / Remember the order. You will need it later.")·question·answer(`crown-card`, 화면이 보냄)·힌트 2개(가이드에게 묻기 삭제), Discovery detail, 학습 목표 문구, glossary 4개(examine·decoded·order·remember). story·c05·e05·transition·Final(7924·입력·판정)·해금·XP/코인 불변, 옛 세이브(QR로 푼 m05)는 완료 id로 그대로. **QR 기능 제거**(다른 사건 사용처 없음 확인): `qr_scanner_screen`·`qr_question`·`/scan` 라우트·Game Master QR 카드·`mobile_scanner`·`qr_flutter`·Android CAMERA 권한·iOS 카메라 사용 문구(생성된 macOS 플러그인 등록 파일 갱신). `InkGlyph.qr`는 디자인 시스템 글리프라 유지(현재 미사용). 새 효과음·BGM 없음(카드·스캔·공개는 시각 + 기존 햅틱만; 정답 후 Discovery의 기존 공통 소리는 그대로). 신규 `case01_decode_test`, 기존 테스트 갱신(정답·편지·ep01 해시 3곳·QR 화면/라우트 테스트를 "카메라 없음" 검증으로). 실기기 미검증
- 2026-10-19 — **Case 01-M3 재설계: Big Ben 아래 현장 조사·단서 연결**(사용자 요청. 같은 날 미커밋으로 만든 숫자 단어 암호 버전과 그림 순서 자물쇠 버전은 실기기 피드백으로 폐기 — 그 코드(`cipher_*`, `picture_lock`, `PictureLockQuestion`, `InkGlyph.bell`, `wordSpan` 훅, m03 그림 누름 소리)는 모두 제거). 새 그림 `assets/images/case01/big_ben_base_night.png`(1536×1024, 사용자 제공: 가로등·벤치·발자국·빛이 닿은 돌·긁힌 자국·배수구 덮개·난간). INVESTIGATE → 봉투 없이 바로 현장(`SceneDeduction`, 01-1과 같은 확대·이동·돋보기 표시·연필 쪽지): 단서 3개(발자국 / 가로등과 벽의 빛 / 돌의 긁힌 자국)를 탭하면 패널 노트에 한 줄씩(CLUES n / 3) → 셋 다 찾으면 그림에 ? 표시 3곳(벤치 밑·벽의 돌·배수구 덮개) → 하나 탭(금색 테두리, "Your choice: …") → SEARCH HERE = 정답 제출 1회. 오답 장소는 기존 오답 시트·기록, 빈 곳·다른 물건 탭은 한 줄만(기록 없음). **데이터 변경(승인)**: m03 `type: multipleChoice`, 옵션 a 벤치 밑 / **b 벽의 돌 뒤(정답)** / c 배수구 덮개(오답마다 "footprints" 피드백), 이야기 2줄째, letterIntro, letter = 단서 노트 3줄(단서 줄과 글자 그대로 같음 — 테스트), question "Where is the box hidden?", 힌트 2개, c03 note "The thief's watch stopped at 7 o'clock."(id·title·value 7·symbol 불변), Post-Case 줄 "The watch in the box at Big Ben / had stopped at 7 o'clock."(이전 SEVEN 쪽지 인용 대체), Discovery detail "The loose stone slides out … Its hands are frozen at 7 o'clock."(최종 7924의 7이 Pocket Watch에서 나옴), glossary 4개(footprints·scratches·lamp·drain). e03·POCKET WATCH·padlock(기존)·M4 해금·XP/코인 불변, 옛 세이브(417로 푼 m03)는 완료 id로 계산되어 그대로. 새 효과음 없음(단서·선택은 시각 + 기존 햅틱만). 학습 설계 m03 essential → helpful/exposure(단서가 그림에도 그려져 있음, 분포 41/6/3). 공용 추가: `models/scene_deduction.dart`, `season1_deductions.dart`(좌표는 실제 그림 위에 겹쳐 그려 확인), 패널 글자는 최대 1.15배(그림 자리 유지). 키패드 전용 테스트는 `ep08_m3`로 이전. 신규 `case01_deduction_test`(20), 기존 테스트 갱신(정답·이야기·ep01 해시 3곳·분포 2곳·Case 01 유형 집합). 실기기 미검증
- 2026-10-18 — **앱 아이콘 V1 + flavor 통합**: 런처 아이콘을 `assets/branding/app_icon_launcher_v1.png`(원본 `app_icon.png`의 프레임 안쪽 크롭)로 iOS·Android(adaptive) 적용, 설정은 pubspec `flutter_launcher_icons`(재생성 시 주의사항은 pubspec 주석). dev/prod flavor 제거 → 단일 앱 `com.londonmystery.app` "London Mystery", `flutter run`/`flutter build` 기본 그대로. Android debug·profile은 debug 키, release는 upload 키(`android/key.properties`) 필수(없으면 빌드 실패, debug 키 대체 없음). iOS는 Debug/Release/Profile + Runner scheme만. 기존 DEV 앱(`com.londonmystery.app.dev`)의 진행 기록은 이전되지 않음(삭제도 하지 않음). 게임·저장 구조 불변
- 2026-10-17 — **탐정 이미지 투명화 + Portrait/Illustration**: 10장 체커보드 제거 → RGBA(원본 `detectives/original/` 보존, 도구 `tool/detective_cutout/`), `DetectiveStyle` 추가, Discovery·Case Closed는 상반신 일러스트, 메달리온 크롭은 손·소품 포함으로 확대. 게임 데이터·저장 불변. 신규 테스트: 알파/투명/가장자리 잔상, 원본 보존, 스타일·비율, 1.3배 텍스트, 이미지 로드 실패(모자 아이콘)
- 2026-10-17 — **플레이어 탐정 표정 시스템**: `assets/art/detectives/` 10장 등록, `ArtAssets.detective/detectiveCrop`, `detective_character.dart`(DetectiveCharacter·PlayerDetective·WithPlayerDetective·DetectiveMoment·DetectiveCast). 배치는 *Visual System > Artwork* 참고. 등록 화면에 CHOOSE YOUR DETECTIVE 라벨(작은 화면은 장식선 자리, 아바타 카드 72→68). 저장 구조 변경 없음(기존 `profile.avatar` 사용, null = boy). 사건·정답·힌트·보상·저장 불변. **이미지 파일에 투명도 없음(체커보드가 그림에 포함)** → 메달리온 크롭으로만 사용, 투명 PNG 재요청 필요. Tests 1316 통과(신규 `player_detective_test` 19), analyze(lib/test) 0 issues
- 2026-10-16~17 — **오프라인 단일 탐정 전환**(사용자 승인 방향): Firebase Auth·Firestore·Functions 연동, 회원가입/로그인/이메일 인증/비밀번호 재설정/계정 설정·삭제·동의, 클라우드 동기화·복원·충돌 해결, 다중 프로필 코드·화면·테스트·의존성·Android/iOS Firebase 설정 삭제. 기기당 탐정 1명(`lm.detective.v1`, Boy/Girl + 이름), CREATE YOUR DETECTIVE → START INVESTIGATION, My detective(이름·아바타 변경, 진행 유지), 계정 빌드 데이터 이전(진행 있는 프로필 2개 이상이면 보류 화면). NEW ADVENTURE = 같은 탐정으로 진행만 초기화. 미션 완료 축하 문구 + CONTINUE INVESTIGATION, 재플레이 보상 없음 표시. 기존 실패 43개 정리: 코인 대화상자 버튼을 **GET MORE HINTS**로(사용자 확정, 테스트 헬퍼와 일치), Case 06 팁 테스트를 현재 흐름(Get a Free Hint → 패널·Notes에 DETECTIVE HINT)으로 갱신. 설계: `docs/OFFLINE_SINGLE_DETECTIVE.md`. Tests 1272 통과
- 2026-10-15 — **Wave 2.5.2: Case 06-M1 추리 피드백 다듬기**(UI만): 판정 3종 — 두 bag: THE STORIES MATCH! + "Both witnesses saw the same thing being carried." / 같은 옷(coat): **GOOD MATCH!**(초록 체크) "Both witnesses described the same clothing." + **BUT CHECK YOUR MISSION**(금색) "You're looking for something he carried, not wore." / 다른 것: **THE STORIES ARE DIFFERENT** "These witnesses described different things." "Try another pair." — 빨간 오류색 없음(테스트), 일치한 쌍은 두 카드 초록 테두리. 비교 화면: 첫 선택 전에는 큰 카드 자리 없음, 첫 선택부터 카드 1 + 빈 자리 2, 판정 블록은 두 카드 바로 아래(같은 블록, 두 번째 선택 시 맨 위로·판정 시 끝이 보이게만 300ms 스크롤), 하단은 CHOOSE ANOTHER PAIR / BACK TO WITNESSES만. 전환: 초상화 400ms 비행 → 착지 150ms 뒤 말풍선 220ms 페이드, 질문 패널은 착지 60ms 뒤(비행 중 패널·말풍선은 터치 무시, 사라지는 도입 패널도 터치 무시 — 비행 중 탭이 Get a tip으로 새던 버그 수정). 완료: 두 bag 해결 + grey hat 청취(순서 무관) → **DESCRIPTION RECORDED** "You learned something about the stranger's appearance." "Your witness notes are ready." + VIEW WITNESS NOTES / CONTINUE(자동 완료 제거, CONTINUE 연타도 정답 b 1회), 이 단계에선 질문·Notes 링크·팁 숨김. 노트 시트 제목 WITNESS NOTES. 모델: `checkLine`·`retryLine`·`notesLine` 추가. 대본·정답·보상·저장 불변. 테스트 43개 유지(내용 갱신·추가). Tests 1482 통과 / 4 실패(다른 세션의 ep06 M3·다른 사건 데이터 변경 때문, 이번 작업 무관) / 52 skip. 실기기 미검증
- 2026-10-15 — **Wave 2.5.1: Case 06-M1 상호작용 다듬기**(UI만): **TALK**: 세 태그가 하나의 컨트롤러(1초 왕복 = 약 2초 주기)로 함께 금테·글자 밝기·은은한 빛만 변함(크기·위치 불변, 높이 28), 증인 선택 시 도입 화면과 함께 정리, 모션 줄이기 = 가장 밝은 정적 상태. **초상화 비행**: 도입에서 인물을 고르면 그 인물 그림(`_PrintedPortrait`, 같은 종이 카드)이 도입 카드 위치에서 대화 초상화 위치로 400ms 커지며 이동(Rect 보간, 페이지 Stack 위 오버레이, 도착 위치는 배치 후 `talk-portrait`를 찾아 측정) — 그동안 원래 카드와 대화 초상화는 숨김(중복 없음), 도입 문구·다른 카드는 350ms 페이드, 하단 패널은 320ms 페이드+살짝 위로. 비행 중 다른 탭 무시, 뒤로가기 안전, 증인 간 전환은 비행 없음, 모션 줄이기 = 즉시. **즉시 판정**: YES/NO 제거. 두 번째 진술을 고르면 두 카드를 나란히 보여 주고(스크롤로 보이게) 450ms 뒤 판정 — 두 bag = THE STORIES MATCH!(1.8초 후 닫힘, 이후 Wave 2.5 흐름: grey hat 미청취면 ONE MORE THING), 같은 물건(coat) = "These statements match, but are they about what he carried?", 다른 물건 = "These witnesses described different things." — 두 카드는 남고 500ms 동안 탭 잠금, 이후 탭하면 그 진술로 새 쌍 시작 또는 CHOOSE ANOTHER PAIR. 반복 오답에도 정답 공개 없음, 기록 없음. 모델: `question`·`lookAgainLine` 제거, compareHow "Tap two statements to compare them." 대본·정답·보상·저장·Firestore 불변. 테스트 `case06_dialogue_test` 38 → 43(TALK 동일·은은함·고정 위치·종료, 비행 출발/도착/성장·중복 없음, 연속 탭 1회, 비행 중 뒤로가기, 모션 줄이기, YES/NO 없음, 판정 중 탭 무시, 반복 오답). Tests 1486 통과 / 52 skip. 실기기 미검증(다른 세션 AVD 사용·부하 높음)
- 2026-10-15 — **Wave 2.5: Case 06-M1 직관적 수사, 진짜 추리**(테스터 피드백: 화살표 의미 불명, 점선 단어가 힌트처럼 보임, 비교 규칙 불명, grey hat 놓침): **화살표 전부 제거**(GuidedActionIndicator·GuideMark는 Case 06에서 미사용, 파일은 남김) — 도입 인물마다 TALK, 얼굴 아래 TALK / SPOKEN TO(질문 하나라도 하면), 상태 줄 "n STATEMENT(S)" + 다음 행동 문장(Ask a question. / Ask another witness. / Compare two statements.). **질문 3개 동일**(순서 wearing·carry·when, 접기·금테 제거). 진술마다 STATEMENT RECORDED / IN YOUR NOTES(모든 진술 동일). **비교**: COMPARE TWO STATEMENTS(두 증인의 진술이 생기면, 주제 무관) → "Find two witnesses who saw him carry the same thing." / "Choose two statements. Then decide if they match." → 들은 진술 전부 목록(동일 스타일)에서 두 개 선택 → 나란히 + "Do these statements describe the same thing?" YES, THEY MATCH / NO, THEY DON'T(나란히). 판정은 데이터 `DialogueStatement.thing`(같은 물건이면 일치): 두 small bag + YES = 해결, 두 dark coat + YES = "They match — but is it something he carried?"(오답 아님, 다른 쌍), 다른 것 + NO = "Right. They are about different things." → CHOOSE ANOTHER PAIR, 틀린 YES/NO = "Look carefully. Are they talking about the same thing?"(기록 없음). **4단계**: 해결 후 `deduction.then`(juggler.wearing)을 아직 못 들었으면 완료하지 않고 목표 띠 "Find out what the stranger was wearing." + ONE MORE THING "Ask the witnesses about the stranger's clothes." — 들으면 DESCRIPTION COMPLETE 1.8초 후 정답 b 1회 제출. 이미 들었으면 반복 없이 바로 완료. **Notebook**: Witness Notes 증거 확대 화면에 해결된 대화 미션이면 WHAT THE WITNESSES TOLD YOU(완료가 보장하는 진술 3개: 두 bag + grey hat, 증인 얼굴·이름·원문, "Heard at the Market Hall · Mission 1") — M2 화면 오른쪽 위 Notebook에서 확인. 저장 필드 추가 없음(완료 여부에서 도출), 옛 완료 세이브도 표시. **단어**: 대화 화면 안의 점선 단어 제거(GlossaryText 대신 Text), 패널 Words → 화면의 어려운 단어 카드 목록(탭 = 기존 단어 카드, 부모 보고서 기록 유지). 공용 GlossaryText는 불변(다른 화면은 그대로). 모델: `DialogueDeduction` 재구성(solves, then·thenGoal·thenHow·doneLine, compareGoal 등), `DialogueScene.matches/described/recorded`, `DialogueProgress.solved`. 대본·Episode JSON·정답·보상·저장·Firestore 불변. 테스트 `case06_dialogue_test` 43 → 38(화살표 테스트 제거, 시작 순서 3가지·4단계·grey hat 먼저·오답/주제외 일치·Notebook(M2에서)·WORDS·360×640 1.3배 비교 카드 전체 보임 추가). Tests 1481 통과 / 52 skip. 실기기 미검증(5560·5562는 다른 세션 E2E 사용 중)
- 2026-10-15 — **Wave 2.4.1: 미조사 증인 안내 보정**(UI만): carry 진술 1명(또는 다른 진술 확인 후) 단계의 화살표 하나(남은 증인 사이/행 괄호선)를 **아직 carry를 묻지 않은 증인 얼굴마다 같은 작은 정적 잉크 화살표**(`GuideMark`, `guided_action_indicator.dart`, IgnorePointer, 0.25초 페이드)로 교체 — 조사한 증인은 초록 체크만, 가운데가 조사 완료여도 그 위에는 아무것도 없음. 증인 얼굴 행의 LayerLink 제거. 도입·질문·COMPARE·비교 시트 안내는 Wave 2.4 그대로. 테스트 41 → 43(시작 순서 3가지별 표시·크기 동일·이름/얼굴 비가림·터치 통과). Tests 1486 통과(같은 기간 다른 작업의 테스트 증가 포함). `dialogue_investigation.dart`에 `dart format -l 120`을 실수로 파일 전체 적용(줄바꿈만, 동작 불변). 기기: emulator-5560 정상 종료·재실행으로 복구(Cold Boot 불필요). 경로 A/B 실기기 검증은 같은 에뮬레이터를 다른 세션의 2기기 동기화 E2E가 쓰고 있어(앱 재설치·삭제, 프로필 ANNA·DEV 로그인) 중단. audioplayers 크래시 조사: logcat상 `MediaPlayerNative error (1, -19)`(NO_INIT) 직후 같은 MediaPlayer에 pause/getDuration/stop/prepareAsync가 state 0에서 호출되어 `prepareAsync` IllegalStateException(메인 스레드, 앱 종료). 경로: audioplayers_android 5.3.0 `WrappedPlayer.onCompletion → stop() → isLiveStream()(잘못된 상태의 duration 0) → stop()+prepare()`. 에뮬레이터가 `-no-audio`로 실행 중이라 출력 장치 초기화 실패가 유력한 계기(미확정). 사운드 코드 수정 없음
- 2026-10-14 — **Wave 2.4: Case 06-M1 다음 행동 화살표**(UI만): 공용 `widgets/guided_action_indicator.dart` — `GuideTarget`(LayerLink 앵커) + `GuidedActionIndicator`(손그림 잉크 화살표, CustomPainter, `IgnorePointer`, 대상의 실제 레이아웃을 따라감, 위 공간 없으면 아래로, 8dp × 3회 끄덕인 뒤 정지, 모션 줄이기 = 정지 표시, 새 단계(새 key)에서만 다시 움직임, `span` = 행 전체 괄호선 + 중앙 화살표). 단계(화면 상태에서만 계산, 저장 없음): 도입 = 인물 카드 3장 전체(괄호선 — 가운데 카드를 가리키지 않음) / carry 미질문 증인 = carry 질문(첫 두 얼굴 사이 틈에서) / carry 1명 = 아직 안 물은 증인들 사이(둘이 양 끝이면 행 전체 괄호선) / 2명 이상 = COMPARE STORIES(금테 등장 0.7초 후) / 비교 시트 YES·NO = 화살표 없음(판단은 플레이어 몫) / 3명 선택 = 증인 행 전체 괄호선 / 맞는 NO(2개) = **ASK ANOTHER WITNESS**(BACK TO WITNESSES 자리, 남색, 왼쪽 화살표; YES/NO는 같은 자리에서 비활성) / 맞는 NO(3개) = **CHOOSE ANOTHER PAIR**(NO 자리, 선택 초기화) + BACK TO WITNESSES 유지. 문구: DIFFERENT STORIES + "These stories are different. Ask another witness." / "…Try another pair." 패널: 상태 줄 아래 화살표 자리 30dp, 다른 진술 상태에서는 COMPARE(outline)를 패널 아래쪽으로. 도입 인물 줄 높이 = 카드 실제 높이(빈 띠 제거). **대본·Episode JSON·정답·보상·저장·Firestore 불변.** 테스트: `case06_dialogue_test` 34 → 41(3크기 화살표 위치·겹침·터치 통과·비암시 배치, 끄덕임/정지/같은 단계 반복 없음, 모션 줄이기, 1.3배). Tests 1445 통과. 에뮬레이터: 경로 A 1~5단계 확인 후 에뮬레이터 응답 정지. audioplayers 네이티브 크래시(`MediaPlayer.prepareAsync` IllegalStateException, 장면 전환 중 2회 — 이번 변경과 무관). 경로 B 실기기 확인은 남음
- 2026-10-14 — **Wave 2.3: Case 06-M1 Guided Investigation**(8~12세가 다음 행동을 알 수 있게, UI·흐름만): 도입 = YOUR MISSION "Find out what the stranger carried." + "Two witnesses may have seen the same thing." + 큰 인물 카드 3장(항상 표시, 높이 130~290) + 하단 "Choose a witness to begin." — 하단 원형 증인 버튼·Statements는 도입에서 숨김(대화부터). 질문: carry 단독 큰 버튼(56dp, 금테·돋보기) + **Other questions** 접기(wearing·when 나란히, 펼침 상태는 `DialogueProgress.othersOpen`으로 증인 전환 후에도 유지). 방금 물은 질문은 연한 파랑(남색 채움 → COMPARE와 경쟁하던 문제). 패널 상단 상태 한 줄: CLUE FOUND "One witness has spoken. Ask another witness." / TWO·THREE STORIES COLLECTED "Do the witnesses agree?" + **COMPARE STORIES**(구 COMPARE CLUES, 열림 조건 Wave 2.2 그대로) / DIFFERENT STORIES(같은 두 진술을 다르다고 맞힌 뒤, 새 진술 전까지 COMPARE는 outline). carry를 들은 증인 얼굴에 초록 체크. **비교 시트**: carry 진술 2개 = 자동으로 나란히, 3개 = "Choose two witnesses to compare."(증인 카드 3장, 두 명 선택·교체, 자동 선택 없음) → "Do their stories match?" YES, THEY MATCH / NO, THEY ARE DIFFERENT / BACK TO WITNESSES(질문·판정·버튼 하단 고정). 판정: 맞는 YES = THE STORIES MATCH! "They both saw the same thing." → 1.8초 후 기존 정답 `b` 1회 제출 → Discovery. 맞는 NO(2개) = "Good detective work! Ask another witness." + BACK 강조, (3개) = "…Compare two other witnesses." 틀린 YES/NO = "Look again. Are they carrying the same thing?"(기록·실패 없음, 같은 화면 재시도). 모델: `DialogueDeduction`의 `judge`/`rules`/`conclusion`/`prompt`/`askLine`/`askMoreLine`/`missingLine` → `matches()` + `choose`/`foundLine`/`matchLine`/`differentLine`/`otherPairLine`/`lookAgainLine`, `DialogueProgress.differentAt`. **NPC 대본·Episode JSON·정답·Clue·Evidence·Discovery·XP·코인·저장·Firestore 불변.** 테스트: `case06_dialogue_test` 30 → 34(경로 A~D·3크기·1.3배·긴 대사·모션 줄이기), `mission_play.solve`는 새 흐름. Tests 1438 통과. 에뮬레이터(Android, 411dp)에서 경로 B(꽃+제빵사 → NO → 복귀 → 저글러 → 3명 비교 오답 YES → 쌍 교체 → YES → DEDUCTION A SMALL BAG +30 XP +30 COINS → M2 해금)와 경로 A + 시스템 뒤로가기 확인. 남은 점: 360×640·글자 1.3배에서 3명 비교 시 이야기 카드 하단이 스크롤 경계에 걸림(문장은 보임)
- 2026-10-14 — **Wave 2.2: Case 06-M1 목표 중심 수사**(플레이 피드백 "어떻게 푸는지 모르겠다, COMPARE에서 돌아갈 곳을 모르겠다"): 도입 = YOUR MISSION "Find out what the stranger carried." + "Ask the witnesses. Look for two matching stories.", 대화 중 한 줄 목표 띠. 질문 순서 carry 먼저(돋보기·금테, 대답 불변). **COMPARE 조건: 진술 3개 → 서로 다른 두 증인의 carry 진술**(일치 여부 무관 — 정답 쌍 기준 아님). 그 전까지 다음 할 일 한 줄(0명/1명), 열리면 COMPARE CLUES + 금테 1회. 비교 시트는 carry 진술만, 하단 고정 LINK THESE TWO + **BACK TO WITNESSES**, 비교 가능한 쌍이 없을 때 오답 줄 끝에 "Try another witness.". 상단 "STATEMENTS n/6"·중복 진술 아이콘 제거, 카드의 YOU ASK 줄 제거(선택된 질문 버튼과 중복). 모델: `DialogueStatement.about`, `DialogueDeduction.topic/witnesses/prompt/askLine/askMoreLine/readyLine`, `DialogueScene.goal/how/comparable/canCompare`. 대본·정답·보상·저장 불변. 에뮬레이터에서 경로 A(질문 2개로 해결)·B(오답→복귀→정답) 확인
- 2026-10-14 — **Wave 2.1: Case 06-M1 대화 UI**(UI만): 초상화가 남은 높이를 채우도록(나란히: 너비 절반 이하·대사 열 최소 160dp, 1.3배 글자 215dp / 세로 공간 넉넉하면 위아래), 대사 카드에 인물 쪽 꼬리. 에뮬레이터 411dp에서 약 130×163 → 190×236dp, 412×915 테스트 약 280×350. 도입 문장 아래 빈 배경 대신 증인 3명 인쇄 카드 줄(탭 = 그 증인과 대화). 진술이 처음 3개가 되는 순간 COMPARE에 금테+잦아드는 빛 1회 + "You have enough statements to compare!"(모션 줄이기: 금테만), 비교를 한 번 열면 사라지고 반복 없음. 데이터·대본·판정·저장 불변
- 2026-10-14 — **Wave 2: Case 06-M1 증인 대화 수사**(사용자 승인 대본·이미지 4장): INVESTIGATE → 바로 대화(봉투·객관식 없음). 증인 3명(꽃 파는 사람·저글러·제빵사, 원작 인물) × 질문 3개(wearing / carry / when), 대답 6개가 진술(when은 진술 아님), 처음 들으면 NEW STATEMENT, 중복 없음. 진술 3개 이상 → COMPARE STATEMENTS: 두 진술을 골라 LINK → 정답 쌍(두 small bag) = MATCH → 기존 정답 `b` 1회 제출 → Discovery. 오답 쌍은 이유 한 줄(coat·hat·umbrella·서로 다름), 기록 없음. 대화 상태는 화면 로컬(재시작 시 처음부터). 공용: `models/dialogue.dart`, `season1_dialogues.dart`, `widgets/dialogue_investigation.dart`, `PlaceScenery.file`, `ArtAssets.characters`(증인 3)·`marketHall`. **Episode JSON·정답·Clue·Evidence·Discovery·학습 설계·저장·클라우드 불변**. 에뮬레이터(Android 14)에서 전체 흐름 확인, 비교 시트가 피드백 줄로 높이가 바뀌어 터치가 어긋나던 문제 수정
- 2026-10-14 — **Wave 1.2: Case 03-M1 화면 마감**(레이아웃만): 탐색은 장면의 `opening` 영역(문·벤치·빈 액자)이 화면 너비를 채우는 배율로 시작(세로 폰 약 1.17배, 세 장소 모두 화면 안 — 테스트), 핀치로 1배(방 전체)까지, 더블 탭은 여는 화면 ↔ 2.5배. 그림의 인쇄 종이 테두리는 `inside`로 잘라냄. 그림 위아래 빈 남색 → 같은 방의 흐리고 어두운 배경(`PlaceScenery`). 발견 카드: 최대 320dp, 좌우 24dp 이상, 기울임 없음, 카드 안에서 스크롤. 도착 화면: 상황 문장 17pt·간격 축소, 보고서 17pt(`LetterCard.textSize`, 기본 19 불변) → 360×640에서 보고서 전체가 한 화면, 제목 "GALLERY 8" 줄바꿈 방지(no-break space, ep03 해시 2곳). 에뮬레이터(Android 14, 411dp)에서 확인
- 2026-10-14 — **Wave 1.1: Case 03-M1 탐색 UX**(사용자 요청, 신규 이미지 없음): INVESTIGATE → 어두운 Gallery 8 위 도착 연출(상황 2줄 페이드 → 보고서가 아래에서 올라옴, 약 1.4s, 탭 = 즉시 완성, 시작 버튼 하단 고정, 다시 오면 즉시). 탐색 화면 재구성: 상단 GALLERY 8 + FOUND n / 3, 중앙 확대·이동(InteractiveViewer, 1~4배, 더블 탭 2.5배 ↔ 원래, 드래그·핀치는 조사 아님), 하단 목표 / **Tap the picture to investigate!** / Pinch 안내 + Report·Tip. 첫 진입 터치 안내(빈 바닥, 1.8s, 첫 터치에 사라짐, 페이지 안에서 반복 없음, 모션 줄이기 시 생략). 보고서는 시트(체크·단어 뜻·열린 Tip). 발견 카드(물건 그림·이름·문장, XP/코인 없음, 탭으로 닫기). 마지막 카드 후 `submitAnswer(c)` 1회; 카드가 열린 채 뒤로 가도 복귀 시 1회 완료. 보고서 첫 줄 "I noticed three things in the gallery." → ep03 해시 2곳 갱신. 저장·클라우드·정답·보상 불변
- 2026-10-14 — **Wave 1: Case 03-M1 현장 탐색**(사용자 요청, 이미지 4장 사용자 제공): Gallery 8을 직접 조사해 under the bench / on the frame / next to the door의 세 물건을 찾는다. 봉투·객관식 단계 대체(장소 → 보고서(봉투 없음) → 탐색). 마지막 발견이 기존 정답 `c`를 `submitAnswer`로 제출 → **미션 ID·정답·Clue·Evidence·XP·코인·저장·클라우드 규칙 불변**, 탐색 중간 상태는 저장하지 않음(재진입 시 처음부터). 공용: `models/investigation.dart`, `season1_investigations.dart`(미션 → 장면 매핑), `widgets/investigation_search.dart`. 데이터 변경: 03-M1 Tip 2(위치 표현), Discovery(EVIDENCE FOUND·fromPuzzle·Red Button 카드), 학습 설계(essential·application), Artwork.gallery → `british_museum_gallery_8.png`, Red Button 증거 그림 `objects/red_button.png`. 기대값 갱신: ep03 해시 2곳·분포 3곳·그림 경로 2곳·Discovery 목록 1곳
- 2026-10-12 — **Phase 4 P1-3·P1-4**(승인): 12-M2 after, 12-F whose, 11-M3 never sleeps. 정답 불변. 기대값 갱신은 `type_b_cases_test` 2단정(새 문구)·ep11/12 해시만. Tests 889 → 904
- 2026-10-12 — **Phase 4 P1-1·P1-2**(승인): Notebook 단어 뜻 보기(원래 사건 glossary), Operator Mode Archive 참고 공개, 부모 보고서 단어 뜻 대체 조회. 기존 테스트 7개 파일의 텍스트 찾기를 `findReadable`로(기대 문구 불변). Tests 878 → 889. P1-3·P1-4 제안만
- 2026-10-12 — **TYPE B Phase 3B (Case 09~11)**(승인): 피드백·Hint, 10-M3 Tower of London, 11-M3 이름 숨김, 화면 읽기 대체 텍스트(코드: `ChoiceOption.altText`, 그림 타일 라벨), 학습 설계 41/6/3. 보호 테스트 기대값 변경 없음; 해시·화면 읽기 라벨·예시 미션 갱신. Tests 865 → 878
- 2026-10-12 — **TYPE B Phase 3A (Case 06~08)**(승인): 오답 피드백·Hint, 06-M2 카드 문장, 학습 설계 40/7/3, 보호 규칙 피드백 확장. 기존 보호 테스트 기대값 변경 없음(ep07 해시·분포만 갱신). Tests 850 → 865
- 2026-10-12 — **TYPE B Phase 2 (Case 02~04)**(승인): 오답 피드백·Hint 정리, 04-M2 라벨, 04-M3 이름 숨김, 학습 설계 39/8/3. 03-F Hint는 보호 규칙에 맞게 제안에서 수정. 기존 테스트 4개 파일 갱신(해시·라벨·이름 예시·분포). Tests 838 → 850
- 2026-10-12 — **XP 규칙 3 + 탐정 행동 배지**(승인): 모든 해결 동일 XP, Sharp Eyes·Quick Thinker retired, Second Look·Notebook Explorer·Word Collector(`BehaviorLog`), Case Closed 요약은 행동 기반 문구(첫 시도 칭찬 제거), 부모 보고서 Detective Actions·첫 시도 주석·XP 안내. 규칙 2 전제 테스트 갱신. Tests 815 → 838
- 2026-10-12 — **TYPE B 대표 Case**(승인): Case 01·05·12 오답 피드백, 01-M1·M2·M4 개선, 05·12 Final 기호 제거, 학습 설계 37/10/3. 기존 테스트 6개 파일 갱신(라벨·해시·스크롤). Tests 799 → 815
- 2026-10-12 — **TYPE B P0**: Parent Report 정직화(별점·정답률 제거, 학습 설계/플레이 기록 분리, 기록 없음 처리), XP 규칙 2 + 미션별 규칙 기록, Sharp Eyes·Quick Thinker 첫 시도 조건, 학습 설계 데이터(`season1_learning.dart`). 의도된 동작 변경으로 기존 테스트 3개 파일 기대값 갱신. Tests 779 → 799
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
