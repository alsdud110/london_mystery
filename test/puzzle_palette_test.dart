import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/content/puzzle_palette.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';

/// The puzzle palette (`PuzzlePalette`): its lookups and filters, and its
/// metadata held against the code it describes — the models and fields it
/// names, the widgets, the season tables, and the missions the game
/// registers in them (their pages and types).
void main() {
  const readyIds = [
    'text_choice',
    'word_entry',
    'number_entry',
    'combo_dial_lock',
    'letter_tile_lock',
    'order_sequence',
    'scene_explore_choose',
    'lens_inspect_word',
    'trace_deduction',
    'object_decode',
    'spot_difference',
    'room_find_match',
    'layer_reveal',
    'clue_filter_choice',
    'record_mismatch',
    'symbol_dial_lock',
    'viewpoint_match',
    'guided_steps',
    'evidence_talk',
    'picture_choice',
    'dark_room_search',
  ];
  const conditionalIds = [
    'clock_set',
    'witness_compare',
    'scene_compare_report',
    'evidence_board',
    'closeup_compare_choose',
    'token_place_map',
    'symbol_join',
  ];

  group('registry', () {
    test('holds the 28 puzzles of STEP 2-4, each id once, none tied to a city', () {
      final ids = [for (final p in PuzzlePalette.all) p.id];
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids, unorderedEquals([...readyIds, ...conditionalIds]));
      for (final p in PuzzlePalette.all) {
        expect(p.id, matches(RegExp(r'^[a-z]+(_[a-z]+)*$')), reason: p.id);
        for (final city in ['london', 'paris']) {
          expect('${p.id} ${p.name} ${p.description}'.toLowerCase(), isNot(contains(city)), reason: p.id);
        }
      }
    });

    test('every puzzle is found by its id', () {
      for (final p in PuzzlePalette.all) {
        expect(PuzzlePalette.byId(p.id), same(p));
        expect(PuzzlePalette.lookup(p.id), same(p));
        expect(PuzzlePalette.contains(p.id), isTrue);
      }
    });

    test('an unknown id fails plainly', () {
      expect(() => PuzzlePalette.byId('gear_board'), throwsArgumentError);
      expect(PuzzlePalette.lookup('gear_board'), isNull);
      expect(PuzzlePalette.contains(''), isFalse);
    });

    test('grades: 21 ready, 7 conditional, no custom engine offered', () {
      expect([for (final p in PuzzlePalette.ready) p.id], readyIds);
      expect([for (final p in PuzzlePalette.conditional) p.id], conditionalIds);
      expect(PuzzlePalette.ofGrade(PuzzleReuseGrade.custom), isEmpty);
    });

    test('generation modes split the palette, each puzzle in one', () {
      final modes = [PuzzlePalette.textOnly, PuzzlePalette.needingAssets, PuzzlePalette.needingDevelopment];
      expect([for (final m in modes) ...m], unorderedEquals(PuzzlePalette.all));
      for (final mode in PuzzleGenerationMode.values) {
        expect(PuzzlePalette.ofMode(mode).every((p) => p.generationMode == mode), isTrue);
      }
      expect([for (final p in PuzzlePalette.textOnly) p.id], ['text_choice', 'word_entry', 'number_entry', 'combo_dial_lock', 'letter_tile_lock', 'order_sequence']);
    });

    test('nothing that needs development is generatable; pictures to approve are said', () {
      for (final p in PuzzlePalette.needingDevelopment) {
        expect(PuzzlePalette.generatable, isNot(contains(p)), reason: p.id);
      }
      expect(PuzzlePalette.generatable, unorderedEquals([...PuzzlePalette.textOnly, ...PuzzlePalette.needingAssets]));
      for (final p in PuzzlePalette.generatable) {
        expect(p.needsAssetApproval, p.generationMode == PuzzleGenerationMode.requiresAssets, reason: p.id);
      }
      // STEP 3-13: a new season's pictures are files (ChoiceOption.picture,
      // InvestigationScene.picture), and a talk's words are its base level's.
      for (final id in ['picture_choice', 'dark_room_search', 'witness_compare']) {
        expect(PuzzlePalette.byId(id).generationMode, PuzzleGenerationMode.requiresAssets, reason: id);
      }
      expect(PuzzlePalette.byId('clock_set').generationMode, PuzzleGenerationMode.requiresDevelopment, reason: 'its clock face is an Artwork value');
    });

    test('a puzzle that needs pictures is never text only, ready or not', () {
      for (final p in PuzzlePalette.all) {
        if (p.requiredAssets.isNotEmpty) {
          expect(p.generationMode, isNot(PuzzleGenerationMode.textOnly), reason: p.id);
        } else {
          expect(p.generationMode, PuzzleGenerationMode.textOnly, reason: p.id);
        }
      }
      expect(PuzzlePalette.byId('spot_difference').reuseGrade, PuzzleReuseGrade.ready);
      expect(PuzzlePalette.byId('spot_difference').generationMode, PuzzleGenerationMode.requiresAssets);
      expect(PuzzlePalette.byId('text_choice').generationMode, PuzzleGenerationMode.textOnly);
    });

    test('every puzzle has an engine, its data, and the pages it is played on', () {
      for (final p in PuzzlePalette.all) {
        expect(p.playable, isNotEmpty, reason: p.id);
        expect(p.requiredData, isNotEmpty, reason: p.id);
        expect(p.surfaces, isNotEmpty, reason: p.id);
        for (final e in p.engines) {
          expect(e.surfaces, isNotEmpty, reason: '${p.id} ${e.widget}');
          expect(e.missionTypes, isNotEmpty, reason: '${p.id} ${e.widget}');
          expect(e.table == null, e.model == null, reason: '${p.id} ${e.widget}: a table names its model');
        }
        for (final s in PuzzleSurface.values) {
          expect(p.supports(s), p.enginesFor(s).isNotEmpty, reason: '${p.id} $s');
        }
      }
    });

    test('final-only engines are never offered to a mission', () {
      for (final id in ['combo_dial_lock', 'clue_filter_choice', 'evidence_board']) {
        expect(PuzzlePalette.byId(id).surfaces, {PuzzleSurface.finalMission}, reason: id);
      }
      expect(PuzzlePalette.forSurface(PuzzleSurface.mission).map((p) => p.id), isNot(contains('evidence_board')));
      // An optional engine never makes its puzzle playable on its page.
      expect(PuzzlePalette.byId('scene_explore_choose').supports(PuzzleSurface.finalMission), isFalse);
      final compare = PuzzlePalette.byId('closeup_compare_choose');
      expect(compare.engines.every((e) => e.role == PuzzleBindingRole.alternative), isTrue);
      expect(compare.enginesFor(PuzzleSurface.finalMission).map((e) => e.widget), ['LetterMapPuzzle']);
      expect(compare.enginesFor(PuzzleSurface.mission), hasLength(3));
    });
  });

  group('against the code', () {
    final classes = _dartClasses();

    test('every field and picture it names is a field of its model', () {
      for (final p in PuzzlePalette.all) {
        final fields = [
          ...p.requiredData,
          for (final a in [...p.requiredAssets, ...p.optionalAssets]) a.field,
        ];
        for (final f in fields) {
          expect(classes[f.model], isNotNull, reason: '${p.id}: no class ${f.model}');
          expect(classes[f.model], contains(f.name), reason: '${p.id}: $f');
        }
        for (final e in p.engines) {
          if (e.model case final model?) expect(classes, contains(model), reason: '${p.id}: no class $model');
        }
      }
    });

    test('every engine widget is declared where it says', () {
      for (final p in PuzzlePalette.all) {
        for (final e in p.engines) {
          final source = File(e.source);
          expect(source.existsSync(), isTrue, reason: '${p.id}: ${e.source}');
          expect(source.readAsStringSync(), matches(RegExp('^class ${RegExp.escape(e.widget)} ', multiLine: true)), reason: '${p.id}: ${e.widget}');
        }
      }
    });

    test("every table is a season's table, and the game's entries in it keep its page, type and model", () {
      final tableNames = season1Content.missionTables.keys.toSet();
      for (final p in PuzzlePalette.all) {
        for (final e in p.engines.where((e) => e.table != null)) {
          expect(tableNames, contains(e.table), reason: '${p.id}: ${e.table}');
          var used = 0;
          for (final (content, missions) in _contents()) {
            for (final MapEntry(:key, :value) in content.missionTables[e.table]!.entries) {
              final m = missions[key];
              expect(m, isNotNull, reason: '${p.id}: ${e.table} $key is no mission');
              expect(e.surfaces, contains(_surfaceOf(m!)), reason: '${p.id}: ${e.table} $key');
              expect(e.missionTypes, contains(m.type), reason: '${p.id}: ${e.table} $key');
              expect(value.runtimeType.toString(), e.model, reason: '${p.id}: ${e.table} $key');
              used++;
            }
          }
          expect(used, greaterThan(0), reason: '${p.id}: nothing in the game is played on ${e.table}');
        }
      }
    });

    test("a mission played on its type alone keeps its puzzle's page", () {
      final scened = {
        for (final p in PuzzlePalette.all)
          for (final e in p.playable)
            if (e.table case final table?)
              for (final (content, _) in _contents()) ...content.missionTables[table]!.keys,
      };
      for (final p in PuzzlePalette.all) {
        for (final e in p.playable.where((e) => e.table == null)) {
          final played = [
            for (final (_, missions) in _contents())
              for (final m in missions.values)
                if (e.missionTypes.contains(m.type) && !scened.contains(m.id)) m,
          ];
          expect(played, isNotEmpty, reason: '${p.id}: no mission plays it');
          for (final m in played) {
            expect(e.surfaces, contains(_surfaceOf(m)), reason: '${p.id}: ${m.id}');
          }
        }
      }
    });
  });
}

PuzzleSurface _surfaceOf(Mission m) => m.finale ? PuzzleSurface.finalMission : PuzzleSurface.mission;

/// Every season's content (its levels' too), with its missions by id.
List<(SeasonContent, Map<String, Mission>)> _contents() => [
  for (final s in SeasonCatalog.all)
    for (final content in [s, ...s.variants.values])
      (
        content,
        {
          for (final json in {...s.episodes, ...s.awaitingArt}.values)
            for (final m in Episode.fromJson({...json, 'seasonId': s.id}).allMissions) m.id: m,
        },
      ),
];

/// Every class of the game's models, by name: its fields' names.
Map<String, Set<String>> _dartClasses() {
  final out = <String, Set<String>>{};
  final header = RegExp(r'^(?:(?:final|sealed|abstract|base) )*class (\w+)\b[^\n]*\{\s*$', multiLine: true);
  final field = RegExp(r'^  final [^;=()]+? (\w+);', multiLine: true);
  for (final file in Directory('lib/data/models').listSync().whereType<File>().where((f) => f.path.endsWith('.dart'))) {
    final text = file.readAsStringSync();
    for (final c in header.allMatches(text)) {
      final end = text.indexOf('\n}', c.end);
      final body = text.substring(c.end, end < 0 ? text.length : end);
      out.putIfAbsent(c.group(1)!, () => {}).addAll([for (final f in field.allMatches(body)) f.group(1)!]);
    }
  }
  return out;
}
