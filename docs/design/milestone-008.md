# Milestone 008 — essential SFX and automatic rounds

Implemented on `development` after `a57870d`, with the Milestone 007 UI polish. The scope refinement is authoritative: FreeSFX supplies **only eight short combat/menu effects**. No new background music, ambient soundscapes, countdown music or round/match melodies were added. All original music, percussion, downbeat offsets and result themes remain intact.

## Source discovery and licensing status

The supplied archive is `assets/audio/sfx/FreeSFX.zip` (102,859,491 bytes, 265 entries). It remains unchanged locally. No licence/readme/terms document was found in it; commercial redistribution rights **could not be established**. The integration is therefore **provisional development work**, not clearance for a commercial build. Outstanding questions are the pack author/licence version, permission for commercial games and modified excerpts/source redistribution, and required attribution. Obtain the applicable rights and attribution requirements before commercial distribution; the word “Free” in a filename does not establish them.

The complete archive is not added to Git. Eight selected originals are retained byte-identically under `source/audio/freesfx_008/` with `.gdignore`, and short runtime excerpts live under `assets/audio/sfx/freesfx_008/`. `docs/assets/milestone-008-sfx.json` records the archive/source/derivative SHA-256 values, exact archive paths, metadata inventory, source frame ranges and fade lengths. `tools/import_freesfx.py` refuses existing output directories and never overwrites the archive or originals.

Candidate WAV metadata was inspected in Impact, Swoosh, PickUp, Events, Alarms Blip Beeps, Music/Success and Cinematic. Long events/rings were avoided; Music/Success and Cinematic were excluded from integration by the refined scope. No accompanying recommendation file was present in the repository, so filenames were starting candidates rather than treated as mandatory choices.

All selected assets retain their original 44.1kHz, 16-bit PCM and channel layout (block is mono; the others stereo). The measured onsets required no leading trim. Runtime excerpts cap the tails and fade the last 12ms to zero, without normalising or resampling source audio. Only derivatives are changed.

| Event | Original path below `FreeSFX/GameSFX/` | Clip ms | Bus / gain | Playback |
| --- | --- | ---: | --- | --- |
| Navigate | `Alarms Blip Beeps/Retro Beeep 06.wav` | 80 | UI / -23dB | Quiet short blip |
| Confirm | `Alarms Blip Beeps/Retro Beeep 20.wav` | 96.7 | UI / -19dB | Distinct short click/beep |
| Back/cancel | `Events/Wrong/Retro Event Wrong Simple 03.wav` | 180 | UI / -22dB | Pitch descends 1.0→0.72, about 209ms playback |
| Stick swing | `Swoosh/Retro Swooosh 02.wav` | 220 | SFX / -25dB | Subtle pitch variation ±0.035 |
| Hit | `Impact/Retro Impact Punch 07.wav` | 280 | SFX / -11dB | Retro impact |
| Block | `Impact/Retro Impact Punch Hurt 01.wav` | 220 | SFX / -16dB | Muted, pitch 0.9 |
| Perfect parry | `Impact/Retro Impact Metal 36.wav` | 240 | SFX / -14dB | Distinct metallic accent |
| Pickup | `PickUp/Retro PickUp Coin 04.wav` | 200 | SFX / -21dB | Brief pickup accent |

The candidate playlist was played through the local device with `afplay` (exit 0). The agent had no auditory input channel, so these character descriptions reflect source categories/configuration, not a verified subjective listening judgement. A listening review of timbre, balance and perceptual contact synchronisation remains outstanding.

## Audio events and mixing

`AudioEvents` is a reusable child of the existing `AudioDirector`. Sound paths stay in the canonical `data/audio.json`; new SFX musical beat-zero fields remain null/unconfirmed. `data/sfx.json` owns resource-key mappings, event gains, bus choice, cooldowns, pitch variation, descending pitch envelope and polyphony. It preloads eight streams and allocates a fixed pool: **three SFX voices and one UI voice**, each with `max_polyphony=1`. A new sound safely replaces the earliest-finishing voice in its bus; there is no unbounded node creation. The obsolete unattached synthetic navigation player was removed.

Music retains its existing player and bus. UI routes to SFX, then Master; UI has an additional **-3dB** bus gain. The existing Master/Music/SFX preferences remain authoritative: muting SFX also mutes UI. Original music/percussion gains and musical clock logic are unchanged. Cosmetic pitch RNG is separate from CPU and anticipation RNG. Back's linear pitch envelope uses an absolute UI clock, not accumulated frame delta.

SFX pause with the conductor and resume without wall-time catch-up. UI remains audible in pause menus, with its own monotonic cooldown/envelope clock. The offline recorder explicitly injects a UI clock only under `--record008` for reproducibility. The result/reset logic never waits for an audio callback.

Event routing:

- Navigation/confirm/back come from `ArcadeFlow` after valid menu commands. A 65ms per-event cooldown keeps rapid key sequences quiet.
- Pickup comes from accepted `Bout.race_press` state or the existing automatic pickup phase. Per-player round flags prevent repeated pickup events; pickups within 70ms coalesce audibly, preserving both logical ownership events.
- Swing and impact come from **`Bout.last_event` after resolution**, alongside the existing contact burst. A valid out-of-range swing gets only a whoosh. Missing/mistimed attacks get no success sound. HIT/BLOCK/PARRY map to separate streams; input/wind-up alone plays none.
- Match/round/phrase keys use the authoritative resolved phrase; duplicate keys are suppressed. The key cache is bounded at 128 and the diagnostic trace at 1,024 entries.
- Countdown/GO events are recorded logically but use the existing percussion/cue path. Round victory/defeat events are intentionally silent. Match victory/defeat events retain the existing original one-shot themes. No FreeSFX melody is mapped to any of these six events.

Returning to the main menu cancels the pending round deadline and clears combat tails while preserving the UI back sound. A final hit's tail is allowed to finish when music stops, avoiding the old shared-effects-player cutoff. Swing is deliberately much quieter than the simultaneous impact. The sampled contact burst and sound dispatch share the resolved callback/clock; hardware output latency and subjective perceptual sync are not established by that fact alone.

## Automatic round state machine

| State | Transition |
| --- | --- |
| Combat | Third clean hit awards one round marker, as before |
| Finishing | Existing 0.35s ordinary / 0.22s deciding impact recovery |
| Ordinary `round_win` | Winner/loser play supplied **unlocked** victory/defeat reactions; display result for 2.5s |
| Standoff | Automatic reset, fresh beat-one origin and original standoff track, then authoritative countdown/race |
| Deciding `match_win` | Guarded, locked final poses and original result theme; explicit rematch/setup/menu controls |

`round_result_seconds` in `data/combat/settings.json` defaults to **2.5** (validated range 2–10 seconds). Total ordinary hit-to-next-round time is approximately 0.35 + 2.5 = **2.85 seconds**. The deadline uses `RhythmConductor.now`; no wall timer or frame-delta clock is introduced. Pause freezes that clock and the deadline remains unchanged. A 1ns comparison tolerance handles floating-point representation at the exact presentation boundary without changing any combat window.

Milestone 008 supersedes the earlier ordinary-round idle-only presentation: ordinary rounds now show short winner/loser reactions, but they are not match-final locks and play no victory/defeat music. Match celebration/result guards remain unchanged.

At reset, `MatchProgress.next_round()` preserves markers and match format; a fresh Bout resets hits/energy, initiative/race state, positions and selections. Actors snap to their logical starting anchors and synchronise hurtboxes **before** the new countdown. Sticks return crossed. Pending/held controls, recovery and round CPU intents clear; directions from the previous round are not re-seeded. CPU learning survives. Stage selection remains fixed for the match. The new standoff starts at a fresh musical phrase origin using the existing owner-confirmed track boundary.

Only `round_win` can dispatch the deadline. Reset clears it to infinity and MatchProgress rejects a second request. Enter no longer advances an ordinary round or skips its result display. Escape still pauses. Completed matches never auto-rematch. No damage, hit geometry, initiative, ±70/±140ms precision, 100ms chords, movement windows or CPU planner rules changed.

## Automated and graphical verification

The full `bash tools/check.sh` run exited **0**:

| Suite | Checks / result |
| --- | ---: |
| Rules / controls | 51 / 46, all passed |
| Media / launch-range | 3,348 / 974, all passed |
| Idle-movement / HUD / live movement | 676 / 189 / 168, all passed |
| CPU fairness and frame-rate replay | **1,795,853 checks; 900 matches; zero failures** |
| Milestone 006 / tutorial / gameplay props / Milestone 007 | 292 / 201 / 166 / 61, all passed |
| UI polish / Milestone 008 | **200 / 292**, all passed |
| Python asset tests | **29 tests**, all passed |

Focused tests cover all 14 logical event mappings, the eight playable streams, per-event deduplication, coalescing, polyphony, distinct impact types at all heights with either attacker, no speculative success sounds, matching effect timestamps, misses, both pickup orders, pause UI audio, and CPU/PvP automatic lifecycle for either winner. They check scores, health, positions, sticks, actor readiness, input clearing, learning retention, duplicate transitions and no automatic match restart.

Legacy fixtures were updated only where they assumed Enter-to-next-round or idle-only ordinary results. The 900-match simulation now waits through the real result deadline and starts its test player at the new cue. Production CPU code is untouched. Existing certificate/ObjectDB diagnostics appeared in the full run; final focused checks after removing the unused navigation node introduced no resource-leak warnings.

The continuous native recording is **`output/milestone008.avi`**: **2,521 frames / 60 FPS = 42.017 seconds**, with audio. It shows menu navigation/confirm/back, match start, pickup, swing/hit, normal block, perfect parry, ordinary winner/loser result, automatic next countdown and final match result. It contains **8 HIT, 2 BLOCK and 2 PARRY** exchanges, one ordinary result and final score **Blue 2–0**. No Enter is sent between rounds.

The recording contains 8,067,200 PCM audio bytes, 6,953,222 nonzero bytes, peak **0.66156** (about -3.59dBFS), RMS **0.09667**, and **zero clipped samples**. Its extracted `output/milestone008-audio.wav` was played through `afplay` (exit 0). This verifies capture and device playback, not subjective balance or perceptual synchronisation. Native screenshots were inspected for impact mapping, visible reactions, cleared/reset state and the explicit final menu. See `docs/screenshots/milestone-008/` and `milestone-008-evidence.json` for captures, audio trace, result music and recording hash.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . \
  --log-file output/008-movie.log --fixed-fps 60 \
  --write-movie output/milestone008.avi \
  --scene scenes/tests/milestone008_demo.tscn -- --record008
```

The demo uses an explicitly injected offline clock and legal scripted PvP actions through `submit_action`; no score, fighter position, current selections or round phase is overridden. Initial mode/stage and anticipation count are test configuration. It is not physical keyboard playtesting. Movies, extracted mixes and audition files stay in ignored `output/`.

## Remaining limitations

Commercial sound licensing is unresolved. Subjective listening/balance and hardware contact-sync review remain manual. Keyboard/focus/hardware rollover playtesting is not established by synthetic actions. No FreeSFX music or ambient material was substituted for those limitations, and all owner-supplied originals remain preserved.
