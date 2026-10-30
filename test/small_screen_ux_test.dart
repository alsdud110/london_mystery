import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/widgets/display_sized_image.dart';
import 'package:world_mystery/widgets/scroll_more_cue.dart';

/// The Rome integration's small-screen work: a page that goes on below the
/// fold says so (a picture choice's last pictures and names), and a big
/// picture is decoded at the size it is shown.
void main() {
  Widget page(double contentHeight, {double viewport = 400}) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          height: viewport,
          child: ScrollMoreCue(
            child: SingleChildScrollView(
              key: const ValueKey('page'),
              child: SizedBox(height: contentHeight, child: const Text('the pictures')),
            ),
          ),
        ),
      ),
    ),
  );

  double cueOpacity(WidgetTester t) =>
      t.widget<AnimatedOpacity>(find.ancestor(of: find.text('MORE BELOW'), matching: find.byType(AnimatedOpacity))).opacity;

  testWidgets('MORE BELOW only while there is more below; a tap scrolls on; gone at the end', (t) async {
    await t.pumpWidget(page(1200));
    await t.pumpAndSettle();
    expect(cueOpacity(t), 1, reason: 'more than the screen holds');
    final position = t.state<ScrollableState>(find.descendant(of: find.byKey(const ValueKey('page')), matching: find.byType(Scrollable))).position;
    expect(position.pixels, 0);
    await t.tap(find.byKey(const ValueKey('scroll-more-cue')));
    await t.pumpAndSettle();
    expect(position.pixels, greaterThan(200), reason: 'scrolled on by most of a screen');
    await t.drag(find.byKey(const ValueKey('page')), const Offset(0, -2000));
    await t.pumpAndSettle();
    expect(cueOpacity(t), 0, reason: 'nothing more below');
    expect(t.widget<IgnorePointer>(find.ancestor(of: find.byType(AnimatedOpacity), matching: find.byType(IgnorePointer)).first).ignoring, isTrue,
        reason: 'hidden, it takes no tap from what is under it');
  });

  testWidgets('a page that fits shows no cue', (t) async {
    await t.pumpWidget(page(300));
    await t.pumpAndSettle();
    expect(cueOpacity(t), 0);
  });

  testWidgets('a picture decoded at the width it is shown, times the screen\'s pixel ratio', (t) async {
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(width: 220, height: 330, child: DisplaySizedImage('assets/seasons/season_03_rome/characters/pia_base.png', fit: BoxFit.contain)),
      ),
    ));
    final image = t.widget<Image>(find.byType(Image)).image;
    expect(image, isA<ResizeImage>());
    expect((image as ResizeImage).width, 660, reason: '220 wide on a 3x screen: 660 of the file\'s 1024');
    expect(image.allowUpscaling, isFalse, reason: 'never decoded larger than the file');
    expect((image.imageProvider as AssetImage).assetName, 'assets/seasons/season_03_rome/characters/pia_base.png');
    expect(DisplaySizedImage.decodeWidth(null, 3), isNull, reason: 'a box of no known width: the file\'s own size');
  });
}
