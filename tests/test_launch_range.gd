extends SceneTree
var game: Node2D
var time: float = 0.0
var checks: int = 0
var failures: int = 0

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)

func _initialize() -> void:
 call_deferred("run")

func key(action: String, down: bool = true) -> void:
 var event: InputEventKey = InputMap.action_get_events(action)[0].duplicate()
 event.pressed = down
 game._unhandled_input(event)

func advance(at: float) -> void:
 time = at
 game._process(1.0)

func reset_combat(left: float, right: float, attacker: int = 0, bpm: int = 120) -> void:
 game.bout = Bout.new()
 game.bout.stick_reach = float(game.settings["stick_reach"])
 game.bout.positions.assign([left, right])
 game.bout.initiative = attacker
 game.mode = "combat"
 game.phrase_resolved = false
 game.exchange_phrase = 0
 game.selected.assign([-1, -1])
 game.previous_bpm = bpm
 for player in range(2):
  game.controls[player].reset()
  game.fighters[player].set_pose("combat_idle")
  game.fighters[player].whiff_time = 0
  game.fighters[player].flash_time = 0
  game.fighters[player].spark_time = 0
 time = 0
 game.conductor.start(0)
 game.conductor.bpm = bpm
 game.conductor.pending_bpm = bpm
 advance(0)

func execute(height: int, block: int, defender_error_ms: float = 0) -> void:
 var attacker: int = game.bout.initiative
 var defender := 1 - attacker
 var forward := "right" if game.facing(attacker) > 0 else "left"
 key("p%d_%s" % [attacker+1, ["high", forward, "low"][height]])
 key("p%d_execute" % (attacker+1))
 if block >= 0:
  time += defender_error_ms / 1000.0
  var defense_forward := "right" if game.facing(defender) > 0 else "left"
  key("p%d_%s" % [defender+1, ["high", defense_forward, "low"][block]])
  key("p%d_execute" % (defender+1))

func capture(name: String) -> void:
 if DisplayServer.get_name() == "headless":
  return
 game.combat_debug.visible = game.debug_visible
 game.combat_debug.queue_redraw()
 game.refresh()
 game.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/range_%s.png" % name)

func run() -> void:
 game = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 game.conductor.clock_override = func(): return time
 root.add_child(game)
 game.set_process(false)
 # Inspect the actual initial menu BEFORE selecting any pose (the previous test blind spot).
 check(game.mode == "menu", "Configured root scene launches to menu")
 check(ProjectSettings.get_setting("display/window/size/viewport_width") == 320 and ProjectSettings.get_setting("display/window/size/viewport_height") == 180, "Viewport remains 320x180")
 check(game.find_children("*", "Camera2D").is_empty(), "No unexpected camera zoom")
 check(game.scale == Vector2.ONE, "Main scene has no hidden scaling")
 for player in range(2):
  var fighter: Fighter = game.fighters[player]
  var meta: Dictionary = fighter.animation_meta["idle"]
  check(fighter.pose == "idle" and fighter.sprite.animation == "idle", "Actual launch pose is idle")
  check(fighter.sprite.scale.is_equal_approx(Vector2.ONE * float(meta["scale"])), "Launch applies idle scale before any transition")
  check(fighter.scale == Vector2.ONE, "Visual scale does not alter fighter/hitbox root")
  check(fighter.position == Vector2(100+120*player, 150), "Initial left/right and ground positions")
  check(not fighter.sprite.flip_h, "Native Red-right/Blue-left is not double-mirrored")
  check(fighter.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Nearest-neighbour filtering")
 await capture("launch")
 # Verify every frame on the actual playable actor, not an independent preview instance.
 for player in range(2):
  var fighter: Fighter = game.fighters[player]
  for state in fighter.animation_meta:
   fighter.set_pose(state)
   var meta: Dictionary = fighter.animation_meta[state]
   var factor := float(meta["scale"])
   check(fighter.sprite.scale.is_equal_approx(Vector2.ONE * factor), "Animation always uses its authored display transform")
   var ground := fighter.sprite.position.y + (float(meta["ground_pixel"])-384) * factor
   check(abs(ground) < 0.001, "Ground anchor is independent of animation state")
   var frames := fighter.sprite.sprite_frames
   for frame in range(frames.get_frame_count(state)):
    var texture := frames.get_frame_texture(state, frame)
    var occupied := texture.get_image().get_used_rect()
    var size := Vector2(occupied.size) * factor
    check(size.y > 35 and size.y < 90 and size.x < 115, "Rendered body proportions stay readable, never sheet-sized")
    var origin := fighter.global_position + fighter.sprite.position + (Vector2(occupied.position)-texture.get_size()/2) * factor
    check(origin.x >= -1 and origin.y >= -1 and origin.x+size.x <= 321 and origin.y+size.y <= 181, "Every launch-position pose fits in the playable viewport")
   # Re-selecting the same pose must repair transforms but not restart playback.
   fighter.sprite.frame = frames.get_frame_count(state)-1
   fighter.sprite.scale = Vector2.ONE
   fighter.set_pose(state)
   check(fighter.sprite.scale.is_equal_approx(Vector2.ONE * factor) and fighter.sprite.frame == frames.get_frame_count(state)-1, "Same-pose call applies metadata without resetting frame")
  fighter.set_pose("idle")
  check(fighter.hurtbox_shape.shape.size == Bout.HURTBOX.size, "Attached hurtbox matches gameplay geometry")
 # Shared reach has exactly the same boundary at every height and from either facing.
 for player in range(2):
  for gap in [40.0,52.999,53.0,53.001,120.0,260.0]:
   reset_combat(30,30+gap,player)
   for height in range(3):
    check(game.bout.in_reach(player,height) == (gap<=53.0), "All heights share identical stick reach and inclusive overlap boundary")
 # Exercise scene input -> beat-four snapshot -> buffered adjudication at every BPM.
 for bpm in [120,140,160]:
  for attacker in range(2):
   for height in range(3):
    reset_combat(30,290,attacker,bpm)
    var target: float = game.conductor.action_time()
    advance(target)
    execute(height,height)
    check(game.active_attack_region().has_area(), "Valid input activates a beat-four attack region")
    advance(target+0.241)
    check(game.bout.last_event.get("kind") == "WHIFF" and game.bout.hits == [0,0], "Across-arena attack cannot hit or parry")
    check(game.bout.initiative == 1-attacker and game.bout.defensive_streak == 0, "Range whiff passes initiative without a defensive success")
    check(not game.active_attack_region().has_area(), "Active region closes after adjudication")
    reset_combat(30,290,attacker,bpm)
    advance(target)
    execute(height,height,90)
    advance(target+0.241)
    check(game.bout.last_event.get("kind") == "WHIFF" and game.bout.hits == [0,0], "Out-of-range good block cannot register")
    check(game.bout.defensive_streak == 0, "Distant defence cannot escalate tempo")
    var expected: Array[int] = [0,0]
    expected[attacker] = 1
    for block in [-1, (height+1)%3, height]:
     reset_combat(140,180,attacker,bpm)
     advance(target)
     execute(height,block)
     advance(target+0.241)
     var kind := "PARRY" if block==height else "HIT"
     check(game.bout.last_event.get("kind") == kind, "Close-range height/defence interaction")
     check(game.bout.hits == ([0,0] if block==height else expected), "Only clean reachable strikes score")
     var score: Array = game.bout.hits.duplicate()
     var initiative: int = game.bout.initiative
     game.resolve_exchange()
     check(game.bout.hits == score and game.bout.initiative == initiative, "Scene prevents double adjudication")
     game.bout.resolve(game.conductor,game.exchange_phrase)
     check(game.bout.hits == score and game.bout.initiative == initiative, "Gameplay rules independently prevent duplicate hit/parry")
    reset_combat(140,180,attacker,bpm)
    advance(target)
    execute(height,height,90)
    advance(target+0.241)
    check(game.bout.last_event.get("kind") == "BLOCK" and game.bout.initiative == attacker, "Good block in reach retains initiative")
 # Reach is read from configuration at bout start, with no height-specific override.
 var original_reach: float = game.settings["stick_reach"]
 game.settings["stick_reach"] = 80.0
 game.begin()
 check(game.bout.stick_reach == 80.0, "New bouts read configurable stick_reach")
 game.bout.positions.assign([100.0,180.0])
 for height in range(3):
  check(game.bout.in_reach(0,height), "Changing the shared reach affects every height equally")
 game.settings["stick_reach"] = original_reach
 reset_combat(140,180)
 advance(1.4)
 execute(0,-1)
 check(not game.active_attack_region().has_area(), "Windup does not activate attack collision before beat four")
 advance(1.5)
 check(game.active_attack_region().has_area(), "Active hitbox begins on beat four")
 # Movement: start just outside reach, advance one beat into range, retreat back out.
 reset_combat(100,156)
 check(not game.bout.in_reach(0,0), "56px gap starts outside stick range")
 time=0.1
 key("p1_right")
 advance(0.5)
 check(game.bout.in_reach(0,0), "Beat-locked advance establishes contact")
 key("p1_right",false)
 key("p1_left")
 advance(1.0)
 check(not game.bout.in_reach(0,0), "Beat-locked retreat removes contact")
 advance(1.5)
 execute(1,1)
 advance(1.741)
 check(game.bout.hits == [0,0] and game.bout.last_event.get("kind") == "WHIFF", "Retreat prevents damage and parry")
 # Contacts are sampled at beat four, not from interpolated sprites or later state.
 reset_combat(30,290)
 advance(1.5)
 execute(0,-1)
 game.bout.positions.assign([140.0,180.0])
 advance(1.741)
 check(game.bout.last_event.get("kind") == "WHIFF", "Late visual/logical changes cannot turn beat-four whiff into a hit")
 reset_combat(140,180)
 advance(1.5)
 execute(0,-1)
 game.bout.positions.assign([30.0,290.0])
 advance(1.741)
 check(game.bout.last_event.get("kind") == "HIT", "Beat-four overlap remains authoritative through late-input grace")
 reset_combat(30,290)
 advance(1.741)
 check(game.fighters[0].pose == "combat_idle" and game.fighters[0].whiff_time == 0, "No execute input must not invent an attack animation")
 # Capture both active geometry and whiff feedback from the playable scene.
 reset_combat(30,290)
 game.debug_visible = true
 advance(1.5)
 execute(0,0)
 await capture("active_far")
 advance(1.741)
 check(game.fighters[0].pose == "high_attack" and game.fighters[0].whiff_time > 0, "Attempted whiff uses existing attack recovery feedback")
 await capture("whiff")
 reset_combat(140,180)
 advance(1.5)
 execute(1,2)
 await capture("active_near")
 advance(1.741)
 await capture("hit")
 game.debug_visible = false
 # Full standoff -> race -> approach -> three hits -> victory -> Enter rematch, for both winners.
 for winner in range(2):
  time = 0
  game.max_anticipation_phrases = 1
  game.begin()
  var race_winner := 1-winner # Empty opening exchange passes initiative during approach.
  advance(game.cue+0.08)
  key("p%d_execute" % (race_winner+1))
  key("p%d_execute" % (race_winner+1),false)
  time += 0.04
  key("p%d_execute" % (winner+1))
  key("p%d_execute" % (winner+1),false)
  advance(time)
  check(game.mode == "pickup" and game.bout.initiative == race_winner and game.bout.hits == [0,0], "Authoritative race still grants initiative without damage")
  advance(game.conductor.epoch)
  var epoch: float = game.conductor.epoch
  time = epoch+0.1
  key("p1_right")
  key("p2_left")
  advance(epoch+0.5)
  advance(epoch+1.0)
  advance(epoch+2.0)
  check(game.bout.in_reach(winner,0) and game.bout.initiative == winner, "Players approach on eligible beats before landing hits")
  for strike in range(3):
   var target: float = game.conductor.action_time()
   advance(target)
   execute(0,2)
   key("p1_execute",false)
   key("p2_execute",false)
   advance(target+0.241)
   check(game.bout.hits[winner] == strike+1, "Reachable clean strike scores exactly once")
   if strike<2:
    advance(game.conductor.phrase_start+game.conductor.duration()*4)
  check(game.mode == "finishing" and game.bout.winner == winner, "Either player reaches three-hit victory")
  await create_timer(0.95).timeout
  check(game.mode == "victory", "Victory animation sequence completes independently of scoring")
  await capture("winner_p%d" % (winner+1))
  var enter := InputEventKey.new()
  enter.keycode = KEY_ENTER
  enter.pressed = true
  game._unhandled_input(enter)
  check(game.mode == "standoff" and game.bout.hits == [0,0] and game.bout.winner == -1 and game.conductor.bpm == 120, "Enter rematch resets complete bout")
 print("LAUNCH/RANGE TESTS: %d checks, %d failures" % [checks,failures])
 game.conductor.clock_override = Callable()
 game.queue_free()
 quit(0 if failures==0 else 1)
