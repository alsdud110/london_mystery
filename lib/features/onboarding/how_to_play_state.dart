import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../season/season_overview.dart';

/// Whether this profile has been through How to Play (finished or skipped).
/// Saved per profile, outside its game saves (see
/// [AppConstants.onboardingSeenKey]): nothing of the game is in it.
class HowToPlaySeenNotifier extends Notifier<bool> {
  String get _key => AppConstants.onboardingSeenKey(ref.read(profileSessionProvider).profileId);

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(_key) ?? false;

  /// Finished, or skipped: either way it is not shown again by itself.
  void complete() {
    if (state) return;
    state = true;
    ref.read(sharedPreferencesProvider).setBool(_key, true);
  }
}

final howToPlaySeenProvider = NotifierProvider<HowToPlaySeenNotifier, bool>(HowToPlaySeenNotifier.new);

/// Whether a detective should be shown How to Play before the season: a
/// detective who has not seen it and has not begun the season. A detective
/// who already plays (a case begun or solved) never gets it by surprise; one
/// who has seen it does not get it again after NEW ADVENTURE.
final needsHowToPlayProvider = Provider<bool>(
  (ref) =>
      ref.watch(gameControllerProvider).hasDetective &&
      !ref.watch(howToPlaySeenProvider) &&
      !ref.watch(seasonOverviewProvider).begun,
);
