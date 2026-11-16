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

The game opens with the original intro music: the Barbados sky slides down, the transparent foreground rises, and the complete animated logo pumps to the beat. Enter during the entrance completes the title; release and press Enter again to open the main menu. A held key cannot skip both states. The start prompt appears after the reveal. Choose **START GAME** to configure Player vs CPU or local Player vs Player, CPU difficulty, best-of-3/5/7, tempo and stage. Use **Up/Down** to highlight, **Left/Right** to change a value, **Enter** to confirm/activate and **Escape** to go back. On a value row, Enter confirms it and advances to the next row. Enter starts a bout only on START BOUT.

During a match, **Escape pauses**. The pause menu offers Resume, Restart Match, Options, How to Play and Main Menu. Left/Right changes the three illustrated tutorial pages; Escape returns to the previous menu, keeping a paused bout frozen. Ordinary rounds show the result and winner/loser reactions for 2.5 seconds, then automatically reset into the next countdown; no Enter press is needed. Escape pauses this interval too. At the final result choose Rematch, Match Setup or Main Menu. Options include audio, window/fullscreen, integer scaling, controls, timing feedback and reset defaults. Changes save automatically in Godot's `user://preferences.cfg`. No mouse, account, network, Python or API key is needed.

| Player | Move left/right | High / Low | MID | Race / execute |
|---|---|---|---|---|
| P1 | A / D | W / S | Forward + F | F |
| P2 | Left / Right | Up / Down | Forward + Right Shift | Right Shift |

Forward is facing-relative: initially D for P1 and Left for P2. If facing reverses, the other horizontal key becomes forward. X, standalone MID actions and Enter for P2 combat/race are removed; Enter still starts the menu/rematch.

Wait through the three-count patterns for GO. Early execution forfeits race initiative. Both fighters get sticks; winning the race awards no hit. Reactions within 5 ms tie; tie priority alternates across tied races, starting with P1. A two-second reaction timeout resolves one valid reaction; no reactions or two false starts restart the count. Keyboard hardware may limit simultaneous keys.

Movement uses deliberate **taps on beats 1–4**. Each new left/right press is graded against the nearest conductor beat: PERFECT ±90 ms, GOOD ±160 ms, otherwise MISS. Early valid taps wait for their boundary; late valid taps execute immediately within that beat's window. Release and press again to move again: holding and OS key-repeat never repeat steps. Each fighter gets at most one step per beat. Misses do not move, walk, drain energy or change initiative. These separate movement windows are configurable in `data/combat/settings.json`; combat timing remains ±70/±140 ms. Precombat holds do not move when combat begins.

Combat requires **direction + execute**, with a 100 ms combination buffer in either order and support for a direction held longer. Up/high or down/low chooses that height; the facing-relative forward key chooses MID. Execute alone never defaults to MID. The execute timestamp determines timing even if its direction arrives later within the combination buffer. ±70 ms is perfect; ±140 ms is valid. A correct perfect block steals initiative; a correct valid block retains the attacker. Incorrect/missing/mistimed defence permits a successful attack to score. A missed attack passes initiative. Three clean hits win a round. Match setup selects first to 2, 3 or 4 round wins for best-of-3, 5 or 7. A perfect parry also prevents only the parried fighter's next movement opportunity; attacking, blocking and countering remain available.

At beat four the deterministic order is **accepted movement → collision limits → frozen positions → attack/block adjudication**. The range snapshot closes after the ±160 ms movement window (including positive latency compensation), before the existing combat/combination grace finishes. This admits legal late steps without changing an evaluated range. A horizontal press can independently qualify for movement and a direction+execute combat chord. Holding a direction still supports combat selection. Shared `stick_reach` remains 44 logical pixels (53-pixel maximum centre gap including hurtbox).

The arcade HUD shows RED/BLUE cards, three energy segments, round-win markers, round number, BPM and initiative. Energy is derived from authoritative scored hits against that player. Countdown **3 → 2 → 1 → GO!** follows the final standoff beats; GO is the existing race cue and false starts still forfeit initiative. Temporary player-facing outcomes include HIGH/MID/LOW HIT, BLOCK, PERFECT PARRY and MISS. No raw diagnostic text appears during normal play. How to Play is available from the main, options and pause menus. F3 toggles diagnostics; F4 is restricted to pre-match developer previews while F3 is enabled.

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

Stages are selected in Match Setup, including RANDOM (chosen once per match). `data/stages.json` catalogues eight valid entries/six distinct images, including the different extensionless Stage 04 original and the identical Stage 04/05 PNGs. Source files are preserved. Nearest filtering, proportional viewport fill and ground Y=150 remain unchanged.


Milestone 005 adds the seeded rhythm-aware CPU. Difficulty parameters are in `data/cpu.json`. Reproduce an opponent with `/Applications/Godot.app/Contents/MacOS/Godot --path . -- --cpu-seed=7000 --cpu-difficulty=hard`. Identical seeds reproduce relative CPU decisions for identical public match/input timelines, not fixed wins. Rematch resets the seed and learned tendencies; next round retains match learning but clears queued actions. F3 adds behaviour, distance, choice, intended beat, timing, outcome, weights, commitment and seed. Stage selection now uses Match Setup, rather than a live-match shortcut.

See [CPU architecture, measured results and recording instructions](docs/design/milestone-005.md). `bash tools/check.sh` includes 900 seeded matches against three defined test strategies. Raw simulation data is saved to `output/cpu005-simulation.json`; summarise with `.venv/bin/python tools/summarize_cpu.py output/cpu005-simulation.json --output output/cpu005-summary.json`. Run `tests/test_cpu.gd` with `-- --quick-cpu` for an 18-match development check. Human keyboard playtesting and subjective balance remain the owner's review.


Milestone 006 adds the arcade front end, saved settings, pause, match formats and supplied stunned/hurt/victory/defeat animations. Ordinary rounds use a short announcement; celebrations and one-shot result music occur only after the deciding round. CPU victory selects the defeat theme, human CPU-mode victory and either PvP winner select victory. Pausing freezes the shared clock, music, CPU and animation; fresh directional presses are required after resume.

See [Milestone 006 implementation, assets, tests and recordings](docs/design/milestone-006.md). The new reaction checks run via `tests/test_milestone006.gd` and `tests/test_reactions.py`, also included in `bash tools/check.sh`. Historical milestone pages describe the controls and presentation at those commits; this page and Milestone 008 define the current flow.


Milestone 007 adds the approved `bim_sky.png` / `bim_foreground.png` title scene, the six-pose complete title logo, three illustrated tutorial pages and a beat-synchronised rubbery speaker on Crop Over Festival only. `data/intro.json` controls musical cues and entrances; cue timings are provisional pending listening review. `data/presentation_sheets.json` records the reviewed irregular speaker regions. Stage speaker position, scale and pulse intensity are configurable per entry in `data/stages.json`. All original art is preserved and used directly. See [Milestone 007 implementation and verification](docs/design/milestone-007.md).


The [Milestone 007 UI polish](docs/design/milestone-007-ui-polish.md) centres the title CTA using container padding and gives round announcements a crisp 2px native outline. [Milestone 008](docs/design/milestone-008.md) adds eight short combat/menu effects, mapped and mixed in `data/sfx.json` with sound paths in `data/audio.json`, and automatic ordinary-round progression (`round_result_seconds` in `data/combat/settings.json`). Original music/percussion remain in use. The supplied FreeSFX effects are **provisional development assets: commercial redistribution rights are unverified**, because no licence was supplied in the archive. Resolve licensing and perform a listening review before commercial distribution.
