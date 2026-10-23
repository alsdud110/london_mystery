import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/abbesses_puzzles.dart';
import '../../../data/models/mission.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import 'abbesses_papers.dart';
import 'opera_papers.dart' show showOperaCloser;
import 'river_papers.dart' show PictureCanvas;
import 'workshop_papers.dart' show handwriting;

/// M3, the torn paper ([TornSlipScene]): P.'s note, the paper folded small,
/// unfolded a fold at a tap; then its parts marked, SAME as the Amendment
/// Slip (brought from the notebook below the page) or MISSING from it. A
/// tap on what is neither (a fold, the tear, dust) only says what it is;
/// the seal is marked only once it is looked at closer and its two
/// questions answered. CHECK sends what is marked ([TornSlipScene.answerOf]).
/// What is unfolded and marked is saved ([state], [onState]).
class TornSlipPuzzle extends StatefulWidget {
  const TornSlipPuzzle({super.key, required this.scene, required this.mission, required this.state, required this.onState, required this.onSubmit});

  final TornSlipScene scene;
  final Mission mission;
  final SlipState state;
  final ValueChanged<SlipState> onState;
  final Future<void> Function(String answer) onSubmit;

  @override
  State<TornSlipPuzzle> createState() => _TornSlipPuzzleState();
}

class _TornSlipPuzzleState extends State<TornSlipPuzzle> {
  FormMark _mode = FormMark.same;

  /// What the last tap said (a fold, the tear, …), or null.
  String? _line;
  bool _checking = false;

  TornSlipScene get _scene => widget.scene;
  SlipState get _state => widget.state;

  bool get _unfolded => _state.opened >= _scene.folds;

  void _unfold() => widget.onState(_state.copyWith(opened: _state.opened + 1));

  Future<void> _tap(Offset p) async {
    final part = _scene.partAt(p.dx, p.dy);
    if (part == null) {
      setState(() => _line = null);
      return;
    }
    final mark = part.mark;
    if (mark == null) {
      setState(() => _line = part.line);
      return;
    }
    final same = {..._state.same};
    final missing = {..._state.missing};
    final marked = mark == FormMark.same ? same : missing;
    // Marked already: tapped again, it is taken off.
    if (marked.contains(part.id)) {
      marked.remove(part.id);
      setState(() => _line = null);
      widget.onState(_state.copyWith(same: same, missing: missing));
      return;
    }
    if (mark != _mode) {
      setState(
        () => _line = _mode == FormMark.same
            ? 'Nothing is left here to compare. Is something MISSING?'
            : 'That is still on this paper. Is it the SAME as on the slip?',
      );
      return;
    }
    if (part.id == _scene.sealId && !await _checkSeal()) return;
    if (!mounted) return;
    marked.add(part.id);
    setState(() => _line = '${part.name}: ${mark == FormMark.same ? 'the same' : 'missing'}.');
    widget.onState(_state.copyWith(same: same, missing: missing));
  }

  /// The seal looked at closer, its questions answered: true when both are
  /// right.
  Future<bool> _checkSeal() async {
    final form = _scene.form;
    final ok = await showOperaCloser<bool>(
      context,
      title: _scene.sealTitle,
      closeKey: const ValueKey('seal-close-done'),
      child: _SealCheck(scene: _scene, stamp: form.stamp),
    );
    return ok ?? false;
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await widget.onSubmit(_scene.answerOf(_state.same, _state.missing));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _note(),
      const SizedBox(height: AppSpace.md),
      if (!_unfolded) _folded() else ..._marking(),
    ],
  );

  Widget _note() => Container(
    key: const ValueKey('slip-note-card'),
    padding: const EdgeInsets.all(AppSpace.md),
    decoration: BoxDecoration(
      color: AppColors.paperLight,
      border: Border.all(color: AppLine.faint(0.25), width: AppLine.hairline),
      borderRadius: BorderRadius.circular(AppRadius.paper),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("P.'S NOTE", style: AppText.eyebrow()),
        const SizedBox(height: AppSpace.xs),
        Text(_scene.noteLines.join('\n'), style: handwriting(18)),
      ],
    ),
  );

  Widget _folded() {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 260, maxHeight: MediaQuery.sizeOf(context).height * 0.32),
            child: Semantics(
              button: true,
              label: 'A paper folded small. Tap to unfold it. ${_state.opened} of ${_scene.folds} folds open.',
              excludeSemantics: true,
              child: GestureDetector(
                key: const ValueKey('slip-folded'),
                onTap: _unfold,
                child: AnimatedRotation(
                  turns: _state.opened * 0.02,
                  duration: still ? Duration.zero : const Duration(milliseconds: 250),
                  child: AnimatedScale(
                    scale: 1 + _state.opened * 0.08,
                    duration: still ? Duration.zero : const Duration(milliseconds: 250),
                    child: PictureCanvas(pixels: _scene.foldedPixels, child: Image.asset(_scene.folded, fit: BoxFit.fill, excludeFromSemantics: true)),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          '${_scene.unfoldTask}  ${_state.opened} / ${_scene.folds}',
          key: const ValueKey('slip-unfold-task'),
          textAlign: TextAlign.center,
          style: AppText.bodyText(size: 15, weight: FontWeight.w600, color: AppColors.navy),
        ),
      ],
    );
  }

  List<Widget> _marking() {
    final scene = _scene;
    final marked = [
      for (final p in scene.parts)
        if (_state.same.contains(p.id) || _state.missing.contains(p.id)) p,
    ];
    return [
      _ModeSwitch(mode: _mode, onMode: (m) => setState(() {
        _mode = m;
        _line = null;
      })),
      const SizedBox(height: AppSpace.sm),
      Text(
        _mode == FormMark.same ? scene.sameTask : scene.missingTask,
        key: const ValueKey('slip-mark-task'),
        textAlign: TextAlign.center,
        style: AppText.bodyText(size: 15, weight: FontWeight.w600, color: AppColors.navy),
      ),
      const SizedBox(height: AppSpace.sm),
      TornFormView(
        key: const ValueKey('slip-torn'),
        form: scene.form,
        child: Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tap(d.localPosition),
            child: Stack(
              children: [
                for (final p in marked)
                  Positioned.fromRect(
                    rect: p.area,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        key: ValueKey('slip-marked-${p.id}'),
                        decoration: BoxDecoration(
                          color: (_state.same.contains(p.id) ? AppColors.success : AppColors.tryAgain).withValues(alpha: 0.12),
                          border: Border.all(color: _state.same.contains(p.id) ? AppColors.success : AppColors.tryAgain, width: 8),
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      if (_line != null) ...[
        const SizedBox(height: AppSpace.sm),
        Semantics(
          liveRegion: true,
          child: Text(_line!, key: const ValueKey('slip-line'), textAlign: TextAlign.center, style: AppText.letter(size: 17, color: AppColors.inkBrown)),
        ),
      ],
      const SizedBox(height: AppSpace.sm),
      _MarkedList(title: 'SAME', parts: [for (final p in marked) if (_state.same.contains(p.id)) p], colour: AppColors.success),
      const SizedBox(height: AppSpace.xs),
      _MarkedList(title: 'MISSING', parts: [for (final p in marked) if (_state.missing.contains(p.id)) p], colour: AppColors.tryAgain),
      const SizedBox(height: AppSpace.md),
      GameButton(
        key: const ValueKey('slip-check'),
        label: scene.checkLabel,
        glyph: InkGlyph.check,
        tap: TapRole.primary,
        onPressed: _checking || marked.isEmpty ? null : _check,
      ),
    ];
  }
}

/// SAME | MISSING: what a tap on the paper marks.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.mode, required this.onMode});

  final FormMark mode;
  final ValueChanged<FormMark> onMode;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (i, m) in FormMark.values.indexed) ...[
        if (i > 0) const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Semantics(
            button: true,
            selected: mode == m,
            label: m == FormMark.same ? 'Mark what is the same' : 'Mark what is missing',
            excludeSemantics: true,
            child: Material(
              color: mode == m ? AppColors.navy : AppColors.paperLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                side: BorderSide(color: mode == m ? AppColors.navy : AppLine.faint(0.35), width: AppLine.hairline),
              ),
              child: InkWell(
                key: ValueKey('slip-mode-${m.name}'),
                borderRadius: BorderRadius.circular(AppRadius.button),
                onTap: () => onMode(m),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Center(
                    child: Text(m == FormMark.same ? 'SAME' : 'MISSING', style: AppText.button(size: 16, color: mode == m ? AppColors.paperLight : AppColors.navy)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

/// What is marked as [title], by name.
class _MarkedList extends StatelessWidget {
  const _MarkedList({required this.title, required this.parts, required this.colour});

  final String title;
  final List<FormPart> parts;
  final Color colour;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: '$title:  ', style: AppText.eyebrow(color: colour)),
        TextSpan(text: parts.isEmpty ? '—' : parts.map((p) => p.name).join(' · '), style: AppText.bodyText(size: 15, color: AppColors.ink)),
      ],
    ),
    key: ValueKey('slip-list-$title'),
    textAlign: TextAlign.center,
  );
}

/// The seal up close and its two questions; DONE pops true once both are
/// answered right.
class _SealCheck extends StatefulWidget {
  const _SealCheck({required this.scene, required this.stamp});

  final TornSlipScene scene;
  final String stamp;

  @override
  State<_SealCheck> createState() => _SealCheckState();
}

class _SealCheckState extends State<_SealCheck> {
  final Map<int, String> _chosen = {};

  @override
  Widget build(BuildContext context) {
    final checks = widget.scene.sealChecks;
    final allRight = [for (final (i, c) in checks.indexed) _chosen[i] == c.answer].every((r) => r);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.3),
          child: AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(color: AppColors.paperLight, borderRadius: BorderRadius.circular(AppRadius.paper)),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.md),
                child: Semantics(
                  image: true,
                  label: 'The purple seal on the torn paper, up close',
                  excludeSemantics: true,
                  child: Image.asset(widget.stamp, key: const ValueKey('seal-close'), fit: BoxFit.contain, excludeFromSemantics: true),
                ),
              ),
            ),
          ),
        ),
        for (final (i, c) in checks.indexed) ...[
          const SizedBox(height: AppSpace.md),
          Text(c.question, style: AppText.title(size: 19, color: AppColors.goldLight)),
          const SizedBox(height: AppSpace.xs),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpace.sm,
            children: [
              for (final choice in c.choices)
                ChoiceChip(
                  key: ValueKey('seal-$i-$choice'),
                  label: Text(choice, style: AppText.button(size: 15, color: _chosen[i] == choice ? AppColors.navyDeep : AppColors.paperLight)),
                  selected: _chosen[i] == choice,
                  selectedColor: AppColors.goldLight,
                  backgroundColor: AppColors.navy,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _chosen[i] = choice),
                ),
            ],
          ),
          if (_chosen[i] != null && _chosen[i] != c.answer)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs),
              child: Text(c.wrongLine, key: ValueKey('seal-wrong-$i'), textAlign: TextAlign.center, style: AppText.aside(size: 16, color: AppColors.paperLight)),
            ),
        ],
        const SizedBox(height: AppSpace.lg),
        GameButton(
          key: const ValueKey('seal-done'),
          label: 'IT IS THE SAME SEAL',
          glyph: InkGlyph.check,
          style: GameButtonStyle.gold,
          tap: TapRole.primary,
          onPressed: allRight ? () => Navigator.of(context).pop(true) : null,
        ),
        const SizedBox(height: AppSpace.xs),
      ],
    );
  }
}
