import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/features/game_master/parent_gate.dart';

import 'helpers.dart';

/// Opens the grown-ups check and returns its pending result.
Future<Future<bool>> openGate(WidgetTester t) async {
  late BuildContext context;
  await t.pumpWidget(MaterialApp(home: Builder(builder: (c) {
    context = c;
    return const Scaffold();
  })));
  final result = ParentGate.show(context);
  await t.pumpAndSettle();
  return result;
}

/// Reads "What is a × b?" from the dialog and returns the right answer.
String gateAnswer(WidgetTester t) {
  final question = t.widget<Text>(find.textContaining('What is')).data!;
  final m = RegExp(r'(\d+) × (\d+)').firstMatch(question)!;
  return '${int.parse(m[1]!) * int.parse(m[2]!)}';
}

void main() {
  testWidgets('submitting from the keyboard closes the check cleanly', (t) async {
    final result = await openGate(t);
    await t.enterText(find.byType(TextField), gateAnswer(t));
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect(await result, isTrue);
    expect(t.takeException(), isNull);
  });

  testWidgets('OK with a wrong answer closes the check cleanly and refuses', (t) async {
    final result = await openGate(t);
    await t.enterText(find.byType(TextField), '1');
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
    expect(await result, isFalse);
    expect(t.takeException(), isNull);
  });

  testWidgets('the keyboard of the check does not squeeze the title page', (t) async {
    // A small phone; the keyboard takes about 300 dp, as in the screenshot.
    t.view.physicalSize = const Size(1080, 1920);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(overrides: await testOverrides(), child: const LondonMysteryApp()));
    await t.pumpAndSettle();
    // The seal on the title page: long-press opens the grown-ups check.
    await t.longPress(find.byWidgetPredicate((w) => w is GestureDetector && w.onLongPress != null));
    await t.pumpAndSettle();
    expect(find.textContaining('What is'), findsOneWidget);
    t.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(t.view.resetViewInsets);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull, reason: 'no overflow behind the check');
    for (final f in [find.byType(TextField), find.text('OK')]) {
      expect(t.getRect(f).bottom, lessThanOrEqualTo(640 - 300), reason: 'the answer and OK sit above the keyboard');
    }
  });

  testWidgets('cancel closes the check cleanly and refuses', (t) async {
    final result = await openGate(t);
    await t.enterText(find.byType(TextField), gateAnswer(t));
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(await result, isFalse);
    expect(t.takeException(), isNull);
  });
}
