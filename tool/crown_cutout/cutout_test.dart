// Cuts Case 01's crown (assets/art/objects/crown.png: the crown drawn on an
// opaque sheet of parchment) out onto transparency, for where it stands on
// the game's own paper (the Case Closed file).
//
//   flutter test tool/crown_cutout/cutout_test.dart
//
// Reads assets/art/objects/crown.png (never changed: the evidence and the
// season opening show it with its parchment) and writes
// assets/art/objects/crown_cutout.png: the crown alone, trimmed and set in a
// square with a small even margin.
//
// How (dart:ui only):
//  1. The parchment's colour: the mean of the picture's border.
//  2. Parchment-like pixels: within a colour distance of it (the crown is
//     gold, dark-inked, jewelled: far from it).
//  3. The backdrop: the parchment-like pixels reached from the edge, and the
//     pockets of them shut in by the crown's arches (large enough).
//  4. The crown: the largest solid region left (the small mark in the
//     picture's corner goes).
//  5. The edge: a few pixels of soft alpha by distance from the backdrop.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const _source = 'assets/art/objects/crown.png';
const _out = 'assets/art/objects/crown_cutout.png';
const _side = 512;
const _margin = 16;

/// Shut-in parchment larger than this is backdrop seen through the arches;
/// smaller is a highlight on the gold.
const _pocket = 2500;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('cut the crown out of its parchment', () async {
    final codec = await ui.instantiateImageCodec(File(_source).readAsBytesSync());
    final image = (await codec.getNextFrame()).image;
    final w = image.width, h = image.height, n = w * h;
    final px = (await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!.buffer.asUint8List();

    // 1. The parchment's colour, around the border.
    var r0 = 0.0, g0 = 0.0, b0 = 0.0, c0 = 0;
    for (var i = 0; i < n; i++) {
      final x = i % w, y = i ~/ w;
      if (x > 8 && y > 8 && x < w - 9 && y < h - 9) continue;
      r0 += px[i * 4];
      g0 += px[i * 4 + 1];
      b0 += px[i * 4 + 2];
      c0++;
    }
    r0 /= c0;
    g0 /= c0;
    b0 /= c0;

    // 2. Parchment-like: close to it (its own light and shade allowed for).
    double dist(int i) {
      final dr = px[i * 4] - r0, dg = px[i * 4 + 1] - g0, db = px[i * 4 + 2] - b0;
      return math.sqrt(dr * dr + dg * dg + db * db);
    }

    // Light, and only a little yellow (blue well up on red): the parchment
    // in its light middle and its darker edge alike; the gold is far more
    // yellow, the ink and jewels dark.
    final like = Uint8List(n);
    for (var i = 0; i < n; i++) {
      final r = px[i * 4], g = px[i * 4 + 1], b = px[i * 4 + 2];
      final lum = 0.299 * r + 0.587 * g + 0.114 * b;
      if (lum > 165 && b > 0.6 * r && dist(i) < 120) like[i] = 1;
    }

    // 3. Components of parchment-like pixels; the backdrop is those touching
    // the edge, and pockets shut in by the crown of a fair size.
    final comp = Int32List(n)..fillRange(0, n, -1);
    final stack = Int32List(n);
    final bg = Uint8List(n);
    var id = 0;
    for (var s = 0; s < n; s++) {
      if (like[s] == 0 || comp[s] >= 0) continue;
      var sp = 0, size = 0, edge = false;
      final members = <int>[];
      stack[sp++] = s;
      comp[s] = id;
      while (sp > 0) {
        final p = stack[--sp];
        members.add(p);
        size++;
        final x = p % w, y = p ~/ w;
        if (x == 0 || y == 0 || x == w - 1 || y == h - 1) edge = true;
        for (final q in [if (x > 0) p - 1, if (x < w - 1) p + 1, if (y > 0) p - w, if (y < h - 1) p + w]) {
          if (like[q] == 1 && comp[q] < 0) {
            comp[q] = id;
            stack[sp++] = q;
          }
        }
      }
      if (edge || size > _pocket) {
        for (final p in members) {
          bg[p] = 1;
        }
      }
      id++;
    }

    // 4. The crown: the largest region of what is left (4-connected).
    final solid = Int32List(n)..fillRange(0, n, -1);
    var best = -1, bestSize = 0;
    id = 0;
    for (var s = 0; s < n; s++) {
      if (bg[s] == 1 || solid[s] >= 0) continue;
      var sp = 0, size = 0;
      stack[sp++] = s;
      solid[s] = id;
      while (sp > 0) {
        final p = stack[--sp];
        size++;
        final x = p % w, y = p ~/ w;
        for (final q in [if (x > 0) p - 1, if (x < w - 1) p + 1, if (y > 0) p - w, if (y < h - 1) p + w]) {
          if (bg[q] == 0 && solid[q] < 0) {
            solid[q] = id;
            stack[sp++] = q;
          }
        }
      }
      if (size > bestSize) {
        bestSize = size;
        best = id;
      }
      id++;
    }

    // 5. Alpha: 1 inside; along the edge, by distance to the backdrop
    // (up to 2 px), so it stays smooth.
    final out = Uint8List(n * 4);
    var left = w, top = h, right = -1, bottom = -1;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = y * w + x;
        if (solid[i] != best) continue;
        var near = 3;
        for (var dy = -2; dy <= 2; dy++) {
          for (var dx = -2; dx <= 2; dx++) {
            final xx = x + dx, yy = y + dy;
            if (xx < 0 || yy < 0 || xx >= w || yy >= h) continue;
            if (solid[yy * w + xx] != best) near = math.min(near, math.max(dx.abs(), dy.abs()));
          }
        }
        final a = near >= 3 ? 255 : (near * 255 / 3).round();
        out[i * 4] = px[i * 4];
        out[i * 4 + 1] = px[i * 4 + 1];
        out[i * 4 + 2] = px[i * 4 + 2];
        out[i * 4 + 3] = a;
        left = math.min(left, x);
        right = math.max(right, x);
        top = math.min(top, y);
        bottom = math.max(bottom, y);
      }
    }
    // ignore: avoid_print
    print('crown: ($left, $top) – ($right, $bottom), $bestSize px; parchment ${r0.round()} ${g0.round()} ${b0.round()}');

    // Trimmed, in a square with an even margin.
    final buffer = await ui.ImmutableBuffer.fromUint8List(out);
    final desc = ui.ImageDescriptor.raw(buffer, width: w, height: h, pixelFormat: ui.PixelFormat.rgba8888);
    final cut = (await (await desc.instantiateCodec()).getNextFrame()).image;
    final src = ui.Rect.fromLTRB(left.toDouble(), top.toDouble(), right + 1.0, bottom + 1.0);
    const room = _side - 2.0 * _margin;
    final scale = math.min(room / src.width, room / src.height);
    final dst = ui.Rect.fromCenter(center: const ui.Offset(_side / 2, _side / 2), width: src.width * scale, height: src.height * scale);
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawImageRect(cut, src, dst, ui.Paint()..filterQuality = ui.FilterQuality.high);
    final square = await recorder.endRecording().toImage(_side, _side);
    File(_out).writeAsBytesSync((await square.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List());
  });
}
