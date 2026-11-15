# Movement repair — awaiting human verification

## Reproduced failure and root cause

The baseline was HEAD `0e0d836217ced3c6cdf0bcdb8863b0d0c8055b2d`.
The normal configured main scene was instantiated with its real process loop, real
clock and enabled audio. Engine-injected Enter passed the menu/countdown; F and
Right Shift completed the authoritative race. No phase/position/clock overrides
were used in this primary reproduction.

A and Right Arrow were pressed together and released about 35 ms later, away
from a boundary. Both raw events arrived. `CombatInput.feed()` handled release
by calling `movement()`, which recomputed `queued` solely from held keys.
`CombatInput.step()` sampled those keys again at the boundary. Both queues
became zero, both feedback strings read `CANCEL released before beat`, and
positions stayed `[100,220]`. This is the first demonstrated failing stage:
request retention, after InputMap/event delivery and before beat resolution.
A second policy mismatch made simultaneous opposing directions neutral rather
than choosing the latest press.

The previous 1,127 checks included injected events but normally forced combat
and used an injected clock. They explicitly asserted that released taps cancel,
so the tests upheld the old rule. Passing those checks did not establish the
new interaction policy or physical keyboard responsiveness. This diagnosis does
not prove that every reported human input failure has the same cause.

## Repair

A pending directional tap now survives release until the next conductor
boundary. A later horizontal press replaces it. Held keys repeat exactly once
per boundary; after the pending tap is consumed, release prevents repetition.
If two directions are held, the most recently pressed wins, independent of
timestamp ties. Releasing it falls back to another still-held direction.
No position changes occur in input handlers. All four boundaries permit steps.
Movement/collision still precedes the beat-four range snapshot. Combat timing,
reach, damage, sprites and audio are unchanged.

Outside combat, directions are observed as holds but do not latch taps or move.
A hold still down when combat begins can step at its first boundary. Losing
application focus clears pending and held input, requiring a new press.

F3 now includes detected key/down-up, phase, queued direction, logical/rendered
X, accepted/rejected reason, last step and raw/routed counters. A brief green
foot marker confirms an accepted press. A bounded 2,048-record trace logs raw
keycode, physical keycode, InputMap action, event ID, focus owner, phase/beat,
queue/acceptance, boundary request, before/after position, execution time and
rendered settlement. Start with `-- --movement-trace` to export it on exit to
`output/movement-trace.json`. A raw event without its matching unhandled record
helps identify GUI consumption; absent raw events require checking OS focus.

## Verification

`bash tools/check.sh` includes the focused rules/assets/rendering/input suites,
match/rematch demo, Python tests, and the slower real-clock lifecycle regression.
`tests/test_live_movement.gd` launches the configured main scene, enters via
Enter, waits for GO, races using F/Right Shift, and injects actual Godot key
events through InputMap and normal scene handlers. It never directly moves a
fighter, sets its phase/position, or overrides its clock. The 140/160 BPM matrix
explicitly calls the supported scheduled-tempo API; it does not claim that this
matrix verifies natural defensive escalation. Existing rule/demo tests cover
that progression.

The test exercises released taps, held repeats, both mirrored controls, all
four resolution beats, simultaneous movement and rendered displacement at each
tempo, then completes rounds and a match through combat key events, starts a
rematch, repeats the race and moves again. Its watchdog fails after 180 seconds.
Evidence is written to `output/live-movement-evidence.json`.

Graphical captures were inspected: [retreat](../screenshots/movement-repair/retreat.png)
shows X=84/236; [closer](../screenshots/movement-repair/closer.png) shows X=116/204.
Both actual sprites retain scale, ground anchors, colours and facing. Captures
come from the running scene, not a preview or manually positioned fixture.

## Human verification still required

These are synthetic Godot key events, not physical keyboard presses. Graphical
rendering was inspected; physical focus, keyboard rollover, human responsiveness
and perceptual audio synchronisation are not verified. Status remains **awaiting
human verification**, rather than fully resolved.

Open the root `project.godot`, press F5, Enter, wait for GO, then race with F and
Right Shift. In combat, tap/release and hold A/D and Right/Left Arrow at arbitrary
points between boundaries. Tap should step at the next boundary; holds repeat
once per beat. Check all four beats, F3 diagnostics, simultaneous keys, round
reset and rematch. If an input fails, capture F3 and export the movement trace.

Executed results: 5,716 focused Godot checks and 20 Python tests passed;
match/champion/rematch demo passed. The real-clock lifecycle regression passed
179 checks in both graphical and headless runs. All four resolution beats were
observed separately at 120, 140 and 160 BPM. Full `tools/check.sh` exited zero.
A final main-scene headless smoke run parsed and launched successfully.
Nonfatal environment messages included the macOS CA-certificate warning,
sandbox denial when saving editor settings, and Godot ObjectDB teardown warnings.
No script parse failures or assertion failures occurred in the successful runs.
The first E2E draft incorrectly assumed two played rounds always finish a
best-of-three; it was corrected to allow a deciding third round and rerun.
See [retained evidence](movement-repair-evidence.json) for before/after samples.
