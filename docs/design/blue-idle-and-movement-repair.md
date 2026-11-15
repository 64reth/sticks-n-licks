# Fighter 02 idle and movement input repair

Historical implementation record. [Milestone 003](milestone-003.md) supersedes earlier movement restrictions: beats 1–4 permit movement; beat-four movement/collision resolution precedes the combat position snapshot. Combat chords do not suppress movement. Match scoring is now best-of-three.


## Supplied Blue idle

Located `assets/characters/fighter_02/spritesheets/fighter_02_idle.png`: **2172×724 RGBA**, alpha range **0–255**, **four left-to-right poses**, natively facing left. Its SHA256 is `641ab06949a8a837b09e3d2fea543b722317cb3256e2ba1a73a53b5b31b0cc72`. The supplied file is byte-identical to `fighter_02_mid_block.png`; that duplication is recorded rather than interpreted as new artwork.

`tools/import_fighter_02_idle.py` reuses the established native extraction, alpha-haze handling, transparent padding and boot anchoring. It only writes a new Blue output directory: `assets/characters/fighter_02/frames/idle_002/`. The four frames retain source pixels/proportions, use 768×768 canvases and baseline 744, and display at scale 64/584 ≈ 0.109589. Both Blue `idle` and `combat_idle` now use this four-frame sequence, looping at the existing 8 FPS (0.5-second cycle), so recovery cannot fall back to the previous one-frame ready pose. Sources and prior exports are preserved. No Red artwork, animation resources or configuration was changed.

SpriteFrames can auto-select idle before `set_pose` runs. The preceding rendering fix correctly applied its transform but still did not start playback when that auto-selected state was unchanged. Looping states now start if not already playing; an already-running loop is not restarted every frame. This shared playback fix does not alter Red assets or animation data.

The current aggregate catalogue is **20 supplied sheets / 117 extracted frames**, including this one incremental sheet/four frames. The new directory's manifest records source hash, rectangles, translations, frame order, scale, alpha checks and visual review. Historical Milestone 002 manifests remain preserved; the aggregate and current Blue config reflect the new mapping.

## Actual movement root causes

The previous handler returned before recording direction events outside `combat`. Players holding a movement key during the countdown or pickup therefore entered combat with Godot's physical key still held but `CombatInput.held` empty. OS repeat events were deliberately ignored, so continuing the hold could never recover: release/repress was required. A reproduction using **Input.parse_input_event → InputMap → scene event dispatch** showed engine D held = true, tracked state empty, and P1 still at x=100 on beat 2. After repair the same held state reaches the first eligible combat boundaries (x=132 after beats 1 and 2).

The handler now tracks held/released directions throughout menu, standoff, race and pickup without creating combat actions or displacement. Bout start clears pending actions and seeds only physical directions already held. Execute is not carried over from racing. Once combat begins, the next eligible boundary samples those directions normally. Focus loss still clears them to prevent stuck movement.

The movement path was **not gated by the attack timing window**, and its timing has not been widened or changed. Movement presses are accepted throughout beats 1–3, independently of ±70 ms perfect / ±140 ms valid attack timing and the 100 ms combination buffer. Steps remain deterministic, once per eligible beat, with visual interpolation and unchanged arena/separation rules. Beat 4 starts no movement. A direction pressed during beat 3 may wait through beat 4 for the next beat 1.

**The existing release-cancels rule remains:** a short tap held across an eligible boundary steps once; a tap released before that boundary cancels. No immediate/off-beat step or queued release-and-forget tap was introduced. Holding forward after a valid direction+execute action remains suppressed until release/repress, preventing an extra combat step. These states now have explicit F3 explanations instead of appearing silently unresponsive.

Walking previously started before collision constraints were applied, even when an arena edge or opponent prevented displacement. One shared pose timer was also refreshed by either player's beat handling, obscuring independent walking-to-idle recovery. Walking now starts only after an actual logical position change, and each fighter has its own visual recovery deadline. Idle resumes independently after walking or action recovery. Collision geometry, stick reach, damage/initiative, scoring and soundtrack were not changed.

## Controls and developer feedback

At default facing: P1 A retreats / D advances; P2 Right retreats / Left advances. The underlying left/right controls and facing-relative MID remain configurable through InputMap.

F3 shows each player's latest input and step decision on the floor panel, alongside the existing geometry and timing overlay:

- `ACCEPT queued left/right`: direction is waiting for an eligible beat.
- `ACCEPT held; wait combat`: physical direction is retained through countdown/pickup.
- `CANCEL released before beat`: the short tap ended before its step boundary.
- `REJECT beat4; queued for beat1`: held movement waits through combat resolution.
- `REJECT arena/separation`: the step cannot displace the fighter.
- `REJECT combat hold; release`: release/repress is required after a combat chord.
- `REJECT opposing directions` or `REJECT focus lost`: explicit cancellation reason.

## Executed verification

`tests/test_idle_movement.gd` runs the **actual configured playable scene** and sends physical-key events through `Input.parse_input_event`, rather than invoking its input handler directly. **875 checks passed**, covering launch autoplay, all four Blue idle frames, left-facing anchors, both directions/players, simultaneous movement, phase-wide movement acceptance at 120/140/160 BPM, short taps spanning/released before boundaries, held-repeat behaviour, precombat holds, race-to-combat transition, walking-to-idle and attack/block/parry/hit recovery, boundary feedback, focus loss and no attacks from movement-only input.

The same suite passed graphically on Godot's OpenGL renderer. Actual captures of all four Blue idle frames, both fighters advancing, both retreating, idle recovery and cancellation feedback were inspected. Source/frame hashes, native retained pixels and audio originals passed Python validation. Existing suites passed: **51 rule checks, 117 control checks, 3,316 media checks, 916 launch/range checks and 20 Python tests**, plus import, main-scene smoke and victory/rematch demonstration. The media/range counts rose only because Blue combat-idle now has four frames instead of one.

This is scripted graphical verification, not a human keyboard playtest. Restricted certificate/editor-settings warnings and occasional graphical engine startup aborts can occur in this environment; successful reruns are the basis of visual verification. Root `project.godot`, main scene, combat timing, shared stick reach, hurtboxes and soundtrack remain intact. No paid generation was performed.
