import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/audio_service.dart';
import '../../data/models/mission.dart';
import '../../widgets/clue_card.dart';
import '../../widgets/detective_tips.dart';
import '../../widgets/evidence_card.dart';
import '../../widgets/back_to.dart';
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
import 'widgets/question_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    final progress = ref.read(gameControllerProvider);
    // Returning players skip straight to the puzzle they were on.
    _stage = progress.isCompleted(widget.missionId) || progress.missionStartedAt.containsKey(widget.missionId)
        ? MissionStage.puzzle
        : MissionStage.story;
  }

  void _goTo(MissionStage stage) {
    if (stage == MissionStage.puzzle) {
      ref.read(gameControllerProvider.notifier).markMissionStarted(widget.missionId);
    }
    setState(() => _stage = stage);
  }

  /// Back (arrow or Android back) walks back one step: puzzle → letter →
  /// place → map. A read letter stays open when coming back to it.
  bool get _atFirstStep => _stage == MissionStage.story || ref.read(gameControllerProvider).isCompleted(widget.missionId);

  void _back() {
    if (_atFirstStep) {
      context.canPop() ? context.pop() : context.go(Routes.map);
      return;
    }
    setState(() {
      if (_stage == MissionStage.puzzle) _letterOpened = true;
      _stage = _stage == MissionStage.puzzle ? MissionStage.letter : MissionStage.story;
    });
  }

  void _onLetterOpened() {
    ref.read(audioServiceProvider).play(GameSound.clue);
    setState(() => _letterOpened = true);
  }

  void _showHint(Mission m) => ref.read(gameControllerProvider.notifier).useHint(m);

  void _rereadLetter(Mission m) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Paper, not an app sheet (this sheet only; the others keep the app's
      // sheet theme): nearly square corners, and a thin ink-brown tab in
      // place of the grey handle (it still drags to close).
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.paper))),
      showDragHandle: false,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.xl),
          child: Column(
            children: [
              // The tab, in the handle's own 48 dp slot (the sheet keeps its height).
              Container(
                width: 32,
                height: 3,
                margin: const EdgeInsets.only(top: 22, bottom: 23),
                decoration: BoxDecoration(
                  color: AppColors.inkBrown.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              LetterCard(text: m.letter),
              const SizedBox(height: AppSpace.xl),
              GameButton(label: 'BACK TO THE PUZZLE', onPressed: () => Navigator.of(context).pop()),
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
        audio.play(GameSound.wrong);
        setState(() => _wrongPulse++);
        final canHint = ref.read(gameControllerProvider).hintsFor(m.id) < m.hints.length;
        final choice = await showTryAgainSheet(context, hintAvailable: canHint);
        if (choice == TryAgainChoice.hint && mounted) _showHint(m);
      case SubmitResult.correct:
        audio.play(GameSound.success);
        final progress = ref.read(gameControllerProvider);
        await showSuccessOverlay(
          context,
          detectiveName: progress.detectiveName ?? '',
          message: m.successMessage,
          xp: XpBreakdown.of(m, progress),
          clue: m.clue,
          evidence: m.evidence,
          newBadges: outcome.newBadges,
          buttonLabel: 'CONTINUE',
        );
        if (mounted) context.go(Routes.story(m.id));
    }
  }

  Widget _questionFor(Mission m) => questionFor(m, (a) => _submit(m, a));

  @override
  Widget build(BuildContext context) {
    final episode = ref.watch(currentEpisodeProvider);
    final progress = ref.watch(gameControllerProvider);
    final m = episode.missionById(widget.missionId);
    if (m == null) return const SizedBox.shrink(); // router guard prevents this
    final solved = progress.isCompleted(m.id);

    final Widget body = solved
        ? _SolvedStage(key: const ValueKey('solved'), mission: m)
        : switch (_stage) {
            MissionStage.story =>
              _StoryStage(key: const ValueKey('story'), mission: m, onInvestigate: () => _goTo(MissionStage.letter)),
            MissionStage.letter => _LetterStage(
                key: const ValueKey('letter'),
                mission: m,
                opened: _letterOpened,
                onOpened: _onLetterOpened,
                onDone: () => _goTo(MissionStage.puzzle),
              ),
            MissionStage.puzzle => _PuzzleStage(
                key: const ValueKey('puzzle'),
                mission: m,
                hintsShown: progress.hintsFor(m.id),
                wrongPulse: _wrongPulse,
                onHint: () => _showHint(m),
                onReread: () => _rereadLetter(m),
                child: _questionFor(m),
              ),
          };

    // Android back always takes the same path as the app bar arrow
    // ([_back]), on every step, the first one included. Letting the route
    // pop by itself on the place step left the answer to the route stack
    // and the platform: with nothing under the mission, an Android 16
    // device (predictive back) sends the app away instead of to the map.
    return BackTo(
      onBack: _back,
      child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: solved || _stage == MissionStage.story ? 'Back to map' : 'Back',
          icon: const InkIcon(InkGlyph.back),
          onPressed: _back,
        ),
        actions: [
          IconButton(
            tooltip: 'Detective notebook',
            icon: const InkIcon(InkGlyph.notebook),
            onPressed: () => context.push(Routes.notebook),
          ),
          const SizedBox(width: AppSpace.xs),
        ],
      ),
      body: PaperBackground(
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                child: body,
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// The place: its name, and the story's title in a quiet line below.
class _PlaceHeading extends StatelessWidget {
  const _PlaceHeading({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    return PageHeading(eyebrow: 'MISSION ${mission.numberLabel}', title: mission.location, subtitle: mission.title);
  }
}

// STEP 1 — the place. One action: investigate.
class _StoryStage extends StatelessWidget {
  const _StoryStage({super.key, required this.mission, required this.onInvestigate});

  final Mission mission;
  final VoidCallback onInvestigate;

  @override
  Widget build(BuildContext context) {
    final m = mission;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.xxl),
      children: [
        _PlaceHeading(mission: m),
        const SizedBox(height: AppSpace.xl),
        // The scene, printed like a picture in a storybook.
        // A square picture (the raven, the suitcase) is kept a page-size
        // print, so the story still starts on the first screen.
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: LandmarkArt.aspectOf(PlaceArt.sceneOf(m)) < 1.2 ? 240 : double.infinity),
            child: PaperSheet(
              padding: const EdgeInsets.all(AppSpace.sm),
              tilt: -0.01,
              child: AspectRatio(aspectRatio: LandmarkArt.aspectOf(PlaceArt.sceneOf(m)), child: LandmarkArt(PlaceArt.sceneOf(m), borderRadius: 2)),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        for (final (i, line) in m.story.indexed)
          _FadeIn(
            delay: Duration(milliseconds: 150 + i * 400),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: GlossaryText(line, style: AppText.bodyText(size: 19), textAlign: TextAlign.center),
            ),
          ),
        const SizedBox(height: AppSpace.xl),
        GameButton(label: 'INVESTIGATE', arrow: true, onPressed: onInvestigate),
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
    required this.onOpened,
    required this.onDone,
  });

  final Mission mission;
  final bool opened;
  final VoidCallback onOpened;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.lg, AppSpace.screen, AppSpace.xxl),
      children: [
        GlossaryText(
          mission.letterIntro,
          style: AppText.aside(size: 19, color: AppColors.inkBrown),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpace.xl),
        EnvelopeReveal(letterText: mission.letter, initiallyOpen: opened, onOpened: onOpened),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: !opened
              ? const SizedBox(key: ValueKey('sealed'), height: AppSpace.xl)
              : Column(
                  key: const ValueKey('open'),
                  children: [
                    const SizedBox(height: AppSpace.lg),
                    Text('Tap a dotted word to see what it means.', style: AppText.caption(), textAlign: TextAlign.center),
                    const SizedBox(height: AppSpace.xl),
                    GameButton(label: 'SOLVE THE PUZZLE', arrow: true, onPressed: onDone),
                  ],
                ),
        ),
      ],
    );
  }
}

// STEP 3 — the puzzle. One action: answer. The letter and tips are quiet
// helpers, opened only when the detective wants them.
class _PuzzleStage extends StatelessWidget {
  const _PuzzleStage({
    super.key,
    required this.mission,
    required this.hintsShown,
    required this.wrongPulse,
    required this.onHint,
    required this.onReread,
    required this.child,
  });

  final Mission mission;
  final int hintsShown;
  final int wrongPulse;
  final VoidCallback onHint;
  final VoidCallback onReread;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tipLabel = nextTipLabel(mission.hints, hintsShown);
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.xxl),
      children: [
        Text('MISSION ${mission.numberLabel} · THE PUZZLE', textAlign: TextAlign.center, style: AppText.eyebrow()),
        const SizedBox(height: AppSpace.sm),
        GlossaryText(mission.question, style: AppText.title(size: 24), textAlign: TextAlign.center),
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
            InkTextButton(label: 'Letter', glyph: InkGlyph.letter, onPressed: onReread),
            if (tipLabel != null) InkTextButton(label: tipLabel, glyph: InkGlyph.hint, color: tipLinkColor, onPressed: onHint),
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
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.xxl),
      children: [
        _PlaceHeading(mission: m),
        const SizedBox(height: AppSpace.lg),
        const Center(child: InkStamp('SOLVED', color: AppColors.success)),
        const SizedBox(height: AppSpace.md),
        Text(m.successMessage, style: AppText.bodyText(), textAlign: TextAlign.center),
        const SizedBox(height: AppSpace.xl),
        LetterCard(text: m.letter),
        if (m.clue != null) ...[
          const SizedBox(height: AppSpace.lg),
          ClueCard(clue: m.clue!, index: clues.indexWhere((c) => c.id == m.clue!.id), location: m.location),
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
        GameButton(label: 'BACK TO MAP', onPressed: () => context.go(Routes.map)),
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
    return AnimatedOpacity(opacity: _visible ? 1 : 0, duration: const Duration(milliseconds: 400), child: widget.child);
  }
}
