import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/router/app_router.dart';

import 'helpers.dart';

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final topPadding in [0.0, 141.0]) {
      testWidgets('$platform status bar through title transitions, inset $topPadding', (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3;
        tester.view.padding = FakeViewPadding(top: topPadding);
        addTearDown(tester.view.reset);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        final container = ProviderContainer(overrides: await testOverrides());
        addTearDown(container.dispose);
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: const WorldMysteryApp(),
        ));

        void expectWhite() {
          if (platform == TargetPlatform.iOS) {
            expect(SystemChrome.latestStyle?.statusBarBrightness, Brightness.dark);
            final regions = tester.widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
              find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
            );
            expect(regions.first.value.statusBarBrightness, Brightness.dark,
                reason: 'Even before/without a painted title, the fallback must be white');
            expect(regions.first.value.statusBarIconBrightness, isNull);
          }
        }
        expectWhite();
        for (var frame = 0; frame < 30; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          expectWhite();
        }
        if (platform == TargetPlatform.android) {
          expect(find.byType(AnnotatedRegion<SystemUiOverlayStyle>), findsNothing);
        }
        final router = container.read(routerProvider);
        router.go(Routes.register);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        if (platform == TargetPlatform.iOS) {
          final regions = tester.widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
          ).toList();
          expect(regions.first.value.statusBarBrightness, Brightness.light,
              reason: 'Ordinary routes keep their original dark-text fallback');
          expect(regions.length, greaterThan(1));
          expect(SystemChrome.latestStyle?.statusBarBrightness,
              regions.last.value.statusBarBrightness,
              reason: 'The existing AppBar must still override the fallback');
        }
        router.go(Routes.start);
        await tester.pump();
        expectWhite();
        for (var frame = 0; frame < 30; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          expectWhite();
        }
        await tester.pumpWidget(const SizedBox.shrink());
        debugDefaultTargetPlatformOverride = null;
      });
    }
  }
}
