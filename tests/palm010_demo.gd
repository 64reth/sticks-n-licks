extends "res://scripts/main.gd"
# Native main-scene input demo; offline time is opt-in for MovieMaker only.
var elapsed:=0.0
var demo_raw:=0.0
var offline:=false
var sent: Dictionary={}
var shots: Dictionary={}
var traversal_started: float=-1
var report: Array[Dictionary]=[]
var twin: CoconutPalm
func _ready() -> void:
 offline="--record010" in OS.get_cmdline_user_args()
 if offline:conductor.clock_override=func():return demo_raw
 preferences_path=""
 super._ready()
 story.save.path=""
 story.save.data={}
 if offline:
  audio.enabled=DisplayServer.get_name()!="headless"
  audio.events.ui_clock_source=conductor.now
  if not audio.active.is_empty():audio.play_track(audio.active,audio.anchor,true)
func tap(code: int) -> void:
 key(code,true)
 key(code,false)
func key(code: int, pressed: bool) -> void:
 var event:=InputEventKey.new()
 event.keycode=code
 event.physical_keycode=code
 event.pressed=pressed
 _unhandled_input(event)
func once(at: float,name: String,codes: Array) -> void:
 if elapsed>=at and not sent.has(name):
  sent[name]=true
  for code in codes:tap(code)
func capture(name: String) -> void:
 if shots.has(name) or DisplayServer.get_name()=="headless":return
 shots[name]=true
 var palm: CoconutPalm=story.screens.current.get_node("CoconutPalm") if mode=="story" else null
 if palm:
  if is_instance_valid(twin):twin.sync_clock()
  report.append({"shot":name,"beat":palm.sampled_beat,"frame":palm.frame,"twin_frame":twin.frame if is_instance_valid(twin) else -1,"phase":story.phase,"x":story.target_x,"epoch":conductor.epoch,"music_restarts":audio.restart_count})
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://output/010-"+name+".png")
func _process(delta: float) -> void:
 elapsed+=delta
 if offline:demo_raw+=delta
 super._process(delta)
 once(.5,"intro skip",[KEY_ENTER])
 once(1,"title",[KEY_ENTER])
 once(1.5,"story menu",[KEY_DOWN,KEY_DOWN,KEY_DOWN,KEY_ENTER])
 once(2.2,"new game",[KEY_ENTER])
 if mode=="story":
  var palm: CoconutPalm=story.screens.current.get_node("CoconutPalm")
  palm.sync_clock()
  if story.phase=="cinematic" and not sent.has("replay"):
   var relative:=story.absolute_beat()-story.origin
   if relative<1:capture("closed")
   if relative>=4 and relative<4.5:capture("kick")
   if relative>=6 and relative<7:capture("landing")
   if relative>=14:capture("recovery")
   for i in range(8):
    if int(floor(palm.sampled_beat))%8==i:capture("frame%d" % i)
  if story.phase=="waiting":capture("handoff")
  if story.phase=="playing" and traversal_started<0:
   traversal_started=conductor.beat_time
   capture("control")
  if story.phase=="playing" and not sent.has("replay"):
   var beats: float=(game_time()-traversal_started)/conductor.duration()
   for i in range(8):
    var name: String="right%d" % i
    if beats>=i+.03 and not sent.has(name):
     sent[name]=true
     tap(KEY_D)
   for i in range(4):
    var name: String="left%d" % i
    if beats>=10+i+.03 and not sent.has(name):
     sent[name]=true
     tap(KEY_A)
   if beats>=14:capture("traversal")
 once(18,"pause",[KEY_ESCAPE])
 if paused:capture("paused")
 once(19,"resume",[KEY_ENTER])
 once(20,"debug",[KEY_F3])
 once(20.5,"replay",[KEY_F6])
 if elapsed>=21 and mode=="story":capture("restarted")
 once(22.5,"skip",[KEY_ENTER])
 once(23.2,"hide diagnostics",[KEY_F3])
 if elapsed>=23 and mode=="story":capture("skipped")
 if elapsed>=24 and mode=="story" and not sent.has("twin"):
  sent.twin=true
  twin=preload("res://scenes/props/coconut_palm.tscn").instantiate()
  twin.position=Vector2(245,149)
  twin.z_index=-1
  twin.display_scale=.24
  twin.phase_offset_beats=2
  story.screens.current.add_child(twin)
  twin.bind_clock(conductor)
 if elapsed>=24.3 and elapsed<28 and is_instance_valid(twin):
  var palm: CoconutPalm=story.screens.current.get_node("CoconutPalm")
  var name: String="two-palms-%d" % (int(floor(palm.sampled_beat))%8)
  capture(name)
 if elapsed>=25 and "--desktop010" in OS.get_cmdline_user_args() and not sent.has("desktop"):
  sent.desktop=true
  OS.execute(ProjectSettings.globalize_path("res://output/capture-game-window"),[str(OS.get_process_id()),ProjectSettings.globalize_path("res://output/010-desktop.png")])
 if elapsed>=28 and is_instance_valid(twin):twin.queue_free()
 if elapsed>=29 and mode=="story":capture("one-palm-restored")
 if elapsed>=30:
  var file:=FileAccess.open("res://output/010-demo-"+("movie" if offline else "live")+".json",FileAccess.WRITE)
  file.store_string(JSON.stringify({"offline_clock":offline,"seconds":elapsed,"captures":shots.keys(),"report":report,"mode":mode,"state":story.phase,"remaining_palms":story.screens.current.get_children().filter(func(n):return n is CoconutPalm).size()},"  "))
  print("PALM DEMO COMPLETE: offline=",offline," state=",story.phase)
  get_tree().quit()
