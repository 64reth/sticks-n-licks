extends SceneTree
var game: Node2D
var time := 0.0
var suffix := "before"
var recording := false
var checks := 0
func _initialize() -> void:call_deferred("run")
func capture(label: String) -> void:
 game.refresh()
 await process_frame
 await RenderingServer.frame_post_draw
 var image:=root.get_texture().get_image()
 image.save_png("res://output/polish-"+suffix+"-"+label+".png")
 if suffix=="after" and game.hud.major_label.text in ["1","2","3"]:
  var filled:=0
  for y in range(43,78):
   for x in range(140,180):
    if image.get_pixel(x,y).is_equal_approx(Color("ffe2a0")):filled+=1
  assert(filled>=64,"Rendered countdown digit must remain visible")
 if "--desktop-polish" in OS.get_cmdline_user_args() and (label.ends_with("cta") or label.ends_with("4_0") or label.ends_with("2_5")):
  var path:=ProjectSettings.globalize_path("res://output/polish-"+suffix+"-"+label+"-desktop.png")
  var code:=OS.execute(ProjectSettings.globalize_path("res://output/capture-game-window"),[str(OS.get_process_id()),path])
  print("POLISH desktop ",label," exit=",code)
func hold(frames: int) -> void:
 if recording:
  for i in range(frames):await process_frame
func run() -> void:
 recording="--record-polish" in OS.get_cmdline_user_args()
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--polish="):suffix=arg.get_slice("=",1)
 game=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 game.preferences_path=""
 game.conductor.clock_override=func():return time
 root.add_child(game)
 game.set_process(false)
 game.intro.set_process(false)
 game.intro.update_at(3.6)
 await capture("cta")
 await hold(90)
 game.intro.update_at(3.9)
 await capture("cta-dim")
 game.intro.visible=false
 game.flow.view.visible=false
 # Backdrop stress-test only: production intro keeps the approved Barbados art.
 game.intro.prompt_panel.reparent(game.hud_layer)
 game.intro.prompt_panel.position=Vector2(20,137)
 game.intro.prompt.modulate=Color.WHITE
 for index in range(game.stage.entries.size()):
  time=0.0
  game.game_mode="pvp"
  game.stage_preference=str(game.stage.entries[index].id)
  game.begin()
  assert(game.stage.selected==index,"Gallery must render the requested actual stage")
  game.cue=4.0
  game.conductor.start(0)
  game.mode="standoff"
  game.intro.prompt_panel.visible=true
  await capture("stage%d-cta" % (index+1))
  await hold(12)
  game.intro.prompt_panel.visible=false
  for at in [0.0,2.5,2.6,3.0,3.5,4.0]:
   time=at
   if at>=4:game.mode="race"
   await capture("stage%d-%s" % [index+1,str(at).replace(".","_")])
   await hold(18)
  game.mode="pickup"
  time=4.4
  await capture("stage%d-pickup" % (index+1))
 if "--desktop-polish" in OS.get_cmdline_user_args():
  root.size=Vector2i(960,540)
  game.intro.prompt_panel.visible=true
  await process_frame
  await capture("960-cta")
 print("UI POLISH GALLERY COMPLETE ",suffix," stages=",game.stage.entries.size())
 game.audio.stop()
 game.queue_free()
 await process_frame
 quit()
