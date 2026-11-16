class_name PixelAnnouncement
extends Label
# Bitmap fonts do not reliably provide FontFile outline glyphs. Draw a discrete
# stroke on the native pixel grid instead, without blur or duplicate Label nodes.
var fill_color := Color("ffe2a0")
var outline_color := Color("172235")
var shadow_color := Color("080f1b")
var outline_pixels: int = 2
func _ready() -> void:
 add_theme_color_override("font_color",Color.TRANSPARENT)
 add_theme_color_override("font_shadow_color",Color.TRANSPARENT)
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 mouse_filter=Control.MOUSE_FILTER_IGNORE
func ink_origin() -> Vector2:
 var font := get_theme_font("font")
 var font_size := get_theme_font_size("font_size")
 var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
 var point := Vector2((size.x-width)/2.0,font.get_ascent(font_size))
 # Offsets are in final logical pixels, even while the countdown label scales.
 return Vector2(roundf(point.x*scale.x)/scale.x,roundf(point.y*scale.y)/scale.y)
func _draw() -> void:
 if text.is_empty():return
 var font := get_theme_font("font")
 var font_size := get_theme_font_size("font_size")
 var point := ink_origin()
 paint(font,point+Vector2(2.0/scale.x,3.0/scale.y),font_size,shadow_color)
 for y in range(-outline_pixels,outline_pixels+1):
  for x in range(-outline_pixels,outline_pixels+1):
   if (x!=0 or y!=0) and x*x+y*y<=outline_pixels*outline_pixels+1:
    paint(font,point+Vector2(float(x)/scale.x,float(y)/scale.y),font_size,outline_color)
 paint(font,point,font_size,fill_color)

func paint(font: Font,point: Vector2,font_size: int,color: Color) -> void:
 # Direct bitmap glyphs keep numeric-only countdowns out of bidi line shaping.
 var advance:=0.0
 for index in range(text.length()):
  var code:=text.unicode_at(index)
  font.draw_char(get_canvas_item(),point+Vector2(advance,0),code,font_size,color)
  advance+=font.get_char_size(code,font_size).x
