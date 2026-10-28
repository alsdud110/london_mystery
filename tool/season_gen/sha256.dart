import 'dart:typed_data';

/// SHA-256 (FIPS 180-4) in plain Dart, so the pipeline's tools run with
/// `dart run` and no package beyond the game's own (`crypto` is only a
/// transitive one). `content_approval_test` checks it against the standard's
/// test vectors.
abstract final class Sha256 {
  static const _mask = 0xffffffff;

  static const _h0 = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19];

  static const _k = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, //
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];

  /// The 32-byte digest of [message].
  static Uint8List digest(List<int> message) {
    final h = [..._h0];
    final padded = Uint8List((message.length + 9 + 63) ~/ 64 * 64)..setRange(0, message.length, message);
    padded[message.length] = 0x80;
    final view = ByteData.sublistView(padded)..setUint64(padded.length - 8, message.length * 8);
    final w = Uint32List(64);
    for (var block = 0; block < padded.length; block += 64) {
      for (var t = 0; t < 16; t++) {
        w[t] = view.getUint32(block + t * 4);
      }
      for (var t = 16; t < 64; t++) {
        final s0 = _rotr(w[t - 15], 7) ^ _rotr(w[t - 15], 18) ^ (w[t - 15] >> 3);
        final s1 = _rotr(w[t - 2], 17) ^ _rotr(w[t - 2], 19) ^ (w[t - 2] >> 10);
        w[t] = w[t - 16] + s0 + w[t - 7] + s1;
      }
      var [a, b, c, d, e, f, g, k] = h;
      for (var t = 0; t < 64; t++) {
        final t1 = (k + (_rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25)) + ((e & f) ^ (~e & g)) + _k[t] + w[t]) & _mask;
        final t2 = ((_rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22)) + ((a & b) ^ (a & c) ^ (b & c))) & _mask;
        k = g;
        g = f;
        f = e;
        e = (d + t1) & _mask;
        d = c;
        c = b;
        b = a;
        a = (t1 + t2) & _mask;
      }
      for (final (i, v) in [a, b, c, d, e, f, g, k].indexed) {
        h[i] = (h[i] + v) & _mask;
      }
    }
    final out = ByteData(32);
    for (final (i, v) in h.indexed) {
      out.setUint32(i * 4, v);
    }
    return out.buffer.asUint8List();
  }

  /// The digest of [message] in lower-case hex (64 characters).
  static String hex(List<int> message) => [for (final b in digest(message)) b.toRadixString(16).padLeft(2, '0')].join();

  static int _rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & _mask;
}
