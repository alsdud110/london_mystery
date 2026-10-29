# ai_agents — pictures made with OpenAI's Image API

STEP 3-10. Plain Dart (`dart run`, no package beyond the game's, no Python):
nothing here is imported by the game, and the API key never reaches the app.

| File | What |
|---|---|
| `openai_image.dart` | Command line and `ImageStudio`: one request checked, priced, sent once, its PNG checked and written, recorded |
| `image_manifest.dart` | `ImageRequest` (its `key`: what shapes the picture) and `ImageManifest` (`image_manifest.json`) |
| `image_pricing.dart` | List prices (2026-10-29), the estimate before a call, the cost of a response's `usage` |
| `image_styles.dart` | The game's styles as prompt lines (`STYLE_GUIDE.md`) |
| `png_check.dart` | A PNG read whole: signature, every chunk's CRC, IHDR, IEND, the pixels inflated to their size |
| `env_file.dart` | `.env` read (never written); `ApiKey`, never shown, redacted from errors |

Tests: `test/ai_agents/openai_image_test.dart` (no call to OpenAI).

## Use

```sh
# A dry run (the default): the request and its estimated cost, nothing sent or written.
dart run tool/ai_agents/openai_image.dart --style london_scene \
  --prompt "The front desk of a small town library..." --output qa/ai_image_tests/desk.png

# The same, made: one call.
dart run tool/ai_agents/openai_image.dart ... --generate
```

| Option | Default | |
|---|---|---|
| `--prompt` | (required) | what to draw; `--style`'s line is added after it |
| `--output` | (required) | a `.png` in the repository, never in `lib/` or `assets/` |
| `--style` | none | `london_scene`, `paris_scene`, `character`, `object`: sets the size and background too |
| `--model` | `gpt-image-2` | any GPT image model (`gpt-image-2.5-flare`, `gpt-image-1.5`, `gpt-image-1-mini`…) |
| `--size` | the style's, else `1536x1024` | `WxH` (multiples of 16, ≤ 3840, ≤ 3:1) or `auto` |
| `--quality` | `medium` | `low`, `medium`, `high`, `auto` (2.5 models: `xhigh`, `max`) |
| `--background` | the style's, else `auto` | `auto`, `opaque`, `transparent` |
| `--subject` | none | what it shows, for later pictures of it |
| `--reference` | none | a picture to draw from: recorded, refused for now (not sent yet) |
| `--manifest` | `<output's folder>/image_manifest.json` | |
| `--budget-usd` | `0.25` | an estimate above it is not sent |
| `--env` | `.env` | where the key is when the environment has none |
| `--overwrite` | off | write over a file that is there |
| `--generate` | off | send it (without it: a dry run) |

Exit codes: `0` made, already made, or a dry run; `1` the API or its picture
failed (recorded); `2` refused before sending (nothing recorded); `64` usage.

## Rules

- **The key**: the environment's `OPENAI_API_KEY`, else `.env`'s (git
  ignores `.env`). It goes in the request's header only: never printed,
  never in the manifest, and any `sk-…` text in an API error is redacted.
  No key: a dry run says so; `--generate` stops before sending.
- **Cost**: printed before every call, from the list prices and the guide's
  output-token table (an estimate: OpenAI gives gpt-image-2's own counts
  only in its calculator). After a call, the response's `usage` at list
  prices is recorded too. The bill is OpenAI's.
- **Once**: one picture a run, one call, no retry by itself. A failed call
  is recorded; running the command again sends it again (`callNumber`).
- **Never twice**: a request already made (same model, prompt, size,
  quality, background, references), its file still as written, is not sent.
- **Never over a file**: an existing output is kept unless `--overwrite`.
- **Whole or nothing**: the answer's PNG is checked before anything is
  written, written beside its place, read back, then moved there.

## The manifest

```json
{
  "schemaVersion": 1,
  "totals": {"apiCalls": 1, "generated": 1, "failed": 0, "fromUsageUsd": 0.042225},
  "entries": [{
    "key": "sha256:…", "status": "generated", "output": "qa/ai_image_tests/….png",
    "model": "gpt-image-2", "size": "1536x1024", "quality": "medium", "background": "opaque",
    "style": "london_scene", "subject": "s9_sandbox.front_desk", "references": [], "prompt": "…",
    "requestedAt": "…Z", "completedAt": "…Z", "durationMs": 32098, "apiCalled": true, "callNumber": 1,
    "usage": {"input_tokens": 213, "output_tokens": 1372, "…": "…"},
    "cost": {"estimatedUsd": 0.04823, "fromUsageUsd": 0.042225, "note": "…"},
    "file": {"bytes": 3507389, "sha256": "sha256:…", "width": 1536, "height": 1024, "hasAlpha": false, "sizeAsAsked": true}
  }]
}
```

A failed entry has `"status": "failed"` and `"error": {status, type, code, message}`.

## Not yet

- Many pictures in one run: `ImageStudio.run` takes one `ImageRequest`; a
  season's asset list will be a list of them, run in turn (each its own
  entry, the budget for the whole).
- Reference pictures (`/v1/images/edits`), transparent cut-outs (whether
  gpt-image-2 takes `background: transparent` is not checked yet), resizing
  to the game's other sizes, writing into `assets/` and `pubspec.yaml`.
