import '../models/mission.dart';

/// How far a puzzle's engine can be used again, as it is, by a new season.
enum PuzzleReuseGrade {
  /// New content and pictures only: no widget, mission type or page branch
  /// to change.
  ready,

  /// The engine works, but something in it is tied to the cases it was made
  /// for (an `Artwork` value, a fixed layout, a missing level variant…): see
  /// [PuzzleDefinition.constraints].
  conditional,

  /// Made for its case alone. None is in the palette: such engines stay
  /// where they are, never offered to a new season.
  custom,
}

/// What it takes to make a new puzzle of a kind (apart from the place's own
/// picture, which every mission has).
enum PuzzleGenerationMode {
  /// Written content only: the generator can write it whole.
  textOnly,

  /// Pictures to be made and approved first, then their sizes and the
  /// places on them (pixels) written in. Never generated straight to code
  /// before the pictures are approved.
  requiresAssets,

  /// The engine as it is cannot take a new season's puzzle: code to change
  /// first (see [PuzzleDefinition.constraints]).
  requiresDevelopment,
}

/// The page a puzzle is played on.
enum PuzzleSurface {
  /// A case's mission (`MissionScreen`).
  mission,

  /// A case's final (`FinalMissionScreen`).
  finalMission,
}

/// What the detective does in a puzzle.
enum PuzzleAction {
  readDocument,
  chooseOption,
  typeAnswer,
  tapPicture,
  magnify,
  dragOnPicture,
  orderItems,
  compare,
  matchPairs,
  slideReveal,
  turnDial,
  setClockHands,
  placeToken,
  linkEvidence,
  talk,
  presentEvidence,
}

/// How a binding takes part in its puzzle.
enum PuzzleBindingRole {
  /// The engine the puzzle is played on.
  primary,

  /// One of several engines that play the same puzzle, each with its own
  /// model (one of them is picked for a mission, never two).
  alternative,

  /// Laid on the primary engine when given (a lock's box, a talk around
  /// the puzzle); the puzzle is played without it.
  optional,
}

/// A field of the game's content: a field of the Dart class [model] (for
/// `Mission`, also its key in the case JSON).
class PuzzleField {
  const PuzzleField(this.model, this.name);

  final String model;
  final String name;

  @override
  String toString() => '$model.$name';
}

/// A picture a puzzle needs, and the field its file (or its `Artwork`)
/// is written in.
class PuzzleAsset {
  const PuzzleAsset(this.description, this.field);

  final String description;
  final PuzzleField field;

  @override
  String toString() => '$description ($field)';
}

/// Where a puzzle's engine is in the code, as the game plays it today.
class PuzzleEngineBinding {
  const PuzzleEngineBinding({
    required this.widget,
    required this.source,
    required this.missionTypes,
    required this.surfaces,
    this.table,
    this.model,
    this.role = PuzzleBindingRole.primary,
    this.note,
  });

  /// The widget class that plays it.
  final String widget;

  /// The file [widget] is declared in, from the package root.
  final String source;

  /// The `SeasonContent` table it is registered in, by its name in
  /// `SeasonContent.missionTables` (null: played from the mission's own
  /// [MissionType], no table).
  final String? table;

  /// The Dart class of [table]'s entries.
  final String? model;

  /// The mission types its missions are written as in the game (the answer
  /// is checked as that type).
  final Set<MissionType> missionTypes;

  /// The pages that play it (the code's branches, not only where the game
  /// uses it).
  final Set<PuzzleSurface> surfaces;

  final PuzzleBindingRole role;
  final String? note;
}

/// One kind of puzzle a season can be made with, whatever its city.
class PuzzleDefinition {
  const PuzzleDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.actions,
    required this.reuseGrade,
    required this.generationMode,
    required this.engines,
    required this.requiredData,
    this.requiredAssets = const [],
    this.optionalAssets = const [],
    this.constraints = const [],
  });

  /// Stable id (snake_case, never a city's name).
  final String id;
  final String name;
  final String description;
  final List<PuzzleAction> actions;
  final PuzzleReuseGrade reuseGrade;
  final PuzzleGenerationMode generationMode;
  final List<PuzzleEngineBinding> engines;

  /// The content to write for one puzzle of this kind.
  final List<PuzzleField> requiredData;

  /// The pictures it needs beyond the place's own.
  final List<PuzzleAsset> requiredAssets;

  /// Pictures used only with an [PuzzleBindingRole.optional] engine.
  final List<PuzzleAsset> optionalAssets;

  /// What in the code limits its use by a new season.
  final List<String> constraints;

  /// The engines that can play it on their own (not the optional ones).
  Iterable<PuzzleEngineBinding> get playable => engines.where((e) => e.role != PuzzleBindingRole.optional);

  /// The pages it can be played on.
  Set<PuzzleSurface> get surfaces => {for (final e in playable) ...e.surfaces};

  bool supports(PuzzleSurface surface) => surfaces.contains(surface);

  /// The engines that play it on [surface].
  List<PuzzleEngineBinding> enginesFor(PuzzleSurface surface) => [
    for (final e in playable)
      if (e.surfaces.contains(surface)) e,
  ];

  /// Whether its pictures must be approved before it is generated.
  bool get needsAssetApproval => generationMode == PuzzleGenerationMode.requiresAssets;
}

/// The puzzles a new season can choose from (STEP 2-4's palette): metadata
/// about the engines London and Paris are played on. Read by tools and
/// tests only; the game never reads it, and nothing here changes how a
/// mission is played (the pages still pick their engine from the season's
/// tables).
abstract final class PuzzlePalette {
  static const _m = {PuzzleSurface.mission};
  static const _f = {PuzzleSurface.finalMission};
  static const _both = {PuzzleSurface.mission, PuzzleSurface.finalMission};
  static const _q = 'lib/features/mission/widgets/question_widgets.dart';
  static const _w = 'lib/features/mission/widgets';

  /// Every puzzle, in palette order (ready first).
  static const List<PuzzleDefinition> all = [
    // ── Ready ──────────────────────────────────────────────────────────
    PuzzleDefinition(
      id: 'text_choice',
      name: 'Read and choose',
      description: 'A document is read; one of three or four written options answers it.',
      actions: [PuzzleAction.readDocument, PuzzleAction.chooseOption],
      reuseGrade: PuzzleReuseGrade.ready,
      generationMode: PuzzleGenerationMode.textOnly,
      engines: [
        PuzzleEngineBinding(widget: 'MultipleChoiceQuestion', source: _q, missionTypes: {MissionType.multipleChoice}, surfaces: _both),
      ],
      requiredData: [
        PuzzleField('Mission', 'letter'),
        PuzzleField('Mission', 'question'),
        PuzzleField('Mission', 'options'),
        PuzzleField('ChoiceOption', 'label'),
        PuzzleField('ChoiceOption', 'feedback'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'hints'),
      ],
      constraints: ['A wrong answer costs only the first-try bonus and can be tried again at once: options can be guessed.'],
    ),
    PuzzleDefinition(
      id: 'word_entry',
      name: 'Write the word',
      description: 'A word found in the clues is typed.',
      actions: [PuzzleAction.readDocument, PuzzleAction.typeAnswer],
      reuseGrade: PuzzleReuseGrade.ready,
      generationMode: PuzzleGenerationMode.textOnly,
      engines: [
        PuzzleEngineBinding(widget: 'WordInputQuestion', source: _q, missionTypes: {MissionType.wordInput}, surfaces: _both),
      ],
      requiredData: [
        PuzzleField('Mission', 'letter'),
        PuzzleField('Mission', 'question'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'acceptedAnswers'),
        PuzzleField('Mission', 'hints'),
      ],
    ),
    PuzzleDefinition(
      id: 'number_entry',
      name: 'Number code',
      description: 'A number or a time found in the clues is put in on a keypad.',
      actions: [PuzzleAction.readDocument, PuzzleAction.typeAnswer],
      reuseGrade: PuzzleReuseGrade.ready,
      generationMode: PuzzleGenerationMode.textOnly,
      engines: [
        PuzzleEngineBinding(widget: 'NumberCodeQuestion', source: _q, missionTypes: {MissionType.numberCode}, surfaces: _both),
      ],
      requiredData: [
        PuzzleField('Mission', 'letter'),
        PuzzleField('Mission', 'question'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'codeLength'),
        PuzzleField('Mission', 'codeFormat'),
        PuzzleField('Mission', 'hints'),
      ],
      constraints: ['codeFormat "time" shows the code as a time (H:MM).'],
    ),
    PuzzleDefinition(
      id: 'combo_dial_lock',
      name: 'Dial lock',
      description: "The final's lock: one dial per digit, each digit from an earlier clue (its symbol on the dial).",
      actions: [PuzzleAction.turnDial],
      reuseGrade: PuzzleReuseGrade.ready,
      generationMode: PuzzleGenerationMode.textOnly,
      engines: [
        PuzzleEngineBinding(
          widget: '_Dial',
          source: 'lib/features/mission/final_mission_screen.dart',
          missionTypes: {MissionType.finalCode},
          surfaces: _f,
          note: 'On a mission page a finalCode is shown as the keypad (number_entry).',
        ),
      ],
      requiredData: [
        PuzzleField('Mission', 'question'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'codeLength'),
        PuzzleField('Mission', 'dialSymbols'),
        PuzzleField('Mission', 'hints'),
      ],
      constraints: [
        "dialSymbols are names in the app's symbol table (lib/widgets/symbol_icon.dart).",
        'The Royal Box (Artwork.royalBox) has its own stage; any other place opens behind the lock.',
      ],
    ),
    PuzzleDefinition(
      id: 'letter_tile_lock',
      name: 'Letter lock',
      description: 'Letter tiles, each used once, are set in the lock to spell the word the clues gave.',
      actions: [PuzzleAction.orderItems],
      reuseGrade: PuzzleReuseGrade.ready,
      generationMode: PuzzleGenerationMode.textOnly,
      engines: [
        PuzzleEngineBinding(widget: 'LetterLockQuestion', source: '$_w/letter_lock.dart', missionTypes: {MissionType.letterLock}, surfaces: _both),
        PuzzleEngineBinding(
          widget: 'LockBoxStage',
          source: '$_w/lock_box.dart',
          table: 'lockBoxes',
          model: 'LockBoxArt',
          missionTypes: {MissionType.letterLock},
          surfaces: _f,
          role: PuzzleBindingRole.optional,
          note: 'A box whose slots show the letters set, opened with the solve (finals only).',
        ),
      ],
      requiredData: [
        PuzzleField('Mission', 'question'),
        PuzzleField('Mission', 'options'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'hints'),
      ],
      optionalAssets: [
        PuzzleAsset('The box, shut, its letter slots', PuzzleField('LockBoxArt', 'closed')),
        PuzzleAsset('The box, open', PuzzleField('LockBoxArt', 'open')),
        PuzzleAsset('What is found inside', PuzzleField('LockBoxArt', 'found')),
      ],
    ),
    PuzzleDefinition(
      id: 'order_sequence',
      name: 'Put in order',
      description: 'Options are tapped in the right order (an option can be used again when there are fewer options than steps).',
      actions: [PuzzleAction.readDocument, PuzzleAction.orderItems],
      reuseGrade: PuzzleReuseGrade.ready,
      generationMode: PuzzleGenerationMode.textOnly,
      engines: [
        PuzzleEngineBinding(widget: 'SequenceQuestion', source: _q, missionTypes: {MissionType.sequence}, surfaces: _both),
      ],
      requiredData: [
        PuzzleField('Mission', 'letter'),
        PuzzleField('Mission', 'question'),
        PuzzleField('Mission', 'options'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'codeLength'),
        PuzzleField('Mission', 'orderFeedback'),
        PuzzleField('Mission', 'hints'),
      ],
    ),
    PuzzleDefinition(
      id: 'scene_explore_choose',
      name: 'Look round the place',
      description: "The place's picture is tapped to look round; the document is found there, then a picture is chosen.",
      actions: [PuzzleAction.tapPicture, PuzzleAction.readDocument, PuzzleAction.chooseOption],
      reuseGrade: PuzzleReuseGrade.ready,
      generationMode: PuzzleGenerationMode.requiresAssets,
      engines: [
        PuzzleEngineBinding(widget: 'SceneExplore', source: '$_w/scene_explore.dart', table: 'explores', model: 'ExploreScene', missionTypes: {MissionType.multipleChoice}, surfaces: _m),
      ],
      requiredData: [
        PuzzleField('Mission', 'letter'),
        PuzzleField('Mission', 'options'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'hints'),
        PuzzleField('ExploreScene', 'picture'),
        PuzzleField('ExploreScene', 'pixels'),
        PuzzleField('ExploreScene', 'place'),
        PuzzleField('ExploreScene', 'task'),
        PuzzleField('ExploreScene', 'nextTask'),
        PuzzleField('ExploreScene', 'spots'),
        PuzzleField('ExploreSpot', 'kind'),
        PuzzleField('ExploreSpot', 'areas'),
        PuzzleField('ExploreSpot', 'mark'),
        PuzzleField('ExploreScene', 'choices'),
        PuzzleField('ExploreScene', 'missLine'),
        PuzzleField('ExploreScene', 'guideAt'),
        PuzzleField('ExploreScene', 'inside'),
        PuzzleField('ExploreScene', 'opening'),
      ],
      requiredAssets: [
        PuzzleAsset('The place to look round', PuzzleField('ExploreScene', 'picture')),
        PuzzleAsset('Each picture to choose from', PuzzleField('ExplorePicture', 'picture')),
      ],
    ),
    PuzzleDefinition(
      id: 'lens_inspect_word',
      name: 'Magnifying glass',
      description: 'A glass is dragged over the exhibits; the one the note describes gives its label, where the missing word is written.',
      actions: [PuzzleAction.magnify, PuzzleAction.dragOnPicture, PuzzleAction.readDocument, PuzzleAction.typeAnswer],
      reuseGrade: PuzzleReuseGrade.ready,
      generationMode: PuzzleGenerationMode.requiresAssets,
      engines: [
        PuzzleEngineBinding(widget: 'LensInspect', source: '$_w/lens_inspect.dart', table: 'inspections', model: 'InspectScene', missionTypes: {MissionType.wordInput}, surfaces: _m),
      ],
      requiredData: [
        PuzzleField('Mission', 'letter'),
        PuzzleField('Mission', 'prompt'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'hints'),
        PuzzleField('InspectScene', 'picture'),
        PuzzleField('InspectScene', 'pixels'),
        PuzzleField('InspectScene', 'task'),
        PuzzleField('InspectScene', 'spots'),
        PuzzleField('InspectSpot', 'areas'),
        PuzzleField('InspectSpot', 'checks'),
        PuzzleField('InspectScene', 'labelTitle'),
        PuzzleField('InspectScene', 'taskLine'),
        PuzzleField('InspectScene', 'lensAt'),
        PuzzleField('InspectScene', 'inside'),
      ],
      requiredAssets: [PuzzleAsset('The room with its exhibits', PuzzleField('InspectScene', 'picture'))],
    ),
    PuzzleDefinition(
      id: 'trace_deduction',
      name: 'Read the traces',
      description: 'Every trace is tapped and noted; then the place they all point to is tapped.',
      actions: [PuzzleAction.tapPicture, PuzzleAction.chooseOption],
      reuseGrade: PuzzleReuseGrade.ready,
      generationMode: PuzzleGenerationMode.requiresAssets,
      engines: [
        PuzzleEngineBinding(widget: 'SceneDeduction', source: '$_w/scene_deduction.dart', table: 'deductions', model: 'DeductionScene', missionTypes: {MissionType.multipleChoice}, surfaces: _m),
      ],
      requiredData: [
        PuzzleField('Mission', 'letter'),
        PuzzleField('Mission', 'options'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'hints'),
        PuzzleField('DeductionScene', 'picture'),
        PuzzleField('DeductionScene', 'pixels'),
        PuzzleField('DeductionScene', 'task'),
        PuzzleField('DeductionScene', 'chooseTask'),
        PuzzleField('DeductionScene', 'clues'),
        PuzzleField('DeductionClue', 'areas'),
        PuzzleField('DeductionClue', 'line'),
        PuzzleField('DeductionScene', 'places'),
        PuzzleField('DeductionPlace', 'optionId'),
        PuzzleField('DeductionPlace', 'areas'),
        PuzzleField('DeductionScene', 'guideAt'),
        PuzzleField('DeductionScene', 'inside'),
        PuzzleField('DeductionScene', 'opening'),
      ],
      requiredAssets: [PuzzleAsset('The place with its traces and hiding places', PuzzleField('DeductionScene', 'picture'))],
    ),
    PuzzleDefinition(
      id: 'object_decode',
      name: 'Decode a thing',
      description: 'A thing at the place is brought closer and scanned; its hidden message shows, and it is taken.',
      actions: [PuzzleAction.tapPicture],
      reuseGrade: PuzzleReuseGrade.ready,
      generationMode: PuzzleGenerationMode.requiresAssets,
      engines: [
        PuzzleEngineBinding(widget: 'SceneDecode', source: '$_w/scene_decode.dart', table: 'decodes', model: 'DecodeScene', missionTypes: {MissionType.examine}, surfaces: _m),
      ],
      requiredData: [
        PuzzleField('Mission', 'letter'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'evidence'),
        PuzzleField('DecodeScene', 'picture'),
        PuzzleField('DecodeScene', 'pixels'),
        PuzzleField('DecodeScene', 'thing'),
        PuzzleField('DecodeScene', 'areas'),
        PuzzleField('DecodeScene', 'closer'),
        PuzzleField('DecodeScene', 'code'),
        PuzzleField('DecodeScene', 'cleared'),
        PuzzleField('DecodeScene', 'clearedArea'),
        PuzzleField('DecodeScene', 'revealed'),
        PuzzleField('DecodeScene', 'ink'),
      ],
      requiredAssets: [
        PuzzleAsset('The thing at its place', PuzzleField('DecodeScene', 'picture')),
        PuzzleAsset('The same picture, its code cleared away', PuzzleField('DecodeScene', 'cleared')),
      ],
      constraints: ['Never a wrong answer: it hands a clue over rather than tests.'],
    ),
    PuzzleDefinition(
      id: 'spot_difference',
      name: 'Spot the differences',
      description: 'Two pictures side by side; every difference is tapped, in any order.',
      actions: [PuzzleAction.compare, PuzzleAction.tapPicture],
      reuseGrade: PuzzleReuseGrade.ready,
      generationMode: PuzzleGenerationMode.requiresAssets,
      engines: [
        PuzzleEngineBinding(widget: 'SpotDifferences', source: '$_w/spot_differences.dart', table: 'compares', model: 'CompareScene', missionTypes: {MissionType.spotDifferences}, surfaces: _m),
      ],
      requiredData: [
        PuzzleField('Mission', 'options'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'hints'),
        PuzzleField('CompareScene', 'pixels'),
        PuzzleField('CompareScene', 'changes'),
        PuzzleField('PictureSpot', 'area'),
        PuzzleField('CompareScene', 'task'),
        PuzzleField('CompareScene', 'foundLines'),
      ],
      requiredAssets: [
        PuzzleAsset('The original picture', PuzzleField('CompareScene', 'real')),
        PuzzleAsset('The changed picture, same framing and size', PuzzleField('CompareScene', 'painted')),
      ],
      constraints: ["Its differences are pixel rects of the picture: small ones are small taps on a phone's width."],
    ),
    PuzzleDefinition(
      id: 'room_find_match',
      name: 'Find and match',
      description: 'A room is looked round for its pictures; then each note is joined to its picture.',
      actions: [PuzzleAction.tapPicture, PuzzleAction.matchPairs],
      reuseGrade: PuzzleReuseGrade.ready,
      generationMode: PuzzleGenerationMode.requiresAssets,
      engines: [
        PuzzleEngineBinding(widget: 'StudioMatch', source: '$_w/studio_match.dart', table: 'studios', model: 'StudioScene', missionTypes: {MissionType.matchPairs}, surfaces: _m),
      ],
      requiredData: [
        PuzzleField('Mission', 'letter'),
        PuzzleField('Mission', 'options'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'hints'),
        PuzzleField('StudioScene', 'picture'),
        PuzzleField('StudioScene', 'pixels'),
        PuzzleField('StudioScene', 'paintings'),
        PuzzleField('StudioPainting', 'area'),
        PuzzleField('StudioPainting', 'file'),
        PuzzleField('StudioScene', 'order'),
        PuzzleField('StudioScene', 'desk'),
        PuzzleField('StudioScene', 'task'),
        PuzzleField('StudioScene', 'matchTask'),
      ],
      requiredAssets: [
        PuzzleAsset('The room', PuzzleField('StudioScene', 'picture')),
        PuzzleAsset('Each picture found in it, up close', PuzzleField('StudioPainting', 'file')),
      ],
    ),
    PuzzleDefinition(
      id: 'layer_reveal',
      name: 'Under the paint',
      description: 'The top picture is slid away; every mark underneath is tapped.',
      actions: [PuzzleAction.slideReveal, PuzzleAction.tapPicture],
      reuseGrade: PuzzleReuseGrade.ready,
      generationMode: PuzzleGenerationMode.requiresAssets,
      engines: [
        PuzzleEngineBinding(widget: 'RevealLayer', source: '$_w/reveal_layer.dart', table: 'layers', model: 'LayerScene', missionTypes: {MissionType.revealLayer}, surfaces: _m),
      ],
      requiredData: [
        PuzzleField('Mission', 'options'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'hints'),
        PuzzleField('LayerScene', 'pixels'),
        PuzzleField('LayerScene', 'view'),
        PuzzleField('LayerScene', 'canvas'),
        PuzzleField('LayerScene', 'marks'),
        PuzzleField('LayerScene', 'slideTask'),
        PuzzleField('LayerScene', 'findTask'),
      ],
      requiredAssets: [
        PuzzleAsset('The top picture', PuzzleField('LayerScene', 'paint')),
        PuzzleAsset('The picture under it, in register', PuzzleField('LayerScene', 'sketch')),
      ],
    ),
    PuzzleDefinition(
      id: 'clue_filter_choice',
      name: 'The one that fits',
      description: 'Every candidate is looked at; the one that fits every clue is chosen and turned round.',
      actions: [PuzzleAction.compare, PuzzleAction.chooseOption],
      reuseGrade: PuzzleReuseGrade.ready,
      generationMode: PuzzleGenerationMode.requiresAssets,
      engines: [
        PuzzleEngineBinding(widget: 'CanvasPicker', source: '$_w/canvas_choice.dart', table: 'canvases', model: 'CanvasScene', missionTypes: {MissionType.canvasChoice}, surfaces: _f),
      ],
      requiredData: [
        PuzzleField('Mission', 'options'),
        PuzzleField('ChoiceOption', 'feedback'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'hints'),
        PuzzleField('CanvasScene', 'canvases'),
        PuzzleField('CanvasScene', 'pixels'),
        PuzzleField('CanvasScene', 'paint'),
        PuzzleField('CanvasScene', 'backPixels'),
        PuzzleField('CanvasScene', 'writeOn'),
        PuzzleField('CanvasScene', 'message'),
      ],
      requiredAssets: [
        PuzzleAsset('Each candidate', PuzzleField('ChoiceCanvas', 'file')),
        PuzzleAsset("The right one's back", PuzzleField('CanvasScene', 'back')),
      ],
    ),
    PuzzleDefinition(
      id: 'record_mismatch',
      name: 'Records that do not match',
      description: 'Two records of the same thing are read; the pair of lines that disagree is picked.',
      actions: [PuzzleAction.readDocument, PuzzleAction.compare, PuzzleAction.matchPairs],
      reuseGrade: PuzzleReuseGrade.ready,
      generationMode: PuzzleGenerationMode.requiresAssets,
      engines: [
        PuzzleEngineBinding(widget: 'TowerRecords', source: '$_w/tower_records.dart', table: 'records', model: 'RecordsScene', missionTypes: {MissionType.matchPairs}, surfaces: _m),
      ],
      requiredData: [
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'hints'),
        PuzzleField('RecordsScene', 'first'),
        PuzzleField('RecordsScene', 'second'),
        PuzzleField('RecordDoc', 'pixels'),
        PuzzleField('RecordDoc', 'crop'),
        PuzzleField('RecordDoc', 'sheet'),
        PuzzleField('RecordDoc', 'layout'),
        PuzzleField('RecordDoc', 'lines'),
        PuzzleField('RecordLine', 'label'),
        PuzzleField('RecordLine', 'value'),
        PuzzleField('RecordsScene', 'readTask'),
        PuzzleField('RecordsScene', 'compareTask'),
      ],
      requiredAssets: [PuzzleAsset('Each record, its paper blank (the app writes on it)', PuzzleField('RecordDoc', 'file'))],
      constraints: ['The words are written by the app on the blank paper (its four corners measured): heavy on reading.'],
    ),
    PuzzleDefinition(
      id: 'symbol_dial_lock',
      name: 'Symbol lock',
      description: 'A padlock whose dials show pictures; each is turned to its symbol.',
      actions: [PuzzleAction.turnDial],
      reuseGrade: PuzzleReuseGrade.ready,
      generationMode: PuzzleGenerationMode.requiresAssets,
      engines: [
        PuzzleEngineBinding(widget: 'DialLock', source: '$_w/dial_lock.dart', table: 'dialLocks', model: 'DialLockScene', missionTypes: {MissionType.sequence}, surfaces: _m),
      ],
      requiredData: [
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'hints'),
        PuzzleField('DialLockScene', 'pixels'),
        PuzzleField('DialLockScene', 'view'),
        PuzzleField('DialLockScene', 'windows'),
        PuzzleField('DialLockScene', 'windowRadius'),
        PuzzleField('DialLockScene', 'dialPixels'),
        PuzzleField('DialLockScene', 'pivot'),
        PuzzleField('DialLockScene', 'symbols'),
        PuzzleField('DialSymbol', 'angle'),
        PuzzleField('DialLockScene', 'start'),
        PuzzleField('DialLockScene', 'task'),
      ],
      requiredAssets: [
        PuzzleAsset('The padlock', PuzzleField('DialLockScene', 'lock')),
        PuzzleAsset('The dial with its symbols', PuzzleField('DialLockScene', 'dial')),
      ],
    ),
    PuzzleDefinition(
      id: 'viewpoint_match',
      name: 'Where was it seen from?',
      description: 'Each spot of a place is seen as from there and compared with a picture made from one of them.',
      actions: [PuzzleAction.tapPicture, PuzzleAction.compare, PuzzleAction.chooseOption],
      reuseGrade: PuzzleReuseGrade.ready,
      generationMode: PuzzleGenerationMode.requiresAssets,
      engines: [
        PuzzleEngineBinding(
          widget: 'PainterCornerPuzzle',
          source: '$_w/painter_corner.dart',
          table: 'cornerChoices',
          model: 'CornerChoiceScene',
          missionTypes: {MissionType.multipleChoice},
          surfaces: _m,
        ),
      ],
      requiredData: [
        PuzzleField('Mission', 'options'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'recall'),
        PuzzleField('Mission', 'hints'),
        PuzzleField('CornerChoiceScene', 'squarePixels'),
        PuzzleField('CornerChoiceScene', 'cornerPixels'),
        PuzzleField('CornerChoiceScene', 'corners'),
        PuzzleField('PainterCorner', 'area'),
        PuzzleField('CornerChoiceScene', 'task'),
      ],
      requiredAssets: [
        PuzzleAsset('The place from above', PuzzleField('CornerChoiceScene', 'square')),
        PuzzleAsset('The view from each spot', PuzzleField('PainterCorner', 'file')),
      ],
      constraints: ['The picture compared with is an earlier evidence, brought by Mission.recall.'],
    ),
    PuzzleDefinition(
      id: 'guided_steps',
      name: 'One step at a time',
      description: 'One small thing a step (look, tap, rub, choose one of two), what it needs on the same screen.',
      actions: [PuzzleAction.tapPicture, PuzzleAction.chooseOption, PuzzleAction.readDocument],
      reuseGrade: PuzzleReuseGrade.ready,
      generationMode: PuzzleGenerationMode.requiresAssets,
      engines: [
        PuzzleEngineBinding(
          widget: 'EasyStepsPuzzle',
          source: '$_w/easy_steps.dart',
          table: 'easySteps',
          model: 'EasyStepsScene',
          missionTypes: {MissionType.multipleChoice, MissionType.matchPairs, MissionType.examine},
          surfaces: _both,
        ),
      ],
      requiredData: [
        PuzzleField('Mission', 'answer'),
        PuzzleField('EasyStepsScene', 'title'),
        PuzzleField('EasyStepsScene', 'steps'),
        PuzzleField('EasyStepsScene', 'answer'),
        PuzzleField('EasyStep', 'say'),
        PuzzleField('EasyStep', 'panels'),
        PuzzleField('EasyStep', 'does'),
        PuzzleField('EasyStep', 'options'),
        PuzzleField('EasyStep', 'answer'),
        PuzzleField('EasyStep', 'hints'),
      ],
      requiredAssets: [PuzzleAsset('The pictures its steps show', PuzzleField('EasyPicture', 'file'))],
      constraints: [
        'PicturePanel, PaperPanel, EvidencePanel, DrawnPanel and QuotePanel are general; GearMarkPanel, RubPanel and MachinePanel were made for their cases.',
        'A choice has two answers; the second wrong one is answered for the detective: hard to fail.',
        "On a final page it is played instead of the final's own scene when both are registered.",
      ],
    ),
    PuzzleDefinition(
      id: 'evidence_talk',
      name: 'Show the evidence',
      description: 'A talk with one person: questions asked, and the evidence that answers each prompt shown to them.',
      actions: [PuzzleAction.talk, PuzzleAction.presentEvidence],
      reuseGrade: PuzzleReuseGrade.ready,
      generationMode: PuzzleGenerationMode.requiresAssets,
      engines: [
        PuzzleEngineBinding(widget: 'CaseTalk', source: '$_w/case_talk.dart', table: 'talks', model: 'TalkScene', missionTypes: {MissionType.examine}, surfaces: _both),
        PuzzleEngineBinding(
          widget: 'CaseTalk',
          source: '$_w/case_talk.dart',
          table: 'talkMissions',
          model: 'TalkMission',
          missionTypes: {MissionType.examine},
          surfaces: _m,
          role: PuzzleBindingRole.optional,
          note: "A talk before and/or after another puzzle of the mission (the puzzle's answer is the mission's).",
        ),
      ],
      requiredData: [
        PuzzleField('Mission', 'answer'),
        PuzzleField('TalkScene', 'id'),
        PuzzleField('TalkScene', 'speaker'),
        PuzzleField('TalkScene', 'goal'),
        PuzzleField('TalkScene', 'opening'),
        PuzzleField('TalkScene', 'questions'),
        PuzzleField('TalkScene', 'presents'),
        PuzzleField('TalkPresent', 'prompt'),
        PuzzleField('TalkPresent', 'choices'),
        PuzzleField('TalkPresent', 'accepted'),
        PuzzleField('TalkPresent', 'beat'),
        PuzzleField('TalkPresent', 'miss'),
        PuzzleField('TalkScene', 'finishWhen'),
        PuzzleField('TalkScene', 'answer'),
      ],
      requiredAssets: [
        PuzzleAsset('The person, one portrait a mood', PuzzleField('TalkSpeaker', 'portraits')),
        PuzzleAsset('Where the talk is', PuzzleField('TalkScene', 'background')),
      ],
      constraints: ['The evidence shown is the notebook\'s (earlier missions\' evidence ids).'],
    ),

    PuzzleDefinition(
      id: 'picture_choice',
      name: 'Choose the picture',
      description: 'One of three or four pictures (their names can be hidden) answers the clues.',
      actions: [PuzzleAction.readDocument, PuzzleAction.chooseOption],
      reuseGrade: PuzzleReuseGrade.ready,
      generationMode: PuzzleGenerationMode.requiresAssets,
      engines: [
        PuzzleEngineBinding(widget: 'ImageChoiceQuestion', source: _q, missionTypes: {MissionType.imageChoice}, surfaces: _both),
      ],
      requiredData: [
        PuzzleField('Mission', 'letter'),
        PuzzleField('Mission', 'question'),
        PuzzleField('Mission', 'options'),
        PuzzleField('ChoiceOption', 'altText'),
        PuzzleField('ChoiceOption', 'feedback'),
        PuzzleField('Mission', 'hideOptionNames'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'hints'),
      ],
      requiredAssets: [PuzzleAsset('Each option', PuzzleField('ChoiceOption', 'picture'))],
      constraints: [
        "A new season's option is its picture file (ChoiceOption.picture, shown whole); London's are Artwork values.",
      ],
    ),
    PuzzleDefinition(
      id: 'dark_room_search',
      name: 'Search the room',
      description: 'A room in the dark; the things a report lists are found by tapping where it says.',
      actions: [PuzzleAction.readDocument, PuzzleAction.tapPicture],
      reuseGrade: PuzzleReuseGrade.ready,
      generationMode: PuzzleGenerationMode.requiresAssets,
      engines: [
        PuzzleEngineBinding(
          widget: 'InvestigationSearch',
          source: '$_w/investigation_search.dart',
          table: 'investigations',
          model: 'InvestigationScene',
          missionTypes: {MissionType.multipleChoice},
          surfaces: _m,
        ),
      ],
      requiredData: [
        PuzzleField('Mission', 'letter'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('InvestigationScene', 'picture'),
        PuzzleField('InvestigationScene', 'pixels'),
        PuzzleField('InvestigationScene', 'task'),
        PuzzleField('InvestigationScene', 'documentTitle'),
        PuzzleField('InvestigationScene', 'finds'),
        PuzzleField('InvestigationFind', 'reportLine'),
        PuzzleField('InvestigationFind', 'areas'),
        PuzzleField('InvestigationScene', 'answer'),
        PuzzleField('InvestigationScene', 'arrival'),
        PuzzleField('InvestigationScene', 'guideAt'),
        PuzzleField('InvestigationScene', 'opening'),
        PuzzleField('InvestigationScene', 'inside'),
      ],
      requiredAssets: [
        PuzzleAsset('The room', PuzzleField('InvestigationScene', 'picture')),
        PuzzleAsset('Each thing found, cut out', PuzzleField('InvestigationFind', 'picture')),
      ],
      constraints: ["A new season's room is its picture file (InvestigationScene.picture and pixels); London's is an Artwork value."],
    ),

    // ── Conditional ────────────────────────────────────────────────────
    PuzzleDefinition(
      id: 'clock_set',
      name: 'Set the clock',
      description: "A clock's hands are set (dragged, or − / +) to the time the clues give.",
      actions: [PuzzleAction.readDocument, PuzzleAction.setClockHands],
      reuseGrade: PuzzleReuseGrade.conditional,
      generationMode: PuzzleGenerationMode.requiresDevelopment,
      engines: [
        PuzzleEngineBinding(widget: 'ClockQuestion', source: '$_w/clock_question.dart', table: 'clocks', model: 'ClockPuzzle', missionTypes: {MissionType.numberCode}, surfaces: _m),
      ],
      requiredData: [
        PuzzleField('Mission', 'letter'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'hints'),
        PuzzleField('ClockPuzzle', 'question'),
        PuzzleField('ClockPuzzle', 'lead'),
        PuzzleField('ClockPuzzle', 'guide'),
        PuzzleField('ClockPuzzle', 'dialLabel'),
      ],
      requiredAssets: [PuzzleAsset('The clock face', PuzzleField('ClockPuzzle', 'face'))],
      constraints: ['ClockPuzzle.face is an Artwork value: only the faces already in the game, or code for a new one.'],
    ),
    PuzzleDefinition(
      id: 'witness_compare',
      name: 'Question the witnesses',
      description: 'Each witness is asked the same questions; the two statements that agree are matched.',
      actions: [PuzzleAction.talk, PuzzleAction.compare, PuzzleAction.matchPairs],
      reuseGrade: PuzzleReuseGrade.conditional,
      generationMode: PuzzleGenerationMode.requiresAssets,
      engines: [
        PuzzleEngineBinding(
          widget: 'DialogueInvestigation',
          source: '$_w/dialogue_investigation.dart',
          table: 'dialogues',
          model: 'DialogueScene',
          missionTypes: {MissionType.multipleChoice},
          surfaces: _m,
        ),
      ],
      requiredData: [
        PuzzleField('Mission', 'options'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('DialogueScene', 'place'),
        PuzzleField('DialogueScene', 'goal'),
        PuzzleField('DialogueScene', 'speakers'),
        PuzzleField('DialogueSpeaker', 'answers'),
        PuzzleField('DialogueScene', 'questions'),
        PuzzleField('DialogueScene', 'statements'),
        PuzzleField('DialogueScene', 'deduction'),
        PuzzleField('DialogueDeduction', 'pair'),
        PuzzleField('DialogueDeduction', 'answer'),
      ],
      requiredAssets: [
        PuzzleAsset('Where the talk is', PuzzleField('DialogueScene', 'background')),
        PuzzleAsset('Each witness', PuzzleField('DialogueSpeaker', 'portrait')),
      ],
      constraints: [
        'No level variant: its words cannot differ by level (London Case 06 is written at Rookie only for it). A generated season writes its base words only, so it plays as it is.',
        'Its letter page is never shown (skipsLetter): what the witnesses say is the English read.',
      ],
    ),
    PuzzleDefinition(
      id: 'scene_compare_report',
      name: 'Compare and report',
      description: "The place's clocks are looked at up close, a board read, and the one that is wrong reported at the desk.",
      actions: [PuzzleAction.tapPicture, PuzzleAction.readDocument, PuzzleAction.compare, PuzzleAction.chooseOption],
      reuseGrade: PuzzleReuseGrade.conditional,
      generationMode: PuzzleGenerationMode.requiresAssets,
      engines: [
        PuzzleEngineBinding(
          widget: 'StationClocks',
          source: '$_w/station_clocks.dart',
          table: 'stationClocks',
          model: 'StationClocksScene',
          missionTypes: {MissionType.multipleChoice},
          surfaces: _m,
        ),
      ],
      requiredData: [
        PuzzleField('Mission', 'options'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'hints'),
        PuzzleField('StationClocksScene', 'picture'),
        PuzzleField('StationClocksScene', 'pixels'),
        PuzzleField('StationClocksScene', 'clocks'),
        PuzzleField('PaintedClock', 'time'),
        PuzzleField('PaintedClock', 'centre'),
        PuzzleField('PaintedClock', 'area'),
        PuzzleField('StationClocksScene', 'board'),
        PuzzleField('StationClocksScene', 'desk'),
        PuzzleField('StationClocksScene', 'departures'),
        PuzzleField('StationClocksScene', 'notice'),
        PuzzleField('StationClocksScene', 'task'),
      ],
      requiredAssets: [PuzzleAsset('The hall with its clocks, board and desk', PuzzleField('StationClocksScene', 'picture'))],
      constraints: [
        'Made for a station hall: painted clocks (hands drawn by the app), a departures board and a desk; its own words (PLATFORM, REPORT HERE…) are in the widget.',
      ],
    ),
    PuzzleDefinition(
      id: 'evidence_board',
      name: 'Evidence board',
      description: "The case's questions each joined to the evidence that answers them; then the conclusion is chosen.",
      actions: [PuzzleAction.linkEvidence, PuzzleAction.chooseOption],
      reuseGrade: PuzzleReuseGrade.conditional,
      generationMode: PuzzleGenerationMode.requiresDevelopment,
      engines: [
        PuzzleEngineBinding(
          widget: 'EvidenceBoard',
          source: '$_w/evidence_board.dart',
          table: 'evidenceBoards',
          model: 'EvidenceBoardScene',
          missionTypes: {MissionType.matchPairs},
          surfaces: _f,
        ),
      ],
      requiredData: [
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'hints'),
        PuzzleField('EvidenceBoardScene', 'questions'),
        PuzzleField('EvidenceBoardScene', 'evidence'),
        PuzzleField('BoardEvidence', 'evidenceId'),
        PuzzleField('EvidenceBoardScene', 'conclusionId'),
        PuzzleField('EvidenceBoardScene', 'conclusionQuestion'),
        PuzzleField('EvidenceBoardScene', 'conclusions'),
      ],
      requiredAssets: [
        PuzzleAsset('The stage, shut', PuzzleField('EvidenceBoardScene', 'shut')),
        PuzzleAsset('The stage, open', PuzzleField('EvidenceBoardScene', 'open')),
        PuzzleAsset('The plaque found', PuzzleField('EvidenceBoardScene', 'plaque')),
      ],
      constraints: ["The board's scene also requires its case's stage: a machine (shut, open) and a plaque with its river word."],
    ),
    PuzzleDefinition(
      id: 'closeup_compare_choose',
      name: 'Compare up close',
      description: 'Each candidate is looked at up close against a reference; the one that matches is chosen.',
      actions: [PuzzleAction.tapPicture, PuzzleAction.compare, PuzzleAction.chooseOption],
      reuseGrade: PuzzleReuseGrade.conditional,
      generationMode: PuzzleGenerationMode.requiresDevelopment,
      engines: [
        PuzzleEngineBinding(
          widget: 'RiverMarks',
          source: '$_w/river_marks.dart',
          table: 'riverMarks',
          model: 'RiverMarksScene',
          missionTypes: {MissionType.multipleChoice},
          surfaces: _m,
          role: PuzzleBindingRole.alternative,
          note: 'Carved marks against a plaque.',
        ),
        PuzzleEngineBinding(
          widget: 'MarkCompare',
          source: '$_w/mark_compare.dart',
          table: 'markCompares',
          model: 'MarkCompareScene',
          missionTypes: {MissionType.multipleChoice},
          surfaces: _m,
          role: PuzzleBindingRole.alternative,
          note: 'Stamped things against a tracing sheet.',
        ),
        PuzzleEngineBinding(
          widget: 'HoldRackPuzzle',
          source: '$_w/hold_rack.dart',
          table: 'holdRacks',
          model: 'HoldRackScene',
          missionTypes: {MissionType.multipleChoice},
          surfaces: _m,
          role: PuzzleBindingRole.alternative,
          note: 'Tags, turned over, against a trail.',
        ),
        PuzzleEngineBinding(
          widget: 'LetterMapPuzzle',
          source: '$_w/letter_map.dart',
          table: 'letterMaps',
          model: 'LetterMapScene',
          missionTypes: {MissionType.multipleChoice},
          surfaces: _f,
          role: PuzzleBindingRole.alternative,
          note: "A map's buildings against a drawing.",
        ),
      ],
      requiredData: [
        PuzzleField('Mission', 'options'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('Mission', 'hints'),
        PuzzleField('RiverMarksScene', 'marks'),
        PuzzleField('MarkCompareScene', 'seals'),
        PuzzleField('HoldRackScene', 'tags'),
        PuzzleField('LetterMapScene', 'spots'),
      ],
      requiredAssets: [
        PuzzleAsset('The wall of marks', PuzzleField('RiverMarksScene', 'wall')),
        PuzzleAsset('The bench of stamped things', PuzzleField('MarkCompareScene', 'bench')),
        PuzzleAsset('The rack of tags', PuzzleField('HoldRackScene', 'file')),
        PuzzleAsset('The map', PuzzleField('LetterMapScene', 'mapFile')),
      ],
      constraints: [
        'No one engine yet: four, each with its own model (one of them per mission; its data and pictures are its own).',
        'RiverMark (waves, arrowDown), BenchSeal (MarkCopy) and MapBuilding (BuildingFeature) carry their cases\' own kinds.',
      ],
    ),
    PuzzleDefinition(
      id: 'token_place_map',
      name: 'Place on the map',
      description: 'Small pieces are dragged (or tapped, then a place tapped) onto their places on a map.',
      actions: [PuzzleAction.placeToken, PuzzleAction.dragOnPicture],
      reuseGrade: PuzzleReuseGrade.conditional,
      generationMode: PuzzleGenerationMode.requiresDevelopment,
      engines: [
        PuzzleEngineBinding(
          widget: 'TrialMapPuzzle',
          source: '$_w/clockwork_garden.dart',
          table: 'trialMaps',
          model: 'TrialMapScene',
          missionTypes: {MissionType.matchPairs},
          surfaces: _m,
        ),
      ],
      requiredData: [
        PuzzleField('Mission', 'options'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('TrialMapScene', 'mapPixels'),
        PuzzleField('TrialMapScene', 'spots'),
        PuzzleField('MapSpot', 'at'),
        PuzzleField('TrialMapScene', 'models'),
        PuzzleField('TrialModel', 'spot'),
        PuzzleField('TrialModel', 'wrongLine'),
        PuzzleField('TrialMapScene', 'task'),
        PuzzleField('TrialMapScene', 'dropRadius'),
      ],
      requiredAssets: [
        PuzzleAsset('The map', PuzzleField('TrialMapScene', 'mapFile')),
        PuzzleAsset('Each piece', PuzzleField('TrialModel', 'file')),
      ],
      constraints: ["The widget describes the map as Paris's to screen readers."],
    ),
    PuzzleDefinition(
      id: 'symbol_join',
      name: 'Join the marks',
      description: 'A mark from the notebook is tapped, then the same mark on a paper.',
      actions: [PuzzleAction.compare, PuzzleAction.matchPairs],
      reuseGrade: PuzzleReuseGrade.conditional,
      generationMode: PuzzleGenerationMode.requiresDevelopment,
      engines: [
        PuzzleEngineBinding(
          widget: 'MakerMarksPuzzle',
          source: '$_w/clockwork_garden.dart',
          table: 'makerMarks',
          model: 'MakerMarksScene',
          missionTypes: {MissionType.matchPairs},
          surfaces: _m,
        ),
      ],
      requiredData: [
        PuzzleField('Mission', 'options'),
        PuzzleField('Mission', 'answer'),
        PuzzleField('MakerMarksScene', 'pixels'),
        PuzzleField('MakerMarksScene', 'marks'),
        PuzzleField('NotebookMark', 'kind'),
        PuzzleField('NotebookMark', 'evidenceId'),
        PuzzleField('MakerMarksScene', 'paper'),
        PuzzleField('PaperMark', 'kind'),
        PuzzleField('PaperMark', 'markAt'),
        PuzzleField('MakerMarksScene', 'task'),
      ],
      requiredAssets: [PuzzleAsset('The paper with its marks', PuzzleField('MakerMarksScene', 'file'))],
      constraints: [
        "MarkKind is an enum (gear, hands, key) the widget draws: a new mark needs code.",
        "The widget describes the paper with its case's words to screen readers.",
      ],
    ),
  ];

  static final Map<String, PuzzleDefinition> _byId = _index(all);

  static Map<String, PuzzleDefinition> _index(List<PuzzleDefinition> list) {
    final out = <String, PuzzleDefinition>{};
    for (final p in list) {
      if (out.containsKey(p.id)) throw StateError('Puzzle id ${p.id} is registered twice');
      out[p.id] = p;
    }
    return out;
  }

  /// Whether [id] is a puzzle of the palette.
  static bool contains(String id) => _byId.containsKey(id);

  /// The puzzle [id], or null.
  static PuzzleDefinition? lookup(String id) => _byId[id];

  /// The puzzle [id]: an [ArgumentError] when there is none.
  static PuzzleDefinition byId(String id) =>
      _byId[id] ?? (throw ArgumentError.value(id, 'id', 'No puzzle with this id in the palette'));

  static List<PuzzleDefinition> ofGrade(PuzzleReuseGrade grade) => [
    for (final p in all)
      if (p.reuseGrade == grade) p,
  ];

  static List<PuzzleDefinition> ofMode(PuzzleGenerationMode mode) => [
    for (final p in all)
      if (p.generationMode == mode) p,
  ];

  /// The puzzles that can be played on [surface].
  static List<PuzzleDefinition> forSurface(PuzzleSurface surface) => [
    for (final p in all)
      if (p.supports(surface)) p,
  ];

  /// Reusable as they are (grade A).
  static List<PuzzleDefinition> get ready => ofGrade(PuzzleReuseGrade.ready);

  /// Reusable with conditions (grade B).
  static List<PuzzleDefinition> get conditional => ofGrade(PuzzleReuseGrade.conditional);

  /// Written whole by the generator, nothing to approve.
  static List<PuzzleDefinition> get textOnly => ofMode(PuzzleGenerationMode.textOnly);

  /// Generated once their pictures are approved (never straight to code).
  static List<PuzzleDefinition> get needingAssets => ofMode(PuzzleGenerationMode.requiresAssets);

  /// Not generated until their code is changed.
  static List<PuzzleDefinition> get needingDevelopment => ofMode(PuzzleGenerationMode.requiresDevelopment);

  /// Every puzzle the generator may plan: [textOnly] (at once) and
  /// [needingAssets] (after approval); never [needingDevelopment].
  static List<PuzzleDefinition> get generatable => [
    for (final p in all)
      if (p.generationMode != PuzzleGenerationMode.requiresDevelopment) p,
  ];
}
