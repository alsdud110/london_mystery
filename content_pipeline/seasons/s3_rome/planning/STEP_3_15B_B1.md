# STEP 3-15B B1 — Act 1 그림 (중단됨: 안전 필터 거부)

**작성:** 2026-10-30 · **승인:** B1만, 호출 최대 16회, 보수적 예산 $1.80, 자동 재시도 금지, 실패 시 즉시 중단. 전체 3-15B 예산 $5.00.

## 1. 결과

16장 중 **5장 생성·검증, 1장 실패(map_hall), 10장 미실행**. 1장씩 실행(`--max-calls 1`, `--max-budget` = $1.80 − 누적)해 각 그림을 눈으로 확인한 뒤 다음으로 넘어갔다.

| 순서 | Asset | 크기 | sha256(앞 16) | 예상 | 보수적 | 사용량 기준 |
|---|---|---|---|---|---|---|
| 1 | floor_stone_ship | 1024×1024 | cc3f546bf8e8b7a5 | $0.0535 | $0.0803 | $0.0534 |
| 2 | floor_stone_lion (← ship) | 1024×1024 | 15f972648a86b8ee | $0.1176 | $0.1764 | $0.0617 |
| 3 | floor_stone_book (← ship) | 1024×1024 | cad8d620c067e71d | $0.1176 | $0.1764 | $0.0617 |
| 4 | floor_stone_key (← ship) | 1024×1024 | dadb8c41fc679144 | $0.1176 | $0.1764 | $0.0617 |
| 5 | pantheon_hall | 1536×1024 | d960679b186dda4b | $0.0485 | $0.0728 | $0.0425 |
| 6 | map_hall | — | — | $0.0488 | $0.0732 | 없음(거부) |

- API 호출 6회(성공 5, 실패 1), 재시도 0. 사용량 기준 $0.2810, 파이프라인 집계 $0.3542(실패 호출을 보수적 값으로 계산).
- **map_hall 실패:** `Your request was rejected by the safety system … safety_violations=[sexual]` (request `req_de65582429e04a658cd8b16397010f19`). 그림 없음. 추정 원인: 프롬프트의 "a large white classical statue"(고전 나체 조각상으로 해석). 거부된 요청의 청구 여부는 OpenAI 청구서로만 확인 가능.
- state의 map_hall은 `failed`: 다음 실행에 `--only map_hall`을 넣으면 **같은 프롬프트로 다시 보낸다**. 프롬프트를 고친 뒤(요청 키가 바뀜) 승인받아 실행할 것.

## 2. 시각 검토

- 바닥 돌 4장: 같은 모자이크 테두리·트래버틴·빛·크기, 조각만 다름(돛 하나인 배, 왼쪽으로 걷는 사자, 빈 페이지의 책, 큰 열쇠). 글자 없음. **공정함.** 참조(images/edits) 1장당 실제 입력 이미지 토큰 1024(보수적 상한 8000).
- pantheon_hall: 위쪽 가운데 천장의 눈(위 가장자리에서 조금 잘림), 왼쪽 빛 원, 오른쪽 청동문, 문 앞 벤치 위 흰 카드, 아래 바닥 돌 4개(조각은 알아볼 수 없음: 선택지 그림과 충돌하지 않게 한 의도대로). 화풍은 cat_ruins·forum_view와 같은 잉크+수채.
- 경미: 벤치 카드에 알아볼 수 없는 낙서 같은 선이 있음(글자로 읽히지 않음). 편지의 "guide sign"은 그림에 따로 없음(게임이 편지로 보여 줌). Case 01 M3 선택지로 쓸 때 천장 눈이 작게 보일 수 있음(실기기 미확인).

## 3. 좌표 (Case 04 M1, 실측)

100px 격자 사본(ImageMagick, 스크래치 폴더)을 눈으로 읽음. `measuredOn = sha256:d960679b…`.

| 대상 | 영역 (px) | mark |
|---|---|---|
| bench (문서) | [1095,690,1345,880] | [1330,700] |
| eye | [530,0,800,120] | [785,15] |
| light | [150,715,650,805] | [640,725] |
| stones (선택) | [95,850,1095,1010], [1095,885,1290,1010] | [1080,860] |
| 기둥 (빈 곳) | [0,380,330,705] | |
| 청동문 (빈 곳) | [1300,290,1500,690], [1345,690,1500,820] | |
| guideAt / opening | [1230,765] / [20,0,1516,1020](유지) | |

벤치와 돌 영역은 겹치지 않게 나눴다(4번째 돌 윗부분 약 13px은 영역 밖).

## 4. 연결

- assets/ 복사(sha256 대조): pantheon_hall, floor_stone ×4. manifest `generated`, pubspec에 `cases/case_04/` 추가, `asset_wiring.json` 갱신(wired 5 → 10).
- **Case 04 slice 생성 불가:** 유일한 차단은 `rotonda_bookshop.png`(B1 미실행분). M1 좌표 검사는 통과.
- 새로 플레이 가능한 Case 없음.

## 5. B1 나머지 (재승인 필요)

미실행 10장 + map_hall: guard_room, map_hall(프롬프트 수정), trevi_fountain, flower_market, rotonda_bookshop, colosseum, giulia, sofia, enzo, aldo, carla. 참조 없음. 보수적 $0.7964, 예상 약 $0.53, 사용량 기준 약 $0.50.

프롬프트 수정 제안(미적용):
- map_hall: "a large white classical statue" → "a large white marble statue of a Roman senator wrapped in a long toga" (발치 먼지 단서 유지).
- trevi_fountain: 실제 분수의 반나체 조각 때문에 같은 거부 위험 → "statues in long flowing robes".

---

# B1 완료 (2026-10-30, 두 번째 승인: 11장, 호출 11회, 추가 예산 $1.00)

## 6. 프롬프트 수정 (승인분만)

- map_hall: "a large white classical statue" → "a large white marble statue of a Roman senator wrapped in a long toga" — 통과.
- trevi_fountain: "statues" → "statues in long flowing robes" — 통과(가운데 오케아노스는 실제처럼 상반신 노출, 필터 통과).

## 7. 생성 (11장 성공, 실패 0, 재시도 0)

| Asset | 크기 | sha256(앞 16) | 사용량 기준 |
|---|---|---|---|
| map_hall | 1536×1024 | 266bb26b88598120 | $0.0427 |
| trevi_fountain | 1536×1024 | 27554e399c8e44f4 | $0.0422 |
| colosseum | 1536×1024 | 4edf531cbb68c624 | $0.0421 |
| guard_room | 1536×1024 | 8a1de9046edeeb3d | $0.0421 |
| flower_market | 1536×1024 | 96be0f43eeb6c9a5 | $0.0421 |
| rotonda_bookshop | 1536×1024 | e06c3be5527a3719 | $0.0421 |
| giulia_base | 1024×1536 | 1373b4300e53249e | $0.0418 |
| sofia_base | 1024×1536 | d6623a200ed1a833 | $0.0418 |
| enzo_base | 1024×1536 | 2160d23a290e2413 | $0.0418 |
| aldo_base | 1024×1536 | be961f98ccd68adf | $0.0418 |
| carla_base | 1024×1536 | 95e9d8316403ab72 | $0.0418 |
| **합계** | | | **$0.4624** (예상 $0.5310, 보수적 $0.7965) |

추가로 livia_base(3-12B 생성분, sha256 6996ddd6ef0b1de5)를 재생성 없이 assets/에 복사(Case 01 M1 증인).

시각 검토: map_hall 먼지 흔적이 case→statue→stairs→door 순서로 Case 01 M2 정답과 일치. guard_room 레버 상자(불 꺼짐 단서). rotonda_bookshop 소포·저울(Case 04 M3 weigh). Aldo 녹색 잉크 손가락(Case 02 M2). Carla 어깨의 짧은 꼬리 주황 고양이(Tito). Colosseum은 물·동전 없음(선택지 공정).
**수정 권장(진행 비차단):** flower_market의 가게 주인이 젊은 남자로 그려짐(Pia는 60대 여성, 그녀의 대화가 이 배경 위에 표시). trevi 소녀가 등지고 던지지 않음(Case 02 대사 "over their shoulders"와 약간 차이). pantheon_hall 천장 눈이 그림 위 가장자리에서 잘려 휴대폰에서 작게 보임.
**절차 메모:** sofia 검토 전에 enzo 생성을 함께 보냄(두 장 모두 통과, 이후 1장씩 복귀).

## 8. 좌표 (Case 01 M3, 실측)

`measuredOn = sha256:266bb26b…`. card [1265,790,1500,940] mark [1480,800] · case [335,345,645,750] · statue [725,90,980,740] · stairs [985,600,1265,885] · map(선택) [40,380,330,835] · 창문 4영역(조각상 머리 피함) · 바닥 [0,860,960,1024] · guideAt [1358,858]. 카드가 작게 그려져 주변 바닥까지 영역으로 잡음. 모든 영역 비겹침(테스트로 검사).

## 9. Generator

일반(비슬라이스) 생성은 시즌 12개 Case 전부를 요구(`case_left_out`)하므로, 기존 `--slice`에 Case 01~05를 순서대로 넘기고 `--out test/sandbox/generated/s3_rome_c01_05`로 생성(Case 05 단독 슬라이스 폴더와 분리). 검사 조건 변경 없음. 게임 validator 지적 0건(Case 01부터라 번호 문제 없음). Pia 초상화만 미생성(얼굴 없이 표시).

## 10. 검증

- `test/sandbox/s3_rome_c01_05_test.dart`(12개): Case 01→05 순서 실제 앱 플레이(인트로, 지도 이동, 대화 전·후, 증인 대화, 편지, 오답·정답, 힌트, Discovery, 스토리, Final, 엔딩, 보고서, 다음 Case 해금, 재시작 2회), 측정 탐색 2개를 작은 폰·길쭉한 폰·태블릿에서.
- 에뮬레이터(Pixel 3a API 34, 393×783dp): `integration_test/rome_c01_05_qa_test.dart` + `test_driver/rome_qa_driver.dart`, 스크린샷 `qa/screenshots/rome/`(Git 제외). 앞 미션은 컨트롤러로 처리하고 대상 화면만 실제 탭.

## 11. UX 발견

1. 공용 탐색 엔진의 문서 닫기 버튼이 'BACK TO THE STATION'(런던 문구 하드코딩): Rome에서도 그대로. 공용 위젯이라 이번에 수정 안 함.
2. 작은 화면(375×667)에서 힌트를 열면 그림 칸이 짧아져 판테온 바닥 돌(선택 대상)이 시야 밖으로 밀림: 그림을 끌어 올려야 함(엔진의 의도된 '보던 위치 유지').
3. 휴대폰에서 탐색 그림은 화면 폭 기준 3:2 띠(약 393×260)로만 보이고 아래는 빈 종이: 천장 눈·카드처럼 작은 단서는 작게 보임.
4. 큰 PNG(3~4MB) 디코딩 지연: 느린 에뮬레이터에서 증인 초상화·배경이 수 초간 빈 카드로 보였다가 표시됨. 실기기 미확인.
5. 판테온 문서 카드가 길어 작은 화면에서 닫기 버튼까지 스크롤 필요. 바닥 돌 선택 화면에서 아래 두 장의 이름표도 스크롤 필요.
