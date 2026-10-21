import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/mission.dart';
import '../../../data/models/river_puzzles.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import 'evidence_board.dart' show BrassPlaque;
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

  Future<void> _check() async {
    if (_checking || _choice == null) return;
    setState(() => _checking = true);
    try {
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
        const SizedBox(height: AppSpace.sm),
        Center(
          child: InkTextButton(
            key: const ValueKey('marks-plaque'),
            label: widget.read.contains(RiverMarksScene.backId) ? 'The brass plaque ✓' : 'The brass plaque',
            glyph: InkGlyph.search,
            onPressed: _plaque,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpace.sm,
          crossAxisSpacing: AppSpace.sm,
          childAspectRatio: 3.2,
          children: [
            for (final o in widget.mission.options)
              _MarkChoice(
                key: ValueKey('mark-${o.id}'),
                label: o.label,
                selected: _choice == o.id,
                onTap: () => setState(() => _choice = o.id),
              ),
          ],
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

/// A mark on the wall: a fine gold frame round it, its letter, a glass
/// until it is looked at, a tick after.
class _MarkSpot extends StatelessWidget {
  const _MarkSpot({super.key, required this.letter, required this.name, required this.looked, required this.onTap});

  final String letter;
  final String name;
  final bool looked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$name${looked ? ', looked at' : ''}. Tap to look closer.',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.goldLight.withValues(alpha: looked ? 0.45 : 0.9), width: AppLine.rule),
            borderRadius: BorderRadius.circular(AppRadius.paper),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: AppColors.navyDeep.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(3)),
                  child: Text(letter, style: AppText.style(AppText.body, size: 12, weight: FontWeight.w800, color: AppColors.goldLight)),
                ),
              ),
              Positioned(
                right: 2,
                top: 2,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: AppColors.navyDeep.withValues(alpha: 0.8),
                  child: InkIcon(looked ? InkGlyph.check : InkGlyph.search, size: 12, color: AppColors.goldLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarkChoice extends StatelessWidget {
  const _MarkChoice({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.navy : AppColors.paperLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          side: BorderSide(color: selected ? AppColors.navy : AppLine.faint(0.35), width: AppLine.hairline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.button),
          onTap: onTap,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                child: Text(label.toUpperCase(), style: AppText.button(size: 15, color: selected ? AppColors.paperLight : AppColors.navy)),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
                        child: Text(
                          mark.word,
                          textAlign: TextAlign.center,
                          style: AppText.title(size: 22, color: AppColors.goldLight).copyWith(letterSpacing: 2),
                        ),
                      ),
                      const SizedBox(height: AppSpace.lg),
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
                    child: Text(
                      _back ? s.plaqueBack.lines.join('\n') : '${s.plaqueFront.plaqueMessage}\nUnder the waves: ${s.plaqueFront.riverWord}',
                      key: const ValueKey('plaque-side-words'),
                      textAlign: TextAlign.center,
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
