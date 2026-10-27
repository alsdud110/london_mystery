# Paris Case 04~06 — 난이도별 영어 콘텐츠 검토 보고서 (PART 7B)

> Season 2 *Paris Stands Still*, Case 04 *The River's Secret* · Case 05 *The Silent Workshop* · Case 06 *The Letter That Never Arrived*.
> 작업: 2026-10-27, 로컬 `main`(시작 HEAD `611c5ea`, 사용자 승인 후 `origin/main`으로 fast-forward). 기준 문서: `docs/SEASON2_PARIS_STORY_BIBLE.md`(§1 정사, §6 Case 06 v1.4, §7 회수표, §8 공개 단계, §9 인과), PART 7A 보고서 `PARIS_CASE_01_03.md`.
> 영어 원문 전체는 **부록 A**(실제 적용 데이터에서 자동 추출)에 있다. 본문 표는 대표 문장이다.

## 0. 결과 요약

- `s2_ep04`~`s2_ep06`를 Rookie·Junior·Master로 `season2WrittenLevels`에 등록했다. 세 사건 모두 세 난이도에서 `missingAt`이 빈 목록이고, `problems()`도 빈 목록이다.
- **Rookie**: 기준본 문장을 그대로 쓴다(이미 VERY EASY 문체). 어색한 두 줄만 Rookie 패치로 바꿨다(§D). glossary에는 사건마다 단어를 더했다.
- **Junior·Master**: 사건 파일 텍스트(synopsis·objectives·intro·caseSummary·hook)를 모두 썼다. 미션 텍스트도 모두 썼다: story·letterIntro·letter·question·hints·successMessage·transition·선택지 오답 줄·오답 줄 맵·단서 note·증거 description. 여기에 장면 문장 5종, EasySteps 3개, 학습 표현 12개, glossary를 더했다.
- **구조 검사**: 장면 11종과 `EasyStepsScene`(패널 7종 포함)을 `season2StructureOf`에 추가했다(§F).
- **불변**: 정답·선택지 id/순서/라벨·힌트 수와 가격·코인·증거 id/이름/글귀·단서 값·미션 순서·EasySteps 단계/정답/힌트 수·장면 구조는 세 난이도에서 같다. 테스트가 이를 고정한다.
- **검증**: 신규 `test/difficulty_paris_7b_test.dart` 30개. `flutter analyze` 0 issues. 전체 `flutter test` 2446개 통과(기존 2416 + 신규 30).

## A. 사건별 스토리 요약 (작성 전 전수조사)

### Case 04 — The River's Secret (Seine Quays)
| 항목 | 내용 |
|---|---|
| 사건 | Case 03 명판 뒷면의 세 줄(물결 셋 / 강 쪽 화살표 / 물을 지켜보는 사람)이 강변으로 이끈다. 에펠탑에서 사라진 상자가 어디로 갔는가 |
| 장소 | 강둑 벽(QUAY 3) → 강 관리인 오두막 → 초록 보관함 → 오두막 안 거리 책자 → PASSAGE DES HORLOGERS 대문 |
| 인물 | River Keeper(장부로만 등장, 공범 근거 없음 — 바이블 §3), 서명 J.M., 두 시계바늘 서명(정체 미공개) |
| 목표·퍼즐 | M1 네 표식 중 세 줄 모두 맞는 것(답 Mark D) · M2 장부에서 에펠탑 짐 중 QUAY 3, 그리고 이동(Box 17→23)(답 Box 23) · M3 찢긴 배송표 FROM/CONTENTS/TO 맞추기, 다른 종이 조각 제외 · Final(very easy) CLUE 1 PASSAGE + CLUE 2 No. 7 → PASSAGE DES HORLOGERS |
| 단서 | QUAY 3, 장부(13~15 MAY, Box 23 collected for No. 7), 라벨(FROM: EIFFEL TOWER — SERVICE LEVEL / CLOCK PARTS / TO: THE WATCHMAKERS / PASSAGE D…), 마지막 조각 `ES HORLOGERS`와 뒷면 `Do not trust the clocks. Follow the hands that made them.` |
| 연결 | 03→04 SEINE 명판(뒷면) / 04→05 주소 + 두 바늘(바이블 §9) |
| 비밀(공개 금지) | 부품의 최종 용도, 두 바늘 = 누구, Clockmaker 정체. `ES HORLOGERS`는 Final 정답 전에 어디에도 나오지 않는다 |

### Case 05 — The Silent Workshop (Passage des Horlogers No. 7)
| 항목 | 내용 |
|---|---|
| 사건 | 아무도 없는 No. 7 공방. 시계들은 움직이는데 조용하다. 탑의 부품이 왜 여기 왔나 |
| 인물 | "the maker"(쪽지·카드·메모로만), 우편 기록 |
| 목표·퍼즐 | M1 대조지로 진짜 서명 찾기(D 작은 서랍) · M2 1분 관찰 + 뒷면 → 바퀴 추가 + 거꾸로 도는 Clock III · M3(very easy) 거울 → THE CLOCK THAT TURNS BACK → Clock III · Final(very easy) 4417/4471 중 4417 → 경로 9:00 COLLECTED · 11:00 SORTED · 4:00 PM HELD · LOUVRE POST ROOM |
| 단서 | 수리 카드, Clock III 바퀴, 영수증 `16 MAY — ONE LETTER COLLECTED FROM No. 7. LETTER No. 4417.`, 찢긴 봉투 모서리, 우편 슬립 |
| 연결 | 05→06 HELD · LOUVRE POST ROOM, 끝 질문 `Who held the letter at the Louvre post room?` |
| 비밀 | 편지 내용·보류자·보류 이유·제작자 신원. **편지가 실제로 Clock III에 있었다/누가 꺼냈다고 단정하지 않는다**(바이블 §1) — "메모가 그렇게 말했다" + 질문으로만 |

### Case 06 — The Letter That Never Arrived (Louvre post room → archive)
| 항목 | 내용 |
|---|---|
| 사건 | 4417이 우편실에 없다. 도난인가, 숨겨졌나 |
| 목표·퍼즐 | M1 꼬리표 4장 앞뒤를 Letter's Trail과 대조(답 Tag D, PRESERVATION ORDER) · M2 짐꾼 쪽지 길찾기(답 Door E → archive) · M3 서랍 범위 + 찢긴 모서리 맞추기(답 Envelope 2, 봉인의 건물 그림) · Final 그림 ↔ 지도(답 Palais Garnier), 뒷면 `OPERA ARCHIVE · FILE 3–4` |
| 확정 대사(바이블 v1.4) | `Wait! It wasn't stolen.` / `Someone kept it safe.` / `We found our next clue!` / `The mystery continues at the opera house!` / 편지 `The clocks may lie. / But the show remembers.` |
| 연결 | 06→07 오페라 극장 그림 + FILE 3–4 |
| 비밀 | 작성자, 보존 지시자와 이유, 이동 담당자, Victor·Émile·Clockmaker 연관, **`THE RECORD WAS REMOVED`는 공개 금지** |

**시즌 전체에서 확인한 공개 범위**(바이블 §8): 04까지 "부품이 No. 7로 운송됨", 05까지 "4417이 16 MAY 4:00 PM Louvre에서 보류", 06까지 "도난이 아니라 Preservation Order로 보류, 다음 날 아침 archive로 이동, 편지 두 줄과 오페라 그림, FILE 3–4". Clockmaker 실명(Case 12)과 기록 삭제 반전(후반)은 세 난이도 어디에도 넣지 않았다.

## B. Mission별 콘텐츠 적용 현황

| 미션 | 퍼즐(화면) | Rookie | Junior | Master | 장면 객체 처리 |
|---|---|---|---|---|---|
| `s2_ep04_m1` | 강둑 표식 4개 | 기준본 | ✓ | ✓ | `riverMarks` 난이도별(정답 후 줄 3개) |
| `s2_ep04_m2` | 오두막·장부 | 기준본 | ✓ | ✓ | `keeperHuts` 난이도별(solvedLine·foundLine), 장부는 공통 |
| `s2_ep04_m3` | 보관함·라벨 맞추기 | 기준본 | ✓ | ✓ | `quayBoxes` 난이도별(상자 메모 3개), 라벨·조각은 공통 |
| `s2_ep04_final` | EasySteps(주소 2개) | 기준본 | ✓ | ✓ | `easySteps` 난이도별 / `streetBooks`(정답 뒤 대문 페이지)는 공통 |
| `s2_ep05_m1` | 서명 대조 | **패치 1줄**(story) | ✓ | ✓ | `markCompares` 공통(쪽지·카드·조작 안내뿐) |
| `s2_ep05_m2` | 시계 벽 | 기준본 | ✓ | ✓ | `clockWalls` 난이도별(뒷면 메모 4개) |
| `s2_ep05_m3` | EasySteps(거울 → 시계) | **패치 1줄**(증거 설명) | ✓ | ✓ | `easySteps` 난이도별 |
| `s2_ep05_final` | EasySteps(4417 찾기) | 기준본 | ✓ | ✓ | `easySteps` 난이도별 / `postTrails`(정답 뒤 경로 페이지) 공통 |
| `s2_ep06_m1` | 꼬리표 앞뒤 | 기준본 | ✓ | ✓ | `holdRacks` 공통(꼬리표 문서·조작 안내뿐) |
| `s2_ep06_m2` | 평면도 길찾기 | 기준본 | ✓ | ✓ | `planRoutes` 공통(조작 안내와 쪽지 인용뿐) |
| `s2_ep06_m3` | 서랍·모서리 맞추기 | 기준본 | ✓ | ✓ | `archives` 난이도별(오답 줄 3개·봉인 줄) |
| `s2_ep06_final` | 지도 ↔ 그림 | 기준본 | ✓ | ✓ | `letterMaps` 공통(조작 안내·지명·편지) |

**텍스트 분류**(요청 8절):
- **A. 안전하게 적용**: 사건 JSON 텍스트 전부(엔진 패치), 장면 문장(빌더가 기준 객체에서 구조 필드를 복사), EasySteps 문장(say·hints·선택지 오답 줄·tell·done — 패널·선택지·정답·힌트 수는 기준 객체 그대로), 학습 표현.
- **B. 최소 구조 확장 필요**: 장면 11종과 EasySteps의 **구조 검사만** 필요했고, 추가했다(§F). 엔진·모델·화면 코드는 바꾸지 않았다.
- **C. 정답·진행과 결합 → 모든 난이도 동일**: 퍼즐을 읽어 내는 문서(명판 뒷면, 표식 단어, 장부 줄, 라벨 줄과 조각 `TO: BOOKSTALL 12 / QUAY 1`, 거리 책자, 작업대 쪽지와 수리 카드, 영수증, 거울 글자, 우편 슬립과 경로 카드, 꼬리표, 짐꾼 쪽지, 서랍 라벨, 편지와 뒷면, 지도 지명), 선택지 라벨(EasySteps의 `CLOCK II\nruns fast` 등 포함), 증거 이름·글귀, 단서 제목·값. 이 값들은 구조 문자열에 들어 있어서 다르게 바꾸면 `problems()`와 테스트가 실패한다.
- **화면에 나오지 않는 문장(도달 불가)**: very easy로 바뀐 뒤(2026-10-27) 옛 화면의 오답 줄은 표시될 길이 없다. 단계 퍼즐은 오답을 보내지 않기 때문이다. 해당 줄은 `s2_ep04_final.feedback`(21개), `s2_ep05_final.feedback`(12개), `s2_ep05_m3` 선택지 오답 줄(3개)이다. 이 줄들은 기준본 그대로 두고 테스트 `unreachable()`에 명시했다. 각 단계에는 난이도별 오답 줄이 따로 있다.

## C. 난이도별 영어 문장 비교 (대표 문장 — 전체는 부록 A)

| 위치 | Rookie | Junior | Master |
|---|---|---|---|
| Story — `s2_ep04` intro[3] | Down by the river: old stone walls and dark, quiet water. | Down by the river, there are old stone walls and dark, quiet water. | Below, the river runs dark and quiet between old stone walls. |
| Story — `s2_ep05_m1` story[0] | Behind the workbench is an empty crate. It looks like the crate from Box 23. *(Rookie 패치)* | Behind the workbench stands an empty crate, like the one from Box 23. | An empty crate stands behind the workbench, much like the one from Box 23. |
| Story — `s2_ep06` synopsis[1] | Now it is not there. Was it stolen? Or is it hidden? | But now it is not there. Was it stolen, or is it hidden? | Now it is nowhere to be seen. Was it stolen, or hidden away? |
| Dialogue/쪽지 — `s2_ep05_m3` transition[3] | The maker's note said the letter was hidden here. | The maker's note says the letter was hidden in this clock. | According to the maker's note, the letter was hidden here. |
| Dialogue — `s2_ep06_m1` 성공 | Wait! It wasn't stolen. | = Rookie (바이블 v1.4) | = Rookie |
| Puzzle — `s2_ep04_m1` question | Which mark follows all three lines? | Which mark matches all three lines? | Which mark satisfies all three lines? |
| Puzzle — `s2_ep05_m2` question | Which clock did the maker change? | Which clock was changed by the maker? | Which clock has the maker altered? |
| Puzzle — `s2_ep06_m2` question | Which door did the letter go through? | Through which door was the letter taken? | Which door did the letter pass through? |
| Puzzle(오답) — `s2_ep04_m2` Box 17 | The heavy crate went into Box 17. Read the last line. Did it stay there? | The heavy crate did go into Box 17. Now read the last line. Is it still there? | The heavy crate began in Box 17. But read on: did it stay there? |
| Hint 1 — `s2_ep04_m1` | The plaque gives you three things to check. Read one line at a time. | Each line of the plaque is one thing to check. Take them one at a time. | The plaque sets three tests. The right mark must pass all of them. |
| Hint 2 — `s2_ep06_m2` | After the statue, count only the doors on the left: one, two. | Once you are past the statue, count the doors on the left only. | Past the statue, ignore the doors on the right. Count along the left. |
| Step(EasySteps) — `s2_ep04_final` say | Find the address. | Which address is it? | Which address fits both clues? |
| Step 오답 — `s2_ep05_final` 4471 | This is 4471. Read the numbers again: 4417. | This slip says 4471. Look again for 4417. | This one reads 4471: the right digits, in the wrong order. |
| 장면 — `s2_ep05_m2` Clock IV 뒷면 | The pendulum hook is broken. | The hook for the pendulum is broken. | The pendulum hook has snapped. |
| 장면 — `s2_ep06_m3` 잘못된 서랍 | {label}. Is 4417 between these two numbers? | {label}. Does 4417 fall between these two numbers? | {label}. Is 4417 inside this range? |

## D. 난이도 적합성

### Rookie 검토 (Q1: 기존 영어 = Rookie 기준본)
- Case 04~06 기준본은 2026-10-21~27 사이에 쓰였고 같은 날 very easy 원칙으로 다듬어졌다. 대부분 한 문장에 정보 하나이고, 문장당 평균 5.9단어다(§D 통계). 그래서 7A처럼 **문장은 유지하고 glossary를 늘렸다**. 기존 사용자 화면과 기존 Case 테스트(`paris_case04/05/06_test`)도 그대로다.
- **바꾼 두 줄**(Rookie 패치, 기준 JSON 불변):
  1. `s2_ep05_m1.story[0]`: "An empty crate stands behind the workbench, just like in Box 23."의 `just like in Box 23`는 "Box 23 안처럼?"으로 읽혀 모호하다. 그래서 "Behind the workbench is an empty crate. It looks like the crate from Box 23."으로 바꿨다. "같은 상자다"라고 단정하지 않는다.
  2. `s2_ep05_m3.evidence.description`: "Read in the hand mirror. What it named was inside Clock III."의 `What it named was inside`는 관계절 주어라 어렵다. 그래서 "You read it in the hand mirror. It named Clock III."로 바꿨다.
- glossary 추가: Case 04 stone·wooden·shelf·somewhere·burning·caught·lists, Case 05 workshop·shape·colour·arrived·bench·backward·nobody·covered, Case 06 building·hundreds·domes·secret·continues·church·slowly·between. 각 단어가 그 난이도 화면에 실제로 있는지 테스트가 확인한다.

### Junior / Master
- **Junior**: 기준본의 사실 순서를 유지한다. 접속사(and, but, so, then)와 완전한 문장으로 쓰고, 단서끼리의 관계를 말한다(예: 힌트 "Both streets start with PASSAGE, so CLUE 1 fits both. Now check CLUE 2."). 어휘는 matches·mention·reminds·belongs·stored 정도다.
- **Master**: 묘사와 간접 표현을 쓴다(weathered, descend, gleaming, hushed, decipher, altered, satisfies, destination, range). 힌트는 관계를 암시한다("Two numbers use the same digits. Only one has them in the right order."). 그래도 문장은 대부분 14단어 이하이고, 성인 소설체 문장(삽입절 여러 개)은 쓰지 않았다.
- **조작 안내는 세 난이도가 같다**(요청 4절 "Master도 조작 안내 명확"): Tap…, Turn…, Drag…, LAY THE CORNER ON IT, `Tap the mirror.`, `Tap the hand mirror.`(힌트 마지막). EasySteps의 마지막 무료 힌트는 정답 위치를 비추는 구조이며 그대로다.
- **정보량이 같은지**: 같은 위치의 문장은 같은 사실만 말한다. Master가 보탠 묘사(enamel sign, lies stained with ink, pressed into the wax)는 그림에 이미 보이는 것뿐이다. Master 힌트 "Three things came from the Eiffel Tower"는 장부 첫 쪽에 이미 보이는 사실(Box 9·17·6)이다. 숨겨진 정보를 꺼낸 문장은 없다.
- **PART 7A와 문체 비교**(실제 데이터에서 자동 계산, 부록 B 방법): §D-통계 표 참조.

#### §D 통계 — PART 7A(Case 01~03)와 비교 (intro·synopsis·story·question·hints·success·transition, 실제 적용 데이터)

| 범위 | 난이도 | 문장 수 | 문장당 단어 | 8글자 이상 단어 비율 |
|---|---|---|---|---|
| Case 01~03 (7A) | Rookie | 216 | 6.0 | 3.6% |
| Case 01~03 (7A) | Junior | 217 | 6.9 | 3.2% |
| Case 01~03 (7A) | Master | 206 | 7.5 | 5.2% |
| **Case 04~06 (7B)** | Rookie | 198 | 5.9 | 3.2% |
| **Case 04~06 (7B)** | Junior | 182 | 7.4 | 3.1% |
| **Case 04~06 (7B)** | Master | 175 | 7.6 | 3.5% |

- 문장 길이는 7A와 같은 계단(Rookie < Junior < Master)이고 폭도 비슷하다. 7B Junior는 7A보다 문장당 0.5단어 길다(접속사로 두 문장을 이은 곳이 많다). 7B Master의 긴 단어 비율은 7A보다 낮다. 그래서 Master가 과하게 어려워지지 않았다고 본다.
- 인물 말투: 7A와 같은 2인칭 서술("You …"), 짧은 감탄 성공 줄, 질문으로 끝나는 사건 끝을 유지했다.

### 의도적으로 모든 난이도에서 같은 줄 (fallback이 아니라 검토 후 유지 — 테스트 `keptAtEveryLevel`)
- 명판 뒷면 세 줄(`s2_ep04_m1.letter`). 라벨을 다시 읽는 세 줄(`s2_ep04_m3.transition[0..2]`). 주소와 라벨 뒷면(`s2_ep04_final.transition[0,2,3]`, Case 05 intro[0]이 이 두 줄로 시작).
- 작업대 쪽지와 수리 카드(`s2_ep05_m1.letter`, `transition[2,3]`, `s2_ep05_m2.letter`), 영수증 줄(`s2_ep05_m3.transition[2]`), Case 05 끝 질문(hook).
- Letter's Trail(`s2_ep06_m1.letter`), 짐꾼 쪽지(`s2_ep06_m2.letter`), 편지(`s2_ep06_final.letter`), 바이블 v1.4 확정 대사(`s2_ep06_m1.successMessage`·`transition[1]`, `s2_ep06_final.successMessage`·`transition[1,2]`), Case 06 끝 질문(hook).
- 장면 6종 전체(`season2SameAtEveryLevel`): `streetBooks/s2_ep04_final`, `markCompares/s2_ep05_m1`, `postTrails/s2_ep05_final`, `holdRacks/s2_ep06_m1`, `planRoutes/s2_ep06_m2`, `letterMaps/s2_ep06_final`. 이 장면에는 조작 안내·문서·스크린리더 그림 설명만 있다.
- 결과: `s2_ep06_m1`의 Discovery 제목은 세 난이도에서 같다(`Wait! It wasn't stolen.`).

## E. 스토리 보호

세 난이도 모두에 대해 테스트(`What each case keeps untold`)가 확인하는 항목이다.

| 위험 | 처리 | 테스트 |
|---|---|---|
| Clockmaker 정체·실명 | Case 04~06 어디에도 `Clockmaker`·Émile·Victor 없음 | 금지어 검사 |
| 두 바늘 서명의 주인 | Case 04에는 `maker` 단어도 없음(Case 05에서 처음 "the maker"), 끝은 질문(`whose hands…?`) | `\bmaker\b` 금지, 마지막 줄 `?` |
| 부품의 용도 | `repair` 등 용도 언급 없음(Case 04) | 금지어 |
| `ES HORLOGERS` 조기 노출 | M1~M3 문장·장면·힌트, Final 정답 전 문장에 `HORLOGERS` 없음(Final 선택지 라벨만) | 검사 |
| 편지가 Clock III에 실제로 있었는지 | "메모가 그렇게 말한다" 한 줄 + "Did someone take it out?" 질문 한 줄. Junior·Master 성공 줄은 기준본보다 덜 단정적으로 썼다("the clock the note named", "the hiding place the note described") | 줄 수 검사, `TOOK IT`/`TAKEN OUT`/`STOLE` 금지 |
| Case 06 정보의 Case 05 조기 노출 | Case 05에 PRESERVATION·KEEP IT SAFE·OPERA·GARNIER·ARCHIVE·편지 두 줄 없음 | 금지어 |
| 오페라 극장 조기 노출 | Case 06 M1~M3와 Final 정답 전 문장(오답 줄 포함)에 OPERA·GARNIER 없음 | 검사 |
| 후반 반전 | `RECORD WAS REMOVED`·`REMOVED`·`THIEF` 없음, 작성자 미상(`maker` 없음), 보존 지시자 무명("Someone kept it safe.") | 금지어 |
| 도난/보류/이동 구분 | M1 성공 줄 = 바이블 문장, M2 story에 HELD → MOVED 두 줄 순서 그대로, caseSummary에 `kept safe` | 검사 |
| 정답 조기 노출 | 힌트에 `Mark D`·`Box 23`·`Clock III`(III)·`Tag D`·`Door E`·`Envelope 2`·정답 라벨 없음. EasySteps 힌트(마지막 제외)·오답 줄에 정답 라벨 없음 | 검사 |
| 인물 관계 | River Keeper는 기록자로만 나온다. 공범이라는 암시는 없다. 우편 담당자에게 악의를 부여하지 않았다 | 원문 검토(부록 A) |

## F. 구조 검사 (`lib/data/mock/season2/season2_structures.dart`)

7A의 `season2StructureOf` 방식(전체 정밀도 좌표 문자열)에 다음 12종을 더했다. 엔진(`DifficultyContent.structureOf`)은 수정하지 않았다. 이미 `season2StructureOf`를 먼저 조회하고 있기 때문이다.

| 객체 | 보호하는 것 |
|---|---|
| `RiverMarksScene` | 그림·좌표, 표식 id/이름/단어/물결 수/화살표 방향, 표지판 QUAY 3, 명판 앞면(EvidenceBoard 구조)·뒷면 문장, 정답 후 줄 **개수** |
| `KeeperHutScene` | 문·장부 영역, 장부 두 쪽의 제목·날짜·상자 id·문장·서명(J.M./두 바늘), 찾을 상자 `box23` |
| `BoxesScene` | 상자 id/번호/영역/메모 유무(열리는 Box 23은 메모 없음), 다른 종이 조각 문장, 배송표 전체(줄·찢긴 선·주소 `PASSAGE D`+`ES HORLOGERS`·뒷면), 칸 순서 |
| `StreetBookScene` | 거리 4개 id/이름/설명/쪽, 증거 id, 최대 2개, 대문 간판·조각 위치·라벨 |
| `MarkCompareScene` | 도장 4개 id/이름/물건/영역/사본 종류, 서명 그림·분할선, 대조지, 쪽지, 수리 카드 |
| `ClockWallScene` | 시계 id/숫자/위치/표시 시각/1분 변화(+1, +5, −1, 0)/뒷면 그림, 관찰 시간 |
| `PostTrailScene` | 슬립 5장 전체(번호·날짜·시각·기록·장소), 칸·칸 이름, 영수증 |
| `HoldRackScene` | 기준 단서, 꼬리표 4장(종류·번호·날짜·시각·기록·사유), 꼬리표 위치, Letter's Trail 종이 |
| `PlanScene` | 문 6개(쪽·조각상 전후·순번), 지시(조각상 지나 왼쪽 두 번째), 답 `e`, 단계 위치 |
| `ArchiveScene` | 서랍 4개(종류·범위), 편지 번호, 봉투 3개 찢김 모양, 모서리, 봉인, `{label}` 자리표시 유지 |
| `LetterMapScene` | 그림 특징, 건물별 특징·공연장 여부, 뒷면, 편지 종이, 지명·위치 |
| `EasyStepsScene` | 제목, 정답(미션 답과 같음), `seen`, 단계별 id·동작·대상·선택지 id/라벨/그림 패널·정답·**힌트 수**·정답 위치 강조(`lookHere`)·tell/done 유무, 패널(그림·쓰인 글자·종이 제목과 줄·증거 id·그린 문서) |

- 문서처럼 "읽어서 푸는" 문자열은 구조에 포함했다. 그래서 어느 난이도도 문서를 바꿀 수 없다.
- 조작 안내 문자열(task·버튼 라벨)은 구조 밖에 두었다. 대신 테스트가 세 난이도에서 같은지 확인한다.
- 난이도별 변형은 빌더(`_wall`·`_hut`·`_boxes`·`_clocks`·`_archive`·`_steps`)로 만든다. 빌더는 기준 객체의 구조 필드를 그대로 복사하고 문장만 받는다. EasySteps는 패널·선택지 패널·`after` 목록을 **같은 객체**로 공유한다(테스트가 `identical`로 확인).
- 결과: `problems()` 빈 목록. 두 난이도 × 14개 표 항목의 구조 문자열이 기준과 같다(테스트).

## G. 학습 표현 (부모 보고서)

모든 미션에서 세 난이도가 서로 다른 표현 묶음을 쓴다. 각 표현은 **그 난이도 화면 문장**(story·letter·question·hints·선택지)에 단어 단위로 있다(`LearningCheck`, 테스트 통과). 의존도·수준·기술·목표(한국어 설명)는 기준과 같다. 표현이 문서 인용(명판, 카드, 짐꾼 쪽지, 편지)이면 세 난이도가 함께 쓰고, 여기에 그 난이도의 질문이나 힌트 표현을 더했다.

| 미션 | Rookie | Junior | Master |
|---|---|---|---|
| 04 M1 | Three waves mark the place. / Follow the arrow towards the river. / Find the one who watches the water. | (명판 2줄) + Which mark matches all three lines? | (명판 2줄) + Which mark satisfies all three lines? |
| 04 M2 | The crate from the tower went to the river. / Where is the crate now? | was sent to the river / Which box holds the tower's crate now? | Where has the crate ended up? / Trace that crate through the later lines of the page |
| 04 M3 | Put the torn label back together. / Read where it was sent. | Fit the pieces of the torn label together / Read where the box was sent | Piece the torn label back together / discover where it was being sent |
| 04 Final | Find the address. / CLUE 2: No. 7 | Which address fits both clues? / CLUE 2: No. 7 | Only one address fits both / CLUE 2: No. 7 |
| 05 M1 | My mark is on everything I make. / A copy is never the same. | A copy is never the same. / Which thing has the maker's real mark? | A copy is never the same. / Which object carries the maker's true mark? |
| 05 M2 | I added one small wheel. / Now its hands turn the wrong way. | (카드 2줄) + Which clock was changed by the maker? | (카드 2줄) + Which clock has the maker altered? |
| 05 M3 | the clock that turns back / Which clock? | the clock that turns back / Use the mirror to read it | Let the mirror turn it round / Which clock does the note point to? |
| 05 Final | Find letter 4417. | Which slip is for letter 4417? | Pick out the slip for letter 4417 |
| 06 M1 | LETTER No. 4417 / Which tag is for Letter 4417? | LETTER No. 4417 / Which tag belongs to Letter 4417? | LETTER No. 4417 / Where ink hides a digit, the back must decide |
| 06 M2 | Walk past the statue. / Take the second door on the left. | (쪽지 2줄) + count the doors on the left only | (쪽지 2줄) + Count along the left |
| 06 M3 | Find the envelope it was torn from. | Which envelope was it torn from? | Find the envelope this corner was torn from |
| 06 Final | But the show remembers. | But the show remembers. / Which building is a place for shows? | But the show remembers. / Where would a show be remembered? |

- 완료 시즌의 보고서는 **시즌에 고정된 난이도**를 따른다. 프로필 난이도를 다른 값으로 바꿔도 Case 05 보고서 표현은 시즌 난이도 그대로다(테스트: 세 난이도 × 프로필은 다른 난이도).

## H. 힌트 · Discovery

- **힌트**: 개수 2개, Tip 1 무료 / Tip 2 20코인, 구매 기록(`hintsUsed`, 미션 id 기준)은 그대로다. 테스트는 Master·Junior·Rookie에서 Box 23 미션의 열린 힌트 1개가 유지되고 그 난이도의 첫 힌트가 보이는지 확인한다. 직접성은 난이도마다 다르다. Rookie는 무엇을 볼지 말한다. Junior는 단서를 잇는 순서를 말한다. Master는 단서 사이의 관계를 암시한다(§C). 세 난이도의 힌트 묶음은 미션마다 모두 다르다.
- **EasySteps 무료 힌트**: 단계 힌트 수는 같고, 마지막 힌트 다음에 정답이 강조되는 구조도 그대로다. 미션 JSON 힌트와 단계 첫 힌트는 난이도마다 일치한다(테스트).
- **Discovery 제목** = 플레이한 난이도의 successMessage다(PART 5 방식). 9개 미션 중 8개는 세 난이도 제목이 서로 다르다. `s2_ep06_m1`만 바이블 문장이라 같다. 제목에 후반 비밀은 없다(Case 05 M3의 Junior·Master 제목은 기준본보다 덜 단정적이다).

## I. 검증

- 신규 `test/difficulty_paris_7b_test.dart` **30개 통과**:
  - 작성 완료와 누락 없음(01~06 written, 07 미작성 확인), Junior·Master 고유 문장, Rookie(패치 2줄 외 기준본, glossary), glossary 단어 실재
  - 구조·정답·선택지·오답 판정·코인·힌트 가격, 장면 14개 구조와 조작 안내, EasySteps 불변
  - 사건별 비밀 × 3난이도
  - 힌트 정답 비노출, 힌트 구매 기록 × 3난이도
  - Discovery, 학습 표현과 보고서 × 3난이도(프로필 변경 후에도 시즌 난이도), 옛 저장
  - 화면 5개: Case 04 Final의 세 난이도 390×844 / Master 360×640 + 글자 1.3배 / Master 834×1194 태블릿. 단계 문장·무료 힌트·오답 줄·정답 줄이 그 난이도로 보이는지, 다른 난이도 문장이 없는지, 선택지 44pt 이상인지, overflow·예외가 없는지 확인
- 기존 테스트 수정 1곳(의도적): `test/difficulty_paris_7a_test.dart`의 "작성 완료 사건 = 정확히 01~03" 단언을 "01~06"으로 바꿨다. 7B가 04~06을 등록했으므로 바뀐 사실을 반영한 것이다. 같은 단언을 7B 테스트도 가진다. 삭제·skip은 없다.
- 관련 회귀(실행): `difficulty_content`·`difficulty_paris_7a`·`difficulty_london_6a`·`learning_objectives`·`paris_case04/05/06`·`discovery_moment` 202개 통과.
- `flutter analyze`: No issues.
- 전체 `flutter test`: **2446 passed, 0 failed, 0 skipped**(5분 9초) = 기존 2416 + 신규 30.

## J. 남은 위험 (자동 테스트로 확인하지 못한 것)

- **원어민·교사 검토 없음.** 난이도 적합성은 작성자 판단과 통계(§D)뿐이다.
- **실기기 확인 없음.** 화면은 위젯 테스트(Case 04 Final, 세 크기)로만 봤다. 장면 위젯(강둑·오두막·보관함·시계 벽·서랍)의 새 문장이 작은 화면에서 어떻게 줄바꿈되는지는 Case 04 Final 말고는 확인하지 않았다. 문장 길이는 평균으로 Junior가 문장당 +1.5단어, Master가 +1.7단어다(§D 통계).
- **도달 불가 문장 36줄**(§B)은 기준본 그대로 남았다. very easy 이전 화면 코드(StreetBookPuzzle·PostTrailPuzzle 미해결 경로 등)는 그대로이고, 다시 쓰이면 Junior·Master에서 이 줄이 기준본 문체로 나온다. 정리(삭제 또는 작성) 여부는 사용자 결정이다.
- Case 05 M1 Rookie 패치는 기준본보다 "상자가 같은 상자인지"를 더 모호하게 둔다(의도). 기존 사용자에게는 이 한 줄이 바뀌어 보인다.
- 스크린리더용 그림 설명(`place`·`label`)은 세 난이도가 같다(7A와 같은 원칙).
- PART 7A 문장에서 이번에 고칠 것은 찾지 못했다. 7A 문장은 수정하지 않았다.

## K. PART 7C 인수인계 (Case 07~09)

- 같은 방식: 새 파일 `lib/data/mock/season2/season2_levels_07_09.dart`(사건 패치·장면 빌더·학습 표현)를 만들고, `season2_difficulty.dart`에서 패치·`season2WrittenLevels`·`season2SameAtEveryLevel`·`season2Variants`(표·learning)에 연결한다.
- 먼저 `season2StructureOf`에 구조 추출을 추가해야 하는 장면: Case 07 `flyRails`·`lightTables`(+ EasySteps M1·M2·Final — EasySteps 구조 검사는 이번에 추가됨), Case 08 `cornerChoices`·`morningSketches`·`tornSlips`·`tornHours`, Case 09 `trialMaps`·`gearBoards`·`makerMarks`·`towerTests`. `DrawnPanel`이 쓰는 `AmendmentSlip`·`CueCard`·`MorningSketch`·`TornForm`·`TrialMapPaper` 등은 `_drawn`이 아직 객체 동일성으로만 비교한다. 그러니 변형에서 같은 객체를 공유하거나 `_drawn`에 추가해야 한다.
- 이번에 남긴 7B 테스트의 `keptAtEveryLevel`·`unreachable()` 방식을 그대로 쓴다. Case 07 Final(very easy)도 옛 오답 맵이 도달 불가인지 먼저 확인한다.
- 바이블 고정: Case 07 확정 명세 v1.5(수정 슬립, 이름·이니셜 없음, CURTAIN UP 4:00→3:00, ABBESSES, `P. KNEW THE BAG.`), Case 08 v1.6, Case 09 v1.7. Case 06 끝 질문 `What is in File 3–4 of the opera archive?`는 Case 07 시작과 이어진다.

---

## 부록 A. 전체 문장 표 (실제 적용 콘텐츠에서 자동 추출)

- 표기: `= Rookie`는 Rookie와 같은 문장, `= Junior`는 Junior와 같은 문장이다. `/`는 줄바꿈 또는 목록 구분이다.
- `scene …` 행은 장면 객체의 문장, `steps …` 행은 EasySteps 문장, `learning …` 행은 부모 보고서 학습 표현이다.
- 모든 난이도에서 같은 장면 6종과 도달 불가 오답 줄(§B)은 표에 싣지 않았다.

### s2_ep04 — The River's Secret

| 위치 | Rookie | Junior | Master |
|---|---|---|---|
| `intro` | Three small waves. One word: SEINE. / You hold the brass plaque up to a street lamp. / On its back, someone has scratched three short lines. / Down by the river: old stone walls and dark, quiet water. / Somewhere on these quays, a mark is waiting for you. | Three small waves, and one word: SEINE. / You lift the brass plaque up to the light of a street lamp. / On the back, someone has scratched three short lines. / Down by the river, there are old stone walls and dark, quiet water. / Somewhere along these quays, a mark is waiting to be found. | Three small waves above a single word: SEINE. / You tilt the brass plaque towards the glow of a street lamp. / Scratched into its back are three short lines. / Below, the river runs dark and quiet between old stone walls. / Somewhere along these quays, a mark is waiting for you to find it. |
| `synopsis` | The brass plaque had three small waves and one word: SEINE. / Three lines on its back lead you to the river. / The crate from the tower went there too. Where is it now? | The brass plaque showed three small waves and one word: SEINE. / Three lines scratched on its back lead you down to the river. / The crate from the tower went there too. Where is it now? | The brass plaque bore three small waves and a single word: SEINE. / Three lines scratched on its back point you towards the river. / The crate from the tower travelled there too. Where is it now? |
| `objectives` | Find the right mark on the quay wall. / Read the river keeper's ledger. / Put the torn label back together. | Find the mark on the quay wall that fits all three lines. / Read the river keeper's ledger carefully. / Put the torn delivery label back together. | Find the one mark on the quay wall that satisfies all three lines. / Follow the boxes through the river keeper's ledger. / Piece the torn delivery label back together. |
| `caseSummary` | Three waves, a ledger and a torn label led you to one address. | Three waves, the keeper's ledger and a torn label led you to a single address. | A carved mark, a keeper's ledger and a torn label pointed you to one address. |
| `hook` | Do not trust the clocks. Whose hands made them? | Do not trust the clocks. So whose hands made them? | "Do not trust the clocks." But whose hands made them? |
| `s2_ep04_m1.story` | Four marks are carved into the old quay wall. / Each one has waves, an arrow and a word. | Four marks are carved into the old stone wall by the river. / Each mark has some waves, an arrow and a word. | Four marks have been carved into the weathered quay wall. / Each one bears waves, an arrow and a single word. |
| `s2_ep04_m1.letterIntro` | The back of the brass plaque says: | On the back of the brass plaque, you read: | Scratched into the back of the brass plaque: |
| `s2_ep04_m1.letter` | Three waves mark the place. / Follow the arrow towards the river. / Find the one who watches the water. | = Rookie | = Rookie |
| `s2_ep04_m1.question` | Which mark follows all three lines? | Which mark matches all three lines? | Which mark satisfies all three lines? |
| `s2_ep04_m1.hints[0]` | The plaque gives you three things to check. Read one line at a time. | Each line of the plaque is one thing to check. Take them one at a time. | The plaque sets three tests. The right mark must pass all of them. |
| `s2_ep04_m1.hints[1]` | For each mark: How many waves? Where does the arrow point? Who does it name? | Check every mark: count the waves, follow the arrow and read the word. | Waves, arrow, word: a mark that fails even one test is not the one. |
| `s2_ep04_m1.successMessage` | You found the River Keeper's mark! | That's the River Keeper's mark! | The River Keeper's mark, at last! |
| `s2_ep04_m1.transition[0]` | Beside the mark, the keeper's steps go down to the water. | Next to the mark, the keeper's steps lead down to the water. | Beside the mark, the keeper's steps descend to the water's edge. |
| `s2_ep04_m1.transition[1]` | A small sign on the wall says QUAY 3. | A small sign on the wall reads QUAY 3. | A small enamel sign on the wall reads QUAY 3. |
| `s2_ep04_m1.transition[2]` | At the bottom of the steps stands a little wooden hut. | At the bottom of the steps, there is a little wooden hut. | At the foot of the steps waits a little wooden hut. |
| `s2_ep04_m1.options[a].feedback` | Look at line 2 again. Where does the arrow on Mark A point? | Read line 2 again. Which way does the arrow on Mark A point? | Line 2 tells you where the arrow should point. Does Mark A agree? |
| `s2_ep04_m1.options[b].feedback` | Look at line 3 again. Read the word. Do booksellers watch the water? | Read line 3 again, then the word on Mark B. Do booksellers watch the water? | Line 3 asks for the one who watches the water. Is that a bookseller's job? |
| `s2_ep04_m1.options[c].feedback` | Look at line 1 again. Count the waves on Mark C. | Read line 1 again. How many waves does Mark C have? | Line 1 names a number of waves. Count Mark C's carefully. |
| `s2_ep04_m1.clue.note` | Beside the mark, the keeper's steps go down to the water. QUAY 3. | Next to the mark, the keeper's steps lead down to the water. QUAY 3. | The keeper's steps descend beside the mark, down to the water. QUAY 3. |
| `s2_ep04_m1.evidence.description` | Carved into the quay wall, beside stone steps to the water. | Carved into the quay wall, next to stone steps that lead to the water. | Carved into the quay wall, beside stone steps that descend to the river. |
| `s2_ep04_m2.story` | The keeper's hut is open. A lamp is burning inside. / The river keeper writes down every box that comes and goes. | The door of the keeper's hut is open. A lamp is burning inside. / The river keeper writes down every box that arrives and leaves. | The keeper's hut stands open, a lamp glowing inside. / Every box that comes and goes along the river is written down here. |
| `s2_ep04_m2.letterIntro` | Your notebook says: | Your notebook reminds you: | Your notebook holds what you know so far: |
| `s2_ep04_m2.letter` | The crate from the tower went to the river. / The River Mark says QUAY 3. /  / Find the keeper's ledger. / Where is the crate now? | The crate from the tower was sent to the river. / The River Mark says QUAY 3. /  / Read the keeper's ledger. / Which box holds the tower's crate now? | The crate from the tower was sent down to the river. / The River Mark points to QUAY 3. /  / The keeper's ledger should tell you more. / Where has the crate ended up? |
| `s2_ep04_m2.question` | Which box is the tower's crate in now? | Which box holds the tower's crate now? | In which box does the tower's crate sit now? |
| `s2_ep04_m2.hints[0]` | Find the things from the Eiffel Tower. Which one is on Quay 3? | Look for the lines that say "from the Eiffel Tower". Only one of them is on Quay 3. | Three things came from the Eiffel Tower, but your River Mark leaves only one quay. |
| `s2_ep04_m2.hints[1]` | Find that box again lower down the page. What happened on 14 May? | Follow that box down the page. What happened to it on 14 May? | A box can change. Trace that crate through the later lines of the page. |
| `s2_ep04_m2.successMessage` | You found the box! | You found the right box! | The crate is tracked down! |
| `s2_ep04_m2.transition[0]` | Box 17 was moved to Box 23. | On 14 May, Box 17 was moved to Box 23. | On 14 May, the crate was moved from Box 17 to Box 23. |
| `s2_ep04_m2.transition[1]` | Then Box 23 was collected for No. 7. | Then, on 15 May, Box 23 was collected for No. 7. | A day later, Box 23 was collected for No. 7. |
| `s2_ep04_m2.transition[2]` | Each line is signed with the same mark: two clock hands. | Every one of these lines is signed with the same mark: two clock hands. | Each of these entries bears the same signature: two clock hands. |
| `s2_ep04_m2.transition[3]` | Outside, green boxes stand in a row along the quay. | Outside, a row of green boxes stands along the quay. | Outside, a row of green boxes lines the quay. |
| `s2_ep04_m2.options[box4].feedback` | Box 4 holds old books. They are not from the Eiffel Tower. | Box 4 is full of old books from the bookstalls, not things from the Eiffel Tower. | Box 4 holds old books from the bookstalls. Nothing from the Eiffel Tower there. |
| `s2_ep04_m2.options[box9].feedback` | Box 9 is on Quay 1. Your River Mark says QUAY 3. | Box 9 came from the tower, but it is on Quay 1. The River Mark says QUAY 3. | Box 9 did come from the tower, but it sits on Quay 1, not QUAY 3. |
| `s2_ep04_m2.options[box12].feedback` | Box 12 is lamp oil from Pont Neuf, not from the Eiffel Tower. | Box 12 holds lamp oil from Pont Neuf. It did not come from the Eiffel Tower. | Box 12 is lamp oil, sent from Pont Neuf rather than the Eiffel Tower. |
| `s2_ep04_m2.options[box17].feedback` | The heavy crate went into Box 17. Read the last line. Did it stay there? | The heavy crate did go into Box 17. Now read the last line. Is it still there? | The heavy crate began in Box 17. But read on: did it stay there? |
| `s2_ep04_m2.options[box6].feedback` | Box 6 is on Quay 2. Your River Mark says QUAY 3. | Box 6 came from the tower, but it is on Quay 2. The River Mark says QUAY 3. | Box 6 did come from the tower, but it sits on Quay 2, not QUAY 3. |
| `s2_ep04_m2.clue.note` | Box 23 was collected for No. 7. Delivery: through the keeper's steps. | Box 23 was collected for No. 7. It was to be delivered through the keeper's steps. | Box 23 was collected for No. 7, to be delivered by way of the keeper's steps. |
| `s2_ep04_m2.evidence.description` | Open on the desk in the river keeper's hut. | It lies open on the desk in the river keeper's hut. | Left open on the desk inside the river keeper's hut. |
| `s2_ep04_m3.story` | Four green boxes stand on the river wall. / One of them holds what came from the tower. | Four green boxes stand in a row on the river wall. / One of them holds the things that came from the tower. | Four green boxes are lined up along the river wall. / Somewhere among them is what came down from the tower. |
| `s2_ep04_m3.letterIntro` | Your notebook says: | In your notebook, you wrote: | Your notebook spells out the next step: |
| `s2_ep04_m3.letter` | Open BOX 23. / Put the torn label back together. / Read where it was sent. | Open BOX 23. / Fit the pieces of the torn label together. / Read where the box was sent. | Open BOX 23. / Piece the torn label back together. / Then discover where it was being sent. |
| `s2_ep04_m3.question` | Put the torn label back together. | Fit the torn label back together. | Piece the torn label back together. |
| `s2_ep04_m3.hints[0]` | One scrap is a different paper: thin and blue-grey. Leave it out. | One scrap does not belong to this label. It is thin and blue-grey, so leave it out. | Not every scrap in the box is part of the label. Compare the paper and the ink. |
| `s2_ep04_m3.hints[1]` | Top to bottom: FROM, CONTENTS, TO. The eyelet piece goes at the top. | A label reads FROM, then CONTENTS, then TO. Start with the piece that has the eyelet. | Think of how any label is written, from top to bottom, and where it is tied on. |
| `s2_ep04_m3.successMessage` | The label fits together! | The label is back in one piece! | The torn label is whole again! |
| `s2_ep04_m3.transition[0]` | FROM: EIFFEL TOWER — SERVICE LEVEL. | = Rookie | = Rookie |
| `s2_ep04_m3.transition[1]` | CONTENTS: CLOCK PARTS. | = Rookie | = Rookie |
| `s2_ep04_m3.transition[2]` | TO: THE WATCHMAKERS. PASSAGE D… | = Rookie | = Rookie |
| `s2_ep04_m3.transition[3]` | Back in the keeper's hut, an old street book sits on a shelf. | Back in the keeper's hut, there is an old street book on a shelf. | Back in the keeper's hut, an old street book waits on a shelf. |
| `s2_ep04_m3.feedback[decoy:top]` | That scrap is a different paper: thin and blue-grey, with blue ink. | That scrap is not from this label. It is thin and blue-grey, and its ink is blue. | That scrap belongs to another paper altogether: thin, blue-grey, written in blue ink. |
| `s2_ep04_m3.feedback[decoy:middle]` | That scrap is a different paper: thin and blue-grey, with blue ink. | That scrap is not from this label. It is thin and blue-grey, and its ink is blue. | That scrap belongs to another paper altogether: thin, blue-grey, written in blue ink. |
| `s2_ep04_m3.feedback[decoy:bottom]` | That scrap is a different paper: thin and blue-grey, with blue ink. | That scrap is not from this label. It is thin and blue-grey, and its ink is blue. | That scrap belongs to another paper altogether: thin, blue-grey, written in blue ink. |
| `s2_ep04_m3.feedback[p1:middle]` | A label is tied by its brass eyelet. That piece goes at the top. | A label hangs from its brass eyelet, so that piece belongs at the top. | A label is tied on by its brass eyelet. That piece must go at the top. |
| `s2_ep04_m3.feedback[p1:bottom]` | A label is tied by its brass eyelet. That piece goes at the top. | A label hangs from its brass eyelet, so that piece belongs at the top. | A label is tied on by its brass eyelet. That piece must go at the top. |
| `s2_ep04_m3.feedback[p2:top]` | A label says FROM first. CONTENTS comes next. | A label starts with FROM. CONTENTS comes after it. | FROM always opens a label. CONTENTS follows it. |
| `s2_ep04_m3.feedback[p2:bottom]` | CONTENTS comes before TO. Do the torn edges meet? | CONTENTS comes before TO. Check that the torn edges meet. | CONTENTS belongs above TO. Do the torn edges line up? |
| `s2_ep04_m3.feedback[p3:top]` | Where a parcel goes comes last. Find the line with TO. | Where a parcel is going is written last. Find the line with TO. | A parcel's destination is written last. Look for TO. |
| `s2_ep04_m3.feedback[p3:middle]` | Where a parcel goes comes last. Find the line with TO. | Where a parcel is going is written last. Find the line with TO. | A parcel's destination is written last. Look for TO. |
| `s2_ep04_m3.clue.note` | TO: THE WATCHMAKERS. The number is washed away. Then PASSAGE D… | TO: THE WATCHMAKERS. The house number has been washed away. Then PASSAGE D… | TO: THE WATCHMAKERS. The house number is lost to the water. Then PASSAGE D… |
| `s2_ep04_m3.evidence.description` | Found in Box 23 on the quay. | It was found inside Box 23 on the quay. | Found tucked inside Box 23, down on the quay. |
| `s2_ep04_final.story` | The keeper's street book lists the watchmakers' streets. / Only one can be the address on the label. | The keeper's street book has a list of the watchmakers' streets. / Only one of them can be the address on the label. | The keeper's street book records every street of watchmakers. / Only one of them can match the address on the label. |
| `s2_ep04_final.letterIntro` | Your notebook says: | Your notebook has two clues: | Two clues are written in your notebook: |
| `s2_ep04_final.letter` | CLUE 1: PASSAGE / CLUE 2: No. 7 /  / Find the address. | CLUE 1: PASSAGE / CLUE 2: No. 7 /  / Which address fits both clues? | CLUE 1: PASSAGE / CLUE 2: No. 7 /  / Only one address fits both. |
| `s2_ep04_final.question` | Find the address. | Which address is it? | Which address fits both clues? |
| `s2_ep04_final.hints[0]` | Both streets are a PASSAGE. Now read CLUE 2. | Both streets start with PASSAGE, so CLUE 1 fits both. Now check CLUE 2. | CLUE 1 cannot decide between them. Let CLUE 2 settle it. |
| `s2_ep04_final.hints[1]` | CLUE 2 is No. 7. Which address has No. 7? | CLUE 2 says No. 7. Find the address with that number. | Compare each house number with CLUE 2. |
| `s2_ep04_final.successMessage` | You found the address! | You found the right address! | You tracked down the address! |
| `s2_ep04_final.transition[0]` | PASSAGE DES HORLOGERS. | = Rookie | = Rookie |
| `s2_ep04_final.transition[1]` | Behind the iron gate, the workshops are dark and quiet. | Behind the iron gate, the workshops are dark and silent. | Beyond the iron gate, the workshops lie dark and still. |
| `s2_ep04_final.transition[2]` | Do not trust the clocks. | = Rookie | = Rookie |
| `s2_ep04_final.transition[3]` | Follow the hands that made them. | = Rookie | = Rookie |
| `s2_ep04_final.transition[4]` | But whose hands are they? | But whose hands made them? | Yet whose hands could they be? |
| `s2_ep04_final.evidence.description` | The last piece of the label, caught in the gate of PASSAGE DES HORLOGERS. | The last piece of the label, stuck in the gate of PASSAGE DES HORLOGERS. | The label's missing piece, snagged on the gate of PASSAGE DES HORLOGERS. |
| `s2_ep04_m1 scene riverMarks.rightLines[0]` | Three waves. | Three waves, just as line 1 says. | Three waves, exactly as line 1 asks. |
| `s2_ep04_m1 scene riverMarks.rightLines[1]` | Its arrow points down, towards the river. | The arrow points down, towards the river. | An arrow pointing down, towards the river. |
| `s2_ep04_m1 scene riverMarks.rightLines[2]` | RIVER KEEPER: he watches the water. | RIVER KEEPER: the one who watches the water. | RIVER KEEPER: the one who keeps watch over the water. |
| `learning s2_ep04_m1` | "Three waves mark the place.", "Follow the arrow towards the river.", "Find the one who watches the water." | "Follow the arrow towards the river.", "Find the one who watches the water.", "Which mark matches all three lines?" | "Follow the arrow towards the river.", "Find the one who watches the water.", "Which mark satisfies all three lines?" |
| `s2_ep04_m2 scene keeperHut.solvedLine` | The crate is in Box 23 now. | Box 23 holds the crate now. | The crate now rests in Box 23. |
| `s2_ep04_m2 scene keeperHut.foundLine` | Box 23 was collected for No. 7. | Look: Box 23 was collected for No. 7. | There it is: Box 23, collected for No. 7. |
| `learning s2_ep04_m2` | "The crate from the tower went to the river.", "Where is the crate now?" | "was sent to the river", "Which box holds the tower's crate now?" | "Where has the crate ended up?", "Trace that crate through the later lines of the page" |
| `s2_ep04_m3 scene quayBoxes.box12.note` | Box 12 is empty. The lamp oil was collected on 15 May. | Box 12 is empty. Its lamp oil was collected on 15 May. | Box 12 stands empty; its lamp oil was collected on 15 May. |
| `s2_ep04_m3 scene quayBoxes.box17.note` | Box 17 is empty. It was moved to Box 23. | Box 17 is empty. Its crate was moved to Box 23. | Box 17 is bare. Whatever it held was moved to Box 23. |
| `s2_ep04_m3 scene quayBoxes.box21.note` | Box 21 is locked. It is not in the ledger. | Box 21 is locked, and the ledger does not mention it. | Box 21 is locked tight, and the ledger never mentions it. |
| `learning s2_ep04_m3` | "Put the torn label back together.", "Read where it was sent." | "Fit the pieces of the torn label together", "Read where the box was sent" | "Piece the torn label back together", "discover where it was being sent" |
| `s2_ep04_final steps address.say` | Find the address. | Which address is it? | Which address fits both clues? |
| `s2_ep04_final steps address.hints[0]` | Both streets are a PASSAGE. Now read CLUE 2. | Both streets start with PASSAGE, so CLUE 1 fits both. Now check CLUE 2. | CLUE 1 cannot decide between them. Let CLUE 2 settle it. |
| `s2_ep04_final steps address.hints[1]` | CLUE 2 is No. 7. Which address has No. 7? | CLUE 2 says No. 7. Find the address with that number. | Compare each house number with CLUE 2. |
| `s2_ep04_final steps address.option pont` | Look at CLUE 2. Is it No. 3? | Read CLUE 2 again. Does it say No. 3? | CLUE 2 gives a house number. Is it 3? |
| `s2_ep04_final steps address.tell` | PASSAGE DES HORLOGERS has No. 7. | PASSAGE DES HORLOGERS is the one with No. 7. | Only PASSAGE DES HORLOGERS has No. 7. |
| `s2_ep04_final steps address.done` | PASSAGE DES HORLOGERS, No. 7! | It is No. 7, PASSAGE DES HORLOGERS! | No. 7, PASSAGE DES HORLOGERS: the watchmakers' address! |
| `learning s2_ep04_final` | "Find the address.", "CLUE 2: No. 7" | "Which address fits both clues?", "CLUE 2: No. 7" | "Only one address fits both", "CLUE 2: No. 7" |
| `glossary (추가된 단어)` | burning, caught, lists, shelf, somewhere, stone, wooden | burning, matches, mention, reminds, shelf, somewhere, stone, stuck, wooden | bears, burning, descend, destination, enamel, matches, mention, reminds, satisfies, shelf, snagged, somewhere, stone, stuck, tracked, weathered, wooden |

### s2_ep05 — The Silent Workshop

| 위치 | Rookie | Junior | Master |
|---|---|---|---|
| `intro` | Do not trust the clocks. Follow the hands that made them. / The gate is not locked. Behind it, a door says No. 7. / Inside, clocks cover the walls. / Their hands move, but the room is silent. / Someone worked here. Not long ago. | Do not trust the clocks. Follow the hands that made them. / The gate is not locked. Behind it is a door marked No. 7. / Inside, the walls are covered with clocks. / Their hands are moving, but the room is silent. / Someone was working here, and not long ago. | Do not trust the clocks. Follow the hands that made them. / The gate swings open. Beyond it, a door is marked No. 7. / Inside, clocks crowd every wall. / Their hands keep moving, yet the room is utterly silent. / Someone worked here, and not very long ago. |
| `synopsis` | The torn label led you to No. 7, Passage des Horlogers. / Inside, the clocks move, but nobody is there. / The clock parts from the tower came here. Why? | The torn label brought you to No. 7, Passage des Horlogers. / Inside, the clocks are moving, but nobody is there. / The clock parts from the tower came here. But why? | The torn label has led you to No. 7, Passage des Horlogers. / Inside, every clock is moving, yet the workshop is empty. / The clock parts from the tower ended up here. Why? |
| `objectives` | Find the maker's own mark. / Find the clock the maker changed. / Read the backwards notes on the desk. | Find the mark the maker really made. / Find out which clock the maker changed. / Read the backwards notes on the writing desk. | Tell the maker's true mark from its copies. / Discover which clock the maker altered. / Decipher the backwards notes on the desk. |
| `caseSummary` | A mark, a backward clock and a mirror led you to letter No. 4417. It never arrived. | A mark, a clock that turns backwards and a mirror led you to letter No. 4417. It never arrived. | A maker's mark, a backward clock and a mirror led you to letter No. 4417, a letter that never arrived. |
| `hook` | Who held the letter at the Louvre post room? | = Rookie | = Rookie |
| `s2_ep05_m1.story` | Behind the workbench is an empty crate. It looks like the crate from Box 23. / Four things on the bench are stamped with two clock hands. / They look the same. Are they? | Behind the workbench stands an empty crate, like the one from Box 23. / Four things on the bench have a stamp of two clock hands. / They all look the same. But are they? | An empty crate stands behind the workbench, much like the one from Box 23. / Four objects on the bench each bear a stamp of two clock hands. / At first glance they look identical. Are they? |
| `s2_ep05_m1.letterIntro` | A note on the workbench says: | There is a note on the workbench: | A note lies on the workbench: |
| `s2_ep05_m1.letter` | My mark is on everything I make. / A copy is never the same. | = Rookie | = Rookie |
| `s2_ep05_m1.question` | Which one has the maker's own mark? | Which thing has the maker's real mark? | Which object carries the maker's true mark? |
| `s2_ep05_m1.hints[0]` | Lay the tracing sheet over each stamp. Look at the lines, not the colour. | Put the tracing sheet over each stamp in turn. Compare the lines, not the colour. | The tracing sheet holds the true mark. Colour can fool you; the lines cannot. |
| `s2_ep05_m1.hints[1]` | Count the hands. See where the short hand sits. Check each tip. | For each stamp, count the hands, check where the short hand is and look at each tip. | A copy gives itself away in small things: a missing hand, a hand out of place, a different tip. |
| `s2_ep05_m1.successMessage` | You found the maker's own mark! | That is the maker's real mark! | The maker's true mark stands out! |
| `s2_ep05_m1.transition[0]` | Only the small drawer has the maker's own mark. | Only the small drawer has the maker's real mark. | Of the four, only the small drawer bears the maker's true mark. |
| `s2_ep05_m1.transition[1]` | Inside it, a repair card says: | Inside the drawer is a repair card. It says: | Inside lies a repair card: |
| `s2_ep05_m1.transition[2]` | I changed one clock. I added one small wheel. | = Rookie | = Rookie |
| `s2_ep05_m1.transition[3]` | Now its hands turn the wrong way. | = Rookie | = Rookie |
| `s2_ep05_m1.transition[4]` | On the wall, four clocks hang in a row. | On the wall, four clocks are hanging in a row. | Across the room, four clocks hang side by side on the wall. |
| `s2_ep05_m1.options[a].feedback` | Look at the tip of the long hand. Is it the same shape? | Compare the tip of the long hand. Does it have the same shape? | Study the tip of the long hand. Is its shape quite right? |
| `s2_ep05_m1.options[b].feedback` | Lay the sheet over it. Does the short hand sit in the same place? | Put the sheet over it. Is the short hand in the same place? | With the sheet laid over it, does the short hand line up? |
| `s2_ep05_m1.options[c].feedback` | Count the hands. The maker's mark has two. | How many hands can you count? The maker's mark has two. | Count again. The maker's mark always has two hands. |
| `s2_ep05_m1.clue.note` | In the small drawer: a repair card, signed with the maker's own mark. | Inside the small drawer: a repair card, signed with the maker's real mark. | Tucked in the small drawer: a repair card bearing the maker's true mark. |
| `s2_ep05_m1.evidence.description` | Found in the small drawer of the workbench. | It was found in the small drawer of the workbench. | Discovered in the small drawer of the workbench. |
| `s2_ep05_m2.story` | Four silent clocks hang in a row on the wall. / Each one shows a different time. | Four silent clocks are hanging in a row on the wall. / Every clock shows a different time. | Four silent clocks hang side by side on the wall. / No two of them agree on the time. |
| `s2_ep05_m2.letterIntro` | The repair card says: | You read the repair card again: | The repair card reads: |
| `s2_ep05_m2.letter` | I changed one clock. / I added one small wheel. / Now its hands turn the wrong way. | = Rookie | = Rookie |
| `s2_ep05_m2.question` | Which clock did the maker change? | Which clock was changed by the maker? | Which clock has the maker altered? |
| `s2_ep05_m2.hints[0]` | Watch the clocks for one minute. Read each time before and after. | Watch all four clocks for one minute. Read each time, before and after. | A minute will tell you which way each clock turns. Compare the times before and after. |
| `s2_ep05_m2.hints[1]` | Find the clock with both: a wheel added, and hands that turn the wrong way. | The right clock has two things: an added wheel, and hands that turn the wrong way. | The card describes two changes. Only one clock shows both. |
| `s2_ep05_m2.successMessage` | You found the clock that turns back! | You found the clock that goes backwards! | There it is: the clock that turns back! |
| `s2_ep05_m2.transition[0]` | Clock III went back, from 10:40 to 10:39. | Clock III moved back, from 10:40 to 10:39. | Clock III slipped backwards, from 10:40 to 10:39. |
| `s2_ep05_m2.transition[1]` | Behind it, one small brass wheel does not belong. | At its back, there is one small brass wheel that does not belong. | Behind it sits one small brass wheel that does not belong. |
| `s2_ep05_m2.transition[2]` | By the window, a writing desk is covered in ink. | By the window stands a writing desk covered in ink. | By the window, a writing desk lies stained with ink. |
| `s2_ep05_m2.options[i].feedback` | Clock I went from 3:10 to 3:11. That is the right way. | Clock I moved from 3:10 to 3:11. It turns the right way. | Clock I crept from 3:10 to 3:11: forward, as a clock should. |
| `s2_ep05_m2.options[ii].feedback` | Clock II runs fast, but it still turns the right way. | Clock II is running fast, but it still turns the right way. | Clock II may race ahead, but its hands still turn the right way. |
| `s2_ep05_m2.options[iv].feedback` | Clock IV does not move at all. It does not turn the wrong way. | Clock IV has stopped. It is not turning the wrong way. | Clock IV has not moved at all, so it cannot be turning the wrong way. |
| `s2_ep05_m2.clue.note` | Clock III turns back. Behind it, one small brass wheel that does not belong. | Clock III turns backwards. At its back: one small brass wheel that does not belong. | Clock III runs backwards. Hidden behind it: one small brass wheel that does not belong. |
| `s2_ep05_m2.evidence.description` | The third clock on the workshop wall. | The third clock in the row on the workshop wall. | Third in the row of clocks on the workshop wall. |
| `s2_ep05_m3.story` | Ink has dried on the blotting paper. The words are backwards. / A small hand mirror lies beside it. | Ink has dried on the blotting paper, and the words are backwards. / There is a small hand mirror next to it. | Dried ink has left words on the blotting paper, all of them backwards. / Beside it rests a small hand mirror. |
| `s2_ep05_m3.letterIntro` | Your notebook says: | In your notebook, you wrote: | Your notebook reminds you: |
| `s2_ep05_m3.letter` | The note is backwards. / Read it in the mirror. / Which clock does it name? | The note is written backwards. / Use the mirror to read it. / Which clock does it name? | The writing runs backwards. / Let the mirror turn it round. / Which clock does it point to? |
| `s2_ep05_m3.question` | Which clock? | Which clock does the note name? | Which clock does the note point to? |
| `s2_ep05_m3.hints[0]` | The note is backwards. A mirror turns it round. | The note is written backwards. A mirror can turn it round. | Backwards writing becomes clear in a mirror. |
| `s2_ep05_m3.hints[1]` | The mirror says: the clock that turns back. | In the mirror, the note says: the clock that turns back. | The mirror names a clock by what it does, not by its number. |
| `s2_ep05_m3.successMessage` | You found where the letter was! | You found the clock the note named! | You found the hiding place the note described! |
| `s2_ep05_m3.transition[0]` | Inside Clock III, there is no letter. | There is no letter inside Clock III. | Clock III holds no letter. |
| `s2_ep05_m3.transition[1]` | Only a torn envelope corner and a small receipt. | There is only a torn envelope corner and a small receipt. | Just a torn envelope corner and a small receipt. |
| `s2_ep05_m3.transition[2]` | 16 MAY — ONE LETTER COLLECTED FROM No. 7. | = Rookie | = Rookie |
| `s2_ep05_m3.transition[3]` | The maker's note said the letter was hidden here. | The maker's note says the letter was hidden in this clock. | According to the maker's note, the letter was hidden here. |
| `s2_ep05_m3.transition[4]` | Now it is gone. Did someone take it out? | But it is not here now. Did someone take it out? | Yet it is no longer here. Did someone take it out? |
| `s2_ep05_m3.transition[5]` | Under the door, post slips have piled up. | Under the door, a pile of post slips has built up. | Beneath the door, post slips have piled up. |
| `s2_ep05_m3.clue.note` | Inside Clock III: no letter. A receipt: 16 MAY — ONE LETTER COLLECTED FROM No. 7. LETTER No. 4417. | No letter inside Clock III, only a receipt: 16 MAY — ONE LETTER COLLECTED FROM No. 7. LETTER No. 4417. | Clock III held no letter, only a receipt: 16 MAY — ONE LETTER COLLECTED FROM No. 7. LETTER No. 4417. |
| `s2_ep05_m3.evidence.description` | You read it in the hand mirror. It named Clock III. | You read it with the hand mirror. The note pointed to Clock III. | Deciphered in the hand mirror, it pointed to Clock III. |
| `s2_ep05_final.story` | The post leaves a slip each time a letter moves. / The post box of the passage stands right outside No. 7. | Every time a letter moves, the post leaves a slip. / The passage has a post box, right outside No. 7. | Each time a letter changes hands, the post leaves a slip behind. / The passage post box stands just outside No. 7. |
| `s2_ep05_final.letterIntro` | The receipt from Clock III says: | The receipt from Clock III reads: | The receipt you found in Clock III: |
| `s2_ep05_final.letter` | 16 MAY — ONE LETTER COLLECTED FROM No. 7. / LETTER No. 4417. /  / Find its slip. | 16 MAY — ONE LETTER COLLECTED FROM No. 7. / LETTER No. 4417. /  / Which slip is for this letter? | 16 MAY — ONE LETTER COLLECTED FROM No. 7. / LETTER No. 4417. /  / Find the slip that belongs to it. |
| `s2_ep05_final.question` | Find letter 4417. | Which slip is for letter 4417? | Pick out the slip for letter 4417. |
| `s2_ep05_final.hints[0]` | Read each number: 4, 4, 1, 7. | Read the numbers one by one: 4, 4, 1, 7. | Read every digit in order. One wrong digit makes another letter. |
| `s2_ep05_final.hints[1]` | Find 4417, not 4471. | Be careful: 4417 and 4471 look alike. | Two numbers use the same digits. Only one has them in the right order. |
| `s2_ep05_final.successMessage` | You followed the letter! | You followed the letter's trail! | The letter's trail is clear now! |
| `s2_ep05_final.transition[0]` | Letter No. 4417 left No. 7 on 16 May. | On 16 May, Letter No. 4417 left No. 7. | Letter No. 4417 left No. 7 on the morning of 16 May. |
| `s2_ep05_final.transition[1]` | It was collected and sorted. | First it was collected, then it was sorted. | It was collected, then sorted. |
| `s2_ep05_final.transition[2]` | Then it stopped: HELD at the Louvre post room. | After that, it stopped: HELD at the Louvre post room. | Then, at 4:00 PM, it went no further: HELD at the Louvre post room. |
| `s2_ep05_final.transition[3]` | It was never delivered. | It was never delivered to anyone. | It never reached its address. |
| `s2_ep05_final.transition[4]` | Who stopped it? And why? | Who stopped it, and why? | Who held it back, and why? |
| `s2_ep05_final.evidence.description` | Three post slips from under the workshop door. | Three post slips found under the workshop door. | Three post slips gathered from under the workshop door. |
| `learning s2_ep05_m1` | "My mark is on everything I make.", "A copy is never the same." | "A copy is never the same.", "Which thing has the maker's real mark?" | "A copy is never the same.", "Which object carries the maker's true mark?" |
| `s2_ep05_m2 scene clockWall.i.backNote` | Brass gears and two weights. | Only brass gears and two weights. | Ordinary brass gears and two weights. |
| `s2_ep05_m2 scene clockWall.ii.backNote` | A big, shiny spring. | There is a big, shiny spring. | A large, gleaming spring. |
| `s2_ep05_m2 scene clockWall.iii.backNote` | A small brass wheel at the side of the gears. | There is a small brass wheel beside the gears. | A small brass wheel tucked beside the gears. |
| `s2_ep05_m2 scene clockWall.iv.backNote` | The pendulum hook is broken. | The hook for the pendulum is broken. | The pendulum hook has snapped. |
| `learning s2_ep05_m2` | "I added one small wheel.", "Now its hands turn the wrong way." | "I added one small wheel.", "Now its hands turn the wrong way.", "Which clock was changed by the maker?" | "I added one small wheel.", "Now its hands turn the wrong way.", "Which clock has the maker altered?" |
| `s2_ep05_m3 steps mirror.say` | Tap the mirror. | = Rookie | = Rookie |
| `s2_ep05_m3 steps mirror.hints[0]` | The note is backwards. A mirror turns it round. | The note is written backwards. A mirror can turn it round. | Backwards writing becomes clear in a mirror. |
| `s2_ep05_m3 steps mirror.hints[1]` | Tap the hand mirror. | = Rookie | = Rookie |
| `s2_ep05_m3 steps mirror.done` | THE CLOCK THAT TURNS BACK. | = Rookie | = Rookie |
| `s2_ep05_m3 steps clock.say` | Which clock? | Which clock does the note name? | Which clock does the note point to? |
| `s2_ep05_m3 steps clock.hints[0]` | The mirror says: the clock that turns back. | In the mirror, the note says: the clock that turns back. | The mirror names a clock by what it does, not by its number. |
| `s2_ep05_m3 steps clock.hints[1]` | Find "turns back" under the clocks. | Read the words under each clock. Find "turns back". | Under each clock are a few words. Which match the mirror? |
| `s2_ep05_m3 steps clock.option ii` | Clock II runs fast. Which clock turns back? | Clock II only runs fast. Which clock turns back? | Clock II runs fast, but it never turns back. Look again. |
| `s2_ep05_m3 steps clock.tell` | Clock III turns back. | Clock III is the one that turns back. | It is Clock III: the clock that turns back. |
| `s2_ep05_m3 steps clock.done` | Clock III! No letter inside. Only a receipt. | Clock III! There is no letter inside, only a receipt. | Clock III! But no letter waits inside, only a receipt. |
| `learning s2_ep05_m3` | "the clock that turns back", "Which clock?" | "the clock that turns back", "Use the mirror to read it" | "Let the mirror turn it round", "Which clock does the note point to?" |
| `s2_ep05_final steps letter.say` | Find letter 4417. | Which slip is for letter 4417? | Pick out the slip for letter 4417. |
| `s2_ep05_final steps letter.hints[0]` | Read each number: 4, 4, 1, 7. | Read the numbers one by one: 4, 4, 1, 7. | Read every digit in order. One wrong digit makes another letter. |
| `s2_ep05_final steps letter.hints[1]` | Find 4417, not 4471. | Be careful: 4417 and 4471 look alike. | Two numbers use the same digits. Only one has them in the right order. |
| `s2_ep05_final steps letter.option 4471` | This is 4471. Read the numbers again: 4417. | This slip says 4471. Look again for 4417. | This one reads 4471: the right digits, in the wrong order. |
| `s2_ep05_final steps letter.tell` | Look: this slip says 4417. | This is the one. Its slip says 4417. | Here: this slip reads 4417. |
| `s2_ep05_final steps letter.done` | Letter 4417! Here is where it went. | Letter 4417! Now you can see where it went. | Letter 4417! Here is the path it took. |
| `learning s2_ep05_final` | "Find letter 4417." | "Which slip is for letter 4417?" | "Pick out the slip for letter 4417" |
| `glossary (추가된 단어)` | arrived, backward, bench, colour, covered, nobody, shape, workshop | arrived, bench, colour, covered, nobody, pile, reads, shape, workshop | altered, arrived, backward, bench, carries, colour, covered, decipher, deciphered, gleaming, identical, nobody, pile, reads, shape, snapped, stained, workshop |

### s2_ep06 — The Letter That Never Arrived

| 위치 | Rookie | Junior | Master |
|---|---|---|---|
| `intro` | Letter No. 4417 stopped at the Louvre post room. / It was never delivered. / The post room is quiet. Nobody is at the desk. / Letter 4417 should be here. | Letter No. 4417 stopped here, at the Louvre post room. / It never reached its address. / The post room is quiet, and nobody is at the desk. / Letter 4417 should be somewhere here. | Letter No. 4417 went no further than the Louvre post room. / Its journey ended here, undelivered. / The post room is hushed. No one sits at the desk. / Somewhere in this room, Letter 4417 should be waiting. |
| `synopsis` | Letter No. 4417 was held at the Louvre post room. / Now it is not there. Was it stolen? Or is it hidden? / What can it tell us about the missing hour? | Letter No. 4417 was stopped and held at the Louvre post room. / But now it is not there. Was it stolen, or is it hidden? / And what can it tell us about the missing hour? | Letter No. 4417 was held back at the Louvre post room. / Now it is nowhere to be seen. Was it stolen, or hidden away? / And what might it reveal about the missing hour? |
| `objectives` | Find the tag of Letter 4417. / Follow the letter through the building. / Find the letter and read its secret. | Find the tag for Letter 4417. / Follow the path the letter took through the building. / Find the letter and read what it says. | Track down the tag for Letter 4417. / Trace the letter's route through the building. / Find the letter and uncover its secret. |
| `caseSummary` | Letter 4417 was kept safe, not stolen. Its back points to the opera archive. | Letter 4417 was not stolen. It was kept safe, and its back points to the opera archive. | Letter 4417 was never stolen, only kept safe, and its back points the way to the opera archive. |
| `hook` | What is in File 3–4 of the opera archive? | = Rookie | = Rookie |
| `s2_ep06_m1.story` | Behind the desk is a wooden rack. One slot is empty. / Four paper tags hang on it. Each tag has two sides. | Behind the desk stands a wooden rack, and one of its slots is empty. / Four paper tags hang from it. Every tag has two sides. | Behind the desk rises a wooden rack. One of its slots sits empty. / Four paper tags dangle from it, each with a front and a back. |
| `s2_ep06_m1.letterIntro` | The Letter's Trail in your notebook says: | Your notebook has the Letter's Trail: | The Letter's Trail, copied in your notebook: |
| `s2_ep06_m1.letter` | LETTER No. 4417 / 16 MAY · 4:00 PM / HELD · LOUVRE POST ROOM | = Rookie | = Rookie |
| `s2_ep06_m1.question` | Which tag is for Letter 4417? | Which tag belongs to Letter 4417? | Which of the tags is the one for Letter 4417? |
| `s2_ep06_m1.hints[0]` | Read each tag's front. Is it a LETTER? Is the number 4417? | Read the front of each tag first. Does it say LETTER? Is the number 4417? | Begin with what each front says: the kind of post, and the number. |
| `s2_ep06_m1.hints[1]` | Ink hides a number on two tags. Turn them over. Check the day and time. | On two tags, ink covers part of the number. Turn those over and compare the day and time. | Where ink hides a digit, the back must decide. Compare it with your notebook. |
| `s2_ep06_m1.successMessage` | Wait! It wasn't stolen. | = Rookie | = Rookie |
| `s2_ep06_m1.transition[0]` | Tag D says PRESERVATION ORDER: keep it safe. | Tag D reads PRESERVATION ORDER: keep it safe. | The back of Tag D reads: PRESERVATION ORDER: keep it safe. |
| `s2_ep06_m1.transition[1]` | Someone kept it safe. | = Rookie | = Rookie |
| `s2_ep06_m1.transition[2]` | But where is it now? | So where is the letter now? | But where has it gone since? |
| `s2_ep06_m1.options[a].feedback` | Read the first word. Is it a LETTER or a PARCEL? | Check the first word. Does it say LETTER or PARCEL? | Mind the first word: a LETTER is not a PARCEL. |
| `s2_ep06_m1.options[b].feedback` | Read the number slowly. Is it 4417? | Read the number again, slowly. Does it say 4417? | Read the digits one by one. Is that really 4417? |
| `s2_ep06_m1.options[c].feedback` | Turn it over. Check the day and the time. | Turn the tag over. Do the day and the time match? | The front cannot tell you enough. What do the day and time on the back say? |
| `s2_ep06_m1.clue.note` | Held on 16 MAY at 4:00 PM. PRESERVATION ORDER: keep it safe. | It was held on 16 MAY at 4:00 PM. PRESERVATION ORDER: keep it safe. | Held on 16 MAY at 4:00 PM, under a PRESERVATION ORDER: keep it safe. |
| `s2_ep06_m1.evidence.description` | Found on the hold rack of the Louvre post room. | It was hanging on the hold rack in the Louvre post room. | Taken from the hold rack of the Louvre post room. |
| `s2_ep06_m2.story` | The post room book has two lines for Letter 4417. / 16 MAY · 4:00 PM · HELD. / 17 MAY · MORNING · MOVED. / A plan of the building hangs on the wall. | In the post room book, there are two lines for Letter 4417. / 16 MAY · 4:00 PM · HELD. / 17 MAY · MORNING · MOVED. / On the wall hangs a plan of the building. | The post room book records two entries for Letter 4417. / 16 MAY · 4:00 PM · HELD. / 17 MAY · MORNING · MOVED. / A plan of the whole building hangs on the wall. |
| `s2_ep06_m2.letterIntro` | A porter's note is pinned to the plan: | Someone has pinned a porter's note to the plan: | Pinned to the plan is a note from a porter: |
| `s2_ep06_m2.letter` | Letters to keep safe go downstairs. / Go down the stairs. / Walk past the statue. / Take the second door on the left. | = Rookie | = Rookie |
| `s2_ep06_m2.question` | Which door did the letter go through? | Through which door was the letter taken? | Which door did the letter pass through? |
| `s2_ep06_m2.hints[0]` | Move one step at a time: the stairs first, then the statue. | Follow the note line by line. Go down the stairs, then walk past the statue. | Let the note lead you, one line at a time. |
| `s2_ep06_m2.hints[1]` | After the statue, count only the doors on the left: one, two. | Once you are past the statue, count the doors on the left only. | Past the statue, ignore the doors on the right. Count along the left. |
| `s2_ep06_m2.successMessage` | The letter went to the archive! | The letter was taken to the archive! | The letter was moved down to the archive! |
| `s2_ep06_m2.transition[0]` | Behind Door E is the archive. | The archive is behind Door E. | Door E opens onto the archive. |
| `s2_ep06_m2.transition[1]` | Tall cabinets. Hundreds of small drawers. | There are tall cabinets with hundreds of small drawers. | Tall cabinets rise to the ceiling, with hundreds of small drawers. |
| `s2_ep06_m2.transition[2]` | Letter 4417 must be here. | Letter 4417 must be somewhere in here. | Letter 4417 must be among them. |
| `s2_ep06_m2.options[a].feedback` | Not yet. Walk past the statue first. | Too early. You have not walked past the statue yet. | Too soon. The note says to pass the statue first. |
| `s2_ep06_m2.options[b].feedback` | Not yet. Walk past the statue first. | Too early. You have not walked past the statue yet. | Too soon. The note says to pass the statue first. |
| `s2_ep06_m2.options[c].feedback` | That's the first door on the left. Count one more. | That is only the first door on the left. Keep counting. | The first door on the left. The note asks for another. |
| `s2_ep06_m2.options[d].feedback` | That door is on the right. Which side is left? | That door is on the right side. Which side is the left? | That door lies on the right. The note says left. |
| `s2_ep06_m2.options[f].feedback` | That door is on the right. Which side is left? | That door is on the right side. Which side is the left? | That door lies on the right. The note says left. |
| `s2_ep06_m2.clue.note` | Down the stairs, past the statue, the second door on the left: the archive. | Down the stairs, past the statue, then the second door on the left. It is the archive. | Down the stairs, past the statue, through the second door on the left: the archive. |
| `s2_ep06_m2.evidence.description` | Pinned to the plan of the building, in the post room. | It was pinned to the plan of the building in the post room. | Found pinned to the building plan in the post room. |
| `s2_ep06_m3.story` | Torn letters are kept here. Each drawer has a label. / Many torn letters have lost their numbers. | Torn letters are stored here, and each drawer has a label. / Many of these torn letters have lost their numbers. | This is where torn letters are kept, each drawer marked with a label. / Many of them have lost their numbers along the way. |
| `s2_ep06_m3.letterIntro` | The torn envelope corner from Clock III says: | The torn envelope corner from Clock III has a label: | The torn envelope corner you found in Clock III reads: |
| `s2_ep06_m3.letter` | No. 4417 /  / Find the envelope it was torn from. | No. 4417 /  / Which envelope was it torn from? | No. 4417 /  / Find the envelope this corner was torn from. |
| `s2_ep06_m3.question` | Which envelope is Letter 4417? | Which envelope is the one for Letter 4417? | Which envelope belongs to Letter 4417? |
| `s2_ep06_m3.hints[0]` | Find the drawer first. Is it for letters? Is 4417 between its two numbers? | First find the right drawer. It must be for letters, and 4417 must be between its two numbers. | The drawer comes first: the right kind of post, and a range that includes 4417. |
| `s2_ep06_m3.hints[1]` | Lay the torn corner on each envelope. Only one torn edge fits. | Try the torn corner on each envelope. Only one torn edge fits it. | Only one torn edge will meet the corner exactly. |
| `s2_ep06_m3.successMessage` | There it is! Letter 4417! | You found it! Letter 4417! | At last, Letter 4417! |
| `s2_ep06_m3.transition[0]` | The corner fits. This is Letter 4417. | The corner fits perfectly. This is Letter 4417. | The corner fits exactly. This is Letter 4417. |
| `s2_ep06_m3.transition[1]` | But what's this little picture on the seal? | But what is this little picture on the seal? | But what is the tiny picture pressed into the seal? |
| `s2_ep06_m3.transition[2]` | Inside the envelope is a letter. | There is a letter inside the envelope. | Inside the envelope, a letter is waiting. |
| `s2_ep06_m3.options[x].feedback` | The torn edges do not match. | These torn edges do not fit together. | The torn edges refuse to line up. |
| `s2_ep06_m3.options[z].feedback` | Look at the torn edge. Does the corner fit there? | Look closely at the torn edge. Does the corner fit it? | Study the torn edge. Would the corner fit it exactly? |
| `s2_ep06_m3.clue.note` | The torn corner from Clock III fits one envelope. On its seal: a tiny picture of a building. | The torn corner from Clock III fits only one envelope. On its seal is a tiny picture of a building. | Only one envelope matches the torn corner from Clock III. Its seal shows a tiny building. |
| `s2_ep06_m3.evidence.description` | Found in a drawer of the archive. | It was in one of the archive drawers. | Recovered from a drawer in the archive. |
| `s2_ep06_final.story` | Two lines, and a drawing of the building on the seal. / A map of Paris hangs on the wall. | The letter has two lines, and a drawing of the building from the seal. / On the wall hangs a map of Paris. | Two short lines, and a drawing of the very building on the seal. / A map of Paris hangs on the archive wall. |
| `s2_ep06_final.letterIntro` | The letter says: | The letter reads: | The letter holds just two lines: |
| `s2_ep06_final.letter` | The clocks may lie. / But the show remembers. | = Rookie | = Rookie |
| `s2_ep06_final.question` | Which building is in the drawing? | Which building does the drawing show? | Which building has been drawn on the letter? |
| `s2_ep06_final.hints[0]` | Look at the roof in the drawing. What shape is it? What stands on it? | Look carefully at the roof in the drawing. What shape is it, and what stands on top? | The roof is the key: its shape, and what stands upon it. |
| `s2_ep06_final.hints[1]` | The letter says "the show remembers". Where do people go to see a show? | The letter says "the show remembers". Which building is a place for shows? | Think about "the show remembers". Where would a show be remembered? |
| `s2_ep06_final.successMessage` | We found our next clue! | = Rookie | = Rookie |
| `s2_ep06_final.transition[0]` | The drawing is the Palais Garnier, the opera house. | The drawing shows the Palais Garnier, the opera house. | The building in the drawing is the Palais Garnier, the city's grand opera house. |
| `s2_ep06_final.transition[1]` | On the back: OPERA ARCHIVE · FILE 3–4. | = Rookie | = Rookie |
| `s2_ep06_final.transition[2]` | The mystery continues at the opera house! | = Rookie | = Rookie |
| `s2_ep06_final.options[montmartre].feedback` | Its church has domes, but no statues on the roof. | Its church does have domes, but there are no statues on its roof. | Domes, yes, but not a single statue on its roof. |
| `s2_ep06_final.options[louvre].feedback` | We are at the Louvre already. Look at the roof in the drawing. | We are already at the Louvre. Look again at the roof in the drawing. | We are already at the Louvre. Compare its roof with the drawing. |
| `s2_ep06_final.options[arcDeTriomphe].feedback` | That is a big arch. The drawing has a dome. | That is a huge arch, but the drawing shows a dome. | An arch, however grand, is not a dome. |
| `s2_ep06_final.options[gareDuNord].feedback` | That is a station. Trains, not shows! | That is a train station. People go there for trains, not shows! | A railway station: trains, not shows! |
| `s2_ep06_final.options[notreDame].feedback` | It has two tall towers. The drawing has a dome. | It has two tall towers, but the drawing has a dome. | Two tall towers rise from it. The drawing shows a dome. |
| `s2_ep06_final.options[eiffelTower].feedback` | The tower has no dome and no statues. | The tower has no dome and no statues at all. | An iron tower, with neither a dome nor statues. |
| `s2_ep06_final.evidence.description` | Letter No. 4417, found in the archive. | This is Letter No. 4417. It was found in the archive. | Letter No. 4417, recovered at last from the archive. |
| `learning s2_ep06_m1` | "LETTER No. 4417", "Which tag is for Letter 4417?" | "LETTER No. 4417", "Which tag belongs to Letter 4417?" | "LETTER No. 4417", "Where ink hides a digit, the back must decide" |
| `learning s2_ep06_m2` | "Walk past the statue.", "Take the second door on the left." | "Walk past the statue.", "Take the second door on the left.", "count the doors on the left only" | "Walk past the statue.", "Take the second door on the left.", "Count along the left" |
| `s2_ep06_m3 scene archive.notHere` | {label}. Is 4417 between these two numbers? | {label}. Does 4417 fall between these two numbers? | {label}. Is 4417 inside this range? |
| `s2_ep06_m3 scene archive.notLetters` | {label}. This drawer is for parcels. | {label}. This drawer is only for parcels. | {label}. Parcels only: not the drawer you need. |
| `s2_ep06_m3 scene archive.notFit` | The torn edges do not match. | These torn edges do not fit together. | The torn edges refuse to line up. |
| `s2_ep06_m3 scene archive.sealLine` | A tiny picture of a grand building. | A tiny picture of a big, grand building. | A tiny drawing of a grand building, pressed into the wax. |
| `learning s2_ep06_m3` | "Find the envelope it was torn from." | "Which envelope was it torn from?" | "Find the envelope this corner was torn from" |
| `learning s2_ep06_final` | "But the show remembers." | "But the show remembers.", "Which building is a place for shows?" | "But the show remembers.", "Where would a show be remembered?" |
| `glossary (추가된 단어)` | between, building, church, continues, domes, hundreds, secret, slowly | belongs, between, building, church, continues, covers, domes, hundreds, secret, slowly, stored | belongs, between, building, church, continues, covers, dangle, domes, hundreds, hushed, range, recovered, refuse, secret, slowly, stored, trace, uncover |

## 부록 B. 재현 방법

- 원본: `lib/data/mock/season2/season2_levels_04_06.dart`(Junior·Master 사건 패치 `junior04`~`master06`, Rookie 패치 `rookie05`, 장면 `juniorScenes0406`/`masterScenes0406`, 학습 표현, glossary). 연결: `season2_difficulty.dart`.
- 적용 결과: `DifficultyContent.episodeAt(<기준 사건>, Difficulty.junior|master)` → 미션별 `SeasonCatalog.easySteps(m)`·`keeperHut(m)` 등.
- 확인: `DifficultyContent.missingAt('s2_ep05', Difficulty.master)`(빈 목록), `DifficultyContent.problems()`(빈 목록).
- 부록 A와 §D 통계는 위 API로 세 Case의 세 난이도 문장을 같은 위치끼리 뽑은 것이다. 위치 체계는 테스트의 `fields()`·`sceneWords()`와 같다.
- 개발자 모드: Game Master → START DEVELOPER MODE → TEST LEVEL에서 난이도를 고른 뒤 Paris Case 04~06.
