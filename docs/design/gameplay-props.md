# Ground sticks and resolved combat impacts

Integration on `development`, following Milestone 006 and preserving the working-tree tutorial work. No fighter artwork, original PNG, combat rule, CPU planner, pickup/race rule, movement window or audio timing was changed.

## Source inspection and presentation

The four owner-supplied originals live in `assets/environments/props/`. Each is RGBA, 2172×724, containing three horizontal 724×724 cells. `docs/assets/gameplay-props.json` records SHA-256, exact cell rectangles, alpha bounds and transparency counts. These are irregular soft-alpha source images, not strict 96px sheets. All have 256 alpha levels; ground sticks have only 2,909 fully transparent pixels across the whole sheet. Inspection found faint background haze and speckles, particularly on ground sticks. A shared canvas shader discards alpha below 0.5 and renders retained source colors opaque. This is presentation only; there are no derivative PNGs, destructive edits or resampling of sources. Imports are lossless without mipmaps; both components select nearest filtering.

`GroundSticks` renders a 48px square cell centred at the existing (160,135) ground-stick anchor; the visible sticks occupy about 30px. Source cell 0 is crossed, cell 1 rises from the left fighter towards centre (LEFT_ONLY), and cell 2 descends towards the right fighter (RIGHT_ONLY). Collected flags are interpreted by ownership: left collected -> RIGHT_ONLY; right collected -> LEFT_ONLY; both -> NONE. Positions and collision remain untouched.

The pre-existing gameplay has no separate distance-triggered pickup inventory. An accepted race reaction commits that fighter to run and collect. Race reactions therefore drive individual removal during the race. After race adjudication the existing `pickup` phase explicitly makes **both** fighters collect, including a player who missed their reaction or forfeited. Both sticks hide at that transition. Neither input before timeout restarts the standoff with both sticks. Ties use the existing alternating initiative rule; round/rematch reset restores crossed sticks. This integration deliberately preserves those gameplay semantics.

## Authoritative effects

One reusable `ImpactEffect` sprite preloads the three sheets. `main.resolve_exchange()` submits `Bout.last_event` only after rule adjudication. HIT maps to orange, BLOCK to cyan, and PARRY to the gold-white perfect-parry sheet. WHIFF, missing actions and non-overlapping geometry do not spawn an effect. A match/round/phrase key and the existing scene/rule resolution guards prevent duplicate spawning. The old procedural parry cross is disabled; the parry pose remains unchanged.

Contact is the centre of the resolved attack-region/hurtbox intersection, using the beat-four frozen geometry already published by Bout. Position rounds to integer pixels and clamps the full square frame inside the 320×180 viewport. Effect canvas sizes are 32px hit/block and 36px parry. `data/impacts.json` exposes frame durations: HIT 55ms (165ms total), BLOCK 50ms (150ms), PARRY 70ms (210ms). Each frame occupies exactly one third of its source sheet. The conductor clock drives frame selection and cleanup, so pausing freezes effects. Starting a new round clears them. A new resolved effect safely replaces the current one without allocating another node. No completion signal, particle callback or animation callback reaches gameplay.

## Verification and reproduction

Run `bash tools/check.sh`. The new `tests/test_gameplay_props.gd` tests pickup ownership in both orders, missed reactions, ties at 0/4/6ms, false starts, automatic pickup, round/rematch reset, all three effects at all three heights with either attacker, duplicate suppression, frame progression/cleanup, safe replacement, pause behavior, no extra damage/initiative changes, missing/out-of-range attacks, and a legal seeded CPU match. `tests/test_gameplay_props_assets.py` verifies original hashes, transparency, cell bounds and import settings. The media regression now expects parry's sprite effect to own feedback instead of the old procedural cross.

Native graphical verification / continuous recording:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . \
  --log-file output/props-gallery.log --fixed-fps 60 \
  --write-movie output/gameplay-props.avi \
  --script tests/test_gameplay_props.gd
```

This opens the real OpenGL Godot player, captures `output/props-*.png`, and records a continuous AVI. The opening section uses explicit fixture state and timestamps to show both pickup orders and all impact frames. The second section starts a fresh production CPU match: Red is the test-only RhythmTestPlayer using `submit_action`, Blue is the production seeded hard CPU (seed 7000), with no position/selection overrides after `begin`. The injected clock and synthetic actions are test-only. This is **not physical keyboard playtesting**. Recording artifacts stay in ignored `output/`, never in the commit.

Screenshots inspected: `props-both`, `props-left-only`, `props-right-only`, `props-none`; all three frames of `props-hit`, `props-block`, `props-parry`; and `props-cpu-hit`, `props-cpu-block`, `props-cpu-parry`. Ground sticks are anchored with no background rectangle; impacts follow high/mid/low contact at Y=98/118/138 and remain readable against the stage. The normal block is cyan and the parry gold-white. No visual clipping was observed in these captures. Native capture is 320×180 at 60 FPS.

## Measured results (2026-11-16)

`bash tools/check.sh` exited 0. Rule 51, input 46, media 3,348, launch/range 974, idle/movement 676, HUD 189, live movement 168, Milestone 006 292, and new gameplay props 166 checks all passed. CPU fairness/replay regression passed **1,795,853 checks across 900 measured matches**, with no changes to planner or rules. The legal CPU demo produced 8 HIT / 4 BLOCK / 1 PARRY / 3 WHIFF events and completed a match. The new integration match produced 13 successful visual events. All 25 Python tests passed. The preserved in-progress tutorial suite also passed 249 checks; its source and check-runner addition remain outside this commit.

The final native recording passed all 166 integration checks: **3,181 frames at 60 FPS, 53.017 seconds, 320×180 Motion JPEG AVI**. The file is `output/gameplay-props.avi`. Reviewed screenshots are committed under `docs/screenshots/gameplay-props/`. `gameplay-props-evidence.json` records measured counts and the recording hash. Existing macOS certificate diagnostics and ObjectDB exit warnings remain in the Godot logs; no script/parse/load failures or regression failures were observed in the successful full run.
