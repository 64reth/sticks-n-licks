class_name StoryOverlay
extends Control
var story: StorySession
const FONT=preload("res://assets/ui/arcade/arcade.fnt")
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func text(value: String, at: Vector2, color: Color=Color("ffe2a0")) -> void:
 for p in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)]:draw_string(FONT,at+p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("172235"))
 draw_string(FONT,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,8,color)
func _draw() -> void:
 if not story:return
 text("RENT DUE!",Vector2(8,12))
 if story.phase in ["cinematic","waiting"]:text("ENTER SKIP" if story.phase=="cinematic" else "READY ON THE NEXT BEAT",Vector2(8,25))
 else:text("A/D STEP   S DUCK",Vector2(8,25))
 for i in range(4):draw_rect(Rect2(136+i*12,164,8,5),Color("ffe2a0") if story.game.conductor.beat==i+1 else Color("172235"))
 if story.phase=="playing" and story.game.game_time()<story.control.movement_feedback_until:text(story.control.movement_grade.to_upper(),Vector2(136,157))
 if story.game.debug_visible:
  draw_rect(Rect2(4,32,312,27),Color("172235"))
  text("%s B%d:%d X%.0f %s %+.0fMS" % [story.player_state(),story.game.conductor.phrase,story.game.conductor.beat,story.target_x,story.control.movement_grade.to_upper(),story.control.movement_error_ms],Vector2(8,43))
  text("F6 REPLAY  F7 RESTART  F8 SKIP",Vector2(8,55))
