class_name CombatDebugOverlay
extends Node2D
var game: Node2D
func _draw() -> void:
 if game == null:
  return
 var bout: Bout = game.bout
 for player in range(2):
  draw_rect(bout.hurt_region(player), Color(0.2, 0.95, 1, 0.9), false, 1)
 var active: Rect2 = game.active_attack_region()
 if active.has_area():
  draw_rect(active, Color(1, 0.7, 0.15, 0.25))
  draw_rect(active, Color(1, 0.7, 0.15), false, 1)
 if not bout.last_event.is_empty():
  var region: Rect2 = bout.last_event["attack_region"]
  draw_rect(region, Color(1, 0.7, 0.15, 0.4), false, 1)
 var event_text := "READY" if bout.last_event.is_empty() else "LAST " + str(bout.last_event["kind"])
 draw_string(ThemeDB.fallback_font, Vector2(8, 164), "%s · reach %.0f · cyan hurt / orange attack" % [event_text, bout.stick_reach], HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
