class_name StoryScreen
extends Node2D
var house_frames: Array[Texture2D]=[]
var house_frame: int=0
var dust_age: float=-1
var dust_x: float=100
func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 for i in range(4):house_frames.append(load("res://assets/story/009/house_%02d.png" % i))
func bind_clock(clock: RhythmConductor) -> void:
 $CoconutPalm.bind_clock(clock)
func _draw() -> void:
 # Masonry backing closes the transparent foundation gap without moving/resizing art.
 draw_rect(Rect2(0,146,82,5),Color("9f7854"))
 if not house_frames.is_empty():draw_texture_rect(house_frames[house_frame],Rect2(-384*.27,150-744*.27,768*.27,768*.27),false)
 if dust_age>=0 and dust_age<1:
  for i in range(9):
   var spread:=4+dust_age*15
   var p:=Vector2(roundf(dust_x+(i-4)*spread/4),roundf(149-dust_age*(4+i%3*2)))
   if dust_age<.45+float(i%3)*.2:draw_rect(Rect2(p,Vector2(2,2)),Color("e4cb9d"))
