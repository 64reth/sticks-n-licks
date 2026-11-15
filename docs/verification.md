# Executed verification — 2026-11-15

Environment: macOS, Apple M4, Godot 4.6.2 stable (`71f334935`), Python 3.9 isolated `.venv`, Pillow 11.3.0 and OpenAI SDK 2.48.0. SDK installation did not generate images.

`bash tools/check.sh` runs editor/headless import, deterministic rule tests, main-scene smoke launch, a scripted end-to-end demo and optional Python asset tests. Godot can exit zero on script parse failures, so the runner also scans logs and requires explicit test/demo completion markers.

- **51 GDScript rule checks passed:** beats at all three tempos, phrase boundaries, phrase-only tempo transitions to 140/160, stalled-frame catch-up, perfect/good/miss endpoints, input compensation, false starts, reaction comparison, alternating race ties, double false start/no reaction reruns, no race damage, all three directional blocks and parries, incorrect/mistimed/missing defence, missed/absent/out-of-reach attacks, third-hit victory and input lock, movement separation/arena boundaries including coupled corner cases, defence-based escalation, right Shift mapping, and loading an exported SpriteFrames resource.
- **12 Python tests passed:** genuine PNG/RGBA/grid/frame counts, occupied frame edges, partial alpha rejection, lossless slicing and source preservation, fresh export destinations, approved reference hashes, missing approval rejection, prompt/budget limits, transparent single-image request planning, mocked SDK generation and editing, original byte preservation and cost/count/approval tracking. SDK tests use mocks and fake test-only keys; no external generation calls occur.
- **Headless scene smoke test passed.** The scripted demo reaches victory after six exchanges, including three opening parries, schedules 140 BPM and verifies rematch resets scores to [0,0] and tempo to 120.
- **Graphical run succeeded** on OpenGL 4.1 Metal compatibility renderer. Godot Movie Maker recorded 1001 frames at 60 FPS (approximately 16.7 seconds) to `output/gameplay.avi`. `output/victory.png` captures the demonstration outcome. These generated artifacts remain local and are ignored by Git.
- **Offline image dry run succeeded.** No API key was required; no paid request was sent. Live generation/editing and billing remain deliberately untested until explicit approval.
- **Asset catalogue:** six new procedural placeholder PNGs plus one supplied reference. The reference hash is `34bc0d686725a6ff4cfe5f2caece324173a23c09f218421c06bfa3f296e7746e`. It is 2172×724 RGBA with true alpha; it fails exact 96×96 sprite-cell/palette/binary-alpha validation. It is preserved unchanged, unapproved and unused in gameplay. Placeholder sheets and their exported frames pass technical checks.

## Verification limits

The sandbox denies access to normal Godot editor settings/snapshot directories and system certificate APIs. Import logs include those platform errors; scripts/resources still import, and the runtime/rule/demo checks complete. Explicit project-local log paths avoid the engine logger failure seen on the initial restricted run. No unrelated repository was modified to address these environment limits.

The graphical demonstration uses artificial inputs and a simulation clock. It is not a human two-player playtest. Keyboard rollover, target-device audio/input latency, production animation quality and Logic soundtrack alignment still require hands-on review. Final sound files are absent: the prototype uses locally synthesised timing clicks. Final artwork remains an asset-production task; most animation poses are intentionally simple procedural placeholders. No production audio alignment or live Image API success is claimed.

The studio kit was inspected read-only at `f0989e7c2187e747fb38f05ef071e73202c5e9b8`. Its small vertical-slice, observed game-feel, visual review and gameplay-debug practices were adapted for Godot. Its browser Lab and npm checks do not apply to this GDScript project.

## Control refinement 001B and strict movement follow-up — 2026-11-15

`bash tools/check.sh` passed after the control/movement changes: **51 core rule checks, 117 new control/movement checks and 12 Python asset tests**. Import, main-scene smoke test and victory/rematch demonstration also passed. Controls tests instantiate the configured root main scene and use Godot physical-key InputMap events for P1 and P2, including Right Shift location filtering.

New checks cover all three BPM values, no immediate/off-beat/beat-4 displacement, one held step per eligible boundary, release cancellation, opposing directions, catch-up timing, focus loss, all attack/block heights, both combination orders including exactly 100 ms, held directions, ±70/±140 ms endpoints, original execute timestamps, directionless execute rejection, reversed-facing MID and movement suppression/re-arming after combat. Existing initiative, scoring, race and victory regression tests remain green.

The control suite also passed graphically on the Apple M4 OpenGL compatibility renderer. Root-project graphical launch completed without runtime errors. A graphical scripted demo exercised the updated controls through three-hit victory, escalation to 140 BPM and rematch. The editor's actual F5 key was not automated: there is no connected editor-control session. Its configured project-run path is verified by launching the root project without a scene override. New music WAVs supplied in the working tree are preserved untouched and excluded from this control change; no audio integration or downbeat alignment was attempted.

Local verification outputs include `output/controls.stdout`, `output/controls-graphical.log`, `output/controls-001b.png` and `output/root-launch-001b.log`. Restricted editor settings/certificate warnings can still occur independently of the passing gameplay checks. A capture attempt aborted during engine startup; graphical launch/control checks were rerun successfully, without relying on that failed recording.
