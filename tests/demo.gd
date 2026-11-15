extends "res://scripts/main.gd"
# Deterministic demonstration clock only; production uses monotonic/audio time.
var demo_time: float = 0.0
var exchanges: int = 0
var acted_phrase: int = -1
var moving_phrase: int = -1
var restart_checked: bool = false
var victory_seen: bool = false
var captured_combat: bool = false
func _ready() -> void:
 conductor.clock_override = func(): return demo_time
 super._ready()
 max_anticipation_phrases = 1
 debug_visible = not OS.get_cmdline_user_args().has("--capture-combat")
 begin()

func press(action: String, down: bool = true) -> void:
 var event := InputEventAction.new()
 event.action = action
 event.pressed = down
 _unhandled_input(event)

func _process(delta: float) -> void:
 demo_time += delta
 super._process(delta)
 if mode == "race":
  if demo_time >= cue + 0.08:
   press("p1_execute")
   press("p1_execute", false)
  if demo_time >= cue + 0.12:
   press("p2_execute")
   press("p2_execute", false)
 if mode == "combat":
  if moving_phrase != conductor.phrase and conductor.beat == 1:
   press("p1_right")
   press("p2_left")
   moving_phrase = conductor.phrase
  if conductor.beat <= 3:
   press("p1_high")
   press("p2_high", exchanges < 3)
   press("p2_low", exchanges >= 3)
  if conductor.beat == 4 and acted_phrase != conductor.phrase:
   press("p1_execute")
   press("p2_execute")
   press("p1_execute", false)
   press("p2_execute", false)
   acted_phrase = conductor.phrase
   exchanges += 1
   if not captured_combat and OS.get_cmdline_user_args().has("--capture-combat"):
    captured_combat = true
    capture_combat.call_deferred()
 if mode == "victory" and not victory_seen:
  victory_seen = true
  print("DEMO: reached three-hit victory; exchanges=", exchanges, "; BPM=", conductor.bpm)
  refresh()
  if DisplayServer.get_name() != "headless":
   get_viewport().get_texture().get_image().save_png("res://output/victory.png")
  await get_tree().create_timer(0.5).timeout
  begin()
  restart_checked = true
  print("DEMO: rematch reset; hits=", bout.hits, "; BPM=", conductor.bpm)
  if OS.get_cmdline_user_args().has("--verify-demo"):
   get_tree().quit(0)

func _exit_tree() -> void:
 conductor.clock_override = Callable()

func capture_combat() -> void:
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://output/combat-002.png")
