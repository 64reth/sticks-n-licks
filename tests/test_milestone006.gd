extends SceneTree
var game: Node2D
var time: float=0.0
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(message)
func key(code: int) -> void:MenuTestInput.key(game,code)
func action(player: int,name: String) -> void:
 var event:=InputEventAction.new()
 event.action="p%d_%s" % [player+1,name]
 event.pressed=true
 game._unhandled_input(event)
 event=event.duplicate()
 event.pressed=false
 game._unhandled_input(event)
func advance(at: float) -> void:
 time=at
 game._process(0.01)
func combat(attacker: int=0,bpm: int=120,best_of: int=3) -> void:
 if game.paused:game.set_paused(false)
 game.conductor.pause_offset=0
 game.conductor.paused=false
 game.settings.match_best_of=best_of
 game.game_mode="pvp"
 game.match_progress.reset(best_of)
 game.bout=Bout.new()
 game.bout.initiative=attacker
 game.bout.positions.assign([140.0,180.0])
 game.mode="combat"
 game.phrase_resolved=false
 game.exchange_phrase=0
 game.selected.assign([-1,-1])
 game.cpu.queue.clear()
 game.result_handled=false
 game.transition_until=INF
 game.movement_stun.assign(["",""])
 game.pose_until_by_player.assign([0.0,0.0])
 for f in game.fighters:
  f.reset_visual()
  f.set_pose("combat_idle")
 for control in game.controls:control.reset()
 time=0
 game.conductor.start(0,bpm)
 game.conductor.update(0)
func strike(attacker: int,defend: bool=false,height: String="high") -> void:
 action(attacker,height)
 action(attacker,"execute")
 if defend:
  action(1-attacker,height)
  action(1-attacker,"execute")
func run() -> void:
 game=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 game.preferences_path=""
 game.conductor.clock_override=func():return time
 root.add_child(game)
 game.set_process(false)
 check(game.flow.view.page=="title" and game.flow.view.visible,"Root launches to title")
 check(game.flow.view.rows.size()==4,"Title has four conventional items")
 key(KEY_DOWN)
 check(game.flow.view.cursor==1,"Down navigates")
 key(KEY_UP)
 var event:=InputEventKey.new()
 event.keycode=KEY_ENTER
 event.pressed=true
 game._unhandled_input(event)
 game._unhandled_input(event)
 check(game.flow.view.page=="setup" and game.flow.view.cursor==0,"Held Enter opens setup only once")
 event.pressed=false
 game._unhandled_input(event)
 key(KEY_ENTER)
 check(game.game_mode=="cpu" and game.flow.view.cursor==1,"Enter confirms a value without changing it")
 key(KEY_UP)
 key(KEY_RIGHT)
 check(game.game_mode=="pvp","Setup changes mode")
 key(KEY_RIGHT)
 key(KEY_DOWN)
 key(KEY_RIGHT)
 check(game.cpu_difficulty=="hard","Setup changes CPU difficulty")
 key(KEY_DOWN)
 key(KEY_RIGHT)
 check(game.settings.match_best_of==5,"Setup selects best of five")
 key(KEY_DOWN)
 key(KEY_RIGHT)
 check(game.selected_bpm==140,"Setup selects tempo")
 key(KEY_DOWN)
 key(KEY_RIGHT)
 check(game.stage_preference=="stage_02","Setup selects discovered stage")
 key(KEY_DOWN)
 key(KEY_ENTER)
 check(game.mode=="standoff" and game.conductor.bpm==140,"Selected tempo starts standoff")
 check(game.match_progress.wins_needed()==3,"Selected format starts match")
 check(game.bout.hits==[0,0],"Menu navigation never damages fighters")
 var frozen: float=game.conductor.now()
 var cue: float=game.cue
 key(KEY_ESCAPE)
 check(game.paused and game.flow.view.page=="pause","Escape pauses match")
 time+=40
 game._process(1)
 action(0,"right")
 action(0,"execute")
 check(game.conductor.now()==frozen and game.cue==cue and game.bout.positions==[100.0,220.0],"Pause freezes clock, CPU, collisions and inputs")
 key(KEY_ESCAPE)
 check(not game.paused and game.conductor.now()==frozen,"Resume subtracts wall-clock pause")
 check(game.controls[0].pending_move==0 and is_inf(game.controls[0].pending_execute),"Resume has no buffered actions")
 game.ui_held[KEY_ENTER]=true
 game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(game.ui_held.is_empty(),"Focus loss clears held menu confirmation")
 game.audio.last_elapsed=1.25
 game.audio.music.stream_paused=true
 check(game.audio.audio_time()==1.25,"Paused audio clock has no mixer-correction drift")
 game.audio.music.stream_paused=false
 game.audio.last_elapsed=0
 # Saved-value validation and isolated disk round trip.
 var prefs:=UserPreferences.new()
 prefs.path="res://output/preferences006.cfg"
 var ids: Array=[]
 for stage in game.stage.entries:ids.append(stage.id)
 prefs.values=prefs.validate({"best_of":99,"bpm":55,"stage":"missing","master":999,"difficulty":"impossible","music_on":"yes"},ids)
 check(prefs.values.best_of==3 and prefs.values.bpm==120 and prefs.values.stage=="stage_01" and prefs.values.master==100 and prefs.values.music_on,"Invalid settings fall back/clamp")
 prefs.values.best_of=7
 prefs.values.bpm=160
 prefs.values.stage="random"
 prefs.values.music=30
 prefs.values.music_on=false
 check(prefs.save_values()==OK,"Preferences write local ConfigFile")
 var reload:=UserPreferences.new()
 reload.path=prefs.path
 reload.load_values(ids)
 check(reload.values==prefs.values,"Preferences survive a fresh loader")
 game.audio.apply_preferences(reload.values)
 check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")),"Music off mutes bus without stopping clock")
 check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")),linear_to_db(0.3)),"Music volume applies")
 game.audio.apply_preferences(UserPreferences.DEFAULTS)
 for best_of in [3,5,7]:
  var progress:=MatchProgress.new()
  progress.reset(best_of)
  var needed: int={3:2,5:3,7:4}[best_of]
  for index in range(needed):
   progress.award_round(1)
   check((progress.winner==1)==(index==needed-1),"Match ends exactly at required wins")
   if index<needed-1:check(progress.next_round(),"Intermediate round advances")
  game.match_progress=progress
  game.refresh()
  check(game.hud.blue.wins_needed==needed,"HUD has dynamic markers")
 var missing_stages:=StageBackground.available_entries([{"id":"gone","path":"assets/not-a-stage.png"},game.stage.entries[0]])
 check(missing_stages.size()==1,"Unavailable stage assets are removed from selectable values")
 game.stage_preference="random"
 game.settings.match_best_of=7
 game.begin()
 var random_stage: int=game.stage.selected
 game._begin_round()
 check(game.stage.selected==random_stage,"Random stage stays stable across rounds")
 check(game.bout.hits==[0,0] and game.match_progress.best_of==7,"Restart retains selected format with fresh energy")
 game.conductor.pause_offset=0
 time=0
 for bpm in [120,140,160]:
  game.return_to_title()
  game.preferences.values.game_mode="pvp"
  game.preferences.values.bpm=bpm
  game.apply_preferences(true)
  game.begin()
  check(game.conductor.bpm==bpm and is_equal_approx(game.audio.music.pitch_scale,float(bpm)/120),"Selected tempo applies to conductor and standoff music")
  advance(game.cue+0.08)
  action(0,"execute")
  time+=0.04
  action(1,"execute")
  game._process(0)
  advance(game.conductor.epoch)
  check(game.mode=="combat" and game.audio.active==str(bpm) and game.audio.music.pitch_scale==1.0,"Selected tempo launches native combat loop")
 var muted:=UserPreferences.DEFAULTS.duplicate(true)
 muted.master=0
 game.audio.apply_preferences(muted)
 check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")),"Zero master volume truly mutes")
 game.audio.apply_preferences(UserPreferences.DEFAULTS)
 # Every imported animation's scale, facing, frame count and non-looping metadata.
 for player in range(2):
  var fighter: Fighter=game.fighters[player]
  fighter.reset_visual()
  for state in ["stunned","hurt","victory","defeat"]:
   fighter.set_pose(state)
   var expected: int={"stunned":3,"hurt":2,"victory":4,"defeat":3}[state]
   check(fighter.sprite.sprite_frames.get_frame_count(state)==expected,"Correct supplied frame count")
   check(not fighter.sprite.sprite_frames.get_animation_loop(state),"Reaction/outcome never loops")
   var meta: Dictionary=fighter.animation_meta[state]
   check(absf(fighter.sprite.position.y+(384.0)*0+(float(meta.ground_pixel)-384.0)*fighter.sprite.scale.y)<0.001,"Ground anchor matches metadata")
   fighter.face(1 if player==0 else -1)
   check(not fighter.sprite.flip_h,"Native facing retained once")
 for bpm in [120,140,160]:
  combat(0,bpm)
  var target: float=game.conductor.action_time()
  advance(target)
  strike(0,true)
  advance(target+0.241)
  check(game.bout.initiative==1 and game.bout.hits==[0,0],"Parry reverses initiative without damage")
  check(game.fighters[0].pose=="stunned","Parried attacker uses supplied stun")
  var next: float=game.conductor.phrase_start+game.conductor.duration()*4
  advance(next-0.10)
  action(0,"right")
  advance(next)
  check(game.bout.positions==[140.0,180.0] and not game.controls[0].movement_executed,"Next early movement tap blocked exactly once")
  advance(next+0.10)
  action(0,"right")
  check(game.bout.positions==[140.0,180.0],"Late tap for same stunned beat also blocked")
  advance(next+0.17)
  check(game.movement_stun[0].is_empty(),"Stun expires even without another key")
  advance(next+game.conductor.duration())
  action(0,"left")
  check(game.bout.positions[0]==124,"Following beat movement allowed")
 combat(0,160)
 advance(1.125)
 strike(0,true)
 advance(1.34)
 action(0,"right")
 check(game.controls[0].pending_move==1,"Early next-beat tap can arrive before parry adjudication")
 advance(1.366)
 check(game.controls[0].pending_move==0 and game.controls[0].step_feedback.begins_with("STUN"),"Parry cancels an already queued next-beat tap with explicit feedback")
 advance(1.5)
 check(game.bout.positions==[140.0,180.0],"Cancelled early tap cannot bypass stun")
 combat(0)
 advance(1.5)
 strike(0,true)
 advance(2.0)
 check(game.stun_time[0]==2.0,"Catch-up parry targets this boundary, not a whole extra phrase")
 advance(2.17)
 check(game.movement_stun[0].is_empty(),"Catch-up stun also expires without a keypress")
 # Every permitted deciding score, including 4-3, for either winner.
 for format in [3,5,7]:
  var needed: int={3:2,5:3,7:4}[format]
  for winner in [0,1]:
   for loser_score in range(needed):
    var progress:=MatchProgress.new()
    progress.reset(format)
    var sequence: Array[int]=[]
    for i in range(loser_score):sequence.append(1-winner)
    for i in range(needed):sequence.append(winner)
    for index in range(sequence.size()):
     check(progress.award_round(sequence[index]),"Legal round counted once")
     if index<sequence.size()-1:check(progress.winner==-1 and progress.next_round(),"No premature result in a longer match")
    check(progress.winner==winner and progress.round_wins[winner]==needed and progress.round_wins[1-winner]==loser_score and not progress.next_round(),"All deciding scores end immediately")
 # Assert combat independence explicitly while a movement-stun target overlaps beat four.
 for attacking in [true,false]:
  combat(0 if attacking else 1)
  game.movement_stun[0]="0:4"
  game.stun_time[0]=1.5
  game.fighters[0].rhythmic_pose("stunned",10,50)
  advance(1.5)
  action(0,"right")
  action(0,"execute")
  action(1,"left" if not attacking else "low")
  action(1,"execute")
  check(game.bout.selections[0]==1 and game.fighters[0].pose in ["mid_attack","mid_block"],"Legal combat interrupts stun and accepts MID without movement")
  advance(1.741)
  check(game.bout.hits[0]==1 if attacking else game.bout.last_event.kind=="PARRY","Stunned fighter can attack or perfect-parry legally")
 combat()
 advance(1.5)
 strike(0)
 advance(1.741)
 check(game.fighters[1].pose=="hurt" and game.bout.hits==[1,0],"Clean strike triggers one damage and hurt")
 # Ordinary rounds: no final animation, no result music.
 for mode in ["cpu","pvp"]:
  for winner in [0,1]:
   combat(winner)
   game.game_mode=mode
   game.cpu.parameters.retreat=0.0
   game.cpu.parameters.hesitate=1.0
   game.bout.hits[winner]=2
   advance(1.5)
   game.submit_action(winner,"high",true,time,"cpu" if winner==1 and mode=="cpu" else "human")
   game.submit_action(winner,"execute",true,time,"cpu" if winner==1 and mode=="cpu" else "human")
   var count: int=game.audio.event_log.size()
   advance(1.741)
   advance(2.10)
   check(game.mode=="round_win" and game.audio.event_log.size()==count,"Ordinary round has no victory/defeat music %s %d %s %s" % [mode,winner,game.mode,str(game.bout.hits)])
   check(game.fighters[0].pose not in ["victory","defeat"] and game.fighters[1].pose not in ["victory","defeat"],"Ordinary round has no final poses")
   # Deciding round in same match, then one legal final strike.
   combat(winner)
   game.game_mode=mode
   game.cpu.parameters.retreat=0.0
   game.cpu.parameters.hesitate=1.0
   game.match_progress.round_wins[winner]=1
   game.bout.hits[winner]=2
   advance(1.5)
   game.submit_action(winner,"high",true,time,"cpu" if winner==1 and mode=="cpu" else "human")
   game.submit_action(winner,"execute",true,time,"cpu" if winner==1 and mode=="cpu" else "human")
   advance(1.741)
   advance(2.0)
   check(game.mode=="match_win" and game.flow.view.page=="result","Deciding hit enters result screen")
   check(game.audio.active==("defeat" if mode=="cpu" and winner==1 else "victory"),"Correct human-outcome result theme")
   check(game.fighters[winner].pose=="victory" and game.fighters[1-winner].pose=="defeat","Only deciding round uses final poses")
   var music_count: int=game.audio.event_log.size()
   for fighter in game.fighters:
    fighter.set_pose("combat_idle")
    fighter.impact("high_attack",0.1)
    fighter.whiff("high",0.1)
   advance(3.0)
   check(game.fighters[winner].pose=="victory" and game.fighters[1-winner].pose=="defeat" and game.audio.event_log.size()==music_count,"Final poses/music immune to stale requests")
 print("MILESTONE 006: %d checks, %d failures" % [checks,failures])
 game.audio.stop()
 game.conductor.clock_override=Callable()
 game.queue_free()
 quit(1 if failures else 0)
