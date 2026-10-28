import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/mock/season1/season1_dialogues.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/backdrop.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/scene_explore.dart' show ScenePixels;
import 'package:world_mystery/widgets/art_assets.dart';
import 'package:world_mystery/widgets/backdrop_art.dart';
import 'package:world_mystery/widgets/landmark_art.dart';
import 'package:world_mystery/widgets/place_art.dart';
import 'package:world_mystery/widgets/place_scenery.dart';

/// The screens a backdrop must look right on (portrait phones and a tablet).
const sizes = [Size(375, 667), Size(393, 852), Size(430, 932), Size(412, 915), Size(820, 1180)];

typedef Backdrop = ({String where, String file, ScenePixels pixels, BackdropLook look});

/// Every picture laid full screen behind the story, in every case of every
/// season: the case's opening, each Discovery Moment, each scene after a
/// mission (Paris: its story picture; London: the place it goes on to).
List<Backdrop> allBackdrops() {
  final out = <Backdrop>[];
  void artwork(String where, Artwork? a) {
    if (a == null || !LandmarkArt.hasPicture(a)) return;
    final file = ArtAssets.scene(a)!;
    final art = BackdropArt.of(file);
    expect(art, isNotNull, reason: '$where: $file has no backdrop look');
    out.add((where: '$where ${a.name}', file: file, pixels: art!.pixels, look: art.look));
  }

  for (final s in SeasonCatalog.all) {
    for (final MapEntry(key: id, value: json) in s.episodes.entries) {
      final e = Episode.fromJson({...json, 'seasonId': s.id});
      artwork('$id intro', e.introScene);
      for (final m in e.allMissions) {
        if (!m.isFinal) artwork('${m.id} discovery', PlaceArt.sceneryOf(m));
        if (m.transition.isEmpty) continue;
        final after = SeasonCatalog.storyScenes(m)?.after;
        if (after != null) {
          if (after.cutOut) continue; // an object, whole in the night
          expect(BackdropArt.of(after.file), isNotNull, reason: '${m.id} story: ${after.file} has no backdrop look');
          out.add((where: '${m.id} story', file: after.file, pixels: after.pixels, look: BackdropArt.storyLook(after)));
        } else {
          final next = m.nextMissionId == null ? null : e.missionById(m.nextMissionId!);
          artwork('${m.id} story', m.isFinal ? PlaceArt.sceneryOf(m) : next == null ? null : PlaceArt.sceneryOf(next));
        }
      }
    }
  }
  return out;
}

bool inside(Rect inner, Rect outer, [double e = 1e-6]) =>
    inner.left >= outer.left - e && inner.top >= outer.top - e && inner.right <= outer.right + e && inner.bottom <= outer.bottom + e;

/// The largest enlargement a backdrop photo may take (screen points per
/// picture pixel): a 1536-wide picture across an 820-wide tablet with room
/// to spare, never a close-up blown into a blur.
const maxPhotoScale = 1.6;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every backdrop picture is listed at its real pixel size', () async {
    final files = {
      for (final b in allBackdrops()) b.file,
      for (final d in season1Dialogues.values) d.background,
    };
    expect(files.length, greaterThan(60));
    for (final file in files) {
      final art = BackdropArt.of(file);
      expect(art, isNotNull, reason: file);
      final bytes = (await rootBundle.load(file)).buffer.asByteData();
      // A PNG's width and height, in its header.
      expect(bytes.getUint32(16).toDouble(), art!.pixels.width, reason: '$file width');
      expect(bytes.getUint32(20).toDouble(), art.pixels.height, reason: '$file height');
    }
  });

  group('on every screen size', () {
    // (Gathered inside the first test: its checks are tests' own.)
    late final backdrops = allBackdrops();

    test('only the allowed part of a picture is ever on screen, the sharp picture or its fill', () {
      for (final b in backdrops) {
        for (final size in sizes) {
          final at = BackdropLayout.of(size, b.pixels, b.look);
          expect(inside(at.window, b.look.bounds), isTrue, reason: '${b.where} at $size: ${at.window}');
          final fill = at.fill;
          if (fill != null) {
            // The fill covers the screen with the allowed part only.
            final shown = Rect.fromLTRB(
              (0 - fill.left) / fill.width,
              (0 - fill.top) / fill.height,
              (size.width - fill.left) / fill.width,
              (size.height - fill.top) / fill.height,
            );
            expect(inside(shown, b.look.bounds), isTrue, reason: '${b.where} fill at $size: $shown');
          }
        }
      }
    });

    test('its focus (the landmark, the clue) is on screen whole', () {
      for (final b in backdrops) {
        for (final size in sizes) {
          final at = BackdropLayout.of(size, b.pixels, b.look);
          final focus = b.look.focus.intersect(b.look.bounds);
          expect(inside(focus, at.window, 1e-3), isTrue, reason: '${b.where} at $size: focus $focus, shown ${at.window}');
        }
      }
    });

    test('the screen is never left bare: the picture covers it, or its fill does', () {
      for (final b in backdrops) {
        for (final size in sizes) {
          final at = BackdropLayout.of(size, b.pixels, b.look);
          if (!at.filled) {
            expect(inside(Offset.zero & size, at.shown, 0.5), isTrue, reason: '${b.where} at $size: ${at.shown}');
          }
        }
      }
    });

    test('never blown up: a print at most ${BackdropArt.printMaxScale}×, a photo at most $maxPhotoScale×', () {
      for (final b in backdrops) {
        final print = b.look.bounds == BackdropArt.printScene;
        for (final size in sizes) {
          final at = BackdropLayout.of(size, b.pixels, b.look);
          expect(at.scale, lessThanOrEqualTo((print ? BackdropArt.printMaxScale : maxPhotoScale) + 1e-9),
              reason: '${b.where} at $size');
        }
      }
    });

    test('a London print never shows its paper edge or its name plate', () {
      for (final file in ArtAssets.landmarkScenes.values) {
        final art = BackdropArt.of(file)!;
        expect(art.look.bounds, BackdropArt.printScene, reason: file);
        for (final size in sizes) {
          expect(inside(BackdropLayout.of(size, art.pixels, art.look).window, BackdropArt.printScene), isTrue);
        }
      }
    });

    test('a Season 1 picture printed on paper never shows its worn edge', () {
      final papers = [...ArtAssets.insideScenes.values, ...ArtAssets.objectScenes.values, ArtAssets.marketHall]
          .where((f) => BackdropArt.of(f) != null && !ArtAssets.landmarkScenes.containsValue(f));
      expect(papers.length, greaterThanOrEqualTo(15));
      for (final file in papers) {
        final art = BackdropArt.of(file)!;
        expect(art.look.bounds, BackdropArt.paperEdge, reason: file);
        for (final size in sizes) {
          expect(inside(BackdropLayout.of(size, art.pixels, art.look).window, BackdropArt.paperEdge), isTrue, reason: '$file at $size');
        }
      }
    });
  });

  group('Case 09: the garden\'s post clock (ten past ten) is never shown', () {
    const garden = 'assets/seasons/season_02_paris/cases/case_09/garden_model_view.png';
    const clockLeft = 1412 / 1536;

    test('every look its picture is laid by stops left of the clock', () {
      final looks = [
        BackdropArt.of(garden)!.look,
        for (final s in SeasonCatalog.all)
          for (final scenes in s.storyScenes.values)
            for (final p in [?scenes.place, ?scenes.after, ?scenes.next])
              if (p.file == garden) BackdropArt.storyLook(p),
      ];
      for (final look in looks) {
        expect(look.bounds.right, lessThanOrEqualTo(BackdropArt.gardenNoClock.right));
        for (final size in [...sizes, const Size(320, 568), const Size(1024, 1366)]) {
          final at = BackdropLayout.of(size, const ScenePixels(1536, 1024), look);
          expect(at.window.right, lessThan(clockLeft), reason: 'at $size');
        }
      }
    });

    // The garden picture swapped (for this test only) for one painted blue
    // where it may be shown and red where it may not: not one red pixel on
    // screen, the picture or the blurred room around it.
    for (final size in sizes) {
      testWidgets('the screen at ${size.width.toInt()}×${size.height.toInt()} shows none of it', (t) async {
        final probe = await t.runAsync(() => _probe(1536, 1024, BackdropArt.gardenNoClock.right));
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        const shot = ValueKey('shot');
        await t.pumpWidget(
          DefaultAssetBundle(
            bundle: _OneFile(garden, probe!),
            child: const MediaQuery(
              data: MediaQueryData(),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: RepaintBoundary(key: shot, child: PlaceScenery(Artwork.luxembourgGarden, map: null)),
              ),
            ),
          ),
        );
        for (var i = 0; i < 4; i++) {
          await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
          await t.pump();
        }
        expect(find.byWidgetPredicate((w) => w is LandmarkArt && w.artwork == Artwork.luxembourgGarden), findsOneWidget);
        final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(shot));
        final pixels = await t.runAsync(() async {
          final image = await boundary.toImage();
          return (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        });
        var blue = 0, red = 0;
        for (var i = 0; i < pixels!.lengthInBytes; i += 4) {
          final r = pixels.getUint8(i), b = pixels.getUint8(i + 2);
          if (b > r + 8) blue++;
          if (r > b + 8) red++;
        }
        expect(blue, greaterThan(size.width * size.height / 2), reason: 'the picture is on screen');
        expect(red, 0, reason: 'nothing right of x = 1380 / 1536');
      });
    }
  });
}

/// A [width] × [height] PNG: blue left of [split] (a fraction), red right.
Future<ByteData> _probe(int width, int height, double split) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final cut = width * split;
  canvas.drawRect(Rect.fromLTWH(0, 0, cut, height.toDouble()), Paint()..color = const Color(0xFF2040E0));
  canvas.drawRect(Rect.fromLTWH(cut, 0, width - cut, height.toDouble()), Paint()..color = const Color(0xFFE02020));
  final image = await recorder.endRecording().toImage(width, height);
  return (await image.toByteData(format: ui.ImageByteFormat.png))!;
}

/// The app's assets, with [file] read as [bytes].
class _OneFile extends CachingAssetBundle {
  _OneFile(this.file, this.bytes);

  final String file;
  final ByteData bytes;

  @override
  Future<ByteData> load(String key) => key == file ? Future.value(bytes) : rootBundle.load(key);

  @override
  Future<ui.ImmutableBuffer> loadBuffer(String key) async =>
      key == file ? ui.ImmutableBuffer.fromUint8List(Uint8List.sublistView(bytes)) : rootBundle.loadBuffer(key);
}
