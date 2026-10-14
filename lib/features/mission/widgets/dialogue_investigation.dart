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

  DialogueProgress get _p => widget.progress;

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

  Future<void> _compare() async {
    if (_completed) return;
    if (_ready) setState(() => _ready = false);
    ref.read(audioServiceProvider).play(GameSound.paperRustle);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: paperSheetShape,
      showDragHandle: false,
      builder: (context) =>
          _CompareSheet(scene: widget.scene, heard: widget.scene.comparable(_p.heard), onSolved: () => _solved = true),
    );
    // Linked: the answer, once (also when the sheet was closed early).
    if (_solved && !_completed && mounted) {
      _completed = true;
      widget.onComplete(widget.scene.deduction.answer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final canCompare = scene.canCompare(_p.heard);
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
              onTalkTo: _talkTo,
              onAsk: _ask,
              onCompare: _compare,
              onNotes: _notes,
              onTip: _tip,
            ),
          ],
        ),
      ],
    );
  }
}

// ── The middle: arriving, then the person talked to ───────────────────────

/// Arriving: the mission first (what to find out, and how), then the
/// people to ask. The lines come in once (about a second); coming back
/// shows them at once.
/// Where there is room under them, the three people stand in a row, each
/// one a print to tap and talk to (the same choice as the panel's faces):
/// the lines lead into the people, not into empty space.
class _Arrival extends StatelessWidget {
  const _Arrival({super.key, required this.scene, required this.instant, required this.onTalkTo});

  final DialogueScene scene;
  final bool instant;
  final ValueChanged<String> onTalkTo;

  /// The row of people shows from this much height, and leaves the lines
  /// about [_linesRoom].
  static const _lineupFrom = 360.0;
  static const _linesRoom = 230.0;

  @override
  Widget build(BuildContext context) {
    final still = instant || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    return InkSurface(
      night: true,
      child: LayoutBuilder(
        builder: (context, box) {
          final lineup = box.maxHeight >= _lineupFrom ? (box.maxHeight - _linesRoom).clamp(120.0, 280.0) : 0.0;
          return Column(
            children: [
              Expanded(child: _lines(still, arrow: lineup == 0)),
              if (lineup > 0)
                _FadeUp(
                  delay: still ? Duration.zero : const Duration(milliseconds: 1300),
                  child: SizedBox(
                    key: const ValueKey('talk-lineup'),
                    height: lineup,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.md),
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
            ],
          );
        },
      ),
    );
  }

  Widget _lines(bool still, {required bool arrow}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.lg, AppSpace.screen, AppSpace.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FadeUp(
              delay: still ? Duration.zero : const Duration(milliseconds: 150),
              child: Text('YOUR MISSION', textAlign: TextAlign.center, style: AppText.eyebrow(color: AppColors.goldLight)),
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
              delay: still ? Duration.zero : const Duration(milliseconds: 750),
              child: GlossaryText(
                scene.how,
                textAlign: TextAlign.center,
                linkColor: AppColors.goldLight,
                style: AppText.bodyText(size: 17, color: AppColors.paperLight.withValues(alpha: 0.85)),
              ),
            ),
            if (arrow) ...[
              const SizedBox(height: AppSpace.sm),
              _FadeUp(
                delay: still ? Duration.zero : const Duration(milliseconds: 1050),
                child: const InkIcon(InkGlyph.down, size: AppIconSize.medium, color: AppColors.goldLight),
              ),
            ],
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
                          // question asked is the navy one in the list below.
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
                                    child: Text('NEW STATEMENT', maxLines: 1, style: AppText.eyebrow(color: AppColors.burgundy)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpace.xs),
                          ],
                          GlossaryText('"$line"', style: AppText.letter(size: 18, color: AppColors.ink)),
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
    required this.onTalkTo,
    required this.onAsk,
    required this.onCompare,
    required this.onNotes,
    required this.onTip,
  });

  final DialogueScene scene;
  final DialogueProgress progress;
  final bool canCompare;

  /// Enough statements were just heard: COMPARE is shown with a little gold
  /// once, and a line says why.
  final bool ready;
  final String? tipLabel;
  final ValueChanged<String> onTalkTo;
  final ValueChanged<String> onAsk;
  final VoidCallback onCompare;
  final VoidCallback onNotes;
  final VoidCallback onTip;

  @override
  Widget build(BuildContext context) {
    final speaker = progress.speakerId;
    final heard = progress.heard.length;
    final d = scene.deduction;
    // What to do next, as far as the detective has got (never who to ask).
    final next = canCompare ? d.readyLine : (scene.witnessesHeard(progress.heard) == 0 ? d.askLine : d.askMoreLine);
    return ConstrainedBox(
      // Never more than most of the screen: the person stays in sight.
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.58),
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
                  // Who to talk to.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final s in scene.speakers)
                        Expanded(
                          child: _SpeakerChoice(
                            speaker: s,
                            chosen: s.id == speaker,
                            asked: scene.questions.where((q) => progress.hasAsked(s.id, q.id)).length,
                            of: scene.questions.length,
                            onTap: () => onTalkTo(s.id),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  // What to ask (once someone is chosen).
                  if (speaker == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                      child: Text(
                        scene.guide,
                        key: const ValueKey('talk-guide'),
                        textAlign: TextAlign.center,
                        style: AppText.bodyText(size: 17, weight: FontWeight.w600, color: AppColors.navy),
                      ),
                    )
                  else
                    for (final q in scene.questions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.xs),
                        child: _QuestionChoice(
                          key: ValueKey('question-${q.id}'),
                          question: q,
                          // The mission's question: a magnifier and a gold edge
                          // until it is asked of this witness (the others stay
                          // free to ask).
                          lead: q.id == d.topic,
                          asked: progress.hasAsked(speaker, q.id),
                          current: progress.questionId == q.id,
                          onTap: () => onAsk(q.id),
                        ),
                      ),
                  const SizedBox(height: AppSpace.xs),
                  // Comparing: the button once there is enough to compare;
                  // until then, one line saying how much is still to hear.
                  if (canCompare) _CompareButton(ready: ready, onPressed: onCompare),
                  if (speaker != null || canCompare)
                    Padding(
                      padding: EdgeInsets.only(top: canCompare ? AppSpace.xs : 0),
                      child: Text(
                        next,
                        key: ValueKey(canCompare ? 'talk-next-ready' : 'talk-next'),
                        textAlign: TextAlign.center,
                        style: AppText.bodyText(
                          size: 15,
                          weight: FontWeight.w600,
                          color: canCompare ? AppColors.goldDeep : AppColors.inkBrown,
                        ),
                      ),
                    ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpace.sm,
                    children: [
                      InkTextButton(
                        key: const ValueKey('open-statements'),
                        label: 'Statements ($heard)',
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

/// COMPARE STATEMENTS. When it has just become possible ([ready]), it comes
/// in once with a gold edge and a soft glow that settles (still with motion
/// reduced: the gold edge only); the edge stays until it is used.
class _CompareButton extends StatelessWidget {
  const _CompareButton({required this.ready, required this.onPressed});

  final bool ready;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final button = GameButton(
      key: const ValueKey('compare-statements'),
      label: 'COMPARE CLUES',
      glyph: InkGlyph.eye,
      singleLine: true,
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
/// a gold ring when they are the one talked to, and how many questions
/// they were asked.
class _SpeakerChoice extends StatelessWidget {
  const _SpeakerChoice({
    required this.speaker,
    required this.chosen,
    required this.asked,
    required this.of,
    required this.onTap,
  });

  final DialogueSpeaker speaker;
  final bool chosen;
  final int asked;
  final int of;
  final VoidCallback onTap;

  static const size = 44.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: chosen,
      label: 'Talk to ${speaker.name.toLowerCase()}${asked > 0 ? ', $asked of $of questions asked' : ''}',
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('speaker-${speaker.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
          child: Column(
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
/// asked (it can be asked again to hear the answer again).
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

  /// The mission's question: marked (a magnifier, a gold edge) until asked.
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
        color: current ? AppColors.navy : AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          side: BorderSide(
            color: current ? AppColors.navyDeep : (lead && !asked ? AppColors.gold : AppLine.faint(0.25)),
            width: lead && !asked && !current ? AppLine.rule : AppLine.hairline,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.paper),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
              child: Row(
                children: [
                  InkIcon(
                    asked ? InkGlyph.check : (lead ? InkGlyph.search : InkGlyph.arrow),
                    size: AppIconSize.small,
                    color: current ? AppColors.goldLight : (asked ? AppColors.success : AppColors.navy),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Text(
                      question.text,
                      style: AppText.bodyText(
                        size: 17,
                        weight: FontWeight.w600,
                        color: current ? AppColors.paperLight : AppColors.navy,
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

/// Comparing: the statements heard, two of them chosen and linked side by
/// side, and what that link shows. The right pair is the answer: shown
/// as a MATCH with its conclusion, then the sheet closes by itself.
class _CompareSheet extends ConsumerStatefulWidget {
  const _CompareSheet({required this.scene, required this.heard, required this.onSolved});

  final DialogueScene scene;
  final List<String> heard;
  final VoidCallback onSolved;

  @override
  ConsumerState<_CompareSheet> createState() => _CompareSheetState();
}

class _CompareSheetState extends ConsumerState<_CompareSheet> {
  final List<String> _picked = [];
  String? _line;
  bool _solved = false;
  Timer? _close;

  static const closeAfter = Duration(milliseconds: 1600);

  @override
  void dispose() {
    _close?.cancel();
    super.dispose();
  }

  void _pick(String id) {
    if (_solved) return;
    playUiTap(context, TapRole.select);
    setState(() {
      _line = null;
      if (_picked.contains(id)) {
        _picked.remove(id);
      } else {
        // Two at most: a third choice takes the place of the first.
        if (_picked.length == 2) _picked.removeAt(0);
        _picked.add(id);
      }
    });
  }

  /// Whether any two of the statements on the page match (when none do,
  /// a wrong link also says there is someone else to ask).
  bool get _anyMatch {
    final ids = widget.heard;
    for (var i = 0; i < ids.length; i++) {
      for (var j = i + 1; j < ids.length; j++) {
        if (widget.scene.deduction.judge(ids[i], ids[j]) == null) return true;
      }
    }
    return false;
  }

  void _link() {
    if (_solved || _picked.length != 2) return;
    final d = widget.scene.deduction;
    final verdict = d.judge(_picked[0], _picked[1]);
    final audio = ref.read(audioServiceProvider);
    if (verdict == null) {
      audio.play(GameSound.pencilNote);
      HapticFeedback.mediumImpact();
      widget.onSolved();
      setState(() => _solved = true);
      _close = Timer(closeAfter, () {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      setState(() => _line = _anyMatch ? verdict : '$verdict ${d.missingLine}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final d = scene.deduction;
    // The statements and what linking shows scroll; the two buttons stay at
    // the bottom, so the way back is always in sight.
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        child: Column(
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
                    Text('COMPARE CLUES', textAlign: TextAlign.center, style: AppText.eyebrow()),
                    const SizedBox(height: AppSpace.xs),
                    GlossaryText(d.question, textAlign: TextAlign.center, style: AppText.title(size: 21)),
                    const SizedBox(height: AppSpace.xs),
                    Text(d.prompt, textAlign: TextAlign.center, style: AppText.caption()),
                    const SizedBox(height: AppSpace.md),
                    for (final id in widget.heard)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.sm),
                        child: _PickCard(
                          key: ValueKey('pick-$id'),
                          scene: scene,
                          statement: scene.statement(id),
                          order: _picked.indexOf(id),
                          matched: _solved && _picked.contains(id),
                          onTap: () => _pick(id),
                        ),
                      ),
                    if (_solved)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.md),
                        child: _Match(conclusion: d.conclusion),
                      )
                    else
                      // Room for the line is kept even when empty: the sheet
                      // never grows or shrinks under the finger while choosing.
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 56),
                        child: Center(
                          child: _line == null
                              ? const SizedBox.shrink()
                              : Text(
                                  _line!,
                                  key: const ValueKey('compare-feedback'),
                                  textAlign: TextAlign.center,
                                  style: AppText.bodyText(size: 16, color: AppColors.tryAgain, weight: FontWeight.w600),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (!_solved)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GameButton(
                      key: const ValueKey('link-statements'),
                      label: 'LINK THESE TWO',
                      glyph: InkGlyph.check,
                      onPressed: _picked.length == 2 ? _link : null,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    GameButton(
                      key: const ValueKey('back-to-witnesses'),
                      label: 'BACK TO WITNESSES',
                      glyph: InkGlyph.back,
                      style: GameButtonStyle.outline,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A statement to choose for the link: chosen ones are inked in navy and
/// numbered 1 and 2; once they match, both are ringed in green.
class _PickCard extends StatelessWidget {
  const _PickCard({
    super.key,
    required this.scene,
    required this.statement,
    required this.order,
    required this.matched,
    required this.onTap,
  });

  final DialogueScene scene;
  final DialogueStatement statement;

  /// 0 or 1 when chosen (first, second), else -1.
  final int order;
  final bool matched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chosen = order >= 0;
    final who = scene.speaker(statement.speakerId);
    final edge = matched ? AppColors.success : (chosen ? AppColors.navy : AppLine.faint(0.25));
    return Semantics(
      button: true,
      selected: chosen,
      label: '${who.name} said: ${statement.text}${chosen ? ', chosen ${order + 1}' : ''}',
      excludeSemantics: true,
      child: Material(
        color: matched ? AppColors.successSoft : (chosen ? AppColors.royalBlueSoft : AppColors.paper),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          side: BorderSide(color: edge, width: chosen || matched ? AppLine.ink : AppLine.hairline),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.paper),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Row(
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
                      Text('"${statement.text}"', style: AppText.letter(size: 17, color: AppColors.ink)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: chosen ? (matched ? AppColors.success : AppColors.navy) : Colors.transparent,
                    border: Border.all(color: chosen ? Colors.transparent : AppLine.faint(0.35), width: AppLine.rule),
                  ),
                  child: chosen
                      ? Text(
                          '${order + 1}',
                          style: AppText.style(
                            AppText.body,
                            size: 14,
                            weight: FontWeight.w700,
                            color: AppColors.paperLight,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The two statements match: what they show.
class _Match extends StatelessWidget {
  const _Match({required this.conclusion});

  final String conclusion;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: PaperSheet(
        key: const ValueKey('compare-match'),
        ruled: true,
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          children: [
            const InkStamp('MATCH', color: AppColors.success),
            const SizedBox(height: AppSpace.md),
            GlossaryText(conclusion, textAlign: TextAlign.center, style: AppText.title(size: 22)),
          ],
        ),
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
