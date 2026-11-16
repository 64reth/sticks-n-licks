# Milestone 006 — arcade front end, configuration and fighter reactions

Built directly on `f0e7f4d68cdb530fde73f81d2b3c1d349148726a` in the existing root
Godot project. `project.godot` still launches `scenes/main/main.tscn`; no nested
project, alternate checkout, new service or infrastructure was introduced.

## Front end and controls

`ArcadeFrontEnd` draws the native 320×180 menu using the project's own bitmap
font, cream/gold/teal palette, consistent borders and a restrained moving focus
triangle. The original font generator now supplies missing punctuation such as
percent signs. No external artwork, fonts or music were added.

`ArcadeFlow` owns page construction/navigation; gameplay remains in the existing
main, conductor, shared input adapter, Bout and CPU controller. Pages are:

- Title: Start Game, Options, How to Play, Quit Game.
- Match Setup: mode, applicable CPU difficulty, best-of format, tempo, stage,
  Start Bout and Back.
- Options: Audio, Display, Gameplay, Reset Defaults and Back; category pages keep
  each list short enough for the native viewport.
- Pause: Resume, Restart Match, Options, Main Menu.
- Final Result: Rematch, Match Setup, Main Menu, below the character baseline.

Up/Down wraps the highlight. Left/Right changes the selected value. Enter
activates a command or confirms a value and advances to the next row. Escape
backs out; during an active match it pauses. OS key-repeat is ignored, held
confirmation is suppressed until release, and focus loss clears stale UI holds.
Menus consume navigation before any fighter input. Mouse support was not added.

Normal M/P/H/C shortcuts are removed. F3 remains off by default and toggles
in-match diagnostics. F4 only previews stages before a match while diagnostics
are enabled; it cannot alter a live stage. Control help is now a normal menu page.

## Configuration and persistence

Setup supports CPU/PvP, Easy/Normal/Hard, best-of-3/5/7, 120/140/160 BPM and each
available stage or Random. Red remains Player 1; Blue remains CPU or Player 2.
The existing CPU profiles, private RNG and committed defence model are retained.
`--cpu-seed=7000 --cpu-difficulty=hard` remains supported; difficulty survives
opening Setup. Last selected mode still comes from preferences.

MatchProgress's existing first-to-wins calculation now receives the selected
format. The winner needs 2/3/4 rounds, and every round still needs three clean
hits. Existing player cards already support dynamic markers; all three layouts
were tested and captured. Every possible deciding score, including 4–3, was
checked for either winner. No unused rounds are required after a decision.

The selected tempo applies to both standoff and combat conductor starts, cue
math, pickup boundary scheduling, CPU timing and native combat recordings.
Only a 120 BPM standoff recording is supplied: it plays at selected-BPM/120
speed, with rate-correct source seeks/clock conversion. Combat uses its native
120/140/160 recording at normal speed. This preserves the supplied files rather
than pretending additional standoff recordings exist. Existing phrase-boundary
escalation remains available; tempo never changes mid-phrase.

`UserPreferences` saves a versioned ConfigFile in `user://preferences.cfg`:
section `preferences`, `version=1`, dictionary `values`. It persists mode,
difficulty, best-of, BPM, stage preference, master/music/SFX volume, music/SFX
on/off, fullscreen, integer scaling and timing feedback. Saved types/enums are
validated, volumes clamped to 0–100, corrupt/unknown values replaced safely, and
unavailable stages fall back to Stage 01 or the first available image.

Changes save automatically. Audio/display/feedback options apply immediately;
resetting defaults during a pause does not reconfigure the active match. New
setup uses the reset match defaults, while restart/rematch preserves the active
match's selected configuration.

Audio uses Master/Music/SFX buses. Music off mutes the bus while retaining its
clock; zero volume truly mutes. Window/fullscreen and integer/fractional scaling
use Godot's window settings, while nearest texture sampling remains enabled.
There is no screen-shake implementation, so no nonfunctional shake toggle was
added. Control reference and timing-feedback visibility are gameplay options.
Navigation uses an original short synthesized click. Supplied impact SFX are
still absent; hit/block/parry use the short procedural click fallback with
separate pitches, through the SFX bus. No unrelated music was substituted.

An isolated write/reload check succeeded in this game's real Godot user-data
directory. A further check saved in one Godot process and reloaded in a second;
the temporary verification file was removed. The owner's `preferences.cfg` was
not changed by tests. Routine tests use empty or `output/` preferences paths.

## Stage discovery

The catalogue contains **eight selectable entries / seven distinct images**, plus
Random. All are RGB PNG, 1672×941:

| ID | Name | Actual source |
|---|---|---|
| stage_01 | Village Street | background_01.png |
| stage_02 | Beach Courtyard | background_02; matching PNG import copy |
| stage_03 | Crop Over Festival | background_03; matching PNG |
| stage_04 | Fish Fry | background_04.png |
| stage_04_original | Seafront Street | extensionless background_04 |
| stage_05 | Fish Fry Copy | background_05; same pixels/bytes as Stage 04 PNG |
| stage_06 | Speightstown | background_06.png |
| stage_07 | Animal Flower Cave | background_07.png |

The extensionless Stage 04 is a different image from its `.png` namesake. It is
preserved and has a byte-identical `background_04_original.png` import copy.
Nothing was silently replaced. `data/stages.json` records source/import hashes,
dimensions, names and the duplicate relationship. Runtime availability filtering
prevents missing assets from appearing as valid choices. All originals and
extensionless provenance files are retained.

StageBackground still uses uniform cover scaling and nearest filtering. Its
slight aspect-ratio overflow is clipped by the viewport, not destructively
cropped from source files. Ground stays Y=150; collision geometry is unchanged.
Random is chosen once per match and remains stable through its rounds. A
separate seeded stage RNG avoids consuming the CPU decision stream; new matches
can reroll. Environmental animation/parallax remain a separate future pass.

## Eight supplied reaction sheets

The actual defeat filenames are `fighter_01_defeat.png` and
`fighter_02_defeat.png`, not `*_defeated.png`. `defeated` is a metadata alias.
Red's extensionless stunned file duplicates its canonical PNG and is preserved.

| State, each fighter | Source dimensions | Layout / frames | Playback |
|---|---|---|---|
| Stunned | 2172×724 | 3 columns, 724px cells | 3 poses / 330 ms |
| Hurt | 1774×887 | 2 columns, 887px cells | 2 poses / 200 ms |
| Victory | 2172×724 | 4 columns, 543px cells | 4 poses / 800 ms |
| Defeat | 2172×724 | 3 columns, 724px cells | 3 poses / 600 ms |

After inspecting source layouts, `tools/import_reactions.py` exported **24 frames**
into new `frames/milestone_006/` directories. Originals were never overwritten,
resized or resampled. The tool refuses an existing output directory. Native
foreground pixels are translated onto 768×768 transparent RGBA canvases with
baseline 744, using the existing metadata pipeline and per-sheet standing-height
calibration. All frames retain native proportions and source-facing orientation.

The original Red victory sheet contains a neutral gray alpha haze, with no fully
transparent background. Only its derivative cells receive border-connected
neutral-haze removal. Alpha dust below 32 is cleared in derivatives; retained
RGBA pixels remain exactly equal to the source. Automated checks compare all
retained pixels, not only samples. New SpriteFrames are non-looping. Hurt aliases
replace old directional-hit fallback poses; stunned/stagger and defeat/defeated
share the appropriate supplied artwork.

The [source/frame manifest](../assets/milestone-006-manifest.json) records original
SHA-256 hashes, rectangles, translations, dimensions, alpha extrema, frame counts
and scales. The new [reaction-frame contact sheet](../screenshots/milestone-006/reaction-frames.png)
was inspected alongside individual native game captures. Raised sticks naturally
extend above the roughly 64px standing body; no arbitrary parent/camera scaling
was used. Hitboxes remain independent of artwork.

## Movement-only parry stun and state priority

A perfect parry still reverses initiative and does no damage. It additionally
marks the parried attacker for the next conductor movement opportunity: the next
phrase's beat one, including its full early/late timing window. Any early tap
already queued for that beat is cancelled with STUN feedback. All taps for that
opportunity are rejected; the restriction expires when its window closes even
if no key was pressed. At a catch-up resolution, the target time is the new
phrase boundary already being processed, not an extra phrase later.

Only movement extraction is restricted. The shared direction/execute combination
continues to select attacks and blocks; it is never gated on stun. Legal combat
can interrupt stunned recoil. The restriction is not driven by animation
completion and cannot persist because a fighter did not attempt movement.

Fighter's visual priority/deadline mechanism separates presentation from rules:
final result is locked at priority 100, legal combat can interrupt recoil/hurt
at 75, hurt uses 70, stunned recoil 50, movement 30 and idle 0. Round transition
mode prevents new actions without playing final poses. Reactions replace the
completed exchange's visual priority; legal later actions still win over recoil.
Hurt applies no extra damage, movement penalty or input lockout. New match/round
reset clears visual locks and old flash/spark/recovery effects.

Final poses reject idle, movement, impact and stale whiff requests. No animation
callback changes gameplay state. Final victory/defeat resources stop once and
hold the last frame until an explicit result choice.

## Pause, ordinary rounds and final results

Pause captures the shared logical clock and suspends music/file effects and
fighter processing. The CPU scheduler and conductor do not advance. Inputs are
consumed by the pause UI; held/pending gameplay input is cleared. Navigation
clicks remain available. Resume subtracts paused wall time through the conductor's
single offset, rather than shifting every event or catching up missed beats.
The paused audio clock returns its captured position, so mixer correction cannot
creep while UI frames redraw. Fresh direction presses are required after resume.

Outcome presentation uses logical deadlines rather than wall-clock timers.
Ordinary round wins stop combat, play the normal final-hit hurt reaction, update
the marker and show ROUND WON, then wait for Enter. They play neither victory nor
defeat music and use no victory/defeated animation. Next standoff resets only the
round state, preserving match score, chosen stage/tempo and appropriate CPU
learning.

On the deciding hit, gameplay stops immediately. After the brief hurt reaction,
one guarded result handler starts winner/loser final animations and calls
`AudioDirector.play_result(game_mode,winner)` exactly once:

| Mode / winner | Theme |
|---|---|
| CPU mode, Red human | victory_120.wav |
| CPU mode, Blue CPU | defeat_120.wav |
| PvP, either winner | victory_120.wav |

Both recordings are the existing approved one-shot assets; their loops remain
disabled. One music player prevents overlapping result themes. Bus volumes and
mute settings apply to them. Rematch/title transitions stop the old result
stream. Result UI stays below the character baseline and holds the final poses.

## Executed verification

`bash tools/check.sh` was executed successfully, including the existing rule,
control, media, range, movement, HUD, real-clock PvP, Python, match-demo and
900-match seeded CPU regressions. Milestone 006 adds focused menu/configuration,
validation/persistence, all deciding scores, tempo, pause, reaction priority,
movement-stun boundary and result-audio checks. Final counts and recorded run
metadata are retained in [milestone-006-evidence.json](milestone-006-evidence.json).
The source/alpha/pixel asset suite passes 24 Python tests.

Important targeted cases include a next-beat tap queued before a 160 BPM parry
is adjudicated, a parry resolved while the conductor catches up across a phrase,
late taps for the restricted beat, expiry without input, and legal MID attacks
and parries while movement restriction is active. Missing stages, invalid saved
settings, held Enter, focus loss, pause/resume input clearing, zero volume and
separate-process persistence were checked. Every final score for both winners
in all three match formats was tested.

Actual graphical runs inspected title, setup, all option categories, control
help, pause, 3/5/7-marker HUDs, all stage entries, fullscreen/windowed presentation,
both fighters' reaction/outcome frames and human-win/CPU-loss/PvP results.
The gallery uses controlled regression starting states followed by validated
combat events; it is distinct from the continuous full-match demonstration.

A separate real-clock graphical run used the production monotonic/audio clock
and completed a best-of-five human victory with five parries. Player input in
these tests is synthetic InputMap key events. Physical keyboard playtesting was
not performed.

## Continuous demonstration and reproduction

Local recording: `output/milestone006-complete.avi` — **91.37 seconds, 2,741 frames,
320×180 at 30 FPS**, with interleaved nonzero audio. Every JPEG frame was verified.
The recording is one uninterrupted Godot Movie Maker run: no splices, manually
awarded scores or forced outcomes. It uses the production CPU and shared action
validator against an automated Red test strategy.

It shows title/options/help navigation, Normal difficulty selection, best-of-five,
Beach Courtyard selection, pause/options/resume, movement, attacks, three parries,
visible STUN, hurt, ordinary rounds, a 3–1 human match victory with the victory
theme, and return to title. Around 37–39 seconds Blue is parried, loses a movement
opportunity, then legally blocks Red's next attack. The filmstrip samples those
moments; the audio event log verifies ordinary rounds used no result theme.

- [Title](../screenshots/milestone-006/title.png),
  [configured setup](../screenshots/milestone-006/setup.png),
  [audio](../screenshots/milestone-006/audio.png),
  [pause](../screenshots/milestone-006/pause.png).
- [HUD best-of-3](../screenshots/milestone-006/hud-best3.png),
  [best-of-5](../screenshots/milestone-006/hud-best5.png),
  [best-of-7](../screenshots/milestone-006/hud-best7.png).
- [Movement stun](../screenshots/milestone-006/movement-stun.png),
  [human victory](../screenshots/milestone-006/human-victory.png),
  [human defeat](../screenshots/milestone-006/human-defeat.png),
  [PvP result](../screenshots/milestone-006/pvp-result.png).
- [Festival](../screenshots/milestone-006/stage-festival.png),
  [cave](../screenshots/milestone-006/stage-cave.png),
  [continuous filmstrip](../screenshots/milestone-006/continuous-filmstrip.png).

From the repository root, after Godot has imported the project:

```sh
mkdir -p output
/Applications/Godot.app/Contents/MacOS/Godot --path . --scene scenes/tests/frontend_demo.tscn --write-movie output/milestone006-complete.avi --fixed-fps 30 --disable-vsync -- --record-front-demo --cpu-seed=7000
```

The test-only recording flag injects a fixed-step clock for offline rendering.
Production gameplay never uses it. Omit `--record-front-demo` and Movie Maker
options for the real-clock graphical run. The test driver sends physical-key
InputEvents through normal handlers and never writes positions, health or wins.

Separate graphical result cases:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --scene scenes/tests/frontend_demo.tscn --fixed-fps 60 --disable-vsync -- --record-front-demo --cpu-seed=7000 --scenario=cpu_loss
/Applications/Godot.app/Contents/MacOS/Godot --path . --scene scenes/tests/frontend_demo.tscn --fixed-fps 60 --disable-vsync -- --record-front-demo --cpu-seed=7000 --scenario=pvp
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/test_frontend_graphics.gd
```

CPU-loss verification selected the defeat theme; PvP completion selected victory.
Both PvP winners are covered by the result-handler regression tests. Their
full event records are included in the evidence JSON. Generated AVIs, temporary
captures, settings-test files and logs remain under ignored `output/`; selected
screenshots and metadata are versioned.

## Remaining review and limitations

Physical keyboard focus/rollover, subjective balance, perceptual audio sync and
the feel of the new stun/recoil require owner playtesting. Recorded PCM presence
and stream/event selection were checked; no listening review is claimed. Standoff
speed adjustment changes pitch at 140/160 BPM because only the approved 120 BPM
standoff export exists. Dedicated native-tempo standoff exports and final impact
SFX can replace the current fallbacks later.

Godot emitted the environment's existing CA-certificate, editor-settings sandbox
and ObjectDB teardown messages; some terminal GUI launches needed a retry before
initialization. Passing runs had no script parse/assertion failures. The root
project remained the development target throughout. Studio-kit guidance was
adapted from its actual vertical-slice/debug/visual-refinement workflows using
Godot runs in place of its browser Lab; no new kit capabilities were invented.
