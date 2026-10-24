import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Host side of `integration_test/case10_visual_qa_test.dart`: every
/// screenshot the device takes is written under `qa/screenshots/case10/`
/// (its name holds the screen size's folder: `393x807/03_m1_tape`).
///
///   flutter drive --driver=test_driver/case10_qa_driver.dart \
///     --target=integration_test/case10_visual_qa_test.dart -d DEVICE
Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final file = File('qa/screenshots/case10/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    return true;
  },
);
