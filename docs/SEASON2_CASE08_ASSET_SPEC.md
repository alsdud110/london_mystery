# Season 2 · Case 08 — The Painter's Last Sketch
## 이미지 에셋 제작 명세서 (v1.0 · 2026-10-23)

**기획 기준:** `docs/SEASON2_PARIS_STORY_BIBLE.md` v1.6 §6 Case 08, `docs/SEASON2_CASE08_SPEC.md`
**저장 폴더:** `assets/seasons/season_02_paris/cases/case_08/`
**원칙:** 아래 이미지는 사용자가 제작한다. 임시 이미지나 도형으로 대체하지 않는다. 받은 뒤 구현 단계에서 픽셀 좌표(찢김 모양, 대문, 가로등, 배지, 종이 위치 등)를 측정해 scene 데이터에 기록한다. Case 05–07과 같은 방식이며, 런타임에 픽셀을 자르거나 측정하지 않는다.

---

## 0. 요약

### 신규 이미지 — 12장 (모두 필수)

| # | 파일 | 용도 | 크기 | 배경 |
|---|---|---|---|---|
| 1 | `corner_2.png` | M1 정답 모퉁이 (**기준 이미지**) | 1536×1024 (3:2) | 불투명 |
| 2 | `corner_1.png` | M1 오답: 배치 같음, dark green gate | 1536×1024 | 불투명 |
| 3 | `corner_3.png` | M1 오답: 좌우 반대 배치, black gate | 1536×1024 | 불투명 |
| 4 | `abbesses_square.png` | M1 장소(세 모퉁이 + 지하철 입구) | 1536×1024 | 불투명 |
| 5 | `drawing_bundle.png` | M1 해결 후 장면, M2 장소 | 1536×1024 | 불투명 |
| 6 | `torn_form_blank.png` | M3 펼친 종이, Final 겹치기 | 1536×1024 | 투명(종이만) |
| 7 | `folded_paper.png` | M3 시작(접힌 상태) | 1024×1024 (1:1) | 투명 |
| 8 | `sketch_morning_1_dark.png` | M2 그림 1 | 1536×1024 | 투명(종이만) |
| 9 | `sketch_morning_2_bag.png` | M2 그림 2 / Bag Sketch 증거 | 1536×1024 | 투명(종이만) |
| 10 | `sketch_morning_3_light.png` | M2 그림 3 / Final 1단계 판 | 1536×1024 | 투명(종이만) |
| 11 | `last_sketch_garden.png` | Case Closed Next Lead(→ Case 09) | 1536×1024 | 투명(종이만) |
| 12 | `paper_study.png` | #10 여백의 종이 확대 연필화(코드에서 #10 여백에 합성) | 1024×1024 | 투명 |

*(2026-10-23 변경)* #10에 여백 확대 그림을 함께 그리면 생성기가 연필화 대신 #6 사진을 붙여 넣는 문제가 반복되었다. 그래서 #10의 여백은 비워 두고, 종이 확대 연필화는 #12로 따로 만들어 코드에서 정해진 위치에 겹쳐 그린다. Case 07에서 도장을 슬립에 겹쳐 그린 것과 같은 방식이며, 런타임에 픽셀을 자르지 않는다.

선택 이미지는 없다. 배지 확대와 종이 확대는 그림 2·3의 **여백 연습 그림**에 포함되므로 따로 만들지 않는다.

### 기존 에셋 재사용 — 5장 (신규 제작 불필요)

| 파일 | 용도 |
|---|---|
| `case_07/abbesses_sketch.png` | Intro(Case 07 슬립 뒷면, `SlipBack` 레이아웃 그대로) |
| `case_07/office_stamp.png` | M3·Final 찢긴 종이의 도장. **같은 이미지를 겹쳐 그려서** Case 07 도장과 완전히 같게 함 |
| `case_07/amendment_slip_blank.png` | M3 Recall Card와 Final 보드의 Amendment Slip(기존 `AmendmentSlipView`) |
| `case_02/hidden_layer_sketch.png` | M1 Recall Card의 Hidden Sketch(기존 크롭 그대로) |
| `locations/map/paris_mystery.png` | Next Lead 지도. Luxembourg 궁전과 둥근 분수 연못이 이미 그려져 있음 |

### 검토했다가 채택하지 않은 최소화 방안
- **M1을 넓은 장면 1장으로만 처리:** 시점이 비스듬하면 "가로등이 대문 왼쪽"이라는 판정이 보는 각도에 따라 흔들린다. 정면 모퉁이 3장이 필요하다.
- **Corner 1을 Corner 2에서 대문 색만 바꿔 만들기:** 똑같은 장소가 두 번 나오면 부자연스럽다. 건물·나무는 다르게 하고 배치만 같게 한다. 시간이 부족하면 차선책으로 허용하되, 그 경우에도 건물 정면과 화분 정도는 바꾼다.
- **배지·종이 확대 이미지 별도 제작:** 여백 연습 그림으로 대체해 2장을 줄였다.

---

## 1. 생성 순서 (연속성 때문에 이 순서를 지킨다)

1. `corner_2.png` — Case 02 Hidden Sketch 구도에 맞춘 기준
2. `corner_1.png`, `corner_3.png` — corner_2를 참고 이미지로 사용
3. `abbesses_square.png` — 세 모퉁이가 1–3과 맞는지 확인
4. `drawing_bundle.png` — corner_2의 왼쪽 기둥
5. `torn_form_blank.png` — 찢김 모양 확정(이후 그림 3 여백 그림의 기준)
6. `folded_paper.png` — 5와 같은 종이
7. `sketch_morning_1_dark.png` — corner_2 구도의 연필화(**기본 판**)
8. `sketch_morning_2_bag.png`, `sketch_morning_3_light.png` — **7을 편집해서** 만든다(새로 생성하지 않음)
9. `last_sketch_garden.png` — 9번 그림의 가방과 배지를 참고 이미지로 사용

---

## 2. 공통 화풍

**A. 회화 장면 (#1–5)**
- 기준: `case_02/montmartre_street_real.png`, `case_02/canvas_c.png`
- 따뜻한 오후빛 대신 **맑은 낮빛**, 두꺼운 붓터치의 인상파풍, 크림색 석조, 담쟁이·꽃, 슬레이트 지붕, 멀리 언덕 위 Sacré-Cœur
- 사람 없음, 글자 없음, 현대 자동차·간판·로고 없음

**B. P.의 연필화 (#8–11)**
- 기준: `case_02/hidden_layer_sketch.png`(easel 위 연필 스케치), `case_07/abbesses_sketch.png`
- 크림색 스케치 종이 위 흑연. 해칭으로 명암을 넣고 색은 없음
- 종이 가장자리 밖은 투명(오려 낸 종이 한 장). 종이는 화면의 약 92%
- **종이 오른쪽 약 22%는 비워 둔 여백**(여백 연습 그림 자리). 본 그림은 왼쪽 약 78%에 들어간다

**C. 문서 (#6–7)**
- 기준: `case_07/amendment_slip_blank.png`(크림색 종이, 짙은 남색 이중 테두리, 머리글 띠)
- 인쇄된 테두리와 띠만 있고 **글자와 도장은 넣지 않는다**(코드에서 그림)

---

## 3. 이미지별 명세

### #1 `corner_2.png` — M1 정답 모퉁이 (기준 이미지)
- **경로:** `assets/seasons/season_02_paris/cases/case_08/corner_2.png`
- **사용:** M1 선택 페이지 2번 그림, 광장에서 돋보기로 연 정면 풍경
- **내용:** 모퉁이를 정면, 앉은 사람 눈높이에서 본 장면. `hidden_layer_sketch.png` 속 스케치와 **같은 배치**:
  - 화면 왼쪽: 낮은 석벽을 따라 **왼쪽 위로 올라가는 돌계단**(난간)
  - 계단 앞, 대문의 **왼쪽**: 오래된 주철 **가로등** 1개
  - 화면 가운데에서 약간 오른쪽: 짧은 돌길 끝, **네모난 돌기둥 두 개 사이의 철 대문**. 대문은 **검은색**(무광 흑철), 닫혀 있음
  - 대문 바로 **위쪽** 하늘: 언덕 위 **흰 교회(Sacré-Cœur)**
  - 양옆에 나무, 뒤로 크림색 건물
  - 왼쪽 기둥 아래쪽 돌 하나가 아주 약간 틈이 있음(눈에 띄지 않게)
- **반드시 포함:** 위 다섯 요소와 배치, 검은 대문, 흰 교회
- **반드시 제외:** 빨간 문, 사람, 글자·간판, 지하철 입구(광장 이미지에만), 새·동물, 그림자가 강한 극적 조명
- **화풍:** A
- **연속성:**
  - Hidden Sketch와 계단·가로등·대문·교회의 **좌우·위아래 관계가 같아야 함**(세부 모양은 같지 않아도 됨)
  - #8–10 연필화의 기준 구도
  - #4 광장 속 모퉁이 2
  - #5의 왼쪽 기둥
- **프롬프트:**
  > Impressionist oil painting with thick, visible brushstrokes, bright clear daylight, Montmartre, Paris. A quiet street corner seen straight on from a seated person's eye level. On the left, worn stone steps with an iron handrail climb up and to the left beside a low cream stone wall. In front of the steps, to the LEFT of the gate, stands one old black cast-iron street lamp. Slightly right of center, at the end of a short cobbled path, a closed wrought-iron gate painted matte BLACK stands between two square cream stone pillars. Directly ABOVE the gate, far up on the hill, the white domes of Sacré-Cœur against a blue sky with soft clouds. Leafy trees on both sides, cream stone houses with grey slate roofs behind. One stone near the bottom of the left pillar sits slightly loose. No people, no text, no signs, no red doors, no metro entrance. Same palette and brushwork as a sunny Montmartre street painting with ivy and flower pots. 3:2 landscape.

### #2 `corner_1.png` — M1 오답: 색만 다름
- **사용:** M1 선택 페이지 1번 그림, 광장 모퉁이 1
- **내용:** corner_2와 **같은 배치**(계단은 왼쪽, 가로등은 대문 왼쪽, 교회는 대문 위). 단 **대문은 짙은 초록색(dark bottle green)**. 건물 정면, 나무 모양, 화분, 계단 수는 corner_2와 다르게 해서 다른 장소로 보이게 한다.
- **반드시 제외:** 검은 대문, 파란 대문(Case 02 오답 캔버스 D와 혼동), 빨간 문, 사람, 글자
- **연속성:** 배치는 corner_2와 같고, 색과 소품은 다름. 연필로 그리면 corner_2와 구별이 어려워야 함(그래야 inscription이 필요해짐)
- **프롬프트:**
  > Same style and light as the reference painting (corner_2). A different Montmartre street corner seen straight on from eye level, with the SAME layout: stone steps climbing up to the left on the left side, one old black cast-iron street lamp to the LEFT of the gate, a wrought-iron gate between two square stone pillars slightly right of center, and the white domes of Sacré-Cœur directly ABOVE the gate. The gate is painted DARK BOTTLE GREEN, clearly green, not black, not blue. Different house fronts, different shutters, different trees and flower pots, a different number of steps. No people, no text, no red doors, no metro entrance. Impressionist oil painting with thick brushstrokes, 3:2 landscape.

### #3 `corner_3.png` — M1 오답: 배치가 다름
- **사용:** M1 선택 페이지 3번 그림, 광장 모퉁이 3
- **내용:** **좌우가 반대인 배치.** 계단은 화면 **오른쪽**에서 오른쪽 위로 올라가고, 가로등은 대문의 **오른쪽**, 대문은 가운데에서 약간 왼쪽. 대문은 **검은색**. 교회는 대문 위. 건물·나무는 corner_1·2와 다름.
- **주의:** corner_2를 그대로 좌우반전하지 않는다. 반전 티가 나고 교회 모양이 뒤집힌다. 새로 생성한다.
- **반드시 제외:** 빨간 문, 사람, 글자, 초록·파란 대문
- **프롬프트:**
  > Same style and light as the reference painting (corner_2). Another Montmartre street corner seen straight on from eye level, with a MIRRORED layout: stone steps with an iron handrail climb up and to the RIGHT on the right side; one old black cast-iron street lamp stands to the RIGHT of the gate; a matte BLACK wrought-iron gate between two square stone pillars sits slightly left of center; the white domes of Sacré-Cœur are directly above the gate. Different houses, trees and flower pots from the reference. No people, no text, no red doors, no metro entrance. Impressionist oil painting with thick brushstrokes, 3:2 landscape.

### #4 `abbesses_square.png` — M1 장소
- **사용:** M1 `scene_explore`의 장소 그림. 확대·이동하며 돋보기 3곳을 연다.
- **내용:** Abbesses 광장을 약간 높은 시점에서 본 넓은 장면. 오른쪽 앞에 **아르누보 양식의 지하철 입구**(녹색 주철 아치, 간판 패널은 **비워 둠**). 광장 가장자리에 **모퉁이 세 곳**이 서로 떨어져 보이며, 왼쪽부터 corner_1, corner_2, corner_3과 각각 같은 배치와 대문 색을 가진다. 회전목마나 카페 의자는 있어도 되지만 사람은 없다.
- **반드시 포함:** 지하철 입구(빈 간판), 구별 가능한 세 모퉁이, 멀리 언덕 위 Sacré-Cœur
- **반드시 제외:** 글자(ABBESSES 글자도 넣지 않음, 필요하면 코드에서 그림), 사람, 빨간 문
- **연속성:** 각 모퉁이의 가로등 좌우 위치와 대문 색이 #1–3과 **반드시** 일치해야 함
- **프롬프트:**
  > Impressionist oil painting, bright clear daylight, the small Place des Abbesses in Montmartre seen from slightly above. In the right foreground, an Art Nouveau metro entrance with curving green cast-iron arches and an EMPTY blank sign panel. Around the edge of the square, three separate street corners are visible, each with stone steps, one street lamp and an iron gate between two stone pillars: LEFT corner, steps on the left, lamp left of a dark green gate; MIDDLE corner, steps on the left, lamp left of a black gate; RIGHT corner, steps on the right, lamp right of a black gate. Sacré-Cœur's white domes rise on the hill in the distance. Trees, cream houses, slate roofs. No people, no text or letters anywhere, no red doors. Thick brushstrokes, 3:2 landscape.

### #5 `drawing_bundle.png` — M1 해결 후 / M2 장소
- **사용:** M1 transition 그림(`Behind it: a bundle of drawings`), M2 시작 장소
- **내용:** corner_2의 **왼쪽 돌기둥** 아래를 가까이서 본 장면. 헐거운 돌이 빼내져 옆에 놓여 있고, 기둥 안 빈 공간 앞에 **끈으로 묶인 종이 묶음**(크림색 스케치 종이 몇 장, 반쯤 풀린 끈, 작은 갈색 종이 꼬리표)이 놓여 있다. 뒤로 검은 대문 일부가 흐리게 보인다.
- **반드시 제외:** 그림의 내용이 보이는 것(맨 윗장은 뒷면이나 빈 면), 글자(꼬리표 글자는 코드에서), 사람·손
- **연속성:** 기둥 돌의 색과 질감, 검은 대문은 corner_2와 같음
- **프롬프트:**
  > Impressionist oil painting, close-up at the base of a square cream stone gate pillar (the left pillar of a black wrought-iron gate, slightly blurred behind). One loose stone has been pulled out and rests on the cobbles; in the dark gap inside the pillar sits a small bundle of cream sketch papers tied with thin string, the string half undone, a small blank brown paper tag on the string. Only the blank back of the top sheet is visible. Soft daylight, ivy at the edge. No people, no hands, no text. Thick brushstrokes, 3:2 landscape.

### #6 `torn_form_blank.png` — 찢긴 시간 변경 종이 (펼친 상태)
- **사용:** M3 비교 화면, Final 1단계 겹치기, Matching Seal·Torn Hour 증거 그림
- **내용:** `amendment_slip_blank.png`와 **같은 양식의 종이**(크림색, 짙은 남색 이중 테두리, 위쪽 머리글 띠, 띠 아래 가로 구분선). 다음과 같이 찢겨 있다.
  - **위쪽 가장자리의 V자 찢김:** 가운데보다 왼쪽(왼쪽에서 약 40% 지점)에서 시작해 깊이 패인 V. 꼭짓점이 종이 높이의 약 55%까지 내려온다. V의 왼쪽 팔은 머리글 띠에서 `FILE` 글자가 들어갈 자리(띠 왼쪽 1/3)의 **바로 오른쪽**을 지나야 한다.
  - **오른쪽 가장자리 전체**가 거칠게 찢겨 원래 양식의 오른쪽 약 30%가 없다.
  - **십자 모양 접힌 자국**(가로 1, 세로 1, 네 번 접힘)
  - 오른쪽 아래, 찢긴 가장자리 안쪽에 **도장이 들어갈 빈 자리**(지름 약 종이 높이의 28%)
  - 계단 먼지 같은 옅은 회색 얼룩 하나(왼쪽 아래)
- **반드시 제외:** 글자, 숫자, 도장, 이름, 날짜, 로고. 글자(`FILE`, `:00 →`)와 도장(`office_stamp.png`)은 코드에서 그린다.
- **배경:** 투명(종이 바깥)
- **연속성:**
  - 이 V자·오른쪽 가장자리·접힌 자국·도장 자리가 #10 그림 3 여백 확대 그림의 **기준**
  - #7 접힌 종이와 같은 종이
  - 테두리 색과 두께는 Case 07 슬립과 같음
- **측정할 것(구현 시):** 종이 윤곽, V 꼭짓점, `FILE` 자리, `:00 →` 자리(V 꼭짓점 바로 오른쪽), 도장 자리
- **프롬프트:**
  > A single sheet of aged cream paper printed with a dark navy double-line border and a header band across the top with a thin rule under it, the same official form design as the reference slip (amendment_slip_blank). The paper is TORN: a deep sharp V-shaped tear comes down from the top edge, starting about 40% from the left, its point reaching a little past the middle of the sheet; the whole right edge is ripped off roughly, so about a third of the form is missing on the right. A cross of soft fold creases (folded in four). An empty space in the lower right for a stamp. One faint grey smudge of dust at the lower left. Absolutely no text, no numbers, no stamp, no logo. Flat, evenly lit, straight-on view, isolated on a transparent background, 3:2 canvas.

### #7 `folded_paper.png` — 접힌 종이
- **사용:** M3 시작, 펼치기 전 상태
- **내용:** #6 종이를 네 번 접어 작게 만든 모습. 바깥 면에 남색 테두리 일부와 거친 찢김 가장자리 일부가 보이고, 안쪽 도장의 보라색이 아주 희미하게 비친다. 작은 종이 클립에 손바닥 크기의 메모지(빈 메모, 글자는 코드에서)가 끼워져 있다.
- **반드시 제외:** 읽을 수 있는 글자, 도장 전체 모습
- **배경:** 투명
- **연속성:** 종이 색, 테두리, 찢긴 가장자리가 #6과 같음
- **프롬프트:**
  > The same torn cream form paper (reference torn_form_blank) folded in four into a small rectangle, seen from above. A bit of the navy double border and part of a rough torn edge show on the outside; a faint purple tint shows through the paper where a stamp is inside. A small blank note slip is held to it with a little metal paper clip. No readable text. Soft even light, isolated on a transparent background, square canvas.

### #8 `sketch_morning_1_dark.png` — M2 그림 1 (기본 판)
- **사용:** M2 순서 놓기와 겹쳐 보기
- **내용:** P.가 corner_2를 **같은 시점**에서 그린 흑연 스케치(본 그림은 종이 왼쪽 78%, 오른쪽 22%는 빈 여백).
  - **하늘: 진한 빗금 해칭, 작고 흰 별 몇 개**(빈 점)
  - **가로등: 켜짐.** 등 둘레에 빛 번짐(해칭을 지워 낸 밝은 원)
  - 대문: 닫힘(짙은 해칭)
  - 계단: 비어 있음. 아래쪽 계단 두세 단이 잘 보이게
  - 인물 없음, 종이 없음, 여백 비어 있음
  - 그림자: 뚜렷한 그림자 없음
- **연속성:** 배치는 corner_2와 Hidden Sketch를 따른다. **#9·#10은 이 이미지를 편집해서 만든다.** 종이 윤곽, 본 그림의 위치와 크기, 계단, 대문, 기둥, 가로등, 교회는 세 장에서 **픽셀 단위로 같아야 한다.**
- **배경:** 투명(종이 바깥)
- **프롬프트:**
  > A graphite pencil sketch on a sheet of cream sketch paper, the same style as the reference pencil sketch (hidden_layer_sketch). The drawing fills only the LEFT 78% of the sheet; the right 22% is blank paper. It shows the street corner from the reference painting (corner_2), from the same viewpoint: stone steps climbing up to the left, an old street lamp to the left of the gate, a closed wrought-iron gate between two square stone pillars, the domes of Sacré-Cœur above. It is before dawn: the sky is filled with dense dark cross-hatching with a few small white stars left unshaded; the street lamp is LIT, with a soft bright halo erased out of the hatching around it. The gate is closed, the steps are empty, no people. No cast shadows. No text, no signature. Isolated sheet on a transparent background, 3:2 canvas.

### #9 `sketch_morning_2_bag.png` — M2 그림 2 / Bag Sketch
- **사용:** M2, Bag Sketch 증거 그림, Next Lead의 가방 비교 기준
- **제작:** **#8을 편집한다.** 아래만 바꾸고 나머지는 그대로 둔다.
  - **하늘:** 빗금이 옅어짐, 별 없음, 교회 뒤 지평선이 밝아짐
  - **가로등:** 여전히 **켜짐**(빛 번짐은 #8보다 약간 작게)
  - **대문:** 안쪽으로 **열림**
  - **인물:** 열린 대문에서 나와 돌길을 건너 **왼쪽 계단의 아래에서 두 번째 단**을 오르고 있음(#8 확정 구도 기준: 대문은 길과 같은 높이, 계단은 왼쪽 위로 올라감). **뒷모습**, 챙 있는 모자와 긴 코트, 얼굴이 전혀 보이지 않음. 몸 오른쪽(보는 사람 쪽)에 **납작한 직사각형 서류 가방**(손잡이 없이 어깨끈, 앞 덮개에 **버클 2개**). 덮개는 **닫혀 있고**, 가방이 꽉 차서 **덮개 아래로 종이 모서리 2–3개가 삐져나옴**. 덮개 가운데에 작은 **방패 모양 배지**가 보는 사람 쪽을 향함(덮개를 열면 배지가 가려지므로 닫힌 덮개 + 삐져나온 종이로 확정)
  - **여백(오른쪽 22%)의 배지 확대 그림:** 방패 모양, **테두리를 따라 작은 잎**이 둘러져 있고, 가운데는 **흐릿한 문지름**(무엇인지 알 수 없음). 가방 쪽으로 짧은 화살표 선 하나(글자 없음)
- **반드시 제외:** 얼굴, 옆얼굴, 머리카락 색 단서, 배지 가운데의 시계·바늘·글자, 이름, 계단 위 종이
- **배지 규칙(Case 09, 11–12 재사용):** 방패 윤곽 + 테두리 잎 + 가운데 불분명. 이 세 가지가 #11에서 **같은 모양**이어야 한다.
- **프롬프트 (이미지 편집, 원본 #8):**
  > Edit this pencil sketch, keeping the paper, the composition, the steps, pillars, lamp and church exactly in place. Change only: lighten the sky hatching to a pale dawn grey, remove the stars, and brighten the horizon behind the domes; keep the street lamp lit, with a slightly smaller halo; swing the gate open inward. Add one figure who has just come out of the open gate and is now climbing the stone steps on the left, standing on the SECOND step from the bottom, seen completely from BEHIND: wide-brimmed hat, long coat, no face visible at all. At the figure's right side, facing us, hangs a FLAT rectangular document bag on a shoulder strap, with two buckles on its front; the flap is CLOSED, but the bag is so full that two or three corners of paper stick out from under the flap. In the middle of the flap, a small SHIELD-shaped badge. In the blank right margin of the sheet, add a small close-up study of the badge: a shield outline with a ring of tiny leaves along its edge and an unclear smudged centre, with one short pencil arrow pointing toward the bag. Same graphite style, no text.

### #10 `sketch_morning_3_light.png` — M2 그림 3 / Final 1단계 판
- **사용:** M2, Final 1단계(실물 종이를 여백 확대 그림에 겹침), Torn Hour 증거 그림
- **제작:** **#8을 편집한다**(#9가 아님. 인물과 배지 연습 그림이 섞이지 않게).
  - **하늘:** 빗금 없음, 흰 하늘, 구름 윤곽 몇 개
  - **가로등: 꺼짐**(빛 번짐 없음, 유리 안 해칭)
  - **대문: 열림**(#9와 같은 각도)
  - 인물 없음
  - **계단 맨 아랫단, #9에서 인물이 밟고 지나간 자리:** 작은 종이 한 장(V자 찢김이 보일 정도). 대문에서 계단으로 가는 길 위에 있어야 함
  - **여백의 종이 확대 그림:** #6 종이를 **위에서 본 그대로** 연필로 옮긴 그림. 위쪽 V자 찢김(왼쪽에서 40%), 거친 오른쪽 가장자리, 십자 접힌 자국, 오른쪽 아래 **동그란 도장 자리**(빈 원 + 옅은 해칭). 계단 위 종이 쪽으로 짧은 화살표 선 하나. 크기는 실물 #6을 화면에 겹칠 수 있을 만큼(여백 높이의 약 40%)
  - 그림자: 아주 옅은 것만 허용(근거로 쓰지 않음)
- **반드시 제외:** 종이 위 글자·숫자, 도장 문양, 인물, 배지 연습 그림
- **연속성:** 여백 확대 그림의 **윤곽이 #6과 같아야 함**(Final에서 한 방향으로 돌렸을 때만 맞아야 함). 대문 각도는 #9와 같음.
- **프롬프트 (이미지 편집, 원본 #8):**
  > Edit this pencil sketch, keeping the paper, the composition, the steps, pillars and church exactly in place. Change only: erase all sky hatching to a light white morning sky with a few cloud outlines; the street lamp is now OFF, with no halo and light hatching inside the glass; the gate stands open inward (same angle as in the reference bag sketch). No people. On the BOTTOM step of the stone steps on the left, on the way from the gate to the steps, lies one small sheet of paper with a sharp V-shaped tear on its top edge. In the blank right margin, draw a larger close-up study of that paper, copied exactly from the reference torn form (torn_form_blank), seen straight on: a deep V tear from the top edge left of centre, a rough torn right edge, a cross of fold lines, and an empty round circle for a stamp in its lower right; one short pencil arrow pointing to the paper on the step. No writing on the paper. Same graphite style, no text.

### #10 보완 — 여백 비우기 (2026-10-23)
- #10은 **여백을 빈 종이로 둔다.** 계단 위 종이와 그 밖의 내용은 위 명세 그대로다.
- 이미 만든 하늘·가로등·대문이 맞는 판이 있으면 그것을 원본으로, 아래 편집만 한다.
  > Edit this pencil sketch, keeping everything exactly in place: the paper sheet, the white sky, the unlit lamp, the open gate, the steps and the small paper on the bottom step. Change only: erase the close-up of the paper in the right margin and the arrow line, leaving the right margin as plain blank cream sketch paper. No people. Same graphite style, no text.

### #12 `paper_study.png` — 종이 확대 연필화 (코드에서 #10 여백에 합성)
- **경로:** `assets/seasons/season_02_paris/cases/case_08/paper_study.png`
- **사용:** #10 여백 위에 겹쳐 그림. Final 1단계에서 실물 종이(#6)를 이 위에 맞춰 놓는 판
- **내용:** P.가 #6 종이를 보고 연필로 그린 그림. **윤곽은 #6과 같아야 한다**: 위쪽 가장자리 왼쪽에서 약 40% 지점에서 시작하는 깊은 V자 찢김, 거친 오른쪽 가장자리, 십자 접힌 자국, 오른쪽 아래 빈 동그라미(도장 자리), 왼쪽 위 모서리 장식이 있는 이중 테두리(연필 선 두 줄)
- **반드시 제외:** 남색 잉크, 색, 사진 같은 종이 질감, 그림자, 종이 바깥 배경, 글자, 도장 문양, 화살표
- **배경:** 투명. 연필 선과 아주 옅은 해칭만 불투명
- **화풍:** #8–10과 같은 흑연
- **프롬프트 (참고 이미지: `torn_form_blank.png`)**
  > A loose graphite pencil drawing, as an artist's quick study in a sketchbook margin, of the torn paper in the reference image, seen straight on with exactly the same outline: a deep sharp V-shaped tear coming down from the top edge, starting about 40% from the left; a rough, jagged torn right edge; a cross of fold lines; a double border drawn as two thin pencil lines with a notched corner at the top left and bottom left; an empty round circle drawn in the lower right. Only pencil lines and light hatching on transparent background. No colour, no navy ink, no paper texture, no shadow, no text, no arrow. Square canvas.

### #11 `last_sketch_garden.png` — P.의 마지막 그림 (→ Case 09)
- **사용:** Case Closed Next Lead (a) 같은 가방 확인, (b) 지도와 대조
- **내용:** 같은 화풍의 흑연 스케치. 이번에는 여백 없이 종이 전체에 그린다.
  - 뒤쪽: **긴 2층 궁전 건물, 가운데 부분이 더 높고 지붕에 작은 돔 모양**(Luxembourg 궁전, 지도 그림과 비슷한 실루엣)
  - 가운데: **분수가 솟는 둥근 연못**, 둘레의 **꽃밭**, 줄지은 나무
  - 앞쪽 잔디: 무릎 높이의 **작은 모형 시계**(돌 받침 위 작은 탑과 둥근 시계판). 시계판에는 바늘 없이 눈금만. 둘레에 **아주 작은 집 지붕 모형 몇 개**(특정 랜드마크로 보이지 않게)
  - 모형 옆: **#9와 같은 인물**(뒷모습, 모자, 코트, 얼굴 없음)이 서 있고 **같은 가방**을 몸 옆에 들었음. 덮개는 **닫힘**, 덮개가 화면을 향해 **버클 2개와 방패 배지**가 보임
  - 잔디 위 다른 곳: 정원사의 **둥근 고리버들 바구니**(미끼)
- **반드시 제외:** 얼굴, 글자, 유리 피라미드(Louvre와 혼동), 에펠탑, 개선문, 오페라 극장, 시계 바늘, 특정 랜드마크 모형
- **연속성:** 가방 비율(납작한 직사각형), 버클 2개, 방패 배지(테두리 잎, 흐릿한 가운데), 인물의 모자와 코트가 #9와 같음. 궁전과 둥근 분수 연못은 `paris_mystery.png` 속 Luxembourg와 같은 관계(궁전 앞 둥근 연못)
- **배경:** 투명(종이 바깥)
- **프롬프트:**
  > A graphite pencil sketch on cream sketch paper, the same hand and style as the reference morning sketches. A formal Paris garden: in the back, a long two-storey palace whose middle section is taller with a small dome on its roof; in front of it, a round pond with a fountain jet, formal flowerbeds and rows of trees. On the lawn in the foreground stands a small knee-high model clock tower on a stone base, its round face showing only hour marks and NO hands, with a few tiny model house roofs around it. Next to it stands the same figure as in the reference sketch, seen completely from behind (wide-brimmed hat, long coat, no face), holding the same FLAT rectangular document bag at the side, flap CLOSED and facing the viewer, with two buckles and the small shield badge with a ring of tiny leaves on its edge. Elsewhere on the grass, a round wicker gardener's basket. No glass pyramid, no other famous monuments, no text, no signature. Isolated sheet on a transparent background, 3:2 canvas.

---

## 4. 납품 후 확인 목록 (구현 전에 실행)

| 확인 | 기준 |
|---|---|
| M1 공정성 | corner_1 = 배치 같음 + 초록 대문, corner_2 = 배치 같음 + 검은 대문, corner_3 = 좌우 반대 + 검은 대문. 세 곳 모두 교회가 대문 위에 있음 |
| 광장 일치 | `abbesses_square`의 세 모퉁이가 #1–3과 가로등 좌우, 대문 색이 같음 |
| 연필화 정렬 | #8·#9·#10의 종이 윤곽, 계단, 기둥, 가로등, 교회 위치를 차이 비교로 확인. 차이는 §3에 적은 항목에서만 나와야 함 |
| 순서 근거 | 하늘 밝기 1 < 2 < 3, 가로등 켜짐·켜짐·꺼짐. 다른 근거(그림자 등)가 다른 순서를 암시하지 않을 것 |
| 종이 동일성 | #10 여백 확대 그림의 V자 위치, 거친 가장자리, 도장 자리가 #6과 한 방향에서만 맞을 것 |
| 배지 동일성 | #9와 #11의 방패 윤곽, 테두리 잎, 흐릿한 가운데가 같음 |
| 금지 요소 | 얼굴, 글자, 빨간 문, 배지 가운데 문양, 피라미드 없음 |
| 투명도 | #6–11은 종이 바깥 알파 0, 종이 안 알파 255 |
