import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/mission_map/map_world.dart';

import 'generated/s9_sandbox/s9_sandbox_cases.g.dart';
import 'generated/s9_sandbox/s9_sandbox_season.g.dart';

/// The sandbox season (STEP 3-8, 3-9): the content `tool/season_gen/generate_season.dart`
/// made of `content_pipeline/seasons/s9_sandbox/`, put in the real app for the
/// tests only. Never in `SeasonCatalog.all`, never in `lib/`: the app as built
/// has no way to it. Every case the season's folder holds comes in through
/// the generated `s9_sandbox_cases.g.dart`: a new case needs no line here.
const sandboxSeasonId = 's9_sandbox';

/// The season as the game's validator checks a season (`SeasonContentValidator.validate`).
const sandboxContent = SeasonContent(
  info: s9SandboxInfoJson,
  episodes: s9SandboxEpisodes,
  places: s9SandboxPlaces,
  released: false,
  storyGreeting: s9SandboxStoryGreeting,
  learning: s9SandboxLearning,
  languageTopics: s9SandboxLanguageTopics,
  evidenceLinks: s9SandboxEvidenceLinks,
);

/// Its cases as the game reads them.
List<Episode> sandboxEpisodes() => [for (final json in sandboxContent.episodes.values) Episode.fromJson(json)];

/// The app with the sandbox season beside the game's own: its season and
/// cases given to the app, Paris's map lent for its pins (it has none of its
/// own), and it alone opened unreleased (operator tools on, as a preview).
/// With [registerSandboxPlaces] for its places' pictures.
List<Override> sandboxOverrides() => [
  seasonsProvider.overrideWithValue([for (final s in SeasonCatalog.all) s.season, sandboxContent.season]),
  allEpisodesProvider.overrideWithValue([...MockEpisodeRepository.bundled(), ...sandboxEpisodes()]),
  seasonMapsProvider.overrideWithValue({...SeasonMap.bySeason, sandboxSeasonId: SeasonMap.paris}),
  seasonReleasedProvider.overrideWithValue((id) => id == sandboxSeasonId || seasonReleased(id)),
  operatorToolsAvailableProvider.overrideWithValue(true),
];

/// Its places, registered as a test's (`SeasonCatalog.testPlaces`); cleared
/// with `SeasonCatalog.testPlaces.clear` after the test.
void registerSandboxPlaces() => SeasonCatalog.testPlaces.addAll(sandboxContent.places);
