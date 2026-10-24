# Season 2 · Case 10 — The Hour of Shadows
## 확정 기획 사양서 (v1.2 · 2026-10-24 · 구현 반영)

**상위 문서:** `docs/SEASON2_PARIS_STORY_BIBLE.md` v1.9 §6 Case 10 확정 명세. 이 문서는 그 화면·대사·판정 상세다. 충돌 시 Story Bible이 우선한다.
**에셋:** `docs/SEASON2_CASE10_ASSET_SPEC.md` v1.1
**상태:** 기획 확정, 에셋 6장 납품·검수 승인, **구현 완료(2026-10-24, 미커밋)**. 코드 `lib/data/mock/season2/episode10_mock.dart`, `season2_case10_scenes.dart`, `lib/data/models/star_puzzles.dart`, `lib/features/mission/widgets/star_records.dart`, 테스트 `test/paris_case10_test.dart`, 시각 QA `integration_test/case10_visual_qa_test.dart`.
**v1.2 (2026-10-24, 구현 반영):** (1) 해시계 각도 정밀 재측정값으로 테이블 확정(§6.2). (2) 스냅 규칙 변경(사용자 지시): **정답이 아닌 시각선에도 스냅**하고 판정은 스냅 뒤에 따로 한다(§6.2). (3) 명판 글자는 프로젝트에 Cinzel이 없어 디자인 시스템의 제목 폰트(IM Fell English SC)로 새긴다. (4) Case Closed 대사는 문장을 바꾸지 않고 화면 순서만 구현 구조(답 → 기록 목록 → 사건 후 장면)에 맞췄다(§8). (5) M2 질문 문구 `Is it a trial clock? Find and sort the clocks.`(§5).
**v1.1 (2026-10-24):** 에셋 검수 결과 반영. Intro 6줄 `A brass plate on the wall:`(명판 위 Flutter 텍스트 오버레이), 문에 붙은 별은 그림 그대로, 성당 시계 터치·확대 검수 기준(§5.2.1), 사진 테두리 이중 적용 금지, M3 해시계 범위 **1:00–4:00 · 30분 · 시각선 7개**와 실측 각도 데이터 테이블(§6.2). 퍼즐 정답·증거·다른 대사는 변경 없음.
**ID:** case `s2_ep10` · missions `s2_ep10_m1`–`m3`, `s2_ep10_final` · evidence `s2_ep10_e1`–`e4` · clues `s2_ep10_c1`–`c3`
**방향:** Case 09와 같은 가벼운 사건. 8–12세가 **5–7분**에 끝낸다. 각 퍼즐은 5초 안에 조작법을 알 수 있고, 한 화면에 단서와 조작 영역이 함께 있다. 오답은 진행을 초기화하지 않는다. 기존 위젯을 최대한 재사용한다.

### 표기
- **[BIBLE]** Story Bible v1.8 이전 또는 구현된 Case 01–09에서 확정된 사실
- **[NEW]** Case 10에서 새로 정한 설정 (2026-10-24 사용자 승인, Bible v1.9 반영)

---

## 0. 한 줄 요약

별의 방(Star Room)에서 T1이 직접 찍은 **드럼 테이프**를 읽으면 3시가 통째로 없다(M1). 같은 순간을 찍은 지붕 사진 속 **시험 시계가 아닌 시계 세 개**는 서로 같은 시각을 가리키고, T1은 그보다 한 시간 늦다(M2). 지붕 해시계의 그림자를 사진처럼 맞추면 **해도** 같은 시각을 가리킨다(M3). 테이프 아래에 해의 시각을 깔면 **3시부터 4시까지의 한 시간이 테이프 안에 그대로 있다**. 다만 그 시간 동안 T1은 한 시간 늦었고, 그 시간을 적은 **기록부 3쪽은 책에 없다**(Final). 기록 목록은 3쪽의 목적지를 **Saint-Sulpice · Archive Annex**로 적고 있다(Case Closed).

**결론 문장:** `The hour was there. T1 was one hour behind, and the page about it is missing.`

**공개하지 않는 것 [BIBLE + NEW]:** 3쪽의 내용, 3쪽을 보낸 사람과 이유, 기록이 사라진 정확한 경위, 3쪽이 실제로 목적지에 도착했는지, 제본 흔적, T1이 틀린 원인과 책임자, 4시에 고친 사람, T2·T3의 실제 시험 결과, Émile·Victor·Clockmaker의 정체와 관련성, 과거 시험 사고 날짜, 가방·방패 배지·보라색 도장.

---

## 1. 지키는 것과 새로 정하는 것

### 1.1 [BIBLE] 유지
| 항목 | 내용 |
|---|---|
| 장소·핀 | Arc de Triomphe, `ParisLandmark.arcDeTriomphe` (`map_world.dart`의 `s2_ep10`) |
| 제목·질문 | `The Hour of Shadows` / `Was the hour lost — or was the clock wrong?` (Case 09 hook으로 구현됨) |
| Case 09 → 10 물증 | M1 T1 받침의 **별**(끝 12개 + 가운데 원), M2 기록 드럼 꼬리표 `TRIAL RECORDS · KEPT AT THE STAR`, Case Closed `The real records may be kept there. We must read them.` |
| 시험 시계 | T1 Arc de Triomphe · T2 Seine Quays · T3 Arts et Métiers. 세 곳뿐 (Trial Map) |
| 모형과 실제 구분 | Case 09 `The model shows what could happen. But what really happened?` Case 09 모형에서 T1–T3이 함께 움직인 것을 **과거 사건의 증거로 쓰지 않는다** |
| §8 공개 범위 | Case 10에서 결론 낼 수 있는 것: 시간이 실제로 사라진 것은 아님. 숨길 것: 삭제 승인자 |
| End hook | 누락 페이지의 보존 목록 → `SAINT-SULPICE · ARCHIVE ANNEX` (map anchor: Luxembourg Gardens 북쪽 끝) |
| 날짜 | 과거 시험 사고 날짜 미지정. 기록에는 `TRIAL DAY`만 |

### 1.2 [NEW] 확정 설정
1. **Star Room:** 개선문 지붕 아래의 작은 석조 방(가상). 문짝에 T1 받침과 같은 별(`star_room.png` 그대로). 안에 기록 드럼, 사진 상자, Trial Log, 벽의 황동 명판 `TRIAL RECORDS · KEPT AT THE STAR`(명판 그림 위에 Flutter 텍스트 오버레이). 실제 개선문에 그런 방이 있다고 단정하지 않는다.
2. **T1의 실제 위치:** 개선문 지붕 위 짧은 철 기둥(가상). Case 09 T1 모형(아치 위 시계)과 맞는다. 현재 T1이 남아 있는지는 말하지 않는다.
3. **지붕 해시계:** 지붕에 있는 오래된 해시계(가상). 지붕 사진에도 T1 옆에 찍혀 있다.
4. **기록 4종:** T1 드럼 테이프, 지붕 사진 2장(Photo 1·2, 같은 자리에서 찍음), Trial Log(p.1·p.2·p.4만 있음, 목차에는 p.1–4), RECORD LIST(Trial Log 뒤표지 안쪽).
5. **과거 시험 중 T1의 표시:** §2 타임라인. 실제 3:00–4:00 동안 T1은 한 시간 늦게 표시했고, 4:00에 정상으로 돌아왔다. 원인과 책임자는 공개하지 않는다.
6. **RECORD LIST의 p.3 줄:** `p.3 · SENT TO: SAINT-SULPICE · ARCHIVE ANNEX`. 목록에 적힌 **목적지일 뿐**이며, 실제 도착 여부는 확정하지 않는다. `removed`라는 단어는 쓰지 않는다.
7. **기록 드럼은 Case 03의 시간 기록 장치와 다른 모양**이다(연결을 암시하지 않음). Case 03은 Case Closed의 회상 한 줄로만 연결한다(§8).

---

## 2. 실제 시간 / T1 표시 타임라인 [NEW]

### 2.1 기록 구조 (작가 기준)
- **드럼의 인쇄 규칙:** 드럼은 T1에 붙어 있고, **T1의 분침이 :00·:15·:30·:45에 닿을 때마다** T1 시계판의 시각을 테이프에 찍는다. 즉 테이프는 "그 순간 T1이 보여 준 시각"이다.
- **테이프 이동:** 드럼은 일정한 속도로 돈다. 그래서 테이프의 눈금 간격은 실제 시간 15분마다 **같은 간격**이다(그림으로만 보여 주고 대사로 설명하지 않는다).
- **두 번의 변화는 모두 정각에 시침만 한 시간 움직였다.** 분침은 그대로라서 인쇄는 계속 실제 15분 간격으로 이어진다.

### 2.2 타임라인

| 테이프 눈금 | 실제 시각 (해·독립 시계) | T1 표시 = 테이프 인쇄 | 사건 | 남은 기록 |
|---|---|---|---|---|
| t1 | 2:00 | 2:00 | 정상 | **Photo 1**: T1 2:00 · 해 2:00 |
| t2 | 2:15 | 2:15 | 정상 | |
| t3 | 2:30 | 2:30 | 정상 | |
| t4 | 2:45 | 2:45 | 정상 | |
| — | **3:00 직전** | 3:00이 되려는 순간 | **변화 ①: T1의 시침이 한 시간 뒤로 움직임 (3 → 2)** | 테이프의 첫 점프 `2:45 → 2:00` |
| t5 | 3:00 | **2:00** | 한 시간 늦음 | |
| t6 | 3:15 | 2:15 | 한 시간 늦음 | |
| t7 | 3:30 | **2:30** | 한 시간 늦음 | **Photo 2**: T1 2:30 · 해 3:30 · 카페·성당·우체국 시계 3:30 |
| t8 | 3:45 | 2:45 | 한 시간 늦음 | |
| — | **4:00 직전** | 3:00이 되려는 순간 | **변화 ②: T1의 시침이 한 시간 앞으로 움직여 정상 복귀 (3 → 4)** | 테이프의 두 번째 점프 `2:45 → 4:00` |
| t9 | 4:00 | **4:00** | 정상 | |
| t10 | 4:15 | 4:15 | 정상 | |

- **결과:** 테이프에는 `3:00`–`3:45`가 한 번도 찍히지 않았다. 대신 `2:00`–`2:45`가 두 번 찍혔다. 실제 3:00–4:00은 정상적으로 흘렀고, 그 한 시간은 테이프의 t5–t8로 남아 있다.
- **대사로 쓰지 않는 것:** 변화 ①·②를 누가 일으켰는지, 왜 정각이었는지, 다른 시험 시계도 움직였는지는 Case 10에서 말하지 않는다.

### 2.3 플레이어가 각 사실을 아는 방법

| 사실 | 증거 | 단계 |
|---|---|---|
| 테이프에 3시가 없고, 2시대가 두 번 나온다 | 테이프 눈금을 직접 읽음 | M1 |
| 같은 순간, T1은 시험 시계가 아닌 시계 세 개보다 한 시간 늦었다 | Photo 2 | M2 |
| 같은 순간, 해도 3:30이었다. Photo 1에서는 T1과 해가 일치했다 | 해시계 그림자 재현 | M3 |
| 첫 번째 2시대(t1–t4)는 실제 2시대, 두 번째(t5–t8)는 실제 3시대 | Photo 1 핀(t1 = 해 2:00) + Photo 2(해 3:30) → t7. 두 핀 사이 6눈금 = 1시간 30분 → 눈금 1칸 = 15분 | Final 1단계 |
| 변화 ①은 실제 3:00, 변화 ②는 실제 4:00 | 해 시각 줄을 테이프 아래에 깔면 t5 = 3:00, t9 = 4:00 | Final 1단계 연출 |
| 4:00에 T1은 다시 맞았다 | t9 인쇄 `4:00` = 해 시각 줄 4:00 | Final 1단계 연출 |
| 3:00–4:00의 기록부 쪽이 없다 | 목차 p.3 ↔ 실제 쪽 p.1·p.2·p.4 | Final 2단계 |

---

## 3. Intro (약 30초)

**장면:** `arc_star_view.png` → 2–4줄에 Case 09 `clock_model_t1.png`의 받침 별을 작게 겹쳐 보임 → 4줄에서 그 별이 `star_room.png` 문짝의 별 위치로 크로스페이드 → 5줄부터 `star_room.png`
- 6줄: `star_room.png`의 빈 황동 명판(실측: 안쪽 판 중심 (760, 268), 196×74, −4° 기울기) 위에 `TRIAL RECORDS` / `KEPT AT THE STAR` 두 줄을 Flutter 텍스트로 겹친다. 글꼴은 디자인 시스템의 제목 폰트(IM Fell English SC, 프로젝트에 Cinzel 없음)이고, 새긴 느낌의 짙은 잉크색이며, 명판 폭의 80% 안에서 자동 축소되고 잘리지 않는다. 360폭에서는 명판 글자가 작으므로 이 줄을 말하는 동안 명판을 확대한 원형 렌즈(`PlateCloser`)를 그림 오른쪽 아래에 띄운다. 이미지 파일은 수정하지 않는다.

**synopsis**
- `A star under T1 pointed to the Arc de Triomphe.`
- `The trial records may be kept there.`
- `Was the hour lost — or was the clock wrong?`

**objectives** (결론을 미리 말하지 않음)
- `Read what T1 wrote.`
- `Check the other clocks.`
- `Ask the sun.`

**intro**
1. `The Arc de Triomphe. Twelve roads meet around it, like a star.`
2. `T1's little clock stood on top of an arch, with a star under it.`
3. `You climb the stairs, up and up, to the top.`
4. `Under the roof, a small door has a star on it.`
5. `Inside: a brass drum, a box of photos, and a thick book.`
6. `A brass plate on the wall: TRIAL RECORDS · KEPT AT THE STAR.`
7. `In the garden, we tested a model. These records are from the real trial.`
8. `Let's read what T1 wrote.`

| 기억할 것 | 줄 | 화면 |
|---|---|---|
| Case 09의 별이 여기를 가리켰다 | 1, 2, 4, 6 | T1 받침 별 → 문짝의 별 크로스페이드, 명판 문구 |
| 모형이 아니라 실제 기록이다 | 7 | 별의 방 전체 |
| 조사할 물건 세 가지 | 5 | 드럼·사진 상자·책에 차례로 빛 강조(기존 강조 효과) |

---

## 4. M1 — The Drum Tape (약 1분)

| 항목 | 내용 |
|---|---|
| location | `THE STAR ROOM · ARC DE TRIOMPHE` |
| 화면 | 위 55%: 왼쪽에 드럼(`record_drum.png`), 오른쪽으로 나오는 테이프(코드 Paper 띠 + 잉크 눈금). 아래: letter 카드와 찾은 개수 `● ○` |
| 조작 | ① 테이프 끝을 오른쪽으로 끌어 펼침(놓으면 멈춤, 끝까지 펼치면 고정). 펼치는 동작이 곧 가로 스크롤 ② 눈금을 탭 |
| 재사용 | 기존 손가락 안내 애니메이션(테이프 끌기 1회), `Paper`, 답 판정 형식 |
| 신규 위젯 | `DrumTape` (Final에서도 사용) |

### 4.1 스토리
- `The drum holds a long paper tape.`
- `T1 printed its time on it, every fifteen minutes.`
- `Pull the tape and read it.`

**letterIntro:** `On the tape:` / **letter:** `T1 · DRUM TAPE · TRIAL DAY`
- 머리글 옆에 톱니 8개 EMBLEM(`InkGlyph.gear`). Case 09 Marks Key와 같은 시험 문양이다. 대사로 해석하지 않는다.

### 4.2 테이프와 판정
- 눈금(t1–t10): `2:00 · 2:15 · 2:30 · 2:45 · 2:00 · 2:15 · 2:30 · 2:45 · 4:00 · 4:15`
- question: `Where does the time jump? Tap the two places.`
- **정답:** t5(두 번째 `2:00`), t9(`4:00`). 각 눈금은 "바로 앞 눈금에서 15분 뒤가 아닌 곳"이다.
- **answer:** `jump:t5,jump:t9`
- 피드백 (오답은 세지 않고 진행을 초기화하지 않음)
  - 정상 눈금(t2–t4, t6–t8, t10): `{time} comes fifteen minutes after {previous}. That's fine.` (예: `2:15 comes fifteen minutes after 2:00. That's fine.`)
  - t1: `That's where the tape starts.`
  - 하나만 찾음: `One jump! Find one more.`
- 정답 표시: 두 점프 자리에 골드 원 + 작은 표시 `2:45 → 2:00`, `2:45 → 4:00`

### 4.3 힌트
1. (무료) `Read the times one by one. Each one should be fifteen minutes after the last.`
2. `Look at what comes after each 2:45.`

### 4.4 transition
1. `After 2:45, the tape goes back to 2:00. T1 went one hour back!`
2. `After the next 2:45, it jumps to 4:00. T1 went one hour forward.`
3. `There is no three o'clock on the tape at all.`
4. `At Gare du Nord, we read: The Clockmaker steals an hour.`
5. `So was an hour stolen? Or did T1 show the wrong time?`
6. **(→ M2)** `The box of photos! Let's see what other clocks said.`

- 1–2줄은 테이프에서 바로 읽히는 사실(T1의 표시가 움직였다)만 말한다. 어느 쪽 2시대가 틀렸는지는 Final까지 열어 둔다.
- 4–5줄: Case 01의 초기 해석(`The Clockmaker steals an hour.`, Case 01 Final 문구)을 **질문으로만** 꺼낸다. Clockmaker의 관련성은 말하지 않는다.

### 4.5 Notebook
- **clue `s2_ep10_c1`** — `No Three O'Clock` · value `2:45 → 2:00 · 2:45 → 4:00` · symbol `clock` · note `T1's tape never shows three o'clock.`
- **evidence `s2_ep10_e1` T1 Drum Tape** — icon `clock` · description `The paper tape from the drum under T1.` · inscription `T1 printed its time every fifteen minutes: 2:00 to 2:45, then 2:00 to 2:45 again, then 4:00. There is no three o'clock on the tape.`
- EvidenceLink → `s2_ep09_e2` Synchronisation Diagram: `The drum under T1, from the tag in the garden.`

---

## 5. M2 — A City of Clocks (약 1–1.5분)

| 항목 | 내용 |
|---|---|
| location | `THE STAR ROOM · ROOF PHOTOS` |
| 화면 | 위 65%: Roof Photo 2(`roof_photo.png` + 코드 바늘, `SearchStage`/`ZoomPicture`, 핀치 확대 가능) + 돋보기. 오른쪽 위: `Trial Map` 칩. 아래 35%: 두 칸 `TRIAL CLOCK` / `NOT A TRIAL CLOCK` + 찾은 카드 트레이 `n / 4` |
| 조작 | ① 돋보기를 끌어 시계 4개 찾기(찾으면 카드가 트레이에 생김) ② 카드를 두 칸에 끌어 놓기(탭 → 탭도 가능) |
| 재사용 | `LensInspect`(돋보기), `SearchStage`/`ZoomPicture`, `StudioMatch`의 끌어 놓기·탭-탭, `matchPairs` 판정, `ClockQuestion` 바늘 그리기(사진 위 바늘) |
| Notebook | 변경 없음. `Trial Map`(`s2_ep09_e1`)을 칩으로 직접 보여 준다(Case 09 M3와 같은 방식) |

### 5.1 스토리
- `ROOF PHOTOS · TRIAL DAY. Two old photos.`
- `Photo 2 shows T1 on the roof, and the city behind it.`
- `Find every clock in the photo.`

**letterIntro:** `On the back of Photo 2:` / **letter:** `T1 · ROOF · PHOTO 2`
- 사진에는 시각을 적지 않는다. 시각은 사진 속 바늘로만 읽는다.

### 5.2 사진 속 시계 4개
| 카드 | 사진 속 위치 | 표식 | 시각 (분류 후 카드에 공개) |
|---|---|---|---|
| `T1` | 앞 왼쪽, 지붕 위 철 기둥. 기둥 판에 **별** | 별 | **2:30** |
| `Café` | 길모퉁이 카페 벽의 브래킷 시계 | 없음 | 3:30 |
| `Church` | 멀리 성당 탑 | 없음 | 3:30 |
| `Post office` | 큰 문 위의 둥근 시계 | 없음 | 3:30 |

- 사진 속 바늘은 처음부터 그려져 있다(사진이니까). 카드는 분류가 끝난 뒤에 시각을 글자로 확정해 보여 준다. 분류 근거는 시각이 아니라 **표식(출처)**이다.
- `roof_photo.png`에는 낡은 사진 테두리가 이미 그려져 있다. `case_07/photo_frame.png`나 코드 테두리를 덧씌우지 않는다(M3 크롭 카드, Final 핀 썸네일도 같음. 카드는 그림자만).

#### 5.2.1 시계 위치와 성당 시계 검수 기준 (필수)
- 네 시계의 시계판 중심·반지름은 `roof_photo.png`(1536×1024) **실측 좌표**로 scene 데이터에 기록한다. 바늘(`ClockQuestion` 방식)도 그 좌표에 그린다.
- 성당 시계는 그림에서 화면 폭의 약 2%로 작다. 이미지는 그대로 쓰고 다음을 지킨다.
  1. 터치·돋보기 판정 영역은 표시 크기와 상관없이 **최소 48×48 logical pixels**.
  2. 판정 영역은 다른 세 시계의 영역과 **겹치지 않는다**. 가까우면 각 영역을 시계 중심 쪽으로 줄이되 48×48 아래로 내려가지 않는다(현재 그림에서는 성당 탑과 다른 시계가 충분히 떨어져 있음, 실측 후 확인).
  3. 돋보기 배율은 성당 시계판이 렌즈 안에서 **지름 40 logical pixels 이상**이 되도록 정하고, 그 크기에서 시침과 분침이 구별되게 바늘 두께·길이 비율을 정한다(시침 굵고 짧게, 분침 가늘고 길게).
  4. 시계를 찾으면 카드에 시계판을 크게 다시 그린다(`clock_dial.png` + 코드 바늘). 아이는 시각을 카드에서 확실히 읽는다.
  5. **360×640 실제 캡처 검수:** 돋보기 위치 4곳(시계마다)과 분류 완료 화면을 캡처해 성당 시계의 판·바늘 구별, 판정 영역 충돌 여부를 확인한다. 태블릿 1종도 같은 방식으로 확인한다.

### 5.3 판정·피드백
- **answer:** `t1:trial,cafe:not,church:not,post:not`
- Café/Church/Post office → `TRIAL CLOCK`: `Is there a star, three arches or a bell on it? Check your Trial Map.`
- T1 → `NOT A TRIAL CLOCK`: `Look at the post under T1. What sign is there?`
- 시계를 다 찾기 전: 분류 칸은 비활성 + `There are more clocks in the photo.`

### 5.4 힌트
1. (무료) `Move the glass over the photo. There are four clocks.`
2. `Only T1 has the trial star. The other clocks are not trial clocks.`

**successMessage:** `They don't agree!`

### 5.5 transition — 결론 범위 제한
1. `T1 says 2:30. The café, the church and the post office clocks all say 3:30.`
2. `Those three are not trial clocks, and they all agree.`
3. `T1 is one hour behind them.`
4. `But what if all three were wrong? Is there a time no one can set?`
5. **(→ M3)** `Look, in the photo! A sundial stands next to T1.`

- M2에서 확정하는 것은 두 가지뿐이다: **T1은 독립 시계보다 한 시간 늦었다**, **독립 시계들은 서로 같은 시각이다**.
- T2·T3의 상태, Case 09 모형의 연동 동작, 틀린 원인은 말하지 않는다. `Trial Map`은 "어느 시계가 시험 시계인가"(장소와 표식)를 가리는 데만 쓴다.

### 5.6 Notebook
- **clue `s2_ep10_c2`** — `One Hour Apart` · value `T1 2:30 · others 3:30` · symbol `clock` · note `Three clocks that are not trial clocks agree with each other.`
- **evidence `s2_ep10_e2` Independent Time Log** — icon `clock` · description `The clocks in Roof Photo 2, at one moment on the trial day.` · inscription `The trial clock T1 said 2:30. Three clocks that are not trial clocks (the café, the church and the post office) all said 3:30. T1 was one hour behind them.`
- EvidenceLink → `s2_ep09_e1` Trial Map: `T1 is the trial clock with the star.`

---

## 6. M3 — The Hour of Shadows (약 1–1.5분)

| 항목 | 내용 |
|---|---|
| location | `THE ROOF · ARC DE TRIOMPHE` |
| 화면 | 위 30%: 사진 카드(Photo 1 → Photo 2, 해시계 부분을 확대한 크롭 + T1 시계판). 가운데 55%: 위에서 본 오늘의 해시계(`sundial_top.png`, 1254×1254)와 그 바깥의 해 궤도(점선 호), 궤도 위의 **해 토큰**. 아래: 읽은 시각 `SUN: --:--`과 비교 줄 |
| 조작 | 해 토큰을 궤도를 따라 끈다 → 그림자가 실시간으로 **방향과 길이**를 바꾼다 → 사진 속 그림자와 같아지면 딸깍 고정(판정은 §6.2의 시각 데이터 기준) |
| 해 토큰 | **이미지 없음.** 신규 `InkGlyph.sun`(기존 InkIcon 체계, 잉크 선: 원 + 짧고 둥근 빛살 12개, 얼굴 없음, Antique Gold). 지름 56pt. 별(끝이 뾰족한 12개)과 구별되도록 빛살 끝은 둥글게 |
| 신규 위젯 | `SunDial` |

### 6.1 스토리
- `Out on the roof, the old sundial is still here.`
- `A sundial tells the time with the sun's shadow.`
- `Make the same shadow as in the photos.`

**letterIntro:** `Around the sundial:` / **letter:** `I COUNT ONLY THE SUNNY HOURS.` (테 띠에 새긴 글. 분위기용이며 풀이에는 쓰지 않는다)

### 6.2 해시계 시각 데이터와 그림자 규칙

**범위 (확정):** 시작 1:00 · 종료 4:00 · 간격 30분 · 시각선 7개 → `1:00 / 1:30 / 2:00 / 2:30 / 3:00 / 3:30 / 4:00`. Photo 1 정답 **2:00**, Photo 2 정답 **3:30**.

**시각선 각도 테이블 (단일 데이터 원천):** `sundial_top.png`의 새겨진 선을 실측한 각도. 기준은 그노몬 밑점(이미지 중심 근처), 각도는 **12시 방향(그노몬 방향) 0°에서 시계 방향**. 시각선 간격이 고르지 않으므로 **등각도 계산을 쓰지 않는다.**

| 시각 | 각도 (확정, 정밀 실측) | (참고: 1차 실측) |
|---|---|---|
| 1:00 | **23.4°** | 23.5° |
| 1:30 | **45.9°** | 46.0° |
| 2:00 | **65.1°** | 65.5° |
| 2:30 | **82.9°** | 82.5° |
| 3:00 | **102.5°** | 102.3° |
| 3:30 | **121.9°** | 121.6° |
| 4:00 | **143.3°** | 143.2° |

- 정밀 실측(구현 시작 시): 맨 아래 세로선이 x = 627에 있어 허브 x = 627을 확인했다. 0.1° 간격으로 반지름 200–450px 구간의 평균 밝기를 재서 가장 어두운 방향을 찾았고, 허브 y는 620과 627을 비교해 새김선이 더 뚜렷한 627로 정했다. 시각선 끝은 허브에서 470px, 판 가장자리는 578px이다. 테스트(`paris_case10_test.dart`)가 7개 각도마다 "선이 양옆(±4°)의 판보다 어둡다"를 이미지 픽셀로 검사한다.
- **맨 아래 세로선(약 180°)은 시각선이 아니다.** 그노몬 축의 연장선(판의 남북 기준선)이므로 시각 데이터에 넣지 않고, 숫자를 붙이지 않으며, 판정·스냅·reduce motion 탭 지점으로도 쓰지 않는다. 그림자는 4:00(143.2°)을 넘어가지 않으므로 이 선에 닿지 않는다.

**하나의 데이터에서 모두 계산한다**
- `SundialHourLine { time, angleDeg }` 7개 목록 하나만 둔다. 해 토큰 위치, 그림자 방향, 그림자 길이, 숫자 위치, 사진 속 그림자, 정답 판정, reduce motion 탭 지점이 모두 이 목록에서 나온다.
- 드래그 중의 연속 값은 **인접한 두 시각선 사이를 선형 보간**한다(시각 ↔ 각도). 1:00 이전이나 4:00 이후로는 움직이지 않는다.
- **그림자 방향** = 해당 시각의 `angleDeg`(그노몬 밑점에서 바깥쪽).
- **해 토큰 위치** = `angleDeg + 180°` 방향, 해시계 판 바깥의 궤도 원 위. 그래서 해는 그림자의 정반대 쪽에 있고, 그림자와 같은 방향(시계 방향)으로 돈다. 궤도는 7개 시각선에 대응하는 호만 점선으로 그리고, 30분마다 작은 점을 찍는다(숫자 없음).
- **그림자 길이** = 해시계 판 반지름의 0.45배(1:00) → 0.90배(4:00), **시각에 비례**(각도가 아님). 오후가 깊을수록 그림자가 길어지는 것이 한눈에 보인다. 그림자 진하기도 같은 비율로 조금 짙어진다.
- **숫자:** 정시 선(1:00, 2:00, 3:00, 4:00) 바깥 끝에 `1`·`2`·`3`·`4`를 코드로 새긴다(Libre Baskerville, 잉크색). 반시간 선에는 숫자 없이 작은 점만. 그림자가 닿은 선의 숫자(반시간이면 점)가 빛난다.
- **사진 속 그림자:** 같은 시각의 `angleDeg`와 길이를 `roof_photo.png` 해시계의 실측 타원(중심, 장축·단축, 기울기)과 사진 속 그노몬 방향(0° 기준)으로 변환해 코드로 그린다. 사진 속 해시계에 새겨진 선(한 바퀴 전체)은 장식이므로 판정에 쓰지 않는다. 아이가 비교하는 것은 **코드로 그린 그림자의 방향과 길이**다.
- **스냅 (v1.2 변경):** 끄는 동안 그림자가 어느 시각선이든 그 선과 이웃 선 사이 간격의 **40% 이내**로 다가오면 그 선에 붙어 보인다. 손을 떼면 **가장 가까운 시각선으로 항상 스냅**한다. 정답이 아닌 선에도 똑같이 스냅한다.
- **판정 (스냅과 분리):** 스냅된 시각이 사진의 시각이면 일치(`The same shadow!`)로 처리하고, 아니면 사진 그림자가 더 긴지 짧은지 알려 준다(`Not yet. The shadow in the photo is longer.` / `…shorter.`, 경로를 따라 방향 빛 표시). 오답으로 세지 않는다.
- **제스처:** 손가락은 해시계 어디에 두어도 되고, 해는 손가락 방향의 궤도 위로 따라간다(해 토큰이 손가락에 가려지지 않음). 위아래로 끌어도 페이지가 스크롤되지 않도록 해시계가 세로·가로 드래그를 먼저 받는다.
- 해를 끄는 동안 하늘 배경이 아주 약하게 따뜻해진다(1:00 밝은 크림 → 4:00 옅은 금빛, 시각에 비례). 장식 효과는 그 이상 넣지 않는다.

### 6.3 단계와 판정
1. Photo 1 카드(T1 2:00 보임). 그림자가 맞으면 → `SUN: 2:00` 도장, 비교 줄 `T1 2:00 · SUN 2:00 · same`(Muted Green)
2. Photo 2 카드(T1 2:30 보임). 맞으면 → `SUN: 3:30`, 비교 줄 `T1 2:30 · SUN 3:30 · one hour apart`(Burgundy 밑줄)
- **answer:** `photo1:2:00,photo2:3:30` (그림자 일치로 판정. 따로 확인 버튼 없음)
- 6초 넘게 맞추지 못하면 안내 한 줄: `Watch the shadow in the photo. Is yours longer or shorter?` + 궤도에 방향 화살표(`◀`/`▶`) 깜빡임 1회
- 궤도 위 점 7개(§6.2 시각 데이터, 1:00–4:00, 30분 간격)는 **항상** 탭할 수 있고, 탭하면 해가 그 자리로 즉시 이동한다(reduce motion에서도 같은 방식으로 풀 수 있음). 탭 영역은 점마다 48×48 logical pixels이다

### 6.4 힌트
1. (무료) `Move the sun slowly. Watch the shadow turn and grow.`
2. `In Photo 2, the shadow points between 3 and 4.` (사진 속 그림자 선을 진하게 덧그림)

**successMessage:** `The sun knows!`

### 6.5 transition
1. `Photo 1: T1 said 2:00. The sun said 2:00. They agree.`
2. `Photo 2: T1 said 2:30. But the sun said 3:30!`
3. `No one can set the sun.`
4. `The letter at the Louvre said: The clocks may lie.`
5. **(→ Final)** `So where did the hour from three to four go? Let's lay it all out.`

- 4줄: Case 06 편지 `The clocks may lie. But the show remembers.`를 인용만 한다. 작성자는 말하지 않는다.

### 6.6 Notebook
- **clue `s2_ep10_c3`** — `The Sun's Time` · value `Photo 2 · SUN 3:30` · symbol `clock` · note `No one can set the sun.`
- **evidence `s2_ep10_e3` The Shadow Check** — icon `clock` · description `The roof sundial in two old photos.` · inscription `Photo 1: T1 2:00, the sun 2:00. Photo 2: T1 2:30, the sun 3:30. No one can set the sun.`
- EvidenceLink → `s2_ep10_e2`: `The same photo, the same moment.`

**공정성:** Photo 1에서 해와 T1이 일치하므로 "이 해시계는 믿을 만하다"는 기준이 화면 안에서 먼저 선다. 계절·경도 보정 같은 지식은 필요 없다.

---

## 7. Final — The Hour Was Recorded (약 1.5–2분)

| 항목 | 내용 |
|---|---|
| location | `THE STAR ROOM · THE TABLE` |
| 화면 | 세로 3단: 위 테이프(`DrumTape`, t1–t10) / 가운데 빈 줄 `THE SUN'S TIME` / 아래 Trial Log(`trial_log_open.png` + 코드 쪽). 진행 중인 단만 밝고 나머지는 60% 불투명. 맨 아래 결론 카드 |
| 필요한 증거 | e1 T1 Drum Tape, e3 The Shadow Check(두 사진의 해 시각), e2 Independent Time Log(결론 오답 반박) |
| 재사용 | `DrumTape`, 기존 쪽 넘기기(◀▶ + 스와이프), `multipleChoice`, `GameButton` |
| 신규 위젯 | `TapeTimeline`(DrumTape + 해 시각 줄 + Trial Log 묶음) |

### 7.1 스토리
- `You lay the tape on the table.`
- `Photo 1 was taken at the first 2:00. T1 and the sun both said 2:00.`
- `Now find Photo 2 on the tape.`

**letterIntro:** `Your photos:` / **letter:**
```
PHOTO 1 · T1 2:00 · SUN 2:00
PHOTO 2 · T1 2:30 · SUN 3:30
```

### 7.2 1단계 — Photo 2를 테이프에 놓기
- Photo 1 핀은 이미 t1에 꽂혀 있다: `PHOTO 1 · SUN 2:00`
- 지시: `When was Photo 2 taken? Tap that 2:30 on the tape.`
- **정답 t7**(두 번째 `2:30`)
- 오답
  - t3(첫 `2:30`): `This 2:30 is only half an hour after Photo 1. Photo 2's sun said 3:30, much later.`
  - `2:30`이 아닌 눈금: `T1 said 2:30 in Photo 2. Find a 2:30.`
- 정답 연출(약 3초, 건너뛰기 가능, reduce motion: 한 번에 표시)
  1. t7에 `PHOTO 2 · SUN 3:30` 핀
  2. 두 핀 사이가 6칸으로 표시된다
  3. 해 시각 줄에 `2:00 2:15 2:30 2:45 3:00 3:15 3:30 3:45 4:00 4:15`가 왼쪽부터 차례로 찍힌다
  4. t5–t8 아래 `3:00–3:45` 구간이 Antique Gold로 남는다
  5. t5 위에 `↶ one hour back`, t9 위에 `↷ right again` 작은 표시
- 연출 대사
  1. `Six marks from Photo 1 to Photo 2: one and a half hours. Fifteen minutes for each mark.`
  2. `There it is: the hour from three to four! It was on the tape all along.`
  3. `At three, T1 went one hour back. At four, it was right again.`

### 7.3 2단계 — 빠진 쪽 찾기
- Trial Log 목차(코드 Paper, 왼쪽 쪽):
  ```
  TRIAL LOG · TRIAL DAY
  p.1 · 1:00 – 2:00
  p.2 · 2:00 – 3:00
  p.3 · 3:00 – 4:00
  p.4 · 4:00 – 5:00
  ```
- 오른쪽 쪽에서 넘겨 볼 수 있는 쪽: **p.1, p.2, p.4**(머리글에 쪽 번호와 시간대만 있고, 본문은 흐린 잉크 줄로 읽히지 않음 = 내용 비공개)
- 지시: `Which page tells about three to four? Is it in the book?` → 목차의 줄을 탭
- **정답 p.3**
- 오답 p.1·p.2·p.4: `That page is in the book. Turn the pages again.`
- 정답 후 목차 p.3 줄 옆이 비어 있다는 표시만 한다(**찢긴 자국·제본 흔적 없음**)
  - `Page 3 should tell about three to four. It is not in the book.`

### 7.4 3단계 — 결론 (3지선다 하나)
question `Was the hour lost — or was the clock wrong?`
- ✅ `wrong` · `The hour was there. T1 was one hour behind, and the page about it is missing.`
- `lost` · `The hour was lost. Time jumped from 2:45 to 4:00.` → `Look at the sun's line. Did the sun jump?`
- `all` · `Every clock in Paris was one hour behind.` → `What did the café and church clocks say?`

**answer:** `photo2:t7,page:p3,why:wrong` (1·2단계는 각 단계 안에서 판정. Case 08 Final의 단계식 판정과 같음)

### 7.5 힌트
1. (무료) `Photo 1 is at the first 2:00. Photo 2 was taken later. How much later?`
2. `Find the line for three to four in the list. Then look for that page in the book.`

### 7.6 Notebook
- **evidence `s2_ep10_e4` The Hour Was Recorded** — icon `letter` · description `T1's tape, laid beside the sun's time.` · inscription `The hour from 3:00 to 4:00 really passed: the sun and three clocks that are not trial clocks show it. In that hour, T1 was one hour behind and printed 2:00 to 2:45. At 4:00 it was right again. Page 3 of the Trial Log, about that hour, is not in the book. The records do not say why T1 was wrong, or where page 3 went.`
- EvidenceLink → `s2_ep09_e4` The Wrong Hour Test: `The garden test was a model. This tape is a real record.`

**successMessage:** `The hour was never lost!`

**Final 직후 (→ Case Closed)**
1. `In the garden, a model showed what could happen. This tape shows what happened to T1.`
2. `Time did not stop. T1 showed the wrong time, and a page went missing.`

**성공 연출:** 테이프의 3:00–3:45 구간이 골드로 남은 채 화면이 살짝 어두워지고, 해 시각 줄의 `3:00`이 한 번 빛난다. 반짝이나 튀는 애니메이션은 쓰지 않는다.

---

## 8. Case Closed — Next Lead (약 30초, 점수 없음)

**구현 순서 (v1.2):** 문장은 아래 그대로 쓰고, 화면 순서만 Case 09와 같은 구조로 맞췄다.
1. 결론 정답 직후, 기록 목록 버튼 위: Final 직후 2줄 + §8.1의 4줄(`And page 3 is not in the book.`) → 버튼 `READ THE RECORD LIST`
2. 기록 목록 화면: RECORD LIST → `Where was page 3 sent?` → p.3 탭 → 지도 + §8.2 완료 문구 1–3줄 → `CONTINUE`(여기서 사건이 닫힘)
3. 사건 후 장면(`transition`): §8.1의 1–3줄 + §8.2 완료 문구 4줄(`The mystery continues at Saint-Sulpice!`)

### 8.1 transition
1. `Paris did not lose an hour. For one hour, T1 showed the wrong time.`
2. `Were T2 and T3 wrong too? This tape is only T1's. We can't tell.`
3. `At the Eiffel Tower, an old time-recording machine hid a plaque: ONE HOUR IS MISSING. THE CLOCK IS STILL RUNNING. Was it about this hour? We don't know yet.`
4. `And page 3 is not in the book.`

- 3줄은 Case 10에서 **유일한** Case 03 회상이다. 구현된 Case 03 사실(`time-recording machine`, 명판이 기계 안에 숨겨져 있었음, 명판 문구)만 쓴다. 명판을 남긴 사람, 장치와 시험의 관계는 말하지 않는다.

### 8.2 Next Lead — 탭 한 번
- 화면: Trial Log 뒤표지 안쪽의 **RECORD LIST**(코드 Paper)
  ```
  RECORD LIST · TRIAL LOG
  p.1 · KEPT AT THE STAR
  p.2 · KEPT AT THE STAR
  p.3 · SENT TO: SAINT-SULPICE · ARCHIVE ANNEX
  p.4 · KEPT AT THE STAR
  ```
- 질문: `Where was page 3 sent?`
- 조작: p.3 줄 탭 → 지도(`paris_mystery.png`)로 크로스페이드, Luxembourg Gardens 북쪽 끝이 빛나고 코드 라벨 `Saint-Sulpice`
  - 다른 줄: `That page is here, in the book. Find page 3.`
- 완료 문구
  1. `The list says page 3 was sent to an archive near Saint-Sulpice.`
  2. `It's just north of the Luxembourg Gardens.`
  3. `Is page 3 really there? Who sent it, and why? The list doesn't say.`
  4. `The mystery continues at Saint-Sulpice!`

**hook (→ Case 11):** `Who sent page 3 away — and why?`
**caseSummary:** `You read T1's drum tape and found no three o'clock. You sorted the clocks in an old photo, matched the sundial's shadow, and laid the sun's time under the tape. The hour was there all along: T1 was one hour behind, and page 3 of the Trial Log was missing. The record list said it was sent to Saint-Sulpice.`
**keyWords:** `tape`, `jump`, `fifteen minutes`, `trial clock`, `agree`, `shadow`, `sun`, `behind`, `missing`, `sent`
**upcoming:** `{'11': 'The Unwritten Hour'}`

**Case 11로 넘기는 것:** 3쪽의 행방(목록상 목적지만), 보낸 사람과 이유, 3쪽 내용, T2·T3, T1이 틀린 원인, 가방이 정원에 온 이유(Case 09에서 넘어온 미해결).

---

## 9. 예상 플레이 시간

| 구간 | 예상 |
|---|---|
| Intro | 0:30 |
| M1 | 0:45–1:00 |
| M2 | 1:00–1:30 |
| M3 | 1:00–1:15 |
| Final | 1:30–2:00 |
| Case Closed | 0:30 |
| **합계** | **약 5:15–6:45** |

---

## 10. 퍼즐 차별화

| 퍼즐 | 사고방식 | 조작 | 비슷한 기존 퍼즐과의 차이 |
|---|---|---|---|
| M1 | 숫자 흐름에서 이상한 곳 찾기(읽기) | 테이프 펼치기 + 눈금 탭 | Case 07 Show Strip은 고정 길이 띠의 **위치 맞추기**. 여기는 **틀린 곳 찾기** |
| M2 | 출처에 따라 분류 | 돋보기 + 두 칸 분류 | Case 01은 "느린 시계 고르기". 여기는 **시험 시계인가**로 나누고 시각은 뒤에 공개 |
| M3 | 자연 현상 관찰·재현 | 해를 궤도 따라 끌기 | 시즌 첫 자연 현상 조작. 시계 바늘이 아니라 해를 움직임 |
| Final | 두 기록을 시간축에 겹치기 | 눈금 탭 → 쪽 탭 → 결론 | Case 08 보드(질문↔증거)와 달리 **시간축 정렬**로 결론을 세움 |

Case 09의 미니어처 배치, 톱니 조립, 기호 매칭, 시계 바늘 조작은 쓰지 않는다.

---

## 11. 정합성·스포일러 점검

| # | 확인 | 결과 |
|---|---|---|
| 1 | Case 09 별·`KEPT AT THE STAR` 회수 | Intro 1·2·4·6줄 |
| 2 | 모형을 과거 사건의 증거로 썼나 | 아니다. Intro 7줄, Final 직후 1줄, e4 EvidenceLink에서 구분. M2·Final 판정에 Case 09 연동 동작을 쓰지 않음 |
| 3 | T2·T3 | M2·Case Closed에서 "모른다". 결론 문장은 T1에 한정 |
| 4 | 원인·책임자 | `The records do not say why T1 was wrong.` 변화 ①·②의 주체는 없음 |
| 5 | 3쪽 | 내용은 흐린 줄(읽히지 않음), 보낸 사람·이유·도착 여부 미확정. `SENT TO`는 목록상 목적지 |
| 6 | 제본 흔적 | 쓰지 않음(Case 11 M1 보호) |
| 7 | `removed` / `THE RECORD WAS REMOVED` | 쓰지 않음 |
| 8 | Émile·Victor·Clockmaker | 이름 없음. Case 01 문구는 질문으로만 |
| 9 | Case 03 | Case Closed 3줄 한 번만, 구현된 사실만 |
| 10 | Case 06 편지 | 인용만 |
| 11 | 가방·방패 배지·보라색 도장·찢긴 시간 변경 종이 | 등장하지 않음 |
| 12 | 날짜·시기 | `TRIAL DAY`만. 사진은 "빛바랜 흑백"으로만 표현하고 몇 년 전인지 말하지 않음 |
| 13 | 새 인물·조직 | 없음. 사진 촬영자·기록 작성자는 언급하지 않음 |
| 14 | Notebook만으로 풀이 | M2 Trial Map 칩 직접 제공, Final 사진 시각 letter 제공. 재플레이 불필요 |
| 15 | Case 01–09 저장·라우팅 | 새 ID만 추가, 기존 데이터 변경 없음 |

---

## 12. 구현 메모 (참고)
- **재사용:** `LensInspect`, `SearchStage`/`ZoomPicture`, `StudioMatch` 끌어 놓기·탭-탭, `matchPairs`, `ClockQuestion` 바늘 그리기, `multipleChoice`, `GameButton`, `Paper`, Case Closed `NextLead` + `LetterMap` 지도 하이라이트, 온보딩 손가락
- **신규 위젯:** `DrumTape`, `SunDial`, `TapeTimeline`
- **scene 데이터(실측):** `star_room.png` 명판 사각형(텍스트 오버레이)·문짝 별·세 물건 강조 영역, `record_drum.png`(1254×1254) 테이프 슬롯·명판, `roof_photo.png` 시계 4개 중심·반지름·판정 영역과 해시계 타원·그노몬 방향, `sundial_top.png`(1254×1254) 그노몬 밑점과 `SundialHourLine` 7개 각도(§6.2), `trial_log_open.png` 쪽 글 영역·EMBLEM 원
- **필수 QA:** §5.2.1 성당 시계 360×640 캡처 검수, §6.2 해 토큰·그림자·판정이 같은 데이터에서 나오는지(단위 테스트로 7개 시각의 각도·스냅 확인, 180° 세로선 미사용 확인)
- **신규 코드 아이콘:** `InkGlyph.sun` (기존 InkIcon 잉크 선 스타일, 이미지 없음)
- **공유 컴포넌트 변경:** `InkGlyph` 열거형에 값 하나 추가 외에는 없음
- **테스트(구현 시):** `test/paris_case10_test.dart`, `flutter analyze`. InkGlyph 추가에 따라 아이콘 관련 기존 테스트 확인

### 12.1 학습 설계
| 미션 | dependency / level | expressions |
|---|---|---|
| m1 | essential / comprehension | `fifteen minutes after`, `goes back`, `jumps to` |
| m2 | exposure | `trial clock`, `they all agree` |
| m3 | essential / comprehension | `the same shadow`, `the sun said` |
| final | essential / application | `one hour behind`, `missing`, `Was the hour lost — or was the clock wrong?` |

`CaseLanguageTopic`: `Time words: after, behind, missing` / `시간 표현: after, behind, missing`
Discovery: m1 `deduction`, m2 `deduction`, m3 `evidenceFound`.
탐정 이름: Season 2의 기존 방식(`you` 서술, 치환자 없음).

### 12.2 Glossary
tape 종이 테이프 · drum 원통 · printed 찍었다 · fifteen 15 · minutes 분 · after ~ 뒤에 · jump(s) 건너뛰다 · again 다시 · forward 앞으로 · back 뒤로 · stolen 도둑맞은 · photo(s) 사진 · roof 지붕 · café 카페 · church 교회 · post office 우체국 · trial 시험 · agree 일치하다 · sundial 해시계 · shadow 그림자 · sun 해 · set 맞추다 · sunny 해가 비치는 · behind (시간이) 늦은 · right 맞는 · page 쪽 · book 책 · missing 없어진 · list 목록 · sent 보냈다 · archive 기록 보관소 · annex 별관 · record(s) 기록 · plaque 명판 · machine 기계 · arch 아치 · roads 길 · stairs 계단

---

## 13. Case 09 → 10 → 11 연결 흐름

| 단계 | 탐정이 아는 것 | 그래서 생기는 질문 | 대사 |
|---|---|---|---|
| Case 09 끝 | 모형은 가능성만 보여 준다. 별(T1) → Arc | 실제로 무슨 일이 있었나? | `Was the hour lost — or was the clock wrong?` |
| Intro | 별의 방에 실제 시험 기록이 있다 | T1은 무엇을 기록했나? | `Let's read what T1 wrote.` |
| M1 → M2 | 테이프에 3시가 없다 | 도둑맞았나, T1이 틀렸나? | `So was an hour stolen? Or did T1 show the wrong time?` |
| M2 → M3 | T1은 독립 시계 셋보다 한 시간 늦다 | 아무도 맞출 수 없는 시각은? | `Is there a time no one can set?` |
| M3 → Final | 해도 3:30 | 그 한 시간은 어디에? | `Let's lay it all out.` |
| Final → Case Closed | 한 시간은 있었다. T1은 3–4시에 한 시간 늦었다. 3쪽이 없다 | 3쪽은 어디로? | `And page 3 is not in the book.` |
| Case Closed → Case 11 | 목록상 3쪽의 목적지는 Saint-Sulpice | 누가, 왜? | `Who sent page 3 away — and why?` |
