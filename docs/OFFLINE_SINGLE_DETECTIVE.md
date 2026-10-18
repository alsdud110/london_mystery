# 오프라인 단일 탐정 구조

> **상태:** 구현 완료 (2026-10-16) · 커밋 전
> **결정:** 계정·Firebase·클라우드 동기화를 완전히 제거하고, **기기당 탐정 프로필 1개만 쓰는 100% 오프라인 게임**으로 전환한다.
> 이전 방향(사용자 계정 + 클라우드)의 설계 문서는 삭제했다(git 기록에 남아 있음). PRD/기능 명세/유저 플로우 V2에는 폐기 배너를 달았다.

## 1. 원칙

- 게임의 모든 기능(최초 실행, 탐정 생성, 미션, 저장, XP·Coin, 사건 완료, 재시작 후 이어하기)은 **네트워크 없이** 동작한다. 앱은 네트워크 상태를 확인하지 않고, 어떤 서버에도 요청하지 않는다.
- 기기에는 탐정 **한 명**뿐이다. 회원가입·로그인·계정·탐정 선택 화면은 없다.
- 저장은 기기의 `SharedPreferences`에만 한다. 여러 키에 걸친 저장은 `SaveJournal`로 **전부 아니면 전무**(원자성)를 유지한다.
- 기존 진행 기록은 절대 지우지 않는다. 옮길 때는 **복사 → 다시 읽기 → 검증** 후에만 새 기록을 쓴다.

## 2. 탐정 프로필

| 항목 | 저장 위치 |
|---|---|
| 로컬 프로필 ID (32자리 hex, 불변) | `lm.detective.v1` → `profile.id` |
| 탐정 이름 | `profile.detectiveName` + 각 사건 저장 `GameProgress.detectiveName` (함께 변경) |
| 아바타 (`boy` / `girl`) | `profile.avatar` |
| 생성 시각 | `profile.createdAt` |
| 게임 진행 기록 | `lm.p.<id>.progress.v1[.epNN]`, `lm.p.<id>.season.v1`, `lm.p.<id>.wallet.v1` (기존 키 그대로) |

- `DetectiveRecord`(`lib/data/models/profile.dart`) = `{schema: 1, profile, held}`. `held`는 이 기기에서 발견됐지만 이 탐정이 아닌 이전 프로필 ID 목록(저장 데이터는 손대지 않고 보관만 함).
- 슬롯은 첫 실행부터 있고(ID가 저장 네임스페이스), **이름을 정하면 "생성됨"**(`isCreated`).
- 중복 생성 불가: `GameController.createDetective`는 이미 탐정이 있으면 거부하고, 라우터는 탐정이 있을 때 `/register`를 `/`로 돌려보낸다.
- 이름·아바타 변경: 지도 메뉴 **My detective** → `/detective`(`DetectiveSettingsScreen`). `renameDetective`는 모든 사건 저장의 이름을 한 트랜잭션으로 바꾸고 진행·XP·Coin·배지·시즌은 그대로 둔다.
- NEW ADVENTURE(타이틀, 확인 대화상자): **같은 탐정(ID·이름·아바타·생성 시각 유지)**으로 게임을 처음부터. 모든 사건·시즌·XP·배지가 초기화되고 코인은 새 지갑(시작 코인 20)으로. 이후 How to Play(본 적 없을 때) → 시즌 케이스북. 탐정 생성 화면으로 가지 않는다.
- Game Master「다음 플레이어」초기화: 게임 + 탐정(이름·아바타)까지 비우고 레거시 원본도 삭제 → 다음 아이가 CREATE YOUR DETECTIVE.
- 어떤 초기화도 보류(held) 프로필, 클라우드 빌드가 남긴 `conflicts.v1`, 사운드 설정은 지우지 않는다.

## 3. 첫 실행 흐름

Title → START ADVENTURE → **CREATE YOUR DETECTIVE**(`/register`: BOY/GIRL 카드 → 이름 → START INVESTIGATION) → How to Play(처음 한 번) → Season Cover → Opening → Case 01.
아바타를 고르지 않으면 "Choose your detective first.", 이름 규칙은 기존 `DetectiveName`(1~12자, 영문·한글·숫자·공백·`.`·`-`).

## 4. 기존 데이터 이전 (`LegacyMigrator`, 앱 시작 시 1회)

1. `lm.detective.v1`이 있으면 그 탐정으로 시작.
2. 없고 계정 빌드의 목록 `lm.profiles.v1`이 있으면:
   - 진행 기록이 있는 프로필이 **1개** → 그 프로필이 탐정. 이름·출처·코인 소급 상태를 그대로 가져온다.
   - **0개** → 게스트(계정 없이 쓰던 프로필).
   - **2개 이상** → **보류**(`ProfileHold`). 아무것도 고르거나 쓰지 않는다. 보호자 확인 화면(`DetectiveHoldScreen`, 곱셈 Parent Gate)에서 하나를 고르면 그것이 탐정이 되고 나머지는 `held`로 보관.
   - 나머지 프로필의 저장 키와 `lm.profiles.v1` 원본은 **변경·삭제하지 않는다.**
3. 둘 다 없으면 프로필 이전의 저장(`lm.progress.v1…`, `lm.season.v1`, `lm.wallet.v1`)을 복사·검증(기존 규칙 그대로: 복사 기록 `lm.migration.legacy.v1`, 중단 후 재개, 이미 있는 키는 유지, 검증 실패 시 원본을 읽기만 하는 안전 모드 후 다음 실행에 재시도). 기록이 손상돼 네임스페이스만 남은 경우도 같은 규칙(진행 기록 2개 이상이면 보류).
4. "진행 기록" = 이름이 있는 사건 저장, 시작한 사건, 해결한 미션 또는 해결한 사건. 시작 코인만 있는 지갑은 진행 기록이 아니다.

## 5. 미션 완료 연출

- 일반 미션(Discovery Moment): 맨 위에 짧은 축하 문구 → 발견 제목 → (증거 카드) → 한 줄 설명 → `+XP · +COINS` → 새 배지 → **CONTINUE INVESTIGATION**. 2.2초 순차 등장, 탭하면 즉시 완성, 모션 줄이기 = 즉시.
- 축하 문구(`DiscoveryType.cheer`): DEDUCTION → *Brilliant Deduction!*, EVIDENCE/CLUE FOUND → *Clue Discovered!*, CLUE CONFIRMED·STORY DISCOVERY → *Excellent Detective Work!*, NEW LEAD·PUZZLE COMPLETE → *You Made It!* — 퍼즐 전에 본 정보에는 "Discovered"를 쓰지 않는 기존 타이밍 규칙을 지킨다(테스트로 강제).
- Final: 자물쇠가 열린 뒤 *You Made It!* + 보상 줄 + CONTINUE INVESTIGATION(Post-Case → Case Closed 흐름 그대로).
- 중복 지급 방지: 코인은 미션당 평생 1회(`Wallet` 키). 다시 플레이한 미션(`SubmitOutcome.firstSolve == false`)은 보상 대신 *Already in your case file*. 사건 XP는 그 회차의 계산값이라 누적되지 않는다.

## 6. 제거한 것

계정(회원가입/로그인/로그아웃/이메일 인증/비밀번호 재설정/계정 설정·삭제·동의), Firebase Auth·Firestore·Cloud Functions 연동, 동기화(Scheduler/Sender/Restorer/Gate/Outbox/Journal 병합/충돌 해결/사건 파일 2개 선택), 여러 탐정 선택, DEV/PROD Firebase 연결, `LM_CLOUD_SYNC`·`LM_CLOUD_EMULATOR`, Firebase 통합 테스트와 Rules·Functions 테스트, Android `google-services` 플러그인, iOS "Firebase config (flavor)" 빌드 단계, 디버그용 에뮬레이터 cleartext 설정.
앱 ID와 서명 설정은 유지한다. (이후 2026-10-18에 dev/prod 플레이버를 없애고 단일 앱 `com.londonmystery.app` "London Mystery"로 통합했다. release 빌드는 upload 키 필수.)

## 7. 필요한 아바타 이미지 (Custom Asset Required)

코드는 `assets/art/avatars/detective_boy.png`, `detective_girl.png`를 읽는다. 폴더(`.gitkeep`)와 `pubspec.yaml` 등록은 이미 되어 있어 **두 파일을 넣기만 하면** 바로 표시된다. 파일이 없으면 카드에 기존 잉크 아이콘(탐정 모자)과 BOY/GIRL 글자만 보인다(임시 그림 없음). 권장: 4:5(1024×1280), 투명 배경 PNG, 머리~어깨.
