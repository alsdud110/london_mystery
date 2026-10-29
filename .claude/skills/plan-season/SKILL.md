---
name: plan-season
description: Plan a whole new World Mystery season (12 cases, 3 acts) from just a season number and a city — story bible, SeasonPlan, 12 CasePlans, asset manifest, checks and report. Use when the user says things like "시즌 3 로마 제작해", "시즌 4 뉴욕 만들어", "plan season 5 in Tokyo", or asks to plan/write a new season's cases.
---

# Plan a season

The user gives a season number and a city. You plan everything else yourself
— title, mystery, characters, places, twelve cases, puzzles, answers, hints,
clue links, ending, pictures — and report back. Do not ask them for titles
or answers.

Follow `tool/season_planner/PLAYBOOK.md` step by step. In short:

1. Check git state and that the season number and folder are free; read
   `CLAUDE.md` §20 and the trial season `content_pipeline/seasons/s3_rome/`
   as the worked example (its shapes, not its story).
2. `dart run tool/season_planner/plan_season.dart init --season <n> --city <City>`
3. Write `planning/story_bible.json`, then `season.plan.json`, then the twelve
   `cases/<caseId>/case.plan.json`, and `assets.manifest.json` alongside.
   Choose each mission's play from its clue (PLAYBOOK §2 "Choosing how each
   mission is played"; the game's play types are in
   `tool/season_gen/GAMEPLAY_CATALOG.md`): text puzzles, and the missions on
   pictures the generator makes — a look round (`explores`), a search
   (`investigations`), a talk with witnesses (`dialogues`), a picture choice
   (`imageChoice`). Their pictures go in the manifest with `use: puzzle`;
   their areas are measured on the made pictures before generation.
   Where the story needs it (not everywhere), add the story around a
   puzzle (PLAYBOOK §2 "The story around the puzzles"): a short talk before
   or after it (`play.talk`), the mission's own Discovery Moment
   (`play.discovery`), and the final's ending (`play.ending`).
4. `plan_season.dart format <dir>` then `plan_season.dart check <dir>`; fix every
   ERROR and the real WARNINGs; repeat.
5. Write each case's `englishReview`, run `check` once more, and report in Korean.

Limits: no OpenAI call, no picture made, no `SeasonCatalog` change, no change to
London or Paris content, no commit or push unless asked. If the story must
change an existing season or a decision the user made, stop and ask.
