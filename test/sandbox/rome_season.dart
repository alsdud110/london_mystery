import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/mission_map/map_world.dart';

import 'generated/s3_rome/s3_rome_cases.g.dart';
import 'generated/s3_rome/s3_rome_season.g.dart';

/// Rome, the whole season (STEP 3-15B B3): the twelve cases of
/// `content_pipeline/seasons/s3_rome/`, made by the season's own path
/// (`tool/season_planner/plan_season.dart generate`, that is
/// `generate_season.dart --target sandbox`) on the pictures the asset
/// pipeline drew. Put in the real app for the tests only, as
/// `rome_slice_season.dart` is: never in `SeasonCatalog.all`, never in
/// `lib/`. Not registered as a season of the game (STEP 3-15B: not yet).
const romeSeasonId = 's3_rome';

/// The twelve cases as the game's validator checks a season. Not a
/// constant: its talks are not.
final romeContent = SeasonContent(
  info: s3RomeInfoJson,
  episodes: s3RomeEpisodes,
  places: s3RomePlaces,
  released: false,
  storyGreeting: s3RomeStoryGreeting,
  learning: s3RomeLearning,
  languageTopics: s3RomeLanguageTopics,
  evidenceLinks: s3RomeEvidenceLinks,
  explores: s3RomeExplores,
  investigations: s3RomeInvestigations,
  dialogues: s3RomeDialogues,
  talkMissions: s3RomeTalkMissions,
  discoveries: s3RomeDiscoveries,
  endings: s3RomeEndings,
);

/// Its cases as the game reads them, in play order.
List<Episode> romeEpisodes() => [for (final json in romeContent.episodes.values) Episode.fromJson(json)];

/// The app with Rome beside the game's own seasons: Paris's map lent for its
/// pins (Rome's map is not drawn yet), opened unreleased.
List<Override> romeOverrides() => [
  seasonsProvider.overrideWithValue([for (final s in SeasonCatalog.all) s.season, romeContent.season]),
  allEpisodesProvider.overrideWithValue([...MockEpisodeRepository.bundled(), ...romeEpisodes()]),
  seasonMapsProvider.overrideWithValue({...SeasonMap.bySeason, romeSeasonId: SeasonMap.paris}),
  seasonReleasedProvider.overrideWithValue((id) => id == romeSeasonId || seasonReleased(id)),
  operatorToolsAvailableProvider.overrideWithValue(true),
];

/// Its places and the season itself, registered as a test's; undone by
/// [unregisterRome].
void registerRome() {
  SeasonCatalog.testPlaces.addAll(romeContent.places);
  SeasonCatalog.testSeasons.add(romeContent);
}

void unregisterRome() {
  SeasonCatalog.testPlaces.clear();
  SeasonCatalog.testSeasons.clear();
}
