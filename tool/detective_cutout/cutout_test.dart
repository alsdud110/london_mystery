// Cuts the player's detective pictures out of the checkered backdrop that
// was painted into them (RGB files, no transparency), into RGBA PNGs.
//
//   flutter test tool/detective_cutout/cutout_test.dart
//
// Reads the delivered files kept in assets/art/detectives/original/ (never
// changed) and writes assets/art/detectives/<boy|girl>/<expression>.png.
// Uses dart:ui only (decode, raw pixels, PNG encode): no extra packages.
//
// How:
//  1. Backdrop-like pixels: grey (no colour) and light — the two checker
//     tones, white and light grey.
//  2. The backdrop is what of them is reached from the picture's edge
//     (the ink outline stops it: a white collar or an eye is never reached).
//  3. Pockets of them shut in by the figure (between an arm and the head)
//     are backdrop too when they have the checker's texture (the tone
//     flips every few pixels along a row).
//  4. The pixels along the edge of the figure are matted: their alpha and
//     colour from the backdrop and the figure near them, so no white or
//     grey fringe is left and the edge stays anti-aliased.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const _avatars = ['boy', 'girl'];
const _expressions = ['thinking', 'surprised', 'investigating', 'happy', 'confident'];

void main() {
  for (final a in _avatars) {
    for (final e in _expressions) {
      test('cut out $a/$e', () async {
        final source = File('assets/art/detectives/original/$a/$e.png');
        expect(source.existsSync(), isTrue, reason: 'the delivered file is kept');
        final decoded = await _decode(source.readAsBytesSync());
        final out = cutOut(decoded.rgba, decoded.width, decoded.height);
        final png = await _encode(out, decoded.width, decoded.height);
        File('assets/art/detectives/$a/$e.png').writeAsBytesSync(png);
      });
    }
  }
}

/// Grey and light: one of the checker's tones (or the light streaks over it).
bool _backdropLike(int r, int g, int b) {
  final hi = math.max(r, math.max(g, b));
  final lo = math.min(r, math.min(g, b));
  return hi - lo <= 14 && lo >= 185;
}

Uint8List cutOut(Uint8List src, int w, int h) {
  final n = w * h;
  final like = Uint8List(n);
  for (var i = 0; i < n; i++) {
    if (_backdropLike(src[i * 4], src[i * 4 + 1], src[i * 4 + 2])) like[i] = 1;
  }

  // Components of backdrop-like pixels (4-connected).
  final comp = Int32List(n)..fillRange(0, n, -1);
  final stack = Int32List(n);
  final touchesEdge = <bool>[];
  final sizes = <int>[];
  final flips = <int>[];
  final runs = <int>[];
  final mids = <int>[];
  final lightRims = <double>[];
  for (var start = 0; start < n; start++) {
    if (like[start] == 0 || comp[start] >= 0) continue;
    final id = sizes.length;
    var size = 0, edge = false, flip = 0, run = 0, mid = 0, rim = 0, lightRim = 0;
    var sp = 0;
    stack[sp++] = start;
    comp[start] = id;
    while (sp > 0) {
      final p = stack[--sp];
      size++;
      // Between the checker's two tones (a gradient, a glare, a shadow).
      final v = src[p * 4 + 1];
      if (v > 224 && v < 240) mid++;
      final x = p % w, y = p ~/ w;
      if (x == 0 || y == 0 || x == w - 1 || y == h - 1) edge = true;
      // Texture: along the row, does the tone (white / grey) change?
      if (x + 1 < w && like[p + 1] == 1) {
        run++;
        if ((src[p * 4] >= 232) != (src[(p + 1) * 4] >= 232)) flip++;
      }
      void visit(int q) {
        if (like[q] == 1) {
          if (comp[q] < 0) {
            comp[q] = id;
            stack[sp++] = q;
          }
        } else {
          // What the pocket is shut in by: light (glass, paper) or ink.
          rim++;
          final l = (src[q * 4] * 3 + src[q * 4 + 1] * 6 + src[q * 4 + 2]) ~/ 10;
          if (l >= 170) lightRim++;
        }
      }

      if (x > 0) visit(p - 1);
      if (x + 1 < w) visit(p + 1);
      if (y > 0) visit(p - w);
      if (y + 1 < h) visit(p + w);
    }
    sizes.add(size);
    touchesEdge.add(edge);
    flips.add(flip);
    runs.add(run);
    mids.add(mid);
    lightRims.add(rim == 0 ? 0 : lightRim / rim);
  }

  // Backdrop: everything reached from the edge, and shut-in pockets with
  // the checker's texture (a tone change every ~10 px or more often).
  final isBackdrop = List<bool>.generate(sizes.length, (id) {
    if (touchesEdge[id]) return true;
    if (sizes[id] < 120 || runs[id] == 0) return false;
    final flip = flips[id] / runs[id];
    if (flip < 0.05) return false;
    // Shut in by light colour all round (the glass of a magnifier, paper):
    // a glare is a gradient (many in-between tones) or flips seldom; the
    // checker flips often between its two tones.
    if (lightRims[id] >= 0.9) return flip >= 0.1 && mids[id] / sizes[id] < 0.3;
    return true;
  });
  if (Platform.environment['LM_CUTOUT_DEBUG'] != null) {
    for (var id = 0; id < sizes.length; id++) {
      if (touchesEdge[id] || sizes[id] < 120) continue;
      // ignore: avoid_print
      print('pocket $id size=${sizes[id]} flip=${(flips[id] / math.max(runs[id], 1)).toStringAsFixed(3)} '
          'mid=${(mids[id] / sizes[id]).toStringAsFixed(2)} lightRim=${lightRims[id].toStringAsFixed(2)} -> ${isBackdrop[id]}');
    }
  }
  final bg = Uint8List(n);
  for (var i = 0; i < n; i++) {
    if (comp[i] >= 0 && isBackdrop[comp[i]]) bg[i] = 1;
  }

  // Distance (in px, up to 3) from the backdrop, for the figure's pixels.
  const band = 3;
  final dist = Uint8List(n)..fillRange(0, n, 255);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      if (bg[i] == 1) {
        dist[i] = 0;
        continue;
      }
      var d = 255;
      for (var dy = -band; dy <= band && d > 1; dy++) {
        final yy = y + dy;
        if (yy < 0 || yy >= h) continue;
        for (var dx = -band; dx <= band; dx++) {
          final xx = x + dx;
          if (xx < 0 || xx >= w) continue;
          if (bg[yy * w + xx] == 1) {
            final dd = math.max(dx.abs(), dy.abs());
            if (dd < d) d = dd;
          }
        }
      }
      dist[i] = d;
    }
  }

  final out = Uint8List(n * 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      final o = i * 4;
      if (bg[i] == 1) continue; // transparent
      final r = src[o], g = src[o + 1], b = src[o + 2];
      if (dist[i] > 2) {
        out[o] = r;
        out[o + 1] = g;
        out[o + 2] = b;
        out[o + 3] = 255;
        continue;
      }
      // An edge pixel: the backdrop next to it (B) and the figure behind it
      // (F, pixels further in), then C = a·F + (1 − a)·B.
      double br = 0, bgc = 0, bb = 0, bn = 0;
      double fr = 0, fg = 0, fb = 0, fn = 0;
      for (var dy = -band; dy <= band; dy++) {
        final yy = y + dy;
        if (yy < 0 || yy >= h) continue;
        for (var dx = -band; dx <= band; dx++) {
          final xx = x + dx;
          if (xx < 0 || xx >= w) continue;
          final j = yy * w + xx;
          final q = j * 4;
          if (bg[j] == 1) {
            br += src[q];
            bgc += src[q + 1];
            bb += src[q + 2];
            bn++;
          } else if (dist[j] > dist[i]) {
            fr += src[q];
            fg += src[q + 1];
            fb += src[q + 2];
            fn++;
          }
        }
      }
      double alpha;
      double cr = r.toDouble(), cg = g.toDouble(), cb = b.toDouble();
      if (bn == 0) {
        alpha = 1;
      } else {
        br /= bn;
        bgc /= bn;
        bb /= bn;
        if (fn == 0) {
          // A thin bit of the figure (a hair, a line): judged against the
          // backdrop only — the further from it, the more opaque.
          final diff = math.sqrt(_sq(cr - br) + _sq(cg - bgc) + _sq(cb - bb));
          alpha = (diff / 120).clamp(0.0, 1.0);
          fr = cr;
          fg = cg;
          fb = cb;
        } else {
          fr /= fn;
          fg /= fn;
          fb /= fn;
          final dr = fr - br, dg = fg - bgc, db = fb - bb;
          final len2 = dr * dr + dg * dg + db * db;
          alpha = len2 < 400
              ? 1
              : (((cr - br) * dr + (cg - bgc) * dg + (cb - bb) * db) / len2).clamp(0.0, 1.0);
        }
        // Fully backdrop-coloured edge pixels go; strong ones stay whole.
        if (_backdropLike(r, g, b) && dist[i] == 1) alpha = math.min(alpha, 0.35);
        if (alpha > 0.04) {
          // The figure's own colour, the backdrop taken out.
          cr = ((cr - (1 - alpha) * br) / alpha).clamp(0, 255);
          cg = ((cg - (1 - alpha) * bgc) / alpha).clamp(0, 255);
          cb = ((cb - (1 - alpha) * bb) / alpha).clamp(0, 255);
        }
      }
      if (alpha <= 0.04) continue;
      out[o] = cr.round();
      out[o + 1] = cg.round();
      out[o + 2] = cb.round();
      out[o + 3] = (alpha * 255).round();
    }
  }
  return out;
}

double _sq(double v) => v * v;

Future<({Uint8List rgba, int width, int height})> _decode(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final image = (await codec.getNextFrame()).image;
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!;
  return (rgba: data.buffer.asUint8List(), width: image.width, height: image.height);
}

Future<Uint8List> _encode(Uint8List rgba, int w, int h) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
  final descriptor = ui.ImageDescriptor.raw(buffer, width: w, height: h, pixelFormat: ui.PixelFormat.rgba8888);
  final codec = await descriptor.instantiateCodec();
  final image = (await codec.getNextFrame()).image;
  final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  return png.buffer.asUint8List();
}
