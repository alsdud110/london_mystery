import '../mock/season_catalog.dart';
import '../models/case_talk.dart';
import '../models/episode.dart';
import '../models/mission.dart';
import 'puzzle_palette.dart';
import 'season_content_validator.dart' show ContentIssue;

/// What a step of a page's engine choice looks at.
enum EngineStepKind {
  /// An entry of a season table for the mission.
  table,

  /// The talk before the puzzle (`TalkMission.before`), still to be had:
  /// it comes first, then the steps after it are looked at again.
  talkBefore,

  /// The mission's own type.
  type,
}

/// One step of a page's engine choice, in the order the page looks.
class EngineStep {
  const EngineStep(String this.table, this.engine)
    : kind = EngineStepKind.table,
      type = null;
  const EngineStep.talkBefore()
    : table = 'talkMissions',
      engine = 'CaseTalk (before)',
      kind = EngineStepKind.talkBefore,
      type = null;
  const EngineStep.type(MissionType this.type, this.engine)
    : table = null,
      kind = EngineStepKind.type;

  final EngineStepKind kind;

  /// The `SeasonContent.missionTables` table looked in.
  final String? table;
  final MissionType? type;

  /// The widget played when this step is taken.
  final String engine;
}

/// How the mission and final pages choose a mission's engine, as their
/// code does it (`MissionScreen.build`, `FinalMissionScreen.build` and
/// `_puzzle`): the first step that holds wins, every later one is never
/// reached. Kept in step with the pages by `puzzle_engine_collisions_test`,
/// which reads their code.
abstract final class PuzzleEngineDispatch {
  /// The mission page's steps (its puzzle stage's `switch`).
  static const mission = [
    EngineStep('investigations', 'InvestigationSearch'),
    EngineStep('stationClocks', 'StationClocks'),
    EngineStep('compares', 'SpotDifferences'),
    EngineStep('studios', 'StudioMatch'),
    EngineStep('layers', 'RevealLayer'),
    EngineStep('records', 'TowerRecords'),
    EngineStep('lifts', 'LiftRoute'),
    EngineStep('dialLocks', 'DialLock'),
    EngineStep('riverMarks', 'RiverMarks'),
    EngineStep('keeperHuts', 'KeeperHut'),
    EngineStep('quayBoxes', 'LabelAssembly'),
    EngineStep('markCompares', 'MarkCompare'),
    EngineStep('clockWalls', 'ClockWall'),
    EngineStep('blotters', 'BlotterMirror'),
    EngineStep('holdRacks', 'HoldRackPuzzle'),
    EngineStep('planRoutes', 'PlanRoutePuzzle'),
    EngineStep('archives', 'ArchivePuzzle'),
    EngineStep('showStrips', 'ShowStripPuzzle'),
    EngineStep('lightBoards', 'LightBoardPuzzle'),
    EngineStep('flyRails', 'FlyRailPuzzle'),
    EngineStep('cornerChoices', 'PainterCornerPuzzle'),
    EngineStep('morningSketches', 'MorningSketchesPuzzle'),
    EngineStep('tornSlips', 'TornSlipPuzzle'),
    EngineStep('trialMaps', 'TrialMapPuzzle'),
    EngineStep('gearBoards', 'GearBoardPuzzle'),
    EngineStep('makerMarks', 'MakerMarksPuzzle'),
    EngineStep('drumTapes', 'DrumTapePuzzle'),
    EngineStep('cityClocks', 'CityClocksPuzzle'),
    EngineStep('shadowChecks', 'ShadowCheckPuzzle'),
    EngineStep('explores', 'SceneExplore'),
    EngineStep('deductions', 'SceneDeduction'),
    EngineStep('decodes', 'SceneDecode'),
    EngineStep('inspections', 'LensInspect'),
    EngineStep.talkBefore(),
    EngineStep('easySteps', 'EasyStepsPuzzle'),
    EngineStep('talks', 'CaseTalk'),
    EngineStep('dialogues', 'DialogueInvestigation'),
    // The question's own clock face, in place of its keypad.
    EngineStep('clocks', 'ClockQuestion'),
  ];

  /// The final page's steps: a talk or steps take the whole page; then its
  /// puzzle (`_puzzle`).
  static const finalMission = [
    EngineStep('talks', 'CaseTalk'),
    EngineStep('easySteps', 'EasyStepsPuzzle'),
    EngineStep.type(MissionType.finalCode, '_Dial'),
    EngineStep('canvases', 'CanvasPicker'),
    EngineStep('hourRecords', 'HourRecordPuzzle'),
    EngineStep('towerTests', 'TowerTestPuzzle'),
    EngineStep('tornHours', 'PaperOnDrawing'),
    EngineStep('evidenceBoards', 'EvidenceBoard'),
    EngineStep('streetBooks', 'StreetBookPuzzle'),
    EngineStep('lightTables', 'ChangedRecordPuzzle'),
    EngineStep('letterMaps', 'LetterMapPuzzle'),
    EngineStep('postTrails', 'PostTrailPuzzle'),
  ];

  /// Played with the mission's puzzle, never in its stead: the talk around
  /// it (`TalkMission`; its talk before is a step of [mission]) and the
  /// thing handed over with its letter (`Exhibit`).
  static const missionCompanions = {'talkMissions', 'exhibits'};

  /// Played with the final's puzzle: the box of its letter lock and the
  /// ending after the answer.
  static const finalCompanions = {'lockBoxes', 'endings'};

  /// Tables of a mission that are no engine (its story, its Discovery
  /// Moment, its learning note).
  static const notEngines = {'storyScenes', 'discoveries', 'learning'};

  /// Tables whose entry (played or not) takes the mission from its story
  /// straight to its puzzle (the story page's `onInvestigate`), with the talk
  /// before: its letter page, where an exhibit is handed over, is never
  /// shown. A searched place (`investigations`) shows its own arrival there.
  static const skipsLetter = {
    'dialogues',
    'talks',
    'easySteps',
    'stationClocks',
    'studios',
    'records',
    'lifts',
    'riverMarks',
    'keeperHuts', //
    'quayBoxes',
    'markCompares',
    'clockWalls',
    'blotters',
    'holdRacks',
    'planRoutes',
    'archives',
    'showStrips',
    'lightBoards',
    'flyRails',
    'cornerChoices',
    'morningSketches',
    'tornSlips',
    'trialMaps',
    'gearBoards',
    'makerMarks',
    'drumTapes',
    'cityClocks',
    'shadowChecks',
    'explores',
    'inspections',
    'deductions',
    'decodes',
  };

  static List<EngineStep> chainOf(PuzzleSurface surface) =>
      surface == PuzzleSurface.mission ? mission : finalMission;

  /// The engine tables [surface]'s page plays (its steps).
  static Set<String> enginesOn(PuzzleSurface surface) => {
    for (final s in chainOf(surface))
      if (s.kind == EngineStepKind.table) s.table!,
  };

  static Set<String> companionsOn(PuzzleSurface surface) =>
      surface == PuzzleSurface.mission ? missionCompanions : finalCompanions;

  /// Every table [surface]'s page reads for a mission's puzzle.
  static Set<String> readOn(PuzzleSurface surface) => {
    ...enginesOn(surface),
    ...companionsOn(surface),
  };

  /// The widget a mission of [type] is played on when no step holds (the
  /// question of its type, `questionFor`), or null when there is none: a
  /// type played on its pictures only shows nothing.
  static String? defaultEngine(MissionType type) => switch (type) {
    MissionType.multipleChoice => 'MultipleChoiceQuestion',
    MissionType.wordInput => 'WordInputQuestion',
    MissionType.numberCode || MissionType.finalCode => 'NumberCodeQuestion',
    MissionType.imageChoice => 'ImageChoiceQuestion',
    MissionType.examine => 'GameButton (EXAMINE)',
    MissionType.sequence => 'SequenceQuestion',
    MissionType.letterLock => 'LetterLockQuestion',
    MissionType.spotDifferences ||
    MissionType.matchPairs ||
    MissionType.revealLayer ||
    MissionType.canvasChoice => null,
  };
}

/// An engine of a slot: a table's, or one chosen by the mission's type
/// ([table] null).
class EngineUse {
  const EngineUse(this.engine, {this.table});

  final String engine;
  final String? table;

  @override
  String toString() => table == null ? engine : '$engine ($table)';
}

/// One mission or final and the engines its season registers for it.
class EngineSlot {
  EngineSlot({
    required this.seasonId,
    required this.caseId,
    required this.mission,
    required this.tables,
  });

  final String seasonId;
  final String caseId;
  final Mission mission;

  /// The tables naming it (engines and companions; not its story's).
  final List<String> tables;

  PuzzleSurface get surface =>
      mission.finale ? PuzzleSurface.finalMission : PuzzleSurface.mission;

  /// The engine played (its type's question when no table holds; its
  /// engine is null when that type shows nothing).
  late EngineUse? active;

  /// Engines registered for it, never reached.
  final shadowed = <EngineUse>[];

  /// Companion tables played with it, and those never shown.
  final companions = <String>[];
  final hiddenCompanions = <String>[];

  /// Tables its page does not read.
  final unread = <String>[];

  /// The palette puzzle its played engine is, or null (an engine outside the
  /// palette, or nothing).
  String? paletteId;

  String get slotLabel =>
      surface == PuzzleSurface.finalMission ? 'Final' : 'M${mission.number}';
}

enum EngineIssueKind {
  /// Two or more engine tables for one slot: the first the page looks at is
  /// played, the others never.
  primaryCollision('primary_collision'),

  /// An engine table under the engine the mission's type picks first.
  typeOverride('type_override'),

  /// A companion that is never shown with the engine played.
  companionHidden('companion_hidden'),

  /// A table the slot's page does not read (the other page's).
  wrongSurface('wrong_surface'),

  /// A type played on its pictures only, with no engine for its pictures:
  /// nothing is shown.
  unplayable('unplayable_type'),

  /// A table the season declares retired, played.
  retiredPlayed('retired_engine_played'),

  /// A retired table that is not an engine table.
  retiredUnknown('retired_engine_unknown');

  const EngineIssueKind(this.code);

  final String code;
}

/// Something wrong (or accepted) in how a slot's engines are registered.
class EngineFinding {
  const EngineFinding({
    required this.seasonId,
    required this.kind,
    required this.message,
    this.caseId,
    this.missionId,
    this.slot,
    this.active,
    this.shadowed = const [],
    this.tables = const [],
    this.accepted = false,
  });

  final String seasonId;
  final String? caseId;
  final String? missionId;

  /// `M1`…, or `Final`.
  final String? slot;
  final EngineIssueKind kind;
  final String message;

  /// The engine played, and the ones it hides.
  final EngineUse? active;
  final List<EngineUse> shadowed;

  /// The tables concerned.
  final List<String> tables;

  /// Kept on purpose (the season declares its hidden tables retired): no
  /// problem under any policy.
  final bool accepted;

  ContentIssue toIssue() => ContentIssue(
    seasonId,
    'engine',
    '${kind.code}: $message',
    caseId: caseId,
    missionId: missionId,
  );

  @override
  String toString() =>
      '[${kind.code}${accepted ? ', accepted' : ''}] ${[seasonId, ?caseId, ?missionId].join(' ')}: $message';
}

/// How engine findings count as problems.
enum EngineCheckPolicy {
  /// Every finding not accepted is a problem (new content, and the game's).
  strict,

  /// Findings are reported ([PuzzleEngineCollisionCheck.findingsOf]), never
  /// problems: to look at content as it is.
  diagnose,
}

/// Whether each mission and final of a season is registered for one engine
/// its page plays, with companions that are shown with it: the pages' own
/// order of choice ([PuzzleEngineDispatch]) applied to the season's tables.
/// Never run by the game.
///
/// The base tables decide: a level's tables hold only entries the base has
/// (`DifficultyContent`), so a slot has the same engines at every level.
/// A table entry that names no mission of the season is
/// `SeasonContentValidator`'s to report (`reference`), not this check's.
abstract final class PuzzleEngineCollisionCheck {
  /// Every slot of [season] (its cases that parse), its engines resolved.
  static List<EngineSlot> slotsOf(SeasonContent season) {
    final tables = season.missionTables;
    final out = <EngineSlot>[];
    for (final MapEntry(key: caseId, value: json) in {
      ...season.episodes,
      ...season.awaitingArt,
    }.entries) {
      final Episode e;
      try {
        e = Episode.fromJson({...json, 'seasonId': season.id});
      } catch (_) {
        continue; // reported by SeasonContentValidator ('case').
      }
      for (final m in e.allMissions) {
        final slot = EngineSlot(
          seasonId: season.id,
          caseId: caseId,
          mission: m,
          tables: [
            for (final MapEntry(key: t, value: entries) in tables.entries)
              if (!PuzzleEngineDispatch.notEngines.contains(t) &&
                  entries.containsKey(m.id))
                t,
          ],
        );
        _resolve(slot, tables);
        out.add(slot);
      }
    }
    return out;
  }

  static void _resolve(
    EngineSlot slot,
    Map<String, Map<String, Object?>> tables,
  ) {
    final m = slot.mission;
    final surface = slot.surface;
    final reads = PuzzleEngineDispatch.readOn(surface);
    final here = {
      for (final t in slot.tables)
        if (reads.contains(t)) t,
    };
    slot.unread.addAll(slot.tables.where((t) => !reads.contains(t)));

    final talk = here.contains('talkMissions')
        ? tables['talkMissions']![m.id] as TalkMission
        : null;
    EngineUse? active;
    var activeAt = -1;
    var talkBeforeAt = -1;
    final chain = PuzzleEngineDispatch.chainOf(surface);
    for (final (i, step) in chain.indexed) {
      switch (step.kind) {
        case EngineStepKind.talkBefore:
          talkBeforeAt = i;
        case EngineStepKind.type when m.type == step.type && active == null:
          active = EngineUse(step.engine);
          activeAt = i;
        case EngineStepKind.type:
          break;
        case EngineStepKind.table when here.contains(step.table):
          final use = EngineUse(step.engine, table: step.table);
          if (active == null) {
            active = use;
            activeAt = i;
          } else {
            slot.shadowed.add(use);
          }
        case EngineStepKind.table:
          break;
      }
    }
    final byDefault = active == null;
    if (byDefault) {
      activeAt = chain.length;
      final engine = PuzzleEngineDispatch.defaultEngine(m.type);
      active = engine == null ? null : EngineUse(engine);
    }
    slot.active = active;

    void companion(String table, bool shown) =>
        (shown ? slot.companions : slot.hiddenCompanions).add(table);
    if (surface == PuzzleSurface.mission) {
      if (talk != null) {
        // The talk after is had whatever the puzzle; the talk before only
        // when no engine is played before it.
        final before = talk.before == null || activeAt > talkBeforeAt;
        companion('talkMissions', before);
      }
      if (here.contains('exhibits')) {
        companion(
          'exhibits',
          talk?.before == null &&
              !slot.tables.any(
                (t) =>
                    t == 'investigations' ||
                    PuzzleEngineDispatch.skipsLetter.contains(t),
              ),
        );
      }
    } else {
      // The box shows the letters set in the final's own letter lock.
      if (here.contains('lockBoxes')) {
        companion('lockBoxes', byDefault && m.type == MissionType.letterLock);
      }
      if (here.contains('endings')) companion('endings', true);
    }

    slot.paletteId = _paletteIdOf(active, m.type, surface);
  }

  static String? _paletteIdOf(
    EngineUse? active,
    MissionType type,
    PuzzleSurface surface,
  ) {
    if (active == null) return null;
    for (final p in PuzzlePalette.all) {
      for (final e in p.playable) {
        if (!e.surfaces.contains(surface)) continue;
        if (active.table != null
            ? e.table == active.table
            : e.table == null &&
                  e.widget == active.engine &&
                  e.missionTypes.contains(type)) {
          return p.id;
        }
      }
    }
    return null;
  }

  /// Every finding of [season] (accepted ones included).
  static List<EngineFinding> findingsOf(SeasonContent season) {
    final out = <EngineFinding>[];
    final retired = season.retiredEngines;
    final engineTables = {
      ...PuzzleEngineDispatch.enginesOn(PuzzleSurface.mission),
      ...PuzzleEngineDispatch.enginesOn(PuzzleSurface.finalMission),
    };
    for (final t in retired) {
      if (!engineTables.contains(t)) {
        out.add(
          EngineFinding(
            seasonId: season.id,
            kind: EngineIssueKind.retiredUnknown,
            message: 'retired table $t is no engine table',
            tables: [t],
          ),
        );
      }
    }
    for (final slot in slotsOf(season)) {
      EngineFinding finding(
        EngineIssueKind kind,
        String message, {
        List<String> tables = const [],
        List<EngineUse> shadowed = const [],
        bool accepted = false,
      }) => EngineFinding(
        seasonId: season.id,
        caseId: slot.caseId,
        missionId: slot.mission.id,
        slot: slot.slotLabel,
        kind: kind,
        message: message,
        active: slot.active,
        shadowed: shadowed,
        tables: tables,
        accepted: accepted,
      );
      final page = slot.surface == PuzzleSurface.mission ? 'mission' : 'final';
      final other = slot.surface == PuzzleSurface.mission
          ? PuzzleSurface.finalMission
          : PuzzleSurface.mission;
      for (final t in slot.unread) {
        final where = PuzzleEngineDispatch.readOn(other).contains(t)
            ? 'read on the ${other == PuzzleSurface.mission ? 'mission' : 'final'} page only'
            : 'read by no page';
        out.add(
          finding(
            EngineIssueKind.wrongSurface,
            '$t is never read on a $page page ($where)',
            tables: [t],
          ),
        );
      }
      final active = slot.active;
      if (slot.shadowed.isNotEmpty) {
        final hidden = slot.shadowed.join(', ');
        final tables = [
          ?active?.table,
          for (final s in slot.shadowed) s.table!,
        ];
        if (active?.table == null) {
          out.add(
            finding(
              EngineIssueKind.typeOverride,
              '$hidden never played: a ${slot.mission.type.name} is played on $active, looked at first',
              tables: tables,
              shadowed: slot.shadowed,
            ),
          );
        } else {
          final accepted =
              !retired.contains(active!.table) &&
              slot.shadowed.every((s) => retired.contains(s.table));
          out.add(
            finding(
              EngineIssueKind.primaryCollision,
              '$active is played; $hidden never (${active.table} is looked at first)${accepted ? '; retired by the season' : ''}',
              tables: tables,
              shadowed: slot.shadowed,
              accepted: accepted,
            ),
          );
        }
      }
      if (active?.table case final t? when retired.contains(t)) {
        out.add(
          finding(
            EngineIssueKind.retiredPlayed,
            '$t is retired by the season, yet $active is played',
            tables: [t],
          ),
        );
      }
      for (final t in slot.hiddenCompanions) {
        final why = switch (t) {
          'talkMissions' => 'its talk before comes after $active',
          'exhibits' => 'the mission goes from its story straight to its puzzle: its letter page is never shown',
          'lockBoxes' =>
            active == null || active.table != null
                ? '$active is played, not its letter lock'
                : 'a ${slot.mission.type.name} has no letter lock',
          _ => 'never shown',
        };
        out.add(
          finding(
            EngineIssueKind.companionHidden,
            '$t never shown: $why',
            tables: [t],
          ),
        );
      }
      if (active == null) {
        out.add(
          finding(
            EngineIssueKind.unplayable,
            'a ${slot.mission.type.name} with no engine for its pictures on the $page page: nothing is shown',
          ),
        );
      }
    }
    return out;
  }

  /// [season]'s findings that are problems under [policy].
  static List<ContentIssue> problemsOf(
    SeasonContent season, {
    EngineCheckPolicy policy = EngineCheckPolicy.strict,
  }) => switch (policy) {
    EngineCheckPolicy.diagnose => const [],
    EngineCheckPolicy.strict => [
      for (final f in findingsOf(season))
        if (!f.accepted) f.toIssue(),
    ],
  };
}
