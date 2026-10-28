import 'dart:convert';

import 'sha256.dart';

/// The hashes approvals are made against (STEP 3-5): `sha256:` and the
/// SHA-256 of the content, in lower-case hex.
///
/// A file's bytes for a picture ([ofBytes]). For a plan, the bytes of its
/// JSON in one canonical form ([canonicalJson]), so the same data written
/// another way (its keys in another order, other spaces and newlines) has
/// the same hash, and any value changed has another:
///
/// 1. The file is read as JSON (RFC 8259); what is not JSON has no hash.
/// 2. An object's keys are sorted by their UTF-16 code units (Dart's
///    `String.compareTo`); an array keeps its order.
/// 3. Nothing is written between tokens: no space, no newline.
/// 4. A string is written as `jsonEncode` writes it: `"` and `\` escaped,
///    control characters below U+0020 as `\b \f \n \r \t` or `\u00xx`,
///    every other character as it is (no Unicode normalisation).
/// 5. A number with no fraction (`3`, `3.0`, `3e0`) is written as an
///    integer; any other as Dart's shortest `double.toString()`.
/// 6. `true`, `false`, `null` as they are.
/// 7. The text is hashed as UTF-8.
abstract final class ContentHash {
  static const prefix = 'sha256:';

  /// A hash as approvals hold it.
  static final pattern = RegExp(r'^sha256:[0-9a-f]{64}$');

  static String ofBytes(List<int> bytes) => '$prefix${Sha256.hex(bytes)}';

  /// The hash of JSON data (as `jsonDecode` reads it).
  static String ofJson(Object? json) => ofBytes(utf8.encode(canonicalJson(json)));

  /// The hex digits of [hash] (no prefix).
  static String hexOf(String hash) => hash.substring(prefix.length);

  /// [json] in the canonical form above. An [ArgumentError] for what JSON
  /// cannot hold (a key not a string, a number not finite, another object).
  static String canonicalJson(Object? json) {
    final out = StringBuffer();
    void write(Object? v) {
      switch (v) {
        case null || bool() || String():
          out.write(jsonEncode(v));
        case int():
          out.write(v);
        case double() when !v.isFinite:
          throw ArgumentError.value(v, 'json', 'not a JSON number');
        case double():
          out.write(v == v.truncateToDouble() && v.abs() < 9007199254740992 ? v.toInt() : v);
        case List():
          out.write('[');
          for (final (i, e) in v.indexed) {
            if (i > 0) out.write(',');
            write(e);
          }
          out.write(']');
        case Map():
          final keys = [
            for (final k in v.keys) k is String ? k : throw ArgumentError.value(k, 'json', 'an object key is not a string'),
          ]..sort();
          out.write('{');
          for (final (i, k) in keys.indexed) {
            if (i > 0) out.write(',');
            out
              ..write(jsonEncode(k))
              ..write(':');
            write(v[k]);
          }
          out.write('}');
        default:
          throw ArgumentError.value(v, 'json', 'not JSON data');
      }
    }

    write(json);
    return out.toString();
  }
}
