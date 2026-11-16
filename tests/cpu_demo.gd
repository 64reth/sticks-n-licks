extends "res://scripts/main.gd"
# Automated test-player only. Blue always uses production CpuController and validation.
var test_player := RhythmTestPlayer.new()
var test_clock := 0.0
var elapsed := 0.0
var recording := false
var start_queued := false
var outcome_at := -1.0
var last_round_cue := -INF
var captured: Dictionary = {}
var last_exchange_count := 0
func _ready() -> void:
 recording="--record-cpu-demo" in OS.get_cmdline_user_args()
 if recording:conductor.clock_override=func():return test_clock
 preferences_path=""
 super._ready()
 if recording:
  # Offline movie audio uses the same simulated conductor clock; production is unchanged.
  audio.enabled=true
  audio.play_track("menu",conductor.now(),true)
 test_player.configure("rush_high",107000)
 conductor.beat_changed.connect(_test_boundary)
func _test_boundary(_beat: int,_phrase: int) -> void:
 if mode=="combat":test_player.plan_boundary(public_cpu_observation())
func _key(code: int) -> void:
 var event:=InputEventKey.new()
 event.keycode=code
 event.pressed=true
 _unhandled_input(event)
 event=event.duplicate()
 event.pressed=false
 _unhandled_input(event)
func _player_action(intent: Dictionary) -> void:
 if intent.kind=="race" and mode not in ["standoff","race"]:return
 if intent.kind!="race" and mode!="combat":return
 for action in [str(intent.action),"execute"] if intent.kind=="combat" else [str(intent.action)]:
  var event:=InputEventAction.new()
  event.action="p1_"+action
  event.pressed=true
  _unhandled_input(event)
  event=event.duplicate()
  event.pressed=false
  _unhandled_input(event)
func capture_once(label: String) -> void:
 if captured.has(label) or DisplayServer.get_name()=="headless":return
 captured[label]=true
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://output/cpu005-"+label+".png")
func _process(delta: float) -> void:
 elapsed+=delta
 if recording:test_clock+=delta
 super._process(delta)
 if mode=="menu" and not start_queued:
  capture_once("menu")
  if elapsed>0.75:
   preferences.values.difficulty=cpu_difficulty
   preferences.values.game_mode=game_mode
   MenuTestInput.start(self)
   start_queued=true
 if mode=="standoff" and cue!=last_round_cue:
  last_round_cue=cue
  test_player.start_round(cue)
 if mode in ["standoff","race","combat"]:
  while test_player.next_time()<=game_time():_player_action(test_player.pop_intent())
 if mode=="standoff":capture_once("countdown")
 if mode=="combat":
  capture_once("combat")
  if not debug_visible and conductor.phrase==1 and not captured.has("debug") and (not recording or "--cpu-debug-capture" in OS.get_cmdline_user_args()):
   _key(KEY_F3)
   capture_once("debug")
  elif debug_visible and conductor.phrase>=2:_key(KEY_F3)
 if completed_exchanges.size()>last_exchange_count:
  last_exchange_count=completed_exchanges.size()
  capture_once(str(bout.last_event.kind).to_lower())
 if mode in ["round_win","match_win"]:
  if outcome_at<0:outcome_at=elapsed
  capture_once(mode)
  if mode=="round_win" and elapsed-outcome_at>0.6:
   _key(KEY_ENTER)
   outcome_at=-1
  elif mode=="match_win" and elapsed-outcome_at>1.0:
   var kinds: Dictionary={}
   for event in completed_exchanges:kinds[event.kind]=int(kinds.get(event.kind,0))+1
   var out:=FileAccess.open("res://output/cpu005-demo-"+("movie" if recording else "live")+".json",FileAccess.WRITE)
   out.store_string(JSON.stringify({"winner":match_progress.winner,"round_wins":match_progress.round_wins,"elapsed_seconds":elapsed,"seed":cpu_seed,"difficulty":cpu_difficulty,"outcomes":kinds,"recording":recording,"test_player":"rush_high; synthetic input; movie clock injected only when recording"},"  "))
   if "--cpu-diagnostics" in OS.get_cmdline_user_args():
    var trace:=FileAccess.open("res://output/cpu005-attempts.json",FileAccess.WRITE)
    trace.store_string(JSON.stringify(cpu_attempts,"  "))
   print("CPU DEMO COMPLETE ",kinds," winner=",match_progress.winner," rounds=",match_progress.round_wins)
   audio.stop()
   get_tree().quit(0 if int(kinds.get("HIT",0))>=6 and int(kinds.get("BLOCK",0))>0 else 1)
 if elapsed>240:
  push_error("CPU demo timed out: "+mode)
  get_tree().quit(1)
