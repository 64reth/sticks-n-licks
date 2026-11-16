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
var latest_horizontal: String = "right"
var pending_move: int = 0
var pending_target: Dictionary = {}
var movement_target: Dictionary = {}
var movement_input_at: float = 0.0
var movement_error_ms: float = 0.0
var movement_grade: String = "READY"
var movement_executed: bool = false
var movement_feedback_until: float = 0.0
var queued: int = 0
var input_feedback: String = "READY"
var step_feedback: String = "No step yet"

func reset() -> void:
 pending_target.clear()
 movement_target.clear()
 movement_grade = "READY"
 movement_executed = false
 movement_feedback_until = 0.0
 held.clear()
 pressed_at.clear()
 pending_execute = -INF
 last_movement_beat = ""
 last_step_time = -INF
 last_step_processed = -INF
 last_step_evaluated = -INF
 latest_horizontal = "right"
 pending_move = 0
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
 queued = pending_move
 return queued

func request_movement(action: String, at: float, clock: RhythmConductor, perfect: float, good: float) -> void:
 movement_input_at = at
 movement_target = clock.nearest_beat(clock.timestamp(at))
 movement_error_ms = (clock.timestamp(at)-float(movement_target.time))*1000.0
 movement_executed = false
 movement_feedback_until = at+0.55
 movement_grade = "perfect" if absf(movement_error_ms)<=perfect+0.000001 else ("good" if absf(movement_error_ms)<=good+0.000001 else "miss")
 if movement_grade=="miss" or str(movement_target.id)==last_movement_beat:
  movement_grade = "miss"
  input_feedback = "MISS outside window" if str(movement_target.id)!=last_movement_beat else "MISS beat already consumed"
  return
 pending_target = movement_target.duplicate()
 pending_move = -1 if action=="left" else 1
 queued = pending_move
 input_feedback = "ACCEPT "+movement_grade+" tap"


func feed(action: String, pressed: bool, at: float, facing: int, allow_combinations: bool = true) -> Dictionary:
 if pressed == bool(held.get(action, false)):
  return {}
 held[action] = pressed
 if not pressed:
  movement()
  if action in ["left", "right"]:
   input_feedback = "RELEASE tap retained" if pending_move != 0 else "RELEASED movement"
  return {}
 pressed_at[action] = at
 if action in ["left", "right"]:latest_horizontal = action
 if action == "execute" and allow_combinations:
  pending_execute = at
 movement()
 if action in ["left", "right"]:
  input_feedback = "ACCEPT queued " + action
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
 if beat<1 or beat>4:return 0
 var identity := "%d:%d" % [phrase,beat]
 if identity==last_movement_beat or pending_move==0 or str(pending_target.get("id",""))!=identity:return 0
 last_movement_beat = identity
 var result := pending_move
 pending_move = 0
 queued = 0
 movement_executed = true
 step_feedback = "EXECUTED "+identity
 return result
