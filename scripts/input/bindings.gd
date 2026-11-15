class_name Bindings
extends RefCounted
static func install() -> void:
 var keys := {"p1_left": KEY_A, "p1_right": KEY_D, "p1_high": KEY_W, "p1_low": KEY_S, "p1_execute": KEY_F, "p2_left": KEY_LEFT, "p2_right": KEY_RIGHT, "p2_high": KEY_UP, "p2_low": KEY_DOWN, "p2_execute": KEY_SHIFT}
 for action in keys:
  if InputMap.has_action(action):
   continue
  InputMap.add_action(action)
  var event := InputEventKey.new()
  event.physical_keycode = keys[action]
  if action == "p2_execute":
   event.location = KEY_LOCATION_RIGHT
  InputMap.action_add_event(action, event)
