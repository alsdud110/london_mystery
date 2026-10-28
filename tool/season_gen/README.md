# season_gen — season content pipeline tools

Tools for planning a new season before any of it becomes game content
(STEP 3). The game never imports this folder, and nothing here imports
Flutter, so it runs with plain `dart run`.

## Plans (STEP 3-2)

| File | What |
|---|---|
| `plan_models.dart` | `SeasonPlan`, `CasePlan`, `MissionPlan`, `PuzzlePlan` (and their parts): `fromJson` / `toJson`, format rules |
| `plan_ids.dart` | Id formats (`s3_tokyo`, `s3_ep03`, `s3_ep03_m2`, `s3_ep03_final`, `s3_ep03_c1`, `s3_ep03_e1`, `s3_tokyo.station`) |
| `plan_check.dart` | `PlanCheck`: how a plan's parts relate (what a schema cannot say) |
| `plan_files.dart` | `PlanFiles`: load and save in one canonical form |
| `json_schema_lite.dart` | `SchemaSet`: validates JSON Schema draft 2020-12 for the keywords these schemas use, and refuses a schema with any other keyword |
| `schema/*.schema.json` | The plans' JSON Schemas (`common`, `season_plan`, `case_plan`, `mission_plan`, `puzzle_plan`) |
| `validate_plan.dart` | Command line: schema, then model, then structure |

```sh
dart run tool/season_gen/validate_plan.dart \
  --season content_pipeline/seasons/s3_tokyo/season.plan.json \
  content_pipeline/seasons/s3_tokyo/cases/s3_ep01/case.plan.json
```

### Rules

The rules come in two layers.

- **Format:** the JSON Schemas and the Dart models apply the same rules, and
  `test/season_gen/season_gen_schema_test.dart` checks that both accept and
  reject the same documents. Unknown fields are rejected. `schemaVersion`
  must be `1`.
- **Structure:** `PlanCheck` checks how the parts relate: a case's id against
  its number, season and act; the acts holding Case 01–12 in order; the
  missions running `m1…`, then `final`, with ids named after their slots;
  outputs and places belonging to their own case and season; a final being
  played on the final page.

Later steps check the rest. STEP 3-3 checks the palette fit, STEP 3-4 the
clue graph. Other later steps cover the levels, the assets and the Dart
content.
