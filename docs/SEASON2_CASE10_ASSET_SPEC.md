# Season 2 · Case 10 — The Hour of Shadows
## 확정 이미지 에셋 명세서 (v1.1 · 2026-10-24 · 사용자 승인)

**기획 기준:** `docs/SEASON2_PARIS_STORY_BIBLE.md` v1.9 §6 Case 10 확정 명세, `docs/SEASON2_CASE10_SPEC.md` v1.1
**상태:** 6장 납품(커밋 `b53ec14`), 검수 승인(2026-10-24). **재생성하지 않는다.** 아래 §4 납품본 기준이 §2의 제작 요청 내용보다 우선한다.
**v1.1 (2026-10-24):** 실제 해상도 반영(`record_drum.png`·`sundial_top.png` 1254×1254), `case_07/photo_frame.png` 재사용 취소(사진 테두리 내장), 명판 텍스트 오버레이, 성당 시계 검수 기준, 해시계 시각선 7개(1:00–4:00) + 맨 아래 세로선 제외, §4 납품 검수 결과 추가.
**저장 폴더:** `assets/seasons/season_02_paris/cases/case_10/`
**원칙**
- 이미지는 사용자가 제작한다. Claude Code는 임시 이미지·도형·AI 이미지를 넣지 않는다.
- 장식 그림과 조작 요소를 분리한다. 시계 바늘, 해시계 그림자, 숫자, 글자, 테이프, 기록부 쪽 내용, EMBLEM은 **코드로 겹친다**. 런타임에 픽셀을 측정하지 않고, 납품 후 좌표를 측정해 scene 데이터에 기록한다.
- 투명 에셋은 **실제 알파 채널 PNG**(바깥 알파 0)로 받는다. 체크무늬를 그려 넣은 가짜 투명은 받지 않는다.
- 화풍: Vintage Detective Storybook. 회화 장면은 `case_08/corner_2.png`, 황동 물건은 `case_03/time_recording_machine_open.png`(재질만 참고하고 실루엣은 따라 하지 않음), 종이는 `case_07/amendment_slip_blank.png` 기준.

---

## 0. 요약

### 0.1 재사용 (신규 제작 없음)
| 파일 / 코드 | 용도 |
|---|---|
| `case_09/clock_model_t1.png` | Intro 2–4줄: T1 받침 별 회수 |
| `locations/map/paris_mystery.png` | M2 `Trial Map` 칩, Case Closed Next Lead(Luxembourg Gardens 북쪽 끝 + `Saint-Sulpice` 라벨) |
| `case_09/clock_dial.png` | M2 분류 카드의 시계판, Final 사진 핀 카드 |
| `InkGlyph.gear` (코드) | 테이프 머리글·Trial Log의 `CHRONOS TRIAL` EMBLEM(톱니 8개) |
| **`InkGlyph.sun` (코드, 신규 아이콘)** | M3 해 토큰. **이미지 없음.** 기존 InkIcon 잉크 선 스타일: 원 + 짧고 둥근 빛살 12개, 얼굴 없음, Antique Gold. 별(뾰족한 끝 12개)과 구별 |
| `ClockQuestion` 바늘 그리기 (코드) | 사진 속 시계 4개의 바늘(Photo 1: 모두 2:00 / Photo 2: T1 2:30, 나머지 3:30) |
| Flutter 텍스트 오버레이 (코드) | `star_room.png` 벽 황동 명판 위 `TRIAL RECORDS` / `KEPT AT THE STAR` (디자인 시스템 제목 폰트 IM Fell English SC — 프로젝트에 Cinzel 없음, 새긴 느낌의 짙은 잉크색, 명판 폭 80% 안 자동 축소) |
| 기존 `Paper` 카드 (코드) | 드럼 테이프 띠·눈금(가장자리 구멍 점은 `star_room.png`의 테이프와 같은 모양), Trial Log 목차·쪽, RECORD LIST |

**쓰지 않는 것:** `case_07/photo_frame.png`. `roof_photo.png`에 낡은 사진 테두리가 이미 그려져 있으므로 액자나 코드 테두리를 덧씌우지 않는다(이중 테두리 금지).
| 기존 온보딩 손가락 애니메이션 | M1 테이프 끌기, M3 해 끌기 첫 안내 |

### 0.2 신규 — 6장
| # | 파일 | 용도 | 크기 | 비율 | 배경 | 필수 |
|---|---|---|---|---|---|---|
| 1 | `arc_star_view.png` | Intro 1–4, Case Closed 배경 | 1536×1024 | 3:2 | 불투명 | 필수 |
| 2 | `star_room.png` | Intro 5–8, M1·M2·Final 배경 | 1536×1024 | 3:2 | 불투명 | 필수 |
| 3 | `record_drum.png` | M1·Final 테이프가 나오는 드럼 | 1254×1254 | 1:1 | 투명 | 필수 |
| 4 | `roof_photo.png` | M2 Photo 2, M3 Photo 1·2 크롭, Final 사진 핀 | 1536×1024 | 3:2 | 불투명 | 필수 |
| 5 | `sundial_top.png` | M3 오늘의 해시계 | 1254×1254 | 1:1 | 투명 | 필수 |
| 6 | `trial_log_open.png` | Final 2단계, Case Closed RECORD LIST | 1536×1024 | 3:2 | 투명 | 필수 |

- **사진은 1장(#4)으로 Photo 1·2를 함께 쓴다.** 같은 자리에서 찍었다는 설정이다. 바늘·그림자·라벨 `PHOTO 1/2`가 코드라서 그림자 각도와 길이를 데이터로 정확히 보장할 수 있다.
- **해 토큰은 이미지로 만들지 않는다**(사용자 결정, 2026-10-24).

---

## 1. 생성 순서
1. `arc_star_view.png` (`clock_model_t1.png`를 실루엣 참고 이미지로)
2. `star_room.png` → `record_drum.png` (#2의 드럼을 참고 이미지로)
3. `roof_photo.png` (`clock_model_t1.png`의 별 모양 참고)
4. `sundial_top.png` (#4의 해시계와 같은 판 모양)
5. `trial_log_open.png`

---

## 2. 이미지별 명세

### #1 `arc_star_view.png` — 개선문 도착
- **배치:** 화면 전체(cover). 아치가 가운데 60% 안에 있어 360×640 크롭에서도 아치 전체가 보인다
- **내용:** 늦은 오후의 개선문 정면, 약간 낮은 시점. 둥근 광장에서 넓은 길이 별처럼 뻗어 나감. 길고 부드러운 그림자(Case 제목 회수). 따뜻한 빛
- **반드시:** 단일 큰 아치(T1 모형과 같은 실루엣), 방사형 도로, 긴 그림자
- **제외:** 초점 맞은 사람·차량, 국기, 글자, 시계, 기념물 조각 클로즈업
- **프롬프트:**
  > Impressionist oil painting with thick, visible brushstrokes, late afternoon golden light. The Arc de Triomphe seen from the front at a slightly low angle, standing alone at the centre of a wide round plaza, wide avenues radiating outward from it like the rays of a star. Long soft shadows stretch across the paving. Warm sky with light clouds. No people in focus, no cars in focus, no flags, no text, no clocks. Vintage storybook atmosphere, restrained palette of cream stone, slate blue and soft gold. The arch sits within the central 60% of the frame. 3:2 landscape.

### #2 `star_room.png` — 별의 방
- **배치:** 화면 전체(cover). Intro 5줄의 강조 대상 세 물건(드럼·사진 상자·책)의 좌표를 측정한다
- **내용(제작 요청 당시):** 지붕 아래 작은 석조 방(가상). 작은 아치 창으로 오후 빛. 낡은 나무 탁자 위에 황동 기록 드럼(종이 테이프 끝이 조금 말려 나옴), 나무 사진 상자, 닫힌 두꺼운 장부(짙은 초록 천 표지). 벽에 빈 황동 카드 꽂이. 문 위 안쪽에 **새긴 별**(끝 12개 + 가운데 작은 원)
- **납품본 기준(확정):** 별은 **문짝**에 있고, 벽에는 **빈 황동 명판**이 있다. 명판 위에 `TRIAL RECORDS` / `KEPT AT THE STAR`를 Flutter 텍스트로 오버레이한다(§0.1). 이미지는 수정하지 않는다.
- **반드시:** 별 모양이 T1 받침 별과 같음. 세 물건이 한눈에 구별됨. 드럼은 #3과 같은 모양
- **제외:** 사람, 가방, 글자, 숫자, 시계 바늘, 톱니 8개 문양(코드), 방패·월계관·보라색 도장, Case 03 시간 기록 장치처럼 보이는 큰 상자형 기계
- **프롬프트:**
  > Painterly vintage storybook interior: a small stone room under a monument's roof, one small arched window letting in warm afternoon light. On a worn wooden table: an antique brass recording drum (a horizontal brass cylinder on a small wooden base) with a narrow paper tape curling out of it, a wooden box of old photographs, and a thick closed ledger with a dark green cloth cover. An empty brass card holder on the wall. Above the inside of the door, a carved star with twelve thin rays and a small circle in the middle. Dust in the light, calm and mysterious. No people, no bags, no text, no numbers, no clock hands. 3:2 landscape.

### #3 `record_drum.png` — 기록 드럼
- **배치:** M1·Final 테이프 단의 왼쪽(단 높이의 약 90%). 테이프 띠는 코드로 슬롯에서 오른쪽으로 뻗는다
- **내용:** 앞에서 약간 위로 본 가로 황동 원통. 작은 나무 받침. 오른쪽에 테이프가 나오는 **빈 슬롯**. 앞면에 **빈 둥근 명판**(EMBLEM은 코드)
- **측정할 것:** 테이프 슬롯의 시작점과 높이, 명판 원의 중심과 반지름
- **제외:** 종이 테이프, 글자, 숫자, 톱니 문양, 시계판, 상자형 실루엣(Case 03 장치와 구별)
- **프롬프트:**
  > An antique brass recording drum seen from the front and slightly above: a horizontal brass cylinder resting on a small wooden base, a narrow empty slot on its right side where a paper tape would come out, and a small blank round plate on the front of the base. Warm soft light, gentle reflections, slightly aged. No paper tape, no clock face, no text, no numbers, no symbols. Isolated on a transparent background. Square.

### #4 `roof_photo.png` — 지붕 사진 (Photo 1·2 공용)
- **배치:** M2 위 65%(줌 가능), M3 사진 카드(해시계·T1 부분 크롭), Final 핀 카드(작은 썸네일)
- **내용:** 빛바랜 흑백(약한 세피아) 사진. 개선문 지붕 위에서 찍음
  - 앞 왼쪽: 짧은 철 기둥 위 **T1 시계**(흰 판, 숫자·바늘 없음). 기둥의 작은 판에 **별**(끝 12개 + 원)
  - 앞 오른쪽: 낮은 돌 받침 위 **해시계**(약간 위에서 본 평평한 둥근 판. 희미한 시각선만 있고 숫자는 지워짐. **그림자 없음**, 그노몬은 있음)
  - 뒤: 지붕들과 방사형 대로. 시계 3개: ① 길모퉁이 카페 벽의 브래킷 시계 ② 멀리 성당 탑 시계 ③ 큰 문 위의 둥근 시계. 모두 흰 판, 바늘·숫자 없음, **각각 화면 폭의 6% 이상**
- **측정할 것:** 시계 4개의 중심·반지름(바늘용), 돋보기 판정 영역 4곳(최소 48pt), 해시계 판 타원(중심, 장축·단축, 기울기)과 그노몬 밑점(그림자 변환용), M3 크롭 영역
- **제외:** 사람, 글자(간판 `POSTE` 등 포함. 우체국은 문 모양 + 코드 라벨로 구별), 시계 바늘, 해시계 그림자, 가방
- **프롬프트:**
  > A faded black-and-white photograph with a slight sepia tone, taken from the rooftop terrace of a great stone arch. In the left foreground, a small trial clock on a short iron post: a plain white round face with NO hands and NO numbers; on a small plate on the post, a carved star with twelve thin rays and a small circle in the middle. In the right foreground, a flat round sundial on a low stone pedestal seen slightly from above, with a thin upright gnomon and faint hour lines but no readable numbers, and NO shadow on the dial. Behind, city roofs and wide avenues radiating outward. Three ordinary clocks clearly visible in the city: a bracket clock on the wall of a corner café, a clock on a distant church tower, and a round clock above a grand doorway. All clock faces plain white with NO hands and NO numbers, each large enough to see. No people, no text, no signs with words. Old photo grain, soft vignette. 3:2 landscape.

### #5 `sundial_top.png` — 오늘의 해시계
- **배치:** M3 가운데(화면 폭의 약 80%, 태블릿에서는 오른쪽 절반). 해 궤도·그림자·숫자는 코드
- **내용(제작 요청 당시):** 바로 위에서 본 둥근 청동 해시계판. 가운데에서 위쪽 가장자리로 향하는 얇은 삼각 그노몬. 오른쪽 절반에 시각선 부채꼴. 바깥 테에 문구용 빈 띠
- **납품본 기준(확정):** 오른쪽 절반의 시각선 **7개**를 `1:00 / 1:30 / 2:00 / 2:30 / 3:00 / 3:30 / 4:00`으로 쓴다. 간격이 고르지 않으므로 각도는 실측 테이블로 관리한다(Spec §6.2 확정값 23.4°·45.9°·65.1°·82.9°·102.5°·121.9°·143.3°, 허브 (627, 627), 12시 방향 0°에서 시계 방향). **맨 아래 세로선(약 180°)은 그노몬 축 연장선이며 시각선이 아니다.** 숫자·점·판정에 쓰지 않는다.
- **크기 규칙:** 1254×1254. 그노몬 밑점은 캔버스 중심 근처(1차 실측 627, 627). 판 지름은 실측값을 쓴다
- **측정할 것:** 그노몬 밑점, 시각선 7개의 각도(정밀 재측정), 판 반지름(그림자 길이 기준), 테 띠의 반지름
- **제외:** 숫자, 글자, 그림자, 과한 이끼·풀
- **프롬프트:**
  > A round bronze sundial plate seen exactly from above, centred: a thin triangular gnomon running from the centre toward the top edge (seen from above as a narrow line), nine engraved hour lines fanning out evenly across the right half, a blank engraved band around the rim. Weathered bronze with a soft green patina at the edges, even light. NO numbers, NO text, NO shadow. Isolated on a transparent background. Square.

### #6 `trial_log_open.png` — 시험 기록부
- **배치:** Final 아래 단(목차 = 왼쪽 쪽, 넘겨 보는 쪽 = 오른쪽 쪽), Case Closed RECORD LIST(같은 그림을 뒤표지 안쪽으로 사용)
- **내용:** 위에서 본 펼쳐진 두꺼운 장부. 양쪽 빈 크림색 쪽(옅은 가로줄), 짙은 초록 천 표지 가장자리, 얇은 버건디 리본 책갈피. 왼쪽 쪽 위에 빈 작은 원(EMBLEM 자리)
- **측정할 것:** 왼쪽·오른쪽 쪽의 글 영역, EMBLEM 원
- **제외:** 글자, 숫자, 도장, 서명, **찢긴 자국·빠진 쪽·제본 흔적(Case 11 몫)**, 얼룩
- **프롬프트:**
  > A thick old ledger lying open, seen from directly above: two blank cream pages with faint ruled lines, a dark green cloth cover edge, a thin burgundy ribbon bookmark. In the top left of the left page, one small empty circle. Clean, intact pages: no tears, no missing pages, no stitching visible. NO text, NO numbers, NO stamps. Isolated on a transparent background. 3:2 landscape.

---

## 3. 납품 후 확인

| 확인 | 기준 |
|---|---|
| 별 일치 | #2 문짝의 별, #4 T1 기둥 별 = `clock_model_t1.png` 받침 별(끝 12개 + 원) |
| 해 아이콘과 구별 | `InkGlyph.sun`의 둥근 빛살이 별과 혼동되지 않음(코드 확인) |
| 바늘·그림자 없음 | #4 시계 4개, #4·#5 해시계 |
| 사진 시계 크기 | 360폭에서 돋보기 없이도 "시계가 있다"는 정도는 보임. 성당 시계는 예외적으로 작음 → §4 검수 기준 |
| 해시계 일치 | #4의 해시계와 #5가 같은 판 모양(둥근 판 + 그노몬) |
| 드럼 구별 | #2·#3의 드럼이 Case 03 `time_recording_machine`과 다른 실루엣 |
| 기록부 | #6 찢김·제본 흔적 없음 |
| 금지 요소 | 사람, 가방, 방패, 월계관, 보라색 도장, 글자 |
| 투명도 | #3, #5, #6 바깥 알파 0 |
| 워터마크 | 모서리 확인(Case 05 사례) |

---

## 4. 납품 검수 결과 (2026-10-24 · 승인, 재생성 없음)

| # | 파일 | 실제 해상도 · 배경 | 결과 | 구현 시 지킬 것 |
|---|---|---|---|---|
| 1 | `arc_star_view.png` | 1536×1024 · 불투명 | 승인. 아치 가운데, 방사형 길, 긴 그림자 | — |
| 2 | `star_room.png` | 1536×1024 · 불투명 | 승인. 별은 **문짝**에 있음(T1 받침 별과 같은 모양), 벽에는 카드 꽂이 대신 **빈 황동 명판** | 명판 실측 사각형 위에 Flutter 텍스트 오버레이. 별은 그림 그대로. Intro 6줄은 `A brass plate on the wall:` |
| 3 | `record_drum.png` | **1254×1254** · 투명(반투명 0.7%) | 승인. 오른쪽 끝 띠에 세로 슬롯, 받침 앞 타원 명판 | 슬롯·명판 실측 |
| 4 | `roof_photo.png` | 1536×1024 · 불투명 | 승인. **사진 테두리 내장.** 성당 시계는 폭 약 2%로 작음(카페·우체국 시계는 충분) | 이중 테두리 금지. 성당 시계 기준은 아래 |
| 5 | `sundial_top.png` | **1254×1254** · 투명(반투명 0.4%) | 승인. 시각선 7개 + 맨 아래 세로선 | 7개 = 1:00–4:00(30분). 세로선은 시각으로 쓰지 않음. 각도는 실측 테이블(Spec §6.2) |
| 6 | `trial_log_open.png` | 1536×1024 · 투명(반투명 0.8%) | 승인. 미리보기의 주변 번짐은 알파 0 영역의 색값이라 화면에 나오지 않음 | 쪽 글 영역 실측 |

**성당 시계 검수 기준 (필수, Spec §5.2.1과 동일)**
1. 터치·돋보기 판정 영역 최소 **48×48 logical pixels**
2. 돋보기 확대 시 시계판(렌즈 안 지름 40 logical pixels 이상)과 시침·분침이 구별될 것
3. **360폭 화면에서 실제 캡처 검수**(태블릿 1종 포함)
4. 다른 시계의 판정 영역과 겹치지 않을 것
5. 시계판 중심·반지름은 이미지 **실측 좌표** 사용
