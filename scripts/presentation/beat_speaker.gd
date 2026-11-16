class_name BeatSpeaker
extends Node2D
# Regions are deliberately irregular: a 362px grid would cut the squash poses.
var sheet: Texture2D
var definition: Dictionary
var display_scale: float = 0.06
var intensity: float = 1.0
var frame: int = 0
var clock_source: Callable
var anchor_time: float = 0.0
var bpm: float = 120.0
func _ready() -> void:
 definition = JSON.parse_string(FileAccess.get_file_as_string("res://data/presentation_sheets.json")).speaker
 sheet = load(definition.texture)
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 var clean := ShaderMaterial.new()
 clean.shader = preload("res://scripts/effects/source_pixel.gdshader")
 material = clean
func sync(musical_seconds: float, tempo: float) -> void:
 var phase := fposmod(maxf(0,musical_seconds)*tempo/60.0,1.0)
 var steps: Array = definition.sequence if intensity>=0.66 else [1,4,0,0,5,0]
 frame = int(steps[mini(5,int(phase*6+0.0000001))]) if intensity>0 else 0
 queue_redraw()
func _process(_delta: float) -> void:
 if visible and clock_source.is_valid():sync(float(clock_source.call())-anchor_time,bpm)
func _draw() -> void:
 if sheet==null:return
 var r: Array = definition.rects[frame]
 var a: Array = definition.anchors[frame]
 var region := Rect2(r[0],r[1],r[2],r[3])
 var factor := display_scale
 # Anchor is a source foot position; local ground never moves with deformation.
 var offset := (region.position-Vector2(a[0],a[1]))*factor
 var target := Rect2(offset.round(),(region.size*factor).round())
 draw_texture_rect_region(sheet,target,region)
