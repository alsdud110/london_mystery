/// The id formats of the season content pipeline's plans (STEP 3-2), as the
/// game names its content (`s2_paris`, `s2_ep10`, `s2_ep10_m1`,
/// `s2_ep10_c1`, `s2_ep10_e1`, `ScenePlaceIds`' `s3_tokyo.station`).
///
/// The JSON Schemas (`schema/common.schema.json`) carry the same patterns,
/// word for word: `season_gen_schema_test` keeps them in step.
abstract final class PlanIds {
  /// `s<N>_<city>`: `s2_paris`, `s3_tokyo`.
  static final season = RegExp(r'^s([1-9][0-9]*)_[a-z][a-z0-9]*$');

  /// `s<N>_ep<NN>`: `s3_ep03`.
  static final caseId = RegExp(r'^s([1-9][0-9]*)_ep([0-9]{2})$');

  /// `<case>_m<n>` or `<case>_final`: `s3_ep03_m2`, `s3_ep03_final`.
  static final mission = RegExp(r'^s[1-9][0-9]*_ep[0-9]{2}_(m[1-9]|final)$');

  /// A mission's place in its case: `m1`…`m9`, or `final`.
  static final slot = RegExp(r'^(m[1-9]|final)$');

  /// `<case>_c<n>`: a clue for the notebook.
  static final clue = RegExp(r'^s[1-9][0-9]*_ep[0-9]{2}_c[1-9][0-9]*$');

  /// `<case>_e<n>`: a piece of evidence.
  static final evidence = RegExp(r'^s[1-9][0-9]*_ep[0-9]{2}_e[1-9][0-9]*$');

  /// `<case>_f<n>`: a story fact (plans only; never in the game).
  static final fact = RegExp(r'^s[1-9][0-9]*_ep[0-9]{2}_f[1-9][0-9]*$');

  /// What a clue input names: a clue, evidence or fact id.
  static final clueRef = RegExp(r'^s[1-9][0-9]*_ep[0-9]{2}_[cef][1-9][0-9]*$');

  /// `<seasonId>.<name>`: a season place (`ScenePlaceIds`).
  static final place = RegExp(r'^s[1-9][0-9]*_[a-z][a-z0-9]*\.[a-z][a-z0-9_]*$');

  /// `<seasonId>.asset.<name>`: a picture a puzzle needs (plans only).
  static final asset = RegExp(r'^s[1-9][0-9]*_[a-z][a-z0-9]*\.asset\.[a-z][a-z0-9_]*$');

  /// A place's picture, from the repository's root: a bundled image under
  /// `assets/` (no `..`, no other folder).
  static final assetFile = RegExp(r'^assets/([A-Za-z0-9_-]+/)*[A-Za-z0-9_-]+\.(png|jpg|jpeg|webp)$');

  /// A character's or location's own id in its season plan: `emile`.
  static final local = RegExp(r'^[a-z][a-z0-9_]*$');

  /// `act1`, `act2`, `act3`.
  static final act = RegExp(r'^act[1-3]$');

  /// A map landmark's key, as its `MapLandmark` enum value is named
  /// (`arcDeTriomphe`).
  static final landmark = RegExp(r'^[a-z][A-Za-z0-9]*$');

  /// A `PuzzlePalette` puzzle id (snake_case).
  static final palette = RegExp(r'^[a-z][a-z0-9_]*$');

  /// A `SeasonContent.missionTables` table name (`drumTapes`).
  static final table = RegExp(r'^[a-z][A-Za-z0-9]*$');

  /// Season number in a season id, or null.
  static int? seasonNumber(String seasonId) {
    final m = season.firstMatch(seasonId);
    return m == null ? null : int.parse(m.group(1)!);
  }

  /// (season number, case number) of a case id, or null.
  static (int, int)? caseNumbers(String id) {
    final m = caseId.firstMatch(id);
    return m == null ? null : (int.parse(m.group(1)!), int.parse(m.group(2)!));
  }

  /// The case id `s<N>_ep<NN>` of season [seasonNumber], case [number].
  static String caseOf(int seasonNumber, int number) => 's${seasonNumber}_ep${number.toString().padLeft(2, '0')}';

  /// The case id an id of the case's own (mission, clue, evidence, fact) starts with.
  static String? caseOfChild(String id) {
    final m = RegExp(r'^(s[1-9][0-9]*_ep[0-9]{2})_').firstMatch(id);
    return m?.group(1);
  }

  /// The season id a season place or asset id starts with.
  static String? seasonOfScoped(String id) {
    final dot = id.indexOf('.');
    return dot <= 0 ? null : id.substring(0, dot);
  }
}
