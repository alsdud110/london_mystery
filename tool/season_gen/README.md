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
puzzles (`text_choice`, `order_sequence`, `word_entry`, `letter_tile_lock`,
and the final's `combo_dial_lock`) are made (STEP 3-13 adds four on pictures, below). Nothing is written when a check
fails; a generated file changed by hand, or one without its header, is never
written over (`--force`); line endings are LF and read back CRLF-blind.

## A season in the game (the Rome integration)

`generate_season.dart --season <season.plan.json> --target game` makes the
season whole as the app plays it: the same files in
`lib/data/generated/<seasonId>/`, with its `SeasonContent`
(`<seasonId>_content.g.dart`) and its art (`<seasonId>_art.g.dart`: its map
and landmarks from `art.map`, every mission at its place's `locId`; its
cover from `art.cover`; its World Map city from `art.worldCity`; its evidence
pictures from its asset manifest), then the game's two lists of generated
seasons (`GameRegistry`: `generated_seasons.g.dart` read by
`SeasonCatalog.all`, `generated_season_art.g.dart` by `SeasonMap.bySeason`,
`ArtAssets.seasonCovers`/`evidencePictures` and `WorldCities.all`). Every
case of the season, its map drawn and measured on the file
(`art.map.measuredOn`), else nothing is written. A season in the game is
released; drafts say so in its manifest (`approved: false`). The season
factory (`tool/season_factory/`) runs it; `test/generated_seasons_test.dart`
checks and plays every season it made.

## The levels: Rookie, Junior, Master

A case's levels are its English, never its game. The plan is written once,
without any level; its words are Rookie's. `cases/<caseId>/levels.json`
(`case_levels.dart`) gives each Rookie line again at Junior and Master:

```sh
dart run tool/season_gen/case_levels.dart skeleton <case.plan.json>...   # every line, Junior/Master empty
dart run tool/season_gen/case_levels.dart check --season <season.plan.json> <case.plan.json>...
```

`check` lays each level's lines over the plan and checks that plan as the
plan is (schema, structure, puzzle selection, clue graph, `PlayCheck`), then:
every line written at both levels, none for a line the plan does not have,
a typed answer a line holds still in its level's words, a mission's
learning expressions still in its words, and nothing but the words changed
(`CaseLevels.sameGame`: the two plans with every word taken out are equal —
ids, answers, choices and their order, pictures, places, steps). What is a
word: the case's title, synopsis, hook, objectives, intro, summary and
place; a choice's label, line and alt text; a mission's learning
expressions; every string of a mission's `play` but its ids, pictures, who
speaks, a statement's `thing` (what two statements match by), an
inscription, a clue's value and the evidence link's line.

The season's own lines (its `outro` and `finale`) are written the same way
in `season.levels.json` beside `season.plan.json` (`SeasonLevels`), checked
by every `check`, given to the game as `SeasonContent.infoLevels`.

`--target game` takes every case at every level (`levels_missing`
otherwise); a sandbox, all of its cases or none. Made from them, beside
each case: `<caseId>_levels.g.dart` (its patch for
`SeasonContent.casePatches`, its puzzle tables at each level), and
`<seasonId>_levels.g.dart` (`casePatches`, `variants`, `writtenLevels`),
given to the season's `SeasonContent`. The game's `DifficultyContent`
checks them again (`test/difficulty_content_test.dart`).

## A season of cases (STEP 3-9)

| File | What |
|---|---|
| `season_cases.dart` | `SeasonCases.of`: the case plans a season's folder holds, in its play order |
| `generate_season.dart` | Command line: every case of the season made together |

```sh
dart run tool/season_gen/generate_season.dart \
  --season content_pipeline/seasons/s9_sandbox/season.plan.json --target sandbox   # --check, --force, --out
```

```
content_pipeline/seasons/<seasonId>/        test/sandbox/generated/<seasonId>/
  season.plan.json                            <seasonId>_season.g.dart
  cases/<caseId>/case.plan.json  (each)  →    <caseId>.g.dart            (each)
                                              <seasonId>_cases.g.dart    every case, for SeasonContent
                                              generated.manifest.json    cases in order, inputs' and outputs' hashes
```

- **Order** is the season plan's acts (Case 01–12). The cases written are
  its first ones: a case is unlocked by the one before it, so one written
  after a missing case is refused (`case_missing`), as is a folder of no case
  of the season (`case_not_in_season`), a case folder with no plan
  (`case_plan_missing`), a case or mission id given twice, a plan away from
  `cases/<caseId>/`. Their number is not fixed anywhere: one case or twelve.
- **All or nothing.** Every case's checks (`validate_plan`, the season's
  clue graph across cases, `PlayCheck`) run before anything is made; one
  case failing makes none. The files are then all written beside their
  places (`*.part`) before any is moved over the one it replaces, the
  manifest last; a file that cannot be written leaves the others as they
  were. The moves themselves are not one step: one failing midway leaves new
  files under the old manifest, which the next run reports as changed by
  hand (`--force` to write over them), never as up to date.
- `<seasonId>_cases.g.dart` lists every case made: the season's content
  (`test/sandbox/sandbox_season.dart`) takes it whole, so a new case needs no
  line written by hand. `generate_case.dart` with only some of a season's
  written cases is refused (`case_left_out`): it would leave the others out
  of that list.

The sandbox season holds Case 01 (STEP 3-6) and Case 02, "The Story Box
Code" (STEP 3-9, planned by Claude Code), played one after the other in
`test/sandbox/s9_multi_case_test.dart` and on a device by
`integration_test/sandbox_multi_case_qa_test.dart` (screenshots under
`qa/screenshots/sandbox/multi_case/`).

## Missions on pictures (STEP 3-13)

What London and Paris play, mission by mission, and what the generator makes
of it: [`GAMEPLAY_CATALOG.md`](GAMEPLAY_CATALOG.md). Besides the text
puzzles, the generator now makes four puzzles played on pictures, each on
the game's own engine (`PlayCheck.generatable`):

| Puzzle | Plan | Written into |
|---|---|---|
| `scene_explore_choose` (a look round) | `play.explore` | `<caseId>Explores` → `SeasonContent.explores` |
| `dark_room_search` (a search) | `play.search` | `<caseId>Investigations` → `SeasonContent.investigations` |
| `witness_compare` (a talk with witnesses) | `play.dialogue` | `<caseId>Dialogues` → `SeasonContent.dialogues` |
| `picture_choice` | `answerSpec.options[].picture`, `altText`, `play.hideOptionNames` | the case JSON (`ChoiceOption.picture`) |

- Places on a picture are its own pixels in the plan; the generator writes
  them as constant fractions (`Rect.fromLTRB(282 / 1536, …)`), as the game's
  scenes keep them. A picture's `pixels` are its file's (checked).
- A picture not on disk stops the generator (`asset_file_missing`); nothing
  stands in for it. Such puzzles are planned `awaitingAssets`.
- `PlayCheck` checks each scene's own rules (one letter and one choice in a
  look round, report lines in the letter, one pair of witnesses that agree,
  areas on their picture…): the table in the catalog, §4.4.
- Two changes in `lib/` made the search and the picture choice take a
  season's own files, the game's own content unchanged:
  `InvestigationScene.picture`/`pixels` beside its `Artwork`, and
  `ChoiceOption.picture`. `SeasonCatalog.testSeasons` (tests only, like
  `testPlaces`) lets a season outside the game find its scene tables.

The sandbox's Case 03, "The Travelling Book", is one mission of each:
`test/sandbox/s9_ep03_test.dart` checks it against its plan and the game's
validator, then plays it from the map with each engine's own controls.

## The story around the puzzles (STEP 3-13B)

Optional words in a mission's `play`, written into tables the game already
plays (no new screen). Without them a mission plays as it always did.

| Plan | Where | Written into | Played |
|---|---|---|---|
| `play.talk` (`speaker`, `goal`, `before` and/or `after`: `lines` of `{by, text}`, `finishLabel`) | missions | `<caseId>TalkMissions` → `SeasonContent.talkMissions` (`TalkMission`) | before: after INVESTIGATE, before the letter or the scene; after: after the right answer, before the Discovery Moment |
| `play.discovery` (`type`, `title`, `detail`, `timing`, `note`, `showEvidence`) | missions | `<caseId>Discoveries` → `SeasonContent.discoveries` (`Discovery`) | the Discovery Moment, in place of the success line |
| `play.ending` (`[{by, text, speaker, portrait, evidence}]`) | finals | `<caseId>Endings` → `SeasonContent.endings` (`EndingLine`) | after the final's answer; the case closes once it is seen, then its story and report |

- `by` is `speaker`, `detective` (YOU) or `narrator`. A talk has one person
  (`speaker`, a charId of the case); an ending's speaker lines each name
  theirs. Names come from the season plan, printed in capitals.
- The talks and the ending are over the mission's own place picture. A
  `portrait` is optional: none, no face is shown (never a stand-in).
- `PlayCheck` keeps each where its page plays it, the people the case's, an
  ending's evidence held by then (this case or one before), and the game's
  discovery timing rule (what was seen before the puzzle is never "found").
- One change in `lib/` made the talk before work with every puzzle: it now
  comes before any engine (it used to be shown only before the text puzzles
  and the talks), and after it the mission goes on to its letter or scene as
  INVESTIGATE leads without it (`MissionScreen`, `PuzzleEngineDispatch`).
- The talks are `final` in the generated files (`TalkScene` is not constant).

The sandbox's Case 02 has each of them: `test/sandbox/s9_presentation_test.dart`
plays it in the app (talks, discoveries, the ending, saves left halfway).

## Story faces, measured places, a slice (STEP 3-15A)

- **A face is the story's, not the puzzle's.** `PlayCheck.puzzlePictureFiles`
  (scenes, choices, witnesses: asked for in `assetNeeds`, `asset_file_missing`
  stops the generator) and `PlayCheck.storyPictureFiles` (a talk's or an
  ending's portrait: never in `assetNeeds`; one not on disk is
  `story_picture_missing`, a `PlayIssue` that is not `blocking`). The
  generator then writes the line without the face (never another one) and
  prints a note; once the portrait is drawn the next run writes it in.
- **Places measured on the drawn picture.** A scene's `picture` takes an
  optional `measuredOn`: the file's `sha256:` when its places (areas,
  marks, `guideAt`, `opening`) were measured on it. A look round or a search
  whose picture is on disk is made only when `measuredOn` is that file's hash
  now: `coordinates_unmeasured` (none), `coordinates_stale` (the picture
  changed since). The picture's size is its `pixels`, checked against the
  file as before. Places a prompt put somewhere are never played.
- **`--slice`.** `generate_case.dart --target sandbox --slice <case.plan.json>…`
  makes any run of a season's cases in play order (none missing between
  them), with only the places their missions use (each on disk), under
  `test/sandbox/generated/<seasonId>_slice/` (`"slice": true` in its
  manifest). Every other check is the same. The game's validator then finds
  one thing only, the slice itself: the case is numbered 05 but is the
  slice's first.

```sh
dart run tool/season_gen/generate_case.dart --season content_pipeline/seasons/s3_rome/season.plan.json \
  --target sandbox --slice content_pipeline/seasons/s3_rome/cases/s3_ep05/case.plan.json
```

Rome's Case 05 is played that way (`test/sandbox/rome_slice_season.dart`,
`test/sandbox/s3_rome_ep05_test.dart`): see
`content_pipeline/seasons/s3_rome/planning/STEP_3_15A_FIRST_PLAYABLE.md`.
