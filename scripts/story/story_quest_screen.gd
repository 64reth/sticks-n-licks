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
  draw_rect(Rect2(112,62,96,118),Color("37414b"))
  for y in range(70,180,18):draw_rect(Rect2(158,y,3,9),Color("ffe2a0"))
  var warning:=session.obstacles.traffic_warning(beat)
  var active:=session.obstacles.traffic_active(beat)
  draw_rect(Rect2(115,66,90,12),Color("9b433c") if warning or active else Color("245b48"))
  var cue: String="CROSS NOW" if session.obstacles.can_start_crossing(beat) else ("KEEP GOING" if session.actor.position.x>112 and session.actor.position.x<208 and not warning and not active else "WAIT")
  caption(cue,Vector2(128,75))
  if active:
   var y:=roundf(session.obstacles.vehicle_y(beat))
   draw_rect(Rect2(138,y-30,44,30),Color("d99745"))
   draw_rect(Rect2(145,y-25,30,9),Color("b1d8da"))
   for wheel_y in [y-24,y-7]:
    draw_rect(Rect2(134,wheel_y,5,7),Color("172235"))
    draw_rect(Rect2(181,wheel_y,5,7),Color("172235"))
  elif warning:caption("VEHICLE APPROACHING",Vector2(106,85))
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
  caption("HOLD S: DUCK" if warning else ("LUNGE!" if active else "WATCH THE CANE"),Vector2(112,69))
  if active:
   var lean:=roundf(sin(session.obstacles.road_phase(beat)*PI)*3)
   draw_rect(Rect2(119+lean,92,85,3),Color("172235"))
 if screen_number in [2,3]:
  var x:=92 if screen_number==2 else 251
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
  caption("F: STICK",Vector2(97,121))
 caption("PLACEHOLDER: "+["","","VILLAGE ROAD","THE CROSSING","CANE ROAD","RUSTLING ROWS","STICK CLEARING"][screen_number],Vector2(8,174))
func caption(value: String, at: Vector2) -> void:
 for offset in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)]:draw_string(StoryOverlay.FONT,at+offset,value,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("172235"))
 draw_string(StoryOverlay.FONT,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("ffe2a0"))
func crate(at: Vector2) -> void:
 draw_rect(Rect2(at,Vector2(13,13)),Color("b7834d"))
 draw_rect(Rect2(at,Vector2(13,13)),Color("553e30"),false,1)
 draw_line(at,at+Vector2(12,12),Color("553e30"),1)
