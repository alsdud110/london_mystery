import 'dart:ui' show Offset, Rect, Size;

import '../../models/investigation.dart' show InvestigationSpot;
import '../../models/painter_puzzles.dart';
import '../../models/scene_exhibit.dart';
import '../../models/scene_explore.dart' show ScenePixels;
import '../../models/station_clocks.dart';
import '../../models/tower_puzzles.dart';

/// What a Season 2 scene is beyond its words (`DifficultyContent.structureOf`
/// for the scenes of Cases 01–03): its pictures and where things are on them,
/// its ids and their order, the times, answers and documents its puzzle is
/// read from. A level may give a scene its own words, never another one of
/// these. Null: not a kind known here.
///
/// Places are written out whole (`Rect`'s and `Offset`'s own strings round
/// to one decimal place, and every place here is a fraction of a picture).
String? season2StructureOf(Object? entry) => switch (entry) {
      final StationClocksScene s => [
          'stationClocks',
          s.picture,
          _px(s.pixels),
          for (final c in s.clocks)
            [c.optionId, c.name, c.time, _at(c.centre), _at(c.twelve), _at(c.hourNumeral), _rect(c.area), _rect(c.closeUp), _at(c.mark)]
                .join(','),
          _spot(s.board),
          _spot(s.desk),
          for (final o in s.others) _areas(o),
          s.boardTitle,
          for (final d in s.departures) '${d.time} ${d.to} ${d.platform}',
          s.noticeTitle,
          ...s.notice,
          ...s.noticeKeys,
          _at(s.guideAt),
          _rect(s.inside),
          _rect(s.opening),
        ].join('|'),
      final Exhibit e => ['exhibit', e.id, e.picture, _px(e.pixels), e.title].join('|'),
      final CompareScene c => [
          'compare',
          c.real,
          c.painted,
          _px(c.pixels),
          for (final s in c.changes) '${s.id}:${_rect(s.area)}',
          c.foundLines.keys.join(','),
          c.checklist.keys.join(','),
          _rect(c.opening),
        ].join('|'),
      final StudioScene s => [
          'studio',
          s.picture,
          _px(s.pixels),
          for (final p in s.paintings) [p.id, _rect(p.area), _at(p.mark), p.file, _px(p.pixels)].join(','),
          s.order.join(','),
          _areas(s.desk),
          _at(s.deskMark),
          for (final o in s.others) _areas(o),
          // The note's letter is put into this line on the page.
          s.matchPainting.contains('{note}'),
          _rect(s.opening),
        ].join('|'),
      final LayerScene l => [
          'layer',
          l.paint,
          l.sketch,
          _px(l.pixels),
          _rect(l.view),
          _rect(l.canvas),
          for (final m in l.marks) '${m.id}:${_rect(m.area)}',
          l.foundLines.keys.join(','),
        ].join('|'),
      final CanvasScene c => [
          'canvas',
          for (final v in c.canvases) '${v.id}:${v.file}:${v.name}',
          _px(c.pixels),
          _rect(c.paint),
          c.back,
          _px(c.backPixels),
          _rect(c.writeOn),
          c.message,
        ].join('|'),
      final RecordsScene r => ['records', _doc(r.first), _doc(r.second), r.checkLabel].join('|'),
      final LiftScene l => [
          'lift',
          l.picture,
          _px(l.pixels),
          _rect(l.plateArea),
          _rect(l.logArea),
          l.plate,
          _px(l.platePixels),
          for (final s in l.stops) '${s.id}:${s.name}:${_at(s.at)}:${s.service}',
          l.passengerRoute.join(','),
          l.serviceRoute.join(','),
          l.legend,
          _rect(l.legendAt),
          l.log,
          _px(l.logPixels),
          _rect(l.logCrop),
          _quad(l.logSheet),
          [_rect(l.logTable.titleBox), l.logTable.columns.join(','), l.logTable.top, l.logTable.rows, l.logTable.rowHeight].join(','),
          l.logHeadings.join(','),
          l.logTitle,
          for (final t in l.trips) '${t.time}:${t.from}:${t.to}:${t.service}',
        ].join('|'),
      final DialLockScene d => [
          'dialLock',
          d.lock,
          _px(d.pixels),
          _rect(d.view),
          for (final w in d.windows) _at(w),
          d.windowRadius,
          d.dial,
          _px(d.dialPixels),
          _at(d.pivot),
          d.showRadius,
          for (final s in d.symbols)
            '${s.id}:${s.name}:${s.angle}:${_rect(s.closeUp)}:${s.outline.ovals.map(_rect).join(';')}:${s.outline.polygon.map(_at).join(';')}',
          d.start.join(','),
          d.openLabel,
        ].join('|'),
      final EvidenceBoardScene b => [
          'evidenceBoard',
          b.shut,
          b.open,
          _px(b.pixels),
          for (final q in b.questions) '${q.id}:${q.text}',
          for (final e in b.evidence) '${e.id}:${e.evidenceId}',
          b.conclusionId,
          b.conclusionQuestion,
          for (final c in b.conclusions) '${c.id}:${c.text}',
          b.solveLabel,
          b.plaque,
          _px(b.plaquePixels),
          _rect(b.plaqueWriteOn),
          b.plaqueMessage,
          _rect(b.riverAt),
          b.riverWord,
        ].join('|'),
      _ => null,
    };

String _px(ScenePixels p) => '${p.width}x${p.height}';
String _at(Offset o) => '(${o.dx},${o.dy})';
String _rect(Rect r) => '[${r.left},${r.top},${r.right},${r.bottom}]';
String _size(Size s) => '${s.width}x${s.height}';
String _areas(InvestigationSpot s) => s.areas.map(_rect).join(';');
String _spot(StationSpot s) => [s.id, s.title, _rect(s.area), _at(s.mark), if (s.outline case final o?) _rect(o)].join(',');
String _quad(PaperQuad q) => [_at(q.topLeft), _at(q.topRight), _at(q.bottomRight), _at(q.bottomLeft), _size(q.flat)].join(',');
String _doc(RecordDoc d) => [
      d.id,
      d.name,
      d.file,
      _px(d.pixels),
      _rect(d.crop),
      _quad(d.sheet),
      [
        _rect(d.layout.title),
        d.layout.rows.join(';'),
        d.layout.rowHeight,
        d.layout.labelLeft,
        d.layout.labelRight,
        d.layout.valueLeft,
        d.layout.valueRight,
        d.layout.noteRow,
        d.layout.noteLeft,
        d.layout.reach,
        d.layout.ink,
      ].join(','),
      d.title,
      for (final l in d.lines) '${l.id}:${l.label}:${l.value}',
      d.note,
    ].join(',');
