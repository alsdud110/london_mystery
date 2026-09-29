# London Mystery — Visual Asset Inventory & 교체 가이드

기준일 2026-09-29. 대상: 일러스트레이터, 아트 담당, 개발자.

현재 게임의 모든 그림은 코드로 그립니다.
- 장면: `LandmarkArt`(CustomPainter)
- 아이콘·심볼·배지: Ink Icon System(`InkGlyph`)
- 아직 그림이 없는 심볼·배지: 머리글자 **모노그램**(Custom Asset Required 표시)

이 문서는 아직 임시인 그림의 목록, 각 그림의 크기·스타일 사양, 파일이 오면 끼워 넣는 방법을 정리합니다.

---

## 1. 우선순위 기준

| 등급 | 기준 |
|---|---|
| **A** | 퍼즐의 정답 판단에 쓰이거나, 모든 사건에서 반복해서 크게 보임 |
| **B** | 자주 보이지만 퍼즐 판단에는 쓰이지 않음. 또는 대체 그림이 장소를 헷갈리게 함 |
| **C** | 대체 그림으로도 맥락이 맞음. 또는 현재 쓰이지 않음 |

---

## 2. 목록

### 2-1. Case 01 심볼 (현재: 모노그램)

| 키 | 현재 | 필요한 그림 | 사용 위치 | 표시 크기 | 우선순위 |
|---|---|---|---|---|---|
| `crown` | 금색 "C" | 왕관 | Buckingham Palace 미션 단서 도장, 증거 *Crown Symbol*, Final 보상 증거 *The Missing Crown*(증거 확대 화면) | 18~83dp | **A** |
| `park` | 초록 "P" | 나무 한 그루 | Hyde Park 단서 도장, 증거 *Crown Symbol*의 네 그림 줄, **Royal Box 잠금 다이얼 3번** | 18~29dp | **A** |
| `museum` | 남색 "M" | 기둥이 있는 박물관 정면 | British Museum 단서 도장, 증거 *Crown Symbol*의 네 그림 줄, **Royal Box 잠금 다이얼 4번** | 18~29dp | **A** |
| `palace` | 버건디 "P" | 궁전 정면(가운데 깃발) | 현재 데이터에서 쓰이지 않음(표만 있음) | — | C |

> 잠금 다이얼 네 개 중 clock·train은 이미 그림이고 park·museum만 글자입니다. "그림 → 숫자" 퍼즐의 핵심이라 A로 분류했습니다.

### 2-2. 기존 배지 4개 (현재: 모노그램)

| 배지 | 현재 | 필요한 그림 | 사용 위치 | 표시 크기(메달 / 그림) | 우선순위 |
|---|---|---|---|---|---|
| `masterDetective` | "M" | 사냥 모자(deerstalker) | **모든 사건의 Case Solved 대표 배지**, Notebook 배지 쪽 | 30~72dp / 15~36dp | **A** |
| `sharpEyes` | "S" | 눈 | Notebook 배지 쪽, Case Solved 배지 줄 | 30~72dp / 15~36dp | B |
| `quickThinker` | "Q" | 회중시계형 스톱워치 | 같음 | 같음 | B |
| `puzzleSolver` | "P" | 퍼즐 조각 | 같음 | 같음 | B |

> 배지 그림은 색이 칠해진 메달 위에 밝은 종이색(`paperLight`)으로 찍힙니다. 잠긴 배지는 자물쇠 글리프로 표시하므로 그림이 필요 없습니다.

### 2-3. Season 1 장소 장면 (현재: 다른 장면을 대신 그림)

| 키 | 장소 | 현재 대체 그림 | 필요한 그림(데이터 속 묘사) | 사용 위치 | 우선순위 |
|---|---|---|---|---|---|
| `staffRoom` | Case 09 Mission 2 *The Staff Room* | 궁전 외관 | 궁전 직원 휴게실: 옷걸이, 찢어진 이름표, 작은 테이블 | 미션 화면, 스토리 썸네일 | **B** |
| `courtyard` | Case 09 Mission 3 *The Courtyard* | 궁전 외관 | 궁전 안뜰: 빨간 제복 근위병 행진, 돌바닥 | 같음 | **B** |
| `dressingRoom` | Case 11 Mission 2 *Behind the Stage* | 극장 외관 | 무대 뒤 분장실: 거울, 흰 가면, 의상 걸이 | 같음 | **B** |
| `waitingRoom` | Case 08 Mission 2 *The Waiting Room* | King's Cross 외관 | 역 대합실: 벤치, 큰 시계(9:20), 여행 가방 | 같음 | **B** |
| `boathouse` | Case 07 Mission 2 *The Boathouse* | Hyde Park | 호숫가 보트 창고: 노, 밧줄, 오래된 상자, 탁자 아래 물뿌리개 | 같음 | C |
| `roseGarden` | Case 07 Mission 3 *The Rose Garden* | Hyde Park | 장미 정원: 장미 덤불, 벤치 위 지도 조각 세 장 | 같음 | C |

> Case 09·11·08은 실내 장면인데 건물 외관이 보여 장소가 헷갈릴 수 있어 B입니다. Case 07의 두 장소는 Hyde Park 안이라 C입니다.
> 퍼즐 화면에서는 장면이 크게 보이므로 **정답이 그림에 드러나면 안 됩니다.** 예를 들어 Boathouse에서 물뿌리개 뒤의 상자를 강조하지 마세요. 스토리 문장에 나오는 물건은 그려도 되고, 정답 위치를 표시하지는 않습니다.

### 2-4. 기타 Custom Asset Required (코드 주석에 표시됨, 모두 C)

| 위치 | 현재 | 필요한 것 |
|---|---|---|
| Register 화면 엠블럼 | 돋보기 글리프 | 탐정 엠블럼(사냥 모자 & 파이프) |
| Final `UNLOCK` 버튼 | 글리프 없음 | 열린 자물쇠 글리프 |
| 오답 시트 `TRY AGAIN` | 글리프 없음 | 다시 하기 글리프 |
| Case Solved `Play again` | 글리프 없음 | 다시 보기 글리프 |
| Case Solved 파일 모서리 | 없음 | 황동 압정 |
| Game Master 초기화 버튼 | 글리프 없음 | 초기화 글리프 |
| 별점 | 활자 ★ / ☆ | 잉크 별 글리프 |
| QR 스캐너 화면 | Material 아이콘 3개 | 손전등 / 카메라 없음 / 카메라 꺼짐 잉크 글리프 (Vintage 스타일에서 남은 유일한 Material 아이콘) |
| 알 수 없는 심볼 | "?" | 필요 없음(데이터 오류 표시용) |

> 이 항목들은 `InkGlyph`에 벡터 경로로 추가하는 편이 맞습니다(개발자 작업). PNG로 받을 필요가 없습니다.

---

## 3. 크기

### 장면 (4:3)

| 사용 위치 | 표시 크기(360dp 폰 기준) | 자르기 |
|---|---|---|
| 미션 화면 상단 | 약 320×240dp (태블릿 최대 약 516×387dp) | 없음 |
| Final 화면 | 약 317×238dp | 없음 |
| 그림 선택 보기 타일 | 약 140×148dp | 가운데 기준 잘림 |
| 스토리 장면 썸네일 | 72×72dp | 가운데 정사각형 |
| Case Solved 사진 | 86×86dp | 가운데 정사각형 |

- **납품: 1600×1200px PNG**(또는 WebP), 불투명 배경(종이색 `#FAF5EA`)
- 주인공 사물은 **가운데 1200×1200px 안**에 둡니다. 정사각형으로 잘려도 읽혀야 합니다.
- 바닥선은 아래에서 약 16% 위치(현재 그림과 같음)

### 심볼 (정사각형, 한 가지 색)

- 표시 18~83dp(가장 큰 곳은 증거 확대 화면)
- **납품: 256×256px PNG, 투명 배경, 검정 한 색**. 게임이 심볼 색으로 다시 칠합니다(`BlendMode.srcIn`). 색이 여러 개면 한 색으로 뭉개집니다.
- 선 굵기: 크기의 약 8%(현재 글리프: 24 단위에 1.9)
- 여백: 사방 약 8%

### 배지 그림 (정사각형, 한 가지 색)

- 표시 15~36dp
- **납품: 192×192px PNG, 투명 배경, 검정 한 색**. 게임이 메달 위에 종이색으로 칠합니다.
- 작게 보이므로 디테일보다 **실루엣**으로 알아볼 수 있어야 합니다.

---

## 4. 스타일

Vintage London Detective Storybook.

- 잉크 펜 윤곽선. 선을 두 번 그은 듯 살짝 어긋난 두 번째 선(현재 `LandmarkArt`와 같은 느낌)
- 하늘 대신 **종이**. 색은 옅은 수채 워시만 쓰고, 그리는 것은 잉크가 합니다.
- **금지**: 그라디언트, 광택·글로우, 반짝이, 이모지, 사진 질감, 3D 렌더
- 팔레트(코드 `AppColors`)

| 이름 | 값 | 용도 |
|---|---|---|
| ink | `#2A2622` | 윤곽선 |
| paperLight | `#FAF5EA` | 배경 종이 |
| stone | `#E9DFC9` | 건물 벽 |
| parchmentDark | `#DCCBA6` | 그늘, 실내 벽 |
| brick | `#C7A48A` | 벽돌 |
| river | `#B7C7D3` | 물, 유리창 |
| park | `#CBD1A8` | 풀밭 |
| gold | `#A8844A` | 금속, 액자 |
| burgundy | `#7A2E2E` | 봉랍, 근위병 |
| royalBlue | `#3E5A8C` | 천, 포인트 |

기준이 되는 기존 그림: Tower of London(`towerOfLondon`), Gallery 8(`gallery`), Big Ben 시계(`clockFace`). 앱의 Case 03·05 미션 화면에서 볼 수 있습니다.

---

## 5. 교체 구조 (개발자용)

새 패키지 없이 `Image.asset`만 씁니다. SVG는 새 dependency가 필요해서 쓰지 않습니다.

### 교체 지점은 한 파일

`lib/widgets/art_assets.dart`의 `ArtAssets`:

| 맵 | 키 | 적용되는 곳 |
|---|---|---|
| `scenes` | `Artwork` | `LandmarkArt`(미션, Final, 그림 선택, 썸네일, Case Solved 사진) |
| `solvedScenes` | `Artwork` | 해결 후 모습이 바뀌는 장면(현재 `clockFace`만: 8:17 → 9:17) |
| `symbols` | 심볼 키(`'park'` 등) | `GameSymbol.mark` → `InkMark`(단서 도장, 증거, 잠금 다이얼) |
| `badges` | `GameBadge` | `BadgeMedal` → `InkMark` |

### 파일 하나를 넣는 순서

1. `assets/art/scenes/boathouse.png`처럼 파일을 넣습니다(폴더는 `scenes/`, `symbols/`, `badges/`).
2. 그 폴더를 `pubspec.yaml`의 `flutter: assets:`에 한 번만 추가합니다(예: `- assets/art/scenes/`).
3. `ArtAssets`에 한 줄을 추가합니다. 예: `Artwork.boathouse: 'assets/art/scenes/boathouse.png'`
4. `flutter test test/art_assets_test.dart`를 실행합니다. 파일 존재, pubspec 등록, 확장자(PNG/WebP/JPEG), 키 유효성을 확인합니다.

화면 코드는 바꾸지 않습니다.

### 안전장치

- **그림이 먼저 그려지는 순서**: 파일 → 글리프 → 모노그램(심볼·배지), 파일 → 코드 그림(장면)
- 파일이 없거나 깨지면 `errorBuilder`가 코드 그림으로 되돌립니다. 빈 칸은 나오지 않습니다(테스트로 확인).
- 여섯 장소는 이미 자기 키(`boathouse` 등)를 씁니다. 파일이 오기 전에는 `LandmarkArt.standIns`의 대체 장면을 **픽셀 단위로 똑같이** 그립니다(테스트로 확인). 그래서 지금 화면은 바뀌지 않았습니다.
- `clockFace`처럼 해결할 때 바뀌는 장면은 `solvedScenes`가 없으면 해결 중·후에 코드 그림을 써서 변화가 보이게 합니다. `scenes`에만 파일을 넣으면 해결 순간 PNG에서 코드 그림으로 바뀌므로 **두 장을 함께** 넣으세요.

### 새 장소를 추가할 때

1. `Artwork` enum에 키를 추가합니다.
2. 그림이 아직 없으면 `LandmarkArt.standIns`에 대체 장면을 지정하고, 페인터 switch의 stand-in case에 키를 넣습니다.
3. 데이터(`lib/data/mock/season1/*.dart`)의 `'scene'`에 새 키를 씁니다.
