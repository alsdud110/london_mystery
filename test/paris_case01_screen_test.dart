import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/features/season/paris_case01_screen.dart';

void main() {
  testWidgets('Paris Case 01 preview plays from landing to case closed', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ParisCase01Screen()));
    expect(find.text('The Ticking Watch'), findsOneWidget);
    await tester.ensureVisible(find.text('BEGIN INVESTIGATION'));
    await tester.tap(find.text('BEGIN INVESTIGATION'));
    await tester.pumpAndSettle();

    for (final name in ['PLATFORM · 10:00', 'HALL · 10:00', 'OLD · 9:00']) {
      await tester.ensureVisible(find.text(name));
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('READ THE NOTICE'));
    await tester.tap(find.text('READ THE NOTICE'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('REPORT THE OLD CLOCK'));
    await tester.tap(find.text('REPORT THE OLD CLOCK'));
    await tester.pumpAndSettle();
    expect(find.text('The Lost Ticket'), findsOneWidget);

    await tester.ensureVisible(find.text('TURN OVER THE TICKET'));
    await tester.tap(find.text('TURN OVER THE TICKET'));
    await tester.pumpAndSettle();
    for (final name in [
      'The hall clock struck ten',
      'The man entered the waiting room',
      'The old clock showed nine',
    ]) {
      await tester.ensureVisible(find.text(name));
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('CHECK THE TIMELINE'));
    await tester.tap(find.text('CHECK THE TIMELINE'));
    await tester.pumpAndSettle();
    expect(find.text('The Clockmaker’s Mark'), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      await tester.ensureVisible(find.text('+ 15 MIN'));
      await tester.tap(find.text('+ 15 MIN'));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('SET THE TIME'));
    await tester.tap(find.text('SET THE TIME'));
    await tester.pumpAndSettle();
    expect(find.text('The Hidden Compartment'), findsOneWidget);

    for (final letter in ['T', 'I', 'M', 'E']) {
      await tester.ensureVisible(find.widgetWithText(OutlinedButton, letter));
      await tester.tap(find.widgetWithText(OutlinedButton, letter));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('OPEN THE COMPARTMENT'));
    await tester.tap(find.text('OPEN THE COMPARTMENT'));
    await tester.pumpAndSettle();
    expect(find.text('CASE CLOSED'), findsWidgets);
    expect(find.text('The Ticking Watch'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
