# Optional OpenAI image pipeline

The studio kit has no image generation integration. These project-local tools use the official OpenAI Python SDK and Pillow and are not required by Godot. No paid images have been generated for this implementation.

## Setup and single-image test

```sh
python3 -m venv .venv
.venv/bin/python -m pip install -r tools/requirements.txt
.venv/bin/python tools/openai_images.py --prompt-file tools/single_image_prompt.txt
```

The last command is an offline dry run. It prints the exact request, reference hash, model, output estimate, reservation and approval ID. It needs no API key and sends no request. Read that result and obtain explicit user approval before passing its ID to `--approve-single ID`. Changing the prompt/reference/request settings changes the approval ID. Each approval ID can be consumed only once, even if count/budget limits are later increased. Never infer approval from a previous request. No paid batch command is implemented; adding one requires explicit approval and a reviewed request/cost list.

For an approved live request only, create a funded OpenAI API project/key (organization verification may be required). Set `OPENAI_API_KEY` locally in the terminal; do not put the value in chat, shell scripts, Godot settings or Git. The SDK reads it from the environment. Prefer a terminal secret manager or a silent shell prompt. The adapter never prints the key and disables automatic API retries.

The enabled model is `gpt-image-1.5`, using `images.generate` or reference-guided `images.edit` with high input fidelity. It requests one 1024×1024 transparent PNG at explicit low/medium/high quality. This model supports image generation, editing and alpha output. Character identity, pixel alignment and exact frame layouts remain imperfect; passing a prompt does not validate a sprite sheet. The model profile is deliberately constrained to verified supported settings; expanding it requires updating capabilities and price validation.

Official references, checked 2026-11-15:
- https://developers.openai.com/api/docs/guides/image-generation
- https://developers.openai.com/api/docs/models/gpt-image-1.5

Published 1024-square output prices are $0.009 low, $0.034 medium and $0.133 high, plus prompt/reference input. Text input is $5/million tokens, image input $8/million and image output $32/million. Recheck pricing before a paid request. Medium is the default; default lifetime limits are one request and $0.10 reserved spending. High quality requires raising both reserve and budget explicitly.

`tools/image_config.json` configures prompt/reference limits, count, budget and per-request reservation. Reservations are checked under a file lock before dispatch, including failures with unknown billing. `assets/generated/cost_ledger.json` tracks reserved spend, SDK usage and estimated token cost where supplied. Provider billing is authoritative: the local reservation is an estimate, not a guaranteed server-side dollar cap. Set provider project limits as well. Do not reset the ledger to bypass approvals or hide spend.

## Approved reference editing

Preserve the source image. After explicit approval, add its project-relative path and SHA256 to `approved_references` in the config. Generate the hash with `shasum -a 256 PATH`. Pass `--reference PATH` during the dry run and review the exact proposal before a live edit. The adapter verifies the reference hash again before dispatch. The supplied file in `references/` is catalogued but is not yet registered as approved.

Each live request gets a unique new directory under `assets/generated/` with untouched `original.png`, request/response metadata and a manifest: animation, expected frames, source reference/hash, files and validation status. Use `--animation idle --expected-frames 8` to declare the intended animation. Original image bytes are never resized or quantised. Failed requests retain their spending reservation. Existing approved art cannot be overwritten by this adapter.

## Validation, slicing and Godot

```sh
.venv/bin/python tools/assets.py path/to/sheet.png --frames 8
.venv/bin/python tools/assets.py path/to/sheet.png --frames 8 \
  --animation idle --export assets/characters/fighter_01/frames/idle_v001 \
  --reference references/approved-character.png
```

Default cells are 96×96. `--cell WIDTH HEIGHT` supports deliberate alternative grids. Validation checks actual PNG/RGBA, transparent+opaque pixels, exact dimensions/frame count, empty frames, occupied cell edges, binary pixel-art alpha, palette size and silhouette size drift. It reports each frame's bounds and source SHA256. No resizing, palette reduction or automatic alpha thresholding occurs. Generated concept art may fail these strict tests; preserve it and author a new derived sprite sheet explicitly.

Successful slicing copies frame pixels losslessly into individual RGBA PNGs and writes a manifest plus a Godot `SpriteFrames` `.tres`. Destination must be a new directory inside this project. Visual/identity approval remains required even after technical validation. The two placeholder idle exports demonstrate this pipeline.

After visual approval, add animation name → project-relative `.tres` path to `data/animations/fighter_01.json` or `fighter_02.json`. Godot merges it with fallback states. Check the referenced manifest and source hash first; never silently replace an approved mapping. The resource loader is not an approval authority. There are no final approved art mappings yet.
