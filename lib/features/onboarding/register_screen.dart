import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../widgets/game_button.dart';
import '../../widgets/paper_background.dart';
import '../game/game_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: ref.read(gameControllerProvider).detectiveName ?? '');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final error = ref.read(gameControllerProvider.notifier).registerDetective(_name.text);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    context.go(Routes.episodes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(Routes.start),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: PaperBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const _DetectiveBadgeCard(),
                      const SizedBox(height: 28),
                      Text('DETECTIVE ID', style: AppText.eyebrow()),
                      const SizedBox(height: 8),
                      Text('What is your\ndetective name?', style: AppText.title(size: 30), textAlign: TextAlign.center),
                      const SizedBox(height: 28),
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
                        style: AppText.title(size: 28, color: AppColors.navy),
                        decoration: InputDecoration(
                          labelText: 'Detective Name',
                          floatingLabelAlignment: FloatingLabelAlignment.center,
                          labelStyle: AppText.bodyText(size: 16, color: AppColors.muted),
                          hintText: 'MINYOUNG',
                          hintStyle: AppText.title(size: 28, color: AppColors.parchmentDark),
                          prefixIcon: const Icon(Icons.badge_rounded, color: AppColors.royalBlue),
                        ),
                        validator: GameController.validateName,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 20),
                      GameButton(label: 'START MISSION', icon: Icons.play_arrow_rounded, onPressed: _submit),
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

class _DetectiveBadgeCard extends StatelessWidget {
  const _DetectiveBadgeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.gold,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.navy, width: 4),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: const Icon(Icons.local_police_rounded, size: 64, color: AppColors.navy),
    );
  }
}
