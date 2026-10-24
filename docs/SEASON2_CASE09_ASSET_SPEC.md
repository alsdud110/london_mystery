# Season 2 · Case 09 — The Clockwork Garden
## 확정 이미지 에셋 명세서 (v1.0 · 2026-10-23 · 사용자 승인)

**기획 기준:** `docs/SEASON2_PARIS_STORY_BIBLE.md` v1.7 §6 Case 09 확정 명세, `docs/SEASON2_CASE09_SPEC.md` v1.0
**저장 폴더:** `assets/seasons/season_02_paris/cases/case_09/`
**원칙**
- 이미지는 사용자가 제작한다. Claude Code는 임시 이미지·도형·AI 이미지를 넣지 않는다.
- 장식 그림과 조작 요소를 분리한다. 톱니·바늘·글자·표식 일부는 낱장 PNG 또는 코드로 겹친다. 런타임에 픽셀을 측정하지 않고, 납품 후 좌표를 측정해 scene 데이터에 기록한다.
- 투명 에셋은 **실제 알파 채널 PNG**(바깥 알파 0). 체크무늬를 그려 넣은 가짜 투명은 받지 않는다.
- 화풍: Vintage Detective Storybook. 회화 장면은 `case_08/corner_2.png`, 황동 물건은 `case_03/time_recording_machine_open.png`, 종이는 `case_07/amendment_slip_blank.png` 기준.

---

## 0. 요약

### 0.1 재사용 (신규 제작 없음)
| 파일 / 코드 | 용도 |
|---|---|
| `case_08/last_sketch_garden.png` | Intro 1–3 |
| `locations/map/paris_mystery.png` | M1 받침의 지도, Trial Map 증거, Next Lead |
| `case_04/hands_sign.png` | M3 Notebook 카드 B, 수리 메모의 두 바늘 도장 |
| `InkGlyph.gear` (코드) | M3 카드 A, 설계도 EMBLEM. **확정:** Case 01 Notebook clue `s2_ep01_c3`의 톱니 8개 아이콘이 기준 |
| `InkGlyph.key` (코드) | M3 미끼 도장 |
| `ClockQuestion` 바늘 그리기 (코드) | 모든 시계 바늘. Final 시작의 **바늘 다시 끼우기 연출**도 이 코드 바늘을 움직여 만든다(새 이미지 없음) |
| 기존 `Paper` 카드 (코드) | M2 기록 꼬리표 `TRIAL RECORDS · KEPT AT THE STAR` (드럼 그림 없이 꼬리표 카드만) |
| 기존 온보딩 손가락 애니메이션 | M1·M2 첫 조작 안내 |

### 0.2 신규 — 8장 (v0.1: 19장)
| # | 파일 | 용도 | 크기 | 비율 | 배경 | 필수 |
|---|---|---|---|---|---|---|
| 1 | `garden_model_view.png` | Intro 4–5, Case Closed 배경 | 1536×1024 | 3:2 | 불투명 | 권장 |
| 2 | `clock_model_t1.png` | M1 모형 T1 (아치 + 별) | 512×512 | 1:1 | 투명 | 필수 |
| 3 | `clock_model_t2.png` | M1 모형 T2 (다리 + 아치 세 개) | 512×512 | 1:1 | 투명 | 필수 |
| 4 | `clock_model_t3.png` | M1 모형 T3 (뾰족탑 + 종) | 512×512 | 1:1 | 투명 | 필수 |
| 5 | `gear_board.png` | M2 판 배경 | 1536×1024 | 3:2 | 불투명 | 필수 |
| 6 | `gear_brass.png` | M2 모든 톱니(크기는 코드에서 조절) | 512×512 | 1:1 | 투명 | 필수 |
| 7 | `clock_dial.png` | M2·Final 모든 시계판(T1–T3, 정원, 탑) | 1024×1024 | 1:1 | 투명 | 필수 |
| 8 | `chronos_plan.png` | M3 설계도 + 핀으로 꽂힌 수리 메모 | 1536×1024 | 3:2 | 투명(종이만) | 필수 |

**더 줄이는 선택지:** #1을 빼면 7장. Intro는 연필화(`last_sketch_garden`)에서 바로 M1 지도 화면으로 넘어간다. 정원에 도착하는 분위기가 약해지므로 권하지 않는다.

### 0.3 v0.1에서 뺀 이미지 (11장 감소 + 통합)
`little_paris_model`(모형 전체), 기둥 확대 4장(`post_*`), 받침돌 표식 3장(`marker_*` → 모형 그림에 포함), `gear_tower`(→ `gear_brass` 크게), `dial_ring`·`dial_plain`(→ `clock_dial` 1장), `record_drum`(→ 꼬리표 카드), `chronos_plan_blank`+`repair_page_blank`(→ #8 1장), `tower_face_blank`(→ `clock_dial`), `trial_lever`(→ 기존 버튼).

---

## 1. 생성 순서
1. `garden_model_view.png` — `last_sketch_garden.png`를 참고 이미지로
2. `clock_model_t1.png` → `t2`, `t3` — t1을 참고 이미지로 같은 받침·같은 시계
3. `clock_dial.png` — #2 모형 시계와 같은 시계판 모양
4. `gear_brass.png` → `gear_board.png`
5. `chronos_plan.png`

---

## 2. 이미지별 명세

### #1 `garden_model_view.png` — 정원 도착
- **배치:** 화면 전체(cover). `last_sketch_garden.png`에서 겹쳐 바뀌는 전환(연필화 → 채색화)
- **내용:** 연필화와 **같은 시점·구도**의 채색화. 뒤에 가운데가 높고 돔이 있는 긴 궁전, 분수 연못, 꽃밭. 앞 가운데 탁자 높이의 직사각형 돌 받침, 그 위에 작은 시계탑(뾰족 지붕, **바늘·숫자 없는 시계판**), 둘레에 작은 집 지붕 3채와 그 뒤로 낮은 작은 건물들. 받침 윗면에 지도가 새겨진 느낌(자세히는 안 보이게). 오른쪽 끝에 기둥 위 **정원 시계**(흰 판, 바늘 없음 — 이 장면에서는 바늘을 그리지 않음)
- **제외:** 사람, 가방, 바구니, 글자, 시계 바늘, 다른 랜드마크
- **연속성:** 받침·탑·지붕 3채가 연필화와 같은 자리
- **프롬프트 (참고: `last_sketch_garden.png`):**
  > Impressionist oil painting with thick, visible brushstrokes, bright clear daylight, the same view and composition as the reference pencil drawing. In the back, a long palace whose middle section is taller with a small dome; a round pond with a fountain jet, formal flowerbeds and clipped cone-shaped trees. In the foreground, a table-high rectangular cream stone base; on it a small model clock tower with a pointed slate roof and a round white face showing only hour marks, NO hands, NO numbers. Three tiny model house roofs around the tower in the same places as in the reference, and more tiny model buildings low behind them. At the far right edge, an ordinary garden clock on a dark iron post, plain white face, NO hands. No people, no bag, no basket, no text, no other monuments. 3:2 landscape.

### #2–4 `clock_model_t1.png` · `t2` · `t3` — 시계 모형 3개
- **배치:** M1 화면 아래 트레이(세 개 나란히, 손가락으로 끌기), 지도에 놓인 뒤에는 랜드마크 위에 작게(지도 폭의 약 9%). Trial Map 증거·Next Lead에서 다시 사용
- **공통:** 손으로 깎은 작은 모형 하나, 앞쪽 약간 위에서 본 시점. 아래에 **같은 모양의 작은 돌 받침**, 받침 앞면에 **새긴 표식 하나**(선명하고 굵게). 모형 옆 또는 위에 **작은 둥근 시계**(흰 판, 황동 테, 바늘·숫자 없음). 세 장 모두 받침 크기·시계 크기·조명 같음. 모형이 캔버스의 약 85%
- **모양과 표식 (반드시)**
  | # | 모형 | 받침 표식 |
  |---|---|---|
  | 2 T1 | 큰 **개선문 아치 하나**, 시계는 아치 위 | **별**(끝 12개, 가운데 작은 원) |
  | 3 T2 | **아치 세 개 돌다리**, 다리 끝에 **초록 책 가판대** 두 개, 시계는 다리 가운데 기둥 위 | **아치 세 개** |
  | 4 T3 | **긴 홀 + 가늘고 높은 뾰족탑 하나**, 시계는 탑에 | **종** |
- **제외:** 글자, 숫자, 바늘, 톱니·잎·방패·바늘 표식, 사람, 월계관(Case 07·08 도장 연상 금지)
- **구별 확인:** T3이 Notre-Dame(사각 탑 둘)처럼 보이지 않을 것. T1이 오페라(돔)처럼 보이지 않을 것
- **프롬프트 (#2):**
  > A small hand-carved model of a single large triumphal arch in cream stone, with a small round clock (white face, brass rim, NO hands, NO numbers) set on top of the arch. It stands on a small square stone plinth; on the plinth's front face, one bold carved symbol: a star with twelve thin rays and a small circle in the middle. Seen from the front and slightly above, warm daylight, painterly storybook style. Isolated on a transparent background. No text, no numbers. Square.
- **#3:** `Same plinth, clock, light and style as the reference. The model is a stone bridge with three round arches, two tiny green bookstalls at one end, and the small clock on a post in the middle of the bridge. Carved symbol on the plinth: three round arches side by side over one line.`
- **#4:** `Same plinth, clock, light and style as the reference. The model is a long hall with one tall thin pointed spire; the small clock is on the spire. Carved symbol on the plinth: a single bell.`

### #5 `gear_board.png` — 톱니판 배경
- **배치:** M2 화면 전체. 탑 바퀴·톱니·고정 톱니·시계·빈 자리 점선·트레이 칸은 **모두 코드로 겹친다**(위치를 데이터로 보장)
- **내용:** 받침 안 작은 문 뒤의 닦인 황동 판, 정면. 모서리 나사 4개, 얇은 테. 위쪽 가장자리에 글을 새길 빈 띠. 아래 약 20%는 움푹한 빈 트레이. 판 표면은 **완전히 비어 있음**
- **제외:** 톱니, 축, 구멍, 글자, 숫자, 시계
- **프롬프트:**
  > A polished antique brass panel seen straight on, filling the frame, inside a small stone niche: four corner screws, a thin raised rim, a blank flat band along the top edge. The surface is completely plain — no gears, no holes, no pins. Along the bottom fifth, a shallow empty recessed tray. Warm soft light, gentle reflections, no heavy rust. No text, no numbers. 3:2 landscape.

### #6 `gear_brass.png` — 톱니 (공용)
- **사용:** 탑 바퀴(크게), 큰 톱니, 작은 톱니, 고정 톱니. 크기 차이는 코드에서 배율로. 회전도 코드
- **내용:** 위에서 똑바로 본 황동 톱니. 둥글고 큼직한 **톱니 10개**, 바퀴살 4개, 가운데 축 구멍. 원근·그림자 없음
- **크기 규칙:** 톱니 끝 지름 = 캔버스 92%, 중심 = 캔버스 중심(회전축)
- **제외:** 문양·표식(특히 M3 EMBLEM의 8개 톱니와 같은 모양이 되지 않게 — 10개)
- **프롬프트:**
  > A single brass gear seen exactly from above, flat and perfectly centred: TEN large rounded teeth, four spokes, a round axle hole in the middle; tooth tips reach 92% of the canvas width. Even light, no shadow, no perspective. Isolated on a transparent background. Square.

### #7 `clock_dial.png` — 시계판 (공용)
- **사용:** M2의 T1·T2·T3·정원 시계(작게), Final의 탑 시계(크게, 바늘 없는 상태에서 코드 바늘을 끼우는 연출)와 결과 줄. 시계 구별은 코드 라벨(`T1`, `GARDEN` 등)로. 바늘은 `ClockQuestion` 방식으로 코드
- **내용:** 위에서 본 둥근 시계판. 흰 법랑, **눈금 12개, 숫자 없음, 바늘 없음**, 가운데 작은 점, 얇은 황동 테
- **크기 규칙:** 바깥 지름 = 캔버스 92%, 중심 = 캔버스 중심
- **연속성:** #1 탑·#2–4 모형 시계와 같은 인상(숫자 없는 흰 판)
- **프롬프트:**
  > A round clock dial seen exactly from above: white enamel face with twelve hour marks, NO numbers, NO hands, a tiny centre dot, a thin brass rim. Centred, even light, no shadow. Isolated on a transparent background. Square.

### #8 `chronos_plan.png` — 설계도 + 수리 메모
- **배치:** M3 화면 오른쪽(가로 화면 기준 약 60%), 왼쪽은 Notebook 카드 2장(코드)
- **내용:** 프러시안 블루 청사진 한 장(흰 선, 기계 그림 — 톱니판 비슷한 바퀴들, 숫자 없음). 오른쪽 아래 구석에 **빈 원 하나**(EMBLEM 자리) 와 그 옆 빈 글 줄 하나. 청사진 오른쪽 위에 **크림색 작은 메모지**가 황동 핀으로 꽂혀 있음: 가로줄 2줄, 각 줄 끝에 **빈 정사각형 도장 칸**
- **코드로 겹치는 것:** `CHRONOS TRIAL · EMBLEM` + 톱니 8개 문양(`InkGlyph.gear`), 메모 줄 글 `REPAIRS · T2 WHEEL` + 두 바늘(`hands_sign.png`), `REPAIRS · T3 GLASS` + 열쇠(`InkGlyph.key`)
- **제외:** 글자, 숫자, 도장, 서명, 사람 이름, 방패·월계관·보라색 도장. 청사진 그림 속 바퀴는 **톱니 8개짜리를 그리지 않음**(EMBLEM과 혼동 방지)
- **측정할 것:** EMBLEM 원, 글 줄 3곳, 도장 칸 2곳 (탭 영역 최소 48pt)
- **프롬프트:**
  > An old Prussian-blue blueprint sheet with crisp white technical lines, seen flat and straight on: a simple drawing of a board of gear wheels (each with twelve or more teeth) and axle crosshairs, no numbers. In the lower right corner, one empty circle and one blank line beside it. Pinned to the upper right of the blueprint with a small brass pin, a small cream note paper with two ruled rows, each ending in one empty square box. Slightly aged edges. Absolutely no text, no numbers, no stamps, no signatures. Isolated on a transparent background, 3:2 landscape.

---

## 3. 납품 후 확인

| 확인 | 기준 |
|---|---|
| 그림 ↔ 정원 | #1의 받침·탑·지붕 3채가 `last_sketch_garden.png`와 같은 구도 |
| 바늘 없음 | #1, #2–4, #7 모두 바늘 없음 |
| 모형 ↔ 지도 | #2 아치, #3 다리+초록 가판대, #4 뾰족탑 하나가 `paris_mystery.png`의 Arc, Seine Quays, Arts et Métiers와 한눈에 맞음 |
| 표식 구별 | 별·아치 세 개·종이 작은 크기(지도 위 약 9%)에서도 구별됨 |
| 톱니 | #6 톱니 10개. 크게·작게 배율을 바꿔도 맞물린 모습이 어색하지 않음(구현 시 확인) |
| EMBLEM 유일성 | #8에 톱니 8개짜리 그림 없음 |
| 금지 요소 | 사람, 가방, 글자, 숫자, 방패, 월계관, 보라색 도장, `M` 글자 없음 |
| 투명도 | #2–4, #6–8 바깥 알파 0 |
| 워터마크 | 생성기 워터마크(Case 05 사례) 모서리 확인 |
