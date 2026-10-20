import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/season2/paris_case01_draft.dart';
import '../../data/models/clock_puzzle.dart';
import '../../data/models/episode.dart';
import '../../widgets/art_assets.dart';

/// Independently playable development preview. Does not mutate production saves
/// or unlock Paris. Its investigation UI is real; final integration into the
/// season progress/reward pipeline remains a separate step.
class ParisCase01Screen extends StatefulWidget {
  const ParisCase01Screen({super.key});

  @override
  State<ParisCase01Screen> createState() => _ParisCase01ScreenState();
}

class _ParisCase01ScreenState extends State<ParisCase01Screen> {
  final Episode caseFile = Episode.fromJson(parisCase01DraftJson);
  int step = 0;
  int? inspectedClock;
  final Set<int> visited = {};
  final List<String> timeline = [];
  ClockTime clock = ClockTime.at(9, 0);
  final List<String> letters = [];
  bool noticeRead = false;
  bool ticketRead = false;
  String? feedback;

  static const ink = Color(0xFF22313D);
  static const paper = Color(0xFFF4EBD9);
  static const gold = Color(0xFFAD864D);

  void advance() => setState(() { feedback = null; step++; });
  void restart() => setState(() {
    step = 0; inspectedClock = null; visited.clear(); timeline.clear();
    clock = ClockTime.at(9, 0); letters.clear();
    noticeRead = false; ticketRead = false; feedback = null;
  });
  void wrong(String message) => setState(() => feedback = message);

  Widget button(String title, VoidCallback? action) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: action,
      style: FilledButton.styleFrom(
        backgroundColor: ink, foregroundColor: paper,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(title, style: const TextStyle(letterSpacing: 1.4)),
    ),
  );

  Widget sheet(String title, Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: paper,
      border: Border.all(color: gold.withValues(alpha: .55)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: ink)),
      const SizedBox(height: 12),
      child,
    ]),
  );

  Widget line(String s) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(s, style: const TextStyle(color: ink, fontSize: 16, height: 1.5)),
  );

  Widget picture() => ClipRRect(
    borderRadius: BorderRadius.circular(9),
    child: AspectRatio(
      aspectRatio: 1.5,
      child: Image.asset(
        ArtAssets.season2GareDuNord,
        fit: BoxFit.cover,
        alignment: const Alignment(0.35, -.2),
        errorBuilder: (_, _, _) => const ColoredBox(
          color: ink, child: Center(child: Text('GARE DU NORD', style: TextStyle(color: paper))),
        ),
      ),
    ),
  );

  Widget title(String number, String name) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(number, style: const TextStyle(color: gold, fontSize: 12, letterSpacing: 3)),
      const SizedBox(height: 5),
      Text(name, style: const TextStyle(color: ink, fontSize: 27, fontWeight: FontWeight.bold)),
      const SizedBox(height: 15),
    ],
  );

  Widget intro() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    picture(), const SizedBox(height: 20),
    title('PARIS · CASE 01', caseFile.title),
    for (final s in caseFile.intro) line(s),
    const SizedBox(height: 12),
    sheet('THE CASE FILE', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final s in caseFile.objectives) line('• $s')],
    )),
    const SizedBox(height: 22),
    button('BEGIN INVESTIGATION', advance),
  ]);

  Widget missionOne() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    title('MISSION 01', 'The Three Clocks'),
    picture(), const SizedBox(height: 14),
    line('Two clocks show 10:00. One shows 9:00. Tap each clock to inspect it.'),
    Wrap(spacing: 9, runSpacing: 9, children: [
      for (var i = 0; i < 3; i++)
        OutlinedButton(
          onPressed: () => setState(() { inspectedClock = i; visited.add(i); }),
          style: OutlinedButton.styleFrom(
            foregroundColor: ink,
            backgroundColor: inspectedClock == i ? gold.withValues(alpha: .25) : paper,
          ),
          child: Text(['PLATFORM · 10:00', 'HALL · 10:00', 'OLD · 9:00'][i]),
        ),
    ]),
    const SizedBox(height: 14),
    if (inspectedClock != null) sheet('INSPECTION', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        line(inspectedClock == 2
          ? 'The oldest clock reads 9:00. A brass mark is scratched beneath it.'
          : 'This clock reads 10:00. Its hands are moving normally.'),
      ],
    )),
    const SizedBox(height: 14),
    sheet('STATION NOTICE', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      line(caseFile.missions[0].letter),
      TextButton(
        onPressed: () => setState(() => noticeRead = true),
        child: Text(noticeRead ? 'NOTICE READ ✓' : 'READ THE NOTICE'),
      ),
    ])),
    const SizedBox(height: 14),
    if (visited.length == 3 && noticeRead) ...[
      line('Which clock is one hour behind?'),
      button('REPORT THE OLD CLOCK', () { advance(); }),
    ] else line('Inspect all three clocks and read the notice.'),
  ]);

  Widget missionTwo() {
    const labels = ['The hall clock struck ten', 'The man entered the waiting room', 'The old clock showed nine'];
    const ids = ['bell', 'man', 'old'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      title('MISSION 02', 'The Lost Ticket'),
      sheet('STATION WORKER’S NOTE', line(caseFile.missions[1].letter)),
      const SizedBox(height: 12),
      sheet('LOST TRAIN TICKET', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        line('A folded ticket has a tiny letter I stamped on its back.'),
        TextButton(onPressed: () => setState(() => ticketRead = true),
          child: Text(ticketRead ? 'TICKET EXAMINED ✓' : 'TURN OVER THE TICKET')),
      ])),
      const SizedBox(height: 14),
      line('Tap the events in the order described in the note.'),
      for (var i = 0; i < ids.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            onPressed: timeline.contains(ids[i]) ? null : () => setState(() => timeline.add(ids[i])),
            child: SizedBox(width: double.infinity, child: Text(labels[i])),
          ),
        ),
      if (timeline.isNotEmpty) line('YOUR ORDER: ${timeline.join(' → ')}'),
      TextButton(onPressed: () => setState(timeline.clear), child: const Text('RESET ORDER')),
      if (feedback != null) line(feedback!),
      button('CHECK THE TIMELINE', timeline.length != 3 || !ticketRead ? null : () {
        if (timeline.join(',') == caseFile.missions[1].answer) {
          advance();
        } else {
          wrong('Read FIRST, NEXT, and AFTER THAT again.');
        }
      }),
    ]);
  }

  Widget missionThree() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    title('MISSION 03', 'The Clockmaker’s Mark'),
    sheet('ENGRAVED INSTRUCTIONS', line(caseFile.missions[2].letter)),
    const SizedBox(height: 14),
    Center(child: Text(clock.label, style: const TextStyle(color: ink, fontSize: 44, fontWeight: FontWeight.bold))),
    const SizedBox(height: 8),
    Center(child: SizedBox(
      width: 240, height: 240,
      child: Stack(alignment: Alignment.center, children: [
        Container(decoration: BoxDecoration(shape: BoxShape.circle, color: paper, border: Border.all(color: gold, width: 5))),
        for (var i = 1; i <= 12; i++)
          Transform.translate(
            offset: Offset(
              91 * -sinDegrees(i * 30),
              91 * -cosDegrees(i * 30),
            ),
            child: Text('$i', style: const TextStyle(color: ink, fontSize: 13)),
          ),
        Transform.rotate(angle: clock.hourDegrees * 3.141592653589793 / 180,
          child: Align(alignment: Alignment.center, child: Container(width: 5, height: 92,
            margin: const EdgeInsets.only(bottom: 46), color: ink))),
        Transform.rotate(angle: clock.minuteDegrees * 3.141592653589793 / 180,
          child: Align(alignment: Alignment.center, child: Container(width: 3, height: 130,
            margin: const EdgeInsets.only(bottom: 65), color: gold))),
        const CircleAvatar(radius: 6, backgroundColor: ink),
      ]),
    )),
    const SizedBox(height: 10),
    line('Turn the minute hand forward. Every full turn advances one hour.'),
    Row(children: [
      Expanded(child: OutlinedButton(
        onPressed: () => setState(() => clock = clock.plusMinutes(-15)),
        child: const Text('− 15 MIN'))),
      const SizedBox(width: 10),
      Expanded(child: OutlinedButton(
        onPressed: () => setState(() => clock = clock.plusMinutes(15)),
        child: const Text('+ 15 MIN'))),
    ]),
    const SizedBox(height: 12),
    if (feedback != null) line(feedback!),
    button('SET THE TIME', () {
      if (clock == ClockTime.at(10, 0)) { advance(); }
      else { wrong('The hall clock reads ten. Move the old clock forward one hour.'); }
    }),
  ]);

  Widget finalPuzzle() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    title('FINAL MISSION', 'The Hidden Compartment'),
    sheet('THE CLOCKMAKER’S LOCK', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      line('WHAT WAS STOLEN FROM PARIS?'),
      line('The old clock gave T. The ticket gave I. The dial gave M. The latch gives E.'),
    ])),
    const SizedBox(height: 18),
    Center(child: Wrap(spacing: 8, children: [
      for (var i = 0; i < 4; i++)
        Container(width: 52, height: 62, alignment: Alignment.center,
          decoration: BoxDecoration(color: paper, border: Border.all(color: gold, width: 2)),
          child: Text(i < letters.length ? letters[i] : '—',
            style: const TextStyle(fontSize: 29, color: ink))),
    ])),
    const SizedBox(height: 18),
    Center(child: Wrap(spacing: 10, children: [
      for (final letter in const ['M', 'E', 'T', 'I'])
        OutlinedButton(
          onPressed: letters.contains(letter) ? null : () => setState(() => letters.add(letter)),
          child: Text(letter, style: const TextStyle(fontSize: 23)),
        ),
    ])),
    TextButton(onPressed: () => setState(letters.clear), child: const Text('CLEAR LETTERS')),
    if (feedback != null) line(feedback!),
    const SizedBox(height: 16),
    button('OPEN THE COMPARTMENT', letters.length < 4 ? null : () {
      if (letters.join() == caseFile.finalMission.answer) { advance(); }
      else { wrong('The word names what the clocks lost. Read the engraving again.'); }
    }),
  ]);

  Widget solved() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    picture(), const SizedBox(height: 18),
    title('CASE CLOSED', 'The Ticking Watch'),
    sheet('DETECTIVE REPORT', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      line('You found the clock that was one hour behind.'),
      line('You followed the station worker’s timeline.'),
      line('You restored the time and opened the hidden compartment.'),
      const Divider(),
      line('Inside: a charcoal sketch of a hill in Paris.'),
      line('On its back: FIND THE PAINTER.'),
      line('NEXT CASE · THE PAINTER’S SKETCH · MONTMARTRE'),
    ])),
    const SizedBox(height: 18),
    button('PLAY AGAIN', restart),
    TextButton(onPressed: () => context.go('/seasons'), child: const Text('BACK TO ARCHIVES')),
  ]);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFE9DFCB),
    appBar: AppBar(
      backgroundColor: ink, foregroundColor: paper,
      title: Text(step == 5 ? 'CASE CLOSED' : 'PARIS · CASE 01',
        style: const TextStyle(fontSize: 15, letterSpacing: 2)),
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {
        if (step == 0) { context.go('/seasons'); }
        else { setState(() { step--; feedback = null; }); }
      }),
    ),
    body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LinearProgressIndicator(value: step / 5, color: gold, backgroundColor: ink.withValues(alpha: .1)),
        const SizedBox(height: 20),
        switch (step) {
          0 => intro(),
          1 => missionOne(),
          2 => missionTwo(),
          3 => missionThree(),
          4 => finalPuzzle(),
          _ => solved(),
        },
        const SizedBox(height: 40),
      ],
    )),
  );
}

double sinDegrees(int degrees) {
  const sin = <int, double>{0: 0, 30: .5, 60: .8660254, 90: 1, 120: .8660254,
    150: .5, 180: 0, 210: -.5, 240: -.8660254, 270: -1, 300: -.8660254, 330: -.5, 360: 0};
  return sin[degrees % 360] ?? 0;
}

double cosDegrees(int degrees) => sinDegrees(degrees + 90);
