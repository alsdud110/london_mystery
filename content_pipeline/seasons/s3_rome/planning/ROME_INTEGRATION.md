# Rome 정식 통합 · Season Factory

**작성:** 2026-10-30 · **이미지 예산:** 이번 작업 별도 $5.00(보수적 비용 기준 차단). 커밋·Push 없음.

## 1. 정식 등록

- **운영 출력:** `generate_season.dart --target game`이 시즌 전체를 `lib/data/generated/s3_rome/`에 만든다.
  - 콘텐츠 15개 파일 외에 `s3_rome_content.g.dart`(SeasonContent)와 `s3_rome_art.g.dart`(지도·커버·도시·증거 그림)를 함께 만든다.
  - 등록 파일 2개(`generated_seasons.g.dart`, `generated_season_art.g.dart`)도 자동 생성된다.
  - 게임은 이 등록 파일을 `SeasonCatalog.all`, `SeasonMap.bySeason`, `ArtAssets.seasonCovers`/`evidencePictures`, `WorldCities.all`에서 읽는다. 다음 시즌은 손으로 고칠 코드 없이 등록된다.
- **시즌 플랜에 추가한 필드:** `places[].locId`, `art.cover/map/worldCity`(스키마, 모델, PlanCheck 규칙).
- **Sandbox 사본 정리:** `test/sandbox/generated/s3_rome`(sandbox 사본)은 삭제했다. 테스트는 게임에 등록된 Rome을 그대로 플레이한다.
- **해금:** 기존 규칙 그대로다. Paris Case 12의 엔딩을 닫으면 Rome이 열리고, Paris 보고서와 보드에 GO TO ROME이 나온다.
- **진입:** London 전용 프롤로그 대신, Rome 보드의 BEGIN INVESTIGATION을 누르면 Case 01 이야기 소개로 바로 간다. London이 아닌 시즌에서 프롤로그 링크는 보드로 돌려보낸다.
- **아카이브 스포일러 수정:** London 진행 중에는 Rome 봉인 파일이 Paris 이름을 말하지 않는다("Solve the season before it…").
- **저장:** Rome 키는 `.season.v1.s3_rome`다. London/Paris 키는 바꾸지 않았다. Rome 등록 전의 저장을 불러와도 모든 키가 그대로임을 테스트로 확인했다.
- **승인:** 플랜 승인(`approve.dart`)은 사람의 몫이라 하지 않았다. 생성 manifest에는 `approved: false`로 기록된다.

## 2. 그림 (14회, 실패 0, 검증 불합격 1 → 재생성 1)

| Asset | sha256(앞 16) | 사용량 | 보수적 |
|---|---|---|---|
| city_map | 5bf9329343cc935e | $0.0433 | $0.0744 |
| cover | 03a040a03c186723 | $0.0428 | $0.0741 |
| 증거 8장(참조 없음) | | $0.4263 | $0.6402 |
| plaster_copy, aldo_photo(← real_piece) | | $0.1233 | $0.3527 |
| livia_drawing v1(불합격: 돌 조각으로 그려짐) | | $0.0617 | $0.1765 |
| livia_drawing(참조 제거, 종이 명시) | fbc34d34d3877432 | $0.0536 | $0.0806 |
| **합계** | | **$0.7510** | **$1.3985** |

- 예산 $5.00 중 남은 금액은 사용량 기준 $4.25, 보수적 기준 $3.60이다.
- **재사용:** 실제 조각(s3_ep11_e1), 명함(s3_ep07_e3), 노란 헬멧(s3_ep10_e2)을 증거 그림으로 연결했다.
- **생성하지 않음:**
  - 프롤로그와 금색 타일: 표시할 화면이 없다.
  - 부엉이 공개 장면: Case 08 M2 대화가 후드 쓴 Livia 초상화와 다리 배경을 이미 보여 준다.
- **지도 랜드마크 11곳:** 격자 실측 결과를 `art.map`에 기록했다(`measuredOn`).
  - 나보나(365,265), 시장(470,485), 판테온(680,395), 유적(735,545), 트레비(785,235), 스페인 계단(1070,210)
  - 대학(1340,360), 캄피돌리오(860,790), 포로(1150,620), 섬(235,760), 치베타(530,640)

## 3. Asset Pipeline

- **`--apply`:** 복사(`.part` → sha256 확인 → 이동), 덮어쓰기 금지(CONFLICT), manifest `generated` 갱신, pubspec 폴더 등록.
- **`--doctor [--fix]`:**
  - 게임 사본과 같은 원본은 복구한다(restored).
  - 다른 PC에서 만든 그림은 기록으로 받아들인다(adopted).
  - 다른 그림이면 CONFLICT로 보고만 한다.
- **재생성 방지:** 생성 실행은 assets/에 이미 있는 그림을 절대 다시 만들지 않는다(in game). 원본이 없을 때 게임 사본이 같으면 자동으로 복구한다.
- **이 PC 상태:** 27장을 adopted로 기록했고, livia 2장을 복구했다. 지금은 `--doctor`가 "all as recorded"다.

## 4. UX

- **그림 선택 페이지:** 아래에 더 있을 때만 MORE BELOW 표시가 나온다(탭하면 스크롤, 숨으면 탭을 막지 않음). 미션 그림 선택과 탐색 선택 페이지에 적용했다. 그림 크기는 줄이지 않았다.
- **이미지 디코딩:** 초상화 3곳, 그림 선택 타일, 탐색 선택 타일을 보이는 폭 × 픽셀 비율로 디코딩한다(`DisplaySizedImage`).
  - 예: 1024×1536 초상화를 3배 화면에서 220dp로 보이면 660px 폭으로 디코딩한다(메모리 약 42%).
  - 탐색 그림은 확대 때문에 원본 그대로 둔다. 실기기 시간 측정은 하지 않았다.
- **판테온:** opening 개선을 유지했다. 천장 눈은 원본에서 잘린 그대로다.
- **학부모 보고서의 영어 표현:** Rome 34개를 화면 문장과 일치하도록 고쳤다. 검사는 대화·탐색 문장까지 보도록 넓혔다.

## 5. Season Factory

- `tool/season_factory/season_factory.dart`: `status`, `run --budget`, `reviewed`, `reject`.
- 스킬: `.claude/skills/create-season`.
- 범용 테스트 `test/generated_seasons_test.dart`: 생성된 모든 시즌을 검사하고 끝까지 플레이한다. 탐색은 4개 화면에서 플레이한다.

## 6. 테스트

- `flutter analyze`: 문제 없음.
- **전체 `flutter test`(마지막 실행, 307초):** 실패 2건이었다. 둘 다 고친 뒤 해당 테스트 파일을 다시 실행해 통과했다.
  - `palette_facts` 복사본 재작성
  - Case 05 슬라이스 재생성
  - 수정 후 `test/season_gen` 전체, `s3_rome_ep05_test`, `palette_facts_test`: 338개 통과
- 그 이전 실행에서 "London/Paris만 있다"고 고정된 단언 41건을 고쳤다(그중 실제 문제 2건: 아카이브 스포일러, 학습 표현 불일치).
- 수정 후 전체 스위트는 다시 돌리지 않았다.
- 실기기와 에뮬레이터는 이번 단계에서 검증하지 않았다(캡처 테스트 `integration_test/rome_qa_test.dart`는 갱신했으나 미실행).
