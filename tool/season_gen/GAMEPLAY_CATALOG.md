# 게임 방식 카탈로그 (STEP 3-13)

**작성:** 2026-10-29 · **근거:** 실제 코드. `SeasonCatalog.all`의 London 12 + Paris 12 Case, 미션·Final 98개를 하나씩 열어 등록된 테이블과 `PuzzleEngineDispatch`(화면이 엔진을 고르는 순서)로 실제 플레이되는 엔진을 집계했다. 목록을 먼저 정하고 맞춘 것이 아니라, 코드가 고르는 엔진을 그대로 분류했다.

이 문서는 새 시즌을 기획하는 사람(또는 Claude)이 **어떤 탐정 활동을 자동 생성할 수 있는지**, 무엇이 아직 안 되는지를 고르는 기준이다. 퍼즐 메타데이터의 원본은 `lib/data/content/puzzle_palette.dart`(`PuzzlePalette`)이고, Studio 쪽 사본은 `tool/season_gen/palette_facts.dart`다.

---

## 1. 요약

| 구분 | 수 | 내용 |
|---|---|---|
| 실제 쓰이는 엔진 | 46 | 기본 질문 위젯 6(`questionFor` 5 + Final 다이얼) + 테이블 엔진 40 |
| 팔레트에 등록된 퍼즐 | 28 | 다른 시즌이 재사용할 수 있게 정리된 엔진 |
| 팔레트 밖 Paris 전용 엔진 | 23 | 그 Case만을 위해 만든 위젯(`lifts`, `drumTapes` …) |
| **Generator가 만드는 퍼즐** | **9** | 텍스트 5종(STEP 3-8) + 그림 4종(이번 STEP 3-13) |

이번 단계에서 새로 자동 생성할 수 있게 된 방식:

| 사용자 요청의 방식 | 실제 엔진 | 원본 사례 | 팔레트 id | 생성 |
|---|---|---|---|---|
| A. 현장 탐색 | `SceneExplore` (`explores`) | London Case 01 M1 King's Cross | `scene_explore_choose` | **지원** |
| B. 그림 속 숨은 단서 찾기 | `InvestigationSearch` (`investigations`) | London Case 03 M1 Gallery 8 | `dark_room_search` | **지원** (`lib/` 변경: 그림 파일 허용) |
| C. 증인 대화·진술 비교 | `DialogueInvestigation` (`dialogues`) | London Case 06 M1 Covent Garden | `witness_compare` | **지원** |
| D. 그림·증거 선택 | `ImageChoiceQuestion` (`imageChoice`) | London Case 01 M4, 03 F, 04 M3, 07 M1·F, 10 M3, 11 M3 | `picture_choice` | **지원** (`lib/` 변경: 그림 파일 허용) |

---

## 2. 모든 미션이 공유하는 진행 흐름 (실제 코드)

```
Story Intro(타자기) → Map(핀) → 장소 도착 Story(INVESTIGATE)
   → [편지 봉투 TAP TO OPEN → SOLVE THE PUZZLE]   ← skipsLetter 테이블이면 생략
   → 엔진 화면(퍼즐/상호작용) → submitAnswer(정답 판정·저장·보상)
   → Discovery Moment → transition 장면 → TO THE MAP (다음 미션 해금)
   … → Final(FinalMissionScreen) → CASE SOLVED → 사건 후 장면 → Case Report → 다음 Case 해금
```

- 정답 판정은 모든 엔진이 같은 길을 쓴다: 엔진이 고른 답을 `GameController.submitAnswer(mission, answer)`가 `AnswerChecker`로 판정하고 저장(`GameProgress.completedMissionIds`), XP·코인, 단서·증거 수첩 반영까지 한다. 엔진 화면 안의 진행(본 곳, 들은 진술, 찾은 물건)은 **저장하지 않는다**. 앱을 다시 열면 그 미션은 처음부터 다시 한다.
- 힌트: 모든 미션 2개(`AppConstants.maxHints`), 무료 힌트·팁 숍이 공통으로 붙는다(엔진마다 표시 위치만 다름).
- 오답: 선택형은 `ChoiceOption.feedback`, 입력·순서형은 `Mission.feedback`/`orderFeedback`. 오답은 첫 시도 보너스만 잃고 바로 다시 시도한다. 탐색·수색은 "틀린 답"이 없다(빈 곳을 누르면 설명만).
- 뒤로가기: 엔진 화면에서 Back → 장소/문서 화면. 수색은 찾은 것을 화면이 열려 있는 동안 기억한다.
- `skipsLetter`(편지 화면 생략): `explores`, `inspections`, `deductions`, `decodes`, `dialogues`, `talks`, `easySteps`와 Paris 전용 다수. 편지는 장면 안에서 읽는다(가방 속 편지, 경비원 보고서, 증인의 말).

---

## 3. 카탈로그

열 설명: **사용 Case**는 코드 집계(L=London, P=Paris, `03-M1` = Case 03 Mission 1, F = Final). **Gen**은 Studio Generator, **Plan**은 Season Planner(PLAYBOOK·검사)가 지원하는지. **테스트**는 그 방식을 플레이로 검증하는 테스트.

### 3.1 기본 질문 위젯 (테이블 없음, `questionFor`)

| Type ID | 설명 | 사용 Case | Flutter 구현 | 입력 데이터 | 이미지 | 정답 판정 | Gen | Plan | 테스트 |
|---|---|---|---|---|---|---|---|---|---|
| `text_choice` | 문서를 읽고 3~4개 보기 중 하나 | L 02-M2·M3, 03-M2, 04-M1·M2, 05-M1, 06-M3·F, 07-M2, 08-M1·F, 09-M1, 10-M1, 11-M1·F, 12-M1 (16) | `MultipleChoiceQuestion` (`question_widgets.dart`) | letter, question, options(+feedback), answer, hints | 장소만 | 보기 id | ✅ | ✅ | `s9_multi_case_test`, `full_playthrough_test` |
| `word_entry` | 단서 속 단어를 입력 | L 04-F, 05-M3, 06-M2, 08-M2, 09-M2·F, 11-M2, 12-M3 (8) | `WordInputQuestion` | answer, acceptedAnswers, prompt, feedback | 장소만 | 대문자·영숫자 정규화 비교 | ✅ | ✅ | `s9_ep01_test` |
| `order_sequence` | 보기를 순서대로 누름 | L 03-M3, 05-M2, 07-M3, 10-M2·F, P 01-M2 (6) | `SequenceQuestion` | options, answer "a,b,c", codeLength, orderFeedback | 장소만 | id 순서 | ✅ | ✅ | `s9_multi_case_test` |
| `picture_choice` | 그림 3~4장 중 선택(이름 숨김 가능) | L 01-M4, 03-F, 04-M3, 07-M1·F, 10-M3, 11-M3 (7) | `ImageChoiceQuestion` | options(+altText, feedback), hideOptionNames | **선택지마다 1장** | 보기 id | ✅ **신규** | ✅ **신규** | `s9_ep03_test` |
| `number_entry` | 숫자/시각을 키패드로 | L 08-M3, 09-M3, 12-M2 (3) | `NumberCodeQuestion` | answer, codeLength, codeFormat | 장소만 | 숫자열 | ❌ (생성기 미포함, 팔레트 textOnly) | ❌ | — |
| `letter_tile_lock` | 글자 타일로 단어 | P 01-F (1, +`lockBoxes` 상자 연출) | `LetterLockQuestion` | options(타일), answer, lockTitle | 장소만(상자는 선택) | 타일 글자 | ✅ (상자 없이) | ✅ | `s9_ep01_test` |
| `combo_dial_lock` | Final 다이얼 잠금 | L 01-F, 02-F, 05-F, 12-F (4) | `_Dial` (`final_mission_screen.dart`) | answer, codeLength, dialSymbols | 장소만 | 숫자열 | ✅ | ✅ | `s9_multi_case_test` |

### 3.2 그림 위 상호작용 — 이번에 생성 지원

| Type ID | 설명 | 사용 Case | Flutter 구현 | 입력 데이터(Plan `play.*`) | 이미지 | 정답 판정 | Gen | Plan | 테스트 |
|---|---|---|---|---|---|---|---|---|---|
| `scene_explore_choose` | 장소 그림을 눌러 둘러봄 → 문서(편지)가 든 물건 발견 → 단서 메모 → 선택 보드에서 그림 하나 고름 | L 01-M1 | `SceneExplore` (`scene_explore.dart`), 모델 `ExploreScene` | `play.explore`: picture, spots(document 1·note·choice 1, areas, mark, requires/lockedLine/unreadLine), others(빈 곳), choices(optionId·그림·설명), choicePixels, guideAt, inside/opening | 장소 그림 1 + 선택 그림 N(같은 크기) | 고른 그림의 option id | ✅ | ✅ | `s9_ep03_test` M1 (잠긴 보드, 편지, 오답 후 재시도) |
| `dark_room_search` | 문서(보고서)의 위치 문장대로 그림 속 물건을 찾음, 확대·드래그, 발견 카드 | L 03-M1 | `InvestigationSearch` (`investigation_search.dart`), 모델 `InvestigationScene` | `play.search`: picture, finds(reportLine = 편지의 한 줄, areas, 찾은 물건 그림·at·width·squash·turn), spots(빈 곳), arrival, guideAt, opening/inside, startLabel | 장소 그림 1 + 찾은 물건 오려낸 그림 N | 마지막 물건을 찾으면 puzzle answer 제출(오답 없음) | ✅ | ✅ | `s9_ep03_test` M2 (Back 후 유지, 재시작) |
| `witness_compare` | 증인 선택 → 질문 → 진술이 노트에 기록 → 두 진술 비교(모순/일치 판정) → 남은 진술 확인 | L 06-M1 | `DialogueInvestigation` (`dialogue_investigation.dart`), 모델 `DialogueScene` | `play.dialogue`: background, questions, witnesses(초상화, greeting, answers{질문: line, thing?}), deduction(topic, pair, then, 대사 10+4줄) | 배경 1 + 증인 초상화 N | 비교한 두 진술이 pair면 deduction.answer 제출 | ✅ | ✅ | `s9_ep03_test` M3 |
| `picture_choice` | (위 3.1) | | | `answerSpec.options[].picture`, `altText`, `play.hideOptionNames` | | | ✅ | ✅ | `s9_ep03_test` M4 (힌트, 오답, 재시도) |

### 3.3 그림 위 상호작용 — 엔진은 재사용 가능, 생성은 아직

모두 `PuzzleGenerationMode.requiresAssets`(그림 파일 기반)라 Plan 스키마만 추가하면 같은 방식으로 생성할 수 있다. 이번 단계 범위 밖.

| Type ID | 설명 | 사용 Case | Flutter 구현 | 핵심 데이터 | 이미지 | 정답 판정 | Gen | Plan |
|---|---|---|---|---|---|---|---|---|
| `lens_inspect_word` | 돋보기를 끌어 전시물 확인 → 맞는 전시물 라벨의 빈칸 입력 | L 01-M2 | `LensInspect`, `InspectScene` | spots(exhibit/match/label/hidden, checks) | 방 1 | 입력 단어 | ❌ | 기획만(`awaitingAssets`) |
| `trace_deduction` | 흔적을 모두 눌러 기록 → 흔적이 가리키는 장소를 그림에서 선택 | L 01-M3 | `SceneDeduction`, `DeductionScene` | clues(line = 편지 한 줄), places(optionId) | 장소 1 | 장소 option id | ❌ | 기획만 |
| `object_decode` | 물건을 가까이 → 스캔 → 숨은 메시지 → 획득 | L 01-M5 | `SceneDecode`, `DecodeScene` | thing, code, cleared | 2(원본, 코드 지운 것) | 오답 없음 | ❌ | 기획만 |
| `spot_difference` | 두 그림의 다른 곳 모두 찾기 | P 02-M1 | `SpotDifferences`, `CompareScene` | changes(rect) | 2(같은 구도) | 모두 찾으면 | ❌ | 기획만 |
| `room_find_match` | 방에서 그림 찾기 → 메모와 짝짓기 | P 02-M2 | `StudioMatch` | paintings, order | 방 + 그림 N | 짝 | ❌ | 기획만 |
| `layer_reveal` | 위 그림을 밀어 아래 스케치 표시 → 표시 찾기 | P 02-M3 | `RevealLayer` | marks | 2(정합) | 표시 | ❌ | 기획만 |
| `clue_filter_choice` | 후보를 모두 보고 모든 단서에 맞는 것 선택(Final) | P 02-F | `CanvasPicker` | canvases, back, message | 후보 N + 뒷면 | option id | ❌ | 기획만 |
| `record_mismatch` | 두 기록을 읽고 어긋난 줄 짝 | P 03-M1 | `TowerRecords` | 두 문서 lines | 빈 종이 | 줄 짝 | ❌ | 기획만 |
| `symbol_dial_lock` | 그림 기호 다이얼 자물쇠 | P 03-M3 | `DialLock` | symbols, windows, angle | 자물쇠·다이얼 | 기호 순서 | ❌ | 기획만 |
| `viewpoint_match` | 지도 위 지점마다 보이는 풍경 → 이전 증거 그림과 비교 | P 08-M1 | `PainterCornerPuzzle` | corners, recall | 지도 + 풍경 N | option id | ❌ | 기획만 |
| `guided_steps` | 한 화면 한 단계(보기·누르기·문지르기·둘 중 하나) | P 04-F, 05-M3·F, 07-M1·M2·F, 11-M1~M3, 12-M1~F (13) | `EasyStepsPuzzle` | steps(say, panels, does, options) | 단계별 그림 | 단계 answer | ❌ | 기획만 |
| `evidence_talk` | 한 인물과 대화, 질문 후 프롬프트마다 수첩 증거 제시 | P 11-F (+`talkMissions` 동반: P 11-M1·M2, 12-M1~M3) | `CaseTalk` | speaker(portraits 기분별), questions, presents | 초상화 N + 배경 | 증거 id | ❌ | 기획만 |
| `scene_compare_report` | 역 시계들 확대 → 안내판 → 틀린 시계 신고 | P 01-M1 | `StationClocks` | 시계 시각·위치 | 역 홀 1 | option id | ❌ | 기획만(조건부: 역 전용 문구) |

### 3.4 코드 변경이 필요한 방식 (`requiresDevelopment`)

| Type ID | 사용 Case | 막는 것 |
|---|---|---|
| `clock_set` | L 02-M1, P 01-M3 | `ClockPuzzle.face`가 `Artwork` enum |
| `evidence_board` | P 03-F | Case 전용 무대(기계·명판) |
| `closeup_compare_choose` | P 04-M1, 05-M1, 06-M1, 06-F | 엔진 4개가 각자 모델(`RiverMarks`, `MarkCompare`, `HoldRack`, `LetterMap`) |
| `token_place_map` | P 09-M1 | 스크린리더 설명이 Paris 지도로 고정 |
| `symbol_join` | P 09-M3 | `MarkKind` enum을 위젯이 그림 |

### 3.5 팔레트 밖 Paris 전용 엔진 (23)

그 Case만을 위해 만든 위젯이라 새 시즌에 제공하지 않는다: `LiftRoute`(P03-M2), `KeeperHut`(P04-M2), `LabelAssembly`(P04-M3), `ClockWall`(P05-M2), `PlanRoutePuzzle`(P06-M2), `ArchivePuzzle`(P06-M3), `FlyRailPuzzle`(P07-M3), 화면 분기는 남아 있지만 지금 어떤 미션에도 등록되지 않은 `BlotterMirror`·`ShowStripPuzzle`·`LightBoardPuzzle`(P05-M3·P07-M1·M2는 `easySteps`로 바뀜), `MorningSketchesPuzzle`(P08-M2), `TornSlipPuzzle`(P08-M3), `PaperOnDrawing`(P08-F), `GearBoardPuzzle`(P09-M2), `TowerTestPuzzle`(P09-F), `DrumTapePuzzle`(P10-M1), `CityClocksPuzzle`(P10-M2), `ShadowCheckPuzzle`(P10-M3), `HourRecordPuzzle`(P10-F), 그리고 등록만 되어 있고 `easySteps`에 가려 플레이되지 않는 `streetBooks`·`postTrails`·`lightTables`(`retiredEngines`).

### 3.6 퍼즐 외 플레이 요소 (모든 Case 공통 또는 일부)

| 요소 | 사용 | 구현 | Gen 지원 |
|---|---|---|---|
| 편지 봉투(TAP TO OPEN) | 기본 질문 미션 전부 | `EnvelopeReveal`, `LetterCard` | ✅ (`letter`) |
| 이전 증거 꺼내 보기(`Mission.recall`) | P 08-M1·F | `EvidenceRecall` | ✅ (`play.recall`) |
| 증거끼리 연결(`evidenceLinks`) | P 02~12 | 수첩 | ✅ (`evidenceLinkLine`) |
| 편지와 함께 받는 물건(`exhibits`) | P 01-M2 | `Exhibit` | ❌ |
| 퍼즐 전후 대화(`talkMissions`) | P 11·12 | `CaseTalk` | ❌ |
| 문자 잠금 상자 연출(`lockBoxes`) | P 01-F | `LockBoxStage` | ❌ (상자 없이 생성) |
| 사건 후 엔딩 대사(`endings`) | P 12-F | `CaseTalk` 엔딩 | ❌ |
| 장면 그림(`storyScenes`, `introPictures` …) | Paris 전체 | `StoryPicture` | ❌ |
| Discovery Moment 전용 문구(`discoveries`) | London 전체 | `DiscoveryMoment` | ❌ (`successMessage`로 대체 표시) |
| 난이도별 문구(`casePatches`, `variants`) | London·Paris | `DifficultyContent` | ❌ (기본 Rookie만) |

---

## 4. 새 방식의 CasePlan 스키마 (STEP 3-13)

모두 **선택 필드**라 기존 Plan은 그대로 통과한다(`schemaVersion` 1 유지). JSON Schema(`schema/mission_plan.schema.json`)와 Dart 모델(`plan_models.dart`)이 같은 규칙이며 `season_gen_schema_test`가 둘을 대조한다.

| 위치 | 필드 | 엔진 |
|---|---|---|
| `missions[].play.explore` | 현장 탐색 장면 | `puzzle.engineTable: "explores"` |
| `missions[].play.search` | 수색 장면 | `"investigations"` |
| `missions[].play.dialogue` | 증인 대화 장면 | `"dialogues"` |
| `puzzle.answerSpec.options[].picture` | 선택지 그림 파일 | `missionType: "imageChoice"` |
| `missions[].play.hideOptionNames` | 그림 이름 숨김 | `imageChoice`만 |

예시와 실제 동작은 `content_pipeline/seasons/s9_sandbox/cases/s9_ep03/case.plan.json`(Sandbox Case 03)을 본다.

### 4.1 좌표 규칙 (원본 그림 → 화면)

- Plan에는 **원본 그림의 픽셀**로 쓴다: 사각형 `[left, top, right, bottom]`, 점 `[x, y]`. 그림의 `pixels`(width, height)는 **실제 파일 크기와 같아야** 한다(`PlayCheck`가 PNG 헤더를 읽어 확인, 다르면 `asset_size_mismatch`).
- 생성기는 `Rect.fromLTRB(282 / 1536, 660 / 1024, …)` 같은 상수식으로 쓴다. 게임은 0..1 비율로 다루므로 어떤 화면 크기에서도 같은 곳이 눌린다(London이 `ScenePixels.rect`로 쓰는 방식과 같다).
- 기기별 맞춤은 엔진이 한다: 그림은 원본 비율 그대로 `BoxFit.fill`로 그 비율의 상자에 그려지고, `inside`(인쇄된 종이 테두리 안쪽)만 보이며, `opening`(처음 보이는 영역)이 화면 폭에 맞춰진다. 나머지는 드래그·핀치로 본다. 그래서 `opening`에는 모든 조사 대상이 들어가야 한다.
- 작은 대상도 손가락 폭으로 눌리도록 엔진이 영역 바깥 여유(slack)를 둔다. 그래도 대상은 원본 기준 대략 60px 이상으로 잡는다(London 기준).
- 그림 선택지는 `BoxFit.contain`으로 **잘리지 않게** 보인다(구분 단서가 가장자리에 있을 수 있음).

### 4.2 생성 차단(이미지가 없을 때)

- 장면·선택지가 가리키는 파일이 디스크에 없으면 `asset_file_missing`으로 **생성기가 아무것도 쓰지 않는다.** 임시·대체 그림으로 통과시키지 않는다.
- Planner(`plan_season check`)에서는 이것이 장소 그림과 같은 `image_pending`(INFO)로 보고되고, 생성기는 `generator_waits_for_pictures`로 "그림만 기다림" 상태가 된다.
- 이미지가 필요한 퍼즐의 Plan `status`는 `awaitingAssets`다. 생성 가능 여부는 status가 아니라 **파일이 실제로 있는지**로 판정한다(`--target season`에서는 STEP 3-5 승인도 필요).

### 4.3 Asset Manifest 연결

- 퍼즐 그림은 `assets.manifest.json`에 `use: "puzzle"`로 계획한다(장소 그림은 `seasonPlace`).
- Planner 검사: 장면·선택지의 파일이 Manifest의 `outputPath`가 아니면 ERROR `asset_scene_unplanned`; 보여 주는 그림의 asset id가 그 퍼즐의 `assetNeeds`에 없으면 WARNING `asset_need_missing`; `use: puzzle`인데 어떤 장면도 보여 주지 않으면 WARNING `asset_unused`.

### 4.4 `PlayCheck`가 장면에 대해 보는 것

| 코드 | 언제 |
|---|---|
| `play_field_missing` | engineTable의 장면이 없음, note에 line 없음, requires에 lockedLine 없음, then이 있는데 then 대사 없음, 그림 선택지에 picture·altText 없음 |
| `play_scene_mismatch` | 다른 테이블의 장면이 쓰여 있음 |
| `asset_file_missing` / `asset_size_mismatch` | 파일 없음 / 선언 크기와 실제 PNG 크기 다름 |
| `scene_area_invalid` | 사각형이 그림 밖이거나 뒤집힘, 점이 그림 밖 |
| `scene_invalid` | 탐색의 document·choice가 1개가 아님, 없는 spot을 requires, 같은 id 두 번, 증인이 모든 질문에 답하지 않음 |
| `scene_answer_mismatch` | 탐색 선택 그림 ≠ 보기, 대화 pair가 진술이 아니거나 topic이 아니거나 같은 증인이거나 다른 것을 말함 |
| `scene_ambiguous` | topic에 대해 같은 것을 말한 다른 진술 쌍이 있음(정답 쌍이 하나가 아님) |
| `scene_text_mismatch` | 수색 대상의 reportLine이 편지에 글자 그대로 없음(편지를 읽고 찾는 퍼즐) |

---

## 5. 남은 격차 (Generator 미지원)

지원하지 않는 것을 지원한다고 표시하지 않는다.

1. **기본 질문 1종:** `number_entry`(키패드). 팔레트상 textOnly라 생성기 목록에 넣기만 하면 되지만 Sandbox 플레이 검증이 없어 이번에 넣지 않았다.
2. **그림 엔진 13종(3.3):** `lens_inspect_word`, `trace_deduction`, `object_decode`, `spot_difference`, `room_find_match`, `layer_reveal`, `clue_filter_choice`, `record_mismatch`, `symbol_dial_lock`, `viewpoint_match`, `guided_steps`, `evidence_talk`, `scene_compare_report`. 엔진은 파일 기반이라 같은 방식(Plan 장면 객체 + PlayCheck + 생성기)으로 추가할 수 있다. 우선순위 제안: `trace_deduction`·`lens_inspect_word`(탐색과 구조가 거의 같음) → `evidence_talk`(인물 대화) → `guided_steps`.
3. **코드 변경 필요 5종(3.4)** 과 **Paris 전용 23종(3.5)**.
4. **동반 연출:** `exhibits`, `talkMissions`, `lockBoxes`, `endings`, `storyScenes`, `discoveries`, 난이도 변형.
5. **현장 탐색의 `note` 단서:** 화면에 메모로만 보이고 수첩 Clue로 저장되지는 않는다(London과 같음). 저장되는 단서는 미션의 `clue`다.
6. **엔진 화면 안의 진행 저장:** 게임 자체가 저장하지 않는다(재진입 시 그 미션을 처음부터). 생성 콘텐츠도 같다.
7. **시각 검증:** 위젯 테스트는 실제 그림 픽셀을 그리지 않는다. 좌표가 그림 속 물건에 정확히 맞는지는 기기 캡처나 사람의 눈으로 확인해야 한다. Sandbox Case 03은 London의 측정된 좌표를 그대로 써서 이 위험이 없다.
