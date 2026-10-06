import 'package:flutter/foundation.dart';

/// The puzzle mechanic used by a mission.
enum MissionType {
  multipleChoice,
  wordInput,
  numberCode,
  imageChoice,
  qrScan,
  finalCode,

  /// Tap the options in the right order (ids joined by commas). An option
  /// can be used again when there are fewer options than [Mission.codeLength]
  /// (e.g. LEFT / RIGHT turns); otherwise each is used once.
  sequence;

  static MissionType fromJson(String value) => MissionType.values.firstWhere(
    (t) => t.name == value,
    orElse: () => throw FormatException('Unknown mission type: $value'),
  );
}

/// English skills a mission exercises (used by the parent report).
enum Skill {
  vocabulary,
  reading,
  problemSolving;

  static Skill fromJson(String value) =>
      Skill.values.firstWhere((s) => s.name == value, orElse: () => throw FormatException('Unknown skill: $value'));
}

/// Illustrations drawn in-app (see `LandmarkArt`). Keeping them as keys lets
/// a backend later send image URLs without touching mission widgets.
enum Artwork {
  kingsCross,
  suitcase,
  britishMuseum,
  bigBen,
  hydePark,
  buckinghamPalace,
  towerBridge,
  londonEye,
  royalBox,
  clockFace,
  gallery,
  towerOfLondon,
  lockedDoor,
  coventGarden,
  theatre,
  raven,
  jewelCase,

  // Places inside a landmark: each has its own picture (see `ArtAssets`);
  // without it, it is drawn as its landmark (see `LandmarkArt.standIns`).
  // Egypt Room and Great Court are named by the presentation only
  // (`PlaceArt.missionScenes`), not by mission data.
  egyptRoom,
  greatCourt,
  // The old brown suitcase (Case 01, Case 04): its picture, else drawn as
  // the suitcase scene. Named by the presentation (`PlaceArt.missionScenes`).
  oldSuitcase,
  boathouse,
  roseGarden,
  waitingRoom,
  staffRoom,
  courtyard,
  dressingRoom,
  // The Covent Garden theatre's auditorium (Case 11: red seats, gold lamps,
  // the stage): its picture, else drawn as the theatre. `theatre` stays the
  // drawn theatre door (Case 06). Named by the presentation.
  auditorium,
  // Mrs Robin's black suitcase (Case 08): its picture, else drawn as the
  // suitcase scene. Named by the presentation (`PlaceArt.missionScenes`).
  blackSuitcase,
  // The doors the data calls `lockedDoor`, each its own: the White Tower's
  // door with a dial and four gears (Case 05) and the small iron door under
  // Big Ben (Case 12). Their pictures, else drawn as the locked door.
  gearDoor,
  ironDoor,
  // The Covent Garden theatre's door at night, the stage lit inside
  // (Case 06): its picture, else drawn as the theatre.
  theatreDoor,
  // The iron chest in the White Tower's locked room (Case 05's final): its
  // picture, else drawn as the locked door. Named by the presentation.
  ironChest,
  // The Royal Archive under Buckingham Palace (Case 01's final place, as the
  // story arrives there): its picture, else drawn as the palace.
  royalArchive,
  // Inside Big Ben: the great wheels behind the clock face, no time to read
  // (Case 02's first mission: the stopped time is its puzzle). Its picture,
  // else drawn as Big Ben.
  clockMechanism,

  // Hyde Park paths (Case 07): the same park, a different spot marked X.
  parkMapA,
  parkMapB,
  parkMapC,
  parkMapD;

  static Artwork fromJson(String value) =>
      Artwork.values.firstWhere((a) => a.name == value, orElse: () => throw FormatException('Unknown artwork: $value'));
}

@immutable
class ChoiceOption {
  const ChoiceOption({required this.id, required this.label, this.artwork});

  final String id;
  final String label;
  final Artwork? artwork;

  factory ChoiceOption.fromJson(Map<String, dynamic> json) => ChoiceOption(
    id: json['id'] as String,
    label: json['label'] as String,
    artwork: json['artwork'] == null ? null : Artwork.fromJson(json['artwork'] as String),
  );

  Map<String, dynamic> toJson() => {'id': id, 'label': label, if (artwork != null) 'artwork': artwork!.name};
}

/// A clue saved to the Detective Notebook when a mission is solved.
@immutable
class Clue {
  const Clue({required this.id, required this.title, required this.value, required this.note, this.symbol});

  final String id;
  final String title;

  /// The short piece of information used later (e.g. a number for the final lock).
  final String value;
  final String note;

  /// Picture key linking this clue to a lock on the Royal Box (see `SymbolIcon`).
  final String? symbol;

  factory Clue.fromJson(Map<String, dynamic> json) => Clue(
    id: json['id'] as String,
    title: json['title'] as String,
    value: json['value'] as String,
    note: json['note'] as String,
    symbol: json['symbol'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'value': value,
    'note': note,
    if (symbol != null) 'symbol': symbol,
  };
}

/// A collectible object found at a location. Players can zoom in on it in
/// the notebook; some evidence carries information needed for the final case.
@immutable
class Evidence {
  const Evidence({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    this.inscription,
    this.symbols = const [],
  });

  final String id;
  final String name;

  /// Icon key (see `EvidenceIcon`).
  final String icon;
  final String description;

  /// Text written on the object, shown when zoomed in.
  final String? inscription;

  /// Pictures drawn on the object, in order (e.g. the Royal Box lock order).
  final List<String> symbols;

  factory Evidence.fromJson(Map<String, dynamic> json) => Evidence(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String,
    description: json['description'] as String,
    inscription: json['inscription'] as String?,
    symbols: (json['symbols'] as List? ?? const []).cast<String>(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'description': description,
    if (inscription != null) 'inscription': inscription,
    if (symbols.isNotEmpty) 'symbols': symbols,
  };
}

@immutable
class Mission {
  const Mission({
    required this.id,
    required this.number,
    required this.title,
    required this.location,
    required this.story,
    required this.scene,
    required this.letterIntro,
    required this.letter,
    required this.type,
    required this.question,
    required this.answer,
    required this.hints,
    required this.successMessage,
    required this.mapX,
    required this.mapY,
    this.prompt,
    this.options = const [],
    this.acceptedAnswers = const [],
    this.codeLength,
    this.dialSymbols = const [],
    this.clue,
    this.evidence,
    this.transition = const [],
    this.nextMissionId,
    this.skills = const [],
    this.finale = false,
  });

  final String id;
  final int number;
  final String title;
  final String location;
  final List<String> story;
  final Artwork scene;
  final String letterIntro;
  final String letter;
  final MissionType type;
  final String question;

  /// Extra prompt shown with the question (e.g. "ROSETTA _____").
  final String? prompt;
  final List<ChoiceOption> options;

  /// Option id for choice missions, otherwise the expected text/code.
  final String answer;
  final List<String> acceptedAnswers;
  final int? codeLength;

  /// Final case only: the picture on each lock, left to right.
  final List<String> dialSymbols;

  /// Up to two hints, from gentle to direct.
  final List<String> hints;
  final Clue? clue;
  final Evidence? evidence;
  final String successMessage;

  /// Short story scene played after the mission is solved. On the final
  /// case: the post-case scene, before the case report.
  final List<String> transition;
  final String? nextMissionId;
  final List<Skill> skills;

  /// Pin position on the illustrated map, as fractions (0..1) of width/height.
  final double mapX;
  final double mapY;

  /// The episode's final case. Set by `Episode` for its `finalMission`, so a
  /// final case can use any puzzle type (Episode 01 uses the picture locks).
  final bool finale;

  bool get isFinal => finale || type == MissionType.finalCode;

  String get numberLabel => number.toString().padLeft(2, '0');

  /// Order of option ids for a [MissionType.sequence] answer.
  static List<String> sequenceIds(String answer) =>
      answer.isEmpty ? const [] : answer.split(',').map((s) => s.trim()).toList();

  String _optionLabel(String id) => options
      .firstWhere(
        (o) => o.id == id,
        orElse: () => ChoiceOption(id: id, label: id),
      )
      .label;

  /// The answer as a helper reads it (game master answer key).
  String get answerLabel => switch (type) {
    MissionType.multipleChoice || MissionType.imageChoice => _optionLabel(answer),
    MissionType.sequence => sequenceIds(answer).map(_optionLabel).join(' → '),
    _ => answer,
  };

  factory Mission.fromJson(Map<String, dynamic> json, {bool finale = false}) => Mission(
    finale: finale,
    id: json['id'] as String,
    number: json['number'] as int,
    title: json['title'] as String,
    location: json['location'] as String,
    story: (json['story'] as List).cast<String>(),
    scene: Artwork.fromJson(json['scene'] as String),
    letterIntro: json['letterIntro'] as String,
    letter: json['letter'] as String,
    type: MissionType.fromJson(json['type'] as String),
    question: json['question'] as String,
    prompt: json['prompt'] as String?,
    options: [for (final o in (json['options'] as List? ?? const [])) ChoiceOption.fromJson(o as Map<String, dynamic>)],
    answer: json['answer'] as String,
    acceptedAnswers: (json['acceptedAnswers'] as List? ?? const []).cast<String>(),
    codeLength: json['codeLength'] as int?,
    dialSymbols: (json['dialSymbols'] as List? ?? const []).cast<String>(),
    hints: (json['hints'] as List).cast<String>(),
    clue: json['clue'] == null ? null : Clue.fromJson(json['clue'] as Map<String, dynamic>),
    evidence: json['evidence'] == null ? null : Evidence.fromJson(json['evidence'] as Map<String, dynamic>),
    successMessage: json['successMessage'] as String,
    transition: (json['transition'] as List? ?? const []).cast<String>(),
    nextMissionId: json['nextMissionId'] as String?,
    skills: [for (final s in (json['skills'] as List? ?? const [])) Skill.fromJson(s as String)],
    mapX: (json['mapX'] as num).toDouble(),
    mapY: (json['mapY'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'title': title,
    'location': location,
    'story': story,
    'scene': scene.name,
    'letterIntro': letterIntro,
    'letter': letter,
    'type': type.name,
    'question': question,
    if (prompt != null) 'prompt': prompt,
    'options': [for (final o in options) o.toJson()],
    'answer': answer,
    'acceptedAnswers': acceptedAnswers,
    if (codeLength != null) 'codeLength': codeLength,
    if (dialSymbols.isNotEmpty) 'dialSymbols': dialSymbols,
    'hints': hints,
    if (clue != null) 'clue': clue!.toJson(),
    if (evidence != null) 'evidence': evidence!.toJson(),
    'successMessage': successMessage,
    if (transition.isNotEmpty) 'transition': transition,
    if (nextMissionId != null) 'nextMissionId': nextMissionId,
    'skills': [for (final s in skills) s.name],
    'mapX': mapX,
    'mapY': mapY,
  };
}
