# Milestone 004 — rhythmic taps, compact steps and stages

The owner confirmed the preceding movement repair through human playtesting.
This milestone deliberately replaces its held-repeat/unrestricted tap policy.
Fresh physical keyboard playtesting of these new rules remains required.

## Rules and timing

A fresh horizontal press targets the nearest musical boundary from the existing
RhythmConductor/audio clock, with the existing input latency compensation.
PERFECT is inclusive ±90 ms; GOOD inclusive ±160 ms; outside is MISS. Values live
in `data/combat/settings.json`. GOOD is clamped to at most 187 ms (strictly below
half the shortest supported 375 ms beat); PERFECT cannot exceed GOOD. At default
160 BPM, adjacent windows leave a 55 ms MISS gap, with no ambiguous overlap.

Early valid taps wait for the target boundary, survive release, and may have
their direction replaced before execution. Valid late taps execute immediately
on that boundary's beat. Every fighter can consume at most one tap per beat,
even after reversing direction or releasing/repressing. Holding and OS key-repeat
never generate steps. Release and press again on another valid beat to move.
Precombat direction state supports combat selection but never auto-moves when
combat begins. Focus loss clears pending taps. Out-of-window input displays MISS
without changing position, energy or initiative or triggering a step animation.
Normal missed combat can still pass initiative at its usual exchange resolution;
that is independent of a movement MISS.

Movement and combat are evaluated independently from the same horizontal press.
A valid MID chord can therefore step and fight on beat four, while a horizontal
press outside the movement window can still select MID for a combat chord.
Attack windows remain ±70/±140 ms and combinations remain 100 ms.

Early movement resolves at the boundary; valid late movement resolves as its
input is processed. Each movement pass uses the established two-player collision
function, arena limits and minimum gap. Input delivery order supplies a fixed
order for late events; early queued requests from both players resolve together.
Beat-four range freezes after its movement window closes, including positive
latency compensation, before buffered combat adjudication. No attack range is
evaluated before that freeze; movement cannot alter an already-evaluated range.
Impact animation still aligns to the nominal fourth beat. Damage remains in
Bout logic, with one shared stick reach and one adjudication per exchange.

## Why movement looked sluggish

The old `forward_step` and `backward_step` resources referenced all six walk
frames, were marked `loop:true`, and orchestration stretched their recovery to
85% of a beat. A single logical step consequently looked like a continuing run.
An additional shared exchange recovery deadline could prolong a walking pose.

Four new SpriteFrames resources under `data/animations/step_004/` reference only
approved walk frames 0 (weight transfer) and 2 (stable stance), selected after
inspecting a contact sheet of both fighters. Both directions use those existing
pixels, native facing, display scale and ground metadata. Resources are
non-looping, two poses at 12.5 FPS: 160 ms total. Original PNGs and original
six-frame resources are unchanged.

The logical step starts visual displacement and playback together. Rendering
interpolates from the current displayed X to the authoritative X over the same
160 ms; there is no easing tail. A new step restarts cleanly from the current
visual position. Walking ends on its own deadline even when unrelated exchange
recovery is longer. Combat poses/reactions may override walking, but animation
never postpones input or gameplay resolution.

## Supplied backgrounds

- Stage 01: `assets/environments/backgrounds/background_01.png`.
- Stage 02 original: `assets/environments/backgrounds/background_02` (no suffix).
- Stage 02 import copy: `assets/environments/backgrounds/background_02.png`.

Both files were inspected: PNG, RGB, 1672×941. Stage 02's import copy is byte-for-
byte identical; the extensionless original remains intact. `data/stages.json`
records dimensions, formats, source paths and SHA-256 hashes. Both backgrounds
are now tracked as requested for integration; they were untracked before this
milestone. Character art and soundtrack remain unchanged.

`StageBackground` is reusable, reads the configured `default`, and supports F4
cycling in the existing main scene. A uniform cover scale fills 320×180; the
source ratio is almost exactly 16:9, with only about 0.096 logical pixels of
vertical overflow. The GPU samples with nearest filtering; no source is cropped,
resized or rewritten. Rendering clips the tiny overflow at the viewport edge.
Artwork is behind fighters, crossed sticks, effects and HUD. Existing fighter
anchors and collision ground remain Y=150, lying on the supplied foreground
fighting surface. There is no parallax or reactive scenery.

## Feedback and evidence

Per-player PERFECT STEP / GOOD STEP / MISS appears briefly below the player
cards. Pixel-font shadows maintain contrast over both supplied backgrounds.
F3 shows input timestamp, nearest phrase:beat, signed millisecond offset, grade,
execution status and logical/rendered X. The existing input trace remains
available with `-- --movement-trace` (run checks first to create `output/`).

Graphical captures from the actual configured playable scene were inspected:

- [Stage 01](../screenshots/milestone-004/stage-01.png) and
  [Stage 02](../screenshots/milestone-004/stage-02.png).
- [Step/weight transfer and PERFECT feedback](../screenshots/milestone-004/step-transfer.png).
- [Stable pose during displacement](../screenshots/milestone-004/step-stable.png).
- [Both fighters back in idle](../screenshots/milestone-004/idle.png).
- [GOOD STEP](../screenshots/milestone-004/good.png) and
  [MISS](../screenshots/milestone-004/miss.png).

## Executed verification

`bash tools/check.sh` exited zero. Focused Godot suites passed 5,146 checks:
rules 51; controls 46; media 3,300; launch/range 884; timed movement/idle/stage 676;
arcade HUD 189. Counts changed because obsolete held-repeat and unrestricted tap
assertions were replaced, and runtime step resources now contain fewer frames.
The scripted round/champion/rematch demo also passed.

The live-scene lifecycle test passed 168 checks graphically and 168 headlessly.
It enters the configured main scene via Enter, countdown and authoritative race,
then sends Godot keyboard events through the normal input pipeline. It covers
both mirrored controls, all four resolution beats at 120/140/160 BPM, released
early taps, no held repetition, GOOD/MISS feedback, simultaneous movement,
visible displacement, F4, full combat rounds, match victory and rematch. The
supported scheduled-tempo API supplies the tempo matrix; natural escalation is
covered by the rule/demo tests. No primary test directly sets positions, phases
or a fake clock. Focused boundary tests intentionally use an injected clock.

A headless test draft used a wall-clock sleep across an audio tempo transition
and incorrectly asserted that its early tap had not crossed a boundary. The
fixture now waits on conductor audio time and distinguishes a crossed boundary;
the corrected complete suite passed. Production movement did not need a timing
change for that test failure.

All 22 Python asset/API-adapter tests passed, including source hashes, alpha,
retained character pixels, soundtrack hashes and byte-identical stage imports.
No paid image request was made. Nonfatal environment output includes macOS
CA-certificate/editor-settings sandbox messages and existing Godot ObjectDB
teardown warnings. Successful runs had no script parse/assertion failures.

These are synthetic Godot key events, with actual graphical render captures.
Physical keyboard focus/rollover, subjective step feel, balance of the proposed
windows and perceptual audio sync require human playtesting. No manual keyboard
interaction or audio listening is claimed.

## Launch and test

Open the root `project.godot`, press F5, Enter, wait for GO and race with F / Right
Shift. Red taps A/D; Blue taps Right/Left. Tap near each beat; release before
another tap. F4 cycles stages, H shows help, F3 shows timings. Test holds (one step
only), late/early taps, midpoint MISS, simultaneous actions and beat-four combat.
Run all checks with `bash tools/check.sh`; the real-clock test takes roughly two
minutes. Graphical regression: `/Applications/Godot.app/Contents/MacOS/Godot
--path . --script tests/test_live_movement.gd --max-fps 120` (one shell line).
