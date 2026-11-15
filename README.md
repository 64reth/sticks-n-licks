# Sticks n Licks

Original local two-player Caribbean stick-fighting rhythm prototype. Godot 4.6+, GDScript, 320×180. No API key, Python installation, final artwork or soundtrack is required to play.

## Launch on this Mac

```sh
cd /Users/garethwallen/Projects/sticks-n-licks
/Applications/Godot.app/Contents/MacOS/Godot --editor --path .
```

Press **F6** with `scenes/main/main.tscn` open, or **F5** to run the project. Direct launch:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

Enter starts Local Versus. H toggles help; F3 toggles the developer overlay; Escape returns to the menu. C on the menu switches the race cue between an accented click and drum cutoff. Enter rematches after victory.

| Player | Move left/right | High / Mid / Low | Race / execute |
|---|---|---|---|
| P1 | A / D | W / S / X | F |
| P2 | Left / Right | Up / Down / Right Shift | Enter |

Wait through the three-count patterns for GO. Early execution forfeits race initiative. Both fighters get sticks; winning the race awards no hit. Reactions within 5 ms tie; tie priority alternates across tied races, starting with P1. A two-second reaction timeout resolves one valid reaction; no reactions or two false starts restart the count. Keyboard hardware may limit simultaneous keys.

Queue movement and choose high/mid/low on beats 1–3. The queued step lands on the next movement beat. Tap execute near beat 4, once per exchange. ±60 ms is perfect; ±130 ms is good. A matching perfect block steals initiative, a good block retains the attacker, an incorrect/missing block loses one hit if the attack succeeds. A missed attack passes initiative. Three clean hits win. An exchange resolves after the late timing window, so late valid input is accepted. Strikes beyond 140 logical pixels miss and pass initiative; movement cannot overlap fighters.

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
