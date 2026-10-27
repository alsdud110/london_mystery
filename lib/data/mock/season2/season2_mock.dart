import '../../models/difficulty.dart';
import 'episode01_mock.dart';
import 'episode02_mock.dart';
import 'episode03_mock.dart';
import 'episode04_mock.dart';
import 'episode05_mock.dart';
import 'episode06_mock.dart';
import 'episode07_mock.dart';
import 'episode08_mock.dart';
import 'episode09_mock.dart';
import 'episode10_mock.dart';
import 'episode11_mock.dart';
import 'episode12_mock.dart';

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
  // None now: all twelve cases are in the game (Cases 11–12, 2026-10-27).
  'upcoming': <String, String>{},
  // Once every case is solved: the season's last words (the board, and the
  // last case's report).
  'outro': ['The hour was never gone.', 'The truth was waiting to be found.'],
  'finale': ['Paris did not lose an hour.', 'The truth is safe now.'],
  // Who was behind it: told on the board only once Case 12 shows it.
  'figures': [
    {'after': 's2_ep12', 'figure': 'emile', 'label': 'The Clockmaker'},
  ],
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
  's2_ep06': season2Episode06Json,
  's2_ep07': season2Episode07Json,
  's2_ep08': season2Episode08Json,
  's2_ep09': season2Episode09Json,
  's2_ep10': season2Episode10Json,
  's2_ep11': season2Episode11Json,
  's2_ep12': season2Episode12Json,
};

/// Season 2's cases written but waiting for their pictures, in case order:
/// never in the game (no case file, board, map or save shows them) until
/// their pictures are, then moved into [season2Json]. None now: Cases 11–12's
/// pictures are in (2026-10-27).
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
  // The case (an hour is missing), the mystery (who took it, and why) and
  // the goal: the player's own words for it, as Case 02's painter says
  // ("I saw who took the hour"). What the hour really is stays untold.
  'missingHour': {
    'title': 'THE MISSING HOUR',
    'clocks': ['10:00', '10:00', '9:00'],
    'lines': ['One hour is missing in Paris.', 'Who took it? And why?'],
  },
  'promise': {
    'cases': 12,
    'lines': ['Follow the clues. Find out who took the hour.', 'Bring it back before Paris stands still.'],
  },
  'firstCase': {
    'id': 's2_ep01',
    'number': '01',
    'title': 'The Ticking Watch',
    'place': 'GARE DU NORD',
    'picture': 'pocketWatch',
    'line': 'Your first clue is waiting\nat the station.',
  },
};

/// [season2PrologueJson]'s spoken lines at Junior and Master (Rookie is the
/// base itself). Only the lines change: every title, PARIS, the ticket, the
/// clocks' times, the promise's numbers and the first case stay the base's,
/// and each line tells the same thing at the same moment.
const Map<Difficulty, Map<String, dynamic>> season2PrologueLevelsJson = {
  Difficulty.junior: {
    'lastClue': {
      'lines': ['The Clockmaker has disappeared.', 'But his pocket watch is still ticking.'],
    },
    'journey': {
      'lines': ['He came to London\non the 11:40 train from Paris.', 'Now it is your turn to follow him back.'],
    },
    'arrival': {
      'lines': ['Your train slowly pulls into Paris.', 'Look up at the clocks in the station...'],
    },
    'missingHour': {
      'lines': ['An hour has gone missing in Paris.', 'Who took it, and why?'],
    },
    'promise': {
      'lines': ['Follow the clues and find out who took the hour.', 'Bring it back before Paris stands still.'],
    },
    'firstCase': {'line': 'Your first clue is waiting\nfor you at the station.'},
  },
  Difficulty.master: {
    'lastClue': {
      'lines': ['The Clockmaker has vanished.', 'Yet his pocket watch ticks on.'],
    },
    'journey': {
      'lines': ['He travelled to London\non the 11:40 from Paris.', 'Now you must follow his trail back.'],
    },
    'arrival': {
      'lines': ['The train glides into Paris at last.', 'Raise your eyes to the station clocks...'],
    },
    'missingHour': {
      'lines': ['An hour has quietly vanished from Paris.', 'Who took it — and for what reason?'],
    },
    'promise': {
      'lines': ['Follow every clue. Uncover who took the hour.', 'Restore it before Paris stands still.'],
    },
    'firstCase': {'line': 'Your first clue awaits you\nat the station.'},
  },
};

/// [season2PrologueJson] at [level]: each scene's words looked for along
/// the level's [Difficulty.fallbackChain], then the base's.
Map<String, dynamic> season2PrologueAt(Difficulty level) => {
  for (final MapEntry(:key, :value) in season2PrologueJson.entries)
    key: {
      ...(value as Map<String, dynamic>),
      for (final d in level.fallbackChain.reversed) ...?(season2PrologueLevelsJson[d]?[key] as Map<String, dynamic>?),
    },
};
