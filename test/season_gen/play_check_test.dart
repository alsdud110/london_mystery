import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/constants/app_constants.dart';

import '../../tool/season_gen/plan_check.dart';
import '../../tool/season_gen/plan_files.dart';
import '../../tool/season_gen/plan_models.dart';
import '../../tool/season_gen/play_check.dart';

/// `PlayCheck` (STEP 3-8): what a plan lacks to be made into the game's
/// content, on the sandbox plans and on changed copies of them. A plan with
/// no words written still keeps its format and structure.
void main() {
  const seasonDir = 'content_pipeline/seasons/s9_sandbox';
  final seasonJson = PlanFiles.readJson('$seasonDir/season.plan.json') as Map<String, Object?>;
  final caseJson = PlanFiles.readJson('$seasonDir/cases/s9_ep01/case.plan.json') as Map<String, Object?>;
  final season = SeasonPlan.fromJson(seasonJson);

  Map<String, Object?> copy(Map<String, Object?> json) => jsonDecode(jsonEncode(json)) as Map<String, Object?>;
  Map<String, Object?> mission(Map<String, Object?> j, int i) => (j['missions'] as List)[i] as Map<String, Object?>;
  Map<String, Object?> words(Map<String, Object?> j, int i) => mission(j, i)['play'] as Map<String, Object?>;

  /// The findings on [change]d copies of the sandbox plans, as `[code] path`.
  List<String> found(void Function(Map<String, Object?> c) change, {void Function(Map<String, Object?> s)? inSeason}) {
    final c = copy(caseJson)..let(change);
    final s = copy(seasonJson)..let(inSeason ?? (_) {});
    return [for (final i in PlayCheck.casePlan(CasePlan.fromJson(c), SeasonPlan.fromJson(s))) '[${i.code}] ${i.path}'];
  }

  test('the sandbox case can be made: nothing missing', () {
    expect(PlayCheck.casePlan(CasePlan.fromJson(caseJson), season), isEmpty);
  });

  test('two missions in a row at one map pin (one room) are a case the game plays, not an error', () {
    final w = [for (final i in [0, 1]) words(caseJson, i)];
    expect((w[0]['mapX'], w[0]['mapY']), (w[1]['mapX'], w[1]['mapY']), reason: 'M1 and M2: the front desk');
  });

  test('saved and opened again, the plans are the same, written as they are', () {
    final tmp = Directory.systemTemp.createTempSync('play_check');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final plan = CasePlan.fromJson(caseJson);
    PlanFiles.saveCasePlan(plan, '${tmp.path}/case.plan.json');
    PlanFiles.saveSeasonPlan(season, '${tmp.path}/season.plan.json');
    expect(PlanFiles.loadCasePlan('${tmp.path}/case.plan.json').toJson(), plan.toJson());
    expect(PlanFiles.loadSeasonPlan('${tmp.path}/season.plan.json').toJson(), season.toJson());
    String onDisk(String path) => File(path).readAsStringSync().replaceAll('\r\n', '\n');
    expect(onDisk('${tmp.path}/case.plan.json'), onDisk('$seasonDir/cases/s9_ep01/case.plan.json'), reason: 'the canonical form');
    expect(onDisk('${tmp.path}/season.plan.json'), onDisk('$seasonDir/season.plan.json'), reason: 'the canonical form');
  });

  test('a plan with no words written keeps its format and structure, and is not playable', () {
    final bare = copy(caseJson)..remove('play');
    for (final m in [...bare['missions'] as List, bare['final']]) {
      (m as Map).remove('play');
    }
    final plan = CasePlan.fromJson(bare);
    expect(PlanCheck.casePlan(plan, season: season), isEmpty);
    expect([for (final i in PlayCheck.casePlan(plan, season)) '[${i.code}] ${i.path}'], [
      r'[play_missing] $.play',
      r'[play_missing] $.missions[0].play',
      r'[play_missing] $.missions[1].play',
      r'[play_missing] $.missions[2].play',
      r'[play_missing] $.final.play',
    ]);
  });

  test('each missing word is named by its path, every one at once', () {
    expect(
      found((c) {
        words(c, 1).remove('hints');
        words(c, 1).remove('mapX');
        (c['final'] as Map<String, Object?>)['play'] = {...(c['final'] as Map)['play'] as Map}..remove('transition');
        (c['play'] as Map).remove('caseSummary');
      }),
      [
        r'[play_field_missing] $.play.caseSummary',
        r'[play_field_missing] $.missions[1].play.hints',
        r'[play_field_missing] $.missions[1].play.mapX',
        r'[play_field_missing] $.final.play.transition',
      ],
    );
  });

  test('a choice of two options is refused here, as the game refuses it', () {
    expect(found((c) => ((mission(c, 0)['puzzle'] as Map)['answerSpec'] as Map)['options'] = [
      {'id': 'desk', 'label': 'On the front desk'},
      {'id': 'shelf', 'label': 'On the blue shelf by the window'},
    ]), [r'[play_choice_few] $.missions[0].puzzle.answerSpec.options']);
  });

  test('hints, clues, symbols, pins, lines for the wrong puzzle', () {
    expect(found((c) => words(c, 0)['hints'] = ['One.', 'Two.', 'Three.']), [r'[play_range] $.missions[0].play.hints']);
    expect(found((c) => words(c, 0).remove('clue')), [r'[play_field_missing] $.missions[0].play.clue']);
    expect(found((c) => (c['final'] as Map)['play'] = {...(c['final'] as Map)['play'] as Map, 'clue': {'title': 'T', 'value': 'V', 'note': 'N'}}),
        [r'[play_clue_mismatch] $.final.play.clue']);
    expect(found((c) => (words(c, 0)['evidence'] as Map)['icon'] = 'book'), [r'[play_symbol_unknown] $.missions[0].play.evidence.icon']);
    expect(found((c) => words(c, 0)['lockTitle'] = 'THE DESK LOCK'), [r'[play_range] $.missions[0].play.lockTitle'],
        reason: 'only a letter lock has a plate to name');
    expect(found((c) => words(c, 0)['feedback'] = {'desk': 'No.'}), [r'[play_range] $.missions[0].play.feedback']);
    expect(found((c) => words(c, 0)['orderFeedback'] = 'Wrong order.'), [r'[play_range] $.missions[0].play.orderFeedback']);
    expect(found((c) => words(c, 0)['recall'] = {'title': 'Find it'}), [r'[play_recall] $.missions[0].play.recall']);
  });

  test("places: each mission's registered, of the season, on disk", () {
    expect(found((_) {}, inSeason: (s) => (s['places'] as List).removeAt(1)), [r'[place_unregistered] $.missions[2].placeId']);
    final missing = PlayCheck.casePlan(
      CasePlan.fromJson(caseJson),
      SeasonPlan.fromJson(copy(seasonJson)..let((s) => ((s['places'] as List).first as Map)['file'] = 'assets/none/nothing.png')),
    );
    expect([for (final i in missing) (i.code, i.path, i.inSeason)], [('place_file_missing', r'$.places[0].file', true)]);
  });

  test('a puzzle the generator cannot make yet is named (Paris Case 10: its own engines)', () {
    const root = 'test/fixtures/season_gen/s2_paris';
    final paris = PlayCheck.casePlan(PlanFiles.loadCasePlan('$root/cases/s2_ep10/case.plan.json'), PlanFiles.loadSeasonPlan('$root/season.plan.json'));
    expect(paris.where((i) => i.code == 'generate_unsupported'), hasLength(4));
  });

  test("its numbers are the game's", () {
    expect(PlayCheck.maxHints, AppConstants.maxHints);
    final validator = File('lib/data/content/season_content_validator.dart').readAsStringSync();
    expect(validator, contains("if (ids.length < ${PlayCheck.minChoiceOptions}) out.add('\${ids.length} options: a guess, not a choice');"));
  });

  // STEP 3-13: puzzles played on pictures (the sandbox's Case 03).
  group('scenes and picture options', () {
    final scened = PlanFiles.readJson('$seasonDir/cases/s9_ep03/case.plan.json') as Map<String, Object?>;
    List<String> on(void Function(Map<String, Object?> c) change) =>
        [for (final i in PlayCheck.casePlan(CasePlan.fromJson(copy(scened)..let(change)), season)) '[${i.code}] ${i.path}'];
    Map<String, Object?> scene(Map<String, Object?> j, int i, String key) => words(j, i)[key] as Map<String, Object?>;
    Map<String, Object?> spot(Map<String, Object?> j, int n) => (scene(j, 0, 'explore')['spots'] as List)[n] as Map<String, Object?>;
    Map<String, Object?> witness(Map<String, Object?> j, int n) => (scene(j, 2, 'dialogue')['witnesses'] as List)[n] as Map<String, Object?>;
    Map<String, Object?> option(Map<String, Object?> j, int n) =>
        ((mission(j, 3)['puzzle'] as Map)['answerSpec'] as Map)['options'][n] as Map<String, Object?>;

    test('Case 03 can be made: a look round, a search, a talk, a picture choice, every picture on disk', () {
      expect(on((_) {}), isEmpty);
      expect(PlayCheck.generatable.keys, containsAll(['scene_explore_choose', 'dark_room_search', 'witness_compare', 'picture_choice']));
    });

    test('the scene its engine table reads, and no other', () {
      expect(on((c) => words(c, 0).remove('explore')), ['[play_field_missing] \$.missions[0].play.explore']);
      expect(on((c) => words(c, 0)['search'] = scene(c, 1, 'search')), ['[play_scene_mismatch] \$.missions[0].play.search']);
      // A scene puzzle played from its type alone is not one the generator makes.
      expect(on((c) => (mission(c, 0)['puzzle'] as Map)['engineTable'] = null), contains('[generate_unsupported] \$.missions[0].puzzle.paletteId'));
      expect(on((c) => (mission(c, 0)['puzzle'] as Map)['status'] = 'devRequest'), contains('[generate_unsupported] \$.missions[0].puzzle.paletteId'));
    });

    test('a picture not made yet stops it, never a stand-in; a picture of another size too', () {
      expect(on((c) => (scene(c, 0, 'explore')['picture'] as Map)['file'] = 'assets/seasons/season_09_none/station.png'),
          ['[asset_file_missing] \$.missions[0].play.explore.picture.file']);
      expect(on((c) => ((scene(c, 0, 'explore')['picture'] as Map)['pixels'] as Map)['width'] = 2048),
          ['[asset_size_mismatch] \$.missions[0].play.explore.picture.file']);
      expect(on((c) => (scene(c, 0, 'explore')['choicePixels'] as Map)['height'] = 1086), hasLength(4), reason: 'each poster measured');
      expect(on((c) => witness(c, 1)['portrait'] = 'assets/seasons/season_09_none/juggler.png'),
          ['[asset_file_missing] \$.missions[2].play.dialogue.witnesses[1].portrait']);
      expect(on((c) => option(c, 1)['picture'] = 'assets/seasons/season_09_none/case.png'),
          ['[asset_file_missing] \$.missions[3].puzzle.answerSpec.options[1].picture']);
    });

    test('places measured on the drawn picture, that very file; else it is not made (STEP 3-15A)', () {
      Map<String, Object?> picture(Map<String, Object?> c, int i, String key) => scene(c, i, key)['picture'] as Map<String, Object?>;
      expect(on((c) => picture(c, 0, 'explore').remove('measuredOn')), ['[coordinates_unmeasured] \$.missions[0].play.explore.picture.measuredOn']);
      expect(on((c) => picture(c, 1, 'search').remove('measuredOn')), ['[coordinates_unmeasured] \$.missions[1].play.search.picture.measuredOn']);
      expect(on((c) => picture(c, 0, 'explore')['measuredOn'] = 'sha256:${'0' * 64}'),
          ['[coordinates_stale] \$.missions[0].play.explore.picture.measuredOn'], reason: 'the picture changed since');
      expect(() => on((c) => picture(c, 0, 'explore')['measuredOn'] = 'measured'), throwsA(isA<PlanFormatException>()));
      // A picture not made yet: only that, never its places' measure.
      expect(on((c) => picture(c, 0, 'explore')
        ..['file'] = 'assets/seasons/season_09_none/station.png'
        ..remove('measuredOn')), ['[asset_file_missing] \$.missions[0].play.explore.picture.file']);
    });

    test('every place on a picture is on it, in its pixels', () {
      expect(on((c) => spot(c, 0)['areas'] = [[282, 660, 1600, 848]]), ['[scene_area_invalid] \$.missions[0].play.explore.spots[0].areas[0]']);
      expect(on((c) => spot(c, 0)['areas'] = [[522, 660, 282, 848]]), ['[scene_area_invalid] \$.missions[0].play.explore.spots[0].areas[0]'], reason: 'right before left');
      expect(on((c) => scene(c, 1, 'search')['guideAt'] = [960, 1100]), ['[scene_area_invalid] \$.missions[1].play.search.guideAt']);
    });

    test('a look round: one letter, one choice, its pictures the options', () {
      expect(on((c) => spot(c, 1)['kind'] = 'document'), ['[scene_invalid] \$.missions[0].play.explore.spots']);
      expect(on((c) => spot(c, 2)['requires'] = 'bench'), ['[scene_invalid] \$.missions[0].play.explore.spots[2].requires']);
      expect(on((c) => spot(c, 1).remove('line')), ['[play_field_missing] \$.missions[0].play.explore.spots[1].line']);
      expect(on((c) => (scene(c, 0, 'explore')['choices'] as List).removeLast()), ['[scene_answer_mismatch] \$.missions[0].play.explore.choices']);
    });

    test('a search: each thing where a line of the letter says, word for word', () {
      expect(on((c) => ((scene(c, 1, 'search')['finds'] as List).first as Map)['reportLine'] = 'The button is under a bench.'),
          ['[scene_text_mismatch] \$.missions[1].play.search.finds[0].reportLine']);
      expect(on((c) => ((scene(c, 1, 'search')['finds'] as List)[1] as Map)['id'] = 'button'), ['[scene_invalid] \$.missions[1].play.search.finds']);
    });

    test('a talk: two witnesses agree, one pair only, every question answered', () {
      Map<String, Object?> answer(Map<String, Object?> c, int w, String q) => (witness(c, w)['answers'] as Map)[q] as Map<String, Object?>;
      expect(on((c) => answer(c, 1, 'carry')['thing'] = 'a brown case'), ['[scene_answer_mismatch] \$.missions[2].play.dialogue.deduction.pair']);
      expect(on((c) => answer(c, 2, 'carry')['thing'] = 'a black case'), ['[scene_ambiguous] \$.missions[2].play.dialogue.deduction.pair', '[scene_ambiguous] \$.missions[2].play.dialogue.deduction.pair']);
      expect(on((c) => (scene(c, 2, 'dialogue')['deduction'] as Map)['pair'] = ['flower_seller.carry', 'flower_seller.wearing']),
          containsAll(['[scene_answer_mismatch] \$.missions[2].play.dialogue.deduction.pair[1]']));
      expect(on((c) => (witness(c, 2)['answers'] as Map).remove('when')), ['[scene_invalid] \$.missions[2].play.dialogue.witnesses[2].answers']);
      expect(on((c) => (scene(c, 2, 'dialogue')['deduction'] as Map).remove('thenGoal')), ['[play_field_missing] \$.missions[2].play.dialogue.deduction.thenGoal']);
      expect(on((c) => (scene(c, 2, 'dialogue')['deduction'] as Map)['then'] = ['juggler.hat']), ['[scene_invalid] \$.missions[2].play.dialogue.deduction.then[0]']);
    });

    test('a picture choice: a picture and words for each option, names hidden only there', () {
      expect(on((c) => option(c, 0).remove('picture')), ['[play_field_missing] \$.missions[3].puzzle.answerSpec.options[0].picture']);
      expect(on((c) => option(c, 2).remove('altText')), ['[play_field_missing] \$.missions[3].puzzle.answerSpec.options[2].altText']);
      expect(on((c) => words(c, 0)['hideOptionNames'] = true), ['[play_range] \$.missions[0].play.hideOptionNames']);
    });
  });

  // STEP 3-13B: the story around the puzzles (the sandbox's Case 02).
  group('the story around the puzzles', () {
    final storyJson = PlanFiles.readJson('$seasonDir/cases/s9_ep02/case.plan.json') as Map<String, Object?>;
    Map<String, Object?> fin(Map<String, Object?> c) => (c['final'] as Map<String, Object?>)['play'] as Map<String, Object?>;
    Map<String, Object?> talk(Map<String, Object?> c, int i) => words(c, i)['talk'] as Map<String, Object?>;
    Map<String, Object?> found(Map<String, Object?> c, int i) => words(c, i)['discovery'] as Map<String, Object?>;
    Map<String, Object?> line(Map<String, Object?> c, int i) => (fin(c)['ending'] as List)[i] as Map<String, Object?>;
    List<String> on(void Function(Map<String, Object?> c) change) {
      final c = copy(storyJson)..let(change);
      return [for (final i in PlayCheck.casePlan(CasePlan.fromJson(c), season)) '[${i.code}] ${i.path}'];
    }

    test('Case 02 can be made: talks, discoveries and an ending, nothing missing', () {
      expect(on((_) {}), isEmpty);
      final plan = CasePlan.fromJson(storyJson);
      expect(plan.missions[0].play!.talk!.before!.lines, hasLength(5));
      expect(plan.finalMission.play!.ending, hasLength(5));
      expect(CasePlan.fromJson(plan.toJson()).toJson(), plan.toJson(), reason: 'read back as it is written');
    });

    test('each only where its page plays it: talks and discoveries on missions, endings on finals', () {
      expect(on((c) => fin(c)['talk'] = talk(c, 0)), ['[play_range] \$.final.play.talk']);
      expect(on((c) => fin(c)['discovery'] = found(c, 0)), ['[play_range] \$.final.play.discovery']);
      expect(on((c) => words(c, 2)['ending'] = fin(c)['ending']), ['[play_range] \$.missions[2].play.ending']);
      expect(on((c) => talk(c, 0).remove('before')), ['[play_field_missing] \$.missions[0].play.talk']);
    });

    test('the people are the case\'s, a speaker\'s line names one, the evidence is held by then', () {
      expect(on((c) => talk(c, 0)['speaker'] = 'mrs_lee'), ['[play_story_person] \$.missions[0].play.talk.speaker']);
      expect(on((c) => line(c, 0).remove('speaker')), ['[play_field_missing] \$.final.play.ending[0].speaker']);
      expect(on((c) => line(c, 3)['speaker'] = 'ms_rosa'), ['[play_range] \$.final.play.ending[3].speaker']);
      expect(on((c) => line(c, 1)['evidence'] = 's9_ep03_e1'), ['[play_range] \$.final.play.ending[1].evidence'], reason: 'a later case');
      expect(on((c) => line(c, 1)['evidence'] = 's9_ep02_e9'), ['[play_range] \$.final.play.ending[1].evidence'], reason: 'none of the case');
      expect(on((c) => line(c, 1)['evidence'] = 's9_ep01_e2'), isEmpty, reason: 'an earlier case: in the notebook');
      // A face not drawn yet is the story's (STEP 3-15A): said, never stopping the case.
      expect(on((c) => talk(c, 0)['portrait'] = 'assets/sandbox/not_made.png'), ['[story_picture_missing] \$.missions[0].play.talk.portrait']);
      expect(on((c) => line(c, 0)['portrait'] = 'assets/sandbox/not_made.png'), ['[story_picture_missing] \$.final.play.ending[0].portrait']);
      final c = copy(storyJson)..let((c) => talk(c, 0)['portrait'] = 'assets/sandbox/not_made.png');
      expect([for (final i in PlayCheck.casePlan(CasePlan.fromJson(c), season)) i.blocking], [false]);
    });

    test("a discovery says something of its own, and keeps the game's timing rule", () {
      expect(on((c) => found(c, 0)['detail'] = found(c, 0)['title']), ['[play_range] \$.missions[0].play.discovery.detail']);
      expect(on((c) => found(c, 0)
        ..['timing'] = 'beforePuzzle'
        ..['type'] = 'clueFound'), ['[play_range] \$.missions[0].play.discovery.type']);
      expect(on((c) => found(c, 0)['type'] = 'evidenceFound'), ['[play_range] \$.missions[0].play.discovery.type'], reason: 'found evidence is shown');
      expect(on((c) => found(c, 0)
        ..['type'] = 'evidenceFound'
        ..['showEvidence'] = true), isEmpty);
    });
  });
}

extension<T> on T {
  T let(void Function(T) change) {
    change(this);
    return this;
  }
}
