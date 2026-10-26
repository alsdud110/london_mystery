<a id="top"></a>

# London Mystery — Complete Case Answer Guide

> **Developer / Tester Only** — 일반 사용자에게 배포·노출하지 않습니다.
>
> ⚠️ **SPOILER WARNING** — 모든 사건의 정답과 풀이가 들어 있습니다.

정답은 모두 실제 소스 코드(에피소드 데이터, 장면 테이블, `AnswerChecker`, 퍼즐 위젯, 플레이스루 테스트)에서 확인한 값입니다. 생성 기준: 2026-10-26 작업 트리.

## 공통 규칙

- **입력 비교** (`lib/core/utils/answer_checker.dart`): 단어·숫자 입력은 대문자로 바꾼 뒤 영문자·숫자 외 문자(공백, 구두점, 아포스트로피)를 모두 지우고 비교합니다. 따라서 대소문자·공백·구두점은 무시됩니다 (예: `Big Ben` = `BIGBEN`).
- **순서 / 조합 정답**: 데이터의 `answer`가 `b,c,a`처럼 쉼표로 이어진 경우 순서가 정확해야 합니다. `q1:e2,q2:e3+e4` 같은 짝 맞추기는 짝의 나열 순서는 상관없지만 각 짝의 증거 조합이 정확히 같아야 합니다 (더 많거나 적으면 오답).
- **게임 안 정답표**: Game Master 화면 → `정답표 (도우미용)`에서 현재 사건의 데이터상 정답을 볼 수 있습니다. 이 문서는 그 값을 화면 조작으로 풀어 쓴 것입니다.
- **바로 진입**: Game Master → `사건 바로가기`에서 시즌과 사건을 골라 진행 기록 변경 없이 바로 열 수 있습니다 (테스트 빌드 전용).

## 목차

- **[Season 1 — London](#s1)** — [Case 01](#s1-c01) · [Case 02](#s1-c02) · [Case 03](#s1-c03) · [Case 04](#s1-c04) · [Case 05](#s1-c05) · [Case 06](#s1-c06) · [Case 07](#s1-c07) · [Case 08](#s1-c08) · [Case 09](#s1-c09) · [Case 10](#s1-c10) · [Case 11](#s1-c11) · [Case 12](#s1-c12)
- **[Season 2 — Paris Stands Still](#s2)** — [Case 01](#s2-c01) · [Case 02](#s2-c02) · [Case 03](#s2-c03) · [Case 04](#s2-c04) · [Case 05](#s2-c05) · [Case 06](#s2-c06) · [Case 07](#s2-c07) · [Case 08](#s2-c08) · [Case 09](#s2-c09) · [Case 10](#s2-c10) · [Case 11](#s2-c11) · [Case 12](#s2-c12)

---

<a id="s1"></a>
## Season 1 — London

<a id="s1-c01"></a>

### Case 01 — The Missing Crown
- 장소: King's Cross → British Museum → Big Ben → Hyde Park → Buckingham Palace → The Royal Archive  ·  미션 수: 5 + Final
- [Mission 1](#s1-c01-m1) · [Mission 2](#s1-c01-m2) · [Mission 3](#s1-c01-m3) · [Mission 4](#s1-c01-m4) · [Mission 5](#s1-c01-m5) · [Final](#s1-c01-final)
- [↑ Season 1 목차](#s1) · [↑ 맨 위](#top)

공통 흐름: 지도에서 `GO TO <장소>` → `INVESTIGATE`. 일반 미션은 `TAP TO OPEN`(편지) → `SOLVE THE PUZZLE` → 선택/입력 → `CHECK ANSWER`. 장면형 미션(아래 표시)은 편지 봉투 없이 바로 장면이 열린다.

<a id="s1-c01-m1"></a>

#### Mission 1 — The Mysterious Suitcase
**목표**
- 도둑의 편지를 읽고 다음 행선지(박물관)를 고른다.
**퍼즐 유형**
- 장면 탐색 + 포스터 객관식 (`season1_explores.dart` `m01`)
**정답**
- 포스터 `The British Museum (treasures from long ago)` (option `b`, 황금 파라오·미라 관·글씨 새겨진 큰 돌 포스터)
**풀이 방법**
1. King's Cross 장면에서 벤치 위 **낡은 여행 가방(THE OLD SUITCASE)** 을 탭 → `TAP TO OPEN`으로 편지 읽기 → `BACK TO THE STATION`.
2. (선택) Platform 9 표지판 탭 — 단서 메모만 보여 줌, 진행에 불필요.
3. 오른쪽 **박물관 포스터 보드(NEXT DESTINATION)** 탭 (가방 편지를 먼저 읽어야 열림).
4. 4장 포스터 중 두 번째(B, British Museum) 탭 → `CHECK ANSWER`.
**필요한 단서**
- 가방 속 편지: "old mummies from Egypt and a famous stone"
**힌트**
- "Read the letter again. What two things does the next museum have?" / 미라·유명한 돌은 공룡뼈·버스·로켓이 아님.

<a id="s1-c01-m2"></a>

#### Mission 2 — The Strange Writing
**목표**
- Room 4의 전시물 중 쪽지와 맞는 것을 찾아 이름표의 빠진 단어를 채운다.
**퍼즐 유형**
- 장면 탐색(돋보기) + 단어 입력 (`season1_inspections.dart` `m02`)
**정답**
- `STONE` (허용: `ROSETTA STONE`). 대소문자·공백·구두점 무시.
- 오답 `ROCK` 입력 시 "Very close!" 피드백.
**풀이 방법**
1. 돋보기를 드래그하거나 전시물을 탭. **큰 회색 석판(STRANGE WRITING)** 을 탭/검사.
2. 석판 앞 작은 이름표(THE LABEL)가 열리면 `READ THE LABEL` (석판을 먼저 봐야 열림).
3. 이름표 입력칸에 `STONE` 입력 → `CHECK ANSWER`.
4. (선택) 석판 받침대(plinth)를 탭하면 황금 열쇠(ROOM 4) 발견 메시지 — 정답과 무관.
**필요한 단서**
- 쪽지 4번째 줄 "The second word means a hard piece of rock."
**힌트**
- "It is another word for rock." / 첫 편지의 "a famous ____".

<a id="s1-c01-m3"></a>

#### Mission 3 — The Locked Box
**목표**
- Big Ben 발치에서 도둑의 흔적 3개를 찾아 상자가 숨겨진 곳을 고른다.
**퍼즐 유형**
- 장면 추리(흔적 찾기 → 장소 선택) (`season1_deductions.dart` `m03`)
**정답**
- `Behind the stone in the tower wall` (option `b`) — 그림 속 가로등 빛이 비치는, 긁힌 자국이 있는 벽돌.
**풀이 방법**
1. 장면에서 단서 3개를 모두 탭: ① 젖은 돌바닥 위 **진흙 발자국**, ② **가로등**(또는 벽에 비친 빛), ③ 탑 벽 아래쪽 **긁힌 자국 있는 돌**. (`CLUES 3 / 3`이 되어야 선택 단계로 넘어감)
2. 선택 단계에서 장소 마커 3개(벤치 / 벽 속 돌 / 배수구 뚜껑) 중 **탑 벽의 긁힌 돌** 탭.
3. `SEARCH HERE` 탭.
**필요한 단서**
- 장면 메모 3줄(발자국이 벽에서 멈춤, 가로등이 한 돌을 비춤, 그 돌에 새 긁힌 자국)
**힌트**
- "Where do the footprints stop? Look closely at that place." / 세 단서가 모두 같은 곳을 가리킴.
- 참고: `season1_ciphers.dart`에 이 미션용 숫자단어 암호(417) 데이터가 남아 있으나 `season_catalog.dart`에 등록되지 않아 **게임에서 쓰이지 않음**.

<a id="s1-c01-m4"></a>

#### Mission 4 — The Secret Drawing
**목표**
- 쪽지의 묘사(궁전, 빨간 깃발, 앞의 분수, 왕이 삶)에 맞는 그림을 고른다.
**퍼즐 유형**
- 그림 객관식 (이름 숨김)
**정답**
- 세 번째 그림 **Picture C** = `Buckingham Palace` (option `c`; 깃발과 분수가 있는 넓은 건물)
**풀이 방법**
1. `TAP TO OPEN` → `SOLVE THE PUZZLE`.
2. 이름 없이 그림 4장(A Tower Bridge, B London Eye, C Buckingham Palace, D Big Ben 순) 중 C 탭 → `CHECK ANSWER`.
**필요한 단서**
- Hyde Park 벤치 밑 쪽지
**힌트**
- "Look for a big building with a red flag and a fountain." / "The King lives in a palace."

<a id="s1-c01-m5"></a>

#### Mission 5 — The Royal Guard
**목표**
- 궁전 문 옆 카드의 암호를 풀어 자물쇠 그림 순서를 얻는다.
**퍼즐 유형**
- 조사(examine) — 오답 없음 (`season1_decodes.dart` `m05`)
**정답**
- 입력 없음. 장면이 데이터값 `crown-card`를 자동 제출.
**풀이 방법**
1. 장면에서 왕관과 네모 기호가 그려진 **낡은 카드** 탭(가까이 보기).
2. `EXAMINE THE CODE` 탭 → 숨은 메시지(THE HIDDEN MESSAGE)와 그림 4개 표시.
3. `TAKE THE CARD` 탭.
**필요한 단서**
- 없음. 획득 증거 `Crown Symbol` = 자물쇠 순서 **clock → train → park → museum** (Final에 필요)
**힌트**
- "Look closely at the card near the palace gate." / "Tap the strange square symbol beside the crown. Then press EXAMINE THE CODE."

<a id="s1-c01-final"></a>

#### Final — The Royal Box
**목표**
- 그림 4개 자물쇠를 수첩의 장소별 숫자로 연다.
**퍼즐 유형**
- 숫자 다이얼(그림 자물쇠 4개)
**정답**
- `7924` (자물쇠 순서: 시계 7 · 기차 9 · 공원 2 · 박물관 4)
**풀이 방법**
1. 지도에서 `OPEN THE FINAL CASE`.
2. 각 다이얼은 0에서 시작. 위 화살표(`Lock N up`)로 1번 7회, 2번 9회, 3번 2회, 4번 4회(아래 화살표는 -1, 순환).
3. `OPEN THE BOX`.
**필요한 단서**
- 시계=Big Ben 회중시계 7시(M3), 기차=Platform 9(M1), 공원=백조 2마리(M4), 박물관=Room 4(M2), 순서=Crown Symbol(M5)
**힌트**
- "Each picture is a place. The train is King's Cross!" / 수첩에서 각 장소의 단서 숫자를 찾을 것.

---

<a id="s1-c02"></a>

### Case 02 — The Silent Clock
- 장소: Westminster Bridge → The Clock Room → The Belfry → Inside Big Ben  ·  미션 수: 3 + Final
- [Mission 1](#s1-c02-m1) · [Mission 2](#s1-c02-m2) · [Mission 3](#s1-c02-m3) · [Final](#s1-c02-final)
- [↑ Season 1 목차](#s1) · [↑ 맨 위](#top)

<a id="s1-c02-m1"></a>

#### Mission 1 — The Frozen Hands
**목표**
- Mrs Bell의 메모로 Big Ben이 멈춘 시각을 시계 바늘로 맞춘다.
**퍼즐 유형**
- 시계 맞추기 (`season1_clocks.dart` `ep02_m1`, 데이터상 numberCode)
**정답**
- 시계 `8:17` (데이터 `817`)
- 대표 오답 피드백: `815`(두 칸 더), `832`(3은 15분), `917`(아직 9시 아님).
**풀이 방법**
1. `TAP TO OPEN` → `SOLVE THE PUZZLE`.
2. 바늘은 12:00에서 시작. HOUR `+` 8회, MINUTE `+` 17회 (또는 짧은 바늘·긴 바늘을 드래그). 표시가 `8:17`인지 확인.
3. `SET THE TIME` (바늘을 한 번이라도 움직여야 활성화).
**필요한 단서**
- 메모: 시침 8과 9 사이, 분침 3(=15분)에서 작은 눈금 2칸 더
**힌트**
- 줄 단위로 시침·분침 위치 읽기 / "'Between eight and nine' means the hour is still eight. On the three is fifteen minutes."

<a id="s1-c02-m2"></a>

#### Mission 2 — The Missing Gear
**목표**
- 쪽지를 읽고 사라진 톱니바퀴 위치를 고른다.
**퍼즐 유형**
- 객관식
**정답**
- `Under the smallest bell` (option `c`)
**풀이 방법**
1. `TAP TO OPEN` → `SOLVE THE PUZZLE`.
2. `Under the smallest bell` 탭 → `CHECK ANSWER`.
**필요한 단서**
- 쪽지 "under the bell that is the opposite of the biggest"
**힌트**
- 마지막 두 줄 중 하나에 "not" / "Big and small are opposites."

<a id="s1-c02-m3"></a>

#### Mission 3 — The Time Card
**목표**
- 멈춘 시각(8:17)을 계획서 규칙(시=갤러리, 분=그림)으로 해석한다.
**퍼즐 유형**
- 객관식(이전 단서 활용)
**정답**
- `Gallery 8 · Picture 17` (option `b`)
**풀이 방법**
1. `TAP TO OPEN` → `SOLVE THE PUZZLE`.
2. (선택) 수첩에서 단서 `8:17` 확인.
3. `Gallery 8 · Picture 17` 탭 → `CHECK ANSWER`.
**필요한 단서**
- M1 단서 `8:17`
**힌트**
- "What time did it stop?" / 시는 GALLERY, 분은 PICTURE.

<a id="s1-c02-final"></a>

#### Final — The Great Clock
**목표**
- 도둑이 그림을 가져갈 시각(멈춘 시각 + 1시간)으로 시계를 맞춘다.
**퍼즐 유형**
- 숫자 다이얼 3개 (시각 9:17을 숫자로)
**정답**
- `917` (= 9:17). 오답 피드백: `817`, `717`, `818`.
**풀이 방법**
1. `OPEN THE FINAL CASE`.
2. 다이얼(0 시작) `Lock 1 up` 9회, `Lock 2 up` 1회, `Lock 3 up` 7회.
3. `UNLOCK`.
**필요한 단서**
- M1 `8:17` + Time Card(M3 증거) "One hour after the clock stops"
**힌트**
- 멈춘 시각과 계획의 "one hour after" 두 단서 필요 / 시는 +1, 분은 그대로.

---

<a id="s1-c03"></a>

### Case 03 — The Vanishing Painting
- 장소: Gallery 8 → The Egypt Room → The Great Court → Museum Street  ·  미션 수: 3 + Final
- [Mission 1](#s1-c03-m1) · [Mission 2](#s1-c03-m2) · [Mission 3](#s1-c03-m3) · [Final](#s1-c03-final)
- [↑ Season 1 목차](#s1) · [↑ 맨 위](#top)

<a id="s1-c03-m1"></a>

#### Mission 1 — The Empty Frame
**목표**
- 경비 보고서의 위치 표현대로 Gallery 8에서 물건 3개를 찾는다.
**퍼즐 유형**
- 장면 탐색(찾기 3개) (`season1_investigations.dart` `ep03_m1`, 데이터상 객관식 정답 `c`)
**정답**
- 세 개 모두 발견하면 자동 정답 처리(option `c` = The wet footprint 제출). 순서 무관.
  - 빨간 단추: **벤치 아래** 바닥
  - 파란 천: 오른쪽 벽의 **빈 금색 액자**
  - 젖은 발자국: 왼쪽 **문 옆** 바닥(문 바로 옆 벽 포함)
**풀이 방법**
1. `INVESTIGATE` → 도착 문장과 GUARD REPORT 표시(탭하면 빨리 넘김) → `SEARCH GALLERY 8`.
2. 그림에서 위 세 곳을 탭, 뜨는 카드를 탭해 닫기. (벤치 위/문 자체/다른 벤치는 오답 안내만)
3. 세 번째 발견 시 자동 완료(`CHECK ANSWER` 없음).
**필요한 단서**
- GUARD REPORT 3줄 (under the bench / on the frame / next to the door)
**힌트**
- 각 줄이 물건의 모습과 위치를 말함 / under = 아래 바닥, on = 붙어 있음, next to = 바로 옆.

<a id="s1-c03-m2"></a>

#### Mission 2 — The Three Visitors
**목표**
- 빨간 단추(코트)와 파란 천(스카프)에 맞는 방문객을 고른다.
**퍼즐 유형**
- 객관식
**정답**
- `Miss Rose` (option `b`)
**풀이 방법**
1. `TAP TO OPEN` → `SOLVE THE PUZZLE`.
2. `Miss Rose` 탭 → `CHECK ANSWER`.
**필요한 단서**
- M1 Red Button(코트 단추), 파란 천 / 방문객 메모(Miss Rose: red coat, blue scarf)
**힌트**
- 단추·천 색을 수첩에서 확인 / "A button comes from a coat. A piece of cloth can come from a scarf."

<a id="s1-c03-m3"></a>

#### Mission 3 — The Wet Footprints
**목표**
- 발자국의 젖은 정도로 Miss Rose가 걸은 순서를 정한다.
**퍼즐 유형**
- 순서 맞추기
**정답**
- `The shop → The stairs → The café → The north door` (데이터 `shop,stairs,cafe,door`) — very wet → wet → a little wet → almost dry
**풀이 방법**
1. `TAP TO OPEN` → `SOLVE THE PUZZLE`.
2. 타일을 `The shop`, `The stairs`, `The café`, `The north door` 순으로 탭 (`Undo`/`Start again`으로 수정 가능).
3. `CHECK ANSWER`.
**필요한 단서**
- 청소부 증언 4줄, "Wet shoes get drier with every step!"
**힌트**
- 가장 젖은 것과 가장 마른 것 찾기 / 첫 발자국이 가장 젖음, 마지막이 가장 마름.

<a id="s1-c03-final"></a>

#### Final — The Way Out
**목표**
- 택시 기사의 말(북쪽, 큰 시계탑 건물)과 증거로 Miss Rose의 행선지 그림을 고른다.
**퍼즐 유형**
- 그림 객관식 (이름 표시됨)
**정답**
- **Picture D** `King's Cross` (option `d`)
**풀이 방법**
1. `OPEN THE FINAL CASE`.
2. 그림 4장(A Big Ben, B Tower Bridge, C Hyde Park, D King's Cross) 중 D 탭 → `CHECK ANSWER`.
**필요한 단서**
- M3 증거 Wet Footprint: "The boot smells of trains and smoke." (시계탑 있는 Big Ben과 구별)
**힌트**
- "Two pictures have a clock tower. Look at the evidence you found today, too." / 수첩의 발자국 "Smells of …".

---

<a id="s1-c04"></a>

### Case 04 — The Secret Letter
- 장소: Lost Property → The Platforms → Platform 4 → The Last Train  ·  미션 수: 3 + Final
- [Mission 1](#s1-c04-m1) · [Mission 2](#s1-c04-m2) · [Mission 3](#s1-c04-m3) · [Final](#s1-c04-final)
- [↑ Season 1 목차](#s1) · [↑ 맨 위](#top)

<a id="s1-c04-m1"></a>

#### Mission 1 — The Black Seal
**목표**
- "Meet me where trains never sleep"를 역 안내판과 대조한다.
**퍼즐 유형**
- 객관식
**정답**
- `The platforms` (option `c`)
**풀이 방법**
1. `TAP TO OPEN` → `SOLVE THE PUZZLE`.
2. `The platforms` 탭 → `CHECK ANSWER`.
**필요한 단서**
- STATION GUIDE "Platforms: open day and night"
**힌트**
- 각 장소 마감 시각 확인 / "'Never sleeps' means it never closes."

<a id="s1-c04-m2"></a>

#### Mission 2 — The Four Words
**목표**
- RED · SMALL · CLOCK · PLATFORM에 모두 맞는 승강장을 찾는다.
**퍼즐 유형**
- 객관식
**정답**
- `Platform 4` (option `b`)
**풀이 방법**
1. `TAP TO OPEN` → `SOLVE THE PUZZLE`.
2. `Platform 4` 탭 → `CHECK ANSWER`.
**필요한 단서**
- 짐꾼의 설명 "Platform 4 has a small red clock."
**힌트**
- 네 단어 모두 대조 / "A red door is not the same as a red clock."

<a id="s1-c04-m3"></a>

#### Mission 3 — The Postmark
**목표**
- 편지 묘사(강가의 오래된 성, 탑 4개, 검은 새)에 맞는 소인 그림을 고른다.
**퍼즐 유형**
- 그림 객관식 (이름 숨김)
**정답**
- **Picture B** = `Tower of London` (option `b`; 사각 탑과 높은 성벽의 요새)
**풀이 방법**
1. `TAP TO OPEN` → `SOLVE THE PUZZLE`.
2. 그림(A Buckingham Palace, B Tower of London, C British Museum, D London Eye 순) 중 B 탭 → `CHECK ANSWER`.
**필요한 단서**
- 두 번째 편지 묘사
**힌트**
- castle·river·four towers·black birds를 하나씩 확인 / 성 = 두꺼운 돌벽과 탑.

<a id="s1-c04-final"></a>

#### Final — The Last Letter
**목표**
- 비밀 결사의 이름(탑에 사는 새, 봉인에 찍힌 새)을 쓴다.
**퍼즐 유형**
- 단어 입력 (`THE _____ SOCIETY`)
**정답**
- `RAVEN` (허용: `RAVENS`, `THE RAVEN SOCIETY`). 대소문자·공백·구두점 무시.
- 오답 피드백: `CROW`, `BIRD`, `BLACK`, `TOWER`.
**풀이 방법**
1. `OPEN THE FINAL CASE`.
2. 입력칸에 `RAVEN` 입력 → `CHECK ANSWER`.
**필요한 단서**
- M1 증거 Black Wax Seal: "A raven is pressed into the wax." / M3 탑(Tower)의 검은 새
**힌트**
- 수첩에서 첫 편지의 봉인 확인 / "named after a bird" = 봉인에 찍힌 새 이름.

---

<a id="s1-c05"></a>

### Case 05 — The Locked Room
- 장소: Tower Green → The White Tower → The Raven Room → The Locked Room  ·  미션 수: 3 + Final
- [Mission 1](#s1-c05-m1) · [Mission 2](#s1-c05-m2) · [Mission 3](#s1-c05-m3) · [Final](#s1-c05-final)
- [↑ Season 1 목차](#s1) · [↑ 맨 위](#top)

<a id="s1-c05-m1"></a>

#### Mission 1 — The Ravenmaster
**목표**
- 길 안내 카드로 잠긴 방 위치를 고른다.
**퍼즐 유형**
- 객관식
**정답**
- `On the third floor, on the right` (option `c`)
**풀이 방법**
1. `TAP TO OPEN` → `SOLVE THE PUZZLE`.
2. `On the third floor, on the right` 탭 → `CHECK ANSWER`.
**필요한 단서**
- 카드 "Go up the stairs to the third floor. The door is on the right."
- 저장 단서: 문 닫는 시각 5시 (Final용)
**힌트**
- 방향이 두 개(밖, 계단 위) / third floor = 3층 위, on the right = 오른손 쪽.

<a id="s1-c05-m2"></a>

#### Mission 2 — The Dial Door
**목표**
- 문에 새겨진 지시대로 다이얼을 4번 돌린다.
**퍼즐 유형**
- 순서 맞추기(같은 버튼 반복 사용)
**정답**
- `TURN LEFT → TURN RIGHT → TURN LEFT → TURN RIGHT` (데이터 `left,right,left,right`)
- 오답 피드백: `left,left,left,left`, `left,right,right,left`.
**풀이 방법**
1. `TAP TO OPEN` → `SOLVE THE PUZZLE`.
2. `TURN LEFT`, `TURN RIGHT`, `TURN LEFT`, `TURN RIGHT` 순서로 탭.
3. `CHECK ANSWER`.
**필요한 단서**
- 문의 4줄 지시("the other way", "the same way as the first time" …)
- 저장 단서: 톱니 4개 (Final용)
**힌트**
- 첫 줄이 1번째 회전 / "the other way" = 반대, "the same way as the first time" = 1번 복사.

<a id="s1-c05-m3"></a>

#### Mission 3 — The Ravens' Box
**목표**
- 탑에 사는 까마귀 수를 영어 숫자 단어로 쓴다.
**퍼즐 유형**
- 단어 입력 (`_____ RAVENS`)
**정답**
- `SEVEN` (허용: `7`, `7 RAVENS`, `SEVEN RAVENS`). 대소문자·공백·구두점 무시.
- 오답 피드백: `SIX`, `6`.
**풀이 방법**
1. `TAP TO OPEN` → `SOLVE THE PUZZLE`.
2. `SEVEN` 입력 → `CHECK ANSWER`.
**필요한 단서**
- 표지판 "always six ravens here... and one more, just in case."
**힌트**
- "six ravens"와 "one more" / 6 + 1을 단어로.

<a id="s1-c05-final"></a>

#### Final — The Iron Chest
**목표**
- 뚜껑의 질문 순서(까마귀 → 톱니 → 문 닫는 시각)대로 자물쇠 3개를 연다.
**퍼즐 유형**
- 숫자 다이얼 3개
**정답**
- `745` (까마귀 7 · 톱니 4 · 5시). 발견 순서 `547`류로 넣으면 orderFeedback.
**풀이 방법**
1. `OPEN THE FINAL CASE`.
2. 다이얼(0 시작) `Lock 1 up` 7회, `Lock 2 up` 4회, `Lock 3 up` 5회.
3. `UNLOCK`.
**필요한 단서**
- M3 Seven Ravens(7), M2 Four Gears(4), M1 Five O'Clock(5)
**힌트**
- 각 자물쇠 질문을 단서로 답하기 / 뚜껑 순서: ravens → gears → gates.

---

<a id="s1-c06"></a>

### Case 06 — The Midnight Detective
- 장소: The Market Hall → The Fountain → The Theatre Door → Midnight(분수대)  ·  미션 수: 3 + Final
- [Mission 1](#s1-c06-m1) · [Mission 2](#s1-c06-m2) · [Mission 3](#s1-c06-m3) · [Final](#s1-c06-final)
- [↑ Season 1 목차](#s1) · [↑ 맨 위](#top)

<a id="s1-c06-m1"></a>

#### Mission 1 — Three Witnesses
**목표**
- 목격자 셋에게 질문하고, 두 사람이 일치하는 "들고 있던 것"을 찾는다.
**퍼즐 유형**
- 대화 조사 + 진술 비교 (`season1_dialogues.dart` `ep06_m1`, 데이터 정답 `b` = A small bag)
**정답**
- 비교할 진술 쌍: **The flower seller "He carried a small bag."** + **The juggler "He carried a small bag."** → `A small bag` (option `b`) 자동 제출
- 이후 추가로 **The juggler에게 "What was he wearing?"** ("He had a grey hat.")를 들어야 미션 종료.
**풀이 방법**
1. The flower seller 탭 → 질문 `What did he carry?`.
2. The juggler 탭 → `What did he carry?` (서로 다른 목격자 2명의 진술이 모이면 비교 가능).
3. `COMPARE TWO STATEMENTS` → 두 "small bag" 진술 탭 (코트 두 개 쌍은 "carry가 아니라 wore" 안내, 다른 쌍은 "different things").
4. 일치 후 "ONE MORE THING": The juggler에게 `What was he wearing?` 질문 (미리 들었으면 생략).
5. `DESCRIPTION RECORDED` → `CONTINUE`.
**필요한 단서**
- 증언: flower seller(dark coat, small bag), juggler(grey hat, small bag), baker(dark coat, big red umbrella). "When" 질문은 단서 아님.
**힌트**
- 각자 들고 있던 것 중 두 명이 같은 것 / "A hat is worn, not carried."

<a id="s1-c06-m2"></a>

#### Mission 2 — The Wet Card
**목표**
- 젖은 명함의 지워진 이름(모자 색 = 비구름·오래된 돌 색)을 쓴다.
**퍼즐 유형**
- 단어 입력 (`INSPECTOR ____`)
**정답**
- `GREY` (허용: `GRAY`, `INSPECTOR GREY`, `INSPECTOR GRAY`). 대소문자·공백·구두점 무시.
- 오답 피드백: `RED`, `BLACK`, `DARK`, `WHITE`, `BLUE`.
**풀이 방법**
1. `TAP TO OPEN` → `SOLVE THE PUZZLE`.
2. `GREY` 입력 → `CHECK ANSWER`.
**필요한 단서**
- M1 Witness Notes: juggler "He had a grey hat."
**힌트**
- 수첩의 목격자 노트 확인 / 이름 = 그가 쓴 모자 색.

<a id="s1-c06-m3"></a>

#### Mission 3 — Two Dark Coats
**목표**
- 극장 경비 노트의 두 밤 중 시장 목격자가 본 사람을 고른다.
**퍼즐 유형**
- 객관식
**정답**
- `Monday: a tall man, a grey hat, a small bag` (option `a`)
**풀이 방법**
1. `TAP TO OPEN` → `SOLVE THE PUZZLE`.
2. Monday 항목 탭 → `CHECK ANSWER`.
3. 이어지는 장면에서 경비가 Theatre Ticket(ROW R · SEAT 17, 뒷면 까마귀 도장)을 건넴.
**필요한 단서**
- M1 Witness Notes (grey hat, small bag) — 다크 코트는 두 밤 공통이라 구분 불가
**힌트**
- 시장 목격자 노트와 맞는 밤 / 같은 디테일 말고 다른 디테일로 구분.

<a id="s1-c06-final"></a>

#### Final — The Midnight Detective
**목표**
- 분수대의 키 큰 남자(작은 가방)가 누구인지 밝힌다.
**퍼즐 유형**
- 객관식
**정답**
- `Inspector Grey` (option `c`)
**풀이 방법**
1. `OPEN THE FINAL CASE`.
2. `Inspector Grey` 탭 → `CHECK ANSWER`.
**필요한 단서**
- M1 작은 가방, M3 Monday의 키 큰 남자, M2 Detective Card(분수대에 떨어뜨린 명함: INSPECTOR GREY), M3 티켓(까마귀 도장 = 키 작은 여자 쪽)
**힌트**
- 키·가방 크기로 노트의 인물과 대조 / 분수대에 떨어뜨린 물건을 수첩에서 확인.

<a id="s1-c07"></a>

### Case 07 — The Lost Map
- 장소: Hyde Park  ·  미션 수: 3 + Final
- [Mission 1](#s1-c07-m1) · [Mission 2](#s1-c07-m2) · [Mission 3](#s1-c07-m3) · [Final](#s1-c07-final)
- [↑ Season 1 목차](#s1) · [↑ 맨 위](#top)

> 공통: Case 07~12의 미션은 모두 표준 문제 위젯(`question_widgets.dart`)으로 진행된다(시즌 1 장면 테이블 `season1_explores/inspections/investigations/dialogues/deductions/clocks/decodes`에 ep07~ep12 항목 없음). 보기 순서는 섞이지 않으며 데이터 순서대로 A, B, C, D로 표시된다. 객관식/그림 선택/순서 맞추기/단어 입력은 고른 뒤 `CHECK ANSWER`, 숫자 입력은 키패드 후 `UNLOCK`.

<a id="s1-c07-m1"></a>

#### Mission 1 — The First Directions
**목표**
- 쪽지의 길 안내(Go past the tree / Turn right at the bridge / Look beside the bench)를 따라 맞는 지도를 고른다.
**퍼즐 유형**
- 그림 선택 (imageChoice, 공원 지도 4장 — 지도 아래 이름 표시 없음)
**정답**
- `Picture C` = "Beside the right bench" (option `c`, 그림 `parkMapA`: X가 오른쪽 위 벤치 옆)
- 다른 정답 없음.
**풀이 방법**
1. 쪽지를 읽는다.
2. 네 지도 중 세 번째 그림(C, 좌상단에 "C" 표시)을 탭한다.
3. `CHECK ANSWER`.
**필요한 단서**
- 이 미션의 쪽지(letter)만.
**힌트**
- 지도 아래에서 손가락으로 길을 따라가라. "past the tree"는 나무에서 멈추지 말라는 뜻, "Turn right"와 "beside the bench"가 멈출 곳.

<a id="s1-c07-m2"></a>

#### Mission 2 — The Boathouse
**목표**
- 문에 긁힌 글을 읽고 지도 조각이 든 상자의 위치를 고른다.
**퍼즐 유형**
- 객관식
**정답**
- `C. Under the table, behind the watering can` (option `c`)
**풀이 방법**
1. 문의 글(The box is not on the shelf / under the table / behind the green watering can)을 읽는다.
2. 보기 C를 탭 → `CHECK ANSWER`.
**필요한 단서**
- 이 미션의 글만.
**힌트**
- 두 번째 줄은 "없는 곳"을 말한다. "Behind"는 "in front of"의 반대.

<a id="s1-c07-m3"></a>

#### Mission 3 — The Three Pieces
**목표**
- 지도 조각 세 장을 위→아래 순서로 맞춘다.
**퍼즐 유형**
- 순서 맞추기 (sequence, 3칸, 각 조각 1회 사용)
**정답**
- `The station piece → The park piece → The river piece` (데이터 `station,park,river`)
- 근거: river는 맨 위가 아님 + station과 river는 맞닿지 않음 → 둘이 위/아래 끝, river가 아래.
**풀이 방법**
1. 타일 `The station piece` 탭 → `The park piece` 탭 → `The river piece` 탭 (1·2·3번 줄이 채워짐, 틀리면 `Undo`/`Start again`).
2. `CHECK ANSWER`.
**필요한 단서**
- 조각 뒷면 지시문(이 미션 letter). 획득 증거 `Joined Map`(화살표가 북쪽=공원 위쪽)은 Final에서 사용.
**힌트**
- 맞닿지 않는 두 조각부터. 맞닿지 않는 조각은 맨 위와 맨 아래 — 그중 맨 위가 아닌 것은?

<a id="s1-c07-final"></a>

#### Final — The Last Piece
**목표**
- Grey의 길 안내(나무 지나서, 다리 건너 왼쪽)와 Joined Map의 화살표(북쪽, 공원 맨 위)를 합쳐 멈출 곳의 지도를 고른다.
**퍼즐 유형**
- 그림 선택 (공원 지도 4장, 이름 표시 없음)
**정답**
- `Picture B` = "At the old gate" (option `b`, 그림 `parkMapD`)
- 함정: `Picture A`(왼쪽 벤치) — 왼쪽은 맞지만 화살표가 가리키는 맨 위가 아님.
**풀이 방법**
1. 두 번째 그림(B)을 탭 → `CHECK ANSWER`.
**필요한 단서**
- Mission 3의 `Joined Map` 증거("An arrow points north, to the top of the park.").
**힌트**
- 두 단서(Grey의 길, 지도 화살표)를 모두 써라. Grey의 길은 두 곳을 남긴다 — 그중 공원 맨 위는?

<a id="s1-c08"></a>

### Case 08 — The Mystery on Platform 9
- 장소: King's Cross  ·  미션 수: 3 + Final
- [Mission 1](#s1-c08-m1) · [Mission 2](#s1-c08-m2) · [Mission 3](#s1-c08-m3) · [Final](#s1-c08-final)
- [↑ Season 1 목차](#s1) · [↑ 맨 위](#top)

<a id="s1-c08-m1"></a>

#### Mission 1 — The Name Tag
**목표**
- 이름이 지워진 꼬리표를 보고 승객에게 할 가장 유용한 질문을 고른다.
**퍼즐 유형**
- 객관식
**정답**
- `B. "Where are you going?"` (option `b`)
**풀이 방법**
1. 꼬리표(TO: Edinburgh, 1 adult, alone)를 읽는다.
2. 보기 B 탭 → `CHECK ANSWER`.
**필요한 단서**
- 꼬리표(letter).
**힌트**
- 이름은 없지만 확인할 수 있는 부분은? 'TO: Edinburgh'를 모든 승객에게서 확인할 질문은?

<a id="s1-c08-m2"></a>

#### Mission 2 — Four Passengers
**목표**
- 승객 네 명의 대답을 꼬리표와 비교해 가방 주인을 찾는다.
**퍼즐 유형**
- 단어 입력 (프롬프트 `MRS _____`)
**정답**
- `ROBIN`
- 허용: `MRS ROBIN`. 대소문자·공백·구두점 무시(`Mrs. Robin`, `robin` 모두 정답).
- 오답 피드백 있음: `LILY`, `PATEL`, `BROWN`.
**풀이 방법**
1. 텍스트 칸에 `ROBIN` 입력 → `CHECK ANSWER`.
**필요한 단서**
- Mission 1 꼬리표("1 adult, alone"). Edinburgh 행은 Lily(아빠와 동행)와 Mrs Robin(혼자) 둘뿐.
**힌트**
- Edinburgh로 가는 사람은 둘. 'Alone'은 혼자, 'My dad and I'는 두 사람.

<a id="s1-c08-m3"></a>

#### Mission 3 — Inside the Suitcase
**목표**
- 표와 자물쇠 쪽지로 3자리 코드를 만든다(좌석 번호 → 기차 시각의 '시').
**퍼즐 유형**
- 숫자 입력 (3자리)
**정답**
- `429` (Seat forty-two = 42, 9:30 기차의 hour = 9)
- 오답 피드백: `930`(전체 시각), 순서만 틀린 조합(예: `942`)은 "Right numbers, wrong order".
**풀이 방법**
1. 키패드에서 `4` `2` `9` → `UNLOCK`.
**필요한 단서**
- 이 미션의 TICKET + NOTE ON THE LOCK.
**힌트**
- 'Forty-two'는 숫자로 쓰기. 'The hour of my train'은 분 없이 시만.

<a id="s1-c08-final"></a>

#### Final — The Last Train
**목표**
- "Gallery 8에 간 적 없다"는 Mrs Robin의 거짓말을 증거로 반박한다.
**퍼즐 유형**
- 객관식 (이전 사건 증거 선택)
**정답**
- `C. Red Button` (option `c`)
- 다른 보기: Name Tag / Luggage Tag / Passenger Notes 는 오답.
**풀이 방법**
1. 보기 C `Red Button` 탭 → `CHECK ANSWER`.
2. (확인용) Notebook → Case Archive → Case 03에서 Red Button이 Gallery 8에서 발견된 코트 단추임을 볼 수 있음.
**필요한 단서**
- Case 03의 `Red Button`(Gallery 8에서 발견, 코트 단추) + Mission 2의 단서("She wears a long red coat").
**힌트**
- Gallery 8은 Case 03. Notebook → Case Archive → Case 03에서 Gallery 8에 남겨진 것은? 그리고 Mrs Robin이 입은 옷을 생각하라.

<a id="s1-c09"></a>

### Case 09 — The Missing Jewel
- 장소: Buckingham Palace  ·  미션 수: 3 + Final
- [Mission 1](#s1-c09-m1) · [Mission 2](#s1-c09-m2) · [Mission 3](#s1-c09-m3) · [Final](#s1-c09-final)
- [↑ Season 1 목차](#s1) · [↑ 맨 위](#top)

<a id="s1-c09-m1"></a>

#### Mission 1 — The Empty Box
**목표**
- 보석함을 연 열쇠가 누구의 것인지 고른다.
**퍼즐 유형**
- 객관식
**정답**
- `C. The guard's key` (option `c`)
**풀이 방법**
1. 집사의 설명(big gold key만 보석함을 연다)을 읽는다.
2. 보기 C 탭 → `CHECK ANSWER`.
**필요한 단서**
- 이 미션의 letter. 획득 단서 `The Gold Key`(Guard)는 Final에서 사용.
**힌트**
- 마지막 줄: 어떤 열쇠가 여는가? 'The maid's key'는 하녀 소유의 열쇠라는 뜻.

<a id="s1-c09-m2"></a>

#### Mission 2 — The New Helper
**목표**
- 경비의 기억(4글자, A로 시작·끝, 가운데 두 글자는 M 다음 글자)으로 새 도우미 이름을 맞춘다.
**퍼즐 유형**
- 단어 입력 (프롬프트 `NAME: ____`)
**정답**
- `ANNA` (대소문자 무시)
- 오답 피드백: `AMMA`, `ALLA`.
**풀이 방법**
1. 텍스트 칸에 `ANNA` 입력 → `CHECK ANSWER`.
**필요한 단서**
- 이 미션의 letter.
**힌트**
- 알파벳: K, L, M 다음은? 그 글자를 두 A 사이에 두 번.

<a id="s1-c09-m3"></a>

#### Mission 3 — The Changing of the Guard
**목표**
- 교대 시간표(8시 시작, 2시간마다)로 '세 번째 교대' 시각을 구한다.
**퍼즐 유형**
- 숫자 입력 (2자리)
**정답**
- `12` (8 → 10 → 12)
- 오답 피드백: `3`, `6`, `10`, `14`.
**풀이 방법**
1. 키패드에서 `1` `2` → `UNLOCK`.
**필요한 단서**
- 시간표(letter).
**힌트**
- 'Every two hours' = 매번 2시간 더하기. 'The third change'는 첫 번째도 포함해서 센다.

<a id="s1-c09-final"></a>

#### Final — The Three Things
**목표**
- R.의 쪽지("Hide it in the thing of the one whose key you used")와 메모로 보석이 숨겨진 물건을 찾는다.
**퍼즐 유형**
- 단어 입력 (프롬프트 `IN THE ___`)
**정답**
- `HAT`
- 허용: `BLACK HAT`, `TALL BLACK HAT`, `THE HAT`, `THE BLACK HAT`, `CARLS HAT`(구두점 무시이므로 `Carl's hat`도 정답). 대소문자·공백 무시.
- 논리: 열쇠는 경비(Carl)의 것(Mission 1) → Ben은 green bag → Anna는 black이 아님 → Anna=red umbrella → Carl=tall black hat.
- 함정 피드백: `UMBRELLA`/`RED UMBRELLA`(Anna는 빌렸을 뿐), `BAG`/`GREEN BAG`, `ANNA`.
**풀이 방법**
1. 텍스트 칸에 `HAT` 입력 → `CHECK ANSWER`.
**필요한 단서**
- Mission 1 단서 `The Gold Key`(경비의 열쇠), Mission 3 전환 장면(Carl = 열쇠를 빌려준 경비), Final의 메모.
**힌트**
- Anna가 열쇠를 썼지만 그 열쇠는 누구의 것? Notebook에서 확인한 뒤 그 주인의 물건을 메모로 찾아라.

<a id="s1-c10"></a>

### Case 10 — The London Raven
- 장소: Tower of London / Tower Bridge  ·  미션 수: 3 + Final
- [Mission 1](#s1-c10-m1) · [Mission 2](#s1-c10-m2) · [Mission 3](#s1-c10-m3) · [Final](#s1-c10-final)
- [↑ Season 1 목차](#s1) · [↑ 맨 위](#top)

<a id="s1-c10-m1"></a>

#### Mission 1 — Which Raven?
**목표**
- 작고, 조용하고, 금반지를 낀 까마귀를 고른다.
**퍼즐 유형**
- 객관식
**정답**
- `C. Poppy` (option `c`)
**풀이 방법**
1. Ravenmaster의 설명을 읽는다.
2. 보기 C 탭 → `CHECK ANSWER`.
**필요한 단서**
- 이 미션의 letter.
**힌트**
- small, quiet, gold ring을 하나씩 맞춰라. 'The smallest'는 가장 작은.

<a id="s1-c10-m2"></a>

#### Mission 2 — Four Mornings
**목표**
- 요일별 단어를 월요일부터 순서대로 놓는다.
**퍼즐 유형**
- 순서 맞추기 (4칸, 각 단어 1회)
**정답**
- `NORTH → TOWER → BRIDGE → THREE` (데이터 `north,tower,bridge,three`; Mon/Tue/Wed/Thu)
- 오답 피드백: 메모 순서(`BRIDGE,NORTH,THREE,TOWER`), 벽 위 배치 순서(`BRIDGE,THREE,NORTH,TOWER`), 그 외 순서는 "Start with Monday...".
**풀이 방법**
1. 타일 `NORTH` → `TOWER` → `BRIDGE` → `THREE` 순으로 탭.
2. `CHECK ANSWER`.
**필요한 단서**
- 메모(letter). 획득 증거 `Raven Papers`는 Mission 3에서 사용.
**힌트**
- 월요일 단어부터. 요일 이름을 먼저 순서대로 놓고 단어를 맞춰라.

<a id="s1-c10-m3"></a>

#### Mission 3 — The Meeting Place
**목표**
- Poppy의 네 단어 중 두 단어를 합친 런던 장소를 고른다.
**퍼즐 유형**
- 그림 선택 (랜드마크 4장, 그림 아래 이름 표시됨)
**정답**
- `Picture C — Tower Bridge` (option `c`)
- 오답: London Eye(A), Tower of London(B, 단어 하나만 포함), King's Cross(D).
**풀이 방법**
1. 세 번째 그림 `Tower Bridge` 탭 → `CHECK ANSWER`.
**필요한 단서**
- Mission 2의 `Raven Papers`(NORTH · TOWER · BRIDGE · THREE): TOWER+BRIDGE = 장소, NORTH+THREE = 북쪽 탑, 3시.
**힌트**
- Notebook에서 네 단어를 다시 보라. 'Put together'는 두 단어를 나란히 붙여 한 이름을 만든다는 뜻.

<a id="s1-c10-final"></a>

#### Final — The Raven's Message
**목표**
- 네 종이를 WHO → WILL do → to WHAT → WHEN 순으로 놓아 경고문을 완성한다.
**퍼즐 유형**
- 순서 맞추기 (4칸, 각 1회)
**정답**
- `THE CLOCKMAKER → WILL STOP → BIG BEN → AT MIDNIGHT` (데이터 `clockmaker,stop,bigben,midnight`)
- 오답 피드백 있음: `AT MIDNIGHT` 맨 앞, `BIG BEN`이 2번째, `BIG BEN` 맨 앞 등.
**풀이 방법**
1. 타일 `THE CLOCKMAKER` → `WILL STOP` → `BIG BEN` → `AT MIDNIGHT` 순으로 탭.
2. `CHECK ANSWER`.
**필요한 단서**
- Ravenmaster의 지시(letter)만.
**힌트**
- 네 질문에 종이를 하나씩 맞춰라. 'Who'는 사람, 'Will stop'은 할 일, 'When'은 시간.

<a id="s1-c11"></a>

### Case 11 — The Masked Stranger
- 장소: Covent Garden 극장 / King's Cross  ·  미션 수: 3 + Final
- [Mission 1](#s1-c11-m1) · [Mission 2](#s1-c11-m2) · [Mission 3](#s1-c11-m3) · [Final](#s1-c11-final)
- [↑ Season 1 목차](#s1) · [↑ 맨 위](#top)

<a id="s1-c11-m1"></a>

#### Mission 1 — Three Stories
**목표**
- 세 목격자 중 다른 두 명과 일치하지 않는 사람을 고른다.
**퍼즐 유형**
- 객관식 (보기 3개)
**정답**
- `C. The child` (option `c`) — 금색 가면, 짧은 초록 망토 (나머지 둘은 흰 가면·검은 망토)
**풀이 방법**
1. 세 진술을 읽는다.
2. 보기 C 탭 → `CHECK ANSWER`.
**필요한 단서**
- 이 미션의 letter.
**힌트**
- 각 진술의 가면 색을 비교하라. 두 이야기가 같고 하나가 다르다.

<a id="s1-c11-m2"></a>

#### Mission 2 — The White Mask
**목표**
- 가면 안에 거꾸로 쓰인 단어 `THGINDIM`을 바로 읽는다.
**퍼즐 유형**
- 단어 입력 (8칸 프롬프트 `________`)
**정답**
- `MIDNIGHT` (대소문자 무시)
- 오답 피드백: `THGINDIM`(그대로 입력).
**풀이 방법**
1. 텍스트 칸에 `MIDNIGHT` 입력 → `CHECK ANSWER`.
**필요한 단서**
- 가면 안 글자(letter).
**힌트**
- 마지막 글자 M부터 왼쪽으로: I, D, N... / 밤 12시를 뜻하는 시간.

<a id="s1-c11-m3"></a>

#### Mission 3 — The Stage Door
**목표**
- 택시 기사 설명(북쪽, 큰 아치 두 개와 시계탑이 있는 큰 역)으로 도망간 곳을 고른다.
**퍼즐 유형**
- 그림 선택 (`hideOptionNames: true` — 그림 아래 이름 없음, 설명으로 판단)
**정답**
- `Picture A` = King's Cross (option `a`; 큰 아치형 유리 지붕과 시계탑이 있는 긴 건물)
- 오답: B Buckingham Palace, C Hyde Park, D Big Ben.
**풀이 방법**
1. 첫 번째 그림(A) 탭 → `CHECK ANSWER`.
**필요한 단서**
- 기사의 진술(letter), 이전 전환 장면의 "the station that never sleeps"(Case 04 참조).
**힌트**
- 'The station that never sleeps' — Case 04에서 기차가 잠들지 않던 곳은? Arches는 터널 윗부분 같은 둥근 모양.

<a id="s1-c11-final"></a>

#### Final — Behind the Mask
**목표**
- 카드 내용("We met at the very start / letter in a suitcase / I still love trains")으로 가면 쓴 사람을 밝힌다.
**퍼즐 유형**
- 객관식 (이전 사건 증거 참조)
**정답**
- `D. The Shadow` (option `d`)
**풀이 방법**
1. 보기 D 탭 → `CHECK ANSWER`.
2. (확인용) Case Archive → Case 01 → 가방 속 편지의 서명 "The Shadow / P.S. I love trains!".
**필요한 단서**
- Case 01의 Old Letter(서명: The Shadow, P.S. I love trains!), Mission 3의 `Toy Train Whistle`/단서 "I Love Trains".
**힌트**
- 'The very start'는 첫 사건. Case Archive → Case 01의 가방 속 편지를 누가 서명했나?

<a id="s1-c12"></a>

### Case 12 — The Midnight Case
- 장소: Big Ben / King's Cross / Tower of London / Under Big Ben  ·  미션 수: 3 + Final
- [Mission 1](#s1-c12-m1) · [Mission 2](#s1-c12-m2) · [Mission 3](#s1-c12-m3) · [Final](#s1-c12-final)
- [↑ Season 1 목차](#s1) · [↑ 맨 위](#top)

<a id="s1-c12-m1"></a>

#### Mission 1 — The Real Gear
**목표**
- 금속(brass)·톱니 수(8)·까마귀 도장 세 조건을 모두 맞는 진짜 톱니바퀴를 고른다.
**퍼즐 유형**
- 객관식
**정답**
- `D. Brass, eight teeth, a raven stamp` (option `d`)
**풀이 방법**
1. Mrs Bell의 설명을 읽는다.
2. 보기 D 탭 → `CHECK ANSWER`.
**필요한 단서**
- 이 미션의 letter(Case 02의 까마귀 도장 언급). 획득 단서 `Eight Teeth`(8)는 Final 두 번째 자물쇠.
**힌트**
- 각 톱니마다 금속·톱니·도장 세 가지를 확인하고, 하나라도 틀리면 지워라.

<a id="s1-c12-m2"></a>

#### Mission 2 — The Last Train In
**목표**
- 도착 안내판과 Grey의 말(작은 빨간 시계가 있는 플랫폼, Edinburgh 기차 다음)로 Clockmaker의 도착 시각을 구한다.
**퍼즐 유형**
- 숫자 입력 (시각 형식, 4자리 — 화면에 `HH:MM`로 콜론이 고정 표시, 콜론은 입력하지 않음)
**정답**
- `11:40` (데이터 `1140`, 11:40 from Paris — Platform 4)
- 오답 피드백: `1015`(같은 플랫폼 4지만 Edinburgh 이전), `1104`(Edinburgh 기차 자체), `1155`(다른 플랫폼).
**풀이 방법**
1. 키패드에서 `1` `1` `4` `0` → `UNLOCK`.
**필요한 단서**
- Case 04의 작은 빨간 시계 = Platform 4 (Case Archive → Case 04).
**힌트**
- Case 04에서 작은 빨간 시계가 있던 플랫폼은? 그 플랫폼의 두 기차 중 Edinburgh 이후의 것.

<a id="s1-c12-m3"></a>

#### Mission 3 — The Raven's Riddle
**목표**
- 수수께끼(손은 있지만 박수 못 침, 얼굴은 있지만 웃지 못함, 아주 높고 매시간 울림)를 풀어 문 위치를 쓴다.
**퍼즐 유형**
- 단어 입력 (프롬프트 `UNDER ___ ___`, 3+3칸)
**정답**
- `BIG BEN`
- 허용: `BIGBEN`, `THE CLOCK TOWER`, `CLOCK TOWER`, `ELIZABETH TOWER`. 대소문자·공백 무시.
**풀이 방법**
1. 텍스트 칸에 `BIG BEN` 입력 → `CHECK ANSWER`.
**필요한 단서**
- 수수께끼(letter), Case 02(Big Ben). 획득 단서 `Seven Ravens`(7)는 Final 세 번째 자물쇠.
**힌트**
- 시계에도 손(바늘)과 얼굴(문자판)이 있다. 매시간 울리는 런던의 높은 곳 — Case 02에서 갔던 곳.

<a id="s1-c12-final"></a>

#### Final — The Clockmaker's Door
**목표**
- 문에 새겨진 순서대로 세 자물쇠 숫자를 맞춘다: ① 작고 빨간 시계가 있는 플랫폼 번호, ② 진짜 톱니의 이 수, ③ 탑을 지키는 까마귀 수.
**퍼즐 유형**
- 숫자 다이얼 자물쇠 (finalCode, 다이얼 3개 — 그림 기호 없음)
**정답**
- `4 · 8 · 7` (데이터 `487`)
- 함정: 오늘 찾은 순서 `8 · 4 · 7`(=`847`) 등 숫자는 맞고 순서만 틀리면 orderFeedback "You put the numbers in the order you found them tonight..." 표시.
**풀이 방법**
1. 다이얼은 모두 0에서 시작. 위 화살표 +1, 아래 화살표 −1(0→9로 순환).
2. 첫째 다이얼 4 (위 ×4), 둘째 다이얼 8 (위 ×8 또는 아래 ×2), 셋째 다이얼 7 (위 ×7 또는 아래 ×3).
3. `UNLOCK`.
**필요한 단서**
- Mission 2 단서 `Platform 4`(4) / Case 04, Mission 1 단서 `Eight Teeth`(8), Mission 3 단서 `Seven Ravens`(7) / Case 05(Tower).
**힌트**
- 자물쇠마다 다른 숫자 — Notebook에서 세 출처를 찾아 자물쇠에 맞춰라. 까마귀는 오늘 Tower 단서나 Case Archive의 Tower 사건.
- 'The platform whose clock is small and red' = 작은 빨간 시계가 있는 플랫폼.

<a id="s2"></a>
## Season 2 — Paris Stands Still

<a id="s2-c01"></a>

### Case 01 — The Ticking Watch
- 장소: GARE DU NORD · PARIS  ·  미션 수: 3 + Final
- [Mission 1](#s2-c01-m1) · [Mission 2](#s2-c01-m2) · [Mission 3](#s2-c01-m3) · [Final](#s2-c01-final)
- [↑ Season 2 목차](#s2) · [↑ 맨 위](#top)

<a id="s2-c01-m1"></a>

#### Mission 1 — The Three Clocks
**목표**
- 역 홀의 시계 셋 중 한 시간 늦은 시계를 찾아 Lost Property Desk에 신고한다.
**퍼즐 유형**
- 장면 탐색 + 객관식 (StationClocks 장면)
**정답**
- `THE OLD CLOCK` (option `c`, 9:00). 나머지 THE HALL CLOCK(`a`)·THE PLATFORM CLOCK(`b`)은 10:00.
**풀이 방법**
1. INVESTIGATE → 홀 그림에서 시계 세 개(벽의 큰 시계, 철기둥 시계, 데스크 위 황동 시계)를 하나씩 탭해 확대 → 닫기.
2. 세 시계를 다 보면 출발 안내판(DEPARTURE BOARD)이 표시됨 → 탭해 공지 읽기 → BACK TO THE HALL.
3. 오른쪽 아래 Lost Property 데스크 탭(시계·안내판을 먼저 안 보면 안내 문구만 나옴) → 시계 카드 3장 중 `THE OLD CLOCK`(9:00) 선택 → REPORT IT.
**필요한 단서**
- 홀의 STATION NOTICE ("If one clock is ONE HOUR BEHIND, report it to the LOST PROPERTY DESK.")
**힌트**
- "Two of them show the same time." / "Behind means one hour less. Which clock shows 9:00?"

<a id="s2-c01-m2"></a>

#### Mission 2 — The Lost Ticket
**목표**
- 직원 메모의 순서어(FIRST / NEXT / AFTER THAT)로 사건 순서를 맞춘다.
**퍼즐 유형**
- 순서 맞추기
**정답**
- `b,c,a` = ① The hall clock struck ten. → ② A man with a pocket watch came in. → ③ The old clock showed nine.
**풀이 방법**
1. INVESTIGATE → (선택) 분실 티켓 그림을 탭해 확대 → BACK TO THE NOTES. 필수 여부는 코드상 강제 없음으로 보임.
2. TAP TO OPEN → SOLVE THE PUZZLE.
3. 문장 카드를 위 순서대로 탭 → CHECK ANSWER. (잘못 넣으면 Start again으로 비움)
**필요한 단서**
- CLERK'S NOTES (FIRST = hall clock, NEXT = man, AFTER THAT = old clock)
**힌트**
- "Find the order words: FIRST, NEXT and AFTER THAT." / "FIRST is the hall clock. AFTER THAT is the old clock."

<a id="s2-c01-m3"></a>

#### Mission 3 — The Clockmaker's Mark
**목표**
- 늦은 옛 시계 바늘을 한 시간 앞으로 돌린다.
**퍼즐 유형**
- 시계 맞추기
**정답**
- 시계 `10:00` (데이터 `1000`). 시작 위치는 9:00.
**풀이 방법**
1. INVESTIGATE → TAP TO OPEN → SOLVE THE PUZZLE.
2. 시침(짧은 바늘)을 9에서 10으로 드래그(분침은 12 그대로). 다이얼 아래 HOUR/MINUTE 증감 버튼으로도 조정 가능(테스트 헬퍼가 hour+ 키 사용).
3. SET THE TIME.
**필요한 단서**
- 시계 틀에 새겨진 글: "Move its hands FORWARD one hour to match the hall clock."
**힌트**
- "The old clock shows 9:00. FORWARD means later." / "The short hand moves to the next number. The long hand stays on 12."

<a id="s2-c01-final"></a>

#### Final — The Hidden Compartment
**목표**
- 모은 글자 T·I·M·E로 황동 상자 글자 자물쇠를 연다.
**퍼즐 유형**
- 단어(글자 자물쇠)
**정답**
- `TIME` (대소문자/공백/구두점 무시). ITEM·EMIT·MITE는 오답(전용 피드백 있음).
**풀이 방법**
1. 지도에서 OPEN THE FINAL CASE.
2. 글자 타일을 T → I → M → E 순으로 탭(또는 슬롯으로 드래그). 잘못 넣은 슬롯은 탭해서 빼기.
3. OPEN THE LOCK.
**필요한 단서**
- M1 T(옛 시계 유리), M2 I(티켓 뒷면), M3 M(시계 속 작은 문), 상자에 새겨진 E
**힌트**
- "What word means hours and minutes?" / "Clocks show the T _ _ E."

<a id="s2-c02"></a>

### Case 02 — The Vanishing Painter
- 장소: MONTMARTRE · PARIS  ·  미션 수: 3 + Final
- [Mission 1](#s2-c02-m1) · [Mission 2](#s2-c02-m2) · [Mission 3](#s2-c02-m3) · [Final](#s2-c02-final)
- [↑ Season 2 목차](#s2) · [↑ 맨 위](#top)

<a id="s2-c02-m1"></a>

#### Mission 1 — The Painted Street
**목표**
- 실제 거리와 화가의 그림을 비교해 바뀐 곳 세 군데를 찾는다.
**퍼즐 유형**
- 틀린 그림 찾기 (spotDifferences)
**정답**
- `clock,window,lamp` (순서 무관, 세 곳 모두 찾으면 자동 해결)
  - 빨간 문 위의 작은 시계(그림에만 있음)
  - 오른쪽 위층 창문(그림에서 빠짐)
  - 계단 옆 가로등(그림에서 밝음)
**풀이 방법**
1. INVESTIGATE → TAP TO OPEN(쪽지) → SOLVE THE PUZZLE. 그림(THE PAINTING) 화면으로 시작, 상단 토글로 THE STREET와 전환 가능(어느 쪽에서 탭해도 인정).
2. 빨간 문 바로 위 벽, 오른쪽 위층 창문, 계단 옆 가로등을 차례로 탭. 다른 곳 탭은 오답 아님("The same on both. Read the note again.").
**필요한 단서**
- 화가 쪽지: "Look above the red door. / Find the window that is missing. / Check the lamp beside the steps."
**힌트**
- "Each line of the note tells you where to look." / "ABOVE means higher than. MISSING means it is not there. BESIDE means next to."

<a id="s2-c02-m2"></a>

#### Mission 2 — The Artist's Studio
**목표**
- 작업실에 숨긴 그림 3점을 찾고, 메모 A·B·C를 각 그림과 짝짓는다.
**퍼즐 유형**
- 장면 탐색 + 짝 맞추기 (matchPairs)
**정답**
- `a:p2,b:p3,c:p1` (순서 무관)
  - A — BEFORE THE RAIN → 먹구름 + 마른 돌바닥(p2, 책상 서랍에서 발견)
  - B — AFTER THE RAIN STOPPED → 젖어 반짝이는 돌바닥 + 먹구름이 조금 남은 하늘(p3, 책상 밑 상자)
  - C — WHEN THE SKY TURNED GOLD → 하늘 전체 금빛, 먹구름 없음 + 마른 돌바닥(p1, 낡은 트렁크)
- 짝 맞추기 화면의 그림 배치 순서는 p3, p1, p2 (데이터 `order`; 메모 순서와 다름). 화면엔 번호 없이 그림만 보이므로 먹구름·돌바닥으로 구분.
- 구별 기준: **하늘**(p1 금빛·먹구름 없음 / p2 짙은 먹구름 / p3 은회색, 회색 구름이 남음)과 **돌바닥**(p1·p2 마름 / p3 젖어서 반사). 작은 그림이 헷갈리면 돋보기 버튼으로 확대.
**풀이 방법**
1. INVESTIGATE → 작업실 그림에서 오른쪽 아래 낡은 트렁크, 책상 서랍, 책상 밑 상자를 탭해 그림 3점 찾기(각각 닫기).
2. 책상 위 종이(Papers on the desk) 탭 → 메모 읽고 닫기(그림을 먼저 다 찾아야 열림).
3. MATCH THE NOTES → 메모 탭 후 해당 그림 탭(또는 메모를 그림으로 드래그) ×3 → CHECK.
**필요한 단서**
- 책상 위 메모 A/B/C (먹구름과 돌바닥 상태)
**힌트**
- "Each note says WHEN he painted it. Check the clouds and the stones." / "BEFORE THE RAIN, the stones are dry. AFTER THE RAIN, they are wet and shiny."

<a id="s2-c02-m3"></a>

#### Mission 3 — The Hidden Layer
**목표**
- 캔버스의 물감을 밀어 내고 밑그림의 램프·계단·문을 찾는다.
**퍼즐 유형**
- 레이어 벗기기 + 장면 탐색 (revealLayer)
**정답**
- `lamp,steps,gate` (순서 무관): 키 큰 가로등(왼쪽), 아래쪽 돌계단, 두 기둥 사이 철문.
**풀이 방법**
1. INVESTIGATE → TAP TO OPEN → SOLVE THE PUZZLE.
2. 아래 슬라이더("Slide the paint away")를 오른쪽 끝까지 드래그(밀기 전 탭은 "Thick paint. Slide it away first.").
3. 드러난 스케치에서 가로등, 계단, 문을 각각 탭 → 세 개 찾으면 해결.
**필요한 단서**
- 액자 쪽지: "Slide the paint away and look UNDERNEATH ... the gate is black."
**힌트**
- "Slide the paint away first." / "The lamp is tall. The steps are at the bottom. The gate is between two pillars."

<a id="s2-c02-final"></a>

#### Final — Behind the Canvas
**목표**
- 세 단서를 모두 만족하는 캔버스를 골라 뒤집는다.
**퍼즐 유형**
- 그림 선택 (canvasChoice, 증거 대조)
**정답**
- `CANVAS C` (option `c`: 돌계단, 가로등, 검은 철문, 파란 하늘)
- 오답 이유: A = 빨간 문, B = 금빛 하늘(문 없음), D = 파란 문.
**풀이 방법**
1. 네 캔버스 썸네일 CANVAS A~D를 모두 한 번씩 탭(다 보기 전에는 뒤집기 버튼 비활성).
2. CANVAS C 선택 → TURN CANVAS C AROUND.
3. 해결 후 READ THE BACK → BACK TO THE STUDIO → CONTINUE INVESTIGATION.
**필요한 단서**
- THE PAINTED STREET(빨간 문 아님), THE ARTIST'S NOTES(파란 하늘), THE HIDDEN SKETCH(계단·램프·검은 문)
**힌트**
- "Check each canvas against all three clues." / "No red door. A blue sky. A black gate beside the steps."

<a id="s2-c03"></a>

### Case 03 — The Tower's Secret
- 장소: EIFFEL TOWER · PARIS  ·  미션 수: 3 + Final
- [Mission 1](#s2-c03-m1) · [Mission 2](#s2-c03-m2) · [Mission 3](#s2-c03-m3) · [Final](#s2-c03-final)
- [↑ Season 2 목차](#s2) · [↑ 맨 위](#top)

<a id="s2-c03-m1"></a>

#### Mission 1 — The Two Notices
**목표**
- 방문객 공지와 정비 기록에서 서로 다른 줄을 찾는다.
**퍼즐 유형**
- 문서 비교 (matchPairs, 양쪽 문서에서 한 줄씩 선택)
**정답**
- `time:time` = VISITOR NOTICE의 `TIME 4:00 PM` + MAINTENANCE LOG의 `TIME 3:00 PM`
- DATE(12 MAY)와 JOB(LIFT INSPECTION)은 양쪽 동일.
**풀이 방법**
1. INVESTIGATE → 방문객 공지가 열려 있음. 탭(record-tab)으로 MAINTENANCE LOG로 전환해 두 문서를 모두 읽기(둘 다 읽어야 확인 버튼 등장).
2. 공지에서 TIME 줄 탭, 로그로 전환해 TIME 줄 탭.
3. THESE DO NOT MATCH.
**필요한 단서**
- 두 기록 (공지 4:00 PM / 로그 3:00 PM)
**힌트**
- "Read each record line by line: the date, the job, the time." / "The date and the job are the same on both. What about the time?"

<a id="s2-c03-m2"></a>

#### Mission 2 — The Lift That Stopped
**목표**
- 승강기 운행 기록의 3:20 행선지(S)를 노선판과 대조해 찾는다.
**퍼즐 유형**
- 문서 대조 + 객관식
**정답**
- `Service Level` (option `service`)
**풀이 방법**
1. INVESTIGATE → 오른쪽 벽의 lift log 탭(3:20 Second → ?, S 표시) → 닫기.
2. 왼쪽 벽의 brass route plate 탭(S = SERVICE RUN, SERVICE LEVEL은 Second에서만 갈라지는 서비스 노선) → 닫기. 둘 다 읽어야 CHECK 등장.
3. 정류장 버튼 중 `Service Level` 선택 → CHECK.
**필요한 단서**
- M1 단서 CHECK THE LIFT LOG, LIFT LOG — 12 MAY, 노선판 범례 "S = SERVICE RUN"
**힌트**
- "Find the S in the lift log. Then find what S means on the route plate." / "S = SERVICE RUN. Which stop is only on the service route?"

<a id="s2-c03-m3"></a>

#### Mission 3 — Behind the Iron Door
**목표**
- 점검 순서 메모대로 자물쇠 다이얼 3개를 맞춘다.
**퍼즐 유형**
- 순서 맞추기 (다이얼 자물쇠)
**정답**
- `clock,lift,key` = 다이얼1 CLOCK, 다이얼2 LIFT, 다이얼3 KEY
**풀이 방법**
1. INVESTIGATE → TAP TO OPEN(INSPECTION STEPS 메모) → SOLVE THE PUZZLE.
2. 시작 상태는 KEY / CLOCK / LIFT. 다이얼은 탭할 때마다 CLOCK → KEY → LIFT → CLOCK 순으로 넘어감(드래그 회전도 가능).
   - 다이얼1: 2번 탭 (KEY→LIFT→CLOCK)
   - 다이얼2: 2번 탭 (CLOCK→KEY→LIFT)
   - 다이얼3: 2번 탭 (LIFT→CLOCK→KEY)
3. OPEN THE LOCK.
**필요한 단서**
- 메모: "Finally, turn the key. / First, check the clock. / Next, stop the lift."
**힌트**
- "FIRST, NEXT and FINALLY tell you the order." / "Dial 1 is what you do FIRST. Dial 2 is NEXT. Dial 3 is FINALLY."

<a id="s2-c03-final"></a>

#### Final — The Missing Hour
**목표**
- 질문 3개에 맞는 증거를 연결하고 결론을 고른다.
**퍼즐 유형**
- 증거 연결 + 결론 선택 (EvidenceBoard)
**정답**
- `q1:e1,q2:e2,q3:e2+e3,why:entered`
  - Q1 What was wrong with the inspection records? → The Conflicting Notices
  - Q2 Where did the lift go? → The Lift Log
  - Q3 What shows that someone went into the service area? → The Lift Log + The Service Room (둘 다)
  - 결론: "Someone went into the service area in the hour the records do not agree on." (`entered`)
- 오답 결론: "An hour really vanished from Paris."(증거 없음), "The lift never moved."
**풀이 방법**
1. 질문 카드 탭 → 해당 증거 카드 탭(Q3는 두 장 모두) — 세 질문 반복.
2. 결론 3개 중 위 `entered` 문장 선택.
3. SOLVE THE CASE(모든 질문 연결 전 비활성) → 해결 후 LOOK INSIDE → BACK TO THE ROOM → CONTINUE INVESTIGATION.
**필요한 단서**
- M1 The Conflicting Notices, M2 The Lift Log, M3 The Service Room
**힌트**
- "Open each piece of evidence. What does each one show?" / "Question 3 needs two pieces: where the lift went, and what was behind the door."

<a id="s2-c04"></a>

### Case 04 — The River's Secret
- 장소: SEINE QUAYS · PARIS  ·  미션 수: 3 + Final
- [Mission 1](#s2-c04-m1) · [Mission 2](#s2-c04-m2) · [Mission 3](#s2-c04-m3) · [Final](#s2-c04-final)
- [↑ Season 2 목차](#s2) · [↑ 맨 위](#top)

<a id="s2-c04-m1"></a>

#### Mission 1 — Three Waves
**목표**
- 명판 뒷면의 세 줄 조건을 모두 만족하는 강둑 벽 표식을 고른다.
**퍼즐 유형**
- 객관식 (장면 비교)
**정답**
- `MARK D` (option `d`): 물결 3개, 화살표 아래(강 쪽), RIVER KEEPER
- 오답: A = 화살표가 위(2번 줄 위반), B = BOOKSELLERS(3번 줄), C = 물결 2개(1번 줄).
**풀이 방법**
1. INVESTIGATE → (선택) 벽의 표식이나 카드의 돋보기로 확대해 물결 수·화살표·단어 확인, "See the plaque"로 명판 앞/뒤 확인.
2. 아래 THE FOUR MARKS 카드 중 MARK D 탭 → THIS IS THE MARK.
3. 정답 이유 3줄 표시 후 계속 버튼 → 해결.
**필요한 단서**
- Case 03 명판 뒷면: "Three waves mark the place. / Follow the arrow towards the river. / Find the one who watches the water."
**힌트**
- "Read one line at a time." / "How many waves? Where does the arrow point? Who does it name?"

<a id="s2-c04-m2"></a>

#### Mission 2 — The River Keeper
**목표**
- 관리인 장부에서 탑에서 온 상자가 지금 있는 보관함을 찾는다.
**퍼즐 유형**
- 문서 읽기 + 선택 (장부의 Box 번호에 동그라미)
**정답**
- `Box 23` (option `box23`)
- 근거: 13 MAY Eiffel Tower 무거운 상자 Quay 3 Box 17 → 14 MAY Box 17 moved to Box 23.
**풀이 방법**
1. INVESTIGATE → 오두막 열린 문 탭 → 책상 위 장부 탭.
2. 1쪽(BOXES IN AND MOVED) 마지막 줄 "14 MAY Box 17 moved to **Box 23**"의 Box 23 탭(동그라미) → THIS IS THE BOX.
3. 정답 후 TURN THE PAGE → 2쪽(BOXES COLLECTED)에서 "15 MAY Box 23 — collected for No. 7" 줄의 Box 23 탭(찾아야 계속 버튼 활성) → 계속.
**필요한 단서**
- M1 River Mark의 QUAY 3, Case 03 끝의 운송 꼬리표(TO: THE RIVER)
**힌트**
- "Find the things from the Eiffel Tower. Which one is on Quay 3?" / "Find that box again lower down the page. What happened on 14 May?"

<a id="s2-c04-m3"></a>

#### Mission 3 — The Hidden Message
**목표**
- Box 23을 열고 찢어진 배송표 조각을 위·가운데·아래에 맞춘다.
**퍼즐 유형**
- 장면 탐색 + 조각 맞추기 (matchPairs)
**정답**
- `p1:top,p2:middle,p3:bottom` (순서 무관)
  - 위: 놋쇠 끈구멍(eyelet) 조각 (PARIS PARCEL SERVICE / FROM: EIFFEL TOWER)
  - 가운데: CONTENTS: CLOCK PARTS 조각
  - 아래: TO: THE WATCHMAKERS 조각
- 파란 회색 얇은 조각(decoy, "TO: BOOKSTALL 12 / QUAY 1")은 어디에도 넣지 않음.
**풀이 방법**
1. INVESTIGATE → 초록 상자 중 Box 23(맨 오른쪽) 탭. (12·17·21은 비었거나 잠김 안내만)
2. 트레이 조각 탭 → 슬롯 탭(또는 드래그)으로 위 배치. 슬롯을 다시 탭하면 조각이 빠짐.
3. 세 슬롯이 다 차면 CHECK THE LABEL.
**필요한 단서**
- M2 장부(Box 23)
**힌트**
- "One scrap is a different paper: thin and blue-grey. Leave it out." / "Top to bottom: FROM, CONTENTS, TO. The eyelet piece goes at the top."

<a id="s2-c04-final"></a>

#### Final — The Watchmaker's Address
**목표**
- 거리 책의 주소 4개 중 틀린 3개를 증거로 지우고 남은 주소를 제출한다.
**퍼즐 유형**
- 소거 추론 + 증거 연결 (주소마다 증거 1~2개)
**정답**
- `quai:e3,pont:e1+e2,horloge:e2` → 남는 주소 `PASSAGE DES HORLOGERS`
  - QUAI DE L'HORLOGE ← The Torn Delivery Label (주소가 PASSAGE로 시작)
  - PASSAGE DU PONT ← The River Mark + The Keeper's Ledger (관리인 계단은 Quay 3, 배달은 그 계단으로 / 이 문은 Quay 1)
  - PASSAGE DE L'HORLOGE ← The Keeper's Ledger (No. 7인데 집 번호 1~5)
- 증거 조합이 정확히 위와 같아야 함(더 많거나 적으면 오답 피드백). 최대 2개.
**풀이 방법**
1. 거리 책 1쪽에서 주소 탭 → 증거 카드 선택 → CROSS IT OUT (지울 때마다 즉시 판정, 틀리면 TRY AGAIN).
2. 1쪽: QUAI DE L'HORLOGE(e3), PASSAGE DU PONT(e1+e2). 2쪽으로 넘겨 PASSAGE DE L'HORLOGE(e2).
3. "One address is left." → THIS IS THE ADDRESS → LOOK AT THE GATE → 다음(gate-next) 3번 → CONTINUE INVESTIGATION.
**필요한 단서**
- M1 The River Mark(QUAY 3), M2 The Keeper's Ledger(No. 7, 관리인 계단 배달), M3 The Torn Delivery Label(PASSAGE D…)
**힌트**
- "Read each address: its name, its house numbers and its gate." / "Each wrong address breaks one clue: the label's start, the ledger's house number, or the keeper's steps."

<a id="s2-c05"></a>

### Case 05 — The Silent Workshop
- 장소: PASSAGE DES HORLOGERS · No. 7  ·  미션 수: 3 + Final
- [Mission 1](#s2-c05-m1) · [Mission 2](#s2-c05-m2) · [Mission 3](#s2-c05-m3) · [Final](#s2-c05-final)
- [↑ Season 2 목차](#s2) · [↑ 맨 위](#top)

<a id="s2-c05-m1"></a>

#### Mission 1 — The Maker's Mark
**목표**
- 작업대 위 도장 4개 중 제작자 진짜 표식(두 시곗바늘)을 찾는다.
**퍼즐 유형**
- 장면 비교 (트레이싱지 겹쳐 보기) + 객관식
**정답**
- `D · THE SMALL DRAWER` (option `d`)
- 오답: A 공구함 = 긴 바늘 끝 모양 다름, B 부품 깡통 = 짧은 바늘 위치 어긋남, C 시계 케이스 = 바늘 하나뿐.
**풀이 방법**
1. INVESTIGATE → 도장 4개(A~D)를 각각 탭해 확대 → LAY THE SHEET ON IT(또는 트레이싱지를 도장 위로 드래그) → 닫기. 4개 모두 겹쳐 봐야 선택 잠금 해제.
2. D · THE SMALL DRAWER 선택 → THIS IS THE MARK.
**필요한 단서**
- 작업대 쪽지 "My mark is on everything I make. A copy is never the same.", Case 04 장부의 두 시곗바늘 서명
**힌트**
- "Lay the tracing sheet over each stamp. Look at the lines, not the colour." / "Count the hands. See where the short hand sits. Check each tip."

<a id="s2-c05-m2"></a>

#### Mission 2 — The Clocks That Lie
**목표**
- 1분 동안 시계를 관찰하고 뒷면을 보아, 거꾸로 가고 바퀴가 추가된 시계를 찾는다.
**퍼즐 유형**
- 관찰 + 객관식
**정답**
- `Clock III` (option `iii`): 10:40 → 10:39 (거꾸로), 뒷면에 작은 황동 바퀴 추가
- 참고: I 3:10→3:11, II 7:25→7:30(빠름, 새 스프링), IV 1:55 정지(추 고리 부러짐).
**풀이 방법**
1. INVESTIGATE → WATCH THE CLOCKS (약 6초 재생 후 ONE MINUTE LATER…, 각 시계에 now 시각 표시). 보기 전엔 선택 잠김.
2. (권장) 시계를 탭해 뒷면 확인 — III: "A small brass wheel at the side of the gears."
3. Clock III 선택 → THIS IS THE CLOCK.
**필요한 단서**
- M1 The Repair Card: "I added one small wheel. Now its hands turn the wrong way."
**힌트**
- "Watch the clocks for one minute. Read each time before and after." / "Find the clock with both: a wheel added, and hands that turn the wrong way."

<a id="s2-c05-m3"></a>

#### Mission 3 — The Blotted Page
**목표**
- 압지에 거꾸로 찍힌 쪽지 3장을 거울로 읽고, 진짜 표식이 있는 쪽지가 가리키는 곳을 고른다.
**퍼즐 유형**
- 거울 읽기(장면 조작) + 객관식
**정답**
- `Clock III` (option `clock3`) — 갈색 쪽지 "The letter is ready. I hid it in the clock that turns back."(진짜 표식)
- 오답: The post box at the corner(파란 쪽지, 표식 없음), The tin of springs(검은 쪽지, 바늘 하나 = 가짜), The desk drawer(어느 쪽지에도 없음).
**풀이 방법**
1. INVESTIGATE → 손거울을 압지의 각 쪽지(파랑·검정·갈색) 위로 드래그(또는 쪽지 탭). 세 장 모두 읽어야 확인 버튼 등장.
2. 장소 선택지 중 `Clock III` 선택 → THIS IS WHERE.
3. Clock III 내부(봉투 귀퉁이 + 영수증 LETTER No. 4417) 표시 → 계속.
**필요한 단서**
- M1 제작자 표식, M2 The Backward Clock(거꾸로 가는 시계 = Clock III)
**힌트**
- "Hold the mirror over each note. Then look at the mark under it." / "The maker's own note says: the clock that turns back. Which clock is that?"

<a id="s2-c05-final"></a>

#### Final — The Letter's Trail
**목표**
- 우편 전표 5장 중 편지 No. 4417의 전표 3장을 시간순으로 놓는다.
**퍼즐 유형**
- 증거 선별 + 순서 맞추기 (matchPairs, 슬롯 1st/2nd/3rd)
**정답**
- `first:s1,second:s2,third:s3`
  - 1st: COLLECTED · PASSAGE BOX (4417, 16 MAY 9:00 AM)
  - 2nd: SORTED · CENTRAL OFFICE (4417, 11:00 AM)
  - 3rd: HELD · LOUVRE POST ROOM (4417, 4:00 PM)
- 제외: COLLECTED · CORNER BOX(No. 4471), DELIVERED · RUE DU BAC(3 MAY, No. 2903).
**풀이 방법**
1. 전표 탭(크게 보기) → 위의 슬롯 1st/2nd/3rd 탭 — 세 장 배치.
2. FOLLOW THE LETTER → CONTINUE INVESTIGATION.
**필요한 단서**
- M3 영수증 "16 MAY — ONE LETTER COLLECTED FROM No. 7. LETTER No. 4417"
**힌트**
- "Look at the letter number on each slip. Is it the same as on the receipt?" / "Three slips are for letter No. 4417. Put them in time order."

<a id="s2-c06"></a>

### Case 06 — The Letter That Never Arrived
- 장소: LOUVRE POST ROOM  ·  미션 수: 3 + Final
- [Mission 1](#s2-c06-m1) · [Mission 2](#s2-c06-m2) · [Mission 3](#s2-c06-m3) · [Final](#s2-c06-final)
- [↑ Season 2 목차](#s2) · [↑ 맨 위](#top)

<a id="s2-c06-m1"></a>

#### Mission 1 — Find Letter 4417
**목표**
- 우편실 보관 선반(hold rack)의 꼬리표 4개 중 Letter 4417의 것을 찾는다.

**퍼즐 유형**
- 장면 탐색 + 객관식 (꼬리표를 탭해 앞/뒷면 읽기)

**정답**
- `Tag D` (option `d`) — 선반 **아래 줄 맨 왼쪽**에 걸린 꼬리표.
- 앞면 `LETTER No. 4?17`(잉크로 한 자리 가려짐), 뒷면 `16 MAY · 4:00 PM · HELD · PRESERVATION ORDER · Keep it safe.`

**풀이 방법**
1. INVESTIGATE → 선반의 꼬리표를 탭해 확대 (A·B·C는 위쪽 줄, D는 아래 줄 왼쪽).
2. `TURN IT OVER`로 뒷면 확인 (C·D는 앞면 번호가 잉크로 가려져 뒷면으로만 구별).
3. Tag D를 연 상태에서 `THIS IS THE TAG`.

**필요한 단서**
- Case 05의 Letter's Trail 세 번째 쪽지: `LETTER No. 4417 · 16 MAY · 4:00 PM · HELD · LOUVRE POST ROOM` (선반 옆에 표시됨).
- 오답 구별: A = `PARCEL` 4417, B = 번호 `4471`, C = 뒷면 `15 MAY · 11:00 AM`.

**힌트**
- "Read each tag's front. Is it a LETTER? Is the number 4417?" / "Ink hides a number on two tags. Turn them over."

<a id="s2-c06-m2"></a>

#### Mission 2 — Follow the Letter
**목표**
- 짐꾼 메모(계단 → 조각상 지나 → 왼쪽 두 번째 문)대로 편지가 지나간 문을 찾는다.

**퍼즐 유형**
- 장면 탐색(평면도 위 한 걸음씩 이동) + 객관식

**정답**
- `Door E` (option `e`) — 조각상을 지난 뒤 **왼쪽 두 번째** 문 (평면도 맨 위쪽 왼편).

**풀이 방법**
1. INVESTIGATE → 평면도에서 **계단**을 탭 (안 하면 "Go down the stairs first.").
2. **조각상**을 탭 (안 하면 "Walk past the statue first.").
3. 왼쪽 위 문 **E**를 탭 → `GO THROUGH DOOR E`.
- 진행(계단/조각상 도달)은 저장되어 재진입 시 유지됨.

**필요한 단서**
- 짐꾼 메모: "Go down the stairs. Walk past the statue. Take the second door on the left."
- 오답: A/B = 조각상 전 문, C = 조각상 뒤 왼쪽 첫 번째, D/F = 오른쪽.

**힌트**
- "Move one step at a time: the stairs first, then the statue." / "After the statue, count only the doors on the left: one, two."

<a id="s2-c06-m3"></a>

#### Mission 3 — The Hidden Envelope
**목표**
- 기록 보관실 서랍에서 올바른 서랍을 열고, Clock III의 찢어진 모서리가 맞는 봉투를 찾는다.

**퍼즐 유형**
- 장면 탐색 + 드래그(조각 맞추기)

**정답**
- 서랍: `LETTERS 4400–4599` (캐비닛 **왼쪽 아래**, id `l4400`).
- 봉투: `Envelope 2` (option `y`, 서랍 안 가운데 봉투).

**풀이 방법**
1. INVESTIGATE → 캐비닛 라벨을 읽고 `LETTERS 4400–4599` 서랍 탭. (오른쪽 위 `PARCELS 4400–4599`는 "This drawer is for parcels.", 나머지는 번호 범위 불일치.)
2. 열린 서랍에서 **Envelope 2** 탭.
3. 찢어진 모서리를 봉투 위로 드래그하거나 `LAY THE CORNER ON IT` → "It fits!" 로 정답 처리.
4. `LOOK AT THE SEAL` → 봉인 확인 후 `CONTINUE` (이후 Discovery 진행).

**필요한 단서**
- Case 05 Clock III의 찢어진 봉투 모서리 (라벨 `No. 4417`).

**힌트**
- "Find the drawer first. Is it for letters? Is 4417 between its two numbers?" / "Lay the torn corner on each envelope. Only one torn edge fits."

<a id="s2-c06-final"></a>

#### Final — The Secret in the Letter
**목표**
- 편지의 그림(돔, 지붕 위 조각상, 아치 창)과 "the show remembers"에 맞는 건물을 파리 지도에서 고른다.

**퍼즐 유형**
- 지도 선택(건물 확대 후 선택)

**정답**
- `Palais Garnier` (option `palaisGarnier`) — 지도 중앙 위쪽(루브르 북서쪽)의 오페라 하우스.

**풀이 방법**
1. (선택) 편지의 그림을 탭해 크게 보기 → 닫기.
2. 지도에서 **Palais Garnier**를 탭해 확대 → `THIS IS THE BUILDING`.
3. 정답 시 편지가 뒤집혀 `OPERA ARCHIVE · FILE 3–4`가 보인다.

**필요한 단서**
- 편지 문장 "The clocks may lie. But the show remembers." + 봉인/스케치의 건물.
- 오답: Montmartre(지붕 조각상 없음), Louvre(이미 여기), Arc de Triomphe(아치), Gare du Nord(역), Notre-Dame(두 탑), Eiffel Tower.

**힌트**
- "Look at the roof in the drawing. What shape is it? What stands on it?" / "Where do people go to see a show?"

---

<a id="s2-c07"></a>

### Case 07 — The Phantom Performance
- 장소: PALAIS GARNIER  ·  미션 수: 3 + Final
- [Mission 1](#s2-c07-m1) · [Mission 2](#s2-c07-m2) · [Mission 3](#s2-c07-m3) · [Final](#s2-c07-final)
- [↑ Season 2 목차](#s2) · [↑ 맨 위](#top)

<a id="s2-c07-m1"></a>

#### Mission 1 — The Show Strip
**목표**
- 2시간 10분짜리 공연 띠를 시계 위에서 밀어, 문이 열린(3:30) 뒤 시작하고 CURTAIN DOWN(6:10)에 끝나는 시작 시각을 찾는다.

**퍼즐 유형**
- 슬라이드(시간 띠 맞추기) → CHECK로 판정

**정답**
- `START 4:00 PM · END 6:10 PM` (option `fit`, "Start at 4:00, end at 6:10").
- 띠의 초기값은 3:00(10분 단위 이동). 판정은 띠 위치로 자동 결정: 3:00 = `office`, 3:30 이전 = `early`, 그 외 = `end`.

**풀이 방법**
1. INVESTIGATE → (선택) FILE 3 / FILE 4 탭해 읽기 → `BACK TO THE TABLE`.
2. 띠를 오른쪽으로 드래그하거나 "10분 뒤(Ten minutes later)" 화살표 버튼을 **6번** → 표시 `START 4:00 PM`, `END 6:10 PM`.
3. `CHECK`.

**필요한 단서**
- FILE 3: DOORS OPEN 3:30 · CURTAIN UP 3:00 · CURTAIN DOWN 6:10 / FILE 4: 10+60+20+40분 = 2시간 10분.

**힌트**
- "The show strip can't get shorter or longer." / "Put the END flag on the CURTAIN DOWN pin."

<a id="s2-c07-m2"></a>

#### Mission 2 — The Ghost Light
**목표**
- 조명 레버로 무대를 옛 사진("3:00 PM · CURTAIN UP!")과 똑같이 밝힌다.

**퍼즐 유형**
- 장면 조작(레버 4개 ON/OFF) → 사진과 비교

**정답**
- **GHOST LIGHT만 ON**, HOUSE LIGHTS·FOOTLIGHTS·BIG SPOT은 OFF (option `match`). 시작 시 모두 OFF.
- 다른 조합은 첫 번째로 다른 조명 기준으로 오답 피드백(`ghostOff`/`house`/`foot`/`spot`).

**풀이 방법**
1. INVESTIGATE → (선택) 옛 사진, THE LIGHTING BOOK 탭해 읽기.
2. 첫 번째 레버(GHOST LIGHT)를 탭(또는 위로 밀기)해 ON.
3. `IT MATCHES THE PHOTO`.
4. 정답 후: 책의 **큐 카드**(SHOW No. 34 · CUE 1 · CURTAIN UP · 4:00) 탭 → 닫기 → **쪽지(scrap)** 탭 → 닫기 → `CONTINUE` (카드→쪽지 순서 필수).

**필요한 단서**
- Lighting Book: "GHOST LIGHT: one lamp on an empty stage."

**힌트**
- "Look at the photo. How many lights are on?" / "Read the Lighting Book. Which light is for an empty stage?"

<a id="s2-c07-m3"></a>

#### Mission 3 — The Painted Sky
**목표**
- 밧줄 레일의 배경막 4개 중 Painted Street(빨간 문 바로 위 작은 시계)와 같은 것을 찾는다.

**퍼즐 유형**
- 장면 조작(밧줄 당기기) + 객관식

**정답**
- `Backdrop 3` (option `clockRed`) — **3번 밧줄**: 빨간 문 + 바로 위 작은 둥근 시계.

**풀이 방법**
1. INVESTIGATE → 밧줄 3을 탭(또는 아래로 당김) → 배경막 3이 내려옴.
2. `THIS ONE!` (확대 화면에서도 같은 버튼).
3. 배경막 뒷면의 **주머니(pocket)** 탭 → Amendment Slip 확인 → `CONTINUE`.

**필요한 단서**
- Case 02 증거 The Painted Street: "Above the red door: a small clock." (화면에 함께 표시)
- 오답: 1 = 문 위 램프, 2 = 문 위는 비고 멀리 시계탑, 4 = 파란 문.

**힌트**
- "Open your notebook: The Painted Street. Two things must match." / "Lower each backdrop. Each time, look right above the door."

<a id="s2-c07-final"></a>

#### Final — The Changed Record
**목표**
- 바뀐 기록(FILE 3)을 찾아 라이트 테이블에서 패치 아래 옛 시각을 드러내고, 슬립의 두 시각을 핀으로 연결한다.

**퍼즐 유형**
- 복합 (기록 선택 → 드래그 배치 → 스위치 → 핀 연결)

**정답**
- 데이터 `old:under,new:patch` (순서 무관):
  - 슬립의 `4:00`(옛 시각) 핀 → CURTAIN UP 줄 **패치 위로 비쳐 보이는 4:00 PM**(불 켠 뒤에만 보임).
  - 슬립의 `3:00`(새 시각) 핀 → **패치 위에 쓰인 3:00 PM**.

**풀이 방법**
1. 상자의 **FILE 3** 탭 (FILE 4는 "agree on 4:00" 오답).
2. FILE 3을 유리판으로 드래그하거나 `PUT IT ON THE TABLE`.
3. 오른쪽 **조명 스위치** 탭(불 켜기) → 슬립 핀이 나타남.
4. `4:00` 핀 탭 → FILE 3의 패치 위 비친 4:00 PM 탭 (드래그도 가능).
5. `3:00` 핀 탭 → 패치의 3:00 PM 탭 → 정답.
6. `TURN THE SLIP OVER` → 뒷면(ABBESSES, P. KNEW THE BAG.) 확인 → `BACK TO THE TABLE` → 이후 CONTINUE INVESTIGATION (뒷면 확인 전엔 다음으로 못 감).

**필요한 단서**
- Amendment Slip (M3): FILE 3 · CURTAIN UP: 4:00 to 3:00. 큐 카드(M2) 4:00.

**힌트**
- "Which line has an extra piece of paper?" / "Turn on the light. The old time is under the patch."

---

<a id="s2-c08"></a>

### Case 08 — The Painter's Last Sketch
- 장소: ABBESSES · MONTMARTRE  ·  미션 수: 3 + Final
- [Mission 1](#s2-c08-m1) · [Mission 2](#s2-c08-m2) · [Mission 3](#s2-c08-m3) · [Final](#s2-c08-final)
- [↑ Season 2 목차](#s2) · [↑ 맨 위](#top)

<a id="s2-c08-m1"></a>

#### Mission 1 — The Hidden Sketch
**목표**
- 광장의 세 모퉁이 중 화가가 앉아 그린 곳(Hidden Sketch와 같은 곳)을 고른다.

**퍼즐 유형**
- 장면 탐색 + 객관식 (선택지 이름 숨김, 그림으로만 비교)

**정답**
- `CORNER 2` (option `corner2`) — **가운데** 모퉁이: 계단 왼쪽, 램프가 문 왼쪽, **검은** 문.

**풀이 방법**
1. INVESTIGATE → 상단 탭 `CORNER 2`(또는 광장 그림의 가운데 모퉁이) 탭.
2. (선택) 그림을 탭해 확대, 하단 증거 카드 "These steps look familiar..."에서 **The Hidden Sketch**(Case 02, `s2_ep02_e3`)를 불러와 비교 — 판정에는 필수 아님.
3. `THIS CORNER!`.

**필요한 단서**
- Case 02 The Hidden Sketch (램프가 문 왼쪽 + 글로 "검은 문").
- 오답: Corner 1 = 짙은 초록 문, Corner 3 = 계단·램프가 오른쪽.

**힌트**
- "Bring the painter's hidden sketch from your notebook." / "Check where the lamp stands. The sketch has no colours, so read its words."

<a id="s2-c08-m2"></a>

#### Mission 2 — The Morning Drawing
**목표**
- 세 그림을 시간 순서로 놓고 겹쳐 보아 달라진 점을 찾은 뒤, 계단의 종이가 어디서 왔는지 답한다.

**퍼즐 유형**
- 순서 맞추기 → 겹쳐 비교(달라진 곳 탭) → 객관식

**정답**
- 순서: `FIRST` = DRAWING B(어두운 하늘·별), `NEXT` = DRAWING C(가방 든 사람), `LAST` = DRAWING A(램프 꺼짐, 계단 위 종이). (테이블 초기 배치 A=light, B=dark, C=bag)
- 질문 정답: `It fell from the bag.` (option `bag`).

**풀이 방법**
1. INVESTIGATE → 그림 카드 탭 → 슬롯(FIRST/NEXT/LAST) 탭으로 배치 → `CHECK THE ORDER` (순서 오류는 오답 카운트 없음).
2. 겹친 그림(DRAWING 1·2)에서 슬라이더로 비교하며 **사람(가방)**, **열린 문**, **오른쪽 여백의 작은 그림(배지)** 3곳 탭 → `NEXT TWO DRAWINGS`.
3. DRAWING 2·3에서 **꺼진 램프**, **사라진 사람**, **계단 위 종이**, **오른쪽 여백의 작은 그림** 4곳 탭.
4. 질문에서 `It fell from the bag.` → `CHECK ANSWER`.

**필요한 단서**
- P.의 꼬리표: 어두운 하늘 → 밝아짐 → 해 뜨면 램프 꺼짐.

**힌트**
- "Read P.'s tag. Dark sky first. When the sun comes up, the lamps go out." / "Look at who was on the steps just before."

<a id="s2-c08-m3"></a>

#### Mission 3 — The Purple Seal
**목표**
- 접힌 종이를 펴고, 오페라 슬립과 같은 부분 4개와 빠진 부분 2개를 표시한다.

**퍼즐 유형**
- 증거 비교(종이 위 영역 탭, SAME/MISSING 모드)

**정답**
- 데이터 `same:border,same:band,same:arrow,same:seal,missing:number,missing:hour` (순서 무관).
  - SAME: 왼쪽 **이중 테두리**, 위쪽 **FILE 띠**, 두 시각 사이 **화살표**, 오른쪽 아래 **보라색 도장**.
  - MISSING: FILE 바로 오른쪽(찢긴 V 안) **FILE 번호**, `:00` 바로 왼쪽 **시(hour)**.
- 도장은 확대 창에서 `How many hands?` → **None**, `What is around the clock?` → **Leaves** 후 `IT IS THE SAME SEAL`을 눌러야 SAME으로 표시됨.

**풀이 방법**
1. INVESTIGATE → 접힌 종이를 **3번** 탭해 펼치기.
2. (선택) 증거 카드에서 The Amendment Slip(Case 07) 불러오기.
3. `SAME` 모드에서 테두리·FILE 띠·화살표 탭, 도장 탭 → None / Leaves → `IT IS THE SAME SEAL`.
4. `MISSING` 모드로 바꿔 FILE 번호 자리, 시 자리 탭.
5. `CHECK`. (접힌 선·오른쪽 찢긴 가장자리·먼지는 오답 아님, 설명만 나옴)

**필요한 단서**
- Case 07 The Amendment Slip (FILE 3, 4:00 → 3:00, 바늘 없는 시계 + 잎사귀 도장).

**힌트**
- "Bring the opera slip from your notebook." / "Count the seal's hands. Then compare FILE and the times on both papers."

<a id="s2-c08-final"></a>

#### Final — The Torn Hour
**목표**
- 찢긴 종이를 그림 3 여백의 종이와 맞춘 뒤, 증거 보드에서 질문별 증거와 결론을 고른다. 이후 P.의 마지막 그림으로 다음 장소를 찾는다.

**퍼즐 유형**
- 회전·배치 → 증거 연결 보드 → (사건 종료 단계) 그림 탐색 + 지도 선택

**정답**
- 데이터 `q1:e2,q2:e3+e4,why:fell`:
  - Q1 `Where did the paper come from?` → **The Bag Sketch** (e2) 하나만.
  - Q2 `What kind of paper is it?` → **The Matching Seal** (e3) + **The Amendment Slip** (e4).
  - 결론 → `A paper for changing a time fell from the bag.` (`fell`)
- 종료 단계: 가방 3부분(flat bag, 두 버클, 방패 배지) 탭, 지도 정답 `Luxembourg Gardens`.

**풀이 방법**
1. 종이는 거꾸로(V가 아래) 시작 → `TURN IT` **2번** (V가 위) → `LAY IT ON THE DRAWING`(또는 여백으로 드래그). 배치 실수는 오답 카운트 없음.
2. 보드: 질문 Q1 탭 → The Bag Sketch 탭 / 질문 Q2 탭 → The Matching Seal, The Amendment Slip 탭.
3. 결론 `A paper for changing a time fell from the bag.` 탭 → `SOLVE THE CASE`.
4. `LOOK AT HIS LAST DRAWING` → 그림에서 가방 본체·버클·배지 3곳 탭 (둥근 바구니는 오답 설명).
5. 지도에서 **Luxembourg Gardens** 탭 → `THE GARDEN IS HERE` → `CONTINUE`. 이 단계까지 끝내야 사건 종료(CASE SOLVED).

**필요한 단서**
- M2 The Bag Sketch, M3 The Matching Seal, Case 07 The Amendment Slip(보드에 자동 제공), The Painter's Spot(오답용).

**힌트**
- "First, turn the paper until its V-shaped tear matches the drawing." / "Which evidence shows where the paper came from? Which ones show what kind of paper it is?"

---

<a id="s2-c09"></a>

### Case 09 — The Clockwork Garden
- 장소: LUXEMBOURG GARDENS  ·  미션 수: 3 + Final
- [Mission 1](#s2-c09-m1) · [Mission 2](#s2-c09-m2) · [Mission 3](#s2-c09-m3) · [Final](#s2-c09-final)
- [↑ Season 2 목차](#s2) · [↑ 맨 위](#top)

<a id="s2-c09-m1"></a>

#### Mission 1 — The Little Paris
**목표**
- 작은 시계 3개를 받침의 파리 지도에서 제자리에 놓는다.

**퍼즐 유형**
- 드래그 매칭(지도 배치)

**정답**
- 데이터 `t1:arcDeTriomphe,t2:seineQuays,t3:artsEtMetiers`:
  - T1(아치, 받침에 별) → **Arc de Triomphe** (지도 왼쪽 위)
  - T2(아치 3개 다리, 초록 책 가판대) → **Seine Quays** (노트르담 서쪽 강가)
  - T3(뾰족탑 하나, 받침에 종) → **Arts et Métiers** (오른쪽 중간, 강 북쪽)

**풀이 방법**
1. INVESTIGATE → 각 시계를 지도 위 장소로 드래그 (또는 시계 탭 → 지도 장소 탭).
2. 틀린 장소는 상자로 돌아가고 설명만 나옴(오답 카운트 없음). 세 개 모두 놓으면 자동 정답.

**필요한 단서**
- 각 모형의 모양(아치/다리/뾰족탑).

**힌트**
- "Look at each clock's shape." / "T1 is an arch. T2 is a bridge. T3 is a tall spire."

<a id="s2-c09-m2"></a>

#### Mission 2 — The Gear Path
**목표**
- 빠진 톱니 2개를 점선 원에 끼워 탑과 시험 시계들을 연결한다.

**퍼즐 유형**
- 드래그 매칭(크기 맞추기)

**정답**
- 데이터 `slot1:big,slot2:small`: **큰 톱니 → T1 옆(위쪽) 점선 원**, **작은 톱니 → T2·T3 옆(아래쪽) 점선 원**.

**풀이 방법**
1. INVESTIGATE → 아래 쟁반의 큰 톱니를 위쪽 점선 원으로 드래그 ("One more gear!").
2. 작은 톱니를 아래쪽 점선 원으로 드래그 → T1·T2·T3이 돌고 GARDEN 시계는 멈춤 → 자동 정답.
- 크기가 틀리면 "Too big!/Too small!"로 쟁반 복귀(오답 카운트 없음).

**필요한 단서**
- 없음(보드 자체).

**힌트**
- "Look at the dotted circles." / "The big gear goes near T1. The small gear goes near T2 and T3."

<a id="s2-c09-m3"></a>

#### Mission 3 — The Maker's Marks
**목표**
- 수첩의 두 표식을 옛 설계도·수리 메모의 같은 표식과 연결한다.

**퍼즐 유형**
- 증거 연결(카드 탭 → 종이 위 표식 탭)

**정답**
- 데이터 `a:emblem,b:repair`:
  - `The Clockmaker's Mark`(톱니, Gare du Nord) → 설계도 오른쪽 아래 `CHRONOS TRIAL EMBLEM` 톱니.
  - `The Repair Card`(두 시계바늘, No. 7) → 수리 메모 첫 줄 `REPAIRS · T2 WHEEL` 옆 표식.
- 함정: 둘째 줄 `REPAIRS · T3 GLASS`의 열쇠 표식.

**풀이 방법**
1. INVESTIGATE → 카드 `The Clockmaker's Mark` 탭 → 설계도의 EMBLEM 톱니 탭.
2. 카드 `The Repair Card` 탭 → `REPAIRS · T2 WHEEL` 표식 탭 → 자동 정답 (오연결은 설명만, 카운트 없음).

**필요한 단서**
- Case 01 The Clockmaker's Mark(`s2_ep01_e3`), Case 05 The Repair Card(`s2_ep05_e1`).

**힌트**
- "Find the same shape on the old paper." / "The gear is on the plan. The two hands are on the repair note."

<a id="s2-c09-final"></a>

#### Final — The Wrong Hour
**목표**
- 탑 시계를 한 시간 뒤로 돌려 TEST한 뒤 결과를 해석하고, 별을 따라간다.

**퍼즐 유형**
- 시계 조작 → 객관식 → (사건 종료 단계) 모형 선택

**정답**
- 탑 시계: `4:00` → **`3:00`** (`1 HOUR BACK` 1번) 후 `TEST`.
- 질문 정답: `Only the joined clocks went wrong.` (option `connected`).
- 종료 단계: 별이 있는 모형 **T1** → Arc de Triomphe.

**풀이 방법**
1. `1 HOUR BACK` 1번 → `TEST` (5:00/2:00 등은 설명만, 오답 카운트 없음). T1·T2·T3 = 3:00, GARDEN = 4:00.
2. 질문에서 `Only the joined clocks went wrong.` → `CHECK ANSWER`.
3. `FOLLOW THE STAR` → 모형 **T1** 탭 → `CONTINUE` (사건 종료).

**필요한 단서**
- M2 Synchronisation Diagram(이어진 시계만 돈다), M1 Trial Map(T1 = 별).

**힌트**
- "One hour back: the short hand goes from 4 to 3." / "Which clocks changed? Which one stayed at four?"

---

<a id="s2-c10"></a>

### Case 10 — The Hour of Shadows
- 장소: ARC DE TRIOMPHE  ·  미션 수: 3 + Final
- [Mission 1](#s2-c10-m1) · [Mission 2](#s2-c10-m2) · [Mission 3](#s2-c10-m3) · [Final](#s2-c10-final)
- [↑ Season 2 목차](#s2) · [↑ 맨 위](#top)

<a id="s2-c10-m1"></a>

#### Mission 1 — The Drum Tape
**목표**
- T1이 15분마다 찍은 테이프에서 시간이 건너뛰는 두 곳을 찾는다.

**퍼즐 유형**
- 장면 탐색(테이프 당겨 표시 탭)

**정답**
- 데이터 `jump:t5,jump:t9`. 테이프: `2:00 · 2:15 · 2:30 · 2:45 · 2:00 · 2:15 · 2:30 · 2:45 · 4:00 · 4:15`
  - **5번째 표시 `2:00`** (2:45 → 2:00), **9번째 표시 `4:00`** (2:45 → 4:00).

**풀이 방법**
1. INVESTIGATE → 테이프를 오른쪽으로 드래그(또는 `PULL THE TAPE`)해 꺼내기.
2. 두 번째 `2:00`(5번째) 탭 → "One jump! Find one more."
3. `4:00` 탭 → "Two jumps!" 자동 정답. (정상 표시는 설명만, 카운트 없음)

**필요한 단서**
- 없음.

**힌트**
- "Each one should be fifteen minutes after the last." / "Look at what comes after each 2:45."

<a id="s2-c10-m2"></a>

#### Mission 2 — A City of Clocks
**목표**
- Roof Photo 2에서 시계 4개를 찾아 시험 시계/아닌 시계로 분류한다.

**퍼즐 유형**
- 돋보기 탐색 + 분류(카드 → 트레이)

**정답**
- 데이터 `t1:trial,cafe:not,church:not,post:not`:
  - `T1`(앞 왼쪽 기둥 위, 별) → **TRIAL CLOCK**
  - `Café`(가운데 카페 벽시계), `Church`(위쪽 교회탑), `Post office`(오른쪽 우체국 문 위) → **NOT A TRIAL CLOCK**

**풀이 방법**
1. INVESTIGATE → 돋보기를 끌거나 사진을 탭해 시계 4개 찾기 (`FOUND 4 / 4`; 해시계는 시계 아님).
2. 카드 탭 → 트레이 탭: T1 → TRIAL CLOCK, 나머지 3개 → NOT A TRIAL CLOCK. 4개 분류 시 자동 정답 (틀린 트레이는 설명만, 카운트 없음).

**필요한 단서**
- Case 09 Trial Map (시험 시계 표식: 별/아치 셋/종).

**힌트**
- "Move the glass over the photo. There are four clocks." / "Only T1 has the trial star."

<a id="s2-c10-m3"></a>

#### Mission 3 — The Hour of Shadows
**목표**
- 해시계 위 해를 움직여 Photo 1, Photo 2와 같은 그림자를 만든다.

**퍼즐 유형**
- 시계 맞추기(해시계 드래그/시각 점 탭)

**정답**
- 데이터 `photo1:t200,photo2:t330`: Photo 1 → **SUN 2:00**, Photo 2 → **SUN 3:30**.

**풀이 방법**
1. INVESTIGATE → 다이얼의 2:00 선 위치를 탭(또는 해를 돌려 드래그) → "The same shadow!" (`PHOTO 1: T1 2:00 · SUN 2:00 · same`).
2. `NEXT PHOTO`.
3. 3:30 선 위치를 탭/드래그 → `PHOTO 2: T1 2:30 · SUN 3:30 · one hour apart` → 자동 정답. (다른 선은 "longer/shorter" 설명만)

**필요한 단서**
- Roof Photo 1·2의 그림자.

**힌트**
- "Move the sun slowly. Watch the shadow turn and grow." / "In Photo 2, the shadow points between 3 and 4."

<a id="s2-c10-final"></a>

#### Final — The Hour Was Recorded
**목표**
- 테이프에서 Photo 2가 찍힌 2:30을 찾고, Trial Log에서 3–4시 쪽이 빠진 것을 확인한 뒤 결론을 고른다. 이후 기록 목록으로 다음 장소를 찾는다.

**퍼즐 유형**
- 장면 탐색(테이프 표시 탭 → 책 목차 탭) → 객관식 → (사건 종료 단계) 목록 선택

**정답**
- 테이프: **두 번째 `2:30`** (7번째 표시, `t7`).
- 책: 목차 `p.3 · 3:00 – 4:00` (NOT IN THE BOOK).
- 질문 정답: `The hour was there. T1 was one hour behind, and the page about it is missing.` (option `wrong`).
- 종료 단계: 목록 `p.3 · SENT TO: SAINT-SULPICE · ARCHIVE ANNEX`.

**풀이 방법**
1. 테이프에서 두 번째 2:30 탭 (첫 번째 2:30은 "only half an hour after Photo 1", 다른 시각은 "Find a 2:30"; 카운트 없음).
2. Trial Log CONTENTS에서 `p.3 · 3:00 – 4:00` 탭 (페이지 넘기기는 선택; p.1/2/4는 "That page is in the book.").
3. 질문 정답 선택 → `CHECK ANSWER`.
4. `READ THE RECORD LIST` → `p.3 · SENT TO: SAINT-SULPICE …` 탭 → `CONTINUE` (사건 종료).

**필요한 단서**
- M1 T1 Drum Tape, M3 The Shadow Check(Photo 2 = SUN 3:30), M2 Independent Time Log.

**힌트**
- "Photo 2 was taken later than Photo 1. How much later?" / "Find the page for three to four. Is it in the book?"

---

<a id="s2-c11"></a>

### Case 11 — The Unwritten Hour
- **장소:** Saint-Sulpice · Archive Annex (지도: Luxembourg Gardens 핀). **난이도:** 매우 쉬움(2026-10-27) — 한 화면에 할 일 하나, 선택지 2개(9번 상자만 3개), 단서는 같은 화면에, 힌트 무료·무제한(마지막 단계에서 정답 강조), 오답은 기록되지 않음(1회: "Try again! Look here." + 볼 곳 강조, 2회: 정답을 직접 말하고 강조).
- **구조:** 각 미션 = (Victor 대화) → 단계 퍼즐 → (Victor 반응) → Discovery → 이야기. 대화는 NEXT로 한 줄씩, 진행은 저장됨.

#### Mission 1 — The Missing Page
- **정답(단계):** ① 큰 장부 탭 → ② 오른쪽 장을 손가락으로 문지르기(드래그 또는 2–3번 탭) → `Page 3 is in Box 9.` / `Lock it. No one may read it.` / 서명이 드러남 → ③ 선반에서 **9번 상자**(오른쪽, 3·12는 오답 안내) → ④ 상자 속 폴더 탭 → ⑤ `TAKE PAGE 3`.
- **획득:** clue `The Rubbing`, evidence `Page 3`.

#### Mission 2 — Two Papers
- **정답:** `Were the clocks right?` → **NO** (3쪽: The clocks are wrong!) → `Are they the same?`(오페라 슬립 도장 vs Victor 서류 도장) → **YES**.
- **획득:** clue `The Same Stamp`, evidence `Victor's Paper`.

#### Mission 3 — Who Signed It?
- **정답:** 방명록 보기(NEXT) → 큰 장부의 서명과 같은 이름 → **Victor, today**(곡선 V·긴 밑줄·점).
- **획득:** clue `The Same Name`, evidence `Victor's Name`.

#### Final — Victor's Truth
- **정답(증거 카드 2장 중 선택):** `What happened at three?` → **Page 3** / `Whose paper was not true?` → **Victor's Paper** / `Who signed the order to hide it?` → **Victor's Name** → (선택) `What about the office bag?` → (필수) `Then who left the clues for me?` → `CLOSE THE CASE`.
- **획득:** evidence `Victor's Truth`. 사건 종료 후 Case 12가 열림.

<a id="s2-c12"></a>

### Case 12 — The Clockmaker's Truth
- **장소:** Arts et Métiers (시즌 마지막 사건). 난이도·오답·힌트 규칙은 Case 11과 같음.

#### Mission 1 — Find the Wheel
- **정답:** Clock III 바퀴(살 4개 X자)와 같은 바퀴 → **Wheel B**(Wheel A는 살 6개) → 이름표 `Made by Émile Moreau` → `TAKE THE TAG`.
- **획득:** clue `E.M.`, evidence `The Name Tag`.

#### Mission 2 — Who Is the Clockmaker?
- **정답:** 회중시계 탭(열기) → 시계 아무 곳이나 탭(안의 바퀴 강조) → 도장 탭(톱니 표식 찍힘) → `Are the marks the same?` **YES** → `Who is the Clockmaker?` **Émile** → 대화: `Are you the Clockmaker?` → `Why did you do it?` → `And Big Ben?` → `Why did you leave clues for me?`(한 번에 질문 하나씩).
- **획득:** clue `Three Clues`, evidence `The Clockmaker's Mark Tool`.

#### Mission 3 — Fix the Machine
- **정답:** **STOP** 버튼 → 큰 바퀴 탭(자동으로 한 시간 회전, 10:20 → 11:20) → 핀 탭(자동 고정) → **START** 버튼.
- **획득:** clue `All Agree`(11:20), evidence `The Fixed Machine`.

#### Final — The Final Case Board
- **정답(질문 6개, 하나씩, 2지선다):** Did Paris lose an hour? **NO** / Were the clocks wrong? **YES** / Who hid page 3? **Victor** / Who is the Clockmaker? **Émile** / Why did Émile leave clues? **To show the truth** / Was Émile right to scare people? **NO** → `CLOSE THE CASE`.
- **이후:** 엔딩(한 줄씩 NEXT, 11줄) → `CLOSE THE CASE`(사건 종료) → 마지막 두 줄 → `SEE MY CASE REPORT` → `SEASON TWO COMPLETE` → `INVESTIGATION BOARD`(COMPLETED, The Clockmaker 공개) → `DETECTIVE ARCHIVES`.
- **획득:** evidence `The Case File`.
