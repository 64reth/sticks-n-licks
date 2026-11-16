extends SceneTree
var game: Node2D
var raw := 0.0
var checks := 0
var failures := 0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(message)
func key(code: int,pressed: bool=true,echo: bool=false) -> void:
 var event:=InputEventKey.new()
 event.keycode=code
 event.pressed=pressed
 event.echo=echo
 game._unhandled_input(event)
func tap(code: int) -> void:
 key(code)
 key(code,false)
func run() -> void:
 game=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 game.preferences_path=""
 game.conductor.clock_override=func():return raw
 root.add_child(game)
 game.set_process(false)
 var intro: ArcadeIntro = game.intro
 check(intro.visible and intro.validate(),"Production root launches valid intro")
 check(game.audio.active=="intro" and game.intro_music_pending,"Original intro starts once")
 check(game.audio.get_children().filter(func(n):return n is AudioStreamPlayer and n==game.audio.music).size()==1,"One shared music player")
 check(intro.sky.texture.get_size()==Vector2(1672,941) and intro.foreground.texture.get_size()==Vector2(1672,941),"Approved layers native size")
 check(intro.sky.texture.resource_path.ends_with("bim_sky.png") and intro.foreground.texture.resource_path.ends_with("bim_foreground.png"),"No gameplay-stage substitution")
 var original_sky: Texture2D=intro.sky.texture
 intro.sky.texture=null
 check(not intro.validate(),"Missing approved intro art is detected for menu fallback")
 intro.update_at(0)
 intro.sky.texture=original_sky
 check(intro.sky.get_index()<intro.foreground.get_index() and intro.foreground.get_index()<intro.logo.get_index(),"Sky foreground logo order")
 check(intro.sky.position.y<=-180 and intro.foreground.position.y>=180,"Initial layers outside viewport")
 intro.update_at(0.3)
 check(intro.sky.position.y<0 and intro.sky.position.y>-180,"Sky slides down")
 intro.update_at(0.8)
 check(intro.foreground.position.y>0 and intro.foreground.position.y<180,"Foreground rises")
 intro.update_at(1.5)
 check(intro.sky.position==Vector2.ZERO and intro.foreground.position==Vector2.ZERO,"Both layers settle at same origin")
 check(intro.sky.scale==intro.foreground.scale and intro.sky.scale.x*1672>=320 and intro.sky.scale.y*941>=180,"Shared transform covers viewport without seam")
 check(not intro.is_ready and not intro.prompt.visible,"No premature prompt/ready state")
 for frame in range(6):
  intro.update_at(2.0+frame/12.0)
  check(intro.logo.frame==int(intro.config.pulse_frames[frame]),"Logo follows 120 BPM phase")
  check(intro.logo.position==Vector2(160,72),"Lettering anchor remains fixed")
 # Skip cannot fast-forward music; a held press must never open main menu.
 intro.update_at(0)
 key(KEY_ENTER)
 check(intro.is_ready and intro.visible and intro.skipped,"First Enter completes visuals")
 check(game.audio.active=="intro" and game.intro_time()==0,"Skip does not seek/restart music")
 key(KEY_ENTER)
 key(KEY_ENTER,true,true)
 check(intro.visible,"Held/echo Enter cannot dismiss title")
 key(KEY_ENTER,false)
 key(KEY_ENTER)
 check(not intro.visible and game.flow.view.page=="title","Distinct Enter opens existing menu")
 key(KEY_ENTER,false)
 check(game.audio.active=="intro","Menu preserves ongoing one-shot intro")
 raw=8.1
 game._process(0)
 check(game.audio.active=="menu" and not game.intro_music_pending,"Menu track takes over once at one-shot end")
 var count: int = game.audio.restart_count
 game._process(0)
 check(game.audio.restart_count==count,"No repeated menu restarts")
 intro.skipped=false
 intro.update_at(game.intro_time())
 check(intro.is_ready,"Title does not replay when menu music starts")
 # Natural reveal independently of skip.
 intro.update_at(2.99)
 check(not intro.prompt.visible,"Prompt before cue hidden")
 intro.update_at(3.0)
 check(intro.prompt.visible and not intro.is_ready,"Prompt reveal cue")
 intro.update_at(3.5)
 check(intro.is_ready,"Natural intro ready cue")
 check(intro.FONT.get_string_size(intro.prompt.text,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x<=intro.prompt.size.x,"Large prompt fits its contrast panel")
 # Stage prop regions stay inside original, and maintain feet despite deformation.
 var prop: BeatSpeaker=game.stage.speaker
 check(prop.definition.rects.size()==6,"Six reviewed speaker regions")
 var all_frames: Dictionary={}
 for i in range(6):
  var values: Array=prop.definition.rects[i]
  check(Rect2(0,0,2172,724).encloses(Rect2(values[0],values[1],values[2],values[3])),"Speaker region in bounds")
  prop.sync(i/12.0,120)
  all_frames[prop.frame]=true
 check(all_frames.size()>=5,"Speaker uses musical squash/rebound poses")
 check(prop.find_children("*","CollisionObject2D").is_empty(),"Environmental prop has no collision")
 var configured:=0
 for i in range(game.stage.entries.size()):
  game.stage.select_stage(i)
  if prop.visible:configured+=1
 check(configured==1,"Only approved demonstration stage enables speaker")
 game.stage.select_stage(2)
 var position: Vector2=prop.position
 prop.sync(0.0834,120)
 prop.sync(0.1667,120)
 check(prop.position==position and prop.position==prop.position.round(),"Prop anchor integer and stable")
 # Tutorial mapping and safe return with paused music/CPU/clock/inputs.
 game.game_mode="pvp"
 game.begin()
 game.mode="combat"
 game.set_paused(true)
 var frozen: float=game.conductor.now()
 var positions: Array=game.bout.positions.duplicate()
 var hits: Array=game.bout.hits.duplicate()
 game.flow.open("help")
 for i in range(3):
  var tutorial: TutorialPages=game.flow.view.tutorial
  check(tutorial.current==i,"Tutorial page order")
  var pictures:=tutorial.get_children().filter(func(n):return n is Sprite2D)
  check(pictures.size()==1 and pictures[0].texture==tutorial.DIAGRAMS[i],"Correct inspected illustration")
  if pictures.size()==1:
   var picture: Sprite2D=pictures[0]
   check(Rect2(0,0,320,150).encloses(Rect2(picture.position,picture.texture.get_size()*picture.scale)),"Illustration fitted into visible tutorial area")
  tap(KEY_RIGHT)
 raw+=30
 tap(KEY_A)
 tap(KEY_F)
 tap(KEY_ESCAPE)
 check(game.paused and game.flow.view.page=="pause","Tutorial Escape returns paused menu")
 check(game.conductor.now()==frozen and game.bout.positions==positions and game.bout.hits==hits,"Tutorial preserves paused clock and combat")
 check(game.paused and game.cpu_attempts.is_empty(),"No CPU dispatch during paused tutorial")
 tap(KEY_ESCAPE)
 check(not game.paused and is_equal_approx(game.conductor.now(),frozen),"Resume without clock catch-up")
 print("MILESTONE 007: %d checks, %d failures" % [checks,failures])
 game.audio.stop()
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)
