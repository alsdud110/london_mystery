import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/theme/app_theme.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/mission/widgets/answer_feedback.dart';
import 'package:london_mystery/widgets/badge_medal.dart';

import 'helpers.dart';

/// A small phone (360 × 640 logical pixels).
void smallPhone(WidgetTester t) {
  t.view.physicalSize = const Size(1080, 1920);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

void main() {
  testWidgets('the "Not quite!" sheet fits on a small phone with both buttons', (t) async {
    smallPhone(t);
    late BuildContext context;
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(),
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Builder(builder: (c) {
          context = c;
          return const Scaffold();
        }),
      ),
    ));
    final choice = showTryAgainSheet(context, hintAvailable: true);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull, reason: 'no overflow');
    expect(find.text('TRY AGAIN'), findsOneWidget);
    await t.tap(find.text('GET A TIP'));
    await t.pumpAndSettle();
    expect(await choice, TryAgainChoice.hint);
  });

  testWidgets('every badge medal has the same size, whatever its label', (t) async {
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Wrap(children: [for (final b in GameBadge.values) BadgeMedal(badge: b, size: 58)]),
      ),
    ));
    final sizes = {for (final b in GameBadge.values) t.getSize(find.byWidgetPredicate((w) => w is BadgeMedal && w.badge == b))};
    expect(sizes, hasLength(1), reason: 'sizes: $sizes');
  });
}
