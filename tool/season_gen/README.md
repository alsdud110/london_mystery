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
| `puzzle_selection_check.dart` | `PuzzleSelectionCheck`: whether a plan's puzzles can be played by the palette's engines (STEP 3-3) |
| `palette_facts.dart` | `PaletteFacts`: the game's `PuzzlePalette` and dial symbols, copied for plain `dart run` (written and checked by `test/season_gen/palette_facts_test.dart`) |
| `clue_graph_check.dart` | `ClueGraphCheck`: whether every clue a mission is given is found before it (STEP 3-4) |
| `validate_plan.dart` | Command line: schema, then model, then structure, then puzzle selection and clue graph |
| `content_approval.dart` | `SeasonApprovals`: approvals of season plans, case plans and assets, their status, a case's readiness (STEP 3-5) |
| `content_hash.dart` | `ContentHash`: a plan's canonical JSON and its SHA-256, a file's SHA-256 |
| `sha256.dart` | `Sha256`: SHA-256 in plain Dart (no package beyond the game's) |
| `change_impact.dart` | `ChangeImpact`: what a change of an approved plan or picture touches |
| `approve.dart` | Command line: `status`, `approve`, `impact` |

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


## Puzzle selection (STEP 3-3)

`PuzzleSelectionCheck` runs on a case plan whose format and structure hold
(the command line does not run it before). It reports errors and warnings,
each with a code and a path (`$.missions[1].puzzle.paletteId`). Errors fail
the command line; warnings alone do not.

**Errors** (the puzzle cannot be made as planned):

| Code | When |
|---|---|
| `palette_unknown` | `paletteId` is not in the palette |
| `palette_missing` | `paletteId` is null on a puzzle that is not a `devRequest` |
| `surface_unsupported` | none of the puzzle's engines plays on its page (`mission` / `finalMission`) |
| `engine_table_mismatch` | `engineTable` is not the table of one of its engines on that page (null when it needs one) |
| `engine_table_companion` | `engineTable` is an engine laid on the puzzle (`lockBoxes`, `talkMissions`), never played alone |
| `mission_type_mismatch` | `missionType` is not a type its engine plays |
| `not_generatable` | a `requiresDevelopment` puzzle not planned as `devRequest` |
| `status_mode_conflict` | `ready` with pictures to make (`requiresAssets`, or `assetNeeds` given); `awaitingAssets` with no picture; `devRequest` for an engine that plays it as it is |
| `asset_needs_missing` | a `requiresAssets` puzzle with no `assetNeeds` |
| `required_data_missing` | no `options` for a puzzle played with options; a choice with one option; no `recall` clue input for a puzzle that compares with an earlier evidence |
| `answer_mismatch` | an answer its data cannot give: a choice's answer not an option id, a code not digits or not `codeLength` long, `codeFormat: time` not four digits, dial symbols not one a dial shows or not one per dial, a sequence with an unknown or (with as many options as steps) a repeated option, letter tiles that do not spell the answer |
| `ready_unmodelled_data` | `ready`, with engine data a plan does not hold |

The answer rules are the engines' own (`AnswerChecker`, the question
widgets). The whole answer data is checked only for puzzles played from
their mission type alone (`text_choice`, `word_entry`, `number_entry`,
`combo_dial_lock`, `letter_tile_lock`, `order_sequence`, `picture_choice`);
for the others, only options and choice answers. Every game mission on a
palette engine, written as a plan, passes these rules
(`test/season_gen/puzzle_selection_check_test.dart`).

**Warnings** (variety, recommendations only; no ratio is enforced):
`repeated_in_case` (the same palette puzzle again in a case),
`season_concentration` (one palette puzzle for more than half of the puzzles
of the case plans given together), `late_diversity_drop` (an act, all of its
cases given, with fewer kinds of palette puzzle than the act before),
`asset_needs_unused` (pictures asked for a text-only puzzle with no engine
to show them).

Each puzzle's fit also says which of its palette `requiredData` a plan
holds, which are a level's words (letter, question, hints…) and which are
its engine's own data (scene models, pixels). Neither of the last two is
checked here: they are written with the Dart content.

Not checked here: the clue graph (below); the Dart content and its
engine collisions (`PuzzleEngineCollisionCheck`, on the made
`SeasonContent`); whether pictures are approved (Approvals, below) or fit their puzzles (STEP 3-8).


## Clue graph (STEP 3-4)

`ClueGraphCheck` runs on case plans whose format and structure hold, as the
puzzle selection does. A clue is anything a mission leaves (`clueOutputs`:
its `clue`, `evidence` and `facts`); a use is a `clueInputs` entry of any
kind (`textMention` too). Story words are never read.

- **Play order** is the plans' own: a case's `missions` as listed, then its
  `final`; the cases as the season plan's acts list them, never by their
  numbers. Plans have no optional mission and no branch, so every player
  finds every clue, in that one order.
- **Clue ids name their case** (`s3_ep03_c1`, and `PlanCheck` keeps every
  output of its own case), so one id is one clue in the whole season.
- **`ClueGraphCheck.casePlan(plan, {available})`** judges the case's own
  clues. A clue of another case is checked against `available` (the clues
  of the cases before), or, with none given, left `unresolved` for the
  season. It never reports a clue as unused: a later case may use it.
- **`ClueGraphCheck.season(season, cases)`** is the verdict: each case's
  own findings, then those between cases. An input of a case whose plan is
  not given stays `unresolved`; `complete` says every case was given.

The report holds every clue's producers and consumers (`producersOf`,
`consumersOf`); each finding its code, case, path, clue, the input that
asks for it (`requiredAt`) and the outputs that leave it (`producedAt`),
and `toJson()` for a generator to read back.

| Code | Weight | When |
|---|---|---|
| `clue_not_found` | error | no mission leaves the clue (its case's plan given), or its case is not of the season, or (a case alone with `available`) it is not given |
| `clue_used_before_discovery` | error | the clue is left only by a later mission or a later case (that case given or not) |
| `clue_duplicate_output` | error | two missions leave the same id: a clue is found once |
| `clue_dependency_cycle` | error | a mission is given the clue it leaves itself |
| `case_not_in_season` / `case_given_twice` | error | a case plan the season cannot place (`season` only) |
| `clue_never_used` | warning | no mission is given the clue; only once every case after its own is given, and never for the season's last final |

In one play order, every dependency cycle of more than one mission runs
through a clue asked for before it is found: it is reported once, as
`clue_used_before_discovery`, with the cycle's missions named on it.

The command line runs `casePlan` on each case file (cross-case clues left
open, counted in its summary), then, with `--season`, `season` on the case
files given and prints the findings between cases.


## Approvals (STEP 3-5)

A plan is checked by the tools above; it is approved by a person. The two
never mix: a plan not approved is not a wrong plan, and `validate_plan.dart`
neither reads nor writes approvals. Saving a plan (`PlanFiles`) never
approves it.

```
content_pipeline/seasons/<seasonId>/
  approvals.json          every approval, oldest first; one is only ever added
  approved/<hex>.json     each plan as it was approved, named by its hash
```

```json
{
  "schemaVersion": 1,
  "seasonId": "s3_tokyo",
  "approvals": [
    {"kind": "seasonPlan", "id": "s3_tokyo", "hash": "sha256:…", "approvedAt": "2026-10-28T09:00:00.000Z", "approvedBy": "name <email>"},
    {"kind": "casePlan", "id": "s3_ep01", "hash": "sha256:…", "approvedAt": "…", "approvedBy": "…", "note": "read through"},
    {"kind": "asset", "id": "s3_tokyo.asset.hall", "path": "assets/seasons/season_03_tokyo/hall.png", "hash": "sha256:…", "approvedAt": "…", "approvedBy": "…"}
  ]
}
```

- **Targets.** A season plan (`season.plan.json`) and a case plan
  (`cases/<caseId>/case.plan.json`) are found by their id; an asset by the
  `path` (from the repository's root) it was approved with.
- **Status** is never written down. It is judged each time from the
  target's file now against its last approval: `draft` (never approved),
  `approved` (the same hash), `stale` (another hash, or a plan that is not
  JSON any more), `missing` (no file: an approval of it holds no more). A
  record with any other field (a `status`) does not read.
- **Approving** a target adds a record and, for a plan, keeps its content
  under `approved/`. Approving it as it already is adds nothing. A stale
  target is approved again with a new record; the old ones stay.
- **A case can be made** (`readiness`, for STEP 3-6) when its season plan,
  its case plan and every asset its puzzles ask for (`assetNeeds`) are
  `approved`.

### The hash

`sha256:` and 64 lower-case hex digits. An asset's: its file's bytes. A
plan's: its JSON in a canonical form (`ContentHash.canonicalJson`), so the
same data written another way hashes the same and any value changed does not:

1. The file is read as JSON; what is not JSON has no hash.
2. Object keys sorted by UTF-16 code units; arrays keep their order.
3. No space or newline between tokens.
4. Strings as `jsonEncode` writes them (`"` and `\` escaped, control
   characters below U+0020 as `\b \f \n \r \t` or `\u00xx`, others as they
   are; no Unicode normalisation).
5. A number with no fraction (`3`, `3.0`) as an integer; others as Dart's
   shortest `double.toString()`.
6. `true`, `false`, `null` as they are.
7. Hashed as UTF-8.

### What a change touches

`ChangeImpact` compares a plan as approved (`approved/`) with the plan now,
and lists what to review again. It follows only what the plans name, and
changes nothing:

| Change | Review |
|---|---|
| A case added to, taken out of or moved in the acts | that case plan; every case plan given one of its clues (`clues_of_moved_case`) |
| A character or location changed or removed | the case plans that list it; a character's `firstCase`, `revealCase`, `secretUntil` |
| `mainMystery`, `figures` changed | the cases they name |
| A mission added or changed | that mission (its puzzle, its clue links) |
| A clue no longer left (an id changed), or left by another mission | every mission given it, of the case or another (`ClueGraphCheck`'s consumers) |
| A picture asked for now | that asset, with its approval status |
| A picture changed | every mission whose puzzle asks for it |

Any other field changed is listed for the record, with nothing to review.

### The command line

```sh
dart run tool/season_gen/approve.dart status  content_pipeline/seasons/s3_tokyo
dart run tool/season_gen/approve.dart status  content_pipeline/seasons/s3_tokyo case s3_ep01
dart run tool/season_gen/approve.dart approve content_pipeline/seasons/s3_tokyo case s3_ep01 --note "read through"
dart run tool/season_gen/approve.dart approve content_pipeline/seasons/s3_tokyo asset s3_tokyo.asset.hall --path assets/seasons/season_03_tokyo/hall.png
dart run tool/season_gen/approve.dart impact  content_pipeline/seasons/s3_tokyo
```

`approve` runs a plan's checks as `validate_plan.dart` does (a case plan
with the season plan beside it) and refuses one with errors. It then asks,
only when its input and output are a terminal, for the target's id to be
typed: input piped in is refused. Who approves is `--by`, or Git's
`user.name <user.email>`. `status` exits 0 when every target it shows is
approved; `impact` with no target looks at every stale target.

Not here: whether a picture is the right size, has transparency, or fits
its hot spots (a later step).

## Playable content (STEP 3-8)

A plan's words as the game shows them are written in the plan, in the game's
own JSON keys (`docs/STEP_3_7_GAME_DATA_MAPPING.md` §5): `CasePlan.play`
(intro, caseSummary…), `MissionPlan.play` (story, letter, question, hints,
successMessage, transition, map pin, clue and evidence words…),
`SeasonPlan.places` (each place's bundled picture) and `storyGreeting`. All
optional: a plan without them keeps its format and structure as before.

| File | What |
|---|---|
| `play_check.dart` | `PlayCheck`: what a case lacks to be generated, each by its JSON path (a choice needs 3 options, as the game asks) |
| `dart_literal.dart` | Dart constants written the same way every time |
| `generate_case.dart` | Command line: the plans' checks, `PlayCheck`, then the Dart files and their manifest |

```sh
dart run tool/season_gen/validate_plan.dart --season <season.plan.json> --playable <case.plan.json>
dart run tool/season_gen/generate_case.dart --season content_pipeline/seasons/s9_sandbox/season.plan.json \
  --target sandbox content_pipeline/seasons/s9_sandbox/cases/s9_ep01/case.plan.json   # --check: compare only
```

`--target sandbox` writes `test/sandbox/generated/<seasonId>/` only (never
`lib/`, never `SeasonCatalog`); `test/sandbox/sandbox_season.dart` puts it in
the real app for the tests (`test/sandbox/s9_ep01_test.dart`,
`integration_test/sandbox_case_qa_test.dart`). Only the sandbox's text
puzzles (`text_choice`, `order_sequence`, `word_entry`, `letter_tile_lock`)
are made. Nothing is written when a check fails; a generated file changed by
hand, or one without its header, is never written over (`--force`); line
endings are LF and read back CRLF-blind.
