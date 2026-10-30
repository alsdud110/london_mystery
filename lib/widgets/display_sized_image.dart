import 'package:flutter/widgets.dart';

/// An asset picture decoded at the size it is shown, not its file's: its
/// box's width times the screen's pixel ratio (the pattern of
/// `exhibit.dart` and `season_props.dart`, made one widget in the Rome
/// integration). A 1024 × 1536 portrait shown 220 wide on a 3× phone
/// decodes 660 wide: under half the memory, and sooner on screen.
///
/// Only where the picture is never shown wider than its box ([BoxFit.contain],
/// [BoxFit.fill], [BoxFit.fitWidth], [BoxFit.scaleDown], or a box of the
/// picture's own shape): a [BoxFit.cover] backdrop may be shown wider, and
/// keeps its own decode size.
class DisplaySizedImage extends StatelessWidget {
  const DisplaySizedImage(
    this.file, {
    super.key,
    this.imageKey,
    this.fit,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.excludeFromSemantics = false,
    this.errorBuilder,
  });

  final String file;

  /// The key of the [Image] itself (tests find it by it).
  final Key? imageKey;
  final BoxFit? fit;
  final AlignmentGeometry alignment;

  /// The width it is shown at, when known; else its box's.
  final double? width;
  final double? height;
  final bool excludeFromSemantics;
  final ImageErrorWidgetBuilder? errorBuilder;

  /// The decode width for [shown] logical pixels at [dpr] (null: unknown).
  static int? decodeWidth(double? shown, double dpr) =>
      shown == null || !shown.isFinite || shown <= 0 ? null : (shown * dpr).ceil();

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    Widget image(double? shown) => Image.asset(
      file,
      key: imageKey,
      fit: fit,
      alignment: alignment,
      width: width,
      height: height,
      cacheWidth: decodeWidth(shown, dpr),
      excludeFromSemantics: excludeFromSemantics,
      errorBuilder: errorBuilder,
    );
    if (width != null) return image(width);
    return LayoutBuilder(builder: (context, box) => image(box.hasBoundedWidth ? box.maxWidth : null));
  }
}
