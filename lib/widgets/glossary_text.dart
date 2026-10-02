import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import '../features/game/game_controller.dart';
import '../features/game/game_providers.dart';
import 'game_button.dart';
import 'paper.dart';

/// English text where harder words (from the episode glossary) get a dotted
/// underline. Tapping one shows its meaning — the translation is never shown
/// up front, so children still read the English first.
class GlossaryText extends ConsumerStatefulWidget {
  const GlossaryText(this.text, {super.key, required this.style, this.textAlign = TextAlign.start});

  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  ConsumerState<GlossaryText> createState() => _GlossaryTextState();
}

class _GlossaryTextState extends ConsumerState<GlossaryText> {
  static final _tokens = RegExp(r"[A-Za-z']+|[^A-Za-z']+");
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

  void _show(String word, String meaning) {
    ref.read(gameControllerProvider.notifier).lookUpWord(word.replaceAll(RegExp(r"'s$"), ''));
    showWordMeaning(context, word, meaning);
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final episode = ref.watch(currentEpisodeProvider);
    final spans = <InlineSpan>[];
    for (final match in _tokens.allMatches(widget.text)) {
      final token = match.group(0)!;
      final meaning = episode.meaningOf(token);
      if (meaning == null) {
        spans.add(TextSpan(text: token));
        continue;
      }
      final recognizer = TapGestureRecognizer()..onTap = () => _show(token, meaning);
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: token,
        recognizer: recognizer,
        semanticsLabel: '$token (tap for meaning)',
        style: TextStyle(
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dotted,
          decorationColor: AppColors.royalBlue,
          decorationThickness: 2.2,
        ),
      ));
    }
    return Text.rich(TextSpan(children: spans), style: widget.style, textAlign: widget.textAlign);
  }
}

/// A small, friendly word card: "Queen = 여왕".
Future<void> showWordMeaning(BuildContext context, String word, String meaning) {
  return showModalBottomSheet<void>(
    context: context,
    // A small reference card from the casebook (this sheet only; the others
    // keep the app's sheet theme): nearly square corners, and a thin
    // ink-brown tab in place of the grey handle (it still drags to close).
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.paper))),
    showDragHandle: false,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The tab, in the handle's own 48 dp slot (the card keeps its height).
            Container(
              width: 32,
              height: 3,
              margin: const EdgeInsets.only(top: 22, bottom: 23),
              decoration: BoxDecoration(
                color: AppColors.inkBrown.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('WORD CARD', style: AppText.eyebrow()),
            const SizedBox(height: 10),
            // A dictionary entry: the word, a rule, its meaning.
            Text(word, style: AppText.title(size: 34)),
            const SizedBox(height: AppSpace.sm),
            const OrnamentRule(),
            const SizedBox(height: AppSpace.sm),
            Text('= $meaning', style: AppText.title(size: 22, color: AppColors.royalBlue)),
            const SizedBox(height: 20),
            GameButton(label: 'GOT IT!', playTapSound: false, onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    ),
  );
}
