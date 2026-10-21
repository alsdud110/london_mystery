import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/mission.dart';
import '../../../data/models/river_puzzles.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import 'river_papers.dart';
import 'tower_documents.dart' show showDocumentCloser;

/// The keeper's hut ([KeeperHutScene]), in three places, one after the
/// other: outside it (its door tapped), inside it (the ledger on the desk
/// tapped), then the ledger's first page, where a box number is circled.
/// THIS IS THE BOX sends it to [onSubmit], checked as the puzzle's answer.
/// Where the detective is and the box circled are the page's ([at],
/// [circled]); every change is handed up ([onAt], [onCircle]) to be saved.
class KeeperHut extends StatefulWidget {
  const KeeperHut({
    super.key,
    required this.scene,
    required this.mission,
    required this.at,
    required this.circled,
    required this.onAt,
    required this.onCircle,
    required this.onSubmit,
  });

  final KeeperHutScene scene;
  final Mission mission;
  final HutStep at;
  final String? circled;
  final ValueChanged<HutStep> onAt;
  final ValueChanged<String> onCircle;
  final Future<void> Function(String answer) onSubmit;

  @override
  State<KeeperHut> createState() => _KeeperHutState();
}

class _KeeperHutState extends State<KeeperHut> {
  bool _checking = false;

  KeeperHutScene get _scene => widget.scene;

  Future<void> _check() async {
    final box = widget.circled;
    if (_checking || box == null) return;
    setState(() => _checking = true);
    try {
      await widget.onSubmit(box);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedSwitcher(
      duration: still ? Duration.zero : const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
      child: switch (widget.at) {
        HutStep.outside => _place(
            key: const ValueKey('hut-outside'),
            task: _scene.doorTask,
            picture: _scene.outside,
            label: _scene.outsideLabel,
            spot: _scene.doorArea,
            spotKey: 'hut-door',
            spotName: 'The open door of the hut',
            onSpot: () => widget.onAt(HutStep.inside),
          ),
        HutStep.inside => _place(
            key: const ValueKey('hut-inside'),
            task: _scene.ledgerTask,
            picture: _scene.inside,
            label: _scene.insideLabel,
            spot: _scene.ledgerArea,
            spotKey: 'hut-ledger',
            spotName: 'The ledger on the desk',
            onSpot: () => widget.onAt(HutStep.ledger),
          ),
        HutStep.ledger => _ledger(),
      },
    );
  }

  Widget _place({
    required Key key,
    required String task,
    required String picture,
    required String label,
    required Rect spot,
    required String spotKey,
    required String spotName,
    required VoidCallback onSpot,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(task, key: const ValueKey('hut-task'), textAlign: TextAlign.center, style: AppText.subtitle()),
        const SizedBox(height: AppSpace.md),
        DecoratedBox(
          decoration: BoxDecoration(boxShadow: AppShadow.paperLift, borderRadius: BorderRadius.circular(AppRadius.paper)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.paper),
            child: AspectRatio(
              aspectRatio: _scene.pixels.aspect,
              child: LayoutBuilder(
                builder: (context, box) => Stack(
                  children: [
                    Positioned.fill(
                      child: Semantics(
                        image: true,
                        label: label,
                        excludeSemantics: true,
                        child: Image.asset(picture, key: ValueKey('hut-picture-$spotKey'), fit: BoxFit.fill, excludeFromSemantics: true),
                      ),
                    ),
                    Positioned(
                      left: spot.left * box.maxWidth,
                      top: spot.top * box.maxHeight,
                      width: spot.width * box.maxWidth,
                      height: spot.height * box.maxHeight,
                      child: HutSpot(key: ValueKey(spotKey), name: spotName, onTap: onSpot),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.at == HutStep.inside) ...[
          const SizedBox(height: AppSpace.sm),
          Center(
            child: InkTextButton(
              key: const ValueKey('hut-go-out'),
              label: 'Back outside',
              glyph: InkGlyph.back,
              onPressed: () => widget.onAt(HutStep.outside),
            ),
          ),
        ],
      ],
    );
  }

  Widget _ledger() {
    final circled = widget.circled;
    final label = circled == null ? null : widget.mission.options.where((o) => o.id == circled).firstOrNull?.label;
    return Column(
      key: const ValueKey('hut-ledger-page'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_scene.circleTask, key: const ValueKey('hut-task'), textAlign: TextAlign.center, style: AppText.subtitle()),
        const SizedBox(height: AppSpace.md),
        DecoratedBox(
          decoration: BoxDecoration(boxShadow: AppShadow.paperLift, borderRadius: BorderRadius.circular(AppRadius.paper)),
          child: LedgerPageView(key: const ValueKey('ledger-page-0'), scene: _scene, page: 0, circled: circled, onBox: widget.onCircle, words: true),
        ),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpace.sm,
          children: [
            InkTextButton(
              key: const ValueKey('ledger-closer'),
              label: 'Look closer',
              glyph: InkGlyph.search,
              onPressed: () => showDocumentCloser(
                context,
                title: _scene.pages.first.title,
                aspect: LedgerEvidenceArt(_scene, 0).aspect,
                child: LedgerPageView(scene: _scene, page: 0, circled: circled, words: true),
              ),
            ),
            InkTextButton(
              key: const ValueKey('hut-go-desk'),
              label: 'Back to the desk',
              glyph: InkGlyph.back,
              onPressed: () => widget.onAt(HutStep.inside),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          label == null ? 'No box circled yet.' : 'You circled: ${label.toUpperCase()}',
          key: const ValueKey('ledger-circled'),
          textAlign: TextAlign.center,
          style: AppText.bodyText(size: 17, weight: FontWeight.w600, color: label == null ? AppColors.muted : AppColors.burgundy),
        ),
        const SizedBox(height: AppSpace.md),
        GameButton(
          key: const ValueKey('ledger-check'),
          label: _scene.checkLabel,
          glyph: InkGlyph.check,
          tap: TapRole.primary,
          onPressed: circled != null && !_checking ? _check : null,
        ),
      ],
    );
  }
}

/// A thing in a picture to go to or open (a door, a ledger): a fine gold
/// frame round it, a glass in its corner.
class HutSpot extends StatelessWidget {
  const HutSpot({super.key, required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$name. Tap it.',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.9), width: AppLine.ink),
            borderRadius: BorderRadius.circular(AppRadius.paper),
            color: AppColors.goldLight.withValues(alpha: 0.06),
          ),
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.xs),
              child: CircleAvatar(
                radius: 13,
                backgroundColor: AppColors.navyDeep.withValues(alpha: 0.85),
                child: const InkIcon(InkGlyph.search, size: AppIconSize.tiny, color: AppColors.goldLight),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// After the box is right: the first page with Box 23 circled, the page
/// turned, and Box 23 found on the second one. Only then CONTINUE
/// ([onContinue]: the Discovery Moment and the story go on).
class LedgerSecondPage extends StatefulWidget {
  const LedgerSecondPage({super.key, required this.scene, required this.answer, required this.onContinue});

  final KeeperHutScene scene;

  /// The box found (the puzzle's answer).
  final String answer;
  final VoidCallback onContinue;

  @override
  State<LedgerSecondPage> createState() => _LedgerSecondPageState();
}

class _LedgerSecondPageState extends State<LedgerSecondPage> {
  bool _turned = false;
  bool _found = false;
  bool _missed = false;

  void _tap(String box) => setState(() {
        if (box == widget.scene.findBox) {
          _found = true;
          _missed = false;
        } else {
          _missed = true;
        }
      });

  @override
  Widget build(BuildContext context) {
    final s = widget.scene;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final task = !_turned ? s.solvedLine : (_found ? s.foundLine : s.findTask);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_turned || _found) ...[
              const InkIcon(InkGlyph.check, size: AppIconSize.small, color: AppColors.success),
              const SizedBox(width: AppSpace.sm),
            ],
            Flexible(
              child: Text(
                task,
                key: const ValueKey('ledger-turn-task'),
                textAlign: TextAlign.center,
                style: AppText.subtitle(color: !_turned || _found ? AppColors.success : AppColors.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        // The page turns: the second slides in over the first.
        AnimatedSwitcher(
          duration: still ? Duration.zero : const Duration(milliseconds: 450),
          transitionBuilder: (child, anim) => SlideTransition(
            position: Tween(begin: const Offset(0.25, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: DecoratedBox(
            key: ValueKey(_turned ? 'ledger-page-1' : 'ledger-page-0-solved'),
            decoration: BoxDecoration(boxShadow: AppShadow.paperLift, borderRadius: BorderRadius.circular(AppRadius.paper)),
            child: _turned
                ? LedgerPageView(scene: s, page: 1, found: _found ? s.findBox : null, onBox: _found ? null : _tap, words: true)
                : LedgerPageView(scene: s, page: 0, circled: widget.answer, words: true),
          ),
        ),
        if (_missed) ...[
          const SizedBox(height: AppSpace.sm),
          Text('Look for BOX 23 on this page.', key: const ValueKey('ledger-missed'), textAlign: TextAlign.center, style: AppText.aside(size: 16, color: AppColors.inkBrown)),
        ],
        const SizedBox(height: AppSpace.lg),
        if (!_turned)
          GameButton(
            key: const ValueKey('ledger-turn'),
            label: s.turnLabel,
            arrow: true,
            tap: TapRole.primary,
            onPressed: () => setState(() => _turned = true),
          )
        else
          GameButton(
            key: const ValueKey('ledger-continue'),
            label: 'CONTINUE',
            arrow: true,
            tap: TapRole.primary,
            onPressed: _found ? widget.onContinue : null,
          ),
      ],
    );
  }
}
