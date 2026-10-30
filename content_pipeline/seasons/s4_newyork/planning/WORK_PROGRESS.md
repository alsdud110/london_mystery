# Season 4 New York — 작업 진행 기록

- 시작: 2026-10-30, `/create-season 시즌 4 뉴욕 제작` (이미지 예산 **$6.84**, 사용자 지정)
- 사용자 지시(2026-10-30): **STEP 1(Plan)까지만 완료하고 중단.** STEP 2(Factory: 이미지 생성·검토·좌표 측정·난이도별 문장·코드 생성)는 다음 세션. Commit/Push 금지.
- 2026-10-30 2차 세션(STEP 2): 그림 59장 생성·검토·게임 반영, 지도·탐색 좌표 측정 완료 후 **사용자 지시로 레벨 문장 단계(exit 35)에서 중단.** Commit/Push 금지.
- 2026-10-30 3차 세션: 레벨 문장 작성 재개, **사용자 지시(주간 사용량 87%)로 8/12 케이스 작성 후 중단.** 코드 생성·시즌 등록·전체 테스트·이미지 재생성 안 함. Commit/Push 안 함.
- 2026-10-30 4차 세션: 남은 레벨 4케이스·전체 review·코드 생성·시즌 등록·전체 테스트·백업 완료.
- 현재 상태: **시즌 4 뉴욕 게임에 들어감(factory exit 0).** 결과는 `planning/FACTORY_REPORT.md`. Commit/Push 안 함.

## 완료 항목 (STEP 1)

| 파일 | 내용 |
|---|---|
| `planning/brief.json` | `plan_season.dart init --season 4 --city "New York"` |
| `season.plan.json` | 제목·태그라인, 핵심 미스터리, 인물 9, 장소(location) 10, place 14(각 locId), 3막, outro/finale, languageArc, `art.cover`, `art.worldCity`(cityId `newyork`, 40.71/-74.01, `mapAt` 없음: 월드맵 그림에 뉴욕이 없음) |
| `cases/s4_ep01…12/case.plan.json` | 12케이스 × (미션 3 + 파이널 1) = 48퍼즐 |
| `planning/story_bible.json` | coreMystery, 인물·장소·막·케이스 개요, 미스터리 질문 12, clueThreads 35(케이스 플랜의 clueInputs에서 그대로 추출), 타임라인, englishReview 12 |
| `assets.manifest.json` | 그림 59장 계획(전부 `planned`), 참조 13, 추정 $3.78(gpt-image-2 medium, 정가 기준) |
| `planning/quality_report.json` | `plan_season.dart check` 결과 |

검증: `plan_season.dart format` → `plan_season.dart check` **0 ERROR**, 55 WARNING, 125 INFO (exit 0). 실제 생성기(in memory) 포함.

남은 WARNING (의도/허용):
- `clue_never_used` 31: 노트북 증거(플레이북상 정상).
- `story_unknown_name` 13: 찻집 주인 "Mrs. Lee"(초상 없는 단역, season.plan 인물 아님).
- `en_repeated` 9: 대질 장면의 공통 UI 문구, 그리고 Case 04/11에서 일부러 다시 읽는 놋쇠 꼬리표 문장.
- `late_diversity_drop` 1: 3막 퍼즐 종류 7 < 2막 8 (3막에 combo_dial_lock 없음). 권고 사항.

## 주요 설계 결정

- **제목**: The Silver Lark of New York / FOLLOW THE SONG.
- **진실**: 1926년 장난감 장인 Eleanor Hart가 노래하는 태엽 새 'Silver Lark'를 벨베데레 성(센트럴파크)에 숨기고, 단서를 4명의 '도시의 친구'(그랜드 센트럴 분실물센터, 차이나타운 찻집, 브루클린 브리지 벤치, 원더 휠 관리인)와 가족에게 맡김. 각 친구는 **질문 하나**를 함(시즌 규칙: 꼼꼼히 읽는 사람만 통과).
- **범인**: TV 보물사냥꾼 Dexter Vance (금요일 22시 도서관에서 마지막 장을 잘라감 → 놋쇠 새·뮤직박스 탈취, 팔려고 함). 7화에서 의심(별무늬 부츠·거짓말), **11화에서 증거로 체포**, 12화 해결.
- **레드 헤링**: 시계공 Otto Brandt — 6화에서 페리표·시간표·누나·민무늬 부츠로 알리바이 확인 후 조력자.
- **비밀 조력자**: 바이올리니스트 Rosa Diaz = Eleanor의 증손녀(8화 공개). 노래 뒷부분 D, A, D와 뮤직박스 보유.
- **6음 노래**: 앞 E, G, G(새 날개 = EGG, 6화) + 뒤 D, A, D(가족, 8화). 12화에서 egg → 앞 → 뒤 순서로 성의 벽을 엶.
- **장거리 단서**: EAST(2화 → 3화 다이얼, 9화 순서, 12화 동쪽 벽), 놋쇠 알(2화 → 6·8·12화), 페이지 조각의 3갈래 지그재그(1화 → 11화), 1926 신문의 약속(1화 → 11·12화) 등 cross-case 35건.
- **글자 모으기 파이널**: 12화 은빛 글자 7개 → FREEDOM (자유의 여신상 Liberty와 연결).
- **퍼즐 분포(48)**: text_choice 9, word_entry 8, letter_tile_lock 8, scene_explore_choose 6, picture_choice 6, order_sequence 5, witness_compare 4, combo_dial_lock 2. 모든 케이스에 그림 퍼즐 또는 손으로 조작하는 퍼즐 포함(6화는 텍스트+조작만).
- **장소 14**: exhibit_hall, library_steps, main_concourse, tea_house(외관), tea_room(내부), bridge_walkway, clock_shop, liberty_island, times_square, square_arch, coney_boardwalk, bethesda_terrace, tv_studio, belvedere_castle. 지어낸 곳: Hart Building(블리커 스트리트), 찻집, TV 스튜디오.
- **그림 스타일**: 시즌 전용 `newyork_scene`(구아슈+잉크, 1920년대 아르데코 여행 포스터 느낌) — 런던 엽서·파리 유화·로마 스케치북과 구분. 인물·사물은 공용 `character`/`object`.
- **공정한 선택지**: 오답 그림은 정답 그림을 참조(reference)해 단서가 말하는 한 가지만 다르게(깡통 뚜껑, 놋쇠 새, 신발 밑창, 관람차 칸, 돌새, 건물 지붕). 색만으로 구분하지 않음.
- **지도**: `art.map`은 지도를 만든 뒤 측정해서 추가(빈 landmarks는 스키마 오류이므로 지금은 미기재). 탐색(explore) 6곳의 좌표는 프롬프트 배치 기준 임시값이며 `UNMEASURED` 노트가 붙어 있음 → STEP 2에서 실제 그림 위에서 측정 → **2차 세션에서 측정 완료, 노트 교체됨.**

## 확인하지 않은 것

- 그림(아무것도 만들지 않음), 실제 좌표, 레벨(Junior/Master) 문장, `lib/` 생성 코드, 앱/기기 실행, `flutter test`(STEP 1은 Dart 플랜 검사만 실행).
- 승인(`approve.dart`)은 사용자 몫 — 실행하지 않음.

---

# STEP 2 진행 기록 (2026-10-30, 2차 세션)

## 그림 59장 — 완료

- `season_factory.dart run --budget 6.84`를 배치(4→8→8→9→10→10→12→1)로 반복. API 호출 **62회**(59장 + 재생성 3장), 지출 **$2.9858**(usage 기준, `planning/factory.json` spentUsd), 남은 예산 **$3.85**.
- 59장 모두 리뷰 시트를 Read로 열어 직접 확인 후 `reviewed`. 의심 장면은 원본 크기로 재확인(지도, Times Square 글자 여부, Coney Island 칸 위치, TV 스튜디오, 벨베데레, 칸 지붕, 알 고리 수, 찢긴 페이지 꼭짓점 수).
- `--apply` 완료: 59장 모두 `assets/seasons/season_04_newyork/`에 들어감(`status`: 59 in the game, 0 to make, 0 to review). `pubspec.yaml`에 에셋 경로 추가됨(미커밋).
- 거절 3건(원본은 `asset_work/s4_newyork/superseded/`에 보존, 프롬프트 수정 후 재생성·재검토 통과):
  1. `belvedere_castle` — 동쪽 벽 위에 큰 매(hawk) 석상 3개 → 놋쇠 판·선택지(종달새/부엉이)와 모순. 벽면에 작고 닳은 새 부조 3개(구분 불가)로 수정.
  2. `char_dexter_base` — 머리 위 선글라스 없음(2·7·11화 인물 설명·목격 단서). 선글라스를 머리 위에 명시.
  3. `car_dome` — 돔 지붕이 낮아 정답 칸(평평한 지붕)과 휴대폰에서 구분 어려움. 높은 반구형 돔으로 수정.
- 허용한 사소한 점: TV 스튜디오 창밖 간판의 아주 작은 무의미한 표식(읽히지 않음), Washington Square 장소 그림의 배경 콘트라베이스 연주자(정답 그림 아님).
- 배선(`asset_wiring.json`): wired 51, ready_to_wire 8(증거 사진 6장 `ArtAssets.evidencePictures` 등 — 코드 생성 단계에서 처리), blocked 0.

## 좌표 측정 — 완료 (exit 30 해소)

- 지도 `art.map`: 10곳 landmarks, `measuredOn` = `sha256:22742456…`(현재 파일과 일치). 모든 place의 locId 포함.
  central_park [800,150] · times_square [515,330] · new_york_public_library [715,385] · grand_central [985,390] · washington_square [720,545] · hart_building [470,540] · chinatown [660,760] · brooklyn_bridge [1185,580] · statue_of_liberty [140,760] · coney_island [1265,850]
- 탐색 6곳(ep01 m3 exhibit_hall, ep03 m1 tea_room, ep05 m2 clock_shop, ep07 m3 times_square, ep09 m2 coney_boardwalk, ep12 m1 belvedere_castle): 각 `areas`, `mark`, `guideAt`(첫 document 스팟 위), `opening`([20,20,1516,1004]), `picture.measuredOn`(현재 파일 sha256과 일치) 기록, `UNMEASURED` 노트를 측정 방법 노트로 교체.
- 검증: 스크립트로 sha 일치·경계 내·mark/guideAt 위치·opening 포함·영역 겹침 0건 확인. 영역을 그림 위에 그려(overlay) 눈으로 7장 모두 실제 물체 위치와 일치 확인. 확인 불가로 남긴 위치 없음.
- 측정 중 발견·수정: tea_room의 lantern과 card 겹침 → lantern을 본체+술 2개 영역으로 나눔.
- 표지 프레이밍 `art.cover`: archiveLook [0,-0.15], crop [0,0], push [0,-0.2] (도시의 탑들을 향함; 난간·새는 전경).

## 레벨 문장 (exit 35) — 미완료

- `season.levels.json`(outro/finale 4줄): Junior·Master **작성 완료**.
- `cases/s4_ep01…12/levels.json`: 스켈레톤만 있음(팩토리가 생성). **1,676줄 × Junior/Master 모두 빈 칸, glossary 비어 있음.** 서브에이전트 4개(3케이스씩)를 시작했으나 사용자 지시로 저장 전에 중단 — 저장된 내용 없음, 파일 손상 없음(13개 JSON 모두 정상).
  줄 수: ep01 183 · ep02 152 · ep03 143 · ep04 117 · ep05 134 · ep06 111 · ep07 172 · ep08 120 · ep09 134 · ep10 112 · ep11 157 · ep12 141.
- `plan_season.dart format` 정상. `plan_season.dart check`: **3,352 ERROR = 전부 `level_missing`**(1,676줄 × 2레벨). 좌표·지도·탐색 관련 ERROR 0건. WARNING 55(STEP 1과 동일).
- 주의: `season_factory.dart status`의 "levels every case at Rookie, Junior and Master" 줄은 파일 존재만 보는 표시로 보임 — 실제로는 미작성. `plans 3352 ERROR`가 실제 상태.

## 다음 세션 재개 순서

1. 각 `cases/<id>/levels.json`의 빈 `junior`/`master`와 `glossary` 작성(create-season § Levels; 케이스 3개씩 서브에이전트 가능). rookie 줄·플랜은 건드리지 않음.
2. `dart run tool/season_gen/case_levels.dart check --season content_pipeline/seasons/s4_newyork/season.plan.json` → 모든 케이스 `ok`.
3. `dart run tool/season_gen/case_levels.dart review content_pipeline/seasons/s4_newyork/season.plan.json` 읽고 의미 검토.
4. `dart run tool/season_factory/season_factory.dart run content_pipeline/seasons/s4_newyork --budget 6.84` → 코드 생성(exit 50/60 처리) → exit 0.
5. 전체 `flutter test`, `asset_pipeline.dart --manifest content_pipeline/seasons/s4_newyork/assets.manifest.json --doctor`, `content_pipeline/asset_work/s4_newyork/` 백업(`~/world_mystery_backups/`) 및 sha256 비교, `planning/FACTORY_REPORT.md`.

## 이번 세션에서 하지 않은 것

- 레벨 문장(케이스), 코드 생성(`lib/` 변경 없음), `flutter analyze`/`flutter test`, `--doctor`, asset_work 백업, 실기기 확인. 승인(`approve.dart`) 실행 안 함. Commit/Push 안 함.

---

# 3차 세션 기록 (2026-10-30) — 레벨 문장 일부 완료 후 중단

서브에이전트 4개(3케이스씩)로 Junior/Master 작성. 사용량 한도 때문에 사용자 지시로 마무리: 끝난 케이스만 저장하고 중단.

## 완료된 Case (8) — `case_levels.dart check` ok

| Case | 줄 | glossary J/M |
|---|---|---|
| s4_ep01 | 183 | 12 / 15 |
| s4_ep04 | 117 | 15 / 17 |
| s4_ep05 | 134 | 15 / 16 |
| s4_ep06 | 111 | 14 / 17 |
| s4_ep07 | 172 | 12 / 16 |
| s4_ep10 | 112 | 12 / 15 |
| s4_ep11 | 157 | 12 / 16 |
| s4_ep12 | 141 | 13 / 16 |

`season.levels.json`(outro/finale) 2차 세션에 작성됨, check ok.

## 미완료 Case (4) — junior/master/glossary 전부 빈 칸(스켈레톤 그대로)

s4_ep02(152줄) · s4_ep03(143줄) · s4_ep08(120줄) · s4_ep09(134줄) → 549줄 × 2 = **1,098 level_missing**.

## 이번 세션 검증 결과

- 레벨 JSON 13개 모두 파싱 정상. 12케이스 rookie 줄이 작업 전 스냅샷과 순서·내용·개수 모두 동일(변경 없음).
- `case_levels.dart check --season …`: 위 8케이스 ok, 4케이스 FAILED — 오류는 전부 `level_missing` 1,098건(다른 종류의 오류 없음).
- `season_factory.dart status`: plans 1098 ERROR / 55 WARNING, pictures 59 in the game · 0 to make · 0 to review, budget $2.9858 spent(6.84 중), measured everything, game "not in the game yet".
  (status의 "levels every case at Rookie, Junior and Master"는 파일 존재만 보는 표시 — 실제는 위 미완료 4케이스.)

## 의미 검토(`review`) 미실행 — 다음 세션에서 꼭 볼 줄

모든 완료 케이스가 `check`(단어 보존)만 통과했고 `case_levels.dart review`는 사용량 절약으로 실행하지 않음. 서브에이전트가 남긴 확인 필요 항목:
- ep01: 파이널 순서 선택지(155–159줄) 변화가 작음; Master 연필 탁본 편지(119줄) "Gaze up, and you will see that its stars are painted backwards."
- ep05 line 13 junior "He wants to sell it for money." — 오답 선택지인데 다른 선택지보다 약간 김.
- ep06 line 54 master "Otto has proof he was elsewhere, in another place." — 중복 표현.
- ep07 line 147 master "What for?"(Rookie "Why?").
- ep10 m3 SONG 피드백: Rookie가 "Read the third line"이라고 하나 페이지에서는 2번째 줄("The girl's box: the end of the song. Got it today!")일 수 있음 → **플랜 자체 오류 가능성**, J/M은 Rookie와 같게 둠. 플랜 확인 필요(플랜 변경 시 사용자 판단).
- ep10 caseSummary junior "he doesn't know the castle" 어색한 표현 승계.
- ep11 Frank: Junior "flashlight", Master "torch" 혼용.

## 남은 작업 (다음 세션 재개 순서)

1. s4_ep02, s4_ep03, s4_ep08, s4_ep09의 `levels.json` junior/master/glossary 작성(rookie·플랜 불변). 서브에이전트 지시문: scratchpad의 `levels_brief.md` 내용 = create-season § Levels 규칙.
2. `dart run tool/season_gen/case_levels.dart check --season content_pipeline/seasons/s4_newyork/season.plan.json` → 12케이스 모두 ok.
3. `dart run tool/season_gen/case_levels.dart review content_pipeline/seasons/s4_newyork/season.plan.json` 전 케이스 의미 검토(위 목록 포함), ep10 "third line" 확인.
4. `season_factory.dart run content_pipeline/seasons/s4_newyork --budget 6.84` → 코드 생성·시즌 등록(exit 50/60 처리) → exit 0.
5. 전체 `flutter test`, `asset_pipeline.dart --manifest … --doctor`, `content_pipeline/asset_work/s4_newyork/` 백업(`~/world_mystery_backups/`) + sha256 비교, `planning/FACTORY_REPORT.md`, 최종 보고.

## 이번 세션에서 하지 않은 것

Flutter 코드 생성(`lib/` 변경 없음), 시즌 등록, `flutter analyze`/`flutter test`, 이미지 생성·수정(API 호출 0, 지출 추가 없음), 좌표 수정, `--doctor`, 백업, `approve.dart`, Commit/Push.

---

# 4차 세션 기록 (2026-10-30) — 완료

- ep02·03·08·09 레벨 작성(check ok), 12케이스 전체 check ok, 전체 review(수정: ep07 m1 Master clue, ep12 m3 Master hint).
- ep10 "Read the third line": 오답 SONG 피드백이 정답 줄(셋째 줄 "The last place: ???")을 가리킴 → 오류 아님, 수정 없음.
- 플랜 Rookie 문제 6건 최소 수정(ep04 m3/final, ep08 final, ep10 m1, ep11 final, palace 기호) — FACTORY_REPORT 표 참고.
- 코드 생성·등록, 테스트 픽스처 갱신(시즌 4개), 전체 flutter test +3328/-2(기존 season_planner_test 실패 2건만), --doctor 59 all as recorded, asset_work 백업 sha256 일치.
- 남은 것: 실기기 확인, approve.dart(사용자), 기존 season_planner_test 2건, Commit/Push(사용자 지시 대기).
