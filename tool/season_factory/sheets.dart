import 'dart:io';

import 'package:image/image.dart' as img;

/// The pictures a person (or Claude, reading the PNG) looks at before the
/// factory goes on: never a verdict of its own.
abstract final class Sheets {
  /// [files] side by side, two a row, each fitted in a [cell] square, with
  /// its number (1, 2, …) in its corner: one picture to review a batch by.
  static void review(List<String> files, String out, {int cell = 640}) {
    final rows = (files.length + 1) ~/ 2;
    final sheet = img.Image(width: cell * 2, height: cell * rows);
    img.fill(sheet, color: img.ColorRgb8(255, 255, 255));
    for (final (i, f) in files.indexed) {
      final src = img.decodePng(File(f).readAsBytesSync())!;
      final scale = cell / (src.width > src.height ? src.width : src.height);
      final small = img.copyResize(src, width: (src.width * scale).round(), height: (src.height * scale).round());
      final x = (i % 2) * cell, y = (i ~/ 2) * cell;
      img.compositeImage(sheet, small, dstX: x, dstY: y);
      img.fillRect(sheet, x1: x, y1: y, x2: x + 44, y2: y + 34, color: img.ColorRgb8(20, 30, 60));
      img.drawString(sheet, '${i + 1}', font: img.arial24, x: x + 8, y: y + 5, color: img.ColorRgb8(255, 255, 255));
    }
    File(out)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(img.encodePng(sheet));
  }

  /// [file] with a line every 50 pixels (every 100 darker and numbered), in
  /// its own pixels: where things are on it are read off it and written
  /// into the plans as they are (never guessed).
  static void grid(String file, String out) {
    final im = img.decodePng(File(file).readAsBytesSync())!;
    final red = img.ColorRgb8(255, 0, 0), pink = img.ColorRgb8(255, 120, 200);
    for (var x = 0; x <= im.width; x += 50) {
      img.drawLine(im, x1: x, y1: 0, x2: x, y2: im.height - 1, color: x % 100 == 0 ? red : pink, thickness: x % 100 == 0 ? 2 : 1);
      if (x % 100 == 0) img.drawString(im, '$x', font: img.arial24, x: x + 3, y: 3, color: red);
    }
    for (var y = 0; y <= im.height; y += 50) {
      img.drawLine(im, x1: 0, y1: y, x2: im.width - 1, y2: y, color: y % 100 == 0 ? red : pink, thickness: y % 100 == 0 ? 2 : 1);
      if (y % 100 == 0) img.drawString(im, '$y', font: img.arial24, x: 3, y: y + 3, color: red);
    }
    File(out)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(img.encodePng(im));
  }
}
