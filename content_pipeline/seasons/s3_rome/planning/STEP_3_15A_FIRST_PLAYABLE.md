# STEP 3-15A — 첫 플레이 가능한 Rome 미션 (그림 → Flutter)

**작성:** 2026-10-30 · **결과:** Rome Case 05 M1(고양이 유적 현장 탐색)이 실제 생성 그림으로 Generator를 거쳐 Flutter에서 끝까지 플레이된다. M1 이후 Case 05 전체(M2·M3·Final·엔딩·보고서)도 같은 테스트에서 플레이된다.

이 문서는 다음 시즌("시즌 4 뉴욕 제작해")에서 같은 과정을 반복할 때, **무엇이 자동이고 무엇이 사람 손을 거쳤는지**를 남긴다.

---

## 1. 흐름과 실제 명령

```text
CasePlan(s3_ep05) → Asset Manifest → asset_pipeline(ImageStudio) → 검증(sha256·크기) → 시각 검토
  → 좌표 측정(그리드) → CasePlan 반영(measuredOn) → assets/ 복사·pubspec → generate_case --slice → Flutter 테스트
```

```sh
# 1. 비용 판정(호출 없음) → 생성(5회, 예산 $0.30)
dart run tool/asset_pipeline/asset_pipeline.dart --manifest content_pipeline/seasons/s3_rome/assets.manifest.json \
  --only s3_rome.asset.cat_ruins --only s3_rome.asset.cast_workshop \
  --only s3_rome.asset.cat_tito --only s3_rome.asset.cat_rosso --only s3_rome.asset.cat_luna \
  --max-budget 0.30 --max-calls 5            # 그다음 같은 명령에 --generate
# 2. 검사 → 생성(Case 05만)
dart run tool/season_gen/validate_plan.dart --playable --season content_pipeline/seasons/s3_rome/season.plan.json \
  content_pipeline/seasons/s3_rome/cases/s3_ep05/case.plan.json
dart run tool/season_gen/generate_case.dart --season content_pipeline/seasons/s3_rome/season.plan.json \
  --target sandbox --slice content_pipeline/seasons/s3_rome/cases/s3_ep05/case.plan.json
# 3. 플레이
flutter test test/sandbox/s3_rome_ep05_test.dart
```

## 2. 미션 선택 — Case 05 M1

| 후보 | 신규 그림 | 예상(보수적) | 판단 |
|---|---|---|---|
| 01 M3 map_hall | 장소 4장(map_hall, pantheon_hall, trevi_fountain, colosseum) | $0.194 ($0.290) | Case 01 M1이 증인 대화(초상화 3장 필요) |
| 04 M1 pantheon_hall | 장소 1 + 바닥 돌 4(그중 3장은 ship 참조) | 더 큼 | 참조 체인 |
| **05 M1 cat_ruins** | 장소 1 + 고양이 3 | **$0.146 ($0.218)** | 참조 없음, M2도 같은 장소 |
| 10 M1 civetta_square | 장소 1 + 헬멧 3 + 명함(참조 체인 3단) | $0.371 ($0.556) | 가장 비쌈 |

**제약 충돌(사용자 결정):** 요청은 "신규 1장·호출 1회·$0.20"이었지만, `ExploreScene`은 선택지마다 그림이 필수(`ExplorePicture.picture`)라 어떤 후보도 1장으로는 플레이할 수 없었다. 사용자가 Case 05 M1 4장을 승인했고, Generator가 Case 단위로 검사하므로 M3·Final 장소(cast_workshop)를 더해 **5장·예산 $0.30**으로 승인했다.

- 조사 대상: 고양이 게시판(문서) → 그릇·신전(노트) → 고양이들(선택, 게시판을 읽은 뒤 열림)
- 발견 단서: `s3_ep05_c1`(Tito: 주황·짧은 꼬리·석고 공방), 증거 `s3_ep05_e1`. Discovery "TITO THE CAT"
- 이후 연결: M2(타일 BASSI) → M3(Bassi 공방) → Final(주문서 서랍 318, Case 04 사본 뒷면 `No. 3?8` 회수)

## 3. 이미지

| Asset | 크기 | sha256(앞 16) | 사용량 기준 비용 |
|---|---|---|---|
| cat_ruins | 1536×1024 | b4a020112fdfd47e | $0.0425 |
| cast_workshop | 1536×1024 | 5f8bdb7652ab8321 | $0.0421 |
| cat_tito | 1024×1024 | 8f95c0df04bb177a | $0.0533 |
| cat_rosso | 1024×1024 | 34dfab186d549e39 | $0.0533 |
| cat_luna | 1024×1024 | c6bdc64d5cca1776 | $0.0533 |
| **합계** | | | **$0.2445** (예상 $0.1938, 보수적 $0.2907) |

- API 호출 5회, 실패 0, 재시도 0. 기존 3장(forum_view, livia_base, livia_hood) sha256·크기 불변, 재생성 없음.
- **가격표 오차 → 보정함(마무리 작업):** gpt-image-2 `medium`의 실제 출력 토큰은 정사각형 1756, 가로·세로형 1372(호출 8건, 형태마다 매번 같음)로, 이전 모델 가이드 표(정사각형 1056, 가로 1568, 세로 1584)와 비율이 반대였다. `ImagePricing.measuredOutputTokens`에 실측을 기록하고 추정은 **가이드와 실측 중 큰 값**을 쓴다: 정사각형은 $0.0533(실제와 같음), 가로·세로형은 보수적인 가이드 값 유지. 실측하지 않은 품질(`low`, `high`)은 가이드 그대로(위험 남음). Rome 63장 추정 $3.59 → **$4.14**(보수적 $5.38 → $6.20).
- 원본 `content_pipeline/asset_work/s3_rome/raw/`, 게임 사본 `assets/seasons/season_03_rome/…`(복사 후 sha256 대조), 변환 없음(API 크기 = 게임 크기).

### 시각 일관성 검토 (마무리 작업, 8장 대조 시트와 확대 사본으로 Claude가 눈으로 확인)

- **스타일:** 8장 모두 잉크+수채, 따뜻한 오후 빛, 장면은 화면 가득·인물과 사물은 같은 양피지 배경. Livia 기본·후드는 얼굴·땋은 머리·초록 스웨터가 같다. 고양이 선택지 3장은 같은 받침돌·구도·크기로 공정하다. **문제 없음.**
- **장면 ↔ 선택지:** Rosso(풍성한 긴 꼬리)·Luna(검은색, 가는 긴 꼬리)는 cat_ruins의 고양이와 일치.

| 그림 | 문제 | 영향 | 원인 | 권장 |
|---|---|---|---|---|
| cat_ruins 오른쪽 주황 고양이 | 줄무늬 단모·흰 발은 Tito와 같지만 꼬리가 몸에 감긴 중간 길이: '짧은 꼬리'로 보이지 않음 | 낮음: 판정은 선택지 그림(cat_tito, 짧은 꼬리 분명)으로 함 | 프롬프트는 "short tail"이었으나 모델이 따르지 않음 | 유지. 재생성 시 cat_tito를 참조(images/edits)로 |
| cast_workshop 고양이(이야기상 Tito) | 꼬리가 길고 풍성하게 감김: Rosso에 가까움 | 중간: M1의 단서('짧은 꼬리')와 M3 장면이 어긋남 | 프롬프트가 "An orange cat sits on the table"뿐 | **재생성 완료**(§9) |

자동 검사로는 판단할 수 없는 항목이며, 재생성은 비용 승인이 필요해 하지 않았다.
3. 게시판의 종이는 빈 종이(글은 게임이 편지로 보여 준다): 의도대로.
4. M1 그릇 대사 "Clean bowls"와 달리 그림의 한 그릇에는 사료가 담겨 있다(사소).

## 4. 좌표

- 측정: 그림 위에 100px 격자와 후보 사각형을 그린 사본(`tool/` 밖, 임시)을 눈으로 확인해 픽셀 좌표를 읽었다. 프롬프트의 예상 위치는 쓰지 않았다(예: 게시판 `[60,520,330,880]` → 실제 `[40,400,345,750]`).
- 원본 크기 1536×1024. `play.explore.picture.measuredOn = sha256:b4a02011…` — 이 파일이 바뀌면 `coordinates_stale`로 생성이 멈춘다.

| 대상 | 영역 (px) | 표시(mark) |
|---|---|---|
| board (문서) | [40,400,345,750] | [330,415] |
| bowls | [215,780,485,905] | [470,790] |
| temples | [430,80,925,470] | [905,95] |
| cats (선택) | [645,600,1045,960], [1065,580,1405,965] | [1390,595] |
| 위쪽 거리 (빈 곳) | [0,0,430,390], [925,0,1536,390] | |
| 돌바닥 (빈 곳) | [330,490,640,690], [640,490,940,600] | |
| guideAt / opening | [190,575] / [0,60,1536,1000] | |

**미확정:** Case 01 M3, 04 M1, 10 M1의 좌표는 그대로 임시값(notes에 UNMEASURED). 그림이 생기면 `measuredOn`이 없어서 `coordinates_unmeasured`로 생성이 멈춘다.

## 5. 파이프라인 수정 (STEP 3-14 §9의 1·2·3번)

| 문제 | 수정 |
|---|---|
| 초상화 검사 충돌(WARNING 55) | 대화·엔딩 초상화를 '연출용 그림'으로 분리(`PlayCheck.storyPictureFiles`). assetNeeds 요구 안 함. 파일이 없으면 `story_picture_missing`(생성을 막지 않음), Generator는 얼굴 없이 쓰고 note를 남긴다. Planner: WARNING 83 → 28(남은 것은 `clue_never_used`뿐), INFO `story_picture_pending` 58 |
| Asset Wiring 오분류(37장) | 파일이 어느 plan 필드에 쓰였는지로 분류, `lib/`에서 그 필드를 그리는 위젯 확인(`AssetWiring.shownBy`). 상태 `wired`(assets/에 있음) · `wired_when_made`(생성 후 자동 연결) · `ready_to_wire`(lib 작업 필요) · `not_supported` |
| 좌표 측정 여부 | `picture.measuredOn`(선택 필드), `coordinates_unmeasured`/`coordinates_stale` 검사. Sandbox Case 03은 London의 측정 좌표라 현재 파일 해시를 기록 |

추가: `generate_case.dart --slice` — 시즌 중간 Case만, 그 Case가 쓰는 장소만으로 테스트 생성(`test/sandbox/generated/s3_rome_slice/`). SeasonCatalog 등록 없음.

## 6. 자동 / 수동

| 단계 | 자동 | 사람·수작업 |
|---|---|---|
| 비용 판정·생성·PNG/크기/sha256 검증·기록 | asset_pipeline | 예산 승인 |
| 그림 내용 확인(대상이 그려졌나, 알아볼 수 있나, 장면↔선택지 일치) | — | **사람**(§3) |
| 좌표 측정 | 격자 사본 생성 | **눈으로 읽음**(Claude가 그림을 보고 판단), plan에 직접 기록 |
| `measuredOn` 기록·검증 | 해시 계산, PlayCheck | — |
| assets/ 복사, manifest `generated`, pubspec 폴더 | — | **수작업**(STEP 3-12C 복사 단계가 아직 없음). 승인(`approve.dart`)은 사람만 가능해 생략: draft로 생성 |
| Case 생성 | generate_case --slice | — |
| Flutter 플레이 검증 | 위젯 테스트 | 실기기·에뮬레이터 시각 확인은 안 함 |

## 7. 전체 시즌 제작에 남은 장애물

1. **STEP 3-12C 복사 단계 미구현** — 승인 → assets/ 복사 → manifest·pubspec 갱신이 수작업.
2. **좌표 측정이 사람(또는 Claude의 눈) 의존** — 탐색 4개 미션마다 반복. 자동 위치 검출 없음.
3. **선택지 그림 수와 비용** — 현장 탐색 하나에 그림 4~5장. 정사각형 보정 후 63장 추정 $4.14(보수적 $6.20). `low`/`high` 품질은 실측이 없다.
4. **장면↔선택지 일관성** — 참조(images/edits) 없이 그린 장면 속 물체와 선택지 그림이 다를 수 있다(§3-1·2). 고양이·헬멧·바닥 돌은 장소 그림을 참조로 묶는 방안 검토.
5. **slice의 번호** — 게임 validator가 "Case 05 is case 1 of the season" 1건을 낸다(슬라이스 구조상 정상). 시즌 전체 생성 시에는 사라진다.
6. **초상화 미생성** — Carla 대사·엔딩은 얼굴 없이 플레이됨. 초상화 10장(그중 Livia 2장은 생성 완료) 생성 후 재생성하면 자동으로 들어간다.
7. 증거 카드 그림 12장·커버·지도는 여전히 `lib/` 연결 필요(`ready_to_wire`).

## 8. Git 추적 정책 (마무리 작업)

`content_pipeline/asset_work/`는 `.gitignore` 대상이고 README 정책은 "Git 밖, 별도 백업"이다. 커밋 `150f353`(이미 `origin/main`에 push됨)이 STEP 3-12B의 5개 파일을 강제 추가해 `.gitignore` 테스트가 실패했다. `git rm -r --cached content_pipeline/asset_work`로 추적만 해제했다(디스크의 원본 8장·기록 2개는 그대로, 삭제는 다음 커밋에 들어감). 원격 히스토리에는 3-12B의 3장이 남는다. **asset_work 폴더는 이제 Git에 없으므로 별도 백업이 필요하다**(원본 8장, 실지출 $0.38).

## 9. cast_workshop 재생성 (사용자 승인: 1장, 호출 1회, 예산 $0.10)

- **방식:** 참조 없는 생성. 기존 그림을 참조(images/edits)로 쓰면 파이프라인의 보수적 추정이 참조 1장당 8,000토큰으로 잡혀 약 $0.17이 되어 $0.10에서 거부된다(실제 참조 비용은 약 $0.012였지만 안전장치는 낮추지 않았다). 구도는 프롬프트에 기존 배치를 문장으로 적어 유지했다(왼쪽 출입구·거리·기둥, 가운데 선반, 오른쪽 금테 거울·서랍장, 앞쪽 작업대). 화풍은 같은 `rome_scene` 프리셋.
- **수작업:** 파이프라인에 '검증된 그림 다시 만들기'가 없어, 기존 그림·기록을 백업한 뒤 state의 레코드를 제거(planned로)하고 원본 파일을 옮겼다. manifest 프롬프트 수정과 notes 기록, 게임 사본 교체(백업 sha256 확인 후)도 수작업.
- **결과:** 호출 1회, 사용량 기준 $0.0426(예상 $0.0487, 보수적 $0.0731). 1536×1024, sha256 `f7a6cda662c71445…`, raw와 게임 사본 일치.
- **단서 확인(기존 그림과 비교):** 꼬리가 몸 뒤의 짧은 털뭉치(밑동만)로 분명히 짧다. 기존 그림은 길게 감긴 풍성한 꼬리. 줄무늬 단모·옅은 발이 cat_tito와 같다. 구도·화풍 유지. **명확, 추가 생성 없음.**
- **영향:** M3·Final 배경일 뿐 탐색 좌표가 없어 재측정 불필요. 생성 코드는 파일 경로만 써서 재생성물 변화 없음(`--check` up to date), Case 05 테스트 통과.
- **백업:** `content_pipeline/asset_work/s3_rome/superseded/cast_workshop_v1_5f8bdb7652ab8321/`(원본·게임 사본, 이전 state·image_manifest·assets.manifest, 제거한 state 레코드).

## 10. 백업 대상 (Git 밖)

`content_pipeline/asset_work/s3_rome/` 전체(약 31MB)는 Git에 없다(추적 해제, `.gitignore`). **반드시 별도 저장소(공유 드라이브·클라우드)에 백업**해야 한다. 잃으면 다시 돈을 내고 그려야 하고, 그림의 sha256·비용 기록도 사라진다.

| 대상 | 내용 |
|---|---|
| `raw/` | 생성 원본 9장 중 현재 8장(forum_view, livia_base, livia_hood, cat_ruins, cast_workshop, cat_tito, cat_rosso, cat_luna) |
| `superseded/` | 교체 전 cast_workshop과 그때의 기록 |
| `pipeline_state.json` | 각 그림의 상태·sha256·크기·비용, 실행 기록 |
| `image_manifest.json` | ImageStudio의 요청·호출·사용량 장부(같은 요청 재전송 방지에도 쓰임) |

게임 사본 5장(`assets/seasons/season_03_rome/…`)은 아직 커밋 전이지만 Git 추적 대상이다. 실지출 누계: $0.1381(3-12B) + $0.2445(3-15A) + $0.0426(재생성) = **$0.4252**.
