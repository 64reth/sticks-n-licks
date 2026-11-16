class_name AudioEvents
extends Node
var config: Dictionary={}
var streams: Dictionary={}
var voices: Array[AudioStreamPlayer]=[]
var until: Array[float]=[]
var envelopes: Array[Dictionary]=[]
var trace: Array[Dictionary]=[]
var seen: Dictionary={}
var order: Array[String]=[]
var last: Dictionary={}
var clock_source: Callable
var ui_clock_source: Callable
var enabled := true
var paused := false
var rng := RandomNumberGenerator.new()
func now() -> float:return float(clock_source.call()) if clock_source.is_valid() else Time.get_ticks_usec()/1000000.0
func ui_now() -> float:return float(ui_clock_source.call()) if ui_clock_source.is_valid() else Time.get_ticks_usec()/1000000.0
func _ready() -> void:
 config=JSON.parse_string(FileAccess.get_file_as_string("res://data/sfx.json"))
 for bus in ["Music","SFX","UI"]:
  if AudioServer.get_bus_index(bus)<0:
   AudioServer.add_bus()
   AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
 AudioServer.set_bus_send(AudioServer.get_bus_index("UI"),"SFX")
 rng.seed=8008 # Cosmetic only; never shares planner or anticipation RNG.
 var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/audio.json"))
 for key in config.events:
  var resource: String=str(config.events[key].get("resource", ""))
  var path= catalog.get(resource,{}).get("path")
  if path is String and ResourceLoader.exists(path):streams[key]=load(path)
 for bus in config.voices:
  for i in range(int(config.voices[bus])):
   var voice:=AudioStreamPlayer.new()
   voice.bus=bus
   voice.max_polyphony=1
   add_child(voice)
   voices.append(voice)
   until.append(-INF)
   envelopes.append({})
func record(row: Dictionary) -> void:
 trace.append(row)
 if trace.size()>1024:trace.pop_front()
func emit_event(event: String,key: String="") -> bool:
 if not config.events.has(event):return false
 var at:=now()
 if not key.is_empty():
  if seen.has(key):return false
  seen[key]=true
  order.append(key)
  if order.size()>128:seen.erase(order.pop_front())
 var mapping: Dictionary=config.events[event]
 var bus: String=str(mapping.get("bus","SFX"))
 if paused and bus!="UI":return false
 var interval_at:=ui_now() if bus=="UI" else at
 var row: Dictionary={"event":event,"key":key,"at":at,"status":"logical","voice":-1}
 if not streams.has(event):
  record(row)
  return false
 if interval_at-float(last.get(event,-INF))<float(mapping.get("min_interval_ms",0))/1000.0:
  row.status="coalesced"
  record(row)
  return false
 last[event]=interval_at
 var chosen: int=-1
 for i in range(voices.size()):
  if voices[i].bus==bus and (chosen<0 or until[i]<until[chosen]):chosen=i
 if chosen<0:return false
 var pitch:=float(mapping.get("pitch",1.0))+rng.randf_range(-float(mapping.get("pitch_variation",0)),float(mapping.get("pitch_variation",0)))
 var voice: AudioStreamPlayer=voices[chosen]
 voice.stop()
 voice.stream=streams[event]
 voice.volume_db=float(mapping.get("volume_db",-18))
 voice.pitch_scale=maxf(0.5,pitch)
 var end_pitch:=maxf(0.5,float(mapping.get("pitch_end",voice.pitch_scale)))
 var duration:=voice.stream.get_length()/((voice.pitch_scale+end_pitch)/2.0)
 until[chosen]=at+duration
 envelopes[chosen]={"at":interval_at,"from":voice.pitch_scale,"to":end_pitch,"duration":duration,"ui":bus=="UI"} if end_pitch!=voice.pitch_scale else {}
 if enabled:voice.play()
 row.status="played" if enabled else "muted"
 row.voice=chosen
 row.bus=bus
 row.volume_db=voice.volume_db
 row.pitch=voice.pitch_scale
 row.pitch_end=end_pitch
 record(row)
 return true
func set_paused(value: bool) -> void:
 paused=value
 for voice in voices:
  if voice.bus=="SFX":voice.stream_paused=value
func clear_round() -> void:
 # Logical clock remains the conductor; no wall-clock deadline shifting.
 for i in range(voices.size()):
  if voices[i].bus=="SFX":
   voices[i].stop()
   until[i]=-INF
   envelopes[i]={}
 last.clear()
func active_voices(bus: String) -> int:
 var count:=0
 for i in range(voices.size()):
  if voices[i].bus==bus and until[i]>now():count+=1
 return count

func _exit_tree() -> void:
 for voice in voices:
  voice.stop()
  voice.stream=null
 streams.clear()
 clock_source=Callable()
 ui_clock_source=Callable()

func _process(_delta: float) -> void:
 for i in range(envelopes.size()):
  if envelopes[i].is_empty():continue
  var curve: Dictionary=envelopes[i]
  var at:=ui_now() if curve.ui else now()
  var progress:=clampf((at-float(curve.at))/float(curve.duration),0,1)
  voices[i].pitch_scale=lerpf(float(curve.from),float(curve.to),progress)
  if progress>=1:envelopes[i]={}
