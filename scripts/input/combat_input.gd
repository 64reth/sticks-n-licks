class_name CombatInput
extends RefCounted
# Per-player event state. No gameplay positions are changed here.
var combination_ms: float = 100.0
var held: Dictionary = {}
var pressed_at: Dictionary = {}
var pending_execute: float = -INF
var suppressed: Dictionary = {}
var last_movement_beat: String = ""
var last_step_time: float = -INF
var last_step_processed: float = -INF
var queued: int = 0

func reset() -> void:
 held.clear()
 pressed_at.clear()
 pending_execute = -INF
 suppressed.clear()
 last_movement_beat = ""
 last_step_time = -INF
 last_step_processed = -INF
 queued = 0

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
 var left: bool = held.get("left", false) and not suppressed.get("left", false)
 var right: bool = held.get("right", false) and not suppressed.get("right", false)
 queued = int(right) - int(left)
 return queued

func suppress_movement() -> void:
 for key in ["left", "right"]:
  if held.get(key, false):
   suppressed[key] = true
 movement()

func feed(action: String, pressed: bool, at: float, facing: int) -> Dictionary:
 if pressed == bool(held.get(action, false)):
  return {}
 held[action] = pressed
 if not pressed:
  suppressed.erase(action)
  movement()
  return {}
 pressed_at[action] = at
 if action == "execute":
  pending_execute = at
 movement()
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
 # Called only from the conductor boundary signal; defensively reject beat 4/repeats.
 if beat < 1 or beat > 3:
  queued = 0
  return 0
 var identity := "%d:%d" % [phrase, beat]
 if identity == last_movement_beat:
  return 0
 last_movement_beat = identity
 return movement()
