import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/scene_explore.dart' show ScenePixels;
import 'search_stage.dart';

/// A picture looked at closer in a [SearchStage]'s viewport: it opens on
/// [opening] (fractions), pinches and drags, always covering the viewport,
/// and goes back to its opening view whenever [resetCount] changes (the
/// page's WHOLE PICTURE). [builder] draws the picture at its size; its taps
/// are fractions of that size, wherever it is enlarged or moved to.
class ZoomPicture extends StatefulWidget {
  const ZoomPicture({
    super.key,
    required this.viewport,
    required this.pixels,
    required this.opening,
    required this.controller,
    required this.builder,
    this.resetCount = 0,
    this.onInteractionStart,
    this.maxScale = 4,
  });

  final Size viewport;
  final ScenePixels pixels;
  final Rect opening;
  final TransformationController controller;
  final Widget Function(Size size) builder;
  final int resetCount;
  final VoidCallback? onInteractionStart;
  final double maxScale;

  /// How far outside a place a tap still counts for it, on screen.
  static const slack = 14.0;

  @override
  State<ZoomPicture> createState() => _ZoomPictureState();
}

class _ZoomPictureState extends State<ZoomPicture> {
  Size? _homeViewport;
  bool _homeShown = false;
  bool _moved = false;

  SearchFrame _frame(double width) => SearchFrame(
        width: width,
        aspect: widget.pixels.aspect,
        inside: const Rect.fromLTRB(0, 0, 1, 1),
        focus: widget.opening,
        maxScale: widget.maxScale,
      );

  @override
  void didUpdateWidget(ZoomPicture old) {
    super.didUpdateWidget(old);
    if (old.resetCount != widget.resetCount) {
      _moved = false;
      widget.controller.value = _frame(widget.viewport.width).home(widget.viewport);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewport = widget.viewport;
    final frame = _frame(viewport.width);
    if (_homeViewport != viewport) {
      _homeViewport = viewport;
      final home = frame.home(viewport);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.controller.value = _moved ? frame.keep(widget.controller.value, viewport) : home;
        if (!_homeShown) setState(() => _homeShown = true);
      });
    }
    return ColoredBox(
      color: AppColors.navyDeep,
      child: Opacity(
        opacity: _homeShown ? 1 : 0,
        child: InteractiveViewer(
          transformationController: widget.controller,
          constrained: false,
          minScale: frame.minScale(viewport),
          maxScale: widget.maxScale,
          boundaryMargin: EdgeInsets.zero,
          onInteractionStart: (_) {
            _moved = true;
            widget.onInteractionStart?.call();
          },
          child: SizedBox.fromSize(size: frame.content, child: widget.builder(frame.picture)),
        ),
      ),
    );
  }
}

/// A thing found on a picture: a gold ring round its place, drawn in
/// (still with reduced motion).
class FoundRing extends StatelessWidget {
  const FoundRing({super.key, required this.still});

  final bool still;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: still ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        builder: (context, t, _) => Transform.scale(
          scale: 0.85 + 0.15 * t,
          child: Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.goldLight, width: AppLine.ink + 1),
                boxShadow: [BoxShadow(color: AppColors.navyDeep.withValues(alpha: 0.5), blurRadius: 6)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [r] (fractions) in a picture [size] big.
Rect placeOn(Rect r, Size size) =>
    Rect.fromLTRB(r.left * size.width, r.top * size.height, r.right * size.width, r.bottom * size.height);
