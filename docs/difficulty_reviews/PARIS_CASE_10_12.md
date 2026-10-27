# Paris Case 10~12 — 난이도별 영어 콘텐츠 검토 보고서 (PART 7D, 시즌 완결)

> Season 2 *Paris Stands Still*의 마지막 세 사건과 시즌 전체 검증을 다룬다.
> - Case 10 *The Hour of Shadows*
> - Case 11 *The Unwritten Hour*
> - Case 12 *The Clockmaker's Truth*
>
> 작업은 2026-10-27에 로컬 `main`에서 했다. PART 7C 커밋 `98bae78` 다음에 이어서 작업했다.
>
> 기준 문서:
> - `docs/SEASON2_PARIS_STORY_BIBLE.md` v2.0: §2(최종 진실), §2.6(Big Ben 이중 잠금), §3(인물), §6 Case 10 v1.9 · Case 11·12 v2.0, §8(공개 단계)
> - `docs/SEASON2_CASE11_SPEC.md`, `docs/SEASON2_CASE12_SPEC.md`
>
> 영어 원문 전체는 **부록 A**에 있다. 실제 적용 데이터에서 자동으로 추출했고, 대화·결말 줄을 줄 단위로 싣는다.

## 0. 결과 요약

- `s2_ep10`~`s2_ep12`를 Rookie·Junior·Master로 `season2WrittenLevels`에 등록했다. 이로써 **Paris Season 2의 12개 Case가 모두 세 난이도로 작성됐다.**
  - 12개 Case 모두 세 난이도에서 `missingAt` 결과가 빈 목록이다.
  - `problems()` 결과도 빈 목록이다.
  - 시즌의 모든 표 항목이 두 난이도 변형에 들어 있다(그림 표만 제외).
- **Rookie**는 기준본을 그대로 쓴다.
  - Case 10~12는 2026-10-26에 8~12세용으로 단순하게 다시 쓴 문장이다(v2.0).
  - 바꿀 문장은 찾지 못했다. glossary만 늘렸다.
- **Junior와 Master**에서 쓴 것:
  - 사건 파일과 미션 텍스트 전부.
  - Case 10 장면 4종의 문장.
  - 대화 7개: Case 11의 미션 대화 2개와 Final 대화, Case 12의 미션 대화 3개. 대사 줄, 질문, 제시 안내, 오답 줄, 정답 안내를 썼다.
  - EasySteps 7개.
  - 결말 11줄.
  - 학습 표현 12개와 glossary.
- **구조 검사**를 추가했다.
  - Case 10 장면: `DrumTapeScene`, `CityClocksScene`, `ShadowCheckScene`, `HourRecordScene`
  - 대화: `TalkScene`, `TalkMission`
  - 결말: `List<EndingLine>`
- **검증**:
  - 신규 테스트 `test/difficulty_paris_7d_test.dart` 36개가 통과했다(시즌 전체 검증 포함).
  - `flutter analyze` 결과 0 issues.
  - 전체 `flutter test` **2,512개 통과**. 기존 2,476개에 신규 36개를 더한 수다. 실패 0, skip 0, 5분 14초.

## A. 사건별 스토리 요약과 공개 시점

| | 이미 아는 것 | 이번에 발견 | 아직 숨김 | 정답 근거 | 결말에서만 |
|---|---|---|---|---|---|
| **10 M1** 드럼 테이프 | T1 = 별 = 개선문, KEPT AT THE STAR | T1이 2:45 다음에 2:00으로 돌아가고 이어서 4:00으로 건너뜀. 3시 기록 없음 | 시간 소멸 여부 | 15분 간격 규칙(`t5`, `t9`) | — |
| **10 M2** 지붕 사진 | 시험 시계에는 표식이 있다(Case 09 Trial Map) | 시험 시계가 아닌 시계 셋은 3:30, T1은 2:30 | 누가 맞는지 | 별 표식 = T1뿐 | — |
| **10 M3** 해시계 | 사진 2장 | 사진 2의 해 = 3:30 | — | 그림자 길이·방향 | — |
| **10 Final** | 위 세 단서 | 시간은 흘렀다. T1이 한 시간 늦었다. 3쪽이 없다 | 3쪽을 보낸 사람·이유·내용 | 사진 2 = 1시간 반 뒤 | 목록 `p.3 · SENT TO: SAINT-SULPICE · ARCHIVE ANNEX` |
| **11 M1** 큰 장부 | 3쪽이 Saint-Sulpice로 보내졌다 | 문질러 읽은 글 `Page 3 is in Box 9. Lock it. No one may read it.` + 서명. 3쪽(E.M. "Stop", V.D. "Keep going") | V.D. = Victor(상자를 연 뒤 대화에서 밝혀짐), E.M.의 정체 | 상자 번호 9 | — |
| **11 M2** 두 종이 | 3쪽 | Victor의 종이(`All the clocks were fine.`)는 거짓. 도장 = 오페라 슬립 도장 | 누가 숨겼는지 | 3쪽 첫 줄, 도장 비교 | — |
| **11 M3** 방문록 | 문지른 서명 | 같은 서명 = Victor | — | 굽은 V, 긴 줄, 점 | — |
| **11 Final** 대화 | 세 증거 | Victor의 고백 `Yes. I hid the page. … I was afraid. I didn't want people to know.` | E.M.의 이름·얼굴, Clockmaker, 런던 | 질문마다 맞는 증거 | `His old machine is at Arts et Métiers.` |
| **12 M1** 바퀴 | E.M., 옛 기계 | 이름표 `Made by Émile Moreau` → E.M. = Émile | **Clockmaker와 같은 사람인지** | 바퀴살 4개(X) | — |
| **12 M2** 시계 | Clockmaker의 시계(런던), Case 01 톱니 표식 | 시계 속 같은 바퀴 + Émile의 도장 = Clockmaker 표식 → **Émile = Clockmaker**. 이어서 동기와 Big Ben 보관함 이야기 | — | 톱니 8개 | — |
| **12 M3** 기계 | 기계가 한 시간 늦다 | 멈춤 → 돌림 → 핀 → 시작으로 고침 | — | 카드 순서 | — |
| **12 Final** 보드 | 전부 | 질문 6개로 사건 정리 | — | 증거 하나씩 | 결말: Victor의 기록, Émile의 사과, 3쪽을 유리 상자에 보관 |

- **스토리 바이블과 실제 구현의 차이**: 충돌은 찾지 못했다. 다만 실제 데이터에는 한 가지가 기록돼 있다(수정하지 않음). `s2_ep10_m2`의 학습 설계가 `isHonest`가 아니다(의존도 exposure + 수준 comprehension). 이 조합은 엔진의 정직성 규칙에 맞지 않는다. §J에 기록했다.
- 세 난이도에서 **같은 시점에 같은 사실**을 공개한다. 테스트 `the whole season at every level`가 확인한다.
  - Victor·Delacroix는 Case 11 전에 나오지 않는다.
  - Émile·Moreau는 Case 12 전에 나오지 않는다.
  - `THE RECORD WAS REMOVED`는 어디에도 없다.
  - "Émile is the Clockmaker"류 문장은 Case 12 M1 전체와 M2의 정답 전 문장(대화 포함)에 없다.

## B. Mission별 적용 현황

| 미션 | 화면 | Rookie | Junior·Master | 장면·대화 |
|---|---|---|---|---|
| `s2_ep10_m1` | 테이프 당기기·두 곳 탭 | 기준본 | ✓ | `drumTapes` 줄 3개 |
| `s2_ep10_m2` | 돋보기·분류 | 기준본 | ✓ | `cityClocks` 오답 4개, 줄 3개 |
| `s2_ep10_m3` | 해 움직이기 | 기준본 | ✓ (question은 조작 안내라 공통) | `shadowChecks` 줄 3개 |
| `s2_ep10_final` | 테이프 2:30 → 3쪽 → 목록 → 지도 | 기준본 | ✓ | `hourRecords` 줄 10종 |
| `s2_ep11_m1` | 대화 → EasySteps 5단계 → 대화 | 기준본 | ✓ | 대화 2개(8줄 + 8줄), 단계 5개 |
| `s2_ep11_m2` | 대화 → EasySteps 2단계 → 대화 | 기준본 | ✓ | 대화 2개, 단계 2개 |
| `s2_ep11_m3` | EasySteps 2단계 | 기준본 | ✓ | 단계 2개 |
| `s2_ep11_final` | Victor와 대화(제시 3 + 질문 2) | 기준본 | ✓ | 대화 1개 |
| `s2_ep12_m1` | 대화 → 바퀴 → 대화 | 기준본 | ✓ | 대화 2개, 단계 2개 |
| `s2_ep12_m2` | 대화 → 시계·도장 5단계 → 대화(질문 4) | 기준본 | ✓ | 대화 2개, 단계 5개 |
| `s2_ep12_m3` | 대화 → 기계 4단계 → 대화 | 기준본 | ✓ | 대화 2개, 단계 4개 |
| `s2_ep12_final` | 보드 6문항 → 결말 | 기준본 | ✓ | 단계 6개, 결말 11줄 |

**텍스트 분류**

- **A. 안전하게 적용**: 사건 JSON, 장면 문장, 대화 문장, 단계 문장, 결말 문장, 학습 표현.
- **B. 최소 구조 확장**: 구조 검사 7종만 추가했다. 엔진·모델·화면 코드는 바꾸지 않았다.
  - 대화는 진행 저장값이 `단계 id + 줄 번호`다. 그래서 **각 대사 묶음의 줄 수, 화자, 표정**을 구조에 넣었다. 어느 난이도도 줄을 더하거나 뺄 수 없다.
- **C. 정답·진행·증거와 결합 → 모든 난이도에서 동일**:
  - 퍼즐 문서: 테이프 머리글, 사진 뒷면, 해시계 글, 사진 시각, Trial Log 쪽과 목록, 문지른 글, 3쪽, Victor의 종이, 이름표, PARIS, 기계 카드, 보드 질문.
  - 선택지 라벨, EasySteps의 질문(YES/NO 선택 질문), 조작 안내(Tap…/Press…/Rub…).
  - 증거가 인용하는 말: Victor의 `Yes. I hid the page.`·`I was afraid.`·`I didn't want people to know.`, 사건 파일 세 줄.
  - 바이블 v2.0의 아이용 설명: `A secret box is under it.`·`Inside is a list of hidden papers.`·`It opens only if Big Ben stops.`, `His old machine is at Arts et Métiers.`
  - 앞 사건 인용: `The Clockmaker steals an hour.`, `The clocks may lie.`, 에펠탑 명판, Case 09의 끝 질문.
  - 시즌 마지막 말 `The hour was never gone.`
- **도달 불가 문장**: Case 10~12에는 없다.

## C. 난이도별 영어 문장 비교 (대표)

| 위치 | Rookie | Junior | Master |
|---|---|---|---|
| Story — `s2_ep10` intro[6] | In the garden, we tested a model. These records are from the real trial. | In the garden, we tested a model. These records come from the real trial. | The garden held only a model. These records belong to the real trial. |
| Story — `s2_ep10_final` transition[0] | Paris did not lose an hour. For one hour, T1 was wrong. | Paris never lost an hour. For one hour, T1 was simply wrong. | Paris lost no hour at all. For one hour, T1 was wrong. |
| Dialogue — Victor, `s2_ep11_m1` 첫 줄 | Welcome to the archive. | Welcome to the archive annex. | Ah, a visitor. Welcome to the archive. |
| Dialogue — Victor, Final `name` | …I did. / Yes. I hid the page. / Why? / The test was my job. / … / I know. I am sorry. | …It was me. / Yes. I hid the page. / But why? / I was in charge of the test. / … / I know. I am truly sorry. | …I signed it. / Yes. I hid the page. / Why would you do that? / The test was my responsibility. / … / I know. I am deeply sorry. |
| Dialogue — Émile, `why` | I wanted people to look. / Look for what? / The missing page. / But you scared people. / I know. I was wrong. | I wanted people to start looking. / Looking for what? / For the missing page. / But you scared people. / I know. I was wrong. | I wanted people to search. / Search for what? / For the page that went missing. / But you frightened people. / I know. I was wrong to do that. |
| Dialogue — Émile, `bigBen` 첫·끝 줄 | I tried to stop Big Ben. … Yes. It never opened. | I tried to make Big Ben stop. … Yes. The box never opened. | I tried to bring Big Ben to a halt. … You did. The box stayed shut. |
| Puzzle — `s2_ep10_m1` question | Where does the time jump? Tap the two places. | Find the two places where the time jumps. Tap them. | Where does the time leap? Tap both places. |
| Puzzle — `s2_ep11_final` question | Who hid the truth? | Who really hid the truth? | Who buried the truth? |
| Hint 1 — `s2_ep10_final` | Photo 2 was taken later than Photo 1. How much later? | Photo 2 was taken after Photo 1. Count how much later. | Measure the time between the two photos on the tape. |
| 보드 q6 오답 | A good reason does not make it OK. | Having a good reason does not make it OK. | Even a good reason cannot make that right. |
| 결말 [2]~[4] (Émile) | And I made bad choices. / I scared people. I'm sorry. / I will tell everyone what I did. | And I made bad choices too. / I scared people, and I'm sorry. / I will tell everyone the truth about what I did. | And I made choices I regret. / I frightened people. I am sorry for that. / I will tell everyone what I have done. |
| 결말 마지막 | No one can hide it again. | Nobody can ever hide it again. | No one will ever hide it again. |

## D. 난이도 적합성과 시즌 전체 문체

| 범위 | Rookie | Junior | Master |
|---|---|---|---|
| Case 01~03 (7A) | 6.0단어 · 3.6% | 6.9 · 3.2% | 7.5 · 5.2% |
| Case 04~06 (7B) | 5.9 · 3.2% | 7.4 · 3.1% | 7.6 · 3.5% |
| Case 07~09 (7C) | 5.7 · 3.3% | 7.3 · 2.9% | 7.6 · 4.2% |
| **Case 10~12 (7D)** | 5.4 · 2.0% | 6.5 · 1.9% | 6.8 · 2.8% |
| **시즌 전체** | **5.8 · 3.1%** (821문장) | **7.0 · 2.8%** (782) | **7.4 · 4.0%** (733) |

(표의 값은 문장당 단어 수와 8글자 이상 단어의 비율이다. intro·synopsis·story·question·hints·success·transition 기준이다.)

- **Case 10~12 수치**: 기준본이 시즌에서 가장 짧은 문장(v2.0 단순화)이라 세 난이도 모두 수치가 낮다. 계단 순서(Rookie < Junior < Master)는 그대로다. 8~12세 대상을 유지하려고 Master도 짧은 문장을 넘지 않게 썼다.
- **인물 말투**:
  - Victor: 짧고 방어적이다가 고백에서 무너진다. Junior는 "Fine. …", Master는 "Very well. …"로 같은 흐름을 유지한다.
  - Émile: 침착하고 짧다. "Trust the clues"라는 주제를 세 난이도 모두 유지한다.
  - 탐정: 짧은 질문을 한다.
  - 대사 묶음마다 줄 수·화자·표정이 같다(테스트).
- **Rookie가 결말을 이해할 수 있는지**: 보드 6문항, 결말 11줄, 사건 파일이 기준본 그대로다. 이 문장들은 v2.0에서 8~12세용으로 확정된 것이다.
- **Master가 결말에 새 사실을 더하지 않았는지**:
  - 결말에서 바뀐 것은 표현뿐이다: "choices I regret", "the whole city can know", "laid in a glass case".
  - 새 설정은 없다. 보관함 위치, 런던 행동의 정당화, 처벌 같은 내용은 넣지 않았다.
- **바이블의 도덕 원칙을 지켰는지**: "옳은 목적이 잘못된 행동을 정당화하지 않는다"는 원칙을 세 난이도 모두에서 지킨다.
  - 보드 q6의 오답 줄과 정답이 이를 보여 준다.
  - Émile의 `why`·`clues` 대사 끝도 같다(`I was wrong` / `That was wrong`, 테스트).

### 의도적으로 모든 난이도에서 같은 줄 (테스트 `keptAtEveryLevel` + 대화·결말 테스트)

- **Case 10**:
  - 문서·사진(`m1~m3.letter`, `final.letter`)
  - `At Gare du Nord we read: The Clockmaker steals an hour.`(`m1.transition[2]`)
  - `The letter at the Louvre said: The clocks may lie.`(`m3.transition[3]`)
  - 에펠탑 명판 줄(`final.transition[2]`)
  - `Move the sun. Make the same shadow as in the photo.`(`m3.question` = 장면 task)
  - `Was the hour lost — or was the clock wrong?`(`final.question`, synopsis 셋째 줄)
- **Case 11**:
  - 문지른 글, Victor의 종이, 증거 이름 목록
  - `E.M. said, "Stop!"` / `Victor said, "Keep going."`(3쪽 인용)
  - Final 대화의 고백 세 줄과 `His old machine is at Arts et Métiers.`
- **Case 12**:
  - 이름표, PARIS, 기계 카드, 보드 질문
  - `The tag says: Made by Émile Moreau.`, 카드 단계 `Stop, turn, fix, start.`(`m3.hints[1]`, M3 대화 끝)
  - Big Ben 보관함 세 줄
  - `You said, "Stop the test!"`
  - 결말의 Victor 기록 줄과 사건 파일 세 줄
  - `The hour was never gone.`(hook, Final 첫 줄)
- **EasySteps**: 조작 안내 say(`Tap the big book.`, `Find Box 9.`, `Press STOP.`, `Question N. Look at the clue.` 등), YES/NO 질문, 3쪽 인용 힌트(`Page 3 says: The clocks are wrong!`, `E.M. said "Stop!" V.D. said "Keep going."`), 마지막 힌트 `Tap the book.`·`Tap the folder.`·`Press the big … button.`

## E. 결말·반전 보호 (세 난이도 모두 테스트)

| 위험 | 처리 |
|---|---|
| Clockmaker 공개 시점 | Case 12 M1 전체(대화 포함)와 M2의 정답 전 문장에 `Émile is/was the Clockmaker`·`Clockmaker is Émile`·`I am the Clockmaker`·`one and the same`이 없다. M2 성공 줄에서 처음 나온다 |
| 이름 공개 시점 | 시즌 전체 × 3난이도: Victor는 Case 11 전, Émile·Moreau는 Case 12 전에 없음 |
| V.D. = Victor | Case 11 M1 정답 전에 없음. 상자를 연 뒤 대화에서 밝힌다 |
| Victor 고백 시점 | `I hid the page`는 Case 11 M1~M3 어디에도 없고 Final 대화에서만 나온다 |
| 가방 운반자 | Victor의 `bag` 답에 "I carried"가 없다(미확정 유지) |
| 시간 소멸 부정 | Case 10 M1~M3와 Final 정답 전 문장에 `never lost / not lost / did not lose / lost no hour`가 없다 |
| Saint-Sulpice | Case 10 M1~M3와 Final 정답 전 문장에 없음. 목록 문장 `p.3 · SENT TO: …`는 구조로 보호한다 |
| Big Ben 보관함 | 바이블 v2.0의 세 줄을 그대로 둔다. 증거로 다루지 않는다(기준본과 같음) |
| 옳은 목적 ≠ 정당화 | q6 정답·오답 줄에 reason + OK/right, Émile 대사 끝에 wrong(테스트) |
| `THE RECORD WAS REMOVED` | 시즌 전체 어디에도 없다 |
| 결말 구조 | 결말 줄 수·화자·이름·초상·배경·증거 id가 같다(구조 + 테스트) |

## F. 구조 검사 (`season2_structures.dart`)

| 객체 | 보호하는 것 |
|---|---|
| `DrumTapeScene` | 드럼 그림·슬롯, 테이프 머리글, 표시 10개(id, 찍힌 시각, 실제 시각) |
| `CityClocksScene` | 사진 시계 4개(id·이름·위치·시험 여부·사진 1/2 시각·카드), 해시계 위치, 잘라낼 영역, Trial Map 증거 id, 정리 후 줄 수 |
| `ShadowCheckScene` | 해시계(시간선·각도·그림자 길이), 사진 2장(T1 시각·해 시각), 테두리 글 |
| `HourRecordScene` | 별의 방(명판·문 별·물건), 테이프, 사진 표시 위치, 쪽 4개(범위·책에 있음), 목록 문장, 정답 p3, Saint-Sulpice 지도 위치, 줄 수 |
| `TalkScene` | id, 화자(id·이름·숨긴 이름·공개 조건·초상), 첫 대사 묶음과 질문·제시 묶음의 **줄마다 화자/표정**, 질문 id·필요 조건·반복 여부, 제시 id·accepted·choices·requires·오답 키·정답 안내 유무, finishWhen, 장소, 배경, 끝 버튼, 정답, 이전 증거 |
| `TalkMission` | before/after 대화 구조 |
| `List<EndingLine>` | 줄마다 화자·이름·초상·배경·증거 id |

- 빌더: `_drum`·`_city`·`_shadow`·`_hour`·`_talk`(줄마다 `_say`가 화자와 표정을 복사)·`_mission`·`_ending`, 그리고 7B의 `retold`.
- EasySteps 패널은 같은 객체를 공유한다. `QuotePanel`(Émile·Victor의 말), `GearMarkPanel`, `RubPanel`, `MachinePanel`은 7B 구조 검사에 들어 있다.
- 결과: `problems()` 빈 목록. 두 난이도의 Case 10~12 표 항목 18개가 기준 구조와 같다. **시즌의 모든 표 항목이 두 난이도 변형에 들어 있다**(테스트).

## G. 학습 표현

부록 A의 `learning …` 행에 전체가 있다. 미션마다 세 난이도 묶음이 서로 다르다. 각 표현이 그 난이도 화면 문장에 있다(LearningCheck). 시즌 전체 36개 미션 × 3난이도를 모두 검사했다.

| 미션 | Rookie | Junior | Master |
|---|---|---|---|
| 10 M1 | Each one should be fifteen minutes after the last. / Where does the time jump? | Every time should be fifteen minutes after the one before it / Find the two places where the time jumps | Fifteen minutes should separate each time from the next / Where does the time leap? |
| 10 Final | (질문) / T1 was one hour behind, and the page about it is missing. | + Count how much later | + Measure the time between the two photos |
| 11 M2 | Were the clocks right? | Were the clocks right, or wrong? | Were the clocks really right? |
| 11 Final | Who hid the truth? | Who really hid the truth? | Who buried the truth? |
| 12 M2 | Who is the Clockmaker? | So who is the Clockmaker? | Who, then, is the Clockmaker? |
| 12 Final | Did Paris lose an hour? | + the hour was there | + the hour itself was never lost |

시즌 고정 난이도로 만든다. 프로필 난이도를 바꿔도 Case 12 보고서 표현은 시즌 난이도를 따른다(3난이도 테스트).

## H. 힌트 · Discovery

- **힌트**: 개수·가격·구매 기록은 그대로다. Case 10 M2의 힌트 1개 열람 기록이 3난이도에서 유지되는지 확인했다. 미션마다 힌트 묶음 3개가 모두 다르고, multipleChoice의 정답 라벨은 없다.
- **EasySteps 무료 힌트**: 개수는 같다. 마지막 힌트는 정답을 비추는 구조다(Rookie와 같은 조작 안내 유지).
- **Discovery**:
  - Case 10~12의 9개 미션 모두 세 난이도 제목이 다르다. 시즌 36개 미션 × 3난이도에서 제목은 그 난이도의 successMessage다.
  - 예외는 `s2_ep06_m1`이다. 바이블 문장이라 세 난이도가 같다(7B에서 기록).

## I. 화면 검증 (위젯 테스트, 실기기 아님)

| 테스트 | 크기 | 확인한 것 |
|---|---|---|
| Case 11 M1 × 3난이도 | 390×844 | 미션 story → INVESTIGATE → Victor의 첫 대사가 그 난이도 문장이고, 다른 난이도 문장이 없음. overflow·예외 없음 |
| Case 12 Final × 3난이도 | 390×844 | 보드 q1의 무료 힌트·오답 줄 → 6문항 정답과 각 done 줄 → **결말 첫 줄**이 그 난이도 문장. overflow·예외 없음 |
| Master, 글자 1.3배 | 360×640 | 대화 화면 / 보드 6문항 + 결말 |
| Master | 834×1194 | 보드 6문항 + 결말 |

- 7B(Case 04 Final)와 7C(Case 07 M1)의 화면 테스트를 더하면, 다음 화면 유형을 세 난이도·세 크기로 위젯 검사했다:
  - Story 화면, 대화 화면, 선택지, 무료 힌트, 오답 줄, Final, 결말.
- **확인하지 못한 것**:
  - 유료 힌트 BottomSheet(EasySteps가 아닌 장면 퍼즐의 힌트 바)는 화면에서 열어 보지 않았다.
  - Discovery 화면은 데이터(제목 = successMessage)로만 확인했다.
  - 장면 퍼즐(테이프·사진·해시계·Case 07~09 장면)의 긴 Master 문장도 화면에서 보지 않았다.

## J. 남은 위험

- **실기기 확인 없음.** 원어민·교사 검토도 없다.
- **기준 데이터 문제(수정하지 않음)**: `season2Learning['s2_ep10_m2']`가 의존도 exposure + 수준 comprehension이라 `isHonest` 규칙(노출이면 수준도 exposure)에 맞지 않는다. 이번 PART는 학습 설계의 의존도·수준을 바꾸지 않는 정책이라 그대로 두었다. 결정이 필요하다.
- **EasySteps의 YES/NO 질문은 세 난이도가 같다**(`Were the clocks right?` 등). 그래서 Junior·Master에서 JSON 질문(예: `Were the clocks right, or wrong?`)과 단계 화면의 질문 문장이 조금 다르다. 의미는 같다. 단계 질문까지 난이도별로 쓰려면 7B `StepWords`에 `question`을 더해야 한다.
- **도달 불가 옛 오답 줄**: 7B 36줄과 7C 15줄은 기준본 그대로다(지시대로 수정하지 않음).
- **기존 테스트 수정**: 7A·7B·7C 테스트의 "작성 완료 사건 = 정확히 …" 단언을 자기 사건 포함 확인으로 바꿨다. 시즌 전체 집합은 7D 테스트가 고정한다.

## K. 다음 작업 (London PART 6B 인수인계)

- Paris Season 2 난이도 콘텐츠는 완료됐다. London은 6A(Case 01~03)만 완료됐고 **6B~6D는 PENDING**이다.
- 6B(Case 04~06)를 시작할 때:
  - `docs/DIFFICULTY_IMPLEMENTATION.md` G의 London 항목을 읽는다. 특히 Case 06 `DialogueScene` 구조 검사를 먼저 추가해야 한다.
  - Paris에서 만든 패턴을 그대로 쓸 수 있다:
    - 테스트 방식 `keptAtEveryLevel` / `unreachable()`
    - 장면 빌더와 구조 검사를 먼저 만드는 순서
    - "최신 PART 테스트만 전체 집합을 고정" 규칙
    - 회상 오답 줄 패치 (London `recall` 데이터에 쓰이면)
  - London 콘텐츠는 이번 작업에서 수정하지 않았다.

---

## 부록 A. 전체 문장 표 (실제 적용 콘텐츠에서 자동 추출)

- 표기: `= Rookie`는 Rookie와 같은 문장, `= Junior`는 Junior와 같은 문장이다. `/`는 줄바꿈 또는 목록 구분이다.
- `scene …`은 장면, `talk …`은 대화(괄호 안은 화자), `ending[i]`은 결말, `steps …`은 EasySteps, `learning …`은 학습 표현 행이다.

### s2_ep10 — The Hour of Shadows

| 위치 | Rookie | Junior | Master |
|---|---|---|---|
| `intro` | The Arc de Triomphe. Twelve roads meet around it, like a star. / T1's little clock stood on top of an arch, with a star under it. / You climb the stairs to the top. / Under the roof, a small door has a star on it. / Inside: a brass drum, a box of photos, and a thick book. / A brass plate on the wall: TRIAL RECORDS · KEPT AT THE STAR. / In the garden, we tested a model. These records are from the real trial. / Let's read what T1 wrote. | The Arc de Triomphe. Twelve roads meet around it, like the points of a star. / T1's little model clock stood on top of an arch, with a star under it. / You climb all the stairs to the top. / Under the roof, there is a small door with a star on it. / Inside are a brass drum, a box of photos and a thick book. / A brass plate on the wall says: TRIAL RECORDS · KEPT AT THE STAR. / In the garden, we tested a model. These records come from the real trial. / Let's read what T1 printed. | The Arc de Triomphe, where twelve roads meet like the points of a star. / T1's little clock had stood on top of an arch, a star beneath it. / You climb the long stairway to the top. / Beneath the roof, a small door bears a star. / Inside wait a brass drum, a box of photos and a thick book. / On the wall, a brass plate reads: TRIAL RECORDS · KEPT AT THE STAR. / The garden held only a model. These records belong to the real trial. / Time to read what T1 recorded. |
| `synopsis` | A star under T1 pointed to the Arc de Triomphe. / The trial records may be kept there. / Was the hour lost — or was the clock wrong? | The star under T1 led you to the Arc de Triomphe. / The records of the trial may be kept there. / Was the hour lost — or was the clock wrong? | The star beneath T1 points to the Arc de Triomphe. / The trial records may be waiting there. / Was the hour lost — or was the clock wrong? |
| `objectives` | Read what T1 wrote. / Check the other clocks. / Ask the sun. | Read the times that T1 printed. / Compare T1 with the other clocks. / Check the time with the sun. | Read the record T1 left behind. / Test T1 against the clocks around it. / Let the sun be the judge. |
| `caseSummary` | The hour really passed: the sun and the café, church and post office clocks show it. T1 was one hour behind. Page 3 is missing. The list says it was sent to Saint-Sulpice. | The hour really passed: the sun and the café, church and post office clocks prove it. T1 was one hour behind, and page 3 is missing. The list says it was sent to Saint-Sulpice. | The hour truly passed, as the sun and the café, church and post office clocks prove. T1 ran an hour behind, page 3 is missing, and the list says it went to Saint-Sulpice. |
| `hook` | Who sent page 3 away — and why? | Who sent page 3 away? And why? | Who sent page 3 away, and for what reason? |
| `s2_ep10_m1.story` | The drum holds a paper tape. / T1 printed its time on it every fifteen minutes. | Inside the drum is a paper tape. / Every fifteen minutes, T1 printed its time on it. | A paper tape is wound inside the drum. / Every fifteen minutes, T1 stamped its time onto it. |
| `s2_ep10_m1.letterIntro` | On the tape: | At the top of the tape: | Printed at the head of the tape: |
| `s2_ep10_m1.letter` | T1 · DRUM TAPE · TRIAL DAY | = Rookie | = Rookie |
| `s2_ep10_m1.question` | Where does the time jump? Tap the two places. | Find the two places where the time jumps. Tap them. | Where does the time leap? Tap both places. |
| `s2_ep10_m1.hints[0]` | Each one should be fifteen minutes after the last. | Every time should be fifteen minutes after the one before it. | Fifteen minutes should separate each time from the next. |
| `s2_ep10_m1.hints[1]` | Look at what comes after each 2:45. | Check what comes right after each 2:45. | Watch what follows each 2:45. |
| `s2_ep10_m1.successMessage` | Two jumps! | You found both jumps! | Both jumps uncovered! |
| `s2_ep10_m1.transition[0]` | After 2:45, the tape goes back to 2:00. Then it jumps to 4:00. | After 2:45, the tape goes back to 2:00. Later it jumps to 4:00. | After 2:45, the tape falls back to 2:00, and later leaps to 4:00. |
| `s2_ep10_m1.transition[1]` | There is no three o'clock on the tape. | The tape never shows three o'clock. | Three o'clock never appears on the tape. |
| `s2_ep10_m1.transition[2]` | At Gare du Nord we read: The Clockmaker steals an hour. | = Rookie | = Rookie |
| `s2_ep10_m1.transition[3]` | Was an hour stolen? Or was T1 wrong? | So was an hour stolen, or was T1 wrong? | Was an hour stolen, or was T1 simply wrong? |
| `s2_ep10_m1.transition[4]` | Let's see what other clocks said. | Let's find out what the other clocks said. | Other clocks may tell a different story. |
| `s2_ep10_m1.clue.note` | T1's tape never shows three o'clock. | Three o'clock is never printed on T1's tape. | Not once does T1's tape show three o'clock. |
| `s2_ep10_m1.evidence.description` | The paper tape from the drum under T1. | The paper tape from the drum that sat under T1. | The paper tape drawn from the drum beneath T1. |
| `s2_ep10_m2.story` | ROOF PHOTOS · TRIAL DAY. Two old photos. / Photo 2 shows T1 on the roof, and the city behind it. | A box says ROOF PHOTOS · TRIAL DAY. Inside are two old photos. / Photo 2 shows T1 on the roof, with the city behind it. | ROOF PHOTOS · TRIAL DAY: a box holding two old photos. / Photo 2 captures T1 on the roof, the city spread out behind it. |
| `s2_ep10_m2.letterIntro` | On the back of Photo 2: | Written on the back of Photo 2: | On the reverse of Photo 2: |
| `s2_ep10_m2.letter` | T1 · ROOF · PHOTO 2 | = Rookie | = Rookie |
| `s2_ep10_m2.question` | Is it a trial clock? Find and sort the clocks. | Find the clocks in the photo. Is each one a trial clock? | Find every clock in the photo, then sort them: trial clock or not? |
| `s2_ep10_m2.hints[0]` | Move the glass over the photo. There are four clocks. | Move the magnifying glass over the photo. Look for four clocks. | Sweep the glass across the photo. Four clocks are hiding there. |
| `s2_ep10_m2.hints[1]` | Only T1 has the trial star. The other clocks are not trial clocks. | Only T1 has the trial star, so the other three are not trial clocks. | A trial clock carries the star. Which ones do not? |
| `s2_ep10_m2.successMessage` | They don't agree! | The clocks don't agree! | The clocks disagree by an hour! |
| `s2_ep10_m2.transition[0]` | The café, church and post office clocks agree. | The café clock, the church clock and the post office clock all agree. | The café, church and post office clocks all tell the same time. |
| `s2_ep10_m2.transition[1]` | T1 is one hour behind them. | But T1 is one hour behind them. | T1 lags one hour behind them. |
| `s2_ep10_m2.transition[2]` | What if all three were wrong? Is there a time no one can set? | What if those three were all wrong? Is there a time that nobody can set? | Yet what if all three were wrong? Is there any time no one can change? |
| `s2_ep10_m2.transition[3]` | Look! A sundial stands next to T1 in the photo. | Look! In the photo, a sundial stands next to T1. | Look closely: a sundial stands beside T1 in the photo. |
| `s2_ep10_m2.clue.note` | Three clocks that are not trial clocks all agree. | Three clocks that are not trial clocks all show the same time. | Three clocks outside the trial all agree with one another. |
| `s2_ep10_m2.evidence.description` | The clocks in Roof Photo 2, at one moment on the trial day. | The clocks in Roof Photo 2, all at one moment on the trial day. | The clocks of Roof Photo 2, caught at a single moment on the trial day. |
| `s2_ep10_m3.story` | On the roof, the old sundial is still here. / A sundial tells the time with the sun's shadow. | The old sundial is still here on the roof. / A sundial uses the shadow of the sun to tell the time. | Up on the roof, the old sundial still stands. / A sundial reads the hour from the shadow the sun casts. |
| `s2_ep10_m3.letterIntro` | Around the sundial: | Words are written around the sundial: | Around the rim of the sundial: |
| `s2_ep10_m3.letter` | I COUNT ONLY THE SUNNY HOURS. | = Rookie | = Rookie |
| `s2_ep10_m3.question` | Move the sun. Make the same shadow as in the photo. | = Rookie | = Rookie |
| `s2_ep10_m3.hints[0]` | Move the sun slowly. Watch the shadow turn and grow. | Move the sun slowly, and watch how the shadow turns and changes. | Guide the sun gently and watch the shadow swing and stretch. |
| `s2_ep10_m3.hints[1]` | In Photo 2, the shadow points between 3 and 4. | In Photo 2, the shadow points somewhere between 3 and 4. | In Photo 2, the shadow rests between 3 and 4. |
| `s2_ep10_m3.successMessage` | The sun knows! | The sun tells the truth! | The sun cannot lie! |
| `s2_ep10_m3.transition[0]` | Photo 1: T1 and the sun both said 2:00. | In Photo 1, T1 and the sun both said 2:00. | Photo 1: T1 and the sun agreed on 2:00. |
| `s2_ep10_m3.transition[1]` | Photo 2: T1 said 2:30. But the sun said 3:30! | In Photo 2, T1 said 2:30, but the sun said 3:30! | Photo 2: T1 claimed 2:30, while the sun showed 3:30! |
| `s2_ep10_m3.transition[2]` | No one can set the sun. | Nobody can set the sun. | No hand can turn the sun. |
| `s2_ep10_m3.transition[3]` | The letter at the Louvre said: The clocks may lie. | = Rookie | = Rookie |
| `s2_ep10_m3.transition[4]` | So where did the hour from three to four go? | Then where did the hour between three and four go? | Then what became of the hour between three and four? |
| `s2_ep10_m3.clue.note` | No one can set the sun. | Nobody can change the time of the sun. | The sun answers to no one. |
| `s2_ep10_m3.evidence.description` | The roof sundial in two old photos. | The sundial on the roof, in two old photos. | The rooftop sundial, as two old photos show it. |
| `s2_ep10_final.story` | You lay the tape on the table. Photo 1 is at the first 2:00. / Now find Photo 2 on the tape. | You lay the tape on the table. Photo 1 goes at the first 2:00. / Now find where Photo 2 belongs on the tape. | You spread the tape across the table, Photo 1 pinned at the first 2:00. / Where on the tape does Photo 2 belong? |
| `s2_ep10_final.letterIntro` | Your photos: | Your two photos say: | From your two photos: |
| `s2_ep10_final.letter` | PHOTO 1 · T1 2:00 · SUN 2:00 / PHOTO 2 · T1 2:30 · SUN 3:30 | = Rookie | = Rookie |
| `s2_ep10_final.question` | Was the hour lost — or was the clock wrong? | = Rookie | = Rookie |
| `s2_ep10_final.hints[0]` | Photo 2 was taken later than Photo 1. How much later? | Photo 2 was taken after Photo 1. Count how much later. | Measure the time between the two photos on the tape. |
| `s2_ep10_final.hints[1]` | Find the page for three to four. Is it in the book? | Look for the page about three to four. Is it in the book? | One page of the Trial Log should cover three to four. Is it there? |
| `s2_ep10_final.successMessage` | The hour was never lost! | The hour was not lost after all! | No hour was ever lost! |
| `s2_ep10_final.transition[0]` | Paris did not lose an hour. For one hour, T1 was wrong. | Paris never lost an hour. For one hour, T1 was simply wrong. | Paris lost no hour at all. For one hour, T1 was wrong. |
| `s2_ep10_final.transition[1]` | Were T2 and T3 wrong too? We can't tell. | Were T2 and T3 wrong too? We can't tell yet. | Did T2 and T3 go wrong too? That we cannot tell. |
| `s2_ep10_final.transition[2]` | At the Eiffel Tower, a time-recording machine hid a plaque: ONE HOUR IS MISSING. THE CLOCK IS STILL RUNNING. | = Rookie | = Rookie |
| `s2_ep10_final.transition[3]` | Was it about this hour? | Was the plaque about this hour? | Could the plaque have meant this very hour? |
| `s2_ep10_final.transition[4]` | The mystery continues at Saint-Sulpice! | Next, the mystery leads to Saint-Sulpice! | The trail now leads to Saint-Sulpice! |
| `s2_ep10_final.options[lost].feedback` | Look at the sun's line. Did the sun jump? | Look at the sun's times. Did the sun ever jump? | Follow the sun's line. Does the sun ever leap ahead? |
| `s2_ep10_final.options[all].feedback` | What did the café and church clocks say? | Check what the café and church clocks said. | Then why did the café and church clocks disagree with T1? |
| `s2_ep10_final.evidence.description` | T1's tape, laid beside the sun's time. | T1's tape, laid next to the sun's time. | T1's tape, set beside the time the sun kept. |
| `s2_ep10_m1 scene tape.startLine` | That's where the tape starts. | This is where the tape begins. | The tape begins here. |
| `s2_ep10_m1 scene tape.oneMore` | One jump! Find one more. | That is one jump! Now find the other one. | One jump found. Another is hiding. |
| `s2_ep10_m1 scene tape.found` | Two jumps! | You found both jumps! | Both jumps uncovered! |
| `learning s2_ep10_m1` | "Each one should be fifteen minutes after the last.", "Where does the time jump?" | "Every time should be fifteen minutes after the one before it", "Find the two places where the time jumps" | "Fifteen minutes should separate each time from the next", "Where does the time leap?" |
| `s2_ep10_m2 scene city.t1.wrongLine` | Look at the post under T1. What sign is there? | Check the post under T1. Which sign is on it? | What sign is on the post beneath T1? |
| `s2_ep10_m2 scene city.cafe.wrongLine` | Is there a star, three arches or a bell on it? Check your Trial Map. | Can you see a star, three arches or a bell on it? Look at your Trial Map. | Does it bear a star, three arches or a bell? Your Trial Map will tell. |
| `s2_ep10_m2 scene city.church.wrongLine` | Is there a star, three arches or a bell on it? Check your Trial Map. | Can you see a star, three arches or a bell on it? Look at your Trial Map. | Does it bear a star, three arches or a bell? Your Trial Map will tell. |
| `s2_ep10_m2 scene city.post.wrongLine` | Is there a star, three arches or a bell on it? Check your Trial Map. | Can you see a star, three arches or a bell on it? Look at your Trial Map. | Does it bear a star, three arches or a bell? Your Trial Map will tell. |
| `s2_ep10_m2 scene city.moreLine` | There are more clocks in the photo. | There are still more clocks in the photo. | More clocks are hiding in the photo. |
| `s2_ep10_m2 scene city.foundLine` | A clock! | You found a clock! | A clock, found! |
| `s2_ep10_m2 scene city.sortedLines` | T1 says 2:30. / The café, the church and the post office say 3:30. | T1 shows 2:30. / The café, the church and the post office all show 3:30. | T1 reads 2:30. / The café, the church and the post office all read 3:30. |
| `learning s2_ep10_m2` | "Is it a trial clock?", "The other clocks are not trial clocks." | "Is each one a trial clock?", "the other three are not trial clocks" | "trial clock or not?", "A trial clock carries the star" |
| `s2_ep10_m3 scene shadow.longer` | Not yet. The shadow in the photo is longer. | Not yet. In the photo, the shadow is longer. | Not quite: the photo's shadow is longer. |
| `s2_ep10_m3 scene shadow.shorter` | Not yet. The shadow in the photo is shorter. | Not yet. In the photo, the shadow is shorter. | Not quite: the photo's shadow is shorter. |
| `s2_ep10_m3 scene shadow.matchLine` | The same shadow! | It is the same shadow! | A perfect match of shadows! |
| `learning s2_ep10_m3` | "Make the same shadow as in the photo." | "Make the same shadow as in the photo.", "watch how the shadow turns" | "Make the same shadow as in the photo.", "watch the shadow swing and stretch" |
| `s2_ep10_final scene hour.firstTwoThirty` | This 2:30 is only half an hour after Photo 1. Photo 2 was later. | This 2:30 is just half an hour after Photo 1. Photo 2 was taken later. | This 2:30 comes only half an hour after Photo 1. Photo 2 is later still. |
| `s2_ep10_final scene hour.notTwoThirty` | T1 said 2:30 in Photo 2. Find a 2:30. | In Photo 2, T1 said 2:30. Find a 2:30 on the tape. | Photo 2 shows T1 at 2:30. Look for a 2:30. |
| `s2_ep10_final scene hour.foundLines` | Six marks of fifteen minutes: one and a half hours after Photo 1. / There it is: the hour from three to four! It was on the tape all along. / At three, T1 went one hour back. At four, it was right again. | Six marks of fifteen minutes: that is one and a half hours after Photo 1. / There it is: the hour from three to four! It was on the tape the whole time. / At three, T1 went back one hour. At four, it was right again. | Six marks of fifteen minutes: an hour and a half after Photo 1. / There it is, the hour from three to four, on the tape all along! / At three, T1 slipped an hour back; at four, it was right once more. |
| `s2_ep10_final scene hour.pageTask` | Which page tells about three to four? Is it in the book? | Which page should tell about three to four? Is it in the book? | Which page should cover three to four? Is it still in the book? |
| `s2_ep10_final scene hour.pageInBook` | That page is in the book. Turn the pages again. | That page is here in the book. Keep turning the pages. | That page is still in the book. Look further. |
| `s2_ep10_final scene hour.pageFoundLine` | Page 3 should tell about three to four. It is not in the book. | Page 3 should tell about three to four, but it is not in the book. | Page 3 ought to cover three to four, yet it is missing from the book. |
| `s2_ep10_final scene hour.afterLines` | In the garden, a model showed what could happen. This tape shows what happened to T1. / Time did not stop. T1 was wrong, and page 3 is missing. | In the garden, a model showed what could happen. This tape shows what really happened to T1. / Time never stopped. T1 was wrong, and page 3 is missing. | The garden model showed what might happen; this tape shows what did happen to T1. / Time never stood still. T1 was wrong, and page 3 is gone. |
| `s2_ep10_final scene list.question` | Where was page 3 sent? | Where was page 3 sent to? | Which place was page 3 sent to? |
| `s2_ep10_final scene list.otherLine` | That page is here, in the book. Find page 3. | That page is still in the book. Look for page 3. | That page never left the book. Find page 3. |
| `s2_ep10_final scene list.doneLines` | The list says page 3 was sent to Saint-Sulpice, north of the Luxembourg Gardens. / Is page 3 really there? Who sent it, and why? The list doesn't say. | The list says page 3 was sent to Saint-Sulpice, just north of the Luxembourg Gardens. / Is page 3 really there? Who sent it there, and why? The list doesn't tell us. | According to the list, page 3 went to Saint-Sulpice, north of the Luxembourg Gardens. / Is it truly there? Who sent it, and why? The list stays silent. |
| `learning s2_ep10_final` | "Was the hour lost — or was the clock wrong?", "T1 was one hour behind, and the page about it is missing." | "Was the hour lost — or was the clock wrong?", "T1 was one hour behind, and the page about it is missing.", "Count how much later" | "Was the hour lost — or was the clock wrong?", "T1 was one hour behind, and the page about it is missing.", "Measure the time between the two photos" |
| `glossary (추가된 단어)` | longer, passed, recorded, shorter, twelve | longer, magnifying, passed, recorded, shorter, simply, twelve | captures, lags, longer, magnifying, measure, passed, recorded, reverse, rooftop, separate, shorter, simply, stairway, stamped, stretch, twelve |

### s2_ep11 — The Unwritten Hour

| 위치 | Rookie | Junior | Master |
|---|---|---|---|
| `intro` | Saint-Sulpice. A quiet street. / A small door says: Archive Annex. / Inside, boxes go up to the ceiling. / A man is reading old papers. / Let's find page 3. | Saint-Sulpice. It is a quiet street. / A small door has a sign: Archive Annex. / Inside, boxes are piled up to the ceiling. / A man is reading some old papers. / Let's look for page 3. | Saint-Sulpice, and a quiet old street. / A small door bears a plate: Archive Annex. / Inside, boxes climb all the way to the ceiling. / A man sits reading old papers. / Time to find page 3. |
| `synopsis` | Page 3 was sent to Saint-Sulpice. / Is it really there? / Who hid it? | The list says page 3 was sent to Saint-Sulpice. / Is it really there now? / And who hid it? | According to the list, page 3 was sent to Saint-Sulpice. / Is it truly there? / And who hid it away? |
| `objectives` | Find page 3. / Find the wrong paper. / Find who signed it. | Find the missing page 3. / Find the paper that is not true. / Find out who signed the order. | Track down page 3. / Expose the paper that lies. / Discover whose name is signed. |
| `caseSummary` | You found page 3 in Box 9. It said the clocks were wrong. Victor's paper was not true. His name was under the order to hide the page. Victor hid the truth. | You found page 3 in Box 9, and it said the clocks were wrong. Victor's paper was not true, and his name was under the order to hide the page. Victor hid the truth. | Page 3 turned up in Box 9, proving the clocks were wrong. Victor's paper was false, and his name sat beneath the order to hide the page. Victor had hidden the truth. |
| `hook` | Who left the clues for me? | So who left the clues for me? | Then who left these clues for me? |
| `s2_ep11_m1.story` | Page 3 was sent here. / Every paper here is in the big book. | Page 3 was sent to this place. / Every paper here is written down in the big book. | Page 3 was sent here, to the annex. / Every paper in this room is listed in the big book. |
| `s2_ep11_m1.letterIntro` | Pressed into the big book: | Pressed into a page of the big book: | Pressed faintly into the big book: |
| `s2_ep11_m1.letter` | Page 3 is in Box 9. / Lock it. No one may read it. | = Rookie | = Rookie |
| `s2_ep11_m1.question` | Find page 3. | Where is page 3? Find it. | Track down page 3. |
| `s2_ep11_m1.hints[0]` | Rub the page with your finger. | Rub the empty page with your finger to see the words. | Rub the blank page: pressed words may appear. |
| `s2_ep11_m1.hints[1]` | Look at the numbers on the boxes. | Then read the numbers on the boxes. | Match the box numbers with the words you uncover. |
| `s2_ep11_m1.successMessage` | You found page 3! | Page 3 was in Box 9! | Page 3, found at last! |
| `s2_ep11_m1.transition[0]` | Page 3 was hidden in Box 9. | Someone hid page 3 in Box 9. | Page 3 had been hidden away in Box 9. |
| `s2_ep11_m1.transition[1]` | The clocks were wrong for one hour. | For one hour, the clocks were wrong. | For a whole hour, the clocks were wrong. |
| `s2_ep11_m1.transition[2]` | E.M. said, "Stop!" | = Rookie | = Rookie |
| `s2_ep11_m1.transition[3]` | Victor said, "Keep going." | = Rookie | = Rookie |
| `s2_ep11_m1.transition[4]` | Now, let's read Victor's paper. | Next, let's read Victor's paper. | Now for Victor's paper. |
| `s2_ep11_m1.clue.note` | "Lock it. No one may read it." And a name. | "Lock it. No one may read it." Under it, there is a name. | "Lock it. No one may read it." Beneath it, a name. |
| `s2_ep11_m1.evidence.description` | The missing page, found in Box 9. | The missing page, which was found in Box 9. | The missing page, recovered from Box 9. |
| `s2_ep11_m2.story` | Victor gives you his paper. / Is it true? | Victor hands you his paper. / But is it true? | Victor passes you his report. / Can it be trusted? |
| `s2_ep11_m2.letterIntro` | Victor's paper says: | Victor's paper reads: | Victor's report states: |
| `s2_ep11_m2.letter` | CLOCK TEST · V.D. / All the clocks were fine. | = Rookie | = Rookie |
| `s2_ep11_m2.question` | Were the clocks right? | Were the clocks right, or wrong? | Were the clocks really right? |
| `s2_ep11_m2.hints[0]` | Read page 3. | Read page 3 again. | Page 3 has something to say about that. |
| `s2_ep11_m2.hints[1]` | Look at the stamps. Are they the same? | Compare the two stamps. Are they the same? | Hold the two stamps side by side. |
| `s2_ep11_m2.successMessage` | Victor's paper is not true! | Victor's paper was not true! | Victor's report is false! |
| `s2_ep11_m2.transition[0]` | Victor's paper was not true. | Victor's paper did not tell the truth. | Victor's report was false. |
| `s2_ep11_m2.transition[1]` | His office changed papers too. | And his office changed papers as well. | His office had changed papers too. |
| `s2_ep11_m2.transition[2]` | But who hid page 3? | So who hid page 3? | Yet who hid page 3? |
| `s2_ep11_m2.transition[3]` | There was a name in the big book. | Remember: there was a name in the big book. | The big book held a name. |
| `s2_ep11_m2.clue.note` | His office changed papers. | His office changed papers too. | His office had altered papers. |
| `s2_ep11_m2.evidence.description` | Victor's paper about the clock test. | The paper Victor wrote about the clock test. | Victor's report on the clock test. |
| `s2_ep11_m3.story` | The big book had a name in it. / Victor signed the visitor book today. | There was a name pressed into the big book. / Today, Victor signed the visitor book. | A name was pressed into the big book. / And Victor signed the visitor book only today. |
| `s2_ep11_m3.letterIntro` | In the visitor book: | In the visitor book, you see: | The visitor book shows: |
| `s2_ep11_m3.letter` | Two names. One is the same. | There are two names. One of them is the same. | Two names. Only one matches. |
| `s2_ep11_m3.question` | Match the names. | Which name matches? | Find the matching name. |
| `s2_ep11_m3.hints[0]` | Look at the V, the line and the dot. | Compare the V, the line and the dot. | A curly V, a line and a dot: compare them carefully. |
| `s2_ep11_m3.hints[1]` | One name has a long line under it. | Only one name has a long line under it. | Look for the long line beneath one name. |
| `s2_ep11_m3.successMessage` | It's Victor's name! | The name is Victor's! | The name belongs to Victor! |
| `s2_ep11_m3.transition[0]` | Victor wrote, "Lock it. No one may read it." | Victor was the one who wrote, "Lock it. No one may read it." | It was Victor who wrote, "Lock it. No one may read it." |
| `s2_ep11_m3.transition[1]` | Then page 3 was hidden. | After that, page 3 was hidden. | And so page 3 was hidden away. |
| `s2_ep11_m3.transition[2]` | It's time to show him. | Now it's time to show him the clues. | Time to confront him. |
| `s2_ep11_m3.clue.note` | Victor signed the order to hide page 3. | Victor signed the order that hid page 3. | Victor put his name to the order hiding page 3. |
| `s2_ep11_m3.evidence.description` | The name pressed into the big book. | The name that was pressed into the big book. | The name left pressed in the big book. |
| `s2_ep11_final.story` | Victor is waiting at the long table. / Show him the truth. | Victor is waiting for you at the long table. / Show him what you found. | Victor waits at the long table. / Lay the truth before him. |
| `s2_ep11_final.letterIntro` | Your clues: | Your three clues: | The clues you carry: |
| `s2_ep11_final.letter` | PAGE 3 · VICTOR'S PAPER · VICTOR'S NAME | = Rookie | = Rookie |
| `s2_ep11_final.question` | Who hid the truth? | Who really hid the truth? | Who buried the truth? |
| `s2_ep11_final.hints[0]` | Show him one clue for each question. | For each question, show him one clue. | Each question needs its own clue. |
| `s2_ep11_final.hints[1]` | Page 3, then his paper, then his name. | First page 3, then his paper, then his name. | Begin with page 3, then his paper, and finally his name. |
| `s2_ep11_final.successMessage` | Victor hid the truth! | It was Victor who hid the truth! | Victor had hidden the truth! |
| `s2_ep11_final.transition[0]` | Victor hid the truth. | So Victor hid the truth. | Victor buried the truth. |
| `s2_ep11_final.transition[1]` | But who left the clues for me? | But then who left the clues for me? | Yet who left these clues for me? |
| `s2_ep11_final.transition[2]` | Victor said E.M. may know. | Victor said E.M. might know. | Victor believes E.M. may know. |
| `s2_ep11_final.transition[3]` | Let's find E.M. at Arts et Métiers! | Next, we will look for E.M. at Arts et Métiers! | The trail leads to Arts et Métiers, and to E.M.! |
| `s2_ep11_final.evidence.description` | What Victor said after you showed him the clues. | What Victor told you after you showed him the clues. | Victor's words, once the clues were laid before him. |
| `s2_ep11_m1 talk before.goal` | Find page 3. | Find the missing page 3. | Track down page 3. |
| `s2_ep11_m1 talk before.opening[0] (speaker)` | Welcome to the archive. | Welcome to the archive annex. | Ah, a visitor. Welcome to the archive. |
| `s2_ep11_m1 talk before.opening[1] (speaker)` | I am Victor Delacroix. | My name is Victor Delacroix. | Victor Delacroix, at your service. |
| `s2_ep11_m1 talk before.opening[2] (speaker)` | Long ago, I ran a clock test. | A long time ago, I was in charge of a clock test. | Many years ago, I ran a clock test. |
| `s2_ep11_m1 talk before.opening[3] (narrator)` | Victor signs the visitor book. | Victor writes his name in the visitor book. | Victor signs his name in the visitor book. |
| `s2_ep11_m1 talk before.opening[4] (detective)` | I'm looking for page 3. | I need to find page 3. | I am searching for page 3. |
| `s2_ep11_m1 talk before.opening[5] (speaker)` | Page 3? | = Rookie | Page 3...? |
| `s2_ep11_m1 talk before.opening[6] (speaker)` | I don't know where it is. | I don't know where that is. | I have no idea where it might be. |
| `s2_ep11_m1 talk before.opening[7] (speaker)` | Look in the big book, then. | You could look in the big book, then. | Try the big book, then. |
| `s2_ep11_m1 talk after.goal` | Find page 3. | Find the missing page 3. | Track down page 3. |
| `s2_ep11_m1 talk after.opening[0] (narrator)` | You show Victor page 3. | You show page 3 to Victor. | You lay page 3 before Victor. |
| `s2_ep11_m1 talk after.opening[1] (speaker)` | That box was locked! | But that box was locked! | That box was supposed to be locked! |
| `s2_ep11_m1 talk after.opening[2] (speaker)` | …All right. There was a page 3. | …Fine. Yes, there was a page 3. | …Very well. There was a page 3. |
| `s2_ep11_m1 talk after.opening[3] (detective)` | Who is V.D.? | Who is V.D., then? | And who is V.D.? |
| `s2_ep11_m1 talk after.opening[4] (speaker)` | V.D.… That is me. | V.D.… That's me. | V.D.… Those are my initials. |
| `s2_ep11_m1 talk after.opening[5] (detective)` | And E.M.? | And who is E.M.? | What about E.M.? |
| `s2_ep11_m1 talk after.opening[6] (speaker)` | E.M. worked on the machine. | E.M. worked on the test machine. | E.M. worked on the machine itself. |
| `s2_ep11_m1 talk after.opening[7] (speaker)` | Here. Read my paper. | Here, read my paper. | Here. Read my own paper. |
| `s2_ep11_m1 steps book.say` | Tap the big book. | = Rookie | = Rookie |
| `s2_ep11_m1 steps book.hints[0]` | The big book is in the middle. | The big book lies in the middle. | Look to the middle of the table. |
| `s2_ep11_m1 steps book.hints[1]` | Tap the book. | = Rookie | = Rookie |
| `s2_ep11_m1 steps rub.say` | A page is torn out! Rub the next page. | One page is torn out! Rub the page after it. | A page has been torn out! Rub the one beneath it. |
| `s2_ep11_m1 steps rub.hints[0]` | Rub the top of the right page. | Rub the top part of the right page. | The words wait at the top of the right page. |
| `s2_ep11_m1 steps rub.hints[1]` | Move your finger. Or tap it a few times. | Move your finger, or tap it a few times. | = Junior |
| `s2_ep11_m1 steps rub.done` | Page 3 is in Box 9! And a name. | Page 3 is in Box 9! And there is a name. | Page 3 is in Box 9, and a name appears! |
| `s2_ep11_m1 steps box.say` | Find Box 9. | = Rookie | = Rookie |
| `s2_ep11_m1 steps box.hints[0]` | Look at the numbers on the boxes. | Read the number on each box. | Each box wears a number. |
| `s2_ep11_m1 steps box.hints[1]` | Box 9 is on the right. | Box 9 is the one on the right. | Box 9 sits on the right. |
| `s2_ep11_m1 steps box.option 3` | That is Box 3. Find 9. | That one is Box 3. Look for 9. | Box 3. You want 9. |
| `s2_ep11_m1 steps box.option 12` | That is Box 12. Find 9. | That one is Box 12. Look for 9. | Box 12. You want 9. |
| `s2_ep11_m1 steps box.tell` | Box 9 is on the right. Tap it. | Box 9 is the one on the right. Tap it. | It is the box on the right. Tap it. |
| `s2_ep11_m1 steps open.say` | Box 9 is open. Tap the folder. | Box 9 is open now. Tap the folder. | Box 9 stands open. Tap the folder. |
| `s2_ep11_m1 steps open.hints[0]` | The folder is inside the box. | Look for the folder inside the box. | A folder lies inside. |
| `s2_ep11_m1 steps open.hints[1]` | Tap the folder. | = Rookie | = Rookie |
| `s2_ep11_m1 steps page.say` | You found page 3! Read it. | Here is page 3! Read it. | Page 3 at last! Read it. |
| `s2_ep11_m1 steps page.hints[0]` | The clocks were wrong. | It says the clocks were wrong. | Read the first line: the clocks. |
| `s2_ep11_m1 steps page.hints[1]` | E.M. said "Stop!" V.D. said "Keep going." | = Rookie | = Rookie |
| `learning s2_ep11_m1` | "Page 3 is in Box 9." | "Page 3 is in Box 9.", "Where is page 3?" | "Page 3 is in Box 9.", "Track down page 3" |
| `s2_ep11_m2 talk before.goal` | Find the wrong paper. | Find the paper that is not true. | Expose the paper that lies. |
| `s2_ep11_m2 talk before.opening[0] (speaker)` | Here is my paper. | This is my paper. | Here is my report. |
| `s2_ep11_m2 talk before.opening[1] (speaker)` | It tells the real story. | It tells what really happened. | It tells the true story. |
| `s2_ep11_m2 talk before.opening[2] (speaker)` | My office never changed any papers. | My office has never changed a single paper. | My office never altered a single paper. |
| `s2_ep11_m2 talk after.goal` | Find the wrong paper. | Find the paper that is not true. | Expose the paper that lies. |
| `s2_ep11_m2 talk after.opening[0] (speaker)` | All right. My paper was wrong. | Fine. My paper was wrong. | Very well. My paper was wrong. |
| `s2_ep11_m2 talk after.opening[1] (speaker)` | But I did not hide page 3! | But I didn't hide page 3! | But I never hid page 3! |
| `s2_ep11_m2 talk after.opening[2] (speaker)` | Anyone in my office could do that. | Anyone in my office could have done that. | Anyone in my office could have done it. |
| `s2_ep11_m2 steps clocks.say` | Look at the two papers. | = Rookie | = Rookie |
| `s2_ep11_m2 steps clocks.hints[0]` | Read page 3. | Read what page 3 says. | Page 3 has something to say about that. |
| `s2_ep11_m2 steps clocks.hints[1]` | Page 3 says: The clocks are wrong! | = Rookie | = Rookie |
| `s2_ep11_m2 steps clocks.option yes` | Read page 3 again. | Read page 3 one more time. | Page 3 says otherwise. |
| `s2_ep11_m2 steps clocks.tell` | Page 3 says the clocks were wrong. Tap NO. | Page 3 says the clocks were wrong, so tap NO. | Page 3 tells us the clocks were wrong. Tap NO. |
| `s2_ep11_m2 steps clocks.done` | Victor's paper is not true! | Victor's paper was not true! | Victor's report is false! |
| `s2_ep11_m2 steps stamps.say` | Look at the two stamps. | = Rookie | = Rookie |
| `s2_ep11_m2 steps stamps.hints[0]` | Look at the clock in each stamp. | Look closely at the clock in each stamp. | Compare the little clocks inside the stamps. |
| `s2_ep11_m2 steps stamps.hints[1]` | Both clocks have no hands. | Neither clock has any hands. | Neither clock has hands. |
| `s2_ep11_m2 steps stamps.option no` | Look again: a clock with no hands, in leaves. | Look again: both show a clock with no hands, in leaves. | Look again. Each has a handless clock in a ring of leaves. |
| `s2_ep11_m2 steps stamps.tell` | They are the same stamp. Tap YES. | It is the same stamp, so tap YES. | The stamps match. Tap YES. |
| `s2_ep11_m2 steps stamps.done` | The same stamp! His office changed the opera paper. | It's the same stamp! His office changed the opera paper. | The very same stamp! His office altered the opera paper. |
| `learning s2_ep11_m2` | "Were the clocks right?" | "Were the clocks right, or wrong?" | "Were the clocks really right?" |
| `s2_ep11_m3 steps names.say` | Look at the names in the visitor book. | Look at the two names in the visitor book. | Study the names in the visitor book. |
| `s2_ep11_m3 steps names.hints[0]` | There are two names. | The book has two names. | Two names share the page. |
| `s2_ep11_m3 steps names.hints[1]` | Victor signed it today. | One was signed by Victor today. | Victor signed it only today. |
| `s2_ep11_m3 steps match.say` | Which name is the same? | Which name matches the big book? | Which signature matches the rubbing? |
| `s2_ep11_m3 steps match.hints[0]` | Look at the V, the line and the dot. | Compare the V, the line and the dot. | A curly V, a line and a dot: compare them carefully. |
| `s2_ep11_m3 steps match.hints[1]` | One name has a long line under it. | Only one name has a long line under it. | Look for the long line beneath one name. |
| `s2_ep11_m3 steps match.option old` | Look: no long line, no dot. | Look again: there is no long line and no dot. | No long line and no dot: not a match. |
| `s2_ep11_m3 steps match.tell` | The curly V, the long line, the dot: it is Victor's name! | It has the curly V, the long line and the dot. It is Victor's name! | Curly V, long line, dot: the name is Victor's! |
| `s2_ep11_m3 steps match.done` | It's Victor's name! Victor signed it. | The name is Victor's! He signed it. | The name belongs to Victor. He signed the order. |
| `learning s2_ep11_m3` | "Match the names." | "Which name matches?" | "Find the matching name" |
| `s2_ep11_final talk.goal` | Show Victor the truth. | Show Victor what really happened. | Lay the truth before Victor. |
| `s2_ep11_final talk.opening[0] (narrator)` | Victor is waiting at the long table. | Victor sits waiting at the long table. | At the long table, Victor is waiting. |
| `s2_ep11_final talk.opening[1] (detective)` | Victor, I found three clues. | Victor, I have found three clues. | Victor, I have three clues for you. |
| `s2_ep11_final talk.opening[2] (speaker)` | Clues? Show me. | Clues? Then show me. | Clues? Go on, show me. |
| `s2_ep11_final talk.q bag` | What about the office bag? | And what about the office bag? | And the bag from your office? |
| `s2_ep11_final talk.q bag[0] (speaker)` | That's one of our office bags. | That is one of our office bags. | That bag belongs to my office. |
| `s2_ep11_final talk.q bag[1] (speaker)` | It took page 3 here. | It carried page 3 here. | It carried page 3 to this annex. |
| `s2_ep11_final talk.q bag[2] (speaker)` | I wanted the tests to stop. | I wanted all the tests to stop. | I wanted the tests brought to an end. |
| `s2_ep11_final talk.q clues` | Then who left the clues for me? | Then who left all the clues for me? | Then who has been leaving clues for me? |
| `s2_ep11_final talk.q clues[0] (speaker)` | Not me. I changed no clocks. | It was not me. I did not change any clocks. | Not I. I never touched a clock. |
| `s2_ep11_final talk.q clues[1] (speaker)` | Maybe E.M. knows. | Perhaps E.M. knows. | E.M. may have the answer. |
| `s2_ep11_final talk.q clues[2] (speaker)` | His old machine is at Arts et Métiers. | = Rookie | = Rookie |
| `s2_ep11_final talk.show three.prompt` | What happened at three? Show him. | What happened at three o'clock? Show him. | What happened at three? Show him the proof. |
| `s2_ep11_final talk.show three[0] (speaker)` | The clocks went wrong. | The clocks... went wrong. | The clocks were wrong. Yes. |
| `s2_ep11_final talk.show three.miss` | That doesn't show the clocks. | That doesn't tell us about the clocks. | That says nothing about the clocks. |
| `s2_ep11_final talk.show three.tell` | Show Page 3. It says the clocks were wrong. | Show Page 3. It says that the clocks were wrong. | Show Page 3: it records the clocks going wrong. |
| `s2_ep11_final talk.show paper.prompt` | Whose paper was not true? Show him. | Whose paper did not tell the truth? Show him. | Whose paper was false? Show him. |
| `s2_ep11_final talk.show paper[0] (speaker)` | …Mine. | …It was mine. | …My own. |
| `s2_ep11_final talk.show paper.miss` | That paper is not mine. | That paper isn't mine. | That paper did not come from me. |
| `s2_ep11_final talk.show paper.tell` | Show Victor's Paper. It said the clocks were fine. | Show Victor's Paper. It said all the clocks were fine. | Show Victor's Paper: it claimed the clocks were fine. |
| `s2_ep11_final talk.show name.prompt` | Who signed the order to hide it? Show him. | Who signed the order to hide the page? Show him. | Whose name is on the order to hide it? Show him. |
| `s2_ep11_final talk.show name[0] (speaker)` | …I did. | …It was me. | …I signed it. |
| `s2_ep11_final talk.show name[1] (speaker)` | Yes. I hid the page. | = Rookie | = Rookie |
| `s2_ep11_final talk.show name[2] (detective)` | Why? | But why? | Why would you do that? |
| `s2_ep11_final talk.show name[3] (speaker)` | The test was my job. | I was in charge of the test. | The test was my responsibility. |
| `s2_ep11_final talk.show name[4] (speaker)` | The clocks went wrong. | And the clocks went wrong. | And it failed: the clocks went wrong. |
| `s2_ep11_final talk.show name[5] (speaker)` | I was afraid. | = Rookie | = Rookie |
| `s2_ep11_final talk.show name[6] (speaker)` | I didn't want people to know. | = Rookie | = Rookie |
| `s2_ep11_final talk.show name[7] (detective)` | But the truth matters. | But the truth is important. | But people deserve the truth. |
| `s2_ep11_final talk.show name[8] (speaker)` | I know. I am sorry. | I know. I am truly sorry. | I know. I am deeply sorry. |
| `s2_ep11_final talk.show name.miss` | There's no name on that. | There isn't a name on that. | No name appears on that. |
| `s2_ep11_final talk.show name.tell` | Show Victor's Name. It was in the big book. | Show Victor's Name. It was pressed into the big book. | Show Victor's Name, from the big book. |
| `learning s2_ep11_final` | "Who hid the truth?" | "Who really hid the truth?" | "Who buried the truth?" |
| `glossary (추가된 단어)` | anyone, ceiling, folder | anyone, ceiling, charge, folder, important, neither, piled | anyone, buried, ceiling, charge, confront, deserve, expose, faintly, folder, handless, important, initials, neither, piled, responsibility |

### s2_ep12 — The Clockmaker's Truth

| 위치 | Rookie | Junior | Master |
|---|---|---|---|
| `intro` | Arts et Métiers. A museum of old machines. / In a quiet room, a big machine ticks. / Its three little clocks are one hour behind! / Someone is standing by the machine. | Arts et Métiers. It is a museum full of old machines. / In a quiet room, a big machine is ticking. / Look: its three little clocks are one hour behind! / Someone is standing next to the machine. | Arts et Métiers, a museum of old machines. / In a hushed room, a great machine ticks on. / All three of its little clocks are an hour behind! / Someone stands beside the machine. |
| `synopsis` | E.M.'s old machine is here. / Who left the clues? | E.M.'s old machine is kept here. / But who left the clues? | E.M.'s old machine waits here. / And who has been leaving the clues? |
| `objectives` | Find his name. / Find the Clockmaker. / Fix the old machine. | Find out his full name. / Find out who the Clockmaker is. / Make the old machine work right. | Uncover his name. / Unmask the Clockmaker. / Repair the old machine. |
| `caseSummary` | You found Émile's name on an old wheel. The same wheel was in the Clockmaker's watch, and Émile's tool made the Clockmaker's mark. Émile was the Clockmaker. He left clues so the truth would be found, but he scared people. You fixed the machine and closed the case. | You found Émile's name on an old wheel. The same wheel was inside the Clockmaker's watch, and Émile's tool made the Clockmaker's mark. So Émile was the Clockmaker. He left clues so the truth would be found, but he scared people. You fixed the machine and closed the case. | Émile's name was on an old wheel. That same wheel sat inside the Clockmaker's watch, and Émile's tool made the Clockmaker's mark: Émile was the Clockmaker. He left clues so the truth would come out, but he frightened people along the way. You repaired the machine and closed the case. |
| `hook` | The hour was never gone. | = Rookie | = Rookie |
| `s2_ep12_m1.story` | The machine has a little door. / Wheels are inside. | There is a little door in the machine. / Behind it are some wheels. | A little door is set into the machine. / Brass wheels wait inside. |
| `s2_ep12_m1.letterIntro` | On a little tag: | There is a little tag: | A little tag reads: |
| `s2_ep12_m1.letter` | Made by Émile Moreau | = Rookie | = Rookie |
| `s2_ep12_m1.question` | Find the same wheel. | Which wheel is the same as Clock III's? | Find the wheel that matches Clock III's. |
| `s2_ep12_m1.hints[0]` | Count the spokes. | Count the spokes on each wheel. | The spokes tell wheels apart. |
| `s2_ep12_m1.hints[1]` | Look at the size too. | Check the size as well. | Size matters too. |
| `s2_ep12_m1.successMessage` | E.M. is Émile Moreau! | E.M. stands for Émile Moreau! | E.M. means Émile Moreau! |
| `s2_ep12_m1.transition[0]` | The tag says: Made by Émile Moreau. | = Rookie | = Rookie |
| `s2_ep12_m1.transition[1]` | E.M. is Émile Moreau! | So E.M. is Émile Moreau! | E.M. was Émile Moreau all along! |
| `s2_ep12_m1.transition[2]` | He made the same wheel for Clock III. | He also made the same wheel for Clock III. | He made the very same wheel for Clock III. |
| `s2_ep12_m1.transition[3]` | But who is the Clockmaker? | But who is the Clockmaker, then? | Yet who is the Clockmaker? |
| `s2_ep12_m1.clue.note` | He made Clock III's small wheel. | He made the small wheel in Clock III. | The small wheel in Clock III is his work. |
| `s2_ep12_m1.evidence.description` | A tag on a wheel inside the old machine. | A tag tied to a wheel inside the old machine. | A tag fixed to a wheel within the old machine. |
| `s2_ep12_m2.story` | You still have the Clockmaker's watch. / You found it in London. | You still have the Clockmaker's pocket watch. / You found it back in London. | The Clockmaker's watch is still in your pocket. / It has been with you since London. |
| `s2_ep12_m2.letterIntro` | On the back of the watch: | Engraved on the back of the watch: | On the watch's back, one word: |
| `s2_ep12_m2.letter` | PARIS | = Rookie | = Rookie |
| `s2_ep12_m2.question` | Who is the Clockmaker? | So who is the Clockmaker? | Who, then, is the Clockmaker? |
| `s2_ep12_m2.hints[0]` | Open the watch. Then try the stamp. | First open the watch. Then try the stamp. | Look inside the watch, then use the stamp. |
| `s2_ep12_m2.hints[1]` | Are the marks the same? | Compare the two marks. Are they the same? | Do the two marks agree? |
| `s2_ep12_m2.successMessage` | Émile is the Clockmaker! | Émile Moreau is the Clockmaker! | The Clockmaker is Émile! |
| `s2_ep12_m2.transition[0]` | Émile is the Clockmaker. | So Émile is the Clockmaker. | Émile and the Clockmaker are one and the same. |
| `s2_ep12_m2.transition[1]` | He wanted people to find page 3. | He wanted people to discover page 3. | He wanted page 3 to be found. |
| `s2_ep12_m2.transition[2]` | But he scared people. That was wrong. | But he scared people, and that was wrong. | But he frightened people, and that was wrong. |
| `s2_ep12_m2.transition[3]` | And the old machine is still wrong. | And the old machine is still not right. | Meanwhile, the old machine is still wrong. |
| `s2_ep12_m2.clue.note` | The wheel, the watch and the mark lead to one man. | The wheel, the watch and the mark all lead to one man. | Wheel, watch and mark all point to a single man. |
| `s2_ep12_m2.evidence.description` | Émile's tool, and the watch from London. | Émile's stamping tool, and the watch from London. | Émile's tool, beside the watch from London. |
| `s2_ep12_m3.story` | The old machine is still wrong. / Its clocks are one hour behind. | The old machine is still not right. / Its three clocks are one hour behind. | The old machine still runs wrong. / All its clocks lag an hour behind. |
| `s2_ep12_m3.letterIntro` | A card on the machine: | There is a card on the machine: | A card is fixed to the machine: |
| `s2_ep12_m3.letter` | HOW TO FIX THE MACHINE / 1. Stop. 2. Turn. 3. Fix. 4. Start. | = Rookie | = Rookie |
| `s2_ep12_m3.question` | Fix the old machine. | Fix the old machine, step by step. | Repair the old machine. |
| `s2_ep12_m3.hints[0]` | Do the steps in order. | Follow the steps in order. | The card lists four steps. Follow them in order. |
| `s2_ep12_m3.hints[1]` | Stop, turn, fix, start. | = Rookie | = Rookie |
| `s2_ep12_m3.successMessage` | You fixed the machine! | The machine is fixed! | The machine runs true again! |
| `s2_ep12_m3.transition[0]` | The old machine is right at last. | At last, the old machine is right. | At long last, the old machine keeps true time. |
| `s2_ep12_m3.transition[1]` | All its clocks agree. | All of its clocks agree now. | Every one of its clocks agrees. |
| `s2_ep12_m3.transition[2]` | Now, let's put the case together. | Now let's put the whole case together. | Time to piece the whole case together. |
| `s2_ep12_m3.clue.note` | Only this machine was fixed. | Only this one machine was fixed. | This machine alone was put right. |
| `s2_ep12_m3.evidence.description` | The old test machine, fixed at last. | The old test machine, finally fixed. | The old test machine, set right at last. |
| `s2_ep12_final.story` | Six questions. One at a time. / Your clues will help. | There are six questions. Answer them one at a time. / Your clues will help you. | Six questions await, one at a time. / Let your clues guide you. |
| `s2_ep12_final.letterIntro` | The case board: | The case board asks: | The case board begins: |
| `s2_ep12_final.letter` | Did Paris lose an hour? | = Rookie | = Rookie |
| `s2_ep12_final.question` | Did Paris lose an hour? | = Rookie | = Rookie |
| `s2_ep12_final.hints[0]` | Look at the clue for each question. | Each question comes with a clue. Look at it. | Read each clue before you answer. |
| `s2_ep12_final.hints[1]` | The clocks were wrong. The hour was there. | The clocks were wrong, but the hour was there. | The clocks erred; the hour itself was never lost. |
| `s2_ep12_final.successMessage` | You solved the case! | You solved the whole case! | The case is solved at last! |
| `s2_ep12_final.transition[0]` | The hour was never gone. | = Rookie | = Rookie |
| `s2_ep12_final.transition[1]` | The truth was waiting to be found. | The truth was just waiting for someone to find it. | All along, the truth was waiting to be found. |
| `s2_ep12_final.evidence.description` | The whole case, in four lines. | The whole case, told in four lines. | The entire case, in four lines. |
| `s2_ep12_m1 talk before.goal` | Who is he? | Who is this man? | Who is the stranger? |
| `s2_ep12_m1 talk before.opening[0] (detective)` | Someone is here. | Someone is in here. | There is someone here. |
| `s2_ep12_m1 talk before.opening[1] (speaker)` | You found me. | So, you found me. | Ah. You have found me. |
| `s2_ep12_m1 talk before.opening[2] (detective)` | Who are you? | = Rookie | = Rookie |
| `s2_ep12_m1 talk before.opening[3] (speaker)` | Don't ask me. | Don't ask me that. | My words will not help you. |
| `s2_ep12_m1 talk before.opening[4] (speaker)` | Find out with clues. | Use the clues to find out. | Let the clues tell you. |
| `s2_ep12_m1 talk after.goal` | Who is he? | Who is this man? | Who is the stranger? |
| `s2_ep12_m1 talk after.opening[0] (detective)` | Émile made this wheel! | = Rookie | This wheel is Émile's work! |
| `s2_ep12_m1 talk after.opening[1] (detective)` | Émile Moreau… E.M.! | Émile Moreau… so he is E.M.! | = Rookie |
| `s2_ep12_m1 talk after.opening[2] (speaker)` | You are getting close. | You are getting closer. | You are close now. Very close. |
| `s2_ep12_m1 steps wheel.say` | Look at this wheel. Find the same one. | Look at this wheel. Which one is the same? | Study this wheel. Which one matches it? |
| `s2_ep12_m1 steps wheel.hints[0]` | Count the spokes. | Count the spokes on each wheel. | The spokes tell wheels apart. |
| `s2_ep12_m1 steps wheel.hints[1]` | Clock III's wheel has 4 spokes, like an X. | Clock III's wheel has 4 spokes that make an X. | Clock III's wheel has four spokes, crossed like an X. |
| `s2_ep12_m1 steps wheel.option six` | Count the spokes. Wheel A has 6. | Count the spokes. Wheel A has six. | Wheel A has six spokes. Count again. |
| `s2_ep12_m1 steps wheel.tell` | Wheel B has 4 spokes, like an X. Tap B. | Wheel B has 4 spokes, like an X. Tap Wheel B. | Wheel B has four spokes in an X. Tap B. |
| `s2_ep12_m1 steps wheel.done` | The same wheel! A tag is on it. | It's the same wheel! There is a tag on it. | A perfect match, and a tag hangs from it. |
| `s2_ep12_m1 steps tag.say` | Émile Moreau made this wheel! | This wheel was made by Émile Moreau! | The maker of this wheel: Émile Moreau! |
| `s2_ep12_m1 steps tag.hints[0]` | Read the tag. | Read what the tag says. | The tag names the maker. |
| `s2_ep12_m1 steps tag.hints[1]` | E.M. is Émile Moreau. | E.M. stands for Émile Moreau. | E.M. means Émile Moreau. |
| `learning s2_ep12_m1` | "Find the same wheel." | "Which wheel is the same as Clock III's?" | "Find the wheel that matches Clock III's" |
| `s2_ep12_m2 talk before.goal` | Find the Clockmaker. | Find out who the Clockmaker is. | Unmask the Clockmaker. |
| `s2_ep12_m2 talk before.opening[0] (narrator)` | He turns around. | The man turns around. | Slowly, he turns to face you. |
| `s2_ep12_m2 talk before.opening[1] (speaker)` | Hello, detective. | Hello there, detective. | Good day, detective. |
| `s2_ep12_m2 talk before.opening[2] (speaker)` | You have the Clockmaker's watch. | You still have the Clockmaker's watch. | I see you carry the Clockmaker's watch. |
| `s2_ep12_m2 talk before.opening[3] (speaker)` | Open it. | Go on, open it. | = Rookie |
| `s2_ep12_m2 talk before.opening[4] (speaker)` | Don't trust my words. Trust clues. | Don't trust what I say. Trust the clues. | Do not trust my words. Trust the clues. |
| `s2_ep12_m2 talk after.goal` | Why did he leave the clues? | Find out why he left the clues. | Learn why he left the clues. |
| `s2_ep12_m2 talk after.opening[0] (detective)` | You made this wheel. | = Rookie | This wheel is your work. |
| `s2_ep12_m2 talk after.opening[1] (speaker)` | Yes, I did. | Yes. I made it. | It is. |
| `s2_ep12_m2 talk after.opening[2] (detective)` | It is in the Clockmaker's watch. | And it is inside the Clockmaker's watch. | And it sits inside the Clockmaker's watch. |
| `s2_ep12_m2 talk after.opening[3] (speaker)` | That's right. | That is right. | Correct. |
| `s2_ep12_m2 talk after.opening[4] (detective)` | And your stamp makes his mark. | = Rookie | = Rookie |
| `s2_ep12_m2 talk after.opening[5] (speaker)` | You found it. | So you found it. | You have found it, then. |
| `s2_ep12_m2 talk after.q clockmaker` | Are you the Clockmaker? | So are you the Clockmaker? | Is it you? Are you the Clockmaker? |
| `s2_ep12_m2 talk after.q clockmaker[0] (speaker)` | Yes. I am. | Yes. I am the Clockmaker. | = Rookie |
| `s2_ep12_m2 talk after.q clockmaker[1] (speaker)` | I am Émile Moreau. | My name is Émile Moreau. | I am Émile Moreau, the Clockmaker. |
| `s2_ep12_m2 talk after.q clockmaker[2] (detective)` | You said, "Stop the test!" | = Rookie | You were the one who said, "Stop the test!" |
| `s2_ep12_m2 talk after.q clockmaker[3] (speaker)` | I did. Nobody listened. | I did. But nobody listened. | I did. No one would listen. |
| `s2_ep12_m2 talk after.q why` | Why did you do it? | Why did you do all of this? | What made you do it? |
| `s2_ep12_m2 talk after.q why[0] (speaker)` | I wanted people to look. | I wanted people to start looking. | I wanted people to search. |
| `s2_ep12_m2 talk after.q why[1] (detective)` | Look for what? | Looking for what? | Search for what? |
| `s2_ep12_m2 talk after.q why[2] (speaker)` | The missing page. | For the missing page. | For the page that went missing. |
| `s2_ep12_m2 talk after.q why[3] (detective)` | But you scared people. | = Rookie | But you frightened people. |
| `s2_ep12_m2 talk after.q why[4] (speaker)` | I know. I was wrong. | = Rookie | I know. I was wrong to do that. |
| `s2_ep12_m2 talk after.q bigBen` | And Big Ben? | And what about Big Ben? | And Big Ben? What was that for? |
| `s2_ep12_m2 talk after.q bigBen[0] (speaker)` | I tried to stop Big Ben. | I tried to make Big Ben stop. | I tried to bring Big Ben to a halt. |
| `s2_ep12_m2 talk after.q bigBen[1] (speaker)` | A secret box is under it. | = Rookie | = Rookie |
| `s2_ep12_m2 talk after.q bigBen[2] (speaker)` | Inside is a list of hidden papers. | = Rookie | = Rookie |
| `s2_ep12_m2 talk after.q bigBen[3] (speaker)` | It opens only if Big Ben stops. | = Rookie | = Rookie |
| `s2_ep12_m2 talk after.q bigBen[4] (detective)` | But I stopped you. | But I stopped your plan. | But I stopped you in London. |
| `s2_ep12_m2 talk after.q bigBen[5] (speaker)` | Yes. It never opened. | Yes. The box never opened. | You did. The box stayed shut. |
| `s2_ep12_m2 talk after.q clues` | Why did you leave clues for me? | Why did you leave the clues for me? | Why leave the clues for me? |
| `s2_ep12_m2 talk after.q clues[0] (speaker)` | You stopped me with clues. | You stopped me by using clues. | You stopped me with clues alone. |
| `s2_ep12_m2 talk after.q clues[1] (speaker)` | People trust clues. | People believe clues. | People trust clues more than words. |
| `s2_ep12_m2 talk after.q clues[2] (speaker)` | I hoped you'd find the page. | I hoped you would find the page. | = Junior |
| `s2_ep12_m2 talk after.q clues[3] (speaker)` | But I set clocks wrong in Paris too. | But I also set clocks wrong here in Paris. | But I set clocks wrong here in Paris, too. |
| `s2_ep12_m2 talk after.q clues[4] (speaker)` | People were confused. That was wrong. | People were confused, and that was wrong. | I confused people. That was wrong. |
| `s2_ep12_m2 steps open.say` | Tap to open the watch. | = Rookie | = Rookie |
| `s2_ep12_m2 steps open.hints[0]` | Tap the watch. | Tap the pocket watch. | Open it with a tap. |
| `s2_ep12_m2 steps open.hints[1]` | Tap anywhere on the watch. | You can tap anywhere on the watch. | = Rookie |
| `s2_ep12_m2 steps wheel.say` | Tap the wheel in the watch. | = Rookie | = Rookie |
| `s2_ep12_m2 steps wheel.hints[0]` | Look for 4 spokes, like an X. | Look for a wheel with 4 spokes, like an X. | Search for four spokes crossed like an X. |
| `s2_ep12_m2 steps wheel.hints[1]` | It is on the right, inside the watch. | It is on the right side, inside the watch. | It sits on the right, inside the watch. |
| `s2_ep12_m2 steps wheel.done` | Look! The same wheel! But anyone can use a wheel. | Look! It is the same wheel! But anyone could use a wheel like this. | The same wheel! Still, anyone might use such a wheel. |
| `s2_ep12_m2 steps stamp.say` | Tap the stamp. | = Rookie | = Rookie |
| `s2_ep12_m2 steps stamp.hints[0]` | It is Émile's little stamp. | This is Émile's little stamp. | Émile's little stamp waits beside the paper. |
| `s2_ep12_m2 steps stamp.hints[1]` | Tap the stamp. It makes a mark. | Tap the stamp to make a mark. | = Rookie |
| `s2_ep12_m2 steps stamp.done` | A mark! Look at it. | It made a mark! Look at it. | A mark appears. Examine it. |
| `s2_ep12_m2 steps marks.say` | Look at the two marks. | = Rookie | = Rookie |
| `s2_ep12_m2 steps marks.hints[0]` | Count the teeth. | Count the teeth on both gears. | The teeth will tell you. |
| `s2_ep12_m2 steps marks.hints[1]` | Both gears have 8 teeth. | Each gear has 8 teeth. | Each gear has eight teeth. |
| `s2_ep12_m2 steps marks.option no` | Count the teeth on each gear. | Count the teeth on each gear again. | Count the teeth of each gear once more. |
| `s2_ep12_m2 steps marks.tell` | Both have 8 teeth. They are the same. Tap YES. | Both gears have 8 teeth, so they are the same. Tap YES. | Eight teeth each: the marks match. Tap YES. |
| `s2_ep12_m2 steps marks.done` | The same mark! Eight teeth. | It is the same mark, with eight teeth! | An identical mark, eight teeth and all. |
| `s2_ep12_m2 steps who.say` | Look at your three clues. | Look at all three of your clues. | Consider your three clues. |
| `s2_ep12_m2 steps who.hints[0]` | Whose stamp made the mark? | Think: whose stamp made the mark? | Whose stamp left that mark? |
| `s2_ep12_m2 steps who.hints[1]` | Émile made the wheel and the stamp. | Émile made both the wheel and the stamp. | The wheel and the stamp are both Émile's. |
| `s2_ep12_m2 steps who.option victor` | Whose stamp made the mark? | Think: whose stamp made the mark? | Whose stamp left that mark? |
| `s2_ep12_m2 steps who.tell` | Émile's stamp makes the Clockmaker's mark. Tap Émile. | Émile's stamp makes the Clockmaker's mark, so tap Émile. | The Clockmaker's mark comes from Émile's stamp. Tap Émile. |
| `s2_ep12_m2 steps who.done` | Émile is the Clockmaker! | Émile Moreau is the Clockmaker! | The Clockmaker is Émile! |
| `learning s2_ep12_m2` | "Who is the Clockmaker?" | "So who is the Clockmaker?" | "Who, then, is the Clockmaker?" |
| `s2_ep12_m3 talk before.goal` | Fix the old machine. | Make the old machine right again. | Repair the old machine. |
| `s2_ep12_m3 talk before.opening[0] (detective)` | Why is the machine still wrong? | Why is the machine still not right? | Why does the machine still run wrong? |
| `s2_ep12_m3 talk before.opening[1] (speaker)` | On the test day, I stopped it. | On the day of the test, I stopped it. | On the day of the test, I brought it to a stop. |
| `s2_ep12_m3 talk before.opening[2] (speaker)` | Then Victor stopped all the tests. | After that, Victor stopped all the tests. | Then Victor ended every test. |
| `s2_ep12_m3 talk before.opening[3] (speaker)` | Nobody fixed the machine. | So nobody ever fixed the machine. | No one ever repaired it. |
| `s2_ep12_m3 talk before.opening[4] (detective)` | Can I fix it? | Can I fix it now? | Could I fix it? |
| `s2_ep12_m3 talk before.opening[5] (speaker)` | Yes. Stop, turn, fix, start. | = Rookie | You could. Stop, turn, fix, start. |
| `s2_ep12_m3 talk after.goal` | Fix the old machine. | Make the old machine right again. | Repair the old machine. |
| `s2_ep12_m3 talk after.opening[0] (speaker)` | It's right at last. | At last, it is right. | At long last, it keeps true time. |
| `s2_ep12_m3 talk after.opening[1] (speaker)` | Thank you, detective. | = Rookie | I am grateful, detective. |
| `s2_ep12_m3 steps stop.say` | Press STOP. | = Rookie | = Rookie |
| `s2_ep12_m3 steps stop.hints[0]` | Step 1: stop the machine. | Step 1 is to stop the machine. | First, the machine must stop. |
| `s2_ep12_m3 steps stop.hints[1]` | Press the big STOP button. | = Rookie | = Rookie |
| `s2_ep12_m3 steps turn.say` | Tap the big wheel. | = Rookie | = Rookie |
| `s2_ep12_m3 steps turn.hints[0]` | Step 2: turn the wheel. | Step 2 is to turn the wheel. | Next, the wheel must turn. |
| `s2_ep12_m3 steps turn.hints[1]` | The big wheel is at the top. | The big wheel is at the top of the machine. | The big wheel sits at the top. |
| `s2_ep12_m3 steps pin.say` | The clocks say 11:20! Tap the pin. | Now the clocks say 11:20! Tap the pin. | The clocks read 11:20! Now tap the pin. |
| `s2_ep12_m3 steps pin.hints[0]` | Step 3: the pin holds the wheel. | Step 3: the pin keeps the wheel in place. | Third, the pin locks the wheel in place. |
| `s2_ep12_m3 steps pin.hints[1]` | The pin is left of the wheel. | The pin is on the left of the wheel. | Look just left of the wheel. |
| `s2_ep12_m3 steps start.say` | Press START. | = Rookie | = Rookie |
| `s2_ep12_m3 steps start.hints[0]` | Step 4: start the machine. | Step 4 is to start the machine again. | Finally, set the machine running. |
| `s2_ep12_m3 steps start.hints[1]` | Press the big START button. | = Rookie | = Rookie |
| `s2_ep12_m3 steps start.done` | All the clocks agree! You fixed the machine! | Every clock agrees now! The machine is fixed! | Every clock agrees! The machine runs true again! |
| `learning s2_ep12_m3` | "Fix the old machine." | "Fix the old machine, step by step" | "Repair the old machine" |
| `s2_ep12_final ending[0] (narrator)` | Victor's words are in the case file. | Victor's words are kept in the case file. | Victor's own words now rest in the case file. |
| `s2_ep12_final ending[1] (speaker VICTOR'S RECORD)` | Yes. I hid the page. | = Rookie | = Rookie |
| `s2_ep12_final ending[2] (speaker ÉMILE MOREAU)` | And I made bad choices. | And I made bad choices too. | And I made choices I regret. |
| `s2_ep12_final ending[3] (speaker ÉMILE MOREAU)` | I scared people. I'm sorry. | I scared people, and I'm sorry. | I frightened people. I am sorry for that. |
| `s2_ep12_final ending[4] (speaker ÉMILE MOREAU)` | I will tell everyone what I did. | I will tell everyone the truth about what I did. | I will tell everyone what I have done. |
| `s2_ep12_final ending[5] (detective)` | The clocks were wrong. | = Rookie | = Rookie |
| `s2_ep12_final ending[6] (detective)` | Victor hid the truth. | = Rookie | = Rookie |
| `s2_ep12_final ending[7] (detective)` | Émile left the clues. | = Rookie | = Rookie |
| `s2_ep12_final ending[8] (detective)` | But now everyone can know. | But now everyone can know the truth. | But now the whole city can know. |
| `s2_ep12_final ending[9] (narrator)` | Page 3 goes into a glass case. | Page 3 is placed in a glass case. | Page 3 is laid in a glass case. |
| `s2_ep12_final ending[10] (narrator)` | No one can hide it again. | Nobody can ever hide it again. | No one will ever hide it again. |
| `s2_ep12_final steps q1.say` | Question 1. Look at the clue. | = Rookie | = Rookie |
| `s2_ep12_final steps q1.hints[0]` | The sun showed the hour. | The sun showed that the hour passed. | The sun kept the hour. |
| `s2_ep12_final steps q1.hints[1]` | The hour was there. The clocks were wrong. | The hour was there; only the clocks were wrong. | The hour passed; the clocks simply showed it wrong. |
| `s2_ep12_final steps q1.option yes` | Did the sun lose an hour? | Think about the sun. Did it lose an hour? | The sun lost no hour. Did Paris? |
| `s2_ep12_final steps q1.tell` | The hour was there. Tap NO. | The hour was really there. Tap NO. | No hour was lost. Tap NO. |
| `s2_ep12_final steps q1.done` | No. The clocks were wrong. | No. Only the clocks were wrong. | No. It was the clocks that were wrong. |
| `s2_ep12_final steps q2.say` | Question 2. Look at page 3. | = Rookie | = Rookie |
| `s2_ep12_final steps q2.hints[0]` | Read page 3. | Read what page 3 says. | Page 3 holds the answer. |
| `s2_ep12_final steps q2.hints[1]` | Page 3 says: The clocks are wrong! | = Rookie | = Rookie |
| `s2_ep12_final steps q2.option no` | Read the first line of page 3. | Read the first line of page 3 again. | Page 3 begins with the answer. |
| `s2_ep12_final steps q2.tell` | Page 3 says the clocks are wrong. Tap YES. | Page 3 says the clocks are wrong, so tap YES. | Page 3 records that the clocks were wrong. Tap YES. |
| `s2_ep12_final steps q2.done` | Yes. Page 3 says so. | Yes. Page 3 says so in writing. | Yes. Page 3 proves it. |
| `s2_ep12_final steps q3.say` | Question 3. Look at the name. | = Rookie | = Rookie |
| `s2_ep12_final steps q3.hints[0]` | Whose name was in the big book? | Think: whose name was in the big book? | Remember the name in the big book. |
| `s2_ep12_final steps q3.hints[1]` | It was the same as in the visitor book. | It matched the name in the visitor book. | It matched a signature in the visitor book. |
| `s2_ep12_final steps q3.option emile` | Whose name was in the big book? | Think: whose name was in the big book? | Remember the name in the big book. |
| `s2_ep12_final steps q3.tell` | It is Victor's name. Tap Victor. | The name is Victor's. Tap Victor. | The name belonged to Victor. Tap Victor. |
| `s2_ep12_final steps q3.done` | Victor hid it. | Victor was the one who hid it. | Victor hid it away. |
| `s2_ep12_final steps q4.say` | Question 4. Look at the mark. | = Rookie | = Rookie |
| `s2_ep12_final steps q4.hints[0]` | Whose stamp made the mark? | Think: whose stamp made the mark? | Whose stamp left that mark? |
| `s2_ep12_final steps q4.hints[1]` | Émile's stamp made it. | It was made by Émile's stamp. | The mark came from Émile's stamp. |
| `s2_ep12_final steps q4.option victor` | Whose stamp made the mark? | Think: whose stamp made the mark? | Whose stamp left that mark? |
| `s2_ep12_final steps q4.tell` | Émile's stamp made the mark. Tap Émile. | The mark was made by Émile's stamp. Tap Émile. | Émile's stamp left the mark. Tap Émile. |
| `s2_ep12_final steps q4.done` | Émile is the Clockmaker. | So Émile is the Clockmaker. | Émile was the Clockmaker. |
| `s2_ep12_final steps q5.say` | Question 5. Read what Émile said. | = Rookie | = Rookie |
| `s2_ep12_final steps q5.hints[0]` | Read what Émile said. | Read Émile's words again. | Émile's own words hold the answer. |
| `s2_ep12_final steps q5.hints[1]` | He wanted people to find page 3. | He hoped people would find page 3. | He wanted page 3 to be found. |
| `s2_ep12_final steps q5.option hide` | He wanted people to find the page. | No. He wanted people to find the page. | He hoped the page would be found, not hidden. |
| `s2_ep12_final steps q5.tell` | He wanted the page found. Tap: To show the truth. | He wanted people to find the page. Tap: To show the truth. | He wanted page 3 found. Tap: To show the truth. |
| `s2_ep12_final steps q5.done` | To show the truth. | He left clues to show the truth. | His clues were meant to reveal the truth. |
| `s2_ep12_final steps q6.say` | Question 6. Read what Émile said. | = Rookie | = Rookie |
| `s2_ep12_final steps q6.hints[0]` | Read what Émile said. | Read Émile's words again. | Émile's own words hold the answer. |
| `s2_ep12_final steps q6.hints[1]` | He said: I was wrong. | He said that he was wrong. | He admitted: I was wrong. |
| `s2_ep12_final steps q6.option yes` | A good reason does not make it OK. | Having a good reason does not make it OK. | Even a good reason cannot make that right. |
| `s2_ep12_final steps q6.tell` | Émile said he was wrong. Tap NO. | Émile said himself that he was wrong. Tap NO. | Émile admitted he was wrong. Tap NO. |
| `s2_ep12_final steps q6.done` | No. He made bad choices. | No. Those were bad choices. | No. His choices were wrong. |
| `learning s2_ep12_final` | "Did Paris lose an hour?" | "Did Paris lose an hour?", "the hour was there" | "Did Paris lose an hour?", "the hour itself was never lost" |
| `glossary (추가된 단어)` | button, choices, confused, workbench | button, choices, confused, discover, engraved, stamping, ticking, workbench | admitted, button, choices, confused, discover, engraved, erred, frightened, grateful, halt, hushed, meanwhile, regret, stamping, ticking, unmask, workbench |

## 부록 B. 재현 방법

- 원본은 `lib/data/mock/season2/season2_levels_10_12.dart`이고, `season2_difficulty.dart`에 연결돼 있다.
- 부록 A와 §D 통계는 `DifficultyContent.episodeAt`·`SeasonCatalog`의 실제 적용 결과에서 뽑았다. 위치 체계는 테스트의 `fields()`와 같다.
- 개발자 모드에서 확인하려면: Game Master → START DEVELOPER MODE → TEST LEVEL → Paris Case 10~12.
