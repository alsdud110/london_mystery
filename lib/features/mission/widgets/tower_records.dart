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

/// Two records of the same job compared ([RecordsScene]): one shown at a
/// time (its tab above it), its words written on its paper. Each is read
/// by looking at it (kept read: [onRead]); once both are, a line is picked
/// on each and THESE DO NOT MATCH sends `first:second` to [onSubmit],
/// checked as the puzzle's answer. Nothing is marked before it is picked:
/// the lines that differ are found by reading.
class TowerRecords extends StatefulWidget {
  const TowerRecords({
    super.key,
    required this.scene,
    required this.mission,
    required this.progress,
    required this.read,
    required this.onRead,
    required this.onChanged,
    required this.onSubmit,
  });

  final RecordsScene scene;
  final Mission mission;
  final TowerPuzzleProgress progress;

  /// The records read so far (by [RecordDoc.id]).
  final Set<String> read;
  final ValueChanged<String> onRead;
  final VoidCallback onChanged;
  final Future<void> Function(String answer) onSubmit;

  @override
  State<TowerRecords> createState() => _TowerRecordsState();
}

class _TowerRecordsState extends State<TowerRecords> {
  bool _checking = false;

  TowerPuzzleProgress get _p => widget.progress;
  RecordsScene get _scene => widget.scene;
  RecordDoc get _shown => _scene.docs[_p.doc.clamp(0, _scene.docs.length - 1)];
  bool get _bothRead => _scene.docs.every((d) => widget.read.contains(d.id));

  @override
  void initState() {
    super.initState();
    // The record on the page is being read.
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  void _markRead() {
    if (mounted && !widget.read.contains(_shown.id)) widget.onRead(_shown.id);
  }

  void _show(int i) {
    _p.doc = i;
    widget.onChanged();
    _markRead();
  }

  void _pick(RecordDoc doc, String line) {
    if (_p.picked[doc.id] == line) {
      _p.picked.remove(doc.id);
    } else {
      _p.picked[doc.id] = line;
    }
    widget.onChanged();
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await widget.onSubmit('${_p.picked[_scene.first.id]}:${_p.picked[_scene.second.id]}');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  String _pickedValue(RecordDoc doc) {
    final id = _p.picked[doc.id];
    if (id == null) return '—';
    final line = doc.lines.firstWhere((l) => l.id == id);
    return '${line.label} ${line.value}';
  }

  @override
  Widget build(BuildContext context) {
    final doc = _shown;
    final ready = _bothRead && _scene.docs.every((d) => _p.picked.containsKey(d.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _bothRead ? _scene.compareTask : _scene.readTask,
          key: const ValueKey('records-task'),
          textAlign: TextAlign.center,
          style: AppText.task(),
        ),
        const SizedBox(height: AppSpace.md),
        // The two records, one tab each; a tick once read.
        Row(
          children: [
            for (final (i, d) in _scene.docs.indexed) ...[
              if (i > 0) const SizedBox(width: AppSpace.sm),
              Expanded(
                child: _DocTab(
                  key: ValueKey('record-tab-${d.id}'),
                  name: d.name,
                  selected: d.id == doc.id,
                  read: widget.read.contains(d.id),
                  onTap: () => _show(i),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpace.md),
        RecordPaper(
          key: ValueKey('record-${doc.id}'),
          doc: doc,
          picked: _p.picked[doc.id],
          // Lines are picked once both records have been read.
          onPick: _bothRead ? (line) => _pick(doc, line) : null,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: InkTextButton(
            label: 'Look closer',
            glyph: InkGlyph.search,
            onPressed: () => showDocumentCloser(
              context,
              title: doc.name,
              aspect: doc.aspect,
              child: RecordPaper(doc: doc, picked: _p.picked[doc.id]),
            ),
          ),
        ),
        if (_bothRead) ...[
          const SizedBox(height: AppSpace.sm),
          // What is picked on each record, side by side.
          Semantics(
            container: true,
            label: [for (final d in _scene.docs) '${d.name}: ${_pickedValue(d)}'].join('. '),
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
              decoration: BoxDecoration(
                color: AppColors.paperLight,
                borderRadius: BorderRadius.circular(AppRadius.paper),
                border: Border.all(color: AppLine.faint(), width: AppLine.hairline),
              ),
              child: Row(
                children: [
                  for (final (i, d) in _scene.docs.indexed) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                        child: SizedBox(height: 34, child: VerticalDivider(width: 1, thickness: AppLine.hairline, color: AppLine.faint(0.35))),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(d.title, maxLines: 1, style: AppText.eyebrow()),
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Text(_pickedValue(d), key: ValueKey('picked-${d.id}'), style: AppText.bodyText(size: 16, weight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          GameButton(
            key: const ValueKey('records-check'),
            label: _scene.checkLabel,
            glyph: InkGlyph.check,
            tap: TapRole.primary,
            onPressed: ready && !_checking ? _check : null,
          ),
        ],
      ],
    );
  }
}

/// A record's tab: its name, a tick once read, the one shown in navy.
class _DocTab extends StatelessWidget {
  const _DocTab({super.key, required this.name, required this.selected, required this.read, required this.onTap});

  final String name;
  final bool selected;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = selected ? AppColors.paperLight : AppColors.navy;
    return Semantics(
      button: true,
      selected: selected,
      label: '$name${read ? ', read' : ''}',
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
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (read) ...[
                    InkIcon(InkGlyph.check, size: AppIconSize.tiny, color: selected ? AppColors.goldLight : AppColors.success),
                    const SizedBox(width: AppSpace.xs),
                  ],
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(name, maxLines: 1, style: AppText.button(size: 15, color: ink)),
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

/// A record: its picture, and its words written on its blank paper as if
/// printed there ([SheetWriting]: in the sheet's own perspective) — the
/// title in its box, each line on its own row (picked by a tap when
/// [onPick] is given; the one picked circled in ink), and its note.
class RecordPaper extends StatelessWidget {
  const RecordPaper({super.key, required this.doc, this.picked, this.onPick});

  final RecordDoc doc;
  final String? picked;
  final ValueChanged<String>? onPick;

  @override
  Widget build(BuildContext context) {
    final l = doc.layout;
    final ink = l.rowHeight * l.ink;
    return CroppedPicture(
      file: doc.file,
      pixels: doc.pixels,
      crop: doc.crop,
      label: doc.label,
      overlay: SheetWriting(
        corners: doc.sheetInCrop,
        flat: doc.sheet.flat,
        child: Stack(
          children: [
            Positioned.fromRect(
              rect: l.title,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: GlossaryText(
                    doc.title,
                    style: paperInk(size: l.title.height * 0.62, weight: FontWeight.w800).copyWith(letterSpacing: 1.5, height: 1),
                  ),
                ),
              ),
            ),
            for (final (i, line) in doc.lines.indexed)
              if (i < l.rows.length)
                Positioned(
                  left: l.labelLeft,
                  top: l.rows[i] - l.reach,
                  width: l.valueRight - l.labelLeft,
                  height: l.rowHeight + 2 * l.reach,
                  child: _RecordLineRow(
                    key: ValueKey('line-${doc.id}-${line.id}'),
                    line: line,
                    layout: l,
                    ink: ink,
                    picked: picked == line.id,
                    onTap: onPick == null ? null : () => onPick!(line.id),
                  ),
                ),
            if ((doc.note, l.noteRow) case (final note?, final row?))
              Positioned(
                left: l.noteLeft ?? l.valueLeft,
                top: row,
                width: l.valueRight - (l.noteLeft ?? l.valueLeft),
                height: l.rowHeight,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: GlossaryText(
                      note,
                      style: AppText.style(AppText.italic, size: ink * 0.9, color: AppColors.inkBrown, fontStyle: FontStyle.italic, height: 1),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One line on a record's row: its label in the labels' column, its value
/// in the values' (each within its own column, never across a ruled line),
/// the whole row and [RecordLayout.reach] round it one target to pick.
class _RecordLineRow extends StatelessWidget {
  const _RecordLineRow({super.key, required this.line, required this.layout, required this.ink, required this.picked, this.onTap});

  final RecordLine line;
  final RecordLayout layout;
  final double ink;
  final bool picked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = layout;
    final h = l.rowHeight;
    Widget cell(double left, double right, Widget text) => Positioned(
          left: left - l.labelLeft,
          top: l.reach,
          width: right - left,
          height: h,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: text),
          ),
        );
    final row = Stack(
      clipBehavior: Clip.none,
      children: [
        // The one picked: circled in ink round its row.
        if (picked)
          Positioned(
            left: -h * 0.15,
            top: l.reach - h * 0.12,
            right: -h * 0.15,
            height: h * 1.24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.navy, width: h * 0.08),
                borderRadius: BorderRadius.circular(h),
              ),
            ),
          ),
        cell(l.labelLeft, l.labelRight, Text(line.label, style: paperInk(size: ink * 0.78, weight: FontWeight.w500, color: AppColors.muted).copyWith(height: 1))),
        // A line to pick is one target: its words are dotted only where the
        // line is read, not picked.
        cell(
          l.valueLeft,
          l.valueRight,
          GlossaryText(line.value, style: paperInk(size: ink).copyWith(height: 1), interactive: onTap == null),
        ),
      ],
    );
    if (onTap == null) {
      return Semantics(label: '${line.label}: ${line.value}', child: ExcludeSemantics(child: row));
    }
    return Semantics(
      button: true,
      selected: picked,
      label: '${line.label}: ${line.value}',
      excludeSemantics: true,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: row),
    );
  }
}
