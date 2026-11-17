extends SceneTree
var checks:=0
var failures:=0
var raw:=0.0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(message)
func run() -> void:
 var clock:=RhythmConductor.new()
 clock.clock_override=func():return raw
 clock.start(0)
 var scene:=preload("res://scenes/props/coconut_palm.tscn")
 var first: CoconutPalm=scene.instantiate()
 var second: CoconutPalm=scene.instantiate()
 root.add_child(first)
 root.add_child(second)
 first.bind_clock(clock)
 second.bind_clock(clock)
 second.phase_offset_beats=2
 check(first.SHEET==second.SHEET,"Instances share original GPU texture")
 check(first.get_child_count()==0,"No animation timers, collision or extra actors")
 check(first.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"Nearest filtering")
 for i in range(8):
  var r:=first.region(i)
  check(r==Rect2(i%4*362,i/4*543,362,543),"Actual 4x2 source region")
  check(Rect2(0,0,1448,1086).encloses(r),"Region within source")
  var dest:=first.destination(i)
  check(dest.position==dest.position.round() and dest.size==dest.size.round(),"Integer-pixel draw rectangle")
  var base:=dest.position+CoconutPalm.ANCHORS[i]*first.display_scale
  check(absf(base.x)<=.5 and absf(base.y)<=.5,"Trunk base stable within pixel rounding")
 for cycle in range(4):
  for beat in range(8):
   for fraction in [0.0,.25,.999]:
    var absolute: float=float(cycle*8+beat)+fraction
    check(first.frame_at(absolute)==beat,"Eight authored beats map as reviewed")
    check(second.frame_at(absolute)==(beat+2)%8,"Deterministic two-beat phase advance")
 check(first.frame_at(7.999)==7 and first.frame_at(8)==0,"Seamless phrase wrap")
 first.start_frame=3
 check(first.frame_at(0)==3 and first.frame_at(8)==3,"Configurable start frame")
 first.start_frame=0
 for bpm in [120,140,160]:
  raw=0
  clock.pause_offset=0
  clock.start(0,bpm)
  for i in range(33):
   raw=i*clock.duration()+clock.duration()*.4
   clock.update(raw)
   first.sync_clock()
   check(first.frame==i%8,"Authoritative fractional phase at supported tempo")
  clock.set_paused(true)
  var frozen:=first.frame
  var beat_before:=first.sampled_beat
  raw+=60
  first.sync_clock()
  check(first.frame==frozen and is_equal_approx(first.sampled_beat,beat_before),"Pause freezes phase without object timer")
  clock.set_paused(false)
  first.sync_clock()
  check(is_equal_approx(first.sampled_beat,beat_before),"Resume does not catch up wall time")
 first.queue_free()
 second.queue_free()
 # Real Story lifecycle, using an isolated save/preferences path.
 raw=0
 var game=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 game.preferences_path=""
 game.conductor.clock_override=func():return raw
 root.add_child(game)
 game.set_process(false)
 game.open_main_menu()
 game.story.start(true)
 var palm: CoconutPalm=game.story.screens.current.get_node("CoconutPalm")
 var screen: StoryScreen=game.story.screens.current
 check(screen.get_children().filter(func(n):return n is CoconutPalm).size()==1,"Final Screen 01 has exactly one palm")
 check(palm.z_index==-1 and screen.get_node("Backdrop").z_index==-2,"Palm behind house and above backdrop")
 check(palm.position==Vector2(42,149),"Reviewed composition placement")
 check(palm.conductor==game.conductor,"Same conductor as fighter, no duplicate clock")
 var epoch: float=game.conductor.epoch
 for time in [1.0,2.0,3.0,7.5,8.0,8.5]:
  raw=time
  game._process(0)
  if time in [1.0,2.0]:
   for press in range(2):
    game.story.submit("execute",true,raw)
    game.story.submit("execute",false,raw)
  palm.sync_clock()
  check(palm.frame==int(time*2)%8,"No discontinuity through kick/landing/recovery/handoff")
 for line in range(3):
  game.story.submit("execute",true,raw)
  game.story.submit("execute",false,raw)
 game.story.advance()
 check(game.story.phase=="playing" and game.conductor.epoch==epoch,"Handoff preserves conductor")
 game.story.submit("right",true,8.5)
 game.story.submit("right",false,8.51)
 raw=8.7
 game._process(0)
 check(game.story.target_x==116 and game.fighters[0].position.x==116,"Existing 16px / 160ms movement unchanged")
 var expected:=palm.frame_at(game.story.absolute_beat())
 game.story.start(true)
 var replacement: CoconutPalm=game.story.screens.current.get_node("CoconutPalm")
 replacement.sync_clock()
 check(replacement.frame==expected and game.conductor.epoch==epoch,"Restart binds current phase instead of resetting palm")
 game.story.finish_cinematic()
 replacement.sync_clock()
 check(replacement.frame==expected,"Skip does not reset palm")
 await process_frame
 check(not is_instance_valid(palm),"Old screen/palm freed after restart")
 game.set_paused(true)
 replacement.sync_clock()
 var phase_before:=replacement.sampled_beat
 raw+=10
 game._process(0)
 replacement.sync_clock()
 check(replacement.sampled_beat==phase_before,"Story pause freezes palm")
 game.set_paused(false)
 replacement.sync_clock()
 check(replacement.sampled_beat==phase_before,"Story resume preserves phase")
 game.return_to_title()
 game.story.start(false)
 var reentry: CoconutPalm=game.story.screens.current.get_node("CoconutPalm")
 raw+=.5
 game._process(0)
 reentry.sync_clock()
 check(reentry.frame==int(floor(reentry.sampled_beat))%8,"Re-entry follows new session conductor")
 game.queue_free()
 await process_frame
 check(not is_instance_valid(reentry),"No palm survives session teardown")
 print("PALM 010: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
