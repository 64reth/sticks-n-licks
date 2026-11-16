class_name ArcadeFrontEnd
extends Control
signal activated(command: String)
signal adjusted(key: String, direction: int)
const FONT=preload("res://assets/ui/arcade/arcade.fnt")
const INK=Color("141e29")
const CREAM=Color("f6e3b8")
const GOLD=Color("efb854")
var page: String="title"
var cursor: int=0
var rows: Array[Dictionary]=[]
var heading: String="STICKS N LICKS"
var subtitle: String="RHYTHM. SPACING. ONE MORE BOUT."
var tutorial:=TutorialPages.new()
var result: bool=false
var visual_phase: float=0.0
func _process(delta: float) -> void:
 if visible:
  visual_phase=fposmod(visual_phase+delta,1.0)
  queue_redraw()
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(tutorial)
 tutorial.visible=page=="help"
func open(next: String) -> void:
 page=next
 tutorial.visible=page=="help"
 if page=="help":
  tutorial.current=0
  tutorial.rebuild()
 cursor=0
 queue_redraw()
func present(title: String, items: Array[Dictionary], sub: String="") -> void:
 heading=title
 rows=items
 subtitle=sub
 cursor=clampi(cursor,0,maxi(0,rows.size()-1))
 result=page=="result"
 queue_redraw()
func key(event: InputEventKey) -> bool:
 if not event.pressed or event.echo:return true
 if page=="help":
  if event.keycode in [KEY_LEFT,KEY_RIGHT]:
   tutorial.change(-1 if event.keycode==KEY_LEFT else 1)
   activated.emit("nav")
  elif event.keycode==KEY_ESCAPE:activated.emit("tutorial_exit")
  return true
 if event.keycode==KEY_UP:
  cursor=posmod(cursor-1,maxi(1,rows.size()))
  activated.emit("nav")
 elif event.keycode==KEY_DOWN:
  cursor=posmod(cursor+1,maxi(1,rows.size()))
  activated.emit("nav")
 elif event.keycode in [KEY_LEFT,KEY_RIGHT] and not rows.is_empty():
  if rows[cursor].has("key"):
   adjusted.emit(str(rows[cursor].key),-1 if event.keycode==KEY_LEFT else 1)
   activated.emit("nav")
 elif event.keycode==KEY_ENTER and not rows.is_empty():
  if rows[cursor].get("disabled",false):return true
  if rows[cursor].has("key"):
   cursor=posmod(cursor+1,rows.size())
   activated.emit("nav")
  else:activated.emit(str(rows[cursor].get("command","back")))
 elif event.keycode==KEY_ESCAPE:activated.emit("back")
 queue_redraw()
 return true
func label(text: String, at: Vector2, color: Color=CREAM) -> void:
 draw_string(FONT,at,text.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,8,color)
func centered(text: String,y: float,color: Color=CREAM) -> void:
 var width:=FONT.get_string_size(text.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,8).x
 label(text,Vector2(roundf((320-width)/2),y),color)
func _draw() -> void:
 if page=="help":return
 if result:
  draw_rect(Rect2(4,43,312,18),INK)
  centered(heading,55,GOLD)
 else:
  draw_rect(Rect2(0,0,320,180),Color(0.055,0.09,0.12,0.94))
  draw_rect(Rect2(10,8,300,164),INK)
  draw_rect(Rect2(10,8,300,164),CREAM,false,1)
  draw_line(Vector2(22,35),Vector2(298,35),GOLD,1)
  if page=="title":
   var extent:=FONT.get_string_size(heading,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
   draw_string(FONT,Vector2((320-extent)/2,27),heading,HORIZONTAL_ALIGNMENT_LEFT,-1,16,GOLD)
  else:centered(heading,25,GOLD)
  if not subtitle.is_empty():centered(subtitle,45,Color("9dbeaa"))
 var start:=158.0 if result else (62.0 if rows.size()>5 else 75.0)
 var spacing:=10.0 if result else 14.0
 for index in range(rows.size() if page!="help" else 0):
  var y:=start+index*spacing
  var selected:=index==cursor
  if selected:
   draw_rect(Rect2(19,y-8,282,10),Color("3b4a42"))
   var x:=23+int(visual_phase>0.5)
   draw_colored_polygon(PackedVector2Array([Vector2(x,y-6),Vector2(x+4,y-3),Vector2(x,y)]),GOLD)
  var row: Dictionary=rows[index]
  label(str(row.label),Vector2(34,y),Color("6c7b7a") if row.get("disabled",false) else (GOLD if selected else CREAM))
  if row.has("value"):
   var value:=str(row.value)
   var extent:=FONT.get_string_size(value.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,8).x
   label(value,Vector2(292-extent,y),GOLD if selected else CREAM)
 if not result:centered("ARROWS SELECT    ENTER CONFIRM    ESC BACK",166,Color("9dbeaa"))
