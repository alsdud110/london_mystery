import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/theme/app_colors.dart';
import 'package:london_mystery/widgets/game_button.dart';
import 'package:london_mystery/widgets/ink_icon.dart';
import 'package:london_mystery/widgets/paper.dart';
import 'package:london_mystery/widgets/paper_background.dart';

import 'helpers.dart';

/// The outline button ("OPEN MY NOTEBOOK") picks its ink from the surface
/// it sits on, in one shared style for every case.
void main() {
  Future<void> pump(WidgetTester t, Widget child) async {
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(),
      child: MaterialApp(home: Scaffold(body: child)),
    ));
  }

  const button = GameButton(label: 'OPEN MY NOTEBOOK', glyph: InkGlyph.notebook, style: GameButtonStyle.outline, onPressed: null);

  Color textColor(WidgetTester t) => t.widget<Text>(find.text('OPEN MY NOTEBOOK')).style!.color!;
  Color iconColor(WidgetTester t) => t.widget<InkIcon>(find.byType(InkIcon)).color!;

  /// WCAG relative-luminance contrast ratio.
  double contrast(Color a, Color b) {
    final (l1, l2) = (a.computeLuminance(), b.computeLuminance());
    return (l1 > l2 ? l1 + 0.05 : l2 + 0.05) / (l1 > l2 ? l2 + 0.05 : l1 + 0.05);
  }

  testWidgets('on the night background: gold ink with readable contrast', (t) async {
    await pump(t, const PaperBackground(night: true, child: Center(child: button)));
    expect(textColor(t), AppColors.goldLight);
    expect(iconColor(t), AppColors.goldLight);
    expect(contrast(textColor(t), AppColors.navy), greaterThanOrEqualTo(4.5));
  });

  testWidgets('on paper, and on paper laid on the night desk: the original ink', (t) async {
    await pump(t, const PaperBackground(child: Center(child: button)));
    expect(textColor(t), AppColors.ink);
    expect(contrast(textColor(t), AppColors.paper), greaterThanOrEqualTo(4.5));

    await pump(t, const PaperBackground(night: true, child: Center(child: PaperSheet(child: button))));
    expect(textColor(t), AppColors.ink);
  });

  testWidgets('the size does not change with the surface', (t) async {
    await pump(t, const PaperBackground(child: SizedBox(width: 320, child: button)));
    final paper = t.getSize(find.byType(GameButton));
    await pump(t, const PaperBackground(night: true, child: SizedBox(width: 320, child: button)));
    expect(t.getSize(find.byType(GameButton)), paper);
  });
}
