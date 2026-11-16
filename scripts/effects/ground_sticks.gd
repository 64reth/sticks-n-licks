class_name GroundSticks
extends Sprite2D
# Ownership is fighter index, never whichever stick was drawn last.
enum State { BOTH_ON_GROUND, LEFT_ONLY, RIGHT_ONLY, NONE }
var state: State = State.BOTH_ON_GROUND

func _ready() -> void:
 texture = preload("res://assets/environments/props/ground_sticks_states.png")
 hframes = 3
 scale = Vector2.ONE * (48.0 / 724.0)
 position = Vector2(160, 135)
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 material = ShaderMaterial.new()
 material.shader = preload("res://scripts/effects/source_pixel.gdshader")
 set_collected(false, false)

func set_collected(left: bool, right: bool) -> void:
 state = State.NONE if left and right else (State.RIGHT_ONLY if left else (State.LEFT_ONLY if right else State.BOTH_ON_GROUND))
 visible = state != State.NONE
 # Cell 1 rises from the left fighter towards centre; cell 2 belongs to right.
 frame = 0 if state == State.BOTH_ON_GROUND else (1 if state == State.LEFT_ONLY else 2)
