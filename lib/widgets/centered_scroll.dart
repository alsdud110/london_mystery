import 'package:flutter/widgets.dart';

/// A page whose [children] are one group: centred up and down in the room
/// the page has when they fit, read from the top and scrolled when they
/// don't. The gaps between them stay as given either way.
///
/// The group's own height decides (no fixed heights, no intrinsic
/// measuring): the column is at least as tall as the room, and the spare
/// room is shared above and below it.
class CenteredScroll extends StatelessWidget {
  const CenteredScroll({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
  });

  final List<Widget> children;

  /// The page margins, kept around the group (and at the ends of a scroll).
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: padding,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - padding.vertical).clamp(
              0.0,
              double.infinity,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
