// Makes Case 01's crown card as it is once its code is decoded: the square
// code symbol (drawn like a QR code) taken off the card, the card's own
// paper restored where its ink was. Only that part is written, as its own
// picture, laid over the card in the game as the code fades.
//
//   flutter test tool/card_code_clear/clear_test.dart
//
// Reads assets/images/case01/buckingham_palace_crown_card.png (never
// changed) and writes assets/images/case01/
// buckingham_palace_crown_card_code_clear.png: the card's pixels in [_area],
// unchanged wherever there was no ink.
//
// How (dart:ui only, no extra packages):
//  1. The ink: in [_area], a pixel clearly darker than the paper around it
//     (the paper's tone taken as a bright percentile of its neighbourhood),
//     the faded modules included; the mask grown by a few pixels for the
//     ink's soft edges. The fleur-de-lis below the code's lower-left corner
//     is never touched ([_keep]).
//  2. The paper under it: its smooth tone (a weighted mean of the paper
//     pixels around, ink left out) plus its grain, taken from paper a short
//     way off (the same offset over small blocks, so the grain stays grain
//     and never repeats as a pattern).
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const _source = 'assets/images/case01/buckingham_palace_crown_card.png';
const _out = 'assets/images/case01/buckingham_palace_crown_card_code_clear.png';

/// The part of the card the code is drawn in (pixels: left, top, right,
/// bottom), a little past its outer squares; kept in step with
/// `season1_decodes.dart` (`DecodeScene.cleared`).
const _area = (648, 414, 980, 714);

/// Never changed: the fleur-de-lis under the code's lower-left corner, and
/// the old stains on the paper right of its upper-right square.
bool _keep(int x, int y) => (x < 686 && y > 690) || (x > 932 && y < 520);

/// Ink is looked for only within the code as drawn (measured: about
/// x 652–972, y 420–706): the old stains just outside it stay.
bool _inCode(int x, int y) => x >= 650 && x <= 974 && y >= 418 && y <= 708;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('clear the code off the crown card', () async {
    final codec = await ui.instantiateImageCodec(File(_source).readAsBytesSync());
    final image = (await codec.getNextFrame()).image;
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!.buffer.asUint8List();
    final w = image.width;
    final (ax, ay, bx, by) = _area;
    final cw = bx - ax, ch = by - ay;
    // A margin of the card around the area, read but never written.
    const m = 40;
    final ox = ax - m, oy = ay - m, ow = cw + 2 * m, oh = ch + 2 * m;
    double lum(int x, int y) {
      final i = ((oy + y) * w + ox + x) * 4;
      return 0.299 * data[i] + 0.587 * data[i + 1] + 0.114 * data[i + 2];
    }

    // 1. The paper's tone around each pixel: the 80th percentile of the
    // brightness in a window (sampled on a coarse grid, then spread).
    const cell = 8, win = 64;
    final gw = (ow / cell).ceil(), gh = (oh / cell).ceil();
    final paperTone = Float64List(gw * gh);
    for (var gy = 0; gy < gh; gy++) {
      for (var gx = 0; gx < gw; gx++) {
        final cx = gx * cell + cell ~/ 2, cy = gy * cell + cell ~/ 2;
        final vals = <double>[];
        for (var y = math.max(0, cy - win); y < math.min(oh, cy + win); y += 2) {
          for (var x = math.max(0, cx - win); x < math.min(ow, cx + win); x += 2) {
            vals.add(lum(x, y));
          }
        }
        vals.sort();
        paperTone[gy * gw + gx] = vals[(vals.length * 0.8).floor()];
      }
    }
    double toneAt(int x, int y) => paperTone[math.min(gh - 1, y ~/ cell) * gw + math.min(gw - 1, x ~/ cell)];

    final ink = Uint8List(ow * oh);
    for (var y = m; y < m + ch; y++) {
      for (var x = m; x < m + cw; x++) {
        if (_keep(ox + x, oy + y) || !_inCode(ox + x, oy + y)) continue;
        if (lum(x, y) < toneAt(x, y) - 38) ink[y * ow + x] = 1;
      }
    }
    // Grown for the ink's soft edges.
    const grow = 3;
    final mask = Uint8List(ow * oh);
    for (var y = m; y < m + ch; y++) {
      for (var x = m; x < m + cw; x++) {
        if (_keep(ox + x, oy + y)) continue;
        var hit = false;
        for (var dy = -grow; dy <= grow && !hit; dy++) {
          for (var dx = -grow; dx <= grow; dx++) {
            if (ink[(y + dy) * ow + x + dx] == 1) {
              hit = true;
              break;
            }
          }
        }
        if (hit) mask[y * ow + x] = 1;
      }
    }

    // 2a. The paper's smooth colour under the ink: a Gaussian-weighted mean
    // of the paper pixels around (computed on the coarse grid).
    const sigma = 14.0, reach = 42;
    final smooth = List<Float64List>.generate(3, (_) => Float64List(gw * gh));
    for (var gy = 0; gy < gh; gy++) {
      for (var gx = 0; gx < gw; gx++) {
        final cx = gx * cell + cell ~/ 2, cy = gy * cell + cell ~/ 2;
        var r = 0.0, g = 0.0, b = 0.0, sum = 0.0;
        for (var y = math.max(0, cy - reach); y < math.min(oh, cy + reach); y += 2) {
          for (var x = math.max(0, cx - reach); x < math.min(ow, cx + reach); x += 2) {
            // Paper only, not the ink. The old stains count: the paper next
            // to them takes their tone gradually, with no edge where the
            // code's ink met them.
            if (mask[y * ow + x] == 1 || ink[y * ow + x] == 1) continue;
            final d2 = ((x - cx) * (x - cx) + (y - cy) * (y - cy)).toDouble();
            final wt = math.exp(-d2 / (2 * sigma * sigma));
            final i = ((oy + y) * w + ox + x) * 4;
            r += data[i] * wt;
            g += data[i + 1] * wt;
            b += data[i + 2] * wt;
            sum += wt;
          }
        }
        smooth[0][gy * gw + gx] = r / sum;
        smooth[1][gy * gw + gx] = g / sum;
        smooth[2][gy * gw + gx] = b / sum;
      }
    }
    // Bilinear on the grid.
    double smoothAt(int c, int x, int y) {
      final fx = ((x - cell / 2) / cell).clamp(0.0, gw - 1.0), fy = ((y - cell / 2) / cell).clamp(0.0, gh - 1.0);
      final x0 = fx.floor(), y0 = fy.floor(), x1 = math.min(gw - 1, x0 + 1), y1 = math.min(gh - 1, y0 + 1);
      final tx = fx - x0, ty = fy - y0;
      final s = smooth[c];
      return (s[y0 * gw + x0] * (1 - tx) + s[y0 * gw + x1] * tx) * (1 - ty) +
          (s[y1 * gw + x0] * (1 - tx) + s[y1 * gw + x1] * tx) * ty;
    }

    // 2b. The grain: per 6 × 6 block, one offset to nearby plain paper —
    // inside the area (never the border lines or stains around it), off the
    // ink, and itself only grain (no line, no blot).
    bool plainPaper(int sx, int sy) {
      if (sx < m || sy < m || sx >= m + cw || sy >= m + ch) return false;
      if (_keep(ox + sx, oy + sy) || mask[sy * ow + sx] == 1) return false;
      for (var c = 0; c < 3; c++) {
        final i = ((oy + sy) * w + ox + sx) * 4 + c;
        if ((data[i] - smoothAt(c, sx, sy)).abs() > 34) return false;
      }
      return true;
    }

    final rnd = math.Random(7);
    const block = 6;
    final out = Uint8List(cw * ch * 4);
    var fallback = 0;
    for (var by0 = 0; by0 < ch; by0 += block) {
      for (var bx0 = 0; bx0 < cw; bx0 += block) {
        // An offset that lands every ink pixel of the block on plain paper.
        (int, int)? off;
        for (var tries = 0; tries < 2000 && off == null; tries++) {
          final dx = rnd.nextInt(181) - 90, dy = rnd.nextInt(181) - 90;
          var clean = true;
          for (var y = by0; y < math.min(ch, by0 + block) && clean; y++) {
            for (var x = bx0; x < math.min(cw, bx0 + block); x++) {
              if (mask[(m + y) * ow + m + x] == 1 && !plainPaper(m + x + dx, m + y + dy)) {
                clean = false;
                break;
              }
            }
          }
          if (clean) off = (dx, dy);
        }
        if (off == null) fallback++;
        // Failing that, each pixel its own nearby plain paper.
        (int, int)? pixelDonor(int lx, int ly) {
          for (var tries = 0; tries < 800; tries++) {
            final dx = rnd.nextInt(241) - 120, dy = rnd.nextInt(241) - 120;
            if (plainPaper(lx + dx, ly + dy)) return (lx + dx, ly + dy);
          }
          return null;
        }
        for (var y = by0; y < math.min(ch, by0 + block); y++) {
          for (var x = bx0; x < math.min(cw, bx0 + block); x++) {
            final lx = m + x, ly = m + y;
            final si = ((oy + ly) * w + ox + lx) * 4;
            final o = (y * cw + x) * 4;
            if (mask[ly * ow + lx] == 0) {
              out[o] = data[si];
              out[o + 1] = data[si + 1];
              out[o + 2] = data[si + 2];
              out[o + 3] = 255;
              continue;
            }
            final donor = off == null ? pixelDonor(lx, ly) : (lx + off.$1, ly + off.$2);
            for (var c = 0; c < 3; c++) {
              // No plain paper anywhere near: the smooth tone alone.
              var detail = 0.0;
              if (donor != null) {
                final (dx, dy) = donor;
                detail = data[((oy + dy) * w + ox + dx) * 4 + c] - smoothAt(c, dx, dy);
              }
              out[o + c] = (smoothAt(c, lx, ly) + detail * 0.9).round().clamp(0, 255);
            }
            out[o + 3] = 255;
          }
        }
      }
    }

    // ignore: avoid_print
    print('blocks with no grain donor: $fallback');
    final buffer = await ui.ImmutableBuffer.fromUint8List(out);
    final desc = ui.ImageDescriptor.raw(buffer, width: cw, height: ch, pixelFormat: ui.PixelFormat.rgba8888);
    final result = (await (await desc.instantiateCodec()).getNextFrame()).image;
    File(_out).writeAsBytesSync((await result.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List());
  });
}
