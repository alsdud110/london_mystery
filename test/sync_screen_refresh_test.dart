import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/repositories/progress_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/sync/sync_session.dart';

import 'full_playthrough_test.dart' show wait;
import 'mission_play.dart';

/// Phase 4.3B-1: what a cloud merge changed in the saves reaches the screen
/// at once, without starting the page over.
void main() {
  testWidgets('a merge while an answer is being typed: the page and the typed answer stay', (t) async {
    final play = MissionPlay();
    final m = play.season.expand((e) => e.missions).firstWhere((m) => m.type == MissionType.wordInput);
    final caseId = play.caseOf(m.id).id;
    await play.openPuzzle(t, const Size(390, 844), m.id);
    await t.enterText(find.byType(TextField), 'half a wor');
    await t.pump();

    final c = ProviderScope.containerOf(t.element(find.byType(LondonMysteryApp)));
    final repo = c.read(progressRepositoryProvider) as SharedPrefsProgressRepository;
    var told = 0;
    c.listen(gameControllerProvider, (_, _) => told++);

    // Nothing changed: nothing is read again, nobody is told.
    reconcileWithSaves(c);
    refreshFromSaves(c, 'case:$caseId');
    expect(told, 0);

    // Another device looked up a word in the same run; the merge was saved.
    final saved = repo.load(caseId);
    final merged = saved.copyWith(lookedUpWords: [...saved.lookedUpWords, 'lantern'], rev: saved.rev + 1);
    repo.saveMerged(episodeId: caseId, progress: merged, queue: false);
    refreshFromSaves(c, 'case:ep99'); // another case: not this one
    expect(told, 0);
    refreshFromSaves(c, 'case:$caseId');
    await wait(t, const Duration(milliseconds: 300));

    expect(told, 1);
    expect(c.read(gameControllerProvider).lookedUpWords, contains('lantern'));
    expect(play.path(), Routes.mission(m.id), reason: 'still on the puzzle');
    expect(t.widget<TextField>(find.byType(TextField)).controller!.text, 'half a wor', reason: 'the typed answer stays');

    // The game's next save is made on top of the merge.
    c.read(gameControllerProvider.notifier).lookUpWord('fog');
    expect(repo.load(caseId).lookedUpWords, containsAll(['lantern', 'fog']));
    expect(t.takeException(), isNull);
  });

  testWidgets('a season merged from the cloud: the case files follow, the open case stays', (t) async {
    final play = MissionPlay();
    await play.openPuzzle(t, const Size(390, 844), 'm02');
    final c = ProviderScope.containerOf(t.element(find.byType(LondonMysteryApp)));
    final repo = c.read(progressRepositoryProvider) as SharedPrefsProgressRepository;
    final before = c.read(gameControllerProvider);
    final season = repo.loadSeason();
    repo.saveMerged(season: season.markSolved('ep01'), queue: false);
    refreshFromSaves(c, 'season');
    await wait(t, const Duration(milliseconds: 300));
    expect(c.read(seasonProvider).isSolved('ep01'), isTrue);
    expect(c.read(gameControllerProvider).completedMissionIds, before.completedMissionIds,
        reason: 'the case being played is not touched');
    expect(play.path(), Routes.mission('m02'));
    expect(t.takeException(), isNull);
  });
}
