import 'episode01_mock.dart';
import 'episode02_mock.dart';
import 'episode03_mock.dart';
import 'episode04_mock.dart';
import 'episode05_mock.dart';

/// Season 2 as a whole: who the season is. Its cases, casebook lines and
/// board figures come with its content; until then the season has no cases,
/// so it can be unlocked but not entered (see `SeasonAvailability`).
///
/// Its ids are its own, so no save or reward of Season 1 is ever shared:
/// cases `s2_ep01` … `s2_ep12`, missions `s2_ep01_m1` … `s2_ep01_final`.
const Map<String, dynamic> season2InfoJson = {
  'id': 's2_paris',
  'number': 2,
  'title': 'Paris Stands Still',
  'tagline': 'ONE STOLEN HOUR',
  'city': 'Paris',
  // Twelve cases planned; the season is complete only once all are solved.
  'cases': 12,
  // The next cases' titles, told on the Case Closed file before they are
  // in the game ("CASE 05 · THE SILENT WORKSHOP"); never their content.
  // None now: Case 05 is in the game, and Case 06's title is not settled
  // (its Case Closed says CASE 06 · COMING SOON).
  'upcoming': <String, String>{},
};

/// Season 2's cases in case order, by id. The season is not released yet
/// (see `season2Content`): its cases are played only in an operator
/// build's season preview.
const Map<String, Map<String, dynamic>> season2Json = {
  's2_ep01': season2Episode01Json,
  's2_ep02': season2Episode02Json,
  's2_ep03': season2Episode03Json,
  's2_ep04': season2Episode04Json,
  's2_ep05': season2Episode05Json,
};

/// Season 2's cases written but waiting for their pictures, in case order:
/// never in the game (no case file, board, map or save shows them) until
/// their pictures are, then moved into [season2Json]. None now: Case 05's
/// pictures are in (2026-10-21).
const Map<String, Map<String, dynamic>> season2AwaitingArtJson = {};

/// Season 2's opening sequence, played once before its Case 01: five short
/// scenes and the first case's file. It picks up where Season 1 ended
/// without telling that ending again (Case 12: the Clockmaker is gone; his
/// watch, still ticking, says PARIS on the back). The 11:40 from Paris is
/// the train the Clockmaker came to London on (Case 12, Platform 4): it is
/// named only as his, never as the detective's own train. Who the
/// Clockmaker is, and how the hour is stolen, stay untold.
/// One short message per line (`\n` is where a line breaks on screen).
const Map<String, dynamic> season2PrologueJson = {
  'lastClue': {
    'title': 'THE LAST CLUE',
    'engraving': 'PARIS',
    'lines': ['The Clockmaker is gone.', 'But his watch is still ticking.'],
  },
  'journey': {
    'title': 'THE JOURNEY',
    'from': 'LONDON',
    'to': 'PARIS',
    'lines': ['He came to London\non the 11:40 from Paris.', 'Now you follow him back.'],
  },
  'arrival': {
    'title': 'GARE DU NORD',
    'lines': ['The train pulls into Paris.', 'Look up at the station clocks...'],
  },
  'missingHour': {
    'title': 'THE MISSING HOUR',
    'clocks': ['10:00', '10:00', '9:00'],
    'lines': ['The clocks do not agree.', 'One hour has gone missing.'],
  },
  'promise': {
    'cases': 12,
    'lines': ['Find the stolen hour.', 'Before Paris stands still.'],
  },
  'firstCase': {
    'id': 's2_ep01',
    'number': '01',
    'title': 'The Ticking Watch',
    'place': 'GARE DU NORD',
    'picture': 'pocketWatch',
    'line': 'Your first case in Paris\nbegins at the station.',
  },
};
