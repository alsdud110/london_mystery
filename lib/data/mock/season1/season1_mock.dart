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

/// Season 1 as a whole: what the casebook and the investigation board say.
///
/// `figures` is who is behind the cases, revealed on the board only after
/// the case that names it in the story is solved:
/// - Case 02: a raven is stamped on the gear — "Who are the ravens?" (hook)
/// - Case 04: the final answer is RAVEN — the Raven Society signs its letter
/// - Case 05: "At midnight, the Clockmaker will stop London." (hook)
/// - Case 12: the Clockmaker is gone; his pocket watch is left behind
///
/// Never named here: Inspector Grey, Miss Rose / Mrs Robin, the Shadow's
/// part, or where the watch points (the Season 2 hook stays in Case 12).
const Map<String, dynamic> season1InfoJson = {
  'number': 1,
  'title': 'Shadows over London',
  'tagline': 'ONE MYSTERY',
  // The season's opening sequence, played once before Case 01: the mood of
  // the season only — kinds of trouble, never a case's answer or a person.
  // One short message per scene (`\n` is where a line breaks on screen).
  'prologue': {
    'city': 'Something strange is happening\nacross the city.',
    'cases': [
      'Treasures have vanished.',
      'Secret letters have appeared.',
      'Doors have been found locked.',
      'And strangers are hiding secrets.',
    ],
    'separate': ['They look like separate cases.', 'But a great detective\nlooks closer.'],
    'question': "What if they're connected?",
    'bigger': 'Every clue could be part\nof something bigger.',
    'promise': ['Follow the clues.', 'Find the connection.', 'Discover the truth.'],
    // The first case's file, handed over at the end: the picture of what is
    // missing (Case 01's own opening line says the Crown is gone).
    'firstCase': {'picture': 'crown', 'line': 'Your first investigation\nbegins tonight.'},
  },
  'outro': ['All the pieces have come together.', 'But this is not the end...'],
  'figures': [
    {'after': 'ep02', 'figure': 'ravens', 'label': 'Who are the ravens?'},
    {'after': 'ep04', 'figure': 'ravenSociety', 'label': 'The Raven Society'},
    {'after': 'ep05', 'figure': 'clockmaker', 'label': 'The Clockmaker'},
    {'after': 'ep12', 'figure': 'clockmakerWatch', 'label': 'The Clockmaker'},
  ],
};

/// Season 1 cases after Case 01 (The Missing Crown), in case order.
///
/// Season thread: a small raven is found on the evidence of every case. The
/// ravens are the Raven Society, and the Society takes its orders from
/// someone called the Clockmaker (Case 12).
const Map<String, Map<String, dynamic>> season1Json = {
  'ep02': episode02Json,
  'ep03': episode03Json,
  'ep04': episode04Json,
  'ep05': episode05Json,
  'ep06': episode06Json,
  'ep07': episode07Json,
  'ep08': episode08Json,
  'ep09': episode09Json,
  'ep10': episode10Json,
  'ep11': episode11Json,
  'ep12': episode12Json,
};
