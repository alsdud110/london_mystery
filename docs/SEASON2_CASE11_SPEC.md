# Season 2 · Case 11 — The Unwritten Hour
## 확정 기획 사양서 v1.0 (2026-10-26 · 어린이용 최종 스토리)

**상위 문서:** `docs/SEASON2_PARIS_STORY_BIBLE.md` v2.0 §6 Case 11 확정 명세. 이 문서는 그 화면·대사·판정 상세다.
**함께 보는 문서:** `SEASON2_CASE12_SPEC.md`, `SEASON2_CASE11_12_ASSET_SPEC.md`, `SEASON2_FINAL_STORY_REVIEW.md`
**상태:** 스토리 확정(사용자 지시에 따라 A1–A9 정리 완료). **구현·이미지 미착수.** 코드·저장 키 변경 없음.
**ID:** case `s2_ep11` · missions `s2_ep11_m1`–`m3`, `s2_ep11_final` · evidence `s2_ep11_e1`–`e4` · clues `s2_ep11_c1`–`c3`

### v1.0에서 바뀐 것 (v0.2 대비)
- **A3 (오페라):** "3시 공연" 알리바이를 지웠다. Victor가 말로 `My office never changed any papers.`라고 하고, 아이는 **Case 07 수정 슬립의 도장 = Victor 서류의 도장**을 비교해 반박한다. 공연 날짜는 새로 정하지 않는다.
- **A4 (지시서 위치):** 별도 지시서를 없앴다. 찢겨 나간 장부 쪽의 내용이 바로 지시였고, 그 아래 **서명까지 눌려 남아 있었다.** M1의 문지르기 하나로 상자 번호와 서명이 함께 나오고, M3에서 그 서명을 비교한다.
- **A5 (가방·바늘):** 긴 고백 대신, 아이가 증거 카드를 보여 줄 때마다 Victor가 두 줄씩 답한다. 가방을 든 사람은 정하지 않는다.

---

## 0. 아이가 이해할 이야기
1. Page 3 was hidden in Box 9. It says the clocks were wrong.
2. Victor's paper says the clocks were fine. That's not true.
3. Victor signed the order to hide page 3.

**결론:** `Victor hid the truth.`
**남는 질문 (→ Case 12):** `Then who left the clues for me?`

---

## 1. 사용하는 사실
| 구분 | 내용 |
|---|---|
| 구현된 사실 [IMPL] | Case 10: Trial Log 3쪽(3:00–4:00)이 없고, 목록에는 `SENT TO: SAINT-SULPICE · ARCHIVE ANNEX`. T1 테이프에 3시가 없다. Case 07: 수정 슬립 `FILE 3 · CURTAIN UP: 4:00 to 3:00`, 도장은 바늘 없는 시계 + 잎 고리, 이름 없음. Case 08: 방패 배지 가방, 가방에서 떨어진 시각 변경 종이. Case 09: 정원 탑의 바늘이 빠져 있었다 |
| Bible 확정 | Victor = 시험 책임자, 실패를 숨기려고 기록 삭제를 지시했다. 런던과 무관. 처벌 장면 없음. 도장 문양과 사무실의 대응은 Case 11에서 회수한다(Bible §7) |
| 이번에 확정 (Bible v2.0) | 별관 방문 이유, 3쪽 4줄과 E.M./V.D., 찢긴 장부 쪽의 지시·서명, 사무실 도장, 가방·정원 바늘의 짧은 설명 |
| 말하지 않는 것 | E.M.의 이름·얼굴, Clockmaker, 런던, 시험 날짜, 오페라 공연 날짜, 오페라 기록을 바꾼 구체적 이유, 가방을 든 사람 |

---

## 2. 대화 화면 규칙 (Case 11·12 공용 `CaseTalk`, §9)
- 한 대화창에는 한 문장(3–8단어)만 둔다.
- 한 블록은 최대 4줄이고, 블록이 끝나면 반드시 질문·`SHOW`·조사 버튼이 나온다.
- NPC는 **증거를 본 뒤에만** 사실을 인정한다.
- **표기:** N = 내레이션, V = Victor(base / nervous / sad), YOU = 탐정, Q = 플레이어가 고르는 질문

---

## 3. Intro — Meet Victor (약 30초)
**장면:** `annex_street.png`(1–2줄) → `annex_reading_room.png`(3–8줄) → 9줄에서 방명록 확대 2초(`visitor_book_open.png` + `victor_signature.png`)

| # | 화자 | English | 한국어 |
|---|---|---|---|
| 1 | N | `Saint-Sulpice. A quiet street.` | 생쉴피스. 조용한 거리. |
| 2 | N | `A small door says: Archive Annex.` | 작은 문에 '기록 별관'이라고 적혀 있다. |
| 3 | N | `Inside, boxes go up to the ceiling.` | 안에는 상자가 천장까지 쌓여 있다. |
| 4 | N | `A man is reading old papers.` | 한 남자가 오래된 서류를 읽고 있다. |
| 5 | V (base) | `Hello. I am Victor Delacroix.` | 안녕하세요. 저는 빅토르 들라크루아입니다. |
| 6 | V (base) | `Long ago, I ran a clock test.` | 오래전에 저는 시계 시험을 맡았어요. |
| 7 | V (base) | `These papers will be locked away soon.` | 이 서류들은 곧 봉인될 거예요. |
| 8 | V (base) | `I came to see them one last time.` | 마지막으로 보러 왔어요. |
| 9 | N | `Victor signs the visitor book.` | 빅토르가 방명록에 서명한다. |
| 10 | N | `You sign it too.` | 당신도 서명한다. |

- 서명의 특징(곡선 V, 긴 밑줄, 끝의 점)은 말하지 않고 그림으로만 보여 준다.

**synopsis:** `Page 3 was sent to Saint-Sulpice.` 3쪽은 생쉴피스로 보내졌다. / `Is it really there?` 정말 거기 있을까? / `Who hid it?` 누가 숨겼을까?
**objectives:** `Find page 3.` 3쪽 찾기 / `Check Victor's paper.` 빅토르의 서류 확인하기 / `Find who signed it.` 서명한 사람 찾기

---

## 4. M1 — The Missing Page (약 2분)
**아이가 알게 될 것:** `The clocks were wrong!` 그리고 `Someone signed the order.`

| 항목 | 내용 |
|---|---|
| location | `ARCHIVE ANNEX · THE BIG BOOK` |
| 조작 | ① 연필로 다음 장 문지르기 ② 선반에서 9번 상자 고르기 ③ 노트 증거로 "사라진 그 쪽인가" 확인 |
| 재사용 | `EvidenceRecall`, `Paper`, 온보딩 손가락, `case_07/office_stamp.png`, `victor_signature.png`(흑연 질감으로 드러냄) |
| 신규 위젯 | `PencilRubbing` |

### 4.1 조사 전 대화
| 순서 | 화자 | English | 한국어 |
|---|---|---|---|
| Q (필수) | YOU | `We're looking for page 3.` | 우리는 3쪽을 찾고 있어요. |
| | V (base) | `Page 3? There was no page 3.` | 3쪽이요? 3쪽은 없었어요. |
| | V (base) | `Nothing happened after three o'clock.` | 3시 이후에는 아무 일도 없었어요. |
| Q (필수) | YOU | `A list says it came here.` | 목록에는 여기로 왔다고 적혀 있어요. |
| | V (nervous) | `Lists can be wrong.` | 목록은 틀릴 수도 있죠. |
| | V (base) | `Look in the big book, then.` | 그럼 저 큰 장부를 보세요. |

→ `LOOK IN THE BIG BOOK`

### 4.2 퍼즐
| 단계 | English | 한국어 | 조작·판정 |
|---|---|---|---|
| story | `This book lists every paper here.` | 이 장부에는 여기 서류가 모두 적혀 있다. | — |
| story | `Look! One page is torn out.` | 봐! 한 장이 찢겨 나갔어. | 제본선의 찢긴 밑동이 반짝인다 |
| 1 | `But the pen pressed hard.` / `Rub the next page with a pencil.` | 하지만 펜을 세게 눌러 썼어. / 다음 장을 연필로 문질러 봐. | 연필 토큰으로 문지른다. 세 영역(두 줄 + 서명)이 각각 70% 이상 덮이면 또렷해진다. 6초 동안 움직임이 없거나 reduce motion이면 탭으로 드러낸다 |
| | 드러남 ① `Page 3 → Box 9.` | 3쪽 → 9번 상자. | |
| | 드러남 ② `Lock it. No one may read it.` | 잠가라. 아무도 읽으면 안 된다. | |
| | 드러남 ③ (흐린 서명) | | `victor_signature.png`를 흑연 질감으로 표시 |
| | `Someone hid page 3. And signed it!` | 누군가 3쪽을 숨겼어. 그리고 서명까지 했어! | 서명이 한 번 빛난다(M3 예고) |
| 2 | `Find Box 9.` | 9번 상자를 찾아. | 선반의 상자 4개 `3`, `9`, `12`, `19` (번호는 이미지가 아니라 Flutter가 라벨 위에 표시. 2026-10-26 확정) |
| | 오답 `3`: `That's Box 3. Find 9.` | 그건 3번이야. 9번을 찾아. | |
| | 오답 `12`: `That's Box 12. Find 9.` | 그건 12번이야. 9번을 찾아. | |
| | 오답 `19`: `That's 19. Look for just 9.` | 그건 19야. 9만 찾아봐. | |
| 3 | `The box has a purple stamp.` / `A clock with no hands!` | 상자에 보라색 도장이 있어. / 바늘 없는 시계야! | 도장 확대. 지금은 해석하지 않는다(M2 씨앗) |
| 4 | `Is this the missing page?` | 이게 사라진 그 쪽일까? | Recall: 정답 `s2_ep10_e4` The Hour Was Recorded |
| | prompt `Find your clue from the Star Room.` | 별의 방에서 찾은 단서를 골라 봐. | 그 밖의 증거: `Look for the clue about page 3.` (3쪽에 관한 단서를 찾아 봐) |

**원본 3쪽 (코드 `Paper`, 누런 옛 종이)**
| English | 한국어 |
|---|---|
| `TRIAL LOG · PAGE 3 · 3:00–4:00` | 시험 기록 · 3쪽 · 3시–4시 |
| `3:00  The clocks are wrong! One hour behind!` | 3:00 시계가 틀렸다! 한 시간 늦다! |
| `3:10  E.M.: "Stop the test!"` | 3:10 E.M.: "시험을 멈춰요!" |
| `3:20  V.D.: "No. Keep going."` | 3:20 V.D.: "안 돼. 계속해." |
| `4:00  E.M. stops the machine.` | 4:00 E.M.이 기계를 멈춘다. |

- 4:00은 Case 10 T1 테이프가 4:00에 정상으로 돌아온 것과 맞는다.

**answer:** `rub:done,box:9,recall:s2_ep10_e4`
**successMessage:** `The clocks were wrong!` 시계들이 틀렸던 거야!
**hints:** ① `Rub every line with the pencil.` 연필로 줄을 모두 문질러 봐. ② `Box 9 is on the top shelf.` 9번 상자는 맨 위 선반에 있어.

### 4.3 증거 제시 → 반응
안내: `Show Victor what you found.` (빅토르에게 찾은 것을 보여 줘.) → `SHOW`
| 제시 | 화자 | English | 한국어 |
|---|---|---|---|
| **`s2_ep11_e1` Page 3 (정답)** | V (nervous) | `That box was locked!` | 그 상자는 잠겨 있었는데! |
| | V (nervous) | `…All right. There was a page 3.` | …알았어요. 3쪽은 있었어요. |
| 다른 증거 | V (base) | `I don't see what that means.` | 그게 무슨 뜻인지 모르겠군요. |

| 순서 | 화자 | English | 한국어 |
|---|---|---|---|
| Q (필수) | YOU | `Who are E.M. and V.D.?` | E.M.과 V.D.는 누구예요? |
| | V (nervous) | `V.D.… That's me.` | V.D.는… 저예요. |
| | V (base) | `E.M. worked on the machine.` | E.M.은 그 기계를 다루던 사람이에요. |
| | V (base) | `He left long ago.` | 그는 오래전에 떠났어요. |
| 마무리 | V (base) | `Here. Read my paper.` | 자, 제 서류를 읽어 봐요. |
| | V (base) | `It tells the real story.` | 진짜 이야기가 적혀 있어요. |

### 4.4 transition
| English | 한국어 |
|---|---|
| `Page 3 was hidden in Box 9.` | 3쪽은 9번 상자에 숨겨져 있었다. |
| `The clocks were wrong for one hour.` | 시계는 한 시간 동안 틀렸다. |
| `E.M. said, "Stop!"` | E.M.은 "멈춰요!"라고 했다. |
| `Victor said, "Keep going."` | 빅토르는 "계속해."라고 했다. |
| `Now, let's read Victor's paper.` | 이제 빅토르의 서류를 읽어 보자. |

### 4.5 Notebook
- **clue `s2_ep11_c1`** `The Rubbing` · value `Page 3 → Box 9` · note `"Lock it. No one may read it." And a name.` · 그림: 문지른 쪽(서명 포함). M3에서 다시 쓴다
- **evidence `s2_ep11_e1` Page 3** · icon `letter` · description `The missing page, found in Box 9.` · inscription `3:00: the clocks are wrong, one hour behind. E.M.: "Stop the test!" V.D.: "No. Keep going." 4:00: E.M. stops the machine.`
- EvidenceLink → `s2_ep10_e4`: `The page missing from the Star Room's book.`

---

## 5. M2 — Two Papers (약 2분)
**아이가 알게 될 것:** `Victor's paper is not true.`

| 항목 | 내용 |
|---|---|
| location | `ARCHIVE ANNEX · THE LONG TABLE` |
| 화면 | 왼쪽 Victor's paper(파란 표지, 아래에 보라색 도장), 오른쪽 Page 3, 아래 단서 카드 4장(직접 제공) |
| 조작 | ① 틀린 줄 탭 → 단서 카드 놓기 ② Victor의 말 → 단서를 보여 주고 도장 두 개를 겹쳐 비교 ③ "어느 쪽이 진실인가?" |
| 재사용 | 칩 끌어 놓기·탭-탭, `multipleChoice`, `CaseTalk` |
| 신규 위젯 | `PaperCompare` (도장 겹쳐 보기 포함) |

### 5.1 story
| English | 한국어 |
|---|---|
| `Victor gives you his paper.` | 빅토르가 자기 서류를 건넨다. |
| `Read it. Is it true?` | 읽어 보자. 사실일까? |

**Victor's paper (`victors_paper.png` + 코드 텍스트 + `office_stamp.png`)**
| 줄 | English | 한국어 |
|---|---|---|
| 머리 | `CLOCK TEST · V.D.` | 시계 시험 · V.D. |
| 1 | `The test began at 1:00.` | 시험은 1시에 시작했다. |
| 2 | `All the clocks were fine.` | 시계는 모두 괜찮았다. |
| 아래 | [보라색 도장] | |

**단서 카드 (직접 제공):** Page 3(`s2_ep11_e1`) · T1 Drum Tape(`s2_ep10_e1`) · The Amendment Slip(`s2_ep07_e3`) · The Hold Tag(`s2_ep06_e1`, 미끼)

### 5.2 1단계 — 틀린 줄
| 줄 | 맞는 단서 | 결과 |
|---|---|---|
| 1 (참) | — | 어떤 카드든: `That line is true.` (그 줄은 사실이야.) |
| **2** | Page 3 또는 T1 Drum Tape | V (nervous) `…Fine. The clocks were wrong.` (…알았어요. 시계가 틀렸어요.) |
| 2에 다른 카드 | — | `Which clue shows the clocks?` (시계를 보여 주는 단서는 뭘까?) |

### 5.3 2단계 — Victor의 말과 도장 (A3 해결)
| 순서 | 화자 | English | 한국어 |
|---|---|---|---|
| | V (nervous) | `One small mistake. That's all.` | 작은 실수 하나예요. 그게 다예요. |
| | V (base) | `My office never changed any papers.` | 우리 사무실은 서류를 바꾼 적이 없어요. |
| 안내 | N | `Is that true? Show a clue.` | 정말일까? 단서를 보여 줘. |
| SHOW 정답 | — | `s2_ep07_e3` The Amendment Slip | 수정 슬립 |
| 조작 | N | `Look at the two stamps.` | 도장 두 개를 봐. |
| | — | 슬립의 도장을 Victor 서류의 도장 위로 끌어 겹친다 | |
| 완료 | N | `The same stamp!` | 똑같은 도장이야! |
| | N | `His office changed the opera paper.` | 그의 사무실이 오페라 기록을 바꿨어. |
| | V (nervous) | `…That's our office stamp.` | …우리 사무실 도장이 맞아요. |

- 틀린 카드: Page 3 → `Page 3 is about the clocks. Which clue shows a changed paper?` (3쪽은 시계에 관한 거야. 바뀐 서류를 보여 주는 단서는?) / 그 밖 → `Look for a paper with a purple stamp.` (보라색 도장이 있는 종이를 찾아 봐.)
- 오페라 기록이 **왜** 바뀌었는지는 말하지 않는다. 아이가 알 것은 "Victor의 사무실도 기록을 바꿨다"뿐이다. 공연 날짜는 정하지 않는다.

### 5.4 3단계 — 진실 고르기
`Which paper tells the truth?` (어느 서류가 진실을 말할까?)
- ✅ `Page 3` → `Page 3 tells the truth!` (3쪽이 진실을 말해!)
- `Victor's paper` → `Victor's paper says the clocks were fine. Look again.` (빅토르의 서류에는 시계가 괜찮았다고 적혀 있어. 다시 봐.)

**answer:** `l2:s2_ep11_e1|s2_ep10_e1,stamp:s2_ep07_e3,truth:page3`
**successMessage:** `Victor's paper isn't true!` 빅토르의 서류는 사실이 아니야!
**hints:** ① `Which clue shows the clocks were wrong?` 시계가 틀렸다는 걸 보여 주는 단서는? ② `Find the opera slip. Look at its stamp.` 오페라 슬립을 찾아서 도장을 봐.

### 5.5 Victor의 반응
| 화자 | English | 한국어 |
|---|---|---|
| V (nervous) | `All right. My paper was wrong.` | 알았어요. 제 서류가 틀렸어요. |
| V (nervous) | `But I didn't hide page 3!` | 하지만 3쪽을 숨기진 않았어요! |
| V (base) | `Anyone in my office could do that.` | 우리 사무실 사람이라면 누구든 할 수 있었죠. |

### 5.6 transition
| English | 한국어 |
|---|---|
| `Victor's paper was not true.` | 빅토르의 서류는 사실이 아니었다. |
| `His office changed papers too.` | 그의 사무실은 다른 기록도 바꿨다. |
| `But who hid page 3?` | 그런데 누가 3쪽을 숨겼을까? |
| `Remember the name in the big book?` | 큰 장부의 서명 기억나? |

### 5.7 Notebook
- **clue `s2_ep11_c2`** `The Same Stamp` · value `Opera slip = Victor's office` · note `His office changed papers.`
- **evidence `s2_ep11_e2` Victor's Paper** · icon `letter` · description `Victor's paper about the clock test.` · inscription `It says all the clocks were fine. Page 3 and T1's tape say no. Its stamp is the same as the stamp on the opera slip.`
- EvidenceLink → `s2_ep07_e3`: `The same office stamp.`

---

## 6. M3 — Who Signed It? (약 1.5분)
**아이가 해야 할 일:** `Find who signed it.`

| 항목 | 내용 |
|---|---|
| location | `ARCHIVE ANNEX · THE VISITOR BOOK` |
| 조작 | 문지른 쪽(M1)의 서명을 투사지로 따라 그린 뒤(자동 1초), 방명록의 서명 3개 위로 끌어 겹쳐 본다 |
| 재사용 | `case_05/tracing_sheet.png`, clue `s2_ep11_c1` 그림 |
| 신규 위젯 | `SignatureTrace` |

| 단계 | English | 한국어 | 판정 |
|---|---|---|---|
| story | `The big book had a name.` | 큰 장부에 이름이 있었지. | 문지른 쪽이 다시 나온다 |
| | `Trace it. Then check the visitor book.` | 따라 그려. 그다음 방명록과 비교해. | |
| 서명 A | `The V is different. Try another.` | V가 달라. 다른 걸 봐. | 곧은 V |
| 서명 B | `No line under it. Try another.` | 밑줄이 없어. 다른 걸 봐. | 밑줄·점 없음 |
| **Victor** | `It's the same! Victor signed it.` | 똑같아! 빅토르가 서명했어. | 곡선 V + 긴 밑줄 + 끝의 점 |

- 방명록의 Victor 서명은 Intro에서 그가 직접 쓴 것이다. A·B는 이름이 읽히지 않는 오래된 방문자 서명이다(새 인물이 아님).

**answer:** `sign:victor`
**successMessage:** `Victor signed it!` 빅토르가 서명했어!
**hints:** ① `Move the tracing paper onto each name.` 투사지를 서명 하나하나에 올려 봐. ② `Look at the V, the line and the dot.` V 모양, 밑줄, 점을 봐.

### 6.1 transition
| English | 한국어 |
|---|---|
| `Victor said, "Lock it. No one may read it."` | 빅토르가 "잠가라. 아무도 읽으면 안 된다."라고 썼다. |
| `Then someone tore that page out.` | 그리고 누군가 그 장을 찢어 냈다. |
| `It's time to show him.` | 이제 그에게 보여 줄 때다. |

### 6.2 Notebook
- **clue `s2_ep11_c3`** `The Same Name` · value `Big book = visitor book` · note `Victor signed the order to hide page 3.`
- **evidence `s2_ep11_e3` Victor's Name** · icon `seal` · description `The name pressed into the big book.` · inscription `"Page 3 → Box 9. Lock it. No one may read it." Under it: the same curly V, long line and dot as Victor's name in the visitor book.`

---

## 7. Final — Victor's Truth (약 2분)
**아이가 해야 할 일:** 질문 세 개에 증거를 하나씩 보여 준다 → Victor가 인정한다.

### 7.1 세 번의 증거 제시
| # | 질문 | 정답 증거 | Victor (정답 후) | 틀린 증거일 때 |
|---|---|---|---|---|
| 1 | `What happened at three?` / 3시에 무슨 일이 있었죠? | Page 3 | V (nervous) `The clocks went wrong.` / 시계가 틀렸어요. | `That doesn't show the clocks.` / 그건 시계를 보여 주지 않아요. |
| 2 | `Whose paper wasn't true?` / 누구의 서류가 사실이 아니었죠? | Victor's Paper | V (nervous) `…Mine.` / …제 거요. | `That paper isn't mine.` / 그건 제 서류가 아니에요. |
| 3 | `Who signed the order to hide it?` / 숨기라는 지시에 누가 서명했죠? | Victor's Name | V (sad) `…I did.` / …제가 했어요. | `There's no name on that.` / 거기엔 이름이 없잖아요. |

**answer:** `q1:s2_ep11_e1,q2:s2_ep11_e2,q3:s2_ep11_e3`
**successMessage:** `Victor hid the truth!` 빅토르가 진실을 숨겼어!

### 7.2 고백
| 화자 | English | 한국어 |
|---|---|---|
| V (sad) | `Yes. I hid the page.` | 네. 제가 그 쪽을 숨겼어요. |
| YOU | `Why?` | 왜요? |
| V (sad) | `The test was my job.` | 그 시험은 제 책임이었어요. |
| V (sad) | `The clocks went wrong.` | 그런데 시계가 틀렸죠. |
| V (sad) | `I was afraid.` | 저는 두려웠어요. |
| V (sad) | `I didn't want people to know.` | 사람들이 알게 되는 게 싫었어요. |

### 7.3 남은 질문 — 증거 카드로 묻기 (A5)
고백 뒤 질문 목록에 `NEW` 표시와 함께 두 가지가 나온다. 둘 다 **카드를 보여 주는 방식**이다. 선택 사항이지만 강조 표시된다.

| 행동 | 화자 | English | 한국어 |
|---|---|---|---|
| SHOW `s2_ep08_e2` The Bag Sketch | V (sad) | `That's one of our office bags.` | 우리 사무실 가방이에요. |
| | V (sad) | `It took page 3 here.` | 그걸로 3쪽을 이리 옮겼죠. |
| 이어서 SHOW `s2_ep08_e4` The Torn Hour | V (sad) | `That's our form for changing a time.` | 시각을 바꿀 때 쓰는 우리 양식이에요. |
| | N | `So it fell from the office bag.` | 그러니까 사무실 가방에서 떨어진 거야. |
| SHOW `s2_ep09_e4` The Wrong Hour Test | V (sad) | `That little model showed the mistake.` | 그 작은 모형이 실수를 보여 줬죠. |
| | V (sad) | `I wanted the tests to stop.` | 저는 시험이 멈추길 바랐어요. |
| | N | `So the little clock lost its hands.` | 그래서 작은 시계의 바늘이 없어졌던 거야. |

- Victor는 **가방을 누가 들었는지 말하지 않는다**(`It took page 3 here.`). 바늘을 누가 뗐는지도 말하지 않는다. 아이에게 필요한 연결은 "가방도, 바늘도 Victor가 숨기려던 일과 이어져 있다"는 것뿐이다.
- 이 대화를 건너뛰어도 Case 11은 끝난다. Case 08–09를 기억하는 아이를 위한 보상이다.

### 7.4 Case 12로 잇는 대화 (필수)
| 화자 | English | 한국어 |
|---|---|---|
| YOU | `Did you change clocks this year?` | 올해 시계를 바꾼 적 있어요? |
| V (base) | `No. Not one clock.` | 아니요. 한 개도요. |
| YOU | `Then who left the clues for me?` | 그럼 누가 저에게 단서를 남긴 거죠? |
| V (base) | `Maybe E.M. knows.` | E.M.이라면 알지도 모르죠. |
| V (base) | `His old machine is at Arts et Métiers.` | 그의 옛 기계는 아르 에 메티에에 있어요. |

### 7.5 Notebook
- **evidence `s2_ep11_e4` Victor's Truth** · icon `seal` · description `What Victor said after you showed him the clues.` · inscription `"Yes. I hid the page. I was afraid. I didn't want people to know." His office bag took page 3 away. He wanted the tests to stop. He did not change any clocks this year.`
- 이 증거는 Case 12 엔딩에서 **Victor의 기록**으로 다시 나온다(Victor는 Case 12에 직접 등장하지 않음).

---

## 8. Case Closed — Next Lead (약 30초)
| 단계 | English | 한국어 |
|---|---|---|
| 화면 | 지도(`paris_mystery.png`)에서 Arts et Métiers 탭 → 빛남(Case 09 T3 자리) | |
| 질문 | `Where is E.M.'s old machine?` | E.M.의 옛 기계는 어디에 있을까? |
| 다른 곳 탭 | `Victor said Arts et Métiers.` | 빅토르는 아르 에 메티에라고 했어. |
| 완료 1 | `Victor hid the truth.` | 빅토르는 진실을 숨겼다. |
| 완료 2 | `But who left the clues for me?` | 하지만 누가 나에게 단서를 남겼을까? |
| 완료 3 | `Let's find E.M.` | E.M.을 찾으러 가자. |

**hook:** `Who left the clues for me?`
**caseSummary:** `You found page 3 in a hidden box. It said the clocks were wrong. Victor's paper was not true. His name was under the order to hide the page. Victor hid the truth.`
**keyWords:** `missing`, `hidden`, `true`, `not true`, `stamp`, `signed`, `afraid`
**upcoming:** `{'12': "The Clockmaker's Truth"}`

---

## 9. 대화 시스템 `CaseTalk` (Case 11·12 공용)
- **현재:** NPC 대화는 Season 1 Case 06 M1(`dialogue_investigation.dart`)에만 있다. 증거 제시, 표정 변경, 대화 중 저장이 없다.
- **확장:** Season 1의 `_Portrait`·`_Speech`·질문 버튼을 공용 위젯으로 꺼낸다(Season 1 동작 그대로, `test/case06_dialogue_test.dart`가 계속 통과해야 함). Season 2 전용 `SeasonContent.talks` 테이블을 추가한다.
- **`SHOW`:** 기존 `EvidenceRecallDock`의 선택 시트를 재사용한다. 틀린 제시는 오답으로 세지 않는다.
- **표정:** 대사마다 표정 키를 둔다. 200ms 크로스페이드, reduce motion이면 즉시 바뀐다.
- **저장:** `puzzleStates[missionId]['talk']`. 새 저장 키는 없다. 이미 본 대화는 `SKIP` 가능.
- **`TALK LOG`:** 들은 대사를 다시 볼 수 있다.
- **뒤로가기:** 미션 이야기 단계로 돌아간다.
- **Game Master:** `season2Json` 등록으로 바로가기에 나타난다.
- **화면:** 배경 + 가운데 초상화 + 아래 대화창. 질문 버튼은 최대 3개, 48dp 이상. `SHOW`는 오른쪽 아래에 고정한다.

## 10. 플레이 시간
| 구간 | 시간 |
|---|---|
| Intro | 0:30 |
| M1 | 2:00 |
| M2 | 2:00 |
| M3 | 1:30 |
| Final (+ 선택 질문) | 2:00–2:30 |
| Case Closed | 0:30 |
| **합계** | **약 8:30–9:00** |

한 퍼즐에서 기억할 것은 숫자 하나(9), 틀린 줄 하나 + 도장 하나, 서명 특징 셋이 최대다.

## 11. 구현 메모
- **신규 위젯:** `CaseTalk`, `PencilRubbing`, `PaperCompare`, `SignatureTrace`
- **등록:** `season2_mock.dart`(Case 11, `upcoming` 12), `season2_discoveries.dart`, `season2_learning.dart`, `art_assets.dart`, `pubspec.yaml`(`case_11/`, `characters/`)
- **테스트(구현 시):** `test/paris_case11_test.dart`, `test/case06_dialogue_test.dart`, `test/case_shortcuts_test.dart`(현재 "11·12 coming soon" 기대값), `flutter analyze`
- **Game Master 정답지:** `docs/CASE_ANSWER_GUIDE.md`

### 11.1 학습
| 미션 | expressions |
|---|---|
| m1 | `missing`, `torn out`, `Stop!`, `Keep going.` |
| m2 | `true`, `not true`, `the same stamp` |
| m3 | `signed`, `the same` |
| final | `Why?`, `I was afraid.` |

`CaseLanguageTopic`: `True or not true?` / `사실일까, 아닐까?`

### 11.2 Glossary
archive 기록 보관소 · annex 별관 · page 쪽 · missing 사라진 · torn out 찢겨 나간 · rub 문지르다 · pencil 연필 · box 상자 · lock 잠그다 · stamp 도장 · test 시험 · wrong 틀린 · behind (시간이) 늦은 · machine 기계 · keep going 계속하다 · paper 서류 · fine 괜찮은 · true 사실인 · office 사무실 · changed 바꿨다 · signed 서명했다 · visitor book 방명록 · trace 따라 그리다 · order 지시 · hide 숨기다 · afraid 두려운 · form 양식 · model 모형 · mistake 실수 · locked away 봉인된
