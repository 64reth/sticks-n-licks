extends SceneTree
var checks:=0
var failures:=0
var raw:=0.0
var game: Node2D
func _initialize() -> void:call_deferred("run")
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(why)
func tick(at: float) -> void:
 raw=at+game.conductor.pause_offset
 game._process(0)
func action(name: String) -> void:
 if name=="execute" and not game.story.dialogue.active():
  if game.story.context_interaction().get("id")=="vendor":
   var at: float=game.conductor.action_time()
   if at<=raw:at+=game.conductor.duration()*4
   tick(at)
  else:tick(ceil((raw+.001)*2)/2)
 game.story.submit(name,true,raw)
 game.story.submit(name,false,raw)
func drain() -> void:
 for i in range(96):
  if not game.story.dialogue.active():break
  action("execute")
  tick(ceil(game.conductor.now()*4)/4+.25)
func run() -> void:
 var quest:=QuestLog.new()
 check(not quest.emit_event("fight_won"),"Cannot complete locked objective")
 for event in ["opening_complete","village_entered","vendor_spoken","crate_picked","road_crossed","crate_delivered","delivery_paid","cane_road_entered","cane_cleared","stick_picked","fight_won"]:
  check(quest.emit_event(event),"Ordered quest event "+event)
  check(not quest.emit_event(event),"Quest event idempotent "+event)
 check(quest.finished(),"Full quest complete")
 quest.definition.quests.append({"id":"optional_test","optional":true,"steps":[{"id":"optional_fixture","text":"Test-only optional objective","event":"optional_done"}]})
 check(quest.emit_event("optional_done","optional_test"),"Optional quest progresses independently")
 check(quest.finished("optional_test") and quest.finished(),"Optional completion does not alter main quest")
 var restored:=QuestLog.new()
 restored.restore(quest.completed)
 check(restored.finished(),"Quest round trip")
 restored.restore(["fight","crate"])
 check(restored.completed.is_empty(),"Invalid order cannot unlock quest")
 var inventory:=StoryInventory.new()
 check(inventory.pickup("crate"),"Crate pickup")
 check(not inventory.pickup("stick"),"One-slot invariant")
 check(not inventory.remove("stick"),"Validated removal")
 check(inventory.remove("crate") and inventory.pickup("stick"),"Handover frees slot")
 var wallet:=StoryWallet.new()
 check(wallet.grant("crate_delivery",5) and not wallet.grant("crate_delivery",5),"Reward exactly once")
 check(wallet.money==5,"BDS 5, no invented rewards")
 var obstacle:=StoryObstacles.new()
 for beat in range(12):check(not obstacle.traffic_active(beat),"Twelve safe beats")
 check(obstacle.traffic_warning(12) and obstacle.traffic_active(14),"Two-beat traffic warning")
 for start in range(5):
  check(obstacle.can_start_crossing(start),"Green entry permits a full safe crossing")
  for step in range(7):check(not obstacle.traffic_active(start+step+.32),"Every approved step fits before traffic")
 check(not obstacle.can_start_crossing(6),"Late starters are clearly told to wait")
 check(obstacle.CROSS_STEPS==11,"Actual two-road crossing step count (five plus six)")
 var dialog:=StoryDialogue.new()
 dialog.begin("vendor")
 check(dialog.queue.size()==7,"All seven exact vendor lines retained")
 dialog.press(true)
 dialog.on_subdivision()
 dialog.press(true)
 dialog.on_subdivision()
 check(dialog.queue.size()==7 and dialog.is_revealed(),"Holding F cannot advance after reveal")
 dialog.press(false)
 dialog.press(true)
 dialog.on_subdivision()
 check(dialog.queue.size()==6,"Fresh F advances a revealed line")
 dialog.clear()
 check(not dialog.active() and not dialog.pending,"Dialogue clears safely")
 var clock:=RhythmConductor.new()
 clock.clock_override=func():return raw
 clock.start(0)
 clock.update(0)
 var world:=BeatWorld.new(clock)
 raw=1.25
 clock.update(raw)
 check(is_equal_approx(world.beat(),2.5),"Shared fractional beat")
 check(world.pose(8,8,2)==4,"Different personality, same clock")
 clock.set_paused(true)
 var phase:=world.phase(8)
 raw+=50
 check(world.phase(8)==phase,"World freezes in pause")
 clock.set_paused(false)
 check(is_equal_approx(world.phase(8),phase),"No world drift after resume")
 raw=0
 game=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 game.preferences_path=""
 game.conductor.clock_override=func():return raw
 root.add_child(game)
 game.set_process(false)
 game.open_main_menu()
 game.story.start(true)
 var story: StorySession=game.story
 for entries in story.dialogue.definitions.values():
  for entry in entries:
   var wrapped:=story.overlay.wrapped_lines(str(entry.text))
   check(wrapped.size()<=3,"Dialogue fits three native lines")
   for line in wrapped:check(StoryOverlay.FONT.get_string_size(line.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,8).x<=278,"Dialogue stays inside panel padding")
 check(not story.actor.visible,"Fighter hidden before kick, no race crouch")
 check(story.dialogue.line().text=="Every month is de same foolishness! Where de rent money?","Exact wife dialogue")
 var epoch: float=game.conductor.epoch
 for t in [0.0,1.0,2.0,3.0,7.5]:
  tick(t)
  drain()
 drain()
 tick(ceil(raw*2)/2+.5)
 check(story.phase=="playing","Dialogue then next-beat control")
 check(game.conductor.epoch==epoch,"Opening does not reset conductor")
 # Use actual legal steps through every screen, including mandatory quest gates.
 walk_to(280)
 tick(ceil(raw*2)/2+.5)
 check(story.screens.screen_id==2,"Beat-aligned Screen 02 transition")
 walk_to(84)
 action("execute")
 drain()
 check(story.quest.completed.has("vendor"),"Mandatory vendor conversation event")
 walk_to(132)
 action("execute")
 check(story.inventory.item=="crate","On-beat pickup visible carried state")
 walk_to(280)
 tick(ceil(raw*2)/2+.5)
 check(story.screens.screen_id==3,"Crate gate to crossing")
 # Deliberate vehicle collision using the real obstacle predicate at contact, then recovery.
 walk_to(100)
 for guard in range(2000):
  tick(raw+.03)
  if story.phase=="recovering":break
 check(story.phase=="recovering","Vehicle collision detected")
 check(story.inventory.item=="crate" and story.wallet.money==0,"Collision retains crate and money")
 tick((story.recovery_beat+.1)*.5+game.conductor.epoch)
 check(story.phase=="playing" and story.target_x==36,"Nearest reached safe checkpoint recovery")
 # Begin at cycle start, seven accepted taps across a twelve-beat safe window.
 cross_road(0)
 cross_road(1)
 check(story.quest.completed.has("cross"),"Actual crossing completes nested objective")
 action("execute")
 drain()
 check(story.inventory.item=="" and story.wallet.money==5,"Delivery transfer and BDS 5")
 story.interact("delivery")
 check(story.wallet.money==5,"No duplicate delivery reward")
 walk_to(280)
 tick(ceil(raw*2)/2+.5)
 check(story.screens.screen_id==4,"Cane road entered")
 for id in [4,5]:
  walk_to(148)
  action_hold_low(true)
  for i in range(35):tick(raw+.25)
  check(story.defenses>=(1 if id==4 else 2),"Conductor warning/duck resolution")
  walk_to(280)
  action_hold_low(false)
  tick(ceil(raw*2)/2+.5)
 check(story.screens.screen_id==6,"Cane cleared, stick clearing")
 walk_to(100)
 action("execute")
 drain()
 tick(ceil(raw/2)*2+2)
 check(story.inventory.item=="stick" and story.phase=="fight","Existing combat handoff")
 check(game.mode=="standoff" and game.game_mode=="cpu","Production match countdown/CPU context")
 check(not story.overlay.visible,"Quest HUD yields to existing combat HUD")
 tick(raw+.02)
 check(not game.fighters[0].sprite.is_playing() and not game.fighters[1].sprite.is_playing(),"Story fight sprites sample conductor rather than free-run")
 check(game.bout.hits==[0,0],"No free damage or initiative reward")
 # Resolve the full best-of-three using legal actions, including race and movement.
 game.cpu.queue.clear()
 game.game_mode="pvp"
 for guard in range(300):
  if game.mode=="match_win":break
  if game.mode in ["standoff","race"]:
   tick(game.cue+.01)
   game.submit_action(0,"execute",true,raw)
   game.submit_action(0,"execute",false,raw)
   game.submit_action(1,"execute",true,raw+.03)
   game.submit_action(1,"execute",false,raw+.03)
   tick(raw+.05)
  elif game.mode=="pickup":tick(story.fight_due)
  elif game.mode=="combat":
   tick(game.conductor.beat_time+game.conductor.duration())
   if absf(game.bout.positions[1]-game.bout.positions[0])>game.bout.stick_reach:
    game.submit_action(0,"right",true,raw)
    game.submit_action(0,"right",false,raw)
   if game.conductor.beat==4:
    game.submit_action(0,"high",true,raw)
    game.submit_action(0,"execute",true,raw)
    game.submit_action(0,"execute",false,raw)
    game.submit_action(0,"high",false,raw)
    tick(raw+.25)
  elif game.mode=="finishing":tick(game.transition_until+.001)
  elif game.mode=="round_win":tick(game.round_transition_at+.001)
 check(story.quest.finished() and game.match_progress.round_wins==[2,0],"Two three-hit round wins complete first match quest")
 check(story.wallet.money==25,"Full match awards configured BDS20 after delivery")
 check(game.conductor.epoch==epoch,"Six screens and full match preserve conductor epoch")
 story.return_from_match()
 drain()
 check(story.phase=="playing","Subquest complete returns to active campaign")
 var disk:=StorySave.new()
 disk.path="res://output/story011-save-test.json"
 disk.data=story.save.data.duplicate(true)
 disk.write()
 check(disk.load_progress(),"Version 2 complete quest save round trip")
 check(disk.data.money==25 and disk.data.rewards==["crate_delivery","fight_first"],"Reward ledger saved exactly once")
 game.return_to_title()
 story.save.data=disk.data.duplicate(true)
 story.start(false)
 check(story.screens.screen_id==6 and story.inventory.item=="stick","Continue restores clearing and armed item")
 check(story.actor.pose=="combat_idle" and story.wallet.money==25,"Armed Continue does not regress to unarmed pose or repay")
 tick(ceil(raw*2)/2+.5)
 check(story.phase=="playing","Completed subquest Continue keeps campaign playable")
 disk.data.item="crate"
 disk.write()
 check(not disk.load_progress(),"Inconsistent inventory save rejected")
 var file:=FileAccess.open(disk.path,FileAccess.WRITE)
 file.store_string('{"version":1,"campaign":"rent_due","unlocked_screen":1,"checkpoint":"screen01_complete","opening_complete":true}')
 file.close()
 check(disk.load_progress() and disk.data.version==2,"Version one checkpoint migrated")
 check(disk.data.screen==1 and disk.data.completed==["rent"] and disk.data.money==0,"Migration does not invent quest progress or money")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(disk.path))
 game.queue_free()
 await process_frame
 print("STORY 011: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
func walk_to(destination: float) -> void:
 var section: int=game.story.road_section
 for guard in range(24):
  if game.story.screens.screen_id==3 and game.story.road_section!=section:break
  if game.story.screens.screen_id!=1 and game.story.phase=="transition":break
  if absf(game.story.target_x-destination)<1:break
  tick(ceil((raw+.001)*2)/2)
  action("right" if game.story.target_x<destination else "left")
  tick(raw+.20)
func action_hold_low(value: bool) -> void:game.story.submit("low",value,raw)

func cross_road(index: int) -> void:
 for guard in range(160):
  tick(ceil((raw+.001)*2)/2)
  if game.story.obstacles.can_start_road(index,game.story.world.beat()):break
 walk_to(292)
 if index==0:check(game.story.road_section==1 and game.story.target_x==36,"Fixed-section transition reaches central reservation")
