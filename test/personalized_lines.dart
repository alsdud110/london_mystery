import 'dart:convert';

/// The season's lines that speak to the player by name (2026-10-17): the
/// detective's title in each became "Detective {detectiveName}", nothing
/// else. Each as (case, mission, field, before, after); [before] is the text
/// as it was, [after] as the data holds it now.
///
/// The tests that pin a case's content as it was (FNV of its JSON) read it
/// through [withoutNames], so they still prove that nothing else changed.
const personalizedLines = <(String, String, String, String, String)>[
  // Letters to the detective.
  ('ep01', 'm01', 'letter', 'Dear Detective,', 'Dear Detective {detectiveName},'),
  ('ep01', 'm05', 'letter', 'Detective, the thief hid', 'Detective {detectiveName}, the thief hid'),
  ('ep02', 'ep02_m1', 'letter', 'Detective,\n\nI looked', 'Detective {detectiveName},\n\nI looked'),
  ('ep02', 'ep02_m2', 'letter', 'Dear Detective,', 'Dear Detective {detectiveName},'),
  ('ep04', 'ep04_m3', 'letter', 'Detective,\n\nI sent', 'Detective {detectiveName},\n\nI sent'),
  ('ep04', 'ep04_final', 'letter', 'Dear Detective,', 'Dear Detective {detectiveName},'),
  // People who speak to the detective.
  ('ep06', 'ep06_final', 'transition', '"Blow it if you need help."', '"Blow it if you need help, Detective {detectiveName}."'),
  ('ep08', 'ep08_m1', 'successMessage', 'Good question, Detective!', 'Good question, Detective {detectiveName}!'),
  ('ep08', 'ep08_final', 'letter', 'You cannot prove it, Detective!', 'You cannot prove it, Detective {detectiveName}!'),
  ('ep11', 'ep11_final', 'story', 'Hello again, Detective,', 'Hello again, Detective {detectiveName},'),
];

String _inJson(String s) {
  final encoded = jsonEncode(s);
  return encoded.substring(1, encoded.length - 1);
}

/// [json] (a case's JSON, encoded) with the lines above as they were before.
String withoutNames(String json) {
  for (final (_, _, _, before, after) in personalizedLines) {
    json = json.replaceAll(_inJson(after), _inJson(before));
  }
  return json;
}
