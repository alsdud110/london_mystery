import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/answer_checker.dart';
import '../../core/utils/audio_service.dart';
import '../../data/mock/season1/season1_sounds.dart';
import '../../data/mock/season_catalog.dart';
import '../../data/models/abbesses_puzzles.dart';
import '../../data/models/game_progress.dart';
import '../../data/models/garden_puzzles.dart';
import '../../data/models/letter_puzzles.dart';
import '../../data/models/mission.dart';
import '../../data/models/opera_puzzles.dart';
import '../../data/models/painter_puzzles.dart';
import '../../data/models/river_puzzles.dart';
import '../../data/models/scene_exhibit.dart';
import '../../data/models/tower_puzzles.dart';
import '../../data/models/workshop_puzzles.dart';
import '../../widgets/clue_card.dart';
import '../../widgets/coin_balance.dart';
import '../../widgets/evidence_card.dart';
import '../../widgets/game_button.dart';
import '../../widgets/glossary_text.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/landmark_art.dart';
import '../../widgets/letter_card.dart';
import '../../widgets/paper.dart';
import '../../widgets/place_art.dart';
import '../../widgets/art_assets.dart';
import '../../widgets/desk_background.dart';
import '../../widgets/royal_box_picture.dart';
import '../../widgets/symbol_icon.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../game/scoring.dart';
import 'widgets/answer_feedback.dart';
import 'widgets/canvas_choice.dart';
import 'widgets/clockwork_garden.dart';
import 'widgets/evidence_board.dart';
import 'widgets/letter_lock.dart' show LetterLockQuestion, LetterLockReveal;
import 'widgets/letter_map.dart';
import 'widgets/light_table.dart';
import 'widgets/lock_box.dart';
import 'widgets/post_trail.dart';
import 'widgets/question_widgets.dart';
import 'widgets/street_book.dart';
import 'widgets/tip_shop.dart';
import 'widgets/torn_hour.dart';
import '../../data/models/detective_name.dart';

/// The final case: four picture locks. The player must combine what they
/// collected — the lock order (Crown Symbol evidence) and the number each
/// place gave them (clues) — to open the Royal Box.
class FinalMissionScreen extends ConsumerStatefulWidget {
  const FinalMissionScreen({super.key});

  @override
  ConsumerState<FinalMissionScreen> createState() => _FinalMissionScreenState();
}

class _FinalMissionScreenState extends ConsumerState<FinalMissionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..addListener(_ringBell);
  final _scroll = ScrollController();
  late List<int> _digits;
  int _wrongPulse = 0;

  /// The locks (question, dials, OPEN): a returning detective lands here,
  /// and the letter is one tap away instead of a scroll back up.
  final _locksKey = GlobalKey();

  Mission get _mission => ref.read(currentEpisodeProvider).finalMission;

  /// A letter lock on a box of its own pictures (Paris Case 01's brass box),
  /// or null: the case's place behind the lock.
  LockBoxArt? get _box => SeasonCatalog.lockBox(_mission);

  /// Canvases to look at and turn round (Paris Case 02), or null.
  CanvasScene? get _canvases => SeasonCatalog.canvasChoice(_mission);

  /// Evidence linked to questions, the time-recording machine on the stage
  /// (Paris Case 03), or null.
  EvidenceBoardScene? get _board => SeasonCatalog.evidenceBoard(_mission);

  /// The board as it is (saved as it changes: `GameProgress.puzzleStates`),
  /// and the question being linked (kept while the page is open).
  Map<String, Set<String>> _links = {};
  String? _conclusion;
  String? _question;

  /// The street book, the keeper's hut and the gate on the stage (Paris
  /// Case 04), or null.
  StreetBookScene? get _book => SeasonCatalog.streetBook(_mission);

  /// The addresses crossed out, with their evidence (saved as they change:
  /// `GameProgress.puzzleStates`); the address picked and the evidence
  /// chosen for it (kept while the page is open).
  Map<String, Set<String>> _crossed = {};
  String? _address;
  Set<String> _picked = {};

  /// The post's slips under the workshop door (Paris Case 05), or null.
  PostTrailScene? get _trail => SeasonCatalog.postTrail(_mission);

  /// The letter and the map of Paris (Paris Case 06), or null.
  LetterMapScene? get _letterMap => SeasonCatalog.letterMap(_mission);

  /// The archive's light table and the Amendment Slip (Paris Case 07), or
  /// null.
  LightTableScene? get _lightTable => SeasonCatalog.lightTable(_mission);

  /// The torn paper laid on P.'s drawing, then the board, then P.'s last
  /// drawing (Paris Case 08), or null.
  TornHourScene? get _tornHour => SeasonCatalog.tornHour(_mission);

  /// The tower set one hour back and tested, then the question, then the
  /// star followed (Paris Case 09), or null.
  TowerTestScene? get _tower => SeasonCatalog.towerTest(_mission);

  /// The hour the tower is set to (saved as it changes: `hour=3`).
  int _hour = 4;

  String get _testedKey => GameProgress.examinedKey(_mission.id, TowerTestScene.testedId);
  String get _starKey => GameProgress.examinedKey(_mission.id, TowerTestScene.leadId);

  void _setHour(int hour) {
    setState(() => _hour = hour);
    ref.read(gameControllerProvider.notifier).recordPuzzleState(_mission.id, 'hour=$hour');
  }

  void _testTower() => _nextTableStep(TowerTestScene.testedId);

  Future<void> _followStar() async {
    final done = await showStarLead(context, _tower!.lead);
    if (done == true && mounted) {
      // The last step done: now the case is closed (solved, the next case
      // file open), never with the answer alone.
      ref.read(gameControllerProvider.notifier).closeCase(_starKey);
      setState(() {});
    }
  }

  /// The board of this final (Case 03's, or Case 08's after its paper is
  /// laid on the drawing), or null.
  EvidenceBoardSpec? get _boardSpec => _board ?? _tornHour?.board;

  String _tableKey(String thing) => GameProgress.examinedKey(_mission.id, thing);

  bool _tableDone(String thing) => ref.watch(gameControllerProvider).hasExamined(_tableKey(thing));

  /// The final's story, opened again once it has been read (it folds away
  /// while FILE 3 is worked on, so the table is in sight).
  bool _storyOpen = false;

  /// A step of the light table done: its next step brought into view.
  void _nextTableStep(String thing) {
    _recordTable(thing);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locks = _locksKey.currentContext;
      if (!mounted || locks == null || !locks.mounted) return;
      Scrollable.ensureVisible(
        locks,
        alignment: 0.02,
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _recordTable(String thing) => ref.read(gameControllerProvider.notifier).recordExamined(_tableKey(thing));

  /// A wrong record or pin, checked as part of the answer (said why); or
  /// the pins right, the whole answer.
  Future<void> _submitTable(String answer) async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await _submit(answer);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _turnSlip() async {
    ref.read(audioServiceProvider).play(GameSound.paperRustle);
    _recordTable(ChangedRecord.slipBackId);
    await showSlipBack(context, scene: _lightTable!);
    if (mounted) setState(() {});
  }

  void _lookAtBuilding(String id) =>
      ref.read(gameControllerProvider.notifier).recordExamined(GameProgress.examinedKey(_mission.id, LetterMap.lookedKey(id)));

  Future<void> _chooseBuilding(String id) async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await _submit(id);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  /// The slips set on the trail (saved as they change:
  /// `GameProgress.puzzleStates`), and the slip picked (kept while the page
  /// is open).
  Map<String, String> _placed = {};
  String? _slipPicked;

  void _pickSlip(String id) {
    ref.read(gameControllerProvider.notifier).recordExamined(GameProgress.examinedKey(_mission.id, PostTrailScene.slipsId));
    setState(() => _slipPicked = _slipPicked == id ? null : id);
  }

  /// A slot tapped: the slip picked is set there (off any other slot); with
  /// none picked, the slip there is taken off.
  void _setSlot(String slot) {
    final trail = _trail!;
    final id = _slipPicked;
    setState(() {
      final placed = {..._placed};
      if (id == null) {
        placed.remove(slot);
      } else {
        placed.removeWhere((_, v) => v == id);
        placed[slot] = id;
        _slipPicked = null;
      }
      _placed = placed;
    });
    ref.read(gameControllerProvider.notifier).recordPuzzleState(_mission.id, TrailState.encode(_placed, trail));
  }

  Future<void> _followLetter() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await _submit(_trail!.answerOf(_placed));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  /// Where the gate's scrap counts as taken and read.
  String get _gateKey => GameProgress.examinedKey(_mission.id, StreetBookScene.gateId);

  void _pickAddress(String id) => setState(() {
        _address = _address == id ? null : id;
        _picked = {};
      });

  void _pickEvidence(String id) => setState(() {
        final set = {..._picked};
        set.contains(id) ? set.remove(id) : set.add(id);
        if (set.length <= _book!.maxEvidence) _picked = set;
      });

  /// An address crossed out with the evidence chosen: struck through when
  /// the evidence rules it out; otherwise checked (a wrong answer, said why).
  Future<void> _crossOut() async {
    final book = _book!;
    final address = _address;
    if (address == null || _picked.isEmpty || _checking) return;
    final part = book.partOf(address, _picked);
    if (Mission.sequenceIds(_mission.answer).contains(part)) {
      ref.read(audioServiceProvider).play(GameSound.paperPlace);
      setState(() {
        _crossed = {..._crossed, address: {..._picked}};
        _address = null;
        _picked = {};
      });
      ref.read(gameControllerProvider.notifier).recordPuzzleState(_mission.id, CrossOutState.encode(_crossed, book));
      return;
    }
    setState(() => _checking = true);
    try {
      await _submit(part);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _submitAddress() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await _submit(_book!.answerOf(_crossed));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _openGate() async {
    ref.read(audioServiceProvider).play(GameSound.paperRustle);
    await showGateReveal(
      context,
      scene: _book!,
      evidence: _mission.evidence,
      onRead: () => ref.read(gameControllerProvider.notifier).recordExamined(_gateKey),
    );
    if (mounted) setState(() {});
  }

  /// The street book's evidence, by its id in the answer.
  Map<String, Evidence> _bookEvidence(StreetBookScene book) {
    final all = {for (final e in ref.read(currentEpisodeProvider).allEvidence) e.id: e};
    return {
      for (final e in book.evidence) e.id: ?all[e.evidenceId],
    };
  }

  /// Where the plaque in the machine counts as read.
  String get _plaqueKey => GameProgress.examinedKey(_mission.id, EvidenceBoardScene.plaqueId);

  void _saveBoard() => ref
      .read(gameControllerProvider.notifier)
      .recordPuzzleState(_mission.id, BoardState.encode(_links, _conclusion, _boardSpec!));

  void _pickQuestion(String id) => setState(() => _question = _question == id ? null : id);

  void _link(String evidence) {
    final q = _question;
    if (q == null) return;
    setState(() {
      final set = {...?_links[q]};
      set.contains(evidence) ? set.remove(evidence) : set.add(evidence);
      _links = {..._links, q: set};
    });
    _saveBoard();
  }

  void _conclude(String id) {
    setState(() => _conclusion = id);
    _saveBoard();
  }

  Future<void> _solveBoard() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await _submit(boardAnswerOf(_boardSpec!, _links, _conclusion));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _readPlaque() async {
    ref.read(audioServiceProvider).play(GameSound.paperRustle);
    ref.read(gameControllerProvider.notifier).recordExamined(_plaqueKey);
    await showBrassPlaque(context, scene: _board!, evidence: _mission.evidence);
    if (mounted) setState(() {});
  }

  /// The evidence on the board, by its board id: the case's own, and an
  /// earlier case's given on it (Case 08: Case 07's Amendment Slip).
  Map<String, Evidence> _boardEvidence(EvidenceBoardSpec board) {
    final all = {
      for (final episode in ref.read(allEpisodesProvider))
        for (final e in episode.allEvidence) e.id: e,
      for (final e in ref.read(currentEpisodeProvider).allEvidence) e.id: e,
    };
    return {
      for (final e in board.evidence) e.id: ?all[e.evidenceId],
    };
  }

  /// Where the torn paper laid on the drawing, and P.'s last drawing looked
  /// at, are kept (Case 08).
  String get _placedKey => GameProgress.examinedKey(_mission.id, TornHourScene.placedId);
  String get _leadKey => GameProgress.examinedKey(_mission.id, TornHourScene.leadId);

  void _placePaper() {
    ref.read(audioServiceProvider).play(GameSound.paperPlace);
    _nextTableStep(TornHourScene.placedId);
  }

  Future<void> _lookAtLastDrawing() async {
    ref.read(audioServiceProvider).play(GameSound.paperRustle);
    final done = await showNextLead(context, _tornHour!.lead);
    if (done == true && mounted) {
      // The last step done: now the case is closed (solved, the next case
      // file open), never with the answer alone.
      ref.read(gameControllerProvider.notifier).closeCase(_leadKey);
      setState(() {});
    }
  }

  /// The canvas looked at, and the canvases looked at (saved, so they stay
  /// looked at after a restart).
  String _looking = '';
  final Set<String> _looked = {};
  bool _checking = false;

  String _canvasKey(String id) => GameProgress.examinedKey(_mission.id, id);

  /// Where the back of the right canvas counts as read.
  String get _backKey => GameProgress.examinedKey(_mission.id, 'back');

  void _lookAt(String id) {
    setState(() {
      _looking = id;
      _looked.add(id);
    });
    ref.read(gameControllerProvider.notifier).recordExamined(_canvasKey(id));
  }

  Future<void> _turnCanvas() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await _submit(_looking);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _readBack() async {
    ref.read(gameControllerProvider.notifier).recordExamined(_backKey);
    await showCanvasBack(context, scene: _canvases!, evidence: _mission.evidence);
    if (mounted) setState(() {});
  }

  /// The letters in the lock's slots, as the box shows them.
  List<String?> _lockLetters = const [];

  /// Where what was found in the box counts as looked at (its back read).
  String? get _insideKey => _box == null ? null : GameProgress.examinedKey(_mission.id, _box!.examineId);

  @override
  void initState() {
    super.initState();
    final length = _mission.codeLength ?? _mission.answer.length;
    _digits = List.filled(length, 0);
    final progress = ref.read(gameControllerProvider);
    if (_boardSpec case final board?) {
      final (links, conclusion) = BoardState.decode(progress.puzzleStateOf(_mission.id), board);
      _links = links;
      _conclusion = conclusion;
    }
    if (_book case final book?) {
      _crossed = CrossOutState.decode(progress.puzzleStateOf(_mission.id), book);
    }
    if (_trail case final trail?) {
      _placed = TrailState.decode(progress.puzzleStateOf(_mission.id), trail);
    }
    if (_tower case final tower?) {
      final saved = int.tryParse((progress.puzzleStateOf(_mission.id) ?? '').replaceFirst('hour=', ''));
      _hour = progress.hasExamined(_testedKey) ? tower.targetHour : (saved != null && saved >= 1 && saved <= 12 ? saved : tower.startHour);
    }
    final canvases = _canvases;
    if (canvases != null) {
      for (final c in canvases.canvases) {
        if (progress.hasExamined(_canvasKey(c.id))) _looked.add(c.id);
      }
      // Solved: the right one, turned round. Otherwise the first canvas is
      // looked at.
      _looking = progress.isCaseSolved ? _mission.answer : canvases.canvases.first.id;
      if (!progress.isCaseSolved && _looked.add(_looking)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.read(gameControllerProvider.notifier).recordExamined(_canvasKey(_looking));
        });
      }
    }
    // Answered: open on the solve (the case closed, or its last step to do).
    if (progress.isCaseSolved || progress.finalAwaitsLastStep(ref.read(currentEpisodeProvider))) {
      _open.value = 1;
    } else {
      // Back again (the story and the letter were read before): open on the locks.
      final returning = progress.missionStartedAt.containsKey(_mission.id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(gameControllerProvider.notifier)
            .markMissionStarted(_mission.id);
        final locks = _locksKey.currentContext;
        if (returning && locks != null && locks.mounted) {
          Scrollable.ensureVisible(locks, alignment: 0.05);
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The Royal Box's pictures decoded ahead: shut on arrival, and open the
    // moment the code is right (never a blank frame as the lid swings).
    final box = _box;
    final canvases = _canvases;
    final board = _board;
    final book = _book;
    final trail = _trail;
    final letters = _letterMap;
    final table = _lightTable;
    final hour = _tornHour;
    final tower = _tower;
    if (_precached || (_mission.scene != Artwork.royalBox && box == null && canvases == null && board == null && book == null && trail == null && letters == null && table == null && hour == null && tower == null)) return;
    _precached = true;
    final files = tower != null
        ? [tower.garden, tower.dialFile, tower.lead.mapFile, for (final m in tower.lead.models) m.file]
        : hour != null
        ? [hour.sketch.file, hour.study.file, hour.form.file, hour.form.stamp, hour.lead.file, hour.lead.mapFile]
        : table != null
        ? [table.archive, table.table, table.tableOn, table.file3.file, table.file3.patch.file, table.slip.file, table.slip.stamp]
        : letters != null
        ? [letters.letter.file, letters.letter.sketch, letters.mapFile]
        : trail != null
        ? [trail.stage, trail.slip, trail.receipt.file]
        : book != null
        ? [book.hut, book.book, book.gate, book.label.file, book.label.back]
        : board != null
        ? [board.shut, board.open, board.plaque]
        : canvases != null
        ? [for (final c in canvases.canvases) c.file, canvases.back]
        : box == null
        ? [ArtAssets.royalBox.closed, ArtAssets.royalBox.open]
        : [box.closed, box.open, box.found];
    for (final file in files) {
      precacheImage(AssetImage(file), context, onError: (_, _) {});
    }
  }

  bool _precached = false;

  /// A lock box's stage height for a page [width] wide: the shut box fitted
  /// to the width; no taller than a third of the [screen] and 300.
  static double _boxStage(LockBoxArt box, double width, double screen) =>
      (width / box.closedPixels.aspect).clamp(150.0, math.min(300.0, math.max(150.0, screen * 0.36)));

  /// The Royal Box's stage height for a page [width] wide: the open box,
  /// fitted to the width, on a [screen] at least so tall; no taller than a
  /// third of the screen and 320, no shorter than 150.
  static double _royalBoxStage(double width, double screen) {
    final open = ArtAssets.royalBox.opened;
    final aspect = ArtAssets.sceneAspects[Artwork.royalBox]! * open.width / open.height;
    return (width / aspect).clamp(150.0, math.min(320.0, math.max(150.0, screen * 0.36)));
  }

  @override
  void dispose() {
    _open.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Solved just now (not a revisit): the case's bell, if it has one, may ring.
  bool _solvedNow = false;
  bool _rung = false;

  /// What this solve paid, shown above CONTINUE: its XP and the coins
  /// actually added (0 when the case was paid before, e.g. played again).
  int _xpEarned = 0;
  int _coinsEarned = 0;
  bool _firstSolve = true;

  /// Big Ben rings as the news comes up ("Big Ben rings again!", at 0.55 of
  /// the opening), after the clock has caught: once.
  void _ringBell() {
    if (!_solvedNow ||
        _rung ||
        _open.value < 0.55 ||
        !ringsBellOnSolve(_mission)) {
      return;
    }
    _rung = true;
    ref.read(audioServiceProvider).play(GameSound.bigBenBell);
  }

  void _turn(int index, int delta) {
    ref.read(audioServiceProvider).play(GameSound.lockDialClick);
    setState(() => _digits[index] = (_digits[index] + delta) % 10);
  }

  /// GET MORE HINTS: a free hint opens at once; one that costs coins asks first
  /// (see [requestTip]). A hint revealed is written onto the page, with the
  /// pencil.
  Future<void> _showHint() async {
    if (ref.read(gameControllerProvider).hintsFor(_mission.id) >=
        _mission.hints.length) {
      return;
    }
    if (await requestTip(context, ref, _mission) && mounted) {
      ref.read(audioServiceProvider).play(GameSound.pencilNote);
    }
  }

  Future<void> _tryOpen() => _submit(_digits.join());

  Future<void> _submit(String answer) async {
    final audio = ref.read(audioServiceProvider);
    final outcome = ref
        .read(gameControllerProvider.notifier)
        .submitAnswer(_mission, answer);
    switch (outcome.result) {
      case SubmitResult.locked:
        context.go(Routes.map);
      case SubmitResult.tryAgain:
        // With the shake (it starts on this setState).
        audio.play(GameSound.puzzleWrong);
        setState(() => _wrongPulse++);
        final canHint =
            ref.read(gameControllerProvider).hintsFor(_mission.id) <
            _mission.hints.length;
        final choice = await showTryAgainSheet(
          context,
          hintAvailable: canHint,
          message: AnswerChecker.feedbackFor(_mission, answer),
          showDetective: true,
        );
        if (choice == TryAgainChoice.hint && mounted) _showHint();
      case SubmitResult.correct:
        _solvedNow = true;
        _xpEarned = XpBreakdown.of(
          _mission,
          ref.read(gameControllerProvider),
        ).total;
        _coinsEarned = outcome.coins;
        _firstSolve = outcome.firstSolve;
        // A thing of the story (the Royal Box, the Great Clock, a heavy
        // lock) sounds as it opens on screen; otherwise the final's cue now.
        final sound = solveSoundOf(_mission);
        if (sound == GameSound.finale) audio.play(sound);
        // Bring the box into view so the child sees it open.
        // (The puzzle is removed now, so wait a frame for the new layout.)
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        if (_scroll.hasClients && _scroll.offset > 0) {
          await _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        }
        if (!mounted) return;
        if (sound != GameSound.finale) audio.play(sound);
        await _open.forward();
    }
  }

  void _rereadLetter() {
    ref.read(gameControllerProvider.notifier).recordRecheck(_mission);
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
              LetterCard(text: _mission.letter),
              const SizedBox(height: AppSpace.xl),
              GameButton(
                label: 'BACK TO THE LOCKS',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// What lies in the open box, looked at closer; its back read the first
  /// time is kept (the case goes on from there).
  Future<void> _lookInside() async {
    final box = _box!;
    ref.read(audioServiceProvider).play(GameSound.paperRustle);
    await showFoundInspect(
      context,
      art: box,
      evidence: _mission.evidence,
      backRead: ref.read(gameControllerProvider).hasExamined(_insideKey!),
      onBackRead: () => ref.read(gameControllerProvider.notifier).recordExamined(_insideKey!),
    );
  }

  void _peekNotebook() {
    ref.read(audioServiceProvider).play(GameSound.notebookOpen);
    final episode = ref.read(currentEpisodeProvider);
    final progress = ref.read(gameControllerProvider);
    final clues = progress.collectedClues(episode);
    final evidence = progress.collectedEvidence(episode);
    String locationOfClue(Clue c) =>
        episode.allMissions.firstWhere((m) => m.clue?.id == c.id).location;
    String locationOfEvidence(Evidence e) =>
        episode.allMissions.firstWhere((m) => m.evidence?.id == e.id).location;
    // Operator mode opens earlier files for reference (see the archive).
    final earlierCases =
        ref
            .read(seasonProvider)
            .solvedEpisodeIds
            .any((id) => id != episode.id) ||
        ref.read(operatorAccessProvider);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Paper, not an app sheet (this sheet only; the others keep the app's
      // sheet theme): nearly square corners, and a thin ink-brown tab in
      // place of the grey handle (it still drags to close).
      shape: paperSheetShape,
      showDragHandle: false,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (context, scroll) => Column(
          children: [
            // Fixed above the scrolling notebook, as the handle was.
            const PaperSheetTab(),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Text(
                    'DETECTIVE NOTEBOOK',
                    style: AppText.mark(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text('Evidence', style: AppText.title(size: 20)),
                  const SizedBox(height: 8),
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: evidenceGridDelegate(context),
                    children: [
                      for (final e in evidence)
                        EvidenceTile(
                          evidence: e,
                          location: locationOfEvidence(e),
                          onOpened: () => ref
                              .read(gameControllerProvider.notifier)
                              .recordEvidenceViewed(e.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Clues', style: AppText.title(size: 20)),
                  const SizedBox(height: 8),
                  for (final (i, c) in clues.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ClueCard(
                        clue: c,
                        index: i,
                        location: locationOfClue(c),
                      ),
                    ),
                  // Earlier cases (e.g. Case 12 needs them): their evidence is in
                  // the archive. Hidden while no other case has been solved.
                  if (earlierCases) ...[
                    const SizedBox(height: 8),
                    GameButton(
                      label: 'OPEN THE CASE ARCHIVE',
                      glyph: InkGlyph.folder,
                      style: GameButtonStyle.outline,
                      // The notebook opens on its archive: its own sound, no tap.
                      onPressed: () {
                        Navigator.of(context).pop();
                        this.context.push(Routes.archive);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(currentEpisodeProvider).finalMission;
    final progress = ref.watch(gameControllerProvider);
    // Answered: the case closed, or its last step after the answer to do
    // (Paris Case 08's last drawing; the case closes with it).
    final solved = progress.isCaseSolved || progress.finalAwaitsLastStep(ref.watch(currentEpisodeProvider));
    final box = _box;
    final canvases = _canvases;
    final board = _board;
    final book = _book;
    final trail = _trail;
    final letters = _letterMap;
    final table = _lightTable;
    final hour = _tornHour;
    final tower = _tower;

    return Scaffold(
      // The night page runs up under the app bar (no paper band on top).
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        foregroundColor: AppColors.goldLight,
        iconTheme: const IconThemeData(color: AppColors.goldLight),
        titleTextStyle: AppText.mark(color: AppColors.goldLight, size: 17),
        title: const Text('FINAL MISSION'),
        leading: IconButton(
          tooltip: 'Back to map',
          icon: const InkIcon(InkGlyph.back),
          onPressed: () => context.go(Routes.map),
        ),
        // The coins in hand (to read only): a hint here may cost some.
        actions: const [
          CoinBalance(key: ValueKey('coin-balance'), dark: true),
          SizedBox(width: AppSpace.lg),
        ],
      ),
      // The last evidence and papers, examined on the detective's desk.
      body: DeskBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              // Built whole (not lazily), so the page can open on the locks.
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.xl,
                  AppSpace.sm,
                  AppSpace.xl,
                  AppSpace.xxxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The app bar already says FINAL MISSION: the page starts on the place.
                    Text(
                      m.location,
                      style: AppText.logo(size: 28, color: AppColors.goldLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    const Center(
                      child: OrnamentRule(color: AppColors.goldLight),
                    ),
                    const SizedBox(height: 12),
                    // A smaller stage on a small phone, so the story and the locks
                    // come sooner; the full 250 on taller screens. The Royal Box
                    // gets the height its picture needs at this width (the open
                    // box, looked at a little closer, the Crown large). Canvases
                    // are looked at by their choice, the clues in view above
                    // them: the stage shows the right one, turned round.
                    if (canvases == null || solved)
                    LayoutBuilder(
                      builder: (context, stage) => SizedBox(
                        height: m.scene == Artwork.royalBox
                            ? _royalBoxStage(stage.maxWidth, MediaQuery.sizeOf(context).height)
                            : tower != null
                            ? (stage.maxWidth / tower.gardenPixels.aspect)
                                .clamp(150.0, math.min(280.0, math.max(150.0, MediaQuery.sizeOf(context).height * 0.3)))
                            : hour != null
                            // Slim while the paper is laid on the drawing
                            // below (the drawing is there too); whole after.
                            ? (!solved && !progress.hasExamined(_placedKey))
                                ? 96.0
                                : (stage.maxWidth / hour.sketch.pixels.aspect)
                                    .clamp(150.0, math.min(320.0, math.max(150.0, MediaQuery.sizeOf(context).height * 0.36)))
                            : table != null
                            // Slim while FILE 3 is on the table below (the
                            // table is there too); whole for the solve.
                            ? (!solved && _tableDone(ChangedRecord.placedId))
                                ? 96.0
                                : (stage.maxWidth / table.tablePixels.aspect)
                                    .clamp(150.0, math.min(320.0, math.max(150.0, MediaQuery.sizeOf(context).height * 0.36)))
                            : letters != null
                            ? (stage.maxWidth / letters.letter.pixels.aspect)
                                .clamp(150.0, math.min(320.0, math.max(150.0, MediaQuery.sizeOf(context).height * 0.36)))
                            : trail != null
                            ? (stage.maxWidth / (trail.stageView.width * trail.stagePixels.aspect / trail.stageView.height))
                                .clamp(150.0, math.min(320.0, math.max(150.0, MediaQuery.sizeOf(context).height * 0.36)))
                            : book != null
                            ? (stage.maxWidth / book.hutPixels.aspect)
                                .clamp(150.0, math.min(320.0, math.max(150.0, MediaQuery.sizeOf(context).height * 0.36)))
                            : board != null
                            ? (stage.maxWidth / board.pixels.aspect)
                                .clamp(150.0, math.min(320.0, math.max(150.0, MediaQuery.sizeOf(context).height * 0.36)))
                            : canvases != null
                            ? (stage.maxWidth / canvases.paintAspect)
                                .clamp(150.0, math.min(320.0, math.max(150.0, MediaQuery.sizeOf(context).height * 0.36)))
                            : box != null
                            ? _boxStage(box, stage.maxWidth, MediaQuery.sizeOf(context).height)
                            : (MediaQuery.sizeOf(context).height * 0.3).clamp(160.0, 250.0),
                        child: ClipRect(
                          child: tower != null
                              // The garden, its clock at four.
                              ? TowerStage(key: const ValueKey('tower-stage'), scene: tower)
                              : hour != null
                              // P.'s drawing; the torn paper on it once laid.
                              ? TornHourStage(
                                  key: const ValueKey('torn-hour-stage'),
                                  scene: hour,
                                  placed: progress.hasExamined(_placedKey),
                                )
                              : table != null
                              // The archive table; FILE 3 on the lit light
                              // table with the solve.
                              ? RecordStage(
                                  key: const ValueKey('record-stage'),
                                  scene: table,
                                  open: _open,
                                  placed: progress.hasExamined(_tableKey(ChangedRecord.placedId)),
                                  lit: progress.hasExamined(_tableKey(ChangedRecord.litId)),
                                )
                              : letters != null
                              // The letter; turned over with the solve.
                              ? LetterStage(
                                  key: const ValueKey('letter-stage'),
                                  scene: letters,
                                  open: _open,
                                  onDrawing: solved ? null : () => showLetterDrawing(context, letters),
                                )
                              : trail != null
                              // The workshop door; the slip that says where
                              // the letter stopped, with the solve.
                              ? TrailStage(key: const ValueKey('trail-stage'), scene: trail, open: _open)
                              : book != null
                              // The keeper's hut; the gate with the solve.
                              ? GateStage(key: const ValueKey('gate-stage'), scene: book, open: _open)
                              : board != null
                              // The machine: its hatch opens with the solve.
                              ? MachineStage(key: const ValueKey('machine-stage'), scene: board, open: _open)
                              : canvases != null
                              ? CanvasStage(
                                  key: const ValueKey('canvas-stage'),
                                  scene: canvases,
                                  looking: _looking,
                                  turn: _open,
                                  turned: true,
                                )
                              : box != null
                              // The box itself: the lock's letters in its slots,
                              // opening round them with the solve.
                              ? LockBoxStage(
                                  art: box,
                                  animation: _open,
                                  letters: solved ? m.answer.split('') : _lockLetters,
                                  word: m.answer,
                                  insideLooked: progress.hasExamined(_insideKey!),
                                  onInside: solved ? _lookInside : null,
                                )
                              : m.scene == Artwork.royalBox
                              // The numbers on its drums follow the locks below
                              // until it opens.
                              ? RoyalBoxAnimation(animation: _open, digits: solved ? const [] : _digits)
                              : m.type == MissionType.letterLock
                              // The lock over its place, opening with the solve.
                              ? LetterLockReveal(
                                  animation: _open,
                                  word: m.answer,
                                  place: _SceneReveal(scene: PlaceArt.sceneOf(m), animation: _open),
                                )
                              : _SceneReveal(
                                  scene: PlaceArt.sceneOf(m),
                                  animation: _open,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // The story gives way to the banner: the height eases over
                    // instead of jumping.
                    AnimatedSize(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: AnimatedBuilder(
                        animation: _open,
                        builder: (context, _) => _open.value > 0.55
                            ? _CaseSolvedBanner(
                                progress: _open.value,
                                message: m.successMessage,
                                detectiveName: progress.detectiveName ?? '',
                                closed: progress.isCaseSolved,
                              )
                            : _intro(m),
                      ),
                    ),
                    const SizedBox(height: AppSpace.xl),
                    if (!solved)
                      ..._puzzle(m, progress.hintsFor(m.id))
                    else
                      _solvedActions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetOrTable({required bool placed, required Widget child}) => placed
      ? KeyedSubtree(key: const ValueKey('light-table-sheet'), child: child)
      : PaperSheet(key: const ValueKey('light-table-sheet'), padding: const EdgeInsets.all(AppSpace.sm), child: child);

  Widget _intro(Mission m) => _lightTable != null && _tableDone(ChangedRecord.chosenId) && !_storyOpen
      // The story read: folded to one line, opened again with a tap.
      ? Center(
          child: InkTextButton(
            key: const ValueKey('story-fold'),
            label: 'Read the story again',
            glyph: InkGlyph.letter,
            color: AppColors.goldLight,
            onPressed: () => setState(() => _storyOpen = true),
          ),
        )
      : Column(
    children: [
      for (final line in m.story)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlossaryText(
            line,
            textAlign: TextAlign.center,
            style: AppText.subtitle(color: AppColors.paperLight),
          ),
        ),
      // The letter itself is on the stage (Paris Case 06), the slip in the
      // puzzle (Paris Case 07): not again.
      if (_letterMap == null && _lightTable == null) ...[
        const SizedBox(height: 12),
        LetterCard(text: m.letter, tilt: 0.01),
      ],
    ],
  );

  List<Widget> _puzzle(Mission m, int hintsShown) => [
    // The tower untested (Case 09): the case's card above says what to do,
    // once; no heading repeats it. Then the question heads the page.
    if (_tower != null && !ref.watch(gameControllerProvider).hasExamined(_testedKey))
      SizedBox(key: _locksKey)
    else
    GlossaryText(
      key: _locksKey,
      // The light table's final asks one step at a time; so does the torn
      // paper's (is it the same paper, then the board).
      _tornHour != null && !ref.watch(gameControllerProvider).hasExamined(_placedKey)
          ? _tornHour!.placeHeading
          : _lightTable == null
          ? m.question
          : ChangedRecordPuzzle.headingOf(
              _lightTable!,
              m,
              chosen: ref.watch(gameControllerProvider).hasExamined(_tableKey(ChangedRecord.chosenId)),
              placed: ref.watch(gameControllerProvider).hasExamined(_tableKey(ChangedRecord.placedId)),
              litSeen: ref.watch(gameControllerProvider).hasExamined(_tableKey(ChangedRecord.litId)),
            ),
      textAlign: TextAlign.center,
      style: AppText.title(size: 24, color: AppColors.goldLight),
      linkColor: AppColors.paperLight,
    ),
    const SizedBox(height: 16),
    if (m.type == MissionType.finalCode) ...[
      ShakeOnChange(
        trigger: _wrongPulse,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _digits.length; i++)
              Flexible(
                child: _Dial(
                  value: _digits[i],
                  index: i,
                  symbol: i < m.dialSymbols.length ? m.dialSymbols[i] : null,
                  onUp: () => _turn(i, 1),
                  onDown: () => _turn(i, 9),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      // Custom Asset Required: an open-lock glyph for this button.
      GameButton(
        label: m.scene == Artwork.royalBox ? 'OPEN THE BOX' : 'UNLOCK',
        style: GameButtonStyle.glass,
        onPressed: _tryOpen,
      ),
      // The letter again, without scrolling back up (as on every puzzle).
      Center(
        child: InkTextButton(
          label: 'Reread Letter',
          glyph: InkGlyph.letter,
          color: AppColors.goldLight,
          onPressed: _rereadLetter,
        ),
      ),
    ] else if (_canvases case final canvases?) ...[
      // The canvas looked at, whole (a tap looks closer), over the four.
      LayoutBuilder(
        builder: (context, box) => SizedBox(
          height: (box.maxWidth / canvases.paintAspect).clamp(150.0, 340.0),
          child: CanvasStage(
            key: const ValueKey('canvas-stage'),
            scene: canvases,
            looking: _looking,
            turn: _open,
            turned: false,
            onCloser: () => showCanvasCloser(context, canvases, _looking, m.options.firstWhere((o) => o.id == _looking).label),
          ),
        ),
      ),
      const SizedBox(height: AppSpace.md),
      ShakeOnChange(
        trigger: _wrongPulse,
        child: CanvasPicker(
          key: const ValueKey('canvas-picker'),
          scene: canvases,
          mission: m,
          looking: _looking,
          looked: _looked,
          checking: _checking,
          onLook: _lookAt,
          onTurn: _turnCanvas,
        ),
      ),
    ] else if (_tower case final tower?) ...[
      // The tower set and tested first; then the question.
      PaperSheet(
        key: const ValueKey('tower-test-sheet'),
        padding: const EdgeInsets.all(AppSpace.md),
        child: TowerTestPuzzle(
          scene: tower,
          hour: _hour,
          tested: ref.watch(gameControllerProvider).hasExamined(_testedKey),
          onHour: _setHour,
          onTested: _testTower,
        ),
      ),
      if (ref.watch(gameControllerProvider).hasExamined(_testedKey)) ...[
        const SizedBox(height: AppSpace.md),
        for (final line in tower.testedLines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.xs),
            child: Text(line, textAlign: TextAlign.center, style: AppText.aside(size: 17, color: AppColors.goldLight)),
          ),
        const SizedBox(height: AppSpace.sm),
        // The page's heading asks it now (no second title).
        ShakeOnChange(
          trigger: _wrongPulse,
          child: PaperSheet(
            key: const ValueKey('tower-question-sheet'),
            padding: const EdgeInsets.all(AppSpace.lg),
            child: questionFor(m, _submit),
          ),
        ),
      ],
      Center(
        child: InkTextButton(
          label: 'Reread the card',
          glyph: InkGlyph.letter,
          color: AppColors.goldLight,
          onPressed: _rereadLetter,
        ),
      ),
    ] else if (_tornHour case final hour?) ...[
      // The paper laid on P.'s drawing first; then the board.
      if (!ref.watch(gameControllerProvider).hasExamined(_placedKey))
        PaperSheet(
          key: const ValueKey('torn-hour-place'),
          padding: const EdgeInsets.all(AppSpace.md),
          child: PaperOnDrawing(scene: hour, onPlaced: _placePaper),
        )
      else ...[
        for (final line in hour.placedLines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.xs),
            child: Text(line, textAlign: TextAlign.center, style: AppText.aside(size: 17, color: AppColors.goldLight)),
          ),
        const SizedBox(height: AppSpace.sm),
        ShakeOnChange(
          trigger: _wrongPulse,
          child: PaperSheet(
            key: const ValueKey('evidence-board'),
            padding: const EdgeInsets.all(AppSpace.lg),
            child: EvidenceBoard(
              scene: hour.board,
              mission: m,
              evidence: _boardEvidence(hour.board),
              links: _links,
              conclusion: _conclusion,
              question: _question,
              checking: _checking,
              onQuestion: _pickQuestion,
              onLink: _link,
              onConclusion: _conclude,
              onSubmit: _solveBoard,
            ),
          ),
        ),
      ],
      Center(
        child: InkTextButton(
          label: 'Reread your evidence',
          glyph: InkGlyph.letter,
          color: AppColors.goldLight,
          onPressed: _rereadLetter,
        ),
      ),
    ] else if (_board case final board?) ...[
      // The questions, the evidence and the conclusion, on one sheet.
      ShakeOnChange(
        trigger: _wrongPulse,
        child: PaperSheet(
          key: const ValueKey('evidence-board'),
          padding: const EdgeInsets.all(AppSpace.lg),
          child: EvidenceBoard(
            scene: board,
            mission: m,
            evidence: _boardEvidence(board),
            links: _links,
            conclusion: _conclusion,
            question: _question,
            checking: _checking,
            onQuestion: _pickQuestion,
            onLink: _link,
            onConclusion: _conclude,
            onSubmit: _solveBoard,
          ),
        ),
      ),
      Center(
        child: InkTextButton(
          label: 'Reread the time cards',
          glyph: InkGlyph.letter,
          color: AppColors.goldLight,
          onPressed: _rereadLetter,
        ),
      ),
    ] else if (_book case final book?) ...[
      // The street book, the address picked, the evidence for it.
      ShakeOnChange(
        trigger: _wrongPulse,
        child: PaperSheet(
          key: const ValueKey('street-book-sheet'),
          padding: const EdgeInsets.all(AppSpace.md),
          child: StreetBookPuzzle(
            scene: book,
            mission: m,
            evidence: _bookEvidence(book),
            crossed: _crossed,
            selected: _address,
            picked: _picked,
            checking: _checking,
            onSelect: _pickAddress,
            onPick: _pickEvidence,
            onCross: _crossOut,
            onSubmit: _submitAddress,
          ),
        ),
      ),
      Center(
        child: InkTextButton(
          label: 'Reread Letter',
          glyph: InkGlyph.letter,
          color: AppColors.goldLight,
          onPressed: _rereadLetter,
        ),
      ),
    ] else if (_lightTable case final table?) ...[
      // Which record was changed; FILE 3 on the light table; the slip's pins.
      ShakeOnChange(
        trigger: _wrongPulse,
        // On the table itself once FILE 3 is laid on it (no paper sheet
        // round the table); the first two steps on a sheet.
        child: _sheetOrTable(
          placed: _tableDone(ChangedRecord.placedId),
          child: ChangedRecordPuzzle(
            scene: table,
            mission: m,
            chosen: ref.watch(gameControllerProvider).hasExamined(_tableKey(ChangedRecord.chosenId)),
            placed: ref.watch(gameControllerProvider).hasExamined(_tableKey(ChangedRecord.placedId)),
            litSeen: ref.watch(gameControllerProvider).hasExamined(_tableKey(ChangedRecord.litId)),
            pinned: {
              for (final pin in ChangedRecord.homes.keys)
                if (ref.watch(gameControllerProvider).hasExamined(_tableKey(ChangedRecord.pinnedKey(pin)))) pin,
            },
            checking: _checking,
            onChosen: () => _nextTableStep(ChangedRecord.chosenId),
            onPlaced: () {
              ref.read(audioServiceProvider).play(GameSound.paperPlace);
              _nextTableStep(ChangedRecord.placedId);
            },
            onLit: () => _nextTableStep(ChangedRecord.litId),
            onPinned: (pin) {
              ref.read(audioServiceProvider).play(GameSound.paperPlace);
              _recordTable(ChangedRecord.pinnedKey(pin));
            },
            onWrong: _submitTable,
            onSolve: _submitTable,
          ),
        ),
      ),
      Center(
        child: InkTextButton(
          label: 'Reread the slip',
          glyph: InkGlyph.letter,
          color: AppColors.goldLight,
          onPressed: _rereadLetter,
        ),
      ),
    ] else if (_letterMap case final letters?) ...[
      // The map of Paris, its buildings to look at beside the drawing.
      ShakeOnChange(
        trigger: _wrongPulse,
        child: PaperSheet(
          key: const ValueKey('letter-map-sheet'),
          padding: const EdgeInsets.all(AppSpace.md),
          child: LetterMapPuzzle(
            scene: letters,
            mission: m,
            looked: {
              for (final s in letters.spots)
                if (ref.watch(gameControllerProvider).hasExamined(GameProgress.examinedKey(m.id, LetterMap.lookedKey(s.id)))) s.id,
            },
            onLooked: _lookAtBuilding,
            onSubmit: _chooseBuilding,
          ),
        ),
      ),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpace.sm,
        children: [
          InkTextButton(
            key: const ValueKey('look-at-drawing'),
            label: 'Look at the drawing',
            glyph: InkGlyph.search,
            color: AppColors.goldLight,
            onPressed: () => showLetterDrawing(context, letters),
          ),
          InkTextButton(
            label: 'Reread Letter',
            glyph: InkGlyph.letter,
            color: AppColors.goldLight,
            onPressed: _rereadLetter,
          ),
        ],
      ),
    ] else if (_trail case final trail?) ...[
      // The receipt, the slips, and the trail they are set on.
      ShakeOnChange(
        trigger: _wrongPulse,
        child: PaperSheet(
          key: const ValueKey('post-trail-sheet'),
          padding: const EdgeInsets.all(AppSpace.md),
          child: PostTrailPuzzle(
            scene: trail,
            mission: m,
            placed: _placed,
            picked: _slipPicked,
            checking: _checking,
            onPick: _pickSlip,
            onSlot: _setSlot,
            onSubmit: _followLetter,
          ),
        ),
      ),
      Center(
        child: InkTextButton(
          label: 'Reread the receipt',
          glyph: InkGlyph.letter,
          color: AppColors.goldLight,
          onPressed: _rereadLetter,
        ),
      ),
    ] else if (_box != null && m.type == MissionType.letterLock)
      // The box's lock: what is set in it shows on the box above.
      ShakeOnChange(
        trigger: _wrongPulse,
        child: PaperSheet(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: LetterLockQuestion(
            mission: m,
            onSubmit: _submit,
            onChanged: (letters) => setState(() => _lockLetters = letters),
          ),
        ),
      )
    else
      // Any other puzzle type: the case's last page, laid on the desk.
      ShakeOnChange(
        trigger: _wrongPulse,
        child: PaperSheet(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: questionFor(m, _submit),
        ),
      ),
    const SizedBox(height: 12),
    GameButton(
      label: 'OPEN MY NOTEBOOK',
      glyph: InkGlyph.notebook,
      style: GameButtonStyle.outline,
      // The notebook's own sound as it opens, no casebook tap with it.
      onPressed: _peekNotebook,
    ),
    const SizedBox(height: 18),
    TipsPanel(
      hints: m.hints,
      revealed: hintsShown,
      onReveal: _showHint,
      dark: true,
    ),
  ];

  Widget _solvedActions() => AnimatedBuilder(
    animation: _open,
    builder: (context, child) =>
        Opacity(opacity: ((_open.value - 0.8) / 0.2).clamp(0, 1), child: child),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Only for the solve just made (not a revisit): the cheer, and what
        // it paid, as the Discovery Moment shows it. No coins when none were
        // added; a case solved before earns nothing new and says so.
        if (_solvedNow && _xpEarned > 0) ...[
          Text(
            'You Made It!',
            key: const ValueKey('final-cheer'),
            textAlign: TextAlign.center,
            style: AppText.cinematicPrompt(size: 28, color: AppColors.goldLight),
          ),
          const SizedBox(height: AppSpace.sm),
          _firstSolve
              ? Text(
                  '+$_xpEarned XP${_coinsEarned > 0 ? '   ·   +$_coinsEarned COINS' : ''}',
                  key: const ValueKey('final-reward'),
                  textAlign: TextAlign.center,
                  style: AppText.style(
                    AppText.body,
                    size: 16,
                    weight: FontWeight.w700,
                    color: AppColors.goldLight,
                    letterSpacing: 2,
                  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                )
              : Text(
                  alreadyRewarded,
                  key: const ValueKey('final-reward'),
                  textAlign: TextAlign.center,
                  style: AppText.aside(size: 15, color: AppColors.paperLight.withValues(alpha: 0.8)),
                ),
          const SizedBox(height: AppSpace.md),
        ],
        // A box with something in it: looked at first (its back holds the
        // case's last words), then the story goes on.
        if (_tower case final tower? when !ref.watch(gameControllerProvider).hasExamined(_starKey)) ...[
          // A model shows what could happen, never what did: the records.
          for (final line in tower.afterLines)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.xs),
              child: Text(line, textAlign: TextAlign.center, style: AppText.aside(size: 17, color: AppColors.paperLight)),
            ),
          const SizedBox(height: AppSpace.md),
          GameButton(
            key: const ValueKey('final-follow-star'),
            label: tower.leadLabel,
            glyph: InkGlyph.search,
            style: GameButtonStyle.glass,
            tap: TapRole.primary,
            onPressed: _followStar,
          ),
        ] else if (_tornHour != null && !ref.watch(gameControllerProvider).hasExamined(_leadKey))
          GameButton(
            key: const ValueKey('final-last-drawing'),
            label: _tornHour!.leadLabel,
            glyph: InkGlyph.search,
            style: GameButtonStyle.glass,
            tap: TapRole.primary,
            onPressed: _lookAtLastDrawing,
          )
        else if (_lightTable != null && !ref.watch(gameControllerProvider).hasExamined(_tableKey(ChangedRecord.slipBackId)))
          GameButton(
            key: const ValueKey('final-turn-slip'),
            label: 'TURN THE SLIP OVER',
            glyph: InkGlyph.search,
            style: GameButtonStyle.glass,
            tap: TapRole.primary,
            onPressed: _turnSlip,
          )
        else if (_book != null && !ref.watch(gameControllerProvider).hasExamined(_gateKey))
          GameButton(
            key: const ValueKey('final-open-gate'),
            label: 'LOOK AT THE GATE',
            glyph: InkGlyph.search,
            style: GameButtonStyle.glass,
            tap: TapRole.primary,
            onPressed: _openGate,
          )
        else if (_board != null && !ref.watch(gameControllerProvider).hasExamined(_plaqueKey))
          GameButton(
            key: const ValueKey('final-read-plaque'),
            label: 'LOOK INSIDE',
            glyph: InkGlyph.search,
            style: GameButtonStyle.glass,
            tap: TapRole.primary,
            onPressed: _readPlaque,
          )
        else if (_canvases != null && !ref.watch(gameControllerProvider).hasExamined(_backKey))
          GameButton(
            key: const ValueKey('final-read-back'),
            label: 'READ THE BACK',
            glyph: InkGlyph.search,
            style: GameButtonStyle.glass,
            tap: TapRole.primary,
            onPressed: _readBack,
          )
        else if (_box != null && !ref.watch(gameControllerProvider).hasExamined(_insideKey!))
          GameButton(
            key: const ValueKey('final-look-inside'),
            label: 'LOOK INSIDE THE BOX',
            glyph: InkGlyph.search,
            style: GameButtonStyle.glass,
            tap: TapRole.primary,
            onPressed: _lookInside,
          )
        else
          _nextButton(),
      ],
    ),
  );

  // The story goes on after the case (its post-case scene, which ends on
  // SEE MY CASE REPORT); a case without one goes straight to the report.
  Widget _nextButton() => _mission.transition.isEmpty
      ? GameButton(
          label: 'SEE MY CASE REPORT',
          glyph: InkGlyph.folder,
          style: GameButtonStyle.glass,
          onPressed: () => context.go(Routes.solved),
        )
      : GameButton(
          label: continueInvestigation,
          arrow: true,
          style: GameButtonStyle.glass,
          tap: TapRole.primary,
          onPressed: () => context.go(Routes.story(_mission.id)),
        );
}

/// One lock: a picture on top and a number wheel below.
class _Dial extends StatelessWidget {
  const _Dial({
    required this.value,
    required this.index,
    required this.symbol,
    required this.onUp,
    required this.onDown,
  });

  final int value;
  final int index;
  final String? symbol;
  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  Widget build(BuildContext context) {
    final label = RoyalBoxPicture.nameOf(symbol);
    final picture = RoyalBoxPicture.of(symbol);
    // A brass lock plate with its picture, wheel and two levers.
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDeep],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.goldDeep, width: AppLine.hairline),
        boxShadow: AppShadow.onNight,
      ),
      foregroundDecoration: const RuledFrame(
        color: AppColors.navyDeep,
        inset: 3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Case 01's Royal Box: its full-colour picture in a small parchment
          // window on the brass (the same picture as on the crown card), and
          // its name; any other lock keeps its stamp.
          if (picture != null)
            _LockPicture(key: ValueKey('lock-picture-${picture.symbol}'), picture: picture)
          else if (symbol != null)
            SymbolBadge(symbol, size: 46, light: true),
          IconButton(
            tooltip: 'Lock ${index + 1} up',
            onPressed: onUp,
            color: AppColors.navy,
            // The ink "down" arrow turned over (no separate up glyph).
            icon: const RotatedBox(
              quarterTurns: 2,
              child: InkIcon(InkGlyph.down, size: AppIconSize.large),
            ),
          ),
          Container(
            width: 58,
            height: 66,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.goldDeep,
                width: AppLine.rule,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Text(
                '$value',
                key: ValueKey(value),
                semanticsLabel: 'Lock ${index + 1}, $label: $value',
                style: AppText.title(size: 36, color: AppColors.goldLight),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Lock ${index + 1} down',
            onPressed: onDown,
            color: AppColors.navy,
            icon: const InkIcon(InkGlyph.down, size: AppIconSize.large),
          ),
        ],
      ),
    );
  }
}

/// A Royal Box lock's picture: set in a parchment window on the brass plate
/// (the picture's own colours read against it, not against the gold), its
/// name under it in capitals, one line whatever the text size.
class _LockPicture extends StatelessWidget {
  const _LockPicture({super.key, required this.picture});

  final RoyalBoxPicture picture;

  static const side = 58.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: side,
          height: side,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.parchment,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.goldDeep, width: AppLine.hairline),
          ),
          child: RoyalBoxPictureImage(picture, size: side - 6),
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: side + 6,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.15,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                picture.name.toUpperCase(),
                maxLines: 1,
                style: AppText.eyebrow(color: AppColors.navyDeep),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CaseSolvedBanner extends StatelessWidget {
  const _CaseSolvedBanner({
    required this.progress,
    required this.message,
    required this.detectiveName,
    this.closed = true,
  });

  final double progress;
  final String message;
  final String detectiveName;

  /// The case is closed: its CASE SOLVED stamp. Not yet while a last step
  /// after the answer waits (Paris Case 08's last drawing).
  final bool closed;

  @override
  Widget build(BuildContext context) {
    final t = ((progress - 0.55) / 0.35).clamp(0.0, 1.0);
    return Opacity(
      opacity: t,
      child: Transform.scale(
        scale: 0.92 + 0.08 * Curves.easeOutCubic.transform(t),
        child: Column(
          children: [
            if (closed) ...[
              const InkStamp('CASE SOLVED', color: AppColors.gold, size: 26),
              const SizedBox(height: 14),
            ],
            Text(
              message,
              style: AppText.title(size: 24, color: AppColors.paperLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Brilliant work, ${DetectiveName.title(detectiveName)}!',
              style: AppText.subtitle(color: AppColors.goldLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// The final place of a case other than Episode 01: its scene, printed like
/// a storybook picture, settles into place when the case is solved.
class _SceneReveal extends StatelessWidget {
  const _SceneReveal({required this.scene, required this.animation});

  final Artwork scene;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(animation.value);
        return Transform.scale(
          scale: 1 + 0.04 * t,
          child: Center(
            child: AspectRatio(
              aspectRatio: LandmarkArt.aspectOf(scene),
              child: PaperSheet(
                padding: const EdgeInsets.all(AppSpace.sm),
                tilt: -0.01,
                // The picture changes with the solve (the Case 02 clock starts
                // again): it times its own change over the reveal's progress.
                child: LandmarkArt(
                  scene,
                  borderRadius: 2,
                  solved: animation.value,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The Royal Box. Painted: shut, the numbers the detective has turned the
/// locks to on its dial drums ([digits]); opening, a small jolt as the
/// locks give, then the open picture (the Crown inside, the drums at the
/// code) takes over from the shut one as the lid would swing, the page
/// looking a little closer so the Crown reads large. Drawn in code when a
/// picture is missing: closed → lid lifts → light → crown rises.
class RoyalBoxAnimation extends StatelessWidget {
  const RoyalBoxAnimation({
    super.key,
    required this.animation,
    this.digits = const [],
    this.art = ArtAssets.royalBox,
  });

  /// 0 = shut (the puzzle), 1 = open with the Crown (solved, or a revisit).
  final Animation<double> animation;

  /// What the locks are turned to now, left to right: written on the shut
  /// box's drums (the open box shows its own).
  final List<int> digits;

  /// The box's two pictures, or null to draw it in code (see [ArtAssets.royalBox]).
  final RoyalBoxArt? art;

  @override
  Widget build(BuildContext context) {
    final pictures = art;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final shake = t < 0.2 ? math.sin(t * 90) * 4 * (1 - t / 0.2) : 0.0;
        // The heavy lid swings open and settles (no spring back).
        final lid = Curves.easeOutCubic.transform(
          ((t - 0.2) / 0.3).clamp(0, 1),
        );
        final crown = Curves.easeOutCubic.transform(
          ((t - 0.4) / 0.45).clamp(0, 1),
        );
        final drawn = CustomPaint(
          painter: _RoyalBoxPainter(lid: lid, crown: crown, rays: t),
          child: const SizedBox.expand(),
        );
        if (pictures == null) {
          return Transform.translate(offset: Offset(shake, 0), child: drawn);
        }
        // Both pictures on the same canvas, placed alike: the part of it the
        // box fills shut, closer to the open box as the lid swings.
        final view = Rect.lerp(pictures.shut, pictures.opened, lid)!;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: LayoutBuilder(
            builder: (context, box) {
              final canvas = _canvasFor(view, box.biggest);
              Rect at(Rect r) => Rect.fromLTRB(
                    canvas.left + r.left * canvas.width,
                    canvas.top + r.top * canvas.height,
                    canvas.left + r.right * canvas.width,
                    canvas.top + r.bottom * canvas.height,
                  );
              Widget picture(String file, double opacity, Key key) => Positioned.fromRect(
                    rect: canvas,
                    child: Opacity(
                      opacity: opacity,
                      child: Image.asset(
                        file,
                        key: key,
                        fit: BoxFit.fill,
                        excludeFromSemantics: true,
                        // A missing or broken picture: the box drawn in code.
                        errorBuilder: (context, error, stack) => drawn,
                      ),
                    ),
                  );
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // The shut box gives way first (the two boxes, shaped
                  // differently, are seen together only briefly).
                  if (lid < 1) picture(pictures.closed, (1 - lid * 1.6).clamp(0.0, 1.0), const ValueKey('royal-box-shut')),
                  // The open box only once it opens: never before the code.
                  if (lid > 0) picture(pictures.open, lid, const ValueKey('royal-box-open')),
                  if (lid < 1)
                    for (final (i, r) in pictures.dials.indexed)
                      if (i < digits.length)
                        Positioned.fromRect(
                          rect: at(r),
                          child: Opacity(
                            opacity: 1 - lid,
                            child: _DrumDigit(key: ValueKey('royal-box-dial-$i'), value: digits[i]),
                          ),
                        ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Where the whole canvas goes so that [view] (fractions of it) fits in
  /// [size], centred, kept to its proportions.
  static Rect _canvasFor(Rect view, Size size) {
    final aspect = ArtAssets.sceneAspects[Artwork.royalBox]!;
    final viewAspect = view.width * aspect / view.height;
    var w = size.width, h = w / viewAspect;
    if (h > size.height) {
      h = size.height;
      w = h * viewAspect;
    }
    final cw = w / view.width, ch = cw / aspect;
    return Rect.fromLTWH(
      (size.width - w) / 2 - view.left * cw,
      (size.height - h) / 2 - view.top * ch,
      cw,
      ch,
    );
  }
}

/// A number on a dial drum of the painted box, in the drum's own dark ink
/// with a pale rim, as the picture's open box prints its code; it rolls in
/// as the lock below is turned. For the eye only: the lock below is read.
class _DrumDigit extends StatelessWidget {
  const _DrumDigit({super.key, required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          transitionBuilder: (child, anim) => SlideTransition(
            position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(anim),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: FittedBox(
            key: ValueKey(value),
            fit: BoxFit.contain,
            child: Text(
              '$value',
              textScaler: TextScaler.noScaling,
              style: AppText.title(size: 40, color: AppColors.ink).copyWith(
                fontWeight: FontWeight.w800,
                height: 1,
                shadows: const [Shadow(color: AppColors.goldLight, blurRadius: 1.5)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoyalBoxPainter extends CustomPainter {
  _RoyalBoxPainter({
    required this.lid,
    required this.crown,
    required this.rays,
  });

  final double lid;
  final double crown;
  final double rays;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final boxW = math.min(size.width * 0.7, 260.0);
    final boxH = boxW * 0.5;
    final boxTop = size.height - boxH - 8;
    final body = Rect.fromLTWH(cx - boxW / 2, boxTop, boxW, boxH);
    final ink = Paint()
      ..color = AppColors.navyDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Light rays (kept inside the canvas so clipping never shows hard edges).
    if (lid > 0) {
      final center = Offset(cx, boxTop);
      final len = math.min(size.height, size.width / 2) * 0.95;
      for (var i = 0; i < 12; i++) {
        final a =
            -math.pi +
            (i + 0.5) * math.pi / 12 +
            math.sin(rays * math.pi) * 0.08;
        final path = Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(
            center.dx + math.cos(a - 0.06) * len,
            center.dy + math.sin(a - 0.06) * len,
          )
          ..lineTo(
            center.dx + math.cos(a + 0.06) * len,
            center.dy + math.sin(a + 0.06) * len,
          )
          ..close();
        canvas.drawPath(
          path,
          Paint()..color = AppColors.goldLight.withValues(alpha: 0.18 * lid),
        );
      }
      canvas.drawCircle(
        center,
        90 * lid,
        Paint()..color = AppColors.goldLight.withValues(alpha: 0.25 * lid),
      );
    }

    // Paint order: an opening lid goes behind the crown; a closed lid sits
    // in front of the body.
    if (lid > 0) _lid(canvas, body, boxH, cx, ink);

    // Crown rising out of the box (its base is hidden by the body).
    if (crown > 0) {
      final cw = boxW * 0.42;
      final cy = boxTop - cw * 0.55 * crown + cw * 0.2;
      _crown(canvas, Offset(cx, cy), cw);
    }

    // Box body.
    final rBody = RRect.fromRectAndRadius(body, const Radius.circular(10));
    canvas.drawRRect(rBody, Paint()..color = AppColors.gold);
    canvas.drawRRect(rBody, ink);
    for (final f in [0.18, 0.82]) {
      final x = body.left + body.width * f;
      final band = Rect.fromLTWH(x - 7, body.top, 14, body.height);
      canvas.drawRect(band, Paint()..color = AppColors.goldLight);
      canvas.drawRect(band, ink..strokeWidth = 2);
    }
    // Lock plate.
    final plate = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, body.top + body.height * 0.45),
        width: 44,
        height: 50,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      plate,
      Paint()..color = lid > 0 ? AppColors.success : AppColors.navy,
    );
    canvas.drawCircle(
      plate.center.translate(0, -6),
      6,
      Paint()..color = AppColors.goldLight,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: plate.center.translate(0, 6),
        width: 5,
        height: 14,
      ),
      Paint()..color = AppColors.goldLight,
    );

    if (lid == 0) _lid(canvas, body, boxH, cx, ink);
  }

  /// The lid pivots on its back-right edge and lifts away as [lid] grows.
  void _lid(Canvas canvas, Rect body, double boxH, double cx, Paint ink) {
    canvas.save();
    canvas.translate(body.right, body.top - lid * 6);
    canvas.rotate(lid * 0.55);
    canvas.translate(-body.right, -body.top);
    final lidRect = Rect.fromLTWH(
      body.left - 8,
      body.top - boxH * 0.42,
      body.width + 16,
      boxH * 0.44,
    );
    final lidPath = Path()
      ..moveTo(lidRect.left, lidRect.bottom)
      ..lineTo(lidRect.left, lidRect.top + lidRect.height * 0.45)
      ..quadraticBezierTo(
        cx,
        lidRect.top - lidRect.height * 0.45,
        lidRect.right,
        lidRect.top + lidRect.height * 0.45,
      )
      ..lineTo(lidRect.right, lidRect.bottom)
      ..close();
    canvas.drawPath(lidPath, Paint()..color = AppColors.goldDeep);
    canvas.drawPath(lidPath, ink..strokeWidth = 3);
    if (lid < 0.3) {
      _crown(
        canvas,
        Offset(cx, lidRect.top + lidRect.height * 0.35),
        26,
        emblem: true,
      );
    }
    canvas.restore();
  }

  void _crown(Canvas c, Offset center, double w, {bool emblem = false}) {
    final h = w * 0.62;
    final l = center.dx - w / 2;
    final r = center.dx + w / 2;
    final top = center.dy - h / 2;
    final bottom = center.dy + h / 2;
    final path = Path()
      ..moveTo(l, bottom)
      ..lineTo(l, top + h * 0.2)
      ..lineTo(l + w * 0.25, top + h * 0.55)
      ..lineTo(center.dx, top)
      ..lineTo(r - w * 0.25, top + h * 0.55)
      ..lineTo(r, top + h * 0.2)
      ..lineTo(r, bottom)
      ..close();
    c.drawPath(
      path,
      Paint()..color = emblem ? AppColors.goldLight : AppColors.gold,
    );
    c.drawPath(
      path,
      Paint()
        ..color = AppColors.navyDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = emblem ? 1.5 : 3,
    );
    if (!emblem) {
      c.drawRect(
        Rect.fromLTRB(l, bottom - h * 0.22, r, bottom),
        Paint()..color = AppColors.goldDeep,
      );
      for (final (fx, color) in [
        (0.2, AppColors.royalBlue),
        (0.5, AppColors.waxRed),
        (0.8, AppColors.royalBlue),
      ]) {
        c.drawCircle(
          Offset(l + w * fx, bottom - h * 0.11),
          w * 0.05,
          Paint()..color = color,
        );
      }
      for (final p in [
        Offset(l, top + h * 0.2),
        Offset(center.dx, top),
        Offset(r, top + h * 0.2),
      ]) {
        c.drawCircle(p, w * 0.045, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(_RoyalBoxPainter old) =>
      old.lid != lid ||
      old.crown != crown ||
      old.rays != rays;
}
