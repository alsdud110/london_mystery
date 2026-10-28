import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/content/puzzle_palette.dart';
import 'package:world_mystery/data/models/learning.dart';
import 'package:world_mystery/data/models/mission.dart';

import '../../tool/season_gen/json_schema_lite.dart';
import '../../tool/season_gen/plan_ids.dart';
import '../../tool/season_gen/plan_models.dart';
import 'plan_samples.dart';

/// The plans' JSON Schemas (tool/season_gen/schema/) are validated for
/// real, and keep the same format rules as the Dart models: every document
/// one accepts the other accepts, every one one rejects the other rejects.
void main() {
  const dir = 'tool/season_gen/schema';
  final schemas = SchemaSet.load(dir);

  bool dartAccepts(Object? json, String schema) {
    try {
      schema == 'season_plan.schema.json' ? SeasonPlan.fromJson(json) : CasePlan.fromJson(json);
      return true;
    } on PlanFormatException {
      return false;
    }
  }

  /// [json] as schema [file] and the Dart models read it: both accept, or both reject.
  void agree(Object? json, String file, {required bool valid, String? reason}) {
    final found = schemas.validate(json, file);
    expect(found.isEmpty, valid, reason: '${reason ?? ''} schema: $found');
    expect(dartAccepts(json, file), valid, reason: '${reason ?? ''} Dart model');
  }

  Map<String, Object?> copy(Map<String, Object?> json) => jsonDecode(jsonEncode(json)) as Map<String, Object?>;

  test('the schemas load: draft 2020-12, only keywords the validator knows, every \$ref found', () {
    expect(schemas.files, unorderedEquals([
      'case_plan.schema.json',
      'common.schema.json',
      'mission_plan.schema.json',
      'puzzle_plan.schema.json',
      'season_plan.schema.json',
    ]));
  });

  test('a schema with a keyword the validator does not know is refused, never half checked', () {
    final tmp = Directory.systemTemp.createTempSync('season_gen_schema');
    addTearDown(() => tmp.deleteSync(recursive: true));
    File('${tmp.path}/x.schema.json').writeAsStringSync(jsonEncode({
      r'$schema': SchemaSet.draft,
      'type': 'object',
      'properties': {'a': {'oneOf': <Object?>[]}},
    }));
    expect(() => SchemaSet.load(tmp.path), throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('oneOf'))));
  });

  test('the validator does validate: types, patterns, counts, enums, refs across files', () {
    final bad = copy(sampleCaseJson());
    bad['number'] = 'one';
    ((bad['final'] as Map)['puzzle'] as Map)['surface'] = 'page';
    final found = schemas.validate(bad, 'case_plan.schema.json');
    expect(found, containsAll([r'$.number: not integer', startsWith(r'$.final.puzzle.surface: "page" is not one of')]));
  });

  group('valid plans: both accept', () {
    test('the samples', () {
      agree(sampleSeasonJson(), 'season_plan.schema.json', valid: true);
      agree(sampleCaseJson(), 'case_plan.schema.json', valid: true);
    });

    test('the Paris fixtures', () {
      const root = 'test/fixtures/season_gen/s2_paris';
      agree(jsonDecode(File('$root/season.plan.json').readAsStringSync()), 'season_plan.schema.json', valid: true);
      agree(jsonDecode(File('$root/cases/s2_ep10/case.plan.json').readAsStringSync()), 'case_plan.schema.json', valid: true);
    });

    test('a whole number written 2.0 is a whole number to both', () {
      agree(copy(sampleSeasonJson())..['number'] = 3.0, 'season_plan.schema.json', valid: true);
    });
  });

  // Every object of a plan: where it is in each sample, and its schema.
  final objects = <(String, Map<String, Object?> Function(), List<Object>, String, String)>[
    ('season', sampleSeasonJson, [], 'season_plan.schema.json', '#'),
    ('mainMystery', sampleSeasonJson, ['mainMystery'], 'season_plan.schema.json', '#/\$defs/mainMystery'),
    ('character', sampleSeasonJson, ['characters', 0], 'season_plan.schema.json', '#/\$defs/character'),
    ('location', sampleSeasonJson, ['locations', 0], 'season_plan.schema.json', '#/\$defs/location'),
    ('act', sampleSeasonJson, ['acts', 0], 'season_plan.schema.json', '#/\$defs/act'),
    ('figure', sampleSeasonJson, ['figures', 0], 'season_plan.schema.json', '#/\$defs/figure'),
    ('prologue', sampleSeasonJson, ['prologue'], 'season_plan.schema.json', '#/\$defs/prologue'),
    ('case', sampleCaseJson, [], 'case_plan.schema.json', '#'),
    ('learningGoal', sampleCaseJson, ['learningGoal'], 'case_plan.schema.json', '#/properties/learningGoal'),
    ('mission', sampleCaseJson, ['missions', 1], 'mission_plan.schema.json', '#'),
    ('clueInput', sampleCaseJson, ['missions', 1, 'clueInputs', 0], 'mission_plan.schema.json', '#/\$defs/clueInput'),
    ('clueOutputs', sampleCaseJson, ['missions', 1, 'clueOutputs'], 'mission_plan.schema.json', '#/\$defs/clueOutputs'),
    ('learning', sampleCaseJson, ['missions', 1, 'learning'], 'mission_plan.schema.json', '#/\$defs/learning'),
    ('puzzle', sampleCaseJson, ['final', 'puzzle'], 'puzzle_plan.schema.json', '#'),
    ('answerSpec', sampleCaseJson, ['final', 'puzzle', 'answerSpec'], 'puzzle_plan.schema.json', '#/\$defs/answerSpec'),
    ('option', sampleCaseJson, ['missions', 0, 'puzzle', 'answerSpec', 'options', 0], 'puzzle_plan.schema.json', '#/\$defs/option'),
  ];

  Map<String, Object?> at(Map<String, Object?> json, List<Object> path) {
    Object? node = json;
    for (final p in path) {
      node = p is int ? (node as List)[p] : (node as Map)[p];
    }
    return node as Map<String, Object?>;
  }

  Map<String, Object?> schemaAt(String file, String pointer) {
    Object? node = schemas.schemaOf(file);
    for (final part in pointer.split('/').skip(1)) {
      node = (node as Map)[part];
    }
    return node as Map<String, Object?>;
  }

  group('required and optional fields: the same set to both', () {
    for (final (name, sample, path, file, pointer) in objects) {
      test(name, () {
        final schema = schemaAt(file, pointer);
        final required = (schema['required'] as List? ?? const []).cast<String>().toSet();
        final properties = (schema['properties'] as Map).keys.cast<String>();
        final top = sample == sampleSeasonJson ? 'season_plan.schema.json' : 'case_plan.schema.json';
        final present = at(sample(), path).keys.toSet();
        for (final key in properties) {
          if (!present.contains(key)) continue;
          final json = copy(sample());
          at(json, path).remove(key);
          agree(json, top, valid: !required.contains(key), reason: '$name without $key');
        }
        // Every required field is in the sample, so each was tried.
        expect(present.containsAll(required), isTrue, reason: '$name sample lacks ${required.difference(present)}');
      });
    }
  });

  group('unknown fields: rejected by both, at any depth', () {
    for (final (name, sample, path, _, _) in objects) {
      test(name, () {
        final json = copy(sample());
        at(json, path)['unknownField'] = 'x';
        agree(json, sample == sampleSeasonJson ? 'season_plan.schema.json' : 'case_plan.schema.json', valid: false, reason: name);
      });
    }
  });

  group('wrong values: rejected by both', () {
    final season = <String, void Function(Map<String, Object?>)>{
      'schemaVersion 2': (j) => j['schemaVersion'] = 2,
      'schemaVersion as text': (j) => j['schemaVersion'] = '1',
      'number 0': (j) => j['number'] = 0,
      'number 2.5': (j) => j['number'] = 2.5,
      'plannedCases 10': (j) => j['plannedCases'] = 10,
      'seasonId without a number': (j) => j['seasonId'] = 'tokyo',
      'empty title': (j) => j['title'] = '',
      'no characters': (j) => j['characters'] = <Object?>[],
      'a character id in capitals': (j) => ((j['characters'] as List).first as Map)['charId'] = 'Guide',
      'a landmark key in snake_case': (j) => ((j['locations'] as List).first as Map)['landmarkKey'] = 'central_station',
      'two acts': (j) => (j['acts'] as List).removeLast(),
      'four acts': (j) => (j['acts'] as List).add((j['acts'] as List).first),
      'act4': (j) => ((j['acts'] as List).last as Map)['actId'] = 'act4',
      'an act of five cases': (j) => (((j['acts'] as List).first as Map)['caseIds'] as List).add('s3_ep13'),
      'a case twice in an act': (j) => (((j['acts'] as List).first as Map)['caseIds'] as List)[3] = 's3_ep01',
      'a case id of one digit': (j) => (((j['acts'] as List).first as Map)['caseIds'] as List)[0] = 's3_ep1',
      'outro not lines': (j) => j['outro'] = 'The end.',
      'an empty outro line': (j) => j['outro'] = [''],
      'a prologue first case with no line': (j) => ((j['prologue'] as Map)['firstCase'] as Map).remove('line'),
    };
    for (final MapEntry(key: name, value: change) in season.entries) {
      test('season: $name', () => agree(copy(sampleSeasonJson())..let(change), 'season_plan.schema.json', valid: false, reason: name));
    }

    Map<String, Object?> mission(Map<String, Object?> j) => ((j['missions'] as List)[1] as Map<String, Object?>);
    Map<String, Object?> puzzle(Map<String, Object?> j) => mission(j)['puzzle'] as Map<String, Object?>;
    final cases = <String, void Function(Map<String, Object?>)>{
      'number 13': (j) => j['number'] = 13,
      'caseId with letters': (j) => j['caseId'] = 's3_epXX',
      'actId act0': (j) => j['actId'] = 'act0',
      'no synopsis': (j) => j['synopsis'] = <Object?>[],
      'no locations': (j) => j['locations'] = <Object?>[],
      'a character twice': (j) => j['characters'] = ['guide', 'guide'],
      'no missions': (j) => j['missions'] = <Object?>[],
      'six missions': (j) => j['missions'] = [for (var n = 1; n <= 6; n++) sampleMissionJson(n)],
      'final as a list': (j) => j['final'] = [j['final']],
      'missionId m10': (j) => mission(j)['missionId'] = 's3_ep01_m10',
      'slot M2': (j) => mission(j)['slot'] = 'M2',
      'placeId with no season': (j) => mission(j)['placeId'] = 'station',
      'clueInputs missing ref': (j) => ((mission(j)['clueInputs'] as List).first as Map).remove('ref'),
      'a clue input naming a mission': (j) => ((mission(j)['clueInputs'] as List).first as Map)['ref'] = 's3_ep01_m1',
      'clue use unknown': (j) => ((mission(j)['clueInputs'] as List).first as Map)['use'] = 'remember',
      'evidence id given as a clue id': (j) => (mission(j)['clueOutputs'] as Map)['evidence'] = 's3_ep01_c2',
      'a fact twice': (j) => (mission(j)['clueOutputs'] as Map)['facts'] = ['s3_ep01_f1', 's3_ep01_f1'],
      'learning dependency unknown': (j) => (mission(j)['learning'] as Map)['dependency'] = 'some',
      'learning skill unknown': (j) => (mission(j)['learning'] as Map)['skill'] = 'grammar',
      'recallFrom not a mission': (j) => (mission(j)['learning'] as Map)['recallFrom'] = 's3_ep01_c1',
      'paletteId in capitals': (j) => puzzle(j)['paletteId'] = 'TextChoice',
      'paletteId empty': (j) => puzzle(j)['paletteId'] = '',
      'engineTable snake_case': (j) => puzzle(j)['engineTable'] = 'drum_tapes',
      'surface final': (j) => puzzle(j)['surface'] = 'final',
      'status done': (j) => puzzle(j)['status'] = 'done',
      'missionType quiz': (j) => puzzle(j)['missionType'] = 'quiz',
      'missionType null': (j) => puzzle(j)['missionType'] = null,
      'assetNeeds not ids': (j) => puzzle(j)['assetNeeds'] = ['station.png'],
      'an asset twice': (j) => puzzle(j)['assetNeeds'] = ['s3_sample.asset.a', 's3_sample.asset.a'],
      'empty answer': (j) => (puzzle(j)['answerSpec'] as Map)['answer'] = '',
      'codeLength 0': (j) => (puzzle(j)['answerSpec'] as Map)['codeLength'] = 0,
      'codeFormat date': (j) => (puzzle(j)['answerSpec'] as Map)['codeFormat'] = 'date',
      'an option with no label': (j) => (((puzzle(j)['answerSpec'] as Map)['options'] as List).first as Map).remove('label'),
      'devNote null': (j) => puzzle(j)['devNote'] = null,
    };
    for (final MapEntry(key: name, value: change) in cases.entries) {
      test('case: $name', () => agree(copy(sampleCaseJson())..let(change), 'case_plan.schema.json', valid: false, reason: name));
    }
  });

  group("what a schema cannot say is PlanCheck's: both formats accept it", () {
    // Each of these is reported by PlanCheck (see season_plan_models_test).
    final relational = <String, (Map<String, Object?> Function(), void Function(Map<String, Object?>))>{
      'a number its season id does not say': (sampleSeasonJson, (j) => j['number'] = 4),
      'a case in two acts': (sampleSeasonJson, (j) => (((j['acts'] as List)[1] as Map)['caseIds'] as List)[0] = 's3_ep01'),
      'acts out of order': (sampleSeasonJson, (j) => ((j['acts'] as List).first as Map)['actId'] = 'act3'),
      'missions out of order': (sampleCaseJson, (j) {
        final m = j['missions'] as List;
        m.insert(0, m.removeAt(1));
      }),
      'a final on the mission page': (sampleCaseJson, (j) => ((j['final'] as Map)['puzzle'] as Map)['surface'] = 'mission'),
    };
    for (final MapEntry(key: name, value: (sample, change)) in relational.entries) {
      test(name, () {
        final file = sample == sampleSeasonJson ? 'season_plan.schema.json' : 'case_plan.schema.json';
        agree(copy(sample())..let(change), file, valid: true, reason: name);
      });
    }
  });

  group("the schemas' words are the game's and the models'", () {
    Object? def(String file, String pointer) {
      Object? node = schemas.schemaOf(file);
      for (final part in pointer.split('/').skip(1)) {
        node = (node as Map)[part];
      }
      return node;
    }

    test('id patterns, word for word', () {
      final ids = {
        'seasonId': PlanIds.season,
        'caseId': PlanIds.caseId,
        'missionId': PlanIds.mission,
        'slot': PlanIds.slot,
        'clueId': PlanIds.clue,
        'evidenceId': PlanIds.evidence,
        'factId': PlanIds.fact,
        'clueRef': PlanIds.clueRef,
        'placeId': PlanIds.place,
        'assetId': PlanIds.asset,
        'localId': PlanIds.local,
        'actId': PlanIds.act,
        'landmarkKey': PlanIds.landmark,
        'paletteId': PlanIds.palette,
        'engineTable': PlanIds.table,
      };
      final defs = def('common.schema.json', '#/\$defs') as Map;
      for (final MapEntry(key: name, value: regex) in ids.entries) {
        expect((defs[name] as Map)['pattern'], regex.pattern, reason: name);
      }
      expect(def('puzzle_plan.schema.json', '#/properties/paletteId/pattern'), PlanIds.palette.pattern);
      expect(def('puzzle_plan.schema.json', '#/properties/engineTable/pattern'), PlanIds.table.pattern);
    });

    test("the game's enums", () {
      expect(PlanVocabulary.missionTypes, [for (final t in MissionType.values) t.name]);
      expect(PlanVocabulary.dependencies, [for (final d in LanguageDependency.values) d.name]);
      expect(PlanVocabulary.learningLevels, [for (final l in LearningLevel.values) l.name]);
      expect(PlanVocabulary.skills, [for (final s in LanguageSkill.values) s.name]);
      expect([for (final s in PlanSurface.values) s.name], [for (final s in PuzzleSurface.values) s.name]);
    });

    test("the schemas' enums are the models'", () {
      expect(def('puzzle_plan.schema.json', '#/properties/missionType/enum'), PlanVocabulary.missionTypes);
      expect(def('puzzle_plan.schema.json', '#/properties/surface/enum'), [for (final s in PlanSurface.values) s.name]);
      expect(def('puzzle_plan.schema.json', '#/properties/status/enum'), [for (final s in PuzzleStatus.values) s.name]);
      expect(def('puzzle_plan.schema.json', '#/\$defs/answerSpec/properties/codeFormat/enum'), PlanVocabulary.codeFormats);
      expect(def('mission_plan.schema.json', '#/\$defs/clueInput/properties/use/enum'), [for (final u in ClueUse.values) u.name]);
      expect(def('mission_plan.schema.json', '#/\$defs/learning/properties/dependency/enum'), PlanVocabulary.dependencies);
      expect(def('mission_plan.schema.json', '#/\$defs/learning/properties/level/enum'), PlanVocabulary.learningLevels);
      expect(def('mission_plan.schema.json', '#/\$defs/learning/properties/skill/enum'), PlanVocabulary.skills);
    });

    test("the schemas' counts are the models'", () {
      expect(def('season_plan.schema.json', '#/properties/plannedCases/const'), plannedCasesPerSeason);
      expect(def('season_plan.schema.json', '#/properties/acts/minItems'), actsPerSeason);
      expect(def('season_plan.schema.json', '#/properties/acts/maxItems'), actsPerSeason);
      expect(def('season_plan.schema.json', '#/\$defs/act/properties/caseIds/maxItems'), casesPerAct);
      expect(def('case_plan.schema.json', '#/properties/missions/minItems'), minMissionsPerCase);
      expect(def('case_plan.schema.json', '#/properties/missions/maxItems'), maxMissionsPerCase);
      expect(def('case_plan.schema.json', '#/properties/number/maximum'), plannedCasesPerSeason);
      expect(def('common.schema.json', '#/\$defs/schemaVersion/const'), planSchemaVersion);
    });
  });
}

extension<T> on T {
  T let(void Function(T) change) {
    change(this);
    return this;
  }
}
