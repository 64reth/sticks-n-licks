# Logic Pro audio handoff

Provide menu, standoff, combat loops at 120/140/160 BPM, race cue (snare/cutoff experiment), stick impact, block, perfect parry and victory sting. Place originals in the relevant `assets/audio/` directories; preserve stems separately. Export loop points at exact musical phrase lengths, preferably WAV or Ogg. Do not infer downbeats from filenames.

Set each resource's `path` in `data/audio.json` to a `res://assets/audio/...` path, and `beat_zero_seconds` to the measured downbeat offset within the file. Music entries loop by default; effects do not. Optional `loop` overrides that choice. Use short loops with beat zero at the file beginning; if an export has a pre-roll or tail, author exact loop points in Godot/the source export before delivery. Automatic looping spans the entire file, not a guessed trimmed range.

AudioDirector seeks playback against the shared beat anchor, accounting for next mix/output latency. During combat, conductor time reads playback position + time since last mix − output latency − configured beat-zero offset. Phrase-boundary tempo changes select the matching tempo loop. `latency_ms` in combat settings compensates player input; positive values subtract measured input delay. The F3 overlay shows offset and input errors. Verify by ear on the target output device. Production soundtrack alignment cannot be verified until the exports exist.

With no tracks present, a monotonic microsecond clock and synthetic metronome keep all rules playable. Drum cutoff means no fourth click at the final cue; the accented alternative plays one. Menu/HUD state remains authoritative.
