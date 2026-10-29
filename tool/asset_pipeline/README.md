# asset_pipeline — a season's pictures, made from its manifest

STEP 3-12A. Plain Dart (`dart run`, no package beyond the game's: resizing
uses `package:image`, already a dev dependency for `tool/prepare_splash.dart`).
Nothing here is imported by the game; nothing here writes `assets/` or `lib/`.

```
Season Planner → assets.manifest.json → asset_pipeline → ImageStudio (tool/ai_agents) → OpenAI Images API
                                         check, order, price, budget,
                                         make, check PNG, fit, record,
                                         wiring map, apply plan
```

| File | What |
|---|---|
| `asset_pipeline.dart` | Command line and `AssetPipeline`: dry run, generating runs, `--wiring`, `--apply-plan` |
| `asset_plan.dart` | `AssetPlan`: the manifest read, checked (`AssetManifest.check` and the pipeline's own checks), scheduled, priced; each asset's `ImageRequest` |
| `asset_scheduler.dart` | `AssetScheduler`: references first, else the manifest's order; a loop refused |
| `asset_budget.dart` | `AssetBudget`: conservative costs, the budget and call limits of a run |
| `asset_state.dart` | `PipelineState` (`pipeline_state.json`): each asset's status and files, each run |
| `asset_transform.dart` | `AssetTransform`: the API's picture fitted to the game's size (policy below) |
| `asset_wiring.dart` | `AssetWiring`: where the game shows each picture (`planning/asset_wiring.json`) |

Tests: `test/asset_pipeline/asset_pipeline_test.dart` (a fake API; no call to OpenAI).

## Use

```sh
# Dry run (the default): the check, the order, the costs, the wiring. Nothing sent or written.
dart run tool/asset_pipeline/asset_pipeline.dart --manifest content_pipeline/seasons/s3_rome/assets.manifest.json

# Make pictures: a budget is required; at most 3 calls unless --max-calls (≤ 50).
dart run tool/asset_pipeline/asset_pipeline.dart --manifest … --generate --max-budget 0.50 --max-calls 3
dart run tool/asset_pipeline/asset_pipeline.dart --manifest … --generate --max-budget 0.50 \
  --only s3_rome.asset.trevi_fountain --only s3_rome.asset.char_livia_base

# Where each picture is shown; --write keeps it in planning/asset_wiring.json.
dart run tool/asset_pipeline/asset_pipeline.dart --manifest … --wiring --write

# Without --generate, --max-budget/--max-calls/--only give the run's verdict (nothing sent).
# What a later step would copy into assets/ (writes nothing).
dart run tool/asset_pipeline/asset_pipeline.dart --manifest … --apply-plan
```

Exit codes: `0` done or a dry run; `1` a call or a picture failed; `2` refused
before any call; `64` usage.

## Where things go

```
content_pipeline/asset_work/<seasonId>/
  raw/<path under the asset root>     the API's picture, as it came (never changed)
  game/<path under the asset root>    the picture fitted to the game's size, only when it had to be
  pipeline_state.json                 every asset's status, files (sha256, size) and cost; every run
  image_manifest.json                 ImageStudio's call ledger: every request and call, usage, cost
```

The game's file is the manifest's `outputPath` (`assets/seasons/season_03_rome/…`),
written only by the apply step (STEP 3-12C), never here.

**Not in Git — back it up.** `.gitignore` leaves `content_pipeline/asset_work/`
out (large, paid-for files and run records). Git keeps no copy of them: after
a generating run, copy the folder somewhere safe (a shared drive, cloud
storage). Losing it means paying for the pictures again. The season's plans
(`assets.manifest.json`, `planning/asset_wiring.json`) stay in Git, and a
picture copied into `assets/` is tracked there. `.env` (the API key) is never
in Git either.

## Covers

A season cover is a portrait painting (`AssetManifest.coverSize`, 1024×1536,
the API's portrait size, shown as it is): London's and Paris's are 941×1672,
filling the phone by `BoxFit.cover`. Safe area on the 1024×1536 picture:

| Where | Shows | Keep there |
|---|---|---|
| y 0–460 (top 30%) | the season title over a shaded sky | open sky, nothing important |
| y 460–1300 | the city, unshaded | the main subjects |
| y 1300–1536 (bottom ~15%) | the BEGIN button on the stone | plain stone |
| x 170–854 | what a 9:20 phone keeps (9:16 keeps x 80–944), before a push of up to 1.165× | everything important |

The archive shows one 2:1 band (1024×512, `archiveLook`); the World Map a
56×72 thumbnail. The cover's prompt says so in words.

## STEP 3-12B: the first three pictures

| | Asset | Size, style | Estimate | Conservative |
|---|---|---|---|---|
| A | `s3_rome.asset.forum_view` (Case 09's Forum) | 1536×1024, `rome_scene` | $0.0481 | $0.0722 |
| B | `s3_rome.asset.char_livia_base` | 1024×1536, `character` | $0.0483 | $0.0725 |
| C | `s3_rome.asset.char_livia_hood`, drawn from B (images/edits) | 1024×1536, `character` | $0.1125 | $0.1688 |
| | | | **$0.2088** | **$0.3132** |

gpt-image-2, `medium`. C's estimate holds $0.064 for its reference picture
(8,000 image input tokens, an assumed upper bound, not OpenAI's figure).

```sh
# Check first (the verdict line): refused at $0.30, within at $0.32.
dart run tool/asset_pipeline/asset_pipeline.dart --manifest content_pipeline/seasons/s3_rome/assets.manifest.json \
  --only s3_rome.asset.forum_view --only s3_rome.asset.char_livia_base --only s3_rome.asset.char_livia_hood \
  --max-budget 0.32 --max-calls 3
# Then the same with --generate.
```

## Statuses

`pipeline_state.json` — `planned` → `generating` (call sent) → `generated`
(API picture checked whole) → `validated` (at the game's size, checked
whole); or `failed` (tried again by the next run) or `blocked` (a file is
there that is not as recorded: never reused, never written over; a person
moves it away).

`assets.manifest.json` keeps its own two: `planned`, and `generated` once the
picture is in `assets/` (the apply step). Its file is never touched by a
generating run, so the planner's checks and report stay as they were.

## Rules

- **Checked whole first.** Ids, fields, paths, sizes, styles, places against
  the case plans (`AssetManifest.check`), then: a priced model, a quality the
  model takes (`low`/`medium`/`high`; `xhigh`/`max` only on 2.5), gpt-image-2's
  pixel limits, at most 16 references, no reference loop, no transparent
  background on gpt-image-2 (a preview), each request as `ImageStudio` checks
  it. Any error: nothing made.
- **Order.** References first (a character's base before its poses, a place
  before a scene drawn from it), otherwise the manifest's order: the same
  manifest, the same order (Kahn's algorithm, earliest first).
- **Budget.** No `--max-budget`, no call. Every limit is checked at the
  conservative cost (the list-price estimate × 1.5; each reference picture as
  8,000 image input tokens, an upper bound: OpenAI gives no count for
  gpt-image-2). The run's planned calls over the budget: refused whole. During
  the run, each call's usage at list prices is spent (a call with no usage, or
  a failed one, at its conservative cost), and the next call is made only if
  it still fits. Estimates are not the bill.
- **Calls.** At most `--max-calls` a run (3 by default, 50 at most).
- **Once.** A validated picture is never made again (its files are checked
  against their sha256 on every run). A request already made with its file
  intact is not sent again (`ImageStudio`'s ledger), even if the state was lost.
- **Resume.** A run goes on where the last stopped: failed pictures first in
  their place in the order, then the planned. A call left `generating` (the
  process died) is `failed`: it may have been billed, its picture is not trusted.
- **Errors.** An API error stops the run at once; nothing more is sent.
- **Never over a file.** `ImageStudio` never writes over a file; the pipeline
  never writes over a game copy that is not its own.

## Reference pictures

A picture with `references` is drawn from its references' validated pictures
through `POST /v1/images/edits` in its JSON form (API reference, checked
2026-10-29): the generation's fields plus `images: [{"image_url": "data:image/png;base64,…"}]`,
at most 16, each data URL at most 20,971,520 characters. Not sent:
`input_fidelity` (gpt-image-2 takes none: it reads every input at high
fidelity), `mask`. Each reference is checked whole (`PngCheck`) before sending;
its bytes are part of the request's key, so a changed reference is a new request.
The prompt gets one line before its style: keep the reference's look.

## Fitting to the game's size

The manifest holds only the sizes the API makes (`1536x1024`, `1024x1536`,
`1024x1024`), so Rome's 47 pictures need no change: the API's picture is the
game's. When an answer comes back at another size (or a later season plans
the game's older sizes, as `1122x1402`):

- the original stays as it came (`raw/`); the fitted copy goes to `game/`;
- scaled to cover the frame, proportions kept, never stretched; what lies
  beyond is cropped: centred, or from the top for characters (heads kept);
- shrinking averages; enlarging (cubic) at most 1.25×; at most 25% cropped
  away; past either, refused (ask for the right size instead);
- transparency kept (RGBA stays RGBA); the result is checked whole and must
  be exactly the planned size.

## Wiring (where the game shows each picture)

`planning/asset_wiring.json`, from the game's code as of 2026-10-29:

| Status | Meaning | Rome |
|---|---|---|
| `wired` | the plans already name the file where the game reads it, and the generator writes it | 18 places (`SeasonContent.places`) |
| `ready_to_wire` | the game has a place for it; a `lib/` line (`libEdit`) or a generator table (`generatorExtension`) is missing | 14 evidence pictures (`ArtAssets.evidencePictures`), the cover (`ArtAssets.seasonCovers`), the map (`SeasonMap.bySeason`), the owl scene (`SeasonContent.storyScenes`) |
| `blocked` | the game has a place, but the picture as planned does not fit it | none |
| `not_supported` | no screen shows it for a generated season | 10 portraits, the prologue, the gold tiles (no evidence id) |

Rome's `ready_to_wire` also holds the cover (portrait since STEP 3-12A's wrap-up;
not wired until a `SeasonCover` line is in `lib/`).

## Applying pictures to the game (STEP 3-12C, designed here)

1. Run the pipeline until the pictures are `validated`.
2. Look at each, then approve it as it is staged:
   `dart run tool/season_gen/approve.dart approve <seasonDir> asset <assetId> --path <its game file>`.
3. `--apply-plan` lists each validated picture, its destination (`outputPath`),
   a CONFLICT where a file is already there (never written over), its
   approval, and the `pubspec.yaml` folders to list under `flutter: assets:`.
4. The copy (to be written in 3-12C): every approved picture copied beside its
   destination (`.part`), checked against its approved hash, then all moved;
   any failure removes the copies made, so `assets/` is as it was. Then the
   manifest's `status` is set to `generated` and `pubspec.yaml` gets the folders.
5. `plan_season.dart check`, then `generate`: the place pictures on disk, the
   generator stops waiting for them.

Names: the manifest's `outputPath` is the file name (`snake_case.png`, under
`assets/seasons/season_NN_<city>/`), checked by the planner; places at the
file `season.plan.json` shows.
