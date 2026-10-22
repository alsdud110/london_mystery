import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/mission.dart';
import '../../../data/models/river_puzzles.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import 'river_papers.dart';
import 'tower_documents.dart' show CroppedPicture;

/// The green boxes on the quay, then the open one ([BoxesScene]). A box is
/// tried by a tap ([onTry], kept tried); only the right one opens. In it,
/// the label's three torn pieces and a scrap of another paper: each piece
/// is set in a slot of the label's frame, by a tap on it and then on the
/// slot, or dragged there ([onPlaced], saved). CHECK THE LABEL sends the
/// frame to [onSubmit], checked as the puzzle's answer. The label's last
/// piece is not in the box, and nothing of it is built here.
class LabelAssembly extends StatefulWidget {
  const LabelAssembly({
    super.key,
    required this.scene,
    required this.mission,
    required this.tried,
    required this.onTry,
    required this.placed,
    required this.onPlaced,
    required this.onSubmit,
  });

  final BoxesScene scene;
  final Mission mission;

  /// The boxes tried so far (the right one: opened).
  final Set<String> tried;
  final ValueChanged<String> onTry;

  /// Each slot's piece.
  final Map<String, String> placed;
  final ValueChanged<Map<String, String>> onPlaced;
  final Future<void> Function(String answer) onSubmit;

  @override
  State<LabelAssembly> createState() => _LabelAssemblyState();
}

class _LabelAssemblyState extends State<LabelAssembly> {
  /// The piece picked up (to be set by a tap on a slot).
  String? _holding;

  /// The last box tried, its note said under the boxes.
  String? _lastTried;
  bool _checking = false;

  late final LabelCut _cut = LabelCut(widget.scene.label);

  BoxesScene get _scene => widget.scene;
  bool get _open => widget.tried.contains(_scene.right.id);

  /// The pieces in the tray, in the order they lie in the box.
  static const _boxOrder = [DeliveryLabel.bottom, BoxesScene.decoyId, DeliveryLabel.top, DeliveryLabel.middle];

  String _name(String piece) => widget.mission.options.where((o) => o.id == piece).firstOrNull?.label ?? piece;

  void _try(QuayBox box) {
    setState(() => _lastTried = box.id);
    widget.onTry(box.id);
  }

  void _put(String piece, String slot) {
    final placed = {...widget.placed}..removeWhere((_, p) => p == piece);
    placed[slot] = piece;
    setState(() => _holding = null);
    widget.onPlaced(placed);
  }

  void _tapSlot(String slot) {
    final holding = _holding;
    if (holding != null) {
      _put(holding, slot);
    } else if (widget.placed.containsKey(slot)) {
      // Taken back out to the tray.
      widget.onPlaced({...widget.placed}..remove(slot));
    }
  }

  Future<void> _check() async {
    if (_checking || widget.placed.length < _scene.slots.length) return;
    setState(() => _checking = true);
    try {
      await widget.onSubmit(_scene.answerOf(widget.placed));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedSwitcher(
      duration: still ? Duration.zero : const Duration(milliseconds: 350),
      child: _open ? _labelStep() : _boxesStep(),
    );
  }

  // ── The boxes ──────────────────────────────────────────────────────────

  Widget _boxesStep() {
    final view = _scene.view;
    final note = _lastTried == null ? null : _scene.box(_lastTried!).note;
    return Column(
      key: const ValueKey('boxes-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_scene.boxTask, key: const ValueKey('boxes-task'), textAlign: TextAlign.center, style: AppText.subtitle()),
        const SizedBox(height: AppSpace.md),
        DecoratedBox(
          decoration: BoxDecoration(boxShadow: AppShadow.paperLift, borderRadius: BorderRadius.circular(AppRadius.paper)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.paper),
            child: AspectRatio(
              aspectRatio: view.width * _scene.pixels.width / (view.height * _scene.pixels.height),
              child: LayoutBuilder(
                builder: (context, box) {
                  Rect at(Rect r) => Rect.fromLTRB(
                        (r.left - view.left) / view.width * box.maxWidth,
                        (r.top - view.top) / view.height * box.maxHeight,
                        (r.right - view.left) / view.width * box.maxWidth,
                        (r.bottom - view.top) / view.height * box.maxHeight,
                      );
                  return Stack(
                    children: [
                      Positioned.fill(child: CroppedPicture(file: _scene.picture, pixels: _scene.pixels, crop: view, label: _scene.place)),
                      for (final b in _scene.boxes)
                        Positioned.fromRect(
                          rect: at(b.area),
                          child: _BoxSpot(
                            key: ValueKey('quay-box-${b.id}'),
                            number: b.number,
                            tried: widget.tried.contains(b.id),
                            onTap: () => _try(b),
                          ),
                        ),
                      // Each number on its plate, large enough to read.
                      for (final b in _scene.boxes)
                        Positioned(
                          left: at(b.plateAt).center.dx - 22,
                          top: at(b.plateAt).center.dy - 15,
                          width: 44,
                          height: 30,
                          child: IgnorePointer(child: _NumberPlate(key: ValueKey('box-number-${b.id}'), number: b.number)),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: note == null
              ? const SizedBox(key: ValueKey('no-note'), height: AppSpace.xl)
              : Container(
                  key: ValueKey('box-note-$_lastTried'),
                  padding: const EdgeInsets.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: AppColors.parchment.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppRadius.paper),
                    border: Border.all(color: AppColors.parchmentDark, width: AppLine.hairline),
                  ),
                  child: Text(note, textAlign: TextAlign.center, style: AppText.bodyText(size: 17, color: AppColors.inkBrown)),
                ),
        ),
      ],
    );
  }

  // ── The label ──────────────────────────────────────────────────────────

  Widget _labelStep() {
    final tray = [for (final p in _boxOrder) if (!widget.placed.containsValue(p)) p];
    final full = widget.placed.length == _scene.slots.length;
    return Column(
      key: const ValueKey('label-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The open box, the scraps in it.
        DecoratedBox(
          decoration: BoxDecoration(boxShadow: AppShadow.paperLift, borderRadius: BorderRadius.circular(AppRadius.paper)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.paper),
            child: CroppedPicture(
              key: const ValueKey('box-open'),
              file: _scene.open,
              pixels: _scene.openPixels,
              crop: _scene.openPixels.rect(150, 120, 1386, 900),
              label: _scene.openLabel,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Text(_scene.labelTask, key: const ValueKey('label-task'), textAlign: TextAlign.center, style: AppText.subtitle()),
        const SizedBox(height: AppSpace.md),
        _Frame(
          scene: _scene,
          cut: _cut,
          placed: widget.placed,
          holding: _holding != null,
          name: _name,
          onTap: _tapSlot,
          onDrop: _put,
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          tray.isEmpty ? 'Every scrap is in the frame.' : 'THE SCRAPS IN THE BOX',
          textAlign: TextAlign.center,
          style: tray.isEmpty ? AppText.aside(size: 15, color: AppColors.inkBrown) : AppText.eyebrow(),
        ),
        const SizedBox(height: AppSpace.sm),
        LayoutBuilder(
          builder: (context, box) {
            final w = (box.maxWidth - AppSpace.sm) / 2;
            return Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              alignment: WrapAlignment.center,
              children: [
                for (final p in tray)
                  _TrayPiece(
                    key: ValueKey('tray-$p'),
                    id: p,
                    width: w,
                    name: _name(p),
                    holding: _holding == p,
                    onTap: () => setState(() => _holding = _holding == p ? null : p),
                    child: _pieceView(p),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpace.md),
        GameButton(
          key: const ValueKey('label-check'),
          label: _scene.checkLabel,
          glyph: InkGlyph.check,
          tap: TapRole.primary,
          onPressed: full && !_checking ? _check : null,
        ),
      ],
    );
  }

  Widget _pieceView(String p) => p == BoxesScene.decoyId
      ? DecoyScrapView(scene: _scene)
      : Semantics(
          image: true,
          label: labelPieceSpoken(_scene.label, p),
          excludeSemantics: true,
          child: LabelPieceView(cut: _cut, piece: p),
        );
}

/// The label's frame: three slots, top to bottom, each the place of one of
/// its pieces. A piece set in its own slot lies exactly there (the label
/// whole once all three are); any other is shown in the slot as it is.
class _Frame extends StatelessWidget {
  const _Frame({
    required this.scene,
    required this.cut,
    required this.placed,
    required this.holding,
    required this.name,
    required this.onTap,
    required this.onDrop,
  });

  final BoxesScene scene;
  final LabelCut cut;
  final Map<String, String> placed;
  final bool holding;
  final String Function(String piece) name;
  final ValueChanged<String> onTap;
  final void Function(String piece, String slot) onDrop;

  /// The piece each slot is the place of.
  static const own = {'top': DeliveryLabel.top, 'middle': DeliveryLabel.middle, 'bottom': DeliveryLabel.bottom};

  @override
  Widget build(BuildContext context) {
    final l = scene.label;
    final w = l.pixels.width, h = l.pixels.height;
    final slots = {
      'top': Rect.fromLTRB(0, 0, w, l.tear1),
      'middle': Rect.fromLTRB(0, l.tear1, w, l.tear2),
      'bottom': Rect.fromLTRB(0, l.tear2, w, h),
    };
    final rightPieces = {for (final e in placed.entries) if (own[e.key] == e.value) e.value};
    return AspectRatio(
      aspectRatio: w / h,
      child: LayoutBuilder(
        builder: (context, box) {
          final scale = box.maxWidth / w;
          Rect at(Rect r) => Rect.fromLTRB(r.left * scale, r.top * scale, r.right * scale, r.bottom * scale);
          return Stack(
            children: [
              // The pieces set in their own slots, where they are on the label.
              Positioned.fill(
                child: IgnorePointer(
                  child: LabelPart(
                    key: const ValueKey('frame-label'),
                    part: Offset.zero & Size(w, h),
                    size: Size(w, h),
                    sheet: LabelSheet(cut: cut, pieces: rightPieces),
                  ),
                ),
              ),
              for (final MapEntry(key: slot, value: r) in slots.entries)
                Positioned.fromRect(
                  rect: at(r).deflate(math.min(3, at(r).height / 10)),
                  child: DragTarget<String>(
                    onAcceptWithDetails: (d) => onDrop(d.data, slot),
                    builder: (context, over, _) {
                      final piece = placed[slot];
                      return Semantics(
                        button: true,
                        label: '${slot[0].toUpperCase()}${slot.substring(1)} of the label: '
                            '${piece == null ? 'empty' : name(piece)}.'
                            '${holding ? ' Tap to put the piece here.' : piece == null ? '' : ' Tap to take it out.'}',
                        excludeSemantics: true,
                        child: GestureDetector(
                          key: ValueKey('slot-$slot'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onTap(slot),
                          child: CustomPaint(
                            painter: piece == null || over.isNotEmpty ? _SlotPainter(lit: over.isNotEmpty || holding) : null,
                            child: piece == null
                                ? Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(slot.toUpperCase(), style: AppText.eyebrow(color: AppColors.inkBrown.withValues(alpha: 0.7))),
                                    ),
                                  )
                                // A piece set in another slot: shown there as it is.
                                : own[slot] == piece
                                ? null
                                : Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Center(
                                      key: ValueKey('slot-$slot-$piece'),
                                      child: piece == BoxesScene.decoyId
                                          ? DecoyScrapView(scene: scene)
                                          : LabelPieceView(cut: cut, piece: piece),
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// An empty slot of the frame: a dashed outline (brighter while a piece is
/// held over it, or picked up to set).
class _SlotPainter extends CustomPainter {
  const _SlotPainter({required this.lit});

  final bool lit;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (lit ? AppColors.navy : AppColors.inkBrown).withValues(alpha: lit ? 0.8 : 0.45)
      ..strokeWidth = lit ? 2 : 1.5
      ..style = PaintingStyle.stroke;
    final r = (Offset.zero & size).deflate(1);
    const dash = 6.0, gap = 4.0;
    for (final (a, b) in [(r.topLeft, r.topRight), (r.topRight, r.bottomRight), (r.bottomRight, r.bottomLeft), (r.bottomLeft, r.topLeft)]) {
      final d = b - a;
      final len = d.distance;
      final dir = d / len;
      for (var t = 0.0; t < len; t += dash + gap) {
        canvas.drawLine(a + dir * t, a + dir * math.min(t + dash, len), paint);
      }
    }
    if (lit) canvas.drawRect(r, Paint()..color = AppColors.royalBlueSoft.withValues(alpha: 0.25));
  }

  @override
  bool shouldRepaint(_SlotPainter old) => old.lit != lit;
}

/// A scrap in the tray: tapped, picked up (a gold edge); or dragged.
class _TrayPiece extends StatelessWidget {
  const _TrayPiece({
    super.key,
    required this.id,
    required this.width,
    required this.name,
    required this.holding,
    required this.onTap,
    required this.child,
  });

  final String id;
  final double width;
  final String name;
  final bool holding;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.all(AppSpace.xs),
      decoration: BoxDecoration(
        color: AppColors.walnutDeep.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: holding ? AppColors.gold : AppLine.faint(0.25), width: holding ? AppLine.ink : AppLine.hairline),
      ),
      alignment: Alignment.center,
      child: child,
    );
    return Semantics(
      button: true,
      selected: holding,
      label: '$name${holding ? ', picked up. Now tap a slot.' : '. Tap to pick it up.'}',
      child: Draggable<String>(
        data: id,
        feedback: Material(type: MaterialType.transparency, child: Opacity(opacity: 0.9, child: SizedBox(width: width, child: child))),
        childWhenDragging: Opacity(opacity: 0.3, child: card),
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: ExcludeSemantics(child: card)),
      ),
    );
  }
}

/// A green box on the quay: a fine gold frame round it, dimmed once tried.
class _BoxSpot extends StatelessWidget {
  const _BoxSpot({super.key, required this.number, required this.tried, required this.onTap});

  final String number;
  final bool tried;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Box $number${tried ? ', tried' : ''}. Tap to open it.',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.goldLight.withValues(alpha: tried ? 0.35 : 0.85), width: AppLine.rule),
            borderRadius: BorderRadius.circular(AppRadius.paper),
          ),
        ),
      ),
    );
  }
}

/// A box's number, painted on an enamel plate over the box's own.
class _NumberPlate extends StatelessWidget {
  const _NumberPlate({super.key, required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.paperLight,
          borderRadius: BorderRadius.circular(AppRadius.paper),
          border: Border.all(color: AppColors.goldDeep, width: AppLine.rule),
          boxShadow: AppShadow.paperLift,
        ),
        child: Center(
          child: MediaQuery.withNoTextScaling(
            child: Text(number, style: AppText.style(AppText.body, size: 17, weight: FontWeight.w800, color: AppColors.navyDeep)),
          ),
        ),
      ),
    );
  }
}
