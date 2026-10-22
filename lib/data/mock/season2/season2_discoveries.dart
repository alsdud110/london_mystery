import '../../models/discovery.dart';
import '../../models/episode.dart';

/// What kind of discovery each regular mission of Season 2 gives, by
/// mission id: its Discovery Moment then names it (DEDUCTION, CLUE FOUND,
/// EVIDENCE FOUND, NEW LEAD) instead of a plain PUZZLE COMPLETE, so the
/// moment and the story after it (MISSION 0n COMPLETE) do not say the same
/// thing twice.
///
/// Presentation only, as every Discovery: nothing here is saved, no reward
/// changes. The words are the mission's own success line; no evidence card
/// is laid (as before), and nothing the next scene tells is told first.
/// What was seen before the puzzle is never "found" (the ticket in Case 01's
/// M2 was handed over: its order is a deduction).
const Map<String, DiscoveryType> season2DiscoveryTypes = {
  // ── Case 01 — The Ticking Watch ─────────────────────────────────────
  's2_ep01_m1': DiscoveryType.deduction, // the old clock is one hour behind
  's2_ep01_m2': DiscoveryType.deduction, // the order of what happened
  's2_ep01_m3': DiscoveryType.clueFound, // the little door: the letter M
  // ── Case 02 — The Vanishing Painter ─────────────────────────────────
  's2_ep02_m1': DiscoveryType.clueFound, // the three changes; his note's back
  's2_ep02_m2': DiscoveryType.clueFound, // the notes matched; the blue-sky day
  's2_ep02_m3': DiscoveryType.evidenceFound, // the sketch under the paint
  // ── Case 03 — The Tower's Secret ────────────────────────────────────
  's2_ep03_m1': DiscoveryType.deduction, // the times do not match
  's2_ep03_m2': DiscoveryType.newLead, // the Service Level
  's2_ep03_m3': DiscoveryType.newLead, // the room behind the iron door
  // ── Case 04 — The River's Secret ────────────────────────────────────
  's2_ep04_m1': DiscoveryType.newLead, // the River Keeper's mark, his steps
  's2_ep04_m2': DiscoveryType.deduction, // Box 17 moved to Box 23
  's2_ep04_m3': DiscoveryType.evidenceFound, // the torn label, put together
  // ── Case 05 — The Silent Workshop ───────────────────────────────────
  's2_ep05_m1': DiscoveryType.evidenceFound, // the maker's own mark; the card
  's2_ep05_m2': DiscoveryType.deduction, // the clock that turns back
  's2_ep05_m3': DiscoveryType.clueFound, // where the letter was
  // ── Case 06 — The Letter That Never Arrived ─────────────────────────
  's2_ep06_m1': DiscoveryType.evidenceFound, // Tag D: kept safe, not stolen
  's2_ep06_m2': DiscoveryType.newLead, // the archive behind Door E
  's2_ep06_m3': DiscoveryType.evidenceFound, // the torn envelope, No. 4417
  // ── Case 07 — The Phantom Performance ───────────────────────────────
  's2_ep07_m1': DiscoveryType.deduction, // the show fits only from 4:00
  's2_ep07_m2': DiscoveryType.evidenceFound, // the stage cue card: 4:00
  's2_ep07_m3': DiscoveryType.evidenceFound, // the Amendment Slip
};

/// The Discovery Moments of Season 2's regular missions in [cases] (case id
/// → case json): each its kind ([season2DiscoveryTypes]) and its own success
/// line.
Map<String, Discovery> season2DiscoveriesOf(Map<String, Map<String, dynamic>> cases) => {
  for (final json in cases.values)
    for (final m in Episode.fromJson(json).missions)
      if (season2DiscoveryTypes[m.id] case final type?)
        m.id: Discovery(type: type, timing: DiscoveryTiming.fromPuzzle, title: m.successMessage, detail: ''),
};
