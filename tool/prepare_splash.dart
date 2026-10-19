// Run before flutter_native_splash:create after changing the source logo.
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main() {
  const source = 'assets/branding/splash_logo.png';
  const output = 'assets/branding/splash_logo_android12.png';
  final image = img.decodePng(File(source).readAsBytesSync())!;
  if (image.width != 1152 || image.height != 1152) {
    throw StateError('Expected a 1152 × 1152 source PNG.');
  }
  double radius(img.Image image) {
    var maximum = 0.0;
    for (final pixel in image) {
      if (pixel.a == 0) continue;
      final dx = pixel.x - (image.width - 1) / 2;
      final dy = pixel.y - (image.height - 1) / 2;
      maximum = math.max(maximum, math.sqrt(dx * dx + dy * dy));
    }
    return maximum;
  }

  // Leave 24px inside Android 12's 384px mask radius for edge filtering.
  final scale = math.min(1.0, 360 / radius(image));
  final size = (1152 * scale).floor();
  final resized = img.copyResize(
    image,
    width: size,
    height: size,
    interpolation: img.Interpolation.average,
  );
  final padded = img.Image(width: 1152, height: 1152, numChannels: 4);
  img.compositeImage(
    padded,
    resized,
    dstX: (1152 - size) ~/ 2,
    dstY: (1152 - size) ~/ 2,
  );
  final actualRadius = radius(padded);
  if (actualRadius > 384) {
    throw StateError('Artwork exceeds Android 12 safe area: $actualRadius');
  }
  File(output).writeAsBytesSync(img.encodePng(padded));
  stdout.writeln(
    '$output: scale=${scale.toStringAsFixed(3)}, '
    'visible radius=${actualRadius.toStringAsFixed(1)}px (limit 384px)',
  );
}
