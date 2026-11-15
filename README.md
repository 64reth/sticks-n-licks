# Sticks n Licks

Original local two-player Caribbean stick-fighting rhythm prototype. Godot 4.6+, GDScript, 320×180. The supplied Red/Blue artwork and original soundtrack are integrated. No API key or Python installation is required to play; optional missing assets have fallbacks.

## Launch on this Mac

```sh
cd /Users/garethwallen/Projects/sticks-n-licks
/Applications/Godot.app/Contents/MacOS/Godot --editor --path .
```

Press **F5** to launch the playable prototype from any open scene. The root `project.godot` sets `res://scenes/main/main.tscn` as the main scene. **F6** runs only the currently open scene. Develop in this repository directly; do not create a nested project or separate working copy. Direct launch:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

Enter starts Local Versus. H toggles help; F3 toggles the developer overlay; Escape returns to the menu. C on the menu switches the race cue between an accented click and drum cutoff. Enter starts the next round after ROUND WON, or a new match after CHAMPION. Match wins remain visible until rematch/menu.

| Player | Move left/right | High / Low | MID | Race / execute |
|---|---|---|---|---|
| P1 | A / D | W / S | Forward + F | F |
| P2 | Left / Right | Up / Down | Forward + Right Shift | Right Shift |

Forward is facing-relative: initially D for P1 and Left for P2. If facing reverses, the other horizontal key becomes forward. X, standalone MID actions and Enter for P2 combat/race are removed; Enter still starts the menu/rematch.

Wait through the three-count patterns for GO. Early execution forfeits race initiative. Both fighters get sticks; winning the race awards no hit. Reactions within 5 ms tie; tie priority alternates across tied races, starting with P1. A two-second reaction timeout resolves one valid reaction; no reactions or two false starts restart the count. Keyboard hardware may limit simultaneous keys.

Movement is beat-locked on **all four beats (1–4)**. Hold left/right to queue a step for the next boundary; release before that boundary to cancel. A short tap spanning a boundary steps once, while opposing held directions hold position. Countdown/pickup-held directions are retained into combat. Movement uses no ±70/±140 ms precision window and never directly changes positions between boundaries.

Combat requires **direction + execute**, with a 100 ms combination buffer in either order and support for a direction held longer. Up/high or down/low chooses that height; the facing-relative forward key chooses MID. Execute alone never defaults to MID. The execute timestamp determines timing even if its direction arrives later within the combination buffer. ±70 ms is perfect; ±140 ms is valid. A correct perfect block steals initiative; a correct valid block retains the attacker. Incorrect/missing/mistimed defence permits a successful attack to score. A missed attack passes initiative. Three clean hits win a round. Two round wins secure the default best-of-three match.

At beat four the deterministic order is **both held movement steps → collision limits → frozen positions → attack/block adjudication**. A direction+execute combination does not lock movement. Inputs arriving after the boundary cannot add a retroactive step or alter the range snapshot. One combat execution per player per phrase is accepted. Resolution waits for the valid late-input window plus the 100 ms combination allowance. Shared `stick_reach` remains 44 logical pixels to the tip (53-pixel maximum centre gap including the opposing hurtbox). Out-of-range attacks always miss.

The arcade HUD shows RED/BLUE cards, three energy segments, round-win markers, round number, BPM and initiative. Energy is derived from authoritative scored hits against that player. Countdown **3 → 2 → 1 → GO!** follows the final standoff beats; GO is the existing race cue and false starts still forfeit initiative. Temporary player-facing outcomes include HIGH/MID/LOW HIT, BLOCK, PERFECT PARRY and MISS. No raw diagnostic text appears during normal play. H shows controls; F3 switches to input/audio/collision diagnostics.

Three consecutive defended exchanges schedule the next tempo: 120 → 140 → 160 BPM. Hits reset that streak rather than accelerating the music. Values and latency are configurable in `data/combat/settings.json`. Bindings are editable in Project Settings → Input Map.

## Test

```sh
bash tools/check.sh
```

Core Godot checks have no Python dependency. For optional asset checks:

```sh
python3 -m venv .venv
.venv/bin/python -m pip install -r tools/requirements.txt
bash tools/check.sh
```

Open `scenes/tests/rhythm_test.tscn` and press F6 for an interactive rhythm test; keys 1/2/3 schedule 120/140/160 BPM at the next phrase boundary. `scenes/tests/demo.tscn` is a deterministic scripted demonstration, separate from normal gameplay. Capture it with:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . \
  --scene scenes/tests/demo.tscn --fixed-fps 60 \
  --write-movie output/gameplay.avi --quit-after 3000 -- --verify-demo
```

Create `output/` first. The demo injects a simulation clock and artificial player inputs; it is not a recording of human play. It demonstrates parries, tempo escalation, two-round match victory and rematch.

## Assets and development

See [design](docs/design/milestone-001.md), [asset catalogue](docs/assets/catalogue.json), [audio handoff](docs/assets/audio.md), [optional image pipeline](docs/assets/image-pipeline.md), and [verification](docs/verification.md). Studio toolkit scope and workflow adaptations are documented in [AGENTS.md](AGENTS.md).

Milestone 002 uses 19 supplied sheets / 113 extracted native-resolution frames. Originals are preserved; Red and Blue retain their costume colours and native facing. Missing authored hit/outcome states reuse real character poses with feedback. Red's pickup-labelled sheet depicts race poses and is not used as pickup animation. See [Milestone 002 asset report](docs/assets/milestone-002.md).

Eight original WAVs are connected to menu/standoff/combat/victory and developer previews. The owner confirmed beat 1 at sample zero and full-file loop boundaries. These settings are recorded explicitly; output latency and perceptual synchronisation still require listening review.

Open `scenes/tests/animation_preview.tscn` and press F6: Left/Right cycles states, Space pauses, comma/period steps frames, brackets change speed. Open `scenes/tests/audio_test.tscn` and press F6: 1/2/3 independently tests 120/140/160 BPM; Q/W/E/V/D previews menu/standoff/intro/victory/defeat at phrase boundaries. Brackets adjust preview offsets and minus/equals adjusts output compensation (not saved). F5 continues to run the playable root main scene.

The [launch/rendering and stick-range fix](docs/design/rendering-and-stick-range-fix.md) documents the initial-idle transform bug, shared range geometry and actual playable-scene regression evidence. Configure reach in `data/combat/settings.json`; changing artwork or animation callbacks never changes contact rules.

The supplied [Blue idle and movement repair](docs/design/blue-idle-and-movement-repair.md) adds a four-frame looping Blue idle (2172×724 source, native left-facing) for launch and post-action recovery. The new idle source duplicates the existing Blue mid-block sheet; no artwork was regenerated. Run `bash tools/check.sh` for actual engine-event movement regressions as well as existing combat/asset checks.

See [Milestone 003](docs/design/milestone-003.md) for HUD/countdown, best-of-three scoring and the corrected four-beat movement contract. [Actual Godot screenshots](docs/screenshots/milestone-003) are included for review. Historical milestone notes describing beat-four lockout or post-combat movement suppression are superseded.
