extends SceneTree
var checks:=0
var failures:=0
var raw:=0.0
var game: Node2D
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(message)
func tick(at: float) -> void:
 raw=at+game.conductor.pause_offset
 game._process(0)
func press() -> void:
 game.story.submit("execute",true,raw)
 game.story.submit("execute",false,raw)
func reveal_advance() -> void:
 for i in range(2):press()
func run() -> void:
 game=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 game.preferences_path=""
 game.conductor.clock_override=func():return raw
 root.add_child(game)
 game.set_process(false)
 game.open_main_menu()
 var story: StorySession=game.story
 story.start(true)
 check(StoryOverlay.DIALOGUE_RECT==Rect2(8,144,304,32),"Fixed compact bottom panel, 44.8 percent less area")
 check(StoryOverlay.DIALOGUE_RECT.size.y<=40,"Panel meets native height target")
 check(ControlPrompt.key_label("p1_execute")=="F" and ControlPrompt.key_label("p1_low")=="S","Keycaps resolve current bindings")
 var dialog:=StoryDialogue.new()
 dialog.sync(0)
 dialog.begin("vendor")
 check(dialog.revealed_count()==0,"Typewriter starts unrevealed")
 dialog.sync(.25)
 check(dialog.revealed_count()==8,"Typewriter derives eight characters from quarter beat")
 dialog.press(true)
 dialog.on_subdivision()
 check(dialog.is_revealed() and dialog.queue.size()==7,"First F reveals without advancing")
 dialog.press(true)
 dialog.on_subdivision()
 check(dialog.queue.size()==7,"Held F cannot advance")
 dialog.press(false)
 dialog.press(true)
 dialog.on_subdivision()
 check(dialog.queue.size()==6,"Fresh F advances revealed page")
 for entries in dialog.definitions.values():
  for entry in entries:
   dialog.clear()
   dialog.queue.append(entry.duplicate())
   dialog.prepare_page()
   var reconstructed: Array[String]=[]
   for page_text in dialog.pages:
    var lines: PackedStringArray=page_text.split("\n")
    check(lines.size()<=2,"Every dialogue page fits two lines")
    for line in lines:check(StoryOverlay.FONT.get_string_size(line.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,8).x<=278,"Page content stays in padding")
    reconstructed.append(page_text.replace("\n"," "))
   check(" ".join(reconstructed)==str(entry.text),"Pagination retains exact approved wording")
 dialog.clear()
 dialog.begin("vendor",[1])
 check(dialog.pages.size()==2,"Long vendor line paginates without panel growth")
 var epoch: float=game.conductor.epoch
 check(not story.actor.visible and story.screens.current.house_frame==0,"Opening hides actor, door closed")
 tick(.5)
 reveal_advance()
 check(story.opening_state=="door_wait","First dialogue completion schedules door beat")
 tick(1)
 check(story.opening_state=="warning" and story.screens.current.house_frame==1,"Door reaches open no-foot hold")
 for i in range(17):
  tick(1+i*.25)
  check(story.screens.current.house_frame==1 and not story.actor.visible,"No foot or actor while final warning is held")
 check(game.conductor.epoch==epoch,"Warning hold never resets music clock")
 reveal_advance()
 check(story.opening_state=="kick_wait","Final warning completion schedules kick")
 var kick: float=story.kick_due*.5
 tick(kick-.001)
 check(story.screens.current.house_frame==1 and not story.actor.visible,"Foot remains hidden until kick boundary")
 tick(kick)
 check(story.actor.visible and story.screens.current.house_frame==2 and story.actor.sprite.frame==2,"Foot emergence and airborne fighter start on same beat")
 tick(kick+.125)
 check(story.screens.current.house_frame==3,"Foot extends on next quarter beat, no flight pause")
 tick(kick+1)
 check(story.actor.position==Vector2(100,150) and story.actor.sprite.frame==3,"Original landing ground/position preserved")
 reveal_advance()
 var idle_at: float=(story.origin+15)*.5
 tick(idle_at)
 check(story.actor.pose=="story_idle","Recovery enters selected unarmed idle")
 tick(idle_at+.5)
 var lifts: Dictionary={}
 for i in range(17):
  tick(idle_at+.5+i*.25)
  lifts[story.unarmed.lift]=true
  check(story.actor.position==Vector2(100,150) and story.actor.scale==Vector2.ONE,"Eight idle beats keep root position/scale fixed")
  check(story.actor.sprite.scale==Vector2.ONE*(64.0/240),"Idle never scales the source during breathing")
 check(lifts.size()==2,"Native-pixel upper-body breath has two conductor placements")
 check(story.actor.sprite.sprite_frames.get_frame_texture("story_idle",0)==load("res://assets/characters/fighter_01/frames/milestone_002/pickup/001.png"),"Idle references audited pickup frame one directly")
 for cycle in range(3):
  story.submit("low",true,raw)
  check(story.actor.pose=="story_duck","S selects preferred crouch")
  check(story.actor.sprite.sprite_frames.get_frame_texture("story_duck",0)==load("res://assets/story/009/fighter_00.png"),"Duck maps kicked frame zero")
  tick(raw+.5)
  story.submit("low",false,raw)
  check(story.actor.pose=="story_idle" and story.actor.position==Vector2(100,150),"Duck release restores idle without displacement")
 tick(ceil(raw*2)/2+.5)
 story.submit("right",true,raw)
 story.submit("right",false,raw)
 tick(raw+.081)
 check(story.actor.pose=="story_forward_step" and story.actor.sprite.frame==1,"Both existing step poses progress over 160ms")
 tick(raw+.080)
 check(story.target_x==116 and story.actor.position.x==116 and story.actor.pose=="story_idle","Original 16px/160ms step returns to idle")
 check(story.quest.hud_objective()=="Earn enough money to pay the rent.","Actionable campaign objective after eviction")
 story.enter_screen(2)
 check(story.quest.hud_objective()=="Talk to the roadside vendor.","Objective updates from quest data on village entry")
 # Walk to the actual vendor range through the unchanged movement adapter.
 for i in range(3):
  tick(ceil((raw+.001)*2)/2)
  story.submit("right",true,raw)
  story.submit("right",false,raw)
  tick(raw+.17)
 check(story.context_interaction().get("beat4",false),"Context exposes available beat-four tutorial")
 var phrase_start: float=game.conductor.phrase_start+2
 tick(phrase_start)
 story.submit("execute",true,raw)
 check(not story.dialogue.active(),"Beat-one interaction rejected")
 tick(phrase_start+1.5)
 check(not story.dialogue.active(),"Held invalid F never auto-triggers on beat four")
 story.submit("execute",false,raw)
 for offset in [-.141,-.14,.14,.141]:
  story.dialogue.clear()
  story.clear_inputs()
  var at: float=game.conductor.phrase_start+3.5
  tick(at+offset)
  press()
  tick(at+.26)
  check(story.dialogue.active()==(absf(offset)<=.14),"Existing inclusive beat-four window %+.3f" % offset)
 story.dialogue.clear()
 var obstacles:=StoryObstacles.new()
 check(obstacles.traffic.lanes.size()==4 and obstacles.traffic.roads.size()==2,"Two roads, four lanes")
 var patterns: Dictionary={}
 for lane in range(4):
  var config: Dictionary=obstacles.traffic.lanes[lane]
  patterns[int(config.cycle)]=true
  var active_at: float=float(config.cycle)-1
  check(obstacles.lane_warning(lane,active_at-2) and obstacles.lane_active(lane,active_at),"Lane has warning and collision interval")
  check(obstacles.lane_vehicle_y(lane,active_at+.25)>obstacles.lane_vehicle_y(lane,active_at-.25) if int(config.direction)>0 else obstacles.lane_vehicle_y(lane,active_at+.25)<obstacles.lane_vehicle_y(lane,active_at-.25),"Opposite traffic directions interpolate from beat phase")
 check(patterns.size()==4,"All four lane cycles differ")
 for road in range(2):
  var safe_starts:=0
  var worst_wait:=0
  var wait:=0
  var unsafe_crossings:=0
  var layout: Dictionary=obstacles.traffic.roads[road]
  for start in range(1680):
   if not obstacles.can_start_road(road,start):
    wait+=1
    worst_wait=maxi(wait,worst_wait)
    continue
   wait=0
   safe_starts+=1
   for step in range(int(layout.steps)):
    for sub in range(17):
     var fraction: float=float(sub)/16
     var x:=float(layout.from)+step*16+16*clampf(fraction/.32,0,1)
     if obstacles.road_collision(start+step+fraction,x):unsafe_crossings+=1
  check(safe_starts>0 and worst_wait<56,"Repeatable green opportunities, no permanent blockage")
  check(unsafe_crossings==0,"Every green invitation fits approved step interpolation")
 check(obstacles.safe_waiting_area(68) and obstacles.safe_waiting_area(148) and obstacles.safe_waiting_area(244),"Safe before/between/after refuges")
 story.enter_screen(3)
 story.road_checkpoint=148
 story.inventory.item="crate"
 story.wallet.money=5
 story.target_x=196
 story.actor.position=Vector2(196,150)
 var before:=story.quest.completed.duplicate()
 story.recover_collision("Test contact")
 check(story.actor.pose=="story_unarmed_reaction","Damage uses unarmed reaction, not armed hurt/block")
 check(story.recovery_checkpoint==148,"Road B contact returns to reached central refuge")
 var end: float=story.recovery_beat*.5
 var start: float=story.recovery_started*.5
 for sample in [{"fraction":.2,"frame":0},{"fraction":.5,"frame":1},{"fraction":.85,"frame":2}]:
  tick(lerpf(start,end,float(sample.fraction)))
  check(story.actor.sprite.frame==int(sample.frame),"Damage frame advances and is not reset by playback stop")
 tick(end)
 check(story.actor.pose=="story_idle" and story.actor.position==Vector2(148,150),"Damage recovery returns cleanly to unarmed idle")
 check(story.inventory.item=="crate" and story.wallet.money==5 and story.quest.completed==before,"Recovery retains crate, money and quest")
 check(game.bout.hits==[0,0],"Environmental reactions never write combat damage")
 story.inventory.item=""
 story.wallet.money=0
 check(story.overlay.currency()=="BDS $0","Clean currency formatter")
 check(StoryOverlay.INVENTORY_RECT.size==Vector2(18,16),"Inventory is separate graphical slot")
 var disk:=StorySave.new()
 disk.path="res://output/012-save-test.json"
 disk.data={"version":2,"campaign":"rent_due","unlocked_screen":3,"checkpoint":"traversal","opening_complete":true,"screen":3,"completed":["rent","village","vendor","crate"],"item":"crate","money":0,"rewards":[],"road_checkpoint":148}
 disk.write()
 check(disk.load_progress(),"Existing v2 quest save accepts optional central checkpoint")
 game.return_to_title()
 story.save.data=disk.data.duplicate(true)
 story.start(false)
 check(story.actor.position==Vector2(148,150) and story.inventory.item=="crate","Continue starts safely at the reached central refuge")
 check(story.obstacles.safe_waiting_area(story.actor.position.x),"Continue never spawns inside a live lane")
 var valid: Dictionary=disk.data.duplicate(true)
 disk.data["road_checkpoint"]=156
 disk.write()
 check(not disk.load_progress(),"Invalid non-checkpoint coordinate is rejected")
 disk.data=valid
 disk.data.erase("road_checkpoint")
 disk.write()
 check(disk.load_progress(),"Pre-012 version-two saves still load")
 story.save.data=disk.data.duplicate(true)
 game.return_to_title()
 story.start(false)
 check(story.actor.position.x==68,"Legacy road save moves to safe start, not former unsafe X100")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(disk.path))
 game.queue_free()
 await process_frame
 print("STORY 012: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
