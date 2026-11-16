class_name Fighter
extends Node2D
var final_locked: bool=false
var visual_priority: int=0
var visual_until: float=-INF
var clock_source: Callable
var sprite := AnimatedSprite2D.new()
var pose: String = "idle"
var asset_config: String = ""
var animation_meta: Dictionary = {}
var native_facing: int = 1
var looking: int = 1
var spark_time: float = 0.0
var flash_time: float = 0.0
var hurtbox := Area2D.new()
var hurtbox_shape := CollisionShape2D.new()
var whiff_time: float = 0.0
var color := Color("f3ba55")
const STATES := ["idle", "standoff_anticipation", "false_start", "race_launch", "running", "stick_pickup", "combat_idle", "forward_step", "backward_step", "high_attack", "mid_attack", "low_attack", "high_block", "mid_block", "low_block", "high_parry", "mid_parry", "low_parry", "high_hit", "mid_hit", "low_hit", "stagger", "knockdown", "victory", "defeat"]

func _ready() -> void:
 add_child(sprite)
 sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 sprite.position.y = -30
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
   var entries: Dictionary = config.get("animations", config)
   native_facing = -1 if config.get("native_facing", "right") == "left" else 1
   for state in entries:
    var entry = entries[state]
    var path: String = "res://" + str(entry.get("resource", "") if entry is Dictionary else entry)
    if entry is Dictionary:
     animation_meta[state] = entry
    if ResourceLoader.exists(path):
     var authored := load(path) as SpriteFrames
     var source_state: String=str(entry.get("source_animation",state)) if entry is Dictionary else state
     if authored and authored.has_animation(source_state):
      if not frames.has_animation(state):
       frames.add_animation(state)
      frames.clear(state)
      for index in range(authored.get_frame_count(source_state)):
       frames.add_frame(state, authored.get_frame_texture(source_state, index))
      frames.set_animation_speed(state, authored.get_animation_speed(source_state))
      frames.set_animation_loop(state, authored.get_animation_loop(source_state))
 sprite.sprite_frames = frames
 set_pose("idle")
 # This visible/inspectable hurtbox mirrors the same gameplay geometry used by Bout.
 hurtbox.name = "Hurtbox"
 hurtbox.collision_layer = 2
 hurtbox.collision_mask = 0
 hurtbox.monitoring = false
 var shape := RectangleShape2D.new()
 shape.size = Bout.HURTBOX.size
 hurtbox_shape.shape = shape
 hurtbox.add_child(hurtbox_shape)
 add_child(hurtbox)
 hurtbox.position = Bout.HURTBOX.get_center()

func sync_hurtbox(logical_ground: Vector2) -> void:
 # Visual interpolation must not move the authoritative receiving region off its grid position.
 hurtbox.global_position = logical_ground + Bout.HURTBOX.get_center()

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

func face(direction: int) -> void:
 looking = direction
 sprite.flip_h = direction != native_facing

func set_pose(value: String) -> void:
 if final_locked and value!=pose:return
 if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(value):
  return
 # SpriteFrames can auto-select idle when assigned. Always apply its metadata,
 # even if this animation is already selected; only playback restart is conditional.
 if animation_meta.has(value):
  var meta: Dictionary = animation_meta[value]
  var factor := float(meta["scale"])
  sprite.scale = Vector2.ONE * factor
  sprite.position = Vector2(0, (float(meta["canvas"][1]) / 2.0 - float(meta["ground_pixel"])) * factor)
 else:
  sprite.scale = Vector2.ONE
  sprite.position = Vector2(0, -30)
 var changed := pose != value or sprite.animation != value
 pose = value
 if changed or (sprite.sprite_frames.get_animation_loop(value) and not sprite.is_playing()):
  sprite.speed_scale = 1.0
  sprite.play(value)

func visual_now() -> float:
 return clock_source.call() if clock_source.is_valid() else Time.get_ticks_usec()/1000000.0
func reset_visual() -> void:
 flash_time=0
 whiff_time=0
 spark_time=0
 sprite.modulate=Color.WHITE
 final_locked=false
 visual_priority=0
 visual_until=-INF
func request_pose(value: String, priority: int, seconds: float) -> bool:
 if final_locked or (visual_now()<visual_until and priority<visual_priority):return false
 visual_priority=priority
 visual_until=visual_now()+seconds
 set_pose(value)
 return true
func play_final(value: String) -> void:
 reset_visual()
 rhythmic_pose(value,0.8 if value=="victory" else 0.6,100)
 final_locked=true
func rhythmic_pose(value: String, seconds: float, priority: int=30) -> void:
 if not request_pose(value,priority,seconds):return
 sprite.frame = 0
 sprite.frame_progress = 0.0
 var count := sprite.sprite_frames.get_frame_count(value)
 sprite.speed_scale = count / maxf(0.001, seconds * sprite.sprite_frames.get_animation_speed(value))

func prepare(value: String, seconds: float) -> void:
 if not request_pose(value,75,seconds):return
 sprite.frame = 0
 var target_frame := 3 if value.ends_with("attack") else 2
 sprite.speed_scale = target_frame / maxf(0.001, seconds * sprite.sprite_frames.get_animation_speed(value))

func impact(value: String, seconds: float) -> void:
 if not request_pose(value,75,seconds):return
 var count := sprite.sprite_frames.get_frame_count(value)
 sprite.frame = mini(3 if value.ends_with("attack") else 2, count - 1)
 sprite.frame_progress = 0.0
 sprite.speed_scale = maxf(1, count - sprite.frame) / maxf(0.001, seconds * sprite.sprite_frames.get_animation_speed(value))

func parry(height: String, seconds: float) -> void:
 if final_locked:return
 impact(height + "_parry", seconds)
 # Resolved ImpactEffect owns parry feedback; no second procedural spark.
 spark_time = 0.0

func whiff(height: String, seconds: float) -> void:
 if final_locked:return
 # Reuse the supplied attack recovery, with the same duration at every height.
 set_pose(height + "_attack")
 sprite.frame = sprite.sprite_frames.get_frame_count(sprite.animation) - 1
 sprite.play()
 whiff_time = seconds

func hit_feedback() -> void:
 if final_locked:return
 flash_time = 0.2

func _process(delta: float) -> void:
 spark_time = maxf(0, spark_time - delta)
 flash_time = maxf(0, flash_time - delta)
 whiff_time = maxf(0, whiff_time - delta)
 sprite.modulate = Color(1, 0.45, 0.45) if flash_time > 0 else (Color(0.7, 0.7, 0.7) if whiff_time > 0 else Color.WHITE)
 queue_redraw()

func _draw() -> void:
 if spark_time > 0:
  var at := Vector2(looking * 25, -38)
  draw_line(at - Vector2(5, 0), at + Vector2(5, 0), Color("fff0ad"), 1)
  draw_line(at - Vector2(0, 5), at + Vector2(0, 5), Color("fff0ad"), 1)
