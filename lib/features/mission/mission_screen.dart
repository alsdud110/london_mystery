import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/answer_checker.dart';
import '../../core/utils/audio_service.dart';
import '../../data/models/mission.dart';
import '../../data/mock/season_catalog.dart';
import '../../data/models/scene_deduction.dart';
import '../../data/models/scene_decode.dart';
import '../../data/models/scene_explore.dart';
import '../../data/models/scene_inspect.dart';
import '../../data/models/clock_puzzle.dart';
import '../../data/models/game_progress.dart';
import '../../data/models/letter_puzzles.dart';
import '../../data/models/opera_puzzles.dart';
import '../../data/models/painter_puzzles.dart';
import '../../data/models/river_puzzles.dart';
import '../../data/models/scene_exhibit.dart';
import '../../data/models/station_clocks.dart';
import '../../data/models/story_picture.dart';
import '../../data/models/tower_puzzles.dart';
import '../../data/models/workshop_puzzles.dart';
import '../../data/models/dialogue.dart';
import '../../data/models/investigation.dart';
import '../../data/mock/season1/season1_sounds.dart';
import '../../widgets/clue_card.dart';
import '../../widgets/coin_balance.dart';
import '../../widgets/detective_character.dart';
import '../../widgets/detective_tips.dart';
import '../../widgets/evidence_card.dart';
import '../../widgets/back_to.dart';
import '../../widgets/centered_scroll.dart';
import '../../widgets/game_button.dart';
import '../../widgets/glossary_text.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/landmark_art.dart';
import '../../widgets/place_art.dart';
import '../../widgets/letter_card.dart';
import '../../widgets/paper.dart';
import '../../widgets/paper_background.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../game/scoring.dart';
import 'widgets/answer_feedback.dart';
import 'widgets/archive_drawers.dart';
import 'widgets/blotter_mirror.dart';
import 'widgets/clock_wall.dart';
import 'widgets/clock_question.dart';
import 'widgets/dial_lock.dart';
import 'widgets/dialogue_investigation.dart';
import 'widgets/exhibit.dart';
import 'widgets/fly_rail.dart';
import 'widgets/hold_rack.dart';
import 'widgets/investigation_search.dart';
import 'widgets/keeper_ledger.dart';
import 'widgets/label_assembly.dart';
import 'widgets/lift_route.dart';
import 'widgets/light_board.dart';
import 'widgets/lens_inspect.dart';
import 'widgets/mark_compare.dart';
import 'widgets/plan_route.dart';
import 'widgets/scene_deduction.dart';
import 'widgets/scene_decode.dart';
import 'widgets/scene_explore.dart';
import 'widgets/show_strip.dart';
import 'widgets/station_clocks.dart';
import 'widgets/story_picture_view.dart';
import 'widgets/question_widgets.dart';
import 'widgets/reveal_layer.dart';
import 'widgets/river_marks.dart';
import 'widgets/spot_differences.dart';
import 'widgets/studio_match.dart';
import 'widgets/tip_shop.dart';
import 'widgets/tower_records.dart';
import '../../data/models/detective_name.dart';

/// The three steps of a mission. Each screen offers one main action.
enum MissionStage { story, letter, puzzle }

/// One mission: the place → the sealed letter → the puzzle.
class MissionScreen extends ConsumerStatefulWidget {
  const MissionScreen({super.key, required this.missionId});

  final String missionId;

  @override
  ConsumerState<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends ConsumerState<MissionScreen> {
  late MissionStage _stage;
  bool _letterOpened = false;
  int _wrongPulse = 0;

  /// A mission searched in its place: what was found so far (kept while
  /// the page is open, so reading the report again keeps it; not saved).
  final List<String> _found = [];

  /// A searched place: its arrival was seen whole (coming back to it shows
  /// it at once), and the first "tap here" guide was shown (never again on
  /// this page). Not saved.
  bool _arrived = false;
  bool _guideShown = false;

  /// A mission played by talking to its people: who was asked what, and
  /// the statements heard (kept while the page is open; not saved).
  final DialogueProgress _talk = DialogueProgress();

  /// A mission played on a clock face: where the detective set its hands
  /// (kept while the page is open, so reading the letter again keeps them;
  /// not saved). Null: not touched yet, at the puzzle's start.
  ClockTime? _clockTime;

  /// A mission played by looking round its place: what was looked at, the
  /// letter opened, what is open over the picture (kept while the page is
  /// open; not saved).
  final ExploreProgress _explore = ExploreProgress();

  /// A mission played by examining its exhibits: what was examined, the
  /// label read, what is open over the room, where the glass is (kept
  /// while the page is open; not saved).
  final InspectProgress _inspect = InspectProgress();

  /// A mission played by reading its place's traces: the clues noted and
  /// the place chosen (kept while the page is open; not saved).
  final DeductionProgress _deduction = DeductionProgress();

  /// A mission played by examining one thing at its place: how far the
  /// detective has got with it (kept while the page is open; not saved).
  final DecodeProgress _decode = DecodeProgress();

  /// A mission played by comparing a station's clocks: what was looked at
  /// (saved too: [GameProgress.examined]), what is open over the hall.
  final StationClocksProgress _station = StationClocksProgress();

  /// A mission played on its pictures (a street and its painting, a studio,
  /// a painted-over sketch): what was found (saved too:
  /// [GameProgress.examined]), what is open or joined on the page.
  final PicturePuzzleProgress _picture = PicturePuzzleProgress();

  /// A mission played on Case 03's papers and lift (Paris): the record
  /// shown, the lines and the stop picked (kept while the page is open;
  /// what was read is saved: [GameProgress.examined]).
  final TowerPuzzleProgress _tower = TowerPuzzleProgress();

  /// Case 04's box answer just found in the ledger (Paris): its reward,
  /// held for the Discovery Moment until the ledger's second page is read.
  /// Null after a restart: the moment then says the reward was paid.
  SubmitOutcome? _ledgerSolve;

  /// Case 05's place just found on the blotter (Paris): its reward, held for
  /// the Discovery Moment until Clock III is opened. Null after a restart.
  SubmitOutcome? _hideawaySolve;

  /// Case 06's envelope just found in the archive (Paris): its reward, held
  /// for the Discovery Moment until its seal is looked at. Null after a
  /// restart.
  SubmitOutcome? _envelopeSolve;

  /// Case 07's stage lit like the photo (Paris): its reward, held for the
  /// Discovery Moment until the cue card is read and the scrap found (the
  /// scrap seen is kept while the page is open). Null after a restart.
  SubmitOutcome? _cueSolve;
  bool _scrapSeen = false;

  /// Case 07's backdrop found (Paris): its reward, held for the Discovery
  /// Moment until the slip is taken from its pocket (the pocket opened is
  /// kept while the page is open). Null after a restart.
  SubmitOutcome? _pocketSolve;
  bool _pocketOpen = false;

  @override
  void initState() {
    super.initState();
    final progress = ref.read(gameControllerProvider);
    // What was found on the pictures before (an earlier visit, or before a
    // restart) stays found.
    final m = _mission;
    final things = [
      ...?SeasonCatalog.compare(m)?.changes.map((c) => c.id),
      ...?SeasonCatalog.studio(m)?.paintings.map((p) => p.id),
      if (SeasonCatalog.studio(m) != null) deskId,
      ...?SeasonCatalog.layer(m)?.marks.map((x) => x.id),
    ];
    for (final id in things) {
      if (progress.hasExamined(GameProgress.examinedKey(widget.missionId, id))) _picture.found.add(id);
    }
    // The clocks and the board looked at before (an earlier visit, or
    // before a restart) stay looked at.
    final hall = SeasonCatalog.stationClocks(_mission);
    if (hall != null) {
      for (final id in [
        for (final c in hall.clocks) c.optionId,
        hall.board.id,
        hall.desk.id,
      ]) {
        if (progress.hasExamined(
          GameProgress.examinedKey(widget.missionId, id),
        )) {
          _station.looked.add(id);
        }
      }
    }
    // Returning players skip straight to the puzzle they were on.
    _stage =
        progress.isCompleted(widget.missionId) ||
            progress.missionStartedAt.containsKey(widget.missionId)
        ? MissionStage.puzzle
        : MissionStage.story;
  }

  void _goTo(MissionStage stage) {
    if (stage == MissionStage.puzzle) {
      ref
          .read(gameControllerProvider.notifier)
          .markMissionStarted(widget.missionId);
      // A padlock's note, read on the letter step, stays read.
      if (SeasonCatalog.dialLock(_mission) != null) _recordFound(_mission, noteId);
    }
    setState(() => _stage = stage);
  }

  /// Back (arrow or Android back) walks back one step: puzzle → letter →
  /// place → map. A read letter stays open when coming back to it.
  bool get _atFirstStep =>
      _stage == MissionStage.story ||
      ref.read(gameControllerProvider).isCompleted(widget.missionId);

  void _back() {
    if (_atFirstStep) {
      context.canPop() ? context.pop() : context.go(Routes.map);
      return;
    }
    final exploring =
        _stage == MissionStage.puzzle &&
        SeasonCatalog.explore(_mission) != null;
    final inspecting =
        _stage == MissionStage.puzzle &&
        SeasonCatalog.inspection(_mission) != null;
    final comparing =
        _stage == MissionStage.puzzle &&
        SeasonCatalog.stationClocks(_mission) != null;
    // The station hall: back first closes the clock, board or desk over it.
    if (comparing && _station.open != null) {
      setState(() => _station.open = null);
      return;
    }
    // The studio: back first closes the painting, the notes or the matching
    // page over it.
    final inStudio = _stage == MissionStage.puzzle && SeasonCatalog.studio(_mission) != null;
    // Case 03's records and lift are read on the puzzle page itself: no
    // letter step (back is the place).
    final onPapers =
        _stage == MissionStage.puzzle &&
        (SeasonCatalog.records(_mission) != null ||
            SeasonCatalog.lift(_mission) != null ||
            SeasonCatalog.riverMarks(_mission) != null ||
            SeasonCatalog.keeperHut(_mission) != null ||
            SeasonCatalog.quayBoxes(_mission) != null ||
            SeasonCatalog.markCompare(_mission) != null ||
            SeasonCatalog.clockWall(_mission) != null ||
            SeasonCatalog.blotter(_mission) != null ||
            SeasonCatalog.holdRack(_mission) != null ||
            SeasonCatalog.planRoute(_mission) != null ||
            SeasonCatalog.archive(_mission) != null ||
            SeasonCatalog.showStrip(_mission) != null ||
            SeasonCatalog.lightBoard(_mission) != null ||
            SeasonCatalog.flyRail(_mission) != null);
    // Case 04's hut: back walks out of it one place at a time (the ledger,
    // the inside, the outside).
    final hut = SeasonCatalog.keeperHut(_mission);
    if (_stage == MissionStage.puzzle && hut != null) {
      final (at, box) = HutState.decode(ref.read(gameControllerProvider).puzzleStateOf(_mission.id), hut);
      if (at != HutStep.outside) {
        _saveHut(_mission, HutStep.values[at.index - 1], box);
        return;
      }
    }
    if (inStudio && _picture.open != null) {
      setState(() => _picture.open = null);
      return;
    }
    // Looking round a place, or examining its exhibits: back first closes
    // what is open over it.
    if (exploring && _explore.open != null) {
      setState(() => _explore.open = null);
      return;
    }
    if (inspecting && _inspect.open != null) {
      setState(() => _inspect.open = null);
      return;
    }
    // A thing brought closer, its code not yet decoded (or half-scanned):
    // back first puts it back in its place.
    final examining =
        _stage == MissionStage.puzzle && SeasonCatalog.decode(_mission) != null;
    if (examining && _decode.step == DecodeStep.closer) {
      setState(() => _decode.step = DecodeStep.look);
      return;
    }
    // A talk, a look round, a place read for its traces and a thing
    // examined have no letter step: back from them is the place.
    final talking =
        _stage == MissionStage.puzzle &&
        SeasonCatalog.dialogue(_mission) != null;
    final reading =
        _stage == MissionStage.puzzle &&
        SeasonCatalog.deduction(_mission) != null;
    setState(() {
      if (_stage == MissionStage.puzzle) _letterOpened = true;
      _stage =
          _stage == MissionStage.puzzle &&
              !talking &&
              !exploring &&
              !inspecting &&
              !comparing &&
              !inStudio &&
              !onPapers &&
              !reading &&
              !examining
          ? MissionStage.letter
          : MissionStage.story;
    });
  }

  /// A thing examined at its place (taking it answers the mission's puzzle:
  /// the scene sends the mission's own answer, never typed).
  Widget _decodeStage(Mission m, DecodeScene scene, int hintsShown) =>
      SceneDecode(
        key: const ValueKey('puzzle'),
        scene: scene,
        mission: m,
        progress: _decode,
        onChanged: () => setState(() {}),
        onTake: () => _submit(m, m.answer),
        hintsShown: hintsShown,
        onHint: () => _showHint(m),
      );

  /// A place read for its traces (the place chosen answers the mission's
  /// puzzle).
  Widget _deductionStage(Mission m, DeductionScene scene, int hintsShown) =>
      SceneDeduction(
        key: const ValueKey('puzzle'),
        scene: scene,
        mission: m,
        progress: _deduction,
        onChanged: () => setState(() {}),
        onChoose: (id) => _submit(m, id),
        hintsShown: hintsShown,
        onHint: () => _showHint(m),
        wrongPulse: _wrongPulse,
      );

  /// Exhibits examined under the glass (the word on the label answers the
  /// mission's puzzle).
  Widget _inspectStage(Mission m, InspectScene scene, int hintsShown) =>
      LensInspect(
        key: const ValueKey('puzzle'),
        scene: scene,
        mission: m,
        progress: _inspect,
        onChanged: () => setState(() {}),
        onSubmit: (word) => _submit(m, word),
        onReread: () => _rereadLetter(m),
        hintsShown: hintsShown,
        onHint: () => _showHint(m),
        wrongPulse: _wrongPulse,
      );

  /// A station hall's clocks compared (the clock reported answers the
  /// mission's puzzle).
  Widget _stationStage(Mission m, StationClocksScene scene, int hintsShown) =>
      StationClocks(
        key: const ValueKey('puzzle'),
        scene: scene,
        mission: m,
        progress: _station,
        onChanged: () => setState(() {}),
        onExamined: (id) => ref
            .read(gameControllerProvider.notifier)
            .recordExamined(GameProgress.examinedKey(m.id, id)),
        onChoose: (id) => _submit(m, id),
        hintsShown: hintsShown,
        onHint: () => _showHint(m),
        wrongPulse: _wrongPulse,
      );

  /// A thing found on a mission's pictures: saved, so it stays found.
  void _recordFound(Mission m, String id) =>
      ref.read(gameControllerProvider.notifier).recordExamined(GameProgress.examinedKey(m.id, id));

  /// A street compared with its painting (every change found answers the
  /// mission's puzzle).
  Widget _compareStage(Mission m, CompareScene scene, int hintsShown) => SpotDifferences(
        key: const ValueKey('puzzle'),
        scene: scene,
        mission: m,
        progress: _picture,
        onChanged: () => setState(() {}),
        onFound: (id) => _recordFound(m, id),
        onComplete: () => _submit(m, m.answer),
        onReread: () => _rereadLetter(m),
        hintsShown: hintsShown,
        onHint: () => _showHint(m),
      );

  /// A studio looked round, its notes joined to its paintings (the pairs
  /// answer the mission's puzzle).
  Widget _studioStage(Mission m, StudioScene scene, int hintsShown) => StudioMatch(
        key: const ValueKey('puzzle'),
        scene: scene,
        mission: m,
        progress: _picture,
        onChanged: () => setState(() {}),
        onFound: (id) => _recordFound(m, id),
        onSubmit: (a) => _submit(m, a),
        hintsShown: hintsShown,
        onHint: () => _showHint(m),
        wrongPulse: _wrongPulse,
      );

  /// A sketch uncovered under its paint (every thing found on it answers the
  /// mission's puzzle).
  Widget _layerStage(Mission m, LayerScene scene, GameProgress progress) => RevealLayer(
        key: const ValueKey('puzzle'),
        scene: scene,
        mission: m,
        progress: _picture,
        revealed: progress.revealedOf(m.id),
        onChanged: () => setState(() {}),
        onReveal: (v) => ref.read(gameControllerProvider.notifier).recordReveal(m.id, v),
        onFound: (id) => _recordFound(m, id),
        onComplete: () => _submit(m, m.answer),
        onReread: () => _rereadLetter(m),
        hintsShown: progress.hintsFor(m.id),
        onHint: () => _showHint(m),
      );

  /// The things of a mission's scene looked at so far (saved), by id.
  Set<String> _looked(Mission m, Iterable<String> ids, GameProgress progress) => {
        for (final id in ids)
          if (progress.hasExamined(GameProgress.examinedKey(m.id, id))) id,
      };

  /// Two records compared line by line (the lines picked answer the
  /// mission's puzzle).
  Widget _recordsStage(Mission m, RecordsScene scene, GameProgress progress) => _PuzzleStage(
        key: const ValueKey('puzzle'),
        mission: m,
        hintsShown: progress.hintsFor(m.id),
        wrongPulse: _wrongPulse,
        onHint: () => _showHint(m),
        onReread: () => _rereadLetter(m),
        child: TowerRecords(
          scene: scene,
          mission: m,
          progress: _tower,
          read: _looked(m, [for (final d in scene.docs) d.id], progress),
          onRead: (id) => _recordFound(m, id),
          onChanged: () => setState(() {}),
          onSubmit: (a) => _submit(m, a),
        ),
      );

  /// The lift's route plate and log read (the stop chosen answers the
  /// mission's puzzle).
  Widget _liftStage(Mission m, LiftScene scene, GameProgress progress) => _PuzzleStage(
        key: const ValueKey('puzzle'),
        mission: m,
        hintsShown: progress.hintsFor(m.id),
        wrongPulse: _wrongPulse,
        onHint: () => _showHint(m),
        onReread: () => _rereadLetter(m),
        child: LiftRoute(
          scene: scene,
          mission: m,
          progress: _tower,
          read: _looked(m, const [LiftScene.plateId, LiftScene.logId], progress),
          onRead: (id) => _recordFound(m, id),
          onChanged: () => setState(() {}),
          onSubmit: (a) => _submit(m, a),
        ),
      );

  /// A padlock's dials set (the symbols set answer the mission's puzzle);
  /// where they are left is saved.
  Widget _dialStage(Mission m, DialLockScene scene, GameProgress progress) => _PuzzleStage(
        key: const ValueKey('puzzle'),
        mission: m,
        hintsShown: progress.hintsFor(m.id),
        wrongPulse: _wrongPulse,
        onHint: () => _showHint(m),
        onReread: () => _rereadLetter(m),
        child: DialLock(
          scene: scene,
          mission: m,
          dials: DialState.decode(progress.puzzleStateOf(m.id), scene),
          onSet: (dials) => ref.read(gameControllerProvider.notifier).recordPuzzleState(m.id, DialState.encode(dials)),
          onSubmit: (a) => _submit(m, a),
        ),
      );

  /// The quay wall's marks looked at, the plaque read again (the mark
  /// chosen answers the mission's puzzle).
  Widget _marksStage(Mission m, RiverMarksScene scene, GameProgress progress) => _PuzzleStage(
        key: const ValueKey('puzzle'),
        mission: m,
        hintsShown: progress.hintsFor(m.id),
        wrongPulse: _wrongPulse,
        onHint: () => _showHint(m),
        onReread: () => _rereadLetter(m),
        child: RiverMarks(
          scene: scene,
          mission: m,
          read: _looked(m, [...scene.marks.map((x) => x.id), RiverMarksScene.backId], progress),
          onRead: (id) => _recordFound(m, id),
          onSubmit: (a) => _submit(m, a),
        ),
      );

  void _saveHut(Mission m, HutStep at, String? box) =>
      ref.read(gameControllerProvider.notifier).recordPuzzleState(m.id, HutState.encode(at, box));

  /// The keeper's hut walked into, its ledger read (the box circled answers
  /// the mission's puzzle); where the detective is and the box are saved.
  Widget _hutStage(Mission m, KeeperHutScene scene, GameProgress progress) {
    final (at, box) = HutState.decode(progress.puzzleStateOf(m.id), scene);
    return _PuzzleStage(
      key: const ValueKey('puzzle'),
      mission: m,
      hintsShown: progress.hintsFor(m.id),
      wrongPulse: _wrongPulse,
      onHint: () => _showHint(m),
      onReread: () => _rereadLetter(m),
      child: KeeperHut(
        scene: scene,
        mission: m,
        at: at,
        circled: box,
        onAt: (to) {
          if (to == HutStep.ledger) _recordFound(m, KeeperHutScene.ledgerId);
          _saveHut(m, to, box);
        },
        onCircle: (b) => _saveHut(m, at, b),
        onSubmit: (a) => _submit(m, a),
      ),
    );
  }

  /// The box is right: the ledger's second page, turned and read before the
  /// story goes on.
  Widget _ledgerAfterStage(Mission m, KeeperHutScene scene) => CenteredScroll(
        key: const ValueKey('ledger-after'),
        padding: _stagePadding,
        children: [
          Text('MISSION ${m.numberLabel} · THE LEDGER', textAlign: TextAlign.center, style: AppText.eyebrow()),
          const SizedBox(height: AppSpace.lg),
          LedgerSecondPage(scene: scene, answer: m.answer, onContinue: () => _afterLedger(m)),
        ],
      );

  Future<void> _afterLedger(Mission m) async {
    final audio = ref.read(audioServiceProvider);
    ref.read(gameControllerProvider.notifier).recordExamined(GameProgress.examinedKey(m.id, KeeperHutScene.page2Id));
    final solve = _ledgerSolve;
    _ledgerSolve = null;
    await showDiscoveryMoment(
      context,
      mission: m,
      discovery: SeasonCatalog.discovery(m),
      xp: XpBreakdown.of(m, ref.read(gameControllerProvider)),
      coins: solve?.coins ?? 0,
      firstSolve: solve?.firstSolve ?? false,
      newBadges: solve?.newBadges ?? const [],
      onEvidenceLaid: () => audio.play(GameSound.paperPlace),
      showDetective: true,
    );
    if (mounted) context.go(Routes.story(m.id));
  }

  /// The green boxes tried, the label put back together (the frame answers
  /// the mission's puzzle); the boxes tried and the frame are saved.
  Widget _boxesStage(Mission m, BoxesScene scene, GameProgress progress) => _PuzzleStage(
        key: const ValueKey('puzzle'),
        mission: m,
        hintsShown: progress.hintsFor(m.id),
        wrongPulse: _wrongPulse,
        onHint: () => _showHint(m),
        onReread: () => _rereadLetter(m),
        child: LabelAssembly(
          scene: scene,
          mission: m,
          tried: _looked(m, [for (final b in scene.boxes) BoxesScene.boxKey(b.id)], progress),
          onTry: (id) => _recordFound(m, BoxesScene.boxKey(id)),
          placed: LabelState.decode(progress.puzzleStateOf(m.id), scene),
          onPlaced: (placed) => ref.read(gameControllerProvider.notifier).recordPuzzleState(m.id, LabelState.encode(placed, scene)),
          onSubmit: (a) => _submit(m, a),
        ),
      );

  /// The workbench's stamps compared under the tracing sheet (the stamp
  /// chosen answers the mission's puzzle); the stamps compared are saved.
  Widget _benchStage(Mission m, MarkCompareScene scene, GameProgress progress) => _PuzzleStage(
        key: const ValueKey('puzzle'),
        mission: m,
        hintsShown: progress.hintsFor(m.id),
        wrongPulse: _wrongPulse,
        onHint: () => _showHint(m),
        onReread: () => _rereadLetter(m),
        child: MarkCompare(
          scene: scene,
          mission: m,
          compared: {
            for (final s in scene.seals)
              if (progress.hasExamined(GameProgress.examinedKey(m.id, MarkCompareScene.sheetKey(s.id)))) s.id,
          },
          onCompared: (id) => _recordFound(m, MarkCompareScene.sheetKey(id)),
          onSubmit: (a) => _submit(m, a),
        ),
      );

  /// The wall of clocks watched, their backs looked at (the clock chosen
  /// answers the mission's puzzle); the minute watched and the backs are
  /// saved.
  Widget _clocksStage(Mission m, ClockWallScene scene, GameProgress progress) => _PuzzleStage(
        key: const ValueKey('puzzle'),
        mission: m,
        hintsShown: progress.hintsFor(m.id),
        wrongPulse: _wrongPulse,
        onHint: () => _showHint(m),
        onReread: () => _rereadLetter(m),
        child: ClockWall(
          scene: scene,
          mission: m,
          watched: progress.hasExamined(GameProgress.examinedKey(m.id, ClockWallScene.watchedId)),
          looked: {
            for (final c in scene.clocks)
              if (progress.hasExamined(GameProgress.examinedKey(m.id, ClockWallScene.backKey(c.id)))) c.id,
          },
          onWatched: () => _recordFound(m, ClockWallScene.watchedId),
          onLooked: (id) => _recordFound(m, ClockWallScene.backKey(id)),
          onSubmit: (a) => _submit(m, a),
        ),
      );

  /// The blotter read in the hand mirror (the place chosen answers the
  /// mission's puzzle); the notes read are saved.
  Widget _blotterStage(Mission m, BlotterScene scene, GameProgress progress) => _PuzzleStage(
        key: const ValueKey('puzzle'),
        mission: m,
        hintsShown: progress.hintsFor(m.id),
        wrongPulse: _wrongPulse,
        onHint: () => _showHint(m),
        onReread: () => _rereadLetter(m),
        child: BlotterMirror(
          scene: scene,
          mission: m,
          read: {
            for (final n in scene.notes)
              if (progress.hasExamined(GameProgress.examinedKey(m.id, BlotterScene.noteKey(n.id)))) n.id,
          },
          onRead: (id) => _recordFound(m, BlotterScene.noteKey(id)),
          onSubmit: (a) => _submit(m, a),
        ),
      );

  /// The place is right: Clock III opened, what is in it read before the
  /// story goes on.
  Widget _hideawayStage(Mission m, BlotterScene scene) => CenteredScroll(
        key: const ValueKey('hideaway'),
        padding: _stagePadding,
        children: [
          Text('MISSION ${m.numberLabel} · CLOCK III', textAlign: TextAlign.center, style: AppText.eyebrow()),
          const SizedBox(height: AppSpace.lg),
          ClockHideaway(scene: scene, onContinue: () => _afterHideaway(m)),
        ],
      );

  Future<void> _afterHideaway(Mission m) async {
    final audio = ref.read(audioServiceProvider);
    _recordFound(m, BlotterScene.openedId);
    final solve = _hideawaySolve;
    _hideawaySolve = null;
    await showDiscoveryMoment(
      context,
      mission: m,
      discovery: SeasonCatalog.discovery(m),
      xp: XpBreakdown.of(m, ref.read(gameControllerProvider)),
      coins: solve?.coins ?? 0,
      firstSolve: solve?.firstSolve ?? false,
      newBadges: solve?.newBadges ?? const [],
      onEvidenceLaid: () => audio.play(GameSound.paperPlace),
      showDetective: true,
    );
    if (mounted) context.go(Routes.story(m.id));
  }

  /// The hold rack's tags looked at and turned over (the tag chosen answers
  /// the mission's puzzle); the tags turned are saved.
  Widget _rackStage(Mission m, HoldRackScene scene, GameProgress progress) => _PuzzleStage(
        key: const ValueKey('puzzle'),
        mission: m,
        hintsShown: progress.hintsFor(m.id),
        wrongPulse: _wrongPulse,
        onHint: () => _showHint(m),
        onReread: () => _rereadLetter(m),
        child: HoldRackPuzzle(
          scene: scene,
          mission: m,
          turned: {
            for (final t in scene.tags)
              if (progress.hasExamined(GameProgress.examinedKey(m.id, HoldRack.turnedKey(t.id)))) t.id,
          },
          onTurned: (id) => _recordFound(m, HoldRack.turnedKey(id)),
          onSubmit: (a) => _submit(m, a),
        ),
      );

  /// The letter moved along the plan of the building (the door it goes
  /// through answers the mission's puzzle); the places it reached are saved.
  Widget _planStage(Mission m, PlanScene scene, GameProgress progress) => _PuzzleStage(
        key: const ValueKey('puzzle'),
        mission: m,
        hintsShown: progress.hintsFor(m.id),
        wrongPulse: _wrongPulse,
        onHint: () => _showHint(m),
        onReread: () => _rereadLetter(m),
        child: PlanRoutePuzzle(
          scene: scene,
          mission: m,
          reached: {
            for (final step in PlanStep.values)
              if (progress.hasExamined(GameProgress.examinedKey(m.id, PlanRoute.reachedKey(step)))) step,
          },
          onReached: (step) => _recordFound(m, PlanRoute.reachedKey(step)),
          onSubmit: (a) => _submit(m, a),
        ),
      );

  /// The archive's drawers opened, the torn corner laid on an envelope (the
  /// envelope it is laid on answers the mission's puzzle); the drawers
  /// opened are saved.
  Widget _archiveStage(Mission m, ArchiveScene scene, GameProgress progress) => _PuzzleStage(
        key: const ValueKey('puzzle'),
        mission: m,
        hintsShown: progress.hintsFor(m.id),
        wrongPulse: _wrongPulse,
        onHint: () => _showHint(m),
        onReread: () => _rereadLetter(m),
        child: ArchivePuzzle(
          scene: scene,
          mission: m,
          opened: {
            for (final d in scene.drawers.drawers)
              if (progress.hasExamined(GameProgress.examinedKey(m.id, ArchiveDrawers.openedKey(d.id)))) d.id,
          },
          onOpened: (id) => _recordFound(m, ArchiveDrawers.openedKey(id)),
          onSubmit: (a) => _submit(m, a),
        ),
      );

  /// The envelope is found: its seal looked at before the story goes on.
  Widget _envelopeFoundStage(Mission m, ArchiveScene scene) => CenteredScroll(
        key: const ValueKey('envelope-found-stage'),
        padding: _stagePadding,
        children: [
          Text('MISSION ${m.numberLabel} · LETTER 4417', textAlign: TextAlign.center, style: AppText.eyebrow()),
          const SizedBox(height: AppSpace.lg),
          EnvelopeFound(scene: scene, onContinue: () => _afterSeal(m)),
        ],
      );

  Future<void> _afterSeal(Mission m) async {
    final audio = ref.read(audioServiceProvider);
    _recordFound(m, ArchiveDrawers.sealId);
    final solve = _envelopeSolve;
    _envelopeSolve = null;
    await showDiscoveryMoment(
      context,
      mission: m,
      discovery: SeasonCatalog.discovery(m),
      xp: XpBreakdown.of(m, ref.read(gameControllerProvider)),
      coins: solve?.coins ?? 0,
      firstSolve: solve?.firstSolve ?? false,
      newBadges: solve?.newBadges ?? const [],
      onEvidenceLaid: () => audio.play(GameSound.paperPlace),
      showDetective: true,
    );
    if (mounted) context.go(Routes.story(m.id));
  }

  /// The show's strip slid along the clock (what its start says answers
  /// the mission's puzzle).
  Widget _stripStage(Mission m, ShowStripScene scene, GameProgress progress) => _PuzzleStage(
        key: const ValueKey('puzzle'),
        mission: m,
        hintsShown: progress.hintsFor(m.id),
        wrongPulse: _wrongPulse,
        onHint: () => _showHint(m),
        onReread: () => _rereadLetter(m),
        child: ShowStripPuzzle(scene: scene, mission: m, onSubmit: (a) => _submit(m, a)),
      );

  /// The stage lit from the lighting desk (what it says against the old
  /// photo answers the mission's puzzle); the photo looked at is saved.
  Widget _lightsStage(Mission m, LightBoardScene scene, GameProgress progress) => _PuzzleStage(
        key: const ValueKey('puzzle'),
        mission: m,
        hintsShown: progress.hintsFor(m.id),
        wrongPulse: _wrongPulse,
        onHint: () => _showHint(m),
        onReread: () => _rereadLetter(m),
        child: LightBoardPuzzle(
          scene: scene,
          mission: m,
          onPhoto: () => _recordFound(m, LightBoard.photoId),
          onSubmit: (a) => _submit(m, a),
        ),
      );

  /// The stage matches: the cue card read and the scrap found before the
  /// story goes on (the cue card read is saved).
  Widget _cueStage(Mission m, LightBoardScene scene, GameProgress progress) => CenteredScroll(
        key: const ValueKey('cue-stage'),
        padding: _stagePadding,
        children: [
          Text('MISSION ${m.numberLabel} · THE LIGHTING BOOK', textAlign: TextAlign.center, style: AppText.eyebrow()),
          const SizedBox(height: AppSpace.lg),
          CueFound(
            scene: scene,
            mission: m,
            cueRead: progress.hasExamined(GameProgress.examinedKey(m.id, LightBoard.cueId)),
            scrapFound: _scrapSeen,
            onCue: () => _recordFound(m, LightBoard.cueId),
            onScrap: () => setState(() => _scrapSeen = true),
            onContinue: () => _afterHeld(m, LightBoard.scrapId, () {
              final solve = _cueSolve;
              _cueSolve = null;
              return solve;
            }),
          ),
        ],
      );

  /// The backdrops lowered from the rope rail (the one chosen answers the
  /// mission's puzzle); the backdrops lowered are saved.
  Widget _railStage(Mission m, FlyRailScene scene, GameProgress progress) => _PuzzleStage(
        key: const ValueKey('puzzle'),
        mission: m,
        hintsShown: progress.hintsFor(m.id),
        wrongPulse: _wrongPulse,
        onHint: () => _showHint(m),
        onReread: () => _rereadLetter(m),
        child: FlyRailPuzzle(
          scene: scene,
          mission: m,
          lowered: _looked(m, [for (final b in scene.rail.ropes) FlyRail.loweredKey(b.id)], progress).map((k) => k.replaceFirst('backdrop-', '')).toSet(),
          onLowered: (id) => _recordFound(m, FlyRail.loweredKey(id)),
          onSubmit: (a) => _submit(m, a),
        ),
      );

  /// The backdrop is the right one: its pocket opened before the story goes
  /// on.
  Widget _pocketStage(Mission m, FlyRailScene scene) => CenteredScroll(
        key: const ValueKey('pocket-stage'),
        padding: _stagePadding,
        children: [
          Text('MISSION ${m.numberLabel} · THE BACKDROP', textAlign: TextAlign.center, style: AppText.eyebrow()),
          const SizedBox(height: AppSpace.lg),
          PocketFound(
            scene: scene,
            mission: m,
            open: _pocketOpen,
            onOpen: () => setState(() => _pocketOpen = true),
            onContinue: () => _afterHeld(m, FlyRail.pocketId, () {
              final solve = _pocketSolve;
              _pocketSolve = null;
              return solve;
            }),
          ),
        ],
      );

  /// What was found after a solve is seen ([key] saved): the Discovery
  /// Moment with the solve's reward ([take]: null after a restart, the
  /// reward paid then), then the story.
  Future<void> _afterHeld(Mission m, String key, SubmitOutcome? Function() take) async {
    final audio = ref.read(audioServiceProvider);
    _recordFound(m, key);
    final solve = take();
    await showDiscoveryMoment(
      context,
      mission: m,
      discovery: SeasonCatalog.discovery(m),
      xp: XpBreakdown.of(m, ref.read(gameControllerProvider)),
      coins: solve?.coins ?? 0,
      firstSolve: solve?.firstSolve ?? false,
      newBadges: solve?.newBadges ?? const [],
      onEvidenceLaid: () => audio.play(GameSound.paperPlace),
      showDetective: true,
    );
    if (mounted) context.go(Routes.story(m.id));
  }

  /// The thing handed over with the letter, looked at closer (kept as seen).
  void _lookAtExhibit(Mission m, Exhibit exhibit) {
    ref.read(audioServiceProvider).play(GameSound.paperRustle);
    ref
        .read(gameControllerProvider.notifier)
        .recordExamined(GameProgress.examinedKey(m.id, exhibit.id));
    showExhibitZoom(context, exhibit);
  }

  /// A place looked round (its choice answers the mission's puzzle).
  Widget _exploreStage(Mission m, ExploreScene scene, int hintsShown) =>
      SceneExplore(
        key: const ValueKey('puzzle'),
        scene: scene,
        mission: m,
        progress: _explore,
        onChanged: () => setState(() {}),
        onChoose: (id) => _submit(m, id),
        onReread: () => _rereadLetter(m),
        onDocumentAgain: () =>
            ref.read(gameControllerProvider.notifier).recordRecheck(m),
        hintsShown: hintsShown,
        onHint: () => _showHint(m),
        wrongPulse: _wrongPulse,
      );

  Mission get _mission =>
      ref.read(currentEpisodeProvider).missionById(widget.missionId)!;

  /// A talked-to place's talk (it answers the mission's puzzle).
  Widget _talkStage(Mission m, DialogueScene talk, int hintsShown) =>
      DialogueInvestigation(
        key: const ValueKey('puzzle'),
        scene: talk,
        progress: _talk,
        onChanged: () => setState(() {}),
        onComplete: (a) => _submit(m, a),
        hints: m.hints,
        hintsShown: hintsShown,
        onHint: () => _showHint(m),
        onNotes: () =>
            ref.read(gameControllerProvider.notifier).recordRecheck(m),
      );

  /// The bar's title on a searched or talked-to place: its name, and how far
  /// the detective has got under it — two short lines that keep their size
  /// (never cut, whatever the text size).
  Widget _barTitle(String place, String count, String spoken, Key key) =>
      MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              place,
              maxLines: 1,
              style: AppText.mark(color: AppColors.goldLight, size: 17),
            ),
            Semantics(
              label: spoken,
              excludeSemantics: true,
              child: Text(
                count,
                key: key,
                style: AppText.tally(color: AppColors.paperLight),
              ),
            ),
          ],
        ),
      );

  /// The envelope was tapped: its sound starts with the seal cracking.
  void _onLetterOpening() =>
      ref.read(audioServiceProvider).play(GameSound.envelopeOpen);

  void _onLetterOpened() => setState(() => _letterOpened = true);

  /// Get More Hints: a free hint opens at once; one that costs coins asks first
  /// (see [requestTip]). A hint revealed is written onto the page, with the
  /// pencil. True when a hint was opened.
  Future<bool> _showHint(Mission m) async {
    if (ref.read(gameControllerProvider).hintsFor(m.id) >= m.hints.length) {
      return false;
    }
    final revealed = await requestTip(context, ref, m);
    if (revealed && mounted) {
      ref.read(audioServiceProvider).play(GameSound.pencilNote);
    }
    return revealed;
  }

  void _rereadLetter(Mission m) {
    ref.read(gameControllerProvider.notifier).recordRecheck(m);
    ref.read(audioServiceProvider).play(GameSound.paperRustle);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Paper, not an app sheet (this sheet only; the others keep the app's
      // sheet theme): nearly square corners, and a thin ink-brown tab in
      // place of the grey handle (it still drags to close).
      shape: paperSheetShape,
      showDragHandle: false,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            0,
            AppSpace.screen,
            AppSpace.xl,
          ),
          child: Column(
            children: [
              const PaperSheetTab(),
              LetterCard(text: m.letter),
              const SizedBox(height: AppSpace.xl),
              GameButton(
                label: 'BACK TO THE PUZZLE',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(Mission m, String answer) async {
    final controller = ref.read(gameControllerProvider.notifier);
    final audio = ref.read(audioServiceProvider);
    final outcome = controller.submitAnswer(m, answer);

    switch (outcome.result) {
      case SubmitResult.locked:
        context.go(Routes.map);
      case SubmitResult.tryAgain:
        // With the shake (it starts on this setState).
        audio.play(GameSound.puzzleWrong);
        setState(() => _wrongPulse++);
        final canHint =
            ref.read(gameControllerProvider).hintsFor(m.id) < m.hints.length;
        final choice = await showTryAgainSheet(
          context,
          hintAvailable: canHint,
          message: AnswerChecker.feedbackFor(m, answer),
          showDetective: true,
        );
        if (choice == TryAgainChoice.hint && mounted) _showHint(m);
      case SubmitResult.correct:
        // A real lock on the scene opens (a heavy one, a padlock); anything
        // else is a discovery.
        audio.play(solveSoundOf(m));
        // The keeper's ledger: its second page is read first (the moment
        // comes after it).
        if (SeasonCatalog.keeperHut(m) != null) {
          setState(() => _ledgerSolve = outcome);
          return;
        }
        // The blotter's place: Clock III is opened first.
        if (SeasonCatalog.blotter(m) != null) {
          setState(() => _hideawaySolve = outcome);
          return;
        }
        // The archive's envelope: its seal is looked at first.
        if (SeasonCatalog.archive(m) != null) {
          setState(() => _envelopeSolve = outcome);
          return;
        }
        // The stage lit like the photo: the cue card and the scrap first.
        if (SeasonCatalog.lightBoard(m) != null) {
          setState(() => _cueSolve = outcome);
          return;
        }
        // The backdrop: the pocket behind it first.
        if (SeasonCatalog.flyRail(m) != null) {
          setState(() => _pocketSolve = outcome);
          return;
        }
        final progress = ref.read(gameControllerProvider);
        await showDiscoveryMoment(
          context,
          mission: m,
          discovery: SeasonCatalog.discovery(m),
          xp: XpBreakdown.of(m, progress),
          coins: outcome.coins,
          firstSolve: outcome.firstSolve,
          newBadges: outcome.newBadges,
          onEvidenceLaid: () => audio.play(GameSound.paperPlace),
          showDetective: true,
        );
        if (mounted) context.go(Routes.story(m.id));
    }
  }

  Widget _questionFor(Mission m) => questionFor(m, (a) => _submit(m, a));

  /// A clock's hands to set (the time set answers the mission's puzzle).
  Widget _clockFor(Mission m, ClockPuzzle clock) => ClockQuestion(
    puzzle: clock,
    time: _clockTime ?? ClockTime.at(clock.start.hour, clock.start.minute),
    moved: _clockTime != null,
    onChanged: (t) => setState(() => _clockTime = t),
    onSubmit: (a) => _submit(m, a),
  );

  /// A searched place's search (it answers the mission's puzzle).
  Widget _search(Mission m, InvestigationScene scene, int hintsShown) =>
      InvestigationSearch(
        key: const ValueKey('puzzle'),
        scene: scene,
        found: _found,
        onFound: (id) => setState(() => _found.add(id)),
        onComplete: (a) => _submit(m, a),
        hints: m.hints,
        hintsShown: hintsShown,
        onHint: () => _showHint(m),
        guideShown: _guideShown,
        onGuideDone: () => setState(() => _guideShown = true),
        onReport: () =>
            ref.read(gameControllerProvider.notifier).recordRecheck(m),
      );

  @override
  Widget build(BuildContext context) {
    final episode = ref.watch(currentEpisodeProvider);
    final progress = ref.watch(gameControllerProvider);
    final m = episode.missionById(widget.missionId);
    if (m == null) return const SizedBox.shrink(); // router guard prevents this
    final solved = progress.isCompleted(m.id);
    // The mission's own scene, from its season's content.
    final scene = SeasonCatalog.investigation(m);
    final talk = SeasonCatalog.dialogue(m);
    final clock = SeasonCatalog.clock(m);
    final explore = SeasonCatalog.explore(m);
    final inspect = SeasonCatalog.inspection(m);
    final deduction = SeasonCatalog.deduction(m);
    final decode = SeasonCatalog.decode(m);
    final hall = SeasonCatalog.stationClocks(m);
    final compare = SeasonCatalog.compare(m);
    final studio = SeasonCatalog.studio(m);
    final layer = SeasonCatalog.layer(m);
    final exhibit = SeasonCatalog.exhibit(m);
    final records = SeasonCatalog.records(m);
    final lift = SeasonCatalog.lift(m);
    final dialLock = SeasonCatalog.dialLock(m);
    final marks = SeasonCatalog.riverMarks(m);
    final hut = SeasonCatalog.keeperHut(m);
    final boxes = SeasonCatalog.quayBoxes(m);
    final bench = SeasonCatalog.markCompare(m);
    final wall = SeasonCatalog.clockWall(m);
    final blotter = SeasonCatalog.blotter(m);
    final rack = SeasonCatalog.holdRack(m);
    final plan = SeasonCatalog.planRoute(m);
    final archive = SeasonCatalog.archive(m);
    final strip = SeasonCatalog.showStrip(m);
    final lights = SeasonCatalog.lightBoard(m);
    final ropes = SeasonCatalog.flyRail(m);

    final Widget body = solved
        // The ledger's second page, until it is read.
        ? hut != null && !progress.hasExamined(GameProgress.examinedKey(m.id, KeeperHutScene.page2Id))
            ? _ledgerAfterStage(m, hut)
            // Clock III opened, until what is in it is read.
            : blotter != null && !progress.hasExamined(GameProgress.examinedKey(m.id, BlotterScene.openedId))
            ? _hideawayStage(m, blotter)
            // The envelope found, until its seal is looked at.
            : archive != null && !progress.hasExamined(GameProgress.examinedKey(m.id, ArchiveDrawers.sealId))
            ? _envelopeFoundStage(m, archive)
            // The cue card and the scrap, until the scrap is found.
            : lights != null && !progress.hasExamined(GameProgress.examinedKey(m.id, LightBoard.scrapId))
            ? _cueStage(m, lights, progress)
            // The backdrop's pocket, until the slip is taken from it.
            : ropes != null && !progress.hasExamined(GameProgress.examinedKey(m.id, FlyRail.pocketId))
            ? _pocketStage(m, ropes)
            : _SolvedStage(key: const ValueKey('solved'), mission: m)
        : switch (_stage) {
            MissionStage.story =>
              // A talk starts at once: who is here is told in the talk itself.
              // A look round shows its place first, then starts at once: the
              // letter is found in the place itself.
              _StoryStage(
                key: const ValueKey('story'),
                mission: m,
                picture: explore != null
                    ? (explore.picture, explore.pixels.aspect)
                    : inspect != null
                    ? (inspect.picture, inspect.pixels.aspect)
                    : deduction != null
                    ? (deduction.picture, deduction.pixels.aspect)
                    : null,
                // A station hall: its clocks' hands drawn on it.
                // A season with pictures for its story (Paris): this place's.
                placePicture: SeasonCatalog.storyScenes(m)?.place,
                // A place read for its traces starts at once too: the notes
                // are written as the traces are found. So does a thing to
                // examine: what it hides is shown on it. (Its place keeps
                // the place's own scene: the thing is found after.)
                onInvestigate: () => _goTo(
                  talk != null ||
                          hall != null ||
                          studio != null ||
                          records != null ||
                          lift != null ||
                          marks != null ||
                          hut != null ||
                          boxes != null ||
                          bench != null ||
                          wall != null ||
                          blotter != null ||
                          rack != null ||
                          plan != null ||
                          archive != null ||
                          strip != null ||
                          lights != null ||
                          ropes != null ||
                          explore != null ||
                          inspect != null ||
                          deduction != null ||
                          decode != null
                      ? MissionStage.puzzle
                      : MissionStage.letter,
                ),
              ),
            // A searched place: the arrival in the dark, the document handed
            // over (no envelope to open), then the search.
            MissionStage.letter when scene != null => InvestigationArrival(
              key: const ValueKey('letter'),
              scene: scene,
              letter: m.letter,
              instant: _arrived,
              onArrived: () => _arrived = true,
              onStart: () => _goTo(MissionStage.puzzle),
            ),
            MissionStage.letter => _LetterStage(
              key: const ValueKey('letter'),
              mission: m,
              exhibit: exhibit,
              exhibitLooked:
                  exhibit != null &&
                  progress.hasExamined(
                    GameProgress.examinedKey(m.id, exhibit.id),
                  ),
              onExhibit: exhibit == null
                  ? null
                  : () => _lookAtExhibit(m, exhibit),
              opened: _letterOpened,
              onOpening: _onLetterOpening,
              onOpened: _onLetterOpened,
              onDone: () => _goTo(MissionStage.puzzle),
            ),
            MissionStage.puzzle when scene != null => _search(
              m,
              scene,
              progress.hintsFor(m.id),
            ),
            MissionStage.puzzle when hall != null => _stationStage(
              m,
              hall,
              progress.hintsFor(m.id),
            ),
            MissionStage.puzzle when compare != null => _compareStage(m, compare, progress.hintsFor(m.id)),
            MissionStage.puzzle when studio != null => _studioStage(m, studio, progress.hintsFor(m.id)),
            MissionStage.puzzle when layer != null => _layerStage(m, layer, progress),
            MissionStage.puzzle when records != null => _recordsStage(m, records, progress),
            MissionStage.puzzle when lift != null => _liftStage(m, lift, progress),
            MissionStage.puzzle when dialLock != null => _dialStage(m, dialLock, progress),
            MissionStage.puzzle when marks != null => _marksStage(m, marks, progress),
            MissionStage.puzzle when hut != null => _hutStage(m, hut, progress),
            MissionStage.puzzle when boxes != null => _boxesStage(m, boxes, progress),
            MissionStage.puzzle when bench != null => _benchStage(m, bench, progress),
            MissionStage.puzzle when wall != null => _clocksStage(m, wall, progress),
            MissionStage.puzzle when blotter != null => _blotterStage(m, blotter, progress),
            MissionStage.puzzle when rack != null => _rackStage(m, rack, progress),
            MissionStage.puzzle when plan != null => _planStage(m, plan, progress),
            MissionStage.puzzle when archive != null => _archiveStage(m, archive, progress),
            MissionStage.puzzle when strip != null => _stripStage(m, strip, progress),
            MissionStage.puzzle when lights != null => _lightsStage(m, lights, progress),
            MissionStage.puzzle when ropes != null => _railStage(m, ropes, progress),
            MissionStage.puzzle when explore != null => _exploreStage(
              m,
              explore,
              progress.hintsFor(m.id),
            ),
            MissionStage.puzzle when deduction != null => _deductionStage(
              m,
              deduction,
              progress.hintsFor(m.id),
            ),
            MissionStage.puzzle when decode != null => _decodeStage(
              m,
              decode,
              progress.hintsFor(m.id),
            ),
            MissionStage.puzzle when inspect != null => _inspectStage(
              m,
              inspect,
              progress.hintsFor(m.id),
            ),
            MissionStage.puzzle when talk != null => _talkStage(
              m,
              talk,
              progress.hintsFor(m.id),
            ),
            MissionStage.puzzle => _PuzzleStage(
              key: const ValueKey('puzzle'),
              mission: m,
              question: clock?.question,
              hintsShown: progress.hintsFor(m.id),
              wrongPulse: _wrongPulse,
              onHint: () => _showHint(m),
              onReread: () => _rereadLetter(m),
              child: clock == null ? _questionFor(m) : _clockFor(m, clock),
            ),
          };

    // Android back always takes the same path as the app bar arrow
    // ([_back]), on every step, the first one included. Letting the route
    // pop by itself on the place step left the answer to the route stack
    // and the platform: with nothing under the mission, an Android 16
    // device (predictive back) sends the app away instead of to the map.
    // A searched place, past its place page: in the dark, the room's picture
    // leading; the search names the place and counts what is found up top.
    final dark =
        (scene != null || talk != null) &&
        !solved &&
        _stage != MissionStage.story;
    final searching = dark && scene != null && _stage == MissionStage.puzzle;
    final talking = dark && talk != null && _stage == MissionStage.puzzle;
    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: body,
    );
    return BackTo(
      onBack: _back,
      child: Scaffold(
        backgroundColor: dark ? AppColors.navyDeep : null,
        appBar: AppBar(
          backgroundColor: dark ? AppColors.navyDeep : null,
          foregroundColor: dark ? AppColors.paperLight : null,
          systemOverlayStyle: dark
              ? AppTheme.statusOnNight
              : AppTheme.statusOnPaper,
          leading: IconButton(
            tooltip: solved || _stage == MissionStage.story
                ? 'Back to map'
                : 'Back',
            icon: const InkIcon(InkGlyph.back),
            onPressed: _back,
          ),
          // The place, and what is found so far under it: two short lines
          // that keep their size in the bar (never cut, whatever the text size).
          title: searching
              ? _barTitle(
                  m.location,
                  foundCountLabel(_found.length, scene.finds.length),
                  'Found ${_found.length} of ${scene.finds.length}',
                  const ValueKey('found-count'),
                )
              // A talk: the place only (Wave 2.2: no "n / 6" — not every
              // statement is needed; the statements are in the panel).
              : talking
              ? MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.1,
                  child: Text(
                    talk.place,
                    maxLines: 1,
                    style: AppText.mark(color: AppColors.goldLight, size: 17),
                  ),
                )
              : null,
          actions: [
            // The coins in hand (to read only), apart from the notebook button.
            CoinBalance(key: const ValueKey('coin-balance'), dark: dark),
            const SizedBox(width: AppSpace.xs),
            IconButton(
              tooltip: 'Detective notebook',
              icon: const InkIcon(InkGlyph.notebook),
              onPressed: () => context.push(Routes.notebook),
            ),
            const SizedBox(width: AppSpace.xs),
          ],
        ),
        body: dark
            // The panel under the search keeps clear of the system bar itself.
            ? InkSurface(
                night: true,
                child: SafeArea(
                  top: false,
                  bottom: !searching && !talking,
                  child: content,
                ),
              )
            : PaperBackground(
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: content,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// The page margins of the place, the letter and the puzzle: the same on
/// all three, and the same above and below, so each page's group sits in
/// the true middle when it fits ([CenteredScroll]).
const _stagePadding = EdgeInsets.symmetric(
  horizontal: AppSpace.screen,
  vertical: AppSpace.xl,
);

/// The place: its name, and the story's title in a quiet line below.
class _PlaceHeading extends StatelessWidget {
  const _PlaceHeading({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    return PageHeading(
      eyebrow: 'MISSION ${mission.numberLabel}',
      title: mission.location,
      subtitle: mission.title,
    );
  }
}

/// A place's story picture ([StoryPicture]) on its page: a print, a little
/// askew, no taller than about two fifths of the screen (a tall part of a
/// scene is printed narrower); or a thing seen up close through a brass
/// lens.
class _PlacePicture extends StatelessWidget {
  const _PlacePicture({required this.picture});

  final StoryPicture picture;

  @override
  Widget build(BuildContext context) {
    final p = picture;
    final tallest = MediaQuery.sizeOf(context).height * 0.4;
    return LayoutBuilder(
      builder: (context, box) {
        if (p.frame == StoryFrame.lens) {
          final side = math.min(math.min(box.maxWidth * 0.72, tallest), 260.0);
          return Center(
            child: Container(
              key: const ValueKey('story-lens'),
              width: side,
              height: side,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.goldDeep, width: 6),
                boxShadow: AppShadow.paperLift,
              ),
              child: ClipOval(
                child: StoryPictureView(
                  p,
                  imageKey: const ValueKey('story-picture'),
                ),
              ),
            ),
          );
        }
        final width = math.min(
          box.maxWidth - 2 * AppSpace.sm,
          tallest * p.aspect,
        );
        return Center(
          child: PaperSheet(
            padding: const EdgeInsets.all(AppSpace.sm),
            tilt: -0.01,
            child: SizedBox(
              width: width,
              height: width / p.aspect,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: StoryPictureView(
                  p,
                  imageKey: const ValueKey('story-picture'),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// STEP 1 — the place. One action: investigate.
class _StoryStage extends StatelessWidget {
  const _StoryStage({
    super.key,
    required this.mission,
    required this.onInvestigate,
    this.picture,
    this.placePicture,
  });

  final Mission mission;
  final VoidCallback onInvestigate;

  /// The place as the story has got to it (Paris: the hall whole, the desk,
  /// the old clock through a lens), in place of [picture].
  final StoryPicture? placePicture;

  /// The place's own picture (its file and width / height) in place of the
  /// mission's scene: a place looked round shows the place it is looked
  /// round in (the scene elsewhere — the case photo, the board — stays).
  final (String, double)? picture;

  @override
  Widget build(BuildContext context) {
    final m = mission;
    final own = picture;
    // The heading, the picture, the story and the way in are one group:
    // centred under the bar when they fit, scrolled from the top when not.
    return CenteredScroll(
      padding: _stagePadding,
      children: [
        _PlaceHeading(mission: m),
        const SizedBox(height: AppSpace.xl),
        // The scene, printed like a picture in a storybook.
        // A square picture (the raven, the suitcase) is kept a page-size
        // print, so the story still starts on the first screen.
        if (placePicture case final p?)
          _PlacePicture(picture: p)
        else
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    own == null &&
                        LandmarkArt.aspectOf(PlaceArt.sceneOf(m)) < 1.2
                    ? 240
                    : double.infinity,
              ),
              child: PaperSheet(
                padding: const EdgeInsets.all(AppSpace.sm),
                tilt: -0.01,
                child: own == null
                    ? AspectRatio(
                        aspectRatio: LandmarkArt.aspectOf(PlaceArt.sceneOf(m)),
                        child: LandmarkArt(
                          PlaceArt.sceneOf(m),
                          borderRadius: 2,
                        ),
                      )
                    : AspectRatio(
                        aspectRatio: own.$2,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Image.asset(
                            own.$1,
                            key: const ValueKey('story-picture'),
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        const SizedBox(height: AppSpace.xl),
        for (final (i, line) in m.story.indexed)
          _FadeIn(
            delay: Duration(milliseconds: 150 + i * 400),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: GlossaryText(
                line,
                style: AppText.bodyText(size: 19),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        const SizedBox(height: AppSpace.xl),
        // The player's detective, magnifying glass up, by the way in.
        WithPlayerDetective(
          moment: DetectiveMoment.investigate,
          child: GameButton(
            label: 'INVESTIGATE',
            arrow: true,
            singleLine: true, // beside the detective on a 360-wide phone
            tap: TapRole.primary,
            onPressed: onInvestigate,
          ),
        ),
      ],
    );
  }
}

// STEP 2 — the letter. One action at a time: open it, then go solve.
class _LetterStage extends StatelessWidget {
  const _LetterStage({
    super.key,
    required this.mission,
    required this.opened,
    required this.onOpening,
    required this.onOpened,
    required this.onDone,
    this.exhibit,
    this.exhibitLooked = false,
    this.onExhibit,
  });

  final Mission mission;

  /// A thing handed over with the letter (the lost ticket), laid above it.
  final Exhibit? exhibit;
  final bool exhibitLooked;
  final VoidCallback? onExhibit;
  final bool opened;
  final VoidCallback onOpening;
  final VoidCallback onOpened;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    // The intro, the letter, the dotted-word note and the button are one
    // group: centred under the bar when the letter is short, read from the
    // top and scrolled when it is long.
    return CenteredScroll(
      padding: _stagePadding,
      children: [
        GlossaryText(
          mission.letterIntro,
          style: AppText.aside(size: 19, color: AppColors.inkBrown),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpace.xl),
        if (exhibit != null) ...[
          ExhibitObject(
            exhibit: exhibit!,
            looked: exhibitLooked,
            onOpen: onExhibit!,
          ),
          const SizedBox(height: AppSpace.xl),
        ],
        EnvelopeReveal(
          letterText: mission.letter,
          initiallyOpen: opened,
          onOpen: onOpening,
          onOpened: onOpened,
        ),
        // The note and the button arrive with a short grow, so the centred
        // group eases up to make room instead of jumping.
        AnimatedSize(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: !opened
                ? const SizedBox(key: ValueKey('sealed'), height: AppSpace.xl)
                : Column(
                    key: const ValueKey('open'),
                    children: [
                      const SizedBox(height: AppSpace.lg),
                      Text(
                        'Tap a dotted word to see what it means.',
                        style: AppText.caption(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpace.xl),
                      GameButton(
                        label: 'SOLVE THE PUZZLE',
                        arrow: true,
                        tap: TapRole.primary,
                        onPressed: onDone,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// STEP 3 — the puzzle. One action: answer. The letter and tips are quiet
// helpers, opened only when the detective wants them. (A searched place has
// its own search instead: `InvestigationSearch`.)
class _PuzzleStage extends StatelessWidget {
  const _PuzzleStage({
    super.key,
    required this.mission,
    this.question,
    required this.hintsShown,
    required this.wrongPulse,
    required this.onHint,
    required this.onReread,
    required this.child,
  });

  final Mission mission;

  /// The heading in place of the mission's question, when the puzzle is
  /// played another way than the question says (a clock to set, not a
  /// time to type).
  final String? question;
  final int hintsShown;
  final int wrongPulse;
  final VoidCallback onHint;
  final VoidCallback onReread;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tipLabel = nextTipLabel(mission.hints, hintsShown);
    // From the heading to Reread Letter and the tip, one group: centred
    // under the bar when it fits (whatever the puzzle's size), scrolled from
    // the top when it does not — a small phone, large text, the keyboard up.
    return CenteredScroll(
      padding: _stagePadding,
      children: [
        Text(
          'MISSION ${mission.numberLabel} · THE PUZZLE',
          textAlign: TextAlign.center,
          style: AppText.eyebrow(),
        ),
        const SizedBox(height: AppSpace.sm),
        GlossaryText(
          question ?? mission.question,
          style: AppText.title(size: 24),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpace.md),
        const Center(child: OrnamentRule()),
        const SizedBox(height: AppSpace.xl),
        ShakeOnChange(trigger: wrongPulse, child: child),
        const SizedBox(height: AppSpace.lg),
        DetectiveTipNotes(hints: mission.hints, revealed: hintsShown),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpace.sm,
          children: [
            InkTextButton(
              label: 'Reread Letter',
              glyph: InkGlyph.letter,
              onPressed: onReread,
            ),
            if (tipLabel != null)
              InkTextButton(
                label: tipLabel,
                glyph: InkGlyph.hint,
                color: tipLinkColor,
                onPressed: onHint,
              ),
          ],
        ),
      ],
    );
  }
}

class _SolvedStage extends ConsumerWidget {
  const _SolvedStage({super.key, required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episode = ref.watch(currentEpisodeProvider);
    final clues = ref.watch(gameControllerProvider).collectedClues(episode);
    final m = mission;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.sm,
        AppSpace.screen,
        AppSpace.xxl,
      ),
      children: [
        _PlaceHeading(mission: m),
        const SizedBox(height: AppSpace.lg),
        const Center(child: InkStamp('SOLVED', color: AppColors.success)),
        const SizedBox(height: AppSpace.md),
        Text(
          DetectiveName.address(
            m.successMessage,
            ref.watch(gameControllerProvider).detectiveName,
          ),
          style: AppText.bodyText(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpace.xl),
        LetterCard(text: m.letter),
        if (m.clue != null) ...[
          const SizedBox(height: AppSpace.lg),
          ClueCard(
            clue: m.clue!,
            index: clues.indexWhere((c) => c.id == m.clue!.id),
            location: m.location,
          ),
        ],
        if (m.evidence != null) ...[
          const SizedBox(height: AppSpace.md),
          // The same tile height as the notebook grid (grows with larger text).
          SizedBox(
            height: evidenceTileHeight(context),
            child: EvidenceTile(evidence: m.evidence!, location: m.location),
          ),
        ],
        const SizedBox(height: AppSpace.xl),
        GameButton(
          label: 'BACK TO MAP',
          onPressed: () => context.go(Routes.map),
        ),
      ],
    );
  }
}

class _FadeIn extends StatefulWidget {
  const _FadeIn({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 400),
      child: widget.child,
    );
  }
}
