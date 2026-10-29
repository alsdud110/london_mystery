/// The order a season's pictures are made in: every picture after the ones
/// it is drawn from (its references), and otherwise in the manifest's own
/// order, so the same manifest always gives the same order.
class AssetSchedule {
  const AssetSchedule(this.order, this.levels, this.cycle);

  /// Every asset id, references first. Empty when there is a [cycle].
  final List<String> order;

  /// How deep each asset is: 0 drawn from nothing, else one more than its
  /// deepest reference.
  final Map<String, int> levels;

  /// A loop of references (`a → b → a`), or null.
  final List<String>? cycle;
}

abstract final class AssetScheduler {
  /// The schedule of [ids] (the manifest's order), each drawn from its
  /// [references] (ids of [ids]; others are ignored here, the manifest's
  /// check reports them).
  ///
  /// Kahn's algorithm, the next picture always the earliest in the manifest
  /// of those whose references are all scheduled.
  static AssetSchedule of(List<String> ids, Map<String, List<String>> references) {
    final index = {for (final (i, id) in ids.indexed) id: i};
    final refs = {for (final id in ids) id: <String>{for (final r in references[id] ?? const <String>[]) if (index.containsKey(r) && r != id) r}};
    final selfLoop = ids.where((id) => (references[id] ?? const []).contains(id)).firstOrNull;
    if (selfLoop != null) return AssetSchedule(const [], const {}, [selfLoop, selfLoop]);

    final waiting = {for (final id in ids) id: refs[id]!.length};
    final users = <String, List<String>>{};
    for (final id in ids) {
      for (final r in refs[id]!) {
        (users[r] ??= []).add(id);
      }
    }
    final ready = [for (final id in ids) if (waiting[id] == 0) id];
    final order = <String>[];
    final levels = <String, int>{};
    while (ready.isNotEmpty) {
      ready.sort((a, b) => index[a]!.compareTo(index[b]!));
      final next = ready.removeAt(0);
      order.add(next);
      levels[next] = refs[next]!.isEmpty ? 0 : refs[next]!.map((r) => levels[r]!).reduce((a, b) => a > b ? a : b) + 1;
      for (final u in users[next] ?? const <String>[]) {
        waiting[u] = waiting[u]! - 1;
        if (waiting[u] == 0) ready.add(u);
      }
    }
    if (order.length == ids.length) return AssetSchedule(order, levels, null);
    return AssetSchedule(const [], const {}, _cycle([for (final id in ids) if (!levels.containsKey(id)) id], refs));
  }

  /// A loop among [left] (every one of which waits on another of them).
  static List<String> _cycle(List<String> left, Map<String, Set<String>> refs) {
    final inLeft = left.toSet();
    final path = <String>[];
    var at = left.first;
    while (!path.contains(at)) {
      path.add(at);
      at = (refs[at]!.where(inLeft.contains).toList()..sort()).first;
    }
    return [...path.sublist(path.indexOf(at)), at];
  }
}
