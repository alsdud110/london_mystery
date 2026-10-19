// Makes Case 01's shut Royal Box with its four dial drums blank: the "0"
// painted on each drum taken off and the brass drum restored, so the game
// writes the detective's own numbers there as the locks are turned.
//
//   flutter test tool/royal_box_blank/blank_test.dart
//
// Reads assets/art/special/royal_box_closed.png (never changed) and writes
// assets/art/special/royal_box_closed_blank.png: the same picture, the same
// pixels except the four painted digits ([_digits]: also where the game
// writes its numbers, `ArtAssets.royalBoxDials`).
//
// How (dart:ui only): on each drum (a brass cylinder: its shading changes
// from top to bottom, hardly from side to side), every pixel of the digit's
// box takes, along its row, the drum's colour just left and right of it,
// blended by distance.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const _source = 'assets/art/special/royal_box_closed.png';
const _out = 'assets/art/special/royal_box_closed_blank.png';

/// The four painted digits (pixels: left, top, right, bottom), measured on
/// the picture (each "0" with its pale rim; the drum face runs a dozen
/// pixels further each side).
const _digits = [(521, 644, 552, 688), (709, 644, 740, 688), (909, 644, 940, 688), (1104, 644, 1135, 688)];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('blank the dial drums of the shut Royal Box', () async {
    final codec = await ui.instantiateImageCodec(File(_source).readAsBytesSync());
    final image = (await codec.getNextFrame()).image;
    final w = image.width, h = image.height;
    final px = (await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!.buffer.asUint8List();
    final out = Uint8List.fromList(px);

    for (final (l, t, r, b) in _digits) {
      // Each row of the digit takes the drum's colour just left and right
      // of it (three pixels each side, a pixel clear of the rim), blended
      // by distance: the drum's own top-to-bottom shading, no digit.
      for (var y = t; y < b; y++) {
        List<double> avg(int x0, int step) {
          final s = [0.0, 0.0, 0.0];
          for (var k = 0; k < 3; k++) {
            final i = (y * w + x0 + k * step) * 4;
            for (var ch = 0; ch < 3; ch++) {
              s[ch] += px[i + ch] / 3;
            }
          }
          return s;
        }

        final a = l - 2, c = r + 1;
        final left = avg(a, -1), right = avg(c, 1);
        for (var x = l; x < r; x++) {
          final f = (x - a) / (c - a);
          final i = (y * w + x) * 4;
          for (var ch = 0; ch < 3; ch++) {
            out[i + ch] = (left[ch] * (1 - f) + right[ch] * f).round().clamp(0, 255);
          }
        }
      }
    }

    final buffer = await ui.ImmutableBuffer.fromUint8List(out);
    final desc = ui.ImageDescriptor.raw(buffer, width: w, height: h, pixelFormat: ui.PixelFormat.rgba8888);
    final result = (await (await desc.instantiateCodec()).getNextFrame()).image;
    File(_out).writeAsBytesSync((await result.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List());
  });
}
