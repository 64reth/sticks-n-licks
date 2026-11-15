extends "res://scripts/main.gd"
func _ready() -> void:
 super._ready()
 debug_visible = true
 max_anticipation_phrases = 1
 begin()

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_1:
   conductor.schedule_tempo(120)
  elif event.keycode == KEY_2:
   conductor.schedule_tempo(140)
  elif event.keycode == KEY_3:
   conductor.schedule_tempo(160)
 super._unhandled_input(event)
