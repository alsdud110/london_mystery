import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/investigation.dart' show InvestigationSpot;
import '../../../data/models/mission.dart';
import '../../../data/models/painter_puzzles.dart';
import '../../../data/models/scene_explore.dart' show ScenePixels;
import '../../../widgets/detective_tips.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/letter_card.dart';
import '../../../widgets/paper.dart';
import '../../../widgets/paper_background.dart';
import 'investigation_search.dart' show PencilSlip, SearchTapRing;
import 'question_widgets.dart' show ShakeOnChange;
import 'scene_explore.dart' show LookMark, OverPicture;
import 'search_stage.dart';
import 'spot_differences.dart' show PicturePuzzleActions;
import 'station_clocks.dart' show GuidePulse;
import 'tower_documents.dart' show CroppedPicture;
import 'zoom_picture.dart';

/// A studio looked round, then its notes joined to its paintings
/// ([StudioScene]). The room fills the top of the page (pinch, drag); a
/// small glass marks each place worth a look. A painting found opens up
/// close (kept found: [onFound]); the desk, once every painting is found,
/// gives the notes (the mission's letter). Then MATCH THE NOTES opens the
/// matching page: a note is tapped then its painting tapped, or dragged onto
/// it; CHECK sends the pairs to [onSubmit], checked as the puzzle's answer.
class StudioMatch extends StatefulWidget {
  const StudioMatch({
    super.key,
    required this.scene,
    required this.mission,
    required this.progress,
    required this.onChanged,
    required this.onFound,
    required this.onSubmit,
    required this.hintsShown,
    required this.onHint,
    required this.wrongPulse,
  });

  final StudioScene scene;
  final Mission mission;
  final PicturePuzzleProgress progress;
  final VoidCallback onChanged;
  final ValueChanged<String> onFound;
  final Future<void> Function(String answer) onSubmit;
  final int hintsShown;
  final Future<bool> Function() onHint;
  final int wrongPulse;

  @override
  State<StudioMatch> createState() => _StudioMatchState();
}

class _StudioMatchState extends State<StudioMatch> {
  final _zoom = TransformationController();
  int _reset = 0;
  String? _line;
  Offset? _tapAt;
  int _tapCount = 0;

  PicturePuzzleProgress get _p => widget.progress;
  StudioScene get _scene => widget.scene;

  bool get _allPaintings => _p.allFound([for (final p in _scene.paintings) p.id]);
  bool get _deskRead => _p.has(deskId);

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  void _tap(Offset at, Size shown) {
    if (_p.open != null) return;
    setState(() {
      _tapAt = at;
      _tapCount++;
    });
    final k = ZoomPicture.slack / _zoom.value.getMaxScaleOnAxis();
    _look(_scene.hit(at, slack: Size(k / shown.width, k / shown.height)));
  }

  void _look(Object? target) {
    if (_p.open != null) return;
    switch (target) {
      case StudioPainting p:
        _open(p.id);
      case InvestigationSpot s when identical(s, _scene.desk):
        if (!_allPaintings) {
          setState(() => _line = _scene.deskFirstLine);
        } else {
          _open(deskId);
        }
      case InvestigationSpot o:
        setState(() => _line = o.line);
      default:
        setState(() => _line = _scene.missLine);
    }
  }

  void _open(String id) {
    HapticFeedback.selectionClick();
    // Saved as looked at: a painting or the notes (the matching page is not
    // a thing found).
    if (id != 'match' && _p.found.add(id)) widget.onFound(id);
    _p.open = id;
    _line = null;
    widget.onChanged();
  }

  void _close() {
    if (_p.open == null) return;
    _p.open = null;
    widget.onChanged();
  }

  String get _task => !_allPaintings
      ? _scene.task
      : !_deskRead
      ? _scene.deskTask
      : _scene.matchTask;

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final open = _p.open;
    final found = [for (final p in scene.paintings) if (_p.has(p.id)) p.id].length;
    return Stack(
      children: [
        SearchStage(
          idealHeight: (width) => width * 1.35,
          picture: (context, viewport) => ZoomPicture(
            viewport: viewport,
            pixels: scene.pixels,
            opening: scene.opening,
            controller: _zoom,
            resetCount: _reset,
            builder: (size) => _StudioPicture(
                key: const ValueKey('studio-picture'),
              scene: scene,
              progress: _p,
              size: size,
              tapAt: _tapAt,
              tapCount: _tapCount,
              still: still,
              guideDesk: _allPaintings && !_deskRead,
              onTap: (at) => _tap(at, size),
              onSpot: _look,
            ),
          ),
          note: PencilSlip(line: _line),
          caption: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Semantics(
                    key: ValueKey(_task),
                    liveRegion: true,
                    child: GlossaryText(_task, key: const ValueKey('studio-task'), textAlign: TextAlign.center, style: AppText.task()),
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'Paintings found: $found of ${scene.paintings.length}',
                  key: const ValueKey('studio-count'),
                  style: AppText.tally(),
                ),
                const SizedBox(height: AppSpace.xs),
                Text('Tap a glass to look. Pinch to look closer.', textAlign: TextAlign.center, style: AppText.caption()),
              ],
            ),
          ),
          actions: PicturePuzzleActions(
            hints: widget.mission.hints,
            hintsShown: widget.hintsShown,
            onTip: widget.onHint,
            documentLabel: _deskRead ? 'The Notes' : null,
            onDocument: () => _open(deskId),
            onWhole: () => setState(() => _reset++),
            extra: _deskRead
                ? GameButton(
                    key: const ValueKey('studio-match'),
                    label: 'MATCH THE NOTES',
                    tap: TapRole.primary,
                    arrow: true,
                    onPressed: () => _open('match'),
                  )
                : null,
          ),
        ),
        if (open != null)
          Positioned.fill(
            child: open == deskId
                ? _NotesCard(key: const ValueKey('studio-notes'), mission: widget.mission, still: still, onClose: _close)
                : open == 'match'
                ? _MatchPage(
                    key: const ValueKey('studio-match-page'),
                    scene: scene,
                    mission: widget.mission,
                    progress: _p,
                    wrongPulse: widget.wrongPulse,
                    onChanged: widget.onChanged,
                    onSubmit: widget.onSubmit,
                    hintsShown: widget.hintsShown,
                    onHint: widget.onHint,
                    onClose: _close,
                  )
                : _PaintingCard(key: ValueKey('studio-painting-$open'), painting: scene.painting(open), still: still, onClose: _close),
          ),
      ],
    );
  }
}

/// The room: a glass on each painting's place and on the desk (a tick once
/// looked at), the desk's glass calling once every painting is found, the
/// last tap's ring, and a button for screen readers on every place.
class _StudioPicture extends StatelessWidget {
  const _StudioPicture({
    super.key,
    required this.scene,
    required this.progress,
    required this.size,
    required this.tapAt,
    required this.tapCount,
    required this.still,
    required this.guideDesk,
    required this.onTap,
    required this.onSpot,
  });

  final StudioScene scene;
  final PicturePuzzleProgress progress;
  final Size size;
  final Offset? tapAt;
  final int tapCount;
  final bool still;
  final bool guideDesk;
  final ValueChanged<Offset> onTap;
  final ValueChanged<Object> onSpot;

  static const markSize = 30.0;

  @override
  Widget build(BuildContext context) {
    Widget mark(String id, Offset at, bool looked) => Positioned(
          left: at.dx * size.width - markSize / 2,
          top: at.dy * size.height - markSize / 2,
          child: LookMark(key: ValueKey('mark-$id'), looked: looked),
        );
    Widget button(Rect area, String label, Object target) => Positioned.fromRect(
          rect: placeOn(area, size),
          child: Semantics(button: true, label: label, onTap: () => onSpot(target), child: const SizedBox.expand()),
        );
    final deskAt = Offset(scene.deskMark.dx * size.width, scene.deskMark.dy * size.height);
    return Semantics(
      label: scene.place,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(Offset(d.localPosition.dx / size.width, d.localPosition.dy / size.height)),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(child: Image.asset(scene.picture, fit: BoxFit.fill, excludeFromSemantics: true)),
            for (final p in scene.paintings) mark(p.id, p.mark, progress.has(p.id)),
            if (guideDesk)
              Positioned(
                left: deskAt.dx - GuidePulse.size / 2,
                top: deskAt.dy - GuidePulse.size / 2,
                child: IgnorePointer(
                  child: GuidePulse(
                    key: const ValueKey('desk-guide'),
                    still: still,
                    child: const LookMark(key: ValueKey('mark-desk'), looked: false),
                  ),
                ),
              )
            else
              mark(deskId, scene.deskMark, progress.has(deskId)),
            if (tapAt != null)
              Positioned(
                left: tapAt!.dx * size.width - 22,
                top: tapAt!.dy * size.height - 22,
                child: SearchTapRing(key: ValueKey('tap-$tapCount'), still: still),
              ),
            for (final p in scene.paintings)
              button(p.area, progress.has(p.id) ? '${_placeOf(p)}, looked at' : _placeOf(p), p),
            button(scene.desk.areas.first, scene.desk.label, scene.desk),
            for (final o in scene.others) button(o.areas.first, o.label, o),
          ],
        ),
      ),
    );
  }

  /// Where a painting is put away, for screen readers (its line's start).
  static String _placeOf(StudioPainting p) => p.line.split(':').first;
}

/// A painting found, up close: its own picture whole, and where it was.
class _PaintingCard extends StatelessWidget {
  const _PaintingCard({super.key, required this.painting, required this.still, required this.onClose});

  final StudioPainting painting;
  final bool still;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return OverPicture(
      still: still,
      onTapOutside: onClose,
      child: PaperSheet(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('FOUND', style: AppText.eyebrow()),
              const SizedBox(height: AppSpace.xs),
              GlossaryText(painting.line, textAlign: TextAlign.center, style: AppText.letter(size: 17)),
              const SizedBox(height: AppSpace.md),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: math.min(300, MediaQuery.sizeOf(context).height * 0.42)),
                child: _Framed(
                  child: Semantics(
                    image: true,
                    label: painting.label,
                    child: AspectRatio(
                      aspectRatio: painting.pixels.aspect,
                      child: Image.asset(painting.file, key: ValueKey('painting-${painting.id}'), fit: BoxFit.cover, excludeFromSemantics: true),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              GameButton(
                key: const ValueKey('studio-painting-close'),
                label: 'KEEP LOOKING',
                style: GameButtonStyle.outline,
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The notes on the desk: the mission's letter.
class _NotesCard extends StatelessWidget {
  const _NotesCard({super.key, required this.mission, required this.still, required this.onClose});

  final Mission mission;
  final bool still;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return OverPicture(
      still: still,
      onTapOutside: onClose,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mission.letterIntro, textAlign: TextAlign.center, style: AppText.aside(color: AppColors.paperLight)),
            const SizedBox(height: AppSpace.sm),
            LetterCard(text: mission.letter, textSize: 16, compact: true),
            const SizedBox(height: AppSpace.md),
            GameButton(
              key: const ValueKey('studio-notes-close'),
              label: 'BACK TO THE STUDIO',
              style: GameButtonStyle.glass,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

/// A painting in a thin gilt frame.
class _Framed extends StatelessWidget {
  const _Framed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.paper),
        border: Border.all(color: AppColors.goldDeep, width: AppLine.ink),
        boxShadow: AppShadow.paperLift,
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.paper), child: child),
    );
  }
}

/// The notes, each a block of the letter ("A — I painted this …").
List<(String, String)> notesOf(Mission m) => [
      for (final block in m.letter.split('\n\n'))
        if (block.trim().isNotEmpty) (block.trim()[0].toLowerCase(), block.trim()),
    ];

/// The matching page, over the studio: the paintings in a row (each takes
/// one note), the notes under them, CHECK once every note has a painting.
class _MatchPage extends StatefulWidget {
  const _MatchPage({
    super.key,
    required this.scene,
    required this.mission,
    required this.progress,
    required this.wrongPulse,
    required this.onChanged,
    required this.onSubmit,
    required this.hintsShown,
    required this.onHint,
    required this.onClose,
  });

  final StudioScene scene;
  final Mission mission;
  final PicturePuzzleProgress progress;
  final int wrongPulse;
  final VoidCallback onChanged;
  final Future<void> Function(String answer) onSubmit;
  final int hintsShown;
  final Future<bool> Function() onHint;
  final VoidCallback onClose;

  @override
  State<_MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<_MatchPage> {
  bool _checking = false;

  /// The first note and the first painting: where the opening demo drags
  /// from and to.
  final _demoPage = GlobalKey();
  final _demoNote = GlobalKey();
  final _demoSlot = GlobalKey();
  Timer? _demoWait;
  (Offset, Offset)? _demo;

  PicturePuzzleProgress get _p => widget.progress;

  List<(String, String)> get _notes => notesOf(widget.mission);

  @override
  void initState() {
    super.initState();
    // The page opened for the first time, nothing joined yet: a hand shows
    // a note dragged onto a painting, once the page has come in.
    if (!_p.matchDemoShown && _p.pairs.isEmpty && _p.pickedNote == null) {
      _demoWait = Timer(const Duration(milliseconds: 600), _startDemo);
    }
  }

  @override
  void dispose() {
    _demoWait?.cancel();
    super.dispose();
  }

  void _startDemo() {
    if (!mounted || (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) return;
    final page = _demoPage.currentContext?.findRenderObject();
    final note = _demoNote.currentContext?.findRenderObject();
    final slot = _demoSlot.currentContext?.findRenderObject();
    if (page is! RenderBox || note is! RenderBox || slot is! RenderBox) return;
    // From the note's letter badge to the painting's note box.
    final from = page.globalToLocal(note.localToGlobal(const Offset(AppSpace.md + 13, AppSpace.sm + 13)));
    final to = page.globalToLocal(slot.localToGlobal(Offset(slot.size.width / 2, slot.size.height - AppSpace.xs - 18)));
    // The note out of sight (a short screen): no demo to point at it.
    if (from.dy > page.size.height - 60) return;
    _p.matchDemoShown = true;
    setState(() => _demo = (from, to));
  }

  void _endDemo() {
    _demoWait?.cancel();
    if (_demo != null) setState(() => _demo = null);
  }

  void _pickNote(String id) {
    HapticFeedback.selectionClick();
    _p.pickedNote = _p.pickedNote == id ? null : id;
    widget.onChanged();
  }

  /// [note] joined to [painting]: a painting takes one note, a note one
  /// painting (whatever was there before lets go).
  void _join(String note, String painting) {
    HapticFeedback.lightImpact();
    _p.pairs.removeWhere((n, p) => n == note || p == painting);
    _p.pairs[note] = painting;
    _p.pickedNote = null;
    widget.onChanged();
  }

  void _tapPainting(String painting) {
    final note = _p.pickedNote;
    if (note != null) {
      _join(note, painting);
      return;
    }
    // Nothing picked: a note already here is taken off.
    final here = _p.pairs.entries.where((e) => e.value == painting).map((e) => e.key).firstOrNull;
    if (here != null) {
      _p.pairs.remove(here);
      widget.onChanged();
    }
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await widget.onSubmit(_p.answerOf([for (final (id, _) in _notes) id]));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _lookCloser(StudioPainting p) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: AppColors.navyDeep.withValues(alpha: 0.92),
        pageBuilder: (context, anim, _) => FadeTransition(opacity: anim, child: PictureCloser(file: p.file, aspect: p.pixels.aspect, label: p.label)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final notes = _notes;
    final allPaired = notes.every((n) => _p.pairs.containsKey(n.$1));
    final picked = _p.pickedNote;
    // The one thing to do now: pick a note, then its painting; CHECK once
    // every note has one.
    final (step, stepLine) = picked != null
        ? ('2', scene.matchPainting.replaceAll('{note}', picked.toUpperCase()))
        : allPaired
        ? ('✓', scene.matchDone)
        : ('1', scene.matchHow);
    final demo = _demo;
    // Any touch ends the demo: the detective has taken over.
    return Listener(
      onPointerDown: (_) => _endDemo(),
      child: Stack(
        key: _demoPage,
        children: [
          _page(context, step, stepLine, allPaired, picked),
          if (demo != null)
            Positioned.fill(
              child: _DragDemo(key: const ValueKey('match-demo'), from: demo.$1, to: demo.$2, note: notes.first.$1, onDone: _endDemo),
            ),
        ],
      ),
    );
  }

  Widget _page(BuildContext context, String step, String stepLine, bool allPaired, String? picked) {
    final m = widget.mission;
    final scene = widget.scene;
    final notes = _notes;
    return ColoredBox(
      color: AppColors.paperLight,
      child: InkSurface(
        night: false,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.xs, AppSpace.sm, 0),
                child: Row(
                  children: [
                    IconButton(
                      key: const ValueKey('studio-match-close'),
                      tooltip: 'Back to the studio',
                      onPressed: widget.onClose,
                      icon: const InkIcon(InkGlyph.back, color: AppColors.navy),
                    ),
                    // The question, in the bar: the room below is the
                    // paintings' and the notes'.
                    Expanded(child: GlossaryText(m.question, textAlign: TextAlign.center, style: AppText.subtitle(color: AppColors.navy))),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              // The step and the paintings stay in view; the notes scroll
              // under them, so a note picked and its painting are on the
              // screen together.
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.xs, AppSpace.screen, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: _MatchStep(key: const ValueKey('match-step'), step: step, line: stepLine),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    ShakeOnChange(
                      trigger: widget.wrongPulse,
                      child: LayoutBuilder(
                        builder: (context, box) {
                          const gap = AppSpace.sm;
                          final n = scene.order.length;
                          final tile = (box.maxWidth - gap * (n - 1)) / n;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final (i, id) in scene.order.indexed) ...[
                                if (i > 0) const SizedBox(width: gap),
                                SizedBox(
                                  key: i == 0 ? _demoSlot : null,
                                  width: tile,
                                  child: _PaintingSlot(
                                    key: ValueKey('slot-$id'),
                                    painting: scene.painting(id),
                                    number: i + 1,
                                    note: _p.pairs.entries.where((e) => e.value == id).map((e) => e.key).firstOrNull,
                                    picked: picked,
                                    onTap: () => _tapPainting(id),
                                    onDrop: (note) => _join(note, id),
                                    onCloser: () => _lookCloser(scene.painting(id)),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('THE NOTES', textAlign: TextAlign.center, style: AppText.eyebrow()),
                      const SizedBox(height: AppSpace.xs),
                      for (final (i, (id, text)) in notes.indexed)
                        Padding(
                          key: i == 0 ? _demoNote : null,
                          padding: const EdgeInsets.only(bottom: AppSpace.sm),
                          child: _NoteChip(
                            key: ValueKey('note-$id'),
                            id: id,
                            text: text,
                            picked: picked == id,
                            joinedTo: _p.pairs[id] == null ? null : scene.order.indexOf(_p.pairs[id]!) + 1,
                            onTap: () => _pickNote(id),
                          ),
                        ),
                      Text(scene.matchDrag, textAlign: TextAlign.center, style: AppText.caption(color: AppColors.inkBrown)),
                      const SizedBox(height: AppSpace.md),
                      DetectiveTipNotes(hints: m.hints, revealed: widget.hintsShown, compact: true),
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.gold.withValues(alpha: 0.6), width: AppLine.rule)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.md, AppSpace.screen, AppSpace.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GameButton(
                        key: const ValueKey('studio-check'),
                        label: 'CHECK',
                        tap: TapRole.primary,
                        onPressed: allPaired && !_checking ? _check : null,
                      ),
                      if (nextTipLabel(m.hints, widget.hintsShown) case final tip?)
                        InkTextButton(label: tip, glyph: InkGlyph.hint, color: tipLinkColor, onPressed: widget.onHint),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// How the matching page is played, shown once as it opens: a hand presses
/// on a note's letter, drags it up onto a painting and lets go, twice; then
/// it is gone (at once on any touch, through [onDone]). It never takes a
/// touch and joins nothing.
class _DragDemo extends StatefulWidget {
  const _DragDemo({super.key, required this.from, required this.to, required this.note, required this.onDone});

  /// Where the fingertip presses and lets go, on the page.
  final Offset from;
  final Offset to;

  /// The letter carried.
  final String note;
  final VoidCallback onDone;

  static const loop = Duration(milliseconds: 2400);
  static const loops = 2;

  @override
  State<_DragDemo> createState() => _DragDemoState();
}

class _DragDemoState extends State<_DragDemo> with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(vsync: this, duration: _DragDemo.loop * _DragDemo.loops)
    ..forward().whenComplete(() {
      if (mounted) widget.onDone();
    });

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  /// [t]'s part between [a] and [b], 0 to 1.
  static double _part(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _motion,
        builder: (context, _) {
          // One loop: come in on the note, press, carry it up, let go, fade.
          final t = (_motion.value * _DragDemo.loops) % 1.0;
          final come = _part(t, 0, 0.12);
          final press = _part(t, 0.12, 0.22);
          final carry = Curves.easeInOutCubic.transform(_part(t, 0.22, 0.72));
          final letGo = _part(t, 0.72, 0.80);
          final fade = _part(t, 0.80, 1.0);
          final at = Offset.lerp(widget.from, widget.to, carry)!;
          final hand = come * (1 - fade);
          final carried = press * (1 - letGo);
          final scale = 1 - 0.12 * (press - letGo);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // The note's letter, lifted and carried under the fingertip.
              Positioned(
                left: at.dx - 15,
                top: at.dy - 15,
                child: Opacity(
                  opacity: carried,
                  child: Transform.scale(scale: 1 + 0.15 * carried, child: _NoteBadge(id: widget.note, size: 30)),
                ),
              ),
              Positioned(
                left: at.dx - _InkHand.tip.dx,
                top: at.dy - _InkHand.tip.dy,
                child: Opacity(
                  opacity: hand,
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment(_InkHand.tip.dx / _InkHand.size.width * 2 - 1, _InkHand.tip.dy / _InkHand.size.height * 2 - 1),
                    child: CustomPaint(size: _InkHand.size, painter: const _InkHand()),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A pointing hand in the game's ink: the forefinger up, the paper-white
/// glove outlined in navy, its tip at [tip].
class _InkHand extends CustomPainter {
  const _InkHand();

  /// Drawn on a 24 × 28 grid, shown at [size].
  static const size = Size(34, 40);
  static const _k = 34 / 24;

  /// Where the fingertip is, in [size].
  static const tip = Offset(9 * _k, 2 * _k);

  @override
  void paint(Canvas canvas, Size _) {
    canvas.scale(_k);
    final glove = Path()
      ..moveTo(7, 14.5)
      ..lineTo(7, 3.5)
      ..arcToPoint(const Offset(11, 3.5), radius: const Radius.circular(2))
      ..lineTo(11, 11.5)
      ..arcToPoint(const Offset(14.5, 11.8), radius: const Radius.circular(1.8))
      ..arcToPoint(const Offset(18, 12.6), radius: const Radius.circular(1.8))
      ..quadraticBezierTo(21, 12.8, 21, 15.5)
      ..lineTo(21, 20)
      ..quadraticBezierTo(21, 26, 15.5, 26.5)
      ..lineTo(11.5, 26.5)
      ..quadraticBezierTo(8.5, 26.5, 6.5, 23.5)
      ..lineTo(3.2, 18.3)
      ..quadraticBezierTo(2.5, 16, 4.6, 15.6)
      ..quadraticBezierTo(6, 15.5, 7, 17)
      ..close();
    canvas.drawShadow(glove, AppColors.navyDeep, 2, false);
    canvas.drawPath(glove, Paint()..color = AppColors.paperLight);
    final ink = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(glove, ink);
    // The knuckles between the curled fingers.
    canvas.drawLine(const Offset(14.5, 12.5), const Offset(14.5, 15.5), ink..strokeWidth = 1);
    canvas.drawLine(const Offset(18, 13.2), const Offset(18, 15.8), ink);
  }

  @override
  bool shouldRepaint(_InkHand old) => false;
}

/// What to do now on the matching page: the step's number (1: a note, 2:
/// its painting; ✓: every note has one) and its words.
class _MatchStep extends StatelessWidget {
  const _MatchStep({super.key, required this.step, required this.line});

  final String step;
  final String line;

  @override
  Widget build(BuildContext context) {
    final now = step == '2';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
      decoration: BoxDecoration(
        color: now ? AppColors.goldLight.withValues(alpha: 0.4) : AppColors.parchment.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.paper),
        border: Border.all(color: now ? AppColors.gold : AppLine.faint(0.3), width: now ? AppLine.rule : AppLine.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.navy),
            // (The type has no tick: the ink one.)
            child: step == '✓'
                ? const InkIcon(InkGlyph.check, size: AppIconSize.tiny, color: AppColors.goldLight)
                : Text(step, style: AppText.button(size: 14, color: AppColors.goldLight)),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(child: Text(line, key: const ValueKey('match-step-line'), style: AppText.subtitle(color: AppColors.navy))),
        ],
      ),
    );
  }
}

/// A note's letter in a small round badge: the same on the note and on the
/// painting it is put on.
class _NoteBadge extends StatelessWidget {
  const _NoteBadge({required this.id, this.light = false, this.size = 26});

  final String id;
  final bool light;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: light ? AppColors.goldLight : AppColors.navy,
      ),
      child: Text(id.toUpperCase(), style: AppText.button(size: size * 0.55, color: light ? AppColors.navyDeep : AppColors.goldLight)),
    );
  }
}

/// One painting on the matching page: its picture and number (a tap with a
/// note picked puts the note on it; the glass looks closer), and the note
/// it holds (a tap with none picked takes it off). While a note is picked,
/// every painting calls for it: PUT A HERE.
class _PaintingSlot extends StatelessWidget {
  const _PaintingSlot({
    super.key,
    required this.painting,
    required this.number,
    required this.note,
    required this.picked,
    required this.onTap,
    required this.onDrop,
    required this.onCloser,
  });

  final StudioPainting painting;
  final int number;
  final String? note;

  /// The note picked to be put on a painting, if any.
  final String? picked;
  final VoidCallback onTap;
  final ValueChanged<String> onDrop;
  final VoidCallback onCloser;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, candidates, _) {
        final hovering = candidates.isNotEmpty;
        final held = note;
        final waiting = picked != null;
        final call = hovering || waiting;
        return Semantics(
          button: true,
          label: 'Painting $number: ${painting.label}.'
              '${held == null ? '' : ' Note ${held.toUpperCase()} is on it.'}'
              '${waiting ? ' Tap to put note ${picked!.toUpperCase()} here.' : held == null ? '' : ' Tap to take it off.'}',
          excludeSemantics: true,
          onTap: onTap,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(AppSpace.xs),
              decoration: BoxDecoration(
                color: call ? AppColors.goldLight.withValues(alpha: 0.35) : AppColors.parchment.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.paper),
                border: Border.all(
                  color: call ? AppColors.gold : AppLine.faint(0.25),
                  width: call ? AppLine.ink : AppLine.hairline,
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      _Framed(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Image.asset(painting.file, fit: BoxFit.cover, excludeFromSemantics: true),
                        ),
                      ),
                      // Its number, on the picture's corner.
                      Positioned(
                        left: AppSpace.xs,
                        top: AppSpace.xs,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.paperLight.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(AppRadius.paper),
                          ),
                          child: Text('$number', style: AppText.button(size: 14, color: AppColors.navy)),
                        ),
                      ),
                      // A 32 px brass lens on the frame's top corner (a
                      // fingertip's 44 px to press it), clear of the middle
                      // of the slot, where a note is laid.
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Semantics(
                          button: true,
                          label: 'Look closer at painting $number',
                          child: GestureDetector(
                            key: ValueKey('closer-${painting.id}'),
                            behavior: HitTestBehavior.opaque,
                            onTap: onCloser,
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Center(
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.paperLight.withValues(alpha: 0.92),
                                    border: Border.all(color: AppColors.gold, width: AppLine.rule),
                                  ),
                                  child: const InkIcon(InkGlyph.search, size: AppIconSize.tiny, color: AppColors.burgundy),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  // The note it holds (✕: a tap takes it off), where the
                  // picked note would go, or room for one.
                  Container(
                    key: ValueKey('slot-note-${painting.id}'),
                    height: 36,
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                    decoration: BoxDecoration(
                      color: held != null && !waiting
                          ? AppColors.navy
                          : waiting
                          ? AppColors.paperLight
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.paper),
                      border: Border.all(
                        color: waiting ? AppColors.gold : held == null ? AppColors.inkBrown.withValues(alpha: 0.35) : AppColors.navyDeep,
                        width: waiting ? AppLine.rule : AppLine.hairline,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: waiting
                          ? Text('PUT ${picked!.toUpperCase()} HERE', maxLines: 1, style: AppText.button(size: 14, color: AppColors.burgundy))
                          : held == null
                          ? Text('NOTE ?', maxLines: 1, style: AppText.button(size: 14, color: AppColors.muted))
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _NoteBadge(id: held, light: true, size: 22),
                                const SizedBox(width: AppSpace.xs),
                                const InkIcon(InkGlyph.close, size: AppIconSize.tiny, color: AppColors.goldLight),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One note, to pick (navy and gold-edged once picked; a tap again lets it
/// go) or drag onto its painting: its letter in a badge, its words, and the
/// painting it is on, once joined.
class _NoteChip extends StatelessWidget {
  const _NoteChip({super.key, required this.id, required this.text, required this.picked, required this.joinedTo, required this.onTap});

  final String id;
  final String text;
  final bool picked;
  final int? joinedTo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The letter is in the badge: the words without their "A — ".
    final words = text.replaceFirst(RegExp(r'^[A-Za-z]\s*—\s*'), '');
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
      decoration: BoxDecoration(
        color: picked ? AppColors.navy : AppColors.paperLight,
        borderRadius: BorderRadius.circular(AppRadius.paper),
        border: Border.all(color: picked ? AppColors.gold : AppColors.parchmentDark, width: picked ? AppLine.ink : AppLine.hairline),
        boxShadow: AppShadow.paperLift,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NoteBadge(id: id, light: picked),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            // Plain words: the whole card picks the note (its words are
            // looked up on the notes' card, from the studio).
            child: Text(
              words,
              style: AppText.letter(size: 15, color: picked ? AppColors.paperLight : AppColors.inkBrown),
            ),
          ),
          if (joinedTo != null) ...[
            const SizedBox(width: AppSpace.sm),
            Column(
              children: [
                InkIcon(InkGlyph.frame, size: AppIconSize.tiny, color: picked ? AppColors.goldLight : AppColors.burgundy),
                Text('$joinedTo', style: AppText.subtitle(color: picked ? AppColors.goldLight : AppColors.burgundy)),
              ],
            ),
          ],
        ],
      ),
    );
    return Semantics(
      button: true,
      selected: picked,
      label: '${text.replaceAll('\n', ' ')}${joinedTo == null ? '' : ' On painting $joinedTo.'}',
      excludeSemantics: true,
      onTap: onTap,
      child: Draggable<String>(
        data: id,
        feedback: Material(
          color: Colors.transparent,
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 260), child: Opacity(opacity: 0.9, child: card)),
        ),
        childWhenDragging: Opacity(opacity: 0.4, child: card),
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: card),
      ),
    );
  }
}

/// A picture over the page, whole (or only its part [crop], fractions of a
/// picture [pixels] large), to pinch closer; a tap outside or CLOSE goes
/// back.
class PictureCloser extends StatelessWidget {
  const PictureCloser({super.key, required this.file, required this.aspect, required this.label, this.pixels, this.crop});

  final String file;
  final double aspect;
  final String label;
  final ScenePixels? pixels;
  final Rect? crop;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: aspect,
                    child: ClipRect(
                      child: InteractiveViewer(
                        maxScale: 4,
                        child: Semantics(
                          image: true,
                          label: label,
                          child: switch ((pixels, crop)) {
                            (final p?, final c?) => CroppedPicture(key: const ValueKey('closer-picture'), file: file, pixels: p, crop: c),
                            _ => Image.asset(file, key: const ValueKey('closer-picture'), fit: BoxFit.contain, excludeFromSemantics: true),
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text('Pinch to look closer.', style: AppText.caption(color: AppColors.paperLight)),
              const SizedBox(height: AppSpace.sm),
              GameButton(
                key: const ValueKey('closer-close'),
                label: 'CLOSE',
                style: GameButtonStyle.glass,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
