import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart';
import '../../../data/models/mission.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/landmark_art.dart';
import '../../game/game_providers.dart';
import 'qr_question.dart';

/// Paper answer surface shared by the puzzle types: faint ink border,
/// navy when chosen.
BoxDecoration _answerPaper({bool selected = false, double radius = 8}) =>
    BoxDecoration(
      color: selected ? AppColors.royalBlueSoft : AppColors.paperLight,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: selected ? AppColors.navy : AppLine.faint(0.3),
        width: selected ? AppLine.ink : AppLine.rule,
      ),
    );

typedef AnswerCallback = void Function(String answer);

/// Shakes its child gently whenever [trigger] changes (used on "try again").
class ShakeOnChange extends StatefulWidget {
  const ShakeOnChange({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<ShakeOnChange> createState() => _ShakeOnChangeState();
}

class _ShakeOnChangeState extends State<ShakeOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

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
        offset: Offset(
          math.sin(_c.value * math.pi * 6) * 10 * (1 - _c.value),
          0,
        ),
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
  const MultipleChoiceQuestion({
    super.key,
    required this.mission,
    required this.onSubmit,
  });

  final Mission mission;
  final AnswerCallback onSubmit;

  @override
  ConsumerState<MultipleChoiceQuestion> createState() =>
      _MultipleChoiceQuestionState();
}

class _MultipleChoiceQuestionState
    extends ConsumerState<MultipleChoiceQuestion> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final options = widget.mission.options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
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
        const SizedBox(height: AppSpace.sm),
        GameButton(
          label: 'CHECK ANSWER',
          onPressed: _selected == null
              ? null
              : () => widget.onSubmit(_selected!),
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.letter,
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          decoration: _answerPaper(selected: selected),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '$letter.',
                  style: AppText.title(size: 18, color: AppColors.navy),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: Text(label, style: AppText.subtitle())),
              if (selected)
                const InkIcon(
                  InkGlyph.check,
                  size: AppIconSize.medium,
                  color: AppColors.navy,
                ),
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
  const WordInputQuestion({
    super.key,
    required this.mission,
    required this.onSubmit,
  });

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
          // The name, written on a museum label.
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpace.lg,
              horizontal: AppSpace.md,
            ),
            decoration: _answerPaper(radius: AppRadius.paper),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                // Empty: the prompt's own blanks, one per letter (a case may
                // say "four letters"). Typing: the child's word in their place.
                _controller.text.trim().isEmpty
                    ? prompt
                    : prompt.replaceAll(
                        RegExp(r'_+'),
                        _controller.text.trim().toUpperCase(),
                      ),
                style: AppText.title(size: 26).copyWith(letterSpacing: 2),
              ),
            ),
          ),
        const SizedBox(height: AppSpace.lg),
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
          style: AppText.title(size: 26).copyWith(letterSpacing: 4),
          decoration: InputDecoration(
            hintText: 'Type the word',
            hintStyle: AppText.bodyText(size: 18, color: AppColors.muted),
            counterText: '',
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpace.lg),
        GameButton(
          label: 'CHECK ANSWER',
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
  const NumberCodeQuestion({
    super.key,
    required this.mission,
    required this.onSubmit,
  });

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
            // The lock's number wheels: the next one to fill is marked in navy.
            for (var i = 0; i < _length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 60,
                height: 72,
                alignment: Alignment.center,
                decoration: _answerPaper(
                  selected: i == _code.length,
                  radius: AppRadius.paper,
                ),
                child: Text(
                  i < _code.length ? _code[i] : '',
                  style: AppText.title(size: 34),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
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
              for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                _Key(label: d, onTap: () => _press(d)),
              _Key(
                glyph: InkGlyph.backspace,
                onTap: _delete,
                subtle: true,
                semantic: 'Delete',
              ),
              _Key(label: '0', onTap: () => _press('0')),
              _Key(
                glyph: InkGlyph.clear,
                onTap: () => setState(() => _code = ''),
                subtle: true,
                semantic: 'Clear',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        GameButton(
          label: 'UNLOCK',
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
  const _Key({
    this.label,
    this.glyph,
    required this.onTap,
    this.subtle = false,
    this.semantic,
  });

  final String? label;
  final InkGlyph? glyph;
  final VoidCallback onTap;
  final bool subtle;
  final String? semantic;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: subtle ? AppColors.parchment : AppColors.paperLight,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppLine.faint(0.25), width: AppLine.rule),
          ),
          child: label != null
              ? Text(
                  label!,
                  style: AppText.title(size: 26, color: AppColors.ink),
                )
              : InkIcon(
                  glyph!,
                  color: AppColors.inkBrown,
                  semanticLabel: semantic,
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TYPE 4 — Image choice (names are hidden: kids must match the description)
// ---------------------------------------------------------------------------

class ImageChoiceQuestion extends ConsumerStatefulWidget {
  const ImageChoiceQuestion({
    super.key,
    required this.mission,
    required this.onSubmit,
  });

  final Mission mission;
  final AnswerCallback onSubmit;

  @override
  ConsumerState<ImageChoiceQuestion> createState() =>
      _ImageChoiceQuestionState();
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
        const SizedBox(height: AppSpace.lg),
        GameButton(
          label: 'CHECK ANSWER',
          onPressed: _selected == null
              ? null
              : () => widget.onSubmit(_selected!),
        ),
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.letter,
    required this.artwork,
    required this.selected,
    required this.onTap,
  });

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
        // A small photograph: white border, letter written in the corner.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: _answerPaper(selected: selected, radius: AppRadius.paper),
          child: Stack(
            children: [
              Positioned.fill(child: LandmarkArt(artwork, borderRadius: 2, showName: false)),
              Positioned(
                left: 6,
                top: 4,
                child: Text(
                  letter,
                  style: AppText.title(size: 20, color: AppColors.navy),
                ),
              ),
              if (selected)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.navy,
                      shape: BoxShape.circle,
                    ),
                    child: const InkIcon(
                      InkGlyph.check,
                      size: AppIconSize.small,
                      color: AppColors.paperLight,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TYPE 5 — Sequence (put steps, turns or words in order)
// ---------------------------------------------------------------------------

class SequenceQuestion extends ConsumerStatefulWidget {
  const SequenceQuestion({
    super.key,
    required this.mission,
    required this.onSubmit,
  });

  final Mission mission;
  final AnswerCallback onSubmit;

  @override
  ConsumerState<SequenceQuestion> createState() => _SequenceQuestionState();
}

class _SequenceQuestionState extends ConsumerState<SequenceQuestion> {
  final _picked = <String>[];

  int get _length =>
      widget.mission.codeLength ??
      Mission.sequenceIds(widget.mission.answer).length;

  /// Turns (LEFT / RIGHT) can repeat; steps and words are used once.
  bool get _reusable => widget.mission.options.length < _length;

  String _label(String id) =>
      widget.mission.options.firstWhere((o) => o.id == id).label;

  void _pick(String id) {
    if (_picked.length >= _length) return;
    ref.read(audioServiceProvider).play(GameSound.tap);
    setState(() => _picked.add(id));
  }

  void _undo() {
    if (_picked.isEmpty) return;
    setState(() => _picked.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.mission.options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The order so far, written down like numbered notebook lines.
        for (var i = 0; i < _length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.sm,
              ),
              decoration: _answerPaper(selected: i == _picked.length),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${i + 1}.',
                      style: AppText.title(size: 18, color: AppColors.navy),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      i < _picked.length ? _label(_picked[i]) : '',
                      semanticsLabel: i < _picked.length
                          ? 'Step ${i + 1}: ${_label(_picked[i])}'
                          : 'Step ${i + 1}: empty',
                      style: AppText.subtitle(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpace.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final o in options)
              _SequenceTile(
                label: o.label,
                used: !_reusable && _picked.contains(o.id),
                onTap: () => _pick(o.id),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkTextButton(
              label: 'Undo',
              glyph: InkGlyph.backspace,
              onPressed: _picked.isEmpty ? null : _undo,
            ),
            InkTextButton(
              label: 'Start again',
              glyph: InkGlyph.clear,
              onPressed: _picked.isEmpty
                  ? null
                  : () => setState(_picked.clear),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        GameButton(
          label: 'CHECK ANSWER',
          onPressed: _picked.length == _length
              ? () => widget.onSubmit(_picked.join(','))
              : null,
        ),
      ],
    );
  }
}

class _SequenceTile extends StatelessWidget {
  const _SequenceTile({
    required this.label,
    required this.used,
    required this.onTap,
  });

  final String label;
  final bool used;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !used,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: used ? null : onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: used ? 0.35 : 1,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52, minWidth: 96),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.md,
            ),
            decoration: _answerPaper(),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppText.subtitle(color: AppColors.navy),
            ),
          ),
        ),
      ),
    );
  }
}

/// The puzzle widget for [mission] (shared by missions and final cases).
Widget questionFor(Mission mission, AnswerCallback onSubmit) =>
    switch (mission.type) {
      MissionType.multipleChoice => MultipleChoiceQuestion(
        mission: mission,
        onSubmit: onSubmit,
      ),
      MissionType.wordInput => WordInputQuestion(
        mission: mission,
        onSubmit: onSubmit,
      ),
      MissionType.numberCode || MissionType.finalCode => NumberCodeQuestion(
        mission: mission,
        onSubmit: onSubmit,
      ),
      MissionType.imageChoice => ImageChoiceQuestion(
        mission: mission,
        onSubmit: onSubmit,
      ),
      MissionType.qrScan => QrQuestion(mission: mission, onSubmit: onSubmit),
      MissionType.sequence => SequenceQuestion(
        mission: mission,
        onSubmit: onSubmit,
      ),
    };
