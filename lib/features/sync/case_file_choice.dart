import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/progress_repository.dart';
import '../../data/sync/case_conflicts.dart';
import 'sync_scheduler.dart';

/// The player's choice between two case files of one case (Phase 4.5).
///
/// - Made on what the server holds now: with the sync, a run brings the
///   server's records down first ([SyncScheduler.runNow]); if that changes
///   the case files, nothing is chosen and they are shown again. Without a
///   connection the choice is made on the device and sent later (it stays
///   `waiting` until the server has it).
/// - Nothing changes once the account or the detective changed meanwhile.
/// - The choice itself is one synchronous save (see [CaseConflicts.choose]).
class CaseFileChooser {
  const CaseFileChooser({this.sync});

  /// The sync of this build (null: it does not sync).
  final SyncScheduler? sync;

  Future<ChoiceResult> choose({
    required SharedPrefsProgressRepository repo,
    required CaseChoice choice,
    required bool keepPlaying,
    required bool Function() isStillValid,
    required void Function(String caseId) applied,
  }) async {
    if (!isStillValid()) return ChoiceResult.stopped;
    final clock = Stopwatch()..start();
    try {
      await sync?.runNow();
    } catch (e) {
      debugPrint('Case files: no run before choosing (${e.runtimeType})');
    }
    if (!isStillValid()) return ChoiceResult.stopped;
    final r = CaseConflicts.choose(repo, choice, keepPlaying: keepPlaying, now: DateTime.now());
    debugPrint('Case files: ${r.name} (server checked in ${clock.elapsedMilliseconds} ms)');
    // Shown at once, before the game can save over it.
    if (r == ChoiceResult.applied) applied(choice.caseId);
    return r;
  }
}

final caseFileChooserProvider = Provider<CaseFileChooser>((ref) => const CaseFileChooser());
