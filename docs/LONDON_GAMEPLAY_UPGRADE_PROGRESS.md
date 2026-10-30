# London Case 02–12 gameplay upgrade — progress

> Started 2026-10-30 from `c662fbb` (main, working tree clean). Image budget
> approved by the user: **$2.00, at most 30 API calls** (gpt-image, one call
> at a time, each picture looked at before the next).
> Source of the plan: `docs/LONDON_GAMEPLAY_AUDIT.md`, checked against the code.

## Rules kept

- Mission ids, answers, clues, evidence, `nextMissionId`, hint counts (2) and
  tip prices unchanged. Scene tables are presentation only: the scene submits
  the mission's own answer, so `completedMissionIds`, the reward ledger
  (`mission:<id>`) and hint/coin records are untouched.
- Where a case's JSON changes (recall, option pictures, a mission type), the
  FNV pins in `final_small_pass_test.dart` / `audit_fix_d4_d5_test.dart` are
  updated with a dated note, as earlier passes did.
- Every new table has Junior and Master words (`season1Variants`).
- Case 01, Paris, Rome and New York content untouched. No sound added.

## Plan

| Case | Mission | Before | After | Engine | New picture |
|---|---|---|---|---|---|
| 02 | m2 | P1 4 options | search the belfry with R.'s note | InvestigationSearch | belfry, gear cut-out |
| 02 | m3 | P1 | P1 + Broken Clock Note brought from the notebook | recall | — |
| 02 | final | P6 number wheels | set Big Ben's hands to 9:17 | ClockQuestion in the final (new branch) | — (clock_face.png) |
| 03 | m2 | P1 names | black-and-white suspect sketches + Red Button recall | ImageChoice `picture` + recall | 3 sketches |
| 03 | m3 | P5 buttons | tap the four footprints' places in order on the Great Court | TrailOrder (new) | Great Court with footprints |
| 03 | final | P2 | P2 + Wet Footprint recall | recall | — |
| 04 | m2 | P1 | read the platforms, then choose one | DeductionScene | platforms |
| 04 | final | P3 | P3 + Black Wax Seal recall | recall | — |
| 06 | m2, m3, final | P3, P1, P1 | + Witness Notes / Detective Card recall | recall | — |
| 07 | m2 | P1 | note the boathouse's places, then choose | DeductionScene | boathouse inside |
| 08 | final | P1 evidence names | Mrs Robin's lie answered by presenting evidence | CaseTalk | Mrs Robin |
| 09 | m2 | P3 typing | letter tiles | LetterLock | — |
| 10 | m1 | P1 names | four raven pictures, names hidden | ImageChoice `picture` | 4 ravens |
| 11 | final | P1 | the Shadow unmasked by presenting Case 01's letter | CaseTalk | the Shadow |
| 12 | m1 | P1 | four gear pictures, names hidden (count the teeth) | ImageChoice `picture` | 4 gears |

## Log

- 2026-10-30: plan written; budget approved.
- **Case 02 done.** Pictures: `cases/case_02/big_ben_belfry.png` (gpt-image-2,
  $0.0428), `objects/brass_gear.png` (gpt-image-1.5 transparent, $0.0436,
  fitted to 512). Code: belfry search (`season1_investigations.dart` +
  Junior/Master in `ep02_levels.dart`), `recall` on ep02_m3, the final's
  Great Clock (`season1_clocks.dart` `ep02_final`; `FinalMissionScreen`
  `_clock` branch, stage kept `Offstage` until the solve so its face is
  decoded; `PuzzleEngineDispatch.finalMission` + palette `clock_set`).
  Belfry task lines kept as short as Gallery 8's: longer ones overflowed the
  search panel at 1.3× text with both tips open (found by the new test).
  Tests updated on purpose (old play pinned): case02_clock, case02_reasoning,
  season_playthrough, audit_fix_d4_d5 (D4 moved to ep05_m1; FNV ep02),
  final_small_pass (FNV ep02), inline_hints (→ ep02_m3), sound_prototype
  (→ ep05_m1), audio_wave2, new_artwork, evidence_recall. New:
  `test/london_upgrade_test.dart`. 503 related tests pass.
  Spent so far: $0.0864 (2 calls).
- **Case 03 done.** Pictures: one pencil sheet (`qa/…/visitor_sketches.png`,
  $0.0423) cut into `cases/case_03/sketch_mr_green|miss_rose|mr_grey.png`
  (460×760; a test checks they hold no colour), and
  `cases/case_03/great_court_footprints.png` ($0.0428; four identical
  footprints, the places not in walking order). M2: imageChoice with the
  sketches + `recall` of the Red Button. M3: new `TrailScene` /
  `TrailOrderQuestion` (`season1_trails.dart`, `SeasonContent.trails`,
  `SeasonCatalog.trail`, `DifficultyContent.structureOf`, dispatch step after
  `clocks`), kept out of the puzzle palette (Season Factory untouched).
  **Recall on finals dropped**: the final page has never shown a recall
  card, and Rome's Case 11 final carries one — showing it would change Rome.
  London finals keep their notebook tips instead (ep03, ep04, ep06).
- **Case 04 done.** Picture: `cases/case_04/kings_cross_platforms.png`
  ($0.0427). M2: `DeductionScene` — each platform noted with the porter's
  line (word for word; Case 12 quotes it), then RED · SMALL · CLOCK chosen.
  Tests moved off ep04_m2 where it was only "a plain MC": case_talk_mission
  (→ ep05_m1), type_b_phase2 (plays the deduction now).
  Spent so far: $0.2142 (5 calls).
- **Case 05 kept** (its final is TYPE B on purpose: the lid's order is read;
  picture locks would hand it over).
- **Case 06 done.** No picture. `recall` of the Witness Notes on m2 and m3.
  M1's witness talk written at Junior and Master (`ep06JuniorDialogues` /
  `ep06MasterDialogues`; structure, statement ids and things the base's):
  Case 06 is now written at every level — no London text falls back.
- **Case 07 done.** Pictures: `cases/case_07/boathouse_inside.png` ($0.0425)
  and `objects/small_wooden_box.png` (gpt-image-1.5 transparent, $0.0444).
  M2: search; every wrong place answers with its place word (NOT on the
  shelf, UNDER the table, BEHIND not in front of the can). Its opening view
  is the shelf, table and can (a whole-room opening left the can below the
  view at 1.3× text with both tips open — found by the new test).
- **Case 08 / Case 11 finals: held.** A `CaseTalk` final (evidence shown to
  Mrs Robin / the Shadow) has no tips on its page; London's finals have two
  (Tip 2 costs 20 coins). Adding tips to the talk page would change Paris's
  talk finals too. Kept as they are rather than drop the hint/coin policy.
- **Case 09 kept.** Letter tiles for ANNA were tried: the season validator's
  common rule wants the tiles to spell the answer exactly (no decoys), which
  leaves only ordering A N N A — weaker than reading "the letter after M".
  Reverted to its typed answer (file unchanged).
- **Case 10 M1: picture made, not applied.** `qa/london_upgrade/four_ravens.png`
  ($0.0421) is right, but Poppy's gold ring is ~20 px on the sheet, 6–10 px
  on a phone tile; gold vs silver would be too hard to see. Kept as words.
- **Case 12 done.** Picture: one sheet (`qa/…/four_gears.png`, $0.0423, teeth
  counted by eye: 8/6/8/8) cut into `cases/case_12/gear_*.png`. M1:
  imageChoice, names hidden, each wrong gear one word off.
  Spent so far: $0.4278 (10 calls).
- **Extra recall** (mission pages only): ep10_m3 → Raven Papers (ep10_e2),
  ep12_m1 → Case 02's Small Brass Gear (ep02_e2).
- **The final's clock on its own table** (`SeasonContent.finalClocks`,
  `SeasonCatalog.finalClock`): sharing `clocks` made the puzzle palette (the
  Season Factory's offer) change; the palette is left exactly as it was.
- **Saves**: `test/london_upgrade_test.dart` opens saves written before the
  upgrade (a started belfry with a tip bought and a wrong answer, a started
  final with both tips, a solved Case 03): all kept, nothing migrated —
  every new table is presentation only, keyed by the same mission ids.

## Final check (2026-10-31)

- `flutter analyze`: no issues.
- Full `flutter test` (run twice: the first found 6 tests pinning the old
  play, fixed): **3390 passed, 2 failed**. The 2 are
  `season_planner_test.dart` ("a hint that says the answer is a WARNING…",
  "English heuristics only warn…"), failing the same way at `c662fbb`
  (checked in a separate worktree): not from this work.
- Images: **9 calls, $0.3855 from usage** (`qa/london_upgrade/image_manifest.json`
  totals; budget $2.00 / 30 calls). The running "spent so far" lines above
  and commit 45a639e's message over-counted (they said up to 11 calls /
  $0.47): the manifest is the record. 8 calls are in the game (13 files: the
  sheets cut into cards); the ravens' sheet is not. Sources and the
  manifest stay in `qa/london_upgrade/` (gitignored).
- Not checked on a real iPhone.
