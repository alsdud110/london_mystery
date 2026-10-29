import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/content/puzzle_engine_collisions.dart';
import 'package:world_mystery/data/content/puzzle_palette.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';

import '../../tool/season_gen/json_schema_lite.dart';
import '../../tool/season_gen/plan_files.dart';
import '../../tool/season_gen/plan_models.dart';
import '../../tool/season_gen/puzzle_selection_check.dart';
import '../../tool/season_gen/validate_plan.dart' as cli;
import 'plan_samples.dart';

/// The puzzle selection check (STEP 3-3): a plan's puzzles against the
/// palette's real puzzles and engines.
void main() {
  Map<String, Object?> puzzle(
    String? paletteId, {
    String surface = 'mission',
    String? table,
    required String type,
    Map<String, Object?> answer = const {'answer': 'b'},
    List<String> assets = const [],
    String status = 'ready',
  }) => {
    'paletteId': paletteId,
    'surface': surface,
    'engineTable': table,
    'missionType': type,
    'answerSpec': answer,
    'assetNeeds': assets,
    'status': status,
    if (status == 'devRequest') 'devNote': 'An engine to develop.',
  };

  const abc = {
    'answer': 'b',
    'options': [
      {'id': 'a', 'label': 'Platform 1'},
      {'id': 'b', 'label': 'Platform 2'},
      {'id': 'c', 'label': 'Platform 3'},
    ],
  };
  const hall = ['s3_sample.asset.station_hall'];

  MissionPlan missionOf(Map<String, Object?> p, {bool isFinal = false, List<Object?>? inputs}) {
    final json = isFinal ? sampleFinalJson() : sampleMissionJson(1);
    json['puzzle'] = p;
    if (inputs != null) json['clueInputs'] = inputs;
    return MissionPlan.fromJson(json, r'$.m');
  }

  (List<SelectionIssue>, PuzzleFit) fit(Map<String, Object?> p, {bool isFinal = false, List<Object?>? inputs}) =>
      PuzzleSelectionCheck.mission(missionOf(p, isFinal: isFinal, inputs: inputs), isFinal ? r'$.final' : r'$.missions[0]');

  List<String> found(Map<String, Object?> p, {bool isFinal = false, List<Object?>? inputs}) => [
    for (final i in fit(p, isFinal: isFinal, inputs: inputs).$1) '${i.severity.name} ${i.code} ${i.path}',
  ];

  group('fits', () {
    test('a text-only mission puzzle: ready, and what of it a plan holds', () {
      final (issues, f) = fit(puzzle('text_choice', type: 'multipleChoice', answer: abc));
      expect(issues, isEmpty);
      expect((f.generatable, f.status), (true, PuzzleStatus.ready));
      expect(f.planned, containsAll(['Mission.options', 'Mission.answer', 'ChoiceOption.label']));
      expect(f.words, containsAll(['Mission.letter', 'Mission.question', 'Mission.hints']));
      expect(f.engineData, isEmpty);
    });

    test('a mission puzzle on pictures: awaiting its assets, its engine data left to later', () {
      final (issues, f) = fit(puzzle('scene_explore_choose', table: 'explores', type: 'multipleChoice', answer: abc, assets: hall, status: 'awaitingAssets'));
      expect(issues, isEmpty);
      expect((f.generatable, f.status), (true, PuzzleStatus.awaitingAssets));
      expect(f.engineData, containsAll(['ExploreScene.picture', 'ExploreScene.spots']));
    });

    test('final puzzles: the dial lock, the letter lock with its box, a talk', () {
      expect(found(isFinal: true, puzzle('combo_dial_lock', surface: 'finalMission', type: 'finalCode', answer: {'answer': '7924', 'codeLength': 4, 'dialSymbols': ['clock', 'train', 'park', 'museum']})), isEmpty);
      const time = {
        'answer': 'TIME',
        'options': [
          {'id': 'm', 'label': 'M'},
          {'id': 'e', 'label': 'E'},
          {'id': 't', 'label': 'T'},
          {'id': 'i', 'label': 'I'},
        ],
      };
      expect(found(isFinal: true, puzzle('letter_tile_lock', surface: 'finalMission', type: 'letterLock', answer: time)), isEmpty);
      // Its box (lockBoxes) is pictures: then it awaits them.
      expect(found(isFinal: true, puzzle('letter_tile_lock', surface: 'finalMission', type: 'letterLock', answer: time, assets: hall, status: 'awaitingAssets')), isEmpty);
      expect(found(isFinal: true, puzzle('evidence_talk', surface: 'finalMission', table: 'talks', type: 'examine', answer: {'answer': 'victor'}, assets: hall, status: 'awaitingAssets')), isEmpty);
    });

    test('a palette puzzle whose code must change, as a development request: no error, never generated', () {
      final (issues, f) = fit(isFinal: true, puzzle('evidence_board', surface: 'finalMission', table: 'evidenceBoards', type: 'matchPairs', answer: {'answer': 'q1:e1'}, assets: hall, status: 'devRequest'));
      expect(issues, isEmpty);
      expect(f.generatable, isFalse);
    });

    test('no palette puzzle, as a development request: no error, never generated', () {
      final (issues, f) = fit(puzzle(null, table: 'drumTapes', type: 'matchPairs', answer: {'answer': 'jump:t5'}, status: 'devRequest'));
      expect(issues, isEmpty);
      expect((f.paletteId, f.generatable), (null, false));
    });

    test('of several engines, the one its table names', () {
      expect(found(puzzle('closeup_compare_choose', table: 'holdRacks', type: 'multipleChoice', answer: abc, status: 'devRequest')), isEmpty);
      expect(found(isFinal: true, puzzle('closeup_compare_choose', surface: 'finalMission', table: 'letterMaps', type: 'multipleChoice', answer: abc, status: 'devRequest')), isEmpty);
    });
  });

  group('errors', () {
    test('a palette id the palette has not', () {
      expect(found(puzzle('crossword', type: 'wordInput')), ['error palette_unknown \$.missions[0].puzzle.paletteId']);
    });

    test('no palette id on a puzzle that is not a development request', () {
      expect(found(puzzle(null, type: 'multipleChoice', answer: abc)), ['error palette_missing \$.missions[0].puzzle.paletteId']);
      expect(found(puzzle(null, type: 'multipleChoice', answer: abc, status: 'awaitingAssets')), ['error palette_missing \$.missions[0].puzzle.paletteId']);
    });

    test('a page its palette puzzle is not played on', () {
      // The final's dial on a mission; a mission's look-round on a final; a final's choice on a mission.
      expect(found(puzzle('combo_dial_lock', type: 'finalCode', answer: {'answer': '12'})), ['error surface_unsupported \$.missions[0].puzzle.surface']);
      expect(
        found(isFinal: true, puzzle('scene_explore_choose', surface: 'finalMission', table: 'explores', type: 'multipleChoice', answer: abc, assets: hall, status: 'awaitingAssets')),
        ['error surface_unsupported \$.final.puzzle.surface'],
      );
      expect(found(puzzle('clue_filter_choice', table: 'canvases', type: 'canvasChoice', answer: abc, assets: hall, status: 'awaitingAssets')), ['error surface_unsupported \$.missions[0].puzzle.surface']);
    });

    test('a mission type its engine does not play', () {
      expect(found(puzzle('text_choice', type: 'wordInput', answer: abc)), ['error mission_type_mismatch \$.missions[0].puzzle.missionType']);
      expect(found(puzzle('guided_steps', table: 'easySteps', type: 'sequence', answer: abc, assets: hall, status: 'awaitingAssets')), ['error mission_type_mismatch \$.missions[0].puzzle.missionType']);
    });

    test("an engine table that is not the puzzle's", () {
      final (issues, _) = fit(puzzle('scene_explore_choose', table: 'deductions', type: 'multipleChoice', answer: abc, assets: hall, status: 'awaitingAssets'));
      expect([for (final i in issues) '${i.code} ${i.path}'], ['engine_table_mismatch \$.missions[0].puzzle.engineTable']);
      expect(issues.single.message, contains("trace_deduction's"));
      // Missing; given to an engine played from its type; another page's.
      expect(found(puzzle('scene_explore_choose', type: 'multipleChoice', answer: abc, assets: hall, status: 'awaitingAssets')), ['error engine_table_mismatch \$.missions[0].puzzle.engineTable']);
      expect(found(puzzle('text_choice', table: 'explores', type: 'multipleChoice', answer: abc)), ['error engine_table_mismatch \$.missions[0].puzzle.engineTable']);
      expect(found(puzzle('closeup_compare_choose', table: 'letterMaps', type: 'multipleChoice', answer: abc, status: 'devRequest')), ['error engine_table_mismatch \$.missions[0].puzzle.engineTable']);
    });

    test('an engine laid on the puzzle, named as its engine', () {
      expect(found(puzzle('evidence_talk', table: 'talkMissions', type: 'examine', answer: {'answer': 'x'}, assets: hall, status: 'awaitingAssets')), ['error engine_table_companion \$.missions[0].puzzle.engineTable']);
      expect(found(isFinal: true, puzzle('letter_tile_lock', surface: 'finalMission', table: 'lockBoxes', type: 'letterLock', answer: abc, assets: hall, status: 'awaitingAssets')), contains('error engine_table_companion \$.final.puzzle.engineTable'));
    });

    test('a puzzle whose code must change, planned as ready or awaiting its assets', () {
      const time = {'answer': '0915', 'codeLength': 4, 'codeFormat': 'time'};
      expect(found(puzzle('clock_set', table: 'clocks', type: 'numberCode', answer: time)), contains('error not_generatable \$.missions[0].puzzle.status'));
      expect(found(puzzle('clock_set', table: 'clocks', type: 'numberCode', answer: time, assets: hall, status: 'awaitingAssets')), ['error not_generatable \$.missions[0].puzzle.status']);
      // STEP 3-13: a picture choice takes a season's own picture files now, so
      // it is planned as any puzzle with pictures to make.
      expect(found(puzzle('picture_choice', type: 'imageChoice', answer: abc, assets: hall, status: 'awaitingAssets')), isEmpty);
      expect(found(puzzle('picture_choice', type: 'imageChoice', answer: abc)), contains('error status_mode_conflict \$.missions[0].puzzle.status'));
    });

    test('a status its generation mode does not allow', () {
      // Pictures to make, planned ready (and its engine data is not in a plan).
      expect(found(puzzle('scene_explore_choose', table: 'explores', type: 'multipleChoice', answer: abc, assets: hall)), [
        'error status_mode_conflict \$.missions[0].puzzle.status',
        'error ready_unmodelled_data \$.missions[0].puzzle.status',
      ]);
      // Text only: as a development request, or waiting for no picture.
      expect(found(puzzle('text_choice', type: 'multipleChoice', answer: abc, status: 'devRequest')), ['error status_mode_conflict \$.missions[0].puzzle.status']);
      expect(found(puzzle('text_choice', type: 'multipleChoice', answer: abc, status: 'awaitingAssets')), ['error status_mode_conflict \$.missions[0].puzzle.status']);
      // Ready, but asking for pictures.
      expect(found(isFinal: true, puzzle('combo_dial_lock', surface: 'finalMission', type: 'finalCode', answer: {'answer': '12'}, assets: hall)), contains('error status_mode_conflict \$.final.puzzle.status'));
    });

    test('no picture asked for by a puzzle on pictures', () {
      expect(found(puzzle('scene_explore_choose', table: 'explores', type: 'multipleChoice', answer: abc, status: 'awaitingAssets')), ['error asset_needs_missing \$.missions[0].puzzle.assetNeeds']);
    });

    test('data its engine plays with, missing', () {
      expect(found(puzzle('text_choice', type: 'multipleChoice')), ['error required_data_missing \$.missions[0].puzzle.answerSpec.options']);
      expect(found(puzzle('order_sequence', type: 'sequence', answer: {'answer': 'a,b'})), ['error required_data_missing \$.missions[0].puzzle.answerSpec.options']);
      // Compared with an earlier evidence, but none is brought.
      final corner = puzzle('viewpoint_match', table: 'cornerChoices', type: 'multipleChoice', answer: abc, assets: hall, status: 'awaitingAssets');
      expect(found(corner, inputs: const []), ['error required_data_missing \$.missions[0].clueInputs']);
      expect(found(corner, inputs: const [{'ref': 's3_ep01_e1', 'use': 'recall'}]), isEmpty);
    });

    test('an answer its data cannot give', () {
      String at(String f) => 'error answer_mismatch \$.missions[0].puzzle.answerSpec.$f';
      expect(found(puzzle('text_choice', type: 'multipleChoice', answer: {...abc, 'answer': 'd'})), [at('answer')]);
      expect(found(puzzle('number_entry', type: 'numberCode', answer: {'answer': '9:10'})), [at('answer')]);
      expect(found(puzzle('number_entry', type: 'numberCode', answer: {'answer': '910', 'codeLength': 4})), [at('codeLength')]);
      expect(found(puzzle('number_entry', type: 'numberCode', answer: {'answer': '910', 'codeFormat': 'time'})), [at('codeFormat')]);
      expect(found(puzzle('word_entry', type: 'wordInput', answer: {'answer': '!?'})), [at('answer')]);
      expect(found(isFinal: true, puzzle('combo_dial_lock', surface: 'finalMission', type: 'finalCode', answer: {'answer': '12', 'dialSymbols': ['clock', 'tower']})), [
        'error answer_mismatch \$.final.puzzle.answerSpec.dialSymbols[1]',
      ]);
      expect(found(isFinal: true, puzzle('combo_dial_lock', surface: 'finalMission', type: 'finalCode', answer: {'answer': '123', 'dialSymbols': ['clock']})), [
        'error answer_mismatch \$.final.puzzle.answerSpec.dialSymbols',
      ]);
      expect(found(puzzle('order_sequence', type: 'sequence', answer: {...abc, 'answer': 'c,a,d'})), [at('answer')]);
      // Three options for three steps: each once. Two options for four steps: again and again.
      expect(found(puzzle('order_sequence', type: 'sequence', answer: {...abc, 'answer': 'c,a,a'})), [at('answer')]);
      const turns = {
        'answer': 'l,r,l,r',
        'options': [
          {'id': 'l', 'label': 'LEFT'},
          {'id': 'r', 'label': 'RIGHT'},
        ],
      };
      expect(found(puzzle('order_sequence', type: 'sequence', answer: turns)), isEmpty);
      expect(found(isFinal: true, puzzle('letter_tile_lock', surface: 'finalMission', type: 'letterLock', answer: {...abc, 'answer': 'TIME'})), ['error answer_mismatch \$.final.puzzle.answerSpec.answer']);
    });

    test('the sample case: its final is a mission puzzle on the final page', () {
      final report = PuzzleSelectionCheck.casePlan(CasePlan.fromJson(sampleCaseJson()));
      expect([for (final i in report.errors) '${i.code} ${i.path}'], ['surface_unsupported \$.final.puzzle.surface']);
    });
  });

  group('warnings, never a failure', () {
    Map<String, Object?> caseJson(int number, List<String> palette) {
      final json = sampleCaseJson();
      final id = 's3_ep${number.toString().padLeft(2, '0')}';
      json
        ..['caseId'] = id
        ..['number'] = number
        ..['actId'] = 'act${(number - 1) ~/ 4 + 1}';
      final missions = [for (final m in json['missions']! as List) m as Map<String, Object?>];
      json['missions'] = missions;
      for (final (i, m) in missions.indexed) {
        m['missionId'] = '${id}_m${i + 1}';
        m['puzzle'] = switch (palette[i]) {
          'number_entry' => puzzle('number_entry', type: 'numberCode', answer: {'answer': '910'}),
          'word_entry' => puzzle('word_entry', type: 'wordInput', answer: {'answer': 'NINE'}),
          'order_sequence' => puzzle('order_sequence', type: 'sequence', answer: {...abc, 'answer': 'c,a,b'}),
          final p => puzzle(p, type: 'multipleChoice', answer: abc),
        };
      }
      json['final'] = {
        ...sampleFinalJson(),
        'missionId': '${id}_final',
        'puzzle': puzzle('combo_dial_lock', surface: 'finalMission', type: 'finalCode', answer: {'answer': '12'}),
      };
      return json;
    }

    test('the same puzzle twice in a case', () {
      final report = PuzzleSelectionCheck.casePlan(CasePlan.fromJson(caseJson(1, ['text_choice', 'number_entry', 'text_choice'])));
      expect(report.hasErrors, isFalse);
      expect([for (final i in report.warnings) '${i.code} ${i.path}'], ['repeated_in_case \$.missions[2].puzzle.paletteId']);
    });

    test('one puzzle for more than half of the cases given', () {
      List<String> codes(List<CasePlan> c) => [for (final i in PuzzleSelectionCheck.season(c)) i.code];
      final heavy = [
        CasePlan.fromJson(caseJson(1, ['text_choice', 'text_choice', 'text_choice'])),
        CasePlan.fromJson(caseJson(2, ['text_choice', 'text_choice', 'word_entry'])),
      ];
      // Five of the eight puzzles (two finals each a dial lock).
      expect(codes(heavy), ['season_concentration']);
      // Four of eight: half, not more.
      final even = [
        CasePlan.fromJson(caseJson(1, ['text_choice', 'text_choice', 'word_entry'])),
        CasePlan.fromJson(caseJson(2, ['text_choice', 'text_choice', 'number_entry'])),
      ];
      expect(codes(even), isEmpty);
      expect(codes(heavy.take(1).toList()), isEmpty, reason: 'one case: its repeats are the case\'s own warnings');
    });

    test('a later act with fewer kinds of puzzle', () {
      final act1 = [for (var n = 1; n <= 4; n++) CasePlan.fromJson(caseJson(n, ['text_choice', 'word_entry', 'order_sequence']))];
      final act2 = [for (var n = 5; n <= 8; n++) CasePlan.fromJson(caseJson(n, ['text_choice', 'word_entry', 'text_choice']))];
      final found = PuzzleSelectionCheck.season([...act1, ...act2]);
      expect([for (final i in found) '${i.code} ${i.path}'], ['late_diversity_drop act2']);
      // An act not all given is not compared.
      expect(PuzzleSelectionCheck.season([...act1, ...act2.take(3)]), isEmpty);
    });

    test('warnings alone pass the command line', () {
      final dir = Directory.systemTemp.createTempSync('selection_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}/case.plan.json';
      File(path).writeAsStringSync(PlanFiles.encode(caseJson(1, ['text_choice', 'number_entry', 'text_choice'])));
      final r = cli.check(path, SchemaSet.load('tool/season_gen/schema'));
      expect(r.errors, isEmpty);
      expect(r.warnings, ['puzzles [repeated_in_case] \$.missions[2].puzzle.paletteId: text_choice again (also at \$.missions[0].puzzle)']);
      expect(r.summary, 'puzzles: 4 ready, 0 awaitingAssets, 0 devRequest');
    });
  });

  group('the command line, in order', () {
    final schemas = SchemaSet.load('tool/season_gen/schema');
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('selection_'));
    tearDown(() => dir.deleteSync(recursive: true));

    String write(Map<String, Object?> json) {
      final path = '${dir.path}/case.plan.json';
      File(path).writeAsStringSync(PlanFiles.encode(json));
      return path;
    }

    test('a puzzle that cannot be made fails it, with its code and place', () {
      final r = cli.check(write(sampleCaseJson()), schemas);
      expect(r.errors, [startsWith('puzzles [surface_unsupported] \$.final.puzzle.surface: scene_explore_choose is played on mission only')]);
      expect(r.summary, contains('1 with errors'));
    });

    test('the selection is not looked at before the structure holds', () {
      final json = sampleCaseJson()..['number'] = 2;
      final r = cli.check(write(json), schemas);
      expect(r.errors, isNotEmpty);
      expect(r.errors.every((e) => e.startsWith('structure ')), isTrue, reason: '${r.errors}');
      expect(r.selection, isNull);
    });
  });

  test('Paris Case 10: a plan that keeps its format and structure, none of it made from the palette', () {
    const root = 'test/fixtures/season_gen/s2_paris';
    final season = PlanFiles.loadSeasonPlan('$root/season.plan.json');
    final r = cli.check('$root/cases/s2_ep10/case.plan.json', SchemaSet.load('tool/season_gen/schema'), season: season);
    expect([...r.errors, ...r.warnings], isEmpty);
    expect([for (final f in r.selection!.fits) (f.paletteId, f.status, f.generatable)], List.filled(4, (null, PuzzleStatus.devRequest, false)));
    expect(r.summary, 'puzzles: 0 ready, 0 awaitingAssets, 4 devRequest');
  });

  test("the game's own puzzles on palette engines, planned as they are, all fit", () {
    var n = 0;
    final covered = <String>{};
    for (final season in SeasonCatalog.all) {
      for (final slot in PuzzleEngineCollisionCheck.slotsOf(season)) {
        final id = slot.paletteId;
        if (id == null) continue;
        final m = slot.mission;
        final mode = PuzzlePalette.byId(id).generationMode;
        final p = PuzzlePlan(
          paletteId: id,
          surface: PlanSurface.values.byName(slot.surface.name),
          engineTable: slot.active!.table,
          missionType: m.type.name,
          answerSpec: AnswerSpec(
            answer: m.answer,
            acceptedAnswers: m.acceptedAnswers,
            options: [for (final o in m.options) OptionPlan(id: o.id, label: o.label, feedback: o.feedback, altText: o.altText)],
            codeLength: m.codeLength,
            codeFormat: m.codeFormat,
            dialSymbols: m.dialSymbols,
          ),
          assetNeeds: mode == PuzzleGenerationMode.textOnly ? const [] : hall,
          status: switch (mode) {
            PuzzleGenerationMode.textOnly => PuzzleStatus.ready,
            PuzzleGenerationMode.requiresAssets => PuzzleStatus.awaitingAssets,
            PuzzleGenerationMode.requiresDevelopment => PuzzleStatus.devRequest,
          },
        );
        final plan = MissionPlan(
          missionId: 's3_ep01_m1',
          slot: m.finale ? 'final' : 'm1',
          placeId: 's3_sample.station',
          puzzle: p,
          clueInputs: [if (m.recall != null) const ClueInput(ref: 's3_ep01_e1', use: ClueUse.recall)],
          clueOutputs: const ClueOutputs(evidence: 's3_ep01_e9'),
          learning: const LearningPlan(dependency: 'low', level: 'exposure', objective: '-'),
        );
        final (issues, _) = PuzzleSelectionCheck.mission(plan, m.id);
        expect(issues, isEmpty, reason: '${season.id} ${m.id} ($id): $issues');
        n++;
        covered.add(id);
      }
    }
    expect(n, greaterThan(60));
    // Every puzzle played from its type alone, whose answer data is checked whole.
    expect(covered, containsAll(['text_choice', 'word_entry', 'number_entry', 'combo_dial_lock', 'letter_tile_lock', 'order_sequence', 'picture_choice']));
  });
}
