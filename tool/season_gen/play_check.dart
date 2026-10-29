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

  /// The puzzles the generator makes now, by palette id, and the table its
  /// scene is written into (null: played from its mission type). The text
  /// puzzles of STEP 3-8 (the mission page's own question widgets, the final
  /// page's dials), and since STEP 3-13 the puzzles played on pictures whose
  /// engines take a season's own files: a look round (`explore`), a search
  /// (`search`), a talk with witnesses (`dialogue`) and a picture choice
  /// (its options' `picture`).
  static const generatable = <String, String?>{
    'text_choice': null,
    'order_sequence': null,
    'word_entry': null,
    'letter_tile_lock': null,
    'combo_dial_lock': null,
    'picture_choice': null,
    'scene_explore_choose': 'explores',
    'dark_room_search': 'investigations',
    'witness_compare': 'dialogues',
  };

  /// The generatable puzzles that need pictures beyond the place's.
  static const pictured = {'picture_choice', 'scene_explore_choose', 'dark_room_search', 'witness_compare'};

  /// The `play` key a table's scene is written under.
  static const sceneKeys = {'explores': 'explore', 'investigations': 'search', 'dialogues': 'dialogue'};

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
      final id = p.paletteId;
      final made = id != null &&
          generatable.containsKey(id) &&
          p.engineTable == generatable[id] &&
          (pictured.contains(id) ? p.status != PuzzleStatus.devRequest : p.status == PuzzleStatus.ready);
      if (!made) {
        issue('generate_unsupported', '$at.puzzle.paletteId',
            '${id ?? 'no palette puzzle'} (${p.status.name}${p.engineTable == null ? '' : ', table ${p.engineTable}'}): the generator makes ${[for (final MapEntry(:key, :value) in generatable.entries) value == null ? key : '$key ($value)'].join(', ')} only');
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
      if (w.hideOptionNames != null && type != 'imageChoice') {
        issue('play_range', '$pa.hideOptionNames', 'a $type shows no pictures to name');
      }
      _pictures(m, at, root, out);

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

  /// The pictures [m] is played on beyond its place's (STEP 3-13): its
  /// scene, the one its engine table reads, and its picture options. Every
  /// file must be on disk at the size the plan gives it (a picture not made
  /// yet stops the generator: `asset_file_missing`, never a stand-in), and
  /// every place on a picture inside it, as its own pixels.
  static void _pictures(MissionPlan m, String at, String root, List<PlayIssue> out) {
    void issue(String code, String path, String message) => out.add(PlayIssue(code, path, message));
    final p = m.puzzle;
    final w = m.play!;
    final pa = '$at.play';
    final a = p.answerSpec;
    final optionIds = {for (final o in a.options) o.id};

    void file(String path, String f, {(int, int)? size}) {
      final disk = File('$root/$f');
      if (!disk.existsSync()) {
        issue('asset_file_missing', path, '$f is not on disk: a picture still to be made');
        return;
      }
      if (size == null) return;
      if (pngSize(disk) case (final width, final height) when (width, height) != size) {
        issue('asset_size_mismatch', path, '$f is ${width}x$height, not ${size.$1}x${size.$2}: places on it are measured on the file');
      }
    }

    void picture(String path, PicturePlan pic) => file('$path.file', pic.file, size: (pic.width, pic.height));

    bool inside(PicturePlan pic, double x, double y) => x >= 0 && y >= 0 && x <= pic.width && y <= pic.height;
    void point(String path, PicturePlan pic, ScenePoint pt) {
      if (!inside(pic, pt.x, pt.y)) issue('scene_area_invalid', path, '(${pt.x}, ${pt.y}) is off the ${pic.width}x${pic.height} picture');
    }

    void rect(String path, PicturePlan pic, SceneRect r) {
      if (!inside(pic, r.left, r.top) || !inside(pic, r.right, r.bottom) || r.left >= r.right || r.top >= r.bottom) {
        issue('scene_area_invalid', path, '[${r.left}, ${r.top}, ${r.right}, ${r.bottom}] is no rectangle on the ${pic.width}x${pic.height} picture');
      }
    }

    void rects(String path, PicturePlan pic, List<SceneRect> rs) {
      for (final (i, r) in rs.indexed) {
        rect('$path[$i]', pic, r);
      }
    }

    void unique(String path, Iterable<String> ids, String what) {
      final seen = <String>{};
      for (final id in ids) {
        if (!seen.add(id)) issue('scene_invalid', path, '$what "$id" given twice');
      }
    }

    // The scene its engine table reads, and no other.
    final table = p.engineTable;
    for (final MapEntry(key: t, value: _) in w.scenes.entries) {
      if (t != table) issue('play_scene_mismatch', '$pa.${sceneKeys[t]}', 'a scene for $t, but the puzzle is played ${table == null ? 'from its type' : 'on $table'}');
    }
    if (table != null && sceneKeys.containsKey(table) && !w.scenes.containsKey(table)) {
      issue('play_field_missing', '$pa.${sceneKeys[table]}', 'missing: the $table scene its engine is played on');
    }

    // A picture choice: a picture for each option, and words for it.
    for (final (i, o) in a.options.indexed) {
      final oa = '$at.puzzle.answerSpec.options[$i]';
      if (p.missionType == 'imageChoice') {
        if (o.picture case final f?) {
          file('$oa.picture', f);
        } else {
          issue('play_field_missing', '$oa.picture', 'missing: a picture choice shows a picture for each option');
        }
        if (o.altText == null) issue('play_field_missing', '$oa.altText', 'missing: what the picture shows, for screen readers');
      } else if (o.picture != null) {
        issue('play_range', '$oa.picture', 'a ${p.missionType} shows no picture for its options');
      }
    }

    if (w.explore case final s? when table == 'explores') {
      final sa = '$pa.explore';
      picture('$sa.picture', s.picture);
      point('$sa.guideAt', s.picture, s.guideAt);
      if (s.inside case final r?) rect('$sa.inside', s.picture, r);
      if (s.opening case final r?) rect('$sa.opening', s.picture, r);
      unique('$sa.spots', [for (final x in s.spots) x.id], 'spot');
      final ids = {for (final x in s.spots) x.id};
      for (final kind in ['document', 'choice']) {
        final n = s.spots.where((x) => x.kind == kind).length;
        if (n != 1) issue('scene_invalid', '$sa.spots', '$n spots of kind $kind: one holds the ${kind == 'document' ? 'letter' : 'choice'}');
      }
      for (final (i, x) in s.spots.indexed) {
        final xa = '$sa.spots[$i]';
        rects('$xa.areas', s.picture, x.areas);
        point('$xa.mark', s.picture, x.mark);
        if (x.kind == 'note' && x.line == null) issue('play_field_missing', '$xa.line', 'missing: a note says what is seen');
        if (x.requires case final need?) {
          if (!ids.contains(need) || need == x.id) issue('scene_invalid', '$xa.requires', '"$need" is no other spot of the scene');
          if (x.lockedLine == null) issue('play_field_missing', '$xa.lockedLine', 'missing: what it says before "$need" is looked at');
        }
      }
      for (final (i, o) in s.others.indexed) {
        rects('$sa.others[$i].areas', s.picture, o.areas);
      }
      unique('$sa.choices', [for (final c in s.choices) c.optionId], 'choice');
      final chosen = {for (final c in s.choices) c.optionId};
      if (!(chosen.length == optionIds.length && chosen.containsAll(optionIds))) {
        issue('scene_answer_mismatch', '$sa.choices', 'pictures for ${chosen.join(', ')}, but the options are ${optionIds.join(', ')}');
      }
      for (final (i, c) in s.choices.indexed) {
        file('$sa.choices[$i].picture', c.picture, size: s.choicePixels);
      }
    }

    if (w.search case final s? when table == 'investigations') {
      final sa = '$pa.search';
      picture('$sa.picture', s.picture);
      point('$sa.guideAt', s.picture, s.guideAt);
      if (s.inside case final r?) rect('$sa.inside', s.picture, r);
      if (s.opening case final r?) rect('$sa.opening', s.picture, r);
      unique('$sa.finds', [for (final f in s.finds) f.id], 'find');
      for (final (i, f) in s.finds.indexed) {
        final fa = '$sa.finds[$i]';
        rects('$fa.areas', s.picture, f.areas);
        point('$fa.at', s.picture, f.at);
        picture('$fa.picture', f.picture);
        // The search is read from the letter: each thing where its line says.
        if (w.letter != null && !w.letter!.contains(f.reportLine)) {
          issue('scene_text_mismatch', '$fa.reportLine', 'not a line of the letter, word for word: the search is read there');
        }
      }
      for (final (i, o) in s.spots.indexed) {
        rects('$sa.spots[$i].areas', s.picture, o.areas);
      }
    }

    if (w.dialogue case final s? when table == 'dialogues') {
      final sa = '$pa.dialogue';
      file('$sa.background', s.background);
      unique('$sa.questions', [for (final q in s.questions) q.id], 'question');
      unique('$sa.witnesses', [for (final x in s.witnesses) x.id], 'witness');
      final questions = {for (final q in s.questions) q.id};
      for (final (i, x) in s.witnesses.indexed) {
        final xa = '$sa.witnesses[$i]';
        file('$xa.portrait', x.portrait);
        final asked = x.answers.keys.toSet();
        if (!(asked.length == questions.length && asked.containsAll(questions))) {
          issue('scene_invalid', '$xa.answers', 'answers ${asked.join(', ')}: every witness answers every question (${questions.join(', ')})');
        }
      }
      final statements = s.statements;
      final d = s.deduction;
      final da = '$sa.deduction';
      if (!questions.contains(d.topic)) issue('scene_invalid', '$da.topic', '"${d.topic}" is no question of the talk');
      final pair = [for (final id in d.pair) statements[id]];
      for (final (i, id) in d.pair.indexed) {
        if (pair[i] == null) {
          issue('scene_answer_mismatch', '$da.pair[$i]', '"$id" is no statement (an answer with a thing, <witness>.<question>)');
        } else if (pair[i]!.$2 != d.topic) {
          issue('scene_answer_mismatch', '$da.pair[$i]', '"$id" is not about ${d.topic}');
        }
      }
      if (pair.every((x) => x != null)) {
        final [(w1, _, a1), (w2, _, a2)] = [for (final x in pair) x!];
        if (w1.id == w2.id) issue('scene_answer_mismatch', '$da.pair', 'two statements of one witness: two witnesses agree');
        if (a1.thing != a2.thing) issue('scene_answer_mismatch', '$da.pair', '"${a1.thing}" and "${a2.thing}": the two that answer it describe the same thing');
        // The pair is the one answer: no other two statements about the
        // topic describe the same thing (the game accepts the pair only).
        final about = [for (final MapEntry(:key, :value) in statements.entries) if (value.$2 == d.topic) (key, value.$3.thing)];
        for (final (i, (k1, t1)) in about.indexed) {
          for (final (k2, t2) in about.skip(i + 1)) {
            if (t1 == t2 && !{k1, k2}.containsAll(d.pair)) {
              issue('scene_ambiguous', '$da.pair', '$k1 and $k2 also describe "$t1" about ${d.topic}: one pair answers it');
            }
          }
        }
      }
      for (final (i, id) in d.then.indexed) {
        if (!statements.containsKey(id)) issue('scene_invalid', '$da.then[$i]', '"$id" is no statement');
      }
      if (d.then.isNotEmpty) {
        for (final k in TalkDeductionPlan.thenLines) {
          if (!d.lines.containsKey(k)) issue('play_field_missing', '$da.$k', 'missing: said while the statements still to find are asked for');
        }
      }
      if ((d.witnesses ?? 2) > s.witnesses.length) {
        issue('scene_invalid', '$da.witnesses', '${d.witnesses} witnesses to hear, of ${s.witnesses.length}');
      }
    }
  }

  /// Every picture file [m] shows beyond its place's, with where the plan
  /// names it (its JSON path from the mission, `.play.explore.picture.file`):
  /// its scene's pictures (the one its engine table reads) and its options'.
  static List<(String, String)> pictureFiles(MissionPlan m) {
    final w = m.play;
    return [
      for (final (i, o) in m.puzzle.answerSpec.options.indexed)
        if (o.picture case final f?) ('.puzzle.answerSpec.options[$i].picture', f),
      if (w?.explore case final s? when m.puzzle.engineTable == 'explores') ...[
        ('.play.explore.picture.file', s.picture.file),
        for (final (i, c) in s.choices.indexed) ('.play.explore.choices[$i].picture', c.picture),
      ],
      if (w?.search case final s? when m.puzzle.engineTable == 'investigations') ...[
        ('.play.search.picture.file', s.picture.file),
        for (final (i, f) in s.finds.indexed) ('.play.search.finds[$i].picture.file', f.picture.file),
      ],
      if (w?.dialogue case final s? when m.puzzle.engineTable == 'dialogues') ...[
        ('.play.dialogue.background', s.background),
        for (final (i, x) in s.witnesses.indexed) ('.play.dialogue.witnesses[$i].portrait', x.portrait),
      ],
    ];
  }

  /// A PNG file's width and height (its header), or null for another kind of file.
  static (int, int)? pngSize(File f) {
    final b = f.openSync();
    try {
      final head = b.readSync(24);
      const signature = [137, 80, 78, 71, 13, 10, 26, 10];
      if (head.length < 24 || [for (var i = 0; i < 8; i++) head[i]].join(',') != signature.join(',')) return null;
      int u32(int o) => (head[o] << 24) | (head[o + 1] << 16) | (head[o + 2] << 8) | head[o + 3];
      return (u32(16), u32(20));
    } finally {
      b.closeSync();
    }
  }
}
