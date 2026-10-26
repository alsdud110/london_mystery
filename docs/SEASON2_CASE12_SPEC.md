# Season 2 · Case 12 — The Clockmaker's Truth
## 확정 기획 사양서 v1.0 (2026-10-26 · 어린이용 최종 스토리)

**상위 문서:** `docs/SEASON2_PARIS_STORY_BIBLE.md` v2.0 §6 Case 12 확정 명세
**함께 보는 문서:** `SEASON2_CASE11_SPEC.md`(대화 시스템 §9), `SEASON2_CASE11_12_ASSET_SPEC.md`, `SEASON2_FINAL_STORY_REVIEW.md`
**상태:** 스토리 확정. **구현·이미지 미착수.** 코드·저장 키 변경 없음.
**ID:** case `s2_ep12` · missions `s2_ep12_m1`–`m3`, `s2_ep12_final` · evidence `s2_ep12_e1`–`e4` · clues `s2_ep12_c1`–`c3`

### v1.0에서 바뀐 것 (v0.2 대비)
- **정체 증명을 세 단계로 늘렸다.** 같은 바퀴만으로는 결론 내리지 않는다. 세 번째로 **Émile의 도구가 Case 01의 Clockmaker 표식(톱니)을 찍는다**는 것을 아이가 직접 찍어서 비교한다. Bible이 정한 "도구 흔적·기존 표식"으로 증명하며, Case 05에서 열어 둔 질문("톱니와 두 바늘은 같은 사람인가?")도 여기서 닫힌다.
- **Émile의 동기를 질문·답변으로 줄였다.** `I wanted people to look.` → `Look for what?` → `The missing page.`
- **Page 3의 위치를 Émile은 몰랐다**로 정리했고, 그래도 단서가 탐정을 그곳으로 이끈 이유를 한 줄로 설명한다(§4.4).
- **엔딩 순서:** 마지막 증거 → Victor의 기록(Case 11 진술) → Émile의 인정 → 탐정이 사건 파일 정리 → 3쪽을 안전하게 보존 → 사건 파일이 닫힘.
- M2의 4장 분류 카드는 삭제했다(Final Q6과 엔딩이 같은 일을 함).

---

## 0. 아이가 이해할 이야기
1. E.M. is Émile Moreau. He is the Clockmaker.
2. He wanted people to find page 3. So he left clues.
3. But he scared people. That was wrong.

**시즌을 세 문장으로:** `The clocks were wrong.` / `Victor hid the truth.` / `Émile left the clues.` (+ `But he scared people.`)

---

## 1. 사용하는 사실
| 구분 | 내용 |
|---|---|
| 구현된 사실 [IMPL] | Season 1 `ep12_e4` The Clockmaker's Watch: `Left on his empty desk.` `Still ticking. On the back: PARIS.` Case 01: `The Clockmaker's watch is still ticking in your pocket.` · `s2_ep01_e3` The Clockmaker's Mark: `A tiny carved gear…`(Notebook 아이콘 = 톱니 8개). Case 05: Clock III에 `one small brass wheel that does not belong`, 수리 카드 `I added one small wheel…`(두 바늘 서명), 편지를 Clock III에 숨김. Case 05 데이터 주석: 톱니 표식과 두 바늘이 같은 사람인지는 열어 둔다. Case 09: 톱니 = Chronos 시험 문양, T3 = Arts et Métiers |
| Bible 확정 | Émile = Season 1 Clockmaker = 시험 기술자. 런던 범행의 책임이 있고 미화하지 않는다. Big Ben 작업실의 별도 보관함에 **기록이 어디로 갔는지 적힌 색인**이 있고, Big Ben이 특정 위치에 멈춰야 열린다. Émile은 열지 못했다. Émile의 말은 그 자체로 믿을 수 없다(그래서 증거로 증명) |
| 이번에 확정 (Bible v2.0) | 바퀴 이름표, 시계 안의 같은 바퀴, Émile의 톱니 도장, 기계가 시험 날 이후 틀린 채 남음, Émile이 3쪽 위치를 몰랐다는 것과 그 이유 |
| 말하지 않는 것 | Big Ben이 멈춰야 하는 정확한 시각, 보관함 자료가 들어간 경위, 편지 4417의 보존 지시자, P.와 Émile의 관계, Case 01 `letter M`의 재해석, 처벌·체포 장면 |

---

## 2. Intro — Someone Is Waiting (약 30초)
**장면:** `arts_metiers_hall.png`(1–2) → `old_machine_room.png` + `chronos_machine.png`(3–5) → `emile_back.png`(6–7) → `emile_base.png`(8–9, 이름표 `???`)

| # | 화자 | English | 한국어 |
|---|---|---|---|
| 1 | N | `Arts et Métiers.` | 아르 에 메티에. |
| 2 | N | `A museum full of old machines.` | 오래된 기계로 가득한 박물관. |
| 3 | N | `In a quiet room, a big machine ticks.` | 조용한 방에서 큰 기계가 째깍거린다. |
| 4 | N | `It has three little clocks.` | 기계에는 작은 시계가 세 개 있다. |
| 5 | N | `They are one hour behind the wall clock!` | 벽시계보다 한 시간 늦다! |
| 6 | N | `Someone is standing by the machine.` | 누군가 기계 옆에 서 있다. |
| 7 | ??? | `You came. Good.` | 왔군요. 잘됐어요. |
| 8 | N | `He turns around.` | 그가 돌아선다. |
| 9 | ??? (base) | `Hello, detective.` | 안녕하세요, 탐정님. |

**synopsis:** `E.M.'s old machine is here.` E.M.의 옛 기계가 여기 있다. / `Who left the clues?` 누가 단서를 남겼을까?
**objectives:** `Find his name.` 그의 이름 찾기 / `Find the Clockmaker.` Clockmaker 찾기 / `Fix the old machine.` 옛 기계 고치기

---

## 3. M1 — What's His Name? (약 2분)
**증명 ①: Émile이 그 바퀴를 만들었다.**

| 항목 | 내용 |
|---|---|
| location | `THE MACHINE ROOM` |
| 조작 | Recall(Clock III) → 기계 안 바퀴 3개 중 같은 모양 탭 → 이름표 읽기 |
| 재사용 | `EvidenceRecall`, `ZoomPicture`, `case_05/clock_back_extra_wheel.png` 크롭(덧붙인 바퀴: 1024 이미지의 약 (670, 520), 지름 약 170px — 구현 시 실측), `case_04/hands_sign.png` |
| 신규 위젯 | `WheelCompare` |

### 3.1 조사 전 대화
| 순서 | 화자 | English | 한국어 |
|---|---|---|---|
| Q (필수) | YOU | `Who are you?` | 누구세요? |
| | ??? (base) | `Don't ask me.` | 저한테 묻지 마요. |
| | ??? (base) | `Find out with clues.` | 단서로 알아내 봐요. |
| Q | YOU | `What is this machine?` | 이 기계는 뭐예요? |
| | ??? (base) | `It ran the clock test, long ago.` | 오래전에 시계 시험을 돌리던 기계예요. |

→ `OPEN THE MACHINE`

### 3.2 퍼즐
| 단계 | English | 한국어 | 조작·판정 |
|---|---|---|---|
| story | `A little door opens.` / `Three wheels are inside.` | 작은 문이 열린다. / 안에 바퀴가 세 개 있다. | — |
| 1 | `Remember Clock III at No. 7?` | 7번지의 Clock III 기억나? | Recall 정답 `s2_ep05_e2` The Backward Clock. 그 밖: `Find the clock that turned back.` (거꾸로 가던 시계를 찾아 봐) |
| 2 | `It had a small wheel that didn't belong.` / `Which wheel looks the same?` | 거기 어울리지 않는 작은 바퀴가 있었지. / 어느 바퀴가 똑같아? | 왼쪽에 Clock III 바퀴, 오른쪽에 3칸. 가운데 탭 |
| | 왼쪽: `Count the spokes.` | 바큇살을 세어 봐. | 살이 6개 |
| | 오른쪽: `Look at the size.` | 크기를 봐. | 크기가 큼 |
| | 정답: `The same wheel!` | 똑같은 바퀴야! | 살 4개(X자), 볼록한 축 마개 |
| 3 | 이름표: `Made by Émile Moreau` + [두 바늘 도장] | 에밀 모로가 만듦 | 이름표가 확대된다 |
| | `Two clock hands! The No. 7 mark!` | 두 개의 시곗바늘! 7번지 표식이야! | |
| | `Émile Moreau… E.M.!` | 에밀 모로… E.M.이다! | |

**answer:** `recall:s2_ep05_e2,wheel:middle`
**successMessage:** `E.M. is Émile Moreau!` E.M.은 에밀 모로야!
**hints:** ① `Look at the spokes and the size.` 바큇살과 크기를 봐. ② `The middle wheel has four spokes, like Clock III's.` 가운데 바퀴도 Clock III 것처럼 살이 4개야.

### 3.3 이름 공개
`SHOW` 정답 `s2_ep12_e1` The Name Tag
| 화자 | English | 한국어 |
|---|---|---|
| ??? → **Émile** (base) | `Yes. I am Émile Moreau.` | 네. 제가 에밀 모로예요. |
| Émile (base) | `I worked on this machine.` | 이 기계를 맡았던 사람이죠. |
| YOU | `You said, "Stop the test!"` | "시험을 멈춰요!"라고 한 사람이 당신이군요. |
| Émile (sad) | `I did. Nobody listened.` | 맞아요. 아무도 듣지 않았죠. |

틀린 증거: ??? (base) `That doesn't tell you my name.` / 그걸로는 제 이름을 알 수 없어요.

### 3.4 Notebook
- **clue `s2_ep12_c1`** `E.M.` · value `Émile Moreau` · note `He made Clock III's small wheel.`
- **evidence `s2_ep12_e1` The Name Tag** · icon `seal` · description `A tag on a wheel inside the old machine.` · inscription `Made by Émile Moreau. Two clock hands, the No. 7 mark. Clock III's small wheel is the same.`
- EvidenceLinks → `s2_ep05_e2`: `The same small wheel.` / → `s2_ep11_e1`: `E.M. on page 3.`

---

## 4. M2 — Who Is the Clockmaker? (약 3분)
**증명 ②: Clockmaker의 시계에도 같은 바퀴가 있다.**
**증명 ③: Émile의 도구가 Clockmaker의 표식을 찍는다.**

| 항목 | 내용 |
|---|---|
| location | `THE WORKBENCH` |
| 조작 | ① 회중시계 뒷면 열기 → 안의 바퀴를 M1 이름표 증거와 비교 ② 작업대의 Émile 도구 중 작은 도장으로 종이에 찍기 → Case 01 표식(Recall)과 비교 |
| 재사용 | Season 1 증거 `ep12_e4`, `EvidenceRecall`, `InkGlyph.gear`(찍힌 표식 = Notebook clue `s2_ep01_c3`와 같은 톱니 8개) |
| 신규 위젯 | `WatchBack`, `GearStamp` |

### 4.1 퍼즐
| 단계 | 화자 | English | 한국어 | 조작·판정 |
|---|---|---|---|---|
| story | N | `You still have the Clockmaker's watch.` | 아직 Clockmaker의 회중시계를 갖고 있지. | Season 1 증거 카드가 노트에서 떠오른다 |
| | N | `You found it on his desk in London.` | 런던에서 그의 책상 위에 있던 거야. | |
| | Émile (base) | `Open it. Don't trust my words.` | 열어 봐요. 제 말은 믿지 말고요. | |
| ① | N | `Open the back of the watch.` | 시계 뒷면을 열어 봐. | 도구를 틈에 대고 비튼다(탭 3회 대안) |
| | N | `Look! A small wheel inside.` | 봐! 안에 작은 바퀴가 있어. | 바퀴 확대 |
| | N | `Have you seen it before?` | 전에 본 적 있어? | 노트에서 `s2_ep12_e1` The Name Tag. 오답: `Look for the wheel you just found.` (방금 찾은 바퀴를 찾아 봐) |
| | N | `The same wheel! Émile made it.` | 같은 바퀴야! 에밀이 만든 거야. | |
| | N | `But wait. Anyone can use a wheel.` | 하지만 잠깐. 바퀴는 누구든 쓸 수 있어. | **결론을 막는 한 줄** |
| | N | `We need one more clue.` | 단서가 하나 더 필요해. | |
| ② | N | `Émile's tools are on the bench.` | 작업대에 에밀의 도구가 있다. | 도구 롤이 펼쳐진다 |
| | N | `One tool has a tiny gear at the end.` | 끝에 작은 톱니가 달린 도구가 있어. | `emile_gear_stamp.png` |
| | N | `Press it on the paper.` | 종이에 눌러 봐. | 도구를 종이로 끌어 누르면 → 톱니 자국(코드 `InkGlyph.gear`, 잉크색) |
| | N | `Where did you see this mark?` | 이 표식을 어디서 봤지? | Recall 정답 `s2_ep01_e3` The Clockmaker's Mark. 그 밖: `Look for a mark from Gare du Nord.` (북역에서 본 표식을 찾아 봐) |
| | N | `The Clockmaker's mark! Eight teeth.` | Clockmaker의 표식이야! 톱니 8개. | 두 표식을 나란히 |

**정리 화면 (세 증거 카드가 차례로 놓인다)**
| 카드 | English | 한국어 |
|---|---|---|
| 1 | `Émile made the wheel.` | 에밀이 바퀴를 만들었다. |
| 2 | `It is in the Clockmaker's watch.` | 그 바퀴가 Clockmaker의 시계 안에 있다. |
| 3 | `His tool makes the Clockmaker's mark.` | 그의 도구가 Clockmaker의 표식을 찍는다. |

질문 `Who is the Clockmaker?` (Clockmaker는 누구일까?)
- ✅ `Émile`
- `Victor` → `Whose tool made the mark?` (누구의 도구가 표식을 찍었지?)
  - 판정 근거는 세 증거 카드뿐이다. Victor가 런던에 있었는지 없었는지는 대사로 다루지 않는다.

**answer:** `open,wheel:s2_ep12_e1,stamp:s2_ep01_e3,who:emile`
**successMessage:** `Émile is the Clockmaker!` 에밀이 Clockmaker야!
**hints:** ① `Compare the wheel. Then try the tool.` 바퀴를 비교해. 그다음 도구를 써 봐. ② `The Clockmaker left a gear mark at Gare du Nord.` Clockmaker는 북역에 톱니 표식을 남겼어.

### 4.2 정체 확인 대화 (증거를 모은 뒤에만)
| 화자 | English | 한국어 |
|---|---|---|
| YOU | `You made this wheel.` | 당신이 이 바퀴를 만들었어요. |
| Émile (base) | `Yes, I did.` | 네, 그래요. |
| YOU | `It's inside the Clockmaker's watch.` | 그게 Clockmaker의 시계 안에 있어요. |
| Émile (base) | `That's right.` | 맞아요. |
| YOU | `And your tool makes his mark.` | 그리고 당신의 도구가 그의 표식을 찍어요. |
| Émile (base) | `You found it.` | 찾아냈군요. |
| YOU | `You're the Clockmaker!` | 당신이 Clockmaker군요! |
| Émile (base) | `Yes. I am.` | 네. 맞아요. |

### 4.3 왜 그랬나 — 질문과 답 (필수 3)
**Q1** `Why did you stop Big Ben?` (왜 빅벤을 멈췄어요?)
| 화자 | English | 한국어 |
|---|---|---|
| Émile (base) | `I wanted people to look.` | 사람들이 보길 바랐어요. |
| YOU | `Look for what?` | 뭘요? |
| Émile (base) | `The missing page.` | 사라진 그 쪽이요. |
| Émile (base) | `Under Big Ben, I had a secret box.` | 빅벤 아래에 제 비밀 상자가 있었어요. |
| *(탭)* | | |
| Émile (base) | `Inside was a list of hidden papers.` | 그 안에 숨겨진 서류 목록이 있었죠. |
| Émile (base) | `It opens only if Big Ben stops.` | 빅벤이 멈춰야만 열려요. |
| YOU | `But you scared people.` | 하지만 사람들을 겁먹게 했잖아요. |
| Émile (sad) | `I know. I was wrong.` | 알아요. 제가 잘못했어요. |

- `It opens only if Big Ben stops.`는 Bible의 "특정 위치에 멈춰야 열린다"를 아이 수준으로 줄인 문장이다. Season 1 Case 02의 8:17 정지로는 열리지 않았다는 점과 부딪히지 않도록, 아이가 더 물을 경우의 선택 질문 `Did it open?` → `No. It needs one special moment. You stopped me.`(아니요. 딱 한 순간이 필요해요. 당신이 저를 막았죠)를 둔다.

**Q2** `Why didn't you find page 3 yourself?` (왜 직접 3쪽을 찾지 않았어요?)
| 화자 | English | 한국어 |
|---|---|---|
| Émile (sad) | `I didn't know where it was.` | 어디 있는지 몰랐어요. |
| Émile (sad) | `And people didn't believe me.` | 게다가 사람들은 제 말을 믿지 않았어요. |
| Émile (sad) | `Even if I found it…` | 제가 찾아냈다고 해도… |
| Émile (sad) | `they'd say I made it up.` | 제가 꾸며 냈다고 했을 거예요. |

**Q3** `Why did you leave clues for me?` (왜 저에게 단서를 남겼어요?)
| 화자 | English | 한국어 |
|---|---|---|
| Émile (base) | `You stopped me with clues.` | 당신은 단서로 저를 막았죠. |
| Émile (base) | `People trust clues.` | 사람들은 단서를 믿어요. |
| Émile (base) | `So I left clues for you.` | 그래서 당신에게 단서를 남겼어요. |
| Émile (base) | `I hoped you'd find the page.` | 당신이 그 쪽을 찾아 주길 바랐어요. |

**선택 질문**
| 질문 | 화자 | English | 한국어 |
|---|---|---|---|
| `How did your clues lead to page 3?` / 당신의 단서가 어떻게 3쪽까지 이끌었죠? | Émile | `Old test papers were kept at the star.` | 옛 시험 기록은 별(개선문)에 보관됐어요. |
| | Émile | `I hoped they'd point to page 3.` | 그 기록이 3쪽을 가리키길 바랐죠. |
| | Émile | `And they did. You found the list.` | 그리고 그랬어요. 당신이 목록을 찾았죠. |
| `What did you do in Paris?` / 파리에서 무엇을 했어요? | Émile (sad) | `I set the station clock back.` | 역 시계를 늦췄어요. |
| | Émile (sad) | `I made Clock III go backwards.` | Clock III가 거꾸로 가게 했죠. |
| | Émile (base) | `I hid a letter in it.` | 그 안에 편지를 숨겼고요. |
| | Émile (sad) | `People were confused. That was wrong.` | 사람들이 혼란스러워했어요. 잘못이었죠. |

- **`What did you do in Paris?`는 Final Q5(편지)의 근거이므로 Final 전에 강조 표시한다.** 아이가 건너뛰어도 Final의 오답 안내가 편지를 가리킨다.

### 4.4 Page 3에 대한 Émile의 인지 (논리 정리)
| 질문 | 답 | 화면 근거 |
|---|---|---|
| Émile은 3쪽이 **숨겨진 것**을 알았나? | **알았다.** 자기가 "멈춰요"라고 한 시간의 기록이 사라졌고, Victor의 서류는 거짓이었다 | Q1 `The missing page.` |
| 3쪽이 **어디 있는지** 알았나? | **몰랐다.** 그래서 런던 상자의 목록(색인)이 필요했다 | Q1 `a list of hidden papers`, Q2 `I didn't know where it was.` |
| 그럼 단서는 어떻게 3쪽까지 갔나? | 그는 시험 기록이 Star Room에 보관된다는 것만 알았다(Case 09 꼬리표 `KEPT AT THE STAR`). 그곳의 RECORD LIST가 Saint-Sulpice를 가리켰다(Case 10) | 선택 질문 `Old test papers were kept at the star.` |
| 왜 Star Room 기록을 직접 읽지 않았나? | 찾아도 아무도 믿지 않았을 것이다(꾸며 냈다고 할 것이다). 믿을 사람이 찾아야 했다 | Q2 3–4줄, Q3 |

### 4.5 Notebook
- **clue `s2_ep12_c2`** `Three Clues` · value `Wheel · Watch · Mark` · note `Émile is the Clockmaker.`
- **evidence `s2_ep12_e2` The Clockmaker's Mark Tool** · icon `gear` · description `Émile's tool, and the watch from London.` · inscription `Inside the Clockmaker's watch: the same small wheel Émile made. Émile's tool makes the Clockmaker's gear mark. Émile is the Clockmaker.`
- EvidenceLinks → `s2_ep01_e3`: `The same gear mark.` / → `ep12_e4`(Season 1): `The watch from his desk.`

---

## 5. M3 — Fix the Machine (약 2분)
**아이가 해야 할 일:** `Stop → Turn → Fix → Start`

### 5.1 조사 전 대화
| 순서 | 화자 | English | 한국어 |
|---|---|---|---|
| Q (필수) | YOU | `Why is the machine still wrong?` | 기계는 왜 아직도 틀려요? |
| | Émile (base) | `On the test day, I stopped it.` | 시험 날 제가 멈췄어요. |
| | Émile (base) | `I fixed the three clocks by hand.` | 시계 세 개는 손으로 고쳤죠. |
| | Émile (sad) | `Then Victor stopped all the tests.` | 그 뒤 빅토르가 시험을 모두 멈췄어요. |
| | Émile (sad) | `Nobody fixed the machine.` | 아무도 기계를 고치지 않았죠. |
| Q (필수) | YOU | `Can I fix it?` | 제가 고쳐도 돼요? |
| | Émile (base) | `Yes. Read the card.` | 그럼요. 카드를 읽어 봐요. |

- 박물관이 점검하려고 기계를 다시 켜 두었다(intro의 "ticks"). 대사로 설명하지 않는다.
- `Victor stopped all the tests.`는 Case 11 고백 `I wanted the tests to stop.`과 이어진다.

### 5.2 퍼즐
**카드 (코드 `Paper`)**
| English | 한국어 |
|---|---|
| `HOW TO FIX THE MACHINE` | 기계 고치는 법 |
| `1. Stop the machine.` | 1. 기계를 멈춘다. |
| `2. Turn the wheel to the wall clock.` | 2. 바퀴를 돌려 벽시계에 맞춘다. |
| `3. Push the pin to fix it.` | 3. 핀을 밀어 고정한다. |
| `4. Start the machine.` | 4. 기계를 켠다. |

시작 상태: 레버 RUN, 바퀴 창 `10:20`, 작은 시계 셋 10:20, 벽시계 11:20.

| 행동 | 결과 (English / 한국어) |
|---|---|
| 켜진 채 바퀴를 돌림 | `The wheel won't turn. Read step 1.` / 바퀴가 안 돌아가. 1단계를 읽어 봐. |
| 핀 없이 START | `The wheel slipped! Read step 3.` / 바퀴가 미끄러졌어! 3단계를 읽어 봐. |
| 다른 시각으로 START | `Not the same as the wall clock.` / 벽시계와 같지 않아. |
| 핀을 넣은 채 바퀴를 돌림 | `Pull the pin out first.` / 먼저 핀을 빼. |
| **11:20 + 핀 + START** | 세 시계가 함께 11:20이 된다. `All the clocks agree!` / 시계가 모두 맞아! |

- 바퀴는 한 칸 = 1시간이며, 정답은 한 시간 앞으로 돌리는 것이다.
- reduce motion: `◀ ▶` 버튼(48dp)으로 돌린다.

**answer:** `stop,turn:11:20,pin,start`
**successMessage:** `You fixed the machine!` 기계를 고쳤어!
**hints:** ① `Do the steps in order.` 순서대로 해 봐. ② `Look at the wall clock. Turn one hour.` 벽시계를 봐. 한 시간만 돌려.

### 5.3 고친 뒤
| 화자 | English | 한국어 |
|---|---|---|
| Émile (base) | `It's right at last.` | 드디어 맞았네요. |
| Émile (base) | `Thank you, detective.` | 고마워요, 탐정님. |
| N | `Only this old machine changed.` | 바뀐 건 이 오래된 기계뿐이다. |

### 5.4 Notebook
- **clue `s2_ep12_c3`** `All Agree` · value `11:20` · note `Only this machine was fixed.`
- **evidence `s2_ep12_e3` The Fixed Machine** · icon `clock` · description `The old test machine, fixed at last.` · inscription `It stayed wrong after the test day. Nobody fixed it. You turned the wheel to the wall clock. Now all three little clocks agree.`
- EvidenceLink → `s2_ep09_e4`: `In the garden, a model went wrong. Here, you fixed the real machine.`

---

## 6. Final — The Final Case Board (약 2.5분)
질문 카드가 하나씩 나온다. 증거 칩을 놓으면 답 버튼 두 개가 열린다. **오답은 세지 않는다.** 틀린 증거를 놓으면 `Which clue answers this?`(어떤 단서가 이 질문에 답할까?)

**증거 트레이 (직접 제공):** The Hour Was Recorded(`s2_ep10_e4`) · Page 3(`s2_ep11_e1`) · Victor's Name(`s2_ep11_e3`) · The Clockmaker's Mark Tool(`s2_ep12_e2`) · The Letter(`s2_ep06_e4`) · The Name Tag(`s2_ep12_e1`)

| # | 질문 | 맞는 증거 | ✅ 답 | 다른 답 → 안내 |
|---|---|---|---|---|
| 1 | `Did Paris lose an hour?` / 파리는 한 시간을 잃었을까? | The Hour Was Recorded | `No. The clocks were wrong.` / 아니. 시계가 틀렸던 거야. | `Yes. It was stolen.` → `What did the sun say?` / 해는 몇 시라고 했지? |
| 2 | `What was hidden?` / 무엇이 숨겨졌을까? | Page 3 | `Page 3 about the clocks.` / 시계에 관한 3쪽. | `A clock.` → `What was in Box 9?` / 9번 상자에 뭐가 있었지? |
| 3 | `Who hid it?` / 누가 숨겼을까? | Victor's Name | `Victor.` / 빅토르. | `Émile.` → `Whose name was in the big book?` / 큰 장부에 누구 이름이 있었지? |
| 4 | `Who is the Clockmaker?` / Clockmaker는 누구일까? | The Clockmaker's Mark Tool | `Émile.` / 에밀. | `Victor.` → `Whose tool made the mark?` / 누구의 도구가 표식을 찍었지? |
| 5 | `Why did Émile leave clues?` / 에밀은 왜 단서를 남겼을까? | The Letter | `He wanted us to find the truth.` / 우리가 진실을 찾길 바랐어. | `To steal an hour.` → `Did anyone steal an hour?` / 누가 시간을 훔쳤었나? |
| 6 | `Was it OK to scare people?` / 사람들을 겁주는 건 괜찮았을까? | (증거 없음) | `No. He made bad choices.` / 아니. 그는 잘못된 선택을 했어. | `Yes. His reason was good.` → `A good reason doesn't make it OK.` / 이유가 좋아도 괜찮은 건 아니야. |

- Q5 증거가 편지인 이유: 편지(`The clocks may lie. But the show remembers.`)는 Émile이 Clock III에 숨긴 것(M2 선택 질문, Case 05)으로, 시계가 아니라 **진실이 적힌 기록**을 보라는 단서였다.

**answer:** `q1:s2_ep10_e4>no,q2:s2_ep11_e1>page,q3:s2_ep11_e3>victor,q4:s2_ep12_e2>emile,q5:s2_ep06_e4>truth,q6:wrong`
**successMessage:** `You solved the case!` 사건을 해결했어!
**hints:** ① `Pick the clue you found for each question.` 질문마다 네가 찾은 단서를 골라 봐. ② `For question 5, read Émile's letter.` 5번은 에밀의 편지를 읽어 봐.

- **evidence `s2_ep12_e4` The Case File** · icon `letter` · inscription `Paris did not lose an hour. The clocks were wrong. Victor hid page 3. Émile, the Clockmaker, left clues so we would find it. But scaring people was wrong.`

---

## 7. Ending — The Case File (약 50초)
**흐름:** ① 마지막 정답 → ② Victor의 기록(Case 11 증거 카드가 사건 파일 위에 놓임) → ③ Émile의 인정 → ④ 탐정이 사건 파일 정리 → ⑤ 3쪽을 유리 상자에 보존 → ⑥ 사건 파일이 닫힘

**장면:** 1–9줄은 `old_machine_room.png` 위에 사건 파일(기존 Notebook·Case File UI)이 열린다. 10줄부터 `finale_morning.png`(아침빛, 유리 상자 속 3쪽).

| # | 단계 | 화자 | English | 한국어 |
|---|---|---|---|---|
| 1 | ② | N | `Victor's words are in the case file.` | 빅토르의 말이 사건 파일에 있다. |
| 2 | ② | Victor's record | `"Yes. I hid the page."` | "네. 제가 그 쪽을 숨겼어요." |
| 3 | ③ | Émile (sad) | `And I made bad choices.` | 그리고 저는 잘못된 선택을 했죠. |
| 4 | ③ | Émile (sad) | `I scared people. I'm sorry.` | 사람들을 겁먹게 했어요. 미안해요. |
| 5 | ③ | Émile (base) | `I will tell everyone what I did.` | 제가 한 일을 모두에게 말할게요. |
| 6 | ④ | YOU | `The clocks were wrong.` | 시계가 틀렸어요. |
| 7 | ④ | YOU | `Victor hid the truth.` | 빅토르는 진실을 숨겼고요. |
| 8 | ④ | YOU | `Émile left the clues.` | 에밀은 단서를 남겼어요. |
| 9 | ④ | YOU | `But now everyone can know.` | 하지만 이제 모두가 알 수 있어요. |
| 10 | ⑤ | N | `Page 3 goes into a glass case.` | 3쪽이 유리 상자에 들어간다. |
| 11 | ⑤ | N | `No one can hide it again.` | 이제 아무도 숨길 수 없다. |
| 12 | ⑥ | N | `The hour was never gone.` | 그 한 시간은 사라진 적이 없었다. |
| 13 | ⑥ | N | `The truth was waiting to be found.` | 진실은 발견되기를 기다리고 있었다. |
| 14 | ⑥ | — | `CASE CLOSED.` | 사건 종결. |

- **Victor는 등장하지 않는다.** 2줄은 Case 11 증거 `s2_ep11_e4`의 카드로 보여 준다(따옴표 + 카드 테두리).
- **Émile의 잘못은 3–5줄에서 분명히 한다.** 처벌·체포·용서 장면은 없다. 5줄은 책임을 지는 행동(스스로 밝힘)이다.
- 6–9줄이 아이가 기억할 세 문장(+ 희망)이다. 12–13줄은 Bible의 마지막 문장이며 여운으로 쓴다.
- 10–11줄: 봉인될 예정이던 기록이 **숨겨지는 대신 모두가 볼 수 있게 보존**된다. 누가 결정했는지는 말하지 않는다(새 인물 없음).
- 사건 파일이 닫히는 연출(14줄)은 기존 Case Closed 화면을 사용한다.

**caseSummary:** `You found Émile's name on an old wheel. The same wheel was in the Clockmaker's watch, and Émile's tool made the Clockmaker's mark. Émile was the Clockmaker. He left clues so the truth would be found, but he scared people. You fixed the machine and closed the case.`
**keyWords:** `wheel`, `the same`, `watch`, `mark`, `Clockmaker`, `wrong`, `fix`, `truth`
**upcoming:** 없음(시즌 완결)

---

## 8. 플레이 시간
| 구간 | 시간 |
|---|---|
| Intro | 0:30 |
| M1 | 2:00 |
| M2 | 3:00 |
| M3 | 2:00 |
| Final | 2:30 |
| Ending | 0:50 |
| **합계** | **약 10:50** |

## 9. 구현 메모
- **신규 위젯:** `WheelCompare`, `WatchBack`, `GearStamp`, `MachinePanel`, `FinalCaseBoard`(공용 `CaseTalk`)
- **Season 1 증거:** Season 2 노트에서 Season 1 `ep12_e4`를 보여 주는 방식은 구현 전에 확인한다. 안 되면 Case 01 intro 문장 `The Clockmaker's watch is still ticking in your pocket.`을 회상 카드로 쓴다.
- **시즌 완결:** Season 2 완결 흐름(Season 1 Case 12 이후 방식)을 구현 전에 확인한다.
- **테스트(구현 시):** `test/paris_case12_test.dart`, `test/case_shortcuts_test.dart`, `flutter analyze`. 시즌 완결이므로 전체 `flutter test`를 1회 실행한다.

### 9.1 Glossary
museum 박물관 · machine 기계 · wheel 바퀴 · spoke 바큇살 · size 크기 · the same 같은 · name tag 이름표 · made by ~가 만든 · watch 회중시계 · open 열다 · inside 안에 · tool 도구 · press 누르다 · mark 표식 · teeth 톱니 · Clockmaker 시계 장인(그의 별명) · prove 증명하다 · believe 믿다 · trust 믿다 · secret box 비밀 상자 · list 목록 · hidden 숨겨진 · made it up 꾸며 냈다 · scare 겁주다 · confused 혼란스러운 · wrong 잘못된, 틀린 · choice 선택 · reason 이유 · stop 멈추다 · turn 돌리다 · pin 핀 · fix 고치다 · start 켜다 · agree 일치하다 · case file 사건 파일 · glass case 유리 상자 · truth 진실
