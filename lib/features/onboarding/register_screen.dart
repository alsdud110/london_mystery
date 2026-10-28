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
import '../../data/models/difficulty.dart';
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
/// (boy or girl), a name and the level of English its seasons start at
/// (Rookie unless another is chosen) — then the investigation begins. No
/// account, nothing sent anywhere.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  DetectiveAvatar? _avatar;
  Difficulty _difficulty = Difficulty.standard;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    // Both are checked at once: the name line shows its own error.
    final named = _formKey.currentState?.validate() ?? false;
    if (_avatar == null) {
      showGameToast(
        context,
        'Choose your detective first.',
        glyph: InkGlyph.pen,
      );
      return;
    }
    if (!named) return;
    final error = ref
        .read(gameControllerProvider.notifier)
        .createDetective(_name.text, _avatar, difficulty: _difficulty);
    if (error != null) {
      showGameToast(context, error, glyph: InkGlyph.pen);
      return;
    }
    // A new detective learns how to play first (once), then the World Map,
    // where London's card opens the season's cover and its opening.
    context.go(
      ref.read(needsHowToPlayProvider) ? Routes.howToPlay : Routes.worldMap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DetectiveDesk(
      formKey: _formKey,
      heading: 'Create Your Detective',
      question: 'Who will take\nthe case?',
      onBack: () => context.go(Routes.start),
      avatar: _avatar,
      onAvatar: (a) => setState(() => _avatar = a),
      name: _name,
      difficulty: _difficulty,
      onDifficulty: (d) => setState(() => _difficulty = d),
      action: 'START INVESTIGATION',
      onAction: _submit,
    );
  }
}

/// The detective's form over London at night: a title slip ([heading],
/// [question]) laid on the form, then its numbered steps — the picture, the
/// name, the level (only with [onDifficulty]) — and [action] under it.
/// Shared by CREATE YOUR DETECTIVE and the detective's settings. With the
/// keyboard up (half a small phone), the letterhead, the question and the
/// level fold away and the pictures shrink to their words, so the name box
/// and the button stay in view.
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
    this.difficulty = Difficulty.standard,
    this.onDifficulty,
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

  /// The level chosen, shown only with [onDifficulty].
  final Difficulty difficulty;
  final ValueChanged<Difficulty>? onDifficulty;

  /// A quiet line under the button (e.g. what a change keeps).
  final String? note;

  /// How far the title slip lies over the top of the form.
  static const _overlap = AppSpace.md;

  @override
  Widget build(BuildContext context) {
    final typing = MediaQuery.viewInsetsOf(context).bottom > 0;
    // A small phone: shorter pictures and closer steps, so more of the form
    // fits the screen.
    final short = MediaQuery.sizeOf(context).height < 700;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final gap = short ? AppSpace.md : AppSpace.lg;
    const fold = Duration(milliseconds: 200);

    // Laid on the form, not on the night: the light shadow of paper on paper.
    final slip = Transform.rotate(
      angle: -0.012,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          boxShadow: AppShadow.paperLift,
        ),
        child: PaperSheet(
          lifted: false,
          padding: EdgeInsets.fromLTRB(
            AppSpace.lg,
            typing ? AppSpace.sm : AppSpace.md,
            AppSpace.lg,
            AppSpace.md,
          ),
          child: Column(
            children: [
              AnimatedSize(
                duration: fold,
                curve: Curves.easeOut,
                child: typing
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.xs),
                        // The letterhead: one line, fitted to the paper.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'LONDON DETECTIVE AGENCY',
                            maxLines: 1,
                            style: AppText.eyebrow(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
              ),
              Text(
                heading,
                style: AppText.aside(size: 16, color: AppColors.burgundy),
                textAlign: TextAlign.center,
              ),
              AnimatedSize(
                duration: fold,
                curve: Curves.easeOut,
                child: typing
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: AppSpace.xs),
                        child: Text(
                          question,
                          style: AppText.title(size: short ? 21 : 23),
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );

    final form = PaperSheet(
      padding: EdgeInsets.fromLTRB(
        AppSpace.lg,
        _overlap + (typing ? AppSpace.md : AppSpace.lg),
        AppSpace.lg,
        AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. The picture: the player picks how their detective looks (the
          // cases are the same for both).
          if (!typing) ...[
            const FormStep(number: 1, label: 'Choose Your Detective'),
            SizedBox(height: short ? AppSpace.sm : AppSpace.md),
          ],
          AvatarChoice(
            selected: avatar,
            onChanged: onAvatar,
            compact: typing,
            short: short,
          ),
          SizedBox(height: typing ? AppSpace.md : gap),
          // 2. The name.
          const FormStep(number: 2, label: 'Your Detective Name'),
          SizedBox(height: typing ? AppSpace.sm : AppSpace.md),
          DetectiveNameLine(
            controller: name,
            onSubmitted: onAction,
            compact: typing,
          ),
          // 3. The level, folded away while the name is written (the choice
          // is kept).
          if (onDifficulty case final onLevel?)
            AnimatedSize(
              duration: fold,
              curve: Curves.easeOut,
              child: typing
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: gap),
                        const FormStep(number: 3, label: 'Choose Your Level'),
                        SizedBox(height: short ? AppSpace.sm : AppSpace.md),
                        DifficultyChoice(
                          selected: difficulty,
                          onChanged: onLevel,
                          row: true,
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );

    return Stack(
      children: [
        const Positioned.fill(child: LondonNightBehind()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            foregroundColor: AppColors.goldLight,
            iconTheme: const IconThemeData(color: AppColors.goldLight),
            // A slim bar: the form, not the bar, is the page.
            toolbarHeight: AppBarSize.slim,
            titleTextStyle: AppText.barTitle(color: AppColors.goldLight, slim: true),
            title: const Text('WORLD MYSTERY'),
            leading: IconButton(
              tooltip: 'Back',
              icon: const InkIcon(InkGlyph.back),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.navyDeep.withValues(alpha: 0.45),
              ),
              onPressed: onBack,
            ),
          ),
          extendBodyBehindAppBar: true,
          body: InkSurface(
            night: true,
            child: SafeArea(
              // Laid over the city as the page comes up (a short fade and
              // settle; none with reduced motion).
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: still
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - t)),
                    child: child,
                  ),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    // The form and its button together in the middle; when
                    // the form is taller than the screen it scrolls and the
                    // button stays under it, on screen — in reach of the
                    // thumb, above the keyboard too.
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Center(
                          heightFactor: 1,
                          child: SingleChildScrollView(
                            // The city shows around the paper (the safe area
                            // already keeps it under the back button).
                            padding: EdgeInsets.fromLTRB(
                              AppSpace.xl,
                              typing ? AppSpace.sm : AppSpace.md,
                              AppSpace.xl,
                              typing ? AppSpace.md : AppSpace.lg,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              // The slip is laid over the form: below it on
                              // the page, painted after it.
                              child: Column(
                                verticalDirection: VerticalDirection.up,
                                children: [
                                  form,
                                  Transform.translate(
                                    offset: const Offset(0, _overlap),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpace.sm,
                                      ),
                                      child: slip,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpace.xl,
                          0,
                          AppSpace.xl,
                          typing ? AppSpace.sm : AppSpace.lg,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GameButton(
                                label: action,
                                arrow: true,
                                singleLine:
                                    true, // one line on a 360-wide phone
                                style: GameButtonStyle.navy,
                                tap: TapRole.primary,
                                onPressed: onAction,
                              ),
                              if (note != null && !typing) ...[
                                const SizedBox(height: AppSpace.md),
                                Text(
                                  note!,
                                  textAlign: TextAlign.center,
                                  style: AppText.caption(
                                    color: AppColors.paperLight.withValues(
                                      alpha: 0.85,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
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

/// London at night behind the form — the river, a lamp, Big Ben — softened
/// and in shadow: present, never competing with the form.
class LondonNightBehind extends StatelessWidget {
  const LondonNightBehind({super.key});

  @override
  Widget build(BuildContext context) {
    const pixels = ArtAssets.season1LondonNightPixels;
    return ColoredBox(
      color: AppColors.nightBottom,
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
              child: LayoutBuilder(
                builder: (context, box) => Image.asset(
                  ArtAssets.season1LondonNight,
                  fit: BoxFit.cover,
                  // The lamp at the left, Big Ben at the right.
                  alignment: const Alignment(0, -0.2),
                  width: double.infinity,
                  height: double.infinity,
                  // Softened anyway: a small decode is enough.
                  cacheWidth: math.min(
                    (math.max(
                              box.maxWidth,
                              box.maxHeight * pixels.aspectRatio,
                            ) *
                            1.5)
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
                    AppColors.navyDeep.withValues(alpha: 0.35),
                    AppColors.navyDeep.withValues(alpha: 0.75),
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
