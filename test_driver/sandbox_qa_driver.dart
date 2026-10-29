import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Host side of `integration_test/sandbox_case_qa_test.dart`: every
/// screenshot the device takes is written under `qa/screenshots/sandbox/`
/// (its name holds the screen size's folder: `393x807/02_m1_puzzle`).
///
///   flutter drive --driver=test_driver/sandbox_qa_driver.dart \
///     --target=integration_test/sandbox_case_qa_test.dart -d DEVICE
Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final file = File('qa/screenshots/sandbox/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    return true;
  },
);
