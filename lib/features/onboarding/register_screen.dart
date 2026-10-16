import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/audio_service.dart';
import '../../data/models/profile.dart';
import '../../widgets/art_assets.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/paper.dart';
import '../../widgets/paper_background.dart';
import '../game/game_controller.dart';
import 'detective_form.dart';
import 'how_to_play_state.dart';

/// CREATE YOUR DETECTIVE: the device's one detective, made once — a picture
/// (boy or girl) and a name — then the investigation begins. No account,
/// nothing sent anywhere.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  DetectiveAvatar? _avatar;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    // Both are checked at once: the name line shows its own error.
    final named = _formKey.currentState?.validate() ?? false;
    if (_avatar == null) {
      showGameToast(context, 'Choose your detective first.', glyph: InkGlyph.pen);
      return;
    }
    if (!named) return;
    final error = ref.read(gameControllerProvider.notifier).createDetective(_name.text, _avatar);
    if (error != null) {
      showGameToast(context, error, glyph: InkGlyph.pen);
      return;
    }
    // A new detective learns how to play first (once), then the season's
    // casebook and its opening.
    context.go(ref.read(needsHowToPlayProvider) ? Routes.howToPlay : Routes.season);
  }

  @override
  Widget build(BuildContext context) {
    return DetectiveDesk(
      formKey: _formKey,
      heading: 'CREATE YOUR DETECTIVE',
      question: 'Who will take\nthe case?',
      onBack: () => context.go(Routes.start),
      avatar: _avatar,
      onAvatar: (a) => setState(() => _avatar = a),
      name: _name,
      action: 'START INVESTIGATION',
      onAction: _submit,
    );
  }
}

/// The detective's form laid on the desk, the office of the title page
/// behind it, dimmed: [heading], [question], the picture choice, the name
/// line, and [action]. Shared by CREATE YOUR DETECTIVE and the detective's
/// settings. With the keyboard up (half a small phone), the emblem folds
/// away and the pictures shrink so the line and the button stay in view.
class DetectiveDesk extends StatelessWidget {
  const DetectiveDesk({
    super.key,
    required this.formKey,
    required this.heading,
    required this.question,
    required this.onBack,
    required this.avatar,
    required this.onAvatar,
    required this.name,
    required this.action,
    required this.onAction,
    this.note,
  });

  final GlobalKey<FormState> formKey;
  final String heading;
  final String question;
  final VoidCallback onBack;
  final DetectiveAvatar? avatar;
  final ValueChanged<DetectiveAvatar> onAvatar;
  final TextEditingController name;
  final String action;
  final VoidCallback onAction;

  /// A quiet line under the button (e.g. what a change keeps).
  final String? note;

  @override
  Widget build(BuildContext context) {
    final typing = MediaQuery.viewInsetsOf(context).bottom > 0;
    // A small phone: the emblem stays off and the pictures are shorter, so
    // the whole form and its button fit the screen.
    final short = MediaQuery.sizeOf(context).height < 700;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Stack(
      children: [
        const Positioned.fill(child: OfficeBehind()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            foregroundColor: AppColors.goldLight,
            iconTheme: const IconThemeData(color: AppColors.goldLight),
            leading: IconButton(
              tooltip: 'Back',
              icon: const InkIcon(InkGlyph.back),
              style: IconButton.styleFrom(backgroundColor: AppColors.navyDeep.withValues(alpha: 0.45)),
              onPressed: onBack,
            ),
          ),
          extendBodyBehindAppBar: true,
          body: InkSurface(
            night: true,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  // A narrower sheet than the screen: the office shows around it.
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpace.xxl,
                    vertical: typing ? AppSpace.sm : AppSpace.lg,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: formKey,
                      // Laid on the desk as the page comes up (a short fade
                      // and settle; none with reduced motion).
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: still ? Duration.zero : const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, child) => Opacity(
                          opacity: t,
                          child: Transform.translate(offset: Offset(0, 10 * (1 - t)), child: child),
                        ),
                        child: Column(
                          children: [
                            PaperSheet(
                              ruled: true,
                              tilt: -0.006,
                              padding: EdgeInsets.fromLTRB(
                                AppSpace.lg,
                                typing ? AppSpace.md : AppSpace.xl,
                                AppSpace.lg,
                                AppSpace.lg,
                              ),
                              child: Column(
                                children: [
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOut,
                                    child: typing
                                        ? const SizedBox(width: double.infinity)
                                        : Column(
                                            children: [
                                              // The letterhead: one line, fitted to the paper.
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  'LONDON DETECTIVE AGENCY',
                                                  maxLines: 1,
                                                  style: AppText.eyebrow(),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              const SizedBox(height: AppSpace.sm),
                                              if (!short) ...[
                                                const BrassEmblem(size: 48),
                                                const SizedBox(height: AppSpace.sm),
                                              ],
                                            ],
                                          ),
                                  ),
                                  Text(
                                    heading,
                                    style: AppText.mark(color: AppColors.burgundy),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpace.xs),
                                  Text(
                                    question,
                                    style: AppText.title(size: typing ? 20 : 23),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpace.sm),
                                  const OrnamentRule(),
                                  SizedBox(height: typing ? AppSpace.sm : AppSpace.md),
                                  AvatarChoice(selected: avatar, onChanged: onAvatar, compact: typing, short: short),
                                  SizedBox(height: typing ? AppSpace.sm : AppSpace.lg),
                                  DetectiveNameLine(controller: name, onSubmitted: onAction, compact: typing),
                                ],
                              ),
                            ),
                            SizedBox(height: typing ? AppSpace.md : AppSpace.lg),
                            GameButton(
                              label: action,
                              arrow: true,
                              singleLine: true, // one line on a 360-wide phone
                              style: GameButtonStyle.glass,
                              tap: TapRole.primary,
                              onPressed: onAction,
                            ),
                            if (note != null && !typing) ...[
                              const SizedBox(height: AppSpace.md),
                              Text(
                                note!,
                                textAlign: TextAlign.center,
                                style: AppText.caption(color: AppColors.paperLight.withValues(alpha: 0.85)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The detective's office from the title page, out of focus and in shadow
/// around the lamp-lit desk: present, never competing with the form.
class OfficeBehind extends StatelessWidget {
  const OfficeBehind({super.key});

  @override
  Widget build(BuildContext context) {
    const pixels = ArtAssets.titleDetectiveOfficePixels;
    return ColoredBox(
      color: AppColors.nightBottom,
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: LayoutBuilder(
                builder: (context, box) => Image.asset(
                  ArtAssets.titleDetectiveOffice,
                  fit: BoxFit.cover,
                  // Low down on the painting: the desk and its lamp light.
                  alignment: const Alignment(0.2, 0.6),
                  width: double.infinity,
                  height: double.infinity,
                  // Blurred anyway: a small decode is enough.
                  cacheWidth: math.min(
                    (math.max(
                              box.maxWidth,
                              box.maxHeight * pixels.aspectRatio,
                            ) *
                            1.2)
                        .ceil(),
                    pixels.width.toInt(),
                  ),
                  excludeFromSemantics: true,
                  errorBuilder: (context, error, stack) =>
                      const SizedBox.expand(),
                ),
              ),
            ),
            // Dimmed, darkest at the edges.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.95,
                  colors: [
                    AppColors.navyDeep.withValues(alpha: 0.45),
                    AppColors.navyDeep.withValues(alpha: 0.82),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
