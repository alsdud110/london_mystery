import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../features/game/game_controller.dart';
import '../features/game/game_providers.dart';

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
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('WORD CARD', style: AppText.eyebrow()),
            const SizedBox(height: 10),
            Text(word, style: AppText.title(size: 34)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.royalBlueSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('= $meaning', style: AppText.subtitle(color: AppColors.royalBlue)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text('GOT IT!', style: AppText.button(size: 17)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
