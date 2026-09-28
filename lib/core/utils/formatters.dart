abstract final class Formatters {
  /// 42:18 or 1:02:05
  static String clock(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  /// "42 min" — rounded, at least 1 minute.
  static String minutes(Duration d) {
    final m = (d.inSeconds / 60).round();
    return '${m < 1 ? 1 : m} min';
  }

  static String clueNumber(int index) => 'CLUE #${(index + 1).toString().padLeft(2, '0')}';
}
