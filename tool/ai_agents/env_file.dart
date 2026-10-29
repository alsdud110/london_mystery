import 'dart:io';

/// A `.env` file read, never written: `KEY=VALUE` lines, `#` comments, blank
/// lines, an optional `export `, and values in single or double quotes.
abstract final class EnvFile {
  /// The entries of [path]; empty when there is no such file.
  static Map<String, String> read(String path) {
    final file = File(path);
    if (!file.existsSync()) return const {};
    return parse(file.readAsStringSync());
  }

  /// The entries of [text].
  static Map<String, String> parse(String text) {
    final out = <String, String>{};
    for (var line in text.split(RegExp(r'\r?\n'))) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      if (line.startsWith('export ')) line = line.substring(7).trimLeft();
      final eq = line.indexOf('=');
      if (eq <= 0) continue;
      final key = line.substring(0, eq).trim();
      var value = line.substring(eq + 1).trim();
      if (value.length >= 2 && (value[0] == '"' || value[0] == "'") && value.endsWith(value[0])) {
        value = value.substring(1, value.length - 1);
      } else {
        final hash = value.indexOf(' #');
        if (hash >= 0) value = value.substring(0, hash).trimRight();
      }
      out[key] = value;
    }
    return out;
  }
}

/// The OpenAI API key: the environment's `OPENAI_API_KEY`, else [envPath]'s.
/// Never printed, logged or written anywhere: [redact] takes it (and any
/// key-like text) out of whatever is shown.
class ApiKey {
  ApiKey._(this._value);

  final String _value;

  /// The key, for the request's header only.
  String get bearer => _value;

  /// The key, or null when neither the environment nor [envPath] has one.
  static ApiKey? find({String envPath = '.env', Map<String, String>? environment}) {
    final env = environment ?? Platform.environment;
    final value = (env['OPENAI_API_KEY'] ?? EnvFile.read(envPath)['OPENAI_API_KEY'] ?? '').trim();
    return value.isEmpty ? null : ApiKey._(value);
  }

  static final _keyLike = RegExp(r'sk-[A-Za-z0-9_\-*]{4,}');

  /// [text] with the key, and anything shaped like a key (an API error can
  /// quote part of one), replaced by `[redacted]`.
  String redact(String text) => redactKeys(text.replaceAll(_value, '[redacted]'));

  /// [text] with anything shaped like an OpenAI key replaced.
  static String redactKeys(String text) => text.replaceAll(_keyLike, '[redacted]');

  @override
  String toString() => 'ApiKey([redacted])';
}
