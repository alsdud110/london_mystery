import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../data/models/profile.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/ink_icon.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import 'register_screen.dart';

/// The detective's name and picture, changed after the detective was made.
/// Only those change: every case, XP, coin and badge stays as it is.
class DetectiveSettingsScreen extends ConsumerStatefulWidget {
  const DetectiveSettingsScreen({super.key});

  @override
  ConsumerState<DetectiveSettingsScreen> createState() => _DetectiveSettingsScreenState();
}

class _DetectiveSettingsScreenState extends ConsumerState<DetectiveSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: ref.read(gameControllerProvider).detectiveName ?? '');
  late DetectiveAvatar? _avatar = ref.read(detectiveProfileProvider).avatar;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _close() => context.canPop() ? context.pop() : context.go(Routes.start);

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final game = ref.read(gameControllerProvider.notifier);
    if (GameController.cleanName(_name.text) != ref.read(gameControllerProvider).detectiveName) {
      final error = game.renameDetective(_name.text);
      if (error != null) {
        showGameToast(context, error, glyph: InkGlyph.pen);
        return;
      }
    }
    final avatar = _avatar;
    if (avatar != null && avatar != ref.read(detectiveProfileProvider).avatar) {
      await ref.read(detectiveProfileProvider.notifier).setAvatar(avatar);
    }
    if (!mounted) return;
    showGameToast(context, 'Your detective file is updated.', glyph: InkGlyph.check);
    _close();
  }

  @override
  Widget build(BuildContext context) {
    return DetectiveDesk(
      formKey: _formKey,
      heading: 'YOUR DETECTIVE',
      question: 'Change your\nname or picture',
      onBack: _close,
      avatar: _avatar,
      onAvatar: (a) => setState(() => _avatar = a),
      name: _name,
      action: 'SAVE CHANGES',
      onAction: _save,
      note: 'Your cases, XP, coins and badges stay as they are.',
    );
  }
}
