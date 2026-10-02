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

/// The one look of an answer card, whatever the puzzle type, so a child
/// learns a single rule: the card I chose is filled in navy ink.
enum AnswerState {
  /// Lying on the desk, ready to be chosen.
  idle,

  /// Chosen: navy fill, gold letter mark and tick.
  selected,

  /// Confirmed right / wrong (success / try-again ink). The result itself is
  /// announced by the success overlay and the try-again sheet; these keep a
  /// card in the same family wherever a puzzle shows its result.
  correct,
  wrong,

  /// Used up (a sequence step already placed, an empty line): flat, faded.
  disabled,
}

/// Paper answer surface shared by the puzzle types.
BoxDecoration _answerPaper(AnswerState state) {
  final (fill, edge, width) = switch (state) {
    AnswerState.idle || AnswerState.disabled => (AppColors.paperLight, AppLine.faint(0.22), AppLine.hairline),
    AnswerState.selected => (AppColors.navy, AppColors.navyDeep, AppLine.hairline),
    AnswerState.correct => (AppColors.successSoft, AppColors.success, AppLine.ink),
    AnswerState.wrong => (AppColors.tryAgainSoft, AppColors.tryAgain, AppLine.ink),
  };
  return BoxDecoration(
    color: fill,
    borderRadius: BorderRadius.circular(AppRadius.paper),
    border: Border.all(color: edge, width: width),
    boxShadow: state == AnswerState.disabled ? null : AppShadow.paperLift,
  );
}

/// Ink on an answer surface in [state].
Color _answerInk(AnswerState state) => state == AnswerState.selected ? AppColors.paperLight : AppColors.ink;

/// A tappable answer surface: it presses in slightly (scale and a little
/// fade) while the finger is down. The same short feedback for every puzzle
/// type and the keypad, instead of a Material ripple.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final duration = still ? Duration.zero : const Duration(milliseconds: 90);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: duration,
        curve: Curves.easeOut,
        child: AnimatedOpacity(opacity: _down ? 0.85 : 1, duration: duration, child: widget.child),
      ),
    );
  }
}

/// A round letter mark ("A", "B", "1") printed beside an answer.
class _LetterMark extends StatelessWidget {
  const _LetterMark(this.letter, {this.inverse = false});

  final String letter;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final ink = inverse ? AppColors.goldLight : AppColors.navy;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: inverse ? Colors.transparent : AppColors.paper,
        border: Border.all(color: ink.withValues(alpha: inverse ? 0.9 : 0.45), width: AppLine.rule),
      ),
      child: Text(letter, style: AppText.style(AppText.display, size: 15, weight: FontWeight.w700, color: ink)),
    );
  }
}

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

  AnswerState get state => selected ? AnswerState.selected : AnswerState.idle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$letter. $label',
      excludeSemantics: true,
      child: _Pressable(
        onTap: onTap,
        // A card on the desk; the chosen one is filled in navy ink.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.md,
          ),
          decoration: _answerPaper(state),
          child: Row(
            children: [
              _LetterMark(letter, inverse: selected),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  label,
                  style: AppText.subtitle(color: _answerInk(state)),
                ),
              ),
              if (selected)
                const InkIcon(
                  InkGlyph.check,
                  size: AppIconSize.medium,
                  color: AppColors.goldLight,
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
            decoration: _answerPaper(AnswerState.idle),
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
            // The lock's number wheels: the next one to fill is ringed in gold.
            for (var i = 0; i < _length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 60,
                height: 74,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: i == _code.length ? AppColors.goldLight : AppColors.gold.withValues(alpha: 0.45),
                    width: i == _code.length ? AppLine.ink + 0.5 : AppLine.hairline,
                  ),
                  boxShadow: const [BoxShadow(color: Color(0x332A2622), blurRadius: 6, offset: Offset(0, 3))],
                ),
                foregroundDecoration: const _WheelShade(),
                child: Text(
                  i < _code.length ? _code[i] : '',
                  style: AppText.title(size: 34, color: AppColors.goldLight),
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
                caption: 'Delete',
              ),
              _Key(label: '0', onTap: () => _press('0')),
              _Key(
                glyph: InkGlyph.clear,
                onTap: () => setState(() => _code = ''),
                subtle: true,
                semantic: 'Clear',
                caption: 'Clear',
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
    this.caption,
  });

  final String? label;
  final InkGlyph? glyph;
  final VoidCallback onTap;
  final bool subtle;
  final String? semantic;

  /// A short word under a glyph key ("Delete", "Clear").
  final String? caption;

  @override
  Widget build(BuildContext context) {
    // A typewriter key: a paper cap on a darker edge. It presses in like the
    // answer cards, instead of a Material ripple.
    return _Pressable(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: subtle ? AppColors.parchment : AppColors.paperLight,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppLine.faint(0.2), width: AppLine.hairline),
          boxShadow: const [BoxShadow(color: AppColors.parchmentDark, offset: Offset(0, 3))],
        ),
        child: label != null
            ? Text(
                label!,
                style: AppText.title(size: 26, color: AppColors.ink),
              )
            // The two erasers look alike as glyphs: name them under the icon.
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkIcon(glyph!, color: AppColors.inkBrown, semanticLabel: semantic),
                    if (caption != null)
                      ExcludeSemantics(child: Text(caption!, style: AppText.caption(color: AppColors.inkBrown))),
                  ],
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
      child: _Pressable(
        onTap: onTap,
        // A small photograph in a paper mount, letter written in the corner;
        // chosen, the mount is filled in navy ink like a chosen answer card.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(AppSpace.sm),
          decoration: _answerPaper(selected ? AnswerState.selected : AnswerState.idle),
          child: Stack(
            children: [
              Positioned.fill(child: LandmarkArt(artwork, borderRadius: 2, showName: false)),
              Positioned(left: 6, top: 6, child: _LetterMark(letter)),
              if (selected)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.goldLight, width: AppLine.rule),
                    ),
                    child: const InkIcon(
                      InkGlyph.check,
                      size: AppIconSize.small,
                      color: AppColors.goldLight,
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
              // Written steps sit on paper; the next empty line is ringed in
              // gold ("write here next"), never filled like a chosen answer.
              decoration: i == _picked.length
                  ? _answerPaper(AnswerState.idle).copyWith(
                      border: Border.all(color: AppColors.gold, width: AppLine.ink),
                    )
                  : _answerPaper(i < _picked.length ? AnswerState.idle : AnswerState.disabled),
              child: Row(
                children: [
                  _LetterMark('${i + 1}'),
                  const SizedBox(width: AppSpace.md),
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
        // Wraps rather than overflows inside a narrow paper sheet (final case).
        Wrap(
          alignment: WrapAlignment.center,
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
      child: _Pressable(
        onTap: used ? null : onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: used ? 0.4 : 1,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52, minWidth: 96),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.md,
            ),
            decoration: _answerPaper(used ? AnswerState.disabled : AnswerState.idle),
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

/// The curve of a number wheel: darker towards its top and bottom edges.
class _WheelShade extends Decoration {
  const _WheelShade();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _WheelShadePainter();
}

class _WheelShadePainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final r = offset & configuration.size!;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)));
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent, Colors.transparent, Colors.black.withValues(alpha: 0.35)],
          stops: const [0, 0.3, 0.7, 1],
        ).createShader(r),
    );
    canvas.restore();
  }
}
