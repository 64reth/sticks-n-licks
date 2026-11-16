extends "res://scripts/main.gd"
# Native main-scene movie, scripted keyboard events. Clock override only on explicit offline flag.
var elapsed:=0.0
var demo_raw:=0.0
var offline:=false
var sent: Dictionary={}
var captures: Dictionary={}
var started_playing: float=-1
var ending_since: float=-1
var desktop_shot: bool=false
var traversal_trace: Array=[]
func _ready() -> void:
 offline="--record009" in OS.get_cmdline_user_args()
 if offline:conductor.clock_override=func():return demo_raw
 preferences_path=""
 super._ready()
 story.save.path=""
 story.save.data={}
 if offline:
  audio.enabled=DisplayServer.get_name()!="headless"
  audio.events.ui_clock_source=conductor.now
  if not audio.active.is_empty():audio.play_track(audio.active,audio.anchor,true)
func key_event(code: int, pressed: bool=true) -> void:
 var event:=InputEventKey.new()
 event.keycode=code
 event.physical_keycode=code
 event.pressed=pressed
 _unhandled_input(event)
func tap(code: int) -> void:
 key_event(code,true)
 key_event(code,false)
func once(at: float, name: String, codes: Array) -> void:
 if elapsed>=at and not sent.has(name):
  sent[name]=true
  for code in codes:tap(code)
func shot(name: String) -> void:
 if captures.has(name) or DisplayServer.get_name()=="headless":return
 captures[name]=true
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://output/009-"+name+".png")
func _process(delta: float) -> void:
 elapsed+=delta
 if offline:demo_raw+=delta
 super._process(delta)
 once(.5,"intro skip",[KEY_ENTER])
 once(1.0,"menu",[KEY_ENTER])
 once(1.5,"story menu",[KEY_DOWN,KEY_DOWN,KEY_DOWN,KEY_ENTER])
 if elapsed>1.6 and mode=="menu":shot("story-menu")
 once(2.2,"new game",[KEY_ENTER])
 if mode=="story":
  var rb:=story.absolute_beat()-story.origin
  if story.phase=="cinematic":
   if rb<1:shot("closed")
   if rb>=2 and rb<3:shot("door")
   if rb>=4 and rb<4.5:shot("kick")
   if rb>=4.8 and rb<5.5:shot("flight")
   if rb>=6 and rb<6.5:shot("landing")
   if rb>=6.6 and rb<7:shot("dust")
   if rb>=12 and rb<13:shot("dust-off")
   if rb>=14 and rb<15:shot("recovered")
  if story.phase=="waiting":shot("handoff-idle")
  if story.phase=="playing" and started_playing<0:
   started_playing=conductor.beat_time
   debug_visible=true
   shot("control-enabled")
  if started_playing>=0 and story.phase=="playing" and ending_since<0:
   var beats: float=(game_time()-started_playing)/conductor.duration()
   # Eight right steps, two idle beats, four left, duck/stand, deliberate miss,
   # one held press spanning three beats (no repeats), release, then exit.
   for i in range(8):
    var name: String="right%d" % i
    if beats>=i+.03 and not sent.has(name):
     sent[name]=true
     tap(KEY_D)
     if i==7:shot("eight-right")
   if beats>=9:
    shot("stopped")
    if not desktop_shot and "--desktop009" in OS.get_cmdline_user_args():
     desktop_shot=true
     OS.execute(ProjectSettings.globalize_path("res://output/capture-game-window"),[str(OS.get_process_id()),ProjectSettings.globalize_path("res://output/009-desktop.png")])
   for i in range(4):
    var name: String="left%d" % i
    if beats>=10+i+.03 and not sent.has(name):
     sent[name]=true
     tap(KEY_A)
   if beats>=14.03 and not sent.has("duck"):
    sent.duck=true
    key_event(KEY_S)
   if beats>=14.3:shot("duck")
   if beats>=15 and not sent.has("stand"):
    sent.stand=true
    key_event(KEY_S,false)
   if beats>=15.5 and not sent.has("miss"):
    sent.miss=true
    tap(KEY_D)
    shot("mistimed")
   if beats>=17.03 and not sent.has("hold"):
    sent.hold=true
    key_event(KEY_D)
   if beats>=19.5:shot("held-no-repeat")
   if beats>=20.01 and not sent.has("release"):
    sent.release=true
    key_event(KEY_D,false)
   for i in range(10):
    var name: String="exit%d" % i
    if beats>=21+i+.03 and not sent.has(name):
     sent[name]=true
     tap(KEY_D)
  if story.phase=="complete" and ending_since<0:
   ending_since=elapsed
   shot("screen-complete")
   traversal_trace=story.trace.duplicate(true)
   print("STORY DEMO: complete steps=",story.trace.filter(func(row):return row.event=="step").size())
 if ending_since>=0:
  once(ending_since+1,"return-story",[KEY_ENTER])
  once(ending_since+2,"continue",[KEY_DOWN,KEY_ENTER])
  if elapsed>=ending_since+2.6:shot("continue")
  once(ending_since+3.5,"pause",[KEY_ESCAPE])
  once(ending_since+4,"main menu",[KEY_DOWN,KEY_DOWN,KEY_ENTER])
  once(ending_since+4.5,"diagnostics off",[KEY_F3])
  once(ending_since+5,"arcade",[KEY_ENTER,KEY_DOWN,KEY_DOWN,KEY_DOWN,KEY_DOWN,KEY_DOWN,KEY_ENTER])
  if elapsed>=ending_since+5.3:shot("arcade")
  if elapsed>=ending_since+7:
   print("STORY DEMO COMPLETE: scripted keyboard, offline clock=",offline)
   var file:=FileAccess.open("res://output/009-demo-summary.json",FileAccess.WRITE)
   file.store_string(JSON.stringify({"offline_clock":offline,"captures":captures.keys(),"arcade_mode":mode,"seconds":elapsed,"traversal":traversal_trace},"  "))
   get_tree().quit()
 if elapsed>45:
  push_error("Story demo timeout: "+story.phase)
  get_tree().quit(1)
