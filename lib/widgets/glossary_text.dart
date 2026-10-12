import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import '../data/models/episode.dart';
import '../features/game/game_controller.dart';
import '../features/game/game_providers.dart';
import 'game_button.dart';
import 'paper.dart';

/// English text where harder words (from the episode glossary) get a dotted
/// underline. Tapping one shows its meaning — the translation is never shown
/// up front, so children still read the English first.
class GlossaryText extends ConsumerStatefulWidget {
  const GlossaryText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.start,
    this.episode,
    this.linkColor = AppColors.royalBlue,
    this.interactive = true,
    this.wordSemantics = true,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  /// The dotted underline's ink: royal blue on paper; a light ink on a dark
  /// surface (a chosen answer card, the final case's desk).
  final Color linkColor;

  /// False: plain text, no dotted words (e.g. an answer card not yet chosen,
  /// where a tap must always choose the card).
  final bool interactive;

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
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  void _show(String word, String meaning) => lookUpAndShowWord(context, ref, word, meaning);

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final Episode episode = widget.episode ?? ref.watch(currentEpisodeProvider);
    final spans = <InlineSpan>[];
    for (final match in _tokens.allMatches(widget.text)) {
      final token = match.group(0)!;
      final meaning = widget.interactive ? episode.meaningOf(token) : null;
      if (meaning == null) {
        spans.add(TextSpan(text: token));
        continue;
      }
      final recognizer = TapGestureRecognizer()..onTap = () => _show(token, meaning);
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: token,
        recognizer: recognizer,
        semanticsLabel: widget.wordSemantics ? '$token (tap for meaning)' : null,
        style: TextStyle(
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dotted,
          decorationColor: widget.linkColor,
          decorationThickness: 2.2,
        ),
      ));
    }
    return Text.rich(TextSpan(children: spans), style: widget.style, textAlign: widget.textAlign);
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

/// Records [word] for the parent report and shows its word card.
Future<void> lookUpAndShowWord(BuildContext context, WidgetRef ref, String word, String meaning) {
  ref.read(gameControllerProvider.notifier).lookUpWord(word.replaceAll(RegExp(r"'s$"), ''));
  return showWordMeaning(context, word, meaning);
}

/// A small, friendly word card: "Queen = 여왕".
Future<void> showWordMeaning(BuildContext context, String word, String meaning) {
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
