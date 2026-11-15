# Milestone 002 — supplied sprites and original soundtrack

This initial milestone report is preserved as history. The later [Blue idle integration](../design/blue-idle-and-movement-repair.md) adds the supplied four-frame idle; the current aggregate is 20 sheets / 117 frames.

## Source preservation and sprite processing

Discovered **19 supplied PNG sheets**, Red 10 / Blue 9. There were no newly supplied standalone frames. Extracted **113 individual frames** into each fighter's `frames/milestone_002/` directory (Red 63 / Blue 50), with matching SpriteFrames resources and per-fighter manifests. The manifest in `docs/assets/milestone-002-sprites.json` records every source hash, rectangle, native pixel translation, filename, count, alpha result and state mapping.

Source layouts are irregular: mostly 2172×724, one 2176×723 and two 1536×1024 walk sheets. They are not 96×96 grids and contain antialiased edges plus low-alpha disconnected haze. Supplied originals are untouched. Derived frames remove isolated alpha haze outside the visible silhouette; retained RGBA values are bit-for-bit source values. There is no image resampling, recolouring or destructive resizing. Native frames are transparently padded to 768×768, anchored at boot centre / baseline pixel 744. The larger canvas is intentional: squeezing these sources into 96×96 files would resample or clip them.

Godot applies a uniform per-animation display scale based on the supplied standing pose (roughly 64 pixels tall) and nearest-neighbour filtering. Proportions and frame-to-frame scale are preserved; the same ground anchor applies to every state. Runtime facing is relative to source orientation: Red is natively right-facing, Blue natively left-facing. Blue therefore starts unflipped. Existing independent hitboxes and logical movement constraints are unchanged.

The old `references/OpenAI Playground 2026-11-15 at 13.48.11.png` was already absent at inspection. Its hash exactly matches the supplied Red race sheet (`34bc0d…e7746e`), so that artwork is preserved at its supplied new location. No original was deleted by this processing.

## Imported states and honest fallbacks

Both fighters use actual supplied art for master/idle, anticipation, race launch/running, embarrassed false start, combat-ready poses, forward/backward walking, high/mid/low attacks and high/mid/low blocks. Each fighter has 26 registered states; these include aliases and missing-art fallbacks, not 26 distinct authored animations.

- Race sheets: 13 poses each. The master uses pose 0; anticipation uses existing idle/crouch poses; launch/run uses poses 7–10; embarrassed reaction ends at the head-scratch pose 12.
- Attacks: 5 frames per height per fighter. Blocks: 4 per height. Walking: 6 per fighter. Red idle: 4. Blue has no dedicated idle sheet; supplied race idle poses are reused.
- Blue pickup: 4 supplied frames. **Red's file labelled pickup depicts 13 race/idle poses rather than a stick pickup.** Its frames are preserved/extracted, but that semantic assignment is rejected; Red retains a supplied ready pose during pickup.
- Dedicated combat-idle artwork is absent; existing ready/idle poses are reused. Perfect parries reuse corresponding block art with an additional spark, not invented parry frames.
- Authored high/mid/low hit reactions, stagger, knockdown, victory and defeat are absent. Existing character poses plus tint/spark feedback keep identity intact; these states still need artwork. There is no fabricated finishing-animation claim.

Movement animation starts with conductor beats 1–3. Beat 4 sets no movement target. Known early attack/block combinations present their authored impact frames at beat 4 (attack frame 3, block frame 2); valid late combinations present immediately when received. Scoring still waits for the agreed ±140 ms timing window and 100 ms direction buffer. Animation signals never determine hits or initiative. Stopping an animation cannot stop resolution. Race launch follows GO; pickup follows race resolution. Pickup-to-combat playback now starts at the next four-beat boundary after its minimum transition, keeping music changes musical without changing scoring/input windows.

## Audio inventory and assignment

All **8 recordings** are original 44,100 Hz stereo 24-bit PCM WAV, with embedded `Tempo: BPM` labels at frame zero. Full metadata, sample counts and source hashes are in `milestone-002-audio.json`.

| File | Duration | Assigned role |
|---|---:|---|
| `120bpm/menu_120.wav` | 8 s | Menu loop |
| `120bpm/standoff_120.wav` | 8 s | Anticipation bed plus authoritative synthetic count/cue |
| `120bpm/combat_120.wav` | 8 s | Opening combat |
| `140bpm/combat_140.wav` | 6.857143 s | Pressure combat |
| `160bpm/combat_160.wav` | 6 s | Frenzy combat |
| `120bpm/intro_120.wav` | 8 s | Optional intro/round-transition preview; not inserted into established bout flow |
| `120bpm/victory_120.wav` | 4 s | Shared victory arrangement at next phrase boundary |
| `120bpm/defeat_120.wav` | 4 s | Optional defeat preview; not played simultaneously with victory |

No distinct recorded race snare/cutoff or impact/block/parry SFX are supplied. The authoritative race cue retains the synthetic accent/cutoff experiment. Standoff overlays the established three-count timing cues. The menu and combat use the owner recordings; missing optional effects stay silent.

**Musical placement is now owner-confirmed:** beat 1 is at sample zero and full-file boundaries are intended. This explicit confirmation, rather than filename/waveform inference, establishes `beat_zero_seconds: 0` and sample-exact loop boundaries. The recordings have exact 16-beat lengths (8 beats for outcome arrangements). Menu/standoff/combat repeat; intro/victory/defeat are one-shot role assignments. A first-signal measurement in the inventory remains a waveform observation, not how the downbeat was determined.

Confirmed offsets/loop points are in `data/audio.json`; leave future unconfirmed files null until reviewed. Output calibration is `audio_latency_ms` in combat settings, separate from input latency. The single music player replaces tracks at transitions; effect/cue playback is separate and intentional. Music does not restart each exchange. Tempo changes and victory music are phrase-boundary transitions. Loop playback positions are unwrapped against the shared monotonic anchor so the gameplay clock never jumps back when a recording loops. Beat durations remain 500 / 428.571 / 375 ms.

## Developer review

Open either scene in the existing Godot project and press F6 (F5 continues to run the main playable scene):

- `scenes/tests/animation_preview.tscn`: both fighters on checkerboard with common ground/centre guides. Left/Right selects state; Space pauses; comma/period steps individual frames; brackets adjust speed. It shows frame index/count and fallback notes. Use it to inspect costume, transparency, order, speed, facing and alignment.
- `scenes/tests/audio_test.tscn`: 1/2/3 tests each BPM independently. Q menu, W standoff, E intro, V victory, D defeat schedule section changes at a phrase boundary. Brackets preview ±5 ms beat-zero adjustment; minus/equals preview output compensation. These review adjustments are not silently saved. File, BPM, beat/phrase, offset, calibration and pending section appear on screen.
- Main F3 overlay retains input/movement timing and adds actual audio filename, recording BPM, beat-zero confirmation, output compensation and pending tempo.

Executed results are in `docs/verification.md`. Visual inspection covered source/extracted contact sheets and actual Godot checkerboard renders. Audio runtime verification exercises playback and clock continuity; **perceptual synchronisation, race arrangement, device calibration and loop seams still require listening review; downbeats and full-file loop placement are owner-confirmed**. No paid generation was requested or performed.
