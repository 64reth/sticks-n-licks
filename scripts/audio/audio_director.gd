class_name AudioDirector
extends Node
var tracks: Dictionary = {}
var offsets: Dictionary = {}
var entries: Dictionary = {}
var music := AudioStreamPlayer.new()
var effects := AudioStreamPlayer.new()
var anchor: float = 0.0
var active: String = ""
var enabled: bool = true
var latency_ms: float = 0.0
var scheduled: Dictionary = {}
var clock_source: Callable
var started_at: float = 0.0
var last_elapsed: float = 0.0
var restart_count: int = 0

func now() -> float:
 return clock_source.call() if clock_source.is_valid() else Time.get_ticks_usec() / 1000000.0

func _ready() -> void:
 add_child(music)
 add_child(effects)
 var file := FileAccess.open("res://data/audio.json", FileAccess.READ)
 if not file:
  return
 entries = JSON.parse_string(file.get_as_text())
 for key in entries:
  var item: Dictionary = entries[key]
  offsets[key] = float(item["beat_zero_seconds"]) if item.get("beat_zero_seconds") != null else 0.0
  var path: String = item.get("path", "")
  if path.is_empty() or not ResourceLoader.exists(path):
   continue
  var stream := load(path).duplicate() as AudioStream
  if stream == null:
   continue
  if stream is AudioStreamWAV:
   stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if item.get("loop", false) else AudioStreamWAV.LOOP_DISABLED
   var from: float = float(item["loop_start_seconds"]) if item.get("loop_start_seconds") != null else 0.0
   var to: float = float(item["loop_end_seconds"]) if item.get("loop_end_seconds") != null else stream.get_length()
   stream.loop_begin = int(round(from * stream.mix_rate))
   stream.loop_end = int(round(to * stream.mix_rate))
  tracks[key] = stream

func stop() -> void:
 music.stop()
 effects.stop()
 scheduled.clear()
 active = ""

func schedule_track(key: String, boundary: float) -> void:
 scheduled = {"key": key, "at": boundary}

func _process(_delta: float) -> void:
 if not scheduled.is_empty() and now() >= float(scheduled["at"]):
  var next := scheduled.duplicate()
  scheduled.clear()
  play_track(next["key"], next["at"])

func play_track(key: String, beat_zero: float, force: bool = false) -> void:
 if active == key and music.playing and not force:
  return
 scheduled.clear()
 active = key
 anchor = beat_zero
 started_at = now()
 last_elapsed = 0.0
 music.stop()
 effects.stop()
 if not enabled or not tracks.has(key):
  return
 music.stream = tracks[key]
 var elapsed := maxf(0.0, now() - anchor)
 var seek := elapsed + float(offsets.get(key, 0.0)) + AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency() + latency_ms / 1000.0
 var length := music.stream.get_length()
 if length > 0 and entries[key].get("loop", false):
  if music.stream is AudioStreamWAV:
   var start: float = float(music.stream.loop_begin) / music.stream.mix_rate
   var end: float = float(music.stream.loop_end) / music.stream.mix_rate
   if seek >= end and end > start:
    seek = start + fposmod(seek - start, end - start)
  else:
   seek = fposmod(seek, length)
 music.play(maxf(0.0, seek))
 restart_count += 1

func sound(key: String) -> void:
 if enabled and tracks.has(key):
  effects.stream = tracks[key]
  effects.play()

static func unwrap(raw: float, expected: float, length: float) -> float:
 # Playback positions wrap; the shared monotonic anchor disambiguates loop cycles.
 if length <= 0:
  return raw
 return raw + maxf(0.0, round((expected - raw) / length)) * length

func audio_time() -> float:
 if not music.playing or music.stream == null:
  return maxf(last_elapsed, now() - anchor)
 var raw := music.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency() - latency_ms / 1000.0 - float(offsets.get(active, 0.0))
 var expected := maxf(0, now() - anchor)
 var length := music.stream.get_length() if entries.get(active, {}).get("loop", false) else 0.0
 if length > 0 and music.stream is AudioStreamWAV:
  length = float(music.stream.loop_end - music.stream.loop_begin) / music.stream.mix_rate
 last_elapsed = maxf(last_elapsed, unwrap(raw, expected, length))
 return last_elapsed

func diagnostic() -> String:
 var item: Dictionary = entries.get(active, {})
 var file: String = str(item.get("path", "none")).get_file()
 var offset := str(item.get("beat_zero_seconds", "unset"))
 if item.get("beat_zero_seconds") == null:
  offset = "UNCONFIRMED"
 return "%s · %s BPM\noffset %s · latency %.1fms\nnext %s" % [file, str(item.get("bpm", "--")), offset, latency_ms, str(scheduled)]

func _exit_tree() -> void:
 music.stop()
 effects.stop()
 music.stream = null
 effects.stream = null
 tracks.clear()
 clock_source = Callable()
