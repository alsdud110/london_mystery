# London (Season 1) 게임성 전수조사 및 개선안

> 작성일: 2026-10-30 · 기준 커밋: `eb420a9` (main, clean)
> 범위: Season 1 London · Season 2 Paris · Season 3 Rome · Season 4 New York의 모든 Case / Mission / Final (총 194개 퍼즐)
> 성격: **조사·제안 문서**. 이 문서를 쓰는 동안 코드, 퍼즐 데이터, 이미지, 테스트는 수정하지 않았다. Season Factory, `flutter test`, `flutter analyze`는 실행하지 않았다.
>
> 표기
> - **[확인]**: 실제 코드나 데이터를 읽어 확인한 사실 (경로 또는 클래스명 표기)
> - **[추정]**: 코드에서 추론했지만 실제 화면에서 플레이해 보지는 않은 내용
> - **[제안]**: 이 문서가 제안하는 변경
> - 통계는 미션 데이터의 `type`과, `SeasonCatalog`에서 그 미션 ID로 조회되는 장면 테이블을 기준으로 계산했다. 화면을 직접 실행해 측정한 값은 아니다.

---

## 0. 조사 방법

1. **실제 화면 분기 확인**: `lib/features/mission/mission_screen.dart`(`build`, 약 1436–1560행)는 미션마다 `SeasonCatalog.xxx(m)` 장면 테이블을 차례로 조회한다. 값이 있으면 그 장면 위젯을 띄우고, 없으면 `_PuzzleStage` → `puzzleFor()`(`question_widgets.dart`)로 기본 위젯(객관식·입력·순서 등)을 띄운다. 파이널은 `final_mission_screen.dart`가 같은 방식으로 분기한다(`lockBox`, `canvasChoice`, `evidenceBoard`, `easySteps` 등).
2. **장면 테이블 매핑**: 시즌마다 `SeasonContent`(`lib/data/mock/season_catalog.dart`)에 등록된 테이블을 미션 ID 기준으로 모두 뽑았다.
   - London: `season1_explores / inspections / deductions / decodes / clocks / investigations / dialogues.dart`
   - Paris: `season2_scenes.dart`, `season2_case03~12_scenes.dart`
   - Rome·NY: `lib/data/generated/s3_rome/*.g.dart`, `s4_newyork/*.g.dart`의 `Explores / Investigations / Dialogues / TalkMissions`
3. **우선순위 확인**: 한 미션에 테이블이 여러 개 걸려 있으면 `mission_screen.dart`의 `switch (_stage)` 순서가 실제로 보이는 화면을 결정한다. `easySteps`는 Paris 장면 테이블보다 뒤에 있지만, Paris Case 04·05·07에서 easy로 바뀐 미션은 원래 장면 테이블에서 해당 키가 빠져 있다(`season_catalog.dart:462-463` 주석). **[확인]**
4. **난이도**: Rookie / Junior / Master에서는 문장만 바뀌고 구조·정답·선택지 순서는 같다(`docs/DIFFICULTY_IMPLEMENTATION.md` A절, `SeasonCatalog._pick`). 그래서 퍼즐 유형 통계는 난이도와 무관하다. **[확인]**
5. **이미지**: London 이미지 59개의 목록을 확인했고, 장면 이미지 4장(보트하우스, Great Court, 대합실, 분장실)은 직접 열어 무엇이 그려져 있는지 확인했다.
6. **분류 원칙**: 사용자 요청대로 *엔진 클래스*가 아니라 **플레이어가 실제로 하는 행동**으로 분류했다(3-1절).

---

## 1. 전체 조사 요약

### 1-1. 핵심 결론 (한 줄씩)

1. **London은 Case 01만 "게임"이고, Case 02부터는 대부분 "편지 읽고 → 문제 풀기" 형식이다.** Case 01의 6개 퍼즐 중 5개는 장면을 탐색하는 전용 엔진(Explore / Lens / Deduction / Decode / Symbol Lock)을 쓴다. Case 02–12의 44개 중 장면 엔진을 쓰는 것은 **3개**(ep02_m1 시계, ep03_m1 수색, ep06_m1 증언)뿐이고, 나머지 **41개(93%)**는 기본 선택지·입력 위젯이다. **[확인]**
2. **London의 *텍스트 설계* 품질은 높다.** 오답마다 무엇을 잘못 읽었는지 알려 주는 피드백이 달려 있고(TYPE B 설계), 여러 Case에 걸친 증거 재활용(ep08 최종: 빨간 단추, ep11 최종: Case 01 편지, ep12: Case 02·04·05 단서)과 영어 구조 학습(전치사, 반대말, 질문 만들기, 문장 순서)이 잘 짜여 있다. **문제는 내용이 아니라 상호작용 방식이 단조롭다는 점이다.** **[확인]**
3. **Paris는 4개 시즌 중 상호작용이 압도적으로 다양하다.** 48개 중 기본 입력·선택형은 4개(8%)뿐이다. 장면 조작, 비교·대조, 경로, 증거 보드, 단계형(EasySteps), 증거 제시 대화가 고르게 섞여 있다. 다만 상당수 엔진이 그 Case 전용이라 재사용하기 어렵다. **[확인]**
4. **Rome·NY(Season Factory 생성)도 London Case 02–12와 비슷하게 단조롭다.** 기본 입력·선택형 비중이 Rome 88%, NY 79%다. 다만 앞뒤에 인물 대화(TalkMission)를 붙여 "사람을 만나는" 느낌을 보강했다(Rome 18개, NY 7개). London에는 TalkMission이 **0개**다. **[확인]**
5. **London의 장소 이미지는 대부분 분위기용 배경이다.** 퍼즐 단서(물건·발자국·사람)가 그려져 있지 않아, 장면 탐색형으로 바꾸려면 대부분 **새 이미지가 필요**하다. 예외는 Case 01 전용 이미지 5장, `british_museum_gallery_8.png`, `covent_garden_market_hall.png`, `clock_face.png`, 인물 6장이다. **[확인: 4장 직접 열람 / 나머지 추정]**
6. **London은 노트북 증거 호출(`Mission.recall`, EvidenceRecallDock)을 한 번도 쓰지 않는다.** 이전 Case 증거를 써야 하는 퍼즐이 많은데도 힌트 문장("Open your notebook…")으로만 안내한다. Paris 2회, Rome 9회, NY 2회. **[확인]**
7. **추천: B안(균형 개선) 중 "1차 묶음"부터 시작.** 첫 3개 Case(특히 Case 02·03)의 퍼즐 4–5개와 Case 07·08·11의 "몸으로 하는" 퍼즐을 이미 있는 엔진으로 바꾸고, 데이터만 손대면 되는 개선(recall, 심볼 다이얼)을 함께 적용한다. **사건 줄거리·정답·미션 ID·저장 구조는 그대로 둔다.**

### 1-2. 숫자 요약

| 지표 | London | Paris | Rome | New York |
|---|---:|---:|---:|---:|
| 퍼즐 수 (Mission + Final) | **50** (Case 01 = 6) | 48 | 48 | 48 |
| 플레이 방식 유형 수 (3-1절 P1–P16 기준) | 10 | 11 | 8 | 8 |
| 기본 입력·선택형 (P1–P7) | **43 (86%)** | 4 (8%) | 42 (88%) | 38 (79%) |
| ㄴ Case 02 이후만 보면 | **41/44 (93%)** | — | — | — |
| 그 가운데 "글 선택지 탭"(P1) | **16 (32%)** | 1 (2%) | 7 (15%) | 9 (19%) |
| 장면 탐색·조작·관찰 (P8·P9·P11·P13) | 6 (12%) | 17 (35%) | 4 (8%) | 6 (13%) |
| 대조·연결 추론 (P10·P12·P14·P16) | 1 (2%) | 14 (29%) | 2 (4%) | 4 (8%) |
| 단계 안내형 EasySteps (P15) | 0 | 13 (27%) | 0 | 0 |
| 그림 위를 직접 탭·드래그하는 퍼즐 | 6 (12%) | 약 44 (92%) [추정] | 4 (8%) | 6 (13%) |
| 인물 대화 (Dialogue + TalkMission + CaseTalk) | 1 | 6 | 20 | 11 |
| 노트북 증거 호출 `recall` | **0** | 2 | 9 | 2 |
| 한 Case 안에서 같은 조작이 연속된 구간 | 4곳 | 2곳 (EasySteps) | 다수 [추정] | 다수 [추정] |

---

## 2. 4개 시즌 퍼즐 유형 통계

### 2-1. 데이터상의 `MissionType` 분포 (엔진 기준, 참고용)

`MissionType`은 `lib/data/models/mission.dart`의 enum이다. 정답 검사 방식만 정할 뿐, **플레이어가 보는 화면은 장면 테이블이 결정**하므로 이 표는 체감 유형과 다르다.

| MissionType | London | Paris | Rome | NY |
|---|---:|---:|---:|---:|
| multipleChoice | 20 | 18 | 13 | 19 |
| wordInput | 9 | 0 | 8 | 8 |
| numberCode | 4 | 1 | 0 | 0 |
| imageChoice | 7 | 0 | 3 | 6 |
| sequence | 5 | 2 | 11 | 5 |
| finalCode | 4 | 0 | 5 | 2 |
| letterLock | 0 | 1 | 8 | 8 |
| examine | 1 | 8 | 0 | 0 |
| matchPairs | 0 | 15 | 0 | 0 |
| spotDifferences / revealLayer / canvasChoice | 0 | 3 | 0 | 0 |
| **합계** | **50** [주1] | **48** [주2] | **48** | **48** |

- [주1] London: m01(MC+Explore), m02(wordInput+Lens), m03(MC+Deduction), m04(imageChoice), m05(examine+Decode), final(finalCode)이 포함된 수치다.
- [주2] Paris는 `matchPairs`·`multipleChoice`를 "정답 문자열을 담는 그릇"으로만 쓴다. 실제 화면은 18종 이상의 전용 장면이다. 같은 `matchPairs`라도 기어 끼우기, 해시계 그림자 맞추기, 드럼 테이프 찾기는 완전히 다른 놀이다. **엔진 이름으로 세면 다양성을 크게 잘못 읽게 된다는 대표 사례다.**

### 2-2. 실제 플레이 방식(P코드) 분포

P코드 정의는 3-1절 표를 참고한다.

| P코드 | 플레이 방식 | London | Paris | Rome | NY |
|---|---|---:|---:|---:|---:|
| P1 | 글 선택지 탭 | **16** | 1 | 7 | 9 |
| P2 | 그림 카드 고르기 | 7 | 1 | 3 | 6 |
| P3 | 단어 타이핑 | 8 | 0 | 8 | 8 |
| P4 | 숫자 키패드 | 3 | 0 | 0 | 0 |
| P5 | 순서대로 버튼 탭 | 5 | 1 | 11 | 5 |
| P6 | 숫자 다이얼 자물쇠 | 4 | 0 | 5 | 2 |
| P7 | 글자 타일 자물쇠 | 0 | 1 | 8 | 8 |
| P8 | 장면 탐색 → 장면 속에서 고르기 | 3 | 4 | 4 | 6 |
| P9 | 확대·관찰 (돋보기·코드 읽기) | 2 | 0 | 0 | 0 |
| P10 | 증인 심문 → 진술 대조 | 1 | 0 | 2 | 4 |
| P11 | 물리 장치 조작 (시계 바늘, 다이얼, 슬라이더, 밧줄, 기어, 해 드래그) | 1 | 9 | 0 | 0 |
| P12 | 비교·대조·짝 맞추기 | 0 | 11 | 0 | 0 |
| P13 | 경로·배치 (평면도 이동, 지도에 놓기, 분류) | 0 | 4 | 0 | 0 |
| P14 | 증거 연결 보드 / 소거 | 0 | 2 | 0 | 0 |
| P15 | 단계 안내형 (한 단계에 한 행동) | 0 | 13 | 0 | 0 |
| P16 | 증거 제시 대화 (CaseTalk) | 0 | 1 | 0 | 0 |
| | **합계** | **50** | **48** | **48** | **48** |

### 2-3. 단순 선택형 vs 탐색·조합·추론형

여기서 "단순"은 *화면 조작*이 단순하다는 뜻이다. London의 P1 중에는 영어로 꽤 깊게 추론해야 하는 문제도 많다(2-5절).

| 구분 | 정의 | London | Paris | Rome | NY |
|---|---|---:|---:|---:|---:|
| 단순 입력·선택 | P1–P7 | 86% | 8% | 88% | 79% |
| 그중 "보기 2–4개 중 하나 탭"(P1+P2) | 맞힐 확률 25–50% | 46% | 4% | 21% | 31% |
| 탐색·조작 | P8·P9·P11·P13 | 12% | 35% | 8% | 13% |
| 대조·연결 추론 | P10·P12·P14·P16 | 2% | 29% | 4% | 8% |
| 단계 안내 | P15 | 0% | 27% | 0% | 0% |

### 2-4. 같은 조작이 연속되는 구간

**London 플레이 순서** (Case | M1 · M2 · M3 · Final)

```
C01 | P8 · P9 · P8 · P2 · P9 · P6     ← 6개 중 5개가 그림 조작
C02 | P11· P1 · P1 · P6               ← M2·M3 연속 P1
C03 | P8 · P1 · P5 · P2
C04 | P1 · P1 · P2 · P3               ← M1·M2 연속 P1 (C03 Final P2 다음)
C05 | P1 · P5 · P3 · P6
C06 | P10· P3 · P1 · P1               ← M3·Final 연속 P1
C07 | P2 · P1 · P5 · P2
C08 | P1 · P3 · P4 · P1
C09 | P1 · P3 · P4 · P3               ← 그림 상호작용 0개
C10 | P1 · P5 · P2 · P5
C11 | P1 · P3 · P2 · P1
C12 | P1 · P4 · P3 · P6               ← C11 Final P1 → C12 M1 P1 연속
```

- **P1 연속 4곳**: C02 M2–M3, C04 M1–M2, C06 M3–Final, C11 Final–C12 M1.
- **Case 첫 미션의 패턴 고정**: C04·C05·C08·C09·C10·C11·C12의 M1이 모두 "편지 읽기 → 글 선택지"(P1)다. 새 Case를 시작해도 첫 화면 경험이 같다.
- **"편지 → 문제" 틀**: Case 02–12의 44개 중 41개가 `story → letter(봉인된 편지 열기) → 문제` 3단 흐름이다(`MissionStage { story, letter, puzzle }`). Case 01과 장면 엔진 미션은 편지를 장면 안에서 찾기 때문에(`noLetter`) 이 흐름을 따르지 않는다. **[확인]**
- **Paris**: C07 M1·M2·Final, C11–C12 전체가 EasySteps로 이어진다(P15 연속 9개). 단, 단계마다 그림·대상이 달라 체감 반복은 London P1보다 적다. **[추정]**

### 2-5. 직접 행동하는 구간 vs 텍스트만 읽는 구간

| 시즌 | 직접 행동 구간 (그림 탭·드래그·장치 조작이 정답 과정의 일부) | 텍스트 위주 구간 (읽고 → 버튼·키보드) |
|---|---|---|
| London | C01 M1·M2·M3·M5, C02 M1, C03 M1 (6개) | 나머지 44개. 이미지 카드 고르기(P2) 7개는 "그림을 보지만 조작은 탭 한 번" |
| Paris | 거의 전부. C06 Final(편지 그림 확대 + 객관식)과 C01 M2(전시물 확대 + 순서)만 반쯤 텍스트 | 약 4개 [추정] |
| Rome | Explore 4개 | 44개 (단, TalkMission 18개는 대화 장면이 붙음) |
| NY | Explore 6개 | 42개 (TalkMission 7개) |

### 2-6. 영어 학습과 추리의 결합 정도

| 시즌 | 평가 | 근거 |
|---|---|---|
| London | **높음** | 오답 선택지마다 "무엇을 잘못 읽었는지" 알려 주는 피드백(`ChoiceOption.feedback`, `Mission.feedback`). 전치사(under / behind / next to / on), 반대말(biggest ↔ smallest), 서수(third change), 시각 읽기(between eight and nine), 질문 만들기(ep08_m1), 문장 성분 순서(ep10_final: WHO / WILL / WHAT / WHEN) 등 영어 구조가 바로 단서가 된다. **[확인]** |
| Paris | 높음 (후반은 낮음) | 기록 대조(C03), 표식 비교(C05), 문서 불일치(C07)에서 영어 읽기가 핵심이다. 다만 C11–12의 EasySteps는 "Tap the big book."처럼 짧은 조작 지시가 대부분이라 영어 추론 비중이 줄어든다(의도된 VERY EASY 설계). **[확인]** |
| Rome / NY | 보통 | 질문 문장만 봐도 영어 이해("What is SAPIENTIA in English?", "Finish the sentence")를 묻는 비중이 있다. 다만 생성 템플릿이 반복된다("Turn the dials to …'s three numbers" 형식이 Rome에만 5회). **[추정: 질문 문장 기준]** |

### 2-7. 이미지와 상호작용하는 정도

| 시즌 | 장면 이미지 수 (assets/seasons) | 이미지 활용 |
|---|---:|---|
| London | 59 | Case 01: 픽셀 좌표로 탭 영역을 정의한 퍼즐 전용 이미지 5장. 그 밖에는 장소 그림을 이야기 머리 그림(`_StoryStage`)으로만 보여 준다. P2의 랜드마크 그림, 공원 지도(`Artwork.parkMapA–D`, `LandmarkArt`이 코드로 그림)는 고르는 카드로 쓴다. |
| Paris | 167 | 거의 모든 퍼즐이 전용 이미지 위에서 진행된다(탭 영역, 겹치기, 슬라이더, 드래그). |
| Rome | 60 | Explore 4개만 장면 탭. 나머지는 장소 그림이 배경. |
| NY | 59 | Explore 6개만 장면 탭. |

---

## 3. 실제 플레이 방식별 분류

### 3-1. P코드 정의와 해당 엔진

| P코드 | 플레이어가 하는 일 | 사용 엔진 (위젯 / 모델) | 같은 범주로 묶은 이유 |
|---|---|---|---|
| P1 | 편지를 읽고 글 선택지 2–4개 중 하나를 탭 | `MultipleChoiceQuestion`; Paris C06 Final은 `LetterStage` + MC | 엔진이 달라도 "글 버튼 하나 탭"이면 같은 유형 |
| P2 | 그림 카드 3–4장 중 하나를 탭 | `ImageChoiceQuestion` (`hideOptionNames` 포함), Paris `CanvasStage`/`CanvasPicker` | 그림을 보지만 조작은 카드 탭 한 번 |
| P3 | 빈칸에 단어를 키보드로 입력 | `WordInputQuestion` | |
| P4 | 숫자 키패드 입력 (시각 형식 포함) | `NumberCodeQuestion` | |
| P5 | 보기 버튼을 정해진 순서로 탭 | `SequenceQuestion`; Paris C01 M2(+`ExhibitObject`) | LEFT/RIGHT, 장소, 요일, 문장 조각 모두 같은 조작 |
| P6 | 숫자 바퀴 2–4개를 돌려 맞춤 | `FinalMissionScreen._Dial` (숫자 또는 `dialSymbols` 그림) | |
| P7 | 글자 타일을 슬롯에 넣음 | `LetterLockQuestion`, `LockBoxStage` | |
| P8 | 장면을 둘러보며 탭하고, 장면 안의 장소·물건을 골라 답함 | `SceneExplore`, `SceneDeduction`, `InvestigationSearch`, Paris `StationClocks`, `KeeperHut`, `ArchivePuzzle`, `HourRecordPuzzle` | 정답이 "그림 속 어딘가를 탭"하는 것으로 정해짐 |
| P9 | 돋보기를 끌거나 물건을 확대해 숨은 정보를 읽음 | `LensInspect`, `SceneDecode` | |
| P10 | 인물·질문을 골라 증언을 듣고, 진술 두 개를 맞대어 결론 | `DialogueInvestigation` (`DialogueScene`) | |
| P11 | 장치를 손으로 조작 (바늘 드래그, 다이얼 회전, 슬라이더, 밧줄 당기기, 기어 끼우기, 해 드래그, 테이프 당기기, 1분 재생) | `ClockQuestion`, `DialLock`, `RevealLayer`, `FlyRailPuzzle`, `GearBoardPuzzle`, `ShadowCheckPuzzle`, `DrumTapePuzzle`, `ClockWall`, `TowerTestPuzzle` | |
| P12 | 두 자료를 비교해 같거나 다른 점을 찾음 / 짝 맞추기 | `SpotDifferences`, `StudioMatch`, `TowerRecords`, `RiverMarks`, `MarkCompare`, `HoldRackPuzzle`, `PainterCornerPuzzle`, `MorningSketchesPuzzle`, `TornSlipPuzzle`, `MakerMarksPuzzle`, Quay Boxes | |
| P13 | 평면도·지도 위에서 이동하거나 물건을 제자리에 놓음 / 분류 | `PlanRoutePuzzle`, `LiftRoute`, `TrialMapPuzzle`, `CityClocksPuzzle` | |
| P14 | 질문마다 증거를 연결하거나, 증거로 후보를 지움 | `EvidenceBoard`, `StreetBookPuzzle`, `PostTrailPuzzle`, `TornHourStage` | |
| P15 | 한 화면에 한 지시("Tap the …"), 탭 / 문지르기 / 2지선다. 힌트 무료·무제한, 결국 정답 위치가 빛남 | `EasyStepsPuzzle` (`EasyStepsScene`) | |
| P16 | 인물과 대화하며 노트북 증거를 제시 | `CaseTalk` (`TalkScene`) | |
| (보조) | 퍼즐 앞뒤의 인물 대화 (퍼즐 자체는 아님) | `TalkMission` (`case_talk.dart`) | 통계에서는 퍼즐 유형으로 세지 않고 별도로 집계 |

### 3-2. 같은 엔진, 다른 경험 (사용자 요청 항목)

| 엔진 | 사례 | 경험 차이 |
|---|---|---|
| `MultipleChoiceQuestion` (P1) | London ep02_m2 "반대말 종" vs ep08_m1 "어떤 질문을 할까?" | 앞은 단어 뜻 하나를 찾는 문제다. 뒤는 *질문을 만드는* 메타 추리로, 체감 난도와 재미가 다르다. 그래도 조작은 같다. |
| `SequenceQuestion` (P5) | ep05_m2 LEFT/RIGHT 4회 vs ep10_final 문장 조립 | 같은 버튼 탭이지만, 뒤는 영문법(주어–조동사–목적어–시간)을 조립하는 "말이 되는" 순간이 있어 만족도가 높다. **[추정]** |
| `ImageChoiceQuestion` (P2) | ep01_m4 (이름 숨김, 묘사 읽고 그림 찾기) vs ep10_m3 (이름이 보이는 랜드마크) | 이름을 숨기면 영어 묘사를 그림으로 옮겨야 한다. 이름이 보이면 단어 맞추기가 된다. |
| `SceneExplore` (P8) | London m01 (장면 탐색 + 포스터 4장 고르기) vs Rome s3_ep01_m3 (카드·유리장·조각상 확인 후 지도 고르기) | 같은 엔진이고 경험도 거의 같다. |
| `matchPairs` (데이터 타입) | Paris C09 M1 기어 vs C10 M3 해시계 | 정답 그릇만 같고, 화면은 완전히 다른 놀이다. |

### 3-3. 영어 사용 방식별 분류 (보조)

| 영어 사용 | London 사례 |
|---|---|
| 묘사 → 대상 찾기 | m01, m04, ep03_final, ep04_m3, ep11_m3 |
| 전치사·위치 | m03, ep03_m1, ep05_m1, ep07_m1, ep07_m2, ep07_final |
| 반대말·부정 | ep02_m2, ep07_m2("NOT on the shelf"), ep07_m3 |
| 수·시간·서수 | ep02_m1, ep02_final, ep05_m3, ep09_m3, ep12_m2 |
| 속성 대조 (색·크기·재료) | ep03_m2, ep04_m2, ep06_m3, ep09_m1, ep10_m1, ep12_m1 |
| 증언 일치·불일치 | ep06_m1, ep11_m1 |
| 단어 만들기·철자 | m02, ep06_m2, ep09_m2, ep11_m2, ep12_m3 |
| 이전 Case 증거 연결 | ep03_final, ep04_final, ep06_final, ep08_final, ep09_final, ep11_m3, ep11_final, ep12 전체 |
| 문장 구조 | ep08_m1(질문), ep10_final(문장 성분 순서) |

---

## 4. 전체 퍼즐 목록

### 4-0. 공통 사항 (각 표에서 반복하지 않음)

- **힌트** [확인]: `Mission.hints`는 최대 2단계(`AppConstants.maxHints = 2`)다. Tip 1은 무료, Tip 2는 20코인이고(`tipPrices = [0, 20]`), 코인이 없으면 무료 "help"가 열린다. 오답 피드백은 선택지별(`ChoiceOption.feedback`) 또는 입력값별(`Mission.feedback`)로 붙고, 순서 오답은 `orderFeedback`로 안내한다. 장면 엔진은 이와 별도로 안내 표시(`guideAt`, 첫 탭 유도)와 빗나간 탭 문장(`missLine`)을 가진다. **EasySteps는 힌트가 무료·무제한이고, 마지막 단계에서 정답 위치를 빛낸다**(`easy_steps.dart:411`).
- **정답 이후** [확인]: Clue와 Evidence가 노트북에 저장되고, Discovery Moment, transition 장면, XP·코인 보상이 이어진다. 저장은 `GameProgress.completedMissionIds` 기준이다.
- **난이도** [확인]: 단어만 바뀌고 구조는 같다.
- **"유사"** 열은 같은 시즌 안에서 플레이 경험이 사실상 같은 퍼즐을 적는다.

### 4-1. Season 1 London (50) — 상세

파일: `lib/data/mock/season1/episodeNN_mock.dart`(Case 01은 `episode01_mock.dart`). 장면 테이블은 `season1_*.dart`.

| ID | 제목 / 상황 | 엔진 · 구현 파일 | 유형 | 플레이어 조작 | 정답 과정 | 영어 요소 | 힌트 특이점 | 이미지 활용 | 유사 |
|---|---|---|---|---|---|---|---|---|---|
| m01 | The Mysterious Suitcase · King's Cross | `SceneExplore` · `season1_explores.dart` | P8 | 역 장면에서 가방 탭 → 편지 읽기 → 포스터 판에서 박물관 4개 중 선택 | "mummies + famous stone" → British Museum | 묘사 읽기, 박물관 어휘 | 장면 안내 + 2단계 | 전용 장면 + 포스터 4장 | ep03_final 패턴 |
| m02 | The Strange Writing · Room 4 | `LensInspect` · `season1_inspections.dart` | P9 | 돋보기를 끌어 전시물 관찰 → 노트 문장 확인 → 라벨 빈칸 입력 | 노트 4행과 전시물 대조 → STONE | 동의어(rock / stone) | | 전용 장면 | — |
| m03 | The Locked Box · Big Ben | `SceneDeduction` · `season1_deductions.dart` | P8 | 흔적 3개(발자국·빛·긁힌 자국) 탭 → 숨긴 곳 탭 | 세 흔적이 가리키는 돌 | 위치 묘사 | | 전용 장면 | ep03_m1 |
| m04 | The Secret Drawing · Hyde Park | `ImageChoiceQuestion` (이름 숨김) | P2 | 랜드마크 그림 4장 중 탭 | 깃발 + 분수 + 왕 → 궁전 | 묘사 → 그림 | | 랜드마크 그림 | ep04_m3, ep11_m3 |
| m05 | The Royal Guard · 크라운 카드 | `SceneDecode` · `season1_decodes.dart` | P9 | 카드 확대 → 코드 스캔 → 가져가기 (오답 없음) | 심볼 순서 획득 | 짧은 메시지 | | 전용 장면 2장 | — |
| final | The Royal Box | `FinalMissionScreen` 심볼 다이얼 (`dialSymbols`) | P6 | 그림 자물쇠 4개를 숫자 바퀴로 맞춤 | 심볼 순서 × 노트북 숫자 → 7924 | 노트북 다시 읽기 | | Royal Box 애니메이션 | ep05·ep12 final |
| ep02_m1 | The Frozen Hands | `ClockQuestion` · `season1_clocks.dart` | P11 | 시계 바늘 드래그 | between 8 and 9, on the three + 2 → 8:17 | 시각 표현 | 오답 시각별 피드백 | `clock_face.png` | — |
| ep02_m2 | The Missing Gear · Clock Room | MC (기본) | P1 | 4개 중 탭 | "not the biggest… opposite" → smallest bell | 부정·반대말 | | 장소 그림(배경) | ep07_m2 |
| ep02_m3 | The Time Card · Belfry | MC | P1 | 4개 중 탭 | 멈춘 시각 8:17 → Gallery 8 · Picture 17 | 숫자 대응 | 이전 단서 참조 | 배경 | — |
| ep02_final | The Great Clock | 숫자 다이얼 3 | P6 | 바퀴 3개 | 8:17 + 1시간 → 917 | one hour after | 오답 3종 피드백 | 배경 | — |
| ep03_m1 | The Empty Frame · Gallery 8 | `InvestigationSearch` · `season1_investigations.dart` | P8 | 어두운 전시실을 수색해 물건 3개를 보고서 위치대로 찾음 | 마지막 "next to the door" = 발자국 | 전치사 | | `british_museum_gallery_8.png` | m03 |
| ep03_m2 | The Three Visitors | MC | P1 | 3명 중 탭 | 빨간 단추(코트) + 파란 천(스카프) → Miss Rose | 색·옷 어휘 | 노트북 참조 | 배경 | ep06_m3, ep09_m1 |
| ep03_m3 | The Wet Footprints · Great Court | Sequence | P5 | 장소 버튼 4개 순서 탭 | very wet > wet > a little wet > almost dry | 정도 비교 | 순서 오답 피드백 | 배경 (발자국 없음 [확인]) | ep10_m2 |
| ep03_final | The Way Out | ImageChoice (이름 표시) | P2 | 4장 중 탭 | north + clock tower + "smells of trains" → King's Cross | 이전 증거 참조 | 노트북 안내 | 랜드마크 그림 | m04 |
| ep04_m1 | The Black Seal | MC | P1 | 4개 중 탭 | "never sleep" + 운영시간표 → platforms | 관용 표현, 시간표 | | 가방 그림 | ep08_m1 |
| ep04_m2 | The Four Words | MC | P1 | 4개 중 탭 | RED · SMALL · CLOCK → Platform 4 | 속성 대조 | | King's Cross 그림 | ep12_m1 |
| ep04_m3 | The Postmark | ImageChoice (이름 숨김) | P2 | 4장 중 탭 | castle + river + towers + black birds → Tower of London | 묘사 → 그림 | | 랜드마크 그림 | m04 |
| ep04_final | The Last Letter | WordInput | P3 | 입력 | 봉인의 새 → RAVEN | 추론 + 철자 | 오답 4종 피드백 | 가방 그림 | ep06_m2 |
| ep05_m1 | The Ravenmaster | MC | P1 | 4개 중 탭 | third floor + on the right | 서수·좌우 | | Tower 그림 | ep07_m2 |
| ep05_m2 | The Dial Door | Sequence (LEFT / RIGHT 반복) | P5 | 2개 버튼을 4번 탭 | first / other / same as first / same as second | 지시어 | | 기어 문 그림 | — |
| ep05_m3 | The Ravens' Box | WordInput | P3 | 입력 | six + one more → SEVEN | 수 단어 | | 까마귀 그림 | — |
| ep05_final | The Iron Chest | 숫자 다이얼 3 | P6 | 바퀴 3개 | 까마귀 7 · 기어 4 · 문 닫는 시각 5 | 질문 순서 | 순서 오답 피드백 | 철제 상자 | m·final, ep12_final |
| ep06_m1 | Three Witnesses | `DialogueInvestigation` · `season1_dialogues.dart` | P10 | 증인 3명 × 질문 3개 → 진술 2개 맞대기 | 두 명이 일치 → small bag | 질문·진술 | **Junior/Master 문장 없음** | 시장 배경 + 인물 3 | ep11_m1(텍스트판) |
| ep06_m2 | The Wet Card | WordInput | P3 | 입력 | 모자 색 = 비구름 색 → GREY | 색 어휘 | 오답 5종 | 배경 | ep04_final |
| ep06_m3 | Two Dark Coats | MC (3지) | P1 | 탭 | 증인 노트와 일치하는 밤 → Monday | 속성 대조 | 노트북 | 극장 문 | ep03_m2 |
| ep06_final | The Midnight Detective | MC | P1 | 탭 | 키 큼 + 작은 가방 + 떨어뜨린 카드 → Inspector Grey | 종합 | 노트북 | 배경 | ep11_final |
| ep07_m1 | The First Directions | ImageChoice (코드로 그린 지도 4장) | P2 | 지도 4장 중 탭 | past the tree / right / beside the bench | 길 안내 | | `parkMapA–D` | ep07_final |
| ep07_m2 | The Boathouse | MC | P1 | 탭 | NOT shelf / under table / behind can | 전치사 | | 보트하우스 외부 그림 [확인] | ep02_m2 |
| ep07_m3 | The Three Pieces | Sequence (3) | P5 | 버튼 3개 순서 탭 | 강 조각은 맨 위가 아님 + 역·강 조각은 붙지 않음 | 논리 조건 | 오답 5종 | 장미정원 | — |
| ep07_final | The Last Piece | ImageChoice (지도) | P2 | 탭 | Grey의 안내 + 합친 지도 화살표 | 두 단서 결합 | | 지도 | ep07_m1 |
| ep08_m1 | The Name Tag | MC | P1 | 탭 | 지워지지 않은 TO: Edinburgh로 확인 가능한 질문 | **질문 만들기** | | 검은 가방 | — |
| ep08_m2 | Four Passengers | WordInput (MRS ____) | P3 | 입력 | Edinburgh + alone → ROBIN | alone / with | | 대합실 (사람 없음 [확인]) | ep11_m1 |
| ep08_m3 | Inside the Suitcase | NumberCode (3) | P4 | 키패드 | seat 42 + hour 9 → 429 | 수 단어 | 순서 오답 | 가방 | ep09_m3 |
| ep08_final | The Last Train | MC (증거 이름 4개) | P1 | 탭 | Case 03의 빨간 단추 | 이전 Case 증거 | Case Archive 경로 안내 | King's Cross | **증거 제시형 후보** |
| ep09_m1 | The Empty Box | MC | P1 | 탭 | big gold key → guard | 소유격 | | 빈 보석함 그림 | ep10_m1 |
| ep09_m2 | The New Helper | WordInput (4글자) | P3 | 입력 | A _ _ A, M 다음 글자 → ANNA | 알파벳 | | 직원실 | ep11_m2 |
| ep09_m3 | The Changing of the Guard | NumberCode (2) | P4 | 키패드 | 8, 10, **12** | 서수·간격 | 오답 4종 | 광장 | ep12_m2 |
| ep09_final | The Three Things | WordInput (IN THE ___) | P3 | 입력 | 열쇠 주인 → Carl → 검은 모자 → HAT | 소거 추론 | 오답 5종 | 궁전 | — |
| ep10_m1 | Which Raven? | MC | P1 | 탭 | small + quiet + gold ring → Poppy | 최상급 | | 까마귀 | ep12_m1 |
| ep10_m2 | Four Mornings | Sequence (4) | P5 | 단어 4개 순서 | 요일 순서 | 요일 | 오답 2종 | 까마귀 | ep03_m3 |
| ep10_m3 | The Meeting Place | ImageChoice (이름 표시) | P2 | 탭 | TOWER + BRIDGE → Tower Bridge | 합성 지명 | | 랜드마크 | — |
| ep10_final | The Raven's Message | Sequence (문장 조각) | P5 | 4개 순서 | WHO → WILL → WHAT → WHEN | **문장 구조** | 오답 3종 | 까마귀 | — |
| ep11_m1 | Three Stories | MC (3지) | P1 | 탭 | 혼자 다른 진술 → the child | 일치·불일치 | | 극장 | ep06_m1 |
| ep11_m2 | The White Mask | WordInput (8글자) | P3 | 입력 | THGINDIM 뒤집기 → MIDNIGHT | 철자 | | 분장실 (**거울이 그려져 있음** [확인]) | — |
| ep11_m3 | The Stage Door | ImageChoice (이름 숨김) | P2 | 탭 | station + arches + clock tower → King's Cross | 묘사 | Case 04 참조 | 랜드마크 | m04 |
| ep11_final | Behind the Mask | MC (인물 4명) | P1 | 탭 | "the very start" + 기차 → The Shadow | 이전 Case | Case Archive 안내 | 가방 | ep06_final |
| ep12_m1 | The Real Gear | MC (속성 3개 조합) | P1 | 탭 | brass + 8 teeth + raven stamp | 속성 소거 | | 시계 | ep10_m1 |
| ep12_m2 | The Last Train In | NumberCode (시각 형식) | P4 | 키패드 | Platform 4 + Edinburgh 다음 → 11:40 | 시간표 | 오답 3종, Case 04 참조 | King's Cross | ep09_m3 |
| ep12_m3 | The Raven's Riddle | WordInput (UNDER ___ ___) | P3 | 입력 | 수수께끼 → BIG BEN | 수수께끼 | | 까마귀 | — |
| ep12_final | The Clockmaker's Door | 숫자 다이얼 3 | P6 | 바퀴 3개 | 4 · 8 · 7 | 이전 단서 3개 | 순서 오답 | 작은 철문 | ep05_final |

**기획과 구현의 차이** [확인]
- 데이터 주석(`episodeNN_mock.dart`)과 장면 테이블 주석은 실제 구현과 일치한다. 기획 문서와 다른 구현은 찾지 못했다.
- 단, `season1_mock.dart`의 시즌 설명은 "a small raven is found on the evidence of every case"인데, 현재 퍼즐 구조는 이 연결을 플레이로 보여 주지 않는다. 증거 inscription 문장에만 남아 있다.
- `ep06`은 `season1WrittenLevels`에서 **Rookie만** 작성되어 있다. M1의 대화 엔진(DialogueScene)에 난이도별 문장이 없기 때문이다(`season1_difficulty.dart` 주석). 반면 Rome은 `s3_rome_levels.g.dart`에서 `dialogues` 난이도 변형을 쓰고 있어, **엔진이 난이도별 문장을 받지 못하는 것이 아니라 London에서 작성하지 않은 상태**로 보인다. `puzzle_palette.dart`의 `witness_compare` 제약 문구("No level variant")는 이 점에서 현재 코드와 어긋난다. **[확인 + 추정]**

### 4-2. Season 2 Paris (48)

파일: 미션 데이터 `lib/data/mock/season2/episodeNN_mock.dart`, 장면 `season2_scenes.dart`(C01–02), `season2_caseNN_scenes.dart`. 위젯은 `lib/features/mission/widgets/`. 힌트는 공통(4-0) 방식이고, P15만 무료·무제한이다.

| ID | 제목 | 엔진 (위젯) | 유형 | 조작 / 정답 과정 요약 | 영어 요소 | 이미지 |
|---|---|---|---|---|---|---|
| s2_ep01_m1 | The Three Clocks | `StationClocks` | P8 | 역 대합실 시계·출발판·책상을 살펴보고 1시간 늦은 시계 선택 | 시각 비교 | 전용 |
| s2_ep01_m2 | The Lost Ticket | `ExhibitObject` + Sequence | P5 | 승차권 확대 후 사건 순서 탭 | 순서 연결어 | 전용 |
| s2_ep01_m3 | The Clockmaker's Mark | `ClockQuestion` | P11 | 옛 시계 바늘 맞추기 | 시각 | 전용 |
| s2_ep01_final | The Hidden Compartment | `LetterLockQuestion` + `LockBoxStage` | P7 | 미션별 글자 T · I · M · E 조합 | 단어 | 전용 |
| s2_ep02_m1 | The Painted Street | `SpotDifferences` | P12 | 거리와 그림을 비교해 차이 3곳 탭 | 묘사 | 전용 2장 |
| s2_ep02_m2 | The Artist's Studio | `StudioMatch` | P12 | 작업실 탐색 → 그림 찾기 → 메모를 그림과 짝지음 | 묘사·날씨 | 전용 |
| s2_ep02_m3 | The Hidden Layer | `RevealLayer` | P11 | 슬라이더로 덧칠을 걷어 내고 표식 3개 찾기 | 사물 어휘 | 전용 2장 |
| s2_ep02_final | Behind the Canvas | `CanvasStage` / `CanvasPicker` | P2 | 단서에 맞는 캔버스 선택 → 뒤집기 | 단서 종합 | 전용 |
| s2_ep03_m1 | The Two Notices | `TowerRecords` | P12 | 두 공지를 읽고 맞지 않는 줄 하나씩 선택 | 정밀 독해 | 전용 |
| s2_ep03_m2 | The Lift That Stopped | `LiftRoute` | P13 | 노선판·기록 읽기 → 빠진 정차층 선택 | 기호 해석 | 전용 |
| s2_ep03_m3 | Behind the Iron Door | `DialLock` | P11 | 심볼 다이얼 3개 드래그 | 단서 연결 | 전용 |
| s2_ep03_final | The Missing Hour | `EvidenceBoard` | P14 | 질문마다 증거 연결 → 결론 선택 | 질문 이해 | 전용 |
| s2_ep04_m1 | Three Waves | `RiverMarks` | P12 | 새김 표식 4개를 확대해 비교 → 선택 | 조건 3개 | 전용 |
| s2_ep04_m2 | The River Keeper | `KeeperHut` | P8 | 오두막 문 → 장부 → 상자 번호에 동그라미 | 장부 읽기 | 전용 3장 |
| s2_ep04_m3 | The Hidden Message | Quay Boxes (`river_papers.dart`) | P12 | 상자를 열어 보며 찢어진 라벨 맞추기 [추정] | 조각 단어 | 전용 |
| s2_ep04_final | The Watchmaker's Address | EasySteps (원래 `StreetBookPuzzle`) | P15 | 단계 안내 | 짧은 지시 | 전용 |
| s2_ep05_m1 | The Maker's Mark | `MarkCompare` | P12 | 트레이싱지를 겹쳐 표식 비교 | 비교 | 전용 |
| s2_ep05_m2 | The Clocks That Lie | `ClockWall` | P11 | 1분 재생으로 시계를 관찰하고 뒷면 확인 → 선택 | 시간 | 전용 |
| s2_ep05_m3 | The Blotted Page | EasySteps (원래 `BlotterMirror`) | P15 | 단계 안내 (거울 글씨) | 거꾸로 쓴 글 | 전용 |
| s2_ep05_final | The Letter's Trail | EasySteps (원래 `PostTrailPuzzle`) | P15 | 단계 안내 | | 전용 |
| s2_ep06_m1 | Find Letter 4417 | `HoldRackPuzzle` | P12 | 꼬리표를 뒤집으며 기록과 대조 | 정밀 독해 | 전용 |
| s2_ep06_m2 | Follow the Letter | `PlanRoutePuzzle` | P13 | 평면도에서 탭으로 한 칸씩 이동 → 문 선택 | 길 안내 | 전용 |
| s2_ep06_m3 | The Hidden Envelope | `ArchivePuzzle` | P8 | 서랍 열기 → 봉투에 귀퉁이 대 보기 | 라벨 | 전용 |
| s2_ep06_final | The Secret in the Letter | `LetterStage` + MC | P1 | 편지 그림 확대 → 건물 선택 | 묘사 | 전용 |
| s2_ep07_m1 | The Show Strip | EasySteps (원래 `ShowStripPuzzle`) | P15 | 단계 안내 | 시각 | 전용 |
| s2_ep07_m2 | The Ghost Light | EasySteps (원래 `LightBoard`) | P15 | 단계 안내 | | 전용 |
| s2_ep07_m3 | The Painted Sky | `FlyRailPuzzle` | P11 | 밧줄을 당겨 배경막을 내리고 비교 → 선택 | 묘사 | 전용 |
| s2_ep07_final | The Changed Record | EasySteps (원래 `RecordStage`) | P15 | 단계 안내 | | 전용 |
| s2_ep08_m1 | The Hidden Sketch | `PainterCornerPuzzle` (+recall) | P12 | 광장 모퉁이 3곳의 시점을 스케치와 비교 | 시점 | 전용 |
| s2_ep08_m2 | The Morning Drawing | `MorningSketchesPuzzle` | P12 | 그림 3장 순서 배치 → 겹쳐 비교 → 질문 | 순서 | 전용 |
| s2_ep08_m3 | The Purple Seal | `TornSlipPuzzle` (+recall) | P12 | 접힌 종이 펼치기 → SAME / MISSING 표시 | 같다·없다 | 전용 |
| s2_ep08_final | The Torn Hour | `TornHourStage` + 보드 | P14 | 종이를 그림에 대기 → 결론 | 종합 | 전용 |
| s2_ep09_m1 | The Little Paris | `TrialMapPuzzle` | P13 | 작은 시계 3개를 지도에 드래그 | 위치 | 전용 |
| s2_ep09_m2 | The Gear Path | `GearBoardPuzzle` | P11 | 크기에 맞는 기어 끼우기 | 크기 | 전용 |
| s2_ep09_m3 | The Maker's Marks | `MakerMarksPuzzle` | P12 | 노트북 표식과 종이 표식 잇기 | 모양 | 전용 |
| s2_ep09_final | The Wrong Hour | `TowerTestPuzzle` + MC | P11 | 탑 시각을 −/+로 맞추고 TEST → 질문 | 원인 | 전용 |
| s2_ep10_m1 | The Drum Tape | `DrumTapePuzzle` | P11 | 테이프를 당겨 시간이 튀는 곳 2곳 탭 | 연속 | 전용 |
| s2_ep10_m2 | A City of Clocks | `CityClocksPuzzle` | P13 | 돋보기로 사진 속 시계 찾기 → 분류 | 분류 | 전용 |
| s2_ep10_m3 | The Hour of Shadows | `ShadowCheckPuzzle` | P11 | 해를 드래그해 그림자 길이 맞추기 | 길다·짧다 | 전용 |
| s2_ep10_final | The Hour Was Recorded | `HourRecordPuzzle` + MC | P8 | 테이프에서 사진 찾기 → 빠진 쪽 찾기 → 질문 | 종합 | 전용 |
| s2_ep11_m1–m3 | Missing Page / Two Papers / Who Signed It? | EasySteps + TalkMission | P15 | 대화 → 단계 안내(문지르기 포함) → 대화 | 짧은 지시 | 전용 |
| s2_ep11_final | Victor's Truth | `CaseTalk` | P16 | 대화하며 증거 제시 | 대화 | 인물 |
| s2_ep12_m1–m3 | Find the Wheel / Who Is the Clockmaker? / Fix the Machine | EasySteps + TalkMission | P15 | 대화 → 단계 → 대화 | | 전용 |
| s2_ep12_final | The Final Case Board | EasySteps | P15 | 사건 보드 단계형 | | 전용 |

**기획과 구현의 차이** [확인]: Case 04 Final(StreetBook), Case 05 M3(Blotter)·Final(PostTrail), Case 07 M1(ShowStrip)·M2(LightBoard)·Final(LightTable)은 원래 전용 엔진으로 구현되었다가, 2026-10-27에 EasySteps(VERY EASY)로 교체되었다(`season_catalog.dart:462-463`, `easy_steps.dart` 1–10행). 원래 엔진 코드는 남아 있다.

### 4-3. Season 3 Rome (48)

파일: `lib/data/generated/s3_rome/s3_epNN.g.dart`(Season Factory 생성, `tool/season_gen/generate_case.dart`). "+대화"는 TalkMission(퍼즐 전후 대화), "+recall"은 노트북 증거 호출이다. 정답 과정은 **질문 문장 기준 [추정]**이다.

| ID | 제목 | 엔진 | 유형 | 질문(요약) |
|---|---|---|---|---|
| s3_ep01_m1 | The Night Log | DialogueInvestigation | P10 | 자정에 무슨 일이 있었나 |
| s3_ep01_m2 | The Dust Trail | Sequence +대화 | P5 | 먼지 자국 순서 |
| s3_ep01_m3 | The Owl's Card | SceneExplore | P8 | 올빼미가 가라는 곳 |
| s3_ep01_final | The Light Box | 숫자 다이얼 | P6 | 세 숫자 |
| s3_ep02_m1 | The Owl's Riddle | WordInput +대화 | P3 | 수수께끼 주제 |
| s3_ep02_m2 | The Professor's Notebook | MC +대화 | P1 | 왜 용의자인가 |
| s3_ep02_m3 | The Owl's Tin | LetterLock | P7 | 재료 철자 |
| s3_ep02_final | The Owl's Route | Sequence | P5 | 경로 순서 |
| s3_ep03_m1 | Pia's Morning | Sequence +대화 +recall | P5 | 시간 순서 |
| s3_ep03_m2 | Inside Box 7 | MC | P1 | 먼지의 출처 |
| s3_ep03_m3 | Thursday Night | WordInput +대화 | P3 | 헬멧 그림 |
| s3_ep03_final | Pia's Cash Box | 숫자 다이얼 | P6 | 세 숫자 |
| s3_ep04_m1 | The Round Eye | SceneExplore | P8 | 어느 돌인가 |
| s3_ep04_m2 | The Password | WordInput | P3 | 암호 |
| s3_ep04_m3 | Test It First | Sequence | P5 | 시험 순서 |
| s3_ep04_final | What Is It Made Of? | LetterLock | P7 | 재료 철자 |
| s3_ep05_m1 | The Cat Board | SceneExplore | P8 | 어떤 고양이였나 |
| s3_ep05_m2 | Tito's Round Tag | LetterLock | P7 | 가족 이름 |
| s3_ep05_m3 | How a Copy Is Made | Sequence +대화 | P5 | 공정 순서 |
| s3_ep05_final | Order Number 3?8 | 숫자 다이얼 | P6 | 주문 번호 |
| s3_ep06_m1 | Big Man, Small Man | MC +대화 +recall | P1 | 그 사람일 수 있나 |
| s3_ep06_m2 | The Door Log of Hall B | Sequence +대화 | P5 | 금요일 밤 순서 |
| s3_ep06_m3 | The Word in the Mirror | WordInput | P3 | 거울 속 단어 |
| s3_ep06_final | What Is His Job? | LetterLock | P7 | 직업 철자 |
| s3_ep07_m1 | Up the Steps | Sequence +recall | P5 | 계단 순서 |
| s3_ep07_m2 | The Chalk Code | WordInput | P3 | 암호 해독 |
| s3_ep07_m3 | The Smiling Sponsor | MC +대화 | P1 | 진실인가 |
| s3_ep07_final | The Box by the Church | 숫자 다이얼 | P6 | 세 숫자 |
| s3_ep08_m1 | The Bridge of Four Heads | ImageChoice +recall | P2 | 어느 다리 |
| s3_ep08_m2 | The Owl Takes Off Her Hood | MC +대화 | P1 | 왜 꺼냈나 |
| s3_ep08_m3 | Livia's Week | Sequence | P5 | 한 주 순서 |
| s3_ep08_final | Livia's Locker | LetterLock | P7 | 표식 철자 |
| s3_ep09_m1 | Half a Word | ImageChoice +대화 +recall | P2 | 그림 속 방 |
| s3_ep09_m2 | Walk the Old Street | Sequence | P5 | 길 순서 |
| s3_ep09_m3 | The Owl Square Today | WordInput +대화 | P3 | 이탈리아어 단어 |
| s3_ep09_final | Aldo's Map Cabinet | 숫자 다이얼 | P6 | 표석 세 개 |
| s3_ep10_m1 | The Helmet on the Hook | SceneExplore +대화 +recall | P8 | 어떤 헬멧 |
| s3_ep10_m2 | The Yellow Helmet | LetterLock | P7 | 찢어진 이름 |
| s3_ep10_m3 | The Box Nobody May Open | MC +대화 | P1 | 상자 속 물건 |
| s3_ep10_final | A Message for Sofia | WordInput | P3 | 광장 밑 |
| s3_ep11_m1 | Three Stones | ImageChoice +대화 +recall | P2 | 진짜 조각 |
| s3_ep11_m2 | A Market on Sunday? | DialogueInvestigation +recall | P10 | 일요일 시장 |
| s3_ep11_m3 | Valli's Plan, Step by Step | Sequence | P5 | 계획 순서 |
| s3_ep11_final | The Pass He Dropped | LetterLock | P7 | 통행증 철자 |
| s3_ep12_m1 | Safety First | Sequence +대화 +recall | P5 | 안전 순서 |
| s3_ep12_m2 | Holes in the Walls | MC +대화 | P1 | 구멍 용도 |
| s3_ep12_m3 | The Owl in the Floor | WordInput +대화 | P3 | SAPIENTIA 뜻 |
| s3_ep12_final | Seven Gold Tiles | LetterLock | P7 | 금 타일 7개 |

recall 위치(Case 단위, [확인]): ep03·06·07·08·09·10·11(2개)·12의 미션. 위 표의 미션별 +recall 배치는 Case 안에서의 위치를 [추정]한 것이다.

### 4-4. Season 4 New York (48)

파일: `lib/data/generated/s4_newyork/s4_epNN.g.dart`. 정답 과정은 **질문 문장 기준 [추정]**이다.

| ID | 제목 | 엔진 | 유형 | 질문(요약) |
|---|---|---|---|---|
| s4_ep01_m1 | The Night at the Library | DialogueInvestigation | P10 | 10시에 무슨 일이 |
| s4_ep01_m2 | The 1926 Newspaper | MC +대화 | P1 | 단서를 얻는 법 |
| s4_ep01_m3 | The Pencil Rubbing | SceneExplore | P8 | 흔적의 시작점 |
| s4_ep01_final | The Night in Order | Sequence | P5 | 그날 밤 순서 |
| s4_ep02_m1 | The Early Visitor | DialogueInvestigation | P10 | 7시에 무슨 일이 |
| s4_ep02_m2 | The Keeper's Question | WordInput | P3 | 질문의 답 |
| s4_ep02_m3 | The Brass Egg | LetterLock | P7 | 여는 방향 |
| s4_ep02_final | Eleanor's Next Friend | ImageChoice | P2 | 다음 가게 |
| s4_ep03_m1 | The Red Tin | SceneExplore +대화 | P8 | 어느 깡통 |
| s4_ep03_m2 | Eleanor's Tea | Sequence | P5 | 차 만드는 순서 |
| s4_ep03_m3 | Mei Lee's Diary | MC | P1 | 마지막 세 음 |
| s4_ep03_final | The Three Dials | 숫자 다이얼 | P6 | 세 숫자 |
| s4_ep04_m1 | Wet Paint | MC | P1 | 언제 가져갔나 |
| s4_ep04_m2 | The Missing Bird | ImageChoice | P2 | 어느 새 |
| s4_ep04_m3 | The Man with the Toolbox | WordInput +대화 | P3 | 직업 |
| s4_ep04_final | Eleanor's Spare Box | LetterLock | P7 | 단어 |
| s4_ep05_m1 | Otto's Letter | MC +대화 | P1 | 왜 원하나 |
| s4_ep05_m2 | Otto's Diary | SceneExplore | P8 | 다리 다음 장소 |
| s4_ep05_m3 | The Tiny Screws | WordInput | P3 | 문장 완성 |
| s4_ep05_final | Karl's Drawer | 숫자 다이얼 | P6 | 세 숫자 |
| s4_ep06_m1 | Otto's Morning | Sequence | P5 | 아침 순서 |
| s4_ep06_m2 | Otto's Alibi | WordInput +대화 | P3 | 지금 가진 것 |
| s4_ep06_m3 | Who Heard the Note? | MC | P1 | 누가 먼저 |
| s4_ep06_final | The Notes on the Wing | LetterLock | P7 | 세 음 |
| s4_ep07_m1 | The Star Boots | ImageChoice | P2 | 어느 장화 |
| s4_ep07_m2 | Dexter's Sunday | DialogueInvestigation | P10 | 일요일 위치 |
| s4_ep07_m3 | The TV Truck | SceneExplore | P8 | 촬영 장소 |
| s4_ep07_final | The Scribbled Note | MC | P1 | 왜 원하나 |
| s4_ep08_m1 | Three Musicians | ImageChoice +recall | P2 | 어느 연주자 |
| s4_ep08_m2 | Rosa's Test | MC | P1 | 왜 믿나 |
| s4_ep08_m3 | Rosa's Secret | WordInput +대화 | P3 | 문장 완성 |
| s4_ep08_final | Rosa's Music Box | LetterLock | P7 | 단어 |
| s4_ep09_m1 | The Keeper's Question | WordInput | P3 | 질문의 답 |
| s4_ep09_m2 | The Car That Never Swings | SceneExplore | P8 | 어느 칸 |
| s4_ep09_m3 | The Iron Box | LetterLock | P7 | 단어 |
| s4_ep09_final | Eleanor's Last Steps | Sequence | P5 | 순서 |
| s4_ep10_m1 | The Empty Violin Case | MC | P1 | 누가 가까웠나 |
| s4_ep10_m2 | Nora's Message | ImageChoice | P2 | 어느 건물 |
| s4_ep10_m3 | The Dropped Page | WordInput | P3 | 모르는 것 |
| s4_ep10_final | Rosa Remembers | LetterLock | P7 | 세 음 |
| s4_ep11_m1 | Friday Night | DialogueInvestigation +recall | P10 | 금요일 위치 |
| s4_ep11_m2 | The Prop Shelf | ImageChoice | P2 | 어느 새 |
| s4_ep11_m3 | The Page in the Drawer | MC | P1 | 무엇을 증명 |
| s4_ep11_final | Finders Keepers | LetterLock | P7 | 금고 단어 |
| s4_ep12_m1 | The East Wall | SceneExplore | P8 | 어느 석조 새 |
| s4_ep12_m2 | The Whole Song | Sequence +대화 | P5 | 순서 |
| s4_ep12_m3 | Eleanor's Letter | WordInput | P3 | 원하는 것 |
| s4_ep12_final | The Silver Cage | LetterLock | P7 | 새장 단어 |

NY의 recall은 ep08·ep11에 1개씩 있다 [확인]. 위 표의 미션 배치는 [추정]이다.

---

## 5. London 12개 Case 분석

평가 기준: 8–12세가 혼자 한다는 전제에서 (1) 손으로 하는 일이 있는가, (2) 스스로 발견하는 순간이 있는가, (3) 영어가 단서 역할을 하는가, (4) 바로 앞 미션과 다른 경험인가.

### Case 01 — The Missing Crown · 개선 필요성 **낮음**

- **진행**: 역 탐색(가방·편지·포스터) → 돋보기 관찰 + 단어 입력 → 흔적 3개 찾고 숨긴 곳 탭 → 그림 고르기 → 카드 코드 스캔 → 그림 자물쇠 4개.
- **재미**: 퍼즐마다 조작이 다르다. 장소에 "들어가서" 직접 찾는 느낌이 있고, 마지막에 노트북 단서를 조합하는 보상이 확실하다(Royal Box 애니메이션). 미스터리 게임의 첫인상으로 매우 좋다.
- **단조로움**: 없음. m04만 상대적으로 평범하다(그림 카드 고르기).
- **추리 부족**: 없음. m05는 "오답 없음"인 정보 획득 단계라 의도된 쉬움이다.
- **영어 부족**: 없음.
- **이유**: London 전체의 기준점이다. **다른 Case를 이 수준에 가깝게 끌어올리는 것이 목표다.** 다만 Case 01이 기대치를 크게 올려 놓기 때문에 Case 02의 낙차가 커진다.

### Case 02 — The Silent Clock · 개선 필요성 **높음** (첫 3개 Case)

- **진행**: 시계 바늘 맞추기 → 글 선택(어느 종 밑인가) → 글 선택(Gallery 몇 번?) → 숫자 다이얼.
- **재미**: M1의 바늘 드래그는 촉감이 좋다. "멈춘 시각이 사실은 메시지였다"는 반전도 좋다.
- **단조로움**: M2·M3가 연속으로 P1이다. 시계탑 안, 종루 같은 극적인 장소인데 플레이는 "읽고 버튼"이다. Final은 M1에서 직접 바늘을 돌렸던 그 시계를 숫자 바퀴로 처리해, "Big Ben이 다시 울린다"는 결말의 손맛이 약하다.
- **추리 부족**: M2는 "opposite of the biggest = smallest" 단어 하나로 풀린다. 보기 중 "Behind the clock face", "On the stairs"는 너무 쉽게 지워진다.
- **영어 부족**: 크지 않다. 반대말과 부정은 좋은 소재다.
- **이유**: 두 번째 Case에서 Case 01 수준의 조작 경험이 바로 끊긴다. 첫 이탈 위험 구간이다. **[추정]**

### Case 03 — The Vanishing Painting · 개선 필요성 **높음** (첫 3개 Case)

- **진행**: 전시실 수색(보고서 위치대로 3개 찾기) → 글 선택(방문자 3명) → 장소 버튼 순서 → 그림 고르기.
- **재미**: M1 수색은 좋다. Final이 Case 01 증거("smells of trains")와 이어지는 것도 좋다.
- **단조로움**: M3 "젖은 발자국 순서"는 본래 **눈으로 보는 퍼즐**인데, 장소 이름 버튼 4개를 누르는 것으로 바뀌어 있다. Great Court 그림에는 발자국이 없다 [확인].
- **추리 부족**: M2는 노트북의 빨간 단추·파란 천을 떠올려야 하는 좋은 추리인데, 화면이 증거를 꺼내 보여 주지 않고 힌트 문장으로만 안내한다.
- **영어 부족**: 색·옷 어휘가 좋다. 그림으로 바꿀 때는 색을 그림으로 보여 주면 읽지 않고도 풀 수 있게 되므로 주의해야 한다(7장).
- **이유**: 첫 "용의자 지목" 장면인데 연출이 약하다.

### Case 04 — The Secret Letter · 개선 필요성 **보통**

- **진행**: 글 선택(운영시간표) → 글 선택(4단어와 승강장) → 그림 고르기(소인) → 단어 입력(RAVEN).
- **재미**: "Raven Society"라는 이름이 드러나는 Final의 서사 보상이 크다.
- **단조로움**: M1·M2 연속 P1이고, Case 03 Final(P2)에 이어 "고르기"가 세 번 이어진다.
- **추리 부족**: M2는 사실 *장면 관찰* 퍼즐이다(빨간 시계 / 빨간 문 / 초록 시계). 글로 된 목록이라 대조가 너무 쉽다.
- **영어 부족**: 없음(관용 표현, 속성 대조 모두 좋음).
- **이유**: M2만 장면형으로 바꿔도 체감이 크게 달라진다.

### Case 05 — The Locked Room · 개선 필요성 **보통**

- **진행**: 글 선택(층·방향) → LEFT/RIGHT 4번 → 단어 입력 SEVEN → 숫자 다이얼.
- **재미**: Tower of London과 까마귀 전설이 매력적이다. Final이 세 미션의 숫자를 모은다.
- **단조로움**: 다이얼 문(`locked_door_gears.png`)이 있는데도 버튼만 누른다.
- **추리 부족**: M3는 "six + one more"라 너무 쉽다.
- **영어 부족**: 서수·좌우·지시어(the other way / the same way)는 좋다.
- **이유**: 몸으로 하는 퍼즐로 바꾸기 좋은 소재가 많지만, 대부분 새 엔진이 필요해 비용 대비 효과는 보통이다.

### Case 06 — The Midnight Detective · 개선 필요성 **보통**

- **진행**: 증인 심문(대화 엔진) → 단어 입력 GREY → 글 선택(월/화) → 글 선택(누구인가).
- **재미**: M1의 증인 대화는 London에서 가장 "사람을 만나는" 장면이다. Inspector Grey라는 조력자가 등장한다.
- **단조로움**: M3·Final 연속 P1.
- **추리 부족**: Final의 정체 밝히기가 보기 4개 중 하나를 고르는 것으로 끝나 극적이지 않다.
- **영어 부족**: M1이 Rookie 문장으로만 작성되어 있어 **Junior/Master 정책에 구멍**이 있다.
- **이유**: Final 연출과 난이도 누락을 보완하면 좋다.

### Case 07 — The Lost Map · 개선 필요성 **보통 (M2는 높음)**

- **진행**: 지도 고르기 → 글 선택(보트하우스 어디) → 조각 순서 → 지도 고르기.
- **재미**: 공원 지도를 손가락으로 따라가는 M1이 좋고, Final이 M1을 반복하며 비트는 구조도 좋다.
- **단조로움**: M2 "under the table, behind the watering can"은 **전치사 퍼즐인데 그림이 없다.** 보트하우스 그림은 외부 풍경이다 [확인].
- **추리 부족**: M3의 논리 조건 두 개는 좋지만, 지도 조각을 실제로 맞추는 손맛이 없다.
- **영어 부족**: 없음.
- **이유**: M2는 London 전체에서 **장면형으로 바꾸기 가장 좋은 후보**다.

### Case 08 — The Mystery on Platform 9 · 개선 필요성 **보통 (Final은 높음)**

- **진행**: 글 선택(어떤 질문?) → 이름 입력 ROBIN → 키패드 429 → 글 선택(증거 이름).
- **재미**: M1의 "질문을 고르는" 발상이 신선하다. Final에서 Case 03과 이어지는 반전이 시즌 최고의 순간 중 하나다.
- **단조로움**: Final의 결정적 증거 제시가 증거 **이름 글자 버튼** 4개다.
- **추리 부족**: M2는 승객 넷의 진술이 이미 다 적혀 있어 "듣는" 과정이 없다.
- **영어 부족**: alone / with 대조는 좋다.
- **이유**: Final을 "증거 제시 대화"로 바꾸면 시즌 중반의 클라이맥스가 살아난다.

### Case 09 — The Missing Jewel · 개선 필요성 **보통**

- **진행**: 글 선택(열쇠) → 단어 입력 ANNA → 키패드 12 → 단어 입력 HAT.
- **재미**: Final의 소거 추론(누구의 열쇠 → 누구의 물건)이 탄탄하다.
- **단조로움**: **그림 상호작용이 0개인 유일한 Case**다. 글자, 숫자, 글자가 이어진다.
- **추리 부족**: M2(알파벳)와 M3(덧셈)은 추리보다 계산·철자에 가깝다.
- **영어 부족**: 소유격(maid's key), 서수는 좋다.
- **이유**: 한 미션만이라도 장면이나 그림으로 바꾸면 리듬이 살아난다.

### Case 10 — The London Raven · 개선 필요성 **보통**

- **진행**: 글 선택(까마귀) → 요일 순서 → 그림 고르기(Tower Bridge) → 문장 조각 순서.
- **재미**: Final의 문장 조립(THE CLOCKMAKER WILL STOP BIG BEN AT MIDNIGHT)이 영어 게임다운 결정적 장면이다.
- **단조로움**: M2와 Final이 같은 Sequence 버튼이다. M2는 요일 순서만 맞추면 되는 약한 퍼즐이다.
- **추리 부족**: M1은 까마귀 묘사를 읽고 *글자* 이름을 고른다. 까마귀를 보여 주지 않는다.
- **영어 부족**: 없음.
- **이유**: M1을 "묘사 → 그림" 퍼즐로 바꾸면 Case 01 m04에서 검증된 재미를 되살릴 수 있다.

### Case 11 — The Masked Stranger · 개선 필요성 **보통 (Final은 높음)**

- **진행**: 글 선택(다른 증인) → 거꾸로 쓴 단어 입력 → 그림 고르기 → 글 선택(가면 속 인물).
- **재미**: Case 01의 Shadow가 돌아오는 반전은 시즌 서사의 핵심이다.
- **단조로움**: M1은 Case 06 M1의 *텍스트판*이다(증인 3명 대조). M2는 분장실에 거울이 있는데도 [확인] 머릿속으로 뒤집어 읽어야 한다.
- **추리 부족**: Final의 반전이 버튼 하나로 끝난다.
- **영어 부족**: 없음.
- **이유**: 시즌 반전 장면(Final)의 연출이 가장 아쉽다.

### Case 12 — The Midnight Case · 개선 필요성 **보통**

- **진행**: 글 선택(진짜 기어) → 키패드 11:40 → 수수께끼 입력 → 숫자 다이얼.
- **재미**: 시즌 전체 단서를 모으는 피날레이고, 수수께끼(M3)가 좋다.
- **단조로움**: Final이 Case 05와 같은 숫자 다이얼이다. Case 01의 그림 자물쇠와 짝을 이루는 "수미상관"을 놓치고 있다.
- **추리 부족**: M1은 속성 3개 대조라 그림으로 보여 주면 훨씬 탐정 같아진다.
- **영어 부족**: 없음.
- **이유**: 마지막 인상이 "숫자 입력"이다.

### 첫 3개 Case 종합 판단 (어린이 첫 경험)

| 질문 | 판단 |
|---|---|
| Case 01만으로 "계속하고 싶다"가 생기는가? | **예.** 6개 퍼즐 모두 조작이 다르고, 마지막 보상이 확실하다. **[추정: 코드 구조 기준, 실제 아동 플레이테스트는 아님]** |
| Case 02에서 유지되는가? | **불안하다.** M1은 좋지만, 이어지는 M2·M3가 "읽고 고르기"라 Case 01의 탐험 기대가 꺾인다. |
| Case 03에서 회복되는가? | **부분적으로.** M1 수색은 좋지만, M2·M3에서 다시 텍스트 위주가 된다. |
| 결론 | **Case 02 M2·M3·Final과 Case 03 M2·M3가 첫 이탈 위험 구간이다.** 개선 투자 1순위다. |

---

## 6. 시즌 2–4에서 재사용할 만한 엔진

재사용 등급(ready / conditional)은 `lib/data/content/puzzle_palette.dart`의 `PuzzleDefinition.reuseGrade` 값이다 [확인]. "아동 적합성"은 이 문서의 판단이다.

| # | 엔진 (palette id) | 원본 사례 | 실제 플레이 | 재미있는 이유 | London 적용 후보 | 재사용 | 새 이미지 | 난이도 | 아동 적합성 / 부작용 |
|---|---|---|---|---|---|---|---|---|---|
| R1 | `SceneExplore` (scene_explore_choose) | London m01, Rome s3_ep01_m3, NY s4_ep12_m1 | 장면을 탭해 둘러보고, 장면 안에서 답을 고름 | 찾는 재미, 정답이 "장소" | ep04_m2, ep07_m2, ep12_m1 | **ready** (London 테이블 이미 있음) | 필요 (장면 + 픽셀 좌표) | 중 | ◎ 직관적. 장면이 복잡하면 작은 화면에서 못 찾을 수 있음 → `guideAt`·`opening` 크롭으로 완화 |
| R2 | `SceneDeduction` (trace_deduction) | London m03 | 흔적 N개를 찾은 뒤 숨긴 곳 탭 | "단서를 모아 결론" 구조가 몸으로 느껴짐 | ep07_m2, ep03_m3(변형) | **ready** | 필요 | 중 | ◎ |
| R3 | `LensInspect` (lens_inspect_word) | London m02 | 돋보기 드래그 → 라벨 빈칸 입력 | 돋보기 = 탐정 도구 | ep06_m2 젖은 카드 | **ready** | 필요 (카드 장면) | 중 | ○ 드래그가 서툰 저학년을 위한 탭 대안이 이미 있음 (`tapGuide`) |
| R4 | `EvidenceRecallDock` (`Mission.recall`) | Paris C08, Rome 9회 | 노트북에서 증거를 꺼내 퍼즐 옆에 놓고 봄 | "전에 찾은 게 쓸모 있다"는 쾌감 | ep02_m3, ep03_m2, ep04_final, ep06_m3, ep09_final, ep12_m2 | **ready** (JSON 필드) | 불필요 | **하** | ◎ 퍼즐이 기다리지 않는 보조 기능이라 위험이 낮음. JSON이 바뀌므로 해시 테스트를 갱신해야 함 |
| R5 | 심볼 다이얼 (`dialSymbols`, combo_dial_lock) | London Case 01 Final | 그림이 붙은 숫자 바퀴 | 그림이 "어느 단서인지" 알려 줌 | ep05_final, ep12_final | **ready** (`final_mission_screen.dart:1216`가 모든 Final에서 읽음) | 불필요 (`clock`·`gear`·`raven` 심볼 존재 [확인]) | **하** | ◎ Case 01과의 수미상관 |
| R6 | `ClockQuestion` (clock_set) | London ep02_m1, Paris C01 M3 | 바늘 드래그 | 촉감, 시간 영어 | ep02_final (9:17) | **conditional**: face가 `Artwork` 값이어야 함 (`clockFace` 있음). **Final 화면에는 시계 분기가 없음** | 불필요 | 중 (Final 분기 개발) | ◎ |
| R7 | `CaseTalk` (evidence_talk) | Paris C11 Final | 인물 대화 중 노트북 증거를 제시 | 역전재판식 "이의 있음" 순간 | **ep08_final, ep11_final**, ep06_final | **ready** | 인물 초상 필요 (Mrs Robin 없음 / 낯선 사람은 `mysterious_stranger.png` 있음, 단 정체성 확인 필요) | 중 | ◎ 시즌 클라이맥스에 최적. 대사가 많아지면 Rookie에게 부담 → 대사를 짧게, 3–5턴 |
| R8 | `TalkMission` (퍼즐 전후 대화) | Rome 18회, NY 7회, Paris C11–12 | 퍼즐 앞에서 인물과 짧은 대화 | 사람을 "만난다" | ep08_m2(승객), ep05(Ravenmaster), ep02(Mrs Bell) | ready | 인물 초상 필요 | 중 | ○ 퍼즐 자체는 그대로라 위험이 낮음. 대화가 길면 진행이 늘어짐 |
| R9 | `DialogueInvestigation` (witness_compare) | London ep06_m1, Rome 2, NY 4 | 질문 × 인물 → 진술 대조 | 직접 묻고 모순을 찾음 | ep11_m1, ep08_m2 | conditional (palette 기준). 실제로는 Rome에서 난이도 변형 사용 중 | 초상 3–4장 | 중 | ○ 같은 Case 06 패턴의 반복이 되지 않도록 Case당 1회 이하 |
| R10 | `ImageChoiceQuestion` + `picture` 파일 (picture_choice) | London m04, NY 6회 | 묘사를 읽고 그림 고르기 | 영어 → 시각 변환 | ep10_m1 까마귀, ep12_m1 기어, ep03_m2 용의자 | ready | 그림 3–4장 | 하–중 | ◎ 단, **그림이 너무 친절하면 읽지 않고 풀린다** → 이름 숨김, 미세한 차이로 설계 |
| R11 | `LetterLockQuestion` (letter_tile_lock) | Rome·NY 각 8회, Paris C01 | 글자 타일 끌어 넣기 | 철자를 손으로 조립 | ep04_final RAVEN, ep09_m2 ANNA | ready | 불필요 | 하 | ○ 타이핑보다 쉬움 → 철자 학습 효과는 줄 수 있음. 저학년에게 유리 |
| R12 | `EasyStepsPuzzle` (guided_steps) | Paris C11–12 | 한 화면 한 지시, 2지선다, 무료 힌트 | 막히지 않음 | ep11_m2 거울 글씨 (`EasyWriting.mirrored` 존재) | ready | 장면 필요 | 중 | △ **추리가 지시 따르기로 바뀜.** 영어 추론이 줄어 London 원칙(스스로 발견)과 충돌. 국소적으로만 사용 |
| R13 | `SpotDifferences` (spot_difference) | Paris C02 M1 | 두 그림의 차이 찾기 | 누구나 아는 놀이 | (현재 London 스토리에 맞는 곳 없음) | ready | 2장 | 중 | ○ 영어 비중이 낮음 → London에는 비추천 |
| R14 | `StationClocks` (scene_compare_report) | Paris C01 M1 | 역 대합실의 시계·안내판 살피기 | 장소 관찰 | ep04_m2 승강장 시계 | conditional (역 대합실 전용 구조) | 필요 | 중–상 | ○ R1으로 충분해 우선순위 낮음 |
| R15 | `PlanRoutePuzzle` / `TrialMapPuzzle` | Paris C06 M2, C09 M1 | 평면도 이동 / 지도에 놓기 | 공간 이동 | ep05_m1, ep07_m3 | conditional + requiresDevelopment | 필요 | 상 | ○ 재미있지만 London 전용 개발 필요 |
| R16 | `RevealLayer`, `ClockWall`, `ShadowCheck`, `GearBoard` 등 Paris 전용 장치 | Paris C02, C05, C09, C10 | 슬라이더, 1분 재생, 해, 기어 | 손맛 | 대체로 London 이야기에 직접 맞지 않음 | ready–custom | 필요 | 상 | — 무리하게 넣지 않음 (CLAUDE.md 12장) |

**아동 적합성 관점의 우선순위**: R4·R5(데이터만 수정, 위험 없음) > R1·R2(검증된 London 엔진, 이미지만 있으면 됨) > R7(클라이맥스) > R10 > R3 > R6 > R8·R9 > R11 > R12.
EasySteps(R12)는 Paris에서 "혼자 하는 어린이"를 위해 도입되었지만 추리를 지시로 바꾸기 때문에, **London에는 거울 글씨 한 곳 정도만** 권한다.

---

## 7. London Case별 구체적인 개선안

공통 원칙 [제안]
- **미션 ID, 정답 문자열, Clue, Evidence, `nextMissionId`는 그대로 둔다.** London 장면 테이블은 "presentation only"로 설계되어 있어(`season1_explores.dart` 등 머리 주석), 장면 엔진이 미션의 `answer`로 그대로 제출한다. 그래서 **세이브(`completedMissionIds`)와 보상 원장(`mission:<id>`)이 바뀌지 않는다.** **[확인]**
- 새 장면 테이블을 추가하면 `season1Variants`(`season1_difficulty.dart`)에도 Junior/Master 항목을 추가해야 한다. 추가하지 않으면 `_pick`이 base(Rookie) 문장으로 대체된다(fallback). **[확인]**
- `MissionType`이나 JSON 필드(`recall`, `dialSymbols`)를 바꾸면 `test/final_small_pass_test.dart`의 "17. no other case changed"(FNV 해시) 값을 갱신해야 한다. **[확인]**
- 이미지는 CLAUDE.md 20장에 따라 **임시 그림 없이**, 사양을 먼저 확정하고 승인받은 뒤 만든다. 아래 "필요 이미지"는 사양 초안이다.
- 사운드는 추가하지 않는다.

난이도 표기: **하** = 데이터만 수정 / **중** = 기존 엔진 + 새 이미지 1–2장 + 테이블 / **상** = 엔진 개발 또는 이미지 3장 이상.

### Case 01 — 유지

| 현재 | 개선 후 | 비고 |
|---|---|---|
| 6개 모두 유지 | 변경 없음 | 기준점. 테스트 `case01_*_test.dart` 7개 보존 |

### Case 02 — The Silent Clock (우선순위 1)

| 항목 | ep02_m2 The Missing Gear | ep02_m3 The Time Card | ep02_final The Great Clock |
|---|---|---|---|
| 현재 | P1: 4개 중 "Under the smallest bell" | P1: Gallery·Picture 조합 4개 중 선택 | P6: 숫자 바퀴 9·1·7 |
| 개선 후 | **R2 SceneDeduction**: 종루에서 종 5개(크기 다름)와 노트를 보고, 흔적(쪽지가 가리키는 "not", "opposite")을 확인한 뒤 **종 밑을 탭** | **R4 recall**: 노트북의 Broken Clock Note(ep02_e1)를 꺼내 시간 카드 옆에 두고 선택 (보기 유지) | **R6 ClockQuestion**: Big Ben 시계판 바늘을 9:17로 직접 맞춤 → 종이 울리는 연출은 기존 Final 연출 재사용 |
| 플레이 변화 | 읽고 고르기 → 장면에서 찾기 | 기억 → 증거 꺼내 보기 | 숫자 → 바늘 |
| 기대 재미 | 시계탑 내부에 들어간 느낌 | "아까 그 단서!"의 연결감 | **M1에서 멈춘 시계를 내 손으로 다시 움직인다**는 수미상관 |
| 엔진 | `SceneDeduction` (`season1Deductions`에 `ep02_m2` 추가) | `EvidenceRecallDock` | `ClockQuestion` (Final 분기 신설) |
| 이미지 | **신규 1**: 종루 내부, 크기가 다른 종 5개, 가장 작은 종 아래 틈 (1536×1024, 야간, Case 01 장면과 같은 화풍) | 없음 | 없음 (`clock_face.png` 재사용) |
| 난이도 | 중 | 하 | 중 (FinalMissionScreen에 `SeasonCatalog.clock(m)` 분기 추가) |
| 데이터·테스트 영향 | JSON 불변. `case02_reasoning_test.dart`(MC 탭 가정 여부 확인 필요 [추정]), 장면 플레이스루 테스트에 London 진행 경로 추가 | JSON에 `recall` 추가 → 해시 갱신 | JSON 불변(정답 917 그대로, 시계가 "917"을 제출). `season_playthrough_test`·`full_playthrough_test`의 Final 입력 방식 수정 필요 [추정] |

### Case 03 — The Vanishing Painting (우선순위 1)

| 항목 | ep03_m2 The Three Visitors | ep03_m3 The Wet Footprints |
|---|---|---|
| 현재 | P1: 이름 3개 | P5: 장소 버튼 4개 순서 |
| 개선 후 | **R10 ImageChoice(그림 카드) + R4 recall**: 방문자 3명의 **흑백 스케치** 카드(옷 모양만 보이고 색은 없음). 색은 경비원 노트(영어)에만 있다. 노트북에서 Red Button·Blue Cloth를 꺼내 대조한 뒤 카드를 탭 | **R1/R2 변형**: Great Court 위에 젖은 발자국 4개가 그려진 장면. 발자국을 탭할 때마다 청소부 노트의 해당 줄이 체크되고, 마지막에 순서를 정한다. 순서 입력은 기존 `SequenceQuestion` 유지 (장면 아래 배치) |
| 플레이 변화 | 이름 → 용의자 카드 + 증거 대조 | 버튼만 → 장면에서 발자국 확인 후 순서 |
| 기대 재미 | 첫 "범인 지목"의 긴장감 | 발자국을 눈으로 따라감 |
| 엔진 | `ImageChoiceQuestion`(`ChoiceOption.picture`, 이름 표시) + `recall` | **추천안 A**: `SceneExplore`의 `note` 스팟 4개(발자국) + 기존 Sequence (개발: Explore가 끝난 뒤 기본 퍼즐로 넘기는 연결, 중). **대안 B**: 장면은 이야기 단계 그림으로만 쓰고 Sequence는 그대로 (하) |
| 이미지 | **신규 3**: Mr Green / Miss Rose / Mr Grey 흑백 스케치 초상 (같은 구도) | **신규 1**: Great Court 바닥에 발자국 4개(물기 정도가 보이게), 상점·계단·카페·북문 표지 |
| 난이도 | 중 | A: 중–상 / B: 중 |
| 데이터·테스트 영향 | `options[].picture` 추가 → JSON 해시 갱신. 정답 `b` 유지. **흑백이어야 영어 읽기가 유지됨**(색을 그리면 읽지 않고 풀림) | A: 새 엔진 연결 테스트 필요. 정답 `shop,stairs,cafe,door` 유지 |

ep03_m1(수색)과 ep03_final은 유지한다.

### Case 04 — The Secret Letter

| 항목 | ep04_m2 The Four Words | ep04_final The Last Letter |
|---|---|---|
| 현재 | P1 | P3 RAVEN |
| 개선 후 | **R1 SceneExplore**: King's Cross 승강장 장면에서 1·4·7·9번 승강장을 탭해 시계·문을 관찰(짐꾼의 말이 노트로 적힘) → 단어 카드와 맞는 승강장 탭 | **R4 recall**: 노트북의 Black Wax Seal(ep04_e1) 호출. 입력 방식(P3)은 유지 |
| 기대 재미 | "빨간 문 ≠ 빨간 시계"를 눈으로 구분 | 봉인을 다시 들여다보는 탐정 동작 |
| 엔진 | `SceneExplore` | recall |
| 이미지 | **신규 1**: 승강장 4개(흰 큰 시계 / 빨간 작은 시계 / 빨간 문, 시계 없음 / 초록 시계), 번호판 | 없음 |
| 난이도 | 중 | 하 |
| 영향 | JSON 불변 | 해시 갱신 |

ep04_m1(운영시간표)과 ep04_m3(소인)은 유지한다. m1은 장면이 아니라 **문서 읽기**가 본질이므로 그대로 두는 것이 낫다.

### Case 05 — The Locked Room

| 항목 | ep05_final The Iron Chest | (선택) ep05_m2 The Dial Door |
|---|---|---|
| 현재 | P6 숫자 바퀴 | P5 LEFT/RIGHT 버튼 |
| 개선 후 | **R5 심볼 다이얼**: `dialSymbols: ['raven','gear','clock']`. 자물쇠마다 그림이 붙어 "어떤 단서인지"가 보인다 | 다이얼 문 그림(`locked_door_gears.png`)을 Sequence 위에 크게 보여 주고, 탭할 때마다 화살표 표시. 기존 Sequence 유지 |
| 기대 재미 | Case 01 Royal Box와 같은 "그림 자물쇠" | 문을 돌리는 느낌 (약함) |
| 엔진 | 기존 Final 심볼 다이얼 | 표현만 변경 (개발 필요) |
| 이미지 | 없음 | 없음 |
| 난이도 | 하 | 중 (가치 대비 비용이 커서 **보류 권장**) |
| 영향 | JSON 해시 갱신. 정답 745 유지 | — |

ep05_m1·m3는 유지한다(Tower 이야기와 영어 지시어가 좋음).

### Case 06 — The Midnight Detective

| 항목 | ep06_m1 Three Witnesses | ep06_m2 The Wet Card | ep06_final The Midnight Detective |
|---|---|---|---|
| 현재 | P10 (Rookie만 작성) | P3 GREY | P1 |
| 개선 후 | **Junior/Master 대화 문장 작성** (`season1Variants`에 `dialogues` 추가). 구조는 그대로 | **R3 LensInspect**: 분수대 옆 젖은 명함을 돋보기로 보며 뒷면 문장 3줄 확인 → `INSPECTOR ____` 라벨 입력 | **R7 CaseTalk**: 분수대의 남자와 대화하며 "Who are you?" → 노트북의 Detective Card 제시 → 정체 확인. 대화가 끝나면 정답 `c` 제출 |
| 기대 재미 | 난이도 정책 완성 | 돋보기 탐정 도구 재등장 (Case 01 m02 이후 처음) | 조력자와의 첫 만남이 "증거로 밝혀 내는" 장면이 됨 |
| 엔진 | `DialogueInvestigation` (variants) | `LensInspect` | `CaseTalk` |
| 이미지 | 없음 | **신규 1**: 밤의 분수대 옆 젖은 명함(앞면 INSPECTOR ___, 뒷면 손글씨 영역) | **확인 필요**: `mysterious_stranger.png`가 Inspector Grey(키 큼, 어두운 코트, 회색 모자, 작은 가방)와 맞는지. 맞지 않으면 **신규 1**: Inspector Grey 초상(표정 2–3종) |
| 난이도 | 하 (텍스트) | 중 | 중 |
| 영향 | `season1WrittenLevels['ep06']`에 Junior·Master 추가 → `difficulty_london_6b_test` 갱신 | JSON 불변 | CaseTalk의 Final 지원은 Paris C11에서 확인됨 [확인]. London Final에 연결할 때 `caseEnding` 등 확인 필요 [추정] |

### Case 07 — The Lost Map (M2 우선순위 1)

| 항목 | ep07_m2 The Boathouse | (선택) ep07_m3 The Three Pieces |
|---|---|---|
| 현재 | P1 전치사 | P5 |
| 개선 후 | **R2 SceneDeduction**: 보트하우스 **내부** 장면. 문에 긁힌 글 4줄이 노트로 표시되고, 선반·탁자 위·탁자 밑 물뿌리개 앞·**뒤**에 상자를 배치. 단서를 확인한 뒤 숨긴 곳을 탭 | 유지 (조각 그림을 Sequence 타일에 붙이는 것은 엔진 확장이 필요해 보류) |
| 기대 재미 | **NOT / under / behind / in front of를 손가락으로 확인**. London 영어 목표와 정확히 맞음 | — |
| 엔진 | `SceneDeduction` (또는 `SceneExplore`) | — |
| 이미지 | **신규 1**: 보트하우스 내부(노, 밧줄, 선반, 탁자, 초록 물뿌리개, 상자 두 개: 하나는 물뿌리개 앞, 하나는 뒤에 반쯤 가려짐) | — |
| 난이도 | 중 | — |
| 영향 | JSON 불변. 정답 `c` 유지. 오답 장소별 `feedback` 그대로 재사용 | — |

ep07_m1과 ep07_final(지도)은 유지한다. 같은 조작이지만 의도된 수미상관이다.

### Case 08 — The Mystery on Platform 9 (Final 우선순위 1)

| 항목 | ep08_m2 Four Passengers | ep08_final The Last Train |
|---|---|---|
| 현재 | P3 ROBIN | P1 증거 이름 |
| 개선 후 | **R8 TalkMission(앞)**: 대합실에서 승객 4명에게 M1에서 고른 질문 "Where are you going?"을 묻는 짧은 대화. 대화가 끝나면 기존 `MRS _____` 입력 | **R7 CaseTalk**: Mrs Robin이 "You cannot prove it!"이라고 말하면 노트북 → Case Archive → Case 03 → Red Button을 **제시**. 다른 증거를 내면 기존 `feedback` 문장으로 반응 |
| 기대 재미 | M1에서 고른 질문을 실제로 써먹음 | **시즌 중반 최고의 반전을 직접 터뜨림** |
| 엔진 | `TalkMission` | `CaseTalk` |
| 이미지 | **신규 4**: Mrs Patel, Mr Brown, Lily(아빠와 함께), Mrs Robin(긴 빨간 코트) 초상. 배경은 `kings_cross_waiting_hall.png` 재사용 | Mrs Robin 초상 공용 (표정 3종: 침착 / 당황 / 체념) |
| 난이도 | 중 | 중 |
| 영향 | JSON 불변(대화는 별도 테이블). 대화 진행 상태는 `puzzleStates`에 저장됨 → 이전 세이브와 호환 [추정] | `final_small_pass_test` 1–16번이 이 Final의 문장을 고정하고 있음 → **문장은 유지**하고 화면만 바꿔야 함. 이 테스트 그룹의 `screens` 부분은 갱신 필요 [추정] |

ep08_m1(질문 고르기)과 ep08_m3는 유지한다.

### Case 09 — The Missing Jewel

| 항목 | ep09_m1 The Empty Box |
|---|---|
| 현재 | P1 열쇠 3개 |
| 개선 후 | **R1 SceneExplore**: 보석실 장면(`empty_glass_jewel_case.png` 재사용)에서 부서지지 않은 자물쇠, 남겨진 카드, 집사를 탭 → 열쇠 판(신규)에서 **열쇠 그림 3개 중 선택**. 열쇠 그림은 크기·재질이 미묘하게 달라 "big gold"를 읽어야 고를 수 있음 |
| 기대 재미 | 그림 상호작용이 0개였던 Case에 탐색 1회 추가 |
| 엔진 | `SceneExplore` (`ExploreKind.choice` 스팟을 열쇠 판으로) |
| 이미지 | **신규 1**: 열쇠 판(작은 은 열쇠 / 오래된 철 열쇠 / 큰 금 열쇠 + 빈 고리). 기존 보석함 장면의 픽셀 좌표 측정 필요 |
| 난이도 | 중 |
| 영향 | JSON 불변. 정답 `c` 유지 |

ep09_m2(ANNA)는 **R11 LetterLock**으로 바꾸는 것도 가능하지만(하), 철자 쓰기 학습이 약해지므로 **유지를 권장**한다. ep09_m3와 ep09_final도 유지한다.

### Case 10 — The London Raven

| 항목 | ep10_m1 Which Raven? |
|---|---|
| 현재 | P1 이름 4개 |
| 개선 후 | **R10 ImageChoice(이름 숨김)**: 까마귀 4마리 그림. Ravenmaster의 묘사(biggest / white feather / smallest + gold ring / noisy)를 읽고 "small, quiet, gold ring"에 맞는 그림을 탭. 이름은 정답 뒤에 공개 |
| 기대 재미 | Case 01 m04에서 검증된 "묘사 → 그림" 재미. Poppy가 이후 Case 12까지 나오는 캐릭터라 얼굴을 기억하게 됨 |
| 엔진 | `ImageChoiceQuestion` + `picture`, `hideOptionNames: true`, `altText` |
| 이미지 | **신규 4**: 같은 구도의 까마귀 4마리(크기 차이, 흰 깃털, 다리의 금 고리, 입 벌린 "noisy" 자세) |
| 난이도 | 중 |
| 영향 | JSON 해시 갱신. 정답 `c` 유지. "quiet / noisy"는 그림으로 전달이 어려움 → 크기 + 고리만으로도 답이 하나로 정해지게 설계 |

ep10_m2(요일)는 약한 퍼즐이지만 바꿀 이득이 작아 유지한다. ep10_final(문장 조립)도 유지한다.

### Case 11 — The Masked Stranger (Final 우선순위 1)

| 항목 | ep11_m2 The White Mask | ep11_final Behind the Mask |
|---|---|---|
| 현재 | P3 거꾸로 쓴 단어 입력 | P1 인물 4명 |
| 개선 후 | **분장실 거울 활용**: 분장실 장면에서 가면 탭 → 안쪽 글씨 THGINDIM → 거울 탭 → 거울 속에 MIDNIGHT가 비침 → 입력. 추천은 `SceneExplore` 스팟 2개 + 기존 WordInput 유지. **대안**: R12 EasySteps(`EasyWriting.mirrored`, 입력 없이 2지선다) | **R7 CaseTalk**: 가면 쓴 인물이 "Do you remember me?"라고 말하면 Case 01의 Old Letter(e01, "P.S. I love trains!")를 **제시** → 가면을 벗음 |
| 기대 재미 | 거울이 실제 도구가 됨 | **시즌의 정체 반전을 직접 밝혀 냄** |
| 엔진 | `SceneExplore` (+ 기본 WordInput) | `CaseTalk` |
| 이미지 | **신규 1**: 흰 가면 클로즈업(안쪽 글씨 영역 비움, 글씨는 앱이 씀). 분장실 배경은 재사용 [확인: 거울 있음] | `mysterious_stranger.png` 사용 가능 여부 확인. 가면 쓴 모습 / 벗은 모습 2종 필요 (신규 1–2) |
| 난이도 | 중 | 중 |
| 영향 | JSON 불변 | Final 문장 고정 테스트 확인 필요 |

ep11_m1(증인 3명, 텍스트판)은 Case 06 M1과 겹치지만, Case 11 Final을 CaseTalk로 바꾸면 대화형이 연달아 나오게 되므로 **유지를 권장**한다.

### Case 12 — The Midnight Case

| 항목 | ep12_m1 The Real Gear | ep12_m2 The Last Train In | ep12_final The Clockmaker's Door |
|---|---|---|---|
| 현재 | P1 속성 조합 4개 | P4 11:40 | P6 숫자 바퀴 |
| 개선 후 | **R10 ImageChoice**: 탁자 위 기어 4개 그림(은 / 놋쇠, 이빨 6 / 8, 까마귀 도장 유무). 이빨을 세고 도장을 찾는 관찰 | **R4 recall**: Case 04 Word Card(ep04_e2) 호출 | **R5 심볼 다이얼**: `dialSymbols: ['clock','gear','raven']` → Case 01 Royal Box와 수미상관 |
| 기대 재미 | "가짜 기어"를 눈으로 가려냄 | 시즌을 관통하는 단서 연결 | 시작과 끝이 같은 그림 자물쇠 |
| 엔진 | `ImageChoiceQuestion` + `picture` | recall | 기존 Final 심볼 다이얼 |
| 이미지 | **신규 4** (또는 기어 4개가 한 장에 있는 그림 1장 + `SceneExplore`) | 없음 | 없음 |
| 난이도 | 중 | 하 | 하 |
| 영향 | 해시 갱신. 정답 `d` 유지 | 해시 갱신 | 해시 갱신. 정답 487 유지 |

### 7-추가. 데이터만 손대면 되는 개선 묶음 (Quick Wins)

| 대상 | 변경 | 효과 |
|---|---|---|
| ep02_m3, ep03_m2, ep04_final, ep06_m3, ep09_final, ep12_m2 | `recall` 추가 | 노트북이 "도구"가 됨. London 0회 → 6회 |
| ep05_final, ep12_final | `dialSymbols` 추가 | 그림 자물쇠의 일관성, 수미상관 |
| ep06 | Junior/Master 대화 문장 | 난이도 정책 완성 |

---

## 8. A / B / C 개선 범위 비교

| | **A. 최소 개선** | **B. 균형 개선** | **C. 대규모 개선** |
|---|---|---|---|
| 범위 | Quick Wins(7-추가) + ep07_m2 + ep08_final | A + Case 02(m2·m3·final) + Case 03(m2·m3) + ep04_m2 + ep06(m2·final) + ep09_m1 + ep10_m1 + ep11(m2·final) + ep12(m1·final) | London 50개 전체를 Paris 방식으로 재설계 (Case마다 전용 장치, 평면도·지도 배치 등) |
| 변경 퍼즐 수 | 약 11 (그중 화면이 바뀌는 것 2) | 약 24 (화면이 바뀌는 것 약 15) | 40개 이상 |
| P1–P7 비중 (Case 02–12) | 93% → 약 89% | 93% → **약 60%** | 30% 미만 목표 |
| 첫 3개 Case 개선 | 거의 없음 | **집중 개선** | 전면 |
| 새 이미지 | 2–3장 (보트하우스 내부, Mrs Robin 초상) | **약 20–24장** (장면 6–7 + 초상 8–10 + 물건 카드 8) | 60장 이상 (Paris 167장 수준의 절반) |
| 엔진 개발 | 없음 (CaseTalk의 London Final 연결 확인만) | 소규모 2건: ① Final 화면의 ClockQuestion 분기 ② (선택) Explore → 기본 퍼즐 연결 | London 전용 엔진 다수 신규 |
| 세이브 호환 | 완전 호환 | 완전 호환 (ID·정답 유지, 장면 테이블은 저장하지 않음) | 미션 구조를 바꾸면 진행 중 세이브의 위치가 어긋날 위험 |
| 다른 시즌 영향 | 없음 | 거의 없음 (Final 분기 추가 시 Paris·Rome·NY Final 회귀 확인 필요) | 공용 엔진 수정 시 위험 |
| 테스트 영향 | 해시 테스트, ep08 Final 화면 테스트 | London 플레이스루 3종(`full_playthrough`, `season_playthrough`, `season_scene_playthrough`) + Case별 테스트 + 난이도 6A–6D + 해시 | 대부분의 London 테스트 재작성 |
| 위험도 | **낮음** | **중간** (이미지 품질과 픽셀 좌표 정확도가 관건) | **높음** (일정, 이미지 예산, 회귀, 난이도 3단계 재작성) |
| 장점 | 빠름, 안전 | 첫 경험(Case 02–03)과 시즌 클라이맥스(08·11 Final)가 확실히 좋아짐. 검증된 London 엔진 재사용 | 최고 수준의 다양성 |
| 단점 | 첫 이탈 구간(Case 02–03)이 그대로 | 이미지 제작·검수 부담 | 비용 대비 효과 체감, "London 텍스트 추리"의 장점이 희석될 위험, 8–12세에게 조작이 과해질 수 있음 |

---

## 9. 최종 추천 및 구현 우선순위

### 추천: **B. 균형 개선**을 3단계로 나눠 진행

**이유**
1. London의 약점은 *내용*이 아니라 *조작의 단조로움*이다. 정답·텍스트·단서 연결은 이미 좋으므로 **화면만 바꾸는 "presentation only" 장면 테이블 방식**(Case 01에서 검증됨)이 가장 효율적이다.
2. Case 01의 높은 기대치가 Case 02–03에서 꺾이는 것이 가장 큰 위험이다. 그래서 B안의 투자를 그 구간에 집중한다.
3. C안은 Paris 수준의 다양성을 줄 수 있지만, 8–12세 첫 시즌에는 조작 종류가 너무 많아질 수 있다. 영어 읽기 추리라는 London의 정체성도 약해질 수 있다.

### 구현 우선순위

| 단계 | 작업 | 이유 | 이미지 | 개발 |
|---|---|---|---|---|
| **1단계 (Quick Wins, 1회 커밋 분량)** | recall 6곳, dialSymbols 2곳(ep05·ep12 Final), ep06 Junior/Master 대화 문장 | 위험 없이 노트북·수미상관·난이도 정책 개선 | 0 | 데이터 + 해시 테스트 갱신 |
| **2단계 (첫 경험)** | ① ep02_m2 종루 SceneDeduction ② ep02_final ClockQuestion ③ ep03_m2 용의자 흑백 카드 ④ ep07_m2 보트하우스 내부 | Case 02–03의 이탈 위험 구간 + London에서 가장 그림이 필요한 전치사 퍼즐 | 종루, 초상 3, 보트하우스 내부 = 5장 | Final 시계 분기 (중) |
| **3단계 (클라이맥스)** | ⑤ ep08_final CaseTalk(Mrs Robin) ⑥ ep11_final CaseTalk(Shadow) ⑦ ep06_final CaseTalk(Grey) | 시즌의 세 반전을 "증거 제시"로 | 초상 3–5인(표정 포함) | London Final의 CaseTalk 연결 확인 |
| **4단계 (리듬 보강)** | ep04_m2 승강장, ep10_m1 까마귀, ep12_m1 기어, ep09_m1 열쇠, ep06_m2 젖은 카드, ep11_m2 거울, ep08_m2 승객 대화, ep03_m3 발자국 | Case 중반의 P1 연속 해소 | 약 12–15장 | 대부분 테이블만. ep03_m3 A안은 연결 개발 |

### 착수 전 결정이 필요한 항목 (사용자 결정)

1. **이미지 예산과 화풍**: 2단계에 필요한 이미지 5장의 사양 승인 (CLAUDE.md 20장: 임시 그림 금지).
2. **ep03_m2 용의자 카드를 흑백 스케치로 할지**: 색을 그리면 영어를 읽지 않고도 풀린다. 흑백을 권장한다.
3. **CaseTalk 3개(ep06·08·11 Final)를 모두 적용할지**: 대화형 Final이 3번이면 반복으로 느껴질 수 있다. **ep08·ep11 두 곳만** 먼저 적용하는 것을 권장한다.
4. **`mysterious_stranger.png`를 Inspector Grey 또는 Shadow로 쓸 수 있는지**: 현재 시즌 프롤로그에서만 쓰고 있다(`prologue_art.dart:268`). 누구를 그린 그림인지 확인이 필요하다.
5. **ep09_m2를 LetterLock으로 바꿀지**: 저학년에게는 쉬워지지만 철자 쓰기 학습이 줄어든다. 유지를 권장한다.

### 확인하지 못한 사항 / 남은 위험

- 실제 기기에서 London을 플레이해 보지 않았다. 재미·이탈 판단은 코드 구조와 퍼즐 설계를 근거로 한 **[추정]**이다.
- Rome·NY는 질문 문장과 엔진 매핑까지만 확인했다. 개별 정답 과정은 **[추정]**이다.
- `case02_reasoning_test`, `case09_reasoning_test`, 플레이스루 테스트 3종이 London 화면을 어떤 방식으로 조작하는지는 열어 보지 않았다. 테스트 영향 범위는 **[추정]**이다.
- London 장소 이미지 59장 중 4장만 직접 열어 보았다. 나머지 "배경 전용" 판단은 파일 이름과 `ArtAssets` 주석을 근거로 한 **[추정]**이다.
- `puzzle_palette.dart`의 `witness_compare` 제약("No level variant")은 Rome의 실제 사용과 맞지 않는다. 문서 갱신이 필요할 수 있다(이번 작업에서는 수정하지 않음).
