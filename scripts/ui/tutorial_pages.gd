class_name TutorialPages
extends Control
# Player-facing diagrams are real Labels/Panels at integer logical coordinates.
const FONT=preload("res://assets/ui/arcade/arcade.fnt")
const INK=Color("141e29")
const CREAM=Color("f6e3b8")
const GOLD=Color("efb854")
const RED=Color("ef7869")
const BLUE=Color("80c8f0")
const DIAGRAMS = [
 preload("res://assets/ui/arcade/how_to_play_02.png"),
 preload("res://assets/ui/arcade/how_to_play_01.png"),
 preload("res://assets/ui/arcade/how_to_play_03.png")]
var current: int=0
var text_bounds: Array[Dictionary]=[]
var key_actions: Array[String]=[]
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 rebuild()
func box(rect: Rect2,color: Color,border: Color=Color.TRANSPARENT) -> Panel:
 var panel:=Panel.new()
 panel.position=rect.position
 panel.size=rect.size
 panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var style:=StyleBoxFlat.new()
 style.bg_color=color
 style.border_color=border
 style.set_border_width_all(1 if border.a>0 else 0)
 panel.add_theme_stylebox_override("panel",style)
 add_child(panel)
 return panel
func words(text: String,rect: Rect2,color: Color=CREAM,font_size: int=8) -> void:
 var node:=Label.new()
 node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 node.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 node.add_theme_font_override("font",FONT)
 node.add_theme_font_size_override("font_size",font_size)
 node.add_theme_color_override("font_color",color)
 node.text=text
 node.position=rect.position
 node.size=rect.size
 node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(node)
 node.size=rect.size
 text_bounds.append({"text":text,"rect":rect,"size":font_size,"node":node})
func keycap(text: String,x: int,y: int,width: int=24,action: String="") -> void:
 box(Rect2(x,y,width,22),CREAM,GOLD)
 words(text,Rect2(x,y,width,22),INK,16 if text.length()==1 else 8)
 if not action.is_empty():key_actions.append(action)
func arrow_key(direction: String,x: int,y: int,action: String="") -> void:
 keycap("",x,y,24,action)
 # Geometric arrow made of UI Panels: no unsupported font glyphs.
 if direction in ["left","right"]:
  box(Rect2(x+6,y+10,12,2),INK)
  var tip:=x+5 if direction=="left" else x+17
  for i in range(4):box(Rect2(tip+(i if direction=="left" else -i),y+10-i,1,2+i*2),INK)
 else:
  box(Rect2(x+11,y+5,2,12),INK)
  for i in range(4):box(Rect2(x+11-i,y+5+i if direction=="up" else y+16-i,2+i*2,1),INK)
func change(direction: int) -> void:
 current=clampi(current+direction,0,2)
 rebuild()
func rebuild() -> void:
 for child in get_children():
  remove_child(child)
  child.queue_free()
 text_bounds.clear()
 key_actions.clear()
 box(Rect2(0,0,320,180),INK)
 box(Rect2(6,5,308,170),INK,CREAM)
 var titles: Array[String]=["MOVE TO THE BEAT","FIGHT TO THE BEAT","HOW TO WIN"]
 words(titles[current],Rect2(8,10,304,20),GOLD,16)
 box(Rect2(18,33,284,1),GOLD)
 match current:
  0:movement_page()
  1:fight_page()
  2:win_page()
 words("<   %d/3   >" % (current+1),Rect2(112,151,96,10),GOLD)
 words("LEFT / RIGHT: PAGES    ESC: BACK",Rect2(8,164,304,8))
func illustration(rect: Rect2) -> void:
 var picture := Sprite2D.new()
 picture.texture = DIAGRAMS[current]
 picture.centered = false
 var factor := minf(rect.size.x/picture.texture.get_width(),rect.size.y/picture.texture.get_height())
 picture.scale = Vector2.ONE*factor
 picture.position = (rect.position+(rect.size-picture.texture.get_size()*factor)/2).round()
 picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 add_child(picture)

func movement_page() -> void:
 illustration(Rect2(73,35,174,55))
 words("TAP TO THE BEAT!",Rect2(10,90,300,10),GOLD)
 words("RED",Rect2(25,103,120,10),RED)
 words("BLUE",Rect2(175,103,120,10),BLUE)
 keycap("A",43,115,28,"p1_left")
 keycap("D",99,115,28,"p1_right")
 arrow_key("left",195,115,"p2_left")
 arrow_key("right",251,115,"p2_right")
 words("ONE TAP, ONE STEP.",Rect2(10,140,300,10))

func small_key(text: String,x: int,y: int,width: int,action: String) -> void:
 box(Rect2(x,y,width,14),CREAM,GOLD)
 words(text,Rect2(x,y,width,14),INK)
 key_actions.append(action)

func fight_page() -> void:
 illustration(Rect2(128,35,64,36))
 words("PICK A HEIGHT. FIGHT ON BEAT 4!",Rect2(8,72,304,10),GOLD)
 for row in range(3):
  var y := 85+row*17
  small_key(["W","D","S"][row],17,y,24,["p1_high","p1_right","p1_low"][row])
  words("+",Rect2(42,y,10,14),GOLD)
  small_key("F",53,y,24,"p1_execute")
  words(["HIGH","MID","LOW"][row],Rect2(80,y,36,14),RED)
  small_key(["UP","LEFT","DOWN"][row],167,y,30,["p2_high","p2_left","p2_low"][row])
  words("+",Rect2(198,y,10,14),GOLD)
  small_key("R SHIFT",209,y,48,"p2_execute")
  words(["HIGH","MID","LOW"][row],Rect2(261,y,36,14),BLUE)
 words("MID: TOWARD THE OTHER FIGHTER.",Rect2(8,134,304,8))
 words("YOUR TURN: HIT. THEIR TURN: BLOCK SAME HEIGHT!",Rect2(8,143,304,8))

func win_page() -> void:
 illustration(Rect2(61,35,198,66))
 words("3 HITS WIN A ROUND!",Rect2(8,106,304,20),CREAM,16)
 words("WIN ROUNDS TO WIN THE MATCH!",Rect2(8,127,304,10),GOLD)
 for i in range(3):
  words("BEST OF %d: WIN %d" % [3+i*2,i+2],Rect2(12+i*100,140,96,10))
