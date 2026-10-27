import '../../../models/investigation.dart' show InvestigationSpot;

/// [base]'s places, each with the line at its own index in [lines] (a
/// level's words for them, in the base's order). A place with no line of
/// its own keeps the base's; the places themselves never change.
List<InvestigationSpot> relined(List<InvestigationSpot> base, List<String> lines) => [
      for (final (i, s) in base.indexed) i < lines.length ? s.copyWith(line: lines[i]) : s,
    ];
