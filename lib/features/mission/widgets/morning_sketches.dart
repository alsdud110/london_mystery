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
import 'question_widgets.dart' show questionFor;
import 'river_papers.dart' show PictureCanvas;
import 'workshop_papers.dart' show handwriting;

/// M2, P.'s three drawings ([MorningSketchesScene]), in three steps, where
/// they are saved ([state], [onState]):
/// 1. put in order on three slots (a drawing tapped then its slot tapped,
///    or dragged there; a filled slot tapped gives it back) by P.'s tag,
///    checked here (a wrong order says why, nothing is lost);
/// 2. each laid over the one before, a slider between them, and what is new
///    tapped (a tap anywhere else is never wrong);
/// 3. the mission's question, its answer sent to [onSubmit].
class MorningSketchesPuzzle extends StatefulWidget {
  const MorningSketchesPuzzle({super.key, required this.scene, required this.mission, required this.state, required this.onState, required this.onSubmit});

  final MorningSketchesScene scene;
  final Mission mission;
  final SketchState state;
  final ValueChanged<SketchState> onState;
  final Future<void> Function(String answer) onSubmit;

  /// The page's heading for where the drawings are.
  static String headingOf(MorningSketchesScene scene, Mission m, SketchState state) => !state.ordered
      ? scene.orderTask
      : state.found.length < scene.changes.length
      ? 'What is new in each drawing?'
      : m.question;

  @override
  State<MorningSketchesPuzzle> createState() => _MorningSketchesPuzzleState();
}

class _MorningSketchesPuzzleState extends State<MorningSketchesPuzzle> {
  /// The drawing picked up from the table (to set on a slot).
  String? _picked;

  /// Why the order is not right, or that it is (just checked).
  String? _line;
  bool _lineIsRight = false;

  /// The pair being compared (0: drawings 1 and 2; 1: drawings 2 and 3),
  /// and how far the earlier one is slid over the later one.
  late int _pair = _firstOpenPair();
  double _split = 0.5;

  /// The last change found (its name said under the drawings).
  String? _just;

  MorningSketchesScene get _scene => widget.scene;
  SketchState get _state => widget.state;

  int _firstOpenPair() {
    for (var i = 1; i < _scene.sketches.length; i++) {
      if (!_scene.sketches[i].changes.every((c) => _state.found.contains(c.id))) return i - 1;
    }
    return _scene.sketches.length - 2;
  }

  // ── The order ─────────────────────────────────────────────────────────

  void _pick(String id) => setState(() {
    _picked = _picked == id ? null : id;
    _line = null;
  });

  void _place(int slot, String id) {
    final placed = [for (final p in _state.placed) p == id ? null : p];
    placed[slot] = id;
    setState(() {
      _picked = null;
      _line = null;
    });
    widget.onState(_state.copyWith(placed: placed));
  }

  void _tapSlot(int slot) {
    final picked = _picked;
    if (picked != null) {
      _place(slot, picked);
      return;
    }
    if (_state.placed[slot] == null) return;
    final placed = [..._state.placed]..[slot] = null;
    setState(() => _line = null);
    widget.onState(_state.copyWith(placed: placed));
  }

  void _checkOrder() {
    final placed = [for (final p in _state.placed) p!];
    final line = _scene.lineFor(placed);
    setState(() {
      _line = line ?? _scene.orderedLine;
      _lineIsRight = line == null;
    });
    if (line == null) {
      _pair = 0;
      widget.onState(_state.copyWith(ordered: true));
    }
  }

  Future<void> _look(MorningSketch s, String title) => showOperaCloser<void>(
    context,
    title: title,
    maxWidth: 720,
    child: MorningSketchView(key: ValueKey('sketch-close-${s.id}'), sketch: s),
  );

  /// A drawing's name on the table before it is ordered: by where it lies.
  String _tableName(String id) => 'DRAWING ${String.fromCharCode(65 + _scene.shown.indexOf(id))}';

  // ── What is new ───────────────────────────────────────────────────────

  void _tapAt(Offset p) {
    final later = _scene.sketches[_pair + 1];
    for (final c in later.changes) {
      if (c.area.contains(p) && !_state.found.contains(c.id)) {
        setState(() => _just = c.label);
        widget.onState(_state.copyWith(found: {..._state.found, c.id}));
        return;
      }
    }
  }

  bool _pairDone(int pair) => _scene.sketches[pair + 1].changes.every((c) => _state.found.contains(c.id));

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (!state.ordered) return _order(context);
    if (state.found.length < _scene.changes.length || !_pairDone(_pair)) return _compare(context);
    return _question(context);
  }

  Widget _tag() => Container(
    key: const ValueKey('sketch-tag'),
    padding: const EdgeInsets.all(AppSpace.md),
    decoration: BoxDecoration(
      color: AppColors.paperLight,
      border: Border.all(color: AppLine.faint(0.25), width: AppLine.hairline),
      borderRadius: BorderRadius.circular(AppRadius.paper),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("P.'S TAG", style: AppText.eyebrow()),
        const SizedBox(height: AppSpace.xs),
        Text(widget.mission.letter, style: handwriting(18)),
      ],
    ),
  );

  Widget _order(BuildContext context) {
    final state = _state;
    final onTable = [for (final id in _scene.shown) if (!state.placed.contains(id)) id];
    final full = state.placed.every((p) => p != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tag(),
        const SizedBox(height: AppSpace.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _scene.slots.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpace.xs),
              Expanded(child: _slot(i)),
            ],
          ],
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          onTable.isEmpty ? 'Tap a drawing on a slot to take it back.' : (_picked == null ? 'Tap a drawing, then tap its slot. Or drag it there.' : 'Now tap a slot for ${_tableName(_picked!)}.'),
          key: const ValueKey('sketch-order-task'),
          textAlign: TextAlign.center,
          style: AppText.bodyText(size: 15, weight: FontWeight.w600, color: AppColors.navy),
        ),
        const SizedBox(height: AppSpace.sm),
        if (onTable.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final id in onTable) _tableCard(context, id),
            ],
          ),
        if (_line != null) ...[
          const SizedBox(height: AppSpace.md),
          Semantics(
            liveRegion: true,
            child: Text(
              _line!,
              key: const ValueKey('sketch-order-line'),
              textAlign: TextAlign.center,
              style: AppText.letter(size: 17, color: _lineIsRight ? AppColors.success : AppColors.tryAgain),
            ),
          ),
        ],
        const SizedBox(height: AppSpace.md),
        GameButton(
          key: const ValueKey('sketch-check-order'),
          label: _scene.checkOrderLabel,
          glyph: InkGlyph.check,
          tap: TapRole.primary,
          onPressed: full ? _checkOrder : null,
        ),
      ],
    );
  }

  Widget _tableCard(BuildContext context, String id) {
    final s = _scene.sketch(id);
    final picked = _picked == id;
    final width = (MediaQuery.sizeOf(context).width * 0.4).clamp(130.0, 200.0);
    final card = SizedBox(width: width, child: MorningSketchView(sketch: s));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Draggable<String>(
          data: id,
          feedback: Material(type: MaterialType.transparency, child: Opacity(opacity: 0.85, child: card)),
          childWhenDragging: Opacity(opacity: 0.3, child: card),
          child: Semantics(
            button: true,
            selected: picked,
            label: '${_tableName(id)}: ${s.label}. Tap to pick it up.',
            excludeSemantics: true,
            child: GestureDetector(
              key: ValueKey('sketch-card-$id'),
              onTap: () => _pick(id),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: Border.all(color: picked ? AppColors.gold : Colors.transparent, width: 3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: card,
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_tableName(id), style: AppText.eyebrow()),
            IconButton(
              key: ValueKey('sketch-look-$id'),
              tooltip: 'Look closer at ${_tableName(id)}',
              icon: const InkIcon(InkGlyph.search, size: AppIconSize.small, color: AppColors.navy),
              onPressed: () => _look(s, _tableName(id)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _slot(int i) {
    final id = _state.placed[i];
    return DragTarget<String>(
      onAcceptWithDetails: (d) => _place(i, d.data),
      builder: (context, candidates, _) => Column(
        children: [
          Text(_scene.slots[i], style: AppText.eyebrow(color: AppColors.goldDeep)),
          const SizedBox(height: AppSpace.xs),
          Semantics(
            button: true,
            label: '${_scene.slots[i]} slot: ${id == null ? 'empty' : _tableName(id)}.',
            excludeSemantics: true,
            child: GestureDetector(
              key: ValueKey('sketch-slot-$i'),
              onTap: () => _tapSlot(i),
              child: AspectRatio(
                aspectRatio: 1.5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: candidates.isNotEmpty || (_picked != null && id == null) ? AppColors.royalBlueSoft : AppColors.parchment,
                    border: Border.all(color: candidates.isNotEmpty ? AppColors.navy : AppLine.faint(0.35), width: AppLine.hairline),
                    borderRadius: BorderRadius.circular(AppRadius.paper),
                  ),
                  child: id == null
                      ? Center(child: Text('?', style: AppText.title(size: 22, color: AppColors.muted)))
                      : Padding(padding: const EdgeInsets.all(2), child: MorningSketchView(sketch: _scene.sketch(id))),
                ),
              ),
            ),
          ),
          if (id != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(_tableName(id), style: AppText.caption(color: AppColors.inkBrown)),
            ),
        ],
      ),
    );
  }

  Widget _compare(BuildContext context) {
    final earlier = _scene.sketches[_pair];
    final later = _scene.sketches[_pair + 1];
    final found = [for (final c in later.changes) if (_state.found.contains(c.id)) c];
    final done = found.length == later.changes.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The order just checked right, said once over the first pair.
        if (_lineIsRight && _line != null && _pair == 0) ...[
          Semantics(
            liveRegion: true,
            child: Text(_line!, key: const ValueKey('sketch-order-line'), textAlign: TextAlign.center, style: AppText.letter(size: 17, color: AppColors.success)),
          ),
          const SizedBox(height: AppSpace.sm),
        ],
        Text('DRAWING ${_pair + 1}  ·  DRAWING ${_pair + 2}', key: const ValueKey('sketch-pair'), textAlign: TextAlign.center, style: AppText.eyebrow()),
        const SizedBox(height: AppSpace.xs),
        Text(_scene.compareTask, textAlign: TextAlign.center, style: AppText.bodyText(size: 15, weight: FontWeight.w600, color: AppColors.navy)),
        const SizedBox(height: AppSpace.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          child: Semantics(
            label: 'Drawing ${_pair + 1} laid over drawing ${_pair + 2}. ${later.label}',
            child: PictureCanvas(
              key: const ValueKey('sketch-overlay'),
              pixels: later.pixels,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _tapAt(d.localPosition),
                child: Stack(
                  children: [
                    Positioned.fill(child: MorningSketchCanvas(sketch: later)),
                    Positioned.fill(
                      child: ClipRect(
                        clipper: _LeftOf(_split),
                        child: MorningSketchCanvas(sketch: earlier),
                      ),
                    ),
                    Positioned(
                      left: later.pixels.width * _split - 4,
                      top: 0,
                      bottom: 0,
                      width: 8,
                      child: const IgnorePointer(child: ColoredBox(color: AppColors.gold)),
                    ),
                    for (final c in found)
                      Positioned.fromRect(
                        rect: c.area,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            key: ValueKey('sketch-found-${c.id}'),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.gold, width: 9),
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Row(
          children: [
            Text('${_pair + 1}', style: AppText.title(size: 18, color: AppColors.goldDeep)),
            Expanded(
              child: Semantics(
                label: 'Slide between drawing ${_pair + 1} and drawing ${_pair + 2}',
                child: Slider(
                  key: const ValueKey('sketch-slider'),
                  value: _split,
                  activeColor: AppColors.navy,
                  inactiveColor: AppColors.parchmentDark,
                  onChanged: (v) => setState(() => _split = v),
                ),
              ),
            ),
            Text('${_pair + 2}', style: AppText.title(size: 18, color: AppColors.goldDeep)),
          ],
        ),
        Text(
          'Found ${found.length} of ${later.changes.length}${_just == null ? '' : ' · $_just'}',
          key: const ValueKey('sketch-found-count'),
          textAlign: TextAlign.center,
          style: AppText.bodyText(size: 15, weight: FontWeight.w700, color: AppColors.navy),
        ),
        if (found.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xs),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              for (final c in found)
                Chip(
                  avatar: const InkIcon(InkGlyph.check, size: 16, color: AppColors.success),
                  label: Text(c.label, style: AppText.caption(color: AppColors.ink)),
                  backgroundColor: AppColors.successSoft,
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
        // The last pair done goes straight on to the question (see build).
        if (done && _pair + 2 < _scene.sketches.length) ...[
          const SizedBox(height: AppSpace.md),
          GameButton(
            key: const ValueKey('sketch-next-pair'),
            label: 'NEXT TWO DRAWINGS',
            arrow: true,
            tap: TapRole.primary,
            onPressed: () => setState(() {
              _just = null;
              _split = 0.5;
              _pair++;
            }),
          ),
        ],
      ],
    );
  }

  Widget _question(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          for (final (i, s) in _scene.sketches.indexed) ...[
            if (i > 0) const SizedBox(width: AppSpace.xs),
            Expanded(
              child: Column(
                children: [
                  Semantics(
                    button: true,
                    label: 'Drawing ${i + 1}: ${s.label}. Tap to look closer.',
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: ValueKey('sketch-ordered-${s.id}'),
                      onTap: () => _look(s, 'DRAWING ${i + 1}'),
                      child: MorningSketchView(sketch: s),
                    ),
                  ),
                  Text('DRAWING ${i + 1}', style: AppText.caption(color: AppColors.inkBrown)),
                ],
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: AppSpace.lg),
      questionFor(widget.mission, widget.onSubmit),
    ],
  );
}

/// The part of a picture left of [split] (a fraction of its width).
class _LeftOf extends CustomClipper<Rect> {
  const _LeftOf(this.split);

  final double split;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * split, size.height);

  @override
  bool shouldReclip(_LeftOf old) => old.split != split;
}
