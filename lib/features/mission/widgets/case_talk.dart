import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart';
import '../../../data/models/case_talk.dart';
import '../../../data/models/mission.dart' show Evidence;
import '../../../widgets/display_sized_image.dart';
import '../../../widgets/evidence_card.dart' show EvidencePicture, EvidenceThumb;
import '../../../widgets/game_button.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/paper.dart';
import '../../../widgets/paper_background.dart';
import '../../../widgets/place_scenery.dart';
import '../../../widgets/typewriter_text.dart';
import '../../game/game_providers.dart';
import 'evidence_recall.dart';

/// A talk with one person (see [TalkScene]): their portrait in the middle
/// (when there is one: never a stand-in), one short line at a time in the
/// card under it, and under that what the detective can do now — ask a
/// question, show evidence from the notebook, or go on once the talk is
/// finished.
///
/// The talk is [progress], kept by the page that shows it and saved by it
/// ([onProgress], the mission's puzzle state): a talk left at any line
/// opens there again. [onFinish] is called once, when the detective goes on
/// from a finished talk.
class CaseTalk extends ConsumerStatefulWidget {
  const CaseTalk({super.key, required this.scene, required this.progress, required this.onProgress, required this.onFinish, this.pickEvidence});

  final TalkScene scene;
  final TalkProgress progress;
  final ValueChanged<TalkProgress> onProgress;
  final VoidCallback onFinish;

  /// Opens the notebook to choose what to show: the id chosen, or null.
  /// Defaults to the notebook's evidence of this season and the scene's
  /// earlier-season pieces held ([showEvidencePicker]).
  final Future<String?> Function(BuildContext context)? pickEvidence;

  @override
  ConsumerState<CaseTalk> createState() => _CaseTalkState();
}

class _CaseTalkState extends ConsumerState<CaseTalk> {
  late TalkProgress _p = widget.progress;

  /// The line on screen is typed out whole.
  bool _typed = false;
  bool _skipTyping = false;

  /// The beat being said was heard before (a question asked again, the
  /// opening coming back): it can be skipped.
  late bool _heardBefore = _p.beatId == TalkScene.openingId ? _p.openingSeen : _p.isDone(_p.beatId) && _p.beatOver(widget.scene);

  bool _finishing = false;

  /// Pieces shown from two cards that did not fit, by present (not saved).
  final Map<String, int> _misses = {};

  TalkScene get _scene => widget.scene;

  @override
  void didUpdateWidget(covariant CaseTalk oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress && widget.progress != _p) _set(widget.progress, report: false);
  }

  void _set(TalkProgress next, {bool report = true, bool heardBefore = false}) {
    final newBeat = next.beatId != _p.beatId;
    final moved = newBeat || next.line != _p.line;
    setState(() {
      _p = next;
      if (moved) {
        _typed = false;
        _skipTyping = false;
      }
      // A new beat (or the same question asked again) starts unheard unless
      // it was heard before.
      if (newBeat || heardBefore) _heardBefore = heardBefore;
    });
    if (report) widget.onProgress(next);
  }

  /// The card tapped: the line whole first, then the next line.
  void _advance() {
    if (!_typed) {
      setState(() => _skipTyping = true);
      return;
    }
    if (_p.beatOver(_scene)) return;
    playUiTap(context, TapRole.select);
    _set(_p.next(_scene));
  }

  void _skip() {
    playUiTap(context, TapRole.select);
    _set(_p.skip(_scene));
    setState(() => _skipTyping = true);
  }

  void _ask(TalkQuestion q) {
    if (!_p.beatOver(_scene)) return;
    playUiTap(context, TapRole.select);
    final again = _p.isDone(q.id);
    _set(_p.ask(_scene, q.id), heardBefore: again);
  }

  Future<void> _show() async {
    if (!_p.beatOver(_scene) || _p.nextPresent(_scene) == null) return;
    ref.read(audioServiceProvider).play(GameSound.notebookOpen);
    final pick =
        widget.pickEvidence ??
        (context) => showEvidencePicker(context, ask: 'Which clue will you show?', earlier: heldEarlierEvidence(ref, _scene.earlierEvidence));
    final id = await pick(context);
    if (id == null || !mounted) return;
    final (next, fits) = _p.show(_scene, id);
    ref.read(audioServiceProvider).play(fits ? GameSound.pencilNote : GameSound.paperRustle);
    _set(next);
  }

  /// A card picked from the two shown ([TalkPresent.choices]).
  void _choose(String evidenceId) {
    final present = _p.nextPresent(_scene);
    if (!_p.beatOver(_scene) || present == null) return;
    final (next, fits) = _p.show(_scene, evidenceId);
    ref.read(audioServiceProvider).play(fits ? GameSound.pencilNote : GameSound.paperRustle);
    if (!fits) _misses[present.id] = (_misses[present.id] ?? 0) + 1;
    _set(next);
  }

  void _finish() {
    if (_finishing) return;
    _finishing = true;
    widget.onFinish();
  }

  Future<void> _log() {
    ref.read(audioServiceProvider).play(GameSound.paperRustle);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: paperSheetShape,
      showDragHandle: false,
      builder: (context) => _TalkLog(scene: _scene, progress: _p),
    );
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final line = _p.current(_scene);
    final portrait = _scene.speaker.portrait(_p.mood(_scene));
    final background = _scene.background;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (background != null) PlaceScenery.file(background) else const ColoredBox(color: AppColors.navyDeep),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.navyDeep.withValues(alpha: 0.25), AppColors.navyDeep.withValues(alpha: 0.15), AppColors.navyDeep.withValues(alpha: 0.9)],
              stops: const [0, 0.4, 1],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GoalStrip(goal: _scene.goal),
              Expanded(
                child: portrait == null
                    // No portrait yet: nothing stands in for the person.
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, 0),
                        child: AnimatedSwitcher(
                          duration: still ? Duration.zero : const Duration(milliseconds: 200),
                          child: _Portrait(
                            key: ValueKey('case-talk-portrait-$portrait'),
                            file: portrait,
                            label: '${_p.speakerName(_scene)}. ${_scene.speaker.description}',
                          ),
                        ),
                      ),
              ),
              if (line != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                  child: _Speech(
                    line: line,
                    name: switch (line.voice) {
                      TalkVoice.speaker => _p.speakerName(_scene),
                      TalkVoice.detective => 'YOU',
                      TalkVoice.narrator => null,
                    },
                    // The beat and line it is, so a new line types afresh.
                    lineKey: '${_p.beatId}#${_p.line}',
                    skip: _skipTyping,
                    more: !_p.beatOver(_scene),
                    // Typed out whole: said after this frame (a line shown
                    // whole at a tap is finished while it is being built).
                    onTyped: () => WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!_typed && mounted) setState(() => _typed = true);
                    }),
                    onTap: _advance,
                  ),
                ),
              _Panel(
                scene: _scene,
                progress: _p,
                typed: _typed,
                canSkip: _heardBefore && !_p.beatOver(_scene),
                onNext: _advance,
                onSkip: _skip,
                onAsk: _ask,
                onShow: _show,
                onChoose: _choose,
                misses: _misses,
                onFinish: _finish,
                onLog: _log,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// What the detective is finding out, one line over the talk.
class _GoalStrip extends StatelessWidget {
  const _GoalStrip({required this.goal});

  final String goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('case-talk-goal'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xs + 2),
      color: AppColors.navyDeep.withValues(alpha: 0.55),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const InkIcon(InkGlyph.search, size: AppIconSize.small, color: AppColors.goldLight),
          const SizedBox(width: AppSpace.sm),
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

/// The person's portrait, a print shown whole. A picture that cannot be
/// loaded leaves the space empty (never a stand-in).
class _Portrait extends StatelessWidget {
  const _Portrait({super.key, required this.file, required this.label});

  final String file;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: label,
      // Decoded at the size it is shown (a 1024 × 1536 portrait, never all of it).
      child: DisplaySizedImage(
        file,
        imageKey: const ValueKey('case-talk-portrait'),
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}

/// The line said now, in its paper card: the speaker's name plate over it
/// (none for the narrator), typed out; tapped, it is whole at once, then the
/// next line comes. A small arrow says there is more.
class _Speech extends StatelessWidget {
  const _Speech({
    required this.line,
    required this.name,
    required this.lineKey,
    required this.skip,
    required this.more,
    required this.onTyped,
    required this.onTap,
  });

  final TalkLine line;
  final String? name;
  final String lineKey;
  final bool skip;
  final bool more;
  final VoidCallback onTyped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final narrator = line.voice == TalkVoice.narrator;
    return Semantics(
      button: true,
      liveRegion: true,
      label: '${name == null ? '' : '$name: '}${line.text}${more ? '. Tap for more.' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('case-talk-line'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (name != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.xs),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name!,
                    key: const ValueKey('case-talk-name'),
                    maxLines: 1,
                    style: AppText.mark(color: AppColors.goldLight, size: 15),
                  ),
                ),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.paperLight,
                  borderRadius: BorderRadius.circular(AppRadius.paper),
                  border: Border.all(color: AppLine.faint(), width: AppLine.hairline),
                  boxShadow: AppShadow.onNight,
                ),
                padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md),
                child: InkSurface(
                  night: false,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TypewriterText(
                          narrator || line.voice == TalkVoice.detective ? line.text : '"${line.text}"',
                          key: ValueKey('case-talk-type-$lineKey'),
                          style: narrator
                              ? AppText.letter(size: 18, color: AppColors.inkBrown).copyWith(fontStyle: FontStyle.italic)
                              : AppText.letter(size: 19, color: AppColors.ink),
                          textAlign: TextAlign.start,
                          skip: skip,
                          sound: false,
                          onFinished: onTyped,
                        ),
                      ),
                      if (more) ...[const SizedBox(width: AppSpace.sm), const InkIcon(InkGlyph.chevron, size: AppIconSize.small, color: AppColors.burgundy)],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Under the line: while a beat is said, NEXT (and SKIP for one heard
/// before); once it is said, the questions to ask, SHOW for the evidence
/// asked for, and the way on once the talk is finished. TALK LOG reads
/// back what was said.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.scene,
    required this.progress,
    required this.typed,
    required this.canSkip,
    required this.onNext,
    required this.onSkip,
    required this.onAsk,
    required this.onShow,
    required this.onChoose,
    required this.misses,
    required this.onFinish,
    required this.onLog,
  });

  final TalkScene scene;
  final TalkProgress progress;
  final bool typed;
  final bool canSkip;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final ValueChanged<TalkQuestion> onAsk;
  final VoidCallback onShow;
  final ValueChanged<String> onChoose;
  final Map<String, int> misses;
  final VoidCallback onFinish;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final saying = !progress.beatOver(scene);
    final present = saying ? null : progress.nextPresent(scene);
    final questions = saying ? const <TalkQuestion>[] : progress.questions(scene);
    final finished = !saying && progress.finished(scene);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.42),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (saying)
              Row(
                children: [
                  if (canSkip) ...[
                    Expanded(
                      child: GameButton(
                        key: const ValueKey('case-talk-skip'),
                        label: 'SKIP',
                        style: GameButtonStyle.outline,
                        singleLine: true,
                        onPressed: onSkip,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                  ],
                  Expanded(
                    flex: 2,
                    child: GameButton(
                      key: const ValueKey('case-talk-next'),
                      label: typed ? 'NEXT' : 'READ ALL',
                      glyph: InkGlyph.chevron,
                      style: GameButtonStyle.glass,
                      singleLine: true,
                      onPressed: onNext,
                    ),
                  ),
                ],
              )
            else ...[
              if (finished) ...[
                GameButton(
                  key: const ValueKey('case-talk-finish'),
                  label: scene.finishLabel,
                  arrow: true,
                  singleLine: true,
                  tap: TapRole.primary,
                  onPressed: onFinish,
                ),
                const SizedBox(height: AppSpace.sm),
              ],
              if (present != null && present.choices.isNotEmpty) ...[
                _EvidenceChoice(present: present, missed: misses[present.id] ?? 0, onChoose: onChoose),
                const SizedBox(height: AppSpace.sm),
              ] else if (present != null) ...[
                Text(
                  present.prompt,
                  key: const ValueKey('case-talk-show-prompt'),
                  textAlign: TextAlign.center,
                  style: AppText.bodyText(size: 16, weight: FontWeight.w600, color: AppColors.goldLight),
                ),
                const SizedBox(height: AppSpace.xs),
                GameButton(
                  key: const ValueKey('case-talk-show'),
                  label: 'SHOW EVIDENCE',
                  glyph: InkGlyph.notebook,
                  style: GameButtonStyle.gold,
                  singleLine: true,
                  tap: TapRole.primary,
                  onPressed: onShow,
                ),
                const SizedBox(height: AppSpace.sm),
              ],
              for (final q in questions) ...[
                _QuestionButton(question: q, asked: progress.isDone(q.id), onTap: () => onAsk(q)),
                const SizedBox(height: AppSpace.xs),
              ],
            ],
            Align(
              alignment: Alignment.centerRight,
              child: InkTextButton(
                key: const ValueKey('case-talk-log'),
                label: 'Talk log',
                glyph: InkGlyph.notebook,
                color: AppColors.paperLight.withValues(alpha: 0.8),
                onPressed: onLog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A question to ask: large enough for a thumb; one asked already is marked
/// with a tick and quieter (it can be asked again).
class _QuestionButton extends StatelessWidget {
  const _QuestionButton({required this.question, required this.asked, required this.onTap});

  final TalkQuestion question;
  final bool asked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${question.text}${asked ? ' Asked.' : ''}',
      excludeSemantics: true,
      child: Material(
        color: asked ? AppColors.navyDeep.withValues(alpha: 0.55) : AppColors.paperLight,
        borderRadius: BorderRadius.circular(AppRadius.paper),
        child: InkWell(
          key: ValueKey('case-talk-q-${question.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.paper),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
              child: Row(
                children: [
                  InkIcon(asked ? InkGlyph.check : InkGlyph.pen, size: AppIconSize.small, color: asked ? AppColors.goldLight : AppColors.burgundy),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      question.text,
                      style: AppText.bodyText(
                        size: 17,
                        weight: asked ? FontWeight.w400 : FontWeight.w600,
                        color: asked ? AppColors.paperLight : AppColors.navy,
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

/// What was said so far, read back: the opening, then each question asked
/// and each piece shown, in the order they were done (a piece that did not
/// fit is not kept).
class _TalkLog extends StatelessWidget {
  const _TalkLog({required this.scene, required this.progress});

  final TalkScene scene;
  final TalkProgress progress;

  @override
  Widget build(BuildContext context) {
    final name = progress.speakerName(scene);
    String who(TalkLine l) => switch (l.voice) {
      TalkVoice.speaker => name,
      TalkVoice.detective => 'YOU',
      TalkVoice.narrator => '',
    };
    final beats = [TalkScene.openingId, ...progress.done];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (context, scroll) => Column(
        children: [
          const PaperSheetTab(),
          Text('TALK LOG', key: const ValueKey('case-talk-log-sheet'), style: AppText.mark()),
          const SizedBox(height: AppSpace.sm),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, AppSpace.xl),
              children: [
                for (final b in beats) ...[
                  if (scene.question(b) case final q?)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.xs),
                      child: Text(q.text, style: AppText.title(size: 16, color: AppColors.burgundy)),
                    ),
                  if (scene.present(b) case final p?)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.xs),
                      child: Text(p.prompt, style: AppText.eyebrow(color: AppColors.burgundy)),
                    ),
                  for (final l in scene.beat(b))
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.xs),
                      child: GlossaryText(who(l).isEmpty ? l.text : '${who(l)}: ${l.text}', style: AppText.letter(size: 16, color: AppColors.ink)),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What to show, from two cards right there (no notebook to search): the
/// question over them, and the two pieces, large. After a second miss, the
/// line that says which ([TalkPresent.tell]), and that card lit.
class _EvidenceChoice extends ConsumerWidget {
  const _EvidenceChoice({required this.present, required this.missed, required this.onChoose});

  final TalkPresent present;
  final int missed;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = {
      for (final e in ref.watch(playedEpisodesProvider))
        for (final v in e.allEvidence) v.id: v,
    };
    final told = missed >= 2 && present.tell != null;
    final cards = [for (final id in present.choices) ?all[id]];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          told ? present.tell! : present.prompt,
          key: const ValueKey('case-talk-show-prompt'),
          textAlign: TextAlign.center,
          style: AppText.bodyText(size: 18, weight: FontWeight.w700, color: AppColors.goldLight),
        ),
        const SizedBox(height: AppSpace.sm),
        // Both cards as tall as the taller one (the panel scrolls: no
        // height to stretch to otherwise).
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final e in cards) ...[
                Expanded(
                  child: _EvidenceCard(
                    key: ValueKey('case-talk-choice-${e.id}'),
                    evidence: e,
                    lit: missed >= 2 && present.accepted.contains(e.id),
                    onTap: () => onChoose(e.id),
                  ),
                ),
                if (e != cards.last) const SizedBox(width: AppSpace.md),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({super.key, required this.evidence, required this.lit, required this.onTap});

  final Evidence evidence;
  final bool lit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Show ${evidence.name}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.button),
          boxShadow: lit ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.8), blurRadius: 18, spreadRadius: 2)] : AppShadow.onNight,
        ),
        child: Material(
          color: AppColors.paperLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            side: BorderSide(color: lit ? AppColors.gold : AppColors.goldLight, width: lit ? 4 : 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.button),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 120),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EvidenceThumb(evidence: evidence, size: 64),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      evidence.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: AppText.title(size: 16, color: AppColors.navy),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A case's ending, one line at a time, each line on only when the
/// detective taps on (never hurried): the place behind it, a face or a
/// piece of evidence, the line in its card. The last line's button closes
/// the case ([onFinish]).
class CaseEnding extends ConsumerStatefulWidget {
  const CaseEnding({super.key, required this.lines, required this.onFinish, this.finishLabel = 'CLOSE THE CASE'});

  final List<EndingLine> lines;
  final VoidCallback onFinish;
  final String finishLabel;

  @override
  ConsumerState<CaseEnding> createState() => _CaseEndingState();
}

class _CaseEndingState extends ConsumerState<CaseEnding> {
  int _at = 0;
  bool _typed = false;
  bool _skip = false;
  bool _closing = false;

  bool get _last => _at == widget.lines.length - 1;

  void _next() {
    if (!_typed) {
      setState(() => _skip = true);
      return;
    }
    if (_last) {
      if (_closing) return;
      _closing = true;
      widget.onFinish();
      return;
    }
    playUiTap(context, TapRole.select);
    setState(() {
      _at++;
      _typed = false;
      _skip = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final line = widget.lines[_at];
    final evidence = line.evidenceId == null
        ? null
        : [
            for (final e in ref.watch(playedEpisodesProvider))
              for (final v in e.allEvidence)
                if (v.id == line.evidenceId) v,
          ].firstOrNull;
    final fade = Duration(milliseconds: still ? 0 : 450);
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: fade,
          child: KeyedSubtree(key: ValueKey('ending-bg-${line.background}'), child: PlaceScenery.file(line.background)),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.navyDeep.withValues(alpha: 0.1), AppColors.navyDeep.withValues(alpha: 0.1), AppColors.navyDeep.withValues(alpha: 0.88)],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.sm),
                  child: AnimatedSwitcher(
                    duration: fade,
                    child: evidence != null
                        ? Center(
                            key: ValueKey('ending-evidence-${evidence.id}'),
                            child: _RecordCard(evidence: evidence),
                          )
                        : line.portrait != null
                        ? _Portrait(key: ValueKey('ending-portrait-${line.portrait}'), file: line.portrait!, label: line.name ?? '')
                        : const SizedBox.expand(key: ValueKey('ending-empty')),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                child: _Speech(
                  line: switch (line.voice) {
                    TalkVoice.narrator => TalkLine.narrator(line.text),
                    TalkVoice.detective => TalkLine.detective(line.text),
                    TalkVoice.speaker => TalkLine(line.text),
                  },
                  name: switch (line.voice) {
                    TalkVoice.speaker => line.name,
                    TalkVoice.detective => 'YOU',
                    TalkVoice.narrator => null,
                  },
                  lineKey: 'ending#$_at',
                  skip: _skip,
                  more: !_last,
                  onTyped: () => WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!_typed && mounted) setState(() => _typed = true);
                  }),
                  onTap: _next,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.md),
                child: GameButton(
                  key: const ValueKey('ending-next'),
                  label: !_typed ? 'READ ALL' : (_last ? widget.finishLabel : 'NEXT'),
                  glyph: _last && _typed ? InkGlyph.folder : InkGlyph.chevron,
                  style: _last && _typed ? GameButtonStyle.gold : GameButtonStyle.glass,
                  singleLine: true,
                  tap: TapRole.primary,
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A record of earlier words, laid over the ending: the evidence card with
/// its words in quotes.
class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.evidence});

  final Evidence evidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.paperLight,
        borderRadius: BorderRadius.circular(AppRadius.paper),
        border: Border.all(color: AppColors.inkBrown.withValues(alpha: 0.5), width: 2),
        boxShadow: AppShadow.onNight,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Its words as they were said (the record's own picture).
          EvidencePicture(evidence: evidence, maxHeight: 190),
          const SizedBox(height: AppSpace.sm),
          Text(
            evidence.name.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppText.mark(size: 16, color: AppColors.goldDeep),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            evidence.description,
            textAlign: TextAlign.center,
            style: AppText.aside(size: 15, color: AppColors.inkBrown),
          ),
        ],
      ),
    );
  }
}
