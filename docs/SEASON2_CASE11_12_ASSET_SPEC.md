# Season 2 · Case 11–12 — 이미지 에셋 최종 명세서
## v1.2 (2026-10-26 · 확정 스토리 기준 · Case 11 납품 16장 승인)

**기획 기준:** `SEASON2_CASE11_SPEC.md` v1.0, `SEASON2_CASE12_SPEC.md` v1.0, Story Bible v2.0
**상태:** 스토리 확정 → **사용자 제작 중.** Claude Code는 이미지를 만들지 않는다. 임시 이미지나 도형으로 대신하지 않는다.
**v1.1 (2026-10-26, 사용자 결정):** Case 11 1차 납품 16장 검수(§6). `annex_shelves.png`는 상자 4개 그대로 쓰고 번호를 3·9·12·19로 정함(정답 9). Émile 시곗줄은 수정하지 않음. 인물 6장을 `characters/`로 옮김. `annex_street.png`는 교체 대기(사용자가 새로 만들 때까지 대체 이미지 없음).
**v1.2 (2026-10-26):** `annex_street.png` 2차 납품본 승인(고전 양식 네모 석조 탑, 돔 없음). Case 11 이미지 16장 완료.

**저장 폴더**
- 인물: `assets/seasons/season_02_paris/characters/` (신규. Season 1 `season_01_london/characters/`와 같은 구조)
- Case 11: `assets/seasons/season_02_paris/cases/case_11/`
- Case 12: `assets/seasons/season_02_paris/cases/case_12/`
- 구현할 때 `pubspec.yaml`에 세 폴더를 등록한다.

---

## 공통 원칙
1. **글자·숫자·시곗바늘·문서 본문·상자 번호·이름표 글자·톱니 자국은 코드로 겹친다.** 이미지에는 넣지 않는다. 예외: 서명 3종(필적 자체가 단서).
2. **투명 에셋은 실제 알파 채널 PNG**(바깥 알파 0). 가짜 체크무늬 투명은 받지 않는다.
3. **워터마크 금지.** 기존 `clockmaker_master.png`, `shared/objects/pocket_watch.png`에는 오른쪽 아래에 생성 도구 표식이 남아 있다.
4. **좌표는 납품 후 실측해 scene 데이터에 기록한다.**
5. **화풍**
   - 인물: Season 1 증인(`flower_seller.png`, `baker.png`)과 같은 잉크 선 + 수채, 양피지 종이 인쇄본
   - 장면: `case_08/corner_2.png`, `case_10/star_room.png`의 인상파 유화 붓질, 크림·슬레이트 블루·골드
   - 황동: `case_10/record_drum.png` 재질. 실루엣은 Case 03 장치·Case 10 드럼과 다르게
   - 종이: `case_07/amendment_slip_blank.png`
6. **공통 제외:** 읽을 수 있는 글자·숫자, 로고, 실제 기관 문장, 국기, 과한 그런지, 경찰·체포를 떠올리게 하는 요소.

### ★ 통일 디자인 1: "Émile's wheel"
**기준(실물 확인):** `case_05/clock_back_extra_wheel.png`(1024×1024)의 오른쪽 가운데, 약 (670, 520)에 있는 지름 약 170px의 작은 황동 바퀴
- **굵고 곧은 바큇살 4개**(X자처럼 엇갈린 십자)
- 가운데 **볼록한 둥근 허브 + 반구형 축 마개**
- 테두리에 **작은 네모 톱니 약 30개**, 얇은 테

| 나오는 곳 | 파일 | 역할 |
|---|---|---|
| Clock III(기존) | `case_05/clock_back_extra_wheel.png` | 비교 기준 |
| 기계 안 3칸의 가운데 | `machine_wheel_row.png` (B4) | 증명 ① |
| Clockmaker 회중시계 안 | `watch_back_open.png` (B9) | 증명 ② |

**규칙:** 기준 이미지를 크롭해 **참조 이미지로 함께 넣고** 만든다. 크기는 장면마다 달라도 되지만 살 수·허브·톱니 모양은 같아야 한다.

### ★ 통일 디자인 2: "The Clockmaker's gear mark"
Case 01 clue `s2_ep01_c3`의 **톱니 8개 아이콘**(`InkGlyph.gear`). 종이에 찍히는 자국은 코드가 이 글리프로 그린다. 도장 도구(`emile_gear_stamp.png`) 끝의 톱니도 **톱니 8개, 같은 실루엣**이어야 한다.

### ★ 통일 디자인 3: "Victor's signature"
`victor_signature.png` 하나를 세 곳에 쓴다.
- 방명록(잉크)
- 찢긴 장부 쪽의 눌린 자국(코드가 흑연 질감으로 변환)
- 투사지 판정

특징 세 가지(곡선 V · 긴 밑줄 · 끝의 점)는 이 서명에만 모두 있다.

---

## 0. 요약

### 0.1 재사용 (신규 제작 없음)
| 파일 / 코드 | 용도 |
|---|---|
| `case_07/office_stamp.png` | Case 11 상자 봉인, Victor's paper의 도장, M2 도장 비교 |
| `case_05/tracing_sheet.png` | Case 11 M3 투사지 |
| `case_05/clock_back_extra_wheel.png` | Case 12 M1 비교 기준 바퀴(크롭) |
| `case_04/hands_sign.png` | Case 12 M1 이름표의 두 바늘 도장 |
| `case_09/clock_dial.png` + 코드 바늘 | Case 12 벽시계 |
| `locations/map/paris_mystery.png` | Case 11 Case Closed 지도 |
| `shared/objects/pocket_watch.png` | 회중시계 B8·B9 제작 참고(화면에 직접 쓰려면 워터마크를 먼저 처리해야 함) |
| 코드 `Paper` | 원본 3쪽, Victor's paper 본문, 문지른 글자, 이름표, 점검 카드 |
| 코드 `InkGlyph` | 연필 토큰, 시계 여는 도구, 톱니 자국(`gear`) |
| 기존 Notebook·Case File UI | 엔딩의 사건 파일 정리·닫기 |

### 0.2 신규 — 총 27장
| # | 파일 | 폴더 | Case · Mission | 크기 | 투명 | 우선순위 |
|---|---|---|---|---|---|---|
| C1 | `victor_base.png` | characters/ | 11 전체 | 1122×1402 | 불투명 | 1 |
| C2 | `victor_nervous.png` | characters/ | 11 M1–M2, Final | 1122×1402 | 불투명 | 1 |
| C3 | `victor_sad.png` | characters/ | 11 Final 고백 | 1122×1402 | 불투명 | 1 |
| C4 | `emile_base.png` | characters/ | 12 전체 | 1122×1402 | 불투명 | 1 |
| C5 | `emile_sad.png` | characters/ | 12 M1–M2, Ending | 1122×1402 | 불투명 | 1 |
| C6 | `emile_back.png` | characters/ | 12 Intro | 1122×1402 | 불투명 | 2 |
| A1 | `annex_street.png` | case_11/ | 11 Intro | 1536×1024 | 불투명 | 3 |
| A2 | `annex_reading_room.png` | case_11/ | 11 대화 배경, M2, Final | 1536×1024 | 불투명 | 1 |
| A3 | `big_book_torn.png` | case_11/ | 11 M1·M3 | 1536×1024 | 투명 | 1 |
| A4 | `annex_shelves.png` | case_11/ | 11 M1 | 1536×1024 | 불투명 | 2 |
| A5 | `box9_open.png` | case_11/ | 11 M1 | 1254×1254 | 투명 | 2 |
| A6 | `visitor_book_open.png` | case_11/ | 11 Intro, M3 | 1536×1024 | 투명 | 1 |
| A7 | `victor_signature.png` | case_11/ | 11 Intro, M1, M3 | 1024×384 | 투명 | 1 |
| A8 | `signature_old_a.png` | case_11/ | 11 M3 | 1024×384 | 투명 | 2 |
| A9 | `signature_old_b.png` | case_11/ | 11 M3 | 1024×384 | 투명 | 2 |
| A10 | `victors_paper.png` | case_11/ | 11 M2, Final | 1024×1536 | 투명 | 1 |
| B1 | `arts_metiers_hall.png` | case_12/ | 12 Intro | 1536×1024 | 불투명 | 3 |
| B2 | `old_machine_room.png` | case_12/ | 12 대화 배경, M2, M3, Final | 1536×1024 | 불투명 | 1 |
| B3 | `chronos_machine.png` | case_12/ | 12 Intro, M1, M3 | 1254×1254 | 투명 | 1 |
| B4 | `machine_wheel_row.png` | case_12/ | 12 M1 | 1536×1024 | 투명 | 1 |
| B5 | `machine_big_wheel.png` | case_12/ | 12 M3 | 1254×1254 | 투명 | 2 |
| B6 | `machine_lever.png` | case_12/ | 12 M3 | 512×1024 | 투명 | 2 |
| B7 | `machine_pin.png` | case_12/ | 12 M3 | 512×512 | 투명 | 2 |
| B8 | `watch_back_closed.png` | case_12/ | 12 M2 | 1254×1254 | 투명 | 1 |
| B9 | `watch_back_open.png` | case_12/ | 12 M2 | 1254×1254 | 투명 | 1 |
| B10 | `emile_gear_stamp.png` | case_12/ | 12 M2 | 512×1024 | 투명 | 1 |
| B11 | `finale_morning.png` | case_12/ | 12 Ending | 1536×1024 | 불투명 | 1 |

**우선순위:** 1 = 이야기·핵심 추리에 꼭 필요 · 2 = 퍼즐 필수 · 3 = 장소 분위기(없으면 다음 장면 그림으로 시작해도 이야기에는 문제없음)

### 0.3 v0.2에서 바뀐 것
| 변경 | 파일 | 이유 |
|---|---|---|
| **삭제** | `hide_order_blank.png` | 별도 지시서를 없앴다. 지시는 찢긴 장부 쪽의 눌린 글씨로 나온다(A4) |
| **추가** | `emile_gear_stamp.png` | 정체 증명 ③(도구가 Clockmaker 표식을 찍음) |
| 내용 변경 | `big_book_torn.png` | 오른쪽 장에 **문지르기 영역 세 개**(두 줄 + 서명) |
| 내용 변경 | `victors_paper.png` | 아래에 **도장 자리**(M2 도장 비교) |
| 내용 변경 | `old_machine_room.png` | 작업대에 **펼친 가죽 도구 롤**(B10을 올리는 자리) |
| 내용 변경 | `machine_wheel_row.png`, `watch_back_open.png` | 기준 바퀴 실측값(살 4개 X자) 반영 |
| 내용 변경 | `finale_morning.png` | 유리 상자 속 3쪽 = "보존" 장면을 분명히 |

### 0.4 언제 만드는가
**스토리가 확정되어 모두 지금 만들 수 있다.** 권장 순서는 §1.

---

## 1. 제작 순서
1. `victor_base` → 참조 편집으로 `victor_nervous`, `victor_sad`
2. `emile_base` → 참조 편집으로 `emile_sad`, `emile_back`
3. `old_machine_room` → `chronos_machine` → `machine_big_wheel`, `machine_lever`, `machine_pin`(B3 참조)
4. **기준 바퀴 크롭 준비** → `machine_wheel_row` → `watch_back_closed` → `watch_back_open`
5. `emile_gear_stamp`
6. `visitor_book_open` → `victor_signature` → `signature_old_a`, `signature_old_b`
7. `annex_reading_room` → `big_book_torn` → `annex_shelves` → `box9_open` → `victors_paper`
8. `finale_morning`(B2·B3이 확정된 뒤)
9. `annex_street`, `arts_metiers_hall`

---

## 2. 인물 초상화 공통 (C1–C6)
| 항목 | 기준 |
|---|---|
| 형식 | Season 1 증인과 같은 **4:5 종이 인쇄본**, 1122×1402, 따뜻한 양피지 바탕(불투명), 테두리 그림 없음 |
| 구도 | 무릎 위 3/4 정면, 인물 폭 70% 이내, **눈높이 = 위에서 약 25%**(대화창이 아래 42%를 덮어도 얼굴이 보임) |
| 표정 세트 일치 | 얼굴·머리·옷·소품·체형·**위치·크기·카메라 각도**가 같아야 한다(얼굴 중심 ±1%). **바뀌는 것은 표정과 손뿐** |
| 제작 방법 | base 확정 → 이미지 편집으로 변형("same character, same clothes, same framing, change only the face and hands") |
| 제외 | 글자, 이름표, 배경 소품, 배지·도장 문양, 바늘이 보이는 시계판 |

**Victor 고정값:** 60대 초반, 키 크고 마름, 길고 좁은 얼굴, 옅은 회색 눈, 옆가르마로 단정히 빗은 은발, 짧은 은색 콧수염. 숯빛 회색 울 코트, 짙은 남색 조끼, 흰 셔츠, 버건디 넥타이, 무늬 없는 은색 넥타이핀. 왼손에 철테 안경. 점잖지만 차가운 인상이며, 악당처럼 과장하지 않는다.

**Émile 고정값:** 50대 초반, 마른 체격, 깊은 짙은 눈과 피곤한 눈가 주름, 관자놀이가 희끗한 짙은 머리, 회색이 섞인 짧은 수염. 소매를 걷은 짙은 청색 셔츠, 낡은 갈색 조끼, **빈 시곗줄 고리**(시계는 탐정에게 있음), 닳은 가죽 작업 앞치마, 목에 건 확대경. 조용하고 지친 인상이며, 영웅이나 악당으로 과장하지 않는다.

---

## 3. 이미지별 명세

### C1 `victor_base.png`
- **경로·사용:** characters/ · Case 11 Intro, M1 조사 전, M2 서류, Final 마지막 대화
- **크기·투명:** 1122×1402 · 불투명
- **재사용:** 불가(신규 인물)
- **일치:** C2·C3 전부
- **우선순위:** 1
> Storybook ink-and-watercolour portrait print on warm aged parchment, like a vintage detective storybook character plate. A tall, thin gentleman in his early sixties, three-quarter view from the knees up, facing slightly to the viewer's left. Long narrow face, pale grey eyes, neatly combed silver hair with a side parting, a short trimmed silver moustache. Charcoal grey wool overcoat with wide lapels, dark navy waistcoat, white shirt, dark burgundy tie, a plain thin silver tie pin. He holds wire-rimmed reading glasses in his left hand. Polite, calm expression with a faint cool smile. Soft light from the upper left. Plain parchment background, no props, no text, no border, no badge. Portrait 4:5.

### C2 `victor_nervous.png`
- **경로·사용:** characters/ · `Lists can be wrong.`, 3쪽 제시 반응, M2 반박, Final 1–2번 질문
- **크기·투명:** C1과 같음 · 우선순위 1
- **재사용:** C1 참조 편집
- **일치:** C1 전체
> Same character, same clothes, same framing and lighting as the reference image. Change only the face and hands: eyebrows raised and drawn together, eyes a little wide, a tight worried mouth, as if caught by surprise; the reading glasses now held against his chest. No comic exaggeration. Everything else identical.

### C3 `victor_sad.png`
- **경로·사용:** characters/ · Final 3번 `…I did.`, 고백, 가방·정원 대사
- **크기·투명:** C1과 같음 · 우선순위 1
- **재사용:** C1 참조 편집
- **일치:** C1 전체
> Same character, same clothes, same framing and lighting as the reference image. Change only the face and hands: he looks down, shoulders a little lowered, a tired, ashamed and sad expression; the reading glasses hang loosely at his side. Calm, not crying. Everything else identical.

### C4 `emile_base.png`
- **경로·사용:** characters/ · Case 12 얼굴 공개, 이름 공개, 정체 확인, 이유 설명, M3, 엔딩 5줄
- **크기·투명:** 1122×1402 · 불투명
- **재사용:** 불가. `clockmaker_master.png`(Season 1, 화면 미사용, 워터마크)는 쓰지 않는다
- **일치:** C5·C6 전부, **빈 시곗줄 고리**
- **우선순위:** 1
> Storybook ink-and-watercolour portrait print on warm aged parchment, like a vintage detective storybook character plate. A lean clockmaker in his early fifties, three-quarter view from the knees up, facing slightly to the viewer's right. Deep-set dark eyes with tired lines, dark hair streaked with grey at the temples and a little untidy, a short grey-flecked beard. Dark blue collarless shirt with rolled-up sleeves, a worn brown waistcoat with an empty watch-chain loop and no watch, a worn dark-brown leather work apron, a jeweller's loupe on a cord around his neck. Quiet, calm, slightly weary expression, looking at the viewer. Soft light from the upper left. Plain parchment background, no props, no text, no border, no emblem. Portrait 4:5.

### C5 `emile_sad.png`
- **경로·사용:** characters/ · `Nobody listened.`, `I was wrong.`, Q2, Paris 행동, 엔딩 3–4줄
- **크기·투명:** C4와 같음 · 우선순위 1
- **재사용:** C4 참조 편집
- **일치:** C4 전체
> Same character, same clothes, same framing and lighting as the reference image. Change only the face and hands: eyes lowered, brows drawn together, mouth set in quiet regret; one hand rests flat on his apron over his chest. Serious and sorry, not dramatic. Everything else identical.

### C6 `emile_back.png`
- **경로·사용:** characters/ · Case 12 Intro 6–7줄(얼굴 공개 직전)
- **크기·투명:** C4와 같음 · 우선순위 2
- **재사용:** C4 참조. 없으면 6–7줄을 이름표 `???`와 내레이션만으로 처리
- **일치:** C4의 머리색·옷·앞치마 끈·체형·크기
> Same character, same clothes and same framing as the reference image, but seen from behind, turned three-quarters away so his face cannot be seen: grey-streaked dark hair, apron straps crossing his back, rolled sleeves. Soft light from the upper left. Same style.

### A1 `annex_street.png`
- **경로·사용:** case_11/ · Case 11 Intro 1–2
- **크기·투명:** 1536×1024 · 불투명
- **재사용:** 해당 장소의 기존 이미지 없음
- **일치:** A2의 시대감
- **우선순위:** 3
- **측정:** 문 옆 명판 사각형(코드 `Archive Annex`)
> Impressionist oil painting with visible brushstrokes, soft late-afternoon light. A quiet narrow street in old Paris, cream stone buildings with tall shuttered windows. In the centre, a small dark wooden door with a blank brass name plate beside it. On the far right edge, part of a great old church tower rises above the roofs, painted loosely. No people in focus, no cars, no text, no signs with words. Calm and mysterious, restrained palette of cream, slate blue and soft gold. The door within the central 60% of the frame. 3:2 landscape.

- **1차 납품본(v1.1): 교체함.** 배경에 사크레쾨르(몽마르트르의 흰 돔 성당)가 그려져 있어, Case 02·08에서 익힌 "언덕 위 흰 교회 = 몽마르트르"로 읽혔다.
- **2차 납품본(v1.2, 2026-10-26): 승인.** 1차의 문·명판·담쟁이·자갈길 구도를 유지하고, 뒤의 탑을 **고전 양식의 네모난 석조 탑**(층마다 둥근 아치 창과 기둥, 꼭대기 평평한 난간)으로 바꿨다. 중간본의 고딕 탑(노트르담과 닮음)은 쓰지 않았다.
- **재생성 조건(추가):** 돔·흰 바실리카·언덕 금지. 평지 골목, 끝에 **네모난 석조 교회 탑** 일부. 1차 납품본의 문·담쟁이·명판·자갈길 구도는 유지해도 좋다.

### A2 `annex_reading_room.png`
- **경로·사용:** case_11/ · Case 11 모든 대화 배경, Intro 3–8, M2, Final
- **크기·투명:** 1536×1024 · 불투명
- **재사용:** 불가(`case_06/archive_room.png`는 Louvre)
- **일치:** A3 장부 표지색, A4 선반 나무색
- **우선순위:** 1
- **조건:** 초상화가 겹치는 **가운데 40%는 차분하게**
> Painterly vintage storybook interior: a quiet archive reading room. Tall dark wooden shelves reach the ceiling, full of old boxes and bound books. A long worn wooden table runs across the middle with one empty chair. Dusty afternoon light from a high window on the left. The centre of the picture is calm, with no busy details. No people, no text, no clocks, no emblems, no bags. 3:2 landscape.

### A3 `big_book_torn.png`
- **경로·사용:** case_11/ · M1 찢긴 장부와 문지르기, M3 서명 다시 보기(clue `s2_ep11_c1`)
- **크기·투명:** 1536×1024 · 투명
- **재사용:** 불가(`case_10/trial_log_open.png`는 찢김이 없는 다른 책)
- **일치:** A2 선반의 장부 표지색. 문지른 서명 영역은 A7 크기에 맞음
- **우선순위:** 1
- **조건**
  - 제본선 왼쪽에 **찢긴 장의 들쭉날쭉한 밑동**이 분명할 것
  - 오른쪽 장은 **얼룩 없이 균일한 크림색**(흑연 효과용)
  - 오른쪽 장 위쪽 3분의 1 안에 **두 줄 + 서명 한 줄이 들어갈 여백**(괘선 3줄)
- **측정:** 문지르기 영역 3개(줄 1, 줄 2, 서명), 찢긴 밑동 위치
> A thick old register book lying open, seen from directly above. Two cream pages with faint ruled lines, completely blank. In the centre binding, just left of the spine, the narrow ragged stub of a torn-out page is clearly visible. Brown cloth cover edges. The right page is clean and even with no stains, with plenty of empty space near the top. No text, no numbers, no marks. Isolated on a transparent background. 3:2 landscape.

### A4 `annex_shelves.png`
- **경로·사용:** case_11/ · M1 `Find Box 9`(상자 3·9·12·19, 정답 9)
- **크기·투명:** 1536×1024 · 불투명
- **재사용:** 불가
- **일치:** A2 빛·나무, A5 상자 모양
- **우선순위:** 2
- **조건:** 각 상자에 **크고 빈 종이 라벨**(화면 폭 8% 이상). 숫자는 코드
- **납품본 기준(v1.1 확정):** 상자 **4개**(위 1, 가운데 2, 아래 1). 번호 **3·9·12·19**는 이미지에 새기지 않고 Flutter가 각 라벨 위에 표시한다. 어느 상자에 어느 번호를 붙일지는 구현 때 정한다(9번이 한눈에 정답으로 보이지 않게 섞는다)
- **측정:** 라벨 4개 사각형, 탭 영역(최소 48×48)
> Painterly storybook view of dark wooden archive shelves seen straight from the front, warm dim light. Three plain cardboard archive boxes stand on the shelves, each with a large blank paper label on its front. A few old books between them. No text, no numbers, no people, no emblems. 3:2 landscape.

### A5 `box9_open.png`
- **경로·사용:** case_11/ · M1 열린 9번 상자(3쪽)
- **크기·투명:** 1254×1254 · 투명
- **재사용:** 불가
- **일치:** A4 상자. 뚜껑의 밀랍 원에 `office_stamp.png`가 들어가는 크기
- **우선순위:** 2
- **조건:** 상자 안에 서류철 하나(3쪽), 열린 뚜껑에 **빈 보라색 밀랍 원**
- **측정:** 밀랍 원, 서류철 탭 영역
> An open cardboard archive box seen slightly from above. Inside lies a single paper folder. On the open lid, a blank round patch of dull purple sealing wax with nothing pressed into it. Warm soft light. No text, no numbers, no symbols. Isolated on a transparent background. Square.

### A6 `visitor_book_open.png`
- **경로·사용:** case_11/ · Intro 9줄(서명 장면), M3 서명 비교
- **크기·투명:** 1536×1024 · 투명
- **재사용:** 불가
- **일치:** A7–A9가 서명 칸 높이의 80% 안에 들어감
- **우선순위:** 1
- **조건:** 오른쪽 장에 빈 서명 줄 4개(방문자 A, Victor, 방문자 B, 탐정). 왼쪽 장은 읽을 수 없는 흐린 잉크 질감
> An old visitor book lying open, seen from directly above. Cream pages; on the right page, four empty ruled lines for signatures; on the left page, only very faint unreadable old ink marks. Dark green cloth cover edges and a thin burgundy ribbon. No readable text, no names, no numbers. Isolated on a transparent background. 3:2 landscape.

### A7 `victor_signature.png`
- **경로·사용:** case_11/ · 방명록(Intro), 찢긴 장부 쪽의 눌린 자국(M1, 코드가 흑연 질감으로 표시), 투사지 판정(M3)
- **크기·투명:** 1024×384 · 투명
- **재사용:** 불가
- **일치:** 세 특징 ① 크게 말린 **곡선 V** ② 서명 전체 아래 **긴 밑줄** ③ 끝의 **점 하나**. 나머지는 읽히지 않는 흘림체(실명 철자가 보이지 않을 것). 흑연 변환 후에도 세 특징이 보이도록 **선이 굵고 단순할 것**
- **우선순위:** 1
> A single handwritten signature in dark blue-black fountain-pen ink on a transparent background: a large looping curly capital V, then quick flowing script that cannot be read, a long straight underline beneath the whole signature, and one small round dot at the very end. Bold, simple strokes, no paper. Wide landscape.

### A8 `signature_old_a.png`
- **경로·사용:** case_11/ · M3 미끼(V 모양이 다름)
- **크기·투명:** 1024×384 · 투명
- **재사용:** 불가
- **일치:** A7과 같은 펜, 조금 바랜 색. **곧은 V** + 밑줄 있음 + 점 없음
- **우선순위:** 2
> A single old handwritten signature in faded blue-black ink on a transparent background: a sharp straight capital V with no loop, quick unreadable script, a long underline beneath, no dot. Wide landscape.

### A9 `signature_old_b.png`
- **경로·사용:** case_11/ · M3 미끼(밑줄·점이 없음)
- **크기·투명:** 1024×384 · 투명
- **재사용:** 불가
- **일치:** 곡선 V + **밑줄 없음 + 점 없음**
- **우선순위:** 2
> A single old handwritten signature in faded blue-black ink on a transparent background: a curly looping capital V, quick unreadable script, no underline and no dot. Wide landscape.

### A10 `victors_paper.png`
- **경로·사용:** case_11/ · M2 Victor's paper(본문 2줄은 코드), Final 2번 증거
- **크기·투명:** 1024×1536 · 투명
- **재사용:** 불가
- **일치:** Page 3(누런 옛 종이, 코드 `Paper`)과 **한눈에 다른** 단정한 새 서류. 아래 도장 원에 `office_stamp.png`가 맞는 크기(M2에서 Case 07 슬립의 도장과 겹쳐 비교)
- **우선순위:** 1
- **조건:** 연한 파란 표지를 위로 접어 올린 보고서, 깨끗한 크림색 한 장, 위쪽 빈 머리글 칸, **아래쪽 가운데 빈 도장 원**
- **측정:** 머리글, 본문 2줄, 도장 원
> A neat official report lying flat, seen from above, portrait: a crisp pale blue card cover folded back at the top, one clean cream page with faint ruled lines, an empty header box, and an empty circle near the bottom centre for a stamp. Tidy and new-looking. No text, no numbers, no stamp, no emblem. Isolated on a transparent background. Portrait 2:3.

### B1 `arts_metiers_hall.png`
- **경로·사용:** case_12/ · Case 12 Intro 1–2
- **크기·투명:** 1536×1024 · 불투명
- **재사용:** 불가
- **일치:** A1과 같은 붓질, B2 문 안쪽의 빛
- **우선순위:** 3
> Impressionist oil painting with visible brushstrokes, soft cool morning light. A tall old museum hall full of historic machines: stone columns, high windows, glass cases, silhouettes of old engines and brass instruments, painted loosely. At the back right, a small door behind a red velvet rope. No people in focus, no text, no clock faces. Quiet and grand. 3:2 landscape.

### B2 `old_machine_room.png`
- **경로·사용:** case_12/ · Case 12 모든 대화 배경, M2 작업대, M3, Final, 엔딩 1–9줄
- **크기·투명:** 1536×1024 · 불투명
- **재사용:** 불가
- **일치:** B11과 같은 방. 받침대 윗면이 화면 높이의 약 62%(B3 자리)
- **우선순위:** 1
- **조건**
  - 가운데 빈 받침대
  - 오른쪽 위 벽에 **빈 시계 고리**(벽시계는 코드)
  - 왼쪽 작업대 위에 **펼친 가죽 도구 롤**(작은 도구 몇 개, B10을 그 위에 겹침)
- **측정:** 받침대 윗면 선, 벽시계 원, 도구 롤의 빈 칸
> Painterly vintage storybook interior: a small quiet museum room for old machines. In the centre, an empty low wooden plinth under a soft pool of light from above. On the upper right wall, an empty round brass hook where a wall clock would hang. On the left, a clockmaker's workbench with a green-shaded lamp and an open leather tool roll holding a few small tools, with one empty slot. Stone walls, dust in the light. No machine, no people, no text, no clock faces. 3:2 landscape.

### B3 `chronos_machine.png`
- **경로·사용:** case_12/ · Intro 3–5, M1 옆문, M3 조작판
- **크기·투명:** 1254×1254 · 투명
- **재사용:** 불가. Case 03 장치·Case 10 드럼과 다른 실루엣
- **일치:** B4–B7과 같은 황동, B11과 같은 실루엣
- **우선순위:** 1
- **조건**
  - 위쪽 가운데 큰 바퀴 홈(B5) + 그 아래 작은 창
  - 아래에 작은 흰 시계판 3개(바늘·숫자 없음)
  - 왼쪽 레버 홈(B6), 바퀴 옆 핀 구멍(B7), 옆면 작은 문(M1)
- **측정:** 각 홈·창·시계판 3개·옆문
> An antique brass clock machine on a small wooden base, seen from the front, slightly from above. At the top centre, a large empty circular recess for a big wheel, with a small empty rectangular window below it. Along the bottom, three small plain white clock faces in a row with NO hands and NO numbers. On the left, an empty slot for a lever; beside the recess, a small round pin hole; a small closed door on the right side panel. Warm, slightly aged polished brass. No text, no numbers, no symbols, no clock hands. Isolated on a transparent background. Square.

### B4 `machine_wheel_row.png`
- **경로·사용:** case_12/ · M1 바퀴 비교(증명 ①)
- **크기·투명:** 1536×1024 · 투명
- **재사용:** 기준 바퀴 크롭을 **참조 이미지로 함께 입력**
- **일치:** ★ Émile's wheel(가운데). 왼쪽은 **같은 크기·살 6개**, 오른쪽은 **같은 모양(살 4개)·확실히 큰 크기**. 차이는 각각 하나씩만 둔다
- **우선순위:** 1
- **측정:** 칸 3개 탭 영역, 가운데 칸 옆 이름표 자리(코드)
> The open side of an antique brass machine, seen from the front: three compartments in a row, each holding one brass gear wheel on a small axle. The middle wheel is small and looks exactly like the reference wheel: four thick straight spokes crossing like an X, a raised round hub with a domed brass axle cap, about thirty small square teeth and a thin rim. The left wheel is the same small size but has six spokes. The right wheel has the same four-spoke shape but is clearly much larger. Warm light, aged brass. No text, no numbers. Isolated on a transparent background. 3:2 landscape.

### B5 `machine_big_wheel.png`
- **경로·사용:** case_12/ · M3 돌리는 큰 바퀴(코드 회전)
- **크기·투명:** 1254×1254 · 투명
- **재사용:** B3 참조
- **일치:** B3 바퀴 홈 지름, 같은 황동. **중심이 캔버스 정중앙**. Émile's wheel과 헷갈리지 않도록 **살 12개**
- **우선순위:** 2
> A large brass wheel seen exactly from the front, perfectly centred: twelve straight spokes, a smooth rim with one small round handle knob near the edge. Slightly aged brass. No numbers, no text. Isolated on a transparent background. Square.

### B6 `machine_lever.png`
- **경로·사용:** case_12/ · M3 STOP/START 레버(코드 회전)
- **크기·투명:** 512×1024 · 투명
- **재사용:** B3 참조
- **일치:** B3 레버 홈. 회전축이 아래 가운데
- **우선순위:** 2
> A single brass machine lever standing upright, seen from the front: a straight brass arm with a round dark wooden knob on top and a small round pivot at the bottom. Slightly aged. No text. Isolated on a transparent background. Tall portrait.

### B7 `machine_pin.png`
- **경로·사용:** case_12/ · M3 `Push the pin to fix it.`
- **크기·투명:** 512×512 · 투명
- **재사용:** B3 참조
- **일치:** B3 핀 구멍 지름
- **우선순위:** 2
> A short brass locking pin seen from the front, slightly from above: a thick round head with a small ring and a short shaft. Slightly aged brass. No text. Isolated on a transparent background. Square.

### B8 `watch_back_closed.png`
- **경로·사용:** case_12/ · M2 시작. 뒷면의 `PARIS`는 코드로 새긴다(Season 1 `ep12_e4`: `On the back: PARIS.`)
- **크기·투명:** 1254×1254 · 투명
- **재사용:** `shared/objects/pocket_watch.png`를 참조 이미지로 사용(케이스·용두·고리·사슬)
- **일치:** pocket_watch.png와 같은 시계, B9와 같은 위치·크기
- **우선순위:** 1
- **측정:** 각인 자리, 뚜껑 홈, 뚜껑 원
> The same antique brass pocket watch as the reference image, now lying face down to show its back: a smooth domed brass back cover with a blank oval engraving area in the centre and a tiny notch on the rim where a tool could open it. The same crown, bow ring and chain. Warm soft light. No text, no numbers. Isolated on a transparent background. Square.

### B9 `watch_back_open.png`
- **경로·사용:** case_12/ · M2 열린 시계(증명 ②)
- **크기·투명:** 1254×1254 · 투명
- **재사용:** B8과 기준 바퀴 크롭을 참조 이미지로 사용
- **일치:** B8 시계 전체, ★ Émile's wheel(B4 가운데와 같은 모양)
- **우선순위:** 1
- **조건:** 뒷뚜껑이 경첩으로 열려 무브먼트가 보인다. 다른 톱니들 사이에서 **Émile's wheel이 가장 밝고 잘 보이는 자리**에 있을 것. **각인·글자·표식 금지**(답을 적어 두는 장치 금지)
- **측정:** Émile's wheel 중심·반지름
> The same pocket watch as the reference image with its back cover swung open on its hinge, showing the brass movement inside: small gears and a balance wheel. Among them, in a clear and well-lit spot, one small wheel looks exactly like the reference wheel: four thick straight spokes crossing like an X, a raised round hub with a domed axle cap, about thirty small square teeth. No engravings, no marks, no text, no numbers. Warm soft light. Isolated on a transparent background. Square.

### B10 `emile_gear_stamp.png`
- **경로·사용:** case_12/ · M2 증명 ③(종이에 눌러 톱니 자국을 찍는 도구. 자국은 코드 `InkGlyph.gear`)
- **크기·투명:** 512×1024 · 투명
- **재사용:** 불가
- **일치:** ★ 끝면의 톱니가 Notebook `s2_ep01_c3` 아이콘과 같은 **톱니 8개** 실루엣. B2 도구 롤의 빈 칸에 맞는 크기·재질
- **우선순위:** 1
- **조건:** 손잡이가 위, 끝이 아래인 작은 금속 각인 도장. **끝면을 약간 아래에서 비스듬히 보여 톱니 8개가 보이게**
> A small old watchmaker's metal punch stamp standing upright: a short dark wooden handle on top and a steel shaft below, tilted slightly so that its flat end can be seen, and the end is shaped like a tiny gear with exactly eight teeth. Worn, well-used, slightly oily. No text, no numbers. Isolated on a transparent background. Tall portrait.

### B11 `finale_morning.png`
- **경로·사용:** case_12/ · 엔딩 10–14줄(3쪽 보존 장면)
- **크기·투명:** 1536×1024 · 불투명
- **재사용:** 불가
- **일치:** B2의 방, B3의 기계 실루엣. 유리 상자 속 종이는 Page 3처럼 **누런 옛 종이 한 장**
- **우선순위:** 1
- **조건:** 아침 햇살, 받침대 위 기계, 그 앞 **작은 유리 진열 상자 속 종이 한 장**, 위쪽 30%에 여백(마지막 문장용). 사람·축하 장식·경찰 없음
> Impressionist oil painting with visible brushstrokes: the same small museum room for old machines at early morning, warm golden sunlight streaming through a high window. On the wooden plinth stands an antique brass clock machine with three small plain white dials. In front of it, a small glass display case holds one old yellowed sheet of paper, safe and clearly visible. Dust glows in the light. Calm, quiet, hopeful. No people, no text, no clock hands. Soft open space in the upper third. 3:2 landscape.

---

## 4. 납품 후 확인
| 확인 | 기준 |
|---|---|
| 표정 세트 | Victor 3장, Émile 2장(+ 뒷모습): 얼굴·옷·구도 동일, 얼굴 중심 ±1%. 360×640에서 대화창이 얼굴을 가리지 않음 |
| Émile 시곗줄 | 빈 고리. *(v1.1: 납품본은 시곗줄이 주머니로 이어지지만 시계 자체는 보이지 않으므로 그대로 사용 — 사용자 결정)* |
| ★ Émile's wheel | 기준 바퀴, B4 가운데, B9 안쪽의 **살 4개(X자)·볼록한 축 마개·약 30개 네모 톱니**가 같음. 360폭에서 비교 가능 |
| 바퀴 미끼 | B4 왼쪽 = 살 6개(크기 같음), 오른쪽 = 크기만 큼 |
| 큰 바퀴 | B5는 살 12개(Émile's wheel과 혼동 없음) |
| 톱니 도장 | B10 끝면 톱니 8개 = `InkGlyph.gear` 실루엣 |
| 시계 | B8·B9 = `pocket_watch.png`와 같은 시계. B9에 각인·글자 없음 |
| 서명 | A7만 세 특징을 모두 가짐. 흑연 변환 후에도 세 특징이 보임 |
| 두 서류 | A10(파란 표지, 새것) ↔ Page 3(누런 옛 종이)가 한눈에 다름 |
| 도장 자리 | A5 밀랍 원, A10 도장 원에 `office_stamp.png`가 맞음 |
| 기계 | B3 실루엣이 Case 03·10 장치와 다름. B5–B7이 B3 홈에 맞음 |
| 보존 장면 | B11 유리 상자 속 종이가 Page 3과 같은 느낌 |
| 글자 | 모든 이미지에 읽을 수 있는 글자·숫자 없음 |
| 투명도 | 투명 항목은 바깥 알파 0 |
| 워터마크 | 모서리 확인 |

## 5. 에셋 관련 남은 선택
- **[OPEN-A]** `clockmaker_master.png`를 Émile 복장 참고로 쓸지. 기본안은 쓰지 않는다.
- ~~**[OPEN-B]** `emile_back.png`를 만들지.~~ → 납품됨(v1.1).
- **[OPEN-C]** 탐정(YOU) 대사에 기존 탐정 아바타를 작게 보여 줄지. 이 경우 신규 이미지는 필요 없다.

---

## 6. 납품 검수 기록

### 6.1 Case 11 1차 납품 (2026-10-26) — 16장
| 파일 | 위치 | 실제 크기 · 배경 | 결과 | 메모 |
|---|---|---|---|---|
| `victor_base.png` | characters/ | 1122×1402 · 불투명 | 승인 | — |
| `victor_nervous.png` | characters/ | 1122×1402 · 불투명 | 승인 | 표정·안경 든 손만 다름 |
| `victor_sad.png` | characters/ | 1122×1402 · 불투명 | 승인 | 표정·손만 다름 |
| `emile_base.png` | characters/ | 1122×1402 · 불투명 | 승인 | 시곗줄이 주머니로 이어짐 → 그대로 사용(시계는 보이지 않음) |
| `emile_sad.png` | characters/ | 1122×1402 · 불투명 | 승인 | 같은 시곗줄 |
| `emile_back.png` | characters/ | 1122×1402 · 불투명 | 승인 | 얼굴 보이지 않음 |
| `annex_reading_room.png` | case_11/ | 1536×1024 · 불투명 | 승인 | — |
| `annex_street.png` | case_11/ | 1536×1024 · 불투명 | 1차 교체 → **2차 승인(v1.2)** | 1차: 배경에 사크레쾨르. 2차: 고전 양식 네모 석조 탑, 돔 없음 |
| `annex_shelves.png` | case_11/ | 1536×1024 · 불투명 | 승인 | 상자 4개 → 번호 3·9·12·19(코드 표시) |
| `big_book_torn.png` | case_11/ | 1536×1024 · 투명 | 승인 | 찢긴 밑동 분명 |
| `box9_open.png` | case_11/ | 1254×1254 · 투명 | 승인 | 미리보기의 붉은 점은 알파 0 영역의 색값(화면에 안 나옴) |
| `victors_paper.png` | case_11/ | 1024×1536 · 투명 | 승인 | — |
| `visitor_book_open.png` | case_11/ | 1536×1024 · 투명 | 승인 | 서명 줄 4개 |
| `victor_signature.png` | case_11/ | 1983×793 · 투명 | 승인 | 곡선 V + 밑줄 + 점 |
| `signature_old_a.png` | case_11/ | 2155×730 · 투명 | 승인 | V만 다름 |
| `signature_old_b.png` | case_11/ | 2154×730 · 투명 | 승인 | 밑줄·점만 다름 |

- **투명 이미지 공통:** 바깥 알파 0 확인. 물건 부분 알파는 252–253(약 1% 비침, 눈으로 구별 안 됨)이라 그대로 사용한다.
- **서명 3종의 크기**는 명세(1024×384)보다 크지만 비율이 비슷하고 코드가 크기를 맞추므로 그대로 사용한다.
- **Case 11 이미지 16장 모두 승인(v1.2).** 남은 이미지는 Case 12의 11장.

### 6.2 Case 12 1차 납품 (2026-10-26) — 11장
| 파일 | 실제 크기 · 배경 | 결과 | 메모 |
|---|---|---|---|
| `old_machine_room.png` | 1536×1024 · 불투명 | 승인 | 빈 받침대, 빈 시계 고리, 작업대·녹색 램프, 빈 칸 있는 도구 롤 |
| `arts_metiers_hall.png` | 1536×1024 · 불투명 | 승인 | 빨간 줄로 막은 문(오른쪽 뒤) |
| `chronos_machine.png` | 1254×1254 · 투명 | 1차 수정 요청 → **2차 승인** | 1차: 왼쪽 레버 홈에 레버가 그려져 `machine_lever.png`와 겹침. 2차(편집본): 홈이 비어 있음, 나머지 동일. 앞면 오른쪽 문·시계판 가운데 구멍은 그대로 사용 |
| `machine_big_wheel.png` | 1254×1254 · 투명 | 승인 | 살 12개. 중심이 캔버스 가운데에서 약 6px 차이 → 구현 때 허브 중심 실측 |
| `machine_lever.png` | 1024×1536 · 투명 | 승인 | 명세(512×1024)와 비율 같음 |
| `machine_pin.png` | 1254×1254 · 투명 | 승인 | — |
| `machine_wheel_row.png` | 1536×1024 · 투명 | 승인 | 가운데 = 살 4개 X자(Clock III 바퀴), 왼쪽 = 살 6개, 오른쪽 = 크기만 큼 |
| `watch_back_closed.png` | 1254×1254 · 투명 | 승인 | `pocket_watch.png`와 같은 시계, 반짝이 표식 없음 |
| `watch_back_open.png` | 1254×1254 · 투명 | 1차 승인 → **2차 교체·승인** | 1차: 바퀴 살이 + 방향. 2차(편집본): 오른쪽 바퀴 살이 **X 방향**으로 `machine_wheel_row` 가운데 바퀴와 같음. 각인 없음 |
| `emile_gear_stamp.png` | 1024×1536 · 투명 | 승인 | 끝면 톱니 8개 |
| `finale_morning.png` | 1536×1024 · 불투명 | 승인 | 같은 방·같은 기계, 유리 상자 속 종이. 레버가 꽂힌 모습은 수리 후 장면이라 그대로 사용 |

- 투명 이미지 공통: 바깥 알파 0, 물건 부분 알파 252–253(Case 11과 같음, 그대로 사용).
- **Case 12 이미지 11장 모두 승인.** `watch_back_open.png`도 X 방향 수정본으로 교체했다.
- **Case 11·12 이미지 27장 완료.**
