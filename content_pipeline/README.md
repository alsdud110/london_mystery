# content_pipeline — plans of seasons in the making

This folder holds the plans of seasons in the making. The game never reads
it, and it is not bundled. The game's content stays in `lib/data/mock/`.

```
content_pipeline/seasons/<seasonId>/
  season.plan.json              SeasonPlan
  cases/<caseId>/case.plan.json CasePlan (its MissionPlans and PuzzlePlans inside)
```

The formats and the checks are described in `tool/season_gen/README.md`.
No season is planned here yet. The Paris plans the tests use are fixtures
under `test/fixtures/season_gen/`.
