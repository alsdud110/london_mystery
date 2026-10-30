# Season 4 New York — Factory 보고서

- 시즌: **The Silver Lark of New York** (`s4_newyork`), 12 Case × (미션 3 + 파이널 1)
- 작업 기간: 2026-10-30 (STEP 1 기획 → 2차: 그림·측정 → 3차: 레벨 8케이스 → 4차: 레벨 4케이스·검토·코드 생성·테스트)
- 결과: `season_factory.dart run … --budget 6.84` **exit 0** — 시즌이 게임에 들어가고 Rookie/Junior/Master 전체 플레이스루 통과.
- Commit/Push 안 함. 승인(`approve.dart`) 실행 안 함.

## 그림

| 항목 | 값 |
|---|---|
| 게임이 보여 주는 그림 | 59장 (모두 `assets/seasons/season_04_newyork/`) |
| 새로 만든 그림 | 59장 (재사용 0) |
| API 호출 | 62회 (59 + 재생성 3) |
| 지출(usage 기준, `planning/factory.json` spentUsd) | **$2.9858** |
| 계획 시 추정(정가, gpt-image-2 medium) | $3.78 |
| 예산 / 남은 예산 | $6.84 / **$3.85** |

거절 3건(원본은 `asset_work/s4_newyork/superseded/`에 보존, 프롬프트 수정 후 재생성·재검토):
1. `belvedere_castle` — 동쪽 벽 위 큰 매 석상 3개가 놋쇠 판·선택지(종달새/부엉이)와 모순 → 작고 닳은 새 부조로 수정.
2. `char_dexter_base` — 머리 위 선글라스 없음(2·7·11화 인물 단서) → 선글라스 명시.
3. `car_dome` — 돔 지붕이 낮아 정답 칸(평평한 지붕)과 휴대폰에서 구분 어려움 → 높은 반구형 돔.

59장 모두 리뷰 시트를 직접 열어 확인 후 `reviewed`. `asset_pipeline.dart --doctor`: **59 pictures, all as recorded**.

## 측정

- 지도 `art.map`: 10곳 landmarks, `measuredOn`이 현재 파일 sha256과 일치.
- 탐색 6곳(ep01 m3, ep03 m1, ep05 m2, ep07 m3, ep09 m2, ep12 m1): `areas`/`mark`/`guideAt`/`opening`/`picture.measuredOn`, 겹침 0, 오버레이로 눈 확인. 4차 세션에서 좌표·그림 변경 없음.
- 표지 프레이밍: archiveLook [0,-0.15], crop [0,0], push [0,-0.2].

## 레벨 문장 (Rookie / Junior / Master)

- 12케이스 `levels.json` 1,675줄(아래 플랜 수정으로 1,676→1,675) × Junior·Master 전부 작성, `season.levels.json`(outro/finale) 작성.
- 단어장(glossary) Junior/Master: ep01 12/15 · ep02 13/15 · ep03 14/20 · ep04 15/17 · ep05 15/16 · ep06 14/17 · ep07 12/16 · ep08 12/18 · ep09 13/17 · ep10 12/15 · ep11 12/16 · ep12 13/16.
- Rookie 줄: 작업 전 스냅샷과 12케이스 모두 동일(순서·개수·내용).
- `case_levels.dart check --season …`: **12케이스 모두 ok** ("every level written, the same game").
- `case_levels.dart review`: 12케이스 모두 R/J/M 읽음(ep02·03·08·09는 작성한 서브에이전트가, 나머지 8케이스는 직접). 수정 2줄:
  - ep07 m1 clue note Master: "boots **sold on** Dexter Vance's TV show" → "boots **from** …" (Rookie에 없는 사실 추가 제거).
  - ep12 m3 hint Master: "the line that forbids two things" → "the line that says what you must not do" (추론 단계 추가 제거).
- review 화면에서 증거 이름/설명의 J/M이 빈 칸으로 보이는 것은 도구 특성(로마도 동일, levels.json 대상 아님).
- **ep10 "Read the third line" 확인**: 오답 SONG의 피드백이며, 쪽지의 셋째 줄 "The last place: ??? The keeper would not tell me."가 정답(PLACE)으로 이끄는 줄 → **오류 아님, 수정하지 않음.**

## 전체 테스트 중 발견해 고친 플랜 문제 (Rookie 원문, 퍼즐·정답 불변)

`difficulty_content_test` 36번(학습 표현이 실제 화면에 있는가)과 `visual_placeholders_test`가 STEP 1 플랜의 문제를 찾음. `plan_season.dart check`는 이를 잡지 못했음. 최소 수정(원본은 scratchpad `plan_bak/`에 백업):

| Case | 문제 | 수정 |
|---|---|---|
| ep04 m3 | 표현 "He said he fixes clocks."가 편지에 문장으로 없음("…and said he fixes clocks.") | 편지 줄을 "He looked at the brass bird. He said he fixes clocks."로 나눔(플랜 + 3레벨) |
| ep04 final | 표현 "If my bird is lost, my song still lives."는 풀이 후 장면에만 나옴 | 이 미션의 학습 표현 목록에서 제외(문장 자체는 그대로 등장) |
| ep08 final | Rookie 편지에 "It opens with our family's old name."이 없음 | Rookie 첫 줄 "My music box is locked. It opens with our family's old name." (J/M은 이미 이 형태) |
| ep10 m1 | 표현 "Nora was up on the steps, far away."가 편지 문장과 다름 | 표현을 편지 문장 "Nora was up on the steps with her camera, far away."로 맞춤 |
| ep11 final | 표현 "Finders keepers!"는 정답(KEEPERS)을 담아 퍼즐 화면에서 일부러 "Finders ...!"로 가림 | 학습 표현에서 제외("The one who finds a thing can keep it." 유지) |
| ep09 m1 / ep12 m1 | 단서 기호 `palace`에 그림 글리프가 없어 글자로 표시됨 | ep09 단서 → `park`(센트럴파크의 성), ep12 단서·증거 → `feather`(돌 종달새의 둥지) |

수정 후 `plan_season.dart check` 0 ERROR / 55 WARNING(이전과 동일), `case_levels.dart check` 12케이스 ok.

## 코드 생성·시즌 등록

- `generate_season.dart --target game`: `lib/data/generated/s4_newyork/`(content, art, levels 13개, manifest) 생성, `generated_seasons.g.dart`·`generated_season_art.g.dart`·`generated.manifest.json`에 등록(로마 다음).
- `pubspec.yaml` 에셋 경로(2차 세션) 유지.
- `lib/data/models/season.dart`에 `SeasonIds.newyork = 's4_newyork'` 추가(로마의 `SeasonIds.rome`과 같은 방식, 테스트에서 사용).

## 테스트

1. 첫 `run`: exit 60 — `generated_seasons_test.dart` 7건 실패. 원인은 시즌 4 추가로 처음 생긴 상황을 공용 플레이스루 테스트(`test/sandbox/season_playthrough.dart`)가 다루지 못한 것:
   - 로마 R/J/M 3건: 로마가 더는 마지막 시즌이 아니라 마지막 보고서에 `SEASON COMPLETE` 대신 다음 시즌 티켓(`_SeasonFinale`)이 나옴 — 앱 동작은 의도대로. 테스트가 다음 시즌이 있으면 티켓·다음 시즌 이름·finale 문장을 확인하도록 수정(없으면 기존 확인 그대로).
   - 뉴욕 J/M 2건: 2화 **파이널**이 그림 선택(정답 tea_house)인데 테스트가 파이널의 그림 선택을 '플레이함'으로 기록하지 않음 → 파이널도 선택지 그림이 화면에 있는지 확인하고 기록.
   - 뉴욕 Rookie 1건(+그 여파 1건): 엔딩 문장 'READ ALL' 버튼이 스크롤하는 사이 타이핑이 끝나 사라지는 경쟁 상태 → 보이게 한 뒤 아직 있으면 누르도록.
   - 검사를 약하게 한 곳 없음(오히려 파이널 그림 선택·다음 시즌 티켓 확인 추가).
2. `generated_seasons_test.dart --plain-name "the whole season in order"`: 6/6 통과(로마·뉴욕 × 3레벨).
3. 두 번째 `run`: **exit 0** — `flutter analyze` No issues, `flutter test test/generated_seasons_test.dart` 통과.
4. 전체 `flutter test` 1차: +3311 / -19.
   - 시즌 목록을 3개(London·Paris·Rome)로 고정한 테스트 11건 → 뉴욕 포함으로 갱신(world_map, rome_integration, season_presentation ×2, scene_place, paris_map, s9_ep01, multi_season ×2, world_archive ×2). world_archive의 가상 '4번째 시즌' 픽스처는 5번째로 옮기고 실제 SEASON FOUR 확인 추가. world_map 새 탐정 상태에 `newyork: locked`(로마가 잠금) 추가.
   - case_shortcuts 2건: 시즌 4개로 Game Master 목록이 길어져 ep12 행이 화면 밖에 빌드된 채 탭됨 → 탭 전 `ensureVisible`.
   - 위 표의 플랜 문제 2건(difficulty_content, visual_placeholders).
   - season_planner_test 2건: **HEAD(c542af1)의 깨끗한 워크트리에서도 같은 2건 실패** → 이번 작업과 무관한 기존 실패, 수정하지 않음.
5. 플랜 수정 후 `run` 다시: exit 0 (analyze No issues, generated_seasons_test +139 통과).
6. 전체 `flutter test` 2차: **+3328 / -2** — 남은 2건은 위 기존 season_planner_test 실패뿐.

## 백업

- `content_pipeline/asset_work/s4_newyork/` → `~/world_mystery_backups/s4_newyork_asset_work_20261030/` (82파일, 233MB), sha256 82개 모두 일치(최종 테스트 후 다시 비교해도 일치).

## 확인하지 않은 것 / 남은 것

- 실기기(iOS/Android) 실행, 실제 화면 눈 확인(테스트의 위젯 플레이스루만).
- `approve.dart` 승인은 사용자 몫.
- 월드맵 그림에 뉴욕이 그려져 있지 않아 `mapAt` 없음(좌표만으로 표시).
- 플랜 WARNING 55(STEP 1과 동일, 의도/허용 항목).
- 기존 실패 season_planner_test 2건(이번 작업과 무관).
- Commit/Push.
