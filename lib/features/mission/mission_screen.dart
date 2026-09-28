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
import '../../widgets/game_button.dart';
import '../../widgets/glossary_text.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/landmark_art.dart';
import '../../widgets/letter_card.dart';
import '../../widgets/paper.dart';
import '../../widgets/paper_background.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../game/scoring.dart';
import 'widgets/answer_feedback.dart';
import 'widgets/qr_question.dart';
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

  void _onLetterOpened() {
    ref.read(audioServiceProvider).play(GameSound.clue);
    setState(() => _letterOpened = true);
  }

  void _showHint(Mission m) => ref.read(gameControllerProvider.notifier).useHint(m);

  void _rereadLetter(Mission m) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.xl),
          child: Column(
            children: [
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

  Widget _questionFor(Mission m) {
    void onSubmit(String a) => _submit(m, a);
    return switch (m.type) {
      MissionType.multipleChoice => MultipleChoiceQuestion(mission: m, onSubmit: onSubmit),
      MissionType.wordInput => WordInputQuestion(mission: m, onSubmit: onSubmit),
      MissionType.numberCode || MissionType.finalCode => NumberCodeQuestion(mission: m, onSubmit: onSubmit),
      MissionType.imageChoice => ImageChoiceQuestion(mission: m, onSubmit: onSubmit),
      MissionType.qrScan => QrQuestion(mission: m, onSubmit: onSubmit),
    };
  }

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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to map',
          icon: const InkIcon(InkGlyph.back),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.map),
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
    );
  }
}

/// The place: its name, and the story's title in a quiet line below.
class _PlaceHeading extends StatelessWidget {
  const _PlaceHeading({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          mission.location,
          textAlign: TextAlign.center,
          style: AppText.title(size: 26).copyWith(letterSpacing: 1.5),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(mission.title, textAlign: TextAlign.center, style: AppText.aside()),
      ],
    );
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
        PaperSheet(
          padding: const EdgeInsets.all(AppSpace.sm),
          tilt: -0.01,
          child: AspectRatio(aspectRatio: 4 / 3, child: LandmarkArt(m.scene, borderRadius: 2)),
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
          style: AppText.bodyText(size: 19),
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
        GlossaryText(mission.question, style: AppText.title(size: 24), textAlign: TextAlign.center),
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
          SizedBox(height: 170, child: EvidenceTile(evidence: m.evidence!, location: m.location)),
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
