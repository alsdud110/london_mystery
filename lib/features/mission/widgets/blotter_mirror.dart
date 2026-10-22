import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/mission.dart';
import '../../../data/models/workshop_puzzles.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import 'mark_compare.dart' show WorkshopChoice;
import 'workshop_papers.dart';

/// The writing desk ([BlotterScene]): the blotting paper, its three notes
/// backwards on it; the hand mirror, dragged over it (or set on a note by a
/// tap), shows what is under its glass the right way round, and a note
/// under it counts as read ([onRead]); each note read is written out under
/// the desk with its mark. Once all three are read, the place chosen goes to
/// [onSubmit], checked as the puzzle's answer.
class BlotterMirror extends StatefulWidget {
  const BlotterMirror({super.key, required this.scene, required this.mission, required this.read, required this.onRead, required this.onSubmit});

  final BlotterScene scene;
  final Mission mission;

  /// The notes read so far, by id.
  final Set<String> read;
  final ValueChanged<String> onRead;
  final Future<void> Function(String answer) onSubmit;

  @override
  State<BlotterMirror> createState() => _BlotterMirrorState();
}

class _BlotterMirrorState extends State<BlotterMirror> {
  /// Where the glass's centre is (desk pixels): at first beside the notes.
  late Offset _glass = Offset(widget.scene.blotter.right - widget.scene.glassOnDesk * 0.4, widget.scene.blotter.top + widget.scene.glassOnDesk * 0.2);
  String? _choice;
  bool _checking = false;
  final _picture = GlobalKey();

  BlotterScene get _scene => widget.scene;

  /// The part of the desk shown: the blotter and a little round it.
  Rect get _view {
    final b = _scene.blotter.inflate(28);
    return Rect.fromLTRB(b.left / _scene.pixels.width, b.top / _scene.pixels.height, b.right / _scene.pixels.width, b.bottom / _scene.pixels.height);
  }

  void _moveTo(Offset desk) {
    final b = _scene.blotter;
    final at = Offset(desk.dx.clamp(b.left, b.right), desk.dy.clamp(b.top, b.bottom));
    setState(() => _glass = at);
    for (final n in _scene.notes) {
      if (n.at.contains(at) && !widget.read.contains(n.id)) widget.onRead(n.id);
    }
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
    final all = _scene.notes.every((n) => widget.read.contains(n.id));
    final view = _view;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          all ? _scene.chooseTask : _scene.readTask,
          key: const ValueKey('blotter-task'),
          textAlign: TextAlign.center,
          style: AppText.subtitle(),
        ),
        const SizedBox(height: AppSpace.md),
        DecoratedBox(
          decoration: BoxDecoration(boxShadow: AppShadow.paperLift, borderRadius: BorderRadius.circular(AppRadius.paper)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.paper),
            child: Semantics(
              label: '${_scene.place}. The notes are backwards. Drag the mirror over them to read them.',
              excludeSemantics: true,
              child: LayoutBuilder(
                builder: (context, box) {
                  // Screen points per desk pixel.
                  final scale = box.maxWidth / (view.width * _scene.pixels.width);
                  Offset toDesk(Offset local) => Offset(view.left * _scene.pixels.width, view.top * _scene.pixels.height) + local / scale;
                  // The mirror is taken at once where the finger lands (the
                  // page does not scroll under it), and follows the finger.
                  return RawGestureDetector(
                    key: const ValueKey('blotter'),
                    behavior: HitTestBehavior.opaque,
                    gestures: {
                      TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                        TapGestureRecognizer.new,
                        (r) => r.onTapUp = (d) => _moveTo(toDesk(d.localPosition)),
                      ),
                      ImmediateMultiDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<ImmediateMultiDragGestureRecognizer>(
                        ImmediateMultiDragGestureRecognizer.new,
                        (r) => r.onStart = (global) {
                          final box = _picture.currentContext?.findRenderObject() as RenderBox?;
                          if (box != null) _moveTo(toDesk(box.globalToLocal(global)));
                          return _GlassDrag((d) => _moveTo(_glass + d.delta / scale));
                        },
                      ),
                    },
                    child: CroppedPicture(
                      key: _picture,
                      file: _scene.desk,
                      pixels: _scene.pixels,
                      crop: view,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // The notes as blotted: backwards.
                          for (final n in _scene.notes)
                            Positioned.fromRect(rect: n.at, child: _NoteInk(note: n, mark: _scene.mark, backwards: true)),
                          // Under the glass: the right way round.
                          Positioned.fill(
                            child: ClipPath(
                              clipper: _GlassClipper(_glass, _scene.glassOnDesk),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(_scene.desk, fit: BoxFit.fill, excludeFromSemantics: true),
                                  for (final n in _scene.notes)
                                    Positioned.fromRect(
                                      rect: n.at,
                                      child: _NoteInk(key: ValueKey('mirror-note-${n.id}'), note: n, mark: _scene.mark, backwards: false),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          // The mirror's frame round its glass.
                          _MirrorFrame(scene: _scene, glass: _glass),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        // The notes read, written out with their marks.
        if (widget.read.isNotEmpty) ...[
          Text('THE NOTES YOU READ', textAlign: TextAlign.center, style: AppText.eyebrow()),
          const SizedBox(height: AppSpace.sm),
          for (final n in _scene.notes)
            if (widget.read.contains(n.id)) _NoteRead(note: n, mark: _scene.mark),
          const SizedBox(height: AppSpace.sm),
          // The maker's own mark, to compare (found on the workbench).
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("The maker's own mark:", style: AppText.aside()),
              const SizedBox(width: AppSpace.sm),
              SizedBox.square(dimension: 56, child: MakerMarkView(mark: _scene.mark, copy: MarkCopy.exact, ink: AppColors.walnutDeep)),
            ],
          ),
        ],
        if (all) ...[
          const SizedBox(height: AppSpace.md),
          for (final o in widget.mission.options)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: WorkshopChoice(key: ValueKey('place-${o.id}'), label: o.label, selected: _choice == o.id, onTap: () => setState(() => _choice = o.id)),
            ),
          const SizedBox(height: AppSpace.sm),
          GameButton(
            key: const ValueKey('blotter-check'),
            label: _scene.chooseLabel,
            glyph: InkGlyph.check,
            tap: TapRole.primary,
            onPressed: _choice != null && !_checking ? _check : null,
          ),
        ],
      ],
    );
  }
}

/// The mirror following a finger.
class _GlassDrag extends Drag {
  _GlassDrag(this.onUpdate);

  final ValueChanged<DragUpdateDetails> onUpdate;

  @override
  void update(DragUpdateDetails details) => onUpdate(details);
}

/// A note in its ink, backwards as blotted or the right way round, its
/// mark under it (none, a copy, the maker's own).
class _NoteInk extends StatelessWidget {
  const _NoteInk({super.key, required this.note, required this.mark, required this.backwards});

  final BlotNote note;
  final MakerMark mark;
  final bool backwards;

  @override
  Widget build(BuildContext context) {
    final ink = inkOf(note.ink);
    final words = Row(
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(note.lines.join('\n'), style: handwriting(40, color: ink)),
          ),
        ),
        SizedBox.square(
          dimension: 120,
          child: note.mark == null ? null : MakerMarkView(mark: mark, copy: note.mark!, ink: ink),
        ),
      ],
    );
    return ExcludeSemantics(
      child: Opacity(
        opacity: backwards ? 0.7 : 1,
        child: backwards ? Transform.flip(flipX: true, child: words) : words,
      ),
    );
  }
}

/// The glass of the mirror, a circle at [centre] (desk pixels).
class _GlassClipper extends CustomClipper<Path> {
  const _GlassClipper(this.centre, this.radius);

  final Offset centre;
  final double radius;

  @override
  Path getClip(Size size) => Path()..addOval(Rect.fromCircle(center: centre, radius: radius));

  @override
  bool shouldReclip(_GlassClipper old) => old.centre != centre || old.radius != radius;
}

/// The hand mirror, its glass round [glass] (desk pixels).
class _MirrorFrame extends StatelessWidget {
  const _MirrorFrame({required this.scene, required this.glass});

  final BlotterScene scene;
  final Offset glass;

  @override
  Widget build(BuildContext context) {
    final k = scene.glassOnDesk / scene.glassRadius;
    return Positioned(
      key: const ValueKey('hand-mirror'),
      left: glass.dx - scene.glassCentre.dx * k,
      top: glass.dy - scene.glassCentre.dy * k,
      width: scene.mirrorPixels.width * k,
      height: scene.mirrorPixels.height * k,
      child: IgnorePointer(child: Image.asset(scene.mirror, fit: BoxFit.fill, excludeFromSemantics: true)),
    );
  }
}

/// A note read in the mirror, written out large, its mark beside it.
class _NoteRead extends StatelessWidget {
  const _NoteRead({required this.note, required this.mark});

  final BlotNote note;
  final MakerMark mark;

  @override
  Widget build(BuildContext context) {
    final ink = inkOf(note.ink);
    return Semantics(
      label: '${note.name}: ${note.lines.join(' ')}. ${note.mark == null ? 'No mark.' : 'Signed with two clock hands.'}',
      excludeSemantics: true,
      child: Container(
        key: ValueKey('note-read-${note.id}'),
        margin: const EdgeInsets.only(bottom: AppSpace.sm),
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: AppColors.paperLight,
          border: Border.all(color: AppLine.faint(0.25), width: AppLine.hairline),
          borderRadius: BorderRadius.circular(AppRadius.paper),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note.name, style: AppText.mark(color: ink)),
                  const SizedBox(height: AppSpace.xs),
                  GlossaryText(note.lines.join(' '), style: handwriting(18, color: ink), wordSemantics: false),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            SizedBox.square(
              dimension: 56,
              child: note.mark == null
                  ? Center(child: Text('no mark', style: AppText.caption()))
                  : MakerMarkView(mark: mark, copy: note.mark!, ink: ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// The right place is found: Clock III opened, and what is in it (the torn
/// envelope corner and its receipt, its words large under it), before the
/// story goes on.
class ClockHideaway extends StatelessWidget {
  const ClockHideaway({super.key, required this.scene, required this.onContinue});

  final BlotterScene scene;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: still ? Duration.zero : const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in scene.hideawayLines)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.xs),
              child: Text(line, textAlign: TextAlign.center, style: AppText.subtitle()),
            ),
          const SizedBox(height: AppSpace.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.paper),
                child: Semantics(
                  image: true,
                  label: 'The back of Clock III, opened',
                  excludeSemantics: true,
                  child: AspectRatio(aspectRatio: 1, child: Image.asset(scene.hideawayBack, fit: BoxFit.cover, excludeFromSemantics: true)),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          WrittenPaperView(key: const ValueKey('hideaway-paper'), paper: scene.hideaway),
          const SizedBox(height: AppSpace.md),
          ExcludeSemantics(
            child: Text(
              scene.receipt.join('\n'),
              key: const ValueKey('hideaway-receipt'),
              textAlign: TextAlign.center,
              style: AppText.title(size: 20).copyWith(height: 1.4),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          GameButton(key: const ValueKey('hideaway-continue'), label: 'CONTINUE', arrow: true, tap: TapRole.primary, onPressed: onContinue),
        ],
      ),
    );
  }
}
