import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/season_gen/content_hash.dart';
import '../../tool/season_gen/dart_literal.dart';
import '../../tool/season_gen/generate_case.dart';
import '../../tool/season_gen/season_cases.dart';

/// The Dart generator (STEP 3-8, 3-9) on copies of the sandbox plans: the
/// season's cases found in its folder and made together, in play order; the
/// same plans make the same bytes; nothing is made when one case fails, a
/// case is missing before another or a folder is no case of the season;
/// a generated file changed by hand is never written over; a write that
/// fails leaves the files as they were; a Windows checkout's CRLF reads as
/// the LF it was written with. (The content it makes is checked and played
/// in `test/sandbox/`.)
void main() {
  const seasonDir = 'content_pipeline/seasons/s9_sandbox';
  late Directory tmp;
  late String dir, season, casePath, case02Path, out;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('generate_case');
    dir = '${tmp.path.replaceAll(r'\', '/')}/seasons/s9_sandbox';
    season = '$dir/season.plan.json';
    casePath = '$dir/cases/s9_ep01/case.plan.json';
    case02Path = '$dir/cases/s9_ep02/case.plan.json';
    out = '${tmp.path}/generated';
    File(casePath).createSync(recursive: true);
    File(case02Path).createSync(recursive: true);
    File('$seasonDir/season.plan.json').copySync(season);
    File('$seasonDir/cases/s9_ep01/case.plan.json').copySync(casePath);
    File('$seasonDir/cases/s9_ep02/case.plan.json').copySync(case02Path);
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Generated make([List<String>? cases]) => CaseGenerator.sandbox(seasonPath: season, casePaths: cases ?? SeasonCases.of(season));
  Map<String, Object?> read(String path) => jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
  void edit(String path, void Function(Map<String, Object?> json) change) {
    final json = read(path);
    change(json);
    File(path).writeAsStringSync(jsonEncode(json));
  }

  Matcher failsWith(Object lines) => throwsA(isA<GenerateFailure>().having((e) => e.lines, 'lines', lines));

  group('the season folder', () {
    test("its case plans, in the season's play order", () {
      expect(SeasonCases.of(season), [casePath, case02Path]);
    });

    test('a folder of no case of the season, or a case folder with no plan, is refused', () {
      Directory('$dir/cases/s8_ep01').createSync();
      Directory('$dir/cases/s9_ep04').createSync();
      expect(() => SeasonCases.of(season), failsWith([
        'FAILED  $season',
        '  error    [case_not_in_season] cases/s8_ep01: not a case of s9_sandbox (its acts)',
        '  error    [case_plan_missing] cases/s9_ep04: no case.plan.json',
      ]));
    });

    test('no case written is refused', () {
      Directory('$dir/cases').deleteSync(recursive: true);
      expect(() => SeasonCases.of(season), failsWith(contains(contains('[no_cases]'))));
    });
  });

  group('the cases made together', () {
    test('the season, each case, the list of cases and their manifest, from the plans alone, the same each time', () {
      final made = make();
      expect(made.files.keys, ['s9_sandbox_season.g.dart', 's9_ep01.g.dart', 's9_ep02.g.dart', 's9_sandbox_cases.g.dart', manifestName]);
      expect(make().files, made.files);
      expect(make([case02Path, casePath]).files, made.files, reason: 'in play order, whatever order they are given in');
      for (final MapEntry(:key, :value) in made.files.entries) {
        if (key.endsWith('.dart')) expect(value, startsWith('$generatedHeader\n// source: '), reason: key);
        expect(value, isNot(contains('\r')), reason: '$key: LF only');
      }
      final manifest = jsonDecode(made.files[manifestName]!) as Map<String, Object?>;
      expect(manifest['generatorVersion'], generatorVersion);
      expect(manifest['cases'], ['s9_ep01', 's9_ep02']);
      expect(manifest['inputs'], {
        'season.plan.json': ContentHash.ofJson(read(season)),
        'cases/s9_ep01/case.plan.json': ContentHash.ofJson(read(casePath)),
        'cases/s9_ep02/case.plan.json': ContentHash.ofJson(read(case02Path)),
      });
      expect(manifest['outputs'], {
        for (final MapEntry(:key, :value) in made.files.entries)
          if (key != manifestName) key: ContentHash.ofBytes(utf8.encode(value)),
      });
      expect(made.files[manifestName], isNot(contains(RegExp(r'20\d\d-'))), reason: 'no time in it');
      final list = made.files['s9_sandbox_cases.g.dart']!;
      expect(list, contains("import 's9_ep01.g.dart';\nimport 's9_ep02.g.dart';\n"));
      expect(list, contains("  's9_ep01': s9Ep01Json,\n  's9_ep02': s9Ep02Json,\n"));
    });

    test('the first case alone is the season so far: a list of one', () {
      final made = make([casePath]);
      expect(made.files.keys, ['s9_sandbox_season.g.dart', 's9_ep01.g.dart', 's9_sandbox_cases.g.dart', manifestName]);
      expect(made.files['s9_sandbox_cases.g.dart'], isNot(contains('s9_ep02')));
    });

    test('a case given without the one before it is refused: it could never be unlocked', () {
      expect(() => make([case02Path]), failsWith([
        'FAILED  $case02Path',
        '  error    [case_missing] s9_ep01 comes before s9_ep02 in s9_sandbox and is not given: s9_ep02 could never be unlocked',
      ]));
    });

    test('a case given twice is refused', () {
      expect(() => make([casePath, casePath]), failsWith(contains(contains('[case_given_twice] s9_ep01'))));
    });

    test('a case plan away from its own folder is refused', () {
      final away = '$dir/cases/s9_ep02/copy/case.plan.json';
      File(away).createSync(recursive: true);
      File(casePath).copySync(away);
      expect(() => make([away]), failsWith(contains(contains('[case_misplaced] not cases/s9_ep01/case.plan.json'))));
    });

    test('a case plan of another season is refused before anything else', () {
      edit(case02Path, (json) => json['seasonId'] = 's8_other');
      expect(make, failsWith(contains(contains('structure'))));
    });

    test('Case 02 lacking a word: every finding with its path, nothing made of Case 01 either', () {
      edit(case02Path, (json) => (((json['missions'] as List)[1] as Map)['play'] as Map).remove('hints'));
      expect(make, failsWith([
        'FAILED  $case02Path',
        r'  error    play [play_field_missing] $.missions[1].play.hints: missing',
      ]));
    });

    test("a clue of a case after its own is refused (the season's clue graph)", () {
      edit(casePath, (json) => ((json['missions'] as List)[0] as Map)['clueInputs'] = [
        {'ref': 's9_ep02_c1', 'use': 'textMention'},
      ]);
      expect(make, failsWith(contains(contains('clue_used_before_discovery'))));
    });

    test("a plan that breaks the plans' own rules is refused before anything else", () {
      edit(casePath, (json) => json['number'] = 2);
      expect(make, failsWith(contains(contains('structure'))));
    });
  });

  group('the files on disk', () {
    test('written, then checked: up to date, whatever the line endings', () {
      final made = make();
      GeneratedFiles.write(out, made.files);
      expect(GeneratedFiles.stale(out, made.files), isEmpty);
      for (final f in made.files.keys) {
        final file = File('$out/$f');
        file.writeAsStringSync(file.readAsStringSync().replaceAll('\n', '\r\n'));
      }
      expect(GeneratedFiles.stale(out, made.files), isEmpty, reason: 'CRLF reads as LF');
      expect(GeneratedFiles.write(out, made.files), isEmpty, reason: 'written again over its own files');
      edit(case02Path, (json) => (json['play'] as Map)['caseSummary'] = 'Another summary.');
      expect(GeneratedFiles.stale(out, make().files), ['s9_ep02.g.dart', manifestName]);
    });

    test('a generated file changed by hand, or one it did not make, is never written over (but with --force)', () {
      final made = make();
      GeneratedFiles.write(out, made.files);
      final file = File('$out/s9_ep01.g.dart');
      file.writeAsStringSync('${file.readAsStringSync()}// a hand-made line\n');
      expect(() => GeneratedFiles.write(out, made.files), failsWith([contains('[hand_edited]')]));
      expect(file.readAsStringSync(), endsWith('// a hand-made line\n'), reason: 'nothing written');
      file.writeAsStringSync('// written by a person\n');
      expect(() => GeneratedFiles.write(out, made.files), failsWith([contains('no GENERATED header')]));
      File('$out/notes.txt').writeAsStringSync('mine');
      expect(GeneratedFiles.write(out, made.files, force: true), [contains('notes.txt')]);
      expect(GeneratedFiles.stale(out, made.files), isEmpty);
      expect(File('$out/notes.txt').readAsStringSync(), 'mine', reason: 'never removed');
    });

    test('a file that cannot be written: none is replaced, nothing is left beside them', () {
      final before = make();
      GeneratedFiles.write(out, before.files);
      final was = {for (final f in before.files.keys) f: File('$out/$f').readAsStringSync()};
      edit(casePath, (json) => (json['play'] as Map)['caseSummary'] = 'Another summary.');
      edit(case02Path, (json) => (json['play'] as Map)['caseSummary'] = 'Another summary too.');
      final after = make();
      Directory('$out/s9_ep02.g.dart.part').createSync(); // in the way of Case 02's file
      expect(() => GeneratedFiles.write(out, after.files), failsWith([contains('[write_failed]')]));
      for (final MapEntry(:key, :value) in was.entries) {
        expect(File('$out/$key').readAsStringSync(), value, reason: '$key as it was: Case 01 is not made alone');
      }
      expect(File('$out/s9_ep01.g.dart.part').existsSync(), isFalse, reason: 'the files written beside are taken away');
      expect(GeneratedFiles.stale(out, before.files), isEmpty);
    });
  });

  test('Dart literals: text escaped, numbers and order as given', () {
    expect(DartLiteral.string(r"it's $5 \ a" '\n'), r"'it\'s \$5 \\ a\n'");
    expect(DartLiteral.of({'b': 1, 'a': 0.5, 'c': 2.0, 'd': <Object?>[]}), "{\n  'b': 1,\n  'a': 0.5,\n  'c': 2.0,\n  'd': [],\n}");
    expect(DartLiteral.of(const DartCall('X', named: {'k': DartCode('Y.z')})), 'X(\n  k: Y.z,\n)');
  });
}
