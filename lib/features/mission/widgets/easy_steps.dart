import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart';
import '../../../data/models/easy_steps.dart';
import '../../../data/models/mission.dart' show Evidence;
import '../../../widgets/evidence_card.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/landmark_art.dart' show ClockHandsPainter;
import '../../game/game_providers.dart';
import 'opera_papers.dart' show PixelCrop;
import 'question_widgets.dart' show ShakeOnChange;
import 'workshop_papers.dart' show DrawnEvidenceView;

/// A puzzle of Cases 11–12 played one step at a time ([EasyStepsScene]):
/// what to do in a few words on top (and HINT beside it, free at any
/// time), what it needs in the middle (the thing to tap lit), and the
/// answers or the way on at the foot of the page, large.
///
/// [done]: how many steps are done (saved; [onDone] saves a step done).
/// Once the last step is done, its button sends the puzzle's answer
/// ([onFinish]). A wrong answer is never sent: the first one lights where
/// to look, the second says the answer.
class EasyStepsPuzzle extends ConsumerStatefulWidget {
  const EasyStepsPuzzle({
    super.key,
    required this.scene,
    required this.done,
    required this.onDone,
    required this.onFinish,
    this.eyebrow,
    this.dark = false,
  });

  final EasyStepsScene scene;
  final int done;
  final ValueChanged<int> onDone;
  final ValueChanged<String> onFinish;

  /// Over the steps ("MISSION 01"); the scene's title follows it.
  final String? eyebrow;

  /// On the night desk (a final): light words on dark.
  final bool dark;

  @override
  ConsumerState<EasyStepsPuzzle> createState() => _EasyStepsPuzzleState();
}

enum _Say { hint, wrong, done }

class _EasyStepsPuzzleState extends ConsumerState<EasyStepsPuzzle> {
  late int _at = widget.done.clamp(0, widget.scene.steps.length - 1);

  /// The step on screen is done (its done line and the way on are shown).
  late bool _stepDone = widget.done > _at;

  int _wrong = 0;
  int _hints = 0;
  int _shake = 0;
  String? _line;
  _Say? _say;

  /// A rubbing: the cells of the page rubbed so far (not saved: a page
  /// left half-rubbed is rubbed again, quickly).
  final Set<int> _rubbed = {};

  bool _finished = false;

  EasyStepsScene get _scene => widget.scene;
  EasyStep get _step => _scene.steps[_at];
  bool get _last => _at == _scene.steps.length - 1;

  void _play(GameSound s) => ref.read(audioServiceProvider).play(s);

  /// The step done: saved, then its done line (if it has one) or the next
  /// step at once.
  void _complete() {
    if (_stepDone) return;
    final step = _step;
    setState(() {
      _stepDone = true;
      _line = step.done;
      _say = step.done == null ? null : _Say.done;
    });
    widget.onDone(_at + 1);
    if (step.done == null && step.after == null) _last ? _finish() : _advance();
  }

  void _advance() {
    if (_last) return;
    setState(() {
      _at++;
      _stepDone = false;
      _wrong = 0;
      _hints = 0;
      _line = null;
      _say = null;
      _rubbed.clear();
    });
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onFinish(_scene.answer);
  }

  void _choose(String id) {
    if (_stepDone) return;
    final step = _step;
    if (id == step.answer) {
      _play(GameSound.pencilNote);
      _complete();
      return;
    }
    _play(GameSound.puzzleWrong);
    final option = step.option(id);
    setState(() {
      _wrong++;
      _shake++;
      _say = _Say.wrong;
      _line = _wrong >= 2 ? (step.tell ?? option?.feedback ?? step.wrong) : (option?.feedback ?? step.wrong);
    });
  }

  void _hint() {
    final step = _step;
    playUiTap(context, TapRole.select);
    setState(() {
      _hints++;
      _say = _Say.hint;
      _line = step.hints[math.min(_hints, step.hints.length) - 1];
    });
  }

  void _tapTarget() {
    if (_stepDone) return;
    _play(GameSound.paperRustle);
    _complete();
  }

  /// A rub at [cell] (and its neighbours when [wide]: a tap rubs a patch).
  void _rub(Iterable<int> cells) {
    if (_stepDone) return;
    final before = _rubbed.length;
    setState(() => _rubbed.addAll(cells));
    if (_rubbed.length != before && _rubCoverage >= _RubView.enough) {
      _play(GameSound.pencilNote);
      _complete();
    }
  }

  double get _rubCoverage => _rubbed.length / (_RubView.columns * _RubView.rows);

  /// The answer is lit: after a second wrong answer, or every hint said.
  bool get _showAnswer => _wrong >= 2 || _hints > _step.hints.length;

  /// Where to look is lit: after a wrong answer, or every hint said.
  bool get _showLook => _wrong >= 1 || _hints > _step.hints.length;

  @override
  Widget build(BuildContext context) {
    final step = _step;
    final stepDone = _stepDone;
    final dark = widget.dark;
    final ink = dark ? AppColors.paperLight : AppColors.navy;
    final panels = _stepDone ? (step.after ?? step.panels) : step.panels;
    final pictureOptions = step.does == EasyDo.choose && step.options.any((o) => o.panel != null);
    final textOptions = step.does == EasyDo.choose && step.options.every((o) => o.panel == null && o.area == null);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            eyebrow: [?widget.eyebrow, _scene.title].join(' · '),
            at: _at,
            of: _scene.steps.length,
            dark: dark,
          ),
          const SizedBox(height: AppSpace.sm),
          // What to do now, and the free hint beside it.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: GlossaryText(
                    step.say,
                    key: ValueKey('easy-say-${step.id}-$_stepDone'),
                    style: AppText.title(size: 23, color: ink),
                  ),
                ),
              ),
              if (!_stepDone) ...[
                const SizedBox(width: AppSpace.sm),
                _HintButton(key: const ValueKey('easy-hint'), dark: dark, onTap: _hint),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Expanded(
            child: ShakeOnChange(
              trigger: _shake,
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 300),
                child: KeyedSubtree(
                  key: ValueKey('easy-stage-${step.id}'),
                  child: pictureOptions && !_stepDone
                      ? _ChoiceCards(
                          reference: panels,
                          step: step,
                          showAnswer: _showAnswer,
                          showLook: _showLook,
                          dark: dark,
                          onChoose: _choose,
                        )
                      : _Panels(
                          panels: panels,
                          dark: dark,
                          // The step and whether it is done as built: a step
                          // fading out keeps its own (never the next one's).
                          builder: (panel, size) => _panelFor(panel, step, size, done: stepDone),
                        ),
                ),
              ),
            ),
          ),
          if (step.question != null && !_stepDone) ...[
            const SizedBox(height: AppSpace.sm),
            GlossaryText(
              step.question!,
              key: const ValueKey('easy-question'),
              style: AppText.title(size: 24, color: ink),
              textAlign: TextAlign.center,
            ),
          ],
          _SayLine(line: _line, kind: _say, dark: dark),
          const SizedBox(height: AppSpace.xs),
          if (_stepDone)
            GameButton(
              key: const ValueKey('easy-next'),
              label: _last ? _scene.finishLabel : (step.doneButton ?? 'NEXT'),
              arrow: true,
              singleLine: true,
              style: dark ? GameButtonStyle.gold : GameButtonStyle.navy,
              tap: TapRole.primary,
              onPressed: _last ? _finish : _advance,
            )
          else if (textOptions)
            _TextOptions(step: step, showAnswer: _showAnswer, dark: dark, onChoose: _choose)
          else if (step.does == EasyDo.next)
            GameButton(
              key: ValueKey('easy-button-${step.id}'),
              label: step.button,
              arrow: step.button == 'NEXT',
              singleLine: true,
              style: dark ? GameButtonStyle.gold : GameButtonStyle.navy,
              tap: TapRole.primary,
              onPressed: _complete,
            )
          else
            // Tap, rub, pick on the picture: the thing itself is the way on.
            const SizedBox(height: 56),
        ],
      ),
    );
  }

  /// A panel of the step, lit where it should be, its targets tappable
  /// ([done]: the step is done, nothing to tap).
  Widget _panelFor(EasyPanel panel, EasyStep step, Size size, {required bool done}) {
    final glows = <Rect?>[];
    final taps = <(Rect?, VoidCallback, String)>[];
    if (!done) {
      if (step.does == EasyDo.tap && (step.target?.panel ?? step.panels.firstOrNull?.id) == panel.id) {
        // The thing to tap is always lit (nothing is hidden); a large one
        // lights what to look at in it instead.
        if (step.lit.isEmpty) glows.add(step.target?.area);
        taps.add((step.target?.area, _tapTarget, step.say));
      }
      for (final m in step.lit) {
        if (m.panel == panel.id) glows.add(m.area);
      }
      if (_showLook) {
        for (final m in step.lookHere) {
          if (m.panel == panel.id) glows.add(m.area);
        }
      }
      if (step.does == EasyDo.choose && panel == step.panels.firstOrNull) {
        for (final o in step.options) {
          if (o.area == null) continue;
          taps.add((o.area, () => _choose(o.id), o.label ?? o.id));
          if (_showAnswer && o.id == step.answer) glows.add(o.area);
        }
      }
    }
    if (panel is RubPanel) {
      return _RubView(
        panel: panel,
        rubbed: _rubbed,
        done: done || step.does != EasyDo.rub,
        onRub: _rub,
      );
    }
    return EasyPanelView(panel: panel, glows: glows, taps: taps, strongGlow: _showAnswer);
  }
}

/// MISSION 01 · THE BIG BOOK, and the steps as dots (the one now filled).
class _Header extends StatelessWidget {
  const _Header({required this.eyebrow, required this.at, required this.of, required this.dark});

  final String eyebrow;
  final int at;
  final int of;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = dark ? AppColors.goldLight : AppColors.goldDeep;
    return Semantics(
      label: '$eyebrow. Step ${at + 1} of $of.',
      excludeSemantics: true,
      child: Row(
        children: [
          Expanded(
            child: Text(eyebrow, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.eyebrow(color: color)),
          ),
          for (var i = 0; i < of; i++)
            Container(
              key: ValueKey('easy-dot-$i'),
              margin: const EdgeInsets.only(left: 6),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= at ? color : Colors.transparent,
                border: Border.all(color: color, width: 1.5),
              ),
            ),
        ],
      ),
    );
  }
}

/// HINT: free, at any time, as often as wanted.
class _HintButton extends StatelessWidget {
  const _HintButton({super.key, required this.dark, required this.onTap});

  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = dark ? AppColors.goldLight : AppColors.goldDeep;
    return Semantics(
      button: true,
      label: 'Hint',
      excludeSemantics: true,
      child: Material(
        color: dark ? AppColors.navyDeep.withValues(alpha: 0.6) : AppColors.paperLight,
        shape: StadiumBorder(side: BorderSide(color: color, width: 1.5)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkIcon(InkGlyph.hint, size: AppIconSize.small, color: color),
                  const SizedBox(width: AppSpace.xs),
                  Text('HINT', style: AppText.button(size: 15, color: color)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The line said now: a hint (gold), a wrong answer's help (red), the step
/// done (green). Nothing: no room taken.
class _SayLine extends StatelessWidget {
  const _SayLine({required this.line, required this.kind, required this.dark});

  final String? line;
  final _Say? kind;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final line = this.line;
    final (bg, fg, glyph) = switch (kind) {
      _Say.done => (AppColors.successSoft, AppColors.success, InkGlyph.check),
      _Say.wrong => (AppColors.tryAgainSoft, AppColors.tryAgain, InkGlyph.search),
      _ => (AppColors.paperLight, AppColors.goldDeep, InkGlyph.hint),
    };
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: line == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: AppSpace.sm),
              child: Semantics(
                liveRegion: true,
                child: Container(
                  key: ValueKey('easy-line-${kind?.name}'),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(AppRadius.paper),
                    border: Border.all(color: fg.withValues(alpha: 0.5), width: AppLine.hairline),
                  ),
                  child: Row(
                    children: [
                      InkIcon(glyph, size: AppIconSize.small, color: fg),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: GlossaryText(line, style: AppText.bodyText(size: 18, weight: FontWeight.w600, color: AppColors.ink)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// Two (or three) answers in words, side by side, large.
class _TextOptions extends StatelessWidget {
  const _TextOptions({required this.step, required this.showAnswer, required this.dark, required this.onChoose});

  final EasyStep step;
  final bool showAnswer;
  final bool dark;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) {
    final long = step.options.any((o) => (o.label ?? '').length > 12);
    final buttons = [
      for (final o in step.options)
        _AnswerButton(
          key: ValueKey('easy-option-${o.id}'),
          label: o.label ?? o.id,
          lit: showAnswer && o.id == step.answer,
          dark: dark,
          onTap: () => onChoose(o.id),
        ),
    ];
    if (long) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final b in buttons) ...[b, if (b != buttons.last) const SizedBox(height: AppSpace.sm)],
        ],
      );
    }
    return Row(
      children: [
        for (final b in buttons) ...[Expanded(child: b), if (b != buttons.last) const SizedBox(width: AppSpace.md)],
      ],
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({super.key, required this.label, required this.lit, required this.dark, required this.onTap});

  final String label;
  final bool lit;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final edge = lit ? AppColors.gold : (dark ? AppColors.goldLight.withValues(alpha: 0.7) : AppColors.navy);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.button),
          boxShadow: lit ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.7), blurRadius: 16, spreadRadius: 2)] : AppShadow.paperLift,
        ),
        child: Material(
          color: AppColors.paperLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            side: BorderSide(color: edge, width: lit ? 3 : 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.button),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppText.title(size: 21, color: AppColors.navy),
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

/// A choice of pictures: what to match on top ([reference]: the step's
/// panels), the answers under it as large cards, each its label.
class _ChoiceCards extends StatelessWidget {
  const _ChoiceCards({
    required this.reference,
    required this.step,
    required this.showAnswer,
    required this.showLook,
    required this.dark,
    required this.onChoose,
  });

  final List<EasyPanel> reference;
  final EasyStep step;
  final bool showAnswer;
  final bool showLook;
  final bool dark;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) {
    final options = [for (final o in step.options) if (o.panel != null) o];
    final refs = reference;
    Widget panel(EasyPanel p, Size size) => EasyPanelView(
      panel: p,
      glows: [
        if (showLook)
          for (final m in step.lookHere)
            if (m.panel == p.id) m.area,
      ],
    );
    // Wide pictures (a name on its line) one over the other, full width;
    // others side by side.
    final wide = options.every((o) => o.panel!.aspect > 1.6);
    final cards = [
      for (final o in options)
        Expanded(
          child: _PictureCard(
            key: ValueKey('easy-option-${o.id}'),
            option: o,
            lit: showAnswer && o.id == step.answer,
            dark: dark,
            onTap: () => onChoose(o.id),
          ),
        ),
    ];
    final gap = wide ? const SizedBox(height: AppSpace.sm) : const SizedBox(width: AppSpace.md);
    final spaced = [
      for (final c in cards) ...[c, if (c != cards.last) gap],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (refs.isNotEmpty) Expanded(flex: 4, child: _Panels(panels: refs, dark: dark, builder: panel)),
        if (refs.isNotEmpty) const SizedBox(height: AppSpace.sm),
        Expanded(
          flex: wide ? 6 : 5,
          child: wide
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: spaced)
              : Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: spaced),
        ),
      ],
    );
  }
}

class _PictureCard extends StatelessWidget {
  const _PictureCard({super.key, required this.option, required this.lit, required this.dark, required this.onTap});

  final EasyOption option;
  final bool lit;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final panel = option.panel!;
    return Semantics(
      button: true,
      label: option.label ?? option.id,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: AppColors.paperLight,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: lit ? AppColors.gold : AppColors.navy.withValues(alpha: 0.6), width: lit ? 4 : 2),
          boxShadow: lit ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.7), blurRadius: 18, spreadRadius: 2)] : AppShadow.paperLift,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.button),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.sm),
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) => Center(
                        child: _Fitted(aspect: panel.aspect, box: box, child: EasyPanelView(panel: panel)),
                      ),
                    ),
                  ),
                  if (option.label case final label?) ...[
                    const SizedBox(height: AppSpace.xs),
                    Text(label, textAlign: TextAlign.center, maxLines: 2, style: AppText.title(size: 17, color: AppColors.navy)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A box of [aspect] as large as [box] allows.
class _Fitted extends StatelessWidget {
  const _Fitted({required this.aspect, required this.box, required this.child});

  final double aspect;
  final BoxConstraints box;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    var w = box.maxWidth;
    var h = w / aspect;
    if (h > box.maxHeight) {
      h = box.maxHeight;
      w = h * aspect;
    }
    return SizedBox(width: w, height: h, child: child);
  }
}

/// The step's panels, laid side by side or one over the other, whichever
/// shows them larger; each as large as it can be, its caption under it.
class _Panels extends StatelessWidget {
  const _Panels({required this.panels, required this.dark, required this.builder});

  final List<EasyPanel> panels;
  final bool dark;
  final Widget Function(EasyPanel panel, Size size) builder;

  static const _gap = AppSpace.md;
  static const _caption = 26.0;
  static const _caption2 = 44.0;

  @override
  Widget build(BuildContext context) {
    if (panels.isEmpty) return const SizedBox.shrink();
    final captions = panels.any((p) => p.caption != null);
    return LayoutBuilder(
      builder: (context, box) {
        final n = panels.length;
        // A long caption takes two lines under a narrow panel.
        final twoLines = panels.any((p) => (p.caption ?? '').length > 18) && n > 1;
        final cap = captions ? (twoLines ? _caption2 : _caption) * MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3).scale(1) : 0.0;
        // Side by side.
        final rowW = (box.maxWidth - _gap * (n - 1)) / n;
        final rowSizes = [
          for (final p in panels) _fit(p.aspect, rowW, box.maxHeight - cap),
        ];
        // One over the other.
        final colH = (box.maxHeight - (_gap + cap) * n + _gap) / n;
        final colSizes = [
          for (final p in panels) _fit(p.aspect, box.maxWidth, colH),
        ];
        double smallest(List<Size> s) => s.map((z) => z.width * z.height).reduce(math.min);
        final row = n == 1 || smallest(rowSizes) >= smallest(colSizes);
        final sizes = row ? rowSizes : colSizes;
        final children = [
          for (var i = 0; i < n; i++)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.fromSize(
                  size: sizes[i],
                  child: KeyedSubtree(key: ValueKey('easy-panel-${panels[i].id}'), child: builder(panels[i], sizes[i])),
                ),
                if (captions)
                  SizedBox(
                    height: cap,
                    width: n == 1 ? math.max(sizes[i].width, math.min(box.maxWidth, 240)) : sizes[i].width,
                    child: panels[i].caption == null
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: twoLines ? math.max(sizes[i].width, 110) : double.infinity),
                                child: Text(
                                  panels[i].caption!,
                                  textAlign: TextAlign.center,
                                  maxLines: twoLines ? 2 : 1,
                                  // One line: made smaller to fit, never cut.
                                  softWrap: twoLines,
                                  style: AppText.bodyText(
                                    size: 15,
                                    weight: FontWeight.w700,
                                    color: dark ? AppColors.goldLight : AppColors.inkBrown,
                                  ).copyWith(height: 1.15),
                                ),
                              ),
                            ),
                          ),
                  ),
              ],
            ),
        ];
        return Center(
          child: row
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (final c in children) ...[c, if (c != children.last) const SizedBox(width: _gap)],
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final c in children) ...[c, if (c != children.last) const SizedBox(height: _gap)],
                  ],
                ),
        );
      },
    );
  }

  static Size _fit(double aspect, double w, double h) {
    if (w <= 0 || h <= 0) return Size.zero;
    var width = w;
    var height = w / aspect;
    if (height > h) {
      height = h;
      width = h * aspect;
    }
    return Size(width, height);
  }
}

/// One panel drawn: a picture with its words and pictures laid on it, a
/// paper, a piece of evidence, someone's words, the gear mark, the machine.
/// [glows]: places lit (null: all of it); [taps]: places that can be tapped
/// (null: all of it), each with what it is, for screen readers.
class EasyPanelView extends ConsumerWidget {
  const EasyPanelView({super.key, required this.panel, this.glows = const [], this.taps = const [], this.strongGlow = false});

  final EasyPanel panel;
  final List<Rect?> glows;
  final List<(Rect?, VoidCallback, String)> taps;
  final bool strongGlow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = panel;
    final Widget body = switch (p) {
      PicturePanel() => _PictureView(panel: p, glows: glows, taps: taps, strongGlow: strongGlow),
      MachinePanel() => _MachineView(panel: p, glows: glows, taps: taps, strongGlow: strongGlow),
      PaperPanel() => _PaperView(panel: p),
      QuotePanel() => _QuoteView(panel: p),
      GearMarkPanel() => _GearMarkView(panel: p),
      EvidencePanel() => _EvidenceView(evidence: _evidenceOf(ref, p.evidenceId)),
      DrawnPanel(:final drawn, :final crop, :final pixels) => crop == null || pixels == null
          ? DrawnEvidenceView(drawn: drawn)
          : PixelCrop(pixels: pixels, crop: crop, child: DrawnEvidenceView(drawn: drawn)),
      RubPanel() => _RubView(panel: p, rubbed: const {}, done: true, onRub: (_) {}),
    };
    // A paper, a quote or evidence lit as a whole, or tapped as a whole.
    final whole = p is! PicturePanel && p is! MachinePanel;
    Widget out = body;
    if (whole && glows.isNotEmpty) out = _GlowFrame(strong: strongGlow, child: out);
    if (whole && taps.isNotEmpty) {
      final (_, onTap, label) = taps.first;
      out = Semantics(button: true, label: label, child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: out));
    }
    return out;
  }

  static Evidence? _evidenceOf(WidgetRef ref, String id) {
    for (final e in ref.read(playedEpisodesProvider)) {
      for (final v in e.allEvidence) {
        if (v.id == id) return v;
      }
    }
    return null;
  }
}

/// A part of a picture's pixels ([view]) drawn to the size given, and the
/// things laid on it at their places in the same pixels.
class _PixelStage extends StatelessWidget {
  const _PixelStage({required this.view, required this.layers});

  final Rect view;
  final List<_At> layers;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final s = box.maxWidth / view.width;
        return ClipRect(
          child: MediaQuery.withNoTextScaling(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (final l in layers)
                  Positioned(
                    left: (l.rect.left - view.left) * s,
                    top: (l.rect.top - view.top) * s,
                    width: l.rect.width * s,
                    height: l.rect.height * s,
                    child: l.build(s),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A thing on a [_PixelStage]: where (pixels), and how it is drawn at the
/// stage's scale.
class _At {
  const _At(this.rect, this.build);

  final Rect rect;
  final Widget Function(double scale) build;
}

TextStyle _inkStyle(EasyInk ink, double size) => switch (ink) {
  EasyInk.pen => AppText.letter(size: size, color: AppColors.ink).copyWith(height: 1.1),
  EasyInk.typed => AppText.bodyText(size: size, weight: FontWeight.w700, color: AppColors.navy).copyWith(height: 1.1),
  EasyInk.graphite => AppText.letter(size: size, color: const Color(0xFF55524D)).copyWith(height: 1.1),
  EasyInk.brass => AppText.mark(size: size, color: AppColors.goldLight).copyWith(height: 1.1),
};

/// Words on a picture, fitted into their place (backwards when blotted).
Widget _writing(EasyWriting w, double s, {double opacity = 1}) {
  Widget text = Text(
    w.text,
    maxLines: 1,
    style: _inkStyle(w.ink, w.size * s).copyWith(
      decoration: w.strong ? TextDecoration.underline : null,
      decorationColor: AppColors.burgundy,
      decorationThickness: 2,
    ),
  );
  if (w.mirrored) text = Transform.flip(flipX: true, child: text);
  return Opacity(
    opacity: opacity,
    child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center, child: text),
  );
}

/// A picture laid on another (in grey when it is a rubbing).
Widget _layer(EasyLayer l, {double opacity = 1}) {
  Widget image = Image.asset(l.file, fit: BoxFit.contain, excludeFromSemantics: true, errorBuilder: (_, _, _) => const SizedBox.shrink());
  if (l.graphite) {
    image = ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.2, 0.2, 0.2, 0, 70, //
        0.2, 0.2, 0.2, 0, 68,
        0.2, 0.2, 0.2, 0, 64,
        0, 0, 0, 1, 0,
      ]),
      child: image,
    );
  }
  if (l.turns != 0) image = Transform.rotate(angle: l.turns * 2 * math.pi, child: image);
  return Opacity(opacity: (l.opacity * opacity).clamp(0.0, 1.0), child: image);
}

class _PictureView extends StatelessWidget {
  const _PictureView({required this.panel, required this.glows, required this.taps, required this.strongGlow});

  final PicturePanel panel;
  final List<Rect?> glows;
  final List<(Rect?, VoidCallback, String)> taps;
  final bool strongGlow;

  @override
  Widget build(BuildContext context) {
    final pic = panel.picture;
    final whole = Rect.fromLTWH(0, 0, pic.pixels.width, pic.pixels.height);
    return Semantics(
      image: true,
      label: [pic.label, for (final w in panel.writing) w.text].join('. '),
      child: _PixelStage(
        view: pic.view,
        layers: [
          _At(whole, (_) => Image.asset(pic.file, fit: BoxFit.fill, excludeFromSemantics: true, gaplessPlayback: true)),
          for (final l in panel.layers) _At(l.at, (_) => _layer(l)),
          for (final w in panel.writing) _At(w.at, (s) => _writing(w, s)),
          for (final g in glows) _At(g ?? pic.view, (s) => _Glow(strong: strongGlow, scale: s)),
          for (final (area, onTap, label) in taps)
            _At(
              area ?? pic.view,
              (_) => Semantics(
                button: true,
                label: label,
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap),
              ),
            ),
        ],
      ),
    );
  }
}

/// A soft gold ring that breathes round a place to look at or tap (still,
/// when animations are off).
class _Glow extends StatefulWidget {
  const _Glow({required this.strong, required this.scale});

  final bool strong;
  final double scale;

  @override
  State<_Glow> createState() => _GlowState();
}

class _GlowState extends State<_Glow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c
        ..stop()
        ..value = 1;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(painter: _GlowPainter(t: _c.value, strong: widget.strong)),
    ),
  );
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter({required this.t, required this.strong});

  final double t;
  final bool strong;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(math.min(size.shortestSide * 0.12, 18)));
    final width = strong ? 5.0 : 3.5;
    canvas.drawRRect(
      r,
      Paint()
        ..color = AppColors.goldLight.withValues(alpha: 0.35 + 0.35 * t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      r,
      Paint()
        ..color = (strong ? AppColors.gold : AppColors.goldLight).withValues(alpha: 0.75 + 0.25 * t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.t != t || old.strong != strong;
}

/// A whole thing lit (a paper, a card).
class _GlowFrame extends StatelessWidget {
  const _GlowFrame({required this.strong, required this.child});

  final bool strong;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      child,
      Positioned.fill(child: _Glow(strong: strong, scale: 1)),
    ],
  );
}

/// A paper written by the app: its title, its lines (the strong ones
/// larger, underlined), a stamp or picture at its foot.
class _PaperView extends StatelessWidget {
  const _PaperView({required this.panel});

  final PaperPanel panel;

  static const _width = 420.0;

  @override
  Widget build(BuildContext context) {
    final p = panel;
    final paper = p.old ? const Color(0xFFEBDDB8) : AppColors.paperLight;
    final edge = p.old ? const Color(0xFFB99A62) : AppColors.royalBlue;
    return Semantics(
      label: [p.title, for (final l in p.lines) l.text, ?p.footLabel].join('. '),
      excludeSemantics: true,
      child: FittedBox(
        child: MediaQuery.withNoTextScaling(
          child: Container(
            width: _width,
            height: _width / p.aspect,
            padding: const EdgeInsets.fromLTRB(26, 22, 26, 18),
            decoration: BoxDecoration(
              color: paper,
              gradient: p.old
                  ? const RadialGradient(colors: [Color(0xFFF1E5C6), Color(0xFFE2CF9F)], radius: 1.1)
                  : null,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: edge, width: 2),
              boxShadow: AppShadow.paperLift,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  p.title,
                  textAlign: TextAlign.center,
                  style: AppText.mark(size: 19, color: p.old ? AppColors.inkBrown : AppColors.navy),
                ),
                const SizedBox(height: 6),
                Container(height: 1.5, color: edge.withValues(alpha: 0.6)),
                const SizedBox(height: 10),
                // The lines as large as the paper allows (never past it).
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: _width - 52,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final l in p.lines)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Text(
                                l.text,
                                style: AppText.letter(size: l.strong ? 27 : 23, color: AppColors.ink).copyWith(
                                  height: 1.2,
                                  fontWeight: l.strong ? FontWeight.w700 : FontWeight.w500,
                                  decoration: l.strong ? TextDecoration.underline : null,
                                  decorationColor: AppColors.burgundy,
                                  decorationThickness: 2,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (p.foot case final foot?)
                  SizedBox(
                    height: math.min(96, _width / p.aspect * 0.28),
                    child: Image.asset(foot, fit: BoxFit.contain, excludeFromSemantics: true, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Someone's words: their face, their name, the line in quotes.
class _QuoteView extends StatelessWidget {
  const _QuoteView({required this.panel});

  final QuotePanel panel;

  @override
  Widget build(BuildContext context) {
    final p = panel;
    return Semantics(
      label: '${p.name}: ${p.quote}',
      excludeSemantics: true,
      child: FittedBox(
        child: MediaQuery.withNoTextScaling(
          child: Container(
            width: 480,
            height: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.paperLight,
              borderRadius: BorderRadius.circular(AppRadius.paper),
              border: Border.all(color: AppColors.inkBrown.withValues(alpha: 0.5), width: 2),
              boxShadow: AppShadow.paperLift,
            ),
            child: Row(
              children: [
                if (p.portrait case final face?) ...[
                  ClipOval(
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: Image.asset(face, fit: BoxFit.cover, alignment: const Alignment(0, -0.7), excludeFromSemantics: true),
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: p.portrait == null ? 440 : 280,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name.toUpperCase(), style: AppText.mark(size: 18, color: AppColors.goldDeep)),
                          const SizedBox(height: 10),
                          Text('"${p.quote}"', style: AppText.letter(size: 30, color: AppColors.ink).copyWith(height: 1.25)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The Clockmaker's mark: Case 01's eight-toothed gear, in violet-black
/// ink, on a small card; or the card still blank.
class _GearMarkView extends StatelessWidget {
  const _GearMarkView({required this.panel});

  final GearMarkPanel panel;

  @override
  Widget build(BuildContext context) {
    final p = panel;
    return Semantics(
      label: p.stamped ? '${p.label}: a gear with eight teeth' : '${p.label}: blank',
      excludeSemantics: true,
      child: FittedBox(
        child: MediaQuery.withNoTextScaling(
          child: Container(
            width: 300,
            height: 300 / p.aspect,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.paperLight,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: AppColors.inkBrown.withValues(alpha: 0.45), width: 2),
              boxShadow: AppShadow.paperLift,
            ),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, a) => ScaleTransition(scale: Tween(begin: 1.25, end: 1.0).animate(a), child: FadeTransition(opacity: a, child: child)),
                      child: p.stamped
                          ? const InkIcon(InkGlyph.gear, key: ValueKey('gear-mark'), size: 190, color: Color(0xFF3B2340))
                          : const SizedBox(key: ValueKey('gear-blank'), width: 190, height: 190),
                    ),
                  ),
                ),
                if (p.label.isNotEmpty)
                  Text(p.label, textAlign: TextAlign.center, style: AppText.title(size: 22, color: AppColors.navy)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A piece of evidence as the notebook draws it, and its name.
class _EvidenceView extends StatelessWidget {
  const _EvidenceView({required this.evidence});

  final Evidence? evidence;

  @override
  Widget build(BuildContext context) {
    final e = evidence;
    if (e == null) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, box) => Container(
        padding: const EdgeInsets.all(AppSpace.sm),
        decoration: BoxDecoration(
          color: AppColors.paperLight,
          borderRadius: BorderRadius.circular(AppRadius.paper),
          border: Border.all(color: AppLine.faint(0.25), width: AppLine.hairline),
          boxShadow: AppShadow.paperLift,
        ),
        child: Column(
          children: [
            Expanded(child: EvidencePicture(evidence: e, maxHeight: math.max(56, box.maxHeight - 72))),
            const SizedBox(height: AppSpace.xs),
            Text(e.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: AppText.title(size: 15, color: AppColors.navy).copyWith(height: 1.1)),
          ],
        ),
      ),
    );
  }
}

/// The page rubbed with a finger (Case 11 M1): where it is rubbed goes grey,
/// and the words pressed into it come out; once enough is rubbed, all of
/// them. A tap rubs a patch, so a finger that cannot drag gets there too.
class _RubView extends StatefulWidget {
  const _RubView({required this.panel, required this.rubbed, required this.done, required this.onRub});

  final RubPanel panel;
  final Set<int> rubbed;
  final bool done;
  final ValueChanged<Iterable<int>> onRub;

  static const columns = 10;
  static const rows = 4;

  /// A quarter of the page rubbed is enough.
  static const enough = 0.25;

  @override
  State<_RubView> createState() => _RubViewState();
}

class _RubViewState extends State<_RubView> with SingleTickerProviderStateMixin {
  late final AnimationController _pencil = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) || widget.done) {
      _pencil.stop();
    } else if (!_pencil.isAnimating) {
      _pencil.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _RubView old) {
    super.didUpdateWidget(old);
    if (widget.done || widget.rubbed.isNotEmpty) _pencil.stop();
  }

  @override
  void dispose() {
    _pencil.dispose();
    super.dispose();
  }

  /// The cell under [local] (a point on the rubbed area, [size] its size),
  /// or null off it.
  int? _cellAt(Offset local, Size size) {
    if (local.dx < 0 || local.dy < 0 || local.dx > size.width || local.dy > size.height) return null;
    final c = (local.dx / size.width * _RubView.columns).floor().clamp(0, _RubView.columns - 1);
    final r = (local.dy / size.height * _RubView.rows).floor().clamp(0, _RubView.rows - 1);
    return r * _RubView.columns + c;
  }

  Iterable<int> _around(int cell, int reach) sync* {
    final c = cell % _RubView.columns;
    final r = cell ~/ _RubView.columns;
    for (var dr = -reach; dr <= reach; dr++) {
      for (var dc = -reach; dc <= reach; dc++) {
        final rr = r + dr;
        final cc = c + dc;
        if (rr >= 0 && rr < _RubView.rows && cc >= 0 && cc < _RubView.columns) yield rr * _RubView.columns + cc;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.panel;
    final book = p.book;
    final whole = Rect.fromLTWH(0, 0, book.pixels.width, book.pixels.height);
    final coverage = widget.rubbed.length / (_RubView.columns * _RubView.rows);
    final shown = widget.done ? 1.0 : (coverage / _RubView.enough).clamp(0.0, 1.0) * 0.85;
    return Semantics(
      label: '${book.label}. ${widget.done ? [for (final l in p.lines) l.text].join(' ') : 'Rub the page.'}',
      child: _PixelStage(
        view: book.view,
        layers: [
          _At(whole, (_) => Image.asset(book.file, fit: BoxFit.fill, excludeFromSemantics: true)),
          // The pencil's grey where it rubbed (all of it once done).
          _At(
            p.area,
            (_) => CustomPaint(painter: _RubPainter(rubbed: widget.rubbed, all: widget.done)),
          ),
          for (final l in p.lines) _At(l.at, (s) => _writing(l, s, opacity: shown)),
          if (p.signature case final sig?) _At(sig.at, (_) => _layer(sig, opacity: shown)),
          if (!widget.done) ...[
            _At(p.area, (s) => _Glow(strong: false, scale: s)),
            _At(
              p.area,
              (s) => LayoutBuilder(
                builder: (context, box) => Semantics(
                  button: true,
                  label: 'Rub the page',
                  child: GestureDetector(
                    key: const ValueKey('easy-rub'),
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) {
                      final cell = _cellAt(d.localPosition, box.biggest);
                      if (cell != null) widget.onRub(_around(cell, 1));
                    },
                    onPanUpdate: (d) {
                      final cell = _cellAt(d.localPosition, box.biggest);
                      if (cell != null) widget.onRub(_around(cell, 0).followedBy(_around(cell, 0).map((c) => c % _RubView.columns == _RubView.columns - 1 ? c : c + 1)));
                    },
                    child: widget.rubbed.isEmpty
                        // A pencil that shows the rubbing, until it starts.
                        ? AnimatedBuilder(
                            animation: _pencil,
                            builder: (context, _) => Align(
                              alignment: Alignment(-0.7 + 1.4 * _pencil.value, 0.1),
                              child: InkIcon(InkGlyph.pen, size: math.max(28, box.maxHeight * 0.3), color: AppColors.inkBrown),
                            ),
                          )
                        : const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RubPainter extends CustomPainter {
  const _RubPainter({required this.rubbed, required this.all});

  final Set<int> rubbed;
  final bool all;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / _RubView.columns;
    final ch = size.height / _RubView.rows;
    final paint = Paint()
      ..color = const Color(0xFF6B6760).withValues(alpha: 0.18)
      ..strokeWidth = math.max(1, ch * 0.05)
      ..strokeCap = StrokeCap.round;
    for (var cell = 0; cell < _RubView.columns * _RubView.rows; cell++) {
      if (!all && !rubbed.contains(cell)) continue;
      final x = (cell % _RubView.columns) * cw;
      final y = (cell ~/ _RubView.columns) * ch;
      // Slanted pencil strokes, close together.
      for (var i = -2; i < 8; i++) {
        final sx = x + i * cw / 6;
        canvas.drawLine(Offset(sx, y + ch), Offset(sx + cw / 2.5, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_RubPainter old) => old.rubbed.length != rubbed.length || old.all != all;
}

/// The old machine at its repair step: the big wheel in its recess (turned
/// one hour on once it is turned), the time in its window, the lever (down
/// while stopped), the pin (in once pushed), its three little clocks, and
/// the wall clock above, to match.
class _MachineView extends StatelessWidget {
  const _MachineView({required this.panel, required this.glows, required this.taps, required this.strongGlow});

  final MachinePanel panel;
  final List<Rect?> glows;
  final List<(Rect?, VoidCallback, String)> taps;
  final bool strongGlow;

  static const _ease = Duration(milliseconds: 900);

  @override
  Widget build(BuildContext context) {
    final m = panel.scene;
    final state = panel.state;
    final still = MediaQuery.disableAnimationsOf(context);
    final ease = still ? Duration.zero : _ease;
    final turned = state.index >= MachineState.turned.index;
    final pinned = state.index >= MachineState.pinned.index;
    final leverDown = state == MachineState.stopped || state == MachineState.turned || state == MachineState.pinned;
    final minutes = turned ? m.right : m.wrong;
    final pic = m.machine;
    final whole = Rect.fromLTWH(0, 0, pic.pixels.width, pic.pixels.height);
    final r = m.dialRadius;
    final wall = Rect.fromCenter(center: Offset(pic.view.right - 150, pic.view.top + 140), width: 250, height: 250);
    final wallLabel = Rect.fromLTRB(wall.left - 330, wall.center.dy - 40, wall.left - 20, wall.center.dy + 40);
    final hub = Alignment(m.wheelHub.dx / m.wheelPixels.width * 2 - 1, m.wheelHub.dy / m.wheelPixels.height * 2 - 1);
    final time = MachineScene.timeOf(minutes);
    return Semantics(
      label: '${pic.label}. Its clocks say $time. The wall clock says ${MachineScene.timeOf(m.right)}. '
          '${switch (state) {
            MachineState.running => 'It is running.',
            MachineState.stopped => 'It is stopped.',
            MachineState.turned => 'The wheel is turned.',
            MachineState.pinned => 'The pin is in.',
            MachineState.fixed => 'It is running again.',
          }}',
      child: _PixelStage(
        view: pic.view,
        layers: [
          _At(whole, (_) => Image.asset(pic.file, fit: BoxFit.fill, excludeFromSemantics: true)),
          // The time in the window under the wheel.
          _At(
            m.window,
            (s) => Center(
              child: AnimatedSwitcher(
                duration: ease,
                child: Text(time, key: ValueKey('machine-window-$time'), style: AppText.mark(size: 40 * s, color: AppColors.goldLight)),
              ),
            ),
          ),
          for (final c in m.dials)
            _At(
              Rect.fromCircle(center: c, radius: r),
              (_) => TweenAnimationBuilder<double>(
                tween: Tween(end: minutes.toDouble()),
                duration: ease,
                curve: Curves.easeInOutCubic,
                builder: (context, t, _) => CustomPaint(painter: _HandsPainter(minutes: t)),
              ),
            ),
          _At(
            m.wheelAt,
            (_) => AnimatedRotation(
              key: const ValueKey('machine-wheel'),
              turns: turned ? 1 / 12 : 0,
              alignment: hub,
              duration: ease,
              curve: Curves.easeInOutCubic,
              child: Image.asset(m.wheel, fit: BoxFit.fill, excludeFromSemantics: true),
            ),
          ),
          _At(
            m.leverAt,
            (_) => AnimatedRotation(
              key: const ValueKey('machine-lever'),
              turns: leverDown ? -0.09 : 0,
              alignment: const Alignment(0, 0.8),
              duration: ease,
              curve: Curves.easeInOutCubic,
              child: Image.asset(m.lever, fit: BoxFit.fill, excludeFromSemantics: true),
            ),
          ),
          _At(
            Rect.fromLTRB(
              math.min(m.pinOut.left, m.pinIn.left),
              math.min(m.pinOut.top, m.pinIn.top),
              math.max(m.pinOut.right, m.pinIn.right),
              math.max(m.pinOut.bottom, m.pinIn.bottom),
            ),
            (s) => TweenAnimationBuilder<double>(
              tween: Tween(end: pinned ? 1 : 0),
              duration: ease,
              curve: Curves.easeInOutCubic,
              builder: (context, t, child) {
                final box = Rect.lerp(m.pinOut, m.pinIn, t)!;
                final origin = Offset(math.min(m.pinOut.left, m.pinIn.left), math.min(m.pinOut.top, m.pinIn.top));
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: (box.left - origin.dx) * s,
                      top: (box.top - origin.dy) * s,
                      width: box.width * s,
                      height: box.height * s,
                      child: child!,
                    ),
                  ],
                );
              },
              child: Image.asset(m.pin, key: const ValueKey('machine-pin'), fit: BoxFit.fill, excludeFromSemantics: true),
            ),
          ),
          // The wall clock: the time to match.
          _At(wall, (_) => Image.asset(m.wallDial, fit: BoxFit.fill, excludeFromSemantics: true)),
          _At(wall, (_) => CustomPaint(painter: _HandsPainter(minutes: m.right.toDouble(), pivot: Offset(m.wallDialPivot.dx / m.wallDialPixels.width, m.wallDialPivot.dy / m.wallDialPixels.height), radius: 0.36))),
          _At(
            wallLabel,
            (s) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text('WALL CLOCK', style: AppText.mark(size: 46 * s, color: AppColors.goldDeep)),
            ),
          ),
          for (final g in glows) _At(g ?? pic.view, (s) => _Glow(strong: strongGlow, scale: s)),
          for (final (area, onTap, label) in taps)
            _At(
              area ?? pic.view,
              (_) => Semantics(button: true, label: label, child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap)),
            ),
        ],
      ),
    );
  }
}

/// A clock's two hands at [minutes] (after twelve), on a dial filling the
/// box ([pivot]: where they turn, as fractions; [radius]: the face's, as a
/// fraction of the box's width).
class _HandsPainter extends CustomPainter {
  const _HandsPainter({required this.minutes, this.pivot = const Offset(0.5, 0.5), this.radius = 0.5});

  final double minutes;
  final Offset pivot;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(pivot.dx * size.width, pivot.dy * size.height);
    final r = radius * size.width;
    final hour = (minutes / 720) * 360;
    final minute = (minutes % 60) / 60 * 360;
    ClockHandsPainter.paintHand(canvas, c, minute, length: r * 0.86, width: r * 0.07, tip: 1.1);
    ClockHandsPainter.paintHand(canvas, c, hour, length: r * 0.58, width: r * 0.11, tip: 1.6);
    ClockHandsPainter.paintCap(canvas, c, r * 0.09);
  }

  @override
  bool shouldRepaint(_HandsPainter old) => old.minutes != minutes;
}

/// Evidence of Cases 11–12 drawn as its panel (the notebook's picture).
class EasyEvidenceView extends StatelessWidget {
  const EasyEvidenceView({super.key, required this.art});

  final EasyEvidence art;

  @override
  Widget build(BuildContext context) => AspectRatio(aspectRatio: art.aspect, child: EasyPanelView(panel: art.panel));
}
