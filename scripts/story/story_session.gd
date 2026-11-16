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
func setup(owner: Node2D) -> void:
 game=owner
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
func install_art() -> void:
 var frames:=actor.sprite.sprite_frames
 var definitions: Dictionary={"story_eviction":[],"story_forward_step":[8,10],"story_backward_step":[8,10],"story_duck":[9]}
 for i in range(12):definitions.story_eviction.append(i)
 for name in definitions:
  frames.add_animation(name)
  frames.set_animation_loop(name,false)
  frames.set_animation_speed(name,12.5)
  for index in definitions[name]:
   var path: String=("res://assets/story/009/fighter_%02d.png" if name=="story_eviction" else "res://assets/characters/fighter_01/frames/milestone_002/race/%03d.png") % index
   frames.add_frame(name,load(path))
  actor.animation_meta[name]={"scale":64.0/289 if name=="story_eviction" else 64.0/240,"canvas":[768,768],"ground_pixel":744}
func absolute_beat() -> float:return (game.game_time()-game.conductor.epoch)/game.conductor.duration()
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
 screens.load_screen(1).bind_clock(game.conductor)
 visible=true
 overlay.visible=true
 game.stage.visible=false
 game.fighters[1].visible=false
 game.ground_sticks.visible=false
 game.impact_effect.visible=false
 game.hud.visible=false
 actor.visible=true
 actor.reset_visual()
 actor.face(1)
 control.reset()
 blocked.clear()
 trace.clear()
 origin=ceil(absolute_beat()-0.000001)
 accents.clear()
 dust_beat=-INF
 target_x=float(config.start_x)
 step_origin=target_x
 step_started=-INF
 actor.position=Vector2(float(config.door_x) if cinematic else target_x,Bout.GROUND_Y)
 house.cues.assign(config.house)
 recovery.cues.assign(config.fighter)
 house.start(origin)
 recovery.start(origin)
 phase="cinematic"
 if not cinematic:finish_cinematic()
 game.refresh()
 advance()
func deactivate() -> void:
 phase="inactive"
 house.stop()
 recovery.stop()
 visible=false
 overlay.visible=false
 game.stage.visible=true
 game.fighters[1].visible=true
 game.impact_effect.visible=true
 actor.reset_visual()
func finish_cinematic() -> void:
 house.stop()
 recovery.stop()
 screens.current.house_frame=1
 actor.position=Vector2(target_x,Bout.GROUND_Y)
 actor.reset_visual()
 actor.set_pose("character_master")
 actor.sprite.stop()
 phase="waiting"
 control.reset()
 for c in game.controls:c.reset()
 # Always a future boundary, never the middle of recovery or the current late window.
 unlock_at=floor(absolute_beat()+0.000001)+1
 save.checkpoint("traversal")
func advance() -> void:
 if phase=="inactive":return
 var beat:=absolute_beat()
 var relative:=beat-origin
 var now: float=game.game_time()
 if phase=="cinematic":
  var h:=house.sample(beat)
  var f:=recovery.sample(beat)
  if not h.is_empty():screens.current.house_frame=int(h.frame)
  actor.set_pose("story_eviction")
  actor.sprite.stop()
  if not f.is_empty():actor.sprite.frame=int(f.frame)
  var progress:=clampf((relative-float(config.flight_start))/(float(config.landing_beat)-float(config.flight_start)),0,1)
  actor.position=Vector2(roundf(lerpf(float(config.door_x),target_x,progress)),roundf(Bout.GROUND_Y-sin(progress*PI)*24))
  for cue in config.accents:
   if relative>=float(cue.beat) and not accents.has(cue.id):
    accents[cue.id]=true
    if cue.id=="land":dust_beat=origin+float(config.landing_beat)
    game.audio.emit_event(cue.sound,"story:%s:%s" % [origin,cue.id])
  if relative>=float(config.idle_beat):finish_cinematic()
 elif phase=="waiting":
  if beat+0.000001>=unlock_at:
   phase="playing"
   control.reset()
   record({"event":"control","at":now,"position":actor.position,"beat":beat})
 elif phase=="playing":
  actor.position=Vector2(roundf(RhythmMovement.position_at(step_origin,target_x,step_started,now,game.step_seconds)),Bout.GROUND_Y)
  if now-step_started>=game.step_seconds:
   actor.reset_visual()
   actor.set_pose("story_duck" if bool(control.held.get("low",false)) else "character_master")
   actor.sprite.stop()
   if target_x>=float(config.playable_right):
    phase="complete"
    control.reset()
    save.checkpoint("screen01_complete")
    game.flow.root("story_end")
 screens.current.dust_age=(beat-dust_beat)*game.conductor.duration() if is_finite(dust_beat) else -1
 screens.current.dust_x=float(config.start_x)
 screens.current.queue_redraw()
 overlay.queue_redraw()
func on_beat(beat: int, phrase_number: int) -> void:
 # Catch up cinematic recovery before dispatching this boundary's movement.
 advance()
 if phase=="playing":apply_step(beat,phrase_number,game.conductor.beat_time)
func apply_step(beat: int, phrase_number: int, at: float) -> void:
 control.last_step_evaluated=at
 var direction:=control.step(beat,phrase_number)
 if direction==0:return
 var before:=target_x
 target_x=clampf(target_x+direction*Bout.STEP,Bout.MIN_X,float(config.playable_right))
 if is_equal_approx(before,target_x):
  control.movement_executed=false
  control.step_feedback="REJECT screen boundary"
  return
 step_origin=actor.position.x
 step_started=game.game_time()
 control.last_step_time=at
 control.last_step_processed=step_started
 actor.rhythmic_pose("story_"+RhythmMovement.pose(direction,1),game.step_seconds)
 record({"event":"step","at":at,"target":target_x,"beat":"%d:%d" % [phrase_number,beat],"grade":control.movement_grade})
func record(row: Dictionary) -> void:
 trace.append(row)
 if trace.size()>256:trace.pop_front()
func submit(action: String, pressed: bool, at: float) -> void:
 game.conductor.update(at)
 advance()
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
  if event.keycode==KEY_ENTER and phase=="cinematic":finish_cinematic()
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
