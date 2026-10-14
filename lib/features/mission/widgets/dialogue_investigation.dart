import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart';
import '../../../data/models/dialogue.dart';
import '../../../widgets/art_assets.dart';
import '../../../widgets/detective_tips.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/guided_action_indicator.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/paper.dart';
import '../../../widgets/paper_background.dart';
import '../../../widgets/place_scenery.dart';
import '../../game/game_providers.dart';

/// A mission played by talking to the people at its place (see
/// [DialogueScene]): the room behind them, the person talked to and what
/// they say in the middle, and under it who to talk to, what to ask, and
/// the statements to compare.
///
/// What was asked and heard lives in [progress], kept by the page that
/// shows the talk (going back to the place and in again keeps it); it is
/// not saved: after a restart the talk begins again. Once two statements
/// are linked that answer the deduction, [onComplete] is called once with
/// the scene's answer (the mission's puzzle answer).
class DialogueInvestigation extends ConsumerStatefulWidget {
  const DialogueInvestigation({
    super.key,
    required this.scene,
    required this.progress,
    required this.onChanged,
    required this.onComplete,
    required this.hints,
    required this.hintsShown,
    required this.onHint,
    this.onNotes,
  });

  final DialogueScene scene;
  final DialogueProgress progress;

  /// Something was asked or heard (the page shows how many statements).
  final VoidCallback onChanged;
  final ValueChanged<String> onComplete;

  final List<String> hints;
  final int hintsShown;

  /// Asks for the next tip; true when one was opened.
  final Future<bool> Function() onHint;

  /// The statements were opened to read again.
  final VoidCallback? onNotes;

  @override
  ConsumerState<DialogueInvestigation> createState() => _DialogueInvestigationState();
}

class _DialogueInvestigationState extends ConsumerState<DialogueInvestigation> {
  bool _solved = false;
  bool _completed = false;

  /// The statements needed to compare were just heard (on this page): the
  /// COMPARE button is shown once with a little gold, until it is used.
  bool _ready = false;

  /// Comparing is open: nothing on the talk is pointed at under it.
  bool _comparing = false;

  /// What the guide arrow can point at (see [_guide]).
  final _lineupLink = GuideLink();
  final _carryLink = GuideLink();
  final _compareLink = GuideLink();

  DialogueProgress get _p => widget.progress;

  /// Another witness is the next thing (one was heard on the topic, the one
  /// talked to has told it, comparing is not yet the thing): every witness
  /// not asked yet is marked alike — whom to ask is the detective's, and
  /// the one already asked is never pointed at.
  bool get _inviteOthers {
    if (_completed || _comparing || _p.speakerId == null) return false;
    final scene = widget.scene;
    final stories = scene.comparable(_p.heard);
    final canCompare = scene.canCompare(_p.heard);
    final different = canCompare && _p.differentAt == stories.length;
    return stories.isNotEmpty && (!canCompare || different) && _p.hasAsked(_p.speakerId!, scene.deduction.topic);
  }

  /// The one next thing to point at, as far as the detective has got — a
  /// place to act, never a witness or an answer: the people (arriving), the
  /// mission's question (a witness not asked it yet), the witnesses' faces
  /// (another witness is next), COMPARE (enough heard). Null: nothing.
  ({String step, GuideLink link, GuideSide side, double along, Color color, Duration delay, bool span})? _guide() {
    if (_completed || _comparing) return null;
    final scene = widget.scene;
    final topic = scene.deduction.topic;
    final speaker = _p.speakerId;
    if (speaker == null) {
      final still = _p.introSeen || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
      return (
        step: 'lineup',
        link: _lineupLink,
        side: GuideSide.above,
        along: 0,
        color: AppColors.goldLight,
        delay: still ? Duration.zero : const Duration(milliseconds: 1300),
        // All three, none favoured: the middle print is not the one meant.
        span: true,
      );
    }
    final stories = scene.comparable(_p.heard);
    final canCompare = scene.canCompare(_p.heard);
    final different = canCompare && _p.differentAt == stories.length;
    if (canCompare && !different) {
      // After the gold of COMPARE coming in has settled.
      return (
        step: 'compare-${stories.length}',
        link: _compareLink,
        side: GuideSide.above,
        along: 0,
        color: AppColors.goldDeep,
        delay: _ready ? const Duration(milliseconds: 700) : Duration.zero,
        span: false,
      );
    }
    if (!_p.hasAsked(speaker, topic)) {
      // Between the first two faces above it: never on a face or a name.
      return (
        step: 'ask-$speaker',
        link: _carryLink,
        side: GuideSide.above,
        along: -0.28,
        color: AppColors.goldDeep,
        delay: Duration.zero,
        span: false,
      );
    }
    return null;
  }

  void _talkTo(String id) {
    if (_completed) return;
    if (_p.speakerId == id && _p.questionId == null) return;
    playUiTap(context, TapRole.select);
    setState(() {
      _p.introSeen = true;
      _p.talkTo(id);
    });
    widget.onChanged();
  }

  void _ask(String questionId) {
    if (_completed || _p.speakerId == null) return;
    // Comparing opens when two witnesses have said what he carried (matching
    // or not: telling whether they match is the detective's).
    final before = widget.scene.canCompare(_p.heard);
    setState(() {
      _p.ask(widget.scene, questionId);
      if (!before && widget.scene.canCompare(_p.heard)) _ready = true;
    });
    if (_p.fresh != null) {
      ref.read(audioServiceProvider).play(GameSound.pencilNote);
      HapticFeedback.selectionClick();
    } else {
      playUiTap(context, TapRole.select);
    }
    widget.onChanged();
  }

  Future<void> _notes() async {
    widget.onNotes?.call();
    ref.read(audioServiceProvider).play(GameSound.paperRustle);
    await showDialogueNotes(
      context,
      scene: widget.scene,
      heard: _p.heard,
      hints: widget.hints,
      hintsShown: widget.hintsShown,
    );
  }

  Future<void> _tip() async {
    if (await widget.onHint() && mounted) {
      // The tip is written with the statements, where it is read.
      await showDialogueNotes(
        context,
        scene: widget.scene,
        heard: _p.heard,
        hints: widget.hints,
        hintsShown: widget.hintsShown + 1,
      );
    }
  }

  void _toggleOthers() {
    playUiTap(context, TapRole.select);
    setState(() => _p.othersOpen = !_p.othersOpen);
  }

  Future<void> _compare() async {
    if (_completed) return;
    setState(() {
      _ready = false;
      _comparing = true;
    });
    ref.read(audioServiceProvider).play(GameSound.paperRustle);
    final stories = widget.scene.comparable(_p.heard);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: paperSheetShape,
      showDragHandle: false,
      builder: (context) => _CompareSheet(
        scene: widget.scene,
        stories: stories,
        onSolved: () => _solved = true,
        // Rightly found different, with no one else to compare them with:
        // the next thing is another witness (until one more is heard).
        onDifferent: () => _p.differentAt = stories.length,
      ),
    );
    if (!mounted) return;
    setState(() => _comparing = false);
    // Matched: the answer, once (also when the sheet was closed early).
    if (_solved && !_completed) {
      _completed = true;
      widget.onComplete(widget.scene.deduction.answer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final canCompare = scene.canCompare(_p.heard);
    final guide = _guide();
    return Stack(
      fit: StackFit.expand,
      children: [
        PlaceScenery.file(scene.background),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                child: _p.speakerId == null
                    ? _Arrival(
                        key: const ValueKey('talk-intro'),
                        scene: scene,
                        instant: _p.introSeen,
                        lineupLink: _lineupLink,
                        onTalkTo: _talkTo,
                      )
                    : _Conversation(
                        key: ValueKey('talk-${_p.speakerId}'),
                        scene: scene,
                        speaker: scene.speaker(_p.speakerId!),
                        question: _p.questionId == null
                            ? null
                            : scene.questions.firstWhere((q) => q.id == _p.questionId),
                        fresh: _p.fresh,
                      ),
              ),
            ),
            _TalkPanel(
              scene: scene,
              progress: _p,
              canCompare: canCompare,
              ready: _ready,
              tipLabel: nextTipLabel(widget.hints, widget.hintsShown),
              carryLink: _carryLink,
              invite: _inviteOthers,
              compareLink: _compareLink,
              onTalkTo: _talkTo,
              onAsk: _ask,
              onToggleOthers: _toggleOthers,
              onCompare: _compare,
              onNotes: _notes,
              onTip: _tip,
            ),
          ],
        ),
        if (guide != null)
          GuidedActionIndicator(
            key: ValueKey('guide-${guide.step}'),
            link: guide.link,
            side: guide.side,
            along: guide.along,
            color: guide.color,
            delay: guide.delay,
            span: guide.span,
          ),
      ],
    );
  }
}

// ── The middle: arriving, then the person talked to ───────────────────────

/// Arriving: the mission first (what to find out, and why the witnesses),
/// then the three people in a row, each one a print to tap and talk to —
/// the only way to choose here (the panel's small faces come with the
/// talk). The lines come in once (about a second); coming back shows them
/// at once.
class _Arrival extends StatelessWidget {
  const _Arrival({
    super.key,
    required this.scene,
    required this.instant,
    required this.lineupLink,
    required this.onTalkTo,
  });

  final DialogueScene scene;
  final bool instant;

  /// The row of people, for the guide arrow (the whole row: never one).
  final GuideLink lineupLink;
  final ValueChanged<String> onTalkTo;

  /// The lines keep about this much height; the row of people takes the
  /// rest, within [_lineupLeast]..[_lineupMost].
  static const _linesRoom = 210.0;
  static const _lineupLeast = 130.0;
  static const _lineupMost = 290.0;

  @override
  Widget build(BuildContext context) {
    final still = instant || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    return InkSurface(
      night: true,
      child: LayoutBuilder(
        builder: (context, box) {
          // Never taller than the prints themselves (they fill their width):
          // the row is the people, with no empty band over them — what the
          // guide arrow points at is them.
          final printWidth = (box.maxWidth - 2 * AppSpace.md - 6 * AppSpace.xs) / scene.speakers.length;
          final nameRoom = AppSpace.sm + MediaQuery.textScalerOf(context).scale(14) * 1.5;
          final natural = printWidth / ArtAssets.witnessPortraitAspect + nameRoom + AppSpace.md;
          final lineup = math.min((box.maxHeight - _linesRoom).clamp(_lineupLeast, _lineupMost), natural);
          return Column(
            children: [
              Expanded(child: _lines(still)),
              _FadeUp(
                delay: still ? Duration.zero : const Duration(milliseconds: 1000),
                child: SizedBox(
                  key: const ValueKey('talk-lineup'),
                  height: lineup,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.md),
                    child: GuideTarget(
                      link: lineupLink,
                      child: Row(
                        children: [
                          for (final s in scene.speakers)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                                child: _LineupPrint(speaker: s, onTap: () => onTalkTo(s.id)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _lines(bool still) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.lg, AppSpace.screen, AppSpace.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FadeUp(
              delay: still ? Duration.zero : const Duration(milliseconds: 150),
              child: Text(
                'YOUR MISSION',
                textAlign: TextAlign.center,
                style: AppText.eyebrow(color: AppColors.goldLight),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            _FadeUp(
              delay: still ? Duration.zero : const Duration(milliseconds: 300),
              child: GlossaryText(
                scene.goal,
                key: const ValueKey('talk-goal'),
                textAlign: TextAlign.center,
                linkColor: AppColors.goldLight,
                style: AppText.title(size: 23, color: AppColors.paperLight),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            _FadeUp(
              delay: still ? Duration.zero : const Duration(milliseconds: 650),
              child: GlossaryText(
                scene.how,
                textAlign: TextAlign.center,
                linkColor: AppColors.goldLight,
                style: AppText.bodyText(size: 17, color: AppColors.paperLight.withValues(alpha: 0.85)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One of the people in the arrival's row: their print, their name under
/// it; a tap talks to them.
class _LineupPrint extends StatelessWidget {
  const _LineupPrint({required this.speaker, required this.onTap});

  final DialogueSpeaker speaker;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Talk to ${speaker.name.toLowerCase()}',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('lineup-${speaker.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // The name right under its print (the print as large as fits).
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: AspectRatio(
                aspectRatio: ArtAssets.witnessPortraitAspect,
                child: PaperSheet(
                  padding: const EdgeInsets.all(AppSpace.xs),
                  child: Image.asset(
                    speaker.portrait,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                    errorBuilder: (context, error, stack) => const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                speaker.name.replaceFirst('The ', ''),
                maxLines: 1,
                style: AppText.mark(color: AppColors.goldLight, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The person talked to: their portrait (a print on parchment), their name
/// plate, and what they just said, under what they were asked. A statement
/// heard for the first time is marked NEW STATEMENT.
///
/// A tall space stacks the portrait over the words; otherwise they stand
/// side by side, the portrait as tall as the space allows (never more than
/// half the width, so the words keep a readable column) and the words'
/// card pointing to it: the person and what they say are one scene.
class _Conversation extends StatelessWidget {
  const _Conversation({
    super.key,
    required this.scene,
    required this.speaker,
    required this.question,
    required this.fresh,
  });

  final DialogueScene scene;
  final DialogueSpeaker speaker;
  final DialogueQuestion? question;
  final String? fresh;

  /// From this height the portrait stands over the words, leaving them about
  /// [_wordsRoom]; below it, beside them.
  static const _stackFrom = 470.0;
  static const _wordsRoom = 190.0;

  @override
  Widget build(BuildContext context) {
    final answer = question == null ? null : speaker.answers[question!.id];
    _Speech words({required bool beside}) => _Speech(
      speaker: speaker,
      question: question,
      line: answer?.line ?? speaker.greeting,
      isNew: fresh != null && answer?.statementId == fresh,
      beside: beside,
    );
    // The mission, one quiet line over the talk: what the questions are for.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MissionStrip(goal: scene.goal),
        Expanded(child: _scene(words)),
      ],
    );
  }

  Widget _scene(_Speech Function({required bool beside}) words) {
    return LayoutBuilder(
      builder: (context, box) {
        const pad = AppSpace.lg;
        const vpad = AppSpace.sm;
        final w = box.maxWidth - 2 * pad;
        final h = box.maxHeight - 2 * vpad;
        if (h >= _stackFrom) {
          final portraitHeight = (h - _wordsRoom).clamp(200.0, 340.0);
          return Padding(
            padding: const EdgeInsets.fromLTRB(pad, vpad, pad, vpad),
            child: Column(
              children: [
                SizedBox(
                  height: portraitHeight,
                  child: _Portrait(speaker: speaker),
                ),
                const SizedBox(height: AppSpace.sm),
                Expanded(child: words(beside: false)),
              ],
            ),
          );
        }
        const aspect = ArtAssets.witnessPortraitAspect;
        // The words keep a readable width first (wider with larger text):
        // on a small screen the person gives way, never what they say.
        final wordsWidth = MediaQuery.textScalerOf(context).scale(1) > 1.1 ? 215.0 : 160.0;
        final portraitWidth = math.max(0.0, math.min(math.min(w * 0.5, h * aspect), w - wordsWidth - AppSpace.md - 4));
        return Padding(
          padding: const EdgeInsets.fromLTRB(pad, vpad, pad, vpad),
          child: Row(
            children: [
              SizedBox(
                width: portraitWidth,
                height: portraitWidth / aspect,
                child: _Portrait(speaker: speaker),
              ),
              const SizedBox(width: AppSpace.md + 4),
              Expanded(
                child: SizedBox(height: h, child: words(beside: true)),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A portrait printed on parchment, whole (never cropped or stretched).
class _Portrait extends StatelessWidget {
  const _Portrait({required this.speaker});

  final DialogueSpeaker speaker;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: '${speaker.name}: ${speaker.description}',
      child: Center(
        child: AspectRatio(
          aspectRatio: ArtAssets.witnessPortraitAspect,
          child: PaperSheet(
            key: const ValueKey('talk-portrait'),
            padding: const EdgeInsets.all(AppSpace.xs),
            child: Image.asset(
              speaker.portrait,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stack) => const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

/// What was asked (small, the detective's) and the answer (the person's,
/// larger, in their paper card), with their name plate.
class _Speech extends StatelessWidget {
  const _Speech({
    required this.speaker,
    required this.question,
    required this.line,
    required this.isNew,
    this.beside = false,
  });

  final DialogueSpeaker speaker;
  final DialogueQuestion? question;
  final String line;
  final bool isNew;

  /// Beside the portrait: the words sit level with the person, and their
  /// card points to them.
  final bool beside;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final edge = isNew ? AppColors.gold : AppLine.faint();
    final edgeWidth = isNew ? AppLine.ink : AppLine.hairline;
    return Column(
      mainAxisAlignment: beside ? MainAxisAlignment.center : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // One line, never wrapped (a long name is set a little smaller).
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            speaker.title,
            key: const ValueKey('talk-name'),
            maxLines: 1,
            style: AppText.mark(color: AppColors.goldLight, size: 15),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Flexible(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              TweenAnimationBuilder<double>(
                key: ValueKey('${question?.id}|$line'),
                tween: Tween(begin: still ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                builder: (context, t, child) => Opacity(opacity: t, child: child),
                child: Container(
                  key: const ValueKey('talk-speech'),
                  decoration: BoxDecoration(
                    color: AppColors.paperLight,
                    borderRadius: BorderRadius.circular(AppRadius.paper),
                    border: Border.all(color: edge, width: edgeWidth),
                    boxShadow: AppShadow.onNight,
                  ),
                  child: InkSurface(
                    night: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // NEW STATEMENT over the answer (always in sight); the
                          // question asked is the one marked in the list below.
                          if (isNew) ...[
                            Row(
                              key: const ValueKey('new-statement'),
                              children: [
                                const InkIcon(InkGlyph.pen, size: AppIconSize.tiny, color: AppColors.burgundy),
                                const SizedBox(width: AppSpace.xs),
                                // One line, set smaller in a narrow card.
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'NEW STATEMENT',
                                      maxLines: 1,
                                      style: AppText.eyebrow(color: AppColors.burgundy),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpace.xs),
                          ],
                          // Beside the person with larger text, a little smaller:
                          // a long answer still reads whole in a short space.
                          GlossaryText(
                            '"$line"',
                            style: AppText.letter(
                              size: beside && MediaQuery.textScalerOf(context).scale(1) > 1.1 ? 16 : 18,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // The card's point, toward the person speaking.
              if (beside)
                Positioned(
                  left: -11,
                  top: 22,
                  child: CustomPaint(
                    size: const Size(12, 22),
                    painter: _CardPoint(fill: AppColors.paperLight, edge: edge, width: edgeWidth),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The small point on the left of a speech card, toward the speaker: paper
/// filled, its two outer sides in the card's edge ink.
class _CardPoint extends CustomPainter {
  const _CardPoint({required this.fill, required this.edge, required this.width});

  final Color fill;
  final Color edge;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    // Over the card's edge by a pixel, so the paper runs on without a seam.
    final tip = Offset(0, size.height / 2);
    final top = Offset(size.width + 1, 0);
    final bottom = Offset(size.width + 1, size.height);
    canvas.drawPath(
      Path()
        ..moveTo(top.dx, top.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(bottom.dx, bottom.dy)
        ..close(),
      Paint()..color = fill,
    );
    canvas.drawPath(
      Path()
        ..moveTo(top.dx - 1, top.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(bottom.dx - 1, bottom.dy),
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CardPoint old) => old.fill != fill || old.edge != edge || old.width != width;
}

/// The mission, one line over the talk: a magnifier and what to find out.
class _MissionStrip extends StatelessWidget {
  const _MissionStrip({required this.goal});

  final String goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('talk-mission'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xs + 2),
      color: AppColors.navyDeep.withValues(alpha: 0.55),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const InkIcon(InkGlyph.search, size: AppIconSize.small, color: AppColors.goldLight),
          const SizedBox(width: AppSpace.sm),
          // One line, a little smaller if it must (it stays a reminder).
          Flexible(
            child: Text(
              goal,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.1),
              textAlign: TextAlign.center,
              style: AppText.bodyText(size: 15, weight: FontWeight.w600, color: AppColors.goldLight),
            ),
          ),
        ],
      ),
    );
  }
}

// ── The bottom: who to talk to, what to ask, comparing ───────────────────

class _TalkPanel extends StatelessWidget {
  const _TalkPanel({
    required this.scene,
    required this.progress,
    required this.canCompare,
    required this.ready,
    required this.tipLabel,
    required this.carryLink,
    required this.compareLink,
    required this.invite,
    required this.onTalkTo,
    required this.onAsk,
    required this.onToggleOthers,
    required this.onCompare,
    required this.onNotes,
    required this.onTip,
  });

  final DialogueScene scene;
  final DialogueProgress progress;
  final bool canCompare;

  /// Enough statements were just heard: COMPARE is shown with a little gold
  /// once.
  final bool ready;
  final String? tipLabel;

  /// What the guide arrow can point at: the mission's question, COMPARE.
  final GuideLink carryLink;
  final GuideLink compareLink;

  /// Mark every witness not asked yet alike (another witness is next).
  final bool invite;
  final ValueChanged<String> onTalkTo;
  final ValueChanged<String> onAsk;
  final VoidCallback onToggleOthers;
  final VoidCallback onCompare;
  final VoidCallback onNotes;
  final VoidCallback onTip;

  static const _counts = ['NO', 'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE'];

  /// The guide arrow's room under a step's line: the arrow at rest, its
  /// gap, and a bracket when it points at a whole row (its nod reaches into
  /// the line's own margin).
  static const _arrowRoom =
      GuidedActionIndicator.length + 2 * GuidedActionIndicator.gap + GuidedActionIndicator.bracket + 1;

  @override
  Widget build(BuildContext context) {
    final speaker = progress.speakerId;
    final d = scene.deduction;
    final stories = scene.comparable(progress.heard);
    final witnesses = scene.witnessesHeard(progress.heard);
    // Two stories rightly found different, nothing new heard since: the
    // next thing is another witness, so COMPARE steps back.
    final different = canCompare && progress.differentAt == stories.length;
    // One next thing at a time (never who to ask): before a witness, choose
    // one; after one on the topic, ask another; then compare.
    final (String? mark, String? line) = switch (null) {
      _ when speaker == null => (null, scene.guide),
      _ when different => ('DIFFERENT STORIES', d.differentLine),
      _ when canCompare => ('${_counts[math.min(stories.length, _counts.length - 1)]} STORIES COLLECTED', d.readyLine),
      _ when witnesses > 0 => ('CLUE FOUND', d.foundLine),
      _ => (null, null),
    };
    final topic = scene.questions.firstWhere((q) => q.id == d.topic);
    final others = [
      for (final q in scene.questions)
        if (q.id != d.topic) q,
    ];
    return ConstrainedBox(
      // Never more than about half the screen: the person and what they
      // say stay in sight (the rest of the panel scrolls).
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.54),
      child: DecoratedBox(
        key: const ValueKey('talk-panel'),
        decoration: BoxDecoration(
          color: AppColors.paperLight,
          border: Border(
            top: BorderSide(color: AppColors.goldLight.withValues(alpha: 0.7), width: AppLine.rule),
          ),
          boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 12, offset: Offset(0, -2))],
        ),
        child: InkSurface(
          night: false,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (line != null) _Status(mark: mark, line: line, guide: speaker == null),
                  // Room for the guide arrow under a step's line, pointing at
                  // what comes next (COMPARE, or the faces).
                  if (mark != null) const SizedBox(height: _arrowRoom),
                  // Comparing, the next thing once there is enough to compare.
                  if (canCompare && !different) ...[
                    GuideTarget(
                      link: compareLink,
                      child: _CompareButton(ready: ready, quiet: false, onPressed: onCompare),
                    ),
                    const SizedBox(height: AppSpace.xs),
                  ],
                  // Arriving, the people are chosen from their prints above;
                  // talking, from their faces here.
                  if (speaker != null) ...[
                    Row(
                      key: const ValueKey('talk-faces'),
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final s in scene.speakers)
                          Expanded(
                            child: _SpeakerChoice(
                              speaker: s,
                              chosen: s.id == speaker,
                              found: progress.hasAsked(s.id, d.topic),
                              invite: invite && !progress.hasAsked(s.id, d.topic),
                              onTap: () => onTalkTo(s.id),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.sm),
                    // The mission's question first and largest; the others
                    // are there to open, never in its way.
                    GuideTarget(
                      link: carryLink,
                      child: _QuestionChoice(
                        key: ValueKey('question-${topic.id}'),
                        question: topic,
                        lead: true,
                        asked: progress.hasAsked(speaker, topic.id),
                        current: progress.questionId == topic.id,
                        onTap: () => onAsk(topic.id),
                      ),
                    ),
                    _OthersToggle(open: progress.othersOpen, onTap: onToggleOthers),
                    // Side by side: opening them leaves the person in sight.
                    if (progress.othersOpen)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.xs),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final q in others) ...[
                                if (q != others.first) const SizedBox(width: AppSpace.sm),
                                Expanded(
                                  child: _QuestionChoice(
                                    key: ValueKey('question-${q.id}'),
                                    question: q,
                                    asked: progress.hasAsked(speaker, q.id),
                                    current: progress.questionId == q.id,
                                    onTap: () => onAsk(q.id),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                  // Found different: comparing again waits below, quietly
                  // (another witness is the next thing).
                  if (different) ...[
                    const SizedBox(height: AppSpace.xs),
                    _CompareButton(ready: false, quiet: true, onPressed: onCompare),
                  ],
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpace.sm,
                    children: [
                      if (speaker != null)
                        InkTextButton(
                          key: const ValueKey('open-statements'),
                          label: 'Statements (${progress.heard.length})',
                          glyph: InkGlyph.letter,
                          onPressed: onNotes,
                        ),
                      if (tipLabel != null)
                        InkTextButton(label: tipLabel!, glyph: InkGlyph.hint, color: tipLinkColor, onPressed: onTip),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Where the detective has got, and the next thing to do: a small mark
/// (CLUE FOUND) over one short line. Arriving, the line alone ([guide]).
class _Status extends StatelessWidget {
  const _Status({required this.mark, required this.line, required this.guide});

  final String? mark;
  final String line;
  final bool guide;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: guide ? AppSpace.md : AppSpace.xs),
      child: TweenAnimationBuilder<double>(
        // Comes in softly as it changes: something has happened.
        key: ValueKey('$mark|$line'),
        tween: Tween(begin: still ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        builder: (context, t, child) => Opacity(opacity: t, child: child),
        child: Column(
          key: const ValueKey('talk-status'),
          children: [
            if (mark != null)
              Text(
                mark!,
                key: const ValueKey('talk-mark'),
                textAlign: TextAlign.center,
                style: AppText.eyebrow(color: AppColors.goldDeep),
              ),
            Text(
              line,
              key: ValueKey(guide ? 'talk-guide' : 'talk-next'),
              textAlign: TextAlign.center,
              style: AppText.bodyText(size: guide ? 18 : 16, weight: FontWeight.w600, color: AppColors.navy),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Other questions": opens and closes the questions besides the mission's.
class _OthersToggle extends StatelessWidget {
  const _OthersToggle({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      expanded: open,
      label: 'Other questions',
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('other-questions'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Other questions',
                style: AppText.bodyText(size: 15, weight: FontWeight.w600, color: AppColors.royalBlue),
              ),
              const SizedBox(width: AppSpace.xs),
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                child: const InkIcon(InkGlyph.down, size: AppIconSize.tiny, color: AppColors.royalBlue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// COMPARE STORIES. When it has just become possible ([ready]), it comes
/// in once with a gold edge and a soft glow that settles (still with motion
/// reduced: the gold edge only). [quiet]: comparing is not the next thing
/// (the stories heard were found different), an outline.
class _CompareButton extends StatelessWidget {
  const _CompareButton({required this.ready, required this.quiet, required this.onPressed});

  final bool ready;
  final bool quiet;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final button = GameButton(
      key: const ValueKey('compare-statements'),
      label: 'COMPARE STORIES',
      glyph: InkGlyph.eye,
      singleLine: true,
      style: quiet ? GameButtonStyle.outline : GameButtonStyle.navy,
      onPressed: onPressed,
    );
    if (!ready) return button;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      key: const ValueKey('compare-ready'),
      tween: Tween(begin: still ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.button + 3),
          border: Border.all(color: AppColors.gold, width: AppLine.ink),
          boxShadow: [
            BoxShadow(
              color: AppColors.goldLight.withValues(alpha: 0.7 * (1 - t)),
              blurRadius: 4 + 16 * (1 - t),
              spreadRadius: 3 * (1 - t),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Transform.scale(scale: 0.95 + 0.05 * t, child: child),
        ),
      ),
      child: button,
    );
  }
}

/// A witness to choose: their face in a round frame, their name under it,
/// a gold ring when they are the one talked to, and a green tick once they
/// have told what the mission asks ([found]).
class _SpeakerChoice extends StatelessWidget {
  const _SpeakerChoice({
    required this.speaker,
    required this.chosen,
    required this.found,
    required this.onTap,
    this.invite = false,
  });

  final DialogueSpeaker speaker;
  final bool chosen;
  final bool found;

  /// One of the witnesses to ask next: a small still arrow over the face,
  /// the same on each of them.
  final bool invite;
  final VoidCallback onTap;

  static const size = 44.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: chosen,
      label: 'Talk to ${speaker.name.toLowerCase()}${found ? ', story heard' : (invite ? ', not asked yet' : '')}',
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('speaker-${speaker.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
          child: Column(
            children: [
              SizedBox.square(
                dimension: size + 6,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: size + 6,
                      height: size + 6,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: chosen ? AppColors.gold : AppLine.faint(0.3),
                          width: chosen ? AppLine.ink + 1 : AppLine.rule,
                        ),
                      ),
                      child: ClipOval(child: _Face(speaker: speaker)),
                    ),
                    if (invite)
                      Positioned(
                        key: ValueKey('invite-${speaker.id}'),
                        top: -(GuideMark.length + 5),
                        left: (size + 6 - GuideMark.width) / 2,
                        child: const GuideMark(),
                      ),
                    if (found)
                      Positioned(
                        right: -4,
                        bottom: -2,
                        child: Container(
                          key: ValueKey('found-${speaker.id}'),
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success,
                            border: Border.all(color: AppColors.paperLight, width: AppLine.rule),
                          ),
                          child: const InkIcon(InkGlyph.check, size: 12, color: AppColors.paperLight),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                speaker.name.replaceFirst('The ', ''),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // A label under the face: it keeps its size with larger text.
                textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.1),
                style: AppText.style(
                  AppText.body,
                  size: 13,
                  weight: chosen ? FontWeight.w700 : FontWeight.w500,
                  color: chosen ? AppColors.navy : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The face part of a portrait, enlarged in its round frame.
class _Face extends StatelessWidget {
  const _Face({required this.speaker});

  final DialogueSpeaker speaker;

  /// How much of the portrait's width the round frame shows.
  static const _span = 0.42;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final d = box.maxWidth;
        final w = d / _span;
        final h = w / ArtAssets.witnessPortraitAspect;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: w,
            maxWidth: w,
            minHeight: h,
            maxHeight: h,
            child: Transform.translate(
              offset: Offset(d / 2 - speaker.face.dx * w, d / 2 - speaker.face.dy * h),
              child: Image.asset(
                speaker.portrait,
                width: w,
                height: h,
                fit: BoxFit.fill,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stack) => const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A question to put to the person talked to: a paper strip, ticked once
/// asked (it can be asked again to hear the answer again); the one just
/// asked is inked in soft blue — marked, never as loud as the next thing
/// to do (COMPARE). The mission's
/// question ([lead]) is the larger one, gold-edged until asked.
class _QuestionChoice extends StatelessWidget {
  const _QuestionChoice({
    super.key,
    required this.question,
    required this.asked,
    required this.current,
    required this.onTap,
    this.lead = false,
  });

  final DialogueQuestion question;

  /// The mission's question: larger, marked (a magnifier, a gold edge)
  /// until asked.
  final bool lead;
  final bool asked;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: current,
      label: '${question.text}${asked ? ', asked' : ''}',
      excludeSemantics: true,
      child: Material(
        color: current ? AppColors.royalBlueSoft : AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          side: BorderSide(
            color: current ? AppColors.navy : (lead && !asked ? AppColors.gold : AppLine.faint(0.25)),
            width: current || (lead && !asked) ? AppLine.ink : AppLine.hairline,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.paper),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: lead ? 56 : 48),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: lead ? AppSpace.md : AppSpace.sm, vertical: AppSpace.sm),
              child: Row(
                children: [
                  InkIcon(
                    asked ? InkGlyph.check : (lead ? InkGlyph.search : InkGlyph.arrow),
                    size: lead ? AppIconSize.medium : AppIconSize.small,
                    color: asked ? AppColors.success : AppColors.navy,
                  ),
                  SizedBox(width: lead ? AppSpace.md : AppSpace.sm),
                  Expanded(
                    child: Text(
                      question.text,
                      style: AppText.bodyText(size: lead ? 19 : 15, weight: FontWeight.w600, color: AppColors.navy),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sheets: the statements, and comparing two of them ────────────────────

/// The statements heard so far, under who said them, and the tips opened.
Future<void> showDialogueNotes(
  BuildContext context, {
  required DialogueScene scene,
  required List<String> heard,
  required List<String> hints,
  required int hintsShown,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: paperSheetShape,
    showDragHandle: false,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: SingleChildScrollView(
          key: const ValueKey('statements-sheet'),
          padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PaperSheetTab(),
              PaperSheet(
                ruled: true,
                padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('STATEMENTS', style: AppText.eyebrow())),
                        Text('${heard.length} / ${scene.statements.length}', style: AppText.mark(size: 14)),
                      ],
                    ),
                    const SizedBox(height: AppSpace.sm),
                    if (heard.isEmpty)
                      Text('Nothing yet. Ask the witnesses what they saw.', style: AppText.caption())
                    else
                      for (final id in heard) ...[
                        const SizedBox(height: AppSpace.sm),
                        _StatementLine(scene: scene, statement: scene.statement(id)),
                      ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              DetectiveTipNotes(hints: hints, revealed: hintsShown),
              GameButton(label: 'BACK TO THE WITNESSES', onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    ),
  );
}

/// One statement: who said it (face and name), and its words.
class _StatementLine extends StatelessWidget {
  const _StatementLine({required this.scene, required this.statement});

  final DialogueScene scene;
  final DialogueStatement statement;

  @override
  Widget build(BuildContext context) {
    final who = scene.speaker(statement.speakerId);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox.square(
          dimension: 36,
          child: ClipOval(child: _Face(speaker: who)),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(who.title, style: AppText.eyebrow(color: AppColors.muted)),
              GlossaryText('"${statement.text}"', style: AppText.letter(size: 17)),
            ],
          ),
        ),
      ],
    );
  }
}

/// What the detective's yes or no about two stories turned out to be.
enum _Verdict {
  /// Wrong (either way): look again, on the same page.
  lookAgain,

  /// Rightly different, with a third story there to compare instead.
  otherPair,

  /// Rightly different, and no one else heard yet: ask another witness.
  different,

  /// Rightly the same: the answer.
  match,
}

/// Comparing stories: two witnesses' stories side by side, and the
/// detective says whether they match. With two stories heard they are
/// shown at once; with more, two witnesses are chosen first (and can be
/// changed). Never chosen for the detective, never told which way.
class _CompareSheet extends ConsumerStatefulWidget {
  const _CompareSheet({required this.scene, required this.stories, required this.onSolved, required this.onDifferent});

  final DialogueScene scene;

  /// The statements on the deduction's topic heard, one per witness, in the
  /// order heard.
  final List<String> stories;
  final VoidCallback onSolved;

  /// Two stories rightly found different, with no third to compare.
  final VoidCallback onDifferent;

  @override
  ConsumerState<_CompareSheet> createState() => _CompareSheetState();
}

class _CompareSheetState extends ConsumerState<_CompareSheet> {
  late final bool _choosing = widget.stories.length > 2;
  late final List<String> _picked = _choosing ? [] : [...widget.stories];
  _Verdict? _verdict;
  Timer? _close;

  /// What the guide arrow can point at: the witnesses to choose from, and
  /// the way on once two were rightly found different.
  final _pickLink = GuideLink();
  final _nextLink = GuideLink();

  static const closeAfter = Duration(milliseconds: 1800);

  @override
  void dispose() {
    _close?.cancel();
    super.dispose();
  }

  void _pick(String id) {
    if (_verdict == _Verdict.match) return;
    playUiTap(context, TapRole.select);
    setState(() {
      _verdict = null;
      if (_picked.contains(id)) {
        _picked.remove(id);
      } else {
        // Two at most: a third choice takes the place of the first.
        if (_picked.length == 2) _picked.removeAt(0);
        _picked.add(id);
      }
    });
  }

  void _say({required bool same}) {
    if (_picked.length != 2 || _verdict == _Verdict.match) return;
    final match = widget.scene.deduction.matches(_picked[0], _picked[1]);
    final audio = ref.read(audioServiceProvider);
    if (same != match) {
      // Not recorded, not failed: the same two to look at again.
      HapticFeedback.lightImpact();
      setState(() => _verdict = _Verdict.lookAgain);
    } else if (match) {
      audio.play(GameSound.pencilNote);
      HapticFeedback.mediumImpact();
      widget.onSolved();
      setState(() => _verdict = _Verdict.match);
      _close = Timer(closeAfter, () {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      audio.play(GameSound.pencilNote);
      HapticFeedback.selectionClick();
      if (!_choosing) widget.onDifferent();
      setState(() => _verdict = _choosing ? _Verdict.otherPair : _Verdict.different);
    }
  }

  /// Every witness was heard and these two differ: back to choosing two
  /// (none chosen for the detective; the stories stay).
  void _anotherPair() {
    playUiTap(context, TapRole.select);
    setState(() {
      _picked.clear();
      _verdict = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final d = scene.deduction;
    final matched = _verdict == _Verdict.match;
    // Found different with no one else to compare: the way on is another
    // witness (the way back, named for what it is for).
    final askAnother = _verdict == _Verdict.different;
    // Every witness heard and these two differ: the way on is another pair.
    final anotherPair = _verdict == _Verdict.otherPair;
    final pair = _picked.length == 2;
    final saying = pair && _verdict != _Verdict.different;
    // The one next thing to point at (never YES or NO, never a witness).
    final guide = switch (null) {
      _ when askAnother => ('ask-another', _nextLink, GuideSide.left),
      _ when anotherPair => ('another-pair', _nextLink, GuideSide.left),
      _ when _choosing && !pair && !matched => ('choose-two', _pickLink, GuideSide.above),
      _ => null,
    };
    // The stories scroll; the question, what saying shows and the buttons
    // stay at the bottom, so the way on and the way back are always in sight.
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    key: const ValueKey('compare-sheet'),
                    padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const PaperSheetTab(),
                        Text('COMPARE STORIES', textAlign: TextAlign.center, style: AppText.eyebrow()),
                        // Choosing whom to compare only when there is a choice
                        // (two stories: they are simply the two).
                        if (_choosing) ...[
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            d.choose,
                            key: const ValueKey('compare-choose'),
                            textAlign: TextAlign.center,
                            textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.1),
                            style: AppText.bodyText(size: 16, weight: FontWeight.w600, color: AppColors.navy),
                          ),
                          // Room for the guide arrow over the witnesses.
                          const SizedBox(height: _TalkPanel._arrowRoom),
                          GuideTarget(
                            link: _pickLink,
                            child: Row(
                              key: const ValueKey('compare-witnesses'),
                              children: [
                                for (final id in widget.stories)
                                  Expanded(
                                    child: _WitnessPick(
                                      speaker: scene.speaker(scene.statement(id).speakerId),
                                      order: _picked.indexOf(id),
                                      onTap: () => _pick(id),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpace.md),
                        // The two stories, side by side (two empty places until
                        // two witnesses are chosen).
                        IntrinsicHeight(
                          child: Row(
                            key: const ValueKey('compare-pair'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < 2; i++) ...[
                                if (i > 0) const SizedBox(width: AppSpace.sm),
                                Expanded(
                                  child: i < _picked.length
                                      ? _StoryCard(
                                          key: ValueKey('story-${_picked[i]}'),
                                          scene: scene,
                                          statement: scene.statement(_picked[i]),
                                          matched: matched,
                                          face: !_choosing,
                                        )
                                      : const _EmptyStory(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpace.sm),
                        if (matched)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpace.lg),
                            child: _Match(line: d.matchLine),
                          ),
                      ],
                    ),
                  ),
                ),
                if (!matched)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // A short heading: it keeps (about) its size with larger
                        // text, so the stories above keep their room.
                        MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.1,
                          child: GlossaryText(
                            d.question,
                            key: const ValueKey('compare-question'),
                            textAlign: TextAlign.center,
                            style: AppText.title(size: 21),
                          ),
                        ),
                        // Room for the line is kept even when empty: the buttons
                        // never move under the finger while saying.
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 56),
                          child: Center(
                            child: switch (_verdict) {
                              null || _Verdict.match => const SizedBox.shrink(),
                              _Verdict.lookAgain => _VerdictLine(d.lookAgainLine, right: false),
                              _Verdict.otherPair => _VerdictLine(
                                d.otherPairLine,
                                right: true,
                                mark: 'DIFFERENT STORIES',
                              ),
                              _Verdict.different => _VerdictLine(
                                d.differentLine,
                                right: true,
                                mark: 'DIFFERENT STORIES',
                              ),
                            },
                          ),
                        ),
                        // Saying: YES / NO. Once two are rightly found different
                        // with another pair to try, the way on stands where NO
                        // was (the bottom buttons never move; the stories gain
                        // the room).
                        if (anotherPair)
                          GuideTarget(
                            link: _nextLink,
                            child: GameButton(
                              key: const ValueKey('choose-another-pair'),
                              label: 'CHOOSE ANOTHER PAIR',
                              glyph: InkGlyph.eye,
                              singleLine: true,
                              onPressed: _anotherPair,
                            ),
                          )
                        else ...[
                          GameButton(
                            key: const ValueKey('say-same'),
                            label: 'YES, THEY MATCH',
                            glyph: InkGlyph.check,
                            singleLine: true,
                            onPressed: saying ? () => _say(same: true) : null,
                          ),
                          const SizedBox(height: AppSpace.sm),
                          GameButton(
                            key: const ValueKey('say-different'),
                            label: 'NO, THEY ARE DIFFERENT',
                            glyph: InkGlyph.close,
                            singleLine: true,
                            onPressed: saying ? () => _say(same: false) : null,
                          ),
                        ],
                        const SizedBox(height: AppSpace.sm),
                        // The way back; when another witness is the next thing,
                        // it says so (one button, not two that do the same).
                        askAnother
                            ? GuideTarget(
                                link: _nextLink,
                                child: GameButton(
                                  key: const ValueKey('ask-another-witness'),
                                  label: 'ASK ANOTHER WITNESS',
                                  glyph: InkGlyph.back,
                                  singleLine: true,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              )
                            : GameButton(
                                key: const ValueKey('back-to-witnesses'),
                                label: 'BACK TO WITNESSES',
                                glyph: InkGlyph.back,
                                singleLine: true,
                                style: GameButtonStyle.outline,
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                      ],
                    ),
                  ),
              ],
            ),
            if (guide != null)
              GuidedActionIndicator(
                key: ValueKey('guide-${guide.$1}'),
                link: guide.$2,
                side: guide.$3,
                // The witnesses to choose from: all of them, none favoured.
                span: guide.$2 == _pickLink,
              ),
          ],
        ),
      ),
    );
  }
}

/// One line saying how the detective's yes or no turned out: right (a
/// green tick) or a gentle look again.
class _VerdictLine extends StatelessWidget {
  const _VerdictLine(this.line, {required this.right, this.mark});

  final String line;
  final bool right;

  /// A small heading over the line (DIFFERENT STORIES).
  final String? mark;

  @override
  Widget build(BuildContext context) {
    final color = right ? AppColors.success : AppColors.tryAgain;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mark != null)
            Text(
              mark!,
              key: const ValueKey('compare-mark'),
              textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.1),
              style: AppText.eyebrow(color: AppColors.goldDeep),
            ),
          Text.rich(
            TextSpan(
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpace.xs),
                    child: InkIcon(right ? InkGlyph.check : InkGlyph.eye, size: AppIconSize.small, color: color),
                  ),
                ),
                TextSpan(text: line),
              ],
            ),
            key: const ValueKey('compare-feedback'),
            textAlign: TextAlign.center,
            style: AppText.bodyText(size: 16, color: color, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// A witness to choose for comparing: their face, their name, and 1 or 2
/// when chosen (tap again to let them go).
class _WitnessPick extends StatelessWidget {
  const _WitnessPick({required this.speaker, required this.order, required this.onTap});

  final DialogueSpeaker speaker;

  /// 0 or 1 when chosen (first, second), else -1.
  final int order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chosen = order >= 0;
    return Semantics(
      button: true,
      selected: chosen,
      label: 'Compare ${speaker.name.toLowerCase()}${chosen ? ', chosen ${order + 1}' : ''}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
        child: Material(
          color: chosen ? AppColors.royalBlueSoft : AppColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.paper),
            side: BorderSide(
              color: chosen ? AppColors.navy : AppLine.faint(0.25),
              width: chosen ? AppLine.ink : AppLine.hairline,
            ),
          ),
          child: InkWell(
            key: ValueKey('pick-${speaker.id}'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.paper),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.sm, horizontal: AppSpace.xs),
              child: Column(
                children: [
                  SizedBox.square(
                    dimension: 40,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipOval(child: _Face(speaker: speaker)),
                        if (chosen)
                          Positioned(
                            right: -6,
                            top: -4,
                            child: Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.navy),
                              child: Text(
                                '${order + 1}',
                                textScaler: TextScaler.noScaling,
                                style: AppText.style(
                                  AppText.body,
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: AppColors.paperLight,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      speaker.name.replaceFirst('The ', ''),
                      maxLines: 1,
                      textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.1),
                      style: AppText.style(
                        AppText.body,
                        size: 13,
                        weight: chosen ? FontWeight.w700 : FontWeight.w500,
                        color: chosen ? AppColors.navy : AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One witness's story, set beside another: their face and name over what
/// they said, word for word. Ringed in green once the two match.
class _StoryCard extends StatelessWidget {
  const _StoryCard({super.key, required this.scene, required this.statement, required this.matched, this.face = true});

  final DialogueScene scene;
  final DialogueStatement statement;
  final bool matched;

  /// Their face over the words (left out when their face was just chosen
  /// above: the stories keep the room).
  final bool face;

  @override
  Widget build(BuildContext context) {
    final who = scene.speaker(statement.speakerId);
    return Semantics(
      label: '${who.name} said: ${statement.text}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.md),
        decoration: BoxDecoration(
          color: matched ? AppColors.successSoft : AppColors.paperLight,
          borderRadius: BorderRadius.circular(AppRadius.paper),
          border: Border.all(
            color: matched ? AppColors.success : AppLine.faint(0.3),
            width: matched ? AppLine.ink : AppLine.hairline,
          ),
          boxShadow: AppShadow.paperLift,
        ),
        child: Column(
          children: [
            if (face) ...[
              SizedBox.square(
                dimension: 44,
                child: ClipOval(child: _Face(speaker: who)),
              ),
              const SizedBox(height: AppSpace.xs),
            ],
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                who.name.replaceFirst('The ', '').toUpperCase(),
                maxLines: 1,
                textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.1),
                style: AppText.eyebrow(color: AppColors.muted),
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              '"${statement.text}"',
              textAlign: TextAlign.center,
              // Two narrow cards side by side: a little smaller with larger
              // text, so both stories read whole together.
              style: AppText.letter(
                size: MediaQuery.textScalerOf(context).scale(1) > 1.1 ? 15 : 17,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The place of a story not chosen yet.
class _EmptyStory extends StatelessWidget {
  const _EmptyStory();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.parchment.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.paper),
        border: Border.all(color: AppColors.parchmentDark, width: AppLine.rule),
      ),
      child: Text('?', style: AppText.title(size: 28, color: AppColors.parchmentDark)),
    );
  }
}

/// The two stories match: THE STORIES MATCH! and what that means.
class _Match extends StatelessWidget {
  const _Match({required this.line});

  final String line;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Column(
        key: const ValueKey('compare-match'),
        children: [
          const InkStamp('THE STORIES MATCH!', color: AppColors.success, tilt: -0.05),
          const SizedBox(height: AppSpace.md),
          GlossaryText(line, textAlign: TextAlign.center, style: AppText.title(size: 20)),
        ],
      ),
    );
  }
}

/// A child fading up into place once, after [delay].
class _FadeUp extends StatefulWidget {
  const _FadeUp({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<_FadeUp> createState() => _FadeUpState();
}

class _FadeUpState extends State<_FadeUp> {
  late bool _shown = widget.delay == Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!_shown) _timer = Timer(widget.delay, () => mounted ? setState(() => _shown = true) : null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: const Duration(milliseconds: 350),
      child: AnimatedSlide(
        offset: _shown ? Offset.zero : const Offset(0, 0.15),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
