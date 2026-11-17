class_name ControlPrompt
extends RefCounted
const FONT=preload("res://assets/ui/arcade/arcade.fnt")
# Keyboard bindings are queried, not guessed. A future device renderer may replace this skin.
static func key_label(action: String) -> String:
 if not InputMap.has_action(action):return ""
 for event in InputMap.action_get_events(action):
  if event is InputEventKey:
   var code: int=event.physical_keycode if event.physical_keycode!=0 else event.keycode
   return OS.get_keycode_string(code).to_upper()
 return ""
static func draw(canvas: CanvasItem, action: String, label: String, at: Vector2) -> Rect2:
 var key:=key_label(action)
 if key.is_empty():return Rect2()
 var width:=maxf(13,FONT.get_string_size(key,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x+6)
 var rect:=Rect2(at.round(),Vector2(width,11))
 canvas.draw_rect(rect,Color("172235"))
 canvas.draw_rect(rect,Color("ffe2a0"),false,1)
 canvas.draw_line(at+Vector2(2,9),at+Vector2(width-2,9),Color("886d4e"),1)
 var key_width:=FONT.get_string_size(key,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x
 canvas.draw_string(FONT,at+Vector2(roundf((width-key_width)/2),8),key,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("ffe2a0"))
 if not label.is_empty():
  var pos:=at+Vector2(width+4,8)
  for offset in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)]:canvas.draw_string(FONT,pos+offset,label.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("172235"))
  canvas.draw_string(FONT,pos,label.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("ffe2a0"))
 return rect
