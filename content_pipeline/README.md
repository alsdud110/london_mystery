# content_pipeline — plans of seasons in the making

This folder holds the plans of seasons in the making. The game never reads
it, and it is not bundled. The game's content stays in `lib/data/mock/`.

```
content_pipeline/seasons/<seasonId>/
  season.plan.json              SeasonPlan
  cases/<caseId>/case.plan.json CasePlan (its MissionPlans and PuzzlePlans inside)
  approvals.json                who approved what, and with which hash
  approved/<hex>.json           each plan as it was approved
```

The formats, the checks and the approvals are described in
`tool/season_gen/README.md`. Approvals are a person's, made with
`tool/season_gen/approve.dart`; nothing approves a plan on its own.
A season planned with `tool/season_planner` (STEP 3-11) also has
`assets.manifest.json` (its pictures, planned) and `planning/` (its brief,
story bible and quality report): see `tool/season_planner/README.md`.

- `s9_sandbox`: the pipeline's trial cases (STEP 3-6 to 3-9).
- `s3_rome`: "The Broken Map of Rome", Season 3: all twelve cases planned by
  Claude Code, drawn by the asset pipeline and in the game since the Rome
  integration (`lib/data/generated/s3_rome/`, `tool/season_factory/`).

The Paris plans the tests use are fixtures under `test/fixtures/season_gen/`.
