extends SceneTree
var checks: int = 0
var failures: int = 0
var time: float = 10.0
var game: Node2D

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)

func _initialize() -> void:
 call_deferred("run")

func reset_game(bpm: int = 120) -> void:
 game.bout = Bout.new()
 for control in game.controls:
  control.reset()
 time = 10.0
 game.conductor.start(time)
 game.conductor.bpm = bpm
 game.conductor.pending_bpm = bpm
 game.mode = "combat"
 game.phrase_resolved = false
 game.selected.assign([-1, -1])
 game.previous_bpm = bpm
 game.conductor.update(time)

func advance(at: float) -> void:
 time = at
 game.conductor.update(at)

func key(action: String, down: bool = true) -> void:
 # Use Godot's actual configured physical-key events, not action-name stand-ins.
 var event: InputEventKey = InputMap.action_get_events(action)[0].duplicate()
 event.pressed = down
 game._unhandled_input(event)

func run() -> void:
 var scene := load(ProjectSettings.get_setting("application/run/main_scene")) as PackedScene
 game = scene.instantiate()
 game.preferences_path=""
 game.game_mode="pvp"
 game.conductor.clock_override = func(): return time
 root.add_child(game)
 game.preferences.values.game_mode=game.game_mode
 game.set_process(false)
 game.metronome_enabled = false
 game.audio.enabled = false
 game.audio.stop()
 game.conductor.clock_override = func(): return time
 for player in range(2):
  var prefix := "p%d_" % (player + 1)
  var forward := "right" if player == 0 else "left"
  var sign_value := 1.0 if player == 0 else -1.0
  for height in range(3):
   reset_game()
   advance(11.3)
   var action: String = ["high", forward, "low"][height]
   key(prefix + action)
   advance(11.5)
   key(prefix + "execute")
   check(game.bout.selections[player] == height, "Physical keys select all heights for P%d" % (player+1))
   check(game.conductor.grade(game.bout.errors[player]) == "perfect", "Held direction + execute preserves timestamp")
   var position: float = game.bout.positions[player]
   advance(12.0)
   check(game.bout.positions[player] == position, "Held combat direction does not auto-repeat movement")
  # Execute first, direction within 100 ms: grade EXECUTE, not late direction.
  reset_game()
  advance(11.5)
  key(prefix + "execute")
  check(is_inf(game.bout.errors[player]), "Execute alone cannot choose default MID")
  time = 11.6
  key(prefix + forward)
  check(game.bout.selections[player] == 1 and abs(game.bout.errors[player]) < 0.001, "100ms execute-first chord uses original execute timestamp")
  reset_game()
  advance(11.5)
  key(prefix + "execute")
  time = 11.601
  key(prefix + forward)
  check(is_inf(game.bout.errors[player]), "Combo beyond 100ms rejected")
  reset_game()
  advance(11.4)
  key(prefix + "low")
  key(prefix + "low", false)
  time = 11.5
  key(prefix + "execute")
  check(game.bout.selections[player] == 2, "Direction-first 100ms buffer supports quick taps")
  # Verify facing-relative combat selection separately from invalid crossed positions.
  var reverse := CombatInput.new()
  var reversed_forward := "left" if player==0 else "right"
  reverse.feed(reversed_forward,true,11.5,-int(sign_value))
  var reversed_combo := reverse.feed("execute",true,11.5,-int(sign_value))
  check(reversed_combo.get("height")==1,"MID follows reversed fighter facing")
  # Valid combat timing endpoints, including buffered late direction.
  for error in [-140.0, -70.0, 70.0, 140.0, 141.0]:
   reset_game()
   advance(11.0)
   key(prefix + "high")
   time = 11.5 + error / 1000.0
   key(prefix + "execute")
   var expected := "perfect" if abs(error) <= 70 else ("good" if abs(error) <= 140 else "miss")
   check(game.conductor.grade(game.bout.errors[player]) == expected, "Inclusive revised timing window")
  reset_game()
  advance(11.64)
  key(prefix + "execute")
  time = 11.74
  key(prefix + "high")
  check(game.bout.selections[player] == 0 and game.conductor.grade(game.bout.errors[player]) == "good", "Late valid execute can finish 100ms combination")
 # Race uses the same physical execute buttons, without requiring a direction.
 reset_game()
 game.mode = "standoff"
 game.cue = 10.5
 time = 10.4
 key("p1_execute")
 check(game.bout.false_starts[0], "P1 F before cue is a false start")
 time = 10.6
 key("p2_execute")
 check(is_equal_approx(game.bout.reactions[1], 0.1), "P2 Right Shift records valid race reaction")
 check(game.bout.resolve_race() == 1 and game.bout.hits == [0,0], "Race initiative and no race damage preserved")
 # Right Shift only, obsolete controls removed, valid main scene retained.
 check(not InputMap.has_action("p1_mid") and not InputMap.has_action("p2_mid"), "No obsolete MID actions")
 var right_shift := InputEventKey.new()
 right_shift.physical_keycode = KEY_SHIFT
 right_shift.location = KEY_LOCATION_RIGHT
 right_shift.pressed = true
 check(right_shift.is_action_pressed("p2_execute"), "Right Shift executes for P2")
 right_shift.location = KEY_LOCATION_LEFT
 check(not right_shift.is_action_pressed("p2_execute"), "Left Shift does not execute for P2")
 game.refresh()
 if DisplayServer.get_name() != "headless":
  for player in range(2):
   game.fighters[player].position = Vector2(game.bout.positions[player],150)
  game.debug_visible = true
  game.refresh()
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://output/controls-001b.png")
 print("CONTROL TESTS: %d checks, %d failures" % [checks, failures])
 game.conductor.clock_override = Callable()
 game.queue_free()
 quit(0 if failures == 0 else 1)
