/// Dart source for constant data, written the same way every time: the same
/// value is always the same text (two-space indents, a trailing comma after
/// every item, single-quoted strings, LF only). What `generate_case.dart`
/// writes its content with.
///
/// Values: `null`, `bool`, `int`, `double` (always with a point: `1.0`),
/// `String`, `List`, `Map` with `String` keys (in their own order), and
/// [DartCall] / [DartCode] for the game's own types.
library;

/// A constructor call: `Name(a: 1, b: 'x')`, its arguments in their order.
class DartCall {
  const DartCall(this.name, {this.positional = const [], this.named = const {}});

  final String name;
  final List<Object?> positional;
  final Map<String, Object?> named;
}

/// Source written as it is (an enum value: `LearningLevel.recall`).
class DartCode {
  const DartCode(this.source);

  final String source;
}

/// A value written as a constant inside data that is not (`const [...]` in
/// a call that cannot be const: a talk's lines).
class DartConst {
  const DartConst(this.value);

  final Object? value;
}

abstract final class DartLiteral {
  /// [s] as a single-quoted Dart string: `\`, `'`, `$` and control
  /// characters escaped.
  static String string(String s) {
    final b = StringBuffer("'");
    for (final r in s.runes) {
      b.write(switch (r) {
        0x5C => r'\\',
        0x27 => r"\'",
        0x24 => r'\$',
        0x0A => r'\n',
        0x0D => r'\r',
        0x09 => r'\t',
        < 0x20 => '\\u{${r.toRadixString(16)}}',
        _ => String.fromCharCode(r),
      });
    }
    b.write("'");
    return b.toString();
  }

  /// [value] as Dart source, its inner lines indented from [indent].
  static String of(Object? value, {String indent = ''}) {
    final inner = '$indent  ';
    return switch (value) {
      null => 'null',
      bool() => '$value',
      int() => '$value',
      double() when !value.isFinite => throw ArgumentError.value(value, 'value', 'not a finite number'),
      double() => value == value.truncateToDouble() && value.abs() < 1e15 ? '${value.toInt()}.0' : '$value',
      String() => string(value),
      DartCode() => value.source,
      DartConst(:final value) => 'const ${of(value, indent: indent)}',
      List() when value.isEmpty => '[]',
      List() => '[\n${[for (final v in value) '$inner${of(v, indent: inner)},\n'].join()}$indent]',
      Map() when value.isEmpty => '{}',
      Map() => '{\n${[
          for (final MapEntry(:key, value: v) in value.entries)
            '$inner${string(key is String ? key : throw ArgumentError.value(key, 'key', 'not text'))}: ${of(v, indent: inner)},\n',
        ].join()}$indent}',
      DartCall(:final name, :final positional, :final named) when positional.isEmpty && named.isEmpty => '$name()',
      DartCall(:final name, :final positional, :final named) => '$name(\n${[
          for (final v in positional) '$inner${of(v, indent: inner)},\n',
          for (final MapEntry(:key, value: v) in named.entries) '$inner$key: ${of(v, indent: inner)},\n',
        ].join()}$indent)',
      _ => throw ArgumentError.value(value, 'value', 'not data a constant can hold'),
    };
  }
}
