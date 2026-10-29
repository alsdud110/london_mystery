# STEP 3-15B 준비 — Rome 남은 그림: 수, 참조, 연결, 순서, 비용

**작성:** 2026-10-30 · 기준: `pipeline_state.json`(validated 8장), `assets.manifest.json`(63장), `planning/asset_wiring.json`, 12개 CasePlan. 가격은 정사각형 보정 후(`ImagePricing.measuredOutputTokens`). **이 문서를 쓰는 동안 생성한 그림 없음.**

## 1. 현재 생성 상태

| | 장 | 그림 |
|---|---|---|
| 생성·검증, assets/에 있음 | 5 | cat_ruins, cast_workshop(재생성본), cat_tito, cat_rosso, cat_luna |
| 생성·검증, assets/ 복사 전 | 3 | forum_view, char_livia_base, char_livia_hood (API 호출 없이 복사만 하면 됨) |
| 미생성 | 55 | 아래 |

## 2. 미생성 55장의 분류 (게임 연결 가능성 기준)

| 분류 | 장 | 연결 | 그림 |
|---|---|---|---|
| **퍼즐 필수**(장소·선택지·증인) | 34 | 생성 후 Generator가 자동 연결(`wired_when_made`) | 장소 15: guard_room, map_hall, trevi_fountain, flower_market, pantheon_hall, rotonda_bookshop, navona_square, lecture_hall, spanish_steps, tiber_bridge, restoration_lab, map_archive, civetta_square, site_office, roman_library · 증인 4: enzo, sofia, pia, bruno_site · 선택지 15: colosseum, floor_stone ×4, bridge ×2, room ×2, helmet ×2, ev_yellow_helmet, ev_real_piece, stone ×2 |
| **참조로만 필요** | 1 | `ready_to_wire`(증거 카드는 lib/ 작업 필요) | ev_business_card: ev_yellow_helmet → 헬멧 2장이 이것에서 그려짐 |
| **연출용 얼굴**(없으면 얼굴 없이 플레이) | 4 | 생성 후 자동 연결 | giulia, aldo, carla, bruno_base(bruno_site의 참조이기도 함) |
| lib/ 연결 필요 | 14 | `ready_to_wire`: 생성해도 화면에 안 나옴 | cover, city_map, 증거 카드 11장, scene_owl_reveal |
| 보여 줄 화면 없음 | 2 | `not_supported` | prologue, ev_gold_tiles |

**Rome 12개 Case 전체를 플레이하는 데 필요한 미생성 그림: 퍼즐 필수 34 + 참조 의존 1 = 35장**(필수). 얼굴 4장을 더하면 39장(완전한 연출). lib/ 작업 대상 16장은 3-15B에서 보류 권장.

## 3. Case별 남은 필수 그림

| Case | 필수(장소·퍼즐) | 얼굴(선택) |
|---|---|---|
| 01 | guard_room, map_hall, pantheon_hall, trevi_fountain, colosseum, enzo, sofia (7) | giulia |
| 02 | trevi_fountain(01과 공유) | aldo, giulia |
| 03 | flower_market | giulia, pia |
| 04 | rotonda_bookshop, pantheon_hall(공유), floor_stone ×4 | giulia |
| 05 | **없음(완료)** | carla |
| 06 | navona_square, lecture_hall | aldo, giulia |
| 07 | spanish_steps | bruno_base, giulia |
| 08 | tiber_bridge, restoration_lab, bridge_angels, bridge_hole | — |
| 09 | map_archive, roman_library, room_bath, room_theatre (+forum_view 복사) | aldo |
| 10 | civetta_square, helmet ×2, ev_yellow_helmet (+ev_business_card 참조) | sofia |
| 11 | site_office, stone ×2, ev_real_piece, pia, sofia, bruno_site(+bruno_base 참조) | — |
| 12 | civetta_square, map_hall, roman_library(모두 공유) | aldo, enzo, giulia, sofia |

Generator(slice 아님)는 Case 01부터 순서대로만 만들므로 **Act 단위로 생성**해야 플레이 가능 구간이 늘어난다.

## 4. 참조 관계 (미생성)

| 그림 | 참조 | 단계 |
|---|---|---|
| floor_stone_lion / book / key | floor_stone_ship | L1 |
| ev_yellow_helmet | ev_business_card | L1 |
| helmet_white_crane / helmet_yellow_plain | ev_yellow_helmet | L2 |
| stone_lion / stone_street | ev_real_piece | L1 |
| char_bruno_site | char_bruno_base | L1 |
| (보류) ev_plaster_copy, ev_aldo_photo, ev_livia_drawing | ev_real_piece | L1 |
| (보류) scene_owl_reveal | char_livia_hood(완료), tiber_bridge | L2 |

같은 실행의 `--only`에 참조 원본을 함께 넣으면 Scheduler가 원본을 먼저 만든다. 참조가 실패하면 그 뒤 그림은 `waiting`.

**일관성 위험(3-15A 교훈):** 장면 속 물체와 선택지 그림이 따로 그려지면 어긋난다(cast_workshop의 고양이). 3-15B에서는 pantheon_hall의 바닥 돌 ↔ floor_stone ×4, civetta_square의 헬멧 걸이 ↔ helmet ×3, site_office의 돌 ↔ stone ×3을 생성 직후 대조해야 한다. 장소 그림이 선택지를 참조하도록 manifest를 바꾸는 방안은 비용(참조 1장당 보수적 $0.096)과 함께 결정 필요.

## 5. 권장 생성 순서·비용·호출 제한

| 배치 | 그림 | 참조 | 파이프라인 추정 | 보수적(예산 판정) | 실측 기반 예상 | `--max-calls` |
|---|---|---|---|---|---|---|
| **B1** Act 1(Case 01~04) + 얼굴 giulia·aldo·carla | 16 | 3 | $0.986 | **$1.479** | ~$0.75 | 16 |
| **B2** Act 2(Case 06~08) | 7 | 0 | $0.337 | **$0.505** | ~$0.29 | 7 |
| **B3** Act 3(Case 09~12) + 참조 의존 2 | 16 | 6 | $1.193 | **$1.789** | ~$0.82 | 16 |
| **합계** | **39** | 9 | $2.515 | **$3.773** | ~$1.87 | 39 |
| (보류) lib/ 작업·화면 없음 | 16 | | $1.155 | | | |

- '실측 기반 예상'은 이번 9회 호출의 usage(가로·세로형 1372토큰, 정사각형 1756토큰, 참조 1장 약 1536토큰)로 계산한 값으로 청구액이 아니다. 예산 판정은 파이프라인의 보수적 값으로 한다(참조 1장 8,000토큰 상한 유지).
- 한 실행의 호출 상한은 50(`--max-calls`), API 오류 시 그 자리에서 정지, 자동 재시도 없음.
- B1 완료 후: 좌표 측정 2건(Case 01 M3 map_hall, Case 04 M1 pantheon_hall) → `measuredOn` 기록 → Case 01~05 일반 생성(slice 아님) 가능. B3 후: Case 10 M1 civetta_square 측정.
- 각 배치 전에 forum_view·livia ×2 복사(B3 전까지), 각 배치 후 시각 검토·좌표 측정·assets/ 복사(수작업, STEP 3-12C 미구현).

## 6. 3-15B 시작 전에 사람이 정할 것

1. B1만 먼저 할지, B1~B3를 한 번에 승인할지(예산 상한).
2. 얼굴 4장을 포함할지(없어도 플레이 가능).
3. 장면↔선택지 일관성을 참조로 묶을지(비용 증가) 생성 후 검토로 갈지.
4. `content_pipeline/asset_work/` 백업 위치.
