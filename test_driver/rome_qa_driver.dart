import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Host side of `integration_test/rome_qa_test.dart`: every
/// screenshot the device takes is written under `qa/screenshots/rome/`
/// (its name holds the screen size's folder: `393x807/04_c01_m3_a_opening`).
///
///   flutter drive --driver=test_driver/rome_qa_driver.dart \
///     --target=integration_test/rome_qa_test.dart -d DEVICE
Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final file = File('qa/screenshots/rome/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    return true;
  },
);
