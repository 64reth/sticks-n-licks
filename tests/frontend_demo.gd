extends "res://scripts/main.gd"
# Continuous UI + match test. Both scripted players send actual InputMap key events.
var demo_raw:=0.0
var elapsed:=0.0
var offline:=false
var scenario: String="human_win"
var red_bot:=RhythmTestPlayer.new()
var blue_bot:=RhythmTestPlayer.new()
var script_keys: Array[int]=[]
var next_key_at:=0.8
var ui_done:=false
var seen_round_cue: float=-INF
var phase_at: float=-1
var recorded: Dictionary={}
var exchange_seen:=0
var pause_done:=false
var pause_steps:=0
var next_pause_key:=0.0
var finished:=false
var result_theme: String=""
var final_at: float=-1
var data: Array[Dictionary]=[]
func _ready() -> void:
 offline="--record-front-demo" in OS.get_cmdline_user_args()
 if offline:conductor.clock_override=func():return demo_raw
 preferences_path=""
 super._ready()
 if offline:
  audio.enabled=true
  audio.play_track("menu",conductor.now(),true)
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--scenario="):scenario=arg.get_slice("=",1)
 red_bot.configure("guard_high" if scenario=="human_win" else "rush_high",107000)
 blue_bot.configure("balanced",107001,1)
 conductor.beat_changed.connect(_boundary)
 # Navigate real title/options/how-to/setup entirely through keyboard events.
 script_keys.assign([KEY_DOWN,KEY_ENTER,KEY_ENTER,KEY_LEFT,KEY_ESCAPE,KEY_ESCAPE,KEY_DOWN,KEY_DOWN,KEY_ENTER,KEY_ESCAPE,KEY_ENTER])
 # At setup, row 0 is Mode.
 if scenario=="pvp":script_keys.append(KEY_RIGHT)
 script_keys.append(KEY_DOWN)
 if scenario=="cpu_loss":script_keys.append(KEY_RIGHT)
 elif scenario=="human_win":script_keys.append_array([KEY_LEFT,KEY_RIGHT])
 script_keys.append(KEY_DOWN)
 if scenario=="human_win":script_keys.append(KEY_RIGHT) # Best of five
 script_keys.append_array([KEY_DOWN,KEY_DOWN,KEY_RIGHT,KEY_DOWN,KEY_ENTER])
func _key(code: int) -> void:
 var event:=InputEventKey.new()
 event.keycode=code
 event.physical_keycode=code
 event.pressed=true
 Input.parse_input_event(event)
 event=event.duplicate()
 event.pressed=false
 Input.parse_input_event(event)
func _action(player: int,action: String) -> void:
 var event: InputEventKey=InputMap.action_get_events("p%d_%s" % [player+1,action])[0].duplicate()
 event.keycode=event.physical_keycode
 event.pressed=true
 Input.parse_input_event(event)
 event=event.duplicate()
 event.pressed=false
 Input.parse_input_event(event)
func _boundary(_beat: int,_phrase: int) -> void:
 if mode=="combat":
  red_bot.plan_boundary(public_cpu_observation())
  if game_mode=="pvp":blue_bot.plan_boundary(public_cpu_observation())
func _attempt(player: int,intent: Dictionary) -> void:
 if intent.kind=="race" and mode not in ["standoff","race"]:return
 if intent.kind!="race" and mode!="combat":return
 _action(player,str(intent.action))
 if intent.kind=="combat":_action(player,"execute")
func capture(name: String) -> void:
 var key:=scenario+"-"+name
 if recorded.has(key) or DisplayServer.get_name()=="headless":return
 recorded[key]=true
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://output/front006-"+key+".png")
func _process(delta: float) -> void:
 elapsed+=delta
 if offline:demo_raw+=delta
 super._process(delta)
 if not ui_done:
  capture(flow.view.page)
  if flow.view.page=="setup" and flow.view.cursor==5 and script_keys.size()==1:capture("configured-setup")
  if elapsed>=next_key_at:
   if not script_keys.is_empty():_key(script_keys.pop_front())
   next_key_at=elapsed+0.25
   if script_keys.is_empty():ui_done=true
  return
 if mode=="standoff" and seen_round_cue!=cue:
  seen_round_cue=cue
  red_bot.start_round(cue)
  blue_bot.start_round(cue)
  if game_mode=="pvp":blue_bot.queue[0].at+=0.05
 if not paused and mode in ["standoff","race","combat"]:
  while red_bot.next_time()<=game_time():_attempt(0,red_bot.pop_intent())
  if game_mode=="pvp":
   while blue_bot.next_time()<=game_time():_attempt(1,blue_bot.pop_intent())
 if scenario=="human_win" and not pause_done and mode=="combat" and conductor.beat==2:
  pause_done=true
  _key(KEY_ESCAPE)
  pause_steps=1
  next_pause_key=elapsed+0.8
 if paused:
  capture("pause")
  if elapsed>=next_pause_key:
   # Show options from pause, then back/resume; logical music time stays frozen.
   var keys: Array[int]=[KEY_DOWN,KEY_DOWN,KEY_ENTER,KEY_ESCAPE,KEY_ESCAPE]
   if pause_steps<=keys.size():_key(keys[pause_steps-1])
   pause_steps+=1
   next_pause_key=elapsed+0.3
  return
 if mode=="combat":
  capture("hud-best%d" % match_progress.best_of)
  for player in range(2):
   if fighters[player].pose in ["stunned","hurt"]:capture("fighter%d-%s" % [player+1,fighters[player].pose])
   if controls[player].step_feedback.begins_with("STUN"):capture("movement-stun")
 if completed_exchanges.size()>exchange_seen:
  exchange_seen=completed_exchanges.size()
  data.append({"event":bout.last_event.kind,"attacker":bout.last_event.attacker,"at":conductor.now(),"round":match_progress.round_number})
  capture(str(bout.last_event.kind).to_lower())
 if mode=="round_win":
  capture("round-win")
  if phase_at<0:
   phase_at=elapsed
   data.append({"event":"ordinary_round","audio":audio.active,"poses":[fighters[0].pose,fighters[1].pose]})
  if elapsed-phase_at>0.8:
   _key(KEY_ENTER)
   phase_at=-1
 if mode=="match_win" and not finished:
  capture("result")
  if final_at<0:
   final_at=elapsed
   result_theme=audio.active
   data.append({"event":"match_result","winner":match_progress.winner,"theme":result_theme,"wins":match_progress.round_wins.duplicate()})
  if elapsed-final_at>1.0:
   capture("final-poses")
  if elapsed-final_at>1.6:
   _key(KEY_DOWN)
   _key(KEY_DOWN)
   _key(KEY_ENTER)
   finished=true
   phase_at=elapsed
 if finished and elapsed-phase_at>0.5:
  var out:=FileAccess.open("res://output/front006-"+scenario+".json",FileAccess.WRITE)
  var parries:=0
  for event in data:
   if event.event=="PARRY":parries+=1
  var success:=mode=="menu" and audio.active=="menu" and ((result_theme=="victory" and parries>0) if scenario=="human_win" else result_theme==("defeat" if scenario=="cpu_loss" else "victory"))
  out.store_string(JSON.stringify({"scenario":scenario,"success":success,"elapsed":elapsed,"events":data,"audio_events":audio.event_log,"seed":cpu_seed,"parries":parries,"clock":"injected for offline recording" if offline else "production monotonic/audio","input":"synthetic physical-key events via InputMap; no manual keyboard"},"  "))
  print("FRONT 006 DEMO ",scenario," success=",success," result=",result_theme," parries=",parries)
  audio.stop()
  get_tree().quit(0 if success else 1)
 if elapsed>300:
  push_error("Front-end demo timed out "+mode+"/"+flow.view.page)
  get_tree().quit(1)
