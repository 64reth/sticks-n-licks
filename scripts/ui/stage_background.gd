class_name StageBackground
extends Node2D
var entries: Array = []
var selected: int = 0
var texture: Texture2D
var destination := Rect2()
func _ready() -> void:
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/stages.json"))
 entries = available_entries(config.stages)
 var initial := 0
 for index in range(entries.size()):
  if entries[index].id==config.get("default","stage_01"):initial=index
 select_stage(initial)
func select_stage(index: int) -> void:
 if entries.is_empty():
  texture=null
  queue_redraw()
  return
 selected = posmod(index,entries.size())
 texture = load("res://"+str(entries[selected].path)) as Texture2D
 if texture:
  var factor := maxf(320.0/texture.get_width(),180.0/texture.get_height())
  var extent := texture.get_size()*factor
  destination = Rect2((Vector2(320,180)-extent)/2.0,extent)
 queue_redraw()
func _draw() -> void:
 if texture:draw_texture_rect(texture,destination,false)

static func available_entries(candidates: Array) -> Array:
 var valid: Array=[]
 for entry in candidates:
  var path: String="res://"+str(entry.get("path",""))
  if ResourceLoader.exists(path) and load(path) is Texture2D:valid.append(entry)
 return valid
