import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
import '../../../widgets/typewriter_text.dart';
import '../../game/game_providers.dart';

/// A mission played by talking to the people at its place (see
/// [DialogueScene]): the room behind them, the person talked to and what
/// they say in the middle, and under it who to talk to, what to ask, and
/// the statements to compare.
///
/// What was asked and heard lives in [progress], kept by the page that
/// shows the talk (going back to the place and in again keeps it); it is
/// not saved: after a restart the talk begins again. Once two statements
/// that answer the deduction are matched, and what is still to be found
/// after it is heard, [onComplete] is called once with the scene's answer
/// (the mission's puzzle answer).
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
  bool _completed = false;

  /// Everything is found (the deduction made, and what was still to find):
  /// DESCRIPTION RECORDED, and the detective goes on with CONTINUE.
  bool _finishing = false;

  /// The statements needed to compare were just heard (on this page): the
  /// COMPARE button is shown once with a little gold, until it is used.
  bool _ready = false;

  /// Choosing from the prints arriving: the chosen portrait flies to its
  /// place in the talk ([_flight], from where it was), the rest fade away.
  final _stackKey = GlobalKey();
  late final Map<String, GlobalKey> _printKeys = {for (final s in widget.scene.speakers) s.id: GlobalKey()};
  final _flying = ValueNotifier<String?>(null);
  Rect? _flight;

  DialogueProgress get _p => widget.progress;

  @override
  void dispose() {
    _flying.dispose();
    super.dispose();
  }

  /// Where [box] is on this page.
  Rect? _onPage(RenderObject? box) {
    final page = _stackKey.currentContext?.findRenderObject();
    if (box is! RenderBox || page is! RenderBox || !box.attached || !box.hasSize) return null;
    return MatrixUtils.transformRect(box.getTransformTo(page), Offset.zero & box.size);
  }

  /// The talk's portrait, where it is laid out (null: not yet).
  Rect? _portraitPlace() {
    RenderObject? found;
    void visit(Element e) {
      if (e.widget.key == const ValueKey('talk-portrait')) found = e.findRenderObject();
      e.visitChildren(visit);
    }

    _stackKey.currentContext?.visitChildElements(visit);
    return _onPage(found);
  }

  /// A print chosen arriving: the talk begins, the portrait flying in (at
  /// once with motion reduced). One at a time: taps meanwhile wait.
  void _talkFromPrint(String id) {
    if (_flying.value != null || _p.speakerId != null) return;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final from = still ? null : _onPage(_printKeys[id]!.currentContext?.findRenderObject());
    if (from != null) {
      _flying.value = id;
      _flight = from;
    }
    _talkTo(id);
  }

  void _landed() {
    if (!mounted) return;
    _flying.value = null;
    setState(() => _flight = null);
  }

  void _talkTo(String id) {
    if (_completed || _finishing) return;
    // A portrait in the air: it lands first.
    if (_flying.value != null && _p.speakerId != null) return;
    if (_p.speakerId == id && _p.questionId == null) return;
    playUiTap(context, TapRole.select);
    setState(() {
      _p.introSeen = true;
      _p.talkTo(id);
    });
    widget.onChanged();
  }

  void _ask(String questionId) {
    if (_completed || _finishing || _p.speakerId == null) return;
    // Comparing opens once two witnesses have said something (about
    // anything: sorting out what matches is the detective's).
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
    // The deduction made, the last thing found: recorded; on with CONTINUE.
    if (_p.solved && widget.scene.described(_p.heard)) _wrapUp();
  }

  void _wrapUp() {
    if (_finishing || _completed) return;
    setState(() => _finishing = true);
  }

  /// The mission's answer, once (CONTINUE, however often it is tapped).
  void _complete() {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onComplete(widget.scene.deduction.answer);
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

  /// A hint opened is written in the panel, under the questions (the talk
  /// stays as it is).
  Future<void> _tip() => widget.onHint();

  /// The words of what is on the screen now, each with its meaning on a tap
  /// (the same word cards as anywhere; here they are listed, not dotted, so
  /// no word in the talk looks like a clue).
  Future<void> _words() {
    final scene = widget.scene;
    final speaker = _p.speakerId == null ? null : scene.speaker(_p.speakerId!);
    final line = speaker == null
        ? null
        : (_p.questionId == null ? speaker.greeting : speaker.answers[_p.questionId]!.line);
    final text = [
      _p.solved ? scene.deduction.thenGoal : scene.goal,
      if (speaker == null) scene.how,
      ?line,
      if (speaker != null)
        for (final q in scene.questions) q.text,
    ].join(' ');
    return showTalkWords(context, ref, text);
  }

  Future<void> _compare() async {
    if (_completed || _finishing || _p.solved) return;
    setState(() => _ready = false);
    ref.read(audioServiceProvider).play(GameSound.paperRustle);
    var solved = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: paperSheetShape,
      showDragHandle: false,
      builder: (context) => _CompareSheet(scene: widget.scene, heard: [..._p.heard], onSolved: () => solved = true),
    );
    if (!mounted || !solved) return;
    // Matched (also when the sheet was closed early): recorded if nothing is
    // left to find (on with CONTINUE); else what is left is the next thing.
    setState(() => _p.solved = true);
    widget.onChanged();
    if (widget.scene.described(_p.heard)) _wrapUp();
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Stack(
      key: _stackKey,
      fit: StackFit.expand,
      children: [
        PlaceScenery.file(scene.background),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AnimatedSwitcher(
                // Arriving → talking: as long as the portrait's flight, the
                // rest fading out and the talk in; between witnesses, quicker.
                duration: still ? Duration.zero : Duration(milliseconds: _flight != null ? 350 : 220),
                child: _p.speakerId == null
                    ? _Arrival(
                        key: const ValueKey('talk-intro'),
                        scene: scene,
                        instant: _p.introSeen,
                        printKeys: _printKeys,
                        flying: _flying,
                        onTalkTo: _talkFromPrint,
                      )
                    : _Conversation(
                        key: ValueKey('talk-${_p.speakerId}'),
                        scene: scene,
                        goal: _p.solved ? scene.deduction.thenGoal : scene.goal,
                        speaker: scene.speaker(_p.speakerId!),
                        question: _p.questionId == null
                            ? null
                            : scene.questions.firstWhere((q) => q.id == _p.questionId),
                        fresh: _p.fresh,
                        recorded: _p.questionId != null &&
                            _p.heard.contains(scene.speaker(_p.speakerId!).answers[_p.questionId]!.statementId),
                        flying: _flying,
                      ),
              ),
            ),
            _TalkPanel(
              scene: scene,
              progress: _p,
              ready: _ready,
              finishing: _finishing,
              flying: _flying,
              onContinue: _complete,
              tipLabel: nextTipLabel(widget.hints, widget.hintsShown),
              hints: widget.hints,
              hintsShown: widget.hintsShown,
              onTalkTo: _talkTo,
              onAsk: _ask,
              onCompare: _compare,
              onNotes: _notes,
              onWords: _words,
              onTip: _tip,
            ),
          ],
        ),
        if (_flight != null && _p.speakerId != null)
          _PortraitFlight(
            key: ValueKey('flight-${_p.speakerId}'),
            speaker: scene.speaker(_p.speakerId!),
            from: _flight!,
            to: _portraitPlace,
            onDone: _landed,
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
/// at once. The three TALK tags glow softly together, the same for each,
/// until a witness is chosen (still with motion reduced: a steady gold).
class _Arrival extends StatefulWidget {
  const _Arrival({
    super.key,
    required this.scene,
    required this.instant,
    required this.printKeys,
    required this.flying,
    required this.onTalkTo,
  });

  final DialogueScene scene;
  final bool instant;

  /// Each print's picture, by speaker id: where a chosen portrait flies from.
  final Map<String, GlobalKey> printKeys;

  /// The witness whose portrait is flying to the talk (their print here is
  /// left out meanwhile, so it is never seen twice).
  final ValueListenable<String?> flying;
  final ValueChanged<String> onTalkTo;

  /// The lines keep about this much height; the row of people takes the
  /// rest, within [_lineupLeast]..[_lineupMost].
  static const _linesRoom = 210.0;
  static const _lineupLeast = 130.0;
  static const _lineupMost = 290.0;

  @override
  State<_Arrival> createState() => _ArrivalState();
}

class _ArrivalState extends State<_Arrival> with SingleTickerProviderStateMixin {
  /// The TALK tags' glow, one for all three: up and down, about 2 s a round.
  late final AnimationController _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _glow
        ..stop()
        ..value = 1;
    } else if (!_glow.isAnimating) {
      _glow.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final still = widget.instant || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    return InkSurface(
      night: true,
      child: LayoutBuilder(
        builder: (context, box) {
          // Never taller than the prints themselves (they fill their width),
          // their names and TALK: the row is the people, no empty band over
          // them.
          final printWidth = (box.maxWidth - 2 * AppSpace.md - 6 * AppSpace.xs) / scene.speakers.length;
          final nameRoom = AppSpace.sm + MediaQuery.textScalerOf(context).scale(14) * 1.5 + AppSpace.xs + _TalkTag.height;
          final natural = printWidth / ArtAssets.witnessPortraitAspect + nameRoom + AppSpace.md;
          final lineup = math.min(
            (box.maxHeight - _Arrival._linesRoom).clamp(_Arrival._lineupLeast, _Arrival._lineupMost),
            natural,
          );
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
                    child: Row(
                      children: [
                        for (final s in scene.speakers)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                              child: _LineupPrint(
                                speaker: s,
                                pictureKey: widget.printKeys[s.id]!,
                                flying: widget.flying,
                                glow: _glow,
                                onTap: () => widget.onTalkTo(s.id),
                              ),
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

  Widget _lines(bool still) {
    final scene = widget.scene;
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
              // Plain words (no dotted ones that look like clues): their
              // meanings are under WORDS.
              child: Text(
                scene.goal,
                key: const ValueKey('talk-goal'),
                textAlign: TextAlign.center,
                style: AppText.title(size: 23, color: AppColors.paperLight),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            _FadeUp(
              delay: still ? Duration.zero : const Duration(milliseconds: 650),
              child: Text(
                scene.how,
                textAlign: TextAlign.center,
                style: AppText.bodyText(size: 17, color: AppColors.paperLight.withValues(alpha: 0.85)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One of the people in the arrival's row: their print, their name and
/// TALK under it (what a tap does, the same for each); a tap talks to them.
class _LineupPrint extends StatelessWidget {
  const _LineupPrint({
    required this.speaker,
    required this.pictureKey,
    required this.flying,
    required this.glow,
    required this.onTap,
  });

  final DialogueSpeaker speaker;
  final GlobalKey pictureKey;
  final ValueListenable<String?> flying;
  final Animation<double> glow;
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
              child: ValueListenableBuilder<String?>(
                valueListenable: flying,
                // Flying to the talk: the print is the one in the air.
                builder: (context, id, child) => Opacity(opacity: id == speaker.id ? 0 : 1, child: child),
                child: AspectRatio(
                  key: pictureKey,
                  aspectRatio: ArtAssets.witnessPortraitAspect,
                  child: _PrintedPortrait(speaker: speaker),
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
            const SizedBox(height: AppSpace.xs),
            _TalkTag(glow: glow),
          ],
        ),
      ),
    );
  }
}

/// TALK, under each person arriving: what tapping them does. Its gold edge
/// and letters brighten and soften with [glow] (never its size or place).
class _TalkTag extends StatelessWidget {
  const _TalkTag({required this.glow});

  final Animation<double> glow;

  static const height = 28.0;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.1);
    return AnimatedBuilder(
      animation: glow,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(glow.value);
        return Container(
          key: const ValueKey('talk-tag'),
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            color: AppColors.goldLight.withValues(alpha: 0.06 + 0.08 * t),
            border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.5 + 0.5 * t), width: AppLine.rule),
            boxShadow: [BoxShadow(color: AppColors.goldLight.withValues(alpha: 0.28 * t), blurRadius: 8)],
          ),
          child: Text(
            'TALK',
            textScaler: scaler,
            style: AppText.eyebrow(color: AppColors.goldLight.withValues(alpha: 0.7 + 0.3 * t)),
          ),
        );
      },
    );
  }
}

/// A witness's picture on its sheet of parchment (in the row arriving, in
/// the talk, and flying between them — the same everywhere).
class _PrintedPortrait extends StatelessWidget {
  const _PrintedPortrait({required this.speaker, super.key});

  final DialogueSpeaker speaker;

  @override
  Widget build(BuildContext context) {
    return PaperSheet(
      padding: const EdgeInsets.all(AppSpace.xs),
      child: Image.asset(
        speaker.portrait,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stack) => const SizedBox.expand(),
      ),
    );
  }
}

/// A chosen witness's portrait flying from their print arriving to its place
/// in the talk ([to], found once the talk is laid out), growing as it goes;
/// [onDone] when it lands (at once when there is nowhere to land).
class _PortraitFlight extends StatefulWidget {
  const _PortraitFlight({super.key, required this.speaker, required this.from, required this.to, required this.onDone});

  final DialogueSpeaker speaker;
  final Rect from;
  final Rect? Function() to;
  final VoidCallback onDone;

  static const duration = Duration(milliseconds: 400);

  @override
  State<_PortraitFlight> createState() => _PortraitFlightState();
}

class _PortraitFlightState extends State<_PortraitFlight> with SingleTickerProviderStateMixin {
  late final AnimationController _move = AnimationController(vsync: this, duration: _PortraitFlight.duration);
  Rect? _to;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _to = widget.to();
      if (_to == null) {
        widget.onDone();
        return;
      }
      setState(() {});
      _move.forward().whenComplete(() {
        if (mounted) widget.onDone();
      });
    });
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _move,
      builder: (context, child) {
        final rect = Rect.lerp(widget.from, _to ?? widget.from, Curves.easeInOutCubic.transform(_move.value))!;
        return Positioned.fromRect(rect: rect, child: child!);
      },
      child: IgnorePointer(
        child: _PrintedPortrait(key: const ValueKey('portrait-flight'), speaker: widget.speaker),
      ),
    );
  }
}

/// The person talked to: their portrait (a print on parchment), their name
/// plate, and what they just said, under what they were asked. A statement
/// that is written down is marked so — STATEMENT RECORDED the first time,
/// IN YOUR NOTES after — the same for every statement, whatever it says.
///
/// A tall space stacks the portrait over the words; otherwise they stand
/// side by side, the portrait as tall as the space allows (never more than
/// half the width, so the words keep a readable column) and the words'
/// card pointing to it: the person and what they say are one scene.
class _Conversation extends StatelessWidget {
  const _Conversation({
    super.key,
    required this.scene,
    required this.goal,
    required this.speaker,
    required this.question,
    required this.fresh,
    required this.recorded,
    required this.flying,
  });

  final DialogueScene scene;

  /// The witness whose portrait is flying in (theirs here waits unseen).
  final ValueListenable<String?> flying;

  /// What the detective is finding out now (the mission, or what is left).
  final String goal;
  final DialogueSpeaker speaker;
  final DialogueQuestion? question;
  final String? fresh;

  /// The answer shown is a statement in the notes.
  final bool recorded;

  /// From this height the portrait stands over the words, leaving them about
  /// [_wordsRoom]; below it, beside them.
  static const _stackFrom = 470.0;
  static const _wordsRoom = 190.0;

  @override
  Widget build(BuildContext context) {
    final answer = question == null ? null : speaker.answers[question!.id];
    // The words come once the portrait flying in has landed.
    Widget words({required bool beside}) => _AfterLanding(
      flying: flying,
      id: speaker.id,
      delay: const Duration(milliseconds: 150),
      child: _Speech(
        speaker: speaker,
        question: question,
        line: answer?.line ?? speaker.greeting,
        note: !recorded
            ? null
            : (fresh != null && answer?.statementId == fresh ? _Note.recorded : _Note.kept),
        beside: beside,
      ),
    );
    // The mission, one quiet line over the talk: what the questions are for.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MissionStrip(goal: goal),
        Expanded(child: _scene(words)),
      ],
    );
  }

  Widget _scene(Widget Function({required bool beside}) words) {
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
                  child: _Portrait(speaker: speaker, flying: flying),
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
                child: _Portrait(speaker: speaker, flying: flying),
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
  const _Portrait({required this.speaker, required this.flying});

  final DialogueSpeaker speaker;
  final ValueListenable<String?> flying;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: '${speaker.name}: ${speaker.description}',
      child: Center(
        child: AspectRatio(
          aspectRatio: ArtAssets.witnessPortraitAspect,
          // While it flies in from the print, the one in the air is seen.
          child: ValueListenableBuilder<String?>(
            valueListenable: flying,
            builder: (context, id, child) => Opacity(opacity: id == speaker.id ? 0 : 1, child: child),
            child: _PrintedPortrait(key: const ValueKey('talk-portrait'), speaker: speaker),
          ),
        ),
      ),
    );
  }
}

/// What was asked (small, the detective's) and the answer (the person's,
/// larger, in their paper card), with their name plate.
class _Speech extends StatefulWidget {
  const _Speech({
    required this.speaker,
    required this.question,
    required this.line,
    required this.note,
    this.beside = false,
  });

  final DialogueSpeaker speaker;
  final DialogueQuestion? question;
  final String line;

  /// How the answer is in the notes (null: it is not a statement).
  final _Note? note;

  /// Beside the portrait: the words sit level with the person, and their
  /// card points to them.
  final bool beside;

  @override
  State<_Speech> createState() => _SpeechState();
}

class _SpeechState extends State<_Speech> {
  bool _skipTyping = false;

  @override
  void didUpdateWidget(covariant _Speech oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line != widget.line ||
        oldWidget.question?.id != widget.question?.id ||
        oldWidget.speaker.id != widget.speaker.id) {
      _skipTyping = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final speaker = widget.speaker;
    final question = widget.question;
    final line = widget.line;
    final note = widget.note;
    final beside = widget.beside;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final isNew = note == _Note.recorded;
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
                          // STATEMENT RECORDED over the answer (always in sight),
                          // alike for every statement; the question asked is the
                          // one marked in the list below.
                          if (note != null) ...[
                            Row(
                              key: ValueKey(isNew ? 'new-statement' : 'kept-statement'),
                              children: [
                                const InkIcon(InkGlyph.pen, size: AppIconSize.tiny, color: AppColors.burgundy),
                                const SizedBox(width: AppSpace.xs),
                                // One line, set smaller in a narrow card.
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      isNew ? 'STATEMENT RECORDED' : 'IN YOUR NOTES',
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
                          // Reuse the case Story Sequence's typewriter reveal.
                          // Tapping the spoken line reveals it immediately; witness
                          // selection, questions and evidence comparison remain unchanged.
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (!_skipTyping) setState(() => _skipTyping = true);
                            },
                            child: TypewriterText(
                              '"$line"',
                              key: ValueKey('talk-typewriter-${speaker.id}-${question?.id ?? 'greeting'}'),
                              style: AppText.letter(
                                size: beside && MediaQuery.textScalerOf(context).scale(1) > 1.1 ? 16 : 18,
                                color: AppColors.ink,
                              ),
                              textAlign: TextAlign.start,
                              skip: _skipTyping,
                              sound: false,
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

/// How an answer is in the notes: written down just now, or already.
enum _Note { recorded, kept }

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
    required this.ready,
    required this.finishing,
    required this.flying,
    required this.onContinue,
    required this.tipLabel,
    required this.hints,
    required this.hintsShown,
    required this.onTalkTo,
    required this.onAsk,
    required this.onCompare,
    required this.onNotes,
    required this.onWords,
    required this.onTip,
  });

  final DialogueScene scene;
  final DialogueProgress progress;

  /// Enough statements were just heard: COMPARE is shown with a little gold
  /// once.
  final bool ready;

  /// Everything is found: DESCRIPTION RECORDED, VIEW WITNESS NOTES and
  /// CONTINUE (the mission ends on CONTINUE).
  final bool finishing;

  /// The witness whose portrait is flying in: the questions come after.
  final ValueListenable<String?> flying;
  final VoidCallback onContinue;
  final String? tipLabel;

  /// The hints opened so far: written under the questions, above the links.
  final List<String> hints;
  final int hintsShown;
  final ValueChanged<String> onTalkTo;
  final ValueChanged<String> onAsk;
  final VoidCallback onCompare;
  final VoidCallback onNotes;
  final VoidCallback onWords;
  final VoidCallback onTip;

  @override
  Widget build(BuildContext context) {
    final speaker = progress.speakerId;
    final d = scene.deduction;
    final heard = progress.heard.length;
    final canCompare = !progress.solved && scene.canCompare(progress.heard);
    final count = '$heard ${heard == 1 ? 'STATEMENT' : 'STATEMENTS'}';
    // Where the detective has got and the one next thing to do, in words
    // (never whom to ask, never which statement).
    final (String? mark, String line) = switch (null) {
      _ when finishing => ('DESCRIPTION RECORDED', d.doneLine),
      _ when progress.solved => ('ONE MORE THING', d.thenHow),
      _ when speaker == null => (null, scene.guide),
      _ when canCompare => (count, d.readyLine),
      _ when heard > 0 => (count, d.anotherLine),
      _ => (null, d.askLine),
    };
    final first = [for (final q in scene.questions.take(2)) q];
    final rest = [for (final q in scene.questions.skip(2)) q];
    Widget question(DialogueQuestion q) => _QuestionChoice(
          key: ValueKey('question-${q.id}'),
          question: q,
          asked: progress.hasAsked(speaker!, q.id),
          current: progress.questionId == q.id,
          onTap: () => onAsk(q.id),
        );
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
              // The talk beginning: its questions come up softly from below.
              child: AnimatedSwitcher(
                duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
                    ? Duration.zero
                    : const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                // What is going away takes no touch (a tap mid-change is
                // never a tip or a word).
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [for (final w in previous) IgnorePointer(child: w), ?current],
                ),
                child: _AfterLanding(
                  key: ValueKey(speaker == null ? 'panel-arriving' : 'panel-talking'),
                  flying: flying,
                  id: speaker,
                  delay: const Duration(milliseconds: 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Status(mark: mark, line: line, guide: speaker == null, extra: finishing ? d.notesLine : null),
                      // All found: the notes to look at, and on.
                      if (finishing) ...[
                        const SizedBox(height: AppSpace.sm),
                        GameButton(
                          key: const ValueKey('view-witness-notes'),
                          label: 'VIEW WITNESS NOTES',
                          glyph: InkGlyph.notebook,
                          singleLine: true,
                          style: GameButtonStyle.outline,
                          onPressed: onNotes,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        GameButton(
                          key: const ValueKey('continue-investigation'),
                          label: 'CONTINUE',
                          arrow: true,
                          singleLine: true,
                          onPressed: onContinue,
                        ),
                        const SizedBox(height: AppSpace.sm),
                      ],
                      // Comparing, the one strong button once there is enough
                      // to compare.
                      if (canCompare) ...[
                        _CompareButton(ready: ready, onPressed: onCompare),
                        const SizedBox(height: AppSpace.sm),
                      ],
                      // Arriving, the people are chosen from their prints above;
                      // talking, from their faces here (done: no more asking).
                      if (speaker != null && !finishing) ...[
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
                                  spoken: scene.questions.any((q) => progress.hasAsked(s.id, q.id)),
                                  onTap: () => onTalkTo(s.id),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.sm),
                        // The questions, all alike: two side by side, then the rest.
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final q in first) ...[
                                if (q != first.first) const SizedBox(width: AppSpace.sm),
                                Expanded(child: question(q)),
                              ],
                            ],
                          ),
                        ),
                        for (final q in rest) ...[
                          const SizedBox(height: AppSpace.sm),
                          question(q),
                        ],
                        const SizedBox(height: AppSpace.xs),
                      ],
                      // The hints opened, on the panel (never over the talk);
                      // always there, so a hint opened now unfolds in.
                      if (!finishing) ...[
                        if (hintsShown > 0) const SizedBox(height: AppSpace.xs),
                        DetectiveTipNotes(
                          key: const ValueKey('talk-hints'),
                          hints: hints,
                          revealed: hintsShown,
                          compact: true,
                        ),
                      ],
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSpace.xs,
                        children: [
                          // All found: VIEW WITNESS NOTES above says it; no tip needed.
                          if (speaker != null && !finishing)
                            InkTextButton(
                              key: const ValueKey('open-statements'),
                              label: 'Notes ($heard)',
                              glyph: InkGlyph.notebook,
                              onPressed: onNotes,
                            ),
                          InkTextButton(
                            key: const ValueKey('open-words'),
                            label: 'Words',
                            glyph: InkGlyph.letter,
                            onPressed: onWords,
                          ),
                          if (tipLabel != null && !finishing)
                            InkTextButton(label: tipLabel!, glyph: InkGlyph.hint, color: tipLinkColor, onPressed: onTip),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Where the detective has got, and the next thing to do: a small mark
/// (2 STATEMENTS) over one short line. Arriving, the line alone ([guide]).
class _Status extends StatelessWidget {
  const _Status({required this.mark, required this.line, required this.guide, this.extra});

  final String? mark;
  final String line;
  final bool guide;

  /// A second, quieter line (where what was found is kept).
  final String? extra;

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
            if (extra != null)
              Text(
                extra!,
                key: const ValueKey('talk-extra'),
                textAlign: TextAlign.center,
                style: AppText.bodyText(size: 15, color: AppColors.inkBrown),
              ),
          ],
        ),
      ),
    );
  }
}

/// COMPARE TWO STATEMENTS. When it has just become possible ([ready]), it
/// comes in once with a gold edge and a soft glow that settles (still with
/// motion reduced: the gold edge only).
class _CompareButton extends StatelessWidget {
  const _CompareButton({required this.ready, required this.onPressed});

  final bool ready;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final button = GameButton(
      key: const ValueKey('compare-statements'),
      label: 'COMPARE TWO STATEMENTS',
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
/// a gold ring when they are the one talked to, and under the name what
/// tapping does or has done — TALK, or SPOKEN TO once asked anything (the
/// same for every witness, whatever they said).
class _SpeakerChoice extends StatelessWidget {
  const _SpeakerChoice({
    required this.speaker,
    required this.chosen,
    required this.spoken,
    required this.onTap,
  });

  final DialogueSpeaker speaker;
  final bool chosen;
  final bool spoken;
  final VoidCallback onTap;

  static const size = 44.0;

  @override
  Widget build(BuildContext context) {
    // A label under the face: it keeps its size with larger text.
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.1);
    return Semantics(
      button: true,
      selected: chosen,
      label: 'Talk to ${speaker.name.toLowerCase()}${spoken ? ', spoken to' : ''}',
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('speaker-${speaker.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
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
                  textScaler: scaler,
                  style: AppText.style(
                    AppText.body,
                    size: 13,
                    weight: chosen ? FontWeight.w700 : FontWeight.w500,
                    color: chosen ? AppColors.navy : AppColors.muted,
                  ),
                ),
                Row(
                  key: ValueKey('${spoken ? 'spoken' : 'talk'}-${speaker.id}'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (spoken) ...[
                      const InkIcon(InkGlyph.check, size: 11, color: AppColors.success),
                      const SizedBox(width: 2),
                    ],
                    Flexible(
                      child: Text(
                        spoken ? 'SPOKEN TO' : 'TALK',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textScaler: scaler,
                        style: AppText.style(
                          AppText.body,
                          size: 10.5,
                          weight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: spoken ? AppColors.success : AppColors.royalBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
/// asked is inked in soft blue. All alike: none is marked as the one.
class _QuestionChoice extends StatelessWidget {
  const _QuestionChoice({
    super.key,
    required this.question,
    required this.asked,
    required this.current,
    required this.onTap,
  });

  final DialogueQuestion question;
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
            color: current ? AppColors.navy : AppLine.faint(0.25),
            width: current ? AppLine.ink : AppLine.hairline,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.paper),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.sm),
              child: Row(
                children: [
                  InkIcon(
                    asked ? InkGlyph.check : InkGlyph.arrow,
                    size: AppIconSize.small,
                    color: asked ? AppColors.success : AppColors.navy,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      question.text,
                      style: AppText.bodyText(size: 15, weight: FontWeight.w600, color: AppColors.navy),
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

// ── Sheets: the words, the statements, and comparing two of them ─────────

/// The harder words of [text] (from the case's glossary), each a card to
/// tap for its meaning — listed here, so no word in the talk is dotted and
/// none looks like a clue. The meaning is never shown before a tap: the
/// English is read first.
Future<void> showTalkWords(BuildContext context, WidgetRef ref, String text) {
  final words = glossaryWordsOf(ref.read(currentEpisodeProvider), text);
  return showModalBottomSheet<void>(
    context: context,
    shape: paperSheetShape,
    showDragHandle: false,
    builder: (context) => SafeArea(
      child: Padding(
        key: const ValueKey('words-sheet'),
        padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PaperSheetTab(),
            Text('WORDS', textAlign: TextAlign.center, style: AppText.eyebrow()),
            const SizedBox(height: AppSpace.xs),
            Text(
              words.isEmpty ? 'No hard words here.' : 'Tap a word to see what it means.',
              textAlign: TextAlign.center,
              style: AppText.caption(),
            ),
            const SizedBox(height: AppSpace.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final w in words)
                  ActionChip(
                    key: ValueKey('word-${w.word.toLowerCase()}'),
                    label: Text(w.word, style: AppText.bodyText(size: 16, weight: FontWeight.w600, color: AppColors.navy)),
                    backgroundColor: AppColors.paper,
                    side: BorderSide(color: AppLine.faint(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.paper)),
                    onPressed: () => lookUpAndShowWord(context, ref, w.word, w.meaning),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

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
                        Expanded(child: Text('WITNESS NOTES', style: AppText.eyebrow())),
                        Text('${heard.length} / ${scene.statements.length}', style: AppText.mark(size: 14)),
                      ],
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text('What the witnesses told you, word for word.', style: AppText.caption()),
                    if (heard.isEmpty)
                      Text('Nothing yet. Ask the witnesses what they saw.', style: AppText.caption())
                    else
                      for (final id in heard) ...[
                        const SizedBox(height: AppSpace.sm),
                        WitnessStatementLine(scene: scene, statement: scene.statement(id)),
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

/// One statement: who said it (face and name), and its words, word for
/// word; with [source], where it was heard (in the notebook).
class WitnessStatementLine extends StatelessWidget {
  const WitnessStatementLine({super.key, required this.scene, required this.statement, this.source});

  final DialogueScene scene;
  final DialogueStatement statement;
  final String? source;

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
              Text('"${statement.text}"', style: AppText.letter(size: 17, color: AppColors.ink)),
              if (source != null) Text(source!, style: AppText.caption()),
            ],
          ),
        ),
      ],
    );
  }
}

/// What two chosen statements show.
enum _Verdict {
  /// The same thing, but not what the mission asks about: another pair.
  offTopic,

  /// Different things: another pair.
  different,

  /// The same thing, what the mission asks about: the answer.
  match,
}

/// Comparing statements: the detective chooses two of the statements heard
/// (any of them, about anything) and sees them side by side; a moment later
/// the game says what the two show. Nothing is chosen for the detective, no
/// statement is marked out, a pair that is not the answer never says which
/// is, and choosing again is always open.
class _CompareSheet extends ConsumerStatefulWidget {
  const _CompareSheet({required this.scene, required this.heard, required this.onSolved});

  final DialogueScene scene;

  /// The statements heard, in the order heard.
  final List<String> heard;
  final VoidCallback onSolved;

  @override
  ConsumerState<_CompareSheet> createState() => _CompareSheetState();
}

class _CompareSheetState extends ConsumerState<_CompareSheet> {
  final List<String> _picked = [];
  _Verdict? _verdict;

  /// Two are chosen and being looked at (the verdict comes in a moment, and
  /// stays a moment): taps wait, so none is lost or doubled.
  bool _judging = false;
  Timer? _timer;
  final _scroll = ScrollController();

  /// The two chosen, side by side: brought into sight once both are chosen.
  final _pairKey = GlobalKey();

  /// The two chosen are seen side by side before what they show is said,
  /// and what they show stays a moment before another tap counts.
  static const judgeAfter = Duration(milliseconds: 450);
  static const holdAfter = Duration(milliseconds: 500);
  static const closeAfter = Duration(milliseconds: 1800);

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _pick(String id) {
    if (_judging || _verdict == _Verdict.match) return;
    playUiTap(context, TapRole.select);
    setState(() {
      // After a pair that was not the answer, a tap starts a new pair with it.
      if (_verdict != null) {
        _verdict = null;
        _picked.clear();
      }
      if (_picked.contains(id)) {
        _picked.remove(id);
      } else {
        _picked.add(id);
      }
    });
    if (_picked.length == 2) _judgeSoon();
  }

  /// The two chosen: brought into sight whole, then judged.
  void _judgeSoon() {
    setState(() => _judging = true);
    _showPair(top: true);
    _timer = Timer(judgeAfter, _judge);
  }

  /// The two chosen and what they show, brought into sight with a short
  /// glide: the two at the top of what is seen ([top]), or just enough for
  /// what they show to be seen whole (no move when it already is).
  void _showPair({bool top = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pair = _pairKey.currentContext;
      if (!mounted || pair == null) return;
      final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      Scrollable.ensureVisible(
        pair,
        alignmentPolicy: top ? ScrollPositionAlignmentPolicy.explicit : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: still ? Duration.zero : const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _judge() {
    if (!mounted || _picked.length != 2) return;
    final scene = widget.scene;
    final (a, b) = (_picked[0], _picked[1]);
    if (scene.deduction.solves(a, b)) {
      ref.read(audioServiceProvider).play(GameSound.pencilNote);
      HapticFeedback.mediumImpact();
      widget.onSolved();
      setState(() => _verdict = _Verdict.match);
      _showPair();
      _timer = Timer(closeAfter, () {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }
    // Not the answer: what they show, and the same two stay to look at.
    HapticFeedback.selectionClick();
    setState(() => _verdict = scene.matches(a, b) ? _Verdict.offTopic : _Verdict.different);
    _showPair();
    _timer = Timer(holdAfter, () {
      if (mounted) setState(() => _judging = false);
    });
  }

  /// Back to choosing two (none chosen for the detective).
  void _anotherPair() {
    if (_judging) return;
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
    // The two describe the same thing (the answer, or not what is asked).
    final alike = matched || _verdict == _Verdict.offTopic;
    // Not the answer: the way on is another pair.
    final anotherPair = _verdict == _Verdict.offTopic || _verdict == _Verdict.different;
    // Headings keep (about) their size with larger text, so the statements
    // keep their room.
    final heading = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.1);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                key: const ValueKey('compare-sheet'),
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PaperSheetTab(),
                    Text('COMPARE STATEMENTS', textAlign: TextAlign.center, style: AppText.eyebrow()),
                    const SizedBox(height: AppSpace.xs),
                    // What to find, and how — never which.
                    Text(
                      d.compareGoal,
                      key: const ValueKey('compare-goal'),
                      textAlign: TextAlign.center,
                      textScaler: heading,
                      style: AppText.title(size: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      d.compareHow,
                      key: const ValueKey('compare-how'),
                      textAlign: TextAlign.center,
                      textScaler: heading,
                      style: AppText.bodyText(size: 15, weight: FontWeight.w600, color: AppColors.inkBrown),
                    ),
                    // The two chosen side by side, and right under them what
                    // they show — one block, brought into sight whole. Nothing
                    // here before a first choice.
                    if (_picked.isNotEmpty)
                      Padding(
                        key: _pairKey,
                        padding: const EdgeInsets.only(top: AppSpace.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                                              matched: alike,
                                            )
                                          : const _EmptyStory(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (_verdict != null)
                              Padding(
                                padding: const EdgeInsets.only(top: AppSpace.sm),
                                child: _VerdictBlock(verdict: _verdict!, deduction: d),
                              ),
                          ],
                        ),
                      ),
                    if (!matched) ...[
                      const SizedBox(height: AppSpace.md),
                      Text(
                        _picked.isEmpty ? 'YOUR STATEMENTS — TAP TWO' : 'YOUR STATEMENTS',
                        textScaler: heading,
                        style: AppText.eyebrow(color: AppColors.muted),
                      ),
                      const SizedBox(height: AppSpace.xs),
                      // Every statement heard, alike, in the order heard.
                      for (final id in widget.heard)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.xs),
                          child: _PickStatement(
                            scene: scene,
                            statement: scene.statement(id),
                            order: _picked.indexOf(id),
                            onTap: () => _pick(id),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            // The way on (another pair) and the way back, always in sight.
            if (!matched)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppLine.faint(0.15))),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (anotherPair) ...[
                        GameButton(
                          key: const ValueKey('choose-another-pair'),
                          label: 'CHOOSE ANOTHER PAIR',
                          glyph: InkGlyph.eye,
                          singleLine: true,
                          onPressed: _anotherPair,
                        ),
                        const SizedBox(height: AppSpace.sm),
                      ],
                      GameButton(
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
              ),
          ],
        ),
      ),
    );
  }
}

/// What two chosen statements show, right under them. The answer: the
/// MATCH stamp. The same thing but not what is asked: the match first,
/// acknowledged (it is a true find), then the mission recalled — calmly,
/// never as an error, never naming the answer. Different things: said
/// gently, and to try another pair.
class _VerdictBlock extends StatelessWidget {
  const _VerdictBlock({required this.verdict, required this.deduction});

  final _Verdict verdict;
  final DialogueDeduction deduction;

  @override
  Widget build(BuildContext context) {
    final d = deduction;
    final heading = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.1);
    Widget mark(String text, Color color, {InkGlyph? glyph}) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (glyph != null) ...[
              InkIcon(glyph, size: AppIconSize.small, color: color),
              const SizedBox(width: AppSpace.xs),
            ],
            Flexible(
              child: Text(text, textAlign: TextAlign.center, textScaler: heading, style: AppText.eyebrow(color: color)),
            ),
          ],
        );
    Widget line(String text, {Color color = AppColors.ink}) => Text(
          text,
          textAlign: TextAlign.center,
          style: AppText.bodyText(size: 16, weight: FontWeight.w600, color: color),
        );
    final body = switch (verdict) {
      _Verdict.match => _Match(line: d.matchLine),
      _Verdict.offTopic => Column(
          children: [
            mark('GOOD MATCH!', AppColors.success, glyph: InkGlyph.check),
            const SizedBox(height: 2),
            line(d.offTopicLine),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
              child: Divider(height: 1, color: AppLine.faint(0.2)),
            ),
            mark('BUT CHECK YOUR MISSION', AppColors.goldDeep, glyph: InkGlyph.search),
            const SizedBox(height: 2),
            line(d.checkLine, color: AppColors.navy),
          ],
        ),
      _Verdict.different => Column(
          children: [
            mark('THE STORIES ARE DIFFERENT', AppColors.inkBrown),
            const SizedBox(height: 2),
            line(d.differentLine),
            const SizedBox(height: 2),
            line(d.retryLine, color: AppColors.muted),
          ],
        ),
    };
    return TweenAnimationBuilder<double>(
      key: ValueKey(verdict),
      tween: Tween(begin: (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Container(
        key: const ValueKey('compare-feedback'),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.md),
        decoration: verdict == _Verdict.match
            ? null
            : BoxDecoration(
                color: AppColors.parchment.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(AppRadius.paper),
                border: Border.all(color: AppLine.faint(0.2), width: AppLine.hairline),
              ),
        child: body,
      ),
    );
  }
}

/// A statement to choose for comparing: who said it and their words, and
/// 1 or 2 when chosen (tap again to let it go). Every statement looks the
/// same until chosen.
class _PickStatement extends StatelessWidget {
  const _PickStatement({required this.scene, required this.statement, required this.order, required this.onTap});

  final DialogueScene scene;
  final DialogueStatement statement;

  /// 0 or 1 when chosen (first, second), else -1.
  final int order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chosen = order >= 0;
    final who = scene.speaker(statement.speakerId);
    return Semantics(
      button: true,
      selected: chosen,
      label: '${who.name} said: ${statement.text}${chosen ? ', chosen ${order + 1}' : ''}',
      excludeSemantics: true,
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
          key: ValueKey('pick-${statement.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.paper),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs + 2),
              child: Row(
                children: [
                  SizedBox.square(dimension: 32, child: ClipOval(child: _Face(speaker: who))),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          who.name.replaceFirst('The ', '').toUpperCase(),
                          textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.1),
                          style: AppText.eyebrow(color: AppColors.muted),
                        ),
                        Text('"${statement.text}"', style: AppText.letter(size: 16, color: AppColors.ink)),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: chosen ? AppColors.navy : Colors.transparent,
                      border: Border.all(color: chosen ? Colors.transparent : AppLine.faint(0.35), width: AppLine.rule),
                    ),
                    child: chosen
                        ? Text(
                            '${order + 1}',
                            textScaler: TextScaler.noScaling,
                            style: AppText.style(AppText.body, size: 13, weight: FontWeight.w700, color: AppColors.paperLight),
                          )
                        : null,
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
  const _StoryCard({super.key, required this.scene, required this.statement, required this.matched});

  final DialogueScene scene;
  final DialogueStatement statement;
  final bool matched;

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
            SizedBox.square(
              dimension: 44,
              child: ClipOval(child: _Face(speaker: who)),
            ),
            const SizedBox(height: AppSpace.xs),
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

/// The place of the second statement, not chosen yet.
class _EmptyStory extends StatelessWidget {
  const _EmptyStory();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.parchment.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.paper),
        border: Border.all(color: AppColors.parchmentDark, width: AppLine.rule),
      ),
      child: Text('2', style: AppText.title(size: 28, color: AppColors.parchmentDark)),
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
          Text(line, textAlign: TextAlign.center, style: AppText.title(size: 20)),
        ],
      ),
    );
  }
}

/// A child that waits while the portrait of [id] is flying in, and comes in
/// softly [delay] after it lands (at once when nothing is flying). It never
/// takes a touch while waiting.
class _AfterLanding extends StatefulWidget {
  const _AfterLanding({super.key, required this.flying, required this.id, required this.delay, required this.child});

  final ValueListenable<String?> flying;
  final String? id;
  final Duration delay;
  final Widget child;

  @override
  State<_AfterLanding> createState() => _AfterLandingState();
}

class _AfterLandingState extends State<_AfterLanding> {
  late bool _shown = widget.id == null || widget.flying.value != widget.id;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.flying.addListener(_changed);
  }

  void _changed() {
    if (_shown || widget.flying.value == widget.id) return;
    _timer ??= Timer(widget.delay, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  void dispose() {
    widget.flying.removeListener(_changed);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !_shown,
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: widget.child,
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
