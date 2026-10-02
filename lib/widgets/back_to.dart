import 'package:flutter/widgets.dart';

/// The system back gesture / Android back button on a page.
///
/// Most pages are reached with `go`, so nothing lies under them and a plain
/// back would close the whole app mid-game. Instead [onBack] takes the
/// player where they would expect: the previous step of a mission, the
/// page this one came from, or a question before leaving the case.
///
/// [enabled] false hands back to the normal behaviour (e.g. a mission page
/// already on its first step pops to the map underneath).
class BackTo extends StatelessWidget {
  const BackTo({super.key, required this.onBack, required this.child, this.enabled = true});

  final VoidCallback onBack;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !enabled,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack();
      },
      child: child,
    );
  }
}
