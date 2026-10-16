# World Mystery 전환 전수조사 보고서

> **참고 (2026-10-16):** 이 감사 이후 계정·Firebase·클라우드 동기화 코드는 모두 제거되었다(`docs/OFFLINE_SINGLE_DETECTIVE.md`). 아래의 `lib/core/cloud`, `lib/data/sync`, `features/account|sync`, Firestore·Firebase 설정 항목은 더 이상 존재하지 않는다.

- 작성일: 2026-10-16
- 대상: London Mystery Flutter 프로젝트 (`/Users/myhwang/flutter-workspace/london_mystery`, 브랜치 `main`, HEAD `0c169cd`)
- 성격: 읽기 전용 조사 및 설계 제안 (조사 중 소스·설정·에셋 수정 없음)

**조사 방식:** 읽기만 했습니다. 파일 수정, 빌드, `flutter analyze`/`flutter test` 실행은 하지 않았습니다. 테스트 통과 수(1486 통과 / 52 skip)는 `PROJECT_CONTEXT.md`에 적힌 값이고, 이번에 직접 돌려 확인한 수치는 아닙니다.

**표기:** 【확인】은 코드에서 직접 본 사실, 【추정】은 추론, 【제안】은 설계안입니다.

---

## 먼저 알아야 할 사실 4가지

1. **실제 패키지명은 `kr.co.jness.london_mystery`가 아닙니다.** 【확인】 Android와 iOS 모두 `com.londonmystery.app`(prod)과 `com.londonmystery.app.dev`(dev) 두 flavor입니다 (`android/app/build.gradle.kts:24,34,64`, `ios/Runner.xcodeproj/project.pbxproj:1087,1110`).
2. **아직 스토어에 출시되지 않은 것으로 보입니다.** 【확인】 `PROJECT_CONTEXT.md:22`에 "플레이테스트 + 출시 polish 단계"로 적혀 있고, PROD 빌드는 계정 UI를 숨깁니다(`accountsShown`). 그래서 지금이 앱 식별자를 바꾸기에 가장 싼 시점입니다.
3. **커밋되지 않은 작업이 많습니다.** 【확인】 Phase 4 클라우드 동기화 관련 파일 등 변경·미추적 항목이 약 104개입니다(조사 시점). 어떤 전환 방식을 고르든 이 작업을 먼저 커밋해 정리해야 합니다.
4. **iOS Bundle ID에는 밑줄(`_`)을 쓸 수 없습니다.** 【확인된 플랫폼 규칙】 그래서 후보안 `kr.co.jness.world_mystery`는 iOS에서 그대로 쓸 수 없습니다. 예: `kr.co.jness.worldmystery`.

---

## A. 현재 프로젝트 진단

### A-1. 실제 아키텍처 【확인】

- **스택:** Flutter, Riverpod 3, go_router 18, shared_preferences, Firebase Auth(이메일/비밀번호), Firestore, audioplayers, mobile_scanner, qr_flutter. Dart 149개 파일, 약 40,400줄.
- **구조:** 기능별로 나뉘어 있습니다.

| 경로 | 역할 |
|---|---|
| `lib/core/` | 라우터(`router/app_router.dart`), 테마 토큰(`theme/app_colors·app_text·app_tokens`), 상수·저장 키(`constants/app_constants.dart`), 오디오(`utils/audio_service.dart`), 정답 판정(`utils/answer_checker.dart`), 클라우드 부트스트랩(`cloud/`) |
| `lib/data/models/` | `Episode`, `Mission`(+`Clue`/`Evidence`/`Artwork`), `GameProgress`, `SeasonProgress`, `Season`, `Wallet`, `Profile`, `InvestigationScene`, `DialogueScene`, `Discovery`, `Learning` |
| `lib/data/mock/season1/` | **런던 콘텐츠 전체**: `episode01~12_mock.dart`(JSON 형태의 Dart const Map), 그리고 미션 ID를 키로 쓰는 부가 테이블(`season1_investigations/dialogues/discoveries/sounds/learning`), `season1_mock.dart`(시즌 정보) |
| `lib/data/repositories/` | `episode_repository.dart`(Mock 카탈로그), `progress_repository.dart`(프로필별 저장), `legacy_migrator.dart`, `profile_store.dart` |
| `lib/data/sync/` | 아웃박스, 저널, 머지, Firestore 코덱·센더·리스토어, 충돌 저장소 |
| `lib/features/` | onboarding, season, mission, mission_map, notebook, result, account, sync, game(controller/scoring/wallet), game_master |
| `lib/widgets/` | 공용 UI(`game_button`, `evidence_card`, `letter_card`, `paper`, `art_assets`, `landmark_art`, `london_skyline` 등) |

### A-2. 지금의 사용자 흐름 【확인】

Start → Register(이름 입력) → Season(사건철) → Prologue(1회) → Episodes(Case Files) → Intro → Map → Mission(장소 → 편지 → 퍼즐) → Story → … → Final → Solved → Episodes

- Start 화면은 상태에 따라 Solved / Map / Season / Register로 바로 보냅니다(`start_screen.dart:103-111`).
- Router의 redirect 가드가 접근 제어를 맡습니다: 탐정 없으면 Register, intro 미시청이면 Episodes, 잠긴 미션이면 Map(`app_router.dart` redirect).

### A-3. 지금 그대로 재사용할 수 있는 것 【확인】

- **미션 실행 흐름:** `MissionScreen`(장소 → 편지 → 퍼즐)과 `FinalMissionScreen`. 12개 Case 모두 같은 화면을 씁니다.
- **퍼즐 위젯:** `questionFor()`(`question_widgets.dart:898`)가 7개 `MissionType`을 하나의 switch로 고릅니다.
- **정답·보상·저장:** `AnswerChecker`, `GameController.submitAnswer`(트랜잭션 저장), XP·코인·힌트(Tip Shop), `BehaviorLog` 배지.
- **기반 시스템:** 프로필, 계정, 동기화(outbox/journal/epoch 머지), 레거시 마이그레이터. 국가 개념과 상관없이 동작합니다.
- **디자인 시스템:** `AppColors`/`AppText`/`AppSpace` 토큰, 공용 위젯, 폰트 3종(Sentient, IM Fell English SC, Libre Baskerville).

### A-4. 런던에 강하게 묶인 부분 【확인】

| 종속성 | 위치 |
|---|---|
| 카탈로그·시즌이 하나뿐 | `episode_repository.dart:18` (`{'ep01':…, ...season1Json}`), `game_providers.dart:79` (`seasonInfoProvider = season1InfoJson`) |
| 기능 위젯이 season1 데이터를 직접 import | `mission_screen.dart:12-17`, `final_mission_screen.dart:13`, `story_scene_screen.dart:13`, `question_widgets.dart:12`, `evidence_card.dart:7`, `audio_scenes.dart:3`, `detective_report.dart:1` |
| `Artwork` enum(닫힌 목록) | `mission.dart:39-130`. 런던 장소만 들어 있고, `fromJson`이 모르는 값을 받으면 **throw**합니다. 새 국가 콘텐츠를 넣으려면 코드 수정이 필수입니다. |
| 지도 | `map_world.dart`의 `Landmark` enum(런던 9곳 좌표)과 `missionLandmarks`(미션 52개 하드코딩), `LondonMapPainter`, `ArtAssets.londonMap` |
| 미션 ID 하드코딩 | `place_art.dart:30-73`, `art_assets.dart:209-213`, `season1_sounds.dart` |
| 배지 | `scoring.dart:103-108`: `episodeId: 'ep02'…'ep12'`, `londonExplorer`, `londonLegend` |
| 오디오 | `AmbienceBase`(`audio_scene.dart:23`)에 런던 장소 앰비언스가 들어 있음 |
| 문구 | `case_solved_screen.dart:151` "London needs you again.", `:365` "London Mystery Detective Agency", `app.dart:97` title |
| 진행 상태가 하나 | `SeasonProgress`(activeEpisodeId/solvedEpisodeIds)가 프로필당 1개, `AppConstants.currentEpisodeId = 'ep01'` |
| 시즌 아트 | `art_assets.dart:58-70` `season1CoverLondonPanorama`, `season1LondonNight` (season_screen, prologue_art에서 사용) |

### A-5. 구조적 문제점

1. **부가 테이블이 기능 레이어에 직접 연결돼 있습니다.** 【확인】 Case 03·06의 특수 미션, 사운드, 디스커버리가 모두 "미션 ID → 데이터" 전역 Map이고, 위젯이 이를 직접 import합니다. 국가를 추가할 때마다 위젯 파일을 고쳐야 합니다.
2. **"국가/시즌" 계층이 없습니다.** 【확인】 Route `/mission/:id`는 `currentEpisodeProvider`를 기준으로 해석됩니다.
3. **미션 중간 상태를 저장하지 않습니다.** 【확인】 찾은 증거(`_found`), 대화 진행(`DialogueProgress`)은 화면 메모리에만 있습니다(`mission_screen.dart:58,69`).
4. **Evidence를 다음 미션의 입력으로 쓰는 구조가 없습니다.** 【확인】 Evidence는 수첩에서 보는 용도이고, 후속 미션에서는 플레이어가 읽고 답을 입력하는 방식뿐입니다.
5. **XP는 사건 단위로만 계산됩니다.** 【확인】 `XpBreakdown.totalFor(episode, progress)`가 지도·수첩·Case Files에서 쓰이며, 전체 XP·랭크·Passport 개념은 없습니다.

### A-6. Case / Episode / Mission 데이터 현황 【확인】

- Case 01(`ep01`): 일반 미션 5개 + final. ID 체계가 다름: `m01`~`m05`, `final`, `c01`, `e01`.
- Case 02~12(`ep02`~`ep12`): 일반 미션 3개 + final. ID 체계: `epNN_mK`, `epNN_final`, `epNN_cK`, `epNN_eK`.
- 총 52개 미션. MissionType 분포: multipleChoice 18, wordInput 9, imageChoice 7, numberCode 6, sequence 5, finalCode 4, qrScan 1.
- 완료 판정: `AnswerChecker.isCorrect` → `GameController._submitAnswer`가 시도 수·오답 수 기록, 코인 지급(`Wallet` `mission:<id>` 1회), XP 규칙 기록, 배지 판정, final이면 `SeasonProgress.markSolved`.
- 다음 미션: `GameProgress.currentMission()` = 순서상 첫 미완료 미션. 해금은 "이전 미션 모두 완료"(`isUnlocked`).
- 다음 사건 해금: `SeasonNotifier.unlockRule` = 카탈로그 인덱스상 이전 사건이 solved.
- 힌트: 미션당 최대 2개, Tip 1 무료 / Tip 2 20코인(못 내면 무료).
- 이어하기: 사건별 `GameProgress` 저장(`missionStartedAt`이 있으면 퍼즐 단계로 바로 진입). 미션 내부 인터랙션 상태는 미저장.

---

## B. World Mystery 전환 가능성

- **전체 난이도: 중간.** 【판단】 엔진은 이미 데이터 중심이라 재작성할 필요가 없습니다. 어려운 부분은 "하나뿐인 시즌"이라는 가정을 풀어내는 일과 클라우드 스키마입니다.
- **재사용 범위 추정: 코드 약 75~85%를 그대로 또는 경미한 수정으로 사용.** 【추정】 근거: core·sync·account·widgets·mission 실행 흐름은 국가와 무관하고, 런던 종속은 mock 폴더, 지도, enum, 몇몇 하드코딩 테이블에 모여 있습니다.
- **가장 큰 리팩터링 대상:**
  1. 콘텐츠 팩 경계: 카탈로그, 시즌 정보, 부가 테이블을 국가 단위로 묶기
  2. `Artwork` enum을 문자열 키로 바꾸기
  3. 국가별 진행률과 Firestore `season/state`·rules
  4. 지도 일반화
- **새 프로젝트 생성: 필요 없습니다** (H-2 참고).
- **주요 위험:** 저장 키·클라우드 스키마 변경, 미커밋 작업과의 충돌, 앱 용량.

---

## C. 공통 미션 엔진 분석

### C-1. 지금 엔진의 핵심 패턴 【확인】

Case 03 M1과 Case 06 M1은 **"표현 오버레이"** 방식입니다.

- 미션 데이터(`Episode` JSON)는 원래의 `multipleChoice` 퍼즐 그대로입니다.
- 별도 Map(`season1Investigations['ep03_m1']`, `season1Dialogues['ep06_m1']`)이 있으면 퍼즐 대신 인터랙티브 화면을 보여 줍니다.
- 인터랙션이 끝나면 **원래 퍼즐의 정답 문자열**(`'c'`, `'b'`)을 `_submit()`에 넘기고, 판정·저장·XP·코인·Clue·Evidence는 기존 경로를 그대로 탑니다.

이 방식은 확장에 좋은 기반입니다. "인터랙션은 정답 문자열을 만들어 낼 뿐이고, 판정과 보상은 하나의 경로"라는 계약이 이미 성립해 있습니다. 문제는 선택 방식이 `if (scene != null) … if (talk != null)` 분기(`mission_screen.dart:294-316`)라는 점, 그리고 데이터가 전역 Map이라는 점입니다.

### C-2. Case 03 M1 상세 (Gallery 8 현장 수색) 【확인】

- **데이터:** `season1_investigations.dart`의 `InvestigationScene`: 찾을 것 3개(`InvestigationFind`: 빨간 단추·파란 천·젖은 발자국), 오답 장소(`InvestigationSpot`), `opening`/`inside` Rect, `guideAt`.
- **좌표:** 모두 **이미지 대비 비율(0..1)**입니다(`_px(x,y,…)`로 1536×1024 픽셀을 비율로 변환). 그래서 화면 크기가 달라도 같은 지점이 맞습니다.
- **터치:** `GestureDetector.onTapUp`의 좌표를 비율로 바꿔 `InvestigationScene.hit()`에 넘깁니다(`investigation_search.dart:651`). 영역 바로 바깥 탭도 `slack` 허용치 안이면 가장 가까운 영역으로 인정해서, 손가락 크기를 보정합니다.
- **확대·이동:** `InteractiveViewer` + `TransformationController`(`investigation_search.dart:272, :508`).
- **피드백:** 찾은 물건 이미지를 장면 위에 겹쳐 그리고(위치·회전·squash), 오답 장소는 그곳의 설명 문장, 빈 곳은 `missLine`을 보여 줍니다. 힌트 2단계, 보고서 다시 보기(`recordRecheck`)가 있습니다.
- **흐름:** `InvestigationArrival`(도착 장면 + 보고서 전달) → `InvestigationSearch`.
- **완료:** 마지막 물건을 찾으면 `answer: 'c'`를 제출합니다.
- **저장:** 미션 완료만 저장됩니다. **찾은 목록은 저장되지 않습니다.** 앱을 다시 켜면 처음부터 다시 찾아야 합니다.
- **한계:** 장면 1개, Dart const(Rect/Offset)라 JSON화가 안 됨, 진행 상태 미저장.

### C-3. Case 06 M1 상세 (Market Hall 증인 대화) 【확인】

- **데이터:** `season1_dialogues.dart`의 `DialogueScene`: 증인 3명(꽃 파는 사람·저글러·제빵사) × 질문 3개의 **고정 행렬**(`answers[questionId]`), 진술(`DialogueStatement.thing`), 추론(`DialogueDeduction.pair`가 정답 쌍, `then`이 추가로 들어야 할 진술).
- **흐름:** 증인 선택 → 질문 → 진술 기록 → 증인 2명 이상의 진술이 모이면 COMPARE → 두 진술 선택 → `thing`이 같고 주제가 맞으면 정답. 그다음 `then` 진술(juggler.wearing)이 남아 있으면 "ONE MORE THING", 다 들으면 `'b'`를 제출합니다.
- **UI:** `dialogue_investigation.dart`(2,316줄). 초상화 비행 애니메이션, 모션 줄이기 대응, 1.3배 글자 대응.
- **편지 단계 없음:** 대화 미션은 장소 → 바로 퍼즐(대화)로 진입(`mission_screen.dart:104-110`).
- **저장:** `DialogueProgress`는 메모리에만 있습니다. 수첩은 완료 여부에서 진술을 다시 만들어 보여 줍니다(`recorded()`, `evidence_card.dart:357`).
- **한계:** 분기 대화 트리 없음, Evidence 보유에 따른 대사 해금 없음, NPC 상태 변화 없음, 중간 이어하기 없음.

### C-4. 미션 유형별 표

| 유형 | 현재 구현 | 재사용 가능 | 신규 개발 | 난이도 |
|---|---|---|---|---|
| A. Hidden Evidence | **있음** (ep03_m1) | `InvestigationScene.hit`, 비율 좌표, `InteractiveViewer`, 찾은 물건 오버레이, 오답 장소 피드백 | 데이터 JSON화, 발견 상태 저장, 장면 여러 개 | **낮음** |
| B. NPC Dialogue | **부분** (ep06_m1, 질문 행렬 + 진술 비교) | 초상화·대화·진술 UI, 비교 시트 | 노드 기반 분기, `requires`(Evidence/Flag) 조건, NPC 반응 상태, 이어하기 | **중간** |
| C. Drag & Drop | **없음** (`sequence`는 탭 순서 방식) | 피드백·보상 경로, 종이 효과음 | 드래그·스냅·목표 영역 판정, 상태 저장 | **중간~높음** |
| D. Spot the Difference | **없음** | A의 hit test와 zoom을 거의 그대로 | 두 이미지 동기 확대, 정답 영역 표시 | **낮음~중간** |
| E. Cipher / Code | **부분**: `numberCode`(숫자 휠), `wordInput`, `finalCode`(심볼 다이얼), `sequence` 다이얼 소리 | 휠·다이얼 UI, `AnswerChecker`(정규화·순서 피드백) | 회전식 암호판, 문양 조합 UI | **중간** |
| F. Map Investigation | **부분**: 지도는 이동 수단일 뿐 퍼즐이 아님. ep07 `imageChoice` 공원 지도 4장이 비슷한 역할 | `MapCamera`, 핀, 경로 페인터 | 지도 팩 일반화, 장소·경로 선택 퍼즐, 단서에 따른 장소 해금 | **중간~높음** |
| G. Evidence Deduction | **부분**: 진술 쌍 비교(B), 최종 자물쇠(Clue 값·심볼), sequence 재구성 | 비교 시트, `EvidenceCard`, 최종 다이얼 | NPC에게 증거 제시, 보유 Evidence를 입력으로 받는 판정 | **중간~높음** |

### C-5. 권장 엔진 구조 【제안】

거대한 단일 위젯은 피하고, **"인터랙션 데이터(sealed) + 유형별 독립 Player 위젯 + 공통 계약"** 구조를 권합니다.

```dart
// data: 미션에 선택적으로 붙는 인터랙션 (지금의 side-table을 Mission 옆으로 옮긴 형태)
sealed class MissionInteraction {
  const MissionInteraction();
  /// 이 미션을 시작/진행하는 데 필요한 이전 증거 (Evidence 재사용)
  List<String> get requiresEvidence => const [];
}
final class SearchInteraction extends MissionInteraction { /* = InvestigationScene */ }
final class DialogueInteraction extends MissionInteraction { /* = DialogueScene (+분기 노드) */ }
final class DragInteraction extends MissionInteraction { /* pieces, targets, snap */ }

// feature: 공통 계약 — 모든 Player는 '정답 문자열'만 내보낸다
class MissionPlayContext {
  final Mission mission;
  final Set<String> heldEvidence;          // 국가 내 수집 증거
  final Map<String, Object?>? savedState;  // 중간 저장 복원
  final void Function(Map<String, Object?>) onState; // 중간 저장
  final void Function(String answer) onAnswer;       // 기존 _submit → AnswerChecker
  final HintBinding hints;
}
typedef MissionPlayerBuilder = Widget Function(MissionPlayContext ctx);
```

- 판정과 보상은 지금처럼 `GameController.submitAnswer` 하나로 유지합니다. 그래서 XP, 코인, Firestore 규칙에 손대지 않아도 됩니다.
- 중간 상태는 `GameProgress`에 `interactionState: Map<missionId, json>` 필드 하나를 추가하면 됩니다. 이 모델은 관대한 디코딩을 쓰므로 기존 세이브와 호환됩니다.
- Evidence 재사용은 `requiresEvidence`와 `heldEvidence`를 쓰고, 화면에는 "이 증거를 보여 줘" 같은 행동으로 드러냅니다.

**8~12세 UX 고려사항:** 터치 영역 최소 48dp(현재 `slack` 방식 유지), 오답을 벌하지 않고 "왜 아닌지"를 알려 주는 문장(현재 원칙), 한 화면에 행동 하나, 드래그는 탭 대안 제공(접근성), 정답 공개 없이 단계적 힌트 2개, 모션 줄이기 대응 유지.

---

## 4장 질문에 대한 답

| 질문 | 답 | 근거 |
|---|---|---|
| 12개 Case가 같은 실행 구조를 쓰는가? | **예** | 모두 `MissionScreen`/`FinalMissionScreen`/`questionFor()`를 씀 |
| Case별 전용 화면·분기가 있는가? | **화면 클래스는 없음. 미션 ID·장면 분기는 있음** | ep03_m1(수색), ep06_m1(대화), `m.scene == Artwork.royalBox`(`final_mission_screen.dart:372`), 사운드·디스커버리·스토리 증거 Map(`season1StoryEvidence = {'ep06_m3','ep10_m3'}`) |
| 새 국가 Case를 기존 엔진으로 돌릴 수 있는가? | **지금은 불가. 경미한 수정 후 가능** | `Artwork` enum이 모르는 값에 throw, 카탈로그·시즌이 하나로 고정 |
| 국가 간 Case ID가 겹쳐도 안전한가? | **아니요** | 미션 ID가 전역 키로 쓰임: `Wallet` `mission:<id>`(`wallet.dart:88`), `CloudCatalog._coins`, Firestore `missionCoins()`/`episodeIds()`, `caseOfEvidence()`/`caseOfClue()`, 부가 테이블, 저장 키 `progress.v1.<episodeId>` |
| 기존 데이터를 유지한 채 Country ID를 붙일 수 있는가? | **예** 【제안】 | 기존 ID는 그대로 두고, 새 국가는 `jp_ep01`, `jp_ep01_m1`처럼 접두어로 전역 고유성을 보장. 복합 키는 불필요 |
| 국가별 Case 수가 달라도 되는가? | **대부분 됨** | 해금은 `unlockRule`(인덱스 기반), overview·archive는 catalog를 순회. 예외: Firestore `solvedEpisodeIds.size() <= 12`, 테스트 `hasLength(12)`(`season_archive_test.dart:42`) |
| 특정 Case 수·순서를 가정하는 코드가 있는가? | **일부** | `currentEpisodeId='ep01'`, `catalog.first`, `case_solved_screen.dart:105`(다음 사건 = 인덱스+1), ep01만 ID 체계가 다름(`m01`, `final`, `c01`, `e01`) |

**계층 제안:** World → Country → Adventure/Season → Case → Episode → Mission은 과합니다. 【제안】 코드의 실제 단위는 **Adventure(= 지금의 Season) → Case(= Episode) → Mission** 세 단계입니다. Country는 Adventure의 메타데이터(국가 코드, 지도, 대표 이미지, 출시 상태)로 충분합니다. 국가 하나에 시즌이 여러 개 생길 때도 `adventureId`(`uk_s1`, `uk_s2`)만 늘리면 됩니다. Episode와 Case는 같은 것이므로 하나로 유지합니다.

---

## D. 권장 아키텍처 【제안】

### D-1. 디렉터리

```
lib/
  core/ data/models/ data/sync/ features/ widgets/   ← 기존 유지
  content/
    content_pack.dart          ← AdventurePack 인터페이스 + 등록 목록(국가 추가 = 1줄)
    uk_s1/                     ← 기존 lib/data/mock/season1/ 을 감싸는 팩 (파일 이동은 선택)
    jp_s1/
  features/world/              ← World Map, Coming Soon
```

기존 `data/mock/season1/`은 **옮기지 않고**, `uk_s1` 팩이 import해서 감싸기만 해도 됩니다. git 이력과 diff 크기를 지킬 수 있습니다.

### D-2. 데이터 모델

```dart
enum ReleaseState { playable, comingSoon }

class AdventurePack {
  final String id;              // 'uk_s1'
  final String countryCode;     // 'GB'
  final String countryName;     // 'United Kingdom'
  final ReleaseState release;
  final String heroArt;         // 국가 대표 이미지
  final Offset worldMapAt;      // 세계지도 위 위치 (비율)
  final Season season;          // 기존 모델 그대로
  final List<Episode> cases;    // 기존 모델 그대로
  final MapPack map;            // 지도 이미지, 랜드마크(문자열 id), 미션→랜드마크
  final Map<String, MissionInteraction> interactions; // ← 기존 season1Investigations/Dialogues
  final Map<String, Discovery> discoveries;
  final SoundPack sounds;
  final Map<String, LearningObjective> learning;
}
```

- `Artwork` enum은 `ArtKey(String)`으로 바꿉니다. 기존 enum 이름을 문자열 키로 그대로 쓰면 런던 데이터는 바뀌지 않습니다. `ArtAssets`가 팩별 경로를 해석합니다.
- 배지: 공통 배지는 그대로 두고, 사건 배지는 팩에 정의합니다. **기존 ID(`londonLegend` 등)는 저장값이므로 이름을 바꾸면 안 됩니다** (`scoring.dart` GameBadge 주석: "Ids are saved by name: never rename or remove one").

### D-3. 진행률 모델 (기존 키 보존이 핵심)

현재 저장 구조 【확인】:

- 로컬(SharedPreferences): 프로필 namespace `lm.p.<profileId>.` 아래 `progress.v1`(ep01), `progress.v1.<episodeId>`(ep02~), `season.v1`, `wallet.v1`, `journal.v1`, `outbox.v1`, `conflicts.v1`, `meta.v1`, `cloud.v1`. 프로필 이전 레거시 키 `lm.progress.v1…`는 `LegacyMigrator`가 게스트 프로필로 복사(원본 보존).
- 클라우드(Firestore): `users/{uid}/profiles/{profileId}/` 아래 `sync/meta`, `cases/{caseId}`, `season/state`, `wallet/{epoch}_{key}`, `wallet/summary`. Rules(`firebase/firestore.rules`)가 `episodeIds()`, `caseMissions()`, `missionCoins()`를 하드코딩(카탈로그에서 생성, `test/cloud_profile_store_test.dart`가 일치 검사), `solvedEpisodeIds.size() <= 12`.
- 탐정 이름은 사건별 `GameProgress.detectiveName`에도 복사됨(`openEpisode`).

제안 구조:

| 데이터 | 범위 | 저장 키 (프로필 namespace `lm.p.<pid>.`) |
|---|---|---|
| 프로필·이름·계정 | 전역 | 기존 그대로 |
| 코인 Wallet | 전역 | `wallet.v1` 그대로. 미션 ID가 전역 고유하면 문제없음 |
| 사건별 진행 `GameProgress` | 사건 단위 | `progress.v1`(ep01), `progress.v1.<caseId>` 그대로. 새 국가는 ID 접두어로 자연스럽게 분리됨 |
| 시즌 진행 `SeasonProgress` | 국가(Adventure) 단위 | **UK는 `season.v1` 그대로**, 새 국가는 `season.v1.<adventureId>` |
| World 기록 (마지막 국가) | 전역 | 새 키 `world.v1` |
| 전체 XP·랭크·Passport | 전역 | **저장하지 않고 계산** (모든 팩 × `XpBreakdown.totalFor` 합). 마이그레이션 불필요 |

→ **기존 키를 하나도 바꾸지 않는 설계**라서 진행률이 초기화될 위험이 없습니다.

클라우드: `cases/{caseId}`는 ID가 전역 고유하면 그대로 동작합니다. `season/state`는 `season/{adventureId}`로 확장하되 UK는 `state`를 유지합니다. Rules의 목록은 모든 팩에서 생성하고 `<= 12` 제한을 일반화합니다. **Rules는 앱보다 먼저 배포**해야 합니다.

### D-4. 라우팅

- 추가: `/world`(세계지도), `/world/:adventureId`(국가 홈 = 지금의 Season 화면).
- 기존 `/mission/:id` 등은 그대로 둡니다. 미션 ID가 전역 고유하므로 "활성 팩"만 찾으면 됩니다. URL에 국가를 넣지 않아도 되니 redirect 가드 변경이 최소화됩니다.
- 흐름: Register → **World** → Country(Season) → 기존 흐름. Solved 다음은 지금처럼 Case Files로, 그 위의 back은 World로. Start 화면의 "이어하기"는 `world.v1`의 마지막 국가와 사건으로 바로 갑니다.

### D-5. 세계지도 구현 방식 비교

| 방식 | 평가 |
|---|---|
| **단일 일러스트 + 비율 터치 영역** | **추천.** 지금 `MapWorld`, `InvestigationScene`이 같은 방식이라 `MapCamera`, `hit()`, 핀 위젯을 재사용 가능. 의존성 추가 없음. 국가 추가 = 좌표 1개. 스토리북 스타일 유지. 국가 수가 적은 단계(2~10개)에 맞음 |
| SVG / Interactive Map | `flutter_svg`와 path hit test 필요. 실제 국경 모양 터치는 일본처럼 작은 나라에서 어린이가 누르기 어려움. 일러스트 톤 맞추기 비용이 큼 |
| 지도 라이브러리 (flutter_map 등) | 타일·온라인·일반 지도 느낌이라 게임 정체성과 오프라인 원칙에 맞지 않음. 비추천 |

국가 터치 영역은 **국경이 아니라 큰 랜드마크 배지나 우표** 형태로 두기를 권합니다. Detective Passport 콘셉트와도 맞습니다. 잠긴 국가는 자물쇠·봉인 표시와 "Coming Soon" 시트로 보여 주고, 결제·진행 조건 문구는 넣지 않습니다.

### D-6. 에셋

현황 【확인】:

- `assets/art`(106MB: scenes 47MB, objects 37MB, characters 15MB, special 4.7MB, symbols 2.4MB), `assets/images`(16MB), `assets/sounds`(디렉터리 250MB, 그중 pubspec에 파일 단위로 등록된 번들 대상 WAV 약 70MB), `assets/fonts`(1.2MB). 파일 208개.
- 이미지 경로는 `ArtAssets`(`lib/widgets/art_assets.dart`)에서 중앙 관리, 사운드는 `audio_service.dart`의 `GameSound`/앰비언스 맵에서 관리(`test/audio_assets_test.dart`가 pubspec과 일치 검사).
- 장면 폴더가 런던 랜드마크 단위(`scenes/big_ben`, `british_museum`, …).

제안:

- **기존 런던 에셋은 옮기지 않기를 권합니다.** 【제안】 `ArtAssets`가 이미 경로를 한곳에서 관리하고, pubspec도 디렉터리 단위 등록이라 이동 효과는 작고 위험(테스트 `art_assets_test`, `audio_assets_test`)만 큽니다.
- 신규 국가만 `assets/countries/jp/...`, `assets/sounds/countries/jp/...`에 두고, 공통 UI 사운드(탭, 타자기, 자물쇠, 종이)는 지금 위치에서 그대로 공유합니다.
- **용량 경고** 【확인】 번들되는 PNG가 약 122MB(원본 기준), 번들 WAV가 약 70MB입니다. 국가마다 이 정도가 붙으면 앱 크기가 금방 커집니다. 【제안】 WebP·압축 오디오(m4a/ogg) 변환을 국가 추가 전 "권장" 작업으로 둡니다. 장기적으로는 Play Asset Delivery / iOS On-Demand Resources를 "추후" 검토합니다.
- **디자인:** "Vintage British Detective Storybook"은 "탐정의 사건철(casebook)"이라는 공통 언어로 일반화할 수 있습니다. 종이·잉크·타이포 3종·버튼은 공통으로 두고, **국가별로는 액센트 1색 + 대표 일러스트 + 앰비언스**만 바꾸는 방식(`ThemeExtension`)이 일관성을 지킵니다. `AppColors`의 런던 전용 토큰(skyline 등)은 팩으로 옮깁니다.

### D-7. 콘텐츠 정의 방식

| 방식 | 평가 |
|---|---|
| Dart (지금) | 에피소드는 사실상 `Map<String,dynamic>`이라 타입 안정성은 테스트에 의존. 부가 테이블(Rect/Offset)은 타입이 있음. 핫 리로드와 테스트가 쉬움 |
| JSON | 콘텐츠 작가 친화적, 원격 배포 가능. 다만 Rect/Offset 표현 규약과 로딩 비동기화가 필요 |
| **혼합 (추천, 단계적)** | 지금은 **Dart 팩 그대로** 둠(가장 적은 변경). `Episode.fromJson`이 이미 있으니 국가가 3개 이상이 되면 에피소드 본문만 `assets/content/*.json`으로 옮기는 선택지를 남겨 둠 |

과도한 CMS나 원격 콘텐츠 서버는 지금 규모에 맞지 않습니다.

**국가 추가 절차(목표 상태):** 팩 폴더 생성 → 대표 이미지·좌표 등록 → Case/Mission 데이터 작성 → 인터랙션 데이터 연결 → Evidence/NPC/Puzzle 데이터 → 등록 목록에 1줄 추가 → 팩 공통 테스트 자동 실행 → `release`를 `playable`로 변경.

---

## E. 패키지명·브랜딩 변경 영향

### E-1. 변경 대상 【확인】

| 구분 | 대상 | 현재 값 |
|---|---|---|
| 표시 이름 (쉬움, 데이터 영향 없음) | `build.gradle.kts:65,71` `appLabel`, `pbxproj` `APP_DISPLAY_NAME` 8곳, `app.dart:97` title, `Info.plist` CFBundleName | "London Mystery" / "London Mystery DEV" / `london_mystery` |
| 앱 식별자 (영향 큼) | Android `namespace`·`applicationId`, `kotlin/com/londonmystery/app/MainActivity.kt` 패키지 경로, iOS `PRODUCT_BUNDLE_IDENTIFIER`(Runner, RunnerTests, dev/prod) | `com.londonmystery.app(.dev)` |
| Firebase | `android/app/src/{dev,prod}/google-services.json`, `ios/config/{dev,prod}/GoogleService-Info.plist`(빌드 스크립트가 BUNDLE_ID 일치를 검사해 다르면 **빌드 실패**, `pbxproj:274`), `firebase.json`, `firebase/generated/firebase_options_*.dart`, `lib/core/cloud/cloud_environment.dart` | 프로젝트 `london-mystery-dev`/`-prod` |
| Dart 패키지명 | `pubspec.yaml` `name`, `package:london_mystery/` import **943곳**(lib·test·integration_test) | `london_mystery` |
| 기타 | `LondonMysteryApp` 클래스(`app.dart:13`, `main.dart:130`), 문서, Firestore rules 주석, 저장 키 접두어 `lm.` | |

딥링크·커스텀 URL 스킴은 Manifest와 Info.plist에서 찾지 못했습니다(주 런처 intent-filter만 있음). CI/CD 설정 파일(`.github`, fastlane, codemagic)도 없습니다. Android 서명은 PROD flavor가 upload key, DEV가 debug key입니다.

### E-2. 영향

- **applicationId·Bundle ID를 바꾸면 OS는 완전히 다른 앱으로 봅니다.** 기존 설치본의 SharedPreferences(모든 진행률)에 새 앱이 접근할 수 없습니다. 다만 지금은 미출시라 실제 사용자 피해는 테스트 기기 데이터뿐입니다(【추정】 출시 기록은 찾지 못함).
- Firebase에 새 Android·iOS 앱을 등록하고 설정 파일을 다시 받아야 합니다. Firebase Auth 사용자 자체는 프로젝트 소속이라 유지됩니다.
- **Firebase projectId는 바꿀 수 없습니다.** 사용자에게 보이지 않으므로 `london-mystery-*` 그대로 써도 됩니다.
- **저장 키 접두어 `lm.`은 절대 바꾸지 마세요.** 바꾸면 진행률이 초기화되고, 사용자에게 보이지도 않습니다.
- Dart 패키지명 변경은 943곳을 기계적으로 고치는 일입니다. 런타임 영향은 없지만 diff가 크고 진행 중인 작업과 충돌합니다. **가치가 낮으니 뒤로 미루거나 하지 않기를 권합니다.**
- Android는 applicationId에 밑줄을 허용하지만 iOS Bundle ID는 허용하지 않습니다. 두 플랫폼 ID를 같게 맞추려면 밑줄 없는 형태를 쓰세요.

### E-3. 안전한 순서

1. 미커밋 작업 정리
2. 스토어 식별자 결정 (예: `kr.co.jness.worldmystery`, 첫 출시 전에 1회만)
3. Firebase 콘솔에 새 앱 등록 → 설정 파일 교체 → **dev flavor에서 먼저** 빌드·로그인·동기화 확인
4. prod 적용
5. 표시 이름 변경
6. (선택) Dart 패키지명 변경은 독립 커밋으로

---

## F. 단계별 전환 로드맵

모든 단계에서 **런던 플레이가 늘 정상 동작**해야 하며, 각 단계는 독립 커밋이라 `git revert`로 되돌릴 수 있습니다.

| 단계 | 목표 | 주요 변경 파일 | 선행 | 검증 |
|---|---|---|---|---|
| **0. 기준선** | 미커밋 Phase 4 정리, 테스트 기준선 확보 | (커밋만) | — | `flutter analyze`, `flutter test` 전체 통과 수 기록 |
| **1. 콘텐츠 팩 경계** | `AdventurePack` 도입, UK 팩이 기존 season1을 감쌈. provider가 팩에서 읽도록. **동작 변화 0** | `game_providers.dart`, `episode_repository.dart`, `content/` 신규 | 0 | 기존 테스트 무수정 통과 |
| **2. 부가 테이블 분리** | `investigationOf`/`dialogueOf`/`discoveryOf`/`solveSoundOf`/`learningOf`/`missionLandmarks`/`place_art`를 팩에서 조회. 위젯의 season1 직접 import 제거 | `mission_screen`, `final_mission_screen`, `story_scene_screen`, `question_widgets`, `evidence_card`, `audio_scenes`, `detective_report`, `map_world`, `place_art` | 1 | case03·case06·audio 테스트 통과 |
| **3. Artwork 문자열 키화** | enum을 문자열 키로, 모르는 키는 throw 대신 fallback | `mission.dart`, `art_assets.dart`, `landmark_art.dart`, `place_art.dart` | 1 | `art_assets_test`, `new_artwork_test`, JSON 왕복 |
| **4. 국가별 진행률 + 클라우드** | `SeasonProgress`를 국가별로(UK 키 유지), `world.v1`. Firestore `season/{adventureId}`(UK는 `state` 유지), rules 목록·`<=12` 일반화 | `progress_repository`, `season_progress`, `game_providers`, `cloud_codec`, `sync_*`, `merge.dart`, `firestore.rules` | 2 | 마이그레이션 테스트(옛 세이브 로드), 에뮬레이터 동기화, **rules를 앱보다 먼저 배포** |
| **5. World Map + 라우팅** | `/world`, Coming Soon, 이어하기 | `app_router.dart`, `features/world/`, `start_screen`, `register_screen`, `season_screen`(back) | 1 | `back_navigation_test`, `small_screen_test` 확장 |
| **6. 지도 팩 일반화** | `Landmark` enum을 팩 데이터로, `LondonMapPainter`를 공용 페인터로 | `mission_map/*` | 2 | `map_camera_test`, `map_menu_sheet_test` |
| **7. 두 번째 국가 1사건 수직 슬라이스** | 엔진을 증명(콘텐츠 최소) | `content/jp_s1/` | 3~6 | 팩 공통 테스트 자동 적용 |
| **8. 브랜딩·식별자** | E-3 순서대로 | 플랫폼 설정 | 0 (출시 전 아무 때나) | dev 빌드 로그인·동기화 |
| **9. 미션 엔진 확장** | `MissionInteraction` + Player 레지스트리, `interactionState` 저장, `requiresEvidence` → 유형 A/D부터 | `mission.dart`, `game_progress.dart`, `mission_screen.dart`, 신규 player 위젯 | 2 | 유형별 위젯 테스트, 재시작 후 복원 |

**롤백:** 각 단계를 독립 커밋(또는 PR)으로 두고, 4단계는 rules 배포와 앱 배포를 분리해 rules를 하위 호환(옛 `season/state` 계속 허용)으로 먼저 배포합니다.

### 테스트 현황과 국가 공통 테스트

현황 【확인】: `test/` 75개 파일(테스트 케이스 약 1,000개, grep 기준 추정), `integration_test/` 9개 파일(Firebase DEV/에뮬레이터 대상). 콘텐츠·진행·동기화·오디오·계정·레이아웃·뒤로가기·전체 플레이스루(`full_playthrough_test`, `season_playthrough_test`) 테스트가 있습니다. 12개·`ep12`를 가정하는 테스트가 일부 있습니다(`season_archive_test.dart`, `story_intro_scene_test.dart`, `audio_context_mapping_test.dart`).

**국가 공통 테스트 【제안】:** `episode_content_test`, `season_content_test`, `type_b_cases_test`는 이미 catalog를 순회합니다. 이를 `for (final pack in allPacks) group(pack.id, …)` 형태로 바꾸면 새 국가에도 같은 검증(ID 고유성, 전체 플레이스루, 에셋 존재, 힌트 2개, 정답 도달 가능성)이 자동으로 돕니다. **전 팩에 걸친 미션·Evidence ID 전역 고유성 테스트**는 필수로 추가하기를 권합니다.

**회귀 위험이 큰 영역:** 런던 12개 Case 진행·해금, 이어하기·재시작 복원, XP·코인·힌트, Play Time, Back Navigation, Guest/로그인 동기화(4단계에서 가장 큼).

---

## G. 우선순위·작업량

작업량은 개발자 1인 기준 추정입니다. 코드 줄 수와 참조 범위를 근거로 했고, ⚠는 불확실성이 높은 항목입니다.

| 작업 | 구분 | 난이도 | 작업량 | 선행 | 기존 기능 영향 |
|---|---|---|---|---|---|
| 0 기준선 정리 | 필수 | 낮음 | 0.5~1일 | — | 없음 |
| 1 콘텐츠 팩 경계 | 필수 | 중간 | 2~4일 | 0 | 낮음 (동작 불변) |
| 2 부가 테이블 분리 | 필수 | 중간 | 2~3일 | 1 | 중간 (9개 파일) |
| 3 Artwork 문자열 키 | 필수 | 낮음~중간 | 1~2일 | 1 | 낮음 |
| 4 국가별 진행률 + 클라우드 ⚠ | 필수 | **높음** | 4~8일 | 2 | **높음** (동기화·rules·머지) |
| 5 World Map + 라우팅 | 필수 | 중간 | 3~5일 (아트 제외) | 1 | 중간 (back 흐름) |
| 6 지도 팩 일반화 | 필수 | 중간 | 2~4일 | 2 | 중간 |
| 7 2번째 국가 슬라이스 ⚠ | 필수 | 중간 | 개발 3~5일 + 아트·사운드·스토리 별도 | 3~6 | 없음 |
| 8 식별자 변경 | 필수 (출시 전) | 중간 | 1~2일 + 콘솔·스토어 작업 | 0 | 중간 (빌드·Firebase) |
| 에셋 압축 (WebP/m4a) | 권장 | 낮음~중간 | 1~3일 | — | 낮음 (사운드 테스트) |
| 9a 엔진 레지스트리 + 중간 저장 | 권장 | 중간 | 3~5일 | 2 | 중간 |
| 유형 A·D (수색·틀린그림) | 권장 | 낮음~중간 | 각 2~4일 | 9a | 없음 |
| 유형 B 분기 대화 + Evidence 조건 | 권장 | 중간 | 4~7일 | 9a | 낮음 |
| 유형 E 회전 암호판 | 추후 | 중간 | 3~5일 | 9a | 없음 |
| 유형 C 드래그앤드롭 | 추후 | 중간~높음 | 4~7일 | 9a | 없음 |
| 유형 F·G 지도 추리·증거 제시 ⚠ | 추후 | 높음 | 각 5~10일 | 6, 9a | 낮음 |
| Dart 패키지명 변경 | 추후·선택 | 낮음 (기계적) | 0.5~1일 | 0 | 넓은 diff |
| 에셋 온디맨드 배포 ⚠ | 추후 | 높음 | 미정 | — | 높음 |

**핵심 전환(0~8) 합계: 약 19~34일 (콘텐츠·아트 제작 제외)** 【추정】 가장 큰 불확실성은 4단계(클라우드 스키마)입니다.

### 프로젝트 전환 방식 비교

| 항목 | A. 기존 프로젝트 직접 수정 | B. 별도 작업 저장소 | C. 신규 프로젝트 이식 |
|---|---|---|---|
| 작업량 | 가장 적음 | 중간 (동기화 부담) | 가장 큼 |
| 코드 재사용률 | 최고 | 최고 | 낮아짐 (이식 손실) |
| Git 이력 | 보존 | 보존 (분기됨) | 단절 |
| 설정 변경 난이도 | 낮음 (점진적) | 중간 | 높음 (Firebase·flavor 재구성) |
| 데이터 호환성 | 유지 | 유지 | 재설계 위험 |
| 테스트 유지 | 그대로 | 그대로 | 대부분 재작성 |
| 롤백 | 커밋 단위 revert | 저장소 단위 | 어려움 |
| 장기 유지보수 | 좋음 | 런던 수정 이중 반영 부담 | 초기 비용 회수 어려움 |

---

## H. 최종 권고안

1. **World Mystery로 전환하는 것이 적절한가?**
   **예.** 엔진이 이미 데이터 중심이고, 판정·보상 경로가 하나이며, 프로필·지갑·동기화는 국가와 무관합니다. 런던 종속은 특정 파일에 모여 있어 경계를 긋기 쉽습니다.

2. **유지할 것인가, 복제할 것인가, 새로 만들 것인가?**
   **기존 저장소를 유지하고(A), 브랜치에서 점진적으로 전환하기를 권합니다.** 1,000개 넘는 테스트, 동기화 설계, 이력을 그대로 지킬 수 있습니다. C(신규 프로젝트)는 이득 없이 비용만 큽니다. B(복제 저장소)는 런던 수정을 두 곳에 반영해야 하는 부담이 생깁니다. 별도 작업 환경이 필요하면 git branch나 worktree로 충분합니다.

3. **패키지명을 지금 바꿔야 하는가?**
   **표시 이름과 스토어 식별자는 "첫 출시 전"에 한 번 바꾸는 것이 가장 쌉니다.** 단, 지금 당장은 아닙니다. 0단계 정리 뒤 독립 작업으로 하되, iOS에서는 밑줄 없는 ID를 써야 합니다. Dart 패키지명(943개 import), Firebase projectId, 저장 키 접두어 `lm.`은 **바꾸지 않기를 권합니다.**

4. **기존 12개 Case를 수정 없이 재사용할 수 있는가?**
   **콘텐츠(스토리, 정답, ID, 에셋)는 수정 없이 재사용할 수 있습니다.** 바뀌는 것은 그 데이터를 감싸는 팩, `Artwork` 키 해석, 부가 테이블의 위치뿐이고, 기존 ID와 저장 키를 유지하므로 진행률도 보존됩니다.

5. **신규 국가 개발량을 줄이려면 무엇을 먼저 바꿔야 하는가?**
   **콘텐츠 팩 경계(1단계)와 부가 테이블 분리(2단계)입니다.** 이 두 가지가 끝나면 국가 추가는 "팩 폴더 하나 + 등록 1줄 + 에셋"이 됩니다.

6. **다양한 미션 유형을 위해 엔진에서 가장 먼저 개선할 부분은?**
   **`mission_screen.dart`의 `if scene / if talk` 분기를 "인터랙션 데이터 + Player 레지스트리"로 바꾸고, 중간 상태 저장(`interactionState`)을 추가하는 것입니다.** "정답 문자열로 기존 판정에 합류한다"는 지금의 계약은 그대로 유지합니다.

7. **가장 위험한 세 가지는?**
   1. **진행률 저장 키와 Firestore 스키마 변경**: 키를 바꾸거나, rules를 앱보다 늦게 배포하거나, 머지 로직이 꼬이면 진행률이 초기화되거나 동기화가 거부됩니다.
   2. **미션·Evidence ID 충돌**: 지갑 `mission:<id>`, 클라우드 카탈로그, 수첩 검색이 모두 전역 ID 기반입니다. 접두어 규칙과 고유성 테스트가 없으면 조용히 깨집니다.
   3. **미커밋 대규모 작업 위에서 리팩터링을 시작하는 것, 그리고 앱 용량**: 약 104개 변경 위에서 구조를 바꾸면 롤백이 불가능해집니다. 에셋 약 190MB 구조는 국가가 늘수록 감당하기 어려워집니다.

8. **지금 당장 착수할 첫 번째 작업은?**
   **0단계: 현재 Phase 4 작업을 커밋해 정리하고, `flutter analyze`·`flutter test` 기준선을 기록하는 것입니다.** 그다음 1단계(동작 변화 없는 `AdventurePack` 도입)로 넘어갑니다.

---

## 조사 한계와 미결정 사항

**확인하지 못한 것:** 테스트와 analyze 실제 실행, 실기기 동작, Firebase 콘솔 상태(등록된 앱, SHA), 스토어 계정이나 출시 이력의 외부 확인, `dialogue_investigation.dart`(2,316줄)·`investigation_search.dart`(1,262줄)의 줄 단위 전체 검토(구조와 핵심 경로만 확인).

**결정이 필요한 것:** 학습 축이 "한국 어린이의 영어 학습"이라는 점(`glossary`가 한국어 뜻, Parent Report)이 일본·스페인 편에서도 영어 학습으로 유지되는지에 따라 콘텐츠 설계와 팩 구조가 달라집니다.
