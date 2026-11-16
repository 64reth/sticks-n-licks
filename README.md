# Sticks n Licks

Original Caribbean stick-fighting rhythm prototype with Player vs CPU and local two-player modes. Godot 4.6+, GDScript, 320×180. The supplied Red/Blue artwork and original soundtrack are integrated. No API key or Python installation is required to play; optional missing assets have fallbacks.

## Launch on this Mac

```sh
cd /Users/garethwallen/Projects/sticks-n-licks
/Applications/Godot.app/Contents/MacOS/Godot --editor --path .
```

Press **F5** to launch the playable prototype from any open scene. The root `project.godot` sets `res://scenes/main/main.tscn` as the main scene. **F6** runs only the currently open scene. Develop in this repository directly; do not create a nested project or separate working copy. Direct launch:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

The menu defaults to **Player vs CPU / Normal**. **M** toggles CPU/PvP; **P** selects PvP immediately; **Left/Right** selects Easy/Normal/Hard in the CPU menu. **Enter** starts. Red is Player 1; Blue is CPU in single-player, with P2 keyboard input disabled during that match. H toggles help; F3 toggles the developer overlay; Escape returns to the menu. C on the menu switches the race cue between an accented click and drum cutoff. Enter starts the next round after ROUND WON, or a new match after CHAMPION. Match wins remain visible until rematch/menu.

| Player | Move left/right | High / Low | MID | Race / execute |
|---|---|---|---|---|
| P1 | A / D | W / S | Forward + F | F |
| P2 | Left / Right | Up / Down | Forward + Right Shift | Right Shift |

Forward is facing-relative: initially D for P1 and Left for P2. If facing reverses, the other horizontal key becomes forward. X, standalone MID actions and Enter for P2 combat/race are removed; Enter still starts the menu/rematch.

Wait through the three-count patterns for GO. Early execution forfeits race initiative. Both fighters get sticks; winning the race awards no hit. Reactions within 5 ms tie; tie priority alternates across tied races, starting with P1. A two-second reaction timeout resolves one valid reaction; no reactions or two false starts restart the count. Keyboard hardware may limit simultaneous keys.

Movement uses deliberate **taps on beats 1–4**. Each new left/right press is graded against the nearest conductor beat: PERFECT ±90 ms, GOOD ±160 ms, otherwise MISS. Early valid taps wait for their boundary; late valid taps execute immediately within that beat's window. Release and press again to move again: holding and OS key-repeat never repeat steps. Each fighter gets at most one step per beat. Misses do not move, walk, drain energy or change initiative. These separate movement windows are configurable in `data/combat/settings.json`; combat timing remains ±70/±140 ms. Precombat holds do not move when combat begins.

Combat requires **direction + execute**, with a 100 ms combination buffer in either order and support for a direction held longer. Up/high or down/low chooses that height; the facing-relative forward key chooses MID. Execute alone never defaults to MID. The execute timestamp determines timing even if its direction arrives later within the combination buffer. ±70 ms is perfect; ±140 ms is valid. A correct perfect block steals initiative; a correct valid block retains the attacker. Incorrect/missing/mistimed defence permits a successful attack to score. A missed attack passes initiative. Three clean hits win a round. Two round wins secure the default best-of-three match.

At beat four the deterministic order is **accepted movement → collision limits → frozen positions → attack/block adjudication**. The range snapshot closes after the ±160 ms movement window (including positive latency compensation), before the existing combat/combination grace finishes. This admits legal late steps without changing an evaluated range. A horizontal press can independently qualify for movement and a direction+execute combat chord. Holding a direction still supports combat selection. Shared `stick_reach` remains 44 logical pixels (53-pixel maximum centre gap including hurtbox).

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


Milestone 004 uses two existing approved walk poses, non-looping over 160 ms, with displacement completing over the same interval. Combat reactions may take visual priority. Compact PERFECT STEP / GOOD STEP / MISS feedback appears per fighter. F3 includes input time, target beat, millisecond error, grade, executed status and logical/rendered X. `-- --movement-trace` exports the bounded input trace to `output/movement-trace.json` after running the checks once to create `output/`.

Stage 01 and Stage 02 are configured in `data/stages.json`; change `default` or press **F4** to switch in place. Both native 1672×941 RGB PNGs fill the 320×180 viewport proportionally with nearest filtering. Stage 02's extensionless original is retained beside a byte-identical importable PNG. The fighting baseline remains Y=150. See [Milestone 004 evidence](docs/design/milestone-004.md).


Milestone 005 adds the seeded rhythm-aware CPU. Difficulty parameters are in `data/cpu.json`. Reproduce an opponent with `/Applications/Godot.app/Contents/MacOS/Godot --path . -- --cpu-seed=7000 --cpu-difficulty=hard`. Identical seeds reproduce relative CPU decisions for identical public match/input timelines, not fixed wins. Rematch resets the seed and learned tendencies; next round retains match learning but clears queued actions. F3 adds behaviour, distance, choice, intended beat, timing, outcome, weights, commitment and seed. F4 still switches stages.

See [CPU architecture, measured results and recording instructions](docs/design/milestone-005.md). `bash tools/check.sh` includes 900 seeded matches against three defined test strategies. Raw simulation data is saved to `output/cpu005-simulation.json`; summarise with `.venv/bin/python tools/summarize_cpu.py output/cpu005-simulation.json --output output/cpu005-summary.json`. Run `tests/test_cpu.gd` with `-- --quick-cpu` for an 18-match development check. Human keyboard playtesting and subjective balance remain the owner's review.
