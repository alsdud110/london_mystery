import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/audio_service.dart';
import '../../../data/models/mission.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/landmark_art.dart';
import '../../game/game_providers.dart';

typedef AnswerCallback = void Function(String answer);

/// Shakes its child gently whenever [trigger] changes (used on "try again").
class ShakeOnChange extends StatefulWidget {
  const ShakeOnChange({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<ShakeOnChange> createState() => _ShakeOnChangeState();
}

class _ShakeOnChangeState extends State<ShakeOnChange> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  @override
  void didUpdateWidget(ShakeOnChange old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(math.sin(_c.value * math.pi * 6) * 10 * (1 - _c.value), 0),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// TYPE 1 — Multiple choice
// ---------------------------------------------------------------------------

class MultipleChoiceQuestion extends ConsumerStatefulWidget {
  const MultipleChoiceQuestion({super.key, required this.mission, required this.onSubmit});

  final Mission mission;
  final AnswerCallback onSubmit;

  @override
  ConsumerState<MultipleChoiceQuestion> createState() => _MultipleChoiceQuestionState();
}

class _MultipleChoiceQuestionState extends ConsumerState<MultipleChoiceQuestion> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final options = widget.mission.options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ChoiceTile(
              letter: String.fromCharCode(65 + i),
              label: options[i].label,
              selected: _selected == options[i].id,
              onTap: () {
                ref.read(audioServiceProvider).play(GameSound.tap);
                setState(() => _selected = options[i].id);
              },
            ),
          ),
        const SizedBox(height: 8),
        GameButton(
          label: 'CHECK ANSWER',
          icon: Icons.check_circle_rounded,
          onPressed: _selected == null ? null : () => widget.onSubmit(_selected!),
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.letter, required this.label, required this.selected, required this.onTap});

  final String letter;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$letter. $label',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.royalBlueSoft : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.royalBlue : AppColors.parchmentDark, width: selected ? 3 : 2),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.royalBlue : AppColors.paper,
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? AppColors.royalBlue : AppColors.parchmentDark, width: 2),
                ),
                child: Text(letter, style: AppText.button(size: 19, color: selected ? Colors.white : AppColors.navy)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: AppText.subtitle(color: AppColors.navy))),
              if (selected) const Icon(Icons.radio_button_checked_rounded, color: AppColors.royalBlue),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TYPE 2 — Word input
// ---------------------------------------------------------------------------

class WordInputQuestion extends StatefulWidget {
  const WordInputQuestion({super.key, required this.mission, required this.onSubmit});

  final Mission mission;
  final AnswerCallback onSubmit;

  @override
  State<WordInputQuestion> createState() => _WordInputQuestionState();
}

class _WordInputQuestionState extends State<WordInputQuestion> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    widget.onSubmit(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final prompt = widget.mission.prompt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (prompt != null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(18),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                prompt.replaceAll(RegExp(r'_+'), _controller.text.trim().isEmpty ? '______' : _controller.text.trim().toUpperCase()),
                style: AppText.style(AppText.display, size: 28, weight: FontWeight.w800, color: AppColors.goldLight, letterSpacing: 2),
              ),
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          maxLength: 20,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
            LengthLimitingTextInputFormatter(20),
          ],
          style: AppText.title(size: 28, color: AppColors.navy).copyWith(letterSpacing: 4),
          decoration: InputDecoration(
            hintText: 'Type the word',
            hintStyle: AppText.bodyText(size: 18, color: AppColors.muted),
            counterText: '',
            prefixIcon: const Icon(Icons.edit_rounded, color: AppColors.royalBlue),
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        GameButton(
          label: 'CHECK ANSWER',
          icon: Icons.check_circle_rounded,
          onPressed: _controller.text.trim().isEmpty ? null : _submit,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// TYPE 3 — Number code (big keypad, kid-sized)
// ---------------------------------------------------------------------------

class NumberCodeQuestion extends ConsumerStatefulWidget {
  const NumberCodeQuestion({super.key, required this.mission, required this.onSubmit});

  final Mission mission;
  final AnswerCallback onSubmit;

  @override
  ConsumerState<NumberCodeQuestion> createState() => _NumberCodeQuestionState();
}

class _NumberCodeQuestionState extends ConsumerState<NumberCodeQuestion> {
  String _code = '';

  int get _length => widget.mission.codeLength ?? widget.mission.answer.length;

  void _press(String digit) {
    if (_code.length >= _length) return;
    ref.read(audioServiceProvider).play(GameSound.tap);
    setState(() => _code += digit);
  }

  void _delete() {
    if (_code.isEmpty) return;
    setState(() => _code = _code.substring(0, _code.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 64,
                height: 78,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i < _code.length ? AppColors.navy : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: i == _code.length ? AppColors.gold : AppColors.parchmentDark,
                    width: i == _code.length ? 3 : 2,
                  ),
                ),
                child: Text(
                  i < _code.length ? _code[i] : '_',
                  style: AppText.title(size: 36, color: i < _code.length ? AppColors.goldLight : AppColors.parchmentDark),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 330),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: [
              for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9']) _Key(label: d, onTap: () => _press(d)),
              _Key(icon: Icons.backspace_rounded, onTap: _delete, subtle: true, semantic: 'Delete'),
              _Key(label: '0', onTap: () => _press('0')),
              _Key(icon: Icons.clear_rounded, onTap: () => setState(() => _code = ''), subtle: true, semantic: 'Clear'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GameButton(
          label: 'UNLOCK',
          icon: Icons.lock_open_rounded,
          onPressed: _code.length == _length
              ? () {
                  widget.onSubmit(_code);
                  setState(() => _code = '');
                }
              : null,
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({this.label, this.icon, required this.onTap, this.subtle = false, this.semantic});

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool subtle;
  final String? semantic;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: subtle ? AppColors.parchment : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.parchmentDark, width: 2),
          ),
          child: label != null
              ? Text(label!, style: AppText.title(size: 28, color: AppColors.navy))
              : Icon(icon, color: AppColors.inkBrown, semanticLabel: semantic),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TYPE 4 — Image choice (names are hidden: kids must match the description)
// ---------------------------------------------------------------------------

class ImageChoiceQuestion extends ConsumerStatefulWidget {
  const ImageChoiceQuestion({super.key, required this.mission, required this.onSubmit});

  final Mission mission;
  final AnswerCallback onSubmit;

  @override
  ConsumerState<ImageChoiceQuestion> createState() => _ImageChoiceQuestionState();
}

class _ImageChoiceQuestionState extends ConsumerState<ImageChoiceQuestion> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final options = widget.mission.options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
          children: [
            for (var i = 0; i < options.length; i++)
              _ImageTile(
                letter: String.fromCharCode(65 + i),
                artwork: options[i].artwork ?? Artwork.bigBen,
                selected: _selected == options[i].id,
                onTap: () {
                  ref.read(audioServiceProvider).play(GameSound.tap);
                  setState(() => _selected = options[i].id);
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        GameButton(
          label: 'CHECK ANSWER',
          icon: Icons.check_circle_rounded,
          onPressed: _selected == null ? null : () => widget.onSubmit(_selected!),
        ),
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.letter, required this.artwork, required this.selected, required this.onTap});

  final String letter;
  final Artwork artwork;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Picture $letter',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.0 : 0.97,
          duration: const Duration(milliseconds: 180),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: selected ? AppColors.royalBlue : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: selected ? AppColors.royalBlue : AppColors.parchmentDark, width: 2),
              boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Stack(
              children: [
                Positioned.fill(child: LandmarkArt(artwork, borderRadius: 18)),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.royalBlue : AppColors.navy,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(letter, style: AppText.button(size: 17, color: Colors.white)),
                  ),
                ),
                if (selected)
                  const Positioned(
                    right: 8,
                    top: 8,
                    child: Icon(Icons.check_circle_rounded, color: AppColors.royalBlue, size: 32),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
