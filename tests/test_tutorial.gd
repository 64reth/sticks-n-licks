extends SceneTree
var game: Node2D
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(message)
func _initialize() -> void:call_deferred("run")
func key(code: int) -> void:MenuTestInput.key(game,code)
func run() -> void:
 game=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 game.preferences_path=""
 root.add_child(game)
 game.set_process(false)
 key(KEY_DOWN)
 key(KEY_DOWN)
 key(KEY_ENTER)
 var tutorial: TutorialPages=game.flow.view.tutorial
 check(game.flow.view.page=="help" and tutorial.visible,"Title opens tutorial")
 check(tutorial.current==0,"Open at page one")
 var positions: Array=game.bout.positions.duplicate()
 var bindings: Dictionary={"p1_left":KEY_A,"p1_right":KEY_D,"p1_high":KEY_W,"p1_low":KEY_S,"p1_execute":KEY_F,"p2_left":KEY_LEFT,"p2_right":KEY_RIGHT,"p2_high":KEY_UP,"p2_low":KEY_DOWN,"p2_execute":KEY_SHIFT}
 for action in bindings:
  var events:=InputMap.action_get_events(action)
  check(events.size()==1,"One actual key for "+action)
  var event: InputEventKey=events[0]
  check(event.physical_keycode==bindings[action],"Diagram matches InputMap: "+action)
  if action=="p2_execute":check(event.location==KEY_LOCATION_RIGHT,"Right Shift, not Left Shift")
 for page in range(3):
  check(tutorial.current==page,"Page order")
  for text in tutorial.text_bounds:
   var rect: Rect2=text.rect
   check(text.node.get_rect()==rect,"Actual Label bounds: "+text.text)
   var needed:=tutorial.FONT.get_string_size(text.text,HORIZONTAL_ALIGNMENT_LEFT,-1,text.size)
   check(Rect2(0,0,320,180).encloses(rect),"Visible text: "+text.text)
   check(needed.x<=rect.size.x and needed.y<=rect.size.y,"Text fits: "+text.text)
  for action in tutorial.key_actions:check(bindings.has(action),"Real gameplay action")
  key(KEY_ENTER)
  key(KEY_UP)
  check(tutorial.current==page and game.flow.view.page=="help","Only Left/Right changes pages")
  if page<2:key(KEY_RIGHT)
 key(KEY_RIGHT)
 check(tutorial.current==2,"End clamps")
 key(KEY_LEFT)
 check(tutorial.current==1,"Back a page")
 # Duplicate physical presses and OS repeats do not skip pages.
 var held:=InputEventKey.new()
 held.keycode=KEY_LEFT
 held.pressed=true
 game._unhandled_input(held)
 game._unhandled_input(held)
 held.echo=true
 game._unhandled_input(held)
 check(tutorial.current==0,"Held and echo navigation cannot skip pages")
 held.pressed=false
 held.echo=false
 game._unhandled_input(held)
 check(game.bout.positions==positions and game.mode=="menu","Tutorial cannot move fighters")
 key(KEY_ESCAPE)
 check(game.flow.view.page=="title" and not tutorial.visible,"Escape returns title")
 game.flow.open("help")
 check(tutorial.current==0,"Reopening resets page")
 key(KEY_ESCAPE)
 game.flow.open("options")
 game.flow.open("gameplay")
 game.flow.open("help")
 key(KEY_ESCAPE)
 check(game.flow.view.page=="gameplay","Escape returns previous options page")
 # Verify MID combinations in both facings; same height is used to defend.
 for facing in [-1,1]:
  var control:=CombatInput.new()
  control.feed("right" if facing==1 else "left",true,0,facing)
  check(control.direction(0,facing)==1,"MID uses facing-relative forward")
 print("TUTORIAL: %d checks, %d failures" % [checks,failures])
 game.queue_free()
 quit(1 if failures else 0)
