import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/audio_service.dart';
import '../../data/models/mission.dart';
import '../../widgets/clue_card.dart';
import '../../widgets/evidence_card.dart';
import '../../widgets/game_button.dart';
import '../../widgets/glossary_text.dart';
import '../../widgets/landmark_art.dart';
import '../../widgets/letter_card.dart';
import '../../widgets/paper_background.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../game/scoring.dart';
import 'widgets/answer_feedback.dart';
import 'widgets/qr_question.dart';
import 'widgets/question_widgets.dart';

/// The three steps of a mission. Each screen offers one main action.
enum MissionStage { story, letter, puzzle }

/// One mission: story → sealed letter → puzzle → clue & evidence.
class MissionScreen extends ConsumerStatefulWidget {
  const MissionScreen({super.key, required this.missionId});

  final String missionId;

  @override
  ConsumerState<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends ConsumerState<MissionScreen> {
  late MissionStage _stage;
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
    _goTo(MissionStage.letter);
  }

  void _showHint(Mission m) => ref.read(gameControllerProvider.notifier).useHint(m);

  void _rereadLetter(Mission m) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: Column(
            children: [
              Text('THE LETTER', style: AppText.eyebrow()),
              const SizedBox(height: 14),
              LetterCard(text: m.letter),
              const SizedBox(height: 20),
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
            MissionStage.story => _StoryStage(key: const ValueKey('story'), mission: m, onOpened: _onLetterOpened),
            MissionStage.letter =>
              _LetterStage(key: const ValueKey('letter'), mission: m, onDone: () => _goTo(MissionStage.puzzle)),
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
        title: Text('MISSION ${m.numberLabel}'),
        leading: IconButton(
          tooltip: 'Back to map',
          icon: const Icon(Icons.map_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.map),
        ),
        actions: [
          IconButton(
            tooltip: 'Detective notebook',
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: () => context.push(Routes.notebook),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(10),
          child: _StageDots(stage: solved ? null : _stage),
        ),
      ),
      body: PaperBackground(
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                ),
                child: body,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Three dots showing story → letter → puzzle.
class _StageDots extends StatelessWidget {
  const _StageDots({required this.stage});

  final MissionStage? stage;

  @override
  Widget build(BuildContext context) {
    if (stage == null) return const SizedBox(height: 10);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final s in MissionStage.values)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: s == stage ? 28 : 10,
            height: 8,
            decoration: BoxDecoration(
              color: s.index <= stage!.index ? AppColors.gold : AppColors.parchmentDark,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _MissionHeader extends StatelessWidget {
  const _MissionHeader({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(mission.location, style: AppText.logo(size: 30), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(mission.title, style: AppText.subtitle(color: AppColors.goldDeep), textAlign: TextAlign.center),
      ],
    );
  }
}

// STEP 1 — the scene. One action: open the sealed letter.
class _StoryStage extends StatelessWidget {
  const _StoryStage({super.key, required this.mission, required this.onOpened});

  final Mission mission;
  final VoidCallback onOpened;

  @override
  Widget build(BuildContext context) {
    final m = mission;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
      children: [
        _MissionHeader(mission: m),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 16 / 10,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.navy, width: 3),
              boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 6))],
            ),
            child: LandmarkArt(m.scene, borderRadius: 23),
          ),
        ),
        const SizedBox(height: 18),
        for (final (i, line) in m.story.indexed)
          _FadeIn(
            delay: Duration(milliseconds: 200 + i * 450),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlossaryText(line, style: AppText.bodyText(size: 19), textAlign: TextAlign.center),
            ),
          ),
        _FadeIn(
          delay: Duration(milliseconds: 200 + m.story.length * 450),
          child: GlossaryText(
            m.letterIntro,
            style: AppText.bodyText(size: 18, weight: FontWeight.w800, color: AppColors.navy),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        EnvelopeReveal(letterText: m.letter, onOpened: onOpened),
      ],
    );
  }
}

// STEP 2 — read the letter. One action: go solve.
class _LetterStage extends StatelessWidget {
  const _LetterStage({super.key, required this.mission, required this.onDone});

  final Mission mission;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 40),
      children: [
        Text('THE LETTER', style: AppText.eyebrow(), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        LetterCard(text: mission.letter),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.touch_app_rounded, size: 18, color: AppColors.royalBlue),
            const SizedBox(width: 6),
            Flexible(
              child: Text('Tap a dotted word to see what it means.',
                  style: AppText.caption(color: AppColors.royalBlue)),
            ),
          ],
        ),
        const SizedBox(height: 22),
        GameButton(
          label: 'I READ IT! SOLVE THE PUZZLE',
          icon: Icons.extension_rounded,
          style: GameButtonStyle.gold,
          onPressed: onDone,
        ),
      ],
    );
  }
}

// STEP 3 — the puzzle. One action: answer (tips are optional helpers).
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        Row(
          children: [
            const Icon(Icons.extension_rounded, color: AppColors.goldDeep),
            const SizedBox(width: 8),
            Expanded(child: Text('PUZZLE · ${mission.location}', style: AppText.eyebrow())),
            TextButton.icon(
              onPressed: onReread,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: const Icon(Icons.mail_rounded, color: AppColors.royalBlue),
              label: Text('Letter', style: AppText.button(size: 15, color: AppColors.royalBlue)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GlossaryText(mission.question, style: AppText.title(size: 25)),
        const SizedBox(height: 18),
        ShakeOnChange(trigger: wrongPulse, child: child),
        const SizedBox(height: 22),
        TipsPanel(hints: mission.hints, revealed: hintsShown, onReveal: onHint),
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
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
      children: [
        _MissionHeader(mission: m),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.successSoft,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.success, width: 2),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.success, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MISSION SOLVED', style: AppText.eyebrow(color: AppColors.success)),
                    Text(m.successMessage, style: AppText.bodyText(size: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LetterCard(text: m.letter),
        if (m.clue != null) ...[
          const SizedBox(height: 16),
          ClueCard(clue: m.clue!, index: clues.indexWhere((c) => c.id == m.clue!.id), location: m.location),
        ],
        if (m.evidence != null) ...[
          const SizedBox(height: 12),
          SizedBox(height: 170, child: EvidenceTile(evidence: m.evidence!, location: m.location)),
        ],
        const SizedBox(height: 20),
        GameButton(
          label: 'BACK TO MAP',
          icon: Icons.map_rounded,
          style: GameButtonStyle.gold,
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
      duration: const Duration(milliseconds: 500),
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.3),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
