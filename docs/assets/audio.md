# Original soundtrack handoff and calibration

The eight supplied WAV recordings are now integrated. See [Milestone 002](milestone-002.md) for assignments and [audio inventory](milestone-002-audio.json) for duration, sample rate, channels, bit depth, hashes and embedded tempo labels.

`data/audio.json` maps menu/standoff/combat/victory to their original resources, and intro/defeat to optional developer previews. No separate recorded race, hit, block or parry SFX exists. The race keeps the established synthetic accent/cutoff cue. One music player owns the arrangement; no track restarts each exchange. Tempo changes and outcome music occur at phrase boundaries.

The owner explicitly confirmed beat 1 at sample zero and whole-file loop boundaries. `beat_zero_seconds: 0`, `alignment_confirmed: true`, and sample-exact start/end boundaries now record that confirmation. Menu/standoff/combat repeat; intro/victory/defeat remain one-shot arrangements by gameplay role. For future unconfirmed exports, keep these fields null until measured or confirmed. Keep originals and stems unchanged. Filenames and first nonzero waveform samples do not establish downbeats.

`audio_latency_ms` in combat settings calibrates output timing; `latency_ms` independently calibrates input timing. The audio clock uses playback position, mix/output latency, the configured offset and a shared monotonic anchor. Loop positions are unwrapped into continuous musical elapsed time. No perceptual audio synchronisation is claimed by automated clock tests.

Open `scenes/tests/audio_test.tscn` and press F6. 1/2/3 tests 120/140/160 BPM. Q/W/E/V/D previews sections at musical boundaries. Brackets adjust the preview offset by 5 ms; minus/equals adjusts output compensation by 1 ms. These controls do not overwrite the configuration. The display includes source file, recording BPM, current beat/phrase, offset status, compensation and next transition. F3 in the main game also exposes audio diagnostics.

Missing optional recordings leave gameplay playable. Loop seams, output-device calibration, the precise three-count arrangement and final race signal still require listening review; downbeat/full-file loop placement is owner-confirmed. Isolated impact/block/parry SFX and separate cue recording remain asset work.
