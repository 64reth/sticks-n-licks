# Milestone 009 — Rent Due! Screen 01

Implemented on `development`, following Milestone 008 (`9b3120a`). Launch F5, dismiss/finish the existing intro, choose **STORY MODE → NEW GAME**. The campaign is **STICKS N LICKS: RENT DUE!**. Watch the eviction, tap A/D on conductor beats, duck with S, then reach the right edge. F remains reserved; it performs no combat. Escape pauses. Enter can skip the opening; held/echoed Enter cannot repeatedly skip it.

## Architecture and preserved mechanics

The configured root project/main scene remains unchanged. `scripts/main.gd` owns the existing conductor, AudioDirector, Red fighter and input routing. Story uses that same Red instance throughout the cinematic, idle, traversal and return to Arcade; Blue and the Arcade stage/HUD/ground sticks are hidden during Story. There is no camera cut, scene reload or second character at handoff.

`StorySession` manages cinematic/waiting/playing/complete state, input locking, the solo screen boundary and pose selection. `StoryScreenManager` instantiates `scenes/story/screen_01.tscn`; loading a section never starts/stops the conductor. `StoryScreen` draws the stationary house, existing sky and a pavement-only crop of the approved foreground. No substitute scenery or gameplay stage was generated. Screen 02 is deliberately absent. `BeatAnimation` samples ordered beat-relative cues from the shared conductor; it supports offsets, multi-phrase lengths, looping, one-shots and explicit start/stop. Replay anchors to the next conductor boundary without resetting musical phase.

The shared `RhythmMovement` adapter calls the existing `CombatInput.feed/request_movement` methods and supplies the original interpolation formula and forward/backward selection. Versus now calls these stateless helpers with identical arguments and keeps its approved step artwork. Story consumes the same `CombatInput.step` results and `Bout.STEP` distance. There is no new movement controller, acceleration, cooldown, tolerance, repeat policy or input buffer.

| Property | Both modes |
| --- | --- |
| Eligible movement beats | 1–4 |
| Movement precision | PERFECT ±90 ms; GOOD ±160 ms, from existing settings |
| Tap semantics | Fresh directional press; early valid taps survive release; valid late taps execute immediately |
| Repetition | At most one consumed tap per target beat; held keys never repeat |
| Displacement / duration | 16 pixels / 160 ms |
| Animation semantics | Forward/backward step, two poses over the same 160 ms, then idle |
| Low input while stepping | Does not suppress accepted movement |

The owner explicitly approved identical mechanics/timing with **unarmed Story artwork**. Story's two step poses are existing race frames **8 and 10**; the deep crouch is existing race frame **9**; unarmed idle is existing `character_master` (race frame **0**). The pickup-labelled sheet was inspected and is not misrepresented as a pickup. Versus has no separate duck action: S still selects its existing low combat input, while Story presents the crouch when stationary, without adding a movement lock. Story faces right, so left steps use the same backward-step semantics.

Context exceptions are the cinematic input lock and solo boundaries: X=30…280, Y=150. X=280 leaves room for the wider unarmed run silhouette; the final step alone clamps to the edge. Versus retains its existing arena/separation limits. Story renders the shared interpolated X on integer pixels (maximum rounding difference 0.5 pixel), with identical logical destinations and step duration. From X=100, twelve rightward taps reach the exit; the first eight cannot complete the screen. Completion waits until the final visual step finishes.

## Supplied artwork and extraction

Original files were discovered at their actual repository paths and preserved byte-for-byte:

| Source | Actual layout | Transparency |
| --- | --- | --- |
| `assets/characters/fighter_01/spritesheets/fighter_kicked_sheet.png` | 1448×1086 RGBA; 4×3 cells of 362×362; 12 row-major poses | Fully transparent padding and soft edge/haze alpha; no labels or opaque backdrop |
| `assets/environments/props/house_wife_kick.png` | 1672×941 RGBA; four house views with uneven horizontal margins | Transparent background with soft haze; first house touches the source left edge |

The fighter mapping is braced(0), launch(1), horizontal flight(2), seated landing(3), stunned seated reactions(4–6), getting up(7–8), brushing/recovery(9–10), upright reaction(11). Frame 11 is an available reaction, not a claimed newly authored head-shake. House mapping is closed(0), open/no foot(1), emerging slipper(2), extended kick(3). Open/no foot is the final static pose.

`tools/import_story_009.py` refuses existing output. It extracts **native pixels**, pads to 768×768 with baseline 744, applies reviewed foot/building translations, and clears isolated alpha haze only in new derivatives. No source resizing/recolouring occurs. The house uses irregular rectangles so uniform grid cuts do not amputate neighbouring silhouettes. `docs/assets/milestone-009.json` records source SHA-256 hashes, dimensions, rectangles, anchors and translations. Source artwork's small internal drawing variations remain; building origin/foundation stay fixed.

The cinematic sheet's standing pose is 289 source pixels high, versus 240 in the existing race idle. Per-animation texture calibration (`64/289` and `64/240`) gives both a 64-pixel standing height without resampling artwork. The actor root stays at scale 1. The cinematic switches to unarmed idle **before** the control handoff; the idle sprite scale, offset, pose and exact ground position are identical on both sides of control enabling. The tests check these values explicitly. Supplied soft alpha within the silhouette is retained; textures have no mipmaps and use nearest filtering.

## Musical cues and handoff

`data/story_009.json` contains the ordered house/fighter/accents cue maps, tempo and layout. All phase comes from the existing conductor epoch/time; no delta-based musical timer exists. A new Story session starts the existing original 120 BPM track once. Replay, recovery, handoff, traversal and screen completion do not restart it. Returning to menus uses the established menu music flow.

| Relative beat (zero based) | Seconds at 120 BPM | Event |
| --- | ---: | --- |
| 0 | 0 | Closed house, braced fighter |
| 2 | 1 | Open door; existing muted block accent |
| 3 | 1.5 | Slipper emerges |
| 4 | 2 | Extended kick, launch/displacement begins; existing hit accent |
| 4.5 | 2.25 | Airborne pose |
| 6 | 3 | Grounded seated landing, bounded procedural pixel dust, muted landing accent |
| 7–9 | 3.5–4.5 | Seated reactions |
| 10–11 | 5–5.5 | Get up |
| 12–14 | 6–7 | Brush off and upright reaction |
| 15 | 7.5 | Existing unarmed idle at X=100/Y=150; clear inputs |
| Next conductor boundary (normally 16) | Normally 8 | Enable traversal; music/camera/actor untouched |

The actor trajectory is Godot-controlled, separate from the house: X=67→100 with a 24-pixel airborne arc, all sampled from conductor beat phase and rounded to pixels. Dust uses nine tiny rectangles, no particle nodes or spawning loops. Effects/accents fire once per cue; the existing sound pool supplies bounded polyphony. Skipping stops both timelines, settles open/no-foot house and idle at X=100, clears controls and waits for the next beat. Directions held during cinematic/waiting remain blocked until released and freshly pressed. Pause freezes the same conductor/audio and clears held/pending controls.

Normal feedback uses the existing arcade font/palette with a crisp dark outline, a compact four-beat indicator and PERFECT/GOOD/MISS. F3 diagnostics show current cinematic/idle/moving/ducking state, beat, X, grade and error. Only debug builds with F3 enabled expose **F6 replay / F7 restart traversal / F8 skip**. Diagnostics and traversal overlays are hidden behind menus and removed when leaving Story.

## Menus and save

Story is appended after HOW TO PLAY; existing START GAME, OPTIONS and tutorial positions remain intact. Continue is greyed out and cannot activate without a valid save. New Game asks for confirmation when a valid checkpoint exists. The existing font/navigation sounds, Arcade setup, CPU/PvP selection, tutorial and preferences remain in use.

`StorySave` writes `user://story-009.json` using a temporary file/rename and stores only:

```json
{"version":1,"campaign":"rent_due","unlocked_screen":1,"checkpoint":"traversal","opening_complete":true}
```

The checkpoint can also be `screen01_complete`. A valid save is created after recovery/skip and updated at the exit. Continue restores the safe X=100 checkpoint without replaying eviction, then waits for the next beat. It does not pretend Screen 02 exists. Missing, malformed or incompatible saves disable Continue without crashing. Tests/recordings use empty or ignored test-local paths and do not write the owner's preferences/save.

## Verification and measured results

The complete `bash tools/check.sh` suite passed, including the 900-match simulation. A final complete run and focused reruns cover the final integration; all 31 Python tests also pass.

| Suite | Checks/results |
| --- | ---: |
| Rules / controls | 51 / 46, zero failures |
| Media / launch-range | 3348 / 1020, zero failures |
| Idle/movement / HUD / live movement | 676 / 189 / 168, zero failures |
| CPU simulation | 1,795,853 checks; **900 matches**, zero failures |
| Milestone 006 / tutorial / gameplay props / 007 | 292 / 201 / 166 / 61, zero failures |
| UI polish / 008 | 200 / 292, zero failures |
| Story 009 | **168 checks**, zero failures |
| Python asset/provenance tests | **31 tests**, zero failures |

The launch-range count increased from 974 because its existing dynamic checks now also inspect Story animation metadata; the harness expectation was updated accordingly. The only existing menu fixture change is four→five main-menu entries. Production CPU, combat rules, damage, initiative, clock, music assets and movement settings are unchanged.

`tests/test_story009.gd` runs the actual Story and Versus main-scene instances against identical timestamped inputs and compares acceptance, pending target, target displacement, consumed beat and semantic step pose. Cases include same-beat duplicate taps, valid early taps across release, late taps, early/late misses, sustained hold/release, reversal and low+direction. It also checks no damage, exact same actor/position/scale at handoff, no conductor/music restart, cinematic input clearing, pause/resume, Continue, save validation, replay/skip, environment loop/offset/stop, exit timing and restored Arcade presentation.

`tests/test_story009_assets.py` verifies the 12+4 frame inventory, originals' hashes, RGBA transparency, native retained source pixels, padding and no mipmaps. Automated pixel provenance does not establish character identity or visual quality; the imported art was also reviewed in actual Godot renders.

The real native player completed the entire menu→cinematic→traversal→exit→Continue→Arcade route using its **production monotonic conductor/audio clock**. The demonstration drives scripted InputMap keyboard events through `_unhandled_input`; it never assigns traversal positions, combat results or health. This is interactive automated verification, **not human physical-keyboard playtesting**.

Rendered review found and fixed a distracting foreground-strip edge, unsupported lowercase diagnostic glyphs, a numeric JSON tempo producing the nonexistent `120.0` music key, and stale debug/overlay drawing after Continue or leaving paused Story. Regression checks cover music selection, handoff continuity and menu/overlay cleanup. The final screenshots and movie show the corrected versions.

## Continuous recording and graphical evidence

The continuous, uncut native Godot recording with game audio is **`output/milestone-009.avi`**: **1,855 frames at 60 FPS, 30.917 seconds, 320×180**. It shows launch/intro, main menu, Story/New Game, all eviction poses, idle/control handoff, eight rightward steps, idle, four leftward steps, duck/stand, a deliberate ~250 ms miss, a held direction with no repeat, the right boundary, completion, Story menu, Continue and an ordinary Arcade start. The recorded route consumes 20 movement taps, including the boundary-clamped final step.

The movie uses an **explicit test-only offline clock** (`--record009`) for deterministic MovieMaker output. Production Story has no injected/delta clock. A separate native run verifies the same route against production time. Neither run is physical keyboard or subjective listening verification. Selected actual screenshots are under [`docs/screenshots/milestone-009/`](../screenshots/milestone-009/); the desktop capture is 1280×776 including window chrome, with a 1280×720 game area. The actual AVI frames were also decoded and inspected, including Continue and return to Arcade, rather than relying only on separate screenshot exports.

The recording's PCM is 48 kHz stereo 16-bit, **5,936,000 audio bytes**, with zero clipped samples. Audio statistics, hashes, exact traversal trace and run summaries are in [`milestone-009-evidence.json`](milestone-009-evidence.json). Captured audio was passed to the local playback device; this establishes playback availability, not perceptual contact synchronisation or balance. No listening judgement is claimed.

Reproduce:

```sh
bash tools/check.sh
/Applications/Godot.app/Contents/MacOS/Godot --path . \
  --log-file output/009-live.log --scene scenes/tests/story009_demo.tscn -- --desktop009
/Applications/Godot.app/Contents/MacOS/Godot --path . \
  --log-file output/009-movie.log --fixed-fps 60 \
  --write-movie output/milestone-009.avi \
  --scene scenes/tests/story009_demo.tscn -- --record009
```

Originals and derived resources/manifests are committed; movies, extracted audio, logs and temporary test files remain ignored in `output/`. Relevant changes are the Story scripts/scene, shared movement helper, `data/story_009.json`, native artwork importer/derivatives/manifest, menu/main routing, focused tests/demo, `tools/check.sh`, README and this report/evidence.

## Remaining review limits

Owner review is still required for physical keyboard focus/rollover, subjective rhythm feel and audio balance/perceptual synchronisation. The original source house is already clipped at its extreme left edge; that edge stays at the viewport boundary. No replacement art or missing head-shake was invented. Earlier FreeSFX commercial licensing remains unresolved as documented in Milestone 008; only already-integrated short effects are reused. Godot emitted the environment's existing certificate/editor-settings and ObjectDB/resource teardown diagnostics; passing runs have no script parse/assertion failures. Screen 02, enemies and inventory are outside this milestone.
