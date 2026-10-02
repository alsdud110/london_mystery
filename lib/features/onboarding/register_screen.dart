import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
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
    final error = ref.read(gameControllerProvider.notifier).registerDetective(_name.text);
    if (error != null) {
      showGameToast(context, error, glyph: InkGlyph.pen);
      return;
    }
    context.go(Routes.season);
  }

  @override
  Widget build(BuildContext context) {
    // Keyboard up (on a small phone it takes half the screen): the card folds
    // away its emblem and agency line so the name line and the button both
    // stay in view above the keys.
    final typing = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const InkIcon(InkGlyph.back),
          onPressed: () => context.go(Routes.start),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: PaperBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: typing ? AppSpace.sm : AppSpace.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  // The detective's ID card, to be filled in by hand.
                  child: Column(
                    children: [
                      PaperSheet(
                        ruled: true,
                        tilt: -0.006,
                        padding: EdgeInsets.fromLTRB(AppSpace.xl, typing ? AppSpace.lg : AppSpace.xxl, AppSpace.xl, AppSpace.xl),
                        child: Column(
                          children: [
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                              child: typing
                                  ? const SizedBox(width: double.infinity)
                                  : Column(
                                      children: [
                                        Text('LONDON DETECTIVE AGENCY', style: AppText.eyebrow(), textAlign: TextAlign.center),
                                        const SizedBox(height: AppSpace.lg),
                                        const BrassEmblem(size: 88),
                                        const SizedBox(height: AppSpace.lg),
                                      ],
                                    ),
                            ),
                            Text('DETECTIVE ID', style: AppText.eyebrow(color: AppColors.burgundy)),
                            const SizedBox(height: AppSpace.sm),
                            Text(
                              'What is your\ndetective name?',
                              style: AppText.title(size: typing ? 22 : 28),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpace.sm),
                            const OrnamentRule(),
                            SizedBox(height: typing ? AppSpace.md : AppSpace.xl),
                            TextFormField(
                              controller: _name,
                              autofocus: true,
                              textAlign: TextAlign.center,
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.done,
                              maxLength: AppConstants.nameMaxLength,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9가-힣ㄱ-ㅎㅏ-ㅣ .\-]')),
                                LengthLimitingTextInputFormatter(AppConstants.nameMaxLength),
                              ],
                              style: AppText.title(size: 28, color: AppColors.navy).copyWith(letterSpacing: 2),
                              // Written on the card's signature line, not in a box.
                              decoration: InputDecoration(
                                labelText: 'Detective Name',
                                floatingLabelAlignment: FloatingLabelAlignment.center,
                                labelStyle: AppText.bodyText(size: 16, color: AppColors.muted),
                                hintText: 'SHERLOCK',
                                hintStyle: AppText.title(
                                  size: 28,
                                  color: AppColors.parchmentDark,
                                ).copyWith(letterSpacing: 2),
                                prefixIcon: const InkIcon(InkGlyph.pen, color: AppColors.royalBlue),
                                filled: false,
                                contentPadding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                                border: UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppLine.faint(0.45), width: AppLine.rule),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppLine.faint(0.45), width: AppLine.rule),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.navy, width: AppLine.ink),
                                ),
                                errorBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.tryAgain, width: AppLine.rule),
                                ),
                                focusedErrorBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.tryAgain, width: AppLine.ink),
                                ),
                              ),
                              validator: GameController.validateName,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: typing ? AppSpace.md : AppSpace.xl),
                      // It hands the detective the season's casebook.
                      GameButton(label: 'OPEN THE CASEBOOK', arrow: true, onPressed: _submit),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
