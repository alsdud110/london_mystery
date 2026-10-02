import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/mission/widgets/answer_feedback.dart';
import 'package:london_mystery/widgets/game_button.dart';

import 'helpers.dart';

/// The "WELL DONE" moment never makes a child wait, and continues once.
void main() {
  Future<({Future<void> closed, int Function() pops})> open(WidgetTester t, {bool reduceMotion = false}) async {
    late BuildContext context;
    var pops = 0;
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(),
      child: MaterialApp(
        navigatorObservers: [_PopCounter(() => pops++)],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: Builder(builder: (c) {
          context = c;
          return const Scaffold();
        }),
      ),
    ));
    final closed = showSuccessOverlay(
      context,
      detectiveName: 'KIM',
      message: 'The thief is going to the British Museum.',
      buttonLabel: 'CONTINUE',
      xp: const XpBreakdown(base: 100, noHintBonus: 30, speedBonus: 15),
    );
    await t.pump(); // the overlay route
    await t.pump(const Duration(milliseconds: 350)); // faded in
    return (closed: closed, pops: () => pops);
  }

  double buttonOpacity(WidgetTester t) => t
      .widget<Opacity>(find.ancestor(of: find.byType(GameButton), matching: find.byType(Opacity)).first)
      .opacity;

  testWidgets('a tap on the moment finishes it at once', (t) async {
    await open(t);
    expect(buttonOpacity(t), 0, reason: 'the button comes last');
    await t.tapAt(const Offset(20, 20));
    await t.pump();
    expect(buttonOpacity(t), 1, reason: 'tap: everything is shown');
    expect(find.text('+145 XP'), findsOneWidget, reason: 'the XP is counted up in full');
    await t.pumpAndSettle();
  });

  testWidgets('CONTINUE closes the overlay once, however often it is tapped', (t) async {
    final o = await open(t);
    await t.tapAt(const Offset(20, 20));
    await t.pump();
    await t.tap(find.text('CONTINUE'));
    await t.tap(find.text('CONTINUE'), warnIfMissed: false);
    await t.pumpAndSettle();
    await o.closed;
    expect(o.pops(), 1, reason: 'only the overlay is closed, not the page under it');
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('with reduced motion the finished page is shown straight away', (t) async {
    await open(t, reduceMotion: true);
    expect(buttonOpacity(t), 1);
    expect(find.text('+145 XP'), findsOneWidget);
    await t.pumpAndSettle();
  });
}

class _PopCounter extends NavigatorObserver {
  _PopCounter(this.onPop);

  final VoidCallback onPop;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => onPop();
}
