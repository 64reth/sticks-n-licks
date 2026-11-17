class_name StorySession
extends Node2D
var game: Node2D
var save:=StorySave.new()
var screens:=StoryScreenManager.new()
var overlay:=StoryOverlay.new()
var control:=CombatInput.new()
var house:=BeatAnimation.new()
var recovery:=BeatAnimation.new()
var config: Dictionary
var actor: Fighter
var phase: String="inactive"
var origin: float=0
var unlock_at: float=INF
var target_x: float=100
var step_origin: float=100
var step_started: float=-INF
var accents: Dictionary={}
var dust_beat: float=-INF
var blocked: Dictionary={}
var trace: Array[Dictionary]=[]
var world: BeatWorld
var quest:=QuestLog.new()
var inventory:=StoryInventory.new()
var wallet:=StoryWallet.new()
var dialogue:=StoryDialogue.new()
var obstacles:=StoryObstacles.new()
var pending_screen: int=0
var transition_beat: float=INF
var notification_until: float=-INF
var action_held: bool=false
var interaction: Dictionary={}
var interaction_beat: String=""
var dialogue_beat: float=INF
var recovery_beat: float=INF
var defenses: int=0
var hazard_cycle: int=-1
var quest_panel: bool=false
var fight_due: float=INF
var fight_result: int=-1
var fight_music_key: String=""
var fight_music_anchor: float=0
var pose_samples: Dictionary={}
var match_motion: Dictionary={}
var opening_gate: bool=false
var obstacle_subdivision: int=-1
var unarmed:=UnarmedPresentation.new()
var opening_state: String="opening"
var door_due: float=INF
var kick_due: float=INF
var recovery_started: float=0
var road_section: int=0
var reward_notice: String=""
var reward_until: float=-INF
var road_checkpoint: float=36
var recovery_checkpoint: float=100
func setup(owner: Node2D) -> void:
 game=owner
 world=BeatWorld.new(game.conductor)
 dialogue.completed.connect(dialogue_completed)
 quest.progressed.connect(func(_event):notification_until=world.beat()+4)
 z_index=-1
 config=JSON.parse_string(FileAccess.get_file_as_string("res://data/story_009.json"))
 if game.conductor.clock_override.is_valid():save.path=""
 save.load_progress()
 add_child(screens)
 overlay.story=self
 game.hud_layer.add_child(overlay)
 game.hud_layer.move_child(overlay,1)
 overlay.visible=false
 visible=false
 actor=game.fighters[0]
 install_art()
 actor.add_child(unarmed)
 unarmed.setup(actor,world)
 unarmed.visible=false
func install_art() -> void:
 var frames:=actor.sprite.sprite_frames
 var definitions: Dictionary={"story_eviction":[],"story_forward_step":[8,10],"story_backward_step":[8,10],"story_duck":[0],"story_idle":[1],"story_unarmed_reaction":[1,8,11]}
 for i in range(12):definitions.story_eviction.append(i)
 for name in definitions:
  frames.add_animation(name)
  frames.set_animation_loop(name,false)
  frames.set_animation_speed(name,12.5)
  for index in definitions[name]:
   var source: String="eviction" if name in ["story_eviction","story_duck","story_unarmed_reaction"] else ("pickup" if name=="story_idle" else "race")
   var path: String=("res://assets/story/009/fighter_%02d.png" if source=="eviction" else "res://assets/characters/fighter_01/frames/milestone_002/"+source+"/%03d.png") % index
   frames.add_frame(name,load(path))
  actor.animation_meta[name]={"scale":64.0/289 if name in ["story_eviction","story_duck","story_unarmed_reaction"] else 64.0/240,"canvas":[768,768],"ground_pixel":744}
func absolute_beat() -> float:return world.beat()
func start(cinematic: bool) -> void:
 game.intro.visible=false
 game.intro_music_pending=false
 if game.paused:game.set_paused(false)
 game.mode="story"
 game.round_transition_at=INF
 game.cpu.queue.clear()
 game.audio.events.clear_round()
 for c in game.controls:c.reset()
 if not game.conductor.started:
  game.conductor.start(game.conductor.now(),int(config.tempo))
  game.audio.play_track(str(int(config.tempo)),game.conductor.epoch,true)
  game.previous_bpm=int(config.tempo)
 if cinematic:
  quest=QuestLog.new()
  quest.progressed.connect(func(_event):notification_until=world.beat()+4)
  inventory=StoryInventory.new()
  wallet=StoryWallet.new()
 elif save.valid():restore_progress()
 dialogue.clear()
 reward_notice=""
 reward_until=-INF
 fight_result=-1
 action_held=false
 var initial_screen: int=1 if cinematic else int(save.data.get("screen",1))
 load_screen(initial_screen)
 visible=true
 overlay.visible=true
 game.stage.visible=false
 game.fighters[1].visible=false
 game.ground_sticks.visible=false
 game.impact_effect.visible=false
 game.hud.visible=false
 actor.visible=not cinematic
 actor.set_process(false)
 actor.reset_visual()
 actor.face(1)
 control.reset()
 blocked.clear()
 trace.clear()
 origin=ceil(absolute_beat()-0.000001)
 accents.clear()
 opening_gate=false
 opening_state="opening"
 door_due=INF
 kick_due=INF
 dust_beat=-INF
 road_section=int(save.data.get("road_section",1 if quest.completed.has("cross") or float(save.data.get("road_checkpoint",68))>=148 else 0))
 target_x=292 if initial_screen==3 and quest.completed.has("cross") else (36 if initial_screen==3 else float(config.start_x))
 road_checkpoint=target_x if initial_screen==3 else 36
 step_origin=target_x
 step_started=-INF
 actor.position=Vector2(float(config.door_x) if cinematic else target_x,Bout.GROUND_Y)
 house.cues.assign(config.house)
 recovery.cues.assign(config.fighter)
 house.start(origin)
 recovery.start(origin)
 phase="cinematic"
 if cinematic:
  dialogue.sync(absolute_beat())
  dialogue.begin("opening",[0])
 else:finish_cinematic()
 game.refresh()
 advance()
func deactivate() -> void:
 phase="inactive"
 dialogue.clear()
 game.fighters[0].visible=true
 house.stop()
 recovery.stop()
 visible=false
 overlay.visible=false
 game.stage.visible=true
 game.fighters[1].visible=true
 game.impact_effect.visible=true
 actor.reset_visual()
 actor.sprite.visible=true
 unarmed.visible=false
 for fighter in game.fighters: fighter.set_process(true)
func finish_cinematic() -> void:
 house.stop()
 recovery.stop()
 screens.current.house_frame=1
 actor.visible=true
 actor.position=Vector2(target_x,Bout.GROUND_Y)
 actor.reset_visual()
 actor.set_pose("combat_idle" if inventory.item=="stick" else "story_idle")
 actor.sprite.pause()
 phase="waiting"
 control.reset()
 for c in game.controls:c.reset()
 # Always a future boundary, never the middle of recovery or the current late window.
 unlock_at=floor(absolute_beat()+0.000001)+1
 quest.emit_event("opening_complete")
 quest.notification=str(quest.definition.objective)
 notification_until=INF
 persist()
func advance() -> void:
 if phase=="inactive":return
 if game.paused:return
 var beat:=absolute_beat()
 var relative:=beat-origin
 var now: float=game.game_time()
 dialogue.sync(beat)
 if dialogue.pending and beat+0.000001>=dialogue_beat:
  dialogue.on_subdivision()
  control.reset()
 if not interaction.is_empty() and beat+0.000001>=float(interaction.due):
  var requested:=interaction.duplicate()
  interaction.clear()
  interact(str(requested.id))
 if phase=="transition" and beat+0.000001>=transition_beat:
  enter_screen(pending_screen)
 if phase=="recovering" and beat+0.000001>=recovery_beat:
  actor.reset_visual()
  target_x=recovery_checkpoint
  step_origin=recovery_checkpoint
  step_started=-INF
  actor.position=Vector2(recovery_checkpoint,150)
  control.reset()
  phase="playing"
 if phase=="recovering":
  actor.sprite.frame=mini(2,int(clampf((beat-recovery_started)/maxf(.001,recovery_beat-recovery_started),0,1)*3))
  actor.sprite.pause()
 if phase=="fight_wait" and beat+0.000001>=fight_due:start_fight()
 if phase=="fight":sync_fight_poses()
 if screens.current is StoryQuestScreen:screens.current.queue_redraw()
 if phase=="cinematic":
  if opening_state=="door_wait" and beat+0.000001>=door_due:
   opening_state="warning"
   screens.current.house_frame=1
   dialogue.begin("opening",[1])
   accents["door"]=true
   game.audio.emit_event("block","story-door:%s" % origin)
  if opening_state=="kick_wait" and beat+0.000001>=kick_due:
   opening_state="flight"
   origin=kick_due-4
   relative=beat-origin
   house.start(origin)
   recovery.start(origin)
  if opening_state!="flight":
   screens.current.house_frame=0 if opening_state in ["opening","door_wait"] else 1
   actor.visible=false
   unarmed.sync()
   screens.current.queue_redraw()
   overlay.queue_redraw()
   return
  var h:=house.sample(beat)
  var f:=recovery.sample(beat)
  if not h.is_empty():screens.current.house_frame=int(h.frame)
  actor.visible=relative>=float(config.flight_start)
  actor.set_pose("story_eviction")
  actor.sprite.pause()
  if not f.is_empty():actor.sprite.frame=2 if relative<float(config.landing_beat) else int(f.frame)
  var progress:=clampf((relative-float(config.flight_start))/(float(config.landing_beat)-float(config.flight_start)),0,1)
  actor.position=Vector2(roundf(lerpf(float(config.door_x),target_x,progress)),roundf(Bout.GROUND_Y-sin(progress*PI)*24))
  for trigger in [{"beat":6,"index":2}]:
   var key: String="dialogue%d" % int(trigger.index)
   if relative>=float(trigger.beat) and not accents.has(key):
    accents[key]=true
    dialogue.begin("opening",[int(trigger.index)])
  for cue in config.accents:
   if relative>=float(cue.beat) and not accents.has(cue.id):
    accents[cue.id]=true
    if cue.id=="land":dust_beat=origin+float(config.landing_beat)
    game.audio.emit_event(cue.sound,"story:%s:%s" % [origin,cue.id])
  if relative>=float(config.idle_beat):finish_cinematic()
 elif phase=="waiting":
  if beat+0.000001>=unlock_at and not dialogue.active():
   phase="playing"
   if quest.notification==str(quest.definition.objective):notification_until=absolute_beat()+8
   if quest.finished():phase="playing"
   control.reset()
   record({"event":"control","at":now,"position":actor.position,"beat":beat})
 elif phase=="playing":
  actor.position=Vector2(roundf(RhythmMovement.position_at(step_origin,target_x,step_started,now,game.step_seconds)),Bout.GROUND_Y)
  if now-step_started>=game.step_seconds:
   actor.reset_visual()
   actor.set_pose("story_duck" if bool(control.held.get("low",false)) else ("combat_idle" if inventory.item=="stick" else "story_idle"))
   actor.sprite.pause()
   if target_x>=(292 if screens.screen_id==3 else float(config.playable_right)) and not dialogue.active():
    if screens.screen_id==3 and road_section==0:
     road_section=1
     road_checkpoint=36
     target_x=36
     step_origin=36
     actor.position.x=36
     step_started=-INF
     control.reset()
     persist()
    else:request_exit()
  if now-step_started<game.step_seconds:
   actor.sprite.frame=mini(1,int((now-step_started)/game.step_seconds*2))
   actor.sprite.pause()
  if not dialogue.active():check_obstacles(beat)
 unarmed.sync()
 screens.current.dust_age=(beat-dust_beat)/2 if is_finite(dust_beat) else -1
 screens.current.dust_x=float(config.start_x)
 screens.current.queue_redraw()
 overlay.queue_redraw()
func on_beat(beat: int, phrase_number: int) -> void:
 # Catch up cinematic recovery before dispatching this boundary's movement.
 advance()
 if phase=="playing" and not dialogue.active():apply_step(beat,phrase_number,game.conductor.beat_time)
func apply_step(beat: int, phrase_number: int, at: float) -> void:
 control.last_step_evaluated=at
 var direction:=control.step(beat,phrase_number)
 if direction==0 or dialogue.active():return
 var before:=target_x
 target_x=clampf(target_x+direction*Bout.STEP,Bout.MIN_X,(292.0 if screens.screen_id==3 else float(config.playable_right)))
 if is_equal_approx(before,target_x):
  control.movement_executed=false
  control.step_feedback="REJECT screen boundary"
  return
 step_origin=actor.position.x
 step_started=game.game_time()
 control.last_step_time=at
 control.last_step_processed=step_started
 actor.rhythmic_pose(("" if inventory.item=="stick" else "story_")+RhythmMovement.pose(direction,1),game.step_seconds)
 record({"event":"step","at":at,"target":target_x,"beat":"%d:%d" % [phrase_number,beat],"grade":control.movement_grade})
func record(row: Dictionary) -> void:
 trace.append(row)
 if trace.size()>256:trace.pop_front()
func submit(action: String, pressed: bool, at: float) -> void:
 game.conductor.update(at)
 advance()
 if action=="execute":
  var fresh:=pressed and not action_held
  action_held=pressed
  dialogue.press(pressed)
  if fresh and dialogue.active():
   dialogue_beat=ceil(absolute_beat()*4-0.000001)/4
   advance()
   return
  if fresh and phase=="playing" and not quest_panel:
   queue_interaction(at)
  if not pressed:dialogue.held=false
  return
 if dialogue.active() or quest_panel:
  if pressed:blocked[action]=true
  else:blocked.erase(action)
  return
 if phase!="playing":
  if pressed:blocked[action]=true
  else:blocked.erase(action)
  return
 if blocked.has(action):
  if not pressed:blocked.erase(action)
  return
 var result:=RhythmMovement.feed(control,action,pressed,at,1,true,game.conductor,game.movement_perfect_ms,game.movement_good_ms)
 if result.requested and control.movement_grade!="miss":apply_step(game.conductor.beat,game.conductor.phrase,game.conductor.beat_time)
 advance()
func key(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_TAB and phase=="playing" and not dialogue.active():
   var safe_verge: bool=obstacles.safe_waiting_area(target_x) if screens.screen_id==3 else (screens.screen_id not in [4,5] or target_x<=112 or target_x>=208)
   if safe_verge or quest_panel:quest_panel=not quest_panel
   else:
    quest.notification="Open quest details from a safe verge."
    notification_until=absolute_beat()+2
   control.reset()
  if event.keycode==KEY_ENTER and phase=="cinematic":
   dialogue.clear()
   finish_cinematic()
  if OS.is_debug_build() and game.debug_visible:
   match event.keycode:
    KEY_F6:start(true)
    KEY_F7:start(false)
    KEY_F8:finish_cinematic()
 for action in ["left","right","low","execute"]:
  if event.is_action("p1_"+action):submit(action,event.is_action_pressed("p1_"+action),game.game_time())
func player_state() -> String:
 if phase in ["cinematic","waiting"]:return phase.to_upper()
 if phase!="playing":return phase.to_upper()
 if game.game_time()-step_started<game.step_seconds:return "MOVING"
 return "DUCKING" if bool(control.held.get("low",false)) else "IDLE"

func load_screen(id: int) -> void:
 var screen:=screens.load_screen(id)
 if screen is StoryQuestScreen:screen.session=self
 screen.bind_clock(game.conductor)
 obstacles.reset_safe(absolute_beat())
 road_checkpoint=36
 road_section=0
 obstacles.traffic=JSON.parse_string(FileAccess.get_file_as_string("res://data/story/traffic_013.json"))
 defenses=0
 obstacle_subdivision=-1
 hazard_cycle=-1
func enter_screen(id: int) -> void:
 load_screen(id)
 target_x=36
 step_origin=36
 step_started=-INF
 actor.position=Vector2(36,150)
 actor.visible=true
 actor.reset_visual()
 actor.set_pose("story_idle")
 control.reset()
 interaction.clear()
 phase="playing"
 pending_screen=0
 if id==2:quest.emit_event("village_entered")
 if id==4:quest.emit_event("cane_road_entered")
 if id==6:quest.emit_event("cane_cleared")
 persist()
func request_exit() -> void:
 var id:=screens.screen_id
 if id==6 and quest.finished():
  quest.notification="More locations and the route home are upcoming."
  notification_until=absolute_beat()+4
  return
 var allowed:=id==1 or (id==2 and inventory.item=="crate") or (id==3 and quest.completed.has("delivery")) or (id==4 and defenses>=1) or (id==5 and defenses>=2)
 if not allowed:
  quest.notification="Finish the current objective first."
  notification_until=absolute_beat()+2
  return
 phase="transition"
 control.reset()
 pending_screen=id+1
 transition_beat=floor(absolute_beat()+0.000001)+1
func queue_interaction(at: float) -> void:
 var target: Dictionary=game.conductor.nearest_beat(game.conductor.timestamp(at))
 var available:=context_interaction()
 var id: String=str(available.get("id",""))
 if id.is_empty():return
 var error_ms:=absf(game.conductor.timestamp(at)-float(target.time))*1000
 if id=="vendor" and (int(target.beat)!=4 or game.conductor.grade((game.conductor.timestamp(at)-float(target.time))*1000)=="miss"):
  quest.notification="Talk on beat 4. Try the next cycle."
  notification_until=absolute_beat()+2
  record({"event":"vendor_invalid","beat":absolute_beat()})
  return
 if id!="vendor" and error_ms>game.movement_good_ms:
  quest.notification="MISS: press F on a beat."
  notification_until=absolute_beat()+2
  return
 if interaction_beat==str(target.id):return
 interaction_beat=str(target.id)
 interaction={"id":id,"due":maxf(ceil(absolute_beat()*4-0.000001)/4,absolute_beat()+maxf(0,float(target.time)-at)/game.conductor.duration())}
 advance()
func interact(id: String) -> void:
 control.reset()
 match id:
  "vendor":
   record({"event":"vendor_valid","beat":absolute_beat()})
   dialogue.begin("vendor")
  "crate":
   if inventory.pickup("crate"):
    quest.emit_event("crate_picked")
    game.audio.emit_event("pickup","story_crate")
    persist()
  "delivery":
   if quest.current().get("id")=="handover" and inventory.remove("crate"):
    quest.emit_event("crate_delivered")
    var reward: Dictionary={"id":"crate_delivery","amount":wallet.campaign.delivery_reward}
    if wallet.grant(str(reward.id),int(reward.amount)):
     reward_notice="DELIVERY REWARD: BDS $%d" % int(reward.amount)
     reward_until=absolute_beat()+16
    quest.emit_event("delivery_paid")
    persist()
    dialogue.begin("delivery")
  "stick":
   if quest.current().get("id")=="stick" and inventory.pickup("stick"):
    quest.emit_event("stick_picked")
    actor.set_pose("combat_idle")
    persist()
    dialogue.begin("fight_intro")
  "fight_intro":dialogue.begin("fight_intro")
func dialogue_completed(id: String) -> void:
 control.reset()
 if id=="opening" and phase=="cinematic":
  if opening_state=="opening":
   opening_state="door_wait"
   door_due=floor(absolute_beat()+0.000001)+1
  elif opening_state=="warning":
   opening_state="kick_wait"
   kick_due=floor(absolute_beat()+0.000001)+1
 if id=="vendor":
  quest.emit_event("vendor_spoken")
  persist()
 if id=="fight_intro" or id=="fight_lost":
  phase="fight_wait"
  fight_due=(floor(absolute_beat()/4)+1)*4
 if id=="quest_complete":phase="playing"
func check_obstacles(beat: float) -> void:
 var subdivision:=int(floor(beat*16+0.000001))
 if subdivision==obstacle_subdivision:return
 obstacle_subdivision=subdivision
 beat=float(subdivision)/16
 if screens.screen_id==3:
  var previous_checkpoint:=road_checkpoint
  road_checkpoint=obstacles.checkpoint_reached(actor.position.x,road_checkpoint)
  if road_checkpoint!=previous_checkpoint:persist()
  if road_section==1 and actor.position.x>=292 and game.game_time()-step_started>=game.step_seconds and quest.current().get("id")=="cross":
   quest.emit_event("road_crossed")
   persist()
  if obstacles.road_collision(beat,actor.position.x,road_section):recover_collision("Traffic: back to the safe pavement.")
 if screens.screen_id in [4,5]:
  var cycle:=int(floor((beat-obstacles.origin)/8))
  if obstacles.cane_active(beat) and actor.position.x>112 and actor.position.x<208 and cycle!=hazard_cycle:
   hazard_cycle=cycle
   if bool(control.held.get("low",false)):
    defenses+=1
    quest.notification="DODGED %d/%d" % [defenses,1 if screens.screen_id==4 else 2]
    notification_until=beat+2
   else:recover_collision("Watch the warning, then hold S to duck.")
func recover_collision(message: String) -> void:
 phase="recovering"
 control.reset()
 actor.reset_visual()
 actor.set_pose("story_unarmed_reaction")
 actor.sprite.pause()
 recovery_started=absolute_beat()
 recovery_checkpoint=road_checkpoint if screens.screen_id==3 else 100
 recovery_beat=ceil(absolute_beat())+1
 if screens.screen_id!=3:obstacles.reset_safe(recovery_beat)
 hazard_cycle=-1
 quest.notification=message
 notification_until=recovery_beat+2
 record({"event":"collision","screen":screens.screen_id,"beat":absolute_beat(),"item":inventory.item})
func persist() -> void:
 if not quest.completed.has("rent"):return
 save.data={"version":2,"campaign":"rent_due","unlocked_screen":screens.screen_id,"checkpoint":"traversal","opening_complete":true,"screen":screens.screen_id,"completed":quest.completed.duplicate(),"item":inventory.item,"money":wallet.money,"rewards":wallet.rewards.duplicate(),"rent_target":wallet.target(),"reward_amounts":wallet.amounts.duplicate()}
 if screens.screen_id==3:
  save.data["road_checkpoint"]=road_checkpoint
  save.data["road_section"]=road_section
 save.write()
func restore_progress() -> void:
 quest.restore(save.data.get("completed",[]))
 inventory.item=str(save.data.get("item",""))
 wallet.money=int(save.data.get("money",0))
 wallet.rewards.assign(save.data.get("rewards",[]))
 wallet.amounts=save.data.get("reward_amounts",{}).duplicate()
 for id in wallet.rewards:
  if not wallet.amounts.has(id):wallet.amounts[id]=wallet.reward_amount(id)
func start_fight() -> void:
 fight_music_key=game.audio.active
 fight_music_anchor=game.audio.anchor
 phase="fight"
 overlay.visible=false
 unarmed.visible=false
 actor.sprite.visible=true
 game.start_story_match(wallet.campaign.encounters.first_stick_fight)
func campaign_objective() -> String:
 if wallet.ready_to_pay():return "Return home and pay the rent. (Upcoming)"
 if quest.finished():return "Find more paid work and stick fights. (Upcoming)"
 return quest.hud_objective()
func match_position(player: int, target: Vector2) -> Vector2:
 # Presentation only: replace render-delta easing with a sampled musical-phase curve.
 # Combat movement still uses the shared RhythmMovement interpolation in main.gd.
 var token: String=game.mode+str(target)
 if not match_motion.has(player) or match_motion[player].token!=token:
  match_motion[player]={"token":token,"from":game.fighters[player].position,"beat":world.beat()}
 var sample: Dictionary=match_motion[player]
 var weight:=1-exp(-8*maxf(0,world.beat()-float(sample.beat)))
 var point: Vector2=Vector2(sample.from).lerp(target,weight)
 return Vector2(roundf(point.x),roundf(point.y))
func sync_fight_poses() -> void:
 screens.current.queue_redraw()
 for i in range(2):
  var fighter: Fighter=game.fighters[i]
  var frames: SpriteFrames=fighter.sprite.sprite_frames
  fighter.sprite.modulate=Color.WHITE
  if not game.completed_exchanges.is_empty():
   var event: Dictionary=game.completed_exchanges.back()
   if int(event.get("defender",-1))==i and event.get("kind")=="HIT" and game.conductor.now()-float(event.time)<.2:fighter.sprite.modulate=Color(1,.45,.45)
  var token: String=fighter.pose+str(fighter.visual_until)
  if frames.get_animation_loop(fighter.pose):
   fighter.sprite.frame=world.pose(frames.get_frame_count(fighter.pose),4,i*2)
  else:
   if not pose_samples.has(i) or pose_samples[i].token!=token:
    pose_samples[i]={"token":token,"start":game.conductor.now(),"frame":fighter.sprite.frame,"speed":frames.get_animation_speed(fighter.pose)*fighter.sprite.speed_scale}
   var sample: Dictionary=pose_samples[i]
   fighter.sprite.frame=mini(frames.get_frame_count(fighter.pose)-1,int(sample.frame)+int(maxf(0,game.conductor.now()-float(sample.start))*float(sample.speed)))
  fighter.sprite.pause()
func finish_fight(winner: int) -> void:
 # Called only by the existing guarded deciding-match result handler.
 if phase!="fight" or game.match_progress.winner!=winner:return
 fight_result=winner
 if winner==0:
  quest.emit_event("fight_won")
  var encounter: Dictionary=wallet.campaign.encounters.first_stick_fight
  if wallet.grant(str(encounter.reward_id),int(encounter.reward)):
   reward_notice="MATCH REWARD: BDS $%d" % int(encounter.reward)
   reward_until=INF
  persist()
func return_from_match() -> void:
 game.audio.play_track(fight_music_key,fight_music_anchor,true)
 game.cpu.queue.clear()
 game.mode="story"
 game.fighters[1].visible=false
 game.impact_effect.clear()
 game.impact_effect.visible=false
 game.ground_sticks.visible=false
 actor.reset_visual()
 actor.set_pose("combat_idle")
 actor.position=Vector2(138,150)
 phase="playing"
 target_x=138
 step_origin=138
 step_started=-INF
 clear_inputs()
 game.flow.view.visible=false
 overlay.visible=true
 if fight_result==0:
  reward_until=absolute_beat()+12
  quest.notification="A Stick To Share Licks complete. More paid work is upcoming."
  notification_until=absolute_beat()+12
 else:dialogue.begin("fight_lost")
 game.refresh()

func clear_inputs() -> void:
 control.reset()
 blocked.clear()
 action_held=false
 interaction.clear()
 dialogue.pending=false
 dialogue.held=false

func context_interaction() -> Dictionary:
 if phase!="playing" or dialogue.active() or quest_panel:return {}
 match screens.screen_id:
  2:
   if absf(target_x-92)<=30 and quest.current().get("id")=="vendor":return {"id":"vendor","label":"Talk - Beat 4","action":"p1_execute","beat4":true}
   if absf(target_x-142)<=28 and quest.current().get("id")=="crate":return {"id":"crate","label":"Pick up","action":"p1_execute"}
  3:
   if road_section==1 and target_x>=292 and quest.current().get("id")=="handover":return {"id":"delivery","label":"Deliver","action":"p1_execute"}
  6:
   if absf(target_x-116)<=28 and inventory.item=="":return {"id":"stick","label":"Pick up","action":"p1_execute"}
   if inventory.item=="stick" and not quest.finished():return {"id":"fight_intro","label":"Talk","action":"p1_execute"}
 return {}
