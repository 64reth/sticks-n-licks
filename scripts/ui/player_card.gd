class_name ArcadePlayerCard
extends Control
const FONT = preload("res://assets/ui/arcade/arcade.fnt")
const CREAM := Color("f6e3b8")
var player_name: String = "RED"
var team_color := Color("d83a30")
var mirrored: bool = false
var energy: int = 3
var wins: int = 0
var wins_needed: int = 2
var initiative: bool = false
var title := Label.new()

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 title.position = Vector2(6,4)
 title.size = Vector2(84,8)
 title.add_theme_font_override("font",FONT)
 title.add_theme_font_size_override("font_size",8)
 title.add_theme_color_override("font_color",CREAM)
 title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if mirrored else HORIZONTAL_ALIGNMENT_LEFT
 title.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(title)

func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("202323"))
 draw_rect(Rect2(Vector2.ZERO,size),CREAM,false,1)
 for segment in range(3):
  var x := 6+(2-segment if mirrored else segment)*28
  draw_rect(Rect2(x,15,24,6),team_color if segment<energy else Color("42413d"))
  draw_rect(Rect2(x,15,24,6),team_color,false,1)
 for marker in range(wins_needed):
  var x := 6+marker*9 if not mirrored else 85-marker*9
  draw_rect(Rect2(x,26,5,4),CREAM if marker<wins else Color("42413d"))
 if initiative:
  var x := 10.0 if mirrored else size.x-10
  draw_colored_polygon(PackedVector2Array([Vector2(x,4),Vector2(x+3,7),Vector2(x,10),Vector2(x-3,7)]),Color("eec65e"))

func update_card(value: int, round_score: int, needed: int, attacking: bool) -> void:
 energy = value
 wins = round_score
 wins_needed = needed
 initiative = attacking
 title.text = player_name
 queue_redraw()
