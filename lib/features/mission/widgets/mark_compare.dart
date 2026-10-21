import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/mission.dart';
import '../../../data/models/workshop_puzzles.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import 'workshop_papers.dart';

/// The stamps' ink on the bench, and the tracing sheet's.
final _stampInk = AppColors.walnutDeep.withValues(alpha: 0.92);
final _sheetInk = AppColors.royalBlue.withValues(alpha: 0.9);

/// The workbench ([MarkCompareScene]): the maker's note, four stamped things
/// (each looked at closer by a tap, the tracing sheet laid over it there:
/// kept as compared, [onCompared]), and the thing chosen; THIS IS THE MARK
/// sends it to [onSubmit], checked as the puzzle's answer.
class MarkCompare extends StatefulWidget {
  const MarkCompare({super.key, required this.scene, required this.mission, required this.compared, required this.onCompared, required this.onSubmit});

  final MarkCompareScene scene;
  final Mission mission;

  /// The stamps the sheet was laid on so far.
  final Set<String> compared;
  final ValueChanged<String> onCompared;
  final Future<void> Function(String answer) onSubmit;

  @override
  State<MarkCompare> createState() => _MarkCompareState();
}

class _MarkCompareState extends State<MarkCompare> {
  String? _choice;
  bool _checking = false;

  MarkCompareScene get _scene => widget.scene;

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
    final all = _scene.seals.every((s) => widget.compared.contains(s.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The maker's note, as it lies on the bench.
        WorkshopNote(key: const ValueKey('maker-note'), intro: widget.mission.letterIntro, text: _scene.note),
        const SizedBox(height: AppSpace.md),
        Text(
          all ? _scene.chooseTask : _scene.readTask,
          key: const ValueKey('bench-task'),
          textAlign: TextAlign.center,
          style: AppText.subtitle(),
        ),
        const SizedBox(height: AppSpace.md),
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
                          child: Image.asset(_scene.bench, fit: BoxFit.fill, excludeFromSemantics: true),
                        ),
                      ),
                      // Each stamp, small as it is on its thing.
                      for (final s in _scene.seals)
                        Positioned.fromRect(rect: at(s.seal), child: _Stamp(mark: _scene.mark, copy: s.copy)),
                      for (final s in _scene.seals)
                        Positioned.fromRect(
                          rect: at(s.area),
                          child: _SealSpot(
                            key: ValueKey('seal-spot-${s.id}'),
                            seal: s,
                            compared: widget.compared.contains(s.id),
                            onTap: () => showSealCloser(context, scene: _scene, seal: s, onCompared: widget.onCompared),
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
        // A thing is chosen only once the sheet has been laid on every
        // stamp: the choice is a comparison, never a guess.
        WorkshopChoices(
          open: all,
          lockedLine: 'Lay the sheet on every stamp first (${widget.compared.length} of ${_scene.seals.length}).',
          children: [
            for (final o in widget.mission.options)
              WorkshopChoice(
                key: ValueKey('bench-${o.id}'),
                label: o.label,
                selected: _choice == o.id,
                onTap: all ? () => setState(() => _choice = o.id) : null,
              ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        GameButton(
          key: const ValueKey('bench-check'),
          label: _scene.chooseLabel,
          glyph: InkGlyph.check,
          tap: TapRole.primary,
          onPressed: all && _choice != null && !_checking ? _check : null,
        ),
      ],
    );
  }
}

/// A stamp in its round place: the mark in ink, inside the circle.
class _Stamp extends StatelessWidget {
  const _Stamp({required this.mark, required this.copy});

  final MakerMark mark;
  final MarkCopy copy;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipOval(
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: FractionallySizedBox(
          widthFactor: 0.74,
          heightFactor: 0.74,
          child: Opacity(opacity: 0.82, child: MakerMarkView(mark: mark, copy: copy, ink: _stampInk)),
        ),
      ),
    ),
  );
}

class _SealSpot extends StatelessWidget {
  const _SealSpot({super.key, required this.seal, required this.compared, required this.onTap});

  final BenchSeal seal;
  final bool compared;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${seal.name}${compared ? ', compared' : ''}. Tap to look closer.',
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.goldLight.withValues(alpha: compared ? 0.45 : 0.9), width: AppLine.rule),
          borderRadius: BorderRadius.circular(AppRadius.paper),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: AppColors.navyDeep.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(3)),
                child: Text(seal.id.toUpperCase(), style: AppText.style(AppText.body, size: 12, weight: FontWeight.w800, color: AppColors.goldLight)),
              ),
            ),
            Positioned(
              right: 2,
              top: 2,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: AppColors.navyDeep.withValues(alpha: 0.8),
                child: InkIcon(compared ? InkGlyph.check : InkGlyph.search, size: 12, color: AppColors.goldLight),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// What the page is read with, on a slip of paper: the maker's note, the
/// repair card.
class WorkshopNote extends StatelessWidget {
  const WorkshopNote({super.key, required this.intro, required this.text});

  final String intro;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
    decoration: BoxDecoration(
      color: AppColors.paperLight,
      border: Border.all(color: AppLine.faint(0.25), width: AppLine.hairline),
      borderRadius: BorderRadius.circular(AppRadius.paper),
    ),
    child: Column(
      children: [
        Text(intro, textAlign: TextAlign.center, style: AppText.caption()),
        const SizedBox(height: 2),
        GlossaryText(text, textAlign: TextAlign.center, style: AppText.letter(size: 18)),
      ],
    ),
  );
}

/// Case 05's choices, two by two: dimmed, with [lockedLine] under them,
/// until what they are chosen from has been looked at ([open]).
class WorkshopChoices extends StatelessWidget {
  const WorkshopChoices({super.key, required this.open, required this.lockedLine, required this.children});

  final bool open;
  final String lockedLine;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: open ? 1 : 0.45,
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpace.sm,
          crossAxisSpacing: AppSpace.sm,
          childAspectRatio: 3.0,
          children: children,
        ),
      ),
      if (!open) ...[
        const SizedBox(height: AppSpace.sm),
        Text(lockedLine, key: const ValueKey('choices-locked'), textAlign: TextAlign.center, style: AppText.aside(size: 15)),
      ],
    ],
  );
}

/// A choice of Case 05's puzzles: a paper button, navy when chosen.
class WorkshopChoice extends StatelessWidget {
  const WorkshopChoice({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
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
    ),
  );
}

/// A stamp looked at up close, the tracing sheet under it: dragged (or laid
/// by its button) over the stamp, it settles where its mark lies on the
/// stamp's, and the stamp counts as compared.
Future<void> showSealCloser(BuildContext context, {required MarkCompareScene scene, required BenchSeal seal, required ValueChanged<String> onCompared}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: AppColors.navyDeep.withValues(alpha: 0.94),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim, _) => FadeTransition(
        opacity: anim,
        child: _SealCloser(scene: scene, seal: seal, onCompared: onCompared),
      ),
    ),
  );
}

class _SealCloser extends StatefulWidget {
  const _SealCloser({required this.scene, required this.seal, required this.onCompared});

  final MarkCompareScene scene;
  final BenchSeal seal;
  final ValueChanged<String> onCompared;

  @override
  State<_SealCloser> createState() => _SealCloserState();
}

class _SealCloserState extends State<_SealCloser> {
  /// Where the sheet's mark is, from the stamp's centre (null: at rest).
  Offset? _sheet;
  bool _laid = false;

  void _lay() {
    setState(() {
      _laid = true;
      _sheet = Offset.zero;
    });
    widget.onCompared(widget.seal.id);
  }

  void _lift() => setState(() {
        _laid = false;
        _sheet = null;
      });

  @override
  Widget build(BuildContext context) {
    final s = widget.scene;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            // The stamp as large as the screen allows, the sheet under it.
            final markShare = s.sheetMarkAt.width / s.sheetPixels.width;
            final stampD = math.min(300.0, math.min(box.maxWidth - 2 * AppSpace.xl, (box.maxHeight - 250) / 1.85)).clamp(140.0, 300.0);
            final markSide = stampD * 0.74;
            final sheetSide = markSide / markShare;
            final markCentre = Offset(s.sheetMarkAt.center.dx / s.sheetPixels.width, s.sheetMarkAt.center.dy / s.sheetPixels.height) * sheetSide;
            // At rest, the sheet's top edge just over the stamp's lower part,
            // its whole mark in view.
            final rest = Offset(0, stampD * 0.4 + markCentre.dy);
            final at = _sheet ?? rest;
            final stageH = stampD / 2 + AppSpace.sm + stampD * 0.4 + s.sheetMarkAt.bottom / s.sheetPixels.height * sheetSide + AppSpace.sm;
            final stageW = math.min(box.maxWidth, 460.0);
            final centre = Offset(stageW / 2, stampD / 2 + AppSpace.sm);
            return Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.seal.name, key: const ValueKey('seal-close-title'), style: AppText.mark(color: AppColors.goldLight)),
                    const SizedBox(height: AppSpace.sm),
                    SizedBox(
                      width: stageW,
                      height: stageH,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          // The stamp on its thing, large.
                          Positioned(
                            left: centre.dx - stampD / 2,
                            top: centre.dy - stampD / 2,
                            width: stampD,
                            height: stampD,
                            child: Semantics(
                              image: true,
                              label: 'The stamp on ${widget.seal.thing}',
                              excludeSemantics: true,
                              child: DecoratedBox(
                                key: ValueKey('seal-close-${widget.seal.id}'),
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.parchment),
                                child: ClipOval(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CroppedPicture(file: s.bench, pixels: s.pixels, crop: widget.seal.seal),
                                      Center(
                                        child: SizedBox.square(
                                          dimension: markSide,
                                          child: Opacity(opacity: 0.85, child: MakerMarkView(mark: s.mark, copy: widget.seal.copy, ink: _stampInk)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // The tracing sheet, the maker's own mark on it.
                          AnimatedPositioned(
                            duration: still || _sheet != null && !_laid ? Duration.zero : const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            left: centre.dx + at.dx - markCentre.dx,
                            top: centre.dy + at.dy - markCentre.dy,
                            width: sheetSide,
                            height: sheetSide,
                            child: Semantics(
                              button: true,
                              label: _laid ? 'The tracing sheet, laid over the stamp' : 'The tracing sheet. Drag it over the stamp.',
                              excludeSemantics: true,
                              child: GestureDetector(
                                key: const ValueKey('tracing-sheet'),
                                onPanUpdate: (d) => setState(() {
                                  _laid = false;
                                  _sheet = (_sheet ?? rest) + d.delta;
                                }),
                                onPanEnd: (_) {
                                  final off = _sheet ?? rest;
                                  if (off.distance < stampD * 0.3) {
                                    _lay();
                                  } else {
                                    setState(() {});
                                  }
                                },
                                child: Opacity(
                                  opacity: 0.58,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.asset(s.sheet, fit: BoxFit.fill, excludeFromSemantics: true),
                                      Positioned(
                                        left: s.sheetMarkAt.left / s.sheetPixels.width * sheetSide,
                                        top: s.sheetMarkAt.top / s.sheetPixels.height * sheetSide,
                                        width: markSide,
                                        height: markSide,
                                        child: MakerMarkView(mark: s.mark, copy: MarkCopy.exact, ink: _sheetInk),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
                      child: Text(
                        _laid ? 'The blue lines are the maker\'s own mark. Do they match?' : 'Drag the tracing sheet over the stamp.',
                        key: const ValueKey('seal-close-task'),
                        textAlign: TextAlign.center,
                        style: AppText.title(size: 19, color: AppColors.goldLight),
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.sm,
                      children: [
                        GameButton(
                          key: const ValueKey('seal-close-lay'),
                          label: _laid ? 'LIFT THE SHEET' : s.sheetLabel,
                          style: GameButtonStyle.glass,
                          onPressed: _laid ? _lift : _lay,
                        ),
                        Builder(
                          builder: (context) => GameButton(
                            key: const ValueKey('seal-close-done'),
                            label: 'BACK TO THE BENCH',
                            style: GameButtonStyle.glass,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
