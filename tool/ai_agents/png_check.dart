import 'dart:io';
import 'dart:typed_data';

/// What a PNG file is: its size and colour, once read whole.
class PngInfo {
  const PngInfo({required this.width, required this.height, required this.bitDepth, required this.colorType, required this.interlaced});

  final int width;
  final int height;
  final int bitDepth;

  /// 0 grey, 2 RGB, 3 palette, 4 grey + alpha, 6 RGBA.
  final int colorType;
  final bool interlaced;

  bool get hasAlpha => colorType == 4 || colorType == 6;

  Map<String, Object?> toJson() =>
      {'width': width, 'height': height, 'bitDepth': bitDepth, 'colorType': colorType, 'hasAlpha': hasAlpha};
}

/// Why bytes are not a PNG an app can open.
class PngProblem implements Exception {
  const PngProblem(this.message);

  final String message;

  @override
  String toString() => 'not a valid PNG: $message';
}

/// Reads a PNG whole: its signature, every chunk's length and CRC, IHDR
/// first and IEND last, and its pixel data inflated to exactly the bytes its
/// size and colour make. A [PngProblem] at the first thing wrong.
abstract final class PngCheck {
  static const _signature = [137, 80, 78, 71, 13, 10, 26, 10];

  static PngInfo file(String path) => bytes(File(path).readAsBytesSync());

  static PngInfo bytes(Uint8List b) {
    if (b.length < 8 || !List.generate(8, (i) => b[i] == _signature[i]).every((x) => x)) {
      throw const PngProblem('no PNG signature');
    }
    final data = ByteData.sublistView(b);
    PngInfo? info;
    final idat = BytesBuilder(copy: false);
    var at = 8;
    var ended = false;
    while (at < b.length) {
      if (at + 12 > b.length) throw PngProblem('a chunk cut short at byte $at');
      final length = data.getUint32(at);
      final type = String.fromCharCodes(b.sublist(at + 4, at + 8));
      if (at + 12 + length > b.length) throw PngProblem('chunk $type runs past the end');
      final body = Uint8List.sublistView(b, at + 8, at + 8 + length);
      final crc = data.getUint32(at + 8 + length);
      if (_crc(Uint8List.sublistView(b, at + 4, at + 8 + length)) != crc) throw PngProblem('chunk $type: wrong CRC');
      if (info == null && type != 'IHDR') throw const PngProblem('IHDR is not the first chunk');
      switch (type) {
        case 'IHDR':
          if (length != 13) throw const PngProblem('IHDR of the wrong length');
          final h = ByteData.sublistView(body);
          info = PngInfo(width: h.getUint32(0), height: h.getUint32(4), bitDepth: body[8], colorType: body[9], interlaced: body[12] == 1);
          if (info.width == 0 || info.height == 0) throw const PngProblem('no pixels');
        case 'IDAT':
          idat.add(body);
        case 'IEND':
          ended = true;
      }
      at += 12 + length;
      if (ended) break;
    }
    if (!ended) throw const PngProblem('no IEND');
    if (at != b.length) throw PngProblem('${b.length - at} bytes after IEND');
    final i = info!;
    final List<int> pixels;
    try {
      pixels = ZLibDecoder().convert(idat.takeBytes());
    } on FormatException catch (e) {
      throw PngProblem('pixel data does not inflate (${e.message})');
    }
    if (!i.interlaced) {
      final channels = switch (i.colorType) { 0 || 3 => 1, 2 => 3, 4 => 2, 6 => 4, _ => throw PngProblem('colour type ${i.colorType}') };
      final rowBytes = (i.width * channels * i.bitDepth + 7) ~/ 8;
      if (pixels.length != i.height * (rowBytes + 1)) {
        throw PngProblem('pixel data of ${pixels.length} bytes, ${i.height * (rowBytes + 1)} expected');
      }
    }
    return i;
  }

  static final _table = List<int>.generate(256, (n) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    return c;
  });

  static int _crc(Uint8List bytes) {
    var c = 0xFFFFFFFF;
    for (final x in bytes) {
      c = _table[(c ^ x) & 0xFF] ^ (c >> 8);
    }
    return c ^ 0xFFFFFFFF;
  }
}
