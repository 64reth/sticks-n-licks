class_name UnarmedPresentation
extends Node2D
# Rendering only, attached to the existing Fighter. Lower body stays bit-for-bit stationary.
var actor: Fighter
var world: BeatWorld
var lift: int=0
const SPLIT_Y=660
func setup(fighter: Fighter, clock: BeatWorld) -> void:
 actor=fighter
 world=clock
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func sync() -> void:
 var presenting: bool=actor.pose=="story_idle"
 visible=presenting
 actor.sprite.visible=not presenting
 if not presenting:return
 # Two upper-body placements across an eight-beat breath; never scale/bounce the boots.
 var phase:=world.phase(8)
 var next_lift:=1 if phase>=.25 and phase<.75 else 0
 if next_lift!=lift:
  lift=next_lift
  queue_redraw()
func _draw() -> void:
 if actor==null or not visible:return
 var texture: Texture2D=actor.sprite.sprite_frames.get_frame_texture("story_idle",0)
 var factor: float=float(actor.animation_meta.story_idle.scale)
 var width:=roundf(768*factor)
 var x:=roundf(-384*factor)
 var top:=roundf(-744*factor)
 var join:=top+roundf(SPLIT_Y*factor)
 var bottom:=top+roundf(768*factor)
 draw_texture_rect_region(texture,Rect2(x,top-lift,width,join-top),Rect2(0,0,768,SPLIT_Y))
 # Repeat a waist row to bridge the one-pixel inhale, without changing lower-body pixels.
 if lift>0:draw_texture_rect_region(texture,Rect2(x,join-lift,width,lift),Rect2(0,SPLIT_Y-1,768,1))
 draw_texture_rect_region(texture,Rect2(x,join,width,bottom-join),Rect2(0,SPLIT_Y,768,768-SPLIT_Y))
