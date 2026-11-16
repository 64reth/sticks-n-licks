extends "res://scripts/main.gd"
# Graphical evidence only: synthetic keys, production main scene and tutorial UI.
var frame: int=0
func _ready() -> void:
 preferences_path=""
 super._ready()
 DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
 DisplayServer.window_set_size(Vector2i(1280,720))
 DisplayServer.window_set_position(Vector2i(40,60))
 DisplayServer.window_move_to_foreground()
func press(code: int) -> void:MenuTestInput.key(self,code)
func capture(page: int) -> void:
 await RenderingServer.frame_post_draw
 var image:=get_viewport().get_texture().get_image()
 image.save_png("res://output/tutorial-page%d-native.png" % page)
 # Save the screen region of the real 1280x720 game window, when supported.
 if "--desktop-capture" not in OS.get_cmdline_user_args():return
 var at:=DisplayServer.window_get_position()
 var area:="%d,%d,1280,720" % [at.x,at.y]
 var path:=ProjectSettings.globalize_path("res://output/tutorial-page%d-desktop.png" % page)
 var code:=OS.execute("/usr/sbin/screencapture",["-x","-R",area,path])
 print("TUTORIAL CAPTURE page=",page," native=",image.get_size()," desktop_exit=",code)
func _process(delta: float) -> void:
 super._process(delta)
 frame+=1
 match frame:
  30:
   press(KEY_DOWN)
   press(KEY_DOWN)
   press(KEY_ENTER)
  75:capture(1)
  135:press(KEY_RIGHT)
  180:capture(2)
  240:press(KEY_RIGHT)
  285:capture(3)
  345:press(KEY_LEFT)
  375:press(KEY_LEFT)
  405:press(KEY_ESCAPE)
  450:
   print("TUTORIAL GRAPHICAL DEMO COMPLETE title=",flow.view.page=="title")
   get_tree().quit()
