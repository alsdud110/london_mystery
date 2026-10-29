# World Mystery — picture style guide

Read from the game's own pictures (`assets/`, 284 files) on 2026-10-29, for
pictures made by `openai_image.dart`. The style lines a prompt gets are
`image_styles.dart`'s; this page is why they say what they say. No existing
picture is changed or made again from it.

## What the game's pictures are

| Kind | Sizes in the game | Background | Look |
|---|---|---|---|
| Scene (a place, full frame) | 1536×1024 (most: 72 of Paris's, 15 of London's), some 1024×1536 | opaque | per season, below |
| Character | 1122×1402, 1254×1254 | plain aged parchment (not transparent, though some files carry an alpha channel) | ink linework, colour washes, three-quarter view, head to below the waist |
| Object, evidence | 1024×1024, 1254×1254 | plain parchment, the object centred | ink linework, colour washes, soft shading |
| Badge, detective, UI art | 1254×1254 and others, often RGBA | transparent | not made by this tool yet |

The GPT image models make 1024×1024, 1536×1024 and 1024×1536 natively: the
game's scene size is one of them, so scenes need no resizing.

## The two seasons' scenes

**London (`london_scene`)** — hand-inked pen lines with soft watercolour
washes on aged parchment; sepia and ochre, with muted teal, green and
burgundy accents; clear architectural perspective; framed like an old
postcard (a thin inked border, worn paper edges). Night scenes keep the
ink and add deep blue skies and warm lamp light (King's Cross platform).

**Paris (`paris_scene`)** — impressionist oil painting: thick, broken,
mosaic-like impasto strokes; golden late-afternoon light and long shadows;
honey, amber, umber and soft sky blue; full bleed, no border.

**Rome (`rome_scene`, STEP 3-12A)** — London's hand: pen lines and soft
watercolour washes, on warm cream paper, lightly stylised like a travel
sketchbook; Rome's colours (terracotta, ochre, travertine cream,
umbrella-pine green, soft sky blue) and warm Mediterranean sun with gentle
shadows; full bleed, no border, so it never reads as London's postcards.
A later season adds its own scene style the same way (here, or in its
manifest's `seasonStyles`), never changing another season's.

## Every picture

- For children of 8 to 12: warm and gently mysterious, never frightening.
- No text, letters or numbers in a picture: the game writes its own words
  over pictures, in English, and a model's lettering is often misspelt
  (London's Great Court picture shows it). Signs and labels stay blank.
- Restrained: the mood comes from light and paper, not from decoration
  (the project's design rules, `CLAUDE.md` §4).

## The same character or place again

A request names what it shows (`--subject`, as `s9_sandbox.front_desk` or
`s3_rome.char.guide`) and the manifest keeps it with the picture's hash.
A later picture of the same subject is to be drawn from that one
(`--reference`, the image edits endpoint): sent since STEP 3-12A, and
`tool/asset_pipeline` makes every reference before the pictures drawn from it.

## The STEP 3-10 test picture

`qa/ai_image_tests/s9_front_desk_test.png`: the sandbox's Town Library front
desk (Case 01 and 02's place), in `london_scene`, gpt-image-2, medium. It
kept the London look (ink, washes, parchment, postcard border) on the first
try; its visitor book's pages stayed free of writing.
