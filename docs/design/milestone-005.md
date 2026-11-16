# Milestone 005 — Player vs CPU

Implemented against Milestone 004 (`93ab389f6d0aba311e18e3ecc8d84718be221fbc`).
The root Godot project/main scene remains unchanged. Original sprites, soundtrack,
movement windows, hit geometry, initiative, three-hit rounds and best-of-three
matches remain in their existing systems.

## Playing and reproducing an opponent

The main menu defaults to **Player vs CPU / Normal**. **M** toggles modes; **P**
selects PvP immediately. **Left/Right** cycles Easy, Normal and Hard in the CPU
menu. **Enter** starts. Player 1 controls Red; Blue is CPU in single-player.
Blue keyboard bindings are ignored during CPU matches, and work normally in PvP.
Enter advances a completed round or rematches. Escape returns to the menu.
H, F3 diagnostics and F4 stage switching remain available. The blue card displays
CPU difficulty without adding an intrusive combat panel.

Open the root `project.godot` and press F5, or run:

```sh
cd /Users/garethwallen/Projects/sticks-n-licks
/Applications/Godot.app/Contents/MacOS/Godot --path . -- --cpu-seed=7000 --cpu-difficulty=hard
```

Default difficulty/seed and tuning live in `data/cpu.json`. The default seed is
5005. Rematch restarts that seed and clears match learning. Next round retains
learned tendencies and the RNG stream, but clears pending inputs and phrase/race
commitments. A seed reproduces relative decisions and timing for an identical
public state and player-input timeline; it never fixes a match outcome.

## Architecture and fairness

`CpuController` is a rendering-independent RefCounted planner with its own seeded
RandomNumberGenerator. It receives copied public positions, initiative, energy,
conductor beat/phrase/time/duration, input latency calibration and effective stick
reach. It receives past attacks only after the normal exchange has resolved.
It never receives the scene, Bout, current selections/errors, held keys, buffered
execute timestamps or unrevealed player actions. No controller code changes
positions, energy, initiative, animation or collision shapes.

The keyboard adapter and CPU both call `main.submit_action()`, which uses the
existing CombatInput, movement timing and Bout resolution. The CPU submits
press/release attempts, including direction plus execute for combat. A MID chord
can independently request a forward step under the existing 004 rule; one-step-
per-beat validation still applies. No damage or range shortcuts were introduced.

`advance_timeline()` merges previously committed CPU inputs with conductor
boundaries in timestamp order. On slow render frames it processes those already
scheduled actions at their musical timestamps, rather than creating extra actions
or granting a late reactive choice. Rendering delta never drives production CPU
musical time. Visual interpolation and animation remain the existing systems.
Human input uses the current shared game clock and the same validator.

At phrase beat one the CPU commits an attack/block height and attempt decision
for beat four. It cannot change that height during the phrase, even if new
information arrives. Minimum decision delays are configured, and movement
scheduling respects that delay: an early offset that would precede the decision
budget becomes a late offset of the same magnitude. Combat commitment always
precedes the action by substantially more than that budget. There is no current-
attack reaction or perfect prediction mechanism.

Attack weights vary by difficulty; after two identical attacks the next choice
must use another height. Defence weights blend a uniform guess with counts of
resolved opponent heights from this match. Frequent high attacks can therefore
become more predictable, but mixed heights remain useful. This is a small tally,
not machine learning. A public observation regression verifies that changing
hidden current input does not change the observation; a commitment regression
verifies new information cannot revise an already chosen defence.

## Behaviour and difficulty

The utility states are STANDOFF, APPROACH, ENGAGE, DEFEND, RETREAT and RECOVER.
The CPU plans movement one beat ahead. Out of reach it approaches, with occasional
hesitation/mistiming. Attacks from far away are uncommon; most commitments there
prioritise approach. In range it attacks or defends according to initiative and
sometimes retreats. It never deliberately retreats on consecutive decisions;
when the retreat creates distance it approaches again. Recovery includes skipped
decisions. Every attempt still needs legal timing and range.

| Parameter | Easy | Normal | Hard |
|---|---:|---:|---:|
| Target valid timing probability | 60% | 80% | 94% |
| Perfect share of valid timing | 8% | 28% | 48% |
| Minimum decision delay | 350 ms | 220 ms | 140 ms |
| Typical race reaction | 280–650 ms | 180–420 ms | 120–280 ms |
| False-start probability | 8% | 3.5% | 1.5% |
| Movement hesitation | 24% | 12% | 4.5% |
| Defensive attempt probability | 52% | 82% | 95% |
| In-range retreat chance | 5% | 12% | 16% |
| History weight strength | 0.12 | 0.45 | 0.72 |
| Base high/mid/low attack weights | .60/.25/.15 | .36/.34/.30 | .34/.33/.33 |

Valid perfect offsets vary between ±18–58 ms. Good movement offsets vary between
±105–145 ms; good combat offsets ±82–126 ms. Mistakes vary between ±172–184 ms,
outside the existing valid windows while staying within half the shortest beat
(187.5 ms at 160 BPM). Both early and late attempts occur. The rhythm-success
parameter is capped below 100%; mistakes are always possible. Race attempts use
the normal false-start/reaction comparison, with occasional extra reaction delay.
A race result grants initiative and never scores a hit.

## Executed measurements

`tests/test_cpu.gd` measured **900 complete matches**: 100 seeds (7000–7099) for
each of three difficulties against each of three defined Red strategies. These
are automated strategies, not representative samples of human skill:

- **rush_high:** high attacks, low blocks, good timing when valid.
- **balanced:** cycling attack/block heights and occasional spacing retreats.
- **guard_high:** high attacks and blocks, with perfect-capable timing.

All approach rhythmically, use 88% valid combat timing and a 230 ms race reaction.
The test player never reads CPU commitments, current inputs or chosen height.
Test-only clocks accelerate simulation; production CPU decisions and rules are
used unchanged. Visual victory timers are accelerated only in the test harness.

| Difficulty | Valid movement timing | Valid combat timing | High/Mid/Low attacks | CPU blocks | CPU parries | Mean match |
|---|---:|---:|---|---:|---:|---:|
| Easy | 56.6% | 60.7% | 53.7 / 27.4 / 18.9% | 9.6% | 1.0% | 47.3 s |
| Normal | 80.9% | 81.6% | 36.6 / 34.4 / 29.1% | 22.4% | 8.6% | 55.5 s |
| Hard | 93.7% | 94.4% | 33.8 / 33.1 / 33.1% | 22.7% | 21.0% | 60.4 s |

Timing rates use actual shared-validator results for attempted actions, excluding
race/hesitation/skipped actions. They are not hit rates or win probabilities.
Movement validity includes accepted early taps; collision blocking can still
prevent displacement. Easy movement fell 3.4 percentage points below its initial
60% target in this sample; tuning is not claimed exact. A separate 6,000-draw
movement and combat calibration per difficulty verified the configured timing
probabilities within 2.5 percentage points.

Block/parry frequencies use in-range successful player attacks against CPU as
the denominator (HIT/BLOCK/PARRY outcomes). Height percentages count attempted
CPU attacks. Match durations use the simulated musical clock plus 0.9 seconds
per round for the normal victory presentation, excluding human Enter/menu waits.

| CPU wins / 100 matches | rush_high | balanced | guard_high | Total / 300 |
|---|---:|---:|---:|---:|
| Easy | 9 | 7 | 0 | 16 |
| Normal | 44 | 27 | 15 | 86 |
| Hard | 85 | 58 | 65 | 208 |

The other completed matches were Red wins. No result was forced or handicapped.
There were **zero 360-second timeouts** and **zero 60-second no-hit stalls** in
900 measured matches. This is sampled evidence, not a proof against every seed.
Detailed counts, denominators and maximum durations are in
[milestone-005-results.json](milestone-005-results.json).

## Tests and graphical evidence

`bash tools/check.sh` exited zero. It passed the existing 5,146 focused Godot
checks, 168 real-clock PvP movement checks, 22 Python tests, the PvP match/rematch
demo, the CPU matrix (1,794,836 checks, mostly per-frame arena/separation
assertions), and the full CPU match demo. Explicit additional scenarios exercised
CPU attempts at 140 and 160 BPM; normal matches start at 120. A fixed-seed replay
at 30 and 120 Hz reproduced identical relative input choices/timing and the same
winner. Absolute clock epochs/UI wait lengths are intentionally not compared.
Rematch, mode/difficulty selection, public-information isolation, commitment
locking, attack-height variety, real blocks/parries and both sides winning were
also checked.

After refining F3's typography/contrast, the 189-check HUD regression and complete
CPU match demo were repeated successfully. F3 now uses the existing uppercase
pixel font on a dark development background, retaining movement and range
information alongside CPU state, distance, action, target beat, offset, result,
seed, difficulty, commitment and weights.

Actual graphical Godot runs used the production wall/audio clock and an automated
Red test player. One completed match (Hard, seed 7000) finished Blue 2–0, with
8 hits, 4 blocks, 1 parry and 3 whiffs across both supplied stages. Screenshots
were inspected:

- [Mode menu](../screenshots/milestone-005/menu.png).
- [Combat](../screenshots/milestone-005/combat.png),
  [block](../screenshots/milestone-005/block.png),
  [parry](../screenshots/milestone-005/parry.png).
- [Round progression](../screenshots/milestone-005/round-won.png),
  [match completion](../screenshots/milestone-005/champion.png).
- [F3 diagnostics](../screenshots/milestone-005/debug.png).
- [Continuous recording filmstrip](../screenshots/milestone-005/continuous-match-filmstrip.png).

A continuous Movie Maker recording is retained locally as
`output/cpu005-complete-match.avi`: **49.8 seconds, 1,494 frames, 320×180 at 30 FPS**.
Its frame count, JPEG frame dimensions, sample frames and nonzero audio payload
were inspected. It includes menu, countdown, race, movement, combat, round change,
stage change and champion display. The video has no spliced segments or forced
scores. The generated video remains outside Git; the filmstrip and
[movie/live verification metadata](milestone-005-demo.json) are versioned.

Reproduce the real-clock graphical test:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --scene scenes/tests/cpu_demo.tscn --max-fps 120 -- --cpu-seed=7000 --cpu-difficulty=hard
```

Reproduce the continuous recording:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --scene scenes/tests/cpu_demo.tscn --write-movie output/cpu005-complete-match.avi --fixed-fps 30 --disable-vsync -- --cpu-seed=7000 --cpu-difficulty=hard --record-cpu-demo
```

Movie Maker explicitly injects a test clock so offline frames stay on a fixed
musical timeline. That override is confined to the test driver; it is never
used in the playable root project. The Blue opponent is the actual production
CPU, not a scripted sequence. Red is a defined automated strategy in both tests.

Reproduce measurements and summary:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --log-file output/cpu.log --script tests/test_cpu.gd
.venv/bin/python tools/summarize_cpu.py output/cpu005-simulation.json --output output/cpu005-summary.json
```

Run checks first to create the ignored output directory. `-- --quick-cpu` selects
an 18-match development matrix; it is not the reported 900-match measurement.

## Limits and preserved files

No physical keyboard playtesting, perceptual audio-sync listening or subjective
"enjoyable/balanced" verdict is claimed. The owner should assess response,
predictability and pacing, especially Easy's movement accuracy. The light history
model recognises height tendencies only; it is intentionally not a sophisticated
fighter. The measured win distributions describe only the specified test bots.

Passing runs had no parse/assertion failures. This environment emitted existing
macOS CA-certificate/editor-settings sandbox and ObjectDB teardown messages;
some terminal GUI launches aborted before initialization and succeeded on retry.
New untracked backgrounds 03–07 and newly supplied character outcome sheets were
left outside this commit. No original artwork/audio, other repositories,
infrastructure, credentials or paid image generation were changed.

Studio workflow adaptation: the kit's inspected vertical-slice and debug-gameplay workflows informed complete-loop replay and seeded rule regression. Godot runs replace its browser Lab; no Godot-specific kit commands or agents were invented.
