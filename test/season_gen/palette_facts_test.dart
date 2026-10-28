import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/content/puzzle_palette.dart';

import '../../tool/season_gen/palette_facts.dart';
import '../../tool/season_gen/plan_models.dart';

/// `tool/season_gen/palette_facts.dart` is the palette's and the dial
/// symbols' own facts, copied for plain `dart run`: written from them here
/// (with `PALETTE_FACTS_WRITE=1`) and checked against them on every run.
void main() {
  const path = 'tool/season_gen/palette_facts.dart';
  const begin = '  // BEGIN GENERATED (palette_facts_test)\n';
  const end = '  // END GENERATED\n';

  String surfaces(Set<PuzzleSurface> s) => '{${[for (final x in PuzzleSurface.values) if (s.contains(x)) 'PlanSurface.${x.name}'].join(', ')}}';
  String texts(Iterable<String> s) => s.map((x) => "'$x'").join(', ');
  String fields(Iterable<PuzzleField> f) => texts(f.map((x) => '$x'));

  String engine(PuzzleEngineBinding e) {
    final table = e.table == null ? 'null' : "'${e.table}'";
    final role = e.role == PuzzleBindingRole.primary ? '' : ', role: PaletteRole.${e.role.name}';
    final types = [for (final t in e.missionTypes) t.name];
    return "        PaletteEngine('${e.widget}', $table, {${texts(types)}}, ${surfaces(e.surfaces)}$role),\n";
  }

  String puzzle(PuzzleDefinition p) {
    final b = StringBuffer()
      ..write("    PalettePuzzle(\n      '${p.id}',\n      PaletteGrade.${p.reuseGrade.name},\n      PaletteMode.${p.generationMode.name},\n")
      ..write('      engines: [\n')
      ..writeAll(p.engines.map(engine))
      ..write('      ],\n')
      ..write('      requiredData: [${fields(p.requiredData)}],\n');
    if (p.requiredAssets.isNotEmpty) b.write('      requiredAssets: [${fields(p.requiredAssets.map((a) => a.field))}],\n');
    if (p.optionalAssets.isNotEmpty) b.write('      optionalAssets: [${fields(p.optionalAssets.map((a) => a.field))}],\n');
    b.write('    ),\n');
    return b.toString();
  }

  /// The keys of `GameSymbol._symbols`: the names a dial can show.
  List<String> dialSymbolNames() {
    final source = File('lib/widgets/symbol_icon.dart').readAsStringSync();
    final start = source.indexOf('static const _symbols = {');
    final stop = source.indexOf('\n  };', start);
    expect(start, isNonNegative, reason: 'GameSymbol._symbols not found');
    return [for (final m in RegExp(r"^\s*'(\w+)': GameSymbol\(", multiLine: true).allMatches(source.substring(start, stop))) m.group(1)!];
  }

  String generated() {
    final b = StringBuffer()
      ..write('  /// Every palette puzzle, in palette order.\n')
      ..write('  static const all = <PalettePuzzle>[\n')
      ..writeAll(PuzzlePalette.all.map(puzzle))
      ..write('  ];\n\n')
      ..write('  /// The names a dial can show (`GameSymbol`).\n')
      ..write('  static const dialSymbols = {${texts(dialSymbolNames())}};\n');
    return b.toString();
  }

  test('the copy is the palette and the dial symbols, as they are', () {
    final file = File(path);
    final source = file.readAsStringSync();
    final from = source.indexOf(begin);
    final to = source.indexOf(end);
    expect(from >= 0 && to > from, isTrue, reason: 'the markers of $path');
    final want = '${source.substring(0, from + begin.length)}${generated()}${source.substring(to)}';
    if (Platform.environment['PALETTE_FACTS_WRITE'] == '1') file.writeAsStringSync(want);
    expect(source, want, reason: 'write it again: PALETTE_FACTS_WRITE=1 flutter test test/season_gen/palette_facts_test.dart');
  });

  test('read back, it is the palette: ids, modes, surfaces, engines', () {
    expect(PaletteFacts.all.length, PuzzlePalette.all.length);
    expect(PaletteFacts.all.length, 28);
    for (final p in PuzzlePalette.all) {
      final f = PaletteFacts.lookup(p.id)!;
      expect(f.mode.name, p.generationMode.name, reason: p.id);
      expect(f.grade.name, p.reuseGrade.name, reason: p.id);
      for (final s in PuzzleSurface.values) {
        final plan = PlanSurface.values.byName(s.name);
        expect(f.supports(plan), p.supports(s), reason: '${p.id} ${s.name}');
        expect([for (final e in f.enginesFor(plan)) e.table], [for (final e in p.enginesFor(s)) e.table], reason: '${p.id} ${s.name}');
      }
    }
    expect(PaletteMode.values.map((m) => m.name), PuzzleGenerationMode.values.map((m) => m.name));
    expect(PaletteRole.values.map((m) => m.name), PuzzleBindingRole.values.map((m) => m.name));
    // The palette has no custom puzzle (see PuzzleReuseGrade.custom).
    expect(PaletteGrade.values.map((m) => m.name), [for (final g in PuzzleReuseGrade.values) if (g != PuzzleReuseGrade.custom) g.name]);
    expect(PaletteFacts.dialSymbols, containsAll(['clock', 'train', 'park', 'museum']));
  });
}
