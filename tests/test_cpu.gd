extends SceneTree
var game: Node2D
var time := 0.0
var checks := 0
var failures := 0
var human := RhythmTestPlayer.new()
var report: Array[Dictionary] = []
var testing_frame := 1.0/60.0
var hook_enabled := false
func _initialize() -> void:call_deferred("run")
func check(ok: bool, message: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(message)
func press(action: String,down: bool=true) -> void:
 var event:=InputEventAction.new()
 event.action="p1_"+action
 event.pressed=down
 game._unhandled_input(event)
func keyboard(code: int) -> void:
 var event:=InputEventKey.new()
 event.keycode=code
 event.pressed=true
 game._unhandled_input(event)
 event=event.duplicate()
 event.pressed=false
 game._unhandled_input(event)
func on_boundary(_beat: int,_phrase: int) -> void:
 if hook_enabled and game.mode=="combat":human.plan_boundary(game.public_cpu_observation())
func start_human_round() -> void:
 human.start_round(game.cue)
func dispatch_human(intent: Dictionary) -> void:
 if intent.kind=="race" and game.mode not in ["standoff","race"]:return
 if intent.kind!="race" and game.mode!="combat":return
 press(str(intent.action))
 if intent.kind=="combat":
  press("execute")
  press("execute",false)
 press(str(intent.action),false)
func simulate(level: String,seed_value: int,strategy: String,frame: float=1.0/60.0,tempo: int=120) -> Dictionary:
 game.cpu_difficulty=level
 game.cpu_seed=seed_value
 game.preferences.values.difficulty=level
 game.preferences.values.game_mode="cpu"
 human.configure(strategy,seed_value+100000)
 game.mode="menu"
 time=0.0
 MenuTestInput.start(game)
 start_human_round()
 var started:=time
 var last_hit:=time
 var last_hits: Array[int]=[0,0]
 var stalls:=0
 var previous_mode: String=game.mode
 var played_rounds:=1
 var movement_steps:=0
 var max_distance:=0.0
 var min_distance:=999.0
 var tempo_round: int=-1
 var frames:=0
 var states_seen: Dictionary={}
 while game.mode!="match_win" and time-started<360.0:
  if game.mode=="finishing":
   time+=frame
   game._process(frame)
   continue
  if game.mode=="round_win":
   keyboard(KEY_ENTER)
   start_human_round()
   played_rounds+=1
  if game.mode=="combat" and tempo_round!=game.match_progress.round_number:
   tempo_round=game.match_progress.round_number
   game.conductor.schedule_tempo(tempo)
  # Human attempts are delivered through the normal InputMap action event handler.
  var next:=minf(time+frame,human.next_time())
  if next<=time:next=time
  var old_position: float=game.bout.positions[1]
  time=next
  game._process(frame)
  if previous_mode in ["standoff","race"] and game.mode=="standoff" and human.queue.is_empty():start_human_round()
  while human.next_time()<=time+0.000000001:dispatch_human(human.pop_intent())
  game._process(0.0)
  if old_position!=game.bout.positions[1]:movement_steps+=1
  if game.mode=="combat":
   max_distance=maxf(max_distance,game.bout.positions[1]-game.bout.positions[0])
   min_distance=minf(min_distance,game.bout.positions[1]-game.bout.positions[0])
   states_seen[game.cpu.state]=true
   if game.bout.hits!=last_hits:
    last_hits=game.bout.hits.duplicate()
    last_hit=time
   elif time-last_hit>60:
    stalls+=1
    last_hit=time
   check(game.bout.positions[0]>=Bout.MIN_X and game.bout.positions[1]<=Bout.MAX_X and game.bout.positions[1]-game.bout.positions[0]>=Bout.GAP-0.001,"CPU stays inside arena and separation")
  previous_mode=game.mode
  frames+=1
  if frames%900==0:await process_frame
 var attempts: Array=game.cpu_attempts.duplicate(true)
 var kinds: Dictionary={}
 var heights: Array[int]=[0,0,0]
 var action_counts: Dictionary={"move":0,"combat":0,"valid_move":0,"valid_combat":0,"perfect_move":0,"perfect_combat":0}
 for attempt in attempts:
  if attempt.kind=="race":continue
  action_counts[attempt.kind]+=1
  if attempt.grade!="miss":action_counts["valid_"+str(attempt.kind)]+=1
  if attempt.grade=="perfect":action_counts["perfect_"+str(attempt.kind)]+=1
  if attempt.kind=="combat" and attempt.role=="attack":heights[int(attempt.height)]+=1
 var observed_bpms: Dictionary={}
 for attempt in attempts:observed_bpms[attempt.bpm]=true
 var cpu_defense_opportunities:=0
 var cpu_blocks:=0
 var cpu_parries:=0
 var race_initiative: Array[int]=[]
 for event in game.completed_exchanges:
  var kind: String=event.kind
  kinds[kind]=int(kinds.get(kind,0))+1
  if int(event.defender)==1 and kind in ["HIT","BLOCK","PARRY"]:cpu_defense_opportunities+=1
  if int(event.defender)==1 and kind=="BLOCK":cpu_blocks+=1
  if int(event.defender)==1 and kind=="PARRY":cpu_parries+=1
 if level=="easy" and seed_value==7000:
  var diagnostic:=FileAccess.open("res://output/cpu005-easy-attempts.json",FileAccess.WRITE)
  diagnostic.store_string(JSON.stringify(attempts,"  "))
 var decisions: Array=game.cpu.decisions.duplicate(true)
 check(game.mode=="match_win","Seeded CPU match completes: %s/%d/%s" % [level,seed_value,strategy])
 check(game.match_progress.round_wins.max()==2,"CPU match uses normal best-of-three scoring")
 return {"difficulty":level,"seed":seed_value,"strategy":strategy,"winner":game.match_progress.winner,"duration":time-started,"active_clock_duration":time-started,"rounds":played_rounds,"stalls":stalls,"timed_out":game.mode!="match_win","timing":action_counts,"attack_heights":heights,"bpms":observed_bpms.keys(),"cpu_defense_opportunities":cpu_defense_opportunities,"cpu_blocks":cpu_blocks,"cpu_parries":cpu_parries,"outcomes":kinds,"movement_changes":movement_steps,"distance_min":min_distance,"distance_max":max_distance,"states":states_seen.keys(),"decisions":decisions,"final_hits":game.bout.hits.duplicate()}
func run() -> void:
 game=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 game.preferences_path=""
 game.conductor.clock_override=func():return time
 root.add_child(game)
 game.open_main_menu() # CPU fixtures bypass the independently tested intro.
 game.preferences.values.game_mode=game.game_mode
 game.set_process(false)
 game.audio.stop()
 check(game.game_mode=="cpu" and game.cpu_difficulty=="normal","Default starts Player vs CPU Normal")
 keyboard(KEY_ENTER)
 keyboard(KEY_DOWN)
 keyboard(KEY_LEFT)
 check(game.cpu_difficulty=="easy","Setup selects Easy")
 keyboard(KEY_RIGHT)
 keyboard(KEY_RIGHT)
 check(game.cpu_difficulty=="hard","Setup selects Hard")
 keyboard(KEY_UP)
 keyboard(KEY_RIGHT)
 check(game.game_mode=="pvp","Setup selects PvP")
 keyboard(KEY_RIGHT)
 check(game.game_mode=="cpu","Setup returns to CPU")
 keyboard(KEY_F3)
 check(game.debug_visible,"F3 CPU diagnostics")
 keyboard(KEY_F4)
 check(game.stage.selected==1,"Pre-match developer stage preview retained")
 game.debug_visible=false
 var public: Dictionary=game.public_cpu_observation()
 var original_public:=public.duplicate(true)
 game.selected.assign([2,0])
 game.controls[0].pending_execute=123.0
 check(game.public_cpu_observation()==original_public,"Changing hidden current input cannot change CPU observation")
 game.selected.assign([-1,-1])
 game.controls[0].reset()
 var fair:=CpuController.new()
 fair.configure("hard",90)
 var fixture: Dictionary={"phrase":0,"beat":1,"beat_time":10.0,"duration":0.5,"positions":[140.0,180.0],"initiative":0,"latency_ms":0.0,"reach":53.0}
 fair.plan_boundary(fixture)
 var original_commit:=fair.commitment.duplicate(true)
 fair.observe_result({"attacker":0,"height":0,"kind":"HIT","reason":""},"previous")
 fixture.beat=2
 fixture.beat_time=10.5
 fair.plan_boundary(fixture)
 check(fair.commitment==original_commit,"Defence cannot revise committed choice on new information")
 for forbidden in ["selected","selections","errors","controls","pending_execute","pressed_at"]:check(not public.has(forbidden),"No hidden input in CPU public API")
 # Empirical raw timing calibration: both timing classifications at every tempo.
 for level in ["easy","normal","hard"]:
  var controller:=CpuController.new()
  controller.configure(level,12345)
  var valid_move:=0
  var valid_combat:=0
  var early:=0
  var late:=0
  for n in range(6000):
   var movement_error:=controller.sample_offset("move")
   var combat_error:=controller.sample_offset("combat")
   valid_move+=int(absf(movement_error)<=160)
   valid_combat+=int(absf(combat_error)<=140)
   early+=int(movement_error<0)
   late+=int(movement_error>0)
  check(absf(float(valid_move)/6000-float(controller.parameters.rhythm_success))<0.025,"Measured movement distribution matches configured target")
  check(absf(float(valid_combat)/6000-float(controller.parameters.rhythm_success))<0.025,"Measured combat distribution matches configured target")
  check(early>0 and late>0 and valid_combat<6000,"Early, late and miss attempts mandatory")
 hook_enabled=true
 game.conductor.beat_changed.connect(on_boundary)
 var match_count:=100
 if "--quick-cpu" in OS.get_cmdline_user_args():match_count=2
 for level in ["easy","normal","hard"]:
  for strategy in ["rush_high","balanced","guard_high"]:
   for index in range(match_count):
    var result:=await simulate(level,7000+index,strategy)
    result.erase("decisions")
    report.append(result)
   print("CPU SIM ",level,"/",strategy," done")
 var wins: Array[int]=[0,0]
 var heights: Array[int]=[0,0,0]
 var blocks:=0
 var parries:=0
 var retreat_seen:=false
 for match_result in report:
  if match_result.winner in [0,1]:wins[int(match_result.winner)]+=1
  for height in range(3):heights[height]+=int(match_result.attack_heights[height])
  blocks+=int(match_result.cpu_blocks)
  parries+=int(match_result.cpu_parries)
  retreat_seen=retreat_seen or "RETREAT" in match_result.states
 check(wins[0]>0 and wins[1]>0,"Both human strategy and CPU can win real matches")
 check(heights.min()>0,"CPU attacks use all three heights")
 check(blocks>0 and parries>0,"CPU blocks and perfect parries resolve legally")
 check(retreat_seen,"CPU retreats without becoming trapped in a retreat loop")
 # Same seed/same strategy, different render-step budgets: scheduler must agree exactly.
 var a:=await simulate("hard",15551,"balanced",1.0/30.0)
 var b:=await simulate("hard",15551,"balanced",1.0/120.0)
 var normalized_a: Array=[]
 var normalized_b: Array=[]
 for sequence in [a.decisions,b.decisions]:
  var normalized: Array=[]
  for intent in sequence:
   var entry: Dictionary={}
   for field in ["kind","action","height","role","offset_ms","beat"]:entry[field]=intent[field]
   normalized.append(entry)
  if normalized_a.is_empty():normalized_a=normalized
  else:normalized_b=normalized
 check(normalized_a==normalized_b and a.winner==b.winner,"Fixed-seed relative timings, decisions and outcome independent of frame rate")
 if normalized_a!=normalized_b:
  var replay:=FileAccess.open("res://output/cpu005-replay-diff.json",FileAccess.WRITE)
  replay.store_string(JSON.stringify({"a":normalized_a,"b":normalized_b},"  "))
 for tempo in [140,160]:
  var probe:=await simulate("hard",8500,"balanced",1.0/60.0,tempo)
  check(tempo in probe.bpms,"CPU legal attempts exercised at %d BPM" % tempo)
 # Replay via Enter clears match state but retains selected difficulty/seed.
 keyboard(KEY_ENTER)
 check(game.mode=="standoff" and game.match_progress.round_wins==[0,0] and game.cpu.history==[0,0,0],"Rematch resets CPU learning and score")
 var output:=FileAccess.open("res://output/cpu005-simulation.json",FileAccess.WRITE)
 output.store_string(JSON.stringify({"checks":checks,"failures":failures,"matches":report},"  "))
 print("CPU TESTS: %d checks, %d failures; %d measured matches" % [checks,failures,report.size()])
 hook_enabled=false
 game.audio.stop()
 game.conductor.clock_override=Callable()
 game.queue_free()
 quit(1 if failures else 0)
