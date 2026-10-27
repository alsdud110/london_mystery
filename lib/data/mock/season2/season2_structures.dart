import 'dart:ui' show Offset, Rect, Size;

import '../../models/abbesses_puzzles.dart';
import '../../models/case_talk.dart';
import '../../models/easy_steps.dart';
import '../../models/garden_puzzles.dart';
import '../../models/investigation.dart' show InvestigationSpot;
import '../../models/letter_puzzles.dart';
import '../../models/opera_puzzles.dart';
import '../../models/painter_puzzles.dart';
import '../../models/river_puzzles.dart';
import '../../models/scene_exhibit.dart';
import '../../models/scene_explore.dart' show ScenePixels;
import '../../models/star_puzzles.dart';
import '../../models/station_clocks.dart';
import '../../models/tower_puzzles.dart';
import '../../models/workshop_puzzles.dart';

/// What a Season 2 scene is beyond its words (`DifficultyContent.structureOf`
/// for the scenes of Cases 01–12: the very easy steps, the talks and the
/// case's ending): its pictures and where things are on them,
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
      // ── Cases 04–06 (PART 7B) ──────────────────────────────────────────
      // The papers a puzzle is read from (the plaque's back, the marks'
      // words, the ledger, the label, the street book, the repair card, the
      // slips, the tags, the porter's plan, the drawers, the letter) are
      // part of what it is; the ways to play are kept by the tests.
      final RiverMarksScene r => [
          'riverMarks',
          r.wall,
          _px(r.pixels),
          for (final m in r.marks)
            [m.id, m.name, _rect(m.area), _rect(m.wordAt), m.closeUp, _rect(m.closeWordAt), m.word, m.waves, m.arrowDown].join(','),
          _px(r.closePixels),
          _rect(r.signAt),
          r.sign,
          season2StructureOf(r.plaqueFront),
          _plaque(r.plaqueBack),
          // Said line by line, one for each of the plaque's.
          r.rightLines.length,
        ].join('|'),
      final KeeperHutScene k => [
          'keeperHut',
          k.outside,
          _rect(k.doorArea),
          k.inside,
          _rect(k.ledgerArea),
          _px(k.pixels),
          k.ledger,
          _px(k.ledgerPixels),
          for (final p in k.pages)
            [
              p.title,
              _rect(p.crop),
              _rect(p.writeOn),
              for (final e in p.entries) '${e.date}:${e.parts.map((x) => '${x.box}=${x.text}').join('+')}:${e.initials}:${e.hands}',
            ].join(','),
          k.hands,
          k.findBox,
        ].join('|'),
      final BoxesScene b => [
          'quayBoxes',
          b.picture,
          _px(b.pixels),
          _rect(b.view),
          for (final x in b.boxes) '${x.id}:${x.number}:${_rect(x.area)}:${_rect(x.plateAt)}:${x.note != null}',
          b.open,
          _px(b.openPixels),
          b.decoy,
          _px(b.decoyPixels),
          _rect(b.decoyAt),
          b.decoyLines.join(','),
          _label(b.label),
          b.slots.join(','),
        ].join('|'),
      final StreetBookScene s => [
          'streetBook',
          s.book,
          _px(s.bookPixels),
          s.pages.map(_rect).join(';'),
          for (final e in s.entries) '${e.id}:${e.name}:${e.lines.join(';')}:${e.page}',
          for (final e in s.evidence) '${e.id}:${e.evidenceId}',
          s.maxEvidence,
          s.hut,
          _px(s.hutPixels),
          s.gate,
          _px(s.gatePixels),
          _rect(s.gateView),
          _rect(s.signAt),
          s.signLines.join(','),
          _rect(s.scrapAt),
          _label(s.label),
          s.hands,
        ].join('|'),
      final MarkCompareScene m => [
          'markCompare',
          m.bench,
          _px(m.pixels),
          for (final x in m.seals) [x.id, x.name, x.thing, _rect(x.area), _rect(x.seal), x.copy.name].join(','),
          _maker(m.mark),
          m.sheet,
          _px(m.sheetPixels),
          _rect(m.sheetMarkAt),
          m.note,
          _written(m.card),
        ].join('|'),
      final ClockWallScene c => [
          'clockWall',
          c.wall,
          _px(c.pixels),
          _rect(c.view),
          for (final x in c.clocks)
            [x.id, x.numeral, _at(x.centre), x.radius, _rect(x.area), _rect(x.plateAt), x.shows, x.change, x.back].join(','),
          _px(c.backPixels),
          c.watch.inMilliseconds,
        ].join('|'),
      final PostTrailScene p => [
          'postTrail',
          p.slip,
          _px(p.slipPixels),
          _rect(p.slipWriteOn),
          for (final x in p.slips) '${x.id}:${x.letter}:${x.date}:${x.time}:${x.record}:${x.where}',
          p.slots.join(','),
          p.slotLabels.join(','),
          _written(p.receipt),
          p.stage,
          _px(p.stagePixels),
          _rect(p.stageView),
        ].join('|'),
      final HoldRackScene h => [
          'holdRack',
          '${h.rack.clue.kind.name}:${h.rack.clue.number}:${h.rack.clue.date}:${h.rack.clue.time}',
          for (final t in h.rack.tags) '${t.id}:${t.kind.name}:${t.number}:${t.date}:${t.time}:${t.record}:${t.reason.join(';')}',
          h.file,
          _px(h.pixels),
          _rect(h.view),
          for (final t in h.tags) '${t.id}:${_rect(t.spot)}:${_rect(t.paper)}',
          h.tagFile,
          _px(h.tagPixels),
          _rect(h.writeOn),
          h.ink,
          _written(h.trail),
        ].join('|'),
      final PlanScene p => [
          'plan',
          for (final d in p.route.doors) '${d.id}:${d.side.name}:${d.pastStatue}:${d.nth}',
          '${p.route.directions.pastStatue}:${p.route.directions.side.name}:${p.route.directions.nth}',
          p.route.archive,
          p.file,
          _px(p.pixels),
          _rect(p.view),
          _at(p.start),
          for (final e in p.steps.entries) '${e.key.name}:${_at(e.value.at)}:${_rect(e.value.area)}',
          for (final d in p.doors) '${d.id}:${_at(d.at)}:${_rect(d.area)}:${_at(d.badge)}',
        ].join('|'),
      final ArchiveScene a => [
          'archive',
          for (final d in a.drawers.drawers) '${d.id}:${d.kind.name}:${d.from}:${d.to}',
          '${a.drawers.kind.name}:${a.drawers.number}',
          for (final e in a.drawers.envelopes) '${e.id}:${e.tear}',
          a.drawers.cornerTear,
          a.drawers.cornerLabel,
          a.cabinet,
          _px(a.cabinetPixels),
          _rect(a.cabinetView),
          for (final d in a.cabinetDrawers) '${d.id}:${_rect(d.area)}:${_rect(d.label)}',
          a.drawer,
          _px(a.drawerPixels),
          _rect(a.drawerView),
          _rect(a.felt),
          for (final e in a.envelopes) '${e.id}:${e.file}:${_rect(e.inDrawer)}',
          _px(a.envelopePixels),
          a.corner,
          _rect(a.cornerPiece),
          _rect(a.cornerTagAt),
          _rect(a.numberTag),
          a.seal,
          _px(a.sealPixels),
          _rect(a.sealAt),
          // The drawer's own label is put into these lines on the page.
          a.notHere.contains('{label}'),
          a.notLetters.contains('{label}'),
        ].join('|'),
      final LetterMapScene l => [
          'letterMap',
          (l.map.drawing.map((f) => f.name).toList()..sort()).join(','),
          for (final b in l.map.buildings) '${b.id}:${(b.features.map((f) => f.name).toList()..sort()).join(',')}:${b.shows}',
          l.map.back.join(','),
          _letter(l.letter),
          _px(l.sketchPixels),
          l.mapFile,
          _px(l.mapPixels),
          for (final s in l.spots) '${s.id}:${s.name}:${_at(s.at)}',
          l.closer,
        ].join('|'),
      // ── Cases 07–09 (PART 7C) ──────────────────────────────────────────
      // Lines a level may say its own way are counted (and, for lines said
      // to an answer, keyed), never read: every other word is the scene's.
      final FlyRailScene f => [
          'flyRail',
          f.rail.door.name,
          f.rail.above.name,
          for (final b in f.rail.ropes) '${b.id}:${b.door.name}:${b.above.name}:${b.tower}',
          f.stage,
          _px(f.stagePixels),
          _rect(f.stageView),
          _rect(f.opening),
          f.railFile,
          _px(f.railPixels),
          _rect(f.railView),
          f.ropeX.join(','),
          f.plates.map(_rect).join(';'),
          f.lockTop,
          f.rope,
          _px(f.ropePixels),
          '${f.ropeStrand.$1},${f.ropeStrand.$2}',
          for (final b in f.backdrops) '${b.id}:${b.file}',
          _px(f.backdropPixels),
          _rect(f.canvas),
          _rect(f.closer),
          f.clueFile,
          _px(f.cluePixels),
          _rect(f.clueCrop),
          f.clueLine,
          f.back,
          _px(f.backPixels),
          _rect(f.pocket),
          _drawn(f.slip),
        ].join('|'),
      final LightTableScene l => [
          'lightTable',
          '${l.record.files.join(',')}:${l.record.changed}:${l.record.oldTime}:${l.record.newTime}',
          l.archive,
          _px(l.archivePixels),
          _rect(l.archiveView),
          l.label,
          _rect(l.labelAt),
          _drawn(l.file3),
          _drawn(l.programme),
          _drawn(l.cue),
          l.table,
          l.tableOn,
          _px(l.tablePixels),
          _rect(l.glass),
          _rect(l.switchAt),
          _rect(l.closeUp),
          for (final p in l.pins) '${p.spot.name}:${_rect(p.area)}:${_at(p.at)}:${p.via.map(_at).join(';')}',
          _drawn(l.slip),
        ].join('|'),
      final CornerChoiceScene c => [
          'cornerChoice',
          c.square,
          _px(c.squarePixels),
          _px(c.cornerPixels),
          for (final x in c.corners) '${x.id}:${x.name}:${_rect(x.area)}:${x.file}',
        ].join('|'),
      final MorningSketchesScene m => [
          'morningSketches',
          for (final x in m.sketches) _sketch(x),
          m.shown.join(','),
          m.lampOff,
          m.slots.join(','),
        ].join('|'),
      final TornSlipScene t => [
          'tornSlip',
          t.folded,
          _px(t.foldedPixels),
          _form(t.form),
          for (final p in t.parts) '${p.id}:${_rect(p.area)}:${p.mark?.name}:${p.name}:${p.line != null}',
          t.sealId,
          for (final c in t.sealChecks) '${c.question}:${c.choices.join(',')}:${c.answer}',
          t.folds,
          t.sealTitle,
          t.noteLines.join(';'),
        ].join('|'),
      final TornHourScene h => [
          'tornHour',
          _sketch(h.sketch),
          _form(h.form),
          h.startTurns,
          for (final q in h.board.questions) '${q.id}:${q.text}',
          for (final e in h.board.evidence) '${e.id}:${e.evidenceId}',
          h.board.conclusionId,
          h.board.conclusionQuestion,
          for (final c in h.board.conclusions) '${c.id}:${c.text}',
          h.lead.file,
          _px(h.lead.pixels),
          for (final p in [...h.lead.bagParts, h.lead.decoy]) '${p.id}:${_rect(p.area)}',
          h.lead.bagDone.length,
          h.lead.features.join(';'),
          h.lead.mapFile,
          _px(h.lead.mapPixels),
          for (final s in h.lead.spots) '${s.id}:${s.name}:${_at(s.at)}',
          h.lead.answer,
          h.lead.feedback.keys.join(','),
          h.lead.doneLines.length,
          h.placedLines.length,
        ].join('|'),
      final TrialMapScene t => [
          'trialMap',
          t.mapFile,
          _px(t.mapPixels),
          for (final s in t.spots) '${s.id}:${s.name}:${_at(s.at)}',
          for (final m in t.models) _model(m),
          _px(t.modelPixels),
          t.dropRadius,
          t.specialLines.keys.join(','),
        ].join('|'),
      final GearBoardScene g => [
          'gearBoard',
          g.file,
          _px(g.pixels),
          _rect(g.view),
          g.gearFile,
          _px(g.gearPixels),
          g.dialFile,
          _px(g.dialPixels),
          _at(g.dialPivot),
          for (final e in g.radii.entries) '${e.key.name}=${e.value}',
          for (final x in g.slots) '${x.id}:${x.size.name}:${_at(x.at)}:${x.branch}',
          for (final x in g.fixed) '${_at(x.at)}:${x.radius}:${x.clockwise}:${x.branch}',
          for (final x in g.clocks) '${x.id}:${x.name}:${_at(x.at)}:${x.radius}:${x.branch}:${x.clockwise}',
          for (final e in g.tray.entries) '${e.key.name}=${_at(e.value)}',
        ].join('|'),
      final MakerMarksScene m => [
          'makerMarks',
          m.file,
          _px(m.pixels),
          m.handsFile,
          _px(m.handsPixels),
          for (final x in m.marks) '${x.id}:${x.kind.name}:${x.name}:${x.source}:${x.evidenceId}',
          for (final x in m.paper) '${x.id}:${x.kind.name}:${x.name}:${x.words}:${_rect(x.markAt)}:${_rect(x.wordsAt)}:${_rect(x.crop)}:${x.light}:${x.angle}',
          m.lines.keys.join(','),
        ].join('|'),
      final TowerTestScene t => [
          'towerTest',
          t.garden,
          _px(t.gardenPixels),
          '${_rect(t.gardenClock.face)}:${t.gardenClock.dial}:${_px(t.gardenClock.dialPixels)}:${_at(t.gardenClock.pivot)}:${t.gardenClock.faceRadius}:${t.gardenClock.hour}',
          t.dialFile,
          _px(t.dialPixels),
          _at(t.dialPivot),
          t.dialRadius,
          t.startHour,
          t.targetHour,
          for (final c in t.clocks) '${c.id}:${c.name}:${c.joined}',
          (t.hourLines.keys.toList()..sort()).join(','),
          t.testedLines.length,
          t.afterLines.length,
          t.lead.title,
          t.lead.tag,
          for (final m in t.lead.models) _model(m),
          _px(t.lead.modelPixels),
          t.lead.answer,
          t.lead.mapFile,
          _px(t.lead.mapPixels),
          '${t.lead.spot.id}:${t.lead.spot.name}:${_at(t.lead.spot.at)}',
          t.lead.doneLines.length,
        ].join('|'),
      // ── Cases 10–12 (PART 7D) ──────────────────────────────────────────
      final DrumTapeScene d => _tape(d),
      final CityClocksScene c => [
          'cityClocks',
          _roofPhoto(c.photo),
          c.trialMapId,
          c.lensScale,
          c.lensSize,
          c.sortedLines.length,
        ].join('|'),
      final ShadowCheckScene sc => [
          'shadowCheck',
          '${sc.sundial.file}:${_px(sc.sundial.pixels)}:${_at(sc.sundial.hub)}:${sc.sundial.radius}:${sc.sundial.plate}:${sc.sundial.lines.map((l) => '${l.time}@${l.angle}').join(',')}:${sc.sundial.shortest}:${sc.sundial.longest}:${sc.sundial.snap}',
          _roofPhoto(sc.photo),
          for (final p in sc.photos) '${p.id}:${p.number}:${p.t1}:${p.sun}',
          sc.plateWords,
        ].join('|'),
      final HourRecordScene h => [
          'hourRecord',
          '${h.room.file}:${_px(h.room.pixels)}:${_at(h.room.plateCentre)}:${h.room.plateSize}:${h.room.plateAngle}:${h.room.plateLines.join(',')}:${_rect(h.room.doorStar)}:${h.room.things.map(_rect).join(';')}',
          _tape(h.tape),
          h.photo1Mark,
          h.photo2Mark,
          for (final p in h.photos) '${p.id}:${p.number}:${p.t1}:${p.sun}',
          h.backLabel,
          h.rightLabel,
          h.foundLines.length,
          h.logFile,
          _px(h.logPixels),
          _rect(h.leftPage),
          _rect(h.rightPage),
          _rect(h.emblem),
          h.logTitle,
          for (final p in h.pages) '${p.id}:${p.number}:${p.from}:${p.to}:${p.inBook}',
          h.afterLines.length,
          h.lead.title,
          h.lead.heading,
          for (final l in h.lead.lines) '${l.id}:${l.text}',
          h.lead.answer,
          h.lead.mapFile,
          _px(h.lead.mapPixels),
          '${h.lead.spot.id}:${h.lead.spot.name}:${_at(h.lead.spot.at)}',
          h.lead.doneLines.length,
        ].join('|'),
      // A talk: who speaks, each step's id and what it needs, and every beat
      // line by line (who says it and how): a saved talk is a step and a
      // line number. What is said is its words.
      final TalkScene t => _talk(t),
      final TalkMission m => ['talkMission', m.before == null ? null : _talk(m.before!), m.after == null ? null : _talk(m.after!)].join('#'),
      final List<EndingLine> l => [
          'ending',
          for (final e in l) '${e.voice.name}:${e.name}:${e.portrait}:${e.background}:${e.evidenceId}',
        ].join('|'),
      // Played one small step at a time: the steps, what each shows and
      // asks, its answer, how many free hints lead to it and where the
      // answer is lit. What each step says (its line, hints, wrong-answer
      // lines, its done line) is its words.
      final EasyStepsScene e => [
          'easySteps',
          e.title,
          e.answer,
          e.seen.join(','),
          for (final s in e.steps)
            [
              s.id,
              s.does.name,
              _mark(s.target),
              s.lit.map(_mark).join(';'),
              s.question != null,
              for (final o in s.options) '${o.id}=${o.label}=${_panel(o.panel)}=${o.area == null ? null : _rect(o.area!)}',
              s.answer,
              s.hints.length,
              s.lookHere.map(_mark).join(';'),
              s.tell != null,
              s.done != null,
              s.panels.map(_panel).join(';'),
              s.after?.map(_panel).join(';'),
            ].join('~'),
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

String _plaque(PlaqueBack p) => [p.file, _px(p.pixels), _rect(p.writeOn), p.lines.join(';')].join(',');

String _maker(MakerMark m) => [m.file, _px(m.pixels), m.split.map(_at).join(';'), _at(m.shift), m.tipFile, _at(m.tipShift)].join(',');

String _written(WrittenPaper w) => [
      w.file,
      _px(w.pixels),
      _rect(w.writeOn),
      w.lines.join(';'),
      w.markAt == null ? null : _rect(w.markAt!),
      w.signedWith == null ? null : _maker(w.signedWith!),
      w.size,
      w.tag,
      w.tagAt == null ? null : _rect(w.tagAt!),
    ].join(',');

String _label(DeliveryLabel l) => [
      l.file,
      l.back,
      _px(l.pixels),
      for (final x in l.lines) '${x.piece}:${x.text}:${x.left}:${x.top}:${x.size}:${x.centred}:${x.stamp}:${x.faint}',
      l.tear1,
      l.tear2,
      l.tear3,
      l.paperLeft,
      l.paperRight,
      l.paperBottom,
      l.numberLabel,
      _rect(l.numberAt),
      l.addressLeft,
      l.addressTop,
      l.addressSize,
      l.addressStart,
      l.addressRest,
      _rect(l.stampAt),
      l.hands,
      l.backLines.join(';'),
      _rect(l.backAt),
    ].join(',');

String _letter(LetterPaper l) =>
    [l.file, _px(l.pixels), l.lines.join(';'), _rect(l.writeOn), l.sketch, _rect(l.sketchAt), l.back.join(';'), _rect(l.backOn), l.showBack].join(',');

String _mark(EasyMark? m) => m == null ? '-' : '${m.panel}@${m.area == null ? '' : _rect(m.area!)}';

String _picture(EasyPicture p) => [p.file, _px(p.pixels), p.crop == null ? null : _rect(p.crop!)].join(',');

String _writing(EasyWriting w) => [w.text, _rect(w.at), w.size, w.ink.name, w.strong, w.mirrored].join(',');

String _layer(EasyLayer l) => [l.file, _rect(l.at), l.opacity, l.graphite, l.turns].join(',');

/// A step's panel beyond its caption: what it shows, and the words drawn
/// on it (a paper's, a picture's) as the case wrote them.
String? _panel(EasyPanel? p) => switch (p) {
      null => null,
      final PicturePanel x => 'picture:${x.id}:${_picture(x.picture)}:${x.writing.map(_writing).join('/')}:${x.layers.map(_layer).join('/')}',
      final PaperPanel x =>
        'paper:${x.id}:${x.title}:${x.lines.map((l) => '${l.text}=${l.strong}').join('/')}:${x.old}:${x.foot}:${x.aspect}',
      final EvidencePanel x => 'evidence:${x.id}:${x.evidenceId}',
      final DrawnPanel x => 'drawn:${x.id}:${_drawn(x.drawn)}:${x.crop == null ? null : _rect(x.crop!)}:${x.pixels == null ? null : _px(x.pixels!)}',
      final QuotePanel x => 'quote:${x.id}:${x.name}:${x.quote}:${x.portrait}',
      final GearMarkPanel x => 'gear:${x.id}:${x.label}:${x.stamped}',
      final RubPanel x =>
        'rub:${x.id}:${_picture(x.book)}:${_rect(x.area)}:${x.lines.map(_writing).join('/')}:${x.signature == null ? null : _layer(x.signature!)}',
      final MachinePanel x => 'machine:${x.id}:${_picture(x.scene.machine)}:${x.scene.wheel}:${x.scene.wrong}:${x.scene.right}:${x.state.name}',
    };

/// A paper drawn as evidence. Kinds not written out here are told by the
/// object itself: a level's step must then show the very same paper.
String _drawn(DrawnEvidence d) => switch (d) {
      final WrittenPaper w => 'written:${_written(w)}',
      final PictureEvidence p => 'picture:${p.file}:${_px(p.pixels)}:${p.crop == null ? null : _rect(p.crop!)}',
      final FittedEnvelope f => 'fitted:${f.envelope}:${f.corner}:${_px(f.pixels)}:${f.tag}:${_rect(f.tagAt)}:${f.seal}:${_rect(f.sealAt)}',
      final LetterPaper l => 'letter:${_letter(l)}',
      final EasyEvidence e => 'easy:${_panel(e.panel)}',
      _ => '${d.runtimeType}#${identityHashCode(d)}',
    };

String _sketch(MorningSketch m) => [
      m.id,
      m.file,
      _px(m.pixels),
      for (final c in m.changes) '${c.id}=${_rect(c.area)}=${c.label}',
      m.study == null ? null : '${m.study!.file}=${_px(m.study!.pixels)}=${_rect(m.study!.at)}',
    ].join(',');

String _form(TornForm f) =>
    [f.file, _px(f.pixels), _rect(f.paper), f.fileWord, _rect(f.fileAt), f.minutes, _rect(f.minutesAt), _rect(f.arrowAt), f.stamp, _rect(f.stampAt)].join(',');

/// A trial clock's model: its picture, place and sign (its line for a
/// wrong place is its words).
String _model(TrialModel m) => [m.id, m.name, m.file, m.spot, m.sign].join(',');

String _tape(DrumTapeScene d) => [
      'drumTape',
      d.drumFile,
      _px(d.drumPixels),
      _at(d.slot),
      _rect(d.plate),
      d.header,
      for (final m in d.marks) '${m.id}:${m.printed}:${m.real}',
    ].join(',');

String _roofPhoto(RoofPhoto p) => [
      p.file,
      _px(p.pixels),
      for (final c in p.clocks) '${c.id}:${c.name}:${_at(c.centre)}:${c.rx}:${c.ry}:${c.trial}:${c.photo1}:${c.photo2}:${_rect(c.card)}',
      '${_at(p.dial.hub)}:${p.dial.rx}:${p.dial.ry}:${p.dial.gnomonTurn}',
      _rect(p.t1Crop),
      _rect(p.dialCrop),
    ].join(',');

/// A beat: its lines' voices and moods, in order (their words not read).
String _beat(List<TalkLine> lines) => lines.map((l) => '${l.voice.name}/${l.mood}').join(';');

String _talk(TalkScene t) => [
      'talk',
      t.id,
      '${t.speaker.id}:${t.speaker.name}:${t.speaker.hiddenName}:${t.speaker.revealedBy}:${t.speaker.portraits}:${t.speaker.baseMood}',
      _beat(t.opening),
      for (final q in t.questions) 'q:${q.id}:${q.requires.toList()..sort()}:${q.repeatable}:${_beat(q.beat)}',
      for (final p in t.presents)
        'p:${p.id}:${p.accepted.toList()..sort()}:${p.choices.join(',')}:${p.requires.toList()..sort()}:${_beat(p.beat)}:${p.misses.keys.join(',')}:${_beat([...p.misses.values, p.miss])}:${p.tell != null}',
      (t.finishWhen.toList()..sort()).join(','),
      t.place,
      t.background,
      t.finishLabel,
      t.answer,
      t.earlierEvidence.join(','),
    ].join('|');
