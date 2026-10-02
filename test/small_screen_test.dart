import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';

import 'full_playthrough_test.dart' show tapText, wait;
import 'helpers.dart';

/// The smallest supported phone (360×640) with the keyboard up.
void main() {
  testWidgets('register: with the keyboard up, the name line and the button stay above the keys', (t) async {
    t.view.physicalSize = const Size(1080, 1920);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(overrides: await testOverrides(), child: const LondonMysteryApp()));
    await wait(t, const Duration(milliseconds: 300));
    await tapText(t, 'START ADVENTURE');
    // The keyboard takes about 300 dp of the 640.
    // The keyboard opens when the name line is tapped (no autofocus).
    await t.tap(find.byType(TextField));
    await t.pump();
    t.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(t.view.resetViewInsets);
    await wait(t, const Duration(milliseconds: 600));
    expect(t.takeException(), isNull, reason: 'no overflow above the keyboard');
    for (final f in [find.byType(TextField), find.text('OPEN THE CASEBOOK')]) {
      final r = t.getRect(f);
      expect(r.top, greaterThanOrEqualTo(0), reason: '$f is not pushed off the top');
      expect(r.bottom, lessThanOrEqualTo(640 - 300), reason: '$f sits above the keyboard');
    }
    await wait(t, const Duration(seconds: 3));
  });
}
