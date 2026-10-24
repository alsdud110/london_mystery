import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Host side of `integration_test/case09_visual_qa_test.dart`: every
/// screenshot the device takes is written under `qa/screenshots/case09/`
/// (its name may hold a sub-folder: `393x807/01_intro_pencil`).
///
///   flutter drive --driver=test_driver/case09_qa_driver.dart \
///     --target=integration_test/case09_visual_qa_test.dart -d DEVICE
Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final file = File('qa/screenshots/case09/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    return true;
  },
);
