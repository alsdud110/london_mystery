# Season 2 · Case 09 — The Clockwork Garden
## 확정 기획 사양서 (v1.1 · 2026-10-23 · 사용자 승인)

**상위 문서:** `docs/SEASON2_PARIS_STORY_BIBLE.md` v1.8 §6 Case 09 확정 명세. 이 문서는 그 화면·대사·판정 상세다. 충돌 시 Story Bible이 우선한다.
**에셋:** `docs/SEASON2_CASE09_ASSET_SPEC.md` v1.0
**상태:** 기획 확정(v0.2 간소화 흐름 + §12 확정 결정), 구현 전. 코드·테스트·에셋 미작성.
**v1.1 (2026-10-23):** 퍼즐·에셋·증거는 그대로 두고 Case 08 → 09 → 10 연결 대사만 보완(§2 Intro, 각 미션 transition의 "다음 미션 연결" 줄, §6 Final 직후, §7 Case Closed, §13 연결 흐름).
**ID:** case `s2_ep09` · missions `s2_ep09_m1`–`m3`, `s2_ep09_final` · evidence `s2_ep09_e1`–`e4` · clues `s2_ep09_c1`–`c3`
**방향 (v0.2 간소화 유지):** 8–12세가 **5–7분**에 끝낼 수 있는 가벼운 사건. 각 퍼즐은 5초 안에 조작법을 알 수 있어야 하고, 한 화면에 단서와 조작 영역이 함께 있다. 오답은 진행을 초기화하지 않는다. 새 시스템을 만들지 않고 기존 위젯을 재사용한다.

### 표기
- **[BIBLE]** Story Bible v1.6 또는 구현된 Case 01–08에서 확정된 사실
- **[NEW]** Case 09에서 새로 정한 설정 (2026-10-23 사용자 승인, Bible v1.7 반영)

---

## 0. 한 줄 요약

P.의 마지막 그림 속 작은 시계는 정원에 있는 **작은 파리 모형(Little Paris)**의 기준 탑이었다. 시계 모형 3개를 제자리에 돌려놓으면 **시험 시계가 파리의 몇 곳에만** 있었다는 것을 알게 된다(M1). 톱니 2개를 끼우면 탑이 **이어진 시계만** 움직인다(M2). 옛 표식 두 개는 **서로 다른 종이**에서 나온다(M3). 탑을 한 시간 뒤로 돌리면 **이어진 시계만 함께 틀린다**(Final). T1 아래 기록 꼬리표의 **별**이 Arc de Triomphe를 가리킨다.

**결론 문장 [BIBLE 취지]:** `One wrong setting can change several connected clocks.`

**공개하지 않는 것 [BIBLE]:** Clockmaker = Émile Moreau, 두 표식의 주인이 같은 사람인지, Clockmaker의 동기, Victor·기록 삭제 책임, 실제로 한 시간이 사라졌는지(→ Case 10), 시험 사고의 날짜, 가방 운반자·가방이 정원에 온 이유, 방패 배지·보라색 도장의 의미.

---

## 1. 지키는 것과 새로 정하는 것

### 1.1 [BIBLE] 유지
| 항목 | 내용 |
|---|---|
| 장소·핀 | Luxembourg Gardens, `ParisLandmark.luxembourgGardens` |
| 제목·질문 | `The Clockwork Garden` / `Could one wrong setting affect several clocks?` |
| 미션·증거명 | M1 The Little Paris → `Trial Map` · M2 The Gear Path → `Synchronisation Diagram` · M3 The Maker's Marks → `Marks Key` · Final The Wrong Hour |
| 시험망 범위 | 일부 시험 시계만. 파리 전체 시계 아님 (§2.4) |
| 앞 Case 시계와의 경계 | Gare du Nord(Case 01), Clock III(Case 05), Eiffel(Case 03) 시각을 시험망 탓으로 만들지 않는다 (§2.4) |
| 표식 | 톱니 표식 = Chronos 시험 설계 문양. 두 바늘 = No. 7 수리 공방, 설계도의 수리 기록에 등장. **동일 인물 결론 금지** |
| Final 한계 | 이것만으로 삭제 책임자를 알 수 없다 |
| End hook | 시험 기록 표식 ↔ Arc de Triomphe |
| Case 08 마지막 그림 | 궁전·분수 연못·꽃밭, 돌 받침 위 시계탑(**시계판 바늘 없음**), 지붕 3채, 같은 가방 (`last_sketch_garden.png` 실물 확인) |
| Case 01 톱니 표식 | `s2_ep01_e3`: `A tiny carved gear, and the letter M.` **증거 그림 없음**. clue `s2_ep01_c3` 기호 = `InkGlyph.gear`(톱니 8개) |
| 두 바늘 표식 | `case_04/hands_sign.png`. `s2_ep05_e1` The Repair Card: `Signed with two clock hands.` |

### 1.2 [NEW] 확정 설정
1. 정원 시계탑은 **Little Paris** 모형의 기준 탑이다. 받침 윗면에 파리 지도가 새겨져 있다(가상 시설).
2. 시험 시계는 **세 곳**: T1 Arc de Triomphe, T2 Seine Quays(다리), T3 Arts et Métiers. 각 모형의 받침에 작은 표식: T1 **별**, T2 아치 세 개, T3 종.
3. 정원에는 모형과 이어지지 않은 **정원 시계**가 있다(제 시간을 지키는 시계, 4:00).
4. T1 아래에 작은 기록 드럼이 있고, 꼬리표에 `TRIAL RECORDS · KEPT AT THE STAR`.
5. 탑의 바늘은 빠져 있었다(P.의 그림과 맞춤). Final 시작에 바늘을 다시 끼우는 **짧은 연출**만 넣는다(§6.1). Case 07·08의 보라색 도장(바늘 없는 시계 + 월계관)과 **연결하지 않는다.**
6. 가방이 정원에 온 이유는 Case 09에서 공개하지 않는다. **Case 11에서 회수할 미해결 단서**로 관리하며, 구체적 이유는 아직 정하지 않는다.

---

## 2. Intro (약 30초)

**장면:** `case_08/last_sketch_garden.png`(재사용) → `garden_model_view.png`(신규)
장소 찾기는 Case 08에서 끝났으므로 반복하지 않는다.

**synopsis**
- `A paper for changing a time fell from a bag.`
- `P.'s last drawing showed the same bag in a garden, beside a little clock.`
- `What is that little clock?`

**objectives**
- `Find out what the little clock is.`
- `Make the clocks move.`
- `Test the clocks.`

**intro** (화면: 1–3 `last_sketch_garden.png` → 4부터 `garden_model_view.png`로 겹쳐 바뀜)
1. `You look at P.'s last drawing again.`
2. `A palace. A round pond. A little clock on a stone base.`
3. `And beside it, the same flat bag. The paper for changing a time fell from that bag.`
4. `You walk into the Luxembourg Gardens.`
5. `The palace. The pond. It's the garden from the drawing!`
6. `Look! That's the little clock from the drawing!`
7. `The same bag was here. But why?`
8. `The bag is gone. The little clock is still here. Let's look closer.`

**플레이어가 기억할 세 가지와 해당 줄**
| 기억할 것 | 줄 | 화면 |
|---|---|---|
| 그림 속 장소가 이 정원이다 | 2, 5 | 연필화 → 같은 구도의 채색화로 겹쳐 바뀜 |
| 같은 가방이 여기 있었다 | 3, 7 | 연필화 속 가방. 정원 그림에는 가방이 없음(8) |
| 작은 시계가 새 조사 대상이다 | 6, 8 | 탑에 잠깐 빛 강조(기존 강조 효과) |

- P.의 그림은 연필화이므로 `painting`이 아니라 `drawing`으로 쓴다(Case 08 `P.'s last drawing`과 같은 말).
- 3번 뒷문장은 Case 08 결론(`A paper for changing a time fell from the bag.`)을 다시 말할 뿐, 새 사실을 더하지 않는다.
- 7번은 Case 08 hook(`Why did the bag go to the little clock in the garden?`)을 이어받는다. **Case 09에서는 답하지 않고** Case Closed에서 "아직 모른다"고 밝힌다. 가방 운반자·방문 목적은 쓰지 않는다. Case 11 회수용 미해결 단서다(§12-3).

---

## 3. M1 — The Little Paris (약 1–1.5분)

| 항목 | 내용 |
|---|---|
| location | `THE LITTLE PARIS · LUXEMBOURG GARDENS` |
| 화면 | 위 70%: 받침에 새겨진 지도 = **`paris_mystery.png` 재사용**. 아래 30%: 시계 모형 3개 |
| 조작 | 모형을 지도 위 건물로 끌어 놓기. 또는 모형 탭 → 건물 탭 |
| 재사용 | `StudioMatch`의 "탭 → 탭 / 끌어 놓기" 연결 방식 + `LetterMap`의 지도 건물 탭 영역(`ParisLandmark` 좌표) |
| 5초 이해 | 손가락 안내 애니메이션(기존 온보딩 손가락)으로 모형 하나를 지도 위로 끄는 모습 1회 |

### 3.1 스토리
- `The stone base has a map of Paris on it.`
- `Three little clocks lie in a box. Their places are empty.`
- `Put them back!`

**letterIntro:** 없음. 화면의 그림이 단서다.

### 3.2 시계 모형 3개
| 모형 | 모양 (그림) | 받침 표식 | 정답 위치 |
|---|---|---|---|
| T1 | 큰 **아치** 하나 + 작은 시계 | 별 | `arcDeTriomphe` |
| T2 | **세 아치 다리** + 초록 책 가판대 + 작은 시계 | 아치 세 개 | `seineQuays` |
| T3 | 긴 홀 + **뾰족탑 하나** + 작은 시계 | 종 | `artsEtMetiers` |

- 모양이 지도 그림과 한눈에 맞는다. 지도의 나머지 건물에는 시계가 놓이지 않는다.
- 놓을 수 있는 곳은 지도의 10개 랜드마크 링(기존 `LetterMap` 탭 영역, 판정 반경 48pt 이상).

### 3.3 판정·피드백 (틀리면 모형이 제자리로 돌아오고 짧은 힌트)
- **answer:** `t1:arcDeTriomphe,t2:seineQuays,t3:artsEtMetiers` (기존 `matchPairs` 형식)
- 오답 피드백(모형별 한 줄)
  - T1: `Look for a big arch.`
  - T2: `Look for a bridge with green bookstalls.`
  - T3: `Look for one tall spire, north of the river.`
- T3을 Notre-Dame에 놓았을 때만: `Notre-Dame has two towers. Find one tall spire.`

### 3.4 힌트
1. (무료) `Look at the shape of each little clock. Find the same shape on the map.`
2. `T1 is an arch. T2 is a bridge. T3 is a tall spire.`

### 3.5 transition
1. `Click! All three clocks are back.`
2. `Only three places in Paris have trial clocks. Not every clock in Paris.`
3. `Each little clock has a sign: a star, three arches, a bell.`
4. **(→ M2)** `Three clocks, far apart. How does one little tower reach them?`

### 3.6 Notebook
- **clue `s2_ep09_c1`** — `Three Trial Clocks` · value `T1 · T2 · T3` · symbol `map` · note `Only three places in Paris have trial clocks.`
- **evidence `s2_ep09_e1` Trial Map** — icon `map` · description `The little clocks, put back on the map of Paris.` · inscription `T1 at the Arc de Triomphe, with a star. T2 at the Seine bridge, with three arches. T3 at Arts et Métiers, with a bell. Only three places have trial clocks.`
- 증거 그림: 지도 + 모형 3개(코드 합성)

---

## 4. M2 — The Gear Path (약 1분)

| 항목 | 내용 |
|---|---|
| location | `UNDER THE LITTLE PARIS` |
| 화면 | 판 하나: 왼쪽 **탑 바퀴**, 오른쪽 **T1·T2·T3 시계**와 **정원 시계**, 그 사이 **빈 자리 2곳**(점선 동그라미), 아래 트레이에 **톱니 2개** |
| 조작 | 톱니를 빈 자리에 끌어 놓기(가까이 놓으면 쏙 들어감). 둘 다 들어가면 자동으로 탑 바퀴가 돌기 시작 |
| 재사용 | `ArchivePuzzle`(Case 06 M3)의 끌어 놓기·스냅 방식. 회전은 단순 회전 애니메이션 |

### 4.1 스토리
- `A little door opens under the model.`
- `Gears! But two are missing.`

**letter (판의 글귀, 한 줄):** `Join the tower to the trial clocks.`

### 4.2 판 구성 (확정)
```
              [빈 자리 1] — T1
 탑 바퀴 ─┤
              [빈 자리 2] — 고정 톱니 ─ T2
                                    └ T3

                 정원 시계 (어느 톱니와도 닿지 않음)
```
- 트레이의 톱니 2개는 **크기가 다르다**(큰 것 1, 작은 것 1). 빈 자리의 점선 동그라미도 크기가 다르다. 크기가 맞아야 들어간다.
- 크기가 안 맞는 자리에 놓으면 톱니가 살짝 흔들리고 트레이로 돌아간다: `Too big!` / `Too small!`
- 하나만 끼우면: 그쪽만 돈다(예: T1만). 화면 문구 `One more gear!`
- 회전 방향 규칙, 걸림(jam), 함정 축은 **없다.**
- **정답:** 큰 톱니 → 빈 자리 1, 작은 톱니 → 빈 자리 2. **answer:** `slot1:big,slot2:small`

### 4.3 정답 후 애니메이션 (약 3초, 건너뛰기 가능)
- 탑 바퀴 → 톱니들 → **T1·T2·T3의 바늘이 함께 돈다.**
- **정원 시계는 움직이지 않는다.** 정원 시계 위에 작은 `still` 표시 없이 그대로 두고 transition에서 말한다.
- reduce motion: 회전 대신 시계 바늘이 한 번에 이동.

### 4.4 힌트
1. (무료) `Look at the dotted circles. Which gear fits each one?`
2. `The big gear goes near T1. The small gear goes near T2 and T3.`

### 4.5 transition
1. `The tower turns. T1, T2 and T3 turn with it!`
2. `The garden clock does not move. It is not joined.`
3. `The gears move the model. The real trial used wires.`
4. `Under T1, a little drum writes the time.`
5. `Its tag says: TRIAL RECORDS · KEPT AT THE STAR.`
6. **(→ M3)** `A drawer opens under the board. Who planned this machine? Who fixed it?`

3번 문장은 톱니 연결과 실제 시험망을 구별하는 **유일한 원리 설명**이다(§12-4). 이 밖의 기계 설명은 넣지 않는다.

### 4.6 Notebook
- **clue `s2_ep09_c2`** — `The Tower Wheel` · value `Tower → T1 · T2 · T3` · symbol `gear` · note `The tower moves only the clocks joined to it.`
- **evidence `s2_ep09_e2` Synchronisation Diagram** — icon `gear` · description `The gear board under the Little Paris.` · inscription `The tower turns T1, T2 and T3 together. The garden clock is not joined, so it does not move. The gears move the model. The real trial used wires. Under T1, a drum. Its tag: TRIAL RECORDS · KEPT AT THE STAR.`
- EvidenceLink → `s2_ep09_e1`: `The same three trial clocks.`

---

## 5. M3 — The Maker's Marks (약 1분)

| 항목 | 내용 |
|---|---|
| location | `UNDER THE LITTLE PARIS` |
| 화면 | 왼쪽: **Notebook의 표식 2개**(카드로 직접 보여 줌). 오른쪽: 서랍 속 종이 한 장(설계도 + 핀으로 꽂힌 수리 메모) 위의 **표식 3개** |
| 조작 | 왼쪽 표식을 탭 → 같은 모양을 탭(선으로 이어짐). 끌어서 이어도 됨 |
| 재사용 | `StudioMatch`의 탭-연결 매칭 + `matchPairs` 판정 |
| Notebook | **변경 없음.** Recall Card를 쓰지 않고, 이전 증거 2개를 화면에 바로 보여 준다(Case 08 Final 보드가 Case 07 증거를 직접 준 것과 같은 방식) |

### 5.1 스토리
- `In the drawer: an old plan. CHRONOS TRIAL.`
- `A repair note is pinned to it.`
- `You know these marks!`

### 5.2 화면의 표식
**왼쪽 (내 Notebook)**
| 카드 | 그림 | 글 |
|---|---|---|
| A | 톱니 8개 문양(`InkGlyph.gear`, Case 01 clue 기호와 같은 모양) | `The Clockmaker's Mark · Gare du Nord` |
| B | 두 바늘(`hands_sign.png`) | `The Repair Card · No. 7` |

**오른쪽 (서랍 속 종이)**
| 자리 | 그림 | 종이 위 글 |
|---|---|---|
| ① 설계도 구석 | 톱니 8개 문양 | `CHRONOS TRIAL · EMBLEM` |
| ② 수리 메모 | 두 바늘 도장 | `REPAIRS · T2 WHEEL` |
| ③ 수리 메모 (미끼) | 열쇠 도장(`InkGlyph.key`) | `REPAIRS · T3 GLASS` |

- **answer:** `a:emblem,b:repair` (③은 미끼)
- 오답 피드백
  - A → ②/③: `Is that a gear?`
  - B → ①: `Count the hands.`
  - B → ③: `That is a key. Look for two hands.`

### 5.3 힌트
1. (무료) `Find the same shape on the old paper.`
2. `The gear is on the plan. The two hands are on the repair note.`

### 5.4 transition (결론은 여기서 말로만 정리, 추가 퀴즈 없음)
1. `The Clockmaker's gear is the trial's emblem.`
2. `The two hands are on the repair note. The No. 7 workshop mended a trial wheel.`
3. `Two marks on two different papers. Did one person make both? The papers do not say.`
4. **(가방 단서)** `And the paper from the bag was for changing a time. Is it linked to this machine? We can't tell yet.`
5. **(→ Final)** `So what does one wrong time do to these clocks? Let's test it!`

4번은 **질문으로만** 남긴다. 가방에 설계도가 있었다거나, 그 종이가 이 장치의 시각을 바꿨다고 말하지 않는다.

### 5.5 Notebook
- **clue `s2_ep09_c3`** — `Two Marks` · value `Gear = trial · hands = No. 7` · symbol `seal` · note `Two marks on two different papers. Who made them is not known.`
- **evidence `s2_ep09_e3` Marks Key** — icon `seal` · description `An old trial plan with a repair note.` · inscription `CHRONOS TRIAL. The plan's emblem is a gear, like the Clockmaker's mark. The repair note is stamped with two clock hands, the No. 7 mark. The papers do not say who made the marks.`
- EvidenceLink → `s2_ep01_e3`: `The same gear as the Clockmaker's mark.`
- 금지 문구: `Émile`, `Moreau`, `Victor`, `the same person`(긍정), `M`의 해석.

---

## 6. Final — The Wrong Hour (약 1–1.5분)

| 항목 | 내용 |
|---|---|
| location | `THE TOWER CLOCK` |
| 화면 | 위: 탑 시계(크게). 아래 한 줄: T1·T2·T3 시계 + 정원 시계 (모두 4:00) |
| 조작 | ① 탑의 짧은 바늘을 4 → 3으로 끈다 ② `TEST` 버튼 ③ 선택 문제 하나 |
| 재사용 | `ClockQuestion`(Case 01 M3 바늘 끌기, HOUR 버튼 포함), 기존 `GameButton`, `multipleChoice` |

### 6.1 스토리 + 바늘 끼우기 연출 (약 2초, 조작 없음, 건너뛰기 가능)
- 연출: 탑 시계판(`clock_dial.png`, 바늘 없음) 위로 긴 바늘과 짧은 바늘이 차례로 미끄러져 들어와 가운데에 딸깍 끼워지고 4:00을 가리킨다. 바늘은 `ClockQuestion`과 같은 코드 바늘이다. reduce motion: 바늘이 바로 나타남.
- `The tower's hands lie in a little box. You put them back on.`
- `Every clock says four.`
- `What if the tower is set wrong?`
- 바늘이 빠져 있던 이유, 누가 뺐는지는 말하지 않는다. Case 07·08의 바늘 없는 시계 도장과 연결하는 문장·힌트·inscription을 쓰지 않는다.

**letter (카드 한 줄):** `Set the tower one hour back. Then press TEST.`

### 6.2 단계
1. **바늘 맞추기:** 시작 4:00. 짧은 바늘을 3으로(긴 바늘은 12 고정). 
   - 5에 놓고 TEST: `That is one hour forward. Go back.`
   - 2에 놓고 TEST: `That is two hours back. Just one.`
   - 오답은 바늘만 4:00으로 돌아가지 않고 **그 자리에 남는다**(다시 고치면 됨).
2. **TEST:** 탑 3:00 → T1·T2·T3 바늘이 함께 3:00으로 돈다. **정원 시계는 4:00 그대로.**
3. **선택 문제** — question `What happened?`
   - ✅ `connected` · `Only the joined clocks went wrong.`
   - `all` · `Every clock in Paris went wrong.` → `Look at the garden clock. What time does it say?`
   - `who` · `Now we know who set the wrong hour.` → `The test shows HOW. Does it show WHO?`
- **answer:** `connected` (1단계는 판정하지 않는 조작 단계, Case 08 Final 1단계와 같은 방식)

### 6.3 힌트
1. (무료) `One hour back: the short hand goes from 4 to 3.`
2. `Which clocks changed? Which one stayed at four?`

### 6.4 Notebook
- **evidence `s2_ep09_e4` The Wrong Hour Test** — icon `clock` · description `A test on the tower clock in the garden.` · inscription `The tower was set one hour back. T1, T2 and T3 went to 3:00 with it. The garden clock stayed at 4:00. One wrong setting can change several connected clocks. The test does not show who set a wrong hour long ago.`
- EvidenceLink → `s2_ep09_e2`: `The same three clocks the tower turns.`

**successMessage:** `One wrong setting!`

**Final 직후 (반드시 포함, → Case Closed):** `The model shows what could happen. But what really happened?`

---

## 7. Case Closed — Case 10 연결 (약 30초, 점수 없음)

### 7.1 transition
1. `We know what the model can do.`
2. `The records may tell us. The drum's tag said: KEPT AT THE STAR.`
3. `And the bag? Why it came here, we still don't know.`

### 7.2 Next Lead — 탭 한 번
- 화면: Trial Map(지도 + 모형 3개, 각 받침의 표식이 보임)
- 질문: `Which trial clock has the star?`
- 조작: 별이 있는 모형을 탭 → **T1** → 지도의 **Arc de Triomphe**가 빛난다.
  - T2: `Those are three arches. Find the star.` / T3: `That is a bell. Find the star.`
- 완료 문구
  1. `The star is under T1, at the Arc de Triomphe.`
  2. `Twelve roads meet there, like a star.` *(실제 사실: Place de l'Étoile)*
  3. `The real records may be kept there. We must read them.`
  4. `The mystery continues at the Arc de Triomphe!`

**hook (→ Case 10):** `Was the hour lost — or was the clock wrong?`
**caseSummary:** `You put three little clocks back on the map, joined them to the tower with gears, matched two old marks, and set the tower one hour wrong. Only the joined clocks went wrong. A star under T1 pointed to the Arc de Triomphe.`
**keyWords:** `joined`, `trial`, `gear`, `big`, `small`, `same`, `one hour back`, `changed`, `still`
**upcoming:** `{'10': 'The Hour of Shadows'}`

**Case 11로 넘기는 미해결 단서:** 가방이 정원의 작은 시계 옆에 있었던 이유(§7.1의 3번). 구체적 이유는 아직 정하지 않았다.

**Case 10에 남기는 것:** 기록이 실제로 거기 있는지(`may`로만 말함), 독립 시간 기록(Independent Time Log), 누락 페이지, 시간이 실제로 사라졌는지. Case 09는 "별 = Arc"까지만.

---

## 8. 예상 플레이 시간

목표: 5–7분.

| 구간 | 예상 |
|---|---|
| Intro | 0:30 |
| M1 | 1:00–1:30 |
| M2 | 0:45–1:00 |
| M3 | 0:45–1:00 |
| Final | 1:00–1:30 |
| Case Closed | 0:30 |
| **합계** | **약 4:30–6:30** (힌트·오답 포함 시 7분 이내) |

---

## 9. v0.1에서 제거한 것

| v0.1 | v0.2 |
|---|---|
| M1 기둥 6개를 명판의 두 조건(번호 고리 + 황동 선)으로 TRIAL/NOT 분류 | **삭제.** 모형 3개를 지도에 놓기만 함 |
| M1 미끼 기둥 3개(Opera·Eiffel·Station), 확대 그림 4종 | 삭제. 범위 제한은 transition 한 줄로 |
| M1 명판 영어 규칙문 5줄 | 삭제(letter 없음) |
| M2 축 13곳·빈 축 7곳·톱니 4개, 회전 방향 규칙, 걸림(jam), 함정 축 3곳, 손잡이 돌리기 | **삭제.** 빈 자리 2곳·톱니 2개(크기 맞추기), 자동 회전 |
| M2 "실제 시험은 선으로 전했다" 설명 | 삭제(기계 원리 설명 없음) |
| M3 설계도·수리 기록 2장, 탭 지점 6곳, 12/16 톱니 미끼, 4지선다 결론 | 종이 1장·표식 3개 연결, 결론은 transition |
| M3 Recall Card 2장 → `EvidenceRecall` 다중화(공유 컴포넌트 변경) | **삭제.** 이전 증거를 화면에 직접 제공, Notebook 시스템 변경 없음 |
| Final 바늘 끼우기, Test 1·Test 2 두 번, 결과 카드, 시계 7개 중 고르기, 4지선다 | 탑을 4→3 한 번, 시계 4개, 3지선다 하나 |
| Final 레버 | 기존 버튼 |
| Next Lead 2단계(별 비교 + 지도 고르기), 나침반 미끼, 12갈래 세기 | 탭 한 번(별이 있는 모형) |
| 신규 위젯 5개(`TrialSort`, `TrialMapPins`, `GearBoard`, `MarksKey`, `TrialTest`) | 신규 위젯 **2개**(§11) |

---

## 10. 정합성 점검

| # | 확인 | 결과 |
|---|---|---|
| 1 | Case 08 그림 ↔ Intro | 같은 이미지 재사용. `garden_model_view`가 같은 구도·바늘 없는 탑 |
| 2 | M1 vs Case 06·08 지도 퍼즐 | 그쪽은 "그림 하나 → 장소 하나 고르기", 이쪽은 "물건 3개를 제자리에 놓기". 지도 그림만 같음 |
| 3 | M2 정답 유일성 | 톱니 2개·자리 2곳, 크기가 서로 맞는 조합은 하나 |
| 4 | M3 표식 | 두 바늘은 기존 이미지, 톱니는 Case 01 clue 기호와 같은 모양(Case 01 증거엔 그림 없음 — §12-1) |
| 5 | 동일 인물 오해 | "Two different papers", "The papers do not say" 명시 |
| 6 | Case 10 결론 선공개 | 없음. "But what really happened?" / "The records may tell us." (기록이 있다고 단정하지 않음) |
| 7 | 시험망 범위 | 세 곳만, 정원 시계는 이어지지 않음 |
| 8 | Case 10 물증 | M2 꼬리표 `KEPT AT THE STAR` + M1 T1 받침의 별 + 지도 위치 |
| 9 | Notebook만으로 풀이 | M3은 이전 증거를 화면에 직접 제공. 재플레이 불필요 |
| 10 | 저장·맵 | 새 ID만 추가, Case 01–08 변경 없음, 공유 컴포넌트 변경 없음 |

---

## 11. 구현 메모 (참고)

- **재사용:** `LetterMap` 지도 탭 영역, `StudioMatch` 탭-연결/끌어 놓기, `ArchivePuzzle` 스냅, `ClockQuestion`, `GameButton`, `multipleChoice`, `matchPairs` 판정, Case Closed `NextLead`(Case 08).
- **신규 위젯 2개(작게):**
  1. `GearSlots` — 빈 자리 2곳 + 톱니 2개 스냅, 회전 애니메이션, 시계 바늘 회전
  2. `TowerTest` — `ClockQuestion` + 결과 줄(시계 4개) + TEST 버튼 묶음
  - M1은 `StudioMatch` 매칭을 지도 위에 쓰는 배치(scene 데이터)로, M3은 `StudioMatch`/`matchPairs` 그대로.
- **테스트(구현 시):** `test/paris_case09_test.dart`, `flutter analyze`. 공유 컴포넌트 변경이 없으므로 다른 Case 회귀는 기본 범위에서 제외.

### 11.1 학습 설계
| 미션 | dependency / level | expressions |
|---|---|---|
| m1 | exposure | `Put them back!` |
| m2 | essential / comprehension | `Join the tower to the trial clocks.` |
| m3 | exposure | `Find the same shape.` |
| final | essential / application | `Set the tower one hour back.`, `Only the joined clocks went wrong.` |

`CaseLanguageTopic`: `Joined or not: same, big and small, one hour back` / `이어졌나 아닌가: same, big/small, one hour back`
Discovery: m1 `deduction`, m2 `deduction`, m3 `evidenceFound`.
탐정 이름: 기존 Season 2처럼 `you` 서술, 치환자 없음.

### 11.2 Glossary
model 모형 · tiny 아주 작은 · base 받침 · trial 시험 · joined 이어진 · arch 아치 · bridge 다리 · bookstalls 책 가판대 · spire 뾰족탑 · bell 종 · star 별 · gear 톱니바퀴 · missing 빠진 · fit 맞다 · dotted 점선의 · tower 탑 · turn 돌다 · drum 원통 · tag 꼬리표 · record(s) 기록 · kept 보관된 · drawer 서랍 · plan 설계도 · emblem 문양 · repair 수리 · mended 고쳤다 · stamp 도장 · hands (시계) 바늘 · back / forward 뒤로 / 앞으로 · wrong 틀린 · changed 바뀌었다 · several 여러 개의 · connected 연결된 · roads 길

---

## 12. 확정 결정 (2026-10-23 사용자 승인)

| # | 항목 | 확정 |
|---|---|---|
| 1 | Case 01 톱니 표식의 모양 | 기존 Notebook clue `s2_ep01_c3`의 **톱니 8개 아이콘**(`InkGlyph.gear`)을 기준으로 한다. M3 카드 A와 설계도 EMBLEM을 이 모양으로 그린다. Case 01 데이터는 바꾸지 않는다. Case 01의 `letter M`은 인용·해석하지 않는다 |
| 2 | 바늘 없는 탑 시계 | Final 시작에 바늘을 다시 끼우는 **짧은 연출**만 추가(§6.1). Case 07·08 도장(바늘 없는 시계 + 월계관)과 **연결하지 않는다** |
| 3 | 가방이 정원에 온 이유 | Case 09에서 공개하지 않는다. **Case 11에서 회수할 미해결 단서**로 관리(Bible §7). 구체적 이유는 아직 창작하지 않는다 |
| 4 | 톱니와 실제 시험망의 구별 | M2 transition에 `The gears move the model. The real trial used wires.` **한 문장만** 추가(§4.5). 그 밖의 기계 원리 설명은 넣지 않는다 |
| 5 | Final 실험 시각 | **4:00 → 3:00 유지.** Final 직후 `The model shows what could happen. But what really happened?` 문장으로 과거 사건·Case 03·07과 같은 사건이라고 단정하지 않는다 |
| 6 | 시험 시계 위치 | **T1 Arc de Triomphe · T2 Seine Quays · T3 Arts et Métiers** 유지 |

---

## 13. Case 08 → 09 → 10 연결 흐름 (v1.1)

| 단계 | 탐정이 아는 것 | 그래서 생기는 질문 | 대사 |
|---|---|---|---|
| Case 08 끝 | 가방에서 시간 변경 종이가 떨어졌다. 같은 가방이 정원의 작은 시계 옆에 있었다 | 그 작은 시계는 무엇인가? | `Why did the bag go to the little clock in the garden?` (Case 08 hook, 구현됨) |
| Intro | 그림 속 정원이 여기다. 가방은 없고 시계는 남아 있다 | 시계를 조사하자 | `The same bag was here. But why?` / `Let's look closer.` |
| M1 → M2 | 시험 시계는 세 곳뿐 | 작은 탑이 멀리 있는 시계에 어떻게 닿나? | `How does one little tower reach them?` |
| M2 → M3 | 탑은 이어진 시계만 움직인다 | 누가 설계하고 고쳤나? | `Who planned this machine? Who fixed it?` |
| M3 → Final | 톱니 = 시험 문양, 두 바늘 = No. 7 수리. 가방 종이와의 관련은 모른다 | 틀린 시각 하나가 무엇을 하나? | `Let's test it!` |
| Final → Case Closed | 설정 하나가 이어진 시계만 함께 바꾼다 | 실제 시계에는 무슨 일이 있었나? | `But what really happened?` / `The records may tell us.` |
| Case Closed → Case 10 | 기록은 별(T1, Arc)에 보관됐을 수 있다 | 한 시간이 사라졌나, 시계가 틀렸나? | `Was the hour lost — or was the clock wrong?` (Case 10 질문, Bible 그대로) |

**쓰지 않는 것:** 가방 속 설계도, 가방 운반자, 가방이 정원에 온 목적, 시간 변경 종이가 바꾼 기록, Clockmaker와 No. 7의 관계 단정, Case 10의 결론(시간이 사라지지 않았다).
