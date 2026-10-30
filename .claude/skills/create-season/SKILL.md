---
name: create-season
description: Make a whole new World Mystery season and put it in the game — plan it, draw its pictures within an image budget, check and measure them, generate it into lib/, register it (catalog, map, cover, World Map, unlock after the season before), play it through in tests, and report. Use when the user says things like "시즌 4 뉴욕 제작해", "시즌 4 뉴욕 제작해. 이미지 예산 $10", "create season 5 in Tokyo", or asks to finish/continue a season already planned so it can be played in the app.
---

# Create a season (plan → pictures → game)

The user gives a season number, a city and maybe an image budget (default
**$5.00** when none is given). Carry the season all the way into the game
yourself; do not stop to ask for approval between steps. Stop and report
only for: the budget would be passed, a user's save could be lost, an
existing season would have to change, a core error you cannot fix, or a
missing credential (`OPENAI_API_KEY` in `.env`).

Read first: `CLAUDE.md` (§20 gameplay, §21 testing), `tool/season_factory/README.md`.
Rome (`content_pipeline/seasons/s3_rome/`) is the worked example of every file.

## 1. Plan (no API call)

If `content_pipeline/seasons/s<n>_<city>/` does not exist yet, follow the
`plan-season` skill (`tool/season_planner/PLAYBOOK.md`) to write the story
bible, season plan, twelve case plans and `assets.manifest.json`; then
`plan_season.dart format` and `check` until there is no ERROR. Besides what
plan-season writes, the game target needs (Rome's `season.plan.json`):

- every `places[]` entry with its `locId` (one of `locations[].locId`);
- a `cover` and a `map` asset in the manifest (Rome's prompts: the map is
  an illustrated bird's-eye map, every location drawn apart and roughly
  where it really is, **no names, no pins, no writing**);
- `art.worldCity` (`cityId`, `latitude`, `longitude`; `mapAt` only when the
  World Map artwork draws that city: London, Paris, Rome, Tokyo and Seoul
  are drawn, see `lib/features/world_map/world_cities.dart`).

Before any picture: read each prompt against its mission. A choice's right
picture must differ from the wrong ones only by what the clue says (Rome's
helmets lost a torn strip only the right one showed); a mission's place
picture must never be its right answer (Rome Case 08 M1); a word with two
meanings is named plainly ("construction tower crane", not "crane").

## 2. Run the factory, again and again

```sh
dart run tool/season_factory/season_factory.dart status <seasonDir>
dart run tool/season_factory/season_factory.dart run <seasonDir> --budget <usd>
```

`run` goes on from where it stopped; act on its exit code and run it again:

| exit | what to do |
|---|---|
| 10 | fix the plans (`plan_season.dart check <seasonDir>`) |
| 20 | **open the review sheet PNG with the Read tool and look at every picture**: style like the season's others, faces as the character's other portraits, every clue the plans name visible, no text, choices fair, nothing giving an answer away. Then `season_factory.dart reviewed <seasonDir> <assetId>...` for the good ones, and for a bad one fix its prompt in `assets.manifest.json` and `season_factory.dart reject <seasonDir> <assetId> --why "<what was wrong>"`. Never mark a picture reviewed without looking at it. |
| 30 | open each grid sheet it names (Read tool), read the pixel positions off the grid and write them into the plans: the map's `art.map.landmarks` (each drawing's centre) with `measuredOn` = the sha256 it printed; a look round's `areas`, `mark`, `guideAt`, `opening` (every place's centre inside it), `picture.measuredOn`, and replace its `UNMEASURED` note with how it was measured. No two areas may overlap. If you cannot see a thing on the picture, do not guess: fix the prompt and reject the picture. |
| 35 | not a stop for the user: write the Junior and Master English yourself right away (§ Levels below, its steps), then run again |
| 40 | the budget is spent: stop and report how much more the remaining pictures need (`asset_pipeline.dart --manifest … --only …` dry run shows it) |
| 50 | read the generator's errors, fix the plans, run again |
| 60 | read the failing test, fix the cause (never weaken the test), run again |
| 1 | an API error or a copy problem: read it; retry once only when the cause is clear and fixed (a prompt the safety system refused: rewrite the part it names). Never loop. |
| 0 | the season is in the game and played through |

### Levels (Rookie / Junior / Master)

The levels are the English, never the game: all three play the very same
cases, missions, puzzles, choices (as many, in the same order), answers,
clues, evidence, pictures and rewards. The plans are written once, without
any level, and their English is Rookie's. Then each case's
`cases/<caseId>/levels.json` (the factory writes its skeleton) gives every
Rookie line again at Junior and at Master — never a new or replaced puzzle,
never a choice more or less.

- **Junior**: natural intermediate English, more varied words and
  sentences, hints moderately direct.
- **Master**: rich vocabulary, complex sentences, indirect hints — but never
  an answer's information left out or a reasoning step added.
- The same at every level: every fact and action, names (people, evidence,
  places, titles, ALL-CAPS labels), numbers, times, codes, the words a
  puzzle reads or the player types, `{detectiveName}`, a mission's short
  learning expressions (and its level sentences still hold them), a search's
  `reportLine` word for word inside its letter. Master still tells clearly
  how to play.
- The season's own lines (its `outro` and `finale`, shown when its last
  case is solved and on its completed board) are written the same way in
  `season.levels.json` beside `season.plan.json`, line for line.
- Harder words a level brings: `glossary.junior` / `glossary.master` (one
  lower-case word → Korean).
At exit 35 do this yourself, without asking (writing is not approving:
`approve.dart` and every other approval stay the user's):

1. The run printed each levels file still to write; the factory wrote its
   skeleton (every Rookie line; the lines already written kept). Write only
   the empty `junior` / `master` fields; never rewrite a line already
   written, a `rookie` line, or the plans. Read the case plan beside it for
   what each line is (a question, a choice, a hint, a clue, a letter).
2. Write each sentence again at its level — never copy Rookie's into it.
   Only a name, title, label, a short choice or the in-world writing a
   puzzle reads stays as it is. The check refuses a level that gives back
   more than half its sentences (six words or more) as Rookie's.
3. Twelve cases are a lot of English: a subagent for a few cases each, with
   these rules and the file paths; each writes and checks its own cases.
4. Check every case until it prints `ok` (the plan's own checks run on each
   level, every line written, answers and expressions kept, nothing but the
   words changed, not copied):
   `dart run tool/season_gen/case_levels.dart check --season <seasonDir>/season.plan.json`
   (no case given: every case of the season, found by the tool — no
   `cases/*` pattern, which PowerShell does not spread; one case: add its
   `case.plan.json` after it)
5. The checks hold an answer's words, not its meaning. Read
   `dart run tool/season_gen/case_levels.dart review <seasonDir>/season.plan.json`
   (every case; or one `case.plan.json`)
   (each mission's question, choices with the answer ✓, hints, clue,
   evidence, a line holding a typed answer — R / J / M one under another)
   for every case, and fix any line where Junior or Master would lead to
   another answer, leaves out what the answer needs, makes a wrong choice
   right, or gives the answer away more than Rookie does.
6. Run the factory again: it goes on from the levels step to generate.
   Stopped half way (a session ended)? `season_factory.dart status` lists
   the files still to write; the lines written are kept.

The generator makes `<caseId>_levels.g.dart` and `<seasonId>_levels.g.dart`
from them (`SeasonContent.casePatches`, `variants`, `writtenLevels`), and
`test/difficulty_content_test.dart` checks every level of every season is
the same game, every word written.

Cover framing (`art.cover.archiveLook`, `crop`, `push`): look at the cover
and set them so the city's landmarks, not the foreground, are framed
(Rome's: archiveLook `[0, 0.15]`, crop `[0.1, 0]`, push `[0, -0.1]`).

## 3. Finish

- `flutter analyze`, `flutter test test/generated_seasons_test.dart` (the
  factory runs both), then the whole `flutter test` (a new season is a
  release milestone, CLAUDE.md §21).
- `asset_pipeline.dart --manifest <manifest> --doctor`: everything as recorded.
- Back up `content_pipeline/asset_work/<seasonId>/` (not in Git) to
  `~/world_mystery_backups/<seasonId>_asset_work_<date>/` and compare sha256.
- Write `planning/FACTORY_REPORT.md` (Korean) and report in Korean: pictures
  made, reused, rejected and why, calls and cost (usage and conservative),
  budget left, what was measured, tests run and their results, what was not
  checked (a real device), what is left.

Never: change London's or Paris's stories, reset or rename saves, add a game
engine or sound, overwrite a file in `assets/`, delete a picture (rejected
ones go to `superseded/`), approve plans on the user's behalf
(`approve.dart` is theirs), commit or push unless asked.
