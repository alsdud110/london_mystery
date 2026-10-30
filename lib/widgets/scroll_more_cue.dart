import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import 'ink_icon.dart';

/// Tells a child there is more under the fold of a scrolled page (the Rome
/// integration: a picture choice whose last pictures and names are below
/// on a small phone). Over the bottom of [child] (a scrollable), only while
/// more of it lies below: the page's paper fading in, and a small MORE
/// BELOW tab that scrolls on when tapped. The pictures keep their size;
/// nothing is squeezed onto one screen.
class ScrollMoreCue extends StatefulWidget {
  const ScrollMoreCue({super.key, required this.child, this.label = 'MORE BELOW', this.paper = AppColors.paperLight});

  /// A scrollable (or a widget holding one, the first one met is followed).
  final Widget child;

  final String label;

  /// The page's paper, faded in over the content's last line.
  final Color paper;

  /// More than this below the fold (logical pixels) shows the cue.
  static const threshold = 32.0;

  @override
  State<ScrollMoreCue> createState() => _ScrollMoreCueState();
}

class _ScrollMoreCueState extends State<ScrollMoreCue> {
  bool _more = false;
  ScrollPosition? _position;

  bool _onMetrics(ScrollMetrics m, ScrollPosition? position) {
    if (m.axis != Axis.vertical) return false;
    _position = position ?? _position;
    final more = m.extentAfter > ScrollMoreCue.threshold;
    if (more != _more) setState(() => _more = more);
    return false;
  }

  void _scrollOn() {
    final p = _position;
    if (p == null || !p.hasContentDimensions) return;
    p.animateTo(
      math.min(p.maxScrollExtent, p.pixels + p.viewportDimension * 0.6),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _onMetrics(n.metrics, Scrollable.maybeOf(n.context)?.position),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _onMetrics(n.metrics, n.context == null ? null : Scrollable.maybeOf(n.context!)?.position),
        child: Stack(
          children: [
            widget.child,
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                ignoring: !_more,
                child: AnimatedOpacity(
                  opacity: _more ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // The paper fades in over the last line: the eye reads
                      // "it goes on", not "it ends here".
                      IgnorePointer(
                        child: Container(
                          height: AppSpace.lg,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [widget.paper.withValues(alpha: 0), widget.paper.withValues(alpha: 0.92)],
                            ),
                          ),
                        ),
                      ),
                      ColoredBox(
                        color: widget.paper.withValues(alpha: 0.92),
                        child: Center(
                          child: Semantics(
                            button: true,
                            label: '${widget.label}: more to see below',
                            excludeSemantics: true,
                            child: InkWell(
                              key: const ValueKey('scroll-more-cue'),
                              onTap: _scrollOn,
                              borderRadius: BorderRadius.circular(AppRadius.button),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minHeight: 44, minWidth: 120),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xs),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(widget.label, style: AppText.eyebrow(color: AppColors.inkBrown)),
                                      const SizedBox(width: AppSpace.xs),
                                      const InkIcon(InkGlyph.down, size: AppIconSize.small, color: AppColors.inkBrown),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
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
