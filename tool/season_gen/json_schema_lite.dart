import 'dart:convert';
import 'dart:io';

/// A JSON Schema (draft 2020-12) validator for the keywords the plans'
/// schemas use, and only those: a schema with any other keyword is refused
/// when loaded ([SchemaSet.load]), never half checked. The project has no
/// JSON Schema package, and these keywords are few.
///
/// Supported: `$schema`, `$id`, `$ref` (`#/$defs/x` and `other.schema.json`
/// `#/$defs/x` of the same set), `$defs`, `$comment`, `title`,
/// `description`, `type` (one or a list), `properties`, `required`,
/// `additionalProperties` (`false` or a schema), `items`, `minItems`,
/// `maxItems`, `uniqueItems`, `enum`, `const`, `pattern`, `minLength`,
/// `minimum`, `maximum`.
class SchemaSet {
  SchemaSet._(this._byFile);

  static const draft = 'https://json-schema.org/draft/2020-12/schema';

  static const supported = {
    r'$schema', r'$id', r'$ref', r'$defs', r'$comment', 'title', 'description', 'type', 'properties', 'required',
    'additionalProperties', 'items', 'minItems', 'maxItems', 'uniqueItems', 'enum', 'const', 'pattern', 'minLength',
    'minimum', 'maximum',
  };

  /// By file name (`case_plan.schema.json`).
  final Map<String, Map<String, Object?>> _byFile;

  /// The schemas of [dir] (every `*.schema.json`), each checked to use
  /// only [supported] keywords and to name [draft].
  factory SchemaSet.load(String dir) {
    final files = Directory(dir).listSync().whereType<File>().where((f) => f.path.endsWith('.schema.json')).toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    final byFile = <String, Map<String, Object?>>{};
    for (final f in files) {
      final name = f.uri.pathSegments.last;
      final json = jsonDecode(f.readAsStringSync());
      if (json is! Map<String, Object?>) throw FormatException('$name: not a schema object');
      if (json[r'$schema'] != draft) throw FormatException('$name: not a draft 2020-12 schema');
      _checkKeywords(json, name);
      byFile[name] = json;
    }
    final set = SchemaSet._(byFile);
    for (final MapEntry(key: name, value: schema) in byFile.entries) {
      set._checkRefs(schema, name);
    }
    return set;
  }

  Iterable<String> get files => _byFile.keys;

  /// The schema of [file] as loaded.
  Map<String, Object?> schemaOf(String file) => _byFile[file] ?? (throw ArgumentError.value(file, 'file', 'no such schema'));

  static void _checkKeywords(Map<String, Object?> schema, String at) {
    for (final MapEntry(:key, :value) in schema.entries) {
      if (!supported.contains(key)) throw FormatException('$at: keyword $key is not supported by this validator');
      switch (key) {
        case r'$defs' || 'properties':
          for (final e in (value as Map<String, Object?>).entries) {
            _checkKeywords(e.value as Map<String, Object?>, '$at/$key/${e.key}');
          }
        case 'items':
          _checkKeywords(value as Map<String, Object?>, '$at/items');
        case 'additionalProperties' when value is Map:
          _checkKeywords(value as Map<String, Object?>, '$at/additionalProperties');
        case 'additionalProperties' when value != false:
          throw FormatException('$at: additionalProperties is false or a schema');
        case 'pattern':
          RegExp(value as String);
      }
    }
  }

  void _checkRefs(Map<String, Object?> schema, String file) {
    if (schema[r'$ref'] case final String ref) _resolve(ref, file);
    for (final key in [r'$defs', 'properties']) {
      for (final s in (schema[key] as Map<String, Object?>? ?? const {}).values) {
        _checkRefs(s as Map<String, Object?>, file);
      }
    }
    if (schema['items'] case final Map<String, Object?> items) _checkRefs(items, file);
    if (schema['additionalProperties'] case final Map<String, Object?> extra) _checkRefs(extra, file);
  }

  /// The schema [ref] names from [file], and the file it is in.
  (Map<String, Object?>, String) _resolve(String ref, String file) {
    final hash = ref.indexOf('#');
    final target = hash == 0 ? file : (hash < 0 ? ref : ref.substring(0, hash));
    final pointer = hash < 0 ? '' : ref.substring(hash + 1);
    Object? node = _byFile[target] ?? (throw FormatException('$file: \$ref $ref names no schema of the set'));
    if (pointer.isNotEmpty) {
      for (final part in pointer.split('/').skip(1)) {
        node = node is Map ? node[part] : null;
        if (node == null) throw FormatException('$file: \$ref $ref names nothing');
      }
    }
    return (node as Map<String, Object?>, target);
  }

  /// Everything wrong with [instance] against schema [file] (empty: valid),
  /// each as `<path>: <why>`.
  List<String> validate(Object? instance, String file) {
    final out = <String>[];
    _validate(instance, schemaOf(file), file, r'$', out);
    return out;
  }

  void _validate(Object? v, Map<String, Object?> s, String file, String at, List<String> out) {
    if (s[r'$ref'] case final String ref) {
      final (target, inFile) = _resolve(ref, file);
      _validate(v, target, inFile, at, out);
    }
    if (s['type'] case final Object type) {
      final types = type is List ? type.cast<String>() : [type as String];
      if (!types.any((t) => _isType(v, t))) {
        out.add('$at: not ${types.join(' or ')}');
        return;
      }
    }
    if (s.containsKey('const') && !_equal(v, s['const'])) out.add('$at: not ${jsonEncode(s['const'])}');
    if (s['enum'] case final List<Object?> values when !values.any((e) => _equal(v, e))) {
      out.add('$at: ${jsonEncode(v)} is not one of ${values.map(jsonEncode).join(', ')}');
    }
    if (v is String) {
      if (s['minLength'] case final int min when v.runes.length < min) out.add('$at: shorter than $min');
      if (s['pattern'] case final String p when !RegExp(p).hasMatch(v)) out.add('$at: "$v" does not match $p');
    }
    if (v is num) {
      if (s['minimum'] case final num min when v < min) out.add('$at: $v is under $min');
      if (s['maximum'] case final num max when v > max) out.add('$at: $v is over $max');
    }
    if (v is List) {
      if (s['minItems'] case final int min when v.length < min) out.add('$at: ${v.length} items, at least $min');
      if (s['maxItems'] case final int max when v.length > max) out.add('$at: ${v.length} items, at most $max');
      if (s['uniqueItems'] == true) {
        for (var i = 0; i < v.length; i++) {
          for (var j = i + 1; j < v.length; j++) {
            if (_equal(v[i], v[j])) out.add('$at: items $i and $j are the same');
          }
        }
      }
      if (s['items'] case final Map<String, Object?> items) {
        for (final (i, x) in v.indexed) {
          _validate(x, items, file, '$at[$i]', out);
        }
      }
    }
    if (v is Map) {
      final props = s['properties'] as Map<String, Object?>? ?? const {};
      for (final key in (s['required'] as List? ?? const []).cast<String>()) {
        if (!v.containsKey(key)) out.add('$at.$key: missing');
      }
      for (final MapEntry(:key, :value) in v.entries) {
        if (props[key] case final Map<String, Object?> p) {
          _validate(value, p, file, '$at.$key', out);
        } else if (s['additionalProperties'] == false) {
          out.add('$at.$key: not a field of this plan');
        } else if (s['additionalProperties'] case final Map<String, Object?> extra) {
          _validate(value, extra, file, '$at.$key', out);
        }
      }
    }
  }

  static bool _isType(Object? v, String type) => switch (type) {
        'object' => v is Map,
        'array' => v is List,
        'string' => v is String,
        // JSON has no integer type of its own: 2.0 is an integer, as the draft says.
        'integer' => v is int || (v is double && v == v.truncateToDouble()),
        'number' => v is num,
        'boolean' => v is bool,
        'null' => v == null,
        _ => throw FormatException('unknown type $type'),
      };

  /// JSON equality (1 and 1.0 are one number).
  static bool _equal(Object? a, Object? b) => switch ((a, b)) {
        (final num x, final num y) => x == y,
        (final List<Object?> x, final List<Object?> y) => x.length == y.length && [for (var i = 0; i < x.length; i++) i].every((i) => _equal(x[i], y[i])),
        (final Map<Object?, Object?> x, final Map<Object?, Object?> y) =>
          x.length == y.length && x.keys.every((k) => y.containsKey(k) && _equal(x[k], y[k])),
        _ => a == b,
      };
}
