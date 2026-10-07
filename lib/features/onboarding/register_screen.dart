import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../widgets/art_assets.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/paper.dart';
import '../../widgets/paper_background.dart';
import '../game/game_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: ref.read(gameControllerProvider).detectiveName ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final error = ref
        .read(gameControllerProvider.notifier)
        .registerDetective(_name.text);
    if (error != null) {
      showGameToast(context, error, glyph: InkGlyph.pen);
      return;
    }
    context.go(Routes.season);
  }

  /// The name as written on the line: 24 pt, or smaller when a long name
  /// would not fit between the pen's slot and its twin (48 dp each side).
  static TextStyle _nameStyle(
    BuildContext context,
    String name,
    double lineWidth, {
    Color color = AppColors.navy,
  }) {
    final full = AppText.title(
      size: 24,
      color: color,
    ).copyWith(letterSpacing: 2);
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
    // Keyboard up (on a small phone it takes half the screen): the card folds
    // away its emblem and agency line so the name line and the button both
    // stay in view above the keys.
    final typing = MediaQuery.viewInsetsOf(context).bottom > 0;
    // The registration form laid on the detective's desk: the office of the
    // title page behind it, dimmed, so the paper is the one thing in the
    // light. The office stays put when the keyboard comes up.
    return Stack(
      children: [
        const Positioned.fill(child: _OfficeBehind()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            foregroundColor: AppColors.goldLight,
            iconTheme: const IconThemeData(color: AppColors.goldLight),
            leading: IconButton(
              tooltip: 'Back',
              icon: const InkIcon(InkGlyph.back),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.navyDeep.withValues(alpha: 0.45),
              ),
              onPressed: () => context.go(Routes.start),
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
                      key: _formKey,
                      // The registration form, to be filled in by hand. It is
                      // laid on the desk as the page comes up (a short fade
                      // and settle; none with reduced motion).
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration:
                            (MediaQuery.maybeDisableAnimationsOf(context) ??
                                false)
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
                                              const SizedBox(
                                                height: AppSpace.md,
                                              ),
                                              const BrassEmblem(size: 64),
                                              const SizedBox(
                                                height: AppSpace.md,
                                              ),
                                            ],
                                          ),
                                  ),
                                  Text(
                                    'DETECTIVE REGISTRATION',
                                    style: AppText.mark(
                                      color: AppColors.burgundy,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpace.sm),
                                  Text(
                                    'What should we\ncall you, Detective?',
                                    style: AppText.title(
                                      size: typing ? 21 : 24,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpace.sm),
                                  const OrnamentRule(),
                                  SizedBox(
                                    height: typing ? AppSpace.sm : AppSpace.lg,
                                  ),
                                  // A long name is written a little smaller so it always fits the
                                  // line (and stays centred) instead of scrolling inside it.
                                  LayoutBuilder(
                                    builder: (context, box) =>
                                        ValueListenableBuilder<
                                          TextEditingValue
                                        >(
                                          valueListenable: _name,
                                          builder: (context, value, _) => TextFormField(
                                            controller: _name,
                                            // No focus on arrival: the whole form shows first;
                                            // the keyboard comes when the line is tapped.
                                            textAlign: TextAlign.center,
                                            // A tap anywhere else puts the pen down: the keyboard
                                            // closes, the name stays. It only listens — the tap
                                            // still reaches whatever was tapped (Back, the button).
                                            onTapOutside: (_) => FocusManager
                                                .instance
                                                .primaryFocus
                                                ?.unfocus(),
                                            textCapitalization:
                                                TextCapitalization.characters,
                                            textInputAction:
                                                TextInputAction.done,
                                            maxLength:
                                                AppConstants.nameMaxLength,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                RegExp(
                                                  r'[A-Za-z0-9가-힣ㄱ-ㅎㅏ-ㅣ .\-]',
                                                ),
                                              ),
                                              LengthLimitingTextInputFormatter(
                                                AppConstants.nameMaxLength,
                                              ),
                                            ],
                                            style: _nameStyle(
                                              context,
                                              value.text,
                                              box.maxWidth,
                                            ),
                                            // Written on the card's signature line, not in a box.
                                            decoration: InputDecoration(
                                              labelText: 'Detective Name',
                                              // A printed label over the line, as on a form — it
                                              // stays put rather than floating up.
                                              floatingLabelBehavior:
                                                  FloatingLabelBehavior.always,
                                              floatingLabelAlignment:
                                                  FloatingLabelAlignment.center,
                                              labelStyle: AppText.bodyText(
                                                size: 16,
                                                color: AppColors.muted,
                                              ),
                                              floatingLabelStyle:
                                                  AppText.eyebrow(
                                                    color: AppColors.muted,
                                                  ).copyWith(
                                                    letterSpacing: 1.5,
                                                  ),
                                              counterStyle: AppText.caption(),
                                              hintText: 'SHERLOCK',
                                              // The example name fits the line by the same rule as a real one.
                                              hintStyle: _nameStyle(
                                                context,
                                                'SHERLOCK',
                                                box.maxWidth,
                                                color: AppColors.parchmentDark,
                                              ),
                                              // Lowered a touch (paint only, the line's layout is
                                              // unchanged) to sit level with the written name.
                                              prefixIcon: Transform.translate(
                                                offset: const Offset(0, 7),
                                                child: const InkIcon(
                                                  InkGlyph.pen,
                                                  color: AppColors.inkBrown,
                                                ),
                                              ),
                                              // The same empty slot on the right as the pen's on the
                                              // left (both get the decorator's 48 dp icon box), so the
                                              // writing space — and the centred name in it — sits in
                                              // the middle of the form, under its label.
                                              suffixIcon:
                                                  const SizedBox.shrink(),
                                              filled: false,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: AppSpace.md,
                                                  ),
                                              border: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: AppLine.faint(0.45),
                                                  width: AppLine.rule,
                                                ),
                                              ),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: AppLine.faint(
                                                        0.45,
                                                      ),
                                                      width: AppLine.rule,
                                                    ),
                                                  ),
                                              // Writing on it darkens the line in ink, no bright accent.
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: AppColors.inkBrown,
                                                      width: AppLine.rule,
                                                    ),
                                                  ),
                                              errorBorder:
                                                  const UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: AppColors.tryAgain,
                                                      width: AppLine.rule,
                                                    ),
                                                  ),
                                              focusedErrorBorder:
                                                  const UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: AppColors.tryAgain,
                                                      width: AppLine.ink,
                                                    ),
                                                  ),
                                            ),
                                            validator:
                                                GameController.validateName,
                                            onFieldSubmitted: (_) => _submit(),
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: typing ? AppSpace.md : AppSpace.lg,
                            ),
                            // It hands the detective the season's casebook.
                            GameButton(
                              label: 'OPEN THE CASEBOOK',
                              arrow: true,
                              singleLine: true, // one line on a 360-wide phone
                              style: GameButtonStyle.glass,
                              onPressed: _submit,
                            ),
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
class _OfficeBehind extends StatelessWidget {
  const _OfficeBehind();

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
