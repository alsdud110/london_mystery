import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/mission_map/map_world.dart';

import 'generated/s3_rome_slice/s3_rome_cases.g.dart';
import 'generated/s3_rome_slice/s3_rome_season.g.dart';

/// Rome's first playable case (STEP 3-15A): Case 05 as
/// `tool/season_gen/generate_case.dart --slice` made it of
/// `content_pipeline/seasons/s3_rome/`, its pictures the asset pipeline's.
/// Put in the real app for the tests only, as the sandbox season is
/// (`sandbox_season.dart`): never in `SeasonCatalog.all`, never in `lib/`.
const romeSliceSeasonId = 's3_rome';

/// The slice as the game's validator checks a season. Not a constant: its
/// talks are not.
final romeSliceContent = SeasonContent(
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

/// Its cases as the game reads them.
List<Episode> romeSliceEpisodes() => [for (final json in romeSliceContent.episodes.values) Episode.fromJson(json)];

/// The app with the slice beside the game's own seasons: Paris's map lent
/// for its pins (Rome's map is not drawn yet), opened unreleased.
List<Override> romeSliceOverrides() => [
  seasonsProvider.overrideWithValue([for (final s in SeasonCatalog.all) s.season, romeSliceContent.season]),
  allEpisodesProvider.overrideWithValue([...MockEpisodeRepository.bundled(), ...romeSliceEpisodes()]),
  seasonMapsProvider.overrideWithValue({...SeasonMap.bySeason, romeSliceSeasonId: SeasonMap.paris}),
  seasonReleasedProvider.overrideWithValue((id) => id == romeSliceSeasonId || seasonReleased(id)),
  operatorToolsAvailableProvider.overrideWithValue(true),
];

/// Its places and the season itself, registered as a test's
/// (`SeasonCatalog.testPlaces`, `testSeasons`); undone by
/// [unregisterRomeSlice].
void registerRomeSlice() {
  SeasonCatalog.testPlaces.addAll(romeSliceContent.places);
  SeasonCatalog.testSeasons.add(romeSliceContent);
}

void unregisterRomeSlice() {
  SeasonCatalog.testPlaces.clear();
  SeasonCatalog.testSeasons.clear();
}
