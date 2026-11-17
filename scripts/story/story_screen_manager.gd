class_name StoryScreenManager
extends Node2D
var current: StoryScreen
var screen_id: int=0
func load_screen(id: int) -> StoryScreen:
 # Screen replacement never touches the shared conductor or audio transport.
 assert(id>=1 and id<=6)
 if current:current.queue_free()
 if id==1:current=preload("res://scenes/story/screen_01.tscn").instantiate()
 else:
  current=StoryQuestScreen.new()
  current.screen_number=id
  if id in [2,4]:
   var palm:=preload("res://scenes/props/coconut_palm.tscn").instantiate()
   palm.position=Vector2(255,149)
   palm.phase_offset_beats=2
   current.add_child(palm)
 screen_id=id
 add_child(current)
 return current
