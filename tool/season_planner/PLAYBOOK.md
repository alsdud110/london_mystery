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

**What the generator makes today** (`PlayCheck.generatable`; the whole map
of the game's play types is `tool/season_gen/GAMEPLAY_CATALOG.md`). Each case
is 3 missions (up to 5) and a final.

Text puzzles, played by the mission page's own widgets (`status: ready`, no
picture beyond the place's):

| Puzzle (`paletteId`) | `missionType` | Where | Answer data |
|---|---|---|---|
| `text_choice` | `multipleChoice` | mission, final | 3+ options; every wrong option has `feedback` |
| `word_entry` | `wordInput` | mission, final | `answer`, `acceptedAnswers`; `play.prompt`, `play.feedback` for likely wrong words |
| `order_sequence` | `sequence` | mission, final | options, `answer` "a,b,c", `codeLength` (extra options are decoys) |
| `letter_tile_lock` | `letterLock` | mission, final | one option per tile, the tiles spell the answer exactly |
| `combo_dial_lock` | `finalCode` | final only | digits, `codeLength`, `dialSymbols` (GameSymbols) |

Puzzles played on pictures (STEP 3-13; `status: awaitingAssets`, their
pictures in `assetNeeds` and in the manifest with `use: puzzle`). The worked
example is the sandbox's `s9_sandbox/cases/s9_ep03/case.plan.json`.

| Puzzle (`paletteId`) | `engineTable` · `missionType` | The detective… | Plan data |
|---|---|---|---|
| `scene_explore_choose` | `explores` · `multipleChoice` (missions) | looks round a place, finds the thing that holds the letter, notes what is seen, then picks one of the pictures the letter points to | `play.explore`: the place picture, spots (one `document`, one `choice` that `requires` it, `note`s), empty places (`others`), the choice pictures (one per option, one size) |
| `dark_room_search` | `investigations` · `multipleChoice` (missions) | reads a report and finds each thing where its line says (under, on, next to…), zooms, drags | `play.search`: the room picture, finds (each `reportLine` a line of the letter word for word, its cut-out picture), empty places with a line that teaches the word |
| `witness_compare` | `dialogues` · `multipleChoice` (missions) | chooses a witness, asks questions, compares two statements to find the two that agree (or the one that contradicts) | `play.dialogue`: the place, questions, witnesses (portrait, answers; an answer with a `thing` is a statement `<witness>.<question>`), the deduction (`topic`, the one `pair`, `then` still to hear) |
| `picture_choice` | none · `imageChoice` (mission, final) | reads a description and looks at 3-4 pictures (names hidden with `play.hideOptionNames`) | each option's `picture` and `altText` (what it shows, for screen readers) |

**Places on pictures** are written in the picture's own pixels (`[left, top,
right, bottom]`, `[x, y]`), with the picture's size as its file has it. While
a picture is only planned, its places are where its prompt puts things:
write the prompt so each target is where the scene says ("the suitcase on
the bench, lower left, about a sixth of the width"), and say in the
mission's `notes` that the areas are to be measured on the made picture.
Once it is made, measure each area on the file and correct the plan before
anything is generated. A picture not on disk stops the generator
(`image_pending` here); never put another picture in its stead.

Other engines (lens, traces, a talk with evidence shown, step by step,
spot the difference…) need their scenes in a plan first: plan them as
`awaitingAssets` only if the user asks, and say the generator cannot make
them yet (`generate_unsupported`).

**Choosing how each mission is played.** Start from the case's clue, not
from a list: what is the player finding out, and what would a detective
physically do there? A letter or log read closely → a text puzzle; a place
where something was left → a look round; a report of where things are → a
search; people who saw something → a talk; a description of a thing or a
place → a picture choice. Then check the season as a whole: the same kind
of mission no more than about a third of the season, at least one mission
on pictures in most cases, no two cases in a row with the same set of
kinds. There is no quota per kind; `PuzzleSelectionCheck.season` warns when
one kind is more than half.

**Rules for puzzles on pictures** (on top of the rules below):

- The answer is seen or deduced, never guessed: the picture shows what the
  English says (the poster with the mummies the letter names; the footprint
  next to the door the report names; two witnesses who say the same thing).
- Every place in a scene that holds nothing says something useful when
  tapped ("Nothing on the bench. The report says UNDER it."): a wrong tap
  teaches the word.
- A talk has exactly one pair that answers it (`scene_ambiguous` otherwise),
  and what is heard after it (`then`) is used later in the case or season.
- Picture choices with names hidden are told apart by the words of the
  letter (colour, shape, what it has), never by the picture's style alone,
  and never by colour alone (say "two brown straps", not only "brown").
- Targets big enough for a finger (60 px or more on a 1536 px picture), all
  inside the part the page opens on (`opening`).

**Every mission** needs, in `play`: title, location (CAPS), story (2-4 lines),
letterIntro, letter (the document the player reads), question, hints (2),
successMessage, transition (2-4 lines), mapX/mapY, clue (missions 1-3, its
id in `clueOutputs.clue`), evidence (always). `symbol`/`icon`/`dialSymbols`
are GameSymbols: train museum clock park palace crown raven gear letter key
watch map ticket feather footprint button cloth seal frame mask gem bag
umbrella whistle. At most one `recall` input (evidence, with `play.recall`)
and one `evidenceLink` (with `evidenceLinkLine`). Case `play`: objectives,
intro, caseSummary, place, keyWords, glossary (one lower-case word each).

**The story around the puzzles** (optional, STEP 3-13B; the worked example
is the sandbox's `s9_sandbox/cases/s9_ep02/case.plan.json`). Use them where
the story needs a voice, not on every mission:

- `play.talk.before` — a short talk with a person of the case before the
  puzzle: what the detective must look into, and why now. It never gives the
  answer. Then the letter or the scene, as without it.
- `play.talk.after` — the person reacts to what was just found (surprise,
  worry, a new question). Then the Discovery Moment.
- `play.discovery` — the Discovery Moment in the mission's own words:
  `title` what was found (a few words, often CAPS), `detail` why it matters
  and where it leads next (one or two short sentences). `type`:
  evidenceFound (with `showEvidence: true`), clueFound, clueConfirmed (seen
  before the puzzle: `timing: beforePuzzle`), deduction, newLead,
  storyDiscovery. Never the success line again, never the same title twice.
- `play.ending` (finals only) — after the answer: the people react to the
  solution, one line says what the key clue meant (lay its `evidence` on
  it), and a last line leaves a small question for the next case.

Lines are 3-12 words for ages 8-12, one sentence each; `by` is `speaker`,
`detective` or `narrator`; a talk's `speaker` (and each ending speaker) is a
charId of the case. A `portrait` is the character's portrait file, only once
it is planned in the manifest; without one, no face is shown.

**Puzzle design rules** (CLAUDE.md §20):

1. The answer is deduced from what the player read in this case or found
   before; never guessed, never outside knowledge (give the list, the
   definition, the guidebook line inside the letter).
2. The English is the tool: reading a log, comparing times, following
   before/after, a definition, a code with its rule stated, a witness who
   contradicts the evidence.
3. The four puzzles of a case are four different kinds, and at least one is
   hands-on (order, tiles, dials, or a mission on pictures). Spread the
   kinds over the season (no kind more than half; see "Choosing how each
   mission is played" above).
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
- Every picture a puzzle shows (a scene's picture, a found thing cut out, a
  witness portrait, a picture option) is an asset with `use: puzzle`, its
  `outputPath` the file the plan names, its id in the puzzle's `assetNeeds`
  (`asset_scene_unplanned` is an ERROR). A witness who is a season
  character reuses their portrait; a talk's background may be the place's
  own picture.
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
