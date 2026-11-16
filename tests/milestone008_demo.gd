extends "res://scripts/main.gd"
# Legal scripted PvP actions; no score, position, selection or phase overrides.
var demo_raw:=0.0
var elapsed:=0.0
var offline:=false
var keys_sent: Dictionary={}
var shots: Dictionary={}
var intents: Array[Dictionary]=[]
var seen_cue: float=-INF
var result_since: float=-INF
var round_results: int=0
var seen_result_round: int=-1
func _ready() -> void:
 offline="--record008" in OS.get_cmdline_user_args()
 if offline:conductor.clock_override=func():return demo_raw
 preferences_path=""
 super._ready()
 # This demonstration covers menus/match; the separate UI movie covers the CTA.
 open_main_menu()
 intro_music_pending=false
 game_mode="pvp"
 preferences.values.game_mode="pvp"
 stage_preference="stage_03"
 preferences.values.stage="stage_03"
 max_anticipation_phrases=1
 if offline:
  audio.events.ui_clock_source=conductor.now
  audio.enabled=DisplayServer.get_name()!="headless"
  audio.play_track("menu",conductor.now(),true)
 conductor.beat_changed.connect(plan)
func key(code: int) -> void:MenuTestInput.key(self,code)
func once(at: float,name: String,codes: Array) -> void:
 if elapsed>=at and not keys_sent.has(name):
  keys_sent[name]=true
  for code in codes:key(code)
func plan(beat: int,phrase: int) -> void:
 if mode!="combat":return
 var public: Dictionary=public_cpu_observation()
 if beat<=3 and public.positions[1]-public.positions[0]>public.reach:
  for p in range(2):intents.append({"at":public.beat_time+0.015,"player":p,"action":"right" if p==0 else "left","execute":false})
 if beat==1:
  var attacker: int=public.initiative
  var height: int=phrase%3
  for p in range(2):
   var chosen: int=height if p==attacker or phrase in [1,2] else (height+1)%3
   var forward: String="right" if public.positions[1-p]>public.positions[p] else "left"
   var delay: float=0.10 if p!=attacker and phrase==1 else 0.0
   intents.append({"at":public.beat_time+3*public.duration+delay,"player":p,"action":["high",forward,"low"][chosen],"execute":true})
 intents.sort_custom(func(a,b):return a.at<b.at)
func action(intent: Dictionary) -> void:
 if bool(intent.get("race",false)):
  if mode not in ["standoff","race"]:return
 elif mode!="combat":return
 var p: int=intent.player
 var name: String=intent.action
 var at: float=intent.at
 submit_action(p,name,true,at)
 if intent.execute:submit_action(p,"execute",true,at)
 submit_action(p,name,false,at)
 if intent.execute:submit_action(p,"execute",false,at)
func capture(label: String) -> void:
 if shots.has(label) or DisplayServer.get_name()=="headless":return
 shots[label]=true
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://output/008-"+label+".png")
func _process(delta: float) -> void:
 elapsed+=delta
 if offline:demo_raw+=delta
 super._process(delta)
 once(0.4,"navigate",[KEY_DOWN])
 once(0.7,"confirm",[KEY_ENTER]) # Options
 once(1.0,"back",[KEY_ESCAPE])
 once(1.4,"start",[KEY_ENTER,KEY_DOWN,KEY_DOWN,KEY_DOWN,KEY_DOWN,KEY_DOWN,KEY_ENTER])
 if mode=="standoff" and cue!=seen_cue:
  seen_cue=cue
  intents.clear()
  intents.append({"at":cue+0.12,"player":0,"action":"execute","execute":false,"race":true})
  intents.append({"at":cue+0.16,"player":1,"action":"execute","execute":false,"race":true})
  capture("countdown-round%d" % match_progress.round_number)
 if mode in ["standoff","race","combat"]:
  while not intents.is_empty() and float(intents[0].at)<=game_time():action(intents.pop_front())
 if mode=="pickup":capture("pickup")
 if mode=="combat" and not bout.last_event.is_empty() and impact_effect.visible:capture(str(bout.last_event.kind).to_lower())
 if mode=="round_win":
  if seen_result_round!=match_progress.round_number:
   seen_result_round=match_progress.round_number
   round_results+=1
   capture("round-result")
  intents.clear()
 if mode=="standoff" and match_progress.round_number==2:capture("automatic-round-two")
 if mode=="match_win":
  capture("match-result")
  if is_inf(result_since):result_since=elapsed
  if elapsed-result_since>=2.0:
   var kinds: Dictionary={}
   for row in completed_exchanges:kinds[row.kind]=int(kinds.get(row.kind,0))+1
   var success:=match_progress.winner>=0 and round_results>=1 and kinds.has("HIT") and kinds.has("BLOCK") and kinds.has("PARRY")
   var report:=FileAccess.open("res://output/milestone008-demo.json",FileAccess.WRITE)
   report.store_string(JSON.stringify({"success":success,"elapsed":elapsed,"outcomes":kinds,"wins":match_progress.round_wins,"ordinary_results":round_results,"audio_events":audio.events.trace,"result_music":audio.event_log,"clock":"injected offline" if offline else "production","inputs":"scripted actions through submit_action; no physical keyboard or perceptual listening claim"},"  "))
   print("MILESTONE 008 DEMO COMPLETE success=",success," outcomes=",kinds," scores=",match_progress.round_wins)
   audio.stop()
   get_tree().quit(0 if success else 1)
 if elapsed>120:
  push_error("008 demo timed out "+mode)
  get_tree().quit(1)
