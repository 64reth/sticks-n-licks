class_name StageBackground
extends Node2D
var entries: Array = []
var selected: int = 0
var texture: Texture2D
var destination := Rect2()
func _ready() -> void:
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/stages.json"))
 entries = config.stages
 var initial := 0
 for index in range(entries.size()):
  if entries[index].id==config.get("default","stage_01"):initial=index
 select_stage(initial)
func select_stage(index: int) -> void:
 selected = posmod(index,entries.size())
 texture = load("res://"+str(entries[selected].path)) as Texture2D
 if texture:
  var factor := maxf(320.0/texture.get_width(),180.0/texture.get_height())
  var extent := texture.get_size()*factor
  destination = Rect2((Vector2(320,180)-extent)/2.0,extent)
 queue_redraw()
func _draw() -> void:
 if texture:draw_texture_rect(texture,destination,false)
