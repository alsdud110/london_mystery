import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/abbesses_puzzles.dart';
import '../../../data/models/letter_puzzles.dart' show MapSpot;
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import 'abbesses_papers.dart';
import 'letter_papers.dart' show PicturePart;
import 'river_papers.dart' show PictureCanvas;
import 'workshop_papers.dart' show CroppedPicture;

/// The final's stage ([TornHourScene]): P.'s drawing of the steps, the
/// paper drawn in its margin; once the torn paper is laid on it ([placed]),
/// the paper itself lies there.
class TornHourStage extends StatelessWidget {
  const TornHourStage({super.key, required this.scene, required this.placed});

  final TornHourScene scene;
  final bool placed;

  @override
  Widget build(BuildContext context) => Center(
    child: MorningSketchView(
      sketch: scene.sketch,
      child: placed ? Positioned.fromRect(rect: _paperOn(scene), child: IgnorePointer(child: _PaperOnStudy(scene: scene))) : null,
    ),
  );
}

/// Where the torn paper lies on the drawing: in the margin study, fitted to
/// it (pixels of the drawing).
Rect _paperOn(TornHourScene scene) {
  final at = scene.study.at;
  final aspect = scene.form.aspect;
  final w = at.width;
  final h = w / aspect;
  return Rect.fromCenter(center: at.center, width: w, height: h);
}

class _PaperOnStudy extends StatelessWidget {
  const _PaperOnStudy({required this.scene});

  final TornHourScene scene;

  @override
  Widget build(BuildContext context) => Opacity(
    key: const ValueKey('paper-on-drawing'),
    opacity: 0.92,
    child: TornFormView(form: scene.form),
  );
}

/// The final's first step: the torn paper, turned a quarter at a time
/// (TURN IT), laid on P.'s drawing of it in the margin (dragged there, or
/// LAY IT ON THE DRAWING). It fits only the way the drawing has it; laid
/// another way, or off the study, it says why ([TornHourScene.tearLine],
/// …). Never a wrong answer: [onPlaced] once it fits.
class PaperOnDrawing extends StatefulWidget {
  const PaperOnDrawing({super.key, required this.scene, required this.onPlaced});

  final TornHourScene scene;
  final VoidCallback onPlaced;

  @override
  State<PaperOnDrawing> createState() => _PaperOnDrawingState();
}

class _PaperOnDrawingState extends State<PaperOnDrawing> {
  late int _turns = widget.scene.startTurns;
  String? _line;
  int _misses = 0;

  void _turn() => setState(() {
    _turns = (_turns + 1) % 4;
    _line = null;
  });

  void _lay() {
    if (_turns % 4 == 0) {
      widget.onPlaced();
      return;
    }
    setState(() {
      _line = _misses.isEven ? widget.scene.tearLine : widget.scene.sealLine;
      _misses++;
    });
  }

  void _off() => setState(() => _line = widget.scene.offLine);

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final paper = RotatedBox(quarterTurns: _turns, child: TornFormView(form: scene.form));
    final study = scene.study.at;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(scene.placeTask, key: const ValueKey('place-task'), textAlign: TextAlign.center, style: AppText.subtitle()),
        const SizedBox(height: AppSpace.md),
        // The drawing: its study takes the paper; the rest of it says where.
        MorningSketchView(
          key: const ValueKey('place-drawing'),
          sketch: scene.sketch,
          child: Positioned.fill(
            child: Stack(
              children: [
                Positioned.fill(
                  child: DragTarget<int>(
                    onAcceptWithDetails: (_) => _off(),
                    builder: (context, _, _) => const SizedBox.expand(),
                  ),
                ),
                Positioned.fromRect(
                  rect: study,
                  child: DragTarget<int>(
                    onAcceptWithDetails: (_) => _lay(),
                    builder: (context, candidates, _) => DecoratedBox(
                      key: const ValueKey('place-study'),
                      decoration: BoxDecoration(
                        border: Border.all(color: candidates.isEmpty ? AppColors.gold.withValues(alpha: 0.7) : AppColors.navy, width: 8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Text('THE TORN PAPER', textAlign: TextAlign.center, style: AppText.eyebrow()),
        const SizedBox(height: AppSpace.xs),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220, maxHeight: 220),
            child: Draggable<int>(
              data: _turns,
              feedback: Material(type: MaterialType.transparency, child: SizedBox(width: 150, child: Opacity(opacity: 0.85, child: paper))),
              childWhenDragging: Opacity(opacity: 0.3, child: paper),
              child: Semantics(
                image: true,
                label: 'The torn paper, turned ${_turns * 90} degrees.',
                child: KeyedSubtree(key: ValueKey('place-paper-$_turns'), child: paper),
              ),
            ),
          ),
        ),
        if (_line != null) ...[
          const SizedBox(height: AppSpace.sm),
          Semantics(
            liveRegion: true,
            child: Text(_line!, key: const ValueKey('place-line'), textAlign: TextAlign.center, style: AppText.letter(size: 17, color: AppColors.tryAgain)),
          ),
        ],
        const SizedBox(height: AppSpace.md),
        GameButton(
          key: const ValueKey('place-turn'),
          label: scene.turnLabel,
          style: GameButtonStyle.outline,
          onPressed: _turn,
        ),
        const SizedBox(height: AppSpace.sm),
        GameButton(
          key: const ValueKey('place-lay'),
          label: scene.layLabel,
          glyph: InkGlyph.check,
          tap: TapRole.primary,
          onPressed: _lay,
        ),
      ],
    );
  }
}

/// After the case, P.'s last drawing ([NextLead]): the same bag found in it
/// (three things tapped), then its garden found on the map. True once done
/// (nothing is scored; leaving early returns null).
Future<bool?> showNextLead(BuildContext context, NextLead lead) {
  final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  return Navigator.of(context).push<bool>(
    PageRouteBuilder<bool>(
      opaque: false,
      barrierDismissible: false,
      barrierColor: AppColors.navyDeep.withValues(alpha: 0.975),
      transitionDuration: still ? Duration.zero : const Duration(milliseconds: 250),
      pageBuilder: (context, anim, _) => FadeTransition(opacity: anim, child: _NextLeadPage(lead: lead)),
    ),
  );
}

class _NextLeadPage extends StatefulWidget {
  const _NextLeadPage({required this.lead});

  final NextLead lead;

  @override
  State<_NextLeadPage> createState() => _NextLeadPageState();
}

class _NextLeadPageState extends State<_NextLeadPage> {
  final Set<String> _found = {};
  String? _line;

  /// The place on the map picked, and whether it was right.
  String? _spot;
  bool _done = false;

  NextLead get _lead => widget.lead;
  bool get _bagDone => _lead.bagParts.every((p) => _found.contains(p.id));

  void _tapDrawing(Offset p) {
    final part = _lead.partAt(p.dx, p.dy);
    if (part == null) return;
    setState(() {
      if (_lead.bagParts.contains(part)) _found.add(part.id);
      // The bag found whole: its line gives way to the map's.
      _line = _bagDone ? null : part.line;
    });
  }

  void _pick(String id) => setState(() {
    _spot = id;
    _line = null;
  });

  void _choose() {
    final spot = _spot;
    if (spot == null) return;
    setState(() {
      if (spot == _lead.answer) {
        _done = true;
        _line = null;
      } else {
        _line = _lead.lineFor(spot);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("P.'S LAST DRAWING", textAlign: TextAlign.center, style: AppText.mark(color: AppColors.goldLight)),
                const SizedBox(height: AppSpace.sm),
                Text('One drawing is left at the bottom of the bundle.', textAlign: TextAlign.center, style: AppText.aside(size: 17, color: AppColors.paperLight)),
                const SizedBox(height: AppSpace.md),
                _drawing(),
                const SizedBox(height: AppSpace.md),
                if (!_bagDone) ..._bagStep() else if (!_done) ..._mapStep() else ..._doneStep(),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _drawing() => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.paper),
    child: Semantics(
      label: _lead.label,
      child: PictureCanvas(
        key: const ValueKey('lead-drawing'),
        pixels: _lead.pixels,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: _bagDone ? null : (d) => _tapDrawing(d.localPosition),
          child: Stack(
            children: [
              Positioned.fill(child: Image.asset(_lead.file, fit: BoxFit.fill, excludeFromSemantics: true)),
              for (final p in _lead.bagParts)
                if (_found.contains(p.id))
                  Positioned.fromRect(
                    rect: p.area.inflate(6),
                    child: IgnorePointer(
                      child: DecoratedBox(
                        key: ValueKey('lead-found-${p.id}'),
                        decoration: BoxDecoration(border: Border.all(color: AppColors.gold, width: 6), borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _say(String line, {Color color = AppColors.goldLight}) => Semantics(
    liveRegion: true,
    child: Text(line, key: const ValueKey('lead-line'), textAlign: TextAlign.center, style: AppText.letter(size: 17, color: color)),
  );

  List<Widget> _bagStep() => [
    Text(_lead.bagTask, key: const ValueKey('lead-task'), textAlign: TextAlign.center, style: AppText.title(size: 19, color: AppColors.goldLight)),
    const SizedBox(height: AppSpace.xs),
    Text('Found ${_found.length} of ${_lead.bagParts.length}', key: const ValueKey('lead-count'), textAlign: TextAlign.center, style: AppText.button(size: 15, color: AppColors.paperLight)),
    if (_line != null) ...[const SizedBox(height: AppSpace.sm), _say(_line!)],
  ];

  List<Widget> _mapStep() {
    final spot = _spot;
    return [
      for (final l in _lead.bagDone) _say(l),
      const SizedBox(height: AppSpace.md),
      Text(_lead.mapTask, key: const ValueKey('lead-task'), textAlign: TextAlign.center, style: AppText.title(size: 19, color: AppColors.goldLight)),
      const SizedBox(height: AppSpace.xs),
      Text('In the drawing: ${_lead.features.join(' · ')}', textAlign: TextAlign.center, style: AppText.aside(size: 16, color: AppColors.paperLight)),
      const SizedBox(height: AppSpace.sm),
      _LeadMap(lead: _lead, picked: spot, onPick: _pick),
      if (spot != null) ...[
        const SizedBox(height: AppSpace.sm),
        Text(_lead.spots.firstWhere((s) => s.id == spot).name.toUpperCase(), key: const ValueKey('lead-spot-name'), textAlign: TextAlign.center, style: AppText.mark(color: AppColors.goldLight)),
        const SizedBox(height: AppSpace.xs),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.25),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.paper),
            child: PicturePart(key: ValueKey('lead-spot-close-$spot'), file: _lead.mapFile, pixels: _lead.mapPixels, crop: _closer(_lead.spots.firstWhere((s) => s.id == spot))),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        GameButton(
          key: const ValueKey('lead-choose'),
          label: _lead.chooseLabel,
          glyph: InkGlyph.check,
          style: GameButtonStyle.gold,
          tap: TapRole.primary,
          onPressed: _choose,
        ),
      ],
      if (_line != null) ...[const SizedBox(height: AppSpace.sm), _say(_line!, color: AppColors.paperLight)],
    ];
  }

  /// The map round a place, up close (fractions of the map).
  Rect _closer(MapSpot s) {
    const w = 0.3;
    final h = w * _lead.mapPixels.aspect / 1.5;
    final left = (s.at.dx - w / 2).clamp(0.0, 1 - w);
    final top = (s.at.dy - h / 2).clamp(0.0, 1 - h);
    return Rect.fromLTWH(left, top, w, h);
  }

  List<Widget> _doneStep() => [
    for (final l in _lead.doneLines) ...[_say(l), const SizedBox(height: AppSpace.xs)],
    const SizedBox(height: AppSpace.md),
    GameButton(
      key: const ValueKey('lead-done'),
      label: 'CONTINUE',
      arrow: true,
      style: GameButtonStyle.glass,
      tap: TapRole.primary,
      onPressed: () => Navigator.of(context).pop(true),
    ),
  ];
}

/// The map of Paris whole, a ring round each place to pick (the one picked
/// in gold).
class _LeadMap extends StatelessWidget {
  const _LeadMap({required this.lead, required this.picked, required this.onPick});

  final NextLead lead;
  final String? picked;
  final ValueChanged<String> onPick;

  static const _ring = 120.0;
  static const _tap = 150.0;

  @override
  Widget build(BuildContext context) {
    final p = lead.mapPixels;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.paper),
      child: Semantics(
        label: 'A map of Paris.',
        child: CroppedPicture(
          key: const ValueKey('lead-map'),
          file: lead.mapFile,
          pixels: p,
          crop: const Rect.fromLTRB(0, 0, 1, 1),
          child: Stack(
            children: [
              for (final s in lead.spots) ...[
                Positioned(
                  left: s.at.dx * p.width - _ring / 2,
                  top: s.at.dy * p.height - _ring / 2,
                  width: _ring,
                  height: _ring,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: picked == s.id ? AppColors.goldLight : AppColors.paperLight, width: picked == s.id ? 10 : 6),
                        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 6, spreadRadius: 1)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: s.at.dx * p.width - _tap / 2,
                  top: s.at.dy * p.height - _tap / 2,
                  width: _tap,
                  height: _tap,
                  child: Semantics(
                    button: true,
                    selected: picked == s.id,
                    label: s.name,
                    excludeSemantics: true,
                    child: ClipOval(
                      child: GestureDetector(key: ValueKey('lead-spot-${s.id}'), behavior: HitTestBehavior.opaque, onTap: () => onPick(s.id)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
