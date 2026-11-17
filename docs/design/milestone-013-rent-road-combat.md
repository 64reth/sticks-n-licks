# Milestone 013 — Rent economy, road scale and full combat integration

Baseline: `971dd4e`, branch `development`, Godot 4.6.2. Original artwork/audio and unrelated untracked files are preserved. Milestone 011 remains subject to owner acceptance; this revision is a new review candidate, not a claim of physical playtesting.

## Requirement audit

PASS below means implemented, regression-tested and inspected in native rendered evidence. Owner feel/balance approval is separate. Final recording metrics and capture hashes are in [the evidence manifest](milestone-013-evidence.json).

| Requirement | Root cause | Implementation / files | Test and native evidence | Status |
| --- | --- | --- | --- | --- |
| Measurable rent | Wallet allowed only 0/5, no target | `campaign_013.json`, `StoryWallet`, exploration HUD target/bar | Data/rebalance/persistence checks; exploration and paid captures | PASS |
| Completed-match reward once | First fight ended at three hits, no configured cash reward | Encounter reward ledger, deciding-match callback only, historical claimed amounts | Premature/duplicate/defeat/Continue checks; native BDS25 reward capture | PASS |
| Campaign remains active | Quest completion opened an end menu | First quest completes independently; exploration resumes with future-work objective, target reached requests return home without payment | Full victory and target threshold checks; native post-match HUD | PASS |
| Broad four-lane crossing | Two 48px road strips and 16×26 cars beside 64px fighter | Two connected fixed 320×180 sections, 184px carriageways, 88px lanes, 64×110 car bodies | All four lane captures; fighter beside car; scale/config and crossing checks | PASS |
| Shared traffic clock and safe recovery | One compact-screen layout; no section context | Four independent BeatWorld cycles; safe verge/refuge transitions, per-road/lane warnings, checkpoint retention | Combined-cycle feasibility, collision and legacy-save tests; native collision/refuge | PASS |
| Complete Versus match | Story constructed its own Bout and intercepted first round winner | `main.gd` existing `_begin_round`, race, pickup, Bout, MatchProgress, automatic round transition and guarded deciding result; Story supplies context/data only | Actual two-round fixtures, native defeat/retry and best-of-three win | PASS |
| Full combat HUD and return | Exploration overlay hidden but normal match progression bypassed | Same ArcadeHUD/HUDPresenter, three energy segments, markers, initiative, countdown/GO; existing result screen with Continue/Retry | Native combat, round 2 and result captures; HUD activation/restoration checks | PASS |
| Speech-only dialogue | Provisional text mixed controls, exchange count, progress guarantees and completion announcements into speech | Typed speech filter, audited resource cleanup; objectives, controls, rewards and completion use their own channels | All fourteen spoken entries and pages captured; source/render audit | PASS |
| Conductor continuity | Existing Versus resets clock each round/pickup; non-combat match phases did not advance it | Story context preserves epoch through shared round lifecycle and advances results/pickup; non-combat match easing sampled from musical phase | Epoch/result progression/pause regressions; native capture epochs | PASS |
| Existing music and presentation | Need full result presentation without restarting Story clock | Original AudioDirector result theme/poses; exploration music resumes from preserved anchor/phase; no new music | Original defeat/victory events in recording; numeric audio and native inspection | PASS |
| Full regression | Earlier fixtures assumed tiny roads and one-round Story completion | Existing tests retained with new superseding layout/match expectations; new 013 and Python checks | `bash tools/check.sh`, including 900 CPU matches | PASS |
| Human feel and final balancing | Cannot be established by scripted input | Manual review instructions below; economy explicitly provisional | No physical keyboard/controller or subjective listening claim | PARTIAL |
| Future jobs and home payment | Outside the six-screen scope | Explicit upcoming objective; no artificial game-over, paid flag or additional earning rule | Threshold check keeps campaign playable and unpaid | PARTIAL (future content, explicitly scoped) |

## Economy and saves

`data/story/campaign_013.json` is the single configuration source:

| Setting | Provisional value |
| --- | --- |
| Rent target | BDS $100 |
| First crate delivery | BDS $5 |
| Encounter `first_stick_fight` | BDS $20, reward ID `fight_first` |
| Match format / CPU | Best of 3 / existing easy CPU |

The owner has not approved final balance. A job plus the complete match yields **BDS $25 / $100**. A compact progress bar and numeric rent progress are separate from the actionable current quest step and inventory. The first quest can finish while the campaign remains active. Below the quota, the current end-of-slice objective identifies more paid work/fights as upcoming. At or above the quota it becomes “Return home and pay the rent. (Upcoming)”. Reaching the quota never marks rent paid or opens a game-over. No new story content, opponents or earning restrictions were added. The present slice contains one BDS5 job and one BDS20 encounter; it cannot yet earn BDS100. Additional configured encounters/jobs and the actual home-payment sequence remain future content.

Money, claimed reward IDs, historical `reward_amounts`, and `rent_target` persist in the existing v2 save path. Historical amounts prevent future reward balancing from rewriting already earned money. Save validation checks unique known rewards, nonnegative integral amounts, matching cash total and quest/item consistency. Existing v1 and v2 saves remain readable. The current campaign data determines the active quota on load; changing the target does not erase cash. Existing completed one-round 011/012 saves receive no retrospective full-match reward. New victories are awarded by the deciding-match handler, persisted before the result is dismissed, and cannot repay through duplicate callbacks, reloads or retries. Defeat retains the established armed clearing checkpoint without reward.

Reward amounts appear in a dedicated bordered reward notification. They are not injected into character speech. Quest completion also uses the notification/HUD channel.

## Road composition and measurements

The fighter is unchanged: approximately 64 logical pixels tall, native source calibration, baseline Y150, 16px steps over 160ms, fresh taps only. The crossing now spans **two connected fixed-camera sections** (320px each), rather than fitting all four lanes into one small screen.

Each carriageway occupies X72–256 (184px). The two lane centers are X116 and X212, configured lane width 88px. Cars have 64×110px bodies plus 6px wheels, making their length 1.72 fighter heights and their body width one fighter height. They are recognisable code-drawn provisional cars, not commissioned or substituted artwork. Each carriageway is 2.875 fighter heights wide. Both carriageways total 368px of road across the two 640px camera sections.

Safe approach/refuge/exit anchors are X36 and X292 within each section. Crossing takes **sixteen unchanged steps per section** (256px), thirty-two total. At the first section's far verge, the next fixed section opens at the central reservation's left verge. Matching reservation materials, the carriageway 1/2 label and persistent conductor make the cut explicit and coherent. No scrolling camera, fighter shrinking or conductor reset is used. Releasing/repressing direction retains the approved movement semantics. The second far verge completes the crossing and enables delivery; the first does not.

Road A's two lanes travel down; Road B's two lanes travel up. Their independent cycles are 64/80/96/112 beats, each with four warning beats and eight travel beats. Cars interpolate their full entry/exit path from BeatWorld phase. Collision uses their visible body dimensions and the fighter's existing 64px height/9px hurtbox half-width. Cars intentionally enter and leave through viewport edges. Road labels and lane warnings render above passing roofs. No traffic nodes, particle pools or free-running timers are created.

The combined pattern repeats over 6,720 beats. Exhaustive start checks found **2,394** safe starts for section A and **3,500** for B. All advertised CROSS windows permit all sixteen 16px steps, including 160ms interpolation, without collision. The conservative reservation produces a worst wait of **45 beats / 22.5 seconds at 120 BPM**. That is a documented pacing limitation for owner review. A lane's GO describes that lane now; CROSS reserves the entire carriageway traversal. Players may observe traffic safely before attempting it.

Collision samples the same phase as rendering, triggers the existing-art unarmed reaction, and returns to the reached safe verge. Crate, cash and quest progress are retained. Traffic phase is never reset by a collision or camera-section handoff. The reservation's `road_section` persists. Legacy X148 checkpoints migrate to the second section's safe verge; former compact-road saves never spawn inside a new lane. Existing cane timing and palm implementation remain unchanged.

## Full combat integration

Story no longer constructs a special three-hit match. `StorySession.start_fight()` delegates encounter setup to `main.start_story_match()`, then the existing `_begin_round`, race/GO/pickup, `submit_action`, CPU planner, Bout resolution, energy computation, MatchProgress, automatic next round and deciding result execute unchanged shared rules. The first round win displays its result for the existing configured delay, preserves round markers and automatically starts the next countdown. Two round wins are required. The same ArcadeHUD supplies three-segment energy bars, initiative indicators, round-win markers and rhythm feedback.

The existing guarded deciding-result handler plays the original victory/defeat poses, original result music and result screen exactly once. Story then receives the match winner. Continue restores exploration after victory; Retry after defeat restores the checkpoint and spoken retry line, then schedules the existing match again. The exploration objective, slot and interaction prompts are absent during combat. No competing match controller or second health system was introduced. CPU receives only the existing public observation and past resolved events; its implementation, jitter, decision delay and fairness configuration are untouched.

Story adds context-specific continuity at the existing reset boundaries: it retains the conductor epoch rather than calling `start()` at round/pickup changes. The conductor continues advancing during pickup, finishing, round results and match results. Countdown cues are computed from its current phrase. Combat's approved movement/input implementation and windows are unchanged. Non-combat race/pickup presentation uses a deterministic phase-sampled easing curve instead of render-delta accumulation; logical positions/race rules remain shared. Story fighter poses remain conductor-sampled through the existing actor. Original result themes deliberately replace the backing track during the result presentation, then exploration playback seeks to the preserved backing-track anchor/phase; the conductor itself never restarts.

## Exhaustive dialogue audit

[The audit](../assets/milestone-013-dialogue-audit.json) lists every speaker, exact text, classification and native capture. There are **14 genuine spoken lines**: opening 3, vendor 7, delivery 2, fight intro 1, fight lost 1. Screens 4 and 5 contain warning/quest/control UI but no speech. The old quest-complete speech branch is empty: completion is a quest notification. The speaker label “WIFE (FROM INSIDE)” is now just “WIFE”; door staging remains cinematic state.

Every approved Bajan **text string** in opening/vendor is preserved exactly, checked against the baseline hash. No additional dialect was invented. Only existing provisional English entries were trimmed: control/exchange instructions, save guarantees, reward amount/navigation instructions and the completion announcement. Remaining provisional English entries are actual character speech. All resource entries are explicitly `type: speech`; `StoryDialogue.begin()` rejects other presentation types. Production dialogue calls are confined to StorySession and this entry point; no other script writes stage directions or objectives into the dialogue queue.

The 304×32 bottom panel, measured wrapping, two-line pagination, 32-characters-per-beat typewriter, fresh F reveal/advance and held-input protection remain. Native inspection covers every line and every full page, including the long vendor entry and the defeat/retry branch. Source checks alone are not treated as rendered proof.

## Verification and evidence

The continuous native route uses legal scripted keyboard/action inputs, including an intentional first-match defeat, retry, then victory. It does not override money, positions, damage, CPU decisions or quest progress. Only explicit `--record013` injects a test clock for offline recording; normal F5 uses the production clock. This is scripted interactive verification, not physical keyboard/controller testing.

- Recording: [output/milestone-013-rent-road-combat.avi](../../output/milestone-013-rent-road-combat.avi).
- Selected native screenshots: [milestone-013](../screenshots/milestone-013/).
- Raw native captures, all pages and logs: `output/013-*.png`, `output/013-demo-movie.json`, `output/native013-proof.stdout`.
- Full test log: `output/check013-final.stdout`.
- Machine-readable frame/audio/hash/test results: [milestone-013-evidence.json](milestone-013-evidence.json).

Reproduce with:

```sh
bash tools/check.sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --log-file output/native013-delivery.log --fixed-fps 60 --write-movie output/milestone-013-rent-road-combat.avi --scene scenes/tests/story013_demo.tscn -- --record013
```

Run the demo scene without `--record013` for a production-clock scripted route. All demo preferences/save paths are test-local or empty. The root F5 scene remains `res://scenes/main/main.tscn`. Recordings and generated builds stay ignored; only selected screenshots and evidence documentation are versioned.

The complete existing suite includes 900 measured CPU matches, all earlier Story/palm/quest checks and Python asset checks. Existing tests were not removed: outdated one-round, tiny-road and completed-campaign expectations were replaced with the new mandatory best-of-three, two-section and active-campaign contracts. The 012 legacy traffic fixture still verifies its original pattern separately; production uses `traffic_013.json`. New 013 checks cover configurable and historical economy, reward guards, win/defeat/retry, HUD handoff, original result events, conductor continuity through results, source classification, all crossing windows, scale and save integrity. Python adds exhaustive dialogue/resource parity, approved text preservation and campaign reward-ID checks. Per-suite counts and final exit status are recorded in the evidence manifest.

## Manual owner review

1. F5 → Story Mode → New Game. Confirm zero cash and BDS100 target. Use F to reveal then advance; inspect every speaker/line, especially the two-page vendor dialogue.
2. Press F away from beat 4 at the first vendor, then freshly on beat 4. Pick up the crate and inspect its separate slot.
3. At the road, stand beside a passing car and judge the stated scale. Watch both same-direction lanes, read WAIT/CROSS, then cross with sixteen fresh D taps. Inspect the central reservation and opposite-direction second section. Deliberately collide; confirm crate/progress/cash and safe recovery, including Save/Continue.
4. Deliver: BDS5 and an empty slot. Continue through cane using existing S, collect the stick and enter the match.
5. Check the full HUD, countdown, GO, initiative and three-segment energy. Win only one round: no BDS20 yet. Wait for automatic progression. Finish two round wins, acknowledge the original victory screen and confirm BDS25/100 plus exploration HUD.
6. Lose a full match and retry. Verify no win cash on defeat and no duplicate cash after reloading a claimed win.
7. Pause/resume in traversal, traffic, countdown, rounds and results. Judge physical input feel and subjective music/effect alignment. Review 22.5-second worst road waits and provisional English/car presentation.
8. Current content stops adding objectives after the first quest, while exploration and the rent objective remain active. Additional work and actual home payment are explicitly upcoming, not a rent-paid or game-over state.

## Final measured delivery

The final uncut AVI is **296.95 seconds (4m56.95s), 17,817 frames at 60fps**, 320×180. Its frame count exactly matches the injected-clock trace, and every capture retains the single epoch `1.91666666666666`. SHA-256: `403a2bb954fc502ec746f298944eb3f56b581db4d9e31bda09ecc73ffeb05f30`. The isolated proof recording was renamed to the requested delivery filename without editing or recompression.

Audio is stereo 48kHz 16-bit PCM: peak 0.82184, RMS 0.11090, zero clipped samples. The extracted WAV was sent to system playback. These measurements and playback do not establish subjective listening or perceptual synchronisation. Original defeat and victory result events each occurred once. Actual AVI frames were sampled across the full route, and all sixteen complete dialogue pages were visually inspected. The capture harness holds each revealed page through `frame_post_draw` before permitting an advancing F, so screenshot labels match actual rendered text.

The full suite exited 0: rules 51; controls 46; media 3,348; launch/range 1,034; idle/movement 676; HUD 189; live movement 168; CPU 1,795,853 checks / 900 matches; milestone 006 292; tutorial 201; props 166; milestone 007 61; UI polish 200; milestone 008 292; Story 009 168; palm 010 353; Story 011 168; Story 012 174; Story 013 148; Python 41. A final boundary-message correction then added one 013 assertion: all Story/palm fixtures passed again, including **149** 013 checks. The completed clearing now explicitly identifies upcoming locations rather than incorrectly asking the player to finish an already completed objective. Reduced dynamic 011/012 counts reflect shorter provisional dialogue and superseded match/layout fixtures; existing assertions were retained or replaced by the stronger mandatory contracts, not disabled. Existing macOS certificate diagnostics and ObjectDB exit warnings remain; no final script errors were observed.

[Initial rent HUD](../screenshots/milestone-013/screen1.png) · [BDS5 after delivery](../screenshots/milestone-013/screen4.png) · [Fighter beside car](../screenshots/milestone-013/lane1-vehicle.png) · [Road section 1](../screenshots/milestone-013/road-section0.png) · [Road section 2](../screenshots/milestone-013/road-section1.png) · [All four lanes](../screenshots/milestone-013/lane3-vehicle.png) · [Collision recovery](../screenshots/milestone-013/traffic-recovery.png) · [Full combat HUD / round 2 marker](../screenshots/milestone-013/combat-hud-match2-round2.png) · [Victory](../screenshots/milestone-013/match-0.png) · [Defeat](../screenshots/milestone-013/match-1.png) · [Reward and restored exploration](../screenshots/milestone-013/reward-exploration.png) · [Long dialogue page](../screenshots/milestone-013/dialogue-vendor-1-page0-full.png).

Additional actual AVI frames at 273–275.42 seconds show the second-round countdown and [GO](../screenshots/milestone-013/countdown-go.png); 290 seconds shows the deciding 2–0 result, and 293/296 seconds show restored exploration and the BDS20 reward.

Changed implementation files: `data/story/{campaign_013,traffic_013,dialogue}.json`; `scripts/main.gd`; `scripts/story/{story_session,story_save,story_obstacles,story_quest_screen,story_overlay,story_dialogue}.gd`; `scripts/story/quest/story_wallet.gd`; `scripts/ui/arcade_flow.gd`. Verification adds `tests/test_story013.gd`, `tests/test_story013_data.py`, `tests/story013_demo.gd`, `scenes/tests/story013_demo.tscn`, updates the 011/012 fixtures and `tools/check.sh`, and supplies the dialogue audit, evidence manifest and selected screenshots. No source artwork/audio, conductor, CombatInput, RhythmMovement, Bout, MatchProgress, CPU planner, palm component or combat settings changed.
