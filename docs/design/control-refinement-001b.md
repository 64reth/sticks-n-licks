# Control refinement 001B and movement timing

Historical implementation record. [Milestone 003](milestone-003.md) supersedes earlier movement restrictions: beats 1–4 permit movement; beat-four movement/collision resolution precedes the combat position snapshot. Combat chords do not suppress movement. Match scoring is now best-of-three.


This updates the existing root Godot project; `application/run/main_scene` remains `res://scenes/main/main.tscn`. No nested project or separate checkout is used.

P1: A/D move, W high, S low, F execute/race. P2: Left/Right move, Up high, Down low, Right Shift execute/race. Enter is menu/rematch only. MID uses the horizontal direction toward the other fighter plus execute, derived from logical positions rather than a fixed player-specific key. Sprites mirror from the same facing calculation. The current arena still prevents fighters crossing.

`CombatInput` keeps per-player held-key state, recent direction timestamps, pending execute and movement suppression. A direction can be held indefinitely or combined within 100 ms in either input order. The most recently pressed eligible direction wins; backward is not MID. Execute without a direction does not default to MID. The original execute timestamp determines the ±70 ms perfect / ±140 ms valid grade, including when direction arrives later. Endpoints include floating point tolerance below one millionth of a millisecond. Input latency compensation remains configurable.

Resolution waits until the late timing window plus combination allowance expires. One combination per player per exchange is accepted. Successful timing suppresses all currently held horizontal movement until its respective key is released. This prevents forward+execute from leaking a movement step into the next phrase. A fresh release/repress explicitly re-arms movement. Missing/mistimed actions preserve the existing initiative rules. Race does not need a direction and does not award hits.

Directional events update a queue, never positions. Only conductor beat signals 1–3 sample held, unsuppressed movement and apply one step. Released keys cancel the queue; opposing held horizontal keys cancel each other. The controller guards duplicate boundary processing. Before accepting an input event, the conductor advances through all already-crossed beats using the previous held state, preventing a new press from affecting a past beat. Catch-up retains exact scheduled timestamps and records the actual processing timestamp separately. Beat 4 sets no new movement target. Visual interpolation is separate from the authoritative position; existing arena limits/minimum separation remain unchanged.

The F3 overlay shows queued movement and last grid/actual movement time for each player. Focus loss resets held state and cancels queued movement. A new bout resets all input state. InputMap and fallback bindings agree; obsolete standalone MID actions and X/Enter combat controls are removed.

Verification uses the configured main scene with Godot physical-key InputMap events for both players, all three tempos, chord orders, timing endpoints, release cancellation, held repetition, no beat-4/off-beat movement, suppressed post-combat steps, reversed-facing MID, race false starts, boundary catch-up and focus loss. These are scripted checks, not human keyboard or editor-shortcut testing.
