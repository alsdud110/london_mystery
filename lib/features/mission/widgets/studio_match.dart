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
                    child: GlossaryText(_task, key: const ValueKey('studio-task'), textAlign: TextAlign.center, style: AppText.title(size: 19)),
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'Paintings found: $found of ${scene.paintings.length}',
                  key: const ValueKey('studio-count'),
                  style: AppText.mark(color: AppColors.burgundy, size: 14),
                ),
                const SizedBox(height: 2),
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
        border: Border.all(color: AppColors.goldDeep, width: AppLine.rule + 1),
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

  PicturePuzzleProgress get _p => widget.progress;

  List<(String, String)> get _notes => notesOf(widget.mission);

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
    final m = widget.mission;
    final scene = widget.scene;
    final notes = _notes;
    final allPaired = notes.every((n) => _p.pairs.containsKey(n.$1));
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
                    Expanded(child: Text('THE NOTES AND THE PAINTINGS', textAlign: TextAlign.center, style: AppText.eyebrow())),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.lg),
                  child: Column(
                    children: [
                      GlossaryText(m.question, textAlign: TextAlign.center, style: AppText.title(size: 21)),
                      const SizedBox(height: AppSpace.xs),
                      Text(scene.matchHow, textAlign: TextAlign.center, style: AppText.caption(color: AppColors.inkBrown)),
                      const SizedBox(height: AppSpace.md),
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
                                    width: tile,
                                    child: _PaintingSlot(
                                      key: ValueKey('slot-$id'),
                                      painting: scene.painting(id),
                                      number: i + 1,
                                      note: _p.pairs.entries.where((e) => e.value == id).map((e) => e.key).firstOrNull,
                                      waiting: _p.pickedNote != null,
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
                      const SizedBox(height: AppSpace.lg),
                      for (final (id, text) in notes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.sm),
                          child: _NoteChip(
                            key: ValueKey('note-$id'),
                            id: id,
                            text: text,
                            picked: _p.pickedNote == id,
                            joinedTo: _p.pairs[id] == null ? null : scene.order.indexOf(_p.pairs[id]!) + 1,
                            onTap: () => _pickNote(id),
                          ),
                        ),
                      const SizedBox(height: AppSpace.sm),
                      DetectiveTipNotes(hints: m.hints, revealed: widget.hintsShown, compact: true),
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.goldLight.withValues(alpha: 0.7), width: AppLine.rule)),
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

/// One painting on the matching page: its picture (a tap with a note picked
/// joins them; the glass looks closer), its number, and the note it holds.
class _PaintingSlot extends StatelessWidget {
  const _PaintingSlot({
    super.key,
    required this.painting,
    required this.number,
    required this.note,
    required this.waiting,
    required this.onTap,
    required this.onDrop,
    required this.onCloser,
  });

  final StudioPainting painting;
  final int number;
  final String? note;
  final bool waiting;
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
        return Semantics(
          button: true,
          label: 'Painting $number: ${painting.label}.${held == null ? '' : ' Note ${held.toUpperCase()} is on it.'}',
          excludeSemantics: true,
          onTap: onTap,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(AppSpace.xs),
              decoration: BoxDecoration(
                color: hovering ? AppColors.goldLight.withValues(alpha: 0.35) : AppColors.parchment.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.paper),
                border: Border.all(
                  color: hovering || waiting ? AppColors.gold : AppLine.faint(0.25),
                  width: hovering || waiting ? AppLine.ink : AppLine.hairline,
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
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Semantics(
                          button: true,
                          label: 'Look closer at painting $number',
                          child: GestureDetector(
                            key: ValueKey('closer-${painting.id}'),
                            onTap: onCloser,
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
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('PAINTING $number', maxLines: 1, style: AppText.eyebrow(color: AppColors.inkBrown)),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  // The note it holds, or room for one.
                  Container(
                    key: ValueKey('slot-note-${painting.id}'),
                    height: 34,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: held == null ? Colors.transparent : AppColors.navy,
                      borderRadius: BorderRadius.circular(AppRadius.paper),
                      border: Border.all(color: held == null ? AppColors.inkBrown.withValues(alpha: 0.35) : AppColors.navyDeep, width: AppLine.hairline),
                    ),
                    child: Text(
                      held == null ? 'note?' : 'NOTE ${held.toUpperCase()}',
                      style: held == null ? AppText.caption() : AppText.mark(color: AppColors.goldLight, size: 14),
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

/// One note, to pick (navy once picked) or drag onto its painting; the
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
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
      decoration: BoxDecoration(
        color: picked ? AppColors.navy : AppColors.paperLight,
        borderRadius: BorderRadius.circular(AppRadius.paper),
        border: Border.all(color: picked ? AppColors.navyDeep : AppColors.parchmentDark, width: picked ? AppLine.ink : AppLine.hairline),
        boxShadow: AppShadow.paperLift,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            // Plain words: the whole card picks the note (its words are
            // looked up on the notes' card, from the studio).
            child: Text(
              text,
              style: AppText.letter(size: 15, color: picked ? AppColors.paperLight : AppColors.inkBrown),
            ),
          ),
          if (joinedTo != null) ...[
            const SizedBox(width: AppSpace.sm),
            Text('→ $joinedTo', style: AppText.mark(color: picked ? AppColors.goldLight : AppColors.burgundy, size: 15)),
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

/// A picture over the page, whole, to pinch closer; a tap outside or CLOSE
/// goes back.
class PictureCloser extends StatelessWidget {
  const PictureCloser({super.key, required this.file, required this.aspect, required this.label});

  final String file;
  final double aspect;
  final String label;

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
                          child: Image.asset(file, key: const ValueKey('closer-picture'), fit: BoxFit.contain, excludeFromSemantics: true),
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
