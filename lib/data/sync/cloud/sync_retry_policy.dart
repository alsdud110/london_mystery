import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// How often a failing sync is tried again (docs/PHASE4_CLOUD_SYNC_DESIGN.md
/// §5.8): up to [maxRoundsPerRun] merge-and-write rounds in one run, then
/// exponential back-off from [baseDelay] up to [maxDelay], and after
/// [stallAfter] failed runs in a row the subject stalls (no automatic retry
/// until the next start's full resync).
@immutable
class SyncRetryPolicy {
  const SyncRetryPolicy({
    this.maxRoundsPerRun = 3,
    this.baseDelay = const Duration(seconds: 30),
    this.maxDelay = const Duration(hours: 1),
    this.stallAfter = 10,
  });

  static const standard = SyncRetryPolicy();

  final int maxRoundsPerRun;
  final Duration baseDelay;
  final Duration maxDelay;
  final int stallAfter;

  /// The wait after [failures] failed runs in a row (1: [baseDelay]),
  /// doubling each time, never over [maxDelay]. [jitter] in (0, 1] spreads
  /// devices apart (1: none).
  Duration delayAfter(int failures, {double jitter = 1}) {
    assert(failures >= 1 && jitter > 0 && jitter <= 1);
    final exp = math.min(failures - 1, 30);
    final ms = math.min(baseDelay.inMilliseconds * math.pow(2, exp), maxDelay.inMilliseconds.toDouble());
    return Duration(milliseconds: (ms * jitter).round());
  }

  bool stalls(int failures) => failures >= stallAfter;

  /// A jitter in [0.5, 1].
  static double randomJitter(math.Random random) => 0.5 + random.nextDouble() / 2;
}
