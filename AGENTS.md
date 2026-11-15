# Sticks n Licks

Work only in this repository. Preserve original artwork, source audio, and unrelated files. Never commit credentials, `.env`, dependencies, `.godot`, or generated builds. No paid image requests without explicit user approval of the exact dry-run request. Paid batch generation and replacement of approved art require separate approval. This project currently has no paid batch command.

## Verified studio workflow

Read-only source: `/Users/garethwallen/Projects/solo-game-studio-kit`, remote `https://github.com/64reth/solo-game-studio-kit`, inspected at `f0989e7c2187e747fb38f05ef071e73202c5e9b8`.

The kit is a TypeScript toolkit. It contains no Godot support, image API integration, named agent system, or Godot test command. Do not claim otherwise. Its `AGENTS.md`, `workflows/vertical-slice.md`, `workflows/game-feel.md`, `workflows/debug-gameplay.md`, and `workflows/visual-refinement.md` guide this project with these documented adaptations:

1. Inspect existing files and the affected rule before editing.
2. Build a small complete start/input/feedback/outcome/restart loop.
3. Launch and interact with the real Godot player in place of the kit's browser Lab. Record what was observed and any limits; a scripted demonstration is not human playtesting.
4. Keep deterministic combat rules separate from rendering and animation. Reproduce timing bugs with explicit timestamps; test meaningful rule regressions.
5. Run `bash tools/check.sh`. The kit's npm checks apply to its TypeScript projects, not this GDScript project.
6. Review visual readability, high/mid/low feedback and controls. Fix observed problems and repeat the player loop. Commit/push only when requested and verify origin first.

## Project conventions

Godot 4.6+, GDScript, 320×180 viewport, nearest-neighbour textures, 96×96 transparent RGBA sprite cells. Use Godot InputMap; preserve the right-Shift-only binding. Combat rules are in `scripts/combat/bout.gd`, the clock in `scripts/rhythm/rhythm_conductor.gd`, orchestration in `scripts/main.gd`. Production musical time is monotonic microseconds or the audio playback clock, never accumulated frame delta. The injected clock in the scripted demo is test-only.

Keep timing windows, input latency, race configuration and escalation thresholds in `data/combat/settings.json`; resource paths and beat-zero offsets in `data/audio.json`. Tempo transitions happen only at phrase boundaries. A race win or parry never awards a hit. Missing production assets must not block launching.

Store original character artwork under `source/` or `references/`; never destructively resize or overwrite it. Export validated frames into a new version directory and inspect the manifest before configuring the fighter. Automated pixel checks do not approve character identity or visual quality. Do not add an API key to Godot or game exports. The optional Python tools are development dependencies only.
