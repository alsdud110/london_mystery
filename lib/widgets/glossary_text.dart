import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import '../data/models/detective_name.dart';
import '../data/models/episode.dart';
import '../features/game/game_controller.dart';
import '../features/game/game_providers.dart';
import 'game_button.dart';
import 'paper.dart';

/// English text where harder words (from the episode glossary) can be looked
/// up: they read like every other word (nothing marks them), and pressing
/// and holding one lights that word alone and opens its word card; closing
/// the card puts the word back as it was. A tap is never a look-up, so it
/// stays the screen's own (the next line, choosing a card). The translation
/// is never shown up front, so children still read the English first.
///
/// A line that speaks to the player ([DetectiveName.placeholder], e.g.
/// "Dear Detective {detectiveName},") is written with the detective's name
/// as saved now; the name is plain text, never a word to look up.
class GlossaryText extends ConsumerStatefulWidget {
  const GlossaryText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.start,
    this.episode,
    this.linkColor = AppColors.gold,
    this.interactive = true,
    this.wordSemantics = true,
    this.practice,
    this.shownWord,
    this.onHold,
  }) : spans = null;

  /// Text made of [spans]: each plain [TextSpan] (a text, no children) gets
  /// its harder words to look up, in its own style; any other span (a box
  /// number to circle, a picture) is kept as it is, with its own taps.
  const GlossaryText.spans(
    List<InlineSpan> this.spans, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.start,
    this.episode,
    this.linkColor = AppColors.gold,
    this.interactive = true,
    this.wordSemantics = true,
    this.practice,
    this.shownWord,
    this.onHold,
  }) : text = '';

  final String text;

  /// See [GlossaryText.spans].
  final List<InlineSpan>? spans;
  final TextStyle style;
  final TextAlign textAlign;

  /// The ink of a held word's wash: antique gold on paper; a light ink on a
  /// dark surface (a chosen answer card, the final case's desk).
  final Color linkColor;

  /// False: plain text, no words to look up (e.g. an answer card not yet
  /// chosen, where a touch must always choose the card).
  final bool interactive;

  /// Practice words in place of the case's glossary (How to Play): held the
  /// same way, on the same word card, but never recorded for the report.
  final Map<String, String>? practice;

  /// A word lit as if held, with no finger on it (How to Play showing how).
  final String? shownWord;

  /// A word was held, just before its card opens (How to Play stops
  /// showing how).
  final VoidCallback? onHold;

  /// False inside a control that speaks for itself (an answer card gives its
  /// words to screen readers as actions, see [glossaryWordsOf]).
  final bool wordSemantics;

  /// The case whose glossary explains the words (e.g. a piece of evidence
  /// from an earlier case, read in the Case Archive). Null: the open case.
  final Episode? episode;

  @override
  ConsumerState<GlossaryText> createState() => _GlossaryTextState();
}

class _GlossaryTextState extends ConsumerState<GlossaryText> {
  // A word keeps its inner apostrophe (King's, o'clock); quotes around it
  // ('Smells of …') are not part of it.
  static final _tokens = RegExp(r"[A-Za-z]+(?:'[A-Za-z]+)*|[^A-Za-z]+");

  /// One per word to look up, in reading order. Kept from build to build, so
  /// a rebuild while a finger is down (a line typing on, a fade) does not
  /// drop the hold.
  final List<LongPressGestureRecognizer> _holds = [];

  /// Words to look up laid out so far in this build.
  int _count = 0;

  /// The word held now (its place in [_holds]): lit until its card closes.
  int? _held;

  @override
  void dispose() {
    for (final r in _holds) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _hold(int index, String word, String meaning) async {
    if (_held != null || wordCardOpen) return;
    HapticFeedback.selectionClick();
    widget.onHold?.call();
    setState(() => _held = index);
    try {
      if (widget.practice != null) {
        await showWordMeaning(context, word, meaning);
      } else {
        await lookUpAndShowWord(context, ref, word, meaning);
      }
    } finally {
      if (mounted) setState(() => _held = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    _count = 0;
    final text = _build(context);
    // Words gone from the text since the last build.
    while (_holds.length > _count) {
      _holds.removeLast().dispose();
    }
    return text;
  }

  Widget _build(BuildContext context) {
    final Episode episode = widget.episode ?? ref.watch(currentEpisodeProvider);
    final name = ref.watch(gameControllerProvider.select((s) => s.detectiveName));
    final spans = <InlineSpan>[];
    if (widget.spans case final parts?) {
      for (final part in parts) {
        if (part is TextSpan && part.children == null && part.recognizer == null && part.text != null) {
          final words = <InlineSpan>[];
          _addWords(part.text!, episode, words);
          spans.add(TextSpan(style: part.style, children: words));
        } else {
          spans.add(part);
        }
      }
      return Text.rich(TextSpan(children: spans), style: widget.style, textAlign: widget.textAlign);
    }
    for (final (text, isName) in _pieces(widget.text, name)) {
      if (isName) {
        spans.add(TextSpan(text: text));
        continue;
      }
      _addWords(text, episode, spans);
    }
    return Text.rich(TextSpan(children: spans), style: widget.style, textAlign: widget.textAlign);
  }

  /// [text] as written for [name]: the words around it, and the name apart.
  static List<(String, bool)> _pieces(String text, String? name) {
    final n = DetectiveName.normalize(name ?? '');
    // Without a name the line reads as before ("Dear Detective,").
    if (n.isEmpty || !text.contains(DetectiveName.placeholder)) return [(DetectiveName.address(text, n), false)];
    // A name that is its own title ("Detective Lu") takes the title's place.
    const title = 'Detective ';
    final titled = DetectiveName.title(n) == n;
    final pieces = <(String, bool)>[];
    for (final part in DetectiveName.splitAtName(text)) {
      if (part != null) {
        pieces.add((part, false));
        continue;
      }
      if (titled && pieces.isNotEmpty && pieces.last.$1.endsWith(title)) {
        final before = pieces.removeLast().$1;
        pieces.add((before.substring(0, before.length - title.length), false));
      }
      pieces.add((n, true));
    }
    return pieces;
  }

  void _addWords(String text, Episode episode, List<InlineSpan> spans) {
    for (final match in _tokens.allMatches(text)) {
      final token = match.group(0)!;
      final meaning = !widget.interactive
          ? null
          : widget.practice != null
          ? widget.practice![token.toLowerCase()]
          : episode.meaningOf(token);
      if (meaning == null) {
        spans.add(TextSpan(text: token));
        continue;
      }
      final index = _count++;
      if (index == _holds.length) _holds.add(LongPressGestureRecognizer());
      final hold = _holds[index]..onLongPress = () => _hold(index, token, meaning);
      final lit = index == _held || token.toLowerCase() == widget.shownWord?.toLowerCase();
      spans.add(TextSpan(
        text: token,
        recognizer: hold,
        semanticsLabel: widget.wordSemantics ? '$token (hold for meaning)' : null,
        // Read like any other word; held, a soft wash of ink behind it.
        style: lit ? TextStyle(backgroundColor: widget.linkColor.withValues(alpha: 0.28)) : null,
      ));
    }
  }
}

/// The words of [text] that [episode]'s glossary explains, in reading order,
/// each once. For a surface that shows [text] inside one tappable control
/// (an answer card): it hands these to screen readers as actions, since the
/// words themselves are not separate targets there.
List<({String word, String meaning})> glossaryWordsOf(Episode episode, String text) {
  final seen = <String>{};
  return [
    for (final match in RegExp(r"[A-Za-z]+(?:'[A-Za-z]+)*").allMatches(text))
      if (episode.meaningOf(match.group(0)!) case final meaning?)
        if (seen.add(match.group(0)!.toLowerCase())) (word: match.group(0)!, meaning: meaning),
  ];
}

/// Records [word] for the parent report and shows its word card (neither,
/// while a word card is already open).
Future<void> lookUpAndShowWord(BuildContext context, WidgetRef ref, String word, String meaning) async {
  if (wordCardOpen) return;
  ref.read(gameControllerProvider.notifier).lookUpWord(word.replaceAll(RegExp(r"'s$"), ''));
  return showWordMeaning(context, word, meaning);
}

/// A word card is open (or opening): a second one waits for it to close.
/// (A card whose screen has gone, closed or not, no longer counts.)
bool get wordCardOpen => _cardOver?.mounted ?? false;

/// The navigator the open word card is shown on.
NavigatorState? _cardOver;

/// A small, friendly word card: "Queen = 여왕". One at a time: asked again
/// while one is open, it does nothing.
Future<void> showWordMeaning(BuildContext context, String word, String meaning) async {
  if (wordCardOpen) return;
  final over = Navigator.of(context);
  _cardOver = over;
  try {
    await _showWordCard(context, word, meaning);
  } finally {
    if (identical(_cardOver, over)) _cardOver = null;
  }
}

Future<void> _showWordCard(BuildContext context, String word, String meaning) {
  return showModalBottomSheet<void>(
    context: context,
    // A small reference card from the casebook (this sheet only; the others
    // keep the app's sheet theme): nearly square corners, and a thin
    // ink-brown tab in place of the grey handle (it still drags to close).
    shape: paperSheetShape,
    showDragHandle: false,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PaperSheetTab(),
            Text('WORD CARD', style: AppText.eyebrow()),
            const SizedBox(height: 10),
            // A dictionary entry: the word, a rule, its meaning.
            Text(word, style: AppText.title(size: 34)),
            const SizedBox(height: AppSpace.sm),
            const OrnamentRule(),
            const SizedBox(height: AppSpace.sm),
            Text('= $meaning', style: AppText.title(size: 22, color: AppColors.royalBlue)),
            const SizedBox(height: 20),
            GameButton(label: 'GOT IT!', onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    ),
  );
}
