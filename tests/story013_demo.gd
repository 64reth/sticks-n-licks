extends "res://scripts/main.gd"
# Legal keyboard-driven native route. Clock injection exists only behind --record013.
var raw_demo:=0.0
var elapsed:=0.0
var offline:=false
var sent: Dictionary={}
var captures: Dictionary={}
var line_key: String=""
var line_since: float=0
var last_move: String=""
var last_action: String=""
var forced_failure: bool=false
var recovering_seen: bool=false
var complete_since: float=-1
var fixture_player:=RhythmTestPlayer.new()
var fight_planned: int=-1
var idle_since: float=-1
var walk_stop_since: float=-1
var result_since: float=-1
var fixture_round: String=""
var observe_since: float=-1
var refuge_since: float=-1
var screen_report: Array[Dictionary]=[]
func _ready() -> void:
 offline="--record013" in OS.get_cmdline_user_args()
 if offline:conductor.clock_override=func():return raw_demo
 preferences_path=""
 super._ready()
 story.save.path=""
 story.save.data={}
 fixture_player.configure("guard_high",311)
 if offline:
  audio.enabled=DisplayServer.get_name()!="headless"
  audio.events.ui_clock_source=conductor.now
  if not audio.active.is_empty():audio.play_track(audio.active,audio.anchor,true)
 conductor.beat_changed.connect(plan_combat)
func key(code: int, pressed: bool) -> void:
 var event:=InputEventKey.new()
 event.keycode=code
 event.physical_keycode=code
 event.pressed=pressed
 _unhandled_input(event)
func tap(code: int) -> void:
 key(code,true)
 key(code,false)
func once(at: float,id: String,codes: Array) -> void:
 if elapsed>=at and not sent.has(id):
  sent[id]=true
  for code in codes:tap(code)
func shot(id: String) -> void:
 if captures.has(id):return
 captures[id]=true
 screen_report.append({"id":id,"beat":story.world.beat(),"epoch":conductor.epoch,"music_restarts":audio.restart_count,"screen":story.screens.screen_id,"phase":story.phase,"item":story.inventory.item,"money":story.wallet.money,"quest":story.quest.completed.duplicate(),"opening":story.opening_state,"house_frame":story.screens.current.house_frame,"pose":story.actor.pose,"sprite_frame":story.actor.sprite.frame,"root_scale":story.actor.scale,"position":story.actor.position,"breath_lift":story.unarmed.lift,"page":story.dialogue.page,"revealed":story.dialogue.is_revealed(),"text":story.dialogue.line().get("text",""),"speaker":story.dialogue.line().get("speaker",""),"road_section":story.road_section,"round_wins":match_progress.round_wins.duplicate(),"rent_target":story.wallet.target()})
 if DisplayServer.get_name()=="headless":return
 if id=="traffic-warning" and "--desktop013" in OS.get_cmdline_user_args():OS.execute(ProjectSettings.globalize_path("res://output/capture-game-window"),[str(OS.get_process_id()),ProjectSettings.globalize_path("res://output/013-desktop.png")])
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://output/013-"+id+".png")
func plan_combat(_beat: int,_phrase: int) -> void:
 if mode=="combat" and story.phase=="fight":fixture_player.plan_boundary(public_cpu_observation())
func move_to(x: float) -> void:
 var id: String="%d:%d" % [conductor.phrase,conductor.beat]
 if last_move==id or absf(story.target_x-x)<1:return
 if absf(game_time()-conductor.beat_time)>.045:return
 last_move=id
 tap(KEY_D if story.target_x<x else KEY_A)
func interact() -> void:
 var id: String="%d:%d" % [conductor.phrase,conductor.beat]
 if last_action==id or absf(game_time()-conductor.beat_time)>.045:return
 if story.context_interaction().get("id")=="vendor":
  if not sent.has("vendor-invalid"):
   if conductor.beat!=2:return
   sent["vendor-invalid"]=true
   last_action=id
   tap(KEY_F)
   shot("vendor-invalid")
   return
  if conductor.beat!=4:return
 last_action=id
 tap(KEY_F)
func _process(delta: float) -> void:
 elapsed+=delta
 if elapsed>700:
  push_error("Story 013 demo timeout: "+story.phase)
  get_tree().quit(1)
  return
 if offline:raw_demo+=delta
 super._process(delta)
 once(.3,"intro",[KEY_ENTER])
 once(.8,"title",[KEY_ENTER])
 once(1.3,"story",[KEY_DOWN,KEY_DOWN,KEY_DOWN,KEY_ENTER])
 once(1.9,"new",[KEY_ENTER])
 if story.phase=="inactive":return
 if story.phase=="fight":
  shot("combat-"+mode+"-match%d-round%d" % [match_serial,match_progress.round_number])
  if mode=="combat":
   shot("combat-hud")
   shot("combat-hud-match%d-round%d" % [match_serial,match_progress.round_number])
  if mode=="match_win":
   shot("match-"+str(match_progress.winner))
   if result_since<0:result_since=elapsed
   if elapsed-result_since>3:
    tap(KEY_ENTER)
    result_since=-1
   return
  var round_id: String="%d:%d" % [match_serial,match_progress.round_number]
  if round_id!=fixture_round:
   fixture_round=round_id
   fixture_player.start_round(cue)
  # First match intentionally permits a CPU win: verify native defeat/retry dialogue.
  if match_serial==1:return
  while fixture_player.next_time()<=game_time():
   var intent:=fixture_player.pop_intent()
   var name: String=intent.action
   submit_action(0,name,true,float(intent.at))
   if intent.kind=="combat":submit_action(0,"execute",true,float(intent.at))
   submit_action(0,name,false,float(intent.at))
   if intent.kind=="combat":submit_action(0,"execute",false,float(intent.at))
  return
 if story.dialogue.active():
  var line: Dictionary=story.dialogue.line()
  var identity: String=str(line.id)+str(line.text)+str(story.dialogue.page)
  if identity!=line_key:
   line_key=identity
   line_since=story.world.beat()
   shot("dialogue-"+str(line.id)+"-"+str(line.sequence_index)+"-page%d" % story.dialogue.page)
  var age:=story.world.beat()-line_since
  var full_id: String="dialogue-"+str(line.id)+"-"+str(line.sequence_index)+"-page%d-full" % story.dialogue.page
  if story.dialogue.is_revealed() and not captures.has(full_id):
   shot(full_id)
   # Keep this exact revealed page through frame_post_draw before any advancing F.
   return
  if str(line.id)=="opening" and int(line.sequence_index)==1 and story.dialogue.is_revealed():shot("warning-hold")
  if age>=.5 and not story.dialogue.is_revealed():tap(KEY_F)
  elif age>=maxf(4 if str(line.id)=="opening" and int(line.sequence_index)==1 else 2,ceil(story.dialogue.page_text().length()/22.0)):tap(KEY_F)
  return
 if story.phase=="cinematic":
  if story.actor.visible:shot("airborne-entrance")
  if story.world.beat()-story.origin>=6:shot("landing")
  return
 if story.phase=="recovering":
  if story.screens.screen_id==3:
   recovering_seen=true
   shot("traffic-recovery")
  shot("damage-frame%d" % story.actor.sprite.frame)
  return
 if story.phase=="complete":
  shot("quest-complete")
  if complete_since<0:complete_since=elapsed
  if elapsed>complete_since+2:finish_demo()
  return
 if story.phase!="playing":return
 if story.quest.finished():
  shot("reward-exploration")
  if complete_since<0:complete_since=elapsed
  if elapsed>complete_since+4:finish_demo()
  return
 var screen: int=story.screens.screen_id
 shot("screen%d" % screen)
 match screen:
  1:
   if idle_since<0:idle_since=story.world.beat()
   var age:=story.world.beat()-idle_since
   if age<8:
    shot("idle-lift%d" % story.unarmed.lift)
    return
   if age<14:
    var duck:=int(floor(age))%2==0
    if duck!=bool(story.control.held.get("low",false)):key(KEY_S,duck)
    shot("duck-%d" % int(age) if duck else "stand-%d" % int(age))
    return
   key(KEY_S,false)
   if story.target_x<164 and walk_stop_since<0:move_to(164)
   elif walk_stop_since<0:walk_stop_since=story.world.beat()
   elif story.world.beat()-walk_stop_since<2:shot("walk-stop")
   else:move_to(280)
  2:
   match str(story.quest.current().get("id")):
    "vendor":
     if absf(story.target_x-84)<=1:interact()
     else:move_to(84)
    "crate":
     if absf(story.target_x-132)<=1:interact()
     else:move_to(132)
    _:move_to(280)
  3:
   var section: int=story.road_section
   for lane in range(section*2,section*2+2):
    if story.obstacles.lane_warning(lane,story.world.beat()):shot("lane%d-warning" % lane)
    if story.obstacles.lane_active(lane,story.world.beat()) and story.obstacles.lane_vehicle_y(lane,story.world.beat())>=140 and story.obstacles.lane_vehicle_y(lane,story.world.beat())<=175:shot("lane%d-vehicle" % lane)
   shot("road-section%d" % section)
   if not recovering_seen:
    if story.target_x<100:move_to(100)
    else:shot("beside-car-approach")
   elif story.target_x<292:
    # Observe both lanes before crossing; each has an independent conductor pattern.
    var observed: bool=captures.has("lane%d-vehicle" % (section*2)) and captures.has("lane%d-vehicle" % (section*2+1))
    if observed and (story.obstacles.can_start_road(section,story.world.beat()) or story.target_x>36):move_to(292)
    elif section==1:shot("central-refuge")
   elif not story.quest.completed.has("delivery"):interact()
   else:
    shot("paid")
    move_to(292)
  4,5:
   if not bool(story.control.held.get("low",false)):
    key(KEY_S,false)
    key(KEY_S,true)
   var needed:=1 if screen==4 else 2
   if story.defenses<needed:move_to(148)
   else:
    shot("duck-screen%d" % screen)
    move_to(280)
  6:
   if story.inventory.item!="stick":
    if absf(story.target_x-100)<=1:interact()
    else:move_to(100)
   else:interact()
 if elapsed>600:
  push_error("Story 013 demo timeout: "+story.phase)
  get_tree().quit(1)
func finish_demo() -> void:
 var file:=FileAccess.open("res://output/013-demo-"+("movie" if offline else "live")+".json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"clock":"offline injected" if offline else "production","seconds":elapsed,"captures":screen_report,"traffic_failure":recovering_seen,"quest_complete":story.quest.finished(),"money":story.wallet.money,"exchanges":completed_exchanges,"music_events":audio.event_log,"claimed_rewards":story.wallet.rewards,"reward_amounts":story.wallet.amounts,"rent_target":story.wallet.target()},"  "))
 print("STORY 013 DEMO COMPLETE: seconds=",elapsed," money=",story.wallet.money," quest=",story.quest.finished())
 get_tree().quit()
