extends SceneTree
func _initialize() -> void:
 Bindings.install()
 for action in InputMap.get_actions():
  if action.begins_with("p1_") or action.begins_with("p2_"):
   ProjectSettings.set_setting("input/" + action, {"deadzone": 0.5, "events": InputMap.action_get_events(action)})
 ProjectSettings.save()
 quit()
