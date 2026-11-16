extends Node2D
var flow:=ArcadeFlow.new()
var preferences:=UserPreferences.new()
var preferences_path: String="user://preferences.cfg"
var selected_bpm: int=120
var stage_preference: String="stage_01"
var stage_rng:=RandomNumberGenerator.new()
var match_serial: int=0
var paused: bool=false
var ui_held: Dictionary={}
var transition_until: float=INF
var result_handled: bool=false
var movement_stun: Array[String]=["",""]
var stun_time: Array[float]=[-INF,-INF]
var game_mode: String = "cpu"
var cpu_difficulty: String = "normal"
var cpu_seed: int = 5005
var cpu := CpuController.new()
var match_rng := RandomNumberGenerator.new()
var cpu_attempts: Array[Dictionary] = []
var completed_exchanges: Array[Dictionary] = []
var cpu_debug_label := Label.new()
var advancing_timeline := false
var stage := StageBackground.new()
var ground_sticks := GroundSticks.new()
var impact_effect := ImpactEffect.new()
var movement_perfect_ms: float = 90.0
var movement_good_ms: float = 160.0
var step_seconds: float = 0.16
var step_origins: Array[float] = [100.0,220.0]
var step_started: Array[float] = [-INF,-INF]
var conductor := RhythmConductor.new()
var bout := Bout.new()
var audio := AudioDirector.new()
var match_progress := MatchProgress.new()
var hud_layer := CanvasLayer.new()
var hud := ArcadeHUD.new()
var outcome_until: float = -INF
var fighters: Array[Fighter] = []
var combat_debug := CombatDebugOverlay.new()
var mode: String = "menu"
var cue: float = 0.0
var race_deadline: float = 0.0
var anticipation_phrases: int = 1
var max_anticipation_phrases: int = 3
var cue_style: String = "snare"
var race_timeout: float = 2.0
var phrase_resolved: bool = false
var exchange_phrase: int = 0
var debug_visible: bool = false
var help_visible: bool = false
var status: String = ""
var label := Label.new()
var detail := Label.new()
var input_feedback_label := Label.new()
var previous_bpm: int = 120
var settings: Dictionary = {}
var selected: Array[int] = [-1, -1]
var controls: Array[CombatInput] = [CombatInput.new(), CombatInput.new()]
var tie_priority: int = 0
var last_error: Array[float] = [INF, INF]
var pose_until: float = 0.0
var pose_until_by_player: Array[float] = [0.0, 0.0]
var click_player := AudioStreamPlayer.new()
var click_stream: AudioStreamWAV
var metronome_enabled: bool = true

# Bounded development trace. _input observes delivery before GUI/unhandled routing.
var movement_trace: Array[Dictionary] = []
var last_keys: Array[String] = ["none", "none"]
var accepted_until: Array[float] = [0.0, 0.0]
var rendered_step_time: Array[float] = [-INF, -INF]
var raw_event_count: int = 0
var handled_event_count: int = 0

func trace_movement(stage: String, player: int, extra: Dictionary = {}) -> void:
 var row := {"stage":stage, "player":player+1, "time":conductor.now(),
  "phase":mode, "beat":conductor.beat, "phrase":conductor.phrase,
  "permitted":mode=="combat", "pending":controls[player].pending_move,
  "queued":controls[player].queued, "logical_x":bout.positions[player],
  "rendered_x":fighters[player].position.x if fighters.size()>player else 0.0,
  "feedback":controls[player].input_feedback, "step":controls[player].step_feedback}
 row.merge(extra,true)
 movement_trace.append(row)
 if movement_trace.size()>2048:movement_trace.pop_front()

func _input(event: InputEvent) -> void:
 if not event is InputEventKey:return
 for player in range(2):
  for action in ["left", "right"]:
   if event.is_action("p%d_%s" % [player+1,action]):
    raw_event_count += 1
    last_keys[player] = "%s %s" % [OS.get_keycode_string(event.physical_keycode),"down" if event.pressed else "up"]
    trace_movement("raw",player,{"event_id":event.get_instance_id(),"keycode":event.keycode,
     "physical_keycode":event.physical_keycode,"pressed":event.pressed,"echo":event.echo,
     "action":"p%d_%s" % [player+1,action], "window_focused":DisplayServer.window_is_focused(),
     "gui_focus":str(get_viewport().gui_get_focus_owner())})

func _exit_tree() -> void:
 if "--movement-trace" in OS.get_cmdline_user_args():
  var file := FileAccess.open("res://output/movement-trace.json",FileAccess.WRITE)
  if file:file.store_string(JSON.stringify(movement_trace,"  "))

func _ready() -> void:
 Bindings.install()
 var cpu_config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/cpu.json"))
 cpu_difficulty=str(cpu_config.default_difficulty)
 cpu_seed=int(cpu_config.default_seed)
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--cpu-seed="):cpu_seed=int(argument.get_slice("=",1))
  if argument.begins_with("--cpu-difficulty="):cpu_difficulty=argument.get_slice("=",1)
 cpu.configure(cpu_difficulty,cpu_seed)
 cpu_difficulty=cpu.difficulty
 cpu_debug_label.position=Vector2(5,88)
 cpu_debug_label.z_index=102
 cpu_debug_label.add_theme_font_size_override("font_size",7)
 add_child(cpu_debug_label)
 stage.z_index = -1
 add_child(stage)
 add_child(ground_sticks)
 impact_effect.clock_source = conductor.now
 add_child(impact_effect)
 flow.setup(self)
 var config := FileAccess.open("res://data/combat/settings.json", FileAccess.READ)
 if config:
  settings = JSON.parse_string(config.get_as_text())
 movement_good_ms = clampf(float(settings.get("movement_good_ms",160)),1.0,187.0)
 movement_perfect_ms = clampf(float(settings.get("movement_perfect_ms",90)),0.0,movement_good_ms)
 step_seconds = clampf(float(settings.get("step_seconds",0.16)),0.04,0.25)
 match_progress.reset(int(settings.get("match_best_of",3)))
 bout.stick_reach = float(settings.get("stick_reach", 44.0))
 conductor.perfect_ms = float(settings.get("perfect_ms", 70.0))
 conductor.good_ms = float(settings.get("good_ms", 140.0))
 for control in controls:
  control.combination_ms = float(settings.get("combination_ms", 100.0))
 conductor.latency_ms = float(settings.get("latency_ms", 0.0))
 max_anticipation_phrases = int(settings.get("max_anticipation_phrases", 3))
 race_timeout = float(settings.get("race_timeout_seconds", 2.0))
 cue_style = str(settings.get("cue_style", "snare"))
 audio.clock_source = conductor.now
 audio.enabled = not conductor.clock_override.is_valid()
 audio.latency_ms = float(settings.get("audio_latency_ms", 0.0))
 add_child(audio)
 metronome_enabled = not audio.tracks.has("120")
 add_child(click_player)
 click_stream = AudioStreamWAV.new()
 click_stream.format = AudioStreamWAV.FORMAT_16_BITS
 click_stream.mix_rate = 22050
 var samples := PackedByteArray()
 samples.resize(2205 * 2)
 for n in range(2205):
  var value := int(sin(n * TAU * 660.0 / 22050.0) * 7000.0 * (1.0 - n / 2205.0))
  samples.encode_s16(n * 2, value)
 click_stream.data = samples
 click_player.stream = click_stream
 for player in range(2):
  var fighter := Fighter.new()
  fighter.clock_source=conductor.now
  fighter.asset_config = "res://data/animations/fighter_0%d.json" % (player + 1)
  fighter.color = Color("f3ba55") if player == 0 else Color("66c9c8")
  add_child(fighter)
  fighter.face(1 if player == 0 else -1)
  fighter.position = Vector2(bout.positions[player], 150)
  fighters.append(fighter)
 label.position = Vector2(8, 5)
 label.add_theme_font_size_override("font_size", 12)
 add_child(label)
 detail.position = Vector2(8, 23)
 detail.add_theme_font_size_override("font_size", 8)
 add_child(detail)
 input_feedback_label.position = Vector2(4, 151)
 input_feedback_label.z_index = 101
 input_feedback_label.add_theme_font_size_override("font_size", 7)
 input_feedback_label.add_theme_constant_override("line_spacing", -2)
 add_child(input_feedback_label)
 for diagnostic_label in [label,detail,input_feedback_label,cpu_debug_label]:
  diagnostic_label.add_theme_font_override("font",ArcadeHUD.FONT)
  diagnostic_label.add_theme_font_size_override("font_size",8)
  diagnostic_label.add_theme_constant_override("line_spacing",0)
 label.position=Vector2(4,3)
 detail.position=Vector2(4,15)
 cpu_debug_label.position=Vector2(4,69)
 input_feedback_label.position=Vector2(4,143)
 combat_debug.game = self
 combat_debug.z_index = 100
 combat_debug.visible = debug_visible
 add_child(combat_debug)
 hud_layer.layer = 10
 add_child(hud_layer)
 hud_layer.add_child(hud)
 hud_layer.add_child(flow.view)
 if conductor.clock_override.is_valid():preferences_path=""
 preferences.path=preferences_path
 var stage_ids: Array=[]
 for entry in stage.entries:stage_ids.append(entry.id)
 preferences.load_values(stage_ids)
 apply_preferences(not preferences_path.is_empty())
 # Explicit test/replay CLI overrides take precedence over saved defaults.
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--cpu-difficulty="):
   var level:=argument.get_slice("=",1).to_lower()
   if level in ["easy","normal","hard"]:
    cpu_difficulty=level
    preferences.values.difficulty=level
 cpu.configure(cpu_difficulty,cpu_seed)
 flow.root("title")
 conductor.beat_changed.connect(on_beat)
 conductor.phrase_changed.connect(on_phrase)
 audio.play_track("menu", conductor.now())
 refresh()

func play_click(force: bool = false) -> void:
 if (force or metronome_enabled) and DisplayServer.get_name() != "headless":
  click_player.play()

func begin() -> void:
 if paused:set_paused(false)
 result_handled=false
 transition_until=INF
 ui_held.clear()
 flow.view.visible=false
 match_serial+=1
 if stage_preference=="random" and not stage.entries.is_empty():
  stage_rng.seed=cpu_seed^0x53544147^match_serial
  stage.select_stage(stage_rng.randi_range(0,stage.entries.size()-1))
 else:
  for index in range(stage.entries.size()):
   if stage.entries[index].id==stage_preference:stage.select_stage(index)
 cpu.configure(cpu_difficulty,cpu_seed)
 cpu_difficulty=cpu.difficulty
 match_rng.seed=cpu_seed^0x534e4c
 cpu_attempts.clear()
 completed_exchanges.clear()
 match_progress.reset(int(settings.get("match_best_of",3)))
 _begin_round()

func next_round() -> void:
 if match_progress.next_round():
  _begin_round()

func _begin_round() -> void:
 impact_effect.clear()
 ground_sticks.set_collected(false, false)
 movement_stun=["",""]
 stun_time=[-INF,-INF]
 transition_until=INF
 phrase_resolved = false
 exchange_phrase = 0
 outcome_until = -INF
 bout = Bout.new()
 bout.stick_reach = float(settings.get("stick_reach", 44.0))
 exchange_phrase = 0
 bout.escalation_threshold = int(settings.get("escalation_threshold", 3))
 bout.tie_priority = tie_priority
 selected = [-1, -1]
 for player in range(2):
  controls[player].reset()
  # Seed physical directions already held when Enter starts/rematches the bout.
  # Execute/pending actions are always cleared and cannot auto-fire from the race.
  for action in ["left", "right", "high", "low"]:
   if not (game_mode=="cpu" and player==1) and Input.is_action_pressed("p%d_%s" % [player+1, action]):
    controls[player].feed(action, true, conductor.now(), facing(player), false)
    controls[player].input_feedback = "REJECT movement phase; held tracked"
 step_started = [-INF,-INF]
 pose_until_by_player = [0.0, 0.0]
 last_error = [INF, INF]
 conductor.start(-1,selected_bpm)
 anticipation_phrases = match_rng.randi_range(1,max_anticipation_phrases) if game_mode=="cpu" else randi_range(1, max_anticipation_phrases)
 cue = conductor.epoch+conductor.duration()*(anticipation_phrases*4+3)
 race_deadline = cue + race_timeout
 mode = "standoff"
 if game_mode=="cpu":cpu.start_round(cue)
 status = "Wait for GO. Early press forfeits the race."
 previous_bpm = selected_bpm
 audio.music.pitch_scale=float(selected_bpm)/120.0
 audio.play_track("standoff", conductor.epoch, true)
 for fighter in fighters:
  fighter.reset_visual()
  fighter.set_pose("standoff_anticipation")
 refresh()

func _process(delta: float) -> void:
 if paused:
  refresh()
  return
 var at := game_time()
 if mode in ["standoff", "race", "combat"]:
  advance_timeline(at)
 if mode == "standoff" and at >= cue:
  mode = "race"
  status = "GO! Grab your stick"
  if cue_style == "snare":
   play_click(true)
  else:
   click_player.stop()
   audio.music.stop()
  audio.sound("race")
  for player in range(2):
   if not bout.false_starts[player]:
    fighters[player].set_pose("race_launch")
 if mode == "race":
  var both := bout.reactions[0] >= 0 and bout.reactions[1] >= 0
  var forfeited := bout.false_starts[0] or bout.false_starts[1]
  if both or forfeited or at >= race_deadline:
   var result := bout.resolve_race()
   tie_priority = bout.tie_priority
   if result < 0:
    _begin_round()
    status = "No valid race: new three-count. Wait for GO."
   else:
    mode = "pickup"
    status = "P%d takes initiative. Both fighters collect sticks." % (result + 1)
    for fighter in fighters:
     fighter.set_pose("stick_pickup")
    var phrase_seconds: float=conductor.duration()*4
    var next_boundary: float = conductor.epoch+ceil((at+conductor.duration()*1.5-conductor.epoch)/phrase_seconds)*phrase_seconds
    conductor.start(next_boundary,selected_bpm)
    phrase_resolved = false
 if mode == "pickup" and at >= conductor.epoch:
  mode = "combat"
  audio.music.pitch_scale=1.0
  audio.play_track(str(selected_bpm), conductor.epoch)
  advance_timeline(at)
 if mode=="finishing" and at>=transition_until:complete_round_transition()
 expire_stuns(at)
 if mode=="combat":
  freeze_combat_positions(at)
 if mode == "combat" and not phrase_resolved and at > conductor.action_time() + (conductor.good_ms + controls[0].combination_ms + maxf(0.0, conductor.latency_ms)) / 1000.0:
  resolve_exchange()
 sync_ground_sticks()
 for player in range(2):
  fighters[player].face(facing(player))
  var target_x := bout.positions[player]
  if mode == "pickup" or (mode == "race" and bout.reactions[player] >= 0):
   target_x = 138.0 if player == 0 else 182.0
   if mode == "race":
    fighters[player].set_pose("running")
  if mode=="combat" and at-step_started[player]<=step_seconds:
   var progress := clampf((at-step_started[player])/step_seconds,0,1)
   fighters[player].position = Vector2(lerpf(step_origins[player],target_x,progress),150)
  elif mode=="combat":
   fighters[player].position = Vector2(target_x,150)
  else:
   fighters[player].position = fighters[player].position.lerp(Vector2(target_x, 150), minf(1.0, delta * 16))
  if controls[player].last_step_time != rendered_step_time[player] and absf(fighters[player].position.x-bout.positions[player])<1.0:
   rendered_step_time[player] = controls[player].last_step_time
   trace_movement("rendered",player,{"execution_time":controls[player].last_step_time})
  fighters[player].sync_hurtbox(Vector2(bout.positions[player], Bout.GROUND_Y))
  if mode=="combat" and fighters[player].pose in ["forward_step","backward_step"] and at-step_started[player]>=step_seconds:
   fighters[player].request_pose("combat_idle",0,0)
  if mode == "combat" and at > pose_until_by_player[player]:
   fighters[player].request_pose("combat_idle",0,0)
 combat_debug.visible = debug_visible
 combat_debug.queue_redraw()
 refresh()
 queue_redraw()

func public_cpu_observation() -> Dictionary:
 # Intentionally no selected[], controls, errors, input buffers, or current attack.
 return {"positions":bout.positions.duplicate(),"initiative":bout.initiative,
  "energy":[bout.energy_remaining(0),bout.energy_remaining(1)],
  "beat":conductor.beat,"phrase":conductor.phrase,"beat_time":conductor.beat_time,
  "duration":conductor.duration(),"latency_ms":conductor.latency_ms,
  "reach":bout.stick_reach+Bout.HURTBOX.size.x/2.0}

func dispatch_cpu(intent: Dictionary) -> void:
 var kind: String=intent.kind
 if kind=="race" and mode not in ["standoff","race"]:return
 if kind!="race" and mode!="combat":return
 var at: float=intent.at
 submit_action(1,str(intent.action),true,at,"cpu")
 if kind=="combat":
  submit_action(1,"execute",true,at,"cpu")
  submit_action(1,"execute",false,at,"cpu")
 submit_action(1,str(intent.action),false,at,"cpu")
 var grade: String=controls[1].movement_grade if kind=="move" else conductor.grade(bout.errors[1])
 if kind=="race":grade="false start" if bout.false_starts[1] else "reaction"
 cpu.result=grade
 var sample:=intent.duplicate(true)
 sample["grade"]=grade
 sample["difficulty"]=cpu_difficulty
 sample["bpm"]=conductor.bpm
 sample["round"]=match_progress.round_number
 sample["position"]=bout.positions[1]
 sample["movement_error_ms"]=controls[1].movement_error_ms
 sample["movement_target"]=controls[1].movement_target.duplicate()
 sample["input_feedback"]=controls[1].input_feedback
 sample["movement_executed"]=controls[1].movement_executed if kind=="move" else false
 cpu_attempts.append(sample)
 if cpu_attempts.size()>4096:cpu_attempts.pop_front()

func advance_timeline(at: float) -> void:
 if paused:return
 if game_mode!="cpu":
  conductor.update(at)
  return
 if advancing_timeline:return
 advancing_timeline=true
 # Merge scheduled input and beat boundaries chronologically, even on slow frames.
 # CPU intents were committed in advance; neither gameplay nor decisions use render delta.
 while mode in ["standoff","race","combat"]:
  var boundary := INF
  if mode=="combat" and conductor.started:
   boundary=conductor.epoch if conductor.beat==0 else conductor.beat_time+conductor.duration()
  var event_time := cpu.next_time()
  if minf(boundary,event_time)>at:break
  if boundary<=event_time:
   conductor.update(boundary)
  else:
   conductor.update(event_time)
   dispatch_cpu(cpu.pop_intent())
 conductor.update(at)
 advancing_timeline=false

func game_time() -> float:
 if mode == "combat" and not conductor.clock_override.is_valid() and audio.tracks.has(audio.active) and audio.music.playing:
  return audio.anchor + maxf(0.0, audio.audio_time())
 return conductor.now()

func on_phrase(_phrase: int) -> void:
 if mode != "combat":
  return
 # Resolve an overdue exchange before clearing it if rendering stalled.
 if not phrase_resolved:
  resolve_exchange()
 if mode != "combat":
  return
 phrase_resolved = false
 selected = [-1, -1]
 for control in controls:
  control.pending_execute = -INF
 if previous_bpm != conductor.bpm:
  audio.play_track(str(conductor.bpm), conductor.phrase_start)
  previous_bpm = conductor.bpm

func on_beat(beat: int, _phrase: int) -> void:
 if mode == "standoff":
  # Earlier anticipation phrases continue; only the final fourth beat cuts off.
  if beat <= 3 or conductor.now() < cue - 0.01:
   play_click(true)
 elif mode == "combat":
  click_player.pitch_scale = 1.5 if beat == 4 else 1.0
  play_click()
  exchange_phrase = _phrase
  expire_stuns(conductor.beat_time)
  apply_movement(beat,_phrase,conductor.beat_time)
  if game_mode=="cpu":cpu.plan_boundary(public_cpu_observation())
  if beat==4:
   for player in range(2):present_combat(player)

func freeze_combat_positions(at: float) -> void:
 # Include legal late movement before any range decision, while retaining combat's window.
 if conductor.beat==4 and at>conductor.action_time()+(movement_good_ms+maxf(0,conductor.latency_ms))/1000.0:
  bout.capture_impact(conductor.phrase,conductor.action_time())

func apply_movement(beat: int, phrase: int, at: float) -> void:
 var before := bout.positions.duplicate()
 var requested: Array[int] = [0,0]
 for player in range(2):
  controls[player].last_step_evaluated=at
  requested[player]=controls[player].step(beat,phrase)
  if movement_stun[player]=="%d:%d" % [phrase,beat]:
   if requested[player]!=0:
    controls[player].step_feedback="STUN: ONE MOVE LOST"
    controls[player].input_feedback="STUN: COMBAT STILL AVAILABLE"
    controls[player].movement_executed=false
   requested[player]=0
  bout.movements[player]=requested[player]
 if requested==[0,0]:return
 bout.move()
 for player in range(2):
  fighters[player].sync_hurtbox(Vector2(bout.positions[player],Bout.GROUND_Y))
  if not is_equal_approx(before[player],bout.positions[player]):
   step_origins[player]=fighters[player].position.x
   step_started[player]=game_time()
   controls[player].last_step_time=at
   controls[player].last_step_processed=game_time()
   fighters[player].rhythmic_pose("forward_step" if requested[player]==facing(player) else "backward_step",step_seconds)
   pose_until_by_player[player]=conductor.now()+step_seconds
  elif requested[player]!=0:
   controls[player].movement_executed=false
   controls[player].step_feedback="REJECT arena/separation"
  trace_movement("movement",player,{"logical_before":before[player],"requested":requested[player],"execution_time":at})

func present_combat(player: int) -> void:
 if bout.selections[player] < 0 or conductor.grade(bout.errors[player]) == "miss":
  return
 var height: String = ["high", "mid", "low"][bout.selections[player]]
 fighters[player].impact(height + ("_attack" if bout.initiative == player else "_block"), conductor.duration() * 0.7)
 pose_until_by_player[player] = conductor.now() + conductor.duration() * 0.85

func facing(player: int) -> int:
 return 1 if bout.positions[1 - player] > bout.positions[player] else -1

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
  ui_held.clear()
  for control in controls:
   control.reset()
   control.input_feedback = "REJECT focus lost; press again"
  bout.movements = [0, 0]

func resolve_exchange() -> void:
 if phrase_resolved:
  return
 freeze_combat_positions(game_time())
 phrase_resolved = true
 var attack := bout.initiative
 var defense := 1 - attack
 var direction := maxi(0, selected[attack])
 var height: String = ["high", "mid", "low"][direction]
 status = bout.resolve(conductor, exchange_phrase)
 impact_effect.play_resolved(bout.last_event, "%d:%d:%d" % [match_serial,match_progress.round_number,exchange_phrase], conductor.now())
 for fighter in fighters:
  fighter.visual_priority=0
  fighter.visual_until=-INF
 var published:=bout.last_event.duplicate(true)
 published["round"]=match_progress.round_number
 published["time"]=game_time()
 completed_exchanges.append(published)
 if completed_exchanges.size()>4096:completed_exchanges.pop_front()
 if game_mode=="cpu":cpu.observe_result(published,"%d:%d" % [match_progress.round_number,exchange_phrase])
 outcome_until = game_time() + 0.6
 pose_until = conductor.now() + 0.35
 pose_until_by_player = [pose_until, pose_until]
 if bout.last_event.get("kind") == "WHIFF" and int(bout.last_event.get("height", -1)) >= 0:
  fighters[attack].whiff(height, 0.35)
 elif status.begins_with("Perfect"):
  fighters[defense].parry(height, conductor.duration() * 0.5)
  movement_stun[attack]="%d:1" % (exchange_phrase+1)
  stun_time[attack]=conductor.phrase_start if conductor.phrase>exchange_phrase else conductor.phrase_start+conductor.duration()*4
  if str(controls[attack].pending_target.get("id",""))==movement_stun[attack]:
   controls[attack].pending_move=0
   controls[attack].queued=0
   controls[attack].movement_executed=false
   controls[attack].step_feedback="STUN: ONE MOVE LOST"
   controls[attack].input_feedback="STUN: COMBAT STILL AVAILABLE"
  fighters[attack].rhythmic_pose("stunned",0.33,50)
  audio.sound("parry")
 elif status.begins_with("Blocked"):
  audio.sound("block")
 elif status.begins_with("Clean") or bout.winner >= 0:
  fighters[defense].rhythmic_pose("hurt",0.2,70)
  fighters[defense].hit_feedback()
  audio.sound("hit")
 if bout.winner >= 0:
  match_progress.award_round(bout.winner)
  mode = "finishing"
  audio.stop()
  transition_until=conductor.now()+(0.22 if match_progress.winner>=0 else 0.35)
 refresh()

func complete_round_transition() -> void:
 if mode!="finishing":return
 transition_until=INF
 if match_progress.winner>=0:
  if result_handled:return
  result_handled=true
  var winner: int=match_progress.winner
  fighters[winner].play_final("victory")
  fighters[1-winner].play_final("defeat")
  audio.music.pitch_scale=1.0
  audio.play_result(game_mode,winner)
  mode="match_win"
  flow.root("result")
 else:
  for fighter in fighters:
   fighter.reset_visual()
   fighter.set_pose("combat_idle")
  mode="round_win"

func expire_stuns(at: float) -> void:
 for player in range(2):
  if not movement_stun[player].is_empty() and at>stun_time[player]+(movement_good_ms+maxf(0,conductor.latency_ms))/1000.0:
   movement_stun[player]=""

func apply_preferences(include_match: bool=true) -> void:
 var values: Dictionary=preferences.values
 if include_match:
  game_mode=values.game_mode
  cpu_difficulty=values.difficulty
  selected_bpm=values.bpm
  stage_preference=values.stage
  settings["match_best_of"]=values.best_of
 audio.apply_preferences(values)
 click_player.bus="SFX"
 if DisplayServer.get_name()!="headless":
  DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if values.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
 get_window().content_scale_stretch=Window.CONTENT_SCALE_STRETCH_INTEGER if values.integer_scale else Window.CONTENT_SCALE_STRETCH_FRACTIONAL

func set_paused(value: bool) -> void:
 if value==paused:return
 if value and audio.music.playing:audio.audio_time()
 paused=value
 conductor.set_paused(value)
 audio.music.stream_paused=value
 audio.effects.stream_paused=value
 for fighter in fighters: fighter.process_mode=Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
 for control in controls:control.reset()
 bout.movements=[0,0]
 if value:flow.root("pause")
 refresh()

func return_to_title() -> void:
 if paused:set_paused(false)
 cpu.queue.clear()
 conductor.started=false
 mode="menu"
 audio.stop()
 audio.music.pitch_scale=1
 audio.play_track("menu",conductor.now(),true)
 for fighter in fighters:
  fighter.reset_visual()
  fighter.set_pose("idle")
 flow.root("title")
 refresh()

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey:
  if not event.pressed:ui_held.erase(event.keycode)
  if event.echo:return
  if event.pressed and event.keycode==KEY_F3:
   debug_visible=not debug_visible
   refresh()
   return
  if event.pressed and event.keycode==KEY_F4:
   if debug_visible and mode=="menu":
    stage.select_stage(stage.selected+1)
   return
  if flow.active():
   if not event.pressed:return
   if ui_held.has(event.keycode):return
   ui_held[event.keycode]=true
   flow.view.key(event)
   refresh()
   return
  if event.pressed and event.keycode==KEY_ESCAPE:
   set_paused(true)
   ui_held[event.keycode]=true
   return
  if event.pressed and event.keycode==KEY_ENTER and mode=="round_win":
   next_round()
   return
 if paused or mode in ["finishing","round_win","match_win","menu"]:return
 var at:=game_time()
 if mode in ["standoff","race","combat"]:advance_timeline(at)
 for player in range(2):
  if game_mode=="cpu" and player==1:continue
  var prefix := "p%d_" % (player+1)
  for action in ["left","right","high","low","execute"]:
   if event.is_action(prefix+action):submit_action(player,action,event.is_action_pressed(prefix+action),at,"human",event.get_instance_id())

func submit_action(player: int, action: String, pressed: bool, at: float, source: String="human", event_id: int=0) -> void:
 # Sole action adapter for keyboard and CPU. All damage/positions remain in existing rules.
 if paused or mode in ["menu","finishing","round_win","match_win"]:return
 if player not in [0,1] or action not in ["left","right","high","low","execute"]:return
 if game_mode=="cpu" and player==1 and source!="cpu":return
 if mode in ["standoff","race"] and action=="execute" and pressed:
  bout.race_press(player,at,cue)
  if bout.false_starts[player]:
   fighters[player].set_pose("false_start")
   status="P%d false start: forfeits initiative" % (player+1)
 var rising := pressed and not bool(controls[player].held.get(action,false))
 var combination := controls[player].feed(action, pressed, at, facing(player), mode == "combat")
 if rising and action in ["left","right"] and mode=="combat":
  controls[player].request_movement(action,at,conductor,movement_perfect_ms,movement_good_ms)
  if controls[player].movement_grade!="miss":
   accepted_until[player]=conductor.now()+0.18
   apply_movement(conductor.beat,conductor.phrase,conductor.beat_time)
  freeze_combat_positions(at)
 if action in ["left", "right"]:
  handled_event_count += 1
  if mode != "combat":controls[player].input_feedback = "REJECT movement phase " + mode

  trace_movement("unhandled",player,{"event_id":event_id,"action":"p%d_%s" % [player+1,action],"pressed":pressed,"source":source,"accepted":mode=="combat" and controls[player].movement_grade!="miss"})
 if mode != "combat":
  if pressed and action in ["left", "right", "high", "low"]:
   controls[player].input_feedback = "REJECT movement phase; held tracked"
  elif pressed and action == "execute":
   controls[player].input_feedback = ("REJECT false start" if bout.false_starts[player] else "ACCEPT race reaction") if mode in ["standoff", "race"] else "REJECT execute outside combat"
  return
 if combination.is_empty():
  return
 if phrase_resolved or not is_inf(bout.errors[player]):
  controls[player].input_feedback = "REJECT action already submitted"
  return
 var error := (conductor.timestamp(combination["execute_at"]) - conductor.action_time()) * 1000.0
 bout.errors[player] = error
 bout.selections[player] = combination["height"]
 selected[player] = combination["height"]
 last_error[player] = error
 if conductor.grade(error) != "miss":
  controls[player].input_feedback = "ACCEPT combat + movement queued"
  if at >= conductor.action_time():
   present_combat(player)
  else:
   var height: String = ["high", "mid", "low"][bout.selections[player]]
   fighters[player].prepare(height + ("_attack" if bout.initiative == player else "_block"), conductor.action_time() - at)
   pose_until_by_player[player] = conductor.now() + conductor.duration()
 else:
  controls[player].input_feedback = "REJECT action timing; movement independent"
func refresh() -> void:
 hud.visible = not debug_visible and mode!="menu"
 flow.refresh()
 hud.blue.player_name="CPU "+cpu_difficulty.to_upper() if game_mode=="cpu" else "BLUE"
 hud.present(HUDPresenter.snapshot(self,game_time()))
 hud.major_label.visible=mode!="match_win"
 hud.footer_label.visible=mode!="match_win"
 hud.outcome_label.visible=mode!="match_win"
 for player in range(2):
  var control: CombatInput=controls[player]
  hud.step_labels[player].text = (control.movement_grade.to_upper()+" STEP" if control.movement_grade in ["perfect","good"] else "MISS") if mode=="combat" and preferences.values.timing_feedback and game_time()<control.movement_feedback_until else ""
 cpu_debug_label.visible=debug_visible and game_mode=="cpu" and not flow.active()
 cpu_debug_label.text=cpu.diagnostic(absf(bout.positions[1]-bout.positions[0]))
 for player in range(2):
  if controls[player].step_feedback.begins_with("STUN") and game_time()<controls[player].movement_feedback_until: hud.step_labels[player].text="STUN"
 label.visible = debug_visible and not flow.active()
 detail.visible = debug_visible and not flow.active()
 input_feedback_label.visible = debug_visible and not flow.active()
 input_feedback_label.text = ""
 for player in range(2):
  var control: CombatInput=controls[player]
  input_feedback_label.text += "P%d t%.3f b%s %+.0fms %s\n%s e%d X%.0f/%.0f %s\n" % [player+1,control.movement_input_at,str(control.movement_target.get("id","-")),control.movement_error_ms,control.movement_grade,last_keys[player],int(control.movement_executed),bout.positions[player],fighters[player].position.x,control.input_feedback]
 label.text = "STICKS N LICKS     %d BPM" % conductor.bpm
 if help_visible:
  detail.text = "P1: A/D move · W high · S low · F execute\nP2: arrows move/high/low · RShift execute\nForward + execute = MID (facing-relative)\nTap on beats 1-4; combat on beat 4\nPerfect ±70ms · valid ±140ms · combo 100ms\nH help · F3 debug · F4 stage · Esc menu"
 elif mode == "menu":
  detail.text = "LOCAL VERSUS · Enter to start · H controls
C cue style: %s · F3 rhythm overlay" % cue_style
 else:
  detail.text = "%s · Beat %d · P%d attacks
P1 %d/3 hits   P2 %d/3 hits
%s" % [mode.to_upper(), conductor.beat, bout.initiative + 1, bout.hits[0], bout.hits[1], status]
  if mode in ["round_win", "match_win"]:
   detail.text += "
Enter rematch · Esc menu"
 if debug_visible and not help_visible:
  var event: Dictionary = bout.last_event
  var result := "READY" if event.is_empty() else str(event["kind"]) + " " + str(event["reason"])
  var stamps: Array[String] = []
  for control in controls:
   stamps.append("--" if is_inf(control.last_step_time) else "%.3f/%.3f" % [control.last_step_time, control.last_step_processed])
  var item: Dictionary = audio.entries.get(audio.active, {})
  var file := str(item.get("path", "none")).get_file()
  detail.text = "%s beat%d phrase%d atkP%d hits%d:%d" % [mode, conductor.beat, conductor.phrase, bout.initiative+1, bout.hits[0], bout.hits[1]]
  detail.text += "\nerr%s sel%s q%s" % ["[%+.0f,%+.0f]" % last_error, str(selected), str([controls[0].movement(),controls[1].movement()])]
  detail.text += " S%s/%s" % [movement_stun[0],movement_stun[1]]
  detail.text += "\nStep grid/actual P1 %s P2 %s" % [stamps[0],stamps[1]]
  detail.text += "\n%s off %ss" % [file,str(item.get("beat_zero_seconds","?"))]
  detail.text += "\nLatency in/out %.0f/%.0fms next%d BPM" % [conductor.latency_ms,audio.latency_ms,conductor.pending_bpm]
  detail.text += "\nLAST %s · reach %.0f" % [result,bout.stick_reach]

 for diagnostic_label in [label,detail,input_feedback_label,cpu_debug_label]:
  diagnostic_label.text=diagnostic_label.text.to_upper().replace("·"," ").replace("±","+/-")

func active_attack_region() -> Rect2:
 # The shared beat-four active window, not sprite callbacks, gates attack geometry.
 if mode != "combat" or conductor.beat != 4 or phrase_resolved:
  return Rect2()
 var player := bout.initiative
 if bout.selections[player] < 0 or conductor.grade(bout.errors[player]) == "miss":
  return Rect2()
 return bout.attack_region(player, bout.selections[player], bout.impact_positions)

func _draw() -> void:
 if not stage.texture or debug_visible:
  draw_rect(Rect2(0, 0, 320, 180), Color("151e29"))
 if debug_visible:draw_line(Vector2(16,150),Vector2(304,150),Color("aeaa7a"),1)
 for player in range(fighters.size()):
  if conductor.now()<accepted_until[player]:
   draw_line(fighters[player].position+Vector2(-3,2),fighters[player].position+Vector2(3,2),Color.GREEN,2)
 for n in range(4):
  if debug_visible or help_visible or not str(hud.state.get("footer", "")).is_empty():
   continue
  draw_circle(Vector2(139 + n * 14, 172), 3, Color("f3ba55") if conductor.beat == n + 1 else Color("596066"))

func sync_ground_sticks() -> void:
 # Existing race adjudication automatically collects both sticks in pickup.
 var automatic_pickup := mode not in ["menu", "standoff", "race"]
 ground_sticks.set_collected(automatic_pickup or (mode == "race" and bout.reactions[0] >= 0), automatic_pickup or (mode == "race" and bout.reactions[1] >= 0))
