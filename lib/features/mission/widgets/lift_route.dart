import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/mission.dart';
import '../../../data/models/tower_puzzles.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import 'tower_documents.dart';

/// The lift ([LiftScene]): its picture, the route plate and the log on its
/// walls, each looked at closer by a tap (kept read: [onRead]). Once both
/// are read, the missing stop is chosen and CHECK sends it to [onSubmit],
/// checked as the puzzle's answer. The log alone never tells: its S is
/// explained only on the plate, and only the plate shows the service route.
class LiftRoute extends StatefulWidget {
  const LiftRoute({
    super.key,
    required this.scene,
    required this.mission,
    required this.progress,
    required this.read,
    required this.onRead,
    required this.onChanged,
    required this.onSubmit,
  });

  final LiftScene scene;
  final Mission mission;
  final TowerPuzzleProgress progress;
  final Set<String> read;
  final ValueChanged<String> onRead;
  final VoidCallback onChanged;
  final Future<void> Function(String answer) onSubmit;

  @override
  State<LiftRoute> createState() => _LiftRouteState();
}

class _LiftRouteState extends State<LiftRoute> {
  bool _checking = false;

  LiftScene get _scene => widget.scene;
  bool get _bothRead => widget.read.contains(LiftScene.plateId) && widget.read.contains(LiftScene.logId);

  /// The option picked (kept on the page while it is open).
  String? get _choice => widget.progress.picked['stop'];

  Future<void> _open(String id) async {
    widget.onRead(id);
    final plate = id == LiftScene.plateId;
    await showDocumentCloser(
      context,
      title: plate ? 'THE ROUTE PLATE' : 'THE LIFT LOG',
      aspect: plate ? _scene.platePixels.aspect : _scene.logAspect,
      child: plate ? RoutePlate(scene: _scene) : LiftLogPage(scene: _scene),
    );
  }

  void _pick(String id) {
    widget.progress.picked['stop'] = id;
    widget.onChanged();
  }

  Future<void> _check() async {
    if (_checking || _choice == null) return;
    setState(() => _checking = true);
    try {
      await widget.onSubmit(_choice!);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final readPlate = widget.read.contains(LiftScene.plateId);
    final readLog = widget.read.contains(LiftScene.logId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _bothRead ? _scene.chooseTask : _scene.readTask,
          key: const ValueKey('lift-task'),
          textAlign: TextAlign.center,
          style: AppText.task(),
        ),
        const SizedBox(height: AppSpace.md),
        // The lift, its plate and its log marked where they hang.
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
                        label: _scene.place,
                        excludeSemantics: true,
                        child: Image.asset(_scene.picture, fit: BoxFit.fill, excludeFromSemantics: true),
                      ),
                    ),
                    for (final (id, area, name, read) in [
                      (LiftScene.plateId, _scene.plateArea, 'The route plate', readPlate),
                      (LiftScene.logId, _scene.logArea, 'The lift log', readLog),
                    ])
                      Positioned(
                        left: area.left * box.maxWidth,
                        top: area.top * box.maxHeight,
                        width: area.width * box.maxWidth,
                        height: area.height * box.maxHeight,
                        child: _WallSpot(key: ValueKey('lift-spot-$id'), name: name, read: read, onTap: () => _open(id)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        // The two again, without hunting for them on the picture.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpace.sm,
          children: [
            InkTextButton(label: 'Route plate', glyph: readPlate ? InkGlyph.check : InkGlyph.map, onPressed: () => _open(LiftScene.plateId)),
            InkTextButton(label: 'Lift log', glyph: readLog ? InkGlyph.check : InkGlyph.notebook, onPressed: () => _open(LiftScene.logId)),
          ],
        ),
        if (_bothRead) ...[
          const SizedBox(height: AppSpace.md),
          // The trip the question is about, as the log has it.
          for (final t in _scene.trips.where((t) => t.service))
            Semantics(
              label: '${t.time}: ${t.from} to a stop not written, marked S',
              excludeSemantics: true,
              child: Row(
                key: const ValueKey('lift-question-trip'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t.time, style: paperInk(size: 20, weight: FontWeight.w700)),
                  const SizedBox(width: AppSpace.md),
                  Text(t.from.toUpperCase(), style: paperInk(size: 20, weight: FontWeight.w700)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpace.sm),
                    child: InkIcon(InkGlyph.arrow, size: AppIconSize.small, color: AppColors.ink),
                  ),
                  Text(t.to.toUpperCase(), style: paperInk(size: 20, weight: FontWeight.w700)),
                  const SizedBox(width: AppSpace.md),
                  Text('(S)', style: paperInk(size: 20, weight: FontWeight.w700, color: AppColors.burgundy)),
                ],
              ),
            ),
          const SizedBox(height: AppSpace.sm),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpace.sm,
            crossAxisSpacing: AppSpace.sm,
            childAspectRatio: 3.2,
            children: [
              for (final o in widget.mission.options)
                _StopChoice(
                  key: ValueKey('stop-${o.id}'),
                  label: o.label,
                  selected: _choice == o.id,
                  onTap: () => _pick(o.id),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          GameButton(
            key: const ValueKey('lift-check'),
            label: 'CHECK',
            glyph: InkGlyph.check,
            tap: TapRole.primary,
            onPressed: _choice != null && !_checking ? _check : null,
          ),
        ],
      ],
    );
  }
}

/// A thing on the lift's wall worth a look: a fine gold frame round it, a
/// glass until it is read, a tick after.
class _WallSpot extends StatelessWidget {
  const _WallSpot({super.key, required this.name, required this.read, required this.onTap});

  final String name;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$name${read ? ', read' : ''}. Tap to look closer.',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.goldLight.withValues(alpha: read ? 0.45 : 0.9), width: AppLine.rule),
            borderRadius: BorderRadius.circular(AppRadius.paper),
          ),
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.xs),
              child: CircleAvatar(
                radius: 13,
                backgroundColor: AppColors.navyDeep.withValues(alpha: 0.8),
                child: InkIcon(read ? InkGlyph.check : InkGlyph.search, size: AppIconSize.tiny, color: AppColors.goldLight),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StopChoice extends StatelessWidget {
  const _StopChoice({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
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
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                child: Text(
                  label.toUpperCase(),
                  style: AppText.button(size: 15, color: selected ? AppColors.paperLight : AppColors.navy),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The route plate, its stops named: the passenger route drawn whole
/// between its studs, the service run dashed and marked S, the legend
/// lettered under the tower.
class RoutePlate extends StatelessWidget {
  const RoutePlate({super.key, required this.scene});

  final LiftScene scene;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'The route plate. The passenger route stops at '
          '${[for (final id in scene.passengerRoute) scene.stop(id).name].join(', ')}. '
          'The service run goes from ${[for (final id in scene.serviceRoute) scene.stop(id).name].join(' to ')}. '
          '${scene.legend}.',
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: scene.platePixels.aspect,
        child: LayoutBuilder(
          builder: (context, box) {
            final size = box.biggest;
            final unit = size.width / 20;
            Offset at(Offset f) => Offset(f.dx * size.width, f.dy * size.height);
            return Stack(
              children: [
                Positioned.fill(child: Image.asset(scene.plate, fit: BoxFit.fill, excludeFromSemantics: true)),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RoutePainter(
                      passenger: [for (final id in scene.passengerRoute) at(scene.stop(id).at)],
                      service: [for (final id in scene.serviceRoute) at(scene.stop(id).at)],
                      width: unit * 0.28,
                      stud: unit * 0.95,
                    ),
                  ),
                ),
                // The S on the service run, by its middle.
                if (scene.serviceRoute.length >= 2)
                  Builder(
                    builder: (context) {
                      final a = at(scene.stop(scene.serviceRoute.first).at);
                      final b = at(scene.stop(scene.serviceRoute.last).at);
                      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
                      return Positioned(
                        left: mid.dx - unit * 0.7,
                        top: mid.dy - unit * 2.2,
                        child: _PlateTag(text: 'S', unit: unit, service: true),
                      );
                    },
                  ),
                for (final s in scene.stops)
                  Positioned(
                    // Passenger stops named to the left of the tower; the
                    // service stop under its own stud, at the right.
                    left: s.service ? at(s.at).dx - unit * 3.6 : null,
                    right: s.service ? null : size.width - at(s.at).dx + unit * 1.3,
                    top: s.service ? at(s.at).dy + unit * 1.1 : at(s.at).dy - unit * 0.75,
                    child: _PlateTag(key: ValueKey('stop-name-${s.id}'), text: s.name, unit: unit, service: s.service),
                  ),
                Positioned(
                  left: scene.legendAt.left * size.width,
                  top: scene.legendAt.top * size.height,
                  width: scene.legendAt.width * size.width,
                  height: scene.legendAt.height * size.height,
                  // Each route's line, as drawn above, and what it is.
                  child: FittedBox(
                    key: const ValueKey('plate-legend'),
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LegendRow(unit: unit, color: AppColors.navy, dashed: false, text: 'PASSENGER ROUTE'),
                        SizedBox(height: unit * 0.2),
                        _LegendRow(unit: unit, color: AppColors.burgundy, dashed: true, text: scene.legend),
                      ],
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

/// One line of the plate's legend: a stroke of the route's line, its name.
class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.unit, required this.color, required this.dashed, required this.text});

  final double unit;
  final Color color;
  final bool dashed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: unit * 0.35, vertical: unit * 0.1),
      decoration: BoxDecoration(
        color: AppColors.paperLight.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.paper),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: unit * 2,
            height: unit * 0.6,
            child: CustomPaint(
              painter: _RoutePainter(
                passenger: dashed ? const [] : [Offset(0, unit * 0.3), Offset(unit * 2, unit * 0.3)],
                service: dashed ? [Offset(0, unit * 0.3), Offset(unit * 2, unit * 0.3)] : const [],
                width: unit * 0.28,
                stud: 0.01,
              ),
            ),
          ),
          SizedBox(width: unit * 0.4),
          GlossaryText(text, style: paperInk(size: unit * 0.8, weight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

/// A name lettered on the plate: dark ink on a small paper label (the
/// service stop's in the run's colour).
class _PlateTag extends StatelessWidget {
  const _PlateTag({super.key, required this.text, required this.unit, this.service = false});

  final String text;
  final double unit;
  final bool service;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: unit * 0.35, vertical: unit * 0.12),
      decoration: BoxDecoration(
        color: AppColors.paperLight.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.paper),
        border: Border.all(color: service ? AppColors.burgundy : AppColors.walnut, width: AppLine.hairline),
      ),
      child: Text(text, style: paperInk(size: unit * 0.78, weight: FontWeight.w800, color: service ? AppColors.burgundy : AppColors.ink)),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.passenger, required this.service, required this.width, required this.stud});

  final List<Offset> passenger;
  final List<Offset> service;
  final double width;
  final double stud;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.navy
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    // The passenger route, stud to stud (stopping short of each stud).
    for (var i = 0; i + 1 < passenger.length; i++) {
      _segment(canvas, passenger[i], passenger[i + 1], line);
    }
    // The service run, dashed.
    final dash = Paint()
      ..color = AppColors.burgundy
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i + 1 < service.length; i++) {
      final a = service[i], b = service[i + 1];
      final d = b - a;
      final length = d.distance;
      if (length <= stud * 2) continue;
      final dir = d / length;
      for (var t = stud; t < length - stud; t += width * 4) {
        final end = (t + width * 2).clamp(0.0, length - stud);
        canvas.drawLine(a + dir * t, a + dir * end, dash);
      }
    }
  }

  void _segment(Canvas canvas, Offset a, Offset b, Paint paint) {
    final d = b - a;
    final length = d.distance;
    if (length <= stud * 2) return;
    final dir = d / length;
    canvas.drawLine(a + dir * stud, b - dir * stud, paint);
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.passenger != passenger || old.service != service || old.width != width;
}

/// The lift log's page: its trips written on the ledger's left page, the
/// stop not written as ?, the service run marked S.
class LiftLogPage extends StatelessWidget {
  const LiftLogPage({super.key, required this.scene});

  final LiftScene scene;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: '${scene.logTitle}. ${[
        for (final t in scene.trips) '${t.time}: ${t.from} to ${t.to == '?' ? 'not written' : t.to}${t.service ? ', marked S' : ''}'
      ].join('. ')}.',
      excludeSemantics: true,
      child: CroppedPicture(
        file: scene.log,
        pixels: scene.logPixels,
        crop: scene.logCrop,
        overlayAt: scene.logWriteInCrop,
        overlay: LayoutBuilder(
          builder: (context, box) {
            final unit = box.maxWidth / 12;
            final ink = paperInk(size: unit * 0.78);
            final unknown = paperInk(size: unit * 0.78, color: AppColors.burgundy, weight: FontWeight.w800);
            TextSpan place(String p) => TextSpan(text: p, style: p == '?' ? unknown : ink);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: unit * 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: box.maxHeight * 0.1,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(scene.logTitle, style: paperInk(size: unit * 0.8, weight: FontWeight.w800)),
                    ),
                  ),
                  SizedBox(height: box.maxHeight * 0.05),
                  for (final t in scene.trips)
                    SizedBox(
                      height: box.maxHeight * 0.12,
                      child: Row(
                        children: [
                          SizedBox(
                            width: unit * 2.4,
                            child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(t.time, style: ink)),
                          ),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text.rich(TextSpan(children: [
                                place(t.from),
                                // The ink arrow (the type has no arrow glyph).
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: unit * 0.35),
                                    child: InkIcon(InkGlyph.arrow, size: unit * 0.75, color: AppColors.ink),
                                  ),
                                ),
                                place(t.to),
                              ])),
                            ),
                          ),
                          SizedBox(
                            width: unit * 1.2,
                            child: t.service
                                ? Center(
                                    child: Container(
                                      key: const ValueKey('log-service-mark'),
                                      padding: EdgeInsets.all(unit * 0.08),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.burgundy, width: AppLine.rule),
                                      ),
                                      child: Text('S', style: paperInk(size: unit * 0.7, weight: FontWeight.w800, color: AppColors.burgundy)),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
