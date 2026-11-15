class_name CombatInput
extends RefCounted
# Per-player event state. No gameplay positions are changed here.
var combination_ms: float = 100.0
var held: Dictionary = {}
var pressed_at: Dictionary = {}
var pending_execute: float = -INF
var last_movement_beat: String = ""
var last_step_time: float = -INF
var last_step_processed: float = -INF
var last_step_evaluated: float = -INF
var queued: int = 0
var input_feedback: String = "READY"
var step_feedback: String = "No step yet"

func reset() -> void:
 held.clear()
 pressed_at.clear()
 pending_execute = -INF
 last_movement_beat = ""
 last_step_time = -INF
 last_step_processed = -INF
 last_step_evaluated = -INF
 queued = 0
 input_feedback = "READY"
 step_feedback = "No step yet"

func direction(at: float, facing: int) -> int:
 var choice := -1
 var latest := -INF
 var names: Array[String] = ["high", "right" if facing > 0 else "left", "low"]
 for height in range(3):
  var key := names[height]
  var when: float = pressed_at.get(key, -INF)
  if (held.get(key, false) or at - when <= combination_ms / 1000.0 + 0.000000001) and when > latest:
   choice = height
   latest = when
 return choice

func movement() -> int:
 var left: bool = held.get("left", false)
 var right: bool = held.get("right", false)
 queued = int(right) - int(left)
 return queued

func feed(action: String, pressed: bool, at: float, facing: int, allow_combinations: bool = true) -> Dictionary:
 if pressed == bool(held.get(action, false)):
  return {}
 held[action] = pressed
 if not pressed:
  movement()
  if action in ["left", "right"]:
   input_feedback = "CANCEL released before beat" if float(pressed_at.get(action, -INF)) > last_step_evaluated else "RELEASED movement"
  return {}
 pressed_at[action] = at
 if action == "execute" and allow_combinations:
  pending_execute = at
 movement()
 if action in ["left", "right"]:
  input_feedback = "ACCEPT queued " + action
  if held.get("left", false) and held.get("right", false):
   input_feedback = "REJECT opposing directions"
 elif action == "execute":
  input_feedback = "WAIT direction + execute"
 else:
  input_feedback = "ACCEPT " + action
 if not allow_combinations:
  pending_execute = -INF
  return {}
 if at - pending_execute > combination_ms / 1000.0 + 0.000000001:
  pending_execute = -INF
  return {}
 var height := direction(at, facing)
 if height < 0:
  return {}
 var result := {"height": height, "execute_at": pending_execute}
 pending_execute = -INF
 return result

func step(beat: int, phrase: int) -> int:
 # Called only from the conductor boundary signal; accept all four boundaries, reject invalid/repeated beats.
 if beat < 1 or beat > 4:
  queued = 0
  step_feedback = "REJECT invalid beat"
  return 0
 var identity := "%d:%d" % [phrase, beat]
 if identity == last_movement_beat:
  step_feedback = "REJECT duplicate beat"
  return 0
 last_movement_beat = identity
 var direction_value := movement()
 if direction_value != 0:
  step_feedback = "ACCEPT step beat%d" % beat
 elif held.get("left", false) or held.get("right", false):
  step_feedback = "REJECT opposing directions"
 else:
  step_feedback = "NO STEP direction not held"
 return direction_value
