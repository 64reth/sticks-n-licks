extends "res://scripts/main.gd"
# Synthetic keyboard events; injected clock only when explicitly recording offline.
var demo_raw := 0.0
var elapsed := 0.0
var offline := false
var captured: Dictionary={}
var sent: Dictionary={}
var bot := RhythmTestPlayer.new()
var seen_cue := -INF
var paused_demo := false
var pause_at := -INF
var resume_at := -INF
func _ready() -> void:
 offline="--record007" in OS.get_cmdline_user_args()
 if offline:conductor.clock_override=func():return demo_raw
 preferences_path=""
 super._ready()
 if offline:
  intro.timeline=func():return demo_raw
  audio.enabled=true
  audio.play_track("intro",conductor.now(),true)
 if "--desktop007" in OS.get_cmdline_user_args():
  DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
  DisplayServer.window_set_size(Vector2i(1280,720))
  DisplayServer.window_set_position(Vector2i(40,60))
  DisplayServer.window_move_to_foreground()
 game_mode="cpu"
 cpu_difficulty="normal"
 stage_preference="stage_03"
 preferences.values.stage=stage_preference
 bot.configure("balanced",107007)
 conductor.beat_changed.connect(func(_b: int,_p: int):
  if mode=="combat":bot.plan_boundary(public_cpu_observation()))
func press(code: int) -> void:
 var event:=InputEventKey.new()
 event.keycode=code
 event.physical_keycode=code
 event.pressed=true
 Input.parse_input_event(event)
 event=event.duplicate()
 event.pressed=false
 Input.parse_input_event(event)
func once(at: float,id: String,keys: Array) -> void:
 if elapsed>=at and not sent.has(id):
  sent[id]=true
  for code in keys:press(code)
func capture(label: String) -> void:
 if captured.has(label) or DisplayServer.get_name()=="headless":return
 captured[label]=true
 await RenderingServer.frame_post_draw
 var required_frames: Dictionary={"logo-rest":0,"logo-squash":1,"logo-stretch":2,"stage-speaker-rest":0,"stage-speaker-pulse":2}
 if required_frames.has(label):
  var actual: int=stage.speaker.frame if label.begins_with("stage-") else intro.logo.frame
  if actual!=int(required_frames[label]):
   captured.erase(label)
   return
 get_viewport().get_texture().get_image().save_png("res://output/007-"+label+".png")
 if "--desktop007" in OS.get_cmdline_user_args():
  var target:=ProjectSettings.globalize_path("res://output/007-"+label+"-desktop.png")
  var code:=OS.execute(ProjectSettings.globalize_path("res://output/capture-game-window"),[str(OS.get_process_id()),target])
  print("007 targeted desktop capture ",label," exit=",code)

func _process(delta: float) -> void:
 elapsed+=delta
 if offline:demo_raw+=delta
 super._process(delta)
 for row in [[0.016,"initial"],[0.25,"sky-entering"],[0.8,"foreground-entering"],[1.65,"logo-entrance"],[2.01,"logo-squash"],[2.10,"logo-stretch"],[2.3,"logo-rest"],[3.6,"title-ready"]]:
  if elapsed>=float(row[0]):capture(str(row[1]))
 once(4.3,"open-menu",[KEY_ENTER])
 if elapsed>=4.5 and elapsed<5:capture("main-menu")
 once(5,"help",[KEY_DOWN,KEY_DOWN,KEY_ENTER])
 if elapsed>=5.3 and elapsed<6:capture("tutorial-1")
 once(6.3,"page2",[KEY_RIGHT])
 if elapsed>=6.6 and elapsed<7.5:capture("tutorial-2")
 once(7.6,"page3",[KEY_RIGHT])
 if elapsed>=7.9 and elapsed<8.8:capture("tutorial-3")
 once(9,"back",[KEY_ESCAPE])
 once(9.5,"setup",[KEY_ENTER])
 once(10,"begin",[KEY_DOWN,KEY_DOWN,KEY_DOWN,KEY_DOWN,KEY_DOWN,KEY_ENTER])
 if mode=="standoff" and cue!=seen_cue:
  seen_cue=cue
  bot.start_round(cue)
 if mode in ["standoff","race","combat"] and not paused:
  while bot.next_time()<=game_time():
   var intent: Dictionary=bot.pop_intent()
   if intent.kind=="race" and mode not in ["standoff","race"]:continue
   if intent.kind!="race" and mode!="combat":continue
   var action: InputEventKey=InputMap.action_get_events("p1_"+str(intent.action))[0]
   press(action.physical_keycode)
   if intent.kind=="combat":press(KEY_F)
 if mode=="combat" and not paused_demo:
  if conductor.beat==1:capture("stage-speaker-rest")
  if conductor.beat==2:capture("stage-speaker-pulse")
  if conductor.beat==3:
   paused_demo=true
   pause_at=elapsed
   press(KEY_ESCAPE)
 if paused_demo:
  once(pause_at+0.4,"pause-help",[KEY_DOWN,KEY_DOWN,KEY_DOWN,KEY_ENTER])
  if elapsed>=pause_at+0.6 and elapsed<pause_at+1.2:capture("pause-tutorial")
  once(pause_at+1.4,"pause-page2",[KEY_RIGHT])
  once(pause_at+2.4,"pause-back",[KEY_ESCAPE])
  if elapsed>=pause_at+2.6 and elapsed<pause_at+3.0:capture("pause-return")
  once(pause_at+3.2,"resume",[KEY_ESCAPE])
  if elapsed>=pause_at+3.5:
   capture("resumed-game")
   if resume_at<0:resume_at=elapsed
  if resume_at>0 and elapsed>resume_at+2:
   var report:=FileAccess.open("res://output/milestone007-demo-"+("movie" if offline else "live")+".json",FileAccess.WRITE)
   report.store_string(JSON.stringify({"success":not paused and mode=="combat","elapsed":elapsed,"captures":captured.keys(),"cue_log":intro.cue_log,"clock":"injected offline" if offline else "production playback/monotonic","input":"scripted keyboard; not physical playtesting","audio_capture":"Godot Movie Maker AVI audio; listening review pending"},"  "))
   print("MILESTONE 007 DEMO COMPLETE resumed=",not paused," stage=",stage.entries[stage.selected].id)
   audio.stop()
   get_tree().quit()
 if elapsed>90:
  push_error("007 demo timed out "+mode+"/"+flow.view.page)
  get_tree().quit(1)
