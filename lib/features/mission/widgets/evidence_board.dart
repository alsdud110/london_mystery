import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/mission.dart';
import '../../../data/models/tower_puzzles.dart';
import '../../../widgets/evidence_card.dart' show EvidenceLinkRow, showEvidenceZoom;
import '../../../widgets/game_button.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/paper.dart' show OrnamentRule;
import '../../../widgets/symbol_icon.dart';
import 'tower_documents.dart';

/// The final's board ([EvidenceBoardSpec]: Case 03's, Case 08's): its
/// questions, the case's evidence, and what can be concluded. A question is tapped, then the
/// evidence that answers it (tapped again: taken off); a piece can answer
/// more than one question, and a question can need more than one piece.
/// Once every question has evidence, a conclusion is chosen; SOLVE THE
/// CASE sends the board to [onSubmit], checked as the puzzle's answer.
/// How the board is left is saved as it changes ([onState]).
class EvidenceBoard extends StatelessWidget {
  const EvidenceBoard({
    super.key,
    required this.scene,
    required this.mission,
    required this.evidence,
    required this.links,
    required this.conclusion,
    required this.question,
    required this.checking,
    required this.onQuestion,
    required this.onLink,
    required this.onConclusion,
    required this.onSubmit,
  });

  final EvidenceBoardSpec scene;
  final Mission mission;

  /// The case's evidence, by board id (`e1`).
  final Map<String, Evidence> evidence;
  final Map<String, Set<String>> links;
  final String? conclusion;

  /// The question being linked.
  final String? question;
  final bool checking;
  final ValueChanged<String> onQuestion;
  final ValueChanged<String> onLink;
  final ValueChanged<String> onConclusion;
  final VoidCallback onSubmit;

  bool get _allLinked => scene.questions.every((q) => links[q.id]?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final selected = question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(scene.linkTask, key: const ValueKey('board-task'), textAlign: TextAlign.center, style: AppText.subtitle()),
        const SizedBox(height: AppSpace.md),
        for (final (i, q) in scene.questions.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpace.sm),
          _QuestionCard(
            key: ValueKey('board-question-${q.id}'),
            number: i + 1,
            text: q.text,
            selected: selected == q.id,
            linked: [
              for (final e in scene.evidence)
                if (links[q.id]?.contains(e.id) ?? false) evidence[e.id]?.name ?? e.id,
            ],
            onTap: () => onQuestion(q.id),
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        Text(
          selected == null ? 'YOUR EVIDENCE' : 'YOUR EVIDENCE · QUESTION ${scene.questions.indexWhere((q) => q.id == selected) + 1}',
          textAlign: TextAlign.center,
          style: AppText.eyebrow(),
        ),
        const SizedBox(height: AppSpace.sm),
        for (final e in scene.evidence)
          if (evidence[e.id] case final ev?)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: _EvidenceRow(
                key: ValueKey('board-evidence-${e.id}'),
                evidence: ev,
                linked: selected != null && (links[selected]?.contains(e.id) ?? false),
                active: selected != null,
                onTap: selected == null ? null : () => onLink(e.id),
              ),
            ),
        if (_allLinked) ...[
          const SizedBox(height: AppSpace.md),
          const Center(child: OrnamentRule()),
          const SizedBox(height: AppSpace.md),
          Text(scene.concludeTask, textAlign: TextAlign.center, style: AppText.subtitle()),
          const SizedBox(height: AppSpace.sm),
          GlossaryText(scene.conclusionQuestion, textAlign: TextAlign.center, style: AppText.title(size: 21)),
          const SizedBox(height: AppSpace.sm),
          for (final c in scene.conclusions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: _ConclusionChoice(
                key: ValueKey('board-conclusion-${c.id}'),
                text: c.text,
                selected: conclusion == c.id,
                onTap: () => onConclusion(c.id),
              ),
            ),
        ],
        const SizedBox(height: AppSpace.md),
        GameButton(
          key: const ValueKey('board-solve'),
          label: scene.solveLabel,
          glyph: InkGlyph.check,
          tap: TapRole.primary,
          onPressed: _allLinked && conclusion != null && !checking ? onSubmit : null,
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({super.key, required this.number, required this.text, required this.selected, required this.linked, required this.onTap});

  final int number;
  final String text;
  final bool selected;
  final List<String> linked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Question $number: $text. ${linked.isEmpty ? 'No evidence yet.' : 'Evidence: ${linked.join(', ')}.'}',
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.royalBlueSoft : AppColors.paperLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          side: BorderSide(color: selected ? AppColors.navy : AppLine.faint(0.3), width: selected ? AppLine.ink : AppLine.hairline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$number', style: AppText.title(size: 22, color: AppColors.goldDeep)),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text, style: AppText.bodyText(size: 16, weight: FontWeight.w600)),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        linked.isEmpty ? 'No evidence yet' : linked.join('  +  '),
                        style: AppText.aside(size: 14, color: linked.isEmpty ? AppColors.muted : AppColors.navy),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A piece of evidence on the board: tapped, linked to (or taken off) the
/// question being linked; its glass opens it up close.
class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({super.key, required this.evidence, required this.linked, required this.active, this.onTap});

  final Evidence evidence;
  final bool linked;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: active,
            selected: linked,
            label: '${evidence.name}${linked ? ', linked' : ''}',
            excludeSemantics: true,
            child: Material(
              color: linked ? AppColors.navy : AppColors.paperLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                side: BorderSide(color: linked ? AppColors.navy : AppLine.faint(0.35), width: AppLine.hairline),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.button),
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xs),
                    child: Row(
                      children: [
                        SymbolBadge(evidence.icon, size: 34, light: linked),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Text(
                            evidence.name,
                            style: AppText.bodyText(size: 16, weight: FontWeight.w600, color: linked ? AppColors.paperLight : AppColors.ink),
                          ),
                        ),
                        if (linked) const InkIcon(InkGlyph.check, size: AppIconSize.small, color: AppColors.goldLight),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Look at ${evidence.name}',
          icon: const InkIcon(InkGlyph.search, color: AppColors.navy),
          onPressed: () => showEvidenceZoom(context, evidence),
        ),
      ],
    );
  }
}

class _ConclusionChoice extends StatelessWidget {
  const _ConclusionChoice({super.key, required this.text, required this.selected, required this.onTap});

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: text,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.navy : AppColors.paperLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          side: BorderSide(color: selected ? AppColors.navy : AppLine.faint(0.35), width: AppLine.hairline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.button),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  style: AppText.bodyText(size: 16, weight: FontWeight.w600, color: selected ? AppColors.paperLight : AppColors.ink),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The time-recording machine on the final's stage: shut, then, as [open]
/// runs (0..1), its hatch open (two pictures in register, crossfaded).
class MachineStage extends StatelessWidget {
  const MachineStage({super.key, required this.scene, required this.open});

  final EvidenceBoardScene scene;
  final Animation<double> open;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Center(
      child: AspectRatio(
        aspectRatio: scene.pixels.aspect,
        child: DecoratedBox(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.paper), boxShadow: AppShadow.onNight),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.paper),
            child: Semantics(
              image: true,
              label: scene.machineLabel,
              excludeSemantics: true,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(scene.shut, key: const ValueKey('machine-shut'), fit: BoxFit.fill, excludeFromSemantics: true),
                  AnimatedBuilder(
                    animation: open,
                    builder: (context, child) {
                      // The hatch swings open over the first part of the solve.
                      final t = open.value <= 0 ? 0.0 : (still ? 1.0 : (open.value / 0.4).clamp(0.0, 1.0));
                      return t == 0 ? const SizedBox.shrink() : Opacity(opacity: t, child: child);
                    },
                    child: Image.asset(scene.open, key: const ValueKey('machine-open'), fit: BoxFit.fill, excludeFromSemantics: true),
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

/// The brass plaque: its blank brass, the message engraved on it by the
/// app, and the word under its waves.
class BrassPlaque extends StatelessWidget {
  const BrassPlaque({super.key, required this.scene});

  final EvidenceBoardScene scene;

  @override
  Widget build(BuildContext context) {
    // Engraved: dark ink with a fine light edge under it.
    TextStyle engraved(double size) => paperInk(size: size, weight: FontWeight.w800, color: AppColors.walnutDeep).copyWith(
          letterSpacing: size * 0.06,
          height: 1.3,
          shadows: [Shadow(color: AppColors.creamGold.withValues(alpha: 0.7), offset: const Offset(0, 1))],
        );
    return Semantics(
      image: true,
      label: '${scene.plaqueLabel}. Engraved on it: ${scene.plaqueMessage.replaceAll('\n', ' ')} Under the waves: ${scene.riverWord}.',
      excludeSemantics: true,
      child: CroppedPicture(
        file: scene.plaque,
        pixels: scene.plaquePixels,
        overlayAt: const Rect.fromLTRB(0, 0, 1, 1),
        overlay: LayoutBuilder(
          builder: (context, box) {
            Rect at(Rect r) => Rect.fromLTRB(r.left * box.maxWidth, r.top * box.maxHeight, r.right * box.maxWidth, r.bottom * box.maxHeight);
            final message = at(scene.plaqueWriteOn);
            final river = at(scene.riverAt);
            return Stack(
              children: [
                Positioned.fromRect(
                  rect: message,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        scene.plaqueMessage,
                        key: const ValueKey('plaque-message'),
                        textAlign: TextAlign.center,
                        style: engraved(box.maxWidth / 22),
                      ),
                    ),
                  ),
                ),
                Positioned.fromRect(
                  rect: river,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        scene.riverWord,
                        key: const ValueKey('plaque-river'),
                        style: engraved(box.maxWidth / 20).copyWith(color: AppColors.goldLight, shadows: const []),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The plaque found inside the machine, read up close: its message, the
/// word under its waves, and the evidence it matches ([evidence]'s link).
Future<void> showBrassPlaque(BuildContext context, {required EvidenceBoardScene scene, required Evidence? evidence}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: AppColors.navyDeep.withValues(alpha: 0.94),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim, _) => FadeTransition(
        opacity: anim,
        child: Material(
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
                      Text('INSIDE THE MACHINE', style: AppText.mark(color: AppColors.goldLight)),
                      const SizedBox(height: AppSpace.lg),
                      ClipRect(child: InteractiveViewer(maxScale: 4, child: BrassPlaque(key: const ValueKey('plaque-close'), scene: scene))),
                      const SizedBox(height: AppSpace.lg),
                      // What the brass says, in words a child reads at once
                      // (the engraving is small on a phone).
                      ExcludeSemantics(
                        child: Text(
                          scene.plaqueMessage,
                          key: const ValueKey('plaque-words'),
                          textAlign: TextAlign.center,
                          style: AppText.title(size: 22, color: AppColors.goldLight).copyWith(letterSpacing: 1.2, height: 1.35),
                        ),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      ExcludeSemantics(
                        child: Text(
                          'Under the waves: ${scene.riverWord}',
                          textAlign: TextAlign.center,
                          style: AppText.aside(size: 17, color: AppColors.paperLight),
                        ),
                      ),
                      if (evidence != null) EvidenceLinkRow(evidenceId: evidence.id, dark: true),
                      const SizedBox(height: AppSpace.xl),
                      Builder(
                        builder: (context) => GameButton(
                          key: const ValueKey('plaque-done'),
                          label: 'BACK TO THE ROOM',
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
        ),
      ),
    ),
  );
}
