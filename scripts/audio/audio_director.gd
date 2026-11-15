class_name AudioDirector
extends Node
# Replace these resources and offsets; names do not establish alignment.
var tracks: Dictionary = {}
var offsets: Dictionary = {}
var music := AudioStreamPlayer.new()
var effects := AudioStreamPlayer.new()
var anchor: float = 0.0
var active: String = ""

func _ready() -> void:
 add_child(music)
 add_child(effects)
 var file := FileAccess.open("res://data/audio.json", FileAccess.READ)
 if file:
  var config = JSON.parse_string(file.get_as_text())
  for key in config:
   offsets[key] = float(config[key].get("beat_zero_seconds", 0.0))
   var path: String = config[key].get("path", "")
   if not path.is_empty() and ResourceLoader.exists(path):
    var stream := load(path).duplicate() as AudioStream
    if bool(config[key].get("loop", key in ["menu", "standoff", "120", "140", "160"])):
     if stream is AudioStreamWAV:
      stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
      stream.loop_end = int(stream.get_length() * stream.mix_rate)
     elif stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
      stream.loop = true
    tracks[key] = stream

func play_track(key: String, beat_zero: float) -> void:
 active = key
 anchor = beat_zero
 music.stop()
 if tracks.has(key):
  music.stream = tracks[key]
  # Start at the shared clock's current beat position, including output delay.
  var elapsed := maxf(0.0, Time.get_ticks_usec() / 1000000.0 - anchor)
  var seek := elapsed + float(offsets.get(key, 0.0)) + AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
  if music.stream.get_length() > 0:
   seek = fposmod(seek, music.stream.get_length())
  music.play(maxf(0.0, seek))

func sound(key: String) -> void:
 if tracks.has(key):
  effects.stream = tracks[key]
  effects.play()

func audio_time() -> float:
 return music.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency() - float(offsets.get(active, 0.0))
