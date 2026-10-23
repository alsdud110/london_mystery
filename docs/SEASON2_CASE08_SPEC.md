# Season 2 · Case 08 — The Painter's Last Sketch
## 확정 기획 사양서 (v1.0 · 2026-10-23)

**상위 문서:** `docs/SEASON2_PARIS_STORY_BIBLE.md` v1.6 §6 Case 08 확정 명세. 이 문서는 그 명세의 화면·대사·판정 상세다. 충돌 시 Story Bible이 우선한다.
**에셋:** `docs/SEASON2_CASE08_ASSET_SPEC.md`
**상태:** 기획 확정, 구현 전. 코드·테스트·에셋 미작성.

---

## 0. 한 줄 요약

Case 07 슬립 뒷면의 `P. KNEW THE BAG.`를 따라 Abbesses에 가서, Case 02 Hidden Sketch로 **P.가 앉아 그리던 자리**를 찾는다. 그곳에 숨겨진 아침 그림 3장을 시간순으로 놓아 **종이가 가방에서 떨어졌다**는 것을 추론한다. 그 종이가 Case 07 슬립과 같은 양식·도장의 **시간 변경 문서**임을 확인하고, 그림 속 종이와 실물 종이가 같은 종이임을 입증한다. 결론: `A paper for changing a time fell from the bag.` 마지막 그림 속 같은 가방은 **Luxembourg Gardens**의 작은 모형 시계 옆에 있다.

**공개하지 않는 것:** 운반자의 얼굴·이름·소속, 배지의 의미, 기록을 바꾼 사람·지시자·이유, `P. KNEW THE BAG.` 작성자, 종이의 FILE 번호와 시각, 그림의 날짜, 모형 시계의 정체(Chronos 시험), Victor·Émile·Clockmaker와의 연관, P.의 현재 행방.

**ID:** case `s2_ep08` · missions `s2_ep08_m1`–`m3`, `s2_ep08_final` · evidence `s2_ep08_e1`–`e4` · clues `s2_ep08_c1`–`c3`.

---

## 1. Intro

**장면:** Case 07 Amendment Slip의 뒷면. `case_07/abbesses_sketch.png`를 재사용하고 슬립 뒷면 레이아웃(`SlipBack`: ABBESSES 표지판, `P. KNEW THE BAG.`)을 그대로 보여 준다. Notebook에 없는 정보를 아이가 기억해야만 하는 상황을 막기 위해 Intro에서 다시 보여 준다.

**synopsis**
- `A slip from the opera says: P. KNEW THE BAG.`
- `P. is the painter who went away.`
- `What did he see?`

**objectives** (정답 암시 금지: "가방에서 떨어진 것"이라고 쓰지 않는다)
- `Find where the painter sat.`
- `Read his drawings.`
- `Find out what P. saw.`

**intro (화면 순서)**
1. `You turn the opera slip over again.`
2. `A tiny pencil sketch: steps, a lamp, a metro sign. ABBESSES.`
3. `Under it: P. KNEW THE BAG.`
4. `P. is the painter from Montmartre. He said: I saw who took the hour.`
5. `What bag? What did he see?`
6. `Abbesses is a metro stop on the hill of Montmartre. Let's go.`

**hook (Case 07 → 08, 기존):** `What did P. see — and what was in the bag?`

---

## 2. M1 — The Hidden Sketch

| 항목 | 내용 |
|---|---|
| location | `ABBESSES · MONTMARTRE` |
| scene | `abbesses_square.png`, 지점 3곳: `corner_1`–`corner_3` |
| 재사용 위젯 | `scene_explore`(장소 둘러보기 → 그림 고르기) + `EvidenceRecallDock` |
| 이전 증거 | **Case 02 `s2_ep02_e3` The Hidden Sketch**: 그림(배치) + inscription(`The gate is black.`) |

### 2.1 시작 상황과 스토리
- `Abbesses. A small square on the hill of Montmartre.`
- `There is the metro sign from the slip.`
- `But look around. Steps, lamps and gates are everywhere.`
- `Where did the painter sit to draw?`

**letterIntro:** `In your notebook, you wrote:`
**letter** (탐정 자신의 메모. 그림의 **요소**만 적고 **배치와 색**은 적지 않는다):
```
The painter hid a sketch in his studio.
Steps. An old lamp. A gate between two pillars.
The white church above.
Which corner did he draw?
```

### 2.2 조작
1. 광장 그림을 확대하고 끌어서 둘러본다. 돋보기 표시 3곳을 탭하면 각 지점의 정면 풍경(`corner_1`–`3`)이 열린다.
2. 아래 Recall Card로 Notebook의 **The Hidden Sketch**를 가져와 나란히 비교한다(선택, 무료).
3. 선택 페이지에서 지점 하나를 고른다. 지점 이름은 숨기고(`hideOptionNames`) 그림만 보여 준다.

### 2.3 세 지점 (정답 유일성)

| 지점 | 계단·가로등·두 기둥 사이 대문·교회 | 배치 | 대문 색 | 판정 |
|---|---|---|---|---|
| Corner 1 | 모두 있음 | **스케치와 같음** (계단은 왼쪽으로 올라감, 가로등은 대문 왼쪽, 교회는 대문 위) | **dark green** | ✗ 색만 다름 → inscription이 있어야 거를 수 있음 |
| **Corner 2** | 모두 있음 | **스케치와 같음** | **black** | ✅ |
| Corner 3 | 모두 있음 | **좌우 반대** (계단은 오른쪽, 가로등은 대문 오른쪽) | black | ✗ 배치가 다름 → 그림이 있어야 거를 수 있음 |

- 색 정보(Corner 1을 거름)와 배치 정보(Corner 3을 거름)가 **각각 꼭 필요하다.** 둘 중 하나만으로는 확정되지 않는다.
- 교회는 세 지점 모두에서 보이게 해서 교회만으로 고르지 못하게 한다. 메모의 `above`는 확인용이다.
- 선택 페이지 순서는 Corner 1, 2, 3으로 고정한다. 정답은 두 번째다(Case 02 Final·Case 07 M3의 "세 번째 정답"과 겹치지 않게).
- red door는 어느 지점에도 넣지 않는다(Case 02 M1·Case 07 M3와 혼동 방지).

### 2.4 질문·정답·피드백
- **question:** `Where did the painter sit to draw his sketch?`
- **answer:** `corner2`
- **오답 피드백**
  - corner1: `The steps, the lamp and the church match. Now read the sketch in your notebook. What colour is the gate?`
  - corner3: `Look at the sketch again. Is the lamp on the left of the gate, or on the right?`

### 2.5 Recall Card
- evidence `s2_ep02_e3` · title `These steps look familiar...` · prompt `Find the drawing the painter hid.`
- 다른 증거를 골랐을 때:
  - `s2_ep07_e3` → `That sketch brought you to Abbesses. Find the one he hid in his studio.`
  - `s2_ep02_e1` → `That street has a red door. Look for steps and a gate.`
  - `s2_ep02_e4` → `That message was on the back of a canvas. Find the sketch under the paint.`
  - 그 밖 → 기본 문구

### 2.6 힌트
1. (무료) `Bring the painter's hidden sketch from your notebook. Look at it beside each corner.`
2. `Check two things: where the lamp stands, and the colour of the gate. The sketch has no colours. Read its words.`

### 2.7 해결 후 새로 밝혀지는 사실 (transition)
1. `The lamp on the left. The church above. A black gate.`
2. `This is the corner in the painter's sketch.`
3. `One stone in the left pillar is loose.`
4. `Behind it: a bundle of drawings, tied with string.`

이 장면은 `drawing_bundle.png`로 보여 준다.

### 2.8 Notebook
- **clue `s2_ep08_c1`** — title `The Painter's Corner` · value `Lamp left · black gate` · note `The corner in his hidden sketch. His drawings were behind a loose stone.`
- **evidence `s2_ep08_e1` The Painter's Spot** — description `A corner in Abbesses, behind a loose stone.` · inscription `Steps on the left, an old lamp left of the gate, a black iron gate between two pillars, the white church above. The same place as his hidden sketch. A bundle of drawings was hidden in the left pillar.`
- EvidenceLink → `s2_ep02_e3`: `The same corner as his hidden sketch.`

**다음 Mission으로 가는 이유:** 찾아낸 묶음 자체가 M2의 조사 대상이다.

---

## 3. M2 — The Morning Drawing

| 항목 | 내용 |
|---|---|
| location | `THE PAINTER'S CORNER` |
| scene | `drawing_bundle.png`(장소) + `sketch_morning_1_dark` / `_2_bag` / `_3_light` |
| 위젯 | **신규 `SketchSequence`**: ① 순서 배열 ② 두 장 겹쳐 비교하며 변화 표시(`reveal_layer` 슬라이더 방식 재사용) ③ 출처 질문 |
| 이전 증거 | M1에서 찾은 묶음과 지점(그림과 같은 구도) |

### 3.1 시작 상황과 스토리
- `You untie the string.`
- `Three pencil drawings of this corner.`
- `The same steps. The same lamp. The same gate.`
- `But they are not the same.`

**letterIntro:** `A tag on the string says:`
**letter** (규칙만 주고 그림의 순서는 주지 않는다):
```
I drew this corner one morning.
First, the sky was dark.
Then it grew light.
When the sun came up, the lamps went out.
— P.
```

### 3.2 세 그림 (같은 구도, 정해진 차이만 있음)

| 그림 | 하늘 | 가로등 | 대문 | 인물 | 계단 위 종이 | 여백 연습 그림 |
|---|---|---|---|---|---|---|
| 1 Dark | 진한 빗금, 별 몇 개 | **켜짐**(빛 번짐) | 닫힘 | 없음 | 없음 | 없음 |
| 2 Bag | 옅은 빗금, 교회 뒤 지평선이 밝음, 별 없음 | **켜짐** | **열림** | 모자, **뒷모습**, 납작한 서류 가방을 들고 열린 대문에서 나와 왼쪽 계단의 아래에서 두 번째 단을 오르는 중. 가방이 꽉 차서 **덮개 아래로 종이 모서리가 삐져나옴**(덮개는 닫혀 있고 방패 배지가 보임) | 없음 | **배지 확대 그림**(방패 모양, 테두리에 잎) |
| 3 Light | 빗금 없음, 흰 하늘, 구름 | **꺼짐**(빛 번짐 없음) | 열림 | 없음 | **계단 맨 아랫단에 종이 한 장**(인물이 밟고 지나간 자리) | **종이 확대 그림**(위쪽 V자 찢김, 오른쪽 거친 가장자리, 십자 접힌 자국, 동그란 도장 자리) |

**순서가 하나로 정해지는 근거** (아이가 화면에서 직접 보는 것만):
- 하늘: 1(어둡고 별) → 2(희미) → 3(밝음). P.의 쪽지가 "먼저 어두웠고 그다음 밝아졌다"고 알려 준다.
- 가로등: 켜짐, 켜짐, 꺼짐. 쪽지가 "해가 뜨면 가로등이 꺼진다"고 알려 준다. 따라서 3이 마지막이다.
- 두 근거가 서로 맞물려 순서는 **1 → 2 → 3** 하나뿐이다.
- **그림자는 순서 근거로 쓰지 않는다.** 해의 방향이 화면에 주어지지 않으므로 그림자로 시각을 단정하지 않는다. 그림에는 뚜렷한 그림자를 그리지 않고, 3에만 아주 옅은 그림자를 허용한다(근거로 쓰지 않음).
- 인물(2에만)과 종이(3에만)는 순서 근거가 아니라 **순서를 정한 뒤 추론할 대상**이다.

### 3.3 조작
1. **순서 놓기:** 섞인 그림 3장(화면 배치 3 · 1 · 2)을 FIRST / NEXT / LAST 칸에 끌어 놓거나, 탭한 뒤 칸을 탭한다. CHECK.
   - 3을 FIRST/NEXT에 놓았을 때: `Look at the lamp. When the sun comes up, the lamps go out. Can this one come before the others?`
   - 1과 2가 뒤바뀌었을 때: `Look at the sky. Which one is darker?`
2. **겹쳐 보기:** 순서가 맞으면 1↔2, 2↔3을 슬라이더로 겹쳐 비교한다. 새로 생긴 것을 탭해 표시한다. 순서는 자유이고 빈 곳을 탭해도 틀린 것이 아니다.
   - 1→2: `someone with a bag`, `the gate is open`, `a little drawing in the corner`(배지)
   - 2→3: `the lamp is out`, `the person is gone`, `a paper on the steps`, `a little drawing in the corner`(종이)
3. **질문:** 변화 표시를 마치면 열린다.

### 3.4 질문·정답·피드백
- **question:** `Where did the paper on the steps come from?`
- **answer:** `bag` — `It fell from the bag.`
- **오답**
  - `always` · `It was on the steps all morning.` → `Look at drawings 1 and 2. Is there a paper on the steps?`
  - `painter` · `The painter dropped it.` → `The painter was drawing from across the street. The paper is on the steps.`
  - `window` · `It fell from a window.` → `Look at drawing 2. Who was on those steps just before the paper came?`

### 3.5 힌트
1. (무료) `Read P.'s tag. Dark sky first. When the sun comes up, the lamps go out.`
2. `When does the paper come? Who was on those steps just before? Look closely at the bag.`

### 3.6 해결 후 새로 밝혀지는 사실 (transition)
1. `Drawing 1: nobody is here.`
2. `Drawing 2: someone comes through the gate with a flat bag. It is so full that papers stick out.`
3. `Drawing 3: the person is gone. A paper lies on the steps.`
4. `The paper fell from the bag!`
5. `In the corner, P. drew the bag's badge: a small shield with leaves around its edge.`
6. `And the face? P. drew only a hat and a back.`

### 3.7 Notebook
- **clue `s2_ep08_c2`** — title `It Fell from the Bag` · value `Paper after the bag` · note `No paper in drawings 1 and 2. The bag went up the steps. Then the paper was there.`
- **evidence `s2_ep08_e2` The Bag Sketch** — description `Three drawings of one morning, from the painter's corner.` · inscription `Someone in a hat, back turned, comes out of the black gate with a flat bag and climbs the steps. The bag is so full that papers stick out under its flap. Two buckles. On the flap: a small shield badge with leaves around its edge. Then a paper lies on the bottom step. No face. No name.`
- 증거 그림: `sketch_morning_2_bag`(여백의 배지 포함). 확대 화면에서 배지를 다시 확인할 수 있어야 한다(Case 11–12 회수용).
- EvidenceLink → `s2_ep08_e1`: `Drawn from the painter's corner.`
- **배지 해석 금지:** 대사·inscription·힌트 어디에도 도장과 비슷하다거나 어느 소속인지 쓰지 않는다.

**다음 Mission으로 가는 이유:** 그림 3장 뒤에 그림이 아닌 종이가 하나 더 있다.

---

## 4. M3 — The Purple Seal

| 항목 | 내용 |
|---|---|
| location | `THE PAINTER'S CORNER` |
| scene | `folded_paper.png` → `torn_form_blank.png` + `case_07/office_stamp.png`(도장, 재사용) |
| 위젯 | **신규 `UnfoldCompare`**: 펼치기(접힌 면 3번) → SAME / MISSING 표시 |
| 이전 증거 | **Case 07 `s2_ep07_e3` The Amendment Slip** (Recall Card) |

### 4.1 시작 상황과 스토리
- `Behind the three drawings is one more paper.`
- `It is folded small. It is not a drawing.`
- `A note is clipped to it.`

**letterIntro:** `P.'s note says:`
**letter** (P.가 **주웠다**는 사실만 말한다. 가방은 언급하지 않는다):
```
I found this paper on the steps.
I kept it with my drawings.
— P.
```

### 4.2 종이의 내용 (확정)
- 양식: 이중 테두리, 머리글 띠, 변경 줄(`→`), 오른쪽 아래 보라색 도장(바늘 없는 시계 + 월계관, Case 07과 **같은 도장 이미지**)
- 보이는 글자: 머리글 `FILE`(번호 자리는 V자 찢김으로 없음), 변경 줄 `:00 →`(시각의 시 숫자는 V자 찢김의 꼭짓점에, 바뀐 시각은 오른쪽 거친 가장자리 너머로 없음)
- 그 밖의 글자 없음: 공연명, 이름, 이니셜, 날짜, 조직명 금지
- 찢김: 위쪽 가장자리의 **V자 찢김**(가운데보다 왼쪽, 꼭짓점이 변경 줄까지 내려옴), 오른쪽 가장자리 전체가 거칠게 찢김
- 접힌 자국: 십자 하나(네 번 접힘)

`:00`과 `→`는 **"시각을 바꾸는 줄"이라는 사실만** 보여 준다. 몇 시인지는 알 수 없다(§8 논리 검증 참고).

### 4.3 조작
1. **펼치기:** 접힌 면을 3번 탭하거나 끌어서 편다.
2. Recall Card로 **The Amendment Slip**을 가져온다(선택). 가져오지 않아도 inscription을 기억하면 풀 수 있지만, 확대해서 비교하는 것을 권장한다.
3. **SAME** 탭: 오페라 슬립과 **같은 것** 4가지를 종이 위에서 탭한다.
   - `border`(이중 테두리), `band`(FILE 머리글 띠), `arrow`(`→`가 있는 변경 줄), `seal`(도장)
   - `seal`을 탭하면 확대 화면이 열리고 두 가지를 확인해야 표시된다: `How many hands?` → `None` / `What is around the clock?` → `Leaves`
4. **MISSING** 탭: 슬립에는 있는데 이 종이에는 **없는 것** 2가지를, 그것이 있어야 할 자리에서 탭한다.
   - `number`(FILE 옆 번호 자리), `hour`(`:00` 앞 시 숫자 자리)
5. CHECK

**미끼 탭 (틀림으로 세지 않고 안내만 함)**
- 접힌 자국 → `Those are folds. P. folded it small.`
- V자 찢김 가장자리(SAME 탭에서) → `The opera slip is not torn. Is this the same?`
- 계단 먼지 자국 → `That is dust from the steps, not part of the paper.`

**answer:** `same:arrow,band,border,seal|missing:hour,number` (항목 순서 무관)

### 4.4 Recall Card
- evidence `s2_ep07_e3` · title `Have you seen this seal before?` · prompt `Find the slip from the opera.`
- 다른 증거를 골랐을 때:
  - `s2_ep01_e3` → `That mark is a gear. Is this a gear?`
  - `s2_ep05_e1` → `Count the hands. This seal has none.`
  - `s2_ep07_e4` → `That is FILE 3 itself. Find the small slip that said to change it.`
  - `s2_ep06_e4` → `That is Letter 4417. Look for a purple seal.`

### 4.5 오답 피드백 (CHECK 후)
- SAME이 3개 이하: `Look again. Four things on this paper are just like the opera slip.`
- seal을 확인하지 않음: `Look closely at the seal. Count the hands.`
- MISSING에 `hour`가 없음: `Read the times on the opera slip. What is in front of :00?`
- MISSING에 `number`가 없음: `The opera slip says FILE 3. What does this paper say after FILE?`

### 4.6 힌트
1. (무료) `Bring the opera slip from your notebook. Put it beside this paper.`
2. `Look closely at the seal: count the hands, and look around the clock. Then read FILE and the times on both papers.`

### 4.7 해결 후 새로 밝혀지는 사실 (transition)
1. `The same border. The same FILE band. An arrow between two times.`
2. `And the same purple seal: a clock with no hands, in a ring of leaves.`
3. `But the FILE number is torn away. So is the hour.`
4. `This paper is like the opera slip. It is a paper for changing a time.`
5. `P. found it on the steps. But is it the paper in his drawing?`

### 4.8 Notebook
- **clue `s2_ep08_c3`** — title `The Same Seal` · value `No hands · leaves` · note `Same form and seal as the opera slip. The FILE number and the hour are torn away.`
- **evidence `s2_ep08_e3` The Matching Seal** — description `A torn, folded paper, kept with P.'s drawings.` · inscription `P.'s note: I found this paper on the steps. The same form as the opera slip: a double border, a FILE band, a time with an arrow, and the same purple seal, a clock with no hands in a ring of leaves. The FILE number and the hour are torn away.`
- EvidenceLink → `s2_ep07_e3`: `The same form and seal as the opera slip.`

**다음 단계로 가는 이유:** P.가 "계단에서 주웠다"고 한 이 종이가 정말 그림 3의 종이인지 아직 확인하지 않았다.

---

## 5. Final — The Torn Hour

| 항목 | 내용 |
|---|---|
| location | `THE PAINTER'S CORNER` |
| 위젯 | ① **신규 `PaperOnDrawing`**: 종이를 돌리고 끌어 그림의 여백 확대 그림에 겹치기 ② **증거 보드**: Case 03 `evidence_board`에서 탑 전용 부분을 떼어 일반화 |
| 증거 제공 | 보드에 **직접 제공**: M2 Bag Sketch, M3 Matching Seal, **Case 07 Amendment Slip**, M1 Painter's Spot(미끼). Final 전용 Recall 확장은 이번 범위에서 제외 |

### 5.1 시작 상황과 스토리
- `You sit where the painter sat.`
- `Drawing 3 is on one side. The torn paper is on the other.`
- `Is it the same paper? And what does it tell us?`

**letterIntro:** `Your evidence:`
**letter**
```
THE BAG SKETCH
A paper lies on the steps after the bag goes by.

THE MATCHING SEAL
A torn paper. The same form and seal as the opera slip.

THE AMENDMENT SLIP
FILE 3 · CURTAIN UP: 4:00 to 3:00.
```

### 5.2 1단계 — 같은 종이인가
- 화면: 그림 3과 여백의 **종이 확대 그림**(위 V자 찢김, 오른쪽 거친 가장자리, 십자 접힌 자국, 오른쪽 아래 동그란 도장 자리)
- 조작: 실물 종이(펼친 상태, 처음에는 90° 돌아가 있음)를 ↻ 버튼으로 90°씩 돌리고, 여백 그림 위로 끌어 놓는다. **V자 찢김, 거친 가장자리, 도장 자리가 모두 맞는 방향에서만** 딱 맞는다.
- 잘못 놓았을 때(틀림으로 세지 않음):
  - V자 위치가 다름 → `Look at the V-shaped tear. Where is it in the drawing?`
  - 도장 자리가 다름 → `Where is the round seal in the drawing?`
  - 그림의 다른 곳에 놓음 → `P. drew the paper big in the corner. Lay it there.`
- 맞추면: `The same V-shaped tear. The same folds. The seal in the same corner.` / `It is the paper from the steps.`

### 5.3 2단계 — 증거 보드
**질문과 증거** (하나의 증거가 여러 질문에 답할 수 있고, 한 질문에 여러 증거가 필요할 수 있다)

| 질문 | 필요한 증거 |
|---|---|
| Q1 `Where did the paper come from?` | **The Bag Sketch** |
| Q2 `What kind of paper is it?` | **The Matching Seal** + **The Amendment Slip** |

- 미끼: The Painter's Spot을 Q1에 놓으면 `That shows where P. sat. Which drawing shows the paper come?`
- Q2에 Matching Seal만 놓으면 `What does a paper with this seal do? Which old clue shows it?`

**결론 고르기** — question `What can you say now?`
- ✅ `fell` · `A paper for changing a time fell from the bag.`
- `parts` · `The bag was full of clock parts.` → `What fell from the bag? A clock part, or a paper?`
- `painter` · `The painter carried the bag.` → `The painter was drawing. Who walked up the steps?`
- `who` · `Now we know who changed the opera record.` → `Did P. draw a face, or write a name? What do we really know?`

**answer:** `paper:placed|q1:e2|q2:e3+s2_ep07_e3|conclusion:fell`

### 5.4 힌트
1. (무료) `First, turn the paper until its V-shaped tear matches the drawing.`
2. `Which evidence shows where the paper came from? Which ones show what kind of paper it is?`

### 5.5 Notebook
- **evidence `s2_ep08_e4` The Torn Hour** — description `The torn paper, laid on P.'s drawing of the steps.` · inscription `The same V-shaped tear as the paper in drawing 3. It lay on the steps just after the bag went by. The same form and seal as the opera slip. A paper for changing a time fell from the bag. Who carried it, and who changed what, is not known.`
- EvidenceLink → `s2_ep08_e2`: `The paper on the steps in drawing 3.`

**successMessage:** `It fell from the bag!`

---

## 6. Case Closed — 마지막 그림과 Next Lead

### 6.1 Case Solved transition
1. `The paper fell from the bag.`
2. `It is a paper for changing a time, like the opera slip.`
3. `So the bag carried a paper for changing a time.`
4. `But who carried it? P. never drew a face.`
5. `One drawing is left at the bottom of the bundle.`

### 6.2 Next Lead (점수 없음, 오답 불이익 없음)
다음 장소를 내레이션으로 바로 알려 주지 않는다. 아이가 두 단계로 직접 찾는다.

**a) `Is it the same bag?`**
- 화면: `last_sketch_garden.png`(P.의 마지막 그림) + Notebook의 The Bag Sketch(직접 제공)
- 조작: 마지막 그림에서 Bag Sketch와 **같은 점 3가지**를 탭한다: `flat shape`, `two buckles`, `the shield badge`
- 미끼: 정원사의 **둥근 바구니**(같은 그림 속) → `That is a round basket. The bag in your notebook is flat.`
- 완료: `The same flat bag. The same two buckles. The same shield badge.` / `P. saw the bag again, in a garden.`

**b) `Where is this garden?`**
- 화면: 마지막 그림의 특징 3가지(P.가 여백에 써 둔 단어가 아니라 그림 자체): **긴 궁전 건물(가운데가 높음)**, **분수가 있는 둥근 연못**, **꽃밭**. 그리고 기존 Paris 지도(`paris_mystery.png`)
- 조작: Case 06 Final의 `LetterMap`처럼 그림의 특징과 지도의 건물을 비교해 장소를 고른다(새 특징 값: palace, roundPond, flowerBeds)
  - `louvre` → `There is a palace. But where is the glass pyramid? Is there a round pond?`
  - `palaisGarnier` → `That is the opera house. Is there a garden with a round pond?`
  - `montmartre` → `That is the white church. Is there a palace?`
  - 그 밖의 장소 → `Look for a palace, a round pond and flowerbeds.`
  - ✅ `luxembourg`
- 완료 문구:
  1. `The Luxembourg Gardens!`
  2. `On the grass in the drawing stands a little clock. Tiny roofs are all around it.`
  3. `Why did the bag go to a little clock in a garden?`
  4. `The mystery continues in the Luxembourg Gardens!`

**hook (→ Case 09):** `Why did the bag go to the little clock in the garden?`

**caseSummary:** `You found the painter's corner, put his morning drawings in order, matched a torn paper to the opera slip, and proved it fell from the bag. Then his last drawing showed the same bag in a garden.`

**keyWords:** `left`, `right`, `above`, `between`, `first`, `next`, `last`, `same`, `missing`, `torn`

### 6.3 Case 09 정합성
- Bible Case 09 M1 `The Little Paris`(정원 모형의 랜드마크 ↔ 실제 지도)와 이어진다. `tiny roofs`는 모형이 작은 도시라는 것만 암시하고 특정 랜드마크는 그리지 않는다.
- 모형의 용도, 시험망, Chronos, 연결된 시계라는 개념은 **Case 08에서 말하지 않는다.**
- 가방이 그 정원에 **왜** 갔는지, 그림이 **언제** 그려졌는지, P.가 가방을 따라갔는지는 공개하지 않는다(`P. saw the bag again`까지만).

---

## 7. 화면 노출 순서 기준 스포일러 점검

| 시점 | 노출되는 것 | 정답을 미리 알려 주는가 |
|---|---|---|
| Intro / objectives | `Find out what P. saw.` | 아님. "떨어졌다"는 말을 쓰지 않음 |
| M1 메모 | 요소만 나열, 배치와 색은 없음 | 아님. 배치는 그림에서, 색은 inscription에서 확인해야 함 |
| M1 선택지 | 그림만, 이름은 숨김 | 아님 |
| M2 쪽지 | 하늘과 가로등 규칙 | 규칙만 줌. 순서는 아이가 적용해야 함 |
| M2 그림 2 여백 | 배지 확대 그림 | 의미는 말하지 않음 |
| M2 그림 3 여백 | 종이 확대 그림 | 이 단계에서는 설명하지 않음. Final에서 사용 |
| M2 질문 | 순서 놓기와 변화 표시가 끝난 뒤에만 열림 | 아님 |
| M3 P.의 쪽지 | "계단에서 주웠다" | 가방은 언급하지 않음(M2 정답 이후에 나오기도 함) |
| M3 transition | "시각을 바꾸는 종이" | M3 퍼즐을 푼 결과로만 공개 |
| Final letter | 세 증거 요약 | 결론 문장은 쓰지 않음. 보드에서 조합해야 함 |
| Next Lead a | 같은 가방인지 비교 | 장소 이름 없음 |
| Next Lead b | 그림 특징 + 지도 | 장소 이름은 아이가 고른 뒤에만 나옴 |

**Mission 제목:** `The Hidden Sketch`, `The Morning Drawing`, `The Purple Seal`, `The Torn Hour`는 모두 조사 대상만 가리키고 결론을 담지 않는다.

---

## 8. 논리 검증: 주장 ↔ 화면 증거

| 주장 | 화면 증거 | 단계 |
|---|---|---|
| P.가 계단에서 종이를 발견했다 | M3의 P.의 쪽지 `I found this paper on the steps.` + 그림 3의 계단 위 종이 | M3 |
| 그림 속 종이와 실제 종이가 같다 | 그림 3 여백 확대 그림의 V자 찢김·거친 가장자리·접힌 자국·도장 자리 = 실물 종이(돌려서 겹칠 때 한 방향에서만 맞음) | Final 1단계 |
| 종이는 가방이 지나간 뒤 나타났다 | 하늘과 가로등으로 정한 순서 1→2→3. 종이는 1·2에 없고 3에만 있음. 2에서 종이 모서리가 삐져나온 가방이 바로 그 계단에 있음 | M2 |
| 종이는 시간 변경 기록과 관련된 양식이다 | Case 07 슬립과 같은 이중 테두리, FILE 띠, `→` 변경 줄, `:00`(시각), 같은 도장. Case 07에서 이 슬립이 시각 변경(4:00→3:00)이었음이 증명됨 | M3 + Case 07 |
| 따라서 가방이 시간 변경 관련 문서를 운반했다 | 위 네 가지를 보드에서 조합. 결론은 **떨어진 종이 한 장에 대한 것**으로 한정: `A paper for changing a time fell from the bag.` | Final 2단계 |

**설계상 보완한 점**
1. **`:00` 조각:** 같은 양식과 도장만으로는 "시간"을 바꾸는 종이라고 말하기에 근거가 약하다. 그래서 시 숫자만 찢겨 나간 `:00 →`를 남겼다. FILE 번호와 구체적인 시각은 보이지 않는다는 결정을 지킨다.
2. **종이 확대 그림을 여백에:** 계단 위 작은 종이만으로는 찢김 모양을 비교할 수 없다. 화가가 여백에 확대해 그리는 습관을 그림 2(배지)와 그림 3(종이)에 같은 방식으로 적용했다.
3. **결론의 범위:** 가방 속 다른 내용물, 운반자, 기록 변경 책임자는 확정하지 않는다. 화면에서도 `Who carried it, and who changed what, is not known.`이라고 명시한다.

---

## 9. 연계성 요약

| 흐름 | 실제 사용 |
|---|---|
| Case 02 → 08 | M1: Hidden Sketch 그림(배치) + inscription(`The gate is black.`). 둘 다 없으면 지점을 정할 수 없음 |
| Case 07 → 08 | Intro: 슬립 뒷면 `ABBESSES`, `P. KNEW THE BAG.`(동네). M3: 슬립 양식과 도장(Recall). Final: 슬립을 보드 증거로 사용 |
| M1 → M2 | M1에서 찾은 묶음 = M2 그림. M1 지점 = 그림의 구도 |
| M2 → M3 | 그림 3의 계단 위 종이 → P.가 주워 보관한 접힌 종이 |
| M2·M3 → Final | 그림 3 여백 확대 그림 ↔ 실물 종이. Bag Sketch + Matching Seal + Amendment Slip이 보드에 들어감 |
| M2 → Next Lead | Bag Sketch의 가방 특징(납작함, 버클 두 개, 방패 배지) ↔ 마지막 그림 |
| Final → Case 09 | 마지막 그림의 궁전, 둥근 연못, 꽃밭 ↔ 지도의 Luxembourg Gardens. 작은 모형 시계와 주변의 작은 지붕들 → Case 09 M1 `The Little Paris` |
| Case 08 → Case 11–12 | 방패 배지(Bag Sketch에 저장), 찢긴 종이(Matching Seal). 의미는 Case 11–12에서 회수 |

---

## 10. Glossary 후보

| 단어 | 뜻 |
|---|---|
| sketch | 스케치, 밑그림 |
| corner | 모퉁이 |
| metro | 지하철 |
| pillar / pillars | 기둥 |
| gate | 대문 |
| iron | 철로 된 |
| loose | 헐거운, 빠질 듯한 |
| bundle | 묶음, 꾸러미 |
| string | 끈 |
| tied | 묶인 |
| tag | 꼬리표 |
| untie | 풀다 |
| morning | 아침 |
| dark / light | 어두운 / 밝은 |
| sun / came up | 해 / 떴다 |
| lamp / lamps / went out | 가로등 / 꺼졌다 |
| drawing / drawings | 그림 |
| order | 순서 |
| first / next / last | 첫째 / 다음 / 마지막 |
| darker | 더 어두운 |
| flat | 납작한 |
| bag | 가방 |
| flap | (가방의) 덮개 |
| stick out | 삐져나오다 |
| full | 꽉 찬 |
| buckle / buckles | 버클, 잠금쇠 |
| badge | 배지 |
| shield | 방패 |
| edge | 가장자리 |
| hat | 모자 |
| back | 뒷모습, 뒤 |
| face | 얼굴 |
| fell / dropped | 떨어졌다 / 떨어뜨렸다 |
| folded | 접힌 |
| unfold | 펼치다 |
| torn | 찢긴 |
| tear | 찢어진 곳 |
| V-shaped | V자 모양의 |
| seal | 도장, 인장 |
| purple | 보라색의 |
| ring | 고리, 둥근 테 |
| leaves | 잎들 |
| hands (clock) | (시계) 바늘 |
| border | 테두리 |
| band | 띠 |
| arrow | 화살표 |
| same / missing | 같은 / 없는, 빠진 |
| hour | 시(시각의 '시') |
| form | 서식, 양식 |
| dust | 먼지 |
| lay | 놓다 |
| turn | 돌리다 |
| garden | 정원 |
| palace | 궁전 |
| pond | 연못 |
| fountain | 분수 |
| flowerbeds | 꽃밭 |
| basket | 바구니 |
| roofs | 지붕들 |
| tiny | 아주 작은 |
