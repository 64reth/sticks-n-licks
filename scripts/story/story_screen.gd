class_name StoryScreen
extends Node2D
const SKY=preload("res://assets/environments/backgrounds/bim_sky.png")
const SCENERY=preload("res://assets/environments/backgrounds/bim_foreground.png")
var house_frames: Array[Texture2D]=[]
var house_frame: int=0
var dust_age: float=-1
var dust_x: float=100
func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 for i in range(4):house_frames.append(load("res://assets/story/009/house_%02d.png" % i))
func _draw() -> void:
 draw_rect(Rect2(0,0,320,180),Color("82c6cb"))
 draw_texture_rect(SKY,Rect2(0,0,320,180),false)
 # Only the approved street strip; its buildings are replaced by the supplied house.
 draw_texture_rect_region(SCENERY,Rect2(0,150,320,30),Rect2(0,880,1672,61))
 if not house_frames.is_empty():draw_texture_rect(house_frames[house_frame],Rect2(-384*.27,150-744*.27,768*.27,768*.27),false)
 if dust_age>=0 and dust_age<1:
  for i in range(9):
   var spread:=4+dust_age*15
   var p:=Vector2(roundf(dust_x+(i-4)*spread/4),roundf(149-dust_age*(4+i%3*2)))
   if dust_age<.45+float(i%3)*.2:draw_rect(Rect2(p,Vector2(2,2)),Color("e4cb9d"))
