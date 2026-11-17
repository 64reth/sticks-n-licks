# Milestone 011 — Playable Story Quest Vertical Slice

Baseline: Milestone 010, `da10d91`, on `development`. The complete **Rent Due! → A Stick To Share Licks** route now runs through six fixed-camera screens, with manual dialogue, a mandatory crate job, a safe crossing challenge, cane defences, stick pickup and the existing CPU combat encounter. Original movement, combat rules, music, artwork and the coconut palm implementation remain intact. New world art is explicitly replaceable placeholder drawing, not generated final artwork.

## Permanent timing architecture

The owner’s rule is recorded in [`rhythmic-world.md`](rhythmic-world.md) and `AGENTS.md`: every animated, moving or reactive Story element follows the existing authoritative conductor. `BeatWorld` is a read-only adapter around that conductor’s phrase, beat, boundary time and fractional phase. It exposes beat position, cycle phase, authored-pose selection and interpolation. It owns no clock or BPM and never accumulates delta.

| Element | Conductor personality |
| --- | --- |
| Fighter traversal | Existing fresh-tap 16px / 160ms step; existing acceptance windows; two unarmed race poses |
| Palms | Unchanged eight-beat component; existing source texture; deterministic offsets |
| Vendor nod / working gesture | Four-beat pose cycles, separate offsets |
| Placeholder clouds | Continuous interpolation over 32 beats, wrapping outside the viewport |
| Cane stalks | Eight-beat sway, staggered offsets per stalk |
| Cane warning / lunge | Eight-beat cycle; warning 4–6, lunge 6–7 |
| Road signals / traffic | Sixteen-beat cycle; two-beat approach warning and two-beat travel |
| Dialogue advancement / contextual interaction | Quarter-beat dispatch; accepted interaction uses existing movement GOOD tolerance |
| Obstacle contact sampling | Conductor sixteenth-beat subdivisions |
| Collision recovery | Next conductor beat plus one; safe obstacle restart offset |
| Dust | Two-beat expansion/dissipation using the existing nine rectangles |
| Quest notifications | Beat-relative deadlines |
| Story combat sprites / flashes | Existing pose/speed metadata and reaction durations sampled from conductor time |
| Screen changes / fight start | Next beat / next full phrase respectively |

Static objects are not forced to bounce. Vendor, cane, palm and cloud cycles deliberately differ. Pause freezes the existing conductor/audio and clears held/pending actions; no object catches up wall time. In-world transitions, recovery, replay and cinematic skip never restart musical phase. Explicitly leaving the Story session for a menu retains the existing session/menu transport behaviour.

The existing `RhythmConductor`, `CombatInput`, `RhythmMovement`, `Bout`, CPU controller, settings, source artwork and palm component were not changed. Story uses the existing Red actor throughout. Its automatic sprite playback/flash processing is suspended while Story’s conductor sampler presents the same supplied poses; normal Versus processing is restored on exit. World drawing and combat poses continue sampling during the fight, rather than silently returning to free-running animation.

## Systems and files

- `data/story/quests.json`: campaign objective, main quest, ordered steps, nested delivery and the single approved reward.
- `data/story/dialogue.json`: exact approved dialogue and clearly flagged neutral temporary dialogue.
- `scripts/story/quest/quest_log.gd`: locked/active/completed states, ordered event consumption, nested steps, notifications, restoration and independent optional-quest IDs.
- `story_inventory.gd`: one validated slot: empty, crate or stick.
- `story_wallet.gd`: money and an idempotent reward ledger.
- `scripts/story/story_dialogue.gd`: queued lines, completion signals and one fresh F press per advancement. A reserved branch hook is present; no branching story is authored.
- `scripts/story/beat_world.gd`: shared conductor phase interface.
- `scripts/story/story_obstacles.gd`: pure road/cane timing and collision predicates.
- `scripts/story/story_quest_screen.gd`: replaceable placeholder rendering for Screens 02–06.
- Existing screen manager/session/overlay/save: integration, screen ownership, interaction gates, HUD and checkpoint persistence.
- `scripts/main.gd` and `arcade_flow.gd`: narrow Story fight result, clock, pause/menu and presentation hooks. Existing deterministic combat/input code is untouched.
- `tests/test_story011.gd`, `tests/test_story011_data.py`, native demo scene/script and `tools/check.sh`: new verification and recording.

The main scene and root `project.godot` configuration remain unchanged. No nested project, paid generation, new music, scrolling world or external asset dependency was introduced.

## Quest model and progression

Campaign `rent_due`, **Rent Due!**: **“Earn enough money to pay the rent.”** No rent amount is defined or invented.

Main quest `a_stick_to_share`, **A Stick To Share Licks**:

| Objective | Explicit event / gate |
| --- | --- |
| Find a way to pay the rent | `opening_complete`: recovery or explicit skip |
| Head down the village road | `village_entered`: actual Screen 02 entry |
| Talk to the roadside vendor | `vendor_spoken`: complete the initiated seven-line conversation |
| Pick up the crate | `crate_picked`: valid nearby beat-timed F pickup |
| Deliver the crate to the next vendor | Parent objective; completes only after all three children below |
| ↳ Cross the road safely | `road_crossed`: actual final crossing step has finished beyond the road |
| ↳ Hand over the crate | `crate_delivered`: nearby F interaction transfers the carried crate |
| ↳ Collect your BDS $5 | `delivery_paid`: idempotent ledger grant, then parent completion |
| Find a good fighting stick | `cane_road_entered`: actual Screen 04 entry |
| Get through the cane | `cane_cleared`: reach Screen 06 after both defensive gates |
| Pick up a fighting stick | `stick_picked`: nearby on-beat F pickup, empty slot required |
| Win your first stick fight | `fight_won`: authoritative existing Bout winner is Red |

This preserves all twelve requested objectives while treating delivery as a parent, not a prematurely completed step before crossing. Events arriving out of order or twice have no effect. Optional quests can use separate quest IDs and globally unique step IDs without advancing the main quest; no optional content is populated yet.

The compact HUD shows current objective, BDS balance and inventory state/icon. An eight-beat opening notification displays the exact campaign objective only after recovery/control handoff. Notifications use conductor deadlines. Tab displays completed/current quest details and hides future spoilers. It opens only on safe verges in obstacle screens, so reading it cannot conceal an active hazard around the player. Movement inputs do not leak through dialogue or the quest panel. The Story HUD yields to the existing combat HUD during the encounter.

## Screen 01 polish and dialogue

The supplied house’s alpha leaves background showing through the foundation. A small masonry-coloured backing at the original ground line closes that gap **behind** the original house. The house texture, scale, door/slipper frames and world position are unchanged. Compare the earlier [Milestone 010 closed-house capture](../screenshots/milestone-010/010-closed.png) with the new opening capture.

The fighter is hidden before the kick. His first visible frame is the supplied horizontal airborne pose (eviction frame 2), emerging from the doorway; there is no crouched race-start pose. The same actor follows the existing conductor-defined flight/landing and recovery sequence, then becomes the existing unarmed idle at the same ground position/scale. Dust remains lightweight and conductor-driven.

Wife line 1 is shown from inside. The door opens and line 2 follows. If the player is still reading either wife line, only the cinematic waits at its pre-kick state; the conductor and palm continue. Once advanced, launch resumes on a conductor beat. The landing triggers the protagonist line. F manually advances each line on a quarter-beat boundary, and holding F cannot advance additional lines. Enter remains an explicit cinematic skip; it clears dialogue/cinematic events, settles the house and idle, and waits for a fresh beat before enabling traversal.

The approved wording is stored **verbatim**, including the vendor conversation and the protagonist’s deliberate exaggeration. The bitmap font displays uppercase glyphs without changing stored wording or punctuation. Panels wrap to a 278px content width at 320×180, with speaker, three text lines and F prompt; automated font-metric checks cover every authored line. No typewriter timer or independent dialogue clock exists. Native currency review found that the project font lacked `$` and rendered the question-mark fallback. The existing font-builder source now supplies one 5×7 dollar glyph; only its atlas cell changed, with all other glyph pixels and metrics preserved. All second-vendor/opponent/end dialogue is marked `placeholder: true` and shown with `[TEMP]`; it uses plain English and invents no Bajan colloquialisms.

Existing idle, stance and recovery assets were inspected. The four-frame idle sheet is **armed**; recovery frames are authored brushing/get-up gestures rather than a breathing loop. No suitable genuine unarmed idle cycle was found. The approved unarmed `character_master` pose remains static, instead of looping crouches or inventing frames. This is a missing-art finding for owner review, not an animation silently claimed complete.

## Screen route, inventory and rewards

| Screen | Implemented content |
| --- | --- |
| 01 — Out Yuh House! | Polished opening, existing house/sky/palm, objective and unchanged traversal |
| 02 — Village Road | Approved `background_01.png` / Village Street, placeholder vendor/stall, mandatory exact conversation and crate |
| 03 — The Crossing | Placeholder road, conductor traffic/signals, safe verges, second vendor and delivery |
| 04 — Cane Road | Placeholder rural road/cane/palm, warning and one successful S defence required |
| 05 — Rustling Rows | Staggered cane, silhouette lunges; two successful defences before exit |
| 06 — Stick Clearing | Placeholder clearing/stick icon, existing armed fighter/Blue opponent and existing CPU fight |

A/D uses exactly the approved shared input/step implementation. Holding a direction never repeats. Facing remains right during Story traversal; left is the existing backward-step semantic. S uses the existing race crouch and existing low-input state, without a new defensive timing/input system or a movement lock. F is contextual and beat-timed; an off-beat attempt reports a miss rather than causing an unintended pickup. Screen exits wait for the visual step to finish, validate their quest gate, then change once on the next conductor beat. Entry positions are fixed, grounded and input-clean; textures/nodes are ready before control resumes.

Crate pickup requires vendor completion, proximity, an empty slot and valid F timing. The crate appears in the slot and as a small carrying marker; character artwork is not stretched or replaced. Screen 02 cannot be left without it. Handover requires the crossing child objective and the crate, then removes the item and grants **BDS $5 once** through reward ID `crate_delivery`. Both the quest’s reward data and wallet ledger are persistent. Re-entry/Continue cannot re-award it. No shop, rent payment, other economy or fight reward exists.

The stick occupies the same quest slot and is the prerequisite for entering the existing armed combat context. There is no second damage/reach/equipment system: the existing Bout remains the combat authority. A defeated player retains the stick, money and quest progress and can retry the same introductory encounter.

## Road and cane fairness

The road spans **X=112…208**. From safe checkpoint **X=100**, the existing 16px steps reach **116,132,148,164,180,196,212**: **seven taps**, with the final 160ms presentation completed before crossing is awarded.

The sixteen-beat traffic cycle is:

- **0–5:** **CROSS NOW** for new entrants. All seven steps, including presentation, fit safely before traffic.
- **5–12:** no traffic; wait on the verge, or **KEEP GOING** if already crossing.
- **12–14:** approaching-vehicle warning.
- **14–16:** vehicle travels continuously along the vertical road, sampled from conductor phase; **WAIT**.

The van uses an inner body/hurt-region overlap in the crossing zone. Contact is evaluated on conductor sixteenth-beat subdivisions, not an independent physics timer. Vehicle position and the warning/safety state share the same obstacle origin. A collision shows the supplied hurt reaction, returns the fighter to X=100 at a beat-defined recovery boundary, retains the crate/money and starts a fresh safe obstacle cycle. No health penalty or economic charge is introduced. The native recording deliberately demonstrates this failure and recovery.

Cane screens warn for two beats before each one-beat high lunge. Holding S uses the existing duck input/pose; movement remains independent. The placeholder lunge is drawn above the ducked silhouette. Standing in the danger zone without defending triggers the same safe, non-punitive recovery. Screen 04 requires one successful defence and Screen 05 requires two; the clearing event cannot occur by simply bypassing the warnings. A reset clears the previous obstacle-cycle guard so the first new defence is not accidentally suppressed.

These are intentionally simple placeholders for owner pacing review, not new enemy combat rules.

## Existing combat integration

After stick pickup and the temporary opponent explanation, the encounter starts on the next full musical phrase. It configures the existing CPU at **Easy**, positions the existing actors within the original reach, clears pending controls and enters the existing `mode="combat"` orchestration. There is no conductor start, music restart, stick race or free hit at this boundary.

Keyboard and CPU actions still go through `submit_action`; damage, block/parry, range, initiative, stun and three-hit victory remain in the existing Bout/Main rules. The CPU receives only `public_cpu_observation()` and resolved history, preserving commitment, delay, timing jitter, mistakes and its separate RNG. Story adds only a guarded resolved-winner hook before Arcade match progression: Red wins complete the quest, Blue wins offer a retry. Neither result changes the wallet. The normal Arcade/PvP/PvCPU result/round flow remains unchanged.

Combat sprites are sampled from the existing pose/frame/speed metadata against conductor time. The Story sampler never resolves combat or awards a hit. Existing impact/SFX mapping and their approved durations remain unchanged and read conductor time. Armed idle cycles sample musical phase; missing unarmed breathing art is not fabricated.

## Persistence and compatibility

The save remains at **`user://story-009.json`**, with **version 2**. Writes use the existing temporary-file/rename pattern. Fields are: version, campaign, unlocked screen, checkpoint, opening complete, screen, completed step IDs, item, money and reward IDs.

Version-one Screen 01 saves migrate in memory to a safe opening-completed Screen 01 checkpoint, BDS $0 and empty inventory. No quest job/reward is invented. Version-two restoration reconstructs the ordered objective prefix and validates screen gates, inventory consistency, the payment step and reward ledger. Missing, malformed or incompatible data disables Continue safely. Continue starts at a safe screen checkpoint rather than mid-obstacle, restores the carried item/money/quest, and waits for a conductor beat. Armed Continue stays armed. A completed quest opens its completion menu; it does not start another fight or duplicate payment. Defence progress within an unfinished cane screen is intentionally checkpoint-local and may need repeating after Continue.

New Game retains the existing overwrite confirmation. Development F6/F7/F8 remain behind F3/debug controls; F6 starts the opening/new quest, F7 restores a checkpoint and F8 skips the cinematic. Test scenes use empty/test-local preferences and save paths and never write the owner’s actual preferences or save.

## Verification and recording

The full `bash tools/check.sh` suite passed with exit **0**:

| Suite | Actual result |
| --- | ---: |
| Rules / controls | 51 / 46 checks, no failures |
| Media / launch-range | 3348 / 1020 checks, no failures |
| Idle/movement / HUD / production-clock movement | 676 / 189 / 168 checks, no failures |
| CPU | **1,795,853 checks; 900 measured matches; zero failures** |
| Milestone 006 / tutorial / gameplay props / 007 | 292 / 201 / 166 / 61 checks, no failures |
| UI polish / 008 | 200 / 292 checks, no failures |
| Story 009 / palm 010 | **168 / 353 checks**, no failures |
| Story quest 011 | **176 checks**, no failures |
| Python | **36 tests**, all passed |

The original Story fixtures now manually dismiss the required dialogue and assert the new next-screen transition/version-two save contract instead of the superseded Screen 01 demo-end menu. Their movement differential, timing, input-clear, pause, actor identity/scale and teardown assertions remain intact. No checks were deleted to obtain a pass. The palm implementation is unchanged. Python count increased from 33 to 36 because of two approved-dialogue/quest-data checks and a missing-currency-glyph regression.

New coverage includes ordered/nested/optional quests, duplicate events/rewards, inventory transfer, all seven crossing steps for every green starting beat, warnings/contact/recovery, retained crate/money, six-screen transitions, manual held-F behaviour, native font-metric bounds, cane defences, existing combat handoff/three-hit victory, no fight cash, save round trips, invalid-bundle rejection, version-one migration, armed/completed Continue and shared world pause/phase.

The genuine native Godot run completed the entire route using the **production monotonic conductor clock** (about 95 seconds). A separate continuous, uncut native recording with game audio is **`output/milestone-011-story-vertical-slice.avi`**: **5,599 frames at 60 FPS, 93.317 seconds, 320×180**, with 48kHz stereo 16-bit PCM (**17,916,800 bytes; zero clipped samples**). The extracted final track played through the local device with exit 0; this establishes playback, not a subjective listening judgement. It includes the full opening, every approved dialogue line, vendor/crate, an intentional traffic collision and safe recovery, BDS $5 delivery, both cane challenges, stick pickup, the real CPU encounter and quest completion. The recording uses an **explicit test-only offline clock** for deterministic MovieMaker output and legal scripted inputs; it is not an assembled animation, physical keyboard playtest or subjective listening assessment. Combat demo decisions use public observations through the existing test strategy, never CPU current selections.

Native screenshots, normal window scaling and decoded AVI frames were inspected. Review corrected the foundation gap, airborne-only entrance, text/beat-footer overlap, vehicle road direction, conservative crossing-start signal, duck/lunge clearance and combat/quest HUD overlap. The final presentation keeps the house, scenery and fighter scale stable. Selected screenshots and run/audio hashes are linked in [`milestone-011-evidence.json`](milestone-011-evidence.json); screenshots are under [`docs/screenshots/milestone-011/`](../screenshots/milestone-011/). Movies, audio, reports and full logs remain ignored in `output/`.

Reproduce the test recording:

```sh
bash tools/check.sh
/Applications/Godot.app/Contents/MacOS/Godot --path . \
  --log-file output/011-native.log --fixed-fps 60 \
  --write-movie output/milestone-011-story-vertical-slice.avi \
  --scene scenes/tests/story011_demo.tscn -- --record011 --desktop011
```

Omit `--record011`/MovieMaker to run the native demo with production time. The demo is test-only, does not assign fighter positions/damage/quest completion, and does not replace production controls.

## Placeholder inventory and limitations

Replaceable Godot drawings: both vendors/stalls, crate and carrying/slot icon, road/van/signals, rural/cane/clearing environments, clouds, cane/lunge silhouette, stick marker and foundation backing. Screen 02 uses the approved Village Street background; palms, house, fighter eviction/run/duck/idle/hurt and both armed fighters are existing original resources. No new final art was generated.

The one-pose unarmed idle remains a missing-animation asset. NPC/vehicle/cane art, road perspective, collision reaction and overall pacing are deliberately provisional. Optional quest support is implemented but no side quest is authored; dialogue branching is only a future hook. Source/effect commercial licensing remains as documented in Milestone 008. Existing Godot certificate/editor-settings/ObjectDB teardown diagnostics remain in logs; passing runs contain no script parse/assertion failures. Physical key focus/rollover, subjective feel/balance and perceptual audio sync require the owner’s hands-on review.

## Manual owner playtest checklist

1. Launch normally → Story Mode → New Game. Read all wife/protagonist lines at your own pace; hold F to confirm it cannot skip multiple lines. Confirm no fighter appears before the airborne kick, the house is grounded, and the exact rent objective appears after recovery.
2. Tap A/D early, on time and late. Hold a direction, reverse it and duck. Compare responsiveness/facing with Versus; no repeated held steps or changed displacement should occur.
3. Reach the first vendor, complete the exact seven-line conversation, then press F on/off the beat near the crate. Check the one-slot icon/carry marker and that the exit is gated until pickup.
4. At the road, wait for CROSS NOW and cross in seven taps. Try a late start, stop on a verge, then deliberately let the van hit you. Confirm warning readability, safe recovery and retained crate/BDS balance.
5. Deliver to the second vendor. Confirm the crate disappears, BDS $5 is added once and the next objective points towards the cane. Return to the menu/Continue and verify no duplicate payment or missing progress.
6. Read each cane warning and hold S through the lunge. Try one failed defence and recover. Confirm one successful defence gates Screen 04 and two gate Screen 05, without changing normal walking.
7. Collect the stick with F, read the temporary opponent explanation and play the existing three-hit fight. Check combat controls, scale, readable HUD, parry/stun behaviour, retry after loss and quest completion after victory. Money must remain BDS $5.
8. Pause/resume during dialogue, traffic and the fight. Continue from crate, paid and armed checkpoints. Watch palms, vendors, clouds, cane and warnings for a common beat with different personalities; no screen transition should restart the music.
9. Open Tab details from safe verges and check completed/current steps, readability and spoiler hiding. Judge walking/discovery/dialogue/hazard/fight pacing as one playable route before approving new artwork or further expansion.
