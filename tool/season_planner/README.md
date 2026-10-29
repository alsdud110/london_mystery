# season_planner — a whole season planned by Claude Code (STEP 3-11)

Claude Code plans a season from a number and a city, following
[`PLAYBOOK.md`](PLAYBOOK.md). The tools here keep the plans in their folder
and check them; they never write a story, call an API or make a picture.
Plain Dart (`dart run`); nothing here is imported by the game.

| File | What |
|---|---|
| `PLAYBOOK.md` | Claude's procedure and quality rules for planning a season |
| `plan_season.dart` | Command line: `init`, `check`, `assets`, `format`, `generate` |
| `season_quality.dart` | `SeasonQuality`: every check of a season's folder, its `QualityReport` |
| `story_bible.dart` | `StoryBible`: `planning/story_bible.json` against the plans |
| `asset_manifest.dart` | `AssetManifest`: `assets.manifest.json` against the plans and `tool/ai_agents` |
| `english_check.dart` | `EnglishCheck`: heuristics on the English a player reads |
| `finding.dart` | `Finding` (ERROR, WARNING, INFO; its source) |

Tests: `test/season_planner/season_planner_test.dart` (each check, on a
copy of the trial season with one thing broken) and
`test/season_planner/s3_rome_season_test.dart` (the trial season whole, the
real generator, the game's `SeasonContentValidator`).

## A season's folder

```
content_pipeline/seasons/<seasonId>/
  season.plan.json                 SeasonPlan (tool/season_gen)
  cases/<caseId>/case.plan.json    CasePlan ×12
  assets.manifest.json             every picture planned (AssetManifest)
  planning/
    brief.json                     init's: number, city, asset folder
    story_bible.json               the writer's truth (StoryBible)
    quality_report.json            check's last report
```

## Commands

```sh
dart run tool/season_planner/plan_season.dart init --season 3 --city Rome   # --cases 12 --acts 3
dart run tool/season_planner/plan_season.dart check content_pipeline/seasons/s3_rome     # --all, --no-report
dart run tool/season_planner/plan_season.dart assets content_pipeline/seasons/s3_rome
dart run tool/season_planner/plan_season.dart format content_pipeline/seasons/s3_rome
dart run tool/season_planner/plan_season.dart generate content_pipeline/seasons/s3_rome  # --check, --force, --out
```

- `init` refuses a season number or folder already planned, and any shape
  other than 12 cases in 3 acts (the plans' schema). It writes the folder
  whole (`<folder>.part`, then renamed) or not at all.
- `check` exits 1 with an ERROR, and writes the report (no time, no machine:
  the same plans write the same report).
- `generate` runs `check` first: an ERROR exits 1, a place picture still
  missing exits 2, and nothing is written in either case. Otherwise it is
  `generate_season.dart --target sandbox`.

## What `check` runs

1. The season_gen checks on every plan, as `validate_plan.dart --season`
   does: schema, structure (`PlanCheck`), puzzle selection, clue graph (one
   case, then across cases), and the season's puzzle variety.
2. `PlayCheck` on every case. A place picture, or a puzzle's picture (a
   scene, a picture option: STEP 3-13), not on disk is `image_pending`
   (INFO), the one thing allowed to be missing; every other finding is an ERROR.
3. Twelve cases, each in its folder; a character never in a case before
   their `firstCase`; a "Mr./Signor/Professor X" no character of the season;
   another season's city named.
4. Puzzles: an answer; a line for every wrong option; a wrong-answer line
   for the right answer; a hint that says the answer (WARNING). How the
   season is played (STEP 3-13, WARNING, no quota): no mission on pictures
   in the whole season (`season_play_text_only`), a case of one kind only.
5. The English (heuristics only, WARNING): sentences over 15 words, long
   words no glossary has, letters over 110 words, the same sentence 3+ times.
   Claude's own reading is the bible's `englishReview` (INFO, source `claudeReview`).
6. The story bible: the season plan's people, places, acts and titles;
   the core mystery revealed and resolved in the season; every question
   answered, after it is asked; every clue thread in the missions' inputs.
7. The asset manifest: ids and paths of the season's own folder (never
   another season's), sizes the image models make, styles that exist
   (`image_styles.dart` or the manifest's `seasonStyles`), every place's
   picture at the season plan's file and size, a base portrait for every
   character and every other pose drawn from it, references to real
   assets, a `generated` picture on disk, every picture a puzzle shows an
   asset of the manifest (`use: puzzle`, in its `assetNeeds`). Cost:
   `ImagePricing.estimate`, list prices, no call.
8. The real generator, in memory (`CaseGenerator.sandbox`, nothing written),
   once there is no ERROR: compatible when its only failures are the
   missing place pictures.

## The trial season (s3_rome)

"The Broken Map of Rome", planned by Claude Code from the input "Season 3,
Rome" to try the planner. It is not the decided Season 3: never in
`SeasonCatalog`, no picture made. See its `planning/story_bible.json`.
