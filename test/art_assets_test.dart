import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/ink_icon.dart';
import 'package:london_mystery/widgets/landmark_art.dart';
import 'package:london_mystery/widgets/symbol_icon.dart';

/// The artwork replacement points: until a file is added, every picture
/// looks exactly as it did; a file that is listed must exist; a missing
/// file never leaves an empty frame.
void main() {
  Future<List<int>> draw(WidgetTester t, Artwork a) async {
    await t.pumpWidget(RepaintBoundary(
      key: const ValueKey('art'),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 160, height: 120, child: LandmarkArt(a)),
      ),
    ));
    return (await t.runAsync(() async {
      final image = await t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('art'))).toImage();
      return (await image.toByteData())!.buffer.asUint8List().toList();
    }))!;
  }

  testWidgets('a place without its own picture looks exactly like its stand-in scene', (t) async {
    expect(LandmarkArt.standIns.keys.toSet(), {
      Artwork.boathouse,
      Artwork.roseGarden,
      Artwork.waitingRoom,
      Artwork.staffRoom,
      Artwork.courtyard,
      Artwork.dressingRoom,
    });
    for (final MapEntry(key: place, value: standIn) in LandmarkArt.standIns.entries) {
      expect(await draw(t, place), await draw(t, standIn), reason: '$place');
      expect(LandmarkArt.standIns.containsKey(standIn), isFalse, reason: 'a stand-in is a real drawing');
    }
  });

  testWidgets('every scene draws without errors', (t) async {
    for (final a in Artwork.values) {
      await draw(t, a);
      expect(t.takeException(), isNull, reason: '$a');
    }
  });

  test('the six places are used by their missions', () {
    final scenes = {for (final e in MockEpisodeRepository.bundled()) for (final m in e.allMissions) m.id: m.scene};
    expect(scenes['ep07_m2'], Artwork.boathouse);
    expect(scenes['ep07_m3'], Artwork.roseGarden);
    expect(scenes['ep08_m2'], Artwork.waitingRoom);
    expect(scenes['ep09_m2'], Artwork.staffRoom);
    expect(scenes['ep09_m3'], Artwork.courtyard);
    expect(scenes['ep11_m2'], Artwork.dressingRoom);
  });

  test('every listed file exists and its folder is bundled in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final files = [
      ...ArtAssets.scenes.values,
      ...ArtAssets.solvedScenes.values,
      ...ArtAssets.symbols.values,
      ...ArtAssets.badges.values,
    ];
    for (final path in files) {
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(pubspec, contains('- ${path.substring(0, path.lastIndexOf('/') + 1)}'), reason: path);
      expect(path, matches(RegExp(r'\.(png|webp|jpe?g)$')), reason: 'no SVG: it needs a new package');
    }
    // Keys are real: symbols the game uses, badges that exist.
    for (final key in ArtAssets.symbols.keys) {
      expect(GameSymbol.of(key).label, isNot('Mystery'), reason: key);
    }
    expect(GameBadge.values, containsAll(ArtAssets.badges.keys));
  });

  test('until a picture is added, the drawing (or monogram) is used everywhere', () {
    for (final a in Artwork.values) {
      expect(ArtAssets.scene(a), ArtAssets.scenes[a]);
    }
    expect(GameSymbol.of('park').asset, ArtAssets.symbols['park']);
    // The solved clock keeps its drawn change unless a solved picture exists.
    expect(ArtAssets.scene(Artwork.clockFace, solved: 1), ArtAssets.solvedScenes[Artwork.clockFace]);
  });

  testWidgets('a listed file that is missing falls back to the drawing', (t) async {
    await t.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: InkMark(glyph: InkGlyph.raven, monogram: 'R', size: 40, asset: 'assets/art/symbols/missing.png'),
      ),
    ));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await t.pump();
    expect(find.byType(InkIcon), findsOneWidget, reason: 'the raven glyph, not an empty box');

    await t.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: InkMark(glyph: null, monogram: 'P', size: 40, asset: 'assets/art/symbols/missing.png')),
    ));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await t.pump();
    expect(find.text('P'), findsOneWidget, reason: 'the monogram');
  });
}
