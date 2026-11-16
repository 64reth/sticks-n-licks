extends SceneTree
var game: Node2D
var time: float=0.0
var captured: Array[String]=[]
func _initialize() -> void:call_deferred("run")
func capture(name: String) -> void:
 game.refresh()
 game.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 if DisplayServer.get_name()!="headless":
  root.get_texture().get_image().save_png("res://output/gallery006-"+name+".png")
  captured.append(name)
func key(code: int) -> void:MenuTestInput.key(game,code)
func action(player: int,name: String) -> void:
 var event:=InputEventAction.new()
 event.action="p%d_%s" % [player+1,name]
 event.pressed=true
 game._unhandled_input(event)
 event=event.duplicate()
 event.pressed=false
 game._unhandled_input(event)
func advance(at: float) -> void:
 time=at
 game._process(0.016)
func combat(attacker: int=0,best: int=3) -> void:
 game.game_mode="pvp"
 game.mode="combat"
 game.bout=Bout.new()
 game.bout.initiative=attacker
 game.bout.positions.assign([110.0,150.0])
 game.match_progress.reset(best)
 game.phrase_resolved=false
 game.result_handled=false
 game.exchange_phrase=0
 game.selected.assign([-1,-1])
 game.movement_stun.assign(["",""])
 game.pose_until_by_player.assign([0.0,0.0])
 game.step_started.assign([-INF,-INF])
 for control in game.controls:control.reset()
 for p in range(2):
  game.fighters[p].reset_visual()
  game.fighters[p].set_pose("combat_idle")
 time=0
 game.conductor.start(0)
 advance(0)
func strike(attacker: int,parry: bool=false) -> void:
 action(attacker,"high")
 action(attacker,"execute")
 if parry:
  action(1-attacker,"high")
  action(1-attacker,"execute")
func run() -> void:
 game=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 game.preferences_path=""
 game.conductor.clock_override=func():return time
 root.add_child(game)
 game.set_process(false)
 await capture("title")
 for page in ["setup","options","audio","display","gameplay","help"]:
  game.flow.root(page)
  await capture(page)
 game.flow.root("display")
 key(KEY_RIGHT)
 await capture("fullscreen")
 key(KEY_RIGHT)
 for best in [3,5,7]:
  combat(0,best)
  await capture("hud-best%d" % best)
 game.set_paused(true)
 await capture("pause")
 game.set_paused(false)
 for stage in range(game.stage.entries.size()):
  game.stage.select_stage(stage)
  await capture("stage-"+str(game.stage.entries[stage].id))
 game.stage.select_stage(0)
 for fighter in range(2):
  combat(fighter)
  advance(1.5)
  strike(fighter,true)
  advance(1.741)
  for frame in range(3):
   await capture("fighter%d-stunned-%d" % [fighter+1,frame])
   await create_timer(0.12).timeout
  combat(1-fighter)
  advance(1.5)
  strike(1-fighter)
  advance(1.741)
  for frame in range(2):
   await capture("fighter%d-hurt-%d" % [fighter+1,frame])
   await create_timer(0.11).timeout
  combat(fighter)
  game.game_mode="cpu"
  game.cpu.parameters.hesitate=1.0
  game.cpu.parameters.retreat=0.0
  game.match_progress.round_wins[fighter]=1
  game.bout.hits[fighter]=2
  advance(1.5)
  # Use the same validator for a controlled deciding hit; no animation-forced result.
  game.submit_action(fighter,"high",true,time,"cpu" if fighter==1 else "human")
  game.submit_action(fighter,"execute",true,time,"cpu" if fighter==1 else "human")
  advance(1.741)
  advance(2.0)
  for frame in range(4):
   await capture("fighter%d-victory-%d" % [fighter+1,frame])
   await create_timer(0.22).timeout
  await capture("fighter%d-defeated-final" % (2-fighter))
  await capture("human-"+("victory" if fighter==0 else "defeat"))
 combat(1)
 game.match_progress.round_wins[1]=1
 game.bout.hits[1]=2
 advance(1.5)
 strike(1)
 advance(1.741)
 advance(2.0)
 await capture("pvp-result")
 print("GRAPHICS 006: ",captured.size()," captures")
 game.audio.stop()
 game.conductor.clock_override=Callable()
 game.queue_free()
 quit()
