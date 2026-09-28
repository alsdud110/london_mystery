import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/features/game_master/parent_gate.dart';

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

  testWidgets('cancel closes the check cleanly and refuses', (t) async {
    final result = await openGate(t);
    await t.enterText(find.byType(TextField), gateAnswer(t));
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(await result, isFalse);
    expect(t.takeException(), isNull);
  });
}
