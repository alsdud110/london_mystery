import 'dart:ui' show Offset, Rect, Size;

import '../data/models/mission.dart';
import '../data/models/profile.dart';
import '../features/game/scoring.dart';

/// The two pictures of the Royal Box: shut, and open with the Crown inside,
/// on canvases of the same size, in register. [dials] are the shut box's
/// four dial drums, left to right, where the game writes the numbers the
/// detective turns the locks to (fractions of the picture; empty: the shut
/// picture has its own). [shut] and [opened] are the parts of the canvas
/// the box fills, shut and open (fractions): the page looks closer at the
/// open box, so the Crown reads large.
typedef RoyalBoxArt = ({
  String closed,
  String open,
  List<Rect> dials,
  Rect shut,
  Rect opened,
});

/// A clock face picture with no hands, and the hands drawn over it: where
/// its pivot is and how long its hands are (fractions of the picture's
/// width / height), and the time it shows before and after its case is
/// solved (hours, minutes).
typedef ClockHandsArt = ({
  Offset pivot,
  double hourLength,
  double minuteLength,
  ({int hour, int minute}) before,
  ({int hour, int minute}) after,
});

/// How the player's detective looks at a moment of play (see
/// [ArtAssets.detective]). The pictures are named after these: never rename
/// one without its files.
enum DetectiveExpression {
  /// Chin in hand: working out a puzzle, or looking again.
  thinking,

  /// Wide eyes, a letter in hand: something new has just turned up.
  surprised,

  /// Magnifying glass up: searching a place.
  investigating,

  /// Fists up, eyes shut with joy: a mission solved.
  happy,

  /// Pointing out, glass in hand: the whole case solved.
  confident,
}

/// Where a detective picture's medallion is cut: the centre of the circle
/// and its radius, in the picture's own pixels ([pixels]).
typedef DetectiveCrop = ({Size pixels, Offset centre, double radius});

/// The one place where finished artwork files are plugged in.
///
/// A picture without a file is drawn in code: scenes by `LandmarkArt`,
/// symbols and badges by the Ink Icon System (or a monogram while a drawing
/// is still a Custom Asset Required). When an illustrator delivers a file,
/// add it under `assets/art/`, list the folder in pubspec.yaml, and add one
/// line here. No screen changes. A missing or broken file falls back to the
/// drawing, so the game never shows an empty frame.
///
/// Files are PNG (or WebP/JPEG) loaded with `Image.asset`, with no extra
/// packages. SVG would need a new dependency and is not used.
abstract final class ArtAssets {
  /// The Mission Map artwork: a 3:2 landscape London map ([londonMapAspect]).
  /// Streets, river and landmarks only; pins and place names are drawn by
  /// the app (landmark positions: `Landmark` in `map_world.dart`). A missing
  /// or broken file falls back to the map drawn in code (`LondonMapPainter`).
  static const londonMap = 'assets/images/london_mystery.png';

  /// Width / height of [londonMap]: the map world keeps this ratio (never
  /// stretched); the map camera shows one part of it at a time.
  static const londonMapAspect = 3 / 2;

  /// Pixel size of [londonMap]: it is never decoded larger than this.
  static const londonMapPixels = Size(1536, 1024);

  /// The title screen: the detective's study on a London evening, in warm
  /// watercolour — bookshelves and the lamp on the left, the desk with a
  /// sealed letter, map and magnifying glass below, and a wide window over
  /// Westminster (Big Ben on the right, the moon above it). Portrait, no
  /// text: the window's sky is left for the title. The title screen (and,
  /// blurred, behind the registration form) only.
  static const titleDetectiveOffice = 'assets/images/title/title_detective_office.png';

  /// Pixel size of [titleDetectiveOffice] (never decoded larger).
  static const titleDetectiveOfficePixels = Size(942, 1670);

  /// The Season 1 cover: London from above at dusk — the Thames and its
  /// bridges, Westminster and Big Ben on the right, St Paul's far off, a
  /// stone balcony and a gas lamp in front (portrait, no text). The cover
  /// only: the opening's first scene has its own picture
  /// ([season1LondonNight]), closer in.
  static const season1CoverLondonPanorama = 'assets/seasons/season_01_london/cover/season1_cover_london_panorama.png';

  /// Pixel size of [season1CoverLondonPanorama] (never decoded larger).
  static const season1CoverLondonPanoramaPixels = Size(941, 1672);

  /// The first scene of the Season 1 opening: a warm London night on the
  /// embankment — Big Ben, Westminster, the bridge and the Thames, a gas
  /// lamp and wet paving in front (portrait, no text). Shown full screen
  /// once, as that scene's hero picture; used nowhere else, so the opening
  /// keeps its moment. Missing → the London drawn in code.
  static const season1LondonNight = 'assets/seasons/season_01_london/cover/season1_london_night.png';

  /// Pixel size of [season1LondonNight] (never decoded larger).
  static const season1LondonNightPixels = Size(941, 1671);

  /// The player's detective, chosen at CREATE YOUR DETECTIVE (see
  /// `DetectiveAvatar`): a boy and a girl in the storybook's style, head and
  /// shoulders on transparency, 4:5. Custom Asset Required: the folder is
  /// already in pubspec.yaml, so dropping the two files in is enough; until
  /// then the choice shows the cap icon and its word.
  static const avatarBoy = 'assets/art/avatars/detective_boy.png';
  static const avatarGirl = 'assets/art/avatars/detective_girl.png';

  /// The player's detective through the cases, one picture per
  /// [DetectiveExpression]: `detectives/<boy|girl>/<expression>.png`. The
  /// avatar is the one chosen at CREATE YOUR DETECTIVE; a detective made
  /// before avatars existed is shown as the boy (as in How to Play).
  ///
  /// Cut-outs on transparency (RGBA), waist up. They were delivered with a
  /// checkered backdrop painted in, which was taken out once (the delivered
  /// files are no longer kept). Shown whole (an illustration) or in a
  /// medallion ([detectiveCrops]).
  static String detective(DetectiveAvatar? avatar, DetectiveExpression expression) =>
      '${_art}detectives/${(avatar ?? DetectiveAvatar.boy).name}/${expression.name}.png';

  /// The medallion of each detective picture (its pixel size, and the
  /// circle round the face with the hands and what they hold).
  static DetectiveCrop detectiveCrop(DetectiveAvatar? avatar, DetectiveExpression expression) =>
      detectiveCrops[avatar ?? DetectiveAvatar.boy]![expression]!;

  static const _square = Size(1254, 1254);
  static const _wide = Size(1312, 1199);

  static const detectiveCrops = <DetectiveAvatar, Map<DetectiveExpression, DetectiveCrop>>{
    DetectiveAvatar.boy: {
      // The chin in the hand.
      DetectiveExpression.thinking: (pixels: _square, centre: Offset(720, 600), radius: 400),
      // The face over the letter.
      DetectiveExpression.surprised: (pixels: _square, centre: Offset(730, 620), radius: 420),
      // The face and the magnifying glass.
      DetectiveExpression.investigating: (pixels: _square, centre: Offset(850, 700), radius: 400),
      DetectiveExpression.happy: (pixels: _square, centre: Offset(720, 480), radius: 420),
      // The pointing hand and the glass either side of the face.
      DetectiveExpression.confident: (pixels: _wide, centre: Offset(780, 540), radius: 470),
    },
    DetectiveAvatar.girl: {
      DetectiveExpression.thinking: (pixels: _square, centre: Offset(740, 620), radius: 420),
      DetectiveExpression.surprised: (pixels: _square, centre: Offset(760, 640), radius: 430),
      DetectiveExpression.investigating: (pixels: _square, centre: Offset(830, 700), radius: 420),
      DetectiveExpression.happy: (pixels: _wide, centre: Offset(790, 520), radius: 450),
      DetectiveExpression.confident: (pixels: _wide, centre: Offset(820, 560), radius: 470),
    },
  };

  /// How to Play (the first-play guide): its own pictures, never a case's
  /// character or evidence. A missing file leaves its place empty.
  ///
  /// The detective in the guide, as the player chose them (boy or girl; a
  /// detective made before avatars existed: the boy), waving hello: full
  /// figure on transparency, 2:3. One rule for every page: see
  /// [onboardingReady].
  static String onboardingWelcome(DetectiveAvatar? avatar) => switch (avatar) {
        DetectiveAvatar.girl => 'assets/art/onboarding/detective_welcome_girl.png',
        DetectiveAvatar.boy || null => 'assets/art/onboarding/detective_welcome_boy.png',
      };

  /// The same detective setting off, letter and magnifying glass in hand
  /// (the guide's last page). Same size as [onboardingWelcome].
  static String onboardingReady(DetectiveAvatar? avatar) => switch (avatar) {
        DetectiveAvatar.girl => 'assets/art/onboarding/detective_ready_girl.png',
        DetectiveAvatar.boy || null => 'assets/art/onboarding/detective_ready_boy.png',
      };

  /// Pixel size of the [onboardingWelcome] and [onboardingReady] pictures
  /// (all four alike, so the boy and the girl show at the same size).
  static const onboardingDetectivePixels = Size(1024, 1536);

  /// Mrs Moss, the tea seller: the practice witness (no case's), printed
  /// like the witnesses of the cases (4:5 on parchment, [witnessPortraitAspect]).
  static const onboardingWitness = 'assets/art/onboarding/witness_tea_seller.png';

  /// Pip, the practice puzzle's lost kitten (red collar): square, on
  /// transparency.
  static const onboardingCat = 'assets/art/onboarding/lost_cat.png';

  /// Scene pictures (mission, final, image choices, the arrival at a place,
  /// Case Solved photo), full colour: the nine London landmarks in
  /// `locations/landmarks/`, and the places inside a landmark in a folder named
  /// after it. A place inside a landmark (the Boathouse in Hyde Park) never
  /// borrows its landmark's picture: without its own it is drawn in code.
  static const Map<Artwork, String> scenes = {
    ...landmarkScenes,
    ...insideScenes,
    ...objectScenes,
  };

  /// Scenes shown by a character or object picture: the Tower raven (Poppy)
  /// for the raven scenes, the old brown suitcase where the story finds one,
  /// and the Royal Box as it is once found: open, the Crown inside (the case
  /// photo; the final case itself animates [royalBox]). Never `special/
  /// royal_box.png`: that is a theatre's royal box. Mrs Robin's black
  /// suitcase (Case 08, its name tag washed blank). Case 09's open glass
  /// case, its cushion empty and a card left on it. The two doors, each for
  /// its own case: the White Tower's, a dial and the four gears the final
  /// lock asks about (Case 05), and the small iron door under Big Ben
  /// (Case 12).
  ///
  /// Not here, on purpose: `objects/jewel_case.png` (a full red box with a
  /// tiara: Case 09's glass case is empty, the Blue Star is a blue jewel) and
  /// `objects/locked_door.png` (a plain arched wooden door, neither case's).
  /// That door is the Season opening's "doors found locked" print only.
  static const objectScenes = <Artwork, String>{
    Artwork.raven: '${_art}characters/raven_master.png',
    Artwork.oldSuitcase: '${_art}objects/suitcase.png',
    Artwork.royalBox: '${_art}special/royal_box_open.png',
    Artwork.blackSuitcase: '${_art}objects/suitcase_black.png',
    Artwork.jewelCase: '${_art}objects/empty_glass_jewel_case.png',
    Artwork.gearDoor: '${_art}objects/locked_door_gears.png',
    Artwork.ironDoor: '${_art}objects/small_iron_door.png',
    // The iron chest behind the White Tower's door (Case 05's final).
    Artwork.ironChest: '${_art}objects/iron_chest.png',
    // Big Ben's clock (Case 02): its face with no hands (the hands are drawn
    // over it: [clockHands]), and the wheels behind it, no time to read.
    Artwork.clockFace: '$_scenes/big_ben/clock_face.png',
    Artwork.clockMechanism: '$_scenes/big_ben/clock_mechanism.png',
  };

  /// Width / height of each scene picture that is not printed like the
  /// landmark set ([scenePrint]): frames take the picture's own ratio.
  static const sceneAspects = <Artwork, double>{
    Artwork.raven: 1,
    Artwork.oldSuitcase: 1,
    Artwork.royalBox: 1659 / 948,
    Artwork.greatCourt: 1264 / 848,
    Artwork.egyptRoom: 1264 / 848,
    Artwork.boathouse: 1288 / 816,
    Artwork.roseGarden: 1288 / 816,
    Artwork.staffRoom: 1288 / 816,
    Artwork.courtyard: 1288 / 816,
    Artwork.dressingRoom: 1290 / 816,
    Artwork.waitingRoom: 1273 / 832,
    Artwork.gallery: 1536 / 1024,
    Artwork.auditorium: 1536 / 1024,
    Artwork.blackSuitcase: 1377 / 1142,
    Artwork.jewelCase: 1536 / 1024,
    Artwork.gearDoor: 1536 / 1024,
    Artwork.ironDoor: 1536 / 1024,
    Artwork.theatreDoor: 1536 / 1024,
    Artwork.ironChest: 1536 / 1024,
    Artwork.royalArchive: 1536 / 1024,
    Artwork.clockFace: 1,
    Artwork.clockMechanism: 1536 / 1024,
  };

  /// Width / height of the picture of [a] ([scenePrint] unless listed).
  static double sceneAspect(Artwork a) => sceneAspects[a] ?? scenePrint.size.aspectRatio;

  /// Recurring characters (full colour, on parchment, square), and the
  /// witnesses a mission talks to (Case 06's market hall: printed on
  /// parchment, 4:5 portraits, see `season1_dialogues.dart`).
  static const characters = <String, String>{
    'raven': '${_art}characters/raven_master.png',
    'clockmaker': '${_art}characters/clockmaker_master.png',
    'flowerSeller': '${_art}characters/flower_seller.png',
    'juggler': '${_art}characters/juggler.png',
    'baker': '${_art}characters/baker.png',
  };

  /// Width / height of a witness portrait ([characters]: flower seller,
  /// juggler, baker).
  static const witnessPortraitAspect = 1122 / 1402;

  /// The Covent Garden market hall at closing time, inside (portrait 2:3):
  /// the room Case 06's witnesses are talked to in.
  static const marketHall = '$_scenes/covent_garden/covent_garden_market_hall.png';

  /// Story objects (full colour, on parchment, square except the map).
  static const objects = <String, String>{
    'crown': '${_art}objects/crown.png',
    'key': '${_art}objects/key.png',
    'letter': '${_art}objects/letter.png',
    'map': '${_art}objects/map.png',
    'pocketWatch': '${_art}objects/pocket_watch.png',
    'suitcase': '${_art}objects/suitcase.png',
  };

  /// The Season opening's prints of trouble, cut out on transparency: a
  /// stranger hiding his face (no one in particular: never the Clockmaker
  /// or the Ravenmaster) and a locked old door (mood only, no case's door).
  static const mysteriousStranger = '${_art}characters/mysterious_stranger.png';
  static const lockedDoor = '${_art}objects/locked_door.png';

  /// The Raven Society mark (full colour, not a tinted [symbols] glyph).
  static const ravenMark = '${_art}symbols/raven_mark.png';

  /// Case 01's Royal Box (the final mission's golden box with the Crown
  /// inside), as two pictures on transparency (1659 × 948, in register):
  /// shut, its four dial drums blank — `royal_box_closed_blank.png`, made
  /// from the delivered `royal_box_closed.png` (kept, its drums painted
  /// 0000) by `tool/royal_box_blank/blank_test.dart` — so the game writes
  /// on them the numbers the detective turns the locks to; and open with the
  /// Crown in it, its drums showing the code (7924), shown only once the box
  /// is opened. The opening animation crossfades the two; a missing picture
  /// falls back to the box drawn in code (`RoyalBoxAnimation`).
  static const RoyalBoxArt royalBox = (
    closed: '${_art}special/royal_box_closed_blank.png',
    open: '${_art}special/royal_box_open.png',
    // The drums' digit faces, measured on the picture (pixels 521–552,
    // 709–740, 909–940, 1104–1135 across; 644–688 down).
    dials: [
      Rect.fromLTRB(521 / 1659, 644 / 948, 552 / 1659, 688 / 948),
      Rect.fromLTRB(709 / 1659, 644 / 948, 740 / 1659, 688 / 948),
      Rect.fromLTRB(909 / 1659, 644 / 948, 940 / 1659, 688 / 948),
      Rect.fromLTRB(1104 / 1659, 644 / 948, 1135 / 1659, 688 / 948),
    ],
    // Shut: the whole box, its wide brass corners included. Open: the box
    // from its lid to its feet, a little closer (the Crown larger).
    shut: Rect.fromLTRB(30 / 1659, 80 / 948, 1630 / 1659, 905 / 948),
    opened: Rect.fromLTRB(100 / 1659, 5 / 948, 1560 / 1659, 905 / 948),
  );

  /// The delivered shut Royal Box, its drums painted 0000: the source of
  /// [royalBox]'s shut picture, never shown (the 0000 would not follow the
  /// locks).
  static const royalBoxClosedPainted = '${_art}special/royal_box_closed.png';

  /// Special pictures. The theatre royal box: listed, not shown yet — the
  /// game's Royal Box (Case 01) is a golden box with the Crown inside.
  static const special = <String, String>{
    'theatreRoyalBox': '${_art}special/royal_box.png',
  };

  /// Evidence shown by its real picture (notebook, zoom, celebrations),
  /// by evidence id. Case 01's map (two swans) keeps its drawn mark, as do
  /// the maps whose drawn ravens the pictures lack. Case 01's Pocket Watch
  /// is the Royal Box's own watch, the same picture everywhere it appears
  /// (2026-10-19, requested), though that picture reads about ten past ten,
  /// not the 7 o'clock its words give.
  static const evidencePictures = <String, String>{
    'e01': '${_art}objects/letter.png', // Old Letter
    'e02': '${_art}objects/key.png', // Golden Key
    'e03': _case01PocketWatch, // Pocket Watch: the Royal Box's clock lock
    // Crown Symbol: the card with a crown on it (the crown it shows).
    'e05': '${_art}objects/crown.png',
    'e06': '${_art}objects/crown.png', // The Missing Crown
    'ep03_e1': '${_art}objects/red_button.png', // Red Button (Case 03, again in Case 08)
    'ep04_e1': ravenMark, // Black Wax Seal: a raven pressed into the wax
    'ep05_e3': '${_art}objects/key.png', // Brass Key
    'ep10_e3': '${_art}objects/letter.png', // Ravenmaster's Letter
    'ep12_e4': '${_art}objects/pocket_watch.png', // The Clockmaker's Watch
  };

  /// What a case's Case Closed file shows under its title in place of the
  /// small tilted case photo, by case id: the thing the case was about,
  /// alone on the file's paper. Case 01: the Missing Crown, cut out of
  /// `objects/crown.png` (kept, on its parchment) by
  /// `tool/crown_cutout/cutout_test.dart`. Other cases keep their photo.
  static const caseClosedEmblems = <String, String>{
    'ep01': '${_art}objects/crown_cutout.png',
  };

  /// How much closer an [evidencePictures] picture is shown in its round
  /// frame, where its object sits small in a wide parchment margin: only
  /// the margin goes, never the object. The crown (crown.png) fills about
  /// the middle half of its square; at 1.5× its cross, jewels and band
  /// still lie inside the circle.
  /// Below 1, farther: the Pocket Watch's bow and open lid reach just past
  /// its square's inscribed circle, so it is shown a little smaller, whole.
  static const evidencePictureZoom = <String, double>{'e05': 1.5, 'e03': 0.95};

  static const _art = 'assets/art/';
  static const _case01 = 'assets/images/case01';
  static const _case01PocketWatch = '$_case01/symbols/symbol_pocket_watch.png';

  /// The nine London landmarks.
  static const landmarkScenes = <Artwork, String>{
    Artwork.kingsCross: '$_scenes/landmarks/kings_cross.png',
    Artwork.britishMuseum: '$_scenes/landmarks/british_museum.png',
    Artwork.coventGarden: '$_scenes/landmarks/covent_garden.png',
    Artwork.bigBen: '$_scenes/landmarks/big_ben.png',
    Artwork.hydePark: '$_scenes/landmarks/hyde_park.png',
    Artwork.buckinghamPalace: '$_scenes/landmarks/buckingham_palace.png',
    Artwork.towerBridge: '$_scenes/landmarks/tower_bridge.png',
    Artwork.towerOfLondon: '$_scenes/landmarks/tower_of_london.png',
    Artwork.londonEye: '$_scenes/landmarks/london_eye.png',
  };

  /// Places inside a landmark, each in its landmark's folder.
  static const insideScenes = <Artwork, String>{
    Artwork.greatCourt: '$_scenes/british_museum/british_museum_great_court.png',
    Artwork.egyptRoom: '$_scenes/british_museum/british_museum_egypt_room.png',
    Artwork.boathouse: '$_scenes/hyde_park/hyde_park_boathouse.png',
    Artwork.roseGarden: '$_scenes/hyde_park/hyde_park_rose_garden.png',
    Artwork.staffRoom: '$_scenes/buckingham_palace/buckingham_palace_palace_staff_room.png',
    Artwork.courtyard: '$_scenes/buckingham_palace/buckingham_palace_palace_courtyard.png',
    Artwork.dressingRoom: '$_scenes/covent_garden/covent_garden_dressing_room.png',
    Artwork.waitingRoom: '$_scenes/kings_cross/kings_cross_waiting_hall.png',
    // Gallery 8 (Case 03): the room as the theft left it — the empty gold
    // frame, the bench, the door (its M1 is searched in this picture: see
    // `season1_investigations.dart`). And the theatre's auditorium (Case 11).
    Artwork.gallery: '$_scenes/british_museum/british_museum_gallery_8.png',
    Artwork.auditorium: '$_scenes/covent_garden/covent_garden_theatre.png',
    // The theatre's door at night (Case 06; the file keeps its delivered name).
    Artwork.theatreDoor: '$_scenes/covent_garden/theatre_door_dark.png',
    // The Royal Archive, down the secret stairs of Buckingham Palace (its own
    // folder: it is no landmark of the map).
    Artwork.royalArchive: '$_scenes/royal_archive/royal_archive.png',
  };

  static const _scenes = 'assets/seasons/season_01_london/locations';

  /// How the scene pictures are printed (about 400×256, a thin paper frame;
  /// the landmark set also has the place's name plate along the bottom).
  /// They show whole, in frames of this ratio. Only where a name must not
  /// show (an image-choice answer, always a landmark) is the part above
  /// [nameTop] shown, inside the [frame].
  /// Fractions of the picture's width / height.
  static const scenePrint = (size: Size(400, 256), frame: 0.045, nameTop: 0.68);

  /// A scene after its case is solved, when it is another picture (none
  /// today: Case 02's clock keeps its face and turns its drawn hands).
  static const Map<Artwork, String> solvedScenes = {};

  /// Clock faces whose hands are drawn over the picture. Case 02: Big Ben
  /// stopped at 8:17, set to 9:17 when the case is solved. The pivot and the
  /// hands are measured on `big_ben/clock_face.png` (1254 × 1254: the pivot
  /// at 627, 548; the numerals' ring about 337 px out).
  static const Map<Artwork, ClockHandsArt> clockHands = {
    Artwork.clockFace: (
      pivot: Offset(0.5, 0.437),
      hourLength: 0.185,
      minuteLength: 0.30,
      before: (hour: 8, minute: 17),
      after: (hour: 9, minute: 17),
    ),
  };

  /// Symbol pictures (clue stamps, evidence, lock dials), keyed like
  /// `GameSymbol`, e.g. `'park': 'assets/art/symbols/park.png'`.
  /// One-colour artwork on transparency: the game tints it with the symbol's
  /// colour, as it does the ink glyphs.
  static const Map<String, String> symbols = {};

  /// Case 01's Royal Box: the four pictures of its locks, in full colour on
  /// transparency (cut out of the delivered files kept in
  /// `assets/images/case01/symbols/original/`, by
  /// `tool/symbol_cutout/cutout_test.dart`), keyed like the locks'
  /// `dialSymbols`. Shown where the lock order is read — the crown card's
  /// hidden message, the Crown Symbol evidence and the locks themselves —
  /// never tinted. Other cases keep their [symbols] glyphs.
  static const royalBoxLocks = <String, String>{
    'clock': _case01PocketWatch,
    'train': '$_case01/symbols/symbol_steam_train.png',
    'park': '$_case01/symbols/symbol_swan.png',
    'museum': '$_case01/symbols/symbol_rosetta_stone.png',
  };

  /// The Royal Box lock pictures are square (512 × 512), each drawing
  /// centred with the same margin, so they look the same size side by side.
  static const royalBoxLockPixels = Size(512, 512);

  static const _badges = 'assets/images/badges';

  /// Badge medals, one per [GameBadge] (retired ones too: old saves still
  /// show them). Each is a finished medal — the gold rosette, its enamel
  /// face and the badge's own emblem — in full colour on transparency,
  /// shown by `BadgeMedal` as it is: never tinted, never framed again.
  static const Map<GameBadge, String> badges = {
    GameBadge.firstClue: '$_badges/badge_first_clue.png',
    GameBadge.sharpEyes: '$_badges/badge_sharp_eyes.png',
    GameBadge.quickThinker: '$_badges/badge_quick_thinker.png',
    GameBadge.puzzleSolver: '$_badges/badge_puzzle_solver.png',
    GameBadge.londonExplorer: '$_badges/badge_london_explorer.png',
    GameBadge.masterDetective: '$_badges/badge_master_detective.png',
    GameBadge.clockWatcher: '$_badges/badge_clock_watcher.png',
    GameBadge.evidenceHunter: '$_badges/badge_evidence_hunter.png',
    GameBadge.letterReader: '$_badges/badge_letter_reader.png',
    GameBadge.codeBreaker: '$_badges/badge_code_breaker.png',
    GameBadge.mapMaster: '$_badges/badge_map_master.png',
    GameBadge.londonLegend: '$_badges/badge_london_legend.png',
    GameBadge.secondLook: '$_badges/badge_second_look.png',
    GameBadge.notebookExplorer: '$_badges/badge_notebook_explorer.png',
    GameBadge.wordCollector: '$_badges/badge_word_collector.png',
  };

  /// The same rosette with an empty face: a badge still to win. Every locked
  /// badge shows it (greyed, with a lock), so its emblem stays a surprise.
  static const badgeFrame = '$_badges/badge_frame.png';

  /// The badge pictures and [badgeFrame] are square, all the same size, so
  /// medals line up whatever their emblem.
  static const badgePixels = Size(1254, 1254);

  /// The file for [artwork], or null to keep the drawing. Once a scene that
  /// changes when solved is being solved (or after), its solved picture if
  /// it has one, else its own picture (its change is drawn over it).
  static String? scene(Artwork artwork, {double solved = 0}) =>
      solved > 0 && changesWhenSolved.contains(artwork) ? solvedScenes[artwork] ?? scenes[artwork] : scenes[artwork];

  /// Scenes that show differently once their case is solved (the clock's
  /// drawn hands; drawn in code, its hands turn too).
  static const changesWhenSolved = {Artwork.clockFace};
}
