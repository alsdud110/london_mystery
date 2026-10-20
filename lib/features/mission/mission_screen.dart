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
import '../../data/mock/season1/season1_discoveries.dart';
import '../../data/mock/season1/season1_investigations.dart';
import '../../data/mock/season1/season1_dialogues.dart';
import '../../data/mock/season1/season1_clocks.dart';
import '../../data/mock/season1/season1_explores.dart';
import '../../data/mock/season1/season1_inspections.dart';
import '../../data/mock/season1/season1_deductions.dart';
import '../../data/mock/season1/season1_decodes.dart';
import '../../data/models/scene_deduction.dart';
import '../../data/models/scene_decode.dart';
import '../../data/models/scene_explore.dart';
import '../../data/models/scene_inspect.dart';
import '../../data/models/clock_puzzle.dart';
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
import 'widgets/clock_question.dart';
import 'widgets/dialogue_investigation.dart';
import 'widgets/investigation_search.dart';
import 'widgets/lens_inspect.dart';
import 'widgets/scene_deduction.dart';
import 'widgets/scene_decode.dart';
import 'widgets/scene_explore.dart';
import 'widgets/question_widgets.dart';
import 'widgets/tip_shop.dart';
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

  @override
  void initState() {
    super.initState();
    final progress = ref.read(gameControllerProvider);
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
        _stage == MissionStage.puzzle && exploreOf(_mission) != null;
    final inspecting =
        _stage == MissionStage.puzzle && inspectionOf(_mission) != null;
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
        _stage == MissionStage.puzzle && decodeOf(_mission) != null;
    if (examining && _decode.step == DecodeStep.closer) {
      setState(() => _decode.step = DecodeStep.look);
      return;
    }
    // A talk, a look round, a place read for its traces and a thing
    // examined have no letter step: back from them is the place.
    final talking =
        _stage == MissionStage.puzzle && dialogueOf(_mission) != null;
    final reading =
        _stage == MissionStage.puzzle && deductionOf(_mission) != null;
    setState(() {
      if (_stage == MissionStage.puzzle) _letterOpened = true;
      _stage =
          _stage == MissionStage.puzzle &&
              !talking &&
              !exploring &&
              !inspecting &&
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
                style: AppText.mark(color: AppColors.paperLight, size: 12.5),
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
        final progress = ref.read(gameControllerProvider);
        await showDiscoveryMoment(
          context,
          mission: m,
          discovery: discoveryOf(m),
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
    final scene = investigationOf(m);
    final talk = dialogueOf(m);
    final clock = clockPuzzleOf(m);
    final explore = exploreOf(m);
    final inspect = inspectionOf(m);
    final deduction = deductionOf(m);
    final decode = decodeOf(m);

    final Widget body = solved
        ? _SolvedStage(key: const ValueKey('solved'), mission: m)
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
                // A place read for its traces starts at once too: the notes
                // are written as the traces are found. So does a thing to
                // examine: what it hides is shown on it. (Its place keeps
                // the place's own scene: the thing is found after.)
                onInvestigate: () => _goTo(
                  talk != null ||
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
          systemOverlayStyle: dark ? AppTheme.statusOnNight : AppTheme.statusOnPaper,
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

// STEP 1 — the place. One action: investigate.
class _StoryStage extends StatelessWidget {
  const _StoryStage({
    super.key,
    required this.mission,
    required this.onInvestigate,
    this.picture,
  });

  final Mission mission;
  final VoidCallback onInvestigate;

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
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: own == null && LandmarkArt.aspectOf(PlaceArt.sceneOf(m)) < 1.2
                  ? 240
                  : double.infinity,
            ),
            child: PaperSheet(
              padding: const EdgeInsets.all(AppSpace.sm),
              tilt: -0.01,
              child: own == null
                  ? AspectRatio(
                      aspectRatio: LandmarkArt.aspectOf(PlaceArt.sceneOf(m)),
                      child: LandmarkArt(PlaceArt.sceneOf(m), borderRadius: 2),
                    )
                  : AspectRatio(
                      aspectRatio: own.$2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Image.asset(own.$1, key: const ValueKey('story-picture'), fit: BoxFit.cover, excludeFromSemantics: true),
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
  });

  final Mission mission;
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
          DetectiveName.address(m.successMessage, ref.watch(gameControllerProvider).detectiveName),
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
