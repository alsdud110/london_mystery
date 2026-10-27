import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/audio_service.dart';
import '../../data/models/detective_name.dart';
import '../../data/models/difficulty.dart';
import '../../data/models/profile.dart';
import '../../widgets/art_assets.dart';
import '../../widgets/game_button.dart';
import '../../widgets/ink_icon.dart';
import '../game/game_controller.dart';

/// The picture of [avatar] (see [ArtAssets.avatarBoy]).
String avatarAsset(DetectiveAvatar avatar) => switch (avatar) {
  DetectiveAvatar.boy => ArtAssets.avatarBoy,
  DetectiveAvatar.girl => ArtAssets.avatarGirl,
};

/// The detective's picture, or — while the picture is not in the app — the
/// detective's cap in ink, never a stand-in drawing.
class DetectivePortrait extends StatelessWidget {
  const DetectivePortrait({
    super.key,
    required this.avatar,
    this.capColor = AppColors.inkBrown,
    this.alignment = Alignment.center,
  });

  final DetectiveAvatar avatar;
  final Color capColor;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Image.asset(
    avatarAsset(avatar),
    fit: BoxFit.contain,
    alignment: alignment,
    excludeFromSemantics: true,
    errorBuilder: (context, error, stack) => Center(
      child: InkIcon(InkGlyph.deerstalker, size: AppIconSize.hero, color: capColor),
    ),
  );
}

/// [word] as a name on the form ("ROOKIE" → "Rookie"): the form's words
/// are read, not stamped.
String titled(String word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase();

/// One numbered step of the detective's form: its number pressed in a wax
/// seal, then what the step asks.
class FormStep extends StatelessWidget {
  const FormStep({super.key, required this.number, required this.label});

  final int number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ExcludeSemantics(
          child: Container(
            width: AppIconSize.large,
            height: AppIconSize.large,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.waxRed,
              border: Border.all(color: AppColors.paperLight.withValues(alpha: 0.35), width: AppLine.hairline),
            ),
            // A number: the reading face, never the display face.
            child: Text(
              '$number',
              textScaler: TextScaler.noScaling,
              style: AppText.button(size: 14, color: AppColors.paperLight).copyWith(letterSpacing: 0),
            ),
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Text(label, style: AppText.title(size: 16, color: AppColors.ink)),
        ),
      ],
    );
  }
}

/// The mark of a choice on the form, in its corner: a navy seal with a tick
/// when chosen, an empty ring when not — the choice reads without its colour.
class _ChoiceMark extends StatelessWidget {
  const _ChoiceMark({required this.selected, required this.duration});

  final bool selected;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      width: AppIconSize.regular,
      height: AppIconSize.regular,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.navy : AppColors.paperLight.withValues(alpha: 0.85),
        border: Border.all(
          color: selected ? AppColors.paperLight : AppLine.faint(0.45),
          width: selected ? AppLine.rule : AppLine.hairline,
        ),
      ),
      child: selected
          ? const Center(
              child: InkIcon(InkGlyph.check, size: AppIconSize.tiny, color: AppColors.paperLight),
            )
          : null,
    );
  }
}

/// The frame of a choice on the form: printed paper, ringed in navy when
/// chosen.
BoxDecoration _choiceFrame(bool selected) => BoxDecoration(
  color: selected ? AppColors.paperLight : AppColors.parchment.withValues(alpha: 0.5),
  borderRadius: BorderRadius.circular(AppRadius.button),
  border: Border.all(
    color: selected ? AppColors.navy : AppLine.faint(0.3),
    width: selected ? AppLine.ink : AppLine.hairline,
  ),
);

/// BOY / GIRL, side by side: two portraits on the form, the chosen one
/// ringed in navy with a tick. [compact] (keyboard up): the words only.
class AvatarChoice extends StatelessWidget {
  const AvatarChoice({
    super.key,
    required this.selected,
    required this.onChanged,
    this.compact = false,
    this.short = false,
  });

  final DetectiveAvatar? selected;
  final ValueChanged<DetectiveAvatar> onChanged;
  final bool compact;

  /// A small phone: shorter pictures.
  final bool short;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, a) in DetectiveAvatar.values.indexed) ...[
          if (i > 0) const SizedBox(width: AppSpace.md),
          Expanded(
            child: _AvatarCard(
              avatar: a,
              selected: selected == a,
              height: compact ? 0 : (short ? 88 : 116),
              onTap: () {
                if (selected != a) playUiTap(context, TapRole.select);
                onChanged(a);
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _AvatarCard extends StatelessWidget {
  const _AvatarCard({required this.avatar, required this.selected, required this.height, required this.onTap});

  final DetectiveAvatar avatar;
  final bool selected;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final duration = reduce ? Duration.zero : const Duration(milliseconds: 180);
    final ink = selected ? AppColors.navy : AppColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: '${avatar.label.toLowerCase()} detective',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('avatar-${avatar.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          decoration: _choiceFrame(selected),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.button - AppLine.ink),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: reduce ? Duration.zero : const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  height: height,
                  child: height == 0
                      ? null
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            // A little London dusk behind the portrait.
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [AppColors.royalBlueSoft, AppColors.paperLight],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpace.sm),
                              child: DetectivePortrait(
                                avatar: avatar,
                                capColor: ink,
                                alignment: Alignment.bottomCenter,
                              ),
                            ),
                            Positioned(
                              top: AppSpace.sm,
                              right: AppSpace.sm,
                              child: _ChoiceMark(selected: selected, duration: duration),
                            ),
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.xs + 2),
                  child: Text(titled(avatar.label), style: AppText.title(size: 15, color: ink)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The ink of a level's cap on its card: the rookie's green, the junior's
/// brown, the master's blue.
Color _levelInk(Difficulty d) => switch (d) {
  Difficulty.rookie => AppColors.success,
  Difficulty.junior => AppColors.inkBrown,
  Difficulty.master => AppColors.royalBlue,
};

/// CHOOSE YOUR LEVEL: ROOKIE / JUNIOR / MASTER. One printed card under the
/// other, each with its line of what it means; with [row], side by side,
/// each with its cap and its line in a few words — back under one another
/// when the cards would be too narrow for their words (a small phone, large
/// text). The chosen one is ringed in navy with a tick (never the colour
/// alone); the others carry an empty ring. A whole card is the target.
class DifficultyChoice extends StatelessWidget {
  const DifficultyChoice({super.key, required this.selected, required this.onChanged, this.row = false});

  final Difficulty selected;
  final ValueChanged<Difficulty> onChanged;
  final bool row;

  /// The narrowest a card side by side may be, at text scale 1.
  static const _minTileWidth = 84.0;

  @override
  Widget build(BuildContext context) {
    void choose(Difficulty d) {
      if (selected != d) playUiTap(context, TapRole.select);
      onChanged(d);
    }

    return LayoutBuilder(
      builder: (context, box) {
        const count = 3;
        final tile = (box.maxWidth - (count - 1) * AppSpace.sm) / count;
        final sideBySide = row && tile >= MediaQuery.textScalerOf(context).scale(_minTileWidth);
        if (sideBySide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, d) in Difficulty.values.indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: _DifficultyTile(difficulty: d, selected: selected == d, onTap: () => choose(d)),
                  ),
                ],
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, d) in Difficulty.values.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpace.sm),
              _DifficultyCard(difficulty: d, selected: selected == d, onTap: () => choose(d)),
            ],
          ],
        );
      },
    );
  }
}

/// What a level's card is to a screen reader, and its tap.
Widget _levelSemantics(Difficulty d, bool selected, VoidCallback onTap, Widget child) => Semantics(
  button: true,
  selected: selected,
  inMutuallyExclusiveGroup: true,
  label: '${d.label.toLowerCase()} level. ${d.blurb}',
  // The card's own tap, so a screen reader can choose it too.
  onTap: onTap,
  excludeSemantics: true,
  child: GestureDetector(
    key: ValueKey('difficulty-${d.storageId}'),
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: child,
  ),
);

/// A level side by side with the others: its cap, its name, its line in a
/// few words, the mark in its corner.
class _DifficultyTile extends StatelessWidget {
  const _DifficultyTile({required this.difficulty, required this.selected, required this.onTap});

  final Difficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final duration = reduce ? Duration.zero : const Duration(milliseconds: 180);
    return _levelSemantics(
      difficulty,
      selected,
      onTap,
      AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        decoration: _choiceFrame(selected),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.xs, AppSpace.md, AppSpace.xs, AppSpace.sm),
              child: Column(
                children: [
                  InkIcon(InkGlyph.deerstalker, size: AppIconSize.large, color: _levelInk(difficulty)),
                  const SizedBox(height: AppSpace.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      titled(difficulty.label),
                      maxLines: 1,
                      style: AppText.title(size: 16, color: selected ? AppColors.navy : AppColors.ink),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    difficulty.tagline,
                    textAlign: TextAlign.center,
                    style: AppText.caption(color: selected ? AppColors.ink : AppColors.muted)
                        .copyWith(fontSize: 13, height: 1.3),
                  ),
                ],
              ),
            ),
            Positioned(
              top: AppSpace.xs + 2,
              right: AppSpace.xs + 2,
              child: _ChoiceMark(selected: selected, duration: duration),
            ),
          ],
        ),
      ),
    );
  }
}

/// A level under the others: the mark, then its name and its whole line.
class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({required this.difficulty, required this.selected, required this.onTap});

  final Difficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final duration = reduce ? Duration.zero : const Duration(milliseconds: 180);
    return _levelSemantics(
      difficulty,
      selected,
      onTap,
      AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
        decoration: _choiceFrame(selected),
        child: Row(
          children: [
            _ChoiceMark(selected: selected, duration: duration),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titled(difficulty.label),
                    style: AppText.title(size: 16, color: selected ? AppColors.navy : AppColors.muted),
                  ),
                  const SizedBox(height: 2),
                  Text(difficulty.blurb, style: AppText.caption(color: selected ? AppColors.ink : AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The name, written in the form's box: its letters as typed, a long name
/// written a little smaller so it always fits; a tap on the cross rubs it
/// out.
class DetectiveNameLine extends StatelessWidget {
  const DetectiveNameLine({super.key, required this.controller, required this.onSubmitted, this.compact = false});

  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final bool compact;

  /// What the box says under it, while the keyboard is down.
  static const helper = 'Shown in every case you solve.';

  /// The name as written in the box: 22 pt, or smaller when a long name
  /// would not fit between the pen's slot and the cross's (48 dp each).
  static TextStyle _nameStyle(BuildContext context, String name, double lineWidth, {Color color = AppColors.navy}) {
    final full = AppText.title(size: 22, color: color).copyWith(letterSpacing: 1);
    if (name.isEmpty) return full;
    // Less a little for the cursor and its margin at the end of the line.
    final room = lineWidth - 2 * kMinInteractiveDimension - AppSpace.md;
    final painter = TextPainter(
      text: TextSpan(text: name, style: full),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    if (width <= room) return full;
    final size = (22 * room / width).clamp(12.0, 22.0);
    return full.copyWith(fontSize: size, letterSpacing: size / 22);
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder box(Color color, [double width = AppLine.hairline]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
      borderSide: BorderSide(color: color, width: width),
    );
    return LayoutBuilder(
      builder: (context, constraints) => ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => Semantics(
          label: 'Detective name',
          child: TextFormField(
            controller: controller,
            // No focus on arrival: the whole form shows first; the keyboard
            // comes when the box is tapped.
            // A tap anywhere else puts the pen down: the keyboard closes, the
            // name stays. It only listens — the tap still reaches its target.
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            // The name is kept exactly as typed: no capitals forced.
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.done,
            maxLength: AppConstants.nameMaxLength,
            inputFormatters: [
              FilteringTextInputFormatter.allow(DetectiveName.typeable),
              LengthLimitingTextInputFormatter(AppConstants.nameMaxLength),
            ],
            style: _nameStyle(context, value.text, constraints.maxWidth),
            decoration: InputDecoration(
              counterStyle: AppText.caption(),
              helperText: compact ? null : helper,
              helperStyle: AppText.caption(),
              helperMaxLines: 2,
              errorStyle: AppText.caption(color: AppColors.tryAgain),
              hintText: 'Sherlock',
              hintStyle: _nameStyle(context, 'Sherlock', constraints.maxWidth, color: AppColors.parchmentDark),
              prefixIcon: const InkIcon(InkGlyph.pen, color: AppColors.inkBrown),
              // The cross rubs the name out; none while the box is empty.
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear name',
                      icon: const InkIcon(InkGlyph.clear, size: AppIconSize.small, color: AppColors.muted),
                      onPressed: controller.clear,
                    ),
              filled: true,
              fillColor: AppColors.paperLight,
              contentPadding: EdgeInsets.symmetric(vertical: compact ? AppSpace.sm : AppSpace.md),
              border: box(AppLine.faint(0.45)),
              enabledBorder: box(AppLine.faint(0.45)),
              // Writing in it darkens the box in ink, no bright accent.
              focusedBorder: box(AppColors.inkBrown, AppLine.rule),
              errorBorder: box(AppColors.tryAgain),
              focusedErrorBorder: box(AppColors.tryAgain, AppLine.ink),
            ),
            validator: GameController.validateName,
            onFieldSubmitted: (_) => onSubmitted(),
          ),
        ),
      ),
    );
  }
}
