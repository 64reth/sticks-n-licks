# Milestone 007 — arcade presentation

Presentation integration on `development`, preserving gameplay props commit `3f023f1`, the ongoing tutorial work and original artwork. Combat, movement, CPU observation/planning, scoring, race and match rules remain unchanged. The playable root scene is still `scenes/main/main.tscn`; F5 opens the integrated experience.

## Approved sources and inspection

`docs/assets/milestone-007.json` records original hashes, dimensions, alpha counts, source regions and WAV metadata. No images or audio were regenerated, recoloured, overwritten or exported as resized derivatives.

| Source | Inspection / use |
| --- | --- |
| `assets/environments/backgrounds/bim_sky.png` | 1672×941 RGB, opaque sunset/sea/boat. Dedicated intro sky, slides down. |
| `assets/environments/backgrounds/bim_foreground.png` | 1672×941 RGBA, 698,065 fully transparent pixels; palms/houses/ground around a transparent centre. Dedicated intro scenery, rises. |
| `assets/ui/arcade/logo_animated.png` | 2172×724 RGBA, **six** horizontal complete title poses at 362px spacing, rather than three square frames. Both speakers are already present. |
| `assets/environments/props/bouncing_speaker_01.png` | 2172×724 RGBA, six irregular squash/stretch/rebound poses. Uniform 362px slices would clip the wide second pose (which crosses cell boundaries). |
| `assets/ui/arcade/how_to_play_02.png` | 2172×724 RGBA, movement illustration. Page 1. |
| `assets/ui/arcade/how_to_play_01.png` | 1672×941 RGBA, raised/crossed sticks. Combat page 2. |
| `assets/ui/arcade/how_to_play_03.png` | 2172×724 RGBA, celebrating fighter and three stars. Winning page 3. |
| `assets/audio/music/120bpm/intro_120.wav` | Original stereo 44.1kHz, 352,800 samples / 8 seconds, 120 BPM. Existing owner-confirmed beat 1 at sample zero. One-shot. |

Sky and foreground share **exactly the same native dimensions, scale (320/1672), source origin and final integer position (0,0)**. This yields a 320×180.096px proportional canvas, clipped at the viewport bottom; there are no exposed gaps, independent crops or mismatched transforms. Only the integer Y positions animate. Source alpha is preserved on the foreground. Unrelated gameplay-stage art is never used for the title.

## Architecture and cue configuration

`ArcadeIntro` is a dedicated Control component in the existing main scene's CanvasLayer, above the existing menus. Its children are sky → foreground → `TempoLogo` → high-contrast prompt panel/text. It uses a short cubic ease-out for opposite-direction layer entrances. A restrained 6px logo bounce ends before its beat animation continues at a fixed anchor. Native rendering is 320×180 with nearest filtering.

`data/intro.json` owns resource paths, BPM, beat-zero reference, all cue times, entrance durations, logo placement/width and the six-step pulse sequence. Times are seconds on the intro presentation timeline:

| Cue | Seconds | Duration / behavior |
| --- | ---: | --- |
| Music start | 0.0 | Original eight-second one-shot, once |
| Sky entrance | 0.0 | 0.75s down from Y=-181 to 0 |
| Foreground entrance | 0.5 | 0.75s up from Y=181 to 0 |
| Logo entrance | 1.5 | 0.35s bounce / fixed final centre (160,72) |
| Speakers activate | 2.0 | Six configured phases per 120 BPM beat |
| Start prompt | 3.0 | `PRESS ENTER TO START`, gently pulses |
| Intro ready | 3.5 | Enter opens the main menu |

These arrangement cues are **provisional**, not claimed as verified bass accents. The track's downbeat and full-file boundary were already owner-confirmed; this does not establish the best visual entrance cues. Edit the map to tune them without scene logic. `music_start` supports a delay; adjust subsequent cue times consistently. `validate()` checks cue order/assets/tempo.

Production reads `AudioDirector.audio_time()` while the intro plays, using the existing latency-aware playback timeline. After the one-shot ends the presentation retains its original monotonic anchor, so switching to menu music cannot rewind/replay the scene. A guarded pending flag makes that music transition once, using the **same** `AudioStreamPlayer`. Enter/skip does not seek, restart or overlap the track; the intro can finish under the main menu. Beginning a bout cancels the pending transition and follows the existing standoff audio path.

## Logo and stage speaker

`TempoLogo` draws directly from the original sheet. Inspection found small title-lettering differences between poses, not just translated copies. A non-destructive runtime composition keeps the approved central lettering region from pose zero and animates the supplied left/right speaker zones. Every segment uses the same scale/destination, eliminating title jitter without creating replacement lettering, adding speakers or exporting art. Source regions are recorded in the manifest. The shared existing alpha-cutoff shader removes source haze only during rendering; no original alpha is altered. Both speakers visibly squash, stretch and rebound around the stable title in the captures.

`BeatSpeaker` is reusable, has no collisions and never writes gameplay state. `data/presentation_sheets.json` records six reviewed irregular rectangles and their individual source-foot anchors. Source feet map to local (0,0) throughout deformation; destination coordinates are rounded. `sync(seconds,bpm)` chooses a frame from musical phase, with a configurable lower-intensity sequence and a rest-only zero setting. `display_scale` separately controls size. No per-beat node allocation or particles are used. Child lifetime follows the stage.

Only **Crop Over Festival (`stage_03`)** enables the demonstration, at integer (303,146), scale 0.055, behind fighters. Its per-stage `speaker` settings support enabled, x/y, scale and intensity. Other stages hide it, including a missing-stage fallback. Main supplies the existing conductor clock, current phrase origin and BPM; pause therefore freezes the prop and tempo changes remain aligned at phrase boundaries. It cannot obscure combat feedback above the fighters or change collision ground Y=150.

## Title input and tutorial

Main's existing keyboard route intercepts intro Enter/Escape before menu navigation. An unfinished intro consumes the first Enter to complete the visuals. The existing held-key set and repeat rejection require a release before a second Enter can open the main menu. A naturally ready title needs only one Enter. Escape completes an unfinished entrance or opens the menu from the ready title. Menu navigation and gameplay submission remain separate.

`TutorialPages` uses three short screens, real pixel-font labels, keycap graphics and direct original illustration sprites. The pictures are proportionally fitted into integer-positioned panels; no source copy is resized. Numbering was assigned by inspected visual content rather than filename order. Copy explains tap/step, beat-four combat and three-hit rounds. Best-of-3/5/7 shows the current 2/3/4 round-win requirement.

Controls were checked against InputMap and CombatInput: Red A/D move, W/S high/low, F execute; Blue arrows move, Up/Down high/low, **Right Shift** execute. MID uses facing-relative forward + execute (initially D+F / Left+Right Shift). The execute chord selects the same height for attack/defence; **initiative** decides which role applies. The tutorial says whose turn hits/blocks, and that defence matches height. It does not introduce a separate block key, held movement repetition or an execute-only MID.

Left/Right changes pages; Enter/Up do not change them. Escape returns through the menu stack. Pause has a direct How to Play item; closing it returns to the pause menu with audio/clock/CPU/positions/hits held. Returning from nested Options/Gameplay likewise returns to that previous page. Tutorial keys never reach `submit_action`.

## Verification and reproduction

`bash tools/check.sh` includes the prior full suite and 900-match CPU simulation, the preserved/adapted tutorial regression, and `tests/test_milestone007.gd`. Legacy menu fixtures explicitly bypass the newly added intro; intro behavior is independently tested through raw key events. The live movement lifecycle test traverses the two distinct intro presses before its existing setup path. Optional Python tests verify every reviewed original hash, dimensions/alpha and region bounds.

Continuous native graphical recording:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . \
  --log-file output/007-demo.log --fixed-fps 60 \
  --write-movie output/milestone007.avi \
  --scene scenes/tests/milestone007_demo.tscn -- --record007
```

It shows the full intro, rest/squash/stretch logo, prompt, Enter to menu, all three tutorial pages, return to menu, match setup/start on Crop Over Festival, the speaker, pause tutorial, return to pause and resumed CPU combat. Godot Movie Maker captures audio. `output/milestone007-demo-movie.json` (and `-live.json` for the production-clock run) records the cue log and the explicit injected-clock/synthetic-key limitation. Red uses the existing test-only player; Blue uses production CPU dispatch. The injected clock exists only under `--record007`.

Desktop verification additionally uses the real production playback/monotonic timeline, without `--record007`. Build the optional macOS test helper, then run:

```sh
swiftc -module-cache-path output/swift-module-cache \
  tools/capture_game_window.swift -o output/capture-game-window
/Applications/Godot.app/Contents/MacOS/Godot --path . \
  --log-file output/007-desktop.log --max-fps 60 \
  --scene scenes/tests/milestone007_demo.tscn -- --desktop007
```

The helper selects only the supplied Godot PID's layer-zero window and captures it by window ID, including when another application occludes it. It is test-only; Swift and desktop screen-capture permission are not gameplay dependencies. No generated executable, movie, dependency or `.godot` cache is committed. Native screenshots are under `docs/screenshots/milestone-007/` after verification; full recordings remain in ignored `output/`.

Physical keyboard playtesting and a listening review of musical accents/output latency remain manual requirements. Scripted key events and a native graphical run do not establish either. No changes to combat fairness or subjective balance are claimed from visual inspection.

## Measured results — 16 November 2026

The complete `bash tools/check.sh` run exited **0**: rule 51; controls 46; media 3,348; launch/range 974; idle/movement 676; HUD 189; live movement 168; Milestone 006 292; tutorial 201; gameplay props 166; Milestone 007 60 checks, all with zero failures. All **27 Python tests** passed. CPU fairness/replay tests passed **1,795,853 checks across 900 measured matches**. The existing legal CPU demo completed with 8 HIT / 4 BLOCK / 1 PARRY / 3 WHIFF events. A final focused intro run after adding missing-art detection passed **61 checks**, with no script errors. Existing Godot macOS certificate/ObjectDB diagnostics remain in prior suite logs.

The final unedited Movie Maker recording is **1,592 frames / 60 FPS = 26.533 seconds**, with 5,094,400 PCM audio bytes, including 3,902,118 nonzero bytes. This verifies an audio stream was captured, not perceptual sync. `output/milestone007.avi` contains the whole requested sequence. The separate production-clock desktop run also completed and resumed combat. All 17 targeted desktop captures succeeded; screenshots are 1280×776 including 56px window chrome around the 1280×720 game image. Native counterparts are 320×180.

Inspected both scales: entering sky/foreground, logo entrance/rest/squash/stretch, completed title/prompt, main menu, all three illustrations, pause tutorial/return and stage speaker/resume. The Barbados layers settle seamlessly; no title speakers are duplicated and no visible sprite/frame clipping was observed. The fixed lettering area is pixel-identical between rendered rest/stretch samples, while speaker zones change. The speaker is small and behind actors on one stage. All reviewed captures, including native/desktop counterparts, are committed in `docs/screenshots/milestone-007/`. Detailed counts, cue logs and the recording SHA-256 are in `milestone-007-evidence.json`.

The intro detects absent approved layers and falls back to the existing menu rather than substituting gameplay backgrounds or blocking launch. The supplied originals are all present in this delivery. The unused supplied static `logo.png` remains untouched outside the commit.
