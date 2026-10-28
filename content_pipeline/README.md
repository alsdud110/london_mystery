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
No season is planned here yet. The Paris plans the tests use are fixtures
under `test/fixtures/season_gen/`.
