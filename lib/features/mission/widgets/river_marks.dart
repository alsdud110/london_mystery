import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/answer_checker.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/mission.dart';
import '../../../data/models/river_puzzles.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/paper.dart';
import 'evidence_board.dart' show BrassPlaque;
import 'mark_compare.dart' show SpotMarks;
import 'river_papers.dart';

/// The quay wall ([RiverMarksScene]): four carved marks, each looked at
/// closer by a tap (kept looked at: [onRead]), the brass plaque's two sides
/// read again, and the mark chosen; THIS IS THE MARK sends it to
/// [onSubmit], checked as the puzzle's answer.
class RiverMarks extends StatefulWidget {
  const RiverMarks({
    super.key,
    required this.scene,
    required this.mission,
    required this.read,
    required this.onRead,
    required this.onSubmit,
  });

  final RiverMarksScene scene;
  final Mission mission;

  /// The marks (and the plaque's back) looked at so far.
  final Set<String> read;
  final ValueChanged<String> onRead;
  final Future<void> Function(String answer) onSubmit;

  @override
  State<RiverMarks> createState() => _RiverMarksState();
}

class _RiverMarksState extends State<RiverMarks> {
  String? _choice;
  bool _checking = false;

  RiverMarksScene get _scene => widget.scene;

  Future<void> _look(RiverMark mark) async {
    widget.onRead(mark.id);
    await showMarkCloser(context, scene: _scene, mark: mark);
  }

  Future<void> _plaque() async {
    widget.onRead(RiverMarksScene.backId);
    await showPlaqueSides(context, scene: _scene);
  }

  /// A mark tapped on the comparing cards: the one chosen (one at a time),
  /// and looked at.
  void _choose(RiverMark mark) {
    HapticFeedback.selectionClick();
    widget.onRead(mark.id);
    setState(() => _choice = mark.id);
  }

  Future<void> _check() async {
    if (_checking || _choice == null) return;
    setState(() => _checking = true);
    try {
      // The right mark: first, line by line, why it is the one (the wrong
      // ones go straight to the check, which says which line they break).
      if (AnswerChecker.isCorrect(widget.mission, _choice!)) {
        await showMarkFollows(context, scene: _scene, mark: _scene.mark(_choice!));
        if (!mounted) return;
      }
      await widget.onSubmit(_choice!);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookedAll = _scene.marks.every((m) => widget.read.contains(m.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          lookedAll ? _scene.chooseTask : _scene.readTask,
          key: const ValueKey('marks-task'),
          textAlign: TextAlign.center,
          style: AppText.subtitle(),
        ),
        const SizedBox(height: AppSpace.md),
        // What to check, always in view: the plaque's three lines, numbered.
        _PlaqueLines(
          lines: _scene.plaqueBack.lines,
          read: widget.read.contains(RiverMarksScene.backId),
          onPlaque: _plaque,
        ),
        const SizedBox(height: AppSpace.md),
        // The wall, its marks where they are carved.
        DecoratedBox(
          decoration: BoxDecoration(boxShadow: AppShadow.paperLift, borderRadius: BorderRadius.circular(AppRadius.paper)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.paper),
            child: AspectRatio(
              aspectRatio: _scene.pixels.aspect,
              child: LayoutBuilder(
                builder: (context, box) {
                  Rect at(Rect r) => Rect.fromLTRB(r.left * box.maxWidth, r.top * box.maxHeight, r.right * box.maxWidth, r.bottom * box.maxHeight);
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Semantics(
                          image: true,
                          label: _scene.place,
                          excludeSemantics: true,
                          child: Image.asset(_scene.wall, fit: BoxFit.fill, excludeFromSemantics: true),
                        ),
                      ),
                      // The enamel sign, and each mark's word, small as on
                      // the wall (read up close).
                      Positioned.fromRect(
                        rect: at(_scene.signAt),
                        child: ExcludeSemantics(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(_scene.sign, key: const ValueKey('wall-sign'), style: AppText.style(AppText.body, size: 14, weight: FontWeight.w800, color: AppColors.navyDeep, letterSpacing: 1.5)),
                            ),
                          ),
                        ),
                      ),
                      for (final m in _scene.marks)
                        Positioned.fromRect(
                          rect: at(m.wordAt),
                          child: ExcludeSemantics(
                            child: FittedBox(fit: BoxFit.scaleDown, child: Text(m.word, style: carved(10))),
                          ),
                        ),
                      for (final m in _scene.marks)
                        Positioned.fromRect(
                          rect: at(m.area).inflate(3),
                          child: _MarkSpot(
                            key: ValueKey('mark-spot-${m.id}'),
                            letter: m.id.toUpperCase(),
                            name: m.name,
                            looked: widget.read.contains(m.id),
                            chosen: _choice == m.id,
                            onTap: () => _look(m),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        // The four marks side by side, each large enough to count its
        // waves, see its arrow and read its word: a tap chooses it, the
        // glass looks closer.
        Text('THE FOUR MARKS', textAlign: TextAlign.center, style: AppText.eyebrow()),
        const SizedBox(height: AppSpace.sm),
        LayoutBuilder(
          builder: (context, box) {
            const gap = AppSpace.sm;
            final w = (box.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final m in _scene.marks)
                  SizedBox(
                    width: w,
                    child: _MarkCard(
                      key: ValueKey('mark-${m.id}'),
                      scene: _scene,
                      mark: m,
                      chosen: _choice == m.id,
                      onTap: () => _choose(m),
                      onCloser: () => _look(m),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpace.md),
        GameButton(
          key: const ValueKey('marks-check'),
          label: _scene.chooseLabel,
          glyph: InkGlyph.check,
          tap: TapRole.primary,
          onPressed: _choice != null && !_checking ? _check : null,
        ),
      ],
    );
  }
}

/// A mark on the wall: a fine gold frame round it, its letter and a glass
/// (never a tick: on this wall a tick would read as an answer). The one
/// chosen below is framed bold.
class _MarkSpot extends StatelessWidget {
  const _MarkSpot({super.key, required this.letter, required this.name, required this.looked, required this.chosen, required this.onTap});

  final String letter;
  final String name;
  final bool looked;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$name${chosen ? ', chosen' : looked ? ', looked at' : ''}. Tap to look closer.',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: chosen ? AppColors.goldLight : AppColors.goldLight.withValues(alpha: looked ? 0.45 : 0.9),
              width: chosen ? AppLine.ink * 1.5 : AppLine.rule,
            ),
            borderRadius: BorderRadius.circular(AppRadius.paper),
          ),
          child: SpotMarks(letter: letter, done: false),
        ),
      ),
    );
  }
}

/// The plaque's three lines, as scratched on its back, numbered: what each
/// mark is checked against (the wrong answers name a line by its number).
/// The plaque itself, both sides, a tap away.
class _PlaqueLines extends StatelessWidget {
  const _PlaqueLines({required this.lines, required this.read, required this.onPlaque});

  final List<String> lines;
  final bool read;
  final VoidCallback onPlaque;

  @override
  Widget build(BuildContext context) {
    return PaperSheet(
      key: const ValueKey('marks-lines'),
      padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.md, AppSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('THE BACK OF THE PLAQUE', textAlign: TextAlign.center, style: AppText.eyebrow()),
          const SizedBox(height: AppSpace.sm),
          for (final (i, line) in lines.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: Row(
                key: ValueKey('marks-line-${i + 1}'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LineNumber(i + 1),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(child: GlossaryText(line, style: AppText.bodyText(size: 17, weight: FontWeight.w600, color: AppColors.navy))),
                ],
              ),
            ),
          Center(
            child: InkTextButton(
              key: const ValueKey('marks-plaque'),
              label: 'See the plaque',
              glyph: read ? InkGlyph.check : InkGlyph.search,
              onPressed: onPlaque,
            ),
          ),
        ],
      ),
    );
  }
}

/// A line's number, in a small navy disc.
class _LineNumber extends StatelessWidget {
  const _LineNumber(this.n, {this.light = false});

  final int n;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: light ? AppColors.goldLight : AppColors.navy),
      child: Text('$n', style: AppText.button(size: 13, color: light ? AppColors.navyDeep : AppColors.goldLight)),
    );
  }
}

/// A mark on the comparing cards: its close-up (the waves, the arrow, the
/// word as carved) and its name. A tap chooses it: the one chosen is framed
/// in navy and named CHOSEN, the others plain. The glass looks closer.
class _MarkCard extends StatelessWidget {
  const _MarkCard({super.key, required this.scene, required this.mark, required this.chosen, required this.onTap, required this.onCloser});

  final RiverMarksScene scene;
  final RiverMark mark;
  final bool chosen;
  final VoidCallback onTap;
  final VoidCallback onCloser;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: chosen,
      label: '${mark.spoken}.${chosen ? ' Chosen.' : ' Tap to choose it.'}',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(AppSpace.xs),
          decoration: BoxDecoration(
            color: chosen ? AppColors.navy : AppColors.paperLight,
            borderRadius: BorderRadius.circular(AppRadius.paper),
            border: Border.all(color: chosen ? AppColors.gold : AppLine.faint(0.3), width: chosen ? AppLine.ink * 1.5 : AppLine.hairline),
            boxShadow: chosen ? AppShadow.paperLift : null,
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.paper),
                    child: RiverMarkView(scene: scene, mark: mark, wordKey: false),
                  ),
                  // The glass on the corner (a fingertip's 44 px).
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Semantics(
                      button: true,
                      label: 'Look closer at ${mark.name}',
                      child: GestureDetector(
                        key: ValueKey('mark-closer-${mark.id}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: onCloser,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.paperLight.withValues(alpha: 0.92),
                                border: Border.all(color: AppColors.gold, width: AppLine.rule),
                              ),
                              child: const InkIcon(InkGlyph.search, size: AppIconSize.tiny, color: AppColors.burgundy),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              SizedBox(
                height: 24,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      chosen ? '${mark.name} · CHOSEN' : mark.name,
                      key: ValueKey('mark-card-name-${mark.id}'),
                      maxLines: 1,
                      style: AppText.button(size: 15, color: chosen ? AppColors.goldLight : AppColors.navy),
                    ),
                  ),
                ),
              ),
              // Its carved word again, large enough to read (small on the
              // stone).
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  mark.word,
                  maxLines: 1,
                  style: AppText.bodyText(size: 14, weight: FontWeight.w600, color: chosen ? AppColors.paperLight : AppColors.inkBrown).copyWith(letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }
}

/// The right mark, checked line by line before the case goes on: each of
/// the plaque's lines, and how this mark follows it ([RiverMarksScene.
/// rightLines]). Shown only once the mark chosen is the right one.
Future<void> showMarkFollows(BuildContext context, {required RiverMarksScene scene, required RiverMark mark}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: false,
      barrierColor: AppColors.navyDeep.withValues(alpha: 0.98),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim, _) => FadeTransition(
        opacity: anim,
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    key: const ValueKey('marks-why'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${mark.name} FOLLOWS ALL THREE LINES',
                        textAlign: TextAlign.center,
                        style: AppText.mark(color: AppColors.goldLight),
                      ),
                      const SizedBox(height: AppSpace.md),
                      SizedBox(
                        width: 160,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.paper),
                          child: RiverMarkView(scene: scene, mark: mark, wordKey: false),
                        ),
                      ),
                      const SizedBox(height: AppSpace.lg),
                      for (final (i, line) in scene.plaqueBack.lines.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.md),
                          child: Row(
                            key: ValueKey('marks-why-${i + 1}'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _LineNumber(i + 1, light: true),
                              const SizedBox(width: AppSpace.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(line, style: AppText.bodyText(size: 15, color: AppColors.paperLight.withValues(alpha: 0.75))),
                                    const SizedBox(height: 2),
                                    Text(
                                      i < scene.rightLines.length ? scene.rightLines[i] : '',
                                      style: AppText.bodyText(size: 18, weight: FontWeight.w700, color: AppColors.goldLight),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpace.sm),
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: InkIcon(InkGlyph.check, size: AppIconSize.small, color: AppColors.success),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpace.sm),
                      Builder(
                        builder: (context) => GameButton(
                          key: const ValueKey('marks-why-continue'),
                          label: 'CONTINUE',
                          arrow: true,
                          style: GameButtonStyle.glass,
                          tap: TapRole.primary,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A mark looked at up close, its word large under it.
Future<void> showMarkCloser(BuildContext context, {required RiverMarksScene scene, required RiverMark mark}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: AppColors.navyDeep.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim, _) => FadeTransition(
        opacity: anim,
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(mark.name, key: const ValueKey('mark-close-title'), style: AppText.mark(color: AppColors.goldLight)),
                      const SizedBox(height: AppSpace.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.paper),
                        child: InteractiveViewer(maxScale: 3, child: RiverMarkView(key: ValueKey('mark-close-${mark.id}'), scene: scene, mark: mark)),
                      ),
                      const SizedBox(height: AppSpace.md),
                      ExcludeSemantics(
                        child: GlossaryText(
                          mark.word,
                          textAlign: TextAlign.center,
                          linkColor: AppColors.goldLight,
                          style: AppText.title(size: 22, color: AppColors.goldLight).copyWith(letterSpacing: 2),
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      // The three lines to check it with, beside it.
                      for (final (i, line) in scene.plaqueBack.lines.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.xs),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _LineNumber(i + 1, light: true),
                              const SizedBox(width: AppSpace.sm),
                              Expanded(child: Text(line, style: AppText.bodyText(size: 16, color: AppColors.paperLight))),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpace.md),
                      Builder(
                        builder: (context) => GameButton(
                          key: const ValueKey('mark-close-done'),
                          label: 'BACK TO THE WALL',
                          style: GameButtonStyle.glass,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The brass plaque from Case 03, either side up: its front (the message
/// and SEINE, as found) and its back (the three lines), each in large words
/// under it. It opens on the back.
Future<void> showPlaqueSides(BuildContext context, {required RiverMarksScene scene}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: AppColors.navyDeep.withValues(alpha: 0.94),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim, _) => FadeTransition(opacity: anim, child: _PlaqueSides(scene: scene)),
    ),
  );
}

class _PlaqueSides extends StatefulWidget {
  const _PlaqueSides({required this.scene});

  final RiverMarksScene scene;

  @override
  State<_PlaqueSides> createState() => _PlaqueSidesState();
}

class _PlaqueSidesState extends State<_PlaqueSides> {
  bool _back = true;

  @override
  Widget build(BuildContext context) {
    final s = widget.scene;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_back ? 'THE BACK OF THE PLAQUE' : 'THE FRONT OF THE PLAQUE', style: AppText.mark(color: AppColors.goldLight)),
                  const SizedBox(height: AppSpace.lg),
                  AnimatedSwitcher(
                    duration: still ? Duration.zero : const Duration(milliseconds: 300),
                    child: _back
                        ? PlaqueBackView(key: const ValueKey('plaque-back'), plaque: s.plaqueBack)
                        : BrassPlaque(key: const ValueKey('plaque-front'), scene: s.plaqueFront),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  // What the brass says, in words a child reads at once.
                  ExcludeSemantics(
                    child: GlossaryText(
                      _back ? s.plaqueBack.lines.join('\n') : '${s.plaqueFront.plaqueMessage}\nUnder the waves: ${s.plaqueFront.riverWord}',
                      key: const ValueKey('plaque-side-words'),
                      textAlign: TextAlign.center,
                      linkColor: AppColors.goldLight,
                      style: AppText.title(size: 21, color: AppColors.goldLight).copyWith(height: 1.4),
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  InkTextButton(
                    key: const ValueKey('plaque-turn'),
                    label: _back ? 'Turn it over: the front' : 'Turn it over: the back',
                    glyph: InkGlyph.search,
                    color: AppColors.goldLight,
                    onPressed: () => setState(() => _back = !_back),
                  ),
                  const SizedBox(height: AppSpace.md),
                  GameButton(
                    key: const ValueKey('plaque-sides-done'),
                    label: 'BACK TO THE WALL',
                    style: GameButtonStyle.glass,
                    onPressed: () => Navigator.of(context).pop(),
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
