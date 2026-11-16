class_name StoryBackdrop
extends Node2D
# The existing Screen 01 backdrop, separated only to admit props behind the house.
const SKY=preload("res://assets/environments/backgrounds/bim_sky.png")
const SCENERY=preload("res://assets/environments/backgrounds/bim_foreground.png")
func _draw() -> void:
 draw_rect(Rect2(0,0,320,180),Color("82c6cb"))
 draw_texture_rect(SKY,Rect2(0,0,320,180),false)
 draw_texture_rect_region(SCENERY,Rect2(0,150,320,30),Rect2(0,880,1672,61))
