// London Case 02–12 upgrade: the pictures' last steps before `assets/`
// (docs/LONDON_GAMEPLAY_UPGRADE_PROGRESS.md). Plain Dart, the game's own
// `image` package; nothing here is imported by the game.
//
//   dart run tool/london_upgrade/art_prep.dart alpha <png>
//   dart run tool/london_upgrade/art_prep.dart crop <in> <out> <left> <top> <right> <bottom>
//   dart run tool/london_upgrade/art_prep.dart clear <in> <out> [tolerance]
//   dart run tool/london_upgrade/art_prep.dart fit <in> <out> <width>
//   dart run tool/london_upgrade/art_prep.dart grey <in> <out>
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main(List<String> args) {
  if (args.isEmpty) _usage();
  switch (args.first) {
    case 'alpha' when args.length == 2:
      final p = _read(args[1]);
      String at(int x, int y) {
        final c = p.getPixel(x, y);
        return '(${c.r},${c.g},${c.b},${c.a})';
      }

      final w = p.width - 1, h = p.height - 1;
      stdout.writeln('${p.width}x${p.height} channels ${p.numChannels}');
      stdout.writeln('corners ${at(0, 0)} ${at(w, 0)} ${at(0, h)} ${at(w, h)} middle ${at(w ~/ 2, h ~/ 2)}');
      var clear = 0, solid = 0;
      for (final c in p) {
        if (c.a < 8) clear++;
        if (c.a > 247) solid++;
      }
      stdout.writeln('clear ${(100 * clear / (p.width * p.height)).toStringAsFixed(1)}%  solid ${(100 * solid / (p.width * p.height)).toStringAsFixed(1)}%');
    case 'crop' when args.length == 7:
      final p = _read(args[1]);
      final [l, t, r, b] = [for (final a in args.sublist(3)) int.parse(a)];
      _write(args[2], img.copyCrop(p, x: l, y: t, width: r - l, height: b - t));
    case 'clear' when args.length == 3 || args.length == 4:
      _write(args[2], _clear(_read(args[1]), args.length == 4 ? int.parse(args[3]) : 40));
    case 'fit' when args.length == 4:
      final p = _read(args[1]);
      final w = int.parse(args[3]);
      _write(args[2], img.copyResize(p, width: w, interpolation: img.Interpolation.average));
    case 'grey' when args.length == 3:
      _write(args[2], img.grayscale(_read(args[1])));
    default:
      _usage();
  }
}

/// The background reached from the picture's edge cleared: every pixel
/// joined to the edge whose colour is within [tolerance] of the edge's own
/// (the mean of the four corners). The object keeps every pixel it has.
img.Image _clear(img.Image src, int tolerance) {
  final p = src.convert(numChannels: 4);
  final w = p.width, h = p.height;
  final corners = [p.getPixel(0, 0), p.getPixel(w - 1, 0), p.getPixel(0, h - 1), p.getPixel(w - 1, h - 1)];
  final br = corners.map((c) => c.r).reduce((a, b) => a + b) / 4;
  final bg = corners.map((c) => c.g).reduce((a, b) => a + b) / 4;
  final bb = corners.map((c) => c.b).reduce((a, b) => a + b) / 4;
  bool near(img.Pixel c) =>
      math.sqrt(math.pow(c.r - br, 2) + math.pow(c.g - bg, 2) + math.pow(c.b - bb, 2)) <= tolerance;
  final seen = List<bool>.filled(w * h, false);
  final todo = <int>[];
  void push(int x, int y) {
    final i = y * w + x;
    if (seen[i]) return;
    seen[i] = true;
    if (near(p.getPixel(x, y))) todo.add(i);
  }

  for (var x = 0; x < w; x++) {
    push(x, 0);
    push(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    push(0, y);
    push(w - 1, y);
  }
  while (todo.isNotEmpty) {
    final i = todo.removeLast();
    final x = i % w, y = i ~/ w;
    p.getPixel(x, y).a = 0;
    if (x > 0) push(x - 1, y);
    if (x < w - 1) push(x + 1, y);
    if (y > 0) push(x, y - 1);
    if (y < h - 1) push(x, y + 1);
  }
  return p;
}

img.Image _read(String path) {
  final p = img.decodePng(File(path).readAsBytesSync());
  if (p == null) {
    stderr.writeln('not a PNG: $path');
    exit(2);
  }
  return p;
}

void _write(String path, img.Image p) {
  File(path).writeAsBytesSync(img.encodePng(p, level: 9));
  stdout.writeln('wrote $path ${p.width}x${p.height}');
}

Never _usage() {
  stderr.writeln('usage: alpha <png> | crop <in> <out> l t r b | clear <in> <out> [tol] | fit <in> <out> <w> | grey <in> <out>');
  exit(64);
}
