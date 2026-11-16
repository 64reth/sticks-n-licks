class_name ImpactEffect
extends Sprite2D
# One bounded reusable sprite. Animation never invokes gameplay callbacks.
var definitions: Dictionary = {}
var textures: Dictionary = {}
var clock_source: Callable
var started: float = -INF
var frame_seconds: float = 0.055
var spawn_count: int = 0
var kind: String = ""
var last_key: String = ""

func _ready() -> void:
 definitions = JSON.parse_string(FileAccess.get_file_as_string("res://data/impacts.json"))
 for key in definitions:
  textures[key] = load(definitions[key].texture)
 hframes = 3
 z_index = 5
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 material = ShaderMaterial.new()
 material.shader = preload("res://scripts/effects/source_pixel.gdshader")
 clear()

func clear() -> void:
 visible = false
 started = -INF
 last_key = ""
 kind = ""

func play_resolved(event: Dictionary, exchange_key: String, at: float) -> bool:
 var value: String = str(event.get("kind", ""))
 if not definitions.has(value) or exchange_key == last_key:
  return false
 var attack: Rect2 = event.get("attack_region", Rect2())
 var hurt: Rect2 = event.get("hurt_region", Rect2())
 var contact := attack.intersection(hurt)
 if not bool(event.get("overlap", false)) or not contact.has_area():
  return false
 last_key = exchange_key
 kind = value
 texture = textures[value]
 var size_px: float = float(definitions[value].display_size)
 scale = Vector2.ONE * size_px / 724.0
 var centre := contact.get_center()
 var margin := ceilf(size_px / 2.0)
 position = Vector2(roundf(clampf(centre.x, margin, 320-margin)), roundf(clampf(centre.y, margin, 180-margin)))
 frame_seconds = maxf(1.0, float(definitions[value].frame_ms)) / 1000.0
 started = at
 frame = 0
 visible = true
 spawn_count += 1
 return true

func advance(at: float) -> void:
 if not visible:return
 var index := int(floor((at-started+0.0000001)/frame_seconds))
 if index >= 3:
  visible = false
 else:
  frame = maxi(0,index)

func _process(_delta: float) -> void:
 if clock_source.is_valid():advance(clock_source.call())
