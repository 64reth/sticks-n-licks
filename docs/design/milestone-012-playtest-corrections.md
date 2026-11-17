# Milestone 012 — Playtest corrections

Baseline: `683288926eff1e2021bb7b4aa02440f5b20d2475`, development. Milestone 011 remains unaccepted by the owner. This revision is ready for owner review; scripted demonstrations do not constitute human playtesting.

## Requirement audit and measured results

PASS means implemented, checked and inspected in native Godot renders. It does not mean owner acceptance. PARTIAL explicitly identifies remaining perceptual verification.

| Requirement | Root cause at baseline | Implementation / verification | Status |
| --- | --- | --- | --- |
| Compact bottom dialogue | Top panel was 304×58, with no delivered pagination/typewriter | 304×32 bottom panel: 44.83% less area, unchanged 8px font, two lines, conductor typewriter, paginated full text. F reveals before advancing. Bounds and all dialogue checked. | PASS |
| Door, final warning, kick | Relative beat 3 selected house frame 2 containing a foot before warning completion | Explicit opening → door wait → warning → kick wait → flight states. Actor hidden until airborne; next-beat kick after final acknowledgement; quarter-beat foot animation. Warning held without premature entrance. | PASS |
| Unarmed idle | Static master pose; no standing-source compatibility audit | Pickup frame 1 plus eight-beat, one-pixel upper-body breathing. Lower body remains fixed. Eight uninterrupted native beats, identical boot silhouettes at both phases. | PASS |
| Preferred unarmed duck | Race frame 9 selected instead of preferred kicked crouch | Kicked frame 0, existing S handling/duration/rules; repeated native duck/stand. | PASS |
| Unarmed damage | Armed hurt selected during unarmed traversal | Existing kicked frames 1, 8, 11 form a conductor-sampled recoil/recovery. No armed block or complete eviction sequence. | PASS |
| Animation continuity | `AnimatedSprite2D.stop()` reset manually sampled frames to zero | Story sampling uses `pause()` to preserve the conductor-selected frame. Tests verify second movement pose and all three damage frames. Same actor, root scale and baseline throughout. | PASS |
| Actionable objective HUD | Campaign heading and child-step labels occupied HUD | Active parent quest's configurable `hud_text`; title retained in quest details. No permanent Rent Due heading or placeholder/debug labels in normal view. | PASS |
| Currency and inventory | Textual EMPTY shared presentation with money; reported question-mark currency not reproducible at current baseline | `BDS $0` / `$5` inspected with existing font; separate 18×16 empty/crate/stick graphical slot. Currency glyph/font artwork unchanged. | PASS |
| Graphical controls | Bare footer text, no reusable keycap renderer | InputMap-derived bordered keycaps; contextual F, S warning, Tab quest. No invented gamepad glyphs. | PASS |
| Vendor beat-four interaction | Generic movement ±160ms window on any beat | Fresh F only on beat 4, inclusive existing ±70/±140ms combat tolerances. Early/late/held failures checked; dialogue F then uses normal reveal/advance. | PASS |
| Two roads, four lanes | Single 16-beat vehicle/crossing | Four independent conductor cycles, opposing lane directions, per-lane warnings, road CROSS/WAIT signals, safe verges and central refuge. Four native mid-pass captures. | PASS |
| Collision and checkpoints | Single crossing lacked two-road refuge recovery | Last reached safe checkpoint, unarmed recovery; money/crate/progress preserved. Road phase continues through collision. Central checkpoint persists in validated optional v2 field. | PASS |
| Shared conductor and established rules | Must preserve approved core systems | No changes to CombatInput, RhythmMovement, Bout, RhythmConductor, CPU controller, Fighter, main orchestration or palm implementation. Existing movement/range/CPU/palm suites pass. | PASS |
| Save and Continue | Maintain existing v1/v2 saves | Existing migration preserved; legacy road saves recover to safe verge (or far verge after crossing), invalid checkpoint rejected. | PASS |
| Continuous native demonstration | Required end-to-end evidence | 125.317s uncut AVI, game audio, menu → cinematic → idle/duck/walk → vendor → crate/roads/collision → payment → cane → fight → completion. Production-clock repeat also completed. | PASS |
| Physical feel and perceptual audio approval | Automated inputs cannot establish subjective acceptance | Native renders and recorded PCM inspected; audio sent to system playback. Physical keyboard feel and subjective audio synchronisation remain owner review. | PARTIAL |

## Complete character-source inspection

All 25 source poses were visually inspected, including alpha padding, proportions, feet and transitions. Exact bounds, extraction rectangles, source hashes and roles are in [the animation audit](../assets/milestone-012-animation-audit.json). Original PNGs and existing derivatives were preserved.

- `assets/characters/fighter_01/spritesheets/fighter_01_pickup.png`: 2172×724 RGBA, alpha 0–255; 13 irregular poses in two rows (7+6). Frames 0–2 are upright; 3 lowered anticipation; 4 turn/reaction; 5 head gesture; 6 eyes-closed gesture; 7 ready; 8 run; 9 crouch/run; 10 run; 11–12 armed and excluded. SHA-256 `93bca3dcaa2feba9c2883172f457055f7ffed7490792115ea5911d0a49f59f26`.
- `assets/characters/fighter_01/spritesheets/fighter_kicked_sheet.png`: 1448×1086 RGBA, alpha 0–255; twelve 362×362 cells, 4×3. Frame 0 braced crouch, 1 startled recoil, 2 airborne, 3 seated landing, 4–6 seated reactions, 7 hands/knees, 8 rising, 9–10 dusting, 11 upright recovery. SHA-256 `c1f4e99bac63aaab92b01b213a7b852012ec001b5b6eb168826a83acefcaba4c`.

Idle uses existing `frames/milestone_002/pickup/001.png`, padded 768×768, baseline 744, calibration 64/240. Other genuine standing poses exist, but their foot spreads shift roughly 1–2 logical pixels when alternated. They were deliberately excluded from the planted idle loop. The rendering-only `UnarmedPresentation` child shares the existing fighter; it adds no controller, movement state or clock. A split at native row 660 keeps the lower body fixed while translating only the upper body by one integer pixel during the middle half of an eight-beat phase. A repeated waist row bridges the seam. There is no breathing scale change or whole-body bounce.

Duck uses `assets/story/009/fighter_00.png`. Recovery uses `fighter_01.png`, `fighter_08.png`, `fighter_11.png`, calibrated 64/289. Root scale stays `(1,1)`; source calibration compensates different source character sizes rather than animating scale. This is an explicitly assembled existing-art reaction, not a newly authored damage sheet. Native review found it usable; no blocking artwork request or new fighter artwork is needed for this revision. Eviction starts airborne with frame 2, never the crouch. All visual samples use the same conductor, and combat animation completion never awards damage.

[Idle phase 0](../screenshots/milestone-012/idle-lift0.png) · [Idle phase 1](../screenshots/milestone-012/idle-lift1.png) · [Duck](../screenshots/milestone-012/duck-8.png) · [Walk stop](../screenshots/milestone-012/walk-stop.png) · [Damage 0](../screenshots/milestone-012/damage-frame0.png) · [Damage 1](../screenshots/milestone-012/damage-frame1.png) · [Damage 2](../screenshots/milestone-012/damage-frame2.png).

RGB comparison found minor background-palm alpha changes behind the actor, but the dark boot silhouette is identical at both breathing phases. Render positions remain integer aligned, Y=150, with nearest filtering and no source resampling.

## Dialogue, HUD and interaction

`StoryDialogue` wraps at the actual font's measured width, two lines per page, 32 characters per conductor beat. A fresh F reveals the current page; another fresh F advances. Holding F cannot skip pages. Cinematic wife acknowledgement gates door and kick states, so a long warning pause never leaks a foot or fighter entrance. Normal dialogue is not locked to beat four.

`StoryOverlay` places the panel at `(8,144)` with 304×32 bounds. Speaker and body occupy separate baselines; the graphical F cap reads Reveal or Next. Long vendor text was inspected on both pages. Objectives come from quest data and the active parent step, including delivery while crossing the roads. Currency and slot are separate. F3 diagnostics remain opt-in. `ControlPrompt` reads actual keyboard bindings from InputMap; unsupported binding types do not display misleading keycaps.

[Final warning hold](../screenshots/milestone-012/warning-hold.png) · [Airborne entrance](../screenshots/milestone-012/airborne-entrance.png) · [Vendor page 1](../screenshots/milestone-012/dialogue-vendor-1-page0-full.png) · [Vendor page 2](../screenshots/milestone-012/dialogue-vendor-1-page1-full.png) · [Invalid vendor beat](../screenshots/milestone-012/vendor-invalid.png) · [Paid / empty slot](../screenshots/milestone-012/paid.png).

## Traffic and world timing

`data/story/traffic_012.json` configures Road A at X80–128, Road B at X176–224. Lane centers are 92/116/188/212, cycles 16/20/24/28 beats, directions down/up/down/up. Each has two warning beats and two travel beats. Vehicle Y interpolates from conductor phase; warnings and collision sample the same geometry/time. There are no independent traffic timers, scene allocations or RNG. Existing palm timing is untouched.

Safe checkpoint positions are 68, 148 and 244. Crossing takes five then six unchanged movement steps. A collision returns only to a checkpoint already reached, keeps crate/cash/quest state and preserves traffic origin. Continue can restore the center refuge. Screen completion requires the far verge and completed final movement step.

Exhaustive 1,680-beat combined-cycle checks found 336 safe starts for Road A and 560 for B. The conservative full-road clearance reservation can require up to 26 beats waiting on A (13 seconds at 120 BPM), 19 on B (9.5 seconds). This is a pacing limitation for owner review, not a permanently blocked crossing. Individual lane GO signs describe that lane now; the road-level CROSS signal reserves enough time for the complete legal crossing.

[Lane 1](../screenshots/milestone-012/lane0-vehicle.png) · [Lane 2](../screenshots/milestone-012/lane1-vehicle.png) · [Lane 3](../screenshots/milestone-012/lane2-vehicle.png) · [Lane 4](../screenshots/milestone-012/lane3-vehicle.png) · [Central refuge](../screenshots/milestone-012/central-refuge.png) · [Recovery](../screenshots/milestone-012/traffic-recovery.png).

## Regression and recording evidence

`bash tools/check.sh` exited 0. All suites passed: rules 51; controls 46; media 3,348; launch/range 1,034; idle/movement 676; HUD 189; live movement 168; CPU 1,795,853 checks / 900 measured matches; milestone 006 292; tutorial 201; props 166; milestone 007 61; UI polish 200; milestone 008 292; Story 009 168; palm 010 353; Story 011 176; Story 012 186; Python 38 tests. No failures. Existing macOS certificate diagnostic messages remain in engine output.

Existing 009/010/011 assertions remain, with fixtures updated for explicit wife acknowledgements, reveal/pagination, beat-four vendor interaction and two-road crossing. Launch/range adds 14 existing metadata checks for new pose aliases; two Python tests validate all source hashes/frame audit records. The 186 new checks cover panel bounds, text pagination, input boundaries/holding, cinematic gates, frame progression, fixed idle position/scale, duck transitions, independent lanes, exhaustive crossing availability, checkpoint recovery, save compatibility and unchanged Bout damage.

Recording: [output/milestone-012-playtest-corrections.avi](../../output/milestone-012-playtest-corrections.avi), 7,519 frames at 60fps, 320×180, 125.317 seconds. SHA-256 `e759708d53fc7c9ce567fa2fc4948fd66399c42b1572a6bb466fbccd4b37b3d2`. Actual AVI frame samples were inspected across the whole route, alongside native PNG captures. Audio: stereo 48kHz 16-bit PCM, peak 0.60477, RMS 0.10992, zero clipped samples; system playback was invoked. Numeric PCM checks and system playback do not establish subjective listening or perceptual synchronisation.

The continuous run includes eight idle beats, three S duck/stand pulses, walking/stopping, invalid then valid vendor interaction, complete paginated dialogue, crate slot, all four traffic lanes, deliberate collision/recovery, both roads/refuge, BDS $5, cane duck, stick slot, existing fight and quest completion. A separate production-clock run completed in 127.166 seconds with BDS $5 and quest complete. The movie alone uses an explicit test clock; both runs submit scripted legal inputs and are not physical keyboard playtests. No position, damage, money or quest overrides drive the route.

Reproduce movie with Godot 4.6.2:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --log-file output/native012-evidence.log --fixed-fps 60 --write-movie output/milestone-012-playtest-corrections.avi --scene scenes/tests/story012_demo.tscn -- --record012 --desktop012
```

Run that scene without `--record012` for the production-clock scripted repeat. Movie and raw logs remain local ignored output; selected screenshots and [measured evidence](milestone-012-evidence.json) are versioned. The main F5 scene remains `res://scenes/main/main.tscn`.

## Owner acceptance loop

1. F5 → Story Mode → New Game. Reveal then acknowledge each wife line; hold the final warning and confirm no foot/fighter before acknowledgement.
2. Watch eight idle beats. Move with fresh A/D taps, stop, reverse, and repeatedly press S. Check planted feet, consistent size and clean recovery. Holding movement must retain existing no-repeat behaviour.
3. At the first vendor press F on beat 2, then a fresh F on beat 4. Reveal/advance every page; inspect the bottom panel and graphical prompts.
4. Pick up the crate; observe all four lanes. Wait for each road's CROSS, cross to the refuge, and deliberately fail a lane. Verify checkpoint, crate, cash and quest retention, including Continue from the refuge.
5. Deliver for BDS $5, inspect the empty slot, duck the cane, collect the stick and finish the fight. Pause/resume and confirm no world drift.
6. Review the continuous recording with audio. Judge reaction-art suitability and conservative road waiting times. These subjective checks remain owner acceptance, not an automated PASS claim.
