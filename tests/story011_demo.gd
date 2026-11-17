extends "res://scripts/main.gd"
# Legal keyboard-driven native route. Clock injection exists only behind --record011.
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
var screen_report: Array[Dictionary]=[]
func _ready() -> void:
 offline="--record011" in OS.get_cmdline_user_args()
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
 screen_report.append({"id":id,"beat":story.world.beat(),"epoch":conductor.epoch,"music_restarts":audio.restart_count,"screen":story.screens.screen_id,"phase":story.phase,"item":story.inventory.item,"money":story.wallet.money,"quest":story.quest.completed.duplicate()})
 if DisplayServer.get_name()=="headless":return
 if id=="traffic-warning" and "--desktop011" in OS.get_cmdline_user_args():OS.execute(ProjectSettings.globalize_path("res://output/capture-game-window"),[str(OS.get_process_id()),ProjectSettings.globalize_path("res://output/011-desktop.png")])
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://output/011-"+id+".png")
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
 last_action=id
 tap(KEY_F)
func _process(delta: float) -> void:
 elapsed+=delta
 if elapsed>240:
  push_error("Story 011 demo timeout: "+story.phase)
  get_tree().quit(1)
  return
 if offline:raw_demo+=delta
 super._process(delta)
 once(.3,"intro",[KEY_ENTER])
 once(.8,"title",[KEY_ENTER])
 once(1.3,"story",[KEY_DOWN,KEY_DOWN,KEY_DOWN,KEY_ENTER])
 once(1.9,"new",[KEY_ENTER])
 if story.phase=="inactive":return
 if mode=="combat" and story.phase=="fight":
  shot("first-fight")
  # Commit only public-observation strategy inputs; never inspect CPU selections.
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
  var identity: String=str(line.id)+str(line.text)
  if identity!=line_key:
   line_key=identity
   line_since=story.world.beat()
   shot("dialogue-"+str(line.id)+"-"+str(line.sequence_index))
  if story.world.beat()-line_since>=maxf(2,ceil(str(line.text).length()/22.0)):tap(KEY_F)
  return
 if story.phase=="cinematic":
  if story.actor.visible:shot("airborne-entrance")
  if story.world.beat()-story.origin>=6:shot("landing")
  return
 if story.phase=="recovering":
  if story.screens.screen_id==3:
   recovering_seen=true
   shot("traffic-recovery")
  return
 if story.phase=="complete":
  shot("quest-complete")
  if complete_since<0:complete_since=elapsed
  if elapsed>complete_since+2:finish_demo()
  return
 if story.phase!="playing":return
 var screen: int=story.screens.screen_id
 shot("screen%d" % screen)
 match screen:
  1:move_to(280)
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
   if not recovering_seen:
    if story.target_x<132:move_to(132)
    else:
     forced_failure=true
     if story.obstacles.traffic_warning(story.world.beat()):shot("traffic-warning")
   elif not story.quest.completed.has("cross"):
    var phase: float=story.obstacles.road_phase(story.world.beat())
    if phase<5 or story.actor.position.x>112:move_to(212)
   elif not story.quest.completed.has("delivery"):
    if story.target_x<244:move_to(244)
    else:interact()
   else:
    shot("paid")
    move_to(280)
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
 if elapsed>210:
  push_error("Story 011 demo timeout: "+story.phase)
  get_tree().quit(1)
func finish_demo() -> void:
 var file:=FileAccess.open("res://output/011-demo-"+("movie" if offline else "live")+".json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"clock":"offline injected" if offline else "production","seconds":elapsed,"captures":screen_report,"traffic_failure":recovering_seen,"quest_complete":story.quest.finished(),"money":story.wallet.money,"exchanges":completed_exchanges},"  "))
 print("STORY 011 DEMO COMPLETE: seconds=",elapsed," money=",story.wallet.money," quest=",story.quest.finished())
 get_tree().quit()
