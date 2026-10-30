/// What the puzzle selection check (STEP 3-3) knows of the game's
/// `PuzzlePalette` (lib/data/content/puzzle_palette.dart) and of the dial
/// symbols (`GameSymbol`, lib/widgets/symbol_icon.dart), in plain Dart.
///
/// The palette itself imports Flutter (through `MissionType`), and these
/// tools run with plain `dart run`: so its facts are copied here, written by
/// `test/season_gen/palette_facts_test.dart` from the palette itself
/// (`PALETTE_FACTS_WRITE=1 flutter test test/season_gen/palette_facts_test.dart`)
/// and checked by it on every run. Never edited by hand between the
/// markers: a palette change fails that test until the copy is written again.
library;

import 'plan_models.dart';

/// `PuzzleGenerationMode`.
enum PaletteMode { textOnly, requiresAssets, requiresDevelopment }

/// `PuzzleReuseGrade` (the palette holds no `custom` puzzle).
enum PaletteGrade { ready, conditional }

/// `PuzzleBindingRole`.
enum PaletteRole { primary, alternative, optional }

/// A `PuzzleEngineBinding`: an engine that plays the puzzle, as the game
/// plays it today.
class PaletteEngine {
  const PaletteEngine(this.widget, this.table, this.missionTypes, this.surfaces, {this.role = PaletteRole.primary});

  final String widget;

  /// Its `SeasonContent.missionTables` table; null: played from the
  /// mission's own type.
  final String? table;

  /// `MissionType` names.
  final Set<String> missionTypes;
  final Set<PlanSurface> surfaces;
  final PaletteRole role;

  /// Plays the puzzle on its own (not laid on another engine).
  bool get playable => role != PaletteRole.optional;
}

/// A `PuzzleDefinition`: its id, grade, mode, engines, and its fields
/// (`Model.field`) as the palette lists them.
class PalettePuzzle {
  const PalettePuzzle(
    this.id,
    this.grade,
    this.mode, {
    required this.engines,
    required this.requiredData,
    this.requiredAssets = const [],
    this.optionalAssets = const [],
  });

  final String id;
  final PaletteGrade grade;
  final PaletteMode mode;
  final List<PaletteEngine> engines;
  final List<String> requiredData;

  /// The fields the pictures it needs are written in.
  final List<String> requiredAssets;

  /// The fields of pictures only an optional engine uses.
  final List<String> optionalAssets;

  /// The engines that play it on [surface] on their own.
  List<PaletteEngine> enginesFor(PlanSurface surface) => [
    for (final e in engines)
      if (e.playable && e.surfaces.contains(surface)) e,
  ];

  bool supports(PlanSurface surface) => enginesFor(surface).isNotEmpty;

  /// The engines laid on its own on [surface] (a lock's box, a talk around it).
  List<PaletteEngine> companionsFor(PlanSurface surface) => [
    for (final e in engines)
      if (!e.playable && e.surfaces.contains(surface)) e,
  ];
}

abstract final class PaletteFacts {
  static final Map<String, PalettePuzzle> _byId = {for (final p in all) p.id: p};

  static PalettePuzzle? lookup(String id) => _byId[id];

  /// The palette puzzle whose engine reads [table], or null.
  static PalettePuzzle? ofTable(String table) {
    for (final p in all) {
      if (p.engines.any((e) => e.table == table)) return p;
    }
    return null;
  }

  // BEGIN GENERATED (palette_facts_test)
  /// Every palette puzzle, in palette order.
  static const all = <PalettePuzzle>[
    PalettePuzzle(
      'text_choice',
      PaletteGrade.ready,
      PaletteMode.textOnly,
      engines: [
        PaletteEngine('MultipleChoiceQuestion', null, {'multipleChoice'}, {PlanSurface.mission, PlanSurface.finalMission}),
      ],
      requiredData: ['Mission.letter', 'Mission.question', 'Mission.options', 'ChoiceOption.label', 'ChoiceOption.feedback', 'Mission.answer', 'Mission.hints'],
    ),
    PalettePuzzle(
      'word_entry',
      PaletteGrade.ready,
      PaletteMode.textOnly,
      engines: [
        PaletteEngine('WordInputQuestion', null, {'wordInput'}, {PlanSurface.mission, PlanSurface.finalMission}),
      ],
      requiredData: ['Mission.letter', 'Mission.question', 'Mission.answer', 'Mission.acceptedAnswers', 'Mission.hints'],
    ),
    PalettePuzzle(
      'number_entry',
      PaletteGrade.ready,
      PaletteMode.textOnly,
      engines: [
        PaletteEngine('NumberCodeQuestion', null, {'numberCode'}, {PlanSurface.mission, PlanSurface.finalMission}),
      ],
      requiredData: ['Mission.letter', 'Mission.question', 'Mission.answer', 'Mission.codeLength', 'Mission.codeFormat', 'Mission.hints'],
    ),
    PalettePuzzle(
      'combo_dial_lock',
      PaletteGrade.ready,
      PaletteMode.textOnly,
      engines: [
        PaletteEngine('_Dial', null, {'finalCode'}, {PlanSurface.finalMission}),
      ],
      requiredData: ['Mission.question', 'Mission.answer', 'Mission.codeLength', 'Mission.dialSymbols', 'Mission.hints'],
    ),
    PalettePuzzle(
      'letter_tile_lock',
      PaletteGrade.ready,
      PaletteMode.textOnly,
      engines: [
        PaletteEngine('LetterLockQuestion', null, {'letterLock'}, {PlanSurface.mission, PlanSurface.finalMission}),
        PaletteEngine('LockBoxStage', 'lockBoxes', {'letterLock'}, {PlanSurface.finalMission}, role: PaletteRole.optional),
      ],
      requiredData: ['Mission.question', 'Mission.options', 'Mission.answer', 'Mission.hints'],
      optionalAssets: ['LockBoxArt.closed', 'LockBoxArt.open', 'LockBoxArt.found'],
    ),
    PalettePuzzle(
      'order_sequence',
      PaletteGrade.ready,
      PaletteMode.textOnly,
      engines: [
        PaletteEngine('SequenceQuestion', null, {'sequence'}, {PlanSurface.mission, PlanSurface.finalMission}),
      ],
      requiredData: ['Mission.letter', 'Mission.question', 'Mission.options', 'Mission.answer', 'Mission.codeLength', 'Mission.orderFeedback', 'Mission.hints'],
    ),
    PalettePuzzle(
      'scene_explore_choose',
      PaletteGrade.ready,
      PaletteMode.requiresAssets,
      engines: [
        PaletteEngine('SceneExplore', 'explores', {'multipleChoice'}, {PlanSurface.mission}),
      ],
      requiredData: ['Mission.letter', 'Mission.options', 'Mission.answer', 'Mission.hints', 'ExploreScene.picture', 'ExploreScene.pixels', 'ExploreScene.place', 'ExploreScene.task', 'ExploreScene.nextTask', 'ExploreScene.spots', 'ExploreSpot.kind', 'ExploreSpot.areas', 'ExploreSpot.mark', 'ExploreScene.choices', 'ExploreScene.missLine', 'ExploreScene.guideAt', 'ExploreScene.inside', 'ExploreScene.opening'],
      requiredAssets: ['ExploreScene.picture', 'ExplorePicture.picture'],
    ),
    PalettePuzzle(
      'lens_inspect_word',
      PaletteGrade.ready,
      PaletteMode.requiresAssets,
      engines: [
        PaletteEngine('LensInspect', 'inspections', {'wordInput'}, {PlanSurface.mission}),
      ],
      requiredData: ['Mission.letter', 'Mission.prompt', 'Mission.answer', 'Mission.hints', 'InspectScene.picture', 'InspectScene.pixels', 'InspectScene.task', 'InspectScene.spots', 'InspectSpot.areas', 'InspectSpot.checks', 'InspectScene.labelTitle', 'InspectScene.taskLine', 'InspectScene.lensAt', 'InspectScene.inside'],
      requiredAssets: ['InspectScene.picture'],
    ),
    PalettePuzzle(
      'trace_deduction',
      PaletteGrade.ready,
      PaletteMode.requiresAssets,
      engines: [
        PaletteEngine('SceneDeduction', 'deductions', {'multipleChoice'}, {PlanSurface.mission}),
      ],
      requiredData: ['Mission.letter', 'Mission.options', 'Mission.answer', 'Mission.hints', 'DeductionScene.picture', 'DeductionScene.pixels', 'DeductionScene.task', 'DeductionScene.chooseTask', 'DeductionScene.clues', 'DeductionClue.areas', 'DeductionClue.line', 'DeductionScene.places', 'DeductionPlace.optionId', 'DeductionPlace.areas', 'DeductionScene.guideAt', 'DeductionScene.inside', 'DeductionScene.opening'],
      requiredAssets: ['DeductionScene.picture'],
    ),
    PalettePuzzle(
      'object_decode',
      PaletteGrade.ready,
      PaletteMode.requiresAssets,
      engines: [
        PaletteEngine('SceneDecode', 'decodes', {'examine'}, {PlanSurface.mission}),
      ],
      requiredData: ['Mission.letter', 'Mission.answer', 'Mission.evidence', 'DecodeScene.picture', 'DecodeScene.pixels', 'DecodeScene.thing', 'DecodeScene.areas', 'DecodeScene.closer', 'DecodeScene.code', 'DecodeScene.cleared', 'DecodeScene.clearedArea', 'DecodeScene.revealed', 'DecodeScene.ink'],
      requiredAssets: ['DecodeScene.picture', 'DecodeScene.cleared'],
    ),
    PalettePuzzle(
      'spot_difference',
      PaletteGrade.ready,
      PaletteMode.requiresAssets,
      engines: [
        PaletteEngine('SpotDifferences', 'compares', {'spotDifferences'}, {PlanSurface.mission}),
      ],
      requiredData: ['Mission.options', 'Mission.answer', 'Mission.hints', 'CompareScene.pixels', 'CompareScene.changes', 'PictureSpot.area', 'CompareScene.task', 'CompareScene.foundLines'],
      requiredAssets: ['CompareScene.real', 'CompareScene.painted'],
    ),
    PalettePuzzle(
      'room_find_match',
      PaletteGrade.ready,
      PaletteMode.requiresAssets,
      engines: [
        PaletteEngine('StudioMatch', 'studios', {'matchPairs'}, {PlanSurface.mission}),
      ],
      requiredData: ['Mission.letter', 'Mission.options', 'Mission.answer', 'Mission.hints', 'StudioScene.picture', 'StudioScene.pixels', 'StudioScene.paintings', 'StudioPainting.area', 'StudioPainting.file', 'StudioScene.order', 'StudioScene.desk', 'StudioScene.task', 'StudioScene.matchTask'],
      requiredAssets: ['StudioScene.picture', 'StudioPainting.file'],
    ),
    PalettePuzzle(
      'layer_reveal',
      PaletteGrade.ready,
      PaletteMode.requiresAssets,
      engines: [
        PaletteEngine('RevealLayer', 'layers', {'revealLayer'}, {PlanSurface.mission}),
      ],
      requiredData: ['Mission.options', 'Mission.answer', 'Mission.hints', 'LayerScene.pixels', 'LayerScene.view', 'LayerScene.canvas', 'LayerScene.marks', 'LayerScene.slideTask', 'LayerScene.findTask'],
      requiredAssets: ['LayerScene.paint', 'LayerScene.sketch'],
    ),
    PalettePuzzle(
      'clue_filter_choice',
      PaletteGrade.ready,
      PaletteMode.requiresAssets,
      engines: [
        PaletteEngine('CanvasPicker', 'canvases', {'canvasChoice'}, {PlanSurface.finalMission}),
      ],
      requiredData: ['Mission.options', 'ChoiceOption.feedback', 'Mission.answer', 'Mission.hints', 'CanvasScene.canvases', 'CanvasScene.pixels', 'CanvasScene.paint', 'CanvasScene.backPixels', 'CanvasScene.writeOn', 'CanvasScene.message'],
      requiredAssets: ['ChoiceCanvas.file', 'CanvasScene.back'],
    ),
    PalettePuzzle(
      'record_mismatch',
      PaletteGrade.ready,
      PaletteMode.requiresAssets,
      engines: [
        PaletteEngine('TowerRecords', 'records', {'matchPairs'}, {PlanSurface.mission}),
      ],
      requiredData: ['Mission.answer', 'Mission.hints', 'RecordsScene.first', 'RecordsScene.second', 'RecordDoc.pixels', 'RecordDoc.crop', 'RecordDoc.sheet', 'RecordDoc.layout', 'RecordDoc.lines', 'RecordLine.label', 'RecordLine.value', 'RecordsScene.readTask', 'RecordsScene.compareTask'],
      requiredAssets: ['RecordDoc.file'],
    ),
    PalettePuzzle(
      'symbol_dial_lock',
      PaletteGrade.ready,
      PaletteMode.requiresAssets,
      engines: [
        PaletteEngine('DialLock', 'dialLocks', {'sequence'}, {PlanSurface.mission}),
      ],
      requiredData: ['Mission.answer', 'Mission.hints', 'DialLockScene.pixels', 'DialLockScene.view', 'DialLockScene.windows', 'DialLockScene.windowRadius', 'DialLockScene.dialPixels', 'DialLockScene.pivot', 'DialLockScene.symbols', 'DialSymbol.angle', 'DialLockScene.start', 'DialLockScene.task'],
      requiredAssets: ['DialLockScene.lock', 'DialLockScene.dial'],
    ),
    PalettePuzzle(
      'viewpoint_match',
      PaletteGrade.ready,
      PaletteMode.requiresAssets,
      engines: [
        PaletteEngine('PainterCornerPuzzle', 'cornerChoices', {'multipleChoice'}, {PlanSurface.mission}),
      ],
      requiredData: ['Mission.options', 'Mission.answer', 'Mission.recall', 'Mission.hints', 'CornerChoiceScene.squarePixels', 'CornerChoiceScene.cornerPixels', 'CornerChoiceScene.corners', 'PainterCorner.area', 'CornerChoiceScene.task'],
      requiredAssets: ['CornerChoiceScene.square', 'PainterCorner.file'],
    ),
    PalettePuzzle(
      'guided_steps',
      PaletteGrade.ready,
      PaletteMode.requiresAssets,
      engines: [
        PaletteEngine('EasyStepsPuzzle', 'easySteps', {'multipleChoice', 'matchPairs', 'examine'}, {PlanSurface.mission, PlanSurface.finalMission}),
      ],
      requiredData: ['Mission.answer', 'EasyStepsScene.title', 'EasyStepsScene.steps', 'EasyStepsScene.answer', 'EasyStep.say', 'EasyStep.panels', 'EasyStep.does', 'EasyStep.options', 'EasyStep.answer', 'EasyStep.hints'],
      requiredAssets: ['EasyPicture.file'],
    ),
    PalettePuzzle(
      'evidence_talk',
      PaletteGrade.ready,
      PaletteMode.requiresAssets,
      engines: [
        PaletteEngine('CaseTalk', 'talks', {'examine'}, {PlanSurface.mission, PlanSurface.finalMission}),
        PaletteEngine('CaseTalk', 'talkMissions', {'examine', 'multipleChoice', 'imageChoice', 'sequence', 'wordInput', 'letterLock', 'finalCode'}, {PlanSurface.mission}, role: PaletteRole.optional),
      ],
      requiredData: ['Mission.answer', 'TalkScene.id', 'TalkScene.speaker', 'TalkScene.goal', 'TalkScene.opening', 'TalkScene.questions', 'TalkScene.presents', 'TalkPresent.prompt', 'TalkPresent.choices', 'TalkPresent.accepted', 'TalkPresent.beat', 'TalkPresent.miss', 'TalkScene.finishWhen', 'TalkScene.answer'],
      requiredAssets: ['TalkSpeaker.portraits', 'TalkScene.background'],
    ),
    PalettePuzzle(
      'picture_choice',
      PaletteGrade.ready,
      PaletteMode.requiresAssets,
      engines: [
        PaletteEngine('ImageChoiceQuestion', null, {'imageChoice'}, {PlanSurface.mission, PlanSurface.finalMission}),
      ],
      requiredData: ['Mission.letter', 'Mission.question', 'Mission.options', 'ChoiceOption.altText', 'ChoiceOption.feedback', 'Mission.hideOptionNames', 'Mission.answer', 'Mission.hints'],
      requiredAssets: ['ChoiceOption.picture'],
    ),
    PalettePuzzle(
      'dark_room_search',
      PaletteGrade.ready,
      PaletteMode.requiresAssets,
      engines: [
        PaletteEngine('InvestigationSearch', 'investigations', {'multipleChoice'}, {PlanSurface.mission}),
      ],
      requiredData: ['Mission.letter', 'Mission.answer', 'InvestigationScene.picture', 'InvestigationScene.pixels', 'InvestigationScene.task', 'InvestigationScene.documentTitle', 'InvestigationScene.finds', 'InvestigationFind.reportLine', 'InvestigationFind.areas', 'InvestigationScene.answer', 'InvestigationScene.arrival', 'InvestigationScene.guideAt', 'InvestigationScene.opening', 'InvestigationScene.inside'],
      requiredAssets: ['InvestigationScene.picture', 'InvestigationFind.picture'],
    ),
    PalettePuzzle(
      'clock_set',
      PaletteGrade.conditional,
      PaletteMode.requiresDevelopment,
      engines: [
        PaletteEngine('ClockQuestion', 'clocks', {'numberCode'}, {PlanSurface.mission}),
      ],
      requiredData: ['Mission.letter', 'Mission.answer', 'Mission.hints', 'ClockPuzzle.question', 'ClockPuzzle.lead', 'ClockPuzzle.guide', 'ClockPuzzle.dialLabel'],
      requiredAssets: ['ClockPuzzle.face'],
    ),
    PalettePuzzle(
      'witness_compare',
      PaletteGrade.conditional,
      PaletteMode.requiresAssets,
      engines: [
        PaletteEngine('DialogueInvestigation', 'dialogues', {'multipleChoice'}, {PlanSurface.mission}),
      ],
      requiredData: ['Mission.options', 'Mission.answer', 'DialogueScene.place', 'DialogueScene.goal', 'DialogueScene.speakers', 'DialogueSpeaker.answers', 'DialogueScene.questions', 'DialogueScene.statements', 'DialogueScene.deduction', 'DialogueDeduction.pair', 'DialogueDeduction.answer'],
      requiredAssets: ['DialogueScene.background', 'DialogueSpeaker.portrait'],
    ),
    PalettePuzzle(
      'scene_compare_report',
      PaletteGrade.conditional,
      PaletteMode.requiresAssets,
      engines: [
        PaletteEngine('StationClocks', 'stationClocks', {'multipleChoice'}, {PlanSurface.mission}),
      ],
      requiredData: ['Mission.options', 'Mission.answer', 'Mission.hints', 'StationClocksScene.picture', 'StationClocksScene.pixels', 'StationClocksScene.clocks', 'PaintedClock.time', 'PaintedClock.centre', 'PaintedClock.area', 'StationClocksScene.board', 'StationClocksScene.desk', 'StationClocksScene.departures', 'StationClocksScene.notice', 'StationClocksScene.task'],
      requiredAssets: ['StationClocksScene.picture'],
    ),
    PalettePuzzle(
      'evidence_board',
      PaletteGrade.conditional,
      PaletteMode.requiresDevelopment,
      engines: [
        PaletteEngine('EvidenceBoard', 'evidenceBoards', {'matchPairs'}, {PlanSurface.finalMission}),
      ],
      requiredData: ['Mission.answer', 'Mission.hints', 'EvidenceBoardScene.questions', 'EvidenceBoardScene.evidence', 'BoardEvidence.evidenceId', 'EvidenceBoardScene.conclusionId', 'EvidenceBoardScene.conclusionQuestion', 'EvidenceBoardScene.conclusions'],
      requiredAssets: ['EvidenceBoardScene.shut', 'EvidenceBoardScene.open', 'EvidenceBoardScene.plaque'],
    ),
    PalettePuzzle(
      'closeup_compare_choose',
      PaletteGrade.conditional,
      PaletteMode.requiresDevelopment,
      engines: [
        PaletteEngine('RiverMarks', 'riverMarks', {'multipleChoice'}, {PlanSurface.mission}, role: PaletteRole.alternative),
        PaletteEngine('MarkCompare', 'markCompares', {'multipleChoice'}, {PlanSurface.mission}, role: PaletteRole.alternative),
        PaletteEngine('HoldRackPuzzle', 'holdRacks', {'multipleChoice'}, {PlanSurface.mission}, role: PaletteRole.alternative),
        PaletteEngine('LetterMapPuzzle', 'letterMaps', {'multipleChoice'}, {PlanSurface.finalMission}, role: PaletteRole.alternative),
      ],
      requiredData: ['Mission.options', 'Mission.answer', 'Mission.hints', 'RiverMarksScene.marks', 'MarkCompareScene.seals', 'HoldRackScene.tags', 'LetterMapScene.spots'],
      requiredAssets: ['RiverMarksScene.wall', 'MarkCompareScene.bench', 'HoldRackScene.file', 'LetterMapScene.mapFile'],
    ),
    PalettePuzzle(
      'token_place_map',
      PaletteGrade.conditional,
      PaletteMode.requiresDevelopment,
      engines: [
        PaletteEngine('TrialMapPuzzle', 'trialMaps', {'matchPairs'}, {PlanSurface.mission}),
      ],
      requiredData: ['Mission.options', 'Mission.answer', 'TrialMapScene.mapPixels', 'TrialMapScene.spots', 'MapSpot.at', 'TrialMapScene.models', 'TrialModel.spot', 'TrialModel.wrongLine', 'TrialMapScene.task', 'TrialMapScene.dropRadius'],
      requiredAssets: ['TrialMapScene.mapFile', 'TrialModel.file'],
    ),
    PalettePuzzle(
      'symbol_join',
      PaletteGrade.conditional,
      PaletteMode.requiresDevelopment,
      engines: [
        PaletteEngine('MakerMarksPuzzle', 'makerMarks', {'matchPairs'}, {PlanSurface.mission}),
      ],
      requiredData: ['Mission.options', 'Mission.answer', 'MakerMarksScene.pixels', 'MakerMarksScene.marks', 'NotebookMark.kind', 'NotebookMark.evidenceId', 'MakerMarksScene.paper', 'PaperMark.kind', 'PaperMark.markAt', 'MakerMarksScene.task'],
      requiredAssets: ['MakerMarksScene.file'],
    ),
  ];

  /// The names a dial can show (`GameSymbol`).
  static const dialSymbols = {'train', 'museum', 'clock', 'park', 'palace', 'crown', 'raven', 'gear', 'letter', 'key', 'watch', 'map', 'ticket', 'feather', 'footprint', 'button', 'cloth', 'seal', 'frame', 'mask', 'gem', 'bag', 'umbrella', 'whistle'};
  // END GENERATED
}
