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
  const DetectivePortrait({super.key, required this.avatar, this.capColor = AppColors.inkBrown});

  final DetectiveAvatar avatar;
  final Color capColor;

  @override
  Widget build(BuildContext context) => Image.asset(
        avatarAsset(avatar),
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stack) =>
            Center(child: InkIcon(InkGlyph.deerstalker, size: AppIconSize.hero, color: capColor)),
      );
}

/// BOY / GIRL, side by side: two printed cards on the form, the chosen one
/// inked in navy with a tick. [compact] (keyboard up): the words only.
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
              height: compact ? 0 : (short ? 68 : 104),
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
          duration: reduce ? Duration.zero : const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(AppSpace.sm),
          decoration: BoxDecoration(
            color: selected ? AppColors.paperLight : AppColors.parchment.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.paper),
            border: Border.all(
              color: selected ? AppColors.navy : AppLine.faint(0.3),
              width: selected ? AppLine.ink : AppLine.hairline,
            ),
          ),
          child: Column(
            children: [
              AnimatedContainer(
                duration: reduce ? Duration.zero : const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                height: height,
                child: height == 0 ? null : Stack(
                  fit: StackFit.expand,
                  children: [
                    DetectivePortrait(avatar: avatar, capColor: ink),
                    if (selected)
                      const Align(
                        alignment: Alignment.topRight,
                        child: InkIcon(InkGlyph.check, size: AppIconSize.small, color: AppColors.navy),
                      ),
                  ],
                ),
              ),
              if (height > 0) const SizedBox(height: AppSpace.xs),
              Text(
                avatar.label,
                style: AppText.mark(color: ink, size: 15).copyWith(letterSpacing: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CHOOSE YOUR LEVEL: ROOKIE / JUNIOR / MASTER, one printed card under the
/// other, each with its line of what it means. The chosen one is ringed in
/// antique gold with a tick (never the colour alone); the others carry an
/// empty ring. A whole card is the target.
class DifficultyChoice extends StatelessWidget {
  const DifficultyChoice({super.key, required this.selected, required this.onChanged});

  final Difficulty selected;
  final ValueChanged<Difficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, d) in Difficulty.values.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpace.sm),
          _DifficultyCard(
            difficulty: d,
            selected: selected == d,
            onTap: () {
              if (selected != d) playUiTap(context, TapRole.select);
              onChanged(d);
            },
          ),
        ],
      ],
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({required this.difficulty, required this.selected, required this.onTap});

  final Difficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final duration = reduce ? Duration.zero : const Duration(milliseconds: 180);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '${difficulty.label.toLowerCase()} level. ${difficulty.blurb}',
      // The card's own tap, so a screen reader can choose it too.
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('difficulty-${difficulty.storageId}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
          decoration: BoxDecoration(
            color: selected ? AppColors.paperLight : AppColors.parchment.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.paper),
            border: Border.all(
              color: selected ? AppColors.gold : AppLine.faint(0.3),
              width: selected ? AppLine.ink : AppLine.hairline,
            ),
          ),
          child: Row(
            children: [
              // The mark: a tick in a gold ring when chosen, an empty ring
              // when not — the choice reads without its colour.
              AnimatedContainer(
                duration: duration,
                width: AppIconSize.regular,
                height: AppIconSize.regular,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.gold : AppLine.faint(0.35),
                    width: selected ? AppLine.ink : AppLine.rule,
                  ),
                ),
                child: selected
                    ? const Center(child: InkIcon(InkGlyph.check, size: AppIconSize.tiny, color: AppColors.goldDeep))
                    : null,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      difficulty.label,
                      style: AppText.mark(color: selected ? AppColors.goldDeep : AppColors.muted, size: 15)
                          .copyWith(letterSpacing: 2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      difficulty.blurb,
                      style: AppText.caption(color: selected ? AppColors.ink : AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The name, written on the form's signature line: centred, its letters as
/// typed, a long name written a little smaller so it always fits the line.
class DetectiveNameLine extends StatelessWidget {
  const DetectiveNameLine({super.key, required this.controller, required this.onSubmitted, this.compact = false});

  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final bool compact;

  /// The name as written on the line: 24 pt, or smaller when a long name
  /// would not fit between the pen's slot and its twin (48 dp each side).
  static TextStyle _nameStyle(BuildContext context, String name, double lineWidth, {Color color = AppColors.navy}) {
    final full = AppText.title(size: 24, color: color).copyWith(letterSpacing: 2);
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
    final size = (24 * room / width).clamp(12.0, 24.0);
    return full.copyWith(fontSize: size, letterSpacing: 2 * size / 24);
  }

  @override
  Widget build(BuildContext context) {
    UnderlineInputBorder line(Color color, [double width = AppLine.rule]) =>
        UnderlineInputBorder(borderSide: BorderSide(color: color, width: width));
    return LayoutBuilder(
      builder: (context, box) => ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextFormField(
          controller: controller,
          // No focus on arrival: the whole form shows first; the keyboard
          // comes when the line is tapped.
          textAlign: TextAlign.center,
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
          style: _nameStyle(context, value.text, box.maxWidth),
          decoration: InputDecoration(
            labelText: 'Detective Name',
            // A printed label over the line, as on a form.
            floatingLabelBehavior: FloatingLabelBehavior.always,
            floatingLabelAlignment: FloatingLabelAlignment.center,
            labelStyle: AppText.bodyText(size: 16, color: AppColors.muted),
            floatingLabelStyle: AppText.eyebrow(color: AppColors.muted).copyWith(letterSpacing: 1.5),
            counterStyle: AppText.caption(),
            hintText: 'Sherlock',
            hintStyle: _nameStyle(context, 'Sherlock', box.maxWidth, color: AppColors.parchmentDark),
            // Lowered a touch (paint only) to sit level with the written name.
            prefixIcon: Transform.translate(
              offset: const Offset(0, 7),
              child: const InkIcon(InkGlyph.pen, color: AppColors.inkBrown),
            ),
            // The same empty slot on the right as the pen's on the left, so
            // the centred name sits in the middle of the form.
            suffixIcon: const SizedBox.shrink(),
            filled: false,
            contentPadding: EdgeInsets.symmetric(vertical: compact ? AppSpace.sm : AppSpace.md),
            border: line(AppLine.faint(0.45)),
            enabledBorder: line(AppLine.faint(0.45)),
            // Writing on it darkens the line in ink, no bright accent.
            focusedBorder: line(AppColors.inkBrown),
            errorBorder: line(AppColors.tryAgain),
            focusedErrorBorder: line(AppColors.tryAgain, AppLine.ink),
          ),
          validator: GameController.validateName,
          onFieldSubmitted: (_) => onSubmitted(),
        ),
      ),
    );
  }
}
