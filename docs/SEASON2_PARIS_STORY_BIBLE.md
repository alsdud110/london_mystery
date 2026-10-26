# WORLD MYSTERY — SEASON 2 STORY BIBLE
## PARIS STANDS STILL — ONE STOLEN HOUR

**Version:** 2.0 · 2026-10-26  
**Status:** 사용자 선택 A안에 따른 **후반부 신규 스토리 설계 기준안**. Case 01–05는 실제 구현이 우선하는 불변 기준이며, Case 06–12 및 시즌 진상은 본 문서에서 새롭게 정한 기획이다. v1.1에서 **Season 1 Clockmaker = Émile Moreau** 통합 설정을, v1.2에서 **편지 4417 보류 시점**과 **Big Ben 비밀 문 보관함 ↔ Paris 연결**을, v1.3에서 **Big Ben 이중 잠금 구조**와 **편지 4417 보류 사유(Preservation Order)**를, v1.4에서 **Case 06 확정 퍼즐·편지 문구·Case 07 연결**을, v1.5에서 **Case 07 확정 퍼즐·수정 슬립·Case 08 연결**을, v1.6에서 **Case 08 확정 퍼즐·가방 그림·방패 배지·찢긴 시간 변경 종이·Case 09 연결**을, v1.7에서 **Case 09 확정 퍼즐(간소화)·시험 시계 세 곳·두 표식의 출처·별 표식 → Arc de Triomphe 연결**을, v1.8에서 **Case 08 → 09 → 10 연결 대사 원칙**을, v1.9에서 **Case 10 확정 퍼즐·실제 시간/T1 표시 타임라인·Trial Log 3쪽 누락·Saint-Sulpice 연결**을 반영했다. Case 08 화면·대사 상세는 `docs/SEASON2_CASE08_SPEC.md`, 이미지 명세는 `docs/SEASON2_CASE08_ASSET_SPEC.md`. Case 09는 `docs/SEASON2_CASE09_SPEC.md`, `docs/SEASON2_CASE09_ASSET_SPEC.md`. Case 10은 `docs/SEASON2_CASE10_SPEC.md`, `docs/SEASON2_CASE10_ASSET_SPEC.md`. v2.0에서 **Case 11·12 확정 명세(8–12세용 단순화)**를 반영했다: Case 11 `docs/SEASON2_CASE11_SPEC.md`, Case 12 `docs/SEASON2_CASE12_SPEC.md`, 이미지 `docs/SEASON2_CASE11_12_ASSET_SPEC.md`, 검토 `docs/SEASON2_FINAL_STORY_REVIEW.md`.  
**Audience:** ages 8–12 · English-language detective adventure · realistic mystery (no actual time travel).  
**Scope:** 12 cases, three acts, full solution, chronology, characters, clue ledger, case-by-case missions and endings, implementation guardrails.

> **One-line premise:** Paris did not lose an hour of time. Someone erased the truth about what happened during that hour.

---

# 1. 절대 유지할 기존 정사 (Case 01–05)

이 절은 이미 구현된 프로젝트 데이터의 조사 결과를 정리한 것이다. 새 후반부 기획 때문에 기존 사건의 정답·증거·대사·저장 키를 변경하지 않는다.

| Case | Title / setting | Established facts | Ending hook |
|---|---|---|---|
| 01 | **The Ticking Watch** · Gare du Nord | 역의 오래된 시계가 한 시간 느리다. 분실물 메모, TIME 자물쇠, 톱니 표식이 등장한다. London의 시계 뒷면에는 PARIS. | 황동 상자의 Montmartre 그림과 `FIND THE PAINTER`. |
| 02 | **The Vanishing Painter** · Montmartre | 화가 P.는 스스로 자취를 감췄다. 그림에 숨겨진 단서를 발견한다. 화가의 말: `I saw who took the hour.` **목격한 사람의 정체는 공개되지 않았다.** | `TOUJOURS PLUS HAUT`와 탑 스케치. |
| 03 | **The Tower's Secret** · Eiffel Tower | 방문객 공지 4:00 / 정비 기록 3:00, 리프트 3:20 Service Level 진입 / 4:25 귀환, 비밀 공간의 상자 흔적. `ONE HOUR IS MISSING` 명판. **실제 시간 소멸은 입증되지 않았다.** | `FROM: SERVICE LEVEL. TO: THE RIVER.` |
| 04 | **The River's Secret** · Seine Quays | Box 17→23, `CLOCK PARTS`, `PASSAGE DES HORLOGERS · No. 7`, 두 바늘 표식. River Keeper의 장부. | No. 7 공방과 `Do not trust the clocks`. |
| 05 | **The Silent Workshop** · Passage des Horlogers No. 7 (map anchor: Notre-Dame) | 도장 비교, Clock III의 특이한 작은 황동 바퀴, 거울로 읽는 메모, 편지 No. 4417. 우편 슬립: 9:00 AM COLLECTED · PASSAGE BOX → 11:00 AM SORTED · CENTRAL OFFICE → 4:00 PM HELD · LOUVRE POST ROOM. **편지의 내용·보류 이유·보류자·제작자 신원은 아직 밝혀지지 않았다.** | `Who held the letter at the Louvre post room?` |

**Existing map allocation, unchanged:** 06 Louvre; 07 Palais Garnier; 08 Montmartre/Abbesses; 09 Luxembourg Gardens; 10 Arc de Triomphe; 11 Luxembourg Gardens (Saint-Sulpice area as a narrative location, subject to map labeling); 12 Arts et Métiers.

**Important:** Case 03의 현재 리프트 이동 기록을 과거 사고 발생 시간과 자동으로 동일시하지 않는다. Case 05의 편지가 실제로 Clock III에 있었다거나 누가 꺼냈다고 단정하지 않는다. 두 바늘 표식과 Case 01 톱니 표식이 동일 인물의 것이라는 사실도 아직 증명되지 않았다.

**Case 01 표현 유지:** Case 01의 `The Clockmaker's Mark`(톱니 표식) 증거와 `The Clockmaker steals an hour.` 등의 기존 대사·힌트는 수정하지 않는다. 이 표현은 **플레이어의 초기 해석**이며, Case 12에서 실제로 사라진 것은 시간이 아니라 사고 기록의 한 시간이었다는 진실로 회수한다.

**날짜 연속성 (구현된 사실, 변경 금지):**
- Case 04 River Keeper 장부: 13 MAY Box 17 입고 → 14 MAY Box 17→23 이동 → 15 MAY Box 23 No. 7 수령.
- Case 05: 16 MAY 영수증 `ONE LETTER COLLECTED FROM No. 7 · LETTER No. 4417`, 우편 슬립 세 장 모두 16 MAY (9:00 AM / 11:00 AM / 4:00 PM HELD).
- Case 06 이후는 **Case 05 이후 시점**이다. 정확한 날짜는 Case별 세부 명세에서 정한다.
- **확정:** 편지 4417은 **5월 16일 오후 4시, Louvre 우편실에서 보류(HELD)**되었다. 이는 Case 05 슬립 `16 MAY · 4:00 PM · HELD · LOUVRE POST ROOM`으로 구현된 사실이다.
- **확정 (v1.3):** 보류 사유는 **Preservation Order(보존 지시)**다. 편지를 폐기·훼손하라는 지시가 아니라 **별도 보관하라는 행정 조치**다.
- **미확정:** 보존 지시를 내린 사람과 구체적 이유, 실제로 보류 처리한 담당자, 이후 이동(TRANSFERRED) 날짜·이동 담당자, 현재 보관 위치.
  - *(v1.4, Case 06에서 확정)* 이동: **17 MAY · MORNING · MOVED**, 이동 장소: 같은 건물 아래층 **archive**(보존 서랍). 보존 지시자·구체적 이유·보류 처리 담당자·이동 담당자는 계속 미확정.
- Case 05의 우편 기록·대사·퍼즐은 변경하지 않는다.
- 과거 시험 사고(15:00–16:00)의 날짜는 계속 미지정이다.

---

# 2. 작가 전용 최종 진실 (초반 플레이어 공개 금지)

## 2.1 사건의 실체

파리에는 과거 **Chronos Synchronisation Trial**이라는 소규모 공공 시계 동기화 시범사업이 있었다. 이 사업은 도시 전체가 아니라 **서로 연결된 일부 시험 시계와 시험 기록 장치**만을 대상으로 했다. 시계 제작자이자 기술 담당자 **Émile Moreau**는 시험 중 장치가 잘못된 기준 시각을 전파할 수 있음을 발견했다.

시범 운용의 어느 날 **오후 3:00–4:00**, 잘못된 기준 시각이 시험망에 적용되었다. 시험 장치의 표시와 실제 운용 기록이 어긋났고, 에밀은 운용을 중단하고 오류를 공개하라고 경고했다. 대규모 재난이나 인명 피해는 설정하지 않는다. 핵심은 **기술적 실패와 이를 숨긴 행위**다.

당시 사업 책임자 **Victor Delacroix**는 자신의 승진·명예와 사업 승인에 불리한 결과를 감추려 했다. 그는 오류를 기록한 **15:00–16:00 시험 일지와 에밀의 경고 보고서를 공식 보관본에서 제거**하도록 지시하고, 일부 요약 시간표를 수정했다. 그는 시간이 아닌 **증거**를 훔쳤다.

에밀은 공식 기록이 사라진 뒤 자신이 문제를 일으킨 사람으로만 남게 된 것을 알고, 원본의 위치를 추적하기 시작했다. 그는 정당한 방법 대신 **런던에서 Season 1 사건을 직접 계획하고 실행**했고(§2.5), 그 계획이 탐정에게 저지된 뒤에는 파리에서 과거 기록을 찾도록 유도하기 위해 **현재의 몇몇 개별 시계에 의도적으로 이상을 만들고**, 자신의 표식·그림·편지·운송 경로를 통해 탐정에게 단서를 남겼다. 에밀은 과거 기록 삭제의 책임자는 아니지만, **런던 사건과 파리의 단서 조작에 대한 책임은 에밀 자신에게 있다.**

## 2.2 왜 지금 시작됐나 — 시즌 촉발 사건

과거 사업의 관련 문서와 시험 장치가 **Arts et Métiers의 가상 특별 보존 목록으로 정리되는 과정**에서 일부 자료가 폐기·봉인될 예정이라는 통지를 에밀이 받았다. 이것은 시즌 2 후반부에서 문서로 확인되는 **새 설정**이다. 기록을 되찾을 시간이 얼마 남지 않았다.

**순서:** 과거 시험 사고와 기록 삭제 → 에밀의 런던 계획(Season 1: Big Ben 비밀 문 뒤 보관함의 자료 확보·공개 목적, §2.6) → 탐정이 계획을 저지, 에밀은 자료를 확보하지 못하고 사라짐 → 에밀이 남긴 `PARIS` 시계 → 파리의 단서망(Season 2).

에밀이 런던에서 `PARIS` 시계를 남긴 이유: 자신의 계획을 증거만으로 무너뜨린 탐정이라면 자기 말이 아니라 **증거로** 진실에 도달할 것이라고 판단했기 때문이다. 에밀의 진술은 그가 런던 사건의 범인이기 때문에 그 자체로 믿을 수 없다. 이것이 Season 2 전체에서 플레이어가 독립적인 기록·물건으로 진실을 입증해야 하는 이유다.

**에밀은 Season 1 런던 사건의 범인이다.** Season 2는 그 사실을 지우거나 미화하지 않는다. 런던 사건의 배경에 파리의 삭제된 기록을 드러내려는 목적이 있었다는 사실은 **동기의 설명일 뿐 정당화가 아니다.** Season 1에서 탐정이 Clockmaker를 막았다는 결말은 그대로 유지한다.

## 2.3 Clockmaker라는 별명과 반전

- **Clockmaker = Émile Moreau = Season 1 London의 Clockmaker** (동일 인물). 플레이어는 Season 1부터 ‘Clockmaker’라는 별명과 그의 런던 계획을 이미 알고 있다. Season 2에서 감춰지는 것은 **그의 실명, 과거 시험 사업과의 관계, 런던·파리 행동의 동기**다. 실명과 동기는 Case 12에서 최종 확인하고, Case 09–11에서는 과거 시험 사업과의 연관만 암시한다.
- **Victor Delacroix = 과거 기록 삭제 지시 책임자** (Case 11에서 증거로 드러나고 Case 12에서 입증한다). Victor는 Season 1 런던 사건과 무관하다.
- Émile은 **영웅이 아니다.** 그는 런던에서 범행을 계획·실행했고 파리에서도 시계를 조작해 사람들을 혼란스럽게 했다. 그가 드러내려던 진실(기록 삭제)이 사실이라는 것과, 그가 쓴 방법이 잘못이라는 것은 **별개의 문제**로 다룬다. 아이들에게는 ‘옳은 목적이 잘못된 행동을 정당화하지 않는다’는 결말로 처리한다.
- **톱니 표식(The Clockmaker's Mark):** 과거 Chronos 시험 장치의 **설계 문양**에서 유래했다. 에밀은 시험 사업 이후 그 문양을 **자신의 상징**으로 쓰기 시작했다. Case 01에서는 Clockmaker의 표식으로만 보이고, Case 09에서 시험 장치 설계도의 문양과 대조해 그 기원을 증거로 확인한다.
- **‘Stolen hour’는 삭제된 한 시간의 기록**이라는 중의적 표현이다.
- **‘Paris stands still’은 시계 표시가 어긋나고 사람들이 무엇이 사실인지 혼란스러워하는 상태를 가리키는 시적 제목**이지 실제 도시가 물리적으로 정지한다는 뜻이 아니다.

## 2.4 기계 작동 원리의 경계

- 시험망은 일부 **시험용 시계**와 기록 장치에만 연결된다. 파리의 모든 시계나 교통 시스템을 조작하는 능력은 없다.
- 에밀은 **Case 01의 특정 오래된 시계**를 별도로 한 시간 늦추고, Case 05의 **Clock III**를 단서용으로 개조했다. 둘을 과거 시험망에 직접 연결했다고 설명하지 않는다.
- Case 03의 공지·정비 기록 차이는 현재 탐정이 발견한 **의심스러운 기록 불일치**다. 후반부에서 이 기록이 과거 시험사업 자료를 찾아가도록 남겨진 **참조 표식**이었다는 것이 밝혀지지만, 같은 날의 실제 시간 소멸이나 과거 사고의 실시간 재현으로 취급하지 않는다.
- 과거 사고의 날짜는 **미지정**. 15:00–16:00은 사건 구간이지 현재 Case 03의 리프트 운행 시간과 같은 날짜라고 주장하지 않는다.

## 2.5 Season 1 London — Clockmaker의 확인된 행동 범위

Season 1 구현 데이터에서 확인된 사실만 정사로 인정한다. 새로운 런던 범행을 소급 추가하지 않는다.

| 확인된 사실 | 출처 (Season 1) |
|---|---|
| Raven Society는 Clockmaker의 명령을 받는다 (`The Clockmaker gives the orders.`) | Case 08 |
| Raven Society의 까마귀 표식이 Big Ben을 멈춘 톱니, 사라진 그림 등 여러 사건 증거에 남았다 | Case 02, 03, 06 등 |
| Ravenmaster는 Clockmaker의 감시 때문에 직접 말하지 못했다 | Case 10 |
| Big Ben은 톱니 하나가 빠져 **8:17**에 멈췄고(까마귀 표식 톱니), 그 시각은 그림 도난 계획의 암호였다. 탐정이 Big Ben을 다시 움직였다 | Case 02 |
| 자정 계획의 수단은 진짜 톱니였다. 탐정이 진짜 톱니를 지켰고 Mrs Bell이 시계 안에 잠갔다. Big Ben은 자정에 울렸다 | Case 12 |
| 계획: 자정에 Big Ben(the great clock)을 다시 멈추고, Raven Society가 Big Ben 아래 그의 비밀 문을 연다 | Case 05, 10, 11, 12 |
| Clockmaker는 11:40 파리발 열차로 런던 Platform 4에 도착했다 | Case 12 |
| 탐정이 계획을 막았다. Clockmaker는 사라졌고, 책상에 `PARIS`가 새겨진 회중시계가 남았다 | Case 12 |
| Clockmaker의 이름·얼굴·비밀 문의 목적은 공개되지 않았다 | Case 12 |

**연결 원칙:**
- 런던에서 시계를 멈추는 방식과 파리에서 시계를 어긋나게 하는 방식은 **같은 시계 기술자의 수법**으로 연결된다.
- Season 2에서 런던 사건을 언급할 때 Season 1의 사실(범행·저지·도주)을 그대로 인정한다. “사실은 좋은 사람이었다”는 식의 반전은 금지.
- 런던 계획과 파리 기록의 연결은 §2.6에서 정한다.
- Season 1 Case 12의 기존 묘사(‘the Clockmaker's door’, ‘his secret door’, 탐정이 Brass Key와 세 자물쇠로 문을 엶, 문 뒤의 ‘his empty desk’ 위 회중시계)는 그대로 유지한다.

## 2.6 Big Ben 이중 잠금 구조 — London → Paris 연결 (v1.2 신규, v1.3 확정)

**성격:** Season 1에서 공개된 사실이 아니라 **Season 2 Case 12에서 밝혀지는 배경**이다. Season 1의 대사·장면·퍼즐·결말은 수정하지 않는다.

**구조 (확정):**

| 잠금 | 무엇 | 여는 방법 | Season 1에서 |
|---|---|---|---|
| 1차 · 비밀 문 | Big Ben 아래 작은 철문 → **Clockmaker의 작업실** | Brass Key + 세 자물쇠 | 탐정이 열었다. 작업실은 비어 있었고 책상 위에 `PARIS` 시계가 있었다 (기존 장면 유지) |
| 2차 · 보관함 | 작업실 안에 **별도로 잠긴 보관함** | **Big Ben의 시계 장치를 특정 위치에 멈추면** 잠금 해제 | 에밀은 열지 못했다. 탐정은 보관함을 발견하지 못했다 |

**확정:**
- 작업실은 Émile Moreau가 **이미 드나들던 공간**이다. ‘the Clockmaker's door’, ‘his empty desk’ 묘사와 일치한다.
- 보관함에는 **과거 파리 시계 동기화 시험(Chronos Synchronisation Trial)의 설계도 일부와 기록 색인**이 들어 있다.
- 에밀은 이 자료를 **확보하거나 공개하려고** 런던 사건을 계획했다. Raven Society를 이용했고, Big Ben을 멈춰 보관함 잠금을 해제하려 했다.
- 탐정이 계획을 저지해(Big Ben이 멈추지 않음) **보관함은 열리지 않았고, 에밀은 자료를 확보하지 못했다.**
- 이후 에밀은 작업실 책상 위에 `PARIS`가 새겨진 시계를 남겼고, 탐정은 파리로 향했다.
- 에밀의 동기는 런던에서의 행동을 **정당화하지 않는다.**
- 보관함의 존재와 잠금 원리는 **Case 12에서 처음 공개**한다.

**Season 1과의 인과 검증:**
- Case 02의 8:17 정지는 그림 도난 계획의 암호용 정지였다. 이 정지로 보관함이 열리지 않은 것은 8:17이 ‘특정 위치’가 아니기 때문으로 정합하게 설명된다.
- Case 12의 계획은 **자정에** Big Ben을 멈추는 것이었고, 수단은 진짜 톱니였다. 탐정이 진짜 톱니를 지켜 Big Ben은 자정에 울렸다 → 시계 장치가 멈추지 않음 → 보관함 잠금 해제 실패. 인과관계가 성립한다.
- 비밀 문은 Brass Key로 열리는 별개의 잠금이므로, 탐정이 문을 열었다는 사실은 보관함이 잠긴 채 남았다는 설정과 모순되지 않는다.

**미확정 (설명 없이 확정 사실로 쓰지 않는다):**
- ‘특정 위치’가 정확히 어느 시각 위치인지. Season 1 계획이 ‘자정에 멈춤’이었으므로 **자정(12:00) 위치**가 가장 자연스럽지만, 사용자 확정 전에는 명시하지 않는다.
- 파리 시험 자료가 런던 보관함에 보관된 경위, Big Ben 시계 장치와 보관함 잠금을 연결한 사람·시기.
- 에밀이 보관함과 자료, 잠금 원리를 알게 된 방법.
- 보관함이 작업실 안에서 어떻게 숨겨져 있었기에 탐정이 발견하지 못했는지.
- 탐정이 Case 12에서 보관함의 존재를 **어떤 증거로** 알게 되는지 (에밀의 진술만으로 확정하지 않는다는 원칙과 함께 결정). *(v2.0 처리: Case 12에서 보관함은 **Émile의 진술로만** 나오고 증거로 확인하지 않는다. 화면이 즉시 `You can't check his box from here. But the clues in Paris are real.`로 밝힌다. 보관함은 동기 설명일 뿐 어떤 결론의 근거도 아니다. 아이에게는 "특정 위치"를 `It opens only if Big Ben stops.` / `It needs one special moment.`로만 말한다.)*
- Season 1 이후 보관함의 현재 상태와 행방, Case 12 이후 보관함을 여는지 여부.

**사용 원칙:**
- 런던 보관함 자료는 Season 2의 어떤 퍼즐에서도 **풀이에 필요한 증거로 쓰지 않는다**(탐정이 확보한 적 없는 자료이기 때문). Paris의 진실은 Paris에서 찾은 증거로 입증한다.
- 런던 보관함의 설계도·색인을 Victor의 책임 입증 근거로 쓰지 않는다.
- Big Ben의 정지가 현실 도시나 실제 시간을 바꾼다는 식으로 묘사하지 않는다. 시계 장치의 위치가 기계식 잠금의 조건일 뿐이다.

---

# 3. 인물 바이블

| 인물 | 겉으로 알려진 역할 | 실제 역할·동기 | 공개 타이밍 |
|---|---|---|---|
| **Émile Moreau** | 이름 없는 Clockmaker (Season 1 런던 사건의 범인) / No. 7 제작자 후보 | 과거 시험 사업의 기술 담당자. 삭제된 기록을 드러내려는 목적으로 **Season 1 런던 사건을 계획·실행**했고, 저지된 뒤 파리에서 현재 단서망을 만든 인물. 목적이 행동을 정당화하지 않는다. **No. 7 제작자와 동일 인물이라는 것은 Case 12에서 도구 흔적·기록으로 확인**. *(v2.0)* 3쪽이 숨겨진 것은 알았지만 **어디 있는지는 몰랐다**(그래서 런던 보관함의 색인이 필요했다). 찾아내더라도 "꾸며 냈다"는 말을 들을 것이므로 탐정이 증거로 찾게 했다 | Clockmaker 별명은 Season 1부터 공개. *(v2.0)* Case 11 원본 3쪽에 이니셜 **E.M.**(시험을 멈추라고 한 사람). Case 12 Intro 얼굴, M1 이름(바퀴 이름표), M2 Clockmaker와 동일인(같은 바퀴 + 톱니 도장), 동기는 그 뒤 질문·답변 |
| **Victor Delacroix** | 옛 시계 시험 사업 책임자 | 실패와 자신의 삭제 지시를 감춘 인물. 물리적 시간 도둑이 아님. | Case 07에는 이름·이니셜 없음(수정 슬립에 바늘 없는 시계 + 월계관 도장만, v1.5), Case 11 명시, Case 12 입증. *(v2.0)* Case 11 Intro에서 직접 등장, 원본 3쪽의 **V.D.**("Keep going"), M2 사무실 도장, M3 서명, Final 고백 `I was afraid.` Case 12에는 직접 등장하지 않고 Case 11 진술 카드로만 나온다 |
| **P. (Painter)** | Montmartre에서 스스로 사라진 화가 | 과거 자료를 옮기는 사람을 목격했다. 얼굴을 보지 못했으므로 성급한 지목 금지. *(v1.6)* Abbesses의 한 모퉁이에서 어느 아침을 연필로 그렸고(가방 운반자의 뒷모습, 방패 배지), 계단에 떨어진 종이를 주워 그림 묶음에 보관했으며, 같은 가방을 정원의 작은 모형 시계 옆에서 다시 그렸다. 현재 행방은 미공개. | Case 02 진술, Case 08 목격 의미 해명 |
| **River Keeper** | 장부에 등장하는 운송 기록자 | Box 23 운송 경로를 기록한 사람. 공범이라는 근거 없음. | Case 04 기록, 후반부 필요 시 기록만 재인용 |
| **Louvre 보관 담당자** | 편지 4417의 행방을 아는 사람 | 편지를 고의 은폐한 악역이 아님. 16 MAY 4:00 PM **Preservation Order(보존 지시)**에 따라 편지를 보류한 행정 조치. 지시를 내린 사람·구체적 이유, 보류 처리 담당자, 이동 날짜·담당자, 현재 보관 위치는 **미확정**. | Case 06 |
| **플레이어 탐정** | 증거를 모으는 어린이 | 누구의 말도 맹신하지 않고 기록·물건·진술을 비교해 진실을 입증 | 전 Case |

**Victor의 구체적 법적 처벌이나 현실 기관의 징계 절차는 묘사하지 않는다.** 원본 기록이 공개되고 책임이 밝혀지는 데 초점을 맞춘다.

---

# 4. 전체 이야기의 3막 구조

### ACT I — THE MISSING HOUR (Cases 01–04)
이상한 시계 → 화가의 경고 → 에펠탑의 시간 불일치 → 강을 통해 옮겨진 시계 부품. **플레이어의 믿음:** 누군가 실제 시간을 훔쳤을지도 모른다. **사실:** 그런 증거는 아직 없다.

### ACT II — THE HIDDEN RECORDS (Cases 05–08)
No. 7 공방 → 편지 4417 → 오페라의 변경된 기록 → 화가의 목격 장면. **중간 반전:** 훔친 것은 시간이 아니라 ‘기록’일 수 있다. **유지할 의문:** 누가 지웠으며, Clockmaker는 왜 시계를 조작했는가?

### ACT III — THE TRUTH BEHIND TIME (Cases 09–12)
시계 시험 설계도 → 시간 조작 방식 검증 → 삭제 지시서와 원본 → 기계 정상화와 최종 증거 보드. **최종 반전:** 런던 사건의 범인 Clockmaker는 과거 시험 사고의 기술 담당자 Émile이었고, 삭제된 기록을 드러내려고 런던과 파리에서 잘못된 방법을 썼다. Victor는 과거 실패를 감추기 위해 기록을 지웠다. 두 사람의 책임은 서로 다르며, 어느 쪽도 다른 쪽을 지워 주지 않는다.

---

# 5. 12개 Case 공식 구성 (01–05 현행 유지, 06–12 신규)

| Case | English title | Location | Story function | Next hook |
|---|---|---|---|---|
| 01 | The Ticking Watch | Gare du Nord | 이상한 한 시간, 톱니 표식 | Montmartre 그림 |
| 02 | The Vanishing Painter | Montmartre | `I saw who took the hour` | 탑 스케치 |
| 03 | The Tower's Secret | Eiffel Tower | 3:00/4:00 기록, Service Level | Seine 운송표 |
| 04 | The River's Secret | Seine Quays | Box 23 / No. 7 / 두 바늘 | 공방 주소 |
| 05 | The Silent Workshop | Passage des Horlogers No. 7 | Clock III / letter 4417 | Louvre 보류 우편 |
| 06 | **The Letter That Never Arrived** | Louvre area | 편지의 보류 사유·색인 확보 | Palais Garnier 기록 번호 |
| 07 | **The Phantom Performance** | Palais Garnier | 공연 기록 수정 흔적·사업 표식 | 화가의 Abbesses 작업실 |
| 08 | **The Painter's Last Sketch** | Montmartre / Abbesses | 화가의 진술 의미 회수: 가방에서 시간 변경 종이가 떨어짐 | P.의 마지막 그림: 같은 가방 + 정원의 작은 모형 시계 |
| 09 | **The Clockwork Garden** | Luxembourg Gardens | 한정된 시험망 작동 원리 | Arc de Triomphe 기록 표식 |
| 10 | **The Hour of Shadows** | Arc de Triomphe | 한 시간 차이의 인위성 증명: 시간은 흘렀고 T1이 한 시간 늦게 표시, 그 시간의 기록부 3쪽 누락 (v1.9) | 기록 목록상 3쪽의 목적지 (Saint-Sulpice) |
| 11 | **The Unwritten Hour** | Saint-Sulpice area (map pin: Luxembourg Gardens) | *(v2.0)* Who hid the truth? 3쪽 발견(9번 상자) → Victor 서류의 거짓 → 서명 → Victor 고백 | E.M.의 옛 기계 → Arts et Métiers |
| 12 | **The Clockmaker's Truth** | Arts et Métiers | *(v2.0)* E.M. = Émile = Clockmaker(바퀴·시계·톱니 도장), 동기와 잘못, 기계 고치기, 최종 보드, 3쪽 보존 | 시즌 완결 |

**지명 주의:** Case 05의 Notre-Dame과 Case 11의 Luxembourg Gardens는 지도용 구역 앵커다. 화면에는 실제 사건 장소를 명확히 표시하며, 역사적 시설 내부에 실재하지 않는 우편실·비밀 보관실이 있다고 단정하지 않는다.

---

# 6. Case 06–12 상세 플롯 / 미션 / 증거 / 반전

## CASE 06 — THE LETTER THAT NEVER ARRIVED

### v1.4 확정 명세 (2026-10-22, 사용자 승인 — 아래 v1.3 기획안보다 우선)
**Location:** Louvre 근처의 가상 우편실(`LOUVRE POST ROOM`, Case 05 슬립의 이름) → 같은 건물 아래층 archive. Map pin: Louvre.  
**Core deduction:** 도난 / 보류 / 이동을 섞지 않는다. 보류 16 MAY 4:00 PM(Preservation Order: "Keep it safe."), 이동 **17 MAY · MORNING · MOVED**.

- **M1 · Find Letter 4417 (꼬리표 뒤집기):** 보류 선반의 꼬리표 4장을 뒤집어 앞뒤를 Notebook의 Case 05 증거 `Letter's Trail`(LETTER No. 4417 · 16 MAY · 4:00 PM · HELD)과 대조. A `PARCEL No. 4417`, B `LETTER No. 4471`, C `LETTER No. 44?7`(잉크 번짐, 뒷면 15 MAY 11:00 AM), **D `LETTER No. 4?17`(뒷면 16 MAY · 4:00 PM · HELD · PRESERVATION ORDER — Keep it safe. Do not send it. Do not throw it away.)**. C·D는 뒷면으로만 구별된다. **증거:** `The Hold Tag`. 정답 후 `Wait! It wasn't stolen.` / `Someone kept it safe.`
- **M2 · Follow the Letter (평면도 길찾기):** 우편실 장부 `16 MAY · 4:00 PM · HELD` → `17 MAY · MORNING · MOVED`. 짐꾼 쪽지 `Go down the stairs. / Walk past the statue. / Take the second door on the left.` 손으로 그린 평면도에서 편지 토큰을 탭으로 한 단계씩 이동(계단 → 조각상 → 문). 문 A·B는 조각상 앞, C·D·E·F는 조각상 뒤(C·E 왼쪽, D·F 오른쪽; 왼쪽은 편지가 걷는 방향 기준). **정답 Door E**, 그 뒤가 archive. **증거:** `The Porter's Note`. 카드 순서 배열은 쓰지 않는다(Case 05 Final과 중복).
- **M3 · The Hidden Envelope (서랍 + 찢긴 모서리 맞추기):** 서랍 라벨 `LETTERS 4000–4199 / 4200–4399 / 4400–4599`, `PARCELS 4400–4599` 중 LETTERS 4400–4599. 그 안의 번호 없는 찢긴 봉투 3장에 **Case 05 Clock III에서 실제로 발견한 찢긴 봉투 모서리**(`envelope_corner.png`, 라벨 No. 4417)를 드래그·스냅으로 맞춘다. 미리 준비된 이미지로만 구현(런타임 픽셀 절단·측정 금지). **정답 Envelope 2.** 봉인의 작은 오페라 극장 문양을 발견. **증거:** `The Torn Envelope`.
- **Final · The Secret in the Letter (그림 ↔ 지도 대조):** 편지 앞면 `The clocks may lie.` / `But the show remembers.` + 오페라 극장 스케치(돔, 지붕 위 조각상, 아치 창). 기존 Paris 지도의 건물과 비교해 **Palais Garnier**에 편지를 놓는다(Montmartre: 돔은 있으나 지붕 조각상 없음, Louvre: 이미 여기, Gare du Nord: 공연장 아님 등). 정답 후 뒷면 `OPERA ARCHIVE · FILE 3–4`. **증거:** `The Letter`. `We found our next clue!` / `The mystery continues at the opera house!`

**Keep hidden (v1.4):** 편지 작성자, 보존 지시자와 이유, 이동 담당자, Victor·Émile·Clockmaker의 연관. **`THE HOUR WAS NOT LOST. THE RECORD WAS REMOVED.`는 Case 06에서 공개하지 않는다** — 시즌 후반 반전으로 남긴다.  
**End hook:** `What is in File 3–4 of the opera archive?` → Case 07 Palais Garnier.

### v1.3 기획안 (참고용, v1.4 확정 명세로 대체됨)
**Location:** Louvre area, **fictional archival post room**.  
**Opening question:** `Who held Letter 4417 — and why?`  
**Starting evidence:** Case 05 `s2_ep05_e4` Letter's Trail: 09:00 → 11:00 → 16:00 HELD. 플레이어가 이미 찾은 증거를 **Case 06 M1에서 직접 열어 대조**하도록 설계.

- **M1 · The Empty Slot:** 편지 보관함과 접수대의 번호표를 살펴본다. 단순 번호 맞히기가 아니라 4417의 **보류 분류 기호**를 보관함 표식과 비교한다. **증거:** `Hold Tag 4417` (16 MAY 4:00 PM · HELD · **PRESERVATION ORDER**; 반송·배달·폐기 아님. 지시자 표기 방식은 미확정).
- **M2 · Two Accounts:** 두 담당자의 진술을 질문·증거로 대조해 **보류 시점과 실제 이동 시점을 구분**한다. 보류 시점은 **16 MAY 4:00 PM**으로 고정이다(Case 05 슬립). 이동 날짜와 이동 담당자는 미정이므로, 그 결정 전에는 진술을 확정 사실처럼 쓰지 않는다. 설계 원칙: 한 진술은 보류 행위(16 MAY 4:00 PM, 슬립과 일치)를, 다른 진술은 그 이후의 이동 행위를 말하며, 두 진술은 시간과 **보류 vs 이동**이라는 서로 다른 행위를 가리켜 모순이 아니다. 플레이어는 `Transfer Register`의 기록으로 이동 시점이 보류 시점 이후임을 확인한다. **증거:** `Transfer Register` (이동 승인 코드·이동 날짜; 날짜 미정). 이번 단계에서 M2 퍼즐·대사는 작성하지 않는다.
- **M3 · The Impressed Envelope:** 봉투 표면의 눌린 글씨를 빛의 각도로 드러내어 **가상 보존 기록 색인**을 읽는다. 현실 문서 감정처럼 어렵지 않게, 탐색 완료 후 명확한 선택지가 나타난다. **증거:** `Index 3–4 / OPERA`.
- **Final · Trace the Letter:** Case 05 슬립 + 보류 태그 + 이동 장부를 사용해 **편지가 사라진 것이 아니라 별도 보존 봉투로 옮겨졌음**을 입증한다. 보존 봉투에서 편지의 일부를 확인한다.

**Letter excerpt (player-visible):** `THE HOUR WAS NOT LOST. THE RECORD WAS REMOVED.`  
**End hook:** `OPERA ARCHIVE · FILE 3–4` → Palais Garnier.  
**Keep hidden:** 편지의 작성자, Victor의 최종 책임, Clockmaker의 이름.  
**Fairness:** 우편 담당자가 악의적으로 보류했다고 결론내리지 않는다. `HELD`와 `TRANSFERRED`는 다른 행위. Case 05의 세 우편 시각은 변경하지 않는다.  
**Core deduction — 보류 vs 도난:** 제목(`The Letter That Never Arrived`)과 Case 05 hook은 플레이어가 처음에 ‘편지를 누가 훔쳤나?’로 의심하게 만든다. Case 06은 Hold Tag의 `PRESERVATION ORDER`와 우편 기록으로 **도난이 아니라 행정적 보류**였음을 증거로 구분하게 한다. 그 다음 단계로 **보류(16 MAY 4:00 PM)와 이후 이동(날짜 미확정)**을 구분한다. 세 개념 — 도난 / 보류 / 이동 — 을 하나로 섞지 않는다.  
**Dates:** Case 06은 Case 05(16 MAY) 이후 시점이다. 보류는 16 MAY 4:00 PM, 사유는 Preservation Order로 확정. 지시자·구체적 이유, 보류 처리 담당자, `TRANSFERRED` 날짜·담당자, 현재 보관 위치는 Case 06 세부 명세에서 확정하며, M2 진술과 Final의 편지 발견 장소는 그 결정 이후에 작성한다.

## CASE 07 — THE PHANTOM PERFORMANCE

### v1.5 확정 명세 (2026-10-23, 사용자 승인 — 아래 v1.0 기획안보다 우선)
**Location:** Palais Garnier, 지붕 아래 가상 기록 보관실(archive) → 객석 뒤 조명 데스크 → 무대 옆 로프 레일 → 다시 archive의 라이트 테이블. Map pin: Palais Garnier.  
**Records:** 공연 *The Golden Nightingale*, **PERFORMANCE No. 34**. **FILE 3** = 사무실 공식 기록(`DOORS OPEN · 3:30 PM`, `CURTAIN UP · 3:00 PM`, `CURTAIN DOWN · 6:10 PM`). **FILE 4** = 공연 프로그램(OVERTURE 10 · ACT ONE 60 · INTERVAL 20 · ACT TWO 40, `THE WHOLE SHOW: 2 HOURS 10 MINUTES`) — **시작 시각은 적혀 있지 않다.** 실제 공연: 4:00 시작, 6:10 종료.  
**Core deduction:** 같은 공연의 시작 시각이 둘. 바뀌지 않은 독립 기록(프로그램 길이, 무대 큐카드)과 바뀐 기록(FILE 3)을 구별한다. 시간이 실제로 사라진 것이 아니라 **기록이 사후에 바뀌었다.**

- **M1 · The Show Strip (공연 띠 맞추기):** 2시간 10분 길이의 공연 띠(길이 고정)를 2:30–6:30 시간줄 위에서 10분 단위로 드래그·◀▶ 이동(시작 2:30–4:20). 관객 입장(3:30) **이후** 시작하고 `CURTAIN DOWN` 6:10에 끝나는 시작은 **4:00 하나**. 오답 분류: office(3:00) / early(≤3:30) / end(종료가 6:10 아님). **증거:** `The Office Record`. M1에서는 기록 수정 여부를 확정하지 않는다.
- **M2 · The Ghost Light (조명 맞추기):** 객석 뒤 조명 데스크의 레버 4개(GHOST LIGHT · HOUSE LIGHTS · FOOTLIGHTS · BIG SPOT, 16개 조합)로 `3:00 PM · CURTAIN UP!`이라 적힌 옛 사진과 같은 조명을 만든다. 정답은 **GHOST LIGHT만**: 빈 무대(공연 아님). 사진은 촬영 시각을 증명하지 않는다. Lighting Book의 No. 34 페이지 **Stage Cue Card**: `SHOW No. 34 · CUE 1 · CURTAIN UP · 4:00`(사무실이 아닌 조명 데스크 보관). 책에 끼워진 **익명의 작은 그림 쪽지**(빨간 문 위의 작은 시계) — 작성자는 밝히지도 추측하지도 않는다. **증거:** `The Stage Cue Card`.
- **M3 · The Painted Sky (배경막 내리기):** Case 02 증거 `The Painted Street`의 `Above the red door: a small clock.`로 로프 4개의 배경막(빨간 문 + 램프 / 빨간 문 + 먼 시계탑 / **빨간 문 + 바로 위 작은 시계(로프 3)** / 파란 문 + 작은 시계) 중 하나를 고른다. 오답은 각각 한 가지만 어긋난다. 배경막 뒤 천 주머니에서 **Amendment Slip**: `FILE 3 · PERFORMANCE No. 34 · CURTAIN UP: 4:00 → 3:00`, 보라색 잉크 **바늘 없는 시계 + 월계관 도장**, 이름·이니셜 없음. 슬립이 배경막 뒤에 있던 이유, P.가 배경막을 그렸는지는 확정하지 않는다(`Did P. paint this? We can't be sure.`). **증거:** `The Amendment Slip`.
- **Final · The Changed Record (라이트 테이블 + 핀 연결):** (1) 바뀐 기록 고르기: FILE 3(3:00) vs FILE 4 + 큐카드(4:00) → FILE 3. (2) FILE 3을 라이트 테이블에 올리고 황동 스위치를 켠다: CURTAIN UP 위에 덧붙인 종이의 테두리와 그 아래 원래 `4:00 PM`이 비친다(DOORS OPEN·CURTAIN DOWN은 그대로). (3) 슬립의 `4:00` 핀 → 덧붙인 종이 아래 원래 시각, `3:00` 핀 → 덧붙인 종이 위 바뀐 시각. 정답 상태 `old:under,new:patch`. **증거:** `The Changed Record`.

**Reveal (Case Solved):** 공연은 4:00에 시작했다. FILE 3도 처음엔 4:00이었고 나중에 누군가 3:00으로 덮었다 — 3:00 공연은 종이 위에만 있었다(*phantom performance*). Case 03 에펠탑 안내문의 3:00/4:00을 **유사 패턴**으로만 회상(`Is it the same hand? We don't know yet.`).  
**End hook:** 슬립 뒷면의 작은 연필 스케치(계단, 가로등, metro 표지판 `ABBESSES`)와 `P. KNEW THE BAG.` → Case 08 *The Painter's Last Sketch* (Montmartre / Abbesses). Case 08 질문: `What did P. see — and what was in the bag?`  
**Keep hidden (v1.5):** 기록을 바꾼 사람·지시자·이유, 그림 쪽지 작성자, 슬립이 배경막 뒤에 있던 이유, P.와 배경막의 관계, Victor·Émile·Clockmaker의 연관, 모든 실명·이니셜. 도장 문양(바늘 없는 시계 + 월계관)은 Case 08 이후 재사용을 위해 유지한다.

### v1.0 기획안 (참고용, v1.5 확정 명세로 대체됨)
**Location:** Palais Garnier, fictional archival wing.  
**Opening question:** `Why does the same performance have two start times?`

- **M1 · The Stage at Four:** 무대 조명 배치와 무대 사진을 조사해 기록 속 장면이 **공연 시작**인지 **리허설**인지 구별한다. **증거:** `Stage Cue Card`.
- **M2 · The Missing Cue:** 소품의 사용 흔적과 큐카드를 이용해 공연 순서를 복원한다. **증거:** `Original Cue Sheet` (4:00 공연 시작).
- **M3 · The Rewritten Programme:** 서로 다른 종이·수정 잉크·날짜 표식을 비교해 공식 보관본이 나중에 고쳐졌음을 발견한다. **증거:** `Amendment Slip` (사업 책임자 부서의 승인 기호; 실명은 일부 가림).
- **Final · Which Record Changed?:** 독립적인 무대 큐카드와 원본을 근거로 **3:00 표기가 사후 수정**이라는 결론을 증명한다. Case 03의 시간 불일치를 **유사 패턴**으로 회상하되 동일 원인이라고 단정하지 않는다.

**End hook:** 수정 지시서 뒷면에 화가 P.가 그린 작은 Abbesses 거리 스케치와 `P. KNEW THE BAG.`  
**Keep hidden:** 지시서의 최종 서명자, P.가 본 얼굴.

## CASE 08 — THE PAINTER'S LAST SKETCH

### v1.6 확정 명세 (2026-10-23, 사용자 승인 — 아래 v1.0 기획안보다 우선)
**상세:** `docs/SEASON2_CASE08_SPEC.md`(대사·피드백·힌트·Glossary), `docs/SEASON2_CASE08_ASSET_SPEC.md`(이미지).  
**Location:** Abbesses 광장 → P.의 모퉁이(계단·가로등·두 기둥 사이 black gate·위쪽 흰 교회). Map pin: Montmartre/Abbesses.  
**Intro:** Case 07 Amendment Slip 뒷면(`abbesses_sketch.png` 재사용, `ABBESSES`, `P. KNEW THE BAG.`)을 다시 보여 준다. Case 07 데이터는 변경하지 않는다.  
**Core deduction:** 그림의 시간 순서와 위치로 **종이가 가방에서 떨어졌음**을 추론하고, 그 종이가 Case 07 슬립과 같은 **시간 변경 양식**임을 확인한다. 결론은 떨어진 종이 한 장으로 한정한다.

- **M1 · The Hidden Sketch (지점 고르기):** 광장의 세 모퉁이를 Case 02 `The Hidden Sketch`(그림 + inscription `The gate is black.`, Recall Card)와 비교한다. Corner 1 = 배치 같음 + **dark green gate**, **Corner 2 = 배치 같음 + black gate (정답)**, Corner 3 = 좌우 반대 배치 + black gate. 배치(그림)와 색(inscription)이 각각 꼭 필요하다. 왼쪽 기둥의 헐거운 돌 뒤에서 그림 묶음 발견. **증거:** `The Painter's Spot`.
- **M2 · The Morning Drawing (순서 + 겹쳐 보기 + 출처 추론):** 같은 구도의 연필화 3장. P.의 꼬리표 `I drew this corner one morning. First, the sky was dark. Then it grew light. When the sun came up, the lamps went out.` 순서 근거는 **하늘의 밝기**(별이 있는 어둠 → 희미 → 밝음)와 **가로등**(켜짐·켜짐·꺼짐)이며, 순서는 1→2→3 하나로 정해진다. **그림자는 순서 근거로 쓰지 않는다.** 그림 2: 모자 쓴 뒷모습의 인물이 꽉 차서 덮개 아래로 종이가 삐져나온 **납작한 서류 가방**(버클 2개, 덮개에 **방패 배지, 테두리에 잎**)을 들고 열린 대문에서 나와 왼쪽 계단을 오르고 있고, 여백에 배지 확대 그림이 있다. 그림 3: 인물 없음, 가로등 꺼짐, **계단 맨 아랫단에 종이**(인물이 지나간 자리), 여백에 종이 확대 그림(위쪽 V자 찢김). 질문 `Where did the paper on the steps come from?` → `It fell from the bag.` **증거:** `The Bag Sketch` (얼굴·이름 없음).
- **M3 · The Purple Seal (펼치기 + 같은 점·없는 점):** 그림 뒤의 접힌 종이와 P.의 쪽지 `I found this paper on the steps. I kept it with my drawings.`(가방 언급 없음). 펼친 뒤 Case 07 `The Amendment Slip`(Recall)과 비교한다. SAME = 이중 테두리, FILE 머리글 띠, `→` 변경 줄, 보라색 도장(바늘 없는 시계 + 월계관, 바늘 수·잎 확인). MISSING = FILE 번호, 시 숫자. 보이는 글자는 `FILE`, `:00 →`뿐이다. Case 05 식의 "도장 여러 개 중 고르기"는 쓰지 않는다. **증거:** `The Matching Seal`.
- **Final · The Torn Hour (겹치기 + 증거 보드):** (1) 실물 종이를 돌려 그림 3 여백의 확대 그림에 겹친다. V자 찢김, 오른쪽 거친 가장자리, 접힌 자국, 도장 자리가 한 방향에서만 맞는다 → 같은 종이. (2) 보드(증거 직접 제공: Bag Sketch, Matching Seal, **Case 07 Amendment Slip**, 미끼 Painter's Spot): Q1 `Where did the paper come from?` → Bag Sketch, Q2 `What kind of paper is it?` → Matching Seal + Amendment Slip. 결론 **`A paper for changing a time fell from the bag.`** (오답: clock parts / the painter carried it / we know who changed the record). Final 전용 Recall 확장은 쓰지 않는다. **증거:** `The Torn Hour`.
- **Case Closed · Next Lead (점수 없음):** 묶음 맨 아래 **P.의 마지막 그림**. (a) Bag Sketch와 같은 가방인지 확인: 납작한 모양, 버클 2개, 방패 배지(미끼: 둥근 바구니). (b) 그림의 긴 궁전(가운데가 높음), 분수가 있는 둥근 연못, 꽃밭을 기존 Paris 지도와 대조(Case 06 `LetterMap` 방식) → **Luxembourg Gardens**. 잔디 위의 **작은 모형 시계, 둘레에 작은 지붕들**.

**Case 09 질문:** `Why did the bag go to the little clock in the garden?`  
**새로 확정한 사실 (v1.6):** P.가 Abbesses 모퉁이에서 어느 아침을 그림 3장으로 그렸다. 운반자는 대문에서 나와 계단을 올라갔고 가방에서 시간 변경 양식의 종이가 떨어졌다. P.가 그 종이를 주워 보관했다. 종이는 Case 07 슬립과 같은 양식(이중 테두리, FILE 띠, `→`)과 같은 보라색 도장을 가졌다. 가방에는 **방패 모양, 테두리에 잎이 있는 배지**가 있다. P.는 같은 가방을 정원 모형 시계 옆에서 다시 그렸다.  
**미확정 (Case 08에서 쓰지 않음):** 운반자의 얼굴·이름·소속, **배지의 의미와 가운데 문양**(P.의 그림에서는 너무 작아 보이지 않음 — Case 11–12에서 회수), 도장과 배지의 관계, 종이의 FILE 번호·원래 시각·바뀐 시각·대상 기록, 가방 속 다른 내용물, 그림의 날짜(과거 시험 사고 날짜 미지정 원칙과 맞춤), 가방이 정원에 간 이유, P.가 가방을 따라갔는지, `P. KNEW THE BAG.` 작성자, P.의 현재 행방.  
**Keep hidden (v1.6):** 위 미확정 항목 전부, Chronos 시험·시험망·모형 시계의 기능, Victor·Émile·Clockmaker와의 연관, 모든 실명·이니셜. `THE RECORD WAS REMOVED`는 계속 비공개.

### v1.0 기획안 (참고용, v1.6 확정 명세로 대체됨)
**Location:** Montmartre / Abbesses.  
**Opening question:** `What did P. really see?`

- **M1 · A View from Above:** 거리 구조·창문·간판을 스케치의 시점과 비교해 화가가 서 있던 곳을 찾는다. Case 02의 단순 차이 찾기를 반복하지 않고 **관찰 위치 선택**을 중심으로 한다. **증거:** `Painter's Viewpoint`.
- **M2 · The Passing Bag:** 서로 다른 시간대의 작은 스케치로 **문서 가방을 든 사람이 기록 상자를 옮기는 이동 경로**를 복원한다. **증거:** `Bag Sketch` (배지 문양은 보이나 얼굴은 안 보임).
- **M3 · The Badge in the Border:** 그림 테두리의 반복된 문양을 찾아 Case 07 수정 지시서의 부서 표식과 대응한다. **증거:** `Trial Office Emblem`.
- **Final · What Was Taken?:** Case 02의 `I saw who took the hour`를 다시 읽고, 화가가 **시계나 실제 시간을 훔치는 장면이 아니라 3–4시 시험 기록을 가져가는 장면**을 보았다는 사실을 도출한다.

**End hook:** 화가가 숨겨둔 종이의 정원 모형 표시 → Luxembourg Gardens.  
**Keep hidden:** 가방을 든 사람의 이름. **배지 소속이 곧 개인 신원이라는 결론은 금지.**

## CASE 09 — THE CLOCKWORK GARDEN

### v1.7 확정 명세 (2026-10-23, 사용자 승인 — 아래 v1.0 기획안보다 우선)
**상세:** `docs/SEASON2_CASE09_SPEC.md`(대사·피드백·힌트·Glossary), `docs/SEASON2_CASE09_ASSET_SPEC.md`(이미지 8장).  
**성격:** 8–12세가 5–7분에 끝내는 가벼운 사건. 퍼즐마다 조작은 5초 안에 이해 가능, 오답은 진행을 초기화하지 않음.  
**Location:** Luxembourg Gardens의 가상 모형 **Little Paris**(돌 받침 위 파리 지도 모형 + 기준 탑). 실제 정원 시설이 아니다. Map pin: Luxembourg Gardens.  
**Intro:** Case 08 `last_sketch_garden.png`를 다시 보여 주고 `Why was the same bag beside that little clock?`로 시작한다. 장소 찾기는 반복하지 않는다. 탑 시계에는 P.의 그림처럼 바늘이 없다.  
**Core deduction:** 시험 시계는 파리의 **세 곳뿐**이고, 기준 탑의 설정 하나가 **이어진 시계만** 함께 바꾼다.

- **M1 · The Little Paris (모형 3개 놓기):** 받침의 파리 지도(`paris_mystery.png`)에 시계 모형 3개를 모양으로 맞춰 놓는다. **T1** 아치 + 받침 **별** → Arc de Triomphe, **T2** 세 아치 다리 + 초록 책 가판대 + 받침 아치 세 개 → Seine Quays, **T3** 긴 홀 + 뾰족탑 하나 + 받침 종 → Arts et Métiers. 다른 랜드마크에는 시험 시계가 없다. **증거:** `Trial Map`.
- **M2 · The Gear Path (톱니 2개):** 크기가 다른 톱니 2개를 점선 자리 2곳에 끼우면 탑이 T1·T2·T3만 돌리고, 이어지지 않은 **정원 시계**는 움직이지 않는다. 문장 `The gears move the model. The real trial used wires.`(톱니는 모형의 방식, 실제 시험은 선). T1 아래 기록 드럼의 꼬리표 `TRIAL RECORDS · KEPT AT THE STAR`. **증거:** `Synchronisation Diagram`.
- **M3 · The Maker's Marks (표식 잇기):** Notebook의 두 표식을 화면에 직접 보여 주고(Recall 시스템 변경 없음) 서랍 속 Chronos 설계도의 같은 모양과 잇는다. **Case 01 톱니 표식 = Notebook clue `s2_ep01_c3`의 톱니 8개 아이콘** → 설계도 `CHRONOS TRIAL · EMBLEM`. **두 바늘**(`hands_sign.png`) → 핀으로 꽂힌 수리 메모 `REPAIRS · T2 WHEEL`(미끼: 열쇠 도장). 결론: 두 표식은 **서로 다른 종이**에서 나왔고, 같은 사람인지는 종이가 말하지 않는다. Case 01의 `letter M`은 인용·해석하지 않는다. **증거:** `Marks Key`.
- **Final · The Wrong Hour (4:00 → 3:00):** 탑에 바늘을 다시 끼우는 짧은 연출(이유·주체는 말하지 않음, **Case 07·08 도장과 연결하지 않음**) 뒤, 탑을 한 시간 뒤로(4:00 → 3:00) 돌리고 TEST. T1–T3만 3:00, 정원 시계는 4:00. 3지선다 정답 `Only the joined clocks went wrong.`(오답: 파리의 모든 시계 / 누가 설정했는지 앎). 직후 `The model shows what could happen. But what really happened?` **증거:** `The Wrong Hour Test`.
- **Case Closed · Next Lead (점수 없음):** 꼬리표의 별 → 별이 있는 모형 T1 탭 → 지도의 **Arc de Triomphe**. `Twelve roads meet there, like a star.`(실제 Place de l'Étoile).

**결론:** `One wrong setting can change several connected clocks.`  
**End hook:** `Was the hour lost — or was the clock wrong?` → Case 10.  
**연결 원칙 (v1.8):** Intro는 연필화 → 같은 구도의 정원 그림으로 이어 그림 속 장소·같은 가방(`The same bag was here. But why?`)·새 조사 대상(작은 시계)을 짚는다. M3 끝에서 Case 08의 시간 변경 종이와 이 장치의 관련을 **질문으로만** 남긴다(`Is it linked to this machine? We can't tell yet.`). Case Closed는 "모형은 가능성만 보여 준다 → 실제 기록이 필요하다 → 기록은 별(T1, Arc)에 있을 수 있다"(`The records may tell us.`)로 Case 10에 가야 하는 이유를 준다. 가방 속 내용물·운반자·방문 목적, 종이가 바꾼 기록, Case 10 결론은 쓰지 않는다.  
**새로 확정한 사실 (v1.7):** Little Paris 모형과 기준 탑, 시험 시계 T1 Arc · T2 Seine Quays · T3 Arts et Métiers(받침 표식 별·아치 세 개·종), 이어지지 않은 정원 시계, 실제 시험은 선(wires)을 사용, T1 아래 기록 드럼과 `KEPT AT THE STAR` 꼬리표, `CHRONOS TRIAL` 설계도의 EMBLEM(톱니 8개)과 No. 7 두 바늘이 찍힌 수리 메모(T2 바퀴).  
**미해결 단서 (Case 11 회수 예정):** 가방이 정원의 작은 시계 옆에 있었던 이유. Case 09에서는 `Why it came here, we still don't know.`까지만 말한다. **구체적 이유는 아직 정하지 않는다.**  
**Keep hidden (v1.7):** Émile의 실명, 두 표식이 같은 사람의 것인지, Clockmaker의 동기, Victor·삭제 승인, 실제 한 시간 소멸 여부(Case 10), 과거 시험 사고 날짜, 가방 운반자·가방이 정원에 온 이유, 방패 배지·보라색 도장의 의미, 탑 바늘이 빠져 있던 이유.  
**Boundary (§2.4):** Gare du Nord(Case 01)·Palais Garnier(Case 07)·Louvre(Case 06)·Eiffel(Case 03)·Notre-Dame(Clock III)은 시험 시계로 두지 않는다. 4:00 → 3:00은 실험값이며 과거 사고·Case 03·Case 07과 같은 사건이라고 말하지 않는다.

### v1.0 기획안 (참고용, v1.7 확정 명세로 대체됨)
**Location:** Luxembourg Gardens; miniature mechanism is fictional.  
**Opening question:** `Could one wrong setting affect several clocks?`

- **M1 · The Little Paris:** 정원 모형의 일부 랜드마크를 실제 지도와 대응해 **시험용 시계의 제한된 범위**를 알아낸다. **증거:** `Trial Map`.
- **M2 · The Gear Path:** 톱니의 회전 방향과 연결 순서를 직접 조작해 한 기준값이 **몇 개의 연결된 시험 시계**에 전달되는 과정을 실험한다. **증거:** `Synchronisation Diagram`.
- **M3 · The Maker's Marks:** Case 01 `The Clockmaker's Mark`(톱니 표식)과 Case 04/05 두 바늘 표식을 시험 장치 설계도에 대조한다. 플레이어는 증거로 다음을 확인한다. (1) 톱니 표식은 **Chronos 시험 장치 설계도의 문양과 같다** → Clockmaker가 과거 시험 사업과 관련 있다. (2) 두 바늘 표식은 설계도에 없는 **No. 7 수리 공방의 표식**이며, 설계도의 수리 기록에 등장한다 → No. 7 공방이 시험 장치 부품을 다뤘다. **증거:** `Marks Key`. 이 단계에서는 두 표식을 쓴 사람이 동일 인물이라고 결론내리지 않는다(동일 인물 확인은 Case 12).
- **Final · The Wrong Hour:** 한 기준값을 한 시간 잘못 설정하면 연결된 시계만 어긋나는 것을 실험으로 입증한다. **이것만으로 과거 기록 삭제 책임자는 알 수 없다.**

**End hook:** 시험망의 보존 기록 코드가 Arc de Triomphe 근처 기록 표식과 일치.  
**Keep hidden:** Émile의 실명, Clockmaker의 동기, Victor의 삭제 승인. (Clockmaker가 시험 사업과 연관 있다는 암시는 공개해도 된다.)

## CASE 10 — THE HOUR OF SHADOWS

### v1.9 확정 명세 (2026-10-24, 사용자 승인 — 아래 v1.0 기획안보다 우선)
**상세:** `docs/SEASON2_CASE10_SPEC.md` v1.1(대사·피드백·힌트·Glossary·해시계 시각 데이터), `docs/SEASON2_CASE10_ASSET_SPEC.md` v1.1(이미지 6장, 납품·검수 승인).  
**성격:** Case 09처럼 8–12세가 5–7분에 끝내는 사건. 오답은 진행을 초기화하지 않는다.  
**Location:** 개선문 지붕 아래의 가상 **Star Room**(문짝에 T1 받침과 같은 별, 벽의 황동 명판 `TRIAL RECORDS · KEPT AT THE STAR`) → 지붕(가상의 T1 기둥과 오래된 해시계). Map pin: Arc de Triomphe. 실제 개선문에 그런 방이 있다고 단정하지 않는다.  
**Intro:** Case 09의 별(T1 받침)과 꼬리표를 회수한다. `In the garden, we tested a model. These records are from the real trial.`로 **모형과 실제 기록을 구분**한다.  
**Core deduction:** 시험 시계 T1의 기록에는 3시가 없지만, 시험 시계가 아닌 시계들과 해는 그 한 시간이 흘렀음을 보여 준다. **한 시간은 사라지지 않았다. T1이 한 시간 늦게 표시했고, 그 시간의 기록부 쪽이 없다.**

**실제 시간 / T1 표시 (확정):** 드럼은 T1의 분침이 :00·:15·:30·:45에 닿을 때마다 T1의 시각을 찍는다(테이프는 일정 속도, 눈금 간격 = 실제 15분).

| 실제 | 2:00 | 2:15 | 2:30 | 2:45 | **3:00** | 3:15 | 3:30 | 3:45 | **4:00** | 4:15 |
|---|---|---|---|---|---|---|---|---|---|---|
| T1 = 테이프 | 2:00 | 2:15 | 2:30 | 2:45 | **2:00** | 2:15 | 2:30 | 2:45 | **4:00** | 4:15 |
| 기록 | Photo 1 (해 2:00) | | | | 변화 ①: 실제 3:00, 시침 한 시간 뒤로 | | Photo 2 (해·독립 시계 3:30) | | 변화 ②: 실제 4:00, 정상 복귀 | |

변화 ①·②의 원인·주체, 정각에 일어난 이유는 공개하지 않는다.

- **M1 · The Drum Tape (테이프 펼치기 + 점프 탭):** T1이 15분마다 찍은 테이프 `2:00 · 2:15 · 2:30 · 2:45 · 2:00 · 2:15 · 2:30 · 2:45 · 4:00 · 4:15`에서 시간이 건너뛰는 두 곳(두 번째 2:00, 4:00)을 찾는다. 테이프에는 3시가 없다. Case 01 `The Clockmaker steals an hour.`는 **질문으로만** 회상한다. **증거:** `T1 Drum Tape`.
- **M2 · A City of Clocks (돋보기 + 출처 분류):** Roof Photo 2(한 순간)의 시계 4개를 `TRIAL CLOCK`(T1, 기둥에 별) / `NOT A TRIAL CLOCK`(카페·성당·우체국)으로 나눈다. 분류 근거는 Case 09 `Trial Map`(장소·표식)뿐이고, Case 09 모형의 연동 동작은 쓰지 않는다. 분류 후 공개되는 시각: T1 2:30, 나머지 셋 3:30. **확정 범위: T1은 독립 시계보다 한 시간 늦었고, 독립 시계들은 서로 같은 시각이었다.** T2·T3의 상태는 확정하지 않는다. **증거:** `Independent Time Log`.
- **M3 · The Hour of Shadows (해 끌기 → 그림자 재현):** 지붕 해시계 위의 해 토큰(코드 아이콘 `InkGlyph.sun`, 이미지 없음)을 궤도를 따라 끌어, 그림자의 **방향과 길이**를 Photo 1·2 속 그림자와 같게 만든다. Photo 1: T1 2:00 = 해 2:00(해시계 신뢰 기준), Photo 2: T1 2:30, 해 3:30. `No one can set the sun.` Case 06 편지 `The clocks may lie.`는 인용만 한다. **증거:** `The Shadow Check`.
- **Final · The Hour Was Recorded (시간축 정렬 + 빠진 쪽 + 결론):** (1) Photo 1 핀(첫 2:00)을 기준으로 Photo 2의 순간을 테이프에서 탭한다 → **두 번째 2:30**(6눈금 = 1시간 30분). 해 시각 줄이 깔리며 t5–t8 아래에 3:00–3:45가 드러나고 변화 ①(3:00)·②(4:00)가 표시된다. (2) Trial Log 목차 p.1–4(p.3 = 3:00–4:00)와 실제 쪽 p.1·p.2·p.4를 비교해 p.3을 탭한다(쪽 본문은 읽히지 않음, **찢김·제본 흔적 없음**). (3) 3지선다 정답 `The hour was there. T1 was one hour behind, and the page about it is missing.`(오답: 시간이 사라졌다 / 파리의 모든 시계가 늦었다). 직후 `In the garden, a model showed what could happen. This tape shows what happened to T1.` **증거:** `The Hour Was Recorded`.
- **Case Closed · Next Lead (점수 없음):** Case 03 회상 **한 번**(`At the Eiffel Tower, an old time-recording machine hid a plaque: ONE HOUR IS MISSING. THE CLOCK IS STILL RUNNING. Was it about this hour? We don't know yet.`). Trial Log 뒤표지 안쪽 RECORD LIST의 `p.3 · SENT TO: SAINT-SULPICE · ARCHIVE ANNEX` 줄을 탭 → 지도의 Luxembourg Gardens 북쪽 끝 `Saint-Sulpice`. `SENT TO`는 **목록에 적힌 목적지일 뿐**이며 실제 도착 여부는 확정하지 않는다(`Is page 3 really there? Who sent it, and why? The list doesn't say.`).

**결론:** `The hour was there. T1 was one hour behind, and the page about it is missing.`  
**End hook:** `Who sent page 3 away — and why?` → Case 11.  
**새로 확정한 사실 (v1.9):** Star Room·지붕 위 T1 기둥·지붕 해시계(모두 가상), 기록 4종(T1 드럼 테이프, 같은 자리에서 찍은 지붕 사진 2장, Trial Log p.1·p.2·p.4, RECORD LIST), 위 실제 시간/T1 표시 표, Trial Log 3쪽(3:00–4:00)이 책에 없음, RECORD LIST상 3쪽의 목적지 `SAINT-SULPICE · ARCHIVE ANNEX`. 기록 드럼은 Case 03 시간 기록 장치와 다른 장치다(연결 암시 금지).  
**Keep hidden (v1.9):** 3쪽의 실제 내용, 3쪽을 보낸 사람·이유, 기록이 사라진 정확한 경위, 3쪽의 실제 도착 여부, 제본 흔적, T1이 틀린 원인과 책임자, 4:00에 고친 주체, **T2·T3의 실제 시험 결과**, Émile·Victor 관련 반전, Clockmaker의 정체, Case 03 명판을 남긴 사람, 과거 시험 사고 날짜, 가방·방패 배지·보라색 도장. `removed` / `THE RECORD WAS REMOVED`는 쓰지 않는다.  
**Boundary:** Case 09 모형에서 T1–T3이 함께 움직인 것을 과거 사건의 증거로 쓰지 않는다. 결론은 T1에 한정한다. Case 01 역 시계(현재 한 시간 늦음)와 과거 T1을 같은 원인으로 말하지 않는다(§2.4).

### v1.0 기획안 (참고용, v1.9 확정 명세로 대체됨)
**Location:** Arc de Triomphe area; fictional trial marker and exhibit.  
**Opening question:** `Was the hour lost — or was the clock wrong?`

- **M1 · A City of Clocks:** 여러 장소의 시간 기록을 **독립적인 기록**과 **시험망 기록**으로 분류한다. 단순 시간 배열 반복이 아니라 출처 신뢰도를 구분한다. **증거:** `Independent Time Log`.
- **M2 · The Signal Table:** 모형의 기준값을 변경하고 시험용 시계들이 함께 어긋나는 모습을 관찰한다. **증거:** `Signal Test Result`.
- **M3 · The Missing Entry:** 공식 요약표의 페이지 번호와 보존 목록을 비교해 **15:00–16:00 구간의 원본 기록이 누락**되었음을 찾는다. **증거:** `Missing Page Reference`.
- **Final · The Hour Was Recorded:** 독립 기록과 시험망 기록을 비교하여 **물리적 시간 소멸은 없었고, 잘못된 시계 표시와 삭제된 기록이 문제**라는 결론을 도출한다.

**End hook:** 누락 페이지의 보존 목록에 `SAINT-SULPICE · ARCHIVE ANNEX` 표시.  
**Keep hidden:** 누가 삭제를 승인했는지, 에밀이 왜 단서를 남겼는지.

## CASE 11 — THE UNWRITTEN HOUR

### v2.0 확정 명세 (2026-10-26, 사용자 지시에 따른 어린이용 단순화 — 아래 v1.0 기획안보다 우선)
**상세:** `docs/SEASON2_CASE11_SPEC.md` v1.0(대사 영·한, 판정, 힌트, Glossary), 이미지 `docs/SEASON2_CASE11_12_ASSET_SPEC.md` v1.0.
**핵심 질문:** `Who hid the truth?` · **결론:** `Victor hid the truth.` · **Location:** Saint-Sulpice 인근 가상 Archive Annex. Map pin: Luxembourg Gardens.
**Intro:** Victor Delacroix가 별관에서 옛 시험 서류를 보고 있다. 서류들이 곧 봉인되기 전에 마지막으로 보러 왔다. 방명록에 서명한다(곡선 V, 긴 밑줄, 끝의 점 — M3 단서).
- **M1 · The Missing Page:** Victor는 `There was no page 3.`라고 말한다. 별관의 큰 장부에서 한 장이 찢겨 나갔다. 다음 장을 연필로 문지르면 눌린 글씨가 드러난다: `Page 3 → Box 9.` / `Lock it. No one may read it.` 그 아래 서명. 선반에서 9번 상자를 찾는다(상자에 보라색 도장 봉인). Case 10 `The Hour Was Recorded`로 사라진 쪽임을 확인한다. **원본 3쪽 4줄:** `3:00 The clocks are wrong! One hour behind!` / `3:10 E.M.: "Stop the test!"` / `3:20 V.D.: "No. Keep going."` / `4:00 E.M. stops the machine.` Victor는 V.D.가 자신이라고 인정하고, E.M.은 기계를 다루던 사람이며 오래전에 떠났다고 말한다. **증거:** `Page 3`.
- **M2 · Two Papers:** Victor's paper(`The test began at 1:00.` / `All the clocks were fine.` + 보라색 도장). 2번 줄을 Page 3 또는 T1 Drum Tape로 반박한다. Victor의 말 `My office never changed any papers.`는 **Case 07 수정 슬립의 도장 = Victor 서류의 도장**으로 반박한다(오페라 기록을 바꾼 이유와 공연 날짜는 정하지 않음). `Which paper tells the truth?` → Page 3. **증거:** `Victor's Paper`.
- **M3 · Who Signed It?:** 문지른 서명을 투사지(Case 05)로 따라 그려 방명록 서명 3개와 비교한다 → Victor. **증거:** `Victor's Name`. 도장은 사무실 것(누구나 사용 가능)이고, 서명은 사람의 것이다.
- **Final · Victor's Truth:** 질문 3개(3시에 무슨 일이? / 누구의 서류가 거짓? / 누가 숨기라고 서명했나?)에 증거를 하나씩 제시한다. 고백: `Yes. I hid the page.` / `The test was my job.` / `The clocks went wrong.` / `I was afraid.` / `I didn't want people to know.` 선택 질문(증거 제시): Bag Sketch → `That's one of our office bags. It took page 3 here.`, The Torn Hour → `That's our form for changing a time.`, Wrong Hour Test → `That little model showed the mistake. I wanted the tests to stop.` **가방을 든 사람과 바늘을 뗀 사람은 정하지 않는다.** 올해 시계는 바꾸지 않았다(`Not one clock.`). **증거:** `Victor's Truth`.
- **Case Closed:** `Maybe E.M. knows. His old machine is at Arts et Métiers.` → 지도 Arts et Métiers.

**End hook:** `Who left the clues for me?`
**새로 확정한 사실 (v2.0):**
- Victor는 봉인 전 마지막 열람차 별관에 왔다.
- 3쪽은 별관 9번 상자에 봉인되어 있었고, 별관 장부의 해당 쪽(숨기라는 지시와 Victor의 서명)은 찢겨 나갔다.
- 원본 3쪽 4줄과 이니셜 E.M./V.D., 4:00에 E.M.이 기계를 멈췄다.
- 바늘 없는 시계 + 잎 도장 = **Victor의 시험 사무실 도장**(개인을 가리키지 않음). Case 07 오페라 기록 변경은 그 사무실이 했다.
- Victor's paper(요약 기록)는 시계가 괜찮았다고 거짓으로 적었다.
- 방패 배지 가방 = 사무실 가방이며 3쪽을 별관으로 옮겼다. Case 08의 떨어진 종이 = 사무실의 시각 변경 양식.
- Victor는 시험이 멈추길 바랐다(정원 모형의 바늘이 없던 이유와 연결).

**Keep hidden / 미확정 (v2.0):** E.M.의 이름·얼굴(Case 12), 가방을 든 사람, 바늘을 뗀 사람, 장부 쪽을 찢은 사람(암시만), 오페라 기록을 바꾼 구체적 이유, Case 08 종이의 FILE 번호·시각, 시험 날짜, 별도 "경고 보고서"(3쪽의 경고 줄로 대체).
**v1.0 기획안에서 바뀐 것:** 제본 흔적·보존 코드 → 찢긴 장부 쪽 문지르기 / 원본·수정본 대조 → Victor's paper 1줄 + 도장 비교 / 승인 코드·부서 직인 → 서명 비교 / 과거·현재 타임라인 → 증거 3회 제시와 고백.

### v1.0 기획안 (참고용, v2.0 확정 명세로 대체됨)
**Location:** fictional archive annex in the Saint-Sulpice area (map anchor remains Luxembourg Gardens).  
**Opening question:** `Who ordered the missing pages removed?`

- **M1 · The Torn Register:** 제본 흔적·연속된 페이지 번호·보존 코드로 누락된 원본 묶음을 찾는다. **증거:** `Original Test Log` (15:00–16:00 오류와 중단 요청).
- **M2 · Two Versions:** 원본과 공식 수정본을 대조해 **시험 실패와 경고 보고가 삭제**되었음을 확인한다. **증거:** `Altered Summary`.
- **M3 · The Approval Trail:** 문서의 승인 코드·날짜·부서 직인을 따라 **Victor Delacroix가 삭제를 지시한 문서**를 찾는다. **증거:** `Removal Order`.
- **Final · The Missing Hour Timeline:** 시험 시작 → 기준값 오류 → Émile의 경고 → Victor의 삭제 지시 → 공식 보관본 변경을 증거에 맞춰 재구성한다. 과거 사건과 현재 단서 배치를 구분해야 정답 처리.

**End hook:** 원본 장치와 최종 검증 기록이 Arts et Métiers의 특별 보존 목록에 있음.  
**Reveal:** Victor의 기록 삭제 책임이 강하게 입증됨. **Émile이 현재 시계를 왜 바꿨는지는 Case 12까지 유보.**  
**Evidence rule:** Victor의 책임은 승인 코드·부서 직인·원본/수정본 대조처럼 **에밀과 독립적인 문서**로만 입증한다. 런던 사건의 범인인 에밀(Clockmaker)의 진술이나 그가 남긴 단서만으로 Victor를 지목하지 않는다. 플레이어는 에밀이 문서를 꾸몄을 가능성도 독립 기록(Case 07 무대 큐카드, Case 10 독립 시간 기록, Case 11 승인 기록)으로 배제할 수 있어야 한다.

## CASE 12 — THE CLOCKMAKER'S TRUTH

### v2.0 확정 명세 (2026-10-26, 사용자 지시에 따른 어린이용 단순화 — 아래 v1.0 기획안보다 우선)
**상세:** `docs/SEASON2_CASE12_SPEC.md` v1.0, 이미지 `docs/SEASON2_CASE11_12_ASSET_SPEC.md` v1.0.
**핵심 질문:** `Who is the Clockmaker?` / `Why did he leave the clues?` · **Location:** Arts et Métiers의 가상 옛 기계 방(옛 시험 기계, 벽시계, 작업대). Map pin: Arts et Métiers.
**Intro:** 기계의 작은 시계 셋이 벽시계보다 한 시간 늦다. 등을 돌린 사람이 돌아선다(얼굴 공개, 이름표 `???`). `You came. Good.`
- **M1 · What's His Name?:** Case 05 Clock III의 덧붙인 작은 바퀴(살 4개)와 같은 바퀴를 기계 안 3개 중에서 고른다. 그 옆 이름표 `Made by Émile Moreau` + 두 바늘 도장 → **E.M. = Émile Moreau**(증명 ① Émile이 그 바퀴를 만들었다). **증거:** `The Name Tag`.
- **M2 · Who Is the Clockmaker?:** Season 1 Clockmaker의 회중시계(`ep12_e4`)를 열면 안에 **같은 바퀴**(증명 ②). `But wait. Anyone can use a wheel.` → 작업대의 Émile 도구 중 **끝이 톱니 8개인 작은 도장**을 종이에 눌러 Case 01 `The Clockmaker's Mark`와 비교 → 같은 표식(증명 ③ 도구 흔적). 세 증거를 놓은 뒤 `Who is the Clockmaker?` → Émile. 그 뒤 대화로 확인: `You made this wheel.` / `Yes, I did.` / `It's inside the Clockmaker's watch.` / `That's right.` / `And your tool makes his mark.` / `You found it.` / `You're the Clockmaker!` / `Yes. I am.` **이유(질문·답변):** `Why did you stop Big Ben?` → `I wanted people to look.` / `Look for what?` → `The missing page.` / 빅벤 아래 비밀 상자 속 숨겨진 서류 목록, 빅벤이 멈춰야 열림 / `But you scared people.` → `I know. I was wrong.` · `Why didn't you find page 3 yourself?` → `I didn't know where it was.` / `And people didn't believe me.` / `Even if I found it… they'd say I made it up.` · `Why did you leave clues for me?` → `You stopped me with clues.` / `People trust clues.` / `So I left clues for you.` · 선택: `Old test papers were kept at the star.` / `I hoped they'd point to page 3.` · 선택: 역 시계, Clock III, 편지를 숨김, `That was wrong.` **증거:** `The Clockmaker's Mark Tool`.
- **M3 · Fix the Machine:** 시험 날 Émile이 기계를 멈추고 세 시계를 손으로 고쳤지만, Victor가 시험을 모두 멈춰 기계는 틀린 채 남았다. 카드 `Stop · Turn · Fix(pin) · Start`로 벽시계(시험 시계 아님)에 맞춘다. 바뀐 것은 이 기계뿐이다. **증거:** `The Fixed Machine`.
- **Final · The Final Case Board:** `Did Paris lose an hour?` → `No. The clocks were wrong.` / `What was hidden?` → `Page 3 about the clocks.` / `Who hid it?` → `Victor.` / `Who is the Clockmaker?` → `Émile.` / `Why did Émile leave clues?` → `He wanted us to find the truth.`(증거: Case 06 편지) / `Was it OK to scare people?` → `No. He made bad choices.` **증거:** `The Case File`.
- **Ending:** Victor의 기록(Case 11 진술 카드, Victor 미등장) `"Yes. I hid the page."` → Émile `And I made bad choices.` / `I scared people. I'm sorry.` / `I will tell everyone what I did.` → 탐정 `The clocks were wrong.` / `Victor hid the truth.` / `Émile left the clues.` / `But now everyone can know.` → `Page 3 goes into a glass case.` / `No one can hide it again.` → `The hour was never gone.` / `The truth was waiting to be found.` → `CASE CLOSED.`

**새로 확정한 사실 (v2.0):**
- 기계 바퀴 이름표 `Made by Émile Moreau`(두 바늘 도장). Clock III의 덧붙인 바퀴는 Émile이 만드는 같은 바퀴다(Box 23 부품이 Clock III에 들어갔다고는 말하지 않음).
- Clockmaker의 회중시계 안에 그 바퀴가 있다(각인 없음).
- Émile의 톱니 도장 도구가 Case 01 Clockmaker 표식을 만든다 → 톱니 표식과 두 바늘 표식은 같은 사람(Case 05 열린 질문 해결).
- 기계는 시험 날 이후 틀린 채 남았다(Émile이 지난주 다시 조작했다는 안은 폐기).
- Émile은 3쪽이 숨겨진 것은 알았지만 위치는 몰랐다. 시험 기록이 Star Room에 보관된다는 것만 알았다.
- 찾아도 "꾸며 냈다"는 말을 들을 것이라 탐정이 증거로 찾게 했다.
- 3쪽은 봉인되는 대신 유리 상자에 보존되어 누구나 볼 수 있다(결정한 사람은 말하지 않음).

**Keep hidden / 미확정 (v2.0):** Big Ben이 멈춰야 하는 정확한 위치(§2.6), 보관함 자료의 경위·현재 상태, 편지 4417 보존 지시자, Case 07 익명 그림 쪽지·`P. KNEW THE BAG.`·슬립이 배경막 뒤에 있던 이유, Case 03 명판을 남긴 사람(Émile의 `I left clues for you.`로 포괄), P.의 행방, Case 01 `letter M`(TIME 자물쇠 글자, 재해석 금지), 처벌·체포 장면.
**v1.0 기획안에서 바뀐 것:** M1 Box 23 부품 대조 → 바퀴 비교 + 이름표 / M2 `Émile's Statement + Victor's Order` → 바퀴·시계·톱니 도장(진술은 증거 뒤 확인용) / M3 정상화 퍼즐 유지 / Final 5질문 → 쉬운 5질문 + 잘못 확인 1문항 / 엔딩에 기록 보존 장면 추가.

### v1.0 기획안 (참고용, v2.0 확정 명세로 대체됨)
**Location:** Arts et Métiers, fictional special conservation exhibit.  
**Opening question:** `Who changed the clocks, who erased the records — and why?`

- **M1 · The Original Machine:** Box 23에서 온 부품 종류, Clock III의 황동 바퀴, 시험 장치 도면을 대조해 **부품은 원본 장치의 수리·검증용**이었음을 확인한다. **증거:** `Machine Parts Record`. Box 23 부품이 반드시 Clock III에 장착됐다는 식의 소급 주장은 금지.
- **M2 · The Two Responsibilities:** Clockmaker(Émile)의 런던 사건·파리 시계 조작 인정 진술과 Victor의 과거 기록 삭제 지시서를 **서로 다른 행위**로 분리해 증명한다. 에밀의 동기가 사실이라는 것이 그의 런던 범행을 지워 주지 않고, 에밀의 범행이 Victor의 삭제 책임을 지워 주지도 않는다. **증거:** `Émile's Statement` + `Victor's Order`. 이 단계에서 톱니 표식(설계 문양에서 유래한 에밀의 상징)과 두 바늘 표식(No. 7 공방)이 같은 인물에게 이어진다는 것을 도구 흔적·기록으로 확인한다.
- **M3 · Set the True Time:** 기준 시각이 잘못된 시험용 모형을 정상값으로 되돌리는 조작형 퍼즐. 현실 도시 시계가 자동 복구되는 장면이 아니라 **전시된 시험 장치의 정상 작동**을 확인한다. **증거:** `Verified Clock Reading`.
- **FINAL · THE FINAL CASE BOARD:** Case 01–12의 주요 증거를 연결해 다섯 질문에 답한다.
  1. `Did an hour really disappear?` → No; time passed normally. (Case 01의 `The Clockmaker steals an hour`는 초기 해석이었다.)
  2. `What was removed?` → The 3:00–4:00 trial record and warning.
  3. `Who ordered the removal?` → Victor Delacroix.
  4. `Who is the Clockmaker who stopped Big Ben in London and changed clocks in Paris?` → Émile Moreau.
  5. `Why?` → To bring the hidden record to light before the archive was sealed — but that did not make his actions right.

**Final moral:** 에밀이 드러내려던 진실은 사실이었지만, 그 목적이 런던에서 저지른 일과 파리에서 사람들을 혼란스럽게 한 일을 정당화하지 않는다. 에밀은 두 도시에서 한 행동의 책임을 인정한다(구체적 법적 처벌 장면은 묘사하지 않는다). Victor의 기록 삭제 책임은 에밀의 잘못과 별개로 증거로 입증된다. 탐정은 추측이나 직함, 범인의 말이 아니라 증거로 진실을 밝혔다.

**Closing English story (draft, adaptable for age-level):**

> The great clock ticks again.  
> The Detective places the original record beside the altered one.  
> “Paris never lost an hour,” the Detective says.  
> “Someone hid what happened during it.”  
> Émile nods. “I stopped clocks in London. I changed clocks in Paris. I wanted people to look.”  
> “It was wrong,” he says. “I should have told the truth another way.”  
> The missing pages are returned to the record.  
> Outside, the clocks keep ticking.  
> **The hour was never gone. The truth was waiting to be found.**  
> **CASE CLOSED.**

**Do not imply:** 모든 파리 시계가 하나의 버튼으로 복구된다거나 Victor가 이미 법적으로 유죄 확정되었다는 장면. 에밀이 런던 사건에 대해 용서받았거나 처음부터 선한 인물이었다는 장면.

---

# 7. 전 시즌 증거 회수표 (setup → payoff)

| Early clue | First appearance | Payoff | What it actually proves |
|---|---|---|---|
| Clockmaker's London plan (Raven Society, Big Ben) | Season 1 | Case 12 | 에밀의 런던 범행; 동기는 Case 12에서 설명되지만 정당화되지 않음 |
| Clockmaker's door under Big Ben | Season 1 Case 12 | Case 12 | 문 뒤는 에밀의 작업실; 그 안의 별도 보관함(Big Ben 정지로 해제)에 파리 시험 설계도 일부·기록 색인이 있었다는 배경(§2.6). 에밀은 열지 못함. Season 2 퍼즐 풀이 증거로는 쓰지 않음 |
| Real gear kept safe (Big Ben rings at midnight) | Season 1 Case 12 | Case 12 | 시계 장치가 멈추지 않아 보관함 잠금이 해제되지 않은 이유 |
| `PARIS` on Clockmaker's watch | Season 1 ending | Case 01, 12 | 런던에서 저지된 Clockmaker가 남긴 파리 수사로의 초대 |
| One-hour-late station clock | Case 01 | Case 09–10, 12 | 현재 특정 시계의 의도적 조정; 시간 소멸의 증거 아님 |
| `The Clockmaker steals an hour` | Case 01 | Case 10, 12 | 플레이어의 초기 해석; 실제로 삭제된 것은 사고 기록의 한 시간 |
| Gear mark (`The Clockmaker's Mark`) | Case 01 | Case 09, 12 | 시험 장치 설계 문양에서 유래, 에밀이 자신의 상징으로 사용. *(v1.7)* Case 09에서 Notebook clue의 톱니 8개 아이콘 = `CHRONOS TRIAL` 설계도 EMBLEM으로 확인 |
| `I saw who took the hour` | Case 02 | Case 08, 12 | 기록을 옮긴 목격; 개인 얼굴 식별 아님 |
| Eiffel 4:00 vs 3:00 | Case 03 | Case 07, 10 | 기록의 불일치와 수정 가능성에 대한 단서 |
| Service Level / missing box | Case 03 | Case 04–05, 12 | 부품 운송 경로 |
| Box 23 `CLOCK PARTS` | Case 04 | Case 05, 12 | 원본 장치의 수리·검증 부품 이동 |
| Two-hands mark | Case 04–05 | Case 09, 12 | No. 7 수리 공방의 표식; Case 09에서는 gear mark와 동일인 단정 금지(설계도의 수리 메모 `T2 WHEEL`에 찍힘, v1.7), Case 12에서 같은 인물로 확인 |
| Backward Clock III | Case 05 | Case 09, 12 | 개별 개조 시계와 제작자의 기술 |
| Letter No. 4417 | Case 05 | Case 06–07 | 보류된 편지의 이동 경로 및 삭제 기록 색인 |
| Modified opera record | Case 07 | Case 08, 11 | 기록 수정 패턴과 사업 부서 연결 |
| Stage Cue Card (CURTAIN UP · 4:00) | Case 07 | Case 11 | 사무실 기록과 독립된 무대 기록; 수정되지 않은 원래 시작 시각 |
| Amendment Slip stamp (바늘 없는 시계 + 월계관, 이름 없음) | Case 07 | Case 08, 11 | 수정 승인 문양; Case 08에서 찢긴 종이의 도장과 같음을 확인(같은 양식의 시간 변경 문서), 부서 표식과의 대응은 Case 11, 개인 신원 단정 금지 |
| P.'s bag and badge sketch (`The Bag Sketch`: 납작한 서류 가방, 버클 2개, 방패 배지 + 테두리 잎) | Case 08 | Case 11–12 | 문서 이동과 소속 단서; 배지 의미는 Case 08에서 해석하지 않음, 인물 단정 금지 |
| Torn time-change paper (`The Matching Seal` / `The Torn Hour`: FILE 번호·시 숫자 찢김, `:00 →`) | Case 08 | Case 11–12 (미확정) | 가방이 시간 변경 양식의 종이를 운반했다는 물증; 대상 기록은 미확정 |
| P.'s last sketch (같은 가방 + 정원의 작은 모형 시계) | Case 08 | Case 09 | 다음 조사 장소(Luxembourg Gardens)의 물증; 모형의 기능은 Case 09에서 |
| Trial map and gear diagram | Case 09 | Case 10, 12 | 제한된 시험망의 작동 방식. *(v1.7)* 시험 시계 T1 Arc · T2 Seine Quays · T3 Arts et Métiers, 기록 꼬리표 `KEPT AT THE STAR` → T1 |
| Why the bag was beside the little clock (P.'s last sketch) | Case 08–09 | Case 11 | *(v2.0)* 가방 = Victor 사무실 가방(3쪽을 별관으로 옮김). Victor는 모형이 실수를 보여 주므로 시험이 멈추길 바랐다 → 정원 탑의 바늘이 없던 이유. 가방을 든 사람·바늘을 뗀 사람은 미확정 |
| Independent time log | Case 10 | Case 12 | 실제 시간 소멸 부정. *(v1.9)* `T1 Drum Tape`(3시 없음, 2시대 두 번) + `Independent Time Log`(Photo 2: T1 2:30, 시험 시계가 아닌 시계 셋 3:30) + `The Shadow Check`(해 2:00 / 3:30) → `The Hour Was Recorded`. T1에 한정, T2·T3 미확정 |
| Trial Log p.3 missing / RECORD LIST `SENT TO` | Case 10 | Case 11 | *(v1.9)* 3:00–4:00 쪽이 Star Room의 책에 없음. 목록상 목적지 `SAINT-SULPICE · ARCHIVE ANNEX`(도착 여부·보낸 사람·이유·내용 미확정) |
| Original test log / removal order | Case 11 | Case 12 | Victor의 삭제 지시와 Émile의 경고. *(v2.0)* 원본 3쪽(E.M. "Stop", V.D. "Keep going"), 찢긴 장부 쪽의 지시·서명(문지르기) |
| *(v2.0)* Office stamp ↔ Victor's paper | Case 07–08 | Case 11 M2 | 바늘 없는 시계 + 잎 = Victor 사무실 도장. 오페라 기록 변경도 그 사무실(이유·날짜 미확정) |
| *(v2.0)* Torn time-change paper | Case 08 | Case 11 Final | 사무실의 시각 변경 양식. 사무실 가방에서 떨어짐. FILE 번호·시각 미확정 |
| *(v2.0)* Émile's small wheel | Case 05 | Case 12 M1–M2 | Clock III 바퀴 = 기계 바퀴(이름표 É. Moreau) = Clockmaker 시계 속 바퀴 |
| *(v2.0)* Gear mark ↔ two hands | Case 01·05 | Case 12 M2 | Émile의 톱니 도장이 Clockmaker 표식을 찍음 → 같은 사람 |
| *(v2.0)* `PARIS` watch | Season 1 → Case 01 | Case 12 M2 | 열면 Émile의 바퀴. 정체 증명 ② |

**Notebook design principle:** 매 Case 최소 1회 이미 얻은 단서를 실제 풀이에 활용한다. 플레이어가 증거를 기억 못 해도 Notebook에서 다시 확인 가능해야 한다. 앞선 Case를 재플레이해야만 풀 수 있는 구조는 금지.

---

# 8. 미스터리 공개 단계 (스포일러 관리)

| Through Case | Player can conclude | Must NOT reveal yet |
|---|---|---|
| Season 1 | Clockmaker라는 범인이 런던 계획을 세웠고 저지됐다, 시계에 PARIS | 실명, 과거 시험 사업, 동기 |
| 01 | 특정 시계가 한 시간 늦다, Clockmaker의 표식이 있다 | 원인, Clockmaker 실명·동기 |
| 02 | 화가가 무언가를 목격했다 | 목격자의 대상·얼굴 |
| 03 | 기록 불일치, 서비스 구역 출입 | 실제 시간 소멸 단정, 기록 삭제 주체 |
| 04 | 시계 부품이 No. 7로 운송됨 | 부품의 최종 용도 |
| 05 | 4417 편지가 16 MAY 4:00 PM Louvre에서 보류됨 | 편지 내용·보류자·보류 이유 |
| 06 | 편지는 도난이 아니라 Preservation Order로 보류됐고(16 MAY 4:00 PM), 다음 날 아침 archive로 옮겨졌다. 편지 `The clocks may lie. / But the show remembers.`와 오페라 극장 그림, 뒷면 `OPERA ARCHIVE · FILE 3–4` | 작성자·삭제 지시자, 보존 지시자, `THE RECORD WAS REMOVED` (v1.4: 시즌 후반 반전으로 보류) |
| 07 | 오페라 기록(FILE 3)의 CURTAIN UP이 4:00에서 3:00으로 사후 수정됨(덧붙인 종이 아래 원래 4:00), 수정 슬립과 바늘 없는 시계 + 월계관 도장, 슬립 뒷면 `ABBESSES` 스케치와 `P. KNEW THE BAG.` | 수정자·지시자·이유, 그림 쪽지 작성자, 슬립이 배경막 뒤에 있던 이유, P.와 배경막의 관계, Victor의 최종 책임과 모든 이름·이니셜 |
| 08 | 화가가 본 것은 기록 가방을 옮기는 행위. 그 가방에서 Case 07 슬립과 같은 양식·도장의 **시간 변경 종이**가 떨어졌다(`A paper for changing a time fell from the bag.`). 가방에는 방패 배지가 있다. 같은 가방이 정원의 작은 모형 시계 옆에 있었다 → Luxembourg Gardens | 얼굴·개인 신원·소속, 배지 의미, 종이의 대상 기록과 시각, 기록 변경자·지시자, 모형 시계의 기능(Chronos 시험), 그림 날짜 |
| 09 | 일부 시험 시계가 하나의 기준값에 연결될 수 있음(시험 시계는 세 곳, 잘못된 설정 하나가 이어진 시계만 함께 바꿈), Clockmaker의 톱니 표식이 시험 장치 설계 문양과 같음, 두 바늘은 No. 7 수리 메모에 있음(서로 다른 종이), 별 표식 → Arc de Triomphe | Clockmaker 실명·동기, 두 표식의 동일인 여부, 삭제 책임, 실제 시간 소멸 여부, 가방이 정원에 온 이유 |
| 10 | 시간이 실제로 사라진 것은 아님. *(v1.9)* 과거 시험 날 실제 3:00–4:00 동안 T1은 한 시간 늦게 표시했고 4:00에 정상으로 돌아왔다. 시험 시계가 아닌 시계들과 해가 그 시각을 증명한다. Trial Log 3쪽(3:00–4:00)이 없고, 목록상 목적지는 Saint-Sulpice Archive Annex | 삭제 승인자, 3쪽 내용·보낸 사람·이유·도착 여부, T1이 틀린 원인·책임자, T2·T3 결과, 제본 흔적, Émile·Victor·Clockmaker 관련 |
| 11 | Victor가 과거 삭제를 승인함. *(v2.0)* 시계가 틀렸다(3쪽), Victor's paper는 거짓, 사무실 도장, Victor의 서명, 고백(두려워서). 3쪽의 E.M.이 "멈춰요"라고 했다 | Émile의 현재 행동 동기 전체. *(v2.0)* E.M.의 이름·얼굴, Clockmaker, 런던 |
| 12 | Clockmaker = Émile, 런던 계획의 목적(작업실 안 보관함의 파리 시험 자료와 Big Ben 정지 잠금 원리), 런던·파리 행동의 동기와 책임, Victor의 별개 책임, 전체 진상. *(v2.0)* 얼굴(Intro) → 이름(M1) → Clockmaker 동일인(M2) → 동기(M2 질문) 순 | 모두 공개 (§2.6 미확정 항목은 확정 전 언급 금지) |

---

# 9. 사건 연결의 필수 인과관계

1→2 **그림과 분실 티켓**이 Montmartre를 가리킨다.  
2→3 **탑 스케치와 TOUJOURS PLUS HAUT**가 Eiffel Tower를 가리킨다.  
3→4 **SEINE 명판과 운송표**가 강을 가리킨다.  
4→5 **Box 23의 주소와 두 바늘 표식**이 No. 7을 가리킨다.  
5→6 **Letter 4417의 HELD · LOUVRE POST ROOM**이 Louvre를 가리킨다.  
6→7 **편지의 오페라 극장 그림과 뒷면 `OPERA ARCHIVE · FILE 3–4`**가 Palais Garnier를 가리킨다.  
7→8 **수정 슬립 뒷면의 P. 스케치(`ABBESSES`)와 `P. KNEW THE BAG.`**가 Abbesses를 가리킨다.  
8→9 **화가의 정원 모형 스케치**가 Luxembourg Gardens를 가리킨다. *(v1.6)* 마지막 그림 속 가방이 Bag Sketch와 같은 가방(납작함, 버클 2개, 방패 배지)이고, 그림의 궁전·분수가 있는 둥근 연못·꽃밭이 지도의 Luxembourg Gardens와 일치한다.  
9→10 **시험망 기록 코드와 Arc de Triomphe의 표식**이 다음 자료를 가리킨다. *(v1.7)* M2 기록 꼬리표 `TRIAL RECORDS · KEPT AT THE STAR`의 별이 M1 시계 모형 T1의 받침 별과 같고, T1은 지도의 Arc de Triomphe에 놓여 있다.  
10→11 **누락 페이지 보존 목록**이 Saint-Sulpice 인근 기록실을 가리킨다. *(v1.9)* Trial Log 뒤표지 안쪽 RECORD LIST의 `p.3 · SENT TO: SAINT-SULPICE · ARCHIVE ANNEX`. 목록에 적힌 목적지일 뿐이므로, 3쪽이 실제로 거기 있는지는 Case 11에서 확인한다.  
11→12 **원본 장치 보존 목록**이 Arts et Métiers를 가리킨다. *(v2.0)* 원본 3쪽의 E.M.이 "기계를 멈췄다"는 기록, Victor의 `His old machine is at Arts et Métiers.`(곧 봉인될 서류와 같은 목록), 지도에서 Case 09 T3 자리.

**원칙:** 다음 장소는 우연히 발견하지 않는다. 각 Case의 Final이 다음 장소로 갈 **검증 가능한 물증**을 남긴다.

---

# 10. Case 06 구현 전 상세 확정 체크리스트

이 문서는 **전체 스토리 바이블**이다. 아직 Case 06 코드·퍼즐 UI·정확한 대사·에셋은 작성하지 않는다. 실제 구현 전 다음을 별도 세부 명세로 확정한다.

1. Case 06의 가상 우편 보관실이 Louvre **구역**에 있다는 문구와 지도 라벨.
2. Case 05 우편 슬립 번호 **4417**과 세 시간(16 MAY)의 원문 보존. Case 06 시점은 Case 05 이후. 보류는 16 MAY 4:00 PM, 사유 Preservation Order 확정; 지시자·구체적 이유, 이동 날짜·담당자, 현재 보관 위치를 확정.
3. 도난이 아닌 보류임을 보여 주는 근거(`PRESERVATION ORDER`), 그리고 `HELD`(16 MAY 4:00 PM)와 이후 `TRANSFERRED`를 구별하는 문서상 근거. M2 진술은 이동 날짜·담당자 확정 후 작성.
4. M1–M3·Final의 관찰 순서, 정답의 유일성, 오답 피드백, 힌트, Notebook 증거 접근.
5. Case 07 `OPERA ARCHIVE · FILE 3–4` 단서가 Case 06 Final에서 실제로 드러나는지.
6. 필요한 신규 이미지: 우편 보관함, 보류 태그, 이동 장부, 눌린 글씨 봉투 등. 각 이미지의 용도·크기·투명 배경 여부·권장 경로·생성 프롬프트를 사용자에게 **먼저 요청**.
7. 미션별 영어 문장은 8–12세가 이해 가능한 길이·어휘로 작성. 어려운 단어는 glossary로 지원.
8. Case 01–05와 Season 1의 저장·라우팅·보상·지도·게이트를 변경하지 않는다.
9. 관련 Case 06 테스트만 우선 실행. 전체 `flutter test`는 요청이 있을 때만.
10. 커밋·푸시는 명시적 승인 없이는 하지 않는다.

---

# 11. Claude Code 지속 참조 규칙

- 이 문서를 `docs/SEASON2_PARIS_STORY_BIBLE.md`에 보관한다.
- `CLAUDE.md` 또는 프로젝트에서 실제 사용하는 컨텍스트 문서에 **이 파일의 경로와 역할을 짧게 연결**한다. 기존 지침을 삭제하거나 덮어쓰지 않는다.
- Season 2의 스토리·미션·증거·캐릭터를 수정하기 전에 이 문서를 읽는다.
- **충돌 우선순위:** (1) 실제 구현된 Case 01–05 확정 사실, (2) 사용자가 명시적으로 승인한 최신 결정, (3) 본 문서의 Case 06–12 기획, (4) 임시 아이디어.
- 기획과 코드가 충돌하면 **조용히 변경하지 말고 충돌을 보고**한다.
- 새 인물, 범인, 시간 조작 규칙, 결말을 독자적으로 추가하지 않는다.
- 본 문서는 창작 기획 문서이며 실제 파리 시설·역사에 대한 사실 자료가 아니다.
- 사용자가 후속으로 변경을 승인하면 이 문서의 버전과 변경 이력을 함께 갱신한다.

## 변경 이력
- **v1.0 (2026-10-21):** A안(실제 시간 소멸 없음) 전체 12개 Case, Clockmaker/Victor 진상, Case 06–12 미션 아크, 증거 회수표 및 구현 가드레일 최초 작성.
- **v1.1 (2026-10-21):** 사용자 승인에 따라 Season 1 Clockmaker = Émile 통합(런던 사건의 범인, 동기는 정당화 아님). Season 1 확인 행동 범위(§2.5), 톱니 표식 기원(시험 장치 설계 문양 → 에밀의 상징), Case 01 표현 유지 원칙, 날짜 연속성(13–16 MAY, 보류 지속·이동 날짜 미확정), Victor 입증의 독립 증거 원칙, Case 12 결말·최종 보드 문구 갱신.
- **v1.2 (2026-10-21):** 편지 4417 보류 시점 확정(16 MAY 4:00 PM, Louvre 우편실; 보류자·이유·이동 날짜는 미확정). §2.6 신설: Big Ben 비밀 문 보관함에 파리 시험 설계도 일부·기록 색인이 있었고 에밀은 확보에 실패했다는 Season 2 후반부 배경(보관 경위·인지 경로 등은 미확정). Case 06 M2를 보류 시점 vs 이동 시점 구분 원칙으로 재정의. §3·§7·§8·§10 반영.
- **v1.3 (2026-10-21):** §2.6을 Big Ben 이중 잠금 구조로 확정(1차 비밀 문 → 에밀의 작업실, 2차 작업실 내 별도 보관함 → Big Ben 시계 장치 특정 위치 정지로 해제; 에밀 해제 실패, 탐정 미발견, Case 12 공개). Season 1 Case 02(8:17 정지)·Case 12(진짜 톱니, 자정 타종)와의 인과 검증 추가. 편지 4417 보류 사유를 Preservation Order로 확정(지시자·구체적 이유·이동 날짜·담당자·현재 위치는 미확정). Case 06에 도난 vs 보류 vs 이동 구분 추리 원칙 추가. §2.5·§3·§7·§8·§10 반영.
- **v1.5 (2026-10-23):** 사용자 승인에 따라 Case 07 확정 명세 추가: M1 공연 띠 맞추기(4:00 시작), M2 조명 데스크 고스트 라이트 + Stage Cue Card(4:00) + 익명 그림 쪽지, M3 Case 02 `The Painted Street`로 배경막 고르기 + Amendment Slip(`4:00 → 3:00`, 바늘 없는 시계 + 월계관 도장, 이름 없음), Final 라이트 테이블에서 덧붙인 종이 아래 4:00 확인 + 핀 연결. 슬립 뒷면 `ABBESSES` 스케치와 `P. KNEW THE BAG.`로 Case 08 연결. §3 Victor 공개 타이밍(Case 07 이름 일부 → 이름·이니셜 없음)과 §6 Case 07·§7·§8 07행·§9 7→8 갱신. Case 08–12 기획, Season 1과 Case 01–06 설정은 변경 없음.
- **v1.4 (2026-10-22):** 사용자 승인에 따라 Case 06 확정 명세 추가: M1 꼬리표 뒤집기, M2 평면도 길찾기(Door E), M3 서랍 + Case 05 찢긴 봉투 모서리 맞추기(Envelope 2), Final 편지 그림 ↔ 지도 대조(Palais Garnier). 편지 문구 `The clocks may lie. / But the show remembers.`, 뒷면 `OPERA ARCHIVE · FILE 3–4`로 Case 07 연결. 이동 `17 MAY · MORNING · MOVED`(archive) 확정. `THE RECORD WAS REMOVED`는 Case 06 비공개(시즌 후반 반전). §1 날짜 메모·§5 표 유지, §8 06행·§9 6→7 갱신. Season 1과 Case 01–05 설정은 변경 없음.
- **v1.6 (2026-10-23):** 사용자 승인에 따라 Case 08 확정 명세 추가. 제목 `The Painter's Last Sketch` 유지(가제 `The Hidden Bag` 폐기). Intro는 Case 07 슬립 뒷면 재표시(Case 07 데이터 변경 없음). M1 Case 02 Hidden Sketch 그림(배치) + inscription(black gate)으로 세 모퉁이 중 Corner 2 선택, M2 연필화 3장을 하늘 밝기·가로등으로 순서 배열(그림자는 근거로 쓰지 않음) + 겹쳐 보기 + "종이는 가방에서 떨어졌다" 추론, 방패 배지 유지, M3 P.의 쪽지(주웠다는 사실만) + 펼치기 + Case 07 슬립과 같은 점·없는 점(FILE 번호·시 숫자 찢김, `:00 →`), Final 종이를 그림 여백 확대 그림에 겹치기 + 증거 보드(Case 07 슬립 직접 제공) → `A paper for changing a time fell from the bag.`, Case Closed Next Lead(같은 가방 확인 → 지도로 Luxembourg Gardens). §3 P. 행, §5 08행, §6 Case 08(v1.0 기획안은 참고용으로 보존), §7 슬립 도장·가방 그림 행 갱신과 찢긴 종이·마지막 그림 행 추가, §8 08행, §9 8→9 갱신. Case 01–07, Case 09–12 기획, Season 1 설정은 변경 없음.
- **v1.7 (2026-10-23):** 사용자 승인에 따라 Case 09 확정 명세 추가(간소화, 5–7분). M1 시계 모형 3개를 지도에 놓기(T1 Arc · T2 Seine Quays · T3 Arts et Métiers, 받침 표식 별·아치 세 개·종), M2 톱니 2개 끼우기 + `The gears move the model. The real trial used wires.` + 기록 꼬리표 `KEPT AT THE STAR`, M3 Notebook 표식 두 개를 설계도 EMBLEM(Case 01 clue 톱니 8개 아이콘 기준)과 수리 메모 두 바늘에 잇기(동일인 결론 금지, Recall 시스템 변경 없음), Final 바늘 다시 끼우기 연출(Case 07·08 도장과 연결 안 함) + 4:00 → 3:00 TEST + 3지선다, Case Closed 별 → T1 → Arc de Triomphe. 가방이 정원에 온 이유는 Case 11 회수 예정 미해결 단서로 등록(이유 미창작). §6 Case 09(v1.0 기획안은 참고용으로 보존), §7 표식·시험 지도 행 갱신과 가방 미해결 행 추가, §8 09행, §9 9→10 갱신. Case 01–08, Case 10–12 기획, Season 1 설정은 변경 없음.
- **v1.8 (2026-10-23):** Case 08 → 09 → 10 연결 대사 원칙 추가(§6 Case 09 `연결 원칙`, Final 직후 문장 교체). 퍼즐·에셋·증거·시험 시계 위치·4:00 → 3:00·미해결 단서(가방 방문 목적, Case 11)는 변경 없음. Case 01–08, Case 10–12, Season 1 설정 변경 없음.
- **v2.0 (2026-10-26):** 사용자 지시에 따라 Case 11·12 확정 명세(8–12세용 단순화)를 추가했다. 확정 사실(§1, §2.1–2.6, §3의 핵심 설정)은 변경하지 않았고, 두 Case의 v1.0 기획안만 대체했다(기획안은 참고용으로 보존).
  - **Case 11:** 찢긴 장부 쪽 문지르기 → 9번 상자 3쪽(E.M./V.D.) → Victor's paper 거짓 + 사무실 도장 비교(Case 07) → 서명 비교 → 증거 3회 제시와 고백. 가방·정원 바늘은 증거 제시에 대한 짧은 답으로 회수했다.
  - **Case 12:** 바퀴 이름표(É. Moreau) → 회중시계 속 같은 바퀴 → 톱니 도장으로 Clockmaker 표식 확인 → 대화로 정체 확인 → 동기 질문·답변(3쪽 위치는 몰랐음) → 기계 고치기(시험 날 이후 틀린 채, Émile 재조작안 폐기) → 쉬운 최종 보드 → Victor 기록·Émile 사과·3쪽 보존 엔딩.
  - §2.6 미확정 항목 처리 메모, §3 Émile·Victor 공개 타이밍, §5 11·12행, §6 Case 11·12, §7 회수 행 추가, §8 11·12행, §9 11→12를 갱신했다.
  - 미확정으로 남긴 것: §2.6의 "특정 위치" 등, 편지 4417 보존 지시자, Case 07 익명 쪽지·`P. KNEW THE BAG.`, Case 03 명판 작성자, P.의 행방, 가방을 든 사람.
- **v1.9 (2026-10-24):** 사용자 승인에 따라 Case 10 확정 명세 추가. Star Room(가상)에서 M1 T1 드럼 테이프 점프 찾기(3시 없음), M2 지붕 사진 시계 4개를 시험 시계 / 아닌 시계로 분류(T1 2:30 vs 독립 시계 3:30, T2·T3 미확정, Case 09 모형 연동을 증거로 쓰지 않음), M3 해 토큰(`InkGlyph.sun`, 이미지 없음)으로 해시계 그림자 방향·길이 재현(해 2:00 / 3:30), Final 테이프 위 시간축 정렬(두 번째 2:30) + Trial Log 3쪽 누락 + 3지선다, Case Closed Case 03 회상 한 줄 + RECORD LIST `SENT TO`(목적지만, 도착 미확정) → Saint-Sulpice. 실제 시간/T1 표시 타임라인 확정(실제 3:00 한 시간 뒤로, 실제 4:00 정상 복귀, 원인·주체 비공개). Bible v1.0 Case 10 M2 `The Signal Table`(Case 09 Final과 중복)과 증거 `Signal Test Result`, `Missing Page Reference`는 폐기(`The Shadow Check`, `The Hour Was Recorded`로 대체). §5 10행, §6 Case 10(v1.0 기획안은 참고용으로 보존), §7 독립 시간 기록 행 갱신과 3쪽 누락 행 추가, §8 10행, §9 10→11 갱신. Case 01–09, Case 11–12 기획, Season 1 설정은 변경 없음. *(같은 날 보정: 에셋 검수 승인에 따라 Case 10 상세 문서 참조를 v1.1로, Star Room 묘사를 "문짝의 별·벽의 황동 명판"으로 맞춤. 스토리·퍼즐 변경 없음.)*
