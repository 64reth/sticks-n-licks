# Sticks n Licks

Original local two-player Caribbean stick-fighting rhythm prototype. Godot 4.6+, GDScript, 320×180. No API key, Python installation, final artwork or soundtrack is required to play.

## Launch on this Mac

```sh
cd /Users/garethwallen/Projects/sticks-n-licks
/Applications/Godot.app/Contents/MacOS/Godot --editor --path .
```

Press **F5** to launch the playable prototype from any open scene. The root `project.godot` sets `res://scenes/main/main.tscn` as the main scene. **F6** runs only the currently open scene. Develop in this repository directly; do not create a nested project or separate working copy. Direct launch:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

Enter starts Local Versus. H toggles help; F3 toggles the developer overlay; Escape returns to the menu. C on the menu switches the race cue between an accented click and drum cutoff. Enter rematches after victory.

| Player | Move left/right | High / Low | MID | Race / execute |
|---|---|---|---|---|
| P1 | A / D | W / S | Forward + F | F |
| P2 | Left / Right | Up / Down | Forward + Right Shift | Right Shift |

Forward is facing-relative: initially D for P1 and Left for P2. If facing reverses, the other horizontal key becomes forward. X, standalone MID actions and Enter for P2 combat/race are removed; Enter still starts the menu/rematch.

Wait through the three-count patterns for GO. Early execution forfeits race initiative. Both fighters get sticks; winning the race awards no hit. Reactions within 5 ms tie; tie priority alternates across tied races, starting with P1. A two-second reaction timeout resolves one valid reaction; no reactions or two false starts restart the count. Keyboard hardware may limit simultaneous keys.

Movement is strictly beat-locked: hold left/right to queue a step for the next eligible beat (1, 2 or 3). Releasing before that boundary cancels it. A held direction steps once per eligible beat; opposite directions together hold position. Key events never directly move the authoritative position. Rendering interpolates toward each beat position. Beat 4 never begins a movement step.

Combat requires **direction + execute**, with a 100 ms combination buffer in either order and support for a direction held longer. Up/high or down/low chooses that height; the facing-relative forward key chooses MID. Execute alone never defaults to MID. The execute timestamp determines timing even if its direction arrives later within the combination buffer. ±70 ms is perfect; ±140 ms is valid. A correct perfect block steals initiative; a correct valid block retains the attacker. Incorrect/missing/mistimed defence permits a successful attack to score. A missed attack passes initiative. Three clean hits win.

Combat takes priority over movement: a valid combination suppresses held horizontal movement until release/repress, including the next phrase's first beat. Holding forward to select MID cannot add an accidental step after the action. One combat execution is accepted per phrase. Resolution waits until the late timing window plus the 100 ms combination buffer closes, so a valid late execute can still receive its direction. Strikes beyond 140 logical pixels miss; arena boundaries and separation remain enforced.

F3 shows current beat/phrase, timing errors, selections, queued movement and each player's last movement grid time/actual processing time (seconds on the shared clock). Render catch-up may process a scheduled boundary late; no input is applied retroactively to a past boundary. Losing application focus clears held keys and queued movement.

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
  --write-movie output/gameplay.avi --quit-after 1500 -- --verify-demo
```

Create `output/` first. The demo injects a simulation clock and artificial player inputs; it is not a recording of human play. It demonstrates parries, tempo escalation, three-hit victory and rematch.

## Assets and development

See [design](docs/design/milestone-001.md), [asset catalogue](docs/assets/catalogue.json), [audio handoff](docs/assets/audio.md), [optional image pipeline](docs/assets/image-pipeline.md), and [verification](docs/verification.md). Studio toolkit scope and workflow adaptations are documented in [AGENTS.md](AGENTS.md).

Temporary procedural pixel fighters provide all named animation states. The included two-frame PNG idle samples also demonstrate the lossless PNG → frames → Godot SpriteFrames pipeline. These are placeholders, not approved production art. The supplied character reference is preserved unmodified and is not assigned to gameplay.
