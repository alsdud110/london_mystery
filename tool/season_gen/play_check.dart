import 'dart:io';

import 'palette_facts.dart';
import 'plan_ids.dart';
import 'plan_models.dart';

/// One thing a plan lacks to be made into the game's content: which kind
/// ([code]), where ([path], as `$.missions[1].play.hints`) and why.
class PlayIssue {
  const PlayIssue(this.code, this.path, this.message, {this.inSeason = false});

  final String code;
  final String path;
  final String message;

  /// In the season plan (its places), not the case plan.
  final bool inSeason;

  @override
  String toString() => '[$code] ${inSeason ? 'season ' : ''}$path: $message';
}

/// What the Dart generator (`generate_case.dart`) needs of a case plan and
/// its season plan before it writes anything (STEP 3-8): the words the game
/// shows (`play`), a picture for every place, and a puzzle it can make.
///
/// Never the game's own content rules again: whether a hint gives the
/// answer away, links and answers are judged right is
/// `SeasonContentValidator`'s, run on the generated content by the tests.
/// Here only what the generator turns into game data, and the one rule the
/// plans keep looser than the game ([minChoiceOptions]).
///
/// A plan with no `play` still keeps its format and structure: this check
/// runs only when a case is to be generated (or `validate_plan --playable`).
abstract final class PlayCheck {
  /// A choice of fewer is "a guess, not a choice" to the game's validator
  /// (`season_content_validator.dart`); the plans accept two while planned
  /// (`PuzzleSelectionCheck`). `play_check_test` keeps the two numbers equal.
  static const minChoiceOptions = 3;

  /// `AppConstants.maxHints`.
  static const maxHints = 2;

  /// The puzzles the generator makes now: the palette's text-only puzzles of
  /// the sandbox cases, played by the mission page's own question widgets
  /// or the final page's dials (no table, no picture).
  static const generatable = {'text_choice', 'order_sequence', 'word_entry', 'letter_tile_lock', 'combo_dial_lock'};

  static const _choiceTypes = {'multipleChoice', 'imageChoice', 'canvasChoice'};

  /// The types `AnswerChecker` reads `Mission.orderFeedback` for.
  static const _orderTypes = {'sequence', 'letterLock', 'wordInput', 'numberCode', 'finalCode', 'examine'};

  static final _glossaryWord = RegExp(r"^[a-z][a-z'-]*$");

  /// Everything [plan] and [season] lack to be generated. [root]: the
  /// repository's root, the places' files are read from.
  static List<PlayIssue> casePlan(CasePlan plan, SeasonPlan season, {String root = '.'}) {
    final out = <PlayIssue>[];
    void issue(String code, String path, String message) => out.add(PlayIssue(code, path, message));
    void missing(String path) => issue('play_field_missing', path, 'missing');

    final places = <String, PlacePlan>{};
    for (final (i, p) in season.places.indexed) {
      final at = '\$.places[$i]';
      if (PlanIds.seasonOfScoped(p.placeId) != season.seasonId) {
        out.add(PlayIssue('place_invalid', '$at.placeId', '${p.placeId} is not a place of ${season.seasonId}', inSeason: true));
      }
      if (places.containsKey(p.placeId)) {
        out.add(PlayIssue('place_invalid', '$at.placeId', '${p.placeId} given twice', inSeason: true));
      }
      places[p.placeId] = p;
      if (!File('$root/${p.file}').existsSync()) {
        out.add(PlayIssue('place_file_missing', '$at.file', '${p.file} is not on disk', inSeason: true));
      }
    }

    final c = plan.play;
    if (c == null) {
      issue('play_missing', r'$.play', "the case's words (intro, caseSummary) are not written");
    } else {
      if (c.intro.isEmpty) missing(r'$.play.intro');
      if (c.caseSummary == null) missing(r'$.play.caseSummary');
      for (final word in c.glossary.keys) {
        if (!_glossaryWord.hasMatch(word)) issue('play_range', '\$.play.glossary.$word', 'not one word in lower case');
      }
    }

    final all = plan.allMissions;
    for (final (i, m) in all.indexed) {
      final at = m.isFinal ? r'$.final' : '\$.missions[$i]';
      final p = m.puzzle;
      final type = p.missionType;
      if (!generatable.contains(p.paletteId) || p.engineTable != null || p.status != PuzzleStatus.ready) {
        issue('generate_unsupported', '$at.puzzle.paletteId',
            '${p.paletteId ?? 'no palette puzzle'} (${p.status.name}${p.engineTable == null ? '' : ', table ${p.engineTable}'}): the generator makes ${generatable.join(', ')} only');
      }
      if (_choiceTypes.contains(type) && p.answerSpec.options.length < minChoiceOptions) {
        issue('play_choice_few', '$at.puzzle.answerSpec.options',
            '${p.answerSpec.options.length} options: the game asks for at least $minChoiceOptions (a guess, not a choice)');
      }
      if (!places.containsKey(m.placeId)) {
        issue('place_unregistered', '$at.placeId', '${m.placeId} has no picture in the season plan (places)');
      }

      final w = m.play;
      if (w == null) {
        issue('play_missing', '$at.play', "the mission's words are not written");
        continue;
      }
      final pa = '$at.play';
      for (final (key, value) in [
        ('title', w.title),
        ('location', w.location),
        ('letterIntro', w.letterIntro),
        ('letter', w.letter),
        ('question', w.question),
        ('successMessage', w.successMessage),
      ]) {
        if (value == null) missing('$pa.$key');
      }
      if (w.story.isEmpty) missing('$pa.story');
      if (w.hints.isEmpty) {
        missing('$pa.hints');
      } else if (w.hints.length > maxHints) {
        issue('play_range', '$pa.hints', '${w.hints.length} hints (1 to $maxHints)');
      }
      if (m.isFinal && w.transition.isEmpty) missing('$pa.transition');
      if (w.mapX == null) missing('$pa.mapX');
      if (w.mapY == null) missing('$pa.mapY');
      if (w.evidence == null) missing('$pa.evidence');

      // The notebook clue: written for the clue the mission leaves, and only then.
      if (m.clueOutputs.clue != null && w.clue == null) missing('$pa.clue');
      if (m.clueOutputs.clue == null && w.clue != null) {
        issue('play_clue_mismatch', '$pa.clue', 'the mission leaves no clue (clueOutputs.clue)');
      }

      void symbol(String path, String? key) {
        if (key != null && !PaletteFacts.dialSymbols.contains(key)) {
          issue('play_symbol_unknown', path, '"$key" is not a GameSymbol (${PaletteFacts.dialSymbols.join(', ')})');
        }
      }

      symbol('$pa.clue.symbol', w.clue?.symbol);
      symbol('$pa.evidence.icon', w.evidence?.icon);
      for (final (j, s) in (w.evidence?.symbols ?? const <String>[]).indexed) {
        symbol('$pa.evidence.symbols[$j]', s);
      }

      if (_choiceTypes.contains(type) && w.feedback.isNotEmpty) {
        issue('play_range', '$pa.feedback', "a choice's wrong-answer lines are its options' (puzzle.answerSpec.options[].feedback)");
      }
      if (w.orderFeedback != null && !_orderTypes.contains(type)) {
        issue('play_range', '$pa.orderFeedback', 'a $type is never in the wrong order');
      }
      if (w.lockTitle != null && type != 'letterLock') {
        issue('play_range', '$pa.lockTitle', 'a $type has no letter lock to name');
      }

      // The notebook evidence a mission recalls: one, found before (the clue graph's).
      final recalls = [for (final c in m.clueInputs) if (c.use == ClueUse.recall) c];
      if (recalls.length > 1) {
        issue('play_recall', '$at.clueInputs', '${recalls.length} recall inputs: the game recalls one piece of evidence');
      } else if (recalls.length == 1 && !PlanIds.evidence.hasMatch(recalls.single.ref)) {
        issue('play_recall', '$at.clueInputs', 'recalls ${recalls.single.ref}: the game recalls evidence (an _e id)');
      } else if (recalls.isEmpty && w.recall != null) {
        issue('play_recall', '$pa.recall', 'the mission has no recall input');
      }

      final links = [for (final c in m.clueInputs) if (c.use == ClueUse.evidenceLink) c];
      if (links.length > 1) {
        issue('play_link', '$at.clueInputs', '${links.length} evidence links: its evidence is matched to one');
      } else if (links.length == 1) {
        if (!PlanIds.evidence.hasMatch(links.single.ref)) issue('play_link', '$at.clueInputs', 'links ${links.single.ref}: evidence is matched to evidence');
        if (w.evidenceLinkLine == null) missing('$pa.evidenceLinkLine');
      } else if (w.evidenceLinkLine != null) {
        issue('play_link', '$pa.evidenceLinkLine', 'the mission has no evidenceLink input');
      }
    }
    return out;
  }
}
