import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../widgets/paper_background.dart';

/// Where a searched picture sits on screen: the picture inside its printed
/// paper edge ([inside]) runs the screen's full [width], and every view of
/// it — the opening one, a pinch, a drag, a double tap — covers the whole
/// viewport, so nothing but the room itself is ever seen behind it.
///
/// The viewer's child is that inside part ([content]); the whole picture
/// ([picture]) lies at [origin] in it, its paper edge outside. Taps on the
/// picture are fractions of the whole picture, as before.
@immutable
class SearchFrame {
  const SearchFrame({
    required this.width,
    required this.aspect,
    required this.inside,
    required this.focus,
    required this.maxScale,
  });

  /// The screen's width (the viewport's).
  final double width;

  /// Width / height of the whole picture.
  final double aspect;

  /// The picture inside its own paper edge (fractions of the picture).
  final Rect inside;

  /// What the opening view shows whole (fractions of the picture): the
  /// scene's opening, every thing to find in it.
  final Rect focus;

  final double maxScale;

  /// The whole picture at scale 1: its inside part as wide as the screen.
  Size get picture {
    final w = width / inside.width;
    return Size(w, w / aspect);
  }

  /// The inside part at scale 1: the viewer's child.
  Size get content => Size(width, picture.height * inside.height);

  /// Where the whole picture lies in [content] (its paper edge outside it).
  Offset get origin => Offset(-inside.left * picture.width, -inside.top * picture.height);

  /// [focus] in [content]'s own space.
  Rect get focusRect {
    final f = focus.intersect(inside);
    final p = picture;
    return Rect.fromLTRB(f.left * p.width, f.top * p.height, f.right * p.width, f.bottom * p.height).shift(origin);
  }

  /// How tall the picture's place on screen would like to be: [focus] as
  /// wide as the screen, with the picture's whole height under it. Shorter
  /// than this, the view simply starts closer; never taller, which would
  /// leave a band of nothing above and below the picture.
  double get idealHeight => content.height * (width / focusRect.width).clamp(1.0, maxScale);

  /// The farthest out the picture goes in [viewport]: still covering it.
  double minScale(Size viewport) => math.min(maxScale, math.max(1.0, viewport.height / content.height));

  /// The opening view: [focus] as large as [viewport] allows, never so far
  /// out that the viewport shows past the picture.
  Matrix4 home(Size viewport) {
    final f = focusRect;
    final s = math.min(viewport.width / f.width, viewport.height / f.height).clamp(minScale(viewport), maxScale);
    return view(s, f.center, viewport.center(Offset.zero), viewport);
  }

  /// The view at scale [s] that puts [point] (in [content]'s space) at
  /// [onScreen], kept inside the picture.
  Matrix4 view(double s, Offset point, Offset onScreen, Size viewport) {
    final dx = (onScreen.dx - s * point.dx).clamp(math.min<double>(0, viewport.width - s * content.width), 0.0);
    final dy = (onScreen.dy - s * point.dy).clamp(math.min<double>(0, viewport.height - s * content.height), 0.0);
    return Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
  }

  /// [current] brought back over the whole of a changed [viewport] (the
  /// panel under it grew or shrank): the same scale where it still covers,
  /// the same spot in the middle.
  Matrix4 keep(Matrix4 current, Size viewport) {
    final s0 = current.getMaxScaleOnAxis();
    final t = current.getTranslation();
    final centre = viewport.center(Offset.zero);
    final point = Offset((centre.dx - t.x) / s0, (centre.dy - t.y) / s0);
    return view(s0.clamp(minScale(viewport), maxScale), point, centre, viewport);
  }
}

/// A searched place's page, one sheet from the bar down: the picture full
/// width at the top, as tall as it would like ([idealHeight] for the
/// screen's width) while the words keep their own height; under it, on the
/// page's paper, the [caption] (what to do, read with the picture), and at
/// the bottom, in reach of the thumb, the [actions] (the hints opened, the
/// report and the tips). Paper is all there is between them: no band of
/// anything else around the picture.
///
/// The [note] (what the last tap found) is pencilled on the page under the
/// caption when there is room for it there, the picture left clear; on a
/// short screen it lies over the top of the picture instead.
class SearchStage extends StatelessWidget {
  const SearchStage({
    super.key,
    required this.idealHeight,
    required this.picture,
    required this.caption,
    required this.actions,
    required this.note,
  });

  final double Function(double width) idealHeight;

  /// The picture's place, built for its size on screen.
  final Widget Function(BuildContext context, Size viewport) picture;
  final Widget caption;
  final Widget actions;
  final Widget note;

  /// The note's margin from the screen's sides, and from what is above it.
  static const noteInset = AppSpace.md;
  static const noteGap = AppSpace.lg;

  @override
  Widget build(BuildContext context) {
    return CustomMultiChildLayout(
      delegate: _StageLayout(idealHeight),
      children: [
        LayoutId(
          id: _Part.paper,
          child: const PaperBackground(child: SizedBox.expand()),
        ),
        LayoutId(
          id: _Part.picture,
          child: ClipRect(child: LayoutBuilder(builder: (context, box) => picture(context, box.biggest))),
        ),
        LayoutId(id: _Part.caption, child: InkSurface(night: false, child: caption)),
        LayoutId(
          id: _Part.actions,
          // Clear of the system's bar at the bottom (the paper runs under it).
          child: InkSurface(night: false, child: SafeArea(top: false, child: actions)),
        ),
        LayoutId(id: _Part.note, child: IgnorePointer(child: note)),
      ],
    );
  }
}

enum _Part { paper, picture, caption, actions, note }

class _StageLayout extends MultiChildLayoutDelegate {
  _StageLayout(this.idealHeight);

  final double Function(double width) idealHeight;

  @override
  void performLayout(Size size) {
    BoxConstraints words(double most) =>
        BoxConstraints(minWidth: size.width, maxWidth: size.width, maxHeight: math.max(0.0, most));
    final actions = layoutChild(_Part.actions, words(size.height));
    final caption = layoutChild(_Part.caption, words(size.height - actions.height));
    final h = math.max(0.0, math.min(idealHeight(size.width), size.height - actions.height - caption.height));
    layoutChild(_Part.picture, BoxConstraints.tight(Size(size.width, h)));
    layoutChild(_Part.paper, BoxConstraints.tight(Size(size.width, size.height - h)));
    positionChild(_Part.picture, Offset.zero);
    positionChild(_Part.paper, Offset(0, h));
    positionChild(_Part.caption, Offset(0, h));
    positionChild(_Part.actions, Offset(0, size.height - actions.height));

    const inset = SearchStage.noteInset;
    const gap = SearchStage.noteGap;
    final note = layoutChild(
      _Part.note,
      // Its own height (the slip centres itself in what it is given).
      BoxConstraints(maxWidth: math.max(0.0, size.width - 2 * inset)),
    );
    final free = size.height - actions.height - (h + caption.height);
    positionChild(
      _Part.note,
      free >= note.height + 2 * gap
          ? Offset(inset, h + caption.height + gap)
          : Offset(inset, AppSpace.sm),
    );
  }

  // The ideal height is a fresh closure on every build; working it out
  // again is cheap.
  @override
  bool shouldRelayout(_StageLayout oldDelegate) => true;
}
