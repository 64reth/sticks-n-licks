extends SceneTree
var game: Node2D
var time := 0.0
var checks := 0
var failures := 0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(message)
func key(action: String,down: bool=true,echo: bool=false) -> void:
 var event: InputEventKey=InputMap.action_get_events(action)[0].duplicate()
 event.keycode=event.physical_keycode
 event.pressed=down
 event.echo=echo
 Input.parse_input_event(event)
 await process_frame
func release_all() -> void:
 for p in range(2):
  for direction in ["left","right"]:
   await key("p%d_%s" % [p+1,direction],false)
func advance(at: float) -> void:
 time=at
 game._process(0.01)
func reset(bpm: int=120) -> void:
 await release_all()
 time=0
 game.bout=Bout.new()
 game.mode="combat"
 game.phrase_resolved=false
 game.exchange_phrase=0
 game.selected.assign([-1,-1])
 game.previous_bpm=bpm
 game.pose_until_by_player.assign([0.0,0.0])
 game.step_started.assign([-INF,-INF])
 for control in game.controls:control.reset()
 for p in range(2):
  game.fighters[p].position=Vector2(game.bout.positions[p],150)
  game.fighters[p].set_pose("combat_idle")
 game.conductor.latency_ms=0
 game.conductor.start(0)
 game.conductor.bpm=bpm
 game.conductor.pending_bpm=bpm
 advance(0)
func run() -> void:
 game=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 game.preferences_path=""
 game.game_mode="pvp"
 game.conductor.clock_override=func():return time
 root.add_child(game)
 game.preferences.values.game_mode=game.game_mode
 game.set_process(false)
 game.audio.stop()
 for p in range(2):
  var sprite: AnimatedSprite2D=game.fighters[p].sprite
  for state in ["forward_step","backward_step"]:
   check(sprite.sprite_frames.get_frame_count(state)==2,"Two approved step poses")
   check(not sprite.sprite_frames.get_animation_loop(state),"Step never loops")
  check(sprite.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"Crisp texture filtering")
 check(game.fighters[1].sprite.sprite_frames.get_frame_count("combat_idle")==4,"Blue supplied idle retained")
 for bpm in [120,140,160]:
  var d: float=60.0/bpm
  for beat in range(1,5):
   for error in [-161.0,-160.0,-90.0,0.0,90.0,160.0,161.0]:
    await reset(bpm)
    # Use phrase 1 to test beat 1's early window too.
    var target: float=d*(beat+3)
    var at: float=target+error/1000.0
    advance(at)
    var initiative_before: int=game.bout.initiative
    await key("p1_right")
    await key("p2_left")
    await key("p1_right",false)
    await key("p2_left",false)
    var grade: String="perfect" if abs(error)<=90 else ("good" if abs(error)<=160 else "miss")
    for p in range(2):check(game.controls[p].movement_grade==grade,"Correct movement grade bpm%d beat%d error%.0f" % [bpm,beat,error])
    check(game.bout.hits==[0,0] and game.bout.initiative==initiative_before,"Tap alone never changes energy or initiative")
    if error<0:advance(target)
    var valid:=grade!="miss"
    check(game.bout.positions==([116.0,204.0] if valid else [100.0,220.0]),"Both players step iff tap valid")
    check(game.bout.hits==[0,0],"Boundary movement never scores damage")
    if valid:
     check(game.fighters[0].pose=="forward_step" and game.fighters[1].pose=="forward_step","Step starts with displacement")
     advance(maxf(target,at)+0.17)
     check(game.fighters[0].pose not in ["forward_step","backward_step"] and game.fighters[1].pose not in ["forward_step","backward_step"],"Step completes after 160ms; combat may override idle")
     check(game.fighters[0].position.x==116 and game.fighters[1].position.x==204,"Visual displacement completes with step")
    else:check(game.fighters[0].pose=="combat_idle","Miss never walks")
  await reset(bpm)
  advance(d-0.04)
  await key("p1_right")
  advance(d)
  var x: float=game.bout.positions[0]
  for n in range(2,6):
   advance(d*n)
   await key("p1_right",true,true)
   check(game.bout.positions[0]==x,"Hold/repeat cannot generate another step")
  await key("p1_right",false)
  advance(d*6)
  await key("p1_right")
  check(game.bout.positions[0]==x+Bout.STEP,"Release/repress allows next step")
  await key("p1_right",false)
  await key("p1_left")
  check(game.bout.positions[0]==x+Bout.STEP,"Second tap same beat consumed once")
  await reset(bpm)
  game.bout.positions.assign([100.0,156.0])
  var target: float=game.conductor.action_time()
  advance(target+0.10)
  await key("p1_right")
  check(game.bout.positions[0]==116,"Late beat-four movement allowed")
  check(game.bout.impact_phrase==-1,"Range not frozen before late window closes")
  advance(target+0.161)
  check(game.bout.impact_positions==[116.0,156.0],"Freeze includes legal late movement")
  await key("p1_right",false)
  advance(target+0.17)
  await key("p1_left")
  check(game.bout.positions==[116.0,156.0],"Late miss cannot change frozen range")
 await reset()
 game.mode="standoff"
 await key("p1_right")
 game.mode="combat"
 advance(0.5)
 check(game.bout.positions==[100.0,220.0],"Precombat holds do not auto-step")
 await reset()
 game.bout.positions.assign([30.0,290.0])
 advance(0.5)
 await key("p1_left")
 await key("p2_right")
 check(game.bout.positions==[30.0,290.0],"Arena boundaries retained")
 check(not game.controls[0].movement_executed,"Blocked step reports not executed")
 await reset()
 advance(0.44)
 await key("p1_right")
 game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
 advance(0.5)
 check(game.bout.positions==[100.0,220.0],"Focus loss cancels pending step")
 await reset()
 game.conductor.latency_ms=100
 game.bout.positions.assign([100.0,156.0])
 advance(1.70)
 await key("p1_right")
 check(game.controls[0].movement_grade=="good" and game.bout.positions[0]==116,"Movement uses conductor latency compensation")
 check(game.bout.impact_phrase==-1,"Freeze waits for compensated movement window")
 advance(1.761)
 check(game.bout.impact_positions==[116.0,156.0],"Compensated late step enters frozen range")
 game.stage.select_stage(0)
 var first: Texture2D=game.stage.texture
 game.stage.select_stage(1)
 check(game.stage.texture!=first,"Stage selection changes actual texture")
 check(game.stage.destination.size.x>=320 and game.stage.destination.size.y>=180,"Stage fills viewport")
 check(is_equal_approx(game.stage.destination.size.aspect(),1672.0/941.0),"Stage proportional fit")
 check(game.stage.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"Stage nearest filtering")
 print("IDLE/MOVEMENT TESTS: %d checks, %d failures" % [checks,failures])
 game.audio.stop()
 game.conductor.clock_override=Callable()
 game.queue_free()
 quit(1 if failures else 0)
