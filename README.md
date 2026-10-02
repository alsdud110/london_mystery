# London Mystery — Episode 01: The Missing Crown

An offline detective mission game for kids aged 8–12. Players solve English
clues and puzzles in a real play space:
**STORY → EXPLORATION → PUZZLE → DISCOVERY → REWARD**.

This is an MVP that runs entirely on local mock data (no backend).

## Run

```bash
flutter pub get
flutter run            # Android / iOS / Chrome / Windows
flutter test           # unit + full-playthrough widget tests
flutter analyze
```

The QR camera works on Android, iOS, macOS and web (web needs HTTPS or
localhost). On other platforms, or if camera permission is denied, the player
types the code printed under the QR card.

## Flow

Title → detective name → case file → typed story intro → **mission map** →
missions 01–05 → final Royal Box → Case Closed report (kid) → Detective Report (parent).
Progress is saved after every step, so closing and reopening the app resumes
the case.

Each mission has three steps, one action per screen:
**scene + sealed envelope → read the letter → solve the puzzle**. After a
solve: success celebration (XP, clue, evidence, new badges) → a short story
scene → back to the map, where the next pin plays a LOCKED → UNLOCKED ceremony.

| # | Location | Puzzle type | Answer | Clue | Evidence |
|---|----------|-------------|--------|------|----------|
| 01 | King's Cross | Multiple choice | B. The British Museum | 🚂 Platform **9** | Old Letter |
| 02 | British Museum | Word input | STONE (Rosetta Stone) | 🏛 Room **4** | Golden Key |
| 03 | Big Ben | Number code | 417 | 🕰 **7** o'clock | Pocket Watch |
| 04 | Hyde Park | Image choice | C. Buckingham Palace | 🌳 **2** swans | London Map |
| 05 | Buckingham Palace | QR scan | `LM-EP01-PALACE` | The Royal Box | Crown Symbol |
| Final | The Royal Archive | 4 picture locks | **7924** | — | The Missing Crown |

**Final case.** Each lock on the Royal Box shows a picture. The *Crown
Symbol* evidence shows the order of the pictures (clock, train, park, museum).
Each picture is a place, and each place gave a numbered clue. Reading the
clues in the order they were found (9472) is wrong. The player has to match
pictures to places.

### Game systems

- **XP**: +100 per mission (+200 final), +50 with no tips (+25 with one tip),
  +20 when solved within 2 minutes (3 for the final). Wrong answers cost nothing.
- **Detective Tips**: up to two per puzzle, from gentle to direct. They are
  recorded in the reports.
- **Badges**: First Clue, Sharp Eyes, Quick Thinker, Puzzle Solver, London
  Explorer, Master Detective (`features/game/scoring.dart`).
- **Notebook**: Clues / Evidence (tap to zoom in) / Badges.
- **Word cards**: harder words have a dotted underline. Tapping one shows its
  meaning (`glossary` in the episode data). Translations are never shown up
  front. Looked-up words are counted in the parent report.
- **Sound**: `core/utils/audio_service.dart` maps `GameSound` → file in
  `assets/sounds/` (success, wrong, unlock, clue, final, tap). Replace a
  file or change its name there. `MockAudioService` is the silent stand-in.

## Running a session (game master)

Long-press the round emblem on the title screen and answer the grown-ups
question to open the **Game Master** screen. From there you can:

- show or print the QR card for Mission 05 (with its typed fallback code),
- see the answer key for helpers,
- reset the device for the next child.

## Architecture

```
lib/
  core/        theme (colors, type, Material 3), router (go_router + guards),
               constants (storage keys, XP rules), utils (answer checker,
               formatters, sound service)
  data/        models (Episode, Mission, Clue, GameProgress), mock JSON,
               repositories (EpisodeRepository, ProgressRepository)
  features/    onboarding, mission_map, mission, notebook, result,
               game (Riverpod controller + providers), game_master
  widgets/     shared UI: GameButton, LetterCard/EnvelopeReveal, LandmarkArt,
               ClueCard, TypewriterText, PaperBackground, game toast
```

- **Content is data.** Missions live in `data/mock/season1/episode01_mock.dart` as the
  same JSON a backend would return and are parsed with `Episode.fromJson`.
  Adding an episode means adding data, not widgets.
- **Backend-ready.** `EpisodeRepository` and `ProgressRepository` are
  interfaces. To move to Firebase (or another backend), implement them and
  override `episodeRepositoryProvider` / `progressRepositoryProvider` in `main.dart`.
- **State.** `GameController` (a Riverpod `Notifier`) owns the run: unlock
  order, attempts, wrong answers, hints (counted once per mission), clues and
  the case timer. It saves after every change.
- **Access control.** The router checks every navigation. Locked missions, the
  final case, the results screens and the game master tools cannot be opened
  from a URL or deep link before they are earned.
- **Art and sound.** Landmark illustrations and the map are drawn with
  `CustomPainter`. Sound effects are generated by `tool/gen_sounds.js`
  (`node tool/gen_sounds.js`). Fonts (Cinzel, Fredoka, Nunito; SIL OFL) are
  bundled so the game works offline.

## Before release

- Replace the launcher icons and splash screen.
- If this is hosted on the web, set the security headers (CSP,
  X-Frame-Options, X-Content-Type-Options, Referrer-Policy) on the hosting
  layer.
- When a backend is added, validate answers and progress on the server as
  well. Today the answers ship inside the app, which is fine for an offline
  venue game but not for competitive or rewarded play.
