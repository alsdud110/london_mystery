import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/landmark_art.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// Case 01's Case Closed file (2026-10-19): the small tilted photo of the
/// open box by the detective's name (the stamp coming down across it) gives
/// way to the Missing Crown alone, under the case's title, on the file's own
/// paper — the crown cut out of `objects/crown.png` (kept). Every other case
/// keeps its photo.
void main() {
  final catalog = MockEpisodeRepository.bundled();

  test('the crown cut out: transparent around it, the source kept', () async {
    final file = ArtAssets.caseClosedEmblems['ep01']!;
    expect(file, 'assets/art/objects/crown_cutout.png');
    expect(ArtAssets.caseClosedEmblems.keys, ['ep01'], reason: 'Case 01 only');
    expect(File(ArtAssets.objects['crown']!).lengthSync(), 2101713, reason: 'the source as it was');
    final codec = await ui.instantiateImageCodec(File(file).readAsBytesSync());
    final img = (await codec.getNextFrame()).image;
    final px = (await img.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!.buffer.asUint8List();
    int alpha(int x, int y) => px[(y * img.width + x) * 4 + 3];
    expect((img.width, img.height), (512, 512));
    for (final (x, y) in [(0, 0), (511, 0), (0, 511), (511, 511), (256, 3), (3, 256)]) {
      expect(alpha(x, y), 0, reason: '($x, $y)');
    }
    // The band across the crown's lower part, and the orb on top: solid;
    // the arches' openings: the paper shows through.
    expect(alpha(256, 440), 255, reason: 'the band');
    expect(alpha(256, 90), 255, reason: 'the orb');
  });

  Future<void> open(WidgetTester t, String id, Size size, {double textScale = 1}) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    t.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    final e = catalog.firstWhere((c) => c.id == id);
    final upTo = catalog.indexOf(e);
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(prefs: {
        AppConstants.progressKeyFor(id): jsonEncode(GameProgress(
          detectiveName: 'MINYOUNG',
          introSeen: true,
          completedMissionIds: [for (final m in e.allMissions) m.id],
          startedAt: DateTime(2026, 9, 29, 10),
          completedAt: DateTime(2026, 9, 29, 10, 30),
          playMillis: 0,
        ).toJson()),
        if (id != AppConstants.currentEpisodeId)
          AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINYOUNG').toJson()),
        AppConstants.seasonStorageKey: jsonEncode(
          SeasonProgress(activeEpisodeId: id, solvedEpisodeIds: [for (final c in catalog.take(upTo + 1)) c.id]).toJson(),
        ),
      }),
      child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
    ));
    await wait(t, const Duration(milliseconds: 300));
    ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first).read(routerProvider).go(Routes.solved);
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
    await wait(t, const Duration(milliseconds: 3200));
  }

  for (final (size, scale) in const [(Size(360, 640), 1.0), (Size(360, 640), 1.3), (Size(430, 932), 1.0), (Size(768, 1024), 1.0)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}@$scale';
    testWidgets('Case 01 $tag: the crown under the title, no photo; the file as before', (t) async {
      await open(t, 'ep01', size, textScale: scale);
      expect(t.takeException(), isNull, reason: 'no overflow');
      final crown = find.byKey(const ValueKey('case-closed-emblem'));
      expect(crown, findsOneWidget);
      expect(find.byType(LandmarkArt), findsNothing, reason: 'no case photo');
      expect(find.byWidgetPredicate((w) => w is Transform && w.child is Container), findsNothing, reason: 'nothing tilted in a frame');
      // Under the title, centred in the file, a fair size.
      final title = t.getRect(find.text('THE MISSING CROWN'));
      final box = t.getRect(crown);
      expect(box.top, greaterThan(title.bottom - 1));
      final file = t.getRect(find.ancestor(of: crown, matching: find.byType(Column)).first);
      expect(box.center.dx, moreOrLessEquals(file.center.dx, epsilon: 1));
      expect(box.width, inInclusiveRange(96, 150));
      // The rest of the file as before.
      for (final s in ['CASE CLOSED', 'MINYOUNG', 'Missions', 'Clues Found', 'Evidence', 'Hints', 'Time', 'XP']) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
      expect(find.text('5 / 5'), findsOneWidget);
      expect(find.text('6 / 6'), findsOneWidget);
      expect(find.text('SOLVED'), findsOneWidget, reason: 'the stamp still comes down');
      expect(t.getRect(find.text('SOLVED')).overlaps(box), isFalse, reason: 'never on the crown');
      await capture(t, 'case01_case_closed_$tag');
    });
  }

  testWidgets('Case 05 keeps its case photo', (t) async {
    await open(t, 'ep05', const Size(360, 640));
    expect(find.byKey(const ValueKey('case-closed-emblem')), findsNothing);
    expect(find.byType(LandmarkArt), findsOneWidget);
  });
}
