extends SceneTree
var checks: int = 0
var failures: int = 0
var time: float = 0.0
func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 for player in range(2):
  var fighter := Fighter.new()
  fighter.asset_config = "res://data/animations/fighter_0%d.json" % (player+1)
  root.add_child(fighter)
  fighter.face(1 if player==0 else -1)
  check(not fighter.sprite.flip_h,"Neither supplied fighter needs default mirroring")
  for state in fighter.animation_meta:
   fighter.set_pose(state)
   var frames := fighter.sprite.sprite_frames
   var count := frames.get_frame_count(state)
   check(count>0,"Animation has frames")
   for index in range(count):
    var texture := frames.get_frame_texture(state,index)
    check(texture != null and texture.get_size()==Vector2(768,768),"Every frame loads at native padded resolution")
   var meta: Dictionary = fighter.animation_meta[state]
   var ground := fighter.sprite.position.y + (float(meta["ground_pixel"])-384)*fighter.sprite.scale.y
   check(abs(ground)<0.001,"All animations share a ground anchor")
  fighter.impact("high_attack",0.3)
  check(fighter.sprite.frame==3,"Attack impact frame selected immediately at beat four")
  fighter.parry("low",0.3)
  check(fighter.spark_time>0 and fighter.sprite.animation=="low_parry","Parry uses supplied block plus feedback")
  fighter.face(-1 if player==0 else 1)
  check(fighter.sprite.flip_h,"Facing reversal mirrors exactly once")
  fighter.queue_free()
 # Visual impact is beat-aligned while adjudication still waits for buffered input.
 var scene := load("res://scenes/main/main.tscn") as PackedScene
 var game = scene.instantiate()
 game.conductor.clock_override = func(): return time
 root.add_child(game)
 game.set_process(false)
 game.conductor.start(0)
 game.bout.positions.assign([140.0, 180.0])
 game.mode = "combat"
 game.conductor.update(0)
 time = 1.49
 for action in ["p1_high","p2_low","p1_execute","p2_execute"]:
  var event := InputEventAction.new()
  event.action = action
  event.pressed = true
  game._unhandled_input(event)
 check(game.fighters[0].sprite.animation == "high_attack" and game.fighters[0].sprite.frame < 3,"Early valid input winds up before fourth-beat impact")
 time = 1.5
 game.conductor.update(time)
 check(game.fighters[0].sprite.animation == "high_attack" and game.fighters[0].sprite.frame == 3,"Attack impact pose on fourth beat")
 check(game.fighters[1].sprite.animation == "low_block" and game.fighters[1].sprite.frame == 2,"Defensive pose on fourth beat")
 check(game.bout.hits == [0,0],"Animation does not prematurely award a hit")
 game.fighters[0].sprite.stop()
 time = 1.741
 game._process(0.01)
 check(game.bout.hits == [1,0],"Animation stopping cannot interrupt state resolution")
 game.conductor.clock_override = Callable()
 game.audio.clock_source = Callable()
 game.queue_free()
 var audio := AudioDirector.new()
 audio.enabled = false
 audio.clock_source = func():return time
 root.add_child(audio)
 for key in ["menu","intro","standoff","120","140","160","victory","defeat"]:
  check(audio.tracks.has(key),"Referenced audio resource loads: "+key)
  var stream: AudioStreamWAV = audio.tracks[key]
  check(stream.stereo and stream.mix_rate==44100,"Audio channel count and sample rate preserved on import")
  check(stream.get_length()>0,"Recording has positive length")
  if audio.entries[key].get("loop",false):
   check(stream.loop_end>stream.loop_begin,"Valid candidate loop range")
 for bpm in [120,140,160]:
  var length: float = 960.0/bpm
  var prev := 0.0
  for tick in range(1000):
   var at := tick*0.05
   var raw := fposmod(at,length)
   var unwrapped := AudioDirector.unwrap(raw,at,length)
   check(abs(unwrapped-at)<0.000001 and unwrapped>=prev,"Loop clock remains continuous at every tempo")
   prev = unwrapped
 audio.play_track("120",0)
 audio.schedule_track("140",2)
 time=1.999
 audio._process(0)
 check(audio.active=="120","No early music transition")
 time=2
 audio._process(0)
 check(audio.active=="140" and audio.anchor==2,"Transition at scheduled musical boundary")
 check(not audio.effects.playing,"No duplicated music in effect player")
 audio.stop()
 audio.clock_source = Callable()
 audio.queue_free()
 print("MEDIA TESTS: %d checks, %d failures" % [checks,failures])
 quit(0 if failures==0 else 1)
