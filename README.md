# London Mystery — Episode 01: The Missing Crown

An offline detective mission game for kids aged 8–12. Players solve English
clues and puzzles in a real play space:
**STORY → EXPLORATION → PUZZLE → DISCOVERY → REWARD**.

The game is **100% offline**: no account, no sign-in, no server, no network
request. Each device has exactly one detective (a boy or girl picture and a
name), kept on the device with all of its progress
(`docs/OFFLINE_SINGLE_DETECTIVE.md`).

## Run

```bash
flutter pub get
flutter run            # Android / iOS / Chrome / Windows
flutter test           # unit + full-playthrough widget tests
flutter analyze
```

Every mission is played on the device alone: no camera, no printed cards and
no helper needed (Mission 05's crown card is examined in its own scene).

## Flow

Title → **CREATE YOUR DETECTIVE** (boy / girl, name) → How to Play → case
file → typed story intro → **mission map** → missions 01–05 → final Royal Box
→ Case Closed report (kid) → Detective Report (parent).
Progress is saved after every step, so closing and reopening the app resumes
the case. The detective's name and picture can be changed later from the map
menu (**My detective**); progress, XP, coins and badges stay.

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
| 05 | Buckingham Palace | Card examined in the scene | (nothing to type: the card's code shows the lock order) | The Royal Box | Crown Symbol |
| Final | The Royal Archive | 4 picture locks | **7924** | — | The Missing Crown |

**Final case.** Each lock on the Royal Box shows a picture. The *Crown
Symbol* evidence shows the order of the pictures (clock, train, park, museum).
Each picture is a place, and each place gave a numbered clue. Reading the
clues in the order they were found (9472) is wrong. The player has to match
pictures to places.

### Game systems

- **XP**: +100 per mission (+200 final) for everyone who reaches the answer:
  wrong answers, tips and time change nothing (XP rule 3). Missions solved
  under an earlier rule keep the XP they earned (`GameProgress.xpRules`).
- **Detective Tips**: up to two per puzzle, from gentle to direct. They are
  free and recorded in the reports. Some wrong answers show a short line
  about what was misread (never the answer).
- **Badges**: First Clue, Puzzle Solver, London Explorer, Master Detective,
  a case badge for six of the cases, and three optional detective-action badges
  (Second Look, Notebook Explorer, Word Collector) earned only by recorded
  actions, never by speed or a first try. Sharp Eyes and Quick Thinker are
  no longer given; saves that hold them keep them (`features/game/scoring.dart`).
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
- **One detective, on the device.** `ProfileStore` keeps the device's
  detective (`lm.detective.v1`); `LegacyMigrator` brings earlier saves to it at
  start (copy, read back, verify; nothing is removed). `ProgressRepository`
  saves each change at once, several keys all-or-nothing (`SaveJournal`).
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

- Check launcher icons and the native splash on devices.
- If this is hosted on the web, set the security headers (CSP,
  X-Frame-Options, X-Content-Type-Options, Referrer-Policy) on the hosting
  layer.
- The answers ship inside the app, which is fine for an offline game but not
  for competitive or rewarded play.
- Add the two avatar pictures (`assets/art/avatars/detective_boy.png`,
  `detective_girl.png`); the folder is already listed in `pubspec.yaml`.

## Native splash screen

Android and iOS use [splash_logo.png](assets/branding/splash_logo.png) on
`#151D30` in both light and dark mode. Configuration lives in
[pubspec.yaml](pubspec.yaml). After replacing the image, regenerate with:

```sh
flutter pub get
dart run tool/prepare_splash.dart
dart run flutter_native_splash:create
```

Rebuild and cold-launch the app; hot reload does not update native launch screens.
Android 12 masks the image to a circle: artwork on a 1152px canvas should fit
within the central 768px-diameter circle.
[prepare_splash.dart](tool/prepare_splash.dart) preserves the original and writes
[splash_logo_android12.png](assets/branding/splash_logo_android12.png), scaling
the artwork into a 360px radius with transparent padding. It checks all visible
pixels against the 384px mask radius. Only Android 12+ uses this variant.

Validation (2026-10-19): native resource generation, Android debug APK build,
iOS plist lint and diff whitespace checks passed. Independent resource review
identified the Android 12 safe-area issue, addressed by the padded variant.
iOS build and device launch appearance
have not been verified. This chat has no bound OpenRig seat, so no queue handoff
was available.
