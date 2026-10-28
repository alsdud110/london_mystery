import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/season_gen/clue_graph_check.dart';
import '../../tool/season_gen/json_schema_lite.dart';
import '../../tool/season_gen/plan_check.dart';
import '../../tool/season_gen/plan_files.dart';
import '../../tool/season_gen/plan_models.dart';
import '../../tool/season_gen/puzzle_selection_check.dart';
import '../../tool/season_gen/validate_plan.dart' as cli;
import 'plan_samples.dart';

/// The clue graph check (STEP 3-4): every clue a mission is given is found
/// before it, in the plans' play order.
void main() {
  final season = SeasonPlan.fromJson(sampleSeasonJson());

  String idOf(int n) => 's3_ep${n.toString().padLeft(2, '0')}';

  /// The sample case as Case [n]: m1–m3 leave `c<k>`, `e<k>`, `f<k>`, the
  /// final `e4`; each slot is given [inputs] (a short ref is the case's
  /// own) and nothing else.
  Map<String, Object?> caseJson(int n, [Map<String, List<String>> inputs = const {}]) {
    final id = idOf(n);
    final json = jsonDecode(jsonEncode(sampleCaseJson()).replaceAll('s3_ep01', id)) as Map<String, Object?>;
    json['number'] = n;
    json['actId'] = 'act${(n - 1) ~/ 4 + 1}';
    for (final m in [...json['missions']! as List, json['final']]) {
      final mission = m as Map<String, Object?>;
      (mission['learning']! as Map).remove('recallFrom');
      mission['clueInputs'] = [
        for (final ref in inputs[mission['slot']] ?? const <String>[]) {'ref': RegExp(r'^s[0-9]+_ep').hasMatch(ref) ? ref : '${id}_$ref', 'use': 'answerDerivation'},
      ];
    }
    return json;
  }

  CasePlan plan(int n, [Map<String, List<String>> inputs = const {}]) {
    final p = CasePlan.fromJson(caseJson(n, inputs));
    expect(PlanCheck.casePlan(p, season: season), isEmpty, reason: 'a fixture whose structure holds');
    return p;
  }

  List<String> codes(ClueGraphReport r) => [for (final i in r.issues) '${i.severity.name} ${i.code} ${i.caseId} ${i.path}'];

  /// Every output of Case [n] given to a later mission: the next of the
  /// case, or (the final's) the next case's first.
  Map<String, List<String>> chain(int n) => {
    'm1': [if (n > 1) '${idOf(n - 1)}_e4'],
    'm2': ['c1', 'e1', 'f1'],
    'm3': ['c2', 'e2', 'f2'],
    'final': ['c3', 'e3', 'f3'],
  };

  group('clues found before they are used', () {
    test('a clue of mission 1 given to mission 2', () {
      final r = ClueGraphCheck.casePlan(plan(1, {'m2': ['c1']}));
      expect(r.issues, isEmpty);
      expect(r.producersOf('s3_ep01_c1').single.path, r'$.missions[0].clueOutputs.clue');
      expect([for (final s in r.consumersOf('s3_ep01_c1')) (s.missionId, s.path, s.use)], [('s3_ep01_m2', r'$.missions[1].clueInputs[0]', ClueUse.answerDerivation)]);
      expect(r.unresolved, isEmpty);
    });

    test('clues put together for the next, and the final given what the missions found', () {
      final r = ClueGraphCheck.casePlan(plan(1, {'m3': ['c1', 'c2'], 'final': ['c3', 'e2', 'f1']}));
      expect(r.issues, isEmpty);
      expect(r.inputs, 5);
      expect(r.consumersOf('s3_ep01_c3').single.missionId, 's3_ep01_final');
      // A case plan alone never says a clue is unused: a later case may use it.
      expect(r.producers.keys, contains('s3_ep01_e1'));
      expect(r.consumersOf('s3_ep01_e1'), isEmpty);
    });

    test('a clue of Case 01 used in Case 03: left to the season alone, found there', () {
      final c3 = plan(3, {'m1': ['s3_ep01_c1']});
      final alone = ClueGraphCheck.casePlan(c3);
      expect(alone.issues, isEmpty);
      expect([for (final s in alone.unresolved) '${s.clue} ${s.path}'], [r's3_ep01_c1 $.missions[0].clueInputs[0]']);

      final r = ClueGraphCheck.season(season, [c3, plan(1), plan(2)]);
      expect(r.errors, isEmpty);
      expect(r.unresolved, isEmpty);
      expect(r.consumersOf('s3_ep01_c1').single.caseId, 's3_ep03');
      expect(r.complete, isFalse);
      expect(r.warnings, isEmpty, reason: 'cases after them not given: never_used is not judged');
    });

    test('the whole season, every clue used: no warning', () {
      final r = ClueGraphCheck.season(season, [for (var n = 1; n <= 12; n++) plan(n, chain(n))]);
      expect(r.complete, isTrue);
      expect(r.issues, isEmpty);
      // The season's last final ends it: its evidence is used by no one, and that is no warning.
      expect(r.consumersOf('s3_ep12_e4'), isEmpty);
    });

    test('clues never used: warnings, never errors', () {
      final cases = [for (var n = 1; n <= 12; n++) plan(n, n == 5 ? (chain(5)..['m3'] = ['c2']) : chain(n))];
      final r = ClueGraphCheck.season(season, cases);
      expect(r.hasErrors, isFalse);
      expect(codes(r), [
        r'warning clue_never_used s3_ep05 $.missions[1].clueOutputs.evidence',
        r'warning clue_never_used s3_ep05 $.missions[1].clueOutputs.facts[0]',
      ]);
      expect(r.warnings.first.producedAt.single.missionId, 's3_ep05_m2');
      // Case 05 to 11 given without Case 12: what Case 11 leaves may be Case 12's, so it is not judged.
      final partial = ClueGraphCheck.season(season, cases.take(11).toList());
      expect(partial.issues, isEmpty);
    });

    test('a case plan with the clues of the cases before it given', () {
      final c3 = plan(3, {'m1': ['s3_ep01_c1'], 'm2': ['s3_ep02_e4']});
      final r = ClueGraphCheck.casePlan(c3, available: {'s3_ep01_c1', 's3_ep02_e4'});
      expect(r.issues, isEmpty);
      expect(r.unresolved, isEmpty);
      final missing = ClueGraphCheck.casePlan(c3, available: {'s3_ep01_c1'});
      expect(codes(missing), [r'error clue_not_found s3_ep03 $.missions[1].clueInputs[0]']);
    });
  });

  group('clues the player cannot have', () {
    test('a clue no mission leaves', () {
      final r = ClueGraphCheck.casePlan(plan(1, {'m2': ['c9']}));
      expect(codes(r), [r'error clue_not_found s3_ep01 $.missions[1].clueInputs[0]']);
      expect(r.errors.single.clue, 's3_ep01_c9');
      expect(r.errors.single.requiredAt!.missionId, 's3_ep01_m2');

      // Of an earlier case given, of a season's case left by no mission of it, of no case of the season.
      final s = ClueGraphCheck.season(season, [plan(1), plan(2, {'m1': ['s3_ep01_c9'], 'm2': ['s4_ep01_c1']})]);
      expect(codes(s), [
        r'error clue_not_found s3_ep02 $.missions[0].clueInputs[0]',
        r'error clue_not_found s3_ep02 $.missions[1].clueInputs[0]',
      ]);
      expect(s.errors.every((i) => i.acrossCases), isTrue);
    });

    test('a clue asked for before it is found: once, with where it is left', () {
      final r = ClueGraphCheck.casePlan(plan(1, {'m1': ['c3']}));
      expect(codes(r), [r'error clue_used_before_discovery s3_ep01 $.missions[0].clueInputs[0]']);
      final i = r.errors.single;
      expect((i.clue, i.requiredAt!.path, i.producedAt.single.path), ('s3_ep01_c3', r'$.missions[0].clueInputs[0]', r'$.missions[2].clueOutputs.clue'));
      expect(i.cycle, isEmpty);
      expect(i.toString(), contains('left by s3_ep01_m3 at \$.missions[2].clueOutputs.clue'));
      expect(i.toJson()['producedAt'], [
        {'clue': 's3_ep01_c3', 'caseId': 's3_ep01', 'missionId': 's3_ep01_m3', 'path': r'$.missions[2].clueOutputs.clue'},
      ]);
    });

    test('the same clue left twice', () {
      final json = caseJson(1);
      (((json['missions']! as List)[1] as Map)['clueOutputs'] as Map)['clue'] = 's3_ep01_c1';
      final r = ClueGraphCheck.casePlan(CasePlan.fromJson(json));
      expect(codes(r), [r'error clue_duplicate_output s3_ep01 $.missions[1].clueOutputs.clue']);
      expect(r.errors.single.producedAt.single.path, r'$.missions[0].clueOutputs.clue');
      expect(r.producersOf('s3_ep01_c1'), hasLength(2));
    });

    test('a dependency cycle: reported once, on the clue asked for before it is found', () {
      final r = ClueGraphCheck.casePlan(plan(1, {'m1': ['c2'], 'm2': ['c1']}));
      expect(codes(r), [r'error clue_used_before_discovery s3_ep01 $.missions[0].clueInputs[0]']);
      expect(r.errors.single.cycle, ['s3_ep01_m1', 's3_ep01_m2']);

      // Across cases: Case 01 needs Case 02's clue, which needs Case 01's.
      final s = ClueGraphCheck.season(season, [plan(1, {'m1': ['s3_ep02_c1']}), plan(2, {'m1': ['s3_ep01_c1']})]);
      expect(codes(s), [r'error clue_used_before_discovery s3_ep01 $.missions[0].clueInputs[0]']);
      expect(s.errors.single.cycle, ['s3_ep01_m1', 's3_ep02_m1']);
    });

    test('a later case\'s clue used in an earlier case, given or not', () {
      final given = ClueGraphCheck.season(season, [plan(1, {'m2': ['s3_ep03_c1']}), plan(3)]);
      expect(codes(given), [r'error clue_used_before_discovery s3_ep01 $.missions[1].clueInputs[0]']);
      expect(given.errors.single.producedAt.single.caseId, 's3_ep03');
      final notGiven = ClueGraphCheck.season(season, [plan(1, {'m2': ['s3_ep03_c1']})]);
      expect(codes(notGiven), [r'error clue_used_before_discovery s3_ep01 $.missions[1].clueInputs[0]']);
      // The order is the season plan's, not the cases' numbers.
      final swapped = sampleSeasonJson();
      final acts = swapped['acts']! as List;
      (acts[0] as Map)['caseIds'] = ['s3_ep03', 's3_ep02', 's3_ep01', 's3_ep04'];
      final r = ClueGraphCheck.season(SeasonPlan.fromJson(swapped), [plan(1, {'m2': ['s3_ep03_c1']}), plan(3)]);
      expect(r.errors, isEmpty);
    });

    test('a mission given the clue it leaves itself', () {
      final r = ClueGraphCheck.casePlan(plan(1, {'m2': ['c2']}));
      expect(codes(r), [r'error clue_dependency_cycle s3_ep01 $.missions[1].clueInputs[0]']);
      expect(r.errors.single.cycle, ['s3_ep01_m2']);
    });

    test('every finding of a plan, together', () {
      final json = caseJson(1, {'m1': ['c3'], 'm2': ['c2', 'c8'], 'final': ['e4']});
      (((json['missions']! as List)[2] as Map)['clueOutputs'] as Map)['evidence'] = 's3_ep01_e1';
      final r = ClueGraphCheck.casePlan(CasePlan.fromJson(json));
      expect(codes(r), [
        r'error clue_used_before_discovery s3_ep01 $.missions[0].clueInputs[0]',
        r'error clue_dependency_cycle s3_ep01 $.missions[1].clueInputs[0]',
        r'error clue_not_found s3_ep01 $.missions[1].clueInputs[1]',
        r'error clue_duplicate_output s3_ep01 $.missions[2].clueOutputs.evidence',
        r'error clue_dependency_cycle s3_ep01 $.final.clueInputs[0]',
      ]);
      // The season keeps the case's own findings and adds its own.
      // First the plans it cannot place, then each case's own, then the season's.
      final s = ClueGraphCheck.season(season, [CasePlan.fromJson(json), plan(2, {'m1': ['s3_ep01_c7']}), plan(2), CasePlan.fromJson(caseJson(5)..['seasonId'] = 's4_other')]);
      expect(codes(s), [
        r'error case_given_twice s3_ep02 $.caseId',
        r'error case_not_in_season s3_ep05 $.seasonId',
        ...codes(r),
        r'error clue_not_found s3_ep02 $.missions[0].clueInputs[0]',
      ]);
      expect([for (final i in s.issues) i.acrossCases], [true, true, ...List.filled(5, false), true]);
    });

    test('a case plan of no act of the season', () {
      final s = ClueGraphCheck.season(season, [CasePlan.fromJson(caseJson(1)..['caseId'] = 's3_ep13')]);
      expect(codes(s), [r'error case_not_in_season s3_ep13 $.caseId']);
    });
  });

  group('the plans as they are', () {
    const root = 'test/fixtures/season_gen/s2_paris';
    final paris = PlanFiles.loadSeasonPlan('$root/season.plan.json');
    final case10 = PlanFiles.loadCasePlan('$root/cases/s2_ep10/case.plan.json');

    test("Paris Case 10: its own clues found in order, Case 09's left to the season", () {
      final r = ClueGraphCheck.casePlan(case10);
      expect(r.issues, isEmpty);
      expect({for (final s in r.unresolved) s.clue}, {'s2_ep09_e1', 's2_ep09_e2', 's2_ep09_e4'});
      expect([for (final s in r.consumersOf('s2_ep10_c2')) (s.missionId, s.use)], [('s2_ep10_final', ClueUse.textMention)]);
      final s = ClueGraphCheck.season(paris, [case10]);
      expect(s.issues, isEmpty);
      expect((s.complete, s.unresolved.length), (false, 3));
    });

    test('the sample plan: its clues hold, its selection is as it was', () {
      final plan = CasePlan.fromJson(sampleCaseJson());
      expect(ClueGraphCheck.casePlan(plan).issues, isEmpty);
      expect([for (final i in PuzzleSelectionCheck.casePlan(plan).errors) i.code], ['surface_unsupported']);
    });

    group('the command line', () {
      final schemas = SchemaSet.load('tool/season_gen/schema');
      late Directory dir;
      setUp(() => dir = Directory.systemTemp.createTempSync('clues_'));
      tearDown(() => dir.deleteSync(recursive: true));

      test('a clue asked for before it is found fails it; the selection is the same', () {
        final path = '${dir.path}/case.plan.json';
        File(path).writeAsStringSync(PlanFiles.encode(caseJson(1, {'m1': ['c3']})));
        final r = cli.check(path, schemas);
        expect(r.errors, [startsWith('puzzles [surface_unsupported]'), startsWith(r'clues [clue_used_before_discovery] s3_ep01 $.missions[0].clueInputs[0]: s3_ep01_c3')]);
        expect(r.summary, 'puzzles: 3 ready, 0 awaitingAssets, 0 devRequest, 1 with errors');
        expect(r.clueSummary, 'clues: 10 left, 1 asked for, 0 of other cases');
      });

      test('not looked at before the structure holds', () {
        final path = '${dir.path}/case.plan.json';
        File(path).writeAsStringSync(PlanFiles.encode(caseJson(1, {'m1': ['c3']})..['number'] = 2));
        final r = cli.check(path, schemas);
        expect(r.errors.every((e) => e.startsWith('structure ')), isTrue, reason: '${r.errors}');
        expect(r.clues, isNull);
        expect(r.clueSummary, isNull);
      });

      test('Paris Case 10', () {
        final r = cli.check('$root/cases/s2_ep10/case.plan.json', schemas, season: paris);
        expect([...r.errors, ...r.warnings], isEmpty);
        expect(r.summary, 'puzzles: 0 ready, 0 awaitingAssets, 4 devRequest');
        expect(r.clueSummary, 'clues: 7 left, 6 asked for, 3 of other cases');
      });
    });
  });
}
