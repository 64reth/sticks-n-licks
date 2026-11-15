class_name Fighter
extends Node2D
var sprite := AnimatedSprite2D.new()
var pose: String = "idle"
var asset_config: String = ""
var color := Color("f3ba55")
const STATES := ["idle", "standoff_anticipation", "false_start", "race_launch", "running", "stick_pickup", "combat_idle", "forward_step", "backward_step", "high_attack", "mid_attack", "low_attack", "high_block", "mid_block", "low_block", "high_parry", "mid_parry", "low_parry", "high_hit", "mid_hit", "low_hit", "stagger", "knockdown", "victory", "defeat"]

func _ready() -> void:
 add_child(sprite)
 var frames := SpriteFrames.new()
 frames.remove_animation("default")
 for state in STATES:
  frames.add_animation(state)
  frames.set_animation_speed(state, 8)
  for index in range(2):
   frames.add_frame(state, placeholder(state, index))
 if not asset_config.is_empty():
  var file := FileAccess.open(asset_config, FileAccess.READ)
  if file:
   var config = JSON.parse_string(file.get_as_text())
   for state in config:
    var path: String = "res://" + str(config[state])
    if ResourceLoader.exists(path):
     var authored := load(path) as SpriteFrames
     if authored and authored.has_animation(state):
      frames.clear(state)
      for index in range(authored.get_frame_count(state)):
       frames.add_frame(state, authored.get_frame_texture(state, index))
      frames.set_animation_speed(state, authored.get_animation_speed(state))
      frames.set_animation_loop(state, authored.get_animation_loop(state))
 sprite.sprite_frames = frames
 set_pose("idle")
 # Geometry is independent of the transparent image.
 var body := Area2D.new()
 var collision := CollisionShape2D.new()
 var shape := RectangleShape2D.new()
 shape.size = Vector2(18, 42)
 collision.shape = shape
 collision.position.y = -21
 body.add_child(collision)
 add_child(body)

func placeholder(state: String, frame: int) -> ImageTexture:
 var img := Image.create(96, 96, false, Image.FORMAT_RGBA8)
 img.fill(Color.TRANSPARENT)
 var bob := frame if state in ["idle", "combat_idle", "running"] else 0
 img.fill_rect(Rect2i(39, 18 + bob, 17, 15), color)
 img.fill_rect(Rect2i(37, 34 + bob, 22, 25), color.darkened(0.2))
 img.fill_rect(Rect2i(38, 59, 7, 19), color)
 img.fill_rect(Rect2i(51, 59, 7, 19), color)
 var stick_y := 42
 if state.begins_with("high"):
  stick_y = 20
 elif state.begins_with("low"):
  stick_y = 65
 if state not in ["idle", "standoff_anticipation", "false_start", "race_launch", "running"]:
  if state.ends_with("block") or state.ends_with("parry"):
   img.fill_rect(Rect2i(66, stick_y - 8, 3, 22), Color("e3c99c"))
  else:
   img.fill_rect(Rect2i(57, stick_y, 28, 3), Color("e3c99c"))
 if state.ends_with("parry") or state == "victory":
  img.fill_rect(Rect2i(69, 12, 3, 16), Color.WHITE)
 if state.ends_with("hit") or state in ["stagger", "defeat", "knockdown"]:
  img.fill_rect(Rect2i(38, 35, 20, 6), Color("ed5565"))
 return ImageTexture.create_from_image(img)

func set_pose(value: String) -> void:
 pose = value
 if sprite.sprite_frames and sprite.sprite_frames.has_animation(value):
  sprite.play(value)
