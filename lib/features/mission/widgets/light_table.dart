import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/mission.dart';
import '../../../data/models/opera_puzzles.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import 'letter_papers.dart' show postType;
import 'opera_papers.dart';

/// The final's stage, as the final goes: the archive table, its box
/// labelled FILE 3–4; once FILE 3 is laid on it ([placed]), the light table
/// (lit once its light has been on: [lit]); with the solve ([open]), the
/// change itself up close: 3:00 on the patch, 4:00 under it, and the slip's
/// words.
class RecordStage extends StatelessWidget {
  const RecordStage({super.key, required this.scene, required this.open, this.placed = false, this.lit = false});

  final LightTableScene scene;
  final Animation<double> open;
  final bool placed;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final solving = CurvedAnimation(parent: open, curve: const Interval(0.25, 0.75, curve: Curves.easeInOut));
    return Stack(
      fit: StackFit.expand,
      children: [
        if (placed)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(width: scene.tablePixels.width, height: scene.tablePixels.height, child: _TableWithRecord(key: const ValueKey('stage-table'), scene: scene, lit: lit)),
          )
        else
          Semantics(
          image: true,
          label: 'The opera archive: a green box on the long table, its label FILE 3–4',
          excludeSemantics: true,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: scene.archiveView.width,
              height: scene.archiveView.height,
              child: PixelCrop(
                pixels: scene.archivePixels,
                crop: scene.archiveView,
                child: Stack(
                  children: [
                    Positioned.fill(child: Image.asset(scene.archive, fit: BoxFit.fill, excludeFromSemantics: true)),
                    Positioned.fromRect(
                      rect: scene.labelAt,
                      child: FittedBox(fit: BoxFit.scaleDown, child: Text(scene.label, key: const ValueKey('box-label'), style: postType(40, color: AppColors.walnutDeep))),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Built once the solve begins (never seen before it).
        AnimatedBuilder(
          animation: open,
          builder: (context, child) => open.value == 0 ? const SizedBox.shrink() : FadeTransition(opacity: solving, child: child),
          child: IgnorePointer(child: _ChangeUpClose(scene: scene)),
        ),
      ],
    );
  }
}

/// The light table seen whole, FILE 3 lying on its glass ([lit]: the light
/// on).
class _TableWithRecord extends StatelessWidget {
  const _TableWithRecord({super.key, required this.scene, required this.lit});

  final LightTableScene scene;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final g = scene.glass;
    // FILE 3, portrait, in the middle of the glass.
    final h = g.height - 70;
    final w = h * scene.file3.pixels.aspect;
    return Semantics(
      image: true,
      label: lit ? 'FILE 3 on the lit light table: a patch over the curtain up time, 4:00 PM showing under it' : 'The light table, its light off',
      excludeSemantics: true,
      child: Stack(
        children: [
          Positioned.fill(child: Image.asset(lit ? scene.tableOn : scene.table, fit: BoxFit.fill, excludeFromSemantics: true)),
          Positioned(
            left: g.center.dx - w / 2,
            top: g.center.dy - h / 2,
            width: w,
            height: h,
            child: Transform.rotate(angle: -0.02, child: OfficeRecordView(record: scene.file3, lit: lit ? 1 : 0, photo: false, semantics: false)),
          ),
        ],
      ),
    );
  }
}

/// The case solved: FILE 3's lines up close on the lit glass, the patch's
/// 3:00 and the 4:00 under it, and what the slip asked for under them.
class _ChangeUpClose extends StatelessWidget {
  const _ChangeUpClose({required this.scene});

  final LightTableScene scene;

  @override
  Widget build(BuildContext context) {
    final g = scene.glass;
    final glass = Rect.fromCenter(center: g.center, width: g.width * 0.5, height: g.height * 0.6);
    // The three lines of the record, the change among them.
    const lines = Rect.fromLTRB(110, 495, 880, 1000);
    final time = AppText.style(AppText.body, size: 20, weight: FontWeight.w800, color: AppColors.navyDeep);
    return Semantics(
      image: true,
      label: 'FILE 3 on the lit light table: on the patch over CURTAIN UP, 3:00 PM; under it, 4:00 PM. The record was changed from 4:00 to 3:00.',
      excludeSemantics: true,
      child: Stack(
        key: const ValueKey('change-up-close'),
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: glass.width,
              height: glass.height,
              child: PixelCrop(pixels: scene.tablePixels, crop: glass, child: Image.asset(scene.tableOn, fit: BoxFit.fill, excludeFromSemantics: true)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 52),
            child: Center(child: PixelCrop(pixels: scene.file3.pixels, crop: lines, child: OfficeRecordView.canvas(scene.file3, lit: 1, photo: false))),
          ),
          // The slip's change, written out under the record.
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.paperLight,
                  borderRadius: BorderRadius.circular(AppRadius.paper),
                  border: Border.all(color: AppColors.goldDeep, width: AppLine.rule),
                  boxShadow: AppShadow.pinned,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  child: Row(
                    key: const ValueKey('change-tag'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('CURTAIN UP  ', style: AppText.eyebrow(color: AppColors.walnut)),
                      Text('4:00', style: time),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: InkIcon(InkGlyph.arrow, size: 18, color: AppColors.walnut)),
                      Text('3:00', style: time.copyWith(color: AppColors.burgundy)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The final ([LightTableScene]), step by step: which record was changed
/// (FILE 3 or FILE 4 with the cue card); FILE 3 laid on the light table
/// (dragged, or PUT IT ON THE TABLE); its light switched on (the patch's
/// edge and the old time under it show); and the Amendment Slip's two times
/// pinned to the change (dragged, or tapped then a line tapped), a red
/// thread from each. What is done is saved; a wrong choice or pin goes to
/// [onWrong] (checked as part of the answer, said why), the pins right to
/// [onSolve].
class ChangedRecordPuzzle extends StatefulWidget {
  const ChangedRecordPuzzle({
    super.key,
    required this.scene,
    required this.mission,
    required this.chosen,
    required this.placed,
    required this.litSeen,
    required this.pinned,
    required this.checking,
    required this.onChosen,
    required this.onPlaced,
    required this.onLit,
    required this.onPinned,
    required this.onWrong,
    required this.onSolve,
  });

  final LightTableScene scene;
  final Mission mission;
  final bool chosen;
  final bool placed;
  final bool litSeen;

  /// The slip's pins pressed in where they belong.
  final Set<String> pinned;
  final bool checking;
  final VoidCallback onChosen;
  final VoidCallback onPlaced;
  final VoidCallback onLit;
  final ValueChanged<String> onPinned;
  final Future<void> Function(String part) onWrong;
  final Future<void> Function(String answer) onSolve;

  /// What the final asks now, as the page's heading: which record was
  /// changed, then FILE 3 onto the light table, the light, the pins.
  static String headingOf(LightTableScene scene, Mission mission, {required bool chosen, required bool placed, required bool litSeen}) =>
      !chosen
      ? mission.question
      : !placed
      ? 'Lay FILE 3 on the light table.'
      : !litSeen
      ? scene.lightTask
      : scene.pinTask;

  @override
  State<ChangedRecordPuzzle> createState() => _ChangedRecordPuzzleState();
}

class _ChangedRecordPuzzleState extends State<ChangedRecordPuzzle> {
  /// The light, on or off (on again after a restart, once it was on).
  late bool _light = widget.litSeen;

  /// The pin picked by a tap, waiting for a line to be tapped.
  String? _picked;

  /// The slip and FILE 3 together (where a pin dropped is found).
  final _board = GlobalKey();

  LightTableScene get _scene => widget.scene;

  Future<void> _choose(String file) async {
    if (widget.checking) return;
    if (file == _scene.record.changed) {
      widget.onChosen();
    } else {
      await widget.onWrong(ChangedRecord.pickPart(file));
    }
  }

  void _switch() {
    setState(() => _light = !_light);
    if (_light) widget.onLit();
  }

  /// The spot at [px] (pixels of the record), as the light shows it: with
  /// the light off, the old time under the patch is not seen (the patch is).
  RecordSpot? _spotAt(Offset px) {
    for (final p in _scene.pins) {
      if (p.area.contains(px)) return !_light && p.spot == RecordSpot.under ? RecordSpot.patch : p.spot;
    }
    return null;
  }

  Future<void> _press(String pin, RecordSpot spot) async {
    setState(() => _picked = null);
    if (widget.checking || widget.pinned.contains(pin)) return;
    if (ChangedRecord.fits(pin, spot) && (spot != RecordSpot.under || _light)) {
      widget.onPinned(pin);
      final all = {...widget.pinned, pin};
      if (all.containsAll(ChangedRecord.homes.keys)) await widget.onSolve(ChangedRecord.answer);
      return;
    }
    await widget.onWrong(ChangedRecord.partOf(pin, spot, lit: _light));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.chosen) return _choosing();
    if (!widget.placed) return _placing();
    return _onTheGlass();
  }

  // ── Which record was changed? ──────────────────────────────────────────

  Widget _choosing() {
    final s = _scene;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.chooseTask, key: const ValueKey('final-task'), textAlign: TextAlign.center, style: AppText.subtitle()),
        const SizedBox(height: AppSpace.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _RecordCard(
                  key: const ValueKey('record-file3'),
                  title: 'FILE 3',
                  subtitle: 'OFFICE RECORD',
                  line: 'CURTAIN UP · 3:00 PM',
                  picture: AspectRatio(aspectRatio: s.file3.pixels.aspect, child: OfficeRecordView(record: s.file3, semantics: false)),
                  onTap: () => _choose('file3'),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: _RecordCard(
                  key: const ValueKey('record-file4'),
                  title: 'FILE 4',
                  subtitle: 'PROGRAMME + CUE CARD',
                  line: 'CURTAIN UP · 4:00',
                  picture: AspectRatio(
                    aspectRatio: s.file3.pixels.aspect,
                    child: Stack(
                      children: [
                        Positioned(left: 0, top: 0, right: 14, bottom: 26, child: ExcludeSemantics(child: ProgrammeView(page: s.programme))),
                        Positioned(left: 10, right: 0, bottom: 0, child: Transform.rotate(angle: 0.05, child: ExcludeSemantics(child: CueCardView(card: s.cue)))),
                      ],
                    ),
                  ),
                  onTap: () => _choose('file4'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── FILE 3 onto the light table ────────────────────────────────────────

  Widget _placing() {
    final s = _scene;
    final file3 = SizedBox(width: 74, child: AspectRatio(aspectRatio: s.file3.pixels.aspect, child: OfficeRecordView(record: s.file3, semantics: false)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.placeTask, key: const ValueKey('final-task'), textAlign: TextAlign.center, style: AppText.subtitle()),
        const SizedBox(height: AppSpace.md),
        DragTarget<String>(
          onAcceptWithDetails: (_) => widget.onPlaced(),
          builder: (context, offered, _) => Semantics(
            image: true,
            label: 'The light table in the archive, its light off. Its glass is empty.',
            excludeSemantics: true,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.paper),
              child: PixelCrop(
                key: const ValueKey('light-table'),
                pixels: s.tablePixels,
                crop: Offset.zero & Size(s.tablePixels.width, s.tablePixels.height),
                child: Stack(
                  children: [
                    Positioned.fill(child: Image.asset(s.table, fit: BoxFit.fill, excludeFromSemantics: true)),
                    Positioned.fromRect(
                      rect: s.glass.deflate(30),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.goldLight.withValues(alpha: offered.isEmpty ? 0.5 : 1), width: offered.isEmpty ? 8 : 16),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Row(
          children: [
            Draggable<String>(
              data: 'file3',
              feedback: Material(type: MaterialType.transparency, child: Opacity(opacity: 0.9, child: file3)),
              childWhenDragging: Opacity(opacity: 0.3, child: file3),
              child: Semantics(label: 'FILE 3. Drag it onto the light table.', excludeSemantics: true, child: KeyedSubtree(key: const ValueKey('drag-file3'), child: file3)),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: GameButton(
                key: const ValueKey('put-on-table'),
                label: 'PUT IT ON THE TABLE',
                tap: TapRole.primary,
                onPressed: widget.onPlaced,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── On the glass: the light, and the pins ─────────────────────────────

  Widget _onTheGlass() {
    final s = _scene;
    final slip = s.slip;
    final still = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        // The light table: a wooden frame, its brass switch on the frame,
        // and on its glass the slip and FILE 3, side by side on one table.
        const frame = 8.0;
        final width = box.maxWidth - 2 * frame;
        const inset = 8.0;
        final paperWidth = width - 2 * inset;
        final slipK = paperWidth / slip.paper.width;
        final slipHeight = slip.paper.height * slipK;
        const gap = AppSpace.md;
        final recordTop = inset + (widget.litSeen ? slipHeight + gap : 0.0);
        final recordK = paperWidth / s.closeUp.width;
        final recordHeight = s.closeUp.height * recordK;
        final boardHeight = recordTop + recordHeight + inset;

        Offset onSlip(Rect r) => const Offset(inset, inset) + (r.center - slip.paper.topLeft) * slipK;
        Offset onRecord(Offset px) => Offset(inset, recordTop) + (px - s.closeUp.topLeft) * recordK;
        Offset toRecord(Offset local) => (local - Offset(inset, recordTop)) / recordK + s.closeUp.topLeft;

        final pins = {ChangedRecord.oldPin: slip.oldAt, ChangedRecord.newPin: slip.newAt};
        final times = {ChangedRecord.oldPin: slip.oldTime, ChangedRecord.newPin: slip.newTime};

        final board = TweenAnimationBuilder<double>(
          tween: Tween(end: _light ? 1 : 0),
          duration: still ? Duration.zero : const Duration(milliseconds: 450),
          curve: Curves.easeOut,
          builder: (context, t, _) => SizedBox(
            key: _board,
            height: boardHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // The frosted glass, lit from under as the light comes on.
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: _GlassTop(scene: s, lit: t),
                  ),
                ),
                if (widget.litSeen)
                  Positioned(
                    left: inset,
                    top: inset,
                    width: paperWidth,
                    height: slipHeight,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(boxShadow: _onGlass),
                      child: AmendmentSlipView(key: const ValueKey('board-slip'), slip: slip, times: false),
                    ),
                  ),
                // FILE 3 lying on the glass.
                Positioned(
                  left: inset,
                  top: recordTop,
                  width: paperWidth,
                  height: recordHeight,
                  child: DragTarget<String>(
                    onAcceptWithDetails: (d) {
                      final box = _board.currentContext?.findRenderObject() as RenderBox?;
                      if (box == null) return;
                      final spot = _spotAt(toRecord(box.globalToLocal(d.offset)));
                      if (spot != null) _press(d.data, spot);
                    },
                    builder: (context, _, _) => GestureDetector(
                      key: const ValueKey('record-glass'),
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (d) {
                        final pin = _picked;
                        if (pin == null) return;
                        final spot = _spotAt(toRecord(d.localPosition + Offset(inset, recordTop)));
                        if (spot != null) _press(pin, spot);
                      },
                      child: DecoratedBox(
                        decoration: const BoxDecoration(boxShadow: _onGlass),
                        child: Semantics(
                          image: true,
                          label: [
                            'FILE 3 on the light table, the light ${_light ? 'on' : 'off'}.',
                            for (final r in s.file3.rows) '${r.label.replaceAll(' ·', '')} ${r.time}.',
                            if (_light) 'A patch is glued over CURTAIN UP. On it: ${s.file3.patch.newTime}. Under it: ${s.file3.patch.oldTime}.',
                          ].join(' '),
                          excludeSemantics: true,
                          child: PixelCrop(
                            key: const ValueKey('record-close-up'),
                            pixels: s.file3.pixels,
                            crop: s.closeUp,
                            child: OfficeRecordView.canvas(s.file3, lit: t, photo: false),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // The red threads, from each pin on the slip to where it went.
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      // Each thread off the slip, down past its edge, along
                      // the glass beside the papers (never over the record's
                      // words), and in to its pin between the lines.
                      painter: _Threads([
                        for (final (i, pin) in widget.pinned.indexed)
                          [
                            onSlip(pins[pin]!),
                            Offset(onSlip(pins[pin]!).dx, inset + slipHeight + gap / 2 + (i - 0.5) * 3),
                            for (final (j, p) in s.pin(ChangedRecord.homes[pin]!).threadOn(s.closeUp.left).indexed)
                              if (j == 0) ...[
                                Offset(inset / 2 + (i - 0.5) * 3, inset + slipHeight + gap / 2 + (i - 0.5) * 3),
                                Offset(inset / 2 + (i - 0.5) * 3, onRecord(p).dy),
                              ] else
                                onRecord(p),
                          ],
                      ]),
                    ),
                  ),
                ),
                if (widget.litSeen)
                  for (final MapEntry(key: pin, value: at) in pins.entries)
                    _PinChip(
                      key: ValueKey('pin-$pin'),
                      pin: pin,
                      time: times[pin]!,
                      centre: onSlip(at),
                      pinned: widget.pinned.contains(pin),
                      picked: _picked == pin,
                      onTap: () => setState(() => _picked = _picked == pin ? null : pin),
                    ),
              ],
            ),
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The step itself is the page's heading ([headingOf]).
            if (widget.litSeen) ...[
              Text(
                _picked == null ? 'Drag a time onto FILE 3, or tap a time, then a line.' : 'Now tap the line on FILE 3.',
                key: const ValueKey('pin-help'),
                textAlign: TextAlign.center,
                style: AppText.caption(color: AppColors.paperLight.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: AppSpace.sm),
            ],
            // The table: its frame, the switch on it, the glass.
            DecoratedBox(
              key: const ValueKey('light-table-frame'),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4A3424), Color(0xFF2E2016)]),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.goldDeep.withValues(alpha: 0.7)),
                boxShadow: AppShadow.onNight,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(frame, 4, frame, frame),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Switch(scene: s, on: _light, onTap: _switch),
                    const SizedBox(height: 4),
                    board,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A record to choose: its picture, its name and what it says of the
/// start.
class _RecordCard extends StatelessWidget {
  const _RecordCard({super.key, required this.title, required this.subtitle, required this.line, required this.picture, required this.onTap});

  final String title;
  final String subtitle;
  final String line;
  final Widget picture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$title, $subtitle. $line. Tap if this record was changed.',
    excludeSemantics: true,
    child: Material(
      color: AppColors.paperLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.paper),
        side: const BorderSide(color: AppColors.gold, width: AppLine.rule),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.sm),
          child: Column(
            children: [
              SizedBox(height: 120, child: Center(child: picture)),
              const SizedBox(height: AppSpace.sm),
              Text(title, style: AppText.title(size: 20)),
              Text(subtitle, textAlign: TextAlign.center, style: AppText.eyebrow()),
              const SizedBox(height: AppSpace.xs),
              Text(line, textAlign: TextAlign.center, style: AppText.bodyText(size: 14, weight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Paper lying on the glass: a soft, low shadow.
const _onGlass = [BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(1, 3))];

/// The light table's frosted glass (its middle, from the table's own
/// picture): dim, then lit from under as [lit] goes to 1.
class _GlassTop extends StatelessWidget {
  const _GlassTop({required this.scene, required this.lit});

  final LightTableScene scene;
  final double lit;

  @override
  Widget build(BuildContext context) {
    final g = scene.glass;
    final glass = Rect.fromCenter(center: g.center, width: g.width * 0.5, height: g.height * 0.6);
    return Stack(
      fit: StackFit.expand,
      children: [
        _part(scene.table, glass),
        if (lit > 0) Opacity(opacity: lit, child: _part(scene.tableOn, glass)),
      ],
    );
  }

  Widget _part(String file, Rect part) => FittedBox(
    fit: BoxFit.cover,
    child: SizedBox(
      width: part.width,
      height: part.height,
      child: PixelCrop(pixels: scene.tablePixels, crop: part, child: Image.asset(file, fit: BoxFit.fill, excludeFromSemantics: true)),
    ),
  );
}

/// The table's brass switch, on its wooden frame: down off, up on (the
/// switch itself, from the table's picture), and what it does beside it.
class _Switch extends StatelessWidget {
  const _Switch({required this.scene, required this.on, required this.onTap});

  final LightTableScene scene;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = scene.switchAt;
    return Semantics(
      button: true,
      toggled: on,
      label: "The light table's brass switch",
      hint: on ? 'Tap to turn the light off.' : 'Tap to turn the light on.',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const ValueKey('light-switch'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                // The switch, glowing a little when on.
                Container(
                  width: 44,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: on ? AppColors.goldLight : AppColors.goldDeep.withValues(alpha: 0.6), width: on ? 2 : 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: PixelCrop(pixels: scene.tablePixels, crop: r, child: Image.asset(on ? scene.tableOn : scene.table, fit: BoxFit.fill, excludeFromSemantics: true)),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(on ? 'THE LIGHT IS ON' : 'THE LIGHT IS OFF', key: const ValueKey('light-state'), style: AppText.eyebrow(color: on ? AppColors.goldLight : AppColors.parchmentDark)),
                      const SizedBox(height: 2),
                      Text(on ? 'Tap the switch to turn it off.' : 'Tap the brass switch.', style: AppText.bodyText(size: 15, weight: FontWeight.w600, color: AppColors.paperLight)),
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

/// One of the slip's times: a pin to drag onto FILE 3, or to tap and then
/// a line. Pressed in, it stays on the slip, its thread going to FILE 3.
class _PinChip extends StatefulWidget {
  const _PinChip({super.key, required this.pin, required this.time, required this.centre, required this.pinned, required this.picked, required this.onTap});

  final String pin;
  final String time;
  final Offset centre;
  final bool pinned;
  final bool picked;
  final VoidCallback onTap;

  static const size = Size(76, 50);

  @override
  State<_PinChip> createState() => _PinChipState();
}

class _PinChipState extends State<_PinChip> {
  String get pin => widget.pin;
  String get time => widget.time;
  bool get pinned => widget.pinned;
  bool get picked => widget.picked;
  static const size = _PinChip.size;

  Widget _face({bool lifted = false}) => Container(
    width: size.width,
    height: size.height,
    // A little paper tag on the slip, a brass-headed pin through it.
    decoration: BoxDecoration(
      color: const Color(0xFFF1E6CC),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: picked ? AppColors.burgundy : pinned ? AppColors.success : AppColors.goldDeep, width: picked ? 3 : 1.5),
      boxShadow: picked || lifted ? AppShadow.pinned : const [BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1))],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pressed in: a tick where its pin head was.
        if (pinned)
          const InkIcon(InkGlyph.check, size: 16, color: AppColors.success)
        else
          Container(
            width: 13,
            height: 13,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(center: Alignment(-0.4, -0.4), colors: [Color(0xFFD9886F), AppColors.burgundy, Color(0xFF4A1A1A)], stops: [0, 0.55, 1]),
            ),
          ),
        const SizedBox(width: 6),
        Text(time, style: AppText.style(AppText.body, size: 18, weight: FontWeight.w800, color: AppColors.navyDeep)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final chip = pinned
        ? _face()
        : Draggable<String>(
            data: pin,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            feedback: Material(
              type: MaterialType.transparency,
              child: Transform.translate(offset: Offset(-size.width / 2, -size.height / 2), child: _face(lifted: true)),
            ),
            childWhenDragging: Opacity(opacity: 0.35, child: _face()),
            // A drag starts once the finger moves: a tap stays a tap.
            child: GestureDetector(onTap: widget.onTap, child: _face()),
          );
    return Positioned(
      left: widget.centre.dx - size.width / 2,
      top: widget.centre.dy - size.height / 2,
      width: size.width,
      height: size.height,
      child: Semantics(
        button: true,
        selected: picked,
        label: pinned ? '$time on the slip, pinned to FILE 3.' : '$time on the slip. Drag it onto FILE 3, or tap it, then tap a line.',
        excludeSemantics: true,
        child: chip,
      ),
    );
  }
}

/// The red threads, slip to FILE 3, each with its pin's head.
class _Threads extends CustomPainter {
  _Threads(this.threads);

  /// Each thread's way, from its pin on the slip to its pin on FILE 3.
  final List<List<Offset>> threads;

  @override
  void paint(Canvas canvas, Size size) {
    final thread = Paint()
      ..color = AppColors.burgundy
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final way in threads) {
      canvas.drawPath(_rounded(way, 7), thread);
      final to = way.last;
      canvas.drawCircle(to, 7, Paint()..color = AppColors.burgundy);
      canvas.drawCircle(to + const Offset(-2, -2), 2.2, Paint()..color = const Color(0xFFF2C9C0));
    }
  }

  /// [way] as a thread pulled round pins: straight runs, its corners
  /// rounded by [r].
  static Path _rounded(List<Offset> way, double r) {
    final path = Path()..moveTo(way.first.dx, way.first.dy);
    for (var i = 1; i < way.length - 1; i++) {
      final p = way[i];
      final inLen = (p - way[i - 1]).distance;
      final outLen = (way[i + 1] - p).distance;
      if (inLen == 0 || outLen == 0) continue;
      final k = math.min(r, math.min(inLen, outLen) / 2);
      final a = p - (p - way[i - 1]) / inLen * k;
      final b = p + (way[i + 1] - p) / outLen * k;
      path
        ..lineTo(a.dx, a.dy)
        ..quadraticBezierTo(p.dx, p.dy, b.dx, b.dy);
    }
    return path..lineTo(way.last.dx, way.last.dy);
  }

  @override
  bool shouldRepaint(_Threads old) => '${old.threads}' != '$threads';
}

/// The back of the slip, turned over once the case is solved.
Future<void> showSlipBack(BuildContext context, {required LightTableScene scene}) => showOperaCloser<void>(
  context,
  title: 'THE BACK OF THE SLIP',
  closeLabel: 'BACK TO THE TABLE',
  closeKey: const ValueKey('slip-back-done'),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AmendmentSlipView(key: const ValueKey('slip-back'), slip: scene.slip, back: true),
      const SizedBox(height: AppSpace.md),
      Text('THE METRO SIGN, CLOSER', style: AppText.eyebrow(color: AppColors.goldLight)),
      const SizedBox(height: AppSpace.xs),
      SizedBox(height: 150, child: SlipSignCloser(back: scene.slip.back)),
    ],
  ),
);
