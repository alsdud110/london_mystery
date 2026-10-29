import 'dart:io';

import '../season_gen/play_check.dart';
import '../season_gen/plan_ids.dart';
import '../season_gen/plan_models.dart';
import 'asset_plan.dart';

/// Whether the game can show a picture of a generated season, read from
/// the game's code (STEP 3-12A, `lib/` as of 2026-10-29; nothing there is
/// changed by this step).
///
/// * `wired`: the plans already name the file where the game reads it, the
///   generator writes that into the season's content, and the file is in
///   `assets/`: shown now.
/// * `wired_when_made`: the same, but the file is not in `assets/` yet:
///   shown as soon as the picture is made and copied there (STEP 3-15A).
/// * `ready_to_wire`: the game has a place that shows this kind of picture,
///   but nothing names this file there yet: a line in `lib/` (`libEdit`) or
///   a table the generator does not write yet (`generatorExtension`).
/// * `blocked`: the game has such a place, but the picture as planned does
///   not fit it (its shape): plan it again first.
/// * `not_supported`: no screen of the game shows it for a generated season.
enum WiringStatus {
  wired('wired'),
  wiredWhenMade('wired_when_made'),
  readyToWire('ready_to_wire'),
  blocked('blocked'),
  notSupported('not_supported');

  const WiringStatus(this.id);

  final String id;
}

/// Where one picture is (or would be) shown.
class Wiring {
  const Wiring({
    required this.asset,
    required this.status,
    required this.screen,
    required this.field,
    this.via,
    this.missions = const [],
    this.note,
  });

  final PipelineAsset asset;
  final WiringStatus status;

  /// The screen that shows it (null: none).
  final String? screen;

  /// The data it is named in, as the game reads it.
  final String? field;

  /// How it gets there: `generator` (already), `libEdit`, `generatorExtension`.
  final String? via;

  /// The missions it is shown in, when the plans say.
  final List<String> missions;
  final String? note;

  Map<String, Object?> toJson() => {
    'assetId': asset.assetId,
    'type': asset.type,
    'subject': asset.subject,
    'caseIds': asset.caseIds,
    'outputPath': asset.outputPath,
    'status': status.id,
    'screen': screen,
    'field': field,
    'via': via,
    if (missions.isNotEmpty) 'missions': missions,
    'note': ?note,
  };
}

abstract final class AssetWiring {
  /// Every picture of [plan], in the manifest's order. [root]: the
  /// repository's root, where `assets/` is looked in.
  static List<Wiring> of(AssetPlan plan, {String root = '.'}) =>
      [for (final a in plan.assets) wiringOf(a, plan.season!, plan.cases, root: root)];

  /// The screen and the field that show each picture a case plan names
  /// (`PlayCheck.pictureFiles`, its path with the indexes taken out), read
  /// from `lib/` on 2026-10-30: the widget that draws the file.
  static const shownBy = <String, (String, String)>{
    '.play.explore.picture.file': ('Look round (SceneExplore, scene_explore.dart)', 'SeasonContent.explores → ExploreScene.picture'),
    '.play.explore.choices[].picture': ('Look round, its choice page (SceneExplore)', 'SeasonContent.explores → ExplorePicture.picture'),
    '.play.search.picture.file': ('Search (InvestigationSearch, investigation_search.dart)', 'SeasonContent.investigations → InvestigationScene.picture'),
    '.play.search.finds[].picture.file': ('Search, a find laid over the scene (InvestigationSearch)', 'SeasonContent.investigations → InvestigationFind'),
    '.play.dialogue.background': ('Talk with witnesses (DialogueInvestigation)', 'SeasonContent.dialogues → DialogueScene.background'),
    '.play.dialogue.witnesses[].portrait': ('Talk with witnesses (DialogueInvestigation, dialogue_investigation.dart)', 'SeasonContent.dialogues → DialogueSpeaker.portrait'),
    '.puzzle.answerSpec.options[].picture': ('Picture choice (question_widgets.dart)', 'case JSON → ChoiceOption.picture'),
    '.play.talk.portrait': ('Talk before or after a mission (CaseTalk, case_talk.dart)', 'SeasonContent.talkMissions → TalkSpeaker.portraits'),
    '.play.ending[].portrait': ('Final ending (CaseTalk, case_talk.dart)', 'SeasonContent.endings → EndingLine.portrait'),
  };

  /// Whether the generator writes [m] (its puzzle one it makes, not a
  /// development request): only then is a picture it names shown.
  static bool _made(MissionPlan m) {
    final id = m.puzzle.paletteId;
    return id != null &&
        PlayCheck.generatable.containsKey(id) &&
        m.puzzle.engineTable == PlayCheck.generatable[id] &&
        m.puzzle.status != PuzzleStatus.devRequest;
  }

  /// Where [a] is shown, for [season] and its [cases].
  static Wiring wiringOf(PipelineAsset a, SeasonPlan season, List<CasePlan> cases, {String root = '.'}) {
    final id = season.seasonId;
    final made = File('$root/${a.outputPath}').existsSync();
    final generated = made ? WiringStatus.wired : WiringStatus.wiredWhenMade;

    // A picture a case plan names (STEP 3-15A): by where it is named, never
    // by its type or its use alone. Each a field the game draws.
    if (a.type != 'place') {
      final named = <String, List<String>>{};
      final waiting = <String>[];
      for (final c in cases) {
        for (final m in c.allMissions) {
          for (final (path, file) in PlayCheck.pictureFiles(m)) {
            if (file != a.outputPath) continue;
            if (!_made(m)) {
              waiting.add(m.missionId);
              continue;
            }
            (named[path.replaceAll(RegExp(r'\[\d+\]'), '[]')] ??= []).add(m.missionId);
          }
        }
      }
      if (named.isNotEmpty) {
        final shown = [for (final p in named.keys) ?shownBy[p]];
        final story = named.keys.every((p) => p == '.play.talk.portrait' || p == '.play.ending[].portrait');
        final evidence = PlanIds.evidence.hasMatch(a.subject) ? ' As evidence ${a.subject}, its notebook card still needs one '
            'lib/ line (ArtAssets.evidencePictures).' : '';
        return Wiring(
          asset: a,
          status: generated,
          screen: {for (final (screen, _) in shown) screen}.join('; '),
          field: {for (final (_, field) in shown) field}.join('; '),
          via: 'generator',
          missions: {for (final ms in named.values) ...ms}.toList(),
          note: '${story ? 'A face of the story (talk, ending): the mission plays without it, the line shows no face until it is made.' : 'Needed to play: the generator stops without it (asset_file_missing).'}'
              '${made ? '' : ' Not in assets/ yet.'}$evidence'
              '${waiting.isEmpty ? '' : ' Also named by ${waiting.join(', ')}, a development request: not shown there.'}',
        );
      }
    }

    switch (a.type) {
      case 'place':
        final place = season.places.where((p) => p.placeId == a.subject).firstOrNull;
        final missions = [for (final c in cases) for (final m in c.allMissions) if (m.placeId == a.subject) m.missionId];
        if (place == null || place.file != a.outputPath || place.width != a.width || place.height != a.height) {
          return Wiring(
            asset: a,
            status: WiringStatus.blocked,
            screen: 'Mission scene',
            field: 'season.plan.json places[${a.subject}]',
            note: 'season.plan.json does not show this file at this size',
          );
        }
        return Wiring(
          asset: a,
          status: generated,
          screen: 'Mission scene: the place picture of its missions (PlaceArt, LandmarkArt.ofScene, PlaceScenery.scene)',
          field: 'season.plan.json places[${a.subject}].file → SeasonContent.places[\'${a.subject}\'] (ScenePlace); missions name it by sceneKey',
          via: 'generator',
          missions: missions,
          note: 'Shown by the generated content (generate_season.dart); the season itself is not in SeasonCatalog.',
        );
      case 'cover':
        final portrait = a.height > a.width;
        return Wiring(
          asset: a,
          status: portrait ? WiringStatus.readyToWire : WiringStatus.blocked,
          screen: 'World Map season board and the Detective Archives file strip',
          field: 'ArtAssets.seasonCovers[\'$id\'] (SeasonCover: file, pixels, crop, push, archiveLook) in lib/widgets/art_assets.dart',
          via: 'libEdit',
          note: portrait
              ? 'Not shown yet: one SeasonCover line in lib/ (file, pixels ${a.width}×${a.height}, crop, push, archiveLook chosen on '
                  'the drawn picture). Shown by BoxFit.cover: full screen on the season board, a 2:1 band in the archive, a 56×72 thumbnail.'
              : 'A season cover is a portrait painting (London 941×1672, Paris 941×1671) cropped to the 9:16 board; '
                  'a ${a.width}×${a.height} landscape loses most of itself there. Plan it as 1024×1536 first.',
        );
      case 'map':
        return Wiring(
          asset: a,
          status: WiringStatus.readyToWire,
          screen: 'Mission Map',
          field: 'SeasonMap.bySeason[\'$id\'] (artwork, pixels, aspect, landmarks, caseLandmarks) in lib/features/mission_map/map_world.dart',
          via: 'libEdit',
          note: 'Its landmarks are measured on the drawn map and written in lib/. Without a SeasonMap the season\'s Mission Map shows '
              '"not ready", so a released season needs this one.',
        );
      case 'prologue':
        return Wiring(
          asset: a,
          status: WiringStatus.notSupported,
          screen: null,
          field: null,
          note: 'The season openings\' pictures are written per season in lib/ (ArtAssets.season1LondonNight, season2GareDuNord); '
              'SeasonPrologue (season.plan.json prologue) is words only.',
        );
      case 'scene':
        return Wiring(
          asset: a,
          status: WiringStatus.readyToWire,
          screen: 'Story scene before or after a mission (StorySceneScreen)',
          field: 'SeasonContent.storyScenes[<missionId>] (StoryScenes.place / after / next: StoryPicture)',
          via: 'generatorExtension',
          note: 'The table is a SeasonContent one, but the generator writes no storyScenes yet and the manifest names no mission for it '
              '(cases ${a.caseIds.join(', ')}).',
        );
      case 'character':
        return Wiring(
          asset: a,
          status: WiringStatus.notSupported,
          screen: null,
          field: null,
          note: 'No case plan names it: no talk, ending or witness of a generated mission shows this face.',
        );
      case 'object' || 'document':
        if (PlanIds.evidence.hasMatch(a.subject)) {
          final missions = [for (final c in cases) for (final m in c.allMissions) if (m.clueOutputs.evidence == a.subject) m.missionId];
          return Wiring(
            asset: a,
            status: missions.isEmpty ? WiringStatus.blocked : WiringStatus.readyToWire,
            screen: 'Notebook evidence card and its close look (EvidenceCard)',
            field: 'ArtAssets.evidencePictures[\'${a.subject}\'] in lib/widgets/art_assets.dart (square: the round frame; no evidencePrints entry)',
            via: 'libEdit',
            missions: missions,
            note: missions.isEmpty
                ? 'No mission leaves ${a.subject}.'
                : 'No SeasonContent table holds evidence pictures: a generated season needs one lib/ line per evidence id, '
                    'or an engine table the generator could write.'
                    '${a.caseIds.length > 1 ? ' Planned for cases ${a.caseIds.join(', ')}: only ${a.subject} is named; other evidence ids it stands for are not mapped.' : ''}',
          );
        }
        return Wiring(
          asset: a,
          status: WiringStatus.notSupported,
          screen: null,
          field: null,
          note: '${a.subject} is no evidence id and no case plan names its file: no screen shows it.',
        );
    }
    return Wiring(asset: a, status: WiringStatus.notSupported, screen: null, field: null, note: 'type ${a.type}');
  }

  /// The counts by status.
  static Map<String, int> counts(List<Wiring> all) => {
    for (final s in WiringStatus.values) s.id: all.where((w) => w.status == s).length,
  };

  /// What `planning/asset_wiring.json` keeps: the same plans always make the
  /// same file (no time, no machine), for a generator to read back.
  static Map<String, Object?> report(AssetPlan plan, {String root = '.'}) {
    final all = of(plan, root: root);
    return {
      'schemaVersion': 1,
      'seasonId': plan.seasonId,
      'tool': 'tool/asset_pipeline/asset_pipeline.dart --wiring --write',
      'checkedAgainst': 'lib/ as of 2026-10-30 (SeasonContent.places, explores, investigations, dialogues, talkMissions, endings, '
          'ChoiceOption.picture, ArtAssets.seasonCovers, SeasonMap.bySeason, ArtAssets.evidencePictures, SeasonContent.storyScenes); '
          'wired: in assets/ now',
      'counts': counts(all),
      'assets': [for (final w in all) w.toJson()],
    };
  }
}
