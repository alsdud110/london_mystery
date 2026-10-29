# STEP 3-14 — Rome 시즌 12 Case 재설계 기록

**작성:** 2026-10-30 · **범위:** `content_pipeline/seasons/s3_rome/` 기획 데이터만. 엔진·Generator·앱 코드는 바꾸지 않았다. OpenAI 호출 0회, 신규 이미지 0장.

이 문서는 Claude가 Season Planner 지침(`tool/season_planner/PLAYBOOK.md`)으로 시즌을 스스로 개선할 때 **무엇을 왜 골랐는지**, 그리고 **사람·다음 단계가 이어받아야 할 일**을 남긴다.

---

## 1. 문서와 코드의 차이 (코드 기준으로 판단)

| 항목 | 요청서/문서 | 실제 코드 |
|---|---|---|
| Planner 명령 | `check --season <dir>` | `plan_season.dart check <seasonDir>` (위치 인자). `assets <seasonDir>`도 같다 |
| 게임 방식 ID | `SceneExplore`, `InvestigationSearch` … | 위젯 이름. Plan은 `paletteId`(`scene_explore_choose`, `dark_room_search`, `witness_compare`, `picture_choice`)와 `engineTable`로 고른다 |
| 숨은 단서 찾기(Search) | GAMEPLAY_CATALOG: 생성 **지원** | Generator는 지원하지만, 찾은 물건을 장면 위에 겹쳐 그리므로 **투명 컷아웃 PNG**가 필요하다. `asset_pipeline`은 gpt-image-2의 투명 배경을 `transparent_unsupported` **오류로 전체 실행 거부**한다 → 새 시즌에서는 그림을 만들 수 없다 |
| 텍스트 퍼즐 + 대화 초상화 | PLAYBOOK: "portrait는 manifest에 계획되면 쓴다" | 텍스트 퍼즐은 `status: ready` + 빈 `assetNeeds`여야 Generator가 만든다(`awaitingAssets`면 `generate_unsupported` ERROR). 그런데 Manifest 검사는 초상화를 `assetNeeds`에 요구한다(`asset_need_missing` WARNING). 두 규칙을 동시에 만족할 수 없다 |
| 배선 보고(`asset_wiring.json`) | README: 초상화 10장 `not_supported` | STEP 3-13/3-13B 이후 Generator는 증인·대화·엔딩 초상화를 쓴다. `AssetWiring`은 `use`를 읽지 않고 `type`만 보므로 퍼즐 그림 37장을 잘못 분류한다 |
| STEP 3-12B 이미지 3장 | "생성됨" | `content_pipeline/asset_work/s3_rome/raw/`에 있고 `pipeline_state.json`에서 `validated`. Manifest `status`는 설계대로 `planned`(assets/ 복사는 STEP 3-12C) |

## 2. 시즌 스토리 — 바꾼 것과 바꾸지 않은 것

**바꾸지 않음:** 중심 미스터리, 범인(Bruno Valli), 동기, 방법, 등장인물 8명, 장소 11곳·18장면, 타임라인, 3막 구조, Case 제목 12개, 결말.

**바꾼 것과 이유**

| 위치 | 변경 | 이유 |
|---|---|---|
| Case 01 M1 | 야간 기록 객관식 → **증인 3명 대화**(Enzo·Sofia·Livia) | 시즌 첫 미션에서 인물을 직접 만나게 하고, Sofia의 "전원은 꺼지지 않았다"가 Final(스위치를 손으로 내림)의 근거가 된다. Livia의 "그때 랩에서 늦게까지 일했다"는 Case 08에서 회수되는 첫 번째 실수 |
| Case 01 Final | 4·3·2 → **4·2·2** | 두 번째 숫자를 "All quiet" 세기에서 "불이 꺼진 걸 본 사람 수"로: 대화에서 얻은 단서를 쓰게 함 |
| Case 06 | M1 편지가 정답("무거운 것을 못 든다")을 말하던 문장 삭제 | 텍스트를 읽으면 정답이 그대로 나오던 문제. 이제 Pia의 진술과 Giulia 메모를 비교해야 한다 |
| Case 06 | 목요일 밤(Pia 진술: 큰 남자)과 금요일 자정(Hall B 기록) **두 밤 모두** 대사로 명시 | Case 05에서 진짜 조각이 목요일에 바뀌었음을 이미 알기 때문에, 금요일 알리바이만으로는 혐의가 풀리지 않던 논리 구멍 |
| Case 08 M1 | 숫자 세기(EIGHT) → **로마의 실제 다리 3개 중 고르기** | 'four faces, two posts'를 그림으로 확인하는 관찰 퍼즐 |
| Case 08 M2 | Livia가 Case 01의 자기 진술을 인정 | Owl 정체가 갑작스럽지 않게: 플레이어가 1화에서 들은 말이 증거 |
| Case 11 M1 | Stone B "석고 4kg" → **줄무늬만 있고 부엉이·균열 없는 대리석** | 석고 사본은 이미 탐정이 가지고 있으므로 두 번째 사본은 모순. 이제 셋 다 대리석 12kg이라 Aldo 사진(회수)으로만 구분된다 |
| Case 11 M2 | Pia의 가게 → **Valli 사무실에서 3자 대화** | Valli·Pia·Sofia가 한자리에서 말해야 진술 비교가 성립 |
| Case 12 | 금 타일 발견 순서 H I / S T / O R Y → **Y T / H O / S I R**, 타일 줄도 섞음 | Final 편지가 정답 HISTORY를 그대로 나열하던 문제 |
| Case 10 M1 | 공사 일정 순서 맞추기 → **현장 규칙 + 헬멧 3개 중 고르기** | 콘크리트 날짜는 Case 09 Final(도시 계획)과 중복. 헬멧 선택은 Pia의 '노란 헬멧+크레인'을 색과 그림 둘 다로 확인하게 한다 |

## 3. 48개 Mission·Final 재평가

`=`: 방식 유지(대화·Discovery·엔딩만 추가) · `→`: 방식 변경 · 좌표: 탐색 장면의 영역이 실제 그림에서 측정되었는지

| Case | M1 | M2 | M3 | Final |
|---|---|---|---|---|
| 01 | → 증인 대화 (guard_room) | = 순서 | → 현장 탐색+그림 선택 (map_hall, **좌표 미측정**) | = 다이얼 (답 422로 변경) |
| 02 | = 단어 | = 객관식 | = 글자 타일 | = 순서 |
| 03 | = 순서 | = 객관식(recall) | = 단어 | = 다이얼 |
| 04 | → 현장 탐색+바닥 돌 4개 (pantheon_hall, **좌표 미측정**) | = 단어 | = 순서 | = 글자 타일 |
| 05 | → 현장 탐색+고양이 3마리 (cat_ruins, **좌표 미측정**) | = 글자 타일 | = 순서 | = 다이얼 |
| 06 | = 객관식(편지 수정) | = 순서 | = 단어 | = 글자 타일 |
| 07 | = 순서 | = 단어 | = 객관식(recall) | = 다이얼 |
| 08 | → 그림 선택: 다리 3개 | = 객관식(recall) | = 순서 | = 글자 타일 |
| 09 | → 그림 선택: 방 3개(recall) | = 순서 | = 단어 | = 다이얼 |
| 10 | → 현장 탐색+헬멧 3개 (civetta_square, **좌표 미측정**) | = 글자 타일 | = 객관식 | = 단어 |
| 11 | → 그림 선택: 돌 3개(recall) | → 증인 대화 (site_office) | = 순서 | = 글자 타일 |
| 12 | = 순서 | = 객관식(recall) | = 단어 | = 글자 타일(타일 순서 수정) |

**방식별 분포(48):** 순서 11 · 단어 8 · 글자 타일 8 · 객관식 7 · 다이얼 5 · 현장 탐색 4 · 그림 선택 3 · 증인 대화 2. 한 방식 최대 23%(기준: 약 1/3 이하). 그림 기반 9개, 그림 미션이 있는 Case 7/12. 각 막의 방식 수: 1막 7 · 2막 7 · 3막 8(후반 다양성 하락 없음). 모든 Case가 4가지 서로 다른 방식이고 손으로 조작하는 퍼즐을 하나 이상 가진다.

**방식 선택 이유(Claude 판단)**

| 미션 | 고른 방식 | 왜 이 장면에 맞나 | 버린 대안 |
|---|---|---|---|
| 01 M1 | 증인 대화 | 세 사람이 같은 밤을 다르게 말한다: 두 진술의 일치가 단서 | 야간 기록 객관식(읽으면 끝) |
| 01 M3 | 현장 탐색 | 먼지 자국 끝(뒷문)에서 카드를 직접 찾고, 방문객 지도 그림에서 '동전을 던지는 곳'을 고른다 | 단어 입력 TREVI(지도 글을 베끼면 끝) |
| 04 M1 | 현장 탐색 | 판테온의 '눈'과 빛의 원을 둘러보고, 시각 표를 계산해 바닥 돌을 고른다 | 객관식 유지 |
| 05 M1 | 현장 탐색 | 고양이 유적지를 둘러보는 행동 자체가 장면. 주황색 고양이 2마리라 '짧은 꼬리'와 '석고 공방' 두 단서를 다 읽어야 한다 | 그림 선택만(둘러보기 없이), 이름 객관식 |
| 08 M1 | 그림 선택 | 실제 로마 다리 세 개(천사·둥근 구멍·네 얼굴 기둥)를 묘사로 구분 | 숫자 세기 EIGHT |
| 09 M1 | 그림 선택 | BIBLIO→도서관→두루마리 구멍이 있는 방, 2단계 추론. 정답 그림은 Case 12의 실제 도서관 장면(복선) | 객관식 유지 |
| 10 M1 | 현장 탐색 | 공사장 울타리 앞에서 규칙을 읽고 고리에 걸린 헬멧을 고른다. 오답 헬멧이 각각 색 또는 그림 하나만 맞아 둘 다 읽어야 한다 | 일정 순서(Case 09와 중복) |
| 11 M1 | 그림 선택 | 세 돌 모두 대리석 12kg: 글로는 구분 불가, Aldo 사진(Case 06 증거)을 꺼내 비교해야만 풀린다 | 객관식(노트에 답이 적혀 있었음) |
| 11 M2 | 증인 대화 | Valli의 거짓말을 두 사람의 일치하는 진술로 깨뜨린다 | 단어 입력 SUNDAY |

**쓰지 않은 방식:** `dark_room_search`(투명 컷아웃 불가, §1). 2막 Case 06·07에도 대화 후보가 있었지만, 대화 엔진은 증인 3명이 모두 시즌 인물(초상화)이어야 해서 장면이 억지스러워 넣지 않았다.

## 4. 스토리 연출 적용

- 미션 전후 대화 18개(전 11 · 후 10), 모두 그 Case의 인물이 말하고 초상화를 지정. 대사는 3~12단어.
- Discovery 36개(미션 전부): deduction 17 · clueFound 11 · newLead 5 · evidenceFound 2 · storyDiscovery 1. 제목이 성공 문구와 같거나 시즌 안에서 겹치는 것 없음.
- Final 엔딩 12개(63줄): 각 Final이 사건을 푼 이유(핵심 증거를 `evidence`로 띄움)와 다음 Case로 이어지는 마지막 한 줄. 엔딩과 겹치던 transition 문장은 다시 썼다.

## 5. 단서·증거

- 다른 Case의 단서 입력 54건(이전 52), 그중 두 Case 이상 떨어진 것 25건. Story Bible 단서 줄기 23개(전부 실제 clueInputs와 연결, Planner가 검사).
- 새로 생긴 장거리 연결: Case 01 Livia의 진술 → Case 08 M2 · Case 07 대출 장부 상자 → Case 08 M1(다리 카드) · Case 09 Aldo 라틴어 카드 → Case 12 M2 · Case 09 도시 계획 → Case 12 M1.
- 발견 전 사용 없음, Final 근거 모두 해당 Case 또는 이전 Case에서 확보(Planner `clue_used_before_discovery` 0건).
- `clue_never_used` WARNING 27건: 수첩에만 남는 증거(기존과 같은 수, PLAYBOOK상 정상).

## 6. 이미지 계획

| 분류 | 수 | 추정(gpt-image-2 medium) |
|---|---|---|
| 이미 생성(보존, 재생성 안 함): forum_view, livia_base, livia_hood | 3 | (지출 완료) |
| **플레이에 필요 — 장소 그림** | 17 | $0.82 |
| **플레이에 필요 — 초상화**(증인·대화·엔딩) | 8 | $0.45 |
| **플레이에 필요 — 퍼즐 그림**(신규 16 + 증거 그림 재사용 2) | 18 | $1.17 |
| 참조용으로 먼저 필요: ev_business_card(헬멧 크레인 로고) | 1 | $0.03 |
| 연결 작업 필요(lib/ 한 줄): 커버, 도시 지도 | 2 | $0.10 |
| 연결 작업 필요(lib/ 또는 Generator 테이블): 증거 그림 11, 부엉이 정체 장면 1 | 12 | $0.72 |
| 현재 화면이 없음(생성 보류): prologue, ev_gold_tiles | 2 | $0.08 |
| **합계** | **63** | 전체 $3.59 / 남은 것 $3.38 |

- 신규 16장: colosseum · 바닥 돌 4(ship·lion·book·key) · 고양이 3(tito·rosso·luna) · 다리 2(angels·hole) · 방 2(bath·theatre) · 헬멧 2(white_crane·yellow_plain) · 돌 2(stone_lion·stone_street).
- 재사용: 선택지에 장소 그림 4장(trevi_fountain, pantheon_hall, tiber_bridge, roman_library)과 증거 그림 2장(ev_real_piece, ev_yellow_helmet)을 그대로 쓴다. 증인 대화의 배경은 각 장소 그림.
- 일관성: 바닥 돌 3장은 ship을, 헬멧 2장은 ev_yellow_helmet을, 돌 2장은 ev_real_piece를 참조(images/edits)해 그린다.
- 장소 프롬프트 7개를 수정(map_hall, pantheon_hall, cat_ruins, civetta_square는 탐색 배치, trevi_fountain은 동전 던지는 소녀, tiber_bridge는 다리 위 인물 제거, site_office는 대리석 돌 셋). 생성된 3장의 프롬프트·크기·스타일·참조는 그대로(스크립트로 확인).

## 7. 좌표 — 미측정 (STEP 3-15에서 확정)

| 미션 | 그림 | 상태 |
|---|---|---|
| Case 01 M3 | map_hall | 프롬프트 배치 기준 **임시값**. 측정 전 생성 금지 |
| Case 04 M1 | pantheon_hall | 〃 |
| Case 05 M1 | cat_ruins | 〃 |
| Case 10 M1 | civetta_square | 〃 |

각 미션 `puzzle.notes`에 `COORDINATES UNMEASURED (STEP 3-14)`로 표시했다. 그림이 디스크에 없으므로 Generator는 지금 이 미션을 만들지 않는다(`asset_file_missing`). 그림 생성 후: 파일 크기 확인 → spots·others·guideAt·opening 측정 → plan 수정 → notes의 표시 삭제 → `check` → `generate`.

## 8. 플레이 가능 상태

이미지 파일이 하나도 `assets/`에 없으므로 **완료(플레이 가능)로 표시한 미션은 없다.** 기획 검사는 모두 통과했고 Generator는 그림 110건만 기다린다(`generator_waits_for_pictures`: 장소 18 + 퍼즐·초상화 92 참조).

| 상태 | 미션 |
|---|---|
| 기획 완료, 장소 그림만 필요 | 텍스트 퍼즐 39개(그중 대화·엔딩이 있는 미션은 초상화도 필요) |
| 기획 완료, 퍼즐 그림 필요 | 그림 선택 3, 증인 대화 2 |
| 퍼즐 그림 + 좌표 측정 필요 | 현장 탐색 4 |

## 9. 자동화 격차 (다음 단계 작업 목록)

1. **대화·엔딩 초상화와 assetNeeds 규칙 충돌** — 텍스트 퍼즐은 `ready`+빈 assetNeeds여야 하는데 Manifest 검사는 초상화를 요구 → `asset_need_missing` WARNING 55건(전부 이 원인). 제안: `asset_manifest.dart`가 `talk.portrait`/`ending[].portrait`를 퍼즐 그림이 아닌 "이야기 그림"으로 따로 검사.
2. **`AssetWiring`이 `use: puzzle`을 모름** — 퍼즐 그림·초상화 37장이 `ready_to_wire`/`not_supported`로 잘못 보고됨. 제안: `use: puzzle`이면 `PlayCheck.pictureFiles`로 미션을 찾아 `wired`.
3. **좌표 측정 여부를 표시할 필드가 없음** — 지금은 notes 문구뿐이라, 그림이 생기면 미측정 좌표로도 생성된다. 제안: 장면에 `measuredOn: <sha256>` 같은 필드와 PlayCheck 검사.
4. **Search 엔진의 투명 컷아웃** — gpt-image-2로 만들 수 없음. 배경 제거 단계 또는 투명 지원 모델이 필요.
5. **증인 초상화 `face` 좌표** — 선택 필드라 비워 둠. 초상화 생성 후 얼굴 위치를 재면 대화 화면 구도가 London과 같아진다.
6. **탐색·대화 엔진 위의 `recall`** — 엔진과 무관하게 하단에 붙지만 검증된 적이 없어 이번엔 탐색 미션에서 쓰지 않았다(Case 05 M1).
7. **선택지 그림과 장소 그림의 일치** — 고양이(cat_ruins·Carla 초상화의 Tito), 헬멧(civetta_square의 고리), 바닥 돌(pantheon_hall의 줄)은 참조로 묶이지 않아 사람이 눈으로 확인해야 한다.
8. **지도 핀(mapX/mapY)** — 도시 지도가 그려진 뒤 측정(기존 격차).

## 10. 검증

- `plan_season.dart check content_pipeline/seasons/s3_rome`: **0 ERROR · 83 WARNING · 124 INFO** (WARNING = asset_need_missing 55 + clue_never_used 27, 둘 다 위 설명. INFO = image_pending 110 등).
- `plan_season.dart assets`: 63장 계획, 오류 없음. `asset_pipeline.dart` 드라이런: 호출 0, 쓰기 0, validated 3 유지.
- Generator(메모리): 그림 대기 외 실패 0.
