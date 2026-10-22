import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/mission.dart';
import '../../../data/models/tower_puzzles.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import 'tower_documents.dart' show CroppedPicture;

/// A padlock with three dials ([DialLockScene]). Each dial is its own
/// picture turned behind a round window of the lock: dragged round, it
/// follows the finger and settles on the nearest symbol; tapped, it turns
/// on to the next. The lock's own brass pointers stay still above the
/// windows: the symbol under each is the one set. Where the dials are left
/// is saved as they settle ([onSet]), so the lock is as it was after a
/// restart. OPEN THE LOCK sends the three, left to right, to [onSubmit],
/// checked as the puzzle's answer: a wrong set opens nothing and says
/// nothing of the answer.
class DialLock extends StatefulWidget {
  const DialLock({
    super.key,
    required this.scene,
    required this.mission,
    required this.dials,
    required this.onSet,
    required this.onSubmit,
  });

  final DialLockScene scene;
  final Mission mission;

  /// The symbol each dial is set on (indices into the scene's symbols).
  final List<int> dials;
  final ValueChanged<List<int>> onSet;
  final Future<void> Function(String answer) onSubmit;

  @override
  State<DialLock> createState() => _DialLockState();
}

class _DialLockState extends State<DialLock> {
  /// Each dial's turn (radians, clockwise), as shown.
  late final List<double> _turns = [for (final i in widget.dials) widget.scene.turnFor(i)];
  late final List<int> _set = [...widget.dials];
  int? _dragging;
  double? _lastAngle;
  bool _checking = false;

  DialLockScene get _scene => widget.scene;

  /// A dial at rest on [index], turned there the short way from where it is.
  void _settle(int dial, int index) {
    final target = _scene.turnFor(index);
    // The same place, as near as can be to where the dial is now (no spin
    // the long way round).
    final full = 2 * math.pi;
    final k = ((_turns[dial] - target) / full).round();
    setState(() {
      _turns[dial] = target + k * full;
      _set[dial] = index;
      _dragging = null;
    });
    HapticFeedback.selectionClick();
    widget.onSet([..._set]);
  }

  /// A tap turns the dial on to the next symbol (anticlockwise, so the
  /// next one comes up under the pointer from the right).
  void _next(int dial) {
    final from = _set[dial];
    final to = (from + 1) % _scene.symbols.length;
    final step = (_scene.symbols[to].angle - _scene.symbols[from].angle) % 360;
    setState(() {
      _turns[dial] -= step * math.pi / 180;
      _set[dial] = to;
    });
    HapticFeedback.selectionClick();
    widget.onSet([..._set]);
  }

  Future<void> _open() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await widget.onSubmit([for (final i in _set) _scene.symbols[i].id].join(','));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final view = _scene.view;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_scene.task, textAlign: TextAlign.center, style: AppText.subtitle()),
        const SizedBox(height: AppSpace.md),
        Semantics(
          label: _scene.label,
          child: AspectRatio(
            aspectRatio: view.width / view.height,
            child: LayoutBuilder(
              builder: (context, box) {
                // Lock pixels to page pixels.
                final k = box.maxWidth / view.width;
                final lockW = _scene.pixels.width * k;
                final lockH = _scene.pixels.height * k;
                // One dial's picture, scaled to its window.
                final dk = _scene.dialScale * k;
                final dialW = _scene.dialPixels.width * dk;
                final dialH = _scene.dialPixels.height * dk;
                final pivot = Offset(_scene.pivot.dx * dk, _scene.pivot.dy * dk);
                final r = _scene.windowRadius * k;
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    for (final (i, w) in _scene.windows.indexed) ...[
                      // Dark behind the window, at its edge only.
                      Positioned(
                        left: (w.dx - view.left) * k - r,
                        top: (w.dy - view.top) * k - r,
                        width: r * 2,
                        height: r * 2,
                        child: const DecoratedBox(decoration: BoxDecoration(color: AppColors.walnutDeep, shape: BoxShape.circle)),
                      ),
                      // The dial, its pivot on the window's centre, seen only
                      // through the window.
                      Positioned(
                        left: (w.dx - view.left) * k - r,
                        top: (w.dy - view.top) * k - r,
                        width: r * 2,
                        height: r * 2,
                        child: ClipOval(
                          child: OverflowBox(
                            alignment: Alignment.topLeft,
                            minWidth: dialW,
                            maxWidth: dialW,
                            minHeight: dialH,
                            maxHeight: dialH,
                            child: Transform.translate(
                              offset: Offset(r - pivot.dx, r - pivot.dy),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(end: _turns[i]),
                                duration: still || _dragging == i ? Duration.zero : const Duration(milliseconds: 260),
                                curve: Curves.easeOutCubic,
                                builder: (context, turn, child) => Transform.rotate(
                                  angle: turn,
                                  origin: Offset(pivot.dx - dialW / 2, pivot.dy - dialH / 2),
                                  child: child,
                                ),
                                child: Image.asset(
                                  _scene.dial,
                                  key: ValueKey('dial-picture-$i'),
                                  width: dialW,
                                  height: dialH,
                                  fit: BoxFit.fill,
                                  excludeFromSemantics: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    // The lock over the dials: its bezels and still pointers.
                    Positioned(
                      left: -view.left * k,
                      top: -view.top * k,
                      width: lockW,
                      height: lockH,
                      child: IgnorePointer(
                        child: Image.asset(_scene.lock, fit: BoxFit.fill, excludeFromSemantics: true),
                      ),
                    ),
                    // Each window takes the finger: a drag turns its dial, a
                    // tap turns it on.
                    for (final (i, w) in _scene.windows.indexed)
                      Positioned(
                        left: (w.dx - view.left) * k - r * 1.5,
                        top: (w.dy - view.top) * k - r * 1.5,
                        width: r * 3,
                        height: r * 3,
                        child: Semantics(
                          button: true,
                          label: 'Dial ${i + 1}: ${_scene.symbols[_set[i]].name}. Tap to turn it.',
                          excludeSemantics: true,
                          onTap: () => _next(i),
                          // A touch on a window is the dial's at once (a
                          // tap, or a drag round it): never the page's
                          // scroll, whichever way the finger goes.
                          child: RawGestureDetector(
                            key: ValueKey('dial-$i'),
                            behavior: HitTestBehavior.opaque,
                            gestures: {
                              _DialTouch: GestureRecognizerFactoryWithHandlers<_DialTouch>(
                                _DialTouch.new,
                                (touch) {
                                  final c = Offset(r * 1.5, r * 1.5);
                                  double angleAt(Offset p) => math.atan2(p.dy - c.dy, p.dx - c.dx);
                                  touch
                                    ..onDown = (p) {
                                      _lastAngle = angleAt(p);
                                    }
                                    ..onMove = (p) {
                                      final a = angleAt(p);
                                      var delta = a - (_lastAngle ?? a);
                                      if (delta > math.pi) delta -= 2 * math.pi;
                                      if (delta < -math.pi) delta += 2 * math.pi;
                                      _lastAngle = a;
                                      setState(() {
                                        _dragging = i;
                                        _turns[i] += delta;
                                      });
                                    }
                                    ..onEnd = (moved) => moved ? _settle(i, _scene.symbolAt(_turns[i])) : _next(i);
                                },
                              ),
                            },
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        // Each dial's number and what it is set on, under the lock: the
        // symbol close and upright (on the lock it is small, and turned).
        Row(
          children: [
            for (final (i, s) in _set.indexed)
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    children: [
                      Text('DIAL ${i + 1}', style: AppText.eyebrow()),
                      const SizedBox(height: AppSpace.xs),
                      _SymbolCloseUp(key: ValueKey('dial-symbol-$i-${_scene.symbols[s].id}'), scene: _scene, symbol: _scene.symbols[s]),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        _scene.symbols[s].name,
                        key: ValueKey('dial-set-$i'),
                        style: AppText.bodyText(size: 16, weight: FontWeight.w700, color: AppColors.navy),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        GameButton(
          key: const ValueKey('dial-open'),
          label: _scene.openLabel,
          glyph: InkGlyph.lock,
          tap: TapRole.primary,
          onPressed: _checking ? null : _open,
        ),
      ],
    );
  }
}

/// A dial's symbol alone, upright, in a small dark brass well: each cut out
/// along its own outline (nothing of the dial round it), every one the
/// same height in the same well.
class _SymbolCloseUp extends StatelessWidget {
  const _SymbolCloseUp({super.key, required this.scene, required this.symbol});

  final DialLockScene scene;
  final DialSymbol symbol;

  @override
  Widget build(BuildContext context) {
    final r = symbol.closeUp;
    final p = scene.dialPixels;
    return Container(
      width: 60,
      height: 60,
      padding: const EdgeInsets.all(AppSpace.sm),
      decoration: BoxDecoration(
        color: AppColors.walnutDeep,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.gold, width: AppLine.rule),
      ),
      child: Center(
        child: ClipPath(
          clipper: _OutlineClip(symbol),
          child: CroppedPicture(
            file: scene.dial,
            pixels: p,
            crop: Rect.fromLTRB(r.left / p.width, r.top / p.height, r.right / p.width, r.bottom / p.height),
          ),
        ),
      ),
    );
  }
}

/// A symbol's outline ([DialSymbol.outline]), from the dial's pixels to the
/// close-up's box ([DialSymbol.closeUp] filling it).
class _OutlineClip extends CustomClipper<Path> {
  const _OutlineClip(this.symbol);

  final DialSymbol symbol;

  @override
  Path getClip(Size size) {
    final box = symbol.closeUp;
    Offset at(Offset p) => Offset((p.dx - box.left) / box.width * size.width, (p.dy - box.top) / box.height * size.height);
    final path = Path();
    for (final o in symbol.outline.ovals) {
      path.addOval(Rect.fromPoints(at(o.topLeft), at(o.bottomRight)));
    }
    if (symbol.outline.polygon.isNotEmpty) path.addPolygon([for (final p in symbol.outline.polygon) at(p)], true);
    return path;
  }

  @override
  bool shouldReclip(_OutlineClip old) => old.symbol != symbol;
}

/// One finger on a dial's window, from down to up: claimed at once (so the
/// page never scrolls from a dial), and told apart as a tap (it never moved
/// past the touch slop) or a turn.
class _DialTouch extends OneSequenceGestureRecognizer {
  ValueChanged<Offset>? onDown;
  ValueChanged<Offset>? onMove;
  ValueChanged<bool>? onEnd;

  Offset _start = Offset.zero;
  bool _moved = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted);
    _start = event.localPosition;
    _moved = false;
    onDown?.call(event.localPosition);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      if (!_moved && (event.localPosition - _start).distance > kTouchSlop) _moved = true;
      if (_moved) onMove?.call(event.localPosition);
    } else if (event is PointerUpEvent) {
      onEnd?.call(_moved);
      stopTrackingPointer(event.pointer);
    } else if (event is PointerCancelEvent) {
      if (_moved) onEnd?.call(true);
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'dial touch';
}
