import 'package:shared_preferences/shared_preferences.dart';

/// Device storage that lives in memory only: the same reads and writes as
/// [SharedPreferences], none of them ever reaching the device. A developer
/// test session (see `DevSessionHost`) plays on one, so whatever it saves —
/// detective, cases, seasons, coins, How to Play — is thrown away with it.
class MemoryPreferences implements SharedPreferences {
  MemoryPreferences([Map<String, Object> values = const {}]) : _values = {...values};

  final Map<String, Object> _values;

  @override
  Set<String> getKeys() => Set<String>.from(_values.keys);

  @override
  Object? get(String key) => _values[key];

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  int? getInt(String key) => _values[key] as int?;

  @override
  double? getDouble(String key) => _values[key] as double?;

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  bool containsKey(String key) => _values.containsKey(key);

  @override
  List<String>? getStringList(String key) => (_values[key] as List<Object?>?)?.cast<String>().toList();

  Future<bool> _set(String key, Object value) {
    _values[key] = value;
    return Future.value(true);
  }

  @override
  Future<bool> setBool(String key, bool value) => _set(key, value);

  @override
  Future<bool> setInt(String key, int value) => _set(key, value);

  @override
  Future<bool> setDouble(String key, double value) => _set(key, value);

  @override
  Future<bool> setString(String key, String value) => _set(key, value);

  @override
  Future<bool> setStringList(String key, List<String> value) => _set(key, List<String>.unmodifiable(value));

  @override
  Future<bool> remove(String key) {
    _values.remove(key);
    return Future.value(true);
  }

  @override
  Future<bool> clear() {
    _values.clear();
    return Future.value(true);
  }

  @override
  Future<bool> commit() async => true;

  @override
  Future<void> reload() async {}
}
