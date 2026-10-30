# season_factory — a planned season carried into the game

The Rome integration. One command for the whole way from a season's plans
(`content_pipeline/seasons/<seasonId>/`) to the season in the app, made of
the tools that already do each part. Nothing here plans, draws, measures
or generates by itself; it calls them in order and stops where a person's
(or Claude's) eyes are needed. The Claude Code skill that drives it:
`.claude/skills/create-season/SKILL.md` ("시즌 4 뉴욕 제작해. 이미지 예산 $10").

```
plan_season.dart (plans, check)
  → asset_pipeline.dart (--doctor --fix, --generate, review, --apply)
  → measured on the made pictures (grid sheets, written into the plans)
  → generate_season.dart --target game (lib/data/generated/, registered)
  → flutter analyze, test/generated_seasons_test.dart
```

| File | What |
|---|---|
| `season_factory.dart` | `status`, `run`, `reviewed`, `reject` |
| `sheets.dart` | review sheets (a batch of pictures, numbered) and grid sheets (a line every 50 px) |

```sh
dart run tool/season_factory/season_factory.dart status   content_pipeline/seasons/s4_newyork
dart run tool/season_factory/season_factory.dart run      content_pipeline/seasons/s4_newyork --budget 10 [--batch 4] [--full-tests]
dart run tool/season_factory/season_factory.dart reviewed content_pipeline/seasons/s4_newyork ev_owl_card cover   # or --all
dart run tool/season_factory/season_factory.dart reject   content_pipeline/seasons/s4_newyork ev_business_card --why "a bird, not a construction crane"
```

## The steps of `run`

Each is done only when it is not done yet: run it again after any stop.

| # | Step | Stops with |
|---|---|---|
| 1 | Every plan check (`SeasonQuality`, the report written) | 10: an ERROR |
| 2 | `--doctor --fix`: this machine's records against the game's files (below) | — |
| 3 | Pictures made here and not looked at: a review sheet | 20: look, then `reviewed` / `reject` |
| 4 | The next `--batch` pictures the game shows, within the budget | 20 (review), 40 (budget), 1 (API error) |
| 5 | `--apply`: validated pictures into `assets/`, manifest, `pubspec.yaml` | 1: a conflict |
| 6 | Anything not measured on the made pictures: a grid sheet | 30: measure, write into the plans |
| 7 | `generate_season.dart --target game` (content, art, the game's lists) | 50: generator errors |
| 8 | `flutter analyze`, `flutter test test/generated_seasons_test.dart` (`--full-tests`: all) | 60: a failure |

**The budget** is the season's (`--budget`, US dollars at list prices; the
bill is OpenAI's): what the factory spent before is kept in
`planning/factory.json` (in Git, so every machine sees it) and taken off.
Each call is checked at its conservative cost before it is sent; the
pipeline's rules hold (no call without a budget, an API error stops the run,
a picture made is never made again, never over a file).

**The pictures the game shows** (step 4): every one a case shows (places,
choices, faces), the cover, the map and each evidence picture. Not one no
screen shows (`not_supported` in the wiring), nor a story scene the
generator has no table for.

**Review** (step 3) is a look, never a verdict of the tool's: a picture is
`reviewed` only once someone has looked at it. `reject` sets the picture
aside (`asset_work/<id>/superseded/`, never deleted, with its record and
why) so the next run makes it again from its fixed prompt.

**Measuring** (step 6): the season map's landmarks (`art.map`, each
location's drawing centre, `measuredOn`) and every look round's areas
(`play.explore`, `picture.measuredOn`, no `UNMEASURED` note) are read off a
grid sheet of the very file and written into the plans. Nothing is guessed:
what cannot be seen on the picture means a new picture.

## Two machines

`content_pipeline/asset_work/` (the API's pictures and their records) is not
in Git; the game's copies in `assets/` are. On a machine that did not make a
picture (or whose work folder was lost or is older):

- a picture already in `assets/` is never made again here (`in game`);
- `--doctor --fix` records it as made, its picture a copy of the game's
  (`adopted`), and puts back a missing picture whose game copy has its
  recorded sha256 (`restored`);
- a picture here that differs from the game's is a `CONFLICT`, left as it
  is; a picture the manifest says is in the game but is not refuses every
  run (`asset_file_missing`): restore it from Git or a backup.

Nothing is synced to the cloud: back the work folder up yourself
(`~/world_mystery_backups/`).

## What stays a person's

- Approvals (`tool/season_gen/approve.dart`): a season in the game made
  from drafts says so in its manifest (`approved: false`).
- Looking at the pictures and measuring on them (Claude does both by
  reading the sheets; the tool never decides).
- A real device: the tests run in Flutter's test binding and on an emulator.
