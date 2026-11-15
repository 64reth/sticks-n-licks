# Milestone 001: project foundation and playable prototype

Player goal: win a local stick-fighting bout by landing three clean hits while selecting and executing high/mid/low actions on a shared musical grid.

## Authoritative requirements and implementation

Godot 4, GDScript, minimalist NES-inspired pixel art, fixed side camera, 320×180 internal resolution. Two local keyboard players. Owner produces the original soundtrack in Logic Pro. Required project structure is preserved: character source/spritesheets/frames, music by 120/140/160 BPM, stems/SFX, backgrounds/props/UI, main/fighter/arena/menu/effect scenes, combat/rhythm/fighter/input/UI scripts, animation/combat data, tests/tools and design/asset documentation.

Each phrase has four beats. Beats 1–2 are movement, beat 3 also allows preparation/directional selection, beat 4 is execution. At 120 BPM a beat is 500 ms and a phrase two seconds; 140 and 160 use 60/BPM seconds per beat. The conductor emits every crossed beat/phrase boundary from absolute timestamps. It applies scheduled tempos at phrase boundaries. Input latency compensation subtracts configured milliseconds from captured input time. When an authored combat track is active, audible playback position plus the shared anchor drives the clock.

Standoff uses a randomly selected 1–3 anticipation phrases, then a final three-count and beat-four GO cue. Placeholder drums are synthesised locally. The menu switches accented-click vs drum-cutoff cue. Each player's first race execution is authoritative. Early input forfeits initiative; a double false start reruns the race. Reaction difference ≤5 ms ties, with alternating priority across ties. Unanswered races time out after two seconds. No reaction reruns the anticipation. Race wins never score a hit. Both fighters collect sticks and enter combat after a 750 ms pickup transition.

Combat tracks initiative, two height selections and one execution timestamp per player per phrase. Heights require direction + execute, with held-direction support and a 100 ms buffer in either order; grading uses the execute timestamp. The timing windows include endpoints: perfect ±70 ms, good ±140 ms, otherwise miss. The late window closes 140 ms plus the 100 ms direction combination buffer after beat four before resolution. Matching good defence blocks; matching perfect defence steals initiative. Incorrect/missing/mistimed defence permits a successful attack to score one hit. A missed attack or out-of-reach strike passes initiative without a hit. Parrying does not inflict damage. First to three hits locks combat input, plays hit/knockdown/victory placeholder states, announces the winner and offers rematch/menu.

Movement queues held left/right and applies once at each eligible beat 1–3, with visual interpolation. Release before the boundary cancels the step. Beat 4 starts no movement. Valid combat combinations suppress held horizontal movement until release/repress so forward MID cannot cause an extra step. Logical positions remain in [30,290], at least 40 pixels apart, and never cross. Step size is 16 pixels. Maximum strike distance is provisionally 140 pixels. Collision Areas are independent of image dimensions; the deterministic combat rule uses logical positions, not rendered pixels. No obstacles in this milestone.

Three consecutive correctly defended exchanges schedule escalation to 140 then 160 BPM; hits/missed attacks reset the streak. No mid-phrase tempo transitions. Timing windows are shared by both players. Rematches reset BPM, score, roles, inputs and movement.

P1 uses A/D move, W high, S low, F execute/race. P2 uses Left/Right move, Up high, Down low, Right Shift execute/race. Facing-relative forward + execute is MID. Enter remains menu/rematch only. InputMap stores configurable bindings; H help, F3 overlay, C menu cue toggle and Escape menu. Minimal text displays score, BPM, phase, initiative and outcome; four beat markers pulse. Overlay adds phrase, timing errors, height selections, audio offset and FPS.

## Animation and audio handoff

`AnimatedSprite2D` and `SpriteFrames` support mirrored fighters. All states have temporary procedural two-frame poses: idle, standoff anticipation, false start, race launch, running, stick pickup, combat idle, forward/back step, high/mid/low attack, block, parry and hit, stagger, knockdown, victory and defeat. Placeholder poses establish state wiring; production animation choreography remains an asset task. Idle PNGs demonstrate genuine RGBA, 96×96 cells and approximately 48×64 content.

AudioDirector accepts menu/standoff/combat loops, race cue, impact/block/parry and victory resources. `data/audio.json` records explicit beat-zero offsets independently of filenames. WAV/Ogg/MP3 loops are supported; gameplay launches with every production resource missing. Placeholder clicks are timing aids, not the owner's soundtrack. Final audio alignment and listening/latency calibration require the actual Logic exports and human review.

## Architecture and validation

`RhythmConductor` owns the musical clock; `Bout` owns deterministic race, movement, scoring and combat transitions; `main.gd` handles state/input/visual orchestration; `AudioDirector` handles resources and audio clock readings; `Fighter` owns visual states and collision Areas. Python asset development tools are entirely optional and never run inside the game.

Automated rules cover all tempos, boundaries, scheduled changes, false starts/reactions/ties, blocks/parries/hits/misses/victory/movement and escalation. Scripted end-to-end playback exercises scene orchestration through victory and rematch. Offline Python tests cover PNG/alpha/grid boundaries/slicing/manifests/API approval guards and mocked SDK/cost limits. See verification for executed results and limits.
