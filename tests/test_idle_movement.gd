extends SceneTree
var game: Node2D
var time: float = 0.0
var checks: int = 0
var failures: int = 0

func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)

func key(action: String, down: bool = true, echo: bool = false) -> void:
 # Exercise Godot's event dispatch + InputMap + _unhandled_input, not a direct handler call.
 var event: InputEventKey = InputMap.action_get_events(action)[0].duplicate()
 event.keycode = event.physical_keycode
 event.pressed = down
 event.echo = echo
 Input.parse_input_event(event)
 await process_frame

func release_all() -> void:
 for player in range(2):
  for action in ["left","right","high","low","execute"]:
   var name := "p%d_%s" % [player+1,action]
   if Input.is_action_pressed(name):
    await key(name,false)

func reset_game(bpm: int = 120) -> void:
 await release_all()
 game.bout = Bout.new()
 game.bout.stick_reach = float(game.settings["stick_reach"])
 game.mode = "combat"
 game.phrase_resolved = false
 game.exchange_phrase = 0
 game.selected.assign([-1,-1])
 game.pose_until_by_player.assign([0.0,0.0])
 game.previous_bpm = bpm
 for control in game.controls: control.reset()
 for fighter in game.fighters:
  fighter.flash_time = 0
  fighter.whiff_time = 0
  fighter.spark_time = 0
  fighter.sprite.modulate = Color.WHITE
  fighter.set_pose("combat_idle")
 time = 0.0
 game.conductor.start(time)
 game.conductor.bpm = bpm
 game.conductor.pending_bpm = bpm
 advance(0)

func advance(at: float) -> void:
 time = at
 game._process(1.0)

func blue_idle() -> bool:
 var sprite: AnimatedSprite2D = game.fighters[1].sprite
 return sprite.animation == "combat_idle" and sprite.sprite_frames.get_frame_count("combat_idle") == 4 and sprite.is_playing() and not sprite.flip_h

func capture(name: String) -> void:
 if DisplayServer.get_name() == "headless": return
 game.refresh()
 game.queue_redraw()
 game.combat_debug.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/idle_move_%s.png" % name)

func run() -> void:
 game = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 game.conductor.clock_override = func():return time
 root.add_child(game)
 game.set_process(false)
 var blue: Fighter = game.fighters[1]
 check(blue.sprite.animation == "idle" and blue.sprite.is_playing(),"Blue idle starts playing immediately on launch")
 check(blue.sprite.sprite_frames.get_frame_count("idle") == 4,"New Blue idle has the four inspected source poses")
 check(blue.sprite.sprite_frames.get_animation_loop("idle"),"Blue idle loops")
 check(blue.sprite.sprite_frames.get_animation_speed("idle") == 8,"Idle uses existing 8fps convention")
 check(not blue.sprite.flip_h and blue.native_facing == -1,"Blue starts natively left-facing")
 var start_frame := blue.sprite.frame
 await create_timer(0.16).timeout
 check(blue.sprite.frame != start_frame,"Idle advances without input or explicit pose transition")
 blue.sprite.pause()
 for index in range(4):
  blue.sprite.frame = index
  var texture := blue.sprite.sprite_frames.get_frame_texture("idle",index)
  check(texture.resource_path.contains("/idle_002/"),"Every Blue idle frame uses the new pipeline output")
  var ground: float = blue.sprite.position.y+(744-384)*blue.sprite.scale.y
  check(abs(ground)<0.001,"Every idle pose retains the ground anchor")
  await capture("blue_frame_%d" % index)
 blue.sprite.play()
 # Movement presses at many points throughout beats 1-4, not near attack timing.
 for bpm in [120,140,160]:
  var d := 60.0/float(bpm)
  for player in range(2):
   for direction in ["left","right"]:
    var sign_value := -1.0 if direction=="left" else 1.0
    var action := "p%d_%s" % [player+1,direction]
    for beat in range(1,5):
     for fraction in [0.05,0.4,0.8]:
      await reset_game(bpm)
      var x: float = game.bout.positions[player]
      time = (beat-1+float(fraction))*d
      await key(action)
      check(game.controls[player].held.get(direction,false),"Real engine event reaches held-direction state")
      check(game.controls[player].input_feedback.begins_with("ACCEPT"),"Movement accepted throughout beats 1-4")
      check(game.bout.positions[player] == x,"No displacement from a key event")
      var next: float = d*beat
      advance(next-0.001)
      check(game.bout.positions[player] == x,"Movement remains queued until eligible boundary")
      advance(next)
      check(game.bout.positions[player] == x+sign_value*Bout.STEP,"One deterministic step at next eligible beat")
      check(game.bout.selections == [-1,-1] and game.bout.hits == [0,0],"Movement-only engine input cannot attack")
      check(game.fighters[player].pose == ("forward_step" if sign_value==game.facing(player) else "backward_step"),"Walking pose matches actual displacement and facing")
    await reset_game(bpm)
    var x: float = game.bout.positions[player]
    time = d-0.02
    await key(action)
    advance(d)
    time = d+0.02
    await key(action,false)
    check(game.bout.positions[player] == x+sign_value*Bout.STEP,"40ms tap spanning a boundary gives one step")
    advance(d*2)
    check(game.bout.positions[player] == x+sign_value*Bout.STEP,"Released tap does not repeat")
    await reset_game(bpm)
    time = d*0.1
    await key(action)
    time = d*0.15
    await key(action,false)
    advance(d)
    check(game.bout.positions[player] == (100.0 if player==0 else 220.0),"Short tap released before beat still cancels by existing rule")
    check(game.controls[player].input_feedback.begins_with("CANCEL"),"Cancelled tap explains why it did not move")
    await reset_game(bpm)
    x = game.bout.positions[player]
    time = d*0.1
    await key(action)
    advance(d)
    advance(d*2)
    advance(d*3)
    check(game.bout.positions[player] == x+sign_value*Bout.STEP*3,"Held key steps on beats 2/3/4")
    advance(d*4)
    check(game.bout.positions[player] == x+sign_value*Bout.STEP*4,"Held key resumes once on next beat 1")
 # Holds survive standoff/pickup and OS-repeat events; execute does not auto-fire.
 for phase in ["menu","standoff","pickup"]:
  await reset_game()
  game.mode = phase
  # Simulate a fresh precombat phase; no combat beat has been consumed yet.
  for control in game.controls: control.reset()
  time = 0.1
  await key("p1_right")
  await key("p2_left")
  check(game.bout.positions == [100.0,220.0],"Precombat directional input cannot move fighters")
  game.mode = "combat"
  game.conductor.start(1.0)
  advance(1.0)
  check(game.bout.positions == [116.0,204.0],"Both precombat holds execute at first combat beat")
  time = 1.1
  await key("p1_right",true,true)
  await key("p2_left",true,true)
  advance(1.5)
  check(game.bout.positions == [132.0,188.0],"Ignored OS repeat cannot erase held movement")
  check(game.bout.selections == [-1,-1],"Precombat holds never become attacks")
 # Real menu-held input is resynchronised when a new bout starts.
 await reset_game()
 game.mode = "menu"
 await key("p1_right")
 await key("p2_left")
 game.max_anticipation_phrases = 1
 game.begin()
 check(game.controls[0].held.get("right",false) and game.controls[1].held.get("left",false),"Bout reset seeds actual physical directions while clearing execute")
 advance(game.cue+0.08)
 await key("p1_execute")
 await key("p1_execute",false)
 time += 0.04
 await key("p2_execute")
 await key("p2_execute",false)
 advance(time)
 check(game.mode == "pickup","Real race still resolves before combat movement")
 advance(game.conductor.epoch)
 check(game.bout.positions == [116.0,204.0],"Countdown-to-race-to-pickup holds visibly move both players at first combat beat")
 check(game.bout.hits == [0,0] and game.bout.selections == [-1,-1],"Race execute does not leak into combat")
 await capture("both_advance")
 # Return independently to idle after walking; retreat visibly on the following eligible beat.
 await key("p1_right",false)
 await key("p2_left",false)
 var epoch: float = game.conductor.epoch
 advance(epoch+0.43)
 check(blue_idle(),"Blue walks back into the new looping idle")
 await capture("after_walk_idle")
 await key("p1_left")
 await key("p2_right")
 advance(epoch+0.5)
 check(game.bout.positions == [100.0,220.0],"P1 A and P2 Right visibly retreat simultaneously")
 await capture("both_retreat")
 # Boundaries reject displacement and walking, without narrowing the movement window.
 await reset_game()
 game.bout.positions.assign([30.0,290.0])
 time = 0.1
 await key("p1_left")
 await key("p2_right")
 advance(0.5)
 check(game.bout.positions == [30.0,290.0],"Arena limits preserved")
 check(game.controls[0].step_feedback.begins_with("REJECT arena") and game.controls[1].step_feedback.begins_with("REJECT arena"),"Boundary rejection is explicit for both players")
 check(game.fighters[0].pose=="combat_idle" and blue_idle(),"Rejected movement does not show phantom walking")
 await key("p1_left",false)
 check(game.controls[0].input_feedback=="RELEASED movement", "Release after a blocked boundary is not misreported as an early tap")
 # New idle resumes after actual high attacks, blocks/parries and hits.
 for attacker in range(2):
  await reset_game()
  game.bout.positions.assign([140.0,180.0])
  game.bout.initiative = attacker
  advance(1.5)
  await key("p1_high")
  await key("p2_high")
  await key("p1_execute")
  await key("p2_execute")
  check(blue.sprite.animation == ("high_attack" if attacker==1 else "high_block"),"Actual combat input presents Blue attack/block")
  advance(1.741)
  check(game.bout.last_event.get("kind")=="PARRY","Existing parry/hitbox rule unchanged")
  advance(2.12)
  check(blue_idle(),"New idle resumes after attack/block/parry recovery")
 await reset_game()
 game.bout.positions.assign([140.0,180.0])
 advance(1.5)
 await key("p1_high")
 await key("p2_low")
 await key("p1_execute")
 await key("p2_execute")
 advance(1.741)
 check(game.bout.last_event.get("kind")=="HIT" and blue.sprite.animation=="high_hit","Blue hit reaction retains existing scoring")
 advance(2.12)
 check(blue_idle(),"New idle resumes after receiving a hit")
 # Independent recovery: idle fighter's movement does not truncate the other's pose.
 await reset_game()
 time=0.1
 await key("p2_left")
 advance(0.5)
 await key("p2_left",false)
 advance(0.94)
 check(blue_idle(),"Only completed Blue walking returns it to idle")
 game.debug_visible = true
 await reset_game()
 time=0.1
 await key("p1_right")
 time=0.12
 await key("p1_right",false)
 advance(0.5)
 game.refresh()
 check(game.input_feedback_label.text.contains("CANCEL"),"F3 displays cancellation reason")
 await capture("feedback_cancel")
 # Focus loss clears held state and explains rejection.
 game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
 game.refresh()
 check(game.input_feedback_label.text.contains("REJECT focus"),"F3 explains focus loss")
 await release_all()
 print("IDLE/MOVEMENT TESTS: %d checks, %d failures" % [checks,failures])
 game.conductor.clock_override = Callable()
 game.queue_free()
 quit(0 if failures==0 else 1)
