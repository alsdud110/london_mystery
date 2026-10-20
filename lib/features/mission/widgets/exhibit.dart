import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/scene_exhibit.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/ink_icon.dart';
import 'scene_explore.dart' show LookMark;

/// A thing handed over with the mission's document ([Exhibit]): laid on the
/// page a little askew, a small glass on it (a tick once looked at); a tap
/// looks at it closer ([showExhibitZoom]).
class ExhibitObject extends StatelessWidget {
  const ExhibitObject({super.key, required this.exhibit, required this.looked, required this.onOpen});

  final Exhibit exhibit;
  final bool looked;
  final VoidCallback onOpen;

  /// The widest it lies on the page.
  static const maxWidth = 340.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${exhibit.title}. ${exhibit.description} Tap to look closer.',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('exhibit-${exhibit.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        child: Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxWidth),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Transform.rotate(
                      angle: -0.035,
                      child: AspectRatio(
                        aspectRatio: exhibit.pixels.aspect,
                        child: Hero(
                          tag: 'exhibit-${exhibit.id}',
                          child: Image.asset(
                            exhibit.picture,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                            // Decoded no larger than shown.
                            cacheWidth: (maxWidth * MediaQuery.devicePixelRatioOf(context)).ceil(),
                          ),
                        ),
                      ),
                    ),
                    Positioned(right: 4, top: 4, child: LookMark(looked: looked)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const InkIcon(InkGlyph.search, size: AppIconSize.small, color: AppColors.burgundy),
                const SizedBox(width: AppSpace.xs),
                Flexible(
                  child: Text(
                    // "THE LOST TICKET" → "Tap the ticket…".
                    'Tap the ${exhibit.title.split(' ').last.toLowerCase()} to look ${looked ? 'again' : 'closer'}.',
                    style: AppText.bodyText(size: 15, weight: FontWeight.w700, color: AppColors.burgundy),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// [exhibit] looked at closer, over the page: the whole picture as wide as
/// the screen, its name, and one line about it.
Future<void> showExhibitZoom(BuildContext context, Exhibit exhibit) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: AppColors.navyDeep.withValues(alpha: 0.88),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim, _) => FadeTransition(opacity: anim, child: _ExhibitZoom(exhibit: exhibit)),
    ),
  );
}

class _ExhibitZoom extends StatelessWidget {
  const _ExhibitZoom({required this.exhibit});

  final Exhibit exhibit;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(exhibit.title, style: AppText.mark(color: AppColors.goldLight)),
                  const SizedBox(height: AppSpace.lg),
                  // Pinch for the small print.
                  InteractiveViewer(
                    maxScale: 3,
                    child: Semantics(
                      image: true,
                      label: exhibit.description,
                      child: AspectRatio(
                        aspectRatio: exhibit.pixels.aspect,
                        child: Hero(
                          tag: 'exhibit-${exhibit.id}',
                          child: Image.asset(exhibit.picture, key: const ValueKey('exhibit-zoom'), fit: BoxFit.contain, excludeFromSemantics: true),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  GlossaryText(
                    exhibit.caption,
                    textAlign: TextAlign.center,
                    linkColor: AppColors.goldLight,
                    style: AppText.aside(size: 17, color: AppColors.paperLight),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text('Pinch to look closer.', textAlign: TextAlign.center, style: AppText.caption(color: AppColors.paperLight.withValues(alpha: 0.75))),
                  const SizedBox(height: AppSpace.xl),
                  SizedBox(
                    width: 260,
                    child: GameButton(
                      key: const ValueKey('exhibit-close'),
                      label: 'BACK TO THE NOTES',
                      singleLine: true,
                      style: GameButtonStyle.glass,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
