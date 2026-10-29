import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/mission_map/map_world.dart';

import 'generated/s3_rome_c01_08/s3_rome_cases.g.dart';
import 'generated/s3_rome_c01_08/s3_rome_season.g.dart';

/// Rome's Cases 01–08 (STEP 3-15B B1, B2): the first eight cases of
/// `content_pipeline/seasons/s3_rome/`, made together by
/// `tool/season_gen/generate_case.dart --slice --out
/// test/sandbox/generated/s3_rome_c01_08`, on the pictures the asset
/// pipeline drew. A slice starting at Case 01, so numbered as the season is.
/// Put in the real app for the tests only, as `rome_slice_season.dart` is:
/// never in `SeasonCatalog.all`, never in `lib/`.
const romeC0108SeasonId = 's3_rome';

/// The eight cases as the game's validator checks a season. Not a constant:
/// its talks are not.
final romeC0108Content = SeasonContent(
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
List<Episode> romeC0108Episodes() => [for (final json in romeC0108Content.episodes.values) Episode.fromJson(json)];

/// The app with the eight cases beside the game's own seasons: Paris's map
/// lent for its pins (Rome's map is not drawn yet), opened unreleased.
List<Override> romeC0108Overrides() => [
  seasonsProvider.overrideWithValue([for (final s in SeasonCatalog.all) s.season, romeC0108Content.season]),
  allEpisodesProvider.overrideWithValue([...MockEpisodeRepository.bundled(), ...romeC0108Episodes()]),
  seasonMapsProvider.overrideWithValue({...SeasonMap.bySeason, romeC0108SeasonId: SeasonMap.paris}),
  seasonReleasedProvider.overrideWithValue((id) => id == romeC0108SeasonId || seasonReleased(id)),
  operatorToolsAvailableProvider.overrideWithValue(true),
];

/// Its places and the season itself, registered as a test's; undone by
/// [unregisterRomeC0108].
void registerRomeC0108() {
  SeasonCatalog.testPlaces.addAll(romeC0108Content.places);
  SeasonCatalog.testSeasons.add(romeC0108Content);
}

void unregisterRomeC0108() {
  SeasonCatalog.testPlaces.clear();
  SeasonCatalog.testSeasons.clear();
}
