# Season planning playbook (for Claude Code)

How Claude Code plans a whole new season when asked "시즌 3 로마 제작해" /
"Make Season 4, New York". The user gives a season number and a city; Claude
decides everything else (title, mystery, people, places, twelve cases,
puzzles, answers, hints, clues, ending, pictures) and reports back. Do not
ask the user for case titles or puzzle answers. Ask only when the request
would change an existing season or a decision the user already made.

The Dart tools (`plan_season.dart`) never write a story: they make the
folder, check what Claude wrote, and keep the report. Creativity is Claude's;
correctness is checked by the tools. No API is called and no picture is made
at this stage (pictures are a later step).

---

## 0. Before writing anything

1. `git status`; read `CLAUDE.md` (§20 gameplay, §22 for Paris).
2. Read the trial season as the worked example: `content_pipeline/seasons/s3_rome/`
   (season plan, one or two case plans, `planning/story_bible.json`,
   `assets.manifest.json`). Copy its shapes, never its story.
3. Read `tool/season_gen/README.md` (formats, checks) and, for wording rules,
   `docs/STEP_3_7_GAME_DATA_MAPPING.md` if a field is unclear.
4. Check the number is free: `content_pipeline/seasons/s<n>_*` and the game's
   `SeasonCatalog` (`lib/data/mock/season_catalog.dart`). London is 1, Paris 2.
   A taken number, or a story that must connect to London/Paris, is reported
   to the user before planning.

```sh
dart run tool/season_planner/plan_season.dart init --season 4 --city "New York"
```

`init` makes `content_pipeline/seasons/s4_newyork/` with `planning/brief.json`
and `cases/`, and refuses a folder or a number already there.

## 1. The season first (story bible)

Write `planning/story_bible.json` before any case. It is the writer's truth:

- **coreMystery**: question, truth, culprit, motive, method, revealCase (Act 3),
  resolvedCase (Case 12). Realistic: no magic, no real time travel, nothing
  frightening for 8-12.
- **characters** (6-9): charId, name, role, personality, purpose, appearance
  (the portrait prompt is written from it), relationships, cases. One
  culprit, at least one red herring cleared by evidence, one helper with a
  secret, a partner who travels with the player.
- **locations** (8-12 real places of the city, at most one made up): cityArea,
  visual, storyRole, cases, placeIds (the scenes the missions happen in).
- **acts**: Act 1 the mystery starts and turns (a reveal at Case 04); Act 2 it
  widens (the red herring cleared, the helper revealed at Case 08); Act 3 the
  truth (the culprit caught at Case 11, resolved at Case 12). Shape it to the
  city's story; do not copy Rome's beats.
- **cases** outline (12): question, solution, fromPrevious, toNext.
- **mysteryQuestions**: every question the season raises, with the case that
  answers it. None left open.
- **clueThreads**: clues of one case used by later missions (`from` → `to`).
  Aim for 20+ threads, several two or more cases apart.
- **timeline**, **themes**, **startingSituation**, **ending**.
- **englishReview**: written last (step 5), one per case.

Then `season.plan.json` from it: the same ids and names, `plannedCases: 12`,
three acts of four, `mainMystery`, `places` (each place's picture file under
`assets/seasons/season_NN_<city>/`, 1536x1024), `outro`, `finale`,
`languageArc`, notes that say it is planned, not released.

## 2. The twelve cases

Write `cases/<caseId>/case.plan.json` for Case 01 to 12, in order, each from
the bible. Run the checks after each case or two (step 4) instead of at the end.

**What the generator makes today** (`PlayCheck.generatable`): only text
puzzles, played by the mission page's own widgets. Each case is 3 missions
and a final:

| Puzzle (`paletteId`) | `missionType` | Where | Answer data |
|---|---|---|---|
| `text_choice` | `multipleChoice` | mission, final | 3+ options; every wrong option has `feedback` |
| `word_entry` | `wordInput` | mission, final | `answer`, `acceptedAnswers`; `play.prompt`, `play.feedback` for likely wrong words |
| `order_sequence` | `sequence` | mission, final | options, `answer` "a,b,c", `codeLength` (extra options are decoys) |
| `letter_tile_lock` | `letterLock` | mission, final | one option per tile, the tiles spell the answer exactly |
| `combo_dial_lock` | `finalCode` | final only | digits, `codeLength`, `dialSymbols` (GameSymbols) |

Anything else (scenes, lenses, talks, picture choices) needs pictures and
engine data: plan it as `awaitingAssets` or `devRequest` only if the user
asks, and say the generator cannot make it yet.

**Every mission** needs, in `play`: title, location (CAPS), story (2-4 lines),
letterIntro, letter (the document the player reads), question, hints (2),
successMessage, transition (2-4 lines), mapX/mapY, clue (missions 1-3, its
id in `clueOutputs.clue`), evidence (always). `symbol`/`icon`/`dialSymbols`
are GameSymbols: train museum clock park palace crown raven gear letter key
watch map ticket feather footprint button cloth seal frame mask gem bag
umbrella whistle. At most one `recall` input (evidence, with `play.recall`)
and one `evidenceLink` (with `evidenceLinkLine`). Case `play`: objectives,
intro, caseSummary, place, keyWords, glossary (one lower-case word each).

**Puzzle design rules** (CLAUDE.md §20):

1. The answer is deduced from what the player read in this case or found
   before; never guessed, never outside knowledge (give the list, the
   definition, the guidebook line inside the letter).
2. The English is the tool: reading a log, comparing times, following
   before/after, a definition, a code with its rule stated, a witness who
   contradicts the evidence.
3. The four puzzles of a case are four different kinds, and at least one is
   hands-on (order, tiles or dials). Spread the kinds over the season (no
   kind more than half).
4. Wrong-answer lines point back to the text without giving the answer.
   Hints: the first says where to look, the second how to think. Neither
   says the answer.
5. Long-range clues matter: a later case `recall`s or `answerDerivation`s
   evidence from two or more cases before. Every case after Case 01 uses a
   clue of an earlier case.
6. At least one final collects letters found in the case's missions and
   arranges them into a meaningful word.
7. A final closes the case's question; its transition opens the next case.

**English for 8-12**: sentences of 15 words or fewer, everyday words, harder
words in the glossary, letters under ~110 words, the same key phrase
consistent across the season. The story may be deep; the lines stay short.

## 3. The pictures (assets.manifest.json)

Written with the cases, not after them. One entry per picture:
`assetId` (`<seasonId>.asset.<name>`), `type` (cover, map, prologue, place,
scene, character, object, document), `use` (`seasonPlace` for a place's
picture, else `notWired`), `subject` (placeId, charId, evidence id, or
`<seasonId>.<name>`), `caseIds`, `description`, `prompt`, `stylePreset`,
`width`/`height`, `transparent: false`, `outputPath`, `references`,
`status: planned`, optional `pose` (characters) and `notes`.

- Every `season.plan.json` place has one `place` asset at the **same file and
  size**. Never point a place at another season's picture.
- Define the city's scene style once in `seasonStyles` (the common lines of
  `tool/ai_agents/image_styles.dart` + the city's look); characters and
  objects use `character` / `object`.
- Every character has a `base` portrait; any other pose `references` it.
  An object drawn from another (a copy of a real thing) references it.
- One picture serves every case that shows the same thing (list all its cases).
- No text in pictures: signs, papers and tiles are blank; the game writes words.

## 4. Check, fix, repeat

```sh
dart run tool/season_planner/plan_season.dart format content_pipeline/seasons/<id>
dart run tool/season_planner/plan_season.dart check  content_pipeline/seasons/<id>
dart run tool/season_planner/plan_season.dart assets content_pipeline/seasons/<id>
```

`check` runs the season_gen checks (schema, structure, puzzle selection,
clue graph, PlayCheck), the real generator in memory, and the planner's own
(twelve cases, people and places, bible, manifest, puzzles, English
heuristics), then writes `planning/quality_report.json`.

- **ERROR**: fix it. Nothing is generated while one is left.
- **WARNING**: read each; fix the real ones (a long sentence, a hint that
  says the answer). `clue_never_used` on notebook evidence is normal.
- **INFO** `image_pending` / `generator_waits_for_pictures`: expected until the
  pictures are made. Never silence them with placeholder or borrowed pictures.

Also run `flutter test test/season_planner/` if the tools changed, and read
every case once through as a player: does each answer follow from the text?

## 5. English review, then report

Read each case's English and write its `englishReview` entry (level,
verdict, notes). The heuristics count words; this is the judgment. Run
`check` again so the report includes it.

Report to the user (in Korean): title, core mystery, the three acts, the
twelve case titles, characters, places; missions, puzzle kinds, clue links,
the English review; the pictures (count by kind, reused, estimated cost);
the checks (ERROR/WARNING/INFO, generator status); what is not verified
(pictures, device play) and what the next step needs. No commit or push
unless asked.
