/// The season content pipeline's intermediate models (STEP 3-2): what an AI
/// plans for a season before any of it becomes the game's Dart content.
///
/// Plans are never read by the game. They live under
/// `content_pipeline/seasons/<seasonId>/` as JSON; the game's own models
/// (`Season`, `Episode`, `Mission`, `SeasonContent`) stay as they are, and
/// a later step turns an approved plan into them.
///
/// Two layers of rules:
/// * **Format** — [SeasonPlan.fromJson] and [CasePlan.fromJson]: keys, types,
///   enums, id formats, counts. The same rules as the JSON Schemas in
///   `schema/`, rule for rule (`season_gen_schema_test` checks both reject
///   the same documents). Unknown keys are rejected.
/// * **Structure** — `PlanCheck`: how a plan's parts relate (a case's id and
///   number, its missions' order, its season's acts). What a JSON Schema
///   cannot say.
///
/// Not here: the palette fit (STEP 3-3, `PuzzleSelectionCheck`), the clue
/// graph (STEP 3-4, `ClueGraphCheck`), the approvals (STEP 3-5,
/// `SeasonApprovals`, kept beside the plans); not yet: the levels' words and
/// asset requests. A plan names what they will use (clue ids,
/// palette ids, asset ids) and, once written (STEP 3-8, optional), the
/// words the game shows (`play`) and its places' pictures (`places`):
/// whether they are all there is `PlayCheck`'s.
library;

import 'plan_ids.dart';

/// The plans' schema version: a plan of another version is rejected.
const planSchemaVersion = 1;

/// The cases a season plan has: three acts of four.
const plannedCasesPerSeason = 12;
const actsPerSeason = 3;
const casesPerAct = 4;

/// The missions a case has before its final. The game sets no bound; London
/// Case 01 has five, every other London and Paris case three.
const minMissionsPerCase = 1;
const maxMissionsPerCase = 5;

/// Words the game's own enums are written with (plans hold them as text).
/// `season_gen_schema_test` keeps them equal to the game's enums.
abstract final class PlanVocabulary {
  /// `MissionType` (lib/data/models/mission.dart).
  static const missionTypes = [
    'multipleChoice',
    'wordInput',
    'numberCode',
    'imageChoice',
    'examine',
    'finalCode',
    'sequence',
    'letterLock',
    'spotDifferences',
    'matchPairs',
    'revealLayer',
    'canvasChoice',
  ];

  /// `LanguageDependency` (lib/data/models/learning.dart).
  static const dependencies = ['essential', 'helpful', 'exposure', 'low'];

  /// `LearningLevel`.
  static const learningLevels = ['exposure', 'comprehension', 'application', 'recall'];

  /// `LanguageSkill`.
  static const skills = ['vocabulary', 'sentenceMeaning', 'grammarInContext'];

  /// `Mission.codeFormat`: the formats the game reads.
  static const codeFormats = ['time'];
}

/// A plan that does not keep the format: where ([path], as `$.acts[0]`) and why.
class PlanFormatException implements Exception {
  const PlanFormatException(this.path, this.message);

  final String path;
  final String message;

  @override
  String toString() => 'PlanFormatException: $path: $message';
}

/// The page a puzzle is played on (`PuzzleSurface` of the palette).
enum PlanSurface { mission, finalMission }

/// Whether a puzzle can be made now.
enum PuzzleStatus {
  /// Its engine is in the palette and it needs no picture to be made.
  ready,

  /// Its engine is in the palette; its pictures are still to be made.
  awaitingAssets,

  /// No engine plays it yet: a development request, never generated.
  devRequest,
}

/// How a mission uses a clue it is given (STEP 3-1 §5.2). Only ways the game
/// can play today. Every use asks for a clue found before (`ClueGraphCheck`).
enum ClueUse {
  /// The answer is worked out from the clue's value.
  answerDerivation,

  /// The evidence is shown in a talk (`TalkScene`).
  talkPresent,

  /// The evidence is matched to this one (`SeasonContent.evidenceLinks`).
  evidenceLink,

  /// The evidence is brought from the notebook (`Mission.recall`): a help only.
  recall,

  /// The English of an earlier mission is read again (`LearningObjective.recallFrom`).
  learningRecall,

  /// The story only mentions it.
  textMention,
}

// ── Reading ──────────────────────────────────────────────────────────────

/// Reads one JSON object at [path], key by key; [done] rejects any key not read.
class _Reader {
  _Reader(Object? json, this.path) : _map = _object(json, path);

  static Map<String, Object?> _object(Object? json, String path) {
    if (json is! Map) throw PlanFormatException(path, 'not an object');
    return {for (final e in json.entries) '${e.key}': e.value};
  }

  final String path;
  final Map<String, Object?> _map;
  final _read = <String>{};

  String _at(String key) => '$path.$key';

  Never _fail(String key, String message) => throw PlanFormatException(_at(key), message);

  Object? _required(String key) {
    _read.add(key);
    if (!_map.containsKey(key)) _fail(key, 'missing');
    return _map[key];
  }

  bool _has(String key) {
    _read.add(key);
    return _map.containsKey(key);
  }

  static String _text(Object? v, String at, RegExp? pattern, List<String>? oneOf) {
    if (v is! String) throw PlanFormatException(at, 'not text');
    if (v.isEmpty) throw PlanFormatException(at, 'empty');
    if (pattern != null && !pattern.hasMatch(v)) throw PlanFormatException(at, '"$v" is not of the form ${pattern.pattern}');
    if (oneOf != null && !oneOf.contains(v)) throw PlanFormatException(at, '"$v" is not one of ${oneOf.join(', ')}');
    return v;
  }

  String str(String key, {RegExp? pattern, List<String>? oneOf}) => _text(_required(key), _at(key), pattern, oneOf);

  String? optStr(String key, {RegExp? pattern, List<String>? oneOf}) =>
      _has(key) ? _text(_map[key], _at(key), pattern, oneOf) : null;

  /// A key that must be there, its value text or null.
  String? nullableStr(String key, {RegExp? pattern}) {
    final v = _required(key);
    return v == null ? null : _text(v, _at(key), pattern, null);
  }

  int integer(String key, {int? min, int? max, int? only}) => _int(_required(key), _at(key), min: min, max: max, only: only);

  int? optInt(String key, {int? min}) => _has(key) ? _int(_map[key], _at(key), min: min) : null;

  double? optNum(String key, {double? min, double? max}) {
    if (!_has(key)) return null;
    final v = _map[key];
    if (v is! num) _fail(key, 'not a number');
    if (min != null && v < min) _fail(key, '$v is under $min');
    if (max != null && v > max) _fail(key, '$v is over $max');
    return v.toDouble();
  }

  bool? optBool(String key) {
    if (!_has(key)) return null;
    final v = _map[key];
    if (v is! bool) _fail(key, 'not true or false');
    return v;
  }

  /// An optional object of text by text: empty when not given.
  Map<String, String> optTextMap(String key) {
    if (!_has(key)) return const {};
    final at = _at(key);
    return {for (final e in _object(_map[key], at).entries) e.key: _text(e.value, '$at.${e.key}', null, null)};
  }

  static int _int(Object? json, String at, {int? min, int? max, int? only}) {
    // As JSON Schema reads it: 2.0 is the whole number 2.
    final v = json is double && json == json.truncateToDouble() && json.isFinite ? json.toInt() : json;
    if (v is! int) throw PlanFormatException(at, 'not a whole number');
    if (only != null && v != only) throw PlanFormatException(at, '$v, not $only');
    if (min != null && v < min) throw PlanFormatException(at, '$v is under $min');
    if (max != null && v > max) throw PlanFormatException(at, '$v is over $max');
    return v;
  }

  E enumOf<E extends Enum>(String key, List<E> values) {
    final name = str(key);
    for (final v in values) {
      if (v.name == name) return v;
    }
    _fail(key, '"$name" is not one of ${values.map((v) => v.name).join(', ')}');
  }

  List<Object?> _list(Object? v, String at, int? min, int? max) {
    if (v is! List) throw PlanFormatException(at, 'not a list');
    if (min != null && v.length < min) throw PlanFormatException(at, '${v.length} items, at least $min');
    if (max != null && v.length > max) throw PlanFormatException(at, '${v.length} items, at most $max');
    return v;
  }

  List<String> _strings(Object? v, String at, {int? min, int? max, RegExp? pattern, bool unique = false}) {
    final list = _list(v, at, min, max);
    final out = [for (final (i, x) in list.indexed) _text(x, '$at[$i]', pattern, null)];
    if (unique && out.toSet().length != out.length) throw PlanFormatException(at, 'an item given twice');
    return out;
  }

  List<String> strings(String key, {int? min, int? max, RegExp? pattern, bool unique = false}) =>
      _strings(_required(key), _at(key), min: min, max: max, pattern: pattern, unique: unique);

  /// An optional list: empty when not given.
  List<String> optStrings(String key, {RegExp? pattern, bool unique = false}) =>
      _has(key) ? _strings(_map[key], _at(key), pattern: pattern, unique: unique) : const [];

  T obj<T>(String key, T Function(Object? json, String path) parse) => parse(_required(key), _at(key));

  T? optObj<T>(String key, T Function(Object? json, String path) parse) => _has(key) ? parse(_map[key], _at(key)) : null;

  List<T> objs<T>(String key, T Function(Object? json, String path) parse, {int? min, int? max}) {
    final at = _at(key);
    return [for (final (i, x) in _list(_required(key), at, min, max).indexed) parse(x, '$at[$i]')];
  }

  List<T> optObjs<T>(String key, T Function(Object? json, String path) parse) {
    if (!_has(key)) return const [];
    final at = _at(key);
    return [for (final (i, x) in _list(_map[key], at, null, null).indexed) parse(x, '$at[$i]')];
  }

  /// Rejects the keys no one asked for.
  void done() {
    final unknown = _map.keys.where((k) => !_read.contains(k)).toList();
    if (unknown.isNotEmpty) throw PlanFormatException(_at(unknown.first), 'not a field of this plan');
  }
}

/// Lays an optional list into [json] only when it has something.
void _putList(Map<String, Object?> json, String key, List<Object?> list) {
  if (list.isNotEmpty) json[key] = list;
}

void _putText(Map<String, Object?> json, String key, String? value) {
  if (value != null) json[key] = value;
}

void _putMap(Map<String, Object?> json, String key, Map<String, Object?> map) {
  if (map.isNotEmpty) json[key] = map;
}

void _version(_Reader r) {
  final v = r.integer('schemaVersion');
  if (v != planSchemaVersion) r._fail('schemaVersion', 'version $v is not supported (this tool reads version $planSchemaVersion)');
}

// ── SeasonPlan ───────────────────────────────────────────────────────────

/// The truth behind the whole season, for the writers (never shown as is).
class MainMystery {
  const MainMystery({required this.truth, required this.culprit, required this.motive, required this.revealCase});

  final String truth;
  final String culprit;
  final String motive;

  /// The case that shows it (a case id of the season).
  final String revealCase;

  factory MainMystery.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = MainMystery(
      truth: r.str('truth'),
      culprit: r.str('culprit'),
      motive: r.str('motive'),
      revealCase: r.str('revealCase', pattern: PlanIds.caseId),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {'truth': truth, 'culprit': culprit, 'motive': motive, 'revealCase': revealCase};
}

/// Someone of the season's story.
class CharacterPlan {
  const CharacterPlan({
    required this.charId,
    required this.name,
    required this.role,
    required this.firstCase,
    this.revealCase,
    this.secretUntil,
  });

  /// Its id in the season plan (`emile`).
  final String charId;
  final String name;

  /// What the story says they are.
  final String role;

  /// The case they first appear in.
  final String firstCase;

  /// The case their true part is shown in; null: they have none to show.
  final String? revealCase;

  /// The case before which something of theirs (a name, a face) is never
  /// told; null: nothing is kept back.
  final String? secretUntil;

  factory CharacterPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = CharacterPlan(
      charId: r.str('charId', pattern: PlanIds.local),
      name: r.str('name'),
      role: r.str('role'),
      firstCase: r.str('firstCase', pattern: PlanIds.caseId),
      revealCase: r.optStr('revealCase', pattern: PlanIds.caseId),
      secretUntil: r.optStr('secretUntil', pattern: PlanIds.caseId),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'charId': charId, 'name': name, 'role': role, 'firstCase': firstCase};
    _putText(json, 'revealCase', revealCase);
    _putText(json, 'secretUntil', secretUntil);
    return json;
  }
}

/// A place of the season's map.
class LocationPlan {
  const LocationPlan({required this.locId, required this.name, required this.landmarkKey});

  final String locId;
  final String name;

  /// The map landmark it is drawn as (the name of its `MapLandmark` value).
  final String landmarkKey;

  factory LocationPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = LocationPlan(
      locId: r.str('locId', pattern: PlanIds.local),
      name: r.str('name'),
      landmarkKey: r.str('landmarkKey', pattern: PlanIds.landmark),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {'locId': locId, 'name': name, 'landmarkKey': landmarkKey};
}

/// One act: its theme and its four cases, in order.
class ActPlan {
  const ActPlan({required this.actId, required this.theme, required this.caseIds});

  final String actId;
  final String theme;
  final List<String> caseIds;

  factory ActPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = ActPlan(
      actId: r.str('actId', pattern: PlanIds.act),
      theme: r.str('theme'),
      caseIds: r.strings('caseIds', min: casesPerAct, max: casesPerAct, pattern: PlanIds.caseId, unique: true),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {'actId': actId, 'theme': theme, 'caseIds': caseIds};
}

/// Who is revealed on the season board, after which case (`SeasonFigure`).
class FigurePlan {
  const FigurePlan({required this.after, required this.figure, required this.label});

  final String after;
  final String figure;
  final String label;

  factory FigurePlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = FigurePlan(
      after: r.str('after', pattern: PlanIds.caseId),
      figure: r.str('figure'),
      label: r.str('label'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {'after': after, 'figure': figure, 'label': label};
}

/// The season's opening, in the keys of the game's `SeasonPrologue` JSON.
class ProloguePlan {
  const ProloguePlan({
    this.city,
    this.cases = const [],
    this.separate = const [],
    this.question,
    this.bigger,
    this.promise = const [],
    this.firstCase,
  });

  final String? city;
  final List<String> cases;
  final List<String> separate;
  final String? question;
  final String? bigger;
  final List<String> promise;
  final ({String picture, String line})? firstCase;

  factory ProloguePlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = ProloguePlan(
      city: r.optStr('city'),
      cases: r.optStrings('cases'),
      separate: r.optStrings('separate'),
      question: r.optStr('question'),
      bigger: r.optStr('bigger'),
      promise: r.optStrings('promise'),
      firstCase: r.optObj('firstCase', (json, path) {
        final f = _Reader(json, path);
        final out = (picture: f.str('picture'), line: f.str('line'));
        f.done();
        return out;
      }),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{};
    _putText(json, 'city', city);
    _putList(json, 'cases', cases);
    _putList(json, 'separate', separate);
    _putText(json, 'question', question);
    _putText(json, 'bigger', bigger);
    _putList(json, 'promise', promise);
    if (firstCase case final f?) json['firstCase'] = {'picture': f.picture, 'line': f.line};
    return json;
  }
}

/// A season place's picture (the game's `ScenePlace`): a mission names it
/// by its [placeId] (`Mission.sceneKey`). Its pixel size is the file's.
class PlacePlan {
  const PlacePlan({required this.placeId, required this.file, required this.width, required this.height});

  final String placeId;

  /// The bundled asset, from the repository's root (`assets/…`).
  final String file;
  final int width;
  final int height;

  factory PlacePlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = r.obj('pixels', (json, path) {
      final p = _Reader(json, path);
      final size = (p.integer('width', min: 1), p.integer('height', min: 1));
      p.done();
      return size;
    });
    final place = PlacePlan(
      placeId: r.str('placeId', pattern: PlanIds.place),
      file: r.str('file', pattern: PlanIds.assetFile),
      width: out.$1,
      height: out.$2,
    );
    r.done();
    return place;
  }

  Map<String, Object?> toJson() => {
    'placeId': placeId,
    'file': file,
    'pixels': {'width': width, 'height': height},
  };
}

/// A whole season, planned: its mystery, people, places and acts.
///
/// The game's `Season` reads every field but its number and title
/// tolerantly (a missing one is empty). The plan asks for more at once (the
/// mystery, acts, people, places) and leaves the words the season says
/// ([prologue], [outro], [finale], [figures]) optional while it is planned:
/// they are required by the Dart generation step (STEP 3-6: [outro] and
/// [finale] written, [figures] given), and [prologue] once a new season
/// has an opening page of its own (STEP 3-10).
class SeasonPlan {
  const SeasonPlan({
    required this.seasonId,
    required this.number,
    required this.city,
    required this.title,
    required this.tagline,
    required this.mainMystery,
    required this.characters,
    required this.locations,
    required this.acts,
    this.plannedCases = plannedCasesPerSeason,
    this.prologue,
    this.outro = const [],
    this.finale = const [],
    this.figures = const [],
    this.languageArc = const [],
    this.places = const [],
    this.storyGreeting,
    this.notes = const [],
  });

  final String seasonId;
  final int number;
  final String city;
  final String title;
  final String tagline;
  final int plannedCases;
  final MainMystery mainMystery;
  final List<CharacterPlan> characters;
  final List<LocationPlan> locations;
  final List<ActPlan> acts;
  final ProloguePlan? prologue;
  final List<String> outro;
  final List<String> finale;
  final List<FigurePlan> figures;

  /// The season's English, act by act (a line each, for the writers).
  final List<String> languageArc;

  /// The pictures of the places its missions happen at (`SeasonContent.places`):
  /// needed once a case is made into the game's content (`PlayCheck`).
  final List<PlacePlan> places;

  /// `SeasonContent.storyGreeting` as written (null: not given, the game's
  /// own true).
  final bool? storyGreeting;

  /// Anything the writers or a reviewer should know (never content).
  final List<String> notes;

  /// Every case id of the acts, in order.
  List<String> get caseIds => [for (final a in acts) ...a.caseIds];

  factory SeasonPlan.fromJson(Object? json, {String path = r'$'}) {
    final r = _Reader(json, path);
    _version(r);
    final out = SeasonPlan(
      seasonId: r.str('seasonId', pattern: PlanIds.season),
      number: r.integer('number', min: 1),
      city: r.str('city'),
      title: r.str('title'),
      tagline: r.str('tagline'),
      plannedCases: r.integer('plannedCases', only: plannedCasesPerSeason),
      mainMystery: r.obj('mainMystery', MainMystery.fromJson),
      characters: r.objs('characters', CharacterPlan.fromJson, min: 1),
      locations: r.objs('locations', LocationPlan.fromJson, min: 1),
      acts: r.objs('acts', ActPlan.fromJson, min: actsPerSeason, max: actsPerSeason),
      prologue: r.optObj('prologue', ProloguePlan.fromJson),
      outro: r.optStrings('outro'),
      finale: r.optStrings('finale'),
      figures: r.optObjs('figures', FigurePlan.fromJson),
      languageArc: r.optStrings('languageArc'),
      places: r.optObjs('places', PlacePlan.fromJson),
      storyGreeting: r.optBool('storyGreeting'),
      notes: r.optStrings('notes'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'schemaVersion': planSchemaVersion,
      'seasonId': seasonId,
      'number': number,
      'city': city,
      'title': title,
      'tagline': tagline,
      'plannedCases': plannedCases,
      'mainMystery': mainMystery.toJson(),
      'characters': [for (final c in characters) c.toJson()],
      'locations': [for (final l in locations) l.toJson()],
      'acts': [for (final a in acts) a.toJson()],
    };
    if (prologue case final p?) json['prologue'] = p.toJson();
    _putList(json, 'outro', outro);
    _putList(json, 'finale', finale);
    _putList(json, 'figures', [for (final f in figures) f.toJson()]);
    _putList(json, 'languageArc', languageArc);
    _putList(json, 'places', [for (final p in places) p.toJson()]);
    if (storyGreeting != null) json['storyGreeting'] = storyGreeting;
    _putList(json, 'notes', notes);
    return json;
  }
}

// ── CasePlan ─────────────────────────────────────────────────────────────

/// A case's words as the game shows them (`Episode`, its keys): written
/// into the plan, never made up by the generator. Every field is optional
/// while the case is planned; `PlayCheck` asks for what the game needs.
class CasePlayPlan {
  const CasePlayPlan({
    this.objectives = const [],
    this.intro = const [],
    this.caseSummary,
    this.place,
    this.keyWords = const [],
    this.glossary = const {},
  });

  /// The case file's briefing; the plan's `goal` when empty.
  final List<String> objectives;

  /// The Story Intro's lines.
  final List<String> intro;

  /// The Case Solved report's line (the game's London line when missing).
  final String? caseSummary;
  final String? place;
  final List<String> keyWords;

  /// A word (lower case) → its meaning.
  final Map<String, String> glossary;

  factory CasePlayPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = CasePlayPlan(
      objectives: r.optStrings('objectives'),
      intro: r.optStrings('intro'),
      caseSummary: r.optStr('caseSummary'),
      place: r.optStr('place'),
      keyWords: r.optStrings('keyWords'),
      glossary: r.optTextMap('glossary'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{};
    _putList(json, 'objectives', objectives);
    _putList(json, 'intro', intro);
    _putText(json, 'caseSummary', caseSummary);
    _putText(json, 'place', place);
    _putList(json, 'keyWords', keyWords);
    _putMap(json, 'glossary', glossary);
    return json;
  }
}

/// A case's language topic (the game's `CaseLanguageTopic`).
class LearningGoal {
  const LearningGoal({required this.title, required this.titleKo});

  final String title;
  final String titleKo;

  factory LearningGoal.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = LearningGoal(title: r.str('title'), titleKo: r.str('titleKo'));
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {'title': title, 'titleKo': titleKo};
}

/// One case, planned: its story, its missions in order and its final.
class CasePlan {
  const CasePlan({
    required this.caseId,
    required this.seasonId,
    required this.number,
    required this.actId,
    required this.title,
    required this.synopsis,
    required this.goal,
    required this.characters,
    required this.locations,
    required this.missions,
    required this.finalMission,
    required this.hook,
    required this.learningGoal,
    this.play,
    this.notes = const [],
  });

  final String caseId;
  final String seasonId;
  final int number;
  final String actId;
  final String title;

  /// The case file's lines (`Episode.synopsis`).
  final List<String> synopsis;

  /// What the detective sets out to find (for the writers).
  final String goal;

  /// Its people and places: ids of its season plan.
  final List<String> characters;
  final List<String> locations;

  /// Its missions before the final, in play order (`m1`, `m2`…).
  final List<MissionPlan> missions;

  /// Its final (JSON key `final`).
  final MissionPlan finalMission;

  /// What it leaves unanswered (`Episode.hook`).
  final String hook;
  final LearningGoal learningGoal;

  /// Its words as the game shows them; null while only its structure is planned.
  final CasePlayPlan? play;
  final List<String> notes;

  /// Its missions and its final, in play order.
  List<MissionPlan> get allMissions => [...missions, finalMission];

  factory CasePlan.fromJson(Object? json, {String path = r'$'}) {
    final r = _Reader(json, path);
    _version(r);
    final out = CasePlan(
      caseId: r.str('caseId', pattern: PlanIds.caseId),
      seasonId: r.str('seasonId', pattern: PlanIds.season),
      number: r.integer('number', min: 1, max: plannedCasesPerSeason),
      actId: r.str('actId', pattern: PlanIds.act),
      title: r.str('title'),
      synopsis: r.strings('synopsis', min: 1),
      goal: r.str('goal'),
      characters: r.strings('characters', pattern: PlanIds.local, unique: true),
      locations: r.strings('locations', min: 1, pattern: PlanIds.local, unique: true),
      missions: r.objs('missions', MissionPlan.fromJson, min: minMissionsPerCase, max: maxMissionsPerCase),
      finalMission: r.obj('final', MissionPlan.fromJson),
      hook: r.str('hook'),
      learningGoal: r.obj('learningGoal', LearningGoal.fromJson),
      play: r.optObj('play', CasePlayPlan.fromJson),
      notes: r.optStrings('notes'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'schemaVersion': planSchemaVersion,
      'caseId': caseId,
      'seasonId': seasonId,
      'number': number,
      'actId': actId,
      'title': title,
      'synopsis': synopsis,
      'goal': goal,
      'characters': characters,
      'locations': locations,
      'missions': [for (final m in missions) m.toJson()],
      'final': finalMission.toJson(),
      'hook': hook,
      'learningGoal': learningGoal.toJson(),
    };
    if (play case final p?) json['play'] = p.toJson();
    _putList(json, 'notes', notes);
    return json;
  }
}

// ── MissionPlan ──────────────────────────────────────────────────────────

/// A clue a mission is given: what it names, and how it is used.
class ClueInput {
  const ClueInput({required this.ref, required this.use, this.note});

  /// A clue, evidence or fact id (of this case or an earlier one).
  final String ref;
  final ClueUse use;
  final String? note;

  factory ClueInput.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = ClueInput(
      ref: r.str('ref', pattern: PlanIds.clueRef),
      use: r.enumOf('use', ClueUse.values),
      note: r.optStr('note'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'ref': ref, 'use': use.name};
    _putText(json, 'note', note);
    return json;
  }
}

/// What a mission leaves the detective: its notebook clue (`Mission.clue`),
/// its evidence (`Mission.evidence`) and the story facts it shows.
class ClueOutputs {
  const ClueOutputs({required this.evidence, this.clue, this.facts = const []});

  final String? clue;
  final String evidence;
  final List<String> facts;

  factory ClueOutputs.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = ClueOutputs(
      clue: r.optStr('clue', pattern: PlanIds.clue),
      evidence: r.str('evidence', pattern: PlanIds.evidence),
      facts: r.optStrings('facts', pattern: PlanIds.fact, unique: true),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{};
    _putText(json, 'clue', clue);
    json['evidence'] = evidence;
    _putList(json, 'facts', facts);
    return json;
  }
}

/// What a mission is designed to do with English: the game's
/// `LearningObjective`, field for field (its enums by name).
class LearningPlan {
  const LearningPlan({
    required this.dependency,
    required this.level,
    required this.objective,
    this.skill,
    this.expressions = const [],
    this.recallFrom,
  });

  final String dependency;
  final String level;

  /// One sentence for the parent report, in Korean.
  final String objective;
  final String? skill;
  final List<String> expressions;

  /// The earlier mission whose English is read again.
  final String? recallFrom;

  factory LearningPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = LearningPlan(
      dependency: r.str('dependency', oneOf: PlanVocabulary.dependencies),
      level: r.str('level', oneOf: PlanVocabulary.learningLevels),
      objective: r.str('objective'),
      skill: r.optStr('skill', oneOf: PlanVocabulary.skills),
      expressions: r.optStrings('expressions'),
      recallFrom: r.optStr('recallFrom', pattern: PlanIds.mission),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'dependency': dependency, 'level': level, 'objective': objective};
    _putText(json, 'skill', skill);
    _putList(json, 'expressions', expressions);
    _putText(json, 'recallFrom', recallFrom);
    return json;
  }
}

/// The notebook clue's words (`Clue`, its id the mission's `clueOutputs.clue`).
class ClueText {
  const ClueText({required this.title, required this.value, required this.note, this.symbol});

  final String title;
  final String value;
  final String note;

  /// A `GameSymbol` key.
  final String? symbol;

  factory ClueText.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = ClueText(title: r.str('title'), value: r.str('value'), note: r.str('note'), symbol: r.optStr('symbol'));
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'title': title, 'value': value, 'note': note};
    _putText(json, 'symbol', symbol);
    return json;
  }
}

/// The evidence's words (`Evidence`, its id the mission's `clueOutputs.evidence`).
class EvidenceText {
  const EvidenceText({required this.name, required this.icon, required this.description, this.inscription, this.symbols = const []});

  final String name;

  /// A `GameSymbol` key.
  final String icon;
  final String description;
  final String? inscription;

  /// `GameSymbol` keys.
  final List<String> symbols;

  factory EvidenceText.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = EvidenceText(
      name: r.str('name'),
      icon: r.str('icon'),
      description: r.str('description'),
      inscription: r.optStr('inscription'),
      symbols: r.optStrings('symbols'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'name': name, 'icon': icon, 'description': description};
    _putText(json, 'inscription', inscription);
    _putList(json, 'symbols', symbols);
    return json;
  }
}

/// The words of a recall card (`EvidenceRecall`, its evidence the mission's
/// one `recall` clue input).
class RecallText {
  const RecallText({this.title, this.prompt, this.feedback = const {}, this.miss});

  final String? title;
  final String? prompt;

  /// Evidence id → a line for it picked instead.
  final Map<String, String> feedback;
  final String? miss;

  factory RecallText.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = RecallText(title: r.optStr('title'), prompt: r.optStr('prompt'), feedback: r.optTextMap('feedback'), miss: r.optStr('miss'));
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{};
    _putText(json, 'title', title);
    _putText(json, 'prompt', prompt);
    _putMap(json, 'feedback', feedback);
    _putText(json, 'miss', miss);
    return json;
  }
}

/// A mission's words as the game shows them (`Mission`, its keys). What the
/// plan already holds (its id, order, place, type, answer, options) is not
/// repeated here. Every field is optional while the mission is planned;
/// `PlayCheck` asks for what the game needs.
class MissionPlayPlan {
  const MissionPlayPlan({
    this.title,
    this.location,
    this.story = const [],
    this.letterIntro,
    this.letter,
    this.question,
    this.prompt,
    this.hints = const [],
    this.successMessage,
    this.transition = const [],
    this.feedback = const {},
    this.orderFeedback,
    this.mapX,
    this.mapY,
    this.clue,
    this.evidence,
    this.recall,
    this.evidenceLinkLine,
    this.lockTitle,
  });

  final String? title;
  final String? location;
  final List<String> story;
  final String? letterIntro;
  final String? letter;
  final String? question;
  final String? prompt;
  final List<String> hints;
  final String? successMessage;

  /// The scene after the answer (a final's: the scene after the case).
  final List<String> transition;

  /// A wrong typed answer → its line (typed and ordered puzzles; a choice's
  /// lines are its options').
  final Map<String, String> feedback;
  final String? orderFeedback;

  /// The map pin, as fractions of the map (0..1).
  final double? mapX;
  final double? mapY;
  final ClueText? clue;
  final EvidenceText? evidence;
  final RecallText? recall;

  /// How this mission's evidence matches the one its `evidenceLink` input names.
  final String? evidenceLinkLine;

  /// A letter lock's name on its plate (`Mission.lockTitle`); the game's
  /// plain "THE LOCK" when not given.
  final String? lockTitle;

  factory MissionPlayPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = MissionPlayPlan(
      title: r.optStr('title'),
      location: r.optStr('location'),
      story: r.optStrings('story'),
      letterIntro: r.optStr('letterIntro'),
      letter: r.optStr('letter'),
      question: r.optStr('question'),
      prompt: r.optStr('prompt'),
      hints: r.optStrings('hints'),
      successMessage: r.optStr('successMessage'),
      transition: r.optStrings('transition'),
      feedback: r.optTextMap('feedback'),
      orderFeedback: r.optStr('orderFeedback'),
      mapX: r.optNum('mapX', min: 0, max: 1),
      mapY: r.optNum('mapY', min: 0, max: 1),
      clue: r.optObj('clue', ClueText.fromJson),
      evidence: r.optObj('evidence', EvidenceText.fromJson),
      recall: r.optObj('recall', RecallText.fromJson),
      evidenceLinkLine: r.optStr('evidenceLinkLine'),
      lockTitle: r.optStr('lockTitle'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{};
    _putText(json, 'title', title);
    _putText(json, 'location', location);
    _putList(json, 'story', story);
    _putText(json, 'letterIntro', letterIntro);
    _putText(json, 'letter', letter);
    _putText(json, 'question', question);
    _putText(json, 'prompt', prompt);
    _putList(json, 'hints', hints);
    _putText(json, 'successMessage', successMessage);
    _putList(json, 'transition', transition);
    _putMap(json, 'feedback', feedback);
    _putText(json, 'orderFeedback', orderFeedback);
    if (mapX != null) json['mapX'] = mapX;
    if (mapY != null) json['mapY'] = mapY;
    if (clue case final c?) json['clue'] = c.toJson();
    if (evidence case final e?) json['evidence'] = e.toJson();
    if (recall case final r?) json['recall'] = r.toJson();
    _putText(json, 'evidenceLinkLine', evidenceLinkLine);
    _putText(json, 'lockTitle', lockTitle);
    return json;
  }
}

/// One mission or final, planned.
class MissionPlan {
  const MissionPlan({
    required this.missionId,
    required this.slot,
    required this.placeId,
    required this.puzzle,
    required this.clueInputs,
    required this.clueOutputs,
    required this.learning,
    this.play,
    this.notes = const [],
  });

  /// `<case>_m<n>` or `<case>_final`.
  final String missionId;

  /// `m1`…, or `final`.
  final String slot;

  /// The season place it happens at (`ScenePlace`, by its id).
  final String placeId;
  final PuzzlePlan puzzle;
  final List<ClueInput> clueInputs;
  final ClueOutputs clueOutputs;
  final LearningPlan learning;

  /// Its words as the game shows them; null while only its structure is planned.
  final MissionPlayPlan? play;
  final List<String> notes;

  bool get isFinal => slot == 'final';

  factory MissionPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = MissionPlan(
      missionId: r.str('missionId', pattern: PlanIds.mission),
      slot: r.str('slot', pattern: PlanIds.slot),
      placeId: r.str('placeId', pattern: PlanIds.place),
      puzzle: r.obj('puzzle', PuzzlePlan.fromJson),
      clueInputs: r.objs('clueInputs', ClueInput.fromJson),
      clueOutputs: r.obj('clueOutputs', ClueOutputs.fromJson),
      learning: r.obj('learning', LearningPlan.fromJson),
      play: r.optObj('play', MissionPlayPlan.fromJson),
      notes: r.optStrings('notes'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'missionId': missionId,
      'slot': slot,
      'placeId': placeId,
      'puzzle': puzzle.toJson(),
      'clueInputs': [for (final c in clueInputs) c.toJson()],
      'clueOutputs': clueOutputs.toJson(),
      'learning': learning.toJson(),
    };
    if (play case final p?) json['play'] = p.toJson();
    _putList(json, 'notes', notes);
    return json;
  }
}

// ── PuzzlePlan ───────────────────────────────────────────────────────────

/// A choice of a puzzle (`ChoiceOption`, without its `Artwork`: a new
/// season's pictures are its own files).
class OptionPlan {
  const OptionPlan({required this.id, required this.label, this.feedback, this.altText});

  final String id;
  final String label;
  final String? feedback;
  final String? altText;

  factory OptionPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = OptionPlan(
      id: r.str('id'),
      label: r.str('label'),
      feedback: r.optStr('feedback'),
      altText: r.optStr('altText'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'id': id, 'label': label};
    _putText(json, 'feedback', feedback);
    _putText(json, 'altText', altText);
    return json;
  }
}

/// A puzzle's answer, in the `Mission` fields the palette's puzzles are
/// written with (`PuzzleDefinition.requiredData`). Only [answer] is common
/// to every puzzle; which others a puzzle needs is the palette's to say
/// (STEP 3-3).
class AnswerSpec {
  const AnswerSpec({
    required this.answer,
    this.acceptedAnswers = const [],
    this.options = const [],
    this.codeLength,
    this.codeFormat,
    this.dialSymbols = const [],
  });

  /// As `Mission.answer` holds it (an option id, a word, a code, ids joined
  /// by commas, `note:picture` pairs).
  final String answer;
  final List<String> acceptedAnswers;
  final List<OptionPlan> options;
  final int? codeLength;
  final String? codeFormat;
  final List<String> dialSymbols;

  factory AnswerSpec.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = AnswerSpec(
      answer: r.str('answer'),
      acceptedAnswers: r.optStrings('acceptedAnswers'),
      options: r.optObjs('options', OptionPlan.fromJson),
      codeLength: r.optInt('codeLength', min: 1),
      codeFormat: r.optStr('codeFormat', oneOf: PlanVocabulary.codeFormats),
      dialSymbols: r.optStrings('dialSymbols'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'answer': answer};
    _putList(json, 'acceptedAnswers', acceptedAnswers);
    _putList(json, 'options', [for (final o in options) o.toJson()]);
    if (codeLength != null) json['codeLength'] = codeLength;
    _putText(json, 'codeFormat', codeFormat);
    _putList(json, 'dialSymbols', dialSymbols);
    return json;
  }
}

/// The puzzle a mission is played with, tied to the engine that plays it.
class PuzzlePlan {
  const PuzzlePlan({
    required this.paletteId,
    required this.surface,
    required this.engineTable,
    required this.missionType,
    required this.answerSpec,
    required this.assetNeeds,
    required this.status,
    this.devNote,
    this.notes = const [],
  });

  /// Its `PuzzlePalette` id; null only for a [PuzzleStatus.devRequest] (an
  /// engine the palette has not).
  final String? paletteId;
  final PlanSurface surface;

  /// The `SeasonContent` table its engine reads (a binding's `table`); null:
  /// played from its [missionType] alone.
  final String? engineTable;

  /// Its `MissionType`, by name.
  final String missionType;
  final AnswerSpec answerSpec;

  /// The pictures it needs beyond its place's (asset ids).
  final List<String> assetNeeds;
  final PuzzleStatus status;

  /// What is to be developed, for a [PuzzleStatus.devRequest].
  final String? devNote;
  final List<String> notes;

  factory PuzzlePlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = PuzzlePlan(
      paletteId: r.nullableStr('paletteId', pattern: PlanIds.palette),
      surface: r.enumOf('surface', PlanSurface.values),
      engineTable: r.nullableStr('engineTable', pattern: PlanIds.table),
      missionType: r.str('missionType', oneOf: PlanVocabulary.missionTypes),
      answerSpec: r.obj('answerSpec', AnswerSpec.fromJson),
      assetNeeds: r.strings('assetNeeds', pattern: PlanIds.asset, unique: true),
      status: r.enumOf('status', PuzzleStatus.values),
      devNote: r.optStr('devNote'),
      notes: r.optStrings('notes'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'paletteId': paletteId,
      'surface': surface.name,
      'engineTable': engineTable,
      'missionType': missionType,
      'answerSpec': answerSpec.toJson(),
      'assetNeeds': assetNeeds,
      'status': status.name,
    };
    _putText(json, 'devNote', devNote);
    _putList(json, 'notes', notes);
    return json;
  }
}
