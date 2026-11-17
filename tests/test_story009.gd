extends SceneTree
var game: Node2D
var raw:=0.0
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(message)
func advance(at: float) -> void:
 raw=at+game.conductor.pause_offset
 game._process(0)
func run() -> void:
 game=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 game.preferences_path=""
 game.conductor.clock_override=func():return raw
 root.add_child(game)
 game.set_process(false)
 game.open_main_menu()
 check(game.flow.view.rows[3].command=="story_menu","Story menu appended without moving Arcade/options/tutorial")
 game.flow.command("story_menu")
 check(game.flow.view.rows[1].disabled,"Continue disabled without save")
 game.flow.command("story_new")
 var story: StorySession=game.story
 var actor: Fighter=game.fighters[0]
 var identity:=actor.get_instance_id()
 check(game.mode=="story" and story.phase=="cinematic","New Game enters opening")
 check(game.audio.active=="120" and game.audio.tracks.has(game.audio.active),"Story selects existing native-tempo music key")
 var epoch: float=game.conductor.epoch
 for i in range(15):
  advance(i*.5)
  if i in [1,3]:
   for press in range(2):
    story.submit("execute",true,raw)
    story.submit("execute",false,raw)
  story.submit("right",true,raw)
  check(is_equal_approx(story.target_x,100),"Cinematic rejects movement")
  check(story.control.pending_move==0,"No cinematic movement queue")
  story.submit("right",false,raw)
 advance(7.51)
 for line in range(3):
  story.submit("execute",true,raw)
  story.submit("execute",false,raw)
 advance(7.75)
 for line in range(3):
  story.submit("execute",true,raw)
  story.submit("execute",false,raw)
 check(story.phase=="waiting","Recovery becomes unarmed idle before handoff")
 check(actor.pose=="story_idle","Existing unarmed idle selected")
 var position: Vector2=actor.position
 var restarts: int=game.audio.restart_count
 var scale: Vector2=actor.sprite.scale
 var sprite_position: Vector2=actor.sprite.position
 story.submit("right",true,raw)
 advance(8)
 check(story.phase=="playing","Control on next valid beat")
 check(actor.get_instance_id()==identity,"Exactly same actor")
 check(actor.position==position and actor.sprite.scale==scale and actor.sprite.position==sprite_position,"Handoff preserves exact ground/scale/metadata")
 check(game.conductor.epoch==epoch,"No conductor reset")
 check(game.audio.restart_count==restarts and game.audio.active=="120","No music restart at handoff")
 story.submit("right",true,raw)
 check(story.target_x==100,"Cinematic held input cannot leak")
 story.submit("right",false,raw)
 # Direct differential against the actual Versus scene/action adapter, on identical clocks.
 var versus=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 versus.preferences_path=""
 versus.conductor.clock_override=func():return raw
 root.add_child(versus)
 versus.set_process(false)
 versus.game_mode="pvp"
 versus.begin()
 versus.mode="combat"
 versus.conductor.start(0)
 versus.bout.positions.assign([100.0,280.0])
 versus.fighters[0].position=Vector2(100,150)
 versus.movement_stun.assign(["",""])
 var events: Array[Dictionary]=[
  {"at":8.02,"action":"right","pressed":true}, {"at":8.04,"action":"right","pressed":false},
  {"at":8.10,"action":"left","pressed":true}, {"at":8.12,"action":"left","pressed":false},
  {"at":8.31,"action":"right","pressed":true}, {"at":8.33,"action":"right","pressed":false},
  {"at":8.35,"action":"left","pressed":true}, {"at":8.37,"action":"left","pressed":false},
  {"at":8.69,"action":"left","pressed":true}, {"at":8.70,"action":"left","pressed":false},
  {"at":9.02,"action":"right","pressed":true}, {"at":10.02,"action":"right","pressed":true},
  {"at":10.10,"action":"right","pressed":false}, {"at":10.50,"action":"low","pressed":true},
  {"at":10.52,"action":"left","pressed":true}, {"at":10.54,"action":"left","pressed":false},
  {"at":10.75,"action":"low","pressed":false}]
 # Keep combat unresolved so the differential isolates movement, no attacks/damage.
 for row in events:
  advance(row.at)
  versus.conductor.update(row.at)
  versus.phrase_resolved=true
  story.submit(row.action,row.pressed,row.at)
  versus.submit_action(0,row.action,row.pressed,row.at)
  check(story.control.movement_grade==versus.controls[0].movement_grade,"Same input acceptance at %.2f" % row.at)
  check(story.control.pending_target==versus.controls[0].pending_target,"Same early tap buffering at %.2f" % row.at)
  check(story.target_x==versus.bout.positions[0],"Same displacement at %.2f" % row.at)
  check(story.control.last_movement_beat==versus.controls[0].last_movement_beat,"Same single tap consumption at %.2f" % row.at)
  if story.player_state()=="MOVING":check(actor.pose=="story_"+versus.fighters[0].pose,"Same semantic animation selection")
  check(versus.bout.hits==[0,0],"Traversal does not alter combat damage")
 advance(11)
 story.submit("low",true,11)
 check(actor.pose=="story_duck","Existing race crouch pose is usable")
 story.submit("low",false,11)
 check(actor.pose=="story_idle","Duck release returns idle")
 var before: float=game.conductor.now()
 game.set_paused(true)
 raw+=10
 game._process(0)
 check(game.conductor.now()==before,"Pause freezes shared clock")
 game.set_paused(false)
 check(game.conductor.now()==before,"Resume has no catch-up")
 var before_epoch: float=game.conductor.epoch
 story.start(false)
 check(game.conductor.epoch==before_epoch,"Checkpoint revisit preserves conductor phase")
 check(story.phase=="waiting" and actor.position.x==100,"Continue safe checkpoint waits for beat")
 advance(11.5)
 check(story.phase=="playing","Continue unlocks on beat")
 # Walk to exit through the real production adapter; no manual position writes.
 for n in range(12):
  var at:=12.0+n*.5
  advance(at)
  story.submit("right",true,at)
  story.submit("right",false,at+.01)
  advance(at+.20)
 check(story.phase=="transition","Exit queues next beat after final movement finishes")
 check(actor.position.x==float(story.config.playable_right),"Right screen boundary clamps safely")
 check(story.pending_screen==2,"Screen 01 now leads to village")
 game.refresh()
 check(story.overlay.visible,"Traversal HUD remains available at screen transition")
 check(story.save.valid() and story.save.data.version==2,"Versioned checkpoint")
 game.flow.command("story_menu")
 check(game.mode=="menu" and game.flow.view.page=="story_menu","Return to Story menu")
 check(not game.flow.view.rows[1].disabled,"Continue enabled")
 game.flow.command("story_new")
 check(game.flow.view.page=="story_new_confirm","New Game confirms before replacing progress")
 game.flow.command("back")
 game.flow.command("story_continue")
 check(story.phase=="waiting","Continue omits cinematic")
 game.set_paused(true)
 game.flow.command("title")
 check(game.mode=="menu" and not story.overlay.visible and story.phase=="inactive","Leaving paused Story clears overlay")
 check(game.stage.visible and game.fighters[1].visible,"Arcade presentation restored after Story pause")
 story.start(true)
 check(story.phase=="cinematic","Replay opening")
 story.finish_cinematic()
 check(story.phase=="waiting" and story.screens.current.house_frame==1,"Skip settles house and idle")
 var environment:=BeatAnimation.new()
 environment.cues.assign([{"beat":0,"frame":0},{"beat":2,"frame":1}])
 environment.length=4
 environment.looping=true
 environment.offset=1
 environment.start(10)
 check(environment.sample(10).is_empty(),"Environmental offset")
 check(environment.sample(13).frame==1 and environment.sample(15).frame==0,"Environmental loop uses absolute beats")
 environment.stop()
 check(environment.sample(20).is_empty(),"Environmental stop")
 # Disk validation is isolated to ignored test output, never the owner's save.
 var disk:=StorySave.new()
 disk.path="res://output/story-save-test.json"
 if FileAccess.file_exists(disk.path):DirAccess.remove_absolute(ProjectSettings.globalize_path(disk.path))
 check(not disk.load_progress(),"Missing save handled")
 for text in ["bad json","[]",'{"version":2}', '{"version":1,"campaign":"other"}', '{"version":1,"campaign":"rent_due","unlocked_screen":1,"checkpoint":"traversal","opening_complete":false}']:
  var file:=FileAccess.open(disk.path,FileAccess.WRITE)
  file.store_string(text)
  file.close()
  check(not disk.load_progress(),"Malformed/incompatible save rejected")
 disk.checkpoint("traversal")
 check(disk.load_progress(),"Versioned save round trip")
 check(disk.data.keys().size()==10,"Version 2 persists quest, inventory and wallet checkpoint")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(disk.path))
 game.return_to_title()
 MenuTestInput.start(game)
 check(game.mode=="standoff","Arcade still launches")
 versus.queue_free()
 game.queue_free()
 await process_frame
 print("STORY 009: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
