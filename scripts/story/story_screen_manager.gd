class_name StoryScreenManager
extends Node2D
var current: StoryScreen
var screen_id: int=0
func load_screen(id: int) -> StoryScreen:
 # Screen replacement never touches the shared conductor or audio transport.
 assert(id==1,"Only Screen 01 exists in this milestone")
 if current:current.queue_free()
 current=preload("res://scenes/story/screen_01.tscn").instantiate()
 screen_id=id
 add_child(current)
 return current
