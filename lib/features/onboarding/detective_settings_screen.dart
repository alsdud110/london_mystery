import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/difficulty.dart';
import '../../data/models/profile.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_dialog.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/ink_icon.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import 'register_screen.dart';

/// The detective's name, picture and level, changed after the detective was
/// made. The name and picture change alone: every case, XP, coin and badge
/// stays as it is. The level follows the season policy: free while the
/// season it is for has not begun; for a season under way only by playing
/// it again from its Case 01 (asked first, see [RestartSeasonDialog]).
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

  /// The level shown: the season's while it is under way, else the
  /// detective's (for the season to come).
  late Difficulty _level =
      (_season()?.begun ?? false) ? _season()!.level : ref.read(detectiveProfileProvider).difficulty;

  /// A new level for a season not begun yet, saved with SAVE CHANGES.
  bool _levelChanged = false;

  /// The season a change of level is about, as it stands (null: none to
  /// come — the last season is complete).
  SeasonLevel? _season() {
    final id = ref.read(levelSeasonProvider);
    return id == null ? null : ref.read(seasonLevelProvider(id));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _close() => context.canPop() ? context.pop() : context.go(Routes.start);

  Future<void> _chooseLevel(Difficulty level) async {
    if (level == _level) return;
    final season = _season();
    if (season == null || !season.begun) {
      setState(() {
        _level = level;
        _levelChanged = true;
      });
      return;
    }
    // A season under way keeps its level, or starts again at the new one.
    if (!await RestartSeasonDialog.ask(context)) return;
    if (!mounted) return;
    final seasonId = ref.read(levelSeasonProvider)!;
    ref.read(gameControllerProvider.notifier).restartSeason(seasonId, level);
    showGameToast(context, 'Your season starts again as ${level.label}.', glyph: InkGlyph.check);
    // Its Case 01 again, from the season's page.
    context.go(Routes.season);
  }

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
    if (_levelChanged && _level != ref.read(detectiveProfileProvider).difficulty) {
      await ref.read(detectiveProfileProvider.notifier).setDifficulty(_level);
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
      difficulty: _level,
      onDifficulty: _chooseLevel,
      action: 'SAVE CHANGES',
      onAction: _save,
      note: 'Your cases, XP, coins and badges stay as they are.',
    );
  }
}

/// Asked before a season under way starts again at a new level: KEEP MY
/// LEVEL is the strong, safe answer; RESTART SEASON the quiet one, in the
/// try-again ink. Closing the paper any other way keeps the level.
abstract final class RestartSeasonDialog {
  static const message = 'Changing your level will restart your current season. Your completed seasons will stay safe.';

  /// Whether the detective chose RESTART SEASON.
  static Future<bool> ask(BuildContext context) async {
    final restart = await showDialog<bool>(
      context: context,
      builder: (context) => GameDialog(
        key: const ValueKey('restart-season-dialog'),
        title: 'Restart your season?',
        scrollable: true,
        content: Text(message, textAlign: TextAlign.center, style: AppText.bodyText(size: 16)),
        actions: [
          GameButton(label: 'KEEP MY LEVEL', onPressed: () => Navigator.of(context).pop(false)),
          const SizedBox(height: AppSpace.xs),
          InkTextButton(
            label: 'RESTART SEASON',
            color: AppColors.tryAgain,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    return restart ?? false;
  }
}
