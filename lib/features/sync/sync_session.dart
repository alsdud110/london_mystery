import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/profile.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/sync/cloud/cloud_catalog.dart';
import '../../data/sync/cloud/cloud_codec.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../game/wallet_controller.dart';

/// What the sync scheduler needs of one profile session (the container
/// `ProfileSessionHost` runs it in): its saves, its profile as saved now,
/// and how to show what a sync changed. Bound to that container only, so a
/// run never touches another profile's game.
class SyncSession {
  SyncSession({
    required this.repo,
    required this.readProfile,
    required this.episodeIds,
    required this.codec,
    required this.applied,
    required this.reconcile,
  });

  /// The session of [container], or null when its saves are not the device's
  /// (tests and previews with saves in memory).
  static SyncSession? of(ProviderContainer container) {
    final repo = container.read(progressRepositoryProvider);
    if (repo is! SharedPrefsProgressRepository) return null;
    final session = container.read(profileSessionProvider);
    final catalog = container.read(episodeCatalogProvider);
    return SyncSession(
      repo: repo,
      readProfile: () => container.read(profileStoreProvider).profile(session.profileId) ?? session.profile,
      episodeIds: [for (final e in catalog) e.id],
      codec: CloudCodec(CloudCatalog.of(catalog)),
      applied: (subject) => refreshFromSaves(container, subject),
      reconcile: () => reconcileWithSaves(container),
    );
  }

  final SharedPrefsProgressRepository repo;
  final List<String> episodeIds;
  final CloudCodec codec;

  /// The profile as saved now (owner, origin, name).
  final DetectiveProfile Function() readProfile;

  /// The sender changed the saves of a subject (see `SyncSender.onApplied`).
  final void Function(String subject) applied;

  /// After a run: whatever on screen differs from the saves is read again.
  final void Function() reconcile;

  String get profileId => repo.profileId;

  DetectiveProfile get profile => readProfile();
}

/// The saves of [subject] changed under the game (a cloud merge): the
/// session's state of it is read again, in the same synchronous step, so the
/// game never saves over the merged result (`case:<id>`, `season`, and
/// `wallet` after a restore). A reset elsewhere (`epoch`)
/// replaced everything: the case, the season and the coins are rebuilt.
void refreshFromSaves(ProviderContainer c, String subject) {
  if (subject == 'epoch') {
    for (final p in [walletProvider, seasonProvider, gameControllerProvider]) {
      if (c.exists(p)) c.invalidate(p);
    }
    return;
  }
  if (subject == 'season' && c.exists(seasonProvider)) c.read(seasonProvider.notifier).reloadFromSaves();
  if (subject == 'wallet' && c.exists(walletProvider)) c.read(walletProvider.notifier).reloadFromSaves();
  if (subject.startsWith('case:') && c.exists(gameControllerProvider)) {
    c.read(gameControllerProvider.notifier).reloadFromSaves(subject.substring('case:'.length));
  }
}

/// Checks the session's case, season and coins against the saves and reads
/// again whatever differs (nothing changes when they agree).
void reconcileWithSaves(ProviderContainer c) {
  if (c.exists(seasonProvider)) c.read(seasonProvider.notifier).reloadFromSaves();
  if (c.exists(gameControllerProvider)) c.read(gameControllerProvider.notifier).reloadFromSaves();
  if (c.exists(walletProvider)) c.read(walletProvider.notifier).reloadFromSaves();
}
