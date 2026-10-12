# London Mystery — Notebook & Cross-Case Learning Audit (Phase 4)

> 감사일: 2026-10-12 · **읽기 전용** (앱 소스·콘텐츠·정답·UI·저장 데이터·PROJECT_CONTEXT 변경 없음, 이 문서만 신규)
> 기준선: `flutter analyze` No issues · `flutter test` **878 passed** (이번 감사에서 실행)
> 기준 콘텐츠: Case 01~12 TYPE B 개선 적용 후 (Essential 41 / Helpful 6 / Low 3)
> 표기: ✅ 구현됨 · ⚠️ 부분/조건부 · ❌ 없음 · **R0~R3** = PROJECT_CONTEXT의 재사용 등급(R3 = 플레이어가 기억하거나 Notebook에서 확인해 실제 추리에 사용)

---

## 1. 요약

- **사건 간 증거 추리(R3)는 3곳**(03 → 08 Red Button, 01 → 11 Old Letter, 04 → 12 small red clock)이며, 셋 다 **필요한 영어 원문이 Archive에 보관되어 있고, 접근 경로가 있고, 테스트로 고정**되어 있다. 일반 플레이에서는 P0(이전 단서 접근 불가·잘못된 단서·저장 손상)이 **없다.**
- **사건 간 "영어 표현" 재사용은 약하다.** 같은 단어가 다시 나오는 경우(north, left/right, agree, smallest, 숫자 단어)는 많지만, **앞 사건에서 배운 표현의 의미를 알아야 풀리는 곳은 거의 없다**(각 사건이 그 표현을 다시 설명하거나 문맥으로 풀린다). whose(09)·전치사(07)·before/after(02)는 이후 다시 요구되지 않는다.
- **Case 12**는 synopsis가 "Every case you solved was a piece of this night"라고 하지만, 실제 이전 사건 의존은 M2 하나(R3)뿐이고 나머지는 R1~R2다.
- **Notebook은 탐정 수첩으로서 잘 작동한다**(사건 단서·증거, 12개 사건 Archive, Final의 수첩 시트, 미션으로 그대로 복귀). 부족한 것은 ① **Notebook 안의 영어(단서 메모·증거 글귀)를 눌러 뜻을 볼 수 없음**, ② **원래 편지(미션의 영어 문서)를 해결 후 다시 볼 수 없음**, ③ **Operator Mode에서 이전 사건 Archive가 닫혀 R3 퍼즐이 막힘**(디버그·플레이테스트 빌드 한정).

---

## 2. 현재 구조 (실제 소스)

### 2-1. 화면과 경로

| 요소 | 구현 | 근거 |
|---|---|---|
| Notebook 화면 | ✅ `THIS CASE`(CLUES / EVIDENCE / BADGES) + `CASE ARCHIVE` 두 부분 | `notebook_screen.dart` (`_NotebookParts`, `_CluesTab`, `_EvidenceTab`, `_BadgesTab`) |
| Case Archive | ✅ 12개 사건 폴더(아코디언). **해결한 사건 = 그 사건의 모든 Evidence·Clue**(다시 플레이 중에도), 진행 중·시작한 사건 = 그 세이브에서 찾은 것, 열리지 않은 사건 = 열 수 없음 | `season_archive.dart` `seasonArchiveProvider` |
| Evidence 상세 | ✅ 탭 → 확대(이름·장소·설명·글귀 `inscription`·기호) | `evidence_card.dart` `showEvidenceZoom` |
| Clue | ⚠️ 카드에 제목·값·메모·장소·기호 표시. **탭/확대 없음** | `clue_card.dart` |
| 미션 → Notebook → 미션 | ✅ 앱바 수첩 아이콘(push) → Back이면 **같은 퍼즐 단계로 복귀** | `mission_screen.dart`, 테스트 `season_archive_test` "Case 12 mission → notebook → archive → Case 04 evidence → back to the same puzzle" |
| Final → 수첩 | ✅ `OPEN MY NOTEBOOK` 시트(이 사건 단서·증거) + `OPEN THE CASE ARCHIVE`(다른 사건을 하나라도 해결했을 때만) | `final_mission_screen.dart:150` (`earlierCases`), `season_archive_test` |
| 원래 편지(미션 영어 문서) | ⚠️ 미션 중에는 `Letter` 버튼으로 다시 읽기 가능. **해결 후에는 Notebook·Archive 어디에도 없음**(요약된 Clue 메모·Evidence 글귀만 남음) | `mission_screen.dart` `_rereadLetter`; Notebook에 letter 필드 표시 없음 |
| Notebook 안 단어 뜻 | ❌ Clue 메모·Evidence 글귀는 일반 `Text` → 단어를 눌러 뜻을 볼 수 없음. 단어 뜻 보기(`GlossaryText`)는 장면·편지·질문·Story에만 | `clue_card.dart`, `evidence_card.dart` (Text), `glossary_text.dart` 사용처 |
| Glossary 범위 | ⚠️ **현재 사건의 glossary만** 사용(`currentEpisodeProvider`) → 다른 사건 Archive의 글귀에 적용하려면 그 사건의 glossary가 필요 | `glossary_text.dart`, `Episode.meaningOf` |

### 2-2. 저장 데이터

| 데이터 | 저장 | Notebook과의 관계 |
|---|---|---|
| 찾은 Clue·Evidence | 저장 안 함 — `completedMissionIds`에서 **계산** | 세이브가 바뀌지 않는 한 손상 위험 없음 |
| 사건별 세이브 | `lm.progress.v1`(Case 01) / `lm.progress.v1.epNN` | Archive가 읽기만 함 |
| 해결한 사건 | `lm.season.v1` `solvedEpisodeIds` | 해결한 사건 = Archive 전체 공개 |
| 찾아본 단어 | `GameProgress.lookedUpWords`(사건별, Play again 시 초기화) + `behavior.words` | **부모 보고서에만 표시**, 아이 화면에는 없음 |
| 탐정 행동 | `behavior.evidenceViewed`(수첩·Archive·Final 수첩의 증거 열기), `rechecked` | Notebook Explorer·Second Look 배지 |

### 2-3. Operator Mode / Playtest Mode

| 모드 | 이전 사건 Archive | 영향 |
|---|---|---|
| 일반 플레이 | 해결한 사건 전부 열림 | 정상 |
| Playtest `CASE NN부터` | 앞 사건을 "해결"로 기록 → Archive 전체 공개 | **R3 퍼즐 정상**(체크리스트도 이 경로를 안내) |
| **Operator Mode**(디버그·`LM_PLAYTEST` 빌드만, `operatorToolsInBuild`) | 모든 사건이 열리지만 **해결 기록 없음** → 이전 사건은 "NOT OPENED"(열 수 없음), Final의 `OPEN THE CASE ARCHIVE` 버튼도 숨김 | **08-F, 11-F, 12-M2를 Archive로 풀 수 없음**(기억·찍기·피드백으로만). 그런데 Hint는 "Open Case 03 in your Case Archive"라고 안내 → 진행자 시연 중 막힐 수 있음. 출시 빌드에는 영향 없음 |

---

## 3. Case 01~12 연결 지도

### 3-1. 증거·사실 연결 (실제 데이터)

| Earlier Case | Later Case | English Expression | Evidence | Current Usage | Improvement |
|---|---|---|---|---|---|
| 01 | 11 Final | "Signed: The Shadow / P.S. I love trains!", "We met at the very start" | Old Letter (Archive Case 01) | **R3** — 마지막 Hint가 Archive Case 01로 안내, 보호 테스트 고정. 단, 보기 소거로도 접근 가능(Grey·Robin·Ravenmaster는 이미 아군/정체 알려짐) | 유지. (P2) 보기 구성 검토는 보호 규칙 재논의 필요 |
| 03 | 08 Final | "From a coat", "I was never in Gallery 8", "prove" | Red Button (Archive Case 03, 장소 GALLERY 8) | **R3** — Archive 4탭, 보호 테스트 고정, 피드백도 금지어 준수 | 유지 |
| 04 | 12 M2 | "Platform 4 has a small red clock" → "always arrives on the platform with the small red clock" | Clue "Platform 4"(메모 "under the red clock on Platform 4"), Word Card | **R3** — Hint 1이 Archive Case 04로 안내, 테스트 고정 | 유지. Clue 메모에 "small"이 없으나 의미상 충분 |
| 02 | 12 M1 | "the small raven stamp — the one you found in Case 02", brass, eight teeth | Small Brass Gear ("A tiny raven is stamped on it.") | **R2** — 편지가 세 조건을 다시 다 말함, Notebook 불필요 | (P1 후보) 조건 하나를 Case 02 증거에서만 확인하게 |
| 05 | 12 Final | "six ravens… and one more" → "how many ravens guard the Tower?" | Clue "Seven Ravens"(Case 05 / Case 12 M3 둘 다) | **R2** — Case 12 M3 Clue가 7을 다시 줌 | (P2) 유지 가능 — 피날레 속도 |
| 05 | 12 M3 → F | "FOR THE CLOCKMAKER'S DOOR" | Brass Key | **R1** — 이야기 회수 | 유지 |
| 05 | 07 | "Half of an old map" | Old Map Fragment | **R1** — 07 intro가 말해 줌 | 유지 |
| 06 | 10 F → 11 | "ROW R · SEAT 17" | Theatre Ticket | **R1** — 10 Post-Case·11 synopsis가 말함 | 유지 |
| 07 | 08 | "Nine small ravens are drawn around Platform 9." | The Old London Map | **R1** — 08 intro가 말함 | 유지 |
| 08 | 09 | "BUCKINGHAM PALACE — it is empty." | Empty Jewel Box | **R1** — 09 intro가 말함 | 유지 |
| 02 | 03 | "Gallery 8 · Picture 17", 9:17 | Time Card | **R1** — 03 intro "9:18 AM… Gallery 8, Picture 17" | 유지 |

### 3-2. 영어 표현 재등장 (같은·비슷한 표현이 나중 사건에 다시 쓰이는가)

| Earlier Case | Later Case | English Expression | Evidence | Current Usage | Improvement |
|---|---|---|---|---|---|
| 04 | 11 M2 장면 | "where trains **never sleep**" → "the station that **never sleeps**" | — | **R1, 표현 재등장** — 장면 대사. 11-M3 편지가 "a big station"을 다시 말해 의미 이해 없이도 진행 | (P1 후보) 11-M3 Hint 1에 "never sleeps"를 Case 04와 연결하는 한 줄 — 단, 보호 규칙(door 금지 등) 확인 후 |
| 06 | 11 M1 | "Two witnesses **agree**" → "One witness **does not agree**" | Witness Notes / Usher's Notes | **표현 재사용 + 새 상황(부정)** — 11-M1을 푸는 데 agree의 뜻이 필요. 11 glossary에 agree 있음 | 좋은 사례. 유지 |
| 05 | 07 | "Turn **left** at…", "on the **right**", "the other way" → "Turn **right** at the bridge", "turn **left**" | Ravenmaster's Card / Joined Map | **어휘 재등장** — 07에서 필수(지도). 단 07은 05를 참조하지 않고 스스로 정의 | 자연스러운 반복. 유지 |
| 03 | 07 · 10 · 11 | "**north** door", "Take me **north**" → "arrow goes **north**", "NORTH", "ran **north**" | Wet Footprint / Joined Map / Raven Papers | **어휘 재등장** — 07-F에서 필수, 나머지는 보조 | 유지 |
| 02 | 10 M1 | "the **smallest** bell" → "Poppy is the **smallest**" | — | **어휘 재등장**, 각 사건 안에서 의미 해결 | 유지 |
| 01 | 05 · 08 | number words "**SEVEN**", "**FOUR**" → "**SEVEN** ravens", "**forty-two**" | — | **어휘 재등장**, 05-M3·08-M3에서 필수 | 유지 |
| 02 | 09 · 12 | "**one hour after**", "between eight and nine" → "every **two hours**", "**third** change" → 시간표 "11:40" | Time Card / Guard Timetable / Arrivals Board | **시간 읽기 기능의 재사용**(표현은 다름) | (P1 후보) 12에 before/after 해석을 한 번 요구 |
| 03 | 11 M3 | "a tall **clock tower**" (King's Cross) → "two big **arches** and a **clock tower**" | — | **묘사 재등장** — 같은 장소를 다른 말로 묘사 | 유지 |
| 09 | — | "**whose** key you used" | Gold Key Clue | **R0** — 이후 재사용 없음 | (P1 후보) Case 12에서 한 번 |
| 07 | — | past / beside / **behind** / above / below | Joined Map 등 | **R0** — 이후 퍼즐에서 요구 없음 | (P1 후보) Case 12에서 한 번 |
| 10 | — | WHO / WILL / WHAT / WHEN 어순 | The Raven's Warning | **R0**(경고문 자체는 12 intro로 이어지는 서사) | 유지 가능 |

**정리:** 사건 간 연결은 "사실·증거" 축(R3 3개)은 탄탄하고, "영어 표현" 축은 **어휘 재등장 수준**이다. 앞 사건에서 배운 표현의 의미가 뒤 사건의 추리를 결정하는 경우는 **06 → 11 (agree)** 정도이며, 의도적으로 설계된 언어 재사용 사슬은 없다.

---

## 4. 학습 연속성 평가

| 기준 | 평가 | 근거 |
|---|---|---|
| 이전 표현의 자연스러운 재등장 | **좋음** | 3-2의 어휘 재등장이 이야기 안에서 자연스럽다(지도·증언·시계) |
| 표현의 의미 이해 | **보통** | 재등장한 표현은 대부분 그 사건 안에서 다시 설명되거나 glossary가 있음 → 앞 사건의 이해를 "확인"하지는 않음 |
| 새 상황에서의 활용 | **약함** | agree → does not agree(06 → 11) 외에 앞 표현을 새 상황에 적용해야 하는 퍼즐 없음 |
| 영어와 증거 추리의 결합 | **좋음(사건 간 3곳)** | 03 → 08, 01 → 11, 04 → 12는 **영어 글귀를 다시 읽어야** 풀린다(단순 숫자 회수가 아님) |
| 8~12세 난이도 | **적절 / 주의** | R3 3곳은 Hint가 Archive 경로(Case 번호)까지 안내 → 기억 부담 완화. 단 Archive 4탭은 8~9세에게 탐색 부담(플레이테스트 관찰 항목) |
| 이전 사건 기억에 대한 과도한 의존 | **없음** | R3 정보가 모두 Archive에 남아 있고 Hint가 경로를 알려 줌. 기억을 요구하지 않음 |

**Case 08 · 11 · 12 집중 분석**

- **Case 08 Final:** 설계가 가장 탄탄하다. 그녀의 거짓말("never in Gallery 8") + Case 03의 "From a coat"(장소 GALLERY 8)를 연결해야 한다. 페이지·Hint·피드백 모두 답(button/coat/red)을 말하지 않음(테스트). 약점: 08-M2 장면이 "a long red coat and a blue scarf"를 말해 Miss Rose를 강하게 떠올리게 함(의도된 복선, 유지 권장).
- **Case 11 Final:** Archive Case 01의 서명으로 풀리도록 설계. 그러나 보기 소거(Grey·Robin·Ravenmaster는 정체가 이미 드러남)로 영어 없이도 도달 가능 — PROJECT_CONTEXT도 "R3(약)"로 기록. 11-M1(agree)과 11-M2 장면(never sleeps)은 앞 사건 표현의 좋은 재등장.
- **Case 12:** synopsis "Use everything you learned"와 달리 실제 의존은 **M2 하나(R3)**. M1은 편지가 조건을 다 말하고(R2), M3 수수께끼는 Big Ben이 서사상 이미 정해져 있고(Helpful), Final은 이번 사건의 단서 세 개로 풀린다(Phase 1에서 질문을 읽게 바꿈). 시즌 피날레로서 **언어 회수(whose·전치사·before/after)의 기회가 가장 큰 사건**.

---

## 5. Notebook UX 평가

| 항목 | 평가 |
|---|---|
| 탐정 수첩 정체성 | ✅ 종이 수첩·사건 폴더·증거 확대. 학습 대시보드·진도율·시험 없음 |
| 지금 필요한 정보 찾기 | ✅ THIS CASE에 이번 사건 단서·증거, Final 시트에 같은 내용 + Archive 링크 |
| 이전 사건 단서 찾기 | ✅ Archive(해결 사건 전체). 4탭(수첩 → CASE ARCHIVE → 사건 폴더 → 증거) |
| 영어 원문 다시 읽기 | ⚠️ 증거 **글귀**·단서 **메모**는 있음. **원래 편지 전문은 없음** (예: 04의 짐꾼 네 문장, 08의 승객 증언 — 결론만 Clue에 남음) |
| 모르는 단어 확인 | ❌ Notebook·Archive의 영어를 눌러도 뜻이 안 나옴 — 미션 화면과 다르게 동작(일관성 부족). 아이가 증거를 **다시 읽는 바로 그 순간**에 도움이 없음 |
| Clue 상세 | ⚠️ 카드에 다 보이지만 확대 없음(문제는 아님) |
| 찾아본 단어 기록 | 부모 보고서에만. 아이용 단어장은 **금지 사항이므로 만들지 않는 것이 맞음** |
| 탭 수 | 적정(새 탭 불필요) |

**최소 개선안 (탐정 수첩 정체성 유지, 새 탭·학습 화면 없음)**
1. **증거 확대 화면과 단서 카드의 영어에 단어 뜻 보기 적용**(그 증거·단서가 속한 사건의 glossary 사용). 미션 화면과 같은 점선 밑줄 → 탭 → 뜻 카드. 새 화면 없음.
2. **(선택) 증거 확대 화면에 "원래 편지" 한 줄 열기**: 그 증거를 준 미션의 편지를 접힌 종이로 다시 보기(이미 있는 `LetterCard` 재사용). 새 탭 없음, 증거 상세 안에서만.

---

## 6. 개선안 (P0 / P1 / P2)

### P0 — 해당 없음
- 이전 단서 접근 불가: **일반 플레이·Playtest Mode에서는 없음**(Operator Mode는 P1로 분류: 출시 빌드에 없음)
- 잘못된 영어 단서: **없음** — R3·R2·R1 연결 13곳의 Hint 문장과 Archive 내용을 대조함(예: 12-M2 Hint "Which platform had the small red clock?" ↔ Case 04 Clue "under the red clock on Platform 4", 11-F Hint "Who signed it?" ↔ Old Letter "Signed: The Shadow")
- 저장 데이터 손상 위험: **없음** — Notebook은 아무것도 저장하지 않고 세이브에서 계산

### P1

| # | 문제 | 근거 | 개선 방향 | 예상 수정 파일 | 저장 데이터 영향 | 승인 필요 |
|---|---|---|---|---|---|---|
| P1-1 | **Operator Mode에서 이전 사건 Archive가 닫혀** 08-F·11-F·12-M2를 Archive로 풀 수 없는데 Hint는 Archive로 안내 | `seasonArchiveProvider`(해결 기록이 있어야 전체 공개), `final_mission_screen.dart:150` | Operator Mode일 때만 열린 사건의 Archive를 **참고용으로 전체 공개**(해결 기록은 만들지 않음) 또는 Operator 화면에 "R3 사건은 CASE NN부터를 쓰세요" 안내 | `season_archive.dart`, `final_mission_screen.dart`(또는 `game_master_screen.dart` 안내만) | 없음(표시만) | 예 — 방식 선택 |
| P1-2 | **Notebook 안 영어에 단어 뜻 보기 없음**(미션 화면과 불일치) | `clue_card.dart`, `evidence_card.dart` Text 사용, `GlossaryText`는 현재 사건 glossary만 | `GlossaryText`에 사용할 사건(glossary)을 넘길 수 있게 하고, 증거 확대·단서 카드에 적용. 찾아본 단어는 현재 실행의 기록에 그대로 쌓임 | `glossary_text.dart`, `evidence_card.dart`, `clue_card.dart`, 호출부(notebook·archive·final 시트) | 없음(기존 `lookedUpWords`·`behavior.words`에 추가될 뿐) | 예 |
| P1-3 | **Case 12가 시즌 영어를 거의 다시 쓰지 않음**(R3 1곳) | 3-1, 3-2 (whose·전치사·before/after R0) | 콘텐츠 후보(정답 불변): 12-M1 조건 하나를 Case 02 증거에서만 확인(예: 편지에서 "the stamp you found in Case 02"를 "the same stamp as the gear from Case 02"로 바꾸고 보기에 다른 새 도장 추가) / 12-M3 또는 12-F 질문 한 줄에 전치사(07)·whose(09)·before(02) 중 하나를 쓰게 | `episode12_mock.dart`, `season1_learning.dart`, 테스트 | 없음(콘텐츠) | 예 — 문구별 승인 필요(보호 규칙: 12 Final 정답 487, PARIS, door/under Big Ben 규칙) |
| P1-4 | **11-M2 장면의 "never sleeps"가 Case 04와 연결되지 않음**(표현 재등장만) | 3-2 | 11-M3 Hint 1 또는 피드백 한 줄에서 "'never sleeps' — you read that in Case 04"처럼 회상 연결(정답·장면 불변) | `episode11_mock.dart` | 없음 | 예(보호 규칙 확인: shadow·door 금지) |

### P2

| # | 내용 | 예상 수정 | 저장 영향 |
|---|---|---|---|
| P2-1 | 증거 확대에서 "원래 편지" 다시 보기(접힌 종이, `LetterCard` 재사용) | `evidence_card.dart`(+ 미션 조회) | 없음 |
| P2-2 | Archive 탐색 단축: R3 Hint가 가리키는 사건 폴더를 열린 상태로 Archive 진입(예: `?view=archive&case=ep03`) | `notebook_screen.dart`, `season_archive.dart`, 라우터 쿼리 | 없음 |
| P2-3 | Clue 카드 탭 → 단서를 준 미션 장소·메모 확대(지금은 확대 없음) | `clue_card.dart` | 없음 |
| P2-4 | 11-F 보기 구성(소거로 접근 가능) 재검토 | `episode11_mock.dart` + 보호 규칙 재논의 | 없음 |

**만들지 않는 것(제약):** 단어장 탭, 학습 대시보드, 진도율, 단어 시험, 문법 설명 화면, 교육용 카드.

---

## 7. 권장 구현 순서와 승인 항목

| 순서 | 항목 | 이유 | 승인 |
|---|---|---|---|
| 1 | **P1-2 Notebook 단어 뜻 보기** | 코드만, 콘텐츠·정답·저장 무관. "증거를 다시 읽는 순간"을 직접 돕는 가장 작은 변경 | 필요 |
| 2 | **P1-1 Operator Mode Archive** | 플레이테스트·시연 중 막힘 방지. 방식 선택 필요(참고용 공개 vs 안내만) | 필요(방식) |
| 3 | **P1-3 / P1-4 콘텐츠** | Case 12·11 언어 회수. 보호 규칙이 많아 문구별 승인 | 필요(문구별) |
| 4 | P2-1 ~ P2-4 | 플레이테스트 결과(Archive 탐색 부담, 원문 재독 요구)를 보고 결정 | 필요 |

**검증 계획(구현 시):** 기존 보호 테스트(`wave1/wave2/case09_reasoning_test`, `final_small_pass_test`, `season_archive_test`) 기대값 불변, Notebook 단어 뜻 위젯 테스트(360×640·390×844), 다른 사건 Archive 글귀가 **그 사건의 glossary**로 뜻을 보이는지, Operator Mode에서 해결 기록이 생기지 않는지, 저장 JSON 형식 불변.
