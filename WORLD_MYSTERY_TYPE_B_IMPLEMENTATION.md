# World Mystery — TYPE B Implementation

> 진행 상태: P0, 대표 Case(01·05·12), XP 규칙 3 + 탐정 행동 배지(§6), Phase 2(§8), 3A(§9), 3B(§10), **Phase 4 P1-1·P1-2·P1-3·P1-4(§11) 구현 완료**. P2 보류. 모두 2026-10-12 사용자 승인 범위.
> Case 콘텐츠는 **승인된 Case 01·05·12만** 수정했다(콘텐츠 해시 테스트로 다른 9개 사건 불변 확인). **50개 퍼즐의 정답은 하나도 바뀌지 않았다.** 게임 규칙(진행 순서, 잠금 해제, 무벌점·무제한 재시도)도 그대로다.
> Git commit 하지 않음.

---

## 1. 기준선 확인 (감사 보고서 대조)

| 항목 | 감사 보고서 | 현재 코드 확인 |
|---|---|---|
| HEAD | `52f24c0` | 동일 (감사 이후 소스 변경 없음) |
| 퍼즐 수 | 50 (일반 38 + Final 12) | 50 — `learning_objectives_test`로 고정 |
| 영어 형태 핵심 / 독해 논리 / 키워드·그림·기호 | 5 / 29 / 16 (감사 축) | 감사 축의 수치는 데이터 변경이 없으므로 유효. TYPE B 설계는 다른 축(essential 32 / helpful 13 / low 5)을 쓴다 — 설계 문서 §3-2 |
| 테스트 | 779 통과 | 작업 전 779 통과 확인 |
| 부모 보고서 별점·코멘트 문제 | `detective_report.dart:47-65, 142-170` | 확인 |
| 찍기 > 힌트 인센티브 | `scoring.dart` | 확인 |
| **추가 발견** | — | XP는 저장값이 아니라 매번 계산된다. 규칙만 바꾸면 기존 세이브의 XP가 소급 변경된다 → §2-2의 규칙 버전 기록으로 해결 |

---

## 2. 구현 내용 (P0)

### 2-1. P0-C 학습 목표 데이터화

| 파일 | 변경 |
|---|---|
| `lib/data/models/learning.dart` (신규) | `LearningLevel`(exposure / comprehension / application / recall), `LanguageDependency`(essential / helpful / exposure / low), `LanguageSkill`(vocabulary / sentenceMeaning / grammarInContext), `LearningObjective`, `CaseLanguageTopic` |
| `lib/data/mock/season1/season1_learning.dart` (신규) | 50개 미션 전부의 학습 설계 + 12개 사건 언어 주제. `learningOf(m)`, `languageTopicOf(id)` |
| `lib/data/models/mission.dart` | `Skill` enum 주석만 변경(더 이상 부모에게 보여 주지 않는 레거시 태그) |

- **Case 콘텐츠 JSON은 변경하지 않았다.** `season1_discoveries.dart`와 같은 별도 매핑 파일 방식 → 기존 콘텐츠 해시 테스트(`final_small_pass_test`)와 승인 전 콘텐츠 수정 금지 조건을 모두 지킨다.
- 구현 필드 6개(objective, skill, expressions, dependency, level, recallFrom). reasoningSkill·evidenceUsage는 화면 사용처가 없어 보류, feedbackStrategy는 Phase 3에서 결정(설계 문서 §2-3).
- **학습 목표와 성취의 분리:** 학습 설계는 콘텐츠이며 `GameProgress`에 저장되지 않는다.

### 2-2. P0-B XP / Badge

| 파일 | 변경 |
|---|---|
| `lib/features/game/scoring.dart` | `XpBreakdown`에 규칙 2 추가: 기본 XP 동일, 힌트 무료, Careful Answer 보너스(첫 시도 +50 / 두 번째 +25 / 이후 0), 속도 보너스 없음. 규칙 1은 기록이 없는 미션에 그대로 적용. Sharp Eyes = 첫 시도 해결(힌트 무관), Quick Thinker = 첫 시도 + 빠름. 배지 설명 3개 수정 |
| `lib/core/constants/app_constants.dart` | `firstTryBonusXp`, `secondTryBonusXp` 추가 (규칙 1 상수 유지) |
| `lib/data/models/game_progress.dart` | `xpRules`(미션 → 규칙 번호) 추가. JSON에는 비어 있지 않을 때만 기록 |
| `lib/features/game/game_controller.dart` | 정답 순간 `xpRules[mission] = 2` 기록 |
| `lib/features/mission/widgets/answer_feedback.dart` | 힌트 안내 "A tip uses a little of your bonus XP." → "Tips are free. Good detectives use them." |

요구사항 대응:

| 요구 | 결과 |
|---|---|
| 1. 기본 XP 동일 | 일반 100 / Final 200, 어떤 경우에도 감소 없음 |
| 2. 오답 처벌·진행 차단 없음 | 추가 없음. 오답은 보너스 조건에만 쓰임 |
| 3. 힌트 ≠ 실패 | 힌트는 XP·배지에 영향 없음. 두 힌트를 모두 보고 첫 시도에 맞히면 최대 XP |
| 4. 오답 없음 ≠ 영어 실력 | Careful Answer는 게임 보상일 뿐, 부모 보고서에 영어 지표로 쓰지 않음 |
| 5. 학습 능력 암시 배지 | Letter Reader 설명 "비밀 편지 해독" → "비밀 편지 사건 해결"(조건은 원래 사건 완료). Sharp Eyes·Quick Thinker는 찍기로 얻을 수 없게 변경 |
| 6. 소급 변경 금지 | 미션별 규칙 기록. 기록 없는 미션 = 규칙 1 → 기존 세이브 XP 불변(테스트). 이미 받은 배지(`badgeIds`)는 그대로 |
| 7. 재플레이 중복 방지 | 구조상 사건별 저장 하나뿐이고 시즌 누적 XP가 없다. Play again은 그 사건 기록을 대체 → 같은 사건을 두 번 해도 XP·배지는 한 번 분량(테스트) |

**알려 둘 점:** 이미 진행 중인 사건이라면 이 업데이트 이후에 푸는 미션부터 규칙 2가 적용되어, 한 사건 안에 두 규칙이 섞일 수 있다. 이미 받은 XP는 바뀌지 않는다.

### 2-3. P0-A Parent Report

| 파일 | 변경 |
|---|---|
| `lib/features/result/detective_report.dart` | 별점(`skillStars`)·정답률(`accuracyPercent`) 제거. `MissionPerformance.recorded`(시도 기록 존재 여부), `hasPlayRecord`, `elapsed`(알 수 없으면 null), `wordsLookedUp`(목록), `lookupsRecorded`, `languageTopic`, `englishEssentialCount`. 코멘트는 관찰 사실만 |
| `lib/features/result/parent_report_screen.dart` | 섹션 구성: **English in This Case**(사건 언어 주제 + 미션별 학습 설계, "측정 결과가 아님" 명시) → **Words Checked**(실제 찾아본 단어 + 뜻) → **Play Record**(해결 미션, 열어 본 힌트, 첫 시도 해결 n/기록된 m, 플레이 시간) + 미션별 기록 → Game Master's Note |
| `lib/data/models/game_progress.dart` | `lookupsRecorded`: 단어 목록이 없던 세이브는 false, 저장 후에도 false 유지 |
| `lib/features/result/case_solved_screen.dart` | 아이용 사건 파일: 기록이 없으면 Hints·Time을 "—"로 |

"기록 없음" 처리:

| 상황 | 표시 |
|---|---|
| 단어 목록이 없던 세이브 | "기록 없음 (단어 기록 이전에 저장된 데이터)" |
| 시도 기록 없는 해결 미션 (플레이테스트 도구 "CASE NN부터", 매우 오래된 세이브) | 미션 행 "기록 없음", 첫 시도 수에서 제외 |
| 사건 전체에 시도 기록 없음 | 힌트·첫 시도·플레이 시간 "기록 없음", 코멘트 "플레이 기록 없이 해결된 것으로 저장" |

제거한 문구(예): "읽기 능력이 돋보였어요", "핵심 단어를 잘 알아보고 활용했어요", "논리적 사고력이 돋보였어요", 아이용 "You did it without a single hint!" → 첫 시도 또는 "You looked again and never gave up!"

---

## 3. 기존 기능 영향

| 영역 | 영향 |
|---|---|
| 진행·잠금·저장·로드 | 없음. 저장 필드 2개 추가(관대한 파싱, 기본값 있음). 기존 키·형식 유지 |
| Operator / Playtest 모드 | 코드 변경 없음. 플레이테스트 도구가 만든 "해결" 사건은 이제 보고서에서 "기록 없음"으로 정직하게 표시 |
| Discovery·Story·지도·아트·애니메이션 | 없음 (Discovery의 XP 숫자만 규칙 2 값) |
| Notebook·Archive | 없음 (XP 표시값만 규칙 2) |
| 배지 | 이미 받은 배지 유지. 앞으로 Sharp Eyes·Quick Thinker는 첫 시도 조건 |

---

## 4. 테스트 결과

- `flutter analyze`: **No issues found**
- `flutter test`: **기준 779 → P0 후 799 → 대표 Case 후 815, 전부 통과** (최종 실행 2026-10-12)

P0 단계:

| 테스트 | 변경 | 이유 |
|---|---|---|
| `test/learning_objectives_test.dart` (신규, 7) | 50개 매핑, 12개 주제, 표현이 실제 콘텐츠에 있는지, recall 출처가 앞 미션인지, 정직성 규칙, 기호·이름표 퍼즐은 Exposure, 분포 32/13/5 | P0-C |
| `test/type_b_p0_test.dart` (신규, 13) | 기존 세이브 XP 불변, 단어 기록 없음 유지, xpRules 저장·로드, 읽기+힌트 > 찍기, 힌트가 XP를 낮추지 않음, 재플레이 비누적, 부모 보고서 단정 문구 없음, 플레이 없이 해결된 사건 "기록 없음", 360×640·390×844 렌더 | P0-A/B |
| `test/game_controller_test.dart` | 2개 테스트 기대값 변경 + 1개 단정 교체 | **의도된 규칙 변경**: "힌트가 보너스를 줄인다", "+20 속도 보너스"는 규칙 1의 동작이었다. 규칙 2 동작으로 다시 썼다. 백그라운드 시간 제외 테스트는 XP 대신 Quick Thinker로 확인 |
| `test/detective_report_test.dart` | 별점·정답률 단정 제거, XP 기대값은 **그대로**(규칙 1 세이브 → 소급 불변 확인) | 별점 기능 제거 |
| `test/remaining_screens_test.dart` | 지표 라벨 `Accuracy`·`Completion Time`·`Words Checked` → 새 라벨, "기록 없음" 확인 추가 | 지표 재정의. 이 테스트의 진행은 시도 기록이 없는 세이브라 "기록 없음"이 정답 |

대표 Case 단계:

| 테스트 | 변경 | 이유 |
|---|---|---|
| `test/type_b_cases_test.dart` (신규, 16) | 오답 피드백이 정답 보기·정답 입력에 붙지 않음, 피드백·힌트가 정답을 말하지 않음(전 시즌), 한 줄 길이, Case 01·05·12 개별 동작, 05·12 Final 기호 없음·01 Final 기호 유지, 오답 시트 2 크기 렌더 | Phase 3 |
| `test/learning_objectives_test.dart` | 분포 32/13/5 → 37/10/3, 기호 자물쇠 = Exposure 규칙 추가 | 학습 설계 갱신 |
| `test/final_small_pass_test.dart` | 콘텐츠 해시 ep01·ep05·ep12 갱신 | 이 테스트의 설계 그대로 "의도적으로 바꾼 사건은 해시 갱신". 나머지 9개 사건 해시는 그대로 통과 → 의도하지 않은 변경 없음 |
| `test/full_playthrough_test.dart`, `test/ui_tour_test.dart` | 01-M1 보기 라벨, 01-M4 그림 의미 라벨 `Picture C`(이름 숨김), Get a tip 확인 전 스크롤, **오답 한 줄 표시 확인 추가** | 승인된 콘텐츠 변경 |
| `test/letter_notebook_slip_test.dart` | Get a tip 확인 전 스크롤 | 01-M1 보기가 길어져 360×640에서 링크가 스크롤 아래로 감 (§5-6 참고) |
| `test/new_artwork_test.dart` | "이름 있는 랜드마크" 예시를 01-M4 → 04-M3으로, 01-M4는 "이름 없음" 쪽으로 | 승인된 이름 숨김 |

기대값을 바꾼 테스트는 모두 **의도적으로 바뀐 동작**을 단정하던 것들이다. 실패 원인을 숨기려고 바꾼 기대값은 없다.

### 화면 검증
- 자동: 부모 보고서(`type_b_p0_test`, `remaining_screens_test`), 오답 시트(`type_b_cases_test`), 그림 선택(`new_artwork_test`), 전 미션 레이아웃(`season_screens_test`)이 **360×640·390×844**에서 예외 없이 렌더.
- 스크린샷 확인(`LM_SCREENSHOTS`, `LM_TOUR_SMALL`): 01-M1 퍼즐(보기 4개 + CHECK ANSWER가 360×640 한 화면), 오답 시트의 진단 한 줄, 01-M4 이름 없는 그림, 부모 보고서. 테스트 환경에는 한글 글꼴이 없어 한국어가 빈칸으로 찍힌다(이전과 동일, 레이아웃 문제 아님). 실기기 확인은 하지 않았다.

---

## 5. Phase 3 — 대표 Case 개선 (**2026-10-12 승인 → 구현 완료**)

아래 5-0~5-5는 승인받은 제안 원문이다. 실제 구현과의 차이는 **5-6**에 적었다.

대상: **Case 01**(첫 경험), **Case 05**(영어 지시문 → 실제 행동), **Case 12**(이전 사건 영어 재사용).
Case 07은 4개 미션이 모두 이미 essential이라 개선 효과가 작아 Case 05를 골랐다.

### 5-0. 공통 코드 변경 (승인 시)
| 변경 | 파일 | 내용 |
|---|---|---|
| 보기별 오답 피드백 | `mission.dart`(`ChoiceOption.feedback`), `answer_feedback.dart`(`showTryAgainSheet`), `mission_screen.dart`, `final_mission_screen.dart` | 선택형 보기에 선택적 한 줄. "Not quite!" 제목은 유지하고, 아래 일반 문구 자리에 표시. 없으면 기존 문구 |
| 입력형 오답 피드백 | `mission.dart`(`Mission.feedback` 맵, `Mission.orderFeedback`) | 특정 오답(정규화 비교)별 한 줄, **같은 글자·숫자를 순서만 틀린 경우** 한 줄 |
| 그림 이름표 숨김 | `mission.dart`(`hideOptionNames`), `question_widgets.dart` | 미션별로 랜드마크 이름표를 숨김(지금은 공원 지도만 숨김) |
| Final 자물쇠 기호 | 데이터만 (`dialSymbols` 제거) | `_Dial`은 이미 기호 없는 자물쇠를 지원(Case 02 Final). Notebook 안내 문구도 자동으로 바뀜 |

### 5-1. Case 01 — The Missing Crown
| 미션 | 현재 문제 | 개선 (전 → 후) | 정답 영향 |
|---|---|---|---|
| M1 MC | 보기 중 museum이 하나뿐 → 단어 하나로 풀림. Hint 2가 사실상 정답 | **보기 3개 교체**: Tower Bridge / Big Ben / Hyde Park → **"The Natural History Museum (dinosaur bones)" / "The London Transport Museum (old buses and trains)" / "The Science Museum (rockets and machines)"**. 편지의 "old mummies from Egypt and a famous stone"을 읽어야 고를 수 있음. 교통 박물관은 The Shadow의 "I love trains"와 이어지는 의도된 함정. Hint 1 "Read the letter again. What does the museum have inside?" / Hint 2 "Mummies come from Egypt. Find the museum with things from Egypt." 오답 피드백 예: 공룡 → "Dinosaur bones are old, too. But what did the letter say is inside?" | 정답 B(British Museum) 유지 |
| M2 Word | 정답 STONE이 미션 제목 "The Famous Stone"과 장면 "a big grey stone"에 보임. Hint 2 `S _ _ _ E` | 제목 → **"The Strange Writing"**, 장면 → **"In Room 4, you see something big and grey, covered in strange writing."** M1 편지의 "a famous stone"으로 떠올리는 길(Recall)은 남김. Hint 2 → **"Rock and ____ mean almost the same. The thief's letter said: 'a famous ____'."** | STONE 유지 |
| M3 Code | Hint 2가 정답("FOUR, ONE, SEVEN") | Hint 2 → **"Each word in BIG letters is a number word. FOUR is 4. Now do the other two."** 순서 오답 피드백: "The numbers are right, but not the order. Read the sentences from 1 to 3." | 417 유지 |
| M4 Image | 그림 아래 "Buckingham Palace" 이름표 → palace 한 단어로 풀림 | **이름표 숨김.** 묘사(gate, soldiers, red coats, tall black hats)로 그림을 골라야 함. 오답 피드백: Tower Bridge "That is a bridge over a river. The letter talks about a gate and soldiers." / London Eye "A big wheel! Does the letter say anything about a wheel?" / Big Ben "A clock tower. Who lives at the thief's last stop?" | C 유지 |
| M5 QR | 영어 의존 낮음(현장 탐색) | 변경 없음 (현장 경험·분위기 역할) | — |
| Final | 기호 매칭 | **변경 없음** — 첫 사건에서 "Notebook의 단서를 쓴다"를 배우는 튜토리얼 역할 | — |

학습 설계 변화(예상): M1 helpful→**essential**(Comprehension), M2 helpful→**essential**(Comprehension/Recall), M4 helpful→**essential**(Comprehension). Case 01 essential 1 → 4.

### 5-2. Case 05 — The Locked Room
| 미션 | 현재 문제 | 개선 | 정답 영향 |
|---|---|---|---|
| M1 MC | 좋음. 오답 피드백 없음, Hint 2가 "어디를 볼지" | Hint 2 → **"'The third floor' is three floors up. 'On the right' is the side of your right hand."** 오답 피드백: 2층·왼쪽 → "Count the floors again. Which floor does the card say?" / 3층·왼쪽 → "Third floor, yes! But which side? Read the last line." / 대포 옆 → "The cannon is where you turn, not where the door is." | C 유지 |
| M2 Sequence | 좋음. "the other way" 오독을 진단하지 않음 | Hint 1 → "Each line tells one turn. The first line already tells you turn 1." / Hint 2 → **"'The other way' is the opposite. 'The same way as the first time' copies turn 1."** 오답 피드백: LEFT×4 → "'The other way' is not the same way. What is the opposite of left?" / L·R·R·L → "Check turn 3: 'the same way as the first time'. What was turn 1?" | L,R,L,R 유지 |
| M3 Word | 좋음 | 오답 피드백: SIX/6 → "Six ravens… and then? Read the last line: 'one more'." | SEVEN 유지(7 허용 유지) |
| Final | **기호 매칭 → 편지를 읽지 않아도 풀림** | **자물쇠 기호 제거** → 뚜껑의 영어 질문 3개("The first lock: how many ravens…?")를 읽고 수첩 단서와 맞춰야 함. 단서를 찾은 순서(5·4·7)를 그대로 넣으면 순서 피드백: **"You put the numbers in the order you found them. Read the lid: which question is first?"** 장면 문구 2줄 수정: M3 전환 "It has three locks. Each lock has a picture." → **"It has three locks. Words are painted on the lid."**, Final 이야기 "Three picture locks keep it shut." → **"Three number locks keep it shut."** | 745 유지 |

학습 설계 변화(예상): Final low→**essential**(Comprehension + Recall).

### 5-3. Case 12 — The Midnight Case
| 미션 | 현재 문제 | 개선 | 정답 영향 |
|---|---|---|---|
| M1 MC | 좋음 | 오답 피드백: Silver → "Check the metal first. What did Mrs Bell say the real gear is made of?" / 6 teeth → "Count again: how many teeth does the real gear have?" / no stamp → "Brass and eight teeth — but one thing is missing. Read the last line." | D 유지 |
| M2 Code | 좋음(Case 04 Recall). 시각표 4개를 하나씩 넣어 볼 수 있음 | 다른 시각별 피드백(1015·1104·1155): **"That train comes in on another platform. Which platform has the small red clock? Look in Case 04."** | 1140 유지 |
| M3 Word | 정답 "Big Ben"이 같은 사건 M1 장소명에도, Case 10 경고문("STOP BIG BEN AT MIDNIGHT")과 Case 11 마지막 장면("Big Ben is waiting.")에도 있음 | **변경하지 않음.** Big Ben은 시즌 서사의 목적지라 노출이 구조적이다. M1 이름만 바꿔도 단서는 남는다. 수수께끼는 피날레로 가는 이야기 장치(helpful / Exposure)로 둔다 | — |
| Final | **기호 매칭 → 피날레에서 영어가 무의미** | **자물쇠 기호 제거** → 문의 질문 3개("The first lock is a train: its platform number…")를 읽고 단서와 맞춤. 찾은 순서(8·4·7)대로 넣으면 순서 피드백 | 487 유지 |

학습 설계 변화(예상): Final low→**essential**(Comprehension + Recall). M3는 helpful 유지.

### 5-4. 예상 수정 파일 (승인 시)
- 콘텐츠: `episode01_mock.dart`, `episode05_mock.dart`, `episode12_mock.dart` (+ 새 단어 glossary: dinosaur, bones, transport, rockets, machines)
- 모델·위젯: `mission.dart`, `answer_feedback.dart`, `mission_screen.dart`, `final_mission_screen.dart`, `question_widgets.dart`
- 학습 데이터: `season1_learning.dart` (의존도·수준 갱신), 분포 테스트 갱신
- 문서: 이 문서, PROJECT_CONTEXT (핵심 Reasoning 구조 표 — Case 01·05·12 Final 설명)

### 5-5. 예상 테스트 범위
- 영향받을 가능성이 높은 기존 테스트: `final_small_pass_test`(다른 사건 JSON 해시 — Case 01·05·12 해시 갱신 필요), `season_content_test`, `full_playthrough_test`(Case 01 정답 경로는 같음), `wave1_reasoning_test`(Case 01), `new_artwork_test`(Case 05·12 Final 자물쇠, 이름표 표시 규칙), `visual_placeholders_test`, `discovery_moment_test`(Case 01 M1 Discovery 문구는 그대로)
- 신규: 보기별·입력별 피드백이 **오답에만** 붙고 정답을 말하지 않는지, 순서 피드백 조건, 이름표 숨김, Case 05·12 Final에 기호가 없는지, 학습 설계 분포 갱신, 360×640·390×844 오답 시트 렌더

---

### 5-6. 구현 결과와 제안 대비 차이

**구현한 코드 변경**

| 파일 | 내용 |
|---|---|
| `lib/data/models/mission.dart` | `ChoiceOption.feedback`, `Mission.feedback`(입력·순서 퍼즐 오답별 한 줄), `Mission.orderFeedback`, `Mission.hideOptionNames`. 모두 선택 필드, 관대한 파싱, 값이 있을 때만 JSON 기록 |
| `lib/core/utils/answer_checker.dart` | `feedbackFor(mission, submission)`: 정답 판정과 같은 정규화. 정답이면 항상 null. 선택형 = 보기의 줄, 입력·순서형 = 알려진 오답의 줄 → 없으면 "같은 글자·숫자·단계, 다른 순서"일 때 `orderFeedback` |
| `lib/features/mission/widgets/answer_feedback.dart` | `showTryAgainSheet(message:)` — "Not quite!" 제목 유지, 일반 문구 자리에 미션의 한 줄, 없으면 기존 문구 |
| `lib/features/mission/mission_screen.dart`, `final_mission_screen.dart` | 오답 시 `feedbackFor` 전달 |
| `lib/features/mission/widgets/question_widgets.dart` | `hideOptionNames`이면 랜드마크 이름 숨김(화면 읽기 라벨도 `Picture C`처럼 이름 없음 — 공원 지도와 같은 규칙) |
| `lib/data/mock/season1/episode01/05/12_mock.dart` | 아래 콘텐츠 |
| `lib/data/mock/season1/season1_learning.dart` | 01-M1·M2·M4, 05-F, 12-F → essential. 분포 **37 / 10 / 3** |
| `docs/playtest/SEASON1_PLAYTEST_CHECKLIST.md` | 바뀐 미션의 관찰 포인트 5줄(이전 문구가 사실과 달라짐) |

**제안 대비 차이 (모두 정답 불변, 승인 범위의 취지 안에서 필요했던 것)**

| 위치 | 제안 | 실제 | 이유 |
|---|---|---|---|
| 01-M1 보기 B | "The British Museum" (이름만) | **"The British Museum (treasures from long ago)"** | 다른 세 보기에만 괄호 설명이 있으면 B가 "모양만으로" 튀어 보여 정답이 드러남. 편지 단어(mummies·Egypt)를 반복하지 않는 설명으로 맞춤 |
| 01-M1 Hint 2 | "…Find the museum with things from Egypt." | "Mummies and a famous stone are not dinosaurs, trains or rockets. They are very old treasures." | 보기에 Egypt가 없으므로 같은 관계(소거 + 의미)를 보기 언어로 |
| 01-M2 | 제목·장면 1줄 | + **질문** "Complete the name of the famous stone." → "Complete its name.", **letterIntro** "…next to the stone!" → "…next to it!", **편지 첫 줄** "This stone helped…" → "It helped…" | 새 테스트(`type_b_cases_test`)가 STONE이 세 곳 더 노출됨을 찾아냄. 승인된 "정답 노출 제거"를 완성하려면 필요 |
| 01-M2 | — | 오답 "ROCK" 피드백 추가 | 가장 흔한 근접 오답 |
| 05-M2 순서 피드백 | "Start again from the first line…" | "Two lefts and two rights, yes! But the order is not right. Read the note one line at a time." | 첫 회전이 맞은 경우에도 나오므로 일반적인 문구로 |
| 12-F 편지 | 기호만 제거 | 질문 3줄 문구 조정: "The first lock is a train: its platform number." → "The first lock: the platform number of his train." 등 | 그림 없는 자물쇠에 "자물쇠가 기차다"는 말이 맞지 않음. 질문 내용·순서·정답 동일 |
| 12-F Hint 2 | — | "The train lock is first…" → "The first lock asks about his train…" | 같은 이유 |
| 12-M3 | (승인 보고 시 이미 "변경 없음") | 변경 없음 | — |

**사용자 경험상 부작용 (수용, 보고)**
- **01-M1, 360×640:** 보기가 두 줄씩 길어져 퍼즐 아래 "Letter / Get a tip" 링크가 스크롤 한 번 아래로 내려갔다. 주 행동(CHECK ANSWER)은 화면 안에 있고, 오답 시 시트가 GET A TIP을 제공하므로 막히지는 않는다. 390×844에서는 영향이 거의 없다. 플레이테스트 관찰 항목에 넣었다(`WORLD_MYSTERY_LEARNING_PLAYTEST.md` §5).
- **01-M4:** 그림 이름이 화면 읽기 라벨에서도 빠졌다(그림 퍼즐이라 이름을 읽어 주면 정답이 노출됨). 시각 장애 접근성은 이 퍼즐에서 제한적이다 — 기존 공원 지도 퍼즐과 같은 수준.

---

## 6. XP 규칙 3 + 탐정 행동 배지 (2026-10-12, 사용자 승인)

> **정정:** §2-2와 이전 완료 보고의 "찍기보다 다시 읽고 힌트를 보는 쪽이 항상 유리" 설명은 **틀렸다**. 규칙 2에서 운 좋은 첫 시도 찍기는 이해와 같은 150 XP와 Sharp Eyes를 받았고, 한 번 오독 후 정정한 경우(125)보다 많았다. 후속 감사로 확인하고 아래로 대체했다. (§2-2는 당시 기록으로 남긴다.)

### 6-1. 규칙 2 → 3

| 시나리오 (일반 미션) | 규칙 2 | 규칙 3 |
|---|---|---|
| 첫 시도 정답 (이해 / 운 좋은 찍기 — 구분 불가) | 150 + Sharp Eyes(+빠르면 Quick Thinker) | **100**, 배지 없음 |
| 오답 1회 → 정답 | 125 | **100** |
| 오답 3회 → 정답 | 100 | **100** |
| 힌트 1 또는 1·2 → 첫 시도 정답 | 150 + Sharp Eyes | **100** |
| Final (어떤 경우든) | 200~250 | **200** |
| 사건 결과 요약 | 전부 첫 시도면 "Every answer on the first try!" | 행동 기반: 다시 확인 → "You checked the clues again and never gave up!", 증거 열람 → "Your notebook helped you crack the case!", 그 외 → "Case closed, Detective!" |

### 6-2. 저장 호환성
| 항목 | 처리 |
|---|---|
| 규칙 1·2로 푼 미션 | `xpRules`에 기록된 규칙(없으면 1)으로 계산 → 기존 XP 불변 |
| 새로 푼 미션 | `xpRules[미션] = 3` |
| 배지 | 저장 형식(이름 문자열 목록)·기존 id 불변. 신규 id 3개 추가. 모르는 id는 건너뜀(기존 동작) |
| 행동 기록 | 선택 필드 `behavior`(`BehaviorLog`: rechecked, evidenceViewed, words). **키가 없는 세이브 = 기록 없음** — 저장 후에도 키를 쓰지 않아 "기록 없음"이 유지됨. 새 세이브·Play again·플레이테스트 seed는 항상 기록 |
| 저장 키 | 변경 없음 (`lm.progress.v1*`, `lm.season.v1`) |

### 6-3. 배지 조건 (코드: `GameBadge.isEarned`)
| 배지 | 상태 | 정확한 조건 |
|---|---|---|
| First Clue | 유지 | 단서 1개 이상 |
| Puzzle Solver | 유지 | 미션 3개 이상 해결 |
| London Explorer | 유지 | 일반 미션 전부 해결 |
| Master Detective | 유지 | 사건 해결 |
| Case Badge 6개 | 유지 | 해당 사건 해결 |
| Sharp Eyes | **retired** | 신규 지급 없음. 보유 세이브에서만 표시. 설명 "이전 버전에서 미션을 해결하며 받은 배지" |
| Quick Thinker | **retired** | 신규 지급 없음. 설명 "이전 버전에서 미션을 빠르게 해결하며 받은 배지" |
| Second Look | 신규 | 기록 중인 실행에서, 해결된 미션 중 `behavior.rechecked`에 있고 오답이 1회 이상인 미션이 있음. rechecked는 **오답 후 · 해결 전**에만 기록: ① 퍼즐/Final의 Letter 버튼(`recordRecheck`), ② 수첩·Archive·Final 수첩의 증거 타일 열기(현재 미션에 오답이 있을 때, `recordEvidenceViewed`) |
| Notebook Explorer | 신규 | 기록 중인 실행에서 `behavior.evidenceViewed` 1개 이상. 사건 해결 전, 수첩·Archive·Final 수첩의 증거 타일을 눌렀을 때만 기록(Discovery·Story·해결된 미션 화면의 증거는 제외) |
| Word Collector | 신규 | 기록 중인 실행에서 `behavior.words`(중복 없는 단어) 3개 이상 |

- 행동 배지는 **XP를 더하지 않는다**(테스트). 사건당 1회(`badgeIds` 중복 방지). 다음 정답 순간의 Discovery에 "New badge:"로 표시(새 화면·팝업 없음).
- Notebook 아이 화면: 배지 칸 = 진행 배지 4 + 행동 배지 3 + 사건 배지(있으면) + 보유한 retired 배지.

### 6-4. 화면 문구
- 제거: "Every answer on the first try!"(사건 결과), 힌트 패널 안내는 이미 "Tips are free"
- 부모 보고서: **Detective Actions** 섹션(새 기록 — 막혔을 때 다시 확인 n, 수첩에서 살펴본 증거 n, 옛 세이브는 "기록 없음"), Play Record에 "첫 시도에 해결은 운 좋게 맞힌 경우와 구분할 수 없어 영어 이해의 근거가 아니다" 주석, 하단에 "XP와 배지는 게임 보상이며 영어 점수가 아니다"
- 부모 코멘트: 행동 기록이 있으면 사실만("다시 확인하고 해결한 미션 n개", "증거 n개를 살펴봄"), 없으면 기록 없음 안내

### 6-5. 수정 파일
| 파일 | 내용 |
|---|---|
| `lib/features/game/scoring.dart` | 규칙 3, retired 플래그·`shownFor`, 행동 배지 3개, `forEpisode` 순서(공통 → 사건 배지), **잘못된 주석 정정** |
| `lib/data/models/game_progress.dart` | `behavior` / `BehaviorLog` |
| `lib/features/game/game_controller.dart` | 규칙 3 기록, `recordRecheck`, `recordEvidenceViewed`, `lookUpWord`가 행동 기록에도 단어 추가 |
| `lib/widgets/evidence_card.dart` | `EvidenceTile.onOpened` |
| `lib/features/notebook/notebook_screen.dart`, `season_archive.dart` | 증거 타일 열기 기록, 배지 칸 `shownFor` |
| `lib/features/mission/mission_screen.dart`, `final_mission_screen.dart` | Letter 다시 읽기 기록, Final 수첩 증거 열기 기록 |
| `lib/features/result/detective_report.dart`, `parent_report_screen.dart` | 행동 기반 요약, 행동 기록 지표·코멘트, 첫 시도 주석, XP 안내 |
| 테스트 | 신규 `type_b_rewards_test.dart`(23). 규칙 2 전제 기대값 갱신: `game_controller_test`(힌트·XP·배지 3개 블록, 속도 XP 단정 1줄 삭제), `detective_report_test`(요약 문구), `type_b_p0_test`(찍기 vs 읽기 → 동일 XP), `visual_placeholders_test`(배지 예시를 현재 지급 배지로) |
| 문서 | 이 문서 §6, 설계 문서 §5, PROJECT_CONTEXT, README, 플레이테스트 문서 §5 |

### 6-6. 테스트 결과
- `flutter analyze`: No issues found
- `flutter test`: **815 → 838 전부 통과** (신규 23)
- 화면: 부모 보고서(행동 섹션·기록 없음) 360×640·390×844 위젯 테스트, 수첩 배지 칸 스크린샷 확인(잉크 아이콘, 글자 대체 없음)

### 6-7. 검증되지 않은 것 / 남은 위험
- **Second Look 유도 위험:** 조건에 오답이 들어가므로 일부러 틀릴 수 있다(설명 문구·XP 없음·사건당 1회로 완화). 플레이테스트 관찰 필요
- 수첩의 **단서 카드 읽기**는 탭 이벤트가 없어 기록할 수 없다 → Second Look·Notebook Explorer는 편지 다시 읽기와 증거 열기만 인정
- 진행 중이던 옛 세이브는 그 실행에서 행동 배지를 받을 수 없다(의도된 정직성 비용)
- 실기기 확인 없음, 아이 플레이테스트 없음

## 7. 미해결 사항
- **Second Look이 일부러 틀리기를 유도할 위험** — 플레이테스트로 관찰(§6-7)
- **플레이테스트 미실시.** 계획: `WORLD_MYSTERY_LEARNING_PLAYTEST.md`. 모든 효과(찍기 감소, 피드백 읽기, 보고서 이해)는 아직 가설
- Phase 4 (Notebook 연속성, Cross-Case 언어 재사용) — **설계만**(설계 문서 §7). 구현하지 않음
- 나머지 9개 사건에는 오답 피드백·이름 숨김을 적용하지 않음 (대표 Case 결과를 보고 확장 여부 결정)
- 감사 P1 중 미착수: 언어 난이도 성장(Case 07~12 문체), 보기·힌트 문구 Glossary 적용, 재플레이 보기 섞기
- `Mission.skills`(레거시 태그)는 데이터에 남아 있으나 더 이상 표시되지 않음
- 실기기 확인(한글 글꼴 포함 보고서 화면) 필요


---

## 8. Phase 2 — Case 02~04 (**2026-10-12 승인 → 구현 완료**)

> 아래 8-1·8-2는 승인받은 분석과 제안 원문이다. 실제 구현과의 차이는 **8-4**에 있다.
> 모든 개선안에서 **정답·사건 흐름·Evidence·장소·미션 수는 그대로**다. 공통 오답 피드백 시스템(`ChoiceOption.feedback`, `Mission.feedback`, `orderFeedback`)과 `hideOptionNames`를 재사용하며 **새 코드는 필요 없다**.

### 8-1. 분석 (현재)

| 미션 | 정답 | 결정적 영어 | 영어 없이 가는 길 | 찍기 | Hint 1 / 2 역할 | 오답 피드백 | Notebook 연결 | 8~12세 | 분류(현재) |
|---|---|---|---|---|---|---|---|---|---|
| 02-M1 숫자 | 817 | "between eight and nine", "two more small marks" | 없음(시계 읽기 필요) | 불가 | H1 시계 지식 / **H2 거의 정답**(8 + 15+2) | 없음 | 8:17 → M3·Final | 8세: 아날로그 시계 자체가 벽 | Essential |
| 02-M2 객관식 | c 가장 작은 종 | "It is **not** under the biggest bell" | 없음(부정문) | ≤3 | H1 "not" 위치 / H2 반의어 관계 | 없음 | 기어 → Case 12 | 적절 | Essential |
| 02-M3 객관식 | b Gallery 8 · 17 | "The hour is the gallery. The minutes are the picture." | 없음 | ≤3 | H1 멈춘 시각 / H2 대응 관계 | 없음 — **오답 3개가 각각 오독 유형인데 진단 안 함** | M1 8:17 | 적절 | Essential |
| 02-F 숫자 | 917 | "One hour after the clock stops" (M3) | 없음 | 불가 | H1 두 단서 / H2 거의 정답 | 없음 | M1·M3 Recall | 10세 이상 적절 | Essential |
| 03-M1 객관식 | c 젖은 발자국 | "It is next to the door" | **"door" 단어 찾기**로 풀림 | ≤3 | H1 보고서 구조 / **H2 "door가 있는 줄을 찾아라"(키워드 매칭)** | 없음 | Red Button → Case 08 | 쉬움 | Helpful |
| 03-M2 객관식(3) | b Miss Rose | "wore a red coat and a blue scarf" + 단추 = 코트 | 없음(두 조건) | ≤2 | **순서 역전**: H1이 의미 관계, H2가 볼 곳 | 없음 | M1 Red Button | 적절 | Essential |
| 03-M3 순서 | 가게→계단→카페→북문 | very wet / wet / a little wet / almost dry | 없음 | 24순열 | H1 관계 / H2 정도 순서 | 없음 | — | 적절 | Essential |
| 03-F 그림(이름 있음) | d King's Cross | "Take me north", "tall clock tower" + "smells of trains"(M3 증거) | 없음 — 이름표가 있어도 시계탑이 둘이라 증거가 결정 | ≤3 | H1 관찰 / H2 Notebook 위치 | 없음 | M3 증거 Recall | 10세 이상 | Essential |
| 04-M1 객관식 | c 승강장 | "where trains never sleep" ↔ "open day and night" | 없음(비유) | ≤3 | **순서 역전**: H1 의미, H2 볼 곳 | 없음 | Black Wax Seal → Final | 적절 | Essential |
| 04-M2 객관식 | b 4번 승강장 빨간 시계 | "Platform 4 has a small red clock", "a red door, **but no clock**" | **보기가 카드 단어(red·clock·Platform 4)를 그대로 반복** → 맞춰 보기로 풀림 | ≤3 | H1 네 단어 모두 / H2 거의 정답 | 없음 | → Case 12 M2 Recall | 쉬움 | Helpful |
| 04-M3 그림(이름 있음) | b Tower of London | "an old castle by the river", "four towers", "Black birds" | **그림 이름표 "Tower of London"**과 편지의 "Tower" | ≤3 | H1 castle 뜻 / H2 "탑을 세어라"(시각) | 없음 | — | 쉬움 | Helpful |
| 04-F 단어 | RAVEN | "named after a bird", "pressed into every seal" | 정답 단어가 Case 02·03·시즌 보드에서 반복 노출 | 불가(단어) | H1 관찰 / H2 Notebook 위치 | 없음 | M1 seal Recall | 쉬움 | Helpful |

현재: Essential **8 / 12** (02: 4, 03: 3, 04: 1)

### 8-2. 개선안 (전 → 후)

| 미션 | 현재 문제 | 변경 내용 | 학습 목표 | 정답 영향 | UX 영향 |
|---|---|---|---|---|---|
| 02-M1 | H2가 계산까지 해 줌, 오답 진단 없음 | **H1** "Read Mrs Bell's note line by line. Where was the hour hand? Where was the minute hand?" **H2** "'Between eight and nine' means the hour is still eight. On the three is fifteen minutes. Each small mark is one more minute." **피드백** `917` "Between eight and nine: the hour hand has not reached nine yet." / `815` "Read the last line: the minute hand moved two more small marks." / `832` "On a clock, the three means fifteen minutes, not three." | 시각 표현 (Comprehension) | 817 유지 | 없음 |
| 02-M2 | 오답 진단 없음 | **피드백** a "Look at the word just before 'under the biggest bell'." / b "The note never talks about the clock face. Which line says where the gear IS?" / d "The stairs are not in the note. Find the line that says where the gear IS." Hint 유지 | 부정문 (Comprehension) | c 유지 | 없음 |
| 02-M3 | 오독형 오답 보기가 있는데 진단 안 함 | **피드백** a "The hour hand was between eight and nine. Which hour had it really reached?" / c "Check the plan: the hour is the GALLERY, the minutes are the PICTURE." / d "Those are the marks in Mrs Bell's note. The plan says to use the stopped TIME." Hint 유지 | 규칙 적용 (Application) | b 유지 | 없음 |
| 02-F | before/after 혼동 진단 없음, H2가 계산 결과에 가까움 | **피드백** `817` "That is when the clock stopped. The plan says ONE HOUR AFTER." / `717` "One hour AFTER, not before. Does the hour go up or down?" / `818` "In one hour, the hour hand moves. Do the minutes change?" **H2** "'One hour after' means the hour goes up by one. The minutes do not change." | before / after (Recall) | 917 유지 | 없음 |
| 03-M1 | H2가 키워드 찾기를 가르침 | **H2** "Each line names a thing first. Then 'It is…' tells where that thing is. Find 'next to the door' and read which thing that line names." **피드백** a "Read the button's line again: where is it?" / b "The blue cloth is on the frame. Which thing is next to the door?" / d "The frame is where the cloth was. Read the line that ends with 'the door'." | 대명사 It이 가리키는 것 | c 유지 | 없음. **분류는 Helpful 유지**(장면 소개 미션, 억지로 어렵게 하지 않음) |
| 03-M2 | Hint 순서 역전, 오답 진단 없음 | **H1** "What colour was the button? What colour was the cloth? Check your notebook." **H2** "A button comes from a coat. A piece of cloth can come from a scarf." **피드백** a(Mr Green) "Mr Green wore brown and green. Which colours did you find in Gallery 8?" / c(Mr Grey) "Mr Grey has something red, but it is his scarf. A button comes from a coat." | 두 조건 묘사 결합 | b 유지 | 없음 |
| 03-M3 | 오답 진단 없음 | **H1** "Each line says how wet one footprint was. Find the wettest and the driest." **H2** "Wet shoes get drier with every step: very wet, then wet, then a little wet, then almost dry." **피드백** 정반대 순서 "You started with the driest step. Her first step was the wettest." / `shop,cafe,stairs,door` "Check 'wet' and 'a little wet': which one is wetter?" / 그 외 순서 "Some steps are in the right place. Put them from very wet to almost dry." | 정도 표현 (Application) | 순서 유지 | 없음 |
| 03-F | 오답 진단 없음, H2가 위치만 안내 | **H1** "Two pictures have a clock tower. Open your notebook: what did the boot from the Great Court smell of?" **H2** "'Smells of trains and smoke': she had been near trains. Which clock tower stands where trains come and go?" **피드백** a(Big Ben) "Big Ben has a clock tower too. But what did her boot smell of?" / b(Tower Bridge) "Read the driver's words: a big building with a tall clock tower. Is this one?" / c(Hyde Park) "A park has no clock tower. Read the driver's words again." **이름표 유지**(시계탑이 둘이라 이름이 정답을 주지 않음) | 증거 글귀 다시 읽기 (Recall) | d 유지 | 없음 |
| 04-M1 | Hint 순서 역전, 오답 진단 없음 | **H1** "Read the station guide: when does each place close?" **H2** "'Never sleeps' means it never closes, not even at night." **피드백** a "At 10 PM the ticket office closes. Does it 'never sleep'?" / b "The café closes at 8 PM: it sleeps at night!" / d "The shop closes at 9 PM. Which place is open day AND night?" | 비유 표현 (Comprehension) | c 유지 | 없음 |
| 04-M2 | **보기가 카드 단어를 그대로 반복** → 맞춰 보기 | **보기 문구만 변경**(id·정답 유지): a "Platform 1" / **b "Platform 4"** / c "Platform 7" / d "Platform 9". 짐꾼의 네 문장을 읽고 RED·FOUR·CLOCK을 확인해야 함(7번 "a red door, **but no clock**", 9번 green). **H1** "Your card has four words. Check each platform against all four." **H2** "FOUR is a platform number. Read every line to the end: 'a red door, but no clock' has no clock." **피드백** a "Platform 1's clock is white. Your card says RED." / c "Platform 7 has a red door. Read to the end of the line: is there a clock?" / d "Platform 9's clock is green. Which colour is on your card?" | 조건 결합 + "but no" → **Essential** | b 유지 (라벨 "Under the red clock on Platform 4" → "Platform 4") | 보기가 짧아짐 |
| 04-M3 | **그림 이름표 "Tower of London"**이 정답 | **이름 숨김**(`hideOptionNames`, Case 01 M4와 같은 방식). **H1** "The letter describes the place in parts: a castle, a river, four towers, black birds. Look for each one." **H2** "A castle is a strong old building with thick stone walls and towers." **피드백** a(Palace) "A palace, not a castle: where are the four towers and thick walls?" / c(Museum) "A museum with tall columns. The letter talks about an old castle by the river." / d(London Eye) "A big wheel by the river. Is it an old castle with four towers?" | 묘사 → 그림 (Comprehension) → **Essential** | b 유지 | 화면 읽기 라벨도 "Picture B"(Case 01 M4·공원 지도와 같은 접근성 수준) |
| 04-F | 정답 단어가 시즌 내내 노출 | **변경 최소**: **H1** "Open your notebook and look closer at the seal from the first letter." **H2** "'Named after a bird' means their name is a bird's name: the bird pressed into every seal." **피드백** `CROW` "Close! A crow is a black bird too. But which bird is pressed into the seal?" / `BIRD` "Which bird? Look closer at the seal from the first letter." / `BLACK` "Black is its colour. What is the bird called?" / `TOWER` "The bird lives at the Tower. What is the bird's name?" **분류 Helpful 유지**(까마귀는 시즌의 이야기 장치) | 앞 증거 다시 읽기 | RAVEN 유지 | 없음 |

개선 후: Essential **10 / 12** (04-M2·M3 추가). 시즌 전체 **37 → 39**.

### 8-3. 확인한 기준
- 정답 문자열을 말하는 Hint·피드백 없음 (`type_b_cases_test`의 규칙이 시즌 전체에 적용되므로 구현 시 자동 확인)
- 같은 피드백 문구 반복 없음 (보기마다 다른 오독)
- Hint 사용 XP 감점 없음 (XP 규칙 3, 변경 없음)
- 예상 수정 파일: `episode02~04_mock.dart`, `season1_learning.dart`(04-M2·M3 → essential, 표현 갱신), 테스트
- 영향받을 테스트: `final_small_pass_test`(ep02~04 해시 갱신), `wave1/wave2/case02_reasoning_test`(Hint 문구 단정이 있으면), `new_artwork_test`(이름 표시 예시 04-M3 → 03-F), `learning_objectives_test`(분포 37/10/3 → 39/8/3), `discovery_moment_test`(문구 불변 예상)

### 8-4. 구현 결과

**승인 범위 그대로 구현:** 12개 미션 전부 오답 피드백·Hint 정리, 04-M2 보기 라벨("Platform 1/4/7/9"), 04-M3 그림 이름 숨김. **12개 정답 전부 불변**(테스트로 고정), Evidence·장소·흐름·미션 수 불변.

**제안 대비 차이 (1건, 기존 추리 보호 규칙 때문)**

| 위치 | 제안 | 실제 | 이유 |
|---|---|---|---|
| 03-F Hint 1·2 | H1 "…Open your notebook: what did the boot … smell of?" / H2 "'Smells of trains and smoke': she had been near trains. Which clock tower stands where trains come and go?" | H1 원래대로 "Two pictures have a clock tower. Look at the evidence you found today, too." / H2 **"Open your notebook and look closer at the footprint. 'Smells of …' tells you where she had been. Which clock tower fits?"** | 기존 `wave2_reasoning_test`(Detective Reasoning Pass 규칙)가 막음: ① Case 03의 Tip은 "train/station"을 말하지 않는다(부츠 글귀를 읽는 것이 추리 자체), ② 마지막 Tip은 Notebook의 footprint를 가리킨다. 제안이 두 규칙을 모두 어겼다. 테스트 기대값을 바꾸지 않고 **콘텐츠를 규칙에 맞춤**. H2는 여전히 "smells of"의 의미 관계를 설명 |

**수정 파일:** `episode02_mock.dart`, `episode03_mock.dart`, `episode04_mock.dart`, `season1_learning.dart`(04-M2·M3 → essential/comprehension, 표현 갱신)

**학습 설계 변화:** Case 02~04 Essential 8 → **10**. 시즌 분포 37/10/3 → **39 / 8 / 3**

**테스트**
- 신규 `test/type_b_phase2_test.dart` (12): 12개 정답 불변, 모든 오답 보기에 피드백·미션 안 중복 없음, Hint 2개·서로 다름, 미션별 오독 피드백(시계·before/after·부정·색·정도·"but no clock"·castle·새 이름), 학습 설계, XP 규칙 3 유지(Case 02 전체를 힌트·오답과 함께 풀어 500 XP), 화면 360×640·390×844(04-M2 "Platform 7" 피드백 표시, 04-M3 이름 없음·화면 읽기 "Picture B")
- 시즌 전체 규칙(`type_b_cases_test`: 피드백이 정답에 붙지 않음·정답을 말하지 않음·한 줄 길이)이 새 콘텐츠에 자동 적용되어 통과
- 기대값 갱신: `final_small_pass_test`(ep02~04 해시 — 나머지 9개 사건 해시 불변 확인), `wave1_reasoning_test`(04-M2 라벨 "Platform 4", 짐꾼 문장 유지 단정 추가), `new_artwork_test`(이름 있는 예시 04-M3 → 11-M3, 04-M3는 이름 없는 쪽), `learning_objectives_test`(분포 39/8/3, 이름 숨김 미션 2개)
- `flutter analyze` 0 issues, `flutter test` **838 → 850 전부 통과**

**UI 영향:** 04-M2 보기가 짧아짐. 04-M3 그림 이름 없음(화면 읽기 라벨 "Picture B" — Case 01 M4·공원 지도와 같은 접근성 수준). 나머지는 오답 시트의 한 줄과 Tip 문구만 바뀜. 새 화면·팝업 없음.

### 8-5. Case 06~11 후속 계획 (같은 방법)

| 단계 | 내용 |
|---|---|
| 1. 분석 | 미션별: 결정적 영어, 영어 없이 가는 길(키워드·이름표·서사적 두드러짐·이미 노출된 정답), 찍기 공간, Hint 역할, **기존 추리 보호 테스트(`wave1/wave2/case09_reasoning_test`, `final_small_pass_test`)가 지키는 규칙 목록** 먼저 확인 — 이번 03-F처럼 제안이 규칙과 충돌하지 않게 |
| 2. 공통 개선 | 모든 선택형 오답 보기에 오독 진단 한 줄, 입력형의 흔한 오답·순서 피드백, Hint 1 = 볼 곳 / Hint 2 = 핵심 영어 의미 (단 사건별 보호 규칙이 우선) |
| 3. 사건별 후보 | **06** M2 GREY가 M1 증언에 이미 노출 → 피드백 중심, Final은 서사적으로 두드러진 보기 → 보기 구성 검토. **07** 이미 4개 모두 essential → 피드백만(전치사 반대 해석). **08** M1 화용 질문·M2 alone 피드백, Final 거짓말 반박. **09** whose 오독 피드백(Anna의 물건 = 가장 흔한 실수), M2 알파벳은 Helpful 유지. **10** M3 그림 이름표 "Tower Bridge"가 단어 그대로 → 이름 숨김 후보, Final 어순 피드백(WHO/WHEN 위치). **11** M3 이름표·앞 장면이 "station" 노출 → 이름 숨김 검토, M2 역순 철자는 Language Independent 유지 |
| 4. 승인 | 미션별 전후 표와 정확한 문구로 승인 요청 → 구현 → 해시·추리 보호 테스트 확인 |
| 5. 규모 | 사건 2~3개씩 묶어 진행(06~08, 09~11) — 이번과 같은 크기 |


---

## 9. Phase 3A — Case 06~08 (**2026-10-12 승인 → 구현 완료**)

> 9-1~9-4는 승인받은 분석·제안 원문이다. 구현은 **제안과 동일**(차이 없음) — 결과는 9-5. 정답·결말·Evidence·장소·미션 수 불변, 공통 오답 피드백 시스템만 재사용(새 코드 없음).

### 9-1. 기존 추리 보호 규칙 (테스트 근거)

| Case | 핵심 미스터리 | 플레이어가 추론할 것 | 미리 공개 금지 | 보호 테스트 | 사건 간 연결 |
|---|---|---|---|---|---|
| 06 | 검은 코트의 낯선 사람은 누구인가 | 같은 코트 두 사람(키 큰 남자·작은 가방 vs 키 작은 여자·큰 가방) 중 분수대 남자 = 카드를 떨어뜨린 사람 = Inspector Grey | Final 페이지·Hint에 grey/gray/inspector/hat/card/"on your side" 금지, M3 장면에 grey 금지, Final 보기는 사람만(≤4단어, 쉼표 없음), 마지막 Hint에 notebook | `final_small_pass_test` 1~9, `wave1_reasoning_test` Case 06 | ROW R · SEAT 17 → Case 10·11, "Find the other half in Hyde Park" → Case 07 |
| 07 | 지도는 어디서 완성되는가 | Grey의 길 안내(다리 건너 왼쪽) + Joined Map 화살표(북쪽) → 멈출 곳 | Final 전 어디에도 "old gate" 금지(Joined Map 글귀 제외), Final 편지·Hint에 gate/bench 금지, 마지막 Hint에 joined map | `wave2_reasoning_test` Case 07, `post_discovery_pass_test` 1~6 | Old Map Fragment(Case 05) → 07 → Platform 9(Case 08) |
| 08 | 가방 주인과 그녀의 거짓말 | M1 꼬리표 → M2 혼자 가는 사람 → Final: Case 03의 Red Button(코트 단추, Gallery 8)으로 "Gallery 8에 간 적 없다"를 반박 | Final 페이지·Hint에 button/coat/red/miss rose 금지, Final 전 "Miss Rose = Mrs Robin" 금지, 마지막 Hint = Case Archive · Case 03, Blue Cloth·Raven Tower 보기 금지 | `final_small_pass_test` 10~16, `wave1_reasoning_test` Case 08 | **Case 03 Red Button → 08 Final (R3)**, Empty Jewel Box → Case 09 |

**발견한 빈틈:** 위 테스트의 `page()`·`beforeFinal()`·`before()`는 **오답 피드백 문구를 검사하지 않는다**(피드백 시스템보다 먼저 만들어진 테스트). 피드백도 화면에 나오므로 같은 금지어를 지켜야 한다 → 이번 안의 모든 피드백은 해당 금지어를 쓰지 않도록 설계했고, **보호 규칙을 피드백까지 넓히는 테스트를 추가**한다.

### 9-2. 06-M2 GREY 노출 문제

- 현재: M1 증언 "He had a **grey** hat", M1 장면 "a dark coat, a **grey** hat, a small bag!", M1 증거 "Dark coat · **grey** hat · small bag". M2 카드는 "My name is a colour. It is the colour of rain clouds and old stones."
- 문제: 아이는 수수께끼를 이해하지 않고도 "앞에서 나온 색 단어"(grey / red)를 넣어 볼 수 있다. 수수께끼와 앞 증언이 **연결되지 않은 채** 둘 다 존재한다.
- grey 삭제는 불가: 회색 모자는 M1 오답 보기(worn vs carried), M3 경비원 기록, 증거 글귀, Final의 두 사람 구분에 모두 쓰이는 이야기의 축이다.
- **제안: 노출을 단서로 바꾼다.** 카드 뒷면을 "My name is a colour. **It is the colour of my hat**, and of rain clouds and old stones."로 바꾼다. 카드를 떨어뜨린 사람 = M1의 낯선 사람(이미 이야기가 말함) → 그의 모자 색 = M1 증언(Notebook의 Witness Notes)에 있음. 이제 grey는 "미리 보인 정답"이 아니라 **영어 문장을 이해해야 연결되는 증거**다(English → Evidence → Deduction). 수수께끼(rain clouds)는 두 번째 길로 남겨 8~9세도 막히지 않게 한다.
- 추리 보호: Final은 "분수대 남자 = 두 코트 중 누구"를 묻는다. M2에서 "카드 주인의 모자 색 = 이름"이 드러나도 Final 페이지에는 모자·grey가 없으므로(보호 규칙 그대로) Final 추리는 바뀌지 않는다. 카드를 떨어뜨린 사람이 낯선 사람이라는 것은 M1 장면·M2 장면("A detective?")이 이미 말한다.

### 9-3. 미션별 분석과 개선안

| 미션 | 정답 | 현재 분류 | 영어 없이 가는 길 · 찍기 | 현재 Hint 1 / 2 | 개선안 (Hint · 피드백 · 콘텐츠) | 개선 후 분류 |
|---|---|---|---|---|---|---|
| 06-M1 객관식 | b 작은 가방 | Essential | — · ≤3 | H1 의미(carried vs worn) / H2 관계 → **역할 뒤바뀜** | **H1** "Read what each witness says he carried. Which thing do two of them say?" **H2** "'Carried' is what he held in his hand. A hat is worn, not carried. 'Agree' means two people say the same thing." **피드백** a "Only the baker saw an umbrella. Which thing do TWO witnesses agree on?" / c "The flower seller sells flowers. Did any witness say he carried flowers?" / d "A hat is worn on the head, not carried. What did he hold?" | Essential |
| 06-M2 단어 | GREY | Helpful | 앞에서 나온 색을 넣어 보기 · 단어(찍기 어려움) | H1 하늘 색 / H2 "흑백 사이, 네 글자"(거의 정답) | **카드 뒷면** "My name is a colour. It is the colour of my hat, and of rain clouds and old stones." **H1** "Who dropped the card? Look at the witness notes in your notebook." **H2** "'The colour of my hat' means his name is the same colour as the hat he wore. Rain clouds are that colour too." **피드백** `RED` "The red thing was the baker's umbrella. What colour was the hat of the man who dropped the card?" / `BLACK`·`DARK` "Dark is the colour of his coat. The card talks about his hat." / `WHITE` "Are rain clouds white? Read the back of the card again." / `BLUE` "Is a rain cloud blue? Check the witness notes: what colour was his hat?" | **Essential** (Recall ← M1) |
| 06-M3 숫자 | 4 | Essential | — · ≤9 | H1 관찰 / H2 관계 (적절) | Hint 유지. **피드백** `5` "The coat is the same on both days: a dark coat. Count only what changes." / `3` "Check every part: tall or short, man or woman, the hat, the bag." / `6` "Read again: some parts are the same on both days." | Essential |
| 06-F 객관식 | c Inspector Grey | Helpful | 보기 중 서사적으로 두드러진 인물 · ≤3 | H1 관찰(키·가방) / H2 Notebook (보호 규칙: 마지막 Hint = notebook) | Hint 유지(보호). **피드백**(grey·inspector·hat·card 금지 준수) a "The Raven Society person was the short woman with a big bag. Is this man short?" / b "The theatre guard was writing in his notebook at the theatre door. Did he drop anything by the fountain?" / d "The juggler was a witness: he saw the stranger. Is he the stranger?" | Helpful 유지 |
| 07-M1 지도 | c 오른쪽 벤치 | Essential | 지도 이름 없음 · ≤3 | H1 관찰 / H2 볼 곳 | **H2** "'Go past the tree' means go on by it. 'Turn right' and 'beside the bench' tell you where to stop." **피드백**(gate 금지 준수) a "The note says to go PAST the tree, not to stop at it." / b "Check the turn at the bridge: which way does the note say?" / d "That spot is far past the bridge. The note says to look beside the bench." | Essential (유지) |
| 07-M2 객관식 | c 물뿌리개 뒤 | Essential | — · ≤3 | H1 관찰 / H2 의미 (적절) | Hint 유지. **피드백** a "Read the second line: the box is NOT on the shelf." / b "Under the table, yes! But 'behind' is not 'in front of'." / d "Is the box ON the table, or UNDER it?" | Essential |
| 07-M3 순서 | station, park, river | Essential | — · 6순열 | H1 관찰 / H2 의미 (적절) | Hint 유지. **피드백** 거꾸로(river, park, station) "That is upside down. Which piece goes at the TOP?" / 그 외 순서 "Read the first two lines again: one piece goes at the top, one at the bottom." | Essential |
| 07-F 지도 | b 지도 D | Essential | — · ≤3 | 보호(마지막 Hint = joined map, gate 금지) | Hint 유지(보호). **피드백**(gate 금지 준수) a "Left after the bridge, yes. But where does your joined map's arrow point?" / c "Inspector Grey says turn LEFT after the bridge." / d "Inspector Grey says go PAST the tree." | Essential |
| 08-M1 객관식 | b "Where are you going?" | Essential | — · ≤3 | H1 관찰 / H2 거의 정답 | **H2** "'TO: Edinburgh' is where the owner is going. Which question gets that answer from every passenger?" **피드백** a "A nice question! But the tag does not say what the owner likes." / c "A clock can tell you the time. Which part of the tag can a passenger's answer check?" / d "The rain washed the name away, but asking about it won't find the owner. What does the tag still say?" | Essential |
| 08-M2 단어 | ROBIN | Essential | 프롬프트 "MRS ___" · Mrs는 둘 | H1 관찰 / H2 의미 | **H2** "'Alone' means with nobody else. 'My dad and I' means two people." **피드백** `LILY` "Lily is going to Edinburgh, but with her dad. The tag says 1 adult, alone." / `PATEL` "Mrs Patel is going to York. Where is the owner going?" / `BROWN` "Mr Brown says 'No, no': he is going to Cambridge." | Essential |
| 08-M3 숫자 | 429 | Essential | — · 1000 | H1 쓰기 방법 / H2 관계 | **H1** "Read the note on the lock: what comes first, and what comes next?" **H2** "'Forty-two' is a number word: write it with numbers. 'The hour of my train' is the hour only, not the minutes." **피드백** `930` "That is the whole train time. The note wants the seat first, then only the hour." / 순서 "Right numbers, wrong order. First the seat, then the hour." | Essential |
| 08-F 객관식 | c Red Button | Essential | 소거로 일부 접근 · ≤3 | 보호(마지막 Hint = Case Archive · Case 03, button 금지) | Hint 유지(보호). **피드백**(button·coat·red·miss rose 금지 준수) a "The name tag is from this case. Does it say anything about Gallery 8?" / b "Look closer at the footprint in the Case Archive: where was it found?" / d "Your passenger notes say where people are going. Do they show who was in Gallery 8?" | Essential |

**개선 후 Essential:** Case 06~08 10 → **11** (06-M2). 시즌 **39 → 40**. 06-F는 Helpful 유지(보기 구성은 보호 규칙 대상이라 이번에 바꾸지 않음).

### 9-4. 추가 테스트 (승인 시)
- 12개 정답 불변, 모든 오답 보기에 피드백·미션 안 중복 없음, Hint 2개
- **보호 규칙을 피드백까지 확장:** 06-F 피드백에 grey/gray/inspector/hat/card 없음 · 07의 Final 전 모든 피드백과 07-F 피드백에 "gate" 없음 · 08-F 피드백에 button/coat/red/miss rose 없음 · 08 Final 전 피드백에 "miss rose"/"same person" 없음
- 06-M2: 카드 뒷면이 모자를 가리키고, M1 증거(Witness Notes)에 grey hat이 남아 있음(Recall 경로)
- Case 03 → 08 연결: Red Button 이름·설명("From a coat")·장소(Gallery 8) 불변
- 화면 360×640·390×844: 06-M2 오답 시트, 08-F 오답 시트
- 갱신 예상: `final_small_pass_test` 해시(ep06·07·08), `learning_objectives_test` 분포(40/7/3)

### 9-5. 구현 결과

- **제안과 동일하게 구현** (06-M2 카드 문장, 12개 미션 피드백·Hint, 보호 테스트 확장). 06-F·07-F·08-F의 Hint는 보호 대상이라 변경하지 않음
- **수정 파일:** `episode06_mock.dart`, `episode07_mock.dart`, `episode08_mock.dart`, `season1_learning.dart`(06-M2 → essential / recall ← 06-M1, 표현에 "He had a grey hat" 포함)
- **구현 중 안전장치가 잡은 것:** 07의 "Beside the right bench" 보기는 M1에서 **정답**, Final에서 오답이다. 편집 스크립트의 "정확히 한 번 일치" 검사가 중복을 막았고, Final 보기에만 피드백을 붙였다(테스트: M1 정답 보기에는 피드백 없음)
- **보호 규칙 확인:** `wave1_reasoning_test`(06·08), `wave2_reasoning_test`(07), `final_small_pass_test` 1~16, `post_discovery_pass_test` — **기대값 변경 없이 모두 통과**. 콘텐츠 해시는 ep07만 갱신(ep06·08은 이 해시 목록 밖, 위 규칙 테스트가 보호), 나머지 사건 해시 불변
- **신규 `test/type_b_phase3a_test.dart` (15):** 12개 정답 불변 · 모든 오답 보기에 피드백 · 정답 보기에는 없음 · 미션 안 중복 없음 · Hint 2개 · **보호 규칙을 피드백까지 확장**(06-F: grey/gray/inspector/hat/card 금지, 06 전체: "on your side" 금지, 07 전체: "gate" 금지, 08-F: button/coat/red/miss rose 금지, 08 전체: "miss rose"/"same person" 금지) · Case 03 → 08 Red Button 연결 · 06-M2 카드-모자-증언 경로 · 미션별 오독 피드백 · Essential 11/12 · XP 규칙 3(Case 06 전체를 오답·힌트와 함께 → 500 XP) · 화면 360×640·390×844(06-M2 RED, 08-M2 LILY 오답 시트)
- **갱신한 테스트:** `learning_objectives_test`(분포 40/7/3), `final_small_pass_test`(ep07 해시)
- `flutter analyze` 0 issues, `flutter test` **850 → 865 전부 통과**
- **접근성:** 이번 단계에서 그림 이름 숨김 없음 → 화면 읽기 영향 없음. 06-M2는 수수께끼 경로를 남겨 수첩 회상이 어려운 아이(8~9세)도 진행 가능
- **Essential:** Case 06~08 10 → 11, 시즌 39 → **40 / 50**

### 9-6. 남은 교육적 약점
- **06-F**(Helpful): 보기 중 이야기상 두드러진 인물이 하나라 영어 없이 고를 수 있다. 보기 구성은 보호 규칙(사람만, 4단어 이하) 대상이라 이번에 바꾸지 않음 — 후보: 보기에 "the tall man / the short woman"처럼 같은 수준의 인물 묘사를 두는 안(보호 규칙 재검토 필요)
- **08-M2**: 프롬프트 "MRS _____"가 후보를 두 명(Patel, Robin)으로 좁힌다
- 06-M3(숫자 1자리)·07-M3(6순열)는 찍기 공간이 작다 — 피드백으로 완화했지만 구조는 그대로
- 플레이테스트 미실시

### 9-7. Case 09~11 후속 계획
| Case | 보호 규칙(먼저 확인) | 후보 |
|---|---|---|
| 09 | `case09_reasoning_test`: whose ≠ who had it, Anna의 물건(우산)이 함정, M1 guard's key → Final | 오답 피드백 핵심: `UMBRELLA`("Anna used the key — but whose key was it?"), `BAG`(Ben의 것); M2 알파벳은 Language Independent 유지; M3 "third change" 피드백(10·14) |
| 10 | `wave2_reasoning_test` Case 10: Tower Bridge·north tower·3시를 장면이 미리 말하지 않음, Final 어순 | M3 그림 이름 "Tower Bridge"가 TOWER+BRIDGE와 그대로 일치 → 이름 숨김 후보; Final 어순 피드백(WHO가 처음, WHEN이 끝); M2 요일 피드백 |
| 11 | `wave1_reasoning_test` Case 11: Old Letter 서명(Case 01) → Final, MIDNIGHT·trains 유지, door/under Big Ben 금지 | M3 그림 이름 + 앞 장면 "station that never sleeps" 노출 → 이름 숨김·장면 문구 검토(보호 규칙 확인 필요); M2 역순 철자 Language Independent 유지; Final 보기 피드백(Case 01 Archive로 안내, door 금지) |


---

## 10. Phase 3B — Case 09~11 (**2026-10-12 승인 → 구현 완료**)

> 10-1~10-4는 승인받은 분석·제안 원문이다(승인: Case 09·10·11, 10-M3 Tower of London, 공통 피드백·Hint, 보호 테스트, 화면 읽기 대체 텍스트, 01-M4·04-M3 소급). 실제 결과는 10-5.

### 10-1. 기존 추리 보호 규칙

| Case | 핵심 미스터리 / 결말 | 플레이어가 추론할 것 | 공개 금지 | 보호 테스트 | 사건 간 연결 |
|---|---|---|---|---|---|
| 09 | 보석은 궁 안 누구의 물건에? → Carl의 모자 | M1 "the guard's key" → (열쇠는 Anna가 썼지만) **whose key** = 경비원 Carl → 메모로 Carl의 물건 = 모자 | Final 페이지·Hint에 "guard's", "belongs", "Carl", "hat"(목록 제외) 금지, Final 전 어디에도 "hat(s)" 금지, Final 메모에 Carl·jewel 금지 | `case09_reasoning_test` | Case 08 Empty Jewel Box → 09 intro, Anna의 이름표 까마귀 → 10 |
| 10 | 까마귀의 경고 → THE CLOCKMAKER WILL STOP BIG BEN AT MIDNIGHT | M2 네 단어 → M3 **두 단어를 합친 이름** = Tower Bridge → Final 문장 어순 | M3 전 어디에도 "tower bridge" 금지, M3 편지에 north/tower/bridge/three 금지, M3 첫 Hint에 notebook, **M3 그림 중 네 단어로 만들어지는 이름은 정답 하나뿐** | `wave2_reasoning_test` Case 10, `post_discovery_pass_test` 7~14 | ROW R · SEAT 17 → 11, 경고문 → 12 |
| 11 | 가면 쓴 사람 = The Shadow(Case 01), 이제 조력자 | Case 01 Old Letter 서명("Signed: The Shadow / P.S. I love trains!")을 Archive에서 다시 읽기 | Final 전 "shadow" 금지, Final 보기에 Case 01·thief 금지, 마지막 Hint에 "Case 01", **"door"는 stage door만**, "under Big Ben" 금지(Case 12 수수께끼 정답) | `wave1_reasoning_test` Case 11 | Case 01 Old Letter → 11 Final(R3), Case 04 "never sleeps" → 11-M2 장면, 11 → 12 |

공통: 콘텐츠 해시(`final_small_pass_test`)는 ep09·ep10·ep11을 보호한다(승인 시 갱신). Phase 3A와 같이 **오답 피드백도 위 금지어를 지킨다**(테스트 확장).

### 10-2. 정답 사전 노출과 화면 읽기

- **10-M3 (Tower Bridge 이름표):** 노출이 아니라 **설계된 메커니즘**이다. 편지가 "Two of them, put together, are the name of a place"라고 하고, 보호 테스트가 "그림 이름 중 네 단어로 만들어지는 것은 정답 하나"를 고정한다. 이름을 숨기면 "단어를 합쳐 이름을 만든다"는 영어 퍼즐이 "Tower Bridge가 어떻게 생겼는지 아는가"라는 상식 퍼즐로 바뀌고, 화면 읽기 사용자는 풀 수 없게 된다 → **이름은 숨기지 않는 것을 권장.** 대신 약점(단어 하나만 맞춰도 됨)을 보완: 보기 Big Ben을 **Tower of London**(같은 사건의 장소, 그림 있음)으로 바꿔 "TOWER 하나만 맞는 이름"을 함정으로 둔다 → 두 단어를 모두 확인해야 함. 보호 테스트 조건(네 단어로 만들어지는 이름은 하나)도 그대로 성립(`of`, `london`은 네 단어가 아님).
- **11-M3 (King's Cross 이름표 + 장면):** 편지 "a big station … two big arches and a clock tower"와 보기 중 역은 하나뿐(이름표 "King's Cross")이라 이름만으로 풀린다. → **이름 숨김 제안**(Case 01 M4·04 M3와 같은 방식). 직전 장면 "the station that never sleeps"는 **Case 04에서 배운 표현의 재사용**이라 유지(삭제하지 않음).
- **그림에 이름이 그려져 있음:** 랜드마크 PNG에는 장소 이름 두루마리가 그림 안에 있다(예: "King's Cross", "Big Ben & Houses of Parliament"). 선택 타일이 이 부분을 잘라 보여 주는지 **구현 시 스크린샷으로 확인**한다(01-M4 캡처에서는 잘려 있었음).
- **화면 읽기 대체 단서(제안):** 이름을 숨긴 그림은 지금 "Picture A"로만 읽혀 시각 장애 아이는 풀 수 없다. `ChoiceOption.altText`(이름이 아닌 **그림 묘사**, 편지 문구를 그대로 쓰지 않음)를 추가하고, 이름을 숨긴 타일의 화면 읽기 라벨을 "Picture C, a long building with a great arched glass roof and a clock tower"처럼 읽게 한다. 11-M3 예시(그림을 보고 작성):
  - King's Cross: "a long building with a great arched glass roof and a clock tower"
  - Big Ben: "a very tall clock tower beside a long building with many pointed towers"
  - Buckingham Palace: "a wide grand building with a flag on top and a fountain in front"
  - Hyde Park: "a green park with a lake, small boats and trees"
  - 같은 처리를 **01-M4·04-M3에도 소급** 적용할 수 있다(별도 승인). 공원 지도(Case 07)는 X 위치가 정답이라 대체 텍스트가 곧 답이 되므로 제외.

### 10-3. 미션별 분석과 개선안

| 미션 | 정답 | 현재 분류 | 문제 | 개선 (Hint · 피드백 · 콘텐츠) | 개선 후 |
|---|---|---|---|---|---|
| 09-M1 객관식 | c guard's key | Essential | Hint 역할 뒤바뀜, 피드백 없음 | **H1** "Read the last line: what kind of key opens the jewel case?" **H2** "'The maid's key' means the key that belongs to the maid. Whose key is big and gold?" **피드백** a "The maid's key is small and silver. Which key is big and gold?" / b "The cook's key is old and iron. Read the last line again." / d "The butler names three keys. Is the King's key one of them?" | Essential |
| 09-M2 단어 | ANNA | Helpful(알파벳) | 영어 의존 낮음 — **억지로 바꾸지 않음** | Hint 유지. **피드백만** `AMMA` "Say the alphabet: which letter comes AFTER M?" / `ALLA` "L comes before M. Which letter comes after it?" | Helpful 유지 |
| 09-M3 숫자 | 12 | Essential | Hint 역할 뒤바뀜 | **H1** "Read the timetable: when is the first change? How often do the guards change?" **H2** "'Every two hours' means add two hours each time. 'The third change' counts the first one too." **피드백** `10` "That is the second change. Count three: the first is at eight." / `14` "Count again: the first change is at eight o'clock." / `6` "'Every two hours': add two hours each time." / `3` "'The third change' asks for a time, not how many." | Essential |
| 09-F 단어 | HAT | Essential | Anna의 물건(우산)이 대표 함정인데 진단 없음 | Hint 유지(보호). **피드백**(guard's·belongs·Carl·hat 금지 준수) `UMBRELLA`·`RED UMBRELLA` "That is Anna's thing. The note says the one WHOSE key you used: was it Anna's key?" / `BAG`·`GREEN BAG` "The green bag is Ben's. Did Ben's key open the jewel case?" / `ANNA` "The note asks for a thing, not a person." | Essential |
| 10-M1 객관식 | c Poppy | Essential | H2가 거의 정답 | **H2** "'The smallest' means smaller than all the others. Find the raven that is small, quiet AND has a ring." **피드백** a "Jubilee is the biggest raven. Your raven is small." / b "Merlin has a white feather. Does the note say she has a gold ring?" / d "Harris is very noisy. Your raven is quiet." | Essential |
| 10-M2 순서 | north, tower, bridge, three | Essential | Hint 역할 뒤바뀜 | **H1** "Find the Monday word first." **H2** "The days of the week go: Monday, Tuesday, Wednesday, Thursday." **피드백** 노트에 적힌 순서(bridge, north, three, tower) "That is the order of your notes, not the order of the days. Which day comes first?" / 그 외 "Start with Monday. Which day comes after Monday?" | Essential |
| 10-M3 그림(이름 있음) | c Tower Bridge | Helpful | 단어 하나만 맞춰도 됨 | **보기 b: Big Ben → Tower of London**(그림 있음, 정답 id 그대로). **이름은 숨기지 않음**(위 10-2). H1 유지(보호: notebook). **H2** "'Put together' means two words side by side make one name. One word alone is not enough." **피드백** a(London Eye) "Is 'London' or 'Eye' one of Poppy's words? Check your notebook." / b(Tower of London) "Only one of Poppy's words is in this name. The note says TWO, put together." / d(King's Cross) "Is 'King's' or 'Cross' one of Poppy's words?" | Helpful 유지(정직한 분류: 단어 조합 수준) |
| 10-F 순서 | clockmaker, stop, bigben, midnight | Essential | H2가 거의 정답, 어순 진단 없음 | **H1** "The note asks four questions in order. Match one paper to each question." **H2** "'Who' is a person. 'Will stop' is what they will do. 'When' is a time." **피드백** `midnight,clockmaker,stop,bigben` "'At midnight' is WHEN. The note says WHEN comes last." / `clockmaker,bigben,stop,midnight` "After WHO comes what they WILL do." / `bigben,stop,clockmaker,midnight` "Big Ben is not a person. The note starts with WHO." / 그 외 순서 "Read the note: WHO, then WILL do, then to WHAT, then WHEN." | Essential |
| 11-M1 객관식(3) | c the child | Essential | H2가 관계만 | **H2** "'Does not agree' means says something different. Two stories say the same thing; find the other one." **피드백** a "The usher and the actor tell the same story: a white mask, a black cloak." / b "The actor agrees with the usher. Which story is different?" | Essential |
| 11-M2 단어 | MIDNIGHT | Low(역순 철자) | 영어 의존 낮음 — **억지로 바꾸지 않음** | Hint 유지. **피드백만** `THGINDIM` "That is the word as it is written. Read it from right to left." | Low 유지 |
| 11-M3 그림 | a King's Cross | Helpful | 이름표 + "station"으로 풀림 | **이름 숨김**(+ 화면 읽기 대체 단서, 10-2). **H1** "Read what the driver saw: a big station, two big arches, a clock tower. Look for all three." **H2** "A station is where trains stop. Arches are big round shapes, like the top of a tunnel." **피드백**(door 금지 준수) b(Palace) "A palace with a flag. Does it have big arches and a clock tower?" / c(Hyde Park) "A park has no clock tower. Read the driver's words again." / d(Big Ben) "A tall clock tower, yes. But where are the two big arches?" | **Essential** |
| 11-F 객관식 | d The Shadow | Essential | 피드백 없음 | Hint 유지(보호: 마지막 = Case 01). **피드백**(shadow·door 금지 준수) a "Inspector Grey helped you in Case 06. Did he leave you a letter at the very start?" / b "Mrs Robin had a suitcase in Case 08. But 'the very start' is your first case." / c "The Ravenmaster sent words with Poppy. Who signed the letter in your first case?" | Essential |

**개선 후:** Case 09~11 Essential 8 → **9**(11-M3). 시즌 **40 → 41 / 50** (분포 41 / 6 / 3).

### 10-4. 추가 테스트 (승인 시)
- 12개 정답 불변, 모든 선택형 오답 보기에 피드백·정답 보기엔 없음, 미션 안 중복 없음, Hint 2개
- 보호 규칙의 피드백 확장: 09 전체 "hat(s)" 금지·09-F guard's/belongs/carl 금지, 10-M3 전 "tower bridge" 금지, 11 전체 "shadow"·"under big ben" 금지, "door"는 stage door만
- 10-M3: 네 단어로 만들어지는 이름은 정답 하나(Tower of London 함정 포함), 이름 표시 유지
- 11-M3: 이름 숨김, 화면 읽기 라벨에 이름 없음·대체 묘사 있음(승인 시), 그림 속 이름 두루마리가 타일에서 잘림(스크린샷 확인)
- Case 01 → 11 Old Letter 서명, Case 08 → 09 보석 상자 연결 불변
- XP 규칙 3, 화면 360×640·390×844

### 10-5. 구현 결과

**제안과의 차이 (1건)**

| 위치 | 제안 | 실제 | 이유 |
|---|---|---|---|
| 09-F 피드백 `UMBRELLA`·`GREEN BAG` | "**That** is Anna's thing. …" / "**That** is Ben's bag. …" | "**This** is Anna's thing. …" / "**This** is Ben's bag. …" | 시즌 공통 규칙(`type_b_cases_test`: 피드백·Hint를 정규화했을 때 정답이 들어 있으면 안 됨)이 "t**HAT**"을 정답 HAT으로 잡았다. Case 09의 기존 Hint 규칙도 같은 검사(정규화 후 HAT 금지)를 쓴다. 테스트를 완화하지 않고 문구를 바꿈 |

**코드 변경 (승인된 화면 읽기 대체 텍스트)**
- `lib/data/models/mission.dart`: `ChoiceOption.altText`(선택, 관대한 파싱, 값이 있을 때만 JSON 기록)
- `lib/features/mission/widgets/question_widgets.dart`: 이름을 숨긴 그림 타일의 화면 읽기 라벨 = "Picture C: <그림 묘사>" (이름이 보이는 타일은 기존대로 "Picture C, <이름>", 묘사가 없으면 "Picture C")
- 대체 텍스트는 **그림마다 하나**(같은 그림은 어디서나 같은 문장), 장소 이름·편지 문장을 쓰지 않음. 그림을 직접 보고 작성:

| 그림 | 대체 텍스트 | 쓰는 곳 |
|---|---|---|
| King's Cross | a long building with a great arched glass roof and a clock tower | 11-M3 |
| Big Ben | a very tall clock tower beside a long building with many pointed towers | 01-M4, 11-M3 |
| Buckingham Palace | a wide grand building with a flag on top and a fountain in front | 01-M4, 04-M3, 11-M3 |
| Hyde Park | a green park with a lake, small boats and trees | 11-M3 |
| Tower Bridge | two tall towers joined by a road across a river, with boats below | 01-M4 |
| London Eye | a giant wheel with little cabins, beside a river | 01-M4, 04-M3 |
| Tower of London | an old fortress with many square towers and high walls | 04-M3 |
| British Museum | a large building with tall columns and a round dome | 04-M3 |

- **그림 속 이름 두루마리 확인:** 11-M3 화면 스크린샷(390×844)에서 타일이 랜드마크 그림의 이름 두루마리를 잘라 보여 주는 것을 확인(King's Cross·Big Ben 모두 이름 없음)

**수정 파일:** `episode09_mock.dart`, `episode10_mock.dart`, `episode11_mock.dart`, `episode01_mock.dart`·`episode04_mock.dart`(대체 텍스트만), `season1_learning.dart`(11-M3 → essential, 10-M3 설명 갱신), `mission.dart`, `question_widgets.dart`

**보호 규칙:** `case09_reasoning_test`, `wave2_reasoning_test`(Case 10), `wave1_reasoning_test`(Case 11), `post_discovery_pass_test` — **기대값 변경 없이 모두 통과**

**테스트**
- 신규 `test/type_b_phase3b_test.dart` (13): 12개 정답 불변 · 오답 보기 피드백(정답 보기 없음) · 미션 안 중복 없음 · Hint 2개 · 보호 규칙의 피드백 확장(09: hats? 금지·Final guard's/belongs/carl/HAT 금지, 10: M3 전 "tower bridge" 금지·이름은 퍼즐이므로 유지·네 단어 이름은 정답 하나·Tower of London 함정, 11: shadow·door·"under big ben" 금지) · 사건 간 연결(01 → 11, 08 → 09, 04 → 11) · 이름 숨긴 모든 그림(01-M4·04-M3·11-M3)에 대체 텍스트·이름 미포함·편지 미복사·그림별 일관 · 11-M3 화면 2 크기(이름 없음, 화면 읽기 "Picture A: a long building…", "King's Cross" 라벨 없음) · 미션별 오독 피드백 · Essential 9/12·시즌 41/50 · XP 규칙 3(Case 10 → 500 XP)
- 기대값 갱신(모두 승인된 변경 때문): `final_small_pass_test` 해시(ep01·04·09·10·11 — 나머지 불변), `full_playthrough_test`·`ui_tour_test`(01-M4 화면 읽기 라벨이 "Picture C: …"가 됨), `type_b_phase2_test`(04-M3 라벨 "Picture B: …"), `new_artwork_test`(이름 있는 예시 11-M3 → 10-M3, 11-M3는 이름 없는 쪽), `learning_objectives_test`(분포 41/6/3)
- `flutter analyze` 0 issues, `flutter test` **865 → 878 전부 통과**

### 10-6. Season 1 최종 분포 (50개)
| 의존도 | 처음(P0) | 현재 |
|---|---|---|
| Essential | 32 | **41** |
| Helpful | 13 | **6** (03-M1 장면 소개, 04-F 시즌 모티프, 06-F 보기 구성, 09-M2 알파벳, 10-M3 이름 조합, 12-M3 Big Ben 서사) |
| Low | 5 | **3** (01-M5 QR, 01-F 튜토리얼 기호, 11-M2 역순 철자) |

### 10-7. 남은 교육적 약점
- Helpful 6개는 각각 이유가 있어 유지했지만, 영어 없이 도달 가능한 경로가 남아 있다(위 표)
- 선택형은 여전히 최대 3번이면 반드시 풀린다. XP 규칙 3으로 찍기가 보상받지는 않지만, 찍기 자체를 막지는 않는다(의도된 무벌점 설계)
- 언어 난이도 성장(감사 §6: 문장 길이가 사건 1~12 내내 평평)은 이번 단계들에서 다루지 않았다
- 피드백·대체 텍스트·Hint의 효과는 전부 가설: **실기기·어린이 플레이테스트 필요**(`WORLD_MYSTERY_LEARNING_PLAYTEST.md`)
  - 실기기: 화면 읽기(TalkBack / VoiceOver)로 01-M4·04-M3·11-M3를 실제로 풀 수 있는지, 한글 글꼴이 있는 부모 보고서, 360×640 기기에서 01-M1의 Tip 링크 스크롤
  - 어린이: 피드백을 읽는가, 06-M2에서 Notebook 증언을 다시 찾는가, 09-F 우산 함정, 10-M3 Tower of London 함정, Second Look 유도 위험


---

## 11. Phase 4 — Notebook & Cross-Case (근거: Notebook·Cross-Case 감사 2026-10-12, 문서는 2026-10-28 정리 시 삭제 — git 이력 참조)

### 11-1. P1-2 Notebook 영어 단어 뜻 조회 (**승인 → 구현 완료**)

- **재사용:** 미션 화면의 `GlossaryText`(점선 밑줄 → 탭 → WORD CARD)와 `showWordMeaning`을 그대로 쓴다. 새 화면·탭·단어장 없음.
- **원래 사건의 단어 데이터:** `GlossaryText`에 선택 매개변수 `episode` 추가(없으면 기존대로 현재 사건). 증거·단서가 발견된 사건은 `caseOfEvidence` / `caseOfClue`(`game_providers.dart`)로 찾는다(시즌 전체에서 id가 사건 하나에만 속함을 테스트로 고정).
- **적용 위치:** 증거 상세(설명·글귀) — 수첩·Case Archive·Final 수첩 시트에서 여는 증거 상세는 모두 같은 화면이라 Discovery·Story에서 연 증거 상세에도 같이 적용된다 / 단서 카드 메모(수첩·Archive·Final 수첩).
- **기록 연동:** 뜻 보기는 미션과 같은 `GameController.lookUpWord`를 부른다 → `lookedUpWords`(부모 보고서)와, 기록 중인 실행이면 `behavior.words`(**Word Collector**, 같은 단어는 한 번)에 쌓인다. 옛 세이브(`behavior` 없음)는 기존처럼 `lookedUpWords`에만 — 저장 형식 변경 없음.
- **부모 보고서:** 다른 사건 증거에서 찾아본 단어도 뜻이 보이도록, 현재 사건 glossary에 없으면 그 단어가 있는 사건의 glossary로 찾는다.
- **화면 읽기:** 뜻이 있는 단어는 미션 화면과 같이 "word (tap for meaning)"으로 읽힌다(기존 동작).

### 11-2. P1-1 Operator Mode Archive 참고 공개 (**승인 → 구현 완료**)

- Operator Mode가 켜져 있으면 **열려 있는 사건 외의 모든 사건 파일**이 `REFERENCE` 도장과 함께 전체 Evidence·Clue를 보여 준다(`ArchiveStatus.reference`).
- **지급 없음:** 해결 기록·XP·Evidence(세이브의 `completedMissionIds`)·Badge를 만들지 않는다. 참고 파일의 증거를 열어도 **Notebook Explorer·Second Look 기록이 남지 않는다**(탐정이 찾은 증거가 아니므로).
- **열려 있는 사건은 그대로**(찾은 것만) — 현재 사건의 정답을 미리 보여 주지 않기 위해. Case 01~12 중 지금 하는 사건만 예외.
- Final 수첩 시트의 `OPEN THE CASE ARCHIVE`도 Operator Mode에서 보인다.
- **일반 플레이는 그대로:** Operator Mode가 꺼져 있으면 잠금 규칙 불변(테스트).

### 11-3. 변경 파일 · 테스트

| 파일 | 변경 |
|---|---|
| `lib/widgets/glossary_text.dart` | `episode` 매개변수 |
| `lib/features/game/game_providers.dart` | `caseOfEvidence`, `caseOfClue` |
| `lib/widgets/evidence_card.dart` | 증거 상세의 설명·글귀 → 그 증거 사건의 `GlossaryText` |
| `lib/widgets/clue_card.dart` | 단서 메모 → 그 단서 사건의 `GlossaryText` |
| `lib/features/notebook/season_archive.dart` | `ArchiveStatus.reference`, Operator 참고 공개, 참고 파일은 행동 기록 없음 |
| `lib/features/mission/final_mission_screen.dart` | Operator Mode에서 Archive 링크 표시 |
| `lib/features/result/parent_report_screen.dart` | 찾아본 단어의 뜻: 다른 사건 glossary로 대체 조회 |

- 신규 `test/notebook_cross_case_test.dart` (11): 증거·단서 → 사건 매핑(시즌 전체), Case 12에서 Archive의 Case 04 봉인 글귀 "wax" → **Case 04 glossary**의 뜻("밀랍" — Case 12 glossary에는 없음) + `lookedUpWords`·`behavior.words` 기록(360×640·390×844), 단서 메모의 단어 카드(2 크기), Word Collector가 수첩 조회를 같은 단어 한 번으로 셈, Operator 참고 공개(현재 사건은 찾은 것만, 해결 기록 없음), Operator 꺼짐 = 잠금 유지, Case 08에서 Case 03 Red Button 참고 열람 → 행동 기록·완료·배지·해결 없음(2 크기)
- 기대값 갱신 이유: 증거 상세·단서 메모가 **뜻 보기가 되는 rich text**가 되어, `find.text`가 화면 읽기 라벨("pressed (tap for meaning)")까지 읽는다. 내용 단정은 그대로 두고 **화면에 보이는 글자로 찾는 `findReadable`**(`test/helpers.dart`)로 바꿨다: `final_small_pass_test`, `wave1_reasoning_test`, `wave2_reasoning_test`, `case09_reasoning_test`, `new_artwork_test`, `post_discovery_pass_test`, `season_archive_test`. 보호 규칙·기대 문구는 하나도 바꾸지 않음
- 화면: 360×640·390×844 스크린샷으로 증거 상세(점선 밑줄, CLOSE 화면 안)와 Operator 참고 열람 확인
- `flutter analyze` 0 issues, `flutter test` **878 → 889 전부 통과**

### 11-4. P1-3 / P1-4 (**A·B·C 승인 → 구현 완료**, 아래는 승인된 제안 원문 — 실제 차이는 11-5)

선정: Case 12에는 **before/after(Case 02)**와 **whose(Case 09)** 두 가지. 위치 전치사(Case 07)는 Case 12 흐름(시계탑·역·탑·문)에 퍼즐로 자연스럽게 들어갈 자리가 없어 제외(억지로 넣으면 문장만 길어짐).

**(A) 12-M2 — after (Case 02의 시간 순서 표현)**

| | 현재 | 제안 |
|---|---|---|
| 도착판 | 10:15 from York — Platform **2** / 11:04 Edinburgh — 9 / 11:40 Paris — 4 / 11:55 Oxford — 7 | 10:15 from York — Platform **4** (나머지 그대로) |
| Grey의 말 | "The Clockmaker always arrives on the platform with the small red clock." | "The Clockmaker always arrives on the platform with the small red clock, **after the train from Edinburgh**." |
| Hint 2 | "Find that platform on the board. Type its time as four numbers." | "Two trains come in on that platform. '**After** the train from Edinburgh' means later than that train." |
| 피드백 `1015` | "That train comes in on another platform…" | "That train comes in on Platform 4 too, but **before** the Edinburgh train. Grey says **after**." |

- 학습 목적: Case 04의 "small red clock"(R3, 그대로) + Case 02의 before/after를 실제 시간표 읽기에 적용. 두 조건이 모두 필요해짐.
- 정답: **1140 그대로**. 증거 글귀 "11:40 from Paris — Platform 4", 단서 "Platform 4", 다음 장면 그대로.
- 정답 노출 위험: 없음 — "after the train from Edinburgh"만으로는 11:40과 11:55가 남고, 승강장(Case 04)이 있어야 하나로 정해짐.
- 영향 테스트: `type_b_cases_test`(12-M2 `1015` 피드백 단정 "Case 04" → 새 문구로), `final_small_pass_test`(ep12 해시), `learning_objectives_test`(12-M2 표현 추가), `wave1_reasoning_test` "Platform 4 stays, for Case 12"(letter에 small red clock·Hint 1에 Case 04 — **그대로 통과 예상**)

**(B) 12-F — whose (Case 09의 소유 관계)**

| | 현재 | 제안 |
|---|---|---|
| 문 첫 줄 | "The first lock: the platform number of his train." | "The first lock: the number of the platform **whose clock is small and red**." |
| Hint 2 | "The first lock asks about his train. Which platform did the Clockmaker arrive on?" | "'The platform **whose** clock is small and red' means the platform that has the small red clock." |

- 학습 목적: Case 09의 "the one whose key you used"와 같은 구조를 새 상황에서 다시 읽기. 답은 이번 사건 M2 단서(Platform 4)와 Case 04 증거 둘 다로 확인 가능.
- 정답: **487 그대로**. 자물쇠 순서·두 번째·세 번째 줄·PARIS 결말 그대로.
- 정답 노출 위험: 낮음 — 문장이 "4"를 말하지 않음(small red clock은 M2에서 이미 나온 표현).
- 영향 테스트: `type_b_cases_test`(12-F letter 단정 문구 → 새 문구로), `type_b_rewards_test`·`type_b_phase3b_test`(영향 없음 예상), `learning_objectives_test`(12-F 표현 갱신), `final_small_pass_test`(ep12 해시)

**(C) 11-M3 — "never sleeps" 연결 (P1-4)**

| | 현재 | 제안 |
|---|---|---|
| Hint 1 | "Read what the driver saw: a big station, two big arches, a clock tower. Look for all three." | "The guard said 'the station that **never sleeps**'. Where did trains 'never sleep' in Case 04?" |
| Hint 2 | "A station is where trains stop. Arches are big round shapes, like the top of a tunnel." | 그대로 |

- 학습 목적: Case 04 M1에서 배운 비유 "where trains never sleep"(그 사건의 무대 = King's Cross, 그림도 Case 04에서 봄)을 Case 11에서 다시 해석 → **표현 재등장이 실제 추리 단서**가 됨. 그림 이름은 계속 숨김.
- 정답: **a 그대로**. 장면(M2) 문구·M3 편지 불변.
- 정답 노출 위험: 낮음 — Hint가 장소 이름을 말하지 않음(시즌 공통 규칙: Hint에 정답 문자열 금지). Case 11 보호 규칙(shadow·door·"under big ben" 금지) 위반 없음.
- 영향 테스트: `final_small_pass_test`(ep11 해시), `learning_objectives_test`(11-M3 → recall, recallFrom ep04_m1, 표현 "the station that never sleeps"), `wave1_reasoning_test` Case 11(door 규칙 — 통과 예상)

**예상 결과:** 정답·Evidence·결말 불변. Essential 수 41 유지(12-M2·12-F·11-M3는 이미 Essential), 사건 간 **영어 표현** 재사용(R3급) 1곳(06 → 11 agree) → 4곳(+ 02 → 12 after, 09 → 12 whose, 04 → 11 never sleeps).

### 11-5. P1-3 / P1-4 구현 결과

**제안 대비 차이 (조건 5 "Archive를 볼 수 없을 때도 Hint로 진행"을 위해)**

| 위치 | 제안 | 실제 | 이유 |
|---|---|---|---|
| 12-M2 Hint 2 | "Two trains come in on that platform. 'After the train from Edinburgh' means later than that train." | "**The small red clock was on Platform 4 in Case 04.** Two trains come in there: 'after the train from Edinburgh' means the later one." | Archive를 열 수 없는 아이도 진행할 수 있도록 Tip 2가 Case 04의 사실을 직접 알려 줌. 시각(1140)은 말하지 않음 — 도착판을 "after"로 읽어야 함 |
| 12-M2 피드백 `1104`·`1155` | (제안 표에 없음) | `1104` "That is the Edinburgh train itself. The Clockmaker comes after it, on another platform." / `1155` "That train comes after Edinburgh, but on another platform. Which one has the small red clock?" | 승강장이 바뀐 도착판에 맞게 두 줄도 갱신. 오독마다 다른 문장(시즌 규칙) |

**검증한 논리 (테스트로 고정, `cross_case_language_test`)**
- 12-M2: 도착판을 실제로 파싱 — 4번 승강장 열차 **둘**(10:15 York, 11:40 Paris), Edinburgh 11:04는 9번. "after the train from Edinburgh" → 4번 중 11:04 이후는 **11:40 하나** = 정답 1140. "after"만으로는 둘(11:40, 11:55)이 남아 Case 04 단서도 필요. 증거 "11:40 from Paris — Platform 4", 단서 "came in on Platform 4, from Paris", 장면 "At 11:40", 사건 시작 "11:00 PM", Discovery "The small red clock is on Platform 4: the train from Paris"와 모순 없음
- 12-F: "the number of the platform whose clock is small and red" — Case 09 "the one whose key you used"와 같은 whose + 명사 구조. 문·Hint·피드백 어디에도 숫자 없음. 정답 487·자물쇠 기호 없음·PARIS 결말·Clockmaker's Watch 불변. Archive 없이도 이번 사건 M2 단서 "Platform 4"로 답할 수 있음
- 11-M3: Hint 1 "The guard said 'the station that never sleeps'. Where did trains 'never sleep' in Case 04?" ↔ Case 04 M1 편지 "Meet me where trains never sleep." · 단서 "The platforms never sleep. They are open day and night." · Case 04 무대 그림 = King's Cross. Hint에 장소 이름 없음, Case 11 금지어(shadow·door) 없음, 그림 이름 계속 숨김. Archive 없이도 Hint 2·택시 기사의 묘사(arches, clock tower)로 진행

**수정 파일:** `episode12_mock.dart`(도착판 York → Platform 4, Grey의 말에 "after the train from Edinburgh", M2 Hint 2·피드백 3줄, Final 첫 줄·Hint 2), `episode11_mock.dart`(M3 Hint 1), `season1_learning.dart`(12-M2 표현 + "after the train from Edinburgh", 12-F 표현 "the platform whose clock is small and red"·skill grammarInContext, 11-M3 → recall ← ep04_m1, 표현 + "the station that never sleeps"·"Meet me where trains never sleep")

**테스트**
- 신규 `test/cross_case_language_test.dart` (15): 도착판 논리(위), 증거·단서·장면 일치, Hint의 Archive 경로와 Archive 없는 경로·정답 미노출, 시각별 피드백, whose 구조·숫자 미노출·결말 불변, never sleeps ↔ Case 04 원문·그림, 장소 이름·금지어 없음, 학습 데이터, XP 규칙 3(Case 12 → 500), 화면 360×640·390×844(12-M2 10:15 피드백 + 늘어난 도착판 편지 시트, 11-M3 Tip)
- 기대값 갱신: `type_b_cases_test`(Phase 1에서 만든 12-M2 피드백·12-F 첫 줄 단정 → 승인된 새 문구), `final_small_pass_test`(ep11·ep12 해시 — 나머지 불변)
- 기존 보호 테스트(`wave1_reasoning_test` Case 11·"Platform 4 stays, for Case 12" 등) 기대값 변경 없이 통과
- 영향 없음 확인: 저장 형식(콘텐츠만 변경), Operator Mode(코드 변경 없음), XP 규칙 3(테스트)
- `flutter analyze` 0 issues, `flutter test` **889 → 904 전부 통과**

**사건 간 영어 표현 재사용(R3급):** 06 → 11 agree, **02 → 12 after**, **09 → 12 whose**, **04 → 11 never sleeps** (1곳 → 4곳). Essential 41 / 50 그대로.

**남은 문제**
- 12-M2 Tip 2가 Case 04 사실을 직접 말하므로, Tip 2를 연 아이에게는 Case 04 회상이 필요 없어진다(조건 5를 위한 의도된 절충)
- 위치 전치사(Case 07)는 여전히 이후 사건에서 재사용되지 않음
- 360×640에서 12-M2 편지가 한 줄 길어져 편지 시트 스크롤이 조금 늘어남(시트는 원래 스크롤됨, 오류 없음)
- 실기기·어린이 플레이테스트 미실시
