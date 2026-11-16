class_name TempoLogo
extends Node2D
var sheet: Texture2D
var frame: int = 0
var display_width: float = 232.0
# The six supplied title renderings differ slightly. Keep approved lettering from
# pose zero fixed, animate only the supplied speaker zones. No exported derivative.
func _ready() -> void:
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 var clean := ShaderMaterial.new()
 clean.shader = preload("res://scripts/effects/source_pixel.gdshader")
 material = clean
func set_frame(index: int) -> void:
 frame = clampi(index,0,5)
 queue_redraw()
func _draw() -> void:
 if sheet==null:return
 var factor := display_width/362.0
 # Same destination mapping for every pose; no per-frame bounding-box scaling.
 for segment in [Rect2(0,250,96,200),Rect2(96,250,172,200),Rect2(268,250,94,200)]:
  var source: Rect2 = segment
  if segment.position.x!=96:source.position.x+=frame*362
  var target := Rect2(((segment.position-Vector2(181,350))*factor).round(),(segment.size*factor).round())
  draw_texture_rect_region(sheet,target,source)
