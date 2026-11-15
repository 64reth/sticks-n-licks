extends Node2D
var conductor := RhythmConductor.new()
var director := AudioDirector.new()
var label := Label.new()
var stage: int = 0
var last_time: float = 0.0
var verified_loops: int = 0
var pending_section: String = ""

func _ready() -> void:
 director.clock_source = conductor.now
 add_child(director)
 label.position = Vector2(6,8)
 label.add_theme_font_size_override("font_size",9)
 add_child(label)
 conductor.phrase_changed.connect(on_phrase)
 start_bpm(120)

func start_bpm(bpm: int) -> void:
 director.stop()
 conductor.start()
 conductor.bpm = bpm
 conductor.pending_bpm = bpm
 director.play_track(str(bpm),conductor.epoch,true)
 last_time = 0.0

func on_phrase(_phrase: int) -> void:
 var key := str(conductor.bpm) if director.active in ["120", "140", "160"] else director.active
 if not pending_section.is_empty():
  key = pending_section
  pending_section = ""
  conductor.bpm = int(director.entries[key].get("bpm", conductor.bpm))
  conductor.pending_bpm = conductor.bpm
 if director.active != key:
  director.play_track(key,conductor.phrase_start)

func _unhandled_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo:return
 match event.keycode:
  KEY_1: start_bpm(120)
  KEY_2: start_bpm(140)
  KEY_3: start_bpm(160)
  KEY_Q: pending_section = "menu"
  KEY_W: pending_section = "standoff"
  KEY_E: pending_section = "intro"
  KEY_V: pending_section = "victory"
  KEY_D: pending_section = "defeat"
  KEY_MINUS: director.latency_ms -= 1
  KEY_EQUAL: director.latency_ms += 1
  KEY_BRACKETLEFT: director.offsets[director.active] = float(director.offsets.get(director.active,0))-0.005
  KEY_BRACKETRIGHT: director.offsets[director.active] = float(director.offsets.get(director.active,0))+0.005

func _process(_delta: float) -> void:
 var elapsed := director.audio_time()
 conductor.update(director.anchor + elapsed)
 label.text = "AUDIO / RHYTHM TEST\n1/2/3 independently test BPM\nQ menu W standoff E intro V victory D defeat\n[ ] preview offset ±5ms · -/+ latency ±1ms\n%s\nBeat %d phrase %d · BPM %d -> %d\nPlayback %.3fs · phase test\nLive offset %.3fs (not saved)\nOwner confirmed beat-zero/full-file loops
Listening / device calibration still required" % [director.diagnostic(),conductor.beat,conductor.phrase,conductor.bpm,conductor.pending_bpm,elapsed,float(director.offsets.get(director.active,0))]
 if OS.get_cmdline_user_args().has("--verify-audio"):
  assert(elapsed + 0.01 >= last_time,"Audio clock moved backwards at loop")
  last_time = elapsed
  if conductor.phrase >= 5:
   assert(director.restart_count == stage + 1,"Music restarted unnecessarily within a test stage")
   assert(not director.effects.playing,"Music duplicated in effects player")
   stage += 1
   print("AUDIO RUNTIME: ",conductor.bpm," BPM, ",elapsed,"s, beat ",conductor.beat,"; loop clock monotonic; starts=",director.restart_count)
   verified_loops += 1
   if conductor.bpm == 160:
    director.stop()
    print("AUDIO RUNTIME: 3 tempos passed; perceptual sync not asserted")
    get_tree().quit()
   else:
    start_bpm(140 if conductor.bpm==120 else 160)
