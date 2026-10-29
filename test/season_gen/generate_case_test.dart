import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/season_gen/content_hash.dart';
import '../../tool/season_gen/dart_literal.dart';
import '../../tool/season_gen/generate_case.dart';

/// The Dart generator (STEP 3-8) on copies of the sandbox plans: the same
/// plans make the same bytes, nothing is written when a plan lacks a word,
/// a generated file changed by hand is never written over, and a Windows
/// checkout's CRLF reads as the LF it was written with. (The content it
/// makes is checked and played in `test/sandbox/s9_ep01_test.dart`.)
void main() {
  const seasonDir = 'content_pipeline/seasons/s9_sandbox';
  late Directory tmp;
  late String season, casePath, out;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('generate_case');
    final dir = '${tmp.path}/seasons/s9_sandbox';
    season = '$dir/season.plan.json';
    casePath = '$dir/cases/s9_ep01/case.plan.json';
    out = '${tmp.path}/generated';
    File(casePath).createSync(recursive: true);
    File('$seasonDir/season.plan.json').copySync(season);
    File('$seasonDir/cases/s9_ep01/case.plan.json').copySync(casePath);
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Generated make() => CaseGenerator.sandbox(seasonPath: season, casePaths: [casePath]);

  test('makes the season and case files and their manifest, from the plans alone, the same each time', () {
    final made = make();
    expect(made.files.keys, ['s9_sandbox_season.g.dart', 's9_ep01.g.dart', 'generated.manifest.json']);
    expect(make().files, made.files);
    for (final MapEntry(:key, :value) in made.files.entries) {
      if (key.endsWith('.dart')) expect(value, startsWith('$generatedHeader\n// source: '), reason: key);
      expect(value, isNot(contains('\r')), reason: '$key: LF only');
    }
    final manifest = jsonDecode(made.files[manifestName]!) as Map<String, Object?>;
    expect(manifest['inputs'], {
      'season.plan.json': ContentHash.ofJson(jsonDecode(File(season).readAsStringSync())),
      'cases/s9_ep01/case.plan.json': ContentHash.ofJson(jsonDecode(File(casePath).readAsStringSync())),
    });
    expect((manifest['outputs'] as Map)['s9_ep01.g.dart'], ContentHash.ofBytes(utf8.encode(made.files['s9_ep01.g.dart']!)));
    expect(made.files[manifestName], isNot(contains(RegExp(r'20\d\d-'))), reason: 'no time in it');
  });

  test('a plan lacking a word: every finding with its path, nothing made', () {
    final json = jsonDecode(File(casePath).readAsStringSync()) as Map<String, Object?>;
    (((json['missions'] as List)[1] as Map)['play'] as Map).remove('hints');
    File(casePath).writeAsStringSync(jsonEncode(json));
    expect(
      make,
      throwsA(isA<GenerateFailure>().having((e) => e.lines, 'lines', [
        'FAILED  $casePath',
        r'  error    play [play_field_missing] $.missions[1].play.hints: missing',
      ])),
    );
  });

  test("a plan that breaks the plans' own rules is refused before anything else", () {
    final json = jsonDecode(File(casePath).readAsStringSync()) as Map<String, Object?>;
    json['number'] = 2;
    File(casePath).writeAsStringSync(jsonEncode(json));
    expect(make, throwsA(isA<GenerateFailure>().having((e) => e.lines.join('\n'), 'lines', contains('structure'))));
  });

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
    final json = jsonDecode(File(casePath).readAsStringSync()) as Map<String, Object?>;
    (json['play'] as Map)['caseSummary'] = 'Another summary.';
    File(casePath).writeAsStringSync(jsonEncode(json));
    expect(GeneratedFiles.stale(out, make().files), ['s9_ep01.g.dart', manifestName]);
  });

  test('a generated file changed by hand, or one it did not make, is never written over (but with --force)', () {
    final made = make();
    GeneratedFiles.write(out, made.files);
    final file = File('$out/s9_ep01.g.dart');
    file.writeAsStringSync('${file.readAsStringSync()}// a hand-made line\n');
    expect(() => GeneratedFiles.write(out, made.files),
        throwsA(isA<GenerateFailure>().having((e) => e.lines.single, 'line', contains('[hand_edited]'))));
    expect(file.readAsStringSync(), endsWith('// a hand-made line\n'), reason: 'nothing written');
    file.writeAsStringSync('// written by a person\n');
    expect(() => GeneratedFiles.write(out, made.files),
        throwsA(isA<GenerateFailure>().having((e) => e.lines.single, 'line', contains('no GENERATED header'))));
    File('$out/notes.txt').writeAsStringSync('mine');
    expect(GeneratedFiles.write(out, made.files, force: true), [contains('notes.txt')]);
    expect(GeneratedFiles.stale(out, made.files), isEmpty);
    expect(File('$out/notes.txt').readAsStringSync(), 'mine', reason: 'never removed');
  });

  test('Dart literals: text escaped, numbers and order as given', () {
    expect(DartLiteral.string(r"it's $5 \ a" '\n'), r"'it\'s \$5 \\ a\n'");
    expect(DartLiteral.of({'b': 1, 'a': 0.5, 'c': 2.0, 'd': <Object?>[]}), "{\n  'b': 1,\n  'a': 0.5,\n  'c': 2.0,\n  'd': [],\n}");
    expect(DartLiteral.of(const DartCall('X', named: {'k': DartCode('Y.z')})), 'X(\n  k: Y.z,\n)');
  });
}
