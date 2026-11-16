class_name ArcadeIntro
extends Control
signal menu_requested
const FONT = preload("res://assets/ui/arcade/arcade.fnt")
var config: Dictionary = {}
var sky := Sprite2D.new()
var foreground := Sprite2D.new()
var logo := TempoLogo.new()
var prompt := Label.new()
var prompt_panel := PanelContainer.new()
const CTA_PADDING := Vector2i(6,4)
const CTA_BORDER := 1
var timeline: Callable
var elapsed: float = 0.0
var skipped: bool = false
var is_ready: bool = false
var prompt_visible: bool = false
var cue_log: Array[Dictionary] = []
var seen: Dictionary = {}
func _ready() -> void:
 config = JSON.parse_string(FileAccess.get_file_as_string("res://data/intro.json"))
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 for item in [[sky,"sky"],[foreground,"foreground"]]:
  var sprite: Sprite2D = item[0]
  sprite.texture = load(config[item[1]]) if ResourceLoader.exists(config[item[1]]) else null
  sprite.centered = false
  if sprite.texture:sprite.scale = Vector2.ONE*320.0/sprite.texture.get_width()
  add_child(sprite)
 logo.sheet = load(config.logo)
 logo.display_width = float(config.logo_width)
 add_child(logo)
 prompt_panel.position = Vector2(20,137)
 prompt_panel.custom_minimum_size = Vector2(280,0)
 var style := StyleBoxFlat.new()
 style.bg_color = Color("141e29")
 style.border_color = Color("efb854")
 style.set_border_width_all(CTA_BORDER)
 style.content_margin_left = CTA_BORDER+CTA_PADDING.x
 style.content_margin_right = CTA_BORDER+CTA_PADDING.x
 style.content_margin_top = CTA_BORDER+CTA_PADDING.y
 style.content_margin_bottom = CTA_BORDER+CTA_PADDING.y
 prompt_panel.add_theme_stylebox_override("panel",style)
 add_child(prompt_panel)
 prompt.add_theme_font_override("font",FONT)
 prompt.add_theme_font_size_override("font_size",16)
 prompt.add_theme_color_override("font_color",Color("f6e3b8"))
 prompt.add_theme_color_override("font_shadow_color",Color("141e29"))
 prompt.add_theme_constant_override("shadow_offset_x",1)
 prompt.add_theme_constant_override("shadow_offset_y",1)
 prompt.text = "PRESS ENTER TO START"
 prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
 prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 prompt_panel.add_child(prompt)
 prompt_panel.reset_size()
 update_at(0)
func validate() -> bool:
 var last := -INF
 for key in ["music_start","sky","foreground","logo","speakers","prompt","ready"]:
  if not config.cues.has(key) or float(config.cues[key])<last:return false
  last = float(config.cues[key])
 return sky.texture!=null and foreground.texture!=null and logo.sheet!=null and float(config.bpm)>0
func progress(at: float, cue: String) -> float:
 return clampf((at-float(config.cues[cue]))/maxf(0.001,float(config.entrance_seconds[cue])),0,1)
func update_at(at: float) -> void:
 elapsed = maxf(0,at)
 var visual := maxf(elapsed,float(config.cues.ready)) if skipped else elapsed
 var sky_p := 1.0-pow(1.0-progress(visual,"sky"),3)
 var fore_p := 1.0-pow(1.0-progress(visual,"foreground"),3)
 sky.position = Vector2(0,roundf(lerpf(-181,0,sky_p)))
 foreground.position = Vector2(0,roundf(lerpf(181,0,fore_p)))
 logo.visible = visual>=float(config.cues.logo)
 var bounce := sin(progress(visual,"logo")*PI)*-6.0
 logo.position = Vector2(float(config.logo_position[0]),roundf(float(config.logo_position[1])+bounce))
 var phase := fposmod(maxf(0,elapsed-float(config.cues.music_start)-float(config.beat_zero_seconds))*float(config.bpm)/60.0,1)
 logo.set_frame(int(config.pulse_frames[mini(5,int(phase*6+0.0000001))]) if elapsed>=float(config.cues.speakers) else 0)
 is_ready = visual>=float(config.cues.ready)
 prompt_visible = visual>=float(config.cues.prompt)
 prompt.visible = prompt_visible
 prompt_panel.visible = prompt_visible
 prompt.modulate.a = 1.0 if phase<0.75 else 0.65
 for key in config.cues:
  if visual>=float(config.cues[key]) and not seen.has(key):
   seen[key]=true
   cue_log.append({"cue":key,"audio_seconds":elapsed,"skipped":skipped})
 queue_redraw()
func skip() -> void:
 skipped = true
 update_at(elapsed)
func accept() -> void:
 if not is_ready:skip()
 else:menu_requested.emit()
func _process(_delta: float) -> void:
 if visible and timeline.is_valid():update_at(float(timeline.call()))
func _draw() -> void:
 draw_rect(Rect2(0,0,320,180),Color("141e29"))
