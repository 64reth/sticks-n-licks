class_name RhythmConductor
extends RefCounted
signal beat_changed(beat: int, phrase: int)
signal phrase_changed(phrase: int)
var bpm: int = 120
var pending_bpm: int = 120
var phrase: int = 0
var beat: int = 0
var beat_time: float = 0.0
var epoch: float = 0.0
var phrase_start: float = 0.0
var latency_ms: float = 0.0
var perfect_ms: float = 70.0
var good_ms: float = 140.0
var started: bool = false
var clock_override: Callable

func now() -> float:
 if clock_override.is_valid():
  return clock_override.call()
 return Time.get_ticks_usec() / 1000000.0

func start(at: float = -1.0) -> void:
 bpm = 120
 pending_bpm = 120
 phrase = 0
 beat = 0
 epoch = now() if at < 0 else at
 phrase_start = epoch
 beat_time = epoch
 started = true

func duration() -> float:
 return 60.0 / bpm

func schedule_tempo(value: int) -> void:
 assert(value in [120, 140, 160])
 pending_bpm = value

func update(at: float) -> void:
 if not started or at < epoch:
  return
 # Emit every crossed boundary in order, even after a slow render frame.
 if beat == 0:
  beat = 1
  beat_time = phrase_start
  beat_changed.emit(beat, phrase)
 while true:
  var boundary := phrase_start + duration() * beat
  if at + 0.000000001 < boundary:
   break
  if beat == 4:
   phrase_start = boundary
   phrase += 1
   bpm = pending_bpm
   beat = 1
   phrase_changed.emit(phrase)
  else:
   beat += 1
  beat_time = boundary
  beat_changed.emit(beat, phrase)

func action_time() -> float:
 return phrase_start + duration() * 3.0

func timestamp(at: float) -> float:
 return at - latency_ms / 1000.0

func grade(error_ms: float) -> String:
 if abs(error_ms) <= perfect_ms + 0.000001:
  return "perfect"
 if abs(error_ms) <= good_ms + 0.000001:
  return "good"
 return "miss"
