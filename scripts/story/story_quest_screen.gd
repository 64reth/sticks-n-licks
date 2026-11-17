class_name StoryQuestScreen
extends StoryScreen
var screen_number: int=2
var session: StorySession
var world: BeatWorld
const VILLAGE=preload("res://assets/environments/backgrounds/background_01.png")
func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func bind_clock(clock: RhythmConductor) -> void:
 world=BeatWorld.new(clock)
 for child in get_children():
  if child is CoconutPalm:child.bind_clock(clock)
func _draw() -> void:
 if session==null or world==null:return
 var beat:=world.beat()
 if screen_number==2:draw_texture_rect(VILLAGE,Rect2(0,0,320,180),false)
 else:
  draw_rect(Rect2(0,0,320,180),Color("85c8c7"))
  draw_rect(Rect2(0,105,320,45),Color("749548"))
  draw_rect(Rect2(0,150,320,30),Color("b88b56"))
  # Clouds move over 32 beats, independently offset from cane and NPC cycles.
  for i in range(3):
   var x:=roundf(world.interpolate(-40,360,32,i*9))
   draw_rect(Rect2(x,45+i*9,26,5),Color("eff0cf"))
 if screen_number==3:
  var section:=session.road_section
  var layout: Dictionary=session.obstacles.traffic.roads[section]
  draw_rect(Rect2(0,53,320,127),Color("b8ae87"))
  draw_rect(Rect2(float(layout.left),53,float(layout.right)-float(layout.left),127),Color("37414b"))
  for edge in [float(layout.left),float(layout.right)]:draw_rect(Rect2(edge,53,2,127),Color("f5e4b2"))
  for y in range(58,180,28):draw_rect(Rect2(163,y,2,16),Color("ffe2a0"))
  # Matching reservation textures at the end/start of the two fixed sections.
  draw_rect(Rect2(270 if section==0 else 0,53,50,127),Color("769153"))
  draw_rect(Rect2(274 if section==0 else 4,56,42,3),Color("d6c58b"))
  caption("REFUGE" if section==0 else "EXIT",Vector2(273,83))
  for index in range(4):
   var lane: Dictionary=session.obstacles.traffic.lanes[index]
   if int(lane.road)!=section:continue
   var x: float=float(lane.x)
   var warning:=session.obstacles.lane_warning(index,beat)
   var active:=session.obstacles.lane_active(index,beat)
   var direction: int=int(lane.direction)
   draw_colored_polygon(PackedVector2Array([Vector2(x-4,77-direction*3),Vector2(x+4,77-direction*3),Vector2(x,77+direction*5)]),Color("ffe2a0"))
   if active:
    var y:=roundf(session.obstacles.lane_vehicle_y(index,beat))
    var colors: Array[Color]=[Color("d99745"),Color("7299bf"),Color("ac735d"),Color("80a45d")]
    # 64 x 110 body, four wheels: a full-size placeholder, never source artwork.
    draw_rect(Rect2(x-32,y-110,64,110),Color("172235"))
    draw_rect(Rect2(x-29,y-108,58,106),colors[index])
    var front:=y-84 if direction>0 else y-42
    draw_rect(Rect2(x-24,front,48,23),Color("b1d8da"))
    draw_rect(Rect2(x-24,y-56,48,20),Color("314b64"))
    for wheel_y in [y-91,y-27]:
     draw_rect(Rect2(x-36,wheel_y,6,17),Color("111927"))
     draw_rect(Rect2(x+30,wheel_y,6,17),Color("111927"))
    for light_x in [x-25,x+17]:draw_rect(Rect2(light_x,y-(5 if direction>0 else 108),8,3),Color("ffe2a0"))
  # Signs are drawn above traffic so a passing roof cannot hide a warning or section label.
  caption("CARRIAGEWAY %d / 2" % (section+1),Vector2(80,46))
  caption("CROSS" if session.obstacles.can_start_road(section,beat) else "WAIT",Vector2(8,71))
  for index in range(section*2,section*2+2):
   var x: float=float(session.obstacles.traffic.lanes[index].x)
   var warning:=session.obstacles.lane_warning(index,beat)
   var active:=session.obstacles.lane_active(index,beat)
   draw_rect(Rect2(x-14,55,28,12),Color("9b433c") if warning or active else Color("245b48"))
   caption("!" if warning else ("X" if active else "GO"),Vector2(x-(3 if warning or active else 6),64))
 if screen_number in [4,5,6]:
  for i in range(18):
   var x:=i*19+int(round(sin(world.phase(8,i*.35)*TAU)*2))
   draw_line(Vector2(i*19,145),Vector2(x,80+i%3*7),Color("386e42"),2)
   draw_line(Vector2(x,105),Vector2(x-9,94),Color("548348"),2)
   draw_line(Vector2(x,114),Vector2(x+10,99),Color("548348"),2)
 if screen_number in [4,5]:
  var warning:=session.obstacles.cane_warning(beat)
  var active:=session.obstacles.cane_active(beat)
  draw_rect(Rect2(110,148,100,2),Color("ffe2a0"))
  caption("WARNING" if warning else ("LUNGE!" if active else "WATCH THE CANE"),Vector2(112,69))
  if warning:ControlPrompt.draw(self,"p1_low","Duck",Vector2(112,49))
  if active:
   var lean:=roundf(sin(session.obstacles.road_phase(beat)*PI)*3)
   draw_rect(Rect2(119+lean,92,85,3),Color("172235"))
 if screen_number==2 or (screen_number==3 and session.road_section==1 and session.quest.completed.has("cross")):
  var x:=92 if screen_number==2 else 300
  var nod:=world.pose(2,4,1)
  draw_rect(Rect2(x-6,111+nod,12,12),Color("a86f44"))
  draw_rect(Rect2(x-8,124,16,24),Color("426f89"))
  draw_rect(Rect2(x-12,106+nod,24,5),Color("e5bc68"))
  var gesture:=int(world.pose(3,4,2))*2
  draw_line(Vector2(x+7,128),Vector2(x+13,126-gesture),Color("a86f44"),3)
  draw_rect(Rect2(x-23,140,46,10),Color("75503b"))
  caption("VENDOR",Vector2(x-18,101))
 if screen_number==2 and session.inventory.item!="crate" and not session.quest.completed.has("crate"):
  crate(Vector2(142,137))
 if screen_number==6 and session.inventory.item!="stick":
  draw_line(Vector2(102,147),Vector2(129,134),Color("ebc888"),3)
func caption(value: String, at: Vector2) -> void:
 for offset in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)]:draw_string(StoryOverlay.FONT,at+offset,value,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("172235"))
 draw_string(StoryOverlay.FONT,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("ffe2a0"))
func crate(at: Vector2) -> void:
 draw_rect(Rect2(at,Vector2(13,13)),Color("b7834d"))
 draw_rect(Rect2(at,Vector2(13,13)),Color("553e30"),false,1)
 draw_line(at,at+Vector2(12,12),Color("553e30"),1)
