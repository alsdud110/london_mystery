import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/mission.dart';
import '../../../data/models/river_puzzles.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/evidence_card.dart' show EvidenceLinkRow, showEvidenceZoom;
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/symbol_icon.dart';
import 'river_papers.dart';
import 'tower_documents.dart' show showDocumentCloser;

/// The final's street book ([StreetBookScene]): an address is tapped, then
/// the evidence that rules it out (one or two pieces), and CROSS IT OUT
/// ([onCross]) — struck through if the evidence shows it cannot be the
/// address; checked as a wrong answer otherwise. Once every address but one
/// is crossed out, THIS IS THE ADDRESS sends the book to [onSubmit].
/// The book is read one page at a time, its words large enough to read.
class StreetBookPuzzle extends StatefulWidget {
  const StreetBookPuzzle({
    super.key,
    required this.scene,
    required this.mission,
    required this.evidence,
    required this.crossed,
    required this.selected,
    required this.picked,
    required this.checking,
    required this.onSelect,
    required this.onPick,
    required this.onCross,
    required this.onSubmit,
  });

  final StreetBookScene scene;
  final Mission mission;

  /// The case's evidence, by its id in the book's answer (`e1`).
  final Map<String, Evidence> evidence;
  final Map<String, Set<String>> crossed;
  final String? selected;
  final Set<String> picked;
  final bool checking;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onPick;
  final VoidCallback onCross;
  final VoidCallback onSubmit;

  @override
  State<StreetBookPuzzle> createState() => _StreetBookPuzzleState();
}

class _StreetBookPuzzleState extends State<StreetBookPuzzle> {
  /// The page open (0: left, 1: right).
  int _page = 0;

  StreetBookScene get scene => widget.scene;
  Map<String, Set<String>> get crossed => widget.crossed;
  String? get selected => widget.selected;

  /// The addresses still in the book (not crossed out).
  List<StreetEntry> get _left => [for (final e in scene.entries) if (!(crossed[e.id]?.isNotEmpty ?? false)) e];

  @override
  Widget build(BuildContext context) {
    final left = _left;
    final oneLeft = left.length == 1;
    final entry = selected == null ? null : scene.entry(selected!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          oneLeft ? scene.addressTask : scene.pickTask,
          key: const ValueKey('book-task'),
          textAlign: TextAlign.center,
          style: AppText.subtitle(),
        ),
        const SizedBox(height: AppSpace.md),
        // The page the one address left is on, once it is the only one.
        Builder(builder: (context) {
          final page = oneLeft ? left.single.page : _page;
          final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSwitcher(
                duration: still ? Duration.zero : const Duration(milliseconds: 250),
                child: StreetBookView(
                  key: ValueKey('street-book-$page'),
                  scene: scene,
                  page: page,
                  selected: oneLeft ? left.single.id : selected,
                  crossed: {for (final e in crossed.entries) if (e.value.isNotEmpty) e.key},
                  onEntry: oneLeft ? null : widget.onSelect,
                ),
              ),
              if (!oneLeft)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpace.sm,
                  children: [
                    for (final i in [0, 1])
                      InkTextButton(
                        key: ValueKey('book-page-$i'),
                        label: 'Page ${i + 1}',
                        glyph: i == 0 ? InkGlyph.back : InkGlyph.arrow,
                        color: i == page ? AppColors.navy : AppColors.royalBlue,
                        onPressed: i == page ? null : () => setState(() => _page = i),
                      ),
                  ],
                ),
            ],
          );
        }),
        Center(
          child: InkTextButton(
            key: const ValueKey('book-closer'),
            label: 'Look closer',
            glyph: InkGlyph.search,
            onPressed: () => showDocumentCloser(
              context,
              title: 'THE STREET BOOK',
              aspect: StreetBookView.view.width / StreetBookView.view.height,
              child: StreetBookView(scene: scene, selected: null, crossed: {for (final e in crossed.entries) if (e.value.isNotEmpty) e.key}),
            ),
          ),
        ),
        // What the crossed-out addresses were crossed out with.
        for (final e in scene.entries)
          if (crossed[e.id] case final ev? when ev.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.xs),
              child: Text(
                '${e.name}: ${[for (final b in scene.evidence) if (ev.contains(b.id)) widget.evidence[b.id]?.name ?? b.id].join(' + ')}',
                key: ValueKey('book-crossed-note-${e.id}'),
                textAlign: TextAlign.center,
                style: AppText.aside(size: 14, color: AppColors.burgundy),
              ),
            ),
        const SizedBox(height: AppSpace.sm),
        if (oneLeft)
          GameButton(
            key: const ValueKey('book-submit'),
            label: scene.submitLabel,
            glyph: InkGlyph.check,
            tap: TapRole.primary,
            onPressed: widget.checking ? null : widget.onSubmit,
          )
        else if (entry != null)
          _AddressPanel(
            key: ValueKey('book-panel-${entry.id}'),
            scene: scene,
            entry: entry,
            evidence: widget.evidence,
            picked: widget.picked,
            checking: widget.checking,
            onPick: widget.onPick,
            onCross: widget.onCross,
          ),
      ],
    );
  }
}

/// The address picked, in words a child reads at once, the evidence to
/// rule it out with, and CROSS IT OUT.
class _AddressPanel extends StatelessWidget {
  const _AddressPanel({
    super.key,
    required this.scene,
    required this.entry,
    required this.evidence,
    required this.picked,
    required this.checking,
    required this.onPick,
    required this.onCross,
  });

  final StreetBookScene scene;
  final StreetEntry entry;
  final Map<String, Evidence> evidence;
  final Set<String> picked;
  final bool checking;
  final ValueChanged<String> onPick;
  final VoidCallback onCross;

  @override
  Widget build(BuildContext context) {
    final full = picked.length >= scene.maxEvidence;
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.paperLight,
        borderRadius: BorderRadius.circular(AppRadius.paper),
        border: Border.all(color: AppColors.navy, width: AppLine.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(entry.name, key: const ValueKey('book-panel-name'), style: AppText.title(size: 21, color: AppColors.navyDeep)),
          const SizedBox(height: AppSpace.xs),
          // The address read large: its harder words can be looked up here
          // (on the page, a tap picks the address).
          for (final line in entry.lines) GlossaryText(line, style: AppText.bodyText(size: 17)),
          const SizedBox(height: AppSpace.md),
          Text(scene.evidenceTask, style: AppText.eyebrow()),
          const SizedBox(height: AppSpace.sm),
          for (final b in scene.evidence)
            if (evidence[b.id] case final ev?)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: _EvidencePick(
                  key: ValueKey('book-evidence-${b.id}'),
                  evidence: ev,
                  picked: picked.contains(b.id),
                  onTap: picked.contains(b.id) || !full ? () => onPick(b.id) : null,
                ),
              ),
          if (full)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: Text('Two pieces at most.', textAlign: TextAlign.center, style: AppText.aside(size: 14, color: AppColors.inkBrown)),
            ),
          GameButton(
            key: const ValueKey('book-cross'),
            label: scene.crossLabel,
            glyph: InkGlyph.pen,
            tap: TapRole.primary,
            onPressed: picked.isNotEmpty && !checking ? onCross : null,
          ),
        ],
      ),
    );
  }
}

class _EvidencePick extends StatelessWidget {
  const _EvidencePick({super.key, required this.evidence, required this.picked, required this.onTap});

  final Evidence evidence;
  final bool picked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            selected: picked,
            enabled: onTap != null,
            label: '${evidence.name}${picked ? ', chosen' : ''}',
            excludeSemantics: true,
            child: Material(
              color: picked ? AppColors.navy : AppColors.paperLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                side: BorderSide(color: picked ? AppColors.navy : AppLine.faint(0.35), width: AppLine.hairline),
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
                        Opacity(opacity: onTap == null ? 0.45 : 1, child: SymbolBadge(evidence.icon, size: 32, light: picked)),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Text(
                            evidence.name,
                            style: AppText.bodyText(
                              size: 16,
                              weight: FontWeight.w600,
                              color: picked ? AppColors.paperLight : (onTap == null ? AppColors.muted : AppColors.ink),
                            ),
                          ),
                        ),
                        if (picked) const InkIcon(InkGlyph.check, size: AppIconSize.small, color: AppColors.goldLight),
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

/// The final's stage: the keeper's hut while the book is read; as [open]
/// runs with the solve, the gate of the address, its sign painted on it.
class GateStage extends StatelessWidget {
  const GateStage({super.key, required this.scene, required this.open});

  final StreetBookScene scene;
  final Animation<double> open;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Center(
      child: AspectRatio(
        aspectRatio: scene.hutPixels.aspect,
        child: DecoratedBox(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.paper), boxShadow: AppShadow.onNight),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.paper),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Semantics(
                  image: true,
                  label: scene.hutLabel,
                  excludeSemantics: true,
                  child: Image.asset(scene.hut, key: const ValueKey('stage-hut'), fit: BoxFit.cover, excludeFromSemantics: true),
                ),
                // The gate only once the address is found: never before.
                AnimatedBuilder(
                  animation: open,
                  builder: (context, child) {
                    final t = open.value <= 0 ? 0.0 : (still ? 1.0 : (open.value / 0.5).clamp(0.0, 1.0));
                    return t == 0 ? const SizedBox.shrink() : Opacity(opacity: t, child: child);
                  },
                  child: ColoredBox(
                    color: AppColors.navyDeep,
                    child: Center(child: GateView(key: const ValueKey('stage-gate'), scene: scene, view: scene.gateView)),
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

/// At the gate, after the solve: the scrap caught on its bar is taken, set
/// against the torn label (it fits: the address whole), and turned over
/// (its message). [onRead] once the message is read.
Future<void> showGateReveal(BuildContext context, {required StreetBookScene scene, required Evidence? evidence, required VoidCallback onRead}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: AppColors.navyDeep.withValues(alpha: 0.95),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim, _) => FadeTransition(
        opacity: anim,
        child: _GateReveal(scene: scene, evidence: evidence, onRead: onRead),
      ),
    ),
  );
}

class _GateReveal extends StatefulWidget {
  const _GateReveal({required this.scene, required this.evidence, required this.onRead});

  final StreetBookScene scene;
  final Evidence? evidence;
  final VoidCallback onRead;

  @override
  State<_GateReveal> createState() => _GateRevealState();
}

class _GateRevealState extends State<_GateReveal> with SingleTickerProviderStateMixin {
  /// 0: the scrap on the gate; 1: set against the label; 2: turned over.
  int _step = 0;
  late final LabelCut _cut = LabelCut(widget.scene.label);
  late final AnimationController _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  void _next() {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    setState(() => _step++);
    _move.value = 0;
    if (still) {
      _move.value = 1;
    } else {
      _move.forward();
    }
    if (_step == 2) widget.onRead();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scene;
    final screen = MediaQuery.sizeOf(context);
    final l = s.label;
    final size = Size(l.pixels.width, l.pixels.height);
    final lower = LabelEvidenceArt(l, last: true).lowerPart;
    final (title, words, button) = switch (_step) {
      0 => ('THE GATE', 'A scrap of paper is caught in the gate.', 'TAKE THE SCRAP'),
      1 => ('IT FITS', '${l.addressStart}${l.addressRest}', 'TURN IT OVER'),
      _ => ('ON ITS BACK', l.backLines.join('\n'), 'BACK TO THE GATE'),
    };
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
                  Text(title, key: const ValueKey('gate-title'), style: AppText.mark(color: AppColors.goldLight)),
                  const SizedBox(height: AppSpace.lg),
                  switch (_step) {
                    // The gate whole, the scrap caught on its bar.
                    0 => ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: math.max(260, screen.height * 0.52)),
                        child: GateView(
                          key: const ValueKey('gate-whole'),
                          scene: s,
                          scrap: LabelPieceView(key: const ValueKey('gate-scrap'), cut: _cut, piece: DeliveryLabel.last),
                        ),
                      ),
                    // The label's lower piece, and the scrap sliding in to
                    // meet its torn edge.
                    1 => Semantics(
                        image: true,
                        label: 'The scrap fits the torn label: ${l.addressStart}${l.addressRest}.',
                        excludeSemantics: true,
                        child: LabelPart(
                          key: const ValueKey('gate-fit'),
                          part: lower,
                          size: size,
                          sheet: Stack(
                            children: [
                              LabelSheet(cut: _cut, pieces: const {DeliveryLabel.bottom}),
                              AnimatedBuilder(
                                animation: _move,
                                builder: (context, child) => Transform.translate(
                                  offset: Offset(260 * (1 - Curves.easeOutCubic.transform(_move.value)), 0),
                                  child: child,
                                ),
                                child: LabelSheet(cut: _cut, pieces: const {DeliveryLabel.last}),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // The scrap turned over.
                    _ => Semantics(
                        image: true,
                        label: 'The back of the scrap: ${l.backLines.join(' ')} Two clock hands are drawn under it.',
                        excludeSemantics: true,
                        child: SizedBox(
                          width: math.min(screen.width - 2 * AppSpace.lg, 420),
                          child: AnimatedBuilder(
                            animation: _move,
                            builder: (context, _) {
                              final a = _move.value * math.pi;
                              final back = a > math.pi / 2;
                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.0012)
                                  ..rotateY(back ? a - math.pi : a),
                                child: back
                                    ? LabelPieceBackView(key: const ValueKey('gate-scrap-back'), cut: _cut)
                                    : LabelPieceView(cut: _cut, piece: DeliveryLabel.last),
                              );
                            },
                          ),
                        ),
                      ),
                  },
                  const SizedBox(height: AppSpace.lg),
                  // What it says, in words a child reads at once.
                  ExcludeSemantics(
                    child: Text(
                      words,
                      key: ValueKey('gate-words-$_step'),
                      textAlign: TextAlign.center,
                      style: _step == 0
                          ? AppText.bodyText(size: 19, color: AppColors.paperLight)
                          : AppText.title(size: 22, color: AppColors.goldLight).copyWith(height: 1.4, letterSpacing: _step == 1 ? 1.5 : 0),
                    ),
                  ),
                  if (_step == 2) ...[
                    const SizedBox(height: AppSpace.sm),
                    SizedBox(
                      height: 48,
                      child: Image.asset(s.hands, key: const ValueKey('gate-hands'), fit: BoxFit.contain, excludeFromSemantics: true),
                    ),
                    if (widget.evidence case final e?) EvidenceLinkRow(evidenceId: e.id, dark: true),
                  ],
                  const SizedBox(height: AppSpace.xl),
                  GameButton(
                    key: const ValueKey('gate-next'),
                    label: button,
                    arrow: _step < 2,
                    style: GameButtonStyle.glass,
                    tap: TapRole.primary,
                    onPressed: _step < 2 ? _next : () => Navigator.of(context).pop(),
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
