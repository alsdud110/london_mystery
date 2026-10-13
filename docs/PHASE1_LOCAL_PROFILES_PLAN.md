# Phase 1 — 로컬 게스트 · 다중 프로필 · 레거시 이전 상세 구현 계획

> **상태:** 조건부 승인 후 구현 완료(커밋 전, 2026-10-13) · 기준 코드 `main`
> **확정:** Q-1 게스트 1명 · Q-2 레거시 원본 삭제는 Game Master 「다음 플레이어」 초기화만 · Q-3 검증 실패 시 원본 유지 + 안전 모드 + 다음 실행 재시도 · Q-4 Operator 데이터는 `origin: playtest` 기록, 동기화 영구 제외 · Q-5 UI는 Phase 3 · Q-6 `rev`는 실제 변경 시만 · Q-7 레거시 `runSeq` = 0 · 음수 잔액 정책은 Phase 2(Phase 1에서 보정·잔액 조작 없음)

## 0. 구현 중 계획과 달라진 점

| 계획 | 구현 | 이유 |
|---|---|---|
| `ProfileKind.operator` | 없음. Operator 데이터는 `ProfileOrigin.playtest`로 표시 | Q-4는 출처 기록. 종류를 늘리면 Phase 1 범위(샌드박스 분리)를 넘음 |
| `lm.device.v1`(installId) | 만들지 않음 | Phase 4 연결 기록에서만 필요 — 범위 밖 |
| 중단 시 네임스페이스 비우고 재복사 | **없는 키·읽을 수 없는 키만 복사**, 있는 키는 유지 | 어떤 경우에도 삭제하지 않음. 안전 모드에서 생긴 새 진행이 덮이지 않음 |
| 안전 모드 = 레거시 키로 실행 | 레거시를 **읽기만** 하고 새 저장은 프로필 키에 씀(오버레이). 안전 모드에서 새 모험 시작 시 `legacy.cleared` 표식으로 원본 읽기만 중단 | 원본을 쓰거나 지우는 경로를 GM 초기화 하나로 제한(필수 조건 7) |
| 새 모험 시작 = 새 게스트 ID | 같은 게스트 ID에서 네임스페이스만 비움 | 실행 중 세션 폐기 위험 제거, 게스트는 동기화 대상 아님 |
| Operator 표시 시점 | 「CASE NN부터」 실행, 또는 **일반 규칙상 잠긴 Case에서 미션을 해결**할 때 (안정화 단계에서 변경: 처음 구현은 스위치 ON만으로 표시해, 아이 프로필이 열람만으로 영구 동기화 불가가 될 수 있었음). 전체 초기화 시 `fresh`로 해제 | 운영 데이터와 구별하되 정상 진행을 오표시하지 않음 |
> **범위:** 패키지 추가 없음, 서버 없음. 사용자 화면 변화 없음(업데이트 후에도 Title → 등록/CONTINUE 흐름 동일).
> **상위 설계:** `docs/ONLINE_ACCOUNT_DESIGN.md` §4~7

## 1. 목표

1. 저장을 **프로필 네임스페이스**로 옮긴다. 기기에는 게스트 프로필 1개가 자동으로 생긴다.
2. 레거시 세이브를 게스트 프로필로 **복사 → 검증 → 표식**하고 원본을 보존한다.
3. 프로필마다 별도 Riverpod 컨테이너와 라우터를 만들어, 전환 시 이전 프로필 상태가 남지 않게 한다.
4. `GameProgress`에 회차 필드(`runId`, `runSeq`, `rev`)를 추가한다(병합 로직은 Phase 2).
5. Wallet 소급 지급을 레거시 이전 프로필 1회로 제한한다.
6. 기존 12 Cases / 50 Missions, XP V1~V4 기록, Coin, GET A TIP 동작은 바꾸지 않는다.

**비범위:** 언어/지역·진입 선택 화면, 프로필 선택 UI, 부모 인증, outbox, 병합, 클라우드.

## 2. 변경 파일

### 2.1 신규

| 파일 | 내용 |
|---|---|
| `lib/data/models/profile.dart` | `ProfileKind { guest, account, operator }`, `ProfileOrigin { legacy, fresh, playtest }`, `WalletBackfill { pending, done, never }`, `DetectiveProfile`, `ProfileRegistry`(활성 ID + 목록). 관대한 JSON 디코딩(기존 모델과 같은 방식) |
| `lib/data/repositories/profile_store.dart` | `ProfileStore(prefs)`: `lm.device.v1`/`lm.profiles.v1` 읽기·쓰기, `createGuest()`, `setActive()`, `rename()`, `markBackfill()`, `clearNamespace(pid)`, `ensureActiveSync()`(테스트·폴백용 동기 부트스트랩), `bootstrap()`(검증 포함 비동기, `main` 전용) |
| `lib/data/repositories/legacy_migrator.dart` | `LegacyMigrator`: 레거시 키 목록화 → 복사(`await setString`) → `prefs.reload()` → 문자열 비교 → 표식. 중단 복구(`state=copying`) 처리 |
| `lib/features/profile/profile_session.dart` | `ProfileSessionHost`(StatefulWidget): 활성 프로필마다 `ProviderContainer` 생성, `UncontrolledProviderScope(key: ValueKey(pid))`, `switchTo(pid)` 시 이전 컨테이너 dispose. `activeProfileIdProvider`, `profileStoreProvider`, `activeProfileProvider` 정의 |

### 2.2 수정

| 파일 | 변경 |
|---|---|
| `lib/main.dart` | `SharedPreferences` 로드 → `await ProfileStore(prefs).bootstrap()` → `runApp(ProfileSessionHost(...))`. 기존 override(prefs, episodes, catalog)는 세션 기본 override로 전달 |
| `lib/core/constants/app_constants.dart` | `deviceKey`, `profilesKey`, `legacyMigrationKey`, `profileKey(pid, base)`, `profileProgressKeyFor(pid, episodeId)` 추가. 기존 `progressKeyFor`·레거시 상수는 그대로(레거시 읽기용) |
| `lib/data/repositories/progress_repository.dart` | `SharedPrefsProgressRepository(prefs, {required String profileId})` — 모든 키를 네임스페이스로. `clear()`는 **해당 프로필 키만** 삭제(레거시 원본 보존). `ProgressRepository` 인터페이스는 변경 없음. `InMemoryProgressRepository` 변경 없음 |
| `lib/features/game/game_providers.dart` | `progressRepositoryProvider`가 `activeProfileIdProvider`를 사용. 그 외 provider 변경 없음 |
| `lib/data/models/game_progress.dart` | `runId`(String?), `runSeq`(int, 기본 0), `rev`(int, 기본 0) 추가. `toJson`은 값이 있을 때만 기록(`runId != null`, `runSeq > 0`, `rev > 0`) → 기존 형식 세이브·테스트와 호환. `resetCase()`는 지금처럼 순수 초기화(회차 필드는 컨트롤러가 설정) |
| `lib/features/game/game_controller.dart` | `_update`: 내용이 바뀐 저장에만 `rev+1`, `runId` 없으면 생성. `playAgain()`: 새 `runId`, `runSeq+1`. `registerDetective()`: 프로필 이름도 갱신. `resetAll()`: 활성 프로필 네임스페이스만 비우고 `walletBackfill=never` |
| `lib/features/game/wallet_controller.dart` | `build()`: Wallet이 없을 때 활성 프로필의 `walletBackfill == pending`이면 소급 후 `done`, 아니면 시작 Coin만. `startFresh()` 변경 없음 |
| `lib/features/game_master/playtest_tools.dart` | `startPlaytestAt` 실행 시 활성 프로필을 `origin: playtest`로 표시(D-5 (a)) 또는 operator 샌드박스 프로필로 전환(D-5 (b)) — 결정에 따름 |
| `lib/features/game_master/game_master_screen.dart` | D-4·D-5 결정에 따라 초기화 안내 문구만 조정(필요한 경우) |

### 2.3 변경 없음(세션 컨테이너 덕분에 그대로 동작)

`app.dart`, `core/router/app_router.dart`, `season_overview.dart`, `season_archive.dart`, `episode_select_screen.dart`, `season_screen.dart`, `start_screen.dart`, `register_screen.dart`, `tip_shop.dart`, 모든 콘텐츠(`data/mock/season1/*`)와 화면 위젯.

### 2.4 테스트

| 파일 | 변경 |
|---|---|
| `test/helpers.dart` | `testOverrides()`가 `ProfileStore.ensureActiveSync()`로 부트스트랩하고 `activeProfileIdProvider`를 override. `savedCase(prefs, episodeId)`, `savedWallet(prefs)` 헬퍼 추가 |
| 저장 직후 레거시 키를 읽는 테스트 (≈10개) | `full_playthrough_test`, `game_controller_test`(초기화 후 기대값: 프로필 키 없음 + **레거시 원본 유지**), `playtest_tools_test`, `season_archive_test`, `season_flow_test`, `season_playthrough_test`, `ui_tour_test` 등 → 헬퍼로 프로필 키를 읽도록 수정 |
| 레거시 키를 seed만 하는 테스트 (≈33개) | 변경 불필요 예상(부트스트랩이 이전) — 구현 시 전수 확인 |
| 신규 | `profile_store_test.dart`, `legacy_migration_test.dart`, `profile_session_test.dart`, `case_run_test.dart`, `wallet_backfill_gate_test.dart` |

## 3. 설계 상세

### 3.1 부트스트랩
1. `lm.profiles.v1`이 있고 활성 프로필이 유효하면 → 종료.
2. 없으면 레거시 키 존재 여부 확인:
   - 없음 → 게스트 생성(`origin: fresh`, `walletBackfill: never`). 현재 신규 사용자와 같다: 시작 20 Coins.
   - 있음 → `LegacyMigrator.run()`.
3. 프로필 목록이 깨졌으면 → 네임스페이스 키를 스캔해 복구, 실패 시 새 게스트 + 진단 로그(이름 마스킹).

`ensureActiveSync()`는 같은 절차를 검증(reload) 없이 수행한다. `main`은 항상 비동기 `bootstrap()`을 먼저 실행하므로, 실제 앱에서는 동기 경로가 아무 일도 하지 않는다. 동기 경로는 테스트와 방어용이다.

### 3.2 레거시 이전
- 대상 키: `lm.progress.v1`, `lm.progress.v1.ep02` ~ `lm.progress.v1.ep12`(실제 존재하는 키만), `lm.season.v1`, `lm.wallet.v1`.
- 순서: 표식 `{state: copying, profileId}` → 프로필 키로 복사 → `reload()` → 원본 문자열과 비교 → 프로필 목록 기록 → 표식 `done`.
- `copying` 상태로 다시 시작하면 그 `profileId` 네임스페이스를 비우고 처음부터 다시 복사한다.
- 검증 실패: 표식은 그대로 두고 다음 실행에 재시도한다. 이번 실행은 [OPEN] 결정(§6 Q-3)에 따른다.
- `walletBackfill` = 레거시 Wallet 있음 → `done`, 없음 → `pending`.
- 프로필 이름 = `lm.season.v1`의 활성 Case 세이브 이름 → 없으면 다른 Case의 첫 이름 → 없으면 null(등록 화면으로 감, 현재와 동일).

### 3.3 세션 격리
- `ProfileSessionHost`가 `ProviderContainer(overrides: [prefs, episodes, catalog, activeProfileIdProvider.overrideWithValue(pid)])`를 만든다.
- `switchTo(pid)`: 현재 세션의 플레이 시간 저장(`pausePlayClock`) → `setActive(pid)` → 이전 컨테이너 dispose → 새 키로 재빌드.
- 컨테이너와 함께 사라지는 것: 라우터·내비게이션 스택, `gameMasterAccess`, `parentReportAccess`, `operatorAccessSwitch`, `recentSolve`/`recentUnlock`, 오디오 서비스(새로 생성).
- Phase 1에서 `switchTo`를 호출하는 화면은 없다(테스트에서만 사용). 계정 프로필 UI는 Phase 4~5.

### 3.4 회차 필드
- 첫 저장 시 `runId` 생성(`Random.secure` 64bit hex). 레거시 세이브는 다음 저장 때 생성된다.
- `rev`는 직렬화 결과가 바뀐 저장에서만 증가한다. 백그라운드 전환 때 내용이 그대로인 저장이 일어나도 rev가 오르지 않는다.
- `playAgain()` → `runSeq+1`, 새 `runId`, `rev=0`.
- Phase 1에서 이 값을 읽는 로직은 없다(Phase 2 병합용).

### 3.5 Wallet 소급 제한
| 프로필 | Wallet 없을 때 |
|---|---|
| `walletBackfill: pending` (코인 도입 전 레거시) | 지금과 같은 소급(완료 미션 Coin + 열어본 TIP 소유) → `done` |
| `done` / `never` | 시작 20 Coins만 |
현재 동작과 다른 경우: Wallet 키만 사라진 이전 완료 프로필 → 지금은 다시 소급하지만, 변경 후에는 소급하지 않음(의도된 변경).

## 4. 테스트 시나리오

### 4.1 신규 단위/위젯 테스트
| # | 시나리오 | 기대 |
|---|---|---|
| T1 | 빈 기기 첫 실행 | 게스트 1개, `fresh`/`never`, 시작 20 Coins, 등록 화면 |
| T2 | 레거시(Case 01~03 + season + wallet) | 프로필 키 내용 = 레거시 문자열, 레거시 키 그대로, 표식 `done`, Title "Welcome back, Detective X", 잔액·XP·힌트 소유 동일 |
| T3 | 코인 도입 전 레거시(wallet 없음) | 소급 1회: 20 + 완료 미션 Coin, 열어본 TIP 무료 소유; 재시작 후 재소급 없음 |
| T4 | V3 XP 레거시(`xpRules` 없음/1~3) | Case별 XP 합계가 이전 전과 동일 |
| T5 | `copying` 표식에서 재시작 | 네임스페이스 재복사, 중복 키 없음, `done` |
| T6 | 이전 두 번 실행 | 두 번째는 아무 변화 없음 |
| T7 | 프로필 A/B (테스트에서 생성) 각각 다른 미션 해결 | 진행·잔액·TIP·배지·Season 독립 |
| T8 | A 세션에서 Parent Report 패스·Operator 스위치 켬 → B로 전환 | B에서 모두 꺼짐, 라우터가 `/`에서 시작 |
| T9 | 새 모험 시작 | 활성 프로필 키만 삭제, 레거시 원본·다른 프로필 유지, 시작 20 Coins(재소급 없음) |
| T10 | Play Again | `runSeq+1`, 새 `runId`, Case 진행 초기화(기존과 동일) |
| T11 | 내용 그대로인 저장(백그라운드) | `rev` 증가 없음 |
| T12 | 손상된 `lm.profiles.v1` | 복구 또는 새 게스트, 크래시 없음, 원본 보존 |
| T13 | Operator 「CASE NN부터」 | D-5 결정대로(표식 또는 샌드박스), 게임 규칙 동일 |
| T14 | `GameProgress` 기존 형식 JSON 왕복 | 회차 필드가 없는 세이브는 이전과 같은 형식으로 저장(`type_b_p0_test`의 형식 보존 원칙) |

### 4.2 회귀
- `flutter analyze` 0건, 기존 `flutter test` 전체 통과(일부는 2.4대로 저장 키 기대값 수정).
- 12 Cases 전체 플레이스루(`season_playthrough_test`, `full_playthrough_test`), GET A TIP 경제(`tip_shop_economy_test`), 뒤로가기(`back_navigation_test`), 오디오 장면(`audio_scene_test`).
- 수동: 기존 버전으로 플레이한 실기기에 새 빌드 설치 → 진행·Coin 동일.

## 5. 회귀 위험

| 위험 | 영향 | 대응 |
|---|---|---|
| 레거시 키를 직접 읽는 테스트 | ≈10개 실패 | 헬퍼로 일괄 수정. 기대값 의미(특히 "초기화 후 키 없음")를 함께 재검토 |
| 저장 JSON 형식 변화(회차 필드) | 저장 문자열을 비교하는 테스트 실패 가능 | 값이 있을 때만 기록, rev는 내용이 바뀔 때만 증가 |
| `clear()` 의미 변경(레거시 보존) | Game Master "다음 플레이어" 초기화 후에도 이전 아이 이름이 레거시 원본에 남음 | D-4 결정 |
| 소급 조건 변경 | Wallet만 유실된 경우 재소급 안 됨 | 의도된 변경. 테스트로 명시 |
| 세션 컨테이너 도입 | `app.dart` 생명주기 리스너·오디오가 세션마다 재생성 | 전환은 Phase 1에서 테스트만 사용. 앱 시작 경로는 컨테이너 1회 생성 |
| 동기 부트스트랩 폴백 | 테스트와 실제 앱의 경로 차이 | 같은 `LegacyMigrator` 로직 공유, 검증 단계만 차이. 비동기 경로 전용 테스트 추가 |
| 프로필 이름과 Case 세이브 이름 불일치 | 표시 이름 차이 | 게임은 지금처럼 Case 세이브 이름을 사용. 프로필 이름은 목록 표시용이며 부트스트랩 때 다시 맞춤 |
| 비원자 저장 | 기존과 동일 수준 | Phase 2 outbox에서 정리 |

## 6. 구현 전 결정 필요

| # | 질문 | 권장 |
|---|---|---|
| Q-1 (D-3) | 기기당 게스트 수 | 1명. 구조는 N명 |
| Q-2 (D-4) | 레거시 원본 보존 기간, Game Master "다음 플레이어" 초기화 시 원본도 지울지 | 일반 초기화는 보존. Game Master 초기화는 운영 현장의 개인정보를 위해 레거시 원본까지 삭제(확인 문구에 명시) |
| Q-3 | 이전 검증 실패 시 이번 실행 | 레거시 키를 그대로 쓰는 안전 모드(현재 동작과 동일), 다음 실행에 재시도 |
| Q-4 (D-5) | Operator 도구 대상 | Phase 1은 (a) `origin: playtest` 표식만 남겨 화면·테스트 변경을 최소화. 샌드박스 분리(b)는 Phase 3에서 환경 분리와 함께 |
| Q-5 | Phase 1에 언어/지역·진입 선택 화면 포함 여부 | 미포함(Phase 3). Phase 1은 사용자 화면 변화 0 |
| Q-6 | `rev` 증가 기준 | 직렬화 내용이 바뀐 저장만 |
| Q-7 | 레거시 세이브 `runSeq` 기준값 | 0 |

## 7. 안정화 결과 (2026-10-13)

| 항목 | 원인 | 조치 |
|---|---|---|
| `audio_assets_test` 실패 | Windows에서 `Directory.listSync`가 `assets/sounds\x.wav`처럼 역슬래시 경로를 반환해 pubspec 경로(`/`)와 불일치. 파일 누락 아님(디스크 wav 141개 모두 추적됨, 재생 대상 45개 모두 존재) | 테스트에서 경로 구분자 정규화 |
| `sound_prototype_test` 실패 | `core.autocrlf=true`로 작업 사본 `pubspec.yaml`이 CRLF → `'…wav\n'` 검색 실패. 저장소에는 LF | 테스트에서 줄바꿈 정규화 |
| 레지스트리·이전 표식 동시 손상 | 기존 프로필 네임스페이스가 있어도 새 게스트를 만들어 진행이 고아화(삭제는 아님)될 수 있었음 | 네임스페이스 키를 스캔해 같은 프로필을 복구(여럿이면 키가 가장 많은 것). 레거시가 없으면 `origin: fresh`, 이전 표식 미기록 |
| 이전 완료 후 레지스트리 손상 + Wallet 유실 | 복구 시 `walletBackfill: pending`이 되어 2차 소급 가능성 | 소급은 이전이 끝나지 않은 경우(표식 없음/`copying`, 복구 아님)에만 `pending` |
| Operator 스위치만으로 `playtest` | 정상 아이 프로필이 열람만으로 영구 동기화 불가 | 표시 조건을 「잠긴 Case에서 해결」로 축소, 전체 초기화 시 해제 |

**Phase 2 제안(미구현):** 프로필 단위 `playtest` 대신 기록 단위 출처 — Operator로 해결한 Case 회차에 `playtest` 표시, 그 해결로 생긴 `CoinEntry`에 출처 표시 → 동기화 시 해당 회차·항목만 제외하고 나머지 정상 진행은 동기화. 보호자 확인 후 `playtest` 회차를 버리고 프로필을 복귀시키는 경로도 함께 설계.
