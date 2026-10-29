/// How much a finding weighs.
///
/// * `error`: the season cannot be made as planned, or its data disagree.
///   Nothing is generated while there is one.
/// * `warning`: worth improving; generation goes on.
/// * `info`: for the record (a picture still to be made, a count).
enum Level { error, warning, info }

/// Where a finding comes from: the season_gen checks run again, the
/// planner's own checks, or a heuristic that only suggests a look (the
/// English checks count words; they never judge a level by themselves).
enum Source { plan, play, generator, season, bible, assets, puzzle, englishHeuristic, claudeReview }

/// One thing the season planner found: its weight, its kind ([code]), where
/// (a file and a JSON path, as `cases/s3_ep02 $.missions[1].play.hints`) and why.
class Finding {
  const Finding(this.level, this.code, this.where, this.message, {this.source = Source.season});

  final Level level;
  final String code;
  final String where;
  final String message;
  final Source source;

  bool get isError => level == Level.error;

  Map<String, Object?> toJson() => {'level': level.name.toUpperCase(), 'code': code, 'where': where, 'source': source.name, 'message': message};

  @override
  String toString() => '${level.name.toUpperCase().padRight(7)} [$code] $where: $message';
}

/// Collects findings, a check at a time.
class Findings {
  final all = <Finding>[];

  void error(String code, String where, String message, {Source source = Source.season}) =>
      all.add(Finding(Level.error, code, where, message, source: source));

  void warning(String code, String where, String message, {Source source = Source.season}) =>
      all.add(Finding(Level.warning, code, where, message, source: source));

  void info(String code, String where, String message, {Source source = Source.season}) =>
      all.add(Finding(Level.info, code, where, message, source: source));

  int count(Level level) => all.where((f) => f.level == level).length;
}
