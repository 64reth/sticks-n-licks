# Milestone 010 — Reusable rhythmic coconut palm

Implemented on `development` from Milestone 009 (`6562fcf`). Screen 01 now contains one decorative palm behind the house. The approved movement, cinematic, audio, save and menu rules are unchanged.

## Source inspection

The owner asset is **`assets/environments/props/coconut_palm.png`**, not an assumed extensionless file. It is **1448×1086 RGBA**, containing **eight frames in four columns and two rows**, with **362×543** cells. SHA-256: `41c4fed20fffbeb4547bc07bb40e9ba526ff7db047e5b943de7982f7b7aa78a9`.

The original was inspected programmatically and visually, including compositing it over navy to assess actual alpha. Alpha ranges from 0 to 255. The sheet has faint low-alpha black/red/yellow haze outside the visible trees (many red pixels have alpha 1); these are not opaque borders or a solid background. The direct source rendering retains this alpha. No source pixels were overwritten, recoloured or resampled, no replacement art was generated, and no frame derivatives were needed. The alpha haze is not visible in the reviewed native composition.

All eight visible silhouettes (alpha ≥64) have padding within their cells, including the far-right fronds of frame 5: its right bound is X=359, leaving three native pixels before the next cell. There are no visibly amputated fronds. Height variation is small and authored: roughly 473–479 native pixels. Trunk bases shift horizontally across the columns and one pixel vertically across the rows. Drawing offsets correct those shifts while preserving a uniform scale and the original shape.

[`docs/assets/milestone-010.json`](../assets/milestone-010.json) records the source hash, exact regions, visible bounds, anchors and sequence. Anchors are local trunk-base positions:

| Frame | Cell | Trunk-base anchor | Reviewed role |
| --- | --- | --- | --- |
| 0 | column 0, row 0 | (139, 513) | Neutral |
| 1 | column 1, row 0 | (134, 513) | Left onset |
| 2 | column 2, row 0 | (131, 513) | Left peak |
| 3 | column 3, row 0 | (128, 513) | Return toward centre |
| 4 | column 0, row 1 | (139, 512) | Neutral transition |
| 5 | column 1, row 1 | (134, 512) | Right onset |
| 6 | column 2, row 1 | (131, 512) | Right peak |
| 7 | column 3, row 1 | (128, 512) | Return toward centre |

Visual review supports the supplied row-major order for the requested left/centre/right phrase. The return poses are slightly asymmetric; they are retained as authored, without mirroring, invented in-betweens or texture blending.

## Reusable component and layering

`scenes/props/coconut_palm.tscn` contains one `CoconutPalm` Node2D using `scripts/props/coconut_palm.gd`. Its position and depth use normal Node2D `position` and `z_index`; it exports uniform `display_scale`, `phase_offset_beats` and `start_frame`. It receives a `RhythmConductor` through `bind_clock()`, without accessing Story Session, the fighter or the eviction timeline. It can be instantiated on future screens without new animation code.

All instances use the same preloaded original `Texture2D` and constant region/anchor/sequence tables. Rendering selects a source region directly. Local draw positions and dimensions are rounded, the placed root position is snapped to integer pixels, filtering is nearest and mipmaps are disabled. There is no collision, shader, AnimationPlayer, timer, RNG or generated texture.

Screen 01's single instance is at **(42, 149)** with **scale 0.24**, relative depth **−1** and phase offset **0**. Its crown appears above the roof; its trunk/base are naturally concealed behind the house. Visible fronds remain inside the viewport and below the normal HUD text. The door, slipper, eviction trajectory, fighter and walking corridor remain clear.

To place the prop behind the existing house, the unchanged sky/street drawing was moved into `StoryBackdrop` at depth **−2**. The Screen 01 parent still draws the house and dust at depth **0**, with their original coordinates, scale, poses and timing. Thus the order is backdrop → palm → house/dust → fighter → CanvasLayer UI. `StorySession.start()` only adds a call binding the loaded screen to its existing conductor. No movement/input/combat/CPU/conductor/audio/settings code changed.

## Conductor synchronisation

The component samples the existing authoritative conductor boundary and fractional phase:

```text
absolute_beat = phrase × 4 + beat − 1
                + clamp((conductor.now() − beat_time) / duration(), 0, 1)
frame = reviewed_sequence[floor(mod(absolute_beat + phase_offset_beats + start_frame, 8))]
```

Before the conductor's initial beat dispatch, phase is zero. `duration()` belongs to the existing conductor; there is no second BPM calculation or elapsed-delta musical clock. Deriving phase from the current boundary also respects phrase-boundary tempo changes rather than dividing an entire song epoch by a new tempo.

Beats 1–8 select source frames **0,1,2,3,4,5,6,7**, then wrap to 0. At 120 BPM the eight-beat loop lasts four seconds. Fractional phase provides deterministic boundary selection and fractional offsets; it does not blend images or introduce subpixel movement. The authored pose changes supply the gentle sway. Fighter movement remains discrete, exactly as approved.

Positive offsets advance the phrase: offset **+2** makes a second palm start at source frame 2 when an offset-zero instance is at frame 0. Start-frame selection adds a whole-frame advance. Both are deterministic and support looping from any conductor phase.

Pause freezes `conductor.now()`, so the palm freezes without its own pause timer. Resume has no wall-time catch-up. Restarting Screen 01 binds a fresh prop to the conductor's **current** phase; it does not restart the palm phrase. Skip and the idle/control handoff do not touch its phase. Leaving Story hides/stops its screen through the existing lifecycle; a new Story session follows that session's existing conductor start.

## Performance and lifecycle

Each palm is one drawing node. A visible bound instance samples a few numbers each frame, but only queues a redraw when its source frame changes. It creates no images, textures, particles or animation resources per frame. Multiple instances share the same source texture; there are no extra gameplay/physics nodes. The original texture is loaded once through Godot's resource cache.

The existing screen manager frees replaced screen nodes. Automated lifecycle checks confirm old palms are freed after restart and no palm instance survives game teardown. No heap/GPU profiler benchmark is claimed; the resource-sharing and node-lifecycle assertions establish the intended lightweight architecture.

## Tests

`tests/test_palm010.gd` adds **353 checks** covering all eight source regions, viewport-independent component properties, integer draw rectangles, trunk anchoring, four loop cycles at fractional phases, deterministic offsets/start frame, shared resource identity, supported conductor tempos, pause/resume, actual Story binding/layering, full cinematic-to-control continuity, restart/skip/re-entry, screen teardown and unchanged **16-pixel / 160 ms** player movement.

`tests/test_palm010_assets.py` adds **two tests** checking the original hash/dimensions/RGBA, each cell's visible alpha padding, substantial transparent background, lossless import and disabled mipmaps. Existing Python tests remain intact: **31 → 33**, solely because of these additions. No existing assertions were weakened or removed.

The complete `bash tools/check.sh` run exited **0**, with zero failures. It includes both new tests and all prior regressions:

| Suite | Result |
| --- | ---: |
| Rules / controls | 51 / 46 checks |
| Media / launch-range | 3348 / 1020 checks |
| Idle/movement / HUD / live movement | 676 / 189 / 168 checks |
| CPU | **1,795,853 checks / 900 measured matches** |
| Milestone 006 / tutorial / gameplay props / 007 | 292 / 201 / 166 / 61 checks |
| UI polish / 008 / Story 009 | 200 / 292 / **168** checks |
| Palm 010 | **353** checks |
| Python | **33 tests** |

Final measured results and the complete-suite exit status are recorded in [`milestone-010-evidence.json`](milestone-010-evidence.json).

## Native verification and continuous recording

The real Godot player was launched and driven through the existing InputMap keyboard path. Native 320×180 screenshots, normal desktop scaling and sampled frames decoded from the actual AVI were inspected for transparency, frame ordering, frond clipping, house-relative depth, fixed ground base, fighter visibility, full eviction/recovery and uninterrupted traversal. The eight poses produce a restrained crown sway; the house and cinematic anchors do not move. A temporary two-palm configuration shows a full eight-beat loop with offsets 0 and +2. Diagnostics were hidden for that view so both crowns remain visible. The second instance is removed before the demonstration finishes and is absent from the production scene.

The continuous, uncut recording is **`output/milestone-010.avi`**, **1801 frames at 60 FPS = 30.017 seconds**, with game audio. It contains launch/menu → Story/New Game → full eviction → handoff → eight forward and four backward steps → pause/resume → cinematic replay/skip → two independent phase-offset palms → restored one-palm screen.

Recording metadata confirms the same conductor epoch and music restart count across cinematic, handoff, traversal, replay and skip. At the two-palm check, frames **0/2** and **2/4** demonstrate the +2 phase offset. The final report contains exactly one remaining palm. A separate native run uses the **production monotonic conductor clock**; the movie uses an explicit `--record010` test-only clock for deterministic MovieMaker output. Both drive scripted keyboard events and are **not human physical-keyboard playtesting**.

The captured PCM is 48 kHz stereo 16-bit: **5,763,200 bytes**, **zero clipped samples**. The extracted audio was played through the local device. This verifies captured/playable audio, without claiming subjective balance or perceptual listening review. Original music and routing were not modified.

Selected screenshots are in [`docs/screenshots/milestone-010/`](../screenshots/milestone-010/). The movie, audio mix, full logs, decoded contact sheet and run reports stay in ignored `output/`. The evidence JSON records hashes, dimensions, phase reports and actual test results.

Reproduce:

```sh
bash tools/check.sh
/Applications/Godot.app/Contents/MacOS/Godot --path . \
  --log-file output/010-live.log --scene scenes/tests/palm010_demo.tscn -- --desktop010
/Applications/Godot.app/Contents/MacOS/Godot --path . \
  --log-file output/010-movie.log --fixed-fps 60 \
  --write-movie output/milestone-010.avi \
  --scene scenes/tests/palm010_demo.tscn -- --record010
```

## Scope and remaining review

Only Screen 01 is populated. Reuse on village roads, coastal paths, rural/cane-field approaches and later screens is supported by the component but not implemented here. No gameplay mechanics, screens, music, fighter animation or timing system were added. The original low-alpha haze and authored return-pose asymmetry remain; owner review can judge sway taste without substituting artwork. Physical keyboard feel and subjective audio review remain separate from scripted graphical verification. Existing Godot certificate/editor-settings/ObjectDB teardown diagnostics are documented in the output; no passing run contains script parse/assertion failures. Unrelated untracked FreeSFX archive and logo files remain untouched.
